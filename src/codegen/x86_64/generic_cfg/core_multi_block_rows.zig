const shared = @import("core_shared.zig");
const core_cfg_emit = @import("core_cfg_emit.zig");
const core_loop_rows = @import("core_loop_rows.zig");
const core_value_support = @import("core_value_support.zig");
const core_value_emit = @import("core_value_emit.zig");
const core_memory_lowering = @import("core_memory_lowering.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");
const cabi_call_lowering = @import("cabi_call_lowering.zig");
const error_union_rows = @import("error_union_rows.zig");
const pointer_slice_rows = @import("pointer_slice_rows.zig");
const aggregate_rows = @import("aggregate_rows.zig");
const optional_rows = @import("optional_rows.zig");
const safety_rows = @import("safety_rows.zig");
const branch_merge_rows = @import("branch_merge_rows.zig");
const terminal_values = @import("terminal_values.zig");

const std = shared.std;
const ir = shared.ir;
const MachineFunction = shared.MachineFunction;
const ArgReg = shared.ArgReg;
const MachineBinaryOp = shared.MachineBinaryOp;

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
const u5Value = shared.u5Value;
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
const genericCfgSupportsBranchIcmp = core_value_support.genericCfgSupportsBranchIcmp;
const genericCfgSupportsPointerNullIcmp = core_value_support.genericCfgSupportsPointerNullIcmp;
const genericCfgSupportsI32Value = core_value_support.genericCfgSupportsI32Value;

pub const lowerGenericCfgLoopTryReturn = error_union_rows.lowerGenericCfgLoopTryReturn;
pub const lowerGenericCfgLinearErrorUnionTryChainReturn = error_union_rows.lowerGenericCfgLinearErrorUnionTryChainReturn;
pub const lowerGenericCfgLinearErrorUnionDiscardPayloadTryChainReturn = error_union_rows.lowerGenericCfgLinearErrorUnionDiscardPayloadTryChainReturn;
pub const lowerGenericCfgErrorUnionTryVoidRewrapErrorReturn = error_union_rows.lowerGenericCfgErrorUnionTryVoidRewrapErrorReturn;
pub const lowerGenericCfgErrorUnionTryRewrapErrorReturn = error_union_rows.lowerGenericCfgErrorUnionTryRewrapErrorReturn;
pub const lowerGenericCfgErrorUnionTrySlotUpdateReturn = error_union_rows.lowerGenericCfgErrorUnionTrySlotUpdateReturn;
pub const lowerGenericCfgErrorUnionTryPayloadCallReturn = error_union_rows.lowerGenericCfgErrorUnionTryPayloadCallReturn;
pub const lowerGenericCfgErrorUnionTryPhiSlotOverrideReturn = error_union_rows.lowerGenericCfgErrorUnionTryPhiSlotOverrideReturn;
pub const lowerGenericCfgErrorUnionTryPayloadBranchReturn = error_union_rows.lowerGenericCfgErrorUnionTryPayloadBranchReturn;
pub const lowerGenericCfgErrorUnionTrySwitchReturn = error_union_rows.lowerGenericCfgErrorUnionTrySwitchReturn;
pub const lowerGenericCfgBranchBothErrorUnionTryReturn = error_union_rows.lowerGenericCfgBranchBothErrorUnionTryReturn;
pub const lowerGenericCfgBranchThenErrorUnionTryReturn = error_union_rows.lowerGenericCfgBranchThenErrorUnionTryReturn;
pub const lowerGenericCfgSwitchBothErrorUnionTryReturn = error_union_rows.lowerGenericCfgSwitchBothErrorUnionTryReturn;
pub const lowerGenericCfgSwitchThenErrorUnionTryReturn = error_union_rows.lowerGenericCfgSwitchThenErrorUnionTryReturn;
pub const lowerGenericCfgErrorUnionSwitchPhiReturn = error_union_rows.lowerGenericCfgErrorUnionSwitchPhiReturn;
pub const lowerGenericCfgErrorUnionErrorTagSwitchReturn = error_union_rows.lowerGenericCfgErrorUnionErrorTagSwitchReturn;
pub const lowerGenericCfgErrorUnionErrorTagBranchReturn = error_union_rows.lowerGenericCfgErrorUnionErrorTagBranchReturn;
pub const lowerGenericCfgErrorUnionCatchValueMergeReturn = error_union_rows.lowerGenericCfgErrorUnionCatchValueMergeReturn;
pub const lowerGenericCfgErrorUnionCatchSwitchReturn = error_union_rows.lowerGenericCfgErrorUnionCatchSwitchReturn;
pub const lowerGenericCfgErrorUnionCatchBranchReturn = error_union_rows.lowerGenericCfgErrorUnionCatchBranchReturn;
pub const lowerGenericCfgErrorUnionCatchCallReturn = error_union_rows.lowerGenericCfgErrorUnionCatchCallReturn;
pub const lowerGenericCfgErrorUnionCatchTerminalReturn = error_union_rows.lowerGenericCfgErrorUnionCatchTerminalReturn;
pub const lowerGenericCfgErrorSetParamSwitchReturn = error_union_rows.lowerGenericCfgErrorSetParamSwitchReturn;
pub const lowerGenericCfgOptionalPointerUnwrapReturn = optional_rows.lowerGenericCfgOptionalPointerUnwrapReturn;
pub const lowerGenericCfgOptionalPointerReturn = optional_rows.lowerGenericCfgOptionalPointerReturn;
pub const lowerGenericCfgOptionalPointerFieldLoadReturn = optional_rows.lowerGenericCfgOptionalPointerFieldLoadReturn;
pub const lowerGenericCfgCheckedOptionalPointerReturn = optional_rows.lowerGenericCfgCheckedOptionalPointerReturn;
pub const lowerGenericCfgGuardedOptionalPointerBranchReturn = optional_rows.lowerGenericCfgGuardedOptionalPointerBranchReturn;
pub const genericCfgOptionalPointerMergeValue = optional_rows.genericCfgOptionalPointerMergeValue;
pub const genericCfgOptionalPointerLoadValue = optional_rows.genericCfgOptionalPointerLoadValue;
pub const genericCfgOptionalPointerMergeHasIncoming = optional_rows.genericCfgOptionalPointerMergeHasIncoming;
pub const genericCfgGuardPanicBlock = safety_rows.genericCfgGuardPanicBlock;
pub const GenericCfgPointerPhiLoad = branch_merge_rows.GenericCfgPointerPhiLoad;
pub const GenericCfgPhiBinaryReturn = branch_merge_rows.GenericCfgPhiBinaryReturn;
pub const appendGenericCfgPhiBinaryImmediate = branch_merge_rows.appendGenericCfgPhiBinaryImmediate;
pub const genericCfgPhiBinaryReturn = branch_merge_rows.genericCfgPhiBinaryReturn;
pub const genericCfgPointerPhiLoadReturn = branch_merge_rows.genericCfgPointerPhiLoadReturn;
pub const lowerGenericCfgStructBranchUpdateReturn = aggregate_rows.lowerGenericCfgStructBranchUpdateReturn;
pub const genericCfgStructFieldZeroUpdateAdd = aggregate_rows.genericCfgStructFieldZeroUpdateAdd;
pub const genericCfgStructFieldZeroMergeReturn = aggregate_rows.genericCfgStructFieldZeroMergeReturn;
pub const emitGenericCfgStructFieldZeroUpdatePath = aggregate_rows.emitGenericCfgStructFieldZeroUpdatePath;
const terminalCondParamReg = terminal_values.terminalCondParamReg;
const genericCfgTerminalBranchExtraBlocksAreUnreachable = terminal_values.genericCfgTerminalBranchExtraBlocksAreUnreachable;
const singleBrTarget = terminal_values.singleBrTarget;
const blockIsUnreachable = terminal_values.blockIsUnreachable;
const blockHasCondbr = terminal_values.blockHasCondbr;
const blockSwitchTerminator = terminal_values.blockSwitchTerminator;
const commonSwitchMergeBlock = terminal_values.commonSwitchMergeBlock;
const firstPhiReturn = terminal_values.firstPhiReturn;
const blockBranchesTo = terminal_values.blockBranchesTo;
const linearTerminalBranchUsesAllBlocks = terminal_values.linearTerminalBranchUsesAllBlocks;
const genericCfgSupportsTerminalReturnBlock = terminal_values.genericCfgSupportsTerminalReturnBlock;
const genericCfgSupportsNestedTerminalReturnBlock = terminal_values.genericCfgSupportsNestedTerminalReturnBlock;
const emitGenericCfgConditionTrueBranch = terminal_values.emitGenericCfgConditionTrueBranch;
const emitGenericCfgTerminalConditionTrueBranch = terminal_values.emitGenericCfgTerminalConditionTrueBranch;
const emitGenericCfgTerminalReturnBlock = terminal_values.emitGenericCfgTerminalReturnBlock;
const emitGenericCfgTerminalReturnBlockInScope = terminal_values.emitGenericCfgTerminalReturnBlockInScope;
const emitGenericCfgTerminalI64ValueIntoRax = terminal_values.emitGenericCfgTerminalI64ValueIntoRax;
const ownedMachineLabel = terminal_values.ownedMachineLabel;

fn blockByName(function: ir.Function, name: []const u8) ?ir.BasicBlock {
    for (function.blocks.items) |block| {
        if (std.mem.eql(u8, block.name, name)) return block;
    }
    return null;
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

pub fn lowerGenericCfgLinearGuardedTerminalReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) and !function.ret_ty.eql(.{ .int = 64 })) return false;
    if (function.blocks.items.len != 5) return false;

    const entry = function.blocks.items[0];
    const entry_condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_condbr.cond_ty.eql(.{ .int = 1 })) return false;

    const first = try genericCfgGuardContinuationSplit(function, entry_condbr);
    const cont_block = first.continuation;
    const cont_condbr = switch (cont_block.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!cont_condbr.cond_ty.eql(.{ .int = 1 })) return false;

    const second = try genericCfgGuardReturnSplit(function, entry, cont_block, cont_condbr);
    if (!genericCfgLinearGuardedReturnUsesAllBlocks(function, cont_block.name, first.panic.name, second.panic.name, second.return_block.name)) return false;

    if (first.true_is_continuation) {
        try emitGenericCfgTerminalConditionTrueBranch(allocator, machine, function, entry, entry, entry_condbr.cond, cont_block.name);
        try appendGenericCfgBlockLabel(allocator, machine, first.panic.name);
        try emitGenericCfgNoreturnCallBlock(allocator, machine, function, first.panic);
        try appendGenericCfgBlockLabel(allocator, machine, cont_block.name);
    } else {
        try emitGenericCfgTerminalConditionTrueBranch(allocator, machine, function, entry, entry, entry_condbr.cond, first.panic.name);
        try appendGenericCfgBlockLabel(allocator, machine, cont_block.name);
    }

    if (second.true_is_return) {
        try emitGenericCfgTerminalConditionTrueBranch(allocator, machine, function, entry, cont_block, cont_condbr.cond, second.return_block.name);
        try appendGenericCfgBlockLabel(allocator, machine, second.panic.name);
        try emitGenericCfgNoreturnCallBlock(allocator, machine, function, second.panic);
        try appendGenericCfgBlockLabel(allocator, machine, second.return_block.name);
        try emitGenericCfgTerminalReturnBlockInScope(allocator, machine, function, .{ .entry = entry, .middle = cont_block, .block = second.return_block });
    } else {
        try emitGenericCfgTerminalConditionTrueBranch(allocator, machine, function, entry, cont_block, cont_condbr.cond, second.panic.name);
        try emitGenericCfgTerminalReturnBlockInScope(allocator, machine, function, .{ .entry = entry, .middle = cont_block, .block = second.return_block });
        try appendGenericCfgBlockLabel(allocator, machine, second.panic.name);
        try emitGenericCfgNoreturnCallBlock(allocator, machine, function, second.panic);
    }

    if (!first.true_is_continuation) {
        try appendGenericCfgBlockLabel(allocator, machine, first.panic.name);
        try emitGenericCfgNoreturnCallBlock(allocator, machine, function, first.panic);
    }
    return true;
}

const GenericCfgGuardContinuationSplit = struct {
    continuation: ir.BasicBlock,
    panic: ir.BasicBlock,
    true_is_continuation: bool,
};

fn genericCfgGuardContinuationSplit(function: ir.Function, condbr: anytype) !GenericCfgGuardContinuationSplit {
    const then_block = blockByName(function, condbr.then_target) orelse return error.InvalidBranchTarget;
    const else_block = blockByName(function, condbr.else_target) orelse return error.InvalidBranchTarget;
    const then_is_cont = blockHasCondbr(then_block);
    const else_is_cont = blockHasCondbr(else_block);
    if (then_is_cont == else_is_cont) return error.UnsupportedCodegenControlFlow;
    const continuation = if (then_is_cont) then_block else else_block;
    const panic = if (then_is_cont) else_block else then_block;
    if (!genericCfgGuardPanicBlock(panic)) return error.UnsupportedCodegenControlFlow;
    return .{
        .continuation = continuation,
        .panic = panic,
        .true_is_continuation = then_is_cont,
    };
}

const GenericCfgGuardReturnSplit = struct {
    return_block: ir.BasicBlock,
    panic: ir.BasicBlock,
    true_is_return: bool,
};

fn genericCfgGuardReturnSplit(
    function: ir.Function,
    entry: ir.BasicBlock,
    continuation: ir.BasicBlock,
    condbr: anytype,
) !GenericCfgGuardReturnSplit {
    const then_block = blockByName(function, condbr.then_target) orelse return error.InvalidBranchTarget;
    const else_block = blockByName(function, condbr.else_target) orelse return error.InvalidBranchTarget;
    const then_is_return = genericCfgSupportsNestedTerminalReturnBlock(function, entry, continuation, then_block);
    const else_is_return = genericCfgSupportsNestedTerminalReturnBlock(function, entry, continuation, else_block);
    if (then_is_return == else_is_return) return error.UnsupportedCodegenControlFlow;
    const return_block = if (then_is_return) then_block else else_block;
    const panic = if (then_is_return) else_block else then_block;
    if (!genericCfgGuardPanicBlock(panic)) return error.UnsupportedCodegenControlFlow;
    return .{
        .return_block = return_block,
        .panic = panic,
        .true_is_return = then_is_return,
    };
}

fn genericCfgLinearGuardedReturnUsesAllBlocks(
    function: ir.Function,
    continuation_name: []const u8,
    first_panic_name: []const u8,
    second_panic_name: []const u8,
    return_name: []const u8,
) bool {
    for (function.blocks.items, 0..) |block, index| {
        if (index == 0 or
            std.mem.eql(u8, block.name, continuation_name) or
            std.mem.eql(u8, block.name, first_panic_name) or
            std.mem.eql(u8, block.name, second_panic_name) or
            std.mem.eql(u8, block.name, return_name))
        {
            continue;
        }
        return false;
    }
    return !std.mem.eql(u8, first_panic_name, second_panic_name) and
        !std.mem.eql(u8, first_panic_name, return_name) and
        !std.mem.eql(u8, second_panic_name, return_name);
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
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len == 0) return false;
    for (function.params.items) |param| {
        if (!param.ty.eql(.{ .int = 32 })) return false;
    }
    if (function.blocks.items.len != 3) return false;

    const entry = function.blocks.items[0];
    if (genericCfgDirectCheckedOverflow(entry)) |checked| {
        const panic_block = blockByName(function, checked.overflow_target) orelse return error.InvalidBranchTarget;
        const ok_block = blockByName(function, checked.ret_target) orelse return error.InvalidBranchTarget;
        try genericCfgValidateDirectCheckedOverflowRet(ok_block, checked.call_name);

        try emitGenericCfgCheckedAddIntoEax(allocator, machine, function, checked.call);
        try appendGenericCfgConditionalBranch(allocator, machine, checked.branch_kind, panic_block.name);
        try appendGenericCfgReturn(allocator, machine);

        try appendGenericCfgBlockLabel(allocator, machine, panic_block.name);
        try emitGenericCfgNoreturnCallBlock(allocator, machine, function, panic_block);
        return true;
    } else |err| switch (err) {
        error.UnsupportedCodegenInstruction,
        error.UnsupportedCodegenType,
        error.UnsupportedCodegenValue,
        error.BlockWithoutTerminator,
        error.UnsupportedCodegenControlFlow,
        => {},
    }

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

const GenericCfgDirectCheckedOverflow = struct {
    call: ir.CallInst,
    call_name: []const u8,
    branch_kind: core_cfg_emit.GenericCfgBranchKind,
    overflow_target: []const u8,
    ret_target: []const u8,
};

fn genericCfgDirectCheckedOverflow(entry: ir.BasicBlock) !GenericCfgDirectCheckedOverflow {
    if (entry.instructions.items.len != 3) return error.UnsupportedCodegenInstruction;
    const call_name = entry.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const overflow_name = entry.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    const cond_name = entry.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;

    const call = switch (entry.instructions.items[0].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (call.callee_value != null or call.inline_asm != null or call.args.items.len != 2) return error.UnsupportedCodegenInstruction;
    if (!call.ret_ty.eql(.{ .aggregate = "{ i32, i1 }" })) return error.UnsupportedCodegenType;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !call.args.items[1].ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
    const branch_kind = checkedOverflowBranchKind(call.callee) orelse return error.UnsupportedCodegenInstruction;

    const overflow_extract = switch (entry.instructions.items[1].kind) {
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

    const cmp = switch (entry.instructions.items[2].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!cmp.operand_ty.eql(.{ .int = 1 }) or !isNamed(cmp.lhs, overflow_name) or !isInt(cmp.rhs, 0)) {
        return error.UnsupportedCodegenInstruction;
    }

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, cond_name)) return error.UnsupportedCodegenValue;

    const BranchTargets = struct {
        ret: []const u8,
        overflow: []const u8,
    };
    const targets: BranchTargets = switch (cmp.predicate) {
        .eq => .{ .ret = condbr.then_target, .overflow = condbr.else_target },
        .ne => .{ .ret = condbr.else_target, .overflow = condbr.then_target },
        else => return error.UnsupportedCodegenInstruction,
    };

    return .{
        .call = call,
        .call_name = call_name,
        .branch_kind = branch_kind,
        .overflow_target = targets.overflow,
        .ret_target = targets.ret,
    };
}

fn genericCfgValidateDirectCheckedOverflowRet(ok: ir.BasicBlock, call_name: []const u8) !void {
    if (ok.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    const value_name = ok.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const value_extract = switch (ok.instructions.items[0].kind) {
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
    const ret = switch (ok.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, value_name)) return error.UnsupportedCodegenValue;
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
    const branch_kind = checkedOverflowBranchKind(call.callee) orelse return error.UnsupportedCodegenInstruction;

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
    if (isCheckedMulOverflowCallee(call.callee)) {
        if ((paramValueReg(function, lhs, .{ .int = 32 }) catch null)) |reg| {
            try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
            try emitGenericCfgCheckedMulOperand(allocator, machine, rhs);
            return;
        }
        if ((paramValueReg(function, rhs, .{ .int = 32 }) catch null)) |reg| {
            try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
            try emitGenericCfgCheckedMulOperand(allocator, machine, lhs);
            return;
        }
        return error.UnsupportedCodegenValue;
    }
    if (isCheckedShlOverflowCallee(call.callee)) {
        const lhs_reg = (paramValueReg(function, lhs, .{ .int = 32 }) catch null) orelse return error.UnsupportedCodegenValue;
        try machine.instructions.append(allocator, .{ .mov_arg_eax = lhs_reg });
        try emitGenericCfgCheckedShlOperand(allocator, machine, rhs);
        return;
    }
    if (isCheckedSubOverflowCallee(call.callee)) {
        const lhs_reg = (paramValueReg(function, lhs, .{ .int = 32 }) catch null) orelse return error.UnsupportedCodegenValue;
        try machine.instructions.append(allocator, .{ .mov_arg_eax = lhs_reg });
        try emitGenericCfgCheckedOverflowOperand(allocator, machine, function, rhs, .sub);
        return;
    }
    if ((paramValueReg(function, lhs, .{ .int = 32 }) catch null)) |reg| {
        try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
        try emitGenericCfgCheckedOverflowOperand(allocator, machine, function, rhs, .add);
        return;
    }
    if ((paramValueReg(function, rhs, .{ .int = 32 }) catch null)) |reg| {
        try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
        try emitGenericCfgCheckedOverflowOperand(allocator, machine, function, lhs, .add);
        return;
    }
    return error.UnsupportedCodegenValue;
}

fn emitGenericCfgCheckedOverflowOperand(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    value: ir.Value,
    op: MachineBinaryOp,
) !void {
    if ((paramValueReg(function, value, .{ .int = 32 }) catch null)) |reg| {
        try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = op, .reg = reg } });
        return;
    }
    if (op != .add) return error.UnsupportedCodegenValue;
    switch (value) {
        .int => |int| try machine.instructions.append(allocator, .{ .add_eax_imm32 = try i32Value(int) }),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

fn emitGenericCfgCheckedMulOperand(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    value: ir.Value,
) !void {
    switch (value) {
        .int => |int| try machine.instructions.append(allocator, .{ .imul_eax_imm32 = try i32Value(int) }),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

fn emitGenericCfgCheckedShlOperand(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    value: ir.Value,
) !void {
    const amount = switch (value) {
        .int => |int| try u5Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    if (amount != 1) return error.UnsupportedCodegenValue;
    try machine.instructions.append(allocator, .{ .shl_eax_imm5 = amount });
}

fn checkedOverflowBranchKind(callee: []const u8) ?core_cfg_emit.GenericCfgBranchKind {
    if (isCalleeName(callee, "llvm.sadd.with.overflow.i32")) return .jo;
    if (isCalleeName(callee, "llvm.uadd.with.overflow.i32")) return .jc;
    if (isCalleeName(callee, "llvm.ssub.with.overflow.i32")) return .jo;
    if (isCalleeName(callee, "llvm.usub.with.overflow.i32")) return .jc;
    if (isCalleeName(callee, "llvm.smul.with.overflow.i32")) return .jo;
    if (isCalleeName(callee, "llvm.ushl.with.overflow.i32")) return .jc;
    return null;
}

fn isCheckedSubOverflowCallee(callee: []const u8) bool {
    return isCalleeName(callee, "llvm.ssub.with.overflow.i32") or
        isCalleeName(callee, "llvm.usub.with.overflow.i32");
}

fn isCheckedMulOverflowCallee(callee: []const u8) bool {
    return isCalleeName(callee, "llvm.smul.with.overflow.i32");
}

fn isCheckedShlOverflowCallee(callee: []const u8) bool {
    return isCalleeName(callee, "llvm.ushl.with.overflow.i32");
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

pub const emitGenericCfgNoreturnCallBlock = pointer_slice_rows.emitGenericCfgNoreturnCallBlock;
pub const validateNoreturnSliceRuntimeCall = pointer_slice_rows.validateNoreturnSliceRuntimeCall;
pub const SlicePointerValue = pointer_slice_rows.SlicePointerValue;
pub const resolveSlicePointerValue = pointer_slice_rows.resolveSlicePointerValue;
pub const SliceLengthValue = pointer_slice_rows.SliceLengthValue;
pub const resolveSliceLengthValue = pointer_slice_rows.resolveSliceLengthValue;
pub const emitSlicePointerIntoRdi = pointer_slice_rows.emitSlicePointerIntoRdi;
pub const emitSliceLengthIntoRsi = pointer_slice_rows.emitSliceLengthIntoRsi;
pub const emitI64ValueIntoArgReg = pointer_slice_rows.emitI64ValueIntoArgReg;
pub const emitNamedI64ValueIntoArgReg = pointer_slice_rows.emitNamedI64ValueIntoArgReg;
pub const emitLoadedI64IntoArgReg = pointer_slice_rows.emitLoadedI64IntoArgReg;
pub const emitComputedI64IntoArgReg = pointer_slice_rows.emitComputedI64IntoArgReg;
const findInstructionInFunction = pointer_slice_rows.findInstructionInFunction;

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

pub fn lowerGenericCfgCheckedLshrExactReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.blocks.items.len != 3) return false;
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

    const cond_inst = findInstruction(entry, cond_name) orelse return false;
    const cmp = switch (cond_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (cmp.predicate != .eq or !cmp.operand_ty.eql(.{ .int = 32 })) return false;

    const source_name, const shl_name = blk: {
        const lhs_name = switch (cmp.lhs) {
            .named => |name| name,
            else => return false,
        };
        const rhs_name = switch (cmp.rhs) {
            .named => |name| name,
            else => return false,
        };
        const lhs_inst = findInstruction(entry, lhs_name) orelse return false;
        const rhs_inst = findInstruction(entry, rhs_name) orelse return false;
        if (rhs_inst.kind == .binary) break :blk .{ lhs_name, rhs_name };
        if (lhs_inst.kind == .binary) break :blk .{ rhs_name, lhs_name };
        return false;
    };

    const shl_inst = findInstruction(entry, shl_name) orelse return false;
    const shl = switch (shl_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (shl.op != .shl or !shl.ty.eql(.{ .int = 32 })) return false;
    const lshr_name = switch (shl.lhs) {
        .named => |name| name,
        else => return false,
    };

    const lshr_inst = findInstruction(entry, lshr_name) orelse return false;
    const lshr = switch (lshr_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (lshr.op != .lshr or !lshr.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(lshr.lhs, source_name)) return false;
    const shift = multiBlockI32Constant(entry, lshr.rhs) orelse return false;
    if (shift <= 0 or shift > 31) return false;

    const inverse_shift = multiBlockI32Constant(entry, shl.rhs) orelse return false;
    if (inverse_shift != shift) return false;

    const cont_block = blockByName(function, condbr.then_target) orelse return error.InvalidBranchTarget;
    const panic_block = blockByName(function, condbr.else_target) orelse return error.InvalidBranchTarget;
    const ret = switch (cont_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, lshr_name)) return false;
    if (cont_block.instructions.items.len != 0) return false;

    const shifted_out_mask: i128 = (@as(i128, 1) << @intCast(shift)) - 1;
    try emitGenericCfgI32ValueIntoEax(allocator, machine, function, entry, lshr.lhs);
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = try i32Value(shifted_out_mask) });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, .jne, panic_block.name);
    try emitGenericCfgI32ValueIntoEax(allocator, machine, function, entry, .{ .named = lshr_name });
    try appendGenericCfgReturn(allocator, machine);

    try appendGenericCfgBlockLabel(allocator, machine, panic_block.name);
    try emitGenericCfgNoreturnCallBlock(allocator, machine, function, panic_block);
    return true;
}

fn multiBlockI32Constant(block: ir.BasicBlock, value: ir.Value) ?i64 {
    return switch (value) {
        .int => |int| i64Value(int) catch null,
        .named => |name| blk: {
            const instruction = findInstruction(block, name) orelse break :blk null;
            break :blk switch (instruction.kind) {
                .cast => |cast| if (cast.op == .zext and cast.to_ty.eql(.{ .int = 32 })) multiBlockI32Constant(block, cast.value) else null,
                else => null,
            };
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
    };
}

pub const lowerGenericCfgErrorUnionPayloadBranchReturn = error_union_rows.lowerGenericCfgErrorUnionPayloadBranchReturn;

pub fn lowerGenericCfgLinearTerminalBranchReturn(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) and !function.ret_ty.eql(.{ .int = 64 })) return false;
    if (try lowerGenericCfgLinearErrorUnionTryChainReturn(allocator, machine, function)) return true;
    if (try lowerGenericCfgLinearErrorUnionDiscardPayloadTryChainReturn(allocator, machine, function)) return true;
    if (try lowerGenericCfgErrorUnionTrySwitchReturn(allocator, machine, function)) return true;
    if (try lowerGenericCfgErrorUnionSwitchPhiReturn(allocator, machine, function)) return true;
    if (try lowerGenericCfgErrorUnionErrorTagSwitchReturn(allocator, machine, function)) return true;
    if (try lowerGenericCfgErrorUnionErrorTagBranchReturn(allocator, machine, function)) return true;
    if (try lowerGenericCfgErrorUnionCatchValueMergeReturn(allocator, machine, function)) return true;
    if (try lowerGenericCfgErrorUnionCatchSwitchReturn(allocator, machine, function)) return true;
    if (try lowerGenericCfgErrorUnionCatchBranchReturn(allocator, machine, function)) return true;
    if (try lowerGenericCfgErrorUnionCatchCallReturn(allocator, machine, function)) return true;
    if (try lowerGenericCfgErrorUnionCatchTerminalReturn(allocator, machine, function)) return true;
    if (try lowerGenericCfgErrorSetParamSwitchReturn(allocator, machine, function)) return true;
    if (try lowerGenericCfgErrorUnionTryVoidRewrapErrorReturn(allocator, machine, function)) return true;
    if (try lowerGenericCfgErrorUnionTryRewrapErrorReturn(allocator, machine, function)) return true;
    if (try lowerGenericCfgErrorUnionTryPayloadCallReturn(allocator, machine, function)) return true;
    if (try lowerGenericCfgErrorUnionTryPhiSlotOverrideReturn(allocator, machine, function)) return true;
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

fn phiIncomingForBlock(phi: ir.PhiInst, block_name: []const u8) ?ir.Value {
    for (phi.incoming.items) |incoming| {
        if (std.mem.eql(u8, incoming.block, block_name)) return incoming.value;
    }
    return null;
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
