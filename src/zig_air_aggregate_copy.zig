const std = @import("std");
const air_model = @import("zig_air_model.zig");
const type_layout = @import("zig_air_type_layout.zig");
const ir = @import("ir.zig");
const target_mod = @import("target.zig");

const ZigType = air_model.ZigType;

pub fn supportedScalarAggregateLeafParamCount(ty: ir.Type, params: []const ZigType) ?usize {
    const plan = aggregateCopyLayoutPlan(ty) orelse return null;
    const leaves = plan.leafSlice();
    if (leaves.len != params.len) return null;
    for (leaves, params) |leaf, param| {
        if (!param.ir_type.eql(leaf.ty)) return null;
    }
    return leaves.len;
}

pub fn supportedAggregateCopyLeafCount(ty: ir.Type) ?usize {
    const plan = aggregateCopyLayoutPlan(ty) orelse return null;
    return plan.leaf_count;
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

pub const AggregateCopyLeaf = type_layout.AggregateLeaf;

pub fn collectAggregateCopyLeaves(allocator: std.mem.Allocator, aggregate_ty: ir.Type) ![]AggregateCopyLeaf {
    const plan = aggregateCopyLayoutPlan(aggregate_ty) orelse return error.UnsupportedAir;
    if (plan.leaf_count < 3) return error.UnsupportedAir;
    const leaves = try allocator.alloc(AggregateCopyLeaf, plan.leaf_count);
    @memcpy(leaves, plan.leafSlice());
    return leaves;
}

fn aggregateCopyLayoutPlan(aggregate_ty: ir.Type) ?type_layout.AggregateLayoutPlan {
    const layout = target_mod.DataLayout.parse("e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128") catch return null;
    return type_layout.aggregateLayoutPlan(layout, aggregate_ty) catch null;
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

test "aggregate copy leaf counts use shared layout plan" {
    const aggregate_ty: ir.Type = .{ .aggregate = "%frontier_sysv_sret_byval.Big12" };
    try std.testing.expectEqual(@as(usize, 12), supportedAggregateCopyLeafCount(aggregate_ty).?);
    const leaves = try collectAggregateCopyLeaves(std.testing.allocator, aggregate_ty);
    defer std.testing.allocator.free(leaves);
    try std.testing.expectEqual(@as(usize, 12), leaves.len);
    try std.testing.expectEqual(@as(u64, 88), leaves[11].offset);
    try std.testing.expect(leaves[11].ty.eql(.{ .int = 64 }));
}
