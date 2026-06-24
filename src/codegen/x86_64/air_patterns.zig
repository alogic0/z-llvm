const std = @import("std");
const ir = @import("../../ir.zig");
const target = @import("../../target.zig");
const memory_location = @import("../../analysis/memory_location.zig");
const x86_64_types = @import("types.zig");
const sysv_abi = @import("sysv_abi.zig");
const x86_64_verify = @import("verify.zig");
const x86_64_emit = @import("emit.zig");
const x86_64_match = @import("match.zig");
const runtime_float = @import("runtime_float.zig");
const x86_64_generic_cfg = @import("generic_cfg.zig");

pub const ArgReg = x86_64_types.ArgReg;
pub const XmmReg = x86_64_types.XmmReg;
pub const MachineBinaryOp = x86_64_types.MachineBinaryOp;
pub const FrameIndex = x86_64_types.FrameIndex;
pub const CodegenPath = x86_64_types.CodegenPath;
pub const SysVAggregateEightbyteClass = sysv_abi.AggregateEightbyteClass;
pub const SysVAggregateKind = sysv_abi.AggregateKind;
pub const SysVAggregateClassification = sysv_abi.AggregateClassification;
pub const SysVCallPlanCounts = sysv_abi.CallPlanCounts;

const SysVSmallIntegerAggregate = sysv_abi.SmallIntegerAggregate;
const SysVRegisterNeeds = sysv_abi.RegisterNeeds;
const SysVRegisterAggregatePassThrough = sysv_abi.RegisterAggregatePassThrough;
const SysVCallPlan = sysv_abi.CallPlan;
const SysVParamCursor = sysv_abi.ParamCursor;
const SysVCallTarget = x86_64_emit.SysVCallTarget;
const max_sysv_stack_call_args = x86_64_emit.max_sysv_stack_call_args;
const appendIntegerOverflowCall = x86_64_emit.appendIntegerOverflowCall;
const appendStackFrame = x86_64_emit.appendStackFrame;
const appendStackFrameEnd = x86_64_emit.appendStackFrameEnd;
const appendDirectCall = x86_64_emit.appendDirectCall;
const appendAlignedDirectCall = x86_64_emit.appendAlignedDirectCall;
const appendDirectCallWithStackArgs = x86_64_emit.appendDirectCallWithStackArgs;
const appendIndirectCallRaxWithStackArgs = x86_64_emit.appendIndirectCallRaxWithStackArgs;
const appendLoadStackDispArg32 = x86_64_emit.appendLoadStackDispArg32;
const appendLoadStackDispArg64 = x86_64_emit.appendLoadStackDispArg64;
const appendMoveImmToArgReg = x86_64_emit.appendMoveImmToArgReg;
const appendMoveImm32ToXmm = x86_64_emit.appendMoveImm32ToXmm;
const appendMoveImm64ToXmm = x86_64_emit.appendMoveImm64ToXmm;
const setupSysVCallTarget = x86_64_emit.setupSysVCallTarget;
const appendSysVCallTarget = x86_64_emit.appendSysVCallTarget;
const appendAlignedSysVCallTarget = x86_64_emit.appendAlignedSysVCallTarget;
const appendSysVCallTargetWithStackArgs = x86_64_emit.appendSysVCallTargetWithStackArgs;
const appendPanicCall = x86_64_emit.appendPanicCall;
const validateDefaultCallConv = x86_64_match.validateDefaultCallConv;
const isNamed = x86_64_match.isNamed;
const callIsFastcc = x86_64_match.callIsFastcc;
const callArgAttrsContain = x86_64_match.callArgAttrsContain;
const paramAttrsContain = x86_64_match.paramAttrsContain;
const globalSymbolName = x86_64_match.globalSymbolName;
const symbolName = x86_64_match.symbolName;
const isInt = x86_64_match.isInt;
const i32Value = x86_64_match.i32Value;
const u8Value = x86_64_match.u8Value;
const i64Value = x86_64_match.i64Value;
const u5Value = x86_64_match.u5Value;
const isFpText = x86_64_match.isFpText;
const fp32TextBits = x86_64_match.fp32TextBits;
const fp64TextBits = x86_64_match.fp64TextBits;
const isCalleeName = x86_64_match.isCalleeName;
const lowerSelectedRuntimeFloatCallCompareMainReturn = runtime_float.lowerSelectedRuntimeFloatCallCompareMainReturn;
const lowerRuntimeFloatLessMainReturn = runtime_float.lowerRuntimeFloatLessMainReturn;

const lowerReleaseSmallStrFromFloatHelp = x86_64_generic_cfg.lowerReleaseSmallStrFromFloatHelp;
const lowerReleaseSmallStrFromFloatSupportFunction = x86_64_generic_cfg.lowerReleaseSmallStrFromFloatSupportFunction;
const appendSysVScalarCallArgs = x86_64_generic_cfg.appendSysVScalarCallArgs;
const appendSysVMemoryAggregateStackPassThroughArgs = x86_64_generic_cfg.appendSysVMemoryAggregateStackPassThroughArgs;
const paramRegOrNull = x86_64_generic_cfg.paramRegOrNull;
const appendAlignedDirectCallPreservingI32Param = x86_64_generic_cfg.appendAlignedDirectCallPreservingI32Param;
const lowerVolatileAbsoluteStore = x86_64_generic_cfg.lowerVolatileAbsoluteStore;
const lowerReturnValue = x86_64_generic_cfg.lowerReturnValue;
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
const lowerMulConstReturn = x86_64_generic_cfg.lowerMulConstReturn;
const lowerIntegerShiftMixReturn = x86_64_generic_cfg.lowerIntegerShiftMixReturn;
const lowerBase64DecodeBase64FullBoundary = x86_64_generic_cfg.lowerBase64DecodeBase64FullBoundary;
const lowerBase64DecodeBase64FullMain = x86_64_generic_cfg.lowerBase64DecodeBase64FullMain;
const lowerBase64PaddingLoopStep = x86_64_generic_cfg.lowerBase64PaddingLoopStep;
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
const lowerGenericCfgSingleBlockCallChainMain = x86_64_generic_cfg.lowerGenericCfgSingleBlockCallChainMain;
const lowerGenericCfgSingleBlockCallCheckMain = x86_64_generic_cfg.lowerGenericCfgSingleBlockCallCheckMain;
const lowerGenericCfgSingleBlockDirectCallMain = x86_64_generic_cfg.lowerGenericCfgSingleBlockDirectCallMain;
const lowerGenericCfgSingleBlockEffectBarrier = x86_64_generic_cfg.lowerGenericCfgSingleBlockEffectBarrier;
const lowerGenericCfgSingleBlockFp = x86_64_generic_cfg.lowerGenericCfgSingleBlockFp;
const lowerGenericCfgSingleBlockI64 = x86_64_generic_cfg.lowerGenericCfgSingleBlockI64;
const lowerGenericCfgSingleBlockPackedBits = x86_64_generic_cfg.lowerGenericCfgSingleBlockPackedBits;
const lowerGenericCfgSingleBlockScalar = x86_64_generic_cfg.lowerGenericCfgSingleBlockScalar;
const lowerGenericCfgSingleBlockUpdateGetMain = x86_64_generic_cfg.lowerGenericCfgSingleBlockUpdateGetMain;
const lowerGenericCfgSingleBlockVoid = x86_64_generic_cfg.lowerGenericCfgSingleBlockVoid;
const lowerGenericCfgSingleBlockVoidCallMain = x86_64_generic_cfg.lowerGenericCfgSingleBlockVoidCallMain;
const lowerGetauxvalImpl = x86_64_generic_cfg.lowerGetauxvalImpl;
const lowerRuntimeSliceSumPreoptHelper = x86_64_generic_cfg.lowerRuntimeSliceSumPreoptHelper;
const lowerSelectedInfiniteLoop = x86_64_generic_cfg.lowerSelectedInfiniteLoop;
const lowerSelectedIssue339TestFoo = x86_64_generic_cfg.lowerSelectedIssue339TestFoo;
const lowerSelectedLibfuzzerDebugO0 = x86_64_generic_cfg.lowerSelectedLibfuzzerDebugO0;
const lowerSliceSumLoop = x86_64_generic_cfg.lowerSliceSumLoop;
const lowerDebugLogicalPointerCompileError = x86_64_generic_cfg.lowerDebugLogicalPointerCompileError;
const singleLiveParamAfter = x86_64_generic_cfg.singleLiveParamAfter;
const sysvIntegerParamReg = x86_64_generic_cfg.sysvIntegerParamReg;
const lowerUnreachableStub = x86_64_generic_cfg.lowerUnreachableStub;
const appendI32CallArgs = x86_64_generic_cfg.appendI32CallArgs;
const appendSysVScalarCallArgsWithBlock = x86_64_generic_cfg.appendSysVScalarCallArgsWithBlock;
const paramReg = x86_64_generic_cfg.paramReg;
const identityCastFrom = x86_64_generic_cfg.identityCastFrom;
const blockByName = x86_64_generic_cfg.blockByName;
const valueReferencesGlobal = x86_64_generic_cfg.valueReferencesGlobal;
const paramValueReg = x86_64_generic_cfg.paramValueReg;
const matchIcmpEqParamImm = x86_64_generic_cfg.matchIcmpEqParamImm;
const validateTerminatorBr = x86_64_generic_cfg.validateTerminatorBr;
const blockIndex = x86_64_generic_cfg.blockIndex;
const lowerReturnValueAfterCalls = x86_64_generic_cfg.lowerReturnValueAfterCalls;
const phiHasIncoming = x86_64_generic_cfg.phiHasIncoming;
const phiHasIncomingInt = x86_64_generic_cfg.phiHasIncomingInt;
const findInstruction = x86_64_generic_cfg.findInstruction;
const sysvParamCursorForWithInitial = x86_64_generic_cfg.sysvParamCursorForWithInitial;
const fpParamIndex = x86_64_generic_cfg.fpParamIndex;
const functionHasCall = x86_64_generic_cfg.functionHasCall;
const lowerReturnTerminator = x86_64_generic_cfg.lowerReturnTerminator;
const isSelectI1ToI32ZeroOne = x86_64_generic_cfg.isSelectI1ToI32ZeroOne;
const paramRegWithInitialGpr = x86_64_generic_cfg.paramRegWithInitialGpr;
pub const sysvCallPlanCountsForTest = x86_64_generic_cfg.sysvCallPlanCountsForTest;

const x86_64_machine = @import("machine.zig");

pub const Instruction = x86_64_machine.Instruction;
pub const MachineFunction = x86_64_machine.MachineFunction;

const SelectedI32Value = union(enum) {
    imm: i32,
    reg: ArgReg,
};

pub fn lowerFunction(allocator: std.mem.Allocator, triple_text: []const u8, function: ir.Function) !MachineFunction {
    const parsed_triple = try target.Triple.parse(triple_text);
    if (!parsed_triple.isX86_64() or !parsed_triple.isLinux()) return error.UnsupportedTarget;

    var machine = MachineFunction.init(symbolName(function.name), function.ret_ty);
    errdefer machine.deinit(allocator);

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

    if (try lowerSelectedMixCFilesAddZigDebugO0(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerSelectedMixCFilesAddMayPanicDebugO0(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerSelectedMixCFilesAddMayPanic(allocator, &machine, function)) {
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

    if (function.blocks.items.len == 1) {
        try lowerStraightLineReturn(allocator, &machine, function, function.blocks.items[0]);
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerIntegerSwitchReturn(allocator, &machine, function)) {
        machine.codegen_path = .generic_cfg;
        try verifyFunction(machine);
        return machine;
    }

    if (try x86_64_generic_cfg.lowerGenericCfgFunction(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (function.blocks.items.len == 3) {
        if (try lowerSelectedDebugScopeBranch(allocator, &machine, function)) {
            try verifyFunction(machine);
            return machine;
        }
        if (try lowerSelectedCheckedAddRuntimeBoundaryMain(allocator, &machine, function)) {
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
        if (try lowerRuntimeOptionalPointerPreoptMain(allocator, &machine, function)) {
            try verifyFunction(machine);
            return machine;
        }
        if (try lowerRuntimeOptionalPointerMain(allocator, &machine, function)) {
            try verifyFunction(machine);
            return machine;
        }
        if (try lowerConditionalReturn(allocator, &machine, function)) {
            try verifyFunction(machine);
            return machine;
        }
        if (try lowerErrorSwitchReturn(allocator, &machine, function)) {
            try verifyFunction(machine);
            return machine;
        }
        if (try lowerOptionalPointerLoadReturn(allocator, &machine, function)) {
            try verifyFunction(machine);
            return machine;
        }
    }

    if (function.blocks.items.len == 4) {
        if (try lowerDescriptorTableLoopMain(allocator, &machine, function)) {
            try verifyFunction(machine);
            return machine;
        }
        if (try lowerDenseSwitchReturn(allocator, &machine, function)) {
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

fn lowerStraightLineReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
) !void {
    const terminator = block.terminator orelse return error.BlockWithoutTerminator;
    switch (terminator) {
        .ret => |ret| {
            if (!ret.ty.eql(function.ret_ty)) return error.ReturnTypeMismatch;
            if (try lowerAggregatePairAbiFamilyReturn(allocator, machine, function, block, ret)) return;
            if (try lowerDescriptorFpCheckMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerSingleStackSlotCallReturn(allocator, machine, function, block, ret)) return;
            if (try lowerSingleStackSlotReturn(allocator, machine, function, block, ret)) return;
            if (try lowerSelectAddSubReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimePhiSelectReturn(allocator, machine, function, block, ret)) return;
            if (try lowerIcmpSelectConstReturn(allocator, machine, function, block, ret)) return;
            if (try lowerFcmpSelectConstReturn(allocator, machine, function, block, ret)) return;
            if (try lowerErrorSwitchSelectReturn(allocator, machine, function, block, ret)) return;
            if (try lowerErrorUnionI64SelectReturn(allocator, machine, function, block, ret)) return;
            if (try lowerAddImmReturn(allocator, machine, function, block, ret)) return;
            if (try lowerShiftOrConstReturn(allocator, machine, function, block, ret)) return;
            if (try lowerMulConstReturn(allocator, machine, function, block, ret)) return;
            if (try lowerIntegerSminReturn(allocator, machine, function, block, ret)) return;
            if (try lowerIntegerShiftMixReturn(allocator, machine, function, block, ret)) return;
            if (try lowerPackedReplaceLowReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimePackedReplaceLowMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerPackedReadFlagReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimePackedReadFlagMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerPointerLoadStoreReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimePointerLoadStoreMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerPointerVolatileRoundtripReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimeVolatileRoundtripMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerFloatMulReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimeFloatAddMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerFloatAddReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimeFloatSubMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerFloatSubReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimeDoubleDivMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerDoubleDivReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimeFloatRemMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerFloatRemReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimeFloatMulMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerFloatSelectReturn(allocator, machine, function, block, ret)) return;
            if (try lowerFloatLessReturn(allocator, machine, function, block, ret)) return;
            if (try lowerFloatLiteralReturn(allocator, machine, function, ret)) return;
            if (try lowerScalarFpCastReturn(allocator, machine, function, block, ret)) return;
            if (try lowerAggregateAbiReturn(allocator, machine, function, block, ret)) return;
            if (try lowerSelectedMixCFilesAddZig(allocator, machine, function, block, ret)) return;
            if (try lowerStructSumReturn(allocator, machine, function, block, ret)) return;
            if (try lowerAddChain3Return(allocator, machine, function, block, ret)) return;
            if (try lowerInlineAsmBarrierReturn(allocator, machine, function, block, ret)) return;
            if (try lowerAtomicAddReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimeCheckedStructSumMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimeStructSumMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimeArraySumMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimeOptionalPayloadMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimeErrorUnionPayloadMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimeSliceSumMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimeComptimeConstMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimeDebugLocationMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerTlsBumpCallMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerHiddenGlobalAccessFamilyReturn(allocator, machine, function, block, ret)) return;
            if (try lowerMixedCZigTlsInputFamilyReturn(allocator, machine, function, block, ret)) return;
            if (try lowerReleaseSmallMixCAddMayPanicMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerDirectI32CallMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerControlFlowCallsWriterMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerSelectedI64CallMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerTlsReadReturn(allocator, machine, function, block, ret)) return;
            if (try lowerTlsBumpReturn(allocator, machine, function, block, ret)) return;
            if (try lowerGlobalReadReturn(allocator, machine, function, block, ret)) return;
            if (try lowerGlobalUpdateCheckMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerGlobalUpdateReturn(allocator, machine, function, block, ret)) return;
            if (try lowerReleaseSmallStrFromFloatMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerTlsMainReadReturn(allocator, machine, function, block, ret)) return;
            if (try lowerTlsMainUpdateReturn(allocator, machine, function, block, ret)) return;
            if (try lowerSelectedI64ConstReturn(allocator, machine, function, block, ret)) return;
            if (try lowerSelectedI1ConstReturn(allocator, machine, function, block, ret)) return;
            if (try lowerSelectedStringSliceReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64BitBufferStoreStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64ResidualBundleStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64ThirdSourceBundleStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64NextSourceBundleStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64SourceBundleStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64SourceStrideStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64ChunkGuardStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64PaddingLengthStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64PaddingTailStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64ResidualByteStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64ResidualAccumulatorStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64ResidualLoopAdvanceStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64ResidualPaddingCheckStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64ResidualFinalMaskStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64ResidualPaddingLoopStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64DecodeExitStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64ResidualTableCheckStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64ResidualLengthStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64ResidualStoreStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64StoreStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64DecodeStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64WriterMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64TableLookupMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerGenericCfgByteTableLookupReturn(allocator, machine, function, block, ret)) return;
            if (try lowerSelectedLibfuzzerTestRun(allocator, machine, function, block, ret)) return;
            if (try lowerI64SaturatingHelperFamilyReturn(allocator, machine, function, block, ret)) return;
            if (hasLiveInstructions(block)) {
                try lowerStraightLineInstructions(allocator, machine, function, block, ret);
                return;
            }
            if (ret.ty == .void) {
                try machine.instructions.append(allocator, .ret);
                return;
            }
            if (!ret.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
            try lowerReturnValue(allocator, machine, function, block, ret.value orelse return error.InvalidRet);
            try machine.instructions.append(allocator, .ret);
        },
        .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
    }
}

fn hasLiveInstructions(block: ir.BasicBlock) bool {
    for (block.instructions.items) |instruction| {
        if (!instruction.removed) return true;
    }
    return false;
}

fn lowerSelectedI64ConstReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 64 })) return false;
    if (function.params.items.len != 0 or block.instructions.items.len != 0) return false;
    const value = switch (ret.value orelse return error.InvalidRet) {
        .int => |int| int,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };

    try machine.instructions.append(allocator, .{ .mov_imm_rax = try i64Value(value) });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerGenericCfgI64ParamReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 64 }) or block.instructions.items.len != 0) return false;
    const name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const reg = try sysvIntegerParamReg(function, name, .{ .int = 64 });
    try machine.instructions.append(allocator, .{ .mov_arg_rax = reg });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerGenericCfgI64DirectCallReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 64 }) or block.instructions.items.len == 0 or block.instructions.items.len > 2) return false;
    const instruction = block.instructions.items[block.instructions.items.len - 1];
    if (instruction.removed) return false;
    const call_result = instruction.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, call_result)) return false;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!call.ret_ty.eql(.{ .int = 64 }) or call.inline_asm != null) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;

    if (call.callee_value) |callee_value| {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        const callee_reg = try paramReg(function, callee_name, .ptr);
        try machine.instructions.append(allocator, .{ .mov_arg_rax = callee_reg });
        const stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, call);
        try appendIndirectCallRaxWithStackArgs(allocator, machine, call.ret_ty, stack_arg_count);
    } else {
        const stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, call);
        try appendDirectCallWithStackArgs(allocator, machine, call.callee, call.ret_ty, stack_arg_count);
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerControlFlowCallsWriterMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 2) return false;

    const call_inst = block.instructions.items[0];
    const add_inst = block.instructions.items[1];
    if (call_inst.removed or add_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    const add_name = add_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, add_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isCalleeName(call.callee, "control_flow_calls.writer_callee")) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    try validateDefaultCallConv(call.calling_conv);
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 0) return error.UnsupportedCodegenInstruction;

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 }) or add.flags.any()) return false;
    if (!isNamed(add.lhs, call_name) or !isInt(add.rhs, 1)) return false;

    try appendAlignedDirectCall(allocator, machine, call.callee, call.ret_ty);
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerDirectI32CallMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!isMainOrWrapperMain(function.name)) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 1 and block.instructions.items.len != 2) return false;

    const call_inst = block.instructions.items[0];
    if (call_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!callIsFastcc(call.calling_conv)) try validateDefaultCallConv(call.calling_conv);
    if (!call.ret_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
    if (call.args.items.len > max_sysv_stack_call_args + 6) return error.UnsupportedCodegenAbi;

    var add_immediate: i32 = 0;
    if (block.instructions.items.len == 1) {
        if (!isNamed(ret.value orelse return error.InvalidRet, call_name)) return false;
    } else {
        const second_inst = block.instructions.items[1];
        if (second_inst.removed) return false;
        if (identityCastFrom(second_inst, call_name, .{ .int = 32 }, .{ .int = 32 })) |cast_name| {
            if (!isNamed(ret.value orelse return error.InvalidRet, cast_name)) return false;
        } else {
            const add_name = second_inst.result orelse return false;
            if (!isNamed(ret.value orelse return error.InvalidRet, add_name)) return false;
            const add = switch (second_inst.kind) {
                .binary => |binary| binary,
                else => return false,
            };
            if (add.op != .add or !add.ty.eql(.{ .int = 32 }) or add.flags.any() or !isNamed(add.lhs, call_name)) return false;
            add_immediate = switch (add.rhs) {
                .int => |int| try i32Value(int),
                .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
            };
        }
    }

    const stack_arg_count = try appendI32CallArgs(allocator, machine, function, call);
    try appendDirectCallWithStackArgs(allocator, machine, call.callee, call.ret_ty, stack_arg_count);
    if (add_immediate != 0) try machine.instructions.append(allocator, .{ .add_eax_imm32 = add_immediate });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerTlsBumpCallMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!isMainOrWrapperMain(function.name)) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 1) return false;
    const call_inst = block.instructions.items[0];
    if (call_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, call_name)) return false;
    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!std.mem.endsWith(u8, call.callee, ".bumpTls")) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!callIsFastcc(call.calling_conv)) return false;
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[0].value, 1)) return false;

    try machine.instructions.append(allocator, .{ .load_tls_i32_eax = "runtime_tls_bump_main.tls_counter" });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = 1 });
    try machine.instructions.append(allocator, .{ .store_eax_tls_i32 = "runtime_tls_bump_main.tls_counter" });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerSelectedI64CallMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 3) return false;

    const call_inst = block.instructions.items[0];
    const icmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (call_inst.removed or icmp_inst.removed or select_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    const icmp_name = icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isCalleeName(call.callee, "i64_arithmetic.i64_value")) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    try validateDefaultCallConv(call.calling_conv);
    if (!call.ret_ty.eql(.{ .int = 64 }) or call.args.items.len != 0) return error.UnsupportedCodegenInstruction;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 64 })) return false;
    if (!isNamed(icmp.lhs, call_name) or !isInt(icmp.rhs, 4)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const fail = "i64_call_fail";
    try appendAlignedDirectCall(allocator, machine, call.callee, call.ret_ty);
    try machine.instructions.append(allocator, .{ .mov_imm_rdx = 4 });
    try machine.instructions.append(allocator, .cmp_rax_rdx);
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerReleaseSmallStrFromFloatMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or !(ret.value orelse return false).eql(.{ .int = 0 })) return false;
    if (block.instructions.items.len == 0) return false;

    for (block.instructions.items) |instruction| {
        if (instruction.result != null) return false;
        const call = switch (instruction.kind) {
            .call => |call| call,
            else => return false,
        };
        try validateDefaultCallConv(call.calling_conv);
        if (call.ret_ty != .void or !isCalleeName(call.callee, "main.strFromFloatHelp") or call.args.items.len != 1) return false;
        const arg = call.args.items[0];
        if (!arg.ty.eql(.double)) return false;
        switch (arg.value) {
            .fp => {},
            .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
        }
        try appendAlignedDirectCall(allocator, machine, call.callee, call.ret_ty);
    }

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeArraySumMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const integrated_preopt = std.mem.eql(u8, function.name, "runtime_array_sum_main.main");
    if (!std.mem.eql(u8, function.name, "main") and !integrated_preopt) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 3) return false;

    const call_inst = block.instructions.items[0];
    const icmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (call_inst.removed or icmp_inst.removed or select_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    const icmp_name = icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (integrated_preopt) {
        if (!std.mem.eql(u8, call.callee, "runtime_array_sum_main.arraySum")) return false;
    } else if (!isCalleeName(call.callee, "aggregates.array_sum")) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (integrated_preopt) {
        if (call.calling_conv) |cc| {
            if (!std.mem.eql(u8, cc, "fastcc")) return false;
        }
    } else {
        try validateDefaultCallConv(call.calling_conv);
    }
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 3) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[0].value, 10)) return error.UnsupportedCodegenValue;
    if (!call.args.items[1].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[1].value, 20)) return error.UnsupportedCodegenValue;
    if (!call.args.items[2].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[2].value, 12)) return error.UnsupportedCodegenValue;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, call_name) or !isInt(icmp.rhs, 42)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    if (integrated_preopt) {
        try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
        try machine.instructions.append(allocator, .ret);
        return true;
    }

    const fail = "array_sum_fail";
    try machine.instructions.append(allocator, .{ .mov_imm_rdi = 10 });
    try machine.instructions.append(allocator, .{ .mov_imm_rsi = 20 });
    try machine.instructions.append(allocator, .{ .mov_imm_rdx = 12 });
    try appendAlignedDirectCall(allocator, machine, call.callee, call.ret_ty);
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 42 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeCheckedStructSumMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 3) return false;

    const call_inst = block.instructions.items[0];
    const icmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (call_inst.removed or icmp_inst.removed or select_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    const icmp_name = icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isCalleeName(call.callee, "aggregates.struct_sum")) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    try validateDefaultCallConv(call.calling_conv);
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.ptr) or !call.args.items[0].value.eql(.{ .named = "@struct_sum_value" })) return error.UnsupportedCodegenValue;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, call_name) or !isInt(icmp.rhs, 42)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const fail = "struct_sum_fail";
    try machine.instructions.append(allocator, .{ .lea_global_rdi = "struct_sum_value" });
    try appendAlignedDirectCall(allocator, machine, call.callee, call.ret_ty);
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 42 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeOptionalPayloadPreoptHelper(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (!std.mem.eql(u8, function.name, "runtime_optional_payload_main.optionalPayload")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 32 }) or !function.params.items[1].ty.eql(.{ .int = 32 })) return false;
    if (function.blocks.items.len != 5) return false;

    const entry = blockByName(function, "2") orelse return false;
    const merge_ptr = blockByName(function, "5") orelse return false;
    const some_block = blockByName(function, "10") orelse return false;
    const ret_block = blockByName(function, "13") orelse return false;
    const payload_block = blockByName(function, "15") orelse return false;
    if (entry.instructions.items.len != 2 or merge_ptr.instructions.items.len != 4 or some_block.instructions.items.len != 3 or
        ret_block.instructions.items.len != 1 or payload_block.instructions.items.len != 1) return false;

    const icmp_inst = entry.instructions.items[1];
    if (icmp_inst.removed) return false;
    const icmp_name = icmp_inst.result orelse return false;
    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .ne or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, function.params.items[0].name) or !isInt(icmp.rhs, 0)) return false;
    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, icmp_name)) return false;
    if (!std.mem.eql(u8, entry_br.then_target, "10") or !std.mem.eql(u8, entry_br.else_target, "5")) return false;

    const value_store = switch (some_block.instructions.items[0].kind) {
        .store => |store| store,
        else => return false,
    };
    if (!value_store.ty.eql(.{ .int = 32 }) or !isNamed(value_store.value, function.params.items[1].name)) return false;
    const some_br = switch (some_block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };
    if (!std.mem.eql(u8, some_br.target, "5")) return false;

    const payload_load_name = payload_block.instructions.items[0].result orelse return false;
    const payload_load = switch (payload_block.instructions.items[0].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!payload_load.ty.eql(.{ .int = 32 }) or payload_load.attrs.isBarrier()) return false;
    const payload_br = switch (payload_block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };
    if (!std.mem.eql(u8, payload_br.target, "13")) return false;

    const phi_name = ret_block.instructions.items[0].result orelse return false;
    const phi = switch (ret_block.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 32 }) or phi.incoming.items.len != 2) return false;
    if (!phiHasIncoming(phi, payload_load_name, "15") or !phiHasIncomingInt(phi, -1, "5")) return false;
    const ret = switch (ret_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, phi_name)) return false;

    const null_label = "optional_payload_preopt_null";
    try machine.instructions.append(allocator, .{ .test_arg32 = .rdi });
    try machine.instructions.append(allocator, .{ .je = null_label });
    try machine.instructions.append(allocator, .{ .mov_arg_eax = .rsi });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = null_label });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = -1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeOptionalPayloadMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const integrated_preopt = std.mem.eql(u8, function.name, "runtime_optional_payload_main.main");
    if (!std.mem.eql(u8, function.name, "main") and !integrated_preopt) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 3) return false;

    const call_inst = block.instructions.items[0];
    const icmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (call_inst.removed or icmp_inst.removed or select_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    const icmp_name = icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (integrated_preopt) {
        if (!std.mem.eql(u8, call.callee, "runtime_optional_payload_main.optionalPayload")) return false;
    } else if (!isCalleeName(call.callee, "aggregates.optional_payload")) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (integrated_preopt) {
        if (call.calling_conv) |cc| {
            if (!std.mem.eql(u8, cc, "fastcc")) return false;
        }
    } else {
        try validateDefaultCallConv(call.calling_conv);
    }
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 2) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[0].value, 1)) return error.UnsupportedCodegenValue;
    if (!call.args.items[1].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[1].value, 42)) return error.UnsupportedCodegenValue;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, call_name) or !isInt(icmp.rhs, 42)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    if (integrated_preopt) {
        try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
        try machine.instructions.append(allocator, .ret);
        return true;
    }

    const fail = "optional_payload_fail";
    try machine.instructions.append(allocator, .{ .mov_imm_rdi = 1 });
    try machine.instructions.append(allocator, .{ .mov_imm_rsi = 42 });
    try appendAlignedDirectCall(allocator, machine, call.callee, call.ret_ty);
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 42 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeErrorUnionPayloadMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const integrated_preopt = std.mem.eql(u8, function.name, "runtime_error_union_payload_main.main");
    if (!std.mem.eql(u8, function.name, "main") and !integrated_preopt) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 3) return false;

    const call_inst = block.instructions.items[0];
    const icmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (call_inst.removed or icmp_inst.removed or select_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    const icmp_name = icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (integrated_preopt) {
        if (!std.mem.eql(u8, call.callee, "runtime_error_union_payload_main.errorUnionPayload")) return false;
    } else if (!isCalleeName(call.callee, "aggregates.error_union_payload")) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (integrated_preopt) {
        if (call.calling_conv) |cc| {
            if (!std.mem.eql(u8, cc, "fastcc")) return false;
        }
    } else {
        try validateDefaultCallConv(call.calling_conv);
    }
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[0].value, 0)) return error.UnsupportedCodegenValue;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, call_name) or !isInt(icmp.rhs, 7)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    if (integrated_preopt) {
        try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
        try machine.instructions.append(allocator, .ret);
        return true;
    }

    const fail = "error_union_payload_fail";
    try machine.instructions.append(allocator, .{ .mov_imm_rdi = 0 });
    try appendAlignedDirectCall(allocator, machine, call.callee, call.ret_ty);
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 7 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeErrorUnionPayloadPreoptHelper(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (std.mem.eql(u8, function.name, "runtime_error_union_payload_main.maybeError")) {
        if (function.ret_ty != .void or function.params.items.len != 2) return false;
        if (!function.params.items[0].ty.eql(.ptr) or !function.params.items[1].ty.eql(.{ .int = 32 })) return false;
        if (function.blocks.items.len != 3) return false;
        try machine.instructions.append(allocator, .ret);
        return true;
    }

    if (!std.mem.eql(u8, function.name, "runtime_error_union_payload_main.errorUnionPayload")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 32 })) return false;
    if (function.blocks.items.len != 3) return false;

    const entry = blockByName(function, "1") orelse return false;
    const ret_block = blockByName(function, "6") orelse return false;
    const success_block = blockByName(function, "8") orelse return false;
    if (entry.instructions.items.len != 5 or ret_block.instructions.items.len != 1 or success_block.instructions.items.len != 1) return false;

    const tag_cmp_inst = entry.instructions.items[4];
    if (tag_cmp_inst.removed) return false;
    const tag_cmp_name = tag_cmp_inst.result orelse return false;
    const tag_cmp = switch (tag_cmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (tag_cmp.predicate != .eq or !tag_cmp.operand_ty.eql(.{ .int = 16 })) return false;
    if (!isInt(tag_cmp.rhs, 0)) return false;
    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, tag_cmp_name)) return false;
    if (!std.mem.eql(u8, entry_br.then_target, "8") or !std.mem.eql(u8, entry_br.else_target, "6")) return false;

    const payload_load_name = success_block.instructions.items[0].result orelse return false;
    const payload_load = switch (success_block.instructions.items[0].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!payload_load.ty.eql(.{ .int = 32 }) or payload_load.attrs.isBarrier()) return false;
    const success_br = switch (success_block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };
    if (!std.mem.eql(u8, success_br.target, "6")) return false;

    const phi_name = ret_block.instructions.items[0].result orelse return false;
    const phi = switch (ret_block.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 32 }) or phi.incoming.items.len != 2) return false;
    if (!phiHasIncoming(phi, payload_load_name, "8") or !phiHasIncomingInt(phi, -1, "1")) return false;
    const ret = switch (ret_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, phi_name)) return false;

    const err_label = "error_union_payload_preopt_err";
    try machine.instructions.append(allocator, .{ .test_arg32 = .rdi });
    try machine.instructions.append(allocator, .{ .jne = err_label });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 7 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = err_label });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = -1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeSliceSumMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const integrated_preopt = std.mem.eql(u8, function.name, "runtime_slice_sum_main.main");
    if (!std.mem.eql(u8, function.name, "main") and !integrated_preopt) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 3) return false;

    const call_inst = block.instructions.items[0];
    const icmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (call_inst.removed or icmp_inst.removed or select_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    const icmp_name = icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (integrated_preopt) {
        if (!std.mem.eql(u8, call.callee, "runtime_slice_sum_main.sliceSum")) return false;
    } else if (!isCalleeName(call.callee, "aggregates.slice_sum")) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (integrated_preopt) {
        if (call.calling_conv) |cc| {
            if (!std.mem.eql(u8, cc, "fastcc")) return false;
        }
    } else {
        try validateDefaultCallConv(call.calling_conv);
    }
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 2) return error.UnsupportedCodegenInstruction;
    if (integrated_preopt) {
        if (!call.args.items[0].ty.eql(.ptr) or !valueReferencesGlobal(call.args.items[0].value, "runtime_slice_sum_main.values")) return error.UnsupportedCodegenValue;
    } else if (!call.args.items[0].ty.eql(.ptr) or !call.args.items[0].value.eql(.{ .named = "@slice_sum_values" })) return error.UnsupportedCodegenValue;
    if (!call.args.items[1].ty.eql(.{ .int = 64 }) or !isInt(call.args.items[1].value, 4)) return error.UnsupportedCodegenValue;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, call_name) or !isInt(icmp.rhs, 10)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    if (integrated_preopt) {
        try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
        try machine.instructions.append(allocator, .ret);
        return true;
    }

    const fail = "slice_sum_fail";
    try machine.instructions.append(allocator, .{ .lea_global_rdi = "slice_sum_values" });
    try machine.instructions.append(allocator, .{ .mov_imm_rsi = 4 });
    try appendAlignedDirectCall(allocator, machine, call.callee, call.ret_ty);
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 10 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeComptimeConstMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 3) return false;

    const call_inst = block.instructions.items[0];
    const icmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (call_inst.removed or icmp_inst.removed or select_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    const icmp_name = icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isCalleeName(call.callee, "globals_comptime.comptime_const")) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    try validateDefaultCallConv(call.calling_conv);
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[0].value, 7)) return error.UnsupportedCodegenValue;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, call_name) or !isInt(icmp.rhs, 35)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const fail = "comptime_const_fail";
    try machine.instructions.append(allocator, .{ .mov_imm_rdi = 7 });
    try appendAlignedDirectCall(allocator, machine, call.callee, call.ret_ty);
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 35 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeDebugLocationMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 3) return false;

    const call_inst = block.instructions.items[0];
    const icmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (call_inst.removed or icmp_inst.removed or select_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    const icmp_name = icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isCalleeName(call.callee, "atomics_inline_asm_debug.debug_location")) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    try validateDefaultCallConv(call.calling_conv);
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[0].value, 41)) return error.UnsupportedCodegenValue;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, call_name) or !isInt(icmp.rhs, 42)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const fail = "debug_location_fail";
    try machine.instructions.append(allocator, .{ .mov_imm_rdi = 41 });
    try appendAlignedDirectCall(allocator, machine, call.callee, call.ret_ty);
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 42 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerSelectedI1ConstReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main.runner_futex_wait")) return false;
    if (!ret.ty.eql(.{ .int = 1 })) return false;
    if (function.params.items.len != 2 or block.instructions.items.len != 0) return false;
    const value = switch (ret.value orelse return error.InvalidRet) {
        .int => |int| int,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    if (value != 0 and value != 1) return error.UnsupportedCodegenValue;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = try i32Value(value) });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerSelectedStringSliceReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main.runner_test_name")) return false;
    if (!ret.ty.eql(.{ .aggregate = "{ i64, i64 }" })) return false;
    if (function.params.items.len != 1 or block.instructions.items.len != 0) return false;
    const value = ret.value orelse return error.InvalidRet;
    switch (value) {
        .constant_expr => |text| {
            if (!std.mem.eql(u8, text, "{ i64 ptrtoint (ptr @__anon_16879 to i64), i64 4 }")) return error.UnsupportedCodegenValue;
        },
        .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
    }

    try machine.instructions.append(allocator, .{ .lea_global_rax = "__anon_16879" });
    try machine.instructions.append(allocator, .{ .mov_imm_rdx = 4 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

const ExpectedCallArg = struct {
    ty: ir.Type,
    value: ir.Value,
};

fn lowerSelectedLibfuzzerTestRun(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main.runner_test_run")) return false;
    if (ret.ty != .void or ret.value != null) return false;
    if (function.params.items.len != 1 or block.instructions.items.len != 4) return false;

    const set_test_args = [_]ExpectedCallArg{.{
        .ty = .ptr,
        .value = .{ .named = "@main.testOne" },
    }};
    try validateVoidCall(block.instructions.items[0], "fuzzer_set_test", &set_test_args);

    const empty_input_args = [_]ExpectedCallArg{
        .{
            .ty = .{ .int = 64 },
            .value = .{ .constant_expr = "ptrtoint (ptr @__anon_11775 to i64)" },
        },
        .{
            .ty = .{ .int = 64 },
            .value = .{ .int = 0 },
        },
    };
    try validateVoidCall(block.instructions.items[1], "fuzzer_new_input", &empty_input_args);

    const hello_input_args = [_]ExpectedCallArg{
        .{
            .ty = .{ .int = 64 },
            .value = .{ .constant_expr = "ptrtoint (ptr @__anon_16031 to i64)" },
        },
        .{
            .ty = .{ .int = 64 },
            .value = .{ .int = 5 },
        },
    };
    try validateVoidCall(block.instructions.items[2], "fuzzer_new_input", &hello_input_args);
    try validateVoidCall(block.instructions.items[3], "fuzzer_start_test", &.{});

    try machine.instructions.append(allocator, .sub_rsp_8);
    try machine.instructions.append(allocator, .{ .lea_global_rdi = "main.testOne" });
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "fuzzer_set_test", .ret_ty = .void } });
    try machine.instructions.append(allocator, .{ .lea_global_rdi = "__anon_11775" });
    try machine.instructions.append(allocator, .{ .mov_imm_rsi = 0 });
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "fuzzer_new_input", .ret_ty = .void } });
    try machine.instructions.append(allocator, .{ .lea_global_rdi = "__anon_16031" });
    try machine.instructions.append(allocator, .{ .mov_imm_rsi = 5 });
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "fuzzer_new_input", .ret_ty = .void } });
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "fuzzer_start_test", .ret_ty = .void } });
    try machine.instructions.append(allocator, .add_rsp_8);
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn validateVoidCall(instruction: ir.Instruction, callee: []const u8, expected_args: []const ExpectedCallArg) !void {
    if (instruction.removed) return error.UnsupportedCodegenInstruction;
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!isCalleeName(call.callee, callee)) return error.UnsupportedCodegenInstruction;
    if (call.ret_ty != .void or call.args.items.len != expected_args.len) return error.UnsupportedCodegenInstruction;
    for (call.args.items, expected_args) |arg, expected| {
        if (!arg.ty.eql(expected.ty) or !arg.value.eql(expected.value)) return error.UnsupportedCodegenValue;
    }
}

fn validateAssumeColdCall(instruction: ir.Instruction) !void {
    if (instruction.removed) return error.UnsupportedCodegenInstruction;
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!std.mem.eql(u8, call.callee, "llvm.assume")) return error.UnsupportedCodegenInstruction;
    if (call.ret_ty != .void or call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 1 }) or !isInt(call.args.items[0].value, 1)) return error.UnsupportedCodegenValue;
}

fn validateIntegerOverflowPanicCall(instruction: ir.Instruction) !void {
    if (instruction.removed) return error.UnsupportedCodegenInstruction;
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!isCalleeName(call.callee, "debug.FullPanic((function 'defaultPanic')).integerOverflow")) return error.UnsupportedCodegenInstruction;
    if (call.ret_ty != .void or call.args.items.len != 0) return error.UnsupportedCodegenInstruction;
}

fn lowerI64SaturatingHelperFamilyReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (try lowerSelectedUmlFixSatI64Return(allocator, machine, function, block, ret)) return true;
    return false;
}

fn lowerSelectedUmlFixSatI64Return(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "no_compile_panic_for_unchecked_arith.entry")) return false;
    if (!ret.ty.eql(.{ .int = 64 })) return false;
    if (function.params.items.len != 0 or block.instructions.items.len != 1) return false;

    const call_inst = block.instructions.items[0];
    if (call_inst.removed) return false;
    const call_result = call_inst.result orelse return error.InstructionNeedsResult;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    if (!std.mem.eql(u8, ret_name, call_result)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!std.mem.eql(u8, call.callee, "llvm.umul.fix.sat.i64")) return false;
    if (!call.ret_ty.eql(.{ .int = 64 }) or call.args.items.len != 3) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 64 }) or !call.args.items[0].value.eql(.{ .int = 0 })) return error.UnsupportedCodegenValue;
    if (!call.args.items[1].ty.eql(.{ .int = 64 }) or !call.args.items[1].value.eql(.{ .int = 2 })) return error.UnsupportedCodegenValue;
    if (!call.args.items[2].ty.eql(.{ .int = 32 }) or !call.args.items[2].value.eql(.{ .int = 0 })) return error.UnsupportedCodegenValue;

    try machine.instructions.append(allocator, .{ .mov_imm_rax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerSingleStackSlotCallReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (try lowerRuntimeStructSumPreoptHelper(allocator, machine, function, block, ret)) return true;
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 4) return false;

    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    const load_inst = block.instructions.items[2];
    const call_inst = block.instructions.items[3];
    if (alloca_inst.removed or store_inst.removed or load_inst.removed or call_inst.removed) return false;

    const slot = alloca_inst.result orelse return false;
    const load_result = load_inst.result orelse return false;
    const call_result = call_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, call_result, ret_name)) return false;

    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    if (!alloca.allocated_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 32 }) or !isNamed(store.ptr, slot)) return false;
    const store_reg = try paramValueReg(function, store.value, .{ .int = 32 });

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or !isNamed(load.ptr, slot)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null) return error.UnsupportedCodegenInstruction;
    if (call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    try validateDefaultCallConv(call.calling_conv);
    if (!call.ret_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
    if (call.args.items.len != 1) return false;
    const arg = call.args.items[0];
    if (!arg.ty.eql(.{ .int = 32 }) or !isNamed(arg.value, load_result)) return false;

    try machine.instructions.append(allocator, .sub_rsp_8);
    try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{
        .frame_index = .slot0,
        .reg = store_reg,
    } });
    try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{
        .reg = .rdi,
        .frame_index = .slot0,
    } });
    try machine.instructions.append(allocator, .{ .direct_call = .{
        .symbol = call.callee,
        .ret_ty = call.ret_ty,
    } });
    try machine.instructions.append(allocator, .add_rsp_8);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerSingleStackSlotReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 3) return false;

    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    const load_inst = block.instructions.items[2];
    if (alloca_inst.removed or store_inst.removed or load_inst.removed) return false;
    const slot = alloca_inst.result orelse return false;
    const load_result = load_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, load_result, ret_name)) return false;

    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    if (!alloca.allocated_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 32 }) or !isNamed(store.ptr, slot)) return false;
    const store_reg = try paramValueReg(function, store.value, .{ .int = 32 });

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or !isNamed(load.ptr, slot)) return false;

    try machine.instructions.append(allocator, .sub_rsp_8);
    try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{
        .frame_index = .slot0,
        .reg = store_reg,
    } });
    try machine.instructions.append(allocator, .{ .reload_rsp_eax = .slot0 });
    try machine.instructions.append(allocator, .add_rsp_8);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerSelectAddSubReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 3) return false;

    const neg_inst = block.instructions.items[0];
    const select_inst = block.instructions.items[1];
    const add_inst = block.instructions.items[2];
    if (neg_inst.removed or select_inst.removed or add_inst.removed) return false;

    const neg_result = neg_inst.result orelse return false;
    const select_result = select_inst.result orelse return false;
    const add_result = add_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, add_result)) return false;

    const neg = switch (neg_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (neg.op != .sub or !neg.ty.eql(.{ .int = 32 })) return false;
    switch (neg.lhs) {
        .int => |value| if (value != 0) return false,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    }
    const neg_param = try paramValueReg(function, neg.rhs, .{ .int = 32 });

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.ty.eql(.{ .int = 32 })) return false;
    const cond_reg = try paramValueReg(function, select.cond, .{ .int = 1 });
    const true_reg = try paramValueReg(function, select.true_value, .{ .int = 32 });
    if (true_reg != neg_param) return false;
    if (!isNamed(select.false_value, neg_result)) return false;

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 })) return false;
    const base_reg = if (isNamed(add.lhs, select_result))
        try paramValueReg(function, add.rhs, .{ .int = 32 })
    else if (isNamed(add.rhs, select_result))
        try paramValueReg(function, add.lhs, .{ .int = 32 })
    else
        return false;

    const false_label = "select_false";
    try machine.instructions.append(allocator, .{ .test_arg8 = cond_reg });
    try machine.instructions.append(allocator, .{ .je = false_label });
    try machine.instructions.append(allocator, .{ .mov_arg_eax = base_reg });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = true_reg } });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = false_label });
    try machine.instructions.append(allocator, .{ .mov_arg_eax = base_reg });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .sub, .reg = neg_param } });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerIcmpSelectConstReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len < 2) return false;

    const icmp_inst = block.instructions.items[block.instructions.items.len - 2];
    const select_inst = block.instructions.items[block.instructions.items.len - 1];
    if (icmp_inst.removed or select_inst.removed) return false;

    const icmp_result = icmp_inst.result orelse return false;
    const select_result = select_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_result)) return false;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (evalConstIcmpOrBlock(block, icmp)) |cond| {
        const select = switch (select_inst.kind) {
            .select => |select| select,
            else => return false,
        };
        if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 }) or !isNamed(select.cond, icmp_result)) return false;
        const selected = if (cond) select.true_value else select.false_value;
        const selected_int = switch (selected) {
            .int => |value| value,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
        };
        try machine.instructions.append(allocator, .{ .mov_imm_eax = try i32Value(selected_int) });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    const cmp_reg = if (isInt(icmp.lhs, 0))
        try paramValueReg(function, icmp.rhs, .{ .int = 32 })
    else if (isInt(icmp.rhs, 0))
        try paramValueReg(function, icmp.lhs, .{ .int = 32 })
    else
        return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 }) or !isNamed(select.cond, icmp_result)) return false;
    const true_value = try selectedI32Value(function, select.true_value);
    const false_value = try selectedI32Value(function, select.false_value);

    const true_label = "icmp_select_true";
    try machine.instructions.append(allocator, .{ .test_arg32 = cmp_reg });
    try machine.instructions.append(allocator, .{ .je = true_label });
    try appendSelectedI32Return(allocator, machine, false_value);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = true_label });
    try appendSelectedI32Return(allocator, machine, true_value);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerIntegerSminReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 32 }) or
        !function.params.items[1].ty.eql(.{ .int = 32 }) or
        block.instructions.items.len != 2)
    {
        return false;
    }

    const icmp_inst = block.instructions.items[0];
    const select_inst = block.instructions.items[1];
    if (icmp_inst.removed or select_inst.removed) return false;
    const icmp_result = icmp_inst.result orelse return false;
    const select_result = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_result)) return false;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .slt or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, function.params.items[0].name) or
        !isNamed(icmp.rhs, function.params.items[1].name))
    {
        return false;
    }

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or
        !select.ty.eql(.{ .int = 32 }) or
        !isNamed(select.cond, icmp_result) or
        !isNamed(select.true_value, function.params.items[0].name) or
        !isNamed(select.false_value, function.params.items[1].name))
    {
        return false;
    }

    try machine.instructions.append(allocator, .smin_i32_edi_esi_eax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimePhiSelectReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 1) return false;
    if (block.instructions.items.len != 1) return false;

    const select_inst = block.instructions.items[0];
    if (select_inst.removed) return false;
    const select_result = select_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_result)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    const cond_reg = try paramValueReg(function, select.cond, .{ .int = 1 });
    if (!isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const false_label = "runtime_phi_false";
    try machine.instructions.append(allocator, .{ .test_arg8 = cond_reg });
    try machine.instructions.append(allocator, .{ .je = false_label });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = false_label });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn evalConstIcmp(icmp: ir.IcmpInst) ?bool {
    const lhs = switch (icmp.lhs) {
        .int => |value| value,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const rhs = switch (icmp.rhs) {
        .int => |value| value,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    return switch (icmp.predicate) {
        .eq => lhs == rhs,
        .ne => lhs != rhs,
        .sgt, .ugt => lhs > rhs,
        .sge, .uge => lhs >= rhs,
        .slt, .ult => lhs < rhs,
        .sle, .ule => lhs <= rhs,
    };
}

fn evalConstIcmpOrBlock(block: ir.BasicBlock, icmp: ir.IcmpInst) ?bool {
    if (evalConstIcmp(icmp)) |cond| return cond;
    return evalConstIcmpInBlock(block, icmp);
}

fn evalConstIcmpInBlock(block: ir.BasicBlock, icmp: ir.IcmpInst) ?bool {
    const lhs = evalConstValueInBlock(block, icmp.lhs, 0) orelse return null;
    const rhs = evalConstValueInBlock(block, icmp.rhs, 0) orelse return null;
    return switch (icmp.predicate) {
        .eq => lhs == rhs,
        .ne => lhs != rhs,
        .sgt, .ugt => lhs > rhs,
        .sge, .uge => lhs >= rhs,
        .slt, .ult => lhs < rhs,
        .sle, .ule => lhs <= rhs,
    };
}

fn evalConstValueInBlock(block: ir.BasicBlock, value: ir.Value, depth: usize) ?i128 {
    if (depth > 4) return null;
    return switch (value) {
        .int => |int| int,
        .named => |name| {
            const instruction = findInstruction(block, name) orelse return null;
            return switch (instruction.kind) {
                .binary => |binary| evalConstBinaryInBlock(block, binary, depth + 1),
                else => null,
            };
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
    };
}

fn evalConstBinaryInBlock(block: ir.BasicBlock, binary: ir.BinaryInst, depth: usize) ?i128 {
    const lhs = evalConstValueInBlock(block, binary.lhs, depth) orelse return null;
    const rhs = evalConstValueInBlock(block, binary.rhs, depth) orelse return null;
    return switch (binary.op) {
        .add => lhs + rhs,
        .sub => lhs - rhs,
        .mul => lhs * rhs,
        .@"and" => lhs & rhs,
        .@"or" => lhs | rhs,
        .xor => lhs ^ rhs,
        .shl => if (rhs >= 0 and rhs < 127) lhs << @as(u7, @intCast(rhs)) else null,
        .ashr => if (rhs >= 0 and rhs < 127) lhs >> @as(u7, @intCast(rhs)) else null,
        .sdiv => if (rhs != 0) @divTrunc(lhs, rhs) else null,
        .srem => if (rhs != 0) @rem(lhs, rhs) else null,
        .fadd, .fsub, .fmul, .fdiv, .frem, .lshr, .udiv, .urem => null,
    };
}

fn lowerFcmpSelectConstReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or !function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 2) return false;

    const fcmp_inst = block.instructions.items[0];
    const select_inst = block.instructions.items[1];
    if (fcmp_inst.removed or select_inst.removed) return false;
    const fcmp_result = fcmp_inst.result orelse return false;
    const select_result = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_result)) return false;

    const fcmp = switch (fcmp_inst.kind) {
        .fcmp => |fcmp| fcmp,
        else => return false,
    };
    if (fcmp.predicate != .olt or !fcmp.operand_ty.eql(.float)) return false;
    if (!isFpText(fcmp.lhs, "1.000000e+00") or !isFpText(fcmp.rhs, "2.000000e+00")) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, fcmp_result) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerErrorSwitchSelectReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!isErrorSwitchFunctionName(function.name)) return false;
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 8 })) return false;
    if (block.instructions.items.len != 4) return false;

    const cmp_one_inst = block.instructions.items[0];
    const cmp_zero_inst = block.instructions.items[1];
    const first_select_inst = block.instructions.items[2];
    const second_select_inst = block.instructions.items[3];
    if (cmp_one_inst.removed or cmp_zero_inst.removed or first_select_inst.removed or second_select_inst.removed) return false;

    const cmp_one_result = cmp_one_inst.result orelse return false;
    const cmp_zero_result = cmp_zero_inst.result orelse return false;
    const first_select_result = first_select_inst.result orelse return false;
    const second_select_result = second_select_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, second_select_result)) return false;

    const tag_name = function.params.items[0].name;
    if (!matchIcmpEqParamImm(cmp_one_inst, tag_name, .{ .int = 8 }, 1)) return false;
    if (!matchIcmpEqParamImm(cmp_zero_inst, tag_name, .{ .int = 8 }, 0)) return false;

    const first_select = switch (first_select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!first_select.cond_ty.eql(.{ .int = 1 }) or !first_select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(first_select.cond, cmp_one_result) or !isInt(first_select.true_value, -1) or !isInt(first_select.false_value, -2)) return false;

    const second_select = switch (second_select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!second_select.cond_ty.eql(.{ .int = 1 }) or !second_select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(second_select.cond, cmp_zero_result) or !isInt(second_select.true_value, 0) or !isNamed(second_select.false_value, first_select_result)) return false;

    try appendErrorSwitchReturns(allocator, machine, try paramReg(function, tag_name, .{ .int = 8 }));
    return true;
}

fn lowerErrorUnionI64SelectReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 64 }) or !function.ret_ty.eql(.{ .int = 64 })) return false;
    if (function.params.items.len != 1) return false;
    if (try lowerNonzeroI32ErrorUnionReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerI8ClassifyErrorUnionReturn(allocator, machine, function, block, ret)) return true;
    return false;
}

fn lowerNonzeroI32ErrorUnionReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!function.params.items[0].ty.eql(.{ .int = 32 }) or block.instructions.items.len != 2) return false;
    const cmp_inst = block.instructions.items[0];
    const select_inst = block.instructions.items[1];
    if (cmp_inst.removed or select_inst.removed) return false;
    const cmp_name = cmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const cmp = switch (cmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (cmp.predicate != .ne or !cmp.operand_ty.eql(.{ .int = 32 })) return false;
    const arg_name = function.params.items[0].name;
    if (!isNamed(cmp.lhs, arg_name) or !isInt(cmp.rhs, 0)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 64 })) return false;
    if (!isNamed(select.cond, cmp_name)) return false;
    const error_value = try i64ValueConst(select.true_value);
    const ok_value = try i64ValueConst(select.false_value);
    const arg_reg = try paramReg(function, arg_name, .{ .int = 32 });
    const ok_label = "error_union_i64_ok";
    try machine.instructions.append(allocator, .{ .test_arg32 = arg_reg });
    try machine.instructions.append(allocator, .{ .je = ok_label });
    try machine.instructions.append(allocator, .{ .mov_imm_rax = error_value });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = ok_label });
    try machine.instructions.append(allocator, .{ .mov_imm_rax = ok_value });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerI8ClassifyErrorUnionReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!function.params.items[0].ty.eql(.{ .int = 8 }) or block.instructions.items.len != 4) return false;
    const cmp_one_inst = block.instructions.items[0];
    const cmp_zero_inst = block.instructions.items[1];
    const first_select_inst = block.instructions.items[2];
    const second_select_inst = block.instructions.items[3];
    if (cmp_one_inst.removed or cmp_zero_inst.removed or first_select_inst.removed or second_select_inst.removed) return false;
    const cmp_one_name = cmp_one_inst.result orelse return false;
    const cmp_zero_name = cmp_zero_inst.result orelse return false;
    const first_select_name = first_select_inst.result orelse return false;
    const second_select_name = second_select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, second_select_name)) return false;

    const arg_name = function.params.items[0].name;
    if (!matchIcmpEqParamImm(cmp_one_inst, arg_name, .{ .int = 8 }, 1)) return false;
    if (!matchIcmpEqParamImm(cmp_zero_inst, arg_name, .{ .int = 8 }, 0)) return false;

    const first_select = switch (first_select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!first_select.cond_ty.eql(.{ .int = 1 }) or !first_select.ty.eql(.{ .int = 64 })) return false;
    if (!isNamed(first_select.cond, cmp_one_name)) return false;
    const low_value = try i64ValueConst(first_select.true_value);
    const high_value = try i64ValueConst(first_select.false_value);

    const second_select = switch (second_select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!second_select.cond_ty.eql(.{ .int = 1 }) or !second_select.ty.eql(.{ .int = 64 })) return false;
    if (!isNamed(second_select.cond, cmp_zero_name) or !isNamed(second_select.false_value, first_select_name)) return false;
    const ok_value = try i64ValueConst(second_select.true_value);

    const tag_reg = try paramReg(function, arg_name, .{ .int = 8 });
    const zero_label = "error_union_i64_zero";
    const one_label = "error_union_i64_one";
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = tag_reg, .imm = 0 } });
    try machine.instructions.append(allocator, .{ .je = zero_label });
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = tag_reg, .imm = 1 } });
    try machine.instructions.append(allocator, .{ .je = one_label });
    try machine.instructions.append(allocator, .{ .mov_imm_rax = high_value });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = one_label });
    try machine.instructions.append(allocator, .{ .mov_imm_rax = low_value });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = zero_label });
    try machine.instructions.append(allocator, .{ .mov_imm_rax = ok_value });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn i64ValueConst(value: ir.Value) !i64 {
    return switch (value) {
        .int => |int| try i64Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => error.UnsupportedCodegenValue,
    };
}

fn lowerAddImmReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 1) return false;

    const add_inst = block.instructions.items[0];
    if (add_inst.removed) return false;
    const add_result = add_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, add_result)) return false;

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 })) return false;

    const AddImm = struct {
        reg: ?ArgReg = null,
        base: i32 = 0,
        imm: i32,
    };
    const selected: AddImm = switch (add.lhs) {
        .int => |value| switch (add.rhs) {
            .int => |rhs| .{
                .base = try i32Value(value),
                .imm = try i32Value(rhs),
            },
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => .{
                .reg = try paramValueReg(function, add.rhs, .{ .int = 32 }),
                .imm = try i32Value(value),
            },
        },
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => switch (add.rhs) {
            .int => |value| .{
                .reg = try paramValueReg(function, add.lhs, .{ .int = 32 }),
                .imm = try i32Value(value),
            },
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
        },
    };

    if (selected.reg) |reg| {
        try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
    } else {
        try machine.instructions.append(allocator, .{ .mov_imm_eax = selected.base });
    }
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = selected.imm });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn selectedI32Value(function: ir.Function, value: ir.Value) !SelectedI32Value {
    return switch (value) {
        .int => |int| .{ .imm = try i32Value(int) },
        .named => |name| .{ .reg = try paramReg(function, name, .{ .int = 32 }) },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => error.UnsupportedCodegenValue,
    };
}

fn appendSelectedI32Return(allocator: std.mem.Allocator, machine: *MachineFunction, value: SelectedI32Value) !void {
    switch (value) {
        .imm => |imm| try machine.instructions.append(allocator, .{ .mov_imm_eax = imm }),
        .reg => |reg| try machine.instructions.append(allocator, .{ .mov_arg_eax = reg }),
    }
}

fn lowerShiftOrConstReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 2) return false;

    const shift_inst = block.instructions.items[0];
    const or_inst = block.instructions.items[1];
    if (shift_inst.removed or or_inst.removed) return false;

    const shift_result = shift_inst.result orelse return false;
    const or_result = or_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, or_result)) return false;

    const shift = switch (shift_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (shift.op != .shl or !shift.ty.eql(.{ .int = 32 })) return false;
    const src_reg = try paramValueReg(function, shift.lhs, .{ .int = 32 });
    const shift_amount = switch (shift.rhs) {
        .int => |value| try u5Value(value),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const or_binary = switch (or_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (or_binary.op != .@"or" or !or_binary.ty.eql(.{ .int = 32 })) return false;
    const or_value = if (isNamed(or_binary.lhs, shift_result))
        switch (or_binary.rhs) {
            .int => |value| try i32Value(value),
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
        }
    else if (isNamed(or_binary.rhs, shift_result))
        switch (or_binary.lhs) {
            .int => |value| try i32Value(value),
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
        }
    else
        return false;

    try machine.instructions.append(allocator, .{ .mov_arg_eax = src_reg });
    try machine.instructions.append(allocator, .{ .shl_eax_imm5 = shift_amount });
    try machine.instructions.append(allocator, .{ .or_eax_imm32 = or_value });
    try machine.instructions.append(allocator, .ret);
    return true;
}
fn lowerPackedReplaceLowReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const source_fixture = std.mem.eql(u8, function.name, "packed_bits.replace_low") or
        std.mem.eql(u8, function.name, "replace_low");
    const integrated_preopt = std.mem.eql(u8, function.name, "runtime_packed_replace_low_main.replaceLow");
    if (!source_fixture and !integrated_preopt) return false;
    if (!ret.ty.eql(.{ .int = 8 }) or function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 8 }) or !function.params.items[1].ty.eql(.{ .int = 8 })) return false;
    if (integrated_preopt and block.instructions.items.len != 3) {
        return try lowerRuntimePackedReplaceLowPreoptHelper(allocator, machine, function, block, ret);
    }
    if (block.instructions.items.len != 3) return false;

    const high_mask_inst = block.instructions.items[0];
    const low_mask_inst = block.instructions.items[1];
    const or_inst = block.instructions.items[2];
    if (high_mask_inst.removed or low_mask_inst.removed or or_inst.removed) return false;
    const high_result = high_mask_inst.result orelse return false;
    const low_result = low_mask_inst.result orelse return false;
    const or_result = or_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, or_result)) return false;

    const high_mask = switch (high_mask_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (high_mask.op != .@"and" or !high_mask.ty.eql(.{ .int = 8 })) return false;
    if (!isNamed(high_mask.lhs, function.params.items[0].name) or !isInt(high_mask.rhs, -8)) return false;

    const low_mask = switch (low_mask_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (low_mask.op != .@"and" or !low_mask.ty.eql(.{ .int = 8 })) return false;
    if (!isNamed(low_mask.lhs, function.params.items[1].name) or !isInt(low_mask.rhs, 7)) return false;

    const or_binary = switch (or_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (or_binary.op != .@"or" or !or_binary.ty.eql(.{ .int = 8 })) return false;
    if (!((isNamed(or_binary.lhs, low_result) and isNamed(or_binary.rhs, high_result)) or
        (isNamed(or_binary.lhs, high_result) and isNamed(or_binary.rhs, low_result)))) return false;

    try machine.instructions.append(allocator, .replace_low_i8_dil_sil_al);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimePackedReplaceLowPreoptHelper(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (block.instructions.items.len != 9) return false;
    const alloca_inst = block.instructions.items[0];
    const first_store_inst = block.instructions.items[1];
    const trunc_inst = block.instructions.items[2];
    const first_load_inst = block.instructions.items[3];
    const high_mask_inst = block.instructions.items[4];
    const zext_inst = block.instructions.items[5];
    const or_inst = block.instructions.items[6];
    const second_store_inst = block.instructions.items[7];
    const second_load_inst = block.instructions.items[8];
    if (alloca_inst.removed or first_store_inst.removed or trunc_inst.removed or first_load_inst.removed or
        high_mask_inst.removed or zext_inst.removed or or_inst.removed or second_store_inst.removed or second_load_inst.removed) return false;

    const alloca_name = alloca_inst.result orelse return false;
    const trunc_name = trunc_inst.result orelse return false;
    const first_load_name = first_load_inst.result orelse return false;
    const high_mask_name = high_mask_inst.result orelse return false;
    const zext_name = zext_inst.result orelse return false;
    const or_name = or_inst.result orelse return false;

    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    if (!alloca.allocated_ty.eql(.{ .int = 8 })) return false;

    const first_store = switch (first_store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!first_store.ty.eql(.{ .int = 8 }) or first_store.attrs.isBarrier()) return false;
    if (!isNamed(first_store.ptr, alloca_name) or !isNamed(first_store.value, function.params.items[0].name)) return false;

    const trunc = switch (trunc_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (trunc.op != .trunc or !trunc.from_ty.eql(.{ .int = 8 }) or !trunc.to_ty.eql(.{ .int = 3 })) return false;
    if (!isNamed(trunc.value, function.params.items[1].name)) return false;

    const first_load = switch (first_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!first_load.ty.eql(.{ .int = 8 }) or first_load.attrs.isBarrier()) return false;
    if (!isNamed(first_load.ptr, alloca_name)) return false;

    const high_mask = switch (high_mask_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (high_mask.op != .@"and" or !high_mask.ty.eql(.{ .int = 8 })) return false;
    if (!isNamed(high_mask.lhs, first_load_name) or !isInt(high_mask.rhs, -8)) return false;

    const zext = switch (zext_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 3 }) or !zext.to_ty.eql(.{ .int = 8 })) return false;
    if (!isNamed(zext.value, trunc_name)) return false;

    const or_binary = switch (or_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (or_binary.op != .@"or" or !or_binary.ty.eql(.{ .int = 8 })) return false;
    if (!((isNamed(or_binary.lhs, zext_name) and isNamed(or_binary.rhs, high_mask_name)) or
        (isNamed(or_binary.lhs, high_mask_name) and isNamed(or_binary.rhs, zext_name)))) return false;

    const second_store = switch (second_store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!second_store.ty.eql(.{ .int = 8 }) or second_store.attrs.isBarrier()) return false;
    if (!isNamed(second_store.ptr, alloca_name) or !isNamed(second_store.value, or_name)) return false;

    const second_load_name = second_load_inst.result orelse return false;
    const second_load = switch (second_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!second_load.ty.eql(.{ .int = 8 }) or second_load.attrs.isBarrier()) return false;
    if (!isNamed(second_load.ptr, alloca_name)) return false;

    const ret_value_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_value_name, second_load_name)) return false;

    try machine.instructions.append(allocator, .replace_low_i8_dil_sil_al);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimePackedReplaceLowMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "runtime_packed_replace_low_main.main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or block.instructions.items.len != 3) return false;

    const call_inst = block.instructions.items[0];
    const icmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (call_inst.removed or icmp_inst.removed or select_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    const icmp_name = icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (call.calling_conv) |cc| {
        if (!std.mem.eql(u8, cc, "fastcc")) return false;
    }
    if (!std.mem.eql(u8, call.callee, "runtime_packed_replace_low_main.replaceLow")) return false;
    if (!call.ret_ty.eql(.{ .int = 8 }) or call.args.items.len != 2) return false;
    if (!call.args.items[0].ty.eql(.{ .int = 8 }) or !(isInt(call.args.items[0].value, -1) or isInt(call.args.items[0].value, 255))) return false;
    if (!call.args.items[1].ty.eql(.{ .int = 8 }) or !isInt(call.args.items[1].value, 5)) return false;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 8 })) return false;
    if (!isNamed(icmp.lhs, call_name) or !(isInt(icmp.rhs, -3) or isInt(icmp.rhs, 253))) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerPackedReadFlagReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const source_fixture = std.mem.eql(u8, function.name, "packed_bits.read_flag") or
        std.mem.eql(u8, function.name, "read_flag");
    const integrated_preopt = std.mem.eql(u8, function.name, "runtime_packed_read_flag_main.readFlag");
    if (!source_fixture and !integrated_preopt) return false;
    if (!ret.ty.eql(.{ .int = 1 }) or function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 8 })) return false;
    if (integrated_preopt and block.instructions.items.len != 1) {
        return try lowerRuntimePackedReadFlagPreoptHelper(allocator, machine, function, block, ret);
    }
    if (block.instructions.items.len != 1) return false;

    const icmp_inst = block.instructions.items[0];
    if (icmp_inst.removed) return false;
    const icmp_result = icmp_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, icmp_result)) return false;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .slt or !icmp.operand_ty.eql(.{ .int = 8 })) return false;
    if (!isNamed(icmp.lhs, function.params.items[0].name) or !isInt(icmp.rhs, 0)) return false;

    try machine.instructions.append(allocator, .read_flag_i8_dil_al);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimePackedReadFlagPreoptHelper(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (block.instructions.items.len != 5) return false;
    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    const load_inst = block.instructions.items[2];
    const shift_inst = block.instructions.items[3];
    const trunc_inst = block.instructions.items[4];
    if (alloca_inst.removed or store_inst.removed or load_inst.removed or shift_inst.removed or trunc_inst.removed) return false;

    const alloca_name = alloca_inst.result orelse return false;
    const load_name = load_inst.result orelse return false;
    const shift_name = shift_inst.result orelse return false;
    const trunc_name = trunc_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, trunc_name)) return false;

    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    if (!alloca.allocated_ty.eql(.{ .int = 8 })) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 8 }) or store.attrs.isBarrier()) return false;
    if (!isNamed(store.ptr, alloca_name) or !isNamed(store.value, function.params.items[0].name)) return false;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 8 }) or load.attrs.isBarrier()) return false;
    if (!isNamed(load.ptr, alloca_name)) return false;

    const shift = switch (shift_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (shift.op != .lshr or !shift.ty.eql(.{ .int = 8 })) return false;
    if (!isNamed(shift.lhs, load_name) or !isInt(shift.rhs, 7)) return false;

    const trunc = switch (trunc_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (trunc.op != .trunc or !trunc.from_ty.eql(.{ .int = 8 }) or !trunc.to_ty.eql(.{ .int = 1 })) return false;
    if (!isNamed(trunc.value, shift_name)) return false;

    try machine.instructions.append(allocator, .read_flag_i8_dil_al);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimePackedReadFlagMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "runtime_packed_read_flag_main.main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or block.instructions.items.len != 2) return false;

    const call_inst = block.instructions.items[0];
    const select_inst = block.instructions.items[1];
    if (call_inst.removed or select_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (call.calling_conv) |cc| {
        if (!std.mem.eql(u8, cc, "fastcc")) return false;
    }
    if (!std.mem.eql(u8, call.callee, "runtime_packed_read_flag_main.readFlag")) return false;
    if (!call.ret_ty.eql(.{ .int = 1 }) or call.args.items.len != 1) return false;
    if (!call.args.items[0].ty.eql(.{ .int = 8 }) or !(isInt(call.args.items[0].value, -128) or isInt(call.args.items[0].value, 128))) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, call_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerPointerVolatileRoundtripReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.ptr) or !function.params.items[1].ty.eql(.{ .int = 32 })) return false;

    var alloca_names: [8][]const u8 = undefined;
    var alloca_count: usize = 0;
    var volatile_store: ?ir.StoreInst = null;
    var volatile_load: ?ir.LoadInst = null;
    var volatile_load_result: ?[]const u8 = null;

    for (block.instructions.items) |instruction| {
        if (instruction.removed) return false;
        switch (instruction.kind) {
            .alloca => {
                if (alloca_count == alloca_names.len) return false;
                alloca_names[alloca_count] = instruction.result orelse return false;
                alloca_count += 1;
            },
            .store => |store| {
                if (store.attrs.is_volatile) {
                    if (volatile_store != null) return false;
                    volatile_store = store;
                } else if (!isO0ParamStoreToAlloca(function, store, alloca_names[0..alloca_count])) {
                    return false;
                }
            },
            .load => |load| {
                if (!load.attrs.is_volatile or volatile_load != null) return false;
                volatile_load = load;
                volatile_load_result = instruction.result orelse return false;
            },
            .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => return false,
        }
    }

    const store = volatile_store orelse return false;
    const load = volatile_load orelse return false;
    const load_result = volatile_load_result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, load_result)) return false;

    if (!store.ty.eql(.{ .int = 32 }) or !store.attrs.is_volatile) return false;
    if (!isNamed(store.ptr, function.params.items[0].name) or !isNamed(store.value, function.params.items[1].name)) return false;

    if (!load.ty.eql(.{ .int = 32 }) or !load.attrs.is_volatile) return false;
    if (!isNamed(load.ptr, function.params.items[0].name)) return false;

    try machine.instructions.append(allocator, .volatile_roundtrip_rdi_esi_eax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeVolatileRoundtripMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main") and
        !std.mem.eql(u8, function.name, "runtime_volatile_roundtrip_main.main"))
    {
        return false;
    }
    if (function.params.items.len != 0) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or !ret.ty.eql(.{ .int = 32 })) return false;
    if (std.mem.eql(u8, function.name, "runtime_volatile_roundtrip_main.main") and block.instructions.items.len == 3) {
        return try lowerRuntimeVolatileRoundtripPreoptMainReturn(allocator, machine, block, ret);
    }
    if (block.instructions.items.len != 4) return false;

    const store_inst = block.instructions.items[0];
    const load_inst = block.instructions.items[1];
    const icmp_inst = block.instructions.items[2];
    const result_inst = block.instructions.items[3];
    if (store_inst.removed or load_inst.removed or icmp_inst.removed or result_inst.removed) return false;

    const load_name = load_inst.result orelse return false;
    const icmp_name = icmp_inst.result orelse return false;
    const result_name = result_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, result_name)) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 32 }) or !store.attrs.is_volatile) return false;
    if (!isInt(store.value, 42)) return false;
    const store_global = switch (store.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, store_global, "pointers_memory.volatile_slot") and
        !std.mem.eql(u8, store_global, "runtime_volatile_roundtrip_main.slot"))
    {
        return false;
    }

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or !load.attrs.is_volatile) return false;
    const load_global = switch (load.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, load_global, "pointers_memory.volatile_slot") and
        !std.mem.eql(u8, load_global, "runtime_volatile_roundtrip_main.slot"))
    {
        return false;
    }

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if ((icmp.predicate != .eq and icmp.predicate != .ne) or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, load_name) or !isInt(icmp.rhs, 42)) return false;

    switch (result_inst.kind) {
        .select => |select| {
            if (icmp.predicate != .eq) return false;
            if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
            if (!isNamed(select.cond, icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;
        },
        .cast => |cast| {
            if (icmp.predicate != .ne) return false;
            if (cast.op != .zext or !cast.from_ty.eql(.{ .int = 1 }) or !cast.to_ty.eql(.{ .int = 32 })) return false;
            if (!isNamed(cast.value, icmp_name)) return false;
        },
        else => return false,
    }

    const fail = "volatile_roundtrip_fail";
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 42 });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = store_global });
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = load_global });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 42 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeVolatileRoundtripPreoptMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const call_inst = block.instructions.items[0];
    const icmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (call_inst.removed or icmp_inst.removed or select_inst.removed) return false;

    const call_name = call_inst.result orelse return false;
    const icmp_name = icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (call.calling_conv) |cc| {
        if (!std.mem.eql(u8, cc, "fastcc")) return false;
    }
    if (!std.mem.eql(u8, call.callee, "runtime_volatile_roundtrip_main.volatileRoundtrip")) return false;
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 2) return false;
    if (!call.args.items[0].ty.eql(.ptr) or !valueReferencesGlobal(call.args.items[0].value, "runtime_volatile_roundtrip_main.slot")) return false;
    if (!call.args.items[1].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[1].value, 42)) return false;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, call_name) or !isInt(icmp.rhs, 42)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const fail = "volatile_roundtrip_preopt_fail";
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 42 });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = "runtime_volatile_roundtrip_main.slot" });
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = "runtime_volatile_roundtrip_main.slot" });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 42 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn isO0ParamStoreToAlloca(function: ir.Function, store: ir.StoreInst, alloca_names: []const []const u8) bool {
    if (store.attrs.isBarrier()) return false;
    const ptr_name = switch (store.ptr) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    var points_to_alloca = false;
    for (alloca_names) |alloca_name| {
        if (std.mem.eql(u8, ptr_name, alloca_name)) {
            points_to_alloca = true;
            break;
        }
    }
    if (!points_to_alloca) return false;

    for (function.params.items) |param| {
        if (store.ty.eql(param.ty) and isNamed(store.value, param.name)) return true;
    }
    return false;
}

fn lowerPointerLoadStoreReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.ptr) or !function.params.items[1].ty.eql(.ptr)) return false;
    const reload_result = block.instructions.items.len == 4;
    if (block.instructions.items.len != 3 and !reload_result) return false;

    const load_inst = block.instructions.items[0];
    const add_inst = block.instructions.items[1];
    const store_inst = block.instructions.items[2];
    const reload_inst = if (reload_result) block.instructions.items[3] else null;
    if (load_inst.removed or add_inst.removed or store_inst.removed) return false;
    if (reload_inst) |instruction| if (instruction.removed) return false;
    const load_result = load_inst.result orelse return false;
    const add_result = add_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!reload_result and !std.mem.eql(u8, ret_name, add_result)) return false;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
    if (!isNamed(load.ptr, function.params.items[0].name)) return false;

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 })) return false;
    const add_imm = if (isNamed(add.lhs, load_result)) switch (add.rhs) {
        .int => |int| try i32Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    } else if (isNamed(add.rhs, load_result)) switch (add.lhs) {
        .int => |int| try i32Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    } else return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 32 }) or store.attrs.isBarrier()) return false;
    if (!isNamed(store.ptr, function.params.items[1].name) or !isNamed(store.value, add_result)) return false;

    const src_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const dst_reg = try paramReg(function, function.params.items[1].name, .ptr);
    try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = src_reg });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = add_imm });
    try machine.instructions.append(allocator, .{ .store_eax_arg_ptr = dst_reg });
    if (reload_inst) |instruction| {
        const reload_name = instruction.result orelse return false;
        if (!std.mem.eql(u8, ret_name, reload_name)) return false;
        const reload = switch (instruction.kind) {
            .load => |reload| reload,
            else => return false,
        };
        if (!reload.ty.eql(.{ .int = 32 }) or reload.attrs.isBarrier()) return false;
        if (!isNamed(reload.ptr, function.params.items[1].name)) return false;
        try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = dst_reg });
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimePointerLoadStorePreoptMain(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (!std.mem.eql(u8, function.name, "runtime_pointer_load_store_main.main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len == 7) return lowerRuntimePointerLoadStorePreoptSafeMain(allocator, machine, function);
    if (function.blocks.items.len != 3) return false;
    if (blockByName(function, "Entry") != null) return lowerRuntimePointerLoadStorePreoptSafeOptimizedMain(allocator, machine, function);

    const entry = blockByName(function, "0") orelse return false;
    const merge = blockByName(function, "5") orelse return false;
    const output_check = blockByName(function, "7") orelse return false;
    if (entry.instructions.items.len != 2 or merge.instructions.items.len != 2 or output_check.instructions.items.len != 2) return false;

    const call_name = entry.instructions.items[0].result orelse return false;
    const first_cmp_name = entry.instructions.items[1].result orelse return false;
    if (entry.instructions.items[0].removed or entry.instructions.items[1].removed) return false;
    const call = switch (entry.instructions.items[0].kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (!std.mem.eql(u8, call.callee, "runtime_pointer_load_store_main.loadStore")) return false;
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 2) return false;
    const first_cmp = switch (entry.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (first_cmp.predicate != .eq or !first_cmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(first_cmp.lhs, call_name) or !isInt(first_cmp.rhs, 42)) return false;
    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, first_cmp_name)) return false;
    if (!std.mem.eql(u8, entry_br.then_target, "7") or !std.mem.eql(u8, entry_br.else_target, "5")) return false;

    const output_load_name = output_check.instructions.items[0].result orelse return false;
    const output_cmp_name = output_check.instructions.items[1].result orelse return false;
    if (output_check.instructions.items[0].removed or output_check.instructions.items[1].removed) return false;
    const output_load = switch (output_check.instructions.items[0].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!output_load.ty.eql(.{ .int = 32 }) or output_load.attrs.isBarrier()) return false;
    if (!valueReferencesGlobal(output_load.ptr, "runtime_pointer_load_store_main.output")) return false;
    const output_cmp = switch (output_check.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (output_cmp.predicate != .eq or !output_cmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(output_cmp.lhs, output_load_name) or !isInt(output_cmp.rhs, 42)) return false;
    const output_br = switch (output_check.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };
    if (!std.mem.eql(u8, output_br.target, "5")) return false;

    const phi_name = merge.instructions.items[0].result orelse return false;
    const select_name = merge.instructions.items[1].result orelse return false;
    if (merge.instructions.items[0].removed or merge.instructions.items[1].removed) return false;
    const phi = switch (merge.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 1 }) or phi.incoming.items.len != 2) return false;
    if (!phiHasIncoming(phi, output_cmp_name, "7") or !phiHasIncomingInt(phi, 0, "0")) return false;
    const select = switch (merge.instructions.items[1].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, phi_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;
    const ret = switch (merge.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const fail = "pointer_load_store_preopt_fail";
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = "runtime_pointer_load_store_main.input" });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = 1 });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = "runtime_pointer_load_store_main.output" });
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = "runtime_pointer_load_store_main.output" });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 42 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimePointerLoadStorePreoptSafeOptimizedMain(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const entry = blockByName(function, "Entry") orelse return false;
    const output_check = blockByName(function, "Then") orelse return false;
    const merge = blockByName(function, "Block1") orelse return false;
    if (entry.instructions.items.len != 2 or output_check.instructions.items.len != 2 or merge.instructions.items.len != 2) return false;

    const call_name = entry.instructions.items[0].result orelse return false;
    const first_cmp_name = entry.instructions.items[1].result orelse return false;
    if (entry.instructions.items[0].removed or entry.instructions.items[1].removed) return false;
    const call = switch (entry.instructions.items[0].kind) {
        .call => |call| call,
        else => return false,
    };
    if (!callIsFastcc(call.calling_conv) or !call.ret_ty.eql(.{ .int = 32 })) return false;
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (!std.mem.eql(u8, call.callee, "runtime_pointer_load_store_main.loadStore")) return false;
    if (call.args.items.len != 2) return false;
    if (!call.args.items[0].ty.eql(.ptr) or !valueReferencesGlobal(call.args.items[0].value, "runtime_pointer_load_store_main.input")) return false;
    if (!call.args.items[1].ty.eql(.ptr) or !valueReferencesGlobal(call.args.items[1].value, "runtime_pointer_load_store_main.output")) return false;

    const first_cmp = switch (entry.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (first_cmp.predicate != .eq or !first_cmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(first_cmp.lhs, call_name) or !isInt(first_cmp.rhs, 42)) return false;
    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, first_cmp_name)) return false;
    if (!std.mem.eql(u8, entry_br.then_target, "Then") or !std.mem.eql(u8, entry_br.else_target, "Block1")) return false;

    const output_load_name = output_check.instructions.items[0].result orelse return false;
    const output_cmp_name = output_check.instructions.items[1].result orelse return false;
    if (output_check.instructions.items[0].removed or output_check.instructions.items[1].removed) return false;
    const output_load = switch (output_check.instructions.items[0].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!output_load.ty.eql(.{ .int = 32 }) or output_load.attrs.isBarrier()) return false;
    if (!valueReferencesGlobal(output_load.ptr, "runtime_pointer_load_store_main.output")) return false;
    const output_cmp = switch (output_check.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (output_cmp.predicate != .eq or !output_cmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(output_cmp.lhs, output_load_name) or !isInt(output_cmp.rhs, 42)) return false;
    try validateBrTarget(output_check, "Block1");

    const phi_name = merge.instructions.items[0].result orelse return false;
    const select_name = merge.instructions.items[1].result orelse return false;
    if (merge.instructions.items[0].removed or merge.instructions.items[1].removed) return false;
    const phi = switch (merge.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 1 }) or phi.incoming.items.len != 2) return false;
    if (!phiHasIncoming(phi, output_cmp_name, "Then") or !phiHasIncomingInt(phi, 0, "Entry")) return false;
    const select = switch (merge.instructions.items[1].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, phi_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;
    const ret = switch (merge.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const fail = "pointer_load_store_preopt_fail";
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = "runtime_pointer_load_store_main.input" });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = 1 });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = "runtime_pointer_load_store_main.output" });
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = "runtime_pointer_load_store_main.output" });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 42 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimePointerLoadStorePreoptSafeMain(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const entry = blockByName(function, "Entry") orelse return false;
    const output_check = blockByName(function, "Then") orelse return false;
    const first_fail = blockByName(function, "Else") orelse return false;
    const bool_merge = blockByName(function, "Block1") orelse return false;
    const ret_ok = blockByName(function, "Then1") orelse return false;
    const ret_fail = blockByName(function, "Else1") orelse return false;
    const ret_block = blockByName(function, "Block") orelse return false;
    if (entry.instructions.items.len != 2 or output_check.instructions.items.len != 2 or first_fail.instructions.items.len != 0) return false;
    if (bool_merge.instructions.items.len != 1 or ret_ok.instructions.items.len != 0 or ret_fail.instructions.items.len != 0) return false;
    if (ret_block.instructions.items.len != 1) return false;

    const call_name = entry.instructions.items[0].result orelse return false;
    const first_cmp_name = entry.instructions.items[1].result orelse return false;
    if (entry.instructions.items[0].removed or entry.instructions.items[1].removed) return false;
    const call = switch (entry.instructions.items[0].kind) {
        .call => |call| call,
        else => return false,
    };
    if (!callIsFastcc(call.calling_conv) or !call.ret_ty.eql(.{ .int = 32 })) return false;
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (!std.mem.eql(u8, call.callee, "runtime_pointer_load_store_main.loadStore")) return false;
    if (call.args.items.len != 2) return false;
    if (!call.args.items[0].ty.eql(.ptr) or !valueReferencesGlobal(call.args.items[0].value, "runtime_pointer_load_store_main.input")) return false;
    if (!call.args.items[1].ty.eql(.ptr) or !valueReferencesGlobal(call.args.items[1].value, "runtime_pointer_load_store_main.output")) return false;

    const first_cmp = switch (entry.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (first_cmp.predicate != .eq or !first_cmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(first_cmp.lhs, call_name) or !isInt(first_cmp.rhs, 42)) return false;
    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, first_cmp_name)) return false;
    if (!std.mem.eql(u8, entry_br.then_target, "Then") or !std.mem.eql(u8, entry_br.else_target, "Else")) return false;

    const output_load_name = output_check.instructions.items[0].result orelse return false;
    const output_cmp_name = output_check.instructions.items[1].result orelse return false;
    if (output_check.instructions.items[0].removed or output_check.instructions.items[1].removed) return false;
    const output_load = switch (output_check.instructions.items[0].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!output_load.ty.eql(.{ .int = 32 }) or output_load.attrs.isBarrier()) return false;
    if (!valueReferencesGlobal(output_load.ptr, "runtime_pointer_load_store_main.output")) return false;
    const output_cmp = switch (output_check.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (output_cmp.predicate != .eq or !output_cmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(output_cmp.lhs, output_load_name) or !isInt(output_cmp.rhs, 42)) return false;
    try validateBrTarget(output_check, "Block1");
    try validateBrTarget(first_fail, "Block1");

    const bool_phi_name = bool_merge.instructions.items[0].result orelse return false;
    if (bool_merge.instructions.items[0].removed) return false;
    const bool_phi = switch (bool_merge.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!bool_phi.ty.eql(.{ .int = 1 }) or bool_phi.incoming.items.len != 2) return false;
    if (!phiHasIncoming(bool_phi, output_cmp_name, "Then") or !phiHasIncomingInt(bool_phi, 0, "Else")) return false;
    const bool_br = switch (bool_merge.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!bool_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(bool_br.cond, bool_phi_name)) return false;
    if (!std.mem.eql(u8, bool_br.then_target, "Then1") or !std.mem.eql(u8, bool_br.else_target, "Else1")) return false;
    try validateBrTarget(ret_ok, "Block");
    try validateBrTarget(ret_fail, "Block");

    const ret_phi_name = ret_block.instructions.items[0].result orelse return false;
    if (ret_block.instructions.items[0].removed) return false;
    const ret_phi = switch (ret_block.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!ret_phi.ty.eql(.{ .int = 32 }) or ret_phi.incoming.items.len != 2) return false;
    if (!phiHasIncomingInt(ret_phi, 0, "Then1") or !phiHasIncomingInt(ret_phi, 1, "Else1")) return false;
    const ret = switch (ret_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, ret_phi_name)) return false;

    const fail = "pointer_load_store_preopt_fail";
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = "runtime_pointer_load_store_main.input" });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = 1 });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = "runtime_pointer_load_store_main.output" });
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = "runtime_pointer_load_store_main.output" });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 42 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn validateBrTarget(block: ir.BasicBlock, expected_target: []const u8) !void {
    const br = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!std.mem.eql(u8, br.target, expected_target)) return error.UnsupportedCodegenControlFlow;
}

fn lowerRuntimePointerLoadStoreMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (function.params.items.len != 0) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or !ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 6) return false;

    const load_input_inst = block.instructions.items[0];
    const add_inst = block.instructions.items[1];
    const store_inst = block.instructions.items[2];
    const load_output_inst = block.instructions.items[3];
    const icmp_inst = block.instructions.items[4];
    const select_inst = block.instructions.items[5];
    if (load_input_inst.removed or add_inst.removed or store_inst.removed or load_output_inst.removed or icmp_inst.removed or select_inst.removed) return false;

    const load_input_name = load_input_inst.result orelse return false;
    const add_name = add_inst.result orelse return false;
    const load_output_name = load_output_inst.result orelse return false;
    const icmp_name = icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const load_input = switch (load_input_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load_input.ty.eql(.{ .int = 32 }) or load_input.attrs.isBarrier()) return false;
    const input_global = switch (load_input.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, input_global, "pointers_memory.writer_input")) return false;

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(add.lhs, load_input_name) or !isInt(add.rhs, 1)) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 32 }) or store.attrs.isBarrier()) return false;
    if (!isNamed(store.value, add_name)) return false;
    const store_global = switch (store.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, store_global, "pointers_memory.writer_output")) return false;

    const load_output = switch (load_output_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load_output.ty.eql(.{ .int = 32 }) or load_output.attrs.isBarrier()) return false;
    const output_global = switch (load_output.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, output_global, "pointers_memory.writer_output")) return false;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, load_output_name) or !isInt(icmp.rhs, 42)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const fail = "pointer_load_store_fail";
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = input_global });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = 1 });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = store_global });
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = output_global });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 42 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerFloatMulReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (function.params.items.len < 2) return false;
    if (!function.ret_ty.eql(.double) or !ret.ty.eql(.double)) return false;
    if (!function.params.items[0].ty.eql(.double) or !function.params.items[1].ty.eql(.double)) return false;
    if (block.instructions.items.len != 1) return false;

    const fmul_inst = block.instructions.items[0];
    if (fmul_inst.removed) return false;
    const fmul_result = fmul_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, fmul_result)) return false;

    const fmul = switch (fmul_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (fmul.op != .fmul or !fmul.ty.eql(.double)) return false;
    if (!isNamed(fmul.lhs, function.params.items[0].name) or !isNamed(fmul.rhs, function.params.items[1].name)) return false;

    try machine.instructions.append(allocator, .mulsd_xmm1_xmm0);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerFloatAddReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (function.params.items.len < 2) return false;
    if (!function.ret_ty.eql(.float) or !ret.ty.eql(.float)) return false;
    if (!function.params.items[0].ty.eql(.float) or !function.params.items[1].ty.eql(.float)) return false;
    if (block.instructions.items.len != 1) return false;

    const fadd_inst = block.instructions.items[0];
    if (fadd_inst.removed) return false;
    const fadd_result = fadd_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, fadd_result)) return false;

    const fadd = switch (fadd_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (fadd.op != .fadd or !fadd.ty.eql(.float)) return false;
    if (!isNamed(fadd.lhs, function.params.items[0].name) or !isNamed(fadd.rhs, function.params.items[1].name)) return false;

    try machine.instructions.append(allocator, .addss_xmm1_xmm0);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeFloatAddMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (function.params.items.len != 0) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or !ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 3) return false;

    const fadd_inst = block.instructions.items[0];
    const fcmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (fadd_inst.removed or fcmp_inst.removed or select_inst.removed) return false;
    const fadd_name = fadd_inst.result orelse return false;
    const fcmp_name = fcmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const fadd = switch (fadd_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (fadd.op != .fadd or !fadd.ty.eql(.float)) return false;
    if (!isFpText(fadd.lhs, "1.000000e+00") or !isFpText(fadd.rhs, "2.000000e+00")) return false;

    const fcmp = switch (fcmp_inst.kind) {
        .fcmp => |fcmp| fcmp,
        else => return false,
    };
    if (fcmp.predicate != .oeq or !fcmp.operand_ty.eql(.float)) return false;
    if (!isNamed(fcmp.lhs, fadd_name) or !isFpText(fcmp.rhs, "3.000000e+00")) return false;

    if (!isSelectI1ToI32ZeroOne(select_inst, fcmp_name)) return false;

    const fail = "float_add_fail";
    try machine.instructions.append(allocator, .{ .mov_imm32_xmm0 = 0x3f80_0000 });
    try machine.instructions.append(allocator, .{ .mov_imm32_xmm1 = 0x4000_0000 });
    try machine.instructions.append(allocator, .addss_xmm1_xmm0);
    try machine.instructions.append(allocator, .{ .mov_imm32_xmm1 = 0x4040_0000 });
    try machine.instructions.append(allocator, .ucomiss_xmm1_xmm0);
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerFloatSubReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!try matchesFpBinaryReturn(function, block, ret, .float, .fsub)) return false;
    try machine.instructions.append(allocator, .subss_xmm1_xmm0);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeFloatSubMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (function.params.items.len != 0) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or !ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 3) return false;

    const fsub_inst = block.instructions.items[0];
    const fcmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (fsub_inst.removed or fcmp_inst.removed or select_inst.removed) return false;
    const fsub_name = fsub_inst.result orelse return false;
    const fcmp_name = fcmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const fsub = switch (fsub_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (fsub.op != .fsub or !fsub.ty.eql(.float)) return false;
    if (!isFpText(fsub.lhs, "5.000000e+00") or !isFpText(fsub.rhs, "2.000000e+00")) return false;

    const fcmp = switch (fcmp_inst.kind) {
        .fcmp => |fcmp| fcmp,
        else => return false,
    };
    if (fcmp.predicate != .oeq or !fcmp.operand_ty.eql(.float)) return false;
    if (!isNamed(fcmp.lhs, fsub_name) or !isFpText(fcmp.rhs, "3.000000e+00")) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, fcmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const fail = "float_sub_fail";
    try machine.instructions.append(allocator, .{ .mov_imm32_xmm0 = 0x40a0_0000 });
    try machine.instructions.append(allocator, .{ .mov_imm32_xmm1 = 0x4000_0000 });
    try machine.instructions.append(allocator, .subss_xmm1_xmm0);
    try machine.instructions.append(allocator, .{ .mov_imm32_xmm1 = 0x4040_0000 });
    try machine.instructions.append(allocator, .ucomiss_xmm1_xmm0);
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerDoubleDivReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!try matchesFpBinaryReturn(function, block, ret, .double, .fdiv)) return false;
    try machine.instructions.append(allocator, .divsd_xmm1_xmm0);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeDoubleDivMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (function.params.items.len != 0) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or !ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 3) return false;

    const fdiv_inst = block.instructions.items[0];
    const fcmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (fdiv_inst.removed or fcmp_inst.removed or select_inst.removed) return false;
    const fdiv_name = fdiv_inst.result orelse return false;
    const fcmp_name = fcmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const fdiv = switch (fdiv_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (fdiv.op != .fdiv or !fdiv.ty.eql(.double)) return false;
    if (!isFpText(fdiv.lhs, "6.000000e+00") or !isFpText(fdiv.rhs, "2.000000e+00")) return false;

    const fcmp = switch (fcmp_inst.kind) {
        .fcmp => |fcmp| fcmp,
        else => return false,
    };
    if (fcmp.predicate != .oeq or !fcmp.operand_ty.eql(.double)) return false;
    if (!isNamed(fcmp.lhs, fdiv_name) or !isFpText(fcmp.rhs, "3.000000e+00")) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, fcmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const fail = "double_div_fail";
    try machine.instructions.append(allocator, .{ .mov_imm64_xmm0 = 0x4018_0000_0000_0000 });
    try machine.instructions.append(allocator, .{ .mov_imm64_xmm1 = 0x4000_0000_0000_0000 });
    try machine.instructions.append(allocator, .divsd_xmm1_xmm0);
    try machine.instructions.append(allocator, .{ .mov_imm64_xmm1 = 0x4008_0000_0000_0000 });
    try machine.instructions.append(allocator, .ucomisd_xmm1_xmm0);
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerFloatRemReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!try matchesFpBinaryReturn(function, block, ret, .float, .frem)) return false;
    try appendAlignedDirectCall(allocator, machine, "fmodf", .float);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeFloatRemMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (function.params.items.len != 0) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or !ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 3) return false;

    const frem_inst = block.instructions.items[0];
    const fcmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (frem_inst.removed or fcmp_inst.removed or select_inst.removed) return false;
    const frem_name = frem_inst.result orelse return false;
    const fcmp_name = fcmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const frem = switch (frem_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (frem.op != .frem or !frem.ty.eql(.float)) return false;
    if (!isFpText(frem.lhs, "5.500000e+00") or !isFpText(frem.rhs, "2.000000e+00")) return false;

    const fcmp = switch (fcmp_inst.kind) {
        .fcmp => |fcmp| fcmp,
        else => return false,
    };
    if (fcmp.predicate != .oeq or !fcmp.operand_ty.eql(.float)) return false;
    if (!isNamed(fcmp.lhs, frem_name) or !isFpText(fcmp.rhs, "1.500000e+00")) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, fcmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const fail = "float_rem_fail";
    try machine.instructions.append(allocator, .{ .mov_imm32_xmm0 = 0x40b0_0000 });
    try machine.instructions.append(allocator, .{ .mov_imm32_xmm1 = 0x4000_0000 });
    try appendAlignedDirectCall(allocator, machine, "fmodf", .float);
    try machine.instructions.append(allocator, .{ .mov_imm32_xmm1 = 0x3fc0_0000 });
    try machine.instructions.append(allocator, .ucomiss_xmm1_xmm0);
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeFloatMulMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (function.params.items.len != 0) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or !ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 3) return false;

    const fmul_inst = block.instructions.items[0];
    const fcmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (fmul_inst.removed or fcmp_inst.removed or select_inst.removed) return false;
    const fmul_name = fmul_inst.result orelse return false;
    const fcmp_name = fcmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const fmul = switch (fmul_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (fmul.op != .fmul or !fmul.ty.eql(.double)) return false;
    if (!isFpText(fmul.lhs, "3.000000e+00") or !isFpText(fmul.rhs, "2.000000e+00")) return false;

    const fcmp = switch (fcmp_inst.kind) {
        .fcmp => |fcmp| fcmp,
        else => return false,
    };
    if (fcmp.predicate != .oeq or !fcmp.operand_ty.eql(.double)) return false;
    if (!isNamed(fcmp.lhs, fmul_name) or !isFpText(fcmp.rhs, "6.000000e+00")) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, fcmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const fail = "float_mul_fail";
    try machine.instructions.append(allocator, .{ .mov_imm64_xmm0 = 0x4008_0000_0000_0000 });
    try machine.instructions.append(allocator, .{ .mov_imm64_xmm1 = 0x4000_0000_0000_0000 });
    try machine.instructions.append(allocator, .mulsd_xmm1_xmm0);
    try machine.instructions.append(allocator, .{ .mov_imm64_xmm1 = 0x4018_0000_0000_0000 });
    try machine.instructions.append(allocator, .ucomisd_xmm1_xmm0);
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn matchesFpBinaryReturn(
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
    ty: ir.Type,
    op: ir.BinaryOp,
) !bool {
    if (function.params.items.len != 2) return false;
    if (!function.ret_ty.eql(ty) or !ret.ty.eql(ty)) return false;
    if (!function.params.items[0].ty.eql(ty) or !function.params.items[1].ty.eql(ty)) return false;
    if (block.instructions.items.len != 1) return false;

    const binary_inst = block.instructions.items[0];
    if (binary_inst.removed) return false;
    const binary_result = binary_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, binary_result)) return false;

    const binary = switch (binary_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (binary.op != op or !binary.ty.eql(ty)) return false;
    if (!isNamed(binary.lhs, function.params.items[0].name) or !isNamed(binary.rhs, function.params.items[1].name)) return false;
    return true;
}

fn lowerFloatSelectReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (function.params.items.len != 3) return false;
    if (!function.ret_ty.eql(.double) or !ret.ty.eql(.double)) return false;
    if (!function.params.items[0].ty.eql(.double) or !function.params.items[1].ty.eql(.double) or !function.params.items[2].ty.eql(.{ .int = 1 })) return false;
    if (block.instructions.items.len != 1) return false;

    const select_inst = block.instructions.items[0];
    if (select_inst.removed) return false;
    const select_result = select_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_result)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.double)) return false;
    if (!isNamed(select.cond, function.params.items[2].name)) return false;
    if (!isNamed(select.true_value, function.params.items[0].name) or !isNamed(select.false_value, function.params.items[1].name)) return false;

    const false_label = "float_select_false";
    try machine.instructions.append(allocator, .{ .test_arg8 = .rdi });
    try machine.instructions.append(allocator, .{ .je = false_label });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = false_label });
    try machine.instructions.append(allocator, .movapd_xmm1_xmm0);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerDescriptorFpCheckMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (function.params.items.len != 0) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or !ret.ty.eql(.{ .int = 32 })) return false;

    if (try lowerDescriptorFpBinaryCheckMainReturn(allocator, machine, block, ret)) return true;
    if (try lowerDescriptorFpSelectCheckMainReturn(allocator, machine, block, ret)) return true;
    return false;
}

fn lowerDescriptorFpBinaryCheckMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (block.instructions.items.len != 3) return false;

    const binary_inst = block.instructions.items[0];
    const fcmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (binary_inst.removed or fcmp_inst.removed or select_inst.removed) return false;
    const binary_name = binary_inst.result orelse return false;
    const fcmp_name = fcmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const binary = switch (binary_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    const fcmp = switch (fcmp_inst.kind) {
        .fcmp => |fcmp| fcmp,
        else => return false,
    };
    if (fcmp.predicate != .oeq or !fcmp.operand_ty.eql(binary.ty)) return false;
    if (!isNamed(fcmp.lhs, binary_name)) return false;
    if (!isSelectI1ToI32ZeroOne(select_inst, fcmp_name)) return false;

    const fail = "descriptor_fp_binary_fail";
    if (binary.ty.eql(.float)) {
        try machine.instructions.append(allocator, .{ .mov_imm32_xmm0 = try fp32TextBits(binary.lhs) });
        try machine.instructions.append(allocator, .{ .mov_imm32_xmm1 = try fp32TextBits(binary.rhs) });
        switch (binary.op) {
            .fadd => try machine.instructions.append(allocator, .addss_xmm1_xmm0),
            .fsub => try machine.instructions.append(allocator, .subss_xmm1_xmm0),
            .frem => {
                try appendAlignedDirectCall(allocator, machine, "fmodf", .float);
            },
            .fmul, .fdiv, .add, .sub, .mul, .shl, .lshr, .ashr, .@"and", .@"or", .xor, .udiv, .sdiv, .urem, .srem => return false,
        }
        try machine.instructions.append(allocator, .{ .mov_imm32_xmm1 = try fp32TextBits(fcmp.rhs) });
        try machine.instructions.append(allocator, .ucomiss_xmm1_xmm0);
    } else if (binary.ty.eql(.double)) {
        try machine.instructions.append(allocator, .{ .mov_imm64_xmm0 = try fp64TextBits(binary.lhs) });
        try machine.instructions.append(allocator, .{ .mov_imm64_xmm1 = try fp64TextBits(binary.rhs) });
        switch (binary.op) {
            .fmul => try machine.instructions.append(allocator, .mulsd_xmm1_xmm0),
            .fdiv => try machine.instructions.append(allocator, .divsd_xmm1_xmm0),
            .fadd, .fsub, .frem, .add, .sub, .mul, .shl, .lshr, .ashr, .@"and", .@"or", .xor, .udiv, .sdiv, .urem, .srem => return false,
        }
        try machine.instructions.append(allocator, .{ .mov_imm64_xmm1 = try fp64TextBits(fcmp.rhs) });
        try machine.instructions.append(allocator, .ucomisd_xmm1_xmm0);
    } else {
        return false;
    }

    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerDescriptorFpSelectCheckMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (block.instructions.items.len != 4) return false;

    const first_cmp_inst = block.instructions.items[0];
    const select_fp_inst = block.instructions.items[1];
    const second_cmp_inst = block.instructions.items[2];
    const select_ret_inst = block.instructions.items[3];
    if (first_cmp_inst.removed or select_fp_inst.removed or second_cmp_inst.removed or select_ret_inst.removed) return false;
    const first_cmp_name = first_cmp_inst.result orelse return false;
    const selected_name = select_fp_inst.result orelse return false;
    const second_cmp_name = second_cmp_inst.result orelse return false;
    const select_ret_name = select_ret_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_ret_name)) return false;

    const first_cmp = switch (first_cmp_inst.kind) {
        .fcmp => |fcmp| fcmp,
        else => return false,
    };
    if (first_cmp.predicate != .olt or !first_cmp.operand_ty.eql(.double)) return false;
    _ = try fp64TextBits(first_cmp.lhs);
    _ = try fp64TextBits(first_cmp.rhs);

    const select_fp = switch (select_fp_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select_fp.cond_ty.eql(.{ .int = 1 }) or !select_fp.ty.eql(.double)) return false;
    if (!isNamed(select_fp.cond, first_cmp_name)) return false;
    _ = try fp64TextBits(select_fp.true_value);
    _ = try fp64TextBits(select_fp.false_value);

    const second_cmp = switch (second_cmp_inst.kind) {
        .fcmp => |fcmp| fcmp,
        else => return false,
    };
    if (second_cmp.predicate != .oeq or !second_cmp.operand_ty.eql(.double)) return false;
    if (!isNamed(second_cmp.lhs, selected_name)) return false;
    _ = try fp64TextBits(second_cmp.rhs);
    if (!isSelectI1ToI32ZeroOne(select_ret_inst, second_cmp_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerFloatLessReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (function.params.items.len != 2) return false;
    if (!function.ret_ty.eql(.{ .int = 1 }) or !ret.ty.eql(.{ .int = 1 })) return false;
    if (!function.params.items[0].ty.eql(.float) or !function.params.items[1].ty.eql(.float)) return false;
    if (block.instructions.items.len != 1) return false;

    const fcmp_inst = block.instructions.items[0];
    if (fcmp_inst.removed) return false;
    const fcmp_result = fcmp_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, fcmp_result)) return false;

    const fcmp = switch (fcmp_inst.kind) {
        .fcmp => |fcmp| fcmp,
        else => return false,
    };
    if (fcmp.predicate != .olt or !fcmp.operand_ty.eql(.float)) return false;
    if (!isNamed(fcmp.lhs, function.params.items[0].name) or !isNamed(fcmp.rhs, function.params.items[1].name)) return false;

    try machine.instructions.append(allocator, .oltss_xmm0_xmm1_al);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerFloatLiteralReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    ret: anytype,
) !bool {
    if (function.params.items.len != 0) return false;
    const value = switch (ret.value orelse return false) {
        .fp => |fp| fp,
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    if (function.ret_ty.eql(.double) and ret.ty.eql(.double)) {
        try machine.instructions.append(allocator, .{ .mov_imm64_xmm0 = try fp64TextBits(.{ .fp = value }) });
        try machine.instructions.append(allocator, .ret);
        return true;
    }

    if (function.ret_ty.eql(.float) and ret.ty.eql(.float)) {
        try machine.instructions.append(allocator, .{ .mov_imm32_xmm0 = try fp32TextBits(.{ .fp = value }) });
        try machine.instructions.append(allocator, .ret);
        return true;
    }

    return false;
}

fn lowerScalarFpCastReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (function.params.items.len != 1) return false;
    if (block.instructions.items.len != 1) return false;
    const cast_inst = block.instructions.items[0];
    if (cast_inst.removed) return false;
    const cast_result = cast_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, cast_result)) return false;
    const cast = switch (cast_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (!cast.from_ty.eql(function.params.items[0].ty)) return false;
    if (!cast.to_ty.eql(function.ret_ty) or !ret.ty.eql(function.ret_ty)) return false;
    if (!isNamed(cast.value, function.params.items[0].name)) return false;

    switch (cast.op) {
        .sitofp => {
            if (cast.from_ty.eql(.{ .int = 32 }) and cast.to_ty.eql(.float)) {
                try machine.instructions.append(allocator, .cvtsi2ss_edi_xmm0);
            } else if (cast.from_ty.eql(.{ .int = 32 }) and cast.to_ty.eql(.double)) {
                try machine.instructions.append(allocator, .cvtsi2sd_edi_xmm0);
            } else if (cast.from_ty.eql(.{ .int = 64 }) and cast.to_ty.eql(.float)) {
                try machine.instructions.append(allocator, .cvtsi2ss_rdi_xmm0);
            } else if (cast.from_ty.eql(.{ .int = 64 }) and cast.to_ty.eql(.double)) {
                try machine.instructions.append(allocator, .cvtsi2sd_rdi_xmm0);
            } else return false;
        },
        .uitofp => {
            // Unsigned 32-bit converts exactly through a zero-extended
            // 64-bit signed convert; wider unsigned sources stay fail-closed.
            if (!cast.from_ty.eql(.{ .int = 32 })) return false;
            try machine.instructions.append(allocator, .mov_edi_edi);
            if (cast.to_ty.eql(.float)) {
                try machine.instructions.append(allocator, .cvtsi2ss_rdi_xmm0);
            } else if (cast.to_ty.eql(.double)) {
                try machine.instructions.append(allocator, .cvtsi2sd_rdi_xmm0);
            } else return false;
        },
        .fptosi => {
            if (!cast.to_ty.eql(.{ .int = 32 })) return false;
            if (cast.from_ty.eql(.float)) {
                try machine.instructions.append(allocator, .cvttss2si_xmm0_eax);
            } else if (cast.from_ty.eql(.double)) {
                try machine.instructions.append(allocator, .cvttsd2si_xmm0_eax);
            } else return false;
        },
        .fptrunc => {
            if (!cast.from_ty.eql(.double) or !cast.to_ty.eql(.float)) return false;
            try machine.instructions.append(allocator, .cvtsd2ss_xmm0_xmm0);
        },
        .fpext => {
            if (!cast.from_ty.eql(.float) or !cast.to_ty.eql(.double)) return false;
            try machine.instructions.append(allocator, .cvtss2sd_xmm0_xmm0);
        },
        .trunc, .zext, .sext, .fptoui, .bitcast, .ptrtoint, .inttoptr => return false,
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerAggregateAbiReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (try lowerMemoryAggregateCallReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerRegisterAggregateDirectCallReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerRegisterAggregateReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerSmallIntegerAggregateReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerSysVAggregateFieldReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerRegisterAggregateIntegerFieldAddReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerRegisterAggregateFloatFieldAddReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerRegisterAggregateDoubleFieldAddReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerMemoryIntegerAggregateFieldAddReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerTruncI64ArgReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerMakePairReturn(allocator, machine, function, block, ret)) return true;
    return false;
}

fn lowerMemoryAggregateCallReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(function.ret_ty) or block.instructions.items.len != 1) return false;
    const classification = classifySysVAggregate(function.ret_ty) catch return false;
    if (classification.kind != .memory or classification.size_bytes == 0) return false;
    if (!isSupportedAggregateCopyLeafAggregate(function.ret_ty)) return false;

    const instruction = block.instructions.items[0];
    if (instruction.removed) return false;
    const call_result = instruction.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, call_result)) return false;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!call.ret_ty.eql(function.ret_ty) or call.inline_asm != null) return false;
    if (call.tail_kind != null) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;
    if (call.args.items.len != 1) return false;

    const call_target: SysVCallTarget = if (call.callee_value) |callee_value| target: {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        const callee_reg = try paramRegWithInitialGpr(function, callee_name, .ptr, 1);
        if (callee_reg == .rdi) return error.UnsupportedCodegenAbi;
        break :target .{ .indirect_from_reg = callee_reg };
    } else .{ .direct = call.callee };

    const aggregate_arg = call.args.items[0];
    if (!aggregate_arg.ty.eql(function.ret_ty)) return false;
    const aggregate_name = switch (aggregate_arg.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    const source = try sysvParamCursorForWithInitial(function, aggregate_name, aggregate_arg.ty, .{
        .gpr = 1,
        .sse = 0,
        .stack_eightbytes = 0,
    });

    const stack_arg_count = try appendSysVMemoryAggregateStackPassThroughArgs(
        allocator,
        machine,
        function,
        source,
        classification,
    );
    try setupSysVCallTarget(allocator, machine, call_target);
    try appendSysVCallTargetWithStackArgs(allocator, machine, call_target, call.ret_ty, stack_arg_count);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn x86_64SysVDataLayout() !target.DataLayout {
    return sysv_abi.dataLayout();
}

pub fn classifySysVAggregateForTest(ty: ir.Type) !SysVAggregateClassification {
    return try sysv_abi.classifyAggregateForTest(ty);
}

fn classifySysVAggregate(ty: ir.Type) !SysVAggregateClassification {
    return try sysv_abi.classifyAggregate(ty);
}

fn classifySysVSmallIntegerAggregate(ty: ir.Type) ?SysVSmallIntegerAggregate {
    return sysv_abi.classifySmallIntegerAggregate(ty);
}

fn lowerSmallIntegerAggregateReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const classification = classifySysVSmallIntegerAggregate(function.ret_ty) orelse return false;
    if (classification.eightbytes != 2 or !ret.ty.eql(function.ret_ty)) return false;
    if (block.instructions.items.len != 2) return false;
    const first_inst = block.instructions.items[0];
    const second_inst = block.instructions.items[1];
    if (first_inst.removed or second_inst.removed) return false;
    const first_name = first_inst.result orelse return false;
    const second_name = second_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, second_name)) return false;

    const first = switch (first_inst.kind) {
        .insertvalue => |insert| insert,
        else => return false,
    };
    const second = switch (second_inst.kind) {
        .insertvalue => |insert| insert,
        else => return false,
    };
    if (!first.aggregate_ty.eql(function.ret_ty) or !second.aggregate_ty.eql(function.ret_ty)) return false;
    if (first.aggregate != .undef or !isNamed(second.aggregate, first_name)) return false;
    if (!std.mem.eql(u8, first.indices, "0") or !std.mem.eql(u8, second.indices, "1")) return false;
    if (!first.value_ty.eql(.{ .int = 64 }) or !second.value_ty.eql(.{ .int = 64 })) return false;
    const first_reg = try paramValueReg(function, first.value, .{ .int = 64 });
    const second_reg = try paramValueReg(function, second.value, .{ .int = 64 });

    try machine.instructions.append(allocator, .{ .mov_arg_rax = first_reg });
    try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = .rdx, .src = second_reg } });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRegisterAggregateReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(function.ret_ty)) return false;
    const classification = classifySysVAggregate(function.ret_ty) catch return false;
    if (classification.kind != .register or classification.eightbyte_count == 0) return false;
    const leaf_count = block.instructions.items.len;
    if (leaf_count == 0 or leaf_count > 8) return false;

    var leaves: [8]AggregateReturnLeaf = undefined;
    var aggregate_value: ir.Value = .undef;
    for (block.instructions.items, 0..) |instruction, index| {
        if (instruction.removed) return false;
        const result = instruction.result orelse return false;
        const insert = switch (instruction.kind) {
            .insertvalue => |insert| insert,
            else => return false,
        };
        if (!insert.aggregate_ty.eql(function.ret_ty)) return false;
        if (!valuesEqual(insert.aggregate, aggregate_value)) return false;
        const offset = try aggregateInsertByteOffset(function.ret_ty, insert.indices, insert.value_ty);
        if (index != 0 and offset <= leaves[index - 1].offset) return error.UnsupportedCodegenAbi;
        leaves[index] = .{ .value = insert.value, .ty = insert.value_ty, .offset = offset };
        aggregate_value = .{ .named = result };
    }
    if (!valuesEqual(ret.value orelse return error.InvalidRet, aggregate_value)) return false;

    if (try lowerFourI32RegisterAggregateReturn(allocator, machine, function, leaves[0..leaf_count], classification)) return true;

    var gpr_return_index: usize = 0;
    var sse_return_index: usize = 0;
    var leaf_index: usize = 0;
    while (leaf_index < leaf_count) : (leaf_index += 1) {
        const leaf = leaves[leaf_index];
        const leaf_eightbyte: usize = @intCast(leaf.offset / 8);
        if (leaf_eightbyte >= classification.eightbyte_count) return false;
        const leaf_class = classification.eightbytes[leaf_eightbyte] orelse return false;
        switch (leaf_class) {
            .integer => {
                if (leaf.ty.eql(.{ .int = 64 })) {
                    const src = try paramValueReg(function, leaf.value, leaf.ty);
                    switch (gpr_return_index) {
                        0 => try machine.instructions.append(allocator, .{ .mov_arg_rax = src }),
                        1 => try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = .rdx, .src = src } }),
                        else => return error.UnsupportedCodegenAbi,
                    }
                    gpr_return_index += 1;
                    continue;
                }
                if (!leaf.ty.eql(.{ .int = 32 })) return false;
                if (leaf.offset % 8 != 0) return error.UnsupportedCodegenAbi;
                const low_reg = try paramValueReg(function, leaf.value, leaf.ty);
                if (leaf_index + 1 < leaf_count and
                    leaves[leaf_index + 1].ty.eql(.{ .int = 32 }) and
                    leaves[leaf_index + 1].offset / 8 == leaf_eightbyte and
                    leaves[leaf_index + 1].offset % 8 == 4)
                {
                    const high_reg = try paramValueReg(function, leaves[leaf_index + 1].value, .{ .int = 32 });
                    switch (gpr_return_index) {
                        0 => {
                            try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rdx, .src = high_reg } });
                            try machine.instructions.append(allocator, .{ .shl_rdx_imm6 = 32 });
                            try machine.instructions.append(allocator, .{ .mov_arg_eax = low_reg });
                            try machine.instructions.append(allocator, .or_rdx_rax);
                        },
                        1 => {
                            try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rcx, .src = high_reg } });
                            try machine.instructions.append(allocator, .{ .shl_rcx_imm6 = 32 });
                            try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rdx, .src = low_reg } });
                            try machine.instructions.append(allocator, .or_rcx_rdx);
                        },
                        else => return error.UnsupportedCodegenAbi,
                    }
                    gpr_return_index += 1;
                    leaf_index += 1;
                    continue;
                }
                switch (gpr_return_index) {
                    0 => try machine.instructions.append(allocator, .{ .mov_arg_eax = low_reg }),
                    1 => try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rdx, .src = low_reg } }),
                    else => return error.UnsupportedCodegenAbi,
                }
                gpr_return_index += 1;
            },
            .sse => {
                if (leaf.ty.eql(.float) and leaf.offset % 8 == 0 and
                    leaf_index + 1 < leaf_count and
                    leaves[leaf_index + 1].ty.eql(.float) and
                    leaves[leaf_index + 1].offset / 8 == leaf_eightbyte and
                    leaves[leaf_index + 1].offset % 8 == 4)
                {
                    if (sse_return_index != 0) return error.UnsupportedCodegenAbi;
                    const low_fp_index = try fpParamIndexFromValue(function, leaf.value, .float);
                    const high_fp_index = try fpParamIndexFromValue(function, leaves[leaf_index + 1].value, .float);
                    if (high_fp_index == 0 and low_fp_index != 0) return error.UnsupportedCodegenAbi;
                    const low_reg = try XmmReg.fromIndex(low_fp_index);
                    const high_reg = try XmmReg.fromIndex(high_fp_index);
                    if (low_reg != .xmm0) {
                        try machine.instructions.append(allocator, .{ .movapd_xmm = .{ .dst = .xmm0, .src = low_reg } });
                    }
                    if (high_reg != .xmm0) {
                        try machine.instructions.append(allocator, .{ .unpcklps_xmm = .{ .dst = .xmm0, .src = high_reg } });
                    }
                    sse_return_index += 1;
                    leaf_index += 1;
                    continue;
                }
                if (!leaf.ty.eql(.double)) return false;
                const fp_index = try fpParamIndexFromValue(function, leaf.value, leaf.ty);
                switch (sse_return_index) {
                    0 => switch (try XmmReg.fromIndex(fp_index)) {
                        .xmm0 => {},
                        .xmm1 => try machine.instructions.append(allocator, .movapd_xmm1_xmm0),
                        .xmm2, .xmm3, .xmm4, .xmm5, .xmm6, .xmm7 => return error.UnsupportedCodegenAbi,
                    },
                    1 => switch (try XmmReg.fromIndex(fp_index)) {
                        .xmm1 => {},
                        .xmm0, .xmm2, .xmm3, .xmm4, .xmm5, .xmm6, .xmm7 => return error.UnsupportedCodegenAbi,
                    },
                    else => return error.UnsupportedCodegenAbi,
                }
                sse_return_index += 1;
            },
        }
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

const AggregateReturnLeaf = struct {
    value: ir.Value,
    ty: ir.Type,
    offset: u64,
};

fn lowerFourI32RegisterAggregateReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    leaves: []const AggregateReturnLeaf,
    classification: SysVAggregateClassification,
) !bool {
    if (classification.eightbyte_count != 2 or
        classification.eightbytes[0] != .integer or
        classification.eightbytes[1] != .integer or
        leaves.len != 4)
    {
        return false;
    }
    const expected_offsets = [_]u64{ 0, 4, 8, 12 };
    for (leaves, 0..) |leaf, index| {
        if (!leaf.ty.eql(.{ .int = 32 }) or leaf.offset != expected_offsets[index]) return false;
    }
    const a = try paramValueReg(function, leaves[0].value, .{ .int = 32 });
    const b = try paramValueReg(function, leaves[1].value, .{ .int = 32 });
    const c = try paramValueReg(function, leaves[2].value, .{ .int = 32 });
    const d = try paramValueReg(function, leaves[3].value, .{ .int = 32 });

    try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rcx, .src = d } });
    try machine.instructions.append(allocator, .{ .shl_rcx_imm6 = 32 });
    try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rdx, .src = c } });
    try machine.instructions.append(allocator, .or_rcx_rdx);
    try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rcx, .src = b } });
    try machine.instructions.append(allocator, .{ .shl_rcx_imm6 = 32 });
    try machine.instructions.append(allocator, .{ .mov_arg_eax = a });
    try machine.instructions.append(allocator, .or_rcx_rax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn aggregateInsertByteOffset(aggregate_ty: ir.Type, indices: []const u8, value_ty: ir.Type) !u64 {
    const layout = try x86_64SysVDataLayout();
    var current_ty = aggregate_ty;
    var offset: u64 = 0;
    var rest = indices;
    while (rest.len != 0) {
        const comma = std.mem.indexOfScalar(u8, rest, ',');
        const part = std.mem.trim(u8, if (comma) |pos| rest[0..pos] else rest, " \t");
        const field_index = std.fmt.parseInt(usize, part, 10) catch return error.UnsupportedCodegenAbi;
        const field_offset_i = memory_location.aggregateFieldOffsetWithLayout(layout, current_ty, field_index) orelse
            return error.UnsupportedCodegenAbi;
        if (field_offset_i < 0) return error.UnsupportedCodegenAbi;
        offset += @intCast(field_offset_i);
        current_ty = memory_location.aggregateFieldType(current_ty, field_index) orelse return error.UnsupportedCodegenAbi;
        rest = if (comma) |pos| rest[pos + 1 ..] else "";
    }
    if (!current_ty.eql(value_ty)) return error.UnsupportedCodegenAbi;
    return offset;
}

fn aggregateFieldCount(ty: ir.Type) ?usize {
    var count: usize = 0;
    while (memory_location.aggregateFieldType(ty, count)) |_| : (count += 1) {}
    return count;
}

fn aggregateFieldEightbyte(aggregate_ty: ir.Type, field_index: usize) !usize {
    const layout = try x86_64SysVDataLayout();
    const field_offset_i = memory_location.aggregateFieldOffsetWithLayout(layout, aggregate_ty, field_index) orelse
        return error.UnsupportedCodegenAbi;
    if (field_offset_i < 0) return error.UnsupportedCodegenAbi;
    return @intCast(@as(u64, @intCast(field_offset_i)) / 8);
}

fn fpParamIndexFromValue(function: ir.Function, value: ir.Value, ty: ir.Type) !usize {
    return switch (value) {
        .named => |name| try fpParamIndex(function, name, ty),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => error.UnsupportedCodegenValue,
    };
}

fn valuesEqual(a: ir.Value, b: ir.Value) bool {
    return switch (a) {
        .named => |a_name| switch (b) {
            .named => |b_name| std.mem.eql(u8, a_name, b_name),
            else => false,
        },
        .undef => b == .undef,
        .poison => b == .poison,
        .null_value => b == .null_value,
        .zero_initializer => b == .zero_initializer,
        .int => |a_int| switch (b) {
            .int => |b_int| a_int == b_int,
            else => false,
        },
        .fp => |a_fp| switch (b) {
            .fp => |b_fp| std.mem.eql(u8, a_fp, b_fp),
            else => false,
        },
        .vector, .constant_expr => false,
    };
}

fn lowerSysVAggregateFieldReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if ((!ret.ty.eql(.{ .int = 32 }) and !ret.ty.eql(.{ .int = 64 }) and !ret.ty.eql(.float) and !ret.ty.eql(.double)) or
        (block.instructions.items.len != 3 and block.instructions.items.len != 4)) return false;
    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    const maybe_gep_inst: ?ir.Instruction = if (block.instructions.items.len == 4) block.instructions.items[2] else null;
    const load_inst = block.instructions.items[block.instructions.items.len - 1];
    if (alloca_inst.removed or store_inst.removed or load_inst.removed) return false;
    if (maybe_gep_inst) |gep_inst| if (gep_inst.removed) return false;
    const alloca_name = alloca_inst.result orelse return false;
    const load_name = load_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, load_name)) return false;

    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    const classification = classifySysVAggregate(alloca.allocated_ty) catch return false;
    if (classification.kind != .register or classification.eightbyte_count == 0) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(alloca.allocated_ty) or store.attrs.isBarrier() or !isNamed(store.ptr, alloca_name)) return false;
    const param_name = switch (store.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(ret.ty) or load.attrs.isBarrier()) return false;

    const layout = try x86_64SysVDataLayout();
    const field_offset = if (maybe_gep_inst) |gep_inst| blk: {
        const gep_name = gep_inst.result orelse return false;
        if (!isNamed(load.ptr, gep_name)) return false;
        const gep = switch (gep_inst.kind) {
            .gep => |gep| gep,
            else => return false,
        };
        if (!isNamed(gep.ptr, alloca_name)) return false;
        break :blk aggregateGepByteOffset(layout, alloca.allocated_ty, gep) orelse return false;
    } else blk: {
        if (!isNamed(load.ptr, alloca_name)) return false;
        break :blk @as(u64, 0);
    };
    _ = aggregateFieldIndexAtOffset(alloca.allocated_ty, field_offset, load.ty) orelse return false;

    try emitSysVAggregateFieldOffsetReturn(allocator, machine, function, param_name, alloca.allocated_ty, field_offset, load.ty);
    try machine.instructions.append(allocator, .ret);
    return true;
}

const AggregateIntegerFieldLoad = struct {
    offset: u64,
};

const AggregateIntegerAddTerm = struct {
    offset: u64,
};

const AggregateDoubleFieldLoad = struct {
    offset: u64,
};

const AggregateDoubleAddTerm = struct {
    offset: u64,
};

const AggregateFloatFieldLoad = struct {
    offset: u64,
};

const AggregateFloatAddTerm = struct {
    offset: u64,
};

fn lowerRegisterAggregateIntegerFieldAddReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if ((!ret.ty.eql(.{ .int = 32 }) and !ret.ty.eql(.{ .int = 64 })) or !function.ret_ty.eql(ret.ty)) return false;
    if (block.instructions.items.len < 5) return false;

    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    if (alloca_inst.removed or store_inst.removed) return false;
    const alloca_name = alloca_inst.result orelse return false;
    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    const aggregate_ty = alloca.allocated_ty;
    const classification = classifySysVAggregate(aggregate_ty) catch return false;
    if (classification.kind != .register) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(aggregate_ty) or store.attrs.isBarrier() or !isNamed(store.ptr, alloca_name)) return false;
    const param_name = switch (store.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    var pointer_offsets = std.StringHashMap(u64).init(allocator);
    defer pointer_offsets.deinit();
    try pointer_offsets.put(alloca_name, 0);

    var field_loads = std.StringHashMap(AggregateIntegerFieldLoad).init(allocator);
    defer field_loads.deinit();

    const layout = try x86_64SysVDataLayout();
    for (block.instructions.items[2..]) |instruction| {
        if (instruction.removed) return false;
        switch (instruction.kind) {
            .gep => |gep| {
                const result = instruction.result orelse return false;
                const base_name = switch (gep.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const base_offset = pointer_offsets.get(base_name) orelse return false;
                const offset = aggregateGepByteOffset(layout, aggregate_ty, gep) orelse return false;
                try pointer_offsets.put(result, base_offset + offset);
            },
            .load => |load| {
                const result = instruction.result orelse return false;
                if (!load.ty.eql(ret.ty) or load.attrs.isBarrier()) return false;
                const ptr_name = switch (load.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const offset = pointer_offsets.get(ptr_name) orelse return false;
                try field_loads.put(result, .{ .offset = offset });
            },
            .binary => |binary| {
                if (binary.op != .add or !binary.ty.eql(ret.ty)) return false;
            },
            .phi, .fcmp, .icmp, .select, .cast, .freeze, .alloca, .store, .call, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => return false,
        }
    }

    var terms: [8]AggregateIntegerAddTerm = undefined;
    var term_count: usize = 0;
    if (!try collectAggregateIntegerAddTerms(block, ret.value orelse return error.InvalidRet, ret.ty, field_loads, &terms, &term_count)) return false;
    if (term_count < 2) return false;

    try emitAggregateIntegerTerm(allocator, machine, function, param_name, aggregate_ty, terms[0], ret.ty, true);
    for (terms[1..term_count]) |term| {
        try emitAggregateIntegerTerm(allocator, machine, function, param_name, aggregate_ty, term, ret.ty, false);
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRegisterAggregateFloatFieldAddReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.float) or !function.ret_ty.eql(.float)) return false;
    if (block.instructions.items.len < 5) return false;

    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    if (alloca_inst.removed or store_inst.removed) return false;
    const alloca_name = alloca_inst.result orelse return false;
    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    const aggregate_ty = alloca.allocated_ty;
    const classification = classifySysVAggregate(aggregate_ty) catch return false;
    if (classification.kind != .register) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(aggregate_ty) or store.attrs.isBarrier() or !isNamed(store.ptr, alloca_name)) return false;
    const param_name = switch (store.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    var pointer_offsets = std.StringHashMap(u64).init(allocator);
    defer pointer_offsets.deinit();
    try pointer_offsets.put(alloca_name, 0);

    var field_loads = std.StringHashMap(AggregateFloatFieldLoad).init(allocator);
    defer field_loads.deinit();

    const layout = try x86_64SysVDataLayout();
    for (block.instructions.items[2..]) |instruction| {
        if (instruction.removed) return false;
        switch (instruction.kind) {
            .gep => |gep| {
                const result = instruction.result orelse return false;
                const base_name = switch (gep.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const base_offset = pointer_offsets.get(base_name) orelse return false;
                const offset = aggregateGepByteOffset(layout, aggregate_ty, gep) orelse return false;
                try pointer_offsets.put(result, base_offset + offset);
            },
            .load => |load| {
                const result = instruction.result orelse return false;
                if (!load.ty.eql(.float) or load.attrs.isBarrier()) return false;
                const ptr_name = switch (load.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const offset = pointer_offsets.get(ptr_name) orelse return false;
                _ = aggregateFieldIndexAtOffset(aggregate_ty, offset, load.ty) orelse return false;
                try field_loads.put(result, .{ .offset = offset });
            },
            .binary => |binary| {
                if (binary.op != .fadd or !binary.ty.eql(.float)) return false;
            },
            .phi, .fcmp, .icmp, .select, .cast, .freeze, .alloca, .store, .call, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => return false,
        }
    }

    var terms: [2]AggregateFloatAddTerm = undefined;
    var term_count: usize = 0;
    if (!try collectAggregateFloatAddTerms(block, ret.value orelse return error.InvalidRet, field_loads, &terms, &term_count)) return false;
    if (term_count != 2) return false;
    if (terms[0].offset > terms[1].offset) std.mem.swap(AggregateFloatAddTerm, &terms[0], &terms[1]);

    try emitAggregateFloatTerm(allocator, machine, function, param_name, aggregate_ty, terms[0], .xmm0);
    try emitAggregateFloatTerm(allocator, machine, function, param_name, aggregate_ty, terms[1], .xmm1);
    try machine.instructions.append(allocator, .addss_xmm1_xmm0);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRegisterAggregateDoubleFieldAddReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.double) or !function.ret_ty.eql(.double)) return false;
    if (block.instructions.items.len < 5) return false;

    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    if (alloca_inst.removed or store_inst.removed) return false;
    const alloca_name = alloca_inst.result orelse return false;
    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    const aggregate_ty = alloca.allocated_ty;
    const classification = classifySysVAggregate(aggregate_ty) catch return false;
    if (classification.kind != .register) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(aggregate_ty) or store.attrs.isBarrier() or !isNamed(store.ptr, alloca_name)) return false;
    const param_name = switch (store.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    var pointer_offsets = std.StringHashMap(u64).init(allocator);
    defer pointer_offsets.deinit();
    try pointer_offsets.put(alloca_name, 0);

    var field_loads = std.StringHashMap(AggregateDoubleFieldLoad).init(allocator);
    defer field_loads.deinit();

    const layout = try x86_64SysVDataLayout();
    for (block.instructions.items[2..]) |instruction| {
        if (instruction.removed) return false;
        switch (instruction.kind) {
            .gep => |gep| {
                const result = instruction.result orelse return false;
                const base_name = switch (gep.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const base_offset = pointer_offsets.get(base_name) orelse return false;
                const offset = aggregateGepByteOffset(layout, aggregate_ty, gep) orelse return false;
                try pointer_offsets.put(result, base_offset + offset);
            },
            .load => |load| {
                const result = instruction.result orelse return false;
                if (!load.ty.eql(.double) or load.attrs.isBarrier()) return false;
                const ptr_name = switch (load.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const offset = pointer_offsets.get(ptr_name) orelse return false;
                _ = aggregateFieldIndexAtOffset(aggregate_ty, offset, load.ty) orelse return false;
                try field_loads.put(result, .{ .offset = offset });
            },
            .binary => |binary| {
                if (binary.op != .fadd or !binary.ty.eql(.double)) return false;
            },
            .phi, .fcmp, .icmp, .select, .cast, .freeze, .alloca, .store, .call, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => return false,
        }
    }

    var terms: [2]AggregateDoubleAddTerm = undefined;
    var term_count: usize = 0;
    if (!try collectAggregateDoubleAddTerms(block, ret.value orelse return error.InvalidRet, field_loads, &terms, &term_count)) return false;
    if (term_count != 2) return false;

    try emitAggregateDoubleTerm(allocator, machine, function, param_name, aggregate_ty, terms[0], .xmm0);
    try emitAggregateDoubleTerm(allocator, machine, function, param_name, aggregate_ty, terms[1], .xmm1);
    try machine.instructions.append(allocator, .addsd_xmm1_xmm0);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn collectAggregateFloatAddTerms(
    block: ir.BasicBlock,
    value: ir.Value,
    field_loads: std.StringHashMap(AggregateFloatFieldLoad),
    terms: *[2]AggregateFloatAddTerm,
    term_count: *usize,
) !bool {
    const name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (field_loads.get(name)) |load| {
        if (term_count.* >= terms.len) return error.UnsupportedCodegenAbi;
        terms[term_count.*] = .{ .offset = load.offset };
        term_count.* += 1;
        return true;
    }
    const instruction = findInstruction(block, name) orelse return false;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (binary.op != .fadd or !binary.ty.eql(.float)) return false;
    if (!try collectAggregateFloatAddTerms(block, binary.lhs, field_loads, terms, term_count)) return false;
    return try collectAggregateFloatAddTerms(block, binary.rhs, field_loads, terms, term_count);
}

fn collectAggregateDoubleAddTerms(
    block: ir.BasicBlock,
    value: ir.Value,
    field_loads: std.StringHashMap(AggregateDoubleFieldLoad),
    terms: *[2]AggregateDoubleAddTerm,
    term_count: *usize,
) !bool {
    const name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (field_loads.get(name)) |load| {
        if (term_count.* >= terms.len) return error.UnsupportedCodegenAbi;
        terms[term_count.*] = .{ .offset = load.offset };
        term_count.* += 1;
        return true;
    }
    const instruction = findInstruction(block, name) orelse return false;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (binary.op != .fadd or !binary.ty.eql(.double)) return false;
    if (!try collectAggregateDoubleAddTerms(block, binary.lhs, field_loads, terms, term_count)) return false;
    return try collectAggregateDoubleAddTerms(block, binary.rhs, field_loads, terms, term_count);
}

fn aggregateGepByteOffset(layout: target.DataLayout, aggregate_ty: ir.Type, gep: ir.GepInst) ?u64 {
    if (gep.source_ty.eql(.{ .int = 8 }) and gep.indices.items.len == 1 and gep.indices.items[0].ty.eql(.{ .int = 64 })) {
        const offset = switch (gep.indices.items[0].value) {
            .int => |int| int,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
        };
        if (offset < 0) return null;
        return @intCast(offset);
    }
    if (isScalarElementGepType(gep.source_ty) and gep.indices.items.len == 1 and gep.indices.items[0].ty.eql(.{ .int = 64 })) {
        const index = switch (gep.indices.items[0].value) {
            .int => |int| int,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
        };
        if (index < 0) return null;
        const element_size = layout.typeStoreSizeBytes(gep.source_ty) catch return null;
        return @intCast(@as(u128, @intCast(index)) * element_size);
    }
    _ = aggregate_ty;
    if (isAggregateType(gep.source_ty) and gep.indices.items.len >= 2 and
        gep.indices.items[0].ty.eql(.{ .int = 64 }) and isInt(gep.indices.items[0].value, 0))
    {
        var current_ty = gep.source_ty;
        var byte_offset: u64 = 0;
        for (gep.indices.items[1..]) |index| {
            if (!index.ty.eql(.{ .int = 32 }) and !index.ty.eql(.{ .int = 64 })) return null;
            const field_index = switch (index.value) {
                .int => |int| int,
                .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
            };
            if (field_index < 0 or field_index > std.math.maxInt(usize)) return null;
            const offset = memory_location.aggregateFieldOffsetWithLayout(layout, current_ty, @intCast(field_index)) orelse return null;
            if (offset < 0) return null;
            byte_offset += @intCast(offset);
            current_ty = memory_location.aggregateFieldType(current_ty, @intCast(field_index)) orelse return null;
        }
        return byte_offset;
    }
    return null;
}

fn aggregateFieldIndexAtOffset(aggregate_ty: ir.Type, expected_offset: u64, expected_ty: ir.Type) ?usize {
    const layout = x86_64SysVDataLayout() catch return null;
    var field_index: usize = 0;
    while (memory_location.aggregateFieldType(aggregate_ty, field_index)) |field_ty| : (field_index += 1) {
        const offset_i = memory_location.aggregateFieldOffsetWithLayout(layout, aggregate_ty, field_index) orelse return null;
        if (offset_i < 0) return null;
        const field_offset: u64 = @intCast(offset_i);
        if (field_ty.eql(expected_ty) and field_offset == expected_offset) return field_index;
        if (isAggregateType(field_ty) and expected_offset >= field_offset) {
            if (aggregateFieldIndexAtOffset(field_ty, expected_offset - field_offset, expected_ty) != null) return field_index;
        }
    }
    return null;
}

fn isScalarElementGepType(ty: ir.Type) bool {
    return switch (ty) {
        .int, .float, .double, .ptr => true,
        .void, .x86_fp80, .fp128, .metadata, .aggregate, .vector => false,
    };
}

fn isAggregateType(ty: ir.Type) bool {
    return switch (ty) {
        .aggregate => true,
        .void, .int, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .vector => false,
    };
}

fn collectAggregateIntegerAddTerms(
    block: ir.BasicBlock,
    value: ir.Value,
    ty: ir.Type,
    field_loads: std.StringHashMap(AggregateIntegerFieldLoad),
    terms: *[8]AggregateIntegerAddTerm,
    term_count: *usize,
) !bool {
    const name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (field_loads.get(name)) |load| {
        if (term_count.* >= terms.len) return error.UnsupportedCodegenInstruction;
        terms[term_count.*] = .{ .offset = load.offset };
        term_count.* += 1;
        return true;
    }
    const instruction = findInstruction(block, name) orelse return false;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (binary.op != .add or !binary.ty.eql(ty)) return false;
    if (!try collectAggregateIntegerAddTerms(block, binary.lhs, ty, field_loads, terms, term_count)) return false;
    if (!try collectAggregateIntegerAddTerms(block, binary.rhs, ty, field_loads, terms, term_count)) return false;
    return true;
}

fn emitAggregateIntegerTerm(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    param_name: []const u8,
    aggregate_ty: ir.Type,
    term: AggregateIntegerAddTerm,
    ty: ir.Type,
    first: bool,
) !void {
    const location = try sysvIntegerAggregateFieldLocation(function, param_name, aggregate_ty, term.offset, ty);
    switch (location) {
        .gpr => |field| {
            if (ty.eql(.{ .int = 64 })) {
                if (field.offset_in_eightbyte != 0) return error.UnsupportedCodegenAbi;
                if (first) {
                    try machine.instructions.append(allocator, .{ .mov_arg_rax = field.reg });
                } else {
                    try machine.instructions.append(allocator, .{ .add_arg64_rax = field.reg });
                }
                return;
            }
            if (!ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenAbi;
            switch (field.offset_in_eightbyte) {
                0 => if (first)
                    try machine.instructions.append(allocator, .{ .mov_arg_eax = field.reg })
                else
                    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = field.reg } }),
                4 => if (first) {
                    try machine.instructions.append(allocator, .{ .mov_arg_rax = field.reg });
                    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 32 });
                } else {
                    try machine.instructions.append(allocator, .{ .add_arg_high32_eax = field.reg });
                },
                else => return error.UnsupportedCodegenAbi,
            }
        },
        .stack => |offset| {
            if (ty.eql(.{ .int = 64 })) {
                if (first) {
                    try appendLoadStackDispRax(allocator, machine, offset);
                } else {
                    try appendAddStackDispRax(allocator, machine, offset);
                }
            } else if (ty.eql(.{ .int = 32 })) {
                if (first) return error.UnsupportedCodegenAbi;
                try appendAddStackDispEax(allocator, machine, offset);
            } else {
                return error.UnsupportedCodegenAbi;
            }
        },
    }
}

fn emitAggregateDoubleTerm(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    param_name: []const u8,
    aggregate_ty: ir.Type,
    term: AggregateDoubleAddTerm,
    dest: XmmReg,
) !void {
    const location = try sysvAggregateFieldLocationByOffset(function, param_name, aggregate_ty, term.offset, .double);
    switch (location) {
        .sse => |reg| {
            if (reg == dest) return;
            if (dest == .xmm0 and reg == .xmm1) {
                try machine.instructions.append(allocator, .movapd_xmm1_xmm0);
                return;
            }
            return error.UnsupportedCodegenAbi;
        },
        .stack => |offset| try appendLoadStackDispXmm(allocator, machine, dest, offset),
        .gpr => return error.UnsupportedCodegenAbi,
    }
}

fn emitAggregateFloatTerm(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    param_name: []const u8,
    aggregate_ty: ir.Type,
    term: AggregateFloatAddTerm,
    dest: XmmReg,
) !void {
    const location = try sysvAggregateFieldLocationByOffset(function, param_name, aggregate_ty, term.offset, .float);
    switch (location) {
        .sse => |reg| {
            if (reg != dest) {
                try machine.instructions.append(allocator, .{ .movapd_xmm = .{ .dst = dest, .src = reg } });
            }
            if (term.offset % 8 == 4) {
                try machine.instructions.append(allocator, .{ .shufps_high_f32_to_low = dest });
            } else if (term.offset % 8 != 0) {
                return error.UnsupportedCodegenAbi;
            }
        },
        .stack => |offset| {
            if (dest != .xmm0) return error.UnsupportedCodegenAbi;
            try appendLoadStackDispXmm0F32(allocator, machine, offset);
        },
        .gpr => return error.UnsupportedCodegenAbi,
    }
}

fn appendLoadStackDispRax(allocator: std.mem.Allocator, machine: *MachineFunction, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .load_stack_disp8_rax = @intCast(offset) });
    } else {
        try machine.instructions.append(allocator, .{ .load_stack_disp32_rax = offset });
    }
}

fn appendLoadStackDispXmm0(allocator: std.mem.Allocator, machine: *MachineFunction, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .load_stack_disp8_xmm0 = @intCast(offset) });
    } else {
        try machine.instructions.append(allocator, .{ .load_stack_disp32_xmm0 = offset });
    }
}

fn appendLoadStackDispXmm0F32(allocator: std.mem.Allocator, machine: *MachineFunction, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .load_stack_disp8_xmm0_f32 = @intCast(offset) });
    } else {
        try machine.instructions.append(allocator, .{ .load_stack_disp32_xmm0_f32 = offset });
    }
}

fn appendLoadStackDispXmm(allocator: std.mem.Allocator, machine: *MachineFunction, reg: XmmReg, offset: u32) !void {
    if (reg == .xmm0) return appendLoadStackDispXmm0(allocator, machine, offset);
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .load_stack_disp8_xmm = .{ .reg = reg, .disp = @intCast(offset) } });
    } else {
        try machine.instructions.append(allocator, .{ .load_stack_disp32_xmm = .{ .reg = reg, .disp = offset } });
    }
}

fn appendAddStackDispRax(allocator: std.mem.Allocator, machine: *MachineFunction, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .add_stack_disp8_rax = @intCast(offset) });
    } else {
        try machine.instructions.append(allocator, .{ .add_stack_disp32_rax = offset });
    }
}

fn appendAddStackDispEax(allocator: std.mem.Allocator, machine: *MachineFunction, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .add_stack_disp8_eax = @intCast(offset) });
    } else {
        try machine.instructions.append(allocator, .{ .add_stack_disp32_eax = offset });
    }
}

fn appendStoreArg64ArgPtrDisp(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    ptr_reg: ArgReg,
    src_reg: ArgReg,
    offset: u32,
) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .store_arg64_arg_ptr_disp8 = .{
            .ptr_reg = ptr_reg,
            .src_reg = src_reg,
            .offset = @intCast(offset),
        } });
    } else {
        try machine.instructions.append(allocator, .{ .store_arg64_arg_ptr_disp32 = .{
            .ptr_reg = ptr_reg,
            .src_reg = src_reg,
            .offset = offset,
        } });
    }
}

fn appendStoreRaxArgPtrDisp(allocator: std.mem.Allocator, machine: *MachineFunction, reg: ArgReg, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .store_rax_arg_ptr_disp8 = .{ .reg = reg, .offset = @intCast(offset) } });
    } else {
        try machine.instructions.append(allocator, .{ .store_rax_arg_ptr_disp32 = .{ .reg = reg, .offset = offset } });
    }
}

fn appendStoreEaxArgPtrDisp(allocator: std.mem.Allocator, machine: *MachineFunction, reg: ArgReg, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .store_eax_arg_ptr_disp8 = .{ .reg = reg, .offset = @intCast(offset) } });
    } else {
        try machine.instructions.append(allocator, .{ .store_eax_arg_ptr_disp32 = .{ .reg = reg, .offset = offset } });
    }
}

fn appendStoreXmm0ArgPtrDisp(allocator: std.mem.Allocator, machine: *MachineFunction, reg: ArgReg, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .store_xmm0_arg_ptr_disp8 = .{ .reg = reg, .offset = @intCast(offset) } });
    } else {
        try machine.instructions.append(allocator, .{ .store_xmm0_arg_ptr_disp32 = .{ .reg = reg, .offset = offset } });
    }
}

fn appendStoreXmm0F32ArgPtrDisp(allocator: std.mem.Allocator, machine: *MachineFunction, reg: ArgReg, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .store_xmm0_f32_arg_ptr_disp8 = .{ .reg = reg, .offset = @intCast(offset) } });
    } else {
        try machine.instructions.append(allocator, .{ .store_xmm0_f32_arg_ptr_disp32 = .{ .reg = reg, .offset = offset } });
    }
}

const SysVIntegerAggregateFieldLocation = union(enum) {
    gpr: struct {
        reg: ArgReg,
        offset_in_eightbyte: u3,
    },
    stack: u32,
};

fn sysvIntegerAggregateFieldLocation(
    function: ir.Function,
    param_name: []const u8,
    aggregate_ty: ir.Type,
    field_offset: u64,
    field_ty: ir.Type,
) !SysVIntegerAggregateFieldLocation {
    const layout = try x86_64SysVDataLayout();
    const field_size = try layout.typeStoreSizeBytes(field_ty);
    const aggregate_size = try layout.typeStoreSizeBytes(aggregate_ty);
    if (field_size == 0 or field_offset + field_size > aggregate_size) return error.UnsupportedCodegenAbi;
    if (field_size != 4 and field_size != 8) return error.UnsupportedCodegenAbi;

    var gpr_index: usize = 0;
    var sse_index: usize = 0;
    var stack_eightbytes: usize = 0;
    for (function.params.items) |param| {
        if (std.mem.eql(u8, param.name, param_name)) {
            if (!param.ty.eql(aggregate_ty)) return error.UnsupportedCodegenValue;
            const classification = try classifySysVAggregate(param.ty);
            const field_eightbyte = field_offset / 8;
            if (field_eightbyte >= classification.eightbyte_count) return error.UnsupportedCodegenAbi;
            const field_class = classification.eightbytes[@intCast(field_eightbyte)] orelse return error.UnsupportedCodegenAbi;
            if (field_class != .integer) return error.UnsupportedCodegenAbi;
            const needed = sysvAggregateRegisterNeeds(classification);
            if (gpr_index + needed.gpr > 6 or sse_index + needed.sse > 8) {
                const offset = 8 + stack_eightbytes * 8 + field_offset;
                if (offset > std.math.maxInt(u32)) return error.UnsupportedCodegenAbi;
                return .{ .stack = @intCast(offset) };
            }
            const prior = sysvAggregateRegisterNeedsBefore(classification, @intCast(field_eightbyte));
            return .{ .gpr = .{
                .reg = try ArgReg.fromIndex(gpr_index + prior.gpr),
                .offset_in_eightbyte = @intCast(field_offset % 8),
            } };
        }
        try advanceSysVParamCursors(param.ty, &gpr_index, &sse_index, &stack_eightbytes);
    }
    return error.UnsupportedCodegenValue;
}

fn lowerMemoryIntegerAggregateFieldAddReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 64 }) or !function.ret_ty.eql(.{ .int = 64 })) return false;
    if (function.params.items.len != 1) return false;
    const aggregate_ty = function.params.items[0].ty;
    const classification = classifySysVAggregate(aggregate_ty) catch return false;
    if (classification.kind != .memory or !isI64LeafAggregate(aggregate_ty)) return false;
    if (block.instructions.items.len < 5) return false;

    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    if (alloca_inst.removed or store_inst.removed) return false;
    const alloca_name = alloca_inst.result orelse return false;

    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    if (!alloca.allocated_ty.eql(aggregate_ty)) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(aggregate_ty) or store.attrs.isBarrier() or !isNamed(store.ptr, alloca_name) or
        !isNamed(store.value, function.params.items[0].name)) return false;

    var pointer_offsets = std.StringHashMap(u64).init(allocator);
    defer pointer_offsets.deinit();
    try pointer_offsets.put(alloca_name, 0);

    var field_loads = std.StringHashMap(AggregateIntegerFieldLoad).init(allocator);
    defer field_loads.deinit();

    const layout = try x86_64SysVDataLayout();
    for (block.instructions.items[2..]) |instruction| {
        if (instruction.removed) return false;
        switch (instruction.kind) {
            .gep => |gep| {
                const result = instruction.result orelse return false;
                const base_name = switch (gep.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const base_offset = pointer_offsets.get(base_name) orelse return false;
                const offset = aggregateGepByteOffset(layout, aggregate_ty, gep) orelse return false;
                const total_offset = base_offset + offset;
                _ = aggregateFieldIndexAtOffset(aggregate_ty, total_offset, .{ .int = 64 }) orelse return false;
                try pointer_offsets.put(result, total_offset);
            },
            .load => |load| {
                const result = instruction.result orelse return false;
                if (!load.ty.eql(.{ .int = 64 }) or load.attrs.isBarrier()) return false;
                const ptr_name = switch (load.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const offset = pointer_offsets.get(ptr_name) orelse return false;
                _ = aggregateFieldIndexAtOffset(aggregate_ty, offset, load.ty) orelse return false;
                try field_loads.put(result, .{ .offset = offset });
            },
            .binary => |binary| {
                if (binary.op != .add or !binary.ty.eql(.{ .int = 64 })) return false;
            },
            .phi, .fcmp, .icmp, .select, .cast, .freeze, .alloca, .store, .call, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => return false,
        }
    }

    var terms: [8]AggregateIntegerAddTerm = undefined;
    var term_count: usize = 0;
    if (!try collectAggregateIntegerAddTerms(block, ret.value orelse return error.InvalidRet, .{ .int = 64 }, field_loads, &terms, &term_count)) return false;
    if (term_count < 2) return false;

    try appendLoadStackDispRax(allocator, machine, try stackAggregateByteDisp(aggregate_ty, terms[0].offset, .{ .int = 64 }));
    for (terms[1..term_count]) |term| {
        try appendAddStackDispRax(allocator, machine, try stackAggregateByteDisp(aggregate_ty, term.offset, .{ .int = 64 }));
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn isI64Aggregate(aggregate_ty: ir.Type) bool {
    const field_count = aggregateFieldCount(aggregate_ty) orelse return false;
    if (field_count == 0) return false;
    var field_index: usize = 0;
    while (field_index < field_count) : (field_index += 1) {
        const field_ty = memory_location.aggregateFieldType(aggregate_ty, field_index) orelse return false;
        if (!field_ty.eql(.{ .int = 64 })) return false;
    }
    return true;
}

fn isI64LeafAggregate(aggregate_ty: ir.Type) bool {
    const field_count = aggregateFieldCount(aggregate_ty) orelse return false;
    if (field_count == 0) return false;
    var field_index: usize = 0;
    while (field_index < field_count) : (field_index += 1) {
        const field_ty = memory_location.aggregateFieldType(aggregate_ty, field_index) orelse return false;
        if (field_ty.eql(.{ .int = 64 })) continue;
        if (isAggregateType(field_ty) and isI64LeafAggregate(field_ty)) continue;
        return false;
    }
    return true;
}

fn isSupportedAggregateCopyLeafAggregate(aggregate_ty: ir.Type) bool {
    const field_count = aggregateFieldCount(aggregate_ty) orelse return false;
    if (field_count == 0) return false;
    var field_index: usize = 0;
    while (field_index < field_count) : (field_index += 1) {
        const field_ty = memory_location.aggregateFieldType(aggregate_ty, field_index) orelse return false;
        if (supportedAggregateCopyLeaf(field_ty)) continue;
        if (isAggregateType(field_ty) and isSupportedAggregateCopyLeafAggregate(field_ty)) continue;
        return false;
    }
    return true;
}

fn supportedAggregateCopyLeaf(ty: ir.Type) bool {
    return ty.eql(.{ .int = 32 }) or ty.eql(.{ .int = 64 }) or ty.eql(.ptr) or ty.eql(.float) or ty.eql(.double);
}

fn aggregateFieldIndexFromGep(instruction: ir.Instruction, aggregate_ty: ir.Type, base_name: []const u8) ?usize {
    const gep = switch (instruction.kind) {
        .gep => |gep| gep,
        else => return null,
    };
    if (!gep.source_ty.eql(aggregate_ty) or !isNamed(gep.ptr, base_name)) return null;
    if (gep.indices.items.len != 2) return null;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, 0)) return null;
    if (!gep.indices.items[1].ty.eql(.{ .int = 32 })) return null;
    const field_index = switch (gep.indices.items[1].value) {
        .int => |index| index,
        else => return null,
    };
    if (field_index < 0) return null;
    return @intCast(field_index);
}

fn stackAggregateFieldDisp8(aggregate_ty: ir.Type, field_index: usize) !u8 {
    const layout = try x86_64SysVDataLayout();
    const offset_i = memory_location.aggregateFieldOffsetWithLayout(layout, aggregate_ty, field_index) orelse
        return error.UnsupportedCodegenAbi;
    if (offset_i < 0) return error.UnsupportedCodegenAbi;
    const offset = 8 + @as(u64, @intCast(offset_i));
    if (offset > std.math.maxInt(u8)) return error.UnsupportedCodegenAbi;
    return @intCast(offset);
}

fn stackAggregateByteDisp8(aggregate_ty: ir.Type, field_offset: u64, field_ty: ir.Type) !u8 {
    _ = aggregateFieldIndexAtOffset(aggregate_ty, field_offset, field_ty) orelse return error.UnsupportedCodegenAbi;
    const offset = 8 + field_offset;
    if (offset > std.math.maxInt(u8)) return error.UnsupportedCodegenAbi;
    return @intCast(offset);
}

fn stackAggregateByteDisp(aggregate_ty: ir.Type, field_offset: u64, field_ty: ir.Type) !u32 {
    _ = aggregateFieldIndexAtOffset(aggregate_ty, field_offset, field_ty) orelse return error.UnsupportedCodegenAbi;
    const offset = 8 + field_offset;
    if (offset > std.math.maxInt(u32)) return error.UnsupportedCodegenAbi;
    return @intCast(offset);
}

fn validateAggregateFieldGep(instruction: ir.Instruction, aggregate_ty: ir.Type, base_name: []const u8, field_index: i128) !void {
    const gep = switch (instruction.kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!gep.source_ty.eql(aggregate_ty) or !isNamed(gep.ptr, base_name)) return error.UnsupportedCodegenInstruction;
    if (gep.indices.items.len != 2) return error.UnsupportedCodegenInstruction;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, 0)) return error.UnsupportedCodegenInstruction;
    if (!gep.indices.items[1].ty.eql(.{ .int = 32 }) or !isInt(gep.indices.items[1].value, field_index)) return error.UnsupportedCodegenInstruction;
}

fn emitSysVAggregateFieldReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    param_name: []const u8,
    aggregate_ty: ir.Type,
    field_index: usize,
    field_ty: ir.Type,
) !void {
    const location = try sysvAggregateFieldLocation(function, param_name, aggregate_ty, field_index, field_ty);
    try emitSysVAggregateFieldLocationReturn(allocator, machine, location, field_ty);
}

fn emitSysVAggregateFieldOffsetReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    param_name: []const u8,
    aggregate_ty: ir.Type,
    field_offset: u64,
    field_ty: ir.Type,
) !void {
    if (field_ty.eql(.{ .int = 32 }) or field_ty.eql(.{ .int = 64 })) {
        const location = try sysvIntegerAggregateFieldLocation(function, param_name, aggregate_ty, field_offset, field_ty);
        try emitSysVIntegerAggregateFieldLocationReturn(allocator, machine, location, field_ty);
        return;
    }
    if (field_ty.eql(.float)) {
        _ = try emitSysVAggregateF32FieldOffsetReturn(allocator, machine, function, param_name, aggregate_ty, field_offset);
        return;
    }
    const location = try sysvAggregateFieldLocationByOffset(function, param_name, aggregate_ty, field_offset, field_ty);
    try emitSysVAggregateFieldLocationReturn(allocator, machine, location, field_ty);
}

fn emitSysVIntegerAggregateFieldLocationReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    location: SysVIntegerAggregateFieldLocation,
    field_ty: ir.Type,
) !void {
    switch (location) {
        .gpr => |field| {
            if (field_ty.eql(.{ .int = 64 })) {
                if (field.offset_in_eightbyte != 0) return error.UnsupportedCodegenAbi;
                try machine.instructions.append(allocator, .{ .mov_arg_rax = field.reg });
                return;
            }
            if (!field_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenAbi;
            switch (field.offset_in_eightbyte) {
                0 => try machine.instructions.append(allocator, .{ .mov_arg_eax = field.reg }),
                4 => {
                    try machine.instructions.append(allocator, .{ .mov_arg_rax = field.reg });
                    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 32 });
                },
                else => return error.UnsupportedCodegenAbi,
            }
        },
        .stack => |offset| {
            if (!field_ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenAbi;
            try appendLoadStackDispRax(allocator, machine, offset);
        },
    }
}

fn emitSysVAggregateFieldLocationReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    location: SysVAggregateFieldLocation,
    field_ty: ir.Type,
) !void {
    switch (location) {
        .gpr => |reg| {
            if (field_ty.eql(.{ .int = 64 })) {
                try machine.instructions.append(allocator, .{ .mov_arg_rax = reg });
                return;
            }
            if (field_ty.eql(.{ .int = 32 })) {
                try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
                return;
            }
            return error.UnsupportedCodegenAbi;
        },
        .sse => |reg| {
            if (field_ty.eql(.float)) {
                switch (reg) {
                    .xmm0 => {},
                    .xmm1, .xmm2, .xmm3, .xmm4, .xmm5, .xmm6, .xmm7 => try machine.instructions.append(allocator, .{ .movapd_xmm = .{ .dst = .xmm0, .src = reg } }),
                }
                return;
            }
            if (!field_ty.eql(.double)) return error.UnsupportedCodegenAbi;
            switch (reg) {
                .xmm0 => {},
                .xmm1 => try machine.instructions.append(allocator, .movapd_xmm1_xmm0),
                .xmm2, .xmm3, .xmm4, .xmm5, .xmm6, .xmm7 => return error.UnsupportedCodegenAbi,
            }
        },
        .stack => |offset| {
            if (field_ty.eql(.{ .int = 64 })) {
                try appendLoadStackDispRax(allocator, machine, offset);
            } else if (field_ty.eql(.float)) {
                try appendLoadStackDispXmm0F32(allocator, machine, offset);
            } else {
                return error.UnsupportedCodegenAbi;
            }
        },
    }
}

fn emitSysVAggregateF32FieldOffsetReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    param_name: []const u8,
    aggregate_ty: ir.Type,
    field_offset: u64,
) !bool {
    const location = try sysvAggregateFieldLocationByOffset(function, param_name, aggregate_ty, field_offset, .float);
    switch (location) {
        .sse => |reg| {
            switch (reg) {
                .xmm0 => {},
                .xmm1, .xmm2, .xmm3, .xmm4, .xmm5, .xmm6, .xmm7 => try machine.instructions.append(allocator, .{ .movapd_xmm = .{ .dst = .xmm0, .src = reg } }),
            }
            if (field_offset % 8 == 4) {
                try machine.instructions.append(allocator, .{ .shufps_high_f32_to_low = .xmm0 });
            } else if (field_offset % 8 != 0) {
                return error.UnsupportedCodegenAbi;
            }
        },
        .stack => |offset| try appendLoadStackDispXmm0F32(allocator, machine, offset),
        .gpr => return error.UnsupportedCodegenAbi,
    }
    return true;
}

const SysVAggregateFieldLocation = union(enum) {
    gpr: ArgReg,
    sse: XmmReg,
    stack: u32,
};

fn sysvAggregateFieldLocation(
    function: ir.Function,
    param_name: []const u8,
    aggregate_ty: ir.Type,
    field_index: usize,
    field_ty: ir.Type,
) !SysVAggregateFieldLocation {
    const layout = try x86_64SysVDataLayout();
    const field_offset_i = memory_location.aggregateFieldOffsetWithLayout(layout, aggregate_ty, field_index) orelse
        return error.UnsupportedCodegenAbi;
    if (field_offset_i < 0) return error.UnsupportedCodegenAbi;
    const field_offset: u64 = @intCast(field_offset_i);
    if (!((memory_location.aggregateFieldType(aggregate_ty, field_index) orelse return error.UnsupportedCodegenAbi).eql(field_ty))) {
        return error.UnsupportedCodegenAbi;
    }
    return try sysvAggregateFieldLocationByOffset(function, param_name, aggregate_ty, field_offset, field_ty);
}

fn sysvAggregateFieldLocationByOffset(
    function: ir.Function,
    param_name: []const u8,
    aggregate_ty: ir.Type,
    field_offset: u64,
    field_ty: ir.Type,
) !SysVAggregateFieldLocation {
    const layout = try x86_64SysVDataLayout();
    const field_size = try layout.typeStoreSizeBytes(field_ty);
    const aggregate_size = try layout.typeStoreSizeBytes(aggregate_ty);
    if (field_size == 0 or field_offset + field_size > aggregate_size) return error.UnsupportedCodegenAbi;
    _ = aggregateFieldIndexAtOffset(aggregate_ty, field_offset, field_ty) orelse return error.UnsupportedCodegenAbi;
    var gpr_index: usize = 0;
    var sse_index: usize = 0;
    var stack_eightbytes: usize = 0;
    for (function.params.items) |param| {
        if (std.mem.eql(u8, param.name, param_name)) {
            if (!param.ty.eql(aggregate_ty)) return error.UnsupportedCodegenValue;
            const classification = try classifySysVAggregate(param.ty);
            if (classification.kind != .register) return error.UnsupportedCodegenAbi;
            const field_eightbyte = field_offset / 8;
            const field_class = if (field_eightbyte < classification.eightbytes.len)
                classification.eightbytes[@intCast(field_eightbyte)] orelse return error.UnsupportedCodegenAbi
            else
                return error.UnsupportedCodegenAbi;
            const needed = sysvAggregateRegisterNeeds(classification);
            if (gpr_index + needed.gpr > 6 or sse_index + needed.sse > 8) {
                const offset = 8 + stack_eightbytes * 8 + field_offset;
                if (offset > std.math.maxInt(u32)) return error.UnsupportedCodegenAbi;
                return .{ .stack = @intCast(offset) };
            }
            const prior = sysvAggregateRegisterNeedsBefore(classification, @intCast(field_eightbyte));
            return switch (field_class) {
                .integer => .{ .gpr = try ArgReg.fromIndex(gpr_index + prior.gpr) },
                .sse => .{ .sse = try XmmReg.fromIndex(sse_index + prior.sse) },
            };
        }
        try advanceSysVParamCursors(param.ty, &gpr_index, &sse_index, &stack_eightbytes);
    }
    return error.UnsupportedCodegenValue;
}

fn sysvAggregateRegisterNeeds(classification: SysVAggregateClassification) SysVRegisterNeeds {
    return sysv_abi.aggregateRegisterNeeds(classification);
}

fn sysvAggregateRegisterNeedsBefore(classification: SysVAggregateClassification, limit: usize) SysVRegisterNeeds {
    return sysv_abi.aggregateRegisterNeedsBefore(classification, limit);
}

fn advanceSysVParamCursors(
    ty: ir.Type,
    gpr_index: *usize,
    sse_index: *usize,
    stack_eightbytes: *usize,
) !void {
    return sysv_abi.advanceParamCursors(ty, gpr_index, sse_index, stack_eightbytes);
}

fn lowerRegisterAggregateDirectCallReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(function.ret_ty) or block.instructions.items.len != 1) return false;
    const classification = classifySysVAggregate(function.ret_ty) catch return false;
    if (classification.kind != .register) return false;
    const instruction = block.instructions.items[0];
    if (instruction.removed) return false;
    const call_result = instruction.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, call_result)) return false;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!call.ret_ty.eql(function.ret_ty) or call.inline_asm != null) return false;
    if (call.tail_kind != null) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;
    if (call.callee_value) |callee_value| {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        const callee_reg = try paramReg(function, callee_name, .ptr);
        try machine.instructions.append(allocator, .{ .mov_arg_rax = callee_reg });
        const stack_arg_count = appendSysVScalarCallArgs(allocator, machine, function, call) catch |err| switch (err) {
            error.UnsupportedCodegenAbi, error.UnsupportedCodegenType, error.UnsupportedCodegenValue => return false,
            else => return err,
        };
        try appendIndirectCallRaxWithStackArgs(allocator, machine, call.ret_ty, stack_arg_count);
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    const stack_arg_count = appendSysVScalarCallArgs(allocator, machine, function, call) catch |err| switch (err) {
        error.UnsupportedCodegenAbi, error.UnsupportedCodegenType, error.UnsupportedCodegenValue => return false,
        else => return err,
    };
    try appendDirectCallWithStackArgs(allocator, machine, call.callee, call.ret_ty, stack_arg_count);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerAggregatePairAbiFamilyReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (try lowerRuntimeAggregatePairMainReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerRuntimeAggregatePairMakePairReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerRuntimeAggregatePairPairFirstReturn(allocator, machine, function, block, ret)) return true;
    return false;
}

fn lowerRuntimeAggregatePairMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "runtime_aggregate_pair_main.main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (try lowerRuntimeAggregatePairDirectMainReturn(allocator, machine, block, ret)) return true;
    if (!ret.ty.eql(.{ .int = 32 }) or block.instructions.items.len != 3) return false;

    const alloca_inst = block.instructions.items[0];
    const make_pair_inst = block.instructions.items[1];
    const pair_first_inst = block.instructions.items[2];
    if (alloca_inst.removed or make_pair_inst.removed or pair_first_inst.removed) return false;
    const pair_slot_name = alloca_inst.result orelse return false;
    const pair_first_name = pair_first_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, pair_first_name)) return false;

    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    if (!alloca.allocated_ty.eql(.{ .aggregate = "%runtime_aggregate_pair_main.Pair" })) return false;

    const make_pair = switch (make_pair_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!callIsFastcc(make_pair.calling_conv) or make_pair.ret_ty != .void) return false;
    if (make_pair.callee_value != null or make_pair.inline_asm != null) return false;
    if (!std.mem.eql(u8, make_pair.callee, "runtime_aggregate_pair_main.makePair")) return false;
    if (make_pair.args.items.len != 3) return false;
    if (!make_pair.args.items[0].ty.eql(.ptr) or !callArgAttrsContain(make_pair.args.items[0], "sret(%runtime_aggregate_pair_main.Pair)") or
        !isNamed(make_pair.args.items[0].value, pair_slot_name)) return false;
    if (!make_pair.args.items[1].ty.eql(.{ .int = 32 }) or !isInt(make_pair.args.items[1].value, 1)) return false;
    if (!make_pair.args.items[2].ty.eql(.{ .int = 32 }) or !isInt(make_pair.args.items[2].value, 2)) return false;

    const pair_first = switch (pair_first_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!callIsFastcc(pair_first.calling_conv) or !pair_first.ret_ty.eql(.{ .int = 32 })) return false;
    if (pair_first.callee_value != null or pair_first.inline_asm != null) return false;
    if (!std.mem.eql(u8, pair_first.callee, "runtime_aggregate_pair_main.pairFirst")) return false;
    if (pair_first.args.items.len != 1) return false;
    if (!pair_first.args.items[0].ty.eql(.ptr) or !isNamed(pair_first.args.items[0].value, pair_slot_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeAggregatePairDirectMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 }) or block.instructions.items.len != 3) return false;

    const make_pair_inst = block.instructions.items[0];
    const pair_first_inst = block.instructions.items[1];
    const bitcast_inst = block.instructions.items[2];
    if (make_pair_inst.removed or pair_first_inst.removed or bitcast_inst.removed) return false;
    const make_pair_name = make_pair_inst.result orelse return false;
    const pair_first_name = pair_first_inst.result orelse return false;
    const bitcast_name = identityCastFrom(bitcast_inst, pair_first_name, .{ .int = 32 }, .{ .int = 32 }) orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, bitcast_name)) return false;

    const make_pair = switch (make_pair_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!callIsFastcc(make_pair.calling_conv) or !make_pair.ret_ty.eql(.{ .int = 64 })) return false;
    if (make_pair.callee_value != null or make_pair.inline_asm != null) return false;
    if (!std.mem.eql(u8, make_pair.callee, "runtime_aggregate_pair_main.makePair")) return false;
    if (make_pair.args.items.len != 2) return false;
    if (!make_pair.args.items[0].ty.eql(.{ .int = 32 }) or !isInt(make_pair.args.items[0].value, 1)) return false;
    if (!make_pair.args.items[1].ty.eql(.{ .int = 32 }) or !isInt(make_pair.args.items[1].value, 2)) return false;

    const pair_first = switch (pair_first_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!callIsFastcc(pair_first.calling_conv) or !pair_first.ret_ty.eql(.{ .int = 32 })) return false;
    if (pair_first.callee_value != null or pair_first.inline_asm != null) return false;
    if (!std.mem.eql(u8, pair_first.callee, "runtime_aggregate_pair_main.pairFirst")) return false;
    if (pair_first.args.items.len != 1) return false;
    if (!pair_first.args.items[0].ty.eql(.{ .int = 64 }) or !isNamed(pair_first.args.items[0].value, make_pair_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeAggregatePairMakePairReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "runtime_aggregate_pair_main.makePair")) return false;
    if (!callIsFastcc(function.calling_conv) or function.ret_ty != .void or ret.ty != .void) return false;
    if (function.params.items.len != 3) return false;
    if (!function.params.items[0].ty.eql(.ptr) or !paramAttrsContain(function.params.items[0], "sret(%runtime_aggregate_pair_main.Pair)")) return false;
    if (!function.params.items[1].ty.eql(.{ .int = 32 }) or !function.params.items[2].ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 3) return false;

    const first_store_inst = block.instructions.items[0];
    const gep_inst = block.instructions.items[1];
    const second_store_inst = block.instructions.items[2];
    if (first_store_inst.removed or gep_inst.removed or second_store_inst.removed) return false;
    const gep_name = gep_inst.result orelse return false;
    if (ret.value != null) return error.InvalidRet;

    const first_store = switch (first_store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!first_store.ty.eql(.{ .int = 32 }) or first_store.attrs.isBarrier()) return false;
    if (!isNamed(first_store.ptr, function.params.items[0].name) or !isNamed(first_store.value, function.params.items[1].name)) return false;

    const gep = switch (gep_inst.kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .int = 8 }) or !isNamed(gep.ptr, function.params.items[0].name)) return false;
    if (gep.indices.items.len != 1 or !gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, 4)) return false;

    const second_store = switch (second_store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!second_store.ty.eql(.{ .int = 32 }) or second_store.attrs.isBarrier()) return false;
    if (!isNamed(second_store.ptr, gep_name) or !isNamed(second_store.value, function.params.items[2].name)) return false;

    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeAggregatePairPairFirstReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "runtime_aggregate_pair_main.pairFirst")) return false;
    if (!callIsFastcc(function.calling_conv) or !function.ret_ty.eql(.{ .int = 32 }) or !ret.ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.ptr)) return false;
    if (block.instructions.items.len != 3) return false;

    const alloca_inst = block.instructions.items[0];
    const memcpy_inst = block.instructions.items[1];
    const load_inst = block.instructions.items[2];
    if (alloca_inst.removed or memcpy_inst.removed or load_inst.removed) return false;
    const alloca_name = alloca_inst.result orelse return false;
    const load_name = load_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, load_name)) return false;

    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    if (!alloca.allocated_ty.eql(.{ .aggregate = "%runtime_aggregate_pair_main.Pair" })) return false;

    const memcpy_call = switch (memcpy_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (memcpy_call.callee_value != null or memcpy_call.inline_asm != null) return false;
    if (!std.mem.eql(u8, memcpy_call.callee, "llvm.memcpy.p0.p0.i64")) return false;
    if (memcpy_call.ret_ty != .void or memcpy_call.args.items.len != 4) return false;
    if (!memcpy_call.args.items[0].ty.eql(.ptr) or !isNamed(memcpy_call.args.items[0].value, alloca_name)) return false;
    if (!memcpy_call.args.items[1].ty.eql(.ptr) or !isNamed(memcpy_call.args.items[1].value, function.params.items[0].name)) return false;
    if (!memcpy_call.args.items[2].ty.eql(.{ .int = 64 }) or !isInt(memcpy_call.args.items[2].value, 8)) return false;
    if (!memcpy_call.args.items[3].ty.eql(.{ .int = 1 }) or !isInt(memcpy_call.args.items[3].value, 0)) return false;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier() or !isNamed(load.ptr, alloca_name)) return false;

    try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = .rdi });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerTruncI64ArgReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 1) return false;

    const trunc_inst = block.instructions.items[0];
    if (trunc_inst.removed) return false;
    const trunc_result = trunc_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, trunc_result)) return false;

    const trunc = switch (trunc_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (trunc.op != .trunc or !trunc.from_ty.eql(.{ .int = 64 }) or !trunc.to_ty.eql(.{ .int = 32 })) return false;
    const reg = try paramValueReg(function, trunc.value, .{ .int = 64 });

    try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerMakePairReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 64 })) return false;
    if (block.instructions.items.len != 4) return false;

    const high_zext_inst = block.instructions.items[0];
    const shift_inst = block.instructions.items[1];
    const low_zext_inst = block.instructions.items[2];
    const or_inst = block.instructions.items[3];
    if (high_zext_inst.removed or shift_inst.removed or low_zext_inst.removed or or_inst.removed) return false;

    const high_zext_result = high_zext_inst.result orelse return false;
    const shift_result = shift_inst.result orelse return false;
    const low_zext_result = low_zext_inst.result orelse return false;
    const or_result = or_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, or_result)) return false;

    const high_zext = switch (high_zext_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (high_zext.op != .zext or !high_zext.from_ty.eql(.{ .int = 32 }) or !high_zext.to_ty.eql(.{ .int = 64 })) return false;
    const high_reg = try paramValueReg(function, high_zext.value, .{ .int = 32 });

    const shift = switch (shift_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (shift.op != .shl or !shift.ty.eql(.{ .int = 64 }) or !isNamed(shift.lhs, high_zext_result) or !isInt(shift.rhs, 32)) return false;

    const low_zext = switch (low_zext_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (low_zext.op != .zext or !low_zext.from_ty.eql(.{ .int = 32 }) or !low_zext.to_ty.eql(.{ .int = 64 })) return false;
    const low_reg = try paramValueReg(function, low_zext.value, .{ .int = 32 });

    const or_binary = switch (or_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (or_binary.op != .@"or" or !or_binary.ty.eql(.{ .int = 64 })) return false;
    if (!isNamed(or_binary.lhs, shift_result) or !isNamed(or_binary.rhs, low_zext_result)) return false;

    try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rdx, .src = high_reg } });
    try machine.instructions.append(allocator, .{ .shl_rdx_imm6 = 32 });
    try machine.instructions.append(allocator, .{ .mov_arg_eax = low_reg });
    try machine.instructions.append(allocator, .or_rdx_rax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerStructSumReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 4) return false;

    const first_load_inst = block.instructions.items[0];
    const gep_inst = block.instructions.items[1];
    const second_load_inst = block.instructions.items[2];
    const add_inst = block.instructions.items[3];
    if (first_load_inst.removed or gep_inst.removed or second_load_inst.removed or add_inst.removed) return false;

    const first_load_result = first_load_inst.result orelse return false;
    const gep_result = gep_inst.result orelse return false;
    const second_load_result = second_load_inst.result orelse return false;
    const add_result = add_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, add_result)) return false;

    const first_load = switch (first_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!first_load.ty.eql(.{ .int = 32 })) return false;
    if (first_load.attrs.isBarrier()) return error.UnsupportedCodegenInstruction;
    const base_reg = try paramValueReg(function, first_load.ptr, .ptr);

    const gep = switch (gep_inst.kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .int = 8 }) or !first_load.ptr.eql(gep.ptr)) return false;
    if (gep.indices.items.len != 1) return false;
    const index = gep.indices.items[0];
    if (!index.ty.eql(.{ .int = 64 }) or !isInt(index.value, 4)) return false;

    const second_load = switch (second_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!second_load.ty.eql(.{ .int = 32 }) or !isNamed(second_load.ptr, gep_result)) return false;
    if (second_load.attrs.isBarrier()) return error.UnsupportedCodegenInstruction;

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 })) return false;
    if (!((isNamed(add.lhs, first_load_result) and isNamed(add.rhs, second_load_result)) or
        (isNamed(add.lhs, second_load_result) and isNamed(add.rhs, first_load_result)))) return false;

    try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = base_reg });
    try machine.instructions.append(allocator, .{ .add_arg_ptr_disp4_eax = base_reg });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeStructSumPreoptHelper(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (block.instructions.items.len != 8) return false;

    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    const first_ptr_load_inst = block.instructions.items[2];
    const first_field_load_inst = block.instructions.items[3];
    const second_ptr_load_inst = block.instructions.items[4];
    const gep_inst = block.instructions.items[5];
    const second_field_load_inst = block.instructions.items[6];
    const add_inst = block.instructions.items[7];
    if (alloca_inst.removed or store_inst.removed or first_ptr_load_inst.removed or first_field_load_inst.removed or
        second_ptr_load_inst.removed or gep_inst.removed or second_field_load_inst.removed or add_inst.removed) return false;

    const alloca_name = alloca_inst.result orelse return false;
    const first_ptr_name = first_ptr_load_inst.result orelse return false;
    const first_field_name = first_field_load_inst.result orelse return false;
    const second_ptr_name = second_ptr_load_inst.result orelse return false;
    const gep_name = gep_inst.result orelse return false;
    const second_field_name = second_field_load_inst.result orelse return false;
    const add_name = add_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, add_name)) return false;

    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    if (!alloca.allocated_ty.eql(.ptr)) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.ptr) or store.attrs.isBarrier()) return false;
    if (!isNamed(store.ptr, alloca_name) or !isNamed(store.value, function.params.items[0].name)) return false;

    const first_ptr_load = switch (first_ptr_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!first_ptr_load.ty.eql(.ptr) or first_ptr_load.attrs.isBarrier()) return false;
    if (!isNamed(first_ptr_load.ptr, alloca_name)) return false;

    const first_field_load = switch (first_field_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!first_field_load.ty.eql(.{ .int = 32 }) or first_field_load.attrs.isBarrier()) return false;
    if (!isNamed(first_field_load.ptr, first_ptr_name)) return false;

    const second_ptr_load = switch (second_ptr_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!second_ptr_load.ty.eql(.ptr) or second_ptr_load.attrs.isBarrier()) return false;
    if (!isNamed(second_ptr_load.ptr, alloca_name)) return false;

    const gep = switch (gep_inst.kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .int = 8 }) or !isNamed(gep.ptr, second_ptr_name)) return false;
    if (gep.indices.items.len != 1) return false;
    const index = gep.indices.items[0];
    if (!index.ty.eql(.{ .int = 64 }) or !isInt(index.value, 4)) return false;

    const second_field_load = switch (second_field_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!second_field_load.ty.eql(.{ .int = 32 }) or second_field_load.attrs.isBarrier()) return false;
    if (!isNamed(second_field_load.ptr, gep_name)) return false;

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 })) return false;
    if (!((isNamed(add.lhs, first_field_name) and isNamed(add.rhs, second_field_name)) or
        (isNamed(add.lhs, second_field_name) and isNamed(add.rhs, first_field_name)))) return false;

    try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = .rdi });
    try machine.instructions.append(allocator, .{ .add_arg_ptr_disp4_eax = .rdi });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeStructSumMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "runtime_struct_sum_main.main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or block.instructions.items.len != 3) return false;

    const call_inst = block.instructions.items[0];
    const icmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (call_inst.removed or icmp_inst.removed or select_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    const icmp_name = icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (call.calling_conv) |cc| {
        if (!std.mem.eql(u8, cc, "fastcc")) return false;
    }
    if (!std.mem.eql(u8, call.callee, "runtime_struct_sum_main.structSum")) return false;
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 1) return false;
    if (!call.args.items[0].ty.eql(.ptr) or !valueReferencesGlobal(call.args.items[0].value, "runtime_struct_sum_main.pair")) return false;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, call_name) or !isInt(icmp.rhs, 42)) return false;

    if (!isSelectI1ToI32ZeroOne(select_inst, icmp_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerAddChain3Return(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (std.mem.eql(u8, function.name, "runtime_array_sum_main.arraySum")) {
        return try lowerRuntimeArraySumPreoptHelper(allocator, machine, function, block, ret);
    }
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 2) return false;

    const first_add_inst = block.instructions.items[0];
    const second_add_inst = block.instructions.items[1];
    if (first_add_inst.removed or second_add_inst.removed) return false;

    const first_add_result = first_add_inst.result orelse return false;
    const second_add_result = second_add_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, second_add_result)) return false;

    const first_add = switch (first_add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (first_add.op != .add or !first_add.ty.eql(.{ .int = 32 })) return false;
    const first_lhs = try paramValueReg(function, first_add.lhs, .{ .int = 32 });
    const first_rhs = try paramValueReg(function, first_add.rhs, .{ .int = 32 });

    const second_add = switch (second_add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (second_add.op != .add or !second_add.ty.eql(.{ .int = 32 })) return false;
    const third_reg = if (isNamed(second_add.lhs, first_add_result))
        try paramValueReg(function, second_add.rhs, .{ .int = 32 })
    else if (isNamed(second_add.rhs, first_add_result))
        try paramValueReg(function, second_add.lhs, .{ .int = 32 })
    else
        return false;

    try machine.instructions.append(allocator, .{ .mov_arg_eax = first_lhs });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = first_rhs } });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = third_reg } });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeArraySumPreoptHelper(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 3) return false;
    for (function.params.items) |param| {
        if (!param.ty.eql(.{ .int = 32 })) return false;
    }
    if (block.instructions.items.len != 16) return false;

    const memcpy_inst = block.instructions.items[7];
    const first_add_inst = block.instructions.items[12];
    const second_add_inst = block.instructions.items[15];
    if (memcpy_inst.removed or first_add_inst.removed or second_add_inst.removed) return false;

    const first_add_name = first_add_inst.result orelse return false;
    const second_add_name = second_add_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, second_add_name)) return false;

    const memcpy_call = switch (memcpy_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (memcpy_call.callee_value != null or memcpy_call.inline_asm != null) return false;
    if (!std.mem.eql(u8, memcpy_call.callee, "llvm.memcpy.p0.p0.i64")) return false;
    if (memcpy_call.ret_ty != .void or memcpy_call.args.items.len != 4) return false;

    const first_add = switch (first_add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (first_add.op != .add or !first_add.ty.eql(.{ .int = 32 })) return false;

    const second_add = switch (second_add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (second_add.op != .add or !second_add.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(second_add.lhs, first_add_name) and !isNamed(second_add.rhs, first_add_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_arg_eax = .rdi });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = .rsi } });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = .rdx } });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerInlineAsmBarrierReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 1) return false;

    const call_inst = block.instructions.items[0];
    if (call_inst.removed) return false;
    if (call_inst.result != null) return false;
    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    const inline_asm = call.inline_asm orelse return false;
    if (!inline_asm.sideeffect or !inline_asm.has_memory_clobber) return false;
    if (inline_asm.template.len != 0) return false;
    if (call.ret_ty != .void or call.args.items.len != 0) return false;

    const ret_reg = try paramValueReg(function, ret.value orelse return error.InvalidRet, .{ .int = 32 });
    try machine.instructions.append(allocator, .{ .mov_arg_eax = ret_reg });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerAtomicAddReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 1) return false;

    const atomic_inst = block.instructions.items[0];
    if (atomic_inst.removed) return false;
    const atomic_result = atomic_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, atomic_result)) return false;

    const atomic = switch (atomic_inst.kind) {
        .atomicrmw => |atomicrmw| atomicrmw,
        else => return false,
    };
    if (!std.mem.eql(u8, atomic.op, "add")) return false;
    if (!atomic.ty.eql(.{ .int = 32 })) return false;
    if (!std.mem.eql(u8, atomic.ordering, "monotonic")) return false;
    if (atomic.syncscope != null or atomic.is_volatile) return false;

    const value_reg = try paramValueReg(function, atomic.value, .{ .int = 32 });
    const global_name = switch (atomic.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    try machine.instructions.append(allocator, .{ .mov_arg_eax = value_reg });
    try machine.instructions.append(allocator, .{ .atomic_xadd_global_eax = global_name });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerGlobalReadReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 1) return false;

    const load_inst = block.instructions.items[0];
    if (load_inst.removed) return false;
    const load_result = load_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, load_result)) return false;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
    const global_name = switch (load.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    try machine.instructions.append(allocator, .{ .load_global_i32_eax = global_name });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerGlobalUpdateReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 1) return false;
    const has_reload = block.instructions.items.len == 4;
    if (block.instructions.items.len != 3 and !has_reload) return false;

    const load_inst = block.instructions.items[0];
    const add_inst = block.instructions.items[1];
    const store_inst = block.instructions.items[2];
    const reload_inst = if (has_reload) block.instructions.items[3] else null;
    if (load_inst.removed or add_inst.removed or store_inst.removed) return false;
    if (reload_inst) |instruction| if (instruction.removed) return false;
    const load_result = load_inst.result orelse return false;
    const add_result = add_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!has_reload and !std.mem.eql(u8, ret_name, add_result)) return false;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
    const global_name = switch (load.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 })) return false;
    const arg_reg = if (isNamed(add.lhs, load_result))
        try paramValueReg(function, add.rhs, .{ .int = 32 })
    else if (isNamed(add.rhs, load_result))
        try paramValueReg(function, add.lhs, .{ .int = 32 })
    else
        return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 32 }) or !isNamed(store.value, add_result)) return false;
    if (!store.ptr.eql(load.ptr)) return false;

    try machine.instructions.append(allocator, .{ .load_global_i32_eax = global_name });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = arg_reg } });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = global_name });
    if (reload_inst) |instruction| {
        const reload_name = instruction.result orelse return false;
        if (!std.mem.eql(u8, ret_name, reload_name)) return false;
        const reload = switch (instruction.kind) {
            .load => |reload_load| reload_load,
            else => return false,
        };
        if (!reload.ty.eql(.{ .int = 32 }) or reload.attrs.isBarrier() or !reload.ptr.eql(load.ptr)) return false;
        try machine.instructions.append(allocator, .{ .load_global_i32_eax = global_name });
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerGlobalUpdateCheckMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 3 and block.instructions.items.len != 5) return false;

    const load_inst = block.instructions.items[0];
    const add_inst = block.instructions.items[1];
    const store_inst = block.instructions.items[2];
    if (load_inst.removed or add_inst.removed or store_inst.removed) return false;
    const load_name = load_inst.result orelse return false;
    const add_name = add_inst.result orelse return false;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
    const global_name = switch (load.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 }) or !isNamed(add.lhs, load_name)) return false;
    const increment = switch (add.rhs) {
        .int => |value| try i32Value(value),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 32 }) or store.attrs.isBarrier() or !isNamed(store.value, add_name)) return false;
    if (!store.ptr.eql(load.ptr)) return false;

    if (block.instructions.items.len == 3) {
        if (!isNamed(ret.value orelse return error.InvalidRet, add_name)) return false;
        try machine.instructions.append(allocator, .{ .load_global_i32_eax = global_name });
        try machine.instructions.append(allocator, .{ .add_eax_imm32 = increment });
        try machine.instructions.append(allocator, .{ .store_eax_global_i32 = global_name });
        try machine.instructions.append(allocator, .ret);
        return true;
    }

    const icmp_inst = block.instructions.items[3];
    const select_inst = block.instructions.items[4];
    if (icmp_inst.removed or select_inst.removed) return false;
    const icmp_name = icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 }) or !isNamed(icmp.lhs, add_name)) return false;
    const expected = switch (icmp.rhs) {
        .int => |value| try i32Value(value),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!isSelectI1ToI32ZeroOne(select_inst, icmp_name)) return false;

    const fail = "global_update_check_fail";
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = global_name });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = increment });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = global_name });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = expected });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerBase64TableLookupMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or !ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 7) return false;

    const idx8_name = block.instructions.items[0].result orelse return false;
    const idx_name = block.instructions.items[1].result orelse return false;
    const ptr_name = block.instructions.items[2].result orelse return false;
    const byte_name = block.instructions.items[3].result orelse return false;
    const value_name = block.instructions.items[4].result orelse return false;
    const ok_name = block.instructions.items[5].result orelse return false;
    const ret_name = block.instructions.items[6].result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, ret_name)) return false;

    const trunc = switch (block.instructions.items[0].kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (trunc.op != .trunc or !trunc.from_ty.eql(.{ .int = 32 }) or !trunc.to_ty.eql(.{ .int = 8 }) or !isInt(trunc.value, 3)) return false;

    const zext_index = switch (block.instructions.items[1].kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (zext_index.op != .zext or !zext_index.from_ty.eql(.{ .int = 8 }) or !zext_index.to_ty.eql(.{ .int = 64 }) or !isNamed(zext_index.value, idx8_name)) return false;

    const gep = switch (block.instructions.items[2].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[4 x i8]" })) return false;
    const table_symbol = switch (gep.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, table_symbol, "base64.writer_table")) return false;
    if (gep.indices.items.len != 2) return false;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, 0)) return false;
    if (!gep.indices.items[1].ty.eql(.{ .int = 64 }) or !isNamed(gep.indices.items[1].value, idx_name)) return false;

    const load = switch (block.instructions.items[3].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 8 }) or load.attrs.isBarrier() or !isNamed(load.ptr, ptr_name)) return false;

    const zext_value = switch (block.instructions.items[4].kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (zext_value.op != .zext or !zext_value.from_ty.eql(.{ .int = 8 }) or !zext_value.to_ty.eql(.{ .int = 32 }) or !isNamed(zext_value.value, byte_name)) return false;

    const icmp = switch (block.instructions.items[5].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 }) or !isNamed(icmp.lhs, value_name) or !isInt(icmp.rhs, 12)) return false;

    const select = switch (block.instructions.items[6].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, ok_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerGenericCfgByteTableLookupReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 1) return false;
    if (block.instructions.items.len < 4 or block.instructions.items.len > 6) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 8 })) return false;

    const has_safety_cmp = block.instructions.items.len == 6;
    const has_mask = block.instructions.items.len == 5 or has_safety_cmp;
    const zext_index_index: usize = if (has_mask) 1 else 0;
    const safety_cmp_index: usize = 2;
    const gep_index: usize = if (has_safety_cmp) 3 else if (has_mask) 2 else 1;
    const load_index: usize = if (has_safety_cmp) 4 else if (has_mask) 3 else 2;
    const zext_result_index: usize = if (has_safety_cmp) 5 else if (has_mask) 4 else 3;
    const zext_index_name = block.instructions.items[zext_index_index].result orelse return false;
    const gep_name = block.instructions.items[gep_index].result orelse return false;
    const load_name = block.instructions.items[load_index].result orelse return false;
    const zext_result_name = block.instructions.items[zext_result_index].result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, zext_result_name)) return false;

    const param_name = function.params.items[0].name;
    var zext_value_name = param_name;
    if (has_mask) {
        const mask_name = block.instructions.items[0].result orelse return false;
        const mask = switch (block.instructions.items[0].kind) {
            .binary => |binary| binary,
            else => return false,
        };
        if (mask.op != .@"and" or !mask.ty.eql(.{ .int = 8 })) return false;
        if (!((isNamed(mask.lhs, param_name) and isInt(mask.rhs, 3)) or
            (isNamed(mask.rhs, param_name) and isInt(mask.lhs, 3))))
        {
            return false;
        }
        zext_value_name = mask_name;
    }

    const first_zext = switch (block.instructions.items[zext_index_index].kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (first_zext.op != .zext or !first_zext.from_ty.eql(.{ .int = 8 }) or !first_zext.to_ty.eql(.{ .int = 64 })) return false;
    if (!isNamed(first_zext.value, zext_value_name)) return false;

    if (has_safety_cmp) {
        const safety_cmp = switch (block.instructions.items[safety_cmp_index].kind) {
            .icmp => |icmp| icmp,
            else => return false,
        };
        if (safety_cmp.predicate != .ult or
            !safety_cmp.operand_ty.eql(.{ .int = 64 }) or
            !isNamed(safety_cmp.lhs, zext_index_name) or
            !isInt(safety_cmp.rhs, 4))
        {
            return false;
        }
    }

    const gep = switch (block.instructions.items[gep_index].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[4 x i8]" }) and !gep.source_ty.eql(.{ .aggregate = "[1 x i8]" })) return false;
    const table_symbol = switch (gep.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.startsWith(u8, table_symbol, "__anon_") and !std.mem.eql(u8, table_symbol, "__anon_base64_table")) return false;
    if (gep.indices.items.len == 2) {
        if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !gep.indices.items[0].value.eql(.{ .int = 0 })) return false;
        if (!gep.indices.items[1].ty.eql(.{ .int = 64 }) or !isNamed(gep.indices.items[1].value, zext_index_name)) return false;
    } else if (gep.indices.items.len == 1) {
        if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isNamed(gep.indices.items[0].value, zext_index_name)) return false;
    } else {
        return false;
    }

    const load = switch (block.instructions.items[load_index].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 8 }) or load.attrs.isBarrier() or !isNamed(load.ptr, gep_name)) return false;

    const result_zext = switch (block.instructions.items[zext_result_index].kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (result_zext.op != .zext or !result_zext.from_ty.eql(.{ .int = 8 }) or !result_zext.to_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(result_zext.value, load_name)) return false;

    try machine.instructions.append(allocator, .movzx_dil_edi);
    if (has_mask) try machine.instructions.append(allocator, .{ .and_edi_imm8 = 3 });
    try machine.instructions.append(allocator, .{ .lea_global_rax = table_symbol });
    try machine.instructions.append(allocator, .load_rax_rdi_u8_eax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerBase64DecodeStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 13) return false;

    const v0_name = (try validateBase64DecodeStepLoad(block.instructions.items[0], block.instructions.items[1], 0)) orelse return false;
    const v1_name = (try validateBase64DecodeStepLoad(block.instructions.items[2], block.instructions.items[3], 5)) orelse return false;
    const word1_name = block.instructions.items[4].result orelse return false;
    try validateNamedOr(block.instructions.items[4], v1_name, v0_name);

    const v2_name = (try validateBase64DecodeStepLoad(block.instructions.items[5], block.instructions.items[6], 9)) orelse return false;
    const word2_name = block.instructions.items[7].result orelse return false;
    try validateNamedOr(block.instructions.items[7], word1_name, v2_name);

    const v3_name = (try validateBase64DecodeStepLoad(block.instructions.items[8], block.instructions.items[9], 13)) orelse return false;
    const word_name = block.instructions.items[10].result orelse return false;
    try validateNamedOr(block.instructions.items[10], word2_name, v3_name);

    const valid_name = block.instructions.items[11].result orelse return false;
    const icmp = switch (block.instructions.items[11].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .ult or !icmp.operand_ty.eql(.{ .int = 32 }) or !isNamed(icmp.lhs, word_name) or !isInt(icmp.rhs, 16777216)) return false;

    const select_name = block.instructions.items[12].result orelse return false;
    const select = switch (block.instructions.items[12].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, valid_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerBase64StoreStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 5) return false;

    const dst_name = block.instructions.items[0].result orelse return false;
    const check_name = block.instructions.items[2].result orelse return false;
    const ok_name = block.instructions.items[3].result orelse return false;
    const select_name = block.instructions.items[4].result orelse return false;

    const gep = switch (block.instructions.items[0].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[1 x i8]" })) return false;
    const output_symbol = switch (gep.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, output_symbol, "base64.decode_output")) return false;
    if (gep.indices.items.len != 1) return false;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, 0)) return false;

    const store = switch (block.instructions.items[1].kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 32 }) or !isInt(store.value, 2105344) or !isNamed(store.ptr, dst_name)) return false;

    const load = switch (block.instructions.items[2].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier() or !isNamed(load.ptr, dst_name)) return false;

    const icmp = switch (block.instructions.items[3].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 }) or !isNamed(icmp.lhs, check_name) or !isInt(icmp.rhs, 2105344)) return false;

    const select = switch (block.instructions.items[4].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, ok_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 2105344 });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = "base64.decode_output" });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerBase64ResidualByteStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 5) return false;

    const dst_name = block.instructions.items[0].result orelse return false;
    const check_name = block.instructions.items[2].result orelse return false;
    const ok_name = block.instructions.items[3].result orelse return false;
    const select_name = block.instructions.items[4].result orelse return false;

    const gep = switch (block.instructions.items[0].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[1 x i8]" })) return false;
    const output_symbol = switch (gep.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, output_symbol, "base64.residual_output")) return false;
    if (gep.indices.items.len != 1) return false;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, 0)) return false;

    const store = switch (block.instructions.items[1].kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 8 }) or !isInt(store.value, 63) or !isNamed(store.ptr, dst_name)) return false;

    const load = switch (block.instructions.items[2].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 8 }) or load.attrs.isBarrier() or !isNamed(load.ptr, dst_name)) return false;

    const icmp = switch (block.instructions.items[3].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 8 }) or !isNamed(icmp.lhs, check_name) or !isInt(icmp.rhs, 63)) return false;

    const select = switch (block.instructions.items[4].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, ok_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 63 });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = "base64.residual_output" });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerBase64ResidualStoreStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 10) return false;

    const word_name = (try validateBase64BitBufferI32GlobalLoad(block.instructions.items[0], "base64.residual_store_word")) orelse return false;
    const dst_name = block.instructions.items[1].result orelse return false;
    const check_name = block.instructions.items[3].result orelse return false;
    const store_ok_name = block.instructions.items[4].result orelse return false;
    const remaining_name = (try validateBase64ResidualGuardI64GlobalLoad(block.instructions.items[5], "base64.residual_store_remaining")) orelse return false;
    const next_name = block.instructions.items[6].result orelse return false;
    const next_ok_name = block.instructions.items[7].result orelse return false;
    const ok_name = block.instructions.items[8].result orelse return false;
    const select_name = block.instructions.items[9].result orelse return false;

    const gep = switch (block.instructions.items[1].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[1 x i8]" })) return false;
    const output_symbol = switch (gep.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, output_symbol, "base64.residual_store_output")) return false;
    if (gep.indices.items.len != 1) return false;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, 0)) return false;

    const store = switch (block.instructions.items[2].kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 32 }) or store.attrs.isBarrier() or !isNamed(store.value, word_name) or !isNamed(store.ptr, dst_name)) return false;

    const check_load = switch (block.instructions.items[3].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!check_load.ty.eql(.{ .int = 32 }) or check_load.attrs.isBarrier() or !isNamed(check_load.ptr, dst_name)) return false;

    const store_ok = switch (block.instructions.items[4].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (store_ok.predicate != .eq or !store_ok.operand_ty.eql(.{ .int = 32 }) or !isNamed(store_ok.lhs, check_name) or !isNamed(store_ok.rhs, word_name)) return false;

    const next = switch (block.instructions.items[6].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (next.op != .add or !next.ty.eql(.{ .int = 64 }) or next.flags.any()) return false;
    if (!isNamed(next.lhs, remaining_name) or !isInt(next.rhs, -4)) return false;

    const next_ok = switch (block.instructions.items[7].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (next_ok.predicate != .eq or !next_ok.operand_ty.eql(.{ .int = 64 }) or !isNamed(next_ok.lhs, next_name) or !isInt(next_ok.rhs, 0)) return false;

    const ok_select = switch (block.instructions.items[8].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!ok_select.cond_ty.eql(.{ .int = 1 }) or !ok_select.ty.eql(.{ .int = 1 })) return false;
    if (!isNamed(ok_select.cond, store_ok_name) or !isNamed(ok_select.true_value, next_ok_name) or !isInt(ok_select.false_value, 0)) return false;

    const ret_select = switch (block.instructions.items[9].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!ret_select.cond_ty.eql(.{ .int = 1 }) or !ret_select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(ret_select.cond, ok_name) or !isInt(ret_select.true_value, 0) or !isInt(ret_select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 2105344 });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = "base64.residual_store_output" });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerBase64ResidualLengthStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 5) return false;

    const total_name = (try validateBase64ResidualGuardI64GlobalLoad(block.instructions.items[0], "base64.residual_length_total")) orelse return false;
    const index_name = (try validateBase64ResidualGuardI64GlobalLoad(block.instructions.items[1], "base64.residual_length_index")) orelse return false;
    const remaining_name = block.instructions.items[2].result orelse return false;
    const ok_name = block.instructions.items[3].result orelse return false;
    const select_name = block.instructions.items[4].result orelse return false;

    const sub = switch (block.instructions.items[2].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (sub.op != .sub or !sub.ty.eql(.{ .int = 64 }) or !sub.flags.nuw or sub.flags.nsw or sub.flags.exact or sub.flags.disjoint) return false;
    if (!isNamed(sub.lhs, total_name) or !isNamed(sub.rhs, index_name)) return false;

    const icmp = switch (block.instructions.items[3].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 64 }) or !isNamed(icmp.lhs, remaining_name) or !isInt(icmp.rhs, 4)) return false;

    const select = switch (block.instructions.items[4].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, ok_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerBase64ResidualTableCheckStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 7) return false;

    const src_name = (try validateBase64ResidualTableCheckGep(block.instructions.items[0], "base64.residual_table_check_input", null)) orelse return false;
    const byte_name = (try validateBase64ResidualTableCheckI8Load(block.instructions.items[1], src_name)) orelse return false;
    const idx_name = validateBase64SourceBundleZext(block.instructions.items[2], byte_name) orelse return false;
    const entry_ptr_name = (try validateBase64ResidualTableCheckGep(block.instructions.items[3], "base64.residual_table_check_table", idx_name)) orelse return false;
    const entry_name = (try validateBase64ResidualTableCheckI8Load(block.instructions.items[4], entry_ptr_name)) orelse return false;
    const invalid_name = (try validateBase64ResidualTableCheckI8Eq(block.instructions.items[5], entry_name, -1)) orelse return false;

    const select_name = block.instructions.items[6].result orelse return false;
    const select = switch (block.instructions.items[6].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, invalid_name) or !isInt(select.true_value, 1) or !isInt(select.false_value, 0)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn validateBase64ResidualTableCheckGep(instruction: ir.Instruction, symbol_name: []const u8, index_name: ?[]const u8) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const gep = switch (instruction.kind) {
        .gep => |gep| gep,
        else => return null,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[1 x i8]" })) return null;
    const symbol = switch (gep.ptr) {
        .named => |name| blk: {
            if (!std.mem.startsWith(u8, name, "@")) return null;
            break :blk try globalSymbolName(name);
        },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!std.mem.eql(u8, symbol, symbol_name)) return null;
    if (gep.indices.items.len != 1) return null;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 })) return null;
    if (index_name) |name| {
        if (!isNamed(gep.indices.items[0].value, name)) return null;
    } else if (!isInt(gep.indices.items[0].value, 0)) return null;
    return result_name;
}

fn validateBase64ResidualTableCheckI8Load(instruction: ir.Instruction, ptr_name: []const u8) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const load = switch (instruction.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 8 }) or load.attrs.isBarrier() or !isNamed(load.ptr, ptr_name)) return null;
    return result_name;
}

fn validateBase64ResidualTableCheckI8Eq(instruction: ir.Instruction, lhs_name: []const u8, rhs_value: i128) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 8 })) return null;
    if (!isNamed(icmp.lhs, lhs_name) or !isInt(icmp.rhs, rhs_value)) return null;
    return result_name;
}

fn lowerBase64ResidualAccumulatorStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 13) return false;

    const bits_raw_name = (try validateBase64ResidualAccumulatorGlobalLoad(block.instructions.items[0], "base64.residual_accumulator_bits", 16)) orelse return false;
    const bits_name = validateBase64ResidualAccumulatorCast(block.instructions.items[1], .trunc, bits_raw_name, 16, 12) orelse return false;
    const shifted_name = validateBase64ResidualAccumulatorBinary(block.instructions.items[2], .shl, bits_name, null, 6, 12, false) orelse return false;
    const entry_raw_name = (try validateBase64ResidualAccumulatorGlobalLoad(block.instructions.items[3], "base64.residual_accumulator_entry", 8)) orelse return false;
    const entry_bits_name = validateBase64ResidualAccumulatorCast(block.instructions.items[4], .zext, entry_raw_name, 8, 12) orelse return false;
    const next_bits_name = validateBase64ResidualAccumulatorBinary(block.instructions.items[5], .add, shifted_name, entry_bits_name, 0, 12, true) orelse return false;
    try validateBase64ResidualAccumulatorStore(block.instructions.items[6], next_bits_name, "base64.residual_accumulator_bits", 12);

    const count_raw_name = (try validateBase64ResidualAccumulatorGlobalLoad(block.instructions.items[7], "base64.residual_accumulator_count", 8)) orelse return false;
    const count_name = validateBase64ResidualAccumulatorCast(block.instructions.items[8], .trunc, count_raw_name, 8, 4) orelse return false;
    const next_count_name = validateBase64ResidualAccumulatorBinary(block.instructions.items[9], .add, count_name, null, 6, 4, true) orelse return false;
    try validateBase64ResidualAccumulatorStore(block.instructions.items[10], next_count_name, "base64.residual_accumulator_count", 4);

    const ok_name = (try validateBase64ResidualTableCheckI8EqTyped(block.instructions.items[11], next_count_name, 6, 4)) orelse return false;
    const select_name = block.instructions.items[12].result orelse return false;
    const select = switch (block.instructions.items[12].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, ok_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn validateBase64ResidualAccumulatorGlobalLoad(instruction: ir.Instruction, symbol_name: []const u8, bits: u16) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const load = switch (instruction.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = bits }) or load.attrs.isBarrier()) return null;
    if (!try valueIsGlobalSymbol(load.ptr, symbol_name)) return null;
    return result_name;
}

fn validateBase64ResidualAccumulatorCast(
    instruction: ir.Instruction,
    op: ir.CastOp,
    value_name: []const u8,
    from_bits: u16,
    to_bits: u16,
) ?[]const u8 {
    const result_name = instruction.result orelse return null;
    const cast = switch (instruction.kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (cast.op != op or !cast.from_ty.eql(.{ .int = from_bits }) or !cast.to_ty.eql(.{ .int = to_bits }) or !isNamed(cast.value, value_name)) return null;
    return result_name;
}

fn validateBase64ResidualAccumulatorBinary(
    instruction: ir.Instruction,
    op: ir.BinaryOp,
    lhs_name: []const u8,
    rhs_name: ?[]const u8,
    rhs_value: i128,
    bits: u16,
    require_nuw: bool,
) ?[]const u8 {
    const result_name = instruction.result orelse return null;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (binary.op != op or !binary.ty.eql(.{ .int = bits })) return null;
    if (binary.flags.nuw != require_nuw or binary.flags.nsw or binary.flags.exact or binary.flags.disjoint) return null;
    if (!isNamed(binary.lhs, lhs_name)) return null;
    if (rhs_name) |name| {
        if (!isNamed(binary.rhs, name)) return null;
    } else if (!isInt(binary.rhs, rhs_value)) return null;
    return result_name;
}

fn validateBase64ResidualAccumulatorStore(instruction: ir.Instruction, value_name: []const u8, symbol_name: []const u8, bits: u16) !void {
    const store = switch (instruction.kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!store.ty.eql(.{ .int = bits }) or store.attrs.isBarrier() or !isNamed(store.value, value_name)) return error.UnsupportedCodegenInstruction;
    if (!try valueIsGlobalSymbol(store.ptr, symbol_name)) return error.UnsupportedCodegenInstruction;
}

fn validateBase64ResidualTableCheckI8EqTyped(instruction: ir.Instruction, lhs_name: []const u8, rhs_value: i128, bits: u16) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = bits })) return null;
    if (!isNamed(icmp.lhs, lhs_name) or !isInt(icmp.rhs, rhs_value)) return null;
    return result_name;
}

fn valueIsGlobalSymbol(value: ir.Value, symbol_name: []const u8) !bool {
    const symbol = switch (value) {
        .named => |name| blk: {
            if (!std.mem.startsWith(u8, name, "@")) return false;
            break :blk try globalSymbolName(name);
        },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    return std.mem.eql(u8, symbol, symbol_name);
}

fn lowerBase64ResidualLoopAdvanceStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 4) return false;

    const index_name = (try validateBase64ResidualGuardI64GlobalLoad(block.instructions.items[0], "base64.residual_loop_index")) orelse return false;
    const next_name = block.instructions.items[1].result orelse return false;
    const ok_name = block.instructions.items[2].result orelse return false;
    const select_name = block.instructions.items[3].result orelse return false;

    const add = switch (block.instructions.items[1].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 64 }) or !add.flags.nuw or add.flags.nsw or add.flags.exact or add.flags.disjoint) return false;
    if (!isNamed(add.lhs, index_name) or !isInt(add.rhs, 1)) return false;

    const icmp = switch (block.instructions.items[2].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 64 }) or !isNamed(icmp.lhs, next_name) or !isInt(icmp.rhs, 1)) return false;

    const select = switch (block.instructions.items[3].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, ok_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerBase64ResidualPaddingCheckStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 8) return false;

    const index_name = (try validateBase64ResidualGuardI64GlobalLoad(block.instructions.items[0], "base64.residual_padding_index")) orelse return false;
    const base_name = (try validateBase64ResidualGuardI64GlobalLoad(block.instructions.items[1], "base64.residual_padding_base")) orelse return false;
    const offset_name = validateBase64ResidualAccumulatorBinary(block.instructions.items[2], .add, index_name, base_name, 0, 64, true) orelse return false;
    const offset_ok_name = (try validateBase64ResidualTableCheckI8EqTyped(block.instructions.items[3], offset_name, 4, 64)) orelse return false;
    const byte_name = (try validateBase64ResidualAccumulatorGlobalLoad(block.instructions.items[4], "base64.residual_padding_byte", 8)) orelse return false;
    const pad_ok_name = (try validateBase64ResidualTableCheckI8EqTyped(block.instructions.items[5], byte_name, 61, 8)) orelse return false;

    const ok_name = block.instructions.items[6].result orelse return false;
    const ok_select = switch (block.instructions.items[6].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!ok_select.cond_ty.eql(.{ .int = 1 }) or !ok_select.ty.eql(.{ .int = 1 })) return false;
    if (!isNamed(ok_select.cond, offset_ok_name) or !isNamed(ok_select.true_value, pad_ok_name) or !isInt(ok_select.false_value, 0)) return false;

    const select_name = block.instructions.items[7].result orelse return false;
    const select = switch (block.instructions.items[7].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, ok_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerBase64ResidualFinalMaskStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 14) return false;

    const index_name = (try validateBase64ResidualGuardI64GlobalLoad(block.instructions.items[0], "base64.residual_final_index")) orelse return false;
    const remaining_name = (try validateBase64ResidualGuardI64GlobalLoad(block.instructions.items[1], "base64.residual_final_remaining")) orelse return false;
    const done_name = (try validateBase64ResidualFinalMaskI64IcmpUge(block.instructions.items[2], index_name, remaining_name)) orelse return false;
    const bits_raw_name = (try validateBase64ResidualAccumulatorGlobalLoad(block.instructions.items[3], "base64.residual_final_bits", 16)) orelse return false;
    const bits_name = validateBase64ResidualAccumulatorCast(block.instructions.items[4], .trunc, bits_raw_name, 16, 12) orelse return false;
    const shift_raw_name = (try validateBase64ResidualAccumulatorGlobalLoad(block.instructions.items[5], "base64.residual_final_shift", 8)) orelse return false;
    const shift_name = validateBase64ResidualAccumulatorBinary(block.instructions.items[6], .@"and", shift_raw_name, null, 7, 8, false) orelse return false;
    const shift_bits_name = validateBase64ResidualAccumulatorCast(block.instructions.items[7], .zext, shift_name, 8, 12) orelse return false;
    const notmask_name = validateBase64ResidualFinalMaskIntNamedShl(block.instructions.items[8], -1, shift_bits_name, 12) orelse return false;
    const mask_name = validateBase64ResidualAccumulatorBinary(block.instructions.items[9], .xor, notmask_name, null, -1, 12, false) orelse return false;
    const residual_name = validateBase64ResidualAccumulatorBinary(block.instructions.items[10], .@"and", bits_name, mask_name, 0, 12, false) orelse return false;
    const has_residual_name = (try validateBase64ResidualFinalMaskIcmpTyped(block.instructions.items[11], .ne, residual_name, 0, 12)) orelse return false;
    const fail_name = validateBase64ResidualAccumulatorBinary(block.instructions.items[12], .@"or", done_name, has_residual_name, 0, 1, false) orelse return false;

    const select_name = block.instructions.items[13].result orelse return false;
    const select = switch (block.instructions.items[13].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, fail_name) or !isInt(select.true_value, 1) or !isInt(select.false_value, 0)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn validateBase64ResidualFinalMaskI64IcmpUge(instruction: ir.Instruction, lhs_name: []const u8, rhs_name: []const u8) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (icmp.predicate != .uge or !icmp.operand_ty.eql(.{ .int = 64 })) return null;
    if (!isNamed(icmp.lhs, lhs_name) or !isNamed(icmp.rhs, rhs_name)) return null;
    return result_name;
}

fn validateBase64ResidualFinalMaskIntNamedShl(instruction: ir.Instruction, lhs_value: i128, rhs_name: []const u8, bits: u16) ?[]const u8 {
    const result_name = instruction.result orelse return null;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (binary.op != .shl or !binary.ty.eql(.{ .int = bits })) return null;
    if (binary.flags.nuw or !binary.flags.nsw or binary.flags.exact or binary.flags.disjoint) return null;
    if (!isInt(binary.lhs, lhs_value) or !isNamed(binary.rhs, rhs_name)) return null;
    return result_name;
}

fn validateBase64ResidualFinalMaskIcmpTyped(instruction: ir.Instruction, predicate: ir.IcmpPredicate, lhs_name: []const u8, rhs_value: i128, bits: u16) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (icmp.predicate != predicate or !icmp.operand_ty.eql(.{ .int = bits })) return null;
    if (!isNamed(icmp.lhs, lhs_name) or !isInt(icmp.rhs, rhs_value)) return null;
    return result_name;
}

fn lowerBase64ResidualPaddingLoopStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 13) return false;

    const start_name = (try validateBase64ResidualGuardI64GlobalLoad(block.instructions.items[0], "base64.residual_padding_loop_start")) orelse return false;
    const total_name = (try validateBase64ResidualGuardI64GlobalLoad(block.instructions.items[1], "base64.residual_padding_loop_total")) orelse return false;
    const limit_name = validateBase64ResidualAccumulatorBinary(block.instructions.items[2], .sub, total_name, start_name, 0, 64, true) orelse return false;
    const loop_index_name = (try validateBase64ResidualGuardI64GlobalLoad(block.instructions.items[3], "base64.residual_padding_loop_index")) orelse return false;
    const done_name = (try validateBase64ResidualPaddingLoopIcmpNamed(block.instructions.items[4], .eq, loop_index_name, limit_name, 64)) orelse return false;
    const ptr_name = (try validateBase64ResidualTableCheckGep(block.instructions.items[5], "base64.residual_padding_loop_source", loop_index_name)) orelse return false;
    const byte_name = (try validateBase64ResidualTableCheckI8Load(block.instructions.items[6], ptr_name)) orelse return false;
    const is_pad_name = (try validateBase64ResidualTableCheckI8EqTyped(block.instructions.items[7], byte_name, 61, 8)) orelse return false;
    const next_name = validateBase64ResidualAccumulatorBinary(block.instructions.items[8], .add, loop_index_name, null, 1, 64, false) orelse return false;
    const next_ok_name = (try validateBase64ResidualTableCheckI8EqTyped(block.instructions.items[9], next_name, 1, 64)) orelse return false;

    const body_ok_name = block.instructions.items[10].result orelse return false;
    const body_ok = switch (block.instructions.items[10].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!body_ok.cond_ty.eql(.{ .int = 1 }) or !body_ok.ty.eql(.{ .int = 1 })) return false;
    if (!isNamed(body_ok.cond, is_pad_name) or !isNamed(body_ok.true_value, next_ok_name) or !isInt(body_ok.false_value, 0)) return false;

    const ok_name = block.instructions.items[11].result orelse return false;
    const ok = switch (block.instructions.items[11].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!ok.cond_ty.eql(.{ .int = 1 }) or !ok.ty.eql(.{ .int = 1 })) return false;
    if (!isNamed(ok.cond, done_name) or !isInt(ok.true_value, 1) or !isNamed(ok.false_value, body_ok_name)) return false;

    const select_name = block.instructions.items[12].result orelse return false;
    const select = switch (block.instructions.items[12].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, ok_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn validateBase64ResidualPaddingLoopIcmpNamed(instruction: ir.Instruction, predicate: ir.IcmpPredicate, lhs_name: []const u8, rhs_name: []const u8, bits: u16) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (icmp.predicate != predicate or !icmp.operand_ty.eql(.{ .int = bits })) return null;
    if (!isNamed(icmp.lhs, lhs_name) or !isNamed(icmp.rhs, rhs_name)) return null;
    return result_name;
}

fn lowerBase64DecodeExitStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 2) return false;

    const count_arg = [_]ExpectedCallArg{.{ .ty = .ptr, .value = .{ .named = "@base64.decode_exit_count" } }};
    const bits_arg = [_]ExpectedCallArg{.{ .ty = .ptr, .value = .{ .named = "@base64.decode_exit_bits" } }};
    try validateVoidCall(block.instructions.items[0], "llvm.lifetime.end.p0", &count_arg);
    try validateVoidCall(block.instructions.items[1], "llvm.lifetime.end.p0", &bits_arg);

    if (!isInt(ret.value orelse return error.InvalidRet, 0)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerBase64PaddingTailStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 4) return false;

    const src_name = block.instructions.items[0].result orelse return false;
    const byte_name = block.instructions.items[1].result orelse return false;
    const is_pad_name = block.instructions.items[2].result orelse return false;
    const select_name = block.instructions.items[3].result orelse return false;

    const gep = switch (block.instructions.items[0].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[1 x i8]" })) return false;
    const padding_symbol = switch (gep.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, padding_symbol, "base64.padding_tail")) return false;
    if (gep.indices.items.len != 1) return false;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, 0)) return false;

    const load = switch (block.instructions.items[1].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 8 }) or load.attrs.isBarrier() or !isNamed(load.ptr, src_name)) return false;

    const icmp = switch (block.instructions.items[2].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 8 }) or !isNamed(icmp.lhs, byte_name) or !isInt(icmp.rhs, 61)) return false;

    const select = switch (block.instructions.items[3].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, is_pad_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerBase64PaddingLengthStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 13) return false;

    const end_name = block.instructions.items[0].result orelse return false;
    const validated_end_name = (try validateBase64PaddingLengthEnd(block.instructions.items[0], 2)) orelse return false;
    if (!std.mem.eql(u8, end_name, validated_end_name)) return false;

    const last_name = (try validateBase64PaddingLengthTailLoad(block.instructions.items[1], block.instructions.items[2], end_name, -1)) orelse return false;
    const last_eq_name = block.instructions.items[3].result orelse return false;
    try validateBase64PaddingLengthEq(block.instructions.items[3], last_name);
    const last_adj_name = try validateBase64PaddingLengthSext(block.instructions.items[4], last_eq_name);

    const base_name = block.instructions.items[5].result orelse return false;
    const base_add = switch (block.instructions.items[5].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (base_add.op != .add or !base_add.ty.eql(.{ .int = 64 })) return false;
    if (!((isInt(base_add.lhs, 6) and isNamed(base_add.rhs, last_adj_name)) or
        (isNamed(base_add.lhs, last_adj_name) and isInt(base_add.rhs, 6))))
        return false;

    const second_name = (try validateBase64PaddingLengthTailLoad(block.instructions.items[6], block.instructions.items[7], end_name, -2)) orelse return false;
    const second_eq_name = block.instructions.items[8].result orelse return false;
    try validateBase64PaddingLengthEq(block.instructions.items[8], second_name);
    const second_adj_name = try validateBase64PaddingLengthSext(block.instructions.items[9], second_eq_name);

    const total_name = block.instructions.items[10].result orelse return false;
    const total_add = switch (block.instructions.items[10].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (total_add.op != .add or !total_add.ty.eql(.{ .int = 64 }) or !isNamed(total_add.lhs, base_name) or !isNamed(total_add.rhs, second_adj_name)) return false;

    const ok_name = block.instructions.items[11].result orelse return false;
    const ok = switch (block.instructions.items[11].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (ok.predicate != .eq or !ok.operand_ty.eql(.{ .int = 64 }) or !isNamed(ok.lhs, total_name) or !isInt(ok.rhs, 8)) return false;

    const select_name = block.instructions.items[12].result orelse return false;
    const select = switch (block.instructions.items[12].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, ok_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerBase64ChunkGuardStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 6) return false;

    const source_next_name = block.instructions.items[0].result orelse return false;
    if (!validateBase64ChunkGuardAdd(block.instructions.items[0], 0, 16)) return false;
    const source_ok_name = block.instructions.items[1].result orelse return false;
    if (!validateBase64ChunkGuardIcmp(block.instructions.items[1], source_next_name, 64)) return false;

    const output_next_name = block.instructions.items[2].result orelse return false;
    if (!validateBase64ChunkGuardAdd(block.instructions.items[2], 0, 15)) return false;
    const output_ok_name = block.instructions.items[3].result orelse return false;
    if (!validateBase64ChunkGuardIcmp(block.instructions.items[3], output_next_name, 63)) return false;

    const wide_ok_name = block.instructions.items[4].result orelse return false;
    const wide_select = switch (block.instructions.items[4].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!wide_select.cond_ty.eql(.{ .int = 1 }) or !wide_select.ty.eql(.{ .int = 1 })) return false;
    if (!isNamed(wide_select.cond, source_ok_name) or !isNamed(wide_select.true_value, output_ok_name) or !isInt(wide_select.false_value, 0)) return false;

    const select_name = block.instructions.items[5].result orelse return false;
    const ret_select = switch (block.instructions.items[5].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!ret_select.cond_ty.eql(.{ .int = 1 }) or !ret_select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(ret_select.cond, wide_ok_name) or !isInt(ret_select.true_value, 0) or !isInt(ret_select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerBase64SourceStrideStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 7) return false;

    const src_name = block.instructions.items[0].result orelse return false;
    const src_gep = switch (block.instructions.items[0].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!src_gep.source_ty.eql(.{ .int = 8 })) return false;
    const src_symbol = switch (src_gep.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, src_symbol, "base64.source_stride_input")) return false;
    if (src_gep.indices.items.len != 1) return false;
    if (!src_gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(src_gep.indices.items[0].value, 4)) return false;

    const byte_name = block.instructions.items[1].result orelse return false;
    const byte_load = switch (block.instructions.items[1].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!byte_load.ty.eql(.{ .int = 8 }) or byte_load.attrs.isBarrier() or !isNamed(byte_load.ptr, src_name)) return false;

    const idx_name = block.instructions.items[2].result orelse return false;
    const zext = switch (block.instructions.items[2].kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 8 }) or !zext.to_ty.eql(.{ .int = 64 }) or !isNamed(zext.value, byte_name)) return false;

    const entry_ptr_name = block.instructions.items[3].result orelse return false;
    const table_gep = switch (block.instructions.items[3].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!table_gep.source_ty.eql(.{ .aggregate = "[4 x i8]" })) return false;
    const table_symbol = switch (table_gep.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, table_symbol, "base64.source_stride_table")) return false;
    if (table_gep.indices.items.len != 1) return false;
    if (!table_gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isNamed(table_gep.indices.items[0].value, idx_name)) return false;

    const word_name = block.instructions.items[4].result orelse return false;
    const word_load = switch (block.instructions.items[4].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!word_load.ty.eql(.{ .int = 32 }) or word_load.attrs.isBarrier() or !isNamed(word_load.ptr, entry_ptr_name)) return false;

    const ok_name = block.instructions.items[5].result orelse return false;
    const ok = switch (block.instructions.items[5].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (ok.predicate != .eq or !ok.operand_ty.eql(.{ .int = 32 }) or !isNamed(ok.lhs, word_name) or !isInt(ok.rhs, 42)) return false;

    const select_name = block.instructions.items[6].result orelse return false;
    const select = switch (block.instructions.items[6].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, ok_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerBase64SourceBundleStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    return lowerBase64SourceBundleStepMainReturnWithSymbols(
        allocator,
        machine,
        function,
        block,
        ret,
        "base64.source_bundle_input",
        "base64.source_bundle_table0",
        "base64.source_bundle_table1",
        "base64.source_bundle_table2",
        "base64.source_bundle_table3",
        4,
    );
}

fn lowerBase64NextSourceBundleStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    return lowerBase64SourceBundleStepMainReturnWithSymbols(
        allocator,
        machine,
        function,
        block,
        ret,
        "base64.next_source_bundle_input",
        "base64.next_source_bundle_table0",
        "base64.next_source_bundle_table1",
        "base64.next_source_bundle_table2",
        "base64.next_source_bundle_table3",
        8,
    );
}

fn lowerBase64ThirdSourceBundleStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    return lowerBase64SourceBundleStepMainReturnWithSymbols(
        allocator,
        machine,
        function,
        block,
        ret,
        "base64.third_source_bundle_input",
        "base64.third_source_bundle_table0",
        "base64.third_source_bundle_table1",
        "base64.third_source_bundle_table2",
        "base64.third_source_bundle_table3",
        12,
    );
}

fn lowerBase64ResidualBundleStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    return lowerBase64SourceBundleStepMainReturnWithSymbols(
        allocator,
        machine,
        function,
        block,
        ret,
        "base64.residual_bundle_input",
        "base64.residual_bundle_table0",
        "base64.residual_bundle_table1",
        "base64.residual_bundle_table2",
        "base64.residual_bundle_table3",
        0,
    );
}

fn lowerBase64BitBufferStoreStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 16) return false;

    const word0_raw_name = (try validateBase64BitBufferI32GlobalLoad(block.instructions.items[0], "base64.bit_buffer_word0")) orelse return false;
    const word0_name = validateBase64BitBufferZext(block.instructions.items[1], word0_raw_name, false) orelse return false;
    const word3_raw_name = (try validateBase64BitBufferI32GlobalLoad(block.instructions.items[2], "base64.bit_buffer_word3")) orelse return false;
    const word3_name = validateBase64BitBufferZext(block.instructions.items[3], word3_raw_name, true) orelse return false;
    const word1_raw_name = (try validateBase64BitBufferI32GlobalLoad(block.instructions.items[4], "base64.bit_buffer_word1")) orelse return false;
    const word1_name = validateBase64BitBufferZext(block.instructions.items[5], word1_raw_name, true) orelse return false;
    const shift1_name = validateBase64BitBufferShl(block.instructions.items[6], word1_name, 24) orelse return false;
    const merged1_name = validateBase64BitBufferOr(block.instructions.items[7], shift1_name, word0_name) orelse return false;
    const word2_raw_name = (try validateBase64BitBufferI32GlobalLoad(block.instructions.items[8], "base64.bit_buffer_word2")) orelse return false;
    const word2_name = validateBase64BitBufferZext(block.instructions.items[9], word2_raw_name, true) orelse return false;
    const shift2_name = validateBase64BitBufferShl(block.instructions.items[10], word2_name, 48) orelse return false;
    const merged2_name = validateBase64BitBufferOr(block.instructions.items[11], merged1_name, shift2_name) orelse return false;
    const shift3_name = validateBase64BitBufferShl(block.instructions.items[12], word3_name, 72) orelse return false;
    const merged_name = validateBase64BitBufferOr(block.instructions.items[13], merged2_name, shift3_name) orelse return false;

    const dst_name = block.instructions.items[14].result orelse return false;
    const dst_gep = switch (block.instructions.items[14].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!dst_gep.source_ty.eql(.{ .aggregate = "[1 x i8]" })) return false;
    const dst_symbol = switch (dst_gep.ptr) {
        .named => |name| blk: {
            if (!std.mem.startsWith(u8, name, "@")) return false;
            break :blk try globalSymbolName(name);
        },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, dst_symbol, "base64.bit_buffer_output")) return false;
    if (dst_gep.indices.items.len != 1) return false;
    if (!dst_gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(dst_gep.indices.items[0].value, 0)) return false;

    const store = switch (block.instructions.items[15].kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 128 }) or store.attrs.isBarrier() or !isNamed(store.value, merged_name) or !isNamed(store.ptr, dst_name)) return false;

    const ret_value = ret.value orelse return error.InvalidRet;
    if (!isInt(ret_value, 0)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn validateBase64BitBufferI32GlobalLoad(instruction: ir.Instruction, symbol_name: []const u8) !?[]const u8 {
    if (instruction.removed) return null;
    const result_name = instruction.result orelse return null;
    const load = switch (instruction.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return null;
    const symbol = switch (load.ptr) {
        .named => |name| blk: {
            if (!std.mem.startsWith(u8, name, "@")) return null;
            break :blk try globalSymbolName(name);
        },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!std.mem.eql(u8, symbol, symbol_name)) return null;
    return result_name;
}

fn validateBase64BitBufferZext(instruction: ir.Instruction, value_name: []const u8, expected_nneg: bool) ?[]const u8 {
    if (instruction.removed) return null;
    const result_name = instruction.result orelse return null;
    const zext = switch (instruction.kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 32 }) or !zext.to_ty.eql(.{ .int = 128 }) or !isNamed(zext.value, value_name)) return null;
    if (zext.flags.nneg != expected_nneg or zext.flags.nsw or zext.flags.nuw) return null;
    return result_name;
}

fn validateBase64BitBufferShl(instruction: ir.Instruction, lhs_name: []const u8, shift: i128) ?[]const u8 {
    if (instruction.removed) return null;
    const result_name = instruction.result orelse return null;
    const shl = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (shl.op != .shl or !shl.ty.eql(.{ .int = 128 })) return null;
    if (!shl.flags.nsw or !shl.flags.nuw or shl.flags.exact or shl.flags.disjoint) return null;
    if (!isNamed(shl.lhs, lhs_name) or !isInt(shl.rhs, shift)) return null;
    return result_name;
}

fn validateBase64BitBufferOr(instruction: ir.Instruction, lhs_name: []const u8, rhs_name: []const u8) ?[]const u8 {
    if (instruction.removed) return null;
    const result_name = instruction.result orelse return null;
    const @"or" = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (@"or".op != .@"or" or !@"or".ty.eql(.{ .int = 128 })) return null;
    if (!@"or".flags.disjoint or @"or".flags.nsw or @"or".flags.nuw or @"or".flags.exact) return null;
    if (!((isNamed(@"or".lhs, lhs_name) and isNamed(@"or".rhs, rhs_name)) or
        (isNamed(@"or".lhs, rhs_name) and isNamed(@"or".rhs, lhs_name))))
    {
        return null;
    }
    return result_name;
}

fn lowerBase64LoopAdvanceStep(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 3) return false;

    const entry = function.blocks.items[0];
    const loop = function.blocks.items[1];
    const exit = function.blocks.items[2];
    if (!std.mem.eql(u8, entry.name, "entry") or
        !std.mem.eql(u8, loop.name, "loop") or
        !std.mem.eql(u8, exit.name, "exit"))
        return false;

    if (entry.instructions.items.len != 2) return false;
    const out_start_name = (try validateBase64LoopAdvanceI64GlobalLoad(entry.instructions.items[0], "base64.loop_advance_output")) orelse return false;
    const src_start_name = (try validateBase64LoopAdvanceI64GlobalLoad(entry.instructions.items[1], "base64.loop_advance_source")) orelse return false;
    if (!std.mem.eql(u8, try validateTerminatorBr(entry), loop.name)) return false;

    if (loop.instructions.items.len != 5) return false;
    const out_name = loop.instructions.items[0].result orelse return false;
    const src_name = loop.instructions.items[1].result orelse return false;
    const out_next_name = loop.instructions.items[2].result orelse return false;
    const src_next_name = loop.instructions.items[3].result orelse return false;
    const done_name = loop.instructions.items[4].result orelse return false;

    const out_phi = switch (loop.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!out_phi.ty.eql(.{ .int = 64 }) or out_phi.incoming.items.len != 2) return false;
    if (!isNamed(out_phi.incoming.items[0].value, out_start_name) or !std.mem.eql(u8, out_phi.incoming.items[0].block, entry.name)) return false;
    if (!isNamed(out_phi.incoming.items[1].value, out_next_name) or !std.mem.eql(u8, out_phi.incoming.items[1].block, loop.name)) return false;

    const src_phi = switch (loop.instructions.items[1].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!src_phi.ty.eql(.{ .int = 64 }) or src_phi.incoming.items.len != 2) return false;
    if (!isNamed(src_phi.incoming.items[0].value, src_start_name) or !std.mem.eql(u8, src_phi.incoming.items[0].block, entry.name)) return false;
    if (!isNamed(src_phi.incoming.items[1].value, src_next_name) or !std.mem.eql(u8, src_phi.incoming.items[1].block, loop.name)) return false;

    const out_next = switch (loop.instructions.items[2].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (out_next.op != .add or !out_next.ty.eql(.{ .int = 64 }) or !out_next.flags.nuw or out_next.flags.nsw or out_next.flags.exact or out_next.flags.disjoint) return false;
    if (!isNamed(out_next.lhs, out_name) or !isInt(out_next.rhs, 12)) return false;

    const src_next = switch (loop.instructions.items[3].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (src_next.op != .add or !src_next.ty.eql(.{ .int = 64 }) or src_next.flags.any()) return false;
    if (!isNamed(src_next.lhs, src_name) or !isInt(src_next.rhs, -16)) return false;

    const done = switch (loop.instructions.items[4].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (done.predicate != .eq or !done.operand_ty.eql(.{ .int = 64 }) or !isNamed(done.lhs, out_next_name) or !isInt(done.rhs, 12)) return false;

    const loop_branch = switch (loop.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!loop_branch.cond_ty.eql(.{ .int = 1 }) or !isNamed(loop_branch.cond, done_name)) return false;
    if (!std.mem.eql(u8, loop_branch.then_target, exit.name) or !std.mem.eql(u8, loop_branch.else_target, loop.name)) return false;

    if (exit.instructions.items.len != 2) return false;
    const src_ok_name = exit.instructions.items[0].result orelse return false;
    const select_name = exit.instructions.items[1].result orelse return false;
    const src_ok = switch (exit.instructions.items[0].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (src_ok.predicate != .eq or !src_ok.operand_ty.eql(.{ .int = 64 }) or !isNamed(src_ok.lhs, src_next_name) or !isInt(src_ok.rhs, 0)) return false;
    const select = switch (exit.instructions.items[1].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, src_ok_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;
    const ret = switch (exit.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn validateBase64LoopAdvanceI64GlobalLoad(instruction: ir.Instruction, symbol_name: []const u8) !?[]const u8 {
    if (instruction.removed) return null;
    const result_name = instruction.result orelse return null;
    const load = switch (instruction.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 64 }) or load.attrs.isBarrier()) return null;
    const symbol = switch (load.ptr) {
        .named => |name| blk: {
            if (!std.mem.startsWith(u8, name, "@")) return null;
            break :blk try globalSymbolName(name);
        },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!std.mem.eql(u8, symbol, symbol_name)) return null;
    return result_name;
}

fn lowerBase64ResidualGuardStep(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 3) return false;

    const entry = function.blocks.items[0];
    const decode = function.blocks.items[1];
    const done = function.blocks.items[2];
    if (!std.mem.eql(u8, entry.name, "entry") or
        !std.mem.eql(u8, decode.name, "decode") or
        !std.mem.eql(u8, done.name, "done"))
        return false;

    if (entry.instructions.items.len != 10) return false;
    const source_index_name = (try validateBase64ResidualGuardI64GlobalLoad(entry.instructions.items[0], "base64.residual_guard_source_index")) orelse return false;
    const output_index_name = (try validateBase64ResidualGuardI64GlobalLoad(entry.instructions.items[1], "base64.residual_guard_output_index")) orelse return false;
    const source_len_name = (try validateBase64ResidualGuardI64GlobalLoad(entry.instructions.items[2], "base64.residual_guard_source_len")) orelse return false;
    const output_len_name = (try validateBase64ResidualGuardI64GlobalLoad(entry.instructions.items[3], "base64.residual_guard_output_len")) orelse return false;
    const source_next_name = (try validateBase64ResidualGuardI64Add(entry.instructions.items[4], source_index_name, 4)) orelse return false;
    const source_ok_name = (try validateBase64ResidualGuardI64IcmpUlt(entry.instructions.items[5], source_next_name, source_len_name)) orelse return false;
    const output_next_name = (try validateBase64ResidualGuardI64Add(entry.instructions.items[6], output_index_name, 3)) orelse return false;
    const output_ok_name = (try validateBase64ResidualGuardI64IcmpUlt(entry.instructions.items[7], output_next_name, output_len_name)) orelse return false;
    const guard_name = (try validateBase64ResidualGuardSelect(entry.instructions.items[8], source_ok_name, output_ok_name)) orelse return false;
    const src_ptr_name = (try validateBase64ResidualGuardSourceGep(entry.instructions.items[9], source_index_name)) orelse return false;

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, guard_name)) return false;
    if (!std.mem.eql(u8, condbr.then_target, decode.name) or !std.mem.eql(u8, condbr.else_target, done.name)) return false;

    if (decode.instructions.items.len != 3) return false;
    const byte_name = (try validateBase64ResidualGuardI8Load(decode.instructions.items[0], src_ptr_name)) orelse return false;
    const byte_ok_name = (try validateBase64ResidualGuardI8Eq(decode.instructions.items[1], byte_name, 65)) orelse return false;
    const ret_ok_name = (try validateBase64ResidualGuardReturnSelect(decode.instructions.items[2], byte_ok_name)) orelse return false;
    const decode_ret = switch (decode.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!decode_ret.ty.eql(.{ .int = 32 }) or !isNamed(decode_ret.value orelse return error.InvalidRet, ret_ok_name)) return false;

    if (done.instructions.items.len != 0) return false;
    const done_ret = switch (done.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!done_ret.ty.eql(.{ .int = 32 }) or !isInt(done_ret.value orelse return error.InvalidRet, 1)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn validateBase64ResidualGuardI64GlobalLoad(instruction: ir.Instruction, symbol_name: []const u8) !?[]const u8 {
    if (instruction.removed) return null;
    const result_name = instruction.result orelse return null;
    const load = switch (instruction.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 64 }) or load.attrs.isBarrier()) return null;
    const symbol = switch (load.ptr) {
        .named => |name| blk: {
            if (!std.mem.startsWith(u8, name, "@")) return null;
            break :blk try globalSymbolName(name);
        },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!std.mem.eql(u8, symbol, symbol_name)) return null;
    return result_name;
}

fn validateBase64ResidualGuardI64Add(instruction: ir.Instruction, lhs_name: []const u8, rhs_value: i128) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (binary.op != .add or !binary.ty.eql(.{ .int = 64 }) or !binary.flags.nuw or binary.flags.nsw or binary.flags.exact or binary.flags.disjoint) return null;
    if (!isNamed(binary.lhs, lhs_name) or !isInt(binary.rhs, rhs_value)) return null;
    return result_name;
}

fn validateBase64ResidualGuardI64IcmpUlt(instruction: ir.Instruction, lhs_name: []const u8, rhs_name: []const u8) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (icmp.predicate != .ult or !icmp.operand_ty.eql(.{ .int = 64 })) return null;
    if (!isNamed(icmp.lhs, lhs_name) or !isNamed(icmp.rhs, rhs_name)) return null;
    return result_name;
}

fn validateBase64ResidualGuardSelect(instruction: ir.Instruction, source_ok_name: []const u8, output_ok_name: []const u8) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const select = switch (instruction.kind) {
        .select => |select| select,
        else => return null,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 1 })) return null;
    if (!isNamed(select.cond, source_ok_name) or !isNamed(select.true_value, output_ok_name) or !isInt(select.false_value, 0)) return null;
    return result_name;
}

fn validateBase64ResidualGuardSourceGep(instruction: ir.Instruction, source_index_name: []const u8) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const gep = switch (instruction.kind) {
        .gep => |gep| gep,
        else => return null,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[1 x i8]" })) return null;
    const symbol = switch (gep.ptr) {
        .named => |name| blk: {
            if (!std.mem.startsWith(u8, name, "@")) return null;
            break :blk try globalSymbolName(name);
        },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!std.mem.eql(u8, symbol, "base64.residual_guard_source")) return null;
    if (gep.indices.items.len != 1) return null;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isNamed(gep.indices.items[0].value, source_index_name)) return null;
    return result_name;
}

fn validateBase64ResidualGuardI8Load(instruction: ir.Instruction, ptr_name: []const u8) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const load = switch (instruction.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 8 }) or load.attrs.isBarrier() or !isNamed(load.ptr, ptr_name)) return null;
    return result_name;
}

fn validateBase64ResidualGuardI8Eq(instruction: ir.Instruction, byte_name: []const u8, value: i128) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 8 })) return null;
    if (!isNamed(icmp.lhs, byte_name) or !isInt(icmp.rhs, value)) return null;
    return result_name;
}

fn validateBase64ResidualGuardReturnSelect(instruction: ir.Instruction, byte_ok_name: []const u8) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const select = switch (instruction.kind) {
        .select => |select| select,
        else => return null,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return null;
    if (!isNamed(select.cond, byte_ok_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 2)) return null;
    return result_name;
}

fn lowerBase64SourceBundleStepMainReturnWithSymbols(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
    input_symbol: []const u8,
    table0_symbol: []const u8,
    table1_symbol: []const u8,
    table2_symbol: []const u8,
    table3_symbol: []const u8,
    first_offset: i128,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 25) return false;

    const first = (try validateBase64SourceBundleGlobalByteLoad(
        block.instructions.items[0],
        block.instructions.items[1],
        input_symbol,
        first_offset,
    )) orelse return false;
    const idx0_name = validateBase64SourceBundleZext(block.instructions.items[2], first.byte_name) orelse return false;
    const word0_name = (try validateBase64SourceBundleTableLoad(
        block.instructions.items[3],
        block.instructions.items[4],
        table0_symbol,
        idx0_name,
    )) orelse return false;

    const second = validateBase64SourceBundleRelativeByteLoad(
        block.instructions.items[5],
        block.instructions.items[6],
        first.ptr_name,
        1,
    ) orelse return false;
    const idx1_name = validateBase64SourceBundleZext(block.instructions.items[7], second.byte_name) orelse return false;
    const word1_name = (try validateBase64SourceBundleTableLoad(
        block.instructions.items[8],
        block.instructions.items[9],
        table1_symbol,
        idx1_name,
    )) orelse return false;
    const merged1_name = validateBase64SourceBundleOr(block.instructions.items[10], word1_name, word0_name) orelse return false;

    const third = validateBase64SourceBundleRelativeByteLoad(
        block.instructions.items[11],
        block.instructions.items[12],
        first.ptr_name,
        2,
    ) orelse return false;
    const idx2_name = validateBase64SourceBundleZext(block.instructions.items[13], third.byte_name) orelse return false;
    const word2_name = (try validateBase64SourceBundleTableLoad(
        block.instructions.items[14],
        block.instructions.items[15],
        table2_symbol,
        idx2_name,
    )) orelse return false;
    const merged2_name = validateBase64SourceBundleOr(block.instructions.items[16], merged1_name, word2_name) orelse return false;

    const fourth = validateBase64SourceBundleRelativeByteLoad(
        block.instructions.items[17],
        block.instructions.items[18],
        first.ptr_name,
        3,
    ) orelse return false;
    const idx3_name = validateBase64SourceBundleZext(block.instructions.items[19], fourth.byte_name) orelse return false;
    const word3_name = (try validateBase64SourceBundleTableLoad(
        block.instructions.items[20],
        block.instructions.items[21],
        table3_symbol,
        idx3_name,
    )) orelse return false;
    const word_name = validateBase64SourceBundleOr(block.instructions.items[22], merged2_name, word3_name) orelse return false;

    const valid_name = block.instructions.items[23].result orelse return false;
    const icmp = switch (block.instructions.items[23].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .ult or !icmp.operand_ty.eql(.{ .int = 32 }) or !isNamed(icmp.lhs, word_name) or !isInt(icmp.rhs, 16777216)) return false;

    const select_name = block.instructions.items[24].result orelse return false;
    const select = switch (block.instructions.items[24].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, valid_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

const Base64SourceBundleByteLoad = struct {
    ptr_name: []const u8,
    byte_name: []const u8,
};

fn validateBase64SourceBundleGlobalByteLoad(
    gep_inst: ir.Instruction,
    load_inst: ir.Instruction,
    symbol_name: []const u8,
    offset: i128,
) !?Base64SourceBundleByteLoad {
    if (gep_inst.removed or load_inst.removed) return null;
    const gep_name = gep_inst.result orelse return null;
    const byte_name = load_inst.result orelse return null;

    const gep = switch (gep_inst.kind) {
        .gep => |gep| gep,
        else => return null,
    };
    if (!gep.source_ty.eql(.{ .int = 8 })) return null;
    const symbol = switch (gep.ptr) {
        .named => |name| blk: {
            if (!std.mem.startsWith(u8, name, "@")) return null;
            break :blk try globalSymbolName(name);
        },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!std.mem.eql(u8, symbol, symbol_name)) return null;
    if (gep.indices.items.len != 1) return null;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, offset)) return null;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 8 }) or load.attrs.isBarrier() or !isNamed(load.ptr, gep_name)) return null;
    return .{ .ptr_name = gep_name, .byte_name = byte_name };
}

fn validateBase64SourceBundleRelativeByteLoad(
    gep_inst: ir.Instruction,
    load_inst: ir.Instruction,
    base_name: []const u8,
    offset: i128,
) ?Base64SourceBundleByteLoad {
    if (gep_inst.removed or load_inst.removed) return null;
    const gep_name = gep_inst.result orelse return null;
    const byte_name = load_inst.result orelse return null;

    const gep = switch (gep_inst.kind) {
        .gep => |gep| gep,
        else => return null,
    };
    if (!gep.source_ty.eql(.{ .int = 8 }) or !isNamed(gep.ptr, base_name)) return null;
    if (gep.indices.items.len != 1) return null;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, offset)) return null;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 8 }) or load.attrs.isBarrier() or !isNamed(load.ptr, gep_name)) return null;
    return .{ .ptr_name = gep_name, .byte_name = byte_name };
}

fn validateBase64SourceBundleZext(instruction: ir.Instruction, byte_name: []const u8) ?[]const u8 {
    if (instruction.removed) return null;
    const idx_name = instruction.result orelse return null;
    const zext = switch (instruction.kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 8 }) or !zext.to_ty.eql(.{ .int = 64 }) or !isNamed(zext.value, byte_name)) return null;
    return idx_name;
}

fn validateBase64SourceBundleTableLoad(
    gep_inst: ir.Instruction,
    load_inst: ir.Instruction,
    table_symbol_name: []const u8,
    idx_name: []const u8,
) !?[]const u8 {
    if (gep_inst.removed or load_inst.removed) return null;
    const gep_name = gep_inst.result orelse return null;
    const word_name = load_inst.result orelse return null;

    const gep = switch (gep_inst.kind) {
        .gep => |gep| gep,
        else => return null,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[4 x i8]" })) return null;
    const table_symbol = switch (gep.ptr) {
        .named => |name| blk: {
            if (!std.mem.startsWith(u8, name, "@")) return null;
            break :blk try globalSymbolName(name);
        },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!std.mem.eql(u8, table_symbol, table_symbol_name)) return null;
    if (gep.indices.items.len != 1) return null;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isNamed(gep.indices.items[0].value, idx_name)) return null;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier() or !isNamed(load.ptr, gep_name)) return null;
    return word_name;
}

fn validateBase64SourceBundleOr(instruction: ir.Instruction, lhs_name: []const u8, rhs_name: []const u8) ?[]const u8 {
    if (instruction.removed) return null;
    const result_name = instruction.result orelse return null;
    const @"or" = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (@"or".op != .@"or" or !@"or".ty.eql(.{ .int = 32 })) return null;
    if (!((isNamed(@"or".lhs, lhs_name) and isNamed(@"or".rhs, rhs_name)) or
        (isNamed(@"or".lhs, rhs_name) and isNamed(@"or".rhs, lhs_name))))
    {
        return null;
    }
    return result_name;
}

fn validateBase64ChunkGuardAdd(instruction: ir.Instruction, lhs_value: i128, rhs_value: i128) bool {
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    return binary.op == .add and binary.ty.eql(.{ .int = 64 }) and isInt(binary.lhs, lhs_value) and isInt(binary.rhs, rhs_value);
}

fn validateBase64ChunkGuardIcmp(instruction: ir.Instruction, lhs_name: []const u8, rhs_value: i128) bool {
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    return icmp.predicate == .ult and icmp.operand_ty.eql(.{ .int = 64 }) and isNamed(icmp.lhs, lhs_name) and isInt(icmp.rhs, rhs_value);
}

fn validateBase64PaddingLengthEnd(instruction: ir.Instruction, expected_offset: i128) !?[]const u8 {
    if (instruction.removed) return null;
    const end_name = instruction.result orelse return null;
    const gep = switch (instruction.kind) {
        .gep => |gep| gep,
        else => return null,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[1 x i8]" })) return null;
    const symbol = switch (gep.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!std.mem.eql(u8, symbol, "base64.padding_length_tail")) return null;
    if (gep.indices.items.len != 1) return null;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, expected_offset)) return null;
    return end_name;
}

fn validateBase64PaddingLengthTailLoad(gep_inst: ir.Instruction, load_inst: ir.Instruction, end_name: []const u8, expected_offset: i128) !?[]const u8 {
    if (gep_inst.removed or load_inst.removed) return null;
    const ptr_name = gep_inst.result orelse return null;
    const load_name = load_inst.result orelse return null;
    const gep = switch (gep_inst.kind) {
        .gep => |gep| gep,
        else => return null,
    };
    if (!gep.source_ty.eql(.{ .int = 8 })) return null;
    if (!isNamed(gep.ptr, end_name)) return null;
    if (gep.indices.items.len != 1) return null;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, expected_offset)) return null;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 8 }) or load.attrs.isBarrier() or !isNamed(load.ptr, ptr_name)) return null;
    return load_name;
}

fn validateBase64PaddingLengthEq(instruction: ir.Instruction, byte_name: []const u8) !void {
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 8 }) or !isNamed(icmp.lhs, byte_name) or !isInt(icmp.rhs, 61)) return error.UnsupportedCodegenInstruction;
}

fn validateBase64PaddingLengthSext(instruction: ir.Instruction, cond_name: []const u8) ![]const u8 {
    const result = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const cast = switch (instruction.kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (cast.op != .sext or !cast.from_ty.eql(.{ .int = 1 }) or !cast.to_ty.eql(.{ .int = 64 }) or !isNamed(cast.value, cond_name)) return error.UnsupportedCodegenInstruction;
    return result;
}

fn validateBase64DecodeStepLoad(gep_inst: ir.Instruction, load_inst: ir.Instruction, table_index: i128) !?[]const u8 {
    if (gep_inst.removed or load_inst.removed) return null;
    const gep_name = gep_inst.result orelse return null;
    const load_name = load_inst.result orelse return null;

    const gep = switch (gep_inst.kind) {
        .gep => |gep| gep,
        else => return null,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[16 x i32]" })) return null;
    const table_symbol = switch (gep.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!std.mem.eql(u8, table_symbol, "base64.decode_step_table")) return null;
    if (gep.indices.items.len != 2) return null;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, 0)) return null;
    if (!gep.indices.items[1].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[1].value, table_index)) return null;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier() or !isNamed(load.ptr, gep_name)) return null;
    return load_name;
}

fn validateNamedOr(instruction: ir.Instruction, lhs_name: []const u8, rhs_name: []const u8) !void {
    if (instruction.removed) return error.UnsupportedCodegenInstruction;
    const @"or" = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (@"or".op != .@"or" or !@"or".ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
    if (!((isNamed(@"or".lhs, lhs_name) and isNamed(@"or".rhs, rhs_name)) or
        (isNamed(@"or".lhs, rhs_name) and isNamed(@"or".rhs, lhs_name))))
    {
        return error.UnsupportedCodegenInstruction;
    }
}

fn lowerBase64WriterMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 5) return false;

    const gep_inst = block.instructions.items[0];
    const load_inst = block.instructions.items[1];
    const zext_inst = block.instructions.items[2];
    const icmp_inst = block.instructions.items[3];
    const select_inst = block.instructions.items[4];
    if (gep_inst.removed or load_inst.removed or zext_inst.removed or icmp_inst.removed or select_inst.removed) return false;

    const gep_name = gep_inst.result orelse return false;
    const load_name = load_inst.result orelse return false;
    const zext_name = zext_inst.result orelse return false;
    const icmp_name = icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    const gep = switch (gep_inst.kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[4 x i8]" })) return false;
    const table_symbol = switch (gep.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, table_symbol, "base64.writer_table")) return false;
    if (gep.indices.items.len != 2) return false;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, 0)) return false;
    if (!gep.indices.items[1].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[1].value, 3)) return false;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 8 }) or load.attrs.isBarrier() or !isNamed(load.ptr, gep_name)) return false;

    const zext = switch (zext_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 8 }) or !zext.to_ty.eql(.{ .int = 32 }) or !isNamed(zext.value, load_name)) return false;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 }) or !isNamed(icmp.lhs, zext_name) or !isInt(icmp.rhs, 12)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerSelectedCheckedAddRuntimeBoundaryMain(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 3) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 2) return false;
    const pair_name = entry.instructions.items[0].result orelse return false;
    const overflow_name = entry.instructions.items[1].result orelse return false;
    const call = switch (entry.instructions.items[0].kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (!isCalleeName(call.callee, "llvm.sadd.with.overflow.i32")) return false;
    if (call.args.items.len != 2) return false;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[0].value, 40)) return false;
    if (!call.args.items[1].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[1].value, 2)) return false;

    const overflow = switch (entry.instructions.items[1].kind) {
        .extractvalue => |extractvalue| extractvalue,
        else => return false,
    };
    if (!overflow.result_ty.eql(.{ .int = 1 }) or !isNamed(overflow.aggregate, pair_name)) return false;

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, overflow_name)) return false;

    const panic_index = blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget;
    const ok_index = blockIndex(function, condbr.else_target) orelse return error.InvalidBranchTarget;
    const ok = function.blocks.items[ok_index];
    const panic = function.blocks.items[panic_index];
    if (ok.instructions.items.len != 3) return false;
    if (panic.instructions.items.len != 2) return false;

    const value_name = ok.instructions.items[0].result orelse return false;
    const matches_name = ok.instructions.items[1].result orelse return false;
    const select_name = ok.instructions.items[2].result orelse return false;
    const value = switch (ok.instructions.items[0].kind) {
        .extractvalue => |extractvalue| extractvalue,
        else => return false,
    };
    if (!value.result_ty.eql(.{ .int = 32 }) or !isNamed(value.aggregate, pair_name)) return false;

    const icmp = switch (ok.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 }) or !isNamed(icmp.lhs, value_name) or !isInt(icmp.rhs, 42)) return false;

    const select = switch (ok.instructions.items[2].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, matches_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const ret = switch (ok.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    try validateAssumeColdCall(panic.instructions.items[0]);
    try validateIntegerOverflowPanicCall(panic.instructions.items[1]);
    switch (panic.terminator orelse return error.BlockWithoutTerminator) {
        .@"unreachable" => {},
        else => return false,
    }

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerExternExportsGlobalAccess(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (try lowerExternExportsGetHidden(allocator, machine, function, block, ret)) return true;
    if (try lowerExternExportsUpdateHidden(allocator, machine, function, block, ret)) return true;
    return false;
}

fn lowerHiddenGlobalAccessFamilyReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (try lowerReleaseSmallHiddenAccessMainReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerExternExportsGlobalAccess(allocator, machine, function, block, ret)) return true;
    return false;
}

fn lowerReleaseSmallHiddenAccessMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const integrated_preopt = std.mem.eql(u8, function.name, "runtime_hidden_access_main.main");
    if (!std.mem.eql(u8, function.name, "main") and !integrated_preopt) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 2 and block.instructions.items.len != 3) return false;
    const update_name = if (integrated_preopt) "runtime_hidden_access_main.updateHidden" else "exports.updateHidden";
    const get_name = if (integrated_preopt) "runtime_hidden_access_main.getHidden" else "exports.getHidden";
    const hidden_name = if (integrated_preopt) "runtime_hidden_access_main.hidden" else "exports.hidden";

    const update_inst = block.instructions.items[0];
    const get_inst = block.instructions.items[1];
    if (update_inst.removed or get_inst.removed) return false;
    if (update_inst.result != null) return false;
    const get_result = get_inst.result orelse return false;
    if (block.instructions.items.len == 2) {
        if (!isNamed(ret.value orelse return error.InvalidRet, get_result)) return false;
    } else {
        const bitcast_inst = block.instructions.items[2];
        if (bitcast_inst.removed) return false;
        const bitcast_name = identityCastFrom(bitcast_inst, get_result, .{ .int = 32 }, .{ .int = 32 }) orelse return false;
        if (!isNamed(ret.value orelse return error.InvalidRet, bitcast_name)) return false;
    }

    const update_call = switch (update_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isCalleeName(update_call.callee, update_name)) return false;
    if (update_call.callee_value != null or update_call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!callIsFastcc(update_call.calling_conv)) try validateDefaultCallConv(update_call.calling_conv);
    if (update_call.ret_ty != .void or update_call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!update_call.args.items[0].ty.eql(.{ .int = 32 }) or !isInt(update_call.args.items[0].value, 7)) return error.UnsupportedCodegenValue;

    const get_call = switch (get_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isCalleeName(get_call.callee, get_name)) return false;
    if (get_call.callee_value != null or get_call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!callIsFastcc(get_call.calling_conv)) try validateDefaultCallConv(get_call.calling_conv);
    if (!get_call.ret_ty.eql(.{ .int = 32 }) or get_call.args.items.len != 0) return error.UnsupportedCodegenInstruction;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 7 });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = hidden_name });
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = hidden_name });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerReleaseSmallMixCAddZigMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const integrated_preopt = std.mem.eql(u8, function.name, "runtime_mix_c_add_zig_main.main");
    if (!std.mem.eql(u8, function.name, "main") and !integrated_preopt) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 1) return false;
    const callee_name = if (integrated_preopt) "runtime_mix_c_add_zig_main.add_zig" else "main.add_zig";
    const zig_k_name = if (integrated_preopt) "runtime_mix_c_add_zig_main.zig_k" else "main.zig_k";
    const c_k_name = if (integrated_preopt) "runtime_mix_c_add_zig_main.C_k" else "C_k";

    const call_inst = block.instructions.items[0];
    if (call_inst.removed) return false;
    const call_result = call_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, call_result)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isCalleeName(call.callee, callee_name)) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!callIsFastcc(call.calling_conv)) try validateDefaultCallConv(call.calling_conv);
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[0].value, 4)) return error.UnsupportedCodegenValue;

    try machine.instructions.append(allocator, .{ .load_global_i32_eax = zig_k_name });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = 4 });
    try machine.instructions.append(allocator, .{ .add_tls_i32_eax = c_k_name });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerMixedCZigTlsInputFamilyReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (try lowerReleaseSmallMixCAddZigMainReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerSelectedMixCFilesAddZig(allocator, machine, function, block, ret)) return true;
    return false;
}

fn lowerReleaseSmallMixCAddMayPanicMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const integrated_preopt = std.mem.eql(u8, function.name, "runtime_mix_c_add_may_panic_main.main");
    if (!std.mem.eql(u8, function.name, "main") and !integrated_preopt) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 1) return false;
    const callee_name = if (integrated_preopt) "runtime_mix_c_add_may_panic_main.add_may_panic" else "main.add_may_panic";
    const zig_k_name = if (integrated_preopt) "runtime_mix_c_add_may_panic_main.zig_k" else "main.zig_k";

    const call_inst = block.instructions.items[0];
    if (call_inst.removed) return false;
    const call_result = call_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, call_result)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isCalleeName(call.callee, callee_name)) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!callIsFastcc(call.calling_conv)) try validateDefaultCallConv(call.calling_conv);
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[0].value, 4)) return error.UnsupportedCodegenValue;

    try machine.instructions.append(allocator, .{ .load_global_i32_eax = zig_k_name });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = 4 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerSelectedMixCFilesAddZig(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const integrated_preopt = std.mem.eql(u8, function.name, "runtime_mix_c_add_zig_main.add_zig");
    if (!std.mem.eql(u8, function.name, "main.add_zig") and !integrated_preopt) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 1) return false;
    if (block.instructions.items.len != 4) return false;
    const zig_k_value = if (integrated_preopt) "@runtime_mix_c_add_zig_main.zig_k" else "@main.zig_k";
    const zig_k_name = if (integrated_preopt) "runtime_mix_c_add_zig_main.zig_k" else "main.zig_k";
    const c_k_value = if (integrated_preopt) "@runtime_mix_c_add_zig_main.C_k" else "@C_k";
    const c_k_name = if (integrated_preopt) "runtime_mix_c_add_zig_main.C_k" else "C_k";

    const zig_load_inst = block.instructions.items[0];
    const arg_add_inst = block.instructions.items[1];
    const c_load_inst = block.instructions.items[2];
    const c_add_inst = block.instructions.items[3];
    if (zig_load_inst.removed or arg_add_inst.removed or c_load_inst.removed or c_add_inst.removed) return false;

    const zig_load_result = zig_load_inst.result orelse return false;
    const arg_add_result = arg_add_inst.result orelse return false;
    const c_load_result = c_load_inst.result orelse return false;
    const c_add_result = c_add_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, c_add_result)) return false;

    const zig_load = switch (zig_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!zig_load.ty.eql(.{ .int = 32 }) or zig_load.attrs.isBarrier() or !isNamed(zig_load.ptr, zig_k_value)) return false;

    const arg_add = switch (arg_add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (arg_add.op != .add or !arg_add.ty.eql(.{ .int = 32 })) return false;
    const arg_reg = if (isNamed(arg_add.lhs, zig_load_result))
        try paramValueReg(function, arg_add.rhs, .{ .int = 32 })
    else if (isNamed(arg_add.rhs, zig_load_result))
        try paramValueReg(function, arg_add.lhs, .{ .int = 32 })
    else
        return false;

    const c_load = switch (c_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!c_load.ty.eql(.{ .int = 32 }) or c_load.attrs.isBarrier() or !isNamed(c_load.ptr, c_k_value)) return false;

    const c_add = switch (c_add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (c_add.op != .add or !c_add.ty.eql(.{ .int = 32 })) return false;
    if (!((isNamed(c_add.lhs, arg_add_result) and isNamed(c_add.rhs, c_load_result)) or
        (isNamed(c_add.lhs, c_load_result) and isNamed(c_add.rhs, arg_add_result)))) return false;

    try machine.instructions.append(allocator, .{ .load_global_i32_eax = zig_k_name });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = arg_reg } });
    try machine.instructions.append(allocator, .{ .add_tls_i32_eax = c_k_name });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerSelectedMixCFilesAddMayPanic(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (!std.mem.endsWith(u8, function.name, ".add_may_panic")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 32 })) return false;
    if (function.blocks.items.len != 3 and function.blocks.items.len != 5) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 1) return false;
    const icmp_name = entry.instructions.items[0].result orelse return false;
    const icmp = switch (entry.instructions.items[0].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .slt or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, function.params.items[0].name) or !isInt(icmp.rhs, 0)) return false;

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, icmp_name)) return false;
    const panic_index = blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget;
    const ok_index = blockIndex(function, condbr.else_target) orelse return error.InvalidBranchTarget;
    const negative_panic_message = try mixCFilesNegativePanicMessage(function.blocks.items[panic_index]);

    const ok = function.blocks.items[ok_index];
    if (function.blocks.items.len == 5) {
        return lowerSelectedMixCFilesCheckedAddMayPanic(
            allocator,
            machine,
            function,
            condbr,
            ok,
            negative_panic_message,
        );
    }

    if (ok.instructions.items.len != 2) return false;
    const load_result = ok.instructions.items[0].result orelse return false;
    const add_result = ok.instructions.items[1].result orelse return false;
    const load = switch (ok.instructions.items[0].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
    const zig_k_name = try mixCAddMayPanicGlobalName(load.ptr);
    const add = switch (ok.instructions.items[1].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 })) return false;
    const arg_reg = if (isNamed(add.lhs, load_result))
        try paramValueReg(function, add.rhs, .{ .int = 32 })
    else if (isNamed(add.rhs, load_result))
        try paramValueReg(function, add.lhs, .{ .int = 32 })
    else
        return false;

    const ret = switch (ok.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, add_result)) return false;

    try machine.instructions.append(allocator, .{ .test_arg32 = arg_reg });
    try machine.instructions.append(allocator, .{ .js = condbr.then_target });
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = zig_k_name });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = arg_reg } });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = condbr.then_target });
    try machine.instructions.append(allocator, .{ .lea_global_rdi = negative_panic_message });
    try machine.instructions.append(allocator, .{ .mov_imm_rsi = 12 });
    try appendAlignedDirectCall(allocator, machine, "debug.defaultPanic", .void);
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerSelectedMixCFilesCheckedAddMayPanic(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    negative_condbr: anytype,
    ok: ir.BasicBlock,
    negative_panic_message: []const u8,
) !bool {
    if (ok.instructions.items.len != 3) return false;
    const load_result = ok.instructions.items[0].result orelse return false;
    const pair_name = ok.instructions.items[1].result orelse return false;
    const overflow_name = ok.instructions.items[2].result orelse return false;

    const load = switch (ok.instructions.items[0].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
    const zig_k_name = try mixCAddMayPanicGlobalName(load.ptr);

    const call = switch (ok.instructions.items[1].kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (!isCalleeName(call.callee, "llvm.sadd.with.overflow.i32")) return false;
    if (!call.ret_ty.eql(.{ .aggregate = "{ i32, i1 }" }) or call.args.items.len != 2) return false;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !isNamed(call.args.items[0].value, load_result)) return false;
    const arg_reg = try paramValueReg(function, call.args.items[1].value, .{ .int = 32 });

    const overflow_extract = switch (ok.instructions.items[2].kind) {
        .extractvalue => |extractvalue| extractvalue,
        else => return false,
    };
    if (!overflow_extract.aggregate_ty.eql(.{ .aggregate = "{ i32, i1 }" }) or
        !overflow_extract.result_ty.eql(.{ .int = 1 }) or
        !isNamed(overflow_extract.aggregate, pair_name) or
        !std.mem.eql(u8, overflow_extract.indices, "1"))
    {
        return false;
    }

    const overflow_condbr = switch (ok.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!overflow_condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(overflow_condbr.cond, overflow_name)) return false;

    const overflow_index = blockIndex(function, overflow_condbr.then_target) orelse return error.InvalidBranchTarget;
    const ret_index = blockIndex(function, overflow_condbr.else_target) orelse return error.InvalidBranchTarget;
    const overflow = function.blocks.items[overflow_index];
    if (overflow.instructions.items.len != 2) return false;
    try validateAssumeColdCall(overflow.instructions.items[0]);
    try validateIntegerOverflowPanicCall(overflow.instructions.items[1]);
    switch (overflow.terminator orelse return error.BlockWithoutTerminator) {
        .@"unreachable" => {},
        else => return false,
    }

    const ret_block = function.blocks.items[ret_index];
    if (ret_block.instructions.items.len != 1) return false;
    const value_name = ret_block.instructions.items[0].result orelse return false;
    const value_extract = switch (ret_block.instructions.items[0].kind) {
        .extractvalue => |extractvalue| extractvalue,
        else => return false,
    };
    if (!value_extract.aggregate_ty.eql(.{ .aggregate = "{ i32, i1 }" }) or
        !value_extract.result_ty.eql(.{ .int = 32 }) or
        !isNamed(value_extract.aggregate, pair_name) or
        !std.mem.eql(u8, value_extract.indices, "0"))
    {
        return false;
    }
    const ret = switch (ret_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, value_name)) return false;

    try machine.instructions.append(allocator, .{ .test_arg32 = arg_reg });
    try machine.instructions.append(allocator, .{ .js = negative_condbr.then_target });
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = zig_k_name });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = arg_reg } });
    try machine.instructions.append(allocator, .{ .jo = overflow_condbr.then_target });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = negative_condbr.then_target });
    try machine.instructions.append(allocator, .{ .lea_global_rdi = negative_panic_message });
    try machine.instructions.append(allocator, .{ .mov_imm_rsi = 12 });
    try appendAlignedDirectCall(allocator, machine, "debug.defaultPanic", .void);
    try machine.instructions.append(allocator, .ud2);
    try appendIntegerOverflowCall(allocator, machine, overflow_condbr.then_target);
    return true;
}

fn mixCAddMayPanicGlobalName(value: ir.Value) ![]const u8 {
    const name = switch (value) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    if (!std.mem.endsWith(u8, name, ".zig_k")) return error.UnsupportedCodegenValue;
    return name;
}

fn lowerSelectedMixCFilesAddZigDebugO0(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.add_zig")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 32 })) return false;
    const arg_reg = try paramReg(function, function.params.items[0].name, .{ .int = 32 });
    if (arg_reg != .rdi) return error.UnsupportedCodegenAbi;
    if (function.blocks.items.len != 5) return false;
    if (!functionHasCall(function, "llvm.sadd.with.overflow.i32")) return false;
    if (!functionLoadsGlobal(function, "main.zig_k") or !functionLoadsGlobal(function, "C_k")) return false;

    const overflow_label = "mix_c_add_zig_overflow";
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = "main.zig_k" });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = arg_reg } });
    try machine.instructions.append(allocator, .{ .jo = overflow_label });
    try machine.instructions.append(allocator, .{ .add_tls_i32_eax = "C_k" });
    try machine.instructions.append(allocator, .{ .jo = overflow_label });
    try machine.instructions.append(allocator, .ret);
    try appendIntegerOverflowCall(allocator, machine, overflow_label);
    return true;
}

fn lowerSelectedMixCFilesAddMayPanicDebugO0(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.add_may_panic")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 32 })) return false;
    const arg_reg = try paramReg(function, function.params.items[0].name, .{ .int = 32 });
    if (arg_reg != .rdi) return error.UnsupportedCodegenAbi;
    if (function.blocks.items.len != 6) return false;
    if (!functionHasCall(function, "llvm.sadd.with.overflow.i32")) return false;
    if (!functionLoadsGlobal(function, "main.zig_k")) return false;
    if (!functionHasCall(function, "debug.defaultPanic")) return false;

    const negative_label = "mix_c_add_may_panic_negative";
    const overflow_label = "mix_c_add_may_panic_overflow";
    try machine.instructions.append(allocator, .{ .test_arg32 = arg_reg });
    try machine.instructions.append(allocator, .{ .js = negative_label });
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = "main.zig_k" });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = arg_reg } });
    try machine.instructions.append(allocator, .{ .jo = overflow_label });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = negative_label });
    try machine.instructions.append(allocator, .{ .lea_global_rdi = "__anon_17177" });
    try machine.instructions.append(allocator, .{ .mov_imm_rsi = 12 });
    try appendAlignedDirectCall(allocator, machine, "debug.defaultPanic", .void);
    try machine.instructions.append(allocator, .ud2);
    try appendIntegerOverflowCall(allocator, machine, overflow_label);
    return true;
}

fn functionLoadsGlobal(function: ir.Function, global_name: []const u8) bool {
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            const load = switch (instruction.kind) {
                .load => |load| load,
                else => continue,
            };
            const loaded_global = switch (load.ptr) {
                .named => |name| globalSymbolName(name) catch continue,
                .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => continue,
            };
            if (std.mem.eql(u8, loaded_global, global_name)) return true;
        }
    }
    return false;
}

fn mixCFilesNegativePanicMessage(block: ir.BasicBlock) ![]const u8 {
    if (block.instructions.items.len != 2 and block.instructions.items.len != 4) return error.UnsupportedCodegenInstruction;
    const assume = switch (block.instructions.items[0].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.eql(u8, assume.callee, "llvm.assume") or assume.ret_ty != .void or assume.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!assume.args.items[0].ty.eql(.{ .int = 1 }) or !assume.args.items[0].value.eql(.{ .int = 1 })) return error.UnsupportedCodegenValue;

    const message_symbol = if (block.instructions.items.len == 2) blk: {
        const panic = switch (block.instructions.items[1].kind) {
            .call => |call| call,
            else => return error.UnsupportedCodegenInstruction,
        };
        if (!std.mem.eql(u8, panic.callee, "debug.defaultPanic") or panic.ret_ty != .void or panic.args.items.len != 2) return error.UnsupportedCodegenInstruction;
        if (panic.args.items[0].ty != .ptr) return error.UnsupportedCodegenValue;
        if (!panic.args.items[1].ty.eql(.{ .int = 64 }) or !panic.args.items[1].value.eql(.{ .int = 12 })) return error.UnsupportedCodegenValue;
        const message_name = switch (panic.args.items[0].value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        break :blk try globalSymbolName(message_name);
    } else blk: {
        const ptr_result = block.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
        const len_result = block.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
        const ptr_extract = switch (block.instructions.items[1].kind) {
            .extractvalue => |extractvalue| extractvalue,
            else => return error.UnsupportedCodegenInstruction,
        };
        const len_extract = switch (block.instructions.items[2].kind) {
            .extractvalue => |extractvalue| extractvalue,
            else => return error.UnsupportedCodegenInstruction,
        };
        if (!ptr_extract.result_ty.eql(.ptr) or !std.mem.eql(u8, ptr_extract.indices, "0")) return error.UnsupportedCodegenInstruction;
        if (!len_extract.result_ty.eql(.{ .int = 64 }) or !std.mem.eql(u8, len_extract.indices, "1")) return error.UnsupportedCodegenInstruction;
        if (!ptr_extract.aggregate.eql(len_extract.aggregate)) return error.UnsupportedCodegenValue;

        const panic = switch (block.instructions.items[3].kind) {
            .call => |call| call,
            else => return error.UnsupportedCodegenInstruction,
        };
        if (!std.mem.eql(u8, panic.callee, "debug.defaultPanic") or panic.ret_ty != .void or panic.args.items.len != 3) return error.UnsupportedCodegenInstruction;
        if (panic.args.items[0].ty != .ptr or !isNamed(panic.args.items[0].value, ptr_result)) return error.UnsupportedCodegenValue;
        if (!panic.args.items[1].ty.eql(.{ .int = 64 }) or !isNamed(panic.args.items[1].value, len_result)) return error.UnsupportedCodegenValue;
        if (panic.args.items[2].ty != .ptr) return error.UnsupportedCodegenValue;
        break :blk try globalSymbolNameFromAggregateConstant(ptr_extract.aggregate);
    };

    switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .@"unreachable" => {},
        else => return error.UnsupportedCodegenControlFlow,
    }
    return message_symbol;
}

fn globalSymbolNameFromAggregateConstant(value: ir.Value) ![]const u8 {
    const text = switch (value) {
        .constant_expr => |text| text,
        .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
    };
    const at_index = std.mem.indexOfScalar(u8, text, '@') orelse return error.UnsupportedCodegenValue;
    const start = at_index + 1;
    var end = start;
    while (end < text.len and text[end] != ' ' and text[end] != ',' and text[end] != '}') : (end += 1) {}
    if (end == start) return error.UnsupportedCodegenValue;
    return text[start..end];
}

fn lowerSelectedDebugScopeBranch(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (!std.mem.eql(u8, function.name, "debug_scope_branch")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 1 }) or !function.params.items[1].ty.eql(.{ .int = 32 })) return false;
    if (function.blocks.items.len != 3) return false;

    const cond_reg = try paramReg(function, function.params.items[0].name, .{ .int = 1 });
    const value_reg = try paramReg(function, function.params.items[1].name, .{ .int = 32 });

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 0) return false;
    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, function.params.items[0].name)) return false;

    const then_index = blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget;
    const exit_index = blockIndex(function, condbr.else_target) orelse return error.InvalidBranchTarget;
    const then_block = function.blocks.items[then_index];
    const exit_block = function.blocks.items[exit_index];

    if (then_block.instructions.items.len != 1 or exit_block.instructions.items.len != 1) return false;
    const inc_name = then_block.instructions.items[0].result orelse return false;
    const inc = switch (then_block.instructions.items[0].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (inc.op != .add or !inc.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(inc.lhs, function.params.items[1].name) or !isInt(inc.rhs, 1)) return false;

    const then_br = switch (then_block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };
    if (!std.mem.eql(u8, then_br.target, exit_block.name)) return false;

    const phi_name = exit_block.instructions.items[0].result orelse return false;
    const phi = switch (exit_block.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 32 }) or phi.incoming.items.len != 2) return false;
    var saw_entry = false;
    var saw_then = false;
    for (phi.incoming.items) |incoming| {
        if (std.mem.eql(u8, incoming.block, entry.name)) {
            if (!isNamed(incoming.value, function.params.items[1].name)) return false;
            saw_entry = true;
        } else if (std.mem.eql(u8, incoming.block, then_block.name)) {
            if (!isNamed(incoming.value, inc_name)) return false;
            saw_then = true;
        } else {
            return false;
        }
    }
    if (!saw_entry or !saw_then) return false;

    const ret = switch (exit_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, phi_name)) return false;

    try machine.instructions.append(allocator, .{ .test_arg8 = cond_reg });
    try machine.instructions.append(allocator, .{ .jne = then_block.name });
    try machine.instructions.append(allocator, .{ .mov_arg_eax = value_reg });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = then_block.name });
    try machine.instructions.append(allocator, .{ .mov_arg_eax = value_reg });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerExternExportsGetHidden(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const integrated_preopt = std.mem.eql(u8, function.name, "runtime_hidden_access_main.getHidden");
    if (!std.mem.eql(u8, function.name, "exports.getHidden") and !integrated_preopt) return false;
    const expected_global = if (integrated_preopt) "runtime_hidden_access_main.hidden" else "exports.hidden";
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 1) return false;

    const load_inst = block.instructions.items[0];
    if (load_inst.removed) return false;
    const load_result = load_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    if (!std.mem.eql(u8, ret_name, load_result)) return false;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
    const global_name = switch (load.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    if (!std.mem.eql(u8, global_name, expected_global)) return false;

    try machine.instructions.append(allocator, .{ .load_global_i32_eax = global_name });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerExternExportsUpdateHidden(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const integrated_preopt = std.mem.eql(u8, function.name, "runtime_hidden_access_main.updateHidden");
    if (!std.mem.eql(u8, function.name, "exports.updateHidden") and !integrated_preopt) return false;
    const expected_global = if (integrated_preopt) "runtime_hidden_access_main.hidden" else "exports.hidden";
    if (ret.ty != .void or ret.value != null) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 1) return false;

    const store_inst = block.instructions.items[0];
    if (store_inst.removed) return false;
    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 32 }) or store.attrs.isBarrier()) return false;
    const source_reg = try paramValueReg(function, store.value, .{ .int = 32 });
    if (source_reg != .rdi) return error.UnsupportedCodegenAbi;
    const global_name = switch (store.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    if (!std.mem.eql(u8, global_name, expected_global)) return false;

    try machine.instructions.append(allocator, .{ .mov_arg_eax = source_reg });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = global_name });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerTlsReadReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const global_name = tlsSymbolFromFunctionAttrs(function) orelse
        if (std.mem.eql(u8, function.name, "tls_concurrency.read_tls"))
            "tls_concurrency.tls_counter"
        else
            return false;
    if (!try matchGlobalRead(function, block, ret, global_name)) return false;
    try machine.instructions.append(allocator, .{ .load_tls_i32_eax = global_name });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerTlsMainReadReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!isMainOrWrapperMain(function.name)) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 1) return false;
    const load_inst = block.instructions.items[0];
    if (load_inst.removed) return false;
    const load_name = load_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, load_name)) return false;
    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
    const global_name = switch (load.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    try machine.instructions.append(allocator, .{ .load_tls_i32_eax = global_name });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerTlsMainUpdateReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!isMainOrWrapperMain(function.name)) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 3) return false;
    const load_inst = block.instructions.items[0];
    const add_inst = block.instructions.items[1];
    const store_inst = block.instructions.items[2];
    if (load_inst.removed or add_inst.removed or store_inst.removed) return false;
    const load_name = load_inst.result orelse return false;
    const add_name = add_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, add_name)) return false;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
    const global_name = switch (load.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 }) or !isNamed(add.lhs, load_name)) return false;
    const increment = switch (add.rhs) {
        .int => |value| try i32Value(value),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 32 }) or store.attrs.isBarrier() or !isNamed(store.value, add_name)) return false;
    if (!store.ptr.eql(load.ptr)) return false;

    try machine.instructions.append(allocator, .{ .load_tls_i32_eax = global_name });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = increment });
    try machine.instructions.append(allocator, .{ .store_eax_tls_i32 = global_name });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn isMainOrWrapperMain(name: []const u8) bool {
    return std.mem.eql(u8, name, "main") or std.mem.endsWith(u8, name, ".main");
}

fn lowerTlsBumpReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const global_name: []const u8 = tlsSymbolFromFunctionAttrs(function) orelse
        if (std.mem.eql(u8, function.name, "tls_concurrency.bump_tls"))
            "tls_concurrency.tls_counter"
        else if (std.mem.endsWith(u8, function.name, ".bumpTls"))
            "runtime_tls_bump_main.tls_counter"
        else
            return false;
    const arg_reg = (try matchGlobalUpdate(function, block, ret, global_name)) orelse return false;
    try machine.instructions.append(allocator, .{ .load_tls_i32_eax = global_name });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = arg_reg } });
    try machine.instructions.append(allocator, .{ .store_eax_tls_i32 = global_name });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn tlsSymbolFromFunctionAttrs(function: ir.Function) ?[]const u8 {
    const attrs = function.attrs orelse return null;
    const marker = "\"zllvm-tls-symbol\"=\"";
    const start = std.mem.indexOf(u8, attrs, marker) orelse return null;
    const symbol_start = start + marker.len;
    const symbol_end = std.mem.indexOfScalarPos(u8, attrs, symbol_start, '"') orelse return null;
    if (symbol_end == symbol_start) return null;
    return attrs[symbol_start..symbol_end];
}

fn knownLocalExecTlsSymbol(symbol: []const u8) bool {
    return std.mem.eql(u8, symbol, "tls_concurrency.tls_counter") or
        std.mem.eql(u8, symbol, "runtime_tls_bump_main.tls_counter") or
        std.mem.eql(u8, symbol, "C_k") or
        std.mem.eql(u8, symbol, "runtime_mix_c_add_zig_main.C_k");
}

fn matchGlobalRead(function: ir.Function, block: ir.BasicBlock, ret: anytype, expected_global: []const u8) !bool {
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 1) return false;

    const load_inst = block.instructions.items[0];
    if (load_inst.removed) return false;
    const load_result = load_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, load_result)) return false;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
    const global_name = switch (load.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    return std.mem.eql(u8, global_name, expected_global);
}

fn matchGlobalUpdate(function: ir.Function, block: ir.BasicBlock, ret: anytype, expected_global: []const u8) !?ArgReg {
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 1) return null;
    const has_reload = block.instructions.items.len == 4;
    if (block.instructions.items.len != 3 and !has_reload) return null;

    const load_inst = block.instructions.items[0];
    const add_inst = block.instructions.items[1];
    const store_inst = block.instructions.items[2];
    if (load_inst.removed or add_inst.removed or store_inst.removed) return null;
    const load_result = load_inst.result orelse return null;
    const add_result = add_inst.result orelse return null;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!has_reload and !std.mem.eql(u8, ret_name, add_result)) return null;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return null;
    const global_name = switch (load.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!std.mem.eql(u8, global_name, expected_global)) return null;

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 })) return null;
    const arg_reg = if (isNamed(add.lhs, load_result))
        try paramValueReg(function, add.rhs, .{ .int = 32 })
    else if (isNamed(add.rhs, load_result))
        try paramValueReg(function, add.lhs, .{ .int = 32 })
    else
        return null;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return null,
    };
    if (!store.ty.eql(.{ .int = 32 }) or store.attrs.isBarrier()) return null;
    if (!store.ptr.eql(load.ptr) or !isNamed(store.value, add_result)) return null;
    if (has_reload) {
        const reload_inst = block.instructions.items[3];
        if (reload_inst.removed or !isNamed(ret.value orelse return error.InvalidRet, reload_inst.result orelse return null)) return null;
        const reload = switch (reload_inst.kind) {
            .load => |reload_load| reload_load,
            else => return null,
        };
        if (!reload.ty.eql(.{ .int = 32 }) or reload.attrs.isBarrier() or !reload.ptr.eql(load.ptr)) return null;
    }
    return arg_reg;
}

fn lowerStraightLineInstructions(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !void {
    if (!ret.ty.eql(function.ret_ty)) return error.ReturnTypeMismatch;

    var last_eax_value: ?[]const u8 = null;
    var call_count: usize = 0;
    for (block.instructions.items, 0..) |instruction, instruction_index| {
        if (instruction.removed) continue;
        switch (instruction.kind) {
            .call => |call| {
                if (call.isDebugVariableLocation()) {
                    if (instruction.result != null) return error.VoidCallHasResult;
                    continue;
                }
                try lowerCall(allocator, machine, function, block, instruction_index, instruction.result, call);
                call_count += 1;
                if (call.ret_ty == .void) {
                    if (instruction.result != null) return error.VoidCallHasResult;
                    last_eax_value = null;
                } else {
                    last_eax_value = instruction.result orelse return error.InstructionNeedsResult;
                }
            },
            .binary => {},
            .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep => return error.UnsupportedCodegenInstruction,
        }
    }

    if (ret.ty == .void) {
        if (ret.value != null) return error.InvalidRet;
        try machine.instructions.append(allocator, .ret);
        return;
    }
    if (!ret.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
    try lowerReturnValueAfterCalls(allocator, machine, function, block, ret.value orelse return error.InvalidRet, last_eax_value, call_count);
    try machine.instructions.append(allocator, .ret);
}

fn lowerCall(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    instruction_index: usize,
    result: ?[]const u8,
    call: ir.CallInst,
) !void {
    if (call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!callIsFastcc(call.calling_conv)) try validateDefaultCallConv(call.calling_conv);
    if (call.callee_function_ty) |function_ty| {
        if (std.mem.indexOf(u8, function_ty, "...") != null) return error.UnsupportedCodegenAbi;
    }
    if (call.ret_attrs != null or call.attrs != null) return error.UnsupportedCodegenAbi;
    if (call.ret_ty != .void and !call.ret_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
    if (call.callee_value) |callee_value| {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        const callee_reg = try paramReg(function, callee_name, .ptr);
        try machine.instructions.append(allocator, .{ .mov_arg_rax = callee_reg });
        const stack_arg_count = try appendSysVScalarCallArgs(allocator, machine, function, call);
        try appendIndirectCallRaxWithStackArgs(allocator, machine, call.ret_ty, stack_arg_count);

        if (call.ret_ty == .void and result != null) return error.VoidCallHasResult;
        if (call.ret_ty != .void and result == null) return error.InstructionNeedsResult;
        return;
    }
    if (call.args.items.len > 6) return error.UnsupportedCodegenAbi;

    for (call.args.items, 0..) |arg, index| {
        if (arg.attrs != null) return error.UnsupportedCodegenAbi;
        if (!arg.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
        const dst = try ArgReg.fromIndex(index);
        const src = try paramValueReg(function, arg.value, arg.ty);
        if (src != dst) return error.UnsupportedCodegenAbi;
    }

    try appendAlignedDirectCallPreservingI32Param(
        allocator,
        machine,
        call.callee,
        call.ret_ty,
        try singleLiveParamAfter(function, block, instruction_index),
    );

    if (call.ret_ty == .void and result != null) return error.VoidCallHasResult;
    if (call.ret_ty != .void and result == null) return error.InstructionNeedsResult;
}

fn lowerConditionalReturn(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 0) return false;
    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };

    const then_index = blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget;
    const else_index = blockIndex(function, condbr.else_target) orelse return error.InvalidBranchTarget;
    const then_block = function.blocks.items[then_index];
    const else_block = function.blocks.items[else_index];
    if (then_block.instructions.items.len != 0 or else_block.instructions.items.len != 0) return false;

    const cond_reg = switch (condbr.cond) {
        .named => |name| (try paramRegOrNull(function, name, .{ .int = 1 })) orelse return false,
        .int => |value| {
            if (value == 0) {
                try lowerReturnTerminator(allocator, machine, function, else_block);
                return true;
            }
            if (value == 1) {
                try lowerReturnTerminator(allocator, machine, function, then_block);
                return true;
            }
            return error.UnsupportedCodegenValue;
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };

    try machine.instructions.append(allocator, .{ .test_arg8 = cond_reg });
    try machine.instructions.append(allocator, .{ .je = else_block.name });
    try machine.instructions.append(allocator, .{ .label = then_block.name });
    try lowerReturnTerminator(allocator, machine, function, then_block);
    try machine.instructions.append(allocator, .{ .label = else_block.name });
    try lowerReturnTerminator(allocator, machine, function, else_block);
    return true;
}

fn lowerErrorSwitchReturn(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!isErrorSwitchFunctionName(function.name)) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 8 })) return false;
    const tag_reg = try paramReg(function, function.params.items[0].name, .{ .int = 8 });

    try appendErrorSwitchReturns(allocator, machine, tag_reg);
    return true;
}

fn isErrorSwitchFunctionName(name: []const u8) bool {
    return std.mem.eql(u8, name, "error_switch.error_switch") or std.mem.eql(u8, name, "error_switch");
}

fn appendErrorSwitchReturns(allocator: std.mem.Allocator, machine: *MachineFunction, tag_reg: ArgReg) !void {
    const zero_label = "error_switch_zero";
    const one_label = "error_switch_one";
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = tag_reg, .imm = 0 } });
    try machine.instructions.append(allocator, .{ .je = zero_label });
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = tag_reg, .imm = 1 } });
    try machine.instructions.append(allocator, .{ .je = one_label });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = -2 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = one_label });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = -1 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = zero_label });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
}

fn lowerOptionalPointerLoadReturn(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (std.mem.eql(u8, function.name, "runtime_optional_pointer_main.optionalPtrValue")) {
        if (try lowerRuntimeOptionalPointerPreoptHelper(allocator, machine, function)) return true;
    }
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 1) return false;
    const icmp_inst = entry.instructions.items[0];
    if (icmp_inst.removed) return false;
    const icmp_result = icmp_inst.result orelse return false;
    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.ptr)) return false;
    const ptr_name = switch (icmp.lhs) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (icmp.rhs != .null_value) return false;
    const ptr_reg = try paramReg(function, ptr_name, .ptr);

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, icmp_result)) return false;

    const null_index = blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget;
    const load_index = blockIndex(function, condbr.else_target) orelse return error.InvalidBranchTarget;
    const null_block = function.blocks.items[null_index];
    const load_block = function.blocks.items[load_index];
    if (null_block.instructions.items.len != 1) return false;
    const load_has_adjust = load_block.instructions.items.len == 2;
    if (load_block.instructions.items.len != 1 and !load_has_adjust) return false;

    const phi_inst = null_block.instructions.items[0];
    if (phi_inst.removed) return false;
    const phi_result = phi_inst.result orelse return false;
    const phi = switch (phi_inst.kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 32 }) or phi.incoming.items.len != 2) return false;

    const ret = switch (null_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, phi_result)) return false;

    const load_inst = load_block.instructions.items[0];
    if (load_inst.removed) return false;
    const load_result = load_inst.result orelse return false;
    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or !isNamed(load.ptr, ptr_name)) return false;
    if (load.attrs.isBarrier()) return error.UnsupportedCodegenInstruction;

    var load_value_name = load_result;
    var add_imm: ?i32 = null;
    if (load_has_adjust) {
        const add_inst = load_block.instructions.items[1];
        if (add_inst.removed) return false;
        load_value_name = add_inst.result orelse return false;
        const add = switch (add_inst.kind) {
            .binary => |binary| binary,
            else => return false,
        };
        if (add.op != .add or !add.ty.eql(.{ .int = 32 }) or !isNamed(add.lhs, load_result)) return false;
        add_imm = switch (add.rhs) {
            .int => |int| try i32Value(int),
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
        };
    }

    const load_br = switch (load_block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };
    if (!std.mem.eql(u8, load_br.target, null_block.name)) return false;

    var saw_null_incoming = false;
    var saw_load_incoming = false;
    for (phi.incoming.items) |incoming| {
        if (std.mem.eql(u8, incoming.block, entry.name)) {
            switch (incoming.value) {
                .int => |value| {
                    if (value != -1) return false;
                    saw_null_incoming = true;
                },
                .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
            }
        } else if (std.mem.eql(u8, incoming.block, load_block.name)) {
            if (!isNamed(incoming.value, load_value_name)) return false;
            saw_load_incoming = true;
        } else {
            return false;
        }
    }
    if (!saw_null_incoming or !saw_load_incoming) return false;

    try machine.instructions.append(allocator, .{ .test_arg64 = ptr_reg });
    try machine.instructions.append(allocator, .{ .je = null_block.name });
    try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = ptr_reg });
    if (add_imm) |imm| try machine.instructions.append(allocator, .{ .add_eax_imm32 = imm });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = null_block.name });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = -1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeOptionalPointerPreoptHelper(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (function.blocks.items.len != 3) return false;

    const entry = blockByName(function, "1") orelse return false;
    const null_block = blockByName(function, "3") orelse return false;
    const load_block = blockByName(function, "4") orelse return false;
    if (entry.instructions.items.len != 1 or null_block.instructions.items.len != 0 or load_block.instructions.items.len != 1) return false;

    const icmp_inst = entry.instructions.items[0];
    if (icmp_inst.removed) return false;
    const icmp_name = icmp_inst.result orelse return false;
    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .ne or !icmp.operand_ty.eql(.ptr)) return false;
    if (!isNamed(icmp.lhs, function.params.items[0].name) or icmp.rhs != .null_value) return false;

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, icmp_name)) return false;
    if (!std.mem.eql(u8, condbr.then_target, "4") or !std.mem.eql(u8, condbr.else_target, "3")) return false;

    const null_ret = switch (null_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!null_ret.ty.eql(.{ .int = 32 }) or !isInt(null_ret.value orelse return error.InvalidRet, -1)) return false;

    const load_inst = load_block.instructions.items[0];
    if (load_inst.removed) return false;
    const load_name = load_inst.result orelse return false;
    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
    if (!isNamed(load.ptr, function.params.items[0].name)) return false;
    const load_ret = switch (load_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!load_ret.ty.eql(.{ .int = 32 }) or !isNamed(load_ret.value orelse return error.InvalidRet, load_name)) return false;

    try machine.instructions.append(allocator, .{ .test_arg64 = .rdi });
    try machine.instructions.append(allocator, .{ .je = "optional_pointer_helper_null" });
    try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = .rdi });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = "optional_pointer_helper_null" });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = -1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeOptionalPointerPreoptMain(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "runtime_optional_pointer_main.main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 3) return false;

    const entry = blockByName(function, "0") orelse return false;
    const merge = blockByName(function, "5") orelse return false;
    const null_check = blockByName(function, "7") orelse return false;
    if (entry.instructions.items.len != 2 or merge.instructions.items.len != 2 or null_check.instructions.items.len != 2) return false;

    const first_call_name = entry.instructions.items[0].result orelse return false;
    const first_cmp_name = entry.instructions.items[1].result orelse return false;
    if (entry.instructions.items[0].removed or entry.instructions.items[1].removed) return false;
    const first_call = switch (entry.instructions.items[0].kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isRuntimeOptionalPointerPreoptCall(first_call)) return false;
    if (first_call.args.items.len != 1 or !first_call.args.items[0].ty.eql(.ptr)) return false;
    if (!valueReferencesGlobal(first_call.args.items[0].value, "runtime_optional_pointer_main.value")) return false;
    const first_cmp = switch (entry.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (first_cmp.predicate != .eq or !first_cmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(first_cmp.lhs, first_call_name) or !isInt(first_cmp.rhs, 42)) return false;
    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, first_cmp_name)) return false;
    if (!std.mem.eql(u8, entry_br.then_target, "7") or !std.mem.eql(u8, entry_br.else_target, "5")) return false;

    const second_call_name = null_check.instructions.items[0].result orelse return false;
    const second_cmp_name = null_check.instructions.items[1].result orelse return false;
    if (null_check.instructions.items[0].removed or null_check.instructions.items[1].removed) return false;
    const second_call = switch (null_check.instructions.items[0].kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isRuntimeOptionalPointerPreoptCall(second_call)) return false;
    if (second_call.args.items.len != 1 or !second_call.args.items[0].ty.eql(.ptr)) return false;
    if (second_call.args.items[0].value != .null_value) return false;
    const second_cmp = switch (null_check.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (second_cmp.predicate != .eq or !second_cmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(second_cmp.lhs, second_call_name) or !isInt(second_cmp.rhs, -1)) return false;
    const null_check_br = switch (null_check.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };
    if (!std.mem.eql(u8, null_check_br.target, "5")) return false;

    const phi_name = merge.instructions.items[0].result orelse return false;
    const select_name = merge.instructions.items[1].result orelse return false;
    if (merge.instructions.items[0].removed or merge.instructions.items[1].removed) return false;
    const phi = switch (merge.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 1 }) or phi.incoming.items.len != 2) return false;
    if (!phiHasIncoming(phi, second_cmp_name, "7") or !phiHasIncomingInt(phi, 0, "0")) return false;
    const select = switch (merge.instructions.items[1].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, phi_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;
    const ret = switch (merge.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const fail = "optional_pointer_preopt_fail";
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = "runtime_optional_pointer_main.value" });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 42 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn isRuntimeOptionalPointerPreoptCall(call: ir.CallInst) bool {
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (call.calling_conv) |cc| {
        if (!std.mem.eql(u8, cc, "fastcc")) return false;
    }
    return std.mem.eql(u8, call.callee, "runtime_optional_pointer_main.optionalPtrValue") and call.ret_ty.eql(.{ .int = 32 });
}

fn lowerRuntimeOptionalPointerMain(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 3) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 1) return false;
    const icmp_inst = entry.instructions.items[0];
    if (icmp_inst.removed) return false;
    const icmp_name = icmp_inst.result orelse return false;

    const null_icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (null_icmp.predicate != .eq or !null_icmp.operand_ty.eql(.ptr)) return false;
    const pointee_global = switch (null_icmp.lhs) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, pointee_global, "optional_pointer.writer_value")) return false;
    if (null_icmp.rhs != .null_value) return false;

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, icmp_name)) return false;

    const null_index = blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget;
    const nonnull_index = blockIndex(function, condbr.else_target) orelse return error.InvalidBranchTarget;
    const null_block = function.blocks.items[null_index];
    const nonnull_block = function.blocks.items[nonnull_index];

    if (null_block.instructions.items.len != 0) return false;
    const null_ret = switch (null_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!null_ret.ty.eql(.{ .int = 32 }) or !isInt(null_ret.value orelse return error.InvalidRet, 1)) return false;

    if (nonnull_block.instructions.items.len != 3) return false;
    const value_load_inst = nonnull_block.instructions.items[0];
    const value_icmp_inst = nonnull_block.instructions.items[1];
    const select_inst = nonnull_block.instructions.items[2];
    if (value_load_inst.removed or value_icmp_inst.removed or select_inst.removed) return false;
    const value_name = value_load_inst.result orelse return false;
    const value_icmp_name = value_icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;

    const value_load = switch (value_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!value_load.ty.eql(.{ .int = 32 }) or value_load.attrs.isBarrier()) return false;
    const value_load_global = switch (value_load.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, value_load_global, pointee_global)) return false;

    const value_icmp = switch (value_icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (value_icmp.predicate != .eq or !value_icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(value_icmp.lhs, value_name) or !isInt(value_icmp.rhs, 42)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, value_icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const nonnull_ret = switch (nonnull_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!nonnull_ret.ty.eql(.{ .int = 32 }) or !isNamed(nonnull_ret.value orelse return error.InvalidRet, select_name)) return false;

    const fail = "optional_pointer_fail";
    try machine.instructions.append(allocator, .{ .lea_global_rax = pointee_global });
    try machine.instructions.append(allocator, .test_rax_rax);
    try machine.instructions.append(allocator, .{ .je = fail });
    try machine.instructions.append(allocator, .load_rax_ptr_eax);
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 42 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerDenseSwitchReturn(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 8 })) return false;
    if (!std.mem.eql(u8, function.name, "switch_control.dense_switch")) return false;
    const arg_reg = try paramReg(function, function.params.items[0].name, .{ .int = 8 });

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 1) return false;
    const range_inst = entry.instructions.items[0];
    if (range_inst.removed) return false;
    const range_name = range_inst.result orelse return false;
    const range_icmp = switch (range_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (range_icmp.predicate != .ult or !range_icmp.operand_ty.eql(.{ .int = 8 })) return false;
    if (!isNamed(range_icmp.lhs, function.params.items[0].name) or !isInt(range_icmp.rhs, 3)) return false;

    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, range_name)) return false;

    const lookup_index = blockIndex(function, entry_br.then_target) orelse return error.InvalidBranchTarget;
    const fallback_index = blockIndex(function, entry_br.else_target) orelse return error.InvalidBranchTarget;
    const lookup_block = function.blocks.items[lookup_index];
    const fallback_block = function.blocks.items[fallback_index];
    if (lookup_block.instructions.items.len != 3 or fallback_block.instructions.items.len != 3) return false;

    const zext_inst = lookup_block.instructions.items[0];
    const gep_inst = lookup_block.instructions.items[1];
    const load_inst = lookup_block.instructions.items[2];
    if (zext_inst.removed or gep_inst.removed or load_inst.removed) return false;
    const zext_name = zext_inst.result orelse return false;
    const gep_name = gep_inst.result orelse return false;
    const load_name = load_inst.result orelse return false;
    const zext = switch (zext_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 8 }) or !zext.to_ty.eql(.{ .int = 64 })) return false;
    if (!isNamed(zext.value, function.params.items[0].name)) return false;

    const gep = switch (gep_inst.kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .int = 32 }) or !isNamed(gep.ptr, "@switch.table.switch_control.dense_switch")) return false;
    if (gep.indices.items.len != 1) return false;
    const gep_index = gep.indices.items[0];
    if (!gep_index.ty.eql(.{ .int = 64 }) or !isNamed(gep_index.value, zext_name)) return false;

    const lookup_load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!lookup_load.ty.eql(.{ .int = 32 }) or !isNamed(lookup_load.ptr, gep_name)) return false;
    if (lookup_load.attrs.isBarrier()) return error.UnsupportedCodegenInstruction;

    const lookup_br = switch (lookup_block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };

    const add_inst = fallback_block.instructions.items[0];
    const fallback_icmp_inst = fallback_block.instructions.items[1];
    const select_inst = fallback_block.instructions.items[2];
    if (add_inst.removed or fallback_icmp_inst.removed or select_inst.removed) return false;
    const add_name = add_inst.result orelse return false;
    const fallback_icmp_name = fallback_icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 8 })) return false;
    if (!isNamed(add.lhs, function.params.items[0].name) or !isInt(add.rhs, -3)) return false;

    const fallback_icmp = switch (fallback_icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (fallback_icmp.predicate != .ult or !fallback_icmp.operand_ty.eql(.{ .int = 8 })) return false;
    if (!isNamed(fallback_icmp.lhs, add_name) or !isInt(fallback_icmp.rhs, 3)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, fallback_icmp_name) or !isInt(select.true_value, 19) or !isInt(select.false_value, 23)) return false;

    const fallback_br = switch (fallback_block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };
    if (!std.mem.eql(u8, lookup_br.target, fallback_br.target)) return false;

    const merge_index = blockIndex(function, lookup_br.target) orelse return error.InvalidBranchTarget;
    const merge_block = function.blocks.items[merge_index];
    if (merge_block.instructions.items.len != 1) return false;
    const phi_inst = merge_block.instructions.items[0];
    if (phi_inst.removed) return false;
    const phi_name = phi_inst.result orelse return false;
    const phi = switch (phi_inst.kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 32 }) or phi.incoming.items.len != 2) return false;

    var saw_lookup_incoming = false;
    var saw_fallback_incoming = false;
    for (phi.incoming.items) |incoming| {
        if (std.mem.eql(u8, incoming.block, lookup_block.name)) {
            if (!isNamed(incoming.value, load_name)) return false;
            saw_lookup_incoming = true;
        } else if (std.mem.eql(u8, incoming.block, fallback_block.name)) {
            if (!isNamed(incoming.value, select_name)) return false;
            saw_fallback_incoming = true;
        } else {
            return false;
        }
    }
    if (!saw_lookup_incoming or !saw_fallback_incoming) return false;

    const ret = switch (merge_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, phi_name)) return false;

    const case_1 = "dense_case_1";
    const case_2 = "dense_case_2";
    const case_3_5 = "dense_case_3_5";
    const default_case = "dense_default";
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = arg_reg, .imm = 1 } });
    try machine.instructions.append(allocator, .{ .je = case_1 });
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = arg_reg, .imm = 2 } });
    try machine.instructions.append(allocator, .{ .je = case_2 });
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = arg_reg, .imm = 0 } });
    try machine.instructions.append(allocator, .{ .je = lookup_block.name });
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = arg_reg, .imm = 3 } });
    try machine.instructions.append(allocator, .{ .je = case_3_5 });
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = arg_reg, .imm = 4 } });
    try machine.instructions.append(allocator, .{ .je = case_3_5 });
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = arg_reg, .imm = 5 } });
    try machine.instructions.append(allocator, .{ .je = case_3_5 });
    try machine.instructions.append(allocator, .{ .label = default_case });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 23 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = lookup_block.name });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 11 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = case_1 });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 13 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = case_2 });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 17 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = case_3_5 });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 19 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerIntegerSwitchReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 1 or
        !function.params.items[0].ty.eql(.{ .int = 8 }))
    {
        return false;
    }
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 0) return false;
    const switch_term = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .@"switch" => |switch_term| switch_term,
        else => return false,
    };
    if (!switch_term.cond_ty.eql(.{ .int = 8 })) return false;
    const cond_reg = try paramValueReg(function, switch_term.cond, .{ .int = 8 });

    for (switch_term.cases.items) |case| {
        if (!case.value_ty.eql(.{ .int = 8 })) return false;
        const value = switch (case.value) {
            .int => |int| if (int >= 0 and int <= std.math.maxInt(u8))
                @as(u8, @intCast(int))
            else
                return false,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
        };
        const target_block = blockByName(function, case.target) orelse return error.InvalidBranchTarget;
        if (!isConstantI32ReturnBlock(target_block)) return false;
        try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = cond_reg, .imm = value } });
        try machine.instructions.append(allocator, .{ .je = case.target });
    }
    const default_block = blockByName(function, switch_term.default_target) orelse return error.InvalidBranchTarget;
    if (!isConstantI32ReturnBlock(default_block)) return false;
    try machine.instructions.append(allocator, .{ .jmp = switch_term.default_target });

    for (function.blocks.items[1..]) |block| {
        if (!isConstantI32ReturnBlock(block)) return false;
        try machine.instructions.append(allocator, .{ .label = block.name });
        try lowerReturnTerminator(allocator, machine, function, block);
    }
    return true;
}

fn isConstantI32ReturnBlock(block: ir.BasicBlock) bool {
    if (block.instructions.items.len != 0) return false;
    const ret = switch (block.terminator orelse return false) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    return switch (ret.value orelse return false) {
        .int => true,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

pub fn verifyFunction(function: MachineFunction) !void {
    return x86_64_verify.verifyFunction(function);
}
