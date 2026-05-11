const std = @import("std");
const ir = @import("../ir.zig");

pub const Node = struct {
    pub const Kind = enum {
        definition,
        declaration,
    };

    function: []const u8,
    kind: Kind,
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
                .kind = .definition,
                .callees = .empty,
            };
            errdefer node.deinit(allocator);
            try collectDirectCallees(allocator, &node, function);
            try graph.nodes.append(allocator, node);
        }

        for (module.declarations.items) |decl| {
            try graph.nodes.append(allocator, .{
                .function = decl.name,
                .kind = .declaration,
                .callees = .empty,
            });
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

    pub fn kindOf(graph: CallGraph, function_name: []const u8) ?Node.Kind {
        for (graph.nodes.items) |node| {
            if (std.mem.eql(u8, node.function, function_name)) return node.kind;
        }
        return null;
    }

    pub fn hasDefinition(graph: CallGraph, function_name: []const u8) bool {
        const kind = graph.kindOf(function_name) orelse return false;
        return kind == .definition;
    }

    pub fn hasDeclaration(graph: CallGraph, function_name: []const u8) bool {
        const kind = graph.kindOf(function_name) orelse return false;
        return kind == .declaration;
    }

    pub fn isKnownCallee(graph: CallGraph, function_name: []const u8) bool {
        return graph.kindOf(function_name) != null;
    }

    pub fn reachableDefinitionsFromRoots(
        graph: CallGraph,
        allocator: std.mem.Allocator,
        roots: []const []const u8,
    ) !std.ArrayList([]const u8) {
        var reachable: std.ArrayList([]const u8) = .empty;
        errdefer reachable.deinit(allocator);
        var worklist: std.ArrayList([]const u8) = .empty;
        defer worklist.deinit(allocator);

        for (roots) |root| {
            if (!graph.hasDefinition(root)) continue;
            try appendUnique(allocator, &reachable, root);
            try appendUnique(allocator, &worklist, root);
        }

        while (worklist.pop()) |caller| {
            const callees = graph.calleesOf(caller) orelse continue;
            for (callees) |callee| {
                if (!graph.hasDefinition(callee)) continue;
                const before = reachable.items.len;
                try appendUnique(allocator, &reachable, callee);
                if (reachable.items.len != before) try appendUnique(allocator, &worklist, callee);
            }
        }
        return reachable;
    }
};

fn collectDirectCallees(allocator: std.mem.Allocator, node: *Node, function: ir.Function) !void {
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .call => |call| if (call.inline_asm == null and call.callee_value == null) try appendUnique(allocator, &node.callees, call.callee),
                .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .gep => {},
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
