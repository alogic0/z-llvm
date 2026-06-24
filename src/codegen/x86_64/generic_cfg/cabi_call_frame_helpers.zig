const cabi_abi_helpers = @import("cabi_abi_helpers.zig");
const cabi_aggregate_lowering = @import("cabi_aggregate_lowering.zig");
const cabi_call_lowering = @import("cabi_call_lowering.zig");
const cabi_tls_global_lowering = @import("cabi_tls_global_lowering.zig");
const std = @import("std");
const x86_64_types = @import("../types.zig");
const x86_64_emit = @import("../emit.zig");
const x86_64_machine = @import("../machine.zig");

const MachineFunction = x86_64_machine.MachineFunction;
const ArgReg = x86_64_types.ArgReg;
const XmmReg = x86_64_types.XmmReg;
const appendMoveImm32ToXmm = x86_64_emit.appendMoveImm32ToXmm;
const appendMoveImm64ToXmm = x86_64_emit.appendMoveImm64ToXmm;

pub fn appendCompareArg32Imm32(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    reg: ArgReg,
    expected: i32,
    fail: []const u8,
) !void {
    try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = expected });
    try machine.instructions.append(allocator, .{ .jne = fail });
}

pub fn appendCompareStackByval64Imm64(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    stack_offset: u8,
    field_offset: u8,
    expected: i64,
    fail: []const u8,
) !void {
    try machine.instructions.append(allocator, .{ .load_stack_disp8_rax = stack_offset });
    try machine.instructions.append(allocator, .{ .load_rax_ptr_disp8_rax = field_offset });
    try machine.instructions.append(allocator, .{ .mov_imm_rdx = expected });
    try machine.instructions.append(allocator, .cmp_rax_rdx);
    try machine.instructions.append(allocator, .{ .jne = fail });
}

pub fn appendCompareStack64Imm64(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    stack_offset: u8,
    expected: i64,
    fail: []const u8,
) !void {
    try machine.instructions.append(allocator, .{ .load_stack_disp8_rax = stack_offset });
    try machine.instructions.append(allocator, .{ .mov_imm_rdx = expected });
    try machine.instructions.append(allocator, .cmp_rax_rdx);
    try machine.instructions.append(allocator, .{ .jne = fail });
}

pub fn appendCompareMem64Imm64(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    reg: ArgReg,
    offset: u8,
    expected: i64,
    fail: []const u8,
) !void {
    try machine.instructions.append(allocator, .{ .load_arg_ptr_disp8_rax = .{ .reg = reg, .offset = offset } });
    try machine.instructions.append(allocator, .{ .mov_imm_rdx = expected });
    try machine.instructions.append(allocator, .cmp_rax_rdx);
    try machine.instructions.append(allocator, .{ .jne = fail });
}

pub fn appendComparePackedFloatPair(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    reg: XmmReg,
    expected_bits: u64,
    fail: []const u8,
) !void {
    try machine.instructions.append(allocator, .{ .movq_xmm_rax = reg });
    try machine.instructions.append(allocator, .{ .mov_imm_rdx = @bitCast(expected_bits) });
    try machine.instructions.append(allocator, .cmp_rax_rdx);
    try machine.instructions.append(allocator, .{ .jne = fail });
}

pub fn appendCompareXmmLowF32(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    reg: XmmReg,
    expected_bits: u32,
    fail: []const u8,
) !void {
    try machine.instructions.append(allocator, .{ .movq_xmm_rax = reg });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = @bitCast(expected_bits) });
    try machine.instructions.append(allocator, .{ .jne = fail });
}

pub fn appendCompareXmmLowF64(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    expected_bits: u64,
    fail: []const u8,
) !void {
    try appendCompareXmmF64(allocator, machine, .xmm0, .xmm1, expected_bits, fail);
}

pub fn appendCompareXmmF64(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    arg_reg: XmmReg,
    scratch_reg: XmmReg,
    expected_bits: u64,
    fail: []const u8,
) !void {
    if (arg_reg == scratch_reg) return error.UnsupportedCodegenAbi;
    try appendMoveImm64ToXmm(allocator, machine, scratch_reg, expected_bits);
    try machine.instructions.append(allocator, .{ .ucomisd = .{ .src = scratch_reg, .dst = arg_reg } });
    try machine.instructions.append(allocator, .{ .jp = fail });
    try machine.instructions.append(allocator, .{ .jne = fail });
}

pub fn appendCompareXmm0LowF64(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    expected_bits: u64,
    fail: []const u8,
) !void {
    try machine.instructions.append(allocator, .{ .mov_imm64_xmm1 = expected_bits });
    try machine.instructions.append(allocator, .ucomisd_xmm1_xmm0);
    try machine.instructions.append(allocator, .{ .jp = fail });
    try machine.instructions.append(allocator, .{ .jne = fail });
}

pub fn appendCompareArg64Imm64(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    reg: ArgReg,
    expected: i64,
    fail: []const u8,
) !void {
    try machine.instructions.append(allocator, .{ .cmp_arg64_imm64 = .{ .reg = reg, .imm = expected } });
    try machine.instructions.append(allocator, .{ .jne = fail });
}

pub const appendI32CallArgs = cabi_call_lowering.appendI32CallArgs;
pub const appendSysVScalarCallArgs = cabi_call_lowering.appendSysVScalarCallArgs;
pub const appendSysVScalarCallArgsWithBlock = cabi_call_lowering.appendSysVScalarCallArgsWithBlock;
pub const sysvCallPlanCountsForTest = cabi_call_lowering.sysvCallPlanCountsForTest;
pub const planSysVCall = cabi_call_lowering.planSysVCall;
pub const appendSysVRegisterAggregatePassThroughArg = cabi_call_lowering.appendSysVRegisterAggregatePassThroughArg;
pub const appendSysVStackAggregatePassThroughArgs = cabi_call_lowering.appendSysVStackAggregatePassThroughArgs;
pub const appendSysVMemoryAggregateStackPassThroughArgs = cabi_call_lowering.appendSysVMemoryAggregateStackPassThroughArgs;
pub const sysvParamCursorFor = cabi_call_lowering.sysvParamCursorFor;
pub const sysvParamCursorForWithInitial = cabi_call_lowering.sysvParamCursorForWithInitial;
pub const sysvScalarCallNeedsStackArgs = cabi_call_lowering.sysvScalarCallNeedsStackArgs;
pub const appendStackScalarCallArg = cabi_call_lowering.appendStackScalarCallArg;
pub const appendAlignedDirectCallPreservingI32Param = cabi_call_lowering.appendAlignedDirectCallPreservingI32Param;
pub const appendAlignedDirectCallPreservingI32Params = cabi_call_lowering.appendAlignedDirectCallPreservingI32Params;
pub const appendAlignedCallPreservingI32Params = cabi_call_lowering.appendAlignedCallPreservingI32Params;
pub const frameIndexForLiveParam = cabi_call_lowering.frameIndexForLiveParam;
pub const lowerReturnTerminator = cabi_call_lowering.lowerReturnTerminator;
pub const lowerReturnValue = cabi_call_lowering.lowerReturnValue;
pub const lowerGenericCfgSelectReturnValue = cabi_call_lowering.lowerGenericCfgSelectReturnValue;
pub const lowerGenericCfgI32ValueIntoEax = cabi_call_lowering.lowerGenericCfgI32ValueIntoEax;
pub const lowerGenericCfgSminSelectReturn = cabi_call_lowering.lowerGenericCfgSminSelectReturn;
pub const emitGenericCfgIcmpCondition = cabi_call_lowering.emitGenericCfgIcmpCondition;
pub const lowerI32AddTreeReturn = cabi_call_lowering.lowerI32AddTreeReturn;
pub const collectI32AddTerms = cabi_call_lowering.collectI32AddTerms;
pub const collectI32AddValue = cabi_call_lowering.collectI32AddValue;
pub const emitI32ValueIntoEax = cabi_call_lowering.emitI32ValueIntoEax;
pub const lowerReturnValueAfterCalls = cabi_call_lowering.lowerReturnValueAfterCalls;
pub const appendI32AddTermToEax = cabi_call_lowering.appendI32AddTermToEax;
pub const paramValueReg = cabi_abi_helpers.paramValueReg;
pub const paramReg = cabi_abi_helpers.paramReg;
pub const sysvIntegerParamReg = cabi_abi_helpers.sysvIntegerParamReg;
pub const sysvIntegerParamRegOrNull = cabi_abi_helpers.sysvIntegerParamRegOrNull;
pub const paramRegOrNull = cabi_abi_helpers.paramRegOrNull;
pub const paramRegWithInitialGpr = cabi_abi_helpers.paramRegWithInitialGpr;
pub const paramRegOrNullWithInitialGpr = cabi_abi_helpers.paramRegOrNullWithInitialGpr;
pub const stackParamDisp8OrNull = cabi_abi_helpers.stackParamDisp8OrNull;
pub const emitI32ParamOrStackIntoEax = cabi_call_lowering.emitI32ParamOrStackIntoEax;
pub const lowerGenericCfgI64ParamReturn = cabi_call_lowering.lowerGenericCfgI64ParamReturn;
pub const lowerGenericCfgI64DirectCallReturn = cabi_call_lowering.lowerGenericCfgI64DirectCallReturn;
pub const lowerAggregateAbiReturn = cabi_aggregate_lowering.lowerAggregateAbiReturn;
pub const lowerMemoryAggregateCallReturn = cabi_aggregate_lowering.lowerMemoryAggregateCallReturn;
pub const lowerRegisterAggregateReturn = cabi_aggregate_lowering.lowerRegisterAggregateReturn;
pub const lowerFourI32RegisterAggregateReturn = cabi_aggregate_lowering.lowerFourI32RegisterAggregateReturn;
pub const lowerSysVAggregateFieldReturn = cabi_aggregate_lowering.lowerSysVAggregateFieldReturn;
pub const lowerRegisterAggregateIntegerFieldAddReturn = cabi_aggregate_lowering.lowerRegisterAggregateIntegerFieldAddReturn;
pub const lowerRegisterAggregateFloatFieldAddReturn = cabi_aggregate_lowering.lowerRegisterAggregateFloatFieldAddReturn;
pub const lowerRegisterAggregateDoubleFieldAddReturn = cabi_aggregate_lowering.lowerRegisterAggregateDoubleFieldAddReturn;
pub const collectAggregateFloatAddTerms = cabi_aggregate_lowering.collectAggregateFloatAddTerms;
pub const collectAggregateDoubleAddTerms = cabi_aggregate_lowering.collectAggregateDoubleAddTerms;
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
pub const sysvIntegerAggregateFieldLocation = cabi_aggregate_lowering.sysvIntegerAggregateFieldLocation;
pub const stackAggregateFieldDisp8 = cabi_aggregate_lowering.stackAggregateFieldDisp8;
pub const stackAggregateByteDisp8 = cabi_aggregate_lowering.stackAggregateByteDisp8;
pub const stackAggregateByteDisp = cabi_aggregate_lowering.stackAggregateByteDisp;
pub const emitSysVAggregateFieldReturn = cabi_aggregate_lowering.emitSysVAggregateFieldReturn;
pub const emitSysVAggregateFieldOffsetReturn = cabi_aggregate_lowering.emitSysVAggregateFieldOffsetReturn;
pub const emitSysVIntegerAggregateFieldLocationReturn = cabi_aggregate_lowering.emitSysVIntegerAggregateFieldLocationReturn;
pub const emitSysVAggregateFieldLocationReturn = cabi_aggregate_lowering.emitSysVAggregateFieldLocationReturn;
pub const emitSysVAggregateF32FieldOffsetReturn = cabi_aggregate_lowering.emitSysVAggregateF32FieldOffsetReturn;
pub const sysvAggregateFieldLocation = cabi_aggregate_lowering.sysvAggregateFieldLocation;
pub const sysvAggregateFieldLocationByOffset = cabi_aggregate_lowering.sysvAggregateFieldLocationByOffset;
pub const sysvAggregateRegisterNeeds = cabi_aggregate_lowering.sysvAggregateRegisterNeeds;
pub const sysvAggregateRegisterNeedsBefore = cabi_aggregate_lowering.sysvAggregateRegisterNeedsBefore;
pub const advanceSysVParamCursors = cabi_abi_helpers.advanceSysVParamCursors;
pub const lowerRegisterAggregateDirectCallReturn = cabi_aggregate_lowering.lowerRegisterAggregateDirectCallReturn;
pub const lowerAggregatePairAbiFamilyReturn = cabi_aggregate_lowering.lowerAggregatePairAbiFamilyReturn;
pub const lowerStructSumReturn = cabi_aggregate_lowering.lowerStructSumReturn;
pub const isMainOrWrapperMain = cabi_tls_global_lowering.isMainOrWrapperMain;
pub const tlsSymbolFromFunctionAttrs = cabi_tls_global_lowering.tlsSymbolFromFunctionAttrs;
pub const knownLocalExecTlsSymbol = cabi_tls_global_lowering.knownLocalExecTlsSymbol;
pub const matchGlobalRead = cabi_tls_global_lowering.matchGlobalRead;
