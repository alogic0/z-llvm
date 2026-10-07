const std = @import("std");

pub const capture_max: usize = 4 * 1024 * 1024;

pub const EnvironmentEntry = struct { name: []const u8, value: []const u8 };

pub const ProcessRequest = struct {
    executable: []const u8,
    argv: []const []const u8,
    environment: []const EnvironmentEntry,
    cwd: []const u8,
};

pub const FixedCommand = struct {
    executable: []const u8,
    argv: []const []const u8,
    environment: []const EnvironmentEntry,
    cwd: []const u8,
};

pub const Termination = union(enum) {
    exited: u8,
    signal: u32,
    stopped: u32,
    unknown: u32,
};

pub const CapturedResult = struct {
    termination: Termination,
    stdout: []const u8,
    stderr: []const u8,
    stdout_complete: bool,
    stderr_complete: bool,
};

pub fn validateCanonicalAbsolute(path: []const u8) !void {
    if (!std.fs.path.isAbsolute(path)) return error.RelativePath;
    if (path.len == 0 or std.mem.indexOfScalar(u8, path, 0) != null)
        return error.NonCanonicalPath;
    if (path.len > 1 and path[path.len - 1] == '/') return error.NonCanonicalPath;
    var components = std.mem.splitScalar(u8, path[1..], '/');
    while (components.next()) |component| {
        if (component.len == 0 or std.mem.eql(u8, component, ".") or
            std.mem.eql(u8, component, "..")) return error.NonCanonicalPath;
    }
}

pub fn validateFixedCommand(request: ProcessRequest, expected: FixedCommand) !void {
    try validateCanonicalAbsolute(request.executable);
    try validateCanonicalAbsolute(request.cwd);
    if (!std.mem.eql(u8, request.executable, expected.executable)) return error.WrongExecutable;
    if (!std.mem.eql(u8, request.cwd, expected.cwd)) return error.WrongWorkingDirectory;
    if (!equalStringSlices(request.argv, expected.argv)) return error.WrongArguments;
    if (request.environment.len != expected.environment.len) return error.WrongEnvironment;
    for (request.environment, expected.environment) |actual, wanted| {
        if (!std.mem.eql(u8, actual.name, wanted.name) or
            !std.mem.eql(u8, actual.value, wanted.value) or
            std.mem.indexOfScalar(u8, actual.name, 0) != null or
            std.mem.indexOfScalar(u8, actual.value, 0) != null)
        {
            return error.WrongEnvironment;
        }
    }
}

fn equalStringSlices(a: []const []const u8, b: []const []const u8) bool {
    if (a.len != b.len) return false;
    for (a, b) |left, right| if (!std.mem.eql(u8, left, right)) return false;
    return true;
}

pub fn validateCapturedResult(result: CapturedResult) !void {
    if (!result.stdout_complete or !result.stderr_complete) return error.IncompleteCapture;
    if (result.stdout.len > capture_max or result.stderr.len > capture_max)
        return error.ChildOutputOverflow;
    switch (result.termination) {
        .exited => |status| if (status != 0) return error.ChildFailed,
        else => return error.ChildFailed,
    }
}

pub fn requireConsistentResult(a: CapturedResult, b: CapturedResult) !void {
    try validateCapturedResult(a);
    try validateCapturedResult(b);
    if (!std.meta.eql(a.termination, b.termination) or
        !std.mem.eql(u8, a.stdout, b.stdout) or
        !std.mem.eql(u8, a.stderr, b.stderr)) return error.InconsistentResult;
}

pub fn runBounded(
    allocator: std.mem.Allocator,
    io: std.Io,
    command: FixedCommand,
) !std.process.RunResult {
    var environment = std.process.Environ.Map.init(allocator);
    defer environment.deinit();
    for (command.environment) |entry| environment.put(entry.name, entry.value) catch
        return error.OutOfMemory;
    return std.process.run(allocator, io, .{
        .argv = command.argv,
        .cwd = .{ .path = command.cwd },
        .environ_map = &environment,
        .stdout_limit = .limited(capture_max),
        .stderr_limit = .limited(capture_max),
    }) catch |failure| switch (failure) {
        error.OutOfMemory => return error.OutOfMemory,
        error.StreamTooLong => return error.ChildOutputOverflow,
        else => return error.SpawnFailed,
    };
}

pub fn processTermination(term: std.process.Child.Term) Termination {
    return switch (term) {
        .exited => |status| .{ .exited = status },
        .signal => |signal| .{ .signal = @intFromEnum(signal) },
        .stopped => |signal| .{ .stopped = @intFromEnum(signal) },
        .unknown => |status| .{ .unknown = status },
    };
}

pub fn fixedEnvironment(home: []const u8, temporary: []const u8) [6]EnvironmentEntry {
    return .{
        .{ .name = "HOME", .value = home },
        .{ .name = "TMPDIR", .value = temporary },
        .{ .name = "LANG", .value = "C" },
        .{ .name = "LC_ALL", .value = "C" },
        .{ .name = "TZ", .value = "UTC0" },
        .{ .name = "SOURCE_DATE_EPOCH", .value = "0" },
    };
}

pub fn fixedCoverageEnvironment(
    home: []const u8,
    temporary: []const u8,
    channel: []const u8,
) [7]EnvironmentEntry {
    return .{
        .{ .name = "HOME", .value = home },
        .{ .name = "TMPDIR", .value = temporary },
        .{ .name = "LANG", .value = "C" },
        .{ .name = "LC_ALL", .value = "C" },
        .{ .name = "TZ", .value = "UTC0" },
        .{ .name = "SOURCE_DATE_EPOCH", .value = "0" },
        .{ .name = "ZLLVM_CALL_COVERAGE_PATH", .value = channel },
    };
}

pub fn fixedGitEnvironment() [10]EnvironmentEntry {
    return .{
        .{ .name = "HOME", .value = "/nonexistent-inbox206cy-home" },
        .{ .name = "LANG", .value = "C" },
        .{ .name = "LC_ALL", .value = "C" },
        .{ .name = "TZ", .value = "UTC0" },
        .{ .name = "GIT_OPTIONAL_LOCKS", .value = "0" },
        .{ .name = "GIT_CONFIG_NOSYSTEM", .value = "1" },
        .{ .name = "GIT_CONFIG_SYSTEM", .value = "/dev/null" },
        .{ .name = "GIT_CONFIG_GLOBAL", .value = "/dev/null" },
        .{ .name = "GIT_TERMINAL_PROMPT", .value = "0" },
        .{ .name = "SOURCE_DATE_EPOCH", .value = "0" },
    };
}

test "fixed command rejects executable argv environment and cwd drift" {
    const argv = [_][]const u8{ "/zig", "version" };
    const environment = [_]EnvironmentEntry{.{ .name = "LC_ALL", .value = "C" }};
    const expected = FixedCommand{ .executable = "/zig", .argv = &argv, .environment = &environment, .cwd = "/repo" };
    var request = ProcessRequest{ .executable = "/zig", .argv = &argv, .environment = &environment, .cwd = "/repo" };
    try validateFixedCommand(request, expected);
    request.executable = "zig";
    try std.testing.expectError(error.RelativePath, validateFixedCommand(request, expected));
    request = .{ .executable = "/other", .argv = &argv, .environment = &environment, .cwd = "/repo" };
    try std.testing.expectError(error.WrongExecutable, validateFixedCommand(request, expected));
    const wrong_argv = [_][]const u8{ "/zig", "env" };
    request = .{ .executable = "/zig", .argv = &wrong_argv, .environment = &environment, .cwd = "/repo" };
    try std.testing.expectError(error.WrongArguments, validateFixedCommand(request, expected));
    const wrong_environment = [_]EnvironmentEntry{.{ .name = "LC_ALL", .value = "en_US" }};
    request = .{ .executable = "/zig", .argv = &argv, .environment = &wrong_environment, .cwd = "/repo" };
    try std.testing.expectError(error.WrongEnvironment, validateFixedCommand(request, expected));
    request = .{ .executable = "/zig", .argv = &argv, .environment = &environment, .cwd = "/other" };
    try std.testing.expectError(error.WrongWorkingDirectory, validateFixedCommand(request, expected));
}

test "capture validates success overflow status abnormal completeness and consistency" {
    const success = CapturedResult{ .termination = .{ .exited = 0 }, .stdout = "ok\n", .stderr = "", .stdout_complete = true, .stderr_complete = true };
    try validateCapturedResult(success);
    var bad = success;
    bad.termination = .{ .exited = 1 };
    try std.testing.expectError(error.ChildFailed, validateCapturedResult(bad));
    bad.termination = .{ .signal = 9 };
    try std.testing.expectError(error.ChildFailed, validateCapturedResult(bad));
    bad = success;
    bad.stdout_complete = false;
    try std.testing.expectError(error.IncompleteCapture, validateCapturedResult(bad));
    const oversized = try std.testing.allocator.alloc(u8, capture_max + 1);
    defer std.testing.allocator.free(oversized);
    bad = success;
    bad.stdout = oversized;
    try std.testing.expectError(error.ChildOutputOverflow, validateCapturedResult(bad));
    bad = success;
    bad.stdout = "different\n";
    try std.testing.expectError(error.InconsistentResult, requireConsistentResult(success, bad));
}

test "one harmless absolute Zig command uses bounded closed capture" {
    const environment = [_]EnvironmentEntry{
        .{ .name = "LANG", .value = "C" },
        .{ .name = "LC_ALL", .value = "C" },
        .{ .name = "TZ", .value = "UTC0" },
    };
    const argv = [_][]const u8{ "/home/oleg/.zig/0.17.0/files/zig", "version" };
    const result = try runBounded(std.testing.allocator, std.testing.io, .{
        .executable = argv[0],
        .argv = &argv,
        .environment = &environment,
        .cwd = "/home/oleg/prog/z_llvm",
    });
    defer std.testing.allocator.free(result.stdout);
    defer std.testing.allocator.free(result.stderr);
    try std.testing.expectEqualStrings("0.17.0\n", result.stdout);
    try std.testing.expectEqual(@as(usize, 0), result.stderr.len);
}
