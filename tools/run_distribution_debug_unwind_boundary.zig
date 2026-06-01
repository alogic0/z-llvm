const std = @import("std");
const common = @import("tool_common.zig");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    const target_env = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "TARGET");
    defer if (target_env) |value| allocator.free(value);
    const fixture_env = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "FIXTURE");
    defer if (fixture_env) |value| allocator.free(value);
    const target = target_env orelse "x86_64-unknown-linux-gnu";
    const fixture = fixture_env orelse "test/zig/expected/debug_metadata.reduced.ll";

    const temp = try common.TempDir.init(allocator, io, "debug_unwind_boundary");
    defer temp.deinit(allocator, io);
    const object = try temp.join(allocator, "debug_metadata_boundary.o");
    defer allocator.free(object);
    const summary = try temp.join(allocator, "debug_metadata_boundary.readelf.txt");
    defer allocator.free(summary);

    const target_arg = try std.fmt.allocPrint(allocator, "--target={s}", .{target});
    defer allocator.free(target_arg);
    const emit_argv = [_][]const u8{ "zig", "build", "run", "--", "--emit=obj", target_arg, "--input-limit=67108864", fixture };
    try common.runToFile(allocator, io, &emit_argv, "zig build run", object);

    const readelf_argv = [_][]const u8{ "readelf", "-W", "-S", object };
    try common.runToFile(allocator, io, &readelf_argv, "readelf", summary);

    const text = try std.Io.Dir.cwd().readFileAlloc(io, summary, allocator, .limited(32 * 1024 * 1024));
    defer allocator.free(text);
    if (std.mem.indexOf(u8, text, ".text") == null) {
        try common.validationError(io, "missing .text section in Debug boundary object\n", .{});
    }
    if (std.mem.indexOf(u8, text, ".debug") != null or std.mem.indexOf(u8, text, ".eh_frame") != null) {
        try common.validationError(io, "error: debug/unwind sections are outside the selected object boundary\n", .{});
    }

    var stdout_buffer: [256]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    try stdout_writer.interface.print("ok distribution debug unwind boundary target={s} [no-dwarf-or-unwind-sections]\n", .{target});
    try stdout_writer.interface.flush();
}
