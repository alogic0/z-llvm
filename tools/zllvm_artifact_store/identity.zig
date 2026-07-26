const std = @import("std");
const digest = @import("digest.zig");

pub const FileIdentity = struct {
    sha256: [64]u8,
    bytes: u64,
    mode: u16,
    key: []u8,

    pub fn deinit(identity: *FileIdentity, allocator: std.mem.Allocator) void {
        allocator.free(identity.key);
        identity.* = undefined;
    }
};

pub const SnapshotIdentity = struct {
    archive: FileIdentity,
    constituent: FileIdentity,
    member_keys: [][]u8,

    pub fn deinit(snapshot: *SnapshotIdentity, allocator: std.mem.Allocator) void {
        snapshot.archive.deinit(allocator);
        snapshot.constituent.deinit(allocator);
        for (snapshot.member_keys) |key| allocator.free(key);
        allocator.free(snapshot.member_keys);
        snapshot.* = undefined;
    }
};

pub fn sameFileIdentity(a: FileIdentity, b: FileIdentity) bool {
    return std.mem.eql(u8, &a.sha256, &b.sha256) and
        a.bytes == b.bytes and
        a.mode == b.mode;
}

pub fn verifyRelativeFile(
    allocator: std.mem.Allocator,
    io: std.Io,
    dir: std.Io.Dir,
    basename: []const u8,
    expected_mode: u16,
) !FileIdentity {
    var file = try dir.openFile(io, basename, .{
        .allow_directory = false,
        .follow_symlinks = false,
    });
    defer file.close(io);
    return identityOfOpenFile(allocator, io, file, expected_mode);
}

pub fn identityOfOpenFile(
    allocator: std.mem.Allocator,
    io: std.Io,
    file: std.Io.File,
    expected_mode: u16,
) !FileIdentity {
    var identity = try identityOfOpenFileAnyMode(allocator, io, file);
    errdefer identity.deinit(allocator);
    if (identity.mode != expected_mode) return error.ModeMismatch;
    return identity;
}

pub fn identityOfOpenFileAnyMode(
    allocator: std.mem.Allocator,
    io: std.Io,
    file: std.Io.File,
) !FileIdentity {
    const stat = try file.stat(io);
    if (stat.kind != .file) return error.NotRegularFile;
    const actual_mode: u16 = @intCast(stat.permissions.toMode() & 0o7777);
    var hasher = digest.Sha256.init(.{});
    var offset: u64 = 0;
    var buffer: [64 * 1024]u8 = undefined;
    while (true) {
        const count = try file.readPositional(io, &.{&buffer}, offset);
        if (count == 0) break;
        hasher.update(buffer[0..count]);
        offset += count;
    }
    var hash: [digest.Sha256.digest_length]u8 = undefined;
    hasher.final(&hash);
    return .{
        .sha256 = std.fmt.bytesToHex(hash, .lower),
        .bytes = offset,
        .mode = actual_mode,
        .key = try allocator.dupe(u8, "-"),
    };
}

pub fn copyFileContents(io: std.Io, source: std.Io.File, destination: std.Io.File) !void {
    var offset: u64 = 0;
    var buffer: [64 * 1024]u8 = undefined;
    while (true) {
        const count = try source.readPositional(io, &.{&buffer}, offset);
        if (count == 0) break;
        try destination.writePositionalAll(io, buffer[0..count], offset);
        offset += count;
    }
}
