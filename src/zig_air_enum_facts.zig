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

const facts = [_]Fact{
    .{
        .name = "Io.Event",
        .backing_type = .{ .int = 32 },
        .enumerators = io_event_enumerators[0..],
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
}
