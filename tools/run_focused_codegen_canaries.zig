const std = @import("std");
const common = @import("tool_common.zig");

const multi3_instruction_stream_sha256 = "8f962b4bda72349aac1464efd86f13daf18ae3595171d7f32548feb46ee82e61";
const multi3_symbol_bytes_sha256 = "f1c97aee4bb07d1ef27ebd12ec2236a2a390faaa95514436dfb282af5e2149ec";
const fma_instruction_stream_sha256 = "cc791b46ef93f564040e5245874216a7aa267df7319e84135862177f4eff776a";
const fma_symbol_bytes_sha256 = "3571863e4438990f77b5a159b95a85de16dea0d50db7a935406b54b09bee9abb";
const fma_ldexp_symbol_bytes_sha256 = "d8653232177f52c3636bdfb9746b44bd16259a762e82ac0cec43d9e4798c1689";
const fma_add_and_denorm_symbol_bytes_sha256 = "639a29b4ba8eae68fc0b87e7a9be45541616146c5ee14b651129b2eaf427054c";

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

    try runMulti3Canary(allocator, io, temp, zllvm_exe, zig_emitter, target, &env_map);
    try runFmaCanary(allocator, io, temp, zllvm_exe, zig_emitter, target, &env_map);

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    try stdout_writer.interface.print("ok focused-codegen-canary name=__multi3 object=ok stream=ok symbol=ok execution_cases=6\n", .{});
    try stdout_writer.interface.print("ok focused-codegen-canary name=fma object=ok stream=ok symbol=ok helpers=ok execution_cases=29 host_libc_substitution=absent\n", .{});
    try stdout_writer.interface.print("summary focused-codegen-canaries target={s} canaries=2 execution_cases=35 local_fail=0\n", .{target});
    try stdout_writer.interface.flush();
}

fn runMulti3Canary(
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

    try buildSourceObject(allocator, io, zig_emitter, target, "test/zig/integrated/compiler_rt_multi3_canary_start.zig", start_object_path, "__multi3 canary start");
    try linkExecutable(allocator, io, zig_emitter, target, executable_path, &.{ start_object_path, object_path }, "__multi3 canary");
    try requireSuccessfulExecutable(allocator, io, executable_path, "__multi3 canary");
}

fn runFmaCanary(
    allocator: std.mem.Allocator,
    io: std.Io,
    temp: common.TempDir,
    zllvm_exe: []const u8,
    zig_emitter: []const u8,
    target: []const u8,
    env_map: *const std.process.Environ.Map,
) !void {
    const fma_object_path = try common.allocTempFile(allocator, temp, "compiler_rt_fma_canary", ".o");
    defer allocator.free(fma_object_path);
    const helper_object_path = try common.allocTempFile(allocator, temp, "compiler_rt_fma_canary", ".helpers.o");
    defer allocator.free(helper_object_path);
    const start_object_path = try common.allocTempFile(allocator, temp, "compiler_rt_fma_canary", ".start.o");
    defer allocator.free(start_object_path);
    const executable_path = try common.allocTempFile(allocator, temp, "compiler_rt_fma_canary", ".exe");
    defer allocator.free(executable_path);

    try emitFmaObject(allocator, io, zllvm_exe, target, fma_object_path, env_map);
    try buildSourceObject(allocator, io, zig_emitter, target, "test/zig/integrated/compiler_rt_fma_helpers.ll", helper_object_path, "fma frozen helpers");
    try inspectFmaObjects(allocator, io, fma_object_path, helper_object_path);
    try buildSourceObject(allocator, io, zig_emitter, target, "test/zig/integrated/compiler_rt_fma_start.zig", start_object_path, "fma canary start");
    try linkExecutable(allocator, io, zig_emitter, target, executable_path, &.{ start_object_path, fma_object_path, helper_object_path }, "fma canary");
    try requireSuccessfulExecutable(allocator, io, executable_path, "fma canary");
}

fn emitFmaObject(
    allocator: std.mem.Allocator,
    io: std.Io,
    zllvm_exe: []const u8,
    target: []const u8,
    object_path: []const u8,
    env_map: *const std.process.Environ.Map,
) !void {
    const target_arg = try std.fmt.allocPrint(allocator, "--target={s}", .{zllvmTarget(target)});
    defer allocator.free(target_arg);
    const object_argv = [_][]const u8{
        zllvm_exe,
        "--emit=obj",
        target_arg,
        "--input-limit=1048576",
        "test/zig/integrated/compiler_rt_fma.ll",
    };
    const object_result = try common.runCaptureEnv(allocator, io, &object_argv, "z_llvm focused compiler_rt fma object", env_map);
    defer common.freeRunResult(allocator, object_result);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = object_path, .data = object_result.stdout });

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

fn inspectFmaObjects(
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
            try common.validationError(io, "compiler_rt fma helper object is missing required definition {s}\n", .{symbol});
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

    const helper_undefined_argv = [_][]const u8{ "llvm-nm-22", "--undefined-only", helper_object_path };
    const helper_undefined = try common.runCapture(allocator, io, &helper_undefined_argv, "compiler_rt fma helper undefined-symbol inspection");
    defer common.freeRunResult(allocator, helper_undefined);
    if (std.mem.trim(u8, helper_undefined.stdout, " \t\r\n").len != 0) {
        try common.validationError(io, "compiler_rt fma helper object has external dependencies (host fallback forbidden):\n{s}\n", .{helper_undefined.stdout});
    }

    try extractAndCheckText(allocator, io, fma_object_path, fma_text_path, 4114, "fma exact symbol bytes", fma_symbol_bytes_sha256);

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

fn extractAndCheckText(
    allocator: std.mem.Allocator,
    io: std.Io,
    object_path: []const u8,
    text_path: []const u8,
    expected_len: usize,
    label: []const u8,
    expected_sha256: []const u8,
) !void {
    const dump_arg = try std.fmt.allocPrint(allocator, "--dump-section=.text={s}", .{text_path});
    defer allocator.free(dump_arg);
    const dump_argv = [_][]const u8{ "llvm-objcopy-22", dump_arg, object_path };
    const dump_result = try common.runCapture(allocator, io, &dump_argv, label);
    defer common.freeRunResult(allocator, dump_result);
    const symbol_bytes = try std.Io.Dir.cwd().readFileAlloc(io, text_path, allocator, .limited(1024 * 1024));
    defer allocator.free(symbol_bytes);
    if (symbol_bytes.len != expected_len) {
        try common.validationError(io, "{s} size changed: expected {}, got {}\n", .{ label, expected_len, symbol_bytes.len });
    }
    try requireSha256(io, label, symbol_bytes, expected_sha256);
}

fn buildSourceObject(
    allocator: std.mem.Allocator,
    io: std.Io,
    zig_emitter: []const u8,
    target: []const u8,
    source: []const u8,
    object_path: []const u8,
    label: []const u8,
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
        source,
        emit_arg,
    };
    const result = try common.runCapture(allocator, io, &argv, label);
    common.freeRunResult(allocator, result);
}

fn linkExecutable(
    allocator: std.mem.Allocator,
    io: std.Io,
    zig_emitter: []const u8,
    target: []const u8,
    executable_path: []const u8,
    objects: []const []const u8,
    label: []const u8,
) !void {
    const emit_arg = try std.fmt.allocPrint(allocator, "-femit-bin={s}", .{executable_path});
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
        "ReleaseFast",
        "-target",
        target,
    });
    try argv.appendSlice(allocator, objects);
    try argv.append(allocator, emit_arg);
    const result = try common.runCapture(allocator, io, argv.items, label);
    common.freeRunResult(allocator, result);
}

fn requireSuccessfulExecutable(
    allocator: std.mem.Allocator,
    io: std.Io,
    executable_path: []const u8,
    label: []const u8,
) !void {
    const argv = [_][]const u8{executable_path};
    const result = try std.process.run(allocator, io, .{
        .argv = &argv,
        .stdout_limit = .limited(1024 * 1024),
        .stderr_limit = .limited(1024 * 1024),
    });
    defer common.freeRunResult(allocator, result);
    switch (result.term) {
        .exited => |code| if (code != 0) {
            try common.validationError(io, "{s} exited with code {}, expected 0\n", .{ label, code });
        },
        else => try common.validationError(io, "{s} exited with {any}, expected exit code 0\n", .{ label, result.term }),
    }
    if (result.stdout.len != 0 or result.stderr.len != 0) {
        try common.validationError(io, "{s} produced unexpected output: stdout={s} stderr={s}\n", .{ label, result.stdout, result.stderr });
    }
}

fn requireSha256(io: std.Io, label: []const u8, contents: []const u8, expected: []const u8) !void {
    var digest: [std.crypto.hash.sha2.Sha256.digest_length]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(contents, &digest, .{});
    const actual = std.fmt.bytesToHex(digest, .lower);
    if (!std.mem.eql(u8, &actual, expected)) {
        try common.validationError(io, "{s} sha256 changed: expected {s}, got {s}\n", .{ label, expected, &actual });
    }
}

fn normalizeTargetQuery(target: []const u8) []const u8 {
    if (std.mem.eql(u8, target, "x86_64-unknown-linux-gnu")) return "x86_64-linux-gnu";
    return target;
}

fn zllvmTarget(target: []const u8) []const u8 {
    if (std.mem.eql(u8, target, "x86_64-linux-gnu")) return "x86_64-unknown-linux-gnu";
    return target;
}

fn copyEnvironment(env_map: *std.process.Environ.Map, source: *const std.process.Environ.Map) !void {
    const keys = source.keys();
    const values = source.values();
    for (keys, values) |key, value| try env_map.put(key, value);
}
