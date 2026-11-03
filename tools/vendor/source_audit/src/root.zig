//! Owned source-analysis reports; the low-level arena APIs remain available.
const std = @import("std");
pub const structure = @import("structure_metrics.zig");
pub const imports = @import("import_graph.zig");
pub const readability = @import("source_readability.zig");
pub const boundaries = @import("boundaries.zig");
pub const Input = struct { path: []const u8, text: []const u8 };
pub const File = struct {
    path: []const u8,
    bytes: usize,
    structure: ?structure.Result,
    readability: readability.Metrics,
};
pub const Report = struct {
    arena: *std.heap.ArenaAllocator,
    files: []const File,
    graph: imports.Graph,
    syntax_errors: usize,

    pub fn deinit(self: *Report) void {
        const parent = self.arena.child_allocator;
        self.arena.deinit();
        parent.destroy(self.arena);
        self.* = undefined;
    }

    pub fn check(self: *Report, rules: []const boundaries.Rule) ![]const boundaries.Violation {
        return boundaries.checkGraph(self.arena.allocator(), self.graph, rules);
    }
};

/// The report owns copied paths, source-derived names and all graph data.
/// Invalid syntax is recorded per file; allocation/path/duplicate errors fail.
pub fn analyze(parent: std.mem.Allocator, input: []const Input) !Report {
    const arena = try parent.create(std.heap.ArenaAllocator);
    arena.* = .init(parent);
    errdefer {
        arena.deinit();
        parent.destroy(arena);
    }
    const a = arena.allocator();
    const files = try a.alloc(File, input.len);
    const sources = try a.alloc(imports.Source, input.len);
    var syntax_errors: usize = 0;
    for (input, files, sources) |entry, *file, *source| {
        if (!validPath(entry.path)) return error.InvalidSourcePath;
        const path = try a.dupe(u8, entry.path);
        const text = try a.dupeSentinel(u8, entry.text, 0);
        const measured = structure.inspect(a, text) catch |err| switch (err) {
            error.InvalidZigSource => null,
            else => return err,
        };
        if (measured == null) syntax_errors += 1;
        file.* = .{ .path = path, .bytes = entry.text.len, .structure = measured, .readability = readability.inspect(text) };
        source.* = .{ .path = path, .text = "", .imports = if (measured) |m| m.imports else &.{} };
    }
    return .{ .arena = arena, .files = files, .graph = try imports.inspect(a, sources), .syntax_errors = syntax_errors };
}

pub fn validPath(path: []const u8) bool {
    if (path.len == 0 or std.fs.path.isAbsolute(path) or std.mem.indexOfAny(u8, path, "\\\x00") != null) return false;
    var parts = std.mem.splitScalar(u8, path, '/');
    while (parts.next()) |part| {
        if (part.len == 0 or std.mem.eql(u8, part, ".") or std.mem.eql(u8, part, "..")) return false;
    }
    return true;
}

test {
    _ = @import("root_test.zig");
}
