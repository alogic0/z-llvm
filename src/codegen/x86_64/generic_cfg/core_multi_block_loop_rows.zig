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
