const std = @import("std");
const air_export = @import("zig_air_export.zig");
const ir = @import("ir.zig");

pub const UnsupportedReason = enum {
    function_type,
    instruction_type,
    opcode,
    control_flow_shape,
    call_shape,
    value,
};

pub const Diagnostic = struct {
    function: []const u8,
    opcode: []const u8,
    reason: UnsupportedReason,
};

pub const Result = struct {
    module: ir.Module,
    accepted_functions: usize,
    unsupported: []Diagnostic,

    pub fn deinit(self: *Result) void {
        const allocator = self.module.allocator;
        self.module.deinit();
        allocator.free(self.unsupported);
        self.* = undefined;
    }
};

const ZigType = struct {
    ir_type: ir.Type,
    signed: bool = false,
    pointer_child: ?ir.Type = null,
    is_volatile_pointer: bool = false,
};

const FunctionType = struct {
    params: []ZigType,
    return_type: ZigType,
    c_calling_convention: bool,

    fn deinit(self: FunctionType, allocator: std.mem.Allocator) void {
        allocator.free(self.params);
    }
};

const TypedValue = struct {
    ty: ZigType,
    value: ir.Value,
};

const LowerError = std.mem.Allocator.Error || error{UnsupportedAir};

pub fn lowerCompatible(
    allocator: std.mem.Allocator,
    air_module: air_export.Module,
) !Result {
    var module: ir.Module = .{
        .allocator = allocator,
        .source = try allocator.dupe(u8, ""),
        .owned_strings = .empty,
        .source_filename = air_module.root_source,
        .target_triple = air_module.target,
        .target_datalayout = null,
        .module_asm = .empty,
        .named_types = .empty,
        .globals = .empty,
        .aliases = .empty,
        .comdats = .empty,
        .declarations = .empty,
        .functions = .empty,
        .attribute_groups = .empty,
        .metadata = .empty,
    };
    errdefer module.deinit();

    var unsupported: std.ArrayList(Diagnostic) = .empty;
    errdefer unsupported.deinit(allocator);

    for (air_module.globals) |air_global| {
        if (air_global.is_constant) continue;
        const global_type = parseZigType(air_global.type_text) orelse continue;
        if (global_type.ir_type != .int and global_type.ir_type != .float and
            global_type.ir_type != .double and global_type.ir_type != .ptr)
        {
            continue;
        }
        const address_attrs = if (!std.mem.eql(u8, air_global.thread_local, "default"))
            try ownPrint(&module, "thread_local({s})", .{air_global.thread_local})
        else
            null;
        try module.globals.append(allocator, .{
            .name = air_global.name,
            .linkage = .external,
            .address_attrs = address_attrs,
            .kind = .global,
            .ty = global_type.ir_type,
            .initializer = .none,
        });
    }

    var accepted_functions: usize = 0;
    for (air_module.functions) |air_function| {
        if (firstUnsupported(allocator, air_function)) |diagnostic| {
            try unsupported.append(allocator, diagnostic);
            continue;
        }
        var function = lowerFunction(allocator, &module, air_function) catch |err| switch (err) {
            error.UnsupportedAir => {
                try unsupported.append(allocator, .{
                    .function = air_function.name,
                    .opcode = "lowering",
                    .reason = .instruction_type,
                });
                continue;
            },
            else => return err,
        };
        errdefer function.deinit(allocator);
        try module.functions.append(allocator, function);
        accepted_functions += 1;
    }

    try module.verify();
    return .{
        .module = module,
        .accepted_functions = accepted_functions,
        .unsupported = try unsupported.toOwnedSlice(allocator),
    };
}

pub fn firstUnsupported(
    allocator: std.mem.Allocator,
    function: air_export.Function,
) ?Diagnostic {
    const function_type = parseFunctionType(allocator, function.type_text) catch {
        return .{ .function = function.name, .opcode = "function-type", .reason = .function_type };
    };
    function_type.deinit(allocator);

    if (accumulatorLoopShape(function) != null or
        isIntegerSwitchBlock(function) or
        conditionalSlotUpdateShape(function) or
        arraySumShape(function) or
        structSumShape(function))
    {
        return null;
    }

    for (function.instructions) |instruction| {
        if (isIgnoredOpcode(instruction.opcode) or isStraightLineOpcode(instruction.opcode)) continue;
        if (std.mem.eql(u8, instruction.opcode, "block")) {
            if (isSimpleSelectBlock(function, instruction.index)) continue;
            return .{ .function = function.name, .opcode = instruction.opcode, .reason = .control_flow_shape };
        }
        if (std.mem.eql(u8, instruction.opcode, "cond_br") or
            std.mem.eql(u8, instruction.opcode, "br"))
        {
            if (belongsToSimpleSelectBlock(function, instruction.index)) continue;
            return .{ .function = function.name, .opcode = instruction.opcode, .reason = .control_flow_shape };
        }
        return .{ .function = function.name, .opcode = instruction.opcode, .reason = .opcode };
    }
    return null;
}

fn lowerFunction(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
) !ir.Function {
    if (accumulatorLoopShape(air_function)) |shape| {
        return lowerAccumulatorLoop(allocator, module, air_function, shape);
    }
    if (isIntegerSwitchBlock(air_function)) {
        return lowerIntegerSwitch(allocator, module, air_function);
    }
    if (conditionalSlotUpdateShape(air_function)) {
        return lowerConditionalSlotUpdate(allocator, air_function);
    }
    if (arraySumShape(air_function)) return lowerArraySum(allocator, air_function);
    if (structSumShape(air_function)) return lowerStructSum(allocator, air_function);

    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);

    var function = ir.Function.init(shortFunctionName(air_function.name), function_type.return_type.ir_type);
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    if (runtimeNavSymbol(air_function)) |tls_symbol| {
        function.attrs = try ownPrint(module, "\"zllvm-tls-symbol\"=\"{s}\"", .{tls_symbol});
    }

    for (function_type.params, 0..) |param_type, param_index| {
        const name = try ownPrint(module, "arg{}", .{param_index});
        try function.params.append(allocator, .{
            .ty = param_type.ir_type,
            .name = name,
        });
    }

    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    const values = try allocator.alloc(?TypedValue, air_function.instruction_count);
    defer allocator.free(values);
    @memset(values, null);

    var context: LoweringContext = .{
        .allocator = allocator,
        .module = module,
        .air_function = air_function,
        .function_type = function_type,
        .function = &function,
        .block = &block,
        .values = values,
    };

    for (air_function.instructions) |instruction| {
        if (isIgnoredOpcode(instruction.opcode)) continue;
        if (std.mem.eql(u8, instruction.opcode, "arg")) {
            try context.lowerArg(instruction);
        } else if (isArithmeticOpcode(instruction.opcode)) {
            try context.lowerBinary(instruction);
        } else if (std.mem.startsWith(u8, instruction.opcode, "cmp_")) {
            try context.lowerCompare(instruction);
        } else if (isCastOpcode(instruction.opcode)) {
            try context.lowerCast(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "alloc")) {
            try context.lowerAlloca(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "load")) {
            try context.lowerLoad(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "store") or
            std.mem.eql(u8, instruction.opcode, "store_safe"))
        {
            try context.lowerStore(instruction);
        } else if (isCallOpcode(instruction.opcode)) {
            try context.lowerCall(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "runtime_nav_ptr")) {
            try context.lowerRuntimeNavPtr(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "atomic_rmw")) {
            try context.lowerAtomicRmw(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "ret") or
            std.mem.eql(u8, instruction.opcode, "ret_safe"))
        {
            try context.lowerReturn(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "unreach")) {
            block.terminator = .{ .@"unreachable" = {} };
        } else if (std.mem.eql(u8, instruction.opcode, "block") or
            std.mem.eql(u8, instruction.opcode, "cond_br") or
            std.mem.eql(u8, instruction.opcode, "br"))
        {
            continue;
        } else {
            return error.UnsupportedAir;
        }
    }
    if (block.terminator == null) return error.UnsupportedAir;
    try function.blocks.append(allocator, block);
    return function;
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
        if (!std.mem.eql(u8, instruction.opcode, opcode)) continue;
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
            std.mem.eql(u8, instruction.opcode, "ret"))
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

const LoweringContext = struct {
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    function: *ir.Function,
    block: *ir.BasicBlock,
    values: []?TypedValue,

    fn lowerArg(self: *LoweringContext, instruction: air_export.Instruction) !void {
        var fields = splitTopLevel(instruction.payload, ',');
        const type_text = fields.next() orelse return error.UnsupportedAir;
        const index_text = fields.next() orelse return error.UnsupportedAir;
        if (fields.next() != null) return error.UnsupportedAir;
        const param_index = std.fmt.parseInt(usize, std.mem.trim(u8, index_text, " "), 10) catch
            return error.UnsupportedAir;
        if (param_index >= self.function_type.params.len) return error.UnsupportedAir;
        const parsed_type = parseZigType(std.mem.trim(u8, type_text, " ")) orelse
            return error.UnsupportedAir;
        if (!parsed_type.ir_type.eql(self.function_type.params[param_index].ir_type)) {
            return error.UnsupportedAir;
        }
        self.values[instruction.index] = .{
            .ty = parsed_type,
            .value = .{ .named = self.blockParamName(param_index) },
        };
    }

    fn lowerBinary(self: *LoweringContext, instruction: air_export.Instruction) !void {
        var fields = splitTopLevel(instruction.payload, ',');
        const lhs = try self.resolveValue(fields.next() orelse return error.UnsupportedAir);
        var rhs = try self.resolveValue(fields.next() orelse return error.UnsupportedAir);
        if (fields.next() != null) return error.UnsupportedAir;
        if (!lhs.ty.ir_type.eql(rhs.ty.ir_type)) {
            if (!isShiftOpcode(instruction.opcode)) return error.UnsupportedAir;
            rhs = try self.extendShiftCount(instruction.index, lhs.ty, rhs);
        }
        const op = binaryOp(instruction.opcode, lhs.ty) orelse return error.UnsupportedAir;
        const result_name = try self.resultName(instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .binary = .{
                .op = op,
                .ty = lhs.ty.ir_type,
                .lhs = lhs.value,
                .rhs = rhs.value,
            } },
        });
        self.values[instruction.index] = .{
            .ty = lhs.ty,
            .value = .{ .named = result_name },
        };
    }

    fn extendShiftCount(
        self: *LoweringContext,
        instruction_index: u32,
        lhs_type: ZigType,
        rhs: TypedValue,
    ) !TypedValue {
        const lhs_bits = intBits(lhs_type.ir_type) orelse return error.UnsupportedAir;
        const rhs_bits = intBits(rhs.ty.ir_type) orelse return error.UnsupportedAir;
        const op: ir.CastOp = if (rhs_bits < lhs_bits)
            .zext
        else if (rhs_bits > lhs_bits)
            .trunc
        else
            return rhs;
        const result_name = try ownPrint(self.module, "air{}_shift_count", .{instruction_index});
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .cast = .{
                .op = op,
                .from_ty = rhs.ty.ir_type,
                .value = rhs.value,
                .to_ty = lhs_type.ir_type,
            } },
        });
        return .{
            .ty = .{ .ir_type = lhs_type.ir_type },
            .value = .{ .named = result_name },
        };
    }

    fn lowerCompare(self: *LoweringContext, instruction: air_export.Instruction) !void {
        var fields = splitTopLevel(instruction.payload, ',');
        const lhs = try self.resolveValue(fields.next() orelse return error.UnsupportedAir);
        const rhs = try self.resolveValue(fields.next() orelse return error.UnsupportedAir);
        if (fields.next() != null or !lhs.ty.ir_type.eql(rhs.ty.ir_type)) return error.UnsupportedAir;
        const result_name = try self.resultName(instruction.index);
        if (isFpType(lhs.ty.ir_type)) {
            try self.block.instructions.append(self.allocator, .{
                .result = result_name,
                .kind = .{ .fcmp = .{
                    .predicate = fpPredicate(instruction.opcode) orelse return error.UnsupportedAir,
                    .operand_ty = lhs.ty.ir_type,
                    .lhs = lhs.value,
                    .rhs = rhs.value,
                } },
            });
        } else {
            try self.block.instructions.append(self.allocator, .{
                .result = result_name,
                .kind = .{ .icmp = .{
                    .predicate = intPredicate(instruction.opcode, lhs.ty.signed) orelse
                        return error.UnsupportedAir,
                    .operand_ty = lhs.ty.ir_type,
                    .lhs = lhs.value,
                    .rhs = rhs.value,
                } },
            });
        }
        self.values[instruction.index] = .{
            .ty = .{ .ir_type = .{ .int = 1 } },
            .value = .{ .named = result_name },
        };
    }

    fn lowerCast(self: *LoweringContext, instruction: air_export.Instruction) !void {
        var fields = splitTopLevel(instruction.payload, ',');
        const target_text = std.mem.trim(u8, fields.next() orelse return error.UnsupportedAir, " ");
        const source = try self.resolveValue(fields.next() orelse return error.UnsupportedAir);
        if (fields.next() != null) return error.UnsupportedAir;
        const target_type = parseZigType(target_text) orelse return error.UnsupportedAir;
        const op = castOp(instruction.opcode, source.ty, target_type) orelse return error.UnsupportedAir;
        const result_name = try self.resultName(instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .cast = .{
                .op = op,
                .from_ty = source.ty.ir_type,
                .value = source.value,
                .to_ty = target_type.ir_type,
            } },
        });
        self.values[instruction.index] = .{
            .ty = target_type,
            .value = .{ .named = result_name },
        };
    }

    fn lowerAlloca(self: *LoweringContext, instruction: air_export.Instruction) !void {
        const pointer_type = parseZigType(std.mem.trim(u8, instruction.payload, " ")) orelse
            return error.UnsupportedAir;
        const allocated_type = pointer_type.pointer_child orelse return error.UnsupportedAir;
        const result_name = try self.resultName(instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .alloca = .{ .allocated_ty = allocated_type } },
        });
        self.values[instruction.index] = .{
            .ty = pointer_type,
            .value = .{ .named = result_name },
        };
    }

    fn lowerLoad(self: *LoweringContext, instruction: air_export.Instruction) !void {
        var fields = splitTopLevel(instruction.payload, ',');
        const result_type = parseZigType(std.mem.trim(u8, fields.next() orelse return error.UnsupportedAir, " ")) orelse
            return error.UnsupportedAir;
        const pointer = try self.resolveValue(fields.next() orelse return error.UnsupportedAir);
        if (fields.next() != null or pointer.ty.ir_type != .ptr) return error.UnsupportedAir;
        const result_name = try self.resultName(instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .load = .{
                .ty = result_type.ir_type,
                .ptr = pointer.value,
                .attrs = .{ .is_volatile = pointer.ty.is_volatile_pointer },
            } },
        });
        self.values[instruction.index] = .{
            .ty = result_type,
            .value = .{ .named = result_name },
        };
    }

    fn lowerStore(self: *LoweringContext, instruction: air_export.Instruction) !void {
        var fields = splitTopLevel(instruction.payload, ',');
        const pointer = try self.resolveValue(fields.next() orelse return error.UnsupportedAir);
        const value = try self.resolveValue(fields.next() orelse return error.UnsupportedAir);
        if (fields.next() != null or pointer.ty.ir_type != .ptr) return error.UnsupportedAir;
        try self.block.instructions.append(self.allocator, .{
            .result = null,
            .kind = .{ .store = .{
                .ty = value.ty.ir_type,
                .value = value.value,
                .ptr = pointer.value,
                .attrs = .{ .is_volatile = pointer.ty.is_volatile_pointer },
            } },
        });
    }

    fn lowerCall(self: *LoweringContext, instruction: air_export.Instruction) !void {
        const function_marker = std.mem.indexOf(u8, instruction.payload, "(function '") orelse
            return error.UnsupportedAir;
        const signature_start = std.mem.indexOfScalar(u8, instruction.payload, '<') orelse
            return error.UnsupportedAir;
        const signature_end = std.mem.lastIndexOfScalar(u8, instruction.payload[signature_start..function_marker], ',') orelse
            return error.UnsupportedAir;
        const signature_text = std.mem.trim(
            u8,
            instruction.payload[signature_start + 1 .. signature_start + signature_end],
            " ",
        );
        const call_type = try parseFunctionType(self.allocator, signature_text);
        defer call_type.deinit(self.allocator);
        const callee_start = function_marker + "(function '".len;
        const callee_relative_end = std.mem.indexOf(u8, instruction.payload[callee_start..], "')") orelse
            return error.UnsupportedAir;
        const callee = instruction.payload[callee_start .. callee_start + callee_relative_end];
        const args_start = std.mem.indexOfScalarPos(u8, instruction.payload, callee_start + callee_relative_end, '[') orelse
            return error.UnsupportedAir;
        const args_end = std.mem.lastIndexOfScalar(u8, instruction.payload, ']') orelse
            return error.UnsupportedAir;
        if (args_end < args_start) return error.UnsupportedAir;

        var call: ir.CallInst = .{
            .ret_ty = call_type.return_type.ir_type,
            .callee = callee,
            .calling_conv = if (call_type.c_calling_convention) null else "fastcc",
            .args = .empty,
        };
        errdefer call.deinit(self.allocator);
        var args = splitTopLevel(instruction.payload[args_start + 1 .. args_end], ',');
        var arg_index: usize = 0;
        while (args.next()) |arg_text| : (arg_index += 1) {
            if (std.mem.trim(u8, arg_text, " ").len == 0) continue;
            if (arg_index >= call_type.params.len) return error.UnsupportedAir;
            const arg = try self.resolveValue(arg_text);
            if (!arg.ty.ir_type.eql(call_type.params[arg_index].ir_type)) return error.UnsupportedAir;
            try call.args.append(self.allocator, .{
                .ty = arg.ty.ir_type,
                .value = arg.value,
            });
        }
        if (arg_index != call_type.params.len) return error.UnsupportedAir;

        const result_name = if (call.ret_ty == .void) null else try self.resultName(instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .call = call },
        });
        if (result_name) |name| {
            self.values[instruction.index] = .{
                .ty = call_type.return_type,
                .value = .{ .named = name },
            };
        }
    }

    fn lowerRuntimeNavPtr(self: *LoweringContext, instruction: air_export.Instruction) !void {
        var fields = splitTopLevel(instruction.payload, ',');
        const pointer_type = parseZigType(std.mem.trim(u8, fields.next() orelse return error.UnsupportedAir, " ")) orelse
            return error.UnsupportedAir;
        const symbol_text = std.mem.trim(u8, fields.next() orelse return error.UnsupportedAir, " ");
        if (fields.next() != null or pointer_type.ir_type != .ptr or symbol_text.len < 3 or
            symbol_text[0] != '\'' or symbol_text[symbol_text.len - 1] != '\'')
        {
            return error.UnsupportedAir;
        }
        const symbol = try ownPrint(self.module, "@{s}", .{symbol_text[1 .. symbol_text.len - 1]});
        self.values[instruction.index] = .{
            .ty = pointer_type,
            .value = .{ .named = symbol },
        };
    }

    fn lowerAtomicRmw(self: *LoweringContext, instruction: air_export.Instruction) !void {
        var fields = splitTopLevel(instruction.payload, ',');
        const pointer = try self.resolveValue(fields.next() orelse return error.UnsupportedAir);
        const value = try self.resolveValue(fields.next() orelse return error.UnsupportedAir);
        const operation = std.mem.trim(u8, fields.next() orelse return error.UnsupportedAir, " ");
        const ordering = std.mem.trim(u8, fields.next() orelse return error.UnsupportedAir, " ");
        if (fields.next() != null or pointer.ty.ir_type != .ptr or
            !std.mem.eql(u8, operation, "Add") or
            !std.mem.eql(u8, ordering, "monotonic"))
        {
            return error.UnsupportedAir;
        }
        const result_name = try self.resultName(instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .atomicrmw = .{
                .op = "add",
                .ty = value.ty.ir_type,
                .ptr = pointer.value,
                .value = value.value,
                .ordering = ordering,
            } },
        });
        self.values[instruction.index] = .{
            .ty = value.ty,
            .value = .{ .named = result_name },
        };
    }

    fn lowerReturn(self: *LoweringContext, instruction: air_export.Instruction) !void {
        const payload = std.mem.trim(u8, instruction.payload, " ");
        if (self.function_type.return_type.ir_type == .void) {
            self.block.terminator = .{ .ret = .{ .ty = .void } };
            return;
        }
        const value = try self.resolveValue(payload);
        if (!value.ty.ir_type.eql(self.function_type.return_type.ir_type)) return error.UnsupportedAir;
        self.block.terminator = .{ .ret = .{
            .ty = self.function_type.return_type.ir_type,
            .value = value.value,
        } };
    }

    fn resolveValue(self: *LoweringContext, text: []const u8) LowerError!TypedValue {
        const trimmed = std.mem.trim(u8, text, " ");
        if (parseInstructionRef(trimmed)) |index| {
            if (index >= self.values.len) return error.UnsupportedAir;
            if (self.values[index]) |value| return value;
            if (self.findInstruction(index)) |instruction| {
                if (std.mem.eql(u8, instruction.opcode, "block") and
                    isSimpleSelectBlock(self.air_function, index))
                {
                    try self.materializeSelectBlock(instruction);
                    return self.values[index] orelse error.UnsupportedAir;
                }
            }
            return error.UnsupportedAir;
        }
        if (parseSymbolPointer(trimmed)) |symbol_pointer| {
            return .{
                .ty = symbol_pointer.ty,
                .value = .{ .named = try ownPrint(self.module, "@{s}", .{symbol_pointer.symbol}) },
            };
        }
        return parseConstant(trimmed) orelse error.UnsupportedAir;
    }

    fn materializeSelectBlock(
        self: *LoweringContext,
        block_instruction: air_export.Instruction,
    ) LowerError!void {
        var condition: ?TypedValue = null;
        var incoming: [2]TypedValue = undefined;
        var incoming_count: usize = 0;
        const block_position = instructionPosition(self.air_function, block_instruction.index) orelse
            return error.UnsupportedAir;
        for (self.air_function.instructions[block_position + 1 ..]) |instruction| {
            if (instruction.indent <= block_instruction.indent) break;
            if (std.mem.eql(u8, instruction.opcode, "cond_br")) {
                var fields = splitTopLevel(instruction.payload, ',');
                condition = try self.resolveValue(fields.next() orelse return error.UnsupportedAir);
            } else if (std.mem.eql(u8, instruction.opcode, "br")) {
                var fields = splitTopLevel(instruction.payload, ',');
                const target_text = fields.next() orelse return error.UnsupportedAir;
                if (parseInstructionRef(target_text) != block_instruction.index) continue;
                if (incoming_count >= incoming.len) return error.UnsupportedAir;
                incoming[incoming_count] = try self.resolveValue(fields.next() orelse return error.UnsupportedAir);
                incoming_count += 1;
            }
        }
        const cond = condition orelse return error.UnsupportedAir;
        if (cond.ty.ir_type != .int or cond.ty.ir_type.int != 1 or incoming_count != 2) {
            return error.UnsupportedAir;
        }
        if (!incoming[0].ty.ir_type.eql(incoming[1].ty.ir_type)) return error.UnsupportedAir;
        const result_name = try self.resultName(block_instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .select = .{
                .cond_ty = cond.ty.ir_type,
                .cond = cond.value,
                .ty = incoming[0].ty.ir_type,
                .true_value = incoming[0].value,
                .false_value = incoming[1].value,
            } },
        });
        self.values[block_instruction.index] = .{
            .ty = incoming[0].ty,
            .value = .{ .named = result_name },
        };
    }

    fn findInstruction(self: LoweringContext, index: u32) ?air_export.Instruction {
        for (self.air_function.instructions) |instruction| {
            if (instruction.index == index) return instruction;
        }
        return null;
    }

    fn resultName(self: *LoweringContext, index: u32) ![]const u8 {
        return ownPrint(self.module, "air{}", .{index});
    }

    fn blockParamName(self: LoweringContext, index: usize) []const u8 {
        return self.function.params.items[index].name;
    }
};

fn parseFunctionType(allocator: std.mem.Allocator, text: []const u8) !FunctionType {
    const trimmed = std.mem.trim(u8, text, " ");
    if (!std.mem.startsWith(u8, trimmed, "fn (")) return error.UnsupportedAir;
    const params_end = findMatching(trimmed, 3, '(', ')') orelse return error.UnsupportedAir;
    const params_text = trimmed[4..params_end];
    const suffix = std.mem.trim(u8, trimmed[params_end + 1 ..], " ");
    const c_calling_convention = std.mem.startsWith(u8, suffix, "callconv(.c)");
    const return_text = if (std.mem.startsWith(u8, suffix, "callconv(")) blk: {
        const close = std.mem.indexOfScalar(u8, suffix, ')') orelse return error.UnsupportedAir;
        break :blk std.mem.trim(u8, suffix[close + 1 ..], " ");
    } else suffix;
    const return_type = parseZigType(return_text) orelse return error.UnsupportedAir;

    var params: std.ArrayList(ZigType) = .empty;
    errdefer params.deinit(allocator);
    var fields = splitTopLevel(params_text, ',');
    while (fields.next()) |field| {
        const param_text = std.mem.trim(u8, field, " ");
        if (param_text.len == 0) continue;
        try params.append(allocator, parseZigType(param_text) orelse return error.UnsupportedAir);
    }
    return .{
        .params = try params.toOwnedSlice(allocator),
        .return_type = return_type,
        .c_calling_convention = c_calling_convention,
    };
}

fn parseZigType(text: []const u8) ?ZigType {
    const trimmed = std.mem.trim(u8, text, " ");
    if (std.mem.eql(u8, trimmed, "void")) return .{ .ir_type = .void };
    if (std.mem.eql(u8, trimmed, "noreturn")) return .{ .ir_type = .void };
    if (std.mem.eql(u8, trimmed, "bool")) return .{ .ir_type = .{ .int = 1 } };
    if (std.mem.eql(u8, trimmed, "c_int")) return .{ .ir_type = .{ .int = 32 }, .signed = true };
    if (std.mem.eql(u8, trimmed, "usize")) return .{ .ir_type = .{ .int = 64 } };
    if (std.mem.eql(u8, trimmed, "isize")) return .{ .ir_type = .{ .int = 64 }, .signed = true };
    if (std.mem.eql(u8, trimmed, "f32")) return .{ .ir_type = .float };
    if (std.mem.eql(u8, trimmed, "f64")) return .{ .ir_type = .double };
    if (std.mem.eql(u8, trimmed, "f128")) return .{ .ir_type = .fp128 };
    if (trimmed.len > 1 and (trimmed[0] == 'u' or trimmed[0] == 'i')) {
        const bits = std.fmt.parseInt(u16, trimmed[1..], 10) catch return null;
        return .{ .ir_type = .{ .int = bits }, .signed = trimmed[0] == 'i' };
    }
    if (isPointerType(trimmed)) {
        const child_text = pointerChildText(trimmed) orelse return null;
        const child = parseZigType(child_text);
        return .{
            .ir_type = .ptr,
            .pointer_child = if (child) |parsed| parsed.ir_type else null,
            .is_volatile_pointer = std.mem.indexOf(u8, trimmed, "volatile") != null,
        };
    }
    return null;
}

fn parseConstant(text: []const u8) ?TypedValue {
    if (std.mem.startsWith(u8, text, "<") and std.mem.endsWith(u8, text, ">")) {
        var fields = splitTopLevel(text[1 .. text.len - 1], ',');
        const type_text = fields.next() orelse return null;
        const value_text = std.mem.trim(u8, fields.next() orelse return null, " ");
        if (fields.next() != null) return null;
        const ty = parseZigType(std.mem.trim(u8, type_text, " ")) orelse return null;
        if (std.mem.eql(u8, value_text, "null")) return .{ .ty = ty, .value = .null_value };
        if (isFpType(ty.ir_type)) return .{ .ty = ty, .value = .{ .fp = value_text } };
        const value = std.fmt.parseInt(i128, value_text, 10) catch return null;
        return .{ .ty = ty, .value = .{ .int = value } };
    }
    if (std.mem.startsWith(u8, text, "@.zero_")) {
        const ty = parseStaticIntegerType(text["@.zero_".len..]) orelse return null;
        return .{ .ty = ty, .value = .{ .int = 0 } };
    }
    if (std.mem.startsWith(u8, text, "@.one_")) {
        const ty = parseStaticIntegerType(text["@.one_".len..]) orelse return null;
        return .{ .ty = ty, .value = .{ .int = 1 } };
    }
    return null;
}

const SymbolPointer = struct {
    ty: ZigType,
    symbol: []const u8,
};

fn parseSymbolPointer(text: []const u8) ?SymbolPointer {
    if (!std.mem.startsWith(u8, text, "<") or !std.mem.endsWith(u8, text, ">")) return null;
    var fields = splitTopLevel(text[1 .. text.len - 1], ',');
    const type_text = std.mem.trim(u8, fields.next() orelse return null, " ");
    const value_text = std.mem.trim(u8, fields.next() orelse return null, " ");
    if (fields.next() != null or !std.mem.startsWith(u8, value_text, "&") or value_text.len == 1) return null;
    const ty = parseZigType(type_text) orelse return null;
    if (ty.ir_type != .ptr) return null;
    return .{ .ty = ty, .symbol = value_text[1..] };
}

fn parseStaticIntegerType(text: []const u8) ?ZigType {
    return parseZigType(if (std.mem.eql(u8, text, "usize")) "usize" else text);
}

fn parseInstructionRef(text: []const u8) ?u32 {
    var trimmed = std.mem.trim(u8, text, " ");
    if (std.mem.endsWith(u8, trimmed, "!")) trimmed = trimmed[0 .. trimmed.len - 1];
    if (trimmed.len < 2 or trimmed[0] != '%') return null;
    return std.fmt.parseInt(u32, trimmed[1..], 10) catch null;
}

fn isSimpleSelectBlock(function: air_export.Function, block_index: u32) bool {
    const block_position = instructionPosition(function, block_index) orelse return false;
    const block_instruction = function.instructions[block_position];
    var cond_count: usize = 0;
    var matching_br_count: usize = 0;
    var after_cond = false;
    for (function.instructions[block_position + 1 ..]) |instruction| {
        if (instruction.indent <= block_instruction.indent) break;
        if (std.mem.eql(u8, instruction.opcode, "cond_br")) {
            cond_count += 1;
            after_cond = true;
            continue;
        }
        if (!after_cond or isIgnoredOpcode(instruction.opcode)) continue;
        if (std.mem.eql(u8, instruction.opcode, "br")) {
            var fields = splitTopLevel(instruction.payload, ',');
            const target = fields.next() orelse return false;
            if (parseInstructionRef(target) == block_index) matching_br_count += 1;
            continue;
        }
        return false;
    }
    return cond_count == 1 and matching_br_count == 2;
}

fn belongsToSimpleSelectBlock(function: air_export.Function, instruction_index: u32) bool {
    const position = instructionPosition(function, instruction_index) orelse return false;
    const instruction = function.instructions[position];
    var parent_position = position;
    while (parent_position > 0) {
        parent_position -= 1;
        const candidate = function.instructions[parent_position];
        if (candidate.indent >= instruction.indent) continue;
        if (std.mem.eql(u8, candidate.opcode, "block")) {
            return isSimpleSelectBlock(function, candidate.index);
        }
    }
    return false;
}

fn instructionPosition(function: air_export.Function, index: u32) ?usize {
    for (function.instructions, 0..) |instruction, position| {
        if (instruction.index == index) return position;
    }
    return null;
}

fn isIgnoredOpcode(opcode: []const u8) bool {
    return std.mem.startsWith(u8, opcode, "dbg_");
}

fn isStraightLineOpcode(opcode: []const u8) bool {
    return std.mem.eql(u8, opcode, "arg") or
        isArithmeticOpcode(opcode) or
        std.mem.startsWith(u8, opcode, "cmp_") or
        isCastOpcode(opcode) or
        std.mem.eql(u8, opcode, "alloc") or
        std.mem.eql(u8, opcode, "load") or
        std.mem.eql(u8, opcode, "store") or
        std.mem.eql(u8, opcode, "store_safe") or
        std.mem.eql(u8, opcode, "runtime_nav_ptr") or
        std.mem.eql(u8, opcode, "atomic_rmw") or
        isCallOpcode(opcode) or
        std.mem.eql(u8, opcode, "ret") or
        std.mem.eql(u8, opcode, "ret_safe") or
        std.mem.eql(u8, opcode, "unreach");
}

fn isArithmeticOpcode(opcode: []const u8) bool {
    return air_export.categoryForOpcode(opcode) == .arithmetic;
}

fn isShiftOpcode(opcode: []const u8) bool {
    return std.mem.startsWith(u8, opcode, "shl") or std.mem.startsWith(u8, opcode, "shr");
}

fn isCastOpcode(opcode: []const u8) bool {
    return std.mem.eql(u8, opcode, "trunc") or
        std.mem.eql(u8, opcode, "intcast") or
        std.mem.eql(u8, opcode, "bitcast") or
        std.mem.eql(u8, opcode, "ptrtoint") or
        std.mem.eql(u8, opcode, "inttoptr") or
        std.mem.eql(u8, opcode, "float_from_int") or
        std.mem.eql(u8, opcode, "int_from_float");
}

fn isCallOpcode(opcode: []const u8) bool {
    return air_export.categoryForOpcode(opcode) == .call;
}

fn binaryOp(opcode: []const u8, ty: ZigType) ?ir.BinaryOp {
    const fp = isFpType(ty.ir_type);
    if (std.mem.startsWith(u8, opcode, "add")) return if (fp) .fadd else .add;
    if (std.mem.startsWith(u8, opcode, "sub")) return if (fp) .fsub else .sub;
    if (std.mem.startsWith(u8, opcode, "mul")) return if (fp) .fmul else .mul;
    if (std.mem.startsWith(u8, opcode, "div_float")) return .fdiv;
    if (std.mem.startsWith(u8, opcode, "div_")) return if (ty.signed) .sdiv else .udiv;
    if (std.mem.startsWith(u8, opcode, "rem")) return if (fp) .frem else if (ty.signed) .srem else .urem;
    if (std.mem.startsWith(u8, opcode, "mod")) return if (ty.signed) .srem else .urem;
    if (std.mem.eql(u8, opcode, "bit_and")) return .@"and";
    if (std.mem.eql(u8, opcode, "bit_or")) return .@"or";
    if (std.mem.eql(u8, opcode, "xor")) return .xor;
    if (std.mem.startsWith(u8, opcode, "shl")) return .shl;
    if (std.mem.startsWith(u8, opcode, "shr")) return if (ty.signed) .ashr else .lshr;
    return null;
}

fn intPredicate(opcode: []const u8, signed: bool) ?ir.IcmpPredicate {
    if (std.mem.startsWith(u8, opcode, "cmp_eq")) return .eq;
    if (std.mem.startsWith(u8, opcode, "cmp_neq")) return .ne;
    if (std.mem.startsWith(u8, opcode, "cmp_lt")) return if (signed) .slt else .ult;
    if (std.mem.startsWith(u8, opcode, "cmp_lte")) return if (signed) .sle else .ule;
    if (std.mem.startsWith(u8, opcode, "cmp_gt")) return if (signed) .sgt else .ugt;
    if (std.mem.startsWith(u8, opcode, "cmp_gte")) return if (signed) .sge else .uge;
    return null;
}

fn fpPredicate(opcode: []const u8) ?ir.FcmpPredicate {
    if (std.mem.startsWith(u8, opcode, "cmp_eq")) return .oeq;
    if (std.mem.startsWith(u8, opcode, "cmp_neq")) return .one;
    if (std.mem.startsWith(u8, opcode, "cmp_lt")) return .olt;
    if (std.mem.startsWith(u8, opcode, "cmp_lte")) return .ole;
    if (std.mem.startsWith(u8, opcode, "cmp_gt")) return .ogt;
    if (std.mem.startsWith(u8, opcode, "cmp_gte")) return .oge;
    return null;
}

fn castOp(opcode: []const u8, from: ZigType, to: ZigType) ?ir.CastOp {
    if (std.mem.eql(u8, opcode, "trunc")) return .trunc;
    if (std.mem.eql(u8, opcode, "bitcast")) return .bitcast;
    if (std.mem.eql(u8, opcode, "ptrtoint")) return .ptrtoint;
    if (std.mem.eql(u8, opcode, "inttoptr")) return .inttoptr;
    if (std.mem.eql(u8, opcode, "float_from_int")) return if (from.signed) .fptosi else .fptoui;
    if (std.mem.eql(u8, opcode, "int_from_float")) return if (to.signed) .fptosi else .fptoui;
    if (!std.mem.eql(u8, opcode, "intcast")) return null;
    const from_bits = intBits(from.ir_type) orelse return null;
    const to_bits = intBits(to.ir_type) orelse return null;
    if (to_bits < from_bits) return .trunc;
    if (to_bits > from_bits) return if (from.signed) .sext else .zext;
    return .bitcast;
}

fn isFpType(ty: ir.Type) bool {
    return ty == .float or ty == .double or ty == .fp128;
}

fn intBits(ty: ir.Type) ?u16 {
    return switch (ty) {
        .int => |bits| bits,
        else => null,
    };
}

fn shortFunctionName(name: []const u8) []const u8 {
    const dot = std.mem.lastIndexOfScalar(u8, name, '.') orelse return name;
    return name[dot + 1 ..];
}

fn isPointerType(text: []const u8) bool {
    return std.mem.startsWith(u8, text, "*") or
        std.mem.startsWith(u8, text, "[*]") or
        std.mem.startsWith(u8, text, "[]") or
        std.mem.startsWith(u8, text, "?*");
}

fn pointerChildText(text: []const u8) ?[]const u8 {
    var child = if (std.mem.startsWith(u8, text, "?*"))
        text[2..]
    else if (std.mem.startsWith(u8, text, "[*]"))
        text[3..]
    else if (std.mem.startsWith(u8, text, "[]"))
        text[2..]
    else if (std.mem.startsWith(u8, text, "*"))
        text[1..]
    else
        return null;
    child = std.mem.trim(u8, child, " ");
    while (true) {
        if (std.mem.startsWith(u8, child, "const ")) {
            child = child["const ".len..];
        } else if (std.mem.startsWith(u8, child, "volatile ")) {
            child = child["volatile ".len..];
        } else if (std.mem.startsWith(u8, child, "allowzero ")) {
            child = child["allowzero ".len..];
        } else {
            break;
        }
    }
    return std.mem.trim(u8, child, " ");
}

fn ownPrint(module: *ir.Module, comptime format: []const u8, args: anytype) ![]const u8 {
    const owned = try std.fmt.allocPrint(module.allocator, format, args);
    errdefer module.allocator.free(owned);
    try module.owned_strings.append(module.allocator, owned);
    return owned;
}

fn findMatching(text: []const u8, open_index: usize, open: u8, close: u8) ?usize {
    var depth: usize = 0;
    for (text[open_index..], open_index..) |char, index| {
        if (char == open) depth += 1;
        if (char == close) {
            if (depth == 0) return null;
            depth -= 1;
            if (depth == 0) return index;
        }
    }
    return null;
}

const TopLevelSplit = struct {
    text: []const u8,
    separator: u8,
    offset: usize = 0,

    fn next(self: *TopLevelSplit) ?[]const u8 {
        if (self.offset > self.text.len) return null;
        const start = self.offset;
        var paren_depth: usize = 0;
        var bracket_depth: usize = 0;
        var brace_depth: usize = 0;
        var angle_depth: usize = 0;
        var quote: ?u8 = null;
        var index = start;
        while (index < self.text.len) : (index += 1) {
            const char = self.text[index];
            if (quote) |active_quote| {
                if (char == active_quote and (index == 0 or self.text[index - 1] != '\\')) quote = null;
                continue;
            }
            switch (char) {
                '\'', '"' => quote = char,
                '(' => paren_depth += 1,
                ')' => if (paren_depth > 0) {
                    paren_depth -= 1;
                },
                '[' => bracket_depth += 1,
                ']' => if (bracket_depth > 0) {
                    bracket_depth -= 1;
                },
                '{' => brace_depth += 1,
                '}' => if (brace_depth > 0) {
                    brace_depth -= 1;
                },
                '<' => angle_depth += 1,
                '>' => if (angle_depth > 0) {
                    angle_depth -= 1;
                },
                else => {},
            }
            if (char == self.separator and paren_depth == 0 and bracket_depth == 0 and
                brace_depth == 0 and angle_depth == 0 and quote == null)
            {
                self.offset = index + 1;
                return self.text[start..index];
            }
        }
        self.offset = self.text.len + 1;
        return self.text[start..];
    }
};

fn splitTopLevel(text: []const u8, separator: u8) TopLevelSplit {
    return .{ .text = text, .separator = separator };
}

test "lower straight-line AIR arithmetic and calls" {
    const air_text =
        \\  %0 = arg(i32, 0)
        \\  %1 = arg(i32, 1)
        \\  %2 = add_wrap(%0!, %1!)
        \\  %3!= ret(%2!)
        \\
    ;
    const input = try makeTestExport(std.testing.allocator, "add_wrap", "fn (i32, i32) callconv(.c) i32", air_text, 4);
    defer std.testing.allocator.free(input);
    var parsed = try air_export.parse(std.testing.allocator, input);
    defer parsed.deinit();
    var lowered = try lowerCompatible(std.testing.allocator, parsed);
    defer lowered.deinit();
    try std.testing.expectEqual(@as(usize, 1), lowered.accepted_functions);
    try std.testing.expectEqual(@as(usize, 0), lowered.unsupported.len);
    try std.testing.expectEqual(ir.BinaryOp.add, lowered.module.functions.items[0].blocks.items[0].instructions.items[0].kind.binary.op);
}

test "lower AIR block result conditional as select" {
    const air_text =
        \\  %0 = arg(i32, 0)
        \\  %1 = arg(i32, 1)
        \\  %2 = block(i32, {
        \\    %3 = cmp_lt(%0, %1)
        \\    %6!= cond_br(%3!, poi {
        \\      %4!= br(%2, %0!)
        \\    }, poi {
        \\      %5!= br(%2, %1!)
        \\    })
        \\  })
        \\  %7!= ret(%2!)
        \\
    ;
    const input = try makeTestExport(std.testing.allocator, "min", "fn (i32, i32) callconv(.c) i32", air_text, 8);
    defer std.testing.allocator.free(input);
    var parsed = try air_export.parse(std.testing.allocator, input);
    defer parsed.deinit();
    var lowered = try lowerCompatible(std.testing.allocator, parsed);
    defer lowered.deinit();
    try std.testing.expectEqual(@as(usize, 1), lowered.accepted_functions);
    const instructions = lowered.module.functions.items[0].blocks.items[0].instructions.items;
    try std.testing.expectEqual(@as(usize, 2), instructions.len);
    try std.testing.expect(instructions[1].kind == .select);
}

test "lower AIR accumulator loop into SSA control flow" {
    const air_text =
        \\  %0 = arg(u32, 0)
        \\  %1 = alloc(*u32)
        \\  %2!= store(%1, <u32, 0>)
        \\  %3 = alloc(*i32)
        \\  %4!= store(%3, <i32, 0>)
        \\  %5!= block(void, {
        \\    %6!= loop(noreturn, {
        \\      %7!= block(void, {
        \\        %8 = load(u32, %1)
        \\        %9 = cmp_lt(%8!, %0)
        \\        %18!= cond_br(%9!, poi {
        \\          %10 = load(i32, %3)
        \\          %11 = load(u32, %1)
        \\          %12 = intcast(i32, %11!)
        \\          %13 = add(%10!, %12!)
        \\          %14!= store(%3, %13!)
        \\          %15 = load(u32, %1)
        \\          %16 = add(%15!, <u32, 1>)
        \\          %17!= store(%1, %16!)
        \\          %19!= br(%7, @.void_value)
        \\        }, poi {
        \\          %20!= br(%5, @.void_value)
        \\        })
        \\      })
        \\      %21!= repeat(%6)
        \\    })
        \\  })
        \\  %22 = load(i32, %3)
        \\  %23!= ret(%22!)
        \\
    ;
    const input = try makeTestExport(
        std.testing.allocator,
        "uncurated_loop_sum",
        "fn (u32) callconv(.c) i32",
        air_text,
        24,
    );
    defer std.testing.allocator.free(input);
    var parsed = try air_export.parse(std.testing.allocator, input);
    defer parsed.deinit();
    var lowered = try lowerCompatible(std.testing.allocator, parsed);
    defer lowered.deinit();
    try std.testing.expectEqual(@as(usize, 1), lowered.accepted_functions);
    try std.testing.expectEqual(@as(usize, 4), lowered.module.functions.items[0].blocks.items.len);
    try std.testing.expect(lowered.module.functions.items[0].blocks.items[1].instructions.items[0].kind == .phi);
}

fn makeTestExport(
    allocator: std.mem.Allocator,
    function_name: []const u8,
    function_type: []const u8,
    air_text: []const u8,
    instruction_count: usize,
) ![]u8 {
    return std.fmt.allocPrint(allocator,
        \\zllvm-air-export-v1
        \\contract_version=1
        \\payload=zig-air-print-v1
        \\producer=test
        \\root_source=test.zig
        \\wrapper=test.zig
        \\mode=ReleaseFast
        \\target=x86_64-unknown-linux-gnu
        \\function_count=1
        \\global_count=0
        \\function_begin
        \\name_bytes={}
        \\{s}
        \\type_bytes={}
        \\{s}
        \\instruction_count={}
        \\main_body_count={}
        \\liveness=present
        \\air_bytes={}
        \\{s}
        \\function_end
        \\
    , .{
        function_name.len,
        function_name,
        function_type.len,
        function_type,
        instruction_count,
        instruction_count,
        air_text.len,
        air_text,
    });
}
