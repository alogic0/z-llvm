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

fn blockByName(function: ir.Function, name: []const u8) ?ir.BasicBlock {
    for (function.blocks.items) |block| {
        if (std.mem.eql(u8, block.name, name)) return block;
    }
    return null;
}

pub fn lowerGenericCfgI128FfsReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 128 })) return false;
    if (function.blocks.items.len != 3) return false;
    const param_name = function.params.items[0].name;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 1) return false;
    const zero_cmp = try validateI128IcmpNamedImm(entry.instructions.items[0], .eq, param_name, 0);
    const entry_branch = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_branch.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_branch.cond, zero_cmp)) return false;

    const zero_block = blockByName(function, entry_branch.then_target) orelse return false;
    const ladder_block = blockByName(function, entry_branch.else_target) orelse return false;
    if (zero_block.instructions.items.len != 1 or ladder_block.instructions.items.len != 43) return false;
    for (ladder_block.instructions.items) |instruction| {
        if (instruction.removed) return false;
    }

    const phi_instruction = zero_block.instructions.items[0];
    const phi_name = phi_instruction.result orelse return error.UnsupportedCodegenInstruction;
    const phi = switch (phi_instruction.kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 32 })) return false;
    const ret = switch (zero_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, phi_name)) return false;
    const ladder_br = switch (ladder_block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };
    if (!std.mem.eql(u8, ladder_br.target, zero_block.name)) return false;

    var cursor: usize = 0;
    const low64 = try validateI128BinaryNamedImm(ladder_block.instructions.items[cursor], .@"and", param_name, 18446744073709551615);
    cursor += 1;
    const low64_is_zero = try validateI128IcmpNamedImm(ladder_block.instructions.items[cursor], .eq, low64, 0);
    cursor += 1;
    const high64 = try validateI128BinaryNamedImm(ladder_block.instructions.items[cursor], .lshr, param_name, 64);
    cursor += 1;
    var count = try validateI128Select(ladder_block.instructions.items[cursor], low64_is_zero, .{ .int = 65 }, .{ .int = 1 });
    cursor += 1;
    var value = try validateI128Select(ladder_block.instructions.items[cursor], low64_is_zero, .{ .named = high64 }, .{ .named = param_name });
    cursor += 1;

    const or_stages = [_]struct { mask: i128, shift: i128, bit: i128 }{
        .{ .mask = 4294967295, .shift = 32, .bit = 32 },
        .{ .mask = 65535, .shift = 16, .bit = 16 },
        .{ .mask = 255, .shift = 8, .bit = 8 },
    };
    for (or_stages) |stage| {
        const masked = try validateI128BinaryNamedImm(ladder_block.instructions.items[cursor], .@"and", value, stage.mask);
        cursor += 1;
        const masked_is_zero = try validateI128IcmpNamedImm(ladder_block.instructions.items[cursor], .eq, masked, 0);
        cursor += 1;
        const next_count = try validateI128BinaryNamedImm(ladder_block.instructions.items[cursor], .@"or", count, stage.bit);
        cursor += 1;
        const shifted = try validateI128BinaryNamedImm(ladder_block.instructions.items[cursor], .lshr, value, stage.shift);
        cursor += 1;
        count = try validateI128Select(ladder_block.instructions.items[cursor], masked_is_zero, .{ .named = next_count }, .{ .named = count });
        cursor += 1;
        value = try validateI128Select(ladder_block.instructions.items[cursor], masked_is_zero, .{ .named = shifted }, .{ .named = value });
        cursor += 1;
    }

    const add_stages = [_]struct { mask: i128, shift: i128, increment: i128 }{
        .{ .mask = 15, .shift = 4, .increment = 4 },
        .{ .mask = 3, .shift = 2, .increment = 2 },
    };
    for (add_stages) |stage| {
        const masked = try validateI128BinaryNamedImm(ladder_block.instructions.items[cursor], .@"and", value, stage.mask);
        cursor += 1;
        const masked_is_zero = try validateI128IcmpNamedImm(ladder_block.instructions.items[cursor], .eq, masked, 0);
        cursor += 1;
        const next_count = try validateI128BinaryNamedImm(ladder_block.instructions.items[cursor], .add, count, stage.increment);
        cursor += 1;
        const shifted = try validateI128BinaryNamedImm(ladder_block.instructions.items[cursor], .lshr, value, stage.shift);
        cursor += 1;
        count = try validateI128Select(ladder_block.instructions.items[cursor], masked_is_zero, .{ .named = next_count }, .{ .named = count });
        cursor += 1;
        value = try validateI128Select(ladder_block.instructions.items[cursor], masked_is_zero, .{ .named = shifted }, .{ .named = value });
        cursor += 1;
    }

    const low_bit = try validateI128BinaryNamedImm(ladder_block.instructions.items[cursor], .@"and", value, 1);
    cursor += 1;
    const shift_delta = try validateI128BinaryNamedImm(ladder_block.instructions.items[cursor], .xor, low_bit, 1);
    cursor += 1;
    const final_count = try validateI128BinaryEitherNamed(ladder_block.instructions.items[cursor], .add, shift_delta, count);
    cursor += 1;
    const final_value = try validateI128BinaryNamed(ladder_block.instructions.items[cursor], .lshr, value, shift_delta);
    cursor += 1;
    const final_bit = try validateI128BinaryNamedImm(ladder_block.instructions.items[cursor], .@"and", final_value, 1);
    cursor += 1;
    const zero_based = try validateI128BinaryNamed(ladder_block.instructions.items[cursor], .sub, final_count, final_bit);
    cursor += 1;
    const zero_based_i32 = try validateI128TruncToI32(ladder_block.instructions.items[cursor], zero_based);
    cursor += 1;
    const one_based_i32 = try validateI32BinaryNamedImm(ladder_block.instructions.items[cursor], .add, zero_based_i32, 1);
    cursor += 1;
    if (cursor != ladder_block.instructions.items.len) return false;
    if (!phiHasIncoming(phi, one_based_i32, ladder_block.name) or !phiHasIncomingInt(phi, 0, entry.name)) return false;

    try machine.instructions.append(allocator, .ffs_i128_rdi_rsi_eax);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub fn lowerGenericCfgI128CtzReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 128 })) return false;
    if (function.blocks.items.len != 3) return false;
    const param_name = function.params.items[0].name;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 1) return false;
    const zero_cmp = try validateI128IcmpNamedImm(entry.instructions.items[0], .eq, param_name, 0);
    const entry_branch = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_branch.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_branch.cond, zero_cmp)) return false;

    const zero_block = blockByName(function, entry_branch.then_target) orelse return false;
    const ladder_block = blockByName(function, entry_branch.else_target) orelse return false;
    if (zero_block.instructions.items.len != 1 or ladder_block.instructions.items.len != 42) return false;
    for (ladder_block.instructions.items) |instruction| {
        if (instruction.removed) return false;
    }

    const phi_instruction = zero_block.instructions.items[0];
    const phi_name = phi_instruction.result orelse return error.UnsupportedCodegenInstruction;
    const phi = switch (phi_instruction.kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 32 })) return false;
    const ret = switch (zero_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, phi_name)) return false;
    const ladder_br = switch (ladder_block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };
    if (!std.mem.eql(u8, ladder_br.target, zero_block.name)) return false;

    var cursor: usize = 0;
    const low64 = try validateI128BinaryNamedImm(ladder_block.instructions.items[cursor], .@"and", param_name, 18446744073709551615);
    cursor += 1;
    const low64_is_zero = try validateI128IcmpNamedImm(ladder_block.instructions.items[cursor], .eq, low64, 0);
    cursor += 1;
    const high64 = try validateI128BinaryNamedImm(ladder_block.instructions.items[cursor], .lshr, param_name, 64);
    cursor += 1;
    var count = try validateI128Select(ladder_block.instructions.items[cursor], low64_is_zero, .{ .int = 65 }, .{ .int = 1 });
    cursor += 1;
    var value = try validateI128Select(ladder_block.instructions.items[cursor], low64_is_zero, .{ .named = high64 }, .{ .named = param_name });
    cursor += 1;

    const or_stages = [_]struct { mask: i128, shift: i128, bit: i128 }{
        .{ .mask = 4294967295, .shift = 32, .bit = 32 },
        .{ .mask = 65535, .shift = 16, .bit = 16 },
        .{ .mask = 255, .shift = 8, .bit = 8 },
    };
    for (or_stages) |stage| {
        const masked = try validateI128BinaryNamedImm(ladder_block.instructions.items[cursor], .@"and", value, stage.mask);
        cursor += 1;
        const masked_is_zero = try validateI128IcmpNamedImm(ladder_block.instructions.items[cursor], .eq, masked, 0);
        cursor += 1;
        const next_count = try validateI128BinaryNamedImm(ladder_block.instructions.items[cursor], .@"or", count, stage.bit);
        cursor += 1;
        const shifted = try validateI128BinaryNamedImm(ladder_block.instructions.items[cursor], .lshr, value, stage.shift);
        cursor += 1;
        count = try validateI128Select(ladder_block.instructions.items[cursor], masked_is_zero, .{ .named = next_count }, .{ .named = count });
        cursor += 1;
        value = try validateI128Select(ladder_block.instructions.items[cursor], masked_is_zero, .{ .named = shifted }, .{ .named = value });
        cursor += 1;
    }

    const add_stages = [_]struct { mask: i128, shift: i128, increment: i128 }{
        .{ .mask = 15, .shift = 4, .increment = 4 },
        .{ .mask = 3, .shift = 2, .increment = 2 },
    };
    for (add_stages) |stage| {
        const masked = try validateI128BinaryNamedImm(ladder_block.instructions.items[cursor], .@"and", value, stage.mask);
        cursor += 1;
        const masked_is_zero = try validateI128IcmpNamedImm(ladder_block.instructions.items[cursor], .eq, masked, 0);
        cursor += 1;
        const next_count = try validateI128BinaryNamedImm(ladder_block.instructions.items[cursor], .add, count, stage.increment);
        cursor += 1;
        const shifted = try validateI128BinaryNamedImm(ladder_block.instructions.items[cursor], .lshr, value, stage.shift);
        cursor += 1;
        count = try validateI128Select(ladder_block.instructions.items[cursor], masked_is_zero, .{ .named = next_count }, .{ .named = count });
        cursor += 1;
        value = try validateI128Select(ladder_block.instructions.items[cursor], masked_is_zero, .{ .named = shifted }, .{ .named = value });
        cursor += 1;
    }

    const low_bit = try validateI128BinaryNamedImm(ladder_block.instructions.items[cursor], .@"and", value, 1);
    cursor += 1;
    const shift_delta = try validateI128BinaryNamedImm(ladder_block.instructions.items[cursor], .xor, low_bit, 1);
    cursor += 1;
    const final_count = try validateI128BinaryEitherNamed(ladder_block.instructions.items[cursor], .add, shift_delta, count);
    cursor += 1;
    const final_value = try validateI128BinaryNamed(ladder_block.instructions.items[cursor], .lshr, value, shift_delta);
    cursor += 1;
    const final_bit = try validateI128BinaryNamedImm(ladder_block.instructions.items[cursor], .@"and", final_value, 1);
    cursor += 1;
    const zero_based = try validateI128BinaryNamed(ladder_block.instructions.items[cursor], .sub, final_count, final_bit);
    cursor += 1;
    const zero_based_i32 = try validateI128TruncToI32(ladder_block.instructions.items[cursor], zero_based);
    cursor += 1;
    if (cursor != ladder_block.instructions.items.len) return false;
    if (!phiHasIncoming(phi, zero_based_i32, ladder_block.name) or !phiHasIncomingInt(phi, 128, entry.name)) return false;

    try machine.instructions.append(allocator, .ctz_i128_rdi_rsi_eax);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub fn lowerGenericCfgI64FfsReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 64 })) return false;
    if (function.blocks.items.len != 3) return false;
    const param_name = function.params.items[0].name;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 1) return false;
    const zero_cmp = try validateI64IcmpNamedImm(entry.instructions.items[0], .eq, param_name, 0);
    const entry_branch = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_branch.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_branch.cond, zero_cmp)) return false;

    const zero_block = blockByName(function, entry_branch.then_target) orelse return false;
    const ladder_block = blockByName(function, entry_branch.else_target) orelse return false;
    if (zero_block.instructions.items.len != 1 or ladder_block.instructions.items.len != 37) return false;
    for (ladder_block.instructions.items) |instruction| {
        if (instruction.removed) return false;
    }

    const phi_instruction = zero_block.instructions.items[0];
    const phi_name = phi_instruction.result orelse return error.UnsupportedCodegenInstruction;
    const phi = switch (phi_instruction.kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 32 })) return false;
    const ret = switch (zero_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, phi_name)) return false;
    const ladder_br = switch (ladder_block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };
    if (!std.mem.eql(u8, ladder_br.target, zero_block.name)) return false;

    var cursor: usize = 0;
    const low32 = try validateI64BinaryNamedImm(ladder_block.instructions.items[cursor], .@"and", param_name, 4294967295);
    cursor += 1;
    const low32_is_zero = try validateI64IcmpNamedImm(ladder_block.instructions.items[cursor], .eq, low32, 0);
    cursor += 1;
    const high32 = try validateI64BinaryNamedImm(ladder_block.instructions.items[cursor], .lshr, param_name, 32);
    cursor += 1;
    var count = try validateI64Select(ladder_block.instructions.items[cursor], low32_is_zero, .{ .int = 33 }, .{ .int = 1 });
    cursor += 1;
    var value = try validateI64Select(ladder_block.instructions.items[cursor], low32_is_zero, .{ .named = high32 }, .{ .named = param_name });
    cursor += 1;

    const or_stages = [_]struct { mask: i128, shift: i128, bit: i128 }{
        .{ .mask = 65535, .shift = 16, .bit = 16 },
        .{ .mask = 255, .shift = 8, .bit = 8 },
        .{ .mask = 15, .shift = 4, .bit = 4 },
    };
    for (or_stages) |stage| {
        const masked = try validateI64BinaryNamedImm(ladder_block.instructions.items[cursor], .@"and", value, stage.mask);
        cursor += 1;
        const masked_is_zero = try validateI64IcmpNamedImm(ladder_block.instructions.items[cursor], .eq, masked, 0);
        cursor += 1;
        const next_count = try validateI64BinaryNamedImm(ladder_block.instructions.items[cursor], .@"or", count, stage.bit);
        cursor += 1;
        const shifted = try validateI64BinaryNamedImm(ladder_block.instructions.items[cursor], .lshr, value, stage.shift);
        cursor += 1;
        count = try validateI64Select(ladder_block.instructions.items[cursor], masked_is_zero, .{ .named = next_count }, .{ .named = count });
        cursor += 1;
        value = try validateI64Select(ladder_block.instructions.items[cursor], masked_is_zero, .{ .named = shifted }, .{ .named = value });
        cursor += 1;
    }

    const masked = try validateI64BinaryNamedImm(ladder_block.instructions.items[cursor], .@"and", value, 3);
    cursor += 1;
    const masked_is_zero = try validateI64IcmpNamedImm(ladder_block.instructions.items[cursor], .eq, masked, 0);
    cursor += 1;
    const next_count = try validateI64BinaryNamedImm(ladder_block.instructions.items[cursor], .add, count, 2);
    cursor += 1;
    const shifted = try validateI64BinaryNamedImm(ladder_block.instructions.items[cursor], .lshr, value, 2);
    cursor += 1;
    count = try validateI64Select(ladder_block.instructions.items[cursor], masked_is_zero, .{ .named = next_count }, .{ .named = count });
    cursor += 1;
    value = try validateI64Select(ladder_block.instructions.items[cursor], masked_is_zero, .{ .named = shifted }, .{ .named = value });
    cursor += 1;

    const low_bit = try validateI64BinaryNamedImm(ladder_block.instructions.items[cursor], .@"and", value, 1);
    cursor += 1;
    const shift_delta = try validateI64BinaryNamedImm(ladder_block.instructions.items[cursor], .xor, low_bit, 1);
    cursor += 1;
    const final_count = try validateI64BinaryEitherNamed(ladder_block.instructions.items[cursor], .add, shift_delta, count);
    cursor += 1;
    const final_value = try validateI64BinaryNamed(ladder_block.instructions.items[cursor], .lshr, value, shift_delta);
    cursor += 1;
    const final_bit = try validateI64BinaryNamedImm(ladder_block.instructions.items[cursor], .@"and", final_value, 1);
    cursor += 1;
    const zero_based = try validateI64BinaryNamed(ladder_block.instructions.items[cursor], .sub, final_count, final_bit);
    cursor += 1;
    const zero_based_i32 = try validateI64TruncToI32(ladder_block.instructions.items[cursor], zero_based);
    cursor += 1;
    const one_based_i32 = try validateI32BinaryNamedImm(ladder_block.instructions.items[cursor], .add, zero_based_i32, 1);
    cursor += 1;
    if (cursor != ladder_block.instructions.items.len) return false;
    if (!phiHasIncoming(phi, one_based_i32, ladder_block.name) or !phiHasIncomingInt(phi, 0, entry.name)) return false;

    try machine.instructions.append(allocator, .ffs_i64_rdi_eax);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub fn lowerGenericCfgI64CtzReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 64 })) return false;
    if (function.blocks.items.len != 3) return false;
    const param_name = function.params.items[0].name;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 1) return false;
    const zero_cmp = try validateI64IcmpNamedImm(entry.instructions.items[0], .eq, param_name, 0);
    const entry_branch = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_branch.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_branch.cond, zero_cmp)) return false;

    const zero_block = blockByName(function, entry_branch.then_target) orelse return false;
    const ladder_block = blockByName(function, entry_branch.else_target) orelse return false;
    if (zero_block.instructions.items.len != 1 or ladder_block.instructions.items.len != 36) return false;
    for (ladder_block.instructions.items) |instruction| {
        if (instruction.removed) return false;
    }

    const phi_instruction = zero_block.instructions.items[0];
    const phi_name = phi_instruction.result orelse return error.UnsupportedCodegenInstruction;
    const phi = switch (phi_instruction.kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 32 })) return false;
    const ret = switch (zero_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, phi_name)) return false;
    const ladder_br = switch (ladder_block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };
    if (!std.mem.eql(u8, ladder_br.target, zero_block.name)) return false;

    var cursor: usize = 0;
    const low32 = try validateI64BinaryNamedImm(ladder_block.instructions.items[cursor], .@"and", param_name, 4294967295);
    cursor += 1;
    const low32_is_zero = try validateI64IcmpNamedImm(ladder_block.instructions.items[cursor], .eq, low32, 0);
    cursor += 1;
    const high32 = try validateI64BinaryNamedImm(ladder_block.instructions.items[cursor], .lshr, param_name, 32);
    cursor += 1;
    var count = try validateI64Select(ladder_block.instructions.items[cursor], low32_is_zero, .{ .int = 33 }, .{ .int = 1 });
    cursor += 1;
    var value = try validateI64Select(ladder_block.instructions.items[cursor], low32_is_zero, .{ .named = high32 }, .{ .named = param_name });
    cursor += 1;

    const or_stages = [_]struct { mask: i128, shift: i128, bit: i128 }{
        .{ .mask = 65535, .shift = 16, .bit = 16 },
        .{ .mask = 255, .shift = 8, .bit = 8 },
        .{ .mask = 15, .shift = 4, .bit = 4 },
    };
    for (or_stages) |stage| {
        const masked = try validateI64BinaryNamedImm(ladder_block.instructions.items[cursor], .@"and", value, stage.mask);
        cursor += 1;
        const masked_is_zero = try validateI64IcmpNamedImm(ladder_block.instructions.items[cursor], .eq, masked, 0);
        cursor += 1;
        const next_count = try validateI64BinaryNamedImm(ladder_block.instructions.items[cursor], .@"or", count, stage.bit);
        cursor += 1;
        const shifted = try validateI64BinaryNamedImm(ladder_block.instructions.items[cursor], .lshr, value, stage.shift);
        cursor += 1;
        count = try validateI64Select(ladder_block.instructions.items[cursor], masked_is_zero, .{ .named = next_count }, .{ .named = count });
        cursor += 1;
        value = try validateI64Select(ladder_block.instructions.items[cursor], masked_is_zero, .{ .named = shifted }, .{ .named = value });
        cursor += 1;
    }

    const masked = try validateI64BinaryNamedImm(ladder_block.instructions.items[cursor], .@"and", value, 3);
    cursor += 1;
    const masked_is_zero = try validateI64IcmpNamedImm(ladder_block.instructions.items[cursor], .eq, masked, 0);
    cursor += 1;
    const next_count = try validateI64BinaryNamedImm(ladder_block.instructions.items[cursor], .add, count, 2);
    cursor += 1;
    const shifted = try validateI64BinaryNamedImm(ladder_block.instructions.items[cursor], .lshr, value, 2);
    cursor += 1;
    count = try validateI64Select(ladder_block.instructions.items[cursor], masked_is_zero, .{ .named = next_count }, .{ .named = count });
    cursor += 1;
    value = try validateI64Select(ladder_block.instructions.items[cursor], masked_is_zero, .{ .named = shifted }, .{ .named = value });
    cursor += 1;

    const low_bit = try validateI64BinaryNamedImm(ladder_block.instructions.items[cursor], .@"and", value, 1);
    cursor += 1;
    const shift_delta = try validateI64BinaryNamedImm(ladder_block.instructions.items[cursor], .xor, low_bit, 1);
    cursor += 1;
    const final_count = try validateI64BinaryEitherNamed(ladder_block.instructions.items[cursor], .add, shift_delta, count);
    cursor += 1;
    const final_value = try validateI64BinaryNamed(ladder_block.instructions.items[cursor], .lshr, value, shift_delta);
    cursor += 1;
    const final_bit = try validateI64BinaryNamedImm(ladder_block.instructions.items[cursor], .@"and", final_value, 1);
    cursor += 1;
    const zero_based = try validateI64BinaryNamed(ladder_block.instructions.items[cursor], .sub, final_count, final_bit);
    cursor += 1;
    const zero_based_i32 = try validateI64TruncToI32(ladder_block.instructions.items[cursor], zero_based);
    cursor += 1;
    if (cursor != ladder_block.instructions.items.len) return false;
    if (!phiHasIncoming(phi, zero_based_i32, ladder_block.name) or !phiHasIncomingInt(phi, 64, entry.name)) return false;

    try machine.instructions.append(allocator, .ctz_i64_rdi_eax);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub fn lowerGenericCfgI32FfsReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 32 })) return false;
    if (function.blocks.items.len != 3) return false;
    const param_name = function.params.items[0].name;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 1) return false;
    const zero_cmp = try validateI32IcmpNamedImm(entry.instructions.items[0], .eq, param_name, 0);
    const entry_branch = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_branch.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_branch.cond, zero_cmp)) return false;

    const zero_block = blockByName(function, entry_branch.then_target) orelse return false;
    const ladder_block = blockByName(function, entry_branch.else_target) orelse return false;
    if (zero_block.instructions.items.len != 1 or ladder_block.instructions.items.len != 30) return false;
    for (ladder_block.instructions.items) |instruction| {
        if (instruction.removed) return false;
    }

    const phi_instruction = zero_block.instructions.items[0];
    const phi_name = phi_instruction.result orelse return error.UnsupportedCodegenInstruction;
    const phi = switch (phi_instruction.kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 32 })) return false;
    const ret = switch (zero_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, phi_name)) return false;
    const ladder_br = switch (ladder_block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };
    if (!std.mem.eql(u8, ladder_br.target, zero_block.name)) return false;

    var cursor: usize = 0;
    const low16 = try validateI32BinaryNamedImm(ladder_block.instructions.items[cursor], .@"and", param_name, 65535);
    cursor += 1;
    const low16_is_zero = try validateI32IcmpNamedImm(ladder_block.instructions.items[cursor], .eq, low16, 0);
    cursor += 1;
    const high16 = try validateI32BinaryNamedImm(ladder_block.instructions.items[cursor], .lshr, param_name, 16);
    cursor += 1;
    var count = try validateI32Select(ladder_block.instructions.items[cursor], low16_is_zero, .{ .int = 17 }, .{ .int = 1 });
    cursor += 1;
    var value = try validateI32Select(ladder_block.instructions.items[cursor], low16_is_zero, .{ .named = high16 }, .{ .named = param_name });
    cursor += 1;

    const or_stages = [_]struct { mask: i128, shift: i128, bit: i128 }{
        .{ .mask = 255, .shift = 8, .bit = 8 },
        .{ .mask = 15, .shift = 4, .bit = 4 },
        .{ .mask = 3, .shift = 2, .bit = 2 },
    };
    for (or_stages) |stage| {
        const masked = try validateI32BinaryNamedImm(ladder_block.instructions.items[cursor], .@"and", value, stage.mask);
        cursor += 1;
        const masked_is_zero = try validateI32IcmpNamedImm(ladder_block.instructions.items[cursor], .eq, masked, 0);
        cursor += 1;
        const next_count = try validateI32BinaryNamedImm(ladder_block.instructions.items[cursor], .@"or", count, stage.bit);
        cursor += 1;
        const shifted = try validateI32BinaryNamedImm(ladder_block.instructions.items[cursor], .lshr, value, stage.shift);
        cursor += 1;
        count = try validateI32Select(ladder_block.instructions.items[cursor], masked_is_zero, .{ .named = next_count }, .{ .named = count });
        cursor += 1;
        value = try validateI32Select(ladder_block.instructions.items[cursor], masked_is_zero, .{ .named = shifted }, .{ .named = value });
        cursor += 1;
    }

    const low_bit = try validateI32BinaryNamedImm(ladder_block.instructions.items[cursor], .@"and", value, 1);
    cursor += 1;
    const shift_delta = try validateI32BinaryNamedImm(ladder_block.instructions.items[cursor], .xor, low_bit, 1);
    cursor += 1;
    const final_value = try validateI32BinaryNamed(ladder_block.instructions.items[cursor], .lshr, value, shift_delta);
    cursor += 1;
    const final_bit = try validateI32BinaryNamedImm(ladder_block.instructions.items[cursor], .@"and", final_value, 1);
    cursor += 1;
    const minus_two_adjust = try validateI32BinaryNamedImm(ladder_block.instructions.items[cursor], .@"or", value, -2);
    cursor += 1;
    const adjust = try validateI32BinaryNamed(ladder_block.instructions.items[cursor], .add, minus_two_adjust, final_bit);
    cursor += 1;
    const one_based_i32 = try validateI32BinaryNamed(ladder_block.instructions.items[cursor], .sub, count, adjust);
    cursor += 1;
    if (cursor != ladder_block.instructions.items.len) return false;
    if (!phiHasIncoming(phi, one_based_i32, ladder_block.name) or !phiHasIncomingInt(phi, 0, entry.name)) return false;

    try machine.instructions.append(allocator, .ffs_i32_edi_eax);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub fn lowerGenericCfgI32CtzReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 32 })) return false;
    if (function.blocks.items.len != 3) return false;
    const param_name = function.params.items[0].name;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 1) return false;
    const zero_cmp = try validateI32IcmpNamedImm(entry.instructions.items[0], .eq, param_name, 0);
    const entry_branch = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_branch.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_branch.cond, zero_cmp)) return false;

    const zero_block = blockByName(function, entry_branch.then_target) orelse return false;
    const ladder_block = blockByName(function, entry_branch.else_target) orelse return false;
    if (zero_block.instructions.items.len != 1 or ladder_block.instructions.items.len != 29) return false;
    for (ladder_block.instructions.items) |instruction| {
        if (instruction.removed) return false;
    }

    const phi_instruction = zero_block.instructions.items[0];
    const phi_name = phi_instruction.result orelse return error.UnsupportedCodegenInstruction;
    const phi = switch (phi_instruction.kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 32 })) return false;
    const ret = switch (zero_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, phi_name)) return false;
    const ladder_br = switch (ladder_block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };
    if (!std.mem.eql(u8, ladder_br.target, zero_block.name)) return false;

    var cursor: usize = 0;
    const low16 = try validateI32BinaryNamedImm(ladder_block.instructions.items[cursor], .@"and", param_name, 65535);
    cursor += 1;
    const low16_is_zero = try validateI32IcmpNamedImm(ladder_block.instructions.items[cursor], .eq, low16, 0);
    cursor += 1;
    const high16 = try validateI32BinaryNamedImm(ladder_block.instructions.items[cursor], .lshr, param_name, 16);
    cursor += 1;
    var count = try validateI32Select(ladder_block.instructions.items[cursor], low16_is_zero, .{ .int = 17 }, .{ .int = 1 });
    cursor += 1;
    var value = try validateI32Select(ladder_block.instructions.items[cursor], low16_is_zero, .{ .named = high16 }, .{ .named = param_name });
    cursor += 1;

    const or_stages = [_]struct { mask: i128, shift: i128, bit: i128 }{
        .{ .mask = 255, .shift = 8, .bit = 8 },
        .{ .mask = 15, .shift = 4, .bit = 4 },
        .{ .mask = 3, .shift = 2, .bit = 2 },
    };
    for (or_stages) |stage| {
        const masked = try validateI32BinaryNamedImm(ladder_block.instructions.items[cursor], .@"and", value, stage.mask);
        cursor += 1;
        const masked_is_zero = try validateI32IcmpNamedImm(ladder_block.instructions.items[cursor], .eq, masked, 0);
        cursor += 1;
        const next_count = try validateI32BinaryNamedImm(ladder_block.instructions.items[cursor], .@"or", count, stage.bit);
        cursor += 1;
        const shifted = try validateI32BinaryNamedImm(ladder_block.instructions.items[cursor], .lshr, value, stage.shift);
        cursor += 1;
        count = try validateI32Select(ladder_block.instructions.items[cursor], masked_is_zero, .{ .named = next_count }, .{ .named = count });
        cursor += 1;
        value = try validateI32Select(ladder_block.instructions.items[cursor], masked_is_zero, .{ .named = shifted }, .{ .named = value });
        cursor += 1;
    }

    const low_bit = try validateI32BinaryNamedImm(ladder_block.instructions.items[cursor], .@"and", value, 1);
    cursor += 1;
    const shift_delta = try validateI32BinaryNamedImm(ladder_block.instructions.items[cursor], .xor, low_bit, 1);
    cursor += 1;
    const final_count = try validateI32BinaryNamed(ladder_block.instructions.items[cursor], .add, shift_delta, count);
    cursor += 1;
    const final_value = try validateI32BinaryNamed(ladder_block.instructions.items[cursor], .lshr, value, shift_delta);
    cursor += 1;
    const final_bit = try validateI32BinaryNamedImm(ladder_block.instructions.items[cursor], .@"and", final_value, 1);
    cursor += 1;
    const zero_based = try validateI32BinaryNamed(ladder_block.instructions.items[cursor], .sub, final_count, final_bit);
    cursor += 1;
    if (cursor != ladder_block.instructions.items.len) return false;
    if (!phiHasIncoming(phi, zero_based, ladder_block.name) or !phiHasIncomingInt(phi, 32, entry.name)) return false;

    try machine.instructions.append(allocator, .ctz_i32_edi_eax);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

fn validateI128BinaryNamedImm(instruction: ir.Instruction, op: ir.BinaryOp, lhs_name: []const u8, rhs_value: i128) ![]const u8 {
    const result_name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (binary.op != op or !binary.ty.eql(.{ .int = 128 }) or !isNamed(binary.lhs, lhs_name) or !isInt(binary.rhs, rhs_value)) return error.UnsupportedCodegenInstruction;
    return result_name;
}

fn validateI64BinaryNamedImm(instruction: ir.Instruction, op: ir.BinaryOp, lhs_name: []const u8, rhs_value: i128) ![]const u8 {
    const result_name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (binary.op != op or !binary.ty.eql(.{ .int = 64 }) or !isNamed(binary.lhs, lhs_name) or !isInt(binary.rhs, rhs_value)) return error.UnsupportedCodegenInstruction;
    return result_name;
}

fn validateI128BinaryNamed(instruction: ir.Instruction, op: ir.BinaryOp, lhs_name: []const u8, rhs_name: []const u8) ![]const u8 {
    const result_name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (binary.op != op or !binary.ty.eql(.{ .int = 128 }) or !isNamed(binary.lhs, lhs_name) or !isNamed(binary.rhs, rhs_name)) return error.UnsupportedCodegenInstruction;
    return result_name;
}

fn validateI64BinaryNamed(instruction: ir.Instruction, op: ir.BinaryOp, lhs_name: []const u8, rhs_name: []const u8) ![]const u8 {
    const result_name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (binary.op != op or !binary.ty.eql(.{ .int = 64 }) or !isNamed(binary.lhs, lhs_name) or !isNamed(binary.rhs, rhs_name)) return error.UnsupportedCodegenInstruction;
    return result_name;
}

fn validateI128BinaryEitherNamed(instruction: ir.Instruction, op: ir.BinaryOp, a_name: []const u8, b_name: []const u8) ![]const u8 {
    const result_name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (binary.op != op or !binary.ty.eql(.{ .int = 128 })) return error.UnsupportedCodegenInstruction;
    const direct = isNamed(binary.lhs, a_name) and isNamed(binary.rhs, b_name);
    const reversed = isNamed(binary.lhs, b_name) and isNamed(binary.rhs, a_name);
    if (!direct and !reversed) return error.UnsupportedCodegenInstruction;
    return result_name;
}

fn validateI64BinaryEitherNamed(instruction: ir.Instruction, op: ir.BinaryOp, a_name: []const u8, b_name: []const u8) ![]const u8 {
    const result_name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (binary.op != op or !binary.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenInstruction;
    const direct = isNamed(binary.lhs, a_name) and isNamed(binary.rhs, b_name);
    const reversed = isNamed(binary.lhs, b_name) and isNamed(binary.rhs, a_name);
    if (!direct and !reversed) return error.UnsupportedCodegenInstruction;
    return result_name;
}

fn validateI32BinaryNamedImm(instruction: ir.Instruction, op: ir.BinaryOp, lhs_name: []const u8, rhs_value: i128) ![]const u8 {
    const result_name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (binary.op != op or !binary.ty.eql(.{ .int = 32 }) or !isNamed(binary.lhs, lhs_name) or !isInt(binary.rhs, rhs_value)) return error.UnsupportedCodegenInstruction;
    return result_name;
}

fn validateI32BinaryNamed(instruction: ir.Instruction, op: ir.BinaryOp, lhs_name: []const u8, rhs_name: []const u8) ![]const u8 {
    const result_name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (binary.op != op or !binary.ty.eql(.{ .int = 32 }) or !isNamed(binary.lhs, lhs_name) or !isNamed(binary.rhs, rhs_name)) return error.UnsupportedCodegenInstruction;
    return result_name;
}

fn validateI32IcmpNamedImm(instruction: ir.Instruction, predicate: ir.IcmpPredicate, lhs_name: []const u8, rhs_value: i128) ![]const u8 {
    const result_name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (icmp.predicate != predicate or !icmp.operand_ty.eql(.{ .int = 32 }) or !isNamed(icmp.lhs, lhs_name) or !isInt(icmp.rhs, rhs_value)) return error.UnsupportedCodegenInstruction;
    return result_name;
}

fn validateI64IcmpNamedImm(instruction: ir.Instruction, predicate: ir.IcmpPredicate, lhs_name: []const u8, rhs_value: i128) ![]const u8 {
    const result_name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (icmp.predicate != predicate or !icmp.operand_ty.eql(.{ .int = 64 }) or !isNamed(icmp.lhs, lhs_name) or !isInt(icmp.rhs, rhs_value)) return error.UnsupportedCodegenInstruction;
    return result_name;
}

fn validateI128IcmpNamedImm(instruction: ir.Instruction, predicate: ir.IcmpPredicate, lhs_name: []const u8, rhs_value: i128) ![]const u8 {
    const result_name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (icmp.predicate != predicate or !icmp.operand_ty.eql(.{ .int = 128 }) or !isNamed(icmp.lhs, lhs_name) or !isInt(icmp.rhs, rhs_value)) return error.UnsupportedCodegenInstruction;
    return result_name;
}

fn validateI32Select(instruction: ir.Instruction, cond_name: []const u8, true_value: ir.Value, false_value: ir.Value) ![]const u8 {
    const result_name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const select = switch (instruction.kind) {
        .select => |select| select,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 }) or !isNamed(select.cond, cond_name) or !select.true_value.eql(true_value) or !select.false_value.eql(false_value)) return error.UnsupportedCodegenInstruction;
    return result_name;
}

fn validateI64Select(instruction: ir.Instruction, cond_name: []const u8, true_value: ir.Value, false_value: ir.Value) ![]const u8 {
    const result_name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const select = switch (instruction.kind) {
        .select => |select| select,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 64 }) or !isNamed(select.cond, cond_name) or !select.true_value.eql(true_value) or !select.false_value.eql(false_value)) return error.UnsupportedCodegenInstruction;
    return result_name;
}

fn validateI128Select(instruction: ir.Instruction, cond_name: []const u8, true_value: ir.Value, false_value: ir.Value) ![]const u8 {
    const result_name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const select = switch (instruction.kind) {
        .select => |select| select,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 128 }) or !isNamed(select.cond, cond_name) or !select.true_value.eql(true_value) or !select.false_value.eql(false_value)) return error.UnsupportedCodegenInstruction;
    return result_name;
}

fn validateI64TruncToI32(instruction: ir.Instruction, value_name: []const u8) ![]const u8 {
    const result_name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const cast = switch (instruction.kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (cast.op != .trunc or !cast.from_ty.eql(.{ .int = 64 }) or !cast.to_ty.eql(.{ .int = 32 }) or !isNamed(cast.value, value_name)) return error.UnsupportedCodegenInstruction;
    return result_name;
}

fn validateI128TruncToI32(instruction: ir.Instruction, value_name: []const u8) ![]const u8 {
    const result_name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const cast = switch (instruction.kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (cast.op != .trunc or !cast.from_ty.eql(.{ .int = 128 }) or !cast.to_ty.eql(.{ .int = 32 }) or !isNamed(cast.value, value_name)) return error.UnsupportedCodegenInstruction;
    return result_name;
}
