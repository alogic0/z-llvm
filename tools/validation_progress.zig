//! Read a durable command record without controlling or signaling its process.
const std = @import("std");
const u = @import("validation/common.zig");
pub fn main(init: std.process.Init) !void {
    var c = try u.Context.init(init);
    const argv = try init.minimal.args.toSlice(c.a);
    if (u.contains(argv[1..], "--help")) {
        try c.print("usage: zig run tools/validation_progress.zig -- --record PATH\n", .{});
        return;
    }
    const args = try u.Args.parse(c.a, argv[1..], &.{"record"}, &.{});
    const record = try c.load(try c.join(&.{try args.require("record")}));
    const samples = try u.json.array(try u.get(record, "samples"));
    var minimum: ?i64 = null;
    for (samples) |sample| {
        const available = try u.json.integer(try u.get(sample, "available_bytes"));
        minimum = @min(minimum orelse available, available);
    }
    const log = try c.read(try u.str(record, "log"));
    var lines = std.mem.tokenizeScalar(u8, log, '\n');
    var active: ?[]const u8 = null;
    var last: ?[]const u8 = null;
    var completed: usize = 0;
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "gate-start ")) active = line;
        if (std.mem.startsWith(u8, line, "gate-end ")) {
            active = null;
            last = line;
            completed += 1;
        }
    }
    const end = if (record.object.get("finished_ns")) |finished| try u.json.integer(finished) else std.Io.Clock.real.now(c.io).nanoseconds;
    try c.print("{s}\n", .{try std.json.Stringify.valueAlloc(c.a, .{
        .status = try u.str(record, "status"),
        .returncode = record.object.get("returncode") orelse .null,
        .elapsed_seconds = @divTrunc(end - try u.json.integer(try u.get(record, "started_ns")), std.time.ns_per_s),
        .samples = samples.len,
        .minimum_available_bytes = minimum,
        .latest_sample = if (samples.len > 0) samples[samples.len - 1] else u.Value.null,
        .completed_gates = completed,
        .active_gate = active,
        .last_completed_gate = last,
        .log = try u.str(record, "log"),
    }, .{ .whitespace = .indent_2 })});
}
