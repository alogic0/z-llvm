//! Shared read-only global-value dependency graph. Public definitions are
//! roots; parsed references connect functions, globals and aliases. External
//! declarations have no body node. Unknown references conservatively retain
//! every definition, matching GlobalDCE's refusal to delete unproved nodes.
const std = @import("std");
const references = @import("module_references.zig");
const ir = @import("../ir.zig");

pub const NodeKind = enum { function, global, alias };

pub const NodeRef = struct {
    kind: NodeKind,
    name: []const u8,
};

const Node = struct {
    ref: NodeRef,
    edges: std.ArrayList(NodeRef),
    has_unknown: bool = false,

    fn deinit(node: *Node, allocator: std.mem.Allocator) void {
        node.edges.deinit(allocator);
    }
};

pub const Graph = struct {
    allocator: std.mem.Allocator,
    nodes: std.ArrayList(Node),
    roots: std.ArrayList(NodeRef),
    has_unknown_roots: bool = false,

    pub fn build(allocator: std.mem.Allocator, module: ir.Module) !Graph {
        var graph: Graph = .{
            .allocator = allocator,
            .nodes = .empty,
            .roots = .empty,
        };
        errdefer graph.deinit();
        var reference_context = try references.Context.init(allocator, &module);
        defer reference_context.deinit();

        for (module.functions.items) |*function| {
            if (!ir.identifiers.isValid(function.name)) graph.has_unknown_roots = true;
            const ref: NodeRef = .{ .kind = .function, .name = function.name };
            var node: Node = .{ .ref = ref, .edges = .empty };
            errdefer node.deinit(allocator);
            if (!isLocal(function.linkage)) try graph.roots.append(allocator, ref);
            try reference_context.walkFunction(function, EdgeVisitor{ .allocator = allocator, .module = &module, .edges = &node.edges, .has_unknown = &node.has_unknown });
            try graph.nodes.append(allocator, node);
        }
        for (module.globals.items) |*global| {
            if (!ir.identifiers.isValid(global.name)) graph.has_unknown_roots = true;
            const ref: NodeRef = .{ .kind = .global, .name = global.name };
            var node: Node = .{ .ref = ref, .edges = .empty };
            errdefer node.deinit(allocator);
            if (!isLocal(global.linkage)) try graph.roots.append(allocator, ref);
            try reference_context.walkGlobal(global, EdgeVisitor{ .allocator = allocator, .module = &module, .edges = &node.edges, .has_unknown = &node.has_unknown });
            try graph.nodes.append(allocator, node);
        }
        for (module.aliases.items) |*alias| {
            if (!ir.identifiers.isValid(alias.name)) graph.has_unknown_roots = true;
            const ref: NodeRef = .{ .kind = .alias, .name = alias.name };
            var node: Node = .{ .ref = ref, .edges = .empty };
            errdefer node.deinit(allocator);
            if (!isLocal(alias.linkage)) try graph.roots.append(allocator, ref);
            try references.walkAlias(alias, EdgeVisitor{ .allocator = allocator, .module = &module, .edges = &node.edges, .has_unknown = &node.has_unknown });
            try graph.nodes.append(allocator, node);
        }
        try reference_context.walkModuleScope(EdgeVisitor{ .allocator = allocator, .module = &module, .edges = &graph.roots, .has_unknown = &graph.has_unknown_roots });

        return graph;
    }

    pub fn deinit(graph: *Graph) void {
        for (graph.nodes.items) |*node| node.deinit(graph.allocator);
        graph.nodes.deinit(graph.allocator);
        graph.roots.deinit(graph.allocator);
    }

    /// Unknown live references can name any definition. The result records
    /// that conservative boundary instead of inferring absence from raw text.
    pub fn reachable(graph: Graph) !Reachability {
        var result: Reachability = .{ .allocator = graph.allocator, .has_unknown = graph.has_unknown_roots };
        errdefer result.deinit();
        if (result.has_unknown) return result;
        var worklist: std.ArrayList(NodeRef) = .empty;
        defer worklist.deinit(graph.allocator);
        for (graph.roots.items) |root| try markLive(graph.allocator, &result.live, &worklist, root);
        while (worklist.pop()) |ref| {
            const node = graph.nodeOf(ref) orelse continue;
            if (node.has_unknown) {
                result.has_unknown = true;
                return result;
            }
            for (node.edges.items) |edge| try markLive(graph.allocator, &result.live, &worklist, edge);
        }
        return result;
    }

    fn nodeOf(graph: Graph, ref: NodeRef) ?*const Node {
        for (graph.nodes.items) |*node| {
            if (sameRef(node.ref, ref)) return node;
        }
        return null;
    }
};

const EdgeVisitor = struct {
    pub const Error = std.mem.Allocator.Error;
    allocator: std.mem.Allocator,
    module: *const ir.Module,
    edges: *std.ArrayList(NodeRef),
    has_unknown: *bool,

    pub fn visit(visitor: EdgeVisitor, _: references.Site, event: references.Event) Error!void {
        switch (event) {
            .unknown => visitor.has_unknown.* = true,
            .symbol => |name| if (definition(visitor.module, name)) |ref| {
                try appendUniqueEdge(visitor.allocator, visitor.edges, ref);
            },
            .block_address => |address| if (definition(visitor.module, address.function)) |ref| {
                try appendUniqueEdge(visitor.allocator, visitor.edges, ref);
            },
        }
    }
};

fn definition(module: *const ir.Module, name: []const u8) ?NodeRef {
    for (module.functions.items) |function| {
        if (ir.identifiers.eql(function.name, name)) return .{ .kind = .function, .name = function.name };
    }
    for (module.globals.items) |global| {
        if (ir.identifiers.eql(global.name, name)) return .{ .kind = .global, .name = global.name };
    }
    for (module.aliases.items) |alias| {
        if (ir.identifiers.eql(alias.name, name)) return .{ .kind = .alias, .name = alias.name };
    }
    return null;
}

pub const Reachability = struct {
    allocator: std.mem.Allocator,
    live: std.ArrayList(NodeRef) = .empty,
    has_unknown: bool = false,

    pub fn deinit(result: *Reachability) void {
        result.live.deinit(result.allocator);
    }

    pub fn contains(result: Reachability, kind: NodeKind, name: []const u8) bool {
        return result.has_unknown or containsRef(result.live.items, .{ .kind = kind, .name = name });
    }
};

fn markLive(
    allocator: std.mem.Allocator,
    live: *std.ArrayList(NodeRef),
    worklist: *std.ArrayList(NodeRef),
    ref: NodeRef,
) !void {
    if (containsRef(live.items, ref)) return;
    try live.append(allocator, ref);
    try worklist.append(allocator, ref);
}

fn appendUniqueEdge(allocator: std.mem.Allocator, edges: *std.ArrayList(NodeRef), ref: NodeRef) !void {
    if (containsRef(edges.items, ref)) return;
    try edges.append(allocator, ref);
}

pub fn containsRef(refs: []const NodeRef, ref: NodeRef) bool {
    for (refs) |candidate| {
        if (sameRef(candidate, ref)) return true;
    }
    return false;
}

fn sameRef(a: NodeRef, b: NodeRef) bool {
    return a.kind == b.kind and ir.identifiers.eql(a.name, b.name);
}

pub fn isLocal(linkage: ir.FunctionLinkage) bool {
    return linkage == .internal or linkage == .private;
}
