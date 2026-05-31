const std = @import("std");

pub const TempDir = struct {
    path: []const u8,

    pub fn init(allocator: std.mem.Allocator, io: std.Io, prefix: []const u8) !TempDir {
        var cwd = std.Io.Dir.cwd();
        try cwd.createDirPath(io, "tmp");
        const path = try std.fmt.allocPrint(allocator, "tmp/{s}_{}", .{ prefix, std.os.linux.getpid() });
        errdefer allocator.free(path);
        cwd.deleteTree(io, path) catch {};
        try cwd.createDirPath(io, path);
        return .{ .path = path };
    }

    pub fn deinit(temp: TempDir, allocator: std.mem.Allocator, io: std.Io) void {
        std.Io.Dir.cwd().deleteTree(io, temp.path) catch {};
        allocator.free(temp.path);
    }

    pub fn join(temp: TempDir, allocator: std.mem.Allocator, name: []const u8) ![]const u8 {
        return std.fs.path.join(allocator, &.{ temp.path, name });
    }
};

pub fn safeStem(allocator: std.mem.Allocator, text: []const u8) ![]const u8 {
    const stem = try allocator.dupe(u8, text);
    for (stem) |*byte| {
        if (!std.ascii.isAlphanumeric(byte.*) and byte.* != '_' and byte.* != '.' and byte.* != '-') {
            byte.* = '_';
        }
    }
    return stem;
}

pub fn allocTempFile(
    allocator: std.mem.Allocator,
    temp: TempDir,
    stem_text: []const u8,
    suffix: []const u8,
) ![]const u8 {
    const stem = try safeStem(allocator, stem_text);
    defer allocator.free(stem);
    const name = try std.fmt.allocPrint(allocator, "{s}{s}", .{ stem, suffix });
    defer allocator.free(name);
    return temp.join(allocator, name);
}

pub fn runCapture(
    allocator: std.mem.Allocator,
    io: std.Io,
    argv: []const []const u8,
    label: []const u8,
) !std.process.RunResult {
    const result = try std.process.run(allocator, io, .{
        .argv = argv,
        .stdout_limit = .limited(128 * 1024 * 1024),
        .stderr_limit = .limited(32 * 1024 * 1024),
    });
    if (!termOk(result.term)) {
        try forwardCommandFailure(io, label, result);
    }
    return result;
}

pub fn freeRunResult(allocator: std.mem.Allocator, result: std.process.RunResult) void {
    allocator.free(result.stdout);
    allocator.free(result.stderr);
}

pub fn runToFile(
    allocator: std.mem.Allocator,
    io: std.Io,
    argv: []const []const u8,
    label: []const u8,
    output_path: []const u8,
) !void {
    const result = try runCapture(allocator, io, argv, label);
    defer freeRunResult(allocator, result);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = output_path, .data = result.stdout });
}

pub fn runExpectFailure(
    allocator: std.mem.Allocator,
    io: std.Io,
    argv: []const []const u8,
) !bool {
    const result = try std.process.run(allocator, io, .{
        .argv = argv,
        .stdout_limit = .limited(128 * 1024 * 1024),
        .stderr_limit = .limited(32 * 1024 * 1024),
    });
    defer freeRunResult(allocator, result);
    return !termOk(result.term);
}

pub fn normalizeToFile(
    allocator: std.mem.Allocator,
    io: std.Io,
    input_path: []const u8,
    output_path: []const u8,
) !void {
    const argv = [_][]const u8{ "zig", "run", "src/normalize_cli.zig", "--", input_path };
    try runToFile(allocator, io, &argv, "zig run src/normalize_cli.zig", output_path);
}

pub fn diffFiles(allocator: std.mem.Allocator, io: std.Io, expected: []const u8, actual: []const u8) !void {
    const argv = [_][]const u8{ "diff", "-u", expected, actual };
    const result = try std.process.run(allocator, io, .{
        .argv = &argv,
        .stdout_limit = .limited(128 * 1024 * 1024),
        .stderr_limit = .limited(32 * 1024 * 1024),
    });
    defer freeRunResult(allocator, result);
    if (termOk(result.term)) return;

    var stderr_buffer: [4096]u8 = undefined;
    var stderr_writer = std.Io.File.stderr().writer(io, &stderr_buffer);
    try stderr_writer.interface.writeAll(result.stdout);
    try stderr_writer.interface.writeAll(result.stderr);
    try stderr_writer.interface.flush();
    std.process.exit(1);
}

pub fn commandExists(allocator: std.mem.Allocator, io: std.Io, command: []const u8) !bool {
    const argv = [_][]const u8{ "which", command };
    const result = try std.process.run(allocator, io, .{
        .argv = &argv,
        .stdout_limit = .limited(1024 * 1024),
        .stderr_limit = .limited(1024 * 1024),
    });
    defer freeRunResult(allocator, result);
    return termOk(result.term);
}

pub fn fileExists(io: std.Io, path: []const u8) !bool {
    std.Io.Dir.cwd().access(io, path, .{}) catch |err| switch (err) {
        error.FileNotFound => return false,
        else => return err,
    };
    return true;
}

pub fn termOk(term: std.process.Child.Term) bool {
    return switch (term) {
        .exited => |code| code == 0,
        else => false,
    };
}

pub fn firstLine(text: []const u8) []const u8 {
    const end = std.mem.indexOfScalar(u8, text, '\n') orelse text.len;
    return std.mem.trimEnd(u8, text[0..end], "\r");
}

pub fn validationError(io: std.Io, comptime fmt: []const u8, args: anytype) !noreturn {
    var stderr_buffer: [4096]u8 = undefined;
    var stderr_writer = std.Io.File.stderr().writer(io, &stderr_buffer);
    try stderr_writer.interface.print(fmt, args);
    try stderr_writer.interface.flush();
    std.process.exit(1);
}

pub fn forwardCommandFailure(io: std.Io, label: []const u8, result: std.process.RunResult) !noreturn {
    var stderr_buffer: [4096]u8 = undefined;
    var stderr_writer = std.Io.File.stderr().writer(io, &stderr_buffer);
    try stderr_writer.interface.print("{s} failed\n", .{label});
    if (result.stderr.len != 0) {
        try stderr_writer.interface.writeAll(result.stderr);
    } else {
        try stderr_writer.interface.writeAll(result.stdout);
    }
    try stderr_writer.interface.flush();
    std.process.exit(1);
}
