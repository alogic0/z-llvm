const std = @import("std");
const ir = @import("../../../ir.zig");
const target = @import("../../../target.zig");
const x86_64_machine = @import("../machine.zig");
const x86_64_types = @import("../types.zig");
const inspection = @import("inspection.zig");
const selector_types = @import("selector_types.zig");
const stage2_planning = @import("stage2_planning.zig");
const composed_helpers = @import("composed_helpers.zig");
const selector_state = @import("composed_selector_state.zig");
const selector_icmp = @import("composed_selector_icmp.zig");
const ValueUseTransaction = @import("composed_selector_value_use_transaction.zig").ValueUseTransaction;

pub const MachineFunction = x86_64_machine.MachineFunction;
const ArgReg = x86_64_types.ArgReg;
const FrameIndex = x86_64_types.FrameIndex;
const MachineBinaryOp = x86_64_types.MachineBinaryOp;
const PairSpillLoc = selector_types.PairSpillLoc;
const RegPair = selector_types.RegPair;
const StackArrayLoc = selector_types.StackArrayLoc;
const StackPtrLoc = selector_types.StackPtrLoc;
const ValueBinding = selector_types.ValueBinding;
const ValueLoc = selector_types.ValueLoc;
const VirtualReg = selector_types.VirtualReg;
const VirtualRegClass = selector_types.VirtualRegClass;
const VirtualRegMetadata = selector_types.VirtualRegMetadata;
const pair_a = selector_types.pair_a;
const pair_b = selector_types.pair_b;
const selector_allocatable_pairs = selector_types.selector_allocatable_pairs;
const selector_allocatable_regs = selector_types.selector_allocatable_regs;
const argRegIndex = selector_types.argRegIndex;

pub const Diagnostic = inspection.Diagnostic;
pub const SelectionResult = inspection.SelectionResult;

const NameSet = stage2_planning.NameSet;
const PlannedValueAssignment = stage2_planning.PlannedValueAssignment;
const SelectorAllocationPlan = stage2_planning.SelectorAllocationPlan;
const SelectorValueInterval = stage2_planning.SelectorValueInterval;
const SpillSlotAssignment = stage2_planning.SpillSlotAssignment;
const allocateSelectorIntervals = stage2_planning.allocateSelectorIntervals;
const analyzeStageTwoNoSpillEnvelope = stage2_planning.analyzeStageTwoNoSpillEnvelope;
const buildSelectorAllocationPlan = stage2_planning.buildSelectorAllocationPlan;
const selectorValueMetadata = stage2_planning.selectorValueMetadata;
const stage2SpillReservedBytes = stage2_planning.stage2SpillReservedBytes;
const stage2_max_blocks = stage2_planning.stage2_max_blocks;
const stage2_spill_slots = stage2_planning.stage2_spill_slots;
const phi_regs = [_]ArgReg{ .r8, .r9, .rcx };

const blockHasPhiIncomingFrom = composed_helpers.blockHasPhiIncomingFrom;
const phiIncomingFrom = composed_helpers.phiIncomingFrom;
const canUseExpiredPlanRegisterReuse = composed_helpers.canUseExpiredPlanRegisterReuse;
const machineBinaryOp = composed_helpers.machineBinaryOp;
const valueLocEql = composed_helpers.valueLocEql;
const valueIsInt = composed_helpers.valueIsInt;
const intBits = composed_helpers.intBits;
const callArgRegisterCount = composed_helpers.callArgRegisterCount;
const isDefaultOrFastcc = composed_helpers.isDefaultOrFastcc;
const parseI32ArrayType = composed_helpers.parseI32ArrayType;
const alignedCallFrameBytes = composed_helpers.alignedCallFrameBytes;
const stack128FrameBytes = composed_helpers.stack128FrameBytes;
const isComposedReturnType = composed_helpers.isComposedReturnType;
const shiftAmount5 = composed_helpers.shiftAmount5;
const shiftAmount6 = composed_helpers.shiftAmount6;
const shiftAmount7 = composed_helpers.shiftAmount7;
const i32Value = composed_helpers.i32Value;
const i32BitPattern = composed_helpers.i32BitPattern;
const i64Value = composed_helpers.i64Value;

pub const ComposedBlockSelector = selector_state.ComposedBlockSelector;
pub const lowerIcmp = selector_icmp.lowerIcmp;

pub fn lowerBinary(selector: *ComposedBlockSelector, result: ?[]const u8, binary: ir.BinaryInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    const bits = intBits(binary.ty) orelse return .{ .no_emitter = "composed-block-binary-not-int" };
    if ((bits == 32 or bits == 64) and binary.op == .add and binary.lhs == .int and
        binary.rhs == .int and (binary.rhs.int == 0 or binary.lhs.int == 0))
    {
        return lowerConstantIdentity(selector, result_name, binary, bits);
    }
    if (bits == 52) return lowerI52Binary(selector, result_name, binary);
    if (bits == 1) {
        if ((binary.op != .@"and" and binary.op != .@"or") or valueIsInt(binary.lhs) or valueIsInt(binary.rhs)) return .{ .no_emitter = "composed-block-binary-width" };
        return lowerB01NamedScalarBinary(selector, result_name, binary);
    }
    const exact_ei_narrow = isExactEiNarrowBits(selector, bits);
    const is_imm_scalar = bits > 7 and bits <= 64 and (valueIsInt(binary.rhs) or valueIsInt(binary.lhs));
    if (bits != 4 and bits != 6 and bits != 7 and bits != 16 and bits != 32 and bits != 64 and bits != 128 and !exact_ei_narrow and !is_imm_scalar)
        return .{ .no_emitter = "composed-block-binary-width" };

    if (valueIsInt(binary.rhs)) {
        return try lowerBinaryImmediateRhs(selector, result_name, binary);
    }
    if (valueIsInt(binary.lhs)) {
        switch (binary.op) {
            .add, .mul, .@"or", .@"and", .xor => {
                var commuted = binary;
                commuted.lhs = binary.rhs;
                commuted.rhs = binary.lhs;
                return try lowerBinaryImmediateRhs(selector, result_name, commuted);
            },
            else => {},
        }
        return try lowerBinaryImmediateLhs(selector, result_name, binary);
    }
    if (bits == 128) return try lowerPairBinary(selector, result_name, binary);

    if (binary.op == .mul and bits == 64) return try lowerMul64(selector, result_name, binary);
    if ((binary.op == .udiv or binary.op == .urem) and (bits == 32 or bits == 64)) {
        return try lowerUnsignedDivRem(selector, result_name, binary, bits);
    }
    if (binary.op == .mul and bits <= 32) {
        return lowerNamedScalarBinary(selector, result_name, binary, bits, exact_ei_narrow, .b03);
    }
    if ((binary.op == .shl or binary.op == .lshr or binary.op == .ashr) and (bits == 16 or bits == 32 or (exact_ei_narrow and bits < 32))) {
        return lowerNamedScalarBinary(selector, result_name, binary, bits, exact_ei_narrow, .b04);
    }
    if ((binary.op == .shl or binary.op == .lshr or binary.op == .ashr) and (bits == 64 or (exact_ei_narrow and bits > 32))) {
        return lowerNamedScalarBinary(selector, result_name, binary, bits, exact_ei_narrow, .b05);
    }
    if (exact_ei_narrow and bits > 32) {
        return lowerNamedScalarBinary(selector, result_name, binary, bits, true, .b06);
    }

    _ = machineBinaryOp(binary.op) orelse return .{ .no_emitter = "composed-block-binary-op" };
    return lowerNamedScalarBinary(selector, result_name, binary, bits, exact_ei_narrow, .b07);
}

fn lowerConstantIdentity(selector: *ComposedBlockSelector, result_name: []const u8, binary: ir.BinaryInst, bits: u16) !?Diagnostic {
    // Private aggregate extraction uses an identity add to name a scalar
    // constant. Adding zero cannot overflow, including with nuw/nsw.
    const value = if (binary.rhs.int == 0) binary.lhs else binary.rhs;
    var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
    defer transaction.deinit();
    if (try transaction.prepare(.preserve, .spill_live)) |diagnostic| return diagnostic;
    const definition: selector_state.AccumulatorDefinition = if (bits == 32) .zeroExtending(32) else .fullRax();
    try transaction.materialize(value, definition);
    try transaction.define(result_name, definition);
    try transaction.commit();
    return null;
}

fn lowerB01NamedScalarBinary(
    selector: *ComposedBlockSelector,
    result_name: []const u8,
    binary: ir.BinaryInst,
) !?Diagnostic {
    var transaction = try ValueUseTransaction.begin(selector);
    defer transaction.deinit();
    const lhs_request = try transaction.register(.{
        .source = binary.lhs,
        .expected = .{ .ty = binary.ty, .register_class = .gpr32 },
        .form = .named_scalar_operand,
        .destination = .prepared_view,
    });
    const rhs_request = try transaction.register(.{
        .source = binary.rhs,
        .expected = .{ .ty = binary.ty, .register_class = .gpr32 },
        .form = .named_scalar_operand,
        .destination = .prepared_source,
    });
    try transaction.attachNamedScalarBinaryAction(lhs_request, .{
        .result = try ValueUseTransaction.ActionIdentity.init(result_name),
        .operation = binary.op,
        .integer_ty = binary.ty,
        .exact_ei = false,
        .rhs = rhs_request,
    });
    transaction.seal() catch |err|
        return namedScalarValueUseDiagnostic(&transaction, lhs_request, rhs_request, .b01, err) orelse return err;
    transaction.prepare() catch |err|
        return namedScalarValueUseDiagnostic(&transaction, lhs_request, rhs_request, .b01, err) orelse return err;
    transaction.materializeAll() catch |err|
        return namedScalarValueUseDiagnostic(&transaction, lhs_request, rhs_request, .b01, err) orelse return err;
    const lease = transaction.preparedView(lhs_request) catch |err|
        return namedScalarValueUseDiagnostic(&transaction, lhs_request, rhs_request, .b01, err) orelse return err;
    transaction.executePreparedAction(lease) catch |err|
        return namedScalarValueUseDiagnostic(&transaction, lhs_request, rhs_request, .b01, err) orelse return err;
    try transaction.commit();
    return null;
}

const NamedScalarDiagnosticKind = enum {
    b01,
    b03,
    b04,
    b05,
    b06,
    b07,
    i52b0,
};

fn lowerNamedScalarBinary(
    selector: *ComposedBlockSelector,
    result_name: []const u8,
    binary: ir.BinaryInst,
    bits: u16,
    exact_ei: bool,
    kind: NamedScalarDiagnosticKind,
) !?Diagnostic {
    var transaction = try ValueUseTransaction.begin(selector);
    defer transaction.deinit();
    const register_class: VirtualRegClass = if (bits <= 32) .gpr32 else .gpr64;
    const lhs_request = try transaction.register(.{
        .source = binary.lhs,
        .expected = .{ .ty = binary.ty, .register_class = register_class },
        .form = .named_scalar_operand,
        .destination = .prepared_view,
    });
    const rhs_request = try transaction.register(.{
        .source = binary.rhs,
        .expected = .{ .ty = binary.ty, .register_class = register_class },
        .form = .named_scalar_operand,
        .destination = .prepared_source,
    });
    try transaction.attachNamedScalarBinaryAction(lhs_request, .{
        .result = try ValueUseTransaction.ActionIdentity.init(result_name),
        .operation = binary.op,
        .integer_ty = binary.ty,
        .exact_ei = exact_ei,
        .rhs = rhs_request,
    });
    transaction.seal() catch |err|
        return namedScalarValueUseDiagnostic(&transaction, lhs_request, rhs_request, kind, err) orelse return err;
    transaction.prepare() catch |err|
        return namedScalarValueUseDiagnostic(&transaction, lhs_request, rhs_request, kind, err) orelse return err;
    transaction.materializeAll() catch |err|
        return namedScalarValueUseDiagnostic(&transaction, lhs_request, rhs_request, kind, err) orelse return err;
    const lease = transaction.preparedView(lhs_request) catch |err|
        return namedScalarValueUseDiagnostic(&transaction, lhs_request, rhs_request, kind, err) orelse return err;
    transaction.executePreparedAction(lease) catch |err|
        return namedScalarValueUseDiagnostic(&transaction, lhs_request, rhs_request, kind, err) orelse return err;
    try transaction.commit();
    return null;
}

fn namedScalarValueUseDiagnostic(
    transaction: *const ValueUseTransaction,
    lhs_request: ValueUseTransaction.RequestHandle,
    rhs_request: ValueUseTransaction.RequestHandle,
    kind: NamedScalarDiagnosticKind,
    err: anyerror,
) ?Diagnostic {
    if (err == error.ValueUseActionDiagnostic) return transaction.actionDiagnostic();
    const request_error = switch (err) {
        error.ValueUseSourcePlanMissing,
        error.ValueUseSourceIntervalMissing,
        error.ValueUseSourceGenerationChanged,
        error.ValueUseUnresolvedSource,
        error.ValueUseExpiredSource,
        error.ValueUseUnsupportedSource,
        error.ValueUseTypeMismatch,
        error.ValueUseRegisterClassMismatch,
        error.ValueUseSourceViewMismatch,
        error.ValueUseForwardPlanMissing,
        error.ValueUseForwardPlanMalformed,
        error.ValueUseForwardPlanStale,
        error.ValueUseForwardIntervalExpired,
        error.ValueUseForwardTypeMismatch,
        error.ValueUseForwardAssignmentMissing,
        error.ValueUseForwardSnapshotCapacityExceeded,
        error.ValueUseNamedScalarFormUnsupported,
        error.ValueUseNamedScalarWidthUnsupported,
        error.ValueUseNamedScalarLocationUnsupported,
        error.ValueUseNamedScalarScratchUnavailable,
        error.ValueUseNamedScalarExactEiUnsupported,
        error.ValueUseNamedScalarI52EnvelopeUnsupported,
        => true,
        else => false,
    };
    if (!request_error) return null;
    if (transaction.failedRequestIs(lhs_request)) return switch (kind) {
        .b01, .b03, .b04, .b07 => .{ .unsupported_value = "composed-block-unknown-lhs" },
        .b05 => .{ .unsupported_value = "composed-block-ei-shift-lhs" },
        .b06 => .{ .unsupported_value = "composed-block-ei-binary-lhs" },
        .i52b0 => .{ .unsupported_value = "composed-block-i52-shift-lhs" },
    };
    if (transaction.failedRequestIs(rhs_request)) return switch (kind) {
        .b01, .b03, .b04, .b07 => .{ .unsupported_value = "composed-block-unknown-rhs" },
        .b05 => .{ .unsupported_value = "composed-block-ei-shift-rhs" },
        .b06 => .{ .unsupported_value = "composed-block-ei-binary-rhs" },
        .i52b0 => .{ .unsupported_value = "composed-block-i52-shift-rhs" },
    };
    return null;
}

const ImmediateScalarDirection = enum {
    rhs,
    lhs,
};

fn lowerImmediateRhsScalar(
    selector: *ComposedBlockSelector,
    result_name: []const u8,
    binary: ir.BinaryInst,
    bits: u16,
    literal: i128,
) !?Diagnostic {
    var transaction = try ValueUseTransaction.begin(selector);
    defer transaction.deinit();
    const source_request = try transaction.register(.{
        .source = binary.lhs,
        .expected = .{
            .ty = binary.ty,
            .register_class = if (bits <= 32) .gpr32 else .gpr64,
        },
        .form = .immediate_rhs_scalar_operand,
        .destination = .prepared_view,
        .prepared_action = .{ .immediate_rhs_scalar = .{
            .result = try ValueUseTransaction.ActionIdentity.init(result_name),
            .operation = binary.op,
            .integer_ty = binary.ty,
            .literal = literal,
        } },
    });
    transaction.seal() catch |err|
        return immediateScalarValueUseDiagnostic(&transaction, source_request, .rhs, binary, err) orelse return err;
    transaction.prepare() catch |err|
        return immediateScalarValueUseDiagnostic(&transaction, source_request, .rhs, binary, err) orelse return err;
    transaction.materializeAll() catch |err|
        return immediateScalarValueUseDiagnostic(&transaction, source_request, .rhs, binary, err) orelse return err;
    const lease = transaction.preparedView(source_request) catch |err|
        return immediateScalarValueUseDiagnostic(&transaction, source_request, .rhs, binary, err) orelse return err;
    transaction.executePreparedAction(lease) catch |err|
        return immediateScalarValueUseDiagnostic(&transaction, source_request, .rhs, binary, err) orelse return err;
    try transaction.commit();
    return null;
}

fn lowerImmediateLhsScalar(
    selector: *ComposedBlockSelector,
    result_name: []const u8,
    binary: ir.BinaryInst,
    bits: u16,
    literal: i128,
) !?Diagnostic {
    var transaction = try ValueUseTransaction.begin(selector);
    defer transaction.deinit();
    const source_request = try transaction.register(.{
        .source = binary.rhs,
        .expected = .{
            .ty = binary.ty,
            .register_class = if (bits <= 32) .gpr32 else .gpr64,
        },
        .form = .immediate_lhs_scalar_operand,
        .destination = .prepared_view,
        .prepared_action = .{ .immediate_lhs_scalar = .{
            .result = try ValueUseTransaction.ActionIdentity.init(result_name),
            .operation = binary.op,
            .integer_ty = binary.ty,
            .literal = literal,
        } },
    });
    transaction.seal() catch |err|
        return immediateScalarValueUseDiagnostic(&transaction, source_request, .lhs, binary, err) orelse return err;
    transaction.prepare() catch |err|
        return immediateScalarValueUseDiagnostic(&transaction, source_request, .lhs, binary, err) orelse return err;
    transaction.materializeAll() catch |err|
        return immediateScalarValueUseDiagnostic(&transaction, source_request, .lhs, binary, err) orelse return err;
    const lease = transaction.preparedView(source_request) catch |err|
        return immediateScalarValueUseDiagnostic(&transaction, source_request, .lhs, binary, err) orelse return err;
    transaction.executePreparedAction(lease) catch |err|
        return immediateScalarValueUseDiagnostic(&transaction, source_request, .lhs, binary, err) orelse return err;
    try transaction.commit();
    return null;
}

fn immediateScalarValueUseDiagnostic(
    transaction: *const ValueUseTransaction,
    source_request: ValueUseTransaction.RequestHandle,
    direction: ImmediateScalarDirection,
    binary: ir.BinaryInst,
    err: anyerror,
) ?Diagnostic {
    if (err == error.ValueUseActionDiagnostic) return transaction.actionDiagnostic();
    if (!transaction.failedRequestIs(source_request)) return null;
    return switch (err) {
        error.ValueUseImmediateScalarScratchUnavailable => .{
            .no_spill_envelope = "composed-block-lshr64-dst",
        },
        error.ValueUseImmediateScalarLiteralOutOfRange => .{
            .unsupported_value = "stage2-binary-value",
        },
        error.ValueUseSourcePlanMissing,
        error.ValueUseSourceIntervalMissing,
        error.ValueUseSourceGenerationChanged,
        error.ValueUseUnresolvedSource,
        error.ValueUseExpiredSource,
        error.ValueUseUnsupportedSource,
        error.ValueUseTypeMismatch,
        error.ValueUseRegisterClassMismatch,
        error.ValueUseSourceViewMismatch,
        error.ValueUseImmediateScalarFormUnsupported,
        error.ValueUseImmediateScalarWidthUnsupported,
        error.ValueUseImmediateScalarLocationUnsupported,
        => switch (direction) {
            .lhs => .{ .unsupported_value = "stage2-binary-value" },
            .rhs => immediateRhsSourceDiagnostic(binary),
        },
        else => null,
    };
}

fn immediateRhsSourceDiagnostic(binary: ir.BinaryInst) Diagnostic {
    const bits = intBits(binary.ty) orelse return .{ .unsupported_value = "stage2-binary-value" };
    return switch (binary.op) {
        .sdiv => .{ .unsupported_value = "composed-block-sdiv-lhs" },
        .shl => if (bits <= 32)
            .{ .unsupported_value = "composed-block-unknown-lhs" }
        else
            .{ .unsupported_value = "stage2-binary-value" },
        .@"and" => if (bits == 64)
            .{ .unsupported_value = "composed-block-and64-lhs" }
        else
            .{ .unsupported_value = "stage2-binary-value" },
        .@"or" => if (bits == 64)
            .{ .unsupported_value = "composed-block-or64-lhs" }
        else
            .{ .unsupported_value = "stage2-binary-value" },
        .add => if (bits == 64 and switch (binary.rhs) {
            .int => |value| value < std.math.minInt(i32) or value > std.math.maxInt(i32),
            else => false,
        })
            .{ .unsupported_value = "composed-block-add64-lhs" }
        else
            .{ .unsupported_value = "stage2-binary-value" },
        .xor => if (bits == 64)
            .{ .unsupported_value = "composed-block-xor64-lhs" }
        else
            .{ .unsupported_value = "stage2-binary-value" },
        else => .{ .unsupported_value = "stage2-binary-value" },
    };
}

fn isScalarImmediateLiveSharedSourcePreservation(binary: ir.BinaryInst) bool {
    if (binary.lhs != .named or binary.rhs != .int) return false;
    const bits = intBits(binary.ty) orelse return false;
    if (bits == 0) return false;
    return binary.op == .ashr and (bits <= 32 or bits == 64);
}

fn scalar_immediate_live_shared_source_preservation(
    selector: *ComposedBlockSelector,
    result_name: []const u8,
    binary: ir.BinaryInst,
    bits: u16,
    literal: i128,
) !?Diagnostic {
    if (bits <= 32) {
        while (try selector_state.liveAccumulatorNameAfterCurrent(selector)) |live_name| {
            if (try selector_state.preserveLiveAccumulatorValue(selector, live_name)) |diagnostic| return diagnostic;
        }
        const amount = try shiftAmount5(literal);
        var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
        defer transaction.deinit();
        if (try transaction.prepare(.preserve, try accumulatorArithmeticDisplacement(selector, binary.lhs, .spill_live))) |diagnostic| return diagnostic;
        try transaction.materialize(binary.lhs, accumulatorDefinition(bits));
        if (amount != 0) try emitArithmeticWrite(selector, .{ .sar_eax_imm5 = amount });
        try finishArithmeticResult(&transaction, result_name, bits);
        return null;
    }

    const amount = try shiftAmount6(literal);
    try selector_state.emitValueIntoScratch(selector, binary.lhs, .rcx, bits);
    if (amount != 0) {
        try selector_state.clobberArgReg(selector, .rcx);
        try emitArithmeticWrite(selector, .{ .sar_arg64_imm6 = .{
            .reg = .rcx,
            .amount = amount,
        } });
    }
    try selector_state.bindScratch(selector, result_name, .rcx, bits);
    if (try selector_state.spillValue(selector, result_name)) |diagnostic| return diagnostic;
    return null;
}

fn isScalarImmediateMultiAliasPreservation(binary: ir.BinaryInst) bool {
    if (binary.lhs != .named or binary.rhs != .int) return false;
    const bits = intBits(binary.ty) orelse return false;
    if (bits == 0 or bits > 32) return false;
    return switch (binary.op) {
        .@"and", .@"or", .add, .sub, .xor => true,
        else => false,
    };
}

fn scalar_immediate_multi_alias_preservation(
    selector: *ComposedBlockSelector,
    result_name: []const u8,
    binary: ir.BinaryInst,
    bits: u16,
    literal: i128,
) !?Diagnostic {
    while (try selector_state.liveAccumulatorNameAfterCurrent(selector)) |live_name| {
        if (try selector_state.preserveLiveAccumulatorValue(selector, live_name)) |diagnostic| return diagnostic;
    }
    switch (binary.op) {
        .@"and" => {
            var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
            defer transaction.deinit();
            if (try transaction.prepare(.preserve, try accumulatorArithmeticDisplacement(selector, binary.lhs, .scratch_preferred))) |diagnostic| return diagnostic;
            try transaction.materialize(binary.lhs, accumulatorDefinition(bits));
            try emitArithmeticWrite(selector, .{ .and_eax_imm32 = try i32BitPattern(literal) });
            try finishArithmeticResult(&transaction, result_name, bits);
        },
        .@"or" => {
            var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
            defer transaction.deinit();
            if (try transaction.prepare(.preserve, try accumulatorArithmeticDisplacement(selector, binary.lhs, .scratch_preferred))) |diagnostic| return diagnostic;
            try transaction.materialize(binary.lhs, accumulatorDefinition(bits));
            try emitArithmeticWrite(selector, .{ .or_eax_imm32 = try i32BitPattern(literal) });
            try finishArithmeticResult(&transaction, result_name, bits);
        },
        .add => {
            var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
            defer transaction.deinit();
            if (try transaction.prepare(.preserve, try accumulatorArithmeticDisplacement(selector, binary.lhs, .scratch_preferred))) |diagnostic| return diagnostic;
            try transaction.materialize(binary.lhs, accumulatorDefinition(bits));
            try emitArithmeticWrite(selector, .{ .add_eax_imm32 = try i32Value(literal) });
            try finishArithmeticResult(&transaction, result_name, bits);
        },
        .sub => {
            const imm = try i32BitPattern(literal);
            var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
            defer transaction.deinit();
            if (try transaction.prepare(.preserve, try accumulatorArithmeticDisplacement(selector, binary.lhs, .scratch_preferred))) |diagnostic| return diagnostic;
            try transaction.materialize(binary.lhs, accumulatorDefinition(bits));
            try emitArithmeticWrite(selector, .{ .add_eax_imm32 = -%imm });
            try finishArithmeticResult(&transaction, result_name, bits);
        },
        .xor => {
            try selector_state.clobberArgReg(selector, .rcx);
            var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
            defer transaction.deinit();
            if (try transaction.prepare(.preserve, try accumulatorArithmeticDisplacement(selector, binary.lhs, .scratch_preferred))) |diagnostic| return diagnostic;
            try transaction.materialize(binary.lhs, accumulatorDefinition(bits));
            try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rcx = try i32BitPattern(literal) });
            try emitArithmeticWrite(selector, .{ .binary_arg_eax = .{ .op = .xor, .reg = .rcx } });
            try finishArithmeticResult(&transaction, result_name, bits);
        },
        else => unreachable,
    }
    return null;
}

fn isScalarImmediateFrameless64(selector: *const ComposedBlockSelector, binary: ir.BinaryInst) bool {
    if (selector.stack_frame_bytes != 0) return false;
    if (binary.lhs != .named or binary.rhs != .int) return false;
    const bits = intBits(binary.ty) orelse return false;
    if (bits <= 32 or bits > 64) return false;
    const literal = binary.rhs.int;
    if (binary.op == .@"and" and literal == std.math.maxInt(u32)) return false;
    if ((binary.op == .add or binary.op == .sub) and literal >= std.math.minInt(i32) and literal <= std.math.maxInt(i32)) return false;
    return switch (binary.op) {
        .@"and", .@"or", .add, .sub, .xor => true,
        else => false,
    };
}

fn scalar_immediate_frameless64(
    selector: *ComposedBlockSelector,
    result_name: []const u8,
    binary: ir.BinaryInst,
    bits: u16,
    literal: i128,
) !?Diagnostic {
    while (try selector_state.liveAccumulatorNameAfterCurrent(selector)) |live_name| {
        if (try selector_state.preserveLiveAccumulatorValue(selector, live_name)) |diagnostic| return diagnostic;
    }
    var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
    defer transaction.deinit();
    if (try transaction.prepare(.preserve, try accumulatorArithmeticDisplacement(selector, binary.lhs, .scratch_preferred))) |diagnostic| return diagnostic;
    try transaction.materialize(binary.lhs, accumulatorDefinition(bits));

    try selector_state.clobberArgReg(selector, .rcx);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rcx = try i64Value(literal) });
    try emitArithmeticWrite(selector, .{ .binary_arg_rax = .{
        .op = switch (binary.op) {
            .@"and" => .@"and",
            .@"or" => .@"or",
            .xor => .xor,
            .add => .add,
            .sub => .sub,
            else => unreachable,
        },
        .reg = .rcx,
    } });

    try finishArithmeticResult(&transaction, result_name, bits);
    return null;
}

pub fn lowerBinaryImmediateRhs(selector: *ComposedBlockSelector, result_name: []const u8, original: ir.BinaryInst) !?Diagnostic {
    var binary = original;
    if (binary.op == .urem) {
        const bits = intBits(binary.ty) orelse return .{ .no_emitter = "composed-block-binary-not-int" };
        const mask = composed_helpers.unsignedPowerOfTwoRemainderMask(bits, binary.rhs.int) orelse
            return .{ .no_emitter = "composed-block-binary-imm-rhs" };
        // Normalize the proven unsigned operation before typed action planning.
        // The ordinary AND action retains ownership of writes and rollback.
        binary.op = .@"and";
        binary.rhs = .{ .int = mask };
    }
    const literal = switch (binary.rhs) {
        .int => |int| int,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => unreachable,
    };
    const bits = intBits(binary.ty) orelse return .{ .no_emitter = "composed-block-binary-not-int" };
    if (isScalarImmediateLiveSharedSourcePreservation(binary))
        return scalar_immediate_live_shared_source_preservation(selector, result_name, binary, bits, literal);
    if (isScalarImmediateMultiAliasPreservation(binary))
        return scalar_immediate_multi_alias_preservation(selector, result_name, binary, bits, literal);
    if (isScalarImmediateFrameless64(selector, binary))
        return scalar_immediate_frameless64(selector, result_name, binary, bits, literal);
    if (ValueUseTransaction.isImmediateRhsScalar(binary))
        return lowerImmediateRhsScalar(selector, result_name, binary, bits, literal);

    if (binary.op == .sdiv)
        return .{ .no_emitter = "composed-block-sdiv-form" };
    return switch (binary.op) {
        .lshr => if (bits == 128) blk: {
            const amount = try shiftAmount7(literal);
            try selector_state.emitPairLshrImmediate(selector, result_name, binary.lhs, amount);
            break :blk null;
        } else .{ .no_emitter = "composed-block-binary-width" },
        .shl => if (bits == 128) blk: {
            const amount = try shiftAmount7(literal);
            try selector_state.emitPairShlImmediate(selector, result_name, binary.lhs, amount);
            break :blk null;
        } else if (bits > 32 and bits != 64)
            .{ .no_emitter = "composed-block-shl-imm-width" }
        else
            .{ .no_emitter = "composed-block-binary-imm-rhs" },
        .ashr => if (bits == 128) blk: {
            const amount = try shiftAmount7(literal);
            if (amount != 127) break :blk .{ .no_emitter = "composed-block-ashr-i128-amount" };
            try selector_state.emitPairSignMask(selector, result_name, binary.lhs, pair_a);
            break :blk null;
        } else if (bits > 32 and bits != 64)
            .{ .no_emitter = "composed-block-ashr-width" }
        else
            .{ .no_emitter = "composed-block-binary-imm-rhs" },
        .@"and", .@"or", .add, .sub, .xor => if (bits > 32 and bits != 64)
            .{ .no_emitter = "composed-block-binary-imm-rhs-width" }
        else
            .{ .no_emitter = "composed-block-binary-imm-rhs" },
        else => .{ .no_emitter = "composed-block-binary-imm-rhs" },
    };
}

pub fn lowerPairBinary(selector: *ComposedBlockSelector, result_name: []const u8, binary: ir.BinaryInst) !?Diagnostic {
    const op = machineBinaryOp(binary.op) orelse return .{ .no_emitter = "composed-block-pair-binary-op" };
    const lhs_existing = selector_state.resolvePairValue(selector, binary.lhs);
    const rhs_existing = selector_state.resolvePairValue(selector, binary.rhs);
    switch (op) {
        .xor => {
            const lhs = selector_state.materializePairValue(selector, binary.lhs, pair_a) catch return .{ .unsupported_value = "composed-block-unknown-lhs" };
            const rhs = selector_state.materializePairValue(selector, binary.rhs, pair_b) catch return .{ .unsupported_value = "composed-block-unknown-rhs" };
            try selector_state.emitPairXorInPlace(selector, rhs, lhs);
            try selector_state.bindPairScratch(selector, result_name, rhs);
        },
        .@"or" => {
            if (lhs_existing) |lhs_pair| {
                if (rhs_existing) |rhs_pair| {
                    try selector_state.emitPairOrInPlace(selector, lhs_pair, rhs_pair);
                    try selector_state.bindPairScratch(selector, result_name, lhs_pair);
                    return null;
                }
            }
            var lhs: RegPair = undefined;
            var rhs: RegPair = undefined;
            if (lhs_existing) |existing| {
                if (existing.eql(pair_b)) {
                    lhs = selector_state.materializePairValue(selector, binary.lhs, pair_a) catch return .{ .unsupported_value = "composed-block-unknown-lhs" };
                    rhs = selector_state.materializePairValue(selector, binary.rhs, pair_b) catch return .{ .unsupported_value = "composed-block-unknown-rhs" };
                } else {
                    rhs = selector_state.materializePairValue(selector, binary.rhs, pair_b) catch return .{ .unsupported_value = "composed-block-unknown-rhs" };
                    lhs = selector_state.materializePairValue(selector, binary.lhs, pair_a) catch return .{ .unsupported_value = "composed-block-unknown-lhs" };
                }
            } else {
                rhs = selector_state.materializePairValue(selector, binary.rhs, pair_b) catch return .{ .unsupported_value = "composed-block-unknown-rhs" };
                lhs = selector_state.materializePairValue(selector, binary.lhs, pair_a) catch return .{ .unsupported_value = "composed-block-unknown-lhs" };
            }
            try selector_state.emitPairOrInPlace(selector, rhs, lhs);
            try selector_state.bindPairScratch(selector, result_name, rhs);
        },
        .sub => {
            var lhs: RegPair = undefined;
            var rhs: RegPair = undefined;
            if (lhs_existing != null and rhs_existing != null) {
                lhs = lhs_existing.?;
                rhs = rhs_existing.?;
                // Both operands are live at this instruction. Reuse their
                // disjoint homes before any fixed scratch pair can clobber one.
                if (!lhs.eql(rhs) and (lhs.contains(rhs.lo) or lhs.contains(rhs.hi)))
                    return .{ .no_emitter = "composed-block-pair-sub-overlap" };
            } else {
                lhs = selector_state.materializePairValue(selector, binary.lhs, pair_b) catch return .{ .unsupported_value = "composed-block-unknown-lhs" };
                rhs = selector_state.materializePairValue(selector, binary.rhs, pair_a) catch return .{ .unsupported_value = "composed-block-unknown-rhs" };
            }
            try selector_state.emitPairSubInPlace(selector, lhs, rhs);
            try selector_state.bindPairScratch(selector, result_name, lhs);
        },
        else => return .{ .no_emitter = "composed-block-pair-binary-op" },
    }
    return null;
}

pub fn lowerMul64(selector: *ComposedBlockSelector, result_name: []const u8, binary: ir.BinaryInst) !?Diagnostic {
    // The complete M64 family uses one instruction-level transaction authority.
    var transaction = try ValueUseTransaction.begin(selector);
    defer transaction.deinit();
    const lhs_request = try transaction.register(.{
        .source = binary.lhs,
        .expected = .{ .ty = binary.ty, .register_class = .gpr64 },
        .form = .named_scalar_operand,
        .destination = .prepared_view,
    });
    const rhs_request = try transaction.register(.{
        .source = binary.rhs,
        .expected = .{ .ty = binary.ty, .register_class = .gpr64 },
        .form = .named_scalar_operand,
        .destination = .prepared_source,
    });
    try transaction.attachScalarMultiplyAction(lhs_request, .{
        .result = try ValueUseTransaction.ActionIdentity.init(result_name),
        .integer_ty = binary.ty,
        .rhs = rhs_request,
    });
    transaction.seal() catch |err|
        return scalarMultiplyValueUseDiagnostic(&transaction, lhs_request, rhs_request, err) orelse return err;
    transaction.prepare() catch |err|
        return scalarMultiplyValueUseDiagnostic(&transaction, lhs_request, rhs_request, err) orelse return err;
    transaction.materializeAll() catch |err|
        return scalarMultiplyValueUseDiagnostic(&transaction, lhs_request, rhs_request, err) orelse return err;
    const lease = transaction.preparedView(lhs_request) catch |err|
        return scalarMultiplyValueUseDiagnostic(&transaction, lhs_request, rhs_request, err) orelse return err;
    transaction.executePreparedAction(lease) catch |err|
        return scalarMultiplyValueUseDiagnostic(&transaction, lhs_request, rhs_request, err) orelse return err;
    try transaction.commit();
    return null;
}

fn scalarMultiplyValueUseDiagnostic(
    transaction: *const ValueUseTransaction,
    lhs_request: ValueUseTransaction.RequestHandle,
    rhs_request: ValueUseTransaction.RequestHandle,
    err: anyerror,
) ?Diagnostic {
    if (err == error.ValueUseActionDiagnostic) return transaction.actionDiagnostic();
    const unresolved = switch (err) {
        error.ValueUseSourcePlanMissing,
        error.ValueUseSourceIntervalMissing,
        error.ValueUseSourceGenerationChanged,
        error.ValueUseUnresolvedSource,
        error.ValueUseExpiredSource,
        error.ValueUseUnsupportedSource,
        error.ValueUseTypeMismatch,
        error.ValueUseRegisterClassMismatch,
        error.ValueUseSourceViewMismatch,
        error.ValueUseForwardPlanMissing,
        error.ValueUseForwardPlanMalformed,
        error.ValueUseForwardPlanStale,
        error.ValueUseForwardIntervalExpired,
        error.ValueUseForwardTypeMismatch,
        error.ValueUseForwardAssignmentMissing,
        error.ValueUseForwardSnapshotCapacityExceeded,
        => true,
        else => false,
    };
    const rejected = switch (err) {
        error.ValueUseNamedScalarFormUnsupported,
        error.ValueUseNamedScalarWidthUnsupported,
        error.ValueUseNamedScalarLocationUnsupported,
        error.ValueUseScalarMultiplyFormUnsupported,
        error.ValueUseScalarMultiplyWidthUnsupported,
        error.ValueUseScalarMultiplyLocationUnsupported,
        => true,
        else => false,
    };
    if (!unresolved and !rejected and
        err != error.ValueUseScalarMultiplyDestinationUnavailable) return null;
    if (transaction.failedRequestIs(lhs_request)) {
        if (err == error.ValueUseScalarMultiplyDestinationUnavailable)
            return .{ .no_spill_envelope = "composed-block-mul64-dst" };
        if (rejected) return .{ .no_emitter = "composed-block-mul64-lhs" };
        return .{ .unsupported_value = "composed-block-unknown-lhs" };
    }
    if (transaction.failedRequestIs(rhs_request)) {
        if (rejected) return .{ .no_emitter = "composed-block-mul64-rhs" };
        return .{ .unsupported_value = "composed-block-unknown-rhs" };
    }
    return null;
}

pub fn lowerUnsignedDivRem(selector: *ComposedBlockSelector, result_name: []const u8, binary: ir.BinaryInst, bits: u16) !?Diagnostic {
    if (binary.op == .urem) return lowerUnsignedRem(selector, result_name, binary, bits);
    if (!ValueUseTransaction.isUnsignedQuotient(binary)) unreachable;
    return lowerUnsignedQuotientValueUse(selector, result_name, binary, bits);
}

fn lowerUnsignedQuotientValueUse(
    selector: *ComposedBlockSelector,
    result_name: []const u8,
    binary: ir.BinaryInst,
    bits: u16,
) !?Diagnostic {
    var transaction = try ValueUseTransaction.begin(selector);
    defer transaction.deinit();
    const rhs_request = try transaction.register(.{
        .source = binary.rhs,
        .expected = .{
            .ty = binary.ty,
            .register_class = if (bits == 32) .gpr32 else .gpr64,
        },
        .form = .named_scalar_operand,
        .destination = .prepared_source,
    });
    const lhs_request = try transaction.register(.{
        .source = binary.lhs,
        .expected = .{
            .ty = binary.ty,
            .register_class = if (bits == 32) .gpr32 else .gpr64,
        },
        .form = .named_scalar_operand,
        .destination = .prepared_view,
    });
    try transaction.attachUnsignedQuotientAction(lhs_request, .{
        .result = try ValueUseTransaction.ActionIdentity.init(result_name),
        .integer_ty = binary.ty,
        .rhs = rhs_request,
    });
    transaction.seal() catch |err|
        return unsignedQuotientValueUseDiagnostic(&transaction, lhs_request, rhs_request, err) orelse return err;
    transaction.prepare() catch |err|
        return unsignedQuotientValueUseDiagnostic(&transaction, lhs_request, rhs_request, err) orelse return err;
    transaction.materializeAll() catch |err|
        return unsignedQuotientValueUseDiagnostic(&transaction, lhs_request, rhs_request, err) orelse return err;
    const lease = transaction.preparedView(lhs_request) catch |err|
        return unsignedQuotientValueUseDiagnostic(&transaction, lhs_request, rhs_request, err) orelse return err;
    transaction.executePreparedAction(lease) catch |err|
        return unsignedQuotientValueUseDiagnostic(&transaction, lhs_request, rhs_request, err) orelse return err;
    try transaction.commit();
    return null;
}

fn unsignedQuotientValueUseDiagnostic(
    transaction: *const ValueUseTransaction,
    lhs_request: ValueUseTransaction.RequestHandle,
    rhs_request: ValueUseTransaction.RequestHandle,
    err: anyerror,
) ?Diagnostic {
    if (err == error.ValueUseActionDiagnostic) return transaction.actionDiagnostic();
    const request_error = switch (err) {
        error.ValueUseSourcePlanMissing,
        error.ValueUseSourceIntervalMissing,
        error.ValueUseSourceGenerationChanged,
        error.ValueUseUnresolvedSource,
        error.ValueUseExpiredSource,
        error.ValueUseUnsupportedSource,
        error.ValueUseTypeMismatch,
        error.ValueUseRegisterClassMismatch,
        error.ValueUseSourceViewMismatch,
        error.ValueUseForwardPlanMissing,
        error.ValueUseForwardPlanMalformed,
        error.ValueUseForwardPlanStale,
        error.ValueUseForwardIntervalExpired,
        error.ValueUseForwardTypeMismatch,
        error.ValueUseForwardAssignmentMissing,
        error.ValueUseForwardSnapshotCapacityExceeded,
        error.ValueUseNamedScalarFormUnsupported,
        error.ValueUseNamedScalarWidthUnsupported,
        error.ValueUseNamedScalarLocationUnsupported,
        error.ValueUseUnsignedQuotientFormUnsupported,
        error.ValueUseUnsignedQuotientWidthUnsupported,
        error.ValueUseUnsignedQuotientLocationUnsupported,
        => true,
        else => false,
    };
    if (!request_error) return null;
    if (transaction.failedRequestIs(rhs_request))
        return .{ .unsupported_value = "composed-block-unknown-rhs" };
    if (transaction.failedRequestIs(lhs_request))
        return .{ .unsupported_value = "composed-block-unknown-lhs" };
    return null;
}

fn lowerUnsignedRem(selector: *ComposedBlockSelector, result_name: []const u8, binary: ir.BinaryInst, bits: u16) !?Diagnostic {
    const rhs = selector_state.resolveValue(selector, binary.rhs) orelse return .{ .unsupported_value = "composed-block-unknown-rhs" };
    const rhs_is_accumulator = switch (rhs) {
        .eax => bits == 32,
        .rax => bits == 64,
        else => false,
    };
    if (rhs_is_accumulator) {
        try selector_state.emitValueIntoScratch(selector, binary.rhs, .rcx, bits);
        try selector_state.emitValueIntoAccumulator(selector, binary.lhs, bits);
    } else {
        try selector_state.emitValueIntoAccumulator(selector, binary.lhs, bits);
        try selector_state.emitValueIntoScratch(selector, binary.rhs, .rcx, bits);
    }
    try selector_state.clobberArgReg(selector, .rdx);
    try emitArithmeticWrite(selector, .xor_edx_edx);
    try selector_state.emitEflagsInstruction(selector, if (bits == 32) .{ .div_arg32 = .rcx } else .{ .div_arg64 = .rcx }, .clobber);
    try selector_state.bindScratch(selector, result_name, .rdx, bits);
    return null;
}

pub fn lowerBinaryImmediateLhs(selector: *ComposedBlockSelector, result_name: []const u8, binary: ir.BinaryInst) !?Diagnostic {
    const literal = switch (binary.lhs) {
        .int => |int| int,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => unreachable,
    };
    const bits = intBits(binary.ty) orelse return .{ .no_emitter = "composed-block-binary-not-int" };
    if (binary.op == .sub and bits == 128 and literal == 0) {
        const rhs = selector_state.materializePairValue(selector, binary.rhs, pair_a) catch
            return .{ .unsupported_value = "composed-block-unknown-rhs" };
        try selector_state.emitZeroArg64(selector, pair_b.lo);
        try selector_state.emitZeroArg64(selector, pair_b.hi);
        try selector_state.emitPairSubInPlace(selector, pair_b, rhs);
        try selector_state.bindPairScratch(selector, result_name, pair_b);
        return null;
    }
    if (ValueUseTransaction.isImmediateLhsScalar(binary))
        return lowerImmediateLhsScalar(selector, result_name, binary, bits, literal);
    if (binary.op != .lshr) return .{ .no_emitter = "composed-block-binary-imm-lhs" };
    if (bits > 32 and bits != 64) return .{ .no_emitter = "composed-block-variable-shift-width" };
    return .{ .no_emitter = "composed-block-binary-imm-lhs" };
}

pub fn lowerIntToPtr(selector: *ComposedBlockSelector, result: ?[]const u8, cast: ir.CastInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    if (cast.op != .inttoptr or !cast.from_ty.eql(.{ .int = 64 }) or cast.to_ty != .ptr or cast.value != .named or cast.flags.any())
        return .{ .no_emitter = "composed-block-inttoptr-form" };
    const text = if (selector.module_context) |context| context.target_datalayout else null;
    const layout = target.DataLayout.parse(text orelse "") catch return .{ .no_emitter = "composed-block-inttoptr-layout" };
    if ((layout.pointerSizeBits() catch return .{ .no_emitter = "composed-block-inttoptr-layout" }) != 64)
        return .{ .no_emitter = "composed-block-inttoptr-layout" };
    return lowerAccumulatorScalarCast(selector, result_name, cast, 64, 64, false);
}

pub fn lowerCast(selector: *ComposedBlockSelector, result: ?[]const u8, cast: ir.CastInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    const pointer_bits = cast.op == .ptrtoint and cast.from_ty == .ptr;
    if (cast.op == .ptrtoint and (!pointer_bits or !cast.to_ty.eql(.{ .int = 64 }) or cast.value != .named or cast.flags.any()))
        return .{ .no_emitter = "composed-block-ptrtoint-form" };
    const from_bits = if (pointer_bits) @as(u16, 64) else intBits(cast.from_ty) orelse return .{ .no_emitter = "composed-block-cast-from-not-int" };
    const to_bits = intBits(cast.to_ty) orelse return .{ .no_emitter = "composed-block-cast-to-not-int" };
    if (from_bits == 52 or to_bits == 52) {
        if (ValueUseTransaction.isAccumulatorScalarCast(cast, false))
            return lowerAccumulatorScalarCast(selector, result_name, cast, from_bits, to_bits, false);
        return lowerI52Cast(cast);
    }
    if (from_bits > 128) return .{ .no_emitter = "composed-block-cast-width" };
    if (to_bits > 64 and !(cast.op == .zext and from_bits == 64 and to_bits == 128)) {
        return .{ .no_emitter = "composed-block-cast-width" };
    }

    switch (cast.op) {
        .trunc, .bitcast, .ptrtoint => {
            if (ValueUseTransaction.isPairLowScalarCast(cast))
                return lowerPairLowScalarCast(selector, result_name, cast, from_bits, to_bits);
            const loc = selector_state.resolveValue(selector, cast.value) orelse return .{ .unsupported_value = "composed-block-unknown-cast" };
            const result_loc: ValueLoc = if (from_bits > 32 and to_bits <= 32) switch (loc) {
                .arg64, .scratch64 => |reg| .{ .scratch32 = reg },
                .rax => .eax,
                .spill64 => |frame_index| .{ .spill64 = frame_index },
                .arg32, .scratch32, .eax => loc,
                .arg128, .scratch128, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill128, .spill_fp, .spill_vector, .aggregate_sse => return .{ .no_emitter = "composed-block-cast-width" },
            } else loc;
            try selector_state.bindValueLoc(selector, result_name, result_loc);
            switch (result_loc) {
                .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .spill64 => {},
                .arg128, .scratch128, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill128, .spill_fp, .spill_vector, .aggregate_sse => return .{ .no_emitter = "composed-block-cast-width" },
            }
        },
        .zext => {
            if (from_bits == 64 and to_bits == 128) {
                const dst = try selector_state.choosePairScratchForClobber(selector, null) orelse return .{ .no_spill_envelope = "composed-block-zext-pair" };
                try selector_state.emitValueIntoScratch(selector, cast.value, dst.lo, 64);
                try selector_state.emitZeroArg64(selector, dst.hi);
                try selector_state.bindPairScratch(selector, result_name, dst);
                return null;
            }
            const exact_ei_narrow = isExactEiNarrowBits(selector, from_bits) or isExactEiNarrowBits(selector, to_bits);
            if ((from_bits == 51 or from_bits == 52 or (from_bits > 32 and to_bits != 64)) and !exact_ei_narrow)
                return .{ .no_emitter = "composed-block-zext-width" };
            if (to_bits > 32 and to_bits != 64 and !exact_ei_narrow) return .{ .no_emitter = "composed-block-zext-width" };
            if (ValueUseTransaction.isAccumulatorScalarCast(cast, exact_ei_narrow))
                return lowerAccumulatorScalarCast(selector, result_name, cast, from_bits, to_bits, exact_ei_narrow);
            return error.UnsupportedCodegenValue;
        },
        .sext => {
            if (from_bits != 32 or to_bits != 64) return .{ .no_emitter = "composed-block-sext-width" };
            if (ValueUseTransaction.isSignExtendScratchCast(cast))
                return lowerSignExtendScratchCast(selector, result_name, cast);
            return .{ .unsupported_value = "composed-block-unknown-sext" };
        },
        else => return .{ .no_emitter = "composed-block-cast-op" },
    }
    return null;
}

const ScalarCastDiagnosticKind = enum {
    pair_low,
    accumulator,
    sign_extend,
};

fn lowerPairLowScalarCast(
    selector: *ComposedBlockSelector,
    result_name: []const u8,
    cast: ir.CastInst,
    from_bits: u16,
    to_bits: u16,
) !?Diagnostic {
    var transaction = try ValueUseTransaction.begin(selector);
    defer transaction.deinit();
    const source_request = try transaction.register(.{
        .source = cast.value,
        .expected = .{
            .ty = cast.from_ty,
            .register_class = .gpr128,
        },
        .form = .pair_low_scalar_cast_operand,
        .destination = .prepared_view,
        .prepared_action = .{ .pair_low_scalar_cast = .{
            .result = try ValueUseTransaction.ActionIdentity.init(result_name),
            .op = cast.op,
            .from_bits = from_bits,
            .to_bits = to_bits,
        } },
    });
    transaction.seal() catch |err|
        return scalarCastValueUseDiagnostic(&transaction, source_request, .pair_low, err) orelse return err;
    transaction.prepare() catch |err|
        return scalarCastValueUseDiagnostic(&transaction, source_request, .pair_low, err) orelse return err;
    transaction.materializeAll() catch |err|
        return scalarCastValueUseDiagnostic(&transaction, source_request, .pair_low, err) orelse return err;
    const lease = transaction.preparedView(source_request) catch |err|
        return scalarCastValueUseDiagnostic(&transaction, source_request, .pair_low, err) orelse return err;
    transaction.executePreparedAction(lease) catch |err|
        return scalarCastValueUseDiagnostic(&transaction, source_request, .pair_low, err) orelse return err;
    try transaction.commit();
    return null;
}

fn lowerAccumulatorScalarCast(
    selector: *ComposedBlockSelector,
    result_name: []const u8,
    cast: ir.CastInst,
    from_bits: u16,
    to_bits: u16,
    exact_ei: bool,
) !?Diagnostic {
    var transaction = try ValueUseTransaction.begin(selector);
    defer transaction.deinit();
    const source_request = try transaction.register(.{
        .source = cast.value,
        .expected = .{
            .ty = cast.from_ty,
            .register_class = if (from_bits <= 32) .gpr32 else .gpr64,
        },
        .form = .accumulator_scalar_cast_operand,
        .destination = .prepared_view,
        .prepared_action = .{ .accumulator_scalar_cast = .{
            .result = try ValueUseTransaction.ActionIdentity.init(result_name),
            .op = cast.op,
            .from_bits = from_bits,
            .to_bits = to_bits,
            .immediate = switch (cast.value) {
                .int => |value| value,
                else => null,
            },
            .exact_ei = exact_ei,
        } },
    });
    transaction.seal() catch |err|
        return scalarCastValueUseDiagnostic(&transaction, source_request, .accumulator, err) orelse return err;
    _ = try transaction.beginAccumulatorSession();
    transaction.prepare() catch |err|
        return scalarCastValueUseDiagnostic(&transaction, source_request, .accumulator, err) orelse return err;
    transaction.materializeAll() catch |err|
        return scalarCastValueUseDiagnostic(&transaction, source_request, .accumulator, err) orelse return err;
    const lease = transaction.preparedView(source_request) catch |err|
        return scalarCastValueUseDiagnostic(&transaction, source_request, .accumulator, err) orelse return err;
    transaction.executePreparedAction(lease) catch |err|
        return scalarCastValueUseDiagnostic(&transaction, source_request, .accumulator, err) orelse return err;
    try transaction.commit();
    return null;
}

fn lowerSignExtendScratchCast(
    selector: *ComposedBlockSelector,
    result_name: []const u8,
    cast: ir.CastInst,
) !?Diagnostic {
    var transaction = try ValueUseTransaction.begin(selector);
    defer transaction.deinit();
    const source_request = try transaction.register(.{
        .source = cast.value,
        .expected = .{
            .ty = cast.from_ty,
            .register_class = .gpr32,
        },
        .form = .sign_extend_scratch_operand,
        .destination = .prepared_view,
        .prepared_action = .{ .sign_extend_scratch = .{
            .result = try ValueUseTransaction.ActionIdentity.init(result_name),
        } },
    });
    transaction.seal() catch |err|
        return scalarCastValueUseDiagnostic(&transaction, source_request, .sign_extend, err) orelse return err;
    transaction.prepare() catch |err|
        return scalarCastValueUseDiagnostic(&transaction, source_request, .sign_extend, err) orelse return err;
    transaction.materializeAll() catch |err|
        return scalarCastValueUseDiagnostic(&transaction, source_request, .sign_extend, err) orelse return err;
    const lease = transaction.preparedView(source_request) catch |err|
        return scalarCastValueUseDiagnostic(&transaction, source_request, .sign_extend, err) orelse return err;
    transaction.executePreparedAction(lease) catch |err|
        return scalarCastValueUseDiagnostic(&transaction, source_request, .sign_extend, err) orelse return err;
    try transaction.commit();
    return null;
}

fn scalarCastValueUseDiagnostic(
    transaction: *const ValueUseTransaction,
    source_request: ValueUseTransaction.RequestHandle,
    kind: ScalarCastDiagnosticKind,
    err: anyerror,
) ?Diagnostic {
    if (err == error.ValueUseActionDiagnostic) return transaction.actionDiagnostic();
    if (!transaction.failedRequestIs(source_request)) return null;
    return switch (kind) {
        .pair_low => switch (err) {
            error.ValueUseScalarCastScratchUnavailable => .{ .no_spill_envelope = "composed-block-cast-scratch" },
            error.ValueUseUnresolvedSource,
            error.ValueUseExpiredSource,
            error.ValueUseUnsupportedSource,
            error.ValueUseTypeMismatch,
            error.ValueUseRegisterClassMismatch,
            error.ValueUseSourceViewMismatch,
            error.ValueUseScalarCastWidthUnsupported,
            error.ValueUseScalarCastLocationUnsupported,
            => .{ .unsupported_value = "composed-block-unknown-cast" },
            else => null,
        },
        .accumulator => switch (err) {
            error.ValueUseUnresolvedSource,
            error.ValueUseExpiredSource,
            error.ValueUseUnsupportedSource,
            error.ValueUseTypeMismatch,
            error.ValueUseRegisterClassMismatch,
            error.ValueUseSourceViewMismatch,
            error.ValueUseScalarCastWidthUnsupported,
            error.ValueUseScalarCastLocationUnsupported,
            error.ValueUseScalarCastImmediateMismatch,
            => .{ .unsupported_value = "composed-block-unknown-cast" },
            else => null,
        },
        .sign_extend => switch (err) {
            error.ValueUseUnresolvedSource,
            error.ValueUseExpiredSource,
            error.ValueUseUnsupportedSource,
            => .{ .unsupported_value = "composed-block-unknown-sext" },
            error.ValueUseTypeMismatch,
            error.ValueUseRegisterClassMismatch,
            error.ValueUseSourceViewMismatch,
            error.ValueUseScalarCastWidthUnsupported,
            error.ValueUseScalarCastLocationUnsupported,
            => .{ .no_emitter = "composed-block-sext-source" },
            else => null,
        },
    };
}

fn lowerI52Cast(
    cast: ir.CastInst,
) !?Diagnostic {
    if (cast.value != .named) return .{ .no_emitter = "composed-block-i52-cast-value" };
    return .{ .no_emitter = "composed-block-i52-cast-form" };
}

fn lowerI52Binary(selector: *ComposedBlockSelector, result_name: []const u8, binary: ir.BinaryInst) !?Diagnostic {
    const function = selector.function orelse return .{ .no_emitter = "composed-block-i52-shift-provenance" };
    if (binary.op != .shl or binary.lhs != .named or binary.rhs != .named or
        !isExactI52ShiftCount(function.*, binary.rhs.named))
    {
        return .{ .no_emitter = "composed-block-i52-binary-form" };
    }
    return lowerExactI52NamedScalarBinary(selector, result_name, binary);
}

fn lowerExactI52NamedScalarBinary(
    selector: *ComposedBlockSelector,
    result_name: []const u8,
    binary: ir.BinaryInst,
) !?Diagnostic {
    var transaction = try ValueUseTransaction.begin(selector);
    defer transaction.deinit();
    const lhs_request = try transaction.register(.{
        .source = binary.lhs,
        .expected = .{ .ty = binary.ty, .register_class = .gpr64 },
        .form = .named_scalar_operand,
        .destination = .prepared_view,
    });
    const rhs_request = try transaction.register(.{
        .source = binary.rhs,
        .expected = .{ .ty = binary.ty, .register_class = .gpr64 },
        .form = .named_scalar_operand,
        .destination = .prepared_source,
    });
    try transaction.attachExactI52BinaryAction(lhs_request, .{
        .result = try ValueUseTransaction.ActionIdentity.init(result_name),
        .rhs = rhs_request,
    });
    transaction.seal() catch |err|
        return namedScalarValueUseDiagnostic(&transaction, lhs_request, rhs_request, .i52b0, err) orelse return err;
    transaction.prepare() catch |err|
        return namedScalarValueUseDiagnostic(&transaction, lhs_request, rhs_request, .i52b0, err) orelse return err;
    transaction.materializeAll() catch |err|
        return namedScalarValueUseDiagnostic(&transaction, lhs_request, rhs_request, .i52b0, err) orelse return err;
    const lease = transaction.preparedView(lhs_request) catch |err|
        return namedScalarValueUseDiagnostic(&transaction, lhs_request, rhs_request, .i52b0, err) orelse return err;
    transaction.executePreparedAction(lease) catch |err|
        return namedScalarValueUseDiagnostic(&transaction, lhs_request, rhs_request, .i52b0, err) orelse return err;
    try transaction.commit();
    return null;
}

fn isExactI52ShiftCount(function: ir.Function, count_name: []const u8) bool {
    const widened = instructionByResult(function, count_name) orelse return false;
    const zext = switch (widened.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 6 }) or !zext.to_ty.eql(.{ .int = 52 }) or zext.value != .named) return false;

    const added = instructionByResult(function, zext.value.named) orelse return false;
    const add = switch (added.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.flags.nuw or !add.ty.eql(.{ .int = 6 }) or add.lhs != .named or !add.rhs.eql(.{ .int = 1 })) return false;

    const narrowed = instructionByResult(function, add.lhs.named) orelse return false;
    const trunc = switch (narrowed.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (trunc.op != .trunc or !trunc.from_ty.eql(.{ .int = 52 }) or !trunc.to_ty.eql(.{ .int = 6 }) or trunc.value != .named) return false;

    const counted = instructionByResult(function, trunc.value.named) orelse return false;
    const call = switch (counted.kind) {
        .call => |call| call,
        else => return false,
    };
    return isExactCtlzI52Envelope(call);
}

fn isExactCtlzI52Envelope(call: ir.CallInst) bool {
    if (!std.mem.eql(u8, call.callee, "llvm.ctlz.i52") or call.inline_asm != null or call.callee_value != null or
        call.callee_function_ty != null or call.calling_conv != null or call.raw_args != null or call.operand_bundle != null or
        !call.ret_ty.eql(.{ .int = 52 }) or call.args.items.len != 2)
    {
        return false;
    }
    if (call.tail_kind) |tail_kind| if (!std.mem.eql(u8, tail_kind, "tail")) return false;
    if (call.attrs) |attrs| {
        const trimmed = std.mem.trim(u8, attrs, " \t");
        if (trimmed.len < 2 or trimmed[0] != '#') return false;
        for (trimmed[1..]) |c| if (!std.ascii.isDigit(c)) return false;
    }
    const ret_attrs = std.mem.trim(u8, call.ret_attrs orelse return false, " \t");
    if (!std.mem.eql(u8, ret_attrs, "range(i52 0, 53)")) return false;
    return call.args.items[0].attrs == null and call.args.items[1].attrs == null and
        call.args.items[0].ty.eql(.{ .int = 52 }) and call.args.items[1].ty.eql(.{ .int = 1 }) and
        call.args.items[1].value.eql(.{ .int = 1 });
}

fn instructionByResult(function: ir.Function, name: []const u8) ?ir.Instruction {
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            if (instruction.result) |result| if (std.mem.eql(u8, result, name)) return instruction;
        }
    }
    return null;
}

fn maskRaxToI52(selector: *ComposedBlockSelector) !void {
    try selector_state.clobberArgReg(selector, .rcx);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rcx = (1 << 52) - 1 });
    try emitArithmeticWrite(selector, .{ .binary_arg_rax = .{ .op = .@"and", .reg = .rcx } });
}

fn accumulatorLocDisplacement(
    value: ir.Value,
    source: ValueLoc,
) selector_state.AccumulatorDisplacementPolicy {
    return switch (source) {
        .eax, .rax => switch (value) {
            .named => |name| .{ .reuse_source = name },
            else => .spill_live,
        },
        else => .spill_live,
    };
}

fn accumulatorArithmeticDisplacement(
    selector: *const ComposedBlockSelector,
    value: ir.Value,
    fallback: selector_state.AccumulatorDisplacementPolicy,
) !selector_state.AccumulatorDisplacementPolicy {
    const name = switch (value) {
        .named => |name| name,
        else => return fallback,
    };
    const source = selector_state.resolveValue(selector, value) orelse return fallback;
    return switch (source) {
        .eax, .rax => if (!try selector_state.valueIsLiveAfterCurrent(selector, name))
            .{ .reuse_source = name }
        else
            fallback,
        else => fallback,
    };
}

pub fn accumulatorPreserveCurrentDisplacement(
    selector: *const ComposedBlockSelector,
    value: ir.Value,
    fallback: selector_state.AccumulatorDisplacementPolicy,
) !selector_state.AccumulatorDisplacementPolicy {
    if (try selector_state.liveAccumulatorName(selector)) |name| return .{ .spill_source = name };
    const name = switch (value) {
        .named => |name| name,
        else => return fallback,
    };
    const source = selector_state.resolveValue(selector, value) orelse return fallback;
    return switch (source) {
        .eax, .rax => .{ .reuse_source = name },
        else => fallback,
    };
}

fn accumulatorDefinition(bits: u16) selector_state.AccumulatorDefinition {
    return if (bits <= 32)
        .zeroExtending(bits)
    else if (bits == 64)
        .fullRax()
    else
        .zeroExtendedRax(bits);
}

fn emitArithmeticWrite(selector: *ComposedBlockSelector, instruction: x86_64_machine.Instruction) !void {
    try selector_state.emitEflagsInstruction(selector, instruction, .write);
}

fn finishArithmeticResult(
    transaction: *selector_state.AccumulatorDefinitionTransaction,
    result_name: []const u8,
    bits: u16,
) !void {
    try transaction.define(result_name, accumulatorDefinition(bits));
    try transaction.commit();
}

pub fn isExactEiNarrowBits(selector: *const ComposedBlockSelector, bits: u16) bool {
    const function = selector.function orelse return false;
    if (!stage2_planning.isExactEiScalarFamily(function.*)) return false;
    return switch (bits) {
        3, 4, 5, 13, 14, 26, 27, 55, 56 => true,
        else => false,
    };
}

pub fn lowerFreeze(selector: *ComposedBlockSelector, result: ?[]const u8, freeze: ir.FreezeInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    const pointer = freeze.ty == .ptr;
    const bits = if (pointer) 64 else intBits(freeze.ty) orelse return .{ .no_emitter = "composed-block-freeze-type" };
    if (bits == 0 or (bits > 32 and bits != 64 and bits != 128)) return .{ .no_emitter = "composed-block-freeze-width" };
    const loc = selector_state.resolveValue(selector, freeze.value) orelse return .{ .unsupported_value = "composed-block-unknown-freeze" };
    if (pointer) switch (loc) {
        .arg64,
        .scratch64,
        .rax,
        .spill64,
        .stack_scalar,
        .stack128,
        .stack_i32_array,
        .stack_i32_ptr,
        .stack_f32_pair_ptr,
        .readonly_table_ptr,
        => {},
        else => return .{ .no_emitter = "composed-block-freeze-loc" },
    } else switch (loc) {
        .arg32, .scratch32, .eax => if (bits > 32) return .{ .no_emitter = "composed-block-freeze-width" },
        .arg64, .scratch64, .rax => if (bits != 64) return .{ .no_emitter = "composed-block-freeze-width" },
        .spill64 => if (bits != 64 and bits > 32) return .{ .no_emitter = "composed-block-freeze-width" },
        .arg128, .scratch128, .stack128_value, .spill128 => if (bits != 128) return .{ .no_emitter = "composed-block-freeze-width" },
        .xmm, .stack_scalar, .stack128, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill_fp, .spill_vector, .aggregate_sse => return .{ .no_emitter = "composed-block-freeze-loc" },
    }
    // A defined integer keeps its existing carrier. Narrow consumers interpret
    // its low bits; masking here would corrupt any wider alias of that carrier.
    // Non-named values (including undef/poison) remain unresolved above.
    try selector_state.bindValueLoc(selector, result_name, loc);
    return null;
}
