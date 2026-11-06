//! Whole-function semantic forms with complete, existing envelope proofs.
//! Recognition is read-only and emits no machine instructions. These forms own
//! their width semantics; scalar normalization is required for every other form.
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const envelopes = @import("legacy_envelopes.zig");

pub const Form = union(enum) {
    multiply_overflow,
    byte_swap,
    shift_right,
    shift_left_overflow,
    bit_not,
    bitwise: machine.Limb64BitwiseOp,
    compare,
    overflow: machine.Limb64OverflowOp,
    bit_reverse,
    population_count,
    trailing_zeroes,
    leading_zeroes,
    divide,
    remainder,
    pointer_bitwise: envelopes.PointerOffsetBitwiseRmw,
    pointer_increment: envelopes.PointerOffsetIncrementRmw,
    pointer_copy: envelopes.PointerOffsetCopy,
};

pub fn recognize(function: ir.Function) ?Form {
    if (@import("../sysv_abi.zig").functionHasVariadicCall(function)) return null;
    if (envelopes.matchesMuloLimb64Envelope(function)) return .multiply_overflow;
    if (envelopes.matchesByteswapLimb64Envelope(function)) return .byte_swap;
    if (envelopes.matchesShrLimb64Envelope(function)) return .shift_right;
    if (envelopes.matchesShloLimb64Envelope(function)) return .shift_left_overflow;
    if (envelopes.matchesNotLimb64Envelope(function)) return .bit_not;
    if (envelopes.matchesBitwiseLimb64Envelope(function)) |op| return .{ .bitwise = op };
    if (envelopes.matchesCmpLimb64Envelope(function)) return .compare;
    if (envelopes.matchesOverflowLimb64Envelope(function)) |op| return .{ .overflow = op };
    if (envelopes.matchesBitreverseLimb64Envelope(function)) return .bit_reverse;
    if (envelopes.matchesPopcountLimb64Envelope(function)) return .population_count;
    if (envelopes.matchesCtzLimb64Envelope(function)) return .trailing_zeroes;
    if (envelopes.matchesClzLimb64Envelope(function)) return .leading_zeroes;
    if (envelopes.matchesUdivei4Envelope(function)) return .divide;
    if (envelopes.matchesUmodei5Envelope(function)) return .remainder;
    if (envelopes.matchesPointerOffsetBitwiseRmwEnvelope(function)) |plan| return .{ .pointer_bitwise = plan };
    if (envelopes.matchesPointerOffsetIncrementRmwEnvelope(function)) |plan| return .{ .pointer_increment = plan };
    if (envelopes.matchesPointerOffsetCopyEnvelope(function)) |plan| return .{ .pointer_copy = plan };
    return null;
}
