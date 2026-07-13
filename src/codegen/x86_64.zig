const x86_64_types = @import("x86_64/types.zig");
const sysv_abi = @import("x86_64/sysv_abi.zig");
const x86_64_generic_cfg = @import("x86_64/generic_cfg.zig");
const x86_64_verify = @import("x86_64/verify.zig");
const x86_64_air_patterns = @import("x86_64/air_patterns.zig");
const x86_64_machine = @import("x86_64/machine.zig");
const x86_64_emit = @import("x86_64/emit.zig");

pub const ArgReg = x86_64_types.ArgReg;
pub const XmmReg = x86_64_types.XmmReg;
pub const MachineBinaryOp = x86_64_types.MachineBinaryOp;
pub const FrameIndex = x86_64_types.FrameIndex;
pub const CodegenPath = x86_64_types.CodegenPath;
pub const CodegenOptions = x86_64_types.CodegenOptions;
pub const ReadOnlyModuleContext = x86_64_types.ReadOnlyModuleContext;
pub const SysVAggregateEightbyteClass = sysv_abi.AggregateEightbyteClass;
pub const SysVAggregateKind = sysv_abi.AggregateKind;
pub const SysVAggregateClassification = sysv_abi.AggregateClassification;
pub const SysVCallPlanCounts = sysv_abi.CallPlanCounts;

pub const sysvCallPlanCountsForTest = x86_64_generic_cfg.sysvCallPlanCountsForTest;
pub const sysvScalarCallNeedsStackArgsForTest = x86_64_generic_cfg.sysvScalarCallNeedsStackArgs;
pub const sysvReturnPlanCountsForTest = sysv_abi.planReturn;
pub const maxSysVStackCallArgsForTest = x86_64_emit.max_sysv_stack_call_args;

pub const Instruction = x86_64_machine.Instruction;
pub const MachineFunction = x86_64_machine.MachineFunction;

pub const lowerFunction = x86_64_air_patterns.lowerFunction;
pub const lowerFunctionWithOptions = x86_64_air_patterns.lowerFunctionWithOptions;
pub const verifyFunction = x86_64_verify.verifyFunction;
pub const classifySysVAggregateForTest = x86_64_air_patterns.classifySysVAggregateForTest;
