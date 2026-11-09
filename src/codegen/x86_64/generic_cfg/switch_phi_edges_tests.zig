const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const verify = @import("../verify.zig");
const edges = @import("switch_phi_edges.zig");

fn ownLabel(allocator: std.mem.Allocator, output: *machine.MachineFunction, name: []const u8) !void {
    const label = try allocator.dupe(u8, name);
    errdefer allocator.free(label);
    try output.owned_labels.append(allocator, label);
}

fn instructions(blocks: []const ir.BasicBlock) [6]machine.Instruction {
    return .{
        .{ .label = blocks[0].name },
        .{ .jmp = blocks[1].name },
        .{ .label = blocks[1].name },
        .{ .jmp = blocks[2].name },
        .{ .label = blocks[2].name },
        .ret,
    };
}

test "private CFG label retention preserves numeric identity and owns released arena names" {
    const a = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(a);
    var active = true;
    defer if (active) arena.deinit();
    var blocks: [3]ir.BasicBlock = undefined;
    for ([_][]const u8{ "entry", "0", "\"0\"" }, &blocks) |name, *block|
        block.* = ir.BasicBlock.init(try arena.allocator().dupe(u8, name));
    var output = machine.MachineFunction.init("labels", .void);
    defer output.deinit(a);
    try ownLabel(a, &output, "existing");
    try output.instructions.appendSlice(a, &instructions(&blocks));
    try edges.retainLabels(a, &output, &blocks);
    try std.testing.expectEqual(@as(usize, 4), output.owned_labels.items.len);
    for ([_]usize{ 0, 2, 4 }, blocks) |index, block|
        try std.testing.expect(output.instructions.items[index].label.ptr != block.name.ptr);
    arena.deinit();
    active = false;
    try std.testing.expectEqualStrings("0", output.instructions.items[1].jmp);
    try std.testing.expectEqualStrings("\"0\"", output.instructions.items[3].jmp);
    try verify.verifyFunction(output);
}

fn checkRetentionAllocation(allocator: std.mem.Allocator, blocks: []const ir.BasicBlock) !void {
    var output = machine.MachineFunction.init("labels", .void);
    defer output.deinit(allocator);
    try ownLabel(allocator, &output, "existing");
    const original = instructions(blocks);
    try output.instructions.appendSlice(allocator, &original);
    edges.retainLabels(allocator, &output, blocks) catch |err| {
        try std.testing.expectEqual(@as(usize, 1), output.owned_labels.items.len);
        try std.testing.expectEqualStrings("existing", output.owned_labels.items[0]);
        for (original, output.instructions.items) |before, after| try std.testing.expect(std.meta.eql(before, after));
        return err;
    };
    try std.testing.expectEqual(@as(usize, 4), output.owned_labels.items.len);
    try verify.verifyFunction(output);
}

test "private CFG label retention rolls back every allocation failure" {
    const blocks = [_]ir.BasicBlock{ ir.BasicBlock.init("entry"), ir.BasicBlock.init("0"), ir.BasicBlock.init("\"0\"") };
    var moving = std.testing.FailingAllocator.init(std.testing.allocator, .{ .resize_fail_index = 0 });
    try std.testing.checkAllAllocationFailures(moving.allocator(), checkRetentionAllocation, .{@as([]const ir.BasicBlock, &blocks)});
}

test "private CFG label retention rejects canonical duplicates before instruction mutation" {
    const a = std.testing.allocator;
    const blocks = [_]ir.BasicBlock{ ir.BasicBlock.init("entry"), ir.BasicBlock.init("a"), ir.BasicBlock.init("\"\\61\"") };
    var output = machine.MachineFunction.init("labels", .void);
    defer output.deinit(a);
    try ownLabel(a, &output, "existing");
    const original = instructions(&blocks);
    try output.instructions.appendSlice(a, &original);
    try std.testing.expectError(error.DuplicateBlock, edges.retainLabels(a, &output, &blocks));
    try std.testing.expectEqual(@as(usize, 1), output.owned_labels.items.len);
    for (original, output.instructions.items) |before, after| try std.testing.expect(std.meta.eql(before, after));
}
