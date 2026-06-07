const std = @import("std");
const common = @import("tool_common.zig");
const source_owned = @import("run_distribution_zig_integrated_object.zig");

pub const source_wrapper_dispatch_case_id = "source-wrapper-dispatch";
pub const expected_release_source_owned_rows = 100;

pub const Context = struct {
    target: []const u8,
    zig_emitter: []const u8,
    zllvm_exe: []const u8,
    env_map: std.process.Environ.Map,

    pub fn init(allocator: std.mem.Allocator, io: std.Io, init_process: std.process.Init, target: []const u8) !Context {
        const zig_source_env = try common.getEnvOwnedOrNull(allocator, init_process.minimal.environ, "ZIG_SOURCE_DIR");
        defer if (zig_source_env) |value| allocator.free(value);
        const zig_emitter_env = try common.getEnvOwnedOrNull(allocator, init_process.minimal.environ, "ZIG_EMITTER");
        errdefer if (zig_emitter_env) |value| allocator.free(value);
        const zllvm_env = try common.getEnvOwnedOrNull(allocator, init_process.minimal.environ, "ZLLVM_EXE");
        errdefer if (zllvm_env) |value| allocator.free(value);

        const zig_source_dir = zig_source_env orelse "../ziglang";
        const zig_emitter = zig_emitter_env orelse try std.fs.path.join(allocator, &.{ zig_source_dir, "build/stage4/bin/zig" });
        errdefer if (zig_emitter_env == null) allocator.free(zig_emitter);

        const zllvm_exe = zllvm_env orelse try allocator.dupe(u8, "zig-out/bin/z_llvm");
        errdefer if (zllvm_env == null) allocator.free(zllvm_exe);

        const check_argv = [_][]const u8{ "zig", "run", "tools/check_zig_stage4_emitter.zig" };
        const check_result = try common.runCapture(allocator, io, &check_argv, "tools/check_zig_stage4_emitter.zig");
        common.freeRunResult(allocator, check_result);

        const build_argv = [_][]const u8{ "zig", "build" };
        const build_result = try common.runCapture(allocator, io, &build_argv, "zig build");
        common.freeRunResult(allocator, build_result);

        var env_map = std.process.Environ.Map.init(allocator);
        errdefer env_map.deinit();
        try copyEnvironment(&env_map, init_process.environ_map);
        try env_map.put("ZIG_USE_ZLLVM_IR_WRITER", "1");
        try env_map.put("ZLLVM_IR_WRITER_MODE", "external");
        try env_map.put("ZLLVM_PIPELINE", "preopt");
        try env_map.put("ZLLVM_EXE", zllvm_exe);

        return .{
            .target = target,
            .zig_emitter = zig_emitter,
            .zllvm_exe = zllvm_exe,
            .env_map = env_map,
        };
    }

    pub fn deinit(context: Context, allocator: std.mem.Allocator) void {
        var env_map = context.env_map;
        env_map.deinit();
        allocator.free(context.zig_emitter);
        allocator.free(context.zllvm_exe);
    }
};

pub fn emitObject(
    allocator: std.mem.Allocator,
    io: std.Io,
    context: Context,
    case: source_owned.Case,
    object: []const u8,
    marker: []const u8,
    ir_path: []const u8,
    descriptor_path: []const u8,
) !void {
    var env_map = try cloneEnvironment(allocator, &context.env_map);
    defer env_map.deinit();
    try env_map.put("ZLLVM_MARKER_PATH", marker);
    try env_map.put("ZLLVM_ZIG_MODE", case.mode);
    try env_map.put("ZLLVM_CASE_ID", source_wrapper_dispatch_case_id);
    try env_map.put("ZLLVM_WRAPPER", case.wrapper);
    try env_map.put("ZLLVM_IR_WRITER_DISPATCH", "source-owned");
    try env_map.put("ZLLVM_SOURCE_FIXTURE", case.covered_fixture);
    try env_map.put("ZLLVM_SEMANTIC_DESCRIPTOR_PATH", descriptor_path);
    try env_map.put("ZLLVM_IR_PATH", ir_path);

    try buildObject(allocator, io, context, case, object, &env_map);
    try requireHookArtifacts(allocator, io, case, marker, descriptor_path);
}

pub fn linkObject(
    allocator: std.mem.Allocator,
    io: std.Io,
    target: []const u8,
    object: []const u8,
    exe: []const u8,
    case: source_owned.Case,
) !void {
    const emit_arg = try std.fmt.allocPrint(allocator, "-femit-bin={s}", .{exe});
    defer allocator.free(emit_arg);
    const argv = [_][]const u8{
        "zig",
        "build-exe",
        "-fno-lld",
        "-fno-compiler-rt",
        "-target",
        target,
        object,
        "-lc",
        emit_arg,
    };
    const label = try std.fmt.allocPrint(allocator, "zig build-exe -fno-lld source-owned {s}", .{case.id});
    defer allocator.free(label);
    const result = try common.runCapture(allocator, io, &argv, label);
    common.freeRunResult(allocator, result);
}

pub const LinkProbeResult = union(enum) {
    accepted,
    failed: LinkFailure,
};

pub const LinkFailure = struct {
    category: []const u8,
    stderr: []u8,
};

pub fn probeLinkObject(
    allocator: std.mem.Allocator,
    io: std.Io,
    target: []const u8,
    object: []const u8,
    exe: []const u8,
) !LinkProbeResult {
    const emit_arg = try std.fmt.allocPrint(allocator, "-femit-bin={s}", .{exe});
    defer allocator.free(emit_arg);
    const argv = [_][]const u8{
        "zig",
        "build-exe",
        "-fno-lld",
        "-fno-compiler-rt",
        "-target",
        target,
        object,
        "-lc",
        emit_arg,
    };
    const result = try std.process.run(allocator, io, .{
        .argv = &argv,
        .stdout_limit = .limited(128 * 1024 * 1024),
        .stderr_limit = .limited(32 * 1024 * 1024),
    });
    defer allocator.free(result.stdout);

    if (common.termOk(result.term)) {
        allocator.free(result.stderr);
        return .accepted;
    }

    return .{ .failed = .{
        .category = classifyLinkFailure(result.stderr),
        .stderr = result.stderr,
    } };
}

pub fn runExecutable(
    allocator: std.mem.Allocator,
    io: std.Io,
    exe: []const u8,
    case: source_owned.Case,
) !void {
    const argv = [_][]const u8{exe};
    const result = try std.process.run(allocator, io, .{
        .argv = &argv,
        .stdout_limit = .limited(128 * 1024 * 1024),
        .stderr_limit = .limited(32 * 1024 * 1024),
    });
    defer common.freeRunResult(allocator, result);

    const expected_code = expectedExitCode(case);
    switch (result.term) {
        .exited => |code| if (code == expected_code) return,
        else => {},
    }
    try common.validationError(io, "source-owned native-link executable {s} exited with {any}, expected exit code {}\n", .{ case.id, result.term, expected_code });
}

pub fn normalizeZigTarget(target: []const u8) []const u8 {
    if (std.mem.eql(u8, target, "x86_64-unknown-linux-gnu")) return "x86_64-linux-gnu";
    if (std.mem.eql(u8, target, "x86_64-unknown-linux-musl")) return "x86_64-linux-musl";
    return target;
}

pub fn validationName(validation: source_owned.Validation) []const u8 {
    return switch (validation) {
        .executable => "executable",
        .link_only => "link-only",
    };
}

pub fn classifyLinkFailure(stderr: []const u8) []const u8 {
    if (std.mem.indexOf(u8, stderr, "undefined symbol") != null or
        std.mem.indexOf(u8, stderr, "undefined reference") != null)
    {
        if (std.mem.indexOf(u8, stderr, "compiler_rt") != null or
            std.mem.indexOf(u8, stderr, "compiler-rt") != null or
            std.mem.indexOf(u8, stderr, "libc") != null or
            std.mem.indexOf(u8, stderr, "__") != null)
        {
            return "runtime/compiler-rt/libc-boundary";
        }
        return "bad-symbol-binding-type";
    }
    if (std.mem.indexOf(u8, stderr, "relocation") != null) return "missing-relocation-support";
    if (std.mem.indexOf(u8, stderr, "section") != null) return "section-flag-alignment";
    if (std.mem.indexOf(u8, stderr, "TLS") != null or std.mem.indexOf(u8, stderr, "thread-local") != null) return "tls-model";
    if (std.mem.indexOf(u8, stderr, "COMDAT") != null or std.mem.indexOf(u8, stderr, "comdat") != null) return "comdat";
    if (std.mem.indexOf(u8, stderr, "align") != null) return "section-flag-alignment";
    if (std.mem.indexOf(u8, stderr, "ABI") != null or std.mem.indexOf(u8, stderr, "calling convention") != null) return "abi";
    return "zig-linker-bug-or-unsupported-feature";
}

pub fn isGenericFailureCategory(category: []const u8) bool {
    return std.mem.eql(u8, category, "runtime-symbol") or
        std.mem.eql(u8, category, "unknown-linker-compatibility") or
        std.mem.eql(u8, category, "unclassified-link-failed");
}

fn buildObject(
    allocator: std.mem.Allocator,
    io: std.Io,
    context: Context,
    case: source_owned.Case,
    object: []const u8,
    env_map: *const std.process.Environ.Map,
) !void {
    const emit_arg = try std.fmt.allocPrint(allocator, "-femit-bin={s}", .{object});
    defer allocator.free(emit_arg);

    var argv: std.ArrayList([]const u8) = .empty;
    defer argv.deinit(allocator);
    try argv.appendSlice(allocator, &.{
        context.zig_emitter,
        "build-obj",
        "-fllvm",
        "-flibllvm",
        "-fno-compiler-rt",
    });
    if (shouldStrip(case.mode)) try argv.append(allocator, "-fstrip");
    try argv.appendSlice(allocator, &.{
        "-O",
        case.mode,
        "-target",
        context.target,
        case.wrapper,
        emit_arg,
    });
    const label = try std.fmt.allocPrint(allocator, "patched Zig source-owned build-obj {s}", .{case.id});
    defer allocator.free(label);
    const result = try common.runCaptureEnv(allocator, io, argv.items, label, env_map);
    common.freeRunResult(allocator, result);
}

fn requireHookArtifacts(
    allocator: std.mem.Allocator,
    io: std.Io,
    case: source_owned.Case,
    marker: []const u8,
    descriptor_path: []const u8,
) !void {
    const marker_contents = std.Io.Dir.cwd().readFileAlloc(io, marker, allocator, .limited(1024 * 1024)) catch |err| {
        try common.validationError(io, "source-owned handoff missing z_llvm marker for {s}: {t}\n", .{ case.id, err });
    };
    defer allocator.free(marker_contents);
    try requireMarker(io, case, marker_contents, "case_id=source-wrapper-dispatch");
    try requireMarker(io, case, marker_contents, "pipeline=preopt");
    try requireMarker(io, case, marker_contents, "ir_writer=external");

    const emitter = readDescriptorInputValue(allocator, io, descriptor_path, case, "facts_emitter") catch |err| switch (err) {
        error.MissingDescriptorInputValue => try readDescriptorInputValue(allocator, io, descriptor_path, case, "descriptor_emitter"),
        else => return err,
    };
    defer allocator.free(emitter);
    if (!std.mem.eql(u8, emitter, "patched-zig-hook")) {
        try common.validationError(io, "source-owned handoff row {s} descriptor emitter is {s}, expected patched-zig-hook\n", .{ case.id, emitter });
    }
}

fn requireMarker(io: std.Io, case: source_owned.Case, marker_contents: []const u8, needle: []const u8) !void {
    if (std.mem.indexOf(u8, marker_contents, needle) == null) {
        try common.validationError(io, "source-owned handoff marker for {s} missing {s}\n", .{ case.id, needle });
    }
}

fn readDescriptorInputValue(
    allocator: std.mem.Allocator,
    io: std.Io,
    descriptor_path: []const u8,
    case: source_owned.Case,
    key: []const u8,
) ![]const u8 {
    const contents = std.Io.Dir.cwd().readFileAlloc(io, descriptor_path, allocator, .limited(1024 * 1024)) catch |err| {
        try common.validationError(io, "missing Zig-emitted semantic descriptor for {s}: {t}\n", .{ case.id, err });
    };
    defer allocator.free(contents);
    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |line| {
        const separator = std.mem.indexOfScalar(u8, line, '=') orelse continue;
        if (std.mem.eql(u8, line[0..separator], key)) {
            return try allocator.dupe(u8, line[separator + 1 ..]);
        }
    }
    return error.MissingDescriptorInputValue;
}

fn cloneEnvironment(allocator: std.mem.Allocator, src: *const std.process.Environ.Map) !std.process.Environ.Map {
    var dst = std.process.Environ.Map.init(allocator);
    errdefer dst.deinit();
    try copyEnvironment(&dst, src);
    return dst;
}

fn copyEnvironment(dst: *std.process.Environ.Map, src: *const std.process.Environ.Map) !void {
    const keys = src.keys();
    const values = src.values();
    for (keys, values) |key, value| {
        try dst.put(key, value);
    }
}

fn shouldStrip(mode: []const u8) bool {
    return std.mem.eql(u8, mode, "ReleaseFast") or std.mem.eql(u8, mode, "ReleaseSmall");
}

fn expectedExitCode(case: source_owned.Case) u8 {
    if (std.mem.eql(u8, case.id, "releasefast_tiny_scalar")) return 42;
    if (std.mem.eql(u8, case.id, "releasefast_source_tiny_scalar")) return 42;
    if (std.mem.eql(u8, case.id, "releasefast_control_flow_calls")) return 42;
    if (std.mem.eql(u8, case.id, "releasefast_globals_comptime")) return 5;
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_read_global")) return 5;
    if (std.mem.eql(u8, case.id, "releasefast_runtime_switch")) return 13;
    if (std.mem.eql(u8, case.id, "releasefast_source_switch_dense")) return 13;
    if (std.mem.eql(u8, case.id, "releasefast_runtime_global_update")) return 4;
    if (std.mem.eql(u8, case.id, "releasefast_source_globals_comptime_global_counter")) return 4;
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_global_update")) return 4;
    if (std.mem.eql(u8, case.id, "releasesafe_source_globals_checked")) return 4;
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_hidden_access")) return 7;
    if (std.mem.eql(u8, case.id, "releasesmall_source_standalone_extern_exports_hidden_access")) return 7;
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_mix_c_add_zig")) return 7;
    if (std.mem.eql(u8, case.id, "releasesmall_source_standalone_mix_c_files_add_zig")) return 7;
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_mix_c_add_may_panic")) return 5;
    if (std.mem.eql(u8, case.id, "releasesmall_source_standalone_mix_c_files_add_may_panic")) return 5;
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_inherit_want_safety_i64")) return 4;
    if (std.mem.eql(u8, case.id, "releasesmall_source_inherit_want_safety_i64_return")) return 4;
    if (std.mem.eql(u8, case.id, "releasefast_runtime_call_chain")) return 3;
    if (std.mem.eql(u8, case.id, "releasefast_source_control_flow_call_chain")) return 3;
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_call_chain")) return 3;
    if (std.mem.eql(u8, case.id, "releasesafe_source_control_flow_calls_checked")) return 3;
    if (std.mem.eql(u8, case.id, "releasefast_runtime_tls_read")) return 1;
    if (std.mem.eql(u8, case.id, "releasefast_source_tls_concurrency_counter_read")) return 1;
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_tls_read")) return 1;
    if (std.mem.eql(u8, case.id, "releasesafe_source_tls_concurrency_checked_read")) return 1;
    if (std.mem.eql(u8, case.id, "releasefast_runtime_tls_bump")) return 2;
    if (std.mem.eql(u8, case.id, "releasefast_source_tls_concurrency_counter_bump")) return 2;
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_tls_bump")) return 2;
    if (std.mem.eql(u8, case.id, "releasesafe_source_tls_concurrency_checked_bump")) return 2;
    if (std.mem.eql(u8, case.id, "releasefast_runtime_inline_asm_barrier")) return 1;
    if (std.mem.eql(u8, case.id, "releasefast_source_atomics_inline_asm_barrier")) return 1;
    if (std.mem.eql(u8, case.id, "releasefast_runtime_aggregate_pair")) return 1;
    if (std.mem.eql(u8, case.id, "releasefast_source_aggregate_abi_pair")) return 1;
    if (std.mem.eql(u8, case.id, "releasesmall_globals_comptime")) return 5;
    return 0;
}
