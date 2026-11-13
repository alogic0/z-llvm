const std = @import("std");
pub const Evidence = struct { path: []const u8, sha256: []const u8 };
pub const Config = struct {
    schema: u32 = 1,
    minimum_idle_hours: u32 = 24,
    max_candidates: usize = 64,
    max_candidate_entries: usize = 250_000,
    max_reclaim_bytes: u64 = 32 * 1024 * 1024 * 1024,
    current_manifests: []const []const u8 = &.{},
    protected_paths: []const []const u8 = &.{},
    retired_manifests: []const Evidence = &.{},
    holds_file: []const u8 = "local-state/storage-cleanup/holds.json",
};
pub const Holds = struct { schema: u32 = 1, paths: []const []const u8 = &.{} };
pub const Retained = struct { path: []const u8, sha256: []const u8, role: enum { source, input, build, result, diagnostic, audit, compiler, other } };
pub const Artifact = struct { path: []const u8, sha256: []const u8, kind: enum { raw_trace, build_output, log }, audit: ?[]const u8 = null };
pub const Release = struct {
    schema: []const u8,
    state: enum { held, superseded },
    run_root: []const u8,
    reason: []const u8,
    producer: Evidence,
    successor: Evidence,
    retained: []const Retained,
    artifacts: []const Artifact,
};
pub fn within(root: []const u8, p: []const u8) bool {
    return std.mem.eql(u8, root, p) or (p.len > root.len and std.mem.startsWith(u8, p, root) and p[root.len] == '/');
}
pub fn overlaps(a: []const u8, b: []const u8) bool {
    return within(a, b) or within(b, a);
}
pub fn relative(p: []const u8) bool {
    if (p.len == 0 or std.fs.path.isAbsolute(p)) return false;
    for (p) |ch| if (ch < 32 or ch == 127 or ch == '\\') return false;
    var parts = std.mem.splitScalar(u8, p, '/');
    while (parts.next()) |part| if (part.len == 0 or std.mem.eql(u8, part, ".") or std.mem.eql(u8, part, "..")) return false;
    return true;
}
pub fn candidate(p: []const u8) bool {
    if (!relative(p) or !std.mem.startsWith(u8, p, "local-state/validations/")) return false;
    var parts = std.mem.splitScalar(u8, p, '/');
    var count: usize = 0;
    while (parts.next()) |_| count += 1;
    return count >= 5;
}
pub fn hash(s: []const u8) bool {
    if (s.len != 64) return false;
    for (s) |ch| if (!std.ascii.isHex(ch) or (ch >= 'A' and ch <= 'F')) return false;
    return true;
}
pub fn cacheName(s: []const u8) bool {
    for ([_][]const u8{ ".zig-cache", "zig-local-cache", "zig-global-cache", "local-cache", "global-cache" }) |name| if (std.mem.eql(u8, name, s)) return true;
    return false;
}
pub fn cacheOwned(run: []const u8, path: []const u8) bool {
    return candidate(path) and std.mem.eql(u8, std.fs.path.dirname(path) orelse "", run) and cacheName(std.fs.path.basename(path));
}
pub fn artifactName(a: Artifact) bool {
    if (!candidate(a.path) or !hash(a.sha256)) return false;
    const name = std.fs.path.basename(a.path);
    return switch (a.kind) {
        .raw_trace => std.mem.eql(u8, name, "profile.events.jsonl") and a.audit != null,
        .build_output => std.mem.eql(u8, name, "z_llvm") or std.mem.endsWith(u8, name, ".o") or std.mem.endsWith(u8, name, ".obj") or std.mem.endsWith(u8, name, ".exe") or std.mem.endsWith(u8, name, ".a"),
        .log => std.mem.endsWith(u8, name, ".log") or std.mem.endsWith(u8, name, ".stdout") or std.mem.endsWith(u8, name, ".stderr"),
    };
}
pub fn validate(c: Config) !void {
    if (c.schema != 1 or c.max_candidates == 0 or c.max_candidates > 1024 or c.max_candidate_entries == 0 or c.max_candidate_entries > 1_000_000 or c.max_reclaim_bytes == 0 or !relative(c.holds_file)) return error.InvalidPolicy;
    for (c.current_manifests) |m| {
        if (!relative(m)) return error.InvalidPolicy;
        for (c.retired_manifests) |r| if (std.mem.eql(u8, m, r.path)) return error.CurrentManifestCannotBeRetired;
    }
    for (c.protected_paths) |p| if (!relative(p)) return error.InvalidPolicy;
    for (c.retired_manifests) |p| if (!relative(p.path) or !hash(p.sha256)) return error.InvalidPolicy;
}
test "storage cleanup: scope rejects traversal, source roots, shared caches and non-canonical names" {
    const t = std.testing;
    try t.expect(!candidate("local-state/validations/a/../source/.zig-cache"));
    try t.expect(!candidate("local-state/caches/a/.zig-cache"));
    try t.expect(!candidate("/tmp/cache"));
    try t.expect(!relative("a//b"));
    try t.expect(!relative("a\nb"));
    try t.expect(cacheOwned("local-state/validations/a/build", "local-state/validations/a/build/zig-local-cache"));
    try t.expect(!cacheOwned("local-state/validations/a/build", "local-state/validations/a/src/.zig-cache"));
    try t.expect(!overlaps("a/cache", "a/cache-other"));
    try t.expect(overlaps("a/cache", "a/cache/o"));
}
test "storage cleanup: current manifest cannot be excused as historical" {
    try std.testing.expectError(error.CurrentManifestCannotBeRetired, validate(.{ .current_manifests = &.{"current.sha256"}, .retired_manifests = &.{.{ .path = "current.sha256", .sha256 = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" }} }));
}
test "storage cleanup: release artifact allowlist cannot name source or input evidence" {
    try std.testing.expect(!artifactName(.{ .path = "local-state/validations/a/run/input.ll", .sha256 = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", .kind = .build_output }));
    try std.testing.expect(!artifactName(.{ .path = "local-state/validations/a/run/profile.events.jsonl", .sha256 = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", .kind = .raw_trace }));
}
