const std = @import("std");
const common = @import("tool_common.zig");

const multi3_instruction_stream_sha256 = "8f962b4bda72349aac1464efd86f13daf18ae3595171d7f32548feb46ee82e61";
const multi3_symbol_bytes_sha256 = "f1c97aee4bb07d1ef27ebd12ec2236a2a390faaa95514436dfb282af5e2149ec";
const fma_instruction_stream_sha256 = "cc791b46ef93f564040e5245874216a7aa267df7319e84135862177f4eff776a";
const fma_symbol_bytes_sha256 = "3571863e4438990f77b5a159b95a85de16dea0d50db7a935406b54b09bee9abb";
const fma_ldexp_symbol_bytes_sha256 = "d8653232177f52c3636bdfb9746b44bd16259a762e82ac0cec43d9e4798c1689";
const fma_add_and_denorm_symbol_bytes_sha256 = "639a29b4ba8eae68fc0b87e7a9be45541616146c5ee14b651129b2eaf427054c";

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
        const exe = try common.allocTempFile(allocator, temp, case.mode, case.proof.outputStem());
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
            const start_obj = try common.allocTempFile(allocator, temp, case.id, ".start.o");
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
            try runFocusedCompilerRtMulti3Canary(allocator, io, temp, zllvm_exe, zig_emitter, target, &focused_env);
            const builtins_obj = try common.allocTempFile(allocator, temp, case.id, ".builtins.o");
            errdefer allocator.free(builtins_obj);
            const helper_obj = try common.allocTempFile(allocator, temp, case.id, ".helper.o");
            errdefer allocator.free(helper_obj);
            const wide_division_obj = try common.allocTempFile(allocator, temp, case.id, ".wide-division.o");
            errdefer allocator.free(wide_division_obj);
            const signed_division_obj = try common.allocTempFile(allocator, temp, case.id, ".signed-division.o");
            errdefer allocator.free(signed_division_obj);
            const signed_remainder_obj = try common.allocTempFile(allocator, temp, case.id, ".signed-remainder.o");
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
            const fma_obj = try common.allocTempFile(allocator, temp, case.id, ".fma.o");
            errdefer allocator.free(fma_obj);
            const fma_helpers_obj = try common.allocTempFile(allocator, temp, case.id, ".fma-helpers.o");
            errdefer allocator.free(fma_helpers_obj);
            try emitFocusedCompilerRtFmaObject(allocator, io, zllvm_exe, target, fma_obj, &focused_env);
            try buildCompilerRtFmaHelpers(allocator, io, zig_emitter, target, fma_helpers_obj);
            try inspectFocusedCompilerRtFmaObjects(allocator, io, fma_obj, fma_helpers_obj);
            try extra_objects.appendSlice(allocator, &.{ fma_obj, fma_helpers_obj });
        } else if (case.setcc_semantic_object) {
            const predicate_obj = try common.allocTempFile(allocator, temp, case.id, ".predicates.o");
            errdefer allocator.free(predicate_obj);
            try emitSetccSemanticObject(allocator, io, predicate_obj);
            try extra_objects.append(allocator, predicate_obj);
        } else if (case.aggregate_sse_semantic_object) {
            const aggregate_obj = try common.allocTempFile(allocator, temp, case.id, ".aggregates.o");
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
}

fn emitFocusedCompilerRtFmaObject(
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
        "test/zig/integrated/compiler_rt_fma.ll",
    };
    const result = try common.runCaptureEnv(allocator, io, &argv, "z_llvm focused compiler_rt fma", env_map);
    defer common.freeRunResult(allocator, result);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = object_path, .data = result.stdout });

    const assembly_argv = [_][]const u8{
        zllvm_exe,
        "--emit=asm",
        target_arg,
        "--input-limit=1048576",
        "test/zig/integrated/compiler_rt_fma.ll",
    };
    const assembly_result = try common.runCaptureEnv(allocator, io, &assembly_argv, "z_llvm focused compiler_rt fma assembly", env_map);
    defer common.freeRunResult(allocator, assembly_result);
    try requireSha256(io, "fma canonical machine instruction stream", assembly_result.stdout, fma_instruction_stream_sha256);
}

fn buildCompilerRtFmaHelpers(
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
        "test/zig/integrated/compiler_rt_fma_helpers.ll",
        emit_arg,
    };
    const result = try common.runCapture(allocator, io, &argv, "pinned Zig frozen compiler_rt fma helper object");
    common.freeRunResult(allocator, result);
}

fn inspectFocusedCompilerRtFmaObjects(
    allocator: std.mem.Allocator,
    io: std.Io,
    fma_object_path: []const u8,
    helper_object_path: []const u8,
) !void {
    const fma_text_path = try std.fmt.allocPrint(allocator, "{s}.text", .{fma_object_path});
    defer allocator.free(fma_text_path);
    const helper_text_path = try std.fmt.allocPrint(allocator, "{s}.text", .{helper_object_path});
    defer allocator.free(helper_text_path);

    const defined_argv = [_][]const u8{ "llvm-nm-22", "--defined-only", fma_object_path };
    const defined = try common.runCapture(allocator, io, &defined_argv, "compiler_rt fma defined-symbol inspection");
    defer common.freeRunResult(allocator, defined);
    if (std.mem.indexOf(u8, defined.stdout, "compiler_rt.fma.fma") == null) {
        try common.validationError(io, "compiler_rt fma object is missing its emitted definition\n", .{});
    }

    const helper_defined_argv = [_][]const u8{ "llvm-nm-22", "--defined-only", helper_object_path };
    const helper_defined = try common.runCapture(allocator, io, &helper_defined_argv, "compiler_rt fma helper defined-symbol inspection");
    defer common.freeRunResult(allocator, helper_defined);
    const required_helpers = [_][]const u8{
        "math.ldexp.ldexp__anon_5959",
        "compiler_rt.fma.add_and_denorm",
        "zllvm_fma_proof_ldexp",
        "zllvm_fma_proof_add_and_denorm",
    };
    for (required_helpers) |symbol| {
        if (std.mem.indexOf(u8, helper_defined.stdout, symbol) == null) {
            try common.validationError(io, "compiler_rt fma object is missing required definition {s}\n", .{symbol});
        }
    }

    const undefined_argv = [_][]const u8{ "llvm-nm-22", "--undefined-only", fma_object_path };
    const undefined_symbols = try common.runCapture(allocator, io, &undefined_argv, "compiler_rt fma undefined-symbol inspection");
    defer common.freeRunResult(allocator, undefined_symbols);
    var undefined_count: usize = 0;
    var undefined_lines = std.mem.splitScalar(u8, undefined_symbols.stdout, '\n');
    while (undefined_lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t\r");
        if (trimmed.len == 0) continue;
        undefined_count += 1;
        if (!std.mem.endsWith(u8, trimmed, "math.ldexp.ldexp__anon_5959") and
            !std.mem.endsWith(u8, trimmed, "compiler_rt.fma.add_and_denorm"))
        {
            try common.validationError(io, "compiler_rt fma object has forbidden external dependency: {s}\n", .{trimmed});
        }
    }
    if (undefined_count != 2) {
        try common.validationError(io, "compiler_rt fma object expected exactly two frozen internal helper references, found {}\n", .{undefined_count});
    }

    const fma_dump_arg = try std.fmt.allocPrint(allocator, "--dump-section=.text={s}", .{fma_text_path});
    defer allocator.free(fma_dump_arg);
    const fma_dump_argv = [_][]const u8{ "llvm-objcopy-22", fma_dump_arg, fma_object_path };
    const fma_dump = try common.runCapture(allocator, io, &fma_dump_argv, "compiler_rt fma symbol-byte extraction");
    defer common.freeRunResult(allocator, fma_dump);
    const fma_symbol_bytes = try std.Io.Dir.cwd().readFileAlloc(io, fma_text_path, allocator, .limited(1024 * 1024));
    defer allocator.free(fma_symbol_bytes);
    if (fma_symbol_bytes.len != 4114) {
        try common.validationError(io, "compiler_rt fma symbol size changed: expected 4114, got {}\n", .{fma_symbol_bytes.len});
    }
    try requireSha256(io, "fma exact symbol bytes", fma_symbol_bytes, fma_symbol_bytes_sha256);

    const helper_undefined_argv = [_][]const u8{ "llvm-nm-22", "--undefined-only", helper_object_path };
    const helper_undefined = try common.runCapture(allocator, io, &helper_undefined_argv, "compiler_rt fma helper undefined-symbol inspection");
    defer common.freeRunResult(allocator, helper_undefined);
    if (std.mem.trim(u8, helper_undefined.stdout, " \t\r\n").len != 0) {
        try common.validationError(io, "compiler_rt fma helper object has external dependencies (host fallback forbidden):\n{s}\n", .{helper_undefined.stdout});
    }

    const helper_dump_arg = try std.fmt.allocPrint(allocator, "--dump-section=.text={s}", .{helper_text_path});
    defer allocator.free(helper_dump_arg);
    const helper_dump_argv = [_][]const u8{ "llvm-objcopy-22", helper_dump_arg, helper_object_path };
    const helper_dump = try common.runCapture(allocator, io, &helper_dump_argv, "compiler_rt fma helper symbol-byte extraction");
    defer common.freeRunResult(allocator, helper_dump);
    const helper_text = try std.Io.Dir.cwd().readFileAlloc(io, helper_text_path, allocator, .limited(1024 * 1024));
    defer allocator.free(helper_text);
    if (helper_text.len != 501) {
        try common.validationError(io, "compiler_rt fma helper text size changed: expected 501, got {}\n", .{helper_text.len});
    }
    try requireSha256(io, "fma internal ldexp exact symbol bytes", helper_text[0x000..0x15e], fma_ldexp_symbol_bytes_sha256);
    try requireSha256(io, "fma internal add_and_denorm exact symbol bytes", helper_text[0x160..0x1db], fma_add_and_denorm_symbol_bytes_sha256);

    const disassembly_argv = [_][]const u8{ "llvm-objdump-22", "-dr", fma_object_path };
    const disassembly = try common.runCapture(allocator, io, &disassembly_argv, "compiler_rt fma recursive-call inspection");
    defer common.freeRunResult(allocator, disassembly);
    var lines = std.mem.splitScalar(u8, disassembly.stdout, '\n');
    while (lines.next()) |line| {
        if (std.mem.indexOf(u8, line, "R_X86_64") != null and std.mem.indexOf(u8, line, "compiler_rt.fma.fma") != null) {
            try common.validationError(io, "compiler_rt fma object contains a recursive fma call: {s}\n", .{line});
        }
    }
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

fn runFocusedCompilerRtMulti3Canary(
    allocator: std.mem.Allocator,
    io: std.Io,
    temp: common.TempDir,
    zllvm_exe: []const u8,
    zig_emitter: []const u8,
    target: []const u8,
    env_map: *const std.process.Environ.Map,
) !void {
    const object_path = try common.allocTempFile(allocator, temp, "compiler_rt_multi3_canary", ".o");
    defer allocator.free(object_path);
    const text_path = try common.allocTempFile(allocator, temp, "compiler_rt_multi3_canary", ".text");
    defer allocator.free(text_path);
    const start_object_path = try common.allocTempFile(allocator, temp, "compiler_rt_multi3_canary", ".start.o");
    defer allocator.free(start_object_path);
    const executable_path = try common.allocTempFile(allocator, temp, "compiler_rt_multi3_canary", ".exe");
    defer allocator.free(executable_path);
    const target_arg = try std.fmt.allocPrint(allocator, "--target={s}", .{zllvmTarget(target)});
    defer allocator.free(target_arg);

    const object_argv = [_][]const u8{
        zllvm_exe,
        "--emit=obj",
        target_arg,
        "--input-limit=1048576",
        "src/codegen/x86_64/generic_cfg/testdata/compiler_rt_multi3.ll",
    };
    const object_result = try common.runCaptureEnv(allocator, io, &object_argv, "z_llvm focused compiler_rt __multi3 canary object", env_map);
    defer common.freeRunResult(allocator, object_result);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = object_path, .data = object_result.stdout });

    const assembly_argv = [_][]const u8{
        zllvm_exe,
        "--emit=asm",
        target_arg,
        "--input-limit=1048576",
        "src/codegen/x86_64/generic_cfg/testdata/compiler_rt_multi3.ll",
    };
    const assembly_result = try common.runCaptureEnv(allocator, io, &assembly_argv, "z_llvm focused compiler_rt __multi3 canary assembly", env_map);
    defer common.freeRunResult(allocator, assembly_result);
    try requireSha256(io, "__multi3 canonical machine instruction stream", assembly_result.stdout, multi3_instruction_stream_sha256);

    const dump_arg = try std.fmt.allocPrint(allocator, "--dump-section=.text={s}", .{text_path});
    defer allocator.free(dump_arg);
    const dump_argv = [_][]const u8{ "llvm-objcopy-22", dump_arg, object_path };
    const dump_result = try common.runCapture(allocator, io, &dump_argv, "compiler_rt __multi3 symbol-byte extraction");
    defer common.freeRunResult(allocator, dump_result);
    const symbol_bytes = try std.Io.Dir.cwd().readFileAlloc(io, text_path, allocator, .limited(1024 * 1024));
    defer allocator.free(symbol_bytes);
    if (symbol_bytes.len != 536) {
        try common.validationError(io, "compiler_rt __multi3 symbol size changed: expected 536, got {}\n", .{symbol_bytes.len});
    }
    try requireSha256(io, "__multi3 exact symbol bytes", symbol_bytes, multi3_symbol_bytes_sha256);

    const nm_argv = [_][]const u8{ "llvm-nm-22", "-S", "--defined-only", object_path };
    const nm_result = try common.runCapture(allocator, io, &nm_argv, "compiler_rt __multi3 symbol inspection");
    defer common.freeRunResult(allocator, nm_result);
    if (!std.mem.eql(u8, std.mem.trim(u8, nm_result.stdout, " \r\n"), "0000000000000000 0000000000000218 T __multi3")) {
        try common.validationError(io, "compiler_rt __multi3 canary object has unexpected defined symbols: {s}\n", .{nm_result.stdout});
    }

    const start_emit_arg = try std.fmt.allocPrint(allocator, "-femit-bin={s}", .{start_object_path});
    defer allocator.free(start_emit_arg);
    const start_argv = [_][]const u8{
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
        "test/zig/integrated/compiler_rt_multi3_canary_start.zig",
        start_emit_arg,
    };
    const start_result = try common.runCapture(allocator, io, &start_argv, "pinned Zig compiler_rt __multi3 canary start object");
    defer common.freeRunResult(allocator, start_result);

    const executable_emit_arg = try std.fmt.allocPrint(allocator, "-femit-bin={s}", .{executable_path});
    defer allocator.free(executable_emit_arg);
    const link_argv = [_][]const u8{
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
        "ReleaseFast",
        "-target",
        target,
        start_object_path,
        object_path,
        executable_emit_arg,
    };
    const link_result = try common.runCapture(allocator, io, &link_argv, "pinned Zig compiler_rt __multi3 canary link");
    defer common.freeRunResult(allocator, link_result);

    const canary_case: Case = .{
        .id = "compiler_rt_multi3_focused_canary",
        .mode = "ReleaseFast",
        .source = "test/zig/integrated/compiler_rt_multi3_canary_start.zig",
        .expected_stdout = "",
        .expected_exit = 0,
        .proof = .compiler_rt_i128_arithmetic,
    };
    try runExecutable(allocator, io, executable_path, canary_case);
}

fn requireSha256(io: std.Io, label: []const u8, contents: []const u8, expected: []const u8) !void {
    var digest: [std.crypto.hash.sha2.Sha256.digest_length]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(contents, &digest, .{});
    const actual = std.fmt.bytesToHex(digest, .lower);
    if (!std.mem.eql(u8, &actual, expected)) {
        try common.validationError(io, "{s} sha256 changed: expected {s}, got {s}\n", .{ label, expected, &actual });
    }
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
