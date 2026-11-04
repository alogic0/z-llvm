const std = @import("std");
const identifiers = @import("../ir/identifiers.zig");

test "identifier identity decodes complete quoted and escaped names" {
    const pairs = [_][2][]const u8{
        .{ "helper", "\"hel\\70er\"" },
        .{ "a.b", "\"a\\2Eb\"" },
        .{ "\"a\\2eb\"", "\"a.b\"" },
        .{ "\"a b\"", "\"a\\20b\"" },
        .{ "\"a\\22b\"", "\"\\61\\22b\"" },
        .{ "\"a\\5Cb\"", "\"a\\5cb\"" },
        .{ "-1", "\"-1\"" },
        .{ "0", "000" },
        .{ "17", "0017" },
    };
    for (pairs) |pair| {
        try std.testing.expect(identifiers.isValid(pair[0]));
        try std.testing.expect(identifiers.isValid(pair[1]));
        try std.testing.expect(identifiers.eql(pair[0], pair[1]));
        try std.testing.expect(identifiers.eql(pair[1], pair[0]));
    }
}

test "identifier identity keeps numeric slots distinct from quoted numeric names" {
    try std.testing.expect(!identifiers.eql("0", "\"0\""));
    try std.testing.expect(!identifiers.eql("\"0\"", "00"));
    try std.testing.expect(identifiers.eql("\"0\"", "\"\\30\""));
    try std.testing.expect(!identifiers.eql("foo", "foobar"));
    try std.testing.expect(!identifiers.eql("foo", "\"fo\\00o\""));
    try std.testing.expect(!identifiers.eql("\"foo\"", "\"bar\""));
}

test "identifier identity rejects unsupported or malformed spellings before comparing" {
    for ([_][]const u8{
        "",                "@foo",                "%foo",                 "3name",      "foo bar",    "4294967296",  "\"\"",
        "\"unfinished",    "\"closed\"trailing",  "\"unescaped\"quote\"", "\"bad\\q\"", "\"bad\\0\"", "\"bad\\zz\"", "\"bad\\+1\"",
        "\"line\nbreak\"", "\"embedded\\00nul\"",
    }) |name| {
        try std.testing.expect(!identifiers.isValid(name));
        try std.testing.expect(!identifiers.eql(name, name));
        try std.testing.expect(!identifiers.eql(name, "unrelated"));
    }
}
