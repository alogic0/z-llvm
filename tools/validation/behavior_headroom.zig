//! Shared serial disk budget, with an explicit stronger caller reserve.
const std = @import("std");
const u = @import("common.zig");
const policy = @import("../distribution_headroom_policy.zig");

pub fn budget(total: u64, requested: ?[]const u8) !policy.Policy {
    var result = policy.forFilesystem(total);
    if (requested) |text| {
        const reserve = try std.fmt.parseInt(u64, text, 10);
        if (reserve < result.reserve_bytes) return error.WeakerHeadroomReserve;
        result.reserve_bytes = reserve;
        result.required_start_bytes = try std.math.add(u64, reserve, result.projected_peak_bytes);
    }
    return result;
}

const Sample = struct { total: u64, free: u64 };
fn sample(io: std.Io, path: []const u8) !Sample {
    const a = std.heap.page_allocator;
    const result = try u.process.runReport(a, io, .{ .spawn = .{ .argv = &.{ "/bin/df", "-B1", "--output=size,avail", path } }, .timeout_ms = 5000, .stdout_limit = 1024, .stderr_limit = 1024 });
    defer result.deinit(a);
    if (!result.success()) return error.DiskSampleFailed;
    const newline = std.mem.indexOfScalar(u8, result.stdout, '\n') orelse return error.DiskSampleFailed;
    var values = std.mem.tokenizeAny(u8, result.stdout[newline + 1 ..], " \t\r\n");
    const total = try std.fmt.parseInt(u64, values.next() orelse return error.DiskSampleFailed, 10);
    const free = try std.fmt.parseInt(u64, values.next() orelse return error.DiskSampleFailed, 10);
    if (values.next() != null or free > total) return error.DiskSampleFailed;
    return .{ .total = total, .free = free };
}

const Watch = struct {
    io: std.Io,
    path: []const u8,
    limits: policy.Policy,
    start: u64,
    minimum: u64,
    log: std.Io.File,
    stop: std.atomic.Value(bool) = .init(false),
    violation: bool = false,
    failed: bool = false,

    fn run(w: *Watch) void {
        while (!w.stop.load(.acquire)) {
            const observed = sample(w.io, w.path) catch {
                w.failed = true;
                @constCast(u.cancellation()).request();
                return;
            };
            if (observed.total != w.limits.filesystem_total_bytes) {
                w.failed = true;
                @constCast(u.cancellation()).request();
                return;
            }
            w.minimum = @min(w.minimum, observed.free);
            var buffer: [120]u8 = undefined;
            const line = std.fmt.bufPrint(&buffer, "{d}\t{d}\n", .{ std.Io.Timestamp.now(w.io, .real).nanoseconds, observed.free }) catch unreachable;
            w.log.writeStreamingAll(w.io, line) catch {
                w.failed = true;
                @constCast(u.cancellation()).request();
                return;
            };
            if (observed.free < w.limits.reserve_bytes) {
                w.violation = true;
                @constCast(u.cancellation()).request();
                return;
            }
            std.Io.sleep(w.io, .fromSeconds(2), .awake) catch return;
        }
    }
};

pub const Guard = struct {
    watch: *Watch,
    thread: std.Thread,

    pub fn start(c: *u.Context, output: []const u8, requested: ?[]const u8) !Guard {
        const first = try sample(c.io, output);
        const limits = try budget(first.total, requested);
        try c.writeJson(try c.join(&.{ output, "space-admission.json" }), .{ .policy = limits, .starting_free_bytes = first.free, .admitted = first.free >= limits.required_start_bytes });
        if (first.free < limits.required_start_bytes) return error.InsufficientAdmissionSpace;
        const watch = try c.a.create(Watch);
        watch.* = .{ .io = c.io, .path = output, .limits = limits, .start = first.free, .minimum = first.free, .log = try c.createLog(try c.join(&.{ output, "space-samples.tsv" }), true) };
        errdefer watch.log.close(c.io);
        return .{ .watch = watch, .thread = try std.Thread.spawn(.{}, Watch.run, .{watch}) };
    }

    pub fn finish(g: Guard, c: *u.Context, output: []const u8) !void {
        g.watch.stop.store(true, .release);
        g.thread.join();
        defer g.watch.log.close(c.io);
        try c.writeJson(try c.join(&.{ output, "space.json" }), .{
            .policy = g.watch.limits,
            .reserve_bytes = g.watch.limits.reserve_bytes,
            .required_start_bytes = g.watch.limits.required_start_bytes,
            .starting_free_bytes = g.watch.start,
            .minimum_sampled_free_bytes = g.watch.minimum,
            .observed_global_decrease_bytes = g.watch.start - g.watch.minimum,
            .reserve_violated = g.watch.violation,
            .sampling_failed = g.watch.failed,
            .interval_ms = 2000,
        });
        if (g.watch.violation) return error.DiskReserveViolated;
        if (g.watch.failed) return error.DiskSampleFailed;
    }
};

test "preopt headroom keeps shared admission and stronger caller floors" {
    const base = try budget(982_240_026_624, null);
    try std.testing.expectEqual(@as(u64, 20_000_000_000), base.required_start_bytes);
    const stronger = try budget(982_240_026_624, "20000000000");
    try std.testing.expectEqual(@as(u64, 28_589_934_592), stronger.required_start_bytes);
    try std.testing.expectError(error.WeakerHeadroomReserve, budget(982_240_026_624, "11410065407"));
    try std.testing.expectError(error.Overflow, budget(982_240_026_624, "18446744073709551615"));
}
