//! Evidence-based project storage collection; see docs/storage_cleanup.md.
const std = @import("std");
const u = @import("validation/common.zig");
const core = @import("storage_cleanup/engine.zig");
const mutation = @import("storage_cleanup/mutation.zig");
const p = core.p;
const usage =
    \\usage: tools/clean-storage [--apply] [--policy FILE]
    \\       tools/clean-storage exec -- COMMAND [ARG...]
    \\
    \\Without --apply, writes a review with reasons and makes no artifact changes.
    \\--apply discovers again and collects eligible completed private caches and
    \\explicitly released artifacts. Unknown or pinned files are retained.
    \\Policy defaults to docs/storage_cleanup_policy.json. JSON reports are saved
    \\under local-state/retirements/automatic-storage-cleanup/.
    \\Use exec for builds/readers to hold the shared cleanup lock. Add queued
    \\work to local-state/storage-cleanup/holds.json before starting it.
    \\
;
pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    errdefer if (c.diagnostic) |d| c.print("{s}\n", .{d}) catch {};
    const args = try init.minimal.args.toSlice(c.a);
    var apply = false;
    var policy_path: []const u8 = "docs/storage_cleanup_policy.json";
    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        if (std.mem.eql(u8, args[i], "--help")) return c.print("{s}", .{usage});
        if (std.mem.eql(u8, args[i], "--apply")) {
            apply = true;
            continue;
        }
        if (std.mem.eql(u8, args[i], "--policy") and i + 1 < args.len) {
            i += 1;
            policy_path = args[i];
            continue;
        }
        return error.UnknownArgument;
    }
    if (!p.relative(policy_path)) return error.InvalidPolicyPath;
    const policy_absolute = try c.join(&.{policy_path});
    var policy_dir = try core.fa.metadata.openRoot(c.io, std.fs.path.dirname(policy_absolute).?);
    defer policy_dir.close(c.io);
    const policy_name = std.fs.path.basename(policy_absolute);
    const policy_metadata = try core.fa.metadata.child(c.gpa, policy_dir, policy_name);
    const bytes = try core.fa.metadata.readFile(c.gpa, c.io, policy_dir, policy_name, policy_metadata, 1024 * 1024);
    defer c.gpa.free(bytes);
    const policy_sha256 = try u.digestBytes(c.a, bytes);
    const config = try std.json.parseFromSlice(p.Config, c.a, bytes, .{});
    try p.validate(config.value);
    const state = "local-state/storage-cleanup";
    try std.Io.Dir.cwd().createDirPath(c.io, try c.join(&.{state}));
    var state_dir = try core.fa.metadata.openRoot(c.io, try c.join(&.{state}));
    defer state_dir.close(c.io);
    const lock = try state_dir.createFile(c.io, "cleanup.lock", .{ .truncate = false });
    defer lock.close(c.io);
    if (!try lock.tryLock(c.io, .exclusive)) return c.fail("Cleanup skipped: another collector or a reader/build holds the storage lock.", .{});
    defer lock.unlock(c.io);
    if (u.exists(c.io, try c.join(&.{mutation.pending_path}))) return c.fail("An interrupted cleanup needs review: {s}. No new deletion attempted.", .{mutation.pending_path});
    const output = try c.fmt("local-state/retirements/automatic-storage-cleanup/{d}-{d}", .{ std.Io.Clock.real.now(c.io).nanoseconds, std.os.linux.getpid() });
    _ = try c.newOutput(output);
    const zigrep = c.env.get("ZIGREP") orelse "zigrep";
    var e = core.Engine.init(&c, config.value, output, zigrep);
    e.collector_binary_sha256 = try c.digest("/proc/self/exe");
    e.collector_sources = try collectorSources(&c);
    var status: []const u8 = "failed";
    defer report(&e, status, apply) catch {};
    try e.check(.{ .path = policy_path, .sha256 = policy_sha256 });
    try e.addControl(policy_path);
    try c.print("Discovering completed runs and release records...\n", .{});
    try e.discover();
    try e.loadHolds();
    try c.print("Checking retention pins for {d} candidates...\n", .{e.actions.items.len});
    try e.pins();
    try c.print("Verifying {d} required integrity manifests...\n", .{config.value.current_manifests.len});
    try e.currentManifests(true);
    try c.print("Checking active consumers and retained source/build evidence...\n", .{});
    try e.consumers();
    var admitted: usize = 0;
    var total: u64 = 0;
    for (e.actions.items, 0..) |*a, index| {
        if (a.status != .discovered) continue;
        if (admitted >= config.value.max_candidates) {
            a.status = .skipped;
            a.reason = "per-run candidate limit";
            continue;
        }
        e.qualify(index) catch |err| {
            a.status = .skipped;
            a.reason = try c.fmt("{s}", .{@errorName(err)});
            continue;
        };
        if (total + a.allocated_bytes > config.value.max_reclaim_bytes) {
            a.status = .skipped;
            a.reason = "per-run allocated-byte limit";
            continue;
        }
        total += a.allocated_bytes;
        admitted += 1;
        try c.print("Eligible: {s} ({d} file bytes)\n", .{ a.path, a.allocated_bytes });
    }
    // Any retained evidence wins over any other action, independent of order.
    for (e.actions.items) |*a| {
        if (a.status != .ready) continue;
        for (e.actions.items) |other| for (other.retained) |ev| if (p.overlaps(try e.absolute(a.path), try e.absolute(ev.path))) {
            a.status = .skipped;
            a.reason = "retained evidence of another candidate";
        };
    }
    try report(&e, "reviewed", apply);
    if (apply) {
        try e.pinRevisions();
        for (e.actions.items, 0..) |*a, index| {
            if (a.status != .ready) continue;
            // Refresh consumers and pins immediately before each owned mutation.
            e.hash_cache.clearRetainingCapacity();
            try e.loadHolds();
            try e.pins();
            try e.consumers();
            if (a.status != .ready) continue;
            try mutation.apply(&e, index);
            try report(&e, "applying", apply);
            try c.print("Removed: {s} ({d} allocated file bytes)\n", .{ a.path, a.reclaimed_file_bytes });
        }
        e.hash_cache.clearRetainingCapacity();
        try e.currentManifests(true);
        for (e.controls.items) |row| try e.check(row);
    }
    try e.compactSnapshots();
    status = "complete";
    try report(&e, status, apply);
    var ready: usize = 0;
    var kept: usize = 0;
    var removed: usize = 0;
    var reclaimed: u64 = 0;
    for (e.actions.items) |a| switch (a.status) {
        .ready => ready += 1,
        .skipped => kept += 1,
        .removed => {
            removed += 1;
            reclaimed += a.reclaimed_file_bytes;
        },
        else => {},
    };
    try c.print("Eligible: {d}; kept: {d}; removed: {d}; reclaimed allocated file bytes: {d}\n", .{ ready, kept, removed, reclaimed });
    try c.print("{s}: {s}/report.json\n", .{ if (apply) "Cleanup complete" else "Review complete", output });
}
fn report(e: *core.Engine, status: []const u8, apply: bool) !void {
    var ready: usize = 0;
    var skipped: usize = 0;
    var removed: usize = 0;
    var proposed: u64 = 0;
    var reclaimed: u64 = 0;
    for (e.actions.items) |a| {
        switch (a.status) {
            .ready => {
                ready += 1;
                proposed += a.allocated_bytes;
            },
            .skipped => skipped += 1,
            .removed => {
                removed += 1;
                reclaimed += a.reclaimed_file_bytes;
            },
            else => {},
        }
    }
    try e.write(try e.c.fmt("{s}/report.json", .{e.output}), .{ .schema = "zllvm-storage-cleanup-v1", .status = status, .mode = if (apply) "apply" else "review", .ready = ready, .skipped = skipped, .removed = removed, .proposed_allocated_file_bytes = proposed, .reclaimed_allocated_file_bytes = reclaimed, .producer_reports = e.producer_reports, .release_records = e.released_records, .pin_files_checked = e.checked_manifests, .collector = .{ .binary_sha256 = e.collector_binary_sha256, .zig_version = @import("builtin").zig_version_string, .compiled_sources = e.collector_sources }, .source_revisions = e.revisions.items, .controls = e.controls.items, .actions = e.actions.items });
}
fn collectorSources(c: *u.Context) ![]const core.Evidence {
    const Source = struct { path: []const u8, bytes: []const u8 };
    const files = [_]Source{
        .{ .path = "tools/clean_storage.zig", .bytes = @embedFile("clean_storage.zig") },
        .{ .path = "tools/storage_cleanup/engine.zig", .bytes = @embedFile("storage_cleanup/engine.zig") },
        .{ .path = "tools/storage_cleanup/mutation.zig", .bytes = @embedFile("storage_cleanup/mutation.zig") },
        .{ .path = "tools/storage_cleanup/policy.zig", .bytes = @embedFile("storage_cleanup/policy.zig") },
        .{ .path = "tools/validation/common.zig", .bytes = @embedFile("validation/common.zig") },
        .{ .path = "tools/vendor/file_audit.SHA256SUMS", .bytes = @embedFile("vendor/file_audit.SHA256SUMS") },
        .{ .path = "tools/vendor/process.SHA256SUMS", .bytes = @embedFile("vendor/process.SHA256SUMS") },
        .{ .path = "tools/vendor/test_support.SHA256SUMS", .bytes = @embedFile("vendor/test_support.SHA256SUMS") },
    };
    var result: std.ArrayList(core.Evidence) = .empty;
    for (files) |file| try result.append(c.a, .{ .path = file.path, .sha256 = try u.digestBytes(c.a, file.bytes) });
    return result.toOwnedSlice(c.a);
}
comptime {
    if (@import("builtin").is_test) _ = @import("storage_cleanup/tests.zig");
}
