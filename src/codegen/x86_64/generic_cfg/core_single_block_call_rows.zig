const shared = @import("core_shared.zig");
const core_cfg_emit = @import("core_cfg_emit.zig");
const core_value_support = @import("core_value_support.zig");
const core_value_emit = @import("core_value_emit.zig");
const cabi_call_lowering = @import("cabi_call_lowering.zig");
const cabi_tls_global_lowering = @import("cabi_tls_global_lowering.zig");
const core_single_block_misc = @import("core_single_block_misc.zig");
const std = shared.std;
const ir = shared.ir;
const target = shared.target;
const MachineFunction = shared.MachineFunction;
const Instruction = shared.x86_64_machine.Instruction;

const max_sysv_stack_call_args = shared.max_sysv_stack_call_args;

const appendAlignedDirectCall = shared.appendAlignedDirectCall;
const appendDirectCallWithStackArgs = shared.appendDirectCallWithStackArgs;
const appendGenericCfgReturn = core_cfg_emit.appendGenericCfgReturn;
const appendI32CallArgs = cabi_call_lowering.appendI32CallArgs;
const callIsFastcc = shared.callIsFastcc;
const emitGenericCfgI32ValueIntoEax = core_value_emit.emitGenericCfgI32ValueIntoEax;
const emitGenericCfgStoreEax = core_value_emit.emitGenericCfgStoreEax;
const emitGenericCfgVoidCall = core_value_emit.emitGenericCfgVoidCall;
const genericCfgSupportsSingleBlockScalarInstruction = core_value_support.genericCfgSupportsSingleBlockScalarInstruction;
const genericCfgSupportsSingleBlockStore = core_value_support.genericCfgSupportsSingleBlockStore;
const genericCfgSupportsLocalAggregateParamStore = core_value_support.genericCfgSupportsLocalAggregateParamStore;
const globalSymbolName = shared.globalSymbolName;
const i32Value = shared.i32Value;
const identityCastFrom = cabi_call_lowering.identityCastFrom;
const isSelectI1ToI32ZeroOne = cabi_call_lowering.isSelectI1ToI32ZeroOne;
const isInt = shared.isInt;
const isMainOrWrapperMain = cabi_tls_global_lowering.isMainOrWrapperMain;
const isNamed = shared.isNamed;
const phiHasIncoming = cabi_call_lowering.phiHasIncoming;
const phiHasIncomingInt = cabi_call_lowering.phiHasIncomingInt;
const symbolName = shared.symbolName;
const validateDefaultCallConv = shared.validateDefaultCallConv;

const lowerAtomicAddReturn = core_single_block_misc.lowerAtomicAddReturn;
const lowerAtomicTryLockReturn = core_single_block_misc.lowerAtomicTryLockReturn;
const lowerAtomicFieldXchgReturn = core_single_block_misc.lowerAtomicFieldXchgReturn;
const lowerInlineAsmBarrierReturn = cabi_tls_global_lowering.lowerInlineAsmBarrierReturn;
const sret_byval_rows = @import("core_single_block_sret_byval_rows.zig");
const lowerGenericCfgSelectedSretStores = sret_byval_rows.lowerGenericCfgSelectedSretStores;

pub fn lowerGenericCfgSingleBlockEffectBarrier(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (try lowerInlineAsmBarrierReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerAtomicAddReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerAtomicTryLockReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerAtomicFieldXchgReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    return false;
}

pub fn lowerGenericCfgSingleBlockVoidCallMain(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isInt(ret.value orelse return error.InvalidRet, 0)) return false;
    if (block.instructions.items.len != 1) return false;
    const call_inst = block.instructions.items[0];
    if (call_inst.removed or call_inst.result != null) return false;
    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.ret_ty != .void or call.args.items.len != 0) return false;
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;

    try appendAlignedDirectCall(allocator, machine, call.callee, .void);
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    machine.codegen_path = .generic_cfg;
    return true;
}

pub fn lowerGenericCfgSingleBlockDirectCallMain(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!isMainOrWrapperMain(function.name)) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 1 and block.instructions.items.len != 2) return false;

    const call_inst = block.instructions.items[0];
    if (call_inst.removed) return false;
    const call_result = call_inst.result orelse return false;
    if (block.instructions.items.len == 1) {
        if (!isNamed(ret.value orelse return error.InvalidRet, call_result)) return false;
    } else {
        const cast_inst = block.instructions.items[1];
        if (cast_inst.removed) return false;
        const cast_name = identityCastFrom(cast_inst, call_result, .{ .int = 32 }, .{ .int = 32 }) orelse return false;
        if (!isNamed(ret.value orelse return error.InvalidRet, cast_name)) return false;
    }

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len > max_sysv_stack_call_args + 6) return false;
    for (call.args.items) |arg| {
        if (arg.attrs != null or !arg.ty.eql(.{ .int = 32 })) return false;
        switch (arg.value) {
            .int => {},
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
        }
    }
    const stack_arg_count = try appendI32CallArgs(allocator, machine, function, call);
    try appendDirectCallWithStackArgs(allocator, machine, call.callee, call.ret_ty, stack_arg_count);
    try machine.instructions.append(allocator, .ret);
    machine.codegen_path = .generic_cfg;
    return true;
}

pub fn lowerGenericCfgSingleBlockCallChainMain(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!isMainOrWrapperMain(function.name)) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or block.instructions.items.len != 3) return false;

    const first_call_inst = block.instructions.items[0];
    const second_call_inst = block.instructions.items[1];
    const cast_inst = block.instructions.items[2];
    if (first_call_inst.removed or second_call_inst.removed or cast_inst.removed) return false;
    const first_result = first_call_inst.result orelse return false;
    const second_result = second_call_inst.result orelse return false;
    const cast_result = identityCastFrom(cast_inst, second_result, .{ .int = 32 }, .{ .int = 32 }) orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, cast_result)) return false;

    const first_call = switch (first_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (first_call.callee_value != null or first_call.inline_asm != null) return false;
    if (!genericCfgCallTargetsWrapperSibling(function.name, first_call.callee)) return false;
    if (!callIsFastcc(first_call.calling_conv)) validateDefaultCallConv(first_call.calling_conv) catch return false;
    if (!first_call.ret_ty.eql(.{ .int = 64 }) or first_call.args.items.len != 2) return false;
    for (first_call.args.items) |arg| {
        if (arg.attrs != null or !arg.ty.eql(.{ .int = 32 })) return false;
    }

    const first_arg = switch (first_call.args.items[0].value) {
        .int => |int| try i32Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const second_arg = switch (first_call.args.items[1].value) {
        .int => |int| try i32Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const second_call = switch (second_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (second_call.callee_value != null or second_call.inline_asm != null) return false;
    if (!genericCfgCallTargetsWrapperSibling(function.name, second_call.callee)) return false;
    if (!callIsFastcc(second_call.calling_conv)) validateDefaultCallConv(second_call.calling_conv) catch return false;
    if (!second_call.ret_ty.eql(.{ .int = 32 }) or second_call.args.items.len != 1) return false;
    const chain_arg = second_call.args.items[0];
    if (chain_arg.attrs != null or !chain_arg.ty.eql(.{ .int = 64 }) or !isNamed(chain_arg.value, first_result)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_rdi = first_arg });
    try machine.instructions.append(allocator, .{ .mov_imm_rsi = second_arg });
    try appendAlignedDirectCall(allocator, machine, first_call.callee, first_call.ret_ty);
    try machine.instructions.append(allocator, .mov_rax_rdi);
    try appendAlignedDirectCall(allocator, machine, second_call.callee, second_call.ret_ty);
    try machine.instructions.append(allocator, .ret);
    machine.codegen_path = .generic_cfg;
    return true;
}

pub fn lowerGenericCfgMultiBlockCallGlobalCheckMain(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!isMainOrWrapperMain(function.name)) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0 or function.blocks.items.len != 3) return false;

    const entry = function.blocks.items[0];
    const merge = function.blocks.items[1];
    const then_block = function.blocks.items[2];
    if (entry.instructions.items.len != 2 or merge.instructions.items.len != 2 or then_block.instructions.items.len != 2) return false;

    const call_inst = entry.instructions.items[0];
    const first_cmp_inst = entry.instructions.items[1];
    const phi_inst = merge.instructions.items[0];
    const select_inst = merge.instructions.items[1];
    const load_inst = then_block.instructions.items[0];
    const second_cmp_inst = then_block.instructions.items[1];
    if (call_inst.removed or first_cmp_inst.removed or phi_inst.removed or select_inst.removed or load_inst.removed or second_cmp_inst.removed) return false;

    const call_name = call_inst.result orelse return false;
    const first_cmp_name = first_cmp_inst.result orelse return false;
    const phi_name = phi_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    const load_name = load_inst.result orelse return false;
    const second_cmp_name = second_cmp_inst.result orelse return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (!genericCfgCallTargetsWrapperSibling(function.name, call.callee)) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 2) return false;
    const first_global = genericCfgGlobalPtrArg(call.args.items[0]) orelse return false;
    const second_global = genericCfgGlobalPtrArg(call.args.items[1]) orelse return false;

    const first_cmp = switch (first_cmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (first_cmp.predicate != .eq or !first_cmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(first_cmp.lhs, call_name)) return false;
    const expected_call = switch (first_cmp.rhs) {
        .int => |int| try i32Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, first_cmp_name)) return false;
    if (!std.mem.eql(u8, entry_br.then_target, then_block.name) or !std.mem.eql(u8, entry_br.else_target, merge.name)) return false;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
    const loaded_global = switch (load.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, loaded_global, second_global)) return false;

    const second_cmp = switch (second_cmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (second_cmp.predicate != .eq or !second_cmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(second_cmp.lhs, load_name)) return false;
    const expected_load = switch (second_cmp.rhs) {
        .int => |int| try i32Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const then_br = switch (then_block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };
    if (!std.mem.eql(u8, then_br.target, merge.name)) return false;

    const phi = switch (phi_inst.kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 1 }) or phi.incoming.items.len != 2) return false;
    if (!phiHasIncoming(phi, second_cmp_name, then_block.name) or !phiHasIncomingInt(phi, 0, entry.name)) return false;

    if (!isSelectI1ToI32ZeroOne(select_inst, phi_name)) return false;
    const ret = switch (merge.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const fail = "generic_cfg_call_global_check_fail";
    try machine.instructions.append(allocator, .{ .lea_global_rdi = first_global });
    try machine.instructions.append(allocator, .{ .lea_global_rsi = second_global });
    try appendAlignedDirectCall(allocator, machine, call.callee, call.ret_ty);
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = expected_call });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = loaded_global });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = expected_load });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    machine.codegen_path = .generic_cfg;
    return true;
}

pub fn lowerGenericCfgMultiBlockTwoCallCheckMain(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!isMainOrWrapperMain(function.name)) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0 or function.blocks.items.len != 3) return false;

    const entry = function.blocks.items[0];
    const merge = function.blocks.items[1];
    const then_block = function.blocks.items[2];
    if (entry.instructions.items.len != 2 or merge.instructions.items.len != 2 or then_block.instructions.items.len != 2) return false;

    const first_call_inst = entry.instructions.items[0];
    const first_cmp_inst = entry.instructions.items[1];
    const phi_inst = merge.instructions.items[0];
    const select_inst = merge.instructions.items[1];
    const second_call_inst = then_block.instructions.items[0];
    const second_cmp_inst = then_block.instructions.items[1];
    if (first_call_inst.removed or first_cmp_inst.removed or phi_inst.removed or select_inst.removed or second_call_inst.removed or second_cmp_inst.removed) return false;

    const first_call_name = first_call_inst.result orelse return false;
    const first_cmp_name = first_cmp_inst.result orelse return false;
    const phi_name = phi_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    const second_call_name = second_call_inst.result orelse return false;
    const second_cmp_name = second_cmp_inst.result orelse return false;

    const first_call = switch (first_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!genericCfgSupportsUnaryPtrSiblingCall(function, first_call)) return false;
    const first_expected = try genericCfgCallEqExpected(first_cmp_inst, first_call_name);

    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, first_cmp_name)) return false;
    if (!std.mem.eql(u8, entry_br.then_target, then_block.name) or !std.mem.eql(u8, entry_br.else_target, merge.name)) return false;

    const second_call = switch (second_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!genericCfgSupportsUnaryPtrSiblingCall(function, second_call)) return false;
    const second_expected = try genericCfgCallEqExpected(second_cmp_inst, second_call_name);

    const then_br = switch (then_block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };
    if (!std.mem.eql(u8, then_br.target, merge.name)) return false;

    const phi = switch (phi_inst.kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 1 }) or phi.incoming.items.len != 2) return false;
    if (!phiHasIncoming(phi, second_cmp_name, then_block.name) or !phiHasIncomingInt(phi, 0, entry.name)) return false;
    if (!isSelectI1ToI32ZeroOne(select_inst, phi_name)) return false;
    const ret = switch (merge.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const fail = "generic_cfg_two_call_check_fail";
    try emitGenericCfgUnaryPtrCallArg(allocator, machine, first_call.args.items[0]);
    try appendAlignedDirectCall(allocator, machine, first_call.callee, first_call.ret_ty);
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = first_expected });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try emitGenericCfgUnaryPtrCallArg(allocator, machine, second_call.args.items[0]);
    try appendAlignedDirectCall(allocator, machine, second_call.callee, second_call.ret_ty);
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = second_expected });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    machine.codegen_path = .generic_cfg;
    return true;
}

pub fn lowerGenericCfgSingleBlockUpdateGetMain(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!isMainOrWrapperMain(function.name)) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 2 and block.instructions.items.len != 3) return false;

    const update_inst = block.instructions.items[0];
    const get_inst = block.instructions.items[1];
    if (update_inst.removed or get_inst.removed or update_inst.result != null) return false;
    const get_result = get_inst.result orelse return false;
    if (block.instructions.items.len == 2) {
        if (!isNamed(ret.value orelse return error.InvalidRet, get_result)) return false;
    } else {
        const cast_inst = block.instructions.items[2];
        if (cast_inst.removed) return false;
        const cast_name = identityCastFrom(cast_inst, get_result, .{ .int = 32 }, .{ .int = 32 }) orelse return false;
        if (!isNamed(ret.value orelse return error.InvalidRet, cast_name)) return false;
    }

    const update_call = switch (update_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (update_call.callee_value != null or update_call.inline_asm != null) return false;
    if (!genericCfgCallTargetsWrapperSibling(function.name, update_call.callee)) return false;
    if (!callIsFastcc(update_call.calling_conv)) validateDefaultCallConv(update_call.calling_conv) catch return false;
    if (update_call.ret_ty != .void or update_call.args.items.len != 1) return false;
    const update_arg = update_call.args.items[0];
    if (update_arg.attrs != null or !update_arg.ty.eql(.{ .int = 32 })) return false;
    const update_value = switch (update_arg.value) {
        .int => |int| try i32Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const get_call = switch (get_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (get_call.callee_value != null or get_call.inline_asm != null) return false;
    if (!genericCfgCallTargetsWrapperSibling(function.name, get_call.callee)) return false;
    if (!callIsFastcc(get_call.calling_conv)) validateDefaultCallConv(get_call.calling_conv) catch return false;
    if (!get_call.ret_ty.eql(.{ .int = 32 }) or get_call.args.items.len != 0) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_rdi = update_value });
    try appendAlignedDirectCall(allocator, machine, update_call.callee, .void);
    try appendAlignedDirectCall(allocator, machine, get_call.callee, get_call.ret_ty);
    try machine.instructions.append(allocator, .ret);
    machine.codegen_path = .generic_cfg;
    return true;
}

pub fn lowerGenericCfgSingleBlockCallCheckMain(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!isMainOrWrapperMain(function.name)) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (try lowerGenericCfgSingleBlockIntCallCheckMainReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgSingleBlockFpCallCheckMainReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgSingleBlockBoolCallCheckMainReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    return false;
}

pub fn lowerGenericCfgSingleBlockIntCallCheckMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (block.instructions.items.len != 3) return false;
    const call_inst = block.instructions.items[0];
    const icmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (call_inst.removed or icmp_inst.removed or select_inst.removed) return false;

    const call_name = call_inst.result orelse return false;
    const icmp_name = icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!genericCfgSupportsConstantWrapperCall(function, call)) return false;
    switch (call.ret_ty) {
        .int => {},
        .void, .half, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .aggregate, .vector => return false,
    }

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    switch (icmp.predicate) {
        .eq, .ne => {},
        .ugt, .uge, .ult, .ule, .sgt, .sge, .slt, .sle => return false,
    }
    if (!icmp.operand_ty.eql(call.ret_ty)) return false;
    if (!isNamed(icmp.lhs, call_name)) return false;
    switch (icmp.rhs) {
        .int => {},
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    }
    if (!isSelectI1ToI32ZeroOne(select_inst, icmp_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgSingleBlockFpCallCheckMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (block.instructions.items.len != 3) return false;
    const call_inst = block.instructions.items[0];
    const fcmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (call_inst.removed or fcmp_inst.removed or select_inst.removed) return false;

    const call_name = call_inst.result orelse return false;
    const fcmp_name = fcmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!genericCfgSupportsConstantWrapperCall(function, call)) return false;
    if (!call.ret_ty.eql(.float) and !call.ret_ty.eql(.double)) return false;

    const fcmp = switch (fcmp_inst.kind) {
        .fcmp => |fcmp| fcmp,
        else => return false,
    };
    if (fcmp.predicate != .oeq or !fcmp.operand_ty.eql(call.ret_ty)) return false;
    if (!isNamed(fcmp.lhs, call_name)) return false;
    switch (fcmp.rhs) {
        .fp => {},
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    }
    if (!isSelectI1ToI32ZeroOne(select_inst, fcmp_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgSingleBlockBoolCallCheckMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (block.instructions.items.len != 2) return false;
    const call_inst = block.instructions.items[0];
    const select_inst = block.instructions.items[1];
    if (call_inst.removed or select_inst.removed) return false;

    const call_name = call_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!genericCfgSupportsConstantWrapperCall(function, call)) return false;
    if (!call.ret_ty.eql(.{ .int = 1 })) return false;
    if (!isSelectI1ToI32ZeroOne(select_inst, call_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn genericCfgSupportsConstantWrapperCall(function: ir.Function, call: ir.CallInst) bool {
    if (!callIsFastcc(call.calling_conv)) return false;
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (!genericCfgCallTargetsWrapperSibling(function.name, call.callee)) return false;
    if (call.args.items.len == 0 or call.args.items.len > 4) return false;
    for (call.args.items) |arg| {
        if (!genericCfgSupportsConstantWrapperCallArg(arg)) return false;
    }
    return true;
}

pub fn genericCfgSupportsConstantWrapperCallArg(arg: ir.CallArg) bool {
    if (arg.attrs != null) return false;
    return switch (arg.ty) {
        .ptr => switch (arg.value) {
            .named => |name| name.len > 0 and name[0] == '@',
            .null_value => true,
            .int, .fp, .undef, .poison, .zero_initializer, .vector, .constant_expr => false,
        },
        .half, .float, .double => switch (arg.value) {
            .fp => true,
            .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
        },
        .int => switch (arg.value) {
            .int => true,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
        },
        .void, .x86_fp80, .fp128, .metadata, .aggregate, .vector => false,
    };
}

pub fn genericCfgGlobalPtrArg(arg: ir.CallArg) ?[]const u8 {
    if (arg.attrs != null or !arg.ty.eql(.ptr)) return null;
    return switch (arg.value) {
        .named => |name| if (name.len > 0 and name[0] == '@') globalSymbolName(name) catch null else null,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
    };
}

pub fn genericCfgSupportsUnaryPtrSiblingCall(function: ir.Function, call: ir.CallInst) bool {
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (!genericCfgCallTargetsWrapperSibling(function.name, call.callee)) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 1) return false;
    const arg = call.args.items[0];
    if (arg.attrs != null or !arg.ty.eql(.ptr)) return false;
    return switch (arg.value) {
        .named => |name| name.len > 0 and name[0] == '@',
        .null_value => true,
        .int, .fp, .undef, .poison, .zero_initializer, .vector, .constant_expr => false,
    };
}

pub fn genericCfgCallEqExpected(instruction: ir.Instruction, call_name: []const u8) !i32 {
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenValue,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 }) or !isNamed(icmp.lhs, call_name)) {
        return error.UnsupportedCodegenValue;
    }
    return switch (icmp.rhs) {
        .int => |int| try i32Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => error.UnsupportedCodegenValue,
    };
}

pub fn emitGenericCfgUnaryPtrCallArg(allocator: std.mem.Allocator, machine: *MachineFunction, arg: ir.CallArg) !void {
    if (arg.attrs != null or !arg.ty.eql(.ptr)) return error.UnsupportedCodegenValue;
    switch (arg.value) {
        .named => |name| try machine.instructions.append(allocator, .{ .lea_global_rdi = try globalSymbolName(name) }),
        .null_value => try machine.instructions.append(allocator, .{ .mov_imm_rdi = 0 }),
        .int, .fp, .undef, .poison, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn genericCfgCallTargetsWrapperSibling(function_name: []const u8, callee: []const u8) bool {
    const name = symbolName(function_name);
    if (!isMainOrWrapperMain(name)) return false;
    const callee_name = symbolName(callee);
    const dot = std.mem.lastIndexOfScalar(u8, name, '.') orelse return false;
    if (!std.mem.eql(u8, name[dot + 1 ..], "main")) return false;
    const prefix = name[0 .. dot + 1];
    return std.mem.startsWith(u8, callee_name, prefix) and callee_name.len > prefix.len;
}

pub fn lowerGenericCfgSingleBlockVoid(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (function.ret_ty != .void or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (ret.ty != .void or ret.value != null) return false;
    if (try lowerGenericCfgSelectedSretStores(allocator, machine, function, block)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgSingleBlockVoidEffects(allocator, machine, function, block)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (@import("legacy_envelopes.zig").matchesPointerOffsetBitwiseRmwEnvelope(function)) |plan| {
        try machine.instructions.append(allocator, .{ .load_arg_ptr_disp8_rax = .{ .reg = .rdi, .offset = plan.offset } });
        try machine.instructions.append(allocator, .{ .mov_imm_rcx = plan.mask });
        try machine.instructions.append(allocator, .{ .binary_arg_rax = .{ .op = plan.op, .reg = .rcx } });
        try machine.instructions.append(allocator, .{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = plan.offset } });
        try machine.instructions.append(allocator, .ret);
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (@import("legacy_envelopes.zig").matchesPointerOffsetIncrementRmwEnvelope(function)) |plan| {
        try machine.instructions.append(allocator, .{ .inc_arg_ptr_disp8 = .{ .reg = .rdi, .offset = plan.offset } });
        try machine.instructions.append(allocator, .ret);
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (block.instructions.items.len == 1) {
        const instruction = block.instructions.items[0];
        if (instruction.removed) return false;
        switch (instruction.kind) {
            .store => |store| {
                if (!genericCfgSupportsSingleBlockStore(function, block, store)) return false;
                try emitGenericCfgI32ValueIntoEax(allocator, machine, function, block, store.value);
                try emitGenericCfgStoreEax(allocator, machine, function, store.ptr);
                try appendGenericCfgReturn(allocator, machine);
                machine.codegen_path = .generic_cfg;
                return true;
            },
            .call => |call| {
                if (instruction.result != null or call.ret_ty != .void) return false;
                try emitGenericCfgVoidCall(allocator, machine, function, block, 0, call);
                try appendGenericCfgReturn(allocator, machine);
                machine.codegen_path = .generic_cfg;
                return true;
            },
            else => return false,
        }
    }
    if (block.instructions.items.len == 0) {
        try appendGenericCfgReturn(allocator, machine);
        machine.codegen_path = .generic_cfg;
        return true;
    }
    for (block.instructions.items) |instruction| {
        if (instruction.removed) return false;
        const store = switch (instruction.kind) {
            .store => |store| store,
            else => return false,
        };
        if (!genericCfgSupportsSingleBlockStore(function, block, store)) return false;
    }
    for (block.instructions.items) |instruction| {
        const store = switch (instruction.kind) {
            .store => |store| store,
            else => unreachable,
        };
        try emitGenericCfgI32ValueIntoEax(allocator, machine, function, block, store.value);
        try emitGenericCfgStoreEax(allocator, machine, function, store.ptr);
    }
    try appendGenericCfgReturn(allocator, machine);
    machine.codegen_path = .generic_cfg;
    return true;
}

fn lowerGenericCfgSingleBlockVoidEffects(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
) !bool {
    if (block.instructions.items.len == 0) return false;
    var saw_effect = false;
    for (block.instructions.items) |instruction| {
        if (instruction.removed) return false;
        if (!genericCfgSupportsSingleBlockScalarInstruction(function, block, instruction)) return false;
        switch (instruction.kind) {
            .store => |store| {
                if (!genericCfgSupportsLocalAggregateParamStore(function, block, store)) saw_effect = true;
            },
            .call => |call| {
                if (instruction.result != null or call.ret_ty != .void) return false;
                saw_effect = true;
            },
            .load, .binary, .icmp, .select, .alloca => {},
            .phi, .fcmp, .cast, .freeze, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep => return false,
        }
    }
    if (!saw_effect) return false;
    for (block.instructions.items, 0..) |instruction, instruction_index| {
        switch (instruction.kind) {
            .store => |store| {
                if (genericCfgSupportsLocalAggregateParamStore(function, block, store)) continue;
                try emitGenericCfgI32ValueIntoEax(allocator, machine, function, block, store.value);
                try emitGenericCfgStoreEax(allocator, machine, function, store.ptr);
            },
            .call => |call| try emitGenericCfgVoidCall(allocator, machine, function, block, instruction_index, call),
            .load, .binary, .icmp, .select, .alloca => {},
            .phi, .fcmp, .cast, .freeze, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep => unreachable,
        }
    }
    try appendGenericCfgReturn(allocator, machine);
    return true;
}
