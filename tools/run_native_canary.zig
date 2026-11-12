//! Run one registered native population through the same differential procedure
//! used by full integration, without exporting an unrelated upstream program.
const std = @import("std");
const u = @import("validation/common.zig");
const canaries = @import("validation/native_canaries.zig");
const Runner = @import("validation/runner.zig").Runner;
const faults = @import("validation/native_faults.zig");

pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    u.installSignals();
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "population", "zllvm", "mode", "fault-count" }, &.{});
    const fault_count = if (args.get("fault-count")) |text| try std.fmt.parseInt(u16, text, 10) else 0;
    if (args.get("fault-count") != null and (fault_count == 0 or fault_count > 1000)) return error.InvalidFaultCount;
    const population = try args.require("population");
    const registry = try canaries.load(&c);
    const canary = for (registry) |entry| {
        if (std.mem.eql(u8, try u.str(entry, "population"), population)) break entry;
    } else return error.UnknownNativePopulation;
    const modes: []const []const u8 = if (args.get("mode")) |mode| &.{mode} else &u.modes;
    for (modes) |mode| if (!u.contains(&u.modes, mode)) return error.InvalidMode;
    const output = try c.newOutput(try args.require("output-root"));
    var runner = Runner.init(&c, output);
    const compiler = try c.join(&.{args.get("zllvm") orelse "zig-out/bin/z_llvm"});
    var report = u.object(c.a);
    try u.put(c.a, &report, "schema", u.s("native-canary-v1"));
    try u.put(c.a, &report, "population", u.s(population));
    try u.put(c.a, &report, "compiler_sha256", u.s(try c.digest(compiler)));
    try u.put(c.a, &report, "compiler", u.s(compiler));
    try u.put(c.a, &report, "compiler_build", try @import("validation/toolchain.zig").compilerBuild(&c, compiler));
    try u.put(c.a, &report, "registry_sha256", u.s(try c.digest(try c.join(&.{"test/real_programs/native_canaries.json"}))));
    for ([_][]const u8{ ".ll", "_driver.c" }) |suffix| {
        const path = try c.join(&.{ "test/real_programs", try c.fmt("{s}{s}", .{ try u.str(canary, "fixture"), suffix }) });
        try u.put(c.a, &report, suffix, u.s(try c.digest(path)));
    }
    if (canary.object.get("reference_fixture")) |value| {
        const path = try c.join(&.{ "test/real_programs", try c.fmt("{s}.ll", .{value.string}) });
        try u.put(c.a, &report, "reference_fixture", try u.toValue(c.a, .{ .path = path, .sha256 = try c.digest(path) }));
        if (canary.object.get("reference_source")) |source| {
            const source_path = try c.join(&.{ "test/real_programs", source.string });
            try u.put(c.a, &report, "reference_source", try u.toValue(c.a, .{ .path = source_path, .sha256 = try c.digest(source_path) }));
        }
        try u.put(c.a, &report, "reference_scope", u.s("Explicit independent oracle fixture; original candidate IR is used unchanged for both local routes"));
    }
    if (canary.object.get("provider_fixture")) |provider| {
        const path = try c.join(&.{ "test/real_programs", try c.fmt("{s}.ll", .{provider.string}) });
        try u.put(c.a, &report, "provider_fixture", try u.toValue(c.a, .{ .path = path, .sha256 = try c.digest(path) }));
    }
    var passed = true;
    for (modes) |mode| {
        const directory = try c.newOutput(try c.join(&.{ output, mode }));
        canaries.run(&runner, directory, compiler, &c.env, mode, &report, canary) catch |err| {
            passed = false;
            try u.put(c.a, &report, "error", u.s(c.diagnostic orelse @errorName(err)));
            break;
        };
    }
    if (passed and fault_count != 0) {
        const directory = try c.newOutput(try c.join(&.{ output, "fault-checks" }));
        var fault_runner = Runner.init(&c, directory);
        var fault_report = u.object(c.a);
        faults.run(&fault_runner, output, modes, canary, "selected", fault_count, &fault_report) catch |err| {
            passed = false;
            try u.put(c.a, &fault_report, "error", u.s(c.diagnostic orelse @errorName(err)));
        };
        try u.put(c.a, &fault_report, "status", u.s(if (passed) "passed" else "failed"));
        try c.writeJson(try c.join(&.{ directory, "report.json" }), fault_report);
        try u.put(c.a, &report, "fault_checks", fault_report);
    }
    try u.put(c.a, &report, "status", u.s(if (passed) "passed" else "failed"));
    try c.writeJson(try c.join(&.{ output, "report.json" }), report);
    try c.print("native-canary {s}: {s}; evidence: {s}/report.json\n", .{ population, if (passed) "passed" else "failed", output });
    if (!passed) std.process.exit(1);
}
