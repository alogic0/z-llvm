//! Streaming state machine for compilation-events-v1.
//! Implements audit-events.jq's balance/order/outcome rules, plus a required
//! profile_begin, supported event names, typed fields and complete EOF.
const std = @import("std");
pub const Counters = struct {
    selected_functions: u64,
    failed_functions: u64,
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
const DetailFields = struct {
    name: ?[]const u8 = null,
    stage: ?[]const u8 = null,
    counters: ?Counters = null,
    succeeded: ?bool = null,
};
pub const Details = struct {
    name: ?[]const u8 = null,
    stage: ?[]const u8 = null,
    counters: ?Counters = null,
    succeeded: ?bool = null,
    pub fn jsonParse(a: std.mem.Allocator, source: anytype, options: std.json.ParseOptions) std.json.ParseError(@TypeOf(source.*))!Details {
        // Zig's anonymous .{} is emitted as [] for retry_begin in these traces.
        // An empty tuple has no fields; non-empty arrays are not details objects.
        if (try source.peekNextTokenType() == .array_begin) {
            _ = try source.next();
            if (try source.next() != .array_end) return error.UnexpectedToken;
            return .{};
        }
        const fields = try std.json.innerParse(DetailFields, a, source, options);
        return .{ .name = fields.name, .stage = fields.stage, .counters = fields.counters, .succeeded = fields.succeeded };
    }
};
pub const Event = struct {
    schema: []const u8,
    sequence: u64,
    elapsed_ns: u64,
    event: []const u8,
    function: ?[]const u8,
    phase: []const u8,
    details: Details,
};
const Kind = enum { profile_begin, profile_end, function_begin, function_end, legalizer_begin, legalizer_end, activity_begin, activity_end, retry_begin, retry_end, iteration, phase };
const Slot = struct {
    buffer: [4096]u8 = undefined,
    length: ?usize = null,
    fn set(s: *Slot, text: []const u8) !void {
        if (text.len > s.buffer.len) return error.UnsupportedLongScopeName;
        @memcpy(s.buffer[0..text.len], text);
        s.length = text.len;
    }
    fn matches(s: *const Slot, text: []const u8) bool {
        return if (s.length) |n| std.mem.eql(u8, s.buffer[0..n], text) else false;
    }
};
pub const FailedFunction = struct {
    name: []const u8,
    begin_sequence: u64,
    end_sequence: u64,
    begin_byte_offset: u64,
    end_byte_offset: u64,
    counters: Counters,
};
pub const State = struct {
    a: std.mem.Allocator,
    names: std.StringHashMap(void),
    failures: std.ArrayList(FailedFunction) = .empty,
    sequence: u64 = 0,
    elapsed_ns: u64 = 0,
    begins: u64 = 0,
    ends: u64 = 0,
    selected: u64 = 0,
    failed: u64 = 0,
    active: ?[]const u8 = null,
    begin_sequence: u64 = 0,
    begin_byte_offset: u64 = 0,
    legalizer: Slot = .{},
    activity: Slot = .{},
    retry: bool = false,
    complete: bool = false,
    succeeded: ?bool = null,
    counters: ?Counters = null,
    event_counts: [@typeInfo(Kind).@"enum".field_names.len]u64 = @splat(0),
    pub fn init(a: std.mem.Allocator) State {
        return .{ .a = a, .names = .init(a) };
    }
    pub fn deinit(s: *State) void {
        var it = s.names.keyIterator();
        while (it.next()) |key| s.a.free(key.*);
        s.names.deinit();
        s.failures.deinit(s.a);
    }
    fn sameFunction(s: *const State, name: ?[]const u8) bool {
        if (s.active) |active| return name != null and std.mem.eql(u8, active, name.?);
        return name == null;
    }
    pub fn feed(s: *State, e: Event, offset: u64, end_offset: u64) !void {
        if (s.complete) return error.EventAfterProfileEnd;
        if (!std.mem.eql(u8, e.schema, "compilation-events-v1")) return error.InvalidSchema;
        if (e.sequence != s.sequence) return error.InvalidSequence;
        if (e.elapsed_ns < s.elapsed_ns) return error.DecreasingTimestamp;
        const kind = std.meta.stringToEnum(Kind, e.event) orelse return error.UnsupportedEventKind;
        if (s.sequence == 0 and kind != .profile_begin) return error.MissingProfileBegin;
        s.elapsed_ns = e.elapsed_ns;
        s.sequence += 1;
        s.event_counts[@backingInt(kind)] += 1;
        switch (kind) {
            .profile_begin => if (e.sequence != 0 or e.function != null) {
                return error.RepeatedProfileBegin;
            },
            .function_begin => {
                if (s.active != null or s.legalizer.length != null or s.activity.length != null or s.retry) return error.OverlappingFunction;
                const name = e.function orelse return error.MissingFunctionName;
                if (s.names.contains(name)) return error.RepeatedFunction;
                const owned = try s.a.dupe(u8, name);
                errdefer s.a.free(owned);
                try s.names.put(owned, {});
                s.active = owned;
                s.begins += 1;
                s.begin_sequence = e.sequence;
                s.begin_byte_offset = offset;
            },
            .function_end => {
                if (s.active == null or !s.sameFunction(e.function) or !s.sameFunction(e.details.name) or s.legalizer.length != null or s.activity.length != null or s.retry) return error.UnbalancedFunction;
                const counts = e.details.counters orelse return error.MissingCounters;
                if (!((counts.selected_functions == 1 and counts.failed_functions == 0) or (counts.selected_functions == 0 and counts.failed_functions == 1))) return error.InvalidFunctionOutcome;
                s.selected += counts.selected_functions;
                s.failed += counts.failed_functions;
                if (counts.failed_functions == 1) try s.failures.append(s.a, .{ .name = s.active.?, .begin_sequence = s.begin_sequence, .end_sequence = e.sequence, .begin_byte_offset = s.begin_byte_offset, .end_byte_offset = end_offset, .counters = counts });
                s.active = null;
                s.ends += 1;
            },
            .legalizer_begin => {
                if (!s.sameFunction(e.function) or s.legalizer.length != null) return error.OverlappingLegalizer;
                try s.legalizer.set(e.details.stage orelse return error.MissingLegalizerStage);
            },
            .legalizer_end => {
                if (!s.sameFunction(e.function) or !s.legalizer.matches(e.details.stage orelse return error.MissingLegalizerStage)) return error.UnbalancedLegalizer;
                s.legalizer.length = null;
            },
            .activity_begin => {
                if (!s.sameFunction(e.function) or s.activity.length != null) return error.OverlappingActivity;
                try s.activity.set(e.details.name orelse return error.MissingActivityName);
            },
            .activity_end => {
                if (!s.sameFunction(e.function) or !s.activity.matches(e.details.name orelse return error.MissingActivityName)) return error.UnbalancedActivity;
                s.activity.length = null;
            },
            .retry_begin => {
                if (s.retry) return error.OverlappingRetry;
                s.retry = true;
            },
            .retry_end => {
                if (!s.retry) return error.UnbalancedRetry;
                s.retry = false;
            },
            .profile_end => {
                if (e.function != null or s.active != null or s.legalizer.length != null or s.activity.length != null or s.retry or s.begins != s.ends) return error.IncompleteProfile;
                const counts = e.details.counters orelse return error.MissingCounters;
                if (s.selected != counts.selected_functions or s.failed != counts.failed_functions) return error.ProfileOutcomeMismatch;
                const succeeded = e.details.succeeded orelse return error.MissingSuccessFlag;
                if (succeeded and s.failed != 0) return error.InconsistentSuccessFlag;
                s.counters = counts;
                s.succeeded = succeeded;
                s.complete = true;
            },
            .iteration, .phase => {},
        }
    }
    pub fn finish(s: *const State) !void {
        if (!s.complete) return error.MissingProfileEnd;
    }
};
fn fixture(a: std.mem.Allocator, events: []const Event) !void {
    var s = State.init(a);
    defer s.deinit();
    for (events) |e| try s.feed(e, 0, 0);
    try s.finish();
}
const begin: Event = .{ .schema = "compilation-events-v1", .sequence = 0, .elapsed_ns = 0, .event = "profile_begin", .function = null, .phase = "other", .details = .{} };
fn event(seq: u64, kind: []const u8, function: ?[]const u8) Event {
    var e = begin;
    e.sequence = seq;
    e.elapsed_ns = seq;
    e.event = kind;
    e.function = function;
    return e;
}
fn end(seq: u64, selected: u64, failed: u64, succeeded: bool) Event {
    var e = event(seq, "profile_end", null);
    e.details = .{ .counters = .{ .selected_functions = selected, .failed_functions = failed }, .succeeded = succeeded };
    return e;
}
fn functionEnd(seq: u64, selected: u64, failed: u64) Event {
    var e = event(seq, "function_end", "f");
    e.details = .{ .name = "f", .counters = .{ .selected_functions = selected, .failed_functions = failed } };
    return e;
}
test "successful and unsuccessful compilations can both have complete valid traces" {
    try fixture(std.testing.allocator, &.{ begin, event(1, "function_begin", "f"), functionEnd(2, 1, 0), end(3, 1, 0, true) });
    try fixture(std.testing.allocator, &.{ begin, event(1, "function_begin", "f"), functionEnd(2, 0, 1), end(3, 0, 1, false) });
    try fixture(std.testing.allocator, &.{ begin, end(1, 0, 0, false) });
}
test "truncation and missing initial record are rejected" {
    try std.testing.expectError(error.MissingProfileEnd, fixture(std.testing.allocator, &.{begin}));
    var e = end(0, 0, 0, true);
    try std.testing.expectError(error.MissingProfileBegin, fixture(std.testing.allocator, &.{e}));
    e = event(1, "function_begin", "f");
    try std.testing.expectError(error.MissingProfileEnd, fixture(std.testing.allocator, &.{ begin, e }));
}
test "schema sequence timestamp and post-completion corruption are rejected" {
    var e = end(1, 0, 0, true);
    e.schema = "wrong";
    try std.testing.expectError(error.InvalidSchema, fixture(std.testing.allocator, &.{ begin, e }));
    e = end(2, 0, 0, true);
    try std.testing.expectError(error.InvalidSequence, fixture(std.testing.allocator, &.{ begin, e }));
    e = end(2, 0, 0, true);
    e.elapsed_ns = 0;
    try std.testing.expectError(error.DecreasingTimestamp, fixture(std.testing.allocator, &.{ begin, event(1, "phase", null), e }));
    try std.testing.expectError(error.EventAfterProfileEnd, fixture(std.testing.allocator, &.{ begin, end(1, 0, 0, true), event(2, "phase", null) }));
}
test "overlapping repeated and mismatched functions are rejected" {
    try std.testing.expectError(error.OverlappingFunction, fixture(std.testing.allocator, &.{ begin, event(1, "function_begin", "f"), event(2, "function_begin", "g") }));
    try std.testing.expectError(error.RepeatedFunction, fixture(std.testing.allocator, &.{ begin, event(1, "function_begin", "f"), functionEnd(2, 1, 0), event(3, "function_begin", "f") }));
    var e = functionEnd(2, 1, 0);
    e.details.name = "g";
    try std.testing.expectError(error.UnbalancedFunction, fixture(std.testing.allocator, &.{ begin, event(1, "function_begin", "f"), e }));
}
test "legalizer activity and retry pairs must close before function completion" {
    inline for (.{ "legalizer_begin", "activity_begin", "retry_begin" }) |kind| {
        var e = event(2, kind, "f");
        e.details.stage = "a";
        e.details.name = "a";
        try std.testing.expectError(error.UnbalancedFunction, fixture(std.testing.allocator, &.{ begin, event(1, "function_begin", "f"), e, functionEnd(3, 1, 0) }));
    }
    var lb = event(2, "legalizer_begin", "f");
    lb.details.stage = "a";
    var le = event(3, "legalizer_end", "f");
    le.details.stage = "b";
    try std.testing.expectError(error.UnbalancedLegalizer, fixture(std.testing.allocator, &.{ begin, event(1, "function_begin", "f"), lb, le }));
    var ab = event(2, "activity_begin", "f");
    ab.details.name = "a";
    var ae = event(3, "activity_end", "f");
    ae.details.name = "b";
    try std.testing.expectError(error.UnbalancedActivity, fixture(std.testing.allocator, &.{ begin, event(1, "function_begin", "f"), ab, ae }));
    try std.testing.expectError(error.UnbalancedRetry, fixture(std.testing.allocator, &.{ begin, event(1, "retry_end", null) }));
}
test "counter mismatch and impossible success are rejected" {
    try std.testing.expectError(error.InvalidFunctionOutcome, fixture(std.testing.allocator, &.{ begin, event(1, "function_begin", "f"), functionEnd(2, 1, 1) }));
    try std.testing.expectError(error.ProfileOutcomeMismatch, fixture(std.testing.allocator, &.{ begin, event(1, "function_begin", "f"), functionEnd(2, 1, 0), end(3, 0, 0, true) }));
    try std.testing.expectError(error.InconsistentSuccessFlag, fixture(std.testing.allocator, &.{ begin, event(1, "function_begin", "f"), functionEnd(2, 0, 1), end(3, 0, 1, true) }));
}
test "failure evidence preserves exact function and record offsets" {
    var s = State.init(std.testing.allocator);
    defer s.deinit();
    try s.feed(begin, 0, 100);
    try s.feed(event(1, "function_begin", "f"), 100, 200);
    try s.feed(functionEnd(2, 0, 1), 200, 300);
    try s.feed(end(3, 0, 1, false), 300, 400);
    try s.finish();
    try std.testing.expectEqual(1, s.failures.items.len);
    try std.testing.expectEqualStrings("f", s.failures.items[0].name);
    try std.testing.expectEqual(100, s.failures.items[0].begin_byte_offset);
    try std.testing.expectEqual(300, s.failures.items[0].end_byte_offset);
    try std.testing.expectEqual(1, s.failures.items[0].begin_sequence);
    try std.testing.expectEqual(2, s.failures.items[0].end_sequence);
}
test "real retry tuple encoding is accepted but populated arrays are rejected" {
    const raw =
        \\{"schema":"compilation-events-v1","sequence":2,"elapsed_ns":2,"event":"retry_begin","function":"f","phase":"select","details":[]}
    ;
    const parsed = try std.json.parseFromSlice(Event, std.testing.allocator, raw, .{ .ignore_unknown_fields = true });
    defer parsed.deinit();
    try fixture(std.testing.allocator, &.{ begin, event(1, "function_begin", "f"), parsed.value, event(3, "retry_end", "f"), functionEnd(4, 1, 0), end(5, 1, 0, true) });
    try std.testing.expectError(error.UnexpectedToken, std.json.parseFromSlice(Details, std.testing.allocator, "[1]", .{}));
}
test "balanced legalizer activity and retry scopes pass together" {
    var lb = event(2, "legalizer_begin", "f");
    lb.details.stage = "stage";
    var le = event(3, "legalizer_end", "f");
    le.details.stage = "stage";
    var ab = event(4, "activity_begin", "f");
    ab.details.name = "activity";
    var ae = event(5, "activity_end", "f");
    ae.details.name = "activity";
    try fixture(std.testing.allocator, &.{ begin, event(1, "function_begin", "f"), lb, le, ab, ae, event(6, "retry_begin", "f"), event(7, "retry_end", "f"), functionEnd(8, 1, 0), end(9, 1, 0, true) });
}
