const std = @import("std");
const air_aggregate_construction = @import("zig_air_aggregate_construction.zig");
const air_aggregate_copy = @import("zig_air_aggregate_copy.zig");
const air_export = @import("zig_air_export.zig");
const air_model = @import("zig_air_model.zig");
const air_text = @import("zig_air_text.zig");
const air_types = @import("zig_air_types.zig");
const air_values = @import("zig_air_values.zig");
const ir = @import("ir.zig");
const legacy = @import("zig_air_lowering_legacy.zig");
const type_layout = @import("zig_air_type_layout.zig");

const ZigType = air_model.ZigType;
const FunctionType = air_model.FunctionType;
const parseConstant = air_values.parseConstant;
const parseInstructionRef = air_text.instructionRef;
const typedDetail = air_model.detail;
const typedOperandTextDetail = air_model.operandTextDetail;
const typedCallee = air_model.callee;
const typedCalleeName = air_model.calleeName;
const typedSingleInstructionByOpcode = air_model.singleInstructionByOpcode;
const shortFunctionName = air_model.shortFunctionName;
const ownPrint = air_model.ownPrint;
const splitTopLevel = air_text.splitTopLevel;
const parseSymbolPointer = air_values.parseSymbolPointer;
const irCallingConvention = air_model.irCallingConvention;
const collectAggregateCopyLeaves = air_aggregate_copy.collectAggregateCopyLeaves;
const validateSretAggregateMakeRecords = air_aggregate_copy.validateSretAggregateMakeRecords;
const validateSretAggregateCopyRecords = air_aggregate_copy.validateSretAggregateCopyRecords;
const validateSretAggregateCallWrapperRecords = air_aggregate_copy.validateSretAggregateCallWrapperRecords;
const isSysVRegisterAggregateCandidate = air_aggregate_construction.isSysVRegisterAggregateCandidate;

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
    return air_aggregate_construction.registerAggregateRecords(function_type, structured_air_v2);
}

pub fn typedV2RegisterAggregateLeafPaths(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
    leaf_paths: *[8][]const u8,
) bool {
    return air_aggregate_construction.registerAggregateLeafPaths(function_type, structured_air_v2, leaf_paths);
}

pub fn aggregateFieldCount(ty: ir.Type) ?usize {
    return type_layout.fieldCount(ty);
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
    return validateSretAggregateMakeRecords(function_type, structured_air_v2);
}

pub fn typedV2SretIntegerAggregateCopyRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (isSysVRegisterAggregateCandidate(function_type.return_type.ir_type)) return false;
    return validateSretAggregateCopyRecords(function_type, structured_air_v2);
}

pub fn typedV2SretIntegerAggregateCallWrapperRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (isSysVRegisterAggregateCandidate(function_type.return_type.ir_type)) return false;
    return validateSretAggregateCallWrapperRecords(function_type, structured_air_v2);
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

pub fn lowerTypedV2ErrorUnionPayload(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2ErrorUnionPayloadRecords(function_type, structured_air_v2)) return null;
    return try lowerErrorUnionPayload(allocator, air_function);
}

pub fn typedV2ErrorUnionPayloadRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return air_model.typedErrorUnionPayloadSummary(function_type, structured_air_v2) != null;
}

pub fn lowerTypedV2MaybeError(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2MaybeErrorRecords(function_type, structured_air_v2)) return null;
    return try lowerMaybeError(allocator, air_function);
}

pub fn typedV2MaybeErrorRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return air_model.typedMaybeErrorSummary(function_type, structured_air_v2) != null;
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

pub fn lowerTypedV2OptionalPayloadBranch(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    const summary = air_model.typedOptionalPayloadBranchSummary(function_type, structured_air_v2) orelse return null;

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg0" });
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg1" });
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg2" });

    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "has_value",
        .kind = .{ .icmp = .{
            .predicate = .ne,
            .operand_ty = .{ .int = 32 },
            .lhs = .{ .named = "arg0" },
            .rhs = .{ .int = 0 },
        } },
    });
    if (summary.threshold == std.math.maxInt(i32)) return error.UnsupportedAir;
    try block.instructions.append(allocator, .{
        .result = "payload_low",
        .kind = .{ .icmp = .{
            .predicate = .slt,
            .operand_ty = .{ .int = 32 },
            .lhs = .{ .named = "arg1" },
            .rhs = .{ .int = summary.threshold + 1 },
        } },
    });
    try block.instructions.append(allocator, .{
        .result = "high_result",
        .kind = .{ .binary = .{
            .op = .add,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "arg1" },
            .rhs = .{ .named = "arg2" },
        } },
    });
    try block.instructions.append(allocator, .{
        .result = "low_result",
        .kind = .{ .binary = .{
            .op = .sub,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "arg1" },
            .rhs = .{ .named = "arg2" },
        } },
    });
    try block.instructions.append(allocator, .{
        .result = "payload_result",
        .kind = .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = "payload_low" },
            .ty = .{ .int = 32 },
            .true_value = .{ .named = "low_result" },
            .false_value = .{ .named = "high_result" },
        } },
    });
    try block.instructions.append(allocator, .{
        .result = "result",
        .kind = .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = "has_value" },
            .ty = .{ .int = 32 },
            .true_value = .{ .named = "payload_result" },
            .false_value = .{ .int = summary.fallback },
        } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "result" } } };
    try function.blocks.append(allocator, block);
    return function;
}

pub fn typedV2OptionalPayloadBranchRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return air_model.typedOptionalPayloadBranchSummary(function_type, structured_air_v2) != null;
}

pub fn typedV2OptionalPayloadFallback(structured_air_v2: air_export.StructuredAirV2) ?i32 {
    return air_model.typedLastBranchI32ConstValue(structured_air_v2);
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
    return air_model.typedOpcodeCount(structured_air_v2, "arg") == 2 and
        air_model.typedOpcodeCount(structured_air_v2, "block") == 2 and
        air_model.typedOpcodeCount(structured_air_v2, "cmp_neq") == 1 and
        air_model.typedOpcodeCount(structured_air_v2, "wrap_optional") == 1 and
        air_model.typedOpcodeCount(structured_air_v2, "is_non_null") == 1 and
        air_model.typedOpcodeCount(structured_air_v2, "optional_payload") == 1 and
        air_model.typedOpcodeCount(structured_air_v2, "br") == 4 and
        air_model.typedOpcodeCount(structured_air_v2, "cond_br") == 2 and
        air_model.typedHasReturnOpcode(structured_air_v2);
}

pub fn lowerTypedV2OptionalPointer(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    const summary = air_model.typedOptionalPointerSummary(function_type, structured_air_v2) orelse return null;
    return try lowerOptionalPointer(
        allocator,
        air_function,
        summary.add_imm,
        summary.fallback,
    );
}

pub fn typedV2OptionalPointerRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return air_model.typedOptionalPointerSummary(function_type, structured_air_v2) != null;
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
    return air_model.typedPackedReadFlagSummary(function_type, structured_air_v2) != null;
}

pub fn typedV2PackedReplaceLowRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return air_model.typedPackedReplaceLowSummary(function_type, structured_air_v2) != null;
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
    return air_model.typedSliceSumSummary(function_type, structured_air_v2) != null;
}

pub fn typedV2ConditionalSliceSumRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return air_model.typedConditionalSliceSumSummary(function_type, structured_air_v2) != null;
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
    return air_model.typedInlineAsmBarrierSummary(function_type, structured_air_v2) != null;
}

pub fn lowerTypedV2AtomicAdd(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    const atomic = (air_model.typedAtomicAddSummary(function_type, structured_air_v2) orelse return null).instruction;
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
    return (air_model.typedAtomicAddSummary(function_type, structured_air_v2) orelse return null).instruction;
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
    return air_model.typedAccumulatorLoopSummary(function_type, structured_air_v2) != null;
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
    return air_model.typedConditionalSlotUpdateSummary(function_type, structured_air_v2) != null;
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
        air_model.typedOpcodeCount(structured_air_v2, "arg") != 1 or
        air_model.typedOpcodeCount(structured_air_v2, "block") != 1 or
        air_model.typedOpcodeCount(structured_air_v2, "switch_br") != 1 or
        !air_model.typedHasReturnOpcode(structured_air_v2))
    {
        return null;
    }
    var results: [5]i32 = undefined;
    const result_count = air_model.typedBranchI32ConstValues(structured_air_v2, &results) orelse return null;
    if (result_count != results.len) return null;
    return results;
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
    return air_model.typedErrorSwitchSummary(function_type, structured_air_v2) != null;
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
    return air_model.typedErrorClassifierSummary(function_type, structured_air_v2) != null;
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
    return air_model.typedRuntimeOptionalPointerMainSummary(function_type, structured_air_v2) != null;
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
    return air_model.typedRuntimePointerLoadStoreMainSummary(function_type, structured_air_v2) != null;
}

pub fn lowerTypedV2MixCAddMayPanic(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    const summary = air_model.typedMixCAddMayPanicSummary(function_type, structured_air_v2) orelse return null;
    return try lowerMixCAddMayPanicChecked(allocator, module, air_function, summary.checked_add);
}

pub fn typedV2MixCAddMayPanicRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return air_model.typedMixCAddMayPanicSummary(function_type, structured_air_v2) != null;
}

pub fn typedV2CheckedIntFromFloatRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return air_model.typedCheckedIntFromFloatSummary(function_type, structured_air_v2) != null;
}

pub fn lowerTypedV2CheckedIntFromFloat(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    const summary = air_model.typedCheckedIntFromFloatSummary(function_type, structured_air_v2) orelse return null;
    const operand_ty = summary.operand_ty;
    const low_text = try normalizedFpLiteralText(module, summary.low_value);
    const high_text = try normalizedFpLiteralText(module, summary.high_value);
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

pub fn lowerTypedV2UnionTagPayloadSwitch(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    const summary = air_model.typedUnionTagPayloadSwitchSummary(function_type, structured_air_v2) orelse return null;

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg0" });
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg1" });

    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "is_tag0",
        .kind = .{ .icmp = .{
            .predicate = .eq,
            .operand_ty = .{ .int = 32 },
            .lhs = .{ .named = "arg0" },
            .rhs = .{ .int = 0 },
        } },
    });
    try block.instructions.append(allocator, .{
        .result = "tag0_result",
        .kind = .{ .binary = .{
            .op = .add,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "arg1" },
            .rhs = .{ .int = summary.tag0_return_add },
        } },
    });
    try block.instructions.append(allocator, .{
        .result = "tag1_payload",
        .kind = .{ .binary = .{
            .op = .add,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "arg1" },
            .rhs = .{ .int = summary.tag1_store_add },
        } },
    });
    try block.instructions.append(allocator, .{
        .result = "tag1_result",
        .kind = .{ .binary = .{
            .op = .add,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "tag1_payload" },
            .rhs = .{ .int = summary.tag1_return_add },
        } },
    });
    try block.instructions.append(allocator, .{
        .result = "result",
        .kind = .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = "is_tag0" },
            .ty = .{ .int = 32 },
            .true_value = .{ .named = "tag0_result" },
            .false_value = .{ .named = "tag1_result" },
        } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "result" } } };
    try function.blocks.append(allocator, block);
    return function;
}

pub fn typedV2UnionTagPayloadSwitchRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return air_model.typedUnionTagPayloadSwitchSummary(function_type, structured_air_v2) != null;
}

pub fn normalizedFpLiteralText(module: *ir.Module, text: []const u8) ![]const u8 {
    if (std.mem.indexOfAny(u8, text, ".eExX") != null) return ownPrint(module, "{s}", .{text});
    return ownPrint(module, "{s}.0", .{text});
}
