const std = @import("std");
const ir = @import("../ir.zig");

pub fn canonicalizeCommutativeConstantRhs(binary: *ir.BinaryInst) bool {
    if (binary.flags.any()) return false;
    if (!isCommutative(binary.op)) return false;
    if (binary.lhs != .int or binary.rhs == .int) return false;
    const old_lhs = binary.lhs;
    binary.lhs = binary.rhs;
    binary.rhs = old_lhs;
    return true;
}

pub fn simplify(instruction: ir.Instruction) ?ir.Value {
    return switch (instruction.kind) {
        .binary => |binary| simplifyBinary(binary),
        .cast => |cast| simplifyCast(cast),
        .freeze => |freeze| simplifyFreeze(freeze),
        .icmp => |icmp| simplifyIcmp(icmp),
        .select => |select| simplifySelect(select),
        .call => |call| simplifyCall(call),
        .phi, .alloca, .load, .store, .gep => null,
    };
}

pub fn sameExpression(a: ir.Instruction, b: ir.Instruction) bool {
    return switch (a.kind) {
        .binary => |a_binary| switch (b.kind) {
            .binary => |b_binary| a_binary.op == b_binary.op and
                a_binary.flags.nsw == b_binary.flags.nsw and
                a_binary.flags.nuw == b_binary.flags.nuw and
                a_binary.flags.exact == b_binary.flags.exact and
                a_binary.flags.disjoint == b_binary.flags.disjoint and
                a_binary.ty.eql(b_binary.ty) and
                a_binary.lhs.eql(b_binary.lhs) and
                a_binary.rhs.eql(b_binary.rhs),
            .cast, .freeze, .icmp, .select, .phi, .alloca, .load, .store, .gep, .call => false,
        },
        .cast => |a_cast| switch (b.kind) {
            .cast => |b_cast| a_cast.op == b_cast.op and
                a_cast.from_ty.eql(b_cast.from_ty) and
                a_cast.value.eql(b_cast.value) and
                a_cast.to_ty.eql(b_cast.to_ty),
            .binary, .freeze, .icmp, .select, .phi, .alloca, .load, .store, .gep, .call => false,
        },
        .icmp => |a_icmp| switch (b.kind) {
            .icmp => |b_icmp| a_icmp.predicate == b_icmp.predicate and
                a_icmp.operand_ty.eql(b_icmp.operand_ty) and
                a_icmp.lhs.eql(b_icmp.lhs) and
                a_icmp.rhs.eql(b_icmp.rhs),
            .binary, .cast, .freeze, .select, .phi, .alloca, .load, .store, .gep, .call => false,
        },
        .select => |a_select| switch (b.kind) {
            .select => |b_select| a_select.cond_ty.eql(b_select.cond_ty) and
                a_select.cond.eql(b_select.cond) and
                a_select.ty.eql(b_select.ty) and
                a_select.true_value.eql(b_select.true_value) and
                a_select.false_value.eql(b_select.false_value),
            .binary, .cast, .freeze, .icmp, .phi, .alloca, .load, .store, .gep, .call => false,
        },
        .phi => |a_phi| switch (b.kind) {
            .phi => |b_phi| samePhi(a_phi, b_phi),
            .binary, .cast, .freeze, .icmp, .select, .alloca, .load, .store, .gep, .call => false,
        },
        .load => |a_load| switch (b.kind) {
            .load => |b_load| a_load.ty.eql(b_load.ty) and a_load.ptr.eql(b_load.ptr) and
                !a_load.attrs.isBarrier() and !b_load.attrs.isBarrier(),
            .binary, .cast, .freeze, .icmp, .select, .phi, .alloca, .store, .gep, .call => false,
        },
        .freeze, .alloca, .store, .gep, .call => false,
    };
}

fn samePhi(a: ir.PhiInst, b: ir.PhiInst) bool {
    if (!a.ty.eql(b.ty) or a.incoming.items.len != b.incoming.items.len) return false;
    for (a.incoming.items, b.incoming.items) |a_incoming, b_incoming| {
        if (!a_incoming.value.eql(b_incoming.value)) return false;
        if (!@import("std").mem.eql(u8, a_incoming.block, b_incoming.block)) return false;
    }
    return true;
}

fn simplifyBinary(binary: ir.BinaryInst) ?ir.Value {
    if (binary.lhs == .int and binary.rhs == .int) {
        if (simplifyBinaryConstants(binary)) |replacement| return replacement;
    }

    if (binary.flags.any()) return null;
    return switch (binary.op) {
        .add => if (isZero(binary.rhs))
            binary.lhs
        else if (isZero(binary.lhs))
            binary.rhs
        else
            null,
        .sub => if (isZero(binary.rhs)) binary.lhs else null,
        .mul => if (isOne(binary.rhs))
            binary.lhs
        else if (isOne(binary.lhs))
            binary.rhs
        else if (isZero(binary.rhs) or isZero(binary.lhs))
            .{ .int = 0 }
        else
            null,
        .@"and" => if (isZero(binary.rhs) or isZero(binary.lhs))
            .{ .int = 0 }
        else if (isAllOnes(binary.rhs))
            binary.lhs
        else if (isAllOnes(binary.lhs))
            binary.rhs
        else if (binary.lhs.eql(binary.rhs))
            binary.lhs
        else
            null,
        .@"or" => if (isZero(binary.rhs))
            binary.lhs
        else if (isZero(binary.lhs))
            binary.rhs
        else if (binary.lhs.eql(binary.rhs))
            binary.lhs
        else
            null,
        .xor => if (isZero(binary.rhs))
            binary.lhs
        else if (isZero(binary.lhs))
            binary.rhs
        else if (binary.lhs.eql(binary.rhs))
            .{ .int = 0 }
        else
            null,
        .shl, .lshr, .ashr => if (isZero(binary.rhs))
            binary.lhs
        else if (isZero(binary.lhs))
            .{ .int = 0 }
        else
            null,
        .udiv, .sdiv => if (isOne(binary.rhs)) binary.lhs else null,
        .urem, .srem => if (isOne(binary.rhs)) .{ .int = 0 } else null,
    };
}

fn simplifyBinaryConstants(binary: ir.BinaryInst) ?ir.Value {
    const lhs = binary.lhs.int;
    const rhs = binary.rhs.int;
    return switch (binary.op) {
        .add => if (!binary.flags.any()) .{ .int = lhs + rhs } else null,
        .sub => if (!binary.flags.any()) .{ .int = lhs - rhs } else null,
        .mul => if (!binary.flags.any()) .{ .int = lhs * rhs } else null,
        .@"and" => if (!binary.flags.any()) .{ .int = lhs & rhs } else null,
        .@"or" => if (!binary.flags.any()) .{ .int = lhs | rhs } else null,
        .xor => if (!binary.flags.any()) .{ .int = lhs ^ rhs } else null,
        .shl, .lshr, .ashr => if (!binary.flags.any() and rhs == 0)
            .{ .int = lhs }
        else if (!binary.flags.any() and lhs == 0)
            .{ .int = 0 }
        else
            null,
        .udiv => foldUnsignedDivRem(binary, .div),
        .urem => foldUnsignedDivRem(binary, .rem),
        .sdiv => foldSignedDivRem(binary, .div),
        .srem => foldSignedDivRem(binary, .rem),
    };
}

const DivRem = enum { div, rem };

fn foldUnsignedDivRem(binary: ir.BinaryInst, mode: DivRem) ?ir.Value {
    if (binary.rhs.int == 0) return null;
    const lhs = unsignedInt(binary.lhs.int, binary.ty) orelse return null;
    const rhs = unsignedInt(binary.rhs.int, binary.ty) orelse return null;
    if (rhs == 0) return null;
    if (binary.flags.exact and lhs % rhs != 0) return null;
    return .{ .int = @intCast(switch (mode) {
        .div => lhs / rhs,
        .rem => lhs % rhs,
    }) };
}

fn foldSignedDivRem(binary: ir.BinaryInst, mode: DivRem) ?ir.Value {
    if (binary.rhs.int == 0) return null;
    if (isSignedMin(binary.lhs.int, binary.ty) and binary.rhs.int == -1) return null;
    if (binary.flags.exact and @rem(binary.lhs.int, binary.rhs.int) != 0) return null;
    return .{ .int = switch (mode) {
        .div => @divTrunc(binary.lhs.int, binary.rhs.int),
        .rem => @rem(binary.lhs.int, binary.rhs.int),
    } };
}

fn simplifyCast(cast: ir.CastInst) ?ir.Value {
    if (cast.value != .int) return null;
    const from_bits = intBits(cast.from_ty) orelse return null;
    const to_bits = intBits(cast.to_ty) orelse return null;
    if (from_bits >= 128 or to_bits >= 128) return null;

    return switch (cast.op) {
        .trunc => truncateConstant(cast.value.int, to_bits),
        .zext => zeroExtendConstant(cast.value.int, from_bits),
        .sext => signExtendConstant(cast.value.int, from_bits),
    };
}

fn simplifyFreeze(freeze: ir.FreezeInst) ?ir.Value {
    return switch (freeze.value) {
        .int => freeze.value,
        .named, .undef => null,
    };
}

fn truncateConstant(value: i128, bits: u16) ?ir.Value {
    if (bits == 0 or bits >= 128) return null;
    const mask = (@as(i128, 1) << @intCast(bits)) - 1;
    return .{ .int = value & mask };
}

fn zeroExtendConstant(value: i128, from_bits: u16) ?ir.Value {
    if (from_bits == 0 or from_bits >= 128) return null;
    return .{ .int = lowBits(value, from_bits) };
}

fn signExtendConstant(value: i128, from_bits: u16) ?ir.Value {
    if (from_bits == 0 or from_bits >= 128) return null;
    const bits = lowBits(value, from_bits);
    const sign_bit = @as(i128, 1) << @intCast(from_bits - 1);
    if ((bits & sign_bit) == 0) return .{ .int = bits };
    return .{ .int = bits - (@as(i128, 1) << @intCast(from_bits)) };
}

fn lowBits(value: i128, bits: u16) i128 {
    const mask = (@as(i128, 1) << @intCast(bits)) - 1;
    return value & mask;
}

fn simplifyIcmp(icmp: ir.IcmpInst) ?ir.Value {
    if (icmp.lhs == .int and icmp.rhs == .int) {
        return simplifyIcmpConstants(icmp);
    }

    if (icmp.lhs.eql(icmp.rhs)) {
        return .{ .int = switch (icmp.predicate) {
            .eq => 1,
            .ne => 0,
            .sgt, .slt, .ugt, .ult => 0,
            .sge, .sle, .uge, .ule => 1,
        } };
    }

    return null;
}

fn simplifyIcmpConstants(icmp: ir.IcmpInst) ?ir.Value {
    const lhs = icmp.lhs.int;
    const rhs = icmp.rhs.int;
    const result = switch (icmp.predicate) {
        .eq => lhs == rhs,
        .ne => lhs != rhs,
        .sgt => lhs > rhs,
        .sge => lhs >= rhs,
        .slt => lhs < rhs,
        .sle => lhs <= rhs,
        .ugt, .uge, .ult, .ule => blk: {
            const lhs_unsigned = unsignedInt(lhs, icmp.operand_ty) orelse return null;
            const rhs_unsigned = unsignedInt(rhs, icmp.operand_ty) orelse return null;
            break :blk switch (icmp.predicate) {
                .ugt => lhs_unsigned > rhs_unsigned,
                .uge => lhs_unsigned >= rhs_unsigned,
                .ult => lhs_unsigned < rhs_unsigned,
                .ule => lhs_unsigned <= rhs_unsigned,
                .eq, .ne, .sgt, .sge, .slt, .sle => unreachable,
            };
        },
    };
    return .{ .int = @intFromBool(result) };
}

fn simplifySelect(select: ir.SelectInst) ?ir.Value {
    if (select.true_value.eql(select.false_value)) return select.true_value;
    if (select.cond == .int) return if (select.cond.int == 0) select.false_value else select.true_value;
    return null;
}

fn simplifyCall(call: ir.CallInst) ?ir.Value {
    if (call.args.items.len != 2) return null;
    if (!isIntegerMinMaxIntrinsic(call.callee)) return null;
    if (!call.ret_ty.eql(call.args.items[0].ty)) return null;
    if (!call.ret_ty.eql(call.args.items[1].ty)) return null;

    const lhs = call.args.items[0].value;
    const rhs = call.args.items[1].value;
    if (lhs.eql(rhs)) return lhs;
    if (lhs != .int or rhs != .int) return null;

    return switch (intrinsicMinMaxKind(call.callee) orelse return null) {
        .smin => .{ .int = @min(lhs.int, rhs.int) },
        .smax => .{ .int = @max(lhs.int, rhs.int) },
        .umin => blk: {
            const lhs_unsigned = unsignedInt(lhs.int, call.ret_ty) orelse return null;
            const rhs_unsigned = unsignedInt(rhs.int, call.ret_ty) orelse return null;
            break :blk if (lhs_unsigned <= rhs_unsigned) lhs else rhs;
        },
        .umax => blk: {
            const lhs_unsigned = unsignedInt(lhs.int, call.ret_ty) orelse return null;
            const rhs_unsigned = unsignedInt(rhs.int, call.ret_ty) orelse return null;
            break :blk if (lhs_unsigned >= rhs_unsigned) lhs else rhs;
        },
    };
}

const MinMaxKind = enum {
    smin,
    smax,
    umin,
    umax,
};

fn isIntegerMinMaxIntrinsic(callee: []const u8) bool {
    return intrinsicMinMaxKind(callee) != null;
}

fn intrinsicMinMaxKind(callee: []const u8) ?MinMaxKind {
    if (std.mem.startsWith(u8, callee, "llvm.smin.")) return .smin;
    if (std.mem.startsWith(u8, callee, "llvm.smax.")) return .smax;
    if (std.mem.startsWith(u8, callee, "llvm.umin.")) return .umin;
    if (std.mem.startsWith(u8, callee, "llvm.umax.")) return .umax;
    return null;
}

fn isCommutative(op: ir.BinaryOp) bool {
    return switch (op) {
        .add, .mul, .@"and", .@"or", .xor => true,
        .sub, .shl, .lshr, .ashr, .udiv, .sdiv, .urem, .srem => false,
    };
}

fn unsignedInt(value: i128, ty: ir.Type) ?u128 {
    const bits = intBits(ty) orelse return null;
    if (bits >= 128) return null;
    if (value >= 0) return @intCast(value);
    const modulus: i128 = @as(i128, 1) << @intCast(bits);
    return @intCast(modulus + value);
}

fn isSignedMin(value: i128, ty: ir.Type) bool {
    const bits = intBits(ty) orelse return false;
    if (bits == 0 or bits >= 128) return false;
    return value == -(@as(i128, 1) << @intCast(bits - 1));
}

fn intBits(ty: ir.Type) ?u16 {
    return switch (ty) {
        .int => |bits| bits,
        .void, .ptr, .aggregate => null,
    };
}

fn isZero(value: ir.Value) bool {
    return value == .int and value.int == 0;
}

fn isOne(value: ir.Value) bool {
    return value == .int and value.int == 1;
}

fn isAllOnes(value: ir.Value) bool {
    return value == .int and value.int == -1;
}
