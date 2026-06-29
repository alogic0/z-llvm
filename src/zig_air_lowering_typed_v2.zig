const std = @import("std");
const air_aggregate_construction = @import("zig_air_aggregate_construction.zig");
const air_aggregate_copy = @import("zig_air_aggregate_copy.zig");
const air_export = @import("zig_air_export.zig");
const error_union_call_facts = @import("zig_air_error_union_call_facts.zig");
const air_model = @import("zig_air_model.zig");
const air_text = @import("zig_air_text.zig");
const air_types = @import("zig_air_types.zig");
const air_values = @import("zig_air_values.zig");
const ir = @import("ir.zig");
const runtime_wrappers = @import("zig_air_runtime_wrappers.zig");
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
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
    fact_provider: ?error_union_call_facts.Provider,
    fact_fallback_reason: ?*?[]const u8,
) !?ir.Function {
    const flow = switch (air_model.typedErrorUnionFlow(function_type, structured_air_v2)) {
        .flow => |flow| flow,
        .diagnostic => return null,
    };
    if (flow.payload_kind != .call_produced) return null;
    return try lowerErrorUnionPayloadFromFact(allocator, module, air_function, function_type, flow, fact_provider, fact_fallback_reason);
}

pub fn typedV2ErrorUnionPayloadRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return air_model.typedErrorUnionPayloadSummary(function_type, structured_air_v2) != null;
}

fn lowerErrorUnionPayloadFromFact(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    flow: air_model.TypedErrorUnionFlow,
    fact_provider: ?error_union_call_facts.Provider,
    fact_fallback_reason: ?*?[]const u8,
) !ir.Function {
    if (function_type.params.len != 1 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        setErrorUnionCallFactFallback(fact_fallback_reason, "unsupported_error_union_payload_signature");
        return error.UnsupportedAir;
    }
    const call_inst = flow.call_result_owner orelse {
        setErrorUnionCallFactFallback(fact_fallback_reason, "missing_call_result_owner");
        return error.UnsupportedAir;
    };
    if (flow.post_success_branch_target == null or flow.post_catch_branch_target == null) {
        setErrorUnionCallFactFallback(fact_fallback_reason, "missing_error_union_branch_target");
        return error.UnsupportedAir;
    }
    const catch_value = flow.catch_value_i32 orelse {
        setErrorUnionCallFactFallback(fact_fallback_reason, "missing_catch_i32_value");
        return error.UnsupportedAir;
    };
    const provider = fact_provider orelse {
        setErrorUnionCallFactFallback(fact_fallback_reason, "missing_error_union_call_fact_provider");
        return error.UnsupportedAir;
    };
    const fact = provider.lookup(air_function.name, call_inst) orelse {
        setErrorUnionCallFactFallback(fact_fallback_reason, "missing_error_union_call_fact");
        return error.UnsupportedAir;
    };
    if (fact.success_arg_index != 0) {
        setErrorUnionCallFactFallback(fact_fallback_reason, "unsupported_error_union_success_argument");
        return error.UnsupportedAir;
    }
    if (!isI32ErrorUnionResultType(fact.result_type)) {
        setErrorUnionCallFactFallback(fact_fallback_reason, "unsupported_error_union_fact_result_type");
        return error.UnsupportedAir;
    }

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg0" });
    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "is_success",
        .kind = .{ .icmp = .{
            .predicate = .eq,
            .operand_ty = .{ .int = 32 },
            .lhs = .{ .named = "arg0" },
            .rhs = .{ .int = fact.success_arg_eq_i32 },
        } },
    });
    try block.instructions.append(allocator, .{
        .result = "result",
        .kind = .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = "is_success" },
            .ty = .{ .int = 32 },
            .true_value = .{ .int = fact.success_payload_i32 },
            .false_value = .{ .int = catch_value },
        } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "result" } } };
    try function.blocks.append(allocator, block);
    _ = module;
    return function;
}

fn isI32ErrorUnionResultType(text: []const u8) bool {
    return std.mem.startsWith(u8, text, "error{") and std.mem.endsWith(u8, text, "!i32");
}

fn setErrorUnionCallFactFallback(fallback_reason: ?*?[]const u8, reason: []const u8) void {
    const slot = fallback_reason orelse return;
    if (slot.* != null) return;
    slot.* = reason;
}

test "typed-v2 error-union payload reports missing call fact provider" {
    var i32_param = [_]ZigType{
        .{ .ir_type = .{ .int = 32 } },
    };
    const function_type = FunctionType{
        .params = &i32_param,
        .return_type = .{ .ir_type = .{ .int = 32 } },
        .c_calling_convention = true,
        .non_default_calling_convention = false,
    };
    var is_non_err_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "1", .type_text = "error{Bad}!i32" },
    };
    var payload_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "1", .type_text = "error{Bad}!i32" },
    };
    var err_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "1", .type_text = "error{Bad}!i32" },
    };
    var success_br_operands = [_]air_export.TypedOperand{
        .{ .kind = "block", .value = "5", .type_text = "block" },
        .{ .kind = "inst", .value = "3", .type_text = "i32" },
    };
    var catch_br_operands = [_]air_export.TypedOperand{
        .{ .kind = "block", .value = "5", .type_text = "block" },
        .{ .kind = "const", .value = "-", .type_text = "i32" },
    };
    var catch_br_details = [_]air_export.TypedDetail{
        .{ .key = "operand1_text", .value = "<i32, -1>" },
    };
    var cond_br_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "2", .type_text = "bool" },
    };
    var call_details = [_]air_export.TypedDetail{
        .{ .key = "call_signature", .value = "fn (i32) error{Bad}!i32" },
        .{ .key = "callee_text", .value = "(function 'maybeError')" },
    };
    var instructions = [_]air_export.TypedInstruction{
        .{ .index = 0, .opcode = "arg", .result_type = "i32", .data_kind = "arg", .operands = &.{} },
        .{ .index = 1, .opcode = "call", .result_type = "error{Bad}!i32", .data_kind = "pl_op", .operands = &.{}, .details = &call_details },
        .{ .index = 2, .opcode = "is_non_err", .result_type = "i1", .data_kind = "un_op", .operands = &is_non_err_operands },
        .{ .index = 3, .opcode = "unwrap_errunion_payload", .result_type = "i32", .data_kind = "ty_op", .operands = &payload_operands },
        .{ .index = 4, .opcode = "unwrap_errunion_err", .result_type = "i16", .data_kind = "ty_op", .operands = &err_operands },
        .{ .index = 5, .opcode = "block", .result_type = "void", .data_kind = "ty_pl", .operands = &.{} },
        .{ .index = 6, .opcode = "br", .result_type = "noreturn", .data_kind = "br", .operands = &success_br_operands },
        .{ .index = 7, .opcode = "br", .result_type = "noreturn", .data_kind = "br", .operands = &catch_br_operands, .details = &catch_br_details },
        .{ .index = 8, .opcode = "cond_br", .result_type = "noreturn", .data_kind = "pl_op", .operands = &cond_br_operands },
        .{ .index = 9, .opcode = "ret", .result_type = "noreturn", .data_kind = "un_op", .operands = &.{} },
    };
    const structured_air_v2 = air_export.StructuredAirV2{ .instructions = &instructions };
    const air_function = air_export.Function{
        .name = "aggregates.error_union_payload",
        .type_text = "fn(i32) callconv(.c) i32",
        .instruction_count = instructions.len,
        .main_body_count = instructions.len,
        .has_liveness = false,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = structured_air_v2,
        .instructions = &.{},
    };

    var module: ir.Module = undefined;
    var reason: ?[]const u8 = null;
    try std.testing.expectError(
        error.UnsupportedAir,
        lowerTypedV2ErrorUnionPayload(
            std.testing.allocator,
            &module,
            air_function,
            function_type,
            structured_air_v2,
            null,
            &reason,
        ),
    );
    try std.testing.expectEqualStrings("missing_error_union_call_fact_provider", reason.?);
}

pub fn lowerTypedV2MaybeError(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    const summary = air_model.typedMaybeErrorSummary(function_type, structured_air_v2) orelse return null;
    if (summary.kind != .maybe_error) return error.UnsupportedAir;
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
        .kind = .{ .icmp = .{
            .predicate = .ne,
            .operand_ty = param_ty,
            .lhs = .{ .named = "arg0" },
            .rhs = .{ .int = 0 },
        } },
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
    const summary = air_model.typedOptionalPayloadSummary(function_type, structured_air_v2) orelse return null;

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
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
            .true_value = .{ .int = summary.fallback },
            .false_value = .{ .named = "arg1" },
        } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "result" } } };
    try function.blocks.append(allocator, block);
    return function;
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

pub fn typedV2OptionalPayloadRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return air_model.typedOptionalPayloadSummary(function_type, structured_air_v2) != null;
}

pub fn lowerTypedV2OptionalPointer(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    const summary = air_model.typedOptionalPointerSummary(function_type, structured_air_v2) orelse return null;

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
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
    const loaded_value_name = if (summary.add_imm == 0) "loaded" else "adjusted";
    if (summary.add_imm != 0) {
        try load.instructions.append(allocator, .{
            .result = loaded_value_name,
            .kind = .{ .binary = .{
                .op = .add,
                .ty = .{ .int = 32 },
                .lhs = .{ .named = "loaded" },
                .rhs = .{ .int = summary.add_imm },
            } },
        });
    }
    load.terminator = .{ .br = .{ .target = "merge" } };
    try function.blocks.append(allocator, load);

    var merge = ir.BasicBlock.init("merge");
    errdefer merge.deinit(allocator);
    var phi: ir.PhiInst = .{ .ty = .{ .int = 32 }, .incoming = .empty };
    errdefer phi.deinit(allocator);
    try phi.incoming.append(allocator, .{ .value = .{ .int = summary.fallback }, .block = "entry" });
    try phi.incoming.append(allocator, .{ .value = .{ .named = loaded_value_name }, .block = "load" });
    try merge.instructions.append(allocator, .{ .result = "result", .kind = .{ .phi = phi } });
    merge.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "result" } } };
    try function.blocks.append(allocator, merge);
    return function;
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
        var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 1 });
        errdefer function.deinit(allocator);
        function.linkage = if (function_type.c_calling_convention) .default else .internal;
        function.calling_conv = irCallingConvention(function_type);
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
    if (typedV2PackedReplaceLowRecords(function_type, structured_air_v2)) {
        var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 8 });
        errdefer function.deinit(allocator);
        function.linkage = if (function_type.c_calling_convention) .default else .internal;
        function.calling_conv = irCallingConvention(function_type);
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

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
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
        .then_target = "exit",
        .else_target = "loop",
    } };
    try function.blocks.append(allocator, entry);

    var loop = ir.BasicBlock.init("loop");
    errdefer loop.deinit(allocator);
    var sum_phi: ir.PhiInst = .{ .ty = .{ .int = 32 }, .incoming = .empty };
    errdefer sum_phi.deinit(allocator);
    try sum_phi.incoming.append(allocator, .{ .value = .{ .int = 0 }, .block = "entry" });
    try sum_phi.incoming.append(allocator, .{ .value = .{ .named = "sum_next" }, .block = "loop" });
    try loop.instructions.append(allocator, .{ .result = "sum", .kind = .{ .phi = sum_phi } });
    sum_phi.incoming = .empty;
    var index_phi: ir.PhiInst = .{ .ty = .{ .int = 64 }, .incoming = .empty };
    errdefer index_phi.deinit(allocator);
    try index_phi.incoming.append(allocator, .{ .value = .{ .int = 0 }, .block = "entry" });
    try index_phi.incoming.append(allocator, .{ .value = .{ .named = "next" }, .block = "loop" });
    try loop.instructions.append(allocator, .{ .result = "index", .kind = .{ .phi = index_phi } });
    index_phi.incoming = .empty;
    var gep: ir.GepInst = .{
        .source_ty = .{ .aggregate = "[4 x i8]" },
        .ptr = .{ .named = "arg0" },
        .indices = .empty,
    };
    errdefer gep.deinit(allocator);
    try gep.indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .named = "index" } });
    try loop.instructions.append(allocator, .{ .result = "ptr", .kind = .{ .gep = gep } });
    gep.indices = .empty;
    try loop.instructions.append(allocator, .{
        .result = "loaded",
        .kind = .{ .load = .{
            .ty = .{ .int = 32 },
            .ptr = .{ .named = "ptr" },
            .attrs = .{ .@"align" = 4 },
        } },
    });
    try loop.instructions.append(allocator, .{
        .result = "sum_next",
        .kind = .{ .binary = .{
            .op = .add,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "loaded" },
            .rhs = .{ .named = "sum" },
        } },
    });
    try loop.instructions.append(allocator, .{
        .result = "next",
        .kind = .{ .binary = .{
            .op = .add,
            .ty = .{ .int = 64 },
            .lhs = .{ .named = "index" },
            .rhs = .{ .int = 1 },
        } },
    });
    try loop.instructions.append(allocator, .{
        .result = "done",
        .kind = .{ .icmp = .{
            .predicate = .eq,
            .operand_ty = .{ .int = 64 },
            .lhs = .{ .named = "next" },
            .rhs = .{ .named = "arg1" },
        } },
    });
    loop.terminator = .{ .condbr = .{
        .cond_ty = .{ .int = 1 },
        .cond = .{ .named = "done" },
        .then_target = "exit",
        .else_target = "loop",
    } };
    try function.blocks.append(allocator, loop);
    loop = ir.BasicBlock.init("loop");

    var exit = ir.BasicBlock.init("exit");
    errdefer exit.deinit(allocator);
    var result_phi: ir.PhiInst = .{ .ty = .{ .int = 32 }, .incoming = .empty };
    errdefer result_phi.deinit(allocator);
    try result_phi.incoming.append(allocator, .{ .value = .{ .int = 0 }, .block = "entry" });
    try result_phi.incoming.append(allocator, .{ .value = .{ .named = "sum_next" }, .block = "loop" });
    try exit.instructions.append(allocator, .{ .result = "result", .kind = .{ .phi = result_phi } });
    result_phi.incoming = .empty;
    exit.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "result" } } };
    try function.blocks.append(allocator, exit);
    return function;
}

pub fn lowerTypedV2ConditionalSliceSum(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2ConditionalSliceSumRecords(function_type, structured_air_v2)) return null;

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
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
    _ = module;

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
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

    return function;
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

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
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

pub fn typedV2ConditionalSlotUpdateRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return air_model.typedConditionalSlotUpdateSummary(function_type, structured_air_v2) != null;
}

pub fn lowerTypedV2LoopTry(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    const summary = air_model.typedLoopTrySummary(function_type, structured_air_v2) orelse return null;
    if (summary.callee_external) return error.UnsupportedAir;
    const call_type = try air_types.parseFunctionType(allocator, summary.call_signature);
    defer call_type.deinit(allocator);
    const dot = std.mem.lastIndexOfScalar(u8, air_function.name, '.') orelse return error.UnsupportedAir;
    const callee_name = try ownPrint(module, "{s}.{s}", .{ air_function.name[0..dot], summary.callee_name });

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg0" });
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg1" });
    if (summary.post_branch != null) {
        try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg2" });
    }

    var entry = ir.BasicBlock.init("entry");
    errdefer entry.deinit(allocator);
    entry.terminator = .{ .br = .{ .target = "loop" } };
    try function.blocks.append(allocator, entry);

    var loop = ir.BasicBlock.init("loop");
    errdefer loop.deinit(allocator);
    var index_phi = ir.PhiInst{ .ty = .{ .int = 32 }, .incoming = .empty };
    try index_phi.incoming.append(allocator, .{ .value = .{ .int = 0 }, .block = "entry" });
    try index_phi.incoming.append(allocator, .{ .value = .{ .named = "index_next" }, .block = "success" });
    try loop.instructions.append(allocator, .{ .result = "index", .kind = .{ .phi = index_phi } });
    var total_phi = ir.PhiInst{ .ty = .{ .int = 32 }, .incoming = .empty };
    try total_phi.incoming.append(allocator, .{ .value = .{ .int = 0 }, .block = "entry" });
    try total_phi.incoming.append(allocator, .{ .value = .{ .named = "total_next" }, .block = "success" });
    try loop.instructions.append(allocator, .{ .result = "total", .kind = .{ .phi = total_phi } });
    try loop.instructions.append(allocator, .{
        .result = "in_bounds",
        .kind = .{ .icmp = .{
            .predicate = .slt,
            .operand_ty = .{ .int = 32 },
            .lhs = .{ .named = "index" },
            .rhs = .{ .named = "arg0" },
        } },
    });
    loop.terminator = .{ .condbr = .{
        .cond_ty = .{ .int = 1 },
        .cond = .{ .named = "in_bounds" },
        .then_target = "body",
        .else_target = "exit",
    } };
    try function.blocks.append(allocator, loop);

    var body = ir.BasicBlock.init("body");
    errdefer body.deinit(allocator);
    try body.instructions.append(allocator, .{
        .result = "matches_fail",
        .kind = .{ .icmp = .{
            .predicate = .eq,
            .operand_ty = .{ .int = 32 },
            .lhs = .{ .named = "index" },
            .rhs = .{ .named = "arg1" },
        } },
    });
    try body.instructions.append(allocator, .{
        .result = "tag",
        .kind = .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = "matches_fail" },
            .ty = .{ .int = 32 },
            .true_value = .{ .int = 1 },
            .false_value = .{ .int = 0 },
        } },
    });
    var call = ir.CallInst{
        .ret_ty = call_type.return_type.ir_type,
        .callee = callee_name,
        .calling_conv = irCallingConvention(call_type),
        .args = .empty,
    };
    errdefer call.deinit(allocator);
    try call.args.append(allocator, .{ .ty = .{ .int = 32 }, .value = .{ .named = "tag" } });
    try call.args.append(allocator, .{ .ty = .{ .int = 32 }, .value = .{ .named = "index" } });
    try body.instructions.append(allocator, .{ .result = "try_result", .kind = .{ .call = call } });
    call.args = .empty;
    try body.instructions.append(allocator, .{
        .result = "error_tag",
        .kind = .{ .binary = .{
            .op = .@"and",
            .ty = .{ .int = 64 },
            .lhs = .{ .named = "try_result" },
            .rhs = .{ .int = 65535 },
        } },
    });
    try body.instructions.append(allocator, .{
        .result = "is_success",
        .kind = .{ .icmp = .{
            .predicate = .eq,
            .operand_ty = .{ .int = 64 },
            .lhs = .{ .named = "error_tag" },
            .rhs = .{ .int = 0 },
        } },
    });
    body.terminator = .{ .condbr = .{
        .cond_ty = .{ .int = 1 },
        .cond = .{ .named = "is_success" },
        .then_target = "success",
        .else_target = "error",
    } };
    try function.blocks.append(allocator, body);

    var success = ir.BasicBlock.init("success");
    errdefer success.deinit(allocator);
    try success.instructions.append(allocator, .{
        .result = "payload64",
        .kind = .{ .binary = .{
            .op = .lshr,
            .ty = .{ .int = 64 },
            .lhs = .{ .named = "try_result" },
            .rhs = .{ .int = 16 },
        } },
    });
    try success.instructions.append(allocator, .{
        .result = "payload",
        .kind = .{ .cast = .{
            .op = .trunc,
            .from_ty = .{ .int = 64 },
            .value = .{ .named = "payload64" },
            .to_ty = .{ .int = 32 },
        } },
    });
    try success.instructions.append(allocator, .{
        .result = "total_next",
        .kind = .{ .binary = .{
            .op = .add,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "total" },
            .rhs = .{ .named = "payload" },
        } },
    });
    try success.instructions.append(allocator, .{
        .result = "index_next",
        .kind = .{ .binary = .{
            .op = .add,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "index" },
            .rhs = .{ .int = 1 },
        } },
    });
    success.terminator = .{ .br = .{ .target = "loop" } };
    try function.blocks.append(allocator, success);

    var err_block = ir.BasicBlock.init("error");
    errdefer err_block.deinit(allocator);
    err_block.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .int = summary.error_return } } };
    try function.blocks.append(allocator, err_block);

    var exit = ir.BasicBlock.init("exit");
    errdefer exit.deinit(allocator);
    if (summary.post_branch) |post_branch| {
        try exit.instructions.append(allocator, .{
            .result = "post_branch_cond",
            .kind = .{ .icmp = .{
                .predicate = .sgt,
                .operand_ty = .{ .int = 32 },
                .lhs = .{ .named = "total" },
                .rhs = .{ .named = "arg2" },
            } },
        });
        exit.terminator = .{ .condbr = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = "post_branch_cond" },
            .then_target = "exit_then",
            .else_target = "exit_else",
        } };
        try function.blocks.append(allocator, exit);

        var exit_then = ir.BasicBlock.init("exit_then");
        errdefer exit_then.deinit(allocator);
        try exit_then.instructions.append(allocator, .{
            .result = "post_branch_true",
            .kind = .{ .binary = .{
                .op = .add,
                .ty = .{ .int = 32 },
                .lhs = .{ .named = "total" },
                .rhs = .{ .int = post_branch.true_addend },
            } },
        });
        exit_then.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "post_branch_true" } } };
        try function.blocks.append(allocator, exit_then);

        var exit_else = ir.BasicBlock.init("exit_else");
        errdefer exit_else.deinit(allocator);
        try exit_else.instructions.append(allocator, .{
            .result = "post_branch_false",
            .kind = .{ .binary = .{
                .op = .add,
                .ty = .{ .int = 32 },
                .lhs = .{ .named = "total" },
                .rhs = .{ .int = post_branch.false_addend },
            } },
        });
        exit_else.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "post_branch_false" } } };
        try function.blocks.append(allocator, exit_else);
        return function;
    }
    if (summary.post_switch) |post_switch| {
        try exit.instructions.append(allocator, .{
            .result = "post_switch_key",
            .kind = .{ .binary = .{
                .op = .@"and",
                .ty = .{ .int = 32 },
                .lhs = .{ .named = "total" },
                .rhs = .{ .int = post_switch.mask },
            } },
        });
        var switch_term: ir.SwitchTerminator = .{
            .cond_ty = .{ .int = 32 },
            .cond = .{ .named = "post_switch_key" },
            .default_target = "exit_default",
            .cases = .empty,
        };
        errdefer switch_term.cases.deinit(allocator);
        try switch_term.cases.append(allocator, .{
            .value_ty = .{ .int = 32 },
            .value = .{ .int = 0 },
            .target = "exit_case0",
        });
        try switch_term.cases.append(allocator, .{
            .value_ty = .{ .int = 32 },
            .value = .{ .int = 1 },
            .target = "exit_case1",
        });
        exit.terminator = .{ .@"switch" = switch_term };
        switch_term.cases = .empty;
        try function.blocks.append(allocator, exit);

        var exit_case0 = ir.BasicBlock.init("exit_case0");
        errdefer exit_case0.deinit(allocator);
        try exit_case0.instructions.append(allocator, .{
            .result = "post_switch_case0",
            .kind = .{ .binary = .{
                .op = .add,
                .ty = .{ .int = 32 },
                .lhs = .{ .named = "total" },
                .rhs = .{ .int = post_switch.case0_addend },
            } },
        });
        exit_case0.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "post_switch_case0" } } };
        try function.blocks.append(allocator, exit_case0);

        var exit_case1 = ir.BasicBlock.init("exit_case1");
        errdefer exit_case1.deinit(allocator);
        try exit_case1.instructions.append(allocator, .{
            .result = "post_switch_case1",
            .kind = .{ .binary = .{
                .op = .add,
                .ty = .{ .int = 32 },
                .lhs = .{ .named = "total" },
                .rhs = .{ .int = post_switch.case1_addend },
            } },
        });
        exit_case1.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "post_switch_case1" } } };
        try function.blocks.append(allocator, exit_case1);

        var exit_default = ir.BasicBlock.init("exit_default");
        errdefer exit_default.deinit(allocator);
        try exit_default.instructions.append(allocator, .{
            .result = "post_switch_default",
            .kind = .{ .binary = .{
                .op = .add,
                .ty = .{ .int = 32 },
                .lhs = .{ .named = "total" },
                .rhs = .{ .int = post_switch.default_addend },
            } },
        });
        exit_default.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "post_switch_default" } } };
        try function.blocks.append(allocator, exit_default);
        return function;
    }
    exit.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "total" } } };
    try function.blocks.append(allocator, exit);
    return function;
}

pub fn typedV2LoopTryRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return air_model.typedLoopTrySummary(function_type, structured_air_v2) != null;
}

pub fn lowerTypedV2DenseIntegerSwitch(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    const results = (air_model.typedDenseIntegerSwitchSummary(function_type, structured_air_v2) orelse return null).results;
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
    return (air_model.typedDenseIntegerSwitchSummary(function_type, structured_air_v2) orelse return null).results;
}

pub fn lowerTypedV2ErrorSwitch(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    const summary = air_model.typedErrorSwitchSummary(function_type, structured_air_v2) orelse return null;
    if (summary.kind != .switch_dispatch) return error.UnsupportedAir;

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
    try function.params.append(allocator, .{ .ty = .{ .int = 8 }, .name = "arg0" });

    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "is_low",
        .kind = .{ .icmp = .{
            .predicate = .eq,
            .operand_ty = .{ .int = 8 },
            .lhs = .{ .named = "arg0" },
            .rhs = .{ .int = 1 },
        } },
    });
    try block.instructions.append(allocator, .{
        .result = "is_zero",
        .kind = .{ .icmp = .{
            .predicate = .eq,
            .operand_ty = .{ .int = 8 },
            .lhs = .{ .named = "arg0" },
            .rhs = .{ .int = 0 },
        } },
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
    const summary = air_model.typedErrorClassifierSummary(function_type, structured_air_v2) orelse return null;
    if (summary.kind != .classify) return error.UnsupportedAir;

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 64 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
    try function.params.append(allocator, .{ .ty = .{ .int = 8 }, .name = "arg0" });

    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "is_low",
        .kind = .{ .icmp = .{
            .predicate = .eq,
            .operand_ty = .{ .int = 8 },
            .lhs = .{ .named = "arg0" },
            .rhs = .{ .int = 1 },
        } },
    });
    try block.instructions.append(allocator, .{
        .result = "is_zero",
        .kind = .{ .icmp = .{
            .predicate = .eq,
            .operand_ty = .{ .int = 8 },
            .lhs = .{ .named = "arg0" },
            .rhs = .{ .int = 0 },
        } },
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
    return try runtime_wrappers.lowerOptionalPointerMainWithType(allocator, air_function, function_type);
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
    return try runtime_wrappers.lowerPointerLoadStoreMainWithType(allocator, air_function, function_type);
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
