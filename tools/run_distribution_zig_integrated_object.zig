const std = @import("std");
const common = @import("tool_common.zig");

const Validation = enum {
    executable,
    link_only,
};

const Pipeline = enum {
    postopt,
    preopt,
};

const Case = struct {
    id: []const u8,
    wrapper: []const u8,
    covered_fixture: []const u8,
    mode: []const u8,
    validation: Validation,
    proof: []const u8 = "integrated Zig build-obj object path plus Zig build-exe native link",
    fallback: []const u8,
};

const cases = [_]Case{
    .{
        .id = "releasefast_tiny_scalar",
        .wrapper = "test/zig/integrated/tiny_scalar_main.zig",
        .covered_fixture = "test/zig/inputs/tiny_scalar.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld",
    },
    .{
        .id = "releasefast_integers",
        .wrapper = "test/zig/integrated/integers_main.zig",
        .covered_fixture = "test/zig/inputs/integers.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld",
    },
    .{
        .id = "releasefast_control_flow_calls",
        .wrapper = "test/zig/integrated/control_flow_calls_main.zig",
        .covered_fixture = "test/zig/inputs/control_flow_calls.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld",
    },
    .{
        .id = "releasefast_globals_comptime",
        .wrapper = "test/zig/integrated/globals_comptime_main.zig",
        .covered_fixture = "test/zig/inputs/globals_comptime.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld",
    },
    .{
        .id = "releasefast_error_switch",
        .wrapper = "test/zig/integrated/error_switch_main.zig",
        .covered_fixture = "test/zig/inputs/error_switch.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld",
    },
    .{
        .id = "releasesafe_error_switch",
        .wrapper = "test/zig/integrated/error_switch_main.zig",
        .covered_fixture = "test/zig/inputs/error_switch.zig",
        .mode = "ReleaseSafe",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld",
    },
    .{
        .id = "releasesafe_tiny_scalar_runtime_boundary",
        .wrapper = "test/zig/integrated/tiny_scalar_releasesafe_boundary_main.zig",
        .covered_fixture = "test/zig/inputs/tiny_scalar.zig",
        .mode = "ReleaseSafe",
        .validation = .link_only,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:zig-panic-runtime",
    },
    .{
        .id = "releasesmall_globals_comptime",
        .wrapper = "test/zig/integrated/globals_comptime_small_main.zig",
        .covered_fixture = "test/zig/inputs/globals_comptime.zig",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld",
    },
    .{
        .id = "releasesmall_i64_arithmetic",
        .wrapper = "test/zig/integrated/i64_arithmetic_main.zig",
        .covered_fixture = "test/zig/inputs/i64_arithmetic.zig",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld",
    },
    .{
        .id = "releasesmall_base64_table_lookup",
        .wrapper = "test/zig/integrated/base64_table_lookup_main.zig",
        .covered_fixture = "test/zig/inputs/base64_table_lookup.zig",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld",
    },
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();
    _ = args.next();
    var pipeline: Pipeline = .postopt;
    var mode_filter: ?[]const u8 = null;
    var case_filter: ?[]const u8 = null;
    var use_ir_writer = false;
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--pipeline=postopt")) {
            pipeline = .postopt;
        } else if (std.mem.eql(u8, arg, "--pipeline=preopt")) {
            pipeline = .preopt;
        } else if (std.mem.eql(u8, arg, "--ir-writer")) {
            use_ir_writer = true;
            pipeline = .preopt;
        } else if (std.mem.startsWith(u8, arg, "--mode=")) {
            mode_filter = arg["--mode=".len..];
        } else if (std.mem.startsWith(u8, arg, "--case=")) {
            case_filter = arg["--case=".len..];
        } else {
            try common.validationError(io, "unexpected argument for integrated object runner: {s}\n", .{arg});
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

    const target = normalizeZigTarget(target_env orelse "x86_64-linux-gnu");
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
    if (use_ir_writer) {
        try env_map.put("ZIG_USE_ZLLVM_IR_WRITER", "1");
    } else {
        try env_map.put("ZIG_USE_ZLLVM_OBJECT", "1");
    }
    try env_map.put("ZLLVM_PIPELINE", pipelineName(pipeline));
    try env_map.put("ZLLVM_EXE", zllvm_exe);

    const temp = try common.TempDir.init(allocator, io, "zig_integrated_object");
    defer temp.deinit(allocator, io);

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    try stdout_writer.interface.print(
        "zig-integrated-object target={s} pipeline={s} linker=zig build-exe -fno-lld hook={s} zllvm={s}\n",
        .{ target, pipelineName(pipeline), if (use_ir_writer) "ZIG_USE_ZLLVM_IR_WRITER" else "ZIG_USE_ZLLVM_OBJECT", zllvm_exe },
    );
    try stdout_writer.interface.flush();

    var executable_ok: usize = 0;
    var link_only_ok: usize = 0;
    var total: usize = 0;
    for (cases) |case| {
        if (mode_filter) |filter| {
            if (!std.mem.eql(u8, filter, case.mode)) continue;
        }
        if (case_filter) |filter| {
            if (!std.mem.eql(u8, filter, case.id)) continue;
        }
        try requirePairing(case);
        total += 1;
        const exe = try common.allocTempFile(allocator, temp, case.id, "_integrated");
        defer allocator.free(exe);
        const object = try common.allocTempFile(allocator, temp, case.id, ".o");
        defer allocator.free(object);
        const marker = try common.allocTempFile(allocator, temp, case.id, "_zllvm_marker.txt");
        defer allocator.free(marker);
        try env_map.put("ZLLVM_MARKER_PATH", marker);
        try env_map.put("ZLLVM_ZIG_MODE", case.mode);
        try env_map.put("ZLLVM_CASE_ID", case.id);
        try env_map.put("ZLLVM_WRAPPER", case.wrapper);
        try buildIntegratedObject(allocator, io, zig_emitter, target, object, case, &env_map);
        try requireHookMarker(allocator, io, marker, case, pipeline, use_ir_writer);
        try linkIntegratedObject(allocator, io, target, object, exe);
        if (case.validation == .executable) {
            const run_argv = [_][]const u8{exe};
            const run_result = try common.runCapture(allocator, io, &run_argv, exe);
            common.freeRunResult(allocator, run_result);
            executable_ok += 1;
        } else {
            link_only_ok += 1;
        }
        try stdout_writer.interface.print(
            "ok zig-integrated-object {s} wrapper={s} covered_fixture={s} mode={s} proof=\"{s}\" validation={s} fallback={s}\n",
            .{ case.id, case.wrapper, case.covered_fixture, case.mode, effectiveProof(use_ir_writer), validationName(case.validation), effectiveFallback(case, use_ir_writer) },
        );
        try stdout_writer.interface.flush();
    }

    try stdout_writer.interface.print(
        "summary zig-integrated-object pipeline={s} ir_writer={} total={} executable_ok={} link_only_ok={} local_fail=0\n",
        .{ pipelineName(pipeline), use_ir_writer, total, executable_ok, link_only_ok },
    );
    try stdout_writer.interface.flush();
}

fn copyEnvironment(dst: *std.process.Environ.Map, src: *const std.process.Environ.Map) !void {
    const keys = src.keys();
    const values = src.values();
    for (keys, values) |key, value| {
        try dst.put(key, value);
    }
}

fn requirePairing(case: Case) !void {
    if (case.wrapper.len == 0 or case.covered_fixture.len == 0 or case.mode.len == 0 or case.proof.len == 0) {
        return error.MissingFixturePairing;
    }
}

fn requireHookMarker(
    allocator: std.mem.Allocator,
    io: std.Io,
    marker: []const u8,
    case: Case,
    pipeline: Pipeline,
    use_ir_writer: bool,
) !void {
    const contents = std.Io.Dir.cwd().readFileAlloc(io, marker, allocator, .limited(1024 * 1024)) catch |err| {
        try common.validationError(io, "missing z_llvm hook marker for {s}: {t}\n", .{ case.id, err });
    };
    defer allocator.free(contents);
    try requireMarkerField(io, contents, "pipeline", pipelineName(pipeline), case);
    try requireMarkerField(io, contents, "target", "x86_64-unknown-linux-gnu", case);
    try requireMarkerContains(io, contents, "zig_target=x86_64", case);
    try requireMarkerContains(io, contents, "object=", case);
    try requireMarkerField(io, contents, "case_id", case.id, case);
    try requireMarkerField(io, contents, "wrapper", case.wrapper, case);
    try requireMarkerField(io, contents, "mode", case.mode, case);
    switch (pipeline) {
        .postopt => try requireMarkerField(io, contents, "zllvm_passes", "", case),
        .preopt => try requireMarkerField(io, contents, "zllvm_passes", acceptedPipeline(case.mode), case),
    }
    if (use_ir_writer) try requireMarkerField(io, contents, "ir_writer", "zig-owned-text", case);
}

fn requireMarkerField(io: std.Io, contents: []const u8, field: []const u8, value: []const u8, case: Case) !void {
    var buffer: [512]u8 = undefined;
    const needle = try std.fmt.bufPrint(&buffer, "{s}={s}", .{ field, value });
    try requireMarkerContains(io, contents, needle, case);
}

fn requireMarkerContains(io: std.Io, contents: []const u8, needle: []const u8, case: Case) !void {
    if (std.mem.indexOf(u8, contents, needle) != null) return;
    try common.validationError(io, "z_llvm hook marker for {s} missing {s}\n", .{ case.id, needle });
}

fn buildIntegratedObject(
    allocator: std.mem.Allocator,
    io: std.Io,
    zig_emitter: []const u8,
    target: []const u8,
    object: []const u8,
    case: Case,
    env_map: *const std.process.Environ.Map,
) !void {
    const emit_arg = try std.fmt.allocPrint(allocator, "-femit-bin={s}", .{object});
    defer allocator.free(emit_arg);

    var argv: std.ArrayList([]const u8) = .empty;
    defer argv.deinit(allocator);
    try argv.appendSlice(allocator, &.{
        zig_emitter,
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
        target,
        case.wrapper,
        emit_arg,
    });
    const result = try common.runCaptureEnv(allocator, io, argv.items, "patched Zig integrated z_llvm build-obj emit", env_map);
    common.freeRunResult(allocator, result);
}

fn linkIntegratedObject(
    allocator: std.mem.Allocator,
    io: std.Io,
    target: []const u8,
    object: []const u8,
    exe: []const u8,
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
    const result = try common.runCapture(allocator, io, &argv, "zig build-exe -fno-lld integrated object");
    common.freeRunResult(allocator, result);
}

fn validationName(validation: Validation) []const u8 {
    return switch (validation) {
        .executable => "executable",
        .link_only => "link-only",
    };
}

fn effectiveProof(use_ir_writer: bool) []const u8 {
    if (use_ir_writer) return "integrated Zig-owned textual IR writer plus z_llvm optimizer/object path plus Zig build-exe native link";
    return "integrated Zig build-obj object path plus Zig build-exe native link";
}

fn effectiveFallback(case: Case, use_ir_writer: bool) []const u8 {
    if (!use_ir_writer) return case.fallback;
    if (case.validation == .link_only) {
        return "ir-construction:zig-owned-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:zig-panic-runtime";
    }
    return "ir-construction:zig-owned-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld";
}

fn pipelineName(pipeline: Pipeline) []const u8 {
    return switch (pipeline) {
        .postopt => "postopt",
        .preopt => "preopt",
    };
}

fn acceptedPipeline(mode: []const u8) []const u8 {
    if (std.mem.eql(u8, mode, "ReleaseFast")) return "zig-release-fast-accepted";
    if (std.mem.eql(u8, mode, "ReleaseSafe")) return "zig-release-safe-accepted";
    if (std.mem.eql(u8, mode, "ReleaseSmall")) return "zig-release-small-accepted";
    return "";
}

fn shouldStrip(mode: []const u8) bool {
    return std.mem.eql(u8, mode, "ReleaseFast") or std.mem.eql(u8, mode, "ReleaseSmall");
}

fn normalizeZigTarget(target: []const u8) []const u8 {
    if (std.mem.eql(u8, target, "x86_64-unknown-linux-gnu")) return "x86_64-linux-gnu";
    if (std.mem.eql(u8, target, "x86_64-unknown-linux-musl")) return "x86_64-linux-musl";
    return target;
}
