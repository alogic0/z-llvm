const std = @import("std");
const air_export = @import("zig_air_export.zig");
const air_model = @import("zig_air_model.zig");
const ir = @import("ir.zig");

const FunctionType = air_model.FunctionType;
const irCallingConvention = air_model.irCallingConvention;
const shortFunctionName = air_model.shortFunctionName;

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
