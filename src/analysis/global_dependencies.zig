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

const RefContext = struct {
    pub fn hash(_: RefContext, ref: NodeRef) u64 {
        return ir.identifiers.Context.hash(.{}, ref.name) ^ @as(u64, @backingInt(ref.kind));
    }

    pub fn eql(_: RefContext, left: NodeRef, right: NodeRef) bool {
        return sameRef(left, right);
    }
};

const NodeIndex = std.HashMapUnmanaged(NodeRef, usize, RefContext, std.hash_map.default_max_load_percentage);
const Membership = std.HashMapUnmanaged(NodeRef, void, RefContext, std.hash_map.default_max_load_percentage);

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
    node_index: NodeIndex = .empty,

    pub fn build(allocator: std.mem.Allocator, module: ir.Module) !Graph {
        var graph: Graph = .{
            .allocator = allocator,
            .nodes = .empty,
            .roots = .empty,
        };
        errdefer graph.deinit();
        // Install all forward references before visiting any bodies. Insertion
        // order preserves the first definition within each symbol kind.
        var position: usize = 0;
        inline for (.{ NodeKind.function, NodeKind.global, NodeKind.alias }, .{ module.functions.items, module.globals.items, module.aliases.items }) |kind, definitions| {
            for (definitions) |item| {
                if (ir.identifiers.isValid(item.name)) {
                    const entry = try graph.node_index.getOrPut(allocator, .{ .kind = kind, .name = item.name });
                    if (!entry.found_existing) entry.value_ptr.* = position;
                } else graph.has_unknown_roots = true;
                position += 1;
            }
        }
        var reference_context = try references.Context.init(allocator, &module);
        defer reference_context.deinit();

        for (module.functions.items) |*function| {
            const ref: NodeRef = .{ .kind = .function, .name = function.name };
            var node: Node = .{ .ref = ref, .edges = .empty };
            errdefer node.deinit(allocator);
            if (!isLocal(function.linkage)) try graph.roots.append(allocator, ref);
            try reference_context.walkFunction(function, EdgeVisitor{ .allocator = allocator, .index = &graph.node_index, .edges = &node.edges, .has_unknown = &node.has_unknown });
            try graph.nodes.append(allocator, node);
        }
        for (module.globals.items) |*global| {
            const ref: NodeRef = .{ .kind = .global, .name = global.name };
            var node: Node = .{ .ref = ref, .edges = .empty };
            errdefer node.deinit(allocator);
            if (!isLocal(global.linkage)) try graph.roots.append(allocator, ref);
            try reference_context.walkGlobal(global, EdgeVisitor{ .allocator = allocator, .index = &graph.node_index, .edges = &node.edges, .has_unknown = &node.has_unknown });
            try graph.nodes.append(allocator, node);
        }
        for (module.aliases.items) |*alias| {
            const ref: NodeRef = .{ .kind = .alias, .name = alias.name };
            var node: Node = .{ .ref = ref, .edges = .empty };
            errdefer node.deinit(allocator);
            if (!isLocal(alias.linkage)) try graph.roots.append(allocator, ref);
            try references.walkAlias(alias, EdgeVisitor{ .allocator = allocator, .index = &graph.node_index, .edges = &node.edges, .has_unknown = &node.has_unknown });
            try graph.nodes.append(allocator, node);
        }
        try reference_context.walkModuleScope(EdgeVisitor{ .allocator = allocator, .index = &graph.node_index, .edges = &graph.roots, .has_unknown = &graph.has_unknown_roots });

        return graph;
    }

    pub fn deinit(graph: *Graph) void {
        for (graph.nodes.items) |*node| node.deinit(graph.allocator);
        graph.nodes.deinit(graph.allocator);
        graph.node_index.deinit(graph.allocator);
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
        for (graph.roots.items) |root| try result.markLive(&worklist, root);
        while (worklist.pop()) |ref| {
            const node = graph.nodeOf(ref) orelse continue;
            if (node.has_unknown) {
                result.has_unknown = true;
                return result;
            }
            for (node.edges.items) |edge| try result.markLive(&worklist, edge);
        }
        return result;
    }

    fn nodeOf(graph: Graph, ref: NodeRef) ?*const Node {
        const position = graph.node_index.get(ref) orelse return null;
        return &graph.nodes.items[position];
    }
};

const EdgeVisitor = struct {
    pub const Error = std.mem.Allocator.Error;
    allocator: std.mem.Allocator,
    index: *const NodeIndex,
    edges: *std.ArrayList(NodeRef),
    has_unknown: *bool,

    pub fn visit(visitor: EdgeVisitor, _: references.Site, event: references.Event) Error!void {
        switch (event) {
            .unknown => visitor.has_unknown.* = true,
            .symbol => |name| if (definition(visitor.index, name)) |ref| {
                try appendUniqueEdge(visitor.allocator, visitor.edges, ref);
            },
            .block_address => |address| if (definition(visitor.index, address.function)) |ref| {
                try appendUniqueEdge(visitor.allocator, visitor.edges, ref);
            },
        }
    }
};

fn definition(index: *const NodeIndex, name: []const u8) ?NodeRef {
    // Unqualified references use function, global, then alias precedence.
    for ([_]NodeKind{ .function, .global, .alias }) |kind| {
        if (index.getKey(.{ .kind = kind, .name = name })) |stored| return stored;
    }
    return null;
}

pub const Reachability = struct {
    allocator: std.mem.Allocator,
    live: std.ArrayList(NodeRef) = .empty,
    // Names belong to the module, membership storage belongs to this result.
    members: Membership = .empty,
    has_unknown: bool = false,

    pub fn deinit(result: *Reachability) void {
        result.live.deinit(result.allocator);
        result.members.deinit(result.allocator);
    }

    pub fn contains(result: Reachability, kind: NodeKind, name: []const u8) bool {
        return result.has_unknown or result.members.contains(.{ .kind = kind, .name = name });
    }

    fn markLive(result: *Reachability, worklist: *std.ArrayList(NodeRef), ref: NodeRef) !void {
        if ((try result.members.getOrPut(result.allocator, ref)).found_existing) return;
        try result.live.append(result.allocator, ref);
        try worklist.append(result.allocator, ref);
    }
};

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
