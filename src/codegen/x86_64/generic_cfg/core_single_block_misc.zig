const shared = @import("core_shared.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");
const cabi_call_lowering = @import("cabi_call_lowering.zig");

const std = shared.std;
const ir = shared.ir;
const MachineFunction = shared.MachineFunction;

const globalSymbolName = shared.globalSymbolName;
const i64Value = shared.i64Value;
const isInt = shared.isInt;
const isNamed = shared.isNamed;
const paramReg = cabi_abi_helpers.paramReg;
const paramValueReg = cabi_abi_helpers.paramValueReg;
const matchIcmpEqParamImm = cabi_call_lowering.matchIcmpEqParamImm;

pub fn lowerErrorUnionI64SelectReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 64 }) or !function.ret_ty.eql(.{ .int = 64 })) return false;
    if (function.params.items.len != 1) return false;
    if (try lowerNonzeroI32ErrorUnionReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerI8ClassifyErrorUnionReturn(allocator, machine, function, block, ret)) return true;
    return false;
}

pub fn lowerNonzeroI32ErrorUnionReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!function.params.items[0].ty.eql(.{ .int = 32 }) or block.instructions.items.len != 2) return false;
    const cmp_inst = block.instructions.items[0];
    const select_inst = block.instructions.items[1];
    if (cmp_inst.removed or select_inst.removed) return false;
    const cmp_name = cmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const cmp = switch (cmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (cmp.predicate != .ne or !cmp.operand_ty.eql(.{ .int = 32 })) return false;
    const arg_name = function.params.items[0].name;
    if (!isNamed(cmp.lhs, arg_name) or !isInt(cmp.rhs, 0)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 64 })) return false;
    if (!isNamed(select.cond, cmp_name)) return false;
    const error_value = try i64ValueConst(select.true_value);
    const ok_value = try i64ValueConst(select.false_value);
    const arg_reg = try paramReg(function, arg_name, .{ .int = 32 });
    const ok_label = "error_union_i64_ok";
    try machine.instructions.append(allocator, .{ .test_arg32 = arg_reg });
    try machine.instructions.append(allocator, .{ .je = ok_label });
    try machine.instructions.append(allocator, .{ .mov_imm_rax = error_value });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = ok_label });
    try machine.instructions.append(allocator, .{ .mov_imm_rax = ok_value });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerI8ClassifyErrorUnionReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!function.params.items[0].ty.eql(.{ .int = 8 }) or block.instructions.items.len != 4) return false;
    const cmp_one_inst = block.instructions.items[0];
    const cmp_zero_inst = block.instructions.items[1];
    const first_select_inst = block.instructions.items[2];
    const second_select_inst = block.instructions.items[3];
    if (cmp_one_inst.removed or cmp_zero_inst.removed or first_select_inst.removed or second_select_inst.removed) return false;
    const cmp_one_name = cmp_one_inst.result orelse return false;
    const cmp_zero_name = cmp_zero_inst.result orelse return false;
    const first_select_name = first_select_inst.result orelse return false;
    const second_select_name = second_select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, second_select_name)) return false;

    const arg_name = function.params.items[0].name;
    if (!matchIcmpEqParamImm(cmp_one_inst, arg_name, .{ .int = 8 }, 1)) return false;
    if (!matchIcmpEqParamImm(cmp_zero_inst, arg_name, .{ .int = 8 }, 0)) return false;

    const first_select = switch (first_select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!first_select.cond_ty.eql(.{ .int = 1 }) or !first_select.ty.eql(.{ .int = 64 })) return false;
    if (!isNamed(first_select.cond, cmp_one_name)) return false;
    const low_value = try i64ValueConst(first_select.true_value);
    const high_value = try i64ValueConst(first_select.false_value);

    const second_select = switch (second_select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!second_select.cond_ty.eql(.{ .int = 1 }) or !second_select.ty.eql(.{ .int = 64 })) return false;
    if (!isNamed(second_select.cond, cmp_zero_name) or !isNamed(second_select.false_value, first_select_name)) return false;
    const ok_value = try i64ValueConst(second_select.true_value);

    const tag_reg = try paramReg(function, arg_name, .{ .int = 8 });
    const zero_label = "error_union_i64_zero";
    const one_label = "error_union_i64_one";
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = tag_reg, .imm = 0 } });
    try machine.instructions.append(allocator, .{ .je = zero_label });
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = tag_reg, .imm = 1 } });
    try machine.instructions.append(allocator, .{ .je = one_label });
    try machine.instructions.append(allocator, .{ .mov_imm_rax = high_value });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = one_label });
    try machine.instructions.append(allocator, .{ .mov_imm_rax = low_value });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = zero_label });
    try machine.instructions.append(allocator, .{ .mov_imm_rax = ok_value });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn i64ValueConst(value: ir.Value) !i64 {
    return switch (value) {
        .int => |int| try i64Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => error.UnsupportedCodegenValue,
    };
}

pub fn lowerAtomicAddReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 1) return false;

    const atomic_inst = block.instructions.items[0];
    if (atomic_inst.removed) return false;
    const atomic_result = atomic_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, atomic_result)) return false;

    const atomic = switch (atomic_inst.kind) {
        .atomicrmw => |atomicrmw| atomicrmw,
        else => return false,
    };
    if (!std.mem.eql(u8, atomic.op, "add")) return false;
    if (!atomic.ty.eql(.{ .int = 32 })) return false;
    if (!std.mem.eql(u8, atomic.ordering, "monotonic")) return false;
    if (atomic.syncscope != null or atomic.is_volatile) return false;

    const value_reg = try paramValueReg(function, atomic.value, .{ .int = 32 });
    const global_name = switch (atomic.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    try machine.instructions.append(allocator, .{ .mov_arg_eax = value_reg });
    try machine.instructions.append(allocator, .{ .atomic_xadd_global_eax = global_name });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerAtomicTryLockReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 1 }) and !ret.ty.eql(.{ .int = 8 })) return false;
    _ = function;
    if (block.instructions.items.len < 1 or block.instructions.items.len > 2) return false;
    const first_inst = block.instructions.items[0];
    if (first_inst.removed) return false;
    const cmpxchg = switch (first_inst.kind) {
        .cmpxchg => |c| c,
        else => return false,
    };
    if (cmpxchg.ptr != .named or !std.mem.eql(u8, cmpxchg.ptr.named, "arg0")) return false;
    if (cmpxchg.expected != .int or cmpxchg.expected.int != 0) return false;
    if (cmpxchg.replacement != .int or cmpxchg.replacement.int != 1) return false;

    try machine.instructions.append(allocator, .atomic_try_lock_rdi_al);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgByteTableLookupReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 1) return false;
    if (block.instructions.items.len < 4 or block.instructions.items.len > 6) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 8 })) return false;

    const has_safety_cmp = block.instructions.items.len == 6;
    const has_mask = block.instructions.items.len == 5 or has_safety_cmp;
    const zext_index_index: usize = if (has_mask) 1 else 0;
    const safety_cmp_index: usize = 2;
    const gep_index: usize = if (has_safety_cmp) 3 else if (has_mask) 2 else 1;
    const load_index: usize = if (has_safety_cmp) 4 else if (has_mask) 3 else 2;
    const zext_result_index: usize = if (has_safety_cmp) 5 else if (has_mask) 4 else 3;
    const zext_index_name = block.instructions.items[zext_index_index].result orelse return false;
    const gep_name = block.instructions.items[gep_index].result orelse return false;
    const load_name = block.instructions.items[load_index].result orelse return false;
    const zext_result_name = block.instructions.items[zext_result_index].result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, zext_result_name)) return false;

    const param_name = function.params.items[0].name;
    var zext_value_name = param_name;
    if (has_mask) {
        const mask_name = block.instructions.items[0].result orelse return false;
        const mask = switch (block.instructions.items[0].kind) {
            .binary => |binary| binary,
            else => return false,
        };
        if (mask.op != .@"and" or !mask.ty.eql(.{ .int = 8 })) return false;
        if (!((isNamed(mask.lhs, param_name) and isInt(mask.rhs, 3)) or
            (isNamed(mask.rhs, param_name) and isInt(mask.lhs, 3))))
        {
            return false;
        }
        zext_value_name = mask_name;
    }

    const first_zext = switch (block.instructions.items[zext_index_index].kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (first_zext.op != .zext or !first_zext.from_ty.eql(.{ .int = 8 }) or !first_zext.to_ty.eql(.{ .int = 64 })) return false;
    if (!isNamed(first_zext.value, zext_value_name)) return false;

    if (has_safety_cmp) {
        const safety_cmp = switch (block.instructions.items[safety_cmp_index].kind) {
            .icmp => |icmp| icmp,
            else => return false,
        };
        if (safety_cmp.predicate != .ult or
            !safety_cmp.operand_ty.eql(.{ .int = 64 }) or
            !isNamed(safety_cmp.lhs, zext_index_name) or
            !isInt(safety_cmp.rhs, 4))
        {
            return false;
        }
    }

    const gep = switch (block.instructions.items[gep_index].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[4 x i8]" }) and !gep.source_ty.eql(.{ .aggregate = "[1 x i8]" })) return false;
    const table_symbol = switch (gep.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.startsWith(u8, table_symbol, "__anon_") and !std.mem.eql(u8, table_symbol, "__anon_base64_table")) return false;
    if (gep.indices.items.len == 2) {
        if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !gep.indices.items[0].value.eql(.{ .int = 0 })) return false;
        if (!gep.indices.items[1].ty.eql(.{ .int = 64 }) or !isNamed(gep.indices.items[1].value, zext_index_name)) return false;
    } else if (gep.indices.items.len == 1) {
        if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isNamed(gep.indices.items[0].value, zext_index_name)) return false;
    } else {
        return false;
    }

    const load = switch (block.instructions.items[load_index].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 8 }) or load.attrs.isBarrier() or !isNamed(load.ptr, gep_name)) return false;

    const result_zext = switch (block.instructions.items[zext_result_index].kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (result_zext.op != .zext or !result_zext.from_ty.eql(.{ .int = 8 }) or !result_zext.to_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(result_zext.value, load_name)) return false;

    try machine.instructions.append(allocator, .movzx_dil_edi);
    if (has_mask) try machine.instructions.append(allocator, .{ .and_edi_imm8 = 3 });
    try machine.instructions.append(allocator, .{ .lea_global_rax = table_symbol });
    try machine.instructions.append(allocator, .load_rax_rdi_u8_eax);
    try machine.instructions.append(allocator, .ret);
    return true;
}
