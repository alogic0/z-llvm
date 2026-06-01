const std = @import("std");
const common = @import("tool_common.zig");

const BoundaryCase = struct {
    name: []const u8,
    function_name: []const u8,
    fixture: []const u8,
};

const cases = [_]BoundaryCase{
    .{
        .name = "standalone_emit_llvm_no_bin_str_from_float_help",
        .function_name = "main.strFromFloatHelp",
        .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_emit_llvm_no_bin_str_from_float_help.ll",
    },
    .{
        .name = "standalone_mix_o_files_base64_decode_base_64",
        .function_name = "base64.decode_base_64",
        .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll",
    },
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    const target_env = try getEnvOwnedOrNull(allocator, init.minimal.environ, "TARGET");
    defer if (target_env) |value| allocator.free(value);
    const target = target_env orelse "x86_64-unknown-linux-gnu";

    const temp = try common.TempDir.init(allocator, io, "releasesmall_boundary_m3");
    defer temp.deinit(allocator, io);

    const build_argv = [_][]const u8{ "zig", "build" };
    const build_result = try common.runCapture(allocator, io, &build_argv, "zig build");
    common.freeRunResult(allocator, build_result);

    var stdout_buffer: [512]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    for (cases) |case| {
        try expectControlFlowBoundary(allocator, io, temp, target, case);
        try stdout_writer.interface.print("ok distribution releasesmall boundary {s} [unsupported-control-flow]\n", .{case.name});
        try stdout_writer.interface.flush();
    }
}

fn expectControlFlowBoundary(
    allocator: std.mem.Allocator,
    io: std.Io,
    temp: common.TempDir,
    target: []const u8,
    case: BoundaryCase,
) !void {
    const err_path = try common.allocTempFile(allocator, temp, case.name, ".err");
    defer allocator.free(err_path);

    const target_arg = try std.fmt.allocPrint(allocator, "--target={s}", .{target});
    defer allocator.free(target_arg);
    const argv = [_][]const u8{
        "zig-out/bin/z_llvm",
        "--emit=obj",
        target_arg,
        "--input-limit=67108864",
        case.fixture,
    };
    const result = try std.process.run(allocator, io, .{
        .argv = &argv,
        .stdout_limit = .limited(128 * 1024 * 1024),
        .stderr_limit = .limited(32 * 1024 * 1024),
    });
    defer common.freeRunResult(allocator, result);

    var combined: std.ArrayList(u8) = .empty;
    defer combined.deinit(allocator);
    try combined.appendSlice(allocator, result.stdout);
    try combined.appendSlice(allocator, result.stderr);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = err_path, .data = combined.items });

    if (common.termOk(result.term)) {
        try common.validationError(io, "error: expected ReleaseSmall boundary fixture to fail: {s}\n", .{case.name});
    }
    if (std.mem.indexOf(u8, combined.items, "UnsupportedCodegenControlFlow") == null) {
        try common.validationError(io, "missing unsupported-control-flow diagnostic for {s}\n", .{case.name});
    }
    const function_diag = try std.fmt.allocPrint(allocator, "codegen failed for function {s}:", .{case.function_name});
    defer allocator.free(function_diag);
    if (std.mem.indexOf(u8, combined.items, function_diag) == null) {
        try common.validationError(io, "missing function diagnostic for {s}\n", .{case.name});
    }
}

fn getEnvOwnedOrNull(allocator: std.mem.Allocator, environ: std.process.Environ, name: []const u8) !?[]const u8 {
    return environ.getAlloc(allocator, name) catch |err| switch (err) {
        error.EnvironmentVariableMissing => null,
        else => err,
    };
}
