const impl = @import("core_impl.zig");
const base64 = @import("core_base64.zig");
const checked = @import("core_checked.zig");
const loop_rows = @import("core_loop_rows.zig");
const std = impl.std;
const ir = impl.ir;

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
pub const lowerDebugLogicalPointerCompileError = impl.lowerDebugLogicalPointerCompileError;
pub const lowerDebugSpirvMergeLogicalPointers = impl.lowerDebugSpirvMergeLogicalPointers;
pub const lowerDescriptorTableLoopMain = checked.lowerDescriptorTableLoopMain;
pub const lowerFpExponentRuntimeBoundaryMain = checked.lowerFpExponentRuntimeBoundaryMain;
pub const lowerI64PassThroughFunctionFamily = impl.lowerI64PassThroughFunctionFamily;
pub const lowerI64SaturatingHelperFunctionFamily = impl.lowerI64SaturatingHelperFunctionFamily;
pub const lowerIntegerShiftMixReturn = impl.lowerIntegerShiftMixReturn;
pub const lowerMulConstReturn = impl.lowerMulConstReturn;
pub const lowerReleaseSmallStrFromFloatHelp = impl.lowerReleaseSmallStrFromFloatHelp;
pub const lowerReleaseSmallStrFromFloatSupportFunction = impl.lowerReleaseSmallStrFromFloatSupportFunction;
pub const lowerRuntimeSliceSumPreoptHelper = loop_rows.lowerRuntimeSliceSumPreoptHelper;
pub const lowerSliceSumLoop = loop_rows.lowerSliceSumLoop;
pub const lowerUnreachableStub = impl.lowerUnreachableStub;
pub const lowerVolatileAbsoluteStore = impl.lowerVolatileAbsoluteStore;
