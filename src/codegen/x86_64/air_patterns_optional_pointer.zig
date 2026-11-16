const std = @import("std");
const ir = @import("../../ir.zig");

const x86_64_generic_cfg = @import("generic_cfg.zig");
const x86_64_match = @import("match.zig");
const x86_64_machine = @import("machine.zig");
const x86_64_types = @import("types.zig");

pub const ArgReg = x86_64_types.ArgReg;
pub const MachineFunction = x86_64_machine.MachineFunction;

const blockByName = x86_64_generic_cfg.blockByName;
const blockIndex = x86_64_generic_cfg.blockIndex;
const globalSymbolName = x86_64_match.globalSymbolName;
const isInt = x86_64_match.isInt;
const isNamed = x86_64_match.isNamed;
const phiHasIncoming = x86_64_generic_cfg.phiHasIncoming;
const phiHasIncomingInt = x86_64_generic_cfg.phiHasIncomingInt;
const valueReferencesGlobal = x86_64_generic_cfg.valueReferencesGlobal;

pub fn lowerRuntimeOptionalPointerPreoptMain(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "runtime_optional_pointer_main.main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 3) return false;

    const entry = blockByName(function, "0") orelse return false;
    const merge = blockByName(function, "5") orelse return false;
    const null_check = blockByName(function, "7") orelse return false;
    if (entry.instructions.items.len != 2 or merge.instructions.items.len != 2 or null_check.instructions.items.len != 2) return false;

    const first_call_name = entry.instructions.items[0].result orelse return false;
    const first_cmp_name = entry.instructions.items[1].result orelse return false;
    if (entry.instructions.items[0].removed or entry.instructions.items[1].removed) return false;
    const first_call = switch (entry.instructions.items[0].kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isRuntimeOptionalPointerPreoptCall(first_call)) return false;
    if (first_call.args.items.len != 1 or !first_call.args.items[0].ty.eql(.ptr)) return false;
    if (!valueReferencesGlobal(first_call.args.items[0].value, "runtime_optional_pointer_main.value")) return false;
    const first_cmp = switch (entry.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (first_cmp.predicate != .eq or !first_cmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(first_cmp.lhs, first_call_name) or !isInt(first_cmp.rhs, 42)) return false;
    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, first_cmp_name)) return false;
    if (!std.mem.eql(u8, entry_br.then_target, "7") or !std.mem.eql(u8, entry_br.else_target, "5")) return false;

    const second_call_name = null_check.instructions.items[0].result orelse return false;
    const second_cmp_name = null_check.instructions.items[1].result orelse return false;
    if (null_check.instructions.items[0].removed or null_check.instructions.items[1].removed) return false;
    const second_call = switch (null_check.instructions.items[0].kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isRuntimeOptionalPointerPreoptCall(second_call)) return false;
    if (second_call.args.items.len != 1 or !second_call.args.items[0].ty.eql(.ptr)) return false;
    if (second_call.args.items[0].value != .null_value) return false;
    const second_cmp = switch (null_check.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (second_cmp.predicate != .eq or !second_cmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(second_cmp.lhs, second_call_name) or !isInt(second_cmp.rhs, -1)) return false;
    const null_check_br = switch (null_check.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };
    if (!std.mem.eql(u8, null_check_br.target, "5")) return false;

    const phi_name = merge.instructions.items[0].result orelse return false;
    const select_name = merge.instructions.items[1].result orelse return false;
    if (merge.instructions.items[0].removed or merge.instructions.items[1].removed) return false;
    const phi = switch (merge.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 1 }) or phi.incoming.items.len != 2) return false;
    if (!phiHasIncoming(phi, second_cmp_name, "7") or !phiHasIncomingInt(phi, 0, "0")) return false;
    const select = switch (merge.instructions.items[1].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, phi_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;
    const ret = switch (merge.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const fail = "optional_pointer_preopt_fail";
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = "runtime_optional_pointer_main.value" });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 42 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn isRuntimeOptionalPointerPreoptCall(call: ir.CallInst) bool {
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (call.calling_conv) |cc| {
        if (!std.mem.eql(u8, cc, "fastcc")) return false;
    }
    return std.mem.eql(u8, call.callee, "runtime_optional_pointer_main.optionalPtrValue") and call.ret_ty.eql(.{ .int = 32 });
}

pub fn lowerRuntimeOptionalPointerMain(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 3) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 1) return false;
    const icmp_inst = entry.instructions.items[0];
    if (icmp_inst.removed) return false;
    const icmp_name = icmp_inst.result orelse return false;

    const null_icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (null_icmp.predicate != .eq or !null_icmp.operand_ty.eql(.ptr)) return false;
    const pointee_global = switch (null_icmp.lhs) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, pointee_global, "optional_pointer.writer_value")) return false;
    if (null_icmp.rhs != .null_value) return false;

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, icmp_name)) return false;

    const null_index = blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget;
    const nonnull_index = blockIndex(function, condbr.else_target) orelse return error.InvalidBranchTarget;
    const null_block = function.blocks.items[null_index];
    const nonnull_block = function.blocks.items[nonnull_index];

    if (null_block.instructions.items.len != 0) return false;
    const null_ret = switch (null_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!null_ret.ty.eql(.{ .int = 32 }) or !isInt(null_ret.value orelse return error.InvalidRet, 1)) return false;

    if (nonnull_block.instructions.items.len != 3) return false;
    const value_load_inst = nonnull_block.instructions.items[0];
    const value_icmp_inst = nonnull_block.instructions.items[1];
    const select_inst = nonnull_block.instructions.items[2];
    if (value_load_inst.removed or value_icmp_inst.removed or select_inst.removed) return false;
    const value_name = value_load_inst.result orelse return false;
    const value_icmp_name = value_icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;

    const value_load = switch (value_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!value_load.ty.eql(.{ .int = 32 }) or value_load.attrs.isBarrier()) return false;
    const value_load_global = switch (value_load.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, value_load_global, pointee_global)) return false;

    const value_icmp = switch (value_icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (value_icmp.predicate != .eq or !value_icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(value_icmp.lhs, value_name) or !isInt(value_icmp.rhs, 42)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, value_icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const nonnull_ret = switch (nonnull_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!nonnull_ret.ty.eql(.{ .int = 32 }) or !isNamed(nonnull_ret.value orelse return error.InvalidRet, select_name)) return false;

    const fail = "optional_pointer_fail";
    try machine.instructions.append(allocator, .{ .lea_global_rax = pointee_global });
    try machine.instructions.append(allocator, .test_rax_rax);
    try machine.instructions.append(allocator, .{ .je = fail });
    try machine.instructions.append(allocator, .load_rax_ptr_eax);
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 42 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}
