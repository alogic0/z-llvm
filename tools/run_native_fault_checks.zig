//! Check retained native executables without recompiling them.
//! --input-manifest JSON: {"fault_count":5,"runs":[{"root":"...",
//! "population":"...","build":"Debug","modes":["ReleaseFast",...]}]}.
//! Omitted modes means all three release pipelines. Every input report must pass.
const std = @import("std");
const u = @import("validation/common.zig");
const canaries = @import("validation/native_canaries.zig");
const faults = @import("validation/native_faults.zig");
const Runner = @import("validation/runner.zig").Runner;

fn execute(c: *u.Context, args: u.Args, runner: *Runner, report: *u.Value) !void {
    const manifest_path = try c.join(&.{try args.require("input-manifest")});
    const manifest = try c.load(manifest_path);
    const count = try u.json.integer(try u.get(manifest, "fault_count"));
    if (count < 1 or count > 1000) return error.InvalidFaultCount;
    try u.put(c.a, report, "input_manifest_sha256", u.s(try c.digest(manifest_path)));
    try u.put(c.a, report, "registry_sha256", u.s(try c.digest(try c.join(&.{"test/real_programs/native_canaries.json"}))));
    try u.put(c.a, report, "inputs", u.array(c.a));
    const registry = try canaries.load(c);
    var seen = std.StringHashMap(void).init(c.a);
    const runs = try u.json.array(try u.get(manifest, "runs"));
    if (runs.len == 0) return error.EmptyNativeFaultRuns;
    for (runs) |run| {
        const population = try u.str(run, "population");
        const build = try u.str(run, "build");
        // Build labels enter filenames. Population and mode names are registry checked.
        if (build.len == 0) return error.InvalidBuildLabel;
        for (build) |ch| if (!std.ascii.isAlphanumeric(ch) and ch != '-' and ch != '_') return error.InvalidBuildLabel;
        const entry = for (registry) |canary| {
            if (std.mem.eql(u8, try u.str(canary, "population"), population)) break canary;
        } else return error.UnknownNativePopulation;
        const input = try c.join(&.{try u.str(run, "root")});
        const input_report_path = try c.join(&.{ input, "report.json" });
        const input_report = try c.load(input_report_path);
        if (!u.json.is(try u.get(input_report, "status"), "passed")) return error.NativeInputFailed;
        if (input_report.object.get("population")) |value| if (!u.json.is(value, population)) return error.NativeInputPopulationDiffers;
        const modes = if (run.object.get("modes")) |value| try u.stringSlice(c.a, value) else &u.modes;
        if (modes.len == 0) return error.EmptyNativeFaultModes;
        for (modes) |mode| {
            const key = try c.fmt("{s}/{s}/{s}", .{ build, population, mode });
            if ((try seen.getOrPut(key)).found_existing) return error.DuplicateNativeFaultRun;
        }
        try u.add(report.object.getPtr("inputs").?, try u.toValue(c.a, .{ .root = input, .report_sha256 = try c.digest(input_report_path) }));
        try faults.run(runner, input, modes, entry, build, @intCast(count), report);
    }
    if (args.get("compare-with")) |path| {
        const prior = try c.join(&.{path});
        try faults.compare(c, try c.load(prior), report.*, args.get("legacy-population"));
        try u.put(c.a, report, "equivalent_to", u.s(prior));
        try u.put(c.a, report, "prior_report_sha256", u.s(try c.digest(prior)));
    }
}
pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const lease = try @import("validation/storage_workspace.zig").reader(&c);
    defer if (lease) |file| {
        file.unlock(c.io);
        file.close(c.io);
    };
    u.installSignals();
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "input-manifest", "output-root", "compare-with", "legacy-population" }, &.{});
    const output = try c.newOutput(try args.require("output-root"));
    var runner = Runner.init(&c, output);
    var report = u.object(c.a);
    try u.put(c.a, &report, "schema", u.s("native-fault-checks-v1"));
    try u.put(c.a, &report, "controls", u.n(0));
    var passed = true;
    execute(&c, args, &runner, &report) catch |err| {
        passed = false;
        try u.put(c.a, &report, "error", u.s(c.diagnostic orelse @errorName(err)));
    };
    try u.put(c.a, &report, "status", u.s(if (passed) "passed" else "failed"));
    try c.writeJson(try c.join(&.{ output, "report.json" }), report);
    try c.print("native fault checks: {s}; evidence: {s}/report.json\n", .{ if (passed) "passed" else "failed", output });
    if (!passed) std.process.exit(1);
}
