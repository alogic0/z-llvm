const std = @import("std");
const regex = @import("zigrep_regex/regex/root.zig");

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

pub fn runCaptureEnv(
    allocator: std.mem.Allocator,
    io: std.Io,
    argv: []const []const u8,
    label: []const u8,
    environ_map: *const std.process.Environ.Map,
) !std.process.RunResult {
    const result = try std.process.run(allocator, io, .{
        .argv = argv,
        .environ_map = environ_map,
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

pub fn writeObjdumpTextSection(
    allocator: std.mem.Allocator,
    io: std.Io,
    object: []const u8,
    output_path: []const u8,
) !void {
    const argv = [_][]const u8{ "objdump", "-dr", object };
    const result = try runCapture(allocator, io, &argv, "objdump");
    defer freeRunResult(allocator, result);

    const marker = "Disassembly of section .text:";
    const start = std.mem.indexOf(u8, result.stdout, marker) orelse {
        try validationError(io, "objdump output missing .text disassembly for {s}\n", .{object});
    };
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = output_path, .data = result.stdout[start..] });
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

pub fn getEnvOwnedOrNull(allocator: std.mem.Allocator, environ: std.process.Environ, name: []const u8) !?[]const u8 {
    return environ.getAlloc(allocator, name) catch |err| switch (err) {
        error.EnvironmentVariableMissing => null,
        else => err,
    };
}

pub fn expectRegex(allocator: std.mem.Allocator, io: std.Io, path: []const u8, pattern: []const u8) !void {
    const contents = try std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(128 * 1024 * 1024));
    defer allocator.free(contents);

    const normalized_pattern = try normalizeRgPattern(allocator, pattern);
    defer allocator.free(normalized_pattern);

    var compiled = regex.compileRe(allocator, normalized_pattern, .{}) catch |err| {
        try validationError(io, "invalid regex pattern for {s}: {s}: {s}\n", .{ path, pattern, @errorName(err) });
    };
    defer compiled.deinit();

    if (try isMatchLinewise(&compiled, contents)) return;
    try validationError(io, "missing regex match in {s}: {s}\n", .{ path, pattern });
}

pub fn expectLiteral(allocator: std.mem.Allocator, io: std.Io, path: []const u8, needle: []const u8) !void {
    const contents = try std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(128 * 1024 * 1024));
    defer allocator.free(contents);
    if (std.mem.indexOf(u8, contents, needle) != null) return;
    try validationError(io, "missing literal match in {s}: {s}\n", .{ path, needle });
}

pub fn expectNoRegex(allocator: std.mem.Allocator, io: std.Io, path: []const u8, pattern: []const u8) !void {
    const contents = try std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(128 * 1024 * 1024));
    defer allocator.free(contents);

    const normalized_pattern = try normalizeRgPattern(allocator, pattern);
    defer allocator.free(normalized_pattern);

    var compiled = regex.compileRe(allocator, normalized_pattern, .{}) catch |err| {
        try validationError(io, "invalid regex pattern for {s}: {s}: {s}\n", .{ path, pattern, @errorName(err) });
    };
    defer compiled.deinit();

    if (!try isMatchLinewise(&compiled, contents)) return;
    try validationError(io, "unexpected regex match in {s}: {s}\n", .{ path, pattern });
}

fn isMatchLinewise(compiled: *const regex.Compiled, contents: []const u8) !bool {
    var start: usize = 0;
    while (start <= contents.len) {
        const newline = std.mem.indexOfScalarPos(u8, contents, start, '\n');
        const end = newline orelse contents.len;
        const line = std.mem.trimEnd(u8, contents[start..end], "\r");
        if (try compiled.isMatch(line)) return true;
        if (newline == null) break;
        start = end + 1;
    }
    return false;
}

fn normalizeRgPattern(allocator: std.mem.Allocator, pattern: []const u8) ![]u8 {
    var normalized: std.ArrayList(u8) = .empty;
    errdefer normalized.deinit(allocator);

    var index: usize = 0;
    while (index < pattern.len) {
        if (std.mem.startsWith(u8, pattern[index..], "[[:space:]]")) {
            try normalized.appendSlice(allocator, "\\s");
            index += "[[:space:]]".len;
        } else if (std.mem.startsWith(u8, pattern[index..], "[[:alpha:]]")) {
            try normalized.appendSlice(allocator, "[A-Za-z]");
            index += "[[:alpha:]]".len;
        } else if (std.mem.startsWith(u8, pattern[index..], "[[:digit:]]")) {
            try normalized.appendSlice(allocator, "\\d");
            index += "[[:digit:]]".len;
        } else if (std.mem.startsWith(u8, pattern[index..], "[[:alnum:]]")) {
            try normalized.appendSlice(allocator, "[A-Za-z0-9]");
            index += "[[:alnum:]]".len;
        } else if (std.mem.startsWith(u8, pattern[index..], "[[:xdigit:]]")) {
            try normalized.appendSlice(allocator, "[A-Fa-f0-9]");
            index += "[[:xdigit:]]".len;
        } else if (std.mem.startsWith(u8, pattern[index..], "[[:blank:]]")) {
            try normalized.appendSlice(allocator, "[ \\t]");
            index += "[[:blank:]]".len;
        } else {
            try normalized.append(allocator, pattern[index]);
            index += 1;
        }
    }

    return normalized.toOwnedSlice(allocator);
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
    // Forward bounded, clearly labeled tails of both streams so the failing
    // tool and its real diagnostic survive into the orchestrator log.
    const tail_limit = 8 * 1024;
    var stderr_buffer: [4096]u8 = undefined;
    var stderr_writer = std.Io.File.stderr().writer(io, &stderr_buffer);
    try stderr_writer.interface.print("command-failure label={s} term={any}\n", .{ label, result.term });
    if (result.stderr.len != 0) {
        const tail = outputTail(result.stderr, tail_limit);
        try stderr_writer.interface.print("command-failure-stderr label={s} bytes={} shown={}\n", .{ label, result.stderr.len, tail.len });
        try stderr_writer.interface.writeAll(tail);
        if (tail.len != 0 and tail[tail.len - 1] != '\n') try stderr_writer.interface.writeAll("\n");
    }
    if (result.stdout.len != 0) {
        const tail = outputTail(result.stdout, tail_limit);
        try stderr_writer.interface.print("command-failure-stdout label={s} bytes={} shown={}\n", .{ label, result.stdout.len, tail.len });
        try stderr_writer.interface.writeAll(tail);
        if (tail.len != 0 and tail[tail.len - 1] != '\n') try stderr_writer.interface.writeAll("\n");
    }
    try stderr_writer.interface.print("command-failure-end label={s}\n", .{label});
    try stderr_writer.interface.flush();
    std.process.exit(1);
}

fn outputTail(text: []const u8, limit: usize) []const u8 {
    if (text.len <= limit) return text;
    const cut = text[text.len - limit ..];
    // Start at the next full line so the tail never opens mid-line.
    const newline = std.mem.indexOfScalar(u8, cut, '\n') orelse return cut;
    return cut[newline + 1 ..];
}
