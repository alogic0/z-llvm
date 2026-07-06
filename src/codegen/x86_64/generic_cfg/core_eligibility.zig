const shared = @import("core_shared.zig");
const diagnostics = @import("core_diagnostics.zig");
const checked = @import("core_checked.zig");
const core_value_support = @import("core_value_support.zig");
const loop_rows = @import("core_loop_rows.zig");
const multi_block_rows = @import("core_multi_block_rows.zig");
const single_block_rows = @import("core_single_block_rows.zig");
const std = shared.std;
const ir = shared.ir;

pub const GenericCfgLoopSumPlan = loop_rows.GenericCfgLoopSumPlan;

pub fn lowerGenericCfgFunction(allocator: std.mem.Allocator, machine: *shared.MachineFunction, function: ir.Function) !bool {
    if (try multi_block_rows.lowerGenericCfgGuardReturnNoreturn(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (multi_block_rows.lowerGenericCfgLinearGuardedTerminalReturn(allocator, machine, function) catch |err| switch (err) {
        error.UnsupportedCodegenInstruction,
        error.UnsupportedCodegenType,
        error.UnsupportedCodegenValue,
        error.UnsupportedCodegenControlFlow,
        error.BlockWithoutTerminator,
        error.InvalidBranchTarget,
        => false,
        else => return err,
    }) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try multi_block_rows.lowerGenericCfgGuardedDynamicPointerLoadPanicReturn(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try multi_block_rows.lowerGenericCfgCheckedSliceStoreLoadReturn(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try multi_block_rows.lowerGenericCfgGuardedDynamicPointerLoadReturn(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try multi_block_rows.lowerGenericCfgOptionalPointerUnwrapReturn(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try multi_block_rows.lowerGenericCfgOptionalPointerReturn(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try multi_block_rows.lowerGenericCfgOptionalPointerFieldLoadReturn(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try multi_block_rows.lowerGenericCfgCheckedOptionalPointerReturn(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try multi_block_rows.lowerGenericCfgStructBranchUpdateReturn(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try multi_block_rows.lowerGenericCfgGuardedOptionalPointerBranchReturn(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try multi_block_rows.lowerGenericCfgErrorUnionPayloadBranchReturn(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (multi_block_rows.lowerGenericCfgI128CtzReturn(allocator, machine, function) catch |err| switch (err) {
        error.UnsupportedCodegenInstruction,
        error.BlockWithoutTerminator,
        error.InvalidRet,
        => false,
        else => return err,
    }) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try multi_block_rows.lowerGenericCfgI128FfsReturn(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (multi_block_rows.lowerGenericCfgI64CtzReturn(allocator, machine, function) catch |err| switch (err) {
        error.UnsupportedCodegenInstruction,
        error.BlockWithoutTerminator,
        error.InvalidRet,
        => false,
        else => return err,
    }) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try multi_block_rows.lowerGenericCfgI64FfsReturn(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (multi_block_rows.lowerGenericCfgI32CtzReturn(allocator, machine, function) catch |err| switch (err) {
        error.UnsupportedCodegenInstruction,
        error.BlockWithoutTerminator,
        error.InvalidRet,
        => false,
        else => return err,
    }) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (multi_block_rows.lowerGenericCfgI32FfsReturn(allocator, machine, function) catch |err| switch (err) {
        error.UnsupportedCodegenInstruction,
        error.BlockWithoutTerminator,
        error.InvalidRet,
        => false,
        else => return err,
    }) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try multi_block_rows.lowerGenericCfgBranchMergeReturn(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try multi_block_rows.lowerGenericCfgLoopTryReturn(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try multi_block_rows.lowerGenericCfgCheckedLshrExactReturn(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (genericCfgLoopSumPlan(function)) |plan| {
        try multi_block_rows.emitGenericCfgLoopSum(allocator, machine, function, plan);
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try loop_rows.lowerGenericCfgConditionalSliceSumLoop(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try loop_rows.lowerByteScanLenLoop(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try loop_rows.lowerGuardedMemmoveCall(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try loop_rows.lowerMemmoveBody(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try loop_rows.lowerMemcpyBody(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try loop_rows.lowerSpinlockedMemcpyBody(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try loop_rows.lowerAtomicCompareExchangeFamily(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try loop_rows.lowerGuardedMemcpyBody(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try loop_rows.lowerGuardedStrncatBody(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try loop_rows.lowerGuardedStrcatBody(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try loop_rows.lowerGuardedStrncpyBody(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try loop_rows.lowerGuardedStrcpyBody(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try loop_rows.lowerGuardedByteMemsetLoop(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try loop_rows.lowerByteMemsetLoop(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try loop_rows.lowerByteCompareDiffLoop(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try loop_rows.lowerByteCompareEqualLoop(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try multi_block_rows.lowerGenericCfgTerminalBranchReturn(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try multi_block_rows.lowerGenericCfgLinearTerminalBranchReturn(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try multi_block_rows.lowerGenericCfgGuardedGlobalAddReturn(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try multi_block_rows.lowerGenericCfgStackCheckedAddReturn(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try loop_rows.lowerSliceSumLoop(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try checked.lowerCheckedIntFromFloat(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (core_value_support.genericCfgSupportsCheckedGuard(function)) {
        if (try checked.lowerCheckedIntFromFloat(allocator, machine, function)) {
            machine.codegen_path = .generic_cfg;
            return true;
        }
        if (try checked.lowerCheckedTableLookup(allocator, machine, function)) {
            machine.codegen_path = .generic_cfg;
            return true;
        }
        return error.GenericCfgFallback;
    }
    return false;
}

pub fn genericCfgLoopSumPlan(function: ir.Function) ?GenericCfgLoopSumPlan {
    if (!function.ret_ty.eql(.{ .int = 32 })) return null;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 32 })) return null;
    if (!loop_rows.matchesAccumulatorLoop(function) and
        !loop_rows.matchesUnrolledAccumulatorLoop(function) and
        !loop_rows.matchesCheckedUnrolledAccumulatorLoop(function) and
        !loop_rows.matchesGuardedDoWhileAccumulatorLoop(function) and
        !loop_rows.matchesCheckedGuardedDoWhileAccumulatorLoop(function)) return null;
    if (!core_value_support.genericCfgSupportsLoopSum(function)) return null;
    return .{ .checked = diagnostics.functionHasCall(function, "llvm.sadd.with.overflow.i32") };
}
pub const lowerGenericCfgMultiBlockCallGlobalCheckMain = single_block_rows.lowerGenericCfgMultiBlockCallGlobalCheckMain;
pub const lowerGenericCfgMultiBlockTwoCallCheckMain = single_block_rows.lowerGenericCfgMultiBlockTwoCallCheckMain;
pub const lowerGenericCfgSingleBlockAggregateAbi = single_block_rows.lowerGenericCfgSingleBlockAggregateAbi;
pub const lowerGenericCfgSingleBlockByteSwap = single_block_rows.lowerGenericCfgSingleBlockByteSwap;
pub const lowerGenericCfgSingleBlockCallChainMain = single_block_rows.lowerGenericCfgSingleBlockCallChainMain;
pub const lowerGenericCfgSingleBlockCallCheckMain = single_block_rows.lowerGenericCfgSingleBlockCallCheckMain;
pub const lowerGenericCfgSingleBlockDirectCallMain = single_block_rows.lowerGenericCfgSingleBlockDirectCallMain;
pub const lowerGenericCfgSingleBlockEffectBarrier = single_block_rows.lowerGenericCfgSingleBlockEffectBarrier;
pub const lowerGenericCfgSingleBlockFp = single_block_rows.lowerGenericCfgSingleBlockFp;
pub const lowerGenericCfgSingleBlockI64 = single_block_rows.lowerGenericCfgSingleBlockI64;
pub const lowerGenericCfgSingleBlockPointerLoadStore = single_block_rows.lowerGenericCfgSingleBlockPointerLoadStore;
pub const lowerGenericCfgSingleBlockSliceLen = single_block_rows.lowerGenericCfgSingleBlockSliceLen;
pub const lowerGenericCfgSingleBlockPackedBits = single_block_rows.lowerGenericCfgSingleBlockPackedBits;
pub const lowerGenericCfgSingleBlockPtr = single_block_rows.lowerGenericCfgSingleBlockPtr;
pub const lowerGenericCfgSingleBlockScalar = single_block_rows.lowerGenericCfgSingleBlockScalar;
pub const lowerGenericCfgSingleBlockUpdateGetMain = single_block_rows.lowerGenericCfgSingleBlockUpdateGetMain;
pub const lowerGenericCfgSingleBlockVoid = single_block_rows.lowerGenericCfgSingleBlockVoid;
pub const lowerGenericCfgSingleBlockVoidCallMain = single_block_rows.lowerGenericCfgSingleBlockVoidCallMain;
