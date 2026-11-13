//! Explicit migration of complete IR inode groups to immutable shared storage.
//! Names and bytes remain available; only redundant allocated data is retired.
const std = @import("std");
const core = @import("engine.zig");
const p = core.p;
const fa = core.fa;
const storage = @import("../zllvm_artifact_store/store.zig");
const mutation = @import("mutation.zig");
const D = std.Io.Dir;
pub const Family = struct { sha256: []const u8, paths: []const []const u8 };
pub const Plan = struct { schema: []const u8 = "zllvm-shared-inputs-v1", inputs: []const Family };
const Group = struct { metadata: fa.Metadata, sha256: []const u8, indexes: std.ArrayList(usize) = .empty, status: []const u8 = "review", reclaimed_file_bytes: u64 = 0 };
const Move = struct { path: []const u8, backup: []const u8, temporary: []const u8, parent_mode: u32 };

fn original(e: *core.Engine, path: []const u8, expected: fa.Metadata, hash: []const u8, changed_links: bool) !void {
    const m = try e.metadata(path);
    var want = expected;
    if (changed_links) {
        want.links = m.links;
        want.ctime_ns = m.ctime_ns;
    }
    if (!m.eql(want) or m.kind != .file or m.uid != std.os.linux.getuid()) return error.SharedInputChanged;
    if (!std.mem.eql(u8, try e.digest(path), hash)) return error.SharedInputHashChanged;
}

fn writable(e: *core.Engine, row: Move) !D {
    var dir = try fa.metadata.openRoot(e.c.io, try e.absolute(std.fs.path.dirname(row.path).?));
    errdefer dir.close(e.c.io);
    if ((try dir.stat(e.c.io)).permissions.toMode() != row.parent_mode) return error.ParentPermissionsChanged;
    if (row.parent_mode & 0o200 == 0) try dir.setPermissions(e.c.io, .fromMode(row.parent_mode | 0o200));
    return dir;
}
fn closeParent(e: *core.Engine, dir: D, row: Move) void {
    if (row.parent_mode & 0o200 == 0) dir.setPermissions(e.c.io, .fromMode(row.parent_mode)) catch {};
    dir.close(e.c.io);
}

pub fn migrate(e: *core.Engine, store: *storage.Store, indexes: []const usize, metadata: fa.Metadata, hash: []const u8) !u64 {
    if (indexes.len == 0 or indexes.len != metadata.links) return error.IncompleteInputAliases;
    var moves: std.ArrayList(Move) = .empty;
    for (indexes) |index| {
        const a = e.actions.items[index];
        if (a.status != .ready) return error.SharedInputHeld;
        try original(e, a.path, metadata, hash, false);
        var parent = try fa.metadata.openRoot(e.c.io, try e.absolute(std.fs.path.dirname(a.path).?));
        defer parent.close(e.c.io);
        const prefix = try e.c.fmt("{s}/.shared-input-{d}-{d}", .{ std.fs.path.dirname(a.path).?, std.os.linux.getpid(), index });
        const row: Move = .{ .path = a.path, .backup = try e.c.fmt("{s}.old", .{prefix}), .temporary = try e.c.fmt("{s}.new", .{prefix}), .parent_mode = (try parent.stat(e.c.io)).permissions.toMode() };
        for ([_][]const u8{ row.backup, row.temporary }) |path| {
            if (e.metadata(path)) |_| return error.SharedInputJournalCollision else |err| if (err != error.FileNotFound) return err;
        }
        try moves.append(e.c.a, row);
    }
    try e.write(mutation.pending_path, .{ .schema = 1, .kind = "shared-input", .output = e.output, .sha256 = hash, .metadata = metadata, .moves = moves.items });
    var deleting = false;
    errdefer if (!deleting) {
        var restored = true;
        for (moves.items) |row| {
            var dir = writable(e, row) catch {
                restored = false;
                continue;
            };
            defer closeParent(e, dir, row);
            if (e.metadata(row.backup)) |_| {
                dir.rename(std.fs.path.basename(row.backup), dir, std.fs.path.basename(row.path), e.c.io) catch {
                    restored = false;
                    continue; // The backup may now be the only old-content name.
                };
                // rename of two names for the same inode is a no-op.
                dir.deleteFile(e.c.io, std.fs.path.basename(row.backup)) catch |err| {
                    if (err != error.FileNotFound) restored = false;
                };
            } else |err| {
                if (err != error.FileNotFound) restored = false;
            }
            dir.deleteFile(e.c.io, std.fs.path.basename(row.temporary)) catch |err| {
                if (err != error.FileNotFound) restored = false;
            };
            storage.syncDir(dir) catch {
                restored = false;
            };
        }
        if (restored) D.cwd().deleteFile(e.c.io, e.absolute(mutation.pending_path) catch "") catch {};
    };
    for (moves.items) |row| {
        var parent = try writable(e, row);
        defer closeParent(e, parent, row);
        try original(e, row.path, metadata, hash, true);
        const file = try parent.openFile(e.c.io, std.fs.path.basename(row.path), .{ .follow_symlinks = false });
        defer file.close(e.c.io);
        try file.hardLink(e.c.io, parent, std.fs.path.basename(row.backup), .{});
        try store.linkInput(hash, try e.absolute(row.temporary));
        try parent.rename(std.fs.path.basename(row.temporary), parent, std.fs.path.basename(row.path), e.c.io);
        try storage.syncDir(parent);
    }
    // All old names are now durable read-only aliases; old data is still in
    // backups. No descriptors remain in consumer directories during refresh.
    try e.loadHolds();
    try e.consumers();
    for (indexes) |index| if (e.actions.items[index].status != .ready) return error.SharedInputHeld;
    for (e.controls.items) |control| try e.check(control);
    // The outer migration verifies all current targets before and after the
    // batch. Here, recheck their control files and each replaced input's bytes.
    try e.currentManifests(false);
    const stored = try store.objects.statFile(e.c.io, hash, .{});
    for (moves.items) |row| {
        try original(e, row.backup, metadata, hash, true);
        const old = try e.metadata(row.backup);
        if (old.links != metadata.links) return error.InputAliasesChanged;
        const current = try e.metadata(row.path);
        if (current.inode != stored.inode or current.mode & 0o222 != 0 or !std.mem.eql(u8, try e.digest(row.path), hash)) return error.SharedInputChanged;
    }
    deleting = true;
    for (moves.items, 0..) |row, n| {
        const parent = try writable(e, row);
        defer closeParent(e, parent, row);
        try original(e, row.backup, metadata, hash, true);
        if ((try e.metadata(row.backup)).links != metadata.links - n) return error.InputAliasesChanged;
        try parent.deleteFile(e.c.io, std.fs.path.basename(row.backup));
        try storage.syncDir(parent);
    }
    for (moves.items) |row| {
        var parent = try fa.metadata.openRoot(e.c.io, try e.absolute(std.fs.path.dirname(row.path).?));
        defer parent.close(e.c.io);
        if ((try parent.stat(e.c.io)).permissions.toMode() != row.parent_mode) return error.ParentPermissionsChanged;
    }
    try e.write(try e.c.fmt("{s}/shared-input-{d}.json", .{ e.output, metadata.inode }), .{ .status = "complete", .sha256 = hash, .old_metadata = metadata, .moves = moves.items, .reclaimed_file_bytes = metadata.allocated_bytes });
    try D.cwd().deleteFile(e.c.io, try e.absolute(mutation.pending_path));
    return metadata.allocated_bytes;
}

pub fn run(e: *core.Engine, plan_path: []const u8, apply: bool) !void {
    if (!p.relative(plan_path)) return error.InvalidEvidencePath;
    try e.addControl(plan_path);
    var parsed = try e.load(e.c.gpa, plan_path);
    defer parsed.deinit();
    var plan = try std.json.parseFromValue(Plan, e.c.gpa, parsed.value, .{});
    defer plan.deinit();
    if (!std.mem.eql(u8, plan.value.schema, "zllvm-shared-inputs-v1") or plan.value.inputs.len == 0) return error.InvalidSharedInputPlan;
    var groups: std.ArrayList(Group) = .empty;
    var seen = std.StringHashMap(void).init(e.c.a);
    for (plan.value.inputs) |family| {
        if (!p.hash(family.sha256)) return error.InvalidSharedInputPlan;
        for (family.paths) |path| {
            if (seen.count() >= 2048 or !p.candidate(path) or !std.mem.endsWith(u8, path, ".ll") or seen.contains(path)) return error.InvalidSharedInputPlan;
            try seen.put(path, {});
            const m = try e.metadata(path);
            if (m.kind != .file or m.uid != std.os.linux.getuid() or m.mode & 0o111 != 0) return error.InvalidSharedInput;
            if (!std.mem.eql(u8, try e.digest(path), family.sha256)) return error.SharedInputHashChanged;
            var group_index: ?usize = null;
            for (groups.items, 0..) |g, index| if (g.metadata.device == m.device and g.metadata.inode == m.inode) {
                group_index = index;
                break;
            };
            if (group_index == null) {
                group_index = groups.items.len;
                try groups.append(e.c.a, .{ .metadata = m, .sha256 = try e.c.a.dupe(u8, family.sha256) });
            }
            const index = e.actions.items.len;
            try e.actions.append(e.c.a, .{ .path = try e.c.a.dupe(u8, path), .run_root = try e.c.a.dupe(u8, @import("inventory.zig").runRoot(path)), .producer = plan_path, .kind = .build_output, .status = .ready, .sha256 = groups.items[group_index.?].sha256, .metadata = m });
            try groups.items[group_index.?].indexes.append(e.c.a, index);
        }
    }
    try e.loadHolds();
    try e.consumers();
    try e.currentManifests(true);
    var status: []const u8 = "failed";
    var reclaimed: u64 = 0;
    var created: u64 = 0;
    const report_path = try e.c.fmt("{s}/shared-input-review.json", .{e.output});
    defer e.write(report_path, .{ .status = status, .apply = apply, .groups = groups.items, .paths = e.actions.items, .removed_allocated_file_bytes = reclaimed, .created_object_allocated_bytes = created, .net_reclaimed_bytes = @as(i128, reclaimed) - created }) catch {};
    for (groups.items) |*g| {
        const object_path = try e.c.fmt("local-state/artifacts/objects/{s}", .{g.sha256});
        const stored = e.metadata(object_path) catch |err| switch (err) {
            error.FileNotFound => null,
            else => return err,
        };
        if (stored) |m| if (m.device == g.metadata.device and m.inode == g.metadata.inode) {
            g.status = "already-shared";
            continue;
        };
        if (g.indexes.items.len != g.metadata.links) {
            g.status = "incomplete-alias-group";
            continue;
        }
        var held = false;
        for (g.indexes.items) |i| if (e.actions.items[i].status != .ready) {
            held = true;
        };
        if (held) {
            g.status = "held";
            continue;
        }
        g.status = "eligible";
        if (!apply) continue;
        var store = try storage.Store.open(e.c.a, e.c.io, try e.absolute("local-state/artifacts"), true);
        defer store.deinit();
        {
            const source = try D.cwd().openFile(e.c.io, try e.absolute(e.actions.items[g.indexes.items[0]].path), .{ .follow_symlinks = false });
            defer source.close(e.c.io);
            try store.publishFile(source, .{ .name = "input.ll", .sha256 = g.sha256, .bytes = g.metadata.size });
        }
        if (stored == null) created += (try e.metadata(object_path)).allocated_bytes;
        g.reclaimed_file_bytes = try migrate(e, &store, g.indexes.items, g.metadata, g.sha256);
        reclaimed += g.reclaimed_file_bytes;
        g.status = "shared";
    }
    try e.currentManifests(true);
    status = "complete";
    try e.c.print("Shared input {s}: removed {d} allocated bytes; created {d} object bytes.\n{s}/shared-input-review.json\n", .{ if (apply) "migration" else "review", reclaimed, created, e.output });
}
