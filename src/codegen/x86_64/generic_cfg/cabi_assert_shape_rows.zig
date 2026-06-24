const std = @import("std");
const ir = @import("../../../ir.zig");
const x86_64_match = @import("../match.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");
const f128_debug_rows = @import("cabi_f128_debug_rows.zig");

const isNamed = x86_64_match.isNamed;
const blockIndex = cabi_abi_helpers.blockIndex;
const validateI8GepOffset = f128_debug_rows.validateI8GepOffset;

pub fn validateAssertDCShape(function: ir.Function) !void {
    if (function.blocks.items.len == 10) return f128_debug_rows.validateDebugAssertDCShape(function);
    if (function.blocks.items.len < 3) return error.UnsupportedCodegenControlFlow;
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 8) return error.UnsupportedCodegenInstruction;

    const fcmp_name = entry.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    const fcmp = switch (entry.instructions.items[2].kind) {
        .fcmp => |fcmp| fcmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (fcmp.predicate != .une or !fcmp.operand_ty.eql(.double) or !isNamed(fcmp.lhs, function.params.items[0].name)) return error.UnsupportedCodegenInstruction;
    switch (fcmp.rhs) {
        .fp => |text| if (!std.mem.eql(u8, text, "-2.500000e-01")) return error.UnsupportedCodegenValue,
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }

    const zext_name = entry.instructions.items[3].result orelse return error.UnsupportedCodegenInstruction;
    const zext = switch (entry.instructions.items[3].kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 1 }) or !zext.to_ty.eql(.{ .int = 32 }) or !isNamed(zext.value, fcmp_name)) return error.UnsupportedCodegenInstruction;

    const and_name = entry.instructions.items[4].result orelse return error.UnsupportedCodegenInstruction;
    const and_inst = switch (entry.instructions.items[4].kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (and_inst.op != .@"and" or !and_inst.ty.eql(.{ .int = 64 }) or !isNamed(and_inst.lhs, function.params.items[1].name) or !and_inst.rhs.eql(.{ .int = 255 })) return error.UnsupportedCodegenInstruction;

    const low_cmp_name = entry.instructions.items[5].result orelse return error.UnsupportedCodegenInstruction;
    const low_cmp = switch (entry.instructions.items[5].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (low_cmp.predicate != .eq or !low_cmp.operand_ty.eql(.{ .int = 64 }) or !isNamed(low_cmp.lhs, and_name) or !low_cmp.rhs.eql(.{ .int = 15 })) return error.UnsupportedCodegenInstruction;

    const select_name = entry.instructions.items[6].result orelse return error.UnsupportedCodegenInstruction;
    const select = switch (entry.instructions.items[6].kind) {
        .select => |select| select,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!isNamed(select.cond, low_cmp_name) or !isNamed(select.true_value, zext_name) or !select.false_value.eql(.{ .int = 2 })) return error.UnsupportedCodegenInstruction;

    const zero_cmp_name = entry.instructions.items[7].result orelse return error.UnsupportedCodegenInstruction;
    const zero_cmp = switch (entry.instructions.items[7].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (zero_cmp.predicate != .eq or !zero_cmp.operand_ty.eql(.{ .int = 32 }) or !isNamed(zero_cmp.lhs, select_name) or !zero_cmp.rhs.eql(.{ .int = 0 })) return error.UnsupportedCodegenInstruction;

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, zero_cmp_name)) return error.UnsupportedCodegenControlFlow;
    const ok_index = blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget;
    const ok_ret = switch (function.blocks.items[ok_index].terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ok_ret.ty.eql(.{ .int = 32 }) or !isNamed(ok_ret.value orelse return error.InvalidRet, select_name)) return error.UnsupportedCodegenValue;
}

pub fn validateAssertCFFShape(function: ir.Function) !void {
    if (function.blocks.items.len == 13) return f128_debug_rows.validateDebugAssertCFFShape(function);
    if (function.blocks.items.len < 3) return error.UnsupportedCodegenControlFlow;
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 13) return error.UnsupportedCodegenInstruction;
    const lshr_name = entry.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    const lshr = switch (entry.instructions.items[2].kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (lshr.op != .lshr or !lshr.ty.eql(.{ .int = 64 }) or !isNamed(lshr.lhs, function.params.items[0].name) or !lshr.rhs.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;

    const trunc_name = entry.instructions.items[3].result orelse return error.UnsupportedCodegenInstruction;
    const trunc = switch (entry.instructions.items[3].kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (trunc.op != .trunc or !trunc.from_ty.eql(.{ .int = 64 }) or !trunc.to_ty.eql(.{ .int = 32 }) or !isNamed(trunc.value, lshr_name)) return error.UnsupportedCodegenInstruction;

    const bitcast_name = entry.instructions.items[4].result orelse return error.UnsupportedCodegenInstruction;
    const bitcast = switch (entry.instructions.items[4].kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (bitcast.op != .bitcast or !bitcast.from_ty.eql(.{ .int = 32 }) or !bitcast.to_ty.eql(.float) or !isNamed(bitcast.value, trunc_name)) return error.UnsupportedCodegenInstruction;

    const and_name = entry.instructions.items[5].result orelse return error.UnsupportedCodegenInstruction;
    const and_inst = switch (entry.instructions.items[5].kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (and_inst.op != .@"and" or !and_inst.ty.eql(.{ .int = 64 }) or !isNamed(and_inst.lhs, function.params.items[0].name) or !and_inst.rhs.eql(.{ .int = 255 })) return error.UnsupportedCodegenInstruction;

    const low_cmp_name = entry.instructions.items[6].result orelse return error.UnsupportedCodegenInstruction;
    const low_cmp = switch (entry.instructions.items[6].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (low_cmp.predicate != .ne or !low_cmp.operand_ty.eql(.{ .int = 64 }) or !isNamed(low_cmp.lhs, and_name) or !low_cmp.rhs.eql(.{ .int = 39 })) return error.UnsupportedCodegenInstruction;

    const zext_name = entry.instructions.items[7].result orelse return error.UnsupportedCodegenInstruction;
    const zext = switch (entry.instructions.items[7].kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 1 }) or !zext.to_ty.eql(.{ .int = 32 }) or !isNamed(zext.value, low_cmp_name)) return error.UnsupportedCodegenInstruction;

    const payload_cmp_name = entry.instructions.items[8].result orelse return error.UnsupportedCodegenInstruction;
    const payload_cmp = switch (entry.instructions.items[8].kind) {
        .fcmp => |fcmp| fcmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (payload_cmp.predicate != .une or !payload_cmp.operand_ty.eql(.float) or !isNamed(payload_cmp.lhs, bitcast_name)) return error.UnsupportedCodegenInstruction;

    const payload_select_name = entry.instructions.items[9].result orelse return error.UnsupportedCodegenInstruction;
    const payload_select = switch (entry.instructions.items[9].kind) {
        .select => |select| select,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!isNamed(payload_select.cond, payload_cmp_name) or !payload_select.true_value.eql(.{ .int = 2 }) or !isNamed(payload_select.false_value, zext_name)) return error.UnsupportedCodegenInstruction;

    const arg_cmp_name = entry.instructions.items[10].result orelse return error.UnsupportedCodegenInstruction;
    const arg_cmp = switch (entry.instructions.items[10].kind) {
        .fcmp => |fcmp| fcmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (arg_cmp.predicate != .une or !arg_cmp.operand_ty.eql(.float) or !isNamed(arg_cmp.lhs, function.params.items[1].name)) return error.UnsupportedCodegenInstruction;

    const final_select_name = entry.instructions.items[11].result orelse return error.UnsupportedCodegenInstruction;
    const final_select = switch (entry.instructions.items[11].kind) {
        .select => |select| select,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!isNamed(final_select.cond, arg_cmp_name) or !final_select.true_value.eql(.{ .int = 3 }) or !isNamed(final_select.false_value, payload_select_name)) return error.UnsupportedCodegenInstruction;

    const zero_cmp_name = entry.instructions.items[12].result orelse return error.UnsupportedCodegenInstruction;
    const zero_cmp = switch (entry.instructions.items[12].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (zero_cmp.predicate != .eq or !zero_cmp.operand_ty.eql(.{ .int = 32 }) or !isNamed(zero_cmp.lhs, final_select_name) or !zero_cmp.rhs.eql(.{ .int = 0 })) return error.UnsupportedCodegenInstruction;

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, zero_cmp_name)) return error.UnsupportedCodegenControlFlow;
    const ok_index = blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget;
    const ok_ret = switch (function.blocks.items[ok_index].terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ok_ret.ty.eql(.{ .int = 32 }) or !isNamed(ok_ret.value orelse return error.InvalidRet, final_select_name)) return error.UnsupportedCodegenValue;
}

pub fn validateAssertPDShape(function: ir.Function) !void {
    if (function.blocks.items.len == 10) return f128_debug_rows.validateDebugAssertPDShape(function);
    if (function.blocks.items.len != 3) return error.UnsupportedCodegenControlFlow;
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 6) return error.UnsupportedCodegenInstruction;
    const alloca_name = entry.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const alloca = switch (entry.instructions.items[0].kind) {
        .alloca => |alloca| alloca,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!alloca.allocated_ty.eql(.{ .aggregate = "{ %main.PD }" })) return error.UnsupportedCodegenType;

    const ptr_ne_name = entry.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    const ptr_ne = switch (entry.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (ptr_ne.predicate != .ne or !ptr_ne.operand_ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenInstruction;
    if (!isNamed(ptr_ne.lhs, function.params.items[0].name) or !ptr_ne.rhs.eql(.{ .int = 0 })) return error.UnsupportedCodegenValue;

    const zext_name = entry.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    const zext = switch (entry.instructions.items[2].kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 1 }) or !zext.to_ty.eql(.{ .int = 32 }) or !isNamed(zext.value, ptr_ne_name)) return error.UnsupportedCodegenInstruction;

    const fcmp_name = entry.instructions.items[3].result orelse return error.UnsupportedCodegenInstruction;
    const fcmp = switch (entry.instructions.items[3].kind) {
        .fcmp => |fcmp| fcmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (fcmp.predicate != .une or !fcmp.operand_ty.eql(.double)) return error.UnsupportedCodegenInstruction;
    if (!isNamed(fcmp.lhs, function.params.items[1].name)) return error.UnsupportedCodegenValue;
    switch (fcmp.rhs) {
        .fp => |text| if (!std.mem.eql(u8, text, "5.000000e-01")) return error.UnsupportedCodegenValue,
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }

    const select_name = entry.instructions.items[4].result orelse return error.UnsupportedCodegenInstruction;
    const select = switch (entry.instructions.items[4].kind) {
        .select => |select| select,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
    if (!isNamed(select.cond, fcmp_name) or !select.true_value.eql(.{ .int = 2 }) or !isNamed(select.false_value, zext_name)) return error.UnsupportedCodegenValue;

    const zero_cmp_name = entry.instructions.items[5].result orelse return error.UnsupportedCodegenInstruction;
    const zero_cmp = switch (entry.instructions.items[5].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (zero_cmp.predicate != .eq or !zero_cmp.operand_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
    if (!isNamed(zero_cmp.lhs, select_name) or !zero_cmp.rhs.eql(.{ .int = 0 })) return error.UnsupportedCodegenValue;

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, zero_cmp_name)) return error.UnsupportedCodegenControlFlow;
    const ok_index = blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget;
    const fail_index = blockIndex(function, condbr.else_target) orelse return error.InvalidBranchTarget;

    const ok_block = function.blocks.items[ok_index];
    if (ok_block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    const ok_ret = switch (ok_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ok_ret.ty.eql(.{ .int = 32 }) or !isNamed(ok_ret.value orelse return error.InvalidRet, select_name)) return error.UnsupportedCodegenValue;

    const fail_block = function.blocks.items[fail_index];
    if (fail_block.instructions.items.len != 4) return error.UnsupportedCodegenInstruction;
    const store_ptr = switch (fail_block.instructions.items[0].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!store_ptr.ty.eql(.{ .int = 64 }) or !isNamed(store_ptr.value, function.params.items[0].name) or !isNamed(store_ptr.ptr, alloca_name)) return error.UnsupportedCodegenValue;
    const gep_name = fail_block.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    const gep = switch (fail_block.instructions.items[1].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(gep, alloca_name, 8);
    const store_double = switch (fail_block.instructions.items[2].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!store_double.ty.eql(.double) or !isNamed(store_double.value, function.params.items[1].name) or !isNamed(store_double.ptr, gep_name)) return error.UnsupportedCodegenValue;
    const call = switch (fail_block.instructions.items[3].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.eql(u8, call.callee, "debug.print__anon_14634") or call.ret_ty != .void) return error.UnsupportedCodegenInstruction;
}
