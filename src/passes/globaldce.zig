const std = @import("std");
const references = @import("../analysis/module_references.zig");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "globaldce",
    .category = .ipo,
    .target_status = "LLVM-shaped algorithm subset",
    .upstream_owner = "llvm/lib/Transforms/IPO/GlobalDCE.cpp",
    .run = run,
};

const NodeKind = enum { function, global, alias };

const NodeRef = struct {
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

const GlobalDependencyGraph = struct {
    allocator: std.mem.Allocator,
    nodes: std.ArrayList(Node),
    roots: std.ArrayList(NodeRef),
    has_unknown_roots: bool = false,

    fn build(allocator: std.mem.Allocator, module: ir.Module) !GlobalDependencyGraph {
        var graph: GlobalDependencyGraph = .{
            .allocator = allocator,
            .nodes = .empty,
            .roots = .empty,
        };
        errdefer graph.deinit();

        for (module.functions.items) |*function| {
            const ref: NodeRef = .{ .kind = .function, .name = function.name };
            var node: Node = .{ .ref = ref, .edges = .empty };
            errdefer node.deinit(allocator);
            if (!isLocal(function.linkage)) try graph.roots.append(allocator, ref);
            try references.walkFunction(function, EdgeVisitor{ .allocator = allocator, .module = &module, .edges = &node.edges, .has_unknown = &node.has_unknown });
            try graph.nodes.append(allocator, node);
        }
        for (module.globals.items) |*global| {
            const ref: NodeRef = .{ .kind = .global, .name = global.name };
            var node: Node = .{ .ref = ref, .edges = .empty };
            errdefer node.deinit(allocator);
            if (!isLocal(global.linkage)) try graph.roots.append(allocator, ref);
            try references.walkGlobal(global, EdgeVisitor{ .allocator = allocator, .module = &module, .edges = &node.edges, .has_unknown = &node.has_unknown });
            try graph.nodes.append(allocator, node);
        }
        for (module.aliases.items) |*alias| {
            const ref: NodeRef = .{ .kind = .alias, .name = alias.name };
            var node: Node = .{ .ref = ref, .edges = .empty };
            errdefer node.deinit(allocator);
            if (!isLocal(alias.linkage)) try graph.roots.append(allocator, ref);
            try references.walkAlias(alias, EdgeVisitor{ .allocator = allocator, .module = &module, .edges = &node.edges, .has_unknown = &node.has_unknown });
            try graph.nodes.append(allocator, node);
        }
        try references.walkModuleScope(&module, EdgeVisitor{ .allocator = allocator, .module = &module, .edges = &graph.roots, .has_unknown = &graph.has_unknown_roots });

        return graph;
    }

    fn deinit(graph: *GlobalDependencyGraph) void {
        for (graph.nodes.items) |*node| node.deinit(graph.allocator);
        graph.nodes.deinit(graph.allocator);
        graph.roots.deinit(graph.allocator);
    }

    fn nodeOf(graph: GlobalDependencyGraph, ref: NodeRef) ?*const Node {
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
        }
    }
};

fn definition(module: *const ir.Module, name: []const u8) ?NodeRef {
    for (module.functions.items) |function| {
        if (std.mem.eql(u8, function.name, name)) return .{ .kind = .function, .name = name };
    }
    for (module.globals.items) |global| {
        if (std.mem.eql(u8, global.name, name)) return .{ .kind = .global, .name = name };
    }
    for (module.aliases.items) |alias| {
        if (std.mem.eql(u8, alias.name, name)) return .{ .kind = .alias, .name = name };
    }
    return null;
}

fn run(module: *ir.Module, context: *pass_manager.Context) !pass_manager.PassResult {
    var graph = try GlobalDependencyGraph.build(context.allocator, module.*);
    defer graph.deinit();

    // Unknown module-scope references can name any definition. Unknowns in
    // unreachable definitions do not root anything; those definitions vanish.
    if (graph.has_unknown_roots) return .unchanged;

    var live = std.ArrayList(NodeRef).empty;
    defer live.deinit(context.allocator);

    var worklist = std.ArrayList(NodeRef).empty;
    defer worklist.deinit(context.allocator);

    for (graph.roots.items) |root| try markLive(context.allocator, &live, &worklist, root);
    while (worklist.pop()) |ref| {
        const node = graph.nodeOf(ref) orelse continue;
        // A live opaque region may refer to any node, including aliases and
        // COMDAT members. Preserve the entire module before any mutation.
        if (node.has_unknown) return .unchanged;
        for (node.edges.items) |edge| try markLive(context.allocator, &live, &worklist, edge);
    }

    const removed_functions = removeDeadFunctions(module, live.items);
    const removed_globals = removeDeadGlobals(module, live.items);
    const removed_aliases = removeDeadAliases(module, live.items);
    const removed_comdats = removeDeadComdats(module);
    return if (removed_functions or removed_globals or removed_aliases or removed_comdats) .changed else .unchanged;
}

fn removeDeadFunctions(module: *ir.Module, live: []const NodeRef) bool {
    var changed = false;
    var index: usize = 0;
    while (index < module.functions.items.len) {
        const function = module.functions.items[index];
        if (!isLocal(function.linkage) or containsRef(live, .{ .kind = .function, .name = function.name })) {
            index += 1;
            continue;
        }

        var removed = module.functions.orderedRemove(index);
        removed.deinit(module.allocator);
        changed = true;
    }
    return changed;
}

fn removeDeadGlobals(module: *ir.Module, live: []const NodeRef) bool {
    var changed = false;
    var index: usize = 0;
    while (index < module.globals.items.len) {
        const global = module.globals.items[index];
        if (!isLocal(global.linkage) or containsRef(live, .{ .kind = .global, .name = global.name })) {
            index += 1;
            continue;
        }
        var removed = module.globals.orderedRemove(index);
        removed.deinit(module.allocator);
        changed = true;
    }
    return changed;
}

fn removeDeadAliases(module: *ir.Module, live: []const NodeRef) bool {
    var changed = false;
    var index: usize = 0;
    while (index < module.aliases.items.len) {
        const alias = module.aliases.items[index];
        if (!isLocal(alias.linkage) or containsRef(live, .{ .kind = .alias, .name = alias.name })) {
            index += 1;
            continue;
        }
        _ = module.aliases.orderedRemove(index);
        changed = true;
    }
    return changed;
}

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

fn removeDeadComdats(module: *ir.Module) bool {
    var changed = false;
    var index: usize = 0;
    while (index < module.comdats.items.len) {
        const name = comdatRecordName(module.comdats.items[index]) orelse {
            index += 1;
            continue;
        };
        if (comdatReferenced(module.*, name)) {
            index += 1;
            continue;
        }
        _ = module.comdats.orderedRemove(index);
        changed = true;
    }
    return changed;
}

fn comdatReferenced(module: ir.Module, name: []const u8) bool {
    for (module.globals.items) |global| {
        if (attrsReferenceComdat(global.attrs, name)) return true;
    }
    for (module.functions.items) |function| {
        if (attrsReferenceComdat(function.attrs, name)) return true;
    }
    return false;
}

fn attrsReferenceComdat(attrs: ?[]const u8, name: []const u8) bool {
    const text = attrs orelse return false;
    var rest = text;
    while (std.mem.indexOf(u8, rest, "comdat(")) |relative_start| {
        const start = relative_start + "comdat(".len;
        const after_start = rest[start..];
        const close = std.mem.indexOfScalar(u8, after_start, ')') orelse return false;
        if (std.mem.eql(u8, after_start[0..close], name)) return true;
        rest = after_start[close + 1 ..];
    }
    return false;
}

fn comdatRecordName(record: []const u8) ?[]const u8 {
    const eq_index = std.mem.indexOfScalar(u8, record, '=') orelse return null;
    return std.mem.trim(u8, record[0..eq_index], " \t");
}

fn containsRef(refs: []const NodeRef, ref: NodeRef) bool {
    for (refs) |candidate| {
        if (sameRef(candidate, ref)) return true;
    }
    return false;
}

fn sameRef(a: NodeRef, b: NodeRef) bool {
    return a.kind == b.kind and std.mem.eql(u8, a.name, b.name);
}

fn isLocal(linkage: ir.FunctionLinkage) bool {
    return linkage == .internal or linkage == .private;
}
