const std = @import("std");
const common = @import("tool_common.zig");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    const zig_source_env = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "ZIG_SOURCE_DIR");
    defer if (zig_source_env) |value| allocator.free(value);
    const zig_source_dir = zig_source_env orelse "../ziglang";

    const zig_emitter_env = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "ZIG_EMITTER");
    defer if (zig_emitter_env) |value| allocator.free(value);
    const default_zig_emitter = try std.fs.path.join(allocator, &.{ zig_source_dir, "build/stage4/bin/zig" });
    defer allocator.free(default_zig_emitter);
    const zig_emitter = zig_emitter_env orelse default_zig_emitter;

    std.Io.Dir.cwd().access(io, zig_emitter, .{ .execute = true }) catch {
        try common.validationError(io, "missing executable Zig emitter: {s}\n", .{zig_emitter});
    };

    const head_argv = [_][]const u8{ "git", "-C", zig_source_dir, "rev-parse", "--short=9", "HEAD" };
    const head_result = try common.runCapture(allocator, io, &head_argv, "git rev-parse Zig source HEAD");
    defer common.freeRunResult(allocator, head_result);
    const head_rev = std.mem.trim(u8, head_result.stdout, " \t\r\n");

    const version_argv = [_][]const u8{ zig_emitter, "version" };
    const version_result = try common.runCapture(allocator, io, &version_argv, "stage4 Zig version");
    defer common.freeRunResult(allocator, version_result);
    const version = std.mem.trim(u8, version_result.stdout, " \t\r\n");

    if (std.mem.indexOf(u8, version, head_rev) == null) {
        try common.validationError(
            io,
            "stage4 Zig version does not match {s} HEAD\n  HEAD:    {s}\n  version: {s}\n",
            .{ zig_source_dir, head_rev, version },
        );
    }

    var stdout_buffer: [512]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    try stdout_writer.interface.print("ok stage4 emitter {s} matches {s} HEAD {s}\n", .{ version, zig_source_dir, head_rev });
    try stdout_writer.interface.flush();
}
