//! Bounded SysV integer/pointer arguments. Floating and split-wide stack
//! arguments keep their separate ABI boundaries.
const ir = @import("../../../ir.zig");

pub const max_arguments = 16;
pub fn scalar(ty: ir.Type) bool {
    return ty == .ptr or ty.eql(.{ .int = 32 }) or ty.eql(.{ .int = 64 });
}
pub fn callCount(call: ir.CallInst) ?usize {
    if (call.args.items.len <= 6 or call.args.items.len > max_arguments) return null;
    for (call.args.items) |arg| if (!scalar(arg.ty)) return null;
    return call.args.items.len - 6;
}
pub fn hasParameters(function: ir.Function) bool {
    if (function.params.items.len <= 6 or function.params.items.len > max_arguments) return false;
    for (function.params.items) |param| if (!scalar(param.ty)) return false;
    return true;
}
