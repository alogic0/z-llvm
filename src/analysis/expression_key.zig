const std = @import("std");
const alias = @import("alias.zig");
const function_attrs = @import("function_attrs.zig");
const ir = @import("../ir.zig");

pub fn hash(instruction: ir.Instruction) u64 {
    var state = HashState.init();
    switch (instruction.kind) {
        .binary => |binary| {
            state.addTag(1);
            state.addTag(@intFromEnum(binary.op));
            state.addBool(binary.flags.nsw);
            state.addBool(binary.flags.nuw);
            state.addBool(binary.flags.exact);
            state.addBool(binary.flags.disjoint);
            state.addType(binary.ty);
            state.addValue(binary.lhs);
            state.addValue(binary.rhs);
        },
        .cast => |cast| {
            state.addTag(2);
            state.addTag(@intFromEnum(cast.op));
            state.addType(cast.from_ty);
            state.addValue(cast.value);
            state.addType(cast.to_ty);
        },
        .icmp => |icmp| {
            state.addTag(3);
            state.addTag(@intFromEnum(icmp.predicate));
            state.addType(icmp.operand_ty);
            state.addValue(icmp.lhs);
            state.addValue(icmp.rhs);
        },
        .fcmp => {
            state.addTag(0);
        },
        .select => |select| {
            state.addTag(4);
            state.addType(select.cond_ty);
            state.addValue(select.cond);
            state.addType(select.ty);
            state.addValue(select.true_value);
            state.addValue(select.false_value);
        },
        .phi => |phi| {
            state.addTag(5);
            state.addType(phi.ty);
            for (phi.incoming.items) |incoming| {
                state.addValue(incoming.value);
                state.addBytes(incoming.block);
            }
        },
        .load => {
            // Keep all loads in one bucket so alias-proven must-alias pointers
            // with different spelling are still compared by equality.
            return 0;
        },
        .call => |call| {
            state.addTag(6);
            state.addType(call.ret_ty);
            state.addBytes(call.callee);
            if (call.calling_conv) |calling_conv| state.addBytes(calling_conv);
            if (call.tail_kind) |tail_kind| state.addBytes(tail_kind);
            for (call.args.items) |arg| {
                state.addType(arg.ty);
                state.addValue(arg.value);
            }
        },
        .freeze, .alloca, .store, .gep => state.addTag(0),
    }
    return state.value;
}

pub fn sameValueExpression(module: ir.Module, function: ir.Function, a: ir.Instruction, b: ir.Instruction) bool {
    if (sameScalarExpression(a, b)) return true;
    if (sameLoadExpression(function, a, b)) return true;
    return sameReadnoneCall(module, a, b);
}

pub fn sameScalarExpression(a: ir.Instruction, b: ir.Instruction) bool {
    return switch (a.kind) {
        .binary => |a_binary| switch (b.kind) {
            .binary => |b_binary| a_binary.op != .fadd and
                !isFpBinary(a_binary.op) and
                !isFpBinary(b_binary.op) and
                a_binary.op == b_binary.op and
                a_binary.flags.nsw == b_binary.flags.nsw and
                a_binary.flags.nuw == b_binary.flags.nuw and
                a_binary.flags.exact == b_binary.flags.exact and
                a_binary.flags.disjoint == b_binary.flags.disjoint and
                a_binary.ty.eql(b_binary.ty) and
                a_binary.lhs.eql(b_binary.lhs) and
                a_binary.rhs.eql(b_binary.rhs),
            .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .load, .store, .gep, .call => false,
        },
        .cast => |a_cast| switch (b.kind) {
            .cast => |b_cast| a_cast.op == b_cast.op and
                a_cast.from_ty.eql(b_cast.from_ty) and
                a_cast.value.eql(b_cast.value) and
                a_cast.to_ty.eql(b_cast.to_ty),
            .binary, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .load, .store, .gep, .call => false,
        },
        .icmp => |a_icmp| switch (b.kind) {
            .icmp => |b_icmp| a_icmp.predicate == b_icmp.predicate and
                a_icmp.operand_ty.eql(b_icmp.operand_ty) and
                a_icmp.lhs.eql(b_icmp.lhs) and
                a_icmp.rhs.eql(b_icmp.rhs),
            .binary, .cast, .freeze, .fcmp, .select, .phi, .alloca, .load, .store, .gep, .call => false,
        },
        .fcmp => false,
        .select => |a_select| switch (b.kind) {
            .select => |b_select| a_select.cond_ty.eql(b_select.cond_ty) and
                a_select.cond.eql(b_select.cond) and
                a_select.ty.eql(b_select.ty) and
                a_select.true_value.eql(b_select.true_value) and
                a_select.false_value.eql(b_select.false_value),
            .binary, .cast, .freeze, .icmp, .fcmp, .phi, .alloca, .load, .store, .gep, .call => false,
        },
        .phi => |a_phi| switch (b.kind) {
            .phi => |b_phi| samePhi(a_phi, b_phi),
            .binary, .cast, .freeze, .icmp, .fcmp, .select, .alloca, .load, .store, .gep, .call => false,
        },
        .freeze, .alloca, .load, .store, .gep, .call => false,
    };
}

pub fn sameLoadExpression(function: ir.Function, a: ir.Instruction, b: ir.Instruction) bool {
    const a_load = switch (a.kind) {
        .load => |load| load,
        .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .store, .gep, .call => return false,
    };
    const b_load = switch (b.kind) {
        .load => |load| load,
        .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .store, .gep, .call => return false,
    };
    if (!a_load.ty.eql(b_load.ty)) return false;
    if (a_load.attrs.isBarrier() or b_load.attrs.isBarrier()) return false;
    return alias.alias(function, a_load.ptr, b_load.ptr) == .must_alias;
}

pub fn sameReadnoneCall(module: ir.Module, a: ir.Instruction, b: ir.Instruction) bool {
    const a_call = switch (a.kind) {
        .call => |call| call,
        .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .load, .store, .gep => return false,
    };
    const b_call = switch (b.kind) {
        .call => |call| call,
        .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .load, .store, .gep => return false,
    };
    if (function_attrs.callMemoryEffect(module, a_call) != .none) return false;
    if (function_attrs.callMemoryEffect(module, b_call) != .none) return false;
    if (!a_call.ret_ty.eql(b_call.ret_ty)) return false;
    if (!std.mem.eql(u8, a_call.callee, b_call.callee)) return false;
    if (!sameOptionalText(a_call.calling_conv, b_call.calling_conv)) return false;
    if (!sameOptionalText(a_call.tail_kind, b_call.tail_kind)) return false;
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

fn isFpBinary(op: ir.BinaryOp) bool {
    return op == .fadd or op == .fmul;
}

const HashState = struct {
    value: u64,

    fn init() HashState {
        return .{ .value = 14695981039346656037 };
    }

    fn addTag(state: *HashState, tag: usize) void {
        state.addInt(@intCast(tag));
    }

    fn addBool(state: *HashState, value: bool) void {
        state.addInt(if (value) 1 else 0);
    }

    fn addType(state: *HashState, ty: ir.Type) void {
        switch (ty) {
            .void => state.addTag(1),
            .int => |bits| {
                state.addTag(2);
                state.addInt(bits);
            },
            .float => state.addTag(3),
            .double => state.addTag(4),
            .ptr => state.addTag(5),
            .aggregate => |text| {
                state.addTag(6);
                state.addBytes(text);
            },
        }
    }

    fn addValue(state: *HashState, value: ir.Value) void {
        switch (value) {
            .named => |name| {
                state.addTag(1);
                state.addBytes(name);
            },
            .int => |int| {
                state.addTag(2);
                state.addInt128(int);
            },
            .undef => state.addTag(3),
        }
    }

    fn addBytes(state: *HashState, bytes: []const u8) void {
        for (bytes) |byte| state.addInt(byte);
        state.addInt(0xff);
    }

    fn addInt(state: *HashState, int: u64) void {
        var value = int;
        for (0..8) |_| {
            state.value ^= value & 0xff;
            state.value *%= 1099511628211;
            value >>= 8;
        }
    }

    fn addInt128(state: *HashState, int: i128) void {
        const bits: u128 = @bitCast(int);
        state.addInt(@truncate(bits));
        state.addInt(@truncate(bits >> 64));
    }
};
