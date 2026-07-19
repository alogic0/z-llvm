const std = @import("std");
const builtin = @import("builtin");
const ir = @import("../../../../../ir.zig");
const machine_module = @import("../../../machine.zig");
const x86_64_types = @import("../../../types.zig");
const selector_types = @import("../../selector_types.zig");
const selector_state = @import("../../composed_selector_state.zig");
const model = @import("../model.zig");
const Types = model;
const composition = @import("../composition.zig");

const ArgReg = x86_64_types.ArgReg;
const ValueLoc = selector_types.ValueLoc;
const AccumulatorDefinitionSession = selector_state.AccumulatorDefinitionSession;

const ScalarMultiplyPlan = union(enum) {
    m64_destination: ArgReg,
    m64_accumulator,
};

const UnsignedQuotientPlan = enum {
    uq32,
    uq64,

    fn bits(plan: UnsignedQuotientPlan) u16 {
        return switch (plan) {
            .uq32 => 32,
            .uq64 => 64,
        };
    }

    fn definition(plan: UnsignedQuotientPlan) selector_state.AccumulatorDefinition {
        return switch (plan) {
            .uq32 => .zeroExtending(32),
            .uq64 => .fullRax(),
        };
    }

    fn rhsIsAccumulator(plan: UnsignedQuotientPlan, source: ValueLoc) bool {
        return switch (plan) {
            .uq32 => source == .eax,
            .uq64 => source == .rax,
        };
    }
};

pub fn isScalarMultiply(binary: ir.BinaryInst) bool {
    return binary.op == .mul and binary.ty.eql(.{ .int = 64 }) and
        binary.lhs == .named and binary.rhs == .named;
}

pub fn isUnsignedQuotient(binary: ir.BinaryInst) bool {
    if (binary.op != .udiv or binary.lhs != .named or binary.rhs != .named)
        return false;
    return binary.ty.eql(.{ .int = 32 }) or binary.ty.eql(.{ .int = 64 });
}

pub fn validateScalarMultiplyAction(action: *const Types.ScalarMultiplyAction) !void {
    try action.result.validate();
    try validateScalarMultiplyForm(action);
}

fn validateScalarMultiplyForm(action: *const Types.ScalarMultiplyAction) Types.ScalarMultiplyRequestError!void {
    if (!action.integer_ty.eql(.{ .int = 64 }))
        return error.ValueUseScalarMultiplyWidthUnsupported;
}

pub fn validateUnsignedQuotientAction(action: *const Types.UnsignedQuotientAction) !void {
    try action.result.validate();
    _ = try unsignedQuotientPlan(action);
}

fn unsignedQuotientPlan(
    action: *const Types.UnsignedQuotientAction,
) Types.UnsignedQuotientRequestError!UnsignedQuotientPlan {
    if (action.integer_ty.eql(.{ .int = 32 })) return .uq32;
    if (action.integer_ty.eql(.{ .int = 64 })) return .uq64;
    return error.ValueUseUnsignedQuotientWidthUnsupported;
}

pub fn executeScalarMultiply(
    comptime Authority: type,
    transaction: anytype,
    lhs_index: u8,
    initial_source_view: *const Types.PreparedView,
    action: *const Types.ScalarMultiplyAction,
) !void {
    _ = initial_source_view;
    validateScalarMultiplyForm(action) catch |err|
        return multiplyRequestError(Authority, transaction, lhs_index, err);
    const rhs_index = Authority.validateRegisteredOperandHandle(
        Authority,
        transaction,
        action.rhs,
    ) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, lhs_index, err);
        return err;
    };

    _ = try namedSource(Authority, transaction, lhs_index);
    _ = try namedSource(Authority, transaction, rhs_index);
    try validateSource(Authority, transaction, lhs_index);

    const plan = try selectPlan(Authority, transaction, lhs_index, action);
    try failForTest(transaction, .after_destination_selection);
    switch (plan) {
        .m64_destination => |dst| try executeDestinationPlan(
            Authority,
            transaction,
            lhs_index,
            rhs_index,
            action,
            dst,
        ),
        .m64_accumulator => try executeAccumulatorPlan(
            Authority,
            transaction,
            lhs_index,
            rhs_index,
            action,
        ),
    }
}

pub fn executeUnsignedQuotient(
    comptime Authority: type,
    transaction: anytype,
    lhs_index: u8,
    initial_source_view: *const Types.PreparedView,
    action: *const Types.UnsignedQuotientAction,
) !void {
    _ = initial_source_view;
    const plan = unsignedQuotientPlan(action) catch |err|
        return quotientRequestError(Authority, transaction, lhs_index, err);
    const rhs_index = Authority.validateRegisteredOperandHandle(
        Authority,
        transaction,
        action.rhs,
    ) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, lhs_index, err);
        return err;
    };

    _ = try namedSource(Authority, transaction, rhs_index);
    _ = try namedSource(Authority, transaction, lhs_index);
    try validateQuotientSource(Authority, transaction, rhs_index, plan);
    try validateQuotientSource(Authority, transaction, lhs_index, plan);

    const rhs_is_accumulator = plan.rhsIsAccumulator(
        transaction.prepared_views[rhs_index].canonical_source_loc,
    );
    try failQuotientForTest(transaction, .after_rhs_classification);
    try composition.beginAccumulatorSessionForPreparedAction(Authority, transaction);
    const session = &transaction.accumulator_session.?;

    if (rhs_is_accumulator) {
        try stageQuotientSource(Authority, transaction, rhs_index, .rcx, plan);
        try failQuotientForTest(transaction, .after_rhs_accumulator_staging);
        try refreshQuotientSource(Authority, transaction, lhs_index);
        try prepareQuotientAccumulator(
            Authority,
            transaction,
            lhs_index,
            session,
            quotientDisplacement(transaction, lhs_index),
        );
        try failQuotientForTest(transaction, .after_accumulator_preparation);
        try refreshQuotientSource(Authority, transaction, lhs_index);
        try materializeQuotientLhs(Authority, transaction, lhs_index, session, plan);
        try failQuotientForTest(transaction, .after_lhs_materialization);
    } else {
        try prepareQuotientAccumulator(
            Authority,
            transaction,
            lhs_index,
            session,
            quotientDisplacement(transaction, lhs_index),
        );
        try failQuotientForTest(transaction, .after_accumulator_preparation);
        try refreshQuotientSource(Authority, transaction, lhs_index);
        try materializeQuotientLhs(Authority, transaction, lhs_index, session, plan);
        try failQuotientForTest(transaction, .after_lhs_materialization);
        try refreshQuotientSource(Authority, transaction, rhs_index);
        try validateQuotientSource(Authority, transaction, rhs_index, plan);
        try stageQuotientSource(Authority, transaction, rhs_index, .rcx, plan);
        try failQuotientForTest(transaction, .after_rhs_non_accumulator_staging);
    }

    selector_state.clobberArgReg(transaction.selector, .rdx) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, lhs_index, err);
        return err;
    };
    try failQuotientForTest(transaction, .after_rdx_preservation);
    try selector_state.emitEflagsInstruction(transaction.selector, .xor_edx_edx, .write);
    try failQuotientForTest(transaction, .after_zero_high_dividend);
    try selector_state.emitEflagsInstruction(
        transaction.selector,
        switch (plan) {
            .uq32 => .{ .div_arg32 = .rcx },
            .uq64 => .{ .div_arg64 = .rcx },
        },
        .clobber,
    );
    try failQuotientForTest(transaction, .after_divide);

    const stored = switch (transaction.requests[lhs_index].prepared_action.?) {
        .unsigned_quotient => |*quotient| &quotient.result,
        else => unreachable,
    };
    std.debug.assert(std.meta.eql(stored.*, action.result));
    const result_name = composition.ownActionIdentity(Authority, transaction, stored) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, lhs_index, err);
        return err;
    };
    try failQuotientForTest(transaction, .after_result_identity_ownership);
    try session.define(result_name, plan.definition());
    try failQuotientForTest(transaction, .after_result_definition);
    try session.finalize();
    try failQuotientForTest(transaction, .after_finalization);
}

fn selectPlan(
    comptime Authority: type,
    transaction: anytype,
    lhs_index: u8,
    action: *const Types.ScalarMultiplyAction,
) !ScalarMultiplyPlan {
    const lhs = transaction.prepared_views[lhs_index].canonical_source_loc;
    return switch (lhs) {
        .scratch64 => |reg| if (transaction.selector.allocation_plan == null)
            .{ .m64_destination = reg }
        else if (selector_state.reusableScratch64RegForInPlace(
            transaction.selector,
            .{ .named = sourceName(transaction, lhs_index) },
        )) |reusable|
            .{ .m64_destination = reusable }
        else if (plannedResultScratch(transaction, &action.result)) |planned|
            .{ .m64_destination = planned }
        else if (freeScratch(transaction, null)) |free|
            .{ .m64_destination = free }
        else if (selector_state.spillScratch64SourceForInPlace(
            transaction.selector,
            .{ .named = sourceName(transaction, lhs_index) },
        )) |source| blk: {
            if (try selector_state.spillValue(transaction.selector, source.name)) |diagnostic| {
                transaction.action_diagnostic = diagnostic;
                return error.ValueUseActionDiagnostic;
            }
            try failForTest(transaction, .after_lhs_preservation);
            try refreshSource(Authority, transaction, lhs_index);
            const rhs_index = try Authority.validateRegisteredOperandHandle(
                Authority,
                transaction,
                action.rhs,
            );
            try refreshSource(Authority, transaction, rhs_index);
            try failForTest(transaction, .after_canonical_refresh);
            break :blk .{ .m64_destination = source.reg };
        } else multiplyRequestError(
            Authority,
            transaction,
            lhs_index,
            error.ValueUseScalarMultiplyDestinationUnavailable,
        ),
        .arg64, .rax, .spill64 => if (plannedResultScratch(transaction, &action.result)) |planned|
            .{ .m64_destination = planned }
        else if (freeScratch(transaction, null)) |free|
            .{ .m64_destination = free }
        else if (lhs == .spill64)
            .m64_accumulator
        else
            multiplyRequestError(
                Authority,
                transaction,
                lhs_index,
                error.ValueUseScalarMultiplyDestinationUnavailable,
            ),
        else => multiplyRequestError(
            Authority,
            transaction,
            lhs_index,
            error.ValueUseScalarMultiplyLocationUnsupported,
        ),
    };
}

fn executeDestinationPlan(
    comptime Authority: type,
    transaction: anytype,
    lhs_index: u8,
    rhs_index: u8,
    action: *const Types.ScalarMultiplyAction,
    dst: ArgReg,
) !void {
    try stageSource(Authority, transaction, lhs_index, dst);
    try failForTest(transaction, .after_lhs_staging);
    try refreshSource(Authority, transaction, rhs_index);
    try failForTest(transaction, .after_rhs_resolution);
    try validateSource(Authority, transaction, rhs_index);

    switch (transaction.prepared_views[rhs_index].canonical_source_loc) {
        .scratch64, .arg64 => |src| try emitWrite(
            transaction,
            .{ .imul_arg64_arg64 = .{ .dst = dst, .src = src } },
        ),
        .rax => try emitWrite(transaction, .{ .imul_arg64_rax = dst }),
        .spill64 => |frame_index| {
            if (freeScratch(transaction, dst)) |src| {
                try stageSource(Authority, transaction, rhs_index, src);
                try failForTest(transaction, .after_rhs_staging);
                try emitWrite(
                    transaction,
                    .{ .imul_arg64_arg64 = .{ .dst = dst, .src = src } },
                );
            } else {
                if (try selector_state.spillCurrentAccumulator(transaction.selector)) |diagnostic| {
                    transaction.action_diagnostic = diagnostic;
                    return error.ValueUseActionDiagnostic;
                }
                try transaction.selector.machine.instructions.append(
                    transaction.selector.allocator,
                    .{ .reload_rsp_rax = frame_index },
                );
                try failForTest(transaction, .after_rhs_staging);
                try emitWrite(transaction, .{ .imul_arg64_rax = dst });
            }
        },
        else => return multiplyRequestError(
            Authority,
            transaction,
            rhs_index,
            error.ValueUseScalarMultiplyLocationUnsupported,
        ),
    }
    try failForTest(transaction, .after_multiply);
    try finishScratchResult(Authority, transaction, lhs_index, action, dst);
}

fn executeAccumulatorPlan(
    comptime Authority: type,
    transaction: anytype,
    lhs_index: u8,
    rhs_index: u8,
    action: *const Types.ScalarMultiplyAction,
) !void {
    try composition.beginAccumulatorSessionForPreparedAction(Authority, transaction);
    const session = &transaction.accumulator_session.?;
    if (try session.prepare(.preserve, .spill_live)) |diagnostic| {
        transaction.action_diagnostic = diagnostic;
        return error.ValueUseActionDiagnostic;
    }
    try failForTest(transaction, .after_accumulator_preparation);
    try refreshSource(Authority, transaction, lhs_index);
    try refreshSource(Authority, transaction, rhs_index);
    try sessionMaterialize(Authority, transaction, lhs_index, session);
    try failForTest(transaction, .after_lhs_accumulator_reload);
    try refreshSource(Authority, transaction, rhs_index);
    try validateSource(Authority, transaction, rhs_index);
    switch (transaction.prepared_views[rhs_index].canonical_source_loc) {
        .arg64, .scratch64 => |src| try emitWrite(
            transaction,
            .{ .imul_rax_arg64 = src },
        ),
        .spill64 => |frame_index| try emitWrite(
            transaction,
            .{ .imul_rax_rsp = frame_index },
        ),
        else => return multiplyRequestError(
            Authority,
            transaction,
            rhs_index,
            error.ValueUseScalarMultiplyLocationUnsupported,
        ),
    }
    try failForTest(transaction, .after_multiply);
    const stored = switch (transaction.requests[lhs_index].prepared_action.?) {
        .scalar_multiply => |*multiply| &multiply.result,
        else => unreachable,
    };
    std.debug.assert(std.meta.eql(stored.*, action.result));
    const result_name = composition.ownActionIdentity(Authority, transaction, stored) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, lhs_index, err);
        return err;
    };
    try failForTest(transaction, .after_result_identity_ownership);
    try session.define(result_name, .fullRax());
    try failForTest(transaction, .after_result_definition);
    try session.finalize();
    try failForTest(transaction, .after_finalization);
}

fn finishScratchResult(
    comptime Authority: type,
    transaction: anytype,
    lhs_index: u8,
    action: *const Types.ScalarMultiplyAction,
    dst: ArgReg,
) !void {
    const stored = switch (transaction.requests[lhs_index].prepared_action.?) {
        .scalar_multiply => |*multiply| &multiply.result,
        else => unreachable,
    };
    std.debug.assert(std.meta.eql(stored.*, action.result));
    const result_name = composition.ownActionIdentity(Authority, transaction, stored) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, lhs_index, err);
        return err;
    };
    try failForTest(transaction, .after_result_identity_ownership);
    try selector_state.bindScratch(transaction.selector, result_name, dst, 64);
    try failForTest(transaction, .after_result_definition);
    try failForTest(transaction, .after_finalization);
}

fn plannedResultScratch(transaction: anytype, result: *const Types.ActionIdentity) ?ArgReg {
    const plan = transaction.selector.allocation_plan orelse return null;
    const assignment = plan.assignment(result.slice()) orelse return null;
    const reg = switch (assignment) {
        .gpr64 => |value| value,
        else => return null,
    };
    return if (scratchAvailable(transaction, reg)) reg else null;
}

fn freeScratch(transaction: anytype, avoid: ?ArgReg) ?ArgReg {
    for (selector_types.selector_allocatable_regs) |reg| {
        if (avoid != null and reg == avoid.?) continue;
        if (scratchAvailable(transaction, reg)) return reg;
    }
    return null;
}

fn scratchAvailable(transaction: anytype, reg: ArgReg) bool {
    return selector_state.regConflictStatus(transaction.selector, reg) orelse true;
}

fn sessionMaterialize(
    comptime Authority: type,
    transaction: anytype,
    index: u8,
    session: *AccumulatorDefinitionSession,
) !void {
    Authority.availabilityForConsumption(Authority, transaction, index) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, index, err);
        return err;
    };
    session.materialize(
        .{ .named = sourceName(transaction, index) },
        .fullRax(),
    ) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, index, err);
        return err;
    };
}

fn stageSource(
    comptime Authority: type,
    transaction: anytype,
    index: u8,
    reg: ArgReg,
) !void {
    Authority.availabilityForConsumption(Authority, transaction, index) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, index, err);
        return err;
    };
    selector_state.emitValueIntoScratch(
        transaction.selector,
        .{ .named = sourceName(transaction, index) },
        reg,
        64,
    ) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, index, err);
        return err;
    };
}

fn refreshSource(
    comptime Authority: type,
    transaction: anytype,
    index: u8,
) !void {
    Authority.availabilityForConsumption(Authority, transaction, index) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, index, err);
        return err;
    };
    transaction.prepared_views[index] =
        Authority.materialization.buildPreparedRecord(Authority, transaction, index) catch |err| {
            Authority.noteRequestBoundaryError(Authority, transaction, index, err);
            return err;
        };
    transaction.prepared_view_valid[index] = true;
}

fn validateSource(
    comptime Authority: type,
    transaction: anytype,
    index: u8,
) !void {
    _ = try namedSource(Authority, transaction, index);
    if (!transaction.prepared_view_valid[index]) {
        Authority.recordRequestFailure(Authority, transaction, index);
        return error.ValueUsePreparedViewMissing;
    }
    const binding = transaction.prepared_views[index].source_vreg;
    if (binding.class != .gpr64 or binding.bits < 64)
        return multiplyRequestError(
            Authority,
            transaction,
            index,
            error.ValueUseScalarMultiplyWidthUnsupported,
        );
    switch (transaction.prepared_views[index].canonical_source_loc) {
        .arg64, .scratch64, .rax, .spill64 => {},
        else => return multiplyRequestError(
            Authority,
            transaction,
            index,
            error.ValueUseScalarMultiplyLocationUnsupported,
        ),
    }
}

fn namedSource(comptime Authority: type, transaction: anytype, index: u8) ![]const u8 {
    return switch (transaction.requests[index].source) {
        .named => |*identity| identity.slice(),
        else => {
            Authority.recordRequestFailure(Authority, transaction, index);
            return error.ValueUseUnsupportedSource;
        },
    };
}

fn sourceName(transaction: anytype, index: u8) []const u8 {
    return transaction.requests[index].source.named.slice();
}

fn emitWrite(transaction: anytype, instruction: machine_module.Instruction) !void {
    try selector_state.emitEflagsInstruction(transaction.selector, instruction, .write);
}

fn quotientDisplacement(
    transaction: anytype,
    lhs_index: u8,
) selector_state.AccumulatorDisplacementPolicy {
    return switch (transaction.prepared_views[lhs_index].canonical_source_loc) {
        .eax, .rax => .{ .reuse_source = sourceName(transaction, lhs_index) },
        else => .spill_live,
    };
}

fn prepareQuotientAccumulator(
    comptime Authority: type,
    transaction: anytype,
    lhs_index: u8,
    session: *AccumulatorDefinitionSession,
    displacement: selector_state.AccumulatorDisplacementPolicy,
) !void {
    if (session.prepare(.preserve, displacement) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, lhs_index, err);
        return err;
    }) |diagnostic| {
        transaction.action_diagnostic = diagnostic;
        return error.ValueUseActionDiagnostic;
    }
}

fn materializeQuotientLhs(
    comptime Authority: type,
    transaction: anytype,
    lhs_index: u8,
    session: *AccumulatorDefinitionSession,
    plan: UnsignedQuotientPlan,
) !void {
    Authority.availabilityForConsumption(Authority, transaction, lhs_index) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, lhs_index, err);
        return err;
    };
    session.materialize(
        .{ .named = sourceName(transaction, lhs_index) },
        plan.definition(),
    ) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, lhs_index, err);
        return err;
    };
}

fn stageQuotientSource(
    comptime Authority: type,
    transaction: anytype,
    index: u8,
    reg: ArgReg,
    plan: UnsignedQuotientPlan,
) !void {
    Authority.availabilityForConsumption(Authority, transaction, index) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, index, err);
        return err;
    };
    selector_state.emitValueIntoScratch(
        transaction.selector,
        .{ .named = sourceName(transaction, index) },
        reg,
        plan.bits(),
    ) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, index, err);
        return err;
    };
}

fn refreshQuotientSource(
    comptime Authority: type,
    transaction: anytype,
    index: u8,
) !void {
    Authority.availabilityForConsumption(Authority, transaction, index) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, index, err);
        return err;
    };
    transaction.prepared_views[index] =
        Authority.materialization.buildPreparedRecord(Authority, transaction, index) catch |err| {
            Authority.noteRequestBoundaryError(Authority, transaction, index, err);
            return err;
        };
    transaction.prepared_view_valid[index] = true;
}

fn validateQuotientSource(
    comptime Authority: type,
    transaction: anytype,
    index: u8,
    plan: UnsignedQuotientPlan,
) !void {
    _ = try namedSource(Authority, transaction, index);
    if (!transaction.prepared_view_valid[index]) {
        Authority.recordRequestFailure(Authority, transaction, index);
        return error.ValueUsePreparedViewMissing;
    }
    const binding = transaction.prepared_views[index].source_vreg;
    const compatible = switch (plan) {
        .uq32 => (binding.class == .gpr32 or binding.class == .gpr64) and binding.bits >= 32,
        .uq64 => binding.class == .gpr64 and binding.bits >= 64,
    };
    if (!compatible)
        return quotientRequestError(
            Authority,
            transaction,
            index,
            error.ValueUseUnsignedQuotientWidthUnsupported,
        );
    const loc = transaction.prepared_views[index].canonical_source_loc;
    const accepted = switch (plan) {
        .uq32 => switch (loc) {
            .arg32, .scratch32, .arg64, .scratch64, .eax, .rax, .spill64 => true,
            else => false,
        },
        .uq64 => switch (loc) {
            .arg64, .scratch64, .rax, .spill64 => true,
            else => false,
        },
    };
    if (!accepted)
        return quotientRequestError(
            Authority,
            transaction,
            index,
            error.ValueUseUnsignedQuotientLocationUnsupported,
        );
}

fn multiplyRequestError(
    comptime Authority: type,
    transaction: anytype,
    index: u8,
    err: Types.ScalarMultiplyRequestError,
) Types.ScalarMultiplyRequestError {
    Authority.noteRequestBoundaryError(Authority, transaction, index, err);
    return err;
}

fn quotientRequestError(
    comptime Authority: type,
    transaction: anytype,
    index: u8,
    err: Types.UnsignedQuotientRequestError,
) Types.UnsignedQuotientRequestError {
    Authority.noteRequestBoundaryError(Authority, transaction, index, err);
    return err;
}

fn failForTest(transaction: anytype, boundary: Types.ScalarMultiplyTestFailure) !void {
    if (builtin.is_test and transaction.scalar_multiply_test_failure == boundary)
        return error.ValueUseScalarMultiplyTestFailure;
}

fn failQuotientForTest(transaction: anytype, boundary: Types.UnsignedQuotientTestFailure) !void {
    if (builtin.is_test and transaction.unsigned_quotient_test_failure == boundary)
        return error.ValueUseUnsignedQuotientTestFailure;
}
