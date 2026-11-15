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
    if (isNegativeZeroSpelling(text) or isNegativeZeroLiteral(ty, text)) {
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

/// Exact scalar LLVM literal representation, shared by data and code lowering.
pub fn scalarLiteralBits(ty: ir.Type, text: []const u8) !u128 {
    if (ty == .half) return try halfLiteralBits(text);
    if (ty == .x86_fp80) {
        if (text.len != 23 or !std.mem.startsWith(u8, text, "0xK")) return error.InvalidFloatingPointLiteral;
        return std.fmt.parseUnsigned(u80, text[3..], 16) catch error.InvalidFloatingPointLiteral;
    }
    if (ty == .fp128) {
        if (std.mem.startsWith(u8, text, "0xL")) {
            if (text.len != 35) return error.InvalidFloatingPointLiteral;
            const lo = std.fmt.parseUnsigned(u64, text[3..19], 16) catch return error.InvalidFloatingPointLiteral;
            const hi = std.fmt.parseUnsigned(u64, text[19..35], 16) catch return error.InvalidFloatingPointLiteral;
            return (@as(u128, hi) << 64) | lo;
        }
        return @bitCast(std.fmt.parseFloat(f128, text) catch return error.InvalidFloatingPointLiteral);
    }
    if (std.mem.startsWith(u8, text, "0x")) {
        if (text.len < 3 or text.len > 18) return error.InvalidFloatingPointLiteral;
        const raw = std.fmt.parseUnsigned(u64, text[2..], 16) catch return error.InvalidFloatingPointLiteral;
        if (ty == .double) return raw;
        if (ty != .float) return error.InvalidFloatingPointLiteral;
        const fraction = raw & 0x000fffffffffffff;
        if (raw & 0x7ff0000000000000 == 0x7ff0000000000000 and fraction != 0) {
            // Copy a representable NaN payload without a floating conversion.
            if (fraction & 0x1fffffff != 0 or fraction >> 29 == 0) return error.InvalidFloatingPointLiteral;
            return ((raw >> 32) & 0x80000000) | 0x7f800000 | (fraction >> 29);
        }
        const wide: f64 = @bitCast(raw);
        const narrow: f32 = @floatCast(wide);
        if (@as(f64, @floatCast(narrow)) != wide) return error.InvalidFloatingPointLiteral;
        return @as(u32, @bitCast(narrow));
    }
    return switch (ty) {
        .float => @as(u32, @bitCast(std.fmt.parseFloat(f32, text) catch return error.InvalidFloatingPointLiteral)),
        .double => @as(u64, @bitCast(std.fmt.parseFloat(f64, text) catch return error.InvalidFloatingPointLiteral)),
        else => error.InvalidFloatingPointLiteral,
    };
}

pub fn isHalfZeroLiteral(spelling: []const u8) bool {
    const bits = halfLiteralBits(spelling) catch return false;
    return bits & 0x7fff == 0;
}

/// Recognize the sign bit alone in a typed LLVM constant. Preserve the older
/// synthetic decimal spelling used by parsed fneg in retained project inputs.
pub fn isNegativeZeroLiteral(ty: ir.Type, spelling: []const u8) bool {
    const width: u8 = switch (ty) {
        .half => 16,
        .float => 32,
        .double => 64,
        .x86_fp80 => 80,
        .fp128 => 128,
        else => return false,
    };
    const text = std.mem.trim(u8, spelling, " \t");
    if (std.mem.eql(u8, text, "-0.000000e+00")) return true;
    const raw = scalarLiteralBits(ty, text) catch return false;
    return raw == @as(u128, 1) << @as(u7, @intCast(width - 1));
}

test "floating negative zero uses exact typed sign bits and rejects nearby payloads" {
    const cases = [_]struct { ty: ir.Type, negative: []const u8, positive: []const u8, adjacent: []const u8 }{
        .{ .ty = .half, .negative = "0xH8000", .positive = "0xH0000", .adjacent = "0xH8001" },
        .{ .ty = .float, .negative = "0x8000000000000000", .positive = "0x0000000000000000", .adjacent = "0xB6A0000000000000" },
        .{ .ty = .double, .negative = "0x8000000000000000", .positive = "0x0000000000000000", .adjacent = "0x8000000000000001" },
        .{ .ty = .x86_fp80, .negative = "0xK80000000000000000000", .positive = "0xK00000000000000000000", .adjacent = "0xK80000000000000000001" },
        .{ .ty = .fp128, .negative = "0xL00000000000000008000000000000000", .positive = "0xL00000000000000000000000000000000", .adjacent = "0xL00000000000000018000000000000000" },
    };
    for (cases) |case| {
        try std.testing.expect(isNegativeZeroLiteral(case.ty, case.negative));
        const classification = try classify(case.ty, case.negative);
        try std.testing.expectEqual(Category.negative_zero, classification.category);
        try std.testing.expect(classification.negative);
        try std.testing.expect(isNegativeZeroLiteral(case.ty, "-0.000000e+00"));
        try std.testing.expect(!isNegativeZeroLiteral(case.ty, case.positive));
        try std.testing.expect(!isNegativeZeroLiteral(case.ty, case.adjacent));
        try std.testing.expect(!isNegativeZeroLiteral(case.ty, "not a constant"));
    }
    try std.testing.expect(!isNegativeZeroLiteral(.{ .int = 80 }, "0xK80000000000000000000"));
    try std.testing.expect(!isNegativeZeroLiteral(.x86_fp80, "0xL00000000000000008000000000000000"));
    try std.testing.expect(!isNegativeZeroLiteral(.fp128, "0xK80000000000000000000"));
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
