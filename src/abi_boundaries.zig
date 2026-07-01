const std = @import("std");
const air_lowering = @import("zig_air_lowering.zig");

pub const Category = enum {
    varargs,
    vector,
    x87,
    packed_aggregate,
    tail_call,
    non_default_callconv,
    stack_pressure,
    safety_edge,
    pointer_slice,

    pub fn name(self: Category) []const u8 {
        return switch (self) {
            .varargs => "varargs",
            .vector => "vector",
            .x87 => "x87",
            .packed_aggregate => "packed-aggregate",
            .tail_call => "tail-call",
            .non_default_callconv => "callconv",
            .stack_pressure => "stack-pressure",
            .safety_edge => "safety-edge",
            .pointer_slice => "pointer-slice",
        };
    }

    pub fn diagnosticName(self: Category) []const u8 {
        return switch (self) {
            .varargs => "UnsupportedVarargsAbi",
            .vector => "UnsupportedVectorAbi",
            .x87 => "UnsupportedLongDoubleAbi",
            .packed_aggregate => "UnsupportedPackedAggregateAbi",
            .tail_call => "UnsupportedTailCallAbi",
            .non_default_callconv => "UnsupportedCallConvAbi",
            .stack_pressure => "UnsupportedCodegenAbi",
            .safety_edge => "UnsupportedCodegenControlFlow",
            .pointer_slice => "UnsupportedPointerSliceAbi",
        };
    }

    pub fn errorValue(self: Category) anyerror {
        return switch (self) {
            .varargs => error.UnsupportedVarargsAbi,
            .vector => error.UnsupportedVectorAbi,
            .x87 => error.UnsupportedLongDoubleAbi,
            .packed_aggregate => error.UnsupportedPackedAggregateAbi,
            .tail_call => error.UnsupportedTailCallAbi,
            .non_default_callconv => error.UnsupportedCallConvAbi,
            .stack_pressure => error.UnsupportedCodegenAbi,
            .safety_edge => error.UnsupportedCodegenControlFlow,
            .pointer_slice => error.UnsupportedPointerSliceAbi,
        };
    }
};

pub const Counts = struct {
    varargs_rows: usize = 0,
    vector_rows: usize = 0,
    x87_rows: usize = 0,
    packed_aggregate_rows: usize = 0,
    tail_call_rows: usize = 0,
    callconv_rows: usize = 0,
    stack_pressure_rows: usize = 0,
    safety_edge_rows: usize = 0,
    pointer_slice_rows: usize = 0,

    pub fn add(self: *Counts, category: Category, amount: usize) void {
        switch (category) {
            .varargs => self.varargs_rows += amount,
            .vector => self.vector_rows += amount,
            .x87 => self.x87_rows += amount,
            .packed_aggregate => self.packed_aggregate_rows += amount,
            .tail_call => self.tail_call_rows += amount,
            .non_default_callconv => self.callconv_rows += amount,
            .stack_pressure => self.stack_pressure_rows += amount,
            .safety_edge => self.safety_edge_rows += amount,
            .pointer_slice => self.pointer_slice_rows += amount,
        }
    }

    pub fn eql(self: Counts, other: Counts) bool {
        return self.varargs_rows == other.varargs_rows and
            self.vector_rows == other.vector_rows and
            self.x87_rows == other.x87_rows and
            self.packed_aggregate_rows == other.packed_aggregate_rows and
            self.tail_call_rows == other.tail_call_rows and
            self.callconv_rows == other.callconv_rows and
            self.stack_pressure_rows == other.stack_pressure_rows and
            self.safety_edge_rows == other.safety_edge_rows and
            self.pointer_slice_rows == other.pointer_slice_rows;
    }
};

pub const ExpectedSummary = struct {
    source_rows: usize,
    discovered_functions: usize,
    counts: Counts,

    pub fn matches(
        self: ExpectedSummary,
        source_rows: usize,
        discovered_functions: usize,
        counts: Counts,
    ) bool {
        return self.source_rows == source_rows and
            self.discovered_functions == discovered_functions and
            self.counts.eql(counts);
    }
};

const SourceBoundary = struct {
    source_fragment: []const u8,
    category: Category,
    expected_rows: usize,
    source_failure_rows: usize = 1,
};

const source_boundaries = [_]SourceBoundary{
    .{ .source_fragment = "frontier_varargs_boundary.zig", .category = .varargs, .expected_rows = 2 },
    .{ .source_fragment = "frontier_vector_boundary.zig", .category = .vector, .expected_rows = 2 },
    .{ .source_fragment = "frontier_x87_boundary.zig", .category = .x87, .expected_rows = 2, .source_failure_rows = 2 },
    .{ .source_fragment = "frontier_packed_aggregate_boundary.zig", .category = .packed_aggregate, .expected_rows = 2, .source_failure_rows = 2 },
    .{ .source_fragment = "frontier_tail_call_boundary.zig", .category = .tail_call, .expected_rows = 1 },
    .{ .source_fragment = "frontier_callconv_boundary.zig", .category = .non_default_callconv, .expected_rows = 1 },
    .{ .source_fragment = "frontier_pointer_slice_boundary.zig", .category = .pointer_slice, .expected_rows = 2 },
};

fn sourceBoundary(source: []const u8) ?SourceBoundary {
    for (source_boundaries) |boundary| {
        if (contains(source, boundary.source_fragment)) return boundary;
    }
    return null;
}

pub fn expectedFrontierBoundarySummary() ExpectedSummary {
    var counts: Counts = .{};
    for (source_boundaries) |boundary| counts.add(boundary.category, boundary.expected_rows);
    return .{
        .source_rows = source_boundaries.len,
        .discovered_functions = 12,
        .counts = counts,
    };
}

pub fn categoryForUnsupported(source: []const u8, diagnostic: air_lowering.Diagnostic) ?Category {
    const boundary = sourceBoundary(source) orelse return null;
    switch (boundary.category) {
        .varargs => if (std.mem.eql(u8, diagnostic.opcode, "lowering") and
            diagnostic.reason == .instruction_type) return .varargs,
        .vector, .x87, .stack_pressure => if (std.mem.eql(u8, diagnostic.opcode, "function-type") and
            diagnostic.reason == .function_type) return boundary.category,
        .tail_call => return .tail_call,
        .pointer_slice => if (std.mem.eql(u8, diagnostic.opcode, "atomic_load") and
            diagnostic.reason == .opcode) return .pointer_slice,
        .packed_aggregate, .non_default_callconv, .safety_edge => {},
    }
    return null;
}

pub fn categoryForAirExportFailure(source: []const u8, stderr: []const u8) ?Category {
    const boundary = sourceBoundary(source) orelse return null;
    switch (boundary.category) {
        .packed_aggregate => if (contains(stderr, "not allowed in function with calling convention")) return .packed_aggregate,
        .x87 => if (contains(stderr, "not allowed in function with calling convention") or
            contains(stderr, "TODO implement compiler support")) return .x87,
        else => {},
    }
    return null;
}

pub fn categoryForLoweringFailure(source: []const u8, err: anyerror) ?Category {
    const boundary = sourceBoundary(source) orelse return null;
    if (boundary.category == .non_default_callconv and err == error.UnsupportedCallingConvention) return .non_default_callconv;
    return null;
}

pub fn categoryForCodegenFailure(source: []const u8, err: anyerror) ?Category {
    const boundary = sourceBoundary(source);
    return switch (err) {
        error.UnsupportedVarargsAbi => .varargs,
        error.UnsupportedVectorAbi => .vector,
        error.UnsupportedLongDoubleAbi => .x87,
        error.UnsupportedPackedAggregateAbi => .packed_aggregate,
        error.UnsupportedTailCallAbi => .tail_call,
        error.UnsupportedCallConvAbi => .non_default_callconv,
        error.UnsupportedCodegenControlFlow => if (boundary) |entry|
            switch (entry.category) {
                .safety_edge => .safety_edge,
                .pointer_slice => .pointer_slice,
                else => null,
            }
        else
            null,
        error.UnsupportedCodegenInstruction => if (boundary) |entry|
            switch (entry.category) {
                .pointer_slice => .pointer_slice,
                .tail_call => .tail_call,
                else => null,
            }
        else
            null,
        error.UnsupportedCodegenAbi => if (boundary) |entry|
            if (entry.category == .stack_pressure) .stack_pressure else null
        else
            null,
        else => null,
    };
}

pub fn rowCountForSource(source: []const u8) usize {
    return if (sourceBoundary(source)) |boundary| boundary.source_failure_rows else 1;
}

fn contains(haystack: []const u8, needle: []const u8) bool {
    return std.mem.indexOf(u8, haystack, needle) != null;
}

test "frontier ABI boundary metadata names diagnostics" {
    try std.testing.expectEqualStrings("varargs", Category.varargs.name());
    try std.testing.expectEqualStrings("UnsupportedVectorAbi", Category.vector.diagnosticName());
    try std.testing.expectEqualStrings("packed-aggregate", Category.packed_aggregate.name());
    try std.testing.expectEqualStrings("pointer-slice", Category.pointer_slice.name());
    try std.testing.expectEqual(error.UnsupportedLongDoubleAbi, Category.x87.errorValue());
    try std.testing.expectEqualStrings("UnsupportedCodegenControlFlow", Category.safety_edge.diagnosticName());
    try std.testing.expectEqualStrings("UnsupportedPointerSliceAbi", Category.pointer_slice.diagnosticName());
}

test "frontier ABI boundary counts update by category" {
    var counts: Counts = .{};
    counts.add(.varargs, 2);
    counts.add(.non_default_callconv, 1);
    counts.add(.stack_pressure, 3);
    counts.add(.safety_edge, 1);
    counts.add(.pointer_slice, 1);

    try std.testing.expectEqual(@as(usize, 2), counts.varargs_rows);
    try std.testing.expectEqual(@as(usize, 1), counts.callconv_rows);
    try std.testing.expectEqual(@as(usize, 3), counts.stack_pressure_rows);
    try std.testing.expectEqual(@as(usize, 1), counts.safety_edge_rows);
    try std.testing.expectEqual(@as(usize, 1), counts.pointer_slice_rows);
    try std.testing.expectEqual(@as(usize, 0), counts.vector_rows);
    try std.testing.expect(counts.eql(.{
        .varargs_rows = 2,
        .callconv_rows = 1,
        .stack_pressure_rows = 3,
        .safety_edge_rows = 1,
        .pointer_slice_rows = 1,
    }));
}

test "frontier ABI boundary expected summary is registry-owned" {
    const expected = expectedFrontierBoundarySummary();
    try std.testing.expectEqual(@as(usize, 7), expected.source_rows);
    try std.testing.expectEqual(@as(usize, 12), expected.discovered_functions);
    try std.testing.expectEqual(@as(usize, 2), expected.counts.varargs_rows);
    try std.testing.expectEqual(@as(usize, 1), expected.counts.tail_call_rows);
    try std.testing.expectEqual(@as(usize, 0), expected.counts.safety_edge_rows);
    try std.testing.expectEqual(@as(usize, 2), expected.counts.pointer_slice_rows);
    try std.testing.expect(expected.matches(7, 12, expected.counts));
    try std.testing.expect(!expected.matches(7, 11, expected.counts));
}

test "frontier ABI boundary source row counts are explicit" {
    try std.testing.expectEqual(@as(usize, 2), rowCountForSource("test/zig/frontier/frontier_x87_boundary.zig"));
    try std.testing.expectEqual(@as(usize, 2), rowCountForSource("test/zig/frontier/frontier_packed_aggregate_boundary.zig"));
    try std.testing.expectEqual(@as(usize, 1), rowCountForSource("test/zig/frontier/frontier_vector_boundary.zig"));
}
