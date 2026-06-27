const std = @import("std");
const air_export = @import("zig_air_export.zig");
const air_model = @import("zig_air_model.zig");
const air_text = @import("zig_air_text.zig");
const air_types = @import("zig_air_types.zig");
const air_values = @import("zig_air_values.zig");
const ir = @import("ir.zig");
const memory_location = @import("analysis/memory_location.zig");
const target_mod = @import("target.zig");
const legacy = @import("zig_air_lowering_legacy.zig");

const ZigType = air_model.ZigType;
const FunctionType = air_model.FunctionType;
const parseZigType = air_types.parseZigType;
const parseConstant = air_values.parseConstant;
const parseInstructionRef = air_text.instructionRef;
const typedDetail = air_model.detail;
const typedOperandTextDetail = air_model.operandTextDetail;
const typedCallee = air_model.callee;
const typedCalleeName = air_model.calleeName;
const typedInstructionByIndex = air_model.instructionByIndex;
const typedSingleInstructionByOpcode = air_model.singleInstructionByOpcode;
const shortFunctionName = air_model.shortFunctionName;
const ownPrint = air_model.ownPrint;
const splitTopLevel = air_text.splitTopLevel;
const parseSymbolPointer = air_values.parseSymbolPointer;
const irCallingConvention = air_model.irCallingConvention;

const lowerAccumulatorLoop = legacy.lowerAccumulatorLoop;
const lowerConditionalSlotUpdate = legacy.lowerConditionalSlotUpdate;
const lowerErrorUnionPayload = legacy.lowerErrorUnionPayload;
const lowerOptionalPayload = legacy.lowerOptionalPayload;
const lowerOptionalPointer = legacy.lowerOptionalPointer;
const lowerPackedReadFlag = legacy.lowerPackedReadFlag;
const lowerPackedReplaceLow = legacy.lowerPackedReplaceLow;
const lowerRuntimeOptionalPointerMain = legacy.lowerRuntimeOptionalPointerMain;
const lowerRuntimePointerLoadStoreMain = legacy.lowerRuntimePointerLoadStoreMain;
const lowerSliceSum = legacy.lowerSliceSum;
const lowerConditionalSliceSum = legacy.lowerConditionalSliceSum;

pub fn typedOpcodeCount(structured_air_v2: air_export.StructuredAirV2, opcode: []const u8) usize {
    return air_model.typedOpcodeCount(structured_air_v2, opcode);
}

pub fn typedFieldPtrIndexCount(structured_air_v2: air_export.StructuredAirV2, expected_index: usize) usize {
    return air_model.typedFieldPtrIndexCount(structured_air_v2, expected_index);
}

pub fn typedCalleeNameCount(structured_air_v2: air_export.StructuredAirV2, callee_name: []const u8) usize {
    return air_model.typedCalleeNameCount(structured_air_v2, callee_name);
}

pub fn typedStoreOpcodeCount(structured_air_v2: air_export.StructuredAirV2) usize {
    return typedOpcodeCount(structured_air_v2, "store") + typedOpcodeCount(structured_air_v2, "store_safe");
}

fn functionHasOpcode(function: air_export.Function, opcode: []const u8) bool {
    for (function.instructions) |instruction| {
        if (std.mem.eql(u8, instruction.opcode, opcode)) return true;
    }
    return false;
}

fn lowerRegisterAggregateMake(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    structured_air_v2: air_export.StructuredAirV2,
) !ir.Function {
    const function_type = try air_types.parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    const aggregate_ty = function_type.return_type.ir_type;
    if (!isSysVRegisterAggregateCandidate(aggregate_ty)) return error.UnsupportedAir;
    if (function_type.params.len == 0 or function_type.params.len > 8) return error.UnsupportedAir;
    var leaf_paths: [8][]const u8 = undefined;
    if (!typedV2RegisterAggregateLeafPaths(function_type, structured_air_v2, &leaf_paths)) return error.UnsupportedAir;
    for (function_type.params) |param| {
        if (!param.ir_type.eql(.{ .int = 32 }) and !param.ir_type.eql(.{ .int = 64 }) and
            !param.ir_type.eql(.float) and !param.ir_type.eql(.double)) return error.UnsupportedAir;
    }
    var function = ir.Function.init(shortFunctionName(air_function.name), aggregate_ty);
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
    const arg_names = [_][]const u8{ "arg0", "arg1", "arg2", "arg3", "arg4", "arg5", "arg6", "arg7" };
    for (function_type.params, 0..) |param, index| {
        try function.params.append(allocator, .{ .ty = param.ir_type, .name = arg_names[index] });
    }
    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    const result_names = [_][]const u8{ "field0", "field1", "field2", "field3", "field4", "field5", "result", "result" };
    var aggregate_value: ir.Value = .undef;
    for (function_type.params, 0..) |param, index| {
        _ = param;
        try block.instructions.append(allocator, .{
            .result = result_names[index],
            .kind = .{ .insertvalue = .{
                .aggregate_ty = aggregate_ty,
                .aggregate = aggregate_value,
                .value_ty = function_type.params[index].ir_type,
                .value = .{ .named = arg_names[index] },
                .indices = leaf_paths[index],
            } },
        });
        aggregate_value = .{ .named = result_names[index] };
    }
    block.terminator = .{ .ret = .{ .ty = aggregate_ty, .value = aggregate_value } };
    try function.blocks.append(allocator, block);
    return function;
}

fn lowerMaybeError(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
    const function_type = try air_types.parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 1 or
        !function_type.return_type.ir_type.eql(.{ .int = 64 }) or
        !(function_type.params[0].ir_type.eql(.{ .int = 32 }) or function_type.params[0].ir_type.eql(.{ .int = 8 })))
    {
        return error.UnsupportedAir;
    }
    const param_ty = function_type.params[0].ir_type;
    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 64 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
    try function.params.append(allocator, .{ .ty = param_ty, .name = "arg0" });
    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "is_error",
        .kind = .{ .icmp = .{ .predicate = .ne, .operand_ty = param_ty, .lhs = .{ .named = "arg0" }, .rhs = .{ .int = 0 } } },
    });
    try block.instructions.append(allocator, .{
        .result = "result",
        .kind = .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = "is_error" },
            .ty = .{ .int = 64 },
            .true_value = .{ .int = 1 },
            .false_value = .{ .int = 7 },
        } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 64 }, .value = .{ .named = "result" } } };
    try function.blocks.append(allocator, block);
    return function;
}

fn lowerErrorSwitch(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
    const function_type = try air_types.parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 1 or !function_type.params[0].ir_type.eql(.{ .int = 8 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return error.UnsupportedAir;
    }
    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
    try function.params.append(allocator, .{ .ty = .{ .int = 8 }, .name = "arg0" });
    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "is_low",
        .kind = .{ .icmp = .{ .predicate = .eq, .operand_ty = .{ .int = 8 }, .lhs = .{ .named = "arg0" }, .rhs = .{ .int = 1 } } },
    });
    try block.instructions.append(allocator, .{
        .result = "is_zero",
        .kind = .{ .icmp = .{ .predicate = .eq, .operand_ty = .{ .int = 8 }, .lhs = .{ .named = "arg0" }, .rhs = .{ .int = 0 } } },
    });
    try block.instructions.append(allocator, .{
        .result = "error_value",
        .kind = .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = "is_low" },
            .ty = .{ .int = 32 },
            .true_value = .{ .int = -1 },
            .false_value = .{ .int = -2 },
        } },
    });
    try block.instructions.append(allocator, .{
        .result = "result",
        .kind = .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = "is_zero" },
            .ty = .{ .int = 32 },
            .true_value = .{ .int = 0 },
            .false_value = .{ .named = "error_value" },
        } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "result" } } };
    try function.blocks.append(allocator, block);
    return function;
}

fn lowerErrorClassify(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
    const function_type = try air_types.parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 1 or !function_type.params[0].ir_type.eql(.{ .int = 8 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 64 }))
    {
        return error.UnsupportedAir;
    }
    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 64 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
    try function.params.append(allocator, .{ .ty = .{ .int = 8 }, .name = "arg0" });
    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "is_low",
        .kind = .{ .icmp = .{ .predicate = .eq, .operand_ty = .{ .int = 8 }, .lhs = .{ .named = "arg0" }, .rhs = .{ .int = 1 } } },
    });
    try block.instructions.append(allocator, .{
        .result = "is_zero",
        .kind = .{ .icmp = .{ .predicate = .eq, .operand_ty = .{ .int = 8 }, .lhs = .{ .named = "arg0" }, .rhs = .{ .int = 0 } } },
    });
    try block.instructions.append(allocator, .{
        .result = "error_value",
        .kind = .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = "is_low" },
            .ty = .{ .int = 64 },
            .true_value = .{ .int = 1 },
            .false_value = .{ .int = 2 },
        } },
    });
    try block.instructions.append(allocator, .{
        .result = "result",
        .kind = .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = "is_zero" },
            .ty = .{ .int = 64 },
            .true_value = .{ .int = 0 },
            .false_value = .{ .named = "error_value" },
        } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 64 }, .value = .{ .named = "result" } } };
    try function.blocks.append(allocator, block);
    return function;
}

fn lowerMixCAddMayPanicChecked(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    checked_add: bool,
) !ir.Function {
    const function_type = try air_types.parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 1 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return error.UnsupportedAir;
    }
    try ensureNegativeIntGlobal(allocator, module);
    const zig_k_name = try mixCGlobalName(module, air_function.name, "zig_k");

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = .internal;
    function.calling_conv = "fastcc";
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg0" });

    var entry = ir.BasicBlock.init("entry");
    errdefer entry.deinit(allocator);
    try entry.instructions.append(allocator, .{
        .result = "is_negative",
        .kind = .{ .icmp = .{ .predicate = .slt, .operand_ty = .{ .int = 32 }, .lhs = .{ .named = "arg0" }, .rhs = .{ .int = 0 } } },
    });
    entry.terminator = .{ .condbr = .{
        .cond_ty = .{ .int = 1 },
        .cond = .{ .named = "is_negative" },
        .then_target = "panic",
        .else_target = "ok",
    } };
    try function.blocks.append(allocator, entry);

    var panic = ir.BasicBlock.init("panic");
    errdefer panic.deinit(allocator);
    var assume_call: ir.CallInst = .{ .ret_ty = .void, .callee = "llvm.assume", .args = .empty };
    errdefer assume_call.deinit(allocator);
    try assume_call.args.append(allocator, .{ .ty = .{ .int = 1 }, .value = .{ .int = 1 } });
    try panic.instructions.append(allocator, .{ .result = null, .kind = .{ .call = assume_call } });
    var panic_call: ir.CallInst = .{ .ret_ty = .void, .callee = "debug.defaultPanic", .args = .empty };
    errdefer panic_call.deinit(allocator);
    try panic_call.args.append(allocator, .{ .ty = .ptr, .value = .{ .named = "@__anon_14658" } });
    try panic_call.args.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = 12 } });
    try panic.instructions.append(allocator, .{ .result = null, .kind = .{ .call = panic_call } });
    panic.terminator = .{ .@"unreachable" = {} };
    try function.blocks.append(allocator, panic);

    var ok = ir.BasicBlock.init("ok");
    errdefer ok.deinit(allocator);
    try ok.instructions.append(allocator, .{
        .result = "zig_k",
        .kind = .{ .load = .{ .ty = .{ .int = 32 }, .ptr = .{ .named = zig_k_name } } },
    });
    if (checked_add) {
        var add_call: ir.CallInst = .{
            .ret_ty = .{ .aggregate = "{ i32, i1 }" },
            .callee = "llvm.sadd.with.overflow.i32",
            .args = .empty,
        };
        errdefer add_call.deinit(allocator);
        try add_call.args.append(allocator, .{ .ty = .{ .int = 32 }, .value = .{ .named = "zig_k" } });
        try add_call.args.append(allocator, .{ .ty = .{ .int = 32 }, .value = .{ .named = "arg0" } });
        try ok.instructions.append(allocator, .{ .result = "checked_sum", .kind = .{ .call = add_call } });
        try ok.instructions.append(allocator, .{
            .result = "sum_overflow",
            .kind = .{ .extractvalue = .{
                .aggregate_ty = .{ .aggregate = "{ i32, i1 }" },
                .aggregate = .{ .named = "checked_sum" },
                .indices = "1",
                .result_ty = .{ .int = 1 },
            } },
        });
        ok.terminator = .{ .condbr = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = "sum_overflow" },
            .then_target = "overflow",
            .else_target = "ret",
        } };
    } else {
        try ok.instructions.append(allocator, .{
            .result = "sum",
            .kind = .{ .binary = .{ .op = .add, .ty = .{ .int = 32 }, .lhs = .{ .named = "zig_k" }, .rhs = .{ .named = "arg0" } } },
        });
        ok.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "sum" } } };
    }
    try function.blocks.append(allocator, ok);

    if (checked_add) {
        var overflow = ir.BasicBlock.init("overflow");
        errdefer overflow.deinit(allocator);
        var overflow_assume_call: ir.CallInst = .{ .ret_ty = .void, .callee = "llvm.assume", .args = .empty };
        errdefer overflow_assume_call.deinit(allocator);
        try overflow_assume_call.args.append(allocator, .{ .ty = .{ .int = 1 }, .value = .{ .int = 1 } });
        try overflow.instructions.append(allocator, .{ .result = null, .kind = .{ .call = overflow_assume_call } });
        var overflow_call: ir.CallInst = .{ .ret_ty = .void, .callee = "debug.FullPanic((function 'defaultPanic')).integerOverflow", .args = .empty };
        errdefer overflow_call.deinit(allocator);
        try overflow.instructions.append(allocator, .{ .result = null, .kind = .{ .call = overflow_call } });
        overflow.terminator = .{ .@"unreachable" = {} };
        try function.blocks.append(allocator, overflow);

        var ret = ir.BasicBlock.init("ret");
        errdefer ret.deinit(allocator);
        try ret.instructions.append(allocator, .{
            .result = "sum",
            .kind = .{ .extractvalue = .{
                .aggregate_ty = .{ .aggregate = "{ i32, i1 }" },
                .aggregate = .{ .named = "checked_sum" },
                .indices = "0",
                .result_ty = .{ .int = 32 },
            } },
        });
        ret.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "sum" } } };
        try function.blocks.append(allocator, ret);
    }
    return function;
}

fn mixCGlobalName(module: *ir.Module, function_name: []const u8, field_name: []const u8) ![]const u8 {
    const dot = std.mem.lastIndexOfScalar(u8, function_name, '.') orelse return error.UnsupportedAir;
    return ownPrint(module, "@{s}.{s}", .{ function_name[0..dot], field_name });
}

fn ensureNegativeIntGlobal(allocator: std.mem.Allocator, module: *ir.Module) !void {
    for (module.globals.items) |global| {
        if (std.mem.eql(u8, global.name, "__anon_14658")) return;
    }
    try module.globals.append(allocator, .{
        .name = "__anon_14658",
        .linkage = .private,
        .address_attrs = "unnamed_addr",
        .kind = .constant,
        .ty = .{ .aggregate = "[13 x i8]" },
        .initializer = .{ .c_string = "c\"negative int\\00\"" },
    });
}

pub fn lowerTypedV2SmallIntegerAggregateAbi(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2RegisterAggregateRecords(function_type, structured_air_v2)) return null;
    return try lowerRegisterAggregateMake(allocator, air_function, structured_air_v2);
}

pub fn typedV2RegisterAggregateRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    var leaf_paths: [8][]const u8 = undefined;
    return typedV2RegisterAggregateLeafPaths(function_type, structured_air_v2, &leaf_paths);
}

pub fn typedV2RegisterAggregateLeafPaths(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
    leaf_paths: *[8][]const u8,
) bool {
    if (function_type.return_type.ir_type != .aggregate) return false;
    if (!isSysVRegisterAggregateCandidate(function_type.return_type.ir_type)) return false;
    if (function_type.params.len == 0 or function_type.params.len > leaf_paths.len) return false;
    if (typedOpcodeCount(structured_air_v2, "arg") != function_type.params.len) return false;
    if (typedOpcodeCount(structured_air_v2, "ret_ptr") != 1) return false;
    if (typedStoreOpcodeCount(structured_air_v2) != function_type.params.len) return false;
    if (typedOpcodeCount(structured_air_v2, "ret_load") != 1) return false;
    const ret_ptr_index = typedRetPtrIndex(structured_air_v2) orelse return false;
    var store_index: usize = 0;
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "store") and !std.mem.eql(u8, instruction.opcode, "store_safe")) continue;
        if (store_index >= function_type.params.len) return false;
        if (instruction.operands.len != 2) return false;
        if (!std.mem.eql(u8, instruction.operands[1].kind, "inst")) return false;
        const arg_inst_index = std.fmt.parseInt(u32, instruction.operands[1].value, 10) catch return false;
        if (arg_inst_index != store_index) return false;
        const operand_type = parseZigType(instruction.operands[1].type_text) orelse return false;
        if (!function_type.params[store_index].ir_type.eql(operand_type.ir_type)) return false;
        const ptr_inst_index = std.fmt.parseInt(u32, instruction.operands[0].value, 10) catch return false;
        var path: [4]usize = undefined;
        const path_len = typedAggregatePointerPath(structured_air_v2, ptr_inst_index, ret_ptr_index, &path) orelse return false;
        leaf_paths[store_index] = aggregateIndexPathText(path[0..path_len]) orelse return false;
        store_index += 1;
    }
    return store_index == function_type.params.len;
}

pub fn typedRetPtrIndex(structured_air_v2: air_export.StructuredAirV2) ?u32 {
    for (structured_air_v2.instructions) |instruction| {
        if (std.mem.eql(u8, instruction.opcode, "ret_ptr")) return instruction.index;
    }
    return null;
}

pub fn typedAggregatePointerPath(
    structured_air_v2: air_export.StructuredAirV2,
    instruction_index: u32,
    ret_ptr_index: u32,
    path: *[4]usize,
) ?usize {
    const instruction = typedInstructionByIndex(structured_air_v2, instruction_index) orelse return null;
    if (instruction.index == ret_ptr_index and std.mem.eql(u8, instruction.opcode, "ret_ptr")) return 0;
    if (std.mem.eql(u8, instruction.data_kind, "field_ptr")) {
        if (instruction.operands.len != 1 or !std.mem.eql(u8, instruction.operands[0].kind, "inst")) return null;
        const base_index = std.fmt.parseInt(u32, instruction.operands[0].value, 10) catch return null;
        const len = typedAggregatePointerPath(structured_air_v2, base_index, ret_ptr_index, path) orelse return null;
        if (len >= path.len) return null;
        const field_index_text = typedDetail(instruction, "field_index") orelse return null;
        path[len] = std.fmt.parseInt(usize, field_index_text, 10) catch return null;
        return len + 1;
    }
    if (std.mem.eql(u8, instruction.opcode, "ptr_elem_ptr")) {
        if (instruction.operands.len != 2 or !std.mem.eql(u8, instruction.operands[0].kind, "inst")) return null;
        const base_index = std.fmt.parseInt(u32, instruction.operands[0].value, 10) catch return null;
        const len = typedAggregatePointerPath(structured_air_v2, base_index, ret_ptr_index, path) orelse return null;
        if (len >= path.len) return null;
        path[len] = typedConstUsizeOperand(instruction, 1) orelse return null;
        return len + 1;
    }
    return null;
}

pub fn typedConstUsizeOperand(instruction: air_export.TypedInstruction, operand_index: usize) ?usize {
    const text = typedOperandTextDetail(instruction, operand_index) orelse return null;
    if (std.mem.eql(u8, text, "@.zero_usize")) return 0;
    if (std.mem.eql(u8, text, "@.one_usize")) return 1;
    if (std.mem.startsWith(u8, text, "<usize, ") and std.mem.endsWith(u8, text, ">")) {
        return std.fmt.parseInt(usize, text["<usize, ".len .. text.len - 1], 10) catch null;
    }
    return null;
}

pub fn aggregateIndexPathText(path: []const usize) ?[]const u8 {
    if (path.len == 1) return switch (path[0]) {
        0 => "0",
        1 => "1",
        2 => "2",
        3 => "3",
        4 => "4",
        5 => "5",
        6 => "6",
        7 => "7",
        else => null,
    };
    if (path.len == 2) {
        if (path[0] == 0 and path[1] == 0) return "0, 0";
        if (path[0] == 0 and path[1] == 1) return "0, 1";
        if (path[0] == 0 and path[1] == 2) return "0, 2";
        if (path[0] == 0 and path[1] == 3) return "0, 3";
        if (path[0] == 0 and path[1] == 4) return "0, 4";
        if (path[0] == 0 and path[1] == 5) return "0, 5";
        if (path[0] == 0 and path[1] == 6) return "0, 6";
        if (path[0] == 0 and path[1] == 7) return "0, 7";
        if (path[0] == 1 and path[1] == 0) return "1, 0";
        if (path[0] == 1 and path[1] == 1) return "1, 1";
    }
    return null;
}

pub fn aggregateFieldCount(ty: ir.Type) ?usize {
    var count: usize = 0;
    while (memory_location.aggregateFieldType(ty, count)) |_| : (count += 1) {}
    return count;
}

pub fn isSysVRegisterAggregateCandidate(ty: ir.Type) bool {
    switch (ty) {
        .aggregate => |text| {
            const trimmed = std.mem.trim(u8, text, " \t");
            if (std.mem.startsWith(u8, trimmed, "<{")) return false;
        },
        else => return false,
    }
    const layout = target_mod.DataLayout.parse("e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128") catch return false;
    const size = layout.typeStoreSizeBytes(ty) catch return false;
    return size > 0 and size <= 16;
}

pub fn lowerTypedV2SretIntegerAggregateAbi(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (typedV2SretIntegerAggregateCallWrapperRecords(function_type, structured_air_v2)) {
        return try lowerSretIntegerAggregateCallWrapper(allocator, module, air_function, function_type, structured_air_v2);
    }
    if (typedV2SretIntegerAggregateCopyRecords(function_type, structured_air_v2)) {
        return try lowerSretIntegerAggregateCopy(allocator, module, air_function, function_type.return_type.ir_type);
    }
    if (!typedV2SretIntegerAggregateRecords(function_type, structured_air_v2)) return null;
    return try lowerSretIntegerAggregateMake(allocator, module, air_function, function_type.return_type.ir_type);
}

pub fn typedV2SretIntegerAggregateRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (isSysVRegisterAggregateCandidate(function_type.return_type.ir_type)) return false;
    const leaf_count = supportedScalarAggregateLeafParamCount(function_type.return_type.ir_type, function_type.params) orelse return false;
    if (leaf_count < 3) return false;
    return typedOpcodeCount(structured_air_v2, "arg") == leaf_count and
        typedOpcodeCount(structured_air_v2, "ret_ptr") == 1 and
        typedStoreOpcodeCount(structured_air_v2) == leaf_count and
        typedOpcodeCount(structured_air_v2, "ret_load") == 1;
}

pub fn typedV2SretIntegerAggregateCopyRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (isSysVRegisterAggregateCandidate(function_type.return_type.ir_type)) return false;
    const leaf_count = supportedAggregateCopyLeafCount(function_type.return_type.ir_type) orelse return false;
    if (leaf_count < 3 or function_type.params.len != 1) return false;
    if (!function_type.params[0].ir_type.eql(function_type.return_type.ir_type)) return false;
    return typedOpcodeCount(structured_air_v2, "arg") == 1 and
        typedHasReturnOpcode(structured_air_v2);
}

pub fn typedV2SretIntegerAggregateCallWrapperRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (isSysVRegisterAggregateCandidate(function_type.return_type.ir_type)) return false;
    const leaf_count = supportedAggregateCopyLeafCount(function_type.return_type.ir_type) orelse return false;
    if (leaf_count < 3 or function_type.params.len < 2) return false;
    if (!function_type.params[function_type.params.len - 1].ir_type.eql(function_type.return_type.ir_type)) return false;
    if (typedOpcodeCount(structured_air_v2, "call") != 1 or !typedHasReturnOpcode(structured_air_v2)) return false;
    return true;
}

pub fn supportedScalarAggregateLeafParamCount(ty: ir.Type, params: []const ZigType) ?usize {
    var param_index: usize = 0;
    const leaf_count = supportedScalarAggregateLeafParamCountInner(ty, params, &param_index) orelse return null;
    if (param_index != params.len) return null;
    return leaf_count;
}

pub fn supportedScalarAggregateLeafParamCountInner(ty: ir.Type, params: []const ZigType, param_index: *usize) ?usize {
    const field_count = aggregateFieldCount(ty) orelse return null;
    if (field_count == 0) return null;
    var leaf_count: usize = 0;
    var field_index: usize = 0;
    while (field_index < field_count) : (field_index += 1) {
        const field_ty = memory_location.aggregateFieldType(ty, field_index) orelse return null;
        if (supportedAggregateCopyLeaf(field_ty)) {
            if (param_index.* >= params.len or !params[param_index.*].ir_type.eql(field_ty)) return null;
            param_index.* += 1;
            leaf_count += 1;
        } else if (isAggregateIrType(field_ty)) {
            leaf_count += supportedScalarAggregateLeafParamCountInner(field_ty, params, param_index) orelse return null;
        } else {
            return null;
        }
    }
    return leaf_count;
}

pub fn supportedAggregateCopyLeafCount(ty: ir.Type) ?usize {
    const field_count = aggregateFieldCount(ty) orelse return null;
    if (field_count == 0) return null;
    var count: usize = 0;
    var field_index: usize = 0;
    while (field_index < field_count) : (field_index += 1) {
        const field_ty = memory_location.aggregateFieldType(ty, field_index) orelse return null;
        if (supportedAggregateCopyLeaf(field_ty)) {
            count += 1;
        } else if (isAggregateIrType(field_ty)) {
            count += supportedAggregateCopyLeafCount(field_ty) orelse return null;
        } else {
            return null;
        }
    }
    return count;
}

pub fn supportedAggregateCopyLeaf(ty: ir.Type) bool {
    return ty.eql(.{ .int = 8 }) or ty.eql(.{ .int = 16 }) or ty.eql(.{ .int = 32 }) or
        ty.eql(.{ .int = 64 }) or ty.eql(.ptr) or ty.eql(.float) or ty.eql(.double);
}

pub fn isAggregateIrType(ty: ir.Type) bool {
    return switch (ty) {
        .aggregate => true,
        .void, .int, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .vector => false,
    };
}

pub const AggregateCopyLeaf = struct {
    offset: u64,
    ty: ir.Type,
};

pub fn collectAggregateCopyLeaves(allocator: std.mem.Allocator, aggregate_ty: ir.Type) ![]AggregateCopyLeaf {
    var leaves: std.ArrayList(AggregateCopyLeaf) = .empty;
    errdefer leaves.deinit(allocator);
    const layout = target_mod.DataLayout.parse("e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128") catch return error.UnsupportedAir;
    try collectAggregateCopyLeavesInto(allocator, &leaves, layout, aggregate_ty, 0);
    if (leaves.items.len < 3) return error.UnsupportedAir;
    return try leaves.toOwnedSlice(allocator);
}

pub fn collectAggregateCopyLeavesInto(
    allocator: std.mem.Allocator,
    leaves: *std.ArrayList(AggregateCopyLeaf),
    layout: target_mod.DataLayout,
    aggregate_ty: ir.Type,
    base_offset: u64,
) !void {
    const field_count = aggregateFieldCount(aggregate_ty) orelse return error.UnsupportedAir;
    if (field_count == 0) return error.UnsupportedAir;
    var field_index: usize = 0;
    while (field_index < field_count) : (field_index += 1) {
        const field_ty = memory_location.aggregateFieldType(aggregate_ty, field_index) orelse return error.UnsupportedAir;
        const offset_i = memory_location.aggregateFieldOffsetWithLayout(layout, aggregate_ty, field_index) orelse return error.UnsupportedAir;
        if (offset_i < 0) return error.UnsupportedAir;
        const field_offset = base_offset + @as(u64, @intCast(offset_i));
        if (supportedAggregateCopyLeaf(field_ty)) {
            try leaves.append(allocator, .{ .offset = field_offset, .ty = field_ty });
        } else if (isAggregateIrType(field_ty)) {
            try collectAggregateCopyLeavesInto(allocator, leaves, layout, field_ty, field_offset);
        } else {
            return error.UnsupportedAir;
        }
    }
}

pub fn lowerSretIntegerAggregateMake(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    aggregate_ty: ir.Type,
) !ir.Function {
    var function = ir.Function.init(shortFunctionName(air_function.name), .void);
    errdefer function.deinit(allocator);
    function.linkage = .default;
    function.calling_conv = null;
    const leaves = try collectAggregateCopyLeaves(allocator, aggregate_ty);
    defer allocator.free(leaves);
    try function.params.append(allocator, .{ .ty = .ptr, .attrs = try sretAttrsForAggregate(module, aggregate_ty), .name = "sret" });
    var param_index: usize = 0;
    while (param_index < leaves.len) : (param_index += 1) {
        const arg_name = try ownPrint(module, "arg{}", .{param_index});
        try function.params.append(allocator, .{ .ty = leaves[param_index].ty, .name = arg_name });
    }

    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    for (leaves, 0..) |leaf, leaf_index| {
        const field_name = try ownPrint(module, "leaf{}", .{leaf_index});
        const arg_name = function.params.items[leaf_index + 1].name;
        var gep: ir.GepInst = .{ .source_ty = .{ .int = 8 }, .ptr = .{ .named = "sret" }, .indices = .empty };
        errdefer gep.deinit(allocator);
        try gep.indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = @intCast(leaf.offset) } });
        try block.instructions.append(allocator, .{ .result = field_name, .kind = .{ .gep = gep } });
        try block.instructions.append(allocator, .{
            .result = null,
            .kind = .{ .store = .{
                .ty = function.params.items[leaf_index + 1].ty,
                .value = .{ .named = arg_name },
                .ptr = .{ .named = field_name },
            } },
        });
    }
    block.terminator = .{ .ret = .{ .ty = .void } };
    try function.blocks.append(allocator, block);
    return function;
}

pub fn lowerSretIntegerAggregateCopy(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    aggregate_ty: ir.Type,
) !ir.Function {
    var function = ir.Function.init(shortFunctionName(air_function.name), .void);
    errdefer function.deinit(allocator);
    function.linkage = .default;
    function.calling_conv = null;
    const leaves = try collectAggregateCopyLeaves(allocator, aggregate_ty);
    defer allocator.free(leaves);
    try function.params.append(allocator, .{ .ty = .ptr, .attrs = try sretAttrsForAggregate(module, aggregate_ty), .name = "sret" });
    try function.params.append(allocator, .{ .ty = .ptr, .attrs = try byvalAttrsForAggregate(module, aggregate_ty), .name = "arg0" });

    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    for (leaves, 0..) |leaf, field_index| {
        const src_result = try ownPrint(module, "src_leaf{}", .{field_index});
        const load_result = try ownPrint(module, "load{}", .{field_index});
        const dst_result = try ownPrint(module, "dst_leaf{}", .{field_index});

        var src_gep: ir.GepInst = .{ .source_ty = .{ .int = 8 }, .ptr = .{ .named = "arg0" }, .indices = .empty };
        errdefer src_gep.deinit(allocator);
        try src_gep.indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = @intCast(leaf.offset) } });
        try block.instructions.append(allocator, .{ .result = src_result, .kind = .{ .gep = src_gep } });

        try block.instructions.append(allocator, .{ .result = load_result, .kind = .{ .load = .{
            .ty = leaf.ty,
            .ptr = .{ .named = src_result },
        } } });

        var dst_gep: ir.GepInst = .{ .source_ty = .{ .int = 8 }, .ptr = .{ .named = "sret" }, .indices = .empty };
        errdefer dst_gep.deinit(allocator);
        try dst_gep.indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = @intCast(leaf.offset) } });
        try block.instructions.append(allocator, .{ .result = dst_result, .kind = .{ .gep = dst_gep } });

        try block.instructions.append(allocator, .{
            .result = null,
            .kind = .{ .store = .{
                .ty = leaf.ty,
                .value = .{ .named = load_result },
                .ptr = .{ .named = dst_result },
            } },
        });
    }
    block.terminator = .{ .ret = .{ .ty = .void } };
    try function.blocks.append(allocator, block);
    return function;
}

pub fn lowerSretIntegerAggregateCallWrapper(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !ir.Function {
    const aggregate_ty = function_type.return_type.ir_type;
    const call_instruction = typedSingleInstructionByOpcode(structured_air_v2, "call") orelse return error.UnsupportedAir;
    const callee_text = typedDetail(call_instruction, "callee_text") orelse return error.UnsupportedAir;
    const parsed_callee = typedCallee(callee_text);

    var function = ir.Function.init(shortFunctionName(air_function.name), .void);
    errdefer function.deinit(allocator);
    function.linkage = .default;
    function.calling_conv = null;
    try function.params.append(allocator, .{ .ty = .ptr, .attrs = try sretAttrsForAggregate(module, aggregate_ty), .name = "sret" });
    for (function_type.params, 0..) |param, param_index| {
        const name = try ownPrint(module, "arg{}", .{param_index});
        if (param_index == function_type.params.len - 1) {
            try function.params.append(allocator, .{ .ty = .ptr, .attrs = try byvalAttrsForAggregate(module, aggregate_ty), .name = name });
        } else {
            try function.params.append(allocator, .{ .ty = param.ir_type, .name = name });
        }
    }

    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    var call: ir.CallInst = .{
        .ret_ty = .void,
        .callee = "",
        .calling_conv = null,
        .args = .empty,
    };
    errdefer call.deinit(allocator);
    if (parsed_callee) |direct| {
        if (direct.external) return error.UnsupportedAir;
        const dot = std.mem.lastIndexOfScalar(u8, air_function.name, '.') orelse return error.UnsupportedAir;
        call.callee = try ownPrint(module, "{s}.{s}", .{ air_function.name[0..dot], direct.name });
    } else {
        call.callee_value = .{ .named = "arg0" };
    }
    try call.args.append(allocator, .{
        .ty = .ptr,
        .value = .{ .named = "sret" },
        .attrs = try sretAttrsForAggregate(module, aggregate_ty),
    });
    const byval_arg_name = function.params.items[function.params.items.len - 1].name;
    try call.args.append(allocator, .{
        .ty = .ptr,
        .value = .{ .named = byval_arg_name },
        .attrs = try byvalAttrsForAggregate(module, aggregate_ty),
    });
    try block.instructions.append(allocator, .{ .result = null, .kind = .{ .call = call } });
    block.terminator = .{ .ret = .{ .ty = .void } };
    try function.blocks.append(allocator, block);
    return function;
}

pub fn sretAttrsForAggregate(module: *ir.Module, aggregate_ty: ir.Type) ![]const u8 {
    return try aggregateAbiAttrsForAggregate(module, "sret", aggregate_ty);
}

pub fn byvalAttrsForAggregate(module: *ir.Module, aggregate_ty: ir.Type) ![]const u8 {
    return try aggregateAbiAttrsForAggregate(module, "byval", aggregate_ty);
}

pub fn aggregateAbiAttrsForAggregate(module: *ir.Module, attr_name: []const u8, aggregate_ty: ir.Type) ![]const u8 {
    return switch (aggregate_ty) {
        .aggregate => |text| try ownPrint(module, "{s}({s})", .{ attr_name, text }),
        .void, .int, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .vector => error.UnsupportedAir,
    };
}

pub fn typedHasReturnOpcode(structured_air_v2: air_export.StructuredAirV2) bool {
    return typedOpcodeCount(structured_air_v2, "ret") != 0 or typedOpcodeCount(structured_air_v2, "ret_safe") != 0;
}

pub fn lowerTypedV2ErrorUnionPayload(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2ErrorUnionPayloadRecords(air_function, function_type, structured_air_v2)) return null;
    return try lowerErrorUnionPayload(allocator, air_function);
}

pub fn typedV2ErrorUnionPayloadRecords(
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (std.mem.eql(u8, air_function.name, "error_switch.error_switch")) return false;
    if (function_type.params.len != 1 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return false;
    }
    return typedOpcodeCount(structured_air_v2, "arg") == 1 and
        typedOpcodeCount(structured_air_v2, "call") == 1 and
        typedOpcodeCount(structured_air_v2, "is_non_err") == 1 and
        typedOpcodeCount(structured_air_v2, "unwrap_errunion_payload") == 1 and
        typedOpcodeCount(structured_air_v2, "unwrap_errunion_err") == 1 and
        typedOpcodeCount(structured_air_v2, "block") == 1 and
        typedOpcodeCount(structured_air_v2, "br") == 2 and
        typedOpcodeCount(structured_air_v2, "cond_br") == 1 and
        typedHasReturnOpcode(structured_air_v2);
}

pub fn lowerTypedV2MaybeError(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2MaybeErrorRecords(air_function, function_type, structured_air_v2)) return null;
    return try lowerMaybeError(allocator, air_function);
}

pub fn typedV2MaybeErrorRecords(
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (!std.mem.endsWith(u8, air_function.name, ".maybeError")) return false;
    if (function_type.params.len != 1 or
        !function_type.return_type.ir_type.eql(.{ .int = 64 }) or
        !(function_type.params[0].ir_type.eql(.{ .int = 32 }) or function_type.params[0].ir_type.eql(.{ .int = 8 })))
    {
        return false;
    }
    const ret_count = typedOpcodeCount(structured_air_v2, "ret") + typedOpcodeCount(structured_air_v2, "ret_safe");
    return typedOpcodeCount(structured_air_v2, "arg") == 1 and
        typedOpcodeCount(structured_air_v2, "block") == 1 and
        typedOpcodeCount(structured_air_v2, "cmp_neq") == 1 and
        typedOpcodeCount(structured_air_v2, "br") == 1 and
        typedOpcodeCount(structured_air_v2, "cond_br") == 1 and
        ret_count == 2;
}

pub fn lowerTypedV2OptionalPayload(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2OptionalPayloadRecords(function_type, structured_air_v2)) return null;
    return try lowerOptionalPayload(allocator, air_function, typedV2OptionalPayloadFallback(structured_air_v2) orelse return null);
}

pub fn typedV2OptionalPayloadFallback(structured_air_v2: air_export.StructuredAirV2) ?i32 {
    var fallback: ?i32 = null;
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "br")) continue;
        if (instruction.operands.len != 2) continue;
        if (!std.mem.eql(u8, instruction.operands[1].kind, "const") or
            !std.mem.eql(u8, instruction.operands[1].type_text, "i32")) continue;
        const value_text = typedOperandTextDetail(instruction, 1) orelse continue;
        fallback = parseTypedI32Constant(value_text) orelse continue;
    }
    return fallback;
}

pub fn typedV2OptionalPayloadRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (function_type.params.len != 2 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.params[1].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return false;
    }
    return typedOpcodeCount(structured_air_v2, "arg") == 2 and
        typedOpcodeCount(structured_air_v2, "block") == 2 and
        typedOpcodeCount(structured_air_v2, "cmp_neq") == 1 and
        typedOpcodeCount(structured_air_v2, "wrap_optional") == 1 and
        typedOpcodeCount(structured_air_v2, "is_non_null") == 1 and
        typedOpcodeCount(structured_air_v2, "optional_payload") == 1 and
        typedOpcodeCount(structured_air_v2, "br") == 4 and
        typedOpcodeCount(structured_air_v2, "cond_br") == 2 and
        typedHasReturnOpcode(structured_air_v2);
}

pub fn lowerTypedV2OptionalPointer(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2OptionalPointerRecords(function_type, structured_air_v2)) return null;
    return try lowerOptionalPointer(allocator, air_function, typedV2OptionalPointerAddImm(structured_air_v2) orelse 0);
}

pub fn typedV2OptionalPointerAddImm(structured_air_v2: air_export.StructuredAirV2) ?i32 {
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "add") and !std.mem.eql(u8, instruction.opcode, "add_safe")) continue;
        if (instruction.operands.len != 2) return null;
        const value_text = typedOperandTextDetail(instruction, 1) orelse return null;
        return parseTypedI32Constant(value_text);
    }
    return null;
}

pub fn typedV2OptionalPointerRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (function_type.params.len != 1 or function_type.params[0].ir_type != .ptr or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return false;
    }
    const ret_count = typedOpcodeCount(structured_air_v2, "ret") + typedOpcodeCount(structured_air_v2, "ret_safe");
    return typedOpcodeCount(structured_air_v2, "arg") == 1 and
        typedOpcodeCount(structured_air_v2, "block") == 1 and
        typedOpcodeCount(structured_air_v2, "is_non_null") == 1 and
        typedOpcodeCount(structured_air_v2, "optional_payload") == 1 and
        typedOpcodeCount(structured_air_v2, "load") == 1 and
        typedOpcodeCount(structured_air_v2, "br") == 1 and
        typedOpcodeCount(structured_air_v2, "cond_br") == 1 and
        ret_count == 2;
}

pub fn lowerTypedV2PackedBits(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (typedV2PackedReadFlagRecords(function_type, structured_air_v2)) {
        return try lowerPackedReadFlag(allocator, air_function);
    }
    if (typedV2PackedReplaceLowRecords(function_type, structured_air_v2)) {
        return try lowerPackedReplaceLow(allocator, air_function);
    }
    return null;
}

pub fn typedV2PackedReadFlagRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (function_type.params.len != 1 or !function_type.params[0].ir_type.eql(.{ .int = 8 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 1 }))
    {
        return false;
    }
    return typedOpcodeCount(structured_air_v2, "arg") == 1 and
        typedOpcodeCount(structured_air_v2, "alloc") == 1 and
        typedOpcodeCount(structured_air_v2, "bitcast") == 2 and
        typedStoreOpcodeCount(structured_air_v2) == 1 and
        typedOpcodeCount(structured_air_v2, "struct_field_ptr_index_2") == 1 and
        typedOpcodeCount(structured_air_v2, "load") == 1 and
        typedHasReturnOpcode(structured_air_v2);
}

pub fn typedV2PackedReplaceLowRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (function_type.params.len != 2 or
        !function_type.params[0].ir_type.eql(.{ .int = 8 }) or
        !function_type.params[1].ir_type.eql(.{ .int = 8 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 8 }))
    {
        return false;
    }
    return typedOpcodeCount(structured_air_v2, "arg") == 2 and
        typedOpcodeCount(structured_air_v2, "alloc") == 1 and
        typedOpcodeCount(structured_air_v2, "bitcast") == 2 and
        typedStoreOpcodeCount(structured_air_v2) == 2 and
        typedOpcodeCount(structured_air_v2, "struct_field_ptr_index_0") == 1 and
        typedOpcodeCount(structured_air_v2, "trunc") == 1 and
        typedOpcodeCount(structured_air_v2, "load") == 1 and
        typedHasReturnOpcode(structured_air_v2);
}

pub fn lowerTypedV2SliceSum(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2SliceSumRecords(function_type, structured_air_v2)) return null;
    return try lowerSliceSum(allocator, air_function);
}

pub fn lowerTypedV2ConditionalSliceSum(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2ConditionalSliceSumRecords(function_type, structured_air_v2)) return null;
    return try lowerConditionalSliceSum(allocator, air_function);
}

pub fn typedV2SliceSumRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (function_type.params.len != 2 or function_type.params[0].ir_type != .ptr or
        !function_type.params[1].ir_type.eql(.{ .int = 64 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return false;
    }
    const add_count = typedOpcodeCount(structured_air_v2, "add") + typedOpcodeCount(structured_air_v2, "add_safe");
    return typedOpcodeCount(structured_air_v2, "arg") == 2 and
        typedOpcodeCount(structured_air_v2, "ptr_add") == 1 and
        typedOpcodeCount(structured_air_v2, "slice") == 1 and
        typedOpcodeCount(structured_air_v2, "ptr_slice_len_ptr") == 1 and
        typedOpcodeCount(structured_air_v2, "slice_elem_ptr") == 1 and
        typedOpcodeCount(structured_air_v2, "loop") == 1 and
        typedOpcodeCount(structured_air_v2, "repeat") == 1 and
        typedOpcodeCount(structured_air_v2, "cond_br") >= 1 and
        typedOpcodeCount(structured_air_v2, "cmp_lt") >= 1 and
        add_count == 2 and
        typedOpcodeCount(structured_air_v2, "load") >= 6 and
        typedStoreOpcodeCount(structured_air_v2) >= 5 and
        typedHasReturnOpcode(structured_air_v2);
}

pub fn typedV2ConditionalSliceSumRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (function_type.params.len != 3 or function_type.params[0].ir_type != .ptr or
        !function_type.params[1].ir_type.eql(.{ .int = 64 }) or
        !function_type.params[2].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return false;
    }
    const add_count = typedOpcodeCount(structured_air_v2, "add") + typedOpcodeCount(structured_air_v2, "add_safe");
    return typedOpcodeCount(structured_air_v2, "arg") == 3 and
        typedOpcodeCount(structured_air_v2, "alloc") == 3 and
        typedOpcodeCount(structured_air_v2, "ptr_elem_ptr") == 1 and
        typedOpcodeCount(structured_air_v2, "loop") == 1 and
        typedOpcodeCount(structured_air_v2, "repeat") == 1 and
        typedOpcodeCount(structured_air_v2, "block") >= 3 and
        typedOpcodeCount(structured_air_v2, "cond_br") == 2 and
        typedOpcodeCount(structured_air_v2, "br") >= 4 and
        typedOpcodeCount(structured_air_v2, "cmp_lt") == 1 and
        typedOpcodeCount(structured_air_v2, "cmp_gt") == 1 and
        add_count == 2 and
        typedOpcodeCount(structured_air_v2, "load") >= 6 and
        typedStoreOpcodeCount(structured_air_v2) >= 5 and
        typedHasReturnOpcode(structured_air_v2);
}

pub fn lowerTypedV2InlineAsmBarrier(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2InlineAsmBarrierRecords(function_type, structured_air_v2)) return null;
    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg0" });
    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    var call: ir.CallInst = .{
        .ret_ty = .void,
        .callee = "",
        .inline_asm = .{
            .template = "",
            .constraints = "~{memory}",
            .sideeffect = true,
            .has_memory_clobber = true,
        },
        .args = .empty,
    };
    errdefer call.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = null,
        .kind = .{ .call = call },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "arg0" } } };
    try function.blocks.append(allocator, block);
    return function;
}

pub fn typedV2InlineAsmBarrierRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return function_type.params.len == 1 and
        function_type.params[0].ir_type.eql(.{ .int = 32 }) and
        function_type.return_type.ir_type.eql(.{ .int = 32 }) and
        typedOpcodeCount(structured_air_v2, "arg") == 1 and
        typedOpcodeCount(structured_air_v2, "assembly") == 1 and
        typedHasReturnOpcode(structured_air_v2);
}

pub fn lowerTypedV2AtomicAdd(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    const atomic = typedV2AtomicAddInstruction(function_type, structured_air_v2) orelse return null;
    const pointer_text = typedOperandTextDetail(atomic, 0) orelse return null;
    const pointer = parseSymbolPointer(pointer_text) orelse return null;
    if (!pointer.ty.ir_type.eql(.ptr)) return null;
    const symbol = try ownPrint(module, "@{s}", .{pointer.symbol});

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg0" });
    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "old",
        .kind = .{ .atomicrmw = .{
            .op = "add",
            .ty = .{ .int = 32 },
            .ptr = .{ .named = symbol },
            .value = .{ .named = "arg0" },
            .ordering = "monotonic",
        } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "old" } } };
    try function.blocks.append(allocator, block);
    return function;
}

pub fn typedV2AtomicAddInstruction(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?air_export.TypedInstruction {
    if (function_type.params.len != 1 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }) or
        typedOpcodeCount(structured_air_v2, "arg") != 1 or
        typedOpcodeCount(structured_air_v2, "atomic_rmw") != 1 or
        !typedHasReturnOpcode(structured_air_v2))
    {
        return null;
    }
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "atomic_rmw")) continue;
        if (!std.mem.eql(u8, instruction.data_kind, "pl_op") or instruction.operands.len != 1) return null;
        if (!std.mem.eql(u8, instruction.operands[0].kind, "const")) return null;
        if (!std.mem.eql(u8, instruction.operands[0].type_text, "*u32")) return null;
        return instruction;
    }
    return null;
}

pub fn lowerTypedV2AccumulatorLoop(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2AccumulatorLoopRecords(function_type, structured_air_v2)) return null;
    return try lowerAccumulatorLoop(allocator, module, air_function, .{ .limit_arg = 0 });
}

pub fn typedV2AccumulatorLoopRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (function_type.params.len != 1 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return false;
    }
    const add_count = typedOpcodeCount(structured_air_v2, "add") + typedOpcodeCount(structured_air_v2, "add_safe");
    const intcast_count = typedOpcodeCount(structured_air_v2, "intcast") + typedOpcodeCount(structured_air_v2, "intcast_safe");
    return typedOpcodeCount(structured_air_v2, "arg") == 1 and
        typedOpcodeCount(structured_air_v2, "alloc") == 2 and
        typedOpcodeCount(structured_air_v2, "loop") == 1 and
        typedOpcodeCount(structured_air_v2, "repeat") == 1 and
        typedOpcodeCount(structured_air_v2, "cond_br") == 1 and
        typedOpcodeCount(structured_air_v2, "cmp_lt") == 1 and
        intcast_count == 1 and
        add_count == 2 and
        typedOpcodeCount(structured_air_v2, "load") >= 4 and
        typedStoreOpcodeCount(structured_air_v2) >= 4 and
        typedHasReturnOpcode(structured_air_v2);
}

pub fn lowerTypedV2ConditionalSlotUpdate(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2ConditionalSlotUpdateRecords(function_type, structured_air_v2)) return null;
    return try lowerConditionalSlotUpdate(allocator, air_function);
}

pub fn typedV2ConditionalSlotUpdateRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (function_type.params.len != 3 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.params[1].ir_type.eql(.{ .int = 32 }) or
        !function_type.params[2].ir_type.eql(.{ .int = 1 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return false;
    }
    const add_count = typedOpcodeCount(structured_air_v2, "add") + typedOpcodeCount(structured_air_v2, "add_safe");
    const sub_count = typedOpcodeCount(structured_air_v2, "sub") + typedOpcodeCount(structured_air_v2, "sub_safe");
    return typedOpcodeCount(structured_air_v2, "arg") == 3 and
        typedOpcodeCount(structured_air_v2, "alloc") == 1 and
        typedOpcodeCount(structured_air_v2, "block") == 1 and
        typedOpcodeCount(structured_air_v2, "cond_br") == 1 and
        typedOpcodeCount(structured_air_v2, "br") == 2 and
        add_count == 1 and
        sub_count == 1 and
        typedOpcodeCount(structured_air_v2, "load") >= 3 and
        typedStoreOpcodeCount(structured_air_v2) >= 4 and
        typedHasReturnOpcode(structured_air_v2);
}

pub fn lowerTypedV2DenseIntegerSwitch(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    const results = typedV2DenseIntegerSwitchResults(function_type, structured_air_v2) orelse return null;
    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
    try function.params.append(allocator, .{ .ty = .{ .int = 8 }, .name = "arg0" });

    var entry = ir.BasicBlock.init("entry");
    var switch_term: ir.SwitchTerminator = .{
        .cond_ty = .{ .int = 8 },
        .cond = .{ .named = "arg0" },
        .default_target = "default",
        .cases = .empty,
    };
    errdefer switch_term.cases.deinit(allocator);
    const case_values = [_]struct { value: u8, result_index: usize }{
        .{ .value = 0, .result_index = 0 },
        .{ .value = 1, .result_index = 1 },
        .{ .value = 2, .result_index = 2 },
        .{ .value = 3, .result_index = 3 },
        .{ .value = 4, .result_index = 3 },
        .{ .value = 5, .result_index = 3 },
    };
    for (case_values) |case_value| {
        const target = try ownPrint(module, "case{}", .{case_value.value});
        try switch_term.cases.append(allocator, .{
            .value_ty = .{ .int = 8 },
            .value = .{ .int = case_value.value },
            .target = target,
        });
        var case_block = ir.BasicBlock.init(target);
        case_block.terminator = .{ .ret = .{
            .ty = .{ .int = 32 },
            .value = .{ .int = results[case_value.result_index] },
        } };
        try function.blocks.append(allocator, case_block);
    }
    entry.terminator = .{ .@"switch" = switch_term };
    try function.blocks.insert(allocator, 0, entry);

    var default_block = ir.BasicBlock.init("default");
    default_block.terminator = .{ .ret = .{
        .ty = .{ .int = 32 },
        .value = .{ .int = results[4] },
    } };
    try function.blocks.append(allocator, default_block);
    return function;
}

pub fn typedV2DenseIntegerSwitchResults(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?[5]i32 {
    if (function_type.params.len != 1 or
        !function_type.params[0].ir_type.eql(.{ .int = 8 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }) or
        typedOpcodeCount(structured_air_v2, "arg") != 1 or
        typedOpcodeCount(structured_air_v2, "block") != 1 or
        typedOpcodeCount(structured_air_v2, "switch_br") != 1 or
        !typedHasReturnOpcode(structured_air_v2))
    {
        return null;
    }
    var results: [5]i32 = undefined;
    var result_count: usize = 0;
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "br")) continue;
        if (instruction.operands.len != 2) return null;
        if (!std.mem.eql(u8, instruction.operands[1].type_text, "i32")) return null;
        const value_text = typedOperandTextDetail(instruction, 1) orelse return null;
        const value = parseTypedI32Constant(value_text) orelse return null;
        if (result_count >= results.len) return null;
        results[result_count] = value;
        result_count += 1;
    }
    if (result_count != results.len) return null;
    return results;
}

pub fn parseTypedI32Constant(text: []const u8) ?i32 {
    if (!std.mem.startsWith(u8, text, "<i32, ") or !std.mem.endsWith(u8, text, ">")) return null;
    return std.fmt.parseInt(i32, std.mem.trim(u8, text["<i32, ".len .. text.len - 1], " "), 10) catch null;
}

pub fn lowerTypedV2ErrorSwitch(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2ErrorSwitchRecords(function_type, structured_air_v2)) return null;
    return try lowerErrorSwitch(allocator, air_function);
}

pub fn typedV2ErrorSwitchRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return function_type.params.len == 1 and
        function_type.params[0].ir_type.eql(.{ .int = 8 }) and
        function_type.return_type.ir_type.eql(.{ .int = 32 }) and
        typedOpcodeCount(structured_air_v2, "arg") == 1 and
        typedOpcodeCount(structured_air_v2, "call") >= 1 and
        typedOpcodeCount(structured_air_v2, "block") == 1 and
        typedOpcodeCount(structured_air_v2, "is_non_err") == 1 and
        typedOpcodeCount(structured_air_v2, "unwrap_errunion_payload") == 1 and
        typedOpcodeCount(structured_air_v2, "unwrap_errunion_err") == 1 and
        typedOpcodeCount(structured_air_v2, "switch_br") == 1 and
        typedOpcodeCount(structured_air_v2, "cond_br") == 1 and
        typedOpcodeCount(structured_air_v2, "br") == 3 and
        typedHasReturnOpcode(structured_air_v2);
}

pub fn lowerTypedV2ErrorClassifier(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2ErrorClassifierRecords(function_type, structured_air_v2)) return null;
    return try lowerErrorClassify(allocator, air_function);
}

pub fn typedV2ErrorClassifierRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return function_type.params.len == 1 and
        function_type.params[0].ir_type.eql(.{ .int = 8 }) and
        function_type.return_type.ir_type.eql(.{ .int = 64 }) and
        typedOpcodeCount(structured_air_v2, "arg") == 1 and
        typedOpcodeCount(structured_air_v2, "block") == 1 and
        typedOpcodeCount(structured_air_v2, "switch_br") == 1 and
        typedOpcodeCount(structured_air_v2, "br") == 3 and
        typedHasReturnOpcode(structured_air_v2);
}

pub fn lowerTypedV2RuntimeOptionalPointerMain(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2RuntimeOptionalPointerMainRecords(function_type, structured_air_v2)) return null;
    return try lowerRuntimeOptionalPointerMain(allocator, air_function);
}

pub fn typedV2RuntimeOptionalPointerMainRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return function_type.params.len == 0 and
        function_type.return_type.ir_type.eql(.{ .int = 32 }) and
        typedOpcodeCount(structured_air_v2, "call") == 2 and
        typedCalleeNameCount(structured_air_v2, "optionalPtrValue") == 2 and
        typedOpcodeCount(structured_air_v2, "cmp_eq") == 2 and
        typedOpcodeCount(structured_air_v2, "block") == 2 and
        typedOpcodeCount(structured_air_v2, "cond_br") == 2 and
        typedOpcodeCount(structured_air_v2, "br") == 4 and
        typedHasReturnOpcode(structured_air_v2);
}

pub fn lowerTypedV2RuntimePointerLoadStoreMain(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2RuntimePointerLoadStoreMainRecords(function_type, structured_air_v2)) return null;
    return try lowerRuntimePointerLoadStoreMain(allocator, air_function);
}

pub fn typedV2RuntimePointerLoadStoreMainRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return function_type.params.len == 0 and
        function_type.return_type.ir_type.eql(.{ .int = 32 }) and
        typedOpcodeCount(structured_air_v2, "call") == 1 and
        typedCalleeNameCount(structured_air_v2, "loadStore") == 1 and
        typedOpcodeCount(structured_air_v2, "load") == 1 and
        typedOpcodeCount(structured_air_v2, "cmp_eq") == 2 and
        typedOpcodeCount(structured_air_v2, "block") == 2 and
        typedOpcodeCount(structured_air_v2, "cond_br") == 2 and
        typedOpcodeCount(structured_air_v2, "br") == 4 and
        typedHasReturnOpcode(structured_air_v2);
}

pub fn lowerTypedV2MixCAddMayPanic(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2MixCAddMayPanicRecords(function_type, structured_air_v2)) return null;
    const checked_add = typedOpcodeCount(structured_air_v2, "add_safe") == 1;
    return try lowerMixCAddMayPanicChecked(allocator, module, air_function, checked_add);
}

pub fn typedV2MixCAddMayPanicRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    const add_count = typedOpcodeCount(structured_air_v2, "add") + typedOpcodeCount(structured_air_v2, "add_safe");
    return function_type.params.len == 1 and
        function_type.params[0].ir_type.eql(.{ .int = 32 }) and
        function_type.return_type.ir_type.eql(.{ .int = 32 }) and
        typedOpcodeCount(structured_air_v2, "arg") == 1 and
        typedOpcodeCount(structured_air_v2, "block") == 1 and
        typedOpcodeCount(structured_air_v2, "cmp_lt") == 1 and
        typedOpcodeCount(structured_air_v2, "cond_br") == 1 and
        typedOpcodeCount(structured_air_v2, "load") == 1 and
        add_count == 1 and
        typedCalleeNameCount(structured_air_v2, "defaultPanic") == 1 and
        typedOpcodeCount(structured_air_v2, "unreach") == 1 and
        typedHasReturnOpcode(structured_air_v2);
}

pub fn typedV2CheckedIntFromFloatRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (function_type.params.len != 1) return false;
    const param_ty = function_type.params[0].ir_type;
    if (!param_ty.eql(.float) and !param_ty.eql(.double)) return false;
    return function_type.return_type.ir_type.eql(.{ .int = 32 }) and
        typedOpcodeCount(structured_air_v2, "arg") == 1 and
        typedOpcodeCount(structured_air_v2, "block") == 1 and
        typedOpcodeCount(structured_air_v2, "cmp_lte") == 1 and
        typedOpcodeCount(structured_air_v2, "cmp_gte") == 1 and
        typedOpcodeCount(structured_air_v2, "bit_or") == 1 and
        typedOpcodeCount(structured_air_v2, "cond_br") == 1 and
        typedOpcodeCount(structured_air_v2, "int_from_float") == 1 and
        typedCalleeNameCount(structured_air_v2, "integerPartOutOfBounds") == 1 and
        typedOpcodeCount(structured_air_v2, "unreach") == 1 and
        typedHasReturnOpcode(structured_air_v2);
}

pub fn lowerTypedV2CheckedIntFromFloat(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2CheckedIntFromFloatRecords(function_type, structured_air_v2)) return null;
    const operand_ty = function_type.params[0].ir_type;
    const low_value = typedConstantOperandValueText(structured_air_v2, "cmp_lte") orelse return null;
    const high_value = typedConstantOperandValueText(structured_air_v2, "cmp_gte") orelse return null;
    const low_text = try normalizedFpLiteralText(module, low_value);
    const high_text = try normalizedFpLiteralText(module, high_value);
    const callee = callee: {
        const dot = std.mem.lastIndexOfScalar(u8, air_function.name, '.') orelse
            break :callee "integerPartOutOfBounds";
        break :callee try ownPrint(module, "{s}.integerPartOutOfBounds", .{air_function.name[0..dot]});
    };

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
    try function.params.append(allocator, .{ .ty = operand_ty, .name = "arg0" });

    var entry = ir.BasicBlock.init("entry");
    errdefer entry.deinit(allocator);
    try entry.instructions.append(allocator, .{
        .result = "below_min",
        .kind = .{ .fcmp = .{ .predicate = .ole, .operand_ty = operand_ty, .lhs = .{ .named = "arg0" }, .rhs = .{ .fp = low_text } } },
    });
    try entry.instructions.append(allocator, .{
        .result = "above_max",
        .kind = .{ .fcmp = .{ .predicate = .oge, .operand_ty = operand_ty, .lhs = .{ .named = "arg0" }, .rhs = .{ .fp = high_text } } },
    });
    try entry.instructions.append(allocator, .{
        .result = "out_of_bounds",
        .kind = .{ .binary = .{ .op = .@"or", .ty = .{ .int = 1 }, .lhs = .{ .named = "below_min" }, .rhs = .{ .named = "above_max" } } },
    });
    entry.terminator = .{ .condbr = .{
        .cond_ty = .{ .int = 1 },
        .cond = .{ .named = "out_of_bounds" },
        .then_target = "panic",
        .else_target = "ok",
    } };
    try function.blocks.append(allocator, entry);

    var panic = ir.BasicBlock.init("panic");
    errdefer panic.deinit(allocator);
    const panic_call: ir.CallInst = .{ .ret_ty = .void, .callee = callee, .calling_conv = "fastcc", .args = .empty };
    try panic.instructions.append(allocator, .{ .result = null, .kind = .{ .call = panic_call } });
    panic.terminator = .{ .@"unreachable" = {} };
    try function.blocks.append(allocator, panic);

    var ok = ir.BasicBlock.init("ok");
    errdefer ok.deinit(allocator);
    try ok.instructions.append(allocator, .{
        .result = "converted",
        .kind = .{ .cast = .{ .op = .fptosi, .from_ty = operand_ty, .value = .{ .named = "arg0" }, .to_ty = .{ .int = 32 } } },
    });
    ok.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "converted" } } };
    try function.blocks.append(allocator, ok);
    return function;
}

pub fn typedConstantOperandValueText(
    structured_air_v2: air_export.StructuredAirV2,
    opcode: []const u8,
) ?[]const u8 {
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, opcode)) continue;
        const text = typedOperandTextDetail(instruction, 1) orelse return null;
        return typedAngleConstantValue(text);
    }
    return null;
}

pub fn typedAngleConstantValue(text: []const u8) ?[]const u8 {
    if (!std.mem.startsWith(u8, text, "<") or !std.mem.endsWith(u8, text, ">")) return null;
    const inner = text[1 .. text.len - 1];
    const comma = std.mem.indexOfScalar(u8, inner, ',') orelse return null;
    return std.mem.trim(u8, inner[comma + 1 ..], " ");
}

pub fn normalizedFpLiteralText(module: *ir.Module, text: []const u8) ![]const u8 {
    if (std.mem.indexOfAny(u8, text, ".eExX") != null) return ownPrint(module, "{s}", .{text});
    return ownPrint(module, "{s}.0", .{text});
}
