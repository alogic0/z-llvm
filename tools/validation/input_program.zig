//! Unchanged upstream program, compiled once per mode and driven by a frozen
//! corpus. Expected observations are independent of both compiler routes.
const std = @import("std");
const u = @import("common.zig");
const Runner = @import("runner.zig").Runner;
const program = @import("program.zig");
const canaries = @import("native_canaries.zig");
const provenance = @import("provenance.zig");
const elf = @import("object_contract.zig");

pub fn matches(completed: bool, code: i64, stdout: []const u8, stderr: []const u8, expected_code: i64, expected_stdout: []const u8, expected_stderr: []const u8) bool {
    return completed and code == expected_code and std.mem.eql(u8, stdout, expected_stdout) and std.mem.eql(u8, stderr, expected_stderr);
}

pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    u.installSignals();
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "zllvm", "zig-emitter", "mode" }, &.{});
    const output = try c.newOutput(try args.require("output-root"));
    var runner = Runner.init(&c, output);
    var report = u.object(c.a);
    try u.put(c.a, &report, "schema", u.s("input-program-v1"));
    try u.put(c.a, &report, "program", u.s("jsmn-jsondump"));
    try u.put(c.a, &report, "status", u.s("failed"));
    try u.put(c.a, &report, "rows", u.array(c.a));
    for ([_][]const u8{ "matched_program_modes", "matched_inputs", "reference_executions", "local_executions", "negative_controls" }) |key| try u.put(c.a, &report, key, u.n(0));
    execute(&c, args, output, &runner, &report) catch |err| {
        try u.put(c.a, &report, "error", u.s(c.diagnostic orelse @errorName(err)));
        try std.Io.File.stderr().writeStreamingAll(c.io, try c.fmt("input-program: {s}\n", .{c.diagnostic orelse @errorName(err)}));
    };
    try c.writeJson(try c.join(&.{ output, "report.json" }), report);
    const passed = u.json.is(try u.get(report, "status"), "passed");
    try c.print("summary input-program schema=input-program-v1 program=jsmn-jsondump program_modes={d} matched_inputs={d} reference_executions={d} local_executions={d} negative_controls={d} local_fail={d}\n", .{
        (try u.get(report, "matched_program_modes")).integer, (try u.get(report, "matched_inputs")).integer,
        (try u.get(report, "reference_executions")).integer,  (try u.get(report, "local_executions")).integer,
        (try u.get(report, "negative_controls")).integer,     @intFromBool(!passed),
    });
    try c.print("evidence: {s}/report.json\n", .{output});
    if (!passed) std.process.exit(1);
}

fn authenticate(c: *u.Context, manifest: u.Value) !void {
    for ((try u.get(manifest, "source_files")).array.items) |file| {
        const path = try c.join(&.{try u.str(file, "path")});
        if (!std.mem.eql(u8, try c.digest(path), try u.str(file, "sha256"))) return error.UpstreamSourceChanged;
    }
}

fn execute(c: *u.Context, args: u.Args, output: []const u8, r: *Runner, report: *u.Value) !void {
    if (@import("builtin").os.tag != .linux or @import("builtin").cpu.arch != .x86_64) return error.RequiresX8664Linux;
    const manifest_path = try c.join(&.{"test/real_programs/jsmn_jsondump.json"});
    const manifest_hash = try c.digest(manifest_path);
    const manifest = try c.load(manifest_path);
    if (!u.json.is(try u.get(manifest, "schema"), "input-program-v1")) return error.InvalidInputProgramSchema;
    try authenticate(c, manifest);
    const tools = try provenance.tools(c);
    const compiler = try c.join(&.{args.get("zllvm") orelse "zig-out/bin/z_llvm"});
    const zig = try c.join(&.{args.get("zig-emitter") orelse "../ziglang/build/stage4/bin/zig"});
    const identity = try program.identity(c);
    if (!std.mem.eql(u8, u.trim(try c.capture(&.{ zig, "version" })), identity.get("ABI_DIFF_REFERENCE_VERSION") orelse "")) return error.WrongFrontendVersion;
    // Match the audited C frontend used by the existing C population.
    const c_manifest = try c.load(try c.join(&.{"test/real_programs/c_compiler.json"}));
    if (!std.mem.eql(u8, try c.digest(zig), try u.str(c_manifest, "zig_emitter_sha256"))) return error.WrongFrontendBinary;
    for ([_][]const u8{ "upstream", "source_files", "mode_scope", "remaining_dependencies", "oracle" }) |key| try u.put(c.a, report, key, try u.get(manifest, key));
    try u.put(c.a, report, "manifest_sha256", u.s(manifest_hash));
    try u.put(c.a, report, "tool_provenance", tools);
    try u.put(c.a, report, "compiler_sha256", u.s(try c.digest(compiler)));
    try u.put(c.a, report, "compiler", u.s(compiler));
    try u.put(c.a, report, "compiler_build", try @import("toolchain.zig").compilerBuild(c, compiler));
    try u.put(c.a, report, "frontend_sha256", u.s(try c.digest(zig)));
    try u.put(c.a, report, "frontend", u.s(zig));
    try u.put(c.a, report, "source_head", u.s(u.trim(try c.capture(&.{ "git", "rev-parse", "HEAD" }))));
    var env = try c.cleanEnvironment();
    try env.put("ZIG_LOCAL_CACHE_DIR", try c.join(&.{ output, "frontend-cache" }));
    try env.put("ZIG_GLOBAL_CACHE_DIR", try c.join(&.{ output, "global-cache" }));
    try r.require(&.{ "clang-22", "--version" }, try c.join(&.{ output, "reference-version" }), &env);
    if (std.mem.indexOf(u8, try c.read(try c.join(&.{ output, "reference-version.stdout" })), "clang version 22.") == null) return error.WrongReferenceVersion;
    const source = try c.join(&.{try u.str(manifest, "source")});
    const raw = try c.join(&.{ output, "preopt.ll" });
    try r.require(&.{ zig, "cc", "-target", try u.str(manifest, "target"), "-O0", "-Xclang", "-disable-O0-optnone", "-S", "-emit-llvm", "-g0", "-fno-sanitize=all", "-fno-stack-protector", "-fno-asynchronous-unwind-tables", "-fno-builtin", source, "-o", raw }, try c.join(&.{ output, "frontend" }), &env);
    try u.put(c.a, report, "preopt_sha256", u.s(try c.digest(raw)));
    const cases = (try u.get(manifest, "cases")).array.items;
    var names = std.StringHashMap(void).init(c.a);
    for (cases) |case| {
        const name = try u.str(case, "id");
        if (name.len == 0 or (try names.getOrPut(name)).found_existing) return error.InvalidInputName;
        for (name) |ch| if (!std.ascii.isAlphanumeric(ch) and ch != '-') return error.InvalidInputName;
        try c.write(try c.join(&.{ output, try c.fmt("{s}.stdin", .{name}) }), try u.str(case, "stdin"));
    }
    try u.put(c.a, report, "inputs", u.n(cases.len));
    for (try program.selectedModes(c, args, manifest)) |mode| {
        const directory = try c.join(&.{ output, mode });
        try c.mkdir(directory);
        var row = u.object(c.a);
        try u.put(c.a, &row, "mode", u.s(mode));
        try u.put(c.a, &row, "status", u.s("failed"));
        try u.put(c.a, &row, "cases", u.array(c.a));
        const rows = report.object.getPtr("rows").?;
        try u.add(rows, row);
        try modeRun(c, r, report, &rows.array.items[rows.array.items.len - 1], manifest, output, directory, mode, raw, compiler, &env);
        try u.increment(c.a, report, "matched_program_modes", 1);
    }
    try authenticate(c, manifest);
    if (!std.mem.eql(u8, manifest_hash, try c.digest(manifest_path))) return error.InputCorpusChanged;
    try provenance.verifyTools(c, tools);
    if (!std.mem.eql(u8, try c.digest(compiler), try u.str(report.*, "compiler_sha256")) or
        !std.mem.eql(u8, try c.digest(zig), try u.str(report.*, "frontend_sha256")) or
        !u.json.eql(try u.get(report.*, "compiler_build"), try @import("toolchain.zig").compilerBuild(c, compiler))) return error.SelectedToolchainChanged;
    try u.put(c.a, report, "status", u.s("passed"));
}

fn modeRun(c: *u.Context, r: *Runner, report: *u.Value, row: *u.Value, manifest: u.Value, output: []const u8, directory: []const u8, mode: []const u8, raw: []const u8, compiler: []const u8, env: *const std.process.Environ.Map) !void {
    const reference = try c.join(&.{ directory, "reference.o" });
    const reference_exe = try c.join(&.{ directory, "reference" });
    try r.require(&.{ "clang-22", "-x", "ir", try canaries.llvmOpt(mode), "-c", raw, "-o", reference }, try c.join(&.{ directory, "reference-compile" }), env);
    try r.require(&.{ "cc", "-no-pie", reference, "-o", reference_exe }, try c.join(&.{ directory, "reference-link" }), env);
    const profile = try c.join(&.{ directory, "profile.json" });
    const owners = try c.join(&.{ directory, "owners.tsv" });
    const local_object = try c.join(&.{ directory, "local-object.stdout" });
    const passes = try c.fmt("--passes=memory-foundation,{s}", .{try u.pipeline(mode)});
    try r.require(&.{ compiler, "--emit=obj", "--generic-cfg-selector", "--report-all-codegen-failures", "--target=x86_64-unknown-linux-gnu", "--input-limit=67108864", passes, try c.fmt("--profile={s}", .{profile}), try c.fmt("--selection-owner-output={s}", .{owners}), raw }, try c.join(&.{ directory, "local-object" }), env);
    try c.writeJson(try c.join(&.{ directory, "object-contract.json" }), try elf.parse(c.a, try c.read(local_object)));
    try canaries.owners(c, try c.read(owners), try u.stringSlice(c.a, try u.get(manifest, "expected_functions")));
    try u.put(c.a, row, "compilation_profile", try c.load(profile));
    try u.put(c.a, row, "object_sha256", u.s(try c.digest(local_object)));
    try u.put(c.a, row, "owners_sha256", u.s(try c.digest(owners)));
    // An independent selection replay remains a permanent regression check.
    try r.require(&.{ compiler, "--emit=selection-owner-manifest", "--generic-cfg-selector", "--target=x86_64-unknown-linux-gnu", passes, raw }, try c.join(&.{ directory, "owners-replay" }), env);
    if (!std.mem.eql(u8, try c.read(owners), try c.read(try c.join(&.{ directory, "owners-replay.stdout" })))) return error.OwnershipReplayMismatch;
    const executable = try c.join(&.{ directory, "local" });
    try r.require(&.{ "cc", "-no-pie", "-x", "none", local_object, "-o", executable }, try c.join(&.{ directory, "local-link" }), env);
    for ((try u.get(manifest, "cases")).array.items) |case| {
        const name = try u.str(case, "id");
        const input = try c.join(&.{ output, try c.fmt("{s}.stdin", .{name}) });
        var observation = u.object(c.a);
        try u.put(c.a, &observation, "id", u.s(name));
        try u.put(c.a, &observation, "input_sha256", u.s(try c.digest(input)));
        try u.put(c.a, &observation, "status", u.s("failed"));
        const observations = row.object.getPtr("cases").?;
        try u.add(observations, observation);
        const observed = &observations.array.items[observations.array.items.len - 1];
        for ([_][]const u8{ "reference", "local" }, [_][]const u8{ reference_exe, executable }) |route, exe| {
            const stem = try c.join(&.{ directory, try c.fmt("{s}-{s}", .{ route, name }) });
            const result = try r.run(&.{exe}, stem, env, .{ .stdin_file = input, .timeout_ms = 5000 });
            try u.increment(c.a, report, try c.fmt("{s}_executions", .{route}), 1);
            const stdout = try c.read(try c.fmt("{s}.stdout", .{stem}));
            const stderr = try c.read(try c.fmt("{s}.stderr", .{stem}));
            try u.put(c.a, observed, route, try u.toValue(c.a, .{ .completed = result.completed, .exit_status = result.code, .stdout_sha256 = try c.digest(try c.fmt("{s}.stdout", .{stem})), .stderr_sha256 = try c.digest(try c.fmt("{s}.stderr", .{stem})) }));
            if (!matches(result.completed, result.code, stdout, stderr, (try u.get(case, "exit_status")).integer, try u.str(case, "stdout"), try u.str(case, "stderr"))) return c.fail("{s}/{s}/{s}: observation differs from frozen oracle", .{ mode, route, name });
            if (std.mem.eql(u8, route, "local")) {
                // Reject mutated observations and abnormal termination even when
                // the encoded return code matches the oracle's ordinary exit.
                const bad = [_]bool{
                    matches(false, result.code, stdout, stderr, result.code, stdout, stderr),
                    matches(true, result.code + 1, stdout, stderr, result.code, stdout, stderr),
                    matches(true, result.code, "wrong stdout", stderr, result.code, stdout, stderr),
                    matches(true, result.code, stdout, "wrong stderr", result.code, stdout, stderr),
                };
                for (bad) |accepted| if (accepted) return error.OracleAcceptedMutation;
                try u.increment(c.a, report, "negative_controls", bad.len);
            }
        }
        try u.put(c.a, observed, "status", u.s("matched"));
        try u.increment(c.a, report, "matched_inputs", 1);
    }
    try u.put(c.a, row, "status", u.s("matched"));
}
