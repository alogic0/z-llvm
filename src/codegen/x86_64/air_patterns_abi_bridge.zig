const std = @import("std");
const air_capabilities = @import("../../zig_air_capabilities.zig");
const ir = @import("../../ir.zig");
const target = @import("../../target.zig");
const type_layout = @import("../../zig_air_type_layout.zig");
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

pub fn lowerAggregateAbiReturn(
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
    if (try lowerSysVAggregateFieldImmAddReturn(allocator, machine, function, block, ret)) return true;
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
    if (leaf_count == 0) {
        const ret_value = ret.value orelse return false;
        if (ret_value == .zero_initializer) {
            for (0..classification.eightbyte_count) |i| {
                const class = classification.eightbytes[i] orelse break;
                switch (class) {
                    .integer => switch (i) {
                        0 => try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 }),
                        1 => try machine.instructions.append(allocator, .xor_edx_edx),
                        else => return false,
                    },
                    else => return false,
                }
            }
            try machine.instructions.append(allocator, .ret);
            return true;
        }
        return false;
    }
    if (leaf_count > 8) return false;

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
                    (leaves[leaf_index + 1].ty.eql(.{ .int = 32 }) or
                        leaves[leaf_index + 1].ty.eql(.{ .int = 16 }) or
                        leaves[leaf_index + 1].ty.eql(.{ .int = 8 })) and
                    leaves[leaf_index + 1].offset / 8 == leaf_eightbyte and
                    leaves[leaf_index + 1].offset % 8 == 4)
                {
                    const next_leaf = leaves[leaf_index + 1];
                    const high_reg = try paramValueReg(function, next_leaf.value, next_leaf.ty);
                    switch (gpr_return_index) {
                        0 => {
                            if (next_leaf.ty.eql(.{ .int = 32 })) {
                                try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rdx, .src = high_reg } });
                                try machine.instructions.append(allocator, .{ .shl_rdx_imm6 = 32 });
                                try machine.instructions.append(allocator, .{ .mov_arg_eax = low_reg });
                                try machine.instructions.append(allocator, .or_rdx_rax);
                            } else {
                                try machine.instructions.append(allocator, .{ .mov_arg_eax = high_reg });
                                const mask: i32 = switch (next_leaf.ty.int) {
                                    8 => 0xff,
                                    16 => 0xffff,
                                    else => return error.UnsupportedCodegenAbi,
                                };
                                try machine.instructions.append(allocator, .{ .and_eax_imm32 = mask });
                                try machine.instructions.append(allocator, .{ .shl_rax_imm6 = 32 });
                                try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rdx, .src = low_reg } });
                                try machine.instructions.append(allocator, .or_rdx_rax);
                            }
                        },
                        1 => {
                            if (next_leaf.ty.eql(.{ .int = 32 })) {
                                try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rcx, .src = high_reg } });
                                try machine.instructions.append(allocator, .{ .shl_rcx_imm6 = 32 });
                                try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rdx, .src = low_reg } });
                                try machine.instructions.append(allocator, .or_rcx_rdx);
                            } else {
                                return error.UnsupportedCodegenAbi;
                            }
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
                    if (sse_return_index >= 2) return error.UnsupportedCodegenAbi;
                    const low_fp_index = try fpParamIndexFromValue(function, leaf.value, .float);
                    const high_fp_index = try fpParamIndexFromValue(function, leaves[leaf_index + 1].value, .float);
                    const low_reg = try XmmReg.fromIndex(low_fp_index);
                    const high_reg = try XmmReg.fromIndex(high_fp_index);
                    const dst = try XmmReg.fromIndex(sse_return_index);
                    if (low_reg != dst) {
                        try machine.instructions.append(allocator, .{ .movapd_xmm = .{ .dst = dst, .src = low_reg } });
                    }
                    if (high_reg != dst) {
                        try machine.instructions.append(allocator, .{ .unpcklps_xmm = .{ .dst = dst, .src = high_reg } });
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
        offset += type_layout.fieldByteOffset(layout, current_ty, field_index) orelse
            return error.UnsupportedCodegenAbi;
        current_ty = type_layout.fieldType(current_ty, field_index) orelse return error.UnsupportedCodegenAbi;
        rest = if (comma) |pos| rest[pos + 1 ..] else "";
    }
    if (!current_ty.eql(value_ty)) return error.UnsupportedCodegenAbi;
    return offset;
}

fn aggregateFieldCount(ty: ir.Type) ?usize {
    return type_layout.fieldCount(ty);
}

fn aggregateFieldEightbyte(aggregate_ty: ir.Type, field_index: usize) !usize {
    const layout = try x86_64SysVDataLayout();
    const field_offset = type_layout.fieldByteOffset(layout, aggregate_ty, field_index) orelse
        return error.UnsupportedCodegenAbi;
    return @intCast(field_offset / 8);
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
    const is_supported_ret = ret.ty.eql(.{ .int = 32 }) or ret.ty.eql(.{ .int = 64 }) or
        ret.ty.eql(.float) or ret.ty.eql(.double) or
        (switch (ret.ty) {
            .int => |bits| bits > 0 and bits <= 64,
            else => false,
        });
    if (!is_supported_ret) return false;

    const has_trunc = blk: {
        if (block.instructions.items.len < 1) break :blk false;
        const last = block.instructions.items[block.instructions.items.len - 1];
        if (last.removed or last.result == null) break :blk false;
        if (!isNamed(ret.value orelse return error.InvalidRet, last.result.?)) break :blk false;
        const cast = switch (last.kind) {
            .cast => |c| c,
            else => break :blk false,
        };
        break :blk cast.op == .trunc and cast.to_ty.eql(ret.ty);
    };

    const expected_base_len: usize = if (has_trunc) 4 else 3;
    if (block.instructions.items.len != expected_base_len and block.instructions.items.len != expected_base_len + 1) return false;
    const has_gep = block.instructions.items.len == expected_base_len + 1;

    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    const maybe_gep_inst: ?ir.Instruction = if (has_gep) block.instructions.items[2] else null;
    const load_inst = if (has_trunc) block.instructions.items[if (has_gep) 3 else 2] else block.instructions.items[block.instructions.items.len - 1];
    if (alloca_inst.removed or store_inst.removed or load_inst.removed) return false;
    if (maybe_gep_inst) |gep_inst| if (gep_inst.removed) return false;
    const alloca_name = alloca_inst.result orelse return false;
    const load_name = load_inst.result orelse return false;

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
    if (load.attrs.isBarrier()) return false;

    if (has_trunc) {
        const last = block.instructions.items[block.instructions.items.len - 1];
        if (!isNamed(last.kind.cast.value, load_name)) return false;
        if (!load.ty.eql(last.kind.cast.from_ty)) return false;
    } else {
        if (!isNamed(ret.value orelse return error.InvalidRet, load_name)) return false;
        if (!load.ty.eql(ret.ty)) return false;
    }

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
    if (has_trunc) {
        switch (ret.ty) {
            .int => |bits| {
                if (bits < 32) {
                    const mask: i32 = @intCast((@as(u64, 1) << @intCast(bits)) - 1);
                    try machine.instructions.append(allocator, .{ .and_eax_imm32 = mask });
                }
            },
            else => return false,
        }
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerSysVAggregateFieldImmAddReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if ((!ret.ty.eql(.{ .int = 32 }) and !ret.ty.eql(.{ .int = 64 })) or
        (block.instructions.items.len != 4 and block.instructions.items.len != 5)) return false;
    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    const maybe_gep_inst: ?ir.Instruction = if (block.instructions.items.len == 5) block.instructions.items[2] else null;
    const load_inst = if (block.instructions.items.len == 5) block.instructions.items[3] else block.instructions.items[2];
    const binary_inst = block.instructions.items[block.instructions.items.len - 1];
    if (alloca_inst.removed or store_inst.removed or load_inst.removed or binary_inst.removed) return false;
    if (maybe_gep_inst) |gep_inst| if (gep_inst.removed) return false;
    const alloca_name = alloca_inst.result orelse return false;
    const load_name = load_inst.result orelse return false;
    const binary_name = binary_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, binary_name)) return false;

    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };

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

    const binary = switch (binary_inst.kind) {
        .binary => |b| b,
        else => return false,
    };
    if (binary.op != .add or !binary.ty.eql(ret.ty)) return false;
    if (!isNamed(binary.lhs, load_name)) return false;
    const imm = switch (binary.rhs) {
        .int => |imm| imm,
        else => return false,
    };

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
    if (ret.ty.eql(.{ .int = 64 })) {
        if (imm >= 0 and imm <= std.math.maxInt(u8)) {
            try machine.instructions.append(allocator, .{ .add_rax_imm8 = @intCast(imm) });
        } else {
            return false;
        }
    } else if (ret.ty.eql(.{ .int = 32 })) {
        if (imm >= std.math.minInt(i32) and imm <= std.math.maxInt(i32)) {
            try machine.instructions.append(allocator, .{ .add_eax_imm32 = @intCast(imm) });
        } else {
            return false;
        }
    } else {
        return false;
    }
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

    var terms: [8]AggregateFloatAddTerm = undefined;
    var term_count: usize = 0;
    if (!try collectAggregateFloatAddTerms(block, ret.value orelse return error.InvalidRet, field_loads, &terms, &term_count)) return false;
    if (term_count < 2) return false;
    sortAggregateFloatTerms(terms[0..term_count]);

    try emitAggregateFloatTerm(allocator, machine, function, param_name, aggregate_ty, terms[0], .xmm0);
    for (terms[1..term_count]) |term| {
        try emitAggregateFloatTerm(allocator, machine, function, param_name, aggregate_ty, term, .xmm1);
        try machine.instructions.append(allocator, .addss_xmm1_xmm0);
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn sortAggregateFloatTerms(terms: []AggregateFloatAddTerm) void {
    var index: usize = 1;
    while (index < terms.len) : (index += 1) {
        var cursor = index;
        while (cursor > 0 and terms[cursor - 1].offset > terms[cursor].offset) : (cursor -= 1) {
            std.mem.swap(AggregateFloatAddTerm, &terms[cursor - 1], &terms[cursor]);
        }
    }
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
    terms: *[8]AggregateFloatAddTerm,
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
            const offset = type_layout.fieldByteOffset(layout, current_ty, @intCast(field_index)) orelse return null;
            byte_offset += offset;
            current_ty = type_layout.fieldType(current_ty, @intCast(field_index)) orelse return null;
        }
        return byte_offset;
    }
    return null;
}

fn aggregateFieldIndexAtOffset(aggregate_ty: ir.Type, expected_offset: u64, expected_ty: ir.Type) ?usize {
    const layout = x86_64SysVDataLayout() catch return null;
    return type_layout.fieldIndexAtOffset(layout, aggregate_ty, expected_offset, expected_ty);
}

fn isScalarElementGepType(ty: ir.Type) bool {
    return switch (ty) {
        .int, .float, .double, .ptr => true,
        .void, .half, .x86_fp80, .fp128, .metadata, .aggregate, .vector => false,
    };
}

fn isAggregateType(ty: ir.Type) bool {
    return air_capabilities.isAggregateType(ty);
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
            if (classification.kind == .memory) {
                const offset = 8 + stack_eightbytes * 8 + field_offset;
                if (offset > std.math.maxInt(u32)) return error.UnsupportedCodegenAbi;
                return .{ .stack = @intCast(offset) };
            }
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
        const field_ty = type_layout.fieldType(aggregate_ty, field_index) orelse return false;
        if (!field_ty.eql(.{ .int = 64 })) return false;
    }
    return true;
}

fn isI64LeafAggregate(aggregate_ty: ir.Type) bool {
    const field_count = aggregateFieldCount(aggregate_ty) orelse return false;
    if (field_count == 0) return false;
    var field_index: usize = 0;
    while (field_index < field_count) : (field_index += 1) {
        const field_ty = type_layout.fieldType(aggregate_ty, field_index) orelse return false;
        if (field_ty.eql(.{ .int = 64 })) continue;
        if (isAggregateType(field_ty) and isI64LeafAggregate(field_ty)) continue;
        return false;
    }
    return true;
}

fn isSupportedAggregateCopyLeafAggregate(aggregate_ty: ir.Type) bool {
    return type_layout.isSupportedScalarLeafAggregate(aggregate_ty);
}

fn supportedAggregateCopyLeaf(ty: ir.Type) bool {
    return type_layout.isSupportedScalarLeaf(ty);
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
    const field_offset = type_layout.fieldByteOffset(layout, aggregate_ty, field_index) orelse
        return error.UnsupportedCodegenAbi;
    const offset = 8 + field_offset;
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
    const field_offset = type_layout.fieldByteOffset(layout, aggregate_ty, field_index) orelse
        return error.UnsupportedCodegenAbi;
    if (!((type_layout.fieldType(aggregate_ty, field_index) orelse return error.UnsupportedCodegenAbi).eql(field_ty))) {
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
        const stack_arg_count = if (sysv_abi.callHasByvalArgAttrs(call)) count: {
            const count = appendSysVScalarCallArgs(allocator, machine, function, call) catch |err| switch (err) {
                error.UnsupportedCodegenAbi, error.UnsupportedCodegenType, error.UnsupportedCodegenValue => return false,
                else => if (sysv_abi.isBoundaryError(err)) return false else return err,
            };
            try machine.instructions.append(allocator, .{ .mov_arg_rax = callee_reg });
            break :count count;
        } else count: {
            try machine.instructions.append(allocator, .{ .mov_arg_rax = callee_reg });
            break :count appendSysVScalarCallArgs(allocator, machine, function, call) catch |err| switch (err) {
                error.UnsupportedCodegenAbi, error.UnsupportedCodegenType, error.UnsupportedCodegenValue => return false,
                else => if (sysv_abi.isBoundaryError(err)) return false else return err,
            };
        };
        try appendIndirectCallRaxWithStackArgs(allocator, machine, call.ret_ty, stack_arg_count);
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    const stack_arg_count = appendSysVScalarCallArgs(allocator, machine, function, call) catch |err| switch (err) {
        error.UnsupportedCodegenAbi, error.UnsupportedCodegenType, error.UnsupportedCodegenValue => return false,
        else => if (sysv_abi.isBoundaryError(err)) return false else return err,
    };
    try appendDirectCallWithStackArgs(allocator, machine, call.callee, call.ret_ty, stack_arg_count);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerAggregatePairAbiFamilyReturn(
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
    if (!isTwoI32PairAggregate(alloca.allocated_ty)) return false;

    const make_pair = switch (make_pair_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isMakePairSretCall(make_pair, pair_slot_name)) return false;

    const pair_first = switch (pair_first_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isPairFirstPtrCall(pair_first, pair_slot_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn isTwoI32PairAggregate(ty: ir.Type) bool {
    const layout = x86_64SysVDataLayout() catch return false;
    const plan = type_layout.aggregateLayoutPlan(layout, ty) catch return false;
    const leaves = plan.leafSlice();
    return plan.field_count == 2 and leaves.len == 2 and
        leaves[0].offset == 0 and leaves[0].ty.eql(.{ .int = 32 }) and
        leaves[1].offset == 4 and leaves[1].ty.eql(.{ .int = 32 });
}

fn isSretPairSlotArg(arg: ir.CallArg, slot_name: []const u8) bool {
    return arg.ty.eql(.ptr) and callArgAttrsContain(arg, "sret(") and isNamed(arg.value, slot_name);
}

fn isSretPairParam(param: ir.Param) bool {
    return param.ty.eql(.ptr) and paramAttrsContain(param, "sret(");
}

fn isMakePairSretCall(call: ir.CallInst, pair_slot_name: []const u8) bool {
    return callIsFastcc(call.calling_conv) and call.ret_ty == .void and
        call.callee_value == null and call.inline_asm == null and
        call.args.items.len == 3 and
        isSretPairSlotArg(call.args.items[0], pair_slot_name) and
        call.args.items[1].ty.eql(.{ .int = 32 }) and isInt(call.args.items[1].value, 1) and
        call.args.items[2].ty.eql(.{ .int = 32 }) and isInt(call.args.items[2].value, 2);
}

fn isMakePairI64Call(call: ir.CallInst) bool {
    return callIsFastcc(call.calling_conv) and call.ret_ty.eql(.{ .int = 64 }) and
        call.callee_value == null and call.inline_asm == null and
        call.args.items.len == 2 and
        call.args.items[0].ty.eql(.{ .int = 32 }) and isInt(call.args.items[0].value, 1) and
        call.args.items[1].ty.eql(.{ .int = 32 }) and isInt(call.args.items[1].value, 2);
}

fn isPairFirstPtrCall(call: ir.CallInst, pair_slot_name: []const u8) bool {
    return callIsFastcc(call.calling_conv) and call.ret_ty.eql(.{ .int = 32 }) and
        call.callee_value == null and call.inline_asm == null and
        call.args.items.len == 1 and
        call.args.items[0].ty.eql(.ptr) and isNamed(call.args.items[0].value, pair_slot_name);
}

fn isPairFirstI64Call(call: ir.CallInst, pair_value_name: []const u8) bool {
    return callIsFastcc(call.calling_conv) and call.ret_ty.eql(.{ .int = 32 }) and
        call.callee_value == null and call.inline_asm == null and
        call.args.items.len == 1 and
        call.args.items[0].ty.eql(.{ .int = 64 }) and isNamed(call.args.items[0].value, pair_value_name);
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
    if (!isMakePairI64Call(make_pair)) return false;

    const pair_first = switch (pair_first_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isPairFirstI64Call(pair_first, make_pair_name)) return false;

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
    if (!callIsFastcc(function.calling_conv) or function.ret_ty != .void or ret.ty != .void) return false;
    if (function.params.items.len != 3) return false;
    if (!isSretPairParam(function.params.items[0])) return false;
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

    const sret_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const first_reg = try paramReg(function, function.params.items[1].name, .{ .int = 32 });
    const second_reg = try paramReg(function, function.params.items[2].name, .{ .int = 32 });
    try machine.instructions.append(allocator, .{ .mov_arg_eax = first_reg });
    try appendStoreEaxArgPtrDisp(allocator, machine, sret_reg, 0);
    try machine.instructions.append(allocator, .{ .mov_arg_eax = second_reg });
    try appendStoreEaxArgPtrDisp(allocator, machine, sret_reg, 4);
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
    if (!isTwoI32PairAggregate(alloca.allocated_ty)) return false;

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
