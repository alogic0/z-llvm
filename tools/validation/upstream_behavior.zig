const std = @import("std");
const u = @import("common.zig");
const Runner = @import("runner.zig").Runner;

pub fn outcomes(a: std.mem.Allocator, bytes: []const u8) !u.Value {
    var rows = u.array(a);
    var total: ?usize = null;
    var names = std.StringHashMap(void).init(a);
    defer names.deinit();
    var lines = std.mem.splitScalar(u8, bytes, '\n');
    while (lines.next()) |line| {
        const slash = std.mem.indexOfScalar(u8, line, '/') orelse continue;
        const space = std.mem.indexOfScalarPos(u8, line, slash, ' ') orelse continue;
        const index = std.fmt.parseInt(usize, line[0..slash], 10) catch continue;
        const count = std.fmt.parseInt(usize, line[slash + 1 .. space], 10) catch continue;
        const dots = std.mem.lastIndexOf(u8, line, "...") orelse return error.IncompleteTestOutcome;
        if (dots <= space + 1 or index != rows.array.items.len + 1 or count == 0 or index > count) return error.InvalidTestSequence;
        if (total) |t| {
            if (count != t) return error.InvalidTestSequence;
        } else total = count;
        const name = line[space + 1 .. dots];
        const suffix = line[dots + 3 ..];
        const status = if (std.mem.startsWith(u8, suffix, "FAIL (") and std.mem.endsWith(u8, suffix, ")")) "FAIL" else suffix;
        if (!u.contains(&.{ "OK", "SKIP", "FAIL" }, status)) return error.IncompleteTestOutcome;
        if ((try names.getOrPut(name)).found_existing) return error.DuplicateTestIdentity;
        var row = u.object(a);
        try u.put(a, &row, "name", u.s(name));
        try u.put(a, &row, "outcome", u.s(status));
        try u.add(&rows, row);
    }
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
    if (argv.len == 2 and std.mem.eql(u8, argv[1], "--help")) return c.print("usage: run_upstream_behavior --output-root DIR --compiler EXE --zig-source DIR --libc-file FILE --mode Debug|ReleaseSafe|ReleaseFast|ReleaseSmall --route llvm|local [--zllvm EXE] [--reference-report FILE] [--resources normal|accepted] [--test-filter TEXT]\n", .{});
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "compiler", "zig-source", "libc-file", "mode", "route", "zllvm", "reference-report", "resources", "test-filter" }, &.{});
    const mode = try args.require("mode");
    const route = try args.require("route");
    const resources = args.get("resources") orelse "normal";
    if (!u.contains(&.{ "Debug", "ReleaseSafe", "ReleaseFast", "ReleaseSmall" }, mode)) return error.InvalidMode;
    if (!u.contains(&.{ "llvm", "local" }, route)) return error.InvalidRoute;
    if (!u.contains(&.{ "normal", "accepted" }, resources)) return error.InvalidResources;
    if (std.mem.eql(u8, route, "local") and args.get("zllvm") == null) return error.MissingBackend;
    const output = try c.newOutput(try args.require("output-root"));
    var report = u.object(c.a);
    try u.put(c.a, &report, "schema", u.s("upstream-behavior-v1"));
    try u.put(c.a, &report, "status", u.s("incomplete"));
    try u.put(c.a, &report, "mode", u.s(mode));
    try u.put(c.a, &report, "route", u.s(route));
    try u.put(c.a, &report, "resources", u.s(resources));
    try u.put(c.a, &report, "full_suite", u.b(args.get("test-filter") == null));
    var runner = Runner.init(&c, output);
    execute(&c, args, output, &runner, &report) catch |err| {
        try u.put(c.a, &report, "error", u.s(c.diagnostic orelse @errorName(err)));
    };
    try u.put(c.a, &report, "commands", runner.commands);
    try c.writeJson(try c.join(&.{ output, "report.json" }), report);
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
    const compiler_before = try identity(c, compiler);
    try u.put(c.a, report, "compiler", compiler_before);
    try u.put(c.a, report, "runner", try identity(c, "/proc/self/exe"));
    try u.put(c.a, report, "suite", try identity(c, input));
    try u.put(c.a, report, "libc", try identity(c, libc));
    const pin = u.trim(try c.capture(&.{ "git", "-C", source, "rev-parse", "HEAD" }));
    if (!std.mem.eql(u8, pin, "1c08b09d1c847f4f02c8216e3b62df323861a437")) return error.UpstreamPinMismatch;
    _ = try c.capture(&.{ "git", "-C", source, "diff", "--exit-code", "HEAD", "--" });
    try u.put(c.a, report, "source_pin", u.s(pin));
    try u.put(c.a, report, "inherited_limits", u.s(try c.read("/proc/self/limits")));
    try u.put(c.a, report, "inherited_affinity", u.s(try c.capture(&.{ "/usr/bin/taskset", "-pc", try c.fmt("{d}", .{std.os.linux.getpid()}) })));
    var env = std.process.Environ.Map.init(c.a);
    for ([_][2][]const u8{
        .{ "PATH", "/home/oleg/bin:/usr/lib/llvm-22/bin:/usr/bin:/bin" }, .{ "LC_ALL", "C" },    .{ "TZ", "UTC0" },
        .{ "ZLLVM_PROJECT_ROOT", c.root },                                .{ "ZIG_LIBC", libc }, .{ "HOME", try c.join(&.{ output, "home" }) },
        .{ "TMPDIR", try c.join(&.{ output, "temp" }) },
    }) |pair| try env.put(pair[0], pair[1]);
    for ([_][]const u8{ "home", "temp", "local-cache", "global-cache", "captures" }) |name| try c.mkdir(try c.join(&.{ output, name }));
    if (local) {
        const backend = try c.join(&.{try args.require("zllvm")});
        try u.put(c.a, report, "backend", try identity(c, backend));
        for ([_][2][]const u8{
            .{ "ZIG_USE_ZLLVM_OBJECT", "1" },                                                      .{ "ZLLVM_PIPELINE", "postopt" },
            .{ "ZLLVM_EXE", try std.Io.Dir.cwd().realPathFileAlloc(c.io, "/proc/self/exe", c.a) }, .{ "ZLLVM_WHOLE_BACKEND", backend },
            .{ "ZLLVM_WHOLE_CAPTURE_ROOT", try c.join(&.{ output, "captures" }) },                 .{ "ZLLVM_MARKER_PATH", try c.join(&.{ output, "hook.marker" }) },
            .{ "ZLLVM_WHOLE_TIMEOUT_MS", "7200000" },
        }) |pair| try env.put(pair[0], pair[1]);
    }
    var command: std.ArrayList([]const u8) = .empty;
    if (accepted) try command.appendSlice(c.a, &.{ "/usr/bin/prlimit", "--stack=1073741824:1073741824", "--", "/usr/bin/taskset", "--cpu-list", "0" });
    const executable = try c.join(&.{ output, "behavior" });
    try command.appendSlice(c.a, &.{ compiler, "test", input, try c.fmt("-O{s}", .{try args.require("mode")}), "-target", "x86_64-linux-gnu", "-mcpu=baseline", "-fllvm", "-lc", "--zig-lib-dir", try c.join(&.{ source, "lib" }), "--libc", libc, "--cache-dir", try c.join(&.{ output, "local-cache" }), "--global-cache-dir", try c.join(&.{ output, "global-cache" }), "--test-no-exec", try c.fmt("-femit-bin={s}", .{executable}) });
    if (args.get("test-filter")) |filter| try command.appendSlice(c.a, &.{ "--test-filter", filter });
    try c.writeJson(try c.join(&.{ output, "report.json" }), report.*);
    const compiled = try runner.run(command.items, try c.join(&.{ output, "compile" }), &env, .{ .timeout_ms = 7200000 });
    if (local) {
        const captures = try @import("whole_compiler.zig").collect(c, try c.join(&.{ output, "captures" }));
        try u.put(c.a, report, "captures", captures);
        if (compiled.code == 0) {
            if (captures.array.items.len == 0 or !u.exists(c.io, try c.join(&.{ output, "hook.marker" }))) return error.MissingLocalCapture;
            for (captures.array.items) |capture| if (!(try u.get(capture, "object_complete")).bool) return error.IncompleteLocalObject;
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
    if (args.get("reference-report")) |path| {
        const reference = try c.load(try c.join(&.{path}));
        if (!u.json.is(try u.get(reference, "status"), "passed") or !u.json.eql(try u.get(reference, "mode"), try u.get(report.*, "mode")) or !u.json.eql(try u.get(reference, "full_suite"), try u.get(report.*, "full_suite"))) return error.InvalidReference;
        if (!u.json.eql(rows, try u.get(reference, "outcomes"))) return error.ReferenceOutcomesDiffer;
        try u.put(c.a, report, "reference", try identity(c, try c.join(&.{path})));
        try u.put(c.a, report, "reference_outcomes_match", u.b(true));
    }
    if (!u.json.eql(compiler_before, try identity(c, compiler))) return error.CompilerChanged;
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
