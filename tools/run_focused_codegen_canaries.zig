const std = @import("std");
const canaries = @import("codegen_canary_shared.zig");
const common = @import("tool_common.zig");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();
    _ = args.skip();
    if (args.next()) |arg| {
        try common.validationError(io, "unexpected argument for focused codegen canaries: {s}\n", .{arg});
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
    try env_map.put("ZLLVM_GENERIC_CFG_SELECTOR", "1");

    const temp = try common.TempDir.init(allocator, io, "focused_codegen_canaries");
    defer temp.deinit(allocator, io);

    try canaries.runMulti3Canary(allocator, io, temp, zllvm_exe, zig_emitter, target, &env_map);
    try canaries.runFmaCanary(allocator, io, temp, zllvm_exe, zig_emitter, target, &env_map);

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    try stdout_writer.interface.print("ok focused-codegen-canary name=__multi3 object=ok stream=ok symbol=ok execution_cases=6\n", .{});
    try stdout_writer.interface.print("ok focused-codegen-canary name=fma object=ok stream=ok symbol=ok helpers=ok execution_cases=29 host_libc_substitution=absent\n", .{});
    try stdout_writer.interface.print("summary focused-codegen-canaries target={s} canaries=2 execution_cases=35 local_fail=0\n", .{target});
    try stdout_writer.interface.flush();
}

fn normalizeTargetQuery(target: []const u8) []const u8 {
    if (std.mem.eql(u8, target, "x86_64-unknown-linux-gnu")) return "x86_64-linux-gnu";
    return target;
}

fn copyEnvironment(env_map: *std.process.Environ.Map, source: *const std.process.Environ.Map) !void {
    const keys = source.keys();
    const values = source.values();
    for (keys, values) |key, value| try env_map.put(key, value);
}
