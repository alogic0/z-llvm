const std = @import("std");
const audit = @import("file_audit");
const t = std.testing;
const Io = std.Io;

fn write(dir: Io.Dir, name: []const u8, bytes: []const u8) !void {
    const file = try dir.createFile(t.io, name, .{});
    defer file.close(t.io);
    try file.writeStreamingAll(t.io, bytes);
    try file.sync(t.io);
}
fn entry(value: audit.Snapshot, name: []const u8) !audit.Entry {
    for (value.entries) |e| if (std.mem.eql(u8, name, e.path)) return e;
    return error.MissingTestEntry;
}

test "snapshot uses known SHA256 bytes and verifies unchanged files" {
    var tmp = t.tmpDir(.{ .iterate = true });
    defer tmp.cleanup();
    try write(tmp.dir, "data", "abc");
    const root = try tmp.dir.realPathFileAlloc(t.io, ".", t.allocator);
    defer t.allocator.free(root);
    var snapshot = try audit.scan(t.allocator, t.io, root, .{ .hash_files = true });
    defer snapshot.deinit();
    try t.expectEqual(@as(usize, 2), snapshot.value.entries.len);
    const file = try entry(snapshot.value, "data");
    try t.expectEqualStrings("ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad", file.sha256.?);
    try t.expectEqual(@as(u64, 3), snapshot.value.totals.logical_file_bytes);
    try t.expectEqual(@as(usize, 1), snapshot.value.totals.unique_file_inodes);
    try audit.verify(t.allocator, t.io, snapshot.value);
}

test "duplicate savings exclude existing hardlinks and different permissions" {
    var tmp = t.tmpDir(.{ .iterate = true });
    defer tmp.cleanup();
    try write(tmp.dir, "a", "same bytes");
    try write(tmp.dir, "b", "same bytes");
    try write(tmp.dir, "executable", "same bytes");
    try tmp.dir.hardLink("a", tmp.dir, "alias", t.io, .{});
    const executable = try tmp.dir.openFile(t.io, "executable", .{});
    defer executable.close(t.io);
    try executable.setPermissions(t.io, .fromMode(0o755));
    const root = try tmp.dir.realPathFileAlloc(t.io, ".", t.allocator);
    defer t.allocator.free(root);
    var snapshot = try audit.scan(t.allocator, t.io, root, .{ .hash_files = true });
    var duplicates = try audit.findDuplicates(t.allocator, snapshot.value);
    defer duplicates.deinit();
    const replacement = try entry(snapshot.value, "b");
    const totals = snapshot.value.totals;
    const expected_allocation = (try entry(snapshot.value, ".")).metadata.allocated_bytes + (try entry(snapshot.value, "a")).metadata.allocated_bytes + replacement.metadata.allocated_bytes + (try entry(snapshot.value, "executable")).metadata.allocated_bytes;
    snapshot.deinit(); // The duplicate result must own its strings.
    try t.expectEqual(@as(usize, 4), totals.files);
    try t.expectEqual(@as(usize, 3), totals.unique_file_inodes);
    try t.expectEqual(expected_allocation, totals.unique_allocated_bytes);
    try t.expectEqual(@as(usize, 1), duplicates.value.duplicate_paths);
    try t.expectEqualStrings("a", duplicates.value.candidates[0].retain);
    try t.expectEqualStrings("b", duplicates.value.candidates[0].replace);
    try t.expectEqual(replacement.metadata.allocated_bytes, duplicates.value.reclaimable_bytes);
}

test "equal sizes are not accepted as equal content" {
    var tmp = t.tmpDir(.{ .iterate = true });
    defer tmp.cleanup();
    try write(tmp.dir, "a", "abc");
    try write(tmp.dir, "b", "abd");
    const root = try tmp.dir.realPathFileAlloc(t.io, ".", t.allocator);
    defer t.allocator.free(root);
    var snapshot = try audit.scan(t.allocator, t.io, root, .{ .hash_files = true });
    defer snapshot.deinit();
    var duplicates = try audit.findDuplicates(t.allocator, snapshot.value);
    defer duplicates.deinit();
    try t.expectEqual(@as(usize, 0), duplicates.value.duplicate_paths);
}

test "sparse files report allocated blocks independently of logical size" {
    var tmp = t.tmpDir(.{ .iterate = true });
    defer tmp.cleanup();
    const sparse = try tmp.dir.createFile(t.io, "sparse", .{});
    defer sparse.close(t.io);
    try sparse.setLength(t.io, 8 * 1024 * 1024);
    const root = try tmp.dir.realPathFileAlloc(t.io, ".", t.allocator);
    defer t.allocator.free(root);
    var snapshot = try audit.scan(t.allocator, t.io, root, .{});
    defer snapshot.deinit();
    const m = (try entry(snapshot.value, "sparse")).metadata;
    try t.expectEqual(@as(u64, 8 * 1024 * 1024), m.size);
    try t.expect(m.allocated_bytes < m.size);
    try t.expectEqual(m.size, snapshot.value.totals.logical_file_bytes);
}

test "verification rejects content edits and directory membership changes" {
    var tmp = t.tmpDir(.{ .iterate = true });
    defer tmp.cleanup();
    try write(tmp.dir, "data", "old");
    const root = try tmp.dir.realPathFileAlloc(t.io, ".", t.allocator);
    defer t.allocator.free(root);
    var original = try audit.scan(t.allocator, t.io, root, .{ .hash_files = true });
    defer original.deinit();
    try write(tmp.dir, "data", "new");
    try t.expectError(error.SnapshotChanged, audit.verify(t.allocator, t.io, original.value));
    var updated = try audit.scan(t.allocator, t.io, root, .{ .hash_files = true });
    defer updated.deinit();
    try write(tmp.dir, "added", "new");
    try t.expectError(error.SnapshotChanged, audit.verify(t.allocator, t.io, updated.value));
}

test "symlinks are recorded and never traversed including root ancestors" {
    var tmp = t.tmpDir(.{ .iterate = true });
    defer tmp.cleanup();
    try tmp.dir.createDir(t.io, "actual", .default_dir);
    try write(tmp.dir, "actual/data", "abc");
    try tmp.dir.symLink(t.io, "actual", "link", .{ .is_directory = true });
    try tmp.dir.symLink(t.io, "absent", "dangling", .{});
    const root = try tmp.dir.realPathFileAlloc(t.io, ".", t.allocator);
    defer t.allocator.free(root);
    var snapshot = try audit.scan(t.allocator, t.io, root, .{ .hash_files = true });
    defer snapshot.deinit();
    try t.expectEqual(@as(usize, 1), snapshot.value.totals.files);
    try t.expectEqual(@as(usize, 2), snapshot.value.totals.symlinks);
    try t.expect((try entry(snapshot.value, "link")).sha256 == null);
    try t.expectError(error.MissingTestEntry, entry(snapshot.value, "link/data"));
    const alias = try std.fs.path.join(t.allocator, &.{ root, "link" });
    defer t.allocator.free(alias);
    if (audit.scan(t.allocator, t.io, alias, .{})) |value| {
        var owned = value;
        owned.deinit();
        return error.FollowedSymlinkRoot;
    } else |err| try t.expect(err == error.NotDir or err == error.SymLinkLoop or err == error.SymlinkPath);
    const m = try audit.metadata.child(t.allocator, tmp.dir, "link");
    try t.expectError(error.NotRegularFile, audit.metadata.hashFile(t.allocator, t.io, tmp.dir, "link", m));
}

test "exclusions are explicit relative subtrees and remain part of verification" {
    var tmp = t.tmpDir(.{ .iterate = true });
    defer tmp.cleanup();
    try tmp.dir.createDir(t.io, "cache", .default_dir);
    try tmp.dir.createDir(t.io, "cache2", .default_dir);
    try write(tmp.dir, "cache/ignored", "old");
    try write(tmp.dir, "cache2/kept", "keep");
    const root = try tmp.dir.realPathFileAlloc(t.io, ".", t.allocator);
    defer t.allocator.free(root);
    var snapshot = try audit.scan(t.allocator, t.io, root, .{ .hash_files = true, .exclude_paths = &.{"cache"} });
    defer snapshot.deinit();
    try t.expectEqual(@as(usize, 1), snapshot.value.totals.files);
    _ = try entry(snapshot.value, "cache2/kept");
    try write(tmp.dir, "cache/ignored", "new");
    try audit.verify(t.allocator, t.io, snapshot.value);
    for ([_][]const u8{ "", "/absolute", "cache/", "cache/../other", ".", "x\x00y" }) |bad| {
        try t.expectError(error.InvalidExclusion, audit.scan(t.allocator, t.io, root, .{ .exclude_paths = &.{bad} }));
    }
}

test "entry and recursion limits fail without returning partial results" {
    var tmp = t.tmpDir(.{ .iterate = true });
    defer tmp.cleanup();
    try tmp.dir.createDir(t.io, "nested", .default_dir);
    try write(tmp.dir, "nested/data", "abc");
    const root = try tmp.dir.realPathFileAlloc(t.io, ".", t.allocator);
    defer t.allocator.free(root);
    try t.expectError(error.EntryLimitExceeded, audit.scan(t.allocator, t.io, root, .{ .max_entries = 1 }));
    try t.expectError(error.DepthLimitExceeded, audit.scan(t.allocator, t.io, root, .{ .max_depth = 0 }));
    try t.expectError(error.InvalidLimits, audit.scan(t.allocator, t.io, root, .{ .max_depth = 257 }));
    try t.expectError(error.InvalidRoot, audit.scan(t.allocator, t.io, "../escape", .{}));
    try t.expectError(error.InvalidName, audit.metadata.child(t.allocator, tmp.dir, "nested/data"));
}

const base: audit.Metadata = .{ .device = 7, .inode = 11, .links = 1, .size = 3, .allocated_bytes = 4096, .mode = 0o644, .uid = 1000, .gid = 1000, .mtime_ns = 1794460216963232019, .ctime_ns = 1794460216963232021, .kind = .file };
const hash = "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad";

test "JSON roundtrip preserves nanoseconds and full unsigned inode range" {
    var m = base;
    m.inode = std.math.maxInt(u64);
    const bytes = try std.json.Stringify.valueAlloc(t.allocator, m, .{});
    defer t.allocator.free(bytes);
    try t.expect(std.mem.indexOf(u8, bytes, "1794460216963232019") != null);
    try t.expect(std.mem.indexOf(u8, bytes, "18446744073709551615") != null);
    const parsed = try std.json.parseFromSlice(audit.Metadata, t.allocator, bytes, .{});
    defer parsed.deinit();
    try t.expect(m.eql(parsed.value));
}

test "duplicate grouping requires matching ownership device and permissions" {
    var entries: [5]audit.Entry = undefined;
    for (&entries, [_][]const u8{ "base", "uid", "gid", "device", "mode" }, 0..) |*e, name, i| {
        var m = base;
        m.inode += i;
        switch (i) {
            1 => m.uid += 1,
            2 => m.gid += 1,
            3 => m.device += 1,
            4 => m.mode = 0o755,
            else => {},
        }
        e.* = .{ .path = name, .metadata = m, .sha256 = hash };
    }
    var report = try audit.findDuplicates(t.allocator, .{ .root = "/fixture", .options = .{ .hash_files = true }, .totals = .{}, .entries = &entries });
    defer report.deinit();
    try t.expectEqual(@as(usize, 0), report.value.duplicate_paths);
}

test "duplicate reports require full hashes and reject ambiguous paths" {
    var rows = [_]audit.Entry{.{ .path = "data", .metadata = base, .sha256 = hash }};
    var snapshot: audit.Snapshot = .{ .root = "/fixture", .options = .{}, .totals = .{}, .entries = &rows };
    try t.expectError(error.HashesRequired, audit.findDuplicates(t.allocator, snapshot));
    snapshot.options.hash_files = true;
    rows[0].sha256 = null;
    try t.expectError(error.MissingHash, audit.findDuplicates(t.allocator, snapshot));
    rows[0].sha256 = "bad";
    try t.expectError(error.InvalidHash, audit.findDuplicates(t.allocator, snapshot));
    rows[0].sha256 = hash;
    rows[0].path = "../outside";
    try t.expectError(error.InvalidPath, audit.findDuplicates(t.allocator, snapshot));
    rows[0].path = "data";
    const repeated = [_]audit.Entry{ rows[0], rows[0] };
    snapshot.entries = &repeated;
    try t.expectError(error.DuplicatePath, audit.findDuplicates(t.allocator, snapshot));
}

test "hashing refuses a stale identity before reading" {
    var tmp = t.tmpDir(.{ .iterate = true });
    defer tmp.cleanup();
    try write(tmp.dir, "data", "old");
    const before = try audit.metadata.child(t.allocator, tmp.dir, "data");
    try write(tmp.dir, "data", "new");
    try t.expectError(error.FileChanged, audit.metadata.hashFile(t.allocator, t.io, tmp.dir, "data", before));
}

test "hashing detects a same-size edit during the actual read" {
    var tmp = t.tmpDir(.{ .iterate = true });
    defer tmp.cleanup();
    try write(tmp.dir, "data", "old");
    const before = try audit.metadata.child(t.allocator, tmp.dir, "data");
    const State = struct {
        dir: Io.Dir,
        changed: bool = false,
        fn operate(userdata: ?*anyopaque, operation: Io.Operation) Io.Cancelable!Io.Operation.Result {
            const self: *@This() = @ptrCast(@alignCast(userdata.?));
            if (operation == .file_read_streaming and !self.changed) {
                self.changed = true;
                write(self.dir, "data", "new") catch return .{ .file_read_streaming = error.InputOutput };
            }
            return t.io.vtable.operate(t.io.userdata, operation);
        }
        fn close(userdata: ?*anyopaque, files: []const Io.File) void {
            _ = userdata;
            t.io.vtable.fileClose(t.io.userdata, files);
        }
    };
    var state: State = .{ .dir = tmp.dir };
    var vtable = t.io.vtable.*;
    vtable.operate = State.operate;
    vtable.fileClose = State.close;
    const changed_io: Io = .{ .userdata = &state, .vtable = &vtable };
    try t.expectError(error.FileChanged, audit.metadata.hashFile(t.allocator, changed_io, tmp.dir, "data", before));
    try t.expect(state.changed);
}

fn scanAndGroup(a: std.mem.Allocator, root: []const u8) !void {
    var snapshot = try audit.scan(a, t.io, root, .{ .hash_files = true });
    defer snapshot.deinit();
    var found = try audit.findDuplicates(a, snapshot.value);
    defer found.deinit();
}

test "guarded reads return exact bytes including empty files and enforce limits" {
    var tmp = t.tmpDir(.{ .iterate = true });
    defer tmp.cleanup();
    for ([_][]const u8{ "", "abc\x00def" }) |data| {
        try write(tmp.dir, "data", data);
        const m = try audit.metadata.child(t.allocator, tmp.dir, "data");
        const bytes = try audit.metadata.readFile(t.allocator, t.io, tmp.dir, "data", m, data.len);
        defer t.allocator.free(bytes);
        try t.expectEqualStrings(data, bytes);
        if (data.len > 0) try t.expectError(error.FileTooLarge, audit.metadata.readFile(t.allocator, t.io, tmp.dir, "data", m, data.len - 1));
    }
}

test "mount identity agrees within a filesystem and distinguishes procfs" {
    var tmp = t.tmpDir(.{ .iterate = true });
    defer tmp.cleanup();
    try write(tmp.dir, "data", "bytes");
    const file = try tmp.dir.openFile(t.io, "data", .{});
    defer file.close(t.io);
    const id = try audit.metadata.mountId(tmp.dir.handle);
    try t.expectEqual(id, try audit.metadata.mountId(file.handle));
    var proc = try audit.metadata.openRoot(t.io, "/proc");
    defer proc.close(t.io);
    try t.expect(id != try audit.metadata.mountId(proc.handle));
}

test "guarded reads reject stale files and replacement symlinks and FIFOs" {
    var tmp = t.tmpDir(.{ .iterate = true });
    defer tmp.cleanup();
    try write(tmp.dir, "data", "old");
    const before = try audit.metadata.child(t.allocator, tmp.dir, "data");
    try write(tmp.dir, "data", "new");
    try t.expectError(error.FileChanged, audit.metadata.readFile(t.allocator, t.io, tmp.dir, "data", before, 64));
    try tmp.dir.deleteFile(t.io, "data");
    try tmp.dir.symLink(t.io, "missing", "data", .{});
    try t.expectError(error.FileChanged, audit.metadata.readFile(t.allocator, t.io, tmp.dir, "data", before, 64));
    try t.expectError(error.NotRegularFile, audit.metadata.readFile(t.allocator, t.io, tmp.dir, "data", try audit.metadata.child(t.allocator, tmp.dir, "data"), 64));
    try tmp.dir.deleteFile(t.io, "data");
    try t.expectEqual(std.os.linux.E.SUCCESS, std.os.linux.errno(std.os.linux.mknodat(tmp.dir.handle, "data", 0o010600, 0)));
    try t.expectError(error.FileChanged, audit.metadata.readFile(t.allocator, t.io, tmp.dir, "data", before, 64));
    try t.expectError(error.NotRegularFile, audit.metadata.readFile(t.allocator, t.io, tmp.dir, "data", try audit.metadata.child(t.allocator, tmp.dir, "data"), 64));
}

test "guarded reads detect a same-size edit during the actual read" {
    var tmp = t.tmpDir(.{ .iterate = true });
    defer tmp.cleanup();
    try write(tmp.dir, "data", "old");
    const before = try audit.metadata.child(t.allocator, tmp.dir, "data");
    const State = struct {
        dir: Io.Dir,
        changed: bool = false,
        fn operate(userdata: ?*anyopaque, operation: Io.Operation) Io.Cancelable!Io.Operation.Result {
            const self: *@This() = @ptrCast(@alignCast(userdata.?));
            if (operation == .file_read_streaming and !self.changed) {
                self.changed = true;
                write(self.dir, "data", "new") catch return .{ .file_read_streaming = error.InputOutput };
            }
            return t.io.vtable.operate(t.io.userdata, operation);
        }
        fn close(_: ?*anyopaque, files: []const Io.File) void {
            t.io.vtable.fileClose(t.io.userdata, files);
        }
    };
    var state: State = .{ .dir = tmp.dir };
    var vtable = t.io.vtable.*;
    vtable.operate = State.operate;
    vtable.fileClose = State.close;
    const changed_io: Io = .{ .userdata = &state, .vtable = &vtable };
    try t.expectError(error.FileChanged, audit.metadata.readFile(t.allocator, changed_io, tmp.dir, "data", before, 64));
    try t.expect(state.changed);
}
test "allocation failures release snapshots reports and file descriptors" {
    var tmp = t.tmpDir(.{ .iterate = true });
    defer tmp.cleanup();
    try write(tmp.dir, "a", "same");
    try write(tmp.dir, "b", "same");
    const root = try tmp.dir.realPathFileAlloc(t.io, ".", t.allocator);
    defer t.allocator.free(root);
    const before = try descriptorCount();
    try t.checkAllAllocationFailures(t.allocator, scanAndGroup, .{root});
    try t.expectEqual(before, try descriptorCount());
}

fn descriptorCount() !usize {
    var dir = try Io.Dir.openDirAbsolute(t.io, "/proc/self/fd", .{ .iterate = true });
    defer dir.close(t.io);
    var iterator = dir.iterate();
    var count: usize = 0;
    while (try iterator.next(t.io)) |_| count += 1;
    return count;
}

test "FIFO is inventoried without opening or hashing it" {
    var tmp = t.tmpDir(.{ .iterate = true });
    defer tmp.cleanup();
    const linux = std.os.linux;
    try t.expectEqual(linux.E.SUCCESS, linux.errno(linux.mknodat(tmp.dir.handle, "fifo", linux.S.IFIFO | 0o600, 0)));
    const root = try tmp.dir.realPathFileAlloc(t.io, ".", t.allocator);
    defer t.allocator.free(root);
    var snapshot = try audit.scan(t.allocator, t.io, root, .{ .hash_files = true });
    defer snapshot.deinit();
    const fifo = try entry(snapshot.value, "fifo");
    try t.expectEqual(audit.Kind.other, fifo.metadata.kind);
    try t.expect(fifo.sha256 == null);
    try t.expectEqual(@as(usize, 1), snapshot.value.totals.other);
}

test "changed hardlink count invalidates an existing snapshot" {
    var tmp = t.tmpDir(.{ .iterate = true });
    defer tmp.cleanup();
    try write(tmp.dir, "data", "abc");
    const root = try tmp.dir.realPathFileAlloc(t.io, ".", t.allocator);
    defer t.allocator.free(root);
    var snapshot = try audit.scan(t.allocator, t.io, root, .{ .hash_files = true });
    defer snapshot.deinit();
    try tmp.dir.hardLink("data", tmp.dir, "alias", t.io, .{});
    try t.expectError(error.SnapshotChanged, audit.verify(t.allocator, t.io, snapshot.value));
}
