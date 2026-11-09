const std = @import("std");
const ir = @import("../ir.zig");
pub const BlockIndexes = std.HashMapUnmanaged([]const u8, usize, ir.identifiers.Context, std.hash_map.default_max_load_percentage);

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
    block_indexes: BlockIndexes = .empty,

    pub fn build(allocator: std.mem.Allocator, function: ir.Function) !Graph {
        var graph: Graph = .{
            .allocator = allocator,
            .edges = .empty,
        };
        errdefer graph.deinit();

        for (function.blocks.items, 0..) |block, index| {
            const entry = try graph.block_indexes.getOrPut(allocator, block.name);
            if (entry.found_existing) return error.DuplicateBlock;
            entry.value_ptr.* = index;
        }
        try graph.edges.appendNTimes(allocator, .{}, function.blocks.items.len);

        for (function.blocks.items, 0..) |block, block_index| {
            const terminator = block.terminator orelse continue;
            switch (terminator) {
                .ret => {},
                .@"unreachable" => {},
                .br => |br| try graph.addEdge(block_index, br.target),
                .condbr => |condbr| {
                    try graph.addEdge(block_index, condbr.then_target);
                    try graph.addEdge(block_index, condbr.else_target);
                },
                .@"switch" => |switch_term| {
                    try graph.addEdge(block_index, switch_term.default_target);
                    for (switch_term.cases.items) |case| try graph.addEdge(block_index, case.target);
                },
                .indirectbr => |indirectbr| {
                    for (indirectbr.targets.items) |target| try graph.addEdge(block_index, target);
                },
            }
        }

        return graph;
    }

    pub fn deinit(graph: *Graph) void {
        for (graph.edges.items) |*edges| edges.deinit(graph.allocator);
        graph.edges.deinit(graph.allocator);
        graph.block_indexes.deinit(graph.allocator);
    }

    pub fn blockIndex(graph: Graph, name: []const u8) ?usize {
        return graph.block_indexes.get(name);
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

    fn addEdge(graph: *Graph, from: usize, target_name: []const u8) !void {
        const to = graph.blockIndex(target_name) orelse return error.UnknownBlock;
        const edges = &graph.edges.items[from];
        for (edges.successors.items, 0..) |successor, i| {
            if (successor == to) {
                edges.successor_counts.items[i] += 1;
                return;
            }
        }
        try edges.successors.append(graph.allocator, to);
        try edges.successor_counts.append(graph.allocator, 1);
        // The outgoing list admits this (from,to) pair once. Its inverse
        // predecessor entry is therefore unique without scanning a large join.
        try graph.edges.items[to].predecessors.append(graph.allocator, from);
    }
};
