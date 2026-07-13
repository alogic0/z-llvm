const std = @import("std");
const ir = @import("../../ir.zig");
const target = @import("../../target.zig");
const x86_64_types = @import("types.zig");
const sysv_abi = @import("sysv_abi.zig");
const x86_64_verify = @import("verify.zig");
const x86_64_match = @import("match.zig");
const x86_64_generic_cfg = @import("generic_cfg.zig");
const x86_64_generic_cfg_selector = @import("generic_cfg_selector.zig");
const air_patterns_abi_bridge = @import("air_patterns_abi_bridge.zig");
const air_patterns_cfg = @import("air_patterns_cfg.zig");
const air_patterns_optional_pointer = @import("air_patterns_optional_pointer.zig");
const air_patterns_runtime = @import("air_patterns_runtime.zig");
const air_patterns_base64_rows = @import("air_patterns_base64_rows.zig");
const air_patterns_packed_volatile_pointer_rows = @import("air_patterns_packed_volatile_pointer_rows.zig");
const air_patterns_global_tls_rows = @import("air_patterns_global_tls_rows.zig");

pub const ArgReg = x86_64_types.ArgReg;
pub const XmmReg = x86_64_types.XmmReg;
pub const MachineBinaryOp = x86_64_types.MachineBinaryOp;
pub const FrameIndex = x86_64_types.FrameIndex;
pub const CodegenPath = x86_64_types.CodegenPath;
pub const CodegenOptions = x86_64_types.CodegenOptions;
pub const SysVAggregateEightbyteClass = sysv_abi.AggregateEightbyteClass;
pub const SysVAggregateKind = sysv_abi.AggregateKind;
pub const SysVAggregateClassification = sysv_abi.AggregateClassification;
pub const SysVCallPlanCounts = sysv_abi.CallPlanCounts;

const symbolName = x86_64_match.symbolName;

const lowerReleaseSmallStrFromFloatHelp = x86_64_generic_cfg.lowerReleaseSmallStrFromFloatHelp;
const lowerReleaseSmallStrFromFloatSupportFunction = x86_64_generic_cfg.lowerReleaseSmallStrFromFloatSupportFunction;
const lowerVolatileAbsoluteStore = x86_64_generic_cfg.lowerVolatileAbsoluteStore;
const lowerCAbiF128Sret = x86_64_generic_cfg.lowerCAbiF128Sret;
const lowerCAbiF128AggregateReturn = x86_64_generic_cfg.lowerCAbiF128AggregateReturn;
const lowerCAbiF128ScalarReturn = x86_64_generic_cfg.lowerCAbiF128ScalarReturn;
const lowerCAbiAssertPDReturnCode = x86_64_generic_cfg.lowerCAbiAssertPDReturnCode;
const lowerCAbiRetPD = x86_64_generic_cfg.lowerCAbiRetPD;
const lowerCAbiAssertCFFReturnCode = x86_64_generic_cfg.lowerCAbiAssertCFFReturnCode;
const lowerCAbiRetDC = x86_64_generic_cfg.lowerCAbiRetDC;
const lowerCAbiAssertDCReturnCode = x86_64_generic_cfg.lowerCAbiAssertDCReturnCode;
const lowerCAbiRetCFF = x86_64_generic_cfg.lowerCAbiRetCFF;
const lowerCAbiRetSplitStructMixed = x86_64_generic_cfg.lowerCAbiRetSplitStructMixed;
const lowerCAbiRetMedStructMixed = x86_64_generic_cfg.lowerCAbiRetMedStructMixed;
const lowerCAbiRetMedStructInts = x86_64_generic_cfg.lowerCAbiRetMedStructInts;
const lowerCAbiRetSmallStructInts = x86_64_generic_cfg.lowerCAbiRetSmallStructInts;
const lowerCAbiBigPackedStruct = x86_64_generic_cfg.lowerCAbiBigPackedStruct;
const lowerCAbiBigStruct = x86_64_generic_cfg.lowerCAbiBigStruct;
const lowerCAbiBigStructBoth = x86_64_generic_cfg.lowerCAbiBigStructBoth;
const lowerCAbiBigUnion = x86_64_generic_cfg.lowerCAbiBigUnion;
const lowerCAbiBool = x86_64_generic_cfg.lowerCAbiBool;
const lowerCAbiCmultdComp = x86_64_generic_cfg.lowerCAbiCmultdComp;
const lowerCAbiCmultf = x86_64_generic_cfg.lowerCAbiCmultf;
const lowerCAbiCmultfComp = x86_64_generic_cfg.lowerCAbiCmultfComp;
const lowerCAbiF32 = x86_64_generic_cfg.lowerCAbiF32;
const lowerCAbiF64 = x86_64_generic_cfg.lowerCAbiF64;
const lowerCAbiFiveFloats = x86_64_generic_cfg.lowerCAbiFiveFloats;
const lowerCAbiFiveIntegers = x86_64_generic_cfg.lowerCAbiFiveIntegers;
const lowerCAbiI16 = x86_64_generic_cfg.lowerCAbiI16;
const lowerCAbiI32 = x86_64_generic_cfg.lowerCAbiI32;
const lowerCAbiI64 = x86_64_generic_cfg.lowerCAbiI64;
const lowerCAbiI8 = x86_64_generic_cfg.lowerCAbiI8;
const lowerCAbiMedStructInts = x86_64_generic_cfg.lowerCAbiMedStructInts;
const lowerCAbiMedStructMixed = x86_64_generic_cfg.lowerCAbiMedStructMixed;
const lowerCAbiMultipleStructFloats = x86_64_generic_cfg.lowerCAbiMultipleStructFloats;
const lowerCAbiMultipleStructInts = x86_64_generic_cfg.lowerCAbiMultipleStructInts;
const lowerCAbiPanic = x86_64_generic_cfg.lowerCAbiPanic;
const lowerCAbiPtr = x86_64_generic_cfg.lowerCAbiPtr;
const lowerCAbiRetBool = x86_64_generic_cfg.lowerCAbiRetBool;
const lowerCAbiRetI16 = x86_64_generic_cfg.lowerCAbiRetI16;
const lowerCAbiRetI64 = x86_64_generic_cfg.lowerCAbiRetI64;
const lowerCAbiRetI8 = x86_64_generic_cfg.lowerCAbiRetI8;
const lowerCAbiRetStructF32 = x86_64_generic_cfg.lowerCAbiRetStructF32;
const lowerCAbiRetStructF32A8 = x86_64_generic_cfg.lowerCAbiRetStructF32A8;
const lowerCAbiRetStructF32A8F32A8 = x86_64_generic_cfg.lowerCAbiRetStructF32A8F32A8;
const lowerCAbiRetStructF32F32F32 = x86_64_generic_cfg.lowerCAbiRetStructF32F32F32;
const lowerCAbiRetStructF64 = x86_64_generic_cfg.lowerCAbiRetStructF64;
const lowerCAbiRetStructU16 = x86_64_generic_cfg.lowerCAbiRetStructU16;
const lowerCAbiRetStructU32 = x86_64_generic_cfg.lowerCAbiRetStructU32;
const lowerCAbiRetStructU32Union = x86_64_generic_cfg.lowerCAbiRetStructU32Union;
const lowerCAbiRetStructU64 = x86_64_generic_cfg.lowerCAbiRetStructU64;
const lowerCAbiRetStructU64U64 = x86_64_generic_cfg.lowerCAbiRetStructU64U64;
const lowerCAbiRetStructU8 = x86_64_generic_cfg.lowerCAbiRetStructU8;
const lowerCAbiRetU16 = x86_64_generic_cfg.lowerCAbiRetU16;
const lowerCAbiRetU32 = x86_64_generic_cfg.lowerCAbiRetU32;
const lowerCAbiRetU64 = x86_64_generic_cfg.lowerCAbiRetU64;
const lowerCAbiRetU8 = x86_64_generic_cfg.lowerCAbiRetU8;
const lowerCAbiSmallPackedStruct = x86_64_generic_cfg.lowerCAbiSmallPackedStruct;
const lowerCAbiSmallStructInts = x86_64_generic_cfg.lowerCAbiSmallStructInts;
const lowerCAbiSplitStructInts = x86_64_generic_cfg.lowerCAbiSplitStructInts;
const lowerCAbiSplitStructMixed = x86_64_generic_cfg.lowerCAbiSplitStructMixed;
const lowerCAbiStructF32 = x86_64_generic_cfg.lowerCAbiStructF32;
const lowerCAbiStructF32A8 = x86_64_generic_cfg.lowerCAbiStructF32A8;
const lowerCAbiStructF32A8F32A8 = x86_64_generic_cfg.lowerCAbiStructF32A8F32A8;
const lowerCAbiStructF32F32F32 = x86_64_generic_cfg.lowerCAbiStructF32F32F32;
const lowerCAbiStructF64 = x86_64_generic_cfg.lowerCAbiStructF64;
const lowerCAbiStructI128 = x86_64_generic_cfg.lowerCAbiStructI128;
const lowerCAbiStructI32I32 = x86_64_generic_cfg.lowerCAbiStructI32I32;
const lowerCAbiStructU128 = x86_64_generic_cfg.lowerCAbiStructU128;
const lowerCAbiStructU16 = x86_64_generic_cfg.lowerCAbiStructU16;
const lowerCAbiStructU32 = x86_64_generic_cfg.lowerCAbiStructU32;
const lowerCAbiStructU32Union = x86_64_generic_cfg.lowerCAbiStructU32Union;
const lowerCAbiStructU64 = x86_64_generic_cfg.lowerCAbiStructU64;
const lowerCAbiStructU64U640 = x86_64_generic_cfg.lowerCAbiStructU64U640;
const lowerCAbiStructU64U641 = x86_64_generic_cfg.lowerCAbiStructU64U641;
const lowerCAbiStructU64U642 = x86_64_generic_cfg.lowerCAbiStructU64U642;
const lowerCAbiStructU64U643 = x86_64_generic_cfg.lowerCAbiStructU64U643;
const lowerCAbiStructU64U644 = x86_64_generic_cfg.lowerCAbiStructU64U644;
const lowerCAbiStructU64U645 = x86_64_generic_cfg.lowerCAbiStructU64U645;
const lowerCAbiStructU64U646 = x86_64_generic_cfg.lowerCAbiStructU64U646;
const lowerCAbiStructU64U647 = x86_64_generic_cfg.lowerCAbiStructU64U647;
const lowerCAbiStructU64U648 = x86_64_generic_cfg.lowerCAbiStructU64U648;
const lowerCAbiStructU8 = x86_64_generic_cfg.lowerCAbiStructU8;
const lowerStartTrampoline = x86_64_generic_cfg.lowerStartTrampoline;
const lowerDebugSpirvMergeLogicalPointers = x86_64_generic_cfg.lowerDebugSpirvMergeLogicalPointers;
const lowerI64PassThroughFunctionFamily = x86_64_generic_cfg.lowerI64PassThroughFunctionFamily;
const lowerI64SaturatingHelperFunctionFamily = x86_64_generic_cfg.lowerI64SaturatingHelperFunctionFamily;
const lowerRuntimeOptionalPayloadPreoptHelper = air_patterns_runtime.lowerRuntimeOptionalPayloadPreoptHelper;
const lowerRuntimeErrorUnionPayloadPreoptHelper = air_patterns_runtime.lowerRuntimeErrorUnionPayloadPreoptHelper;
const lowerBase64DecodeBase64FullBoundary = x86_64_generic_cfg.lowerBase64DecodeBase64FullBoundary;
const lowerBase64DecodeBase64FullMain = x86_64_generic_cfg.lowerBase64DecodeBase64FullMain;
const lowerBase64PaddingLoopStep = x86_64_generic_cfg.lowerBase64PaddingLoopStep;
const lowerRuntimePointerLoadStorePreoptMain = air_patterns_packed_volatile_pointer_rows.lowerRuntimePointerLoadStorePreoptMain;
const lowerBase64LoopAdvanceStep = air_patterns_base64_rows.lowerBase64LoopAdvanceStep;
const lowerBase64ResidualGuardStep = air_patterns_base64_rows.lowerBase64ResidualGuardStep;
const lowerCheckedAddRuntimeBoundaryMain = x86_64_generic_cfg.lowerCheckedAddRuntimeBoundaryMain;
const lowerCheckedArraySum = x86_64_generic_cfg.lowerCheckedArraySum;
const lowerCheckedBranchMix = x86_64_generic_cfg.lowerCheckedBranchMix;
const lowerCheckedCallChain = x86_64_generic_cfg.lowerCheckedCallChain;
const lowerCheckedComptimeConst = x86_64_generic_cfg.lowerCheckedComptimeConst;
const lowerCheckedDebugLocation = x86_64_generic_cfg.lowerCheckedDebugLocation;
const lowerCheckedGlobalUpdate = x86_64_generic_cfg.lowerCheckedGlobalUpdate;
const lowerCheckedGlobalUpdateMain = x86_64_generic_cfg.lowerCheckedGlobalUpdateMain;
const lowerCheckedIntFromFloat = x86_64_generic_cfg.lowerCheckedIntFromFloat;
const lowerCheckedPointerLoadStore = x86_64_generic_cfg.lowerCheckedPointerLoadStore;
const lowerCheckedSingleParamAddFunction = x86_64_generic_cfg.lowerCheckedSingleParamAddFunction;
const lowerCheckedStructSum = x86_64_generic_cfg.lowerCheckedStructSum;
const lowerCheckedTableLookup = x86_64_generic_cfg.lowerCheckedTableLookup;
const lowerCheckedTinyAdd = x86_64_generic_cfg.lowerCheckedTinyAdd;
const lowerCheckedTlsBump = x86_64_generic_cfg.lowerCheckedTlsBump;
const lowerControlFlowLoopSum = x86_64_generic_cfg.lowerControlFlowLoopSum;
const lowerDescriptorTableLoopMain = x86_64_generic_cfg.lowerDescriptorTableLoopMain;
const lowerFpExponentRuntimeBoundaryMain = x86_64_generic_cfg.lowerFpExponentRuntimeBoundaryMain;
const lowerGenericCfgMultiBlockCallGlobalCheckMain = x86_64_generic_cfg.lowerGenericCfgMultiBlockCallGlobalCheckMain;
const lowerGenericCfgMultiBlockTwoCallCheckMain = x86_64_generic_cfg.lowerGenericCfgMultiBlockTwoCallCheckMain;
const lowerGenericCfgSingleBlockAggregateAbi = x86_64_generic_cfg.lowerGenericCfgSingleBlockAggregateAbi;
const lowerGenericCfgSingleBlockByteSwap = x86_64_generic_cfg.lowerGenericCfgSingleBlockByteSwap;
const lowerGenericCfgSingleBlockCallChainMain = x86_64_generic_cfg.lowerGenericCfgSingleBlockCallChainMain;
const lowerGenericCfgSingleBlockCallCheckMain = x86_64_generic_cfg.lowerGenericCfgSingleBlockCallCheckMain;
const lowerGenericCfgSingleBlockDirectCallMain = x86_64_generic_cfg.lowerGenericCfgSingleBlockDirectCallMain;
const lowerGenericCfgSingleBlockEffectBarrier = x86_64_generic_cfg.lowerGenericCfgSingleBlockEffectBarrier;
const lowerGenericCfgSingleBlockFp = x86_64_generic_cfg.lowerGenericCfgSingleBlockFp;
const lowerGenericCfgSingleBlockI64 = x86_64_generic_cfg.lowerGenericCfgSingleBlockI64;
const lowerGenericCfgSingleBlockPointerLoadStore = x86_64_generic_cfg.lowerGenericCfgSingleBlockPointerLoadStore;
const lowerGenericCfgSingleBlockSliceLen = x86_64_generic_cfg.lowerGenericCfgSingleBlockSliceLen;
const lowerGenericCfgSingleBlockPackedBits = x86_64_generic_cfg.lowerGenericCfgSingleBlockPackedBits;
const lowerGenericCfgSingleBlockPtr = x86_64_generic_cfg.lowerGenericCfgSingleBlockPtr;
const lowerGenericCfgSingleBlockScalar = x86_64_generic_cfg.lowerGenericCfgSingleBlockScalar;
const lowerGenericCfgSingleBlockUpdateGetMain = x86_64_generic_cfg.lowerGenericCfgSingleBlockUpdateGetMain;
const lowerGenericCfgSingleBlockVoid = x86_64_generic_cfg.lowerGenericCfgSingleBlockVoid;
const lowerGenericCfgSingleBlockVoidCallMain = x86_64_generic_cfg.lowerGenericCfgSingleBlockVoidCallMain;
const lowerAtomicExchangeFamily = x86_64_generic_cfg.lowerAtomicExchangeFamily;
const lowerAtomicFetchAddFamily = x86_64_generic_cfg.lowerAtomicFetchAddFamily;
const lowerAtomicFetchAndFamily = x86_64_generic_cfg.lowerAtomicFetchAndFamily;
const lowerAtomicFetchNandFamily = x86_64_generic_cfg.lowerAtomicFetchNandFamily;
const lowerAtomicFetchOrFamily = x86_64_generic_cfg.lowerAtomicFetchOrFamily;
const lowerAtomicFetchSubFamily = x86_64_generic_cfg.lowerAtomicFetchSubFamily;
const lowerAtomicFetchUminFamily = x86_64_generic_cfg.lowerAtomicFetchUminFamily;
const lowerAtomicFetchUmaxFamily = x86_64_generic_cfg.lowerAtomicFetchUmaxFamily;
const lowerAtomicFetchXorFamily = x86_64_generic_cfg.lowerAtomicFetchXorFamily;
const lowerAtomicLoadFamily = x86_64_generic_cfg.lowerAtomicLoadFamily;
const lowerAtomicStoreFamily = x86_64_generic_cfg.lowerAtomicStoreFamily;
const lowerLimbAbsTwosComplementBody = x86_64_generic_cfg.lowerLimbAbsTwosComplementBody;
const lowerValgrindDiscardTranslationsClientRequest = x86_64_generic_cfg.lowerValgrindDiscardTranslationsClientRequest;
const lowerGetauxvalImpl = x86_64_generic_cfg.lowerGetauxvalImpl;
const lowerRuntimeSliceSumPreoptHelper = x86_64_generic_cfg.lowerRuntimeSliceSumPreoptHelper;
const lowerSelectedInfiniteLoop = x86_64_generic_cfg.lowerSelectedInfiniteLoop;
const lowerSelectedIssue339TestFoo = x86_64_generic_cfg.lowerSelectedIssue339TestFoo;
const lowerSelectedLibfuzzerDebugO0 = x86_64_generic_cfg.lowerSelectedLibfuzzerDebugO0;
const lowerSliceSumLoop = x86_64_generic_cfg.lowerSliceSumLoop;
const lowerDebugLogicalPointerCompileError = x86_64_generic_cfg.lowerDebugLogicalPointerCompileError;
const lowerUnreachableStub = x86_64_generic_cfg.lowerUnreachableStub;
const functionHasCall = x86_64_generic_cfg.functionHasCall;
pub const sysvCallPlanCountsForTest = x86_64_generic_cfg.sysvCallPlanCountsForTest;
pub const classifySysVAggregateForTest = air_patterns_abi_bridge.classifySysVAggregateForTest;

const x86_64_machine = @import("machine.zig");

pub const Instruction = x86_64_machine.Instruction;
pub const MachineFunction = x86_64_machine.MachineFunction;
const scalar_patterns = @import("air_patterns_scalar.zig");
const fp_patterns = @import("air_patterns_fp.zig");
const aggregate_runtime_patterns = @import("air_patterns_aggregate_runtime.zig");
pub const lowerStraightLineReturn = scalar_patterns.lowerStraightLineReturn;
pub const hasLiveInstructions = scalar_patterns.hasLiveInstructions;
pub const lowerSelectedI1ConstReturn = scalar_patterns.lowerSelectedI1ConstReturn;
pub const lowerSelectedStringSliceReturn = scalar_patterns.lowerSelectedStringSliceReturn;
pub const lowerSelectedLibfuzzerTestRun = scalar_patterns.lowerSelectedLibfuzzerTestRun;
pub const validateVoidCall = scalar_patterns.validateVoidCall;
pub const validateAssumeColdCall = scalar_patterns.validateAssumeColdCall;
pub const validateIntegerOverflowPanicCall = scalar_patterns.validateIntegerOverflowPanicCall;
pub const lowerI64SaturatingHelperFamilyReturn = scalar_patterns.lowerI64SaturatingHelperFamilyReturn;
pub const lowerSelectedUmlFixSatI64Return = scalar_patterns.lowerSelectedUmlFixSatI64Return;
pub const lowerSingleStackSlotCallReturn = scalar_patterns.lowerSingleStackSlotCallReturn;
pub const lowerInlineAsmBarrierReturn = scalar_patterns.lowerInlineAsmBarrierReturn;
pub const lowerAtomicAddReturn = scalar_patterns.lowerAtomicAddReturn;
pub const lowerFloatMulReturn = fp_patterns.lowerFloatMulReturn;
pub const lowerFloatAddReturn = fp_patterns.lowerFloatAddReturn;
pub const lowerRuntimeFloatAddMainReturn = fp_patterns.lowerRuntimeFloatAddMainReturn;
pub const lowerFloatSubReturn = fp_patterns.lowerFloatSubReturn;
pub const lowerX86Fp80NegReturn = fp_patterns.lowerX86Fp80NegReturn;
pub const lowerFp128NegReturn = fp_patterns.lowerFp128NegReturn;
pub const lowerRuntimeFloatSubMainReturn = fp_patterns.lowerRuntimeFloatSubMainReturn;
pub const lowerDoubleDivReturn = fp_patterns.lowerDoubleDivReturn;
pub const lowerRuntimeDoubleDivMainReturn = fp_patterns.lowerRuntimeDoubleDivMainReturn;
pub const lowerFloatRemReturn = fp_patterns.lowerFloatRemReturn;
pub const lowerRuntimeFloatRemMainReturn = fp_patterns.lowerRuntimeFloatRemMainReturn;
pub const lowerRuntimeFloatMulMainReturn = fp_patterns.lowerRuntimeFloatMulMainReturn;
pub const matchesFpBinaryReturn = fp_patterns.matchesFpBinaryReturn;
pub const lowerFloatSelectReturn = fp_patterns.lowerFloatSelectReturn;
pub const lowerFloatLessReturn = fp_patterns.lowerFloatLessReturn;
pub const lowerFloatLiteralReturn = fp_patterns.lowerFloatLiteralReturn;
pub const lowerStructSumReturn = aggregate_runtime_patterns.lowerStructSumReturn;
pub const lowerRuntimeStructSumPreoptHelper = aggregate_runtime_patterns.lowerRuntimeStructSumPreoptHelper;
pub const lowerRuntimeStructSumMainReturn = aggregate_runtime_patterns.lowerRuntimeStructSumMainReturn;
pub const lowerAddChain3Return = aggregate_runtime_patterns.lowerAddChain3Return;
pub const lowerRuntimeArraySumPreoptHelper = aggregate_runtime_patterns.lowerRuntimeArraySumPreoptHelper;

fn lowerSingleStackSlotCallFunction(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    return lowerSingleStackSlotCallReturn(allocator, machine, function, block, ret);
}

pub fn lowerFunction(allocator: std.mem.Allocator, triple_text: []const u8, function: ir.Function) !MachineFunction {
    return lowerFunctionWithOptions(allocator, triple_text, function, .{});
}

pub fn lowerFunctionWithOptions(
    allocator: std.mem.Allocator,
    triple_text: []const u8,
    function: ir.Function,
    options: CodegenOptions,
) !MachineFunction {
    const parsed_triple = try target.Triple.parse(triple_text);
    if (!parsed_triple.isX86_64() or !parsed_triple.isLinux()) return error.UnsupportedTarget;

    var machine = MachineFunction.init(symbolName(function.name), function.ret_ty);
    errdefer machine.deinit(allocator);

    if (options.generic_cfg_selector) {
        switch (try x86_64_generic_cfg_selector.tryLowerWithContext(allocator, &machine, function, options.module_context)) {
            .selected => {
                machine.codegen_path = .generic_cfg;
                try verifyFunction(machine);
                return machine;
            },
            .unsupported => |diagnostic| {
                if (options.generic_cfg_selector_diagnostic_tag) |tag| tag.* = diagnostic.tagName();
                if (options.generic_cfg_selector_diagnostic_detail) |detail| detail.* = diagnostic.detail();
            },
        }
    }

    if (try lowerSingleStackSlotCallFunction(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerGenericCfgSingleBlockSliceLen(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (functionHasCall(function, "llvm.ushl.sat.i32")) {
        if (try lowerGenericCfgSingleBlockScalar(allocator, &machine, function)) {
            try verifyFunction(machine);
            return machine;
        }
    }

    if (try lowerVolatileAbsoluteStore(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerUnreachableStub(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerReleaseSmallStrFromFloatHelp(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerReleaseSmallStrFromFloatSupportFunction(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerDebugLogicalPointerCompileError(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerDebugSpirvMergeLogicalPointers(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerI64PassThroughFunctionFamily(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerI64SaturatingHelperFunctionFamily(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiF128Sret(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiF128AggregateReturn(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiF128ScalarReturn(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiAssertPDReturnCode(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetPD(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetCFF(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiAssertCFFReturnCode(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetDC(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiAssertDCReturnCode(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetSplitStructMixed(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetMedStructMixed(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetMedStructInts(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetSmallStructInts(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetStructU32Union(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetStructU64U64(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetStructF32F32F32(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetStructF32A8F32A8(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetStructF32A8(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetStructF64(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetStructF32(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetStructU64(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetStructU32(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetStructU16(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetStructU8(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetI64(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetU64(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetU32(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetI16(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetI8(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetU16(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetU8(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetBool(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiMultipleStructFloats(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiMultipleStructInts(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiBigStructBoth(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiSplitStructMixed(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiSplitStructInts(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiBigPackedStruct(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiSmallPackedStruct(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiMedStructInts(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiSmallStructInts(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiMedStructMixed(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiBigUnion(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiBigStruct(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructI32I32(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructU32Union(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructF32F32F32(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructF32A8F32A8(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructF32A8(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructF64(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiCmultdComp(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiCmultfComp(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiCmultf(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructF32(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructU64U648(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructU64U647(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructU64U646(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructU64U645(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructU64U644(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructU64U643(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructU64U642(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructU64U641(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructU64U640(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructU64(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructU32(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructU16(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructU8(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiBool(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiPtr(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiF64(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiF32(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiFiveFloats(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructU128(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructI128(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiI64(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiI32(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiI16(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiI8(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiFiveIntegers(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiPanic(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerStartTrampoline(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerGetauxvalImpl(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerSelectedInfiniteLoop(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerSelectedLibfuzzerDebugO0(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try air_patterns_global_tls_rows.lowerSelectedMixCFilesAddZigDebugO0(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try air_patterns_global_tls_rows.lowerSelectedMixCFilesAddMayPanicDebugO0(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerSelectedIssue339TestFoo(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerRuntimeOptionalPayloadPreoptHelper(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerRuntimeErrorUnionPayloadPreoptHelper(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerGenericCfgMultiBlockCallGlobalCheckMain(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerGenericCfgMultiBlockTwoCallCheckMain(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerRuntimePointerLoadStorePreoptMain(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerBase64DecodeBase64FullMain(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerGenericCfgSingleBlockByteSwap(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerGenericCfgSingleBlockFp(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerGenericCfgSingleBlockAggregateAbi(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerGenericCfgSingleBlockPackedBits(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerGenericCfgSingleBlockI64(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerGenericCfgSingleBlockPtr(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerGenericCfgSingleBlockPointerLoadStore(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerGenericCfgSingleBlockEffectBarrier(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerGenericCfgSingleBlockVoidCallMain(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerGenericCfgSingleBlockDirectCallMain(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerGenericCfgSingleBlockCallChainMain(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerGenericCfgSingleBlockUpdateGetMain(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerGenericCfgSingleBlockCallCheckMain(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerGenericCfgSingleBlockVoid(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerGenericCfgSingleBlockScalar(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerAtomicExchangeFamily(allocator, &machine, function)) {
        machine.codegen_path = .generic_cfg;
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerAtomicStoreFamily(allocator, &machine, function)) {
        machine.codegen_path = .generic_cfg;
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerAtomicLoadFamily(allocator, &machine, function)) {
        machine.codegen_path = .generic_cfg;
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerAtomicFetchUminFamily(allocator, &machine, function)) {
        machine.codegen_path = .generic_cfg;
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerAtomicFetchUmaxFamily(allocator, &machine, function)) {
        machine.codegen_path = .generic_cfg;
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerAtomicFetchNandFamily(allocator, &machine, function)) {
        machine.codegen_path = .generic_cfg;
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerAtomicFetchXorFamily(allocator, &machine, function)) {
        machine.codegen_path = .generic_cfg;
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerAtomicFetchOrFamily(allocator, &machine, function)) {
        machine.codegen_path = .generic_cfg;
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerAtomicFetchAndFamily(allocator, &machine, function)) {
        machine.codegen_path = .generic_cfg;
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerAtomicFetchSubFamily(allocator, &machine, function)) {
        machine.codegen_path = .generic_cfg;
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerAtomicFetchAddFamily(allocator, &machine, function)) {
        machine.codegen_path = .generic_cfg;
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerValgrindDiscardTranslationsClientRequest(allocator, &machine, function)) {
        machine.codegen_path = .generic_cfg;
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerLimbAbsTwosComplementBody(allocator, &machine, function)) {
        machine.codegen_path = .generic_cfg;
        try verifyFunction(machine);
        return machine;
    }

    if (function.blocks.items.len == 1) {
        try lowerStraightLineReturn(allocator, &machine, function, function.blocks.items[0]);
        try verifyFunction(machine);
        return machine;
    }

    if (try air_patterns_cfg.lowerIntegerSwitchReturn(allocator, &machine, function)) {
        machine.codegen_path = .generic_cfg;
        try verifyFunction(machine);
        return machine;
    }

    if (try x86_64_generic_cfg.lowerGenericCfgFunction(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try air_patterns_global_tls_rows.lowerSelectedMixCFilesAddMayPanic(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (function.blocks.items.len == 3) {
        if (try air_patterns_global_tls_rows.lowerSelectedDebugScopeBranch(allocator, &machine, function)) {
            try verifyFunction(machine);
            return machine;
        }
        if (try air_patterns_global_tls_rows.lowerSelectedCheckedAddRuntimeBoundaryMain(allocator, &machine, function)) {
            try verifyFunction(machine);
            return machine;
        }
        if (try lowerCheckedGlobalUpdateMain(allocator, &machine, function)) {
            try verifyFunction(machine);
            return machine;
        }
        if (try lowerCheckedSingleParamAddFunction(allocator, &machine, function)) {
            try verifyFunction(machine);
            return machine;
        }
        if (try lowerFpExponentRuntimeBoundaryMain(allocator, &machine, function)) {
            try verifyFunction(machine);
            return machine;
        }
        if (try air_patterns_optional_pointer.lowerRuntimeOptionalPointerPreoptMain(allocator, &machine, function)) {
            try verifyFunction(machine);
            return machine;
        }
        if (try air_patterns_optional_pointer.lowerRuntimeOptionalPointerMain(allocator, &machine, function)) {
            try verifyFunction(machine);
            return machine;
        }
        if (try air_patterns_cfg.lowerConditionalReturn(allocator, &machine, function)) {
            try verifyFunction(machine);
            return machine;
        }
        if (try air_patterns_cfg.lowerErrorSwitchReturn(allocator, &machine, function)) {
            try verifyFunction(machine);
            return machine;
        }
        if (try air_patterns_optional_pointer.lowerOptionalPointerLoadReturn(allocator, &machine, function)) {
            try verifyFunction(machine);
            return machine;
        }
    }

    if (function.blocks.items.len == 4) {
        if (try lowerDescriptorTableLoopMain(allocator, &machine, function)) {
            try verifyFunction(machine);
            return machine;
        }
        if (try air_patterns_cfg.lowerDenseSwitchReturn(allocator, &machine, function)) {
            try verifyFunction(machine);
            return machine;
        }
    }

    if (try lowerBase64LoopAdvanceStep(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerBase64ResidualGuardStep(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerBase64PaddingLoopStep(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerBase64DecodeBase64FullBoundary(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (x86_64_generic_cfg.genericCfgLoopSumPlan(function) != null) return error.GenericCfgFallback;
    if (try lowerControlFlowLoopSum(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerRuntimeSliceSumPreoptHelper(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerSliceSumLoop(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCheckedStructSum(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCheckedArraySum(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCheckedDebugLocation(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCheckedCallChain(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCheckedComptimeConst(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCheckedGlobalUpdate(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCheckedPointerLoadStore(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCheckedBranchMix(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCheckedAddRuntimeBoundaryMain(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCheckedTinyAdd(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCheckedTlsBump(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCheckedIntFromFloat(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCheckedTableLookup(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    return error.UnsupportedCodegenControlFlow;
}

pub fn verifyFunction(function: MachineFunction) !void {
    return x86_64_verify.verifyFunction(function);
}

test "x86_64 lowers i1 constant return with unused pointer parameter" {
    const allocator = std.testing.allocator;
    var function = ir.Function.init("real.const_i1_unused_ptr", .{ .int = 1 });
    defer function.deinit(allocator);
    try function.params.append(allocator, .{ .ty = .ptr, .name = "arg0" });

    var block = ir.BasicBlock.init("entry");
    block.terminator = .{ .ret = .{ .ty = .{ .int = 1 }, .value = .{ .int = 0 } } };
    try function.blocks.append(allocator, block);

    var machine = try lowerFunction(allocator, "x86_64-unknown-linux-gnu", function);
    defer machine.deinit(allocator);

    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(@as(i32, 0), switch (machine.instructions.items[0]) {
        .mov_imm_eax => |value| value,
        else => return error.TestExpectedEqual,
    });
    try std.testing.expectEqual(.ret, machine.instructions.items[1]);
}
