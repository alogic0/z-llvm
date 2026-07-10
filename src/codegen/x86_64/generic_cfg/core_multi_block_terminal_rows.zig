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
const emitGenericCfgNoreturnCallBlock = pointer_slice_rows.emitGenericCfgNoreturnCallBlock;
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
const genericCfgSupportsSingleBlockIcmp = core_value_support.genericCfgSupportsSingleBlockIcmp;
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

    if (!genericCfgSupportsTerminalBranchCondition(function, entry, condbr.cond)) return false;
    try emitGenericCfgTerminalConditionTrueBranch(allocator, machine, function, entry, entry, condbr.cond, then_block.name);
    try emitGenericCfgTerminalReturnBlock(allocator, machine, function, entry, else_block);
    try appendGenericCfgBlockLabel(allocator, machine, then_block.name);
    try emitGenericCfgTerminalReturnBlock(allocator, machine, function, entry, then_block);
    return true;
}

fn genericCfgSupportsTerminalBranchCondition(function: ir.Function, block: ir.BasicBlock, cond: ir.Value) bool {
    const cond_name = switch (cond) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const cond_inst = findInstruction(block, cond_name) orelse return false;
    const icmp = switch (cond_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    return genericCfgSupportsSingleBlockIcmp(function, null, icmp);
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
