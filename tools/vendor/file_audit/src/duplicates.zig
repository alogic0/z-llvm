const std = @import("std");
const snapshot = @import("snapshot.zig");

pub const Duplicate = struct {
    retain: []const u8,
    replace: []const u8,
    sha256: []const u8,
    reclaimable_bytes: u64,
    device: u64,
    mode: u32,
    uid: u32,
    gid: u32,
};
pub const Report = struct {
    schema: u32 = 1,
    root: []const u8,
    duplicate_paths: usize,
    reclaimable_bytes: u64,
    candidates: []const Duplicate,
    notice: []const u8 = "Read-only candidates. Equal SHA-256, size, device, mode and ownership; replacements have one link. Recheck content, metadata, active use and retention pins before mutation. Shared extents, open unlinked files and filesystem behavior can reduce actual reclaimed space.",
};
pub const Owned = struct {
    arena: std.heap.ArenaAllocator,
    value: Report,
    pub fn deinit(self: *Owned) void {
        self.arena.deinit();
        self.* = undefined;
    }
};
const Key = struct { sha256: [32]u8, size: u64, device: u64, mode: u32, uid: u32, gid: u32 };
fn key(entry: snapshot.Entry) !Key {
    const text = entry.sha256 orelse return error.MissingHash;
    if (text.len != 64) return error.InvalidHash;
    var bytes: [32]u8 = undefined;
    _ = std.fmt.hexToBytes(&bytes, text) catch return error.InvalidHash;
    const m = entry.metadata;
    return .{ .sha256 = bytes, .size = m.size, .device = m.device, .mode = m.mode, .uid = m.uid, .gid = m.gid };
}
fn prefer(a: snapshot.Entry, b: snapshot.Entry) bool {
    return a.metadata.links > b.metadata.links or (a.metadata.links == b.metadata.links and std.mem.lessThan(u8, a.path, b.path));
}
fn less(_: void, a: Duplicate, b: Duplicate) bool {
    return std.mem.lessThan(u8, a.replace, b.replace);
}

/// Groups by content AND ownership/permissions/device. Already shared inodes
/// are never savings, and multiply linked replacement inodes are not proposed.
/// The result owns its strings independently of the input snapshot.
pub fn find(allocator: std.mem.Allocator, value: snapshot.Snapshot) !Owned {
    if (value.schema != 1) return error.UnsupportedSchema;
    if (!value.options.hash_files) return error.HashesRequired;
    var arena = std.heap.ArenaAllocator.init(allocator);
    errdefer arena.deinit();
    const a = arena.allocator();
    var groups = std.AutoHashMap(Key, usize).init(a);
    var paths = std.StringHashMap(void).init(a);
    for (value.entries, 0..) |entry, i| {
        if (std.mem.eql(u8, entry.path, ".") and entry.metadata.kind != .directory) return error.InvalidPath;
        if (!std.mem.eql(u8, entry.path, ".") and !snapshot.validRelative(entry.path)) return error.InvalidPath;
        const seen = try paths.getOrPut(entry.path);
        if (seen.found_existing) return error.DuplicatePath;
        if (entry.metadata.kind != .file) continue;
        if (entry.metadata.links == 0) return error.UnlinkedFile;
        const g = try groups.getOrPut(try key(entry));
        if (!g.found_existing or prefer(entry, value.entries[g.value_ptr.*])) g.value_ptr.* = i;
    }
    var rows: std.ArrayList(Duplicate) = .empty;
    var total: u64 = 0;
    for (value.entries) |entry| {
        if (entry.metadata.kind != .file or entry.metadata.links != 1) continue;
        const canonical = value.entries[groups.get(try key(entry)).?];
        if (entry.metadata.inode == canonical.metadata.inode) continue;
        const m = entry.metadata;
        total = try std.math.add(u64, total, m.allocated_bytes);
        try rows.append(a, .{
            .retain = try a.dupe(u8, canonical.path),
            .replace = try a.dupe(u8, entry.path),
            .sha256 = try a.dupe(u8, entry.sha256.?),
            .reclaimable_bytes = m.allocated_bytes,
            .device = m.device,
            .mode = m.mode,
            .uid = m.uid,
            .gid = m.gid,
        });
    }
    std.mem.sort(Duplicate, rows.items, {}, less);
    return .{ .arena = arena, .value = .{
        .root = try a.dupe(u8, value.root),
        .duplicate_paths = rows.items.len,
        .reclaimable_bytes = total,
        .candidates = try rows.toOwnedSlice(a),
    } };
}
