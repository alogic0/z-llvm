const std = @import("std");
const u = @import("common.zig");
const Runner = @import("runner.zig").Runner;
const elf = @import("object_contract.zig");
const provenance = @import("provenance.zig");

pub fn identity(c: *u.Context) !std.StringHashMap([]const u8) {
    var fields = std.StringHashMap([]const u8).init(c.a);
    var lines = std.mem.splitScalar(u8, try c.read(try c.join(&.{"test/abi_diff/reference_identity.env"})), '\n');
    while (lines.next()) |line| {
        const eq = std.mem.indexOfScalar(u8, line, '=') orelse continue;
        const value = line[eq + 1 ..];
        if (std.mem.startsWith(u8, line, "ABI_DIFF_") and value.len >= 2 and value[0] == '\'' and value[value.len - 1] == '\'')
            try fields.put(line[0..eq], value[1 .. value.len - 1]);
    }
    return fields;
}
pub fn markerFields(c: *u.Context, bytes: []const u8) !std.StringHashMap([]const u8) {
    var fields = std.StringHashMap([]const u8).init(c.a);
    var tokens = std.mem.tokenizeAny(u8, bytes, " \t\r\n");
    while (tokens.next()) |token| {
        const eq = std.mem.indexOfScalar(u8, token, '=') orelse continue;
        if (eq == 0 or eq + 1 == token.len) continue;
        try fields.put(token[0..eq], token[eq + 1 ..]);
    }
    return fields;
}
pub fn selectedModes(c: *u.Context, args: u.Args, manifest: u.Value) ![]const []const u8 {
    const available = try u.stringSlice(c.a, try u.get(manifest, "modes"));
    for (available) |mode| _ = try u.pipeline(mode);
    if (args.get("mode")) |mode| {
        if (!u.contains(available, mode)) return c.fail("mode is outside the program's frozen manifest", .{});
        const chosen = try c.a.alloc([]const u8, 1);
        chosen[0] = mode;
        return chosen;
    }
    return available;
}
pub fn linkDriver(args: u.Args, manifest: u.Value) !enum { system, zig_compiler_rt } {
    const driver = if (manifest.object.get("link_driver")) |value| try u.json.string(value) else "system";
    if (std.mem.eql(u8, driver, "system")) return .system;
    if (!std.mem.eql(u8, driver, "zig-compiler-rt")) return error.UnsupportedProgramLinkDriver;
    if (args.get("linker") != null) return error.ConflictingProgramLinker;
    return .zig_compiler_rt;
}
pub fn argv(c: *u.Context, first: []const []const u8, last: []const []const u8) ![]const []const u8 {
    return std.mem.concat(c.a, []const u8, &.{ first, last });
}
pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    u.installSignals();
    const args = try init.minimal.args.toSlice(c.a);
    if (c.env.get("ZLLVM_CAPTURE_DIR") != null and c.env.get("ZLLVM_CAPTURE_EXE") != null) {
        const code = capture(&c, args[1..]) catch |err| {
            try std.Io.File.stderr().writeStreamingAll(c.io, try c.fmt("capture-zllvm: {s}\n", .{c.diagnostic orelse @errorName(err)}));
            std.process.exit(1);
        };
        if (code < 0) {
            const sig: std.posix.SIG = @fromBackingInt(@intCast(@as(u32, @intCast(-code))));
            const action: std.posix.Sigaction = .{ .handler = .{ .handler = std.posix.SIG.DFL }, .mask = std.posix.sigemptyset(), .flags = 0 };
            std.posix.sigaction(sig, &action, null);
            _ = std.os.linux.kill(std.os.linux.getpid(), sig);
        }
        std.process.exit(@intCast(if (code < 0) 128 - code else code));
    }
    if (args.len == 2 and std.mem.eql(u8, args[1], "--help")) {
        try c.print("usage: run_real_program --output-root DIR [--zig-source DIR] [--zig-emitter EXE] [--zllvm EXE] [--linker EXE] [--manifest JSON] [--mode ReleaseFast|ReleaseSafe|ReleaseSmall] [--codegen-reachable]\n", .{});
        return;
    }
    const code = run(&c, args[1..]) catch |err| {
        try std.Io.File.stderr().writeStreamingAll(c.io, try c.fmt("real-program: {s}\n", .{c.diagnostic orelse @errorName(err)}));
        std.process.exit(2);
    };
    std.process.exit(code);
}

fn capture(c: *u.Context, args: []const []const u8) !i64 {
    if (args.len == 0) return error.MissingCompilerArguments;
    const directory = c.env.get("ZLLVM_CAPTURE_DIR").?;
    const exe = c.env.get("ZLLVM_CAPTURE_EXE").?;
    const object = u.contains(args, "--emit=obj");
    const stem = if (object) "object" else "optimize";
    try c.copy(try c.join(&.{args[args.len - 1]}), try c.join(&.{ directory, if (object) "object-input.ll" else "preopt.ll" }));
    const output = try c.join(&.{ directory, if (object) "local.o" else "optimized.ll" });
    var runner = Runner.init(c, directory);
    const command = try argv(c, &.{exe}, args);
    const result = try runner.run(command, try c.join(&.{ directory, stem }), &c.env, .{
        .stdout_file = output,
        .timeout_ms = std.math.maxInt(u32),
        .group = .child_only,
    });
    try c.writeJson(try c.join(&.{ directory, try c.fmt("{s}-command.json", .{stem}) }), .{ .argv = command, .returncode = result.code, .wall_ns = result.wall_ns });
    try std.Io.File.stdout().writeStreamingAll(c.io, try c.read(output));
    try std.Io.File.stderr().writeStreamingAll(c.io, try c.read(try c.join(&.{ directory, try c.fmt("{s}.stderr", .{stem}) })));
    return result.code;
}

fn run(c: *u.Context, arguments: []const []const u8) !u8 {
    const args = try u.Args.parse(c.a, arguments, &.{ "output-root", "zig-source", "zig-emitter", "zllvm", "linker", "manifest", "mode" }, &.{"codegen-reachable"});
    const output = try c.newOutput(try args.require("output-root"));
    const manifest_path = args.get("manifest") orelse try c.join(&.{"test/real_programs/hello_libc.json"});
    const program = std.fs.path.stem(manifest_path);
    var runner = Runner.init(c, output);
    var report = u.object(c.a);
    try u.put(c.a, &report, "schema", u.s("real-program-v1"));
    try u.put(c.a, &report, "population", u.s("unchanged-upstream-zig-program"));
    try u.put(c.a, &report, "status", u.s("failed"));
    for ([_][]const u8{ "local_executions", "reference_executions", "matched_program_modes" }) |key| try u.put(c.a, &report, key, u.n(0));
    try u.put(c.a, &report, "codegen_selection", u.s(if (args.flag("codegen-reachable")) "reachable" else "legacy"));
    try u.put(c.a, &report, "rows", u.array(c.a));
    execute(c, args, output, manifest_path, &runner, &report) catch |err| {
        try u.put(c.a, &report, "error", u.s(c.diagnostic orelse @errorName(err)));
    };
    try c.writeJson(try c.join(&.{ output, "report.json" }), report);
    const passed = u.json.is(try u.get(report, "status"), "passed");
    try c.print("summary real-program schema=real-program-v1 program={s} programs=1 program_modes={d} reference_executions={d} local_executions={d} matched_program_modes={d} local_fail={d}\n", .{
        program,                                         (report.object.get("program_modes") orelse u.n(0)).integer, (try u.get(report, "reference_executions")).integer,
        (try u.get(report, "local_executions")).integer, (try u.get(report, "matched_program_modes")).integer,       @intFromBool(!passed),
    });
    try c.print("{s}\n", .{try summaryJson(c, report)});
    try c.print("evidence: {s}/report.json\n", .{output});
    if (report.object.get("error")) |err| try std.Io.File.stderr().writeStreamingAll(c.io, try c.fmt("{s}\n", .{err.string}));
    return if (passed) 0 else 1;
}

pub fn summaryJson(c: *u.Context, report: u.Value) ![]const u8 {
    // Preserve the original sorted, single-line JSON record used by full-log comparisons.
    return c.fmt("{{\"local_executions\": {d}, \"matched_program_modes\": {d}, \"reference_executions\": {d}, \"status\": {s}}}", .{
        (try u.get(report, "local_executions")).integer,
        (try u.get(report, "matched_program_modes")).integer,
        (try u.get(report, "reference_executions")).integer,
        try std.json.Stringify.valueAlloc(c.a, try u.str(report, "status"), .{}),
    });
}

fn execute(c: *u.Context, args: u.Args, output: []const u8, manifest_path: []const u8, runner: *Runner, report: *u.Value) !void {
    if (@import("builtin").os.tag != .linux or @import("builtin").cpu.arch != .x86_64) return error.RequiresX8664Linux;
    const procedure = try provenance.tools(c);
    try u.put(c.a, report, "tool_provenance", procedure);
    const manifest = try c.load(try c.join(&.{manifest_path}));
    _ = try linkDriver(args, manifest);
    const modes = try selectedModes(c, args, manifest);
    const source_root = try c.join(&.{args.get("zig-source") orelse "../ziglang"});
    const zig = try c.join(&.{args.get("zig-emitter") orelse try c.join(&.{ source_root, "build/stage4/bin/zig" })});
    const zllvm = try c.join(&.{args.get("zllvm") orelse "zig-out/bin/z_llvm"});
    const pin = u.trim(try c.read(try c.join(&.{"docs/evidence/ziglang_pin.txt"})));
    const contract = try identity(c);
    if (!std.mem.eql(u8, contract.get("ABI_DIFF_SOURCE_REVISION") orelse return error.MissingReferenceIdentity, pin)) return c.fail("reference identity contract differs from the tracked Zig pin", .{});
    if (!std.mem.eql(u8, u.trim(try c.capture(&.{ "git", "-C", source_root, "rev-parse", "HEAD" })), pin)) return c.fail("Zig source revision differs from the tracked pin", .{});
    if (!std.mem.eql(u8, u.trim(try c.capture(&.{ zig, "version" })), contract.get("ABI_DIFF_REFERENCE_VERSION") orelse return error.MissingReferenceIdentity)) return c.fail("Zig emitter identity differs from the reference contract", .{});
    const source = try c.join(&.{ source_root, try u.str(manifest, "source") });
    if (!std.mem.eql(u8, try c.digest(source), try u.str(manifest, "source_sha256"))) return c.fail("upstream program source hash changed; audit the manifest before running", .{});
    if (!std.mem.eql(u8, try c.read(source), try c.capture(&.{ "git", "-C", source_root, "show", try c.fmt("{s}:{s}", .{ pin, try u.str(manifest, "source") }) }))) return c.fail("upstream program has local modifications", .{});
    try u.put(c.a, report, "source", u.s(source));
    try u.put(c.a, report, "source_sha256", u.s(try c.digest(source)));
    try u.put(c.a, report, "zig_revision", u.s(pin));
    try u.put(c.a, report, "zig_emitter_sha256", u.s(try c.digest(zig)));
    try u.put(c.a, report, "link_driver", manifest.object.get("link_driver") orelse u.s("system"));
    try u.put(c.a, report, "zllvm_sha256", u.s(try c.digest(zllvm)));
    try u.put(c.a, report, "source_head", u.s(u.trim(try c.capture(&.{ "git", "rev-parse", "HEAD" }))));
    for ([_][]const u8{ "target", "cpu", "remaining_dependencies" }) |key| try u.put(c.a, report, key, try u.get(manifest, key));
    try u.put(c.a, report, "pipeline", try u.get(manifest, "local_pipeline"));
    try u.put(c.a, report, "programs", u.n(1));
    try u.put(c.a, report, "program_modes", u.n(modes.len));
    try u.put(c.a, report, "manifest", u.s(manifest_path));
    try u.put(c.a, report, "program", u.s(std.fs.path.stem(manifest_path)));
    const base_env = try c.cleanEnvironment();
    const global_cache = try c.join(&.{ output, "global-cache" });
    const proxy = try c.join(&.{ output, "capture-zllvm" });
    try c.copy("/proc/self/exe", proxy);
    const proxy_file = try std.Io.Dir.cwd().openFile(c.io, proxy, .{});
    defer proxy_file.close(c.io);
    try proxy_file.setPermissions(c.io, .fromMode(0o755));
    for (modes) |mode| {
        const directory = try c.join(&.{ output, mode });
        try c.mkdir(directory);
        var row = u.object(c.a);
        try u.put(c.a, &row, "mode", u.s(mode));
        try u.put(c.a, &row, "status", u.s("failed"));
        try u.put(c.a, &row, "failure_stage", u.s("reference-compile"));
        try u.put(c.a, &row, "local_executions", u.n(0));
        // Publish the row before running, so exceptions retain the last failure stage.
        const rows = report.object.getPtr("rows").?;
        try u.add(rows, row);
        try runMode(c, args, directory, mode, source, zig, zllvm, proxy, global_cache, manifest, &base_env, runner, report, &rows.array.items[rows.array.items.len - 1]);
    }
    try provenance.verifyTools(c, procedure);
    try u.put(c.a, report, "status", u.s(if ((try u.get(report.*, "matched_program_modes")).integer == modes.len) "passed" else "blocked"));
}

fn runMode(c: *u.Context, args: u.Args, directory: []const u8, mode: []const u8, source: []const u8, zig: []const u8, zllvm: []const u8, proxy: []const u8, global_cache: []const u8, manifest: u.Value, base_env: *const std.process.Environ.Map, runner: *Runner, report: *u.Value, row: *u.Value) !void {
    var common = std.array_list.Managed([]const u8).init(c.a);
    try common.appendSlice(&.{ zig, "build-obj", source, "-lc", try c.fmt("-O{s}", .{mode}), "-target", try u.str(manifest, "target"), try c.fmt("-mcpu={s}", .{try u.str(manifest, "cpu")}), "-fllvm", "-flibllvm", "-fno-lto", "-fno-stack-protector", "-fno-unwind-tables", "--global-cache-dir", global_cache });
    if (manifest.object.get("extra_compile_args")) |extra| try common.appendSlice(try u.stringSlice(c.a, extra));
    const reference = try c.join(&.{ directory, "reference.o" });
    if ((try runner.run(try argv(c, common.items, &.{ "--cache-dir", try c.join(&.{ directory, "reference-cache" }), try c.fmt("-femit-bin={s}", .{reference}) }), try c.join(&.{ directory, "reference-compile" }), base_env, .{})).code != 0) return;
    const linker = args.get("linker") orelse "cc";
    try u.put(c.a, row, "failure_stage", u.s("reference-link"));
    const reference_exe = try c.join(&.{ directory, "reference" });
    if ((try runner.run(try linkCommand(c, args, manifest, zig, linker, mode, reference, reference_exe, global_cache), try c.join(&.{ directory, "reference-link" }), base_env, .{})).code != 0) return;
    try u.increment(c.a, report, "reference_executions", 1);
    try u.put(c.a, row, "failure_stage", u.s("reference-execution"));
    runner.observe(reference_exe, &.{}, try u.json.integer(try u.get(manifest, "exit_status")), try u.str(manifest, "stdout"), try c.join(&.{ directory, "reference-run" }), base_env) catch |err| {
        if (err == error.ValidationFailed) return;
        return err;
    };
    const candidate = try c.join(&.{ directory, "candidate.o" });
    const marker = try c.join(&.{ directory, "candidate.marker" });
    const capture_dir = try c.join(&.{ directory, "capture" });
    try c.mkdir(capture_dir);
    var local_env = try base_env.clone(c.a);
    const env_keys = [_][]const u8{ "ZIG_USE_ZLLVM_OBJECT", "ZLLVM_PIPELINE", "ZLLVM_EXE", "ZLLVM_CAPTURE_EXE", "ZLLVM_CAPTURE_DIR", "ZLLVM_ZIG_MODE", "ZLLVM_GENERIC_CFG_SELECTOR", "ZLLVM_MARKER_PATH" };
    const env_values = [_][]const u8{ "1", try u.str(manifest, "local_pipeline"), proxy, zllvm, capture_dir, mode, "1", marker };
    for (env_keys, env_values) |key, value| try local_env.put(key, value);
    const selection: []const []const u8 = if (args.flag("codegen-reachable")) &.{"--codegen-reachable"} else &.{};
    if (args.flag("codegen-reachable")) try local_env.put("ZLLVM_CODEGEN_REACHABLE", "1");
    const local_compile = try c.join(&.{ directory, "local-compile" });
    if ((try runner.run(try argv(c, common.items, &.{ "--cache-dir", try c.join(&.{ directory, "candidate-cache" }), try c.fmt("-femit-bin={s}", .{candidate}) }), local_compile, &local_env, .{})).code != 0) {
        const diagnostic = try c.read(try c.fmt("{s}.stderr", .{local_compile}));
        const fields = try markerFields(c, diagnostic);
        const stage = fields.get("failure_category") orelse "local-compile";
        try u.put(c.a, row, "failure_stage", u.s(stage));
        try u.put(c.a, row, "diagnostic", u.s(diagnostic[diagnostic.len -| 8192..]));
        const input = try c.join(&.{ capture_dir, "object-input.ll" });
        if (std.mem.eql(u8, stage, "object") and u.exists(c.io, input)) {
            _ = try runner.run(try argv(c, &.{zllvm}, try argv(c, selection, &.{ "--report-all-codegen-failures", "--generic-cfg-selector", "--emit=obj", "--target=x86_64-unknown-linux-gnu", "--input-limit=67108864", input })), try c.join(&.{ directory, "codegen-failures" }), base_env, .{});
            const details = try c.read(try c.join(&.{ directory, "codegen-failures.stderr" }));
            try u.put(c.a, row, "codegen_diagnostic", u.s(details[details.len -| 8192..]));
        }
        return;
    }
    const fields = try markerFields(c, try c.read(marker));
    if (!std.mem.eql(u8, fields.get("pipeline") orelse "", "preopt") or !std.mem.eql(u8, fields.get("mode") orelse "", mode)) return c.fail("local hook marker does not prove the selected optimizer route", .{});
    const optimized = try c.join(&.{ capture_dir, "object-input.ll" });
    for ([_][]const u8{ "ir", "object" }) |key| if (!u.isWithin(directory, try c.ownedPath(fields.get(key) orelse return error.MissingHookArtifact))) return c.fail("hook artifacts escaped the runner-owned directory", .{});
    if (!std.mem.eql(u8, fields.get("zllvm_passes") orelse "", try u.pipeline(mode))) return c.fail("local hook marker does not identify the accepted mode pipeline", .{});
    const hook = try c.join(&.{ capture_dir, "local.o" });
    const hook_contract = try elf.parse(c.a, try c.read(hook));
    if (!u.json.eql(hook_contract, try elf.parse(c.a, try c.read(candidate)))) return c.fail("linked candidate changed hook sections, symbols or relocations", .{});
    try c.writeJson(try c.join(&.{ directory, "object-contract.json" }), hook_contract);
    try u.put(c.a, row, "hook_object_sha256", u.s(try c.digest(hook)));
    try u.put(c.a, row, "failure_stage", u.s("selection-owner-manifest"));
    if ((try runner.run(try argv(c, &.{zllvm}, try argv(c, selection, &.{ "--emit=selection-owner-manifest", "--generic-cfg-selector", "--target=x86_64-unknown-linux-gnu", "--input-limit=67108864", optimized })), try c.join(&.{ directory, "owners" }), base_env, .{})).code != 0) return;
    var owners = u.object(c.a);
    var lines = std.mem.tokenizeScalar(u8, try c.read(try c.join(&.{ directory, "owners.stdout" })), '\n');
    _ = lines.next();
    while (lines.next()) |line| {
        var columns = std.mem.splitScalar(u8, line, '\t');
        _ = columns.next();
        try u.increment(c.a, &owners, columns.next() orelse return error.InvalidOwnerManifest, 1);
    }
    try u.put(c.a, row, "selector_owners", owners);
    try u.put(c.a, row, "object_bytes", u.n((try std.Io.Dir.cwd().statFile(c.io, candidate, .{})).size));
    try u.put(c.a, row, "object_sha256", u.s(try c.digest(candidate)));
    try u.put(c.a, row, "failure_stage", u.s("local-link"));
    const candidate_exe = try c.join(&.{ directory, "candidate" });
    if ((try runner.run(try linkCommand(c, args, manifest, zig, linker, mode, candidate, candidate_exe, global_cache), try c.join(&.{ directory, "local-link" }), base_env, .{})).code != 0) return;
    try u.increment(c.a, row, "local_executions", 1);
    try u.increment(c.a, report, "local_executions", 1);
    try u.put(c.a, row, "failure_stage", u.s("local-execution"));
    runner.observe(candidate_exe, &.{}, try u.json.integer(try u.get(manifest, "exit_status")), try c.read(try c.join(&.{ directory, "reference-run.stdout" })), try c.join(&.{ directory, "local-run" }), base_env) catch |err| {
        if (err == error.ValidationFailed) return;
        return err;
    };
    try u.put(c.a, row, "status", u.s("matched"));
    try u.put(c.a, row, "failure_stage", .null);
    try u.increment(c.a, report, "matched_program_modes", 1);
}

fn linkCommand(c: *u.Context, args: u.Args, manifest: u.Value, zig: []const u8, linker: []const u8, mode: []const u8, object: []const u8, executable: []const u8, global_cache: []const u8) ![]const []const u8 {
    if (try linkDriver(args, manifest) == .system) return c.a.dupe([]const u8, &.{ linker, "-no-pie", object, "-o", executable });
    // Both objects use the same pinned runtime and CRT. This only links the
    // already admitted object; it does not compile the program source again.
    return c.a.dupe([]const u8, &.{
        zig,                                        "build-exe", object,                        "-lc",                                                 "-fcompiler-rt",      "-fllvm",     "-flibllvm",   "-fno-lto",
        try c.fmt("-O{s}", .{mode}),                "-target",   try u.str(manifest, "target"), try c.fmt("-mcpu={s}", .{try u.str(manifest, "cpu")}), "--global-cache-dir", global_cache, "--cache-dir", try c.fmt("{s}-link-cache", .{executable}),
        try c.fmt("-femit-bin={s}", .{executable}),
    });
}
