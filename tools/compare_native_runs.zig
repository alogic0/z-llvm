//! Compare native evidence roots; admit only explicitly named new populations.
//! --added-populations is a comma-separated list from the current registry.
//! Optional --baseline-registry FILE verifies exact retention of old entries.
const std = @import("std");
const u = @import("validation/common.zig");
const canaries = @import("validation/native_canaries.zig");
const comparison = @import("validation/native_comparison.zig");

fn execute(c: *u.Context, args: u.Args, report: *u.Value) !void {
    var additions = u.array(c.a);
    var requested = std.mem.splitScalar(u8, args.get("added-populations") orelse "", ',');
    const registry = try canaries.load(c);
    while (requested.next()) |population| {
        if (population.len == 0) continue;
        const canary = for (registry) |entry| {
            if (std.mem.eql(u8, try u.str(entry, "population"), population)) break entry;
        } else return error.UnknownNativePopulation;
        try u.add(&additions, canary);
    }
    const before = try c.join(&.{try args.require("baseline-root")});
    const after = try c.join(&.{try args.require("candidate-root")});
    try u.put(c.a, report, "baseline", u.s(before));
    try u.put(c.a, report, "candidate", u.s(after));
    try u.put(c.a, report, "allowed_additions", additions);
    for ([_][]const u8{ "report.json", "commands.json" }) |name| {
        try u.put(c.a, report, try c.fmt("baseline_{s}_sha256", .{name}), u.s(try c.digest(try c.join(&.{ before, name }))));
        try u.put(c.a, report, try c.fmt("candidate_{s}_sha256", .{name}), u.s(try c.digest(try c.join(&.{ after, name }))));
    }
    if (args.get("baseline-registry")) |path| {
        const prior = try c.join(&.{path});
        const current = try c.join(&.{"test/real_programs/native_canaries.json"});
        try u.put(c.a, report, "registry", try comparison.registry(c, try c.load(prior), try c.load(current), additions.array.items));
        try u.put(c.a, report, "baseline_registry_sha256", u.s(try c.digest(prior)));
        try u.put(c.a, report, "candidate_registry_sha256", u.s(try c.digest(current)));
    }
    try comparison.compare(c, before, after, additions.array.items, report);
}
pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    const args = try u.Args.parse(c.a, argv[1..], &.{ "baseline-root", "candidate-root", "output-root", "added-populations", "baseline-registry" }, &.{});
    const output = try c.newOutput(try args.require("output-root"));
    var report = u.object(c.a);
    try u.put(c.a, &report, "schema", u.s("native-run-comparison-v1"));
    var passed = true;
    execute(&c, args, &report) catch |err| {
        passed = false;
        try u.put(c.a, &report, "error", u.s(c.diagnostic orelse @errorName(err)));
        if (err == error.NativeArtifactsRequireReview) try u.put(c.a, &report, "requires_review", u.b(true));
    };
    try u.put(c.a, &report, "status", u.s(if (passed) "passed" else "failed"));
    try c.writeJson(try c.join(&.{ output, "report.json" }), report);
    try c.print("native comparison: {s}; evidence: {s}/report.json\n", .{ if (passed) "passed" else "failed", output });
    if (!passed) std.process.exit(1);
}
