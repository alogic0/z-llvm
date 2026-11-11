//! Exact named i128 call operands use the existing literal-pair builder.
const std = @import("std");
const ir = @import("../../../ir.zig");
const Candidate = @import("rewrite_candidate.zig").Candidate;
const forms = @import("scalar_forms.zig");
const sysv = @import("../sysv_abi.zig");

pub fn legalize(allocator: std.mem.Allocator, function: ir.Function) !?ir.Function {
    var candidate = Candidate.init(allocator, function);
    var names: forms.TemporaryNames = .{};
    defer names.deinit(allocator);
    for (function.blocks.items, 0..) |original, block_index| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items, 0..) |inst, instruction_index| {
            if (!inst.removed and inst.kind == .call and inst.kind.call.inline_asm == null and
                inst.kind.call.raw_args == null and inst.kind.call.operand_bundle == null and
                !std.mem.startsWith(u8, inst.kind.call.callee, "llvm."))
            {
                const call = inst.kind.call;
                var needed = false;
                for (call.args.items) |arg| needed = needed or (arg.ty.eql(.{ .int = 128 }) and arg.value == .int);
                if (needed) {
                    sysv.rejectUnsupportedCallEnvelope(call) catch return null;
                    for (call.args.items) |arg| sysv.rejectUnsupportedCallArgAttrs(arg) catch return null;
                    try candidate.begin(&block, block_index, instruction_index);
                    var copy = inst;
                    copy.kind.call.args = try call.args.clone(allocator);
                    for (copy.kind.call.args.items) |*arg| if (arg.ty.eql(.{ .int = 128 }) and arg.value == .int) {
                        arg.value = try @import("binary128_arithmetic.zig").materializeIntegerArgument(allocator, function, &block, &names, .{ .op = .uitofp, .from_ty = arg.ty, .value = arg.value, .to_ty = .fp128 });
                    };
                    copy.metadata = null;
                    try block.instructions.append(allocator, copy);
                    continue;
                }
            }
            try candidate.keep(&block, inst);
        }
        try candidate.finishBlock(block);
    }
    return candidate.finish();
}
