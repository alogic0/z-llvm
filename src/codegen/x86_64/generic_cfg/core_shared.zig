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

pub fn x86_64SysVDataLayout() !target.DataLayout {
    return try sysv_abi.dataLayout();
}

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
pub const globalSymbolNameFromValue = x86_64_match.globalSymbolNameFromValue;
pub const symbolName = x86_64_match.symbolName;
pub const isInt = x86_64_match.isInt;
pub const i32BitPattern = x86_64_match.i32BitPattern;
pub const i32Value = x86_64_match.i32Value;
pub const u8Value = x86_64_match.u8Value;
pub const i64Value = x86_64_match.i64Value;
pub const u5Value = x86_64_match.u5Value;
pub const isFpText = x86_64_match.isFpText;
pub const fp32TextBits = x86_64_match.fp32TextBits;
pub const fp64TextBits = x86_64_match.fp64TextBits;
pub const isCalleeName = x86_64_match.isCalleeName;

pub const lowerSelectedRuntimeFloatCallCompareMainReturn = runtime_float.lowerSelectedRuntimeFloatCallCompareMainReturn;
pub const lowerRuntimeFloatLessMainReturn = runtime_float.lowerRuntimeFloatLessMainReturn;
