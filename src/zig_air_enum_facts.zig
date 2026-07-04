const std = @import("std");
const ir = @import("ir.zig");

pub const Enumerator = struct {
    name: []const u8,
    value: i128,
};

pub const Fact = struct {
    name: []const u8,
    backing_type: ir.Type,
    signed: bool = false,
    enumerators: []const Enumerator,
};

const io_event_enumerators = [_]Enumerator{
    .{ .name = "unset", .value = 0 },
    .{ .name = "waiting", .value = 1 },
    .{ .name = "is_set", .value = 2 },
};

const io_limit_enumerators = [_]Enumerator{
    .{ .name = "nothing", .value = 0 },
    .{ .name = "unlimited", .value = std.math.maxInt(u64) },
};

const http_reader_remaining_chunk_len_enumerators = [_]Enumerator{
    .{ .name = "head", .value = 0 },
    .{ .name = "n", .value = 1 },
    .{ .name = "rn", .value = 2 },
};

const zig_ast_optional_token_index_enumerators = [_]Enumerator{
    .{ .name = "none", .value = std.math.maxInt(u32) },
};

const facts = [_]Fact{
    .{
        .name = "Io.Event",
        .backing_type = .{ .int = 32 },
        .enumerators = io_event_enumerators[0..],
    },
    .{
        .name = "Io.Limit",
        .backing_type = .{ .int = 64 },
        .enumerators = io_limit_enumerators[0..],
    },
    .{
        .name = "http.Reader.RemainingChunkLen",
        .backing_type = .{ .int = 64 },
        .enumerators = http_reader_remaining_chunk_len_enumerators[0..],
    },
    .{
        .name = "zig.Ast.OptionalTokenIndex",
        .backing_type = .{ .int = 32 },
        .enumerators = zig_ast_optional_token_index_enumerators[0..],
    },
};

pub fn lookup(nominal: []const u8) ?Fact {
    const normalized = stripNominalSigil(std.mem.trim(u8, nominal, " "));
    for (facts) |fact| {
        if (std.mem.eql(u8, normalized, fact.name)) return fact;
    }
    return null;
}

pub fn enumeratorValue(nominal: []const u8, literal: []const u8) ?i128 {
    const fact = lookup(nominal) orelse return null;
    const trimmed = std.mem.trim(u8, literal, " ");
    if (trimmed.len < 2 or trimmed[0] != '.') return null;
    const name = trimmed[1..];
    for (fact.enumerators) |enumerator| {
        if (std.mem.eql(u8, name, enumerator.name)) return enumerator.value;
    }
    return null;
}

fn stripNominalSigil(text: []const u8) []const u8 {
    if (text.len != 0 and (text[0] == '%' or text[0] == '@')) return text[1..];
    return text;
}

test "enum facts expose exact nominal backing types and literals" {
    const fact = lookup("Io.Event") orelse return error.TestExpectedEqual;
    try std.testing.expectEqual(ir.Type{ .int = 32 }, fact.backing_type);
    try std.testing.expectEqual(@as(?i128, 0), enumeratorValue("Io.Event", ".unset"));
    try std.testing.expectEqual(@as(?i128, 2), enumeratorValue("Io.Event", ".is_set"));
    try std.testing.expect(enumeratorValue("Event", ".unset") == null);

    const limit = lookup("Io.Limit") orelse return error.TestExpectedEqual;
    try std.testing.expectEqual(ir.Type{ .int = 64 }, limit.backing_type);
    try std.testing.expectEqual(@as(?i128, 0), enumeratorValue("Io.Limit", ".nothing"));

    const chunk_len = lookup("http.Reader.RemainingChunkLen") orelse return error.TestExpectedEqual;
    try std.testing.expectEqual(ir.Type{ .int = 64 }, chunk_len.backing_type);
    try std.testing.expectEqual(@as(?i128, 2), enumeratorValue("http.Reader.RemainingChunkLen", ".rn"));

    const optional_token = lookup("zig.Ast.OptionalTokenIndex") orelse return error.TestExpectedEqual;
    try std.testing.expectEqual(ir.Type{ .int = 32 }, optional_token.backing_type);
    try std.testing.expectEqual(@as(?i128, std.math.maxInt(u32)), enumeratorValue("zig.Ast.OptionalTokenIndex", ".none"));
}
