const std = @import("std");
const common = @import("tool_common.zig");

const commands = [_]Command{
    .{ .label = "zig build test", .argv = &.{ "zig", "build", "test" } },
    .{ .label = "tools/compare_opt.zig", .argv = &.{ "zig", "run", "tools/compare_opt.zig" } },
    .{ .label = "tools/lint_zig_ir_manifest.zig", .argv = &.{ "zig", "run", "tools/lint_zig_ir_manifest.zig" } },
    .{ .label = "tools/run_zig_corpus.zig", .argv = &.{ "zig", "run", "tools/run_zig_corpus.zig" } },
    .{ .label = "tools/run_handoff_validation.zig", .argv = &.{ "zig", "run", "tools/run_handoff_validation.zig" } },
    .{ .label = "tools/run_generated_scalar_diff.zig", .argv = &.{ "zig", "run", "tools/run_generated_scalar_diff.zig" } },
    .{ .label = "zig build release-pipeline-policy", .argv = &.{ "zig", "build", "release-pipeline-policy" } },
};

const Command = struct {
    label: []const u8,
    argv: []const []const u8,
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);

    for (commands) |command| {
        const result = try common.runCapture(allocator, io, command.argv, command.label);
        defer common.freeRunResult(allocator, result);
        try stdout_writer.interface.writeAll(result.stdout);
        try stdout_writer.interface.flush();
    }

    try stdout_writer.interface.writeAll("ok readiness checks\n");
    try stdout_writer.interface.flush();
}
