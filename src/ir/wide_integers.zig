//! Borrowed integer spelling beyond the compact Type/Value payload bounds.
//! This does not widen Source or the public typed-transfer representation.
const std = @import("std");
const core = @import("core.zig");
pub const max_bits = 65536;

pub fn width(ty: core.Type) ?u32 {
    if (ty == .int) return ty.int;
    if (ty != .aggregate or ty.aggregate.len < 2 or ty.aggregate[0] != 'i') return null;
    const bits = std.fmt.parseUnsigned(u32, ty.aggregate[1..], 10) catch return null;
    return if (bits > std.math.maxInt(u16) and bits <= max_bits) bits else null;
}

pub fn decimal(text: []const u8) bool {
    const digits = if (text.len != 0 and text[0] == '-') text[1..] else text;
    if (digits.len == 0) return false;
    for (digits) |byte| if (!std.ascii.isDigit(byte)) return false;
    return true;
}

/// Separate the signed payload range from borrowed wide literals before a
/// decimal multiplication can discard a high bit.
pub fn parseCompact(text: []const u8) std.fmt.ParseIntError!i128 {
    const max: u128 = std.math.maxInt(i128);
    const decimal_digits = std.fmt.comptimePrint("{d}", .{max}).len;
    if (text.len < decimal_digits) return std.fmt.parseInt(i128, text, 10);

    const negative = text[0] == '-';
    const digits = if (negative or text[0] == '+') text[1..] else text;
    if (digits[0] == '_' or digits[digits.len - 1] == '_') return error.InvalidCharacter;
    const last_digit = @as(u8, max % 10) + @intFromBool(negative);
    var magnitude: u128 = 0;
    for (digits) |byte| {
        if (byte == '_') continue;
        if (!std.ascii.isDigit(byte)) return error.InvalidCharacter;
        const digit = byte - '0';
        if (magnitude > max / 10 or (magnitude == max / 10 and digit > last_digit)) return error.Overflow;
        magnitude = magnitude * 10 + digit;
    }
    return @bitCast(if (negative) 0 -% magnitude else magnitude);
}

pub fn decode(a: std.mem.Allocator, bits: u32, value: core.Value) ![]u64 {
    if (bits == 0 or bits > max_bits) return error.UnsupportedWideInteger;
    const words = try a.alloc(u64, (bits + 63) / 64);
    errdefer a.free(words);
    @memset(words, 0);
    switch (value) {
        .undef, .poison, .zero_initializer => {},
        .int => |signed| {
            @memset(words, if (signed < 0) std.math.maxInt(u64) else 0);
            const raw: u128 = @bitCast(signed);
            words[0] = @truncate(raw);
            if (words.len > 1) words[1] = @truncate(raw >> 64);
        },
        .constant_expr => |text| {
            if (!decimal(text)) return error.UnsupportedWideIntegerLiteral;
            const negative = text[0] == '-';
            const digits = if (negative) text[1..] else text;
            for (digits) |digit| {
                var carry: u128 = digit - '0';
                for (words) |*limb| {
                    const product = @as(u128, limb.*) * 10 + carry;
                    limb.* = @truncate(product);
                    carry = product >> 64;
                }
                if (carry != 0) return error.WideIntegerLiteralOverflow;
            }
            if (bits % 64 != 0 and words[words.len - 1] >> @as(u6, @intCast(bits % 64)) != 0) return error.WideIntegerLiteralOverflow;
            if (negative) {
                var carry: u1 = 1;
                for (words) |*limb| {
                    const added = @addWithOverflow(~limb.*, carry);
                    limb.* = added[0];
                    carry = added[1];
                }
            }
        },
        else => return error.UnsupportedWideIntegerLiteral,
    }
    if (bits % 64 != 0) words[words.len - 1] &= (@as(u64, 1) << @as(u6, @intCast(bits % 64))) - 1;
    return words;
}
