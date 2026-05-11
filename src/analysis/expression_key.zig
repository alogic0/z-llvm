const std = @import("std");
const alias = @import("alias.zig");
const function_attrs = @import("function_attrs.zig");
const ir = @import("../ir.zig");

pub fn sameValueExpression(module: ir.Module, function: ir.Function, a: ir.Instruction, b: ir.Instruction) bool {
    if (sameScalarExpression(a, b)) return true;
    if (sameLoadExpression(function, a, b)) return true;
    return sameReadnoneCall(module, a, b);
}

pub fn sameScalarExpression(a: ir.Instruction, b: ir.Instruction) bool {
    return switch (a.kind) {
        .binary => |a_binary| switch (b.kind) {
            .binary => |b_binary| a_binary.op == b_binary.op and
                a_binary.flags.nsw == b_binary.flags.nsw and
                a_binary.flags.nuw == b_binary.flags.nuw and
                a_binary.flags.exact == b_binary.flags.exact and
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
        .freeze, .alloca, .load, .store, .gep, .call => false,
    };
}

pub fn sameLoadExpression(function: ir.Function, a: ir.Instruction, b: ir.Instruction) bool {
    const a_load = switch (a.kind) {
        .load => |load| load,
        .binary, .cast, .freeze, .icmp, .select, .phi, .alloca, .store, .gep, .call => return false,
    };
    const b_load = switch (b.kind) {
        .load => |load| load,
        .binary, .cast, .freeze, .icmp, .select, .phi, .alloca, .store, .gep, .call => return false,
    };
    if (!a_load.ty.eql(b_load.ty)) return false;
    if (a_load.attrs.isBarrier() or b_load.attrs.isBarrier()) return false;
    return alias.alias(function, a_load.ptr, b_load.ptr) == .must_alias;
}

pub fn sameReadnoneCall(module: ir.Module, a: ir.Instruction, b: ir.Instruction) bool {
    const a_call = switch (a.kind) {
        .call => |call| call,
        .binary, .cast, .freeze, .icmp, .select, .phi, .alloca, .load, .store, .gep => return false,
    };
    const b_call = switch (b.kind) {
        .call => |call| call,
        .binary, .cast, .freeze, .icmp, .select, .phi, .alloca, .load, .store, .gep => return false,
    };
    if (function_attrs.callMemoryEffect(module, a_call) != .none) return false;
    if (function_attrs.callMemoryEffect(module, b_call) != .none) return false;
    if (!a_call.ret_ty.eql(b_call.ret_ty)) return false;
    if (!std.mem.eql(u8, a_call.callee, b_call.callee)) return false;
    if (!sameOptionalText(a_call.calling_conv, b_call.calling_conv)) return false;
    if (a_call.args.items.len != b_call.args.items.len) return false;
    for (a_call.args.items, b_call.args.items) |a_arg, b_arg| {
        if (!a_arg.ty.eql(b_arg.ty)) return false;
        if (!a_arg.value.eql(b_arg.value)) return false;
    }
    return true;
}

fn samePhi(a: ir.PhiInst, b: ir.PhiInst) bool {
    if (!a.ty.eql(b.ty) or a.incoming.items.len != b.incoming.items.len) return false;
    for (a.incoming.items, b.incoming.items) |a_incoming, b_incoming| {
        if (!a_incoming.value.eql(b_incoming.value)) return false;
        if (!std.mem.eql(u8, a_incoming.block, b_incoming.block)) return false;
    }
    return true;
}

fn sameOptionalText(a: ?[]const u8, b: ?[]const u8) bool {
    if (a == null and b == null) return true;
    if (a == null or b == null) return false;
    return std.mem.eql(u8, a.?, b.?);
}
