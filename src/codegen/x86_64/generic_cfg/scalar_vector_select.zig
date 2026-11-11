//! Scalar-conditioned FP vector choices through exact integer lane bits.
const std = @import("std");
const ir = @import("../../../ir.zig");
const Candidate = @import("rewrite_candidate.zig").Candidate;
const forms = @import("scalar_forms.zig");

fn supported(select: ir.SelectInst) bool {
    if (!select.cond_ty.eql(.{ .int = 1 }) or select.ty != .vector) return false;
    const vector = select.ty.vector;
    const bits: usize = if (vector.elem_ty == .float) 32 else if (vector.elem_ty == .double) 64 else return false;
    return vector.len == 2 and vector.len * bits <= 128;
}

const Builder = struct {
    allocator: std.mem.Allocator,
    function: ir.Function,
    block: *ir.BasicBlock,
    names: *forms.TemporaryNames,
    fn emit(b: Builder, kind: @FieldType(ir.Instruction, "kind")) !ir.Value {
        const name = try forms.temporary(b.allocator, b.function, b.names);
        try b.block.instructions.append(b.allocator, .{ .result = name, .kind = kind });
        return .{ .named = name };
    }
    fn laneBits(b: Builder, ty: ir.Type, value: ir.Value, index: usize, integer: ir.Type) !ir.Value {
        if (value == .undef or value == .poison or value == .zero_initializer) return .{ .int = 0 };
        const scalar = ty.vector.elem_ty.toType();
        const lane = try b.emit(.{ .extractelement = .{ .vector_ty = ty, .vector = value, .index_ty = .{ .int = 64 }, .index = .{ .int = @intCast(index) } } });
        return b.emit(.{ .cast = .{ .op = .bitcast, .from_ty = scalar, .value = lane, .to_ty = integer } });
    }
};

pub fn legalize(allocator: std.mem.Allocator, function: ir.Function) !?ir.Function {
    var candidate = Candidate.init(allocator, function);
    var names: forms.TemporaryNames = .{};
    defer names.deinit(allocator);
    for (function.blocks.items, 0..) |original, block_index| {
        var block = original;
        block.instructions = .empty;
        const b: Builder = .{ .allocator = allocator, .function = function, .block = &block, .names = &names };
        for (original.instructions.items, 0..) |inst, instruction_index| {
            if (!inst.removed and inst.result != null and inst.kind == .select and supported(inst.kind.select)) {
                try candidate.begin(&block, block_index, instruction_index);
                const select = inst.kind.select;
                const scalar = select.ty.vector.elem_ty.toType();
                const integer: ir.Type = .{ .int = if (scalar == .float) 32 else 64 };
                const condition = if (select.cond == .undef or select.cond == .poison) ir.Value{ .int = 0 } else select.cond;
                var vector: ir.Value = .poison;
                for (0..select.ty.vector.len) |index| {
                    const lhs = try b.laneBits(select.ty, select.true_value, index, integer);
                    const rhs = try b.laneBits(select.ty, select.false_value, index, integer);
                    const bits = try b.emit(.{ .select = .{ .cond_ty = .{ .int = 1 }, .cond = condition, .ty = integer, .true_value = lhs, .false_value = rhs } });
                    const value = try b.emit(.{ .cast = .{ .op = .bitcast, .from_ty = integer, .value = bits, .to_ty = scalar } });
                    const kind: @FieldType(ir.Instruction, "kind") = .{ .insertelement = .{ .vector_ty = select.ty, .vector = vector, .value_ty = scalar, .value = value, .index_ty = ir.Type{ .int = 64 }, .index = ir.Value{ .int = @intCast(index) } } };
                    if (index + 1 == select.ty.vector.len) {
                        var copy = inst;
                        copy.kind = kind;
                        copy.metadata = null;
                        try block.instructions.append(allocator, copy);
                    } else vector = try b.emit(kind);
                }
            } else try candidate.keep(&block, inst);
        }
        try candidate.finishBlock(block);
    }
    return candidate.finish();
}
