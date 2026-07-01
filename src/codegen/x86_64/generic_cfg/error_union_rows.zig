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
const appendAlignedCallPreservingI32Params = cabi_call_lowering.appendAlignedCallPreservingI32Params;
const appendSysVScalarCallArgsWithBlock = cabi_call_lowering.appendSysVScalarCallArgsWithBlock;
const blockIndex = cabi_abi_helpers.blockIndex;
const blockHasCondbr = terminal_values.blockHasCondbr;
const blockIsUnreachable = terminal_values.blockIsUnreachable;
const blockSwitchTerminator = terminal_values.blockSwitchTerminator;
const commonSwitchMergeBlock = terminal_values.commonSwitchMergeBlock;
const callIsFastcc = shared.callIsFastcc;
const emitRaxIntoArgReg = pointer_slice_rows.emitRaxIntoArgReg;
const firstPhiReturn = terminal_values.firstPhiReturn;
const i32Value = shared.i32Value;
const i64Value = shared.i64Value;
const isInt = shared.isInt;
const isNamed = shared.isNamed;
const LiveParamSet = cabi_call_lowering.LiveParamSet;
const machineBinaryOp = cabi_call_lowering.machineBinaryOp;
const noteLiveValueSet = cabi_call_lowering.noteLiveValueSet;
const paramReg = cabi_abi_helpers.paramReg;
const phiHasIncoming = cabi_call_lowering.phiHasIncoming;
const phiHasIncomingInt = cabi_call_lowering.phiHasIncomingInt;
const findInstruction = cabi_call_lowering.findInstruction;
const genericCfgTerminalBranchExtraBlocksAreUnreachable = terminal_values.genericCfgTerminalBranchExtraBlocksAreUnreachable;
const blockBranchesTo = terminal_values.blockBranchesTo;
const linearTerminalBranchUsesAllBlocks = terminal_values.linearTerminalBranchUsesAllBlocks;
const ownedMachineLabel = terminal_values.ownedMachineLabel;
const emitGenericCfgTerminalConditionTrueBranch = terminal_values.emitGenericCfgTerminalConditionTrueBranch;
const emitGenericCfgTerminalI32ValueIntoEax = terminal_values.emitGenericCfgTerminalI32ValueIntoEax;
const emitGenericCfgTerminalI64ValueIntoRax = terminal_values.emitGenericCfgTerminalI64ValueIntoRax;
const emitGenericCfgTerminalReturnBlock = terminal_values.emitGenericCfgTerminalReturnBlock;
const emitGenericCfgBranchSideEffects = core_value_emit.emitGenericCfgBranchSideEffects;
const genericCfgSupportsTerminalReturnBlock = terminal_values.genericCfgSupportsTerminalReturnBlock;
const phiIncomingForBlock = terminal_values.phiIncomingForBlock;
const singleBrTarget = terminal_values.singleBrTarget;
const validateDefaultCallConv = shared.validateDefaultCallConv;
const paramRegOrNull = cabi_abi_helpers.paramRegOrNull;

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

fn supportsDirectI16I32ToI32Call(call: ir.CallInst) bool {
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

const ZeroParamBranchCondition = struct {
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

fn blockReturnsErrUnionPayloadI32(block: ir.BasicBlock, call_name: []const u8) bool {
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

const LinearErrorUnionTryStage = struct {
    call_name: []const u8,
    call: ir.CallInst,
    err_block: ir.BasicBlock,
    cont_block: ir.BasicBlock,
};

const LinearErrorUnionTryChain = struct {
    entry: ir.BasicBlock,
    first: LinearErrorUnionTryStage,
    second: LinearErrorUnionTryStage,
    second_call_first_arg: ArgReg,
    first_payload_add: u8,
    success_payload_add: u8,
};

const LinearErrorUnionDiscardPayloadTryChain = struct {
    entry: ir.BasicBlock,
    first: LinearErrorUnionTryStage,
    second: LinearErrorUnionTryStage,
    second_call_first_arg: ArgReg,
    second_call_second_arg: ParamAddArg,
};

const ParamAddArg = struct {
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

fn linearErrorUnionTryChain(function: ir.Function) ?LinearErrorUnionTryChain {
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

fn linearErrorUnionDiscardPayloadTryChain(function: ir.Function) ?LinearErrorUnionDiscardPayloadTryChain {
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

fn blockReturnsI64Zero(block: ir.BasicBlock) bool {
    const ret = switch (block.terminator orelse return false) {
        .ret => |ret| ret,
        else => return false,
    };
    return ret.ty.eql(.{ .int = 64 }) and isInt(ret.value orelse return false, 0);
}

fn blockHasDiscardedPayloadDecode(block: ir.BasicBlock, call_name: []const u8) bool {
    for (block.instructions.items) |instruction| {
        const name = instruction.result orelse continue;
        if (payloadValueFromCallResult(block, .{ .named = name }, call_name)) return true;
    }
    return false;
}

fn paramAddArg(function: ir.Function, block: ir.BasicBlock, value: ir.Value) ?ParamAddArg {
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

const ErrorUnionTryRewrapErrorReturn = struct {
    entry: ir.BasicBlock,
    call_name: []const u8,
    call: ir.CallInst,
    cont_block: ir.BasicBlock,
    err_block: ir.BasicBlock,
    payload_add_imm: u8,
    success_is_then: bool,
};

const ErrorUnionTryVoidRewrapErrorReturn = struct {
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

fn errorUnionTryRewrapErrorReturn(function: ir.Function) ?ErrorUnionTryRewrapErrorReturn {
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

fn errorUnionTryVoidRewrapErrorReturn(function: ir.Function) ?ErrorUnionTryVoidRewrapErrorReturn {
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

fn blockReturnsRewrappedErrorBits(block: ir.BasicBlock, call_name: []const u8) bool {
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

const ErrorUnionTrySlotUpdateReturn = struct {
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

fn errorUnionTrySlotUpdateReturn(function: ir.Function) ?ErrorUnionTrySlotUpdateReturn {
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

fn payloadSlotUpdateWrapReturn(function: ir.Function, entry: ir.BasicBlock, block: ir.BasicBlock, call_name: []const u8) ?PayloadBinaryWrapReturn {
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

fn instructionIndexByResult(block: ir.BasicBlock, result_name: []const u8) ?usize {
    for (block.instructions.items, 0..) |instruction, index| {
        if (instruction.removed) continue;
        const result = instruction.result orelse continue;
        if (std.mem.eql(u8, result, result_name)) return index;
    }
    return null;
}

fn entryAllocaTy(entry: ir.BasicBlock, result_name: []const u8, ty: ir.Type) bool {
    const instruction = findInstruction(entry, result_name) orelse return false;
    const alloca = switch (instruction.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    return alloca.allocated_ty.eql(ty);
}

const ErrorUnionTryPayloadCallReturn = struct {
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

const TryPayloadCallArg = union(enum) {
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

fn emitTryPayloadCallArg(
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

fn errorUnionTryPayloadCallReturn(function: ir.Function) ?ErrorUnionTryPayloadCallReturn {
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

const PayloadCallWrapReturn = struct {
    call: ir.CallInst,
    args: [2]TryPayloadCallArg,
    live_arg_reg: ArgReg,
};

fn payloadCallWrapReturn(function: ir.Function, block: ir.BasicBlock, call_name: []const u8) ?PayloadCallWrapReturn {
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

const ErrorUnionTryPhiSlotOverrideReturn = struct {
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

fn errorUnionTryPhiSlotOverrideReturn(function: ir.Function) ?ErrorUnionTryPhiSlotOverrideReturn {
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

const ErrorUnionTryPayloadBranchReturn = struct {
    entry: ir.BasicBlock,
    call_name: []const u8,
    call: ir.CallInst,
    err_block: ir.BasicBlock,
    cont_block: ir.BasicBlock,
    true_block: ir.BasicBlock,
    false_block: ir.BasicBlock,
    compare: PayloadGreaterConst,
    delta_reg: ArgReg,
    true_op: MachineBinaryOp,
    false_op: MachineBinaryOp,
};

const PayloadGreaterConstPredicate = enum {
    signed_gt,
    unsigned_gt,
};

const PayloadGreaterConst = union(PayloadGreaterConstPredicate) {
    signed_gt: i32,
    unsigned_gt: i32,
};

pub fn lowerGenericCfgErrorUnionTryPayloadBranchReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = errorUnionTryPayloadBranchReturn(function) orelse return false;
    const frame_bytes: u8 = 24;
    const epilogue_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_try_payload_branch_{}_generic_cfg_select_end",
        .{machine.instructions.items.len},
    );

    try appendStackFrame(allocator, machine, frame_bytes);
    try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{ .frame_index = .slot2, .reg = plan.delta_reg } });

    try emitTwoI32ArgCallIntoRax(allocator, machine, function, plan.entry, plan.call);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, .jne, plan.err_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, plan.cont_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 16 });
    switch (plan.compare) {
        .signed_gt => |imm| {
            try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = imm });
            try machine.instructions.append(allocator, .{ .jle = plan.false_block.name });

            try appendGenericCfgBlockLabel(allocator, machine, plan.true_block.name);
            try emitPayloadBinaryWrapReturn(allocator, machine, plan.true_op, plan.delta_reg, epilogue_label);

            try appendGenericCfgBlockLabel(allocator, machine, plan.false_block.name);
            try emitPayloadBinaryWrapReturn(allocator, machine, plan.false_op, plan.delta_reg, epilogue_label);
        },
        .unsigned_gt => |imm| {
            if (imm == std.math.maxInt(i32)) return error.UnsupportedCodegenControlFlow;
            try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = imm + 1 });
            try machine.instructions.append(allocator, .{ .jae = plan.true_block.name });

            try appendGenericCfgBlockLabel(allocator, machine, plan.false_block.name);
            try emitPayloadBinaryWrapReturn(allocator, machine, plan.false_op, plan.delta_reg, epilogue_label);

            try appendGenericCfgBlockLabel(allocator, machine, plan.true_block.name);
            try emitPayloadBinaryWrapReturn(allocator, machine, plan.true_op, plan.delta_reg, epilogue_label);
        },
    }

    try appendGenericCfgBlockLabel(allocator, machine, plan.err_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

fn emitPayloadBinaryWrapReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    op: MachineBinaryOp,
    delta_reg: ArgReg,
    epilogue_label: []const u8,
) !void {
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 16 });
    try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{ .frame_index = .slot2, .reg = delta_reg } });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = op, .reg = delta_reg } });
    try machine.instructions.append(allocator, .{ .shl_rax_imm6 = 16 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });
}

fn errorUnionTryPayloadBranchReturn(function: ir.Function) ?ErrorUnionTryPayloadBranchReturn {
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.blocks.items.len != 5) return null;
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
    const then_is_cont = blockHasCondbr(then_block);
    const else_is_cont = blockHasCondbr(else_block);
    if (then_is_cont == else_is_cont) return null;
    const cont_block = if (then_is_cont) then_block else else_block;
    const err_block = if (then_is_cont) else_block else then_block;
    if (!blockReturnsNamedValue(err_block, call_name, .{ .int = 64 })) return null;

    const cont_condbr = switch (cont_block.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!cont_condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const compare = payloadGreaterConst(cont_block, cont_condbr.cond, call_name) orelse return null;
    const true_block = function.blocks.items[blockIndex(function, cont_condbr.then_target) orelse return null];
    const false_block = function.blocks.items[blockIndex(function, cont_condbr.else_target) orelse return null];
    const true_return = payloadBinaryWrapReturn(function, cont_block, true_block, call_name) orelse return null;
    const false_return = payloadBinaryWrapReturn(function, cont_block, false_block, call_name) orelse return null;
    if (true_return.reg != false_return.reg) return null;
    if (!linearTerminalBranchUsesAllBlocks(
        function,
        blockIndex(function, cont_block.name) orelse return null,
        blockIndex(function, err_block.name) orelse return null,
        blockIndex(function, true_block.name) orelse return null,
        blockIndex(function, false_block.name) orelse return null,
    )) return null;

    return .{
        .entry = entry,
        .call_name = call_name,
        .call = call,
        .err_block = err_block,
        .cont_block = cont_block,
        .true_block = true_block,
        .false_block = false_block,
        .compare = compare,
        .delta_reg = true_return.reg,
        .true_op = true_return.op,
        .false_op = false_return.op,
    };
}

fn payloadGreaterConst(block: ir.BasicBlock, cond: ir.Value, call_name: []const u8) ?PayloadGreaterConst {
    const cond_name = switch (cond) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const cond_inst = findInstruction(block, cond_name) orelse return null;
    const icmp = switch (cond_inst.kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (!icmp.operand_ty.eql(.{ .int = 32 })) return null;
    const predicate: PayloadGreaterConstPredicate = switch (icmp.predicate) {
        .sgt => .signed_gt,
        .ugt => .unsigned_gt,
        else => return null,
    };
    const rhs = switch (icmp.rhs) {
        .int => |int| i32Value(int) catch return null,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!payloadValueFromCallResult(block, icmp.lhs, call_name)) return null;
    return switch (predicate) {
        .signed_gt => .{ .signed_gt = rhs },
        .unsigned_gt => .{ .unsigned_gt = rhs },
    };
}

fn payloadBinaryWrapReturn(function: ir.Function, payload_scope: ir.BasicBlock, block: ir.BasicBlock, call_name: []const u8) ?PayloadBinaryWrapReturn {
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
    const binary_name = switch (zext.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const binary_inst = findInstruction(block, binary_name) orelse return null;
    const binary = switch (binary_inst.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (!binary.ty.eql(.{ .int = 32 }) or (binary.op != .add and binary.op != .sub)) return null;
    if (!payloadValueFromCallResult(payload_scope, binary.lhs, call_name)) return null;
    const reg = switch (binary.rhs) {
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

const ErrorUnionTrySwitchCase = struct {
    value: i32,
    block: ir.BasicBlock,
    add_imm: u8,
};

const ErrorUnionTrySwitchReturn = struct {
    entry: ir.BasicBlock,
    call_name: []const u8,
    call: ir.CallInst,
    err_block: ir.BasicBlock,
    switch_block: ir.BasicBlock,
    merge_block: ir.BasicBlock,
    mask: i32,
    cases: [8]ErrorUnionTrySwitchCase,
    case_count: usize,
    default_case: ErrorUnionTrySwitchCase,
};

pub fn lowerGenericCfgErrorUnionTrySwitchReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = errorUnionTrySwitchReturn(function) orelse return false;
    const frame_bytes: u8 = 24;
    const epilogue_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_try_switch_{}_generic_cfg_select_end",
        .{machine.instructions.items.len},
    );

    try appendStackFrame(allocator, machine, frame_bytes);
    try emitTwoI32ArgCallIntoRax(allocator, machine, function, plan.entry, plan.call);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, .jne, plan.err_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, plan.switch_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 16 });
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot2 });
    if (plan.mask != 0) try machine.instructions.append(allocator, .{ .and_eax_imm32 = plan.mask });
    for (plan.cases[0..plan.case_count]) |case| {
        try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = case.value });
        try appendGenericCfgConditionalBranch(allocator, machine, .je, case.block.name);
    }
    try machine.instructions.append(allocator, .{ .jmp = plan.default_case.block.name });

    for (plan.cases[0..plan.case_count]) |case| {
        try appendGenericCfgBlockLabel(allocator, machine, case.block.name);
        try emitPayloadAddImmWrapFromSlot(allocator, machine, case.add_imm, epilogue_label);
    }
    try appendGenericCfgBlockLabel(allocator, machine, plan.default_case.block.name);
    try emitPayloadAddImmWrapFromSlot(allocator, machine, plan.default_case.add_imm, epilogue_label);

    try appendGenericCfgBlockLabel(allocator, machine, plan.err_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

fn emitPayloadAddImmWrapFromSlot(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    add_imm: u8,
    epilogue_label: []const u8,
) !void {
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot2 });
    if (add_imm != 0) try machine.instructions.append(allocator, .{ .add_rax_imm8 = add_imm });
    try machine.instructions.append(allocator, .{ .shl_rax_imm6 = 16 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });
}

fn errorUnionTrySwitchReturn(function: ir.Function) ?ErrorUnionTrySwitchReturn {
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.blocks.items.len < 6) return null;
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
    const then_is_switch = blockSwitchTerminator(then_block) != null;
    const else_is_switch = blockSwitchTerminator(else_block) != null;
    if (then_is_switch == else_is_switch) return null;
    const switch_block = if (then_is_switch) then_block else else_block;
    const err_block = if (then_is_switch) else_block else then_block;
    if (!blockReturnsNamedValue(err_block, call_name, .{ .int = 64 })) return null;

    const switch_term = blockSwitchTerminator(switch_block) orelse return null;
    if (!switch_term.cond_ty.eql(.{ .int = 32 })) return null;
    const mask = payloadMaskConst(switch_block, switch_term.cond, call_name) orelse return null;
    if (switch_term.cases.items.len == 0 or switch_term.cases.items.len > 8) return null;
    const merge_block = commonSwitchMergeBlock(function, switch_term) orelse return null;
    const phi = firstPhiReturn(function, merge_block) orelse return null;
    if (!phi.ty.eql(.{ .int = 64 })) return null;

    var cases: [8]ErrorUnionTrySwitchCase = undefined;
    for (switch_term.cases.items, 0..) |case, case_index| {
        if (!case.value_ty.eql(.{ .int = 32 })) return null;
        const value = switch (case.value) {
            .int => |int| i32Value(int) catch return null,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
        };
        const block = function.blocks.items[blockIndex(function, case.target) orelse return null];
        if (!blockBranchesTo(block, merge_block.name)) return null;
        cases[case_index] = .{
            .value = value,
            .block = block,
            .add_imm = payloadAddWrapPhiIncoming(function, switch_block, phi, block.name, call_name) orelse return null,
        };
    }
    const default_block = function.blocks.items[blockIndex(function, switch_term.default_target) orelse return null];
    if (!blockBranchesTo(default_block, merge_block.name)) return null;
    const default_case: ErrorUnionTrySwitchCase = .{
        .value = 0,
        .block = default_block,
        .add_imm = payloadAddWrapPhiIncoming(function, switch_block, phi, default_block.name, call_name) orelse return null,
    };
    if (!trySwitchUsesAllBlocks(function, switch_block.name, err_block.name, merge_block.name, switch_term)) return null;

    return .{
        .entry = entry,
        .call_name = call_name,
        .call = call,
        .err_block = err_block,
        .switch_block = switch_block,
        .merge_block = merge_block,
        .mask = mask,
        .cases = cases,
        .case_count = switch_term.cases.items.len,
        .default_case = default_case,
    };
}

fn payloadMaskConst(block: ir.BasicBlock, value: ir.Value, call_name: []const u8) ?i32 {
    const mask_name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const mask_inst = findInstruction(block, mask_name) orelse return null;
    const mask = switch (mask_inst.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (!mask.ty.eql(.{ .int = 32 }) or mask.op != .@"and") return null;
    const rhs = switch (mask.rhs) {
        .int => |int| i32Value(int) catch return null,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!payloadValueFromCallResult(block, mask.lhs, call_name)) return null;
    return rhs;
}

fn payloadAddWrapPhiIncoming(
    function: ir.Function,
    payload_scope: ir.BasicBlock,
    phi: ir.PhiInst,
    predecessor: []const u8,
    call_name: []const u8,
) ?u8 {
    for (phi.incoming.items) |incoming| {
        if (!std.mem.eql(u8, incoming.block, predecessor)) continue;
        const value_block = function.blocks.items[blockIndex(function, predecessor) orelse return null];
        return payloadAddWrapValue(value_block, payload_scope, incoming.value, call_name);
    }
    return null;
}

pub fn payloadAddWrapValue(value_block: ir.BasicBlock, payload_scope: ir.BasicBlock, value: ir.Value, call_name: []const u8) ?u8 {
    const shl_name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const shl_inst = findInstruction(value_block, shl_name) orelse return null;
    const shl = switch (shl_inst.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (!shl.ty.eql(.{ .int = 64 }) or shl.op != .shl or !isInt(shl.rhs, 16)) return null;
    const zext_name = switch (shl.lhs) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const zext_inst = findInstruction(value_block, zext_name) orelse return null;
    const zext = switch (zext_inst.kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 32 }) or !zext.to_ty.eql(.{ .int = 64 })) return null;
    const add_name = switch (zext.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const add_inst = findInstruction(value_block, add_name) orelse return null;
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
    if (!payloadValueFromCallResult(payload_scope, add.lhs, call_name)) return null;
    return @intCast(rhs);
}

fn trySwitchUsesAllBlocks(
    function: ir.Function,
    switch_block: []const u8,
    err_block: []const u8,
    merge_block: []const u8,
    switch_term: ir.SwitchTerminator,
) bool {
    for (function.blocks.items, 0..) |block, index| {
        if (index == 0 or
            std.mem.eql(u8, block.name, switch_block) or
            std.mem.eql(u8, block.name, err_block) or
            std.mem.eql(u8, block.name, merge_block) or
            std.mem.eql(u8, block.name, switch_term.default_target))
        {
            continue;
        }
        var matched_case = false;
        for (switch_term.cases.items) |case| {
            if (std.mem.eql(u8, block.name, case.target)) {
                matched_case = true;
                break;
            }
        }
        if (!matched_case) return false;
    }
    return true;
}

pub const ErrorUnionSwitchPhiCase = struct {
    value: i32,
    block: ir.BasicBlock,
    incoming: ir.Value,
};

const ErrorUnionSwitchCond = union(enum) {
    param: ArgReg,
    masked_param: struct {
        reg: ArgReg,
        mask: i32,
    },
};

const ErrorUnionSwitchPhiReturn = struct {
    entry: ir.BasicBlock,
    cond: ErrorUnionSwitchCond,
    cases: [8]ErrorUnionSwitchPhiCase,
    case_count: usize,
    default_block: ir.BasicBlock,
    default_incoming: ir.Value,
};

const ErrorUnionErrorTagSwitchReturn = struct {
    entry: ir.BasicBlock,
    call_name: []const u8,
    call: ir.CallInst,
    success_block: ir.BasicBlock,
    success_return: ErrorUnionI32ReturnValue,
    switch_block: ir.BasicBlock,
    cases: [8]ErrorUnionSwitchPhiCase,
    case_count: usize,
    default_block: ir.BasicBlock,
    merge_block: ir.BasicBlock,
    live_param_reg: ?ArgReg,
};

const ErrorUnionErrorTagBranchReturn = struct {
    entry: ir.BasicBlock,
    call_name: []const u8,
    call: ir.CallInst,
    payload_block: ir.BasicBlock,
    payload_return: ErrorUnionI32ReturnValue,
    branch_block: ir.BasicBlock,
    error_value: i32,
    true_block: ir.BasicBlock,
    true_value: i32,
    false_block: ir.BasicBlock,
    false_value: i32,
};

const ErrorUnionCatchValueMergeReturn = struct {
    entry: ir.BasicBlock,
    call_name: []const u8,
    call: ir.CallInst,
    payload_block: ir.BasicBlock,
    fallback_block: ir.BasicBlock,
    merge_block: ir.BasicBlock,
    fallback: ErrorUnionCatchFallbackValue,
    add_imm: i32,
};

const ErrorUnionCatchFallbackValue = union(enum) {
    int: i32,
    param: ArgReg,
};

const NamedPhi = struct {
    name: []const u8,
    phi: ir.PhiInst,
};

const ErrorUnionCatchSwitchReturn = struct {
    entry: ir.BasicBlock,
    call_name: []const u8,
    call: ir.CallInst,
    payload_block: ir.BasicBlock,
    payload_add_imm: u8,
    switch_block: ir.BasicBlock,
    cases: [8]ErrorUnionSwitchPhiCase,
    case_count: usize,
    default_block: ir.BasicBlock,
    merge_block: ir.BasicBlock,
};

const ErrorUnionCatchBranchReturn = struct {
    entry: ir.BasicBlock,
    call_name: []const u8,
    call: ir.CallInst,
    payload_block: ir.BasicBlock,
    payload_add_imm: u8,
    branch_block: ir.BasicBlock,
    error_value: i32,
    true_block: ir.BasicBlock,
    true_value: i64,
    false_block: ir.BasicBlock,
    false_value: i64,
};

const ErrorUnionCatchCallReturn = struct {
    entry: ir.BasicBlock,
    call_name: []const u8,
    call: ir.CallInst,
    success_block: ir.BasicBlock,
    success_return: ErrorUnionI32ReturnValue,
    catch_block: ir.BasicBlock,
    catch_call: ir.CallInst,
    live_param_reg: ArgReg,
};

const ErrorUnionCatchTerminalReturn = struct {
    entry: ir.BasicBlock,
    call_name: []const u8,
    call: ir.CallInst,
    success_block: ir.BasicBlock,
    catch_block: ir.BasicBlock,
    live_params: LiveParamSet,
};

const ErrorSetParamSwitchCase = struct {
    value: u16,
    block: ir.BasicBlock,
    incoming: ir.Value,
};

const ErrorSetParamSwitchReturn = struct {
    entry: ir.BasicBlock,
    tag_reg: ArgReg,
    cases: [8]ErrorSetParamSwitchCase,
    case_count: usize,
    default_block: ir.BasicBlock,
    merge_block: ir.BasicBlock,
};

pub const ErrorUnionI32ReturnValue = union(enum) {
    generic: ir.Value,
    payload_add_imm: i32,
    payload_binary: PayloadBinaryWrapReturn,
};

pub fn lowerGenericCfgErrorUnionSwitchPhiReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = errorUnionSwitchPhiReturn(function) orelse return false;
    try emitErrorUnionSwitchCondIntoEax(allocator, machine, plan.cond);
    for (plan.cases[0..plan.case_count]) |case| {
        try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = case.value });
        try appendGenericCfgConditionalBranch(allocator, machine, .je, case.block.name);
    }
    try machine.instructions.append(allocator, .{ .jmp = plan.default_block.name });

    for (plan.cases[0..plan.case_count]) |case| {
        try appendGenericCfgBlockLabel(allocator, machine, case.block.name);
        try emitGenericCfgTerminalI64ValueIntoRax(allocator, machine, function, plan.entry, case.block, case.incoming);
        try appendGenericCfgReturn(allocator, machine);
    }
    try appendGenericCfgBlockLabel(allocator, machine, plan.default_block.name);
    try emitGenericCfgTerminalI64ValueIntoRax(allocator, machine, function, plan.entry, plan.default_block, plan.default_incoming);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub fn lowerGenericCfgErrorUnionErrorTagSwitchReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = errorUnionErrorTagSwitchReturn(function) orelse return false;
    const frame_bytes: u8 = if (plan.live_param_reg != null) 24 else 8;
    const epilogue_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_error_tag_switch_{}_generic_cfg_select_end",
        .{machine.instructions.items.len},
    );

    try appendStackFrame(allocator, machine, frame_bytes);
    if (plan.live_param_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{ .frame_index = .slot2, .reg = reg } });
    }
    try emitTwoI32ArgCallIntoRax(allocator, machine, function, plan.entry, plan.call);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, .je, plan.success_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, plan.switch_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    for (plan.cases[0..plan.case_count]) |case| {
        try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = case.value });
        try appendGenericCfgConditionalBranch(allocator, machine, .je, case.block.name);
    }
    try machine.instructions.append(allocator, .{ .jmp = plan.default_block.name });

    for (plan.cases[0..plan.case_count]) |case| {
        try appendGenericCfgBlockLabel(allocator, machine, case.block.name);
        try emitErrorUnionI32ReturnValueIntoEax(allocator, machine, function, plan.entry, case.block, .{ .generic = case.incoming }, plan.live_param_reg);
        try machine.instructions.append(allocator, .{ .jmp = epilogue_label });
    }

    try appendGenericCfgBlockLabel(allocator, machine, plan.success_block.name);
    try emitErrorUnionI32ReturnValueIntoEax(allocator, machine, function, plan.entry, plan.success_block, plan.success_return, plan.live_param_reg);
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);

    try appendGenericCfgBlockLabel(allocator, machine, plan.default_block.name);
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerGenericCfgErrorUnionErrorTagBranchReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = errorUnionErrorTagBranchReturn(function) orelse return false;
    const frame_bytes: u8 = 8;
    const epilogue_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_error_tag_branch_{}_generic_cfg_select_end",
        .{machine.instructions.items.len},
    );

    try appendStackFrame(allocator, machine, frame_bytes);
    try emitTwoI32ArgCallIntoRax(allocator, machine, function, plan.entry, plan.call);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, .je, plan.payload_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, plan.branch_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = plan.error_value });
    try appendGenericCfgConditionalBranch(allocator, machine, .je, plan.true_block.name);
    try appendGenericCfgBlockLabel(allocator, machine, plan.false_block.name);
    try machine.instructions.append(allocator, .{ .mov_imm_eax = plan.false_value });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, plan.true_block.name);
    try machine.instructions.append(allocator, .{ .mov_imm_eax = plan.true_value });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, plan.payload_block.name);
    try emitErrorUnionI32ReturnValueIntoEax(allocator, machine, function, plan.entry, plan.payload_block, plan.payload_return, null);
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub fn lowerGenericCfgErrorUnionCatchValueMergeReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = errorUnionCatchValueMergeReturn(function) orelse return false;
    const live_fallback_reg: ?ArgReg = switch (plan.fallback) {
        .param => |reg| reg,
        .int => null,
    };
    const frame_bytes: u8 = if (live_fallback_reg != null) 24 else 8;
    const fallback_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_error_catch_value_{}_fallback",
        .{machine.instructions.items.len},
    );
    const epilogue_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_error_catch_value_{}_generic_cfg_select_end",
        .{machine.instructions.items.len},
    );

    try appendStackFrame(allocator, machine, frame_bytes);
    if (live_fallback_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{ .frame_index = .slot2, .reg = reg } });
    }
    try emitTwoI32ArgCallIntoRax(allocator, machine, function, plan.entry, plan.call);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, .jne, fallback_label);

    try appendGenericCfgBlockLabel(allocator, machine, plan.payload_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 16 });
    if (plan.add_imm != 0) try machine.instructions.append(allocator, .{ .add_eax_imm32 = plan.add_imm });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, fallback_label);
    switch (plan.fallback) {
        .int => |value| try machine.instructions.append(allocator, .{ .mov_imm_eax = value }),
        .param => |reg| {
            try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{ .frame_index = .slot2, .reg = reg } });
            try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
        },
    }
    if (plan.add_imm != 0) try machine.instructions.append(allocator, .{ .add_eax_imm32 = plan.add_imm });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub fn lowerGenericCfgErrorUnionCatchSwitchReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = errorUnionCatchSwitchReturn(function) orelse return false;
    const frame_bytes: u8 = 8;
    const epilogue_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_error_catch_switch_{}_generic_cfg_select_end",
        .{machine.instructions.items.len},
    );

    try appendStackFrame(allocator, machine, frame_bytes);
    try emitTwoI32ArgCallIntoRax(allocator, machine, function, plan.entry, plan.call);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, .je, plan.payload_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, plan.switch_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    for (plan.cases[0..plan.case_count]) |case| {
        try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = case.value });
        try appendGenericCfgConditionalBranch(allocator, machine, .je, case.block.name);
    }
    try machine.instructions.append(allocator, .{ .jmp = plan.default_block.name });

    for (plan.cases[0..plan.case_count]) |case| {
        try appendGenericCfgBlockLabel(allocator, machine, case.block.name);
        try emitGenericCfgTerminalI64ValueIntoRax(allocator, machine, function, plan.entry, case.block, case.incoming);
        try machine.instructions.append(allocator, .{ .jmp = epilogue_label });
    }

    try appendGenericCfgBlockLabel(allocator, machine, plan.payload_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 16 });
    if (plan.payload_add_imm != 0) try machine.instructions.append(allocator, .{ .add_rax_imm8 = plan.payload_add_imm });
    try machine.instructions.append(allocator, .{ .shl_rax_imm6 = 16 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);

    try appendGenericCfgBlockLabel(allocator, machine, plan.default_block.name);
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerGenericCfgErrorUnionCatchBranchReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = errorUnionCatchBranchReturn(function) orelse return false;
    const frame_bytes: u8 = 8;
    const epilogue_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_error_catch_branch_{}_generic_cfg_select_end",
        .{machine.instructions.items.len},
    );

    try appendStackFrame(allocator, machine, frame_bytes);
    try emitTwoI32ArgCallIntoRax(allocator, machine, function, plan.entry, plan.call);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, .je, plan.payload_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, plan.branch_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = plan.error_value });
    try appendGenericCfgConditionalBranch(allocator, machine, .je, plan.true_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, plan.false_block.name);
    try machine.instructions.append(allocator, .{ .mov_imm_rax = plan.false_value });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, plan.true_block.name);
    try machine.instructions.append(allocator, .{ .mov_imm_rax = plan.true_value });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, plan.payload_block.name);
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

pub fn lowerGenericCfgErrorUnionCatchCallReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = errorUnionCatchCallReturn(function) orelse return false;
    const frame_bytes: u8 = 24;
    const epilogue_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_error_catch_call_{}_generic_cfg_select_end",
        .{machine.instructions.items.len},
    );

    try appendStackFrame(allocator, machine, frame_bytes);
    try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{ .frame_index = .slot2, .reg = plan.live_param_reg } });
    try emitTwoI32ArgCallIntoRax(allocator, machine, function, plan.entry, plan.call);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, .je, plan.success_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, plan.catch_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .mov_rax_rdi);
    try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{ .frame_index = .slot2, .reg = .rsi } });
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = plan.catch_call.callee, .ret_ty = plan.catch_call.ret_ty } });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, plan.success_block.name);
    try emitErrorUnionI32ReturnValueIntoEax(allocator, machine, function, plan.entry, plan.success_block, plan.success_return, plan.live_param_reg);
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub fn lowerGenericCfgErrorUnionCatchTerminalReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = errorUnionCatchTerminalReturn(function) orelse return false;

    try appendAlignedCallPreservingI32Params(allocator, machine, function, plan.call, plan.live_params, .{ .direct = plan.call.callee });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, .je, plan.success_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, plan.catch_block.name);
    try emitGenericCfgTerminalReturnBlock(allocator, machine, function, plan.entry, plan.catch_block);

    try appendGenericCfgBlockLabel(allocator, machine, plan.success_block.name);
    try emitGenericCfgTerminalReturnBlock(allocator, machine, function, plan.entry, plan.success_block);
    return true;
}

pub fn lowerGenericCfgErrorSetParamSwitchReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = errorSetParamSwitchReturn(function) orelse return false;
    for (plan.cases[0..plan.case_count]) |case| {
        try machine.instructions.append(allocator, .{ .cmp_arg16_imm16 = .{ .reg = plan.tag_reg, .imm = case.value } });
        try appendGenericCfgConditionalBranch(allocator, machine, .je, case.block.name);
    }
    try machine.instructions.append(allocator, .{ .jmp = plan.default_block.name });

    for (plan.cases[0..plan.case_count]) |case| {
        try appendGenericCfgBlockLabel(allocator, machine, case.block.name);
        try emitGenericCfgTerminalI32ValueIntoEax(allocator, machine, function, plan.entry, case.block, case.incoming);
        try appendGenericCfgReturn(allocator, machine);
    }

    try appendGenericCfgBlockLabel(allocator, machine, plan.default_block.name);
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn errorUnionSwitchPhiReturn(function: ir.Function) ?ErrorUnionSwitchPhiReturn {
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.blocks.items.len < 4) return null;
    const entry = function.blocks.items[0];
    const switch_term = blockSwitchTerminator(entry) orelse return null;
    if (!switch_term.cond_ty.eql(.{ .int = 32 })) return null;
    const cond = errorUnionSwitchCond(function, entry, switch_term.cond) orelse return null;
    if (switch_term.cases.items.len == 0 or switch_term.cases.items.len > 8) return null;
    const merge_block = commonSwitchMergeBlock(function, switch_term) orelse return null;
    const phi = firstPhiReturn(function, merge_block) orelse return null;
    if (!phi.ty.eql(.{ .int = 64 })) return null;

    var cases: [8]ErrorUnionSwitchPhiCase = undefined;
    for (switch_term.cases.items, 0..) |case, case_index| {
        if (!case.value_ty.eql(.{ .int = 32 })) return null;
        const value = switch (case.value) {
            .int => |int| i32Value(int) catch return null,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
        };
        const block = function.blocks.items[blockIndex(function, case.target) orelse return null];
        if (!blockBranchesTo(block, merge_block.name)) return null;
        cases[case_index] = .{
            .value = value,
            .block = block,
            .incoming = phiIncomingForBlock(phi, block.name) orelse return null,
        };
    }
    const default_block = function.blocks.items[blockIndex(function, switch_term.default_target) orelse return null];
    if (!blockBranchesTo(default_block, merge_block.name)) return null;
    if (!switchPhiUsesAllBlocks(function, merge_block.name, switch_term)) return null;

    return .{
        .entry = entry,
        .cond = cond,
        .cases = cases,
        .case_count = switch_term.cases.items.len,
        .default_block = default_block,
        .default_incoming = phiIncomingForBlock(phi, default_block.name) orelse return null,
    };
}

fn errorUnionSwitchCond(function: ir.Function, entry: ir.BasicBlock, value: ir.Value) ?ErrorUnionSwitchCond {
    const name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (entry.instructions.items.len == 0) {
        const reg = paramRegOrNull(function, name, .{ .int = 32 }) catch return null;
        return .{ .param = reg orelse return null };
    }
    if (entry.instructions.items.len != 1) return null;
    const instruction = findInstruction(entry, name) orelse return null;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (binary.op != .@"and" or !binary.ty.eql(.{ .int = 32 })) return null;
    const reg = switch (binary.lhs) {
        .named => |lhs| paramRegOrNull(function, lhs, .{ .int = 32 }) catch return null,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    } orelse return null;
    const mask = switch (binary.rhs) {
        .int => |int| i32Value(int) catch return null,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    return .{ .masked_param = .{ .reg = reg, .mask = mask } };
}

fn emitErrorUnionSwitchCondIntoEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    cond: ErrorUnionSwitchCond,
) !void {
    switch (cond) {
        .param => |reg| try machine.instructions.append(allocator, .{ .mov_arg_eax = reg }),
        .masked_param => |masked| {
            try machine.instructions.append(allocator, .{ .mov_arg_eax = masked.reg });
            try machine.instructions.append(allocator, .{ .and_eax_imm32 = masked.mask });
        },
    }
}

fn switchPhiUsesAllBlocks(
    function: ir.Function,
    merge_block: []const u8,
    switch_term: ir.SwitchTerminator,
) bool {
    for (function.blocks.items, 0..) |block, index| {
        if (index == 0 or
            std.mem.eql(u8, block.name, merge_block) or
            std.mem.eql(u8, block.name, switch_term.default_target))
        {
            continue;
        }
        var matched_case = false;
        for (switch_term.cases.items) |case| {
            if (std.mem.eql(u8, block.name, case.target)) {
                matched_case = true;
                break;
            }
        }
        if (!matched_case) return false;
    }
    return true;
}

fn errorUnionErrorTagSwitchReturn(function: ir.Function) ?ErrorUnionErrorTagSwitchReturn {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.blocks.items.len < 6) return null;
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
    if (!supportsDirectI64Call(call)) return null;

    const then_block = function.blocks.items[blockIndex(function, entry_condbr.then_target) orelse return null];
    const else_block = function.blocks.items[blockIndex(function, entry_condbr.else_target) orelse return null];
    const then_is_switch = errorUnionErrorTagSwitchBlock(then_block, call_name);
    const else_is_switch = errorUnionErrorTagSwitchBlock(else_block, call_name);
    if (then_is_switch == else_is_switch) return null;
    const success_block = if (then_is_switch) else_block else then_block;
    const switch_block = if (then_is_switch) then_block else else_block;
    const success_return = errorUnionPayloadI32Return(function, success_block, call_name) orelse
        errorUnionGenericI32Return(success_block) orelse return null;

    const switch_term = blockSwitchTerminator(switch_block) orelse return null;
    if (switch_term.cases.items.len == 0 or switch_term.cases.items.len > 8) return null;
    const merge_block = exhaustiveSwitchMergeBlock(function, switch_term) orelse return null;
    const phi = firstPhiReturn(function, merge_block) orelse return null;
    if (!phi.ty.eql(.{ .int = 32 })) return null;

    var cases: [8]ErrorUnionSwitchPhiCase = undefined;
    var live_param_reg = errorUnionI32ReturnLiveParam(function, success_block, success_return);
    for (switch_term.cases.items, 0..) |case, case_index| {
        if (!case.value_ty.eql(.{ .int = 16 })) return null;
        const value = switch (case.value) {
            .int => |int| i32Value(int) catch return null,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
        };
        const block = function.blocks.items[blockIndex(function, case.target) orelse return null];
        if (!blockBranchesTo(block, merge_block.name)) return null;
        const incoming = phiIncomingForBlock(phi, block.name) orelse return null;
        if (!mergeLiveParam(&live_param_reg, errorUnionI32ReturnLiveParam(function, block, .{ .generic = incoming }))) return null;
        cases[case_index] = .{
            .value = value,
            .block = block,
            .incoming = incoming,
        };
    }
    const default_block = function.blocks.items[blockIndex(function, switch_term.default_target) orelse return null];
    if (!blockIsUnreachable(default_block)) return null;
    if (!errorTagSwitchUsesAllBlocks(function, success_block.name, switch_block.name, merge_block.name, switch_term)) return null;

    return .{
        .entry = entry,
        .call_name = call_name,
        .call = call,
        .success_block = success_block,
        .success_return = success_return,
        .switch_block = switch_block,
        .cases = cases,
        .case_count = switch_term.cases.items.len,
        .default_block = default_block,
        .merge_block = merge_block,
        .live_param_reg = live_param_reg,
    };
}

fn errorUnionErrorTagSwitchBlock(block: ir.BasicBlock, call_name: []const u8) bool {
    const switch_term = blockSwitchTerminator(block) orelse return false;
    return switch_term.cond_ty.eql(.{ .int = 16 }) and errorTagValueFromCallResult(block, switch_term.cond, call_name);
}

fn errorUnionErrorTagBranchReturn(function: ir.Function) ?ErrorUnionErrorTagBranchReturn {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.blocks.items.len < 5) return null;
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
    const then_payload_return = errorUnionPayloadI32Return(function, then_block, call_name);
    const else_payload_return = errorUnionPayloadI32Return(function, else_block, call_name);
    if ((then_payload_return != null) == (else_payload_return != null)) return null;
    const payload_block = if (then_payload_return != null) then_block else else_block;
    const branch_block = if (then_payload_return != null) else_block else then_block;
    const payload_return = then_payload_return orelse else_payload_return.?;
    if (errorUnionI32ReturnLiveParam(function, payload_block, payload_return) != null) return null;

    const branch_condbr = switch (branch_block.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!branch_condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const error_value = errorTagIcmpValueFromCallResult(branch_block, branch_condbr.cond, call_name) orelse return null;
    const true_block = function.blocks.items[blockIndex(function, branch_condbr.then_target) orelse return null];
    const false_block = function.blocks.items[blockIndex(function, branch_condbr.else_target) orelse return null];
    const true_value = terminalConstI32Return(true_block) orelse return null;
    const false_value = terminalConstI32Return(false_block) orelse return null;
    if (!errorTagBranchUsesOnlyExpectedBlocks(function, entry.name, payload_block.name, branch_block.name, true_block.name, false_block.name)) return null;

    return .{
        .entry = entry,
        .call_name = call_name,
        .call = call,
        .payload_block = payload_block,
        .payload_return = payload_return,
        .branch_block = branch_block,
        .error_value = error_value,
        .true_block = true_block,
        .true_value = true_value,
        .false_block = false_block,
        .false_value = false_value,
    };
}

fn errorUnionCatchValueMergeReturn(function: ir.Function) ?ErrorUnionCatchValueMergeReturn {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.blocks.items.len < 4) return null;
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
    const then_target = singleBrTarget(then_block) orelse return null;
    const else_target = singleBrTarget(else_block) orelse return null;
    if (!std.mem.eql(u8, then_target, else_target)) return null;
    const merge_block = function.blocks.items[blockIndex(function, then_target) orelse return null];
    const named_phi = firstNamedPhi(merge_block) orelse return null;
    const phi = named_phi.phi;
    if (!phi.ty.eql(.{ .int = 32 })) return null;

    const then_incoming = phiIncomingForBlock(phi, then_block.name) orelse return null;
    const else_incoming = phiIncomingForBlock(phi, else_block.name) orelse return null;
    const then_is_payload = payloadValueFromCallResult(then_block, then_incoming, call_name);
    const else_is_payload = payloadValueFromCallResult(else_block, else_incoming, call_name);
    if (then_is_payload == else_is_payload) return null;
    const payload_block = if (then_is_payload) then_block else else_block;
    const fallback_block = if (then_is_payload) else_block else then_block;
    const fallback_value = if (then_is_payload) else_incoming else then_incoming;
    const fallback = catchFallbackValue(function, fallback_value) orelse return null;
    const add_imm = phiAddReturnImm(merge_block, named_phi.name) orelse return null;
    if (!catchValueMergeUsesOnlyExpectedBlocks(function, entry.name, payload_block.name, fallback_block.name, merge_block.name)) return null;

    return .{
        .entry = entry,
        .call_name = call_name,
        .call = call,
        .payload_block = payload_block,
        .fallback_block = fallback_block,
        .merge_block = merge_block,
        .fallback = fallback,
        .add_imm = add_imm,
    };
}

fn errorUnionCatchSwitchReturn(function: ir.Function) ?ErrorUnionCatchSwitchReturn {
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.blocks.items.len < 6) return null;
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
    const then_payload_add = payloadAddWrapReturnFromCallResult(then_block, call_name);
    const else_payload_add = payloadAddWrapReturnFromCallResult(else_block, call_name);
    if ((then_payload_add != null) == (else_payload_add != null)) return null;
    const payload_block = if (then_payload_add != null) then_block else else_block;
    const switch_block = if (then_payload_add != null) else_block else then_block;
    const payload_add_imm = then_payload_add orelse else_payload_add.?;

    const switch_term = blockSwitchTerminator(switch_block) orelse return null;
    if (!switch_term.cond_ty.eql(.{ .int = 16 })) return null;
    if (!errorTagValueFromCallResult(switch_block, switch_term.cond, call_name)) return null;
    if (switch_term.cases.items.len == 0 or switch_term.cases.items.len > 8) return null;
    const merge_block = exhaustiveSwitchMergeBlock(function, switch_term) orelse return null;
    const phi = firstPhiReturn(function, merge_block) orelse return null;
    if (!phi.ty.eql(.{ .int = 64 })) return null;

    var cases: [8]ErrorUnionSwitchPhiCase = undefined;
    for (switch_term.cases.items, 0..) |case, case_index| {
        if (!case.value_ty.eql(.{ .int = 16 })) return null;
        const value = switch (case.value) {
            .int => |int| i32Value(int) catch return null,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
        };
        const block = function.blocks.items[blockIndex(function, case.target) orelse return null];
        if (!blockBranchesTo(block, merge_block.name)) return null;
        cases[case_index] = .{
            .value = value,
            .block = block,
            .incoming = phiIncomingForBlock(phi, block.name) orelse return null,
        };
    }
    const default_block = function.blocks.items[blockIndex(function, switch_term.default_target) orelse return null];
    if (!blockIsUnreachable(default_block)) return null;
    if (!errorTagSwitchUsesAllBlocks(function, payload_block.name, switch_block.name, merge_block.name, switch_term)) return null;

    return .{
        .entry = entry,
        .call_name = call_name,
        .call = call,
        .payload_block = payload_block,
        .payload_add_imm = payload_add_imm,
        .switch_block = switch_block,
        .cases = cases,
        .case_count = switch_term.cases.items.len,
        .default_block = default_block,
        .merge_block = merge_block,
    };
}

fn errorUnionCatchBranchReturn(function: ir.Function) ?ErrorUnionCatchBranchReturn {
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.blocks.items.len < 5) return null;
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
    const then_payload_add = payloadAddWrapReturnFromCallResult(then_block, call_name);
    const else_payload_add = payloadAddWrapReturnFromCallResult(else_block, call_name);
    if ((then_payload_add != null) == (else_payload_add != null)) return null;
    const payload_block = if (then_payload_add != null) then_block else else_block;
    const branch_block = if (then_payload_add != null) else_block else then_block;
    const payload_add_imm = then_payload_add orelse else_payload_add.?;

    const branch_condbr = switch (branch_block.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!branch_condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const error_value = errorTagIcmpValueFromCallResult(branch_block, branch_condbr.cond, call_name) orelse return null;
    const true_block = function.blocks.items[blockIndex(function, branch_condbr.then_target) orelse return null];
    const false_block = function.blocks.items[blockIndex(function, branch_condbr.else_target) orelse return null];
    const true_value = terminalConstI64Return(true_block) orelse return null;
    const false_value = terminalConstI64Return(false_block) orelse return null;
    if (!errorTagBranchUsesOnlyExpectedBlocks(function, entry.name, payload_block.name, branch_block.name, true_block.name, false_block.name)) return null;

    return .{
        .entry = entry,
        .call_name = call_name,
        .call = call,
        .payload_block = payload_block,
        .payload_add_imm = payload_add_imm,
        .branch_block = branch_block,
        .error_value = error_value,
        .true_block = true_block,
        .true_value = true_value,
        .false_block = false_block,
        .false_value = false_value,
    };
}

fn errorUnionCatchCallReturn(function: ir.Function) ?ErrorUnionCatchCallReturn {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.blocks.items.len != 3) return null;
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
    if (!supportsDirectI64Call(call)) return null;

    const then_block = function.blocks.items[blockIndex(function, entry_condbr.then_target) orelse return null];
    const else_block = function.blocks.items[blockIndex(function, entry_condbr.else_target) orelse return null];
    const then_catch_call = catchErrorCallReturn(function, then_block, call_name);
    const else_catch_call = catchErrorCallReturn(function, else_block, call_name);
    if ((then_catch_call != null) == (else_catch_call != null)) return null;
    const success_block = if (then_catch_call != null) else_block else then_block;
    const catch_block = if (then_catch_call != null) then_block else else_block;
    const catch_call = then_catch_call orelse else_catch_call.?;
    const success_return = errorUnionPayloadI32Return(function, success_block, call_name) orelse
        errorUnionGenericI32Return(success_block) orelse return null;
    var live_param_reg: ?ArgReg = catch_call.live_param_reg;
    if (!mergeLiveParam(&live_param_reg, errorUnionI32ReturnLiveParam(function, success_block, success_return))) return null;
    if (!catchCallUsesOnlyExpectedBlocks(function, entry.name, success_block.name, catch_block.name)) return null;

    return .{
        .entry = entry,
        .call_name = call_name,
        .call = call,
        .success_block = success_block,
        .success_return = success_return,
        .catch_block = catch_block,
        .catch_call = catch_call.call,
        .live_param_reg = live_param_reg orelse return null,
    };
}

fn errorUnionCatchTerminalReturn(function: ir.Function) ?ErrorUnionCatchTerminalReturn {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.blocks.items.len != 3) return null;
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
    if (!supportsDirectI64Call(call)) return null;

    const success_block = function.blocks.items[blockIndex(function, entry_condbr.then_target) orelse return null];
    const catch_block = function.blocks.items[blockIndex(function, entry_condbr.else_target) orelse return null];
    if (!genericCfgSupportsTerminalReturnBlock(function, entry, success_block)) return null;
    if (!genericCfgSupportsTerminalReturnBlock(function, entry, catch_block)) return null;

    var live_params: LiveParamSet = .{};
    noteTerminalReturnLiveParams(function, success_block, &live_params) catch return null;
    noteTerminalReturnLiveParams(function, catch_block, &live_params) catch return null;

    return .{
        .entry = entry,
        .call_name = call_name,
        .call = call,
        .success_block = success_block,
        .catch_block = catch_block,
        .live_params = live_params,
    };
}

fn noteTerminalReturnLiveParams(function: ir.Function, block: ir.BasicBlock, live_params: *LiveParamSet) !void {
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    try noteLiveValueSet(function, block, ret.value orelse return error.InvalidRet, live_params);
}

const CatchErrorCallReturn = struct {
    call: ir.CallInst,
    live_param_reg: ArgReg,
};

fn catchErrorCallReturn(function: ir.Function, block: ir.BasicBlock, call_name: []const u8) ?CatchErrorCallReturn {
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return null;
    const call_result = switch (ret.value orelse return null) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const call_instruction = findInstruction(block, call_result) orelse return null;
    const call = switch (call_instruction.kind) {
        .call => |call| call,
        else => return null,
    };
    if (!supportsDirectI16I32ToI32Call(call) or call.args.items.len != 2) return null;

    var error_arg_count: usize = 0;
    var live_param_reg: ?ArgReg = null;
    for (call.args.items) |arg| {
        if (arg.ty.eql(.{ .int = 16 }) and errorTagValueFromCallResult(block, arg.value, call_name)) {
            error_arg_count += 1;
            continue;
        }
        if (!arg.ty.eql(.{ .int = 32 })) return null;
        const reg = switch (arg.value) {
            .named => |name| paramReg(function, name, .{ .int = 32 }) catch return null,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
        };
        if (live_param_reg != null and live_param_reg.? != reg) return null;
        live_param_reg = reg;
    }
    if (error_arg_count != 1) return null;
    return .{ .call = call, .live_param_reg = live_param_reg orelse return null };
}

fn catchCallUsesOnlyExpectedBlocks(function: ir.Function, entry: []const u8, payload: []const u8, catch_block: []const u8) bool {
    for (function.blocks.items) |block| {
        if (std.mem.eql(u8, block.name, entry) or
            std.mem.eql(u8, block.name, payload) or
            std.mem.eql(u8, block.name, catch_block))
        {
            continue;
        }
        return false;
    }
    return true;
}

fn errorSetParamSwitchReturn(function: ir.Function) ?ErrorSetParamSwitchReturn {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.blocks.items.len < 3) return null;
    const entry = function.blocks.items[0];
    const switch_term = blockSwitchTerminator(entry) orelse return null;
    if (!switch_term.cond_ty.eql(.{ .int = 16 }) or switch_term.cases.items.len == 0 or switch_term.cases.items.len > 8) return null;
    const cond_name = switch (switch_term.cond) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const tag_reg = paramReg(function, cond_name, .{ .int = 16 }) catch return null;

    const merge_block = exhaustiveSwitchMergeBlock(function, switch_term) orelse return null;
    const phi = firstPhiReturn(function, merge_block) orelse return null;
    if (!phi.ty.eql(.{ .int = 32 })) return null;

    var cases: [8]ErrorSetParamSwitchCase = undefined;
    for (switch_term.cases.items, 0..) |case, case_index| {
        if (!case.value_ty.eql(.{ .int = 16 })) return null;
        const value_i32 = switch (case.value) {
            .int => |int| i32Value(int) catch return null,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
        };
        if (value_i32 < 0 or value_i32 > std.math.maxInt(u16)) return null;
        const block = function.blocks.items[blockIndex(function, case.target) orelse return null];
        if (!blockBranchesTo(block, merge_block.name)) return null;
        cases[case_index] = .{
            .value = @intCast(value_i32),
            .block = block,
            .incoming = phiIncomingForBlock(phi, block.name) orelse return null,
        };
    }
    const default_block = function.blocks.items[blockIndex(function, switch_term.default_target) orelse return null];
    if (!blockIsUnreachable(default_block)) return null;
    if (!errorSetSwitchUsesAllBlocks(function, entry.name, default_block.name, merge_block.name, switch_term)) return null;
    return .{
        .entry = entry,
        .tag_reg = tag_reg,
        .cases = cases,
        .case_count = switch_term.cases.items.len,
        .default_block = default_block,
        .merge_block = merge_block,
    };
}

fn errorSetSwitchUsesAllBlocks(function: ir.Function, entry: []const u8, default_block: []const u8, merge_block: []const u8, switch_term: ir.SwitchTerminator) bool {
    for (function.blocks.items) |block| {
        if (std.mem.eql(u8, block.name, entry) or
            std.mem.eql(u8, block.name, default_block) or
            std.mem.eql(u8, block.name, merge_block))
        {
            continue;
        }
        var expected_case = false;
        for (switch_term.cases.items) |case| {
            if (std.mem.eql(u8, block.name, case.target)) {
                expected_case = true;
                break;
            }
        }
        if (!expected_case) return false;
    }
    return true;
}

pub fn errorUnionPayloadI32Return(function: ir.Function, block: ir.BasicBlock, call_name: []const u8) ?ErrorUnionI32ReturnValue {
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return null;
    const ret_value = ret.value orelse return null;
    if (payloadValueFromCallResult(block, ret_value, call_name)) return .{ .payload_add_imm = 0 };
    const add_name = switch (ret_value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (payloadAddFromCallResult(block, add_name, call_name)) |imm| return .{ .payload_add_imm = imm };
    if (payloadBinaryI32Return(function, block, block, call_name)) |binary| return .{ .payload_binary = binary };
    return null;
}

fn errorUnionGenericI32Return(block: ir.BasicBlock) ?ErrorUnionI32ReturnValue {
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return null;
    return .{ .generic = ret.value orelse return null };
}

pub fn payloadAddWrapReturnFromCallResult(block: ir.BasicBlock, call_name: []const u8) ?u8 {
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 64 })) return null;
    return payloadAddWrapValue(block, block, ret.value orelse return null, call_name);
}

fn terminalConstI64Return(block: ir.BasicBlock) ?i64 {
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 64 })) return null;
    const value = switch (ret.value orelse return null) {
        .int => |int| int,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    return i64Value(value) catch null;
}

fn payloadBinaryI32Return(
    function: ir.Function,
    payload_scope: ir.BasicBlock,
    block: ir.BasicBlock,
    call_name: []const u8,
) ?PayloadBinaryWrapReturn {
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return null;
    const binary_name = switch (ret.value orelse return null) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const binary_inst = findInstruction(block, binary_name) orelse return null;
    const binary = switch (binary_inst.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (!binary.ty.eql(.{ .int = 32 }) or (binary.op != .add and binary.op != .sub)) return null;
    const payload_on_lhs = payloadValueFromCallResult(payload_scope, binary.lhs, call_name);
    const payload_on_rhs = payloadValueFromCallResult(payload_scope, binary.rhs, call_name);
    if (payload_on_lhs == payload_on_rhs) return null;
    if (binary.op == .sub and !payload_on_lhs) return null;
    const other_value = if (payload_on_lhs) binary.rhs else binary.lhs;
    const reg = switch (other_value) {
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

pub fn errorUnionI32ReturnLiveParam(function: ir.Function, block: ir.BasicBlock, value: ErrorUnionI32ReturnValue) ?ArgReg {
    return switch (value) {
        .payload_binary => |binary| binary.reg,
        .payload_add_imm => null,
        .generic => |generic| i32ValueLiveParam(function, block, generic),
    };
}

fn i32ValueLiveParam(function: ir.Function, block: ir.BasicBlock, value: ir.Value) ?ArgReg {
    switch (value) {
        .int => return null,
        .named => |name| {
            if (paramRegOrNull(function, name, .{ .int = 32 }) catch null) |reg| return reg;
            const instruction = findInstruction(block, name) orelse return null;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (!binary.ty.eql(.{ .int = 32 })) return null;
                    const lhs = i32ValueLiveParam(function, block, binary.lhs);
                    const rhs = i32ValueLiveParam(function, block, binary.rhs);
                    if (lhs != null and rhs != null) return null;
                    return lhs orelse rhs;
                },
                else => return null,
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    }
}

pub fn mergeLiveParam(existing: *?ArgReg, candidate: ?ArgReg) bool {
    const candidate_reg = candidate orelse return true;
    if (existing.*) |existing_reg| return existing_reg == candidate_reg;
    existing.* = candidate_reg;
    return true;
}

pub fn emitErrorUnionI32ReturnValueIntoEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    entry: ir.BasicBlock,
    block: ir.BasicBlock,
    value: ErrorUnionI32ReturnValue,
    live_param_reg: ?ArgReg,
) !void {
    switch (value) {
        .payload_add_imm => |imm| {
            try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
            try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 16 });
            if (imm != 0) try machine.instructions.append(allocator, .{ .add_eax_imm32 = imm });
        },
        .payload_binary => |binary| {
            const live_reg = live_param_reg orelse return error.UnsupportedLiveAcrossCall;
            if (live_reg != binary.reg) return error.UnsupportedLiveAcrossCall;
            try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
            try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 16 });
            try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{ .frame_index = .slot2, .reg = binary.reg } });
            try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = binary.op, .reg = binary.reg } });
        },
        .generic => |generic| {
            if (live_param_reg) |reg| {
                try emitI32ValueWithLiveParamIntoEax(allocator, machine, function, entry, block, generic, reg);
            } else {
                try emitGenericCfgTerminalI32ValueIntoEax(allocator, machine, function, entry, block, generic);
            }
        },
    }
}

fn emitI32ValueWithLiveParamIntoEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    entry: ir.BasicBlock,
    block: ir.BasicBlock,
    value: ir.Value,
    live_param_reg: ArgReg,
) !void {
    switch (value) {
        .int => |int| try machine.instructions.append(allocator, .{ .mov_imm_eax = try i32Value(int) }),
        .named => |name| {
            if ((paramRegOrNull(function, name, .{ .int = 32 }) catch null)) |reg| {
                if (reg == live_param_reg) {
                    try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{ .frame_index = .slot2, .reg = reg } });
                }
                try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
                return;
            }
            const instruction = findInstruction(block, name) orelse return error.UnsupportedCodegenValue;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (!binary.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
                    try emitI32ValueWithLiveParamIntoEax(allocator, machine, function, entry, block, binary.lhs, live_param_reg);
                    switch (binary.rhs) {
                        .int => |int| switch (binary.op) {
                            .add => try machine.instructions.append(allocator, .{ .add_eax_imm32 = try i32Value(int) }),
                            .sub => try machine.instructions.append(allocator, .{ .add_eax_imm32 = -try i32Value(int) }),
                            else => return error.UnsupportedCodegenInstruction,
                        },
                        .named => |rhs_name| {
                            const rhs_reg = try paramReg(function, rhs_name, .{ .int = 32 });
                            if (rhs_reg == live_param_reg) {
                                try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{ .frame_index = .slot2, .reg = rhs_reg } });
                            }
                            const op = machineBinaryOp(binary.op) orelse return error.UnsupportedCodegenInstruction;
                            try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = op, .reg = rhs_reg } });
                        },
                        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
                    }
                },
                else => try emitGenericCfgTerminalI32ValueIntoEax(allocator, machine, function, entry, block, value),
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn errorTagValueFromCallResult(block: ir.BasicBlock, value: ir.Value, call_name: []const u8) bool {
    const trunc_name = switch (value) {
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
    return mask.ty.eql(.{ .int = 64 }) and mask.op == .@"and" and isInt(mask.rhs, 65535) and isNamed(mask.lhs, call_name);
}

pub fn errorTagIcmpValueFromCallResult(block: ir.BasicBlock, value: ir.Value, call_name: []const u8) ?i32 {
    const icmp_name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const icmp_inst = findInstruction(block, icmp_name) orelse return null;
    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 16 })) return null;
    if (errorTagValueFromCallResult(block, icmp.lhs, call_name)) {
        return switch (icmp.rhs) {
            .int => |int| i32Value(int) catch null,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
        };
    }
    if (errorTagValueFromCallResult(block, icmp.rhs, call_name)) {
        return switch (icmp.lhs) {
            .int => |int| i32Value(int) catch null,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
        };
    }
    return null;
}

fn errorTagBranchUsesOnlyExpectedBlocks(
    function: ir.Function,
    entry_name: []const u8,
    payload_name: []const u8,
    branch_name: []const u8,
    true_name: []const u8,
    false_name: []const u8,
) bool {
    for (function.blocks.items) |block| {
        if (std.mem.eql(u8, block.name, entry_name) or
            std.mem.eql(u8, block.name, payload_name) or
            std.mem.eql(u8, block.name, branch_name) or
            std.mem.eql(u8, block.name, true_name) or
            std.mem.eql(u8, block.name, false_name))
        {
            continue;
        }
        if (!blockIsUnreachable(block)) return false;
    }
    return true;
}

pub fn exhaustiveSwitchMergeBlock(function: ir.Function, switch_term: ir.SwitchTerminator) ?ir.BasicBlock {
    var target: ?[]const u8 = null;
    for (switch_term.cases.items) |case| {
        const block = function.blocks.items[blockIndex(function, case.target) orelse return null];
        const branch_target = singleBrTarget(block) orelse return null;
        if (target) |existing| {
            if (!std.mem.eql(u8, existing, branch_target)) return null;
        } else {
            target = branch_target;
        }
    }
    return function.blocks.items[blockIndex(function, target orelse return null) orelse return null];
}

pub fn errorTagSwitchUsesAllBlocks(
    function: ir.Function,
    payload_block: []const u8,
    switch_block: []const u8,
    merge_block: []const u8,
    switch_term: ir.SwitchTerminator,
) bool {
    for (function.blocks.items, 0..) |block, index| {
        if (index == 0 or
            std.mem.eql(u8, block.name, payload_block) or
            std.mem.eql(u8, block.name, switch_block) or
            std.mem.eql(u8, block.name, merge_block) or
            std.mem.eql(u8, block.name, switch_term.default_target))
        {
            continue;
        }
        var matched_case = false;
        for (switch_term.cases.items) |case| {
            if (std.mem.eql(u8, block.name, case.target)) {
                matched_case = true;
                break;
            }
        }
        if (matched_case) continue;
        if (blockIsUnreachable(block)) continue;
        return false;
    }
    return true;
}

fn firstNamedPhi(block: ir.BasicBlock) ?NamedPhi {
    if (block.instructions.items.len == 0) return null;
    const instruction = block.instructions.items[0];
    const name = instruction.result orelse return null;
    return .{
        .name = name,
        .phi = switch (instruction.kind) {
            .phi => |phi| phi,
            else => return null,
        },
    };
}

fn catchFallbackValue(function: ir.Function, value: ir.Value) ?ErrorUnionCatchFallbackValue {
    return switch (value) {
        .int => |int| .{ .int = i32Value(int) catch return null },
        .named => |name| {
            const reg = paramRegOrNull(function, name, .{ .int = 32 }) catch return null;
            return .{ .param = reg orelse return null };
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
    };
}

fn phiAddReturnImm(block: ir.BasicBlock, phi_name: []const u8) ?i32 {
    if (block.instructions.items.len != 2) return null;
    const add_name = block.instructions.items[1].result orelse return null;
    const add = switch (block.instructions.items[1].kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (!add.ty.eql(.{ .int = 32 }) or add.op != .add or !isNamed(add.lhs, phi_name)) return null;
    const imm = switch (add.rhs) {
        .int => |int| i32Value(int) catch return null,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return null, add_name)) return null;
    return imm;
}

fn catchValueMergeUsesOnlyExpectedBlocks(
    function: ir.Function,
    entry_name: []const u8,
    payload_name: []const u8,
    fallback_name: []const u8,
    merge_name: []const u8,
) bool {
    for (function.blocks.items) |block| {
        if (std.mem.eql(u8, block.name, entry_name) or
            std.mem.eql(u8, block.name, payload_name) or
            std.mem.eql(u8, block.name, fallback_name) or
            std.mem.eql(u8, block.name, merge_name))
        {
            continue;
        }
        if (!blockIsUnreachable(block)) return false;
    }
    return true;
}

const BranchThenErrorUnionTryReturn = struct {
    entry: ir.BasicBlock,
    try_block: ir.BasicBlock,
    direct_block: ir.BasicBlock,
    call_name: []const u8,
    call: ir.CallInst,
    success_block: ir.BasicBlock,
    err_block: ir.BasicBlock,
    success_add_imm: u8,
    try_is_then: bool,
    success_is_then: bool,
};

const BranchBothErrorUnionTryReturn = struct {
    entry: ir.BasicBlock,
    then_block: ir.BasicBlock,
    then_stage: BranchTryStage,
    else_block: ir.BasicBlock,
    else_stage: BranchTryStage,
};

const SwitchThenErrorUnionTryReturn = struct {
    entry: ir.BasicBlock,
    switch_term: ir.SwitchTerminator,
    direct_case: ErrorUnionSwitchPhiCase,
    try_block: ir.BasicBlock,
    call: ir.CallInst,
    success_block: ir.BasicBlock,
    err_block: ir.BasicBlock,
    success_add_imm: u8,
    success_is_then: bool,
};

const SwitchBothErrorUnionTryReturn = struct {
    entry: ir.BasicBlock,
    switch_term: ir.SwitchTerminator,
    case_block: ir.BasicBlock,
    case_stage: BranchTryStage,
    case_success_add_imm: u8,
    default_block: ir.BasicBlock,
    default_stage: BranchTryStage,
    default_success_add_imm: u8,
};

pub fn lowerGenericCfgBranchBothErrorUnionTryReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = branchBothErrorUnionTryReturn(function) orelse return false;
    const frame_bytes: u8 = 8;
    const epilogue_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_branch_both_try_{}_generic_cfg_select_end",
        .{machine.instructions.items.len},
    );

    const entry_condbr = switch (plan.entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };

    try appendStackFrame(allocator, machine, frame_bytes);
    try emitGenericCfgTerminalConditionTrueBranch(allocator, machine, function, plan.entry, plan.entry, entry_condbr.cond, plan.then_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, plan.else_block.name);
    try emitErrorUnionTryStageToEpilogue(allocator, machine, function, plan.else_block, plan.else_stage, plan.else_stage.success_add_imm, epilogue_label);

    try appendGenericCfgBlockLabel(allocator, machine, plan.then_block.name);
    try emitErrorUnionTryStageToEpilogue(allocator, machine, function, plan.then_block, plan.then_stage, plan.then_stage.success_add_imm, epilogue_label);

    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub fn lowerGenericCfgBranchThenErrorUnionTryReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = branchThenErrorUnionTryReturn(function) orelse return false;
    const frame_bytes: u8 = 8;
    const epilogue_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_branch_then_try_{}_generic_cfg_select_end",
        .{machine.instructions.items.len},
    );

    const entry_condbr = switch (plan.entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };
    try emitGenericCfgTerminalConditionTrueBranch(allocator, machine, function, plan.entry, plan.entry, entry_condbr.cond, if (plan.try_is_then) plan.try_block.name else plan.direct_block.name);
    if (plan.try_is_then) {
        try emitGenericCfgTerminalReturnBlock(allocator, machine, function, plan.entry, plan.direct_block);
        try appendGenericCfgBlockLabel(allocator, machine, plan.try_block.name);
    }

    try appendStackFrame(allocator, machine, frame_bytes);
    const stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, plan.try_block, plan.call);
    if (stack_arg_count != 0) return error.UnsupportedLiveAcrossCall;
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = plan.call.callee, .ret_ty = plan.call.ret_ty } });
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, if (plan.success_is_then) .je else .jne, plan.success_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, plan.err_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, plan.success_block.name);
    try emitPayloadAddImmWrapFromCallSlot(allocator, machine, plan.success_add_imm, epilogue_label);

    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);

    if (!plan.try_is_then) {
        try appendGenericCfgBlockLabel(allocator, machine, plan.direct_block.name);
        try emitGenericCfgTerminalReturnBlock(allocator, machine, function, plan.entry, plan.direct_block);
    }
    return true;
}

fn emitErrorUnionTryStageToEpilogue(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    try_block: ir.BasicBlock,
    stage: BranchTryStage,
    success_add_imm: u8,
    epilogue_label: []const u8,
) !void {
    const stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, try_block, stage.call);
    if (stack_arg_count != 0) return error.UnsupportedLiveAcrossCall;
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = stage.call.callee, .ret_ty = stage.call.ret_ty } });
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, if (stage.success_is_then) .je else .jne, stage.success_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, stage.err_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, stage.success_block.name);
    try emitPayloadAddImmWrapFromCallSlot(allocator, machine, success_add_imm, epilogue_label);
}

pub fn lowerGenericCfgSwitchThenErrorUnionTryReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = switchThenErrorUnionTryReturn(function) orelse return false;
    const frame_bytes: u8 = 8;
    const epilogue_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_switch_then_try_{}_generic_cfg_select_end",
        .{machine.instructions.items.len},
    );

    try appendStackFrame(allocator, machine, frame_bytes);
    try emitSwitchThenTryCondition(allocator, machine, function, plan.entry, plan.switch_term);
    try appendGenericCfgConditionalBranch(allocator, machine, .je, plan.direct_case.block.name);
    try machine.instructions.append(allocator, .{ .jmp = plan.try_block.name });

    try appendGenericCfgBlockLabel(allocator, machine, plan.direct_case.block.name);
    try emitGenericCfgTerminalI64ValueIntoRax(allocator, machine, function, plan.entry, plan.direct_case.block, plan.direct_case.incoming);
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, plan.try_block.name);
    const stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, plan.try_block, plan.call);
    if (stack_arg_count != 0) return error.UnsupportedLiveAcrossCall;
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = plan.call.callee, .ret_ty = plan.call.ret_ty } });
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, if (plan.success_is_then) .je else .jne, plan.success_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, plan.err_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, plan.success_block.name);
    try emitPayloadAddImmWrapFromCallSlot(allocator, machine, plan.success_add_imm, epilogue_label);

    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub fn lowerGenericCfgSwitchBothErrorUnionTryReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = switchBothErrorUnionTryReturn(function) orelse return false;
    const frame_bytes: u8 = 8;
    const epilogue_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_switch_both_try_{}_generic_cfg_select_end",
        .{machine.instructions.items.len},
    );

    try appendStackFrame(allocator, machine, frame_bytes);
    try emitSwitchThenTryCondition(allocator, machine, function, plan.entry, plan.switch_term);
    try appendGenericCfgConditionalBranch(allocator, machine, .je, plan.case_block.name);
    try machine.instructions.append(allocator, .{ .jmp = plan.default_block.name });

    try appendGenericCfgBlockLabel(allocator, machine, plan.default_block.name);
    try emitErrorUnionTryStageToEpilogue(allocator, machine, function, plan.default_block, plan.default_stage, plan.default_success_add_imm, epilogue_label);

    try appendGenericCfgBlockLabel(allocator, machine, plan.case_block.name);
    try emitErrorUnionTryStageToEpilogue(allocator, machine, function, plan.case_block, plan.case_stage, plan.case_success_add_imm, epilogue_label);

    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

fn branchBothErrorUnionTryReturn(function: ir.Function) ?BranchBothErrorUnionTryReturn {
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.blocks.items.len != 7) return null;
    const entry = function.blocks.items[0];
    const entry_condbr = switch (entry.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!entry_condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const then_block = function.blocks.items[blockIndex(function, entry_condbr.then_target) orelse return null];
    const else_block = function.blocks.items[blockIndex(function, entry_condbr.else_target) orelse return null];
    const then_stage = branchTryStage(function, then_block) orelse return null;
    const else_stage = branchTryStage(function, else_block) orelse return null;
    if (!branchBothTryUsesAllBlocks(
        function,
        then_block.name,
        then_stage.success_block.name,
        then_stage.err_block.name,
        else_block.name,
        else_stage.success_block.name,
        else_stage.err_block.name,
    )) return null;

    return .{
        .entry = entry,
        .then_block = then_block,
        .then_stage = then_stage,
        .else_block = else_block,
        .else_stage = else_stage,
    };
}

fn switchBothErrorUnionTryReturn(function: ir.Function) ?SwitchBothErrorUnionTryReturn {
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.blocks.items.len != 8) return null;
    const entry = function.blocks.items[0];
    const switch_term = blockSwitchTerminator(entry) orelse return null;
    if (!switch_term.cond_ty.eql(.{ .int = 32 }) or switch_term.cases.items.len != 1) return null;
    const case = switch_term.cases.items[0];
    if (!case.value_ty.eql(.{ .int = 32 }) or !isInt(case.value, 0)) return null;
    if (switchMaskParamConst(function, entry, switch_term.cond) != 1) return null;

    const case_block = function.blocks.items[blockIndex(function, case.target) orelse return null];
    const default_block = function.blocks.items[blockIndex(function, switch_term.default_target) orelse return null];
    const case_stage = switchArmTryStage(function, case_block) orelse return null;
    const default_stage = switchArmTryStage(function, default_block) orelse return null;
    const merge_block = commonSwitchBothTryMergeBlock(function, case_stage.success_block, default_stage.success_block) orelse return null;
    const phi = firstPhiReturn(function, merge_block) orelse return null;
    if (!phi.ty.eql(.{ .int = 64 }) or phi.incoming.items.len != 2) return null;

    const case_incoming = phiIncomingForBlock(phi, case_stage.success_block.name) orelse return null;
    const default_incoming = phiIncomingForBlock(phi, default_stage.success_block.name) orelse return null;
    const case_success_add_imm = payloadAddWrapValue(case_stage.success_block, case_stage.success_block, case_incoming, case_stage.call_name) orelse return null;
    const default_success_add_imm = payloadAddWrapValue(default_stage.success_block, default_stage.success_block, default_incoming, default_stage.call_name) orelse return null;
    if (!switchBothTryUsesAllBlocks(
        function,
        case_block.name,
        case_stage.success_block.name,
        case_stage.err_block.name,
        default_block.name,
        default_stage.success_block.name,
        default_stage.err_block.name,
        merge_block.name,
    )) return null;

    return .{
        .entry = entry,
        .switch_term = switch_term,
        .case_block = case_block,
        .case_stage = case_stage,
        .case_success_add_imm = case_success_add_imm,
        .default_block = default_block,
        .default_stage = default_stage,
        .default_success_add_imm = default_success_add_imm,
    };
}

fn branchThenErrorUnionTryReturn(function: ir.Function) ?BranchThenErrorUnionTryReturn {
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.blocks.items.len != 5) return null;
    const entry = function.blocks.items[0];
    const entry_condbr = switch (entry.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!entry_condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const then_block = function.blocks.items[blockIndex(function, entry_condbr.then_target) orelse return null];
    const else_block = function.blocks.items[blockIndex(function, entry_condbr.else_target) orelse return null];
    const then_try = branchTryStage(function, then_block);
    const else_try = branchTryStage(function, else_block);
    if ((then_try != null) == (else_try != null)) return null;
    const try_stage = then_try orelse else_try.?;
    const try_block = if (then_try != null) then_block else else_block;
    const direct_block = if (then_try != null) else_block else then_block;
    if (!genericCfgSupportsTerminalReturnBlock(function, entry, direct_block)) return null;
    if (!branchThenTryUsesAllBlocks(function, try_block.name, direct_block.name, try_stage.success_block.name, try_stage.err_block.name)) return null;

    return .{
        .entry = entry,
        .try_block = try_block,
        .direct_block = direct_block,
        .call_name = try_stage.call_name,
        .call = try_stage.call,
        .success_block = try_stage.success_block,
        .err_block = try_stage.err_block,
        .success_add_imm = try_stage.success_add_imm,
        .try_is_then = then_try != null,
        .success_is_then = try_stage.success_is_then,
    };
}

fn switchThenErrorUnionTryReturn(function: ir.Function) ?SwitchThenErrorUnionTryReturn {
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.blocks.items.len != 6) return null;
    const entry = function.blocks.items[0];
    const switch_term = blockSwitchTerminator(entry) orelse return null;
    if (!switch_term.cond_ty.eql(.{ .int = 32 }) or switch_term.cases.items.len != 1) return null;
    const case = switch_term.cases.items[0];
    if (!case.value_ty.eql(.{ .int = 32 }) or !isInt(case.value, 0)) return null;
    if (switchMaskParamConst(function, entry, switch_term.cond) != 1) return null;

    const direct_block = function.blocks.items[blockIndex(function, case.target) orelse return null];
    const try_block = function.blocks.items[blockIndex(function, switch_term.default_target) orelse return null];
    const try_stage = switchArmTryStage(function, try_block) orelse return null;
    const merge_block = commonSwitchTryMergeBlock(function, direct_block, try_stage.success_block) orelse return null;
    const phi = firstPhiReturn(function, merge_block) orelse return null;
    if (!phi.ty.eql(.{ .int = 64 }) or phi.incoming.items.len != 2) return null;

    const direct_incoming = phiIncomingForBlock(phi, direct_block.name) orelse return null;
    if (!blockBranchesTo(direct_block, merge_block.name)) return null;
    if (!blockBranchesTo(try_stage.success_block, merge_block.name)) return null;
    const success_incoming = phiIncomingForBlock(phi, try_stage.success_block.name) orelse return null;
    const success_add_imm = payloadAddWrapValue(try_stage.success_block, try_stage.success_block, success_incoming, try_stage.call_name) orelse return null;
    if (!switchThenTryUsesAllBlocks(function, direct_block.name, try_block.name, try_stage.success_block.name, try_stage.err_block.name, merge_block.name)) return null;

    return .{
        .entry = entry,
        .switch_term = switch_term,
        .direct_case = .{ .value = 0, .block = direct_block, .incoming = direct_incoming },
        .try_block = try_block,
        .call = try_stage.call,
        .success_block = try_stage.success_block,
        .err_block = try_stage.err_block,
        .success_add_imm = success_add_imm,
        .success_is_then = try_stage.success_is_then,
    };
}

fn switchArmTryStage(function: ir.Function, block: ir.BasicBlock) ?BranchTryStage {
    const condbr = switch (block.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const call_name = errorUnionTryGuardCallResult(block, condbr.cond) orelse return null;
    const call_instruction = findInstruction(block, call_name) orelse return null;
    const call = switch (call_instruction.kind) {
        .call => |call| call,
        else => return null,
    };
    if (!supportsDirectI64Call(call)) return null;

    const then_block = function.blocks.items[blockIndex(function, condbr.then_target) orelse return null];
    const else_block = function.blocks.items[blockIndex(function, condbr.else_target) orelse return null];
    const then_is_success = singleBrTarget(then_block) != null;
    const else_is_success = singleBrTarget(else_block) != null;
    if (then_is_success == else_is_success) return null;
    const success_block = if (then_is_success) then_block else else_block;
    const err_block = if (then_is_success) else_block else then_block;
    if (!blockReturnsNamedValue(err_block, call_name, .{ .int = 64 })) return null;
    return .{
        .call_name = call_name,
        .call = call,
        .success_block = success_block,
        .err_block = err_block,
        .success_add_imm = 0,
        .success_is_then = then_is_success,
    };
}

fn switchMaskParamConst(function: ir.Function, block: ir.BasicBlock, value: ir.Value) ?i32 {
    const name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const instruction = findInstruction(block, name) orelse return null;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (!binary.ty.eql(.{ .int = 32 }) or binary.op != .@"and") return null;
    const lhs_name = switch (binary.lhs) {
        .named => |lhs_name| lhs_name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if ((paramRegOrNull(function, lhs_name, .{ .int = 32 }) catch null) == null) return null;
    return switch (binary.rhs) {
        .int => |int| i32Value(int) catch null,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
    };
}

fn emitSwitchThenTryCondition(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    switch_term: ir.SwitchTerminator,
) !void {
    const cond_name = switch (switch_term.cond) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    const instruction = findInstruction(block, cond_name) orelse return error.UnsupportedCodegenValue;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!binary.ty.eql(.{ .int = 32 }) or binary.op != .@"and") return error.UnsupportedCodegenInstruction;
    const lhs_name = switch (binary.lhs) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    const reg = try paramReg(function, lhs_name, .{ .int = 32 });
    const rhs = switch (binary.rhs) {
        .int => |int| try i32Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
    if (rhs != 0) try machine.instructions.append(allocator, .{ .and_eax_imm32 = rhs });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 0 });
}

fn commonSwitchTryMergeBlock(function: ir.Function, direct_block: ir.BasicBlock, success_block: ir.BasicBlock) ?ir.BasicBlock {
    const direct_target = singleBrTarget(direct_block) orelse return null;
    const success_target = singleBrTarget(success_block) orelse return null;
    if (!std.mem.eql(u8, direct_target, success_target)) return null;
    return function.blocks.items[blockIndex(function, direct_target) orelse return null];
}

fn commonSwitchBothTryMergeBlock(function: ir.Function, case_success_block: ir.BasicBlock, default_success_block: ir.BasicBlock) ?ir.BasicBlock {
    const case_target = singleBrTarget(case_success_block) orelse return null;
    const default_target = singleBrTarget(default_success_block) orelse return null;
    if (!std.mem.eql(u8, case_target, default_target)) return null;
    return function.blocks.items[blockIndex(function, case_target) orelse return null];
}

fn switchThenTryUsesAllBlocks(
    function: ir.Function,
    direct_block: []const u8,
    try_block: []const u8,
    success_block: []const u8,
    err_block: []const u8,
    merge_block: []const u8,
) bool {
    for (function.blocks.items, 0..) |block, index| {
        if (index == 0 or
            std.mem.eql(u8, block.name, direct_block) or
            std.mem.eql(u8, block.name, try_block) or
            std.mem.eql(u8, block.name, success_block) or
            std.mem.eql(u8, block.name, err_block) or
            std.mem.eql(u8, block.name, merge_block))
        {
            continue;
        }
        return false;
    }
    return true;
}

const BranchTryStage = struct {
    call_name: []const u8,
    call: ir.CallInst,
    success_block: ir.BasicBlock,
    err_block: ir.BasicBlock,
    success_add_imm: u8,
    success_is_then: bool,
};

fn branchTryStage(function: ir.Function, block: ir.BasicBlock) ?BranchTryStage {
    const condbr = switch (block.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const call_name = errorUnionTryGuardCallResult(block, condbr.cond) orelse return null;
    const call_instruction = findInstruction(block, call_name) orelse return null;
    const call = switch (call_instruction.kind) {
        .call => |call| call,
        else => return null,
    };
    if (!supportsDirectI64Call(call)) return null;

    const then_block = function.blocks.items[blockIndex(function, condbr.then_target) orelse return null];
    const else_block = function.blocks.items[blockIndex(function, condbr.else_target) orelse return null];
    const then_success = successReturnPayloadAdd(then_block, call_name);
    const else_success = successReturnPayloadAdd(else_block, call_name);
    if ((then_success != null) == (else_success != null)) return null;
    const success_block = if (then_success != null) then_block else else_block;
    const err_block = if (then_success != null) else_block else then_block;
    if (!blockReturnsNamedValue(err_block, call_name, .{ .int = 64 })) return null;
    return .{
        .call_name = call_name,
        .call = call,
        .success_block = success_block,
        .err_block = err_block,
        .success_add_imm = then_success orelse else_success.?,
        .success_is_then = then_success != null,
    };
}

fn branchThenTryUsesAllBlocks(
    function: ir.Function,
    try_block: []const u8,
    direct_block: []const u8,
    success_block: []const u8,
    err_block: []const u8,
) bool {
    for (function.blocks.items, 0..) |block, index| {
        if (index == 0 or
            std.mem.eql(u8, block.name, try_block) or
            std.mem.eql(u8, block.name, direct_block) or
            std.mem.eql(u8, block.name, success_block) or
            std.mem.eql(u8, block.name, err_block))
        {
            continue;
        }
        return false;
    }
    return true;
}

fn branchBothTryUsesAllBlocks(
    function: ir.Function,
    then_block: []const u8,
    then_success: []const u8,
    then_err: []const u8,
    else_block: []const u8,
    else_success: []const u8,
    else_err: []const u8,
) bool {
    for (function.blocks.items, 0..) |block, index| {
        if (index == 0 or
            std.mem.eql(u8, block.name, then_block) or
            std.mem.eql(u8, block.name, then_success) or
            std.mem.eql(u8, block.name, then_err) or
            std.mem.eql(u8, block.name, else_block) or
            std.mem.eql(u8, block.name, else_success) or
            std.mem.eql(u8, block.name, else_err))
        {
            continue;
        }
        return false;
    }
    return true;
}

fn switchBothTryUsesAllBlocks(
    function: ir.Function,
    case_block: []const u8,
    case_success: []const u8,
    case_err: []const u8,
    default_block: []const u8,
    default_success: []const u8,
    default_err: []const u8,
    merge_block: []const u8,
) bool {
    for (function.blocks.items, 0..) |block, index| {
        if (index == 0 or
            std.mem.eql(u8, block.name, case_block) or
            std.mem.eql(u8, block.name, case_success) or
            std.mem.eql(u8, block.name, case_err) or
            std.mem.eql(u8, block.name, default_block) or
            std.mem.eql(u8, block.name, default_success) or
            std.mem.eql(u8, block.name, default_err) or
            std.mem.eql(u8, block.name, merge_block))
        {
            continue;
        }
        return false;
    }
    return true;
}

fn emitPayloadAddImmWrapFromCallSlot(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    add_imm: u8,
    epilogue_label: []const u8,
) !void {
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 16 });
    if (add_imm != 0) try machine.instructions.append(allocator, .{ .add_rax_imm8 = add_imm });
    try machine.instructions.append(allocator, .{ .shl_rax_imm6 = 16 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });
}
