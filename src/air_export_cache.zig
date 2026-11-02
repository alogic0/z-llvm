//! Publish a validated run-owned export without retaining a second payload.
//! Metadata is the atomic commit record; payloads are immutable and named by
//! both generation and content, so readers never pair new bytes with old hashes.
const std = @import("std");
const Io = std.Io;
const Sha256 = std.crypto.hash.sha2.Sha256;

fn digest(bytes: []const u8) [32]u8 {
    var result: [32]u8 = undefined;
    Sha256.hash(bytes, &result, .{});
    return result;
}

pub fn value(metadata: []const u8, key: []const u8) ?[]const u8 {
    var lines = std.mem.splitScalar(u8, metadata, '\n');
    while (lines.next()) |line| {
        if (std.mem.eql(u8, line, "key_begin")) break;
        if (line.len > key.len and line[key.len] == '=' and
            std.mem.eql(u8, line[0..key.len], key)) return line[key.len + 1 ..];
    }
    return null;
}

fn validHash(hash: []const u8) bool {
    if (hash.len != 64) return false;
    for (hash) |c| if (!std.ascii.isDigit(c) and !(c >= 'a' and c <= 'f')) return false;
    return true;
}

pub fn payloadName(allocator: std.mem.Allocator, key: []const u8, metadata: []const u8) ![]u8 {
    if (!validHash(key) or !std.mem.eql(u8, value(metadata, "cache_key") orelse return error.InvalidExportMetadata, key))
        return error.InvalidExportMetadata;
    const hash = value(metadata, "descriptor_sha256") orelse return error.InvalidExportMetadata;
    if (!validHash(hash)) return error.InvalidExportMetadata;
    const schema = value(metadata, "schema") orelse return error.InvalidExportMetadata;
    if (std.mem.eql(u8, schema, "3")) return std.fmt.allocPrint(allocator, "{s}.air", .{key});
    if (std.mem.eql(u8, schema, "4")) return std.fmt.allocPrint(allocator, "{s}.{s}.air", .{ key, hash });
    return error.InvalidExportMetadata;
}

fn verify(io: Io, file: Io.File, expected: []const u8) !Io.File.Stat {
    const before = try file.stat(io);
    if (before.kind != .file or before.size != expected.len) return error.ExportContentMismatch;
    var hash = Sha256.init(.{});
    var buffer: [64 * 1024]u8 = undefined;
    var offset: u64 = 0;
    while (true) {
        const n = try file.readPositional(io, &.{&buffer}, offset);
        if (n == 0) break;
        hash.update(buffer[0..n]);
        offset += n;
    }
    const after = try file.stat(io);
    var expected_hash: [32]u8 = undefined;
    Sha256.hash(expected, &expected_hash, .{});
    if (offset != expected.len or before.inode != after.inode or before.size != after.size or
        !std.meta.eql(before.mtime, after.mtime) or !std.mem.eql(u8, &hash.finalResult(), &expected_hash))
        return error.ExportContentMismatch;
    return after;
}

fn syncDir(dir: Io.Dir) !void {
    switch (std.os.linux.errno(std.os.linux.fsync(dir.handle))) {
        .SUCCESS => {},
        else => |err| return std.posix.unexpectedErrno(err),
    }
}

fn rollback(io: Io, raw_dir: Io.Dir, raw_name: []const u8, cache: Io.Dir, payload: []const u8, moved: bool, created: bool) !void {
    if (moved) {
        // Never overwrite a subsequently created run-owned diagnostic.
        try cache.renamePreserve(payload, raw_dir, raw_name, io);
    } else if (created) try cache.deleteFile(io, payload);
}

pub const Method = enum { moved, copied, reused };

pub fn publish(
    allocator: std.mem.Allocator,
    io: Io,
    raw_dir: Io.Dir,
    raw_name: []const u8,
    cache: Io.Dir,
    key: []const u8,
    metadata: []const u8,
    descriptor: []const u8,
) !Method {
    return publishWithCommit(allocator, io, raw_dir, raw_name, cache, key, metadata, descriptor, commitMetadata);
}

fn commitMetadata(atomic: *Io.File.Atomic, io: Io) !void {
    try atomic.replace(io);
}

fn publishWithCommit(
    allocator: std.mem.Allocator,
    io: Io,
    raw_dir: Io.Dir,
    raw_name: []const u8,
    cache: Io.Dir,
    key: []const u8,
    metadata: []const u8,
    descriptor: []const u8,
    comptime commit: anytype,
) !Method {
    if (!std.mem.eql(u8, value(metadata, "schema") orelse "", "4")) return error.InvalidExportMetadata;
    const payload = try payloadName(allocator, key, metadata);
    defer allocator.free(payload);
    const actual_hash = std.fmt.bytesToHex(digest(descriptor), .lower);
    if (!std.mem.eql(u8, &actual_hash, value(metadata, "descriptor_sha256").?)) return error.ExportContentMismatch;
    const meta_name = try std.fmt.allocPrint(allocator, "{s}.meta", .{key});
    defer allocator.free(meta_name);
    const lock_name = try std.fmt.allocPrint(allocator, "{s}.lock", .{key});
    defer allocator.free(lock_name);
    const new_lock = cache.createFile(io, lock_name, .{ .exclusive = true }) catch |err| switch (err) {
        error.PathAlreadyExists => null,
        else => return err,
    };
    if (new_lock) |file| file.close(io);
    const lock = try cache.openFile(io, lock_name, .{ .mode = .read_write, .follow_symlinks = false, .allow_directory = false, .lock = .exclusive, .lock_nonblocking = true });
    defer lock.close(io);

    const previous_meta = cache.readFileAlloc(io, meta_name, allocator, .limited(64 * 1024)) catch null;
    defer if (previous_meta) |bytes| allocator.free(bytes);
    const previous_payload = if (previous_meta) |bytes| payloadName(allocator, key, bytes) catch null else null;
    defer if (previous_payload) |name| allocator.free(name);

    const raw = try raw_dir.openFile(io, raw_name, .{ .follow_symlinks = false, .allow_directory = false });
    defer raw.close(io);
    const raw_state = try verify(io, raw, descriptor);
    try raw.sync(io);
    // Prepare and synchronize metadata before transferring ownership of raw.
    var atomic_meta = try cache.createFileAtomic(io, meta_name, .{ .replace = true });
    defer atomic_meta.deinit(io);
    try atomic_meta.file.writeStreamingAll(io, metadata);
    try atomic_meta.file.sync(io);

    var moved = false;
    var created = false;
    var method: Method = .moved;
    const existing_payload = cache.openFile(io, payload, .{ .follow_symlinks = false, .allow_directory = false }) catch |err| switch (err) {
        error.FileNotFound => null,
        else => return err,
    };
    if (existing_payload) |file| {
        defer file.close(io);
        _ = try verify(io, file, descriptor);
        method = .reused;
    } else raw_dir.renamePreserve(raw_name, cache, payload, io) catch |err| switch (err) {
        error.PathAlreadyExists => {
            const existing = try cache.openFile(io, payload, .{ .follow_symlinks = false, .allow_directory = false });
            defer existing.close(io);
            _ = try verify(io, existing, descriptor);
            method = .reused;
        },
        error.CrossDevice => {
            // A cross-filesystem publication needs a temporary second copy.
            // It is atomic, and raw stays owned by the run until metadata commits.
            var atomic_payload = try cache.createFileAtomic(io, payload, .{});
            defer atomic_payload.deinit(io);
            try atomic_payload.file.writeStreamingAll(io, descriptor);
            try atomic_payload.file.sync(io);
            try atomic_payload.link(io);
            created = true;
            method = .copied;
        },
        else => return err,
    };
    if (method == .moved) {
        moved = true;
        created = true;
    }
    syncDir(cache) catch |err| {
        try rollback(io, raw_dir, raw_name, cache, payload, moved, created);
        return err;
    };
    commit(&atomic_meta, io) catch |err| {
        try rollback(io, raw_dir, raw_name, cache, payload, moved, created);
        return err;
    };
    // The cache owns the validated export after this atomic commit, including
    // when a subsequent directory sync or obsolete-payload cleanup fails.
    try syncDir(cache);
    if (!moved) {
        const current = try raw_dir.statFile(io, raw_name, .{ .follow_symlinks = false });
        if (current.inode != raw_state.inode or current.size != raw_state.size or
            !std.meta.eql(current.mtime, raw_state.mtime)) return error.ExportContentMismatch;
        try raw_dir.deleteFile(io, raw_name);
    }
    if (previous_payload) |name| {
        if (!std.mem.eql(u8, name, payload)) cache.deleteFile(io, name) catch |err| switch (err) {
            error.FileNotFound => {},
            else => return err,
        };
    }
    try syncDir(cache);
    return method;
}

fn testMetadata(allocator: std.mem.Allocator, key: []const u8, descriptor: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "schema=4\ncache_key={s}\ndescriptor_sha256={s}\n", .{ key, std.fmt.bytesToHex(digest(descriptor), .lower) });
}

test "publication transfers the original inode and leaves no raw duplicate" {
    const a = std.testing.allocator;
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    var cache = try tmp.dir.createDirPathOpen(io, "cache", .{ .open_options = .{ .iterate = true } });
    defer cache.close(io);
    const key: [64]u8 = @splat('a');
    const bytes = "validated descriptor";
    try tmp.dir.writeFile(io, .{ .sub_path = "compiler.air", .data = bytes });
    const before = try tmp.dir.statFile(io, "compiler.air", .{});
    const meta = try testMetadata(a, &key, bytes);
    defer a.free(meta);
    try std.testing.expectEqual(Method.moved, try publish(a, io, tmp.dir, "compiler.air", cache, &key, meta, bytes));
    try std.testing.expectError(error.FileNotFound, tmp.dir.access(io, "compiler.air", .{}));
    const name = try payloadName(a, &key, meta);
    defer a.free(name);
    try std.testing.expectEqual(before.inode, (try cache.statFile(io, name, .{})).inode);
    const stored = try cache.readFileAlloc(io, &key ++ ".meta", a, .limited(4096));
    defer a.free(stored);
    try std.testing.expectEqualStrings(meta, stored);
}

test "failed metadata commit restores raw and preserves previous committed payload" {
    const a = std.testing.allocator;
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    var cache = try tmp.dir.createDirPathOpen(io, "cache", .{ .open_options = .{ .iterate = true } });
    defer cache.close(io);
    const key: [64]u8 = @splat('b');
    const previous = try testMetadata(a, &key, "previous committed evidence");
    defer a.free(previous);
    try tmp.dir.writeFile(io, .{ .sub_path = "compiler.air", .data = "previous committed evidence" });
    _ = try publish(a, io, tmp.dir, "compiler.air", cache, &key, previous, "previous committed evidence");
    const bytes = "new descriptor";
    try tmp.dir.writeFile(io, .{ .sub_path = "compiler.air", .data = bytes });
    const meta = try testMetadata(a, &key, bytes);
    defer a.free(meta);
    const FailingCommit = struct {
        fn fail(_: *Io.File.Atomic, _: Io) !void {
            return error.InjectedMetadataCommitFailure;
        }
    };
    try std.testing.expectError(error.InjectedMetadataCommitFailure, publishWithCommit(a, io, tmp.dir, "compiler.air", cache, &key, meta, bytes, FailingCommit.fail));
    const restored = try tmp.dir.readFileAlloc(io, "compiler.air", a, .limited(4096));
    defer a.free(restored);
    try std.testing.expectEqualStrings(bytes, restored);
    const committed_meta = try cache.readFileAlloc(io, &key ++ ".meta", a, .limited(4096));
    defer a.free(committed_meta);
    try std.testing.expectEqualStrings(previous, committed_meta);
    const previous_name = try payloadName(a, &key, previous);
    defer a.free(previous_name);
    try cache.access(io, previous_name, .{});
    const name = try payloadName(a, &key, meta);
    defer a.free(name);
    try std.testing.expectError(error.FileNotFound, cache.access(io, name, .{}));
}

test "publication rejects changed raw content before transferring ownership" {
    const a = std.testing.allocator;
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    var cache = try tmp.dir.createDirPathOpen(io, "cache", .{ .open_options = .{ .iterate = true } });
    defer cache.close(io);
    const key: [64]u8 = @splat('c');
    const meta = try testMetadata(a, &key, "expected");
    defer a.free(meta);
    try tmp.dir.writeFile(io, .{ .sub_path = "compiler.air", .data = "tampered" });
    try std.testing.expectError(error.ExportContentMismatch, publish(a, io, tmp.dir, "compiler.air", cache, &key, meta, "expected"));
    try tmp.dir.access(io, "compiler.air", .{});
    try std.testing.expectError(error.FileNotFound, cache.access(io, &key ++ ".meta", .{}));
}

test "republication reuses verified bytes and retires only the prior payload" {
    const a = std.testing.allocator;
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    var cache = try tmp.dir.createDirPathOpen(io, "cache", .{ .open_options = .{ .iterate = true } });
    defer cache.close(io);
    const key: [64]u8 = @splat('d');
    for ([_][]const u8{ "old", "new", "new" }, 0..) |bytes, i| {
        const meta = try testMetadata(a, &key, bytes);
        defer a.free(meta);
        try tmp.dir.writeFile(io, .{ .sub_path = "compiler.air", .data = bytes });
        const method = try publish(a, io, tmp.dir, "compiler.air", cache, &key, meta, bytes);
        try std.testing.expectEqual(if (i == 2) Method.reused else Method.moved, method);
    }
    const old = try testMetadata(a, &key, "old");
    defer a.free(old);
    const name = try payloadName(a, &key, old);
    defer a.free(name);
    try std.testing.expectError(error.FileNotFound, cache.access(io, name, .{}));
}

test "payload lookup retains schema 3 compatibility and rejects path injection" {
    const a = std.testing.allocator;
    const key: [64]u8 = @splat('e');
    const meta = "schema=3\ncache_key=" ++ key ++ "\ndescriptor_sha256=" ++ key ++ "\n";
    const name = try payloadName(a, &key, meta);
    defer a.free(name);
    try std.testing.expectEqualStrings(&key ++ ".air", name);
    try std.testing.expectError(error.InvalidExportMetadata, payloadName(a, "../escape", meta));
    try std.testing.expectError(error.InvalidExportMetadata, payloadName(a, &key, "schema=4\ncache_key=" ++ key ++ "\ndescriptor_sha256=../escape\n"));
}

test "busy publication preserves run-owned input and committed state" {
    const io = std.testing.io;
    const a = std.testing.allocator;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    var cache = try tmp.dir.createDirPathOpen(io, "cache", .{ .open_options = .{ .iterate = true } });
    defer cache.close(io);
    const key: [64]u8 = @splat('f');
    const lock = try cache.createFile(io, &key ++ ".lock", .{ .lock = .exclusive });
    defer lock.close(io);
    try tmp.dir.writeFile(io, .{ .sub_path = "compiler.air", .data = "input" });
    const meta = try testMetadata(a, &key, "input");
    defer a.free(meta);
    try std.testing.expectError(error.WouldBlock, publish(a, io, tmp.dir, "compiler.air", cache, &key, meta, "input"));
    try tmp.dir.access(io, "compiler.air", .{});
    try std.testing.expectError(error.FileNotFound, cache.access(io, &key ++ ".meta", .{}));
}

test "schema 3 migration preserves hardlinked frozen inputs" {
    const io = std.testing.io;
    const a = std.testing.allocator;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    var cache = try tmp.dir.createDirPathOpen(io, "cache", .{ .open_options = .{ .iterate = true } });
    defer cache.close(io);
    const key: [64]u8 = @splat('a');
    const old_meta = try std.fmt.allocPrint(a, "schema=3\ncache_key={s}\ndescriptor_sha256={s}\n", .{ key, std.fmt.bytesToHex(digest("frozen"), .lower) });
    defer a.free(old_meta);
    try cache.writeFile(io, .{ .sub_path = &key ++ ".meta", .data = old_meta });
    try cache.writeFile(io, .{ .sub_path = &key ++ ".air", .data = "frozen" });
    try cache.hardLink(&key ++ ".air", tmp.dir, "frozen.air", io, .{});
    try tmp.dir.writeFile(io, .{ .sub_path = "compiler.air", .data = "new export" });
    const meta = try testMetadata(a, &key, "new export");
    defer a.free(meta);
    _ = try publish(a, io, tmp.dir, "compiler.air", cache, &key, meta, "new export");
    const frozen = try tmp.dir.readFileAlloc(io, "frozen.air", a, .limited(4096));
    defer a.free(frozen);
    try std.testing.expectEqualStrings("frozen", frozen);
    try std.testing.expectError(error.FileNotFound, cache.access(io, &key ++ ".air", .{}));
}

test "cross-filesystem publication copies atomically then removes raw and reuses content" {
    const io = std.testing.io;
    const a = std.testing.allocator;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    var shared = Io.Dir.openDirAbsolute(io, "/dev/shm", .{ .iterate = true }) catch return error.SkipZigTest;
    defer shared.close(io);
    var name_buffer: [128]u8 = undefined;
    const name = try std.fmt.bufPrint(&name_buffer, "zllvm-air-publication-{}-{s}", .{ std.os.linux.getpid(), tmp.sub_path });
    try shared.createDir(io, name, .default_dir);
    defer shared.deleteTree(io, name) catch {};
    var cache = try shared.openDir(io, name, .{ .iterate = true });
    defer cache.close(io);
    const key: [64]u8 = @splat('b');
    const bytes = "cross-filesystem descriptor";
    const meta = try testMetadata(a, &key, bytes);
    defer a.free(meta);
    for (0..2) |i| {
        try tmp.dir.writeFile(io, .{ .sub_path = "compiler.air", .data = bytes });
        try std.testing.expectEqual(if (i == 0) Method.copied else Method.reused, try publish(a, io, tmp.dir, "compiler.air", cache, &key, meta, bytes));
        try std.testing.expectError(error.FileNotFound, tmp.dir.access(io, "compiler.air", .{}));
    }
}
