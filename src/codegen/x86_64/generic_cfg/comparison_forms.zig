//! Normalize scalar comparisons to the selector's full-word compare actions.
//! Narrow signed order is unsigned order after flipping the original sign bit.
//! All temporaries belong to the private view; no source IR or ABI is changed.
const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const addresses = @import("../symbol_address.zig");
const forms = @import("scalar_forms.zig");

fn reverse(predicate: ir.IcmpPredicate) ir.IcmpPredicate {
    return switch (predicate) {
        .eq, .ne => predicate,
        .slt => .sgt,
        .sle => .sge,
        .sgt => .slt,
        .sge => .sle,
        .ult => .ugt,
        .ule => .uge,
        .ugt => .ult,
        .uge => .ule,
    };
}

fn unsignedPredicate(predicate: ir.IcmpPredicate) ir.IcmpPredicate {
    return switch (predicate) {
        .slt => .ult,
        .sle => .ule,
        .sgt => .ugt,
        .sge => .uge,
        else => predicate,
    };
}

fn validInteger(value: ir.Value, bits: u16) bool {
    if (value == .named) return !std.mem.startsWith(u8, value.named, "@");
    if (value != .int) return false;
    const shift: u7 = @intCast(bits);
    return value.int >= -(@as(i128, 1) << (shift - 1)) and value.int < (@as(i128, 1) << shift);
}

fn pointerValue(value: ir.Value) bool {
    return value == .null_value or (value == .named and !std.mem.startsWith(u8, value.named, "@"));
}

fn literal(allocator: std.mem.Allocator, function: ir.Function, block: *ir.BasicBlock, serial: *usize, bits: u16, value: i128) !ir.Value {
    const name = try forms.temporary(allocator, function, serial);
    try block.instructions.append(allocator, .{ .result = name, .kind = .{ .binary = .{
        .op = .add,
        .ty = .{ .int = bits },
        .lhs = .{ .int = value },
        .rhs = .{ .int = 0 },
    } } });
    return .{ .named = name };
}

fn wordValue(allocator: std.mem.Allocator, function: ir.Function, block: *ir.BasicBlock, serial: *usize, ty: ir.Type, value: ir.Value, signed: bool) !ir.Value {
    const bits: u16 = if (ty == .ptr) 64 else ty.int;
    const wide: u16 = if (bits <= 32) 32 else 64;
    if (value == .null_value) return literal(allocator, function, block, serial, 64, 0);
    if (value == .int) {
        const mask = (@as(i128, 1) << @as(u7, @intCast(bits))) - 1;
        const bias: i128 = if (signed and bits < 32) @as(i128, 1) << @as(u7, @intCast(bits - 1)) else 0;
        return literal(allocator, function, block, serial, wide, (value.int & mask) ^ bias);
    }
    var result = value;
    if (ty == .ptr) {
        // A frame object is an address value, not the bytes stored in it. GEP
        // materializes that address through the selector's typed address path.
        const name = try forms.temporary(allocator, function, serial);
        var indices: std.ArrayList(ir.GepIndex) = .empty;
        try indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = 0 } });
        try block.instructions.append(allocator, .{ .result = name, .kind = .{ .gep = .{
            .source_ty = .{ .int = 8 },
            .ptr = value,
            .indices = indices,
        } } });
        result = .{ .named = name };
    }
    if (ty == .ptr or bits < 32) {
        const name = try forms.temporary(allocator, function, serial);
        try block.instructions.append(allocator, .{ .result = name, .kind = .{ .cast = .{
            .op = if (ty == .ptr) .ptrtoint else .zext,
            .from_ty = ty,
            .value = result,
            .to_ty = .{ .int = wide },
        } } });
        result = .{ .named = name };
    }
    if (signed and bits < 32) {
        const name = try forms.temporary(allocator, function, serial);
        try block.instructions.append(allocator, .{ .result = name, .kind = .{ .binary = .{
            .op = .xor,
            .ty = .{ .int = 32 },
            .lhs = result,
            .rhs = .{ .int = @as(i128, 1) << @as(u7, @intCast(bits - 1)) },
        } } });
        result = .{ .named = name };
    }
    return result;
}

// Preserve existing compares that explicitly inspect only the declared bits:
// byte/halfword instructions, halfword normalization, and masked sign tests.
// Other narrow paths may observe dirty upper bits left by a truncation alias.
fn needsNarrowNormalization(cmp: ir.IcmpInst) bool {
    if (cmp.samesign or cmp.operand_ty != .int or cmp.operand_ty.int == 0 or cmp.operand_ty.int >= 32)
        return false;
    const bits = cmp.operand_ty.int;
    if (cmp.lhs == .named) {
        if (cmp.rhs == .int) {
            const value = cmp.rhs.int;
            if (cmp.predicate == .ne and value == 0 and (bits == 8 or bits == 16)) return false;
            if (cmp.predicate == .sgt and value == -1 and (bits == 6 or bits == 16)) return false;
            if (cmp.predicate == .slt and value == 0 and bits == 16) return false;
            if ((cmp.predicate == .ult or cmp.predicate == .ugt) and bits == 16) return false;
            // The existing masked six-bit action compares against 51.
            if (cmp.predicate == .ult and bits == 6 and (value & 63) == 51) return false;
        }
        if (cmp.rhs == .named and bits == 16 and
            (cmp.predicate == .ne or cmp.predicate == .slt or cmp.predicate == .sgt)) return false;
    }
    return true;
}

pub fn requiresNarrowNormalization(function: ir.Function) bool {
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (!inst.removed and inst.kind == .icmp and needsNarrowNormalization(inst.kind.icmp)) return true;
    };
    return false;
}

pub fn legalize(allocator: std.mem.Allocator, function: ir.Function, context: ?*const machine.ReadOnlyModuleContext) !?ir.Function {
    var result = function;
    result.blocks = .empty;
    var changed = false;
    var serial: usize = 0;
    for (function.blocks.items) |original| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items) |inst| {
            if (!inst.removed and inst.result != null and inst.kind == .icmp) {
                var cmp = inst.kind.icmp;
                const pointer = cmp.operand_ty == .ptr;
                const bits: u16 = if (pointer) 64 else if (cmp.operand_ty == .int) cmp.operand_ty.int else 0;
                const signed = unsignedPredicate(cmp.predicate) != cmp.predicate;
                const integer_form = !pointer and bits > 0 and (bits <= 32 or bits == 64) and
                    validInteger(cmp.lhs, bits) and validInteger(cmp.rhs, bits);
                const pointer_form = pointer and !signed and pointerValue(cmp.lhs) and pointerValue(cmp.rhs) and
                    addresses.supportsLayout(if (context) |ctx| ctx.target_datalayout else null);
                const pointer_needs_rewrite = pointer and (cmp.predicate != .eq and
                    (cmp.predicate != .ne or cmp.rhs != .null_value));
                // Existing full-width named comparisons are already canonical.
                // Preserve established null and nonnegative compare fast paths.
                const needs_rewrite = pointer_needs_rewrite or (!pointer and (needsNarrowNormalization(cmp) or
                    cmp.lhs == .int or
                    (cmp.rhs == .int and (cmp.rhs.int != 0 or cmp.predicate == .uge or (bits == 32 and cmp.predicate == .ule))) or
                    (cmp.predicate == .sge and !(bits == 32 and cmp.rhs.eql(.{ .int = 0 }))) or
                    cmp.predicate == .sle));
                if (!cmp.samesign and (integer_form or pointer_form) and needs_rewrite and
                    (pointer or bits >= 32 or needsNarrowNormalization(cmp)) and
                    (cmp.lhs == .named or cmp.rhs == .named))
                {
                    if (cmp.lhs != .named and cmp.rhs == .named) {
                        const lhs = cmp.lhs;
                        cmp.lhs = cmp.rhs;
                        cmp.rhs = lhs;
                        cmp.predicate = reverse(cmp.predicate);
                    }
                    const lhs = try wordValue(allocator, function, &block, &serial, cmp.operand_ty, cmp.lhs, signed);
                    const rhs = try wordValue(allocator, function, &block, &serial, cmp.operand_ty, cmp.rhs, signed);
                    cmp.lhs = lhs;
                    cmp.rhs = rhs;
                    cmp.operand_ty = .{ .int = if (bits <= 32) 32 else 64 };
                    if (signed and bits < 32) cmp.predicate = unsignedPredicate(cmp.predicate);
                    const invert = cmp.predicate == .sge or cmp.predicate == .sle;
                    if (invert) cmp.predicate = if (cmp.predicate == .sge) .slt else .sgt;
                    var comparison = inst;
                    comparison.kind.icmp = cmp;
                    if (invert) comparison.result = try forms.temporary(allocator, function, &serial);
                    try block.instructions.append(allocator, comparison);
                    if (invert) try block.instructions.append(allocator, .{ .result = inst.result, .kind = .{ .binary = .{
                        .op = .xor,
                        .ty = .{ .int = 1 },
                        .lhs = .{ .named = comparison.result.? },
                        .rhs = .{ .int = 1 },
                    } } });
                    changed = true;
                    continue;
                }
            }
            try block.instructions.append(allocator, inst);
        }
        try result.blocks.append(allocator, block);
    }
    return if (changed) result else null;
}
