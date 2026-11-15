//! Explicit migration of complete IR/AIR inode groups to immutable shared storage.
//! Names and bytes remain available; only redundant allocated data is retired.
const std = @import("std");
const core = @import("engine.zig");
const p = core.p;
const fa = core.fa;
const storage = @import("../zllvm_artifact_store/store.zig");
const mutation = @import("mutation.zig");
const D = std.Io.Dir;
pub const Family = struct { sha256: []const u8, paths: []const []const u8 };
pub const SharingHolds = struct { manifest: p.Evidence, paths: []const []const u8 };
pub const Plan = struct {
    schema: []const u8 = "zllvm-shared-inputs-v1",
    inputs: []const Family,
    review: ?p.Evidence = null,
    reason: ?[]const u8 = null,
    // Explicit permission to replace only the inode backing an immutable view.
    // These manual holds remain in force in the stored hold file after sharing.
    sharing_holds: ?SharingHolds = null,
};
const Group = struct { metadata: fa.Metadata, sha256: []const u8, indexes: std.ArrayList(usize) = .empty, status: []const u8 = "review", reclaimed_file_bytes: u64 = 0 };
const Move = struct { path: []const u8, backup: []const u8, temporary: []const u8, parent_mode: u32, group: usize };
pub const Migration = struct { indexes: []const usize, metadata: fa.Metadata, sha256: []const u8 };
// Small evidence files otherwise repeat the global consumer snapshot thousands
// of times. Keep the transaction bounded while amortizing that fixed cost.
pub const max_batch_inodes = 4096;

pub fn scope(path: []const u8) bool {
    if (!p.relative(path) or !(std.mem.endsWith(u8, path, ".ll") or std.mem.endsWith(u8, path, ".air"))) return false;
    return p.validationOutput(path) or std.mem.startsWith(u8, path, "local-state/inputs/") or
        std.mem.startsWith(u8, path, "local-state/caches/");
}

/// Completed immutable evidence may share contents only through a separate
/// hash-bound review. Compiled products, raw traces and arbitrary files do not
/// gain admission from their descriptive role in that review.
pub fn evidenceScope(path: []const u8) bool {
    if (scope(path)) return true;
    if (!p.relative(path) or !(p.validationOutput(path) or p.within("local-state/retirements", path))) return false;
    if (std.mem.eql(u8, std.fs.path.basename(path), "profile.events.jsonl")) return false;
    const extension = std.fs.path.extension(path);
    for ([_][]const u8{ ".json", ".jsonl", ".ndjson", ".sha256", ".log", ".stdout", ".stderr", ".tsv", ".md", ".txt", ".zig", ".c", ".h", ".cpp", ".S" }) |allowed| {
        if (std.mem.eql(u8, extension, allowed)) return true;
    }
    return false;
}

/// Only generic policy roots are excepted for this byte-preserving operation.
/// An explicit hold, queued job or more specific policy entry still wins.
pub fn genericPolicyRoot(path: []const u8) bool {
    return std.mem.eql(u8, path, "local-state/inputs") or std.mem.eql(u8, path, "local-state/caches");
}

/// Older validation trees omit the batch level. Inventory bucket depth is not
/// a consumer boundary: a queued parent job may not yet have opened its input.
pub fn consumerRoot(path: []const u8) []const u8 {
    var parts = std.mem.splitScalar(u8, path, '/');
    for (0..3) |_| _ = parts.next() orelse return path;
    const family_end = parts.index orelse return std.fs.path.dirname(path) orelse path;
    if (!std.mem.startsWith(u8, path, "local-state/validations/")) return path[0 .. family_end - 1];
    const fourth = parts.next() orelse return path;
    if (parts.index == null) return path[0 .. family_end - 1];
    if (std.mem.eql(u8, fourth, "batch") or std.mem.startsWith(u8, fourth, "batch-")) _ = parts.next() orelse return path;
    const end = parts.index orelse return path;
    return path[0 .. end - 1];
}

fn original(e: *core.Engine, path: []const u8, expected: fa.Metadata, hash: []const u8, changed_links: bool) !void {
    const m = try e.metadata(path);
    var want = expected;
    if (changed_links) {
        want.links = m.links;
        want.ctime_ns = m.ctime_ns;
    }
    if (!m.eql(want) or m.kind != .file or m.uid != std.os.linux.getuid()) return error.SharedInputChanged;
    // Our backup hardlinks deliberately change ctime/link counts. Verify these
    // exact old bytes directly instead of relaxing parsed pathname observations.
    if (changed_links) {
        var parent = try fa.metadata.openRoot(e.c.io, try e.absolute(std.fs.path.dirname(path).?));
        defer parent.close(e.c.io);
        const actual = std.fmt.bytesToHex(try fa.metadata.hashFile(e.c.gpa, e.c.io, parent, std.fs.path.basename(path), m), .lower);
        if (!std.mem.eql(u8, &actual, hash)) return error.SharedInputHashChanged;
    } else if (!std.mem.eql(u8, try e.digest(path), hash)) return error.SharedInputHashChanged;
}

/// Rebind only the exact inode changes performed by this byte-preserving
/// transaction. Parsed contents/hashes stay identical; unrelated observations
/// keep their strict identity check. Existing aliases of the destination object
/// may change only link count and ctime as we install more names.
fn rebindObservations(e: *core.Engine, moves: []const Move, groups: []const Migration) !void {
    var replacements = std.StringHashMap(usize).init(e.c.a);
    var destinations = std.AutoHashMap(fa.metadata.Identity, []const u8).init(e.c.a);
    const objects = try e.c.a.alloc(fa.Metadata, groups.len);
    for (groups, 0..) |group, i| {
        objects[i] = try e.metadata(try e.c.fmt("local-state/artifacts/objects/{s}", .{group.sha256}));
        try destinations.put(fa.metadata.identity(objects[i]), group.sha256);
    }
    for (moves) |row| try replacements.put(try e.absolute(row.path), row.group);
    var observations = e.observed_reads.iterator();
    while (observations.next()) |entry| {
        const before = entry.value_ptr.*;
        const after = try e.metadata(entry.key_ptr.*);
        if (before.metadata.eql(after)) continue;
        if (replacements.get(entry.key_ptr.*)) |i| {
            if (!after.eql(objects[i]) or !std.mem.eql(u8, before.sha256, groups[i].sha256)) return error.FileChanged;
        } else if (destinations.get(fa.metadata.identity(before.metadata))) |hash| {
            var expected = before.metadata;
            expected.links = after.links;
            expected.ctime_ns = after.ctime_ns;
            if (!expected.eql(after) or after.links < before.metadata.links or !std.mem.eql(u8, before.sha256, hash)) return error.FileChanged;
        } else return error.FileChanged;
        var parent = try fa.metadata.openRoot(e.c.io, std.fs.path.dirname(entry.key_ptr.*).?);
        defer parent.close(e.c.io);
        const hash = std.fmt.bytesToHex(try fa.metadata.hashFile(e.c.gpa, e.c.io, parent, std.fs.path.basename(entry.key_ptr.*), after), .lower);
        if (!std.mem.eql(u8, &hash, before.sha256)) return error.FileChanged;
        entry.value_ptr.metadata = after;
        try e.hash_cache.put(fa.metadata.identity(after), .{ .metadata = after, .sha256 = before.sha256 });
    }
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
    return migrateBatch(e, store, &.{.{ .indexes = indexes, .metadata = metadata, .sha256 = hash }});
}

fn refreshBatch(e: *core.Engine, groups: []const Migration) !void {
    const all = e.actions;
    var selected: std.ArrayList(core.Action) = .empty;
    for (groups) |group| for (group.indexes) |index| {
        try selected.append(e.c.a, all.items[index]);
    };
    e.actions = selected;
    defer {
        var n: usize = 0;
        for (groups) |group| for (group.indexes) |index| {
            all.items[index] = e.actions.items[n];
            n += 1;
        };
        e.actions = all;
    }
    // Refresh the same global job/hold/process sources, but compare only the
    // names whose backups are in this transaction. Other groups refresh again
    // before their own old contents can be removed.
    try e.loadHolds();
    try e.consumers();
}

/// Keep every old inode in durable backups until one fresh consumer/hold check
/// covers the complete bounded batch. Any new hold rolls back every group.
pub fn migrateBatch(e: *core.Engine, store: *storage.Store, groups: []const Migration) !u64 {
    if (groups.len == 0 or groups.len > max_batch_inodes) return error.InvalidInputBatch;
    var moves: std.ArrayList(Move) = .empty;
    var seen = std.AutoHashMap(usize, void).init(e.c.a);
    var identities = std.AutoHashMap(fa.metadata.Identity, void).init(e.c.a);
    var reclaimed: u64 = 0;
    for (groups, 0..) |group, group_index| {
        if (group.indexes.len == 0 or group.indexes.len != group.metadata.links) return error.IncompleteInputAliases;
        if ((try identities.getOrPut(fa.metadata.identity(group.metadata))).found_existing) return error.DuplicateInputInode;
        reclaimed += group.metadata.allocated_bytes;
        for (group.indexes) |index| {
            if (index >= e.actions.items.len or (try seen.getOrPut(index)).found_existing) return error.InvalidInputBatch;
            const a = e.actions.items[index];
            if (a.status != .ready) return error.SharedInputHeld;
            try original(e, a.path, group.metadata, group.sha256, false);
            var parent = try fa.metadata.openRoot(e.c.io, try e.absolute(std.fs.path.dirname(a.path).?));
            defer parent.close(e.c.io);
            const prefix = try e.c.fmt("{s}/.shared-input-{d}-{d}", .{ std.fs.path.dirname(a.path).?, std.os.linux.getpid(), index });
            const row: Move = .{ .path = a.path, .backup = try e.c.fmt("{s}.old", .{prefix}), .temporary = try e.c.fmt("{s}.new", .{prefix}), .parent_mode = (try parent.stat(e.c.io)).permissions.toMode(), .group = group_index };
            for ([_][]const u8{ row.backup, row.temporary }) |path| {
                if (e.metadata(path)) |_| return error.SharedInputJournalCollision else |err| if (err != error.FileNotFound) return err;
            }
            try moves.append(e.c.a, row);
        }
    }
    try e.write(mutation.pending_path, .{ .schema = 1, .kind = "shared-input-batch", .output = e.output, .groups = groups, .moves = moves.items });
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
        const group = groups[row.group];
        var parent = try writable(e, row);
        defer closeParent(e, parent, row);
        try original(e, row.path, group.metadata, group.sha256, true);
        const file = try parent.openFile(e.c.io, std.fs.path.basename(row.path), .{ .follow_symlinks = false });
        defer file.close(e.c.io);
        try file.hardLink(e.c.io, parent, std.fs.path.basename(row.backup), .{});
        try store.linkInput(group.sha256, try e.absolute(row.temporary));
        try parent.rename(std.fs.path.basename(row.temporary), parent, std.fs.path.basename(row.path), e.c.io);
        try storage.syncDir(parent);
    }
    // All old names are now durable read-only aliases; old data is still in
    // backups. No descriptors remain in consumer directories during refresh.
    try rebindObservations(e, moves.items, groups);
    try refreshBatch(e, groups);
    for (groups) |group| for (group.indexes) |index| {
        if (e.actions.items[index].status != .ready) return error.SharedInputHeld;
    };
    for (e.controls.items) |control| try e.check(control);
    // The outer migration verifies all current targets before and after the
    // batch. Here, recheck their control files and each replaced input's bytes.
    try e.currentManifests(false);
    for (moves.items) |row| {
        const group = groups[row.group];
        const stored = try store.objects.statFile(e.c.io, group.sha256, .{});
        try original(e, row.backup, group.metadata, group.sha256, true);
        const old = try e.metadata(row.backup);
        if (old.links != group.metadata.links) return error.InputAliasesChanged;
        const current = try e.metadata(row.path);
        if (current.inode != stored.inode or current.mode & 0o222 != 0 or !std.mem.eql(u8, try e.digest(row.path), group.sha256)) return error.SharedInputChanged;
    }
    const remaining = try e.c.a.alloc(u64, groups.len);
    for (groups, 0..) |group, i| remaining[i] = group.metadata.links;
    deleting = true;
    for (moves.items) |row| {
        const group = groups[row.group];
        const parent = try writable(e, row);
        defer closeParent(e, parent, row);
        try original(e, row.backup, group.metadata, group.sha256, true);
        if ((try e.metadata(row.backup)).links != remaining[row.group]) return error.InputAliasesChanged;
        try parent.deleteFile(e.c.io, std.fs.path.basename(row.backup));
        remaining[row.group] -= 1;
        try storage.syncDir(parent);
    }
    for (moves.items) |row| {
        var parent = try fa.metadata.openRoot(e.c.io, try e.absolute(std.fs.path.dirname(row.path).?));
        defer parent.close(e.c.io);
        if ((try parent.stat(e.c.io)).permissions.toMode() != row.parent_mode) return error.ParentPermissionsChanged;
    }
    try e.write(try e.c.fmt("{s}/shared-input-batch-{d}.json", .{ e.output, groups[0].metadata.inode }), .{ .status = "complete", .groups = groups, .moves = moves.items, .reclaimed_file_bytes = reclaimed });
    try D.cwd().deleteFile(e.c.io, try e.absolute(mutation.pending_path));
    return reclaimed;
}

fn applyGroups(e: *core.Engine, groups: []Group, indexes: []const usize, reclaimed: *u64, created: *u64) !void {
    if (indexes.len == 0) return;
    var store = try storage.Store.open(e.c.a, e.c.io, try e.absolute("local-state/artifacts"), true);
    defer store.deinit();
    var migrations: std.ArrayList(Migration) = .empty;
    for (indexes) |index| {
        const g = groups[index];
        const object_path = try e.c.fmt("local-state/artifacts/objects/{s}", .{g.sha256});
        const existed = if (e.metadata(object_path)) |_| true else |err| switch (err) {
            error.FileNotFound => false,
            else => return err,
        };
        const source = try D.cwd().openFile(e.c.io, try e.absolute(e.actions.items[g.indexes.items[0]].path), .{ .follow_symlinks = false });
        defer source.close(e.c.io);
        try store.publishFile(source, .{ .name = "input.ll", .sha256 = g.sha256, .bytes = g.metadata.size });
        if (!existed) created.* += (try e.metadata(object_path)).allocated_bytes;
        try migrations.append(e.c.a, .{ .indexes = g.indexes.items, .metadata = g.metadata, .sha256 = g.sha256 });
    }
    reclaimed.* += try migrateBatch(e, &store, migrations.items);
    for (indexes) |index| {
        groups[index].reclaimed_file_bytes = groups[index].metadata.allocated_bytes;
        groups[index].status = "shared";
    }
    try e.c.print("Shared batch: {d} old inodes; total removed {d} allocated bytes; created {d} object bytes.\n", .{ indexes.len, reclaimed.*, created.* });
}

pub fn run(e: *core.Engine, plan_path: []const u8, apply: bool) !void {
    if (!p.relative(plan_path)) return error.InvalidEvidencePath;
    // A held release protects inputs even when no manual/job hold repeats it.
    try e.discover();
    e.actions.clearRetainingCapacity();
    try e.addControl(plan_path);
    var parsed = try e.load(e.c.gpa, plan_path);
    defer parsed.deinit();
    var plan = try std.json.parseFromValue(Plan, e.c.gpa, parsed.value, .{});
    defer plan.deinit();
    const evidence = std.mem.eql(u8, plan.value.schema, "zllvm-shared-evidence-v1");
    if ((!evidence and !std.mem.eql(u8, plan.value.schema, "zllvm-shared-inputs-v1")) or plan.value.inputs.len == 0) return error.InvalidSharedInputPlan;
    if (evidence or plan.value.sharing_holds != null) {
        const review = plan.value.review orelse return error.MissingEvidenceSharingReview;
        const reason = plan.value.reason orelse return error.MissingEvidenceSharingReview;
        if (!p.relative(review.path) or !p.hash(review.sha256) or std.mem.trim(u8, reason, " \t\r\n").len == 0) return error.InvalidEvidenceSharingReview;
        try e.check(review);
        try e.addControl(review.path);
    }
    if (plan.value.sharing_holds) |review| {
        if (!std.mem.eql(u8, review.manifest.path, e.config.holds_file) or review.paths.len == 0) return error.InvalidSharingHoldReview;
        try e.check(review.manifest);
        var held = try e.load(e.c.gpa, review.manifest.path);
        defer held.deinit();
        var holds = try std.json.parseFromValue(p.Holds, e.c.gpa, held.value, .{});
        defer holds.deinit();
        if (holds.value.schema != 1) return error.InvalidHolds;
        var selected = std.StringHashMap(void).init(e.c.a);
        for (review.paths) |path| {
            if (!p.relative(path) or selected.contains(path)) return error.InvalidSharingHoldReview;
            try selected.put(path, {});
            var declared = false;
            for (holds.value.paths) |held_path| if (std.mem.eql(u8, path, held_path)) {
                declared = true;
                break;
            };
            var used = false;
            for (plan.value.inputs) |family| for (family.paths) |input| {
                if (p.overlaps(path, input)) used = true;
            };
            if (!declared or !used) return error.InvalidSharingHoldReview;
        }
        e.reviewed_holds = .{ .path = try e.c.a.dupe(u8, review.manifest.path), .sha256 = try e.c.a.dupe(u8, review.manifest.sha256) };
        const owned_paths = try e.c.a.alloc([]const u8, review.paths.len);
        for (review.paths, 0..) |path, i| owned_paths[i] = try e.c.a.dupe(u8, path);
        e.reviewed_hold_paths = owned_paths;
    }
    var groups: std.ArrayList(Group) = .empty;
    var seen = std.StringHashMap(void).init(e.c.a);
    var checked_text = std.StringHashMap(void).init(e.c.gpa);
    defer checked_text.deinit();
    for (plan.value.inputs) |family| {
        if (!p.hash(family.sha256)) return error.InvalidSharedInputPlan;
        for (family.paths) |path| {
            const admitted = if (evidence) evidenceScope(path) else scope(path);
            if (seen.count() >= 16_384 or !admitted or seen.contains(path)) return error.InvalidSharedInputPlan;
            try seen.put(path, {});
            const m = try e.metadata(path);
            if (m.kind != .file or m.uid != std.os.linux.getuid() or m.mode & 0o111 != 0) return error.InvalidSharedInput;
            if (!std.mem.eql(u8, try e.digest(path), family.sha256)) return error.SharedInputHashChanged;
            if (evidence and !scope(path) and !checked_text.contains(family.sha256)) {
                const file = try D.cwd().openFile(e.c.io, try e.absolute(path), .{ .follow_symlinks = false });
                defer file.close(e.c.io);
                var prefix: [8]u8 = undefined;
                const n = try file.readPositionalAll(e.c.io, &prefix, 0);
                if (std.mem.startsWith(u8, prefix[0..n], "\x7fELF") or std.mem.startsWith(u8, prefix[0..n], "!<arch>\n")) return error.CompiledEvidenceNotShareable;
                try checked_text.put(family.sha256, {});
            }
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
            try e.actions.append(e.c.a, .{ .path = try e.c.a.dupe(u8, path), .run_root = try e.c.a.dupe(u8, consumerRoot(path)), .producer = plan_path, .kind = .build_output, .status = .ready, .sha256 = groups.items[group_index.?].sha256, .metadata = m, .shared_input = true });
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
    var batch: std.ArrayList(usize) = .empty;
    var batch_bytes: u64 = 0;
    for (groups.items, 0..) |*g, index| {
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
        if (batch.items.len != 0 and (batch.items.len == max_batch_inodes or batch_bytes + g.metadata.size > 64 * 1024 * 1024)) {
            try applyGroups(e, groups.items, batch.items, &reclaimed, &created);
            batch.clearRetainingCapacity();
            batch_bytes = 0;
        }
        try batch.append(e.c.a, index);
        batch_bytes += g.metadata.size;
    }
    try applyGroups(e, groups.items, batch.items, &reclaimed, &created);
    try e.currentManifests(true);
    status = "complete";
    try e.c.print("Shared input {s}: removed {d} allocated bytes; created {d} object bytes.\n{s}/shared-input-review.json\n", .{ if (apply) "migration" else "review", reclaimed, created, e.output });
}
