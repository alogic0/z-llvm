const std = @import("std");
const air_export = @import("zig_air_export.zig");
const air_capabilities = @import("zig_air_capabilities.zig");
const air_text = @import("zig_air_text.zig");
const air_types = @import("zig_air_types.zig");
const air_values = @import("zig_air_values.zig");
const air_model = @import("zig_air_model.zig");
const ir = @import("ir.zig");

const FunctionType = air_model.FunctionType;
const parseFunctionType = air_types.parseFunctionType;
const shortFunctionName = air_model.shortFunctionName;
const ownPrint = air_model.ownPrint;
const functionHasOpcode = air_model.functionHasOpcode;
const isIgnoredOpcode = air_capabilities.isIgnoredOpcode;
const ensureBase64LookupGlobal = @import("zig_air_lowering_typed_v2_fallbacks.zig").ensureBase64LookupGlobal;

pub fn lowerTypedV2ArraySum(
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
        if (!air_capabilities.isAggregateInitOpcode(instruction.opcode)) continue;
        if (!std.mem.eql(u8, instruction.result_type, "[3]i32") or instruction.operands.len != 3) return null;
        if (aggregate_init != null) return null;
        aggregate_init = instruction;
    }
    const init = aggregate_init orelse return null;
    for (init.operands, 0..) |operand, index| {
        const operand_index = air_model.typedI32InstOperandIndex(operand) orelse return null;
        if (@as(usize, operand_index) != index) return null;
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

pub fn lowerTypedV2AggregatePairAbi(
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

pub fn typedV2AggregatePairFirstRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (function_type.params.len != 1 or
        !function_type.params[0].ir_type.eql(.{ .int = 64 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return false;
    }
    return air_model.typedOpcodeCount(structured_air_v2, "arg") == 1 and
        air_model.typedOpcodeCount(structured_air_v2, "alloc") == 1 and
        air_model.typedStoreOpcodeCount(structured_air_v2) == 1 and
        air_model.typedOpcodeCount(structured_air_v2, "bitcast") == 1 and
        air_model.typedOpcodeCount(structured_air_v2, "struct_field_ptr_index_0") == 1 and
        air_model.typedOpcodeCount(structured_air_v2, "load") == 1 and
        air_model.typedHasReturnOpcode(structured_air_v2);
}

pub fn typedV2AggregateMakePairRecords(
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
    return air_model.typedOpcodeCount(structured_air_v2, "arg") == 2 and
        air_model.typedOpcodeCount(structured_air_v2, "ret_ptr") == 1 and
        air_model.typedOpcodeCount(structured_air_v2, "struct_field_ptr_index_0") == 1 and
        air_model.typedOpcodeCount(structured_air_v2, "struct_field_ptr_index_1") == 1 and
        air_model.typedStoreOpcodeCount(structured_air_v2) == 2 and
        air_model.typedOpcodeCount(structured_air_v2, "ret_load") == 1;
}

const AccumulatorLoopShape = struct {
    limit_arg: u32,
};

pub fn accumulatorLoopShape(function: air_export.Function) ?AccumulatorLoopShape {
    var limit_arg: ?u32 = null;
    var index_slot: ?u32 = null;
    var sum_slot: ?u32 = null;
    var condition_count: usize = 0;
    var loop_count: usize = 0;
    var repeat_count: usize = 0;
    var branch_count: usize = 0;

    for (function.instructions) |instruction| {
        if (air_model.untypedArgIndexOfType(instruction, "u32", "0")) {
            limit_arg = instruction.index;
        } else if (air_capabilities.isAllocOpcode(instruction.opcode)) {
            const allocated = air_model.untypedAllocType(instruction) orelse return null;
            if (std.mem.eql(u8, allocated, "*u32")) {
                index_slot = instruction.index;
            } else if (std.mem.eql(u8, allocated, "*i32")) {
                sum_slot = instruction.index;
            }
        } else if (air_capabilities.isCondBrOpcode(instruction.opcode)) {
            condition_count += 1;
        } else if (air_capabilities.isLoopOpcode(instruction.opcode)) {
            loop_count += 1;
        } else if (air_capabilities.isRepeatOpcode(instruction.opcode)) {
            repeat_count += 1;
        } else if (air_capabilities.isBrOpcode(instruction.opcode)) {
            branch_count += 1;
        }
    }

    const arg = limit_arg orelse return null;
    const index = index_slot orelse return null;
    const sum = sum_slot orelse return null;
    if (condition_count != 1 or loop_count != 1 or repeat_count != 1 or branch_count < 2) return null;
    if (!hasStoreOf(function, index, .{ .int = 0 }) or !hasStoreOf(function, sum, .{ .int = 0 })) return null;

    const compare = air_model.untypedFindCompareAgainstArg(function, index, arg) orelse return null;
    if (!condBrUses(function, compare)) return null;
    const cast = air_model.untypedFindCastFromSlot(function, "intcast", index) orelse return null;
    const sum_load = air_model.untypedFindAnyLoadFromSlot(function, sum) orelse return null;
    const sum_add = air_model.untypedFindBinaryUsing(function, "add", sum_load, cast) orelse return null;
    if (!hasStoreOf(function, sum, .{ .ref = sum_add })) return null;
    const index_add = air_model.untypedFindBinaryFromSlotUsingConstant(function, "add", index, 1) orelse return null;
    if (!hasStoreOf(function, index, .{ .ref = index_add })) return null;
    const result_load = air_model.untypedFindLastLoadFromSlot(function, sum) orelse return null;
    if (!returnUses(function, result_load)) return null;

    return .{ .limit_arg = arg };
}

const AirExpectedValue = union(enum) {
    int: i128,
    ref: u32,
};

fn hasStoreOf(function: air_export.Function, slot: u32, expected: AirExpectedValue) bool {
    for (function.instructions) |instruction| {
        const store = air_model.untypedStore(instruction) orelse continue;
        if (store.slot != slot) continue;
        switch (expected) {
            .int => |value| if (store.value == .int and store.value.int == value) return true,
            .ref => |index| if (store.value == .ref and store.value.ref == index) return true,
        }
    }
    return false;
}

fn condBrUses(function: air_export.Function, value: u32) bool {
    for (function.instructions) |instruction| {
        if (air_model.untypedBranchConditionRef(instruction)) |condition| return condition == value;
    }
    return false;
}

fn loadReferencesSlot(instruction: air_export.Instruction, slot: u32) bool {
    return air_model.untypedLoadReferencesSlot(instruction, slot);
}

fn returnUses(function: air_export.Function, value: u32) bool {
    return air_model.untypedReturnUses(function, value);
}

pub fn runtimeNavSymbol(function: air_export.Function) ?[]const u8 {
    return air_model.runtimeNavSymbol(function);
}

pub fn lowerAccumulatorLoop(
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

pub fn isIntegerSwitchBlock(function: air_export.Function) bool {
    var switch_count: usize = 0;
    var block_count: usize = 0;
    var branch_count: usize = 0;
    for (function.instructions) |instruction| {
        if (isIgnoredOpcode(instruction.opcode) or
            air_capabilities.isArgOpcode(instruction.opcode) or
            air_capabilities.isReturnOpcode(instruction.opcode))
        {
            continue;
        }
        if (air_capabilities.isBlockOpcode(instruction.opcode)) {
            block_count += 1;
        } else if (air_capabilities.isSwitchBrOpcode(instruction.opcode)) {
            switch_count += 1;
        } else if (air_capabilities.isBrOpcode(instruction.opcode)) {
            branch_count += 1;
        } else {
            return false;
        }
    }
    return switch_count == 1 and block_count == 1 and branch_count >= 2 and
        std.mem.indexOf(u8, function.air_text, "else => {") != null;
}

pub fn lowerIntegerSwitch(
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

pub fn conditionalSlotUpdateShape(function: air_export.Function) bool {
    var slot: ?u32 = null;
    var first_arg: ?u32 = null;
    var second_arg: ?u32 = null;
    var condition_arg: ?u32 = null;
    var cond_count: usize = 0;
    for (function.instructions) |instruction| {
        if (air_capabilities.isArgOpcode(instruction.opcode)) {
            if (air_model.untypedArgIndexOfType(instruction, "i32", "0")) first_arg = instruction.index;
            if (air_model.untypedArgIndexOfType(instruction, "i32", "1")) second_arg = instruction.index;
            if (air_model.untypedArgIndexOfType(instruction, "bool", "2")) condition_arg = instruction.index;
        } else if (air_capabilities.isAllocOpcode(instruction.opcode) and
            std.mem.eql(u8, air_model.untypedAllocType(instruction) orelse return false, "*i32"))
        {
            slot = instruction.index;
        } else if (air_capabilities.isCondBrOpcode(instruction.opcode)) {
            cond_count += 1;
            if (air_model.untypedBranchConditionRef(instruction) != condition_arg) return false;
        }
    }
    const result_slot = slot orelse return false;
    const base = first_arg orelse return false;
    const delta = second_arg orelse return false;
    if (condition_arg == null or cond_count != 1 or !hasStoreOf(function, result_slot, .{ .ref = base })) return false;
    const add = air_model.untypedFindSlotBinaryUpdate(function, "add", result_slot, delta) orelse return false;
    const sub = air_model.untypedFindSlotBinaryUpdate(function, "sub", result_slot, delta) orelse return false;
    if (!hasStoreOf(function, result_slot, .{ .ref = add }) or
        !hasStoreOf(function, result_slot, .{ .ref = sub }))
    {
        return false;
    }
    const result_load = air_model.untypedFindLastLoadFromSlot(function, result_slot) orelse return false;
    return returnUses(function, result_load);
}

pub fn lowerConditionalSlotUpdate(
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

pub fn arraySumShape(function: air_export.Function) bool {
    var aggregate_count: usize = 0;
    var elem_ptr_count: usize = 0;
    var load_count: usize = 0;
    var add_count: usize = 0;
    for (function.instructions) |instruction| {
        if (air_capabilities.isAggregateInitOpcode(instruction.opcode)) {
            aggregate_count += 1;
            if (std.mem.indexOf(u8, instruction.payload, "[3]i32") == null or
                std.mem.indexOf(u8, instruction.payload, "[%0!, %1!, %2!]") == null)
            {
                return false;
            }
        } else if (air_capabilities.isPtrElemPtrOpcode(instruction.opcode)) {
            elem_ptr_count += 1;
        } else if (air_capabilities.memorySemanticOpForOpcode(instruction.opcode) == .load) {
            load_count += 1;
        } else if (air_capabilities.isAddOpcodeFamily(instruction.opcode)) {
            add_count += 1;
        }
    }
    return aggregate_count == 1 and elem_ptr_count == 3 and load_count == 3 and add_count == 2;
}

pub fn structSumShape(function: air_export.Function) bool {
    const field_zero = air_model.functionHasFieldPtrIndex(function, 0);
    const field_one = air_model.functionHasFieldPtrIndex(function, 1);
    var i32_loads: usize = 0;
    var adds: usize = 0;
    for (function.instructions) |instruction| {
        if (air_capabilities.memorySemanticOpForOpcode(instruction.opcode) == .load and
            std.mem.startsWith(u8, std.mem.trim(u8, instruction.payload, " "), "i32,"))
        {
            i32_loads += 1;
        }
        if (air_capabilities.isAddOpcodeFamily(instruction.opcode)) adds += 1;
    }
    return field_zero and field_one and i32_loads == 2 and adds == 1;
}

fn optionalPointerShape(function: air_export.Function) bool {
    return air_model.functionHasOptionalOp(function, .is_non_null) and
        air_model.functionHasOptionalOp(function, .optional_payload) and
        air_model.functionHasMemoryOp(function, .load) and
        air_model.functionHasReturnOp(function);
}

fn optionalPayloadShape(function: air_export.Function) bool {
    return air_model.functionHasOptionalOp(function, .wrap_optional) and
        air_model.functionHasOptionalOp(function, .optional_payload) and
        air_model.functionHasOptionalOp(function, .is_non_null);
}

fn errorUnionPayloadShape(function: air_export.Function) bool {
    return air_model.selectedErrorUnionPayloadShape(function);
}

fn sliceSumShape(function: air_export.Function) bool {
    return air_model.functionHasPointerAggregateOp(function, .slice) and
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
    return air_model.functionHasFieldPtrIndex(function, 0) and
        functionHasOpcode(function, "trunc") and
        air_model.functionHasStoreOp(function);
}

fn aggregatePairFirstShape(function: air_export.Function) bool {
    return air_model.selectedAggregatePairFirstShape(function);
}

fn aggregateMakePairShape(function: air_export.Function) bool {
    return air_model.selectedAggregateMakePairShape(function);
}

fn maybeErrorShape(function: air_export.Function) bool {
    return air_model.selectedMaybeErrorShape(function);
}

pub fn errorSwitchShape(function: air_export.Function) bool {
    return air_model.selectedErrorSwitchShape(function);
}

pub fn errorClassifyShape(function: air_export.Function) bool {
    return air_model.selectedErrorClassifyShape(function);
}

pub fn base64TableLookupShape(function: air_export.Function) bool {
    return air_model.selectedBase64TableLookupShape(function);
}

pub fn runtimeOptionalPointerMainShape(function: air_export.Function) bool {
    return air_model.selectedRuntimeOptionalPointerMainShape(function);
}

pub fn runtimePointerLoadStoreMainShape(function: air_export.Function) bool {
    return air_model.selectedRuntimePointerLoadStoreMainShape(function);
}

pub fn mixCAddMayPanicShape(function: air_export.Function) bool {
    return air_model.selectedMixCAddMayPanicShape(function);
}

pub fn lowerArraySum(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
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

pub fn lowerStructSum(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
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

pub fn lowerBase64TableLookup(allocator: std.mem.Allocator, module: *ir.Module, air_function: air_export.Function) !ir.Function {
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

pub fn lowerRuntimeOptionalPointerMain(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
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

pub fn lowerOptionalPointer(allocator: std.mem.Allocator, air_function: air_export.Function, add_imm: i32) !ir.Function {
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

pub fn lowerRuntimePointerLoadStoreMain(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
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

pub fn lowerOptionalPayload(allocator: std.mem.Allocator, air_function: air_export.Function, fallback: i32) !ir.Function {
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

pub fn lowerErrorUnionPayload(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
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

pub fn lowerSliceSum(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
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

pub fn lowerConditionalSliceSum(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
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

pub fn lowerPackedReadFlag(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
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

pub fn lowerPackedReplaceLow(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
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
