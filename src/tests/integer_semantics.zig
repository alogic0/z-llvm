const std = @import("std");
const ir = @import("../ir.zig");
const semantics = @import("../analysis/integer_semantics.zig");
const Integer = semantics.Integer;
const simplify = @import("../passes/inst_simplify.zig").simplify;

// Use a wider mathematical representation as an independent oracle. This
// avoids reproducing the production helper's mask/sign-bit implementation.
fn referenceUnsigned(bits: u16, value: i128) i256 {
    const modulus = @as(i256, 1) << @intCast(bits);
    return @mod(@as(i256, value), modulus);
}

fn referenceSigned(bits: u16, value: i128) i256 {
    const modulus = @as(i256, 1) << @intCast(bits);
    const raw = referenceUnsigned(bits, value);
    return if (raw >= @divExact(modulus, 2)) raw - modulus else raw;
}

fn checkPair(bits: u16, lhs: i128, rhs: i128) !void {
    const integer = Integer.initBits(bits).?;
    const a = referenceSigned(bits, lhs);
    const b = referenceSigned(bits, rhs);
    const ua = referenceUnsigned(bits, lhs);
    const ub = referenceUnsigned(bits, rhs);
    inline for (std.meta.tags(ir.IcmpPredicate)) |predicate| {
        const expected = switch (predicate) {
            .eq => a == b,
            .ne => a != b,
            .sgt => a > b,
            .sge => a >= b,
            .slt => a < b,
            .sle => a <= b,
            .ugt => ua > ub,
            .uge => ua >= ub,
            .ult => ua < ub,
            .ule => ua <= ub,
        };
        try std.testing.expectEqual(expected, integer.compare(predicate, lhs, rhs));
    }
    inline for (std.meta.tags(semantics.DivRem)) |mode| {
        if (b == 0) {
            try std.testing.expectError(error.DivisionByZero, integer.signedDivRem(mode, lhs, rhs, false));
        } else if (a == -(@as(i256, 1) << @intCast(bits - 1)) and b == -1) {
            try std.testing.expectError(error.SignedOverflow, integer.signedDivRem(mode, lhs, rhs, false));
        } else {
            const expected: i128 = @intCast(if (mode == .div) @divTrunc(a, b) else @rem(a, b));
            try std.testing.expectEqual(expected, try integer.signedDivRem(mode, lhs, rhs, false));
            if (@rem(a, b) == 0) {
                try std.testing.expectEqual(expected, try integer.signedDivRem(mode, lhs, rhs, true));
            } else {
                try std.testing.expectError(error.Inexact, integer.signedDivRem(mode, lhs, rhs, true));
            }
        }
    }
}

test "integer semantics: reject unsupported widths and non-scalar types" {
    for ([_]u16{ 0, 129, 256, 65535 }) |bits| try std.testing.expect(Integer.initBits(bits) == null);
    for ([_]ir.Type{ .ptr, .float, .void, .{ .vector = .{ .len = 2, .elem_ty = .{ .int = 32 } } } }) |ty| {
        try std.testing.expect(Integer.init(ty) == null);
    }
    for ([_]u16{ 1, 8, 64, 127, 128 }) |bits| try std.testing.expectEqual(bits, Integer.init(.{ .int = bits }).?.bits);
}

test "integer semantics: exhaustive narrow comparisons and signed divrem" {
    for (1..9) |bits_usize| {
        const bits: u16 = @intCast(bits_usize);
        const limit = @as(usize, 1) << @intCast(bits);
        for (0..limit) |lhs| {
            for (0..limit) |rhs| {
                try checkPair(bits, @intCast(lhs), @intCast(rhs));
            }
        }
    }
}

test "integer semantics: wide signed and unsigned spellings normalize identically" {
    for ([_]u16{ 1, 7, 8, 16, 32, 64, 127, 128 }) |bits| {
        const integer = Integer.initBits(bits).?;
        const min: i128 = @intCast(-(@as(i256, 1) << @intCast(bits - 1)));
        const max: i128 = @intCast((@as(i256, 1) << @intCast(bits - 1)) - 1);
        const values = [_]i128{ 0, 1, -1, min, max, min + 1, std.math.minInt(i128), std.math.maxInt(i128) };
        for (values) |lhs| {
            try std.testing.expectEqual(@as(i128, @intCast(referenceSigned(bits, lhs))), integer.normalize(lhs));
            try std.testing.expectEqual(@as(u128, @intCast(referenceUnsigned(bits, lhs))), integer.unsigned(lhs));
            for (values) |rhs| try checkPair(bits, lhs, rhs);
        }
        if (bits < 128) {
            // Positive spellings of negative bit patterns still fit i128 here.
            const unsigned_min: i128 = @intCast(referenceUnsigned(bits, min));
            const unsigned_ones: i128 = @intCast(referenceUnsigned(bits, -1));
            try std.testing.expectEqual(min, integer.normalize(unsigned_min));
            try std.testing.expectEqual(@as(i128, -1), integer.normalize(unsigned_ones));
            try std.testing.expect(integer.compare(.eq, min, unsigned_min));
            try std.testing.expect(integer.compare(.eq, -1, unsigned_ones));
            for (values) |rhs| try checkPair(bits, unsigned_min, rhs);
        }
    }
    // Unsigned decimal spellings above maxInt(i128) are not representable by
    // the current parser. At i128 test the same bits via signed storage instead.
    try std.testing.expectEqual(std.math.maxInt(u128), Integer.initBits(128).?.unsigned(-1));
}

fn binary(op: ir.BinaryOp, bits: u16, lhs: ir.Value, rhs: ir.Value, flags: ir.BinaryFlags) ?ir.Value {
    return simplify(.{ .result = "r", .kind = .{ .binary = .{ .op = op, .ty = .{ .int = bits }, .lhs = lhs, .rhs = rhs, .flags = flags } } });
}

test "integer semantics: simplifier retains conservative division and comparison policy" {
    for ([_]u16{ 1, 8, 64, 127, 128 }) |bits| {
        const integer = Integer.initBits(bits).?;
        for ([_]ir.BinaryOp{ .sdiv, .srem }) |op| {
            try std.testing.expect(binary(op, bits, .{ .int = -1 }, .{ .int = 0 }, .{}) == null);
            try std.testing.expect(binary(op, bits, .{ .int = integer.signedMin() }, .{ .int = -1 }, .{}) == null);
        }
    }
    try std.testing.expect(binary(.sdiv, 8, .{ .int = 253 }, .{ .int = 2 }, .{ .exact = true }) == null);
    try std.testing.expect(binary(.sdiv, 8, .{ .int = 250 }, .{ .int = 2 }, .{ .exact = true }).?.eql(.{ .int = -3 }));
    for ([_]ir.Value{ .poison, .undef }) |value| {
        try std.testing.expect(binary(.sdiv, 8, value, .{ .int = 2 }, .{}) == null);
        try std.testing.expect(binary(.srem, 8, value, .{ .int = 2 }, .{}) == null);
        try std.testing.expect(simplify(.{ .result = "r", .kind = .{ .icmp = .{ .predicate = .eq, .operand_ty = .{ .int = 8 }, .lhs = value, .rhs = .{ .int = 2 } } } }) == null);
    }
    for ([_]u16{ 0, 129 }) |bits| {
        try std.testing.expect(binary(.sdiv, bits, .{ .int = 7 }, .{ .int = 2 }, .{}) == null);
        try std.testing.expect(simplify(.{ .result = "r", .kind = .{ .icmp = .{ .predicate = .eq, .operand_ty = .{ .int = bits }, .lhs = .{ .int = 3 }, .rhs = .{ .int = 3 } } } }) == null);
    }
    try std.testing.expect(simplify(.{ .result = "r", .kind = .{ .icmp = .{ .predicate = .eq, .samesign = true, .operand_ty = .{ .int = 8 }, .lhs = .{ .int = 3 }, .rhs = .{ .int = 3 } } } }) == null);
}

test "integer semantics: shared normalization preserves wrapping and shift boundaries" {
    try std.testing.expect(binary(.add, 8, .{ .int = 127 }, .{ .int = 1 }, .{}).?.eql(.{ .int = -128 }));
    try std.testing.expect(binary(.sub, 128, .{ .int = std.math.minInt(i128) }, .{ .int = 1 }, .{}).?.eql(.{ .int = std.math.maxInt(i128) }));
    try std.testing.expect(binary(.mul, 128, .{ .int = 1 << 64 }, .{ .int = 1 << 64 }, .{}).?.eql(.{ .int = 0 }));
    for ([_]ir.BinaryOp{ .shl, .lshr, .ashr }) |op| {
        try std.testing.expect(binary(op, 8, .{ .int = 1 }, .{ .int = 8 }, .{}).? == .poison);
        try std.testing.expect(binary(op, 8, .{ .int = 1 }, .{ .int = -1 }, .{}).? == .poison);
        try std.testing.expect(binary(op, 128, .{ .int = 1 }, .{ .int = 127 }, .{}) == null);
    }
    try std.testing.expect(binary(.shl, 8, .{ .int = 1 }, .{ .int = 7 }, .{}).?.eql(.{ .int = -128 }));
    try std.testing.expect(binary(.lshr, 8, .{ .int = 255 }, .{ .int = 7 }, .{}).?.eql(.{ .int = 1 }));
    try std.testing.expect(binary(.ashr, 8, .{ .int = 255 }, .{ .int = 7 }, .{}).?.eql(.{ .int = -1 }));
}
