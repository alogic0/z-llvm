//! Explicitly narrow a reviewed closed run's manual hold around private caches.
//! Existing non-cache children remain held. This command never deletes payloads.
const std = @import("std");
const core = @import("engine.zig");
const p = core.p;

pub const Root = struct { path: []const u8, metadata: core.fa.Metadata, cache_paths: []const []const u8, retained_children: []const []const u8 };
pub const Proposal = struct { before: p.Evidence, after: p.Holds, roots: []const Root, actions: []const usize };

pub fn prepare(e: *core.Engine, roots_path: []const u8) !Proposal {
    if (!p.relative(roots_path)) return error.InvalidEvidencePath;
    try e.addControl(roots_path);
    try e.addControl(e.config.holds_file);
    var parsed = try e.load(e.c.gpa, e.config.holds_file);
    defer parsed.deinit();
    var holds = try std.json.parseFromValue(p.Holds, e.c.gpa, parsed.value, .{});
    defer holds.deinit();
    if (holds.value.schema != 1) return error.InvalidHolds;
    for (holds.value.paths) |path| if (!p.relative(path)) return error.InvalidHolds;
    const bytes = try e.read(e.c.gpa, roots_path, 1024 * 1024);
    defer e.c.gpa.free(bytes);
    var selected = std.StringHashMap(void).init(e.c.a);
    var lines = std.mem.tokenizeScalar(u8, bytes, '\n');
    var roots: std.ArrayList(Root) = .empty;
    var indexes: std.ArrayList(usize) = .empty;
    try @import("jobs.zig").scan(e, false);
    while (lines.next()) |run| {
        if (!p.candidate(run) or selected.contains(run) or selected.count() >= 1024) return error.InvalidHoldReview;
        var found = false;
        for (holds.value.paths) |path| if (std.mem.eql(u8, run, path)) {
            found = true;
            break;
        };
        if (!found) return error.HoldNotPresent;
        for (e.config.protected_paths) |path| if (p.overlaps(path, run)) return error.ProtectedCacheHold;
        for (e.held.items) |path| if (p.overlaps(path, run)) return error.ActiveJobCacheHold;
        const released = try e.c.fmt("{s}/storage-release.json", .{run});
        if (e.metadata(released)) |_| {
            var release = try e.load(e.c.gpa, released);
            defer release.deinit();
            if (core.eq(release.value, "state", "held")) return error.ActiveJobCacheHold;
        } else |err| if (err != error.FileNotFound) return err;
        const owned = try e.c.a.dupe(u8, run);
        try selected.put(owned, {});
        var parent = try core.fa.metadata.openRoot(e.c.io, try e.absolute(run));
        defer parent.close(e.c.io);
        var directory = try parent.openDir(e.c.io, ".", .{ .iterate = true, .follow_symlinks = false });
        defer directory.close(e.c.io);
        const metadata = try core.fa.metadata.descriptor(directory.handle);
        if (metadata.uid != std.os.linux.getuid()) return error.ForeignOwner;
        var cache_paths: std.ArrayList([]const u8) = .empty;
        var children: std.ArrayList([]const u8) = .empty;
        var entries = directory.iterate();
        while (try entries.next(e.c.io)) |entry| {
            const path = try e.c.fmt("{s}/{s}", .{ run, entry.name });
            if (!p.relative(path)) return error.InvalidHoldReview;
            const m = try core.fa.metadata.child(e.c.gpa, directory, entry.name);
            if (p.cacheOwned(run, path)) {
                if (m.kind != .directory) return error.CacheNotDirectory;
                const producer = try e.c.fmt("{s}/report.json", .{run});
                const index = try e.add(path, run, producer, .cache, null);
                var kept: std.ArrayList(p.Evidence) = .empty;
                try e.closedCache(e.actions.items[index], &kept);
                e.actions.items[index].retained = kept.items;
                e.actions.items[index].replay_required = false;
                try indexes.append(e.c.a, index);
                try cache_paths.append(e.c.a, path);
            } else try children.append(e.c.a, path);
        }
        if (cache_paths.items.len == 0 or children.items.len == 0) return error.NoClosedCacheHold;
        if (!metadata.eql(try core.fa.metadata.descriptor(directory.handle))) return error.HeldRootChanged;
        try roots.append(e.c.a, .{ .path = owned, .metadata = metadata, .cache_paths = cache_paths.items, .retained_children = children.items });
    }
    if (roots.items.len == 0) return error.InvalidHoldReview;
    try e.consumers();
    for (indexes.items) |index| if (e.actions.items[index].status == .skipped) return error.ActiveCacheConsumer;
    var after: std.ArrayList([]const u8) = .empty;
    for (holds.value.paths) |path| if (!selected.contains(path)) {
        try after.append(e.c.a, try e.c.a.dupe(u8, path));
    };
    for (roots.items) |root| try after.appendSlice(e.c.a, root.retained_children);
    std.mem.sort([]const u8, after.items, {}, struct {
        fn less(_: void, a: []const u8, b: []const u8) bool {
            return std.mem.lessThan(u8, a, b);
        }
    }.less);
    return .{ .before = .{ .path = e.config.holds_file, .sha256 = try e.digest(e.config.holds_file) }, .after = .{ .paths = after.items }, .roots = roots.items, .actions = indexes.items };
}

pub fn apply(e: *core.Engine, proposal: Proposal) !void {
    try e.verifyBatchEvidence(proposal.actions);
    try e.check(proposal.before);
    for (proposal.roots) |root| if (!root.metadata.eql(try e.metadata(root.path))) return error.HeldRootChanged;
    try e.consumers();
    for (proposal.actions) |index| if (e.actions.items[index].status == .skipped) return error.ActiveCacheConsumer;
    // The caller holds the exclusive storage lease. Keep the old document as
    // a durable receipt before the atomic replacement.
    var before = try e.load(e.c.gpa, proposal.before.path);
    defer before.deinit();
    try e.write(try e.c.fmt("{s}/holds-before.json", .{e.output}), before.value);
    try e.write(try e.c.fmt("{s}/holds-after.json", .{e.output}), proposal.after);
    try e.check(proposal.before);
    try e.write(proposal.before.path, proposal.after);
}

pub fn execute(e: *core.Engine, roots_path: []const u8, reason: []const u8, mutate: bool) !void {
    if (reason.len == 0) return error.InvalidHoldReview;
    const proposal = try prepare(e, roots_path);
    try e.write(try e.c.fmt("{s}/hold-review.json", .{e.output}), .{ .schema = "zllvm-cache-hold-review-v1", .reason = reason, .proposal = proposal });
    if (mutate) try apply(e, proposal);
    try e.write(try e.c.fmt("{s}/hold-change.json", .{e.output}), .{
        .status = if (mutate) "complete" else "reviewed",
        .reason = reason,
        .before = proposal.before,
        .after_sha256 = if (mutate) try e.c.digest(try e.absolute(proposal.before.path)) else null,
        .narrowed_roots = proposal.roots.len,
        .private_caches = proposal.actions.len,
        .scope = "Only the reviewed run-level manual holds were replaced by holds on every existing non-cache child. No payload was removed. Other holds, current pins and consumer checks still apply during collection.",
    });
    try e.c.print("{s} {d} run holds around {d} closed private caches; retained every other existing child.\n{s}/hold-review.json\n", .{ if (mutate) "Narrowed" else "Reviewed", proposal.roots.len, proposal.actions.len, e.output });
}
