//! Calibrate native oracles using the driver's numbered injected failures.
const std = @import("std");
const u = @import("common.zig");
const Runner = @import("runner.zig").Runner;
pub const routes = [_][]const u8{ "reference", "direct", "release" };

pub fn detected(result: Runner.Result, stdout: []const u8, stderr: []const u8, marker: []const u8) bool {
    if (!result.completed or result.code != 1 or stdout.len != 0) return false;
    var tokens = std.mem.tokenizeAny(u8, stderr, " \t\r\n");
    while (tokens.next()) |token| if (std.mem.eql(u8, token, marker)) return true;
    return false;
}

pub fn run(runner: *Runner, input: []const u8, modes: []const []const u8, canary: u.Value, build: []const u8, count: u16, report: *u.Value) !void {
    const c = runner.context;
    if (count == 0 or count > 1000) return error.InvalidFaultCount;
    const population = try u.str(canary, "population");
    if (report.object.get("records") == null) try u.put(c.a, report, "records", u.array(c.a));
    for (modes) |mode| {
        if (!u.contains(&u.modes, mode)) return error.InvalidMode;
        for (routes) |route| {
            const exe = try @import("storage_workspace.zig").artifact(c, input, &.{ input, mode, try c.fmt("{s}-{s}", .{ try u.str(canary, "prefix"), route }) });
            const digest = try c.digest(exe);
            const stem = try c.join(&.{ runner.output, try c.fmt("{s}-{s}-{s}-{s}", .{ build, population, mode, route }) });
            // A pre-existing success report alone cannot rule out an always-failing oracle.
            try runner.observe(exe, &.{}, 0, try u.str(canary, "stdout"), try c.fmt("{s}-baseline", .{stem}), &c.env);
            for (1..@as(usize, count) + 1) |fault| {
                const fault_text = try c.fmt("{d}", .{fault});
                const fault_stem = try c.fmt("{s}-fault-{s}", .{ stem, fault_text });
                const result = try runner.run(&.{ exe, fault_text }, fault_stem, &c.env, .{ .timeout_ms = 20_000 });
                const stdout = try c.read(try c.fmt("{s}.stdout", .{fault_stem}));
                const stderr = try c.read(try c.fmt("{s}.stderr", .{fault_stem}));
                const passed = detected(result, stdout, stderr, try c.fmt("fault={s}", .{fault_text}));
                try u.add(report.object.getPtr("records").?, try u.toValue(c.a, .{
                    .build = build,
                    .population = population,
                    .mode = mode,
                    .route = route,
                    .fault = fault,
                    .returncode = result.code,
                    .stdout = stdout,
                    .stderr = stderr,
                    .completed = result.completed,
                    .executable_sha256 = digest,
                    .detected = passed,
                }));
                try u.increment(c.a, report, "controls", 1);
                try c.writeJson(try c.join(&.{ runner.output, "fault-progress.json" }), report.*);
                if (!passed) return c.fail("native oracle did not detect {s}: {s}", .{ fault_text, exe });
            }
            if (!std.mem.eql(u8, digest, try c.digest(exe))) return error.NativeExecutableChanged;
        }
    }
}

fn recordKey(c: *u.Context, record: u.Value, fallback_population: ?[]const u8) ![]const u8 {
    if (record != .object) return error.ExpectedFaultRecord;
    const build_text = if (record.object.get("build")) |value| try u.json.text(value) else try u.str(record, "compiler_build");
    const build = if (std.mem.eql(u8, build_text, "fast")) "ReleaseFast" else if (std.mem.eql(u8, build_text, "debug")) "Debug" else build_text;
    const population = if (record.object.get("population")) |value| try u.json.text(value) else fallback_population orelse return error.MissingFaultPopulation;
    return c.fmt("{s}/{s}/{s}/{s}/{d}", .{ build, population, try u.str(record, "mode"), try u.str(record, "route"), try u.json.integer(try u.get(record, "fault")) });
}

/// Compare legacy or current reports by semantic identity, not record ordering.
pub fn compare(c: *u.Context, prior: u.Value, current: u.Value, fallback_population: ?[]const u8) !void {
    if (!u.json.is(try u.get(prior, "status"), "passed")) return error.PriorFaultChecksFailed;
    const before = try u.json.array(try u.get(prior, "records"));
    const after = try u.json.array(try u.get(current, "records"));
    if (before.len != after.len or try u.json.integer(try u.get(prior, "controls")) != before.len or try u.json.integer(try u.get(current, "controls")) != after.len) return error.FaultControlCountDiffers;
    var indexed = std.StringHashMap(u.Value).init(c.a);
    for (before) |record| {
        const entry = try indexed.getOrPut(try recordKey(c, record, fallback_population));
        if (entry.found_existing) return error.DuplicateFaultControl;
        entry.value_ptr.* = record;
    }
    for (after) |record| {
        const entry = indexed.fetchRemove(try recordKey(c, record, fallback_population)) orelse return error.FaultControlIdentityDiffers;
        for ([_][]const u8{ "returncode", "stderr", "executable_sha256" }) |field| if (!u.json.eql(try u.get(entry.value, field), try u.get(record, field))) return c.fail("fault result differs: {s}: {s}", .{ entry.key, field });
        if (!u.json.is(try u.get(record, "stdout"), "") or (entry.value.object.get("stdout") != null and !u.json.is(try u.get(entry.value, "stdout"), ""))) return error.FaultStdoutDiffers;
        const detected_value = try u.get(record, "detected");
        if (detected_value != .bool or !detected_value.bool) return error.UndetectedFault;
    }
    if (indexed.count() != 0) return error.FaultControlIdentityDiffers;
}
