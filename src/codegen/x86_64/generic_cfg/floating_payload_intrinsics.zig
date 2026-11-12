//! fabs/copysign change only the sign bit, including NaN payloads and zeros.
const std = @import("std");
const ir = @import("../../../ir.zig");
const Candidate = @import("rewrite_candidate.zig").Candidate;
const forms = @import("scalar_forms.zig");
fn admissible(call: ir.CallInst) ?bool {
    const bits: usize = if (call.ret_ty == .x86_fp80) 80 else if (call.ret_ty == .fp128) 128 else return null;
    var spelling: [64]u8 = undefined;
    const copy = if (ir.identifiers.eql(call.callee, std.fmt.bufPrint(&spelling, "llvm.copysign.f{d}", .{bits}) catch return null)) true else
        if (ir.identifiers.eql(call.callee, std.fmt.bufPrint(&spelling, "llvm.fabs.f{d}", .{bits}) catch return null)) false else return null;
    if (call.args.items.len != (if (copy) @as(usize, 2) else 1) or call.callee_value != null or
        call.callee_function_ty != null or call.inline_asm != null or call.raw_args != null or call.operand_bundle != null or
        call.calling_conv != null or call.native_query != null or call.va_arg) return null;
    if (call.ret_attrs) |attrs| if (!std.mem.eql(u8, attrs, "noundef")) return null;
    if (call.tail_kind) |tail| if (std.mem.eql(u8, tail, "musttail")) return null;
    for (call.args.items) |arg| {
        if (!arg.ty.eql(call.ret_ty)) return null;
        if (arg.attrs) |attrs| if (!std.mem.eql(u8, attrs, "noundef")) return null;
    }
    return copy;
}
pub fn legalize(a: std.mem.Allocator, source: ir.Function) !?ir.Function {
    var candidate = Candidate.init(a, source);
    var names: forms.TemporaryNames = .{ .prefix = "__zllvm_fp_sign_" };
    defer names.deinit(a);
    for (source.blocks.items, 0..) |original, bi| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items, 0..) |inst, ii| {
            if (!inst.removed and inst.kind == .call) if (admissible(inst.kind.call)) |copy_sign| {
                const call = inst.kind.call;
                const bits: u16 = if (call.ret_ty == .x86_fp80) 80 else 128;
                const ty: ir.Type = .{ .int = bits };
                const mask: i128 = if (bits == 128) std.math.maxInt(i128) else (@as(i128, 1) << 79) - 1;
                try candidate.begin(&block, bi, ii);
                const raw = try forms.temporary(a, source, &names);
                const magnitude = try forms.temporary(a, source, &names);
                const input = if (call.args.items[0].value == .undef or call.args.items[0].value == .poison) ir.Value.zero_initializer else call.args.items[0].value;
                try block.instructions.appendSlice(a, &.{
                    .{ .result = raw, .kind = .{ .cast = .{ .op = .bitcast, .from_ty = call.ret_ty, .value = input, .to_ty = ty } } },
                    .{ .result = magnitude, .kind = .{ .binary = .{ .op = .@"and", .ty = ty, .lhs = .{ .named = raw }, .rhs = .{ .int = mask } } } },
                });
                var result: ir.Value = .{ .named = magnitude };
                if (copy_sign) {
                    const sign_raw = try forms.temporary(a, source, &names);
                    const sign = try forms.temporary(a, source, &names);
                    const combined = try forms.temporary(a, source, &names);
                    const sign_mask: i128 = if (bits == 128) std.math.minInt(i128) else @as(i128, 1) << 79;
                    const sign_input = if (call.args.items[1].value == .undef or call.args.items[1].value == .poison) ir.Value.zero_initializer else call.args.items[1].value;
                    try block.instructions.appendSlice(a, &.{
                        .{ .result = sign_raw, .kind = .{ .cast = .{ .op = .bitcast, .from_ty = call.ret_ty, .value = sign_input, .to_ty = ty } } },
                        .{ .result = sign, .kind = .{ .binary = .{ .op = .@"and", .ty = ty, .lhs = .{ .named = sign_raw }, .rhs = .{ .int = sign_mask } } } },
                        .{ .result = combined, .kind = .{ .binary = .{ .op = .@"or", .ty = ty, .lhs = result, .rhs = .{ .named = sign } } } },
                    });
                    result = .{ .named = combined };
                }
                try block.instructions.append(a, .{ .result = inst.result, .metadata = inst.metadata, .kind = .{ .cast = .{ .op = .bitcast, .from_ty = ty, .value = result, .to_ty = call.ret_ty } } });
                continue;
            };
            try candidate.keep(&block, inst);
        }
        try candidate.finishBlock(block);
    }
    return candidate.finish();
}
