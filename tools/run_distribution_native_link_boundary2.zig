const std = @import("std");
const common = @import("tool_common.zig");

const Mode = struct {
    name: []const u8,
    summary: []const u8,
};

const modes = [_]Mode{
    .{ .name = "ReleaseFast", .summary = "tmp/zig_ir/native_link_boundary2_releasefast.summary" },
    .{ .name = "ReleaseSafe", .summary = "tmp/zig_ir/native_link_boundary2_releasesafe.summary" },
    .{ .name = "ReleaseSmall", .summary = "tmp/zig_ir/native_link_boundary2_releasesmall.summary" },
    .{ .name = "Debug", .summary = "tmp/zig_ir/native_link_boundary2_debug.summary" },
};

const Summary = struct {
    total: usize,
    accepted: usize,
    accounted: usize,
    local_fail: usize,
    excluded: usize,
    accounted_total: usize,
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    try stdout_writer.interface.writeAll("native-link boundary2 linker=zig build-exe -fno-lld\n");

    for (modes) |mode| {
        const mode_arg = try std.fmt.allocPrint(allocator, "--mode={s}", .{mode.name});
        defer allocator.free(mode_arg);
        const summary_arg = try std.fmt.allocPrint(allocator, "--summary={s}", .{mode.summary});
        defer allocator.free(summary_arg);
        const argv = [_][]const u8{ "zig", "run", "tools/probe_native_linker_broad.zig", "--", mode_arg, summary_arg };
        const result = try common.runCapture(allocator, io, &argv, "zig run tools/probe_native_linker_broad.zig");
        defer common.freeRunResult(allocator, result);

        if (std.mem.indexOf(u8, result.stdout, "runtime-symbol") != null) {
            try common.validationError(io, "generic runtime-symbol category found in broad native-link probe for {s}\n", .{mode.name});
        }

        const summary = try parseSummary(io, result.stdout, mode.name);
        if (summary.local_fail != 0) {
            try common.validationError(io, "native-link boundary2 {s} has local_fail={}\n", .{ mode.name, summary.local_fail });
        }

        try stdout_writer.interface.print(
            "ok native-link boundary2 {s} total={} accepted={} accounted={} excluded={} accounted_total={} local_fail=0\n",
            .{ mode.name, summary.total, summary.accepted, summary.accounted, summary.excluded, summary.accounted_total },
        );
        try stdout_writer.interface.flush();
    }
}

fn parseSummary(io: std.Io, output: []const u8, mode: []const u8) !Summary {
    var lines = std.mem.splitScalar(u8, output, '\n');
    while (lines.next()) |line| {
        if (!std.mem.startsWith(u8, line, "summary ")) continue;
        return .{
            .total = try parseField(io, line, "total"),
            .accepted = try parseField(io, line, "accepted"),
            .accounted = try parseField(io, line, "accounted"),
            .local_fail = try parseField(io, line, "local_fail"),
            .excluded = try parseField(io, line, "excluded"),
            .accounted_total = try parseField(io, line, "accounted_total"),
        };
    }
    try common.validationError(io, "missing broad native-link summary for {s}\n", .{mode});
}

fn parseField(io: std.Io, line: []const u8, field: []const u8) !usize {
    var needle_buffer: [64]u8 = undefined;
    const needle = try std.fmt.bufPrint(&needle_buffer, "{s}=", .{field});
    const start = std.mem.indexOf(u8, line, needle) orelse {
        try common.validationError(io, "missing summary field {s} in: {s}\n", .{ field, line });
    };
    const value_start = start + needle.len;
    const value_end = std.mem.indexOfAnyPos(u8, line, value_start, " \t\r\n") orelse line.len;
    return std.fmt.parseInt(usize, line[value_start..value_end], 10) catch {
        try common.validationError(io, "invalid summary field {s} in: {s}\n", .{ field, line });
    };
}
