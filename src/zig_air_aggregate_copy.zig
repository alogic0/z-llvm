const std = @import("std");
const air_capabilities = @import("zig_air_capabilities.zig");
const air_model = @import("zig_air_model.zig");
const ir = @import("ir.zig");
const target_mod = @import("target.zig");

const ZigType = air_model.ZigType;

pub fn supportedScalarAggregateLeafParamCount(ty: ir.Type, params: []const ZigType) ?usize {
    var param_index: usize = 0;
    const leaf_count = supportedScalarAggregateLeafParamCountInner(ty, params, &param_index) orelse return null;
    if (param_index != params.len) return null;
    return leaf_count;
}

fn supportedScalarAggregateLeafParamCountInner(ty: ir.Type, params: []const ZigType, param_index: *usize) ?usize {
    const field_count = air_capabilities.aggregateFieldCount(ty);
    if (field_count == 0) return null;
    var leaf_count: usize = 0;
    var field_index: usize = 0;
    while (field_index < field_count) : (field_index += 1) {
        const field_ty = air_capabilities.aggregateFieldType(ty, field_index) orelse return null;
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
    const field_count = air_capabilities.aggregateFieldCount(ty);
    if (field_count == 0) return null;
    var count: usize = 0;
    var field_index: usize = 0;
    while (field_index < field_count) : (field_index += 1) {
        const field_ty = air_capabilities.aggregateFieldType(ty, field_index) orelse return null;
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

fn collectAggregateCopyLeavesInto(
    allocator: std.mem.Allocator,
    leaves: *std.ArrayList(AggregateCopyLeaf),
    layout: target_mod.DataLayout,
    aggregate_ty: ir.Type,
    base_offset: u64,
) !void {
    const field_count = air_capabilities.aggregateFieldCount(aggregate_ty);
    if (field_count == 0) return error.UnsupportedAir;
    var field_index: usize = 0;
    while (field_index < field_count) : (field_index += 1) {
        const field_ty = air_capabilities.aggregateFieldType(aggregate_ty, field_index) orelse return error.UnsupportedAir;
        const offset = air_capabilities.aggregateFieldByteOffset(layout, aggregate_ty, field_index) orelse return error.UnsupportedAir;
        const field_offset = base_offset + offset;
        if (supportedAggregateCopyLeaf(field_ty)) {
            try leaves.append(allocator, .{ .offset = field_offset, .ty = field_ty });
        } else if (isAggregateIrType(field_ty)) {
            try collectAggregateCopyLeavesInto(allocator, leaves, layout, field_ty, field_offset);
        } else {
            return error.UnsupportedAir;
        }
    }
}

test "collect aggregate copy leaves from nested aggregate" {
    const aggregate_ty: ir.Type = .{ .aggregate = "{ i32, { i64, double }, ptr }" };
    const leaves = try collectAggregateCopyLeaves(std.testing.allocator, aggregate_ty);
    defer std.testing.allocator.free(leaves);

    try std.testing.expectEqual(@as(usize, 4), leaves.len);
    try std.testing.expect(leaves[0].ty.eql(.{ .int = 32 }));
    try std.testing.expect(leaves[1].ty.eql(.{ .int = 64 }));
    try std.testing.expect(leaves[2].ty.eql(.double));
    try std.testing.expect(leaves[3].ty.eql(.ptr));
}
