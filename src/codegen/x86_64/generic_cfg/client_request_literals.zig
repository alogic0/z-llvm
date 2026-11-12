//! Give exact admitted integer assembly literals ordinary private SSA homes.
const std = @import("std");
const ir = @import("../../../ir.zig");
const Candidate = @import("rewrite_candidate.zig").Candidate;
const forms = @import("scalar_forms.zig");
pub fn legalize(a: std.mem.Allocator, source: ir.Function) !?ir.Function {
    var candidate = Candidate.init(a, source);
    var names: forms.TemporaryNames = .{};
    defer names.deinit(a);
    for (source.blocks.items, 0..) |original, bi| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items, 0..) |inst, ii| {
            if (!inst.removed and inst.kind == .call and @import("../inline_asm.zig").clientRequest(inst.kind.call)) {
                var needed = false;
                for (inst.kind.call.args.items) |arg| needed = needed or (arg.ty.eql(.{ .int = 64 }) and arg.value == .int);
                if (needed) {
                    try candidate.begin(&block, bi, ii);
                    var copy = inst;
                    copy.kind.call.args = try inst.kind.call.args.clone(a);
                    for (copy.kind.call.args.items) |*arg| if (arg.ty.eql(.{ .int = 64 }) and arg.value == .int) {
                        const name = try forms.temporary(a, source, &names);
                        try block.instructions.append(a, .{ .result = name, .kind = .{ .binary = .{ .op = .add, .ty = arg.ty, .lhs = arg.value, .rhs = .{ .int = 0 } } } });
                        arg.value = .{ .named = name };
                    };
                    try block.instructions.append(a, copy);
                    continue;
                }
            }
            try candidate.keep(&block, inst);
        }
        try candidate.finishBlock(block);
    }
    return candidate.finish();
}
