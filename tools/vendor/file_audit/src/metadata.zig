const std = @import("std");
const linux = std.os.linux;
const Io = std.Io;

pub const Kind = enum { file, directory, symlink, other };
pub const Metadata = struct {
    device: u64,
    inode: u64,
    links: u64,
    size: u64,
    allocated_bytes: u64,
    mode: u32,
    uid: u32,
    gid: u32,
    mtime_ns: i64,
    ctime_ns: i64,
    kind: Kind,

    /// Includes link count and ctime: a hardlink operation invalidates a snapshot.
    /// Reading atime is deliberately excluded.
    pub fn eql(a: Metadata, b: Metadata) bool {
        return std.meta.eql(a, b);
    }
};

pub const Identity = struct { device: u64, inode: u64 };
pub fn identity(m: Metadata) Identity {
    return .{ .device = m.device, .inode = m.inode };
}

fn result(code: usize) !void {
    return switch (linux.errno(code)) {
        .SUCCESS => {},
        .NOENT => error.FileNotFound,
        .ACCES, .PERM => error.AccessDenied,
        .LOOP => error.SymlinkPath,
        .NOTDIR => error.NotDir,
        .NAMETOOLONG => error.NameTooLong,
        .NOSYS, .OPNOTSUPP => error.UnsupportedFilesystem,
        else => error.FilesystemError,
    };
}

fn ns(t: linux.statx_timestamp) !i64 {
    return std.math.cast(i64, @as(i128, t.sec) * 1_000_000_000 + t.nsec) orelse error.TimestampOutOfRange;
}

fn statAt(fd: linux.fd_t, name: [:0]const u8, flags: u32) !Metadata {
    if (@import("builtin").os.tag != .linux) @compileError("zig-file-audit currently supports Linux");
    var st: linux.Statx = undefined;
    try result(linux.statx(fd, name, flags, linux.STATX.BASIC_STATS, &st));
    const requested: u32 = @bitCast(linux.STATX.BASIC_STATS);
    if (@as(u32, @bitCast(st.mask)) & requested != requested) return error.IncompleteMetadata;
    return .{
        .device = (@as(u64, st.dev_major) << 32) | st.dev_minor,
        .inode = st.ino,
        .links = st.nlink,
        .size = st.size,
        .allocated_bytes = try std.math.mul(u64, st.blocks, 512),
        .mode = st.mode & 0o7777,
        .uid = st.uid,
        .gid = st.gid,
        .mtime_ns = try ns(st.mtime),
        .ctime_ns = try ns(st.ctime),
        .kind = switch (st.mode & 0o170000) {
            0o100000 => .file,
            0o040000 => .directory,
            0o120000 => .symlink,
            else => .other,
        },
    };
}

/// Only a single directory entry name is accepted. No ancestor is dereferenced.
pub fn child(allocator: std.mem.Allocator, dir: Io.Dir, name: []const u8) !Metadata {
    try validateName(name);
    const z = try allocator.dupeSentinel(u8, name, 0);
    defer allocator.free(z);
    return statAt(dir.handle, z, linux.AT.SYMLINK_NOFOLLOW);
}

pub fn descriptor(fd: linux.fd_t) !Metadata {
    return statAt(fd, "", linux.AT.EMPTY_PATH | linux.AT.SYMLINK_NOFOLLOW);
}

/// Linux mount identity, including bind mounts on the same device. This is a
/// current-namespace observation, not a persistent identifier across boots.
pub fn mountId(fd: linux.fd_t) !u64 {
    var st: linux.Statx = undefined;
    const request: linux.STATX = .{ .MNT_ID = true };
    try result(linux.statx(fd, "", linux.AT.EMPTY_PATH | linux.AT.SYMLINK_NOFOLLOW, request, &st));
    if (!st.mask.MNT_ID) return error.IncompleteMetadata;
    return st.mnt_id;
}

fn validateName(name: []const u8) !void {
    if (name.len == 0 or std.mem.eql(u8, name, ".") or std.mem.eql(u8, name, "..") or std.mem.indexOfAny(u8, name, "/\x00") != null) return error.InvalidName;
}

/// Opens every component relative to an already opened directory, without
/// following symlinks. The caller owns the returned descriptor.
pub fn openRoot(io: Io, absolute: []const u8) !Io.Dir {
    if (!std.fs.path.isAbsolute(absolute) or std.mem.indexOfScalar(u8, absolute, 0) != null) return error.InvalidRoot;
    var dir = try Io.Dir.openDirAbsolute(io, "/", .{ .iterate = true, .follow_symlinks = false });
    errdefer dir.close(io);
    var parts = std.mem.tokenizeScalar(u8, absolute, '/');
    while (parts.next()) |part| {
        try validateName(part);
        const next = try dir.openDir(io, part, .{ .iterate = true, .follow_symlinks = false });
        dir.close(io);
        dir = next;
    }
    return dir;
}

/// Hash an exact observed regular file through a no-follow descriptor. Rejects
/// replacement, metadata changes and non-regular files before or during reads.
/// O_NONBLOCK prevents a replacement FIFO from blocking the open operation.
fn openObserved(allocator: std.mem.Allocator, io: Io, dir: Io.Dir, name: []const u8, expected: Metadata) !Io.File {
    try validateName(name);
    if (expected.kind != .file) return error.NotRegularFile;
    if (!expected.eql(try child(allocator, dir, name))) return error.FileChanged;
    const z = try allocator.dupeSentinel(u8, name, 0);
    defer allocator.free(z);
    const fd = linux.openat(dir.handle, z, .{ .ACCMODE = .RDONLY, .CLOEXEC = true, .NOFOLLOW = true, .NONBLOCK = true, .NOCTTY = true }, 0);
    try result(fd);
    const file: Io.File = .{ .handle = @intCast(fd), .flags = .{ .nonblocking = true } };
    errdefer file.close(io);
    if (!expected.eql(try descriptor(file.handle))) return error.FileChanged;
    return file;
}

/// Read an exact observed regular file, up to max_bytes, without following
/// symlinks or blocking on a replacement FIFO. The caller owns the bytes.
/// Descriptor and pathname metadata must match before and after the read.
pub fn readFile(allocator: std.mem.Allocator, io: Io, dir: Io.Dir, name: []const u8, expected: Metadata, max_bytes: usize) ![]u8 {
    if (expected.kind != .file) return error.NotRegularFile;
    if (expected.size > max_bytes) return error.FileTooLarge;
    const file = try openObserved(allocator, io, dir, name, expected);
    defer file.close(io);
    var buffer: [65536]u8 = undefined;
    var reader = file.readerStreaming(io, &buffer);
    const bytes = try reader.interface.allocRemaining(allocator, .limited(max_bytes));
    errdefer allocator.free(bytes);
    if (bytes.len != expected.size or !expected.eql(try descriptor(file.handle)) or !expected.eql(try child(allocator, dir, name))) return error.FileChanged;
    return bytes;
}

/// Hash an exact observed regular file through the same guarded descriptor.
pub fn hashFile(allocator: std.mem.Allocator, io: Io, dir: Io.Dir, name: []const u8, expected: Metadata) ![32]u8 {
    const file = try openObserved(allocator, io, dir, name, expected);
    defer file.close(io);
    var buffer: [65536]u8 = undefined;
    var reader = file.readerStreaming(io, &buffer);
    var hash = std.crypto.hash.sha2.Sha256.init(.{});
    while (true) {
        const bytes = reader.interface.peekGreedy(1) catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };
        hash.update(bytes);
        reader.interface.toss(bytes.len);
    }
    if (!expected.eql(try descriptor(file.handle)) or !expected.eql(try child(allocator, dir, name))) return error.FileChanged;
    return hash.finalResult();
}
