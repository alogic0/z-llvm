//! Durable command capture and disk telemetry using an owned zig-process child.
const std = @import("std");
const u = @import("validation/common.zig");
const telemetry = @import("validation/telemetry.zig");
const storage = @import("validation/storage_lifecycle.zig");
const workspaces = @import("validation/storage_workspace.zig");
var storage_project: ?[]const u8 = null;

pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    u.installSignals();
    const args = try init.minimal.args.toSlice(c.a);
    const code = run(&c, args[1..]) catch |err| {
        try std.Io.File.stderr().writeStreamingAll(c.io, try c.fmt("run-checked: {s}\n", .{c.diagnostic orelse @errorName(err)}));
        std.process.exit(2);
    };
    const exit_code: u8 = @intCast(if (code < 0) 128 - code else code);
    if (storage_project) |root| storage.collect(&c, root, exit_code);
    std.process.exit(exit_code);
}

fn run(c: *u.Context, supplied: []const []const u8) !i64 {
    const retain_products = supplied.len != 0 and std.mem.eql(u8, supplied[0], "--retain-products");
    const args = if (retain_products) supplied[1..] else supplied;
    if (args.len == 1 and std.mem.eql(u8, args[0], "--help")) {
        try c.print("usage: zig run tools/run_checked.zig -- [--retain-products] --output-root DIR LABEL -- COMMAND [ARG...]\n", .{});
        return 0;
    }
    if (args.len < 5 or !std.mem.eql(u8, args[0], "--output-root") or !std.mem.eql(u8, args[3], "--")) return error.InvalidArguments;
    const output = try c.ownedPath(args[1]);
    const label = args[2];
    if (label.len == 0) return error.InvalidLabel;
    for (label) |ch| if (!std.ascii.isAlphanumeric(ch) and ch != '-' and ch != '_') return error.InvalidLabel;
    if (retain_products and try storage.outputRoot(c, output) == null) return error.PipelineRequiresManagedStorage;
    try c.mkdir(output);
    const record_path = try c.join(&.{ output, try c.fmt("{s}.json", .{label}) });
    const log_path = try c.join(&.{ output, try c.fmt("{s}.log", .{label}) });
    if (u.exists(c.io, record_path) or u.exists(c.io, log_path)) return error.EvidenceAlreadyExists;
    const log = try c.createLog(log_path, true);
    defer log.close(c.io);
    var record = u.object(c.a);
    try u.put(c.a, &record, "argv", try u.strings(c.a, args[4..]));
    try u.put(c.a, &record, "cwd", u.s(c.root));
    if (c.env.get("ZLLVM_STORAGE_ROOT")) |owner| try u.put(c.a, &record, "storage_owner", u.s(owner));
    try u.put(c.a, &record, "status", u.s("running"));
    try u.put(c.a, &record, "started_ns", u.n(std.Io.Clock.real.now(c.io).nanoseconds));
    try u.put(c.a, &record, "samples", u.array(c.a));
    try u.put(c.a, &record, "log", u.s(log_path));
    try u.put(c.a, &record, "runner_binary_sha256", u.s(try c.digest("/proc/self/exe")));
    if (std.mem.startsWith(u8, label, "full-")) {
        var raw_root = output;
        var cache_root: []const u8 = "local-state/caches/ir-headroom-20261103";
        for (args[4..]) |arg| {
            if (std.mem.startsWith(u8, arg, "--real-rows-validation-root=")) raw_root = arg["--real-rows-validation-root=".len..];
            if (std.mem.startsWith(u8, arg, "--real-rows-cache-root=")) cache_root = arg["--real-rows-cache-root=".len..];
        }
        try u.put(c.a, &record, "air_roots", try u.toValue(c.a, .{ .raw = raw_root, .cache = cache_root }));
    }
    const session = try storage.start(c, output, record_path, (try u.get(record, "started_ns")).integer);
    defer if (session) |s| s.close(c);
    const workspace = if (retain_products) try workspaces.startPipeline(c, output, label) else try workspaces.start(c, output, label);
    defer if (workspace) |w| w.close(c);
    if (c.workspace_paths) |mapping| {
        try c.env.put("ZLLVM_RUN_ROOT", mapping.evidence);
        try c.env.put("ZLLVM_TEMP_ROOT", mapping.temporary);
        var overrides = u.array(c.a);
        for ([_][2][]const u8{ .{ "TMPDIR", "temp" }, .{ "ZIG_LOCAL_CACHE_DIR", "local-cache" }, .{ "ZIG_GLOBAL_CACHE_DIR", "global-cache" } }) |pair| {
            if (c.env.get(pair[0]) == null) {
                const path = try c.temporaryPath(&.{ output, pair[1] });
                try c.mkdir(path);
                try c.env.put(pair[0], path);
            } else {
                // Inherited/explicit overrides have another owner. Recording
                // them never makes that path part of this disposable workspace.
                const path = c.env.get(pair[0]).?;
                if (!u.isWithin(mapping.temporary, try c.join(&.{path})))
                    try u.add(&overrides, try u.toValue(c.a, .{ .variable = pair[0], .path = path }));
            }
        }
        var environment = u.object(c.a);
        for ([_][]const u8{ "TMPDIR", "ZIG_LOCAL_CACHE_DIR", "ZIG_GLOBAL_CACHE_DIR", "ZLLVM_RUN_ROOT", "ZLLVM_TEMP_ROOT" }) |key|
            try u.put(c.a, &environment, key, u.s(c.env.get(key).?));
        try u.put(c.a, &record, "workspace_environment", environment);
        try u.put(c.a, &record, "storage", try u.toValue(c.a, .{
            .evidence_root = mapping.evidence,
            .temporary_root = mapping.temporary,
            .layout = workspace.?.record_path,
            .lifetime = workspace.?.record.lifetime,
            .caller_owned_overrides = overrides,
        }));
    }
    // Storage admission can wait for a collector; exclude that wait from the
    // supervised command's wall time.
    const start = std.Io.Clock.awake.now(c.io);
    const code = execute(c, args[4..], record_path, log_path, log, start, &record) catch |err| {
        // Retain the primary supervision error even if final evidence writing also fails.
        u.put(c.a, &record, "status", u.s("failed")) catch {};
        u.put(c.a, &record, "outcome", u.s("supervision_failed")) catch {};
        u.put(c.a, &record, "error", u.s(@errorName(err))) catch {};
        u.put(c.a, &record, "returncode", u.n(2)) catch {};
        u.put(c.a, &record, "finished_ns", u.n(std.Io.Clock.real.now(c.io).nanoseconds)) catch {};
        c.writeJson(record_path, record) catch {};
        return err;
    };
    if (workspace) |w| w.finish(c, record_path, &.{log_path}) catch |err| {
        try std.Io.File.stderr().writeStreamingAll(c.io, try c.fmt("temporary workspace completion deferred: {s}\n", .{@errorName(err)}));
        return code;
    };
    if (session) |s| {
        s.finish(c) catch |err| {
            // A completed test's outcome must survive a cleanup bookkeeping
            // failure. The original running hold remains for later review.
            const message = c.fmt("storage completion deferred: {s}; producer status retained\n", .{@errorName(err)}) catch "storage completion deferred; producer status retained\n";
            std.Io.File.stderr().writeStreamingAll(c.io, message) catch {};
            return code;
        };
        storage_project = s.root;
    }
    return code;
}

fn execute(c: *u.Context, argv: []const []const u8, record_path: []const u8, log_path: []const u8, log: std.Io.File, start: std.Io.Timestamp, record: *u.Value) !i64 {
    try telemetry.sample(c, record);
    var outcome: []const u8 = "completed";
    var actual: ?i64 = null;
    const code: i64 = blk: {
        var child = u.process.Child.spawn(c.gpa, c.io, .{
            .argv = argv,
            .cwd = .{ .path = c.root },
            .environ_map = &c.env,
            .search_path = true,
            .stdout = .{ .file = log },
            .stderr = .{ .file = log },
            .cancellation = u.cancellation(),
        }) catch |err| {
            outcome = "launch_failed";
            try u.put(c.a, record, "error", u.s(@errorName(err)));
            try log.writeStreamingAll(c.io, try c.fmt("launch failed: {s}\n", .{@errorName(err)}));
            break :blk 127;
        };
        defer child.deinit();
        try u.put(c.a, record, "pid", u.n(child.pid.?));
        try c.writeJson(record_path, record.*);
        var sampled = start;
        while (true) {
            if (u.cancellation().isRequested()) {
                outcome = "canceled";
                actual = u.returnCode(try child.stop(2000));
                break :blk u.cancellationCode();
            }
            if (try child.poll()) |_| {
                actual = u.returnCode(try child.finish());
                break :blk actual.?;
            }
            const now = std.Io.Clock.awake.now(c.io);
            if (now.nanoseconds - sampled.nanoseconds >= 2 * std.time.ns_per_s) {
                try telemetry.sample(c, record);
                try c.writeJson(record_path, record.*);
                sampled = now;
            }
            try c.io.sleep(.fromMilliseconds(50), .awake);
        }
    };
    if (!u.cancellation().isRequested()) try telemetry.sample(c, record);
    try u.put(c.a, record, "returncode", u.n(code));
    try u.put(c.a, record, "status", u.s("finished"));
    try u.put(c.a, record, "outcome", u.s(outcome));
    try u.put(c.a, record, "actual_returncode", if (actual) |value| u.n(value) else .null);
    try u.put(c.a, record, "wall_ns", u.n(std.Io.Clock.awake.now(c.io).nanoseconds - start.nanoseconds));
    try u.put(c.a, record, "finished_ns", u.n(std.Io.Clock.real.now(c.io).nanoseconds));
    try c.writeJson(record_path, record.*);
    try c.print("{s}\n", .{try std.json.Stringify.valueAlloc(c.a, .{ .argv = argv, .returncode = code, .wall_ns = (try u.get(record.*, "wall_ns")).integer }, .{})});
    const contents = try c.read(log_path);
    try std.Io.File.stdout().writeStreamingAll(c.io, contents[contents.len -| 5000..]);
    return code;
}
