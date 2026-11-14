const std = @import("std");
const core = @import("engine.zig");
const u = @import("../validation/common.zig");
const fa = core.fa;
const D = std.Io.Dir;
pub const pending_path = "local-state/storage-cleanup/pending.json";

pub fn generatedAction(a: core.Action) bool {
    return a.kind == .generated_assembly or (a.kind == .build_output and std.mem.eql(u8, std.fs.path.basename(a.path), "capture-zllvm"));
}
pub fn fileAction(a: core.Action) bool {
    return a.snapshot == null and a.kind != .cache and a.kind != .temporary_workspace;
}
/// Keep complete inode groups together within the configured candidate budget.
/// The existing hard cap is 1024; minimal collection can use one admitted set.
pub fn fileBatch(e: *core.Engine, start: usize) ![]const usize {
    var indexes: std.ArrayList(usize) = .empty;
    const limit = @min(e.config.max_candidates, 1024);
    for (e.actions.items[start..], start..) |a, index| {
        if (a.status != .ready or !fileAction(a)) continue;
        if (std.mem.indexOfScalar(usize, indexes.items, index) != null) continue;
        const m = a.metadata orelse return error.CandidateChanged;
        const count = m.links;
        if (count > limit) return error.InvalidGeneratedBatch;
        if (indexes.items.len + count > limit) continue;
        if (count == 1) {
            try indexes.append(e.c.a, index);
        } else {
            for (e.actions.items, 0..) |other, other_index| {
                const om = other.metadata orelse continue;
                if (om.device == m.device and om.inode == m.inode) try indexes.append(e.c.a, other_index);
            }
        }
        if (indexes.items.len >= limit) break;
    }
    return indexes.items;
}
const GeneratedMove = struct {
    action_index: usize,
    path: []const u8,
    quarantine: []const u8,
    metadata: fa.Metadata,
    sha256: []const u8,
    parent_mode: u32,
};
fn syncDirectory(dir: D) !void {
    if (std.os.linux.errno(std.os.linux.fsync(dir.handle)) != .SUCCESS) return error.DirectorySyncFailed;
}
fn moveGenerated(e: *core.Engine, entry: GeneratedMove, restore: bool, did_move: ?*bool) !void {
    const original = try e.absolute(entry.path);
    var parent = try fa.metadata.openRoot(e.c.io, std.fs.path.dirname(original).?);
    defer parent.close(e.c.io);
    const mode = (try parent.stat(e.c.io)).permissions.toMode();
    if (mode != entry.parent_mode) return error.ParentPermissionsChanged;
    if (mode & 0o200 == 0) try parent.setPermissions(e.c.io, .fromMode(mode | 0o200));
    defer if (mode & 0o200 == 0) parent.setPermissions(e.c.io, .fromMode(mode)) catch {};
    const name = std.fs.path.basename(original);
    const qname = std.fs.path.basename(entry.quarantine);
    if (restore) try parent.renamePreserve(qname, parent, name, e.c.io) else {
        var expected = entry.metadata;
        if (expected.links > 1) expected.ctime_ns = (try fa.metadata.child(e.c.gpa, parent, name)).ctime_ns;
        try unchangedGenerated(e, parent, name, expected, e.actions.items[entry.action_index].sha256.?);
        try parent.renamePreserve(name, parent, qname, e.c.io);
    }
    if (did_move) |flag| flag.* = true;
    try syncDirectory(parent);
}

/// One explicitly inventoried generation, without deleting its mixed directory.
/// Quarantine every named file, refresh pins/consumers, then unlink exact files.
/// Before the first unlink any failure restores all names. An interruption or
/// partial unlink leaves the durable batch journal for explicit recovery.
pub fn applyGeneratedBatch(e: *core.Engine, indexes: []const usize) !void {
    if (indexes.len < 2 or indexes.len > 1024) return error.InvalidGeneratedBatch;
    for (indexes) |index| if (index >= e.actions.items.len) return error.InvalidGeneratedBatch;
    const scope = @import("generated.zig").consumerRoot(e.actions.items[indexes[0]].run_root);
    const first = e.actions.items[indexes[0]].metadata orelse return error.InvalidGeneratedBatch;
    const aliases = first.links > 1;
    for (indexes) |index| {
        const a = e.actions.items[index];
        if (!generatedAction(a) or (!aliases and !std.mem.eql(u8, scope, @import("generated.zig").consumerRoot(a.run_root)))) return error.InvalidGeneratedBatch;
    }
    return applyFileBatch(e, indexes);
}

/// A bounded set of fully qualified files, possibly from independent closed
/// runs. Every hardlink must be present and qualified within this transaction.
pub fn applyFileBatch(e: *core.Engine, indexes: []const usize) !void {
    if (indexes.len == 0 or indexes.len > 1024) return error.InvalidGeneratedBatch;
    for (indexes) |index| if (index >= e.actions.items.len) return error.InvalidGeneratedBatch;
    var entries: std.ArrayList(GeneratedMove) = .empty;
    try e.verifyBatchEvidence(indexes);
    for (indexes, 0..) |index, n| {
        for (indexes[0..n]) |old| if (old == index) return error.InvalidGeneratedBatch;
        const a = e.actions.items[index];
        if (a.status != .ready or !fileAction(a)) return error.InvalidGeneratedBatch;
        const observed = try e.metadata(a.path);
        if (!observed.eql(a.metadata.?) or observed.kind != .file) return error.CandidateChanged;
        if (observed.links > 1) {
            if (!e.aliasAllowed(a)) return error.InvalidGeneratedBatch;
            var count: usize = 0;
            for (indexes) |other_index| {
                const other = e.actions.items[other_index];
                const om = other.metadata orelse return error.InvalidGeneratedBatch;
                if (om.device != observed.device or om.inode != observed.inode) continue;
                if (!om.eql(observed) or !e.aliasAllowed(other) or other.sha256 == null or !std.mem.eql(u8, other.sha256.?, a.sha256.?)) return error.InvalidGeneratedBatch;
                count += 1;
            }
            if (count != observed.links) return error.InvalidGeneratedBatch;
        }
        const absolute = try e.absolute(a.path);
        var parent = try fa.metadata.openRoot(e.c.io, std.fs.path.dirname(absolute).?);
        defer parent.close(e.c.io);
        try unchangedGenerated(e, parent, std.fs.path.basename(absolute), observed, a.sha256.?);
        try entries.append(e.c.a, .{ .action_index = index, .path = a.path, .quarantine = try e.c.fmt("{s}/.storage-cleanup-{d}-{d}-{s}", .{ std.fs.path.dirname(a.path).?, std.os.linux.getpid(), index, std.fs.path.basename(a.path) }), .metadata = observed, .sha256 = a.sha256.?, .parent_mode = (try parent.stat(e.c.io)).permissions.toMode() });
    }
    // Reject an invalid accounting/order plan before moving or unlinking any
    // name, including callers that reorder a previously guarded alias group.
    for (entries.items, 0..) |entry, position| {
        var last = true;
        for (entries.items[position + 1 ..]) |later| if (later.metadata.device == entry.metadata.device and later.metadata.inode == entry.metadata.inode) {
            last = false;
        };
        const allocation: u64 = if (last) entry.metadata.allocated_bytes else 0;
        if (e.actions.items[entry.action_index].allocated_bytes != allocation) return error.AllocationMismatch;
    }
    try e.write(pending_path, .{ .schema = 1, .status = "pending", .kind = "file-batch", .output = e.output, .entries = entries.items });
    var moved: usize = 0;
    var deleting = false;
    errdefer if (!deleting) {
        var restored = true;
        while (moved > 0) {
            moved -= 1;
            moveGenerated(e, entries.items[moved], true, null) catch {
                restored = false;
            };
        }
        if (restored) D.cwd().deleteFile(e.c.io, e.absolute(pending_path) catch "") catch {};
    };
    for (entries.items) |entry| {
        var did_move = false;
        moveGenerated(e, entry, false, &did_move) catch |err| {
            if (did_move) moved += 1;
            return err;
        };
        moved += 1;
    }
    // No open descriptors in candidate directories remain during this refresh.
    // This also catches a newly introduced pin while names were quarantined.
    e.hash_cache.clearRetainingCapacity();
    try e.loadHolds();
    try e.pins();
    try e.consumers();
    try e.guardCaptureGroups();
    try e.verifyBatchEvidence(indexes);
    for (entries.items) |entry| {
        const a = e.actions.items[entry.action_index];
        if (a.status != .ready) return error.GeneratedBatchBecameHeld;
        const absolute = try e.absolute(entry.quarantine);
        var parent = try fa.metadata.openRoot(e.c.io, std.fs.path.dirname(absolute).?);
        defer parent.close(e.c.io);
        var expected = entry.metadata;
        expected.ctime_ns = (try fa.metadata.child(e.c.gpa, parent, std.fs.path.basename(absolute))).ctime_ns;
        try unchangedGenerated(e, parent, std.fs.path.basename(absolute), expected, a.sha256.?);
    }
    const journal = try u.files.createLog(e.c.io, .{ .path = try e.absolute(try e.c.fmt("{s}/actions.jsonl", .{e.output})), .truncate = false });
    defer journal.close(e.c.io);
    for (entries.items, 0..) |entry, position| {
        const a = &e.actions.items[entry.action_index];
        const absolute = try e.absolute(entry.quarantine);
        var parent = try fa.metadata.openRoot(e.c.io, std.fs.path.dirname(absolute).?);
        defer parent.close(e.c.io);
        const mode = (try parent.stat(e.c.io)).permissions.toMode();
        if (mode != entry.parent_mode) return error.ParentPermissionsChanged;
        const name = std.fs.path.basename(absolute);
        var expected = entry.metadata;
        for (entries.items[0..position]) |old| if (old.metadata.device == expected.device and old.metadata.inode == expected.inode) {
            expected.links -= 1;
        };
        expected.ctime_ns = (try fa.metadata.child(e.c.gpa, parent, name)).ctime_ns;
        try unchangedGenerated(e, parent, name, expected, a.sha256.?);
        if (mode & 0o200 == 0) try parent.setPermissions(e.c.io, .fromMode(mode | 0o200));
        defer if (mode & 0o200 == 0) parent.setPermissions(e.c.io, .fromMode(mode)) catch {};
        deleting = true;
        try parent.deleteFile(e.c.io, name);
        if (mode & 0o200 == 0) try parent.setPermissions(e.c.io, .fromMode(mode));
        if ((try parent.stat(e.c.io)).permissions.toMode() != mode) return error.ParentPermissionsChanged;
        try syncDirectory(parent);
        a.reclaimed_file_bytes = if (expected.links == 1) entry.metadata.allocated_bytes else 0;
        if (a.reclaimed_file_bytes != a.allocated_bytes) return error.AllocationMismatch;
        a.status = .removed;
        try journal.writeStreamingAll(e.c.io, try e.c.fmt("{{\"action\":{d},\"phase\":\"removed\",\"reclaimed_file_bytes\":{d}}}\n", .{ entry.action_index, a.reclaimed_file_bytes }));
        try journal.sync(e.c.io);
        try e.write(try e.c.fmt("{s}/record-{d}.json", .{ e.output, entry.action_index }), .{ .status = "complete", .action = a.*, .retained = a.retained });
    }
    try e.verifyBatchEvidence(indexes);
    try D.cwd().deleteFile(e.c.io, try e.absolute(pending_path));
}

fn unchangedGenerated(e: *core.Engine, parent: D, name: []const u8, expected: fa.Metadata, sha: []const u8) !void {
    const m = try fa.metadata.child(e.c.gpa, parent, name);
    if (!m.eql(expected) or m.kind != .file) return error.CandidateChanged;
    if (!std.mem.eql(u8, sha, &std.fmt.bytesToHex(try fa.metadata.hashFile(e.c.gpa, e.c.io, parent, name, m), .lower))) return error.CandidateHashChanged;
}

fn unchangedFile(e: *core.Engine, parent: D, name: []const u8, expected: fa.Metadata, sha: []const u8) !void {
    const m = try fa.metadata.child(e.c.gpa, parent, name);
    if (!m.eql(expected) or m.kind != .file or m.links != 1) return error.CandidateChanged;
    if (!std.mem.eql(u8, sha, &std.fmt.bytesToHex(try fa.metadata.hashFile(e.c.gpa, e.c.io, parent, name, m), .lower))) return error.CandidateHashChanged;
}
fn sameDirectory(a: fa.Metadata, b: fa.Metadata) bool {
    return a.kind == .directory and b.kind == .directory and a.device == b.device and a.inode == b.inode and a.mode == b.mode and a.uid == b.uid and a.gid == b.gid;
}
pub fn compareMoved(before: fa.Snapshot, after: fa.Snapshot) !void {
    if (before.entries.len != after.entries.len) return error.QuarantineMembershipChanged;
    for (before.entries, after.entries, 0..) |old, new, index| {
        var expected = old.metadata;
        if (index == 0) expected.ctime_ns = new.metadata.ctime_ns;
        if (!std.mem.eql(u8, old.path, new.path) or !expected.eql(new.metadata)) return error.QuarantineChanged;
        if (old.sha256) |h| if (new.sha256 == null or !std.mem.eql(u8, h, new.sha256.?)) return error.QuarantineHashChanged;
    }
}

// The pending record is durable before rename. A process interruption blocks a
// later invocation, leaving the exact scope and original names available for review.
pub fn apply(e: *core.Engine, index: usize) !void {
    const a = &e.actions.items[index];
    if (a.status != .ready) return error.NotReady;
    try e.verifyEvidence(a.*);
    const observed = try e.metadata(a.path);
    if (!observed.eql(a.metadata.?)) return error.CandidateChanged;
    const absolute = try e.absolute(a.path);
    var parent = try fa.metadata.openRoot(e.c.io, std.fs.path.dirname(absolute).?);
    defer parent.close(e.c.io);
    const name = std.fs.path.basename(absolute);
    const qname = try e.c.fmt(".storage-cleanup-{d}-{s}", .{ std.os.linux.getpid(), name });
    const quarantine = try e.c.fmt("{s}/{s}", .{ std.fs.path.dirname(a.path).?, qname });
    const mode = (try parent.stat(e.c.io)).permissions;
    const readonly = mode.toMode() & 0o200 == 0;
    if ((a.kind == .cache or a.kind == .temporary_workspace) and readonly) return error.FrozenCacheParent;
    var snapshot: ?std.json.Parsed(fa.Snapshot) = null;
    defer if (snapshot) |*s| s.deinit();
    if (a.snapshot) |s| {
        try e.check(s);
        const bytes = try e.read(e.c.gpa, s.path, 512 * 1024 * 1024);
        defer e.c.gpa.free(bytes);
        snapshot = try std.json.parseFromSlice(fa.Snapshot, e.c.gpa, bytes, .{ .allocate = .alloc_always });
        try fa.verify(e.c.gpa, e.c.io, snapshot.?.value);
    } else try unchangedFile(e, parent, name, observed, a.sha256.?);
    try e.write(pending_path, .{ .schema = 1, .status = "pending", .output = e.output, .action_index = index, .action = a.*, .quarantine = quarantine, .parent_mode = mode.toMode() & 0o7777 });
    var moved = false;
    var deleting = false;
    var finished = false;
    errdefer {
        // Before the first unlink, restore the original name on any failure.
        // After an unlink, leave a documented partial root quarantined.
        if (!deleting and !finished) {
            if (readonly) parent.setPermissions(e.c.io, .fromMode(mode.toMode() | 0o200)) catch {};
            if (moved) parent.renamePreserve(qname, parent, name, e.c.io) catch {};
            if (!moved or (u.exists(e.c.io, absolute) and !u.exists(e.c.io, e.absolute(quarantine) catch ""))) D.cwd().deleteFile(e.c.io, e.absolute(pending_path) catch "") catch {};
            if (readonly) parent.setPermissions(e.c.io, mode) catch {};
        }
    }
    if (readonly) try parent.setPermissions(e.c.io, .fromMode(mode.toMode() | 0o200));
    defer if (readonly) parent.setPermissions(e.c.io, mode) catch {};
    try parent.renamePreserve(name, parent, qname, e.c.io);
    moved = true;
    const journal_path = try e.c.fmt("{s}/actions.jsonl", .{e.output});
    const journal = try u.files.createLog(e.c.io, .{ .path = try e.absolute(journal_path), .truncate = false });
    defer journal.close(e.c.io);
    try journal.writeStreamingAll(e.c.io, try e.c.fmt("{{\"action\":{d},\"phase\":\"quarantined\"}}\n", .{index}));
    try journal.sync(e.c.io);
    if (snapshot) |s| {
        var after = try fa.scan(e.c.gpa, e.c.io, try e.absolute(quarantine), s.value.options);
        defer after.deinit();
        try compareMoved(s.value, after.value);
        try e.checkMounts(after.value);
        if (a.kind == .temporary_workspace) {
            // A large scratch tree can take time to rehash. Refresh its owner
            // decision and pins after quarantine, while rollback is still possible.
            try e.loadHolds();
            try e.pins();
            try e.consumers();
            if (a.status != .ready) return error.WorkspaceBecameHeld;
            try e.verifyEvidence(a.*);
        }
        // Delete exact inventoried entries. Never use a recursive wildcard;
        // unexpected membership makes final directory removal fail closed.
        for (after.value.entries) |entry| {
            if (entry.metadata.kind != .file) continue;
            const path = try std.fs.path.join(e.c.gpa, &.{ e.c.root, quarantine, entry.path });
            defer e.c.gpa.free(path);
            var d = try fa.metadata.openRoot(e.c.io, std.fs.path.dirname(path).?);
            defer d.close(e.c.io);
            const leaf = std.fs.path.basename(path);
            try unchangedFile(e, d, leaf, entry.metadata, entry.sha256.?);
            deleting = true;
            try d.deleteFile(e.c.io, leaf);
            a.reclaimed_file_bytes += entry.metadata.allocated_bytes;
        }
        var i = after.value.entries.len;
        while (i > 0) {
            i -= 1;
            const entry = after.value.entries[i];
            if (entry.metadata.kind != .directory) continue;
            const path = try std.fs.path.join(e.c.gpa, if (i == 0) &.{ e.c.root, quarantine } else &.{ e.c.root, quarantine, entry.path });
            defer e.c.gpa.free(path);
            var d = try fa.metadata.openRoot(e.c.io, std.fs.path.dirname(path).?);
            defer d.close(e.c.io);
            if (!sameDirectory(entry.metadata, try fa.metadata.child(e.c.gpa, d, std.fs.path.basename(path)))) return error.QuarantineDirectoryChanged;
            deleting = true;
            try d.deleteDir(e.c.io, std.fs.path.basename(path));
        }
    } else {
        const current = try fa.metadata.child(e.c.gpa, parent, qname);
        var expected = observed;
        expected.ctime_ns = current.ctime_ns;
        try unchangedFile(e, parent, qname, expected, a.sha256.?);
        deleting = true;
        try parent.deleteFile(e.c.io, qname);
        a.reclaimed_file_bytes = observed.allocated_bytes;
    }
    if (readonly) try parent.setPermissions(e.c.io, mode);
    if ((try parent.stat(e.c.io)).permissions.toMode() != mode.toMode()) return error.ParentPermissionsChanged;
    try e.verifyEvidence(a.*);
    if (a.reclaimed_file_bytes != a.allocated_bytes) return error.AllocationMismatch;
    a.status = .removed;
    try journal.writeStreamingAll(e.c.io, try e.c.fmt("{{\"action\":{d},\"phase\":\"removed\",\"reclaimed_file_bytes\":{d}}}\n", .{ index, a.reclaimed_file_bytes }));
    try journal.sync(e.c.io);
    try e.write(try e.c.fmt("{s}/record-{d}.json", .{ e.output, index }), .{ .status = "complete", .action = a.*, .retained = a.retained });
    try D.cwd().deleteFile(e.c.io, try e.absolute(pending_path));
    finished = true;
}
