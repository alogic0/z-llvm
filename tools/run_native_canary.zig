//! Run one registered native population through the same differential procedure
//! used by full integration, without exporting an unrelated upstream program.
const std = @import("std");
const u = @import("validation/common.zig");
const canaries = @import("validation/native_canaries.zig");
const Runner = @import("validation/runner.zig").Runner;

pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    u.installSignals();
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "output-root", "population", "zllvm", "mode" }, &.{});
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
    try u.put(c.a, &report, "registry_sha256", u.s(try c.digest(try c.join(&.{"test/real_programs/native_canaries.json"}))));
    for ([_][]const u8{ ".ll", "_driver.c" }) |suffix| {
        const path = try c.join(&.{ "test/real_programs", try c.fmt("{s}{s}", .{ try u.str(canary, "fixture"), suffix }) });
        try u.put(c.a, &report, suffix, u.s(try c.digest(path)));
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
    try u.put(c.a, &report, "status", u.s(if (passed) "passed" else "failed"));
    try c.writeJson(try c.join(&.{ output, "report.json" }), report);
    try c.print("native-canary {s}: {s}; evidence: {s}/report.json\n", .{ population, if (passed) "passed" else "failed", output });
    if (!passed) std.process.exit(1);
}
