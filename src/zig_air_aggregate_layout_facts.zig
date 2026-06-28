const std = @import("std");

pub const Match = enum {
    exact,
    basename,
};

pub const Evidence = struct {
    construction: bool = false,
    store: bool = false,
    load: bool = false,
};

pub const Fact = struct {
    name: []const u8,
    aggregate_text: []const u8,
    match: Match = .basename,
    evidence: Evidence = .{
        .construction = true,
        .store = true,
        .load = true,
    },
};

const facts = [_]Fact{
    .{ .name = "aggregate_abi.Pair", .aggregate_text = "{ i32, i32 }", .match = .exact },
    .{ .name = "runtime_aggregate_pair_main.Pair", .aggregate_text = "{ i32, i32 }", .match = .exact },
    .{ .name = "expanded_abi_frontier.Pair", .aggregate_text = "{ i32, i32 }", .match = .exact },
    .{ .name = "Pair64", .aggregate_text = "{ i64, i64 }" },
    .{ .name = "BigNested", .aggregate_text = "{ { i64, i64, i64 }, { i64, i64, i64 } }" },
    .{ .name = "BigMixed", .aggregate_text = "{ i64, i32, i64, i32 }" },
    .{ .name = "BigArray", .aggregate_text = "{ [5 x i64] }" },
    .{ .name = "BigDoubleArray", .aggregate_text = "{ [3 x double] }" },
    .{ .name = "BigFloatArray", .aggregate_text = "{ [5 x float] }" },
    .{ .name = "BigPtrDouble", .aggregate_text = "{ ptr, double, i64 }" },
    .{ .name = "BigPtrFloat", .aggregate_text = "{ ptr, float, i64 }" },
    .{ .name = "BigArrayMixed", .aggregate_text = "{ [2 x i32], [2 x double], ptr }" },
    .{ .name = "BigNestedArrayMixed", .aggregate_text = "{ { [5 x float] }, { [3 x double] }, ptr, i64 }" },
    .{ .name = "MixedArrayLeaf", .aggregate_text = "{ i32, double }" },
    .{ .name = "BigStructArrayMixed", .aggregate_text = "{ [3 x { i32, double }], i64 }" },
    .{ .name = "BigDeepMixed", .aggregate_text = "{ { { [5 x float] }, { [3 x double] }, ptr, i64 }, [2 x { i32, double }], { { i8, i16 }, i32, double, ptr }, [2 x ptr], i32 }" },
    .{ .name = "BigByteTail", .aggregate_text = "{ [17 x i8] }" },
    .{ .name = "BigByteTail5", .aggregate_text = "{ [21 x i8] }" },
    .{ .name = "BigByteTail6", .aggregate_text = "{ [22 x i8] }" },
    .{ .name = "BigByteTail7", .aggregate_text = "{ [23 x i8] }" },
    .{ .name = "BigWordTail", .aggregate_text = "{ [9 x i16] }" },
    .{ .name = "ScalarMixed", .aggregate_text = "{ i8, i16, i32, i64, ptr, float, double }" },
    .{ .name = "ScalarNestedInner", .aggregate_text = "{ i8, i16 }" },
    .{ .name = "ScalarNested", .aggregate_text = "{ { i8, i16 }, i32, double, ptr }" },
    .{ .name = "ScalarArray", .aggregate_text = "{ [3 x i32], [2 x double], ptr }" },
};

pub fn lookup(nominal: []const u8) ?Fact {
    const normalized = stripNominalSigil(std.mem.trim(u8, nominal, " "));
    for (facts) |fact| {
        if (factMatches(normalized, fact)) return fact;
    }
    return null;
}

pub fn count() usize {
    return facts.len;
}

pub fn all() []const Fact {
    return facts[0..];
}

fn factMatches(nominal: []const u8, fact: Fact) bool {
    return switch (fact.match) {
        .exact => std.mem.eql(u8, nominal, fact.name),
        .basename => std.mem.eql(u8, typeBasename(nominal), fact.name),
    };
}

fn typeBasename(text: []const u8) []const u8 {
    const trimmed = stripNominalSigil(std.mem.trim(u8, text, " "));
    if (std.mem.lastIndexOfScalar(u8, trimmed, '.')) |dot| return trimmed[dot + 1 ..];
    return trimmed;
}

fn stripNominalSigil(text: []const u8) []const u8 {
    if (text.len != 0 and (text[0] == '%' or text[0] == '@')) return text[1..];
    return text;
}

test "aggregate layout facts keep exact pair ownership narrow" {
    try std.testing.expect(lookup("aggregate_abi.Pair") != null);
    try std.testing.expect(lookup("%runtime_aggregate_pair_main.Pair") != null);
    try std.testing.expect(lookup("other.Pair") == null);
}
