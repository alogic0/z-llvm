const std = @import("std");
const common = @import("tool_common.zig");

const Mode = enum { object, executable };

const usage =
    \\usage: zig run tools/run_distribution_x86_64_musl_subset.zig -- --mode=object|executable
    \\
    \\Run the selected x86_64 musl distribution subset gates.
    \\Set TARGET to override x86_64-unknown-linux-musl.
    \\
;

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    const mode = try parseMode(allocator, io, init);
    const target = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "TARGET");
    defer if (target) |value| allocator.free(value);
    const selected_target = target orelse "x86_64-unknown-linux-musl";

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    try stdout_writer.interface.print("distribution x86_64 musl {s} subset target={s}\n", .{ @tagName(mode), selected_target });
    try stdout_writer.interface.flush();

    switch (mode) {
        .object => {
            try runGate(allocator, io, selected_target, "scripts/run_distribution_object_m1.sh");
            try runGate(allocator, io, selected_target, "scripts/run_distribution_releasesafe_object_m2.sh");
            try runGate(allocator, io, selected_target, "scripts/run_distribution_releasesmall_object_m3.sh");
            try runGate(allocator, io, selected_target, "scripts/run_distribution_debug_object_m4.sh");
        },
        .executable => {
            try runGate(allocator, io, selected_target, "scripts/run_distribution_executable_m1.sh");
            try runGate(allocator, io, selected_target, "scripts/run_distribution_releasesafe_object_m2.sh");
            try runGate(allocator, io, selected_target, "scripts/run_distribution_releasesmall_executable_m3.sh");
            try runGate(allocator, io, selected_target, "scripts/run_distribution_debug_executable_m4.sh");
        },
    }

    try stdout_writer.interface.print("ok distribution x86_64 musl {s} subset\n", .{@tagName(mode)});
    try stdout_writer.interface.flush();
}

fn parseMode(allocator: std.mem.Allocator, io: std.Io, init: std.process.Init) !Mode {
    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();
    _ = args.next();

    var mode: ?Mode = null;
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            var stdout_buffer: [512]u8 = undefined;
            var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
            try stdout_writer.interface.writeAll(usage);
            try stdout_writer.interface.flush();
            std.process.exit(0);
        } else if (std.mem.startsWith(u8, arg, "--mode=")) {
            const text = arg["--mode=".len..];
            mode = if (std.mem.eql(u8, text, "object"))
                .object
            else if (std.mem.eql(u8, text, "executable"))
                .executable
            else
                try common.validationError(io, "unknown mode: {s}\n{s}", .{ text, usage });
        } else {
            try common.validationError(io, "unexpected argument: {s}\n{s}", .{ arg, usage });
        }
    }

    return mode orelse try common.validationError(io, "missing --mode\n{s}", .{usage});
}

fn runGate(allocator: std.mem.Allocator, io: std.Io, target: []const u8, script: []const u8) !void {
    const target_arg = try std.fmt.allocPrint(allocator, "TARGET={s}", .{target});
    defer allocator.free(target_arg);
    const argv = [_][]const u8{ "env", target_arg, "bash", script };
    const result = try common.runCapture(allocator, io, &argv, script);
    defer common.freeRunResult(allocator, result);

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    try stdout_writer.interface.writeAll(result.stdout);
    try stdout_writer.interface.flush();
}
