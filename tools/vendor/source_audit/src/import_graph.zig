//! Literal local imports, reverse dependencies and strongly connected components.
//! Returned data belongs to the caller's allocator, normally a report arena.
const std = @import("std");
const metrics = @import("structure_metrics.zig");
const A = std.mem.Allocator;
pub const Source = struct { path: []const u8, text: []const u8, imports: ?[]const metrics.Import = null };
pub const Problem = struct { line: usize, name: []const u8, reason: enum { expression, outside_root, outside_scan } };
pub const Entry = struct {
    path: []const u8,
    dependencies: []const []const u8,
    dependents: usize = 0,
    modules: []const []const u8,
    unresolved: []const Problem,
    cycle: ?usize = null,
};
pub const Graph = struct {
    entries: []Entry,
    index: std.StringHashMap(usize),
    cycles: []const []const []const u8,
};

fn addUnique(a: A, list: *std.ArrayList([]const u8), value: []const u8) !void {
    for (list.items) |prior| if (std.mem.eql(u8, prior, value)) return;
    try list.append(a, value);
}
fn less(_: void, x: []const u8, y: []const u8) bool {
    return std.mem.lessThan(u8, x, y);
}
pub fn inspect(a: A, sources: []const Source) !Graph {
    var index: std.StringHashMap(usize) = .init(a);
    for (sources, 0..) |s, i| {
        const slot = try index.getOrPut(s.path);
        if (slot.found_existing) return error.DuplicateSource;
        slot.value_ptr.* = i;
    }
    const entries = try a.alloc(Entry, sources.len);
    for (sources, 0..) |s, i| {
        const parsed = s.imports orelse (try metrics.inspect(a, try a.dupeSentinel(u8, s.text, 0))).imports;
        var dependencies: std.ArrayList([]const u8) = .empty;
        var modules: std.ArrayList([]const u8) = .empty;
        var unresolved: std.ArrayList(Problem) = .empty;
        for (parsed) |imp| {
            // Inline test dependencies do not inflate production context.
            if (imp.test_only and !metrics.isTestFile(s.path)) continue;
            switch (imp.kind) {
                .dynamic => try unresolved.append(a, .{ .line = imp.line, .name = imp.name, .reason = .expression }),
                .module => try addUnique(a, &modules, imp.name),
                .local => {
                    const absolute = try std.fs.path.resolve(a, &.{ "/repository", std.fs.path.dirname(s.path) orelse ".", imp.name });
                    if (!std.mem.startsWith(u8, absolute, "/repository/")) {
                        try unresolved.append(a, .{ .line = imp.line, .name = imp.name, .reason = .outside_root });
                        continue;
                    }
                    const target = absolute["/repository/".len..];
                    try addUnique(a, &dependencies, target);
                    if (!index.contains(target)) try unresolved.append(a, .{ .line = imp.line, .name = target, .reason = .outside_scan });
                },
            }
        }
        std.mem.sort([]const u8, dependencies.items, {}, less);
        std.mem.sort([]const u8, modules.items, {}, less);
        entries[i] = .{ .path = s.path, .dependencies = try dependencies.toOwnedSlice(a), .modules = try modules.toOwnedSlice(a), .unresolved = try unresolved.toOwnedSlice(a) };
    }
    for (entries) |entry| {
        if (metrics.isTestFile(entry.path)) continue;
        for (entry.dependencies) |target| if (index.get(target)) |i| {
            entries[i].dependents += 1;
        };
    }
    var graph = Graph{ .entries = entries, .index = index, .cycles = &.{} };
    graph.cycles = try findCycles(a, &graph);
    return graph;
}

// Iterative Kosaraju traversal avoids recursion on long import chains.
fn findCycles(a: A, graph: *Graph) ![]const []const []const u8 {
    const n = graph.entries.len;
    const visited = try a.alloc(bool, n);
    defer a.free(visited);
    @memset(visited, false);
    const reverse = try a.alloc(std.ArrayList(usize), n);
    defer a.free(reverse);
    for (reverse) |*r| r.* = .empty;
    defer for (reverse) |*r| r.deinit(a);
    for (graph.entries, 0..) |entry, i| for (entry.dependencies) |target| {
        if (graph.index.get(target)) |j| try reverse[j].append(a, i);
    };
    const Frame = struct { node: usize, next: usize = 0 };
    var stack: std.ArrayList(Frame) = .empty;
    defer stack.deinit(a);
    var order: std.ArrayList(usize) = .empty;
    defer order.deinit(a);
    for (0..n) |root| {
        if (visited[root]) continue;
        visited[root] = true;
        try stack.append(a, .{ .node = root });
        while (stack.items.len != 0) {
            const top = &stack.items[stack.items.len - 1];
            const edges = graph.entries[top.node].dependencies;
            if (top.next == edges.len) {
                try order.append(a, top.node);
                _ = stack.pop();
                continue;
            }
            const target = edges[top.next];
            top.next += 1;
            const j = graph.index.get(target) orelse continue;
            if (visited[j]) continue;
            visited[j] = true;
            try stack.append(a, .{ .node = j });
        }
    }
    @memset(visited, false);
    var cycles: std.ArrayList([]const []const u8) = .empty;
    var pending: std.ArrayList(usize) = .empty;
    defer pending.deinit(a);
    var members: std.ArrayList(usize) = .empty;
    defer members.deinit(a);
    while (order.pop()) |root| {
        if (visited[root]) continue;
        visited[root] = true;
        members.clearRetainingCapacity();
        try pending.append(a, root);
        while (pending.pop()) |i| {
            try members.append(a, i);
            for (reverse[i].items) |j| {
                if (visited[j]) continue;
                visited[j] = true;
                try pending.append(a, j);
            }
        }
        var self_edge = false;
        for (graph.entries[root].dependencies) |target| {
            self_edge = self_edge or std.mem.eql(u8, target, graph.entries[root].path);
        }
        if (members.items.len < 2 and !self_edge) continue;
        const paths = try a.alloc([]const u8, members.items.len);
        for (members.items, paths) |i, *path| {
            graph.entries[i].cycle = cycles.items.len;
            path.* = graph.entries[i].path;
        }
        std.mem.sort([]const u8, paths, {}, less);
        try cycles.append(a, paths);
    }
    return cycles.toOwnedSlice(a);
}

test "distinct edges, production dependents, cycles and unresolved context" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const g = try inspect(arena.allocator(), &.{
        .{ .path = "src/a.zig", .text = "const b = @import (\"b.zig\"); const c = @import(\"b.zig\"); const std = @import(\"std\"); test { _ = @import(\"test.zig\"); }" },
        .{ .path = "src/b.zig", .text = "const a = @import(\"a.zig\"); const absent = @import(\"missing.zig\"); const x = @import(name); const y = @import(\"../../escape.zig\");" },
        .{ .path = "src/c.zig", .text = "// @import(\"a.zig\")\nconst s = \"@import(\\\"a.zig\\\")\";" },
        .{ .path = "src/a_test.zig", .text = "test { _ = @import(\"a.zig\"); }" },
    });
    try std.testing.expectEqual(@as(usize, 1), g.entries[0].dependencies.len);
    try std.testing.expectEqual(@as(usize, 1), g.entries[0].dependents);
    try std.testing.expectEqual(@as(usize, 1), g.entries[0].modules.len);
    try std.testing.expectEqual(@as(usize, 3), g.entries[1].unresolved.len);
    try std.testing.expectEqual(@as(usize, 0), g.entries[2].dependencies.len);
    try std.testing.expectEqual(@as(usize, 1), g.cycles.len);
    try std.testing.expectEqual(@as(usize, 2), g.cycles[0].len);
}

test "self cycles and a long acyclic chain terminate" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    var sources: std.ArrayList(Source) = .empty;
    for (0..1500) |i| try sources.append(a, .{ .path = try std.fmt.allocPrint(a, "src/{d}.zig", .{i}), .text = try std.fmt.allocPrint(a, "const next = @import(\"{d}.zig\");", .{i + 1}) });
    try sources.append(a, .{ .path = "src/1500.zig", .text = "" });
    try sources.append(a, .{ .path = "src/self.zig", .text = "const self = @import(\"self.zig\");" });
    const g = try inspect(a, sources.items);
    try std.testing.expectEqual(@as(usize, 1), g.cycles.len);
    try std.testing.expectEqualStrings("src/self.zig", g.cycles[0][0]);
}
