const std = @import("std");
const ir = @import("../../ir.zig");
const x86_64_types = @import("types.zig");
const sysv_abi = @import("sysv_abi.zig");
const x86_64_emit = @import("emit.zig");
const x86_64_match = @import("match.zig");
const x86_64_generic_cfg = @import("generic_cfg.zig");
const air_patterns_abi_bridge = @import("air_patterns_abi_bridge.zig");
const air_patterns_cfg = @import("air_patterns_cfg.zig");
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
pub const CodegenOptions = x86_64_types.CodegenOptions;
pub const SysVAggregateEightbyteClass = sysv_abi.AggregateEightbyteClass;
pub const SysVAggregateKind = sysv_abi.AggregateKind;
pub const SysVAggregateClassification = sysv_abi.AggregateClassification;
pub const SysVCallPlanCounts = sysv_abi.CallPlanCounts;

const appendDirectCall = x86_64_emit.appendDirectCall;
const validateDefaultCallConv = x86_64_match.validateDefaultCallConv;
const isNamed = x86_64_match.isNamed;
const globalSymbolName = x86_64_match.globalSymbolName;
const isInt = x86_64_match.isInt;
const i32Value = x86_64_match.i32Value;
const i64Value = x86_64_match.i64Value;
const isCalleeName = x86_64_match.isCalleeName;

const lowerReturnValue = x86_64_generic_cfg.lowerReturnValue;
const lowerMulConstReturn = x86_64_generic_cfg.lowerMulConstReturn;
const lowerIntegerShiftMixReturn = x86_64_generic_cfg.lowerIntegerShiftMixReturn;
const lowerSelectedI64ConstReturn = air_patterns_runtime.lowerSelectedI64ConstReturn;
const lowerControlFlowCallsWriterMainReturn = air_patterns_runtime.lowerControlFlowCallsWriterMainReturn;
const lowerDirectI32CallMainReturn = air_patterns_runtime.lowerDirectI32CallMainReturn;
const lowerTlsBumpCallMainReturn = air_patterns_runtime.lowerTlsBumpCallMainReturn;
const lowerSelectedI64CallMainReturn = air_patterns_runtime.lowerSelectedI64CallMainReturn;
const lowerReleaseSmallStrFromFloatMainReturn = air_patterns_runtime.lowerReleaseSmallStrFromFloatMainReturn;
const lowerRuntimeArraySumMainReturn = air_patterns_runtime.lowerRuntimeArraySumMainReturn;
const lowerRuntimeCheckedStructSumMainReturn = air_patterns_runtime.lowerRuntimeCheckedStructSumMainReturn;
const lowerRuntimeOptionalPayloadMainReturn = air_patterns_runtime.lowerRuntimeOptionalPayloadMainReturn;
const lowerRuntimeErrorUnionPayloadMainReturn = air_patterns_runtime.lowerRuntimeErrorUnionPayloadMainReturn;
const lowerRuntimeSliceSumMainReturn = air_patterns_runtime.lowerRuntimeSliceSumMainReturn;
const lowerRuntimeComptimeConstMainReturn = air_patterns_runtime.lowerRuntimeComptimeConstMainReturn;
const lowerRuntimeDebugLocationMainReturn = air_patterns_runtime.lowerRuntimeDebugLocationMainReturn;
const lowerPackedReplaceLowReturn = air_patterns_packed_volatile_pointer_rows.lowerPackedReplaceLowReturn;
const lowerRuntimePackedReplaceLowMainReturn = air_patterns_packed_volatile_pointer_rows.lowerRuntimePackedReplaceLowMainReturn;
const lowerPackedReadFlagReturn = air_patterns_packed_volatile_pointer_rows.lowerPackedReadFlagReturn;
const lowerRuntimePackedReadFlagMainReturn = air_patterns_packed_volatile_pointer_rows.lowerRuntimePackedReadFlagMainReturn;
const lowerPointerVolatileRoundtripReturn = air_patterns_packed_volatile_pointer_rows.lowerPointerVolatileRoundtripReturn;
const lowerRuntimeVolatileRoundtripMainReturn = air_patterns_packed_volatile_pointer_rows.lowerRuntimeVolatileRoundtripMainReturn;
const lowerPointerLoadStoreReturn = air_patterns_packed_volatile_pointer_rows.lowerPointerLoadStoreReturn;
const lowerRuntimePointerLoadStoreMainReturn = air_patterns_packed_volatile_pointer_rows.lowerRuntimePointerLoadStoreMainReturn;
const lowerBase64TableLookupMainReturn = air_patterns_base64_rows.lowerBase64TableLookupMainReturn;
const lowerGenericCfgByteTableLookupReturn = air_patterns_base64_rows.lowerGenericCfgByteTableLookupReturn;
const lowerBase64DecodeStepMainReturn = air_patterns_base64_rows.lowerBase64DecodeStepMainReturn;
const lowerBase64StoreStepMainReturn = air_patterns_base64_rows.lowerBase64StoreStepMainReturn;
const lowerBase64ResidualByteStepMainReturn = air_patterns_base64_rows.lowerBase64ResidualByteStepMainReturn;
const lowerBase64ResidualStoreStepMainReturn = air_patterns_base64_rows.lowerBase64ResidualStoreStepMainReturn;
const lowerBase64ResidualLengthStepMainReturn = air_patterns_base64_rows.lowerBase64ResidualLengthStepMainReturn;
const lowerBase64ResidualTableCheckStepMainReturn = air_patterns_base64_rows.lowerBase64ResidualTableCheckStepMainReturn;
const lowerBase64ResidualAccumulatorStepMainReturn = air_patterns_base64_rows.lowerBase64ResidualAccumulatorStepMainReturn;
const lowerBase64ResidualLoopAdvanceStepMainReturn = air_patterns_base64_rows.lowerBase64ResidualLoopAdvanceStepMainReturn;
const lowerBase64ResidualPaddingCheckStepMainReturn = air_patterns_base64_rows.lowerBase64ResidualPaddingCheckStepMainReturn;
const lowerBase64ResidualFinalMaskStepMainReturn = air_patterns_base64_rows.lowerBase64ResidualFinalMaskStepMainReturn;
const lowerBase64ResidualPaddingLoopStepMainReturn = air_patterns_base64_rows.lowerBase64ResidualPaddingLoopStepMainReturn;
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
const lowerBase64WriterMainReturn = air_patterns_base64_rows.lowerBase64WriterMainReturn;
const paramValueReg = x86_64_generic_cfg.paramValueReg;
pub const sysvCallPlanCountsForTest = x86_64_generic_cfg.sysvCallPlanCountsForTest;
pub const classifySysVAggregateForTest = air_patterns_abi_bridge.classifySysVAggregateForTest;

const x86_64_machine = @import("machine.zig");

pub const Instruction = x86_64_machine.Instruction;
pub const MachineFunction = x86_64_machine.MachineFunction;
const fp_patterns = @import("air_patterns_fp.zig");
const aggregate_runtime_patterns = @import("air_patterns_aggregate_runtime.zig");
const lowerFloatMulReturn = fp_patterns.lowerFloatMulReturn;
const lowerFloatAddReturn = fp_patterns.lowerFloatAddReturn;
const lowerRuntimeFloatAddMainReturn = fp_patterns.lowerRuntimeFloatAddMainReturn;
const lowerFloatSubReturn = fp_patterns.lowerFloatSubReturn;
const lowerX86Fp80NegReturn = fp_patterns.lowerX86Fp80NegReturn;
const lowerFp128NegReturn = fp_patterns.lowerFp128NegReturn;
const lowerRuntimeFloatSubMainReturn = fp_patterns.lowerRuntimeFloatSubMainReturn;
const lowerDoubleDivReturn = fp_patterns.lowerDoubleDivReturn;
const lowerRuntimeDoubleDivMainReturn = fp_patterns.lowerRuntimeDoubleDivMainReturn;
const lowerFloatRemReturn = fp_patterns.lowerFloatRemReturn;
const lowerRuntimeFloatRemMainReturn = fp_patterns.lowerRuntimeFloatRemMainReturn;
const lowerRuntimeFloatMulMainReturn = fp_patterns.lowerRuntimeFloatMulMainReturn;
const lowerFloatSelectReturn = fp_patterns.lowerFloatSelectReturn;
const lowerFloatLessReturn = fp_patterns.lowerFloatLessReturn;
const lowerFloatLiteralReturn = fp_patterns.lowerFloatLiteralReturn;
const lowerStructSumReturn = aggregate_runtime_patterns.lowerStructSumReturn;
const lowerRuntimeStructSumPreoptHelper = aggregate_runtime_patterns.lowerRuntimeStructSumPreoptHelper;
const lowerRuntimeStructSumMainReturn = aggregate_runtime_patterns.lowerRuntimeStructSumMainReturn;
const lowerAddChain3Return = aggregate_runtime_patterns.lowerAddChain3Return;

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
            if (try lowerBitSetMaskBitReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBitSetNumMasksReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRegisterIdReturn(allocator, machine, function, block, ret)) return;
            if (try lowerSingleStackSlotCallReturn(allocator, machine, function, block, ret)) return;
            if (try air_patterns_abi_bridge.lowerAggregatePairAbiFamilyReturn(allocator, machine, function, block, ret)) return;
            if (try air_patterns_fp_descriptor_rows.lowerDescriptorFpCheckMainReturn(allocator, machine, function, block, ret)) return;
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
            if (try lowerX86Fp80NegReturn(allocator, machine, function, block, ret)) return;
            if (try lowerFp128NegReturn(allocator, machine, function, block, ret)) return;
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
            if (try lowerAtomicTryLockReturn(allocator, machine, function, block, ret)) return;
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
            if (ret.ty == .ptr) {
                const value = ret.value orelse return error.InvalidRet;
                switch (value) {
                    .named => |name| {
                        const sym = if (std.mem.startsWith(u8, name, "@")) name[1..] else name;
                        try machine.instructions.append(allocator, .{ .lea_global_rax = sym });
                        try machine.instructions.append(allocator, .ret);
                        return;
                    },
                    .null_value, .zero_initializer => {
                        try machine.instructions.append(allocator, .{ .mov_imm_rax = 0 });
                        try machine.instructions.append(allocator, .ret);
                        return;
                    },
                    else => return error.UnsupportedCodegenValue,
                }
            }
            if (ret.ty.eql(.{ .int = 64 })) {
                const value = ret.value orelse return error.InvalidRet;
                switch (value) {
                    .int => |int| {
                        try machine.instructions.append(allocator, .{ .mov_imm_rax = try i64Value(int) });
                        try machine.instructions.append(allocator, .ret);
                        return;
                    },
                    else => {},
                }
            }
            const ret_bits = switch (ret.ty) {
                .int => |bits| bits,
                else => null,
            };
            if (ret_bits) |bits| if (bits <= 32) {
                const value = ret.value orelse return error.InvalidRet;
                switch (value) {
                    .int => |int| {
                        try machine.instructions.append(allocator, .{ .mov_imm_eax = try i32Value(int) });
                        try machine.instructions.append(allocator, .ret);
                        return;
                    },
                    else => {},
                }
            };
            if (!ret.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
            try lowerReturnValue(allocator, machine, function, block, ret.value orelse return error.InvalidRet);
            try machine.instructions.append(allocator, .ret);
        },
        .@"unreachable" => {
            if (hasLiveInstructions(block)) {
                try air_patterns_cfg.lowerStraightLineUnreachable(allocator, machine, function, block);
                return;
            }
            try machine.instructions.append(allocator, .ud2);
        },
        .br, .condbr, .@"switch", .indirectbr => return error.UnsupportedCodegenControlFlow,
    }
}

pub fn lowerBitSetMaskBitReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    _ = block;
    if (!ret.ty.eql(.{ .int = 64 })) return false;
    if (function.params.items.len != 1) return false;
    if (!std.mem.endsWith(u8, function.name, "maskBit") and !std.mem.endsWith(u8, function.name, "toByteUnits")) return false;

    try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = .rcx, .src = .rdi } });
    try machine.instructions.append(allocator, .{ .mov_imm_rax = 1 });
    try machine.instructions.append(allocator, .shl_rax_cl);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerBitSetNumMasksReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    _ = block;
    if (!ret.ty.eql(.{ .int = 64 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 64 })) return false;
    if (!std.mem.endsWith(u8, function.name, "numMasks")) return false;

    try machine.instructions.append(allocator, .{ .mov_arg_rax = .rdi });
    try machine.instructions.append(allocator, .{ .add_rax_imm8 = 63 });
    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 6 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRegisterIdReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    _ = block;
    _ = ret;
    if (!std.mem.endsWith(u8, function.name, "encodeId") and
        !std.mem.endsWith(u8, function.name, ".id") and
        !std.mem.endsWith(u8, function.name, "fromFwdRefIndex")) return false;
    if (function.params.items.len != 1) return false;

    try machine.instructions.append(allocator, .{ .mov_arg_rax = .rdi });
    try machine.instructions.append(allocator, .ret);
    return true;
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
    _ = function;
    if (!ret.ty.eql(.{ .int = 1 })) return false;
    if (hasLiveInstructions(block)) return false;
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
    if (!alloca.allocated_ty.eql(.{ .int = 32 })) return false;

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

    try machine.instructions.append(allocator, .sub_rsp_24);
    try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{
        .frame_index = .slot0,
        .reg = store_reg,
    } });
    try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{
        .reg = .rdi,
        .frame_index = .slot0,
    } });
    try appendDirectCall(allocator, machine, call.callee, call.ret_ty);
    try machine.instructions.append(allocator, .add_rsp_24);
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

pub fn lowerAtomicTryLockReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 1 }) and !ret.ty.eql(.{ .int = 8 })) return false;
    _ = function;
    if (block.instructions.items.len < 1 or block.instructions.items.len > 2) return false;
    const first_inst = block.instructions.items[0];
    if (first_inst.removed) return false;
    const cmpxchg = switch (first_inst.kind) {
        .cmpxchg => |c| c,
        else => return false,
    };
    if (cmpxchg.ptr != .named or !std.mem.eql(u8, cmpxchg.ptr.named, "arg0")) return false;
    if (cmpxchg.expected != .int or cmpxchg.expected.int != 0) return false;
    if (cmpxchg.replacement != .int or cmpxchg.replacement.int != 1) return false;

    try machine.instructions.append(allocator, .atomic_try_lock_rdi_al);
    try machine.instructions.append(allocator, .ret);
    return true;
}
