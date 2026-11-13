const std = @import("std");
const u = @import("common.zig");
const p = @import("program.zig");
const canaries = @import("native_canaries.zig");
const Runner = @import("runner.zig").Runner;
const elf = @import("object_contract.zig");
const provenance = @import("provenance.zig");
const toolchain = @import("toolchain.zig");

pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    u.installSignals();
    const args = try init.minimal.args.toSlice(c.a);
    if (args.len == 2 and std.mem.eql(u8, args[1], "--help")) {
        try c.print("usage: run_upstream_c_program --output-root DIR [--zig-source DIR] [--zig-emitter EXE] [--zllvm EXE] [--mode ReleaseFast|ReleaseSafe|ReleaseSmall] [--retain-products]\n", .{});
        return;
    }
    const code = run(&c, args[1..]) catch |err| {
        try std.Io.File.stderr().writeStreamingAll(c.io, try c.fmt("upstream-c-program: {s}\n", .{c.diagnostic orelse @errorName(err)}));
        std.process.exit(2);
    };
    std.process.exit(code);
}
fn run(c: *u.Context, arguments: []const []const u8) !u8 {
    const args = try u.Args.parse(c.a, arguments, &.{ "output-root", "zig-source", "zig-emitter", "zllvm", "mode" }, &.{"retain-products"});
    const output = try c.newOutput(try args.require("output-root"));
    const storage = @import("storage_workspace.zig");
    const workspace = if (args.flag("retain-products")) try storage.startPipeline(c, output, "validation") else try storage.start(c, output, "validation");
    defer if (workspace) |w| w.close(c);
    const registry = try canaries.load(c);
    var runner = Runner.init(c, output);
    var report = u.object(c.a);
    try u.put(c.a, &report, "schema", u.s("upstream-c-program-v1"));
    try u.put(c.a, &report, "program", u.s("zig-c-compiler-fixture"));
    try u.put(c.a, &report, "language", u.s("C"));
    try u.put(c.a, &report, "status", u.s("failed"));
    try u.put(c.a, &report, "programs", u.n(1));
    for ([_][]const u8{ "matched_program_modes", "reference_case_executions", "local_case_executions", "integer_variadic_observations", "heap_call_observations", "native_call_observations", "bounded_storage_guard_checks" }) |key| try u.put(c.a, &report, key, u.n(0));
    try u.put(c.a, &report, "rows", u.array(c.a));
    for (registry) |canary| for ([_][]const u8{ "local", "reference" }) |route| try u.put(c.a, &report, try c.fmt("{s}_{s}_observations", .{ try u.str(canary, "population"), route }), u.n(0));
    execute(c, args, output, &runner, &report, registry) catch |err| {
        try u.put(c.a, &report, "error", u.s(c.diagnostic orelse @errorName(err)));
    };
    try c.writeJson(try c.join(&.{ output, "report.json" }), report);
    if (workspace) |w| try w.finishReport(c);
    try summary(c, report, registry);
    try c.print("evidence: {s}/report.json\n", .{output});
    if (report.object.get("error")) |err| try std.Io.File.stderr().writeStreamingAll(c.io, try c.fmt("{s}\n", .{err.string}));
    return if (u.json.is(try u.get(report, "status"), "passed")) 0 else 1;
}

fn execute(c: *u.Context, args: u.Args, output: []const u8, runner: *Runner, report: *u.Value, registry: []u.Value) !void {
    if (@import("builtin").os.tag != .linux or @import("builtin").cpu.arch != .x86_64) return error.RequiresX8664Linux;
    const procedure = try provenance.tools(c);
    try u.put(c.a, report, "tool_provenance", procedure);
    const manifest = try c.load(try c.join(&.{"test/real_programs/c_compiler.json"}));
    const modes = try p.selectedModes(c, args, manifest);
    try u.put(c.a, report, "program_modes", u.n(modes.len));
    const source_root = try c.join(&.{args.get("zig-source") orelse "../ziglang"});
    const zig = try c.join(&.{args.get("zig-emitter") orelse try c.join(&.{ source_root, "build/stage4/bin/zig" })});
    const zllvm = try c.join(&.{args.get("zllvm") orelse "zig-out/bin/z_llvm"});
    const selected_toolchain = try toolchain.record(c, zllvm, zig, source_root);
    try u.put(c.a, report, "toolchain", selected_toolchain);
    const pin = u.trim(try c.read(try c.join(&.{"docs/evidence/ziglang_pin.txt"})));
    const source = try c.join(&.{ source_root, try u.str(manifest, "source") });
    if (!std.mem.eql(u8, u.trim(try c.capture(&.{ "git", "-C", source_root, "rev-parse", "HEAD" })), pin)) return c.fail("upstream revision differs from the tracked pin", .{});
    if (!std.mem.eql(u8, try c.digest(source), try u.str(manifest, "source_sha256")) or !std.mem.eql(u8, try c.read(source), try c.capture(&.{ "git", "-C", source_root, "show", try c.fmt("{s}:{s}", .{ pin, try u.str(manifest, "source") }) }))) return c.fail("upstream C source differs from the unchanged pinned fixture", .{});
    const identity = try p.identity(c);
    if (!std.mem.eql(u8, pin, identity.get("ABI_DIFF_SOURCE_REVISION") orelse "") or !std.mem.eql(u8, u.trim(try c.capture(&.{ zig, "version" })), identity.get("ABI_DIFF_REFERENCE_VERSION") orelse "")) return c.fail("pinned Zig frontend identity differs", .{});
    if (!std.mem.eql(u8, try c.digest(zig), try u.str(manifest, "zig_emitter_sha256"))) return c.fail("pinned Zig frontend binary hash differs", .{});
    if ((try c.capture(&.{ "git", "-C", source_root, "status", "--porcelain", "--untracked-files=no" })).len != 0) return c.fail("upstream checkout has tracked modifications", .{});
    try u.put(c.a, report, "source", u.s(source));
    try u.put(c.a, report, "source_sha256", u.s(try c.digest(source)));
    try u.put(c.a, report, "source_pin", u.s(pin));
    try u.put(c.a, report, "zig_sha256", u.s(try c.digest(zig)));
    try u.put(c.a, report, "zllvm_sha256", u.s(try c.digest(zllvm)));
    for ([_][]const u8{ "target", "remaining_dependencies" }) |key| try u.put(c.a, report, key, try u.get(manifest, key));
    try u.put(c.a, report, "mode_scope", u.s("Local release pipelines; C assertions stay enabled, C sanitizers are disabled."));
    try u.put(c.a, report, "source_head", u.s(u.trim(try c.capture(&.{ "git", "rev-parse", "HEAD" }))));
    try u.put(c.a, report, "runner_sha256", u.s(try c.digest(try c.join(&.{"tools/validation/upstream_c.zig"}))));
    try u.put(c.a, report, "native_canaries_sha256", u.s(try c.digest(try c.join(&.{"test/real_programs/native_canaries.json"}))));
    var fixtures = u.object(c.a);
    for ([_][]const u8{ "c_compiler.json", "variadic_integer.ll", "variadic_integer_driver.c", "variadic_integer_shim.S" }) |name| try u.put(c.a, &fixtures, name, u.s(try c.digest(try c.join(&.{ "test/real_programs", name }))));
    for (registry) |canary| for ([_][]const u8{ ".ll", "_driver.c" }) |suffix| {
        const name = try c.fmt("{s}{s}", .{ try u.str(canary, "fixture"), suffix });
        try u.put(c.a, &fixtures, name, u.s(try c.digest(try c.join(&.{ "test/real_programs", name }))));
    };
    for (registry) |canary| if (canary.object.get("reference_fixture")) |reference| {
        const name = try c.fmt("{s}.ll", .{try u.json.text(reference)});
        try u.put(c.a, &fixtures, name, u.s(try c.digest(try c.join(&.{ "test/real_programs", name }))));
        if (canary.object.get("reference_source")) |source_value| {
            const name_source = try u.json.text(source_value);
            try u.put(c.a, &fixtures, name_source, u.s(try c.digest(try c.join(&.{ "test/real_programs", name_source }))));
        }
    };
    for (registry) |canary| if (canary.object.get("provider_fixture")) |provider| {
        const name = try c.fmt("{s}.ll", .{try u.json.text(provider)});
        try u.put(c.a, &fixtures, name, u.s(try c.digest(try c.join(&.{ "test/real_programs", name }))));
    };
    try u.put(c.a, report, "fixture_sha256", fixtures);
    var env = try c.cleanEnvironment();
    try env.put("ZIG_LOCAL_CACHE_DIR", try c.temporaryPath(&.{ output, "frontend-cache" }));
    try env.put("ZIG_GLOBAL_CACHE_DIR", try c.temporaryPath(&.{ output, "global-cache" }));
    try runner.require(&.{ "clang-22", "--version" }, try c.join(&.{ output, "reference-identity" }), &env);
    if (std.mem.indexOf(u8, try c.read(try c.join(&.{ output, "reference-identity.stdout" })), "clang version 22.") == null) return c.fail("LLVM reference must be Clang 22", .{});
    const raw = try c.join(&.{ output, "preopt.ll" });
    try runner.require(&.{ zig, "cc", "-target", try u.str(manifest, "target"), "-O0", "-Xclang", "-disable-O0-optnone", "-S", "-emit-llvm", "-g0", "-fno-sanitize=all", "-fno-stack-protector", "-fno-asynchronous-unwind-tables", "-fno-builtin", source, "-o", raw }, try c.join(&.{ output, "frontend" }), &env);
    try u.put(c.a, report, "preopt_sha256", u.s(try c.digest(raw)));
    for (modes) |mode| {
        const directory = try c.join(&.{ output, mode });
        try c.mkdir(directory);
        var row = u.object(c.a);
        try u.put(c.a, &row, "mode", u.s(mode));
        try u.put(c.a, &row, "status", u.s("failed"));
        try u.put(c.a, &row, "local_cases", u.n(0));
        try u.put(c.a, &row, "reference_cases", u.n(0));
        const rows = report.object.getPtr("rows").?;
        try u.add(rows, row);
        // A row's backing map can grow independently of the report's registry counters.
        const at = rows.array.items.len - 1;
        try runMode(c, directory, mode, raw, zllvm, manifest, &env, runner, report, registry, at);
        try u.increment(c.a, report, "matched_program_modes", 1);
    }
    if (!std.mem.eql(u8, try c.digest(source), try u.str(report.*, "source_sha256"))) return error.UpstreamSourceChangedDuringExecution;
    try provenance.verifyTools(c, procedure);
    try toolchain.verify(c, selected_toolchain);
    try u.put(c.a, report, "status", u.s("passed"));
}

fn runMode(c: *u.Context, directory: []const u8, mode: []const u8, raw: []const u8, zllvm: []const u8, manifest: u.Value, env: *const std.process.Environ.Map, runner: *Runner, report: *u.Value, registry: []u.Value, row_index: usize) !void {
    const row = &report.object.getPtr("rows").?.array.items[row_index];
    const reference = try c.temporaryPath(&.{ directory, "reference.o" });
    const reference_exe = try c.temporaryPath(&.{ directory, "reference" });
    try runner.require(&.{ "clang-22", "-x", "ir", try canaries.llvmOpt(mode), "-c", raw, "-o", reference }, try c.join(&.{ directory, "reference-compile" }), env);
    try runner.require(&.{ "cc", "-no-pie", reference, "-o", reference_exe }, try c.join(&.{ directory, "reference-link" }), env);
    for (try u.json.array(try u.get(manifest, "cases"))) |case| {
        try canaries.observation(runner, reference_exe, case, try c.join(&.{ directory, try c.fmt("reference-{s}", .{try u.str(case, "id")}) }), env);
        try u.increment(c.a, report, "reference_case_executions", 1);
        try u.increment(c.a, row, "reference_cases", 1);
    }
    const memory = try c.join(&.{ directory, "memory.ll" });
    try runner.require(&.{ zllvm, "--pipeline=memory-foundation", raw }, try c.join(&.{ directory, "memory-optimize" }), env);
    try c.copy(try c.join(&.{ directory, "memory-optimize.stdout" }), memory);
    const optimized = try c.join(&.{ directory, "optimized.ll" });
    try runner.require(&.{ zllvm, try c.fmt("--pipeline={s}", .{try u.pipeline(mode)}), memory }, try c.join(&.{ directory, "release-optimize" }), env);
    try c.copy(try c.join(&.{ directory, "release-optimize.stdout" }), optimized);
    const local = try c.temporaryPath(&.{ directory, "local.o" });
    try runner.requireOutput(&.{ zllvm, "--generic-cfg-selector", "--emit=obj", "--target=x86_64-unknown-linux-gnu", optimized }, try c.join(&.{ directory, "local-object" }), env, local);
    try c.writeJson(try c.join(&.{ directory, "object-contract.json" }), try elf.parse(c.a, try c.read(local)));
    try runner.require(&.{ zllvm, "--generic-cfg-selector", "--emit=selection-owner-manifest", "--target=x86_64-unknown-linux-gnu", optimized }, try c.join(&.{ directory, "owners" }), env);
    var owners = u.array(c.a);
    var lines = std.mem.tokenizeScalar(u8, try c.read(try c.join(&.{ directory, "owners.stdout" })), '\n');
    _ = lines.next();
    while (lines.next()) |line| try u.add(&owners, u.s(line));
    try u.put(c.a, row, "owners", owners);
    const hash = try c.digest(local);
    try u.put(c.a, row, "local_object_sha256", u.s(hash));
    const exe = try c.temporaryPath(&.{ directory, "local" });
    try runner.require(&.{ "cc", "-no-pie", local, "-o", exe }, try c.join(&.{ directory, "local-link" }), env);
    for (try u.json.array(try u.get(manifest, "cases"))) |case| {
        try canaries.observation(runner, exe, case, try c.join(&.{ directory, try c.fmt("local-{s}", .{try u.str(case, "id")}) }), env);
        try u.increment(c.a, report, "local_case_executions", 1);
        try u.increment(c.a, row, "local_cases", 1);
    }
    if (!std.mem.eql(u8, hash, try c.digest(local))) return error.LocalObjectChangedDuringExecution;
    try canaries.variadic(runner, directory, zllvm, env);
    try u.increment(c.a, report, "native_call_observations", 22);
    try u.increment(c.a, report, "integer_variadic_observations", 16);
    try u.increment(c.a, report, "heap_call_observations", 6);
    for (registry) |canary| try canaries.run(runner, directory, zllvm, env, mode, report, canary);
    try u.put(c.a, row, "status", u.s("matched"));
}

fn count(report: u.Value, key: []const u8) i64 {
    return (report.object.get(key) orelse u.n(0)).integer;
}
fn summary(c: *u.Context, report: u.Value, registry: []u.Value) !void {
    const failed = @intFromBool(!u.json.is(try u.get(report, "status"), "passed"));
    const mode_count = count(report, "program_modes");
    try c.print("summary upstream-c-program schema=upstream-c-program-v1 programs=1 program_modes={d} matched_program_modes={d} reference_case_executions={d} local_case_executions={d} integer_variadic_observations={d} heap_call_observations={d} native_call_observations={d} local_fail={d}\n", .{
        mode_count, count(report, "matched_program_modes"), count(report, "reference_case_executions"), count(report, "local_case_executions"), count(report, "integer_variadic_observations"), count(report, "heap_call_observations"), count(report, "native_call_observations"), failed,
    });
    const special = [_][3][]const u8{
        .{ "word_pair", "word-pair-memory", "standalone-two-word-stack-memory" },         .{ "pointer_stack", "pointer-stack-memory", "standalone-runtime-pointer-stack" },
        .{ "scalar_stack", "scalar-stack-memory", "standalone-scalar-stack" },            .{ "integer_pointer", "integer-pointer-casts", "standalone-integer-pointer-casts" },
        .{ "signed_nonnegative", "signed-nonnegative", "standalone-signed-nonnegative" }, .{ "type_layout_padding", "type-layout-padding", "standalone-type-allocation-padding" },
    };
    // Keep legacy summary ordering as well as names for whole-log comparison.
    var ordered: std.ArrayList(u.Value) = .empty;
    for (special) |item| for (registry) |canary| {
        if (u.json.is(try u.get(canary, "population"), item[0])) try ordered.append(c.a, canary);
    };
    for (registry) |canary| {
        var is_special = false;
        for (special) |item| if (u.json.is(try u.get(canary, "population"), item[0])) {
            is_special = true;
            break;
        };
        if (!is_special) try ordered.append(c.a, canary);
    }
    for (ordered.items) |canary| {
        const population = try u.str(canary, "population");
        var selected: ?[3][]const u8 = null;
        for (special) |item| if (std.mem.eql(u8, population, item[0])) {
            selected = item;
            break;
        };
        const name = if (selected) |item| item[1] else try std.mem.replaceOwned(u8, c.a, population, "_", "-");
        const scope = if (selected) |item| item[2] else try c.fmt("standalone-{s}", .{name});
        const extra = if (std.mem.eql(u8, population, "module_dependencies")) try c.fmt(" negative_controls={d} environment_checks={d}", .{ count(report, "module_dependencies_negative_controls"), count(report, "module_dependencies_environment_checks") }) else if (std.mem.eql(u8, population, "bounded_storage")) try c.fmt(" guard_checks={d}", .{count(report, "bounded_storage_guard_checks")}) else "";
        try c.print("summary {s} population={s} routes=direct,release modes={d} local_observations={d} reference_observations={d} reference_reused_per_route=true local_fail={d}{s}\n", .{
            name, scope, mode_count, count(report, try c.fmt("{s}_local_observations", .{population})), count(report, try c.fmt("{s}_reference_observations", .{population})), failed, extra,
        });
    }
}
