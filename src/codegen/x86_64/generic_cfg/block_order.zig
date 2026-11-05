//! Use reverse postorder for the private selector view. This places reachable
//! dominating definitions before their consumers without changing CFG edges.
const std = @import("std");
const ir = @import("../../../ir.zig");
const cfg = @import("../../../analysis/cfg.zig");
const planning = @import("stage2_planning.zig");

pub fn legalize(allocator: std.mem.Allocator, function: ir.Function) !?ir.Function {
    const count = function.blocks.items.len;
    if (count < 2 or count > planning.stage2_max_blocks) return null;
    var graph = try cfg.Graph.build(allocator, function);
    defer graph.deinit();
    const visited = try allocator.alloc(bool, count);
    defer allocator.free(visited);
    @memset(visited, false);
    const Frame = struct { index: usize, next: usize = 0 };
    var stack: std.ArrayList(Frame) = .empty;
    defer stack.deinit(allocator);
    var postorder: std.ArrayList(usize) = .empty;
    defer postorder.deinit(allocator);
    try stack.append(allocator, .{ .index = 0 });
    visited[0] = true;
    while (stack.items.len != 0) {
        const top = &stack.items[stack.items.len - 1];
        const successors = graph.successors(top.index);
        if (top.next < successors.len) {
            const child = successors[top.next];
            top.next += 1;
            if (!visited[child]) {
                visited[child] = true;
                try stack.append(allocator, .{ .index = child });
            }
        } else {
            const completed = stack.pop().?;
            try postorder.append(allocator, completed.index);
        }
    }
    var result = function;
    result.blocks = .empty;
    var remaining = postorder.items.len;
    while (remaining != 0) {
        remaining -= 1;
        try result.blocks.append(allocator, function.blocks.items[postorder.items[remaining]]);
    }
    // Keep every unreachable block and its relative order. This is scheduling,
    // not reachability pruning, and it is stable on repeated legalization.
    for (function.blocks.items, visited) |block, reached| if (!reached) try result.blocks.append(allocator, block);
    for (function.blocks.items, result.blocks.items) |before, after|
        if (!ir.identifiers.eql(before.name, after.name)) return result;
    return null;
}
