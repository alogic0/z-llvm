const std = @import("std");
const builtin = @import("builtin");
const ir = @import("../../../../../ir.zig");
const x86_64_types = @import("../../../types.zig");
const selector_types = @import("../../selector_types.zig");
const state_data = @import("../../composed_selector_state_data.zig");
const selector_state = @import("../../composed_selector_state.zig");

const ArgReg = x86_64_types.ArgReg;
const ComposedBlockSelector = state_data.ComposedBlockSelector;
const AccumulatorDefinition = selector_state.AccumulatorDefinition;
const AccumulatorDisplacementPolicy = selector_state.AccumulatorDisplacementPolicy;
const AccumulatorPreparationEffect = selector_state.AccumulatorPreparationEffect;
const model = @import("../model.zig");
const Types = model;
const composition = @import("../composition.zig");

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
