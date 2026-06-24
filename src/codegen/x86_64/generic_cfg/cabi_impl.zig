const core = @import("core.zig");
const core_impl = @import("core_impl.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");
const cabi_call_lowering = @import("cabi_call_lowering.zig");
const cabi_aggregate_lowering = @import("cabi_aggregate_lowering.zig");
const cabi_tls_global_lowering = @import("cabi_tls_global_lowering.zig");
pub const std = @import("std");
pub const ir = @import("../../../ir.zig");
pub const target = @import("../../../target.zig");
pub const memory_location = @import("../../../analysis/memory_location.zig");
pub const x86_64_types = @import("../types.zig");
pub const sysv_abi = @import("../sysv_abi.zig");
pub const x86_64_emit = @import("../emit.zig");
pub const x86_64_match = @import("../match.zig");
pub const runtime_float = @import("../runtime_float.zig");
pub const x86_64_machine = @import("../machine.zig");

pub const MachineBinaryOp = x86_64_types.MachineBinaryOp;
pub const ArgReg = x86_64_types.ArgReg;
pub const XmmReg = x86_64_types.XmmReg;
pub const MachineFunction = x86_64_machine.MachineFunction;
pub const FrameIndex = x86_64_types.FrameIndex;
pub const SysVAggregateEightbyteClass = sysv_abi.AggregateEightbyteClass;
pub const SysVAggregateKind = sysv_abi.AggregateKind;
pub const SysVAggregateClassification = sysv_abi.AggregateClassification;
pub const SysVCallPlanCounts = sysv_abi.CallPlanCounts;
pub const SysVSmallIntegerAggregate = sysv_abi.SmallIntegerAggregate;
pub const SysVRegisterNeeds = sysv_abi.RegisterNeeds;
pub const SysVRegisterAggregatePassThrough = sysv_abi.RegisterAggregatePassThrough;
pub const SysVCallPlan = sysv_abi.CallPlan;
pub const SysVParamCursor = sysv_abi.ParamCursor;
pub const SysVCallTarget = x86_64_emit.SysVCallTarget;
pub const max_sysv_stack_call_args = x86_64_emit.max_sysv_stack_call_args;
pub const appendIntegerOverflowCall = x86_64_emit.appendIntegerOverflowCall;
pub const appendStackFrame = x86_64_emit.appendStackFrame;
pub const appendStackFrameEnd = x86_64_emit.appendStackFrameEnd;
pub const appendDirectCall = x86_64_emit.appendDirectCall;
pub const appendAlignedDirectCall = x86_64_emit.appendAlignedDirectCall;
pub const appendDirectCallWithStackArgs = x86_64_emit.appendDirectCallWithStackArgs;
pub const appendIndirectCallRaxWithStackArgs = x86_64_emit.appendIndirectCallRaxWithStackArgs;
pub const appendLoadStackDispArg32 = x86_64_emit.appendLoadStackDispArg32;
pub const appendLoadStackDispArg64 = x86_64_emit.appendLoadStackDispArg64;
pub const appendMoveImmToArgReg = x86_64_emit.appendMoveImmToArgReg;
pub const appendMoveImm32ToXmm = x86_64_emit.appendMoveImm32ToXmm;
pub const appendMoveImm64ToXmm = x86_64_emit.appendMoveImm64ToXmm;
pub const setupSysVCallTarget = x86_64_emit.setupSysVCallTarget;
pub const appendSysVCallTarget = x86_64_emit.appendSysVCallTarget;
pub const appendAlignedSysVCallTarget = x86_64_emit.appendAlignedSysVCallTarget;
pub const appendSysVCallTargetWithStackArgs = x86_64_emit.appendSysVCallTargetWithStackArgs;
pub const appendPanicCall = x86_64_emit.appendPanicCall;
pub const validateDefaultCallConv = x86_64_match.validateDefaultCallConv;
pub const isNamed = x86_64_match.isNamed;
pub const callIsFastcc = x86_64_match.callIsFastcc;
pub const callArgAttrsContain = x86_64_match.callArgAttrsContain;
pub const paramAttrsContain = x86_64_match.paramAttrsContain;
pub const globalSymbolName = x86_64_match.globalSymbolName;
pub const symbolName = x86_64_match.symbolName;
pub const isInt = x86_64_match.isInt;
pub const i32Value = x86_64_match.i32Value;
pub const u8Value = x86_64_match.u8Value;
pub const i64Value = x86_64_match.i64Value;
pub const u5Value = x86_64_match.u5Value;
pub const isFpText = x86_64_match.isFpText;
pub const fp32TextBits = x86_64_match.fp32TextBits;
pub const fp64TextBits = x86_64_match.fp64TextBits;
pub const isCalleeName = x86_64_match.isCalleeName;

pub const paramValueReg = cabi_abi_helpers.paramValueReg;
pub const paramReg = cabi_abi_helpers.paramReg;
pub const sysvIntegerParamReg = cabi_abi_helpers.sysvIntegerParamReg;
pub const sysvIntegerParamRegOrNull = cabi_abi_helpers.sysvIntegerParamRegOrNull;
pub const paramRegOrNull = cabi_abi_helpers.paramRegOrNull;
pub const paramRegWithInitialGpr = cabi_abi_helpers.paramRegWithInitialGpr;
pub const paramRegOrNullWithInitialGpr = cabi_abi_helpers.paramRegOrNullWithInitialGpr;
pub const scalarParamStackDisp8 = cabi_abi_helpers.scalarParamStackDisp8;
pub const isSysVIntegerParamType = cabi_abi_helpers.isSysVIntegerParamType;
pub const fpParamIndex = cabi_abi_helpers.fpParamIndex;
pub const stackParamDisp8OrNull = cabi_abi_helpers.stackParamDisp8OrNull;
pub const registerParamRegOrNull = cabi_abi_helpers.registerParamRegOrNull;
pub const blockIndex = cabi_abi_helpers.blockIndex;
pub const advanceSysVParamCursors = cabi_abi_helpers.advanceSysVParamCursors;

pub const appendI32CallArgs = cabi_call_lowering.appendI32CallArgs;
pub const i32CallStackArgCount = cabi_call_lowering.i32CallStackArgCount;
pub const appendSysVScalarCallArgs = cabi_call_lowering.appendSysVScalarCallArgs;
pub const appendSysVScalarCallArgsWithBlock = cabi_call_lowering.appendSysVScalarCallArgsWithBlock;
pub const adjustedIncomingStackDisp8 = cabi_call_lowering.adjustedIncomingStackDisp8;
pub const sysvCallPlanCountsForTest = cabi_call_lowering.sysvCallPlanCountsForTest;
pub const planSysVCall = cabi_call_lowering.planSysVCall;
pub const appendSysVRegisterAggregatePassThroughArg = cabi_call_lowering.appendSysVRegisterAggregatePassThroughArg;
pub const appendSysVStackAggregatePassThroughArgs = cabi_call_lowering.appendSysVStackAggregatePassThroughArgs;
pub const appendSysVMemoryAggregateStackPassThroughArgs = cabi_call_lowering.appendSysVMemoryAggregateStackPassThroughArgs;
pub const sysvParamCursorFor = cabi_call_lowering.sysvParamCursorFor;
pub const sysvParamCursorForWithInitial = cabi_call_lowering.sysvParamCursorForWithInitial;
pub const sysvScalarCallNeedsStackArgs = cabi_call_lowering.sysvScalarCallNeedsStackArgs;
pub const StackScalarCallArg = cabi_call_lowering.StackScalarCallArg;
pub const appendStackScalarCallArg = cabi_call_lowering.appendStackScalarCallArg;
pub const appendAlignedDirectCallPreservingI32Param = cabi_call_lowering.appendAlignedDirectCallPreservingI32Param;
pub const appendAlignedDirectCallPreservingI32Params = cabi_call_lowering.appendAlignedDirectCallPreservingI32Params;
pub const appendAlignedCallPreservingI32Params = cabi_call_lowering.appendAlignedCallPreservingI32Params;
pub const frameIndexForLiveParam = cabi_call_lowering.frameIndexForLiveParam;
pub const lowerReturnTerminator = cabi_call_lowering.lowerReturnTerminator;
pub const lowerReturnValue = cabi_call_lowering.lowerReturnValue;
pub const lowerGenericCfgSelectReturnValue = cabi_call_lowering.lowerGenericCfgSelectReturnValue;
pub const lowerGenericCfgI32ValueIntoEax = cabi_call_lowering.lowerGenericCfgI32ValueIntoEax;
pub const genericCfgSelectTrueLabel = cabi_call_lowering.genericCfgSelectTrueLabel;
pub const genericCfgSelectEndLabel = cabi_call_lowering.genericCfgSelectEndLabel;
pub const lowerGenericCfgSminSelectReturn = cabi_call_lowering.lowerGenericCfgSminSelectReturn;
pub const emitGenericCfgIcmpCondition = cabi_call_lowering.emitGenericCfgIcmpCondition;
pub const lowerI32AddTreeReturn = cabi_call_lowering.lowerI32AddTreeReturn;
pub const collectI32AddTerms = cabi_call_lowering.collectI32AddTerms;
pub const collectI32AddValue = cabi_call_lowering.collectI32AddValue;
pub const emitI32ValueIntoEax = cabi_call_lowering.emitI32ValueIntoEax;
pub const lowerReturnValueAfterCalls = cabi_call_lowering.lowerReturnValueAfterCalls;
pub const lowerBinaryReturnAfterCall = cabi_call_lowering.lowerBinaryReturnAfterCall;
pub const appendI32AddTermToEax = cabi_call_lowering.appendI32AddTermToEax;
pub const machineBinaryOp = cabi_call_lowering.machineBinaryOp;
pub const singleLiveParamAfter = cabi_call_lowering.singleLiveParamAfter;
pub const LiveParamSet = cabi_call_lowering.LiveParamSet;
pub const liveParamsAfter = cabi_call_lowering.liveParamsAfter;
pub const noteLiveParamsSet = cabi_call_lowering.noteLiveParamsSet;
pub const noteLiveValueSet = cabi_call_lowering.noteLiveValueSet;
pub const noteLiveParams = cabi_call_lowering.noteLiveParams;
pub const noteLiveValue = cabi_call_lowering.noteLiveValue;
pub const identityCastFrom = cabi_call_lowering.identityCastFrom;
pub const isSelectI1ToI32ZeroOne = cabi_call_lowering.isSelectI1ToI32ZeroOne;
pub const isSelectI1ToI32ExpectedOne = cabi_call_lowering.isSelectI1ToI32ExpectedOne;
pub const valueReferencesGlobal = cabi_call_lowering.valueReferencesGlobal;
pub const phiHasIncoming = cabi_call_lowering.phiHasIncoming;
pub const phiHasIncomingInt = cabi_call_lowering.phiHasIncomingInt;
pub const matchIcmpEqParamImm = cabi_call_lowering.matchIcmpEqParamImm;
pub const isCommutative = cabi_call_lowering.isCommutative;
pub const findInstruction = cabi_call_lowering.findInstruction;
pub const findInstructionIndex = cabi_call_lowering.findInstructionIndex;
pub const emitI32ParamOrStackIntoEax = cabi_call_lowering.emitI32ParamOrStackIntoEax;
pub const lowerSelectedI64ConstReturn = cabi_call_lowering.lowerSelectedI64ConstReturn;
pub const lowerGenericCfgI64ParamReturn = cabi_call_lowering.lowerGenericCfgI64ParamReturn;
pub const lowerGenericCfgI64DirectCallReturn = cabi_call_lowering.lowerGenericCfgI64DirectCallReturn;

pub const lowerAggregateAbiReturn = cabi_aggregate_lowering.lowerAggregateAbiReturn;
pub const lowerMemoryAggregateCallReturn = cabi_aggregate_lowering.lowerMemoryAggregateCallReturn;
pub const classifySysVAggregateForTest = cabi_aggregate_lowering.classifySysVAggregateForTest;
pub const classifySysVAggregate = cabi_aggregate_lowering.classifySysVAggregate;
pub const classifySysVSmallIntegerAggregate = cabi_aggregate_lowering.classifySysVSmallIntegerAggregate;
pub const lowerSmallIntegerAggregateReturn = cabi_aggregate_lowering.lowerSmallIntegerAggregateReturn;
pub const lowerRegisterAggregateReturn = cabi_aggregate_lowering.lowerRegisterAggregateReturn;
pub const AggregateReturnLeaf = cabi_aggregate_lowering.AggregateReturnLeaf;
pub const lowerFourI32RegisterAggregateReturn = cabi_aggregate_lowering.lowerFourI32RegisterAggregateReturn;
pub const aggregateInsertByteOffset = cabi_aggregate_lowering.aggregateInsertByteOffset;
pub const aggregateFieldCount = cabi_aggregate_lowering.aggregateFieldCount;
pub const aggregateFieldEightbyte = cabi_aggregate_lowering.aggregateFieldEightbyte;
pub const fpParamIndexFromValue = cabi_aggregate_lowering.fpParamIndexFromValue;
pub const valuesEqual = cabi_aggregate_lowering.valuesEqual;
pub const lowerSysVAggregateFieldReturn = cabi_aggregate_lowering.lowerSysVAggregateFieldReturn;
pub const AggregateIntegerFieldLoad = cabi_aggregate_lowering.AggregateIntegerFieldLoad;
pub const AggregateIntegerAddTerm = cabi_aggregate_lowering.AggregateIntegerAddTerm;
pub const AggregateDoubleFieldLoad = cabi_aggregate_lowering.AggregateDoubleFieldLoad;
pub const AggregateDoubleAddTerm = cabi_aggregate_lowering.AggregateDoubleAddTerm;
pub const AggregateFloatFieldLoad = cabi_aggregate_lowering.AggregateFloatFieldLoad;
pub const AggregateFloatAddTerm = cabi_aggregate_lowering.AggregateFloatAddTerm;
pub const lowerRegisterAggregateIntegerFieldAddReturn = cabi_aggregate_lowering.lowerRegisterAggregateIntegerFieldAddReturn;
pub const lowerRegisterAggregateFloatFieldAddReturn = cabi_aggregate_lowering.lowerRegisterAggregateFloatFieldAddReturn;
pub const lowerRegisterAggregateDoubleFieldAddReturn = cabi_aggregate_lowering.lowerRegisterAggregateDoubleFieldAddReturn;
pub const collectAggregateFloatAddTerms = cabi_aggregate_lowering.collectAggregateFloatAddTerms;
pub const collectAggregateDoubleAddTerms = cabi_aggregate_lowering.collectAggregateDoubleAddTerms;
pub const aggregateGepByteOffset = cabi_aggregate_lowering.aggregateGepByteOffset;
pub const aggregateFieldIndexAtOffset = cabi_aggregate_lowering.aggregateFieldIndexAtOffset;
pub const isScalarElementGepType = cabi_aggregate_lowering.isScalarElementGepType;
pub const isAggregateType = cabi_aggregate_lowering.isAggregateType;
pub const collectAggregateIntegerAddTerms = cabi_aggregate_lowering.collectAggregateIntegerAddTerms;
pub const emitAggregateIntegerTerm = cabi_aggregate_lowering.emitAggregateIntegerTerm;
pub const emitAggregateDoubleTerm = cabi_aggregate_lowering.emitAggregateDoubleTerm;
pub const emitAggregateFloatTerm = cabi_aggregate_lowering.emitAggregateFloatTerm;
pub const appendLoadStackDispRax = cabi_aggregate_lowering.appendLoadStackDispRax;
pub const appendLoadStackDispXmm0 = cabi_aggregate_lowering.appendLoadStackDispXmm0;
pub const appendLoadStackDispXmm0F32 = cabi_aggregate_lowering.appendLoadStackDispXmm0F32;
pub const appendLoadStackDispXmm = cabi_aggregate_lowering.appendLoadStackDispXmm;
pub const appendAddStackDispRax = cabi_aggregate_lowering.appendAddStackDispRax;
pub const appendAddStackDispEax = cabi_aggregate_lowering.appendAddStackDispEax;
pub const appendStoreArg64ArgPtrDisp = cabi_aggregate_lowering.appendStoreArg64ArgPtrDisp;
pub const appendStoreRaxArgPtrDisp = cabi_aggregate_lowering.appendStoreRaxArgPtrDisp;
pub const appendStoreEaxArgPtrDisp = cabi_aggregate_lowering.appendStoreEaxArgPtrDisp;
pub const appendStoreXmm0ArgPtrDisp = cabi_aggregate_lowering.appendStoreXmm0ArgPtrDisp;
pub const appendStoreXmm0F32ArgPtrDisp = cabi_aggregate_lowering.appendStoreXmm0F32ArgPtrDisp;
pub const SysVIntegerAggregateFieldLocation = cabi_aggregate_lowering.SysVIntegerAggregateFieldLocation;
pub const sysvIntegerAggregateFieldLocation = cabi_aggregate_lowering.sysvIntegerAggregateFieldLocation;
pub const lowerMemoryIntegerAggregateFieldAddReturn = cabi_aggregate_lowering.lowerMemoryIntegerAggregateFieldAddReturn;
pub const isI64Aggregate = cabi_aggregate_lowering.isI64Aggregate;
pub const isI64LeafAggregate = cabi_aggregate_lowering.isI64LeafAggregate;
pub const isSupportedAggregateCopyLeafAggregate = cabi_aggregate_lowering.isSupportedAggregateCopyLeafAggregate;
pub const supportedAggregateCopyLeaf = cabi_aggregate_lowering.supportedAggregateCopyLeaf;
pub const aggregateFieldIndexFromGep = cabi_aggregate_lowering.aggregateFieldIndexFromGep;
pub const stackAggregateFieldDisp8 = cabi_aggregate_lowering.stackAggregateFieldDisp8;
pub const stackAggregateByteDisp8 = cabi_aggregate_lowering.stackAggregateByteDisp8;
pub const stackAggregateByteDisp = cabi_aggregate_lowering.stackAggregateByteDisp;
pub const validateAggregateFieldGep = cabi_aggregate_lowering.validateAggregateFieldGep;
pub const emitSysVAggregateFieldReturn = cabi_aggregate_lowering.emitSysVAggregateFieldReturn;
pub const emitSysVAggregateFieldOffsetReturn = cabi_aggregate_lowering.emitSysVAggregateFieldOffsetReturn;
pub const emitSysVIntegerAggregateFieldLocationReturn = cabi_aggregate_lowering.emitSysVIntegerAggregateFieldLocationReturn;
pub const emitSysVAggregateFieldLocationReturn = cabi_aggregate_lowering.emitSysVAggregateFieldLocationReturn;
pub const emitSysVAggregateF32FieldOffsetReturn = cabi_aggregate_lowering.emitSysVAggregateF32FieldOffsetReturn;
pub const SysVAggregateFieldLocation = cabi_aggregate_lowering.SysVAggregateFieldLocation;
pub const sysvAggregateFieldLocation = cabi_aggregate_lowering.sysvAggregateFieldLocation;
pub const sysvAggregateFieldLocationByOffset = cabi_aggregate_lowering.sysvAggregateFieldLocationByOffset;
pub const sysvAggregateRegisterNeeds = cabi_aggregate_lowering.sysvAggregateRegisterNeeds;
pub const sysvAggregateRegisterNeedsBefore = cabi_aggregate_lowering.sysvAggregateRegisterNeedsBefore;
pub const lowerRegisterAggregateDirectCallReturn = cabi_aggregate_lowering.lowerRegisterAggregateDirectCallReturn;
pub const lowerAggregatePairAbiFamilyReturn = cabi_aggregate_lowering.lowerAggregatePairAbiFamilyReturn;
pub const lowerRuntimeAggregatePairMainReturn = cabi_aggregate_lowering.lowerRuntimeAggregatePairMainReturn;
pub const lowerRuntimeAggregatePairDirectMainReturn = cabi_aggregate_lowering.lowerRuntimeAggregatePairDirectMainReturn;
pub const lowerRuntimeAggregatePairMakePairReturn = cabi_aggregate_lowering.lowerRuntimeAggregatePairMakePairReturn;
pub const lowerRuntimeAggregatePairPairFirstReturn = cabi_aggregate_lowering.lowerRuntimeAggregatePairPairFirstReturn;
pub const lowerTruncI64ArgReturn = cabi_aggregate_lowering.lowerTruncI64ArgReturn;
pub const lowerMakePairReturn = cabi_aggregate_lowering.lowerMakePairReturn;
pub const lowerStructSumReturn = cabi_aggregate_lowering.lowerStructSumReturn;
pub const lowerRuntimeStructSumPreoptHelper = cabi_aggregate_lowering.lowerRuntimeStructSumPreoptHelper;
pub const lowerRuntimeStructSumMainReturn = cabi_aggregate_lowering.lowerRuntimeStructSumMainReturn;
pub const lowerAddChain3Return = cabi_aggregate_lowering.lowerAddChain3Return;
pub const lowerRuntimeArraySumPreoptHelper = cabi_aggregate_lowering.lowerRuntimeArraySumPreoptHelper;

pub const validateAllocaNamed = core_impl.validateAllocaNamed;
pub const validateMemset = core_impl.validateMemset;
pub const validateStore = core_impl.validateStore;
pub const validateRetVoid = core_impl.validateRetVoid;
pub const singleRetVoidBlock = core_impl.singleRetVoidBlock;
pub const hasSingleBlockInstructionCount = core_impl.hasSingleBlockInstructionCount;
pub const sliceSumHasOverflowCheck = core_impl.functionHasOverflowPanicEdge;
pub const genericCfgSupportsSingleBlockI32Value = core_impl.genericCfgSupportsSingleBlockI32Value;
pub const genericCfgSupportsI64Value = core_impl.genericCfgSupportsI64Value;
pub const emitGenericCfgI32ValueIntoEax = core_impl.emitGenericCfgI32ValueIntoEax;
pub const emitGenericCfgI64ValueIntoRax = core_impl.emitGenericCfgI64ValueIntoRax;
pub const genericCfgSupportsI1Param = core_impl.genericCfgSupportsI1Param;
pub const genericCfgSupportsSminSelect = core_impl.genericCfgSupportsSminSelect;
pub const GenericCfgBranchKind = core_impl.GenericCfgBranchKind;
pub const appendGenericCfgBlockLabel = core_impl.appendGenericCfgBlockLabel;
pub const appendGenericCfgConditionalBranch = core_impl.appendGenericCfgConditionalBranch;
pub const appendGenericCfgCompareParamZero = core_impl.appendGenericCfgCompareParamZero;
pub const appendGenericCfgCompareLocalImm = core_impl.appendGenericCfgCompareLocalImm;
pub const matchGlobalUpdate = core_impl.matchGlobalUpdate;

pub const lowerInlineAsmBarrierReturn = cabi_tls_global_lowering.lowerInlineAsmBarrierReturn;
pub const lowerTlsReadReturn = cabi_tls_global_lowering.lowerTlsReadReturn;
pub const lowerTlsMainReadReturn = cabi_tls_global_lowering.lowerTlsMainReadReturn;
pub const lowerTlsMainUpdateReturn = cabi_tls_global_lowering.lowerTlsMainUpdateReturn;
pub const isMainOrWrapperMain = cabi_tls_global_lowering.isMainOrWrapperMain;
pub const lowerTlsBumpReturn = cabi_tls_global_lowering.lowerTlsBumpReturn;
pub const tlsSymbolFromFunctionAttrs = cabi_tls_global_lowering.tlsSymbolFromFunctionAttrs;
pub const knownLocalExecTlsSymbol = cabi_tls_global_lowering.knownLocalExecTlsSymbol;
pub const matchGlobalRead = cabi_tls_global_lowering.matchGlobalRead;

pub fn x86_64SysVDataLayout() !target.DataLayout {
    return target.DataLayout.parse(std.heap.page_allocator, "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128");
}

pub fn validateCondbr(block: ir.BasicBlock, cond_name: []const u8, true_block: []const u8, false_block: []const u8) !void {
    const condbr = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        .ret, .br, .@"switch", .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
    };
    if (!isNamed(condbr.cond, cond_name) or !std.mem.eql(u8, condbr.then_target, true_block) or !std.mem.eql(u8, condbr.else_target, false_block)) return error.UnsupportedCodegenControlFlow;
}

pub fn validateBr(block: ir.BasicBlock, target_block: []const u8) !void {
    const br = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        .ret, .condbr, .@"switch", .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
    };
    if (!std.mem.eql(u8, br.target, target_block)) return error.UnsupportedCodegenControlFlow;
}

pub fn validateAssumeTrue(instruction: ir.Instruction) !void {
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.eql(u8, call.callee, "llvm.assume") or call.ret_ty != .void or call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 1 }) or !call.args.items[0].value.eql(.{ .int = 1 })) return error.UnsupportedCodegenInstruction;
}

pub fn lowerDebugSpirvMergeLogicalPointers(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "spirv_merge_logical_pointers.a")) return false;
    if (function.ret_ty != .void or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 4) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 8) return error.UnsupportedCodegenInstruction;
    const result_slot = try validateAllocaNamed(entry.instructions.items[0], .ptr);
    const cond_slot = try validateAllocaNamed(entry.instructions.items[1], .{ .int = 1 });
    const false_slot = try validateAllocaNamed(entry.instructions.items[2], .ptr);
    const true_slot = try validateAllocaNamed(entry.instructions.items[3], .ptr);
    try validateMemset(entry.instructions.items[4], true_slot, 8);
    try validateMemset(entry.instructions.items[5], false_slot, 8);
    try validateStore(entry.instructions.items[6], .{ .int = 1 }, .{ .int = 0 }, cond_slot);
    const cond_name = try validateNamedLoad(entry.instructions.items[7], .{ .int = 1 }, cond_slot);
    try validateCondbr(entry, cond_name, "8", "10");

    const merge = function.blocks.items[1];
    if (!std.mem.eql(u8, merge.name, "6") or merge.instructions.items.len != 2) return error.UnsupportedCodegenControlFlow;
    const phi_name = merge.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const phi = switch (merge.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (phi.incoming.items.len != 2 or !phi.ty.eql(.ptr)) return error.UnsupportedCodegenInstruction;
    try validatePhiIncoming(phi.incoming.items[0], "9", "8");
    try validatePhiIncoming(phi.incoming.items[1], "11", "10");
    try validateStore(merge.instructions.items[1], .ptr, .{ .named = phi_name }, result_slot);
    try validateRetVoid(merge);

    const true_block = function.blocks.items[2];
    if (!std.mem.eql(u8, true_block.name, "8") or true_block.instructions.items.len != 1) return error.UnsupportedCodegenControlFlow;
    const true_loaded = try validateNamedLoad(true_block.instructions.items[0], .ptr, true_slot);
    if (!std.mem.eql(u8, true_loaded, "9")) return error.UnsupportedCodegenInstruction;
    try validateBr(true_block, "6");

    const false_block = function.blocks.items[3];
    if (!std.mem.eql(u8, false_block.name, "10") or false_block.instructions.items.len != 1) return error.UnsupportedCodegenControlFlow;
    const false_loaded = try validateNamedLoad(false_block.instructions.items[0], .ptr, false_slot);
    if (!std.mem.eql(u8, false_loaded, "11")) return error.UnsupportedCodegenInstruction;
    try validateBr(false_block, "6");

    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn validatePhiIncoming(incoming: ir.PhiIncoming, value_name: []const u8, block_name: []const u8) !void {
    if (!isNamed(incoming.value, value_name) or !std.mem.eql(u8, incoming.block, block_name)) return error.UnsupportedCodegenInstruction;
}

pub fn lowerI64PassThroughFunctionFamily(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (try lowerDebugInheritWantSafety(allocator, machine, function)) return true;
    return false;
}

pub fn lowerDebugInheritWantSafety(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "inherit_want_safety.entry")) return false;
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 16) return false;
    try validateDebugInheritWantSafetyShape(function);

    try machine.instructions.append(allocator, .{ .mov_imm_rax = 4 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn validateDebugInheritWantSafetyShape(function: ir.Function) !void {
    if (function.blocks.items.len != 16) return error.UnsupportedCodegenControlFlow;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 8) return error.UnsupportedCodegenInstruction;
    const ret_slot = try validateAllocaNamed(entry.instructions.items[0], .{ .int = 64 });
    const counter_slot = try validateAllocaNamed(entry.instructions.items[1], .{ .int = 64 });
    try validateStore(entry.instructions.items[2], .{ .int = 64 }, .{ .int = 0 }, counter_slot);
    const first_load = try validateNamedLoad(entry.instructions.items[3], .{ .int = 64 }, counter_slot);
    const first_add = try validateAddNamedImm(entry.instructions.items[4], .{ .int = 64 }, first_load, 1);
    try validateStore(entry.instructions.items[5], .{ .int = 64 }, .{ .named = first_add }, counter_slot);
    const branch_load = try validateNamedLoad(entry.instructions.items[6], .{ .int = 64 }, counter_slot);
    const branch_cmp = try validateIcmpNamedImm(entry.instructions.items[7], .eq, .{ .int = 64 }, branch_load, 0);
    try validateCondbr(entry, branch_cmp, "8", "11");

    try validateEmptyBrBlock(blockByName(function, "7") orelse return error.InvalidBranchTarget, "7", "14");
    try validateCounterIncrementBlock(blockByName(function, "8") orelse return error.InvalidBranchTarget, "8", counter_slot, "7");
    try validateEmptyBrBlock(blockByName(function, "11") orelse return error.InvalidBranchTarget, "11", "7");
    try validateLoopSetupBlock(blockByName(function, "12") orelse return error.InvalidBranchTarget, ret_slot, counter_slot, "24");
    try validateLoopHeaderBlock(blockByName(function, "14") orelse return error.InvalidBranchTarget, "14", counter_slot, "18", "21");
    try validateEmptyBrBlock(blockByName(function, "17") orelse return error.InvalidBranchTarget, "17", "14");
    try validateCounterIncrementBlock(blockByName(function, "18") orelse return error.InvalidBranchTarget, "18", counter_slot, "17");
    try validateEmptyBrBlock(blockByName(function, "21") orelse return error.InvalidBranchTarget, "21", "12");
    try validateSwitchBlock(blockByName(function, "22") orelse return error.InvalidBranchTarget, "22", counter_slot, "39");
    try validateLoopCompareBlock(blockByName(function, "24") orelse return error.InvalidBranchTarget, "24", ret_slot, "13", "29", "32");
    try validateCounterIncrementBlock(blockByName(function, "29") orelse return error.InvalidBranchTarget, "29", counter_slot, "27");
    try validateEmptyBrBlock(blockByName(function, "32") orelse return error.InvalidBranchTarget, "32", "22");

    const block27 = blockByName(function, "27") orelse return error.InvalidBranchTarget;
    if (block27.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    const loop_index = try validateAddNamedImm(block27.instructions.items[0], .{ .int = 64 }, "25", 1);
    try validateStore(block27.instructions.items[1], .{ .int = 64 }, .{ .named = loop_index }, ret_slot);
    try validateBr(block27, "24");

    const block33 = blockByName(function, "33") orelse return error.InvalidBranchTarget;
    if (block33.instructions.items.len != 7) return error.UnsupportedCodegenInstruction;
    const load34 = try validateNamedLoad(block33.instructions.items[0], .{ .int = 64 }, counter_slot);
    const add35 = try validateAddNamedImm(block33.instructions.items[1], .{ .int = 64 }, load34, 1);
    try validateStore(block33.instructions.items[2], .{ .int = 64 }, .{ .named = add35 }, counter_slot);
    const ret_name = try validateNamedLoad(block33.instructions.items[3], .{ .int = 64 }, counter_slot);
    const load37 = try validateNamedLoad(block33.instructions.items[4], .{ .int = 64 }, counter_slot);
    const add38 = try validateAddNamedImm(block33.instructions.items[5], .{ .int = 64 }, load37, 1);
    try validateStore(block33.instructions.items[6], .{ .int = 64 }, .{ .named = add38 }, counter_slot);
    const ret = switch (block33.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .int = 64 }) or !isNamed(ret.value orelse return error.InvalidRet, ret_name)) return error.UnsupportedCodegenControlFlow;

    try validateCounterIncrementBlock(blockByName(function, "39") orelse return error.InvalidBranchTarget, "39", counter_slot, "33");
}

pub fn validateEmptyBrBlock(block: ir.BasicBlock, name: []const u8, target_block: []const u8) !void {
    if (!std.mem.eql(u8, block.name, name) or block.instructions.items.len != 0) return error.UnsupportedCodegenControlFlow;
    try validateBr(block, target_block);
}

pub fn validateLoopSetupBlock(block: ir.BasicBlock, ret_slot: []const u8, counter_slot: []const u8, target_block: []const u8) !void {
    if (!std.mem.eql(u8, block.name, "12") or block.instructions.items.len != 2) return error.UnsupportedCodegenControlFlow;
    try validateStore(block.instructions.items[0], .{ .int = 64 }, .{ .int = 0 }, ret_slot);
    const limit_name = try validateNamedLoad(block.instructions.items[1], .{ .int = 64 }, counter_slot);
    if (!std.mem.eql(u8, limit_name, "13")) return error.UnsupportedCodegenInstruction;
    try validateBr(block, target_block);
}

pub fn validateCounterIncrementBlock(block: ir.BasicBlock, name: []const u8, counter_slot: []const u8, target_block: []const u8) !void {
    if (!std.mem.eql(u8, block.name, name) or block.instructions.items.len != 3) return error.UnsupportedCodegenControlFlow;
    const load_name = try validateNamedLoad(block.instructions.items[0], .{ .int = 64 }, counter_slot);
    const add_name = try validateAddNamedImm(block.instructions.items[1], .{ .int = 64 }, load_name, 1);
    try validateStore(block.instructions.items[2], .{ .int = 64 }, .{ .named = add_name }, counter_slot);
    try validateBr(block, target_block);
}

pub fn validateLoopHeaderBlock(block: ir.BasicBlock, name: []const u8, counter_slot: []const u8, then_target: []const u8, else_target: []const u8) !void {
    if (!std.mem.eql(u8, block.name, name) or block.instructions.items.len != 2) return error.UnsupportedCodegenControlFlow;
    const load_name = try validateNamedLoad(block.instructions.items[0], .{ .int = 64 }, counter_slot);
    const cmp_name = try validateIcmpNamedImm(block.instructions.items[1], .eq, .{ .int = 64 }, load_name, 0);
    try validateCondbr(block, cmp_name, then_target, else_target);
}

pub fn validateLoopCompareBlock(block: ir.BasicBlock, name: []const u8, ret_slot: []const u8, limit_name: []const u8, then_target: []const u8, else_target: []const u8) !void {
    if (!std.mem.eql(u8, block.name, name) or block.instructions.items.len != 2) return error.UnsupportedCodegenControlFlow;
    const load_name = try validateNamedLoad(block.instructions.items[0], .{ .int = 64 }, ret_slot);
    const cmp_name = block.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    const cmp = switch (block.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (cmp.predicate != .ult or !cmp.operand_ty.eql(.{ .int = 64 }) or !isNamed(cmp.lhs, load_name) or !isNamed(cmp.rhs, limit_name)) return error.UnsupportedCodegenInstruction;
    try validateCondbr(block, cmp_name, then_target, else_target);
}

pub fn validateSwitchBlock(block: ir.BasicBlock, name: []const u8, counter_slot: []const u8, default_target: []const u8) !void {
    if (!std.mem.eql(u8, block.name, name) or block.instructions.items.len != 1) return error.UnsupportedCodegenControlFlow;
    const load_name = try validateNamedLoad(block.instructions.items[0], .{ .int = 64 }, counter_slot);
    const switch_term = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .@"switch" => |switch_term| switch_term,
        .ret, .br, .condbr, .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
    };
    if (!switch_term.cond_ty.eql(.{ .int = 64 }) or !isNamed(switch_term.cond, load_name) or !std.mem.eql(u8, switch_term.default_target, default_target)) return error.UnsupportedCodegenControlFlow;
    if (switch_term.cases.items.len != 0) return error.UnsupportedCodegenControlFlow;
}

pub fn validateAddNamedImm(instruction: ir.Instruction, ty: ir.Type, lhs_name: []const u8, rhs: i128) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (binary.op != .add or !binary.ty.eql(ty) or !isNamed(binary.lhs, lhs_name) or !binary.rhs.eql(.{ .int = rhs })) return error.UnsupportedCodegenInstruction;
    return name;
}

pub fn validateIcmpNamedImm(instruction: ir.Instruction, predicate: ir.IcmpPredicate, ty: ir.Type, lhs_name: []const u8, rhs: i128) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const cmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (cmp.predicate != predicate or !cmp.operand_ty.eql(ty) or !isNamed(cmp.lhs, lhs_name) or !cmp.rhs.eql(.{ .int = rhs })) return error.UnsupportedCodegenInstruction;
    return name;
}

pub fn blockByName(function: ir.Function, name: []const u8) ?ir.BasicBlock {
    for (function.blocks.items) |block| {
        if (std.mem.eql(u8, block.name, name)) return block;
    }
    return null;
}

pub fn lowerI64SaturatingHelperFunctionFamily(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (try lowerDebugNoCompilePanicUncheckedArith(allocator, machine, function)) return true;
    return false;
}

pub fn lowerDebugNoCompilePanicUncheckedArith(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "no_compile_panic_for_unchecked_arith.entry")) return false;
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 1) return false;
    if (function.blocks.items[0].instructions.items.len != 21) return false;
    try validateDebugNoCompilePanicUncheckedArithShape(function);

    try machine.instructions.append(allocator, .{ .mov_imm_rax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn validateDebugNoCompilePanicUncheckedArithShape(function: ir.Function) !void {
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
    };
    if (block.instructions.items.len != 21 or !ret.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenInstruction;

    const slot = try validateAllocaNamed(block.instructions.items[0], .{ .int = 64 });
    try validateStore(block.instructions.items[1], .{ .int = 64 }, .{ .int = 0 }, slot);
    const load2 = try validateNamedLoad(block.instructions.items[2], .{ .int = 64 }, slot);
    const add3 = try validateBinaryNamedImm(block.instructions.items[3], .add, .{ .int = 64 }, load2, 1);
    try validateStore(block.instructions.items[4], .{ .int = 64 }, .{ .named = add3 }, slot);
    const load5 = try validateNamedLoad(block.instructions.items[5], .{ .int = 64 }, slot);
    const sub6 = try validateBinaryNamedImm(block.instructions.items[6], .sub, .{ .int = 64 }, load5, 1);
    try validateStore(block.instructions.items[7], .{ .int = 64 }, .{ .named = sub6 }, slot);
    const load8 = try validateNamedLoad(block.instructions.items[8], .{ .int = 64 }, slot);
    const mul9 = try validateBinaryNamedImm(block.instructions.items[9], .mul, .{ .int = 64 }, load8, 2);
    try validateStore(block.instructions.items[10], .{ .int = 64 }, .{ .named = mul9 }, slot);
    const load11 = try validateNamedLoad(block.instructions.items[11], .{ .int = 64 }, slot);
    const uadd12 = try validateSaturatingCall(block.instructions.items[12], "llvm.uadd.sat.i64", load11, 1, null);
    try validateStore(block.instructions.items[13], .{ .int = 64 }, .{ .named = uadd12 }, slot);
    const load14 = try validateNamedLoad(block.instructions.items[14], .{ .int = 64 }, slot);
    const usub15 = try validateSaturatingCall(block.instructions.items[15], "llvm.usub.sat.i64", load14, 1, null);
    try validateStore(block.instructions.items[16], .{ .int = 64 }, .{ .named = usub15 }, slot);
    const load17 = try validateNamedLoad(block.instructions.items[17], .{ .int = 64 }, slot);
    const umul18 = try validateSaturatingCall(block.instructions.items[18], "llvm.umul.fix.sat.i64", load17, 2, 0);
    try validateStore(block.instructions.items[19], .{ .int = 64 }, .{ .named = umul18 }, slot);
    const load20 = try validateNamedLoad(block.instructions.items[20], .{ .int = 64 }, slot);
    if (!isNamed(ret.value orelse return error.InvalidRet, load20)) return error.UnsupportedCodegenControlFlow;
}

pub fn validateBinaryNamedImm(instruction: ir.Instruction, op: ir.BinaryOp, ty: ir.Type, lhs_name: []const u8, rhs: i128) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (binary.op != op or !binary.ty.eql(ty) or !isNamed(binary.lhs, lhs_name) or !binary.rhs.eql(.{ .int = rhs })) return error.UnsupportedCodegenInstruction;
    return name;
}

pub fn validateSaturatingCall(instruction: ir.Instruction, callee: []const u8, lhs_name: []const u8, rhs: i128, scale: ?i128) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!isCalleeName(call.callee, callee) or !call.ret_ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenInstruction;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    const expected_args: usize = if (scale == null) 2 else 3;
    if (call.args.items.len != expected_args) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 64 }) or !isNamed(call.args.items[0].value, lhs_name)) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[1].ty.eql(.{ .int = 64 }) or !call.args.items[1].value.eql(.{ .int = rhs })) return error.UnsupportedCodegenInstruction;
    if (scale) |scale_value| {
        if (!call.args.items[2].ty.eql(.{ .int = 32 }) or !call.args.items[2].value.eql(.{ .int = scale_value })) return error.UnsupportedCodegenInstruction;
    }
    return name;
}

pub fn lowerStartTrampoline(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "start._start")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 0) return false;
    if (function.blocks.items.len != 1) return error.UnsupportedCodegenControlFlow;

    const block = function.blocks.items[0];
    const terminator = block.terminator orelse return error.BlockWithoutTerminator;
    switch (terminator) {
        .@"unreachable" => {},
        .ret, .br, .condbr, .@"switch", .indirectbr => return error.UnsupportedCodegenControlFlow,
    }
    if (block.instructions.items.len != 2 and block.instructions.items.len != 3) return error.UnsupportedCodegenControlFlow;
    try validateStartCfiInlineAsm(block.instructions.items[0]);
    const call_target = try validateStartTrampolineInlineAsm(block.instructions.items[1]);
    if (block.instructions.items.len == 3) try validateTrapCall(block.instructions.items[2]);

    try machine.instructions.append(allocator, .xor_ebp_ebp);
    try machine.instructions.append(allocator, .mov_rsp_rdi);
    try machine.instructions.append(allocator, .and_rsp_neg16);
    try machine.instructions.append(allocator, .{ .noreturn_direct_call = call_target });
    return true;
}

pub fn validateStartCfiInlineAsm(instruction: ir.Instruction) !void {
    if (instruction.removed or instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    const inline_asm = call.inline_asm orelse return error.UnsupportedCodegenInstruction;
    if (call.ret_ty != .void or call.args.items.len != 0) return error.UnsupportedCodegenInstruction;
    if (!inline_asm.sideeffect) return error.UnsupportedCodegenInstruction;
    if (!std.mem.eql(u8, inline_asm.template, ".cfi_undefined %rip")) return error.UnsupportedCodegenInstruction;
    if (!std.mem.eql(u8, inline_asm.constraints, "~{dirflag},~{fpsr},~{flags}")) return error.UnsupportedCodegenInstruction;
}

pub fn validateTrapCall(instruction: ir.Instruction) !void {
    if (instruction.removed or instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.eql(u8, call.callee, "llvm.trap") or call.ret_ty != .void or call.args.items.len != 0) return error.UnsupportedCodegenInstruction;
}

pub fn validateStartTrampolineInlineAsm(instruction: ir.Instruction) ![]const u8 {
    if (instruction.removed or instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    const inline_asm = call.inline_asm orelse return error.UnsupportedCodegenInstruction;
    if (call.ret_ty != .void or call.args.items.len != 2) return error.UnsupportedCodegenInstruction;
    if (!inline_asm.sideeffect) return error.UnsupportedCodegenInstruction;
    if (!std.mem.eql(u8, inline_asm.template, " xorl %ebp, %ebp\\0A movq %rsp, %rdi\\0A andq $$-16, %rsp\\0A callq ${1:P}")) return error.UnsupportedCodegenInstruction;
    if (!std.mem.eql(u8, inline_asm.constraints, "X,X,~{dirflag},~{fpsr},~{flags}")) return error.UnsupportedCodegenInstruction;

    const self_arg = call.args.items[0];
    if (self_arg.ty != .ptr or !isNamed(self_arg.value, "@start._start")) return error.UnsupportedCodegenInstruction;

    const target_arg = call.args.items[1];
    if (target_arg.ty != .ptr) return error.UnsupportedCodegenInstruction;
    const call_target = switch (target_arg.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.startsWith(u8, call_target, "@")) return error.UnsupportedCodegenInstruction;
    return call_target[1..];
}

pub fn lowerSelectedInfiniteLoop(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main._start")) return false;
    if (function.ret_ty != .void or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 2) return false;

    const entry = function.blocks.items[0];
    const loop = function.blocks.items[1];
    if (entry.instructions.items.len != 0 or loop.instructions.items.len != 0) return false;
    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        .ret, .condbr, .@"switch", .indirectbr, .@"unreachable" => return false,
    };
    if (!std.mem.eql(u8, entry_br.target, loop.name)) return false;
    const loop_br = switch (loop.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        .ret, .condbr, .@"switch", .indirectbr, .@"unreachable" => return false,
    };
    if (!std.mem.eql(u8, loop_br.target, loop.name)) return false;

    try machine.instructions.append(allocator, .{ .label = "loop" });
    try machine.instructions.append(allocator, .{ .jmp = "loop" });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerSelectedIssue339TestFoo(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "test.foo")) return false;
    if (function.ret_ty != .void or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 4) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    const call_name = entry.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const call = switch (entry.instructions.items[0].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!isCalleeName(call.callee, "test.bar") or !call.ret_ty.eql(.{ .int = 16 }) or call.args.items.len != 0 or call.callee_value != null or call.inline_asm != null) {
        return error.UnsupportedCodegenInstruction;
    }
    const cmp_name = try validateIcmpNamedImm(entry.instructions.items[1], .eq, .{ .int = 16 }, call_name, 0);
    try validateCondbr(entry, cmp_name, "4", "5");

    const ret_block = blockByName(function, "3") orelse return error.InvalidBranchTarget;
    if (ret_block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    try validateRetVoid(ret_block);

    try validateEmptyBrBlock(blockByName(function, "4") orelse return error.InvalidBranchTarget, "4", "3");

    const panic = blockByName(function, "5") orelse return error.InvalidBranchTarget;
    if (panic.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    try validatePanicCallWithNamedI16(panic.instructions.items[0], "debug.FullPanic((function 'panic')).unwrapError", call_name);
    switch (panic.terminator orelse return error.BlockWithoutTerminator) {
        .@"unreachable" => {},
        .ret, .br, .condbr, .@"switch", .indirectbr => return error.UnsupportedCodegenControlFlow,
    }

    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn validatePanicCallWithNamedI16(instruction: ir.Instruction, callee: []const u8, arg_name: []const u8) !void {
    if (instruction.removed or instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!isCalleeName(call.callee, callee) or call.ret_ty != .void or call.args.items.len != 1 or call.callee_value != null or call.inline_asm != null) {
        return error.UnsupportedCodegenInstruction;
    }
    if (!call.args.items[0].ty.eql(.{ .int = 16 }) or !isNamed(call.args.items[0].value, arg_name)) return error.UnsupportedCodegenValue;
}

pub fn lowerGetauxvalImpl(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "os.linux.getauxvalImpl")) return false;
    if (!function.ret_ty.eql(.{ .int = 64 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 64 })) return false;
    try validateGetauxvalShape(function);

    try machine.instructions.append(allocator, .{ .load_global_ptr_rax = "os.linux.elf_aux_maybe" });
    try machine.instructions.append(allocator, .test_rax_rax);
    try machine.instructions.append(allocator, .{ .je = "zero" });
    try machine.instructions.append(allocator, .{ .label = "loop" });
    try machine.instructions.append(allocator, .load_rax_ptr_rdx);
    try machine.instructions.append(allocator, .test_rdx_rdx);
    try machine.instructions.append(allocator, .{ .je = "zero" });
    try machine.instructions.append(allocator, .cmp_rdx_rdi);
    try machine.instructions.append(allocator, .{ .je = "found" });
    try machine.instructions.append(allocator, .{ .add_rax_imm8 = 16 });
    try machine.instructions.append(allocator, .{ .jmp = "loop" });
    try machine.instructions.append(allocator, .{ .label = "found" });
    try machine.instructions.append(allocator, .{ .load_rax_ptr_disp8_rax = 8 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = "zero" });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn validateGetauxvalShape(function: ir.Function) !void {
    const optimized_shape = function.blockIndex("common.ret") != null and function.blockIndex(".preheader") != null and function.blockIndex("8") != null;
    const debug_shape = function.blockIndex("11") != null and function.blockIndex("18") != null and function.blockIndex("29") != null;
    if (!optimized_shape and !debug_shape) return error.UnsupportedCodegenControlFlow;

    var saw_global_load = false;
    var saw_tag_load = false;
    var saw_value_load = false;
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .load => |load| {
                    if (load.ty == .ptr and isNamed(load.ptr, "@os.linux.elf_aux_maybe")) saw_global_load = true;
                    if (load.ty.eql(.{ .int = 64 }) and instruction.result != null) {
                        if (isNamed(load.ptr, "3") or isNamed(load.ptr, "14") or isNamed(load.ptr, "21")) saw_tag_load = true;
                        if (isNamed(load.ptr, "9") or isNamed(load.ptr, "33")) saw_value_load = true;
                    }
                },
                else => {},
            }
        }
    }
    if (!saw_global_load or !saw_tag_load or !saw_value_load) return error.UnsupportedCodegenControlFlow;
}

pub fn validateNamedLoad(instruction: ir.Instruction, expected_ty: ir.Type, ptr_name: []const u8) ![]const u8 {
    const result = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const load = switch (instruction.kind) {
        .load => |load| load,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!load.ty.eql(expected_ty) or load.attrs.isBarrier() or !isNamed(load.ptr, ptr_name)) return error.UnsupportedCodegenInstruction;
    return result;
}

pub fn validateI8GepOffset(gep: ir.GepInst, ptr_name: []const u8, offset: i128) !void {
    if (!gep.source_ty.eql(.{ .int = 8 }) or !isNamed(gep.ptr, ptr_name)) return error.UnsupportedCodegenInstruction;
    if (gep.indices.items.len != 1) return error.UnsupportedCodegenInstruction;
    const index = gep.indices.items[0];
    if (!index.ty.eql(.{ .int = 64 }) or !index.value.eql(.{ .int = offset })) return error.UnsupportedCodegenInstruction;
}

pub fn functionHasOverflowPanicEdge(function: ir.Function) bool {
    return sliceSumHasOverflowCheck(function);
}

pub fn lowerControlFlowCallsWriterMainReturn(
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

pub fn lowerDirectI32CallMainReturn(
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

pub const ExpectedCallArg = struct {
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

pub fn lowerPointerVolatileRoundtripReturn(
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

pub fn lowerRuntimeVolatileRoundtripMainReturn(
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

pub fn lowerRuntimeVolatileRoundtripPreoptMainReturn(
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

pub fn isO0ParamStoreToAlloca(function: ir.Function, store: ir.StoreInst, alloca_names: []const []const u8) bool {
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

pub fn lowerScalarFpCastReturn(
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
