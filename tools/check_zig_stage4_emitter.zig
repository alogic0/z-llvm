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

    const pin_file_env = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "ZIGLANG_PIN_FILE");
    defer if (pin_file_env) |value| allocator.free(value);
    const pin_file = pin_file_env orelse "docs/evidence/ziglang_pin.txt";

    const pin_contents = try std.Io.Dir.cwd().readFileAlloc(io, pin_file, allocator, .limited(4096));
    defer allocator.free(pin_contents);
    const pin = std.mem.trim(u8, pin_contents, " \t\r\n");
    if (pin.len < 9) {
        try common.validationError(io, "invalid Zig pin in {s}: expected at least 9 hex characters\n", .{pin_file});
    }
    const pinned_rev = pin[0..9];

    const version_argv = [_][]const u8{ zig_emitter, "version" };
    const version_result = try common.runCapture(allocator, io, &version_argv, "stage4 Zig version");
    defer common.freeRunResult(allocator, version_result);
    const version = std.mem.trim(u8, version_result.stdout, " \t\r\n");

    if (std.mem.indexOf(u8, version, pinned_rev) == null) {
        try common.validationError(
            io,
            "stage4 Zig version does not match tracked Zig pin\n  pin_file: {s}\n  pin:      {s}\n  version:  {s}\n  fix:      rebuild stage4 per docs/build_steps.md or update the pin after selecting a new stage4 emitter\n",
            .{ pin_file, pin, version },
        );
    }

    var stdout_buffer: [512]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    try stdout_writer.interface.print("ok stage4 emitter {s} matches tracked Zig pin {s} ({s})\n", .{ version, pinned_rev, pin_file });
    try stdout_writer.interface.flush();
}
