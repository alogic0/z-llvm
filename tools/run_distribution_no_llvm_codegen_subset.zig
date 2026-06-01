const std = @import("std");
const common = @import("tool_common.zig");

const tools = [_][]const u8{
    "tools/run_distribution_object_m1.zig",
    "tools/run_distribution_executable_m1.zig",
    "tools/run_distribution_releasesafe_object_m2.zig",
    "tools/run_distribution_releasesmall_object_m3.zig",
    "tools/run_distribution_releasesmall_executable_m3.zig",
    "tools/run_distribution_debug_object_m4.zig",
    "tools/run_distribution_debug_executable_m4.zig",
    "tools/run_handoff_validation.zig",
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    const target_env = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "TARGET");
    defer if (target_env) |value| allocator.free(value);
    const target = target_env orelse "x86_64-unknown-linux-gnu";
    const target_assignment = try std.fmt.allocPrint(allocator, "TARGET={s}", .{target});
    defer allocator.free(target_assignment);

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    try stdout_writer.interface.print("distribution no-LLVM-codegen subset target={s}\n", .{target});
    try stdout_writer.interface.flush();

    for (tools) |tool| {
        const argv = [_][]const u8{ "env", target_assignment, "zig", "run", tool };
        const result = try common.runCapture(allocator, io, &argv, tool);
        defer common.freeRunResult(allocator, result);
        try stdout_writer.interface.writeAll(result.stdout);
        try stdout_writer.interface.flush();
    }

    try stdout_writer.interface.writeAll("ok distribution no-LLVM-codegen subset\n");
    try stdout_writer.interface.flush();
}
