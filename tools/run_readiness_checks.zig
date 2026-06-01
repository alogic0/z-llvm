const std = @import("std");
const common = @import("tool_common.zig");

const commands = [_]Command{
    .{ .label = "zig build test", .argv = &.{ "zig", "build", "test" } },
    .{ .label = "scripts/compare_opt.sh", .argv = &.{ "bash", "scripts/compare_opt.sh" } },
    .{ .label = "scripts/lint_zig_ir_manifest.sh", .argv = &.{ "bash", "scripts/lint_zig_ir_manifest.sh" } },
    .{ .label = "scripts/run_zig_corpus.sh", .argv = &.{ "bash", "scripts/run_zig_corpus.sh" } },
    .{ .label = "scripts/run_handoff_validation.sh", .argv = &.{ "bash", "scripts/run_handoff_validation.sh" } },
    .{ .label = "scripts/run_generated_scalar_diff.sh", .argv = &.{ "bash", "scripts/run_generated_scalar_diff.sh" } },
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
