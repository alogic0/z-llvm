//! Bounded private-cache/workspace transactions, with fresh guards after quarantine.
const std = @import("std");
const core = @import("engine.zig");
const mutation = @import("mutation.zig");
const u = @import("../validation/common.zig");
const fa = core.fa;
const D = std.Io.Dir;
// Many validation modes own tiny caches or empty workspaces. Bound the total
// snapshot files and bytes as well as roots, without repeating the global pin
// scan for every handful of directories.
const limit = 128;

pub fn accepts(a: core.Action) bool {
    return a.interrupted_workspace_recovery == null and (a.kind == .cache or a.kind == .temporary_workspace) and a.snapshot != null;
}

pub fn select(e: *core.Engine, start: usize) ![]const usize {
    var indexes: std.ArrayList(usize) = .empty;
    var bytes: u64 = 0;
    var files: usize = 0;
    for (e.actions.items[start..], start..) |a, index| {
        if (a.status != .ready or !accepts(a)) continue;
        if (indexes.items.len != 0 and (a.allocated_bytes > (1024 * 1024 * 1024) -| bytes or a.file_count > e.config.max_candidate_entries -| files)) continue;
        try indexes.append(e.c.a, index);
        bytes += a.allocated_bytes;
        files += a.file_count;
        if (indexes.items.len >= @min(limit, e.config.max_candidates)) break;
    }
    return indexes.items;
}
const Entry = struct {
    index: usize,
    path: []const u8,
    quarantine: []const u8,
    metadata: fa.Metadata,
    parent_mode: u32,
    before: std.json.Parsed(fa.Snapshot),
    after: ?fa.OwnedSnapshot = null,
};
fn move(e: *core.Engine, entry: Entry, restore: bool, moved: ?*bool) !void {
    var parent = try fa.metadata.openRoot(e.c.io, std.fs.path.dirname(try e.absolute(entry.path)).?);
    defer parent.close(e.c.io);
    if ((try parent.stat(e.c.io)).permissions.toMode() != entry.parent_mode) return error.ParentPermissionsChanged;
    const original = std.fs.path.basename(entry.path);
    const quarantine = std.fs.path.basename(entry.quarantine);
    if (!restore and !entry.metadata.eql(try fa.metadata.child(e.c.gpa, parent, original))) return error.CandidateChanged;
    if (restore) try parent.renamePreserve(quarantine, parent, original, e.c.io) else try parent.renamePreserve(original, parent, quarantine, e.c.io);
    if (moved) |flag| flag.* = true;
    try mutation.syncDirectory(parent);
}

pub fn apply(e: *core.Engine, indexes: []const usize) !void {
    if (indexes.len == 0 or indexes.len > limit) return error.InvalidCacheBatch;
    for (indexes, 0..) |index, i| {
        if (index >= e.actions.items.len) return error.InvalidCacheBatch;
        for (indexes[0..i]) |other| if (index == other) return error.InvalidCacheBatch;
    }
    try e.verifyBatchEvidence(indexes);
    var entries: std.ArrayList(Entry) = .empty;
    defer {
        for (entries.items) |*entry| {
            entry.before.deinit();
            if (entry.after) |*after| after.deinit();
        }
        entries.deinit(e.c.gpa);
    }
    for (indexes) |index| {
        const a = e.actions.items[index];
        if (!accepts(a) or a.status != .ready or a.metadata == null) return error.InvalidCacheBatch;
        const metadata = try e.metadata(a.path);
        if (!metadata.eql(a.metadata.?) or metadata.kind != .directory) return error.CandidateChanged;
        try e.check(a.snapshot.?);
        const bytes = try e.read(e.c.gpa, a.snapshot.?.path, 512 * 1024 * 1024);
        defer e.c.gpa.free(bytes);
        var before = try std.json.parseFromSlice(fa.Snapshot, e.c.gpa, bytes, .{ .allocate = .alloc_always });
        errdefer before.deinit();
        if (!std.mem.eql(u8, before.value.root, try e.absolute(a.path))) return error.InvalidCacheBatch;
        try e.checkCache(before.value);
        if (a.kind == .temporary_workspace) for (before.value.entries) |entry| {
            if (std.mem.eql(u8, std.fs.path.basename(entry.path), "profile.events.jsonl")) return error.WorkspaceContainsRawTrace;
        };
        try fa.verify(e.c.gpa, e.c.io, before.value);
        var allocation: u64 = 0;
        for (before.value.entries) |entry| if (entry.metadata.kind == .file) {
            allocation += entry.metadata.allocated_bytes;
        };
        if (allocation != a.allocated_bytes) return error.AllocationMismatch;
        var parent = try fa.metadata.openRoot(e.c.io, std.fs.path.dirname(try e.absolute(a.path)).?);
        defer parent.close(e.c.io);
        const mode = (try parent.stat(e.c.io)).permissions.toMode();
        if (mode & 0o200 == 0) return error.FrozenCacheParent;
        try entries.append(e.c.gpa, .{ .index = index, .path = a.path, .quarantine = try e.c.fmt("{s}/.storage-cleanup-{d}-{d}", .{ std.fs.path.dirname(a.path).?, std.os.linux.getpid(), index }), .metadata = metadata, .parent_mode = mode, .before = before });
    }
    const Pending = struct { action_index: usize, action: core.Action, quarantine: []const u8, parent_mode: u32 };
    var pending: std.ArrayList(Pending) = .empty;
    for (entries.items) |entry| try pending.append(e.c.a, .{ .action_index = entry.index, .action = e.actions.items[entry.index], .quarantine = entry.quarantine, .parent_mode = entry.parent_mode });
    try e.write(mutation.pending_path, .{ .schema = 1, .status = "pending", .kind = "cache-batch", .output = e.output, .entries = pending.items });
    var moved: usize = 0;
    var deleting = false;
    errdefer if (!deleting) {
        var restored = true;
        while (moved > 0) {
            moved -= 1;
            move(e, entries.items[moved], true, null) catch {
                restored = false;
            };
        }
        if (restored) D.cwd().deleteFile(e.c.io, e.absolute(mutation.pending_path) catch "") catch {};
    };
    for (entries.items) |entry| {
        var did_move = false;
        move(e, entry, false, &did_move) catch |err| {
            if (did_move) moved += 1;
            return err;
        };
        moved += 1;
    }
    for (entries.items) |*entry| {
        var after = try fa.scan(e.c.gpa, e.c.io, try e.absolute(entry.quarantine), entry.before.value.options);
        errdefer after.deinit();
        try mutation.compareMoved(entry.before.value, after.value);
        try e.checkMounts(after.value);
        entry.after = after;
    }
    e.hash_cache.clearRetainingCapacity();
    try e.loadHolds();
    try e.pins();
    try e.consumers();
    try e.verifyBatchEvidence(indexes);
    for (entries.items) |entry| {
        if (e.actions.items[entry.index].status != .ready) return error.CacheBatchBecameHeld;
        try fa.verify(e.c.gpa, e.c.io, entry.after.?.value);
    }
    const journal = try u.files.createLog(e.c.io, .{ .path = try e.absolute(try e.c.fmt("{s}/actions.jsonl", .{e.output})), .truncate = false });
    defer journal.close(e.c.io);
    for (entries.items) |entry| {
        const a = &e.actions.items[entry.index];
        for (entry.after.?.value.entries) |item| {
            if (item.metadata.kind != .file) continue;
            const path = try std.fs.path.join(e.c.gpa, &.{ e.c.root, entry.quarantine, item.path });
            defer e.c.gpa.free(path);
            var parent = try fa.metadata.openRoot(e.c.io, std.fs.path.dirname(path).?);
            defer parent.close(e.c.io);
            try mutation.unchangedFile(e, parent, std.fs.path.basename(path), item.metadata, item.sha256.?);
            deleting = true;
            try parent.deleteFile(e.c.io, std.fs.path.basename(path));
            a.reclaimed_file_bytes += item.metadata.allocated_bytes;
        }
        var i = entry.after.?.value.entries.len;
        while (i > 0) {
            i -= 1;
            const item = entry.after.?.value.entries[i];
            if (item.metadata.kind != .directory) continue;
            const path = try std.fs.path.join(e.c.gpa, if (i == 0) &.{ e.c.root, entry.quarantine } else &.{ e.c.root, entry.quarantine, item.path });
            defer e.c.gpa.free(path);
            var parent = try fa.metadata.openRoot(e.c.io, std.fs.path.dirname(path).?);
            defer parent.close(e.c.io);
            if (!mutation.sameDirectory(item.metadata, try fa.metadata.child(e.c.gpa, parent, std.fs.path.basename(path)))) return error.QuarantineDirectoryChanged;
            deleting = true;
            try parent.deleteDir(e.c.io, std.fs.path.basename(path));
        }
        var parent = try fa.metadata.openRoot(e.c.io, std.fs.path.dirname(try e.absolute(entry.path)).?);
        defer parent.close(e.c.io);
        if ((try parent.stat(e.c.io)).permissions.toMode() != entry.parent_mode) return error.ParentPermissionsChanged;
        try mutation.syncDirectory(parent);
        if (a.reclaimed_file_bytes != a.allocated_bytes) return error.AllocationMismatch;
        a.status = .removed;
        try journal.writeStreamingAll(e.c.io, try e.c.fmt("{{\"action\":{d},\"phase\":\"removed\",\"reclaimed_file_bytes\":{d}}}\n", .{ entry.index, a.reclaimed_file_bytes }));
        try journal.sync(e.c.io);
        try e.write(try e.c.fmt("{s}/record-{d}.json", .{ e.output, entry.index }), .{ .status = "complete", .action = a.*, .retained = a.retained });
    }
    try e.verifyBatchEvidence(indexes);
    try D.cwd().deleteFile(e.c.io, try e.absolute(mutation.pending_path));
}
