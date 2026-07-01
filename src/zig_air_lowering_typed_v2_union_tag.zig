const std = @import("std");
const air_export = @import("zig_air_export.zig");
const air_model = @import("zig_air_model.zig");
const ir = @import("ir.zig");

const FunctionType = air_model.FunctionType;
const irCallingConvention = air_model.irCallingConvention;
const shortFunctionName = air_model.shortFunctionName;

pub fn lowerTypedV2UnionTagPayloadSwitch(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air: air_export.StructuredAir,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    const summary = air_model.typedUnionTagPayloadSwitchSummary(function_type, structured_air, structured_air_v2) orelse return null;
    return lowerTypedV2UnionTagPayloadSummary(allocator, air_function, function_type, summary);
}

pub fn lowerTypedV2UnionTagPayloadBranch(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air: air_export.StructuredAir,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    const summary = air_model.typedUnionTagPayloadBranchSummary(function_type, structured_air, structured_air_v2) orelse return null;
    return lowerTypedV2UnionTagPayloadSummary(allocator, air_function, function_type, summary);
}

fn lowerTypedV2UnionTagPayloadSummary(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    summary: air_model.TypedUnionTagPayloadSwitchSummary,
) !?ir.Function {
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
        .result = "tag0_payload",
        .kind = .{ .binary = .{
            .op = .add,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "arg1" },
            .rhs = .{ .int = summary.tag0_store_add },
        } },
    });
    try block.instructions.append(allocator, .{
        .result = "tag0_result",
        .kind = .{ .binary = .{
            .op = .add,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "tag0_payload" },
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
            .true_value = .{ .named = unionTagResultName(summary.true_tag_index) orelse return null },
            .false_value = .{ .named = unionTagResultName(summary.false_tag_index) orelse return null },
        } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "result" } } };
    try function.blocks.append(allocator, block);
    return function;
}

pub fn typedV2UnionTagPayloadSwitchRecords(
    function_type: FunctionType,
    structured_air: air_export.StructuredAir,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return air_model.typedUnionTagPayloadSwitchSummary(function_type, structured_air, structured_air_v2) != null;
}

pub fn typedV2UnionTagPayloadBranchRecords(
    function_type: FunctionType,
    structured_air: air_export.StructuredAir,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return air_model.typedUnionTagPayloadBranchSummary(function_type, structured_air, structured_air_v2) != null;
}

fn unionTagResultName(tag_index: u32) ?[]const u8 {
    return switch (tag_index) {
        0 => "tag0_result",
        1 => "tag1_result",
        else => null,
    };
}
