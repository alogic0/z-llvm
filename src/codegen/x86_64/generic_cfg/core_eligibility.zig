const impl = @import("core_impl.zig");
const diagnostics = @import("core_diagnostics.zig");
const checked = @import("core_checked.zig");
const loop_rows = @import("core_loop_rows.zig");
const single_block_rows = @import("core_single_block_rows.zig");
const std = impl.std;
const ir = impl.ir;

pub const GenericCfgLoopSumPlan = impl.GenericCfgLoopSumPlan;

pub fn lowerGenericCfgFunction(allocator: std.mem.Allocator, machine: *impl.MachineFunction, function: ir.Function) !bool {
    if (try impl.lowerGenericCfgGuardedDynamicPointerLoadReturn(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try impl.lowerGenericCfgOptionalPointerReturn(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try impl.lowerGenericCfgStructBranchUpdateReturn(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try impl.lowerGenericCfgGuardedOptionalPointerBranchReturn(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try impl.lowerGenericCfgBranchMergeReturn(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (genericCfgLoopSumPlan(function)) |plan| {
        try impl.emitGenericCfgLoopSum(allocator, machine, function, plan);
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try loop_rows.lowerGenericCfgConditionalSliceSumLoop(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try impl.lowerGenericCfgGuardedGlobalAddReturn(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try loop_rows.lowerSliceSumLoop(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (impl.genericCfgSupportsCheckedGuard(function)) {
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
    if (!impl.genericCfgSupportsLoopSum(function)) return null;
    return .{ .checked = diagnostics.functionHasCall(function, "llvm.sadd.with.overflow.i32") };
}
pub const lowerGenericCfgMultiBlockCallGlobalCheckMain = single_block_rows.lowerGenericCfgMultiBlockCallGlobalCheckMain;
pub const lowerGenericCfgMultiBlockTwoCallCheckMain = single_block_rows.lowerGenericCfgMultiBlockTwoCallCheckMain;
pub const lowerGenericCfgSingleBlockAggregateAbi = single_block_rows.lowerGenericCfgSingleBlockAggregateAbi;
pub const lowerGenericCfgSingleBlockCallChainMain = single_block_rows.lowerGenericCfgSingleBlockCallChainMain;
pub const lowerGenericCfgSingleBlockCallCheckMain = single_block_rows.lowerGenericCfgSingleBlockCallCheckMain;
pub const lowerGenericCfgSingleBlockDirectCallMain = single_block_rows.lowerGenericCfgSingleBlockDirectCallMain;
pub const lowerGenericCfgSingleBlockEffectBarrier = single_block_rows.lowerGenericCfgSingleBlockEffectBarrier;
pub const lowerGenericCfgSingleBlockFp = single_block_rows.lowerGenericCfgSingleBlockFp;
pub const lowerGenericCfgSingleBlockI64 = single_block_rows.lowerGenericCfgSingleBlockI64;
pub const lowerGenericCfgSingleBlockPackedBits = single_block_rows.lowerGenericCfgSingleBlockPackedBits;
pub const lowerGenericCfgSingleBlockScalar = single_block_rows.lowerGenericCfgSingleBlockScalar;
pub const lowerGenericCfgSingleBlockUpdateGetMain = single_block_rows.lowerGenericCfgSingleBlockUpdateGetMain;
pub const lowerGenericCfgSingleBlockVoid = single_block_rows.lowerGenericCfgSingleBlockVoid;
pub const lowerGenericCfgSingleBlockVoidCallMain = single_block_rows.lowerGenericCfgSingleBlockVoidCallMain;
