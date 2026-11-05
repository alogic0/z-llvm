const std = @import("std");
const u = @import("common.zig");

pub fn files(c: *u.Context, scope: []const []const u8) !u.Value {
    var argv: std.ArrayList([]const u8) = .empty;
    try argv.appendSlice(c.a, &.{ "git", "ls-files", "--cached", "--others", "--exclude-standard", "-z", "--" });
    try argv.appendSlice(c.a, scope);
    const listed = try c.capture(argv.items);
    var paths: std.ArrayList([]const u8) = .empty;
    var split = std.mem.tokenizeScalar(u8, listed, 0);
    while (split.next()) |path| try paths.append(c.a, path);
    std.mem.sort([]const u8, paths.items, {}, struct {
        fn less(_: void, a: []const u8, b: []const u8) bool {
            return std.mem.lessThan(u8, a, b);
        }
    }.less);
    var result = u.object(c.a);
    for (paths.items) |path| {
        const absolute = try c.join(&.{path});
        // Deleted tracked paths are represented explicitly until committed.
        try u.put(c.a, &result, path, if (u.exists(c.io, absolute)) u.s(try c.digest(absolute)) else .null);
    }
    return result;
}
pub fn toolSources(c: *u.Context) !u.Value {
    return files(c, &.{ "tools", "test/real_programs/native_canaries.json", "test/behavioral/performance_manifest.json" });
}
pub fn tools(c: *u.Context) !u.Value {
    var result = u.object(c.a);
    try u.put(c.a, &result, "binary_sha256", u.s(try c.digest("/proc/self/exe")));
    try u.put(c.a, &result, "source_sha256", try toolSources(c));
    try u.put(c.a, &result, "process_provider_revision", u.s("e9fcfccecc84f44a362b12de1bee78258b1e811f"));
    try u.put(c.a, &result, "test_support_provider_revision", u.s("f0f54d4e8cb649af7673ca498f259b6b2f9aa25e"));
    return result;
}
pub fn verifyTools(c: *u.Context, before: u.Value) !void {
    if (!u.json.eql(before, try tools(c))) return error.ValidationToolsChanged;
}
pub fn snapshot(c: *u.Context) !u.Value {
    var result = u.object(c.a);
    try u.put(c.a, &result, "schema", u.n(1));
    try u.put(c.a, &result, "root", u.s(c.root));
    try u.put(c.a, &result, "head", u.s(u.trim(try c.capture(&.{ "git", "rev-parse", "HEAD" }))));
    try u.put(c.a, &result, "tree", u.s(u.trim(try c.capture(&.{ "git", "rev-parse", "HEAD^{tree}" }))));
    try u.put(c.a, &result, "files", try files(c, &.{}));
    return result;
}
pub fn relative(c: *u.Context, path: []const u8) ![]const u8 {
    const absolute = try c.join(&.{path});
    if (!u.isWithin(c.root, absolute)) return error.PathOutsideProject;
    return absolute[c.root.len + 1 ..];
}
