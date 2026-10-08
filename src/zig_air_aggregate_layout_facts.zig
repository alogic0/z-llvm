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
    .{
        .name = "BiasedFp(f64)",
        .aggregate_text = "{ i64, i32 }",
        .match = .basename,
        .evidence = .{
            .construction = true,
            .store = true,
            .load = true,
        },
    },
    .{
        .name = "BiasedFp(f32)",
        .aggregate_text = "{ i32, i32 }",
        .match = .basename,
        .evidence = .{
            .construction = true,
            .store = true,
            .load = true,
        },
    },
    .{
        .name = "PartIterator",
        .aggregate_text = "{ i32, i5 }",
        .match = .basename,
        .evidence = .{
            .construction = true,
            .store = true,
            .load = true,
        },
    },
    .{
        .name = "Progress.Node",
        .aggregate_text = "{ i8 }",
        .match = .exact,
        .evidence = .{
            .construction = true,
            .store = true,
            .load = true,
        },
    },
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
    try std.testing.expectEqual(@as(usize, 4), count());
    try std.testing.expect(lookup("aggregate_abi.Pair") == null);
    try std.testing.expect(lookup("%runtime_aggregate_pair_main.Pair") == null);
    try std.testing.expect(lookup("other.Pair") == null);
    try std.testing.expect(lookup("fmt.parse_float.common.BiasedFp(f64)") != null);
    try std.testing.expect(lookup("fmt.parse_float.common.BiasedFp(f32)") != null);
    try std.testing.expect(lookup("codegen.aarch64.Select.Value.PartIterator") != null);
    try std.testing.expect(lookup("Progress.Node") != null);
}
