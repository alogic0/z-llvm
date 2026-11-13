const std = @import("std");
const core = @import("engine.zig");
const u = @import("../validation/common.zig");
const fa = core.fa;
const D = std.Io.Dir;
pub const pending_path = "local-state/storage-cleanup/pending.json";

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
    if (a.kind == .cache and readonly) return error.FrozenCacheParent;
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
