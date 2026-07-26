const std = @import("std");
const builtin = @import("builtin");
const identity = @import("identity.zig");
const manifest = @import("manifest.zig");

pub fn openOrCreateDir(io: std.Io, parent: std.Io.Dir, name: []const u8) !std.Io.Dir {
    if (std.mem.indexOfScalar(u8, name, '/') != null or
        std.mem.eql(u8, name, ".") or std.mem.eql(u8, name, ".."))
    {
        return error.UnsafePathComponent;
    }
    const created = created: {
        parent.createDir(io, name, .default_dir) catch |err| switch (err) {
            error.PathAlreadyExists => break :created false,
            else => return err,
        };
        break :created true;
    };
    if (parent.openDir(io, name, .{
        .access_sub_paths = true,
        .iterate = true,
        .follow_symlinks = false,
    })) |dir| {
        if (created) {
            try syncDirectory(dir);
            try syncDirectory(parent);
        }
        return dir;
    } else |err| return err;
}

pub fn openExistingDir(io: std.Io, parent: std.Io.Dir, name: []const u8) !std.Io.Dir {
    if (std.mem.indexOfScalar(u8, name, '/') != null) return error.UnsafePathComponent;
    return parent.openDir(io, name, .{
        .access_sub_paths = true,
        .iterate = true,
        .follow_symlinks = false,
    });
}

pub fn openPathNoFollow(
    io: std.Io,
    start: std.Io.Dir,
    relative: []const u8,
    create: bool,
) !std.Io.Dir {
    if (std.mem.eql(u8, relative, ".")) {
        return start.openDir(io, ".", .{
            .access_sub_paths = true,
            .iterate = true,
            .follow_symlinks = false,
        });
    }
    try manifest.validateRelativeKey(relative);
    var current = start;
    var current_owned = false;
    errdefer if (current_owned) current.close(io);
    var segments = std.mem.splitScalar(u8, relative, '/');
    while (segments.next()) |segment| {
        const next = if (create)
            try openOrCreateDir(io, current, segment)
        else
            try openExistingDir(io, current, segment);
        if (current_owned) current.close(io);
        current = next;
        current_owned = true;
    }
    return current;
}

pub fn writeCollisionFixtureAtomic(
    io: std.Io,
    dir: std.Io.Dir,
    basename: []const u8,
    bytes: []const u8,
    mode: u16,
) !void {
    if (!builtin.is_test) return error.TestOnlyOperation;
    if (std.mem.indexOfScalar(u8, basename, '/') != null) return error.UnsafePathComponent;
    var atomic = try dir.createFileAtomic(io, basename, .{
        .permissions = .fromMode(0o600),
        .replace = false,
    });
    defer atomic.deinit(io);
    try atomic.file.writeStreamingAll(io, bytes);
    try atomic.file.sync(io);
    try atomic.file.setPermissions(io, .fromMode(mode));
    try atomic.file.sync(io);
    try atomic.link(io);
    try syncDirectory(dir);
}

pub const PublishFault = enum {
    none,
    corrupt_incoming,
    corrupt_final,
};

pub fn publishVerifiedBytes(
    allocator: std.mem.Allocator,
    io: std.Io,
    dir: std.Io.Dir,
    basename: []const u8,
    bytes: []const u8,
    expected: identity.FileIdentity,
    fault: PublishFault,
) !bool {
    var atomic = try dir.createFileAtomic(io, basename, .{
        .permissions = .fromMode(0o600),
        .replace = false,
    });
    defer atomic.deinit(io);
    try atomic.file.writeStreamingAll(io, bytes);
    return finishVerifiedAtomic(allocator, io, dir, basename, &atomic, expected, fault);
}

pub fn publishVerifiedFile(
    allocator: std.mem.Allocator,
    io: std.Io,
    dir: std.Io.Dir,
    basename: []const u8,
    source: std.Io.File,
    expected: identity.FileIdentity,
    fault: PublishFault,
) !bool {
    var atomic = try dir.createFileAtomic(io, basename, .{
        .permissions = .fromMode(0o600),
        .replace = false,
    });
    defer atomic.deinit(io);
    try identity.copyFileContents(io, source, atomic.file);
    return finishVerifiedAtomic(allocator, io, dir, basename, &atomic, expected, fault);
}

pub fn finishVerifiedAtomic(
    allocator: std.mem.Allocator,
    io: std.Io,
    dir: std.Io.Dir,
    basename: []const u8,
    atomic: *std.Io.File.Atomic,
    expected: identity.FileIdentity,
    fault: PublishFault,
) !bool {
    try atomic.file.sync(io);
    if (fault == .corrupt_incoming) {
        try atomic.file.writePositionalAll(io, "!", 0);
        try atomic.file.sync(io);
    }
    try atomic.file.setPermissions(io, .fromMode(expected.mode));
    try atomic.file.sync(io);
    var incoming = try identity.identityOfOpenFile(allocator, io, atomic.file, expected.mode);
    defer incoming.deinit(allocator);
    if (!identity.sameFileIdentity(incoming, expected)) {
        return error.PrepublicationVerificationFailed;
    }

    var created = true;
    atomic.link(io) catch |err| switch (err) {
        error.PathAlreadyExists => created = false,
        else => return err,
    };
    try syncDirectory(dir);

    if (created and fault == .corrupt_final) {
        try dir.setFilePermissions(
            io,
            basename,
            .fromMode(0o600),
            .{ .follow_symlinks = false },
        );
        var final_for_fault = try dir.openFile(io, basename, .{
            .mode = .read_write,
            .allow_directory = false,
            .follow_symlinks = false,
        });
        defer final_for_fault.close(io);
        try final_for_fault.writePositionalAll(io, "!", 0);
        try final_for_fault.sync(io);
        try final_for_fault.setPermissions(io, .fromMode(expected.mode));
        try final_for_fault.sync(io);
    }

    const verified = identity.verifyRelativeFile(
        allocator,
        io,
        dir,
        basename,
        expected.mode,
    ) catch |err| {
        if (created) {
            dir.deleteFile(io, basename) catch {};
            syncDirectory(dir) catch {};
        }
        return err;
    };
    defer {
        var mutable = verified;
        mutable.deinit(allocator);
    }
    if (!identity.sameFileIdentity(verified, expected)) {
        if (created) {
            try dir.deleteFile(io, basename);
            try syncDirectory(dir);
        }
        return if (created)
            error.PostPublicationReadBackMismatch
        else
            error.UnequalExistingCollision;
    }
    try syncDirectory(dir);
    return created;
}

pub fn writeExclusive(
    io: std.Io,
    dir: std.Io.Dir,
    basename: []const u8,
    bytes: []const u8,
    mode: u16,
) !void {
    var file = try dir.createFile(io, basename, .{
        .exclusive = true,
        .permissions = .fromMode(0o600),
    });
    defer file.close(io);
    try file.writeStreamingAll(io, bytes);
    try file.sync(io);
    try file.setPermissions(io, .fromMode(mode));
    try file.sync(io);
    try syncDirectory(dir);
}

threadlocal var test_directory_sync_count: usize = 0;

pub fn resetTestDirectorySyncCount() !void {
    if (!builtin.is_test) return error.TestOnlyOperation;
    test_directory_sync_count = 0;
}

pub fn readTestDirectorySyncCount() !usize {
    if (!builtin.is_test) return error.TestOnlyOperation;
    return test_directory_sync_count;
}

pub fn syncDirectory(dir: std.Io.Dir) !void {
    switch (std.os.linux.errno(std.os.linux.fsync(dir.handle))) {
        .SUCCESS => {},
        else => |err| return std.posix.unexpectedErrno(err),
    }
    if (builtin.is_test) test_directory_sync_count += 1;
}
