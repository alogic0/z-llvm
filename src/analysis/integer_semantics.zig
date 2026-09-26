//! Fixed-width scalar integer constants representable by the IR's i128 storage.
//! Construct through init/initBits; unsupported types and widths return null.
//! Values are bit patterns modulo 2^width, irrespective of literal spelling.
//! Poison, undef, symbolic values and instruction flags belong to the caller;
//! a failed operation is not permission to invent a constant or a poison value.
const std = @import("std");
const ir = @import("../ir.zig");

pub const DivRem = enum { div, rem };
pub const DivisionError = error{ DivisionByZero, SignedOverflow, Inexact };

pub const Integer = struct {
    bits: u16,

    pub fn init(ty: ir.Type) ?Integer {
        return switch (ty) {
            .int => |bits| initBits(bits),
            else => null,
        };
    }

    pub fn initBits(bits: u16) ?Integer {
        if (bits == 0 or bits > 128) return null;
        return .{ .bits = bits };
    }

    pub fn unsignedMax(integer: Integer) u128 {
        return if (integer.bits == 128) std.math.maxInt(u128) else (@as(u128, 1) << @intCast(integer.bits)) - 1;
    }

    pub fn unsigned(integer: Integer, value: i128) u128 {
        return @as(u128, @bitCast(value)) & integer.unsignedMax();
    }

    /// Wrap a literal/result to this width and interpret its sign bit. This
    /// also handles i128 without shifting by 128 or negating minInt(i128).
    pub fn normalize(integer: Integer, value: i128) i128 {
        const raw = integer.unsigned(value);
        if (integer.bits == 128) return @bitCast(raw);
        const sign = @as(u128, 1) << @intCast(integer.bits - 1);
        if (raw & sign == 0) return @intCast(raw);
        return -@as(i128, @intCast((@as(u128, 1) << @intCast(integer.bits)) - raw));
    }

    pub fn signedMin(integer: Integer) i128 {
        if (integer.bits == 128) return std.math.minInt(i128);
        return -(@as(i128, 1) << @intCast(integer.bits - 1));
    }

    pub fn compare(integer: Integer, predicate: ir.IcmpPredicate, lhs: i128, rhs: i128) bool {
        const signed_lhs = integer.normalize(lhs);
        const signed_rhs = integer.normalize(rhs);
        const unsigned_lhs = integer.unsigned(lhs);
        const unsigned_rhs = integer.unsigned(rhs);
        return switch (predicate) {
            .eq => unsigned_lhs == unsigned_rhs,
            .ne => unsigned_lhs != unsigned_rhs,
            .sgt => signed_lhs > signed_rhs,
            .sge => signed_lhs >= signed_rhs,
            .slt => signed_lhs < signed_rhs,
            .sle => signed_lhs <= signed_rhs,
            .ugt => unsigned_lhs > unsigned_rhs,
            .uge => unsigned_lhs >= unsigned_rhs,
            .ult => unsigned_lhs < unsigned_rhs,
            .ule => unsigned_lhs <= unsigned_rhs,
        };
    }

    /// LLVM sdiv/srem truncate toward zero. Both reject min/-1 and division
    /// by zero; exact additionally requires a zero remainder. The simplifier
    /// conservatively leaves these cases unfolded, as before this extraction.
    pub fn signedDivRem(integer: Integer, mode: DivRem, lhs: i128, rhs: i128, exact: bool) DivisionError!i128 {
        const numerator = integer.normalize(lhs);
        const denominator = integer.normalize(rhs);
        if (denominator == 0) return error.DivisionByZero;
        if (numerator == integer.signedMin() and denominator == -1) return error.SignedOverflow;
        const remainder = @rem(numerator, denominator);
        if (exact and remainder != 0) return error.Inexact;
        return switch (mode) {
            .div => @divTrunc(numerator, denominator),
            .rem => remainder,
        };
    }
};
