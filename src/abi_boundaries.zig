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

    pub fn name(self: Category) []const u8 {
        return switch (self) {
            .varargs => "varargs",
            .vector => "vector",
            .x87 => "x87",
            .packed_aggregate => "packed-aggregate",
            .tail_call => "tail-call",
            .non_default_callconv => "callconv",
            .stack_pressure => "stack-pressure",
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

    pub fn add(self: *Counts, category: Category, amount: usize) void {
        switch (category) {
            .varargs => self.varargs_rows += amount,
            .vector => self.vector_rows += amount,
            .x87 => self.x87_rows += amount,
            .packed_aggregate => self.packed_aggregate_rows += amount,
            .tail_call => self.tail_call_rows += amount,
            .non_default_callconv => self.callconv_rows += amount,
            .stack_pressure => self.stack_pressure_rows += amount,
        }
    }
};

pub fn categoryForUnsupported(source: []const u8, diagnostic: air_lowering.Diagnostic) ?Category {
    if (contains(source, "frontier_varargs_boundary.zig") and
        std.mem.eql(u8, diagnostic.opcode, "lowering") and
        diagnostic.reason == .instruction_type)
    {
        return .varargs;
    }
    if (contains(source, "frontier_vector_boundary.zig") and
        std.mem.eql(u8, diagnostic.opcode, "function-type") and
        diagnostic.reason == .function_type)
    {
        return .vector;
    }
    if (contains(source, "frontier_x87_boundary.zig") and
        std.mem.eql(u8, diagnostic.opcode, "function-type") and
        diagnostic.reason == .function_type)
    {
        return .x87;
    }
    if (contains(source, "frontier_stack_pressure_boundary.zig") and
        std.mem.eql(u8, diagnostic.opcode, "function-type") and
        diagnostic.reason == .function_type)
    {
        return .stack_pressure;
    }
    if (contains(source, "frontier_tail_call_boundary.zig")) {
        return .tail_call;
    }
    return null;
}

pub fn categoryForAirExportFailure(source: []const u8, stderr: []const u8) ?Category {
    if (contains(source, "frontier_packed_aggregate_boundary.zig") and
        contains(stderr, "not allowed in function with calling convention"))
    {
        return .packed_aggregate;
    }
    if (contains(source, "frontier_x87_boundary.zig") and
        (contains(stderr, "not allowed in function with calling convention") or
            contains(stderr, "TODO implement compiler support")))
    {
        return .x87;
    }
    return null;
}

pub fn categoryForLoweringFailure(source: []const u8, err: anyerror) ?Category {
    if (contains(source, "frontier_callconv_boundary.zig") and
        err == error.UnsupportedCallingConvention)
    {
        return .non_default_callconv;
    }
    return null;
}

pub fn categoryForCodegenFailure(source: []const u8, err: anyerror) ?Category {
    return switch (err) {
        error.UnsupportedVarargsAbi => .varargs,
        error.UnsupportedVectorAbi => .vector,
        error.UnsupportedLongDoubleAbi => .x87,
        error.UnsupportedPackedAggregateAbi => .packed_aggregate,
        error.UnsupportedTailCallAbi => .tail_call,
        error.UnsupportedCallConvAbi => .non_default_callconv,
        error.UnsupportedCodegenAbi => if (contains(source, "frontier_stack_pressure_boundary.zig")) .stack_pressure else null,
        else => null,
    };
}

pub fn rowCountForSource(source: []const u8) usize {
    if (contains(source, "frontier_packed_aggregate_boundary.zig")) return 2;
    if (contains(source, "frontier_x87_boundary.zig")) return 2;
    return 1;
}

fn contains(haystack: []const u8, needle: []const u8) bool {
    return std.mem.indexOf(u8, haystack, needle) != null;
}

test "frontier ABI boundary metadata names diagnostics" {
    try std.testing.expectEqualStrings("varargs", Category.varargs.name());
    try std.testing.expectEqualStrings("UnsupportedVectorAbi", Category.vector.diagnosticName());
    try std.testing.expectEqualStrings("packed-aggregate", Category.packed_aggregate.name());
}

test "frontier ABI boundary counts update by category" {
    var counts: Counts = .{};
    counts.add(.varargs, 2);
    counts.add(.non_default_callconv, 1);
    counts.add(.stack_pressure, 3);

    try std.testing.expectEqual(@as(usize, 2), counts.varargs_rows);
    try std.testing.expectEqual(@as(usize, 1), counts.callconv_rows);
    try std.testing.expectEqual(@as(usize, 3), counts.stack_pressure_rows);
    try std.testing.expectEqual(@as(usize, 0), counts.vector_rows);
}

test "frontier ABI boundary source row counts are explicit" {
    try std.testing.expectEqual(@as(usize, 2), rowCountForSource("test/zig/frontier/frontier_x87_boundary.zig"));
    try std.testing.expectEqual(@as(usize, 2), rowCountForSource("test/zig/frontier/frontier_packed_aggregate_boundary.zig"));
    try std.testing.expectEqual(@as(usize, 1), rowCountForSource("test/zig/frontier/frontier_vector_boundary.zig"));
}
