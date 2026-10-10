const std = @import("std");
const air_model = @import("zig_air_model.zig");
const ir = @import("ir.zig");

const ZigType = air_model.ZigType;

pub fn binaryOp(opcode: []const u8, ty: ZigType) ?ir.BinaryOp {
    const fp = isFpType(ty.ir_type);
    if (std.mem.startsWith(u8, opcode, "add")) return if (fp) .fadd else .add;
    if (std.mem.startsWith(u8, opcode, "sub")) return if (fp) .fsub else .sub;
    if (std.mem.startsWith(u8, opcode, "mul")) return if (fp) .fmul else .mul;
    if (std.mem.startsWith(u8, opcode, "div_float")) return .fdiv;
    if (std.mem.startsWith(u8, opcode, "div_")) return if (ty.signed) .sdiv else .udiv;
    if (std.mem.startsWith(u8, opcode, "rem")) return if (fp) .frem else if (ty.signed) .srem else .urem;
    if (std.mem.startsWith(u8, opcode, "mod")) return if (ty.signed) .srem else .urem;
    if (std.mem.eql(u8, opcode, "bit_and")) return .@"and";
    if (std.mem.eql(u8, opcode, "bit_or")) return .@"or";
    if (std.mem.eql(u8, opcode, "xor")) return .xor;
    if (std.mem.startsWith(u8, opcode, "shl")) return .shl;
    if (std.mem.startsWith(u8, opcode, "shr")) return if (ty.signed) .ashr else .lshr;
    return null;
}

pub fn intPredicate(opcode: []const u8, signed: bool) ?ir.IcmpPredicate {
    if (std.mem.startsWith(u8, opcode, "cmp_eq")) return .eq;
    if (std.mem.startsWith(u8, opcode, "cmp_neq")) return .ne;
    if (std.mem.startsWith(u8, opcode, "cmp_lte")) return if (signed) .sle else .ule;
    if (std.mem.startsWith(u8, opcode, "cmp_lt")) return if (signed) .slt else .ult;
    if (std.mem.startsWith(u8, opcode, "cmp_gte")) return if (signed) .sge else .uge;
    if (std.mem.startsWith(u8, opcode, "cmp_gt")) return if (signed) .sgt else .ugt;
    return null;
}

pub fn fpPredicate(opcode: []const u8) ?ir.FcmpPredicate {
    if (std.mem.startsWith(u8, opcode, "cmp_eq")) return .oeq;
    if (std.mem.startsWith(u8, opcode, "cmp_neq")) return .one;
    if (std.mem.startsWith(u8, opcode, "cmp_lte")) return .ole;
    if (std.mem.startsWith(u8, opcode, "cmp_lt")) return .olt;
    if (std.mem.startsWith(u8, opcode, "cmp_gte")) return .oge;
    if (std.mem.startsWith(u8, opcode, "cmp_gt")) return .ogt;
    return null;
}

pub fn castOp(opcode: []const u8, from: ZigType, to: ZigType) ?ir.CastOp {
    if (std.mem.eql(u8, opcode, "trunc")) return .trunc;
    if (std.mem.eql(u8, opcode, "bitcast") or
        std.mem.eql(u8, opcode, "bit_cast") or
        std.mem.eql(u8, opcode, "bit_cast_safe") or
        std.mem.eql(u8, opcode, "bitcast_safe") or
        std.mem.eql(u8, opcode, "ptr_cast")) return .bitcast;
    if (std.mem.eql(u8, opcode, "ptrtoint") or
        std.mem.eql(u8, opcode, "int_from_ptr")) return .ptrtoint;
    if (std.mem.eql(u8, opcode, "inttoptr") or
        std.mem.eql(u8, opcode, "ptr_from_int")) return .inttoptr;
    if (std.mem.eql(u8, opcode, "float_from_int")) return if (from.signed) .sitofp else .uitofp;
    if (std.mem.eql(u8, opcode, "int_from_float")) return if (to.signed) .fptosi else .fptoui;
    if (std.mem.eql(u8, opcode, "fpext")) return .fpext;
    if (std.mem.eql(u8, opcode, "fptrunc")) return .fptrunc;
    if (!std.mem.eql(u8, opcode, "intcast") and
        !std.mem.eql(u8, opcode, "intcast_safe") and
        !std.mem.eql(u8, opcode, "int_cast") and
        !std.mem.eql(u8, opcode, "int_cast_safe")) return null;
    const from_bits = intBits(from.ir_type) orelse return null;
    const to_bits = intBits(to.ir_type) orelse return null;
    if (to_bits < from_bits) return .trunc;
    if (to_bits > from_bits) return if (from.signed) .sext else .zext;
    return .bitcast;
}

pub fn isFpType(ty: ir.Type) bool {
    return ty == .float or ty == .double or ty == .fp128;
}

pub fn intBits(ty: ir.Type) ?u16 {
    return switch (ty) {
        .int => |bits| bits,
        else => null,
    };
}

test "safe intcast shares integer cast semantics" {
    const unsigned64: ZigType = .{ .ir_type = .{ .int = 64 } };
    const unsigned32: ZigType = .{ .ir_type = .{ .int = 32 } };
    const signed32: ZigType = .{ .ir_type = .{ .int = 32 }, .signed = true };
    try std.testing.expectEqual(ir.CastOp.trunc, castOp("intcast_safe", unsigned64, unsigned32).?);
    try std.testing.expectEqual(ir.CastOp.zext, castOp("intcast_safe", unsigned32, unsigned64).?);
    try std.testing.expectEqual(ir.CastOp.sext, castOp("intcast_safe", signed32, unsigned64).?);
    try std.testing.expectEqual(ir.CastOp.bitcast, castOp("intcast_safe", unsigned64, unsigned64).?);
    try std.testing.expectEqual(ir.CastOp.trunc, castOp("int_cast", unsigned64, unsigned32).?);
    try std.testing.expectEqual(ir.CastOp.zext, castOp("int_cast", unsigned32, unsigned64).?);
    try std.testing.expectEqual(ir.CastOp.sext, castOp("int_cast_safe", signed32, unsigned64).?);
}
