const std = @import("std");
const canaries = @import("codegen_canary_shared.zig");
const common = @import("tool_common.zig");
const toolchain = @import("validation/toolchain.zig");
const u = @import("validation/common.zig");

const Case = struct {
    id: []const u8,
    mode: []const u8,
    source: []const u8,
    expected_stdout: []const u8,
    expected_exit: u8,
    proof: Proof,
    compiler_rt: bool = false,
    generic_cfg_selector: bool = false,
    focused_compiler_rt_i128_objects: bool = false,
    focused_compiler_rt_fma_object: bool = false,
    prebuild_start_object: bool = false,
    setcc_semantic_object: bool = false,
    aggregate_sse_semantic_object: bool = false,
};

const Proof = enum {
    syscall_hello,
    compiler_rt_i128_arithmetic,
    compiler_rt_fma,
    setcc_predicates,
    aggregate_sse_returns,

    fn outputStem(proof: Proof) []const u8 {
        return switch (proof) {
            .syscall_hello => ".syscall_hello",
            .compiler_rt_i128_arithmetic => ".compiler_rt_i128_arithmetic",
            .compiler_rt_fma => ".compiler_rt_fma",
            .setcc_predicates => ".setcc_predicates",
            .aggregate_sse_returns => ".aggregate_sse_returns",
        };
    }
};

const cases = [_]Case{
    .{
        .id = "syscall_hello_releasefast",
        .mode = "ReleaseFast",
        .source = "test/zig/integrated/syscall_hello_start.zig",
        .expected_stdout = "hello\n",
        .expected_exit = 0,
        .proof = .syscall_hello,
    },
    .{
        .id = "syscall_hello_releasesafe",
        .mode = "ReleaseSafe",
        .source = "test/zig/integrated/syscall_hello_start.zig",
        .expected_stdout = "hello\n",
        .expected_exit = 0,
        .proof = .syscall_hello,
    },
    .{
        .id = "syscall_hello_releasesmall",
        .mode = "ReleaseSmall",
        .source = "test/zig/integrated/syscall_hello_start.zig",
        .expected_stdout = "hello\n",
        .expected_exit = 0,
        .proof = .syscall_hello,
    },
    .{
        .id = "compiler_rt_i128_arithmetic_releasefast",
        .mode = "ReleaseFast",
        .source = "test/zig/integrated/compiler_rt_i128_arithmetic_start.zig",
        .expected_stdout = "",
        .expected_exit = 0,
        .proof = .compiler_rt_i128_arithmetic,
        .generic_cfg_selector = true,
        .focused_compiler_rt_i128_objects = true,
        .prebuild_start_object = true,
    },
    .{
        .id = "setcc_predicates_releasefast",
        .mode = "ReleaseFast",
        .source = "test/zig/integrated/setcc_predicates_start.zig",
        .expected_stdout = "",
        .expected_exit = 0,
        .proof = .setcc_predicates,
        .prebuild_start_object = true,
        .setcc_semantic_object = true,
    },
    .{
        .id = "compiler_rt_fma_releasefast",
        .mode = "ReleaseFast",
        .source = "test/zig/integrated/compiler_rt_fma_start.zig",
        .expected_stdout = "",
        .expected_exit = 0,
        .proof = .compiler_rt_fma,
        .generic_cfg_selector = true,
        .focused_compiler_rt_fma_object = true,
        .prebuild_start_object = true,
    },
    .{
        .id = "aggregate_sse_returns_releasefast",
        .mode = "ReleaseFast",
        .source = "test/zig/integrated/aggregate_sse_returns_start.zig",
        .expected_stdout = "",
        .expected_exit = 0,
        .proof = .aggregate_sse_returns,
        .prebuild_start_object = true,
        .aggregate_sse_semantic_object = true,
    },
};

comptime {
    if (cases.len != 7) @compileError("mandatory integrated-exe inventory must remain exactly seven cases");
}

fn aggregateTimeout(text: ?[]const u8) !u32 {
    // This wraps the entire integration suite, including every native population
    // in all three modes. Individual commands retain their own deadlines.
    const value = text orelse return 6 * 60 * 60 * 1000;
    if (value.len == 0) return error.InvalidIntegratedTimeout;
    for (value) |byte| if (!std.ascii.isDigit(byte)) return error.InvalidIntegratedTimeout;
    const timeout_ms = std.fmt.parseInt(u32, value, 10) catch return error.InvalidIntegratedTimeout;
    if (timeout_ms == 0) return error.InvalidIntegratedTimeout;
    return timeout_ms;
}

pub fn main(init: std.process.Init) !void {
    const root = init.environ_map.get("ZLLVM_INTEGRATED_OUTPUT_ROOT") orelse return run(init);
    if (init.environ_map.get("ZLLVM_INTEGRATED_WORKER") != null) return run(init);
    var c = try u.Context.init(init);
    u.installSignals();
    const timeout_ms = try aggregateTimeout(c.env.get("ZLLVM_INTEGRATED_TIMEOUT_MS"));
    const output = try c.newOutput(root);
    const storage = @import("validation/storage_workspace.zig");
    const workspace = try storage.start(&c, output, "validation");
    defer if (workspace) |w| w.close(&c);
    var env = try c.env.clone(c.a);
    try env.put("ZLLVM_INTEGRATED_WORKER", "1");
    try env.put("ZLLVM_INTEGRATED_OUTPUT_ROOT", output);
    try storage.exportPaths(&c, &env);
    if (workspace != null) {
        for ([_][2][]const u8{ .{ "ZIG_LOCAL_CACHE_DIR", "local-cache" }, .{ "ZIG_GLOBAL_CACHE_DIR", "global-cache" }, .{ "TMPDIR", "tmp" } }) |setting| {
            if (env.get(setting[0]) == null) {
                const path = try c.temporaryPath(&.{ output, setting[1] });
                try c.mkdir(path);
                try env.put(setting[0], path);
            }
        }
    }
    const argv = try init.minimal.args.toSlice(c.a);
    const command = try c.a.dupe([]const u8, argv);
    command[0] = try std.Io.Dir.cwd().realPathFileAlloc(c.io, "/proc/self/exe", c.a);
    var runner = @import("validation/runner.zig").Runner.init(&c, output);
    const result = try runner.run(command, try c.join(&.{ output, "integrated" }), &env, .{ .timeout_ms = timeout_ms });
    const passed = result.completed and result.code == 0;
    try c.writeJson(try c.join(&.{ output, "report.json" }), .{ .schema = "integrated-workspace-v1", .status = if (passed) "passed" else "failed", .returncode = result.code, .completed = result.completed, .aggregate_timeout_ms = timeout_ms, .timeout_scope = "entire integrated suite; individual command deadlines remain owned by their runners" });
    if (workspace) |w| try w.finish(&c, try c.join(&.{ output, "report.json" }), &.{ try c.join(&.{ output, "commands.json" }), try c.join(&.{ output, "integrated.stdout" }), try c.join(&.{ output, "integrated.stderr" }) });
    // Existing callers parse these summaries; keep the worker's streams intact
    // while also retaining them as evidence for workspace collection.
    try std.Io.File.stdout().writeStreamingAll(c.io, try c.read(try c.join(&.{ output, "integrated.stdout" })));
    try std.Io.File.stderr().writeStreamingAll(c.io, try c.read(try c.join(&.{ output, "integrated.stderr" })));
    if (!passed) std.process.exit(@intCast(if (result.code < 0) 128 - result.code else result.code));
}

test "integrated aggregate deadline covers the full suite and accepts explicit budgets" {
    try std.testing.expectEqual(@as(u32, 21_600_000), try aggregateTimeout(null));
    try std.testing.expectEqual(@as(u32, 3_600_000), try aggregateTimeout("3600000"));
    try std.testing.expectEqual(@as(u32, 7), try aggregateTimeout("0007"));
}

test "integrated aggregate deadline rejects disabled and malformed budgets" {
    for ([_][]const u8{ "", "0", "000", "-1", "+1", "1_000", "1ms", " 10", "10 ", "4294967296" }) |value| {
        try std.testing.expectError(error.InvalidIntegratedTimeout, aggregateTimeout(value));
    }
}

fn run(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    var context = try u.Context.init(init);
    try @import("validation/storage_workspace.zig").adopt(&context);
    if (context.workspace_paths != null) common.workspace_context = &context;
    defer common.workspace_context = null;

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
    try canaries.assertMandatoryMismatchNegative();

    const target_env = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "TARGET");
    defer if (target_env) |value| allocator.free(value);
    const zig_source_env = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "ZIG_SOURCE_DIR");
    defer if (zig_source_env) |value| allocator.free(value);
    const zig_emitter_env = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "ZIG_EMITTER");
    defer if (zig_emitter_env) |value| allocator.free(value);

    const target = normalizeTargetQuery(target_env orelse "x86_64-linux-gnu");
    const zig_source_dir = zig_source_env orelse "../ziglang";
    const default_zig_emitter = try std.fs.path.join(allocator, &.{ zig_source_dir, "build/stage4/bin/zig" });
    defer allocator.free(default_zig_emitter);
    const zig_emitter = zig_emitter_env orelse default_zig_emitter;

    const check_argv = [_][]const u8{ "zig", "run", "tools/check_zig_stage4_emitter.zig" };
    const check_result = try common.runCapture(allocator, io, &check_argv, "tools/check_zig_stage4_emitter.zig");
    common.freeRunResult(allocator, check_result);

    const zllvm_exe = try common.resolveZllvm(init);
    defer allocator.free(zllvm_exe);
    const selection: toolchain.Selection = .{ .zllvm = zllvm_exe, .emitter = zig_emitter, .source = zig_source_dir };

    var env_map = std.process.Environ.Map.init(allocator);
    defer env_map.deinit();
    try copyEnvironment(&env_map, init.environ_map);
    try env_map.put("ZIG_USE_ZLLVM_OBJECT", "1");
    try env_map.put("ZLLVM_PIPELINE", "postopt");
    try env_map.put("ZLLVM_EXE", zllvm_exe);

    const retained_root = init.environ_map.get("ZLLVM_INTEGRATED_OUTPUT_ROOT");
    const temp: common.TempDir = if (retained_root) |path|
        .{ .path = try allocator.dupe(u8, try context.join(&.{path})) }
    else
        try common.TempDir.init(allocator, io, "zig_integrated_exe");
    defer if (retained_root != null) allocator.free(temp.path) else temp.deinit(allocator, io);
    const work: common.TempDir = .{ .path = if (context.workspace_paths) |mapping| mapping.temporary else temp.path };
    const selected_toolchain = try toolchain.record(&context, zllvm_exe, zig_emitter, zig_source_dir);
    const identity_path = try temp.join(allocator, "toolchain.json");
    defer allocator.free(identity_path);
    try context.writeJson(identity_path, selected_toolchain);

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
    var stdout_ok: usize = 0;
    var exit_ok: usize = 0;
    var minimal_inline_asm_syscall_rows: usize = 0;
    var compiler_rt_i128_arithmetic_rows: usize = 0;
    var compiler_rt_fma_rows: usize = 0;
    var setcc_predicate_rows: usize = 0;
    var aggregate_sse_return_rows: usize = 0;
    for (cases) |case| {
        if (mode_filter) |filter| {
            if (!std.mem.eql(u8, filter, case.mode)) continue;
        }
        total += 1;
        const exe = try common.allocTempFile(allocator, work, case.mode, case.proof.outputStem());
        defer allocator.free(exe);
        var case_env = std.process.Environ.Map.init(allocator);
        defer case_env.deinit();
        try copyEnvironment(&case_env, &env_map);
        var extra_objects: std.ArrayList([]const u8) = .empty;
        defer {
            for (extra_objects.items) |object_path| allocator.free(object_path);
            extra_objects.deinit(allocator);
        }
        if (case.prebuild_start_object) {
            const start_obj = try common.allocTempFile(allocator, work, case.id, ".start.o");
            errdefer allocator.free(start_obj);
            try buildCaseSourceObject(allocator, io, zig_emitter, target, start_obj, case);
            try extra_objects.append(allocator, start_obj);
        }
        if (case.focused_compiler_rt_i128_objects) {
            var focused_env = std.process.Environ.Map.init(allocator);
            defer focused_env.deinit();
            try copyEnvironment(&focused_env, &case_env);
            if (case.generic_cfg_selector) {
                try focused_env.put("ZLLVM_GENERIC_CFG_SELECTOR", "1");
            }
            try canaries.runMulti3Canary(allocator, io, work, zllvm_exe, zig_emitter, target, &focused_env);
            const builtins_obj = try common.allocTempFile(allocator, work, case.id, ".builtins.o");
            errdefer allocator.free(builtins_obj);
            const helper_obj = try common.allocTempFile(allocator, work, case.id, ".helper.o");
            errdefer allocator.free(helper_obj);
            const wide_division_obj = try common.allocTempFile(allocator, work, case.id, ".wide-division.o");
            errdefer allocator.free(wide_division_obj);
            const signed_division_obj = try common.allocTempFile(allocator, work, case.id, ".signed-division.o");
            errdefer allocator.free(signed_division_obj);
            const signed_remainder_obj = try common.allocTempFile(allocator, work, case.id, ".signed-remainder.o");
            errdefer allocator.free(signed_remainder_obj);
            try emitFocusedCompilerRtI128Builtins(allocator, io, zllvm_exe, target, builtins_obj, &focused_env);
            try emitFocusedCompilerRtObject(allocator, io, zllvm_exe, target, wide_division_obj, "test/zig/integrated/compiler_rt_udivei5_umodei4.ll", "wide division", &focused_env);
            try emitFocusedCompilerRtObject(allocator, io, zllvm_exe, target, signed_division_obj, "test/zig/integrated/compiler_rt_signed_division.ll", "signed division", &focused_env);
            try emitFocusedCompilerRtObject(allocator, io, zllvm_exe, target, signed_remainder_obj, "test/zig/integrated/compiler_rt_signed_remainder.ll", "signed remainder", &focused_env);
            try buildCompilerRtI128Helper(allocator, io, zig_emitter, target, helper_obj);
            try extra_objects.appendSlice(allocator, &.{ builtins_obj, wide_division_obj, signed_division_obj, signed_remainder_obj, helper_obj });
        } else if (case.focused_compiler_rt_fma_object) {
            var focused_env = std.process.Environ.Map.init(allocator);
            defer focused_env.deinit();
            try copyEnvironment(&focused_env, &case_env);
            if (case.generic_cfg_selector) {
                try focused_env.put("ZLLVM_GENERIC_CFG_SELECTOR", "1");
            }
            const fma_obj = try common.allocTempFile(allocator, work, case.id, ".fma.o");
            errdefer allocator.free(fma_obj);
            const fma_helpers_obj = try common.allocTempFile(allocator, work, case.id, ".fma-helpers.o");
            errdefer allocator.free(fma_helpers_obj);
            try canaries.buildAndValidateFmaObjects(allocator, io, zllvm_exe, zig_emitter, target, fma_obj, fma_helpers_obj, &focused_env);
            try extra_objects.appendSlice(allocator, &.{ fma_obj, fma_helpers_obj });
        } else if (case.setcc_semantic_object) {
            const predicate_obj = try common.allocTempFile(allocator, work, case.id, ".predicates.o");
            errdefer allocator.free(predicate_obj);
            try emitSetccSemanticObject(allocator, io, predicate_obj);
            try extra_objects.append(allocator, predicate_obj);
        } else if (case.aggregate_sse_semantic_object) {
            const aggregate_obj = try common.allocTempFile(allocator, work, case.id, ".aggregates.o");
            errdefer allocator.free(aggregate_obj);
            try emitAggregateSseSemanticObject(allocator, io, aggregate_obj);
            try extra_objects.append(allocator, aggregate_obj);
        } else if (case.generic_cfg_selector) {
            try case_env.put("ZLLVM_GENERIC_CFG_SELECTOR", "1");
        }
        try buildExecutable(allocator, io, zig_emitter, target, exe, case, extra_objects.items, &case_env);
        build_ok += 1;
        try runExecutable(allocator, io, exe, case);
        run_ok += 1;
        stdout_ok += 1;
        exit_ok += 1;
        switch (case.proof) {
            .syscall_hello => minimal_inline_asm_syscall_rows += 1,
            .compiler_rt_i128_arithmetic => compiler_rt_i128_arithmetic_rows += 1,
            .compiler_rt_fma => compiler_rt_fma_rows += 1,
            .setcc_predicates => setcc_predicate_rows += 1,
            .aggregate_sse_returns => aggregate_sse_return_rows += 1,
        }
        try stdout_writer.interface.print("ok zig-integrated-exe case={s} mode={s} proof={s} exit=0\n", .{
            case.id,
            case.mode,
            @tagName(case.proof),
        });
        try stdout_writer.interface.flush();
    }

    if (total == 0) {
        try common.validationError(io, "integrated exe runner selected no cases\n", .{});
    }
    try stdout_writer.interface.print(
        "summary zig-integrated-exe total={} build_ok={} run_ok={} stdout_ok={} exit_ok={} minimal_inline_asm_syscall_rows={} compiler_rt_i128_arithmetic_rows={} compiler_rt_fma_rows={} setcc_predicate_rows={} aggregate_sse_return_rows={} local_fail=0\n",
        .{
            total,
            build_ok,
            run_ok,
            stdout_ok,
            exit_ok,
            minimal_inline_asm_syscall_rows,
            compiler_rt_i128_arithmetic_rows,
            compiler_rt_fma_rows,
            setcc_predicate_rows,
            aggregate_sse_return_rows,
        },
    );
    try stdout_writer.interface.flush();
    // Separate population: these programs extend the mandatory executable
    // canaries without reinterpreting the original seven integrated cases.
    try @import("run_behavioral_diff.zig").run(init);
    try @import("run_memset_diff.zig").run(init);
    try @import("run_memcpy_diff.zig").run(init);
    try @import("run_byte_loops_diff.zig").run(init);
    const cohort_controls_root = try temp.join(allocator, "execution-breadth-controls");
    defer allocator.free(cohort_controls_root);
    const cohort_controls = try common.runCapture(allocator, io, &.{
        "zig",           "build",              "execution-breadth-controls", "--",
        "--output-root", cohort_controls_root, "--zig-emitter",              zig_emitter,
    }, "compiler-core execution breadth controls");
    defer common.freeRunResult(allocator, cohort_controls);
    try stdout_writer.interface.writeAll(cohort_controls.stdout);
    try stdout_writer.interface.flush();
    const program_root = try temp.join(allocator, "unchanged-hello-libc");
    defer allocator.free(program_root);
    const program_command = try selection.command(allocator, .program, program_root, &.{});
    defer allocator.free(program_command);
    const program_result = try common.runCapture(allocator, io, program_command, "unchanged upstream hello libc");
    defer common.freeRunResult(allocator, program_result);
    try stdout_writer.interface.writeAll(program_result.stdout);
    try stdout_writer.interface.flush();
    if (!common.termOk(program_result.term)) try common.forwardCommandFailure(io, "unchanged upstream hello libc", program_result);
    for ([_][]const u8{ "recursive_fibonacci", "optionals", "taking_pointer_of_global_tagged_union", "array_in_anon_struct", "while_loops", "migrate_langref" }) |program| {
        const label = try std.fmt.allocPrint(allocator, "unchanged upstream {s}", .{program});
        defer allocator.free(label);
        const stem = try std.fmt.allocPrint(allocator, "unchanged-{s}", .{program});
        defer allocator.free(stem);
        const root = try temp.join(allocator, stem);
        defer allocator.free(root);
        const manifest = try std.fmt.allocPrint(allocator, "test/real_programs/{s}.json", .{program});
        defer allocator.free(manifest);
        const extra = try std.mem.concat(allocator, []const u8, &.{ &.{ "--manifest", manifest, "--codegen-reachable" }, if (std.mem.eql(u8, program, "migrate_langref")) &.{"--replay-owners"} else &.{} });
        defer allocator.free(extra);
        const command = try selection.command(allocator, .program, root, extra);
        defer allocator.free(command);
        const unchanged_result = try common.runCapture(allocator, io, command, label);
        defer common.freeRunResult(allocator, unchanged_result);
        try stdout_writer.interface.writeAll(unchanged_result.stdout);
        try stdout_writer.interface.flush();
        if (!common.termOk(unchanged_result.term)) try common.forwardCommandFailure(io, label, unchanged_result);
    }
    const input_program_root = try temp.join(allocator, "input-program");
    defer allocator.free(input_program_root);
    const input_program_command = try selection.command(allocator, .input_program, input_program_root, &.{});
    defer allocator.free(input_program_command);
    const input_program_result = try common.runCapture(allocator, io, input_program_command, "unchanged input-driven JSON-dump");
    defer common.freeRunResult(allocator, input_program_result);
    try stdout_writer.interface.writeAll(input_program_result.stdout);
    try stdout_writer.interface.flush();
    if (!common.termOk(input_program_result.term)) try common.forwardCommandFailure(io, "unchanged input-driven JSON-dump", input_program_result);
    const c_program_root = try temp.join(allocator, "unchanged-upstream-c");
    defer allocator.free(c_program_root);
    const c_program_command = try selection.command(allocator, .upstream_c, c_program_root, &.{});
    defer allocator.free(c_program_command);
    const c_program_result = try common.runCapture(allocator, io, c_program_command, "unchanged upstream C fixture");
    defer common.freeRunResult(allocator, c_program_result);
    try stdout_writer.interface.writeAll(c_program_result.stdout);
    try stdout_writer.interface.flush();
    if (!common.termOk(c_program_result.term)) try common.forwardCommandFailure(io, "unchanged upstream C fixture", c_program_result);
    try toolchain.verify(&context, selected_toolchain);
}

fn emitAggregateSseSemanticObject(
    allocator: std.mem.Allocator,
    io: std.Io,
    object_path: []const u8,
) !void {
    const argv = [_][]const u8{
        "zig",
        "run",
        "src/aggregate_sse_semantic_object.zig",
        "--",
        object_path,
    };
    const result = try common.runCapture(allocator, io, &argv, "z_llvm aggregate SSE semantic object");
    common.freeRunResult(allocator, result);
}

fn emitSetccSemanticObject(
    allocator: std.mem.Allocator,
    io: std.Io,
    object_path: []const u8,
) !void {
    const argv = [_][]const u8{
        "zig",
        "run",
        "src/setcc_semantic_object.zig",
        "--",
        object_path,
    };
    const result = try common.runCapture(allocator, io, &argv, "z_llvm setcc semantic object");
    common.freeRunResult(allocator, result);
}

fn buildExecutable(
    allocator: std.mem.Allocator,
    io: std.Io,
    zig_emitter: []const u8,
    target: []const u8,
    exe: []const u8,
    case: Case,
    extra_objects: []const []const u8,
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
        "-fno-stack-protector",
        "-fno-unwind-tables",
        "-fentry=_start",
        "-O",
        case.mode,
        "-target",
        target,
        emit_arg,
    });
    if (!case.prebuild_start_object) {
        try argv.insert(allocator, argv.items.len - 1, case.source);
    }
    try argv.insertSlice(allocator, argv.items.len - 1, extra_objects);
    if (!case.compiler_rt) {
        try argv.insert(allocator, 4, "-fno-compiler-rt");
    }
    const label = try std.fmt.allocPrint(allocator, "patched Zig integrated z_llvm build-exe {s} {s}", .{ case.id, case.mode });
    defer allocator.free(label);
    const result = try common.runCaptureEnv(allocator, io, argv.items, label, env_map);
    common.freeRunResult(allocator, result);
}

fn buildCaseSourceObject(
    allocator: std.mem.Allocator,
    io: std.Io,
    zig_emitter: []const u8,
    target: []const u8,
    object_path: []const u8,
    case: Case,
) !void {
    const emit_arg = try std.fmt.allocPrint(allocator, "-femit-bin={s}", .{object_path});
    defer allocator.free(emit_arg);
    const argv = [_][]const u8{
        zig_emitter,
        "build-obj",
        "-fllvm",
        "-flibllvm",
        "-fno-compiler-rt",
        "-fno-stack-protector",
        "-fno-unwind-tables",
        "-O",
        case.mode,
        "-target",
        target,
        case.source,
        emit_arg,
    };
    const label = try std.fmt.allocPrint(allocator, "patched Zig integrated start object {s} {s}", .{ case.id, case.mode });
    defer allocator.free(label);
    const result = try common.runCapture(allocator, io, &argv, label);
    common.freeRunResult(allocator, result);
}

fn emitFocusedCompilerRtI128Builtins(
    allocator: std.mem.Allocator,
    io: std.Io,
    zllvm_exe: []const u8,
    target: []const u8,
    object_path: []const u8,
    env_map: *const std.process.Environ.Map,
) !void {
    const target_arg = try std.fmt.allocPrint(allocator, "--target={s}", .{zllvmTarget(target)});
    defer allocator.free(target_arg);
    const argv = [_][]const u8{
        zllvm_exe,
        "--emit=obj",
        target_arg,
        "--input-limit=1048576",
        "test/zig/integrated/compiler_rt_i128_builtins.ll",
    };
    const result = try common.runCaptureEnv(allocator, io, &argv, "z_llvm focused compiler_rt i128 builtins", env_map);
    defer common.freeRunResult(allocator, result);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = object_path, .data = result.stdout });
}

fn emitFocusedCompilerRtObject(
    allocator: std.mem.Allocator,
    io: std.Io,
    zllvm_exe: []const u8,
    target: []const u8,
    object_path: []const u8,
    input_path: []const u8,
    description: []const u8,
    env_map: *const std.process.Environ.Map,
) !void {
    const target_arg = try std.fmt.allocPrint(allocator, "--target={s}", .{zllvmTarget(target)});
    defer allocator.free(target_arg);
    const argv = [_][]const u8{
        zllvm_exe,
        "--emit=obj",
        target_arg,
        "--input-limit=1048576",
        input_path,
    };
    const label = try std.fmt.allocPrint(allocator, "z_llvm focused compiler_rt {s}", .{description});
    defer allocator.free(label);
    const result = try common.runCaptureEnv(allocator, io, &argv, label, env_map);
    defer common.freeRunResult(allocator, result);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = object_path, .data = result.stdout });
}

fn buildCompilerRtI128Helper(
    allocator: std.mem.Allocator,
    io: std.Io,
    zig_emitter: []const u8,
    target: []const u8,
    object_path: []const u8,
) !void {
    const emit_arg = try std.fmt.allocPrint(allocator, "-femit-bin={s}", .{object_path});
    defer allocator.free(emit_arg);
    const argv = [_][]const u8{
        zig_emitter,
        "build-obj",
        "-fllvm",
        "-flibllvm",
        "-fno-compiler-rt",
        "-fno-stack-protector",
        "-fno-unwind-tables",
        "-O",
        "ReleaseFast",
        "-target",
        target,
        "test/zig/integrated/compiler_rt_i128_helper.zig",
        emit_arg,
    };
    const result = try common.runCapture(allocator, io, &argv, "patched Zig compiler_rt i128 helper object");
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
        .exited => |code| {
            if (code != case.expected_exit) {
                try common.validationError(io, "integrated exe case={s} mode={s} exited with code {}, expected exit code {}\n", .{ case.id, case.mode, code, case.expected_exit });
            }
        },
        else => try common.validationError(io, "integrated exe case={s} mode={s} exited with {any}, expected exit code {}\n", .{ case.id, case.mode, result.term, case.expected_exit }),
    }
    if (!std.mem.eql(u8, result.stdout, case.expected_stdout)) {
        try common.validationError(io, "integrated exe case={s} mode={s} stdout mismatch: expected {s}, got {s}\n", .{ case.id, case.mode, case.expected_stdout, result.stdout });
    }
}

fn normalizeTargetQuery(target: []const u8) []const u8 {
    if (std.mem.eql(u8, target, "x86_64-unknown-linux-gnu")) {
        return "x86_64-linux-gnu";
    }
    return target;
}

fn zllvmTarget(target: []const u8) []const u8 {
    if (std.mem.eql(u8, target, "x86_64-linux-gnu")) {
        return "x86_64-unknown-linux-gnu";
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
