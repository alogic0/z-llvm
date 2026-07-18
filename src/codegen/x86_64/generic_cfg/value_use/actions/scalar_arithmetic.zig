const scalar_cast = @import("scalar_cast.zig");
const scalar_immediate = @import("scalar_immediate.zig");

pub const executeAccumulatorScalarCast = scalar_cast.executeAccumulatorScalarCast;
pub const executeImmediateLhsScalar = scalar_immediate.executeImmediateLhsScalar;
pub const executeImmediateRhsScalar = scalar_immediate.executeImmediateRhsScalar;
pub const executePairLowScalarCast = scalar_cast.executePairLowScalarCast;
pub const executeSignExtendScratch = scalar_cast.executeSignExtendScratch;
pub const isAccumulatorScalarCast = scalar_cast.isAccumulatorScalarCast;
pub const isImmediateLhsScalar = scalar_immediate.isImmediateLhsScalar;
pub const isImmediateRhsScalar = scalar_immediate.isImmediateRhsScalar;
pub const isPairLowScalarCast = scalar_cast.isPairLowScalarCast;
pub const isSignExtendScratchCast = scalar_cast.isSignExtendScratchCast;
pub const validateAccumulatorScalarCastAction = scalar_cast.validateAccumulatorScalarCastAction;
pub const validateImmediateLhsScalarAction = scalar_immediate.validateImmediateLhsScalarAction;
pub const validateImmediateRhsScalarAction = scalar_immediate.validateImmediateRhsScalarAction;
pub const validatePairLowScalarCastAction = scalar_cast.validatePairLowScalarCastAction;
