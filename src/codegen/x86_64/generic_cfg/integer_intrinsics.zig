//! Expand scalar saturation and narrow bit permutations into existing integer
//! operations without changing the original function or its ABI.
const std = @import("std");
const Candidate = @import("rewrite_candidate.zig").Candidate;
const ir = @import("../../../ir.zig");
const forms = @import("scalar_forms.zig");
const intrinsic_attrs = @import("intrinsic_attrs.zig");
const bit_intrinsics = @import("integer_bit_intrinsics.zig");

const Operation = enum { uadd_sat, usub_sat, ushl_one, sadd_sat, ssub_sat, scmp, reverse, umin, umax, smin, smax };

fn minimumMaximum(op: Operation) bool {
    return op == .umin or op == .umax or op == .smin or op == .smax;
}

fn emit(allocator: std.mem.Allocator, function: ir.Function, block: *ir.BasicBlock, serial: *forms.TemporaryNames, kind: @FieldType(ir.Instruction, "kind")) !ir.Value {
    const name = try forms.temporary(allocator, function, serial);
    try block.instructions.append(allocator, .{ .result = name, .kind = kind });
    return .{ .named = name };
}

fn extend(allocator: std.mem.Allocator, function: ir.Function, block: *ir.BasicBlock, serial: *forms.TemporaryNames, ty: ir.Type, wide: ir.Type, value: ir.Value) !ir.Value {
    if (value == .int) return emit(allocator, function, block, serial, .{ .binary = .{
        .op = .add,
        .ty = wide,
        .lhs = .{ .int = value.int & ((@as(i128, 1) << @as(u7, @intCast(ty.int))) - 1) },
        .rhs = .{ .int = 0 },
    } });
    if (ty.eql(wide)) return value;
    return emit(allocator, function, block, serial, .{ .cast = .{ .op = .zext, .from_ty = ty, .value = value, .to_ty = wide } });
}

fn signedExtend(allocator: std.mem.Allocator, function: ir.Function, block: *ir.BasicBlock, serial: *forms.TemporaryNames, ty: ir.Type, wide: ir.Type, value: ir.Value) !ir.Value {
    if (value == .int) {
        const modulus = @as(i128, 1) << @as(u7, @intCast(ty.int));
        const raw = value.int & (modulus - 1);
        return emit(allocator, function, block, serial, .{ .binary = .{
            .op = .add,
            .ty = wide,
            .lhs = .{ .int = if (raw >= @divExact(modulus, 2)) raw - modulus else raw },
            .rhs = .{ .int = 0 },
        } });
    }
    return emit(allocator, function, block, serial, .{ .cast = .{ .op = .sext, .from_ty = ty, .value = value, .to_ty = wide } });
}

fn fixedMultiply(call: ir.CallInst) bool {
    if (!std.mem.eql(u8, call.callee, "llvm.umul.fix.sat.i16") or !call.ret_ty.eql(.{ .int = 16 }) or
        !intrinsic_attrs.scalarIntegerCallSupported(call) or call.args.items.len != 3) return false;
    for (call.args.items[0..2]) |arg| {
        if (!arg.ty.eql(call.ret_ty) or (arg.value != .named and arg.value != .int)) return false;
        if (arg.value == .named and std.mem.startsWith(u8, arg.value.named, "@")) return false;
        if (arg.value == .int and (arg.value.int < -32768 or arg.value.int > 65535)) return false;
    }
    const scale = call.args.items[2];
    return scale.ty.eql(.{ .int = 32 }) and scale.value == .int and scale.value.int == 0;
}

fn operation(call: ir.CallInst) ?Operation {
    if (!std.mem.startsWith(u8, call.callee, "llvm.") or
        !intrinsic_attrs.scalarIntegerCallSupported(call) or (call.ret_ty.int > 64 and call.ret_ty.int != 96)) return null;
    const bits = call.ret_ty.int;
    for (call.args.items) |arg| {
        if (!arg.ty.eql(call.ret_ty) or (arg.value != .named and arg.value != .int)) return null;
        if (arg.value == .named and std.mem.startsWith(u8, arg.value.named, "@")) return null;
        if (arg.value == .int and (arg.value.int < -(@as(i128, 1) << @as(u7, @intCast(bits - 1))) or
            arg.value.int >= (@as(i128, 1) << @as(u7, @intCast(bits))))) return null;
    }
    var buffer: [64]u8 = undefined;
    for ([_][]const u8{ "uadd.sat", "usub.sat", "ushl.sat", "sadd.sat", "ssub.sat", "scmp.i32", "bitreverse", "umin", "umax", "smin", "smax" }, [_]Operation{ .uadd_sat, .usub_sat, .ushl_one, .sadd_sat, .ssub_sat, .scmp, .reverse, .umin, .umax, .smin, .smax }) |name, op| {
        const spelling = std.fmt.bufPrint(&buffer, "llvm.{s}.i{d}", .{ name, bits }) catch return null;
        if (!std.mem.eql(u8, call.callee, spelling)) continue;
        if (bits > 64 and op != .sadd_sat and op != .ssub_sat) return null;
        if (op == .reverse) {
            if (bits == 32 or bits == 64 or call.args.items.len != 1) return null;
        } else if (op == .ushl_one) {
            if (bits != 64 or call.args.items.len != 2 or call.args.items[1].value != .int or call.args.items[1].value.int != 1) return null;
        } else if (op == .ssub_sat or op == .sadd_sat) {
            if (call.args.items.len != 2) return null;
            switch (bits) {
                8, 16, 32, 64, 96 => {},
                else => return null,
            }
        } else if (op == .scmp) {
            if (bits != 32 or call.args.items.len != 2) return null;
        } else if (minimumMaximum(op)) {
            if (call.args.items.len != 2) return null;
            if (bits == 32 or bits == 64) {
                var facts = call.ret_attrs != null;
                for (call.args.items) |arg| facts = facts or arg.attrs != null;
                if (!facts) return null;
            }
        } else if ((bits > 32 and bits != 64) or call.args.items.len != 2) return null;
        return op;
    }
    return null;
}

pub fn legalize(allocator: std.mem.Allocator, function: ir.Function) !?ir.Function {
    var candidate = Candidate.init(allocator, function);
    var serial: forms.TemporaryNames = .{};
    defer serial.deinit(allocator);
    for (function.blocks.items, 0..) |original, block_index| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items, 0..) |inst, instruction_index| {
            if (!inst.removed and inst.result != null and inst.kind == .call and fixedMultiply(inst.kind.call)) {
                try candidate.begin(&block, block_index, instruction_index);
                const call = inst.kind.call;
                const wide: ir.Type = .{ .int = 64 };
                const lhs = try extend(allocator, function, &block, &serial, call.ret_ty, wide, call.args.items[0].value);
                const rhs = try extend(allocator, function, &block, &serial, call.ret_ty, wide, call.args.items[1].value);
                // Scale zero is exact unsigned multiplication, so no rounding
                // choice is involved. Its full product fits in32 bits.
                const product = try emit(allocator, function, &block, &serial, .{ .binary = .{ .op = .mul, .ty = wide, .lhs = lhs, .rhs = rhs } });
                const overflow = try emit(allocator, function, &block, &serial, .{ .icmp = .{ .predicate = .ugt, .operand_ty = wide, .lhs = product, .rhs = .{ .int = 65535 } } });
                const clamped = try emit(allocator, function, &block, &serial, .{ .select = .{ .cond_ty = .{ .int = 1 }, .cond = overflow, .ty = wide, .true_value = .{ .int = 65535 }, .false_value = product } });
                try block.instructions.append(allocator, .{ .result = inst.result, .metadata = inst.metadata, .kind = .{ .cast = .{ .op = .trunc, .from_ty = wide, .value = clamped, .to_ty = call.ret_ty } } });
                continue;
            }
            if (!inst.removed and inst.result != null and inst.kind == .call) if (bit_intrinsics.operation(inst.kind.call)) |op| {
                try candidate.begin(&block, block_index, instruction_index);
                try bit_intrinsics.expand(allocator, function, &block, &serial, inst, op);
                continue;
            };
            if (!inst.removed and inst.result != null and inst.kind == .call) if (operation(inst.kind.call)) |op| {
                try candidate.begin(&block, block_index, instruction_index);
                const call = inst.kind.call;
                const bits = call.ret_ty.int;
                if (minimumMaximum(op)) {
                    const wide: ir.Type = .{ .int = if (bits < 32) 32 else 64 };
                    const lhs = try extend(allocator, function, &block, &serial, call.ret_ty, wide, call.args.items[0].value);
                    const rhs = try extend(allocator, function, &block, &serial, call.ret_ty, wide, call.args.items[1].value);
                    var compare_lhs = lhs;
                    var compare_rhs = rhs;
                    if (op == .smin or op == .smax) {
                        const sign: ir.Value = .{ .int = @as(i128, 1) << @as(u7, @intCast(bits - 1)) };
                        compare_lhs = try emit(allocator, function, &block, &serial, .{ .binary = .{ .op = .xor, .ty = wide, .lhs = lhs, .rhs = sign } });
                        compare_rhs = try emit(allocator, function, &block, &serial, .{ .binary = .{ .op = .xor, .ty = wide, .lhs = rhs, .rhs = sign } });
                    }
                    const condition = try emit(allocator, function, &block, &serial, .{ .icmp = .{
                        .predicate = .ugt,
                        .operand_ty = wide,
                        .lhs = if (op == .umin or op == .smin) compare_rhs else compare_lhs,
                        .rhs = if (op == .umin or op == .smin) compare_lhs else compare_rhs,
                    } });
                    const selected = try emit(allocator, function, &block, &serial, .{ .select = .{
                        .cond_ty = .{ .int = 1 },
                        .cond = condition,
                        .ty = wide,
                        .true_value = lhs,
                        .false_value = rhs,
                    } });
                    try block.instructions.append(allocator, .{ .result = inst.result, .metadata = inst.metadata, .kind = if (wide.eql(call.ret_ty))
                        .{ .binary = .{ .op = .add, .ty = wide, .lhs = selected, .rhs = .{ .int = 0 } } }
                    else
                        .{ .cast = .{ .op = .trunc, .from_ty = wide, .value = selected, .to_ty = call.ret_ty } } });
                } else if (op == .ssub_sat or op == .sadd_sat) {
                    // The wider carrier represents the exact mathematical
                    // sum or difference. Clamp before narrowing; normalize
                    // constants in their original signed logical width.
                    const wide: ir.Type = .{ .int = if (bits < 64) 64 else 128 };
                    const lhs = try signedExtend(allocator, function, &block, &serial, call.ret_ty, wide, call.args.items[0].value);
                    const rhs = try signedExtend(allocator, function, &block, &serial, call.ret_ty, wide, call.args.items[1].value);
                    const difference = try emit(allocator, function, &block, &serial, .{ .binary = .{ .op = if (op == .sadd_sat) .add else .sub, .ty = wide, .lhs = lhs, .rhs = rhs } });
                    const minimum: ir.Value = .{ .int = -(@as(i128, 1) << @as(u7, @intCast(bits - 1))) };
                    const maximum: ir.Value = .{ .int = -minimum.int - 1 };
                    const below = try emit(allocator, function, &block, &serial, .{ .icmp = .{ .predicate = .slt, .operand_ty = wide, .lhs = difference, .rhs = minimum } });
                    const lower = try emit(allocator, function, &block, &serial, .{ .select = .{ .cond_ty = .{ .int = 1 }, .cond = below, .ty = wide, .true_value = minimum, .false_value = difference } });
                    const above = try emit(allocator, function, &block, &serial, .{ .icmp = .{ .predicate = .sgt, .operand_ty = wide, .lhs = lower, .rhs = maximum } });
                    const clamped = try emit(allocator, function, &block, &serial, .{ .select = .{ .cond_ty = .{ .int = 1 }, .cond = above, .ty = wide, .true_value = maximum, .false_value = lower } });
                    try block.instructions.append(allocator, .{ .result = inst.result, .metadata = inst.metadata, .kind = .{ .cast = .{ .op = .trunc, .from_ty = wide, .value = clamped, .to_ty = call.ret_ty } } });
                } else if (op == .scmp) {
                    const lhs = try extend(allocator, function, &block, &serial, call.ret_ty, call.ret_ty, call.args.items[0].value);
                    const rhs = try extend(allocator, function, &block, &serial, call.ret_ty, call.ret_ty, call.args.items[1].value);
                    const less = try emit(allocator, function, &block, &serial, .{ .icmp = .{ .predicate = .slt, .operand_ty = call.ret_ty, .lhs = lhs, .rhs = rhs } });
                    const greater = try emit(allocator, function, &block, &serial, .{ .icmp = .{ .predicate = .sgt, .operand_ty = call.ret_ty, .lhs = lhs, .rhs = rhs } });
                    const nonnegative = try emit(allocator, function, &block, &serial, .{ .select = .{ .cond_ty = .{ .int = 1 }, .cond = greater, .ty = call.ret_ty, .true_value = .{ .int = 1 }, .false_value = .{ .int = 0 } } });
                    try block.instructions.append(allocator, .{ .result = inst.result, .metadata = inst.metadata, .kind = .{ .select = .{ .cond_ty = .{ .int = 1 }, .cond = less, .ty = call.ret_ty, .true_value = .{ .int = -1 }, .false_value = nonnegative } } });
                } else if (op == .reverse) {
                    const wide: ir.Type = .{ .int = if (bits < 32) 32 else 64 };
                    const input = try extend(allocator, function, &block, &serial, call.ret_ty, wide, call.args.items[0].value);
                    const reversed = try forms.temporary(allocator, function, &serial);
                    var extended = call;
                    extended.ret_ty = wide;
                    extended.ret_attrs = null;
                    extended.callee = try std.fmt.allocPrint(allocator, "llvm.bitreverse.i{d}", .{wide.int});
                    extended.args = .empty;
                    try extended.args.append(allocator, .{ .ty = wide, .value = input });
                    try block.instructions.append(allocator, .{ .result = reversed, .kind = .{ .call = extended } });
                    const shifted = try forms.temporary(allocator, function, &serial);
                    try block.instructions.append(allocator, .{ .result = shifted, .kind = .{ .binary = .{
                        .op = .lshr,
                        .ty = wide,
                        .lhs = .{ .named = reversed },
                        .rhs = .{ .int = wide.int - bits },
                    } } });
                    try block.instructions.append(allocator, .{ .result = inst.result, .metadata = inst.metadata, .kind = .{ .cast = .{
                        .op = .trunc,
                        .from_ty = wide,
                        .value = .{ .named = shifted },
                        .to_ty = call.ret_ty,
                    } } });
                } else {
                    const pair_name = try forms.temporary(allocator, function, &serial);
                    const value_name = try forms.temporary(allocator, function, &serial);
                    const flag_name = try forms.temporary(allocator, function, &serial);
                    const pair_type: ir.Type = .{ .aggregate = try std.fmt.allocPrint(allocator, "{{ i{d}, i1 }}", .{bits}) };
                    var checked = call;
                    checked.ret_ty = pair_type;
                    // Facts on the saturated scalar do not describe this
                    // overflow aggregate. Keep source facts untouched and omit
                    // validated advisory facts only on the private expansion.
                    checked.ret_attrs = null;
                    checked.args = try call.args.clone(allocator);
                    for (checked.args.items) |*arg| arg.attrs = null;
                    // Saturating unsigned shift by one equals a saturated
                    // doubling. Preserve simultaneous duplicate operands.
                    if (op == .ushl_one) checked.args.items[1].value = call.args.items[0].value;
                    checked.callee = try std.fmt.allocPrint(allocator, "llvm.{s}.with.overflow.i{d}", .{ if (op == .uadd_sat or op == .ushl_one) "uadd" else "usub", bits });
                    try block.instructions.append(allocator, .{ .result = pair_name, .kind = .{ .call = checked } });
                    try block.instructions.append(allocator, .{ .result = value_name, .kind = .{ .extractvalue = .{
                        .aggregate_ty = pair_type,
                        .aggregate = .{ .named = pair_name },
                        .indices = "0",
                        .result_ty = call.ret_ty,
                    } } });
                    try block.instructions.append(allocator, .{ .result = flag_name, .kind = .{ .extractvalue = .{
                        .aggregate_ty = pair_type,
                        .aggregate = .{ .named = pair_name },
                        .indices = "1",
                        .result_ty = .{ .int = 1 },
                    } } });
                    try block.instructions.append(allocator, .{ .result = inst.result, .metadata = inst.metadata, .kind = .{ .select = .{
                        .cond_ty = .{ .int = 1 },
                        .cond = .{ .named = flag_name },
                        .ty = call.ret_ty,
                        .true_value = .{ .int = if (op == .uadd_sat or op == .ushl_one) (@as(i128, 1) << @as(u7, @intCast(bits))) - 1 else 0 },
                        .false_value = .{ .named = value_name },
                    } } });
                }
                continue;
            };
            try candidate.keep(&block, inst);
        }
        try candidate.finishBlock(block);
    }
    return candidate.finish();
}
