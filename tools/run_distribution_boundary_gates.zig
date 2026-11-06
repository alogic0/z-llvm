const std = @import("std");
const common = @import("tool_common.zig");

const Gate = struct {
    tool: []const u8,
    target: ?[]const u8 = null,
};

const gates = [_]Gate{
    .{ .tool = "tools/run_compilation_contract.zig" },
    .{ .tool = "tools/run_distribution_linker_boundary.zig" },
    .{ .tool = "tools/run_distribution_releasesmall_boundary_m3.zig" },
    .{ .tool = "tools/run_distribution_debug_unwind_boundary.zig" },
    .{ .tool = "tools/run_distribution_debug_unwind_boundary.zig", .target = "x86_64-unknown-linux-musl" },
    .{ .tool = "tools/run_distribution_aarch64_object_boundary.zig", .target = "aarch64-unknown-linux-gnu" },
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    try stdout_writer.interface.writeAll("distribution boundary gates\n");
    try stdout_writer.interface.flush();

    for (gates) |gate| {
        if (gate.target) |target| {
            const target_assignment = try std.fmt.allocPrint(allocator, "TARGET={s}", .{target});
            defer allocator.free(target_assignment);
            const argv = [_][]const u8{ "env", target_assignment, "zig", "run", gate.tool };
            try runAndForward(allocator, io, &stdout_writer.interface, &argv, gate.tool);
        } else {
            const argv = [_][]const u8{ "zig", "run", gate.tool };
            try runAndForward(allocator, io, &stdout_writer.interface, &argv, gate.tool);
        }
    }

    try stdout_writer.interface.writeAll("ok distribution boundary gates\n");
    try stdout_writer.interface.flush();
}

fn runAndForward(
    allocator: std.mem.Allocator,
    io: std.Io,
    writer: *std.Io.Writer,
    argv: []const []const u8,
    label: []const u8,
) !void {
    const result = try common.runCapture(allocator, io, argv, label);
    defer common.freeRunResult(allocator, result);
    try writer.writeAll(result.stdout);
    try writer.flush();
}
