//! Optional per-compilation instrumentation. Phases are exclusive elapsed time.
//! Legalizer allocation counters observe requests made through each legalizer's
//! allocator, above its arena. They are not resident memory or live heap bytes.
const std = @import("std");

pub const Phase = enum { other, input, parse, air_lowering, verify, optimize, reachability, normalize, legalize, select, object_write, ownership_write };
const phase_count = @typeInfo(Phase).@"enum".field_names.len;
const legalizer_stage_count = @typeInfo(@import("codegen/x86_64/generic_cfg/optional_legalization.zig").Stage).@"enum".field_names.len;
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
    legalizers: [legalizer_stage_count]Legalizer = @splat(.{}),
    legalizer_count: usize = 0,
    legalizer_allocations: Allocations = .{},
    functions: std.ArrayList(Function) = .empty,
    current_function: ?usize = null,
    original_form_ns: u64 = 0,
    events_file: ?std.Io.File = null,
    events_error: ?anyerror = null,
    event_sequence: u64 = 0,

    pub fn init(allocator: std.mem.Allocator, io: std.Io) Profile {
        const now = std.Io.Timestamp.now(io, .awake);
        return .{ .allocator = allocator, .io = io, .started = now, .last = now };
    }

    pub fn deinit(p: *Profile) void {
        if (p.events_file) |file| file.close(p.io);
        for (p.functions.items) |function| p.allocator.free(function.name);
        p.functions.deinit(p.allocator);
    }

    /// Each JSONL record is flushed independently. A killed process leaves a
    /// useful prefix, without pretending that its current function completed.
    pub fn startEvents(p: *Profile, path: []const u8) !void {
        try p.startEventsFile(try std.Io.Dir.cwd().createFile(p.io, path, .{}));
    }

    fn startEventsFile(p: *Profile, file: std.Io.File) !void {
        std.debug.assert(p.events_file == null);
        p.events_file = file;
        p.event("profile_begin", .{ .clock = "awake", .timing = "includes opt-in event output overhead" });
        if (p.events_error != null) return error.ProfileEventWriteFailed;
    }

    pub fn finishEvents(p: *Profile, succeeded: bool) !void {
        std.debug.assert(p.current_function == null);
        p.event("profile_end", .{ .succeeded = succeeded, .counters = p.counters });
        if (p.events_error != null) return error.ProfileEventWriteFailed;
    }

    fn event(p: *Profile, kind: []const u8, details: anytype) void {
        const file = p.events_file orelse return;
        if (p.events_error != null) return;
        p.writeEvent(file, kind, details) catch |err| {
            p.events_error = err;
            return;
        };
        p.event_sequence += 1;
    }

    fn writeEvent(p: *Profile, file: std.Io.File, kind: []const u8, details: anytype) !void {
        var buffer: [4096]u8 = undefined;
        // Streaming writers advance the file position across independent
        // records. A fresh positional writer would overwrite the prefix.
        var writer = file.writerStreaming(p.io, &buffer);
        try std.json.Stringify.value(.{
            .schema = "compilation-events-v1",
            .sequence = p.event_sequence,
            .elapsed_ns = elapsedNs(p.started, .now(p.io, .awake)),
            .event = kind,
            .function = if (p.current_function) |index| p.functions.items[index].name else @as(?[]const u8, null),
            .phase = @tagName(p.active),
            .details = details,
        }, .{}, &writer.interface);
        try writer.interface.writeByte('\n');
        try writer.interface.flush();
    }

    pub fn beginFunction(p: *Profile, name: []const u8, blocks: usize, instructions: usize) !FunctionScope {
        std.debug.assert(p.current_function == null);
        const owned_name = try p.allocator.dupe(u8, name);
        errdefer p.allocator.free(owned_name);
        try p.functions.append(p.allocator, .{ .name = owned_name, .input_blocks = blocks, .input_instructions = instructions });
        p.transition(p.active);
        p.current_function = p.functions.items.len - 1;
        p.event("function_begin", .{ .blocks = blocks, .instructions = instructions, .index = p.current_function.? });
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
        p.event("iteration", .{ .iteration = count });
    }

    pub fn discardCandidate(p: *Profile, stage: usize, bytes: u64) void {
        p.legalizers[stage].discarded_candidates += 1;
        p.legalizers[stage].discarded_candidate_bytes += bytes;
        if (p.current_function) |index| p.functions.items[index].discarded_candidate_bytes += bytes;
    }

    fn transitionAt(p: *Profile, next: Phase, now: std.Io.Timestamp) void {
        const previous = p.active;
        p.elapsed[@backingInt(p.active)] += elapsedNs(p.last, now);
        p.last = now;
        p.active = next;
        if (previous != next) p.event("phase", .{ .from = @tagName(previous), .to = @tagName(next) });
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
        p.event("function_end", function.*);
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

/// Diagnostic substeps do not change the final profile's phase or legalizer
/// counters. No clocks or writes are added when the event stream is disabled.
pub const Activity = struct {
    profile: ?*Profile = null,
    name: []const u8 = "",
    started: std.Io.Timestamp = undefined,

    pub fn end(scope: Activity) void {
        if (scope.profile) |p| p.event("activity_end", .{ .name = scope.name, .elapsed_ns = elapsedNs(scope.started, .now(p.io, .awake)) });
    }
};

pub fn activity(profile: ?*Profile, name: []const u8) Activity {
    const p = profile orelse return .{};
    if (p.events_file == null or p.events_error != null) return .{};
    p.event("activity_begin", .{ .name = name });
    return .{ .profile = p, .name = name, .started = .now(p.io, .awake) };
}

pub const RetryScope = struct {
    profile: ?*Profile,
    started: std.Io.Timestamp = undefined,
    pub fn end(scope: RetryScope) void {
        if (scope.profile) |p| {
            const ns = elapsedNs(scope.started, .now(p.io, .awake));
            p.original_form_ns += ns;
            p.event("retry_end", .{ .elapsed_ns = ns });
        }
    }
};
pub fn retry(profile: ?*Profile) RetryScope {
    if (profile) |p| p.event("retry_begin", .{});
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
            p.event("legalizer_begin", .{ .stage = name });
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
        p.event("legalizer_end", .{ .stage = item.stage, .outcome = @tagName(a.outcome), .elapsed_ns = ns, .allocations = a.allocations });
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

test "progress records are readable before completion and preserve event order" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    var p = Profile.init(std.testing.allocator, std.testing.io);
    defer p.deinit();
    try p.startEventsFile(try tmp.dir.createFile(std.testing.io, "events.jsonl", .{}));
    const function = try p.beginFunction("quoted\"name\n", 2, 3);
    const phase = enter(&p, .legalize);
    p.iteration(1);
    var attempt = Attempt.init(&p, 0, "pending-stage", std.testing.allocator);
    const prefix = try tmp.dir.readFileAlloc(std.testing.io, "events.jsonl", std.testing.allocator, .limited(65536));
    defer std.testing.allocator.free(prefix);
    try std.testing.expect(std.mem.endsWith(u8, prefix, "\n"));
    try std.testing.expect(std.mem.indexOf(u8, prefix, "profile_end") == null);
    var lines = std.mem.tokenizeScalar(u8, prefix, '\n');
    var records: usize = 0;
    while (lines.next()) |line| {
        const parsed = try std.json.parseFromSlice(std.json.Value, std.testing.allocator, line, .{});
        defer parsed.deinit();
        try std.testing.expectEqual(@as(i64, @intCast(records)), parsed.value.object.get("sequence").?.integer);
        records += 1;
        if (lines.peek() == null) {
            try std.testing.expectEqualStrings("legalizer_begin", parsed.value.object.get("event").?.string);
            try std.testing.expectEqualStrings("quoted\"name\n", parsed.value.object.get("function").?.string);
        }
    }
    attempt.outcome = .unchanged;
    attempt.end();
    phase.end();
    p.counters.selected_functions += 1;
    function.end();
    try p.finishEvents(true);
    const completed = try tmp.dir.readFileAlloc(std.testing.io, "events.jsonl", std.testing.allocator, .limited(65536));
    defer std.testing.allocator.free(completed);
    try std.testing.expect(std.mem.startsWith(u8, completed, prefix));
    var complete_lines = std.mem.tokenizeScalar(u8, completed, '\n');
    var count: usize = 0;
    while (complete_lines.next()) |line| {
        const parsed = try std.json.parseFromSlice(std.json.Value, std.testing.allocator, line, .{});
        defer parsed.deinit();
        try std.testing.expectEqual(@as(i64, @intCast(count)), parsed.value.object.get("sequence").?.integer);
        count += 1;
        if (complete_lines.peek() == null) {
            try std.testing.expectEqualStrings("profile_end", parsed.value.object.get("event").?.string);
            try std.testing.expect(parsed.value.object.get("details").?.object.get("succeeded").?.bool);
        }
    }
    try std.testing.expect(count > records);
}

test "progress output failures cannot produce a successful completion record" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.writeFile(std.testing.io, .{ .sub_path = "readonly", .data = "original" });
    var p = Profile.init(std.testing.allocator, std.testing.io);
    defer p.deinit();
    try std.testing.expectError(error.ProfileEventWriteFailed, p.startEventsFile(try tmp.dir.openFile(std.testing.io, "readonly", .{})));
    try std.testing.expectError(error.ProfileEventWriteFailed, p.finishEvents(true));
    try std.testing.expectEqual(0, p.event_sequence);
    const retained = try tmp.dir.readFileAlloc(std.testing.io, "readonly", std.testing.allocator, .limited(100));
    defer std.testing.allocator.free(retained);
    try std.testing.expectEqualStrings("original", retained);
}
