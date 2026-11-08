const std = @import("std");
const identifiers = @import("../ir/identifiers.zig");
const ir = @import("../ir.zig");

test "quoted symbol module verification shares canonical definition and call identity" {
    for ([_][]const u8{
        "@plain = global i64 1\n@\"pla\\69n\" = global i64 2\n",
        "@plain = global i64 1\n@\"pla\\69n\" = alias i64, ptr @plain\n",
        "declare i64 @plain()\ndeclare i64 @\"pla\\69n\"()\n",
        "define i64 @plain() {\nentry:\n ret i64 1\n}\ndefine i64 @\"pla\\69n\"() {\nentry:\n ret i64 2\n}\n",
    }) |source| {
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        try std.testing.expectError(error.DuplicateDefinition, module.verify());
    }
    var module = try ir.Module.parse(std.testing.allocator,
        \\@"indirect,alias" = alias i64, ptr @"pla\69n"
        \\@plain = global i64 1
        \\@pointer = constant ptr @"indirect,ali\61s"
        \\declare i64 @"consume"(i64)
        \\define i64 @entry() {
        \\entry:
        \\ %r = call i64 @"cons\75me"(i64 3)
        \\ ret i64 %r
        \\}
    );
    defer module.deinit();
    try module.verify();
    module.functions.items[0].blocks.items[0].instructions.items[0].kind.call.args.items[0].ty = .{ .int = 32 };
    try std.testing.expectError(error.CallSignatureMismatch, module.verify());
}

test "indexed identifier suffixes preserve canonical spelling and escaped identity" {
    for ([_][]const u8{ "tmp_12", "\"tmp_12\"", "\"\\74mp_\\31\\32\"" }) |name|
        try std.testing.expectEqual(@as(?usize, 12), identifiers.indexedSuffix(name, "tmp_"));
    try std.testing.expectEqual(@as(?usize, 0), identifiers.indexedSuffix("tmp_0", "tmp_"));
    for ([_][]const u8{ "tmp_", "tmp_00", "tmp_01", "tmp_-1", "tmp_+1", "tmp_1x", "tmp_1 ", "\"tmp_\\00\"", "\"tmp_\\q1\"", "\"tmp_1\"x", "tmp_184467440737095516160", "12" }) |name|
        try std.testing.expectEqual(@as(?usize, null), identifiers.indexedSuffix(name, "tmp_"));
}

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
        const context: identifiers.Context = .{};
        try std.testing.expectEqual(context.hash(pair[0]), context.hash(pair[1]));
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

test "identifier identity preserves spelling classes across ordered comparisons" {
    const groups = [_][]const []const u8{
        &.{ "helper", "\"helper\"", "\"hel\\70er\"" },
        &.{ "helpers", "\"helpers\"" },
        &.{ "a.b", "\"a\\2Eb\"", "\"a\\2eb\"" },
        &.{ "-.$_", "\"-.$_\"", "\"\\2D.\\24_\"" },
        &.{ "__zllvm_scalar_form_0", "\"__zllvm_scalar_form_0\"", "\"__zllvm_scalar_form_\\30\"" },
        &.{ "__zllvm_scalar_form_00", "\"__zllvm_scalar_form_00\"" },
        &.{ "0", "00", "000" },
        &.{ "17", "0017" },
        &.{ "4294967295", "0004294967295" },
        &.{ "\"0\"", "\"\\30\"" },
        &.{ "\"00\"", "\"\\30\\30\"" },
        &.{ "\"17\"", "\"\\31\\37\"" },
        &.{ "\"0017\"", "\"00\\31\\37\"" },
        &.{ "\"a b\"", "\"a\\20b\"" },
        &.{ "\"a\\22b\"", "\"\\61\\22b\"" },
        &.{ "\"a\\5Cb\"", "\"a\\5cb\"" },
        &.{ "\"\\0A\"", "\"\\0a\"" },
        &.{ "\"\xc3\xa9\"", "\"\\C3\\a9\"" },
    };
    for (groups, 0..) |left_group, left_id| {
        for (left_group) |left| {
            try std.testing.expect(identifiers.isValid(left));
            for (groups, 0..) |right_group, right_id| {
                for (right_group) |right|
                    try std.testing.expectEqual(left_id == right_id, identifiers.eql(left, right));
            }
        }
    }
}

test "identifier identity rejects unsupported or malformed spellings before comparing" {
    for ([_][]const u8{
        "",                "@foo",                "%foo",                 "3name",           "foo bar",    "4294967296",  "\"\"",
        "\"unfinished",    "\"closed\"trailing",  "\"unescaped\"quote\"", "\"bad\\q\"",      "\"bad\\0\"", "\"bad\\zz\"", "\"bad\\+1\"",
        "\"line\nbreak\"", "\"embedded\\00nul\"", "\"raw\x00nul\"",       "\"raw\rreturn\"", "\"bad\\\"",  "foo\x00",     "foo\r",
        "foo\n",           "\xc3\xa9",            "0004294967296",        "17x",
    }) |name| {
        try std.testing.expect(!identifiers.isValid(name));
        try std.testing.expect(!identifiers.eql(name, name));
        try std.testing.expect(!identifiers.eql(name, "unrelated"));
        try std.testing.expect(!identifiers.eql("unrelated", name));
        try std.testing.expect(!identifiers.eql(name, "\"unrelated\""));
        try std.testing.expect(!identifiers.eql("\"unrelated\"", name));
    }
}
