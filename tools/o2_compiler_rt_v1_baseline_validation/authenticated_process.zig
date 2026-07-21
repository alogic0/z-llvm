const std = @import("std");
const process = @import("process.zig");
const inputs = @import("authenticated_inputs.zig");

pub const FileCommandResult = struct {
    term: std.process.Child.Term,
    stderr: []u8,
    output: inputs.FileIdentity,

    pub fn deinit(self: FileCommandResult, allocator: std.mem.Allocator) void {
        allocator.free(self.stderr);
    }
};

pub fn runAuthenticated(
    allocator: std.mem.Allocator,
    io: std.Io,
    subject: inputs.AuthenticatedSubject,
    command: process.FixedCommand,
    expected_status: u8,
    registered_worktrees: []const []const u8,
) !std.process.RunResult {
    if (!std.mem.eql(u8, subject.path, command.executable) or command.argv.len == 0 or
        !std.mem.eql(u8, command.argv[0], subject.path)) return error.WrongExecutable;
    try inputs.requireSubjectStable(io, subject, registered_worktrees);
    const result = try process.runBounded(allocator, io, command);
    errdefer {
        allocator.free(result.stdout);
        allocator.free(result.stderr);
    }
    const captured = process.CapturedResult{
        .termination = process.processTermination(result.term),
        .stdout = result.stdout,
        .stderr = result.stderr,
        .stdout_complete = true,
        .stderr_complete = true,
    };
    if (captured.stdout.len > process.capture_max or captured.stderr.len > process.capture_max)
        return error.ChildOutputOverflow;
    switch (captured.termination) {
        .exited => |status| if (status != expected_status) return error.ChildFailed,
        else => return error.ChildFailed,
    }
    try inputs.requireSubjectStable(io, subject, registered_worktrees);
    return result;
}

pub fn runAuthenticatedToFile(
    allocator: std.mem.Allocator,
    io: std.Io,
    subject: inputs.AuthenticatedSubject,
    command: process.FixedCommand,
    output_path: []const u8,
    output_limit: u64,
    expected_status: u8,
    registered_worktrees: []const []const u8,
) !FileCommandResult {
    if (!std.mem.eql(u8, subject.path, command.executable) or command.argv.len == 0 or
        !std.mem.eql(u8, command.argv[0], subject.path)) return error.WrongExecutable;
    try inputs.requireSubjectStable(io, subject, registered_worktrees);
    var environment = std.process.Environ.Map.init(allocator);
    defer environment.deinit();
    for (command.environment) |entry| try environment.put(entry.name, entry.value);
    var output = try std.Io.Dir.createFileAbsolute(io, output_path, .{
        .read = true,
        .exclusive = true,
        .truncate = false,
        .permissions = .fromMode(0o444),
    });
    var output_open = true;
    defer if (output_open) output.close(io);
    var child = std.process.spawn(io, .{
        .argv = command.argv,
        .cwd = .{ .path = command.cwd },
        .environ_map = &environment,
        .stdin = .ignore,
        .stdout = .{ .file = output },
        .stderr = .pipe,
    }) catch return error.SpawnFailed;
    defer child.kill(io);
    var stderr_buffer: [4096]u8 = undefined;
    var stderr_reader = child.stderr.?.reader(io, &stderr_buffer);
    const stderr = stderr_reader.interface.allocRemaining(allocator, .limited(process.capture_max)) catch |failure| switch (failure) {
        error.StreamTooLong => return error.ChildOutputOverflow,
        error.OutOfMemory => return error.OutOfMemory,
        else => return error.IncompleteCapture,
    };
    errdefer allocator.free(stderr);
    const term = try child.wait(io);
    switch (term) {
        .exited => |status| if (status != expected_status) return error.ChildFailed,
        else => return error.ChildFailed,
    }
    try output.sync(io);
    const stat = try output.stat(io);
    if (stat.kind != .file or stat.size == 0 or stat.size > output_limit) return error.FileCapExceeded;
    output.close(io);
    output_open = false;
    const identity = try inputs.observeFile(io, output_path, false, output_limit, registered_worktrees);
    try inputs.requireSubjectStable(io, subject, registered_worktrees);
    return .{ .term = term, .stderr = stderr, .output = identity };
}

pub fn authenticateGeneratedSubject(io: std.Io, path: []const u8, registered_worktrees: []const []const u8) !inputs.AuthenticatedSubject {
    return .{
        .path = path,
        .identity = try inputs.observeFile(io, path, true, inputs.maximum_artifact_bytes, registered_worktrees),
    };
}

pub fn expectCleanOutput(result: std.process.RunResult) !void {
    try process.validateCapturedResult(.{
        .termination = process.processTermination(result.term),
        .stdout = result.stdout,
        .stderr = result.stderr,
        .stdout_complete = true,
        .stderr_complete = true,
    });
    if (result.stderr.len != 0) return error.ResultDrift;
}

pub fn expectSuccessfulBuildOutput(result: std.process.RunResult) !void {
    try process.validateCapturedResult(.{
        .termination = process.processTermination(result.term),
        .stdout = result.stdout,
        .stderr = result.stderr,
        .stdout_complete = true,
        .stderr_complete = true,
    });
    if (result.stdout.len != 0 or !std.mem.startsWith(u8, result.stderr, "Build Summary: ") or
        result.stderr[result.stderr.len - 1] != '\n') return error.ResultDrift;
}

pub fn runZigVersion(
    allocator: std.mem.Allocator,
    io: std.Io,
    zig: inputs.AuthenticatedSubject,
    cwd: []const u8,
    registered_worktrees: []const []const u8,
) !void {
    const environment = process.fixedEnvironment("/nonexistent-inbox206cy-home", "/nonexistent-inbox206cy-tmp");
    const argv = [_][]const u8{ zig.path, "version" };
    const result = try runAuthenticated(allocator, io, zig, .{
        .executable = zig.path,
        .argv = &argv,
        .environment = &environment,
        .cwd = cwd,
    }, 0, registered_worktrees);
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);
    try expectCleanOutput(result);
    const portable = zig.portable_tool orelse return error.SubjectAuthorityMismatch;
    if (portable.role != .zig) return error.SubjectAuthorityMismatch;
    const version = portable.version orelse return error.SubjectAuthorityMismatch;
    if (!std.mem.eql(u8, version, inputs.expected_zig_version) or
        result.stdout.len != version.len + 1 or result.stdout[result.stdout.len - 1] != '\n' or
        !std.mem.eql(u8, result.stdout[0..version.len], version)) return error.ZigVersionMismatch;
}

test "successful build output is exact and process spawn fails closed" {
    var empty: [0]u8 = .{};
    var summary = "Build Summary: 3/3 steps succeeded\ninstall success\n".*;
    const valid = std.process.RunResult{ .term = .{ .exited = 0 }, .stdout = &empty, .stderr = &summary };
    try expectSuccessfulBuildOutput(valid);
    var invalid = valid;
    invalid.stderr = &empty;
    try std.testing.expectError(error.ResultDrift, expectSuccessfulBuildOutput(invalid));
    const environment = [_]process.EnvironmentEntry{.{ .name = "LC_ALL", .value = "C" }};
    const argv = [_][]const u8{ "/definitely-absent-inbox206cy-executable", "version" };
    try std.testing.expectError(error.SpawnFailed, process.runBounded(std.testing.allocator, std.testing.io, .{
        .executable = argv[0],
        .argv = &argv,
        .environment = &environment,
        .cwd = "/home/oleg/prog/z_llvm",
    }));
}
