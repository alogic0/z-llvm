const std = @import("std");
const ir = @import("../ir.zig");

pub const Category = enum {
    zero,
    negative_zero,
    nan,
    infinity,
    normal,
    subnormal,
};

pub const Classification = struct {
    ty: ir.Type,
    spelling: []const u8,
    category: Category,
    negative: bool = false,
};

pub fn classify(ty: ir.Type, spelling: []const u8) !Classification {
    switch (ty) {
        .half, .float, .double, .x86_fp80, .fp128 => {},
        else => return error.UnsupportedFloatingPointType,
    }

    const text = std.mem.trim(u8, spelling, " \t");
    if (text.len == 0) return error.InvalidFloatingPointLiteral;

    if (std.mem.eql(u8, text, "nan") or std.mem.eql(u8, text, "+nan")) {
        return .{ .ty = ty, .spelling = spelling, .category = .nan };
    }
    if (std.mem.eql(u8, text, "-nan")) {
        return .{ .ty = ty, .spelling = spelling, .category = .nan, .negative = true };
    }
    if (isKnownNanHexSpelling(text)) {
        return .{
            .ty = ty,
            .spelling = spelling,
            .category = .nan,
            .negative = std.mem.startsWith(u8, text, "-"),
        };
    }
    if (std.mem.eql(u8, text, "inf") or std.mem.eql(u8, text, "+inf")) {
        return .{ .ty = ty, .spelling = spelling, .category = .infinity };
    }
    if (std.mem.eql(u8, text, "-inf")) {
        return .{ .ty = ty, .spelling = spelling, .category = .infinity, .negative = true };
    }
    if (isNegativeZeroSpelling(text)) {
        return .{ .ty = ty, .spelling = spelling, .category = .negative_zero, .negative = true };
    }
    if (isPositiveZeroSpelling(text)) {
        return .{ .ty = ty, .spelling = spelling, .category = .zero };
    }
    if (isKnownSubnormalHexSpelling(text)) {
        return .{
            .ty = ty,
            .spelling = spelling,
            .category = .subnormal,
            .negative = std.mem.startsWith(u8, text, "-"),
        };
    }

    if (!looksLikeFpLiteral(text)) return error.InvalidFloatingPointLiteral;
    return .{
        .ty = ty,
        .spelling = spelling,
        .category = .normal,
        .negative = std.mem.startsWith(u8, text, "-"),
    };
}

pub fn looksLikeFpLiteral(text: []const u8) bool {
    return std.mem.eql(u8, text, "nan") or
        std.mem.eql(u8, text, "+nan") or
        std.mem.eql(u8, text, "-nan") or
        std.mem.eql(u8, text, "inf") or
        std.mem.eql(u8, text, "+inf") or
        std.mem.eql(u8, text, "-inf") or
        std.mem.indexOfAny(u8, text, ".eE") != null or
        std.mem.startsWith(u8, text, "0x") or
        std.mem.startsWith(u8, text, "-0x") or
        std.mem.startsWith(u8, text, "+0x");
}

pub fn halfLiteralBits(spelling: []const u8) !u16 {
    const text = std.mem.trim(u8, spelling, " \t");
    if (text.len != 7 or !std.mem.startsWith(u8, text, "0xH")) return error.InvalidFloatingPointLiteral;
    return std.fmt.parseInt(u16, text[3..], 16) catch error.InvalidFloatingPointLiteral;
}

pub fn isHalfZeroLiteral(spelling: []const u8) bool {
    const bits = halfLiteralBits(spelling) catch return false;
    return bits & 0x7fff == 0;
}

fn isPositiveZeroSpelling(text: []const u8) bool {
    return std.mem.eql(u8, text, "0.0") or
        std.mem.eql(u8, text, "+0.0") or
        std.mem.eql(u8, text, "0.000000e+00") or
        std.mem.eql(u8, text, "+0.000000e+00") or
        std.mem.eql(u8, text, "0x0000000000000000");
}

fn isNegativeZeroSpelling(text: []const u8) bool {
    return std.mem.eql(u8, text, "-0.0") or
        std.mem.eql(u8, text, "-0.000000e+00") or
        std.mem.eql(u8, text, "-0x0000000000000000") or
        std.mem.eql(u8, text, "0x8000000000000000");
}

fn isKnownSubnormalHexSpelling(text: []const u8) bool {
    const unsigned = if (std.mem.startsWith(u8, text, "-") or std.mem.startsWith(u8, text, "+")) text[1..] else text;
    return std.mem.eql(u8, unsigned, "0x0000000000000001") or
        std.mem.eql(u8, unsigned, "0x000FFFFFFFFFFFFF") or
        std.mem.eql(u8, unsigned, "0x00000001");
}

fn isKnownNanHexSpelling(text: []const u8) bool {
    const unsigned = if (std.mem.startsWith(u8, text, "-") or std.mem.startsWith(u8, text, "+")) text[1..] else text;
    return std.mem.eql(u8, unsigned, "0x7FF8000000000000") or
        std.mem.eql(u8, unsigned, "0xFFF8000000000000") or
        std.mem.eql(u8, unsigned, "0x7FC00000") or
        std.mem.eql(u8, unsigned, "0xFFC00000");
}
