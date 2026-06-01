const std = @import("std");
const common = @import("tool_common.zig");

const scripts = [_][]const u8{
    "scripts/run_distribution_no_llvm_codegen_subset.sh",
    "scripts/run_distribution_boundary_gates.sh",
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
    try stdout_writer.interface.print("distribution all gates target={s}\n", .{target});
    try stdout_writer.interface.flush();

    for (scripts) |script| {
        const argv = [_][]const u8{ "env", target_assignment, "bash", script };
        const result = try common.runCapture(allocator, io, &argv, script);
        defer common.freeRunResult(allocator, result);
        try stdout_writer.interface.writeAll(result.stdout);
        try stdout_writer.interface.flush();
    }

    try stdout_writer.interface.writeAll("ok distribution all gates\n");
    try stdout_writer.interface.flush();
}
