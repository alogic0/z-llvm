const std = @import("std");
const air_aggregate_construction = @import("zig_air_aggregate_construction.zig");
const air_aggregate_copy = @import("zig_air_aggregate_copy.zig");
const air_export = @import("zig_air_export.zig");
const air_model = @import("zig_air_model.zig");
const ir = @import("ir.zig");
const type_layout = @import("zig_air_type_layout.zig");

const FunctionType = air_model.FunctionType;
const collectAggregateCopyLeaves = air_aggregate_copy.collectAggregateCopyLeaves;
const validateSretAggregateMakeRecords = air_aggregate_copy.validateSretAggregateMakeRecords;
const validateSretAggregateCopyRecords = air_aggregate_copy.validateSretAggregateCopyRecords;
const validateSretAggregateCallWrapperRecords = air_aggregate_copy.validateSretAggregateCallWrapperRecords;
const isSysVRegisterAggregateCandidate = air_aggregate_construction.isSysVRegisterAggregateCandidate;
const typedDetail = air_model.detail;
const typedCallee = air_model.callee;
const typedSingleInstructionByOpcode = air_model.singleInstructionByOpcode;
const shortFunctionName = air_model.shortFunctionName;
const ownPrint = air_model.ownPrint;
const irCallingConvention = air_model.irCallingConvention;

fn lowerRegisterAggregateMake(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !ir.Function {
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
pub fn lowerTypedV2SmallIntegerAggregateAbi(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2RegisterAggregateRecords(function_type, structured_air_v2)) return null;
    return try lowerRegisterAggregateMake(allocator, air_function, function_type, structured_air_v2);
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
