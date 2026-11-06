//! Optional per-compilation instrumentation. Phases are exclusive elapsed time.
//! Legalizer allocation counters observe requests made through each legalizer's
//! allocator, above its arena. They are not resident memory or live heap bytes.
const std = @import("std");

pub const Phase = enum { other, input, parse, air_lowering, verify, optimize, reachability, normalize, legalize, select, object_write, ownership_write };
const phase_count = @typeInfo(Phase).@"enum".field_names.len;
const PhaseRow = struct { phase: []const u8, exclusive_ns: u64 };

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

pub const Allocations = struct {
    alloc_calls: u64 = 0,
    requested_bytes: u64 = 0,
    allocated_bytes: u64 = 0,
    failed_allocations: u64 = 0,
    resize_calls: u64 = 0,
    remap_calls: u64 = 0,
    grown_bytes: u64 = 0,
    free_calls: u64 = 0,

    pub fn bytes(a: Allocations) u64 {
        return a.allocated_bytes + a.grown_bytes;
    }
    fn add(a: *Allocations, other: Allocations) void {
        inline for (@typeInfo(Allocations).@"struct".field_names) |name|
            @field(a, name) += @field(other, name);
    }
};

pub const Profile = struct {
    const Legalizer = struct {
        stage: []const u8 = "",
        attempts: u64 = 0,
        rewrites: u64 = 0,
        errors: u64 = 0,
        elapsed_ns: u64 = 0,
        rewritten_ns: u64 = 0,
        unchanged_ns: u64 = 0,
        error_ns: u64 = 0,
        allocations: Allocations = .{},
        unchanged_allocation_bytes: u64 = 0,
        discarded_candidates: u64 = 0,
        discarded_candidate_bytes: u64 = 0,
    };
    const Function = struct {
        name: []const u8,
        input_blocks: usize,
        input_instructions: usize,
        total_ns: u64 = 0,
        phases: [phase_count]PhaseRow = rows(@splat(0)),
        counters: Counters = .{},
        legalizer_allocations: Allocations = .{},
        original_form_ns: u64 = 0,
        discarded_candidate_bytes: u64 = 0,
    };

    allocator: std.mem.Allocator,
    io: std.Io,
    started: std.Io.Timestamp,
    last: std.Io.Timestamp,
    active: Phase = .other,
    elapsed: [phase_count]u64 = @splat(0),
    counters: Counters = .{},
    legalizers: [32]Legalizer = @splat(.{}),
    legalizer_count: usize = 0,
    legalizer_allocations: Allocations = .{},
    functions: std.ArrayList(Function) = .empty,
    current_function: ?usize = null,
    original_form_ns: u64 = 0,

    pub fn init(allocator: std.mem.Allocator, io: std.Io) Profile {
        const now = std.Io.Timestamp.now(io, .awake);
        return .{ .allocator = allocator, .io = io, .started = now, .last = now };
    }

    pub fn deinit(p: *Profile) void {
        for (p.functions.items) |function| p.allocator.free(function.name);
        p.functions.deinit(p.allocator);
    }

    pub fn beginFunction(p: *Profile, name: []const u8, blocks: usize, instructions: usize) !FunctionScope {
        std.debug.assert(p.current_function == null);
        const owned_name = try p.allocator.dupe(u8, name);
        errdefer p.allocator.free(owned_name);
        try p.functions.append(p.allocator, .{ .name = owned_name, .input_blocks = blocks, .input_instructions = instructions });
        p.transition(p.active);
        p.current_function = p.functions.items.len - 1;
        return .{ .profile = p, .before = p.counters, .elapsed = p.elapsed, .original_form_ns = p.original_form_ns };
    }

    pub fn iteration(p: *Profile, count: u64) void {
        p.counters.selection_iterations += 1;
        p.counters.normalization_runs += 1;
        p.counters.max_selection_iterations = @max(p.counters.max_selection_iterations, count);
        if (p.current_function) |index| {
            const counters = &p.functions.items[index].counters;
            counters.max_selection_iterations = @max(counters.max_selection_iterations, count);
        }
    }

    pub fn discardCandidate(p: *Profile, stage: usize, bytes: u64) void {
        p.legalizers[stage].discarded_candidates += 1;
        p.legalizers[stage].discarded_candidate_bytes += bytes;
        if (p.current_function) |index| p.functions.items[index].discarded_candidate_bytes += bytes;
    }

    fn transitionAt(p: *Profile, next: Phase, now: std.Io.Timestamp) void {
        p.elapsed[@backingInt(p.active)] += elapsedNs(p.last, now);
        p.last = now;
        p.active = next;
    }

    fn transition(p: *Profile, next: Phase) void {
        p.transitionAt(next, .now(p.io, .awake));
    }

    pub fn write(p: *Profile, path: []const u8, succeeded: bool) !void {
        std.debug.assert(p.current_function == null);
        p.transition(.other);
        const file = try std.Io.Dir.cwd().createFile(p.io, path, .{});
        defer file.close(p.io);
        var buffer: [4096]u8 = undefined;
        var writer = file.writer(p.io, &buffer);
        try std.json.Stringify.value(.{
            .schema = "compilation-profile-v2",
            .succeeded = succeeded,
            .clock = "awake",
            .timing = "exclusive phases; function phases partition selection; stage times nest in legalize; original_form_ns nests in select",
            .allocation_scope = "logical legalizer allocator requests; allocated_bytes plus grown_bytes; excludes profiler storage; not live bytes or RSS",
            .total_ns = p.started.durationTo(p.last).nanoseconds,
            .phases = rows(p.elapsed),
            .counters = p.counters,
            .legalizer_allocations = p.legalizer_allocations,
            .original_form_ns = p.original_form_ns,
            .legalizers = p.legalizers[0..p.legalizer_count],
            .functions = p.functions.items,
        }, .{ .whitespace = .indent_2 }, &writer.interface);
        try writer.interface.writeByte('\n');
        try writer.interface.flush();
    }
};

fn elapsedNs(start: std.Io.Timestamp, finish: std.Io.Timestamp) u64 {
    return @intCast(@max(0, start.durationTo(finish).nanoseconds));
}
fn rows(elapsed: [phase_count]u64) [phase_count]PhaseRow {
    var result: [phase_count]PhaseRow = undefined;
    inline for (@typeInfo(Phase).@"enum".field_names, 0..) |name, i|
        result[i] = .{ .phase = name, .exclusive_ns = elapsed[i] };
    return result;
}

pub const FunctionScope = struct {
    profile: ?*Profile = null,
    before: Counters = .{},
    elapsed: [phase_count]u64 = @splat(0),
    original_form_ns: u64 = 0,

    pub fn end(scope: FunctionScope) void {
        const p = scope.profile orelse return;
        p.transition(p.active);
        const function = &p.functions.items[p.current_function.?];
        var elapsed: [phase_count]u64 = undefined;
        for (&elapsed, p.elapsed, scope.elapsed) |*value, now, before| {
            value.* = now - before;
            function.total_ns += value.*;
        }
        function.phases = rows(elapsed);
        inline for (@typeInfo(Counters).@"struct".field_names) |name| {
            if (!comptime std.mem.eql(u8, name, "max_selection_iterations"))
                @field(function.counters, name) = @field(p.counters, name) - @field(scope.before, name);
        }
        function.original_form_ns = p.original_form_ns - scope.original_form_ns;
        p.current_function = null;
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

pub const RetryScope = struct {
    profile: ?*Profile,
    started: std.Io.Timestamp = undefined,
    pub fn end(scope: RetryScope) void {
        if (scope.profile) |p| p.original_form_ns += elapsedNs(scope.started, .now(p.io, .awake));
    }
};
pub fn retry(profile: ?*Profile) RetryScope {
    return .{ .profile = profile, .started = if (profile) |p| .now(p.io, .awake) else undefined };
}

/// A probe lives through the legalizer call only. Returned IR contains ordinary
/// allocator-independent containers; the wrapper never owns an allocation.
pub const Attempt = struct {
    pub const Outcome = enum { unchanged, rewritten, failed };
    profile: ?*Profile,
    stage: usize,
    parent: std.mem.Allocator,
    started: std.Io.Timestamp = undefined,
    outcome: Outcome = .failed,
    allocations: Allocations = .{},

    pub fn init(profile: ?*Profile, stage: usize, name: []const u8, parent: std.mem.Allocator) Attempt {
        if (profile) |p| {
            std.debug.assert(stage < p.legalizers.len);
            const item = &p.legalizers[stage];
            std.debug.assert(item.stage.len == 0 or std.mem.eql(u8, item.stage, name));
            item.stage = name;
            item.attempts += 1;
            p.counters.legalizer_attempts += 1;
            p.legalizer_count = @max(p.legalizer_count, stage + 1);
        }
        return .{ .profile = profile, .stage = stage, .parent = parent, .started = if (profile) |p| .now(p.io, .awake) else undefined };
    }

    pub fn allocator(a: *Attempt) std.mem.Allocator {
        if (a.profile == null) return a.parent;
        return .{ .ptr = a, .vtable = &.{ .alloc = allocate, .resize = resize, .remap = remap, .free = free } };
    }

    pub fn end(a: *Attempt) void {
        if (a.profile) |p| a.endAt(.now(p.io, .awake));
    }

    fn endAt(a: *Attempt, now: std.Io.Timestamp) void {
        const p = a.profile orelse return;
        const item = &p.legalizers[a.stage];
        const ns = elapsedNs(a.started, now);
        item.elapsed_ns += ns;
        switch (a.outcome) {
            .rewritten => {
                item.rewrites += 1;
                p.counters.legalizer_rewrites += 1;
                item.rewritten_ns += ns;
            },
            .unchanged => {
                item.unchanged_ns += ns;
                item.unchanged_allocation_bytes += a.allocations.bytes();
            },
            .failed => {
                item.errors += 1;
                item.error_ns += ns;
            },
        }
        item.allocations.add(a.allocations);
        p.legalizer_allocations.add(a.allocations);
        if (p.current_function) |index| p.functions.items[index].legalizer_allocations.add(a.allocations);
    }

    fn allocate(ctx: *anyopaque, len: usize, alignment: std.mem.Alignment, ret: usize) ?[*]u8 {
        const a: *Attempt = @ptrCast(@alignCast(ctx));
        a.allocations.alloc_calls += 1;
        a.allocations.requested_bytes += len;
        const result = a.parent.rawAlloc(len, alignment, ret) orelse {
            a.allocations.failed_allocations += 1;
            return null;
        };
        a.allocations.allocated_bytes += len;
        return result;
    }
    fn resize(ctx: *anyopaque, memory: []u8, alignment: std.mem.Alignment, len: usize, ret: usize) bool {
        const a: *Attempt = @ptrCast(@alignCast(ctx));
        a.allocations.resize_calls += 1;
        if (!a.parent.rawResize(memory, alignment, len, ret)) return false;
        if (len > memory.len) a.allocations.grown_bytes += len - memory.len;
        return true;
    }
    fn remap(ctx: *anyopaque, memory: []u8, alignment: std.mem.Alignment, len: usize, ret: usize) ?[*]u8 {
        const a: *Attempt = @ptrCast(@alignCast(ctx));
        a.allocations.remap_calls += 1;
        const result = a.parent.rawRemap(memory, alignment, len, ret) orelse return null;
        if (len > memory.len) a.allocations.grown_bytes += len - memory.len;
        return result;
    }
    fn free(ctx: *anyopaque, memory: []u8, alignment: std.mem.Alignment, ret: usize) void {
        const a: *Attempt = @ptrCast(@alignCast(ctx));
        a.allocations.free_calls += 1;
        a.parent.rawFree(memory, alignment, ret);
    }
};

test "phase measurements account nested work exclusively" {
    var p = Profile.init(std.testing.allocator, std.testing.io);
    defer p.deinit();
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

test "legalizer profiles distinguish unchanged rewritten and failed allocation work" {
    var p = Profile.init(std.testing.allocator, std.testing.io);
    defer p.deinit();
    var storage: [128]u8 = undefined;
    var fixed = std.heap.FixedBufferAllocator.init(&storage);
    var attempt = Attempt.init(&p, 0, "test-stage", fixed.allocator());
    const allocator = attempt.allocator();
    var bytes = try allocator.alloc(u8, 8);
    @memset(bytes, 0x5a);
    try std.testing.expect(allocator.resize(bytes, 16));
    bytes = bytes.ptr[0..16];
    bytes = try allocator.realloc(bytes, 32);
    for (bytes[0..8]) |byte| try std.testing.expectEqual(@as(u8, 0x5a), byte);
    allocator.free(bytes);
    try std.testing.expectError(error.OutOfMemory, allocator.alloc(u8, 129));
    attempt.outcome = .unchanged;
    attempt.endAt(attempt.started.addDuration(.{ .nanoseconds = 10 }));
    var rewritten = Attempt.init(&p, 0, "test-stage", fixed.allocator());
    rewritten.outcome = .rewritten;
    rewritten.endAt(rewritten.started.addDuration(.{ .nanoseconds = 20 }));
    var failed = Attempt.init(&p, 0, "test-stage", fixed.allocator());
    failed.endAt(failed.started.addDuration(.{ .nanoseconds = 30 }));
    const item = p.legalizers[0];
    try std.testing.expectEqual(3, item.attempts);
    try std.testing.expectEqual(1, item.rewrites);
    try std.testing.expectEqual(1, item.errors);
    try std.testing.expectEqual(60, item.elapsed_ns);
    try std.testing.expectEqual(32, item.unchanged_allocation_bytes);
    try std.testing.expectEqual(1, item.allocations.failed_allocations);
    try std.testing.expectEqualDeep(item.allocations, p.legalizer_allocations);
    var disabled = Attempt.init(null, 0, "disabled", fixed.allocator());
    try std.testing.expect(disabled.allocator().ptr == fixed.allocator().ptr);
    disabled.end();
}

test "function profiles retain names and separate successful and failed selections" {
    var p = Profile.init(std.testing.allocator, std.testing.io);
    defer p.deinit();
    var name = [_]u8{ 't', 'e', 's', 't' };
    const first = try p.beginFunction(&name, 1, 3);
    const selection = enter(&p, .select);
    p.iteration(1);
    p.iteration(2);
    p.counters.selected_functions += 1;
    selection.end();
    first.end();
    @memset(&name, 'x');
    const second = try p.beginFunction("failure", 2, 5);
    p.iteration(1);
    p.counters.failed_functions += 1;
    second.end();
    try std.testing.expectEqualStrings("test", p.functions.items[0].name);
    try std.testing.expectEqual(1, p.functions.items[0].counters.selected_functions);
    try std.testing.expectEqual(2, p.functions.items[0].counters.max_selection_iterations);
    try std.testing.expectEqual(1, p.functions.items[1].counters.failed_functions);
    try std.testing.expectEqual(1, p.functions.items[1].counters.max_selection_iterations);
    for (p.functions.items) |function| {
        var total: u64 = 0;
        for (function.phases) |phase| total += phase.exclusive_ns;
        try std.testing.expectEqual(function.total_ns, total);
    }
}
