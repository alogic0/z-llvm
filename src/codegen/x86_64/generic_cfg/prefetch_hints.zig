//! Data-prefetch hints have no observable effect and cannot trap. This backend
//! does not yet emit cache hints: preserve their semantics with no instruction.
//! https://releases.llvm.org/22.1.0/docs/LangRef.html#llvm-prefetch-intrinsic
const std = @import("std");
const ir = @import("../../../ir.zig");
const Candidate = @import("rewrite_candidate.zig").Candidate;

fn valid(inst: ir.Instruction) bool {
    if (inst.result != null) return false;
    const call = inst.kind.call;
    if (call.ret_ty != .void or call.args.items.len != 4 or call.inline_asm != null or
        call.callee_value != null or call.callee_function_ty != null or call.raw_args != null or
        call.operand_bundle != null or call.calling_conv != null or call.ret_attrs != null or call.native_query != null)
        return false;
    if (call.tail_kind) |tail| if (!std.mem.eql(u8, tail, "tail") and !std.mem.eql(u8, tail, "notail")) return false;
    const address = call.args.items[0];
    if (address.ty != .ptr or address.attrs != null or (address.value != .named and address.value != .null_value)) return false;
    for (call.args.items[1..]) |arg| if (!arg.ty.eql(.{ .int = 32 }) or arg.attrs != null or arg.value != .int) return false;
    return call.args.items[1].value.int >= 0 and call.args.items[1].value.int <= 1 and
        call.args.items[2].value.int >= 0 and call.args.items[2].value.int <= 3 and call.args.items[3].value.int == 1;
}

pub fn legalize(a: std.mem.Allocator, function: ir.Function) !?ir.Function {
    var present = false;
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (inst.removed or inst.kind != .call or !ir.identifiers.eql(inst.kind.call.callee, "llvm.prefetch.p0")) continue;
        if (!valid(inst)) return null;
        present = true;
    };
    if (!present) return null;
    var candidate: Candidate = .init(a, function);
    for (function.blocks.items, 0..) |original, bi| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items, 0..) |inst, ii| {
            if (!inst.removed and inst.kind == .call and ir.identifiers.eql(inst.kind.call.callee, "llvm.prefetch.p0")) {
                try candidate.begin(&block, bi, ii);
                continue;
            }
            try candidate.keep(&block, inst);
        }
        try candidate.finishBlock(block);
    }
    return candidate.finish();
}
