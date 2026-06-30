const impl = @import("zig_air_lowering_impl.zig");
const context = @import("zig_air_lowering_context.zig");

pub const UnsupportedReason = impl.UnsupportedReason;
pub const Diagnostic = impl.Diagnostic;
pub const Result = impl.Result;
pub const TypedV2Fallback = impl.TypedV2Fallback;
pub const LoweringContext = context.LoweringContext;

pub const lowerCompatible = impl.lowerCompatible;
pub const firstUnsupported = impl.firstUnsupported;
