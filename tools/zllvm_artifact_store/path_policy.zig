const std = @import("std");

pub fn pathContains(parent: []const u8, child: []const u8) bool {
    if (std.mem.eql(u8, parent, child)) return true;
    return std.mem.startsWith(u8, child, parent) and child.len > parent.len and
        parent[parent.len - 1] != '/' and child[parent.len] == '/';
}

pub fn normalizedAbsolute(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    if (!std.fs.path.isAbsolute(path)) return error.PathNotAbsolute;
    return std.fs.path.resolve(allocator, &.{path});
}
