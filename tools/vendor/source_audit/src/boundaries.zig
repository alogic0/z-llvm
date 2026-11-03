//! Consumer-configured transitive import boundaries, independent of file layout.
const std = @import("std");
const graph_mod = @import("import_graph.zig");
const metrics = @import("structure_metrics.zig");
const A = std.mem.Allocator;

/// Constraints within one selector are ANDed; selector lists are ORed.
pub const Selector = struct {
    exact: ?[]const u8 = null,
    prefix: ?[]const u8 = null,
    suffix: ?[]const u8 = null,
    contains: ?[]const u8 = null,
    exclude_paths: []const []const u8 = &.{},
    tests: enum { any, only, exclude } = .any,

    pub fn matches(self: Selector, path: []const u8) bool {
        if (self.exact) |v| if (!std.mem.eql(u8, path, v)) return false;
        if (self.prefix) |v| if (!std.mem.startsWith(u8, path, v)) return false;
        if (self.suffix) |v| if (!std.mem.endsWith(u8, path, v)) return false;
        if (self.contains) |v| if (std.mem.indexOf(u8, path, v) == null) return false;
        for (self.exclude_paths) |v| if (std.mem.eql(u8, path, v)) return false;
        return switch (self.tests) {
            .any => true,
            .only => metrics.isTestFile(path),
            .exclude => !metrics.isTestFile(path),
        };
    }
};
pub const Rule = struct { name: []const u8, from: []const Selector, deny: []const Selector };
pub const Violation = struct { rule: []const u8, chain: []const []const u8 };

fn matches(selectors: []const Selector, path: []const u8) bool {
    for (selectors) |selector| if (selector.matches(path)) return true;
    return false;
}

/// Returned storage uses the caller's report arena; graph strings are borrowed.
/// Scratch is reused across origins. Predecessors avoid copying every path prefix.
pub fn checkGraph(a: A, graph: graph_mod.Graph, rules: []const Rule) ![]const Violation {
    var result: std.ArrayList(Violation) = .empty;
    var parents: std.StringHashMap([]const u8) = .init(a);
    defer parents.deinit();
    var pending: std.ArrayList([]const u8) = .empty;
    defer pending.deinit(a);
    for (graph.entries) |origin| {
        var active = false;
        for (rules) |rule| active = active or matches(rule.from, origin.path);
        if (!active) continue;
        parents.clearRetainingCapacity();
        pending.clearRetainingCapacity();
        try parents.put(origin.path, origin.path);
        try pending.append(a, origin.path);
        var cursor: usize = 0;
        var origin_seen = false;
        while (cursor < pending.items.len) : (cursor += 1) {
            const path = pending.items[cursor];
            const index = graph.index.get(path) orelse continue;
            if (metrics.isTestFile(path) and !std.mem.eql(u8, path, origin.path)) continue;
            for (graph.entries[index].dependencies) |target| {
                const closes_cycle = std.mem.eql(u8, target, origin.path);
                const slot = try parents.getOrPut(target);
                if (slot.found_existing and (!closes_cycle or origin_seen)) continue;
                if (!slot.found_existing) slot.value_ptr.* = path;
                if (closes_cycle) origin_seen = true;
                var forbidden: ?[]const u8 = null;
                for (rules) |rule| {
                    if (matches(rule.from, origin.path) and matches(rule.deny, target)) {
                        forbidden = rule.name;
                        break;
                    }
                }
                if (forbidden) |name| {
                    var chain: std.ArrayList([]const u8) = .empty;
                    var member = path;
                    while (true) {
                        try chain.append(a, member);
                        if (std.mem.eql(u8, member, origin.path)) break;
                        member = parents.get(member).?;
                    }
                    std.mem.reverse([]const u8, chain.items);
                    try chain.append(a, target);
                    try result.append(a, .{ .rule = try a.dupe(u8, name), .chain = try chain.toOwnedSlice(a) });
                } else if (!closes_cycle) try pending.append(a, target);
            }
        }
    }
    return result.toOwnedSlice(a);
}
