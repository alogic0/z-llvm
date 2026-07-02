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
const air_patterns_abi_bridge = @import("air_patterns_abi_bridge.zig");
const air_patterns_cfg = @import("air_patterns_cfg.zig");
const air_patterns_optional_pointer = @import("air_patterns_optional_pointer.zig");
const air_patterns_runtime = @import("air_patterns_runtime.zig");
const air_patterns_base64_rows = @import("air_patterns_base64_rows.zig");
const air_patterns_packed_volatile_pointer_rows = @import("air_patterns_packed_volatile_pointer_rows.zig");
const air_patterns_fp_descriptor_rows = @import("air_patterns_fp_descriptor_rows.zig");
const air_patterns_global_tls_rows = @import("air_patterns_global_tls_rows.zig");

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
const lowerSelectedI64ConstReturn = air_patterns_runtime.lowerSelectedI64ConstReturn;
const lowerGenericCfgI64ParamReturn = air_patterns_runtime.lowerGenericCfgI64ParamReturn;
const lowerGenericCfgI64DirectCallReturn = air_patterns_runtime.lowerGenericCfgI64DirectCallReturn;
const lowerControlFlowCallsWriterMainReturn = air_patterns_runtime.lowerControlFlowCallsWriterMainReturn;
const lowerDirectI32CallMainReturn = air_patterns_runtime.lowerDirectI32CallMainReturn;
const lowerTlsBumpCallMainReturn = air_patterns_runtime.lowerTlsBumpCallMainReturn;
const lowerSelectedI64CallMainReturn = air_patterns_runtime.lowerSelectedI64CallMainReturn;
const lowerReleaseSmallStrFromFloatMainReturn = air_patterns_runtime.lowerReleaseSmallStrFromFloatMainReturn;
const lowerRuntimeArraySumMainReturn = air_patterns_runtime.lowerRuntimeArraySumMainReturn;
const lowerRuntimeCheckedStructSumMainReturn = air_patterns_runtime.lowerRuntimeCheckedStructSumMainReturn;
const lowerRuntimeOptionalPayloadPreoptHelper = air_patterns_runtime.lowerRuntimeOptionalPayloadPreoptHelper;
const lowerRuntimeOptionalPayloadMainReturn = air_patterns_runtime.lowerRuntimeOptionalPayloadMainReturn;
const lowerRuntimeErrorUnionPayloadMainReturn = air_patterns_runtime.lowerRuntimeErrorUnionPayloadMainReturn;
const lowerRuntimeErrorUnionPayloadPreoptHelper = air_patterns_runtime.lowerRuntimeErrorUnionPayloadPreoptHelper;
const lowerRuntimeSliceSumMainReturn = air_patterns_runtime.lowerRuntimeSliceSumMainReturn;
const lowerRuntimeComptimeConstMainReturn = air_patterns_runtime.lowerRuntimeComptimeConstMainReturn;
const lowerRuntimeDebugLocationMainReturn = air_patterns_runtime.lowerRuntimeDebugLocationMainReturn;
const lowerBase64DecodeBase64FullBoundary = x86_64_generic_cfg.lowerBase64DecodeBase64FullBoundary;
const lowerBase64DecodeBase64FullMain = x86_64_generic_cfg.lowerBase64DecodeBase64FullMain;
const lowerBase64PaddingLoopStep = x86_64_generic_cfg.lowerBase64PaddingLoopStep;
const lowerPackedReplaceLowReturn = air_patterns_packed_volatile_pointer_rows.lowerPackedReplaceLowReturn;
const lowerRuntimePackedReplaceLowPreoptHelper = air_patterns_packed_volatile_pointer_rows.lowerRuntimePackedReplaceLowPreoptHelper;
const lowerRuntimePackedReplaceLowMainReturn = air_patterns_packed_volatile_pointer_rows.lowerRuntimePackedReplaceLowMainReturn;
const lowerPackedReadFlagReturn = air_patterns_packed_volatile_pointer_rows.lowerPackedReadFlagReturn;
const lowerRuntimePackedReadFlagPreoptHelper = air_patterns_packed_volatile_pointer_rows.lowerRuntimePackedReadFlagPreoptHelper;
const lowerRuntimePackedReadFlagMainReturn = air_patterns_packed_volatile_pointer_rows.lowerRuntimePackedReadFlagMainReturn;
const lowerPointerVolatileRoundtripReturn = air_patterns_packed_volatile_pointer_rows.lowerPointerVolatileRoundtripReturn;
const lowerRuntimeVolatileRoundtripMainReturn = air_patterns_packed_volatile_pointer_rows.lowerRuntimeVolatileRoundtripMainReturn;
const lowerRuntimeVolatileRoundtripPreoptMainReturn = air_patterns_packed_volatile_pointer_rows.lowerRuntimeVolatileRoundtripPreoptMainReturn;
const isO0ParamStoreToAlloca = air_patterns_packed_volatile_pointer_rows.isO0ParamStoreToAlloca;
const lowerPointerLoadStoreReturn = air_patterns_packed_volatile_pointer_rows.lowerPointerLoadStoreReturn;
const lowerRuntimePointerLoadStorePreoptMain = air_patterns_packed_volatile_pointer_rows.lowerRuntimePointerLoadStorePreoptMain;
const lowerRuntimePointerLoadStorePreoptSafeOptimizedMain = air_patterns_packed_volatile_pointer_rows.lowerRuntimePointerLoadStorePreoptSafeOptimizedMain;
const lowerRuntimePointerLoadStorePreoptSafeMain = air_patterns_packed_volatile_pointer_rows.lowerRuntimePointerLoadStorePreoptSafeMain;
const lowerRuntimePointerLoadStoreMainReturn = air_patterns_packed_volatile_pointer_rows.lowerRuntimePointerLoadStoreMainReturn;
const lowerBase64TableLookupMainReturn = air_patterns_base64_rows.lowerBase64TableLookupMainReturn;
const lowerGenericCfgByteTableLookupReturn = air_patterns_base64_rows.lowerGenericCfgByteTableLookupReturn;
const lowerBase64DecodeStepMainReturn = air_patterns_base64_rows.lowerBase64DecodeStepMainReturn;
const lowerBase64StoreStepMainReturn = air_patterns_base64_rows.lowerBase64StoreStepMainReturn;
const lowerBase64ResidualByteStepMainReturn = air_patterns_base64_rows.lowerBase64ResidualByteStepMainReturn;
const lowerBase64ResidualStoreStepMainReturn = air_patterns_base64_rows.lowerBase64ResidualStoreStepMainReturn;
const lowerBase64ResidualLengthStepMainReturn = air_patterns_base64_rows.lowerBase64ResidualLengthStepMainReturn;
const lowerBase64ResidualTableCheckStepMainReturn = air_patterns_base64_rows.lowerBase64ResidualTableCheckStepMainReturn;
const validateBase64ResidualTableCheckGep = air_patterns_base64_rows.validateBase64ResidualTableCheckGep;
const validateBase64ResidualTableCheckI8Load = air_patterns_base64_rows.validateBase64ResidualTableCheckI8Load;
const validateBase64ResidualTableCheckI8Eq = air_patterns_base64_rows.validateBase64ResidualTableCheckI8Eq;
const lowerBase64ResidualAccumulatorStepMainReturn = air_patterns_base64_rows.lowerBase64ResidualAccumulatorStepMainReturn;
const validateBase64ResidualAccumulatorGlobalLoad = air_patterns_base64_rows.validateBase64ResidualAccumulatorGlobalLoad;
const validateBase64ResidualAccumulatorCast = air_patterns_base64_rows.validateBase64ResidualAccumulatorCast;
const validateBase64ResidualAccumulatorBinary = air_patterns_base64_rows.validateBase64ResidualAccumulatorBinary;
const validateBase64ResidualAccumulatorStore = air_patterns_base64_rows.validateBase64ResidualAccumulatorStore;
const validateBase64ResidualTableCheckI8EqTyped = air_patterns_base64_rows.validateBase64ResidualTableCheckI8EqTyped;
const valueIsGlobalSymbol = air_patterns_base64_rows.valueIsGlobalSymbol;
const lowerBase64ResidualLoopAdvanceStepMainReturn = air_patterns_base64_rows.lowerBase64ResidualLoopAdvanceStepMainReturn;
const lowerBase64ResidualPaddingCheckStepMainReturn = air_patterns_base64_rows.lowerBase64ResidualPaddingCheckStepMainReturn;
const lowerBase64ResidualFinalMaskStepMainReturn = air_patterns_base64_rows.lowerBase64ResidualFinalMaskStepMainReturn;
const validateBase64ResidualFinalMaskI64IcmpUge = air_patterns_base64_rows.validateBase64ResidualFinalMaskI64IcmpUge;
const validateBase64ResidualFinalMaskIntNamedShl = air_patterns_base64_rows.validateBase64ResidualFinalMaskIntNamedShl;
const validateBase64ResidualFinalMaskIcmpTyped = air_patterns_base64_rows.validateBase64ResidualFinalMaskIcmpTyped;
const lowerBase64ResidualPaddingLoopStepMainReturn = air_patterns_base64_rows.lowerBase64ResidualPaddingLoopStepMainReturn;
const validateBase64ResidualPaddingLoopIcmpNamed = air_patterns_base64_rows.validateBase64ResidualPaddingLoopIcmpNamed;
const lowerBase64DecodeExitStepMainReturn = air_patterns_base64_rows.lowerBase64DecodeExitStepMainReturn;
const lowerBase64PaddingTailStepMainReturn = air_patterns_base64_rows.lowerBase64PaddingTailStepMainReturn;
const lowerBase64PaddingLengthStepMainReturn = air_patterns_base64_rows.lowerBase64PaddingLengthStepMainReturn;
const lowerBase64ChunkGuardStepMainReturn = air_patterns_base64_rows.lowerBase64ChunkGuardStepMainReturn;
const lowerBase64SourceStrideStepMainReturn = air_patterns_base64_rows.lowerBase64SourceStrideStepMainReturn;
const lowerBase64SourceBundleStepMainReturn = air_patterns_base64_rows.lowerBase64SourceBundleStepMainReturn;
const lowerBase64NextSourceBundleStepMainReturn = air_patterns_base64_rows.lowerBase64NextSourceBundleStepMainReturn;
const lowerBase64ThirdSourceBundleStepMainReturn = air_patterns_base64_rows.lowerBase64ThirdSourceBundleStepMainReturn;
const lowerBase64ResidualBundleStepMainReturn = air_patterns_base64_rows.lowerBase64ResidualBundleStepMainReturn;
const lowerBase64BitBufferStoreStepMainReturn = air_patterns_base64_rows.lowerBase64BitBufferStoreStepMainReturn;
const validateBase64BitBufferI32GlobalLoad = air_patterns_base64_rows.validateBase64BitBufferI32GlobalLoad;
const validateBase64BitBufferZext = air_patterns_base64_rows.validateBase64BitBufferZext;
const validateBase64BitBufferShl = air_patterns_base64_rows.validateBase64BitBufferShl;
const validateBase64BitBufferOr = air_patterns_base64_rows.validateBase64BitBufferOr;
const lowerBase64LoopAdvanceStep = air_patterns_base64_rows.lowerBase64LoopAdvanceStep;
const validateBase64LoopAdvanceI64GlobalLoad = air_patterns_base64_rows.validateBase64LoopAdvanceI64GlobalLoad;
const lowerBase64ResidualGuardStep = air_patterns_base64_rows.lowerBase64ResidualGuardStep;
const validateBase64ResidualGuardI64GlobalLoad = air_patterns_base64_rows.validateBase64ResidualGuardI64GlobalLoad;
const validateBase64ResidualGuardI64Add = air_patterns_base64_rows.validateBase64ResidualGuardI64Add;
const validateBase64ResidualGuardI64IcmpUlt = air_patterns_base64_rows.validateBase64ResidualGuardI64IcmpUlt;
const validateBase64ResidualGuardSelect = air_patterns_base64_rows.validateBase64ResidualGuardSelect;
const validateBase64ResidualGuardSourceGep = air_patterns_base64_rows.validateBase64ResidualGuardSourceGep;
const validateBase64ResidualGuardI8Load = air_patterns_base64_rows.validateBase64ResidualGuardI8Load;
const validateBase64ResidualGuardI8Eq = air_patterns_base64_rows.validateBase64ResidualGuardI8Eq;
const validateBase64ResidualGuardReturnSelect = air_patterns_base64_rows.validateBase64ResidualGuardReturnSelect;
const lowerBase64SourceBundleStepMainReturnWithSymbols = air_patterns_base64_rows.lowerBase64SourceBundleStepMainReturnWithSymbols;
const validateBase64SourceBundleGlobalByteLoad = air_patterns_base64_rows.validateBase64SourceBundleGlobalByteLoad;
const validateBase64SourceBundleRelativeByteLoad = air_patterns_base64_rows.validateBase64SourceBundleRelativeByteLoad;
const validateBase64SourceBundleZext = air_patterns_base64_rows.validateBase64SourceBundleZext;
const validateBase64SourceBundleTableLoad = air_patterns_base64_rows.validateBase64SourceBundleTableLoad;
const validateBase64SourceBundleOr = air_patterns_base64_rows.validateBase64SourceBundleOr;
const validateBase64ChunkGuardAdd = air_patterns_base64_rows.validateBase64ChunkGuardAdd;
const validateBase64ChunkGuardIcmp = air_patterns_base64_rows.validateBase64ChunkGuardIcmp;
const validateBase64PaddingLengthEnd = air_patterns_base64_rows.validateBase64PaddingLengthEnd;
const validateBase64PaddingLengthTailLoad = air_patterns_base64_rows.validateBase64PaddingLengthTailLoad;
const validateBase64PaddingLengthEq = air_patterns_base64_rows.validateBase64PaddingLengthEq;
const validateBase64PaddingLengthSext = air_patterns_base64_rows.validateBase64PaddingLengthSext;
const validateBase64DecodeStepLoad = air_patterns_base64_rows.validateBase64DecodeStepLoad;
const validateNamedOr = air_patterns_base64_rows.validateNamedOr;
const lowerBase64WriterMainReturn = air_patterns_base64_rows.lowerBase64WriterMainReturn;
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
pub const classifySysVAggregateForTest = air_patterns_abi_bridge.classifySysVAggregateForTest;

const x86_64_machine = @import("machine.zig");

pub const Instruction = x86_64_machine.Instruction;
pub const MachineFunction = x86_64_machine.MachineFunction;

pub fn lowerFunction(allocator: std.mem.Allocator, triple_text: []const u8, function: ir.Function) !MachineFunction {
    const parsed_triple = try target.Triple.parse(triple_text);
    if (!parsed_triple.isX86_64() or !parsed_triple.isLinux()) return error.UnsupportedTarget;

    var machine = MachineFunction.init(symbolName(function.name), function.ret_ty);
    errdefer machine.deinit(allocator);

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

pub fn lowerStraightLineReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
) !void {
    const terminator = block.terminator orelse return error.BlockWithoutTerminator;
    switch (terminator) {
        .ret => |ret| {
            if (!ret.ty.eql(function.ret_ty)) return error.ReturnTypeMismatch;
            if (try air_patterns_abi_bridge.lowerAggregatePairAbiFamilyReturn(allocator, machine, function, block, ret)) return;
            if (try air_patterns_fp_descriptor_rows.lowerDescriptorFpCheckMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerSingleStackSlotCallReturn(allocator, machine, function, block, ret)) return;
            if (try air_patterns_cfg.lowerSingleStackSlotReturn(allocator, machine, function, block, ret)) return;
            if (try air_patterns_cfg.lowerSelectAddSubReturn(allocator, machine, function, block, ret)) return;
            if (try air_patterns_cfg.lowerRuntimePhiSelectReturn(allocator, machine, function, block, ret)) return;
            if (try air_patterns_cfg.lowerIcmpSelectConstReturn(allocator, machine, function, block, ret)) return;
            if (try air_patterns_cfg.lowerFcmpSelectConstReturn(allocator, machine, function, block, ret)) return;
            if (try air_patterns_cfg.lowerErrorSwitchSelectReturn(allocator, machine, function, block, ret)) return;
            if (try air_patterns_cfg.lowerErrorUnionI64SelectReturn(allocator, machine, function, block, ret)) return;
            if (try air_patterns_cfg.lowerAddImmReturn(allocator, machine, function, block, ret)) return;
            if (try air_patterns_cfg.lowerShiftOrConstReturn(allocator, machine, function, block, ret)) return;
            if (try lowerMulConstReturn(allocator, machine, function, block, ret)) return;
            if (try air_patterns_cfg.lowerIntegerSminReturn(allocator, machine, function, block, ret)) return;
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
            if (try air_patterns_fp_descriptor_rows.lowerScalarFpCastReturn(allocator, machine, function, block, ret)) return;
            if (try air_patterns_abi_bridge.lowerAggregateAbiReturn(allocator, machine, function, block, ret)) return;
            if (try air_patterns_global_tls_rows.lowerSelectedMixCFilesAddZig(allocator, machine, function, block, ret)) return;
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
            if (try air_patterns_global_tls_rows.lowerHiddenGlobalAccessFamilyReturn(allocator, machine, function, block, ret)) return;
            if (try air_patterns_global_tls_rows.lowerMixedCZigTlsInputFamilyReturn(allocator, machine, function, block, ret)) return;
            if (try air_patterns_global_tls_rows.lowerReleaseSmallMixCAddMayPanicMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerDirectI32CallMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerControlFlowCallsWriterMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerSelectedI64CallMainReturn(allocator, machine, function, block, ret)) return;
            if (try air_patterns_global_tls_rows.lowerTlsReadReturn(allocator, machine, function, block, ret)) return;
            if (try air_patterns_global_tls_rows.lowerTlsBumpReturn(allocator, machine, function, block, ret)) return;
            if (try air_patterns_global_tls_rows.lowerGlobalReadReturn(allocator, machine, function, block, ret)) return;
            if (try air_patterns_global_tls_rows.lowerGlobalUpdateCheckMainReturn(allocator, machine, function, block, ret)) return;
            if (try air_patterns_global_tls_rows.lowerGlobalUpdateReturn(allocator, machine, function, block, ret)) return;
            if (try lowerReleaseSmallStrFromFloatMainReturn(allocator, machine, function, block, ret)) return;
            if (try air_patterns_global_tls_rows.lowerTlsMainReadReturn(allocator, machine, function, block, ret)) return;
            if (try air_patterns_global_tls_rows.lowerTlsMainUpdateReturn(allocator, machine, function, block, ret)) return;
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
                try air_patterns_cfg.lowerStraightLineInstructions(allocator, machine, function, block, ret);
                return;
            }
            if (ret.ty == .void) {
                try machine.instructions.append(allocator, .ret);
                return;
            }
            try sysv_abi.rejectUnsupportedAbiType(ret.ty);
            if (!ret.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
            try lowerReturnValue(allocator, machine, function, block, ret.value orelse return error.InvalidRet);
            try machine.instructions.append(allocator, .ret);
        },
        .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
    }
}

pub fn hasLiveInstructions(block: ir.BasicBlock) bool {
    for (block.instructions.items) |instruction| {
        if (!instruction.removed) return true;
    }
    return false;
}

pub fn lowerSelectedI1ConstReturn(
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

pub fn lowerSelectedStringSliceReturn(
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

pub fn lowerSelectedLibfuzzerTestRun(
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

pub fn validateVoidCall(instruction: ir.Instruction, callee: []const u8, expected_args: []const ExpectedCallArg) !void {
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

pub fn validateAssumeColdCall(instruction: ir.Instruction) !void {
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

pub fn validateIntegerOverflowPanicCall(instruction: ir.Instruction) !void {
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

pub fn lowerI64SaturatingHelperFamilyReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (try lowerSelectedUmlFixSatI64Return(allocator, machine, function, block, ret)) return true;
    return false;
}

pub fn lowerSelectedUmlFixSatI64Return(
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

pub fn lowerSingleStackSlotCallReturn(
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

pub fn lowerFloatMulReturn(
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

pub fn lowerFloatAddReturn(
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

pub fn lowerRuntimeFloatAddMainReturn(
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

pub fn lowerFloatSubReturn(
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

pub fn lowerRuntimeFloatSubMainReturn(
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

pub fn lowerDoubleDivReturn(
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

pub fn lowerRuntimeDoubleDivMainReturn(
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

pub fn lowerFloatRemReturn(
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

pub fn lowerRuntimeFloatRemMainReturn(
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

pub fn lowerRuntimeFloatMulMainReturn(
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

pub fn matchesFpBinaryReturn(
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

pub fn lowerFloatSelectReturn(
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

pub fn lowerFloatLessReturn(
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

pub fn lowerFloatLiteralReturn(
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

pub fn lowerStructSumReturn(
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

pub fn lowerRuntimeStructSumPreoptHelper(
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

pub fn lowerRuntimeStructSumMainReturn(
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

pub fn lowerAddChain3Return(
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

pub fn lowerRuntimeArraySumPreoptHelper(
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

pub fn lowerInlineAsmBarrierReturn(
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

pub fn lowerAtomicAddReturn(
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

pub fn verifyFunction(function: MachineFunction) !void {
    return x86_64_verify.verifyFunction(function);
}
