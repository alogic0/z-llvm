const std = @import("std");
const ir = @import("../../ir.zig");
const x86_64_types = @import("types.zig");
const x86_64_machine = @import("machine.zig");
const x86_64_match = @import("match.zig");

const MachineFunction = x86_64_machine.MachineFunction;
const ArgReg = x86_64_types.ArgReg;
const globalSymbolName = x86_64_match.globalSymbolName;
const isNamed = x86_64_match.isNamed;
const isInt = x86_64_match.isInt;
const i32Value = x86_64_match.i32Value;
const isCalleeName = x86_64_match.isCalleeName;
const validateDefaultCallConv = x86_64_match.validateDefaultCallConv;
const symbolName = x86_64_match.symbolName;

const ExpectedCallArg = struct {
    ty: ir.Type,
    value: ir.Value,
};

fn validateVoidCall(instruction: ir.Instruction, callee: []const u8, expected_args: []const ExpectedCallArg) !void {
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!isCalleeName(call.callee, callee) or call.ret_ty != .void) return error.UnsupportedCodegenInstruction;
    if (call.args.items.len != expected_args.len) return error.UnsupportedCodegenInstruction;
    for (expected_args, 0..) |expected, index| {
        if (!call.args.items[index].ty.eql(expected.ty) or !call.args.items[index].value.eql(expected.value)) return error.UnsupportedCodegenValue;
    }
}

fn validateTerminatorBr(block: ir.BasicBlock) ![]const u8 {
    return switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br.target,
        else => error.UnsupportedCodegenControlFlow,
    };
}

pub fn lowerBase64TableLookupMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or !ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 7) return false;

    const idx8_name = block.instructions.items[0].result orelse return false;
    const idx_name = block.instructions.items[1].result orelse return false;
    const ptr_name = block.instructions.items[2].result orelse return false;
    const byte_name = block.instructions.items[3].result orelse return false;
    const value_name = block.instructions.items[4].result orelse return false;
    const ok_name = block.instructions.items[5].result orelse return false;
    const ret_name = block.instructions.items[6].result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, ret_name)) return false;

    const trunc = switch (block.instructions.items[0].kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (trunc.op != .trunc or !trunc.from_ty.eql(.{ .int = 32 }) or !trunc.to_ty.eql(.{ .int = 8 }) or !isInt(trunc.value, 3)) return false;

    const zext_index = switch (block.instructions.items[1].kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (zext_index.op != .zext or !zext_index.from_ty.eql(.{ .int = 8 }) or !zext_index.to_ty.eql(.{ .int = 64 }) or !isNamed(zext_index.value, idx8_name)) return false;

    const gep = switch (block.instructions.items[2].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[4 x i8]" })) return false;
    const table_symbol = switch (gep.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, table_symbol, "base64.writer_table")) return false;
    if (gep.indices.items.len != 2) return false;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, 0)) return false;
    if (!gep.indices.items[1].ty.eql(.{ .int = 64 }) or !isNamed(gep.indices.items[1].value, idx_name)) return false;

    const load = switch (block.instructions.items[3].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 8 }) or load.attrs.isBarrier() or !isNamed(load.ptr, ptr_name)) return false;

    const zext_value = switch (block.instructions.items[4].kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (zext_value.op != .zext or !zext_value.from_ty.eql(.{ .int = 8 }) or !zext_value.to_ty.eql(.{ .int = 32 }) or !isNamed(zext_value.value, byte_name)) return false;

    const icmp = switch (block.instructions.items[5].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 }) or !isNamed(icmp.lhs, value_name) or !isInt(icmp.rhs, 12)) return false;

    const select = switch (block.instructions.items[6].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, ok_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
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

pub fn lowerBase64DecodeStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 13) return false;

    const v0_name = (try validateBase64DecodeStepLoad(block.instructions.items[0], block.instructions.items[1], 0)) orelse return false;
    const v1_name = (try validateBase64DecodeStepLoad(block.instructions.items[2], block.instructions.items[3], 5)) orelse return false;
    const word1_name = block.instructions.items[4].result orelse return false;
    try validateNamedOr(block.instructions.items[4], v1_name, v0_name);

    const v2_name = (try validateBase64DecodeStepLoad(block.instructions.items[5], block.instructions.items[6], 9)) orelse return false;
    const word2_name = block.instructions.items[7].result orelse return false;
    try validateNamedOr(block.instructions.items[7], word1_name, v2_name);

    const v3_name = (try validateBase64DecodeStepLoad(block.instructions.items[8], block.instructions.items[9], 13)) orelse return false;
    const word_name = block.instructions.items[10].result orelse return false;
    try validateNamedOr(block.instructions.items[10], word2_name, v3_name);

    const valid_name = block.instructions.items[11].result orelse return false;
    const icmp = switch (block.instructions.items[11].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .ult or !icmp.operand_ty.eql(.{ .int = 32 }) or !isNamed(icmp.lhs, word_name) or !isInt(icmp.rhs, 16777216)) return false;

    const select_name = block.instructions.items[12].result orelse return false;
    const select = switch (block.instructions.items[12].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, valid_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerBase64StoreStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 5) return false;

    const dst_name = block.instructions.items[0].result orelse return false;
    const check_name = block.instructions.items[2].result orelse return false;
    const ok_name = block.instructions.items[3].result orelse return false;
    const select_name = block.instructions.items[4].result orelse return false;

    const gep = switch (block.instructions.items[0].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[1 x i8]" })) return false;
    const output_symbol = switch (gep.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, output_symbol, "base64.decode_output")) return false;
    if (gep.indices.items.len != 1) return false;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, 0)) return false;

    const store = switch (block.instructions.items[1].kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 32 }) or !isInt(store.value, 2105344) or !isNamed(store.ptr, dst_name)) return false;

    const load = switch (block.instructions.items[2].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier() or !isNamed(load.ptr, dst_name)) return false;

    const icmp = switch (block.instructions.items[3].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 }) or !isNamed(icmp.lhs, check_name) or !isInt(icmp.rhs, 2105344)) return false;

    const select = switch (block.instructions.items[4].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, ok_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 2105344 });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = "base64.decode_output" });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerBase64ResidualByteStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 5) return false;

    const dst_name = block.instructions.items[0].result orelse return false;
    const check_name = block.instructions.items[2].result orelse return false;
    const ok_name = block.instructions.items[3].result orelse return false;
    const select_name = block.instructions.items[4].result orelse return false;

    const gep = switch (block.instructions.items[0].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[1 x i8]" })) return false;
    const output_symbol = switch (gep.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, output_symbol, "base64.residual_output")) return false;
    if (gep.indices.items.len != 1) return false;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, 0)) return false;

    const store = switch (block.instructions.items[1].kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 8 }) or !isInt(store.value, 63) or !isNamed(store.ptr, dst_name)) return false;

    const load = switch (block.instructions.items[2].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 8 }) or load.attrs.isBarrier() or !isNamed(load.ptr, dst_name)) return false;

    const icmp = switch (block.instructions.items[3].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 8 }) or !isNamed(icmp.lhs, check_name) or !isInt(icmp.rhs, 63)) return false;

    const select = switch (block.instructions.items[4].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, ok_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 63 });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = "base64.residual_output" });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerBase64ResidualStoreStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 10) return false;

    const word_name = (try validateBase64BitBufferI32GlobalLoad(block.instructions.items[0], "base64.residual_store_word")) orelse return false;
    const dst_name = block.instructions.items[1].result orelse return false;
    const check_name = block.instructions.items[3].result orelse return false;
    const store_ok_name = block.instructions.items[4].result orelse return false;
    const remaining_name = (try validateBase64ResidualGuardI64GlobalLoad(block.instructions.items[5], "base64.residual_store_remaining")) orelse return false;
    const next_name = block.instructions.items[6].result orelse return false;
    const next_ok_name = block.instructions.items[7].result orelse return false;
    const ok_name = block.instructions.items[8].result orelse return false;
    const select_name = block.instructions.items[9].result orelse return false;

    const gep = switch (block.instructions.items[1].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[1 x i8]" })) return false;
    const output_symbol = switch (gep.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, output_symbol, "base64.residual_store_output")) return false;
    if (gep.indices.items.len != 1) return false;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, 0)) return false;

    const store = switch (block.instructions.items[2].kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 32 }) or store.attrs.isBarrier() or !isNamed(store.value, word_name) or !isNamed(store.ptr, dst_name)) return false;

    const check_load = switch (block.instructions.items[3].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!check_load.ty.eql(.{ .int = 32 }) or check_load.attrs.isBarrier() or !isNamed(check_load.ptr, dst_name)) return false;

    const store_ok = switch (block.instructions.items[4].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (store_ok.predicate != .eq or !store_ok.operand_ty.eql(.{ .int = 32 }) or !isNamed(store_ok.lhs, check_name) or !isNamed(store_ok.rhs, word_name)) return false;

    const next = switch (block.instructions.items[6].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (next.op != .add or !next.ty.eql(.{ .int = 64 }) or next.flags.any()) return false;
    if (!isNamed(next.lhs, remaining_name) or !isInt(next.rhs, -4)) return false;

    const next_ok = switch (block.instructions.items[7].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (next_ok.predicate != .eq or !next_ok.operand_ty.eql(.{ .int = 64 }) or !isNamed(next_ok.lhs, next_name) or !isInt(next_ok.rhs, 0)) return false;

    const ok_select = switch (block.instructions.items[8].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!ok_select.cond_ty.eql(.{ .int = 1 }) or !ok_select.ty.eql(.{ .int = 1 })) return false;
    if (!isNamed(ok_select.cond, store_ok_name) or !isNamed(ok_select.true_value, next_ok_name) or !isInt(ok_select.false_value, 0)) return false;

    const ret_select = switch (block.instructions.items[9].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!ret_select.cond_ty.eql(.{ .int = 1 }) or !ret_select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(ret_select.cond, ok_name) or !isInt(ret_select.true_value, 0) or !isInt(ret_select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 2105344 });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = "base64.residual_store_output" });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerBase64ResidualLengthStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 5) return false;

    const total_name = (try validateBase64ResidualGuardI64GlobalLoad(block.instructions.items[0], "base64.residual_length_total")) orelse return false;
    const index_name = (try validateBase64ResidualGuardI64GlobalLoad(block.instructions.items[1], "base64.residual_length_index")) orelse return false;
    const remaining_name = block.instructions.items[2].result orelse return false;
    const ok_name = block.instructions.items[3].result orelse return false;
    const select_name = block.instructions.items[4].result orelse return false;

    const sub = switch (block.instructions.items[2].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (sub.op != .sub or !sub.ty.eql(.{ .int = 64 }) or !sub.flags.nuw or sub.flags.nsw or sub.flags.exact or sub.flags.disjoint) return false;
    if (!isNamed(sub.lhs, total_name) or !isNamed(sub.rhs, index_name)) return false;

    const icmp = switch (block.instructions.items[3].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 64 }) or !isNamed(icmp.lhs, remaining_name) or !isInt(icmp.rhs, 4)) return false;

    const select = switch (block.instructions.items[4].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, ok_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerBase64ResidualTableCheckStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 7) return false;

    const src_name = (try validateBase64ResidualTableCheckGep(block.instructions.items[0], "base64.residual_table_check_input", null)) orelse return false;
    const byte_name = (try validateBase64ResidualTableCheckI8Load(block.instructions.items[1], src_name)) orelse return false;
    const idx_name = validateBase64SourceBundleZext(block.instructions.items[2], byte_name) orelse return false;
    const entry_ptr_name = (try validateBase64ResidualTableCheckGep(block.instructions.items[3], "base64.residual_table_check_table", idx_name)) orelse return false;
    const entry_name = (try validateBase64ResidualTableCheckI8Load(block.instructions.items[4], entry_ptr_name)) orelse return false;
    const invalid_name = (try validateBase64ResidualTableCheckI8Eq(block.instructions.items[5], entry_name, -1)) orelse return false;

    const select_name = block.instructions.items[6].result orelse return false;
    const select = switch (block.instructions.items[6].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, invalid_name) or !isInt(select.true_value, 1) or !isInt(select.false_value, 0)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn validateBase64ResidualTableCheckGep(instruction: ir.Instruction, symbol_name: []const u8, index_name: ?[]const u8) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const gep = switch (instruction.kind) {
        .gep => |gep| gep,
        else => return null,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[1 x i8]" })) return null;
    const symbol = switch (gep.ptr) {
        .named => |name| blk: {
            if (!std.mem.startsWith(u8, name, "@")) return null;
            break :blk try globalSymbolName(name);
        },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!std.mem.eql(u8, symbol, symbol_name)) return null;
    if (gep.indices.items.len != 1) return null;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 })) return null;
    if (index_name) |name| {
        if (!isNamed(gep.indices.items[0].value, name)) return null;
    } else if (!isInt(gep.indices.items[0].value, 0)) return null;
    return result_name;
}

pub fn validateBase64ResidualTableCheckI8Load(instruction: ir.Instruction, ptr_name: []const u8) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const load = switch (instruction.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 8 }) or load.attrs.isBarrier() or !isNamed(load.ptr, ptr_name)) return null;
    return result_name;
}

pub fn validateBase64ResidualTableCheckI8Eq(instruction: ir.Instruction, lhs_name: []const u8, rhs_value: i128) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 8 })) return null;
    if (!isNamed(icmp.lhs, lhs_name) or !isInt(icmp.rhs, rhs_value)) return null;
    return result_name;
}

pub fn lowerBase64ResidualAccumulatorStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 13) return false;

    const bits_raw_name = (try validateBase64ResidualAccumulatorGlobalLoad(block.instructions.items[0], "base64.residual_accumulator_bits", 16)) orelse return false;
    const bits_name = validateBase64ResidualAccumulatorCast(block.instructions.items[1], .trunc, bits_raw_name, 16, 12) orelse return false;
    const shifted_name = validateBase64ResidualAccumulatorBinary(block.instructions.items[2], .shl, bits_name, null, 6, 12, false) orelse return false;
    const entry_raw_name = (try validateBase64ResidualAccumulatorGlobalLoad(block.instructions.items[3], "base64.residual_accumulator_entry", 8)) orelse return false;
    const entry_bits_name = validateBase64ResidualAccumulatorCast(block.instructions.items[4], .zext, entry_raw_name, 8, 12) orelse return false;
    const next_bits_name = validateBase64ResidualAccumulatorBinary(block.instructions.items[5], .add, shifted_name, entry_bits_name, 0, 12, true) orelse return false;
    try validateBase64ResidualAccumulatorStore(block.instructions.items[6], next_bits_name, "base64.residual_accumulator_bits", 12);

    const count_raw_name = (try validateBase64ResidualAccumulatorGlobalLoad(block.instructions.items[7], "base64.residual_accumulator_count", 8)) orelse return false;
    const count_name = validateBase64ResidualAccumulatorCast(block.instructions.items[8], .trunc, count_raw_name, 8, 4) orelse return false;
    const next_count_name = validateBase64ResidualAccumulatorBinary(block.instructions.items[9], .add, count_name, null, 6, 4, true) orelse return false;
    try validateBase64ResidualAccumulatorStore(block.instructions.items[10], next_count_name, "base64.residual_accumulator_count", 4);

    const ok_name = (try validateBase64ResidualTableCheckI8EqTyped(block.instructions.items[11], next_count_name, 6, 4)) orelse return false;
    const select_name = block.instructions.items[12].result orelse return false;
    const select = switch (block.instructions.items[12].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, ok_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn validateBase64ResidualAccumulatorGlobalLoad(instruction: ir.Instruction, symbol_name: []const u8, bits: u16) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const load = switch (instruction.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = bits }) or load.attrs.isBarrier()) return null;
    if (!try valueIsGlobalSymbol(load.ptr, symbol_name)) return null;
    return result_name;
}

pub fn validateBase64ResidualAccumulatorCast(
    instruction: ir.Instruction,
    op: ir.CastOp,
    value_name: []const u8,
    from_bits: u16,
    to_bits: u16,
) ?[]const u8 {
    const result_name = instruction.result orelse return null;
    const cast = switch (instruction.kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (cast.op != op or !cast.from_ty.eql(.{ .int = from_bits }) or !cast.to_ty.eql(.{ .int = to_bits }) or !isNamed(cast.value, value_name)) return null;
    return result_name;
}

pub fn validateBase64ResidualAccumulatorBinary(
    instruction: ir.Instruction,
    op: ir.BinaryOp,
    lhs_name: []const u8,
    rhs_name: ?[]const u8,
    rhs_value: i128,
    bits: u16,
    require_nuw: bool,
) ?[]const u8 {
    const result_name = instruction.result orelse return null;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (binary.op != op or !binary.ty.eql(.{ .int = bits })) return null;
    if (binary.flags.nuw != require_nuw or binary.flags.nsw or binary.flags.exact or binary.flags.disjoint) return null;
    if (!isNamed(binary.lhs, lhs_name)) return null;
    if (rhs_name) |name| {
        if (!isNamed(binary.rhs, name)) return null;
    } else if (!isInt(binary.rhs, rhs_value)) return null;
    return result_name;
}

pub fn validateBase64ResidualAccumulatorStore(instruction: ir.Instruction, value_name: []const u8, symbol_name: []const u8, bits: u16) !void {
    const store = switch (instruction.kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!store.ty.eql(.{ .int = bits }) or store.attrs.isBarrier() or !isNamed(store.value, value_name)) return error.UnsupportedCodegenInstruction;
    if (!try valueIsGlobalSymbol(store.ptr, symbol_name)) return error.UnsupportedCodegenInstruction;
}

pub fn validateBase64ResidualTableCheckI8EqTyped(instruction: ir.Instruction, lhs_name: []const u8, rhs_value: i128, bits: u16) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = bits })) return null;
    if (!isNamed(icmp.lhs, lhs_name) or !isInt(icmp.rhs, rhs_value)) return null;
    return result_name;
}

pub fn valueIsGlobalSymbol(value: ir.Value, symbol_name: []const u8) !bool {
    const symbol = switch (value) {
        .named => |name| blk: {
            if (!std.mem.startsWith(u8, name, "@")) return false;
            break :blk try globalSymbolName(name);
        },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    return std.mem.eql(u8, symbol, symbol_name);
}

pub fn lowerBase64ResidualLoopAdvanceStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 4) return false;

    const index_name = (try validateBase64ResidualGuardI64GlobalLoad(block.instructions.items[0], "base64.residual_loop_index")) orelse return false;
    const next_name = block.instructions.items[1].result orelse return false;
    const ok_name = block.instructions.items[2].result orelse return false;
    const select_name = block.instructions.items[3].result orelse return false;

    const add = switch (block.instructions.items[1].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 64 }) or !add.flags.nuw or add.flags.nsw or add.flags.exact or add.flags.disjoint) return false;
    if (!isNamed(add.lhs, index_name) or !isInt(add.rhs, 1)) return false;

    const icmp = switch (block.instructions.items[2].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 64 }) or !isNamed(icmp.lhs, next_name) or !isInt(icmp.rhs, 1)) return false;

    const select = switch (block.instructions.items[3].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, ok_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerBase64ResidualPaddingCheckStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 8) return false;

    const index_name = (try validateBase64ResidualGuardI64GlobalLoad(block.instructions.items[0], "base64.residual_padding_index")) orelse return false;
    const base_name = (try validateBase64ResidualGuardI64GlobalLoad(block.instructions.items[1], "base64.residual_padding_base")) orelse return false;
    const offset_name = validateBase64ResidualAccumulatorBinary(block.instructions.items[2], .add, index_name, base_name, 0, 64, true) orelse return false;
    const offset_ok_name = (try validateBase64ResidualTableCheckI8EqTyped(block.instructions.items[3], offset_name, 4, 64)) orelse return false;
    const byte_name = (try validateBase64ResidualAccumulatorGlobalLoad(block.instructions.items[4], "base64.residual_padding_byte", 8)) orelse return false;
    const pad_ok_name = (try validateBase64ResidualTableCheckI8EqTyped(block.instructions.items[5], byte_name, 61, 8)) orelse return false;

    const ok_name = block.instructions.items[6].result orelse return false;
    const ok_select = switch (block.instructions.items[6].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!ok_select.cond_ty.eql(.{ .int = 1 }) or !ok_select.ty.eql(.{ .int = 1 })) return false;
    if (!isNamed(ok_select.cond, offset_ok_name) or !isNamed(ok_select.true_value, pad_ok_name) or !isInt(ok_select.false_value, 0)) return false;

    const select_name = block.instructions.items[7].result orelse return false;
    const select = switch (block.instructions.items[7].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, ok_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerBase64ResidualFinalMaskStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 14) return false;

    const index_name = (try validateBase64ResidualGuardI64GlobalLoad(block.instructions.items[0], "base64.residual_final_index")) orelse return false;
    const remaining_name = (try validateBase64ResidualGuardI64GlobalLoad(block.instructions.items[1], "base64.residual_final_remaining")) orelse return false;
    const done_name = (try validateBase64ResidualFinalMaskI64IcmpUge(block.instructions.items[2], index_name, remaining_name)) orelse return false;
    const bits_raw_name = (try validateBase64ResidualAccumulatorGlobalLoad(block.instructions.items[3], "base64.residual_final_bits", 16)) orelse return false;
    const bits_name = validateBase64ResidualAccumulatorCast(block.instructions.items[4], .trunc, bits_raw_name, 16, 12) orelse return false;
    const shift_raw_name = (try validateBase64ResidualAccumulatorGlobalLoad(block.instructions.items[5], "base64.residual_final_shift", 8)) orelse return false;
    const shift_name = validateBase64ResidualAccumulatorBinary(block.instructions.items[6], .@"and", shift_raw_name, null, 7, 8, false) orelse return false;
    const shift_bits_name = validateBase64ResidualAccumulatorCast(block.instructions.items[7], .zext, shift_name, 8, 12) orelse return false;
    const notmask_name = validateBase64ResidualFinalMaskIntNamedShl(block.instructions.items[8], -1, shift_bits_name, 12) orelse return false;
    const mask_name = validateBase64ResidualAccumulatorBinary(block.instructions.items[9], .xor, notmask_name, null, -1, 12, false) orelse return false;
    const residual_name = validateBase64ResidualAccumulatorBinary(block.instructions.items[10], .@"and", bits_name, mask_name, 0, 12, false) orelse return false;
    const has_residual_name = (try validateBase64ResidualFinalMaskIcmpTyped(block.instructions.items[11], .ne, residual_name, 0, 12)) orelse return false;
    const fail_name = validateBase64ResidualAccumulatorBinary(block.instructions.items[12], .@"or", done_name, has_residual_name, 0, 1, false) orelse return false;

    const select_name = block.instructions.items[13].result orelse return false;
    const select = switch (block.instructions.items[13].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, fail_name) or !isInt(select.true_value, 1) or !isInt(select.false_value, 0)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn validateBase64ResidualFinalMaskI64IcmpUge(instruction: ir.Instruction, lhs_name: []const u8, rhs_name: []const u8) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (icmp.predicate != .uge or !icmp.operand_ty.eql(.{ .int = 64 })) return null;
    if (!isNamed(icmp.lhs, lhs_name) or !isNamed(icmp.rhs, rhs_name)) return null;
    return result_name;
}

pub fn validateBase64ResidualFinalMaskIntNamedShl(instruction: ir.Instruction, lhs_value: i128, rhs_name: []const u8, bits: u16) ?[]const u8 {
    const result_name = instruction.result orelse return null;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (binary.op != .shl or !binary.ty.eql(.{ .int = bits })) return null;
    if (binary.flags.nuw or !binary.flags.nsw or binary.flags.exact or binary.flags.disjoint) return null;
    if (!isInt(binary.lhs, lhs_value) or !isNamed(binary.rhs, rhs_name)) return null;
    return result_name;
}

pub fn validateBase64ResidualFinalMaskIcmpTyped(instruction: ir.Instruction, predicate: ir.IcmpPredicate, lhs_name: []const u8, rhs_value: i128, bits: u16) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (icmp.predicate != predicate or !icmp.operand_ty.eql(.{ .int = bits })) return null;
    if (!isNamed(icmp.lhs, lhs_name) or !isInt(icmp.rhs, rhs_value)) return null;
    return result_name;
}

pub fn lowerBase64ResidualPaddingLoopStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 13) return false;

    const start_name = (try validateBase64ResidualGuardI64GlobalLoad(block.instructions.items[0], "base64.residual_padding_loop_start")) orelse return false;
    const total_name = (try validateBase64ResidualGuardI64GlobalLoad(block.instructions.items[1], "base64.residual_padding_loop_total")) orelse return false;
    const limit_name = validateBase64ResidualAccumulatorBinary(block.instructions.items[2], .sub, total_name, start_name, 0, 64, true) orelse return false;
    const loop_index_name = (try validateBase64ResidualGuardI64GlobalLoad(block.instructions.items[3], "base64.residual_padding_loop_index")) orelse return false;
    const done_name = (try validateBase64ResidualPaddingLoopIcmpNamed(block.instructions.items[4], .eq, loop_index_name, limit_name, 64)) orelse return false;
    const ptr_name = (try validateBase64ResidualTableCheckGep(block.instructions.items[5], "base64.residual_padding_loop_source", loop_index_name)) orelse return false;
    const byte_name = (try validateBase64ResidualTableCheckI8Load(block.instructions.items[6], ptr_name)) orelse return false;
    const is_pad_name = (try validateBase64ResidualTableCheckI8EqTyped(block.instructions.items[7], byte_name, 61, 8)) orelse return false;
    const next_name = validateBase64ResidualAccumulatorBinary(block.instructions.items[8], .add, loop_index_name, null, 1, 64, false) orelse return false;
    const next_ok_name = (try validateBase64ResidualTableCheckI8EqTyped(block.instructions.items[9], next_name, 1, 64)) orelse return false;

    const body_ok_name = block.instructions.items[10].result orelse return false;
    const body_ok = switch (block.instructions.items[10].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!body_ok.cond_ty.eql(.{ .int = 1 }) or !body_ok.ty.eql(.{ .int = 1 })) return false;
    if (!isNamed(body_ok.cond, is_pad_name) or !isNamed(body_ok.true_value, next_ok_name) or !isInt(body_ok.false_value, 0)) return false;

    const ok_name = block.instructions.items[11].result orelse return false;
    const ok = switch (block.instructions.items[11].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!ok.cond_ty.eql(.{ .int = 1 }) or !ok.ty.eql(.{ .int = 1 })) return false;
    if (!isNamed(ok.cond, done_name) or !isInt(ok.true_value, 1) or !isNamed(ok.false_value, body_ok_name)) return false;

    const select_name = block.instructions.items[12].result orelse return false;
    const select = switch (block.instructions.items[12].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, ok_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn validateBase64ResidualPaddingLoopIcmpNamed(instruction: ir.Instruction, predicate: ir.IcmpPredicate, lhs_name: []const u8, rhs_name: []const u8, bits: u16) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (icmp.predicate != predicate or !icmp.operand_ty.eql(.{ .int = bits })) return null;
    if (!isNamed(icmp.lhs, lhs_name) or !isNamed(icmp.rhs, rhs_name)) return null;
    return result_name;
}

pub fn lowerBase64DecodeExitStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 2) return false;
    // Optimized modules can retain removed instructions. An unrelated main
    // with two slots is not evidence for this complete lifetime-call form.
    if (block.instructions.items[0].removed or block.instructions.items[1].removed) return false;

    const count_arg = [_]ExpectedCallArg{.{ .ty = .ptr, .value = .{ .named = "@base64.decode_exit_count" } }};
    const bits_arg = [_]ExpectedCallArg{.{ .ty = .ptr, .value = .{ .named = "@base64.decode_exit_bits" } }};
    validateVoidCall(block.instructions.items[0], "llvm.lifetime.end.p0", &count_arg) catch return false;
    validateVoidCall(block.instructions.items[1], "llvm.lifetime.end.p0", &bits_arg) catch return false;

    if (!isInt(ret.value orelse return error.InvalidRet, 0)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerBase64PaddingTailStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 4) return false;

    const src_name = block.instructions.items[0].result orelse return false;
    const byte_name = block.instructions.items[1].result orelse return false;
    const is_pad_name = block.instructions.items[2].result orelse return false;
    const select_name = block.instructions.items[3].result orelse return false;

    const gep = switch (block.instructions.items[0].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[1 x i8]" })) return false;
    const padding_symbol = switch (gep.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, padding_symbol, "base64.padding_tail")) return false;
    if (gep.indices.items.len != 1) return false;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, 0)) return false;

    const load = switch (block.instructions.items[1].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 8 }) or load.attrs.isBarrier() or !isNamed(load.ptr, src_name)) return false;

    const icmp = switch (block.instructions.items[2].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 8 }) or !isNamed(icmp.lhs, byte_name) or !isInt(icmp.rhs, 61)) return false;

    const select = switch (block.instructions.items[3].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, is_pad_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerBase64ChunkGuardStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 6) return false;

    const source_next_name = block.instructions.items[0].result orelse return false;
    if (!validateBase64ChunkGuardAdd(block.instructions.items[0], 0, 16)) return false;
    const source_ok_name = block.instructions.items[1].result orelse return false;
    if (!validateBase64ChunkGuardIcmp(block.instructions.items[1], source_next_name, 64)) return false;

    const output_next_name = block.instructions.items[2].result orelse return false;
    if (!validateBase64ChunkGuardAdd(block.instructions.items[2], 0, 15)) return false;
    const output_ok_name = block.instructions.items[3].result orelse return false;
    if (!validateBase64ChunkGuardIcmp(block.instructions.items[3], output_next_name, 63)) return false;

    const wide_ok_name = block.instructions.items[4].result orelse return false;
    const wide_select = switch (block.instructions.items[4].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!wide_select.cond_ty.eql(.{ .int = 1 }) or !wide_select.ty.eql(.{ .int = 1 })) return false;
    if (!isNamed(wide_select.cond, source_ok_name) or !isNamed(wide_select.true_value, output_ok_name) or !isInt(wide_select.false_value, 0)) return false;

    const select_name = block.instructions.items[5].result orelse return false;
    const ret_select = switch (block.instructions.items[5].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!ret_select.cond_ty.eql(.{ .int = 1 }) or !ret_select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(ret_select.cond, wide_ok_name) or !isInt(ret_select.true_value, 0) or !isInt(ret_select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerBase64SourceStrideStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 7) return false;

    const src_name = block.instructions.items[0].result orelse return false;
    const src_gep = switch (block.instructions.items[0].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!src_gep.source_ty.eql(.{ .int = 8 })) return false;
    const src_symbol = switch (src_gep.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, src_symbol, "base64.source_stride_input")) return false;
    if (src_gep.indices.items.len != 1) return false;
    if (!src_gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(src_gep.indices.items[0].value, 4)) return false;

    const byte_name = block.instructions.items[1].result orelse return false;
    const byte_load = switch (block.instructions.items[1].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!byte_load.ty.eql(.{ .int = 8 }) or byte_load.attrs.isBarrier() or !isNamed(byte_load.ptr, src_name)) return false;

    const idx_name = block.instructions.items[2].result orelse return false;
    const zext = switch (block.instructions.items[2].kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 8 }) or !zext.to_ty.eql(.{ .int = 64 }) or !isNamed(zext.value, byte_name)) return false;

    const entry_ptr_name = block.instructions.items[3].result orelse return false;
    const table_gep = switch (block.instructions.items[3].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!table_gep.source_ty.eql(.{ .aggregate = "[4 x i8]" })) return false;
    const table_symbol = switch (table_gep.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, table_symbol, "base64.source_stride_table")) return false;
    if (table_gep.indices.items.len != 1) return false;
    if (!table_gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isNamed(table_gep.indices.items[0].value, idx_name)) return false;

    const word_name = block.instructions.items[4].result orelse return false;
    const word_load = switch (block.instructions.items[4].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!word_load.ty.eql(.{ .int = 32 }) or word_load.attrs.isBarrier() or !isNamed(word_load.ptr, entry_ptr_name)) return false;

    const ok_name = block.instructions.items[5].result orelse return false;
    const ok = switch (block.instructions.items[5].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (ok.predicate != .eq or !ok.operand_ty.eql(.{ .int = 32 }) or !isNamed(ok.lhs, word_name) or !isInt(ok.rhs, 42)) return false;

    const select_name = block.instructions.items[6].result orelse return false;
    const select = switch (block.instructions.items[6].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, ok_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerBase64SourceBundleStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    return lowerBase64SourceBundleStepMainReturnWithSymbols(
        allocator,
        machine,
        function,
        block,
        ret,
        "base64.source_bundle_input",
        "base64.source_bundle_table0",
        "base64.source_bundle_table1",
        "base64.source_bundle_table2",
        "base64.source_bundle_table3",
        4,
    );
}

pub fn lowerBase64NextSourceBundleStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    return lowerBase64SourceBundleStepMainReturnWithSymbols(
        allocator,
        machine,
        function,
        block,
        ret,
        "base64.next_source_bundle_input",
        "base64.next_source_bundle_table0",
        "base64.next_source_bundle_table1",
        "base64.next_source_bundle_table2",
        "base64.next_source_bundle_table3",
        8,
    );
}

pub fn lowerBase64ThirdSourceBundleStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    return lowerBase64SourceBundleStepMainReturnWithSymbols(
        allocator,
        machine,
        function,
        block,
        ret,
        "base64.third_source_bundle_input",
        "base64.third_source_bundle_table0",
        "base64.third_source_bundle_table1",
        "base64.third_source_bundle_table2",
        "base64.third_source_bundle_table3",
        12,
    );
}

pub fn lowerBase64ResidualBundleStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    return lowerBase64SourceBundleStepMainReturnWithSymbols(
        allocator,
        machine,
        function,
        block,
        ret,
        "base64.residual_bundle_input",
        "base64.residual_bundle_table0",
        "base64.residual_bundle_table1",
        "base64.residual_bundle_table2",
        "base64.residual_bundle_table3",
        0,
    );
}

pub fn lowerBase64BitBufferStoreStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 16) return false;

    const word0_raw_name = (try validateBase64BitBufferI32GlobalLoad(block.instructions.items[0], "base64.bit_buffer_word0")) orelse return false;
    const word0_name = validateBase64BitBufferZext(block.instructions.items[1], word0_raw_name, false) orelse return false;
    const word3_raw_name = (try validateBase64BitBufferI32GlobalLoad(block.instructions.items[2], "base64.bit_buffer_word3")) orelse return false;
    const word3_name = validateBase64BitBufferZext(block.instructions.items[3], word3_raw_name, true) orelse return false;
    const word1_raw_name = (try validateBase64BitBufferI32GlobalLoad(block.instructions.items[4], "base64.bit_buffer_word1")) orelse return false;
    const word1_name = validateBase64BitBufferZext(block.instructions.items[5], word1_raw_name, true) orelse return false;
    const shift1_name = validateBase64BitBufferShl(block.instructions.items[6], word1_name, 24) orelse return false;
    const merged1_name = validateBase64BitBufferOr(block.instructions.items[7], shift1_name, word0_name) orelse return false;
    const word2_raw_name = (try validateBase64BitBufferI32GlobalLoad(block.instructions.items[8], "base64.bit_buffer_word2")) orelse return false;
    const word2_name = validateBase64BitBufferZext(block.instructions.items[9], word2_raw_name, true) orelse return false;
    const shift2_name = validateBase64BitBufferShl(block.instructions.items[10], word2_name, 48) orelse return false;
    const merged2_name = validateBase64BitBufferOr(block.instructions.items[11], merged1_name, shift2_name) orelse return false;
    const shift3_name = validateBase64BitBufferShl(block.instructions.items[12], word3_name, 72) orelse return false;
    const merged_name = validateBase64BitBufferOr(block.instructions.items[13], merged2_name, shift3_name) orelse return false;

    const dst_name = block.instructions.items[14].result orelse return false;
    const dst_gep = switch (block.instructions.items[14].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!dst_gep.source_ty.eql(.{ .aggregate = "[1 x i8]" })) return false;
    const dst_symbol = switch (dst_gep.ptr) {
        .named => |name| blk: {
            if (!std.mem.startsWith(u8, name, "@")) return false;
            break :blk try globalSymbolName(name);
        },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, dst_symbol, "base64.bit_buffer_output")) return false;
    if (dst_gep.indices.items.len != 1) return false;
    if (!dst_gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(dst_gep.indices.items[0].value, 0)) return false;

    const store = switch (block.instructions.items[15].kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 128 }) or store.attrs.isBarrier() or !isNamed(store.value, merged_name) or !isNamed(store.ptr, dst_name)) return false;

    const ret_value = ret.value orelse return error.InvalidRet;
    if (!isInt(ret_value, 0)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn validateBase64BitBufferI32GlobalLoad(instruction: ir.Instruction, symbol_name: []const u8) !?[]const u8 {
    if (instruction.removed) return null;
    const result_name = instruction.result orelse return null;
    const load = switch (instruction.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return null;
    const symbol = switch (load.ptr) {
        .named => |name| blk: {
            if (!std.mem.startsWith(u8, name, "@")) return null;
            break :blk try globalSymbolName(name);
        },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!std.mem.eql(u8, symbol, symbol_name)) return null;
    return result_name;
}

pub fn validateBase64BitBufferZext(instruction: ir.Instruction, value_name: []const u8, expected_nneg: bool) ?[]const u8 {
    if (instruction.removed) return null;
    const result_name = instruction.result orelse return null;
    const zext = switch (instruction.kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 32 }) or !zext.to_ty.eql(.{ .int = 128 }) or !isNamed(zext.value, value_name)) return null;
    if (zext.flags.nneg != expected_nneg or zext.flags.nsw or zext.flags.nuw) return null;
    return result_name;
}

pub fn validateBase64BitBufferShl(instruction: ir.Instruction, lhs_name: []const u8, shift: i128) ?[]const u8 {
    if (instruction.removed) return null;
    const result_name = instruction.result orelse return null;
    const shl = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (shl.op != .shl or !shl.ty.eql(.{ .int = 128 })) return null;
    if (!shl.flags.nsw or !shl.flags.nuw or shl.flags.exact or shl.flags.disjoint) return null;
    if (!isNamed(shl.lhs, lhs_name) or !isInt(shl.rhs, shift)) return null;
    return result_name;
}

pub fn validateBase64BitBufferOr(instruction: ir.Instruction, lhs_name: []const u8, rhs_name: []const u8) ?[]const u8 {
    if (instruction.removed) return null;
    const result_name = instruction.result orelse return null;
    const @"or" = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (@"or".op != .@"or" or !@"or".ty.eql(.{ .int = 128 })) return null;
    if (!@"or".flags.disjoint or @"or".flags.nsw or @"or".flags.nuw or @"or".flags.exact) return null;
    if (!((isNamed(@"or".lhs, lhs_name) and isNamed(@"or".rhs, rhs_name)) or
        (isNamed(@"or".lhs, rhs_name) and isNamed(@"or".rhs, lhs_name))))
    {
        return null;
    }
    return result_name;
}

pub fn lowerBase64LoopAdvanceStep(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 3) return false;

    const entry = function.blocks.items[0];
    const loop = function.blocks.items[1];
    const exit = function.blocks.items[2];
    if (!std.mem.eql(u8, entry.name, "entry") or
        !std.mem.eql(u8, loop.name, "loop") or
        !std.mem.eql(u8, exit.name, "exit"))
        return false;

    if (entry.instructions.items.len != 2) return false;
    const out_start_name = (try validateBase64LoopAdvanceI64GlobalLoad(entry.instructions.items[0], "base64.loop_advance_output")) orelse return false;
    const src_start_name = (try validateBase64LoopAdvanceI64GlobalLoad(entry.instructions.items[1], "base64.loop_advance_source")) orelse return false;
    if (!std.mem.eql(u8, try validateTerminatorBr(entry), loop.name)) return false;

    if (loop.instructions.items.len != 5) return false;
    const out_name = loop.instructions.items[0].result orelse return false;
    const src_name = loop.instructions.items[1].result orelse return false;
    const out_next_name = loop.instructions.items[2].result orelse return false;
    const src_next_name = loop.instructions.items[3].result orelse return false;
    const done_name = loop.instructions.items[4].result orelse return false;

    const out_phi = switch (loop.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!out_phi.ty.eql(.{ .int = 64 }) or out_phi.incoming.items.len != 2) return false;
    if (!isNamed(out_phi.incoming.items[0].value, out_start_name) or !std.mem.eql(u8, out_phi.incoming.items[0].block, entry.name)) return false;
    if (!isNamed(out_phi.incoming.items[1].value, out_next_name) or !std.mem.eql(u8, out_phi.incoming.items[1].block, loop.name)) return false;

    const src_phi = switch (loop.instructions.items[1].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!src_phi.ty.eql(.{ .int = 64 }) or src_phi.incoming.items.len != 2) return false;
    if (!isNamed(src_phi.incoming.items[0].value, src_start_name) or !std.mem.eql(u8, src_phi.incoming.items[0].block, entry.name)) return false;
    if (!isNamed(src_phi.incoming.items[1].value, src_next_name) or !std.mem.eql(u8, src_phi.incoming.items[1].block, loop.name)) return false;

    const out_next = switch (loop.instructions.items[2].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (out_next.op != .add or !out_next.ty.eql(.{ .int = 64 }) or !out_next.flags.nuw or out_next.flags.nsw or out_next.flags.exact or out_next.flags.disjoint) return false;
    if (!isNamed(out_next.lhs, out_name) or !isInt(out_next.rhs, 12)) return false;

    const src_next = switch (loop.instructions.items[3].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (src_next.op != .add or !src_next.ty.eql(.{ .int = 64 }) or src_next.flags.any()) return false;
    if (!isNamed(src_next.lhs, src_name) or !isInt(src_next.rhs, -16)) return false;

    const done = switch (loop.instructions.items[4].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (done.predicate != .eq or !done.operand_ty.eql(.{ .int = 64 }) or !isNamed(done.lhs, out_next_name) or !isInt(done.rhs, 12)) return false;

    const loop_branch = switch (loop.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!loop_branch.cond_ty.eql(.{ .int = 1 }) or !isNamed(loop_branch.cond, done_name)) return false;
    if (!std.mem.eql(u8, loop_branch.then_target, exit.name) or !std.mem.eql(u8, loop_branch.else_target, loop.name)) return false;

    if (exit.instructions.items.len != 2) return false;
    const src_ok_name = exit.instructions.items[0].result orelse return false;
    const select_name = exit.instructions.items[1].result orelse return false;
    const src_ok = switch (exit.instructions.items[0].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (src_ok.predicate != .eq or !src_ok.operand_ty.eql(.{ .int = 64 }) or !isNamed(src_ok.lhs, src_next_name) or !isInt(src_ok.rhs, 0)) return false;
    const select = switch (exit.instructions.items[1].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, src_ok_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;
    const ret = switch (exit.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn validateBase64LoopAdvanceI64GlobalLoad(instruction: ir.Instruction, symbol_name: []const u8) !?[]const u8 {
    if (instruction.removed) return null;
    const result_name = instruction.result orelse return null;
    const load = switch (instruction.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 64 }) or load.attrs.isBarrier()) return null;
    const symbol = switch (load.ptr) {
        .named => |name| blk: {
            if (!std.mem.startsWith(u8, name, "@")) return null;
            break :blk try globalSymbolName(name);
        },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!std.mem.eql(u8, symbol, symbol_name)) return null;
    return result_name;
}

pub fn lowerBase64ResidualGuardStep(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 3) return false;

    const entry = function.blocks.items[0];
    const decode = function.blocks.items[1];
    const done = function.blocks.items[2];
    if (!std.mem.eql(u8, entry.name, "entry") or
        !std.mem.eql(u8, decode.name, "decode") or
        !std.mem.eql(u8, done.name, "done"))
        return false;

    if (entry.instructions.items.len != 10) return false;
    const source_index_name = (try validateBase64ResidualGuardI64GlobalLoad(entry.instructions.items[0], "base64.residual_guard_source_index")) orelse return false;
    const output_index_name = (try validateBase64ResidualGuardI64GlobalLoad(entry.instructions.items[1], "base64.residual_guard_output_index")) orelse return false;
    const source_len_name = (try validateBase64ResidualGuardI64GlobalLoad(entry.instructions.items[2], "base64.residual_guard_source_len")) orelse return false;
    const output_len_name = (try validateBase64ResidualGuardI64GlobalLoad(entry.instructions.items[3], "base64.residual_guard_output_len")) orelse return false;
    const source_next_name = (try validateBase64ResidualGuardI64Add(entry.instructions.items[4], source_index_name, 4)) orelse return false;
    const source_ok_name = (try validateBase64ResidualGuardI64IcmpUlt(entry.instructions.items[5], source_next_name, source_len_name)) orelse return false;
    const output_next_name = (try validateBase64ResidualGuardI64Add(entry.instructions.items[6], output_index_name, 3)) orelse return false;
    const output_ok_name = (try validateBase64ResidualGuardI64IcmpUlt(entry.instructions.items[7], output_next_name, output_len_name)) orelse return false;
    const guard_name = (try validateBase64ResidualGuardSelect(entry.instructions.items[8], source_ok_name, output_ok_name)) orelse return false;
    const src_ptr_name = (try validateBase64ResidualGuardSourceGep(entry.instructions.items[9], source_index_name)) orelse return false;

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, guard_name)) return false;
    if (!std.mem.eql(u8, condbr.then_target, decode.name) or !std.mem.eql(u8, condbr.else_target, done.name)) return false;

    if (decode.instructions.items.len != 3) return false;
    const byte_name = (try validateBase64ResidualGuardI8Load(decode.instructions.items[0], src_ptr_name)) orelse return false;
    const byte_ok_name = (try validateBase64ResidualGuardI8Eq(decode.instructions.items[1], byte_name, 65)) orelse return false;
    const ret_ok_name = (try validateBase64ResidualGuardReturnSelect(decode.instructions.items[2], byte_ok_name)) orelse return false;
    const decode_ret = switch (decode.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!decode_ret.ty.eql(.{ .int = 32 }) or !isNamed(decode_ret.value orelse return error.InvalidRet, ret_ok_name)) return false;

    if (done.instructions.items.len != 0) return false;
    const done_ret = switch (done.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!done_ret.ty.eql(.{ .int = 32 }) or !isInt(done_ret.value orelse return error.InvalidRet, 1)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn validateBase64ResidualGuardI64GlobalLoad(instruction: ir.Instruction, symbol_name: []const u8) !?[]const u8 {
    if (instruction.removed) return null;
    const result_name = instruction.result orelse return null;
    const load = switch (instruction.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 64 }) or load.attrs.isBarrier()) return null;
    const symbol = switch (load.ptr) {
        .named => |name| blk: {
            if (!std.mem.startsWith(u8, name, "@")) return null;
            break :blk try globalSymbolName(name);
        },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!std.mem.eql(u8, symbol, symbol_name)) return null;
    return result_name;
}

pub fn validateBase64ResidualGuardI64Add(instruction: ir.Instruction, lhs_name: []const u8, rhs_value: i128) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (binary.op != .add or !binary.ty.eql(.{ .int = 64 }) or !binary.flags.nuw or binary.flags.nsw or binary.flags.exact or binary.flags.disjoint) return null;
    if (!isNamed(binary.lhs, lhs_name) or !isInt(binary.rhs, rhs_value)) return null;
    return result_name;
}

pub fn validateBase64ResidualGuardI64IcmpUlt(instruction: ir.Instruction, lhs_name: []const u8, rhs_name: []const u8) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (icmp.predicate != .ult or !icmp.operand_ty.eql(.{ .int = 64 })) return null;
    if (!isNamed(icmp.lhs, lhs_name) or !isNamed(icmp.rhs, rhs_name)) return null;
    return result_name;
}

pub fn validateBase64ResidualGuardSelect(instruction: ir.Instruction, source_ok_name: []const u8, output_ok_name: []const u8) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const select = switch (instruction.kind) {
        .select => |select| select,
        else => return null,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 1 })) return null;
    if (!isNamed(select.cond, source_ok_name) or !isNamed(select.true_value, output_ok_name) or !isInt(select.false_value, 0)) return null;
    return result_name;
}

pub fn validateBase64ResidualGuardSourceGep(instruction: ir.Instruction, source_index_name: []const u8) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const gep = switch (instruction.kind) {
        .gep => |gep| gep,
        else => return null,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[1 x i8]" })) return null;
    const symbol = switch (gep.ptr) {
        .named => |name| blk: {
            if (!std.mem.startsWith(u8, name, "@")) return null;
            break :blk try globalSymbolName(name);
        },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!std.mem.eql(u8, symbol, "base64.residual_guard_source")) return null;
    if (gep.indices.items.len != 1) return null;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isNamed(gep.indices.items[0].value, source_index_name)) return null;
    return result_name;
}

pub fn validateBase64ResidualGuardI8Load(instruction: ir.Instruction, ptr_name: []const u8) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const load = switch (instruction.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 8 }) or load.attrs.isBarrier() or !isNamed(load.ptr, ptr_name)) return null;
    return result_name;
}

pub fn validateBase64ResidualGuardI8Eq(instruction: ir.Instruction, byte_name: []const u8, value: i128) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 8 })) return null;
    if (!isNamed(icmp.lhs, byte_name) or !isInt(icmp.rhs, value)) return null;
    return result_name;
}

pub fn validateBase64ResidualGuardReturnSelect(instruction: ir.Instruction, byte_ok_name: []const u8) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const select = switch (instruction.kind) {
        .select => |select| select,
        else => return null,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return null;
    if (!isNamed(select.cond, byte_ok_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 2)) return null;
    return result_name;
}

pub fn lowerBase64SourceBundleStepMainReturnWithSymbols(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
    input_symbol: []const u8,
    table0_symbol: []const u8,
    table1_symbol: []const u8,
    table2_symbol: []const u8,
    table3_symbol: []const u8,
    first_offset: i128,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 25) return false;

    const first = (try validateBase64SourceBundleGlobalByteLoad(
        block.instructions.items[0],
        block.instructions.items[1],
        input_symbol,
        first_offset,
    )) orelse return false;
    const idx0_name = validateBase64SourceBundleZext(block.instructions.items[2], first.byte_name) orelse return false;
    const word0_name = (try validateBase64SourceBundleTableLoad(
        block.instructions.items[3],
        block.instructions.items[4],
        table0_symbol,
        idx0_name,
    )) orelse return false;

    const second = validateBase64SourceBundleRelativeByteLoad(
        block.instructions.items[5],
        block.instructions.items[6],
        first.ptr_name,
        1,
    ) orelse return false;
    const idx1_name = validateBase64SourceBundleZext(block.instructions.items[7], second.byte_name) orelse return false;
    const word1_name = (try validateBase64SourceBundleTableLoad(
        block.instructions.items[8],
        block.instructions.items[9],
        table1_symbol,
        idx1_name,
    )) orelse return false;
    const merged1_name = validateBase64SourceBundleOr(block.instructions.items[10], word1_name, word0_name) orelse return false;

    const third = validateBase64SourceBundleRelativeByteLoad(
        block.instructions.items[11],
        block.instructions.items[12],
        first.ptr_name,
        2,
    ) orelse return false;
    const idx2_name = validateBase64SourceBundleZext(block.instructions.items[13], third.byte_name) orelse return false;
    const word2_name = (try validateBase64SourceBundleTableLoad(
        block.instructions.items[14],
        block.instructions.items[15],
        table2_symbol,
        idx2_name,
    )) orelse return false;
    const merged2_name = validateBase64SourceBundleOr(block.instructions.items[16], merged1_name, word2_name) orelse return false;

    const fourth = validateBase64SourceBundleRelativeByteLoad(
        block.instructions.items[17],
        block.instructions.items[18],
        first.ptr_name,
        3,
    ) orelse return false;
    const idx3_name = validateBase64SourceBundleZext(block.instructions.items[19], fourth.byte_name) orelse return false;
    const word3_name = (try validateBase64SourceBundleTableLoad(
        block.instructions.items[20],
        block.instructions.items[21],
        table3_symbol,
        idx3_name,
    )) orelse return false;
    const word_name = validateBase64SourceBundleOr(block.instructions.items[22], merged2_name, word3_name) orelse return false;

    const valid_name = block.instructions.items[23].result orelse return false;
    const icmp = switch (block.instructions.items[23].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .ult or !icmp.operand_ty.eql(.{ .int = 32 }) or !isNamed(icmp.lhs, word_name) or !isInt(icmp.rhs, 16777216)) return false;

    const select_name = block.instructions.items[24].result orelse return false;
    const select = switch (block.instructions.items[24].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, valid_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

const Base64SourceBundleByteLoad = struct {
    ptr_name: []const u8,
    byte_name: []const u8,
};

pub fn validateBase64SourceBundleGlobalByteLoad(
    gep_inst: ir.Instruction,
    load_inst: ir.Instruction,
    symbol_name: []const u8,
    offset: i128,
) !?Base64SourceBundleByteLoad {
    if (gep_inst.removed or load_inst.removed) return null;
    const gep_name = gep_inst.result orelse return null;
    const byte_name = load_inst.result orelse return null;

    const gep = switch (gep_inst.kind) {
        .gep => |gep| gep,
        else => return null,
    };
    if (!gep.source_ty.eql(.{ .int = 8 })) return null;
    const symbol = switch (gep.ptr) {
        .named => |name| blk: {
            if (!std.mem.startsWith(u8, name, "@")) return null;
            break :blk try globalSymbolName(name);
        },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!std.mem.eql(u8, symbol, symbol_name)) return null;
    if (gep.indices.items.len != 1) return null;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, offset)) return null;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 8 }) or load.attrs.isBarrier() or !isNamed(load.ptr, gep_name)) return null;
    return .{ .ptr_name = gep_name, .byte_name = byte_name };
}

pub fn validateBase64SourceBundleRelativeByteLoad(
    gep_inst: ir.Instruction,
    load_inst: ir.Instruction,
    base_name: []const u8,
    offset: i128,
) ?Base64SourceBundleByteLoad {
    if (gep_inst.removed or load_inst.removed) return null;
    const gep_name = gep_inst.result orelse return null;
    const byte_name = load_inst.result orelse return null;

    const gep = switch (gep_inst.kind) {
        .gep => |gep| gep,
        else => return null,
    };
    if (!gep.source_ty.eql(.{ .int = 8 }) or !isNamed(gep.ptr, base_name)) return null;
    if (gep.indices.items.len != 1) return null;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, offset)) return null;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 8 }) or load.attrs.isBarrier() or !isNamed(load.ptr, gep_name)) return null;
    return .{ .ptr_name = gep_name, .byte_name = byte_name };
}

pub fn validateBase64SourceBundleZext(instruction: ir.Instruction, byte_name: []const u8) ?[]const u8 {
    if (instruction.removed) return null;
    const idx_name = instruction.result orelse return null;
    const zext = switch (instruction.kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 8 }) or !zext.to_ty.eql(.{ .int = 64 }) or !isNamed(zext.value, byte_name)) return null;
    return idx_name;
}

pub fn validateBase64SourceBundleTableLoad(
    gep_inst: ir.Instruction,
    load_inst: ir.Instruction,
    table_symbol_name: []const u8,
    idx_name: []const u8,
) !?[]const u8 {
    if (gep_inst.removed or load_inst.removed) return null;
    const gep_name = gep_inst.result orelse return null;
    const word_name = load_inst.result orelse return null;

    const gep = switch (gep_inst.kind) {
        .gep => |gep| gep,
        else => return null,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[4 x i8]" })) return null;
    const table_symbol = switch (gep.ptr) {
        .named => |name| blk: {
            if (!std.mem.startsWith(u8, name, "@")) return null;
            break :blk try globalSymbolName(name);
        },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!std.mem.eql(u8, table_symbol, table_symbol_name)) return null;
    if (gep.indices.items.len != 1) return null;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isNamed(gep.indices.items[0].value, idx_name)) return null;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier() or !isNamed(load.ptr, gep_name)) return null;
    return word_name;
}

pub fn validateBase64SourceBundleOr(instruction: ir.Instruction, lhs_name: []const u8, rhs_name: []const u8) ?[]const u8 {
    if (instruction.removed) return null;
    const result_name = instruction.result orelse return null;
    const @"or" = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (@"or".op != .@"or" or !@"or".ty.eql(.{ .int = 32 })) return null;
    if (!((isNamed(@"or".lhs, lhs_name) and isNamed(@"or".rhs, rhs_name)) or
        (isNamed(@"or".lhs, rhs_name) and isNamed(@"or".rhs, lhs_name))))
    {
        return null;
    }
    return result_name;
}

pub fn validateBase64ChunkGuardAdd(instruction: ir.Instruction, lhs_value: i128, rhs_value: i128) bool {
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    return binary.op == .add and binary.ty.eql(.{ .int = 64 }) and isInt(binary.lhs, lhs_value) and isInt(binary.rhs, rhs_value);
}

pub fn validateBase64ChunkGuardIcmp(instruction: ir.Instruction, lhs_name: []const u8, rhs_value: i128) bool {
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    return icmp.predicate == .ult and icmp.operand_ty.eql(.{ .int = 64 }) and isNamed(icmp.lhs, lhs_name) and isInt(icmp.rhs, rhs_value);
}
pub fn validateBase64DecodeStepLoad(gep_inst: ir.Instruction, load_inst: ir.Instruction, table_index: i128) !?[]const u8 {
    if (gep_inst.removed or load_inst.removed) return null;
    const gep_name = gep_inst.result orelse return null;
    const load_name = load_inst.result orelse return null;

    const gep = switch (gep_inst.kind) {
        .gep => |gep| gep,
        else => return null,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[16 x i32]" })) return null;
    const table_symbol = switch (gep.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!std.mem.eql(u8, table_symbol, "base64.decode_step_table")) return null;
    if (gep.indices.items.len != 2) return null;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, 0)) return null;
    if (!gep.indices.items[1].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[1].value, table_index)) return null;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier() or !isNamed(load.ptr, gep_name)) return null;
    return load_name;
}

pub fn validateNamedOr(instruction: ir.Instruction, lhs_name: []const u8, rhs_name: []const u8) !void {
    if (instruction.removed) return error.UnsupportedCodegenInstruction;
    const @"or" = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (@"or".op != .@"or" or !@"or".ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
    if (!((isNamed(@"or".lhs, lhs_name) and isNamed(@"or".rhs, rhs_name)) or
        (isNamed(@"or".lhs, rhs_name) and isNamed(@"or".rhs, lhs_name))))
    {
        return error.UnsupportedCodegenInstruction;
    }
}

pub fn lowerBase64WriterMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 5) return false;

    const gep_inst = block.instructions.items[0];
    const load_inst = block.instructions.items[1];
    const zext_inst = block.instructions.items[2];
    const icmp_inst = block.instructions.items[3];
    const select_inst = block.instructions.items[4];
    if (gep_inst.removed or load_inst.removed or zext_inst.removed or icmp_inst.removed or select_inst.removed) return false;

    const gep_name = gep_inst.result orelse return false;
    const load_name = load_inst.result orelse return false;
    const zext_name = zext_inst.result orelse return false;
    const icmp_name = icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    const gep = switch (gep_inst.kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[4 x i8]" })) return false;
    const table_symbol = switch (gep.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, table_symbol, "base64.writer_table")) return false;
    if (gep.indices.items.len != 2) return false;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, 0)) return false;
    if (!gep.indices.items[1].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[1].value, 3)) return false;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 8 }) or load.attrs.isBarrier() or !isNamed(load.ptr, gep_name)) return false;

    const zext = switch (zext_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 8 }) or !zext.to_ty.eql(.{ .int = 32 }) or !isNamed(zext.value, load_name)) return false;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 }) or !isNamed(icmp.lhs, zext_name) or !isInt(icmp.rhs, 12)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}
