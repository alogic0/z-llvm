const impl = @import("cabi_impl.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");
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

pub const appendI32CallArgs = impl.appendI32CallArgs;
pub const appendSysVScalarCallArgs = impl.appendSysVScalarCallArgs;
pub const appendSysVScalarCallArgsWithBlock = impl.appendSysVScalarCallArgsWithBlock;
pub const sysvCallPlanCountsForTest = impl.sysvCallPlanCountsForTest;
pub const planSysVCall = impl.planSysVCall;
pub const appendSysVRegisterAggregatePassThroughArg = impl.appendSysVRegisterAggregatePassThroughArg;
pub const appendSysVStackAggregatePassThroughArgs = impl.appendSysVStackAggregatePassThroughArgs;
pub const appendSysVMemoryAggregateStackPassThroughArgs = impl.appendSysVMemoryAggregateStackPassThroughArgs;
pub const sysvParamCursorFor = impl.sysvParamCursorFor;
pub const sysvParamCursorForWithInitial = impl.sysvParamCursorForWithInitial;
pub const sysvScalarCallNeedsStackArgs = impl.sysvScalarCallNeedsStackArgs;
pub const appendStackScalarCallArg = impl.appendStackScalarCallArg;
pub const appendAlignedDirectCallPreservingI32Param = impl.appendAlignedDirectCallPreservingI32Param;
pub const appendAlignedDirectCallPreservingI32Params = impl.appendAlignedDirectCallPreservingI32Params;
pub const appendAlignedCallPreservingI32Params = impl.appendAlignedCallPreservingI32Params;
pub const frameIndexForLiveParam = impl.frameIndexForLiveParam;
pub const lowerReturnTerminator = impl.lowerReturnTerminator;
pub const lowerReturnValue = impl.lowerReturnValue;
pub const lowerGenericCfgSelectReturnValue = impl.lowerGenericCfgSelectReturnValue;
pub const lowerGenericCfgI32ValueIntoEax = impl.lowerGenericCfgI32ValueIntoEax;
pub const lowerGenericCfgSminSelectReturn = impl.lowerGenericCfgSminSelectReturn;
pub const emitGenericCfgIcmpCondition = impl.emitGenericCfgIcmpCondition;
pub const lowerI32AddTreeReturn = impl.lowerI32AddTreeReturn;
pub const collectI32AddTerms = impl.collectI32AddTerms;
pub const collectI32AddValue = impl.collectI32AddValue;
pub const emitI32ValueIntoEax = impl.emitI32ValueIntoEax;
pub const lowerReturnValueAfterCalls = impl.lowerReturnValueAfterCalls;
pub const appendI32AddTermToEax = impl.appendI32AddTermToEax;
pub const paramValueReg = cabi_abi_helpers.paramValueReg;
pub const paramReg = cabi_abi_helpers.paramReg;
pub const sysvIntegerParamReg = cabi_abi_helpers.sysvIntegerParamReg;
pub const sysvIntegerParamRegOrNull = cabi_abi_helpers.sysvIntegerParamRegOrNull;
pub const paramRegOrNull = cabi_abi_helpers.paramRegOrNull;
pub const paramRegWithInitialGpr = cabi_abi_helpers.paramRegWithInitialGpr;
pub const paramRegOrNullWithInitialGpr = cabi_abi_helpers.paramRegOrNullWithInitialGpr;
pub const stackParamDisp8OrNull = cabi_abi_helpers.stackParamDisp8OrNull;
pub const emitI32ParamOrStackIntoEax = impl.emitI32ParamOrStackIntoEax;
pub const lowerGenericCfgI64ParamReturn = impl.lowerGenericCfgI64ParamReturn;
pub const lowerGenericCfgI64DirectCallReturn = impl.lowerGenericCfgI64DirectCallReturn;
pub const lowerAggregateAbiReturn = impl.lowerAggregateAbiReturn;
pub const lowerMemoryAggregateCallReturn = impl.lowerMemoryAggregateCallReturn;
pub const lowerRegisterAggregateReturn = impl.lowerRegisterAggregateReturn;
pub const lowerFourI32RegisterAggregateReturn = impl.lowerFourI32RegisterAggregateReturn;
pub const lowerSysVAggregateFieldReturn = impl.lowerSysVAggregateFieldReturn;
pub const lowerRegisterAggregateIntegerFieldAddReturn = impl.lowerRegisterAggregateIntegerFieldAddReturn;
pub const lowerRegisterAggregateFloatFieldAddReturn = impl.lowerRegisterAggregateFloatFieldAddReturn;
pub const lowerRegisterAggregateDoubleFieldAddReturn = impl.lowerRegisterAggregateDoubleFieldAddReturn;
pub const collectAggregateFloatAddTerms = impl.collectAggregateFloatAddTerms;
pub const collectAggregateDoubleAddTerms = impl.collectAggregateDoubleAddTerms;
pub const collectAggregateIntegerAddTerms = impl.collectAggregateIntegerAddTerms;
pub const emitAggregateIntegerTerm = impl.emitAggregateIntegerTerm;
pub const emitAggregateDoubleTerm = impl.emitAggregateDoubleTerm;
pub const emitAggregateFloatTerm = impl.emitAggregateFloatTerm;
pub const appendLoadStackDispRax = impl.appendLoadStackDispRax;
pub const appendLoadStackDispXmm0 = impl.appendLoadStackDispXmm0;
pub const appendLoadStackDispXmm0F32 = impl.appendLoadStackDispXmm0F32;
pub const appendLoadStackDispXmm = impl.appendLoadStackDispXmm;
pub const appendAddStackDispRax = impl.appendAddStackDispRax;
pub const appendAddStackDispEax = impl.appendAddStackDispEax;
pub const appendStoreArg64ArgPtrDisp = impl.appendStoreArg64ArgPtrDisp;
pub const appendStoreRaxArgPtrDisp = impl.appendStoreRaxArgPtrDisp;
pub const appendStoreEaxArgPtrDisp = impl.appendStoreEaxArgPtrDisp;
pub const appendStoreXmm0ArgPtrDisp = impl.appendStoreXmm0ArgPtrDisp;
pub const appendStoreXmm0F32ArgPtrDisp = impl.appendStoreXmm0F32ArgPtrDisp;
pub const sysvIntegerAggregateFieldLocation = impl.sysvIntegerAggregateFieldLocation;
pub const stackAggregateFieldDisp8 = impl.stackAggregateFieldDisp8;
pub const stackAggregateByteDisp8 = impl.stackAggregateByteDisp8;
pub const stackAggregateByteDisp = impl.stackAggregateByteDisp;
pub const emitSysVAggregateFieldReturn = impl.emitSysVAggregateFieldReturn;
pub const emitSysVAggregateFieldOffsetReturn = impl.emitSysVAggregateFieldOffsetReturn;
pub const emitSysVIntegerAggregateFieldLocationReturn = impl.emitSysVIntegerAggregateFieldLocationReturn;
pub const emitSysVAggregateFieldLocationReturn = impl.emitSysVAggregateFieldLocationReturn;
pub const emitSysVAggregateF32FieldOffsetReturn = impl.emitSysVAggregateF32FieldOffsetReturn;
pub const sysvAggregateFieldLocation = impl.sysvAggregateFieldLocation;
pub const sysvAggregateFieldLocationByOffset = impl.sysvAggregateFieldLocationByOffset;
pub const sysvAggregateRegisterNeeds = impl.sysvAggregateRegisterNeeds;
pub const sysvAggregateRegisterNeedsBefore = impl.sysvAggregateRegisterNeedsBefore;
pub const advanceSysVParamCursors = cabi_abi_helpers.advanceSysVParamCursors;
pub const lowerRegisterAggregateDirectCallReturn = impl.lowerRegisterAggregateDirectCallReturn;
pub const lowerAggregatePairAbiFamilyReturn = impl.lowerAggregatePairAbiFamilyReturn;
pub const lowerStructSumReturn = impl.lowerStructSumReturn;
pub const isMainOrWrapperMain = impl.isMainOrWrapperMain;
pub const tlsSymbolFromFunctionAttrs = impl.tlsSymbolFromFunctionAttrs;
pub const knownLocalExecTlsSymbol = impl.knownLocalExecTlsSymbol;
pub const matchGlobalRead = impl.matchGlobalRead;
