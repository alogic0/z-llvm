const std = @import("std");
const ir = @import("../ir.zig");

pub const BlockEdges = struct {
    successors: std.ArrayList(usize) = .empty,
    successor_counts: std.ArrayList(usize) = .empty,
    predecessors: std.ArrayList(usize) = .empty,

    pub fn deinit(edges: *BlockEdges, allocator: std.mem.Allocator) void {
        edges.successors.deinit(allocator);
        edges.successor_counts.deinit(allocator);
        edges.predecessors.deinit(allocator);
    }
};

pub const Graph = struct {
    allocator: std.mem.Allocator,
    edges: std.ArrayList(BlockEdges),

    pub fn build(allocator: std.mem.Allocator, function: ir.Function) !Graph {
        var graph: Graph = .{
            .allocator = allocator,
            .edges = .empty,
        };
        errdefer graph.deinit();

        try graph.edges.appendNTimes(allocator, .{}, function.blocks.items.len);

        for (function.blocks.items, 0..) |block, block_index| {
            const terminator = block.terminator orelse continue;
            switch (terminator) {
                .ret => {},
                .@"unreachable" => {},
                .br => |br| try graph.addEdge(function, block_index, br.target),
                .condbr => |condbr| {
                    try graph.addEdge(function, block_index, condbr.then_target);
                    try graph.addEdge(function, block_index, condbr.else_target);
                },
                .@"switch" => |switch_term| {
                    try graph.addEdge(function, block_index, switch_term.default_target);
                    for (switch_term.cases.items) |case| try graph.addEdge(function, block_index, case.target);
                },
                .indirectbr => |indirectbr| {
                    for (indirectbr.targets.items) |target| try graph.addEdge(function, block_index, target);
                },
            }
        }

        return graph;
    }

    pub fn deinit(graph: *Graph) void {
        for (graph.edges.items) |*edges| edges.deinit(graph.allocator);
        graph.edges.deinit(graph.allocator);
    }

    pub fn successors(graph: Graph, block_index: usize) []const usize {
        return graph.edges.items[block_index].successors.items;
    }

    pub fn predecessors(graph: Graph, block_index: usize) []const usize {
        return graph.edges.items[block_index].predecessors.items;
    }

    /// Analyses traverse unique successors; PHIs require one incoming value per
    /// terminator edge, including repeated switch/conditional destinations.
    pub fn edgeCount(graph: Graph, from: usize, to: usize) usize {
        const edges = graph.edges.items[from];
        for (edges.successors.items, edges.successor_counts.items) |successor, count| {
            if (successor == to) return count;
        }
        return 0;
    }

    pub fn reachableFromEntry(graph: Graph, allocator: std.mem.Allocator) ![]bool {
        const reachable = try allocator.alloc(bool, graph.edges.items.len);
        errdefer allocator.free(reachable);
        @memset(reachable, false);
        if (reachable.len == 0) return reachable;

        var worklist: std.ArrayList(usize) = .empty;
        defer worklist.deinit(allocator);

        reachable[0] = true;
        try worklist.append(allocator, 0);

        while (worklist.pop()) |block_index| {
            for (graph.successors(block_index)) |successor| {
                if (reachable[successor]) continue;
                reachable[successor] = true;
                try worklist.append(allocator, successor);
            }
        }

        return reachable;
    }

    fn addEdge(graph: *Graph, function: ir.Function, from: usize, target_name: []const u8) !void {
        const to = function.blockIndex(target_name) orelse return error.UnknownBlock;
        const edges = &graph.edges.items[from];
        for (edges.successors.items, 0..) |successor, i| {
            if (successor == to) {
                edges.successor_counts.items[i] += 1;
                return;
            }
        }
        try edges.successors.append(graph.allocator, to);
        try edges.successor_counts.append(graph.allocator, 1);
        try appendUnique(graph.allocator, &graph.edges.items[to].predecessors, from);
    }
};

fn appendUnique(allocator: std.mem.Allocator, list: *std.ArrayList(usize), value: usize) !void {
    for (list.items) |existing| {
        if (existing == value) return;
    }
    try list.append(allocator, value);
}
