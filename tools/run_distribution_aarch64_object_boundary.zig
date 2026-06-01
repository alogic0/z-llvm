const std = @import("std");
const common = @import("tool_common.zig");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    const fixture_env = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "FIXTURE");
    defer if (fixture_env) |value| allocator.free(value);
    const target_env = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "TARGET");
    defer if (target_env) |value| allocator.free(value);

    const fixture = fixture_env orelse "test/distribution/releasefast_x86_64/inputs/tiny_scalar.ll";
    const target = target_env orelse "aarch64-unknown-linux-gnu";

    const temp = try common.TempDir.init(allocator, io, "aarch64_object_boundary");
    defer temp.deinit(allocator, io);
    const out = try temp.join(allocator, "aarch64_object_boundary.out");
    defer allocator.free(out);
    const err = try temp.join(allocator, "aarch64_object_boundary.err");
    defer allocator.free(err);

    const build_argv = [_][]const u8{ "zig", "build" };
    const build_result = try common.runCapture(allocator, io, &build_argv, "zig build");
    common.freeRunResult(allocator, build_result);

    const target_arg = try std.fmt.allocPrint(allocator, "--target={s}", .{target});
    defer allocator.free(target_arg);
    const argv = [_][]const u8{ "zig-out/bin/z_llvm", "--emit=obj", target_arg, fixture };
    const result = try std.process.run(allocator, io, .{
        .argv = &argv,
        .stdout_limit = .limited(128 * 1024 * 1024),
        .stderr_limit = .limited(32 * 1024 * 1024),
    });
    defer common.freeRunResult(allocator, result);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = out, .data = result.stdout });
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = err, .data = result.stderr });

    if (common.termOk(result.term)) {
        try common.validationError(io, "error: expected non-x86_64 object emission to remain outside the local boundary\n", .{});
    }

    const expected = try std.fmt.allocPrint(allocator, "unsupported codegen target: {s}; supported target subset is x86_64-linux", .{target});
    defer allocator.free(expected);
    const err_text = try std.Io.Dir.cwd().readFileAlloc(io, err, allocator, .limited(32 * 1024 * 1024));
    defer allocator.free(err_text);
    if (std.mem.indexOf(u8, err_text, expected) == null) {
        try common.validationError(io, "missing expected unsupported target diagnostic for {s}\n", .{target});
    }

    var stdout_buffer: [256]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    try stdout_writer.interface.print("ok distribution aarch64 object boundary target={s} [unsupported-codegen-target]\n", .{target});
    try stdout_writer.interface.flush();
}
