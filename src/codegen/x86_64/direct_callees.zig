//! Definitions required by actual emitted direct calls, including private
//! runtime helpers that the legacy IR-writer root policy otherwise omits.
const std = @import("std");
const ir = @import("../../ir.zig");
const machine = @import("machine.zig");
const symbolName = @import("match.zig").symbolName;

pub const Queue = struct {
    allocator: std.mem.Allocator,
    definitions: std.StringHashMap(usize),
    queued: []bool,
    items: std.ArrayList(usize) = .empty,

    pub fn init(allocator: std.mem.Allocator, functions: []const ir.Function) !Queue {
        var definitions = std.StringHashMap(usize).init(allocator);
        errdefer definitions.deinit();
        for (functions, 0..) |function, index| try definitions.put(symbolName(function.name), index);
        const queued = try allocator.alloc(bool, functions.len);
        @memset(queued, false);
        return .{ .allocator = allocator, .definitions = definitions, .queued = queued };
    }

    pub fn deinit(queue: *Queue) void {
        queue.definitions.deinit();
        queue.allocator.free(queue.queued);
        queue.items.deinit(queue.allocator);
    }

    pub fn include(queue: *Queue, index: usize) !void {
        if (queue.queued[index]) return;
        try queue.items.append(queue.allocator, index);
        queue.queued[index] = true;
    }

    pub fn includeCallees(queue: *Queue, instructions: []const machine.Instruction) !void {
        for (instructions) |instruction| {
            const name = switch (instruction) {
                .direct_call => |call| call.symbol,
                .noreturn_direct_call, .direct_jump => |name| name,
                else => continue,
            };
            if (queue.definitions.get(symbolName(name))) |index| try queue.include(index);
        }
    }
};

test "IR writer direct callee closure is transitive unique and definition owned" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\declare void @external()
        \\define void @root() {
        \\entry:
        \\ ret void
        \\}
        \\define private void @"debug.local"() {
        \\entry:
        \\ ret void
        \\}
        \\define private void @leaf() {
        \\entry:
        \\ ret void
        \\}
    );
    defer module.deinit();
    var queue = try Queue.init(std.testing.allocator, module.functions.items);
    defer queue.deinit();
    try queue.include(0);
    try queue.includeCallees(&.{
        .{ .direct_call = .{ .symbol = "debug.local", .ret_ty = .void } },
        .{ .noreturn_direct_call = "debug.local" },
        .{ .direct_call = .{ .symbol = "external", .ret_ty = .void } },
    });
    try std.testing.expectEqualSlices(usize, &.{ 0, 1 }, queue.items.items);
    try queue.includeCallees(&.{ .{ .direct_jump = "leaf" }, .{ .direct_jump = "root" } });
    try std.testing.expectEqualSlices(usize, &.{ 0, 1, 2 }, queue.items.items);
}
