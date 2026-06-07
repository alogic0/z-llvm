const std = @import("std");
const common = @import("tool_common.zig");

const Tool = struct {
    path: []const u8,
    args: []const []const u8 = &.{},
};

const tools = [_]Tool{
    .{ .path = "tools/run_distribution_no_llvm_codegen_subset.zig" },
    .{ .path = "tools/run_native_link_object_inspection.zig" },
    .{ .path = "tools/run_distribution_native_link_m5.zig" },
    .{ .path = "tools/probe_native_linker_compatibility.zig" },
    .{ .path = "tools/run_distribution_zig_source_native_link.zig" },
    .{ .path = "tools/run_distribution_zig_integrated_object.zig" },
    .{ .path = "tools/run_distribution_zig_integrated_object.zig", .args = &.{"--pipeline=preopt"} },
    .{ .path = "tools/run_distribution_zig_integrated_object.zig", .args = &.{"--ir-writer"} },
    .{ .path = "tools/run_distribution_zig_integrated_object.zig", .args = &.{"--release-source-owned"} },
    .{ .path = "tools/run_distribution_boundary_gates.zig" },
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

    for (tools) |tool| {
        var argv: std.ArrayList([]const u8) = .empty;
        defer argv.deinit(allocator);
        try argv.appendSlice(allocator, &.{ "env", target_assignment, "zig", "run", tool.path });
        if (tool.args.len != 0) {
            try argv.append(allocator, "--");
            try argv.appendSlice(allocator, tool.args);
        }
        const result = try common.runCapture(allocator, io, argv.items, tool.path);
        defer common.freeRunResult(allocator, result);
        try stdout_writer.interface.writeAll(result.stdout);
        try stdout_writer.interface.flush();
    }

    try stdout_writer.interface.writeAll("ok distribution all gates\n");
    try stdout_writer.interface.flush();
}
