const std = @import("std");
const common = @import("tool_common.zig");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    const temp = try common.TempDir.init(allocator, io, "linker_boundary");
    defer temp.deinit(allocator, io);
    const help_out = try temp.join(allocator, "help.txt");
    defer allocator.free(help_out);
    const exe_out = try temp.join(allocator, "emit_exe.out");
    defer allocator.free(exe_out);
    const exe_err = try temp.join(allocator, "emit_exe.err");
    defer allocator.free(exe_err);

    const fixture = "test/distribution/releasefast_x86_64/inputs/tiny_scalar.ll";

    const build_argv = [_][]const u8{ "zig", "build" };
    const build_result = try common.runCapture(allocator, io, &build_argv, "zig build");
    common.freeRunResult(allocator, build_result);

    const help_argv = [_][]const u8{ "zig-out/bin/z_llvm", "--help" };
    try common.runToFile(allocator, io, &help_argv, "zig-out/bin/z_llvm --help", help_out);
    try expectContains(allocator, io, help_out, "usage: z_llvm [--emit=ir|asm|obj|ir-writer|semantic-descriptor]");

    const exe_argv = [_][]const u8{ "zig-out/bin/z_llvm", "--emit=exe", "--target=x86_64-unknown-linux-gnu", fixture };
    const exe_result = try std.process.run(allocator, io, .{
        .argv = &exe_argv,
        .stdout_limit = .limited(128 * 1024 * 1024),
        .stderr_limit = .limited(32 * 1024 * 1024),
    });
    defer common.freeRunResult(allocator, exe_result);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = exe_out, .data = exe_result.stdout });
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = exe_err, .data = exe_result.stderr });
    if (common.termOk(exe_result.term)) {
        try common.validationError(io, "error: expected --emit=exe to remain outside the local distribution boundary\n", .{});
    }
    try expectContains(allocator, io, exe_err, "UnsupportedEmitMode");

    try expectContains(allocator, io, "tools/run_distribution_executable_m1.zig", "\"zig\", \"cc\", \"-target\", cc_target");
    try expectContains(allocator, io, "tools/run_distribution_releasesafe_object_m2.zig", "\"zig\", \"cc\", \"-target\", cc_target");
    try expectContains(allocator, io, "tools/run_distribution_releasesmall_executable_m3.zig", "\"zig\", \"cc\", \"-target\", cc_target");
    try expectContains(allocator, io, "tools/run_distribution_debug_executable_m4.zig", "\"zig\", \"cc\", \"-target\", cc_target");
    try expectContains(allocator, io, "tools/run_distribution_native_link_m5.zig", "\"zig\", \"build-exe\"");
    try expectContains(allocator, io, "tools/run_distribution_native_link_m5.zig", "\"-fno-lld\"");

    var stdout_buffer: [256]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    try stdout_writer.interface.writeAll("ok distribution linker boundary [local emit=ir/asm/obj/ir-writer/semantic-descriptor, executable handoff=zig cc, native proof=zig build-exe -fno-lld]\n");
    try stdout_writer.interface.flush();
}

fn expectContains(allocator: std.mem.Allocator, io: std.Io, path: []const u8, needle: []const u8) !void {
    const contents = try std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(32 * 1024 * 1024));
    defer allocator.free(contents);
    if (std.mem.indexOf(u8, contents, needle) == null) {
        try common.validationError(io, "missing expected text in {s}: {s}\n", .{ path, needle });
    }
}
