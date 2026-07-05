const shared = @import("core_shared.zig");
const misc_rows = @import("core_misc_rows.zig");
const base64 = @import("core_base64.zig");
const checked = @import("core_checked.zig");
const debug_logical_pointer_rows = @import("core_debug_logical_pointer_rows.zig");
const loop_rows = @import("core_loop_rows.zig");
const release_small_rows = @import("core_release_small_rows.zig");
const std = shared.std;
const ir = shared.ir;

pub fn blockByName(function: ir.Function, name: []const u8) ?ir.BasicBlock {
    for (function.blocks.items) |block| {
        if (std.mem.eql(u8, block.name, name)) return block;
    }
    return null;
}

pub fn functionHasCall(function: ir.Function, callee: []const u8) bool {
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            const call = switch (instruction.kind) {
                .call => |call| call,
                else => continue,
            };
            if (std.mem.eql(u8, call.callee, callee)) return true;
        }
    }
    return false;
}

pub fn validateTerminatorBr(block: ir.BasicBlock) ![]const u8 {
    return switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br.target,
        else => error.UnsupportedCodegenControlFlow,
    };
}

pub const lowerBase64DecodeBase64FullBoundary = base64.lowerBase64DecodeBase64FullBoundary;
pub const lowerBase64DecodeBase64FullMain = base64.lowerBase64DecodeBase64FullMain;
pub const lowerBase64PaddingLoopStep = base64.lowerBase64PaddingLoopStep;
pub const lowerCheckedAddRuntimeBoundaryMain = checked.lowerCheckedAddRuntimeBoundaryMain;
pub const lowerCheckedArraySum = checked.lowerCheckedArraySum;
pub const lowerCheckedBranchMix = checked.lowerCheckedBranchMix;
pub const lowerCheckedCallChain = checked.lowerCheckedCallChain;
pub const lowerCheckedComptimeConst = checked.lowerCheckedComptimeConst;
pub const lowerCheckedDebugLocation = checked.lowerCheckedDebugLocation;
pub const lowerCheckedGlobalUpdate = checked.lowerCheckedGlobalUpdate;
pub const lowerCheckedGlobalUpdateMain = checked.lowerCheckedGlobalUpdateMain;
pub const lowerCheckedIntFromFloat = checked.lowerCheckedIntFromFloat;
pub const lowerCheckedPointerLoadStore = checked.lowerCheckedPointerLoadStore;
pub const lowerCheckedSingleParamAddFunction = checked.lowerCheckedSingleParamAddFunction;
pub const lowerCheckedStructSum = checked.lowerCheckedStructSum;
pub const lowerCheckedTableLookup = checked.lowerCheckedTableLookup;
pub const lowerCheckedTinyAdd = checked.lowerCheckedTinyAdd;
pub const lowerCheckedTlsBump = checked.lowerCheckedTlsBump;
pub const lowerDebugLogicalPointerCompileError = debug_logical_pointer_rows.lowerDebugLogicalPointerCompileError;
pub const lowerDebugSpirvMergeLogicalPointers = misc_rows.lowerDebugSpirvMergeLogicalPointers;
pub const lowerDescriptorTableLoopMain = checked.lowerDescriptorTableLoopMain;
pub const lowerFpExponentRuntimeBoundaryMain = checked.lowerFpExponentRuntimeBoundaryMain;
pub const lowerI64PassThroughFunctionFamily = misc_rows.lowerI64PassThroughFunctionFamily;
pub const lowerI64SaturatingHelperFunctionFamily = misc_rows.lowerI64SaturatingHelperFunctionFamily;
pub const lowerIntegerShiftMixReturn = misc_rows.lowerIntegerShiftMixReturn;
pub const lowerMulConstReturn = misc_rows.lowerMulConstReturn;
pub const lowerReleaseSmallStrFromFloatHelp = release_small_rows.lowerReleaseSmallStrFromFloatHelp;
pub const lowerReleaseSmallStrFromFloatSupportFunction = release_small_rows.lowerReleaseSmallStrFromFloatSupportFunction;
pub const lowerRuntimeSliceSumPreoptHelper = loop_rows.lowerRuntimeSliceSumPreoptHelper;
pub const lowerByteScanLenLoop = loop_rows.lowerByteScanLenLoop;
pub const lowerSliceSumLoop = loop_rows.lowerSliceSumLoop;
pub const lowerUnreachableStub = misc_rows.lowerUnreachableStub;
pub const lowerVolatileAbsoluteStore = misc_rows.lowerVolatileAbsoluteStore;
