//! Standalone diagnostic, deliberately outside the accepted distribution gates.
const std = @import("std");
const u = @import("common.zig");
const Runner = @import("runner.zig").Runner;
const program = @import("program.zig");
const reports = @import("whole_compiler_report.zig");
const provenance = @import("provenance.zig");
const elf = @import("object_contract.zig");
const policy = @import("../distribution_headroom_policy.zig");
const retained = @import("whole_compiler_reuse.zig");
const resources = @import("whole_compiler_resources.zig");
const pin = "1c08b09d1c847f4f02c8216e3b62df323861a437";
const usage = "usage: run_whole_compiler --output-root DIR --zllvm EXE [--zig-source DIR] [--zig-emitter EXE] [--config-h FILE] [--libc-file FILE] [--reuse-captured-objects ROOT] [--self-cpu N] [--timeout-ms N] [--input-ir FILE] [--profile-events] [--runtime-checks]\n";

pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    u.installSignals();
    const argv = try init.minimal.args.toSlice(c.a);
    if (c.env.get("ZLLVM_WHOLE_CAPTURE_ROOT")) |root| {
        const code = capture(&c, root, argv[1..]) catch |err| {
            try std.Io.File.stderr().writeStreamingAll(c.io, try c.fmt("whole-compiler capture: {s}\n", .{@errorName(err)}));
            std.process.exit(2);
        };
        std.process.exit(code);
    }
    if (argv.len == 2 and std.mem.eql(u8, argv[1], "--help")) return c.print("{s}", .{usage});
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "zllvm", "zig-source", "zig-emitter", "config-h", "libc-file", "reuse-captured-objects", "self-cpu", "timeout-ms", "input-ir" }, &.{ "profile-events", "runtime-checks" });
    if (args.flag("runtime-checks") and args.get("input-ir") == null) return error.RuntimeChecksRequireCapturedInput;
    if (args.get("self-cpu")) |cpu| {
        _ = try resources.cpuIndex(cpu);
        if (args.get("input-ir") != null) return error.SelfCpuRequiresWholeBuild;
    }
    const output = try c.newOutput(try args.require("output-root"));
    var report = u.object(c.a);
    try u.put(c.a, &report, "schema", u.s("whole-compiler-diagnostic-v1"));
    try u.put(c.a, &report, "population", u.s(if (args.get("input-ir") != null) "captured-ir-diagnostic" else "whole-zig-compiler"));
    try u.put(c.a, &report, "route", u.s("llvm-postopt-to-zllvm-object"));
    try u.put(c.a, &report, "status", u.s("incomplete"));
    try u.put(c.a, &report, "failure_stage", u.s("setup"));
    try u.put(c.a, &report, "capability_credit", u.b(false));
    var runner = Runner.init(&c, output);
    execute(&c, args, output, &runner, &report) catch |err| {
        try u.put(c.a, &report, "runner_error", u.s(c.diagnostic orelse @errorName(err)));
    };
    try u.put(c.a, &report, "commands", runner.commands);
    try c.writeJson(try c.join(&.{ output, "report.json" }), report);
    try c.print("whole-compiler status={s} stage={s} report={s}/report.json\n", .{ try u.str(report, "status"), try u.str(report, "failure_stage"), output });
    if (report.object.get("runner_error")) |err| try std.Io.File.stderr().writeStreamingAll(c.io, try c.fmt("{s}\n", .{err.string}));
    std.process.exit(if (report.object.contains("runner_error")) 2 else if (u.json.is(try u.get(report, "status"), "passed")) 0 else 1);
}

fn timeout(args: u.Args) !u32 {
    const value = try std.fmt.parseInt(u32, args.get("timeout-ms") orelse "3600000", 10);
    if (value == 0) return error.InvalidTimeout;
    return value;
}

fn fileIdentity(c: *u.Context, path: []const u8) !u.Value {
    var value = u.object(c.a);
    try u.put(c.a, &value, "path", u.s(path));
    try u.put(c.a, &value, "bytes", u.n((try std.Io.Dir.cwd().statFile(c.io, path, .{})).size));
    try u.put(c.a, &value, "sha256", u.s(try c.digest(path)));
    return value;
}

fn environment(c: *u.Context, output: []const u8) !std.process.Environ.Map {
    var env = std.process.Environ.Map.init(c.a);
    for ([_][2][]const u8{
        .{ "PATH", "/home/oleg/bin:/usr/lib/llvm-22/bin:/usr/bin:/bin" },
        .{ "LC_ALL", "C" },
        .{ "LANG", "C" },
        .{ "TZ", "UTC0" },
        .{ "HOME", try c.join(&.{ output, "home" }) },
        .{ "TMPDIR", try c.join(&.{ output, "temp" }) },
        .{ "ZIG_GLOBAL_CACHE_DIR", try c.join(&.{ output, "global-cache" }) },
        .{ "GIT_OPTIONAL_LOCKS", "0" },
        .{ "GIT_CONFIG_NOSYSTEM", "1" },
        .{ "GIT_CONFIG_SYSTEM", "/dev/null" },
        .{ "GIT_CONFIG_GLOBAL", "/dev/null" },
        .{ "GIT_TERMINAL_PROMPT", "0" },
        .{ "ZLLVM_PROJECT_ROOT", c.root },
    }) |pair| try env.put(pair[0], pair[1]);
    for ([_][]const u8{ "HOME", "TMPDIR", "ZIG_GLOBAL_CACHE_DIR" }) |key| try c.mkdir(env.get(key).?);
    return env;
}

fn saveEnvironment(c: *u.Context, env: *const std.process.Environ.Map, path: []const u8) !void {
    var value = u.object(c.a);
    for (env.keys(), env.values()) |key, item| try u.put(c.a, &value, key, u.s(item));
    try c.writeJson(path, value);
}

fn execute(c: *u.Context, args: u.Args, output: []const u8, runner: *Runner, report: *u.Value) !void {
    if (@import("builtin").cpu.arch != .x86_64 or @import("builtin").os.tag != .linux) return error.RequiresX8664Linux;
    const compiler = try c.join(&.{try args.require("zllvm")});
    const compiler_hash = try c.digest(compiler);
    try u.put(c.a, report, "backend", try fileIdentity(c, compiler));
    const compiler_build = try @import("toolchain.zig").compilerBuild(c, compiler);
    try u.put(c.a, report, "backend_build", compiler_build);
    try u.put(c.a, report, "backend_build_mode", if (u.json.is(try u.get(compiler_build, "status"), "recorded")) try u.get(try u.get(compiler_build, "identity"), "build_mode") else u.s("unrecorded caller-selected compiler"));
    try u.put(c.a, report, "project_revision", u.s(u.trim(try c.capture(&.{ "git", "rev-parse", "HEAD" }))));
    const source_scope = &.{ "src", "tools", "test/whole_compiler", "build.zig", "build.zig.zon" };
    const source_snapshot = try provenance.files(c, source_scope);
    try u.put(c.a, report, "source_snapshot", source_snapshot);
    try u.put(c.a, report, "runner", try fileIdentity(c, "/proc/self/exe"));
    var env = try environment(c, output);
    if (args.flag("profile-events")) try env.put("ZLLVM_WHOLE_PROFILE_EVENTS", "1");
    if (args.get("libc-file")) |path| {
        const original = try c.join(&.{path});
        const libc = try std.zig.LibCInstallation.parse(c.a, c.io, original, &@import("builtin").target);
        const effective = try c.join(&.{ output, "native-libc.txt" });
        try c.copy(original, effective);
        try env.put("ZIG_LIBC", effective);
        try u.put(c.a, report, "original_libc_config", try fileIdentity(c, original));
        try u.put(c.a, report, "effective_libc_config", try fileIdentity(c, effective));
        var inputs = u.array(c.a);
        const crt = libc.crt_dir orelse return error.MissingLibcCrtDirectory;
        const cc = libc.cc_dir orelse return error.MissingLibcCcDirectory;
        if (!std.fs.path.isAbsolute(crt) or !std.fs.path.isAbsolute(cc)) return error.LibcPathsMustBeAbsolute;
        for ([_][]const u8{ "crt1.o", "Scrt1.o", "crti.o", "crtn.o", "libc.so", "libc.so.6", "ld-linux-x86-64.so.2" }) |name| try u.add(&inputs, try fileIdentity(c, try c.join(&.{ crt, name })));
        for ([_][]const u8{ "crtbegin.o", "crtend.o", "crtbeginS.o", "crtendS.o" }) |name| try u.add(&inputs, try fileIdentity(c, try c.join(&.{ cc, name })));
        try u.put(c.a, report, "native_libc_inputs", inputs);
    }
    if (args.get("reuse-captured-objects")) |path| {
        const root = try c.join(&.{path});
        if (u.isWithin(output, root) or u.isWithin(root, output)) return error.ReuseRootMustBeIndependent;
        try env.put("ZLLVM_WHOLE_REUSE_ROOT", root);
        try u.put(c.a, report, "initial_build_reuse_root", u.s(root));
        try u.put(c.a, report, "self_rebuild_backend_reuse", u.b(false));
    }
    try saveEnvironment(c, &env, try c.join(&.{ output, "base-environment.json" }));
    const first = try freeSpace(c.io, output);
    if (first < policy.serial_reserve_floor_bytes + policy.serial_projected_peak_bytes) return error.InsufficientAdmissionSpace;
    var watch: Watch = .{ .io = c.io, .path = output, .minimum = first, .start = first, .log = try c.createLog(try c.join(&.{ output, "space-samples.tsv" }), true) };
    defer watch.log.close(c.io);
    const space_path = try c.join(&.{ output, "space.json" });
    const thread = try std.Thread.spawn(.{}, Watch.run, .{&watch});
    defer {
        watch.stop.store(true, .release);
        thread.join();
        c.writeJson(space_path, .{
            .starting_free_bytes = watch.start,
            .minimum_sampled_free_bytes = watch.minimum,
            .reserve_bytes = policy.serial_reserve_floor_bytes,
            .required_start_bytes = policy.serial_reserve_floor_bytes + policy.serial_projected_peak_bytes,
            .reserve_violated = watch.violation,
            .sampling_failed = watch.failed,
            .interval_ms = 2000,
        }) catch {};
        if (watch.violation or watch.failed) {
            u.put(c.a, report, "status", u.s("resource-stop")) catch {};
            u.put(c.a, report, "failure_stage", u.s(if (watch.violation) "disk-reserve" else "disk-sampling")) catch {};
        }
    }
    if (args.get("input-ir")) |input| {
        const directory = try c.join(&.{ output, "backend" });
        try c.mkdir(directory);
        const result = try backend(c, directory, compiler, try c.join(&.{input}), &.{}, &env, try timeout(args), .owned);
        try u.put(c.a, report, "invocation", result);
        try u.put(c.a, report, "failure_stage", try u.get(result, "failure_stage"));
        try u.put(c.a, report, "status", u.s(if ((try u.get(result, "object_complete")).bool) "passed" else "blocked"));
        if (args.flag("runtime-checks") and (try u.get(result, "object_complete")).bool) {
            try u.put(c.a, report, "failure_stage", u.s("runtime-execution"));
            try u.put(c.a, report, "status", u.s("incomplete"));
            try c.writeJson(try c.join(&.{ output, "report.json" }), report.*);
            try u.put(c.a, report, "runtime_object_checks", try runtimeObjectChecks(c, output, result, &env, runner));
            try u.put(c.a, report, "failure_stage", u.s("none"));
            try u.put(c.a, report, "status", u.s("passed"));
        }
    } else {
        try wholeBuild(c, args, output, compiler, &env, runner, report);
    }
    if (!std.mem.eql(u8, compiler_hash, try c.digest(compiler))) return error.BackendChangedDuringRun;
    if (!u.json.eql(source_snapshot, try provenance.files(c, source_scope))) return error.DiagnosticSourceChangedDuringRun;
    for ([_][]const u8{ "original_libc_config", "effective_libc_config" }) |field| if (report.object.get(field)) |identity| {
        if (!std.mem.eql(u8, try c.digest(try u.str(identity, "path")), try u.str(identity, "sha256"))) return error.LibcConfigChangedDuringRun;
    };
    if (report.object.get("native_libc_inputs")) |inputs| for (inputs.array.items) |identity| {
        if (!std.mem.eql(u8, try c.digest(try u.str(identity, "path")), try u.str(identity, "sha256"))) return error.LibcProviderChangedDuringRun;
    };
    try u.put(c.a, report, "source_and_backend_verified", u.b(true));
}

fn buildArgs(c: *u.Context, zig: []const u8, source: []const u8, config: []const u8, output: []const u8) ![]const []const u8 {
    // This pinned build runner accepts ZIG_GLOBAL_CACHE_DIR through its
    // environment; --global-cache-dir is a compiler-command option only.
    return c.a.dupe([]const u8, &.{ zig, "build", "--build-file", try c.join(&.{ source, "build.zig" }), "--cache-dir", try c.join(&.{ output, "local-cache" }), "--prefix", try c.join(&.{ output, "install" }), "-j1", "--verbose", "--summary", "all", "-Dtarget=x86_64-linux-gnu", "-Dcpu=baseline", "-Doptimize=ReleaseFast", "-Dstrip=true", "-Ddev=full", "-Denable-llvm=true", "-Duse-llvm=true", "-Ddebug-extensions=true", "-Dno-lib=true", "-Dno-langref=true", try c.fmt("-Dconfig_h={s}", .{config}) });
}

fn timed(c: *u.Context, runner: *Runner, command: []const []const u8, stem: []const u8, env: *const std.process.Environ.Map, options: Runner.Options) !Runner.Result {
    return runner.run(try program.argv(c, &.{ "/usr/bin/time", "-f", "wall_seconds=%e\nmax_rss_kb=%M\nexit_status=%x", "-o", try c.fmt("{s}.time", .{stem}), "--" }, command), stem, env, options);
}

fn warmupEnvironment(c: *u.Context, output: []const u8, env: *const std.process.Environ.Map) !std.process.Environ.Map {
    // Populate this generation's host-tool cache without the object hook.
    // Both generations use the pinned emitter for setup. Switching global
    // roots afterward would rebuild the host tool under the hook instead of
    // starting the requested baseline compiler.
    const warm = try env.clone(c.a);
    try saveEnvironment(c, &warm, try c.join(&.{ output, "warmup-environment.json" }));
    return warm;
}

fn resolveProviders(c: *u.Context, config: []const u8, output: []const u8, report: *u.Value) ![]const u8 {
    // An explicit GNU target does not inherit the host's multiarch search
    // directories. Preserve the original config and resolve its installed
    // system providers, without modifying the pinned source/build tree.
    const text = try c.read(config);
    const prefix = "#define ZIG_LLVM_LIBRARIES \"";
    const begin = (std.mem.indexOf(u8, text, prefix) orelse return error.MissingLlvmLibraries) + prefix.len;
    const end = begin + (std.mem.indexOfScalar(u8, text[begin..], '"') orelse return error.InvalidLlvmLibraries);
    var libraries: std.ArrayList([]const u8) = .empty;
    var items = std.mem.splitScalar(u8, text[begin..end], ';');
    while (items.next()) |item| {
        var resolved = item;
        if (std.mem.startsWith(u8, item, "-l")) {
            const path = try c.fmt("/usr/lib/x86_64-linux-gnu/lib{s}.so", .{item[2..]});
            if (u.exists(c.io, path)) resolved = path;
        }
        try libraries.append(c.a, resolved);
    }
    const effective = try c.join(&.{ output, "resolved-config.h" });
    const updated = try c.fmt("{s}{s}{s}", .{ text[0..begin], try std.mem.join(c.a, ";", libraries.items), text[end..] });
    try c.write(effective, updated);
    var providers = u.array(c.a);
    var lines = std.mem.tokenizeScalar(u8, updated, '\n');
    while (lines.next()) |line| {
        if (!std.mem.startsWith(u8, line, "#define ZIG_") or std.mem.indexOf(u8, line, "_LIBRARIES ") == null) continue;
        const quote = std.mem.indexOfScalar(u8, line, '"') orelse continue;
        var paths = std.mem.tokenizeScalar(u8, line[quote + 1 .. line.len - 1], ';');
        while (paths.next()) |path| if (std.fs.path.isAbsolute(path)) try u.add(&providers, try fileIdentity(c, path));
    }
    try u.put(c.a, report, "external_libraries", providers);
    try u.put(c.a, report, "resolved_cmake_config", try fileIdentity(c, effective));
    return effective;
}

fn wholeBuild(c: *u.Context, args: u.Args, output: []const u8, compiler: []const u8, env: *std.process.Environ.Map, runner: *Runner, report: *u.Value) !void {
    const self_cpu = args.get("self-cpu");
    // Resource controls are explicit process launchers. They do not alter the
    // source, target CPU, generated-frame guard or captured object contract.
    if (self_cpu) |cpu| {
        try u.put(c.a, report, "self_rebuild_cpu", u.n(try resources.cpuIndex(cpu)));
        try u.put(c.a, report, "self_rebuild_cpu_launcher", try fileIdentity(c, resources.launcher));
    }
    const limits_path = try c.join(&.{ output, "process-limits.txt" });
    try c.write(limits_path, try c.read("/proc/self/limits"));
    try u.put(c.a, report, "inherited_process_limits", try fileIdentity(c, limits_path));
    const source = try c.join(&.{args.get("zig-source") orelse "../ziglang"});
    const zig = try c.join(&.{args.get("zig-emitter") orelse "../ziglang/build/stage4/bin/zig"});
    const original_config = try c.join(&.{args.get("config-h") orelse try c.join(&.{ source, "build/config.h" })});
    const revision = u.trim(try c.capture(&.{ "git", "-C", source, "rev-parse", "HEAD" }));
    if (!std.mem.eql(u8, pin, revision)) return error.UnexpectedFrontendPin;
    if (u.trim(try c.capture(&.{ "git", "-C", source, "status", "--porcelain", "--untracked-files=no" })).len != 0) return error.ModifiedFrontendSource;
    const zig_hash = try c.digest(zig);
    try u.put(c.a, report, "zig_source_revision", u.s(revision));
    try u.put(c.a, report, "zig_emitter", try fileIdentity(c, zig));
    try u.put(c.a, report, "host_tool_warmup_emitter", try fileIdentity(c, zig));
    try u.put(c.a, report, "host_tool_scope", u.s("pinned-emitter setup outside compiler/runtime object captures"));
    try u.put(c.a, report, "zig_version", u.s(u.trim(try c.capture(&.{ zig, "version" }))));
    try u.put(c.a, report, "target", u.s("x86_64-linux-gnu"));
    try u.put(c.a, report, "cpu", u.s("baseline"));
    try u.put(c.a, report, "mode", u.s("ReleaseFast"));
    try u.put(c.a, report, "llvm_enabled", u.b(true));
    try u.put(c.a, report, "llvm_optimization", u.b(true));
    try u.put(c.a, report, "cmake_config", try fileIdentity(c, original_config));
    try c.copy(original_config, try c.join(&.{ output, "config.h" }));
    const config = try resolveProviders(c, original_config, output, report);
    try c.write(try c.join(&.{ output, "frontend-libraries.txt" }), try c.capture(&.{ "ldd", zig }));
    try u.put(c.a, report, "zigcpp_provider", try fileIdentity(c, try c.join(&.{ source, "build/zigcpp/libzigcpp.a" })));
    try env.put("ZIG_LIB_DIR", try c.join(&.{ source, "lib" }));
    const command = try buildArgs(c, zig, source, config, output);
    try c.writeJson(try c.join(&.{ output, "build-command.json" }), command);
    try u.put(c.a, report, "status", u.s("blocked"));
    try u.put(c.a, report, "failure_stage", u.s("build-runner-warmup"));
    const warm_env = try warmupEnvironment(c, output, env);
    const warm = try timed(c, runner, try program.argv(c, command, &.{"--help"}), try c.join(&.{ output, "warmup" }), &warm_env, .{ .timeout_ms = try timeout(args) });
    if (warm.code != 0) return;
    const captures = try c.join(&.{ output, "captures" });
    try c.mkdir(captures);
    var local_env = try env.clone(c.a);
    const proxy = try std.Io.Dir.cwd().realPathFileAlloc(c.io, "/proc/self/exe", c.a);
    for ([_][2][]const u8{
        .{ "ZIG_USE_ZLLVM_OBJECT", "1" },                                  .{ "ZLLVM_PIPELINE", "postopt" },
        .{ "ZLLVM_EXE", proxy },                                           .{ "ZLLVM_WHOLE_BACKEND", compiler },
        .{ "ZLLVM_WHOLE_CAPTURE_ROOT", captures },                         .{ "ZLLVM_ZIG_MODE", "ReleaseFast" },
        .{ "ZLLVM_MARKER_PATH", try c.join(&.{ output, "hook.marker" }) }, .{ "ZLLVM_WHOLE_TIMEOUT_MS", try c.fmt("{d}", .{try timeout(args)}) },
    }) |pair| try local_env.put(pair[0], pair[1]);
    try saveEnvironment(c, &local_env, try c.join(&.{ output, "hook-environment.json" }));
    try u.put(c.a, report, "failure_stage", u.s("frontend-or-optimization"));
    const build = try timed(c, runner, command, try c.join(&.{ output, "build" }), &local_env, .{ .timeout_ms = try timeout(args) });
    const invocations = try collect(c, captures);
    try u.put(c.a, report, "invocations", invocations);
    try u.put(c.a, report, "build_returncode", u.n(build.code));
    try u.put(c.a, report, "build_completed", u.b(build.completed));
    var compiler_seen = false;
    var complete = invocations.array.items.len != 0;
    for (invocations.array.items) |invocation| {
        const input = try u.str(invocation, "original_input");
        const name = std.fs.path.basename(input);
        if (std.mem.eql(u8, name, "zig_zcu.o.zllvm.ll") or std.mem.eql(u8, name, "zig.o.zllvm.ll") or std.mem.eql(u8, name, "zig.zllvm.ll")) compiler_seen = true;
        if (!(try u.get(invocation, "object_complete")).bool) {
            complete = false;
            try u.put(c.a, report, "failure_stage", try u.get(invocation, "failure_stage"));
        }
    }
    try u.put(c.a, report, "compiler_object_captured", u.b(compiler_seen));
    try u.put(c.a, report, "all_hook_objects_complete", u.b(complete));
    if (!build.completed) try u.put(c.a, report, "failure_stage", u.s("build-process-interruption"));
    if (!std.mem.eql(u8, zig_hash, try c.digest(zig))) return error.FrontendBinaryChanged;
    if (!std.mem.eql(u8, revision, u.trim(try c.capture(&.{ "git", "-C", source, "rev-parse", "HEAD" })))) return error.FrontendRevisionChanged;
    if (u.trim(try c.capture(&.{ "git", "-C", source, "status", "--porcelain", "--untracked-files=no" })).len != 0) return error.ModifiedFrontendSource;
    for ((try u.get(report.*, "external_libraries")).array.items) |provider| {
        if (!std.mem.eql(u8, try c.digest(try u.str(provider, "path")), try u.str(provider, "sha256"))) return error.ExternalProviderChanged;
    }
    if (build.code != 0 or !complete) {
        try u.put(c.a, report, "status", u.s("blocked"));
        if (complete) try u.put(c.a, report, "failure_stage", u.s("link-or-runtime-build"));
        // The build may reject compiler_rt before ever emitting the compiler
        // module. Preserve that failure, then diagnose the actual compiler's
        // postopt IR separately. This cannot earn link/startup/rebuild credit.
        if (build.completed and !compiler_seen and invocations.array.items.len != 0)
            try diagnoseCompilerModule(c, args, output, source, zig, compiler, env, runner, report);
        return;
    }
    if (!compiler_seen) return error.MissingCompilerObjectCapture;
    const marker = try c.read(try c.join(&.{ output, "hook.marker" }));
    if (std.mem.indexOf(u8, marker, "pipeline=postopt") == null) return error.MissingPostoptHookMarker;
    const candidate = try c.join(&.{ output, "install/bin/zig" });
    try u.put(c.a, report, "candidate", try fileIdentity(c, candidate));
    try u.put(c.a, report, "failure_stage", u.s("startup"));
    const version = try runner.run(&.{ candidate, "version" }, try c.join(&.{ output, "version" }), env, .{});
    if (version.code != 0 or !std.mem.eql(u8, u.trim(try c.read(try c.join(&.{ output, "version.stdout" }))), try u.str(report.*, "zig_version"))) return;
    try u.put(c.a, report, "startup_passed", u.b(true));
    try u.put(c.a, report, "failure_stage", u.s("behavior"));
    try behaviors(c, output, source, candidate, env, runner);
    try u.put(c.a, report, "behavior_passed", u.b(true));
    try u.put(c.a, report, "failure_stage", u.s("self-rebuild"));
    const rebuild = try c.join(&.{ output, "self-rebuild" });
    try c.mkdir(rebuild);
    var rebuild_env = try env.clone(c.a);
    const rebuild_global_cache = try c.join(&.{ rebuild, "global-cache" });
    try c.mkdir(rebuild_global_cache);
    try rebuild_env.put("ZIG_GLOBAL_CACHE_DIR", rebuild_global_cache);
    _ = rebuild_env.swapRemove("ZLLVM_WHOLE_REUSE_ROOT");
    try saveEnvironment(c, &rebuild_env, try c.join(&.{ rebuild, "base-environment.json" }));
    const rebuild_warm_env = try warmupEnvironment(c, rebuild, &rebuild_env);
    const rebuild_command = try buildArgs(c, candidate, source, config, rebuild);
    const rebuild_warm_command = try buildArgs(c, zig, source, config, rebuild);
    const self_build_command = try resources.command(c.a, self_cpu, rebuild_command);
    const self_warm_command = try resources.command(c.a, self_cpu, try program.argv(c, rebuild_warm_command, &.{"--help"}));
    try c.writeJson(try c.join(&.{ rebuild, "build-command.json" }), self_build_command);
    try c.writeJson(try c.join(&.{ rebuild, "warmup-command.json" }), self_warm_command);
    if ((try timed(c, runner, self_warm_command, try c.join(&.{ output, "self-warmup" }), &rebuild_warm_env, .{ .timeout_ms = try timeout(args) })).code != 0) return;
    const rebuild_captures = try c.join(&.{ rebuild, "captures" });
    try c.mkdir(rebuild_captures);
    try local_env.put("ZLLVM_WHOLE_CAPTURE_ROOT", rebuild_captures);
    try local_env.put("ZLLVM_MARKER_PATH", try c.join(&.{ rebuild, "hook.marker" }));
    // Only the initial retry may reuse preceding complete local objects.
    // The candidate's own compiler-module rebuild must execute the backend.
    _ = local_env.swapRemove("ZLLVM_WHOLE_REUSE_ROOT");
    try local_env.put("ZIG_GLOBAL_CACHE_DIR", rebuild_global_cache);
    try saveEnvironment(c, &local_env, try c.join(&.{ rebuild, "hook-environment.json" }));
    const rebuilt = try timed(c, runner, self_build_command, try c.join(&.{ output, "self-build" }), &local_env, .{ .timeout_ms = try timeout(args) });
    const rebuild_invocations = try collect(c, rebuild_captures);
    try u.put(c.a, report, "self_rebuild_invocations", rebuild_invocations);
    if (rebuilt.code != 0 or rebuild_invocations.array.items.len == 0) return;
    var rebuilt_compiler_seen = false;
    for (rebuild_invocations.array.items) |invocation| {
        if (!(try u.get(invocation, "object_complete")).bool) return error.IncompleteSelfRebuild;
        const name = std.fs.path.basename(try u.str(invocation, "original_input"));
        if (std.mem.eql(u8, name, "zig_zcu.o.zllvm.ll") or std.mem.eql(u8, name, "zig.o.zllvm.ll") or std.mem.eql(u8, name, "zig.zllvm.ll")) rebuilt_compiler_seen = true;
    }
    // Runtime-only captures cannot prove that the new compiler rebuilt itself.
    if (!rebuilt_compiler_seen) return error.MissingCompilerObjectCapture;
    if (std.mem.indexOf(u8, try c.read(try c.join(&.{ rebuild, "hook.marker" })), "pipeline=postopt") == null) return error.MissingPostoptHookMarker;
    const rebuilt_exe = try c.join(&.{ rebuild, "install/bin/zig" });
    try u.put(c.a, report, "rebuilt_candidate", try fileIdentity(c, rebuilt_exe));
    try runner.observe(rebuilt_exe, &.{"version"}, 0, try c.fmt("{s}\n", .{try u.str(report.*, "zig_version")}), try c.join(&.{ output, "self-version" }), env);
    try behaviors(c, rebuild, source, rebuilt_exe, env, runner);
    try u.put(c.a, report, "self_rebuild_passed", u.b(true));
    if (self_cpu != null) {
        const recorded_launcher = try u.get(report.*, "self_rebuild_cpu_launcher");
        if (!std.mem.eql(u8, try c.digest(resources.launcher), try u.str(recorded_launcher, "sha256"))) return error.SelfCpuLauncherChanged;
    }
    try u.put(c.a, report, "failure_stage", u.s("none"));
    try u.put(c.a, report, "status", u.s("passed"));
}

fn diagnoseCompilerModule(c: *u.Context, args: u.Args, output: []const u8, source: []const u8, zig: []const u8, compiler: []const u8, env: *const std.process.Environ.Map, runner: *Runner, report: *u.Value) !void {
    const log = try c.read(try c.join(&.{ output, "build.stderr" }));
    const prefix = try c.fmt("info(verbose): {s} build-exe ", .{zig});
    var lines = std.mem.tokenizeScalar(u8, log, '\n');
    var recorded: ?[]const u8 = null;
    while (lines.next()) |line| if (std.mem.startsWith(u8, line, prefix)) {
        if (recorded != null) return error.AmbiguousCompilerCommand;
        recorded = line["info(verbose): ".len..];
    };
    const line = recorded orelse return error.MissingCompilerCommand;
    // The pinned runner prints this host's argument vector without quoting.
    // Refuse quoted/escaped variants; never execute recorded text as a shell.
    if (std.mem.indexOfAny(u8, line, "\"'\\\t") != null) return error.AmbiguousCompilerCommand;
    var command: std.ArrayList([]const u8) = .empty;
    var tokens = std.mem.tokenizeScalar(u8, line, ' ');
    while (tokens.next()) |arg| if (!std.mem.eql(u8, arg, "--listen=-")) try command.append(c.a, arg);
    const root_arg = try c.fmt("-Mroot={s}/src/main.zig", .{source});
    if (!u.contains(command.items, root_arg) or !u.contains(command.items, "-Ofast") or !u.contains(command.items, "x86_64-linux-gnu")) return error.UnexpectedCompilerCommand;
    const directory = try c.join(&.{ output, "compiler-module" });
    try c.mkdir(directory);
    const input = try c.join(&.{ directory, "compiler.ll" });
    try command.appendSlice(c.a, &.{ "-fno-compiler-rt", "-fno-emit-bin", try c.fmt("-femit-llvm-ir={s}", .{input}) });
    try c.writeJson(try c.join(&.{ directory, "frontend-argv.json" }), command.items);
    var result = u.object(c.a);
    try u.put(c.a, &result, "scope", u.s("compiler module only; runtime failure remains; no object fallback or link credit"));
    try u.put(c.a, &result, "failure_stage", u.s("frontend-or-optimization"));
    try u.put(c.a, &result, "object_complete", u.b(false));
    const emitted = try timed(c, runner, command.items, try c.join(&.{ directory, "frontend" }), env, .{ .timeout_ms = try timeout(args) });
    try u.put(c.a, &result, "frontend_returncode", u.n(emitted.code));
    if (emitted.code == 0) {
        const backend_dir = try c.join(&.{ directory, "backend" });
        try c.mkdir(backend_dir);
        const invocation = try backend(c, backend_dir, compiler, input, &.{}, env, try timeout(args), .owned);
        try u.put(c.a, &result, "invocation", invocation);
        try u.put(c.a, &result, "failure_stage", try u.get(invocation, "failure_stage"));
        try u.put(c.a, &result, "object_complete", try u.get(invocation, "object_complete"));
    }
    try c.writeJson(try c.join(&.{ directory, "report.json" }), result);
    try u.put(c.a, report, "compiler_module_diagnostic", result);
}

fn behaviors(c: *u.Context, output: []const u8, source: []const u8, candidate: []const u8, env: *std.process.Environ.Map, runner: *Runner) !void {
    for ([_][]const u8{ "hello_libc", "while_loops" }) |name| {
        const manifest = try c.load(try c.fmt("{s}/test/real_programs/{s}.json", .{ c.root, name }));
        const input = try c.join(&.{ source, try u.str(manifest, "source") });
        if (!std.mem.eql(u8, try c.digest(input), try u.str(manifest, "source_sha256"))) return error.BehaviorSourceChanged;
        const exe = try c.join(&.{ output, name });
        const command = [_][]const u8{ candidate, "build-exe", input, "-OReleaseFast", "-target", "x86_64-linux-gnu", "-mcpu=baseline", "-lc", "-fllvm", "-fsingle-threaded", "--cache-dir", try c.join(&.{ output, "behavior-cache" }), try c.fmt("-femit-bin={s}", .{exe}) };
        const result = try timed(c, runner, &command, try c.fmt("{s}/compile-{s}", .{ output, name }), env, .{ .timeout_ms = 900_000 });
        if (result.code != 0) return error.BehaviorCompilationFailed;
        try runner.observe(exe, &.{}, try u.json.integer(try u.get(manifest, "exit_status")), try u.str(manifest, "stdout"), try c.fmt("{s}/run-{s}", .{ output, name }), env);
    }
    const invalid = try c.join(&.{ output, "invalid.zig" });
    try c.write(invalid, "pub fn main() void { @compileError(\"whole-compiler-negative-control\"); }\n");
    const result = try runner.run(&.{ candidate, "build-exe", invalid, "-fno-emit-bin", "--cache-dir", try c.join(&.{ output, "behavior-cache" }) }, try c.join(&.{ output, "invalid" }), env, .{});
    if (!result.completed or result.code != 1 or std.mem.indexOf(u8, try c.read(try c.join(&.{ output, "invalid.stderr" })), "whole-compiler-negative-control") == null) return error.MissingExpectedCompileError;
}

fn capture(c: *u.Context, root: []const u8, argv: []const []const u8) !u8 {
    if (argv.len == 0 or !u.contains(argv, "--emit=obj")) return error.UnexpectedHookInvocation;
    const directory = try c.newOutput(try c.fmt("{s}/{d}", .{ root, std.os.linux.getpid() }));
    const result = try backend(c, directory, c.env.get("ZLLVM_WHOLE_BACKEND") orelse return error.MissingBackend, argv[argv.len - 1], argv, &c.env, try std.fmt.parseInt(u32, c.env.get("ZLLVM_WHOLE_TIMEOUT_MS") orelse "3600000", 10), .child_only);
    // Only verified successful objects are delivered to Zig. Failed/partial
    // output remains in the evidence directory and never reaches the linker.
    if ((try u.get(result, "object_complete")).bool) {
        const file = try std.Io.Dir.cwd().openFile(c.io, try c.join(&.{ directory, "local.o" }), .{});
        defer file.close(c.io);
        var buffer: [65536]u8 = undefined;
        var input = file.readerStreaming(c.io, &buffer);
        var out_buffer: [65536]u8 = undefined;
        var writer = std.Io.File.stdout().writerStreaming(c.io, &out_buffer);
        _ = try input.interface.streamRemaining(&writer.interface);
        try writer.interface.flush();
        return 0;
    }
    try std.Io.File.stderr().writeStreamingAll(c.io, try c.fmt("whole-compiler backend failed stage={s}; retained {s}/report.json\n", .{ try u.str(result, "failure_stage"), directory }));
    return 1;
}

fn backend(c: *u.Context, directory: []const u8, compiler: []const u8, original: []const u8, original_argv: []const []const u8, env: *const std.process.Environ.Map, deadline: u32, group: u.process.Group) !u.Value {
    var report = u.object(c.a);
    try u.put(c.a, &report, "original_input", u.s(original));
    try u.put(c.a, &report, "original_argv", try u.strings(c.a, original_argv));
    try u.put(c.a, &report, "object_complete", u.b(false));
    try u.put(c.a, &report, "failure_stage", u.s("capture"));
    try c.writeJson(try c.join(&.{ directory, "invocation.json" }), report);
    const input = try c.join(&.{ directory, "input.ll" });
    try c.copy(original, input);
    try u.put(c.a, &report, "input", try fileIdentity(c, input));
    if (!std.mem.eql(u8, try c.digest(original), try u.str(try u.get(report, "input"), "sha256"))) return error.InputChangedDuringCapture;
    try u.put(c.a, &report, "text_scan", try scan(c, input));
    try c.writeJson(try c.join(&.{ directory, "invocation.json" }), report);
    const bytes = (try std.Io.Dir.cwd().statFile(c.io, input, .{})).size;
    const profile_path = try c.join(&.{ directory, "profile.json" });
    const owners_path = try c.join(&.{ directory, "owners.tsv" });
    const events_path = try c.join(&.{ directory, "profile.events.jsonl" });
    // Leave room for readFileAlloc's EOF probe at an exact byte boundary.
    var command: std.ArrayList([]const u8) = .empty;
    try command.appendSlice(c.a, &.{ compiler, "--emit=obj", "--generic-cfg-selector", "--codegen-reachable", "--report-all-codegen-failures", "--target=x86_64-unknown-linux-gnu", try c.fmt("--input-limit={d}", .{try std.math.add(u64, bytes, 1)}), try c.fmt("--profile={s}", .{profile_path}), try c.fmt("--selection-owner-output={s}", .{owners_path}) });
    if (env.get("ZLLVM_WHOLE_PROFILE_EVENTS") != null) try command.append(c.a, try c.fmt("--profile-events={s}", .{events_path}));
    try command.append(c.a, input);
    try c.writeJson(try c.join(&.{ directory, "effective-argv.json" }), command.items);
    if (env.get("ZLLVM_WHOLE_REUSE_ROOT")) |root| {
        const replay = retained.tryReplay(c, root, compiler, directory, command.items, report) catch |err| {
            try u.put(c.a, &report, "backend_executed", u.b(false));
            try u.put(c.a, &report, "failure_stage", u.s("retained-object-verification"));
            try u.put(c.a, &report, "reuse_error", u.s(@errorName(err)));
            try c.writeJson(try c.join(&.{ directory, "report.json" }), report);
            return report;
        };
        if (replay) |result| return result;
    }
    try u.put(c.a, &report, "backend_executed", u.b(true));
    var runner = Runner.init(c, directory);
    const result = try timed(c, &runner, command.items, try c.join(&.{ directory, "backend" }), env, .{ .timeout_ms = deadline, .stdout_file = try c.join(&.{ directory, "local.o" }), .group = group });
    try u.put(c.a, &report, "returncode", u.n(result.code));
    const time_path = try c.join(&.{ directory, "backend.time" });
    const time_text = if (u.exists(c.io, time_path)) try c.read(time_path) else "";
    const completed = result.completed and std.mem.indexOf(u8, time_text, "Command terminated by signal") == null;
    try u.put(c.a, &report, "process_completed", u.b(completed));
    try u.put(c.a, &report, "time_record", u.s(time_text));
    try u.put(c.a, &report, "commands", runner.commands);
    const diagnostic = try c.read(try c.join(&.{ directory, "backend.stderr" }));
    try u.put(c.a, &report, "diagnostic_tail", u.s(diagnostic[diagnostic.len -| 32768..]));
    const analysis = try reports.analyze(c.a, diagnostic);
    try u.put(c.a, &report, "selection", analysis);
    const profile: ?u.Value = if (u.exists(c.io, profile_path)) try c.load(profile_path) else null;
    try u.put(c.a, &report, "failure_stage", u.s(try reports.stage(profile, analysis, result.code, completed)));
    if (profile != null) try u.put(c.a, &report, "profile", u.s(profile_path));
    if (u.exists(c.io, events_path)) {
        try u.put(c.a, &report, "profile_events", try fileIdentity(c, events_path));
        const file = try std.Io.Dir.cwd().openFile(c.io, events_path, .{});
        defer file.close(c.io);
        const size = (try file.stat(c.io)).size;
        var tail: [65536]u8 = undefined;
        const offset = size -| tail.len;
        const count = try file.readPositionalAll(c.io, &tail, offset);
        try u.put(c.a, &report, "profile_progress", try reports.eventTail(c.a, tail[0..count], offset != 0));
    }
    if (result.code == 0 and completed) {
        try reports.validateSuccess(c.a, analysis, profile orelse return error.MissingProfile, try c.read(owners_path));
        const object_path = try c.join(&.{ directory, "local.o" });
        const contract = try elf.parse(c.a, try c.read(object_path));
        reports.validateObject(c.a, contract, profile.?) catch |err| {
            try u.put(c.a, &report, "failure_stage", u.s("object-contract"));
            try u.put(c.a, &report, "object_error", u.s(@errorName(err)));
            try c.writeJson(try c.join(&.{ directory, "report.json" }), report);
            return report;
        };
        try c.writeJson(try c.join(&.{ directory, "object-contract.json" }), contract);
        try u.put(c.a, &report, "object", try fileIdentity(c, object_path));
        try u.put(c.a, &report, "object_complete", u.b(true));
        try u.put(c.a, &report, "failure_stage", u.s("none"));
    }
    try c.writeJson(try c.join(&.{ directory, "report.json" }), report);
    return report;
}

fn runtimeObjectChecks(c: *u.Context, output: []const u8, invocation: u.Value, env: *const std.process.Environ.Map, runner: *Runner) !u.Value {
    const input = try u.get(invocation, "input");
    if (!std.mem.eql(u8, try u.str(input, "sha256"), "ca04995e5bc4d6537f6e1b994a79569ed8dc10d64451f89dfc0714fb40a732af")) return error.RuntimeChecksRequireOriginalRuntime;
    const directory = try c.newOutput(try c.join(&.{ output, "runtime-execution" }));
    const driver = try c.join(&.{"test/whole_compiler/runtime_completion_driver.c"});
    const reference = try c.join(&.{ directory, "reference.o" });
    try runner.require(&.{ "clang-22", "-O2", "-c", try u.str(input, "path"), "-o", reference }, try c.join(&.{ directory, "reference-object" }), env);
    const expected = "runtime-completion observations=1280 complex=conversion=sqrt=integer=preserved\n";
    var result = u.object(c.a);
    for ([_][]const u8{ "local", "reference" }) |route| {
        const object = if (std.mem.eql(u8, route, "local")) try u.str(try u.get(invocation, "object"), "path") else reference;
        const exe = try c.join(&.{ directory, route });
        try runner.require(&.{ "cc", "-O2", "-fno-builtin", "-no-pie", "-Wl,-z,noexecstack", driver, object, "-lm", "-o", exe }, try c.fmt("{s}-link", .{exe}), env);
        try runner.observe(exe, &.{}, 0, expected, try c.fmt("{s}-run", .{exe}), env);
        for (1..4) |fault| {
            const stem = try c.fmt("{s}-fault-{d}", .{ exe, fault });
            const observed = try runner.run(&.{ exe, try c.fmt("{d}", .{fault}) }, stem, env, .{ .timeout_ms = 5000 });
            const diagnostic = try c.read(try c.fmt("{s}.stderr", .{stem}));
            if (!observed.completed or observed.code != 1 or (try c.read(try c.fmt("{s}.stdout", .{stem}))).len != 0 or
                !std.mem.startsWith(u8, diagnostic, "runtime-completion line=") or std.mem.indexOf(u8, diagnostic, try c.fmt("fault={d}\n", .{fault})) == null)
                return error.RuntimeFaultControlDidNotFail;
        }
        try u.put(c.a, &result, route, try fileIdentity(c, exe));
    }
    try u.put(c.a, &result, "status", u.s("passed"));
    try u.put(c.a, &result, "driver", try fileIdentity(c, driver));
    try u.put(c.a, &result, "reference_object", try fileIdentity(c, reference));
    try u.put(c.a, &result, "local_observations", u.n(1280));
    try u.put(c.a, &result, "reference_observations", u.n(1280));
    try u.put(c.a, &result, "fault_controls", u.n(6));
    return result;
}

fn collect(c: *u.Context, root: []const u8) !u.Value {
    var dir = try std.Io.Dir.cwd().openDir(c.io, root, .{ .iterate = true });
    defer dir.close(c.io);
    var it = dir.iterate();
    var paths: std.ArrayList([]const u8) = .empty;
    while (try it.next(c.io)) |entry| if (entry.kind == .directory) {
        try paths.append(c.a, try c.join(&.{ root, entry.name }));
    };
    std.mem.sort([]const u8, paths.items, {}, struct {
        fn less(_: void, a: []const u8, b: []const u8) bool {
            return std.mem.lessThan(u8, a, b);
        }
    }.less);
    var result = u.array(c.a);
    for (paths.items) |path| {
        const final = try c.join(&.{ path, "report.json" });
        var invocation = try c.load(if (u.exists(c.io, final)) final else try c.join(&.{ path, "invocation.json" }));
        if (!u.exists(c.io, final)) try u.put(c.a, &invocation, "failure_stage", u.s("capture-or-process-interruption"));
        try u.put(c.a, &invocation, "directory", u.s(path));
        try u.add(&result, invocation);
    }
    return result;
}

// Textual counts are independent observations, never a semantic reachability
// census. Fixed-size streaming also handles giant constant/metadata lines.
fn scan(c: *u.Context, path: []const u8) !u.Value {
    const file = try std.Io.Dir.cwd().openFile(c.io, path, .{});
    defer file.close(c.io);
    var buffer: [65536]u8 = undefined;
    var reader = file.readerStreaming(c.io, &buffer);
    var prefix: [16]u8 = undefined;
    var n: usize = 0;
    var definitions: u64 = 0;
    var declarations: u64 = 0;
    var globals: u64 = 0;
    while (true) {
        const byte = reader.interface.takeByte() catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };
        if (byte == '\n') {
            n = 0;
            continue;
        }
        if (n == prefix.len) continue;
        prefix[n] = byte;
        n += 1;
        if (n == 1 and byte == '@') globals += 1;
        if (n == 7 and std.mem.eql(u8, prefix[0..n], "define ")) definitions += 1;
        if (n == 8 and std.mem.eql(u8, prefix[0..n], "declare ")) declarations += 1;
    }
    var result = u.object(c.a);
    try u.put(c.a, &result, "scope", u.s("line-prefix inventory; not parsed or proven reachable"));
    try u.put(c.a, &result, "definitions", u.n(definitions));
    try u.put(c.a, &result, "declarations", u.n(declarations));
    try u.put(c.a, &result, "global_or_alias_lines", u.n(globals));
    return result;
}

fn freeSpace(io: std.Io, path: []const u8) !u64 {
    const a = std.heap.page_allocator;
    const result = try u.process.runReport(a, io, .{ .spawn = .{ .argv = &.{ "/bin/df", "-B1", "--output=avail", path } }, .timeout_ms = 5000, .stdout_limit = 1024, .stderr_limit = 1024 });
    defer result.deinit(a);
    if (!result.success()) return error.DiskSampleFailed;
    var fields = std.mem.tokenizeAny(u8, result.stdout, " \r\n\t");
    _ = fields.next() orelse return error.DiskSampleFailed;
    const value = try std.fmt.parseInt(u64, fields.next() orelse return error.DiskSampleFailed, 10);
    if (fields.next() != null) return error.DiskSampleFailed;
    return value;
}

const Watch = struct {
    io: std.Io,
    path: []const u8,
    start: u64,
    minimum: u64,
    log: std.Io.File,
    stop: std.atomic.Value(bool) = .init(false),
    violation: bool = false,
    failed: bool = false,
    fn run(w: *Watch) void {
        while (!w.stop.load(.acquire)) {
            const value = freeSpace(w.io, w.path) catch {
                w.failed = true;
                @constCast(u.cancellation()).request();
                return;
            };
            w.minimum = @min(w.minimum, value);
            var buffer: [120]u8 = undefined;
            const line = std.fmt.bufPrint(&buffer, "{d}\t{d}\n", .{ std.Io.Timestamp.now(w.io, .real).nanoseconds, value }) catch unreachable;
            w.log.writeStreamingAll(w.io, line) catch {
                w.failed = true;
                @constCast(u.cancellation()).request();
                return;
            };
            if (value < policy.serial_reserve_floor_bytes) {
                w.violation = true;
                @constCast(u.cancellation()).request();
                return;
            }
            std.Io.sleep(w.io, .fromSeconds(2), .awake) catch return;
        }
    }
};
