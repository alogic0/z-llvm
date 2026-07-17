const std = @import("std");
const builtin = @import("builtin");
const ir = @import("../../../../../ir.zig");
const machine_module = @import("../../../machine.zig");
const x86_64_types = @import("../../../types.zig");
const selector_types = @import("../../selector_types.zig");
const state_data = @import("../../composed_selector_state_data.zig");
const selector_state = @import("../../composed_selector_state.zig");

const ArgReg = x86_64_types.ArgReg;
const ComposedBlockSelector = state_data.ComposedBlockSelector;
const AccumulatorDefinition = selector_state.AccumulatorDefinition;
const AccumulatorDisplacementPolicy = selector_state.AccumulatorDisplacementPolicy;
const AccumulatorPreparationEffect = selector_state.AccumulatorPreparationEffect;
const AccumulatorDefinitionSession = selector_state.AccumulatorDefinitionSession;
const model = @import("../model.zig");
const Types = model;
const composition = @import("../composition.zig");

const ImmediateScalarPlan = enum {
    r00_signed_divide_by_two,
    r01_logical_shift_right_scratch,
    r01_logical_shift_right_accumulator,
    r02_shift_left_accumulator,
    r02_shift_left_scratch32_writeback,
    r03_arithmetic_shift_right_accumulator,
    r03_arithmetic_shift_right_scratch64,
    r04_narrow_accumulator_immediate,
    r05_wide_accumulator_immediate,
    r06_wide_scratch_immediate,
    l01_reverse_subtract,
    l02_variable_shift_left,
    l03_variable_logical_shift_right,
};

const AccumulatorScalarCastPlan = enum {
    c04_exact_ei,
    c05_narrow_zext,
    c52_0_trunc_i64_to_i52,
    c52_1_zext_i6_to_i52,
    c52_2_zext_i52_to_i64,
    c52_3_trunc_i52,
};

pub fn isPairLowScalarCast(cast: ir.CastInst) bool {
    const from_bits = switch (cast.from_ty) {
        .int => |bits| bits,
        else => return false,
    };
    const to_bits = switch (cast.to_ty) {
        .int => |bits| bits,
        else => return false,
    };
    return (cast.op == .trunc or cast.op == .bitcast) and
        cast.value == .named and from_bits == 128 and to_bits > 0 and to_bits <= 64;
}

pub fn isAccumulatorScalarCast(cast: ir.CastInst, exact_ei: bool) bool {
    const from_bits = switch (cast.from_ty) {
        .int => |bits| bits,
        else => return false,
    };
    const to_bits = switch (cast.to_ty) {
        .int => |bits| bits,
        else => return false,
    };
    if (from_bits == 0 or from_bits > 64 or to_bits == 0 or to_bits > 64) return false;
    if (from_bits == 52 or to_bits == 52) {
        if (cast.value != .named) return false;
        return (cast.op == .trunc and from_bits == 64 and to_bits == 52) or
            (cast.op == .zext and from_bits == 6 and to_bits == 52) or
            (cast.op == .zext and from_bits == 52 and to_bits == 64) or
            (cast.op == .trunc and from_bits == 52 and (to_bits == 6 or to_bits == 32));
    }
    if (cast.op != .zext) return false;
    if (exact_ei and !scalarCastExactEiBits(from_bits) and !scalarCastExactEiBits(to_bits))
        return false;
    if (from_bits > 32) return exact_ei and to_bits <= 64 and cast.value == .named;
    if (to_bits <= 32 or to_bits == 64 or exact_ei)
        return cast.value == .named or cast.value == .int;
    return false;
}

pub fn isSignExtendScratchCast(cast: ir.CastInst) bool {
    return cast.op == .sext and cast.value == .named and
        cast.from_ty.eql(.{ .int = 32 }) and cast.to_ty.eql(.{ .int = 64 });
}

pub fn validatePairLowScalarCastAction(action: *const Types.PairLowScalarCastAction) !void {
    if ((action.op != .trunc and action.op != .bitcast) or action.from_bits != 128 or
        action.to_bits == 0 or action.to_bits > 64)
    {
        return error.ValueUseScalarCastFormUnsupported;
    }
}

pub fn validateAccumulatorScalarCastAction(action: *const Types.AccumulatorScalarCastAction) !void {
    if (action.from_bits == 0 or action.from_bits > 64 or
        action.to_bits == 0 or action.to_bits > 64)
    {
        return error.ValueUseScalarCastFormUnsupported;
    }
    if (action.from_bits == 52 or action.to_bits == 52) {
        if (action.immediate != null) return error.ValueUseScalarCastImmediateMismatch;
        const valid = (action.op == .trunc and action.from_bits == 64 and action.to_bits == 52) or
            (action.op == .zext and action.from_bits == 6 and action.to_bits == 52) or
            (action.op == .zext and action.from_bits == 52 and action.to_bits == 64) or
            (action.op == .trunc and action.from_bits == 52 and
                (action.to_bits == 6 or action.to_bits == 32));
        if (!valid) return error.ValueUseScalarCastFormUnsupported;
        return;
    }
    if (action.op != .zext) return error.ValueUseScalarCastFormUnsupported;
    if (action.exact_ei and !scalarCastExactEiBits(action.from_bits) and
        !scalarCastExactEiBits(action.to_bits))
    {
        return error.ValueUseScalarCastFormUnsupported;
    }
    if (action.from_bits > 32) {
        if (!action.exact_ei or action.immediate != null)
            return error.ValueUseScalarCastFormUnsupported;
        return;
    }
    if (action.to_bits > 32 and action.to_bits != 64 and !action.exact_ei)
        return error.ValueUseScalarCastFormUnsupported;
}

fn scalarCastExactEiBits(bits: u16) bool {
    return switch (bits) {
        3, 4, 5, 13, 14, 26, 27, 55, 56 => true,
        else => false,
    };
}

pub fn executePairLowScalarCast(
    comptime Authority: type,
    transaction: anytype,
    source_index: u8,
    initial_source_view: *const Types.PreparedView,
    action: *const Types.PairLowScalarCastAction,
) !void {
    _ = initial_source_view;
    try validatePairLowScalarCastAction(action);
    const source_name = try scalarCastNamedSource(Authority, transaction, source_index);
    const binding = transaction.selector.values.get(source_name) orelse
        return error.ValueUseUnresolvedSource;
    const current = transaction.prepared_views[source_index].canonical_source_loc;
    if (binding.vreg.class != .gpr128 or binding.vreg.bits < 128)
        return scalarCastRequestError(Authority, transaction, source_index, error.ValueUseScalarCastWidthUnsupported);
    switch (current) {
        .arg128, .scratch128, .stack128_value, .spill128 => {},
        else => return scalarCastRequestError(Authority, transaction, source_index, error.ValueUseScalarCastLocationUnsupported),
    }

    const stored_action = &transaction.requests[source_index].prepared_action.?.pair_low_scalar_cast;
    const result_identity = &stored_action.result;
    const destination = plannedScalarCastScratch(transaction.selector, result_identity.slice()) orelse
        if (selector_state.resolvePairValue(transaction.selector, .{ .named = source_name })) |pair|
            pair.lo
        else
            scalarCastScratchForUse(transaction.selector) orelse
                return scalarCastRequestError(Authority, transaction, source_index, error.ValueUseScalarCastScratchUnavailable);
    try failScalarCastForTest(Authority, transaction, .after_scratch_selection);
    selector_state.emitPairLowLaneIntoScratch(
        transaction.selector,
        .{ .named = source_name },
        destination,
    ) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, source_index, err);
        return err;
    };
    try failScalarCastForTest(Authority, transaction, .after_pair_staging);
    const result_name = try composition.ownActionIdentity(Authority, transaction, &stored_action.result);
    try failScalarCastForTest(Authority, transaction, .after_result_identity_ownership);
    try selector_state.bindScratch(transaction.selector, result_name, destination, 64);
    try failScalarCastForTest(Authority, transaction, .after_result_definition);
}

pub fn executeAccumulatorScalarCast(
    comptime Authority: type,
    transaction: anytype,
    source_index: u8,
    initial_source_view: *const Types.PreparedView,
    action: *const Types.AccumulatorScalarCastAction,
) !void {
    _ = initial_source_view;
    try validateAccumulatorScalarCastAction(action);
    const session = if (transaction.accumulator_session) |*session|
        session
    else
        return error.ValueUseScalarCastAccumulatorSessionRequired;
    const source = try scalarCastSourceValue(Authority, transaction, source_index, action);
    const plan = scalarCastPlan(action);
    const displacement = try scalarCastDisplacement(Authority, transaction, source_index, plan);
    const effect: AccumulatorPreparationEffect = if (action.from_bits == 52)
        if (action.to_bits == 32 or action.to_bits == 64) .preserve else .clobber
    else if (action.from_bits < 32 or action.from_bits > 32)
        .clobber
    else
        .preserve;
    if (try session.prepare(effect, displacement)) |diagnostic| {
        transaction.action_diagnostic = diagnostic;
        return error.ValueUseActionDiagnostic;
    }
    try failScalarCastForTest(Authority, transaction, .after_accumulator_preparation);

    const materialization_definition: AccumulatorDefinition = if (action.from_bits == 64)
        .fullRax()
    else if (action.from_bits == 52)
        if (action.to_bits == 6 or action.to_bits == 32)
            .zeroExtending(32)
        else
            .zeroExtendedRax(52)
    else if (action.from_bits > 32)
        .zeroExtendedRax(action.from_bits)
    else
        .zeroExtending(action.from_bits);
    session.materialize(source, materialization_definition) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, source_index, err);
        return err;
    };
    try failScalarCastForTest(Authority, transaction, .after_accumulator_materialization);

    if ((action.from_bits > 32 and action.from_bits != 52) or
        (action.from_bits == 64 and action.to_bits == 52))
    {
        const mask: u64 = if (action.to_bits == 52)
            (@as(u64, 1) << 52) - 1
        else
            (@as(u64, 1) << @intCast(action.from_bits)) - 1;
        try selector_state.clobberArgReg(transaction.selector, .rcx);
        try transaction.selector.machine.instructions.append(
            transaction.selector.allocator,
            .{ .mov_imm_rcx = @bitCast(mask) },
        );
        try failScalarCastForTest(Authority, transaction, .after_mask_materialization);
        try selector_state.emitEflagsInstruction(
            transaction.selector,
            .{ .binary_arg_rax = .{ .op = .@"and", .reg = .rcx } },
            .write,
        );
        try failScalarCastForTest(Authority, transaction, .after_mask);
    } else if (action.from_bits < 32 or (action.from_bits == 52 and action.to_bits == 6)) {
        const shift: u5 = @intCast(if (action.from_bits == 52) action.to_bits else action.from_bits);
        const mask = (@as(i32, 1) << shift) - 1;
        try selector_state.emitEflagsInstruction(
            transaction.selector,
            .{ .and_eax_imm32 = mask },
            .write,
        );
        try failScalarCastForTest(Authority, transaction, .after_mask);
    }

    const stored_action = &transaction.requests[source_index].prepared_action.?.accumulator_scalar_cast;
    const result_name = try composition.ownActionIdentity(Authority, transaction, &stored_action.result);
    try failScalarCastForTest(Authority, transaction, .after_result_identity_ownership);
    try session.define(result_name, scalarCastResultDefinition(action.to_bits));
    try failScalarCastForTest(Authority, transaction, .after_result_definition);
    try session.finalize();
    try failScalarCastForTest(Authority, transaction, .after_finalization);
}

pub fn executeSignExtendScratch(
    comptime Authority: type,
    transaction: anytype,
    source_index: u8,
    initial_source_view: *const Types.PreparedView,
    action: *const Types.SignExtendScratchAction,
) !void {
    _ = initial_source_view;
    _ = action;
    const source_name = try scalarCastNamedSource(Authority, transaction, source_index);
    const binding = transaction.selector.values.get(source_name) orelse
        return error.ValueUseUnresolvedSource;
    if (binding.vreg.class != .gpr32 or binding.vreg.bits < 32)
        return scalarCastRequestError(Authority, transaction, source_index, error.ValueUseScalarCastWidthUnsupported);
    const source = switch (transaction.prepared_views[source_index].canonical_source_loc) {
        .arg32, .scratch32 => |reg| reg,
        else => return scalarCastRequestError(Authority, transaction, source_index, error.ValueUseScalarCastLocationUnsupported),
    };
    const destination: ArgReg = switch (source) {
        .rdi => .r8,
        .rsi => .r9,
        .rdx => .rcx,
        .rcx => .r8,
        .r8 => .r9,
        .r9 => .r8,
    };
    try transaction.selector.machine.instructions.append(
        transaction.selector.allocator,
        .{ .movsxd_arg32_arg64 = .{ .dst = destination, .src = source } },
    );
    try failScalarCastForTest(Authority, transaction, .after_sign_extend);
    const stored_action = &transaction.requests[source_index].prepared_action.?.sign_extend_scratch;
    const result_name = try composition.ownActionIdentity(Authority, transaction, &stored_action.result);
    try failScalarCastForTest(Authority, transaction, .after_result_identity_ownership);
    try selector_state.bindScratch(transaction.selector, result_name, destination, 64);
    try failScalarCastForTest(Authority, transaction, .after_result_definition);
}

fn scalarCastNamedSource(
    comptime Authority: type,
    transaction: anytype,
    source_index: u8,
) ![]const u8 {
    return switch (transaction.requests[source_index].source) {
        .named => |*identity| identity.slice(),
        .int, .null_value, .unsupported => {
            Authority.recordRequestFailure(Authority, transaction, source_index);
            return error.ValueUseUnsupportedSource;
        },
    };
}

fn scalarCastSourceValue(
    comptime Authority: type,
    transaction: anytype,
    source_index: u8,
    action: *const Types.AccumulatorScalarCastAction,
) !ir.Value {
    return switch (transaction.requests[source_index].source) {
        .named => |*identity| .{ .named = identity.slice() },
        .int => |value| {
            if (action.immediate == null or action.immediate.? != value) {
                Authority.recordRequestFailure(Authority, transaction, source_index);
                return error.ValueUseScalarCastImmediateMismatch;
            }
            return .{ .int = value };
        },
        .null_value, .unsupported => {
            Authority.recordRequestFailure(Authority, transaction, source_index);
            return error.ValueUseUnsupportedSource;
        },
    };
}

fn scalarCastDisplacement(
    comptime Authority: type,
    transaction: anytype,
    source_index: u8,
    plan: AccumulatorScalarCastPlan,
) !AccumulatorDisplacementPolicy {
    if (plan == .c52_0_trunc_i64_to_i52) return .spill_live;
    return scalarCastSourceDisplacement(Authority, transaction, source_index);
}

fn scalarCastSourceDisplacement(
    comptime Authority: type,
    transaction: anytype,
    source_index: u8,
) !AccumulatorDisplacementPolicy {
    return switch (transaction.requests[source_index].source) {
        .int => .spill_live,
        .named => |*identity| switch (transaction.prepared_views[source_index].canonical_source_loc) {
            .eax, .rax => .{ .reuse_source = identity.slice() },
            else => .spill_live,
        },
        .null_value, .unsupported => {
            Authority.recordRequestFailure(Authority, transaction, source_index);
            return error.ValueUseUnsupportedSource;
        },
    };
}

fn scalarCastPlan(action: *const Types.AccumulatorScalarCastAction) AccumulatorScalarCastPlan {
    if (action.from_bits == 52) {
        return if (action.op == .zext)
            .c52_2_zext_i52_to_i64
        else
            .c52_3_trunc_i52;
    }
    if (action.to_bits == 52) {
        return if (action.from_bits == 64)
            .c52_0_trunc_i64_to_i52
        else
            .c52_1_zext_i6_to_i52;
    }
    return if (action.from_bits > 32)
        .c04_exact_ei
    else
        .c05_narrow_zext;
}

fn scalarCastResultDefinition(bits: u16) AccumulatorDefinition {
    return if (bits <= 32)
        .zeroExtending(bits)
    else if (bits == 64)
        .fullRax()
    else
        .zeroExtendedRax(bits);
}

fn plannedScalarCastScratch(selector: *const ComposedBlockSelector, result: []const u8) ?ArgReg {
    const plan = selector.allocation_plan orelse return null;
    const assignment = plan.assignment(result) orelse return null;
    const reg = switch (assignment) {
        .gpr64 => |reg| reg,
        .gpr32, .gpr128, .fp16, .fp32, .fp64, .vector_xmm, .stack_object, .stack_pointer, .spill => return null,
    };
    return if (scalarCastScratchAvailable(selector, reg)) reg else null;
}

fn scalarCastScratchForUse(selector: *const ComposedBlockSelector) ?ArgReg {
    for (selector_types.selector_allocatable_regs) |reg|
        if (scalarCastScratchAvailable(selector, reg)) return reg;
    return null;
}

fn scalarCastScratchAvailable(selector: *const ComposedBlockSelector, reg: ArgReg) bool {
    return selector_state.regConflictStatus(selector, reg) orelse true;
}

fn scalarCastRequestError(
    comptime Authority: type,
    transaction: anytype,
    source_index: u8,
    err: Types.ScalarCastRequestError,
) Types.ScalarCastRequestError {
    Authority.noteRequestBoundaryError(Authority, transaction, source_index, err);
    return err;
}

fn failScalarCastForTest(
    comptime _: type,
    transaction: anytype,
    boundary: Types.ScalarCastTestFailure,
) !void {
    if (builtin.is_test and transaction.scalar_cast_test_failure == boundary)
        return error.ValueUseScalarCastTestFailure;
}

pub fn isImmediateRhsScalar(binary: ir.BinaryInst) bool {
    if (binary.lhs != .named or binary.rhs != .int) return false;
    const bits = integerBits(binary.ty) orelse return false;
    if (bits == 0 or bits > 64) return false;
    const literal = binary.rhs.int;
    return switch (binary.op) {
        .sdiv => bits == 32 and literal == 2,
        .lshr => bits == 16 or bits == 32 or bits == 64,
        .shl, .ashr => bits <= 32 or bits == 64,
        .@"and", .@"or", .add, .sub, .xor => bits <= 32 or bits == 64,
        else => false,
    };
}

pub fn isImmediateLhsScalar(binary: ir.BinaryInst) bool {
    if (binary.lhs != .int or binary.rhs != .named) return false;
    const bits = integerBits(binary.ty) orelse return false;
    if (bits == 0 or bits > 64) return false;
    return switch (binary.op) {
        .sub => bits <= 32 or bits == 64,
        .shl => bits == 16 or bits == 32,
        .lshr => bits <= 32 or bits == 64,
        else => false,
    };
}

pub fn validateImmediateRhsScalarAction(action: *const Types.ImmediateRhsScalarAction) !void {
    _ = try classifyImmediateRhsSemantic(action);
    try action.result.validate();
}

pub fn validateImmediateLhsScalarAction(action: *const Types.ImmediateLhsScalarAction) !void {
    _ = try classifyImmediateLhsSemantic(action);
    try action.result.validate();
}

pub fn executeImmediateRhsScalar(
    comptime Authority: type,
    transaction: anytype,
    source_index: u8,
    initial_source_view: *const Types.PreparedView,
    action: *const Types.ImmediateRhsScalarAction,
) !void {
    _ = initial_source_view;
    const semantic_plan = try classifyImmediateRhsSemantic(action);
    const bits = integerBits(action.integer_ty) orelse
        return immediateScalarRequestError(
            Authority,
            transaction,
            source_index,
            error.ValueUseImmediateScalarWidthUnsupported,
        );
    const source_name = try immediateScalarNamedSource(Authority, transaction, source_index);
    try validateImmediateScalarSource(Authority, transaction, source_index, bits);

    if (bits <= 32 and switch (semantic_plan) {
        .r02_shift_left_accumulator,
        .r03_arithmetic_shift_right_accumulator,
        .r04_narrow_accumulator_immediate,
        => true,
        else => false,
    }) {
        while (try selector_state.liveAccumulatorNameAfterCurrent(transaction.selector)) |live_name| {
            if (try selector_state.preserveLiveAccumulatorValue(transaction.selector, live_name)) |diagnostic| {
                transaction.action_diagnostic = diagnostic;
                return error.ValueUseActionDiagnostic;
            }
        }
        try failImmediateScalarForTest(transaction, .after_preservation);
        try refreshImmediateScalarSource(Authority, transaction, source_index);
    }

    switch (semantic_plan) {
        .r00_signed_divide_by_two => try executeImmediateR00(
            Authority,
            transaction,
            source_index,
            source_name,
            action,
        ),
        .r01_logical_shift_right_scratch => try executeImmediateR01(
            Authority,
            transaction,
            source_index,
            source_name,
            action,
            bits,
        ),
        .r02_shift_left_accumulator => try executeImmediateR02(
            Authority,
            transaction,
            source_index,
            source_name,
            action,
            bits,
        ),
        .r03_arithmetic_shift_right_accumulator,
        .r03_arithmetic_shift_right_scratch64,
        => try executeImmediateR03(
            Authority,
            transaction,
            source_index,
            source_name,
            action,
            bits,
        ),
        .r04_narrow_accumulator_immediate,
        .r05_wide_accumulator_immediate,
        .r06_wide_scratch_immediate,
        => try executeImmediateR04R06(
            Authority,
            transaction,
            source_index,
            source_name,
            action,
            bits,
        ),
        .r01_logical_shift_right_accumulator,
        .r02_shift_left_scratch32_writeback,
        .l01_reverse_subtract,
        .l02_variable_shift_left,
        .l03_variable_logical_shift_right,
        => unreachable,
    }
}

pub fn executeImmediateLhsScalar(
    comptime Authority: type,
    transaction: anytype,
    source_index: u8,
    initial_source_view: *const Types.PreparedView,
    action: *const Types.ImmediateLhsScalarAction,
) !void {
    _ = initial_source_view;
    const plan = try classifyImmediateLhsSemantic(action);
    const bits = integerBits(action.integer_ty) orelse
        return immediateScalarRequestError(
            Authority,
            transaction,
            source_index,
            error.ValueUseImmediateScalarWidthUnsupported,
        );
    _ = try immediateScalarNamedSource(Authority, transaction, source_index);
    try validateImmediateScalarSource(Authority, transaction, source_index, bits);
    try selector_state.emitValueIntoScratch(
        transaction.selector,
        immediateScalarSourceValue(transaction, source_index),
        .rcx,
        bits,
    );
    try failImmediateScalarForTest(transaction, .after_rcx_staging);

    const session = try beginImmediateAccumulatorSession(Authority, transaction);
    if (try session.prepare(.preserve, .spill_live)) |diagnostic| {
        transaction.action_diagnostic = diagnostic;
        return error.ValueUseActionDiagnostic;
    }
    try failImmediateScalarForTest(transaction, .after_accumulator_preparation);
    session.materialize(.{ .int = action.literal }, immediateAccumulatorDefinition(bits)) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, source_index, err);
        return err;
    };
    try failImmediateScalarForTest(
        transaction,
        if (bits <= 32) .after_eax_staging else .after_rax_staging,
    );

    switch (plan) {
        .l01_reverse_subtract => {
            try emitImmediateWrite(
                transaction,
                if (bits <= 32)
                    .{ .binary_arg_eax = .{ .op = .sub, .reg = .rcx } }
                else
                    .{ .binary_arg_rax = .{ .op = .sub, .reg = .rcx } },
            );
            try failImmediateScalarForTest(transaction, .after_first_instruction);
            if (bits < 32) {
                try emitImmediateWrite(transaction, .{
                    .and_eax_imm32 = (@as(i32, 1) << @intCast(bits)) - 1,
                });
                try failImmediateScalarForTest(transaction, .after_second_instruction);
            }
        },
        .l02_variable_shift_left => {
            try emitImmediateWrite(transaction, .shl_eax_cl);
            try failImmediateScalarForTest(transaction, .after_first_instruction);
            if (bits == 16) {
                try emitImmediateWrite(transaction, .{ .and_eax_imm32 = 0xffff });
                try failImmediateScalarForTest(transaction, .after_second_instruction);
            }
        },
        .l03_variable_logical_shift_right => {
            try emitImmediateWrite(
                transaction,
                if (bits <= 32) .shr_eax_cl else .shr_rax_cl,
            );
            try failImmediateScalarForTest(transaction, .after_first_instruction);
        },
        else => unreachable,
    }
    try finishImmediateAccumulatorResult(
        Authority,
        transaction,
        source_index,
        session,
        action.result,
        bits,
    );
}

fn classifyImmediateRhsSemantic(
    action: *const Types.ImmediateRhsScalarAction,
) Types.ImmediateScalarRequestError!ImmediateScalarPlan {
    const bits = integerBits(action.integer_ty) orelse
        return error.ValueUseImmediateScalarWidthUnsupported;
    if (bits == 0 or bits > 64) return error.ValueUseImmediateScalarWidthUnsupported;
    return switch (action.operation) {
        .sdiv => if (bits == 32 and action.literal == 2)
            .r00_signed_divide_by_two
        else
            error.ValueUseImmediateScalarFormUnsupported,
        .lshr => if (bits == 16 or bits == 32 or bits == 64)
            .r01_logical_shift_right_scratch
        else
            error.ValueUseImmediateScalarWidthUnsupported,
        .shl => if (bits <= 32 or bits == 64)
            .r02_shift_left_accumulator
        else
            error.ValueUseImmediateScalarWidthUnsupported,
        .ashr => if (bits <= 32)
            .r03_arithmetic_shift_right_accumulator
        else if (bits == 64)
            .r03_arithmetic_shift_right_scratch64
        else
            error.ValueUseImmediateScalarWidthUnsupported,
        .@"and", .@"or", .add, .sub, .xor => if (bits <= 32)
            .r04_narrow_accumulator_immediate
        else if (bits != 64)
            error.ValueUseImmediateScalarWidthUnsupported
        else if (action.operation == .sub)
            if (fitsI32(action.literal))
                .r06_wide_scratch_immediate
            else
                error.ValueUseImmediateScalarLiteralOutOfRange
        else if (action.operation == .add and fitsI32(action.literal))
            .r06_wide_scratch_immediate
        else
            .r05_wide_accumulator_immediate,
        else => error.ValueUseImmediateScalarFormUnsupported,
    };
}

fn classifyImmediateLhsSemantic(
    action: *const Types.ImmediateLhsScalarAction,
) Types.ImmediateScalarRequestError!ImmediateScalarPlan {
    const bits = integerBits(action.integer_ty) orelse
        return error.ValueUseImmediateScalarWidthUnsupported;
    if (bits == 0 or bits > 64) return error.ValueUseImmediateScalarWidthUnsupported;
    return switch (action.operation) {
        .sub => if (bits <= 32 or bits == 64)
            .l01_reverse_subtract
        else
            error.ValueUseImmediateScalarWidthUnsupported,
        .shl => if (bits == 16 or bits == 32)
            .l02_variable_shift_left
        else
            error.ValueUseImmediateScalarWidthUnsupported,
        .lshr => if (bits <= 32 or bits == 64)
            .l03_variable_logical_shift_right
        else
            error.ValueUseImmediateScalarWidthUnsupported,
        else => error.ValueUseImmediateScalarFormUnsupported,
    };
}

fn executeImmediateR00(
    comptime Authority: type,
    transaction: anytype,
    source_index: u8,
    source_name: []const u8,
    action: *const Types.ImmediateRhsScalarAction,
) !void {
    selector_state.clobberArgReg(transaction.selector, .rcx) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, source_index, err);
        return err;
    };
    const session = try beginImmediateAccumulatorSession(Authority, transaction);
    if (try session.prepare(
        .preserve,
        immediateSourceDisplacement(transaction, source_index, .scratch_preferred),
    )) |diagnostic| {
        transaction.action_diagnostic = diagnostic;
        return error.ValueUseActionDiagnostic;
    }
    try failImmediateScalarForTest(transaction, .after_accumulator_preparation);
    try materializeImmediateAccumulator(Authority, transaction, source_index, session, 32);
    try transaction.selector.machine.instructions.append(
        transaction.selector.allocator,
        .{ .mov_eax_to_arg = .rcx },
    );
    try failImmediateScalarForTest(transaction, .after_first_instruction);
    try emitImmediateWrite(transaction, .{ .shr_eax_imm5 = 31 });
    try failImmediateScalarForTest(transaction, .after_second_instruction);
    try emitImmediateWrite(transaction, .add_ecx_eax);
    try failImmediateScalarForTest(transaction, .after_third_instruction);
    try emitImmediateWrite(transaction, .{ .sar_eax_imm5 = 1 });
    try finishImmediateAccumulatorResult(
        Authority,
        transaction,
        source_index,
        session,
        action.result,
        32,
    );
    _ = source_name;
}

fn executeImmediateR01(
    comptime Authority: type,
    transaction: anytype,
    source_index: u8,
    source_name: []const u8,
    action: *const Types.ImmediateRhsScalarAction,
    bits: u16,
) !void {
    const amount = immediateShiftAmount(action.literal, bits) catch |err|
        return immediateScalarRequestError(Authority, transaction, source_index, err);
    if (bits <= 32) {
        try selector_state.emitValueIntoScratch(
            transaction.selector,
            .{ .named = source_name },
            .rcx,
            bits,
        );
        try failImmediateScalarForTest(transaction, .after_rcx_staging);
        if (amount != 0) {
            try emitImmediateWrite(transaction, .{ .shr_arg_imm5 = .{
                .reg = .rcx,
                .amount = @intCast(amount),
            } });
            try failImmediateScalarForTest(transaction, .after_first_instruction);
        }
        try bindImmediateScratchResult(
            Authority,
            transaction,
            source_index,
            action.result,
            .rcx,
            bits,
        );
        return;
    }

    const destination = try immediateScratch64Destination(
        Authority,
        transaction,
        source_index,
        &action.result,
    );
    if (destination) |reg| {
        try failImmediateScalarForTest(transaction, .after_scratch_selection);
        try selector_state.emitValueIntoScratch(
            transaction.selector,
            .{ .named = source_name },
            reg,
            64,
        );
        if (amount != 0) {
            try emitImmediateWrite(transaction, .{ .shr_arg64_imm6 = .{
                .reg = reg,
                .amount = @intCast(amount),
            } });
            try failImmediateScalarForTest(transaction, .after_first_instruction);
        }
        try bindImmediateScratchResult(
            Authority,
            transaction,
            source_index,
            action.result,
            reg,
            64,
        );
        return;
    }

    const current = transaction.prepared_views[source_index].canonical_source_loc;
    if (current != .spill64)
        return immediateScalarRequestError(
            Authority,
            transaction,
            source_index,
            error.ValueUseImmediateScalarScratchUnavailable,
        );
    const session = try beginImmediateAccumulatorSession(Authority, transaction);
    if (try session.prepare(.preserve, .spill_live)) |diagnostic| {
        transaction.action_diagnostic = diagnostic;
        return error.ValueUseActionDiagnostic;
    }
    try failImmediateScalarForTest(transaction, .after_accumulator_preparation);
    try materializeImmediateAccumulator(Authority, transaction, source_index, session, 64);
    if (amount != 0) {
        try emitImmediateWrite(transaction, .{ .shr_rax_imm6 = @intCast(amount) });
        try failImmediateScalarForTest(transaction, .after_first_instruction);
    }
    try finishImmediateAccumulatorResult(
        Authority,
        transaction,
        source_index,
        session,
        action.result,
        64,
    );
}

fn executeImmediateR02(
    comptime Authority: type,
    transaction: anytype,
    source_index: u8,
    source_name: []const u8,
    action: *const Types.ImmediateRhsScalarAction,
    bits: u16,
) !void {
    const amount = immediateShiftAmount(action.literal, bits) catch |err|
        return immediateScalarRequestError(Authority, transaction, source_index, err);
    const current = transaction.prepared_views[source_index].canonical_source_loc;
    if (bits <= 32 and current == .scratch32) {
        const destination = current.scratch32;
        if (try selector_state.preserveCurrentEaxIntoScratch(transaction.selector)) |diagnostic| {
            transaction.action_diagnostic = diagnostic;
            return error.ValueUseActionDiagnostic;
        }
        try failImmediateScalarForTest(transaction, .after_preservation);
        selector_state.emitValueIntoEax(
            transaction.selector,
            .{ .named = source_name },
        ) catch |err| {
            Authority.noteRequestBoundaryError(Authority, transaction, source_index, err);
            return err;
        };
        try failImmediateScalarForTest(transaction, .after_eax_staging);
        if (amount != 0) {
            try emitImmediateWrite(transaction, .{ .shl_eax_imm5 = @intCast(amount) });
            try failImmediateScalarForTest(transaction, .after_first_instruction);
        }
        try transaction.selector.machine.instructions.append(
            transaction.selector.allocator,
            .{ .mov_eax_to_arg = destination },
        );
        try bindImmediateScratchResult(
            Authority,
            transaction,
            source_index,
            action.result,
            destination,
            bits,
        );
        return;
    }

    const session = try beginImmediateAccumulatorSession(Authority, transaction);
    if (try session.prepare(
        .preserve,
        immediateSourceDisplacement(
            transaction,
            source_index,
            if (bits <= 32) .scratch_preferred else .spill_live,
        ),
    )) |diagnostic| {
        transaction.action_diagnostic = diagnostic;
        return error.ValueUseActionDiagnostic;
    }
    try failImmediateScalarForTest(transaction, .after_accumulator_preparation);
    try materializeImmediateAccumulator(Authority, transaction, source_index, session, bits);
    if (amount != 0) {
        try emitImmediateWrite(
            transaction,
            if (bits <= 32)
                .{ .shl_eax_imm5 = @intCast(amount) }
            else
                .{ .shl_rax_imm6 = @intCast(amount) },
        );
        try failImmediateScalarForTest(transaction, .after_first_instruction);
    }
    try finishImmediateAccumulatorResult(
        Authority,
        transaction,
        source_index,
        session,
        action.result,
        bits,
    );
}

fn executeImmediateR03(
    comptime Authority: type,
    transaction: anytype,
    source_index: u8,
    source_name: []const u8,
    action: *const Types.ImmediateRhsScalarAction,
    bits: u16,
) !void {
    const amount = immediateShiftAmount(action.literal, bits) catch |err|
        return immediateScalarRequestError(Authority, transaction, source_index, err);
    if (bits == 64) {
        try selector_state.emitValueIntoScratch(
            transaction.selector,
            .{ .named = source_name },
            .rcx,
            64,
        );
        try failImmediateScalarForTest(transaction, .after_rcx_staging);
        if (amount != 0) {
            try emitImmediateWrite(transaction, .{ .sar_arg64_imm6 = .{
                .reg = .rcx,
                .amount = @intCast(amount),
            } });
            try failImmediateScalarForTest(transaction, .after_first_instruction);
        }
        const result_name = try ownImmediateResult(
            Authority,
            transaction,
            source_index,
            action.result,
        );
        try selector_state.bindScratch(transaction.selector, result_name, .rcx, 64);
        try failImmediateScalarForTest(transaction, .after_result_definition);
        if (try selector_state.spillValue(transaction.selector, result_name)) |diagnostic| {
            transaction.action_diagnostic = diagnostic;
            return error.ValueUseActionDiagnostic;
        }
        return;
    }
    const session = try beginImmediateAccumulatorSession(Authority, transaction);
    if (try session.prepare(
        .preserve,
        immediateSourceDisplacement(transaction, source_index, .spill_live),
    )) |diagnostic| {
        transaction.action_diagnostic = diagnostic;
        return error.ValueUseActionDiagnostic;
    }
    try failImmediateScalarForTest(transaction, .after_accumulator_preparation);
    try materializeImmediateAccumulator(Authority, transaction, source_index, session, bits);
    if (amount != 0) {
        try emitImmediateWrite(transaction, .{ .sar_eax_imm5 = @intCast(amount) });
        try failImmediateScalarForTest(transaction, .after_first_instruction);
    }
    try finishImmediateAccumulatorResult(
        Authority,
        transaction,
        source_index,
        session,
        action.result,
        bits,
    );
}

fn executeImmediateR04R06(
    comptime Authority: type,
    transaction: anytype,
    source_index: u8,
    source_name: []const u8,
    action: *const Types.ImmediateRhsScalarAction,
    bits: u16,
) !void {
    if (bits == 64 and
        (action.operation == .add or action.operation == .sub) and
        fitsI32(action.literal))
    {
        try selector_state.emitValueIntoScratch(
            transaction.selector,
            .{ .named = source_name },
            .rcx,
            64,
        );
        try failImmediateScalarForTest(transaction, .after_rcx_staging);
        const immediate: i32 = @intCast(action.literal);
        try emitImmediateWrite(transaction, .{ .add_arg64_imm32 = .{
            .reg = .rcx,
            .imm = if (action.operation == .sub) -immediate else immediate,
        } });
        try failImmediateScalarForTest(transaction, .after_first_instruction);
        try bindImmediateScratchResult(
            Authority,
            transaction,
            source_index,
            action.result,
            .rcx,
            64,
        );
        return;
    }

    if (bits <= 32 and action.operation == .xor)
        try selector_state.clobberArgReg(transaction.selector, .rcx);
    const session = try beginImmediateAccumulatorSession(Authority, transaction);
    if (try session.prepare(
        .preserve,
        immediateSourceDisplacement(
            transaction,
            source_index,
            if (bits <= 32) .scratch_preferred else .spill_live,
        ),
    )) |diagnostic| {
        transaction.action_diagnostic = diagnostic;
        return error.ValueUseActionDiagnostic;
    }
    try failImmediateScalarForTest(transaction, .after_accumulator_preparation);
    try materializeImmediateAccumulator(Authority, transaction, source_index, session, bits);

    if (bits <= 32) {
        const literal = immediateI32(action.literal) catch |err|
            return immediateScalarRequestError(Authority, transaction, source_index, err);
        switch (action.operation) {
            .@"and" => try emitImmediateWrite(transaction, .{ .and_eax_imm32 = literal }),
            .@"or" => try emitImmediateWrite(transaction, .{ .or_eax_imm32 = literal }),
            .add => try emitImmediateWrite(transaction, .{ .add_eax_imm32 = literal }),
            .sub => try emitImmediateWrite(transaction, .{ .add_eax_imm32 = -literal }),
            .xor => {
                try transaction.selector.machine.instructions.append(
                    transaction.selector.allocator,
                    .{ .mov_imm_rcx = literal },
                );
                try emitImmediateWrite(
                    transaction,
                    .{ .binary_arg_eax = .{ .op = .xor, .reg = .rcx } },
                );
            },
            else => unreachable,
        }
        try failImmediateScalarForTest(transaction, .after_first_instruction);
    } else if (action.operation == .@"and" and action.literal == std.math.maxInt(u32)) {
        try emitImmediateWrite(transaction, .{ .and_eax_imm32 = -1 });
        try failImmediateScalarForTest(transaction, .after_first_instruction);
    } else {
        try selector_state.clobberArgReg(transaction.selector, .rcx);
        try transaction.selector.machine.instructions.append(
            transaction.selector.allocator,
            .{ .mov_imm_rcx = immediateI64(action.literal) catch |err|
                return immediateScalarRequestError(Authority, transaction, source_index, err) },
        );
        try failImmediateScalarForTest(transaction, .after_first_instruction);
        try emitImmediateWrite(transaction, .{ .binary_arg_rax = .{
            .op = switch (action.operation) {
                .@"and" => .@"and",
                .@"or" => .@"or",
                .add => .add,
                .xor => .xor,
                else => unreachable,
            },
            .reg = .rcx,
        } });
        try failImmediateScalarForTest(transaction, .after_second_instruction);
    }
    try finishImmediateAccumulatorResult(
        Authority,
        transaction,
        source_index,
        session,
        action.result,
        bits,
    );
}

fn beginImmediateAccumulatorSession(
    comptime Authority: type,
    transaction: anytype,
) !*AccumulatorDefinitionSession {
    try composition.beginAccumulatorSessionForPreparedAction(Authority, transaction);
    return &transaction.accumulator_session.?;
}

fn materializeImmediateAccumulator(
    comptime Authority: type,
    transaction: anytype,
    source_index: u8,
    session: *AccumulatorDefinitionSession,
    bits: u16,
) !void {
    session.materialize(
        immediateScalarSourceValue(transaction, source_index),
        immediateAccumulatorDefinition(bits),
    ) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, source_index, err);
        return err;
    };
    try failImmediateScalarForTest(
        transaction,
        if (bits <= 32) .after_eax_staging else .after_rax_staging,
    );
}

fn finishImmediateAccumulatorResult(
    comptime Authority: type,
    transaction: anytype,
    source_index: u8,
    session: *AccumulatorDefinitionSession,
    result: Types.ActionIdentity,
    bits: u16,
) !void {
    const result_name = try ownImmediateResult(
        Authority,
        transaction,
        source_index,
        result,
    );
    try session.define(result_name, immediateAccumulatorDefinition(bits));
    try failImmediateScalarForTest(transaction, .after_result_definition);
    try session.finalize();
    try failImmediateScalarForTest(transaction, .after_finalization);
}

fn bindImmediateScratchResult(
    comptime Authority: type,
    transaction: anytype,
    source_index: u8,
    result: Types.ActionIdentity,
    reg: ArgReg,
    bits: u16,
) !void {
    const result_name = try ownImmediateResult(
        Authority,
        transaction,
        source_index,
        result,
    );
    try selector_state.bindScratch(transaction.selector, result_name, reg, bits);
    try failImmediateScalarForTest(transaction, .after_result_definition);
}

fn ownImmediateResult(
    comptime Authority: type,
    transaction: anytype,
    source_index: u8,
    result: Types.ActionIdentity,
) ![]const u8 {
    const stored = switch (transaction.requests[source_index].prepared_action.?) {
        .immediate_rhs_scalar => |*action| &action.result,
        .immediate_lhs_scalar => |*action| &action.result,
        else => unreachable,
    };
    std.debug.assert(std.meta.eql(stored.*, result));
    const name = composition.ownActionIdentity(Authority, transaction, stored) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, source_index, err);
        return err;
    };
    try failImmediateScalarForTest(transaction, .after_result_identity_ownership);
    return name;
}

fn immediateScalarNamedSource(
    comptime Authority: type,
    transaction: anytype,
    source_index: u8,
) ![]const u8 {
    return switch (transaction.requests[source_index].source) {
        .named => |*identity| identity.slice(),
        .int, .null_value, .unsupported => {
            Authority.recordRequestFailure(Authority, transaction, source_index);
            return error.ValueUseUnsupportedSource;
        },
    };
}

fn immediateScalarSourceValue(transaction: anytype, source_index: u8) ir.Value {
    return switch (transaction.requests[source_index].source) {
        .named => |*identity| .{ .named = identity.slice() },
        .int => |value| .{ .int = value },
        .null_value => .null_value,
        .unsupported => .undef,
    };
}

fn validateImmediateScalarSource(
    comptime Authority: type,
    transaction: anytype,
    source_index: u8,
    bits: u16,
) !void {
    const source_name = try immediateScalarNamedSource(Authority, transaction, source_index);
    const binding = transaction.selector.values.get(source_name) orelse {
        Authority.recordRequestFailure(Authority, transaction, source_index);
        return error.ValueUseUnresolvedSource;
    };
    if (binding.vreg.bits < bits or switch (binding.vreg.class) {
        .gpr32 => bits > 32,
        .gpr64 => false,
        else => true,
    }) return immediateScalarRequestError(
        Authority,
        transaction,
        source_index,
        error.ValueUseImmediateScalarWidthUnsupported,
    );
    const current = transaction.prepared_views[source_index].canonical_source_loc;
    const valid = if (bits <= 32)
        switch (current) {
            .eax, .rax, .arg32, .arg64, .scratch32, .scratch64, .spill64 => true,
            else => false,
        }
    else switch (current) {
        .rax, .arg64, .scratch64, .spill64 => true,
        else => false,
    };
    if (!valid) return immediateScalarRequestError(
        Authority,
        transaction,
        source_index,
        error.ValueUseImmediateScalarLocationUnsupported,
    );
}

fn refreshImmediateScalarSource(
    comptime Authority: type,
    transaction: anytype,
    source_index: u8,
) !void {
    transaction.prepared_views[source_index] =
        Authority.materialization.buildPreparedRecord(
            Authority,
            transaction,
            source_index,
        ) catch |err| {
            Authority.noteRequestBoundaryError(Authority, transaction, source_index, err);
            return err;
        };
    transaction.prepared_view_valid[source_index] = true;
}

fn immediateSourceDisplacement(
    transaction: anytype,
    source_index: u8,
    fallback: AccumulatorDisplacementPolicy,
) AccumulatorDisplacementPolicy {
    const identity = switch (transaction.requests[source_index].source) {
        .named => |*name| name.slice(),
        else => return fallback,
    };
    return switch (transaction.prepared_views[source_index].canonical_source_loc) {
        .eax, .rax => .{ .reuse_source = identity },
        else => fallback,
    };
}

fn immediateScratch64Destination(
    comptime Authority: type,
    transaction: anytype,
    source_index: u8,
    result: *const Types.ActionIdentity,
) !?ArgReg {
    if (transaction.selector.allocation_plan) |plan| {
        if (plan.assignment(result.slice())) |assignment| {
            if (assignment == .gpr64 and immediateScratchAvailable(transaction.selector, assignment.gpr64))
                return assignment.gpr64;
        }
    }
    for (selector_types.selector_allocatable_regs) |reg|
        if (immediateScratchAvailable(transaction.selector, reg)) return reg;
    if (selector_state.reusableScratch64RegForInPlace(
        transaction.selector,
        immediateScalarSourceValue(transaction, source_index),
    )) |reg| return reg;
    if (selector_state.spillScratch64SourceForInPlace(
        transaction.selector,
        immediateScalarSourceValue(transaction, source_index),
    )) |source| {
        if (try selector_state.spillValue(transaction.selector, source.name)) |diagnostic| {
            transaction.action_diagnostic = diagnostic;
            return error.ValueUseActionDiagnostic;
        }
        return source.reg;
    }
    _ = Authority;
    return null;
}

fn immediateScratchAvailable(selector: *const ComposedBlockSelector, reg: ArgReg) bool {
    return selector_state.regConflictStatus(selector, reg) orelse true;
}

fn immediateAccumulatorDefinition(bits: u16) AccumulatorDefinition {
    return if (bits <= 32)
        .zeroExtending(bits)
    else
        .fullRax();
}

fn emitImmediateWrite(transaction: anytype, instruction: machine_module.Instruction) !void {
    try selector_state.emitEflagsInstruction(transaction.selector, instruction, .write);
}

fn immediateScalarRequestError(
    comptime Authority: type,
    transaction: anytype,
    source_index: u8,
    err: Types.ImmediateScalarRequestError,
) Types.ImmediateScalarRequestError {
    Authority.noteRequestBoundaryError(Authority, transaction, source_index, err);
    return err;
}

fn immediateShiftAmount(literal: i128, bits: u16) Types.ImmediateScalarRequestError!u7 {
    const physical_shift_width: u16 = if (bits <= 32) 32 else 64;
    if (literal < 0 or literal >= physical_shift_width)
        return error.ValueUseImmediateScalarLiteralOutOfRange;
    return @intCast(literal);
}

fn immediateI32(literal: i128) Types.ImmediateScalarRequestError!i32 {
    if (!fitsI32(literal)) return error.ValueUseImmediateScalarLiteralOutOfRange;
    return @intCast(literal);
}

fn immediateI64(literal: i128) Types.ImmediateScalarRequestError!i64 {
    if (literal < std.math.minInt(i64) or literal > std.math.maxInt(i64))
        return error.ValueUseImmediateScalarLiteralOutOfRange;
    return @intCast(literal);
}

fn fitsI32(literal: i128) bool {
    return literal >= std.math.minInt(i32) and literal <= std.math.maxInt(i32);
}

fn integerBits(ty: ir.Type) ?u16 {
    return switch (ty) {
        .int => |bits| bits,
        else => null,
    };
}

fn failImmediateScalarForTest(
    transaction: anytype,
    boundary: Types.ImmediateScalarTestFailure,
) !void {
    if (builtin.is_test and transaction.immediate_scalar_test_failure == boundary)
        return error.ValueUseImmediateScalarTestFailure;
}
