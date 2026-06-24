const impl = @import("core_impl.zig");
const diagnostics = @import("core_diagnostics.zig");
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
    if (try impl.lowerGenericCfgConditionalSliceSumLoop(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try impl.lowerGenericCfgGuardedGlobalAddReturn(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try impl.lowerSliceSumLoop(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (impl.genericCfgSupportsCheckedGuard(function)) {
        if (try impl.lowerCheckedIntFromFloat(allocator, machine, function)) {
            machine.codegen_path = .generic_cfg;
            return true;
        }
        if (try impl.lowerCheckedTableLookup(allocator, machine, function)) {
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
    if (!impl.matchesAccumulatorLoop(function) and
        !impl.matchesUnrolledAccumulatorLoop(function) and
        !impl.matchesCheckedUnrolledAccumulatorLoop(function) and
        !impl.matchesGuardedDoWhileAccumulatorLoop(function) and
        !impl.matchesCheckedGuardedDoWhileAccumulatorLoop(function)) return null;
    if (!impl.genericCfgSupportsLoopSum(function)) return null;
    return .{ .checked = diagnostics.functionHasCall(function, "llvm.sadd.with.overflow.i32") };
}
pub const lowerGenericCfgMultiBlockCallGlobalCheckMain = impl.lowerGenericCfgMultiBlockCallGlobalCheckMain;
pub const lowerGenericCfgMultiBlockTwoCallCheckMain = impl.lowerGenericCfgMultiBlockTwoCallCheckMain;
pub const lowerGenericCfgSingleBlockAggregateAbi = impl.lowerGenericCfgSingleBlockAggregateAbi;
pub const lowerGenericCfgSingleBlockCallChainMain = impl.lowerGenericCfgSingleBlockCallChainMain;
pub const lowerGenericCfgSingleBlockCallCheckMain = impl.lowerGenericCfgSingleBlockCallCheckMain;
pub const lowerGenericCfgSingleBlockDirectCallMain = impl.lowerGenericCfgSingleBlockDirectCallMain;
pub const lowerGenericCfgSingleBlockEffectBarrier = impl.lowerGenericCfgSingleBlockEffectBarrier;
pub const lowerGenericCfgSingleBlockFp = impl.lowerGenericCfgSingleBlockFp;
pub const lowerGenericCfgSingleBlockI64 = impl.lowerGenericCfgSingleBlockI64;
pub const lowerGenericCfgSingleBlockPackedBits = impl.lowerGenericCfgSingleBlockPackedBits;
pub const lowerGenericCfgSingleBlockScalar = impl.lowerGenericCfgSingleBlockScalar;
pub const lowerGenericCfgSingleBlockUpdateGetMain = impl.lowerGenericCfgSingleBlockUpdateGetMain;
pub const lowerGenericCfgSingleBlockVoid = impl.lowerGenericCfgSingleBlockVoid;
pub const lowerGenericCfgSingleBlockVoidCallMain = impl.lowerGenericCfgSingleBlockVoidCallMain;
