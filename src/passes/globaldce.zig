const std = @import("std");
const call_graph = @import("../analysis/call_graph.zig");
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

    fn deinit(node: *Node, allocator: std.mem.Allocator) void {
        node.edges.deinit(allocator);
    }
};

const GlobalDependencyGraph = struct {
    allocator: std.mem.Allocator,
    nodes: std.ArrayList(Node),
    roots: std.ArrayList(NodeRef),

    fn build(allocator: std.mem.Allocator, module: ir.Module) !GlobalDependencyGraph {
        var graph: GlobalDependencyGraph = .{
            .allocator = allocator,
            .nodes = .empty,
            .roots = .empty,
        };
        errdefer graph.deinit();

        var calls = try call_graph.CallGraph.build(allocator, module);
        defer calls.deinit();

        for (module.functions.items) |function| {
            const ref: NodeRef = .{ .kind = .function, .name = function.name };
            var node: Node = .{ .ref = ref, .edges = .empty };
            errdefer node.deinit(allocator);
            if (!isLocal(function.linkage) or hasComdat(function.attrs)) try graph.roots.append(allocator, ref);
            const callees = calls.calleesOf(function.name) orelse &.{};
            for (callees) |callee| {
                if (!hasFunctionDefinition(module, callee)) continue;
                try appendUniqueEdge(allocator, &node.edges, .{ .kind = .function, .name = callee });
            }
            try addFunctionGlobalEdges(allocator, module, &node.edges, function);
            try graph.nodes.append(allocator, node);
        }

        for (module.globals.items) |global| {
            const ref: NodeRef = .{ .kind = .global, .name = global.name };
            var node: Node = .{ .ref = ref, .edges = .empty };
            errdefer node.deinit(allocator);
            if (!isLocal(global.linkage) or hasComdat(global.attrs) or isThreadLocal(global)) try graph.roots.append(allocator, ref);
            try addInitializerEdges(allocator, module, &node.edges, global.initializer);
            try graph.nodes.append(allocator, node);
        }

        for (module.aliases.items) |alias| {
            const ref: NodeRef = .{ .kind = .alias, .name = alias.name };
            var node: Node = .{ .ref = ref, .edges = .empty };
            errdefer node.deinit(allocator);
            if (!isLocal(alias.linkage)) try graph.roots.append(allocator, ref);
            if (hasFunctionDefinition(module, alias.target)) {
                try appendUniqueEdge(allocator, &node.edges, .{ .kind = .function, .name = alias.target });
            } else if (hasGlobalDefinition(module, alias.target)) {
                try appendUniqueEdge(allocator, &node.edges, .{ .kind = .global, .name = alias.target });
            }
            try graph.nodes.append(allocator, node);
        }

        return graph;
    }

    fn deinit(graph: *GlobalDependencyGraph) void {
        for (graph.nodes.items) |*node| node.deinit(graph.allocator);
        graph.nodes.deinit(graph.allocator);
        graph.roots.deinit(graph.allocator);
    }

    fn edgesOf(graph: GlobalDependencyGraph, ref: NodeRef) []const NodeRef {
        for (graph.nodes.items) |node| {
            if (sameRef(node.ref, ref)) return node.edges.items;
        }
        return &.{};
    }
};

fn addInitializerEdges(
    allocator: std.mem.Allocator,
    module: ir.Module,
    edges: *std.ArrayList(NodeRef),
    initializer: ir.GlobalInitializer,
) !void {
    switch (initializer) {
        .scalar => |value| try addValueEdge(allocator, module, edges, value),
        .array => |array| for (array.values.items) |value| try addValueEdge(allocator, module, edges, value),
    }
}

fn addValueEdge(allocator: std.mem.Allocator, module: ir.Module, edges: *std.ArrayList(NodeRef), value: ir.Value) !void {
    const raw_name = switch (value) {
        .named => |name| name,
        .int, .undef => return,
    };
    const name = if (std.mem.startsWith(u8, raw_name, "@")) raw_name[1..] else raw_name;
    if (hasFunctionDefinition(module, name)) {
        try appendUniqueEdge(allocator, edges, .{ .kind = .function, .name = name });
    } else if (hasGlobalDefinition(module, name)) {
        try appendUniqueEdge(allocator, edges, .{ .kind = .global, .name = name });
    }
}

fn addFunctionGlobalEdges(allocator: std.mem.Allocator, module: ir.Module, edges: *std.ArrayList(NodeRef), function: ir.Function) !void {
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            switch (instruction.kind) {
                .binary => |binary| {
                    try addValueEdge(allocator, module, edges, binary.lhs);
                    try addValueEdge(allocator, module, edges, binary.rhs);
                },
                .cast => |cast| try addValueEdge(allocator, module, edges, cast.value),
                .freeze => |freeze| try addValueEdge(allocator, module, edges, freeze.value),
                .icmp => |icmp| {
                    try addValueEdge(allocator, module, edges, icmp.lhs);
                    try addValueEdge(allocator, module, edges, icmp.rhs);
                },
                .fcmp => |fcmp| {
                    try addValueEdge(allocator, module, edges, fcmp.lhs);
                    try addValueEdge(allocator, module, edges, fcmp.rhs);
                },
                .select => |select| {
                    try addValueEdge(allocator, module, edges, select.cond);
                    try addValueEdge(allocator, module, edges, select.true_value);
                    try addValueEdge(allocator, module, edges, select.false_value);
                },
                .phi => |phi| for (phi.incoming.items) |incoming| try addValueEdge(allocator, module, edges, incoming.value),
                .alloca => {},
                .load => |load| try addValueEdge(allocator, module, edges, load.ptr),
                .store => |store| {
                    try addValueEdge(allocator, module, edges, store.value);
                    try addValueEdge(allocator, module, edges, store.ptr);
                },
                .gep => |gep| {
                    try addValueEdge(allocator, module, edges, gep.ptr);
                    for (gep.indices.items) |index| try addValueEdge(allocator, module, edges, index.value);
                },
                .call => |call| for (call.args.items) |arg| try addValueEdge(allocator, module, edges, arg.value),
            }
        }
        if (block.terminator) |terminator| switch (terminator) {
            .ret => |ret| if (ret.value) |value| try addValueEdge(allocator, module, edges, value),
            .condbr => |condbr| try addValueEdge(allocator, module, edges, condbr.cond),
            .br, .@"unreachable" => {},
        };
    }
}

fn run(module: *ir.Module, context: *pass_manager.Context) !pass_manager.PassResult {
    var graph = try GlobalDependencyGraph.build(context.allocator, module.*);
    defer graph.deinit();

    var live = std.ArrayList(NodeRef).empty;
    defer live.deinit(context.allocator);

    var worklist = std.ArrayList(NodeRef).empty;
    defer worklist.deinit(context.allocator);

    for (graph.roots.items) |root| try markLive(context.allocator, &live, &worklist, root);
    while (worklist.pop()) |ref| {
        for (graph.edgesOf(ref)) |edge| try markLive(context.allocator, &live, &worklist, edge);
    }

    const removed_functions = removeDeadFunctions(module, live.items);
    const removed_globals = removeDeadGlobals(module, live.items);
    const removed_aliases = removeDeadAliases(module, live.items);
    return if (removed_functions or removed_globals or removed_aliases) .changed else .unchanged;
}

fn removeDeadFunctions(module: *ir.Module, live: []const NodeRef) bool {
    var changed = false;
    var index: usize = 0;
    while (index < module.functions.items.len) {
        const function = module.functions.items[index];
        if (!isLocal(function.linkage) or hasComdat(function.attrs) or containsRef(live, .{ .kind = .function, .name = function.name })) {
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
        if (!isLocal(global.linkage) or hasComdat(global.attrs) or isThreadLocal(global) or containsRef(live, .{ .kind = .global, .name = global.name })) {
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

fn containsRef(refs: []const NodeRef, ref: NodeRef) bool {
    for (refs) |candidate| {
        if (sameRef(candidate, ref)) return true;
    }
    return false;
}

fn sameRef(a: NodeRef, b: NodeRef) bool {
    return a.kind == b.kind and std.mem.eql(u8, a.name, b.name);
}

fn hasFunctionDefinition(module: ir.Module, name: []const u8) bool {
    for (module.functions.items) |function| {
        if (std.mem.eql(u8, function.name, name)) return true;
    }
    return false;
}

fn hasGlobalDefinition(module: ir.Module, name: []const u8) bool {
    for (module.globals.items) |global| {
        if (std.mem.eql(u8, global.name, name)) return true;
    }
    return false;
}

fn isLocal(linkage: ir.FunctionLinkage) bool {
    return linkage == .internal or linkage == .private;
}

fn hasComdat(attrs: ?[]const u8) bool {
    return if (attrs) |text| std.mem.indexOf(u8, text, "comdat") != null else false;
}

fn isThreadLocal(global: ir.Global) bool {
    return if (global.address_attrs) |text| std.mem.indexOf(u8, text, "thread_local") != null else false;
}
