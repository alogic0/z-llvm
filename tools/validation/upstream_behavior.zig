const std = @import("std");
const u = @import("common.zig");
const Runner = @import("runner.zig").Runner;
const storage = @import("storage_workspace.zig");
const preopt = @import("preopt_capture.zig");
const headroom = @import("behavior_headroom.zig");
const reference_binding = @import("upstream_reference.zig");

fn outcomeStatus(text: []const u8) ?[]const u8 {
    if (std.mem.eql(u8, text, "OK") or std.mem.eql(u8, text, "SKIP")) return text;
    if (std.mem.startsWith(u8, text, "FAIL (") and std.mem.endsWith(u8, text, ")")) return "FAIL";
    return null;
}
fn appendOutcome(a: std.mem.Allocator, rows: *u.Value, names: *std.StringHashMap(void), name: []const u8, status: []const u8) !void {
    if ((try names.getOrPut(name)).found_existing) return error.DuplicateTestIdentity;
    var row = u.object(a);
    try u.put(a, &row, "name", u.s(name));
    try u.put(a, &row, "outcome", u.s(status));
    try u.add(rows, row);
}
pub fn outcomes(a: std.mem.Allocator, bytes: []const u8) !u.Value {
    var rows = u.array(a);
    var total: ?usize = null;
    var names = std.StringHashMap(void).init(a);
    defer names.deinit();
    var pending: ?[]const u8 = null;
    var lines = std.mem.splitScalar(u8, bytes, '\n');
    while (lines.next()) |line| {
        if (pending) |name| if (outcomeStatus(line)) |status| {
            try appendOutcome(a, &rows, &names, name, status);
            pending = null;
            continue;
        };
        const slash = std.mem.indexOfScalar(u8, line, '/') orelse continue;
        const space = std.mem.indexOfScalarPos(u8, line, slash, ' ') orelse continue;
        const index = std.fmt.parseInt(usize, line[0..slash], 10) catch continue;
        const count = std.fmt.parseInt(usize, line[slash + 1 .. space], 10) catch continue;
        const dots = std.mem.lastIndexOf(u8, line, "...") orelse return error.IncompleteTestOutcome;
        if (pending != null) return error.IncompleteTestOutcome;
        if (dots <= space + 1 or index != rows.array.items.len + 1 or count == 0 or index > count) return error.InvalidTestSequence;
        if (total) |t| {
            if (count != t) return error.InvalidTestSequence;
        } else total = count;
        const name = line[space + 1 .. dots];
        const suffix = line[dots + 3 ..];
        if (outcomeStatus(suffix)) |status| try appendOutcome(a, &rows, &names, name, status) else {
            // Zig prints expectation diagnostics after the test prefix and
            // puts its final FAIL record on a subsequent line.
            pending = name;
        }
    }
    if (pending != null) return error.IncompleteTestOutcome;
    if (total == null or rows.array.items.len != total.?) return error.IncompleteTestRun;
    return rows;
}

fn identity(c: *u.Context, path: []const u8) !u.Value {
    var result = u.object(c.a);
    try u.put(c.a, &result, "path", u.s(path));
    try u.put(c.a, &result, "sha256", u.s(try c.digest(path)));
    return result;
}

pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    u.installSignals();
    const argv = try init.minimal.args.toSlice(c.a);
    if (argv.len == 2 and std.mem.eql(u8, argv[1], "--help")) return c.print("usage: run_upstream_behavior --output-root DIR --compiler EXE --zig-source DIR --libc-file FILE --mode Debug|ReleaseSafe|ReleaseFast|ReleaseSmall --route llvm|local [--zllvm EXE] [--local-pipeline postopt|preopt] [--reference-report FILE] [--reference-sha256 SHA256] [--record-providers] [--reserve-bytes N] [--resources normal|accepted] [--test-filter TEXT] [--profile-events] [--retain-products]\n", .{});
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "compiler", "zig-source", "libc-file", "mode", "route", "zllvm", "reference-report", "reference-sha256", "local-pipeline", "reserve-bytes", "resources", "test-filter" }, &.{ "profile-events", "record-providers", "retain-products" });
    const mode = try args.require("mode");
    const route = try args.require("route");
    const resources = args.get("resources") orelse "normal";
    const pipeline = args.get("local-pipeline") orelse "postopt";
    if (!u.contains(&.{ "postopt", "preopt" }, pipeline)) return error.InvalidLocalPipeline;
    const is_preopt = std.mem.eql(u8, pipeline, "preopt");
    if (!u.contains(&.{ "Debug", "ReleaseSafe", "ReleaseFast", "ReleaseSmall" }, mode)) return error.InvalidMode;
    if (!u.contains(&.{ "llvm", "local" }, route)) return error.InvalidRoute;
    if (!u.contains(&.{ "normal", "accepted" }, resources)) return error.InvalidResources;
    if (std.mem.eql(u8, route, "local") and args.get("zllvm") == null) return error.MissingBackend;
    if (args.flag("profile-events") and !std.mem.eql(u8, route, "local")) return error.ProfileEventsRequireLocalRoute;
    if (is_preopt) {
        if (!std.mem.eql(u8, route, "local")) return error.PreoptRequiresLocalRoute;
        _ = try preopt.passes(mode);
        if (args.get("reference-report") == null or args.get("reference-sha256") == null) return error.PreoptRequiresBoundReference;
    }
    if (args.get("reference-sha256") != null and args.get("reference-report") == null) return error.ReferenceHashRequiresReport;
    const requested_output = try c.ownedPath(try args.require("output-root"));
    if (args.flag("retain-products") and try @import("storage_lifecycle.zig").outputRoot(&c, requested_output) == null) return error.PipelineRequiresManagedStorage;
    const output = try c.newOutput(requested_output);
    const workspace = if (args.flag("retain-products")) try storage.startPipeline(&c, output, "validation") else try storage.start(&c, output, "validation");
    defer if (workspace) |w| w.close(&c);
    var report = u.object(c.a);
    try u.put(c.a, &report, "schema", u.s("upstream-behavior-v1"));
    try u.put(c.a, &report, "status", u.s("incomplete"));
    try u.put(c.a, &report, "mode", u.s(mode));
    try u.put(c.a, &report, "route", u.s(route));
    try u.put(c.a, &report, "local_pipeline", u.s(pipeline));
    try u.put(c.a, &report, "resources", u.s(resources));
    try u.put(c.a, &report, "full_suite", u.b(args.get("test-filter") == null));
    try u.put(c.a, &report, "profile_events_requested", u.b(args.flag("profile-events")));
    if (is_preopt) {
        try u.put(c.a, &report, "inventory_status", u.s("provisional-until-independent-audits"));
        try u.put(c.a, &report, "stage_chains_complete", u.b(false));
        try u.put(c.a, &report, "compiler_rt_frontend_mode", u.s(if (std.mem.eql(u8, mode, "ReleaseSmall")) "ReleaseSmall" else "ReleaseFast"));
        try u.put(c.a, &report, "hook_mode", u.s(mode));
        try u.put(c.a, &report, "hook_passes", u.s(try preopt.passes(mode)));
    }
    var runner = Runner.init(&c, output);
    const monitor = if (is_preopt or args.get("reserve-bytes") != null) headroom.Guard.start(&c, output, args.get("reserve-bytes")) catch |err| failed: {
        try u.put(c.a, &report, "status", u.s("failed"));
        try u.put(c.a, &report, "failure_stage", u.s("disk-admission"));
        try u.put(c.a, &report, "resource_stop", u.b(true));
        try u.put(c.a, &report, "error", u.s(@errorName(err)));
        break :failed @as(?headroom.Guard, null);
    } else @as(?headroom.Guard, null);
    if (!report.object.contains("error")) execute(&c, args, output, &runner, &report) catch |err| {
        try u.put(c.a, &report, "status", u.s("failed"));
        try u.put(c.a, &report, "error", u.s(c.diagnostic orelse @errorName(err)));
    };
    if (monitor) |guard| guard.finish(&c, output) catch |err| {
        try u.put(c.a, &report, "status", u.s("failed"));
        try u.put(c.a, &report, "failure_stage", u.s("disk-monitoring"));
        try u.put(c.a, &report, "resource_stop", u.b(true));
        try u.put(c.a, &report, "error", u.s(@errorName(err)));
    };
    try u.put(c.a, &report, "commands", runner.commands);
    try c.writeJson(try c.join(&.{ output, "report.json" }), report);
    if (workspace) |w| try w.finishReport(&c);
    try c.print("upstream behavior status={s} report={s}/report.json\n", .{ try u.str(report, "status"), output });
    if (report.object.get("error")) |err| try std.Io.File.stderr().writeStreamingAll(c.io, try c.fmt("{s}\n", .{err.string}));
    std.process.exit(if (u.json.is(try u.get(report, "status"), "passed")) 0 else 1);
}

fn execute(c: *u.Context, args: u.Args, output: []const u8, runner: *Runner, report: *u.Value) !void {
    const compiler = try c.join(&.{try args.require("compiler")});
    const source = try c.join(&.{try args.require("zig-source")});
    const libc = try c.join(&.{try args.require("libc-file")});
    const input = try c.join(&.{ source, "test/behavior.zig" });
    const local = std.mem.eql(u8, try args.require("route"), "local");
    const accepted = std.mem.eql(u8, args.get("resources") orelse "normal", "accepted");
    const pipeline = args.get("local-pipeline") orelse "postopt";
    const is_preopt = std.mem.eql(u8, pipeline, "preopt");
    const compiler_before = try identity(c, compiler);
    try u.put(c.a, report, "compiler", compiler_before);
    try u.put(c.a, report, "runner", try identity(c, "/proc/self/exe"));
    try u.put(c.a, report, "suite", try identity(c, input));
    try u.put(c.a, report, "libc", try identity(c, libc));
    const pin = u.trim(try c.capture(&.{ "git", "-C", source, "rev-parse", "HEAD" }));
    if (!std.mem.eql(u8, pin, "1c08b09d1c847f4f02c8216e3b62df323861a437")) return error.UpstreamPinMismatch;
    _ = try c.capture(&.{ "git", "-C", source, "diff", "--exit-code", "HEAD", "--" });
    try u.put(c.a, report, "source_pin", u.s(pin));
    const record_providers = args.flag("record-providers") or (is_preopt and args.get("test-filter") == null);
    if (record_providers) try u.put(c.a, report, "native_libc_inputs", try @import("native_libc.zig").identities(c, libc));
    var reference: ?u.Value = null;
    var reference_identity: ?u.Value = null;
    if (args.get("reference-report")) |path| {
        const resolved = try c.join(&.{path});
        reference_identity = try identity(c, resolved);
        if (args.get("reference-sha256")) |expected| {
            if (!u.json.is(try u.get(reference_identity.?, "sha256"), expected)) return error.ReferenceIdentityChanged;
        }
        reference = try c.load(resolved);
        if (is_preopt) try reference_binding.validate(reference.?, report.*, source, c.a);
        try u.put(c.a, report, "reference", reference_identity.?);
    }
    try u.put(c.a, report, "inherited_limits", u.s(try c.read("/proc/self/limits")));
    try u.put(c.a, report, "inherited_affinity", u.s(try c.capture(&.{ "/usr/bin/taskset", "-pc", try c.fmt("{d}", .{std.os.linux.getpid()}) })));
    var env = std.process.Environ.Map.init(c.a);
    for ([_][2][]const u8{
        .{ "PATH", "/home/oleg/bin:/usr/lib/llvm-22/bin:/usr/bin:/bin" }, .{ "LC_ALL", "C" },    .{ "TZ", "UTC0" },
        .{ "ZLLVM_PROJECT_ROOT", c.root },                                .{ "ZIG_LIBC", libc }, .{ "HOME", try c.temporaryPath(&.{ output, "home" }) },
        .{ "TMPDIR", try c.temporaryPath(&.{ output, "temp" }) },
    }) |pair| try env.put(pair[0], pair[1]);
    for ([_][]const u8{ "home", "temp", "local-cache", "global-cache" }) |name| try c.mkdir(try c.temporaryPath(&.{ output, name }));
    try c.mkdir(try c.join(&.{ output, "captures" }));
    try storage.exportPaths(c, &env);
    if (local) {
        const backend = try c.join(&.{try args.require("zllvm")});
        try u.put(c.a, report, "backend", try identity(c, backend));
        if (is_preopt) {
            try env.put("ZLLVM_ZIG_MODE", try args.require("mode"));
            try u.put(c.a, report, "project_revision", u.s(u.trim(try c.capture(&.{ "git", "-C", c.root, "rev-parse", "HEAD" }))));
            try u.put(c.a, report, "backend_build", try @import("toolchain.zig").compilerBuild(c, backend));
        }
        if (args.flag("profile-events")) try env.put("ZLLVM_WHOLE_PROFILE_EVENTS", "1");
        for ([_][2][]const u8{
            .{ "ZIG_USE_ZLLVM_OBJECT", "1" },                                                      .{ "ZLLVM_PIPELINE", pipeline },
            .{ "ZLLVM_EXE", try std.Io.Dir.cwd().realPathFileAlloc(c.io, "/proc/self/exe", c.a) }, .{ "ZLLVM_WHOLE_BACKEND", backend },
            .{ "ZLLVM_WHOLE_CAPTURE_ROOT", try c.join(&.{ output, "captures" }) },                 .{ "ZLLVM_MARKER_PATH", try c.join(&.{ output, "hook.marker" }) },
            .{ "ZLLVM_WHOLE_TIMEOUT_MS", "7200000" },
        }) |pair| try env.put(pair[0], pair[1]);
    }
    var command: std.ArrayList([]const u8) = .empty;
    if (accepted) try command.appendSlice(c.a, &.{ "/usr/bin/prlimit", "--stack=1073741824:1073741824", "--", "/usr/bin/taskset", "--cpu-list", "0" });
    const executable = try c.temporaryPath(&.{ output, "behavior" });
    try command.appendSlice(c.a, &.{ compiler, "test", input, try c.fmt("-O{s}", .{try args.require("mode")}), "-target", "x86_64-linux-gnu", "-mcpu=baseline", "-fllvm", "-lc", "--zig-lib-dir", try c.join(&.{ source, "lib" }), "--libc", libc, "--cache-dir", try c.temporaryPath(&.{ output, "local-cache" }), "--global-cache-dir", try c.temporaryPath(&.{ output, "global-cache" }), "--test-no-exec", try c.fmt("-femit-bin={s}", .{executable}) });
    if (args.get("test-filter")) |filter| try command.appendSlice(c.a, &.{ "--test-filter", filter });
    try c.writeJson(try c.join(&.{ output, "report.json" }), report.*);
    const compiled = try runner.run(command.items, try c.join(&.{ output, "compile" }), &env, .{ .timeout_ms = 7200000 });
    if (local) {
        const all_captures = try @import("whole_compiler.zig").collect(c, try c.join(&.{ output, "captures" }));
        const captures = try preopt.split(c.a, all_captures, is_preopt);
        try u.put(c.a, report, "captures", captures.objects);
        if (is_preopt) try u.put(c.a, report, "optimizations", captures.optimizations);
        if (compiled.code == 0) {
            if (captures.objects.array.items.len == 0 or !u.exists(c.io, try c.join(&.{ output, "hook.marker" }))) return error.MissingLocalCapture;
            for (captures.objects.array.items) |capture| {
                if (!(try u.get(capture, "object_complete")).bool) return error.IncompleteLocalObject;
                if (is_preopt) try preopt.audit(c, output, report.*, capture);
                if (args.flag("profile-events")) {
                    const events = capture.object.get("profile_events") orelse return error.MissingLocalProfileEvents;
                    const path = try u.str(events, "path");
                    if ((try u.get(events, "bytes")).integer <= 0 or
                        !std.mem.eql(u8, try c.digest(path), try u.str(events, "sha256"))) return error.LocalProfileEventsChanged;
                }
            }
            if (is_preopt) {
                try preopt.reconcile(c.a, captures);
                try u.put(c.a, report, "stage_chains_complete", u.b(true));
            }
        }
    }
    if (compiled.code != 0 or !compiled.completed) return error.BehaviorCompileFailed;
    try u.put(c.a, report, "executable", try identity(c, executable));
    const observed = try runner.run(&.{executable}, try c.join(&.{ output, "execute" }), &env, .{ .timeout_ms = 300000 });
    const rows = try outcomes(c.a, try c.read(try c.join(&.{ output, "execute.stderr" })));
    try u.put(c.a, report, "outcomes", rows);
    try u.put(c.a, report, "tests", u.n(rows.array.items.len));
    if (observed.code != 0 or !observed.completed) return error.BehaviorExecutionFailed;
    for (rows.array.items) |row| if (u.json.is(try u.get(row, "outcome"), "FAIL")) return error.FailedTest;
    if (reference) |selected| {
        if (!u.json.is(try u.get(selected, "status"), "passed") or !u.json.eql(try u.get(selected, "mode"), try u.get(report.*, "mode")) or !u.json.eql(try u.get(selected, "full_suite"), try u.get(report.*, "full_suite"))) return error.InvalidReference;
        if (!u.json.eql(rows, try u.get(selected, "outcomes"))) return error.ReferenceOutcomesDiffer;
        if (!u.json.eql(reference_identity.?, try identity(c, try u.str(reference_identity.?, "path")))) return error.ReferenceIdentityChanged;
        try u.put(c.a, report, "reference_outcomes_match", u.b(true));
    }
    if (!u.json.eql(compiler_before, try identity(c, compiler))) return error.CompilerChanged;
    if (record_providers and !u.json.eql(try u.get(report.*, "native_libc_inputs"), try @import("native_libc.zig").identities(c, libc))) return error.LibcProviderChangedDuringRun;
    if (local and !u.json.eql(try u.get(report.*, "backend"), try identity(c, try c.join(&.{try args.require("zllvm")})))) return error.BackendChanged;
    _ = try c.capture(&.{ "git", "-C", source, "diff", "--exit-code", "HEAD", "--" });
    try u.put(c.a, report, "status", u.s("passed"));
}

test "upstream outcomes retain complete identities and explicit skips" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const rows = try outcomes(arena.allocator(), "1/2 first...test...OK\n2/2 second...SKIP\n1 passed; 1 skipped; 0 failed.\n");
    try std.testing.expectEqual(@as(usize, 2), rows.array.items.len);
    try std.testing.expectEqualStrings("first...test", try u.str(rows.array.items[0], "name"));
    try std.testing.expectEqualStrings("SKIP", try u.str(rows.array.items[1], "outcome"));
}

test "preopt helper modules participate in focused qualification" {
    _ = preopt;
    _ = headroom;
    _ = reference_binding;
}

test "upstream outcomes reject truncation missing duplicates and reordered records" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    try std.testing.expectError(error.IncompleteTestRun, outcomes(a, "1/2 first...OK\n"));
    try std.testing.expectError(error.InvalidTestSequence, outcomes(a, "2/2 second...OK\n"));
    try std.testing.expectError(error.DuplicateTestIdentity, outcomes(a, "1/2 same...OK\n2/2 same...OK\n"));
    try std.testing.expectError(error.IncompleteTestOutcome, outcomes(a, "1/1 first..."));
    const failed = try outcomes(a, "1/1 first...FAIL (TestUnexpectedResult)\nstack trace\n");
    try std.testing.expectEqualStrings("FAIL", try u.str(failed.array.items[0], "outcome"));
}

test "upstream outcomes retain failures whose expectation diagnostics split the record" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const rows = try outcomes(a, "1/2 payload...expected 2141192192, found 2145386496\nFAIL (TestExpectedEqual)\nstack trace\n2/2 next...OK\n1 passed; 0 skipped; 1 failed.\n");
    try std.testing.expectEqual(@as(usize, 2), rows.array.items.len);
    try std.testing.expectEqualStrings("payload", try u.str(rows.array.items[0], "name"));
    try std.testing.expectEqualStrings("FAIL", try u.str(rows.array.items[0], "outcome"));
    try std.testing.expectError(error.IncompleteTestOutcome, outcomes(a, "1/1 crashed...thread panic\n(empty stack trace)\n"));
    try std.testing.expectError(error.IncompleteTestOutcome, outcomes(a, "1/2 missing...diagnostic\n2/2 next...OK\n"));
}
