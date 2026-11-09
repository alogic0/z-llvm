const std = @import("std");
const ir = @import("../ir.zig");
const cfg = @import("../analysis/cfg.zig");

const source =
    \\define void @indexed(i1 %condition) {
    \\entry:
    \\ br i1 %condition, label %"\61", label %a
    \\a:
    \\ switch i32 0, label %"0" [
    \\  i32 1, label %0
    \\  i32 2, label %"0"
    \\ ]
    \\0:
    \\ ret void
    \\"0":
    \\ ret void
    \\}
;

test "CFG graph indexing preserves canonical blocks numeric namespace and edge multiplicity" {
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    try module.verify();
    var graph = try cfg.Graph.build(std.testing.allocator, module.functions.items[0]);
    defer graph.deinit();
    try std.testing.expectEqual(@as(?usize, 1), graph.blockIndex("a"));
    try std.testing.expectEqual(@as(?usize, 1), graph.blockIndex("\"a\""));
    try std.testing.expectEqual(@as(?usize, 1), graph.blockIndex("\"\\61\""));
    try std.testing.expectEqual(@as(?usize, 2), graph.blockIndex("0"));
    try std.testing.expectEqual(@as(?usize, 3), graph.blockIndex("\"0\""));
    try std.testing.expectEqual(@as(usize, 2), graph.edgeCount(0, 1));
    try std.testing.expectEqualSlices(usize, &.{0}, graph.predecessors(1));
    try std.testing.expectEqual(@as(usize, 1), graph.edgeCount(1, 2));
    try std.testing.expectEqual(@as(usize, 2), graph.edgeCount(1, 3));
    try std.testing.expectEqualSlices(usize, &.{1}, graph.predecessors(2));
    try std.testing.expectEqualSlices(usize, &.{1}, graph.predecessors(3));
    const reached = try graph.reachableFromEntry(std.testing.allocator);
    defer std.testing.allocator.free(reached);
    for (reached) |value| try std.testing.expect(value);
}

test "CFG graph indexing rejects duplicate identities and unknown destinations" {
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    const saved = module.functions.items[0].blocks.items[2].name;
    module.functions.items[0].blocks.items[2].name = "\"a\"";
    try std.testing.expectError(error.DuplicateBlock, cfg.Graph.build(std.testing.allocator, module.functions.items[0]));
    module.functions.items[0].blocks.items[2].name = saved;
    module.functions.items[0].blocks.items[0].terminator.?.condbr.then_target = "absent";
    try std.testing.expectError(error.UnknownBlock, cfg.Graph.build(std.testing.allocator, module.functions.items[0]));
}

fn buildWithAllocator(allocator: std.mem.Allocator, function: ir.Function) !void {
    var graph = try cfg.Graph.build(allocator, function);
    defer graph.deinit();
    try std.testing.expectEqual(@as(usize, 2), graph.edgeCount(0, 1));
    try std.testing.expectEqualSlices(usize, &.{0}, graph.predecessors(1));
}

test "CFG graph indexing releases partially built maps and edge arrays on allocation failure" {
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    try std.testing.checkAllAllocationFailures(std.testing.allocator, buildWithAllocator, .{module.functions.items[0]});
    try module.verify();
}
