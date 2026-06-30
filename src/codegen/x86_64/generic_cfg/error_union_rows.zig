const shared = @import("core_shared.zig");
const core_cfg_emit = @import("core_cfg_emit.zig");
const cabi_call_lowering = @import("cabi_call_lowering.zig");

const std = shared.std;
const ir = shared.ir;
const MachineFunction = shared.MachineFunction;

const appendStackFrame = shared.appendStackFrame;
const appendStackFrameEnd = shared.appendStackFrameEnd;
const appendGenericCfgBlockLabel = core_cfg_emit.appendGenericCfgBlockLabel;
const appendGenericCfgConditionalBranch = core_cfg_emit.appendGenericCfgConditionalBranch;
const appendGenericCfgReturn = core_cfg_emit.appendGenericCfgReturn;
const i32Value = shared.i32Value;
const isInt = shared.isInt;
const isNamed = shared.isNamed;
const phiHasIncoming = cabi_call_lowering.phiHasIncoming;
const phiHasIncomingInt = cabi_call_lowering.phiHasIncomingInt;

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
