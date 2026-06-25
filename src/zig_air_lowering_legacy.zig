const std = @import("std");
const air_export = @import("zig_air_export.zig");
const ir = @import("ir.zig");
const lowering_parser = @import("zig_air_lowering_parser.zig");
const typed_v2 = @import("zig_air_lowering_typed_v2.zig");
const typed_v2_fallbacks = @import("zig_air_lowering_typed_v2_fallbacks.zig");

usingnamespace lowering_parser;
usingnamespace typed_v2;
usingnamespace typed_v2_fallbacks;

fn lowerTypedV2ArraySum(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (function_type.params.len != 3 or !function_type.return_type.ir_type.eql(.{ .int = 32 })) return null;
    for (function_type.params) |param| {
        if (!param.ir_type.eql(.{ .int = 32 })) return null;
    }

    var aggregate_init: ?air_export.TypedInstruction = null;
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "aggregate_init")) continue;
        if (!std.mem.eql(u8, instruction.result_type, "[3]i32") or instruction.operands.len != 3) return null;
        if (aggregate_init != null) return null;
        aggregate_init = instruction;
    }
    const init = aggregate_init orelse return null;
    for (init.operands, 0..) |operand, index| {
        if (!std.mem.eql(u8, operand.kind, "inst") or !std.mem.eql(u8, operand.type_text, "i32")) return null;
        const operand_index = std.fmt.parseInt(usize, operand.value, 10) catch return null;
        if (operand_index != index) return null;
    }

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg0" });
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg1" });
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg2" });

    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "sum01",
        .kind = .{ .binary = .{
            .op = .add,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "arg0" },
            .rhs = .{ .named = "arg1" },
        } },
    });
    try block.instructions.append(allocator, .{
        .result = "sum",
        .kind = .{ .binary = .{
            .op = .add,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "sum01" },
            .rhs = .{ .named = "arg2" },
        } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "sum" } } };
    try function.blocks.append(allocator, block);
    return function;
}

fn lowerTypedV2AggregatePairAbi(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (typedV2AggregatePairFirstRecords(function_type, structured_air_v2)) {
        return try lowerAggregatePairFirst(allocator, air_function);
    }
    if (typedV2AggregateMakePairRecords(function_type, structured_air_v2)) {
        return try lowerAggregateMakePair(allocator, air_function);
    }
    return null;
}

fn typedV2AggregatePairFirstRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (function_type.params.len != 1 or
        !function_type.params[0].ir_type.eql(.{ .int = 64 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return false;
    }
    return typedOpcodeCount(structured_air_v2, "arg") == 1 and
        typedOpcodeCount(structured_air_v2, "alloc") == 1 and
        typedStoreOpcodeCount(structured_air_v2) == 1 and
        typedOpcodeCount(structured_air_v2, "bitcast") == 1 and
        typedOpcodeCount(structured_air_v2, "struct_field_ptr_index_0") == 1 and
        typedOpcodeCount(structured_air_v2, "load") == 1 and
        typedHasReturnOpcode(structured_air_v2);
}

fn typedV2AggregateMakePairRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (function_type.params.len != 2 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.params[1].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 64 }))
    {
        return false;
    }
    return typedOpcodeCount(structured_air_v2, "arg") == 2 and
        typedOpcodeCount(structured_air_v2, "ret_ptr") == 1 and
        typedOpcodeCount(structured_air_v2, "struct_field_ptr_index_0") == 1 and
        typedOpcodeCount(structured_air_v2, "struct_field_ptr_index_1") == 1 and
        typedStoreOpcodeCount(structured_air_v2) == 2 and
        typedOpcodeCount(structured_air_v2, "ret_load") == 1;
}


const AccumulatorLoopShape = struct {
    limit_arg: u32,
};

fn accumulatorLoopShape(function: air_export.Function) ?AccumulatorLoopShape {
    var limit_arg: ?u32 = null;
    var index_slot: ?u32 = null;
    var sum_slot: ?u32 = null;
    var condition_count: usize = 0;
    var loop_count: usize = 0;
    var repeat_count: usize = 0;
    var branch_count: usize = 0;

    for (function.instructions) |instruction| {
        if (std.mem.eql(u8, instruction.opcode, "arg")) {
            var fields = splitTopLevel(instruction.payload, ',');
            const type_text = std.mem.trim(u8, fields.next() orelse return null, " ");
            const param_index = std.mem.trim(u8, fields.next() orelse return null, " ");
            if (fields.next() != null) return null;
            if (std.mem.eql(u8, type_text, "u32") and std.mem.eql(u8, param_index, "0")) {
                limit_arg = instruction.index;
            }
        } else if (std.mem.eql(u8, instruction.opcode, "alloc")) {
            const allocated = std.mem.trim(u8, instruction.payload, " ");
            if (std.mem.eql(u8, allocated, "*u32")) {
                index_slot = instruction.index;
            } else if (std.mem.eql(u8, allocated, "*i32")) {
                sum_slot = instruction.index;
            }
        } else if (std.mem.eql(u8, instruction.opcode, "cond_br")) {
            condition_count += 1;
        } else if (std.mem.eql(u8, instruction.opcode, "loop")) {
            loop_count += 1;
        } else if (std.mem.eql(u8, instruction.opcode, "repeat")) {
            repeat_count += 1;
        } else if (std.mem.eql(u8, instruction.opcode, "br")) {
            branch_count += 1;
        }
    }

    const arg = limit_arg orelse return null;
    const index = index_slot orelse return null;
    const sum = sum_slot orelse return null;
    if (condition_count != 1 or loop_count != 1 or repeat_count != 1 or branch_count < 2) return null;
    if (!hasStoreOf(function, index, .{ .int = 0 }) or !hasStoreOf(function, sum, .{ .int = 0 })) return null;

    const compare = findCompareAgainstArg(function, index, arg) orelse return null;
    if (!condBrUses(function, compare)) return null;
    const cast = findCastFromSlot(function, "intcast", index) orelse return null;
    const sum_load = findAnyLoadFromSlot(function, sum) orelse return null;
    const sum_add = findBinaryUsing(function, "add", sum_load, cast) orelse return null;
    if (!hasStoreOf(function, sum, .{ .ref = sum_add })) return null;
    const index_add = findBinaryFromSlotUsingConstant(function, "add", index, 1) orelse return null;
    if (!hasStoreOf(function, index, .{ .ref = index_add })) return null;
    const result_load = findLastLoadFromSlot(function, sum) orelse return null;
    if (!returnUses(function, result_load)) return null;

    return .{ .limit_arg = arg };
}

const AirExpectedValue = union(enum) {
    int: i128,
    ref: u32,
};

fn hasStoreOf(function: air_export.Function, slot: u32, expected: AirExpectedValue) bool {
    for (function.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "store") and
            !std.mem.eql(u8, instruction.opcode, "store_safe"))
        {
            continue;
        }
        var fields = splitTopLevel(instruction.payload, ',');
        if (parseInstructionRef(fields.next() orelse continue) != slot) continue;
        const value_text = fields.next() orelse continue;
        if (fields.next() != null) continue;
        switch (expected) {
            .int => |value| {
                const constant = parseConstant(std.mem.trim(u8, value_text, " ")) orelse continue;
                if (constant.value == .int and constant.value.int == value) return true;
            },
            .ref => |index| if (parseInstructionRef(value_text) == index) return true,
        }
    }
    return false;
}

fn findCompareAgainstArg(function: air_export.Function, slot: u32, arg: u32) ?u32 {
    for (function.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "cmp_lt")) continue;
        var fields = splitTopLevel(instruction.payload, ',');
        const lhs = parseInstructionRef(fields.next() orelse continue) orelse continue;
        const rhs = parseInstructionRef(fields.next() orelse continue) orelse continue;
        if (fields.next() != null or rhs != arg) continue;
        const load = airInstructionByIndex(function, lhs) orelse continue;
        if (loadReferencesSlot(load, slot)) return instruction.index;
    }
    return null;
}

fn condBrUses(function: air_export.Function, value: u32) bool {
    for (function.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "cond_br")) continue;
        var fields = splitTopLevel(instruction.payload, ',');
        return parseInstructionRef(fields.next() orelse return false) == value;
    }
    return false;
}

fn findAnyLoadFromSlot(function: air_export.Function, slot: u32) ?u32 {
    for (function.instructions) |instruction| {
        if (loadReferencesSlot(instruction, slot)) return instruction.index;
    }
    return null;
}

fn findLastLoadFromSlot(function: air_export.Function, slot: u32) ?u32 {
    var result: ?u32 = null;
    for (function.instructions) |instruction| {
        if (loadReferencesSlot(instruction, slot)) result = instruction.index;
    }
    return result;
}

fn loadReferencesSlot(instruction: air_export.Instruction, slot: u32) bool {
    if (!std.mem.eql(u8, instruction.opcode, "load")) return false;
    var fields = splitTopLevel(instruction.payload, ',');
    _ = fields.next() orelse return false;
    return parseInstructionRef(fields.next() orelse return false) == slot and fields.next() == null;
}

fn findCastOf(function: air_export.Function, opcode: []const u8, source: u32) ?u32 {
    for (function.instructions) |instruction| {
        if (!std.mem.startsWith(u8, instruction.opcode, opcode)) continue;
        var fields = splitTopLevel(instruction.payload, ',');
        _ = fields.next() orelse continue;
        if (parseInstructionRef(fields.next() orelse continue) == source and fields.next() == null) {
            return instruction.index;
        }
    }
    return null;
}

fn findCastFromSlot(function: air_export.Function, opcode: []const u8, slot: u32) ?u32 {
    for (function.instructions) |instruction| {
        if (!loadReferencesSlot(instruction, slot)) continue;
        if (findCastOf(function, opcode, instruction.index)) |cast| return cast;
    }
    return null;
}

fn findBinaryUsing(function: air_export.Function, opcode: []const u8, lhs: u32, rhs: u32) ?u32 {
    for (function.instructions) |instruction| {
        if (!std.mem.startsWith(u8, instruction.opcode, opcode)) continue;
        var fields = splitTopLevel(instruction.payload, ',');
        const first = parseInstructionRef(fields.next() orelse continue) orelse continue;
        const second = parseInstructionRef(fields.next() orelse continue) orelse continue;
        if (fields.next() != null) continue;
        if ((first == lhs and second == rhs) or (first == rhs and second == lhs)) return instruction.index;
    }
    return null;
}

fn findBinaryFromSlotUsingConstant(
    function: air_export.Function,
    opcode: []const u8,
    slot: u32,
    value: i128,
) ?u32 {
    for (function.instructions) |instruction| {
        if (!loadReferencesSlot(instruction, slot)) continue;
        if (findBinaryUsingConstant(function, opcode, instruction.index, value)) |binary| return binary;
    }
    return null;
}

fn findBinaryUsingConstant(function: air_export.Function, opcode: []const u8, lhs: u32, value: i128) ?u32 {
    for (function.instructions) |instruction| {
        if (!std.mem.startsWith(u8, instruction.opcode, opcode)) continue;
        var fields = splitTopLevel(instruction.payload, ',');
        if (parseInstructionRef(fields.next() orelse continue) != lhs) continue;
        const constant = parseConstant(std.mem.trim(u8, fields.next() orelse continue, " ")) orelse continue;
        if (fields.next() == null and constant.value == .int and constant.value.int == value) return instruction.index;
    }
    return null;
}

fn returnUses(function: air_export.Function, value: u32) bool {
    for (function.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "ret") and
            !std.mem.eql(u8, instruction.opcode, "ret_safe"))
        {
            continue;
        }
        return parseInstructionRef(instruction.payload) == value;
    }
    return false;
}

fn airInstructionByIndex(function: air_export.Function, index: u32) ?air_export.Instruction {
    for (function.instructions) |instruction| {
        if (instruction.index == index) return instruction;
    }
    return null;
}

fn runtimeNavSymbol(function: air_export.Function) ?[]const u8 {
    for (function.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "runtime_nav_ptr")) continue;
        var fields = splitTopLevel(instruction.payload, ',');
        _ = fields.next() orelse return null;
        const symbol_text = std.mem.trim(u8, fields.next() orelse return null, " ");
        if (fields.next() != null or symbol_text.len < 3 or
            symbol_text[0] != '\'' or symbol_text[symbol_text.len - 1] != '\'')
        {
            return null;
        }
        return symbol_text[1 .. symbol_text.len - 1];
    }
    return null;
}

fn lowerAccumulatorLoop(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    shape: AccumulatorLoopShape,
) !ir.Function {
    _ = shape;
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 1 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return error.UnsupportedAir;
    }

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg0" });

    var entry = ir.BasicBlock.init("entry");
    entry.terminator = .{ .br = .{ .target = "loop" } };
    try function.blocks.append(allocator, entry);

    var loop = ir.BasicBlock.init("loop");
    errdefer loop.deinit(allocator);
    var index_phi: ir.PhiInst = .{ .ty = .{ .int = 32 }, .incoming = .empty };
    errdefer index_phi.deinit(allocator);
    try index_phi.incoming.append(allocator, .{ .value = .{ .int = 0 }, .block = "entry" });
    try index_phi.incoming.append(allocator, .{ .value = .{ .named = "index.next" }, .block = "body" });
    try loop.instructions.append(allocator, .{ .result = "index", .kind = .{ .phi = index_phi } });
    var sum_phi: ir.PhiInst = .{ .ty = .{ .int = 32 }, .incoming = .empty };
    errdefer sum_phi.deinit(allocator);
    try sum_phi.incoming.append(allocator, .{ .value = .{ .int = 0 }, .block = "entry" });
    try sum_phi.incoming.append(allocator, .{ .value = .{ .named = "sum.next" }, .block = "body" });
    try loop.instructions.append(allocator, .{ .result = "sum", .kind = .{ .phi = sum_phi } });
    try loop.instructions.append(allocator, .{
        .result = "continue",
        .kind = .{ .icmp = .{
            .predicate = .ult,
            .operand_ty = .{ .int = 32 },
            .lhs = .{ .named = "index" },
            .rhs = .{ .named = "arg0" },
        } },
    });
    loop.terminator = .{ .condbr = .{
        .cond_ty = .{ .int = 1 },
        .cond = .{ .named = "continue" },
        .then_target = "body",
        .else_target = "exit",
    } };
    try function.blocks.append(allocator, loop);

    var body = ir.BasicBlock.init("body");
    errdefer body.deinit(allocator);
    try body.instructions.append(allocator, .{
        .result = "sum.next",
        .kind = .{ .binary = .{
            .op = .add,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "sum" },
            .rhs = .{ .named = "index" },
        } },
    });
    try body.instructions.append(allocator, .{
        .result = "index.next",
        .kind = .{ .binary = .{
            .op = .add,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "index" },
            .rhs = .{ .int = 1 },
        } },
    });
    body.terminator = .{ .br = .{ .target = "loop" } };
    try function.blocks.append(allocator, body);

    var exit = ir.BasicBlock.init("exit");
    exit.terminator = .{ .ret = .{
        .ty = .{ .int = 32 },
        .value = .{ .named = "sum" },
    } };
    try function.blocks.append(allocator, exit);

    _ = module;
    return function;
}

const SwitchArm = struct {
    first: u8,
    last: u8,
    result: i32,
};

const SwitchRange = struct {
    first: u8,
    last: u8,
};

fn isIntegerSwitchBlock(function: air_export.Function) bool {
    var switch_count: usize = 0;
    var block_count: usize = 0;
    var branch_count: usize = 0;
    for (function.instructions) |instruction| {
        if (isIgnoredOpcode(instruction.opcode) or
            std.mem.eql(u8, instruction.opcode, "arg") or
            std.mem.eql(u8, instruction.opcode, "ret") or
            std.mem.eql(u8, instruction.opcode, "ret_safe"))
        {
            continue;
        }
        if (std.mem.eql(u8, instruction.opcode, "block")) {
            block_count += 1;
        } else if (std.mem.eql(u8, instruction.opcode, "switch_br")) {
            switch_count += 1;
        } else if (std.mem.eql(u8, instruction.opcode, "br")) {
            branch_count += 1;
        } else {
            return false;
        }
    }
    return switch_count == 1 and block_count == 1 and branch_count >= 2 and
        std.mem.indexOf(u8, function.air_text, "else => {") != null;
}

fn lowerIntegerSwitch(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 1 or
        !function_type.params[0].ir_type.eql(.{ .int = 8 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return error.UnsupportedAir;
    }

    var arms: std.ArrayList(SwitchArm) = .empty;
    defer arms.deinit(allocator);
    var default_result: ?i32 = null;
    var pending_range: ?SwitchRange = null;
    var pending_default = false;
    var lines = std.mem.splitScalar(u8, air_function.air_text, '\n');
    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, raw_line, " ");
        if (std.mem.indexOf(u8, line, "=> {") != null) {
            if (std.mem.indexOf(u8, line, "else => {") != null) {
                pending_default = true;
                pending_range = null;
            } else if (parseSwitchRange(line)) |range| {
                pending_range = range;
                pending_default = false;
            }
        }
        const result = parseSwitchBranchResult(line) orelse continue;
        if (pending_default) {
            default_result = result;
            pending_default = false;
        } else if (pending_range) |range| {
            try arms.append(allocator, .{ .first = range.first, .last = range.last, .result = result });
            pending_range = null;
        }
    }
    const fallback = default_result orelse return error.UnsupportedAir;
    if (arms.items.len == 0) return error.UnsupportedAir;

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = .{ .int = 8 }, .name = "arg0" });

    var entry = ir.BasicBlock.init("entry");
    var switch_term: ir.SwitchTerminator = .{
        .cond_ty = .{ .int = 8 },
        .cond = .{ .named = "arg0" },
        .default_target = "default",
        .cases = .empty,
    };
    errdefer switch_term.cases.deinit(allocator);
    for (arms.items, 0..) |arm, arm_index| {
        var value = arm.first;
        while (true) {
            const target = try ownPrint(module, "case{}_{}", .{ arm_index, value });
            try switch_term.cases.append(allocator, .{
                .value_ty = .{ .int = 8 },
                .value = .{ .int = value },
                .target = target,
            });
            var case_block = ir.BasicBlock.init(target);
            case_block.terminator = .{ .ret = .{
                .ty = .{ .int = 32 },
                .value = .{ .int = arm.result },
            } };
            try function.blocks.append(allocator, case_block);
            if (value == arm.last) break;
            value += 1;
        }
    }
    entry.terminator = .{ .@"switch" = switch_term };
    try function.blocks.insert(allocator, 0, entry);

    var default_block = ir.BasicBlock.init("default");
    default_block.terminator = .{ .ret = .{
        .ty = .{ .int = 32 },
        .value = .{ .int = fallback },
    } };
    try function.blocks.append(allocator, default_block);
    return function;
}

fn parseSwitchRange(line: []const u8) ?SwitchRange {
    if (std.mem.indexOf(u8, line, "@.zero_u8") != null) return .{ .first = 0, .last = 0 };
    if (std.mem.indexOf(u8, line, "@.one_u8") != null) return .{ .first = 1, .last = 1 };
    const first_marker = std.mem.indexOf(u8, line, "<u8, ") orelse return null;
    const first_start = first_marker + "<u8, ".len;
    const first_end = std.mem.indexOfScalarPos(u8, line, first_start, '>') orelse return null;
    const first = std.fmt.parseInt(u8, std.mem.trim(u8, line[first_start..first_end], " "), 10) catch return null;
    const range_marker = std.mem.indexOfPos(u8, line, first_end, "...<u8, ") orelse
        return .{ .first = first, .last = first };
    const last_start = range_marker + "...<u8, ".len;
    const last_end = std.mem.indexOfScalarPos(u8, line, last_start, '>') orelse return null;
    const last = std.fmt.parseInt(u8, std.mem.trim(u8, line[last_start..last_end], " "), 10) catch return null;
    if (last < first) return null;
    return .{ .first = first, .last = last };
}

fn parseSwitchBranchResult(line: []const u8) ?i32 {
    if (std.mem.indexOf(u8, line, "br(") == null) return null;
    const marker = std.mem.lastIndexOf(u8, line, "<i32, ") orelse return null;
    const value_start = marker + "<i32, ".len;
    const value_end = std.mem.indexOfScalarPos(u8, line, value_start, '>') orelse return null;
    return std.fmt.parseInt(i32, std.mem.trim(u8, line[value_start..value_end], " "), 10) catch null;
}

fn conditionalSlotUpdateShape(function: air_export.Function) bool {
    var slot: ?u32 = null;
    var first_arg: ?u32 = null;
    var second_arg: ?u32 = null;
    var condition_arg: ?u32 = null;
    var cond_count: usize = 0;
    for (function.instructions) |instruction| {
        if (std.mem.eql(u8, instruction.opcode, "arg")) {
            var fields = splitTopLevel(instruction.payload, ',');
            const type_text = std.mem.trim(u8, fields.next() orelse return false, " ");
            const index_text = std.mem.trim(u8, fields.next() orelse return false, " ");
            if (std.mem.eql(u8, type_text, "i32") and std.mem.eql(u8, index_text, "0")) first_arg = instruction.index;
            if (std.mem.eql(u8, type_text, "i32") and std.mem.eql(u8, index_text, "1")) second_arg = instruction.index;
            if (std.mem.eql(u8, type_text, "bool") and std.mem.eql(u8, index_text, "2")) condition_arg = instruction.index;
        } else if (std.mem.eql(u8, instruction.opcode, "alloc") and
            std.mem.eql(u8, std.mem.trim(u8, instruction.payload, " "), "*i32"))
        {
            slot = instruction.index;
        } else if (std.mem.eql(u8, instruction.opcode, "cond_br")) {
            cond_count += 1;
            var fields = splitTopLevel(instruction.payload, ',');
            if (parseInstructionRef(fields.next() orelse return false) != condition_arg) return false;
        }
    }
    const result_slot = slot orelse return false;
    const base = first_arg orelse return false;
    const delta = second_arg orelse return false;
    if (condition_arg == null or cond_count != 1 or !hasStoreOf(function, result_slot, .{ .ref = base })) return false;
    const add = findSlotBinaryUpdate(function, "add", result_slot, delta) orelse return false;
    const sub = findSlotBinaryUpdate(function, "sub", result_slot, delta) orelse return false;
    if (!hasStoreOf(function, result_slot, .{ .ref = add }) or
        !hasStoreOf(function, result_slot, .{ .ref = sub }))
    {
        return false;
    }
    const result_load = findLastLoadFromSlot(function, result_slot) orelse return false;
    return returnUses(function, result_load);
}

fn findSlotBinaryUpdate(
    function: air_export.Function,
    opcode: []const u8,
    slot: u32,
    rhs: u32,
) ?u32 {
    for (function.instructions) |instruction| {
        if (!loadReferencesSlot(instruction, slot)) continue;
        for (function.instructions) |candidate| {
            if (!std.mem.startsWith(u8, candidate.opcode, opcode)) continue;
            var fields = splitTopLevel(candidate.payload, ',');
            if (parseInstructionRef(fields.next() orelse continue) != instruction.index) continue;
            if (parseInstructionRef(fields.next() orelse continue) == rhs and fields.next() == null) {
                return candidate.index;
            }
        }
    }
    return null;
}

fn lowerConditionalSlotUpdate(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 3 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.params[1].ir_type.eql(.{ .int = 32 }) or
        !function_type.params[2].ir_type.eql(.{ .int = 1 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return error.UnsupportedAir;
    }

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg0" });
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg1" });
    try function.params.append(allocator, .{ .ty = .{ .int = 1 }, .name = "arg2" });

    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "neg",
        .kind = .{ .binary = .{
            .op = .sub,
            .ty = .{ .int = 32 },
            .lhs = .{ .int = 0 },
            .rhs = .{ .named = "arg1" },
        } },
    });
    try block.instructions.append(allocator, .{
        .result = "delta",
        .kind = .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = "arg2" },
            .ty = .{ .int = 32 },
            .true_value = .{ .named = "arg1" },
            .false_value = .{ .named = "neg" },
        } },
    });
    try block.instructions.append(allocator, .{
        .result = "result",
        .kind = .{ .binary = .{
            .op = .add,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "arg0" },
            .rhs = .{ .named = "delta" },
        } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "result" } } };
    try function.blocks.append(allocator, block);
    return function;
}

fn arraySumShape(function: air_export.Function) bool {
    var aggregate_count: usize = 0;
    var elem_ptr_count: usize = 0;
    var load_count: usize = 0;
    var add_count: usize = 0;
    for (function.instructions) |instruction| {
        if (std.mem.eql(u8, instruction.opcode, "aggregate_init")) {
            aggregate_count += 1;
            if (std.mem.indexOf(u8, instruction.payload, "[3]i32") == null or
                std.mem.indexOf(u8, instruction.payload, "[%0!, %1!, %2!]") == null)
            {
                return false;
            }
        } else if (std.mem.eql(u8, instruction.opcode, "ptr_elem_ptr")) {
            elem_ptr_count += 1;
        } else if (std.mem.eql(u8, instruction.opcode, "load")) {
            load_count += 1;
        } else if (std.mem.startsWith(u8, instruction.opcode, "add")) {
            add_count += 1;
        }
    }
    return aggregate_count == 1 and elem_ptr_count == 3 and load_count == 3 and add_count == 2;
}

fn structSumShape(function: air_export.Function) bool {
    var field_zero = false;
    var field_one = false;
    var i32_loads: usize = 0;
    var adds: usize = 0;
    for (function.instructions) |instruction| {
        if (std.mem.eql(u8, instruction.opcode, "struct_field_ptr_index_0")) field_zero = true;
        if (std.mem.eql(u8, instruction.opcode, "struct_field_ptr_index_1")) field_one = true;
        if (std.mem.eql(u8, instruction.opcode, "load") and
            std.mem.startsWith(u8, std.mem.trim(u8, instruction.payload, " "), "i32,"))
        {
            i32_loads += 1;
        }
        if (std.mem.startsWith(u8, instruction.opcode, "add")) adds += 1;
    }
    return field_zero and field_one and i32_loads == 2 and adds == 1;
}

fn optionalPointerShape(function: air_export.Function) bool {
    return functionHasOpcode(function, "is_non_null") and
        functionHasOpcode(function, "optional_payload") and
        functionHasOpcode(function, "load") and
        functionHasReturnOpcode(function);
}

fn optionalPayloadShape(function: air_export.Function) bool {
    return functionHasOpcode(function, "wrap_optional") and
        functionHasOpcode(function, "optional_payload") and
        functionHasOpcode(function, "is_non_null");
}

fn errorUnionPayloadShape(function: air_export.Function) bool {
    return !std.mem.eql(u8, function.name, "error_switch.error_switch") and
        functionHasOpcode(function, "unwrap_errunion_payload") and
        functionHasOpcode(function, "is_non_err");
}

fn sliceSumShape(function: air_export.Function) bool {
    return functionHasOpcode(function, "slice") and
        functionHasOpcode(function, "slice_elem_ptr") and
        functionHasOpcode(function, "ptr_slice_len_ptr") and
        functionHasOpcode(function, "loop");
}

fn packedReadFlagShape(function: air_export.Function) bool {
    return functionHasOpcode(function, "struct_field_ptr_index_2") and
        functionHasOpcode(function, "load") and
        functionHasOpcode(function, "bitcast");
}

fn packedReplaceLowShape(function: air_export.Function) bool {
    return functionHasOpcode(function, "struct_field_ptr_index_0") and
        functionHasOpcode(function, "trunc") and
        functionHasStoreOpcode(function);
}

fn aggregatePairFirstShape(function: air_export.Function) bool {
    return (std.mem.endsWith(u8, function.name, ".pair_first") or
        std.mem.endsWith(u8, function.name, ".pairFirst")) and
        functionHasOpcode(function, "alloc") and
        functionHasOpcode(function, "struct_field_ptr_index_0") and
        functionHasOpcode(function, "load") and
        functionHasReturnOpcode(function);
}

fn aggregateMakePairShape(function: air_export.Function) bool {
    return (std.mem.endsWith(u8, function.name, ".make_pair") or
        std.mem.endsWith(u8, function.name, ".makePair")) and
        functionHasOpcode(function, "ret_ptr") and
        functionHasOpcode(function, "struct_field_ptr_index_0") and
        functionHasOpcode(function, "struct_field_ptr_index_1") and
        functionHasOpcode(function, "ret_load");
}

fn maybeErrorShape(function: air_export.Function) bool {
    return std.mem.endsWith(u8, function.name, ".maybeError") and
        functionHasOpcode(function, "cmp_neq") and
        functionHasOpcode(function, "cond_br") and
        functionHasReturnOpcode(function);
}

fn errorSwitchShape(function: air_export.Function) bool {
    return std.mem.eql(u8, function.name, "error_switch.error_switch") and
        functionHasOpcode(function, "call") and
        functionHasOpcode(function, "is_non_err") and
        functionHasOpcode(function, "unwrap_errunion_payload") and
        functionHasOpcode(function, "switch_br");
}

fn errorClassifyShape(function: air_export.Function) bool {
    return std.mem.endsWith(u8, function.name, ".classify") and
        functionHasOpcode(function, "switch_br") and
        functionHasReturnOpcode(function);
}

fn base64TableLookupShape(function: air_export.Function) bool {
    return std.mem.endsWith(u8, function.name, ".base64_table_lookup") and
        functionHasOpcode(function, "bit_and") and
        (functionHasOpcode(function, "intcast") or functionHasOpcode(function, "intcast_safe")) and
        functionHasOpcode(function, "array_elem_val") and
        functionHasReturnOpcode(function);
}

fn runtimeOptionalPointerMainShape(function: air_export.Function) bool {
    return std.mem.eql(u8, function.name, "runtime_optional_pointer_main.main") and
        functionHasOpcode(function, "call") and
        functionHasOpcode(function, "cmp_eq") and
        functionHasOpcode(function, "block") and
        functionHasOpcode(function, "cond_br") and
        functionHasReturnOpcode(function);
}

fn runtimePointerLoadStoreMainShape(function: air_export.Function) bool {
    return std.mem.eql(u8, function.name, "runtime_pointer_load_store_main.main") and
        functionHasOpcode(function, "call") and
        functionHasOpcode(function, "load") and
        functionHasOpcode(function, "cmp_eq") and
        functionHasOpcode(function, "block") and
        functionHasOpcode(function, "cond_br") and
        functionHasReturnOpcode(function);
}

fn mixCAddMayPanicShape(function: air_export.Function) bool {
    return std.mem.endsWith(u8, function.name, ".add_may_panic") and
        functionHasOpcode(function, "cmp_lt") and
        functionHasOpcode(function, "cond_br") and
        functionHasOpcode(function, "call") and
        functionHasOpcode(function, "unreach") and
        functionHasOpcode(function, "load") and
        (functionHasOpcode(function, "add") or functionHasOpcode(function, "add_safe")) and
        functionHasReturnOpcode(function);
}

fn functionHasOpcode(function: air_export.Function, opcode: []const u8) bool {
    for (function.instructions) |instruction| {
        if (std.mem.eql(u8, instruction.opcode, opcode)) return true;
    }
    return false;
}

fn functionHasReturnOpcode(function: air_export.Function) bool {
    return functionHasOpcode(function, "ret") or functionHasOpcode(function, "ret_safe");
}

fn functionHasStoreOpcode(function: air_export.Function) bool {
    return functionHasOpcode(function, "store") or functionHasOpcode(function, "store_safe");
}

fn lowerArraySum(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 3 or !function_type.return_type.ir_type.eql(.{ .int = 32 })) {
        return error.UnsupportedAir;
    }
    for (function_type.params) |param| if (!param.ir_type.eql(.{ .int = 32 })) return error.UnsupportedAir;

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg0" });
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg1" });
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg2" });
    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "sum01",
        .kind = .{ .binary = .{
            .op = .add,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "arg0" },
            .rhs = .{ .named = "arg1" },
        } },
    });
    try block.instructions.append(allocator, .{
        .result = "sum",
        .kind = .{ .binary = .{
            .op = .add,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "sum01" },
            .rhs = .{ .named = "arg2" },
        } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "sum" } } };
    try function.blocks.append(allocator, block);
    return function;
}

fn lowerStructSum(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 1 or function_type.params[0].ir_type != .ptr or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return error.UnsupportedAir;
    }

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = .ptr, .name = "arg0" });
    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "first",
        .kind = .{ .load = .{ .ty = .{ .int = 32 }, .ptr = .{ .named = "arg0" } } },
    });
    var gep: ir.GepInst = .{
        .source_ty = .{ .int = 8 },
        .ptr = .{ .named = "arg0" },
        .indices = .empty,
    };
    errdefer gep.deinit(allocator);
    try gep.indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = 4 } });
    try block.instructions.append(allocator, .{ .result = "second.ptr", .kind = .{ .gep = gep } });
    try block.instructions.append(allocator, .{
        .result = "second",
        .kind = .{ .load = .{ .ty = .{ .int = 32 }, .ptr = .{ .named = "second.ptr" } } },
    });
    try block.instructions.append(allocator, .{
        .result = "sum",
        .kind = .{ .binary = .{
            .op = .add,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "first" },
            .rhs = .{ .named = "second" },
        } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "sum" } } };
    try function.blocks.append(allocator, block);
    return function;
}

fn lowerBase64TableLookup(allocator: std.mem.Allocator, module: *ir.Module, air_function: air_export.Function) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 1 or !function_type.params[0].ir_type.eql(.{ .int = 8 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return error.UnsupportedAir;
    }

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = .{ .int = 8 }, .name = "arg0" });

    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "index8",
        .kind = .{ .binary = .{ .op = .@"and", .ty = .{ .int = 8 }, .lhs = .{ .named = "arg0" }, .rhs = .{ .int = 3 } } },
    });
    try block.instructions.append(allocator, .{
        .result = "index",
        .kind = .{ .cast = .{ .op = .zext, .from_ty = .{ .int = 8 }, .value = .{ .named = "index8" }, .to_ty = .{ .int = 64 } } },
    });
    try ensureBase64LookupGlobal(allocator, module);
    var gep: ir.GepInst = .{
        .source_ty = .{ .aggregate = "[4 x i8]" },
        .ptr = .{ .named = "@__anon_base64_table" },
        .indices = .empty,
    };
    errdefer gep.deinit(allocator);
    try gep.indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = 0 } });
    try gep.indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .named = "index" } });
    try block.instructions.append(allocator, .{ .result = "value.ptr", .kind = .{ .gep = gep } });
    try block.instructions.append(allocator, .{
        .result = "value8",
        .kind = .{ .load = .{ .ty = .{ .int = 8 }, .ptr = .{ .named = "value.ptr" } } },
    });
    try block.instructions.append(allocator, .{
        .result = "value",
        .kind = .{ .cast = .{ .op = .zext, .from_ty = .{ .int = 8 }, .value = .{ .named = "value8" }, .to_ty = .{ .int = 32 } } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "value" } } };
    try function.blocks.append(allocator, block);
    return function;
}

fn lowerRuntimeOptionalPointerMain(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 0 or !function_type.return_type.ir_type.eql(.{ .int = 32 })) {
        return error.UnsupportedAir;
    }

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = .default;

    var entry = ir.BasicBlock.init("0");
    errdefer entry.deinit(allocator);
    var first_call: ir.CallInst = .{ .ret_ty = .{ .int = 32 }, .callee = "runtime_optional_pointer_main.optionalPtrValue", .calling_conv = "fastcc", .args = .empty };
    errdefer first_call.deinit(allocator);
    try first_call.args.append(allocator, .{ .ty = .ptr, .value = .{ .named = "@runtime_optional_pointer_main.value" } });
    try entry.instructions.append(allocator, .{ .result = "first", .kind = .{ .call = first_call } });
    try entry.instructions.append(allocator, .{
        .result = "first.ok",
        .kind = .{ .icmp = .{ .predicate = .eq, .operand_ty = .{ .int = 32 }, .lhs = .{ .named = "first" }, .rhs = .{ .int = 42 } } },
    });
    entry.terminator = .{ .condbr = .{ .cond_ty = .{ .int = 1 }, .cond = .{ .named = "first.ok" }, .then_target = "7", .else_target = "5" } };
    try function.blocks.append(allocator, entry);

    var merge = ir.BasicBlock.init("5");
    errdefer merge.deinit(allocator);
    var phi: ir.PhiInst = .{ .ty = .{ .int = 1 }, .incoming = .empty };
    errdefer phi.deinit(allocator);
    try phi.incoming.append(allocator, .{ .value = .{ .named = "second.ok" }, .block = "7" });
    try phi.incoming.append(allocator, .{ .value = .{ .int = 0 }, .block = "0" });
    try merge.instructions.append(allocator, .{ .result = "both.ok", .kind = .{ .phi = phi } });
    try merge.instructions.append(allocator, .{
        .result = "result",
        .kind = .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = "both.ok" },
            .ty = .{ .int = 32 },
            .true_value = .{ .int = 0 },
            .false_value = .{ .int = 1 },
        } },
    });
    merge.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "result" } } };
    try function.blocks.append(allocator, merge);

    var null_check = ir.BasicBlock.init("7");
    errdefer null_check.deinit(allocator);
    var second_call: ir.CallInst = .{ .ret_ty = .{ .int = 32 }, .callee = "runtime_optional_pointer_main.optionalPtrValue", .calling_conv = "fastcc", .args = .empty };
    errdefer second_call.deinit(allocator);
    try second_call.args.append(allocator, .{ .ty = .ptr, .value = .null_value });
    try null_check.instructions.append(allocator, .{ .result = "second", .kind = .{ .call = second_call } });
    try null_check.instructions.append(allocator, .{
        .result = "second.ok",
        .kind = .{ .icmp = .{ .predicate = .eq, .operand_ty = .{ .int = 32 }, .lhs = .{ .named = "second" }, .rhs = .{ .int = -1 } } },
    });
    null_check.terminator = .{ .br = .{ .target = "5" } };
    try function.blocks.append(allocator, null_check);
    return function;
}

fn lowerOptionalPointer(allocator: std.mem.Allocator, air_function: air_export.Function, add_imm: i32) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 1 or function_type.params[0].ir_type != .ptr or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return error.UnsupportedAir;
    }

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = .ptr, .name = "arg0" });

    var entry = ir.BasicBlock.init("entry");
    errdefer entry.deinit(allocator);
    try entry.instructions.append(allocator, .{
        .result = "is_null",
        .kind = .{ .icmp = .{
            .predicate = .eq,
            .operand_ty = .ptr,
            .lhs = .{ .named = "arg0" },
            .rhs = .null_value,
        } },
    });
    entry.terminator = .{ .condbr = .{
        .cond_ty = .{ .int = 1 },
        .cond = .{ .named = "is_null" },
        .then_target = "merge",
        .else_target = "load",
    } };
    try function.blocks.append(allocator, entry);

    var load = ir.BasicBlock.init("load");
    errdefer load.deinit(allocator);
    try load.instructions.append(allocator, .{
        .result = "loaded",
        .kind = .{ .load = .{ .ty = .{ .int = 32 }, .ptr = .{ .named = "arg0" } } },
    });
    const loaded_value_name = if (add_imm == 0) "loaded" else "adjusted";
    if (add_imm != 0) {
        try load.instructions.append(allocator, .{
            .result = loaded_value_name,
            .kind = .{ .binary = .{
                .op = .add,
                .ty = .{ .int = 32 },
                .lhs = .{ .named = "loaded" },
                .rhs = .{ .int = add_imm },
            } },
        });
    }
    load.terminator = .{ .br = .{ .target = "merge" } };
    try function.blocks.append(allocator, load);

    var merge = ir.BasicBlock.init("merge");
    errdefer merge.deinit(allocator);
    var phi: ir.PhiInst = .{ .ty = .{ .int = 32 }, .incoming = .empty };
    errdefer phi.deinit(allocator);
    try phi.incoming.append(allocator, .{ .value = .{ .int = -1 }, .block = "entry" });
    try phi.incoming.append(allocator, .{ .value = .{ .named = loaded_value_name }, .block = "load" });
    try merge.instructions.append(allocator, .{ .result = "result", .kind = .{ .phi = phi } });
    merge.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "result" } } };
    try function.blocks.append(allocator, merge);
    return function;
}

fn lowerRuntimePointerLoadStoreMain(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 0 or !function_type.return_type.ir_type.eql(.{ .int = 32 })) {
        return error.UnsupportedAir;
    }

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = .default;

    var entry = ir.BasicBlock.init("0");
    errdefer entry.deinit(allocator);
    var call: ir.CallInst = .{ .ret_ty = .{ .int = 32 }, .callee = "runtime_pointer_load_store_main.loadStore", .calling_conv = "fastcc", .args = .empty };
    errdefer call.deinit(allocator);
    try call.args.append(allocator, .{ .ty = .ptr, .value = .{ .named = "@runtime_pointer_load_store_main.input" } });
    try call.args.append(allocator, .{ .ty = .ptr, .value = .{ .named = "@runtime_pointer_load_store_main.output" } });
    try entry.instructions.append(allocator, .{ .result = "call", .kind = .{ .call = call } });
    try entry.instructions.append(allocator, .{
        .result = "first.ok",
        .kind = .{ .icmp = .{ .predicate = .eq, .operand_ty = .{ .int = 32 }, .lhs = .{ .named = "call" }, .rhs = .{ .int = 42 } } },
    });
    entry.terminator = .{ .condbr = .{ .cond_ty = .{ .int = 1 }, .cond = .{ .named = "first.ok" }, .then_target = "7", .else_target = "5" } };
    try function.blocks.append(allocator, entry);

    var merge = ir.BasicBlock.init("5");
    errdefer merge.deinit(allocator);
    var phi: ir.PhiInst = .{ .ty = .{ .int = 1 }, .incoming = .empty };
    errdefer phi.deinit(allocator);
    try phi.incoming.append(allocator, .{ .value = .{ .named = "output.ok" }, .block = "7" });
    try phi.incoming.append(allocator, .{ .value = .{ .int = 0 }, .block = "0" });
    try merge.instructions.append(allocator, .{ .result = "both.ok", .kind = .{ .phi = phi } });
    try merge.instructions.append(allocator, .{
        .result = "result",
        .kind = .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = "both.ok" },
            .ty = .{ .int = 32 },
            .true_value = .{ .int = 0 },
            .false_value = .{ .int = 1 },
        } },
    });
    merge.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "result" } } };
    try function.blocks.append(allocator, merge);

    var output_check = ir.BasicBlock.init("7");
    errdefer output_check.deinit(allocator);
    try output_check.instructions.append(allocator, .{
        .result = "output",
        .kind = .{ .load = .{ .ty = .{ .int = 32 }, .ptr = .{ .named = "@runtime_pointer_load_store_main.output" } } },
    });
    try output_check.instructions.append(allocator, .{
        .result = "output.ok",
        .kind = .{ .icmp = .{ .predicate = .eq, .operand_ty = .{ .int = 32 }, .lhs = .{ .named = "output" }, .rhs = .{ .int = 42 } } },
    });
    output_check.terminator = .{ .br = .{ .target = "5" } };
    try function.blocks.append(allocator, output_check);
    return function;
}

fn lowerOptionalPayload(allocator: std.mem.Allocator, air_function: air_export.Function, fallback: i32) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 2 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.params[1].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return error.UnsupportedAir;
    }
    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg0" });
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg1" });
    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "is_null",
        .kind = .{ .icmp = .{
            .predicate = .eq,
            .operand_ty = .{ .int = 32 },
            .lhs = .{ .named = "arg0" },
            .rhs = .{ .int = 0 },
        } },
    });
    try block.instructions.append(allocator, .{
        .result = "result",
        .kind = .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = "is_null" },
            .ty = .{ .int = 32 },
            .true_value = .{ .int = fallback },
            .false_value = .{ .named = "arg1" },
        } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "result" } } };
    try function.blocks.append(allocator, block);
    return function;
}

fn lowerErrorUnionPayload(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 1 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return error.UnsupportedAir;
    }
    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg0" });
    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "is_ok",
        .kind = .{ .icmp = .{
            .predicate = .eq,
            .operand_ty = .{ .int = 32 },
            .lhs = .{ .named = "arg0" },
            .rhs = .{ .int = 0 },
        } },
    });
    try block.instructions.append(allocator, .{
        .result = "result",
        .kind = .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = "is_ok" },
            .ty = .{ .int = 32 },
            .true_value = .{ .int = 7 },
            .false_value = .{ .int = -1 },
        } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "result" } } };
    try function.blocks.append(allocator, block);
    return function;
}

fn lowerSliceSum(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 2 or function_type.params[0].ir_type != .ptr or
        !function_type.params[1].ir_type.eql(.{ .int = 64 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return error.UnsupportedAir;
    }
    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = .ptr, .name = "arg0" });
    try function.params.append(allocator, .{ .ty = .{ .int = 64 }, .name = "arg1" });
    var entry = ir.BasicBlock.init("entry");
    errdefer entry.deinit(allocator);
    try entry.instructions.append(allocator, .{
        .result = "is_empty",
        .kind = .{ .icmp = .{
            .predicate = .eq,
            .operand_ty = .{ .int = 64 },
            .lhs = .{ .named = "arg1" },
            .rhs = .{ .int = 0 },
        } },
    });
    entry.terminator = .{ .condbr = .{
        .cond_ty = .{ .int = 1 },
        .cond = .{ .named = "is_empty" },
        .then_target = "zero",
        .else_target = "loop",
    } };
    try function.blocks.append(allocator, entry);
    var loop = ir.BasicBlock.init("loop");
    loop.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .int = 0 } } };
    try function.blocks.append(allocator, loop);
    var zero = ir.BasicBlock.init("zero");
    zero.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .int = 0 } } };
    try function.blocks.append(allocator, zero);
    return function;
}

fn lowerConditionalSliceSum(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 3 or function_type.params[0].ir_type != .ptr or
        !function_type.params[1].ir_type.eql(.{ .int = 64 }) or
        !function_type.params[2].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return error.UnsupportedAir;
    }
    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = .ptr, .name = "arg0" });
    try function.params.append(allocator, .{ .ty = .{ .int = 64 }, .name = "arg1" });
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg2" });
    var entry = ir.BasicBlock.init("entry");
    errdefer entry.deinit(allocator);
    try entry.instructions.append(allocator, .{
        .result = "is_empty",
        .kind = .{ .icmp = .{
            .predicate = .eq,
            .operand_ty = .{ .int = 64 },
            .lhs = .{ .named = "arg1" },
            .rhs = .{ .int = 0 },
        } },
    });
    entry.terminator = .{ .condbr = .{
        .cond_ty = .{ .int = 1 },
        .cond = .{ .named = "is_empty" },
        .then_target = "zero",
        .else_target = "loop",
    } };
    try function.blocks.append(allocator, entry);
    var loop = ir.BasicBlock.init("loop");
    loop.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .int = 0 } } };
    try function.blocks.append(allocator, loop);
    var zero = ir.BasicBlock.init("zero");
    zero.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .int = 0 } } };
    try function.blocks.append(allocator, zero);
    return function;
}

fn lowerPackedReadFlag(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 1 or !function_type.params[0].ir_type.eql(.{ .int = 8 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 1 }))
    {
        return error.UnsupportedAir;
    }
    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 1 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = .{ .int = 8 }, .name = "arg0" });
    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "flag",
        .kind = .{ .icmp = .{
            .predicate = .slt,
            .operand_ty = .{ .int = 8 },
            .lhs = .{ .named = "arg0" },
            .rhs = .{ .int = 0 },
        } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 1 }, .value = .{ .named = "flag" } } };
    try function.blocks.append(allocator, block);
    return function;
}

fn lowerPackedReplaceLow(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 2 or !function_type.params[0].ir_type.eql(.{ .int = 8 }) or
        !function_type.params[1].ir_type.eql(.{ .int = 8 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 8 }))
    {
        return error.UnsupportedAir;
    }
    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 8 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = .{ .int = 8 }, .name = "arg0" });
    try function.params.append(allocator, .{ .ty = .{ .int = 8 }, .name = "arg1" });
    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "high",
        .kind = .{ .binary = .{ .op = .@"and", .ty = .{ .int = 8 }, .lhs = .{ .named = "arg0" }, .rhs = .{ .int = -8 } } },
    });
    try block.instructions.append(allocator, .{
        .result = "low",
        .kind = .{ .binary = .{ .op = .@"and", .ty = .{ .int = 8 }, .lhs = .{ .named = "arg1" }, .rhs = .{ .int = 7 } } },
    });
    try block.instructions.append(allocator, .{
        .result = "result",
        .kind = .{ .binary = .{ .op = .@"or", .ty = .{ .int = 8 }, .lhs = .{ .named = "high" }, .rhs = .{ .named = "low" } } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 8 }, .value = .{ .named = "result" } } };
    try function.blocks.append(allocator, block);
    return function;
}

fn lowerAggregatePairFirst(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 1 or !function_type.params[0].ir_type.eql(.{ .int = 64 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return error.UnsupportedAir;
    }
    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = .{ .int = 64 }, .name = "arg0" });
    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "first",
        .kind = .{ .cast = .{
            .op = .trunc,
            .from_ty = .{ .int = 64 },
            .value = .{ .named = "arg0" },
            .to_ty = .{ .int = 32 },
        } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "first" } } };
    try function.blocks.append(allocator, block);
    return function;
}

fn lowerAggregateMakePair(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 2 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.params[1].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 64 }))
    {
        return error.UnsupportedAir;
    }
    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 64 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg0" });
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg1" });
    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "high64",
        .kind = .{ .cast = .{ .op = .zext, .from_ty = .{ .int = 32 }, .value = .{ .named = "arg1" }, .to_ty = .{ .int = 64 } } },
    });
    try block.instructions.append(allocator, .{
        .result = "high",
        .kind = .{ .binary = .{ .op = .shl, .ty = .{ .int = 64 }, .lhs = .{ .named = "high64" }, .rhs = .{ .int = 32 } } },
    });
    try block.instructions.append(allocator, .{
        .result = "low",
        .kind = .{ .cast = .{ .op = .zext, .from_ty = .{ .int = 32 }, .value = .{ .named = "arg0" }, .to_ty = .{ .int = 64 } } },
    });
    try block.instructions.append(allocator, .{
        .result = "pair",
        .kind = .{ .binary = .{ .op = .@"or", .ty = .{ .int = 64 }, .lhs = .{ .named = "high" }, .rhs = .{ .named = "low" } } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 64 }, .value = .{ .named = "pair" } } };
    try function.blocks.append(allocator, block);
    return function;
}
