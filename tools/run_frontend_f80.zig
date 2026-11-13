//! Candidate frontend f80 layout and C ABI observations with retained inputs.
const std = @import("std");
const u = @import("validation/common.zig");
const Runner = @import("validation/runner.zig").Runner;
const storage = @import("validation/storage_workspace.zig");

fn identity(c: *u.Context, path: []const u8) !u.Value {
    return u.toValue(c.a, .{ .path = path, .sha256 = try c.digest(path) });
}

pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    u.installSignals();
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "compiler", "zig-source", "probe", "driver" }, &.{});
    const output = try c.newOutput(try args.require("output-root"));
    const workspace = try storage.start(&c, output, "validation");
    defer if (workspace) |w| w.close(&c);
    var report = try u.toValue(c.a, .{ .schema = "frontend-f80-v1", .status = "incomplete", .pipeline = "candidate normal -fllvm; independent C caller", .resources = "normal" });
    var runner = Runner.init(&c, output);
    execute(&c, args, output, &runner, &report) catch |err| {
        try u.put(c.a, &report, "error", u.s(c.diagnostic orelse @errorName(err)));
    };
    try u.put(c.a, &report, "commands", runner.commands);
    try c.writeJson(try c.join(&.{ output, "report.json" }), report);
    if (workspace) |w| try w.finishReport(&c);
    try c.print("frontend f80: {s}; {s}/report.json\n", .{ try u.str(report, "status"), output });
    if (!u.json.is(try u.get(report, "status"), "passed")) std.process.exit(1);
}

fn execute(c: *u.Context, args: u.Args, output: []const u8, runner: *Runner, report: *u.Value) !void {
    const compiler = try c.join(&.{try args.require("compiler")});
    const source = try c.join(&.{try args.require("zig-source")});
    const probe = try c.join(&.{try args.require("probe")});
    const driver = try c.join(&.{try args.require("driver")});
    const pin = u.trim(try c.capture(&.{ "git", "-C", source, "rev-parse", "HEAD" }));
    if (!std.mem.eql(u8, pin, "1c08b09d1c847f4f02c8216e3b62df323861a437")) return error.UpstreamPinMismatch;
    _ = try c.capture(&.{ "git", "-C", source, "diff", "--exit-code", "HEAD", "--" });
    const frontend_identity = try identity(c, compiler);
    const probe_identity = try identity(c, probe);
    const driver_identity = try identity(c, driver);
    try u.put(c.a, report, "compiler", frontend_identity);
    try u.put(c.a, report, "probe", probe_identity);
    try u.put(c.a, report, "driver", driver_identity);
    try u.put(c.a, report, "runner", try identity(c, "/proc/self/exe"));
    try u.put(c.a, report, "source_pin", u.s(pin));
    try u.put(c.a, report, "inherited_limits", u.s(try c.read("/proc/self/limits")));
    try u.put(c.a, report, "inherited_affinity", u.s(try c.capture(&.{ "/usr/bin/taskset", "-pc", try c.fmt("{d}", .{std.os.linux.getpid()}) })));
    const retained_probe = try c.join(&.{ output, "probe.zig" });
    const retained_driver = try c.join(&.{ output, "driver.c" });
    try c.copy(probe, retained_probe);
    try c.copy(driver, retained_driver);
    var env = try c.cleanEnvironment();
    for ([_][]const u8{ "home", "temp", "local-cache", "global-cache" }) |name| try c.mkdir(try c.temporaryPath(&.{ output, name }));
    try env.put("HOME", try c.temporaryPath(&.{ output, "home" }));
    try env.put("TMPDIR", try c.temporaryPath(&.{ output, "temp" }));
    try env.put("ZIG_LIB_DIR", try c.join(&.{ source, "lib" }));
    const object = try c.temporaryPath(&.{ output, "probe.o" });
    const llvm_ir = try c.join(&.{ output, "probe.ll" });
    const executable = try c.temporaryPath(&.{ output, "probe" });
    const compiled = try runner.run(&.{ compiler, "build-obj", "-OReleaseFast", "-target", "x86_64-linux-gnu", "-mcpu=baseline", "-fllvm", "--cache-dir", try c.temporaryPath(&.{ output, "local-cache" }), "--global-cache-dir", try c.temporaryPath(&.{ output, "global-cache" }), try c.fmt("-Mroot={s}", .{retained_probe}), try c.fmt("-femit-bin={s}", .{object}), try c.fmt("-femit-llvm-ir={s}", .{llvm_ir}) }, try c.join(&.{ output, "compile" }), &env, .{ .timeout_ms = 600000 });
    if (!compiled.completed or compiled.code != 0) return error.FrontendCompileFailed;
    try runner.require(&.{ "cc", "-O2", "-fno-builtin", "-no-pie", "-Wl,-z,noexecstack", retained_driver, object, "-o", executable }, try c.join(&.{ output, "link" }), &env);
    const executable_before = try identity(c, executable);
    try runner.observe(executable, &.{}, 0, "frontend-f80 observations=9 size=16 align=16 stride=16 fields=preserved\n", try c.join(&.{ output, "observe" }), &env);
    for ([_][2][]const u8{ .{ compiler, try u.str(frontend_identity, "sha256") }, .{ probe, try u.str(probe_identity, "sha256") }, .{ retained_probe, try u.str(probe_identity, "sha256") }, .{ driver, try u.str(driver_identity, "sha256") }, .{ retained_driver, try u.str(driver_identity, "sha256") } }) |pair| {
        if (!std.mem.eql(u8, try c.digest(pair[0]), pair[1])) return error.FrontendInputChanged;
    }
    if (!u.json.eql(executable_before, try identity(c, executable))) return error.ExecutableChanged;
    _ = try c.capture(&.{ "git", "-C", source, "diff", "--exit-code", "HEAD", "--" });
    try u.put(c.a, report, "object", try identity(c, object));
    try u.put(c.a, report, "llvm_ir", try identity(c, llvm_ir));
    try u.put(c.a, report, "executable", executable_before);
    try u.put(c.a, report, "compile_time_checks", try u.strings(c.a, &.{ "f80 size16", "f80 alignment16", "array stride16", "field offset16" }));
    try u.put(c.a, report, "native_observations", u.n(9));
    try u.put(c.a, report, "stores_unchanged", u.b(true));
    try u.put(c.a, report, "input_and_executable_hashes_verified", u.b(true));
    try u.put(c.a, report, "status", u.s("passed"));
}
