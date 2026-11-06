//! Optional, per-compilation instrumentation. Nested phases account exclusive
//! time: normalization/legalization is not counted again as selection time.
const std = @import("std");

pub const Phase = enum { other, input, parse, air_lowering, verify, optimize, reachability, normalize, legalize, select, object_write, ownership_write };
const phase_count = @typeInfo(Phase).@"enum".field_names.len;

pub const Counters = struct {
    selected_functions: u64 = 0,
    failed_functions: u64 = 0,
    normalization_runs: u64 = 0,
    legalizer_attempts: u64 = 0,
    legalizer_rewrites: u64 = 0,
    original_form_retries: u64 = 0,
    original_form_selected: u64 = 0,
    selection_iterations: u64 = 0,
    max_selection_iterations: u64 = 0,
    emitted_instructions: u64 = 0,
    emitted_spill_instructions: u64 = 0,
};

pub const Profile = struct {
    const Legalizer = struct { stage: []const u8, attempts: u64 = 0, rewrites: u64 = 0 };
    io: std.Io,
    started: std.Io.Timestamp,
    last: std.Io.Timestamp,
    active: Phase = .other,
    elapsed: [phase_count]u64 = @splat(0),
    counters: Counters = .{},
    legalizers: [32]Legalizer = undefined,
    legalizer_count: usize = 0,

    pub fn attempt(p: *Profile, stage: []const u8) void {
        p.counters.legalizer_attempts += 1;
        for (p.legalizers[0..p.legalizer_count]) |*item| {
            if (std.mem.eql(u8, item.stage, stage)) {
                item.attempts += 1;
                return;
            }
        }
        std.debug.assert(p.legalizer_count < p.legalizers.len);
        p.legalizers[p.legalizer_count] = .{ .stage = stage, .attempts = 1 };
        p.legalizer_count += 1;
    }

    pub fn rewritten(p: *Profile, stage: []const u8) void {
        p.counters.legalizer_rewrites += 1;
        for (p.legalizers[0..p.legalizer_count]) |*item| {
            if (std.mem.eql(u8, item.stage, stage)) {
                item.rewrites += 1;
                return;
            }
        }
        unreachable; // Every rewrite follows a recorded attempt.
    }

    pub fn init(io: std.Io) Profile {
        const now = std.Io.Timestamp.now(io, .awake);
        return .{ .io = io, .started = now, .last = now };
    }

    fn transitionAt(p: *Profile, next: Phase, now: std.Io.Timestamp) void {
        const ns = p.last.durationTo(now).nanoseconds;
        p.elapsed[@backingInt(p.active)] += @intCast(@max(0, ns));
        p.last = now;
        p.active = next;
    }

    fn transition(p: *Profile, next: Phase) void {
        p.transitionAt(next, .now(p.io, .awake));
    }

    pub fn write(p: *Profile, path: []const u8, succeeded: bool) !void {
        p.transition(.other);
        const Row = struct { phase: []const u8, exclusive_ns: u64 };
        var phases: [phase_count]Row = undefined;
        inline for (@typeInfo(Phase).@"enum".field_names, 0..) |name, i| {
            phases[i] = .{ .phase = name, .exclusive_ns = p.elapsed[i] };
        }
        const file = try std.Io.Dir.cwd().createFile(p.io, path, .{});
        defer file.close(p.io);
        var buffer: [4096]u8 = undefined;
        var writer = file.writer(p.io, &buffer);
        try std.json.Stringify.value(.{
            .schema = "compilation-profile-v1",
            .succeeded = succeeded,
            .clock = "awake",
            .timing = "exclusive; other includes uninstrumented work",
            .total_ns = p.started.durationTo(p.last).nanoseconds,
            .phases = phases,
            .counters = p.counters,
            .legalizers = p.legalizers[0..p.legalizer_count],
        }, .{ .whitespace = .indent_2 }, &writer.interface);
        try writer.interface.writeByte('\n');
        try writer.interface.flush();
    }
};

pub const Scope = struct {
    profile: ?*Profile,
    parent: Phase = .other,

    pub fn end(scope: Scope) void {
        if (scope.profile) |p| p.transition(scope.parent);
    }
};

pub fn enter(profile: ?*Profile, phase: Phase) Scope {
    if (profile) |p| {
        const parent = p.active;
        p.transition(phase);
        return .{ .profile = p, .parent = parent };
    }
    return .{ .profile = null };
}

test "phase measurements account nested work exclusively" {
    var p = Profile.init(std.testing.io);
    const zero = p.started;
    p.transitionAt(.select, zero.addDuration(.{ .nanoseconds = 10 }));
    p.transitionAt(.normalize, zero.addDuration(.{ .nanoseconds = 30 }));
    p.transitionAt(.select, zero.addDuration(.{ .nanoseconds = 45 }));
    p.transitionAt(.other, zero.addDuration(.{ .nanoseconds = 50 }));
    try std.testing.expectEqual(10, p.elapsed[@backingInt(Phase.other)]);
    try std.testing.expectEqual(25, p.elapsed[@backingInt(Phase.select)]);
    try std.testing.expectEqual(15, p.elapsed[@backingInt(Phase.normalize)]);
    enter(null, .select).end();
}
