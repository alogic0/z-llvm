const std = @import("std");
pub const Evidence = struct { path: []const u8, sha256: []const u8 };
pub const Config = struct {
    schema: u32 = 1,
    minimum_idle_hours: u32 = 24,
    max_candidates: usize = 64,
    max_candidate_entries: usize = 250_000,
    max_reclaim_bytes: u64 = 32 * 1024 * 1024 * 1024,
    cache_evidence: enum { replay, closed_producer } = .replay,
    current_manifests: []const []const u8 = &.{},
    protected_paths: []const []const u8 = &.{},
    retired_manifests: []const Evidence = &.{},
    retired_empty_log_records: []const Evidence = &.{},
    holds_file: []const u8 = "local-state/storage-cleanup/holds.json",
};
/// Minimal retention changes batching and the optional waiting period only.
/// Provenance, pins, ownership, consumers and mutation checks are identical.
pub fn minimal(c: Config) Config {
    var result = c;
    result.minimum_idle_hours = 0;
    result.max_candidates = 16_384;
    return result;
}
pub const Holds = struct { schema: u32 = 1, paths: []const []const u8 = &.{} };
pub const Retained = struct { path: []const u8, sha256: []const u8, role: enum { source, input, build, result, diagnostic, audit, compiler, other } };
pub const Artifact = struct { path: []const u8, sha256: []const u8 = "", kind: enum { raw_trace, build_output, generated_assembly, log, private_cache }, audit: ?[]const u8 = null };
pub const CacheOwner = struct {
    working_directory: []const u8,
    legacy_working_directory_review: ?[]const u8 = null,
};
pub const PinTransition = struct {
    manifest: Evidence,
    reference: []const u8,
    target: Evidence,
    reason: []const u8,
};
pub const Release = struct {
    schema: []const u8,
    state: enum { held, disposable, superseded, audited },
    run_root: []const u8,
    reason: []const u8,
    producer: Evidence,
    successor: ?Evidence = null,
    retained: []const Retained,
    artifacts: []const Artifact,
    source_reconstructions: []const Evidence = &.{},
    retired_pins: []const PinTransition = &.{},
    cache_owner: ?CacheOwner = null,
    compiler_retirement: ?Evidence = null,
    command_outputs: ?Evidence = null,
    command_caches: ?Evidence = null,
    command_owner: ?CacheOwner = null,
    closed_command_outputs: bool = false,
    compiler_observation: ?Evidence = null,
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
pub fn validationRun(p: []const u8) bool {
    return relative(p) and std.mem.startsWith(u8, p, "local-state/validations/") and p.len > "local-state/validations/".len;
}
pub fn validationOutput(path: []const u8) bool {
    return relative(path) and validationRun(std.fs.path.dirname(path) orelse "");
}
pub fn releaseRoot(r: Release) bool {
    if (candidate(r.run_root)) return true;
    if (!validationRun(r.run_root)) return false;
    if (r.command_outputs != null or r.compiler_observation != null) return true;
    // Older real-program runs have no batch component. Admit only their exact
    // capture helper here; generated.verify still requires a passed comparison
    // and the runner's recorded binary hash before collection.
    if (r.state != .disposable or r.artifacts.len != 1) return false;
    const artifact = r.artifacts[0];
    return artifact.kind == .build_output and
        std.mem.eql(u8, std.fs.path.basename(artifact.path), "capture-zllvm") and
        std.mem.eql(u8, std.fs.path.dirname(artifact.path) orelse "", r.run_root) and
        std.mem.eql(u8, std.fs.path.basename(r.producer.path), "report.json") and
        std.mem.eql(u8, std.fs.path.dirname(r.producer.path) orelse "", r.run_root);
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
pub fn privateCacheName(name: []const u8) bool {
    return cacheName(name) or (std.mem.startsWith(u8, name, "zig-local-") and name.len > "zig-local-".len) or
        (std.mem.startsWith(u8, name, "zig-global-") and name.len > "zig-global-".len);
}
pub fn commandCacheName(name: []const u8) bool {
    return cacheName(name) or std.mem.eql(u8, name, "frontend-cache") or
        std.mem.eql(u8, name, "reference-cache") or std.mem.eql(u8, name, "candidate-cache") or
        std.mem.eql(u8, name, "reference-link-cache") or std.mem.eql(u8, name, "candidate-link-cache");
}
pub fn privateCacheOwned(run: []const u8, cwd: []const u8, path: []const u8) bool {
    if (std.mem.eql(u8, cwd, ".")) return privateCacheOwned(run, run, path);
    if (!candidate(cwd) or !candidate(path) or !within(run, cwd) or !within(cwd, path) or !privateCacheName(std.fs.path.basename(path))) return false;
    const parent = std.fs.path.dirname(path) orelse return false;
    if (std.mem.eql(u8, parent, cwd)) return true;
    return std.mem.eql(u8, std.fs.path.dirname(parent) orelse "", cwd) and
        (std.mem.eql(u8, std.fs.path.basename(parent), "evidence") or std.mem.eql(u8, std.fs.path.basename(parent), "local-state"));
}
pub fn artifactName(a: Artifact) bool {
    if (!candidate(a.path)) return false;
    if (a.kind == .private_cache) return a.sha256.len == 0 and (privateCacheName(std.fs.path.basename(a.path)) or commandCacheName(std.fs.path.basename(a.path)));
    if (!hash(a.sha256)) return false;
    const name = std.fs.path.basename(a.path);
    return switch (a.kind) {
        .raw_trace => std.mem.eql(u8, name, "profile.events.jsonl") and a.audit != null,
        .build_output => std.mem.eql(u8, name, "local") or std.mem.eql(u8, name, "reference") or std.mem.eql(u8, name, "z_llvm") or std.mem.eql(u8, name, "capture-zllvm") or std.mem.endsWith(u8, name, ".o") or std.mem.endsWith(u8, name, ".obj") or std.mem.endsWith(u8, name, ".exe") or std.mem.endsWith(u8, name, ".a"),
        .generated_assembly => std.mem.eql(u8, name, "linked-harness.s"),
        .log => std.mem.endsWith(u8, name, ".log") or std.mem.endsWith(u8, name, ".stdout") or std.mem.endsWith(u8, name, ".stderr"),
        .private_cache => unreachable,
    };
}
/// Test runners also produce names such as case-reference and linked-harness.
/// These names are admitted only with a verified command-output owner; the
/// collector additionally requires ELF/archive bytes before any removal.
pub fn commandOutputName(a: Artifact) bool {
    return a.kind == .build_output and validationOutput(a.path) and hash(a.sha256) and
        (artifactName(a) or std.mem.indexOfScalar(u8, std.fs.path.basename(a.path), '.') == null);
}
pub fn validate(c: Config) !void {
    if (c.schema != 1 or c.max_candidates == 0 or c.max_candidates > 16_384 or c.max_candidate_entries == 0 or c.max_candidate_entries > 1_000_000 or c.max_reclaim_bytes == 0 or !relative(c.holds_file)) return error.InvalidPolicy;
    for (c.current_manifests) |m| {
        if (!relative(m)) return error.InvalidPolicy;
        for (c.retired_manifests) |r| if (std.mem.eql(u8, m, r.path)) return error.CurrentManifestCannotBeRetired;
    }
    for (c.protected_paths) |p| if (!relative(p)) return error.InvalidPolicy;
    for (c.retired_manifests) |p| if (!relative(p.path) or !hash(p.sha256)) return error.InvalidPolicy;
    for (c.retired_empty_log_records) |record| if (!relative(record.path) or !within("local-state/retirements", record.path) or !hash(record.sha256)) return error.InvalidPolicy;
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
