const shared = @import("core_shared.zig");
const core_cfg_emit = @import("core_cfg_emit.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");
const cabi_call_lowering = @import("cabi_call_lowering.zig");
const terminal_values = @import("terminal_values.zig");

const std = shared.std;
const ir = shared.ir;
const MachineFunction = shared.MachineFunction;

const appendStackFrame = shared.appendStackFrame;
const appendStackFrameEnd = shared.appendStackFrameEnd;
const appendGenericCfgBlockLabel = core_cfg_emit.appendGenericCfgBlockLabel;
const appendGenericCfgConditionalBranch = core_cfg_emit.appendGenericCfgConditionalBranch;
const appendGenericCfgReturn = core_cfg_emit.appendGenericCfgReturn;
const appendSysVScalarCallArgsWithBlock = cabi_call_lowering.appendSysVScalarCallArgsWithBlock;
const blockIndex = cabi_abi_helpers.blockIndex;
const blockSwitchTerminator = terminal_values.blockSwitchTerminator;
const firstPhiReturn = terminal_values.firstPhiReturn;
const i32Value = shared.i32Value;
const isInt = shared.isInt;
const paramReg = cabi_abi_helpers.paramReg;
const findInstruction = cabi_call_lowering.findInstruction;
const blockBranchesTo = terminal_values.blockBranchesTo;
const ownedMachineLabel = terminal_values.ownedMachineLabel;
const emitGenericCfgTerminalConditionTrueBranch = terminal_values.emitGenericCfgTerminalConditionTrueBranch;
const emitGenericCfgTerminalI64ValueIntoRax = terminal_values.emitGenericCfgTerminalI64ValueIntoRax;
const emitGenericCfgTerminalReturnBlock = terminal_values.emitGenericCfgTerminalReturnBlock;
const genericCfgSupportsTerminalReturnBlock = terminal_values.genericCfgSupportsTerminalReturnBlock;
const phiIncomingForBlock = terminal_values.phiIncomingForBlock;
const singleBrTarget = terminal_values.singleBrTarget;
const paramRegOrNull = cabi_abi_helpers.paramRegOrNull;
const try_rows = @import("error_union_try_rows.zig");
const supportsDirectI64Call = try_rows.supportsDirectI64Call;
const errorUnionTryGuardCallResult = try_rows.errorUnionTryGuardCallResult;
const blockReturnsNamedValue = try_rows.blockReturnsNamedValue;
const successReturnPayloadAdd = try_rows.successReturnPayloadAdd;
const switch_rows = @import("error_union_switch_rows.zig");
const payloadAddWrapValue = switch_rows.payloadAddWrapValue;
const ErrorUnionSwitchPhiCase = switch_rows.ErrorUnionSwitchPhiCase;

pub const BranchThenErrorUnionTryReturn = struct {
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

pub const BranchBothErrorUnionTryReturn = struct {
    entry: ir.BasicBlock,
    then_block: ir.BasicBlock,
    then_stage: BranchTryStage,
    else_block: ir.BasicBlock,
    else_stage: BranchTryStage,
};

pub const SwitchThenErrorUnionTryReturn = struct {
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

pub const SwitchBothErrorUnionTryReturn = struct {
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

pub fn emitErrorUnionTryStageToEpilogue(
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

pub fn branchBothErrorUnionTryReturn(function: ir.Function) ?BranchBothErrorUnionTryReturn {
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

pub fn switchBothErrorUnionTryReturn(function: ir.Function) ?SwitchBothErrorUnionTryReturn {
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

pub fn branchThenErrorUnionTryReturn(function: ir.Function) ?BranchThenErrorUnionTryReturn {
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

pub fn switchThenErrorUnionTryReturn(function: ir.Function) ?SwitchThenErrorUnionTryReturn {
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

pub fn switchArmTryStage(function: ir.Function, block: ir.BasicBlock) ?BranchTryStage {
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

pub fn switchMaskParamConst(function: ir.Function, block: ir.BasicBlock, value: ir.Value) ?i32 {
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

pub fn emitSwitchThenTryCondition(
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

pub fn commonSwitchTryMergeBlock(function: ir.Function, direct_block: ir.BasicBlock, success_block: ir.BasicBlock) ?ir.BasicBlock {
    const direct_target = singleBrTarget(direct_block) orelse return null;
    const success_target = singleBrTarget(success_block) orelse return null;
    if (!std.mem.eql(u8, direct_target, success_target)) return null;
    return function.blocks.items[blockIndex(function, direct_target) orelse return null];
}

pub fn commonSwitchBothTryMergeBlock(function: ir.Function, case_success_block: ir.BasicBlock, default_success_block: ir.BasicBlock) ?ir.BasicBlock {
    const case_target = singleBrTarget(case_success_block) orelse return null;
    const default_target = singleBrTarget(default_success_block) orelse return null;
    if (!std.mem.eql(u8, case_target, default_target)) return null;
    return function.blocks.items[blockIndex(function, case_target) orelse return null];
}

pub fn switchThenTryUsesAllBlocks(
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

pub const BranchTryStage = struct {
    call_name: []const u8,
    call: ir.CallInst,
    success_block: ir.BasicBlock,
    err_block: ir.BasicBlock,
    success_add_imm: u8,
    success_is_then: bool,
};

pub fn branchTryStage(function: ir.Function, block: ir.BasicBlock) ?BranchTryStage {
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

pub fn branchThenTryUsesAllBlocks(
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

pub fn branchBothTryUsesAllBlocks(
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

pub fn switchBothTryUsesAllBlocks(
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

pub fn emitPayloadAddImmWrapFromCallSlot(
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
