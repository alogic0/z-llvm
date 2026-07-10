const shared = @import("core_shared.zig");
const core_cfg_emit = @import("core_cfg_emit.zig");
const core_value_emit = @import("core_value_emit.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");
const cabi_call_lowering = @import("cabi_call_lowering.zig");
const terminal_values = @import("terminal_values.zig");
const pointer_slice_rows = @import("pointer_slice_rows.zig");
const error_union_loop_rows = @import("error_union_loop_rows.zig");

const std = shared.std;
const ir = shared.ir;
const MachineFunction = shared.MachineFunction;
const MachineBinaryOp = shared.MachineBinaryOp;
const ArgReg = shared.ArgReg;

const appendStackFrame = shared.appendStackFrame;
const appendStackFrameEnd = shared.appendStackFrameEnd;
const appendGenericCfgBlockLabel = core_cfg_emit.appendGenericCfgBlockLabel;
const appendGenericCfgConditionalBranch = core_cfg_emit.appendGenericCfgConditionalBranch;
const appendGenericCfgReturn = core_cfg_emit.appendGenericCfgReturn;
const appendSysVScalarCallArgsWithBlock = cabi_call_lowering.appendSysVScalarCallArgsWithBlock;
const blockIndex = cabi_abi_helpers.blockIndex;
const blockHasCondbr = terminal_values.blockHasCondbr;
const callIsFastcc = shared.callIsFastcc;
const emitRaxIntoArgReg = pointer_slice_rows.emitRaxIntoArgReg;
const i32Value = shared.i32Value;
const i64Value = shared.i64Value;
const isInt = shared.isInt;
const isNamed = shared.isNamed;
const paramReg = cabi_abi_helpers.paramReg;
const findInstruction = cabi_call_lowering.findInstruction;
const genericCfgTerminalBranchExtraBlocksAreUnreachable = terminal_values.genericCfgTerminalBranchExtraBlocksAreUnreachable;
const linearTerminalBranchUsesAllBlocks = terminal_values.linearTerminalBranchUsesAllBlocks;
const ownedMachineLabel = terminal_values.ownedMachineLabel;
const emitGenericCfgBranchSideEffects = core_value_emit.emitGenericCfgBranchSideEffects;
const singleBrTarget = terminal_values.singleBrTarget;
const validateDefaultCallConv = shared.validateDefaultCallConv;

pub const lowerGenericCfgLoopTryReturn = error_union_loop_rows.lowerGenericCfgLoopTryReturn;

pub fn supportsDirectI64Call(call: ir.CallInst) bool {
    if (!call.ret_ty.eql(.{ .int = 64 }) or call.inline_asm != null or call.callee_value != null) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;
    for (call.args.items) |arg| {
        if (!arg.ty.eql(.{ .int = 32 })) return false;
    }
    return true;
}

pub fn supportsDirectI32Call(call: ir.CallInst) bool {
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.inline_asm != null or call.callee_value != null) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;
    for (call.args.items) |arg| {
        if (!arg.ty.eql(.{ .int = 32 })) return false;
    }
    return true;
}

pub fn supportsDirectI16I32ToI32Call(call: ir.CallInst) bool {
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.inline_asm != null or call.callee_value != null) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;
    for (call.args.items) |arg| {
        if (!arg.ty.eql(.{ .int = 16 }) and !arg.ty.eql(.{ .int = 32 })) return false;
    }
    return true;
}

pub fn errorUnionTryGuardCallResult(block: ir.BasicBlock, cond: ir.Value) ?[]const u8 {
    const cond_name = switch (cond) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const icmp_inst = findInstruction(block, cond_name) orelse return null;
    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 64 })) return null;
    const masked_value = if (isInt(icmp.rhs, 0))
        icmp.lhs
    else if (isInt(icmp.lhs, 0))
        icmp.rhs
    else
        return null;
    const mask_name = switch (masked_value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const mask_inst = findInstruction(block, mask_name) orelse return null;
    const mask = switch (mask_inst.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (!mask.ty.eql(.{ .int = 64 }) or mask.op != .@"and" or !isInt(mask.rhs, 65535)) return null;
    return switch (mask.lhs) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
    };
}

pub fn blockReturnsNamedValue(block: ir.BasicBlock, name: []const u8, ty: ir.Type) bool {
    const ret = switch (block.terminator orelse return false) {
        .ret => |ret| ret,
        else => return false,
    };
    return ret.ty.eql(ty) and isNamed(ret.value orelse return false, name);
}

pub const ZeroParamBranchCondition = struct {
    reg: ArgReg,
    predicate: ir.IcmpPredicate,
};

pub fn branchConditionParamReg(function: ir.Function, block: ir.BasicBlock, cond: ir.Value) ?ZeroParamBranchCondition {
    const cond_name = switch (cond) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const instruction = findInstruction(block, cond_name) orelse return null;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (!icmp.operand_ty.eql(.{ .int = 32 }) or (icmp.predicate != .eq and icmp.predicate != .ne)) return null;
    const param_value = if (isInt(icmp.rhs, 0))
        icmp.lhs
    else if (isInt(icmp.lhs, 0))
        icmp.rhs
    else
        return null;
    const reg = switch (param_value) {
        .named => |name| paramReg(function, name, .{ .int = 32 }) catch return null,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    return .{ .reg = reg, .predicate = icmp.predicate };
}

pub fn branchKindToSkipOverride(predicate: ir.IcmpPredicate, override_is_then: bool) ?core_cfg_emit.GenericCfgBranchKind {
    return switch (predicate) {
        .ne => if (override_is_then) .je else .jne,
        .eq => if (override_is_then) .jne else .je,
        else => null,
    };
}

pub fn payloadAddArgFromCallResult(block: ir.BasicBlock, value: ir.Value, call_name: []const u8) ?u8 {
    const add_name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    return payloadAddFromCallResult(block, add_name, call_name);
}

pub fn payloadAddFromCallResult(block: ir.BasicBlock, add_name: []const u8, call_name: []const u8) ?u8 {
    const add_inst = findInstruction(block, add_name) orelse return null;
    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (!add.ty.eql(.{ .int = 32 }) or add.op != .add) return null;
    const rhs = switch (add.rhs) {
        .int => |int| i32Value(int) catch return null,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (rhs < 0 or rhs > std.math.maxInt(u8)) return null;
    const trunc_name = switch (add.lhs) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const trunc_inst = findInstruction(block, trunc_name) orelse return null;
    const trunc = switch (trunc_inst.kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (trunc.op != .trunc or !trunc.from_ty.eql(.{ .int = 64 }) or !trunc.to_ty.eql(.{ .int = 32 })) return null;
    const shift_name = switch (trunc.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const shift_inst = findInstruction(block, shift_name) orelse return null;
    const shift = switch (shift_inst.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (!shift.ty.eql(.{ .int = 64 }) or shift.op != .lshr or !isInt(shift.rhs, 16) or !isNamed(shift.lhs, call_name)) return null;
    return @intCast(rhs);
}

pub fn successReturnPayloadAdd(block: ir.BasicBlock, call_name: []const u8) ?u8 {
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 64 })) return null;
    const shl_name = switch (ret.value orelse return null) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const shl_inst = findInstruction(block, shl_name) orelse return null;
    const shl = switch (shl_inst.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (!shl.ty.eql(.{ .int = 64 }) or shl.op != .shl or !isInt(shl.rhs, 16)) return null;
    const zext_name = switch (shl.lhs) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const zext_inst = findInstruction(block, zext_name) orelse return null;
    const zext = switch (zext_inst.kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 32 }) or !zext.to_ty.eql(.{ .int = 64 })) return null;
    return payloadAddArgFromCallResult(block, zext.value, call_name);
}

pub fn emitTwoI32ArgCallIntoRax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    call: ir.CallInst,
) !void {
    if (!supportsDirectI64Call(call)) return error.UnsupportedCodegenInstruction;
    const stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, call);
    if (stack_arg_count != 0) return error.UnsupportedLiveAcrossCall;
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = call.callee, .ret_ty = call.ret_ty } });
}

pub fn lowerGenericCfgErrorUnionPayloadBranchReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.blocks.items.len < 3 or function.blocks.items.len > 4) return false;
    const entry = function.blocks.items[0];
    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 })) return false;
    const call_name = errorUnionTryGuardCallResult(entry, condbr.cond) orelse return false;
    const call_instruction = findInstruction(entry, call_name) orelse return false;
    const call = switch (call_instruction.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!supportsDirectI64Call(call)) return false;

    const then_block = function.blocks.items[blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget];
    const else_block = function.blocks.items[blockIndex(function, condbr.else_target) orelse return error.InvalidBranchTarget];
    const then_is_payload = blockReturnsErrUnionPayloadI32(then_block, call_name);
    const else_is_payload = blockReturnsErrUnionPayloadI32(else_block, call_name);
    if (then_is_payload == else_is_payload) return false;
    const payload_block = if (then_is_payload) then_block else else_block;
    const fallback_block = if (then_is_payload) else_block else then_block;
    const fallback_value = terminalConstI32Return(fallback_block) orelse return false;
    if (!genericCfgTerminalBranchExtraBlocksAreUnreachable(
        function,
        blockIndex(function, then_block.name) orelse return error.InvalidBranchTarget,
        blockIndex(function, else_block.name) orelse return error.InvalidBranchTarget,
    )) return false;

    const frame_bytes: u8 = 8;
    const epilogue_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_errunion_payload_branch_{}_generic_cfg_select_end",
        .{machine.instructions.items.len},
    );

    try appendStackFrame(allocator, machine, frame_bytes);
    const stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, entry, call);
    if (stack_arg_count != 0) return error.UnsupportedLiveAcrossCall;
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = call.callee, .ret_ty = call.ret_ty } });
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    if (then_is_payload) {
        try appendGenericCfgConditionalBranch(allocator, machine, .je, payload_block.name);
        try machine.instructions.append(allocator, .{ .mov_imm_eax = fallback_value });
        try machine.instructions.append(allocator, .{ .jmp = epilogue_label });
        try appendGenericCfgBlockLabel(allocator, machine, payload_block.name);
    } else {
        try appendGenericCfgConditionalBranch(allocator, machine, .jne, payload_block.name);
        try machine.instructions.append(allocator, .{ .mov_imm_eax = fallback_value });
        try machine.instructions.append(allocator, .{ .jmp = epilogue_label });
        try appendGenericCfgBlockLabel(allocator, machine, payload_block.name);
    }
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 16 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub fn terminalConstI32Return(block: ir.BasicBlock) ?i32 {
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return null;
    const value = switch (ret.value orelse return null) {
        .int => |int| int,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    return i32Value(value) catch null;
}

pub fn blockReturnsErrUnionPayloadI32(block: ir.BasicBlock, call_name: []const u8) bool {
    const ret = switch (block.terminator orelse return false) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    const trunc_name = switch (ret.value orelse return false) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const trunc_inst = findInstruction(block, trunc_name) orelse return false;
    const trunc = switch (trunc_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (trunc.op != .trunc or !trunc.from_ty.eql(.{ .int = 64 }) or !trunc.to_ty.eql(.{ .int = 32 })) return false;
    const shift_name = switch (trunc.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const shift_inst = findInstruction(block, shift_name) orelse return false;
    const shift = switch (shift_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    return shift.ty.eql(.{ .int = 64 }) and shift.op == .lshr and isInt(shift.rhs, 16) and isNamed(shift.lhs, call_name);
}

pub const LinearErrorUnionTryStage = struct {
    call_name: []const u8,
    call: ir.CallInst,
    err_block: ir.BasicBlock,
    cont_block: ir.BasicBlock,
};

pub const LinearErrorUnionTryChain = struct {
    entry: ir.BasicBlock,
    first: LinearErrorUnionTryStage,
    second: LinearErrorUnionTryStage,
    second_call_first_arg: ArgReg,
    first_payload_add: u8,
    success_payload_add: u8,
};

pub const LinearErrorUnionDiscardPayloadTryChain = struct {
    entry: ir.BasicBlock,
    first: LinearErrorUnionTryStage,
    second: LinearErrorUnionTryStage,
    second_call_first_arg: ArgReg,
    second_call_second_arg: ParamAddArg,
};

pub const ParamAddArg = struct {
    reg: ArgReg,
    imm: i32,
};

pub fn lowerGenericCfgLinearErrorUnionTryChainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const chain = linearErrorUnionTryChain(function) orelse return false;
    const frame_bytes: u8 = 24;
    const epilogue_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_linear_try_chain_{}_generic_cfg_select_end",
        .{machine.instructions.items.len},
    );

    try appendStackFrame(allocator, machine, frame_bytes);
    try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{ .frame_index = .slot2, .reg = chain.second_call_first_arg } });

    try emitTwoI32ArgCallIntoRax(allocator, machine, function, chain.entry, chain.first.call);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, .jne, chain.first.err_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, chain.first.cont_block.name);
    try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{ .frame_index = .slot2, .reg = .rdi } });
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 16 });
    if (chain.first_payload_add != 0) try machine.instructions.append(allocator, .{ .add_rax_imm8 = chain.first_payload_add });
    try machine.instructions.append(allocator, .mov_rax_rsi);
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = chain.second.call.callee, .ret_ty = chain.second.call.ret_ty } });
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, .jne, chain.second.err_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, chain.second.cont_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 16 });
    if (chain.success_payload_add != 0) try machine.instructions.append(allocator, .{ .add_rax_imm8 = chain.success_payload_add });
    try machine.instructions.append(allocator, .{ .shl_rax_imm6 = 16 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, chain.first.err_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, chain.second.err_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub fn lowerGenericCfgLinearErrorUnionDiscardPayloadTryChainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const chain = linearErrorUnionDiscardPayloadTryChain(function) orelse return false;
    const frame_bytes: u8 = 40;
    const epilogue_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_linear_try_discard_payload_chain_{}_generic_cfg_select_end",
        .{machine.instructions.items.len},
    );

    try appendStackFrame(allocator, machine, frame_bytes);
    try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{ .frame_index = .slot2, .reg = chain.second_call_first_arg } });
    try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{ .frame_index = .slot3, .reg = chain.second_call_second_arg.reg } });

    try emitTwoI32ArgCallIntoRax(allocator, machine, function, chain.entry, chain.first.call);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, .jne, chain.first.err_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, chain.first.cont_block.name);
    try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{ .frame_index = .slot3, .reg = .rsi } });
    try machine.instructions.append(allocator, .{ .mov_arg_eax = .rsi });
    if (chain.second_call_second_arg.imm != 0) try machine.instructions.append(allocator, .{ .add_eax_imm32 = chain.second_call_second_arg.imm });
    try machine.instructions.append(allocator, .mov_rax_rsi);
    try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{ .frame_index = .slot2, .reg = .rdi } });
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = chain.second.call.callee, .ret_ty = chain.second.call.ret_ty } });
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, .jne, chain.second.err_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, chain.second.cont_block.name);
    try machine.instructions.append(allocator, .{ .mov_imm_rax = 0 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, chain.first.err_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, chain.second.err_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub fn linearErrorUnionTryChain(function: ir.Function) ?LinearErrorUnionTryChain {
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.blocks.items.len != 5) return null;
    const entry = function.blocks.items[0];
    const entry_condbr = switch (entry.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!entry_condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const first_call_name = errorUnionTryGuardCallResult(entry, entry_condbr.cond) orelse return null;
    const first_call_instruction = findInstruction(entry, first_call_name) orelse return null;
    const first_call = switch (first_call_instruction.kind) {
        .call => |call| call,
        else => return null,
    };
    if (!supportsDirectI64Call(first_call) or first_call.args.items.len != 2) return null;

    const then_block = function.blocks.items[blockIndex(function, entry_condbr.then_target) orelse return null];
    const else_block = function.blocks.items[blockIndex(function, entry_condbr.else_target) orelse return null];
    const then_is_cont = blockHasCondbr(then_block);
    const else_is_cont = blockHasCondbr(else_block);
    if (then_is_cont == else_is_cont) return null;
    const first_cont = if (then_is_cont) then_block else else_block;
    const first_err = if (then_is_cont) else_block else then_block;
    if (!blockReturnsNamedValue(first_err, first_call_name, .{ .int = 64 })) return null;

    const cont_condbr = switch (first_cont.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!cont_condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const second_call_name = errorUnionTryGuardCallResult(first_cont, cont_condbr.cond) orelse return null;
    const second_call_instruction = findInstruction(first_cont, second_call_name) orelse return null;
    const second_call = switch (second_call_instruction.kind) {
        .call => |call| call,
        else => return null,
    };
    if (!supportsDirectI64Call(second_call) or second_call.args.items.len != 2) return null;
    const second_first_arg = switch (second_call.args.items[0].value) {
        .named => |name| paramReg(function, name, .{ .int = 32 }) catch return null,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const first_payload_add = payloadAddArgFromCallResult(first_cont, second_call.args.items[1].value, first_call_name) orelse return null;

    const second_then = function.blocks.items[blockIndex(function, cont_condbr.then_target) orelse return null];
    const second_else = function.blocks.items[blockIndex(function, cont_condbr.else_target) orelse return null];
    const second_then_is_success = successReturnPayloadAdd(second_then, second_call_name);
    const second_else_is_success = successReturnPayloadAdd(second_else, second_call_name);
    if ((second_then_is_success != null) == (second_else_is_success != null)) return null;
    const second_cont = if (second_then_is_success != null) second_then else second_else;
    const second_err = if (second_then_is_success != null) second_else else second_then;
    if (!blockReturnsNamedValue(second_err, second_call_name, .{ .int = 64 })) return null;
    if (!linearTerminalBranchUsesAllBlocks(
        function,
        blockIndex(function, first_cont.name) orelse return null,
        blockIndex(function, first_err.name) orelse return null,
        blockIndex(function, second_cont.name) orelse return null,
        blockIndex(function, second_err.name) orelse return null,
    )) return null;

    return .{
        .entry = entry,
        .first = .{ .call_name = first_call_name, .call = first_call, .err_block = first_err, .cont_block = first_cont },
        .second = .{ .call_name = second_call_name, .call = second_call, .err_block = second_err, .cont_block = second_cont },
        .second_call_first_arg = second_first_arg,
        .first_payload_add = first_payload_add,
        .success_payload_add = second_then_is_success orelse second_else_is_success.?,
    };
}

pub fn linearErrorUnionDiscardPayloadTryChain(function: ir.Function) ?LinearErrorUnionDiscardPayloadTryChain {
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.blocks.items.len != 5) return null;
    const entry = function.blocks.items[0];
    const entry_condbr = switch (entry.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!entry_condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const first_call_name = errorUnionTryGuardCallResult(entry, entry_condbr.cond) orelse return null;
    const first_call_instruction = findInstruction(entry, first_call_name) orelse return null;
    const first_call = switch (first_call_instruction.kind) {
        .call => |call| call,
        else => return null,
    };
    if (!supportsDirectI64Call(first_call) or first_call.args.items.len != 2) return null;

    const then_block = function.blocks.items[blockIndex(function, entry_condbr.then_target) orelse return null];
    const else_block = function.blocks.items[blockIndex(function, entry_condbr.else_target) orelse return null];
    const then_is_cont = blockHasCondbr(then_block);
    const else_is_cont = blockHasCondbr(else_block);
    if (then_is_cont == else_is_cont) return null;
    const first_cont = if (then_is_cont) then_block else else_block;
    const first_err = if (then_is_cont) else_block else then_block;
    if (!blockReturnsNamedValue(first_err, first_call_name, .{ .int = 64 })) return null;
    if (!blockHasDiscardedPayloadDecode(first_cont, first_call_name)) return null;

    const cont_condbr = switch (first_cont.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!cont_condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const second_call_name = errorUnionTryGuardCallResult(first_cont, cont_condbr.cond) orelse return null;
    const second_call_instruction = findInstruction(first_cont, second_call_name) orelse return null;
    const second_call = switch (second_call_instruction.kind) {
        .call => |call| call,
        else => return null,
    };
    if (!supportsDirectI64Call(second_call) or second_call.args.items.len != 2) return null;

    const second_first_arg = switch (second_call.args.items[0].value) {
        .named => |name| paramReg(function, name, .{ .int = 32 }) catch return null,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const second_second_arg = paramAddArg(function, first_cont, second_call.args.items[1].value) orelse return null;

    const second_then = function.blocks.items[blockIndex(function, cont_condbr.then_target) orelse return null];
    const second_else = function.blocks.items[blockIndex(function, cont_condbr.else_target) orelse return null];
    const second_then_is_success = blockReturnsI64Zero(second_then);
    const second_else_is_success = blockReturnsI64Zero(second_else);
    if (second_then_is_success == second_else_is_success) return null;
    const second_cont = if (second_then_is_success) second_then else second_else;
    const second_err = if (second_then_is_success) second_else else second_then;
    if (!blockReturnsNamedValue(second_err, second_call_name, .{ .int = 64 })) return null;
    if (!blockHasDiscardedPayloadDecode(second_cont, second_call_name)) return null;
    if (!linearTerminalBranchUsesAllBlocks(
        function,
        blockIndex(function, first_cont.name) orelse return null,
        blockIndex(function, first_err.name) orelse return null,
        blockIndex(function, second_cont.name) orelse return null,
        blockIndex(function, second_err.name) orelse return null,
    )) return null;

    return .{
        .entry = entry,
        .first = .{ .call_name = first_call_name, .call = first_call, .err_block = first_err, .cont_block = first_cont },
        .second = .{ .call_name = second_call_name, .call = second_call, .err_block = second_err, .cont_block = second_cont },
        .second_call_first_arg = second_first_arg,
        .second_call_second_arg = second_second_arg,
    };
}

pub fn blockReturnsI64Zero(block: ir.BasicBlock) bool {
    const ret = switch (block.terminator orelse return false) {
        .ret => |ret| ret,
        else => return false,
    };
    return ret.ty.eql(.{ .int = 64 }) and isInt(ret.value orelse return false, 0);
}

pub fn blockHasDiscardedPayloadDecode(block: ir.BasicBlock, call_name: []const u8) bool {
    for (block.instructions.items) |instruction| {
        const name = instruction.result orelse continue;
        if (payloadValueFromCallResult(block, .{ .named = name }, call_name)) return true;
    }
    return false;
}

pub fn paramAddArg(function: ir.Function, block: ir.BasicBlock, value: ir.Value) ?ParamAddArg {
    const name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const instruction = findInstruction(block, name) orelse {
        return .{ .reg = paramReg(function, name, .{ .int = 32 }) catch return null, .imm = 0 };
    };
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (!binary.ty.eql(.{ .int = 32 }) or binary.op != .add) return null;
    const imm = switch (binary.rhs) {
        .int => |int| i32Value(int) catch return null,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const reg = switch (binary.lhs) {
        .named => |lhs_name| paramReg(function, lhs_name, .{ .int = 32 }) catch return null,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    return .{ .reg = reg, .imm = imm };
}

pub const ErrorUnionTryRewrapErrorReturn = struct {
    entry: ir.BasicBlock,
    call_name: []const u8,
    call: ir.CallInst,
    cont_block: ir.BasicBlock,
    err_block: ir.BasicBlock,
    payload_add_imm: u8,
    success_is_then: bool,
};

pub const ErrorUnionTryVoidRewrapErrorReturn = struct {
    entry: ir.BasicBlock,
    call_name: []const u8,
    call: ir.CallInst,
    cont_block: ir.BasicBlock,
    err_block: ir.BasicBlock,
    success_is_then: bool,
};

pub const PayloadBinaryWrapReturn = struct {
    op: MachineBinaryOp,
    reg: ArgReg,
};

pub fn payloadValueFromCallResult(block: ir.BasicBlock, value: ir.Value, call_name: []const u8) bool {
    const trunc_name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const trunc_inst = findInstruction(block, trunc_name) orelse return false;
    const trunc = switch (trunc_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (trunc.op != .trunc or !trunc.from_ty.eql(.{ .int = 64 }) or !trunc.to_ty.eql(.{ .int = 32 })) return false;
    const shift_name = switch (trunc.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const shift_inst = findInstruction(block, shift_name) orelse return false;
    const shift = switch (shift_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    return shift.ty.eql(.{ .int = 64 }) and shift.op == .lshr and isInt(shift.rhs, 16) and isNamed(shift.lhs, call_name);
}

pub fn lowerGenericCfgErrorUnionTryRewrapErrorReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = errorUnionTryRewrapErrorReturn(function) orelse return false;
    const frame_bytes: u8 = 8;
    const epilogue_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_try_rewrap_error_{}_generic_cfg_select_end",
        .{machine.instructions.items.len},
    );

    try appendStackFrame(allocator, machine, frame_bytes);
    try emitTwoI32ArgCallIntoRax(allocator, machine, function, plan.entry, plan.call);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, if (plan.success_is_then) .je else .jne, plan.cont_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, plan.err_block.name);
    try emitGenericCfgBranchSideEffects(allocator, machine, function, plan.err_block);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, plan.cont_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 16 });
    if (plan.payload_add_imm != 0) try machine.instructions.append(allocator, .{ .add_rax_imm8 = plan.payload_add_imm });
    try machine.instructions.append(allocator, .{ .shl_rax_imm6 = 16 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub fn lowerGenericCfgErrorUnionTryVoidRewrapErrorReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = errorUnionTryVoidRewrapErrorReturn(function) orelse return false;
    const frame_bytes: u8 = 8;
    const epilogue_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_try_void_rewrap_error_{}_generic_cfg_select_end",
        .{machine.instructions.items.len},
    );

    try appendStackFrame(allocator, machine, frame_bytes);
    try emitTwoI32ArgCallIntoRax(allocator, machine, function, plan.entry, plan.call);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, if (plan.success_is_then) .je else .jne, plan.cont_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, plan.err_block.name);
    try emitGenericCfgBranchSideEffects(allocator, machine, function, plan.err_block);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, plan.cont_block.name);
    try machine.instructions.append(allocator, .{ .mov_imm_rax = 0 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub fn errorUnionTryRewrapErrorReturn(function: ir.Function) ?ErrorUnionTryRewrapErrorReturn {
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.blocks.items.len != 3) return null;
    const entry = function.blocks.items[0];
    const entry_condbr = switch (entry.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!entry_condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const call_name = errorUnionTryGuardCallResult(entry, entry_condbr.cond) orelse return null;
    const call_instruction = findInstruction(entry, call_name) orelse return null;
    const call = switch (call_instruction.kind) {
        .call => |call| call,
        else => return null,
    };
    if (!supportsDirectI64Call(call) or call.args.items.len != 2) return null;

    const then_block = function.blocks.items[blockIndex(function, entry_condbr.then_target) orelse return null];
    const else_block = function.blocks.items[blockIndex(function, entry_condbr.else_target) orelse return null];
    const then_success = successReturnPayloadAdd(then_block, call_name);
    const else_success = successReturnPayloadAdd(else_block, call_name);
    if ((then_success != null) == (else_success != null)) return null;
    const cont_block = if (then_success != null) then_block else else_block;
    const err_block = if (then_success != null) else_block else then_block;
    if (!blockReturnsRewrappedErrorBits(err_block, call_name)) return null;

    return .{
        .entry = entry,
        .call_name = call_name,
        .call = call,
        .cont_block = cont_block,
        .err_block = err_block,
        .payload_add_imm = then_success orelse else_success.?,
        .success_is_then = then_success != null,
    };
}

pub fn errorUnionTryVoidRewrapErrorReturn(function: ir.Function) ?ErrorUnionTryVoidRewrapErrorReturn {
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.blocks.items.len != 3) return null;
    const entry = function.blocks.items[0];
    const entry_condbr = switch (entry.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!entry_condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const call_name = errorUnionTryGuardCallResult(entry, entry_condbr.cond) orelse return null;
    const call_instruction = findInstruction(entry, call_name) orelse return null;
    const call = switch (call_instruction.kind) {
        .call => |call| call,
        else => return null,
    };
    if (!supportsDirectI64Call(call) or call.args.items.len != 2) return null;

    const then_block = function.blocks.items[blockIndex(function, entry_condbr.then_target) orelse return null];
    const else_block = function.blocks.items[blockIndex(function, entry_condbr.else_target) orelse return null];
    const then_success = blockReturnsI64Zero(then_block);
    const else_success = blockReturnsI64Zero(else_block);
    if (then_success == else_success) return null;
    const cont_block = if (then_success) then_block else else_block;
    const err_block = if (then_success) else_block else then_block;
    if (!blockReturnsRewrappedErrorBits(err_block, call_name)) return null;

    return .{
        .entry = entry,
        .call_name = call_name,
        .call = call,
        .cont_block = cont_block,
        .err_block = err_block,
        .success_is_then = then_success,
    };
}

pub fn blockReturnsRewrappedErrorBits(block: ir.BasicBlock, call_name: []const u8) bool {
    const ret = switch (block.terminator orelse return false) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 64 })) return false;
    const zext_name = switch (ret.value orelse return false) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const zext_inst = findInstruction(block, zext_name) orelse return false;
    const zext = switch (zext_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 16 }) or !zext.to_ty.eql(.{ .int = 64 })) return false;
    const trunc_name = switch (zext.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const trunc_inst = findInstruction(block, trunc_name) orelse return false;
    const trunc = switch (trunc_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (trunc.op != .trunc or !trunc.from_ty.eql(.{ .int = 64 }) or !trunc.to_ty.eql(.{ .int = 16 })) return false;
    const mask_name = switch (trunc.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const mask_inst = findInstruction(block, mask_name) orelse return false;
    const mask = switch (mask_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    return mask.ty.eql(.{ .int = 64 }) and mask.op == .@"and" and isNamed(mask.lhs, call_name) and isInt(mask.rhs, 65535);
}

pub const ErrorUnionTrySlotUpdateReturn = struct {
    entry: ir.BasicBlock,
    call_name: []const u8,
    call: ir.CallInst,
    cont_block: ir.BasicBlock,
    err_block: ir.BasicBlock,
    op: MachineBinaryOp,
    rhs_reg: ArgReg,
    success_is_then: bool,
};

pub fn lowerGenericCfgErrorUnionTrySlotUpdateReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = errorUnionTrySlotUpdateReturn(function) orelse return false;
    const frame_bytes: u8 = 24;
    const epilogue_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_try_slot_update_{}_generic_cfg_select_end",
        .{machine.instructions.items.len},
    );

    try appendStackFrame(allocator, machine, frame_bytes);
    try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{ .frame_index = .slot2, .reg = plan.rhs_reg } });
    try emitTwoI32ArgCallIntoRax(allocator, machine, function, plan.entry, plan.call);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, if (plan.success_is_then) .je else .jne, plan.cont_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, plan.err_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, plan.cont_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 16 });
    try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{ .frame_index = .slot2, .reg = plan.rhs_reg } });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = plan.op, .reg = plan.rhs_reg } });
    try machine.instructions.append(allocator, .{ .shl_rax_imm6 = 16 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub fn errorUnionTrySlotUpdateReturn(function: ir.Function) ?ErrorUnionTrySlotUpdateReturn {
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.blocks.items.len != 3) return null;
    const entry = function.blocks.items[0];
    const entry_condbr = switch (entry.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!entry_condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const call_name = errorUnionTryGuardCallResult(entry, entry_condbr.cond) orelse return null;
    const call_instruction = findInstruction(entry, call_name) orelse return null;
    const call = switch (call_instruction.kind) {
        .call => |call| call,
        else => return null,
    };
    if (!supportsDirectI64Call(call) or call.args.items.len != 2) return null;

    const then_block = function.blocks.items[blockIndex(function, entry_condbr.then_target) orelse return null];
    const else_block = function.blocks.items[blockIndex(function, entry_condbr.else_target) orelse return null];
    const then_update = payloadSlotUpdateWrapReturn(function, entry, then_block, call_name);
    const else_update = payloadSlotUpdateWrapReturn(function, entry, else_block, call_name);
    if ((then_update != null) == (else_update != null)) return null;
    const cont_block = if (then_update != null) then_block else else_block;
    const err_block = if (then_update != null) else_block else then_block;
    if (!blockReturnsNamedValue(err_block, call_name, .{ .int = 64 })) return null;
    const update = then_update orelse else_update.?;

    return .{
        .entry = entry,
        .call_name = call_name,
        .call = call,
        .cont_block = cont_block,
        .err_block = err_block,
        .op = update.op,
        .rhs_reg = update.reg,
        .success_is_then = then_update != null,
    };
}

pub fn payloadSlotUpdateWrapReturn(function: ir.Function, entry: ir.BasicBlock, block: ir.BasicBlock, call_name: []const u8) ?PayloadBinaryWrapReturn {
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 64 })) return null;
    const shl_name = switch (ret.value orelse return null) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const shl_inst = findInstruction(block, shl_name) orelse return null;
    const shl = switch (shl_inst.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (!shl.ty.eql(.{ .int = 64 }) or shl.op != .shl or !isInt(shl.rhs, 16)) return null;
    const zext_name = switch (shl.lhs) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const zext_inst = findInstruction(block, zext_name) orelse return null;
    const zext = switch (zext_inst.kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 32 }) or !zext.to_ty.eql(.{ .int = 64 })) return null;
    const load_name = switch (zext.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const load_index = instructionIndexByResult(block, load_name) orelse return null;
    const load = switch (block.instructions.items[load_index].kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return null;
    const slot_name = switch (load.ptr) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!entryAllocaTy(entry, slot_name, .{ .int = 32 })) return null;

    var stored_value_name: ?[]const u8 = null;
    for (block.instructions.items[0..load_index]) |instruction| {
        if (instruction.removed) continue;
        const store = switch (instruction.kind) {
            .store => |store| store,
            else => continue,
        };
        if (!store.ty.eql(.{ .int = 32 }) or store.attrs.isBarrier() or !isNamed(store.ptr, slot_name)) continue;
        stored_value_name = switch (store.value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
        };
    }
    const binary_name = stored_value_name orelse return null;
    const binary_inst = findInstruction(block, binary_name) orelse return null;
    const binary = switch (binary_inst.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (!binary.ty.eql(.{ .int = 32 }) or (binary.op != .add and binary.op != .sub)) return null;
    const payload_on_lhs = payloadValueFromCallResult(block, binary.lhs, call_name);
    const payload_on_rhs = payloadValueFromCallResult(block, binary.rhs, call_name);
    if (payload_on_lhs == payload_on_rhs) return null;
    if (binary.op == .sub and !payload_on_lhs) return null;
    const rhs_value = if (payload_on_lhs) binary.rhs else binary.lhs;
    const reg = switch (rhs_value) {
        .named => |name| paramReg(function, name, .{ .int = 32 }) catch return null,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const op: MachineBinaryOp = switch (binary.op) {
        .add => .add,
        .sub => .sub,
        else => unreachable,
    };
    return .{ .op = op, .reg = reg };
}

pub fn instructionIndexByResult(block: ir.BasicBlock, result_name: []const u8) ?usize {
    for (block.instructions.items, 0..) |instruction, index| {
        if (instruction.removed) continue;
        const result = instruction.result orelse continue;
        if (std.mem.eql(u8, result, result_name)) return index;
    }
    return null;
}

pub fn entryAllocaTy(entry: ir.BasicBlock, result_name: []const u8, ty: ir.Type) bool {
    const instruction = findInstruction(entry, result_name) orelse return false;
    const alloca = switch (instruction.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    return alloca.allocated_ty.eql(ty);
}

pub const ErrorUnionTryPayloadCallReturn = struct {
    entry: ir.BasicBlock,
    call_name: []const u8,
    call: ir.CallInst,
    cont_block: ir.BasicBlock,
    err_block: ir.BasicBlock,
    payload_call: ir.CallInst,
    payload_call_args: [2]TryPayloadCallArg,
    live_arg_reg: ArgReg,
    success_is_then: bool,
};

pub const TryPayloadCallArg = union(enum) {
    payload,
    param: ArgReg,
};

pub fn lowerGenericCfgErrorUnionTryPayloadCallReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = errorUnionTryPayloadCallReturn(function) orelse return false;
    const frame_bytes: u8 = 24;
    const epilogue_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_try_payload_call_{}_generic_cfg_select_end",
        .{machine.instructions.items.len},
    );

    try appendStackFrame(allocator, machine, frame_bytes);
    try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{ .frame_index = .slot2, .reg = plan.live_arg_reg } });
    try emitTwoI32ArgCallIntoRax(allocator, machine, function, plan.entry, plan.call);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, if (plan.success_is_then) .je else .jne, plan.cont_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, plan.err_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, plan.cont_block.name);
    try emitTryPayloadCallArg(allocator, machine, .rdi, plan.payload_call_args[0]);
    try emitTryPayloadCallArg(allocator, machine, .rsi, plan.payload_call_args[1]);
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = plan.payload_call.callee, .ret_ty = plan.payload_call.ret_ty } });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = -1 });
    try machine.instructions.append(allocator, .{ .shl_rax_imm6 = 16 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub fn emitTryPayloadCallArg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    dst: ArgReg,
    arg: TryPayloadCallArg,
) !void {
    switch (arg) {
        .payload => {
            try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
            try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 16 });
            try emitRaxIntoArgReg(allocator, machine, dst);
        },
        .param => try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{ .frame_index = .slot2, .reg = dst } }),
    }
}

pub fn errorUnionTryPayloadCallReturn(function: ir.Function) ?ErrorUnionTryPayloadCallReturn {
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.blocks.items.len != 3) return null;
    const entry = function.blocks.items[0];
    const entry_condbr = switch (entry.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!entry_condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const call_name = errorUnionTryGuardCallResult(entry, entry_condbr.cond) orelse return null;
    const call_instruction = findInstruction(entry, call_name) orelse return null;
    const call = switch (call_instruction.kind) {
        .call => |call| call,
        else => return null,
    };
    if (!supportsDirectI64Call(call) or call.args.items.len != 2) return null;

    const then_block = function.blocks.items[blockIndex(function, entry_condbr.then_target) orelse return null];
    const else_block = function.blocks.items[blockIndex(function, entry_condbr.else_target) orelse return null];
    const then_payload_call = payloadCallWrapReturn(function, then_block, call_name);
    const else_payload_call = payloadCallWrapReturn(function, else_block, call_name);
    if ((then_payload_call != null) == (else_payload_call != null)) return null;
    const cont_block = if (then_payload_call != null) then_block else else_block;
    const err_block = if (then_payload_call != null) else_block else then_block;
    if (!blockReturnsNamedValue(err_block, call_name, .{ .int = 64 })) return null;
    const payload_call = then_payload_call orelse else_payload_call.?;

    return .{
        .entry = entry,
        .call_name = call_name,
        .call = call,
        .cont_block = cont_block,
        .err_block = err_block,
        .payload_call = payload_call.call,
        .payload_call_args = payload_call.args,
        .live_arg_reg = payload_call.live_arg_reg,
        .success_is_then = then_payload_call != null,
    };
}

pub const PayloadCallWrapReturn = struct {
    call: ir.CallInst,
    args: [2]TryPayloadCallArg,
    live_arg_reg: ArgReg,
};

pub fn payloadCallWrapReturn(function: ir.Function, block: ir.BasicBlock, call_name: []const u8) ?PayloadCallWrapReturn {
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 64 })) return null;
    const shl_name = switch (ret.value orelse return null) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const shl_inst = findInstruction(block, shl_name) orelse return null;
    const shl = switch (shl_inst.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (!shl.ty.eql(.{ .int = 64 }) or shl.op != .shl or !isInt(shl.rhs, 16)) return null;
    const zext_name = switch (shl.lhs) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const zext_inst = findInstruction(block, zext_name) orelse return null;
    const zext = switch (zext_inst.kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 32 }) or !zext.to_ty.eql(.{ .int = 64 })) return null;
    const payload_call_name = switch (zext.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const payload_call_inst = findInstruction(block, payload_call_name) orelse return null;
    const payload_call = switch (payload_call_inst.kind) {
        .call => |call| call,
        else => return null,
    };
    if (!supportsDirectI32Call(payload_call) or payload_call.args.items.len != 2) return null;

    var args: [2]TryPayloadCallArg = undefined;
    var payload_arg_count: usize = 0;
    var live_arg_reg: ?ArgReg = null;
    for (payload_call.args.items, 0..) |arg, index| {
        if (!arg.ty.eql(.{ .int = 32 })) return null;
        if (payloadValueFromCallResult(block, arg.value, call_name)) {
            args[index] = .payload;
            payload_arg_count += 1;
            continue;
        }
        const reg = switch (arg.value) {
            .named => |name| paramReg(function, name, .{ .int = 32 }) catch return null,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
        };
        if (live_arg_reg != null and live_arg_reg.? != reg) return null;
        live_arg_reg = reg;
        args[index] = .{ .param = reg };
    }
    if (payload_arg_count != 1) return null;
    return .{ .call = payload_call, .args = args, .live_arg_reg = live_arg_reg orelse return null };
}

pub const ErrorUnionTryPhiSlotOverrideReturn = struct {
    entry: ir.BasicBlock,
    call_name: []const u8,
    call: ir.CallInst,
    phi_name: []const u8,
    override_error: i64,
    condition_reg: ArgReg,
    branch_to_after_override: core_cfg_emit.GenericCfgBranchKind,
    cont_block: ir.BasicBlock,
    err_block: ir.BasicBlock,
    payload_add_imm: u8,
    success_is_then: bool,
};

pub fn lowerGenericCfgErrorUnionTryPhiSlotOverrideReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = errorUnionTryPhiSlotOverrideReturn(function) orelse return false;
    const frame_bytes: u8 = 24;
    const after_override_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_try_phi_override_{}_after_override",
        .{machine.instructions.items.len},
    );
    const epilogue_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_try_phi_override_{}_generic_cfg_select_end",
        .{machine.instructions.items.len},
    );

    try appendStackFrame(allocator, machine, frame_bytes);
    try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{ .frame_index = .slot2, .reg = plan.condition_reg } });
    try emitTwoI32ArgCallIntoRax(allocator, machine, function, plan.entry, plan.call);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });

    try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{ .frame_index = .slot2, .reg = .rcx } });
    try machine.instructions.append(allocator, .{ .test_arg32 = .rcx });
    try appendGenericCfgConditionalBranch(allocator, machine, plan.branch_to_after_override, after_override_label);
    try machine.instructions.append(allocator, .{ .mov_imm_rax = plan.override_error });
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    try appendGenericCfgBlockLabel(allocator, machine, after_override_label);

    try appendGenericCfgBlockLabel(allocator, machine, "generic_cfg_try_phi_override_guard");
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, if (plan.success_is_then) .je else .jne, plan.cont_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, plan.err_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, plan.cont_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 16 });
    if (plan.payload_add_imm != 0) try machine.instructions.append(allocator, .{ .add_rax_imm8 = plan.payload_add_imm });
    try machine.instructions.append(allocator, .{ .shl_rax_imm6 = 16 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub fn errorUnionTryPhiSlotOverrideReturn(function: ir.Function) ?ErrorUnionTryPhiSlotOverrideReturn {
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.blocks.items.len != 6) return null;
    const entry = function.blocks.items[0];
    const entry_condbr = switch (entry.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!entry_condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const condition = branchConditionParamReg(function, entry, entry_condbr.cond) orelse return null;

    const then_block = function.blocks.items[blockIndex(function, entry_condbr.then_target) orelse return null];
    const else_block = function.blocks.items[blockIndex(function, entry_condbr.else_target) orelse return null];
    if (then_block.instructions.items.len != 0 or else_block.instructions.items.len != 0) return null;
    const merge_name = singleBrTarget(then_block) orelse return null;
    if (!std.mem.eql(u8, singleBrTarget(else_block) orelse return null, merge_name)) return null;
    const merge_block = function.blocks.items[blockIndex(function, merge_name) orelse return null];
    const merge_condbr = switch (merge_block.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!merge_condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const phi_name = errorUnionTryGuardCallResult(merge_block, merge_condbr.cond) orelse return null;
    const phi_instruction = findInstruction(merge_block, phi_name) orelse return null;
    const phi = switch (phi_instruction.kind) {
        .phi => |phi| phi,
        else => return null,
    };
    if (!phi.ty.eql(.{ .int = 64 }) or phi.incoming.items.len != 2) return null;

    var call_name: ?[]const u8 = null;
    var override_error: ?i64 = null;
    var override_block: ?[]const u8 = null;
    for (phi.incoming.items) |incoming| {
        if (!std.mem.eql(u8, incoming.block, then_block.name) and !std.mem.eql(u8, incoming.block, else_block.name)) return null;
        switch (incoming.value) {
            .named => |name| {
                if (call_name != null) return null;
                call_name = name;
            },
            .int => |int| {
                if (override_error != null) return null;
                const value = i64Value(int) catch return null;
                if (value <= 0 or value > 65535) return null;
                override_error = value;
                override_block = incoming.block;
            },
            .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
        }
    }
    const call_result_name = call_name orelse return null;
    const call_instruction = findInstruction(entry, call_result_name) orelse return null;
    const call = switch (call_instruction.kind) {
        .call => |call| call,
        else => return null,
    };
    if (!supportsDirectI64Call(call) or call.args.items.len != 2) return null;

    const then_success = successReturnPayloadAdd(function.blocks.items[blockIndex(function, merge_condbr.then_target) orelse return null], phi_name);
    const else_success = successReturnPayloadAdd(function.blocks.items[blockIndex(function, merge_condbr.else_target) orelse return null], phi_name);
    if ((then_success != null) == (else_success != null)) return null;
    const cont_block = if (then_success != null)
        function.blocks.items[blockIndex(function, merge_condbr.then_target) orelse return null]
    else
        function.blocks.items[blockIndex(function, merge_condbr.else_target) orelse return null];
    const err_block = if (then_success != null)
        function.blocks.items[blockIndex(function, merge_condbr.else_target) orelse return null]
    else
        function.blocks.items[blockIndex(function, merge_condbr.then_target) orelse return null];
    if (!blockReturnsNamedValue(err_block, phi_name, .{ .int = 64 })) return null;

    const override_is_then = std.mem.eql(u8, override_block orelse return null, then_block.name);
    return .{
        .entry = entry,
        .call_name = call_result_name,
        .call = call,
        .phi_name = phi_name,
        .override_error = override_error orelse return null,
        .condition_reg = condition.reg,
        .branch_to_after_override = branchKindToSkipOverride(condition.predicate, override_is_then) orelse return null,
        .cont_block = cont_block,
        .err_block = err_block,
        .payload_add_imm = then_success orelse else_success.?,
        .success_is_then = then_success != null,
    };
}
