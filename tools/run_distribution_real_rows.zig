const std = @import("std");
const common = @import("tool_common.zig");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();
    _ = args.next();

    var argv: std.ArrayList([]const u8) = .empty;
    defer argv.deinit(allocator);
    try argv.appendSlice(allocator, &.{ "zig", "run", "src/distribution_real_rows_gate.zig" });

    var saw_user_arg = false;
    while (args.next()) |arg| {
        if (!saw_user_arg) {
            try argv.append(allocator, "--");
            saw_user_arg = true;
        }
        try argv.append(allocator, arg);
    }

    const result = try std.process.run(allocator, io, .{
        .argv = argv.items,
        .stdout_limit = .limited(128 * 1024 * 1024),
        .stderr_limit = .limited(128 * 1024 * 1024),
    });
    defer common.freeRunResult(allocator, result);

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    try stdout_writer.interface.writeAll(result.stdout);
    try stdout_writer.interface.flush();

    var stderr_buffer: [4096]u8 = undefined;
    var stderr_writer = std.Io.File.stderr().writer(io, &stderr_buffer);
    try stderr_writer.interface.writeAll(result.stderr);
    try stderr_writer.interface.flush();

    if (!common.termOk(result.term)) {
        switch (result.term) {
            .exited => |code| std.process.exit(@intCast(code)),
            else => std.process.exit(1),
        }
    }
}
