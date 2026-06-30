const shared = @import("core_shared.zig");
const core_cfg_emit = @import("core_cfg_emit.zig");
const core_loop_rows = @import("core_loop_rows.zig");
const core_value_support = @import("core_value_support.zig");
const core_value_emit = @import("core_value_emit.zig");
const core_memory_lowering = @import("core_memory_lowering.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");
const cabi_call_lowering = @import("cabi_call_lowering.zig");

const std = shared.std;
const ir = shared.ir;
const MachineFunction = shared.MachineFunction;
const MachineBinaryOp = shared.MachineBinaryOp;
const ArgReg = shared.ArgReg;

const appendAlignedDirectCall = shared.appendAlignedDirectCall;
const appendDirectCallWithStackArgs = shared.appendDirectCallWithStackArgs;
const appendStackFrame = shared.appendStackFrame;
const appendStackFrameEnd = shared.appendStackFrameEnd;
const appendGenericCfgBlockLabel = core_cfg_emit.appendGenericCfgBlockLabel;
const appendGenericCfgConditionalBranch = core_cfg_emit.appendGenericCfgConditionalBranch;
const appendGenericCfgI32Zero = core_cfg_emit.appendGenericCfgI32Zero;
const appendGenericCfgAccumulatorAdd = core_cfg_emit.appendGenericCfgAccumulatorAdd;
const appendGenericCfgAccumulatorIncrement = core_cfg_emit.appendGenericCfgAccumulatorIncrement;
const appendGenericCfgCompareParamZero = core_cfg_emit.appendGenericCfgCompareParamZero;
const appendGenericCfgCompareLocalImm = core_cfg_emit.appendGenericCfgCompareLocalImm;
const appendGenericCfgCompareLocalParam = core_cfg_emit.appendGenericCfgCompareLocalParam;
const appendGenericCfgReturn = core_cfg_emit.appendGenericCfgReturn;
const appendPanicCall = shared.appendPanicCall;
const appendMoveImmToArgReg = shared.appendMoveImmToArgReg;
const callIsFastcc = shared.callIsFastcc;
const emitGenericCfgLoadI32IntoEax = core_value_emit.emitGenericCfgLoadI32IntoEax;
const emitGenericCfgIcmpCondition = cabi_call_lowering.emitGenericCfgIcmpCondition;
const findInstruction = cabi_call_lowering.findInstruction;
const globalSymbolName = shared.globalSymbolName;
const globalSymbolNameFromValue = shared.globalSymbolNameFromValue;
const i32Value = shared.i32Value;
const i64Value = shared.i64Value;
const isCalleeName = shared.isCalleeName;
const isInt = shared.isInt;
const isNamed = shared.isNamed;
const machineBinaryOp = cabi_call_lowering.machineBinaryOp;
const appendSysVScalarCallArgsWithBlock = cabi_call_lowering.appendSysVScalarCallArgsWithBlock;
const phiHasIncoming = cabi_call_lowering.phiHasIncoming;
const phiHasIncomingInt = cabi_call_lowering.phiHasIncomingInt;
const paramReg = cabi_abi_helpers.paramReg;
const paramRegOrNull = cabi_abi_helpers.paramRegOrNull;
const paramValueReg = cabi_abi_helpers.paramValueReg;
const blockIndex = cabi_abi_helpers.blockIndex;
const validateDefaultCallConv = shared.validateDefaultCallConv;

pub const GenericCfgLoopSumPlan = core_loop_rows.GenericCfgLoopSumPlan;
const genericCfgPointerSlotParam = core_memory_lowering.genericCfgPointerSlotParam;
const genericCfgLoadPtrFromSlot = core_memory_lowering.genericCfgLoadPtrFromSlot;
const genericCfgSupportsBranchIcmp = core_value_support.genericCfgSupportsBranchIcmp;
const genericCfgSupportsPointerNullIcmp = core_value_support.genericCfgSupportsPointerNullIcmp;
const genericCfgSupportsI32Value = core_value_support.genericCfgSupportsI32Value;

pub fn lowerGenericCfgLoopTryReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = loopTryReturn(function) orelse return false;
    const loop_label = "generic_cfg_loop_try_loop";
    const tag_one_label = "generic_cfg_loop_try_tag_one";
    const call_label = "generic_cfg_loop_try_call";
    const error_label = "generic_cfg_loop_try_error";
    const exit_label = "generic_cfg_loop_try_exit";
    const exit_else_label = "generic_cfg_loop_try_exit_else";
    const exit_case1_label = "generic_cfg_loop_try_exit_case1";
    const exit_default_label = "generic_cfg_loop_try_exit_default";
    const epilogue_label = "generic_cfg_loop_try_generic_cfg_select_end";
    const frame_bytes: u8 = if (plan.post_branch != null) 40 else 24;

    try appendStackFrame(allocator, machine, frame_bytes);
    try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{ .frame_index = .slot2, .reg = .rdi } });
    try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{ .frame_index = .slot3, .reg = .rsi } });
    if (plan.post_branch != null) {
        try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{ .frame_index = .slot6, .reg = .rdx } });
    }
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .{ .spill_eax_rsp = .slot0 });
    try machine.instructions.append(allocator, .{ .spill_eax_rsp = .slot1 });

    try appendGenericCfgBlockLabel(allocator, machine, loop_label);
    try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{ .reg = .rcx, .frame_index = .slot1 } });
    try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{ .reg = .r9, .frame_index = .slot2 } });
    try machine.instructions.append(allocator, .{ .cmp_ecx_arg32 = .r9 });
    try appendGenericCfgConditionalBranch(allocator, machine, .jle, exit_label);

    try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{ .reg = .r8, .frame_index = .slot3 } });
    try machine.instructions.append(allocator, .{ .cmp_ecx_arg32 = .r8 });
    try appendGenericCfgConditionalBranch(allocator, machine, .je, tag_one_label);
    try machine.instructions.append(allocator, .{ .mov_imm_rdi = 0 });
    try machine.instructions.append(allocator, .{ .jmp = call_label });
    try appendGenericCfgBlockLabel(allocator, machine, tag_one_label);
    try machine.instructions.append(allocator, .{ .mov_imm_rdi = 1 });
    try appendGenericCfgBlockLabel(allocator, machine, call_label);
    try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rsi, .src = .rcx } });
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = plan.call.callee, .ret_ty = plan.call.ret_ty } });
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot4 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, .jne, error_label);

    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot4 });
    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 16 });
    try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{ .reg = .rcx, .frame_index = .slot0 } });
    try machine.instructions.append(allocator, .add_ecx_eax);
    try machine.instructions.append(allocator, .{ .spill_eax_rsp = .slot0 });
    try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{ .reg = .rcx, .frame_index = .slot1 } });
    try machine.instructions.append(allocator, .inc_rcx);
    try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{ .frame_index = .slot1, .reg = .rcx } });
    try machine.instructions.append(allocator, .{ .jmp = loop_label });

    try appendGenericCfgBlockLabel(allocator, machine, error_label);
    try machine.instructions.append(allocator, .{ .mov_imm_eax = plan.error_return });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, exit_label);
    if (plan.post_branch) |post_branch| {
        try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{ .reg = .rcx, .frame_index = .slot6 } });
        try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{ .reg = .r9, .frame_index = .slot0 } });
        try machine.instructions.append(allocator, .{ .cmp_ecx_arg32 = .r9 });
        try appendGenericCfgConditionalBranch(allocator, machine, .jle, exit_else_label);
        try machine.instructions.append(allocator, .{ .reload_rsp_eax = .slot0 });
        if (post_branch.true_addend != 0) try machine.instructions.append(allocator, .{ .add_eax_imm32 = post_branch.true_addend });
        try machine.instructions.append(allocator, .{ .jmp = epilogue_label });
        try appendGenericCfgBlockLabel(allocator, machine, exit_else_label);
        try machine.instructions.append(allocator, .{ .reload_rsp_eax = .slot0 });
        if (post_branch.false_addend != 0) try machine.instructions.append(allocator, .{ .add_eax_imm32 = post_branch.false_addend });
    } else if (plan.post_switch) |post_switch| {
        try machine.instructions.append(allocator, .{ .reload_rsp_eax = .slot0 });
        try machine.instructions.append(allocator, .{ .and_eax_imm32 = post_switch.mask });
        try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 0 });
        try machine.instructions.append(allocator, .{ .jne = exit_case1_label });
        try machine.instructions.append(allocator, .{ .reload_rsp_eax = .slot0 });
        if (post_switch.case0_addend != 0) try machine.instructions.append(allocator, .{ .add_eax_imm32 = post_switch.case0_addend });
        try machine.instructions.append(allocator, .{ .jmp = epilogue_label });
        try appendGenericCfgBlockLabel(allocator, machine, exit_case1_label);
        try machine.instructions.append(allocator, .{ .reload_rsp_eax = .slot0 });
        try machine.instructions.append(allocator, .{ .and_eax_imm32 = post_switch.mask });
        try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 1 });
        try machine.instructions.append(allocator, .{ .jne = exit_default_label });
        try machine.instructions.append(allocator, .{ .reload_rsp_eax = .slot0 });
        if (post_switch.case1_addend != 0) try machine.instructions.append(allocator, .{ .add_eax_imm32 = post_switch.case1_addend });
        try machine.instructions.append(allocator, .{ .jmp = epilogue_label });
        try appendGenericCfgBlockLabel(allocator, machine, exit_default_label);
        try machine.instructions.append(allocator, .{ .reload_rsp_eax = .slot0 });
        if (post_switch.default_addend != 0) try machine.instructions.append(allocator, .{ .add_eax_imm32 = post_switch.default_addend });
    } else {
        try machine.instructions.append(allocator, .{ .reload_rsp_eax = .slot0 });
    }
    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

const LoopTryReturnPlan = struct {
    call: ir.CallInst,
    error_return: i32,
    post_branch: ?LoopTryPostBranchPlan = null,
    post_switch: ?LoopTryPostSwitchPlan = null,
};

const LoopTryPostBranchPlan = struct {
    true_addend: i32,
    false_addend: i32,
};

const LoopTryPostSwitchPlan = struct {
    mask: i32,
    case0_addend: i32,
    case1_addend: i32,
    default_addend: i32,
};

fn loopTryReturn(function: ir.Function) ?LoopTryReturnPlan {
    const post_kind: enum { none, branch, @"switch" } = switch (function.params.items.len) {
        2 => switch (function.blocks.items.len) {
            6 => .none,
            9 => .@"switch",
            else => return null,
        },
        3 => .branch,
        else => return null,
    };
    const expected_block_count: usize = switch (post_kind) {
        .none => 6,
        .branch => 8,
        .@"switch" => 9,
    };
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.blocks.items.len != expected_block_count) return null;
    if (!function.params.items[0].ty.eql(.{ .int = 32 }) or !function.params.items[1].ty.eql(.{ .int = 32 })) return null;
    if (post_kind == .branch and !function.params.items[2].ty.eql(.{ .int = 32 })) return null;
    const entry = function.blocks.items[0];
    const loop = function.blocks.items[1];
    const body = function.blocks.items[2];
    const success = function.blocks.items[3];
    const err_block = function.blocks.items[4];
    const exit = function.blocks.items[5];
    const exit_then = if (post_kind == .branch) function.blocks.items[6] else undefined;
    const exit_else = if (post_kind == .branch) function.blocks.items[7] else undefined;
    const exit_case0 = if (post_kind == .@"switch") function.blocks.items[6] else undefined;
    const exit_case1 = if (post_kind == .@"switch") function.blocks.items[7] else undefined;
    const exit_default = if (post_kind == .@"switch") function.blocks.items[8] else undefined;
    if (!std.mem.eql(u8, entry.name, "entry") or
        !std.mem.eql(u8, loop.name, "loop") or
        !std.mem.eql(u8, body.name, "body") or
        !std.mem.eql(u8, success.name, "success") or
        !std.mem.eql(u8, err_block.name, "error") or
        !std.mem.eql(u8, exit.name, "exit")) return null;
    if (post_kind == .branch and (!std.mem.eql(u8, exit_then.name, "exit_then") or !std.mem.eql(u8, exit_else.name, "exit_else"))) return null;
    if (post_kind == .@"switch" and (!std.mem.eql(u8, exit_case0.name, "exit_case0") or
        !std.mem.eql(u8, exit_case1.name, "exit_case1") or
        !std.mem.eql(u8, exit_default.name, "exit_default"))) return null;
    switch (entry.terminator orelse return null) {
        .br => |br| if (!std.mem.eql(u8, br.target, loop.name)) return null,
        else => return null,
    }
    if (loop.instructions.items.len != 3) return null;
    const index_name = loop.instructions.items[0].result orelse return null;
    const total_name = loop.instructions.items[1].result orelse return null;
    const cond_name = loop.instructions.items[2].result orelse return null;
    const index_phi = switch (loop.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return null,
    };
    const total_phi = switch (loop.instructions.items[1].kind) {
        .phi => |phi| phi,
        else => return null,
    };
    if (!index_phi.ty.eql(.{ .int = 32 }) or !total_phi.ty.eql(.{ .int = 32 })) return null;
    if (!phiHasIncomingInt(index_phi, 0, entry.name) or !phiHasIncoming(index_phi, "index_next", success.name)) return null;
    if (!phiHasIncomingInt(total_phi, 0, entry.name) or !phiHasIncoming(total_phi, "total_next", success.name)) return null;
    const loop_cmp = switch (loop.instructions.items[2].kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (loop_cmp.predicate != .slt or
        !loop_cmp.operand_ty.eql(.{ .int = 32 }) or
        !isNamed(loop_cmp.lhs, index_name) or
        !isNamed(loop_cmp.rhs, function.params.items[0].name)) return null;
    const loop_branch = switch (loop.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!isNamed(loop_branch.cond, cond_name) or
        !std.mem.eql(u8, loop_branch.then_target, body.name) or
        !std.mem.eql(u8, loop_branch.else_target, exit.name)) return null;

    if (body.instructions.items.len != 5) return null;
    const cmp_name = body.instructions.items[0].result orelse return null;
    const tag_name = body.instructions.items[1].result orelse return null;
    const call_name = body.instructions.items[2].result orelse return null;
    const tag_mask_name = body.instructions.items[3].result orelse return null;
    const success_cond_name = body.instructions.items[4].result orelse return null;
    const fail_cmp = switch (body.instructions.items[0].kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (fail_cmp.predicate != .eq or
        !fail_cmp.operand_ty.eql(.{ .int = 32 }) or
        !isNamed(fail_cmp.lhs, index_name) or
        !isNamed(fail_cmp.rhs, function.params.items[1].name)) return null;
    const tag = switch (body.instructions.items[1].kind) {
        .select => |select| select,
        else => return null,
    };
    if (!isNamed(tag.cond, cmp_name) or !tag.ty.eql(.{ .int = 32 }) or !isInt(tag.true_value, 1) or !isInt(tag.false_value, 0)) return null;
    const call = switch (body.instructions.items[2].kind) {
        .call => |call| call,
        else => return null,
    };
    if (!call.ret_ty.eql(.{ .int = 64 }) or call.args.items.len != 2 or call.callee_value != null) return null;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !isNamed(call.args.items[0].value, tag_name)) return null;
    if (!call.args.items[1].ty.eql(.{ .int = 32 }) or !isNamed(call.args.items[1].value, index_name)) return null;
    const tag_mask = switch (body.instructions.items[3].kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (tag_mask.op != .@"and" or !tag_mask.ty.eql(.{ .int = 64 }) or !isNamed(tag_mask.lhs, call_name) or !isInt(tag_mask.rhs, 65535)) return null;
    const success_cmp = switch (body.instructions.items[4].kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (success_cmp.predicate != .eq or !success_cmp.operand_ty.eql(.{ .int = 64 }) or !isNamed(success_cmp.lhs, tag_mask_name) or !isInt(success_cmp.rhs, 0)) return null;
    const body_branch = switch (body.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!isNamed(body_branch.cond, success_cond_name) or
        !std.mem.eql(u8, body_branch.then_target, success.name) or
        !std.mem.eql(u8, body_branch.else_target, err_block.name)) return null;

    if (success.instructions.items.len != 4) return null;
    const payload64_name = success.instructions.items[0].result orelse return null;
    const payload_name = success.instructions.items[1].result orelse return null;
    const total_next_name = success.instructions.items[2].result orelse return null;
    const index_next_name = success.instructions.items[3].result orelse return null;
    const payload64 = switch (success.instructions.items[0].kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (payload64.op != .lshr or !payload64.ty.eql(.{ .int = 64 }) or !isNamed(payload64.lhs, call_name) or !isInt(payload64.rhs, 16)) return null;
    const payload = switch (success.instructions.items[1].kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (payload.op != .trunc or !payload.from_ty.eql(.{ .int = 64 }) or !payload.to_ty.eql(.{ .int = 32 }) or !isNamed(payload.value, payload64_name)) return null;
    const total_next = switch (success.instructions.items[2].kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (!std.mem.eql(u8, total_next_name, "total_next") or total_next.op != .add or !total_next.ty.eql(.{ .int = 32 }) or !isNamed(total_next.lhs, total_name) or !isNamed(total_next.rhs, payload_name)) return null;
    const index_next = switch (success.instructions.items[3].kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (!std.mem.eql(u8, index_next_name, "index_next") or index_next.op != .add or !index_next.ty.eql(.{ .int = 32 }) or !isNamed(index_next.lhs, index_name) or !isInt(index_next.rhs, 1)) return null;
    switch (success.terminator orelse return null) {
        .br => |br| if (!std.mem.eql(u8, br.target, loop.name)) return null,
        else => return null,
    }
    const error_ret = switch (err_block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!error_ret.ty.eql(.{ .int = 32 })) return null;
    const error_return = switch (error_ret.value orelse return null) {
        .int => |int| i32Value(int) catch return null,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const post_branch: ?LoopTryPostBranchPlan = if (post_kind == .branch)
        loopTryPostBranch(exit, exit_then, exit_else, total_name, function.params.items[2].name) orelse return null
    else
        null;
    const post_switch: ?LoopTryPostSwitchPlan = if (post_kind == .@"switch")
        loopTryPostSwitch(exit, exit_case0, exit_case1, exit_default, total_name) orelse return null
    else
        null;
    if (post_kind == .none) {
        const exit_ret = switch (exit.terminator orelse return null) {
            .ret => |ret| ret,
            else => return null,
        };
        if (!exit_ret.ty.eql(.{ .int = 32 }) or !isNamed(exit_ret.value orelse return null, total_name)) return null;
    }
    return .{ .call = call, .error_return = error_return, .post_branch = post_branch, .post_switch = post_switch };
}

fn loopTryPostBranch(
    exit: ir.BasicBlock,
    exit_then: ir.BasicBlock,
    exit_else: ir.BasicBlock,
    total_name: []const u8,
    threshold_name: []const u8,
) ?LoopTryPostBranchPlan {
    if (exit.instructions.items.len != 1) return null;
    const cond_name = exit.instructions.items[0].result orelse return null;
    const cmp = switch (exit.instructions.items[0].kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (cmp.predicate != .sgt or
        !cmp.operand_ty.eql(.{ .int = 32 }) or
        !isNamed(cmp.lhs, total_name) or
        !isNamed(cmp.rhs, threshold_name)) return null;
    const branch = switch (exit.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!isNamed(branch.cond, cond_name) or
        !std.mem.eql(u8, branch.then_target, exit_then.name) or
        !std.mem.eql(u8, branch.else_target, exit_else.name)) return null;
    return .{
        .true_addend = loopTryPostBranchReturnAddend(exit_then, total_name) orelse return null,
        .false_addend = loopTryPostBranchReturnAddend(exit_else, total_name) orelse return null,
    };
}

fn loopTryPostBranchReturnAddend(block: ir.BasicBlock, total_name: []const u8) ?i32 {
    if (block.instructions.items.len != 1) return null;
    const result_name = block.instructions.items[0].result orelse return null;
    const add = switch (block.instructions.items[0].kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 }) or !isNamed(add.lhs, total_name)) return null;
    const addend = switch (add.rhs) {
        .int => |int| i32Value(int) catch return null,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return null, result_name)) return null;
    return addend;
}

fn loopTryPostSwitch(
    exit: ir.BasicBlock,
    exit_case0: ir.BasicBlock,
    exit_case1: ir.BasicBlock,
    exit_default: ir.BasicBlock,
    total_name: []const u8,
) ?LoopTryPostSwitchPlan {
    if (exit.instructions.items.len != 1) return null;
    const key_name = exit.instructions.items[0].result orelse return null;
    const key = switch (exit.instructions.items[0].kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (key.op != .@"and" or !key.ty.eql(.{ .int = 32 }) or !isNamed(key.lhs, total_name)) return null;
    const mask = switch (key.rhs) {
        .int => |int| i32Value(int) catch return null,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const switch_term = switch (exit.terminator orelse return null) {
        .@"switch" => |switch_term| switch_term,
        else => return null,
    };
    if (!switch_term.cond_ty.eql(.{ .int = 32 }) or !isNamed(switch_term.cond, key_name)) return null;
    if (!std.mem.eql(u8, switch_term.default_target, exit_default.name) or switch_term.cases.items.len != 2) return null;
    if (!switchCaseTargets(switch_term.cases.items[0], 0, exit_case0.name) or
        !switchCaseTargets(switch_term.cases.items[1], 1, exit_case1.name)) return null;
    return .{
        .mask = mask,
        .case0_addend = loopTryPostBranchReturnAddend(exit_case0, total_name) orelse return null,
        .case1_addend = loopTryPostBranchReturnAddend(exit_case1, total_name) orelse return null,
        .default_addend = loopTryPostBranchReturnAddend(exit_default, total_name) orelse return null,
    };
}

fn switchCaseTargets(case: ir.SwitchCase, value: i32, target: []const u8) bool {
    return case.value_ty.eql(.{ .int = 32 }) and isInt(case.value, value) and std.mem.eql(u8, case.target, target);
}

fn validateAssumeColdCall(instruction: ir.Instruction) !void {
    if (instruction.removed) return error.UnsupportedCodegenInstruction;
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!std.mem.eql(u8, call.callee, "llvm.assume")) return error.UnsupportedCodegenInstruction;
    if (call.ret_ty != .void or call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 1 }) or !isInt(call.args.items[0].value, 1)) return error.UnsupportedCodegenValue;
}

fn blockByName(function: ir.Function, name: []const u8) ?ir.BasicBlock {
    for (function.blocks.items) |block| {
        if (std.mem.eql(u8, block.name, name)) return block;
    }
    return null;
}

pub fn lowerGenericCfgOptionalPointerUnwrapReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = genericCfgOptionalPointerUnwrapPlan(function) orelse return false;
    const load_label = "generic_cfg_optional_unwrap_load";
    const null_label = "generic_cfg_optional_unwrap_null";
    try emitGenericCfgConditionTrueBranch(allocator, machine, function, plan.entry, plan.entry_cond, if (plan.true_is_ptr) load_label else null_label);
    if (plan.true_is_ptr) {
        try emitGenericCfgOptionalPointerUnwrapNullPath(allocator, machine, function, plan);
        try appendGenericCfgBlockLabel(allocator, machine, load_label);
        try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = plan.ptr_reg });
        try appendGenericCfgReturn(allocator, machine);
    } else {
        try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = plan.ptr_reg });
        try appendGenericCfgReturn(allocator, machine);
        try appendGenericCfgBlockLabel(allocator, machine, null_label);
        try emitGenericCfgOptionalPointerUnwrapNullPath(allocator, machine, function, plan);
    }
    return true;
}

pub fn lowerGenericCfgOptionalPointerReturn(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.blocks.items.len != 3) return false;
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 1) return false;
    const cond_result = entry.instructions.items[0].result orelse return false;
    const icmp = switch (entry.instructions.items[0].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (!genericCfgSupportsPointerNullIcmp(function, icmp)) return false;
    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, cond_result)) return false;

    const then_block = function.blocks.items[blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget];
    const else_block = function.blocks.items[blockIndex(function, condbr.else_target) orelse return error.InvalidBranchTarget];
    const then_is_merge = genericCfgOptionalPointerMergeValue(then_block, entry.name) != null;
    const else_is_merge = genericCfgOptionalPointerMergeValue(else_block, entry.name) != null;
    if (then_is_merge == else_is_merge) return false;
    const merge_block = if (then_is_merge) then_block else else_block;
    const load_block = if (then_is_merge) else_block else then_block;
    const null_value = genericCfgOptionalPointerMergeValue(merge_block, entry.name) orelse return false;
    const load_value = genericCfgOptionalPointerLoadValue(function, load_block, merge_block.name) orelse return false;
    if (!genericCfgOptionalPointerMergeHasIncoming(merge_block, load_block.name, load_value)) return false;

    const branch_kind = try emitGenericCfgIcmpCondition(allocator, machine, function, icmp);
    if (then_is_merge) {
        const null_label = "generic_cfg_optional_pointer_null";
        try appendGenericCfgConditionalBranch(allocator, machine, branch_kind, null_label);
        try emitGenericCfgI32ValueIntoEax(allocator, machine, function, load_block, load_value);
        try appendGenericCfgReturn(allocator, machine);
        try appendGenericCfgBlockLabel(allocator, machine, null_label);
        try emitGenericCfgI32ValueIntoEax(allocator, machine, function, merge_block, null_value);
        try appendGenericCfgReturn(allocator, machine);
    } else {
        const load_label = "generic_cfg_optional_pointer_load";
        try appendGenericCfgConditionalBranch(allocator, machine, branch_kind, load_label);
        try emitGenericCfgI32ValueIntoEax(allocator, machine, function, merge_block, null_value);
        try appendGenericCfgReturn(allocator, machine);
        try appendGenericCfgBlockLabel(allocator, machine, load_label);
        try emitGenericCfgI32ValueIntoEax(allocator, machine, function, load_block, load_value);
        try appendGenericCfgReturn(allocator, machine);
    }
    return true;
}

const GenericCfgOptionalPointerUnwrapPlan = struct {
    entry: ir.BasicBlock,
    entry_cond: ir.Value,
    true_is_ptr: bool,
    ptr_reg: ArgReg,
    panic_block: ?ir.BasicBlock,
};

fn genericCfgOptionalPointerUnwrapPlan(function: ir.Function) ?GenericCfgOptionalPointerUnwrapPlan {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len < 2) return null;
    if (!function.params.items[0].ty.eql(.{ .int = 1 }) or !function.params.items[1].ty.eql(.ptr)) return null;
    if (function.blocks.items.len != 4 and function.blocks.items.len != 6) return null;
    const entry = function.blocks.items[0];
    const condbr = switch (entry.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const then_block = blockByName(function, condbr.then_target) orelse return null;
    const else_block = blockByName(function, condbr.else_target) orelse return null;
    const then_target = singleBrTarget(then_block) orelse return null;
    const else_target = singleBrTarget(else_block) orelse return null;
    if (!std.mem.eql(u8, then_target, else_target)) return null;
    const merge_block = blockByName(function, then_target) orelse return null;
    if (merge_block.instructions.items.len < 2) return null;
    const phi_name = merge_block.instructions.items[0].result orelse return null;
    const phi = switch (merge_block.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return null,
    };
    if (!phi.ty.eql(.ptr) or phi.incoming.items.len != 2) return null;

    var ptr_block: ?[]const u8 = null;
    var ptr_reg: ?ArgReg = null;
    var null_block: ?[]const u8 = null;
    for (phi.incoming.items) |incoming| {
        if (incoming.value == .null_value) {
            null_block = incoming.block;
            continue;
        }
        const reg = paramRegOrNull(function, switch (incoming.value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
        }, .ptr) catch return null;
        ptr_reg = reg orelse return null;
        ptr_block = incoming.block;
    }
    const ptr_block_name = ptr_block orelse return null;
    _ = null_block orelse return null;
    const true_is_ptr = std.mem.eql(u8, condbr.then_target, ptr_block_name);
    if (!true_is_ptr and !std.mem.eql(u8, condbr.else_target, ptr_block_name)) return null;

    if (function.blocks.items.len == 4) {
        const load_name = merge_block.instructions.items[1].result orelse return null;
        const load = switch (merge_block.instructions.items[1].kind) {
            .load => |load| load,
            else => return null,
        };
        if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier() or !isNamed(load.ptr, phi_name)) return null;
        const ret = switch (merge_block.terminator orelse return null) {
            .ret => |ret| ret,
            else => return null,
        };
        if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return null, load_name)) return null;
        return .{ .entry = entry, .entry_cond = condbr.cond, .true_is_ptr = true_is_ptr, .ptr_reg = ptr_reg orelse return null, .panic_block = null };
    }

    const icmp_name = merge_block.instructions.items[1].result orelse return null;
    const icmp = switch (merge_block.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (icmp.predicate != .ne or !icmp.operand_ty.eql(.ptr) or !isNamed(icmp.lhs, phi_name) or icmp.rhs != .null_value) return null;
    const guard = switch (merge_block.terminator orelse return null) {
        .condbr => |guard| guard,
        else => return null,
    };
    if (!guard.cond_ty.eql(.{ .int = 1 }) or !isNamed(guard.cond, icmp_name)) return null;
    const cont_block = blockByName(function, guard.then_target) orelse return null;
    const panic_block = blockByName(function, guard.else_target) orelse return null;
    if (!genericCfgOptionalPointerUnwrapContReturn(cont_block, phi_name)) return null;
    if (!genericCfgNoreturnBlock(panic_block)) return null;
    return .{ .entry = entry, .entry_cond = condbr.cond, .true_is_ptr = true_is_ptr, .ptr_reg = ptr_reg orelse return null, .panic_block = panic_block };
}

fn genericCfgOptionalPointerUnwrapContReturn(block: ir.BasicBlock, phi_name: []const u8) bool {
    if (block.instructions.items.len != 1) return false;
    const load_name = block.instructions.items[0].result orelse return false;
    const load = switch (block.instructions.items[0].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier() or !isNamed(load.ptr, phi_name)) return false;
    const ret = switch (block.terminator orelse return false) {
        .ret => |ret| ret,
        else => return false,
    };
    return ret.ty.eql(.{ .int = 32 }) and isNamed(ret.value orelse return false, load_name);
}

fn genericCfgNoreturnBlock(block: ir.BasicBlock) bool {
    if (block.instructions.items.len == 0 or block.instructions.items.len > 2) return false;
    const call_index: usize = if (block.instructions.items.len == 2) 1 else 0;
    const call = switch (block.instructions.items[call_index].kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null or call.inline_asm != null or call.ret_ty != .void) return false;
    if (call.args.items.len != 0) return false;
    switch (block.terminator orelse return false) {
        .@"unreachable" => return true,
        else => return false,
    }
}

fn emitGenericCfgOptionalPointerUnwrapNullPath(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    plan: GenericCfgOptionalPointerUnwrapPlan,
) !void {
    if (plan.panic_block) |panic_block| {
        try emitGenericCfgNoreturnCallBlock(allocator, machine, function, panic_block);
    } else {
        try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
        try appendGenericCfgReturn(allocator, machine);
    }
}

pub fn lowerGenericCfgGuardReturnNoreturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.blocks.items.len == 5) return try lowerGenericCfgGuardReturnBoundsThenNoreturn(allocator, machine, function);
    if (function.blocks.items.len != 3) return false;
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 0) return false;
    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 })) return false;
    const cond_reg = paramValueReg(function, condbr.cond, .{ .int = 1 }) catch return false;

    const then_block = blockByName(function, condbr.then_target) orelse return false;
    const else_block = blockByName(function, condbr.else_target) orelse return false;
    const then_ret = genericCfgConstI32Return(then_block);
    const else_ret = genericCfgConstI32Return(else_block);
    if (then_ret == null and else_ret == null) return false;
    const ret_block = if (then_ret != null) then_block else else_block;
    const panic_block = if (then_ret != null) else_block else then_block;
    const ret_value = then_ret orelse else_ret.?;

    _ = validateNoreturnSliceRuntimeCall(panic_block) catch return false;
    try machine.instructions.append(allocator, .{ .test_arg8 = cond_reg });
    if (then_ret != null) {
        try appendGenericCfgConditionalBranch(allocator, machine, .jne, ret_block.name);
    } else {
        try appendGenericCfgConditionalBranch(allocator, machine, .je, ret_block.name);
    }
    try appendGenericCfgBlockLabel(allocator, machine, panic_block.name);
    try emitGenericCfgNoreturnCallBlock(allocator, machine, function, panic_block);
    try appendGenericCfgBlockLabel(allocator, machine, ret_block.name);
    try machine.instructions.append(allocator, .{ .mov_imm_eax = ret_value });
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

fn lowerGenericCfgGuardReturnBoundsThenNoreturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 0) return false;
    const entry_condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_condbr.cond_ty.eql(.{ .int = 1 })) return false;
    const cond_reg = paramValueReg(function, entry_condbr.cond, .{ .int = 1 }) catch return false;

    const then_block = blockByName(function, entry_condbr.then_target) orelse return false;
    const else_block = blockByName(function, entry_condbr.else_target) orelse return false;
    const then_ret = genericCfgConstI32Return(then_block);
    const else_ret = genericCfgConstI32Return(else_block);
    if (then_ret == null and else_ret == null) return false;
    const ret_block = if (then_ret != null) then_block else else_block;
    const guard_block = if (then_ret != null) else_block else then_block;
    const ret_value = then_ret orelse else_ret.?;

    const guard = try genericCfgBoundsGuard(function, guard_block);
    const panic_block = blockByName(function, guard.panic_target) orelse return false;
    const cont_block = blockByName(function, guard.cont_target) orelse return false;
    _ = validateNoreturnSliceRuntimeCall(cont_block) catch return false;
    try validateI64NoreturnCallBlock(panic_block);

    try machine.instructions.append(allocator, .{ .test_arg8 = cond_reg });
    if (then_ret != null) {
        try appendGenericCfgConditionalBranch(allocator, machine, .jne, ret_block.name);
    } else {
        try appendGenericCfgConditionalBranch(allocator, machine, .je, ret_block.name);
    }

    try appendGenericCfgBlockLabel(allocator, machine, guard_block.name);
    try emitI64ValueIntoArgReg(allocator, machine, function, guard_block, .rdi, guard.len_value);
    try machine.instructions.append(allocator, .{ .cmp_arg64_imm64 = .{ .reg = .rdi, .imm = guard.max_value + 1 } });
    try appendGenericCfgConditionalBranch(allocator, machine, .jae, panic_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, cont_block.name);
    try emitGenericCfgNoreturnCallBlock(allocator, machine, function, cont_block);

    try appendGenericCfgBlockLabel(allocator, machine, panic_block.name);
    try emitI64ValueIntoArgReg(allocator, machine, function, guard_block, .rdi, guard.len_value);
    try appendMoveImmToArgReg(allocator, machine, .rsi, guard.max_value);
    try emitValidatedI64NoreturnCallBlock(allocator, machine, panic_block);

    try appendGenericCfgBlockLabel(allocator, machine, ret_block.name);
    try machine.instructions.append(allocator, .{ .mov_imm_eax = ret_value });
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

const GenericCfgBoundsGuard = struct {
    len_value: ir.Value,
    max_value: i64,
    cont_target: []const u8,
    panic_target: []const u8,
};

fn genericCfgBoundsGuard(function: ir.Function, block: ir.BasicBlock) !GenericCfgBoundsGuard {
    if (block.instructions.items.len == 0) return error.UnsupportedCodegenControlFlow;
    const condbr = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 })) return error.UnsupportedCodegenControlFlow;
    const icmp_name = switch (condbr.cond) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    const instruction = findInstructionInFunction(function, block, icmp_name) orelse return error.UnsupportedCodegenInstruction;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (icmp.predicate != .ule or !icmp.operand_ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenInstruction;
    const max_value = switch (icmp.rhs) {
        .int => |int| try i64Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    if (max_value == std.math.maxInt(i64)) return error.UnsupportedCodegenValue;
    return .{
        .len_value = icmp.lhs,
        .max_value = max_value,
        .cont_target = condbr.then_target,
        .panic_target = condbr.else_target,
    };
}

fn validateI64NoreturnCallBlock(block: ir.BasicBlock) !void {
    if (block.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    const call = switch (block.instructions.items[0].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (call.callee_value != null or call.inline_asm != null or call.ret_ty != .void) return error.UnsupportedCodegenInstruction;
    if (!callIsFastcc(call.calling_conv)) try validateDefaultCallConv(call.calling_conv);
    if (call.args.items.len != 2) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 64 }) or !call.args.items[1].ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
    switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .@"unreachable" => {},
        else => return error.UnsupportedCodegenControlFlow,
    }
}

fn emitValidatedI64NoreturnCallBlock(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    block: ir.BasicBlock,
) !void {
    try validateI64NoreturnCallBlock(block);
    const call = switch (block.instructions.items[0].kind) {
        .call => |call| call,
        else => unreachable,
    };
    try appendAlignedDirectCall(allocator, machine, call.callee, .void);
    try machine.instructions.append(allocator, .ud2);
}

fn emitValidatedI64NoreturnCallBlockWithArgs(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    entry: ir.BasicBlock,
    block: ir.BasicBlock,
) !void {
    try validateI64NoreturnCallBlock(block);
    const call = switch (block.instructions.items[0].kind) {
        .call => |call| call,
        else => unreachable,
    };
    const first = call.args.items[0].value;
    const second = call.args.items[1].value;
    if (directI64ParamReg(function, first) == .rsi or directI64ParamReg(function, second) == .rdi) {
        return error.UnsupportedCodegenAbi;
    }
    try emitI64ValueIntoArgReg(allocator, machine, function, entry, .rdi, first);
    try emitI64ValueIntoArgReg(allocator, machine, function, entry, .rsi, second);
    try appendAlignedDirectCall(allocator, machine, call.callee, .void);
    try machine.instructions.append(allocator, .ud2);
}

fn directI64ParamReg(function: ir.Function, value: ir.Value) ?ArgReg {
    const name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    return paramRegOrNull(function, name, .{ .int = 64 }) catch null;
}

fn genericCfgConstI32Return(block: ir.BasicBlock) ?i32 {
    if (block.instructions.items.len != 0) return null;
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

pub fn lowerGenericCfgGuardedDynamicPointerLoadReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 3) return false;
    if (!function.params.items[0].ty.eql(.ptr) or
        !function.params.items[1].ty.eql(.{ .int = 64 }) or
        !function.params.items[2].ty.eql(.{ .int = 64 })) return false;
    if (function.blocks.items.len != 3) return false;

    const entry = function.blocks.items[0];
    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 })) return false;
    const cond_name = switch (condbr.cond) {
        .named => |name| name,
        else => return false,
    };
    const cond_instruction = findInstruction(entry, cond_name) orelse return false;
    const icmp = switch (cond_instruction.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .uge or !icmp.operand_ty.eql(.{ .int = 64 })) return false;

    const true_block = blockByName(function, condbr.then_target) orelse return false;
    const false_block = blockByName(function, condbr.else_target) orelse return false;
    const true_const = genericCfgConstantI32Return(true_block);
    const false_const = genericCfgConstantI32Return(false_block);
    if ((true_const == null) == (false_const == null)) return false;
    const const_block = if (true_const != null) true_block else false_block;
    const load_block = if (true_const != null) false_block else true_block;
    const const_value = true_const orelse false_const orelse return false;

    const address = core_memory_lowering.genericCfgDynamicI32LoadReturnAddress(function, entry, load_block) orelse return false;
    const lhs_reg = genericCfgI64ParamRegThroughIdentityCast(function, entry, icmp.lhs) orelse return false;
    const rhs_reg = genericCfgI64ParamRegThroughIdentityCast(function, entry, icmp.rhs) orelse return false;
    if ((address.index_reg orelse return false) != lhs_reg) return false;

    try emitGenericCfgUgeI64ParamCondition(allocator, machine, lhs_reg, rhs_reg);
    const branch_to_const = true_const != null;
    if (branch_to_const) {
        try appendGenericCfgConditionalBranch(allocator, machine, .jae, const_block.name);
        try core_memory_lowering.emitGenericCfgDynamicI32LoadIntoEax(allocator, machine, address);
        try appendGenericCfgReturn(allocator, machine);
        try appendGenericCfgBlockLabel(allocator, machine, const_block.name);
        try machine.instructions.append(allocator, .{ .mov_imm_eax = const_value });
        try appendGenericCfgReturn(allocator, machine);
    } else {
        try appendGenericCfgConditionalBranch(allocator, machine, .jae, load_block.name);
        try machine.instructions.append(allocator, .{ .mov_imm_eax = const_value });
        try appendGenericCfgReturn(allocator, machine);
        try appendGenericCfgBlockLabel(allocator, machine, load_block.name);
        try core_memory_lowering.emitGenericCfgDynamicI32LoadIntoEax(allocator, machine, address);
        try appendGenericCfgReturn(allocator, machine);
    }
    return true;
}

pub fn lowerGenericCfgGuardedDynamicPointerLoadPanicReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 3) return false;
    if (!function.params.items[0].ty.eql(.ptr) or
        !function.params.items[1].ty.eql(.{ .int = 64 }) or
        !function.params.items[2].ty.eql(.{ .int = 64 })) return false;
    if (function.blocks.items.len != 3) return false;

    const entry = function.blocks.items[0];
    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 })) return false;
    const cond_name = switch (condbr.cond) {
        .named => |name| name,
        else => return false,
    };
    const cond_instruction = findInstruction(entry, cond_name) orelse return false;
    const icmp = switch (cond_instruction.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    switch (icmp.predicate) {
        .uge, .ult => {},
        else => return false,
    }
    if (!icmp.operand_ty.eql(.{ .int = 64 })) return false;

    const true_block = blockByName(function, condbr.then_target) orelse return false;
    const false_block = blockByName(function, condbr.else_target) orelse return false;
    const true_panic = if (validateNoreturnSliceRuntimeCall(true_block)) |_| true else |_| if (validateI64NoreturnCallBlock(true_block)) |_| true else |_| false;
    const false_panic = if (validateNoreturnSliceRuntimeCall(false_block)) |_| true else |_| if (validateI64NoreturnCallBlock(false_block)) |_| true else |_| false;
    if (true_panic == false_panic) return false;
    const panic_block = if (true_panic) true_block else false_block;
    const load_block = if (true_panic) false_block else true_block;

    const width = core_memory_lowering.GenericCfgScalarWidth.fromType(function.ret_ty) orelse return false;
    const address = core_memory_lowering.genericCfgTypedScalarLoadReturnAddressAcrossBlocks(function, entry, load_block, width) orelse return false;
    const lhs_reg = genericCfgI64ParamRegThroughIdentityCast(function, entry, icmp.lhs) orelse return false;
    if (address.add_index_reg != lhs_reg or address.sub_index_reg != null) return false;

    switch (icmp.predicate) {
        .uge => {
            try emitGenericCfgUgeI64ValueCondition(allocator, machine, function, entry, lhs_reg, icmp.rhs);
            if (true_panic) {
                try appendGenericCfgConditionalBranch(allocator, machine, .jae, panic_block.name);
                try core_memory_lowering.emitGenericCfgTypedScalarLoadIntoReturn(allocator, machine, address);
                try appendGenericCfgReturn(allocator, machine);
                try appendGenericCfgBlockLabel(allocator, machine, panic_block.name);
                try emitGenericCfgNoreturnPanicBlock(allocator, machine, function, entry, panic_block);
            } else {
                try appendGenericCfgConditionalBranch(allocator, machine, .jae, load_block.name);
                try emitGenericCfgNoreturnPanicBlock(allocator, machine, function, entry, panic_block);
                try appendGenericCfgBlockLabel(allocator, machine, load_block.name);
                try core_memory_lowering.emitGenericCfgTypedScalarLoadIntoReturn(allocator, machine, address);
                try appendGenericCfgReturn(allocator, machine);
            }
        },
        .ult => {
            try emitGenericCfgUgeI64ValueCondition(allocator, machine, function, entry, lhs_reg, icmp.rhs);
            if (true_panic) {
                try appendGenericCfgConditionalBranch(allocator, machine, .jae, load_block.name);
                try emitGenericCfgNoreturnPanicBlock(allocator, machine, function, entry, panic_block);
                try appendGenericCfgBlockLabel(allocator, machine, load_block.name);
                try core_memory_lowering.emitGenericCfgTypedScalarLoadIntoReturn(allocator, machine, address);
                try appendGenericCfgReturn(allocator, machine);
            } else {
                try appendGenericCfgConditionalBranch(allocator, machine, .jae, panic_block.name);
                try core_memory_lowering.emitGenericCfgTypedScalarLoadIntoReturn(allocator, machine, address);
                try appendGenericCfgReturn(allocator, machine);
                try appendGenericCfgBlockLabel(allocator, machine, panic_block.name);
                try emitGenericCfgNoreturnPanicBlock(allocator, machine, function, entry, panic_block);
            }
        },
        else => return false,
    }
    return true;
}

pub fn lowerGenericCfgCheckedSliceStoreLoadReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 4) return false;
    if (!function.params.items[0].ty.eql(.ptr) or
        !function.params.items[1].ty.eql(.{ .int = 64 }) or
        !function.params.items[2].ty.eql(.{ .int = 64 }) or
        !function.params.items[3].ty.eql(.{ .int = 32 })) return false;
    if (function.blocks.items.len != 5) return false;

    const entry = function.blocks.items[0];
    const first_guard = genericCfgSliceBoundsGuard(function, entry) orelse return false;
    const store_block = blockByName(function, first_guard.cont_target) orelse return false;
    const first_panic = blockByName(function, first_guard.panic_target) orelse return false;
    try validateSliceBoundsPanicBlock(function, entry, first_panic, first_guard.index_value, first_guard.len_value);

    const store_step = genericCfgCheckedSliceStoreStep(function, entry, store_block) orelse return false;
    if (!first_guard.index_value.eql(store_step.index_value)) return false;
    const second_panic = blockByName(function, store_step.guard.panic_target) orelse return false;
    const load_block = blockByName(function, store_step.guard.cont_target) orelse return false;
    try validateSliceBoundsPanicBlock(function, entry, second_panic, store_step.guard.index_value, store_step.guard.len_value);

    const load_address = genericCfgCheckedSliceReturnLoadAddress(function, entry, store_block, load_block) orelse return false;
    if (!core_memory_lowering.sameGenericCfgTypedAddress(store_step.store_address, load_address)) return false;

    const index_reg = genericCfgI64ParamRegThroughIdentityCast(function, entry, first_guard.index_value) orelse return false;
    if (store_step.store_address.add_index_reg != index_reg or store_step.store_address.sub_index_reg != null) return false;

    try core_memory_lowering.emitGenericCfgScalarValueIntoReturnReg(allocator, machine, function, store_step.store_value, .i32);
    try emitGenericCfgUgeI64ValueCondition(allocator, machine, function, entry, index_reg, first_guard.len_value);
    try appendGenericCfgConditionalBranch(allocator, machine, .jae, first_panic.name);
    try core_memory_lowering.emitGenericCfgTypedAddressIntoRcx(allocator, machine, store_step.store_address);
    try core_memory_lowering.emitGenericCfgTypedScalarStoreReturnReg(allocator, machine, .i32);

    try emitGenericCfgUgeI64ValueCondition(allocator, machine, function, entry, index_reg, store_step.guard.len_value);
    try appendGenericCfgConditionalBranch(allocator, machine, .jae, second_panic.name);
    try core_memory_lowering.emitGenericCfgTypedScalarLoadIntoReturn(allocator, machine, load_address);
    try appendGenericCfgReturn(allocator, machine);

    try appendGenericCfgBlockLabel(allocator, machine, first_panic.name);
    try emitValidatedI64NoreturnCallBlockWithArgs(allocator, machine, function, entry, first_panic);
    try appendGenericCfgBlockLabel(allocator, machine, second_panic.name);
    try emitValidatedI64NoreturnCallBlockWithArgs(allocator, machine, function, entry, second_panic);
    return true;
}

const GenericCfgSliceBoundsGuard = struct {
    index_value: ir.Value,
    len_value: ir.Value,
    cont_target: []const u8,
    panic_target: []const u8,
};

const GenericCfgCheckedSliceStoreStep = struct {
    store_address: core_memory_lowering.GenericCfgTypedAddress,
    store_value: ir.Value,
    index_value: ir.Value,
    guard: GenericCfgSliceBoundsGuard,
};

fn genericCfgSliceBoundsGuard(function: ir.Function, block: ir.BasicBlock) ?GenericCfgSliceBoundsGuard {
    const condbr = switch (block.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const cond_name = switch (condbr.cond) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const cond_inst = findInstructionInFunction(function, block, cond_name) orelse return null;
    const icmp = switch (cond_inst.kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (icmp.predicate != .ult or !icmp.operand_ty.eql(.{ .int = 64 })) return null;
    return .{
        .index_value = icmp.lhs,
        .len_value = icmp.rhs,
        .cont_target = condbr.then_target,
        .panic_target = condbr.else_target,
    };
}

fn genericCfgCheckedSliceStoreStep(
    function: ir.Function,
    entry: ir.BasicBlock,
    block: ir.BasicBlock,
) ?GenericCfgCheckedSliceStoreStep {
    const guard = genericCfgSliceBoundsGuard(function, block) orelse return null;
    var store_inst: ?ir.StoreInst = null;
    for (block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        const store = switch (instruction.kind) {
            .store => |store| store,
            else => continue,
        };
        if (store_inst != null) return null;
        store_inst = store;
    }
    const store = store_inst orelse return null;
    if (!store.ty.eql(.{ .int = 32 }) or store.attrs.isBarrier()) return null;
    const address = core_memory_lowering.genericCfgTypedScalarAddressAcrossBlocks(function, entry, block, store.ptr, .i32) orelse return null;
    return .{
        .store_address = address,
        .store_value = store.value,
        .index_value = guard.index_value,
        .guard = guard,
    };
}

fn genericCfgCheckedSliceReturnLoadAddress(
    function: ir.Function,
    entry: ir.BasicBlock,
    store_block: ir.BasicBlock,
    block: ir.BasicBlock,
) ?core_memory_lowering.GenericCfgTypedAddress {
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return null;
    const ret_name = switch (ret.value orelse return null) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const ret_inst = findInstruction(block, ret_name) orelse return null;
    const load = switch (ret_inst.kind) {
        .load => |load| load,
        else => return null,
    };
    return core_memory_lowering.genericCfgTypedScalarLoadAddressAcrossScopes(function, entry, store_block, block, load, .i32);
}

fn validateSliceBoundsPanicBlock(
    function: ir.Function,
    entry: ir.BasicBlock,
    block: ir.BasicBlock,
    index_value: ir.Value,
    len_value: ir.Value,
) !void {
    try validateI64NoreturnCallBlock(block);
    const call = switch (block.instructions.items[0].kind) {
        .call => |call| call,
        else => unreachable,
    };
    if (!call.args.items[0].value.eql(index_value) or !call.args.items[1].value.eql(len_value)) {
        return error.UnsupportedCodegenValue;
    }
    _ = genericCfgI64ParamRegThroughIdentityCast(function, entry, index_value) orelse return error.UnsupportedCodegenValue;
    if (directI64ParamReg(function, index_value) == .rsi or directI64ParamReg(function, len_value) == .rdi) {
        return error.UnsupportedCodegenAbi;
    }
}

pub fn genericCfgConstantI32Return(block: ir.BasicBlock) ?i32 {
    if (block.instructions.items.len != 0) return null;
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return null;
    return switch (ret.value orelse return null) {
        .int => |int| i32Value(int) catch null,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
    };
}

pub fn genericCfgI64ParamRegThroughIdentityCast(function: ir.Function, block: ir.BasicBlock, value: ir.Value) ?ArgReg {
    const name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (paramRegOrNull(function, name, .{ .int = 64 }) catch null) |reg| return reg;
    const instruction = findInstruction(block, name) orelse return null;
    const cast = switch (instruction.kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (cast.op != .bitcast or !cast.from_ty.eql(.{ .int = 64 }) or !cast.to_ty.eql(.{ .int = 64 })) return null;
    return genericCfgI64ParamRegThroughIdentityCast(function, block, cast.value);
}

pub fn emitGenericCfgUgeI64ParamCondition(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    lhs_reg: ArgReg,
    rhs_reg: ArgReg,
) !void {
    if (lhs_reg == .rcx) return error.UnsupportedCodegenAbi;
    try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = .rcx, .src = rhs_reg } });
    try machine.instructions.append(allocator, .{ .cmp_rcx_arg64 = lhs_reg });
}

fn emitGenericCfgUgeI64ValueCondition(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    entry: ir.BasicBlock,
    lhs_reg: ArgReg,
    rhs: ir.Value,
) !void {
    if (lhs_reg == .rcx) return error.UnsupportedCodegenAbi;
    try emitI64ValueIntoArgReg(allocator, machine, function, entry, .rcx, rhs);
    try machine.instructions.append(allocator, .{ .cmp_rcx_arg64 = lhs_reg });
}

fn emitGenericCfgNoreturnPanicBlock(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    entry: ir.BasicBlock,
    block: ir.BasicBlock,
) !void {
    if (validateI64NoreturnCallBlock(block)) |_| {
        try emitValidatedI64NoreturnCallBlockWithArgs(allocator, machine, function, entry, block);
    } else |_| {
        try emitGenericCfgNoreturnCallBlock(allocator, machine, function, block);
    }
}

pub fn genericCfgOptionalPointerMergeValue(block: ir.BasicBlock, entry_name: []const u8) ?ir.Value {
    if (block.instructions.items.len != 1) return null;
    const instruction = block.instructions.items[0];
    if (instruction.removed) return null;
    const phi_name = instruction.result orelse return null;
    const phi = switch (instruction.kind) {
        .phi => |phi| phi,
        else => return null,
    };
    if (!phi.ty.eql(.{ .int = 32 }) or phi.incoming.items.len != 2) return null;
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return null, phi_name)) return null;
    for (phi.incoming.items) |incoming| {
        if (std.mem.eql(u8, incoming.block, entry_name)) return incoming.value;
    }
    return null;
}

pub fn genericCfgOptionalPointerLoadValue(function: ir.Function, block: ir.BasicBlock, merge_name: []const u8) ?ir.Value {
    if (block.instructions.items.len == 0 or block.instructions.items.len > 2) return null;
    const load_instruction = block.instructions.items[0];
    if (load_instruction.removed) return null;
    const load_name = load_instruction.result orelse return null;
    const load = switch (load_instruction.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return null;
    const ptr_name = switch (load.ptr) {
        .named => |name| name,
        else => return null,
    };
    if ((paramRegOrNull(function, ptr_name, .ptr) catch null) == null) return null;
    if (!std.mem.eql(u8, singleBrTarget(block) orelse return null, merge_name)) return null;
    if (block.instructions.items.len == 2) {
        const add_instruction = block.instructions.items[1];
        if (add_instruction.removed) return null;
        const add_name = add_instruction.result orelse return null;
        const binary = switch (add_instruction.kind) {
            .binary => |binary| binary,
            else => return null,
        };
        if (binary.op != .add or !binary.ty.eql(.{ .int = 32 }) or !isNamed(binary.lhs, load_name)) return null;
        switch (binary.rhs) {
            .int => {},
            else => return null,
        }
        return .{ .named = add_name };
    }
    return .{ .named = load_name };
}

pub fn genericCfgOptionalPointerMergeHasIncoming(block: ir.BasicBlock, incoming_block: []const u8, expected: ir.Value) bool {
    const phi = switch (block.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    for (phi.incoming.items) |incoming| {
        if (std.mem.eql(u8, incoming.block, incoming_block)) return incoming.value.eql(expected);
    }
    return false;
}

pub fn lowerGenericCfgStructBranchUpdateReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 2 or function.blocks.items.len != 4) return false;
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 3) return false;
    const slot = genericCfgPointerSlotParam(function, entry.instructions.items[0], entry.instructions.items[1]) orelse return false;
    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 })) return false;
    const then_block = function.blocks.items[blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget];
    const else_block = function.blocks.items[blockIndex(function, condbr.else_target) orelse return error.InvalidBranchTarget];
    const then_target = singleBrTarget(then_block) orelse return false;
    const else_target = singleBrTarget(else_block) orelse return false;
    if (!std.mem.eql(u8, then_target, else_target)) return false;
    const merge_block = function.blocks.items[blockIndex(function, then_target) orelse return error.InvalidBranchTarget];

    const then_add = genericCfgStructFieldZeroUpdateAdd(then_block, slot.slot_name) orelse return false;
    const else_add = genericCfgStructFieldZeroUpdateAdd(else_block, slot.slot_name) orelse return false;
    if (!genericCfgStructFieldZeroMergeReturn(merge_block, slot.slot_name)) return false;

    try emitGenericCfgConditionTrueBranch(allocator, machine, function, entry, condbr.cond, then_block.name);
    try emitGenericCfgStructFieldZeroUpdatePath(allocator, machine, slot.param_reg, else_add);
    try appendGenericCfgBlockLabel(allocator, machine, then_block.name);
    try emitGenericCfgStructFieldZeroUpdatePath(allocator, machine, slot.param_reg, then_add);
    return true;
}

pub fn genericCfgStructFieldZeroUpdateAdd(block: ir.BasicBlock, slot_name: []const u8) ?i32 {
    if (block.instructions.items.len != 4) return null;
    const loaded_ptr = genericCfgLoadPtrFromSlot(block.instructions.items[0], slot_name) orelse return null;

    const load_name = block.instructions.items[1].result orelse return null;
    const load = switch (block.instructions.items[1].kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier() or !isNamed(load.ptr, loaded_ptr)) return null;

    const add_name = block.instructions.items[2].result orelse return null;
    const add = switch (block.instructions.items[2].kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 }) or !isNamed(add.lhs, load_name)) return null;
    const add_imm = switch (add.rhs) {
        .int => |int| i32Value(int) catch return null,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };

    const store = switch (block.instructions.items[3].kind) {
        .store => |store| store,
        else => return null,
    };
    if (!store.ty.eql(.{ .int = 32 }) or store.attrs.isBarrier()) return null;
    if (!isNamed(store.value, add_name) or !isNamed(store.ptr, loaded_ptr)) return null;
    return add_imm;
}

pub fn genericCfgStructFieldZeroMergeReturn(block: ir.BasicBlock, slot_name: []const u8) bool {
    if (block.instructions.items.len != 2) return false;
    const loaded_ptr = genericCfgLoadPtrFromSlot(block.instructions.items[0], slot_name) orelse return false;
    const load_name = block.instructions.items[1].result orelse return false;
    const load = switch (block.instructions.items[1].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier() or !isNamed(load.ptr, loaded_ptr)) return false;
    const ret = switch (block.terminator orelse return false) {
        .ret => |ret| ret,
        else => return false,
    };
    return ret.ty.eql(.{ .int = 32 }) and isNamed(ret.value orelse return false, load_name);
}

pub fn emitGenericCfgStructFieldZeroUpdatePath(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    ptr_reg: ArgReg,
    add_imm: i32,
) !void {
    try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = ptr_reg });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = add_imm });
    try machine.instructions.append(allocator, .{ .store_eax_arg_ptr = ptr_reg });
    try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = ptr_reg });
    try appendGenericCfgReturn(allocator, machine);
}

pub fn lowerGenericCfgGuardedOptionalPointerBranchReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 32 }) or !function.params.items[1].ty.eql(.ptr)) return false;
    if (function.blocks.items.len != 6) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 1) return false;
    const outer_cond_name = entry.instructions.items[0].result orelse return false;
    const outer_icmp = switch (entry.instructions.items[0].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (!genericCfgSupportsBranchIcmp(function, outer_icmp)) return false;
    const outer_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!outer_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(outer_br.cond, outer_cond_name)) return false;

    const then_block = blockByName(function, outer_br.then_target) orelse return false;
    const else_block = blockByName(function, outer_br.else_target) orelse return false;
    if (then_block.instructions.items.len != 1) return false;
    const guard_cond_name = then_block.instructions.items[0].result orelse return false;
    const guard_icmp = switch (then_block.instructions.items[0].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (guard_icmp.predicate != .ne) return false;
    if (!genericCfgSupportsPointerNullIcmp(function, guard_icmp)) return false;
    const guard_br = switch (then_block.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!guard_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(guard_br.cond, guard_cond_name)) return false;
    const cont_block = blockByName(function, guard_br.then_target) orelse return false;
    const panic_block = blockByName(function, guard_br.else_target) orelse return false;
    if (!genericCfgGuardPanicBlock(panic_block)) return false;

    const merge_name = singleBrTarget(cont_block) orelse return false;
    if (!std.mem.eql(u8, singleBrTarget(else_block) orelse return false, merge_name)) return false;
    const merge_block = blockByName(function, merge_name) orelse return false;
    const phi_binary = genericCfgPhiBinaryReturn(merge_block) orelse return false;

    if (cont_block.instructions.items.len != 1) return false;
    const load_name = cont_block.instructions.items[0].result orelse return false;
    const load = switch (cont_block.instructions.items[0].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
    const ptr_name = switch (load.ptr) {
        .named => |name| name,
        else => return false,
    };
    if ((paramRegOrNull(function, ptr_name, .ptr) catch null) == null) return false;

    var loaded_incoming = false;
    var fallback_value: ?ir.Value = null;
    for (phi_binary.phi.incoming.items) |incoming| {
        if (std.mem.eql(u8, incoming.block, cont_block.name)) {
            if (!isNamed(incoming.value, load_name)) return false;
            loaded_incoming = true;
        } else if (std.mem.eql(u8, incoming.block, else_block.name)) {
            fallback_value = incoming.value;
        } else {
            return false;
        }
    }
    if (!loaded_incoming) return false;
    const fallback = fallback_value orelse return false;

    const outer_branch_kind = try emitGenericCfgIcmpCondition(allocator, machine, function, outer_icmp);
    try appendGenericCfgConditionalBranch(allocator, machine, outer_branch_kind, then_block.name);
    try emitGenericCfgI32ValueIntoEax(allocator, machine, function, else_block, fallback);
    try appendGenericCfgPhiBinaryImmediate(allocator, machine, phi_binary);
    try appendGenericCfgReturn(allocator, machine);

    try appendGenericCfgBlockLabel(allocator, machine, then_block.name);
    const guard_branch_kind = try emitGenericCfgIcmpCondition(allocator, machine, function, guard_icmp);
    try appendGenericCfgConditionalBranch(allocator, machine, guard_branch_kind, cont_block.name);
    try appendGenericCfgBlockLabel(allocator, machine, panic_block.name);
    const panic_call = switch (panic_block.instructions.items[0].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    try appendAlignedDirectCall(allocator, machine, panic_call.callee, .void);
    try machine.instructions.append(allocator, .ud2);

    try appendGenericCfgBlockLabel(allocator, machine, cont_block.name);
    try core_value_emit.emitGenericCfgLoadI32IntoEax(allocator, machine, function, load.ptr);
    try appendGenericCfgPhiBinaryImmediate(allocator, machine, phi_binary);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub fn genericCfgGuardPanicBlock(block: ir.BasicBlock) bool {
    if (block.instructions.items.len == 4) return genericCfgGuardSlicePanicBlock(block);
    if (block.instructions.items.len == 0 or block.instructions.items.len > 2) return false;
    var call_index: usize = 0;
    if (block.instructions.items.len == 2) {
        validateAssumeColdCall(block.instructions.items[0]) catch return false;
        call_index = 1;
    }
    const call = switch (block.instructions.items[call_index].kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.ret_ty != .void or call.callee_value != null or call.inline_asm != null) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;
    if (call.args.items.len == 2) {
        if (call.args.items[0].ty != .ptr) return false;
        if (!call.args.items[1].ty.eql(.{ .int = 64 })) return false;
        switch (call.args.items[0].value) {
            .named => {},
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
        }
        switch (call.args.items[1].value) {
            .int => |int| _ = i64Value(int) catch return false,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
        }
    } else if (call.args.items.len != 0) {
        return false;
    }
    return switch (block.terminator orelse return false) {
        .@"unreachable" => true,
        else => false,
    };
}

fn genericCfgGuardSlicePanicBlock(block: ir.BasicBlock) bool {
    validateAssumeColdCall(block.instructions.items[0]) catch return false;
    const ptr_name = block.instructions.items[1].result orelse return false;
    const len_name = block.instructions.items[2].result orelse return false;
    const ptr_extract = switch (block.instructions.items[1].kind) {
        .extractvalue => |extractvalue| extractvalue,
        else => return false,
    };
    const len_extract = switch (block.instructions.items[2].kind) {
        .extractvalue => |extractvalue| extractvalue,
        else => return false,
    };
    if (!ptr_extract.result_ty.eql(.ptr) or !std.mem.eql(u8, ptr_extract.indices, "0")) return false;
    if (!len_extract.result_ty.eql(.{ .int = 64 }) or !std.mem.eql(u8, len_extract.indices, "1")) return false;
    if (!ptr_extract.aggregate.eql(len_extract.aggregate)) return false;
    _ = globalSymbolNameFromValue(ptr_extract.aggregate) catch return false;

    const call = switch (block.instructions.items[3].kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.ret_ty != .void or call.callee_value != null or call.inline_asm != null) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;
    if (call.args.items.len != 3) return false;
    if (call.args.items[0].ty != .ptr or !isNamed(call.args.items[0].value, ptr_name)) return false;
    if (!call.args.items[1].ty.eql(.{ .int = 64 }) or !isNamed(call.args.items[1].value, len_name)) return false;
    if (call.args.items[2].ty != .ptr) return false;
    return switch (block.terminator orelse return false) {
        .@"unreachable" => true,
        else => false,
    };
}

pub fn lowerGenericCfgGuardedGlobalAddReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 32 })) return false;
    if (function.blocks.items.len != 3 and function.blocks.items.len != 5) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 1) return false;
    const guard_name = entry.instructions.items[0].result orelse return false;
    const guard_icmp = switch (entry.instructions.items[0].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (!genericCfgSupportsNegativeI32Guard(function, guard_icmp)) return false;
    const guard_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!guard_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(guard_br.cond, guard_name)) return false;

    const panic_block = blockByName(function, guard_br.then_target) orelse return false;
    const ok_block = blockByName(function, guard_br.else_target) orelse return false;

    const branch_kind = try emitGenericCfgIcmpCondition(allocator, machine, function, guard_icmp);
    if (branch_kind != .js) return false;
    try appendGenericCfgConditionalBranch(allocator, machine, branch_kind, panic_block.name);

    if (function.blocks.items.len == 3) {
        try emitGenericCfgGlobalAddOkReturn(allocator, machine, function, ok_block);
        try appendGenericCfgBlockLabel(allocator, machine, panic_block.name);
        try emitGenericCfgNoreturnCallBlock(allocator, machine, function, panic_block);
        return true;
    }

    const checked = try genericCfgCheckedGlobalAdd(ok_block);
    try emitGenericCfgGlobalLoadParamAdd(allocator, machine, function, checked.load, checked.call);
    try appendGenericCfgConditionalBranch(allocator, machine, .jo, checked.overflow_target);
    try genericCfgValidateCheckedAddRet(function, checked.ret_target, checked.call_name);
    try appendGenericCfgReturn(allocator, machine);

    try appendGenericCfgBlockLabel(allocator, machine, panic_block.name);
    try emitGenericCfgNoreturnCallBlock(allocator, machine, function, panic_block);

    const overflow_block = blockByName(function, checked.overflow_target) orelse return false;
    try appendGenericCfgBlockLabel(allocator, machine, overflow_block.name);
    try emitGenericCfgNoreturnCallBlock(allocator, machine, function, overflow_block);
    return true;
}

pub fn lowerGenericCfgStackCheckedAddReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 32 })) return false;
    if (function.blocks.items.len != 3) return false;

    const entry = function.blocks.items[0];
    const checked = genericCfgStackCheckedAdd(entry) catch |err| switch (err) {
        error.UnsupportedCodegenInstruction,
        error.UnsupportedCodegenType,
        error.UnsupportedCodegenValue,
        error.BlockWithoutTerminator,
        error.UnsupportedCodegenControlFlow,
        => return false,
    };

    const panic_block = blockByName(function, checked.overflow_target) orelse return error.InvalidBranchTarget;
    const ok_block = blockByName(function, checked.ret_target) orelse return error.InvalidBranchTarget;
    try genericCfgValidateStackCheckedAddRet(ok_block, checked.slot_name);

    try emitGenericCfgCheckedAddIntoEax(allocator, machine, function, checked.call);
    try appendGenericCfgConditionalBranch(allocator, machine, checked.branch_kind, panic_block.name);
    try appendGenericCfgReturn(allocator, machine);

    try appendGenericCfgBlockLabel(allocator, machine, panic_block.name);
    try emitGenericCfgNoreturnCallBlock(allocator, machine, function, panic_block);
    return true;
}

const GenericCfgStackCheckedAdd = struct {
    call: ir.CallInst,
    branch_kind: core_cfg_emit.GenericCfgBranchKind,
    slot_name: []const u8,
    overflow_target: []const u8,
    ret_target: []const u8,
};

fn genericCfgStackCheckedAdd(entry: ir.BasicBlock) !GenericCfgStackCheckedAdd {
    if (entry.instructions.items.len != 6) return error.UnsupportedCodegenInstruction;
    const call_name = entry.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const slot_name = entry.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    const flag_ptr_name = entry.instructions.items[3].result orelse return error.UnsupportedCodegenInstruction;
    const flag_name = entry.instructions.items[4].result orelse return error.UnsupportedCodegenInstruction;
    const cond_name = entry.instructions.items[5].result orelse return error.UnsupportedCodegenInstruction;

    const call = switch (entry.instructions.items[0].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (call.callee_value != null or call.inline_asm != null or call.args.items.len != 2) return error.UnsupportedCodegenInstruction;
    if (!call.ret_ty.eql(.{ .aggregate = "{ i32, i1 }" })) return error.UnsupportedCodegenType;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !call.args.items[1].ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
    const branch_kind: core_cfg_emit.GenericCfgBranchKind = if (isCalleeName(call.callee, "llvm.sadd.with.overflow.i32"))
        .jo
    else if (isCalleeName(call.callee, "llvm.uadd.with.overflow.i32"))
        .jc
    else
        return error.UnsupportedCodegenInstruction;

    const alloca = switch (entry.instructions.items[1].kind) {
        .alloca => |alloca| alloca,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!alloca.allocated_ty.eql(.{ .aggregate = "{ i32, i1 }" })) return error.UnsupportedCodegenType;

    const store = switch (entry.instructions.items[2].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!store.ty.eql(.{ .aggregate = "{ i32, i1 }" }) or !isNamed(store.value, call_name) or !isNamed(store.ptr, slot_name)) {
        return error.UnsupportedCodegenInstruction;
    }

    const flag_gep = switch (entry.instructions.items[3].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!flag_gep.source_ty.eql(.{ .int = 8 }) or !isNamed(flag_gep.ptr, slot_name) or flag_gep.indices.items.len != 1) {
        return error.UnsupportedCodegenInstruction;
    }
    const flag_offset = flag_gep.indices.items[0];
    if (!flag_offset.ty.eql(.{ .int = 64 }) or !isInt(flag_offset.value, 4)) return error.UnsupportedCodegenValue;

    const flag_load = switch (entry.instructions.items[4].kind) {
        .load => |load| load,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!flag_load.ty.eql(.{ .int = 1 }) or flag_load.attrs.isBarrier() or !isNamed(flag_load.ptr, flag_ptr_name)) {
        return error.UnsupportedCodegenInstruction;
    }

    const flag_cmp = switch (entry.instructions.items[5].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (flag_cmp.predicate != .ne or !flag_cmp.operand_ty.eql(.{ .int = 1 }) or
        !isNamed(flag_cmp.lhs, flag_name) or !isInt(flag_cmp.rhs, 0))
    {
        return error.UnsupportedCodegenInstruction;
    }

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, cond_name)) return error.UnsupportedCodegenValue;

    return .{
        .call = call,
        .branch_kind = branch_kind,
        .slot_name = slot_name,
        .overflow_target = condbr.then_target,
        .ret_target = condbr.else_target,
    };
}

fn genericCfgValidateStackCheckedAddRet(ok: ir.BasicBlock, slot_name: []const u8) !void {
    if (ok.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    const load_name = ok.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const load = switch (ok.instructions.items[0].kind) {
        .load => |load| load,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier() or !isNamed(load.ptr, slot_name)) return error.UnsupportedCodegenInstruction;
    const ret = switch (ok.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, load_name)) return error.UnsupportedCodegenValue;
}

fn emitGenericCfgCheckedAddIntoEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    call: ir.CallInst,
) !void {
    const lhs = call.args.items[0].value;
    const rhs = call.args.items[1].value;
    if ((paramValueReg(function, lhs, .{ .int = 32 }) catch null)) |reg| {
        try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
        try emitGenericCfgCheckedAddOperand(allocator, machine, function, rhs);
        return;
    }
    if ((paramValueReg(function, rhs, .{ .int = 32 }) catch null)) |reg| {
        try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
        try emitGenericCfgCheckedAddOperand(allocator, machine, function, lhs);
        return;
    }
    return error.UnsupportedCodegenValue;
}

fn emitGenericCfgCheckedAddOperand(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    value: ir.Value,
) !void {
    if ((paramValueReg(function, value, .{ .int = 32 }) catch null)) |reg| {
        try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = reg } });
        return;
    }
    switch (value) {
        .int => |int| try machine.instructions.append(allocator, .{ .add_eax_imm32 = try i32Value(int) }),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn genericCfgSupportsNegativeI32Guard(function: ir.Function, icmp: ir.IcmpInst) bool {
    if (icmp.predicate != .slt or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isInt(icmp.rhs, 0)) return false;
    return (paramValueReg(function, icmp.lhs, .{ .int = 32 }) catch null) != null;
}

pub fn emitGenericCfgGlobalAddOkReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    ok: ir.BasicBlock,
) !void {
    if (ok.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    const load_name = ok.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const add_name = ok.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    const load = switch (ok.instructions.items[0].kind) {
        .load => |load| load,
        else => return error.UnsupportedCodegenInstruction,
    };
    const add = switch (ok.instructions.items[1].kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
    if (!((isNamed(add.lhs, load_name) and genericCfgSupportsI32ParamValue(function, add.rhs)) or
        (isNamed(add.rhs, load_name) and genericCfgSupportsI32ParamValue(function, add.lhs)))) return error.UnsupportedCodegenValue;
    const ret = switch (ok.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, add_name)) return error.UnsupportedCodegenValue;
    try emitGenericCfgGlobalLoadParamAdd(allocator, machine, function, load, add);
    try appendGenericCfgReturn(allocator, machine);
}

pub const GenericCfgCheckedGlobalAdd = struct {
    load: ir.LoadInst,
    call: ir.CallInst,
    call_name: []const u8,
    overflow_target: []const u8,
    ret_target: []const u8,
};

pub fn genericCfgCheckedGlobalAdd(ok: ir.BasicBlock) !GenericCfgCheckedGlobalAdd {
    if (ok.instructions.items.len != 3) return error.UnsupportedCodegenInstruction;
    const load_name = ok.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const call_name = ok.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    const overflow_name = ok.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    const load = switch (ok.instructions.items[0].kind) {
        .load => |load| load,
        else => return error.UnsupportedCodegenInstruction,
    };
    const call = switch (ok.instructions.items[1].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!isCalleeName(call.callee, "llvm.sadd.with.overflow.i32")) return error.UnsupportedCodegenInstruction;
    if (!call.ret_ty.eql(.{ .aggregate = "{ i32, i1 }" }) or call.args.items.len != 2) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !call.args.items[1].ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
    if (!isNamed(call.args.items[0].value, load_name) and !isNamed(call.args.items[1].value, load_name)) return error.UnsupportedCodegenValue;
    const overflow_extract = switch (ok.instructions.items[2].kind) {
        .extractvalue => |extractvalue| extractvalue,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!overflow_extract.aggregate_ty.eql(.{ .aggregate = "{ i32, i1 }" }) or
        !overflow_extract.result_ty.eql(.{ .int = 1 }) or
        !isNamed(overflow_extract.aggregate, call_name) or
        !std.mem.eql(u8, overflow_extract.indices, "1"))
    {
        return error.UnsupportedCodegenInstruction;
    }
    const overflow_br = switch (ok.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!overflow_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(overflow_br.cond, overflow_name)) return error.UnsupportedCodegenValue;
    return .{
        .load = load,
        .call = call,
        .call_name = call_name,
        .overflow_target = overflow_br.then_target,
        .ret_target = overflow_br.else_target,
    };
}

pub fn genericCfgValidateCheckedAddRet(function: ir.Function, ret_target: []const u8, call_name: []const u8) !void {
    const ret_block = blockByName(function, ret_target) orelse return error.InvalidBranchTarget;
    if (ret_block.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    const value_name = ret_block.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const value_extract = switch (ret_block.instructions.items[0].kind) {
        .extractvalue => |extractvalue| extractvalue,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!value_extract.aggregate_ty.eql(.{ .aggregate = "{ i32, i1 }" }) or
        !value_extract.result_ty.eql(.{ .int = 32 }) or
        !isNamed(value_extract.aggregate, call_name) or
        !std.mem.eql(u8, value_extract.indices, "0"))
    {
        return error.UnsupportedCodegenInstruction;
    }
    const ret = switch (ret_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, value_name)) return error.UnsupportedCodegenValue;
}

pub fn emitGenericCfgGlobalLoadParamAdd(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    load: ir.LoadInst,
    add: anytype,
) !void {
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return error.UnsupportedCodegenInstruction;
    const global_name = try globalSymbolNameFromValue(load.ptr);
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = global_name });

    if (@TypeOf(add) == ir.BinaryInst) {
        const arg = if (isNamed(add.lhs, "zig_k"))
            add.rhs
        else if (isNamed(add.rhs, "zig_k"))
            add.lhs
        else if ((paramValueReg(function, add.lhs, .{ .int = 32 }) catch null) != null)
            add.lhs
        else
            add.rhs;
        try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = try paramValueReg(function, arg, .{ .int = 32 }) } });
        return;
    }

    const arg = if (isNamed(add.args.items[0].value, "zig_k"))
        add.args.items[1].value
    else if (isNamed(add.args.items[1].value, "zig_k"))
        add.args.items[0].value
    else if ((paramValueReg(function, add.args.items[0].value, .{ .int = 32 }) catch null) != null)
        add.args.items[0].value
    else
        add.args.items[1].value;
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = try paramValueReg(function, arg, .{ .int = 32 }) } });
}

pub fn genericCfgSupportsI32ParamValue(function: ir.Function, value: ir.Value) bool {
    return (paramValueReg(function, value, .{ .int = 32 }) catch null) != null;
}

pub fn emitGenericCfgNoreturnCallBlock(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
) !void {
    if (block.instructions.items.len >= 4) {
        if (validateNoreturnSliceRuntimeCall(block)) |call| {
            try emitSlicePointerIntoRdi(allocator, machine, function, block, call.args.items[0].value);
            try emitSliceLengthIntoRsi(allocator, machine, function, block, call.args.items[1].value);
            try appendAlignedDirectCall(allocator, machine, call.callee, .void);
            try machine.instructions.append(allocator, .ud2);
            return;
        } else |err| switch (err) {
            error.UnsupportedCodegenInstruction,
            error.UnsupportedCodegenType,
            error.UnsupportedCodegenValue,
            error.BlockWithoutTerminator,
            error.UnsupportedCodegenControlFlow,
            => {},
            else => return err,
        }
    }

    if (block.instructions.items.len == 0 or block.instructions.items.len > 2) return error.UnsupportedCodegenInstruction;
    var call_index: usize = 0;
    if (block.instructions.items.len == 2) {
        try validateAssumeColdCall(block.instructions.items[0]);
        call_index = 1;
    }
    const call = switch (block.instructions.items[call_index].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (call.callee_value != null or call.inline_asm != null or call.ret_ty != .void) return error.UnsupportedCodegenInstruction;
    if (!callIsFastcc(call.calling_conv)) try validateDefaultCallConv(call.calling_conv);
    switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .@"unreachable" => {},
        else => return error.UnsupportedCodegenControlFlow,
    }

    if (call.args.items.len == 2) {
        try validateSliceRuntimeCallArgs(call);
        try emitSlicePointerIntoRdi(allocator, machine, function, block, call.args.items[0].value);
        try emitSliceLengthIntoRsi(allocator, machine, function, block, call.args.items[1].value);
    } else if (call.args.items.len != 0) {
        return error.UnsupportedCodegenInstruction;
    }
    try appendAlignedDirectCall(allocator, machine, call.callee, .void);
    try machine.instructions.append(allocator, .ud2);
}

pub fn validateNoreturnSliceRuntimeCall(block: ir.BasicBlock) !ir.CallInst {
    if (block.instructions.items.len == 0) return error.UnsupportedCodegenInstruction;
    if (block.instructions.items.len > 1) {
        validateAssumeColdCall(block.instructions.items[0]) catch |err| switch (err) {
            error.UnsupportedCodegenInstruction, error.UnsupportedCodegenValue => {},
        };
    }
    const call_instruction = block.instructions.items[block.instructions.items.len - 1];
    const call = switch (call_instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (call.callee_value != null or call.inline_asm != null or call.ret_ty != .void) return error.UnsupportedCodegenInstruction;
    if (!callIsFastcc(call.calling_conv)) try validateDefaultCallConv(call.calling_conv);
    try validateSliceRuntimeCallArgs(call);
    if (call.args.items.len == 3 and call.args.items[2].ty != .ptr) return error.UnsupportedCodegenType;
    _ = try resolveSlicePointerValue(block, call.args.items[0].value);
    switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .@"unreachable" => {},
        else => return error.UnsupportedCodegenControlFlow,
    }
    return call;
}

fn validateSliceRuntimeCallArgs(call: ir.CallInst) !void {
    if (call.args.items.len != 2 and call.args.items.len != 3) return error.UnsupportedCodegenInstruction;
    if (call.args.items[0].ty != .ptr) return error.UnsupportedCodegenType;
    if (!call.args.items[1].ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
}

pub const SlicePointerValue = union(enum) {
    global: []const u8,
    materialize: ir.Value,
};

pub fn resolveSlicePointerValue(block: ir.BasicBlock, value: ir.Value) !SlicePointerValue {
    switch (value) {
        .named => |name| {
            if (std.mem.startsWith(u8, name, "@")) return .{ .global = try globalSymbolName(name) };
            const instruction = findInstruction(block, name) orelse return error.UnsupportedCodegenValue;
            const extract = switch (instruction.kind) {
                .extractvalue => |extractvalue| extractvalue,
                else => return error.UnsupportedCodegenInstruction,
            };
            if (!extract.result_ty.eql(.ptr) or !std.mem.eql(u8, extract.indices, "0")) return error.UnsupportedCodegenInstruction;
            if (resolveSlicePointerFromInsertedAggregate(block, extract.aggregate)) |resolved| return resolved;
            return .{ .global = try globalSymbolNameFromValue(extract.aggregate) };
        },
        .constant_expr => return .{ .global = try globalSymbolNameFromValue(value) },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
    }
}

fn resolveSlicePointerFromInsertedAggregate(block: ir.BasicBlock, aggregate: ir.Value) ?SlicePointerValue {
    const aggregate_name = switch (aggregate) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const len_insert = findInstruction(block, aggregate_name) orelse return null;
    const len_insertvalue = switch (len_insert.kind) {
        .insertvalue => |insertvalue| insertvalue,
        else => return null,
    };
    if (!std.mem.eql(u8, len_insertvalue.indices, "1")) return null;
    const ptr_insert_name = switch (len_insertvalue.aggregate) {
        .named => |name| name,
        .undef => return null,
        .int, .fp, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const ptr_insert = findInstruction(block, ptr_insert_name) orelse return null;
    const ptr_insertvalue = switch (ptr_insert.kind) {
        .insertvalue => |insertvalue| insertvalue,
        else => return null,
    };
    if (!std.mem.eql(u8, ptr_insertvalue.indices, "0") or !ptr_insertvalue.value_ty.eql(.ptr)) return null;
    if (globalSymbolNameFromValue(ptr_insertvalue.value)) |symbol| return .{ .global = symbol } else |_| {}
    return switch (ptr_insertvalue.value) {
        .named => .{ .materialize = ptr_insertvalue.value },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
    };
}

pub fn resolveSliceLengthValue(function: ir.Function, block: ir.BasicBlock, value: ir.Value) anyerror!SliceLengthValue {
    switch (value) {
        .int => |int| return .{ .imm = try i64Value(int) },
        .named => |name| {
            if (paramRegOrNull(function, name, .{ .int = 64 }) catch null) |reg| return .{ .reg = reg };
            const instruction = findInstructionInFunction(function, block, name) orelse return error.UnsupportedCodegenValue;
            switch (instruction.kind) {
                .extractvalue => |extract| {
                    if (!extract.result_ty.eql(.{ .int = 64 }) or !std.mem.eql(u8, extract.indices, "1")) return error.UnsupportedCodegenInstruction;
                    if (try resolveSliceLengthFromInsertedAggregate(function, block, extract.aggregate)) |len| return len;
                    return .{ .imm = try sliceLengthFromAggregateConstant(extract.aggregate) };
                },
                .cast, .load, .binary => return .{ .materialize = value },
                .phi => |phi| {
                    if (!phi.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
                    return .{ .materialize = value };
                },
                else => return error.UnsupportedCodegenInstruction,
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

fn resolveSliceLengthFromInsertedAggregate(function: ir.Function, block: ir.BasicBlock, aggregate: ir.Value) anyerror!?SliceLengthValue {
    const aggregate_name = switch (aggregate) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const instruction = findInstructionInFunction(function, block, aggregate_name) orelse return null;
    switch (instruction.kind) {
        .insertvalue => |insert| {
            if (!std.mem.eql(u8, insert.indices, "1") or !insert.value_ty.eql(.{ .int = 64 })) return null;
            return try resolveSliceLengthValue(function, block, insert.value);
        },
        .load => |load| {
            if (!load.ty.eql(.{ .aggregate = "{ ptr, i64 }" }) or load.attrs.isBarrier()) return null;
            const slot_name = switch (load.ptr) {
                .named => |slot| slot,
                .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
            };
            const stored = storedValueInFunction(function, block, slot_name, .{ .aggregate = "{ ptr, i64 }" }) orelse return null;
            return try resolveSliceLengthFromInsertedAggregate(function, block, stored);
        },
        else => return null,
    }
}

fn storedValueInFunction(function: ir.Function, preferred_block: ir.BasicBlock, slot_name: []const u8, ty: ir.Type) ?ir.Value {
    if (storedValueInBlock(preferred_block, slot_name, ty)) |value| return value;
    for (function.blocks.items) |block| {
        if (std.mem.eql(u8, block.name, preferred_block.name)) continue;
        if (storedValueInBlock(block, slot_name, ty)) |value| return value;
    }
    return null;
}

fn storedValueInBlock(block: ir.BasicBlock, slot_name: []const u8, ty: ir.Type) ?ir.Value {
    for (block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        const store = switch (instruction.kind) {
            .store => |store| store,
            else => continue,
        };
        if (!store.ty.eql(ty) or store.attrs.isBarrier() or !isNamed(store.ptr, slot_name)) continue;
        return store.value;
    }
    return null;
}

pub const SliceLengthValue = union(enum) {
    imm: i64,
    reg: ArgReg,
    materialize: ir.Value,
};

pub fn emitSlicePointerIntoRdi(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    value: ir.Value,
) !void {
    switch (try resolveSlicePointerValue(block, value)) {
        .global => |symbol| try machine.instructions.append(allocator, .{ .lea_global_rdi = symbol }),
        .materialize => |materialized| try emitPointerValueIntoArgReg(allocator, machine, function, block, .rdi, materialized),
    }
}

pub fn emitSliceLengthIntoRsi(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    value: ir.Value,
) !void {
    switch (try resolveSliceLengthValue(function, block, value)) {
        .imm => |len| try appendMoveImmToArgReg(allocator, machine, .rsi, len),
        .reg => |reg| if (reg != .rsi) try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = .rsi, .src = reg } }),
        .materialize => |materialized| try emitI64ValueIntoArgReg(allocator, machine, function, block, .rsi, materialized),
    }
}

pub fn emitI64ValueIntoArgReg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    dst: ArgReg,
    value: ir.Value,
) anyerror!void {
    switch (value) {
        .int => |int| return try appendMoveImmToArgReg(allocator, machine, dst, try i64Value(int)),
        .named => |name| {
            if (try emitNamedI64ValueIntoArgReg(allocator, machine, function, block, dst, name)) return;
            return error.UnsupportedCodegenValue;
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn emitNamedI64ValueIntoArgReg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    dst: ArgReg,
    name: []const u8,
) anyerror!bool {
    if (paramRegOrNull(function, name, .{ .int = 64 }) catch null) |reg| {
        if (reg != dst) try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = dst, .src = reg } });
        return true;
    }
    const instruction = findInstructionInFunction(function, block, name) orelse return false;
    switch (instruction.kind) {
        .cast => |cast| {
            if (cast.op != .bitcast or !cast.from_ty.eql(.{ .int = 64 }) or !cast.to_ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenInstruction;
            try emitI64ValueIntoArgReg(allocator, machine, function, block, dst, cast.value);
            return true;
        },
        .load => |load| {
            try emitLoadedI64IntoArgReg(allocator, machine, function, dst, load);
            return true;
        },
        .binary => |binary| {
            try emitComputedI64IntoArgReg(allocator, machine, function, block, dst, binary);
            return true;
        },
        .select => |select| {
            try emitSelectedI64IntoArgReg(allocator, machine, function, block, dst, name, select);
            return true;
        },
        .phi => |phi| {
            try emitPhiSelectedI64IntoArgReg(allocator, machine, function, block, dst, phi);
            return true;
        },
        .extractvalue => |extract| {
            if (!extract.result_ty.eql(.{ .int = 64 }) or !std.mem.eql(u8, extract.indices, "1")) return error.UnsupportedCodegenInstruction;
            if (try resolveSliceLengthFromInsertedAggregate(function, block, extract.aggregate)) |len| {
                switch (len) {
                    .imm => |imm| try appendMoveImmToArgReg(allocator, machine, dst, imm),
                    .reg => |reg| if (reg != dst) try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = dst, .src = reg } }),
                    .materialize => |materialized| try emitI64ValueIntoArgReg(allocator, machine, function, block, dst, materialized),
                }
                return true;
            }
            try appendMoveImmToArgReg(allocator, machine, dst, try sliceLengthFromAggregateConstant(extract.aggregate));
            return true;
        },
        else => return error.UnsupportedCodegenInstruction,
    }
}

fn emitPointerValueIntoArgReg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    dst: ArgReg,
    value: ir.Value,
) anyerror!void {
    switch (value) {
        .named => |name| {
            if (paramRegOrNull(function, name, .ptr) catch null) |reg| {
                if (reg != dst) try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = dst, .src = reg } });
                return;
            }
            const instruction = findInstructionInFunction(function, block, name) orelse return error.UnsupportedCodegenValue;
            switch (instruction.kind) {
                .load => |load| {
                    try emitLoadedPointerIntoArgReg(allocator, machine, function, dst, load);
                    return;
                },
                .cast => |cast| {
                    if (cast.op != .bitcast or cast.to_ty != .ptr) return error.UnsupportedCodegenInstruction;
                    try emitPointerValueIntoArgReg(allocator, machine, function, block, dst, cast.value);
                    return;
                },
                .extractvalue => {
                    switch (try resolveSlicePointerValue(block, value)) {
                        .global => |symbol| {
                            if (dst != .rdi) return error.UnsupportedCodegenAbi;
                            try machine.instructions.append(allocator, .{ .lea_global_rdi = symbol });
                        },
                        .materialize => |materialized| try emitPointerValueIntoArgReg(allocator, machine, function, block, dst, materialized),
                    }
                    return;
                },
                else => return error.UnsupportedCodegenInstruction,
            }
        },
        .constant_expr => {
            if (dst != .rdi) return error.UnsupportedCodegenAbi;
            try machine.instructions.append(allocator, .{ .lea_global_rdi = try globalSymbolNameFromValue(value) });
        },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
    }
}

fn emitLoadedPointerIntoArgReg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    dst: ArgReg,
    load: ir.LoadInst,
) anyerror!void {
    if (load.ty != .ptr or load.attrs.isBarrier()) return error.UnsupportedCodegenInstruction;
    switch (load.ptr) {
        .named => |name| {
            if (paramRegOrNull(function, name, .ptr) catch null) |reg| {
                try machine.instructions.append(allocator, .{ .load_arg_ptr_disp8_rax = .{ .reg = reg, .offset = 0 } });
            } else if (std.mem.startsWith(u8, name, "@")) {
                try machine.instructions.append(allocator, .{ .load_global_ptr_rax = try globalSymbolName(name) });
            } else {
                return error.UnsupportedCodegenValue;
            }
        },
        .constant_expr => try machine.instructions.append(allocator, .{ .load_global_ptr_rax = try globalSymbolNameFromValue(load.ptr) }),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
    }
    try emitRaxIntoArgReg(allocator, machine, dst);
}

pub fn emitLoadedI64IntoArgReg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    dst: ArgReg,
    load: ir.LoadInst,
) anyerror!void {
    if (!load.ty.eql(.{ .int = 64 }) or load.attrs.isBarrier()) return error.UnsupportedCodegenInstruction;
    switch (load.ptr) {
        .named => |name| {
            if (paramRegOrNull(function, name, .ptr) catch null) |reg| {
                try machine.instructions.append(allocator, .{ .load_arg_ptr_disp8_rax = .{ .reg = reg, .offset = 0 } });
            } else if (std.mem.startsWith(u8, name, "@")) {
                try machine.instructions.append(allocator, .{ .load_global_ptr_rax = try globalSymbolName(name) });
            } else {
                return error.UnsupportedCodegenValue;
            }
        },
        .constant_expr => try machine.instructions.append(allocator, .{ .load_global_ptr_rax = try globalSymbolNameFromValue(load.ptr) }),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
    }
    try emitRaxIntoArgReg(allocator, machine, dst);
}

fn emitSelectedI64IntoArgReg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    dst: ArgReg,
    result_name: []const u8,
    select: ir.SelectInst,
) anyerror!void {
    _ = result_name;
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenInstruction;
    const cond_reg = paramValueReg(function, select.cond, .{ .int = 1 }) catch return error.UnsupportedCodegenValue;
    const true_label = "generic_cfg_i64_select_true";
    const end_label = "generic_cfg_i64_select_end";
    try machine.instructions.append(allocator, .{ .test_arg8 = cond_reg });
    try appendGenericCfgConditionalBranch(allocator, machine, .jne, true_label);
    try emitI64ValueIntoArgReg(allocator, machine, function, block, dst, select.false_value);
    try machine.instructions.append(allocator, .{ .jmp = end_label });
    try appendGenericCfgBlockLabel(allocator, machine, true_label);
    try emitI64ValueIntoArgReg(allocator, machine, function, block, dst, select.true_value);
    try appendGenericCfgBlockLabel(allocator, machine, end_label);
}

pub fn emitComputedI64IntoArgReg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    dst: ArgReg,
    binary: ir.BinaryInst,
) anyerror!void {
    if (!binary.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
    switch (binary.op) {
        .add => {
            try emitGenericCfgI64ValueIntoRax(allocator, machine, function, block, binary.lhs);
            switch (binary.rhs) {
                .int => |int| {
                    const rhs = try i64Value(int);
                    if (rhs < 0 or rhs > std.math.maxInt(u8)) return error.UnsupportedCodegenValue;
                    if (rhs != 0) try machine.instructions.append(allocator, .{ .add_rax_imm8 = @intCast(rhs) });
                },
                .named => |name| {
                    const reg = (paramRegOrNull(function, name, .{ .int = 64 }) catch null) orelse return error.UnsupportedCodegenValue;
                    try machine.instructions.append(allocator, .{ .add_arg64_rax = reg });
                },
                .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
            }
        },
        .sub => {
            const rhs = switch (binary.rhs) {
                .int => |int| try i64Value(int),
                .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
            };
            if (rhs != 0) return error.UnsupportedCodegenInstruction;
            try emitI64ValueIntoArgReg(allocator, machine, function, block, dst, binary.lhs);
            return;
        },
        else => return error.UnsupportedCodegenInstruction,
    }
    try emitRaxIntoArgReg(allocator, machine, dst);
}

fn emitPhiSelectedI64IntoArgReg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    dst: ArgReg,
    phi: ir.PhiInst,
) anyerror!void {
    if (phi.incoming.items.len != 1) return error.UnsupportedCodegenControlFlow;
    try emitI64ValueIntoArgReg(allocator, machine, function, block, dst, phi.incoming.items[0].value);
}

fn emitRaxIntoArgReg(allocator: std.mem.Allocator, machine: *MachineFunction, dst: ArgReg) !void {
    switch (dst) {
        .rdi => try machine.instructions.append(allocator, .mov_rax_rdi),
        .rsi => try machine.instructions.append(allocator, .mov_rax_rsi),
        .rdx, .rcx, .r8, .r9 => return error.UnsupportedCodegenAbi,
    }
}

fn findInstructionInFunction(function: ir.Function, preferred_block: ir.BasicBlock, result_name: []const u8) ?ir.Instruction {
    if (findInstruction(preferred_block, result_name)) |instruction| return instruction;
    for (function.blocks.items) |candidate_block| {
        if (std.mem.eql(u8, candidate_block.name, preferred_block.name)) continue;
        if (findInstruction(candidate_block, result_name)) |instruction| return instruction;
    }
    return null;
}

fn sliceLengthFromAggregateConstant(value: ir.Value) !i64 {
    const text = switch (value) {
        .constant_expr => |text| text,
        .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
    };
    const marker = "i64 ";
    const start_marker = std.mem.lastIndexOf(u8, text, marker) orelse return error.UnsupportedCodegenValue;
    var start = start_marker + marker.len;
    while (start < text.len and text[start] == ' ') : (start += 1) {}
    var end = start;
    while (end < text.len and (std.ascii.isDigit(text[end]) or text[end] == '-')) : (end += 1) {}
    if (end == start) return error.UnsupportedCodegenValue;
    return std.fmt.parseInt(i64, text[start..end], 10) catch return error.UnsupportedCodegenValue;
}

pub fn appendGenericCfgPhiBinaryImmediate(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    phi_binary: GenericCfgPhiBinaryReturn,
) !void {
    switch (phi_binary.op) {
        .add => try machine.instructions.append(allocator, .{ .add_eax_imm32 = phi_binary.imm }),
        .sub => try machine.instructions.append(allocator, .{ .add_eax_imm32 = -phi_binary.imm }),
        else => return error.UnsupportedCodegenInstruction,
    }
}

pub fn lowerGenericCfgBranchMergeReturn(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.blocks.items.len != 4) return false;
    const entry = function.blocks.items[0];
    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 })) return false;
    const then_index = blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget;
    const else_index = blockIndex(function, condbr.else_target) orelse return error.InvalidBranchTarget;
    const then_block = function.blocks.items[then_index];
    const else_block = function.blocks.items[else_index];
    const then_target = singleBrTarget(then_block) orelse return false;
    const else_target = singleBrTarget(else_block) orelse return false;
    if (!std.mem.eql(u8, then_target, else_target)) return false;
    const merge_index = blockIndex(function, then_target) orelse return error.InvalidBranchTarget;
    const merge_block = function.blocks.items[merge_index];
    if (!genericCfgSupportsBranchMergeBlock(function, entry, then_block, else_block, merge_block)) return false;

    try emitGenericCfgConditionTrueBranch(allocator, machine, function, entry, condbr.cond, then_block.name);
    try emitGenericCfgBranchPathReturn(allocator, machine, function, else_block, merge_block);
    try appendGenericCfgBlockLabel(allocator, machine, then_block.name);
    try emitGenericCfgBranchPathReturn(allocator, machine, function, then_block, merge_block);
    return true;
}

pub fn lowerGenericCfgTerminalBranchReturn(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) and !function.ret_ty.eql(.{ .int = 64 })) return false;
    if (function.blocks.items.len < 3 or function.blocks.items.len > 4) return false;
    if (try lowerGenericCfgErrorUnionPayloadBranchReturn(allocator, machine, function)) return true;
    const entry = function.blocks.items[0];
    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 })) return false;
    const then_index = blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget;
    const else_index = blockIndex(function, condbr.else_target) orelse return error.InvalidBranchTarget;
    const then_block = function.blocks.items[then_index];
    const else_block = function.blocks.items[else_index];
    if (!genericCfgTerminalBranchExtraBlocksAreUnreachable(function, then_index, else_index)) return false;
    if (!genericCfgSupportsTerminalReturnBlock(function, entry, then_block)) return false;
    if (!genericCfgSupportsTerminalReturnBlock(function, entry, else_block)) return false;

    if (terminalCondParamReg(function, condbr.cond)) |cond_reg| {
        try machine.instructions.append(allocator, .{ .test_arg8 = cond_reg });
        try appendGenericCfgConditionalBranch(allocator, machine, .je, else_block.name);
        try appendGenericCfgBlockLabel(allocator, machine, then_block.name);
        try emitGenericCfgTerminalReturnBlock(allocator, machine, function, entry, then_block);
        try appendGenericCfgBlockLabel(allocator, machine, else_block.name);
        try emitGenericCfgTerminalReturnBlock(allocator, machine, function, entry, else_block);
        return true;
    }

    try emitGenericCfgTerminalConditionTrueBranch(allocator, machine, function, entry, entry, condbr.cond, then_block.name);
    try emitGenericCfgTerminalReturnBlock(allocator, machine, function, entry, else_block);
    try appendGenericCfgBlockLabel(allocator, machine, then_block.name);
    try emitGenericCfgTerminalReturnBlock(allocator, machine, function, entry, then_block);
    return true;
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

fn terminalConstI32Return(block: ir.BasicBlock) ?i32 {
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

pub fn lowerGenericCfgLinearTerminalBranchReturn(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) and !function.ret_ty.eql(.{ .int = 64 })) return false;
    if (try lowerGenericCfgLinearErrorUnionTryChainReturn(allocator, machine, function)) return true;
    if (try lowerGenericCfgErrorUnionTrySwitchReturn(allocator, machine, function)) return true;
    if (try lowerGenericCfgErrorUnionSwitchPhiReturn(allocator, machine, function)) return true;
    if (try lowerGenericCfgErrorUnionErrorTagSwitchReturn(allocator, machine, function)) return true;
    if (try lowerGenericCfgErrorUnionCatchSwitchReturn(allocator, machine, function)) return true;
    if (try lowerGenericCfgErrorUnionTrySlotUpdateReturn(allocator, machine, function)) return true;
    if (try lowerGenericCfgErrorUnionTryPayloadBranchReturn(allocator, machine, function)) return true;
    if (try lowerGenericCfgBranchBothErrorUnionTryReturn(allocator, machine, function)) return true;
    if (try lowerGenericCfgBranchThenErrorUnionTryReturn(allocator, machine, function)) return true;
    if (try lowerGenericCfgSwitchBothErrorUnionTryReturn(allocator, machine, function)) return true;
    if (try lowerGenericCfgSwitchThenErrorUnionTryReturn(allocator, machine, function)) return true;
    if (function.blocks.items.len < 5) return false;
    const entry = function.blocks.items[0];
    const entry_condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_condbr.cond_ty.eql(.{ .int = 1 })) return false;

    const then_index = blockIndex(function, entry_condbr.then_target) orelse return error.InvalidBranchTarget;
    const else_index = blockIndex(function, entry_condbr.else_target) orelse return error.InvalidBranchTarget;
    const then_block = function.blocks.items[then_index];
    const else_block = function.blocks.items[else_index];
    const then_is_cont = blockHasCondbr(then_block);
    const else_is_cont = blockHasCondbr(else_block);
    if (then_is_cont == else_is_cont) return false;

    const continuation_index = if (then_is_cont) then_index else else_index;
    const first_return_index = if (then_is_cont) else_index else then_index;
    const continuation = function.blocks.items[continuation_index];
    const first_return = function.blocks.items[first_return_index];
    const continuation_condbr = switch (continuation.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!continuation_condbr.cond_ty.eql(.{ .int = 1 })) return false;
    if (!genericCfgSupportsTerminalReturnBlock(function, entry, first_return)) return false;

    const second_then_index = blockIndex(function, continuation_condbr.then_target) orelse return error.InvalidBranchTarget;
    const second_else_index = blockIndex(function, continuation_condbr.else_target) orelse return error.InvalidBranchTarget;
    if (second_then_index == 0 or second_else_index == 0 or
        second_then_index == continuation_index or second_else_index == continuation_index or
        second_then_index == first_return_index or second_else_index == first_return_index)
    {
        return false;
    }
    const second_then = function.blocks.items[second_then_index];
    const second_else = function.blocks.items[second_else_index];
    if (!genericCfgSupportsNestedTerminalReturnBlock(function, entry, continuation, second_then)) return false;
    if (!genericCfgSupportsNestedTerminalReturnBlock(function, entry, continuation, second_else)) return false;
    if (!linearTerminalBranchUsesAllBlocks(function, continuation_index, first_return_index, second_then_index, second_else_index)) return false;

    if (then_is_cont) {
        try emitGenericCfgTerminalConditionTrueBranch(allocator, machine, function, entry, entry, entry_condbr.cond, continuation.name);
        try emitGenericCfgTerminalReturnBlock(allocator, machine, function, entry, first_return);
        try appendGenericCfgBlockLabel(allocator, machine, continuation.name);
        try emitGenericCfgNestedTerminalBranch(
            allocator,
            machine,
            function,
            entry,
            continuation,
            continuation_condbr.cond,
            continuation_condbr.then_target,
            continuation_condbr.else_target,
        );
    } else {
        try emitGenericCfgTerminalConditionTrueBranch(allocator, machine, function, entry, entry, entry_condbr.cond, first_return.name);
        try appendGenericCfgBlockLabel(allocator, machine, continuation.name);
        try emitGenericCfgNestedTerminalBranch(
            allocator,
            machine,
            function,
            entry,
            continuation,
            continuation_condbr.cond,
            continuation_condbr.then_target,
            continuation_condbr.else_target,
        );
        try appendGenericCfgBlockLabel(allocator, machine, first_return.name);
        try emitGenericCfgTerminalReturnBlock(allocator, machine, function, entry, first_return);
    }
    return true;
}

const ErrorUnionSwitchPhiCase = struct {
    value: i32,
    block: ir.BasicBlock,
    incoming: ir.Value,
};

const ErrorUnionSwitchPhiReturn = struct {
    entry: ir.BasicBlock,
    tag_reg: ArgReg,
    cases: [8]ErrorUnionSwitchPhiCase,
    case_count: usize,
    default_block: ir.BasicBlock,
    default_incoming: ir.Value,
};

const ErrorUnionErrorTagSwitchReturn = struct {
    entry: ir.BasicBlock,
    call_name: []const u8,
    call: ir.CallInst,
    payload_block: ir.BasicBlock,
    payload_return: ErrorUnionI32ReturnValue,
    switch_block: ir.BasicBlock,
    cases: [8]ErrorUnionSwitchPhiCase,
    case_count: usize,
    default_block: ir.BasicBlock,
    merge_block: ir.BasicBlock,
    live_param_reg: ?ArgReg,
};

const ErrorUnionI32ReturnValue = union(enum) {
    generic: ir.Value,
    payload_add_imm: i32,
    payload_binary: PayloadBinaryWrapReturn,
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

fn lowerGenericCfgErrorUnionSwitchPhiReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = errorUnionSwitchPhiReturn(function) orelse return false;
    try machine.instructions.append(allocator, .{ .mov_arg_eax = plan.tag_reg });
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

fn errorUnionSwitchPhiReturn(function: ir.Function) ?ErrorUnionSwitchPhiReturn {
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.blocks.items.len < 4) return null;
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 0) return null;
    const switch_term = blockSwitchTerminator(entry) orelse return null;
    if (!switch_term.cond_ty.eql(.{ .int = 32 })) return null;
    const tag_reg = switch (switch_term.cond) {
        .named => |name| paramRegOrNull(function, name, .{ .int = 32 }) catch return null,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    } orelse return null;
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
        .tag_reg = tag_reg,
        .cases = cases,
        .case_count = switch_term.cases.items.len,
        .default_block = default_block,
        .default_incoming = phiIncomingForBlock(phi, default_block.name) orelse return null,
    };
}

fn lowerGenericCfgErrorUnionErrorTagSwitchReturn(
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
        try emitErrorUnionI32ReturnValueIntoEax(allocator, machine, function, plan.entry, case.block, .{ .generic = case.incoming }, plan.live_param_reg);
        try machine.instructions.append(allocator, .{ .jmp = epilogue_label });
    }

    try appendGenericCfgBlockLabel(allocator, machine, plan.payload_block.name);
    try emitErrorUnionI32ReturnValueIntoEax(allocator, machine, function, plan.entry, plan.payload_block, plan.payload_return, plan.live_param_reg);
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);

    try appendGenericCfgBlockLabel(allocator, machine, plan.default_block.name);
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerGenericCfgErrorUnionCatchSwitchReturn(
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
    if (!supportsDirectI64Call(call) or call.args.items.len != 2) return null;

    const then_block = function.blocks.items[blockIndex(function, entry_condbr.then_target) orelse return null];
    const else_block = function.blocks.items[blockIndex(function, entry_condbr.else_target) orelse return null];
    const then_payload_return = errorUnionPayloadI32Return(function, then_block, call_name);
    const else_payload_return = errorUnionPayloadI32Return(function, else_block, call_name);
    if ((then_payload_return != null) == (else_payload_return != null)) return null;
    const payload_block = if (then_payload_return != null) then_block else else_block;
    const switch_block = if (then_payload_return != null) else_block else then_block;
    const payload_return = then_payload_return orelse else_payload_return.?;

    const switch_term = blockSwitchTerminator(switch_block) orelse return null;
    if (!switch_term.cond_ty.eql(.{ .int = 16 })) return null;
    if (!errorTagValueFromCallResult(switch_block, switch_term.cond, call_name)) return null;
    if (switch_term.cases.items.len == 0 or switch_term.cases.items.len > 8) return null;
    const merge_block = exhaustiveSwitchMergeBlock(function, switch_term) orelse return null;
    const phi = firstPhiReturn(function, merge_block) orelse return null;
    if (!phi.ty.eql(.{ .int = 32 })) return null;

    var cases: [8]ErrorUnionSwitchPhiCase = undefined;
    var live_param_reg = errorUnionI32ReturnLiveParam(function, payload_block, payload_return);
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
    if (!errorTagSwitchUsesAllBlocks(function, payload_block.name, switch_block.name, merge_block.name, switch_term)) return null;

    return .{
        .entry = entry,
        .call_name = call_name,
        .call = call,
        .payload_block = payload_block,
        .payload_return = payload_return,
        .switch_block = switch_block,
        .cases = cases,
        .case_count = switch_term.cases.items.len,
        .default_block = default_block,
        .merge_block = merge_block,
        .live_param_reg = live_param_reg,
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

fn errorUnionPayloadI32Return(function: ir.Function, block: ir.BasicBlock, call_name: []const u8) ?ErrorUnionI32ReturnValue {
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

fn payloadAddWrapReturnFromCallResult(block: ir.BasicBlock, call_name: []const u8) ?u8 {
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 64 })) return null;
    return payloadAddWrapValue(block, block, ret.value orelse return null, call_name);
}

fn errorUnionPayloadAddReturn(block: ir.BasicBlock, call_name: []const u8) ?i32 {
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return null;
    const ret_value = ret.value orelse return null;
    if (payloadValueFromCallResult(block, ret_value, call_name)) return 0;
    const add_name = switch (ret_value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    return payloadAddFromCallResult(block, add_name, call_name) orelse return null;
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

fn errorUnionI32ReturnLiveParam(function: ir.Function, block: ir.BasicBlock, value: ErrorUnionI32ReturnValue) ?ArgReg {
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

fn mergeLiveParam(existing: *?ArgReg, candidate: ?ArgReg) bool {
    const candidate_reg = candidate orelse return true;
    if (existing.*) |existing_reg| return existing_reg == candidate_reg;
    existing.* = candidate_reg;
    return true;
}

fn emitErrorUnionI32ReturnValueIntoEax(
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

fn errorTagValueFromCallResult(block: ir.BasicBlock, value: ir.Value, call_name: []const u8) bool {
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

fn exhaustiveSwitchMergeBlock(function: ir.Function, switch_term: ir.SwitchTerminator) ?ir.BasicBlock {
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

fn errorTagSwitchUsesAllBlocks(
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

fn phiIncomingForBlock(phi: ir.PhiInst, block_name: []const u8) ?ir.Value {
    for (phi.incoming.items) |incoming| {
        if (std.mem.eql(u8, incoming.block, block_name)) return incoming.value;
    }
    return null;
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

fn lowerGenericCfgErrorUnionTrySwitchReturn(
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

fn lowerGenericCfgLinearErrorUnionTryChainReturn(
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

fn lowerGenericCfgBranchBothErrorUnionTryReturn(
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

fn lowerGenericCfgBranchThenErrorUnionTryReturn(
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

fn lowerGenericCfgSwitchThenErrorUnionTryReturn(
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

fn lowerGenericCfgSwitchBothErrorUnionTryReturn(
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
            .add_imm = payloadAddWrapPhiIncoming(function, switch_block, merge_block, phi, block.name, call_name) orelse return null,
        };
    }
    const default_block = function.blocks.items[blockIndex(function, switch_term.default_target) orelse return null];
    if (!blockBranchesTo(default_block, merge_block.name)) return null;
    const default_case: ErrorUnionTrySwitchCase = .{
        .value = 0,
        .block = default_block,
        .add_imm = payloadAddWrapPhiIncoming(function, switch_block, merge_block, phi, default_block.name, call_name) orelse return null,
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

fn blockSwitchTerminator(block: ir.BasicBlock) ?ir.SwitchTerminator {
    return switch (block.terminator orelse return null) {
        .@"switch" => |switch_term| switch_term,
        else => null,
    };
}

fn commonSwitchMergeBlock(function: ir.Function, switch_term: ir.SwitchTerminator) ?ir.BasicBlock {
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
    const default_block = function.blocks.items[blockIndex(function, switch_term.default_target) orelse return null];
    const default_target = singleBrTarget(default_block) orelse return null;
    if (target) |existing| {
        if (!std.mem.eql(u8, existing, default_target)) return null;
    } else {
        target = default_target;
    }
    return function.blocks.items[blockIndex(function, target orelse return null) orelse return null];
}

fn firstPhiReturn(function: ir.Function, block: ir.BasicBlock) ?ir.PhiInst {
    if (block.instructions.items.len != 1) return null;
    const phi_name = block.instructions.items[0].result orelse return null;
    const phi = switch (block.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return null,
    };
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(function.ret_ty) or !isNamed(ret.value orelse return null, phi_name)) return null;
    return phi;
}

fn blockBranchesTo(block: ir.BasicBlock, target: []const u8) bool {
    const branch_target = singleBrTarget(block) orelse return false;
    return std.mem.eql(u8, branch_target, target);
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
    merge_block: ir.BasicBlock,
    phi: ir.PhiInst,
    predecessor: []const u8,
    call_name: []const u8,
) ?u8 {
    _ = merge_block;
    for (phi.incoming.items) |incoming| {
        if (!std.mem.eql(u8, incoming.block, predecessor)) continue;
        const value_block = blockByName(function, predecessor) orelse return null;
        return payloadAddWrapValue(value_block, payload_scope, incoming.value, call_name);
    }
    return null;
}

fn payloadAddWrapValue(value_block: ir.BasicBlock, payload_scope: ir.BasicBlock, value: ir.Value, call_name: []const u8) ?u8 {
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

fn lowerGenericCfgErrorUnionTrySlotUpdateReturn(
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

fn lowerGenericCfgErrorUnionTryPayloadBranchReturn(
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
    const compare = payloadGreaterConst(function, cont_block, cont_condbr.cond, call_name) orelse return null;
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

fn payloadGreaterConst(function: ir.Function, block: ir.BasicBlock, cond: ir.Value, call_name: []const u8) ?PayloadGreaterConst {
    _ = function;
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

const PayloadGreaterConstPredicate = enum {
    signed_gt,
    unsigned_gt,
};

const PayloadGreaterConst = union(PayloadGreaterConstPredicate) {
    signed_gt: i32,
    unsigned_gt: i32,
};

const PayloadBinaryWrapReturn = struct {
    op: MachineBinaryOp,
    reg: ArgReg,
};

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

fn payloadValueFromCallResult(block: ir.BasicBlock, value: ir.Value, call_name: []const u8) bool {
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

fn supportsDirectI64Call(call: ir.CallInst) bool {
    if (!call.ret_ty.eql(.{ .int = 64 }) or call.inline_asm != null or call.callee_value != null) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;
    for (call.args.items) |arg| {
        if (!arg.ty.eql(.{ .int = 32 })) return false;
    }
    return true;
}

fn errorUnionTryGuardCallResult(block: ir.BasicBlock, cond: ir.Value) ?[]const u8 {
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

fn blockReturnsNamedValue(block: ir.BasicBlock, name: []const u8, ty: ir.Type) bool {
    const ret = switch (block.terminator orelse return false) {
        .ret => |ret| ret,
        else => return false,
    };
    return ret.ty.eql(ty) and isNamed(ret.value orelse return false, name);
}

fn payloadAddArgFromCallResult(block: ir.BasicBlock, value: ir.Value, call_name: []const u8) ?u8 {
    const add_name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    return payloadAddFromCallResult(block, add_name, call_name);
}

fn payloadAddFromCallResult(block: ir.BasicBlock, add_name: []const u8, call_name: []const u8) ?u8 {
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

fn successReturnPayloadAdd(block: ir.BasicBlock, call_name: []const u8) ?u8 {
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

fn emitTwoI32ArgCallIntoRax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    call: ir.CallInst,
) !void {
    if (!supportsDirectI64Call(call) or call.args.items.len != 2) return error.UnsupportedCodegenInstruction;
    const first_reg = switch (call.args.items[0].value) {
        .named => |name| try paramReg(function, name, .{ .int = 32 }),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    const second_reg = switch (call.args.items[1].value) {
        .named => |name| try paramReg(function, name, .{ .int = 32 }),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    if (first_reg != .rdi and second_reg == .rdi) return error.UnsupportedCodegenAbi;
    if (first_reg != .rdi) try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rdi, .src = first_reg } });
    if (second_reg != .rsi) try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rsi, .src = second_reg } });
    _ = block;
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = call.callee, .ret_ty = call.ret_ty } });
}

fn emitGenericCfgNestedTerminalBranch(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    entry: ir.BasicBlock,
    scope: ir.BasicBlock,
    cond: ir.Value,
    then_target: []const u8,
    else_target: []const u8,
) !void {
    const then_block = function.blocks.items[blockIndex(function, then_target) orelse return error.InvalidBranchTarget];
    const else_block = function.blocks.items[blockIndex(function, else_target) orelse return error.InvalidBranchTarget];
    try emitGenericCfgTerminalConditionTrueBranch(allocator, machine, function, entry, scope, cond, then_block.name);
    try emitGenericCfgTerminalReturnBlockInScope(allocator, machine, function, .{ .entry = entry, .middle = scope, .block = else_block });
    try appendGenericCfgBlockLabel(allocator, machine, then_block.name);
    try emitGenericCfgTerminalReturnBlockInScope(allocator, machine, function, .{ .entry = entry, .middle = scope, .block = then_block });
}

fn blockHasCondbr(block: ir.BasicBlock) bool {
    return switch (block.terminator orelse return false) {
        .condbr => true,
        else => false,
    };
}

fn linearTerminalBranchUsesAllBlocks(
    function: ir.Function,
    continuation_index: usize,
    first_return_index: usize,
    second_then_index: usize,
    second_else_index: usize,
) bool {
    for (function.blocks.items, 0..) |block, index| {
        if (index == 0 or index == continuation_index or index == first_return_index or
            index == second_then_index or index == second_else_index)
        {
            continue;
        }
        switch (block.terminator orelse return false) {
            .@"unreachable" => {},
            else => return false,
        }
    }
    return second_then_index != second_else_index;
}

fn terminalCondParamReg(function: ir.Function, cond: ir.Value) ?ArgReg {
    const cond_name = switch (cond) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    return paramRegOrNull(function, cond_name, .{ .int = 1 }) catch null;
}

fn genericCfgTerminalBranchExtraBlocksAreUnreachable(function: ir.Function, then_index: usize, else_index: usize) bool {
    for (function.blocks.items, 0..) |block, index| {
        if (index == 0 or index == then_index or index == else_index) continue;
        switch (block.terminator orelse return false) {
            .@"unreachable" => {},
            else => return false,
        }
    }
    return true;
}

pub fn singleBrTarget(block: ir.BasicBlock) ?[]const u8 {
    return switch (block.terminator orelse return null) {
        .br => |br| br.target,
        else => null,
    };
}

fn blockIsUnreachable(block: ir.BasicBlock) bool {
    return switch (block.terminator orelse return false) {
        .@"unreachable" => true,
        else => false,
    };
}

fn genericCfgSupportsTerminalReturnBlock(function: ir.Function, entry: ir.BasicBlock, block: ir.BasicBlock) bool {
    return genericCfgSupportsTerminalReturnBlockInScope(function, .{ .entry = entry, .block = block });
}

fn genericCfgSupportsNestedTerminalReturnBlock(function: ir.Function, entry: ir.BasicBlock, middle: ir.BasicBlock, block: ir.BasicBlock) bool {
    return genericCfgSupportsTerminalReturnBlockInScope(function, .{ .entry = entry, .middle = middle, .block = block });
}

fn genericCfgSupportsTerminalReturnBlockInScope(function: ir.Function, scope: TerminalValueScope) bool {
    const ret = switch (scope.block.terminator orelse return false) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(function.ret_ty)) return false;
    const ret_value = ret.value orelse return false;
    if (function.ret_ty.eql(.{ .int = 32 })) {
        return genericCfgSupportsI32Value(function, ret_value) or terminalBlockCanMaterializeI32Value(function, scope, ret_value);
    }
    return terminalBlockCanMaterializeI64Value(function, scope, ret_value);
}

const TerminalValueScope = struct {
    entry: ir.BasicBlock,
    middle: ?ir.BasicBlock = null,
    block: ir.BasicBlock,
};

fn terminalScopeInstruction(scope: TerminalValueScope, name: []const u8) ?ir.Instruction {
    if (findInstruction(scope.block, name)) |instruction| return instruction;
    if (scope.middle) |middle| {
        if (findInstruction(middle, name)) |instruction| return instruction;
    }
    return findInstruction(scope.entry, name);
}

const TerminalScopeInstruction = struct {
    instruction: ir.Instruction,
    block: ir.BasicBlock,
};

fn terminalScopeInstructionWithBlock(scope: TerminalValueScope, name: []const u8) ?TerminalScopeInstruction {
    if (findInstruction(scope.block, name)) |instruction| return .{ .instruction = instruction, .block = scope.block };
    if (scope.middle) |middle| {
        if (findInstruction(middle, name)) |instruction| return .{ .instruction = instruction, .block = middle };
    }
    if (findInstruction(scope.entry, name)) |instruction| return .{ .instruction = instruction, .block = scope.entry };
    return null;
}

fn terminalBlockCanMaterializeI32Value(function: ir.Function, scope: TerminalValueScope, value: ir.Value) bool {
    return switch (value) {
        .int => true,
        .named => |name| blk: {
            if ((paramRegOrNull(function, name, .{ .int = 32 }) catch null) != null) break :blk true;
            const instruction = terminalScopeInstruction(scope, name) orelse break :blk false;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (!binary.ty.eql(.{ .int = 32 })) break :blk false;
                    if (machineBinaryOp(binary.op) == null) break :blk false;
                    break :blk terminalBlockCanMaterializeI32Value(function, scope, binary.lhs) and
                        terminalBlockCanMaterializeI32Value(function, scope, binary.rhs);
                },
                .cast => |cast| {
                    if (cast.op != .trunc or !cast.from_ty.eql(.{ .int = 64 }) or !cast.to_ty.eql(.{ .int = 32 })) break :blk false;
                    break :blk terminalBlockCanMaterializeI64Value(function, scope, cast.value);
                },
                else => break :blk false,
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

fn terminalBlockCanMaterializeI64Value(function: ir.Function, scope: TerminalValueScope, value: ir.Value) bool {
    return switch (value) {
        .int => true,
        .named => |name| blk: {
            if ((paramRegOrNull(function, name, .{ .int = 64 }) catch null) != null) break :blk true;
            const instruction = terminalScopeInstruction(scope, name) orelse break :blk false;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (!binary.ty.eql(.{ .int = 64 })) break :blk false;
                    switch (binary.op) {
                        .add, .@"and", .lshr, .shl => {},
                        else => break :blk false,
                    }
                    if (binary.rhs != .int) break :blk false;
                    break :blk terminalBlockCanMaterializeI64Value(function, scope, binary.lhs);
                },
                .cast => |cast| {
                    if (cast.op != .zext or !cast.to_ty.eql(.{ .int = 64 })) break :blk false;
                    switch (cast.from_ty) {
                        .int => |bits| if (bits > 32) break :blk false,
                        else => break :blk false,
                    }
                    break :blk terminalBlockCanMaterializeI32Value(function, scope, cast.value);
                },
                .select => |select| {
                    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 64 })) break :blk false;
                    break :blk terminalBlockCanMaterializeI64Value(function, scope, select.true_value) and
                        terminalBlockCanMaterializeI64Value(function, scope, select.false_value);
                },
                .call => |call| {
                    break :blk call.ret_ty.eql(.{ .int = 64 }) and call.inline_asm == null and call.callee_value == null;
                },
                else => break :blk false,
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

fn emitGenericCfgTerminalConditionTrueBranch(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    entry: ir.BasicBlock,
    block: ir.BasicBlock,
    cond: ir.Value,
    true_label: []const u8,
) !void {
    const cond_name = switch (cond) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    const cond_inst = findInstruction(block, cond_name) orelse {
        try emitGenericCfgConditionTrueBranch(allocator, machine, function, block, cond, true_label);
        return;
    };
    const icmp = switch (cond_inst.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (icmp.predicate == .ugt and icmp.operand_ty.eql(.{ .int = 32 })) {
        const rhs = switch (icmp.rhs) {
            .int => |int| try i32Value(int),
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        if (rhs == std.math.maxInt(i32)) return error.UnsupportedCodegenValue;
        try emitGenericCfgTerminalI32ValueIntoEax(allocator, machine, function, entry, block, icmp.lhs);
        try appendGenericCfgCompareLocalImm(allocator, machine, .eax, rhs + 1);
        try appendGenericCfgConditionalBranch(allocator, machine, .jae, true_label);
        return;
    }
    if (icmp.operand_ty.eql(.{ .int = 64 }) and (icmp.predicate == .eq or icmp.predicate == .ne)) {
        const value = if (isInt(icmp.rhs, 0)) icmp.lhs else if (isInt(icmp.lhs, 0)) icmp.rhs else return error.UnsupportedCodegenValue;
        try emitGenericCfgTerminalI64ValueIntoRax(allocator, machine, function, entry, block, value);
        try machine.instructions.append(allocator, .test_rax_rax);
        try appendGenericCfgConditionalBranch(allocator, machine, if (icmp.predicate == .eq) .je else .jne, true_label);
        return;
    }
    try emitGenericCfgConditionTrueBranch(allocator, machine, function, block, cond, true_label);
}

fn emitGenericCfgTerminalReturnBlock(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    entry: ir.BasicBlock,
    block: ir.BasicBlock,
) !void {
    try emitGenericCfgTerminalReturnBlockInScope(allocator, machine, function, .{ .entry = entry, .block = block });
}

fn emitGenericCfgTerminalReturnBlockInScope(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    scope: TerminalValueScope,
) !void {
    const ret = switch (scope.block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (function.ret_ty.eql(.{ .int = 32 })) {
        try emitGenericCfgTerminalI32ValueIntoEaxInScope(allocator, machine, function, scope, ret.value orelse return error.InvalidRet);
    } else if (function.ret_ty.eql(.{ .int = 64 })) {
        try emitGenericCfgTerminalI64ValueIntoRaxInScope(allocator, machine, function, scope, ret.value orelse return error.InvalidRet);
    } else {
        return error.UnsupportedCodegenType;
    }
    try appendGenericCfgReturn(allocator, machine);
}

fn emitGenericCfgTerminalI32ValueIntoEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    entry: ir.BasicBlock,
    block: ir.BasicBlock,
    value: ir.Value,
) !void {
    try emitGenericCfgTerminalI32ValueIntoEaxInScope(allocator, machine, function, .{ .entry = entry, .block = block }, value);
}

fn emitGenericCfgTerminalI32ValueIntoEaxInScope(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    scope: TerminalValueScope,
    value: ir.Value,
) !void {
    switch (value) {
        .int => |int| try machine.instructions.append(allocator, .{ .mov_imm_eax = try i32Value(int) }),
        .named => |name| {
            if ((paramRegOrNull(function, name, .{ .int = 32 }) catch null)) |reg| {
                try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
                return;
            }
            const instruction = terminalScopeInstruction(scope, name) orelse return error.UnsupportedCodegenValue;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (!binary.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
                    try emitGenericCfgTerminalI32ValueIntoEaxInScope(allocator, machine, function, scope, binary.lhs);
                    switch (binary.rhs) {
                        .int => |int| switch (binary.op) {
                            .add => try machine.instructions.append(allocator, .{ .add_eax_imm32 = try i32Value(int) }),
                            .sub => try machine.instructions.append(allocator, .{ .add_eax_imm32 = -try i32Value(int) }),
                            else => return error.UnsupportedCodegenInstruction,
                        },
                        .named => |rhs_name| {
                            const op = machineBinaryOp(binary.op) orelse return error.UnsupportedCodegenInstruction;
                            const rhs_reg = try paramReg(function, rhs_name, .{ .int = 32 });
                            try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = op, .reg = rhs_reg } });
                        },
                        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
                    }
                },
                .cast => |cast| {
                    if (cast.op != .trunc or !cast.from_ty.eql(.{ .int = 64 }) or !cast.to_ty.eql(.{ .int = 32 })) {
                        return error.UnsupportedCodegenInstruction;
                    }
                    try emitGenericCfgTerminalI64ValueIntoRaxInScope(allocator, machine, function, scope, cast.value);
                },
                else => try emitGenericCfgI32ValueIntoEax(allocator, machine, function, scope.block, value),
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

fn emitGenericCfgTerminalI64ValueIntoRax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    entry: ir.BasicBlock,
    block: ir.BasicBlock,
    value: ir.Value,
) anyerror!void {
    try emitGenericCfgTerminalI64ValueIntoRaxInScope(allocator, machine, function, .{ .entry = entry, .block = block }, value);
}

fn emitGenericCfgTerminalI64ValueIntoRaxInScope(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    scope: TerminalValueScope,
    value: ir.Value,
) anyerror!void {
    switch (value) {
        .int => |int| try machine.instructions.append(allocator, .{ .mov_imm_rax = try i64Value(int) }),
        .named => |name| {
            if (paramRegOrNull(function, name, .{ .int = 64 }) catch null) |reg| {
                try machine.instructions.append(allocator, .{ .mov_arg_rax = reg });
                return;
            }
            const scoped_instruction = terminalScopeInstructionWithBlock(scope, name) orelse return error.UnsupportedCodegenValue;
            switch (scoped_instruction.instruction.kind) {
                .binary => |binary| {
                    if (!binary.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
                    const rhs = switch (binary.rhs) {
                        .int => |int| try i64Value(int),
                        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
                    };
                    try emitGenericCfgTerminalI64ValueIntoRaxInScope(allocator, machine, function, scope, binary.lhs);
                    switch (binary.op) {
                        .add => {
                            if (rhs < 0 or rhs > 127) return error.UnsupportedCodegenValue;
                            if (rhs != 0) try machine.instructions.append(allocator, .{ .add_rax_imm8 = @intCast(rhs) });
                        },
                        .@"and" => {
                            if (rhs < std.math.minInt(i32) or rhs > std.math.maxInt(i32)) return error.UnsupportedCodegenValue;
                            try machine.instructions.append(allocator, .{ .and_eax_imm32 = @intCast(rhs) });
                        },
                        .lshr => {
                            if (rhs < 0 or rhs > 63) return error.UnsupportedCodegenValue;
                            if (rhs != 0) try machine.instructions.append(allocator, .{ .shr_rax_imm6 = @intCast(rhs) });
                        },
                        .shl => {
                            if (rhs < 0 or rhs > 63) return error.UnsupportedCodegenValue;
                            if (rhs != 0) try machine.instructions.append(allocator, .{ .shl_rax_imm6 = @intCast(rhs) });
                        },
                        else => return error.UnsupportedCodegenInstruction,
                    }
                },
                .cast => |cast| {
                    if (cast.op != .zext or !cast.to_ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenInstruction;
                    switch (cast.from_ty) {
                        .int => |bits| if (bits > 32) return error.UnsupportedCodegenType,
                        else => return error.UnsupportedCodegenType,
                    }
                    try emitGenericCfgTerminalI32ValueIntoEaxInScope(allocator, machine, function, scope, cast.value);
                },
                .select => |select| try emitGenericCfgTerminalI64SelectIntoRax(allocator, machine, function, scope.entry, scope.block, name, select),
                .call => |call| try emitGenericCfgTerminalI64CallIntoRax(allocator, machine, function, scoped_instruction.block, call),
                else => return error.UnsupportedCodegenInstruction,
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

fn emitGenericCfgTerminalI64CallIntoRax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    call: ir.CallInst,
) !void {
    if (!call.ret_ty.eql(.{ .int = 64 }) or call.inline_asm != null or call.callee_value != null) {
        return error.UnsupportedCodegenInstruction;
    }
    if (!callIsFastcc(call.calling_conv)) try validateDefaultCallConv(call.calling_conv);
    const stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, call);
    try appendDirectCallWithStackArgs(allocator, machine, call.callee, call.ret_ty, stack_arg_count);
}

fn emitGenericCfgTerminalI64SelectIntoRax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    entry: ir.BasicBlock,
    block: ir.BasicBlock,
    result_name: []const u8,
    select: ir.SelectInst,
) anyerror!void {
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
    const cond_name = switch (select.cond) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    const cond_instruction = terminalScopeInstruction(.{ .entry = entry, .block = block }, cond_name) orelse return error.UnsupportedCodegenValue;
    const icmp = switch (cond_instruction.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    const label_suffix = machine.instructions.items.len;
    const true_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_terminal_i64_select_{s}_{s}_{}_true",
        .{ block.name, result_name, label_suffix },
    );
    const end_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_terminal_i64_select_{s}_{s}_{}_end",
        .{ block.name, result_name, label_suffix },
    );
    const branch_kind = try emitGenericCfgIcmpCondition(allocator, machine, function, icmp);
    try appendGenericCfgConditionalBranch(allocator, machine, branch_kind, true_label);
    try emitGenericCfgTerminalI64ValueIntoRax(allocator, machine, function, entry, block, select.false_value);
    try machine.instructions.append(allocator, .{ .jmp = end_label });
    try appendGenericCfgBlockLabel(allocator, machine, true_label);
    try emitGenericCfgTerminalI64ValueIntoRax(allocator, machine, function, entry, block, select.true_value);
    try appendGenericCfgBlockLabel(allocator, machine, end_label);
}

fn ownedMachineLabel(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    comptime fmt: []const u8,
    args: anytype,
) ![]const u8 {
    const label = try std.fmt.allocPrint(allocator, fmt, args);
    errdefer allocator.free(label);
    try machine.owned_labels.append(allocator, label);
    return label;
}

pub fn genericCfgSupportsBranchMergeBlock(
    function: ir.Function,
    entry: ir.BasicBlock,
    then_block: ir.BasicBlock,
    else_block: ir.BasicBlock,
    merge_block: ir.BasicBlock,
) bool {
    for (entry.instructions.items) |instruction| {
        if (instruction.removed) return false;
        switch (instruction.kind) {
            .icmp => |icmp| if (!genericCfgSupportsBranchIcmp(function, icmp)) return false,
            else => return false,
        }
    }
    if (!genericCfgSupportsBranchSideEffects(function, then_block)) return false;
    if (!genericCfgSupportsBranchSideEffects(function, else_block)) return false;
    const ret = switch (merge_block.terminator orelse return false) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (genericCfgPointerPhiLoadReturn(function, merge_block) != null) return true;
    if (genericCfgPhiBinaryReturn(merge_block) != null) return true;
    if (merge_block.instructions.items.len > 1) return false;
    if (merge_block.instructions.items.len == 1) {
        const instruction = merge_block.instructions.items[0];
        if (instruction.removed) return false;
        const ret_name = switch (ret.value orelse return false) {
            .named => |name| name,
            else => return false,
        };
        const result_name = instruction.result orelse return false;
        if (!std.mem.eql(u8, result_name, ret_name)) return false;
        switch (instruction.kind) {
            .phi => |phi| {
                if (!phi.ty.eql(.{ .int = 32 }) or phi.incoming.items.len != 2) return false;
            },
            .load => |load| {
                if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
                if (core_value_support.genericCfgI32Address(function, load.ptr) == null) return false;
            },
            else => return false,
        }
    }
    return true;
}

pub const GenericCfgPointerPhiLoad = struct {
    phi_name: []const u8,
    load_name: []const u8,
    phi: ir.PhiInst,
};

pub const GenericCfgPhiBinaryReturn = struct {
    phi_name: []const u8,
    binary_name: []const u8,
    phi: ir.PhiInst,
    op: ir.BinaryOp,
    imm: i32,
};

pub fn genericCfgPhiBinaryReturn(merge_block: ir.BasicBlock) ?GenericCfgPhiBinaryReturn {
    if (merge_block.instructions.items.len != 2) return null;
    const phi_instruction = merge_block.instructions.items[0];
    const binary_instruction = merge_block.instructions.items[1];
    if (phi_instruction.removed or binary_instruction.removed) return null;
    const phi_name = phi_instruction.result orelse return null;
    const binary_name = binary_instruction.result orelse return null;
    const phi = switch (phi_instruction.kind) {
        .phi => |phi| phi,
        else => return null,
    };
    if (!phi.ty.eql(.{ .int = 32 }) or phi.incoming.items.len != 2) return null;
    const binary = switch (binary_instruction.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (!binary.ty.eql(.{ .int = 32 }) or !isNamed(binary.lhs, phi_name)) return null;
    const imm = switch (binary.rhs) {
        .int => |int| i32Value(int) catch return null,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    switch (binary.op) {
        .add, .sub => {},
        else => return null,
    }
    const ret = switch (merge_block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return null, binary_name)) return null;
    return .{
        .phi_name = phi_name,
        .binary_name = binary_name,
        .phi = phi,
        .op = binary.op,
        .imm = imm,
    };
}

pub fn genericCfgPointerPhiLoadReturn(function: ir.Function, merge_block: ir.BasicBlock) ?GenericCfgPointerPhiLoad {
    if (merge_block.instructions.items.len != 2) return null;
    const phi_instruction = merge_block.instructions.items[0];
    const load_instruction = merge_block.instructions.items[1];
    if (phi_instruction.removed or load_instruction.removed) return null;
    const phi_name = phi_instruction.result orelse return null;
    const load_name = load_instruction.result orelse return null;
    const phi = switch (phi_instruction.kind) {
        .phi => |phi| phi,
        else => return null,
    };
    if (!phi.ty.eql(.ptr) or phi.incoming.items.len != 2) return null;
    for (phi.incoming.items) |incoming| {
        const ptr_name = switch (incoming.value) {
            .named => |name| name,
            else => return null,
        };
        if ((paramRegOrNull(function, ptr_name, .ptr) catch null) == null) return null;
    }
    const load = switch (load_instruction.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier() or !isNamed(load.ptr, phi_name)) return null;
    const ret = switch (merge_block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return null, load_name)) return null;
    return .{ .phi_name = phi_name, .load_name = load_name, .phi = phi };
}

pub fn lowerGenericCfgDynamicPointerLoadReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.ptr) or !function.params.items[1].ty.eql(.{ .int = 64 })) return false;
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        else => return false,
    };
    const ret_instruction = findInstruction(block, ret_name) orelse return false;
    switch (ret_instruction.kind) {
        .load => |load| {
            const address = core_memory_lowering.genericCfgDynamicI32LoadAddress(function, block, load) orelse return false;
            try core_memory_lowering.emitGenericCfgDynamicI32LoadIntoEax(allocator, machine, address);
        },
        .binary => |binary| {
            if (binary.op != .add or !binary.ty.eql(.{ .int = 32 })) return false;
            const lhs = core_memory_lowering.genericCfgDynamicI32LoadValueAddress(function, block, binary.lhs) orelse return false;
            const rhs = core_memory_lowering.genericCfgDynamicI32LoadValueAddress(function, block, binary.rhs) orelse return false;
            try core_memory_lowering.emitGenericCfgDynamicI32LoadIntoEax(allocator, machine, lhs);
            try core_memory_lowering.emitGenericCfgDynamicI32AddIntoEax(allocator, machine, rhs);
        },
        else => return false,
    }
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub fn genericCfgSupportsBranchSideEffects(function: ir.Function, block: ir.BasicBlock) bool {
    for (block.instructions.items) |instruction| {
        if (instruction.removed) return false;
        switch (instruction.kind) {
            .store => |store| {
                if (!store.ty.eql(.{ .int = 32 })) return false;
                if (!genericCfgSupportsI32Value(function, store.value)) {
                    if (store.value != .named) return false;
                }
                if (core_value_support.genericCfgI32Address(function, store.ptr) == null) return false;
            },
            .load => |load| {
                if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
                if (core_value_support.genericCfgI32Address(function, load.ptr) == null) return false;
            },
            .binary => |binary| {
                if (!binary.ty.eql(.{ .int = 32 })) return false;
                if (!genericCfgSupportsI32Value(function, binary.lhs)) return false;
                switch (binary.rhs) {
                    .int => switch (binary.op) {
                        .add, .sub => {},
                        else => return false,
                    },
                    .named => |name| {
                        if ((paramRegOrNull(function, name, .{ .int = 32 }) catch null) == null) return false;
                        if (machineBinaryOp(binary.op) == null) return false;
                    },
                    .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                }
            },
            .call => |call| {
                if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len > 4) return false;
                if (call.callee_value != null or call.inline_asm != null) return false;
                if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;
                for (call.args.items) |arg| {
                    if (!arg.ty.eql(.{ .int = 32 })) return false;
                    switch (arg.value) {
                        .int => {},
                        .named => |name| if ((paramRegOrNull(function, name, .{ .int = 32 }) catch null) == null) return false,
                        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                    }
                }
            },
            .phi, .icmp, .fcmp, .cast, .freeze, .select, .alloca, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep => return false,
        }
    }
    return true;
}

pub fn emitGenericCfgConditionTrueBranch(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    cond: ir.Value,
    true_label: []const u8,
) !void {
    const cond_name = switch (cond) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    if (paramRegOrNull(function, cond_name, .{ .int = 1 }) catch null) |reg| {
        try appendGenericCfgCompareParamZero(allocator, machine, reg);
        try appendGenericCfgConditionalBranch(allocator, machine, .jne, true_label);
        return;
    }
    const cond_inst = findInstruction(block, cond_name) orelse return error.UnsupportedCodegenValue;
    const icmp = switch (cond_inst.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    const branch_kind = try emitGenericCfgIcmpCondition(allocator, machine, function, icmp);
    try appendGenericCfgConditionalBranch(allocator, machine, branch_kind, true_label);
}

pub fn emitGenericCfgBranchPathReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    branch_block: ir.BasicBlock,
    merge_block: ir.BasicBlock,
) !void {
    try emitGenericCfgBranchSideEffects(allocator, machine, function, branch_block);
    const ret = switch (merge_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    const ret_value = ret.value orelse return error.InvalidRet;
    if (genericCfgPointerPhiLoadReturn(function, merge_block)) |pointer_load| {
        for (pointer_load.phi.incoming.items) |incoming| {
            if (!std.mem.eql(u8, incoming.block, branch_block.name)) continue;
            const ptr_reg = try paramValueReg(function, incoming.value, .ptr);
            try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = ptr_reg });
            try appendGenericCfgReturn(allocator, machine);
            return;
        }
        return error.UnsupportedCodegenValue;
    }
    if (genericCfgPhiBinaryReturn(merge_block)) |phi_binary| {
        for (phi_binary.phi.incoming.items) |incoming| {
            if (!std.mem.eql(u8, incoming.block, branch_block.name)) continue;
            try emitGenericCfgI32ValueIntoEax(allocator, machine, function, branch_block, incoming.value);
            switch (phi_binary.op) {
                .add => try machine.instructions.append(allocator, .{ .add_eax_imm32 = phi_binary.imm }),
                .sub => try machine.instructions.append(allocator, .{ .add_eax_imm32 = -phi_binary.imm }),
                else => return error.UnsupportedCodegenInstruction,
            }
            try appendGenericCfgReturn(allocator, machine);
            return;
        }
        return error.UnsupportedCodegenValue;
    }
    if (merge_block.instructions.items.len > 0) {
        const phi = switch (merge_block.instructions.items[0].kind) {
            .phi => |phi| phi,
            else => null,
        };
        if (phi) |phi_inst| {
            const ret_name = switch (ret_value) {
                .named => |name| name,
                else => return error.UnsupportedCodegenValue,
            };
            const phi_name = merge_block.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
            if (!std.mem.eql(u8, ret_name, phi_name)) return error.UnsupportedCodegenValue;
            for (phi_inst.incoming.items) |incoming| {
                if (!std.mem.eql(u8, incoming.block, branch_block.name)) continue;
                try emitGenericCfgI32ValueIntoEax(allocator, machine, function, branch_block, incoming.value);
                try appendGenericCfgReturn(allocator, machine);
                return;
            }
            return error.UnsupportedCodegenValue;
        }
    }
    try emitGenericCfgI32ValueIntoEax(allocator, machine, function, merge_block, ret_value);
    try appendGenericCfgReturn(allocator, machine);
}

pub const emitGenericCfgBranchSideEffects = core_value_emit.emitGenericCfgBranchSideEffects;
pub const emitGenericCfgI32ValueIntoEax = core_value_emit.emitGenericCfgI32ValueIntoEax;
pub const emitGenericCfgI64ValueIntoRax = core_value_emit.emitGenericCfgI64ValueIntoRax;
pub const emitGenericCfgI32AddValueToEax = core_value_emit.emitGenericCfgI32AddValueToEax;
pub const emitGenericCfgStoreEax = core_value_emit.emitGenericCfgStoreEax;
pub const emitGenericCfgI32CallIntoEax = core_value_emit.emitGenericCfgI32CallIntoEax;
pub const emitGenericCfgVoidCall = core_value_emit.emitGenericCfgVoidCall;

pub fn emitGenericCfgLoopSum(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    plan: GenericCfgLoopSumPlan,
) !void {
    const count_reg = try paramReg(function, function.params.items[0].name, .{ .int = 32 });
    if (count_reg != .rdi) return error.UnsupportedCodegenAbi;

    const loop_label = "generic_cfg_loop_sum_loop";
    const zero_label = "generic_cfg_loop_sum_zero";
    const overflow_label = "generic_cfg_loop_sum_overflow";
    const out_of_bounds_label = "generic_cfg_loop_sum_out_of_bounds";
    try appendGenericCfgCompareParamZero(allocator, machine, count_reg);
    try appendGenericCfgConditionalBranch(allocator, machine, .je, zero_label);
    try appendGenericCfgConditionalBranch(allocator, machine, .js, zero_label);
    try appendGenericCfgI32Zero(allocator, machine, .eax);
    try appendGenericCfgI32Zero(allocator, machine, .ecx);
    try appendGenericCfgBlockLabel(allocator, machine, loop_label);
    if (plan.checked) {
        try appendGenericCfgCompareLocalImm(allocator, machine, .ecx, std.math.minInt(i32));
        try appendGenericCfgConditionalBranch(allocator, machine, .je, out_of_bounds_label);
    }
    try appendGenericCfgAccumulatorAdd(allocator, machine);
    if (plan.checked) try appendGenericCfgConditionalBranch(allocator, machine, .jo, overflow_label);
    try appendGenericCfgAccumulatorIncrement(allocator, machine);
    try appendGenericCfgCompareLocalParam(allocator, machine, .ecx, count_reg);
    try appendGenericCfgConditionalBranch(allocator, machine, .jne, loop_label);
    try appendGenericCfgReturn(allocator, machine);
    try appendGenericCfgBlockLabel(allocator, machine, zero_label);
    try appendGenericCfgI32Zero(allocator, machine, .eax);
    try appendGenericCfgReturn(allocator, machine);
    if (plan.checked) {
        try appendPanicCall(allocator, machine, overflow_label, "debug.FullPanic((function 'defaultPanic')).integerOverflow");
        try appendPanicCall(allocator, machine, out_of_bounds_label, "debug.FullPanic((function 'defaultPanic')).integerOutOfBounds");
    }
}
