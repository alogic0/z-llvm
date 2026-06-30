const shared = @import("core_shared.zig");
const core_cfg_emit = @import("core_cfg_emit.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");
const cabi_call_lowering = @import("cabi_call_lowering.zig");
const terminal_values = @import("terminal_values.zig");

const std = shared.std;
const ir = shared.ir;
const MachineFunction = shared.MachineFunction;
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
const i32Value = shared.i32Value;
const i64Value = shared.i64Value;
const isInt = shared.isInt;
const isNamed = shared.isNamed;
const paramReg = cabi_abi_helpers.paramReg;
const phiHasIncoming = cabi_call_lowering.phiHasIncoming;
const phiHasIncomingInt = cabi_call_lowering.phiHasIncomingInt;
const findInstruction = cabi_call_lowering.findInstruction;
const genericCfgTerminalBranchExtraBlocksAreUnreachable = terminal_values.genericCfgTerminalBranchExtraBlocksAreUnreachable;
const linearTerminalBranchUsesAllBlocks = terminal_values.linearTerminalBranchUsesAllBlocks;
const ownedMachineLabel = terminal_values.ownedMachineLabel;
const validateDefaultCallConv = shared.validateDefaultCallConv;

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
