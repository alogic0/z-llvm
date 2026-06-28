const std = @import("std");

pub const Boundary = struct {
    name: []const u8,
    aggregate_text: []const u8,
};

const boundaries = [_]Boundary{
    .{ .name = "PackedMixed", .aggregate_text = "{ i32, i32, double }" },
    .{ .name = "PackedReverseMixed", .aggregate_text = "{ double, i32, i32 }" },
};

pub fn lookup(nominal: []const u8) ?Boundary {
    const basename = typeBasename(nominal);
    for (boundaries) |boundary| {
        if (std.mem.eql(u8, basename, boundary.name)) return boundary;
    }
    return null;
}

pub fn count() usize {
    return boundaries.len;
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

test "aggregate layout boundaries classify packed aggregates by basename only" {
    try std.testing.expect(lookup("frontier_aggregate_boundaries.PackedMixed") != null);
    try std.testing.expect(lookup("%PackedReverseMixed") != null);
    try std.testing.expect(lookup("Mixed") == null);
}
