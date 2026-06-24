const impl = @import("core_impl.zig");
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

pub const lowerBase64DecodeBase64FullBoundary = impl.lowerBase64DecodeBase64FullBoundary;
pub const lowerBase64DecodeBase64FullMain = impl.lowerBase64DecodeBase64FullMain;
pub const lowerBase64PaddingLoopStep = impl.lowerBase64PaddingLoopStep;
pub const lowerCAbiAssertCFFReturnCode = impl.lowerCAbiAssertCFFReturnCode;
pub const lowerCAbiAssertDCReturnCode = impl.lowerCAbiAssertDCReturnCode;
pub const lowerCAbiAssertPDReturnCode = impl.lowerCAbiAssertPDReturnCode;
pub const lowerCAbiBigPackedStruct = impl.lowerCAbiBigPackedStruct;
pub const lowerCAbiBigStruct = impl.lowerCAbiBigStruct;
pub const lowerCAbiBigStructBoth = impl.lowerCAbiBigStructBoth;
pub const lowerCAbiBigUnion = impl.lowerCAbiBigUnion;
pub const lowerCAbiBool = impl.lowerCAbiBool;
pub const lowerCAbiCmultdComp = impl.lowerCAbiCmultdComp;
pub const lowerCAbiCmultf = impl.lowerCAbiCmultf;
pub const lowerCAbiCmultfComp = impl.lowerCAbiCmultfComp;
pub const lowerCAbiF128AggregateReturn = impl.lowerCAbiF128AggregateReturn;
pub const lowerCAbiF128ScalarReturn = impl.lowerCAbiF128ScalarReturn;
pub const lowerCAbiF128Sret = impl.lowerCAbiF128Sret;
pub const lowerCAbiF32 = impl.lowerCAbiF32;
pub const lowerCAbiF64 = impl.lowerCAbiF64;
pub const lowerCAbiFiveFloats = impl.lowerCAbiFiveFloats;
pub const lowerCAbiFiveIntegers = impl.lowerCAbiFiveIntegers;
pub const lowerCAbiI16 = impl.lowerCAbiI16;
pub const lowerCAbiI32 = impl.lowerCAbiI32;
pub const lowerCAbiI64 = impl.lowerCAbiI64;
pub const lowerCAbiI8 = impl.lowerCAbiI8;
pub const lowerCAbiMedStructInts = impl.lowerCAbiMedStructInts;
pub const lowerCAbiMedStructMixed = impl.lowerCAbiMedStructMixed;
pub const lowerCAbiMultipleStructFloats = impl.lowerCAbiMultipleStructFloats;
pub const lowerCAbiMultipleStructInts = impl.lowerCAbiMultipleStructInts;
pub const lowerCAbiPanic = impl.lowerCAbiPanic;
pub const lowerCAbiPtr = impl.lowerCAbiPtr;
pub const lowerCAbiRetBool = impl.lowerCAbiRetBool;
pub const lowerCAbiRetCFF = impl.lowerCAbiRetCFF;
pub const lowerCAbiRetDC = impl.lowerCAbiRetDC;
pub const lowerCAbiRetI16 = impl.lowerCAbiRetI16;
pub const lowerCAbiRetI64 = impl.lowerCAbiRetI64;
pub const lowerCAbiRetI8 = impl.lowerCAbiRetI8;
pub const lowerCAbiRetMedStructInts = impl.lowerCAbiRetMedStructInts;
pub const lowerCAbiRetMedStructMixed = impl.lowerCAbiRetMedStructMixed;
pub const lowerCAbiRetPD = impl.lowerCAbiRetPD;
pub const lowerCAbiRetSmallStructInts = impl.lowerCAbiRetSmallStructInts;
pub const lowerCAbiRetSplitStructMixed = impl.lowerCAbiRetSplitStructMixed;
pub const lowerCAbiRetStructF32 = impl.lowerCAbiRetStructF32;
pub const lowerCAbiRetStructF32A8 = impl.lowerCAbiRetStructF32A8;
pub const lowerCAbiRetStructF32A8F32A8 = impl.lowerCAbiRetStructF32A8F32A8;
pub const lowerCAbiRetStructF32F32F32 = impl.lowerCAbiRetStructF32F32F32;
pub const lowerCAbiRetStructF64 = impl.lowerCAbiRetStructF64;
pub const lowerCAbiRetStructU16 = impl.lowerCAbiRetStructU16;
pub const lowerCAbiRetStructU32 = impl.lowerCAbiRetStructU32;
pub const lowerCAbiRetStructU32Union = impl.lowerCAbiRetStructU32Union;
pub const lowerCAbiRetStructU64 = impl.lowerCAbiRetStructU64;
pub const lowerCAbiRetStructU64U64 = impl.lowerCAbiRetStructU64U64;
pub const lowerCAbiRetStructU8 = impl.lowerCAbiRetStructU8;
pub const lowerCAbiRetU16 = impl.lowerCAbiRetU16;
pub const lowerCAbiRetU32 = impl.lowerCAbiRetU32;
pub const lowerCAbiRetU64 = impl.lowerCAbiRetU64;
pub const lowerCAbiRetU8 = impl.lowerCAbiRetU8;
pub const lowerCAbiSmallPackedStruct = impl.lowerCAbiSmallPackedStruct;
pub const lowerCAbiSmallStructInts = impl.lowerCAbiSmallStructInts;
pub const lowerCAbiSplitStructInts = impl.lowerCAbiSplitStructInts;
pub const lowerCAbiSplitStructMixed = impl.lowerCAbiSplitStructMixed;
pub const lowerCAbiStructF32 = impl.lowerCAbiStructF32;
pub const lowerCAbiStructF32A8 = impl.lowerCAbiStructF32A8;
pub const lowerCAbiStructF32A8F32A8 = impl.lowerCAbiStructF32A8F32A8;
pub const lowerCAbiStructF32F32F32 = impl.lowerCAbiStructF32F32F32;
pub const lowerCAbiStructF64 = impl.lowerCAbiStructF64;
pub const lowerCAbiStructI128 = impl.lowerCAbiStructI128;
pub const lowerCAbiStructI32I32 = impl.lowerCAbiStructI32I32;
pub const lowerCAbiStructU128 = impl.lowerCAbiStructU128;
pub const lowerCAbiStructU16 = impl.lowerCAbiStructU16;
pub const lowerCAbiStructU32 = impl.lowerCAbiStructU32;
pub const lowerCAbiStructU32Union = impl.lowerCAbiStructU32Union;
pub const lowerCAbiStructU64 = impl.lowerCAbiStructU64;
pub const lowerCAbiStructU64U640 = impl.lowerCAbiStructU64U640;
pub const lowerCAbiStructU64U641 = impl.lowerCAbiStructU64U641;
pub const lowerCAbiStructU64U642 = impl.lowerCAbiStructU64U642;
pub const lowerCAbiStructU64U643 = impl.lowerCAbiStructU64U643;
pub const lowerCAbiStructU64U644 = impl.lowerCAbiStructU64U644;
pub const lowerCAbiStructU64U645 = impl.lowerCAbiStructU64U645;
pub const lowerCAbiStructU64U646 = impl.lowerCAbiStructU64U646;
pub const lowerCAbiStructU64U647 = impl.lowerCAbiStructU64U647;
pub const lowerCAbiStructU64U648 = impl.lowerCAbiStructU64U648;
pub const lowerCAbiStructU8 = impl.lowerCAbiStructU8;
pub const lowerCheckedAddRuntimeBoundaryMain = impl.lowerCheckedAddRuntimeBoundaryMain;
pub const lowerCheckedArraySum = impl.lowerCheckedArraySum;
pub const lowerCheckedBranchMix = impl.lowerCheckedBranchMix;
pub const lowerCheckedCallChain = impl.lowerCheckedCallChain;
pub const lowerCheckedComptimeConst = impl.lowerCheckedComptimeConst;
pub const lowerCheckedDebugLocation = impl.lowerCheckedDebugLocation;
pub const lowerCheckedGlobalUpdate = impl.lowerCheckedGlobalUpdate;
pub const lowerCheckedGlobalUpdateMain = impl.lowerCheckedGlobalUpdateMain;
pub const lowerCheckedIntFromFloat = impl.lowerCheckedIntFromFloat;
pub const lowerCheckedPointerLoadStore = impl.lowerCheckedPointerLoadStore;
pub const lowerCheckedSingleParamAddFunction = impl.lowerCheckedSingleParamAddFunction;
pub const lowerCheckedStructSum = impl.lowerCheckedStructSum;
pub const lowerCheckedTableLookup = impl.lowerCheckedTableLookup;
pub const lowerCheckedTinyAdd = impl.lowerCheckedTinyAdd;
pub const lowerCheckedTlsBump = impl.lowerCheckedTlsBump;
pub const lowerDebugLogicalPointerCompileError = impl.lowerDebugLogicalPointerCompileError;
pub const lowerDebugSpirvMergeLogicalPointers = impl.lowerDebugSpirvMergeLogicalPointers;
pub const lowerDescriptorTableLoopMain = impl.lowerDescriptorTableLoopMain;
pub const lowerFpExponentRuntimeBoundaryMain = impl.lowerFpExponentRuntimeBoundaryMain;
pub const lowerGetauxvalImpl = impl.lowerGetauxvalImpl;
pub const lowerI64PassThroughFunctionFamily = impl.lowerI64PassThroughFunctionFamily;
pub const lowerI64SaturatingHelperFunctionFamily = impl.lowerI64SaturatingHelperFunctionFamily;
pub const lowerIntegerShiftMixReturn = impl.lowerIntegerShiftMixReturn;
pub const lowerMulConstReturn = impl.lowerMulConstReturn;
pub const lowerReleaseSmallStrFromFloatHelp = impl.lowerReleaseSmallStrFromFloatHelp;
pub const lowerReleaseSmallStrFromFloatSupportFunction = impl.lowerReleaseSmallStrFromFloatSupportFunction;
pub const lowerRuntimeSliceSumPreoptHelper = impl.lowerRuntimeSliceSumPreoptHelper;
pub const lowerSelectedInfiniteLoop = impl.lowerSelectedInfiniteLoop;
pub const lowerSelectedIssue339TestFoo = impl.lowerSelectedIssue339TestFoo;
pub const lowerSelectedLibfuzzerDebugO0 = impl.lowerSelectedLibfuzzerDebugO0;
pub const lowerSliceSumLoop = impl.lowerSliceSumLoop;
pub const lowerStartTrampoline = impl.lowerStartTrampoline;
pub const lowerUnreachableStub = impl.lowerUnreachableStub;
pub const lowerVolatileAbsoluteStore = impl.lowerVolatileAbsoluteStore;
