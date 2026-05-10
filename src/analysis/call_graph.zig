const std = @import("std");
const ir = @import("../ir.zig");

pub const Node = struct {
    function: []const u8,
    callees: std.ArrayList([]const u8),

    pub fn deinit(node: *Node, allocator: std.mem.Allocator) void {
        node.callees.deinit(allocator);
    }
};

pub const CallGraph = struct {
    allocator: std.mem.Allocator,
    nodes: std.ArrayList(Node),

    pub fn build(allocator: std.mem.Allocator, module: ir.Module) !CallGraph {
        var graph: CallGraph = .{
            .allocator = allocator,
            .nodes = .empty,
        };
        errdefer graph.deinit();

        for (module.functions.items) |function| {
            var node: Node = .{
                .function = function.name,
                .callees = .empty,
            };
            errdefer node.deinit(allocator);
            try collectDirectCallees(allocator, &node, function);
            try graph.nodes.append(allocator, node);
        }

        return graph;
    }

    pub fn deinit(graph: *CallGraph) void {
        for (graph.nodes.items) |*node| node.deinit(graph.allocator);
        graph.nodes.deinit(graph.allocator);
    }

    pub fn calleesOf(graph: CallGraph, function_name: []const u8) ?[]const []const u8 {
        for (graph.nodes.items) |node| {
            if (std.mem.eql(u8, node.function, function_name)) return node.callees.items;
        }
        return null;
    }

    pub fn hasDirectEdge(graph: CallGraph, caller: []const u8, callee: []const u8) bool {
        const callees = graph.calleesOf(caller) orelse return false;
        for (callees) |candidate| {
            if (std.mem.eql(u8, candidate, callee)) return true;
        }
        return false;
    }
};

fn collectDirectCallees(allocator: std.mem.Allocator, node: *Node, function: ir.Function) !void {
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .call => |call| try appendUnique(allocator, &node.callees, call.callee),
                .binary, .cast, .freeze, .icmp, .select, .phi, .alloca, .load, .store, .gep => {},
            }
        }
    }
}

fn appendUnique(allocator: std.mem.Allocator, list: *std.ArrayList([]const u8), value: []const u8) !void {
    for (list.items) |existing| {
        if (std.mem.eql(u8, existing, value)) return;
    }
    try list.append(allocator, value);
}
