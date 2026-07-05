const std = @import("std");
const common = @import("tool_common.zig");

const Case = struct {
    mode: []const u8,
    source: []const u8,
    expected_stdout: []const u8,
    expected_exit: u8,
};

const cases = [_]Case{
    .{
        .mode = "ReleaseFast",
        .source = "test/zig/integrated/syscall_hello_start.zig",
        .expected_stdout = "hello\n",
        .expected_exit = 0,
    },
    .{
        .mode = "ReleaseSafe",
        .source = "test/zig/integrated/syscall_hello_start.zig",
        .expected_stdout = "hello\n",
        .expected_exit = 0,
    },
    .{
        .mode = "ReleaseSmall",
        .source = "test/zig/integrated/syscall_hello_start.zig",
        .expected_stdout = "hello\n",
        .expected_exit = 0,
    },
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    var mode_filter: ?[]const u8 = null;
    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();
    _ = args.skip();
    while (args.next()) |arg| {
        if (std.mem.startsWith(u8, arg, "--mode=")) {
            mode_filter = arg["--mode=".len..];
        } else {
            try common.validationError(io, "unexpected argument for integrated exe runner: {s}\n", .{arg});
        }
    }

    const target_env = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "TARGET");
    defer if (target_env) |value| allocator.free(value);
    const zig_source_env = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "ZIG_SOURCE_DIR");
    defer if (zig_source_env) |value| allocator.free(value);
    const zig_emitter_env = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "ZIG_EMITTER");
    defer if (zig_emitter_env) |value| allocator.free(value);
    const zllvm_env = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "ZLLVM_EXE");
    defer if (zllvm_env) |value| allocator.free(value);

    const target = normalizeTargetQuery(target_env orelse "x86_64-linux-gnu");
    const zig_source_dir = zig_source_env orelse "../ziglang";
    const default_zig_emitter = try std.fs.path.join(allocator, &.{ zig_source_dir, "build/stage4/bin/zig" });
    defer allocator.free(default_zig_emitter);
    const zig_emitter = zig_emitter_env orelse default_zig_emitter;
    const zllvm_exe = zllvm_env orelse "zig-out/bin/z_llvm";

    const check_argv = [_][]const u8{ "zig", "run", "tools/check_zig_stage4_emitter.zig" };
    const check_result = try common.runCapture(allocator, io, &check_argv, "tools/check_zig_stage4_emitter.zig");
    common.freeRunResult(allocator, check_result);

    const build_argv = [_][]const u8{ "zig", "build" };
    const build_result = try common.runCapture(allocator, io, &build_argv, "zig build");
    common.freeRunResult(allocator, build_result);

    var env_map = std.process.Environ.Map.init(allocator);
    defer env_map.deinit();
    try copyEnvironment(&env_map, init.environ_map);
    try env_map.put("ZIG_USE_ZLLVM_OBJECT", "1");
    try env_map.put("ZLLVM_PIPELINE", "postopt");
    try env_map.put("ZLLVM_EXE", zllvm_exe);

    const temp = try common.TempDir.init(allocator, io, "zig_integrated_exe");
    defer temp.deinit(allocator, io);

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    try stdout_writer.interface.print(
        "zig-integrated-exe target={s} linker=zig build-exe -fno-lld hook=ZIG_USE_ZLLVM_OBJECT zllvm={s}\n",
        .{ target, zllvm_exe },
    );
    try stdout_writer.interface.flush();

    var total: usize = 0;
    var build_ok: usize = 0;
    var run_ok: usize = 0;
    for (cases) |case| {
        if (mode_filter) |filter| {
            if (!std.mem.eql(u8, filter, case.mode)) continue;
        }
        total += 1;
        const exe = try common.allocTempFile(allocator, temp, case.mode, ".syscall_hello");
        defer allocator.free(exe);
        try buildExecutable(allocator, io, zig_emitter, target, exe, case, &env_map);
        build_ok += 1;
        try runExecutable(allocator, io, exe, case);
        run_ok += 1;
        try stdout_writer.interface.print("ok zig-integrated-exe mode={s} stdout=hello exit=0\n", .{case.mode});
        try stdout_writer.interface.flush();
    }

    if (total == 0) {
        try common.validationError(io, "integrated exe runner selected no cases\n", .{});
    }
    try stdout_writer.interface.print(
        "summary zig-integrated-exe total={} build_ok={} run_ok={} stdout_ok={} exit_ok={} minimal_inline_asm_syscall_rows={} local_fail=0\n",
        .{ total, build_ok, run_ok, run_ok, run_ok, run_ok },
    );
    try stdout_writer.interface.flush();
}

fn buildExecutable(
    allocator: std.mem.Allocator,
    io: std.Io,
    zig_emitter: []const u8,
    target: []const u8,
    exe: []const u8,
    case: Case,
    env_map: *const std.process.Environ.Map,
) !void {
    const emit_arg = try std.fmt.allocPrint(allocator, "-femit-bin={s}", .{exe});
    defer allocator.free(emit_arg);
    var argv: std.ArrayList([]const u8) = .empty;
    defer argv.deinit(allocator);
    try argv.appendSlice(allocator, &.{
        zig_emitter,
        "build-exe",
        "-fllvm",
        "-flibllvm",
        "-fno-lld",
        "-fno-compiler-rt",
        "-fno-stack-protector",
        "-fno-unwind-tables",
        "-fentry=_start",
        "-O",
        case.mode,
        "-target",
        target,
        case.source,
        emit_arg,
    });
    const label = try std.fmt.allocPrint(allocator, "patched Zig integrated z_llvm build-exe syscall hello {s}", .{case.mode});
    defer allocator.free(label);
    const result = try common.runCaptureEnv(allocator, io, argv.items, label, env_map);
    common.freeRunResult(allocator, result);
}

fn runExecutable(
    allocator: std.mem.Allocator,
    io: std.Io,
    exe: []const u8,
    case: Case,
) !void {
    const argv = [_][]const u8{exe};
    const result = try std.process.run(allocator, io, .{
        .argv = &argv,
        .stdout_limit = .limited(1024 * 1024),
        .stderr_limit = .limited(1024 * 1024),
    });
    defer common.freeRunResult(allocator, result);

    switch (result.term) {
        .exited => |code| if (code == case.expected_exit) {},
        else => try common.validationError(io, "integrated syscall hello {s} exited with {any}, expected exit code {}\n", .{ case.mode, result.term, case.expected_exit }),
    }
    if (!std.mem.eql(u8, result.stdout, case.expected_stdout)) {
        try common.validationError(io, "integrated syscall hello {s} stdout mismatch: expected {s}, got {s}\n", .{ case.mode, case.expected_stdout, result.stdout });
    }
}

fn normalizeTargetQuery(target: []const u8) []const u8 {
    if (std.mem.eql(u8, target, "x86_64-unknown-linux-gnu")) {
        return "x86_64-linux-gnu";
    }
    return target;
}

fn copyEnvironment(
    env_map: *std.process.Environ.Map,
    source: *const std.process.Environ.Map,
) !void {
    const keys = source.keys();
    const values = source.values();
    for (keys, values) |key, value| {
        try env_map.put(key, value);
    }
}
