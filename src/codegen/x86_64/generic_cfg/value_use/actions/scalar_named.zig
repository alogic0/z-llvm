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
const AccumulatorDefinition = selector_state.AccumulatorDefinition;
const AccumulatorDefinitionSession = selector_state.AccumulatorDefinitionSession;

const NamedScalarPlan = enum {
    b01_boolean,
    b03_narrow_multiply,
    b04_narrow_shift,
    b05_wide_shift,
    b06_wide_exact_binary,
    b07_general_binary,
};

const ExactI52Plan = enum {
    i52b0_guarded_shift,
};

pub fn isNamedScalarBinary(binary: ir.BinaryInst, exact_ei: bool) bool {
    if (binary.lhs != .named or binary.rhs != .named) return false;
    const action = Types.NamedScalarBinaryAction{
        .result = .{},
        .operation = binary.op,
        .integer_ty = binary.ty,
        .exact_ei = exact_ei,
        .rhs = .{ .authority = 0, .index = 0, .generation = 0 },
    };
    return classifyNamedScalar(&action) != error.ValueUseNamedScalarFormUnsupported and
        classifyNamedScalar(&action) != error.ValueUseNamedScalarWidthUnsupported and
        classifyNamedScalar(&action) != error.ValueUseNamedScalarExactEiUnsupported;
}

pub fn isExactI52Binary(ir_body: ?*const ir.Function, binary: ir.BinaryInst) bool {
    if (binary.op != .shl or !binary.ty.eql(.{ .int = 52 }) or
        binary.lhs != .named or binary.rhs != .named)
        return false;
    const body = ir_body orelse return false;
    return isExactI52ShiftCount(body.*, binary.rhs.named);
}

pub fn validateNamedScalarBinaryAction(action: *const Types.NamedScalarBinaryAction) !void {
    try action.result.validate();
    _ = try classifyNamedScalar(action);
}

pub fn validateExactI52BinaryAction(action: *const Types.ExactI52BinaryAction) !void {
    try action.result.validate();
    _ = classifyExactI52(action);
}

pub fn executeNamedScalarBinary(
    comptime Authority: type,
    transaction: anytype,
    lhs_index: u8,
    initial_source_view: *const Types.PreparedView,
    action: *const Types.NamedScalarBinaryAction,
) !void {
    _ = initial_source_view;
    const plan = classifyNamedScalar(action) catch |err|
        return namedRequestError(Authority, transaction, lhs_index, err);
    const bits = integerBits(action.integer_ty) orelse
        return namedRequestError(Authority, transaction, lhs_index, error.ValueUseNamedScalarWidthUnsupported);
    const rhs_index = Authority.validateRegisteredOperandHandle(Authority, transaction, action.rhs) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, lhs_index, err);
        return err;
    };
    const lhs_name = try namedSource(Authority, transaction, lhs_index);
    _ = try namedSource(Authority, transaction, rhs_index);
    try validateNamedSource(Authority, transaction, lhs_index, bits);

    if (plan == .b07_general_binary) {
        while (try selector_state.liveAccumulatorNameAfterCurrent(transaction.selector)) |live_name| {
            if (try selector_state.preserveLiveAccumulatorValue(transaction.selector, live_name)) |diagnostic| {
                transaction.action_diagnostic = diagnostic;
                return error.ValueUseActionDiagnostic;
            }
        }
        if (try Authority.mustSurviveInstruction(Authority, transaction, lhs_index)) {
            if (try selector_state.preserveLiveAccumulatorValue(transaction.selector, lhs_name)) |diagnostic| {
                transaction.action_diagnostic = diagnostic;
                return error.ValueUseActionDiagnostic;
            }
        }
        try failNamedForTest(transaction, .after_preamble);
        try refreshNamedSource(Authority, transaction, lhs_index);
        try refreshNamedSource(Authority, transaction, rhs_index);
        try failNamedForTest(transaction, .after_canonical_refresh);
        try validateNamedSource(Authority, transaction, rhs_index, bits);
        return executeGeneralNamedBinary(
            Authority,
            transaction,
            lhs_index,
            rhs_index,
            action,
            bits,
        );
    }

    const session = try beginNamedAccumulatorSession(Authority, transaction);
    switch (plan) {
        .b01_boolean, .b04_narrow_shift, .b05_wide_shift, .b06_wide_exact_binary => {
            try validateNamedSource(Authority, transaction, rhs_index, bits);
            try stageNamedSource(
                Authority,
                transaction,
                rhs_index,
                .rcx,
                if (plan == .b05_wide_shift or plan == .b06_wide_exact_binary) 64 else bits,
            );
            try failNamedForTest(transaction, .after_first_operand_staging);
            try prepareNamedAccumulator(
                Authority,
                transaction,
                lhs_index,
                session,
                try displacementForPlan(Authority, transaction, lhs_index, plan),
            );
            try failNamedForTest(transaction, .after_accumulator_preparation);
            try materializeNamedAccumulator(Authority, transaction, lhs_index, session, bits);
            try failNamedForTest(transaction, .after_second_operand_staging);
        },
        .b03_narrow_multiply => {
            try prepareNamedAccumulator(
                Authority,
                transaction,
                lhs_index,
                session,
                try displacementForPlan(Authority, transaction, lhs_index, plan),
            );
            try failNamedForTest(transaction, .after_accumulator_preparation);
            try validateNamedSource(Authority, transaction, rhs_index, bits);
            try stageNamedSource(Authority, transaction, rhs_index, .rcx, bits);
            try failNamedForTest(transaction, .after_first_operand_staging);
            try materializeNamedAccumulator(Authority, transaction, lhs_index, session, bits);
            try failNamedForTest(transaction, .after_second_operand_staging);
        },
        .b07_general_binary => unreachable,
    }

    try emitNamedWrite(transaction, instructionForPlan(plan, action.operation, bits));
    try failNamedForTest(transaction, .after_first_arithmetic_write);
    try finishNamedResult(Authority, transaction, lhs_index, session, action.result, bits);
}

pub fn executeExactI52Binary(
    comptime Authority: type,
    transaction: anytype,
    lhs_index: u8,
    initial_source_view: *const Types.PreparedView,
    action: *const Types.ExactI52BinaryAction,
) !void {
    _ = initial_source_view;
    _ = classifyExactI52(action);
    const rhs_index = Authority.validateRegisteredOperandHandle(Authority, transaction, action.rhs) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, lhs_index, err);
        return err;
    };
    _ = try namedSource(Authority, transaction, lhs_index);
    _ = try namedSource(Authority, transaction, rhs_index);
    try validateNamedSource(Authority, transaction, lhs_index, 52);

    const session = try beginNamedAccumulatorSession(Authority, transaction);
    try prepareNamedAccumulator(
        Authority,
        transaction,
        lhs_index,
        session,
        try displacementForPlan(Authority, transaction, lhs_index, .b05_wide_shift),
    );
    try failNamedForTest(transaction, .after_accumulator_preparation);
    try validateNamedSource(Authority, transaction, rhs_index, 52);
    try stageNamedSource(Authority, transaction, rhs_index, .rcx, 64);
    try failNamedForTest(transaction, .after_first_operand_staging);
    try materializeNamedAccumulator(Authority, transaction, lhs_index, session, 52);
    try failNamedForTest(transaction, .after_second_operand_staging);
    try emitNamedWrite(transaction, .shl_rax_cl);
    try failNamedForTest(transaction, .after_first_arithmetic_write);
    try selector_state.clobberArgReg(transaction.selector, .rcx);
    try transaction.selector.machine.instructions.append(
        transaction.selector.allocator,
        .{ .mov_imm_rcx = (1 << 52) - 1 },
    );
    try emitNamedWrite(transaction, .{ .binary_arg_rax = .{ .op = .@"and", .reg = .rcx } });
    try failNamedForTest(transaction, .after_second_arithmetic_write);
    try finishNamedResult(Authority, transaction, lhs_index, session, action.result, 52);
}

fn executeGeneralNamedBinary(
    comptime Authority: type,
    transaction: anytype,
    lhs_index: u8,
    rhs_index: u8,
    action: *const Types.NamedScalarBinaryAction,
    bits: u16,
) !void {
    const op = machineBinaryOp(action.operation).?;
    const lhs = transaction.prepared_views[lhs_index].canonical_source_loc;
    const rhs = transaction.prepared_views[rhs_index].canonical_source_loc;

    if (locIsAccumulator(lhs) and locIsAccumulator(rhs)) {
        const session = try beginNamedAccumulatorSession(Authority, transaction);
        try Authority.availabilityForConsumption(Authority, transaction, rhs_index);
        const lhs_name = sourceNameUnchecked(transaction, lhs_index);
        const rhs_name = sourceNameUnchecked(transaction, rhs_index);
        if (std.mem.eql(u8, lhs_name, rhs_name)) {
            try selector_state.emitValueIntoScratch(
                transaction.selector,
                .{ .named = rhs_name },
                .rcx,
                bits,
            );
        } else {
            try selector_state.emitValueIntoScratchAndRelocate(
                transaction.selector,
                .{ .named = rhs_name },
                .rcx,
                bits,
            );
        }
        try failNamedForTest(transaction, .after_first_operand_staging);
        try prepareNamedAccumulator(
            Authority,
            transaction,
            lhs_index,
            session,
            try displacementForPlan(Authority, transaction, lhs_index, .b07_general_binary),
        );
        try failNamedForTest(transaction, .after_accumulator_preparation);
        try materializeNamedAccumulator(Authority, transaction, lhs_index, session, bits);
        try failNamedForTest(transaction, .after_second_operand_staging);
        try selector_state.emitBinaryArgAccumulator(transaction.selector, op, .rcx, bits);
        try failNamedForTest(transaction, .after_first_arithmetic_write);
        return finishNamedResult(Authority, transaction, lhs_index, session, action.result, bits);
    }

    if (locIsAccumulator(rhs)) {
        if (isCommutative(op)) {
            const session = try beginNamedAccumulatorSession(Authority, transaction);
            try prepareNamedAccumulator(
                Authority,
                transaction,
                rhs_index,
                session,
                try displacementForPlan(Authority, transaction, rhs_index, .b07_general_binary),
            );
            try failNamedForTest(transaction, .after_accumulator_preparation);
            try materializeNamedAccumulator(Authority, transaction, rhs_index, session, bits);
            try failNamedForTest(transaction, .after_second_operand_staging);
            try refreshNamedSource(Authority, transaction, lhs_index);
            const current_lhs = transaction.prepared_views[lhs_index].canonical_source_loc;
            try selector_state.emitBinaryLocIntoAccumulator(transaction.selector, op, current_lhs, bits);
            try failNamedForTest(transaction, .after_first_arithmetic_write);
            return finishNamedResult(Authority, transaction, lhs_index, session, action.result, bits);
        }

        const rhs_scratch: ArgReg = switch (lhs) {
            .arg32, .arg64, .scratch32, .scratch64 => |reg| if (reg == .rcx) .rdx else .rcx,
            .eax, .rax => unreachable,
            else => .rcx,
        };
        try stageNamedSource(Authority, transaction, rhs_index, rhs_scratch, bits);
        try failNamedForTest(transaction, .after_first_operand_staging);
        const session = try beginNamedAccumulatorSession(Authority, transaction);
        try prepareNamedAccumulator(
            Authority,
            transaction,
            lhs_index,
            session,
            try displacementForPlan(Authority, transaction, lhs_index, .b07_general_binary),
        );
        try failNamedForTest(transaction, .after_accumulator_preparation);
        try materializeNamedAccumulator(Authority, transaction, lhs_index, session, bits);
        try failNamedForTest(transaction, .after_second_operand_staging);
        try selector_state.emitBinaryArgAccumulator(transaction.selector, op, rhs_scratch, bits);
        try failNamedForTest(transaction, .after_first_arithmetic_write);
        return finishNamedResult(Authority, transaction, lhs_index, session, action.result, bits);
    }

    const session = try beginNamedAccumulatorSession(Authority, transaction);
    try prepareNamedAccumulator(
        Authority,
        transaction,
        lhs_index,
        session,
        try displacementForPlan(Authority, transaction, lhs_index, .b07_general_binary),
    );
    try failNamedForTest(transaction, .after_accumulator_preparation);
    try materializeNamedAccumulator(Authority, transaction, lhs_index, session, bits);
    try failNamedForTest(transaction, .after_second_operand_staging);
    try refreshNamedSource(Authority, transaction, rhs_index);
    const current_rhs = transaction.prepared_views[rhs_index].canonical_source_loc;
    const rhs_reg: ArgReg = switch (current_rhs) {
        .arg32, .scratch32 => |reg| if (bits <= 32)
            reg
        else
            return namedRequestError(
                Authority,
                transaction,
                rhs_index,
                error.ValueUseNamedScalarWidthUnsupported,
            ),
        .arg64, .scratch64 => |reg| if (bits == 64 or bits > 32)
            reg
        else
            return namedRequestError(
                Authority,
                transaction,
                rhs_index,
                error.ValueUseNamedScalarWidthUnsupported,
            ),
        .spill64 => |frame_index| blk: {
            try selector_state.clobberArgReg(transaction.selector, .rcx);
            try transaction.selector.machine.instructions.append(
                transaction.selector.allocator,
                if (bits <= 32)
                    .{ .reload_arg_rsp = .{ .reg = .rcx, .frame_index = frame_index } }
                else
                    .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = frame_index } },
            );
            break :blk .rcx;
        },
        else => return namedRequestError(
            Authority,
            transaction,
            rhs_index,
            error.ValueUseNamedScalarLocationUnsupported,
        ),
    };
    try selector_state.emitBinaryArgAccumulator(transaction.selector, op, rhs_reg, bits);
    try failNamedForTest(transaction, .after_first_arithmetic_write);
    return finishNamedResult(Authority, transaction, lhs_index, session, action.result, bits);
}

fn classifyNamedScalar(action: *const Types.NamedScalarBinaryAction) Types.NamedScalarRequestError!NamedScalarPlan {
    const bits = integerBits(action.integer_ty) orelse
        return error.ValueUseNamedScalarWidthUnsupported;
    if (bits == 0 or bits > 64) return error.ValueUseNamedScalarWidthUnsupported;
    if (bits == 1) {
        if (action.operation != .@"and" and action.operation != .@"or")
            return error.ValueUseNamedScalarFormUnsupported;
        if (action.exact_ei) return error.ValueUseNamedScalarExactEiUnsupported;
        return .b01_boolean;
    }
    if (action.operation == .mul) {
        if (bits == 64) return error.ValueUseNamedScalarFormUnsupported;
        if (bits == 6 or bits == 7 or bits == 16 or bits == 32 or
            (action.exact_ei and bits < 32))
            return .b03_narrow_multiply;
        return error.ValueUseNamedScalarWidthUnsupported;
    }
    if (isShift(action.operation)) {
        if (bits == 16 or bits == 32 or (action.exact_ei and bits < 32))
            return .b04_narrow_shift;
        if (bits == 64 or (action.exact_ei and bits > 32))
            return .b05_wide_shift;
        return error.ValueUseNamedScalarWidthUnsupported;
    }
    if (action.exact_ei and bits > 32) {
        _ = machineBinaryOp(action.operation) orelse
            return error.ValueUseNamedScalarFormUnsupported;
        return .b06_wide_exact_binary;
    }
    _ = machineBinaryOp(action.operation) orelse
        return error.ValueUseNamedScalarFormUnsupported;
    if (bits == 4 or bits == 6 or bits == 7 or bits == 16 or bits == 23 or bits == 32 or bits == 37 or bits == 64 or
        (action.exact_ei and bits < 32))
        return .b07_general_binary;
    return error.ValueUseNamedScalarWidthUnsupported;
}

fn classifyExactI52(_: *const Types.ExactI52BinaryAction) ExactI52Plan {
    return .i52b0_guarded_shift;
}

fn displacementForPlan(
    comptime Authority: type,
    transaction: anytype,
    lhs_index: u8,
    plan: NamedScalarPlan,
) !selector_state.AccumulatorDisplacementPolicy {
    return switch (plan) {
        .b01_boolean, .b04_narrow_shift => directDisplacement(transaction, lhs_index, .spill_live),
        .b03_narrow_multiply => livenessDisplacement(
            Authority,
            transaction,
            lhs_index,
            .scratch_preferred,
        ),
        .b05_wide_shift, .b06_wide_exact_binary => preserveCurrentDisplacement(
            transaction,
            lhs_index,
            .spill_live,
        ),
        .b07_general_binary => livenessDisplacement(
            Authority,
            transaction,
            lhs_index,
            .spill_live,
        ),
    };
}

fn directDisplacement(
    transaction: anytype,
    index: u8,
    fallback: selector_state.AccumulatorDisplacementPolicy,
) selector_state.AccumulatorDisplacementPolicy {
    return switch (transaction.prepared_views[index].canonical_source_loc) {
        .eax, .rax => .{ .reuse_source = sourceNameUnchecked(transaction, index) },
        else => fallback,
    };
}

fn livenessDisplacement(
    comptime Authority: type,
    transaction: anytype,
    index: u8,
    fallback: selector_state.AccumulatorDisplacementPolicy,
) !selector_state.AccumulatorDisplacementPolicy {
    return switch (transaction.prepared_views[index].canonical_source_loc) {
        .eax, .rax => if (!try Authority.mustSurviveInstruction(Authority, transaction, index))
            .{ .reuse_source = sourceNameUnchecked(transaction, index) }
        else
            fallback,
        else => fallback,
    };
}

fn preserveCurrentDisplacement(
    transaction: anytype,
    index: u8,
    fallback: selector_state.AccumulatorDisplacementPolicy,
) !selector_state.AccumulatorDisplacementPolicy {
    if (try selector_state.liveAccumulatorName(transaction.selector)) |name|
        return .{ .spill_source = name };
    return directDisplacement(transaction, index, fallback);
}

fn beginNamedAccumulatorSession(
    comptime Authority: type,
    transaction: anytype,
) !*AccumulatorDefinitionSession {
    try composition.beginAccumulatorSessionForPreparedAction(Authority, transaction);
    return &transaction.accumulator_session.?;
}

fn prepareNamedAccumulator(
    comptime Authority: type,
    transaction: anytype,
    source_index: u8,
    session: *AccumulatorDefinitionSession,
    displacement: selector_state.AccumulatorDisplacementPolicy,
) !void {
    _ = Authority;
    _ = source_index;
    if (try session.prepare(.preserve, displacement)) |diagnostic| {
        transaction.action_diagnostic = diagnostic;
        return error.ValueUseActionDiagnostic;
    }
}

fn materializeNamedAccumulator(
    comptime Authority: type,
    transaction: anytype,
    source_index: u8,
    session: *AccumulatorDefinitionSession,
    bits: u16,
) !void {
    Authority.availabilityForConsumption(Authority, transaction, source_index) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, source_index, err);
        return err;
    };
    session.materialize(
        .{ .named = sourceNameUnchecked(transaction, source_index) },
        accumulatorDefinition(bits),
    ) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, source_index, err);
        return err;
    };
}

fn stageNamedSource(
    comptime Authority: type,
    transaction: anytype,
    index: u8,
    reg: ArgReg,
    bits: u16,
) !void {
    Authority.availabilityForConsumption(Authority, transaction, index) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, index, err);
        return err;
    };
    selector_state.emitValueIntoScratch(
        transaction.selector,
        .{ .named = sourceNameUnchecked(transaction, index) },
        reg,
        bits,
    ) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, index, err);
        return err;
    };
}

fn finishNamedResult(
    comptime Authority: type,
    transaction: anytype,
    source_index: u8,
    session: *AccumulatorDefinitionSession,
    result: Types.ActionIdentity,
    bits: u16,
) !void {
    const stored = switch (transaction.requests[source_index].prepared_action.?) {
        .named_scalar_binary => |*named| &named.result,
        .exact_i52_binary => |*named| &named.result,
        else => unreachable,
    };
    std.debug.assert(std.meta.eql(stored.*, result));
    const result_name = composition.ownActionIdentity(Authority, transaction, stored) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, source_index, err);
        return err;
    };
    try failNamedForTest(transaction, .after_result_identity_ownership);
    try session.define(result_name, accumulatorDefinition(bits));
    try failNamedForTest(transaction, .after_result_definition);
    try session.finalize();
    try failNamedForTest(transaction, .after_finalization);
}

fn refreshNamedSource(
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

fn validateNamedSource(
    comptime Authority: type,
    transaction: anytype,
    index: u8,
    bits: u16,
) !void {
    _ = try namedSource(Authority, transaction, index);
    if (!transaction.prepared_view_valid[index]) {
        Authority.recordRequestFailure(Authority, transaction, index);
        return error.ValueUsePreparedViewMissing;
    }
    const binding = transaction.prepared_views[index].source_vreg;
    const valid_class = if (bits <= 32)
        binding.class == .gpr32 or binding.class == .gpr64
    else
        binding.class == .gpr64;
    if (!valid_class or binding.bits < bits)
        return namedRequestError(Authority, transaction, index, error.ValueUseNamedScalarWidthUnsupported);
    const current = transaction.prepared_views[index].canonical_source_loc;
    const valid_home = if (bits <= 32) switch (current) {
        .eax, .rax, .arg32, .arg64, .scratch32, .scratch64, .spill64 => true,
        else => false,
    } else switch (current) {
        .rax, .arg64, .scratch64, .spill64 => true,
        else => false,
    };
    if (!valid_home)
        return namedRequestError(Authority, transaction, index, error.ValueUseNamedScalarLocationUnsupported);
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

fn sourceNameUnchecked(transaction: anytype, index: u8) []const u8 {
    return transaction.requests[index].source.named.slice();
}

fn instructionForPlan(
    plan: NamedScalarPlan,
    operation: ir.BinaryOp,
    bits: u16,
) machine_module.Instruction {
    return switch (plan) {
        .b03_narrow_multiply => .{ .imul_eax_arg32 = .rcx },
        .b04_narrow_shift => switch (operation) {
            .shl => .shl_eax_cl,
            .lshr => .shr_eax_cl,
            .ashr => .sar_eax_cl,
            else => unreachable,
        },
        .b05_wide_shift => switch (operation) {
            .shl => .shl_rax_cl,
            .lshr => .shr_rax_cl,
            .ashr => .sar_rax_cl,
            else => unreachable,
        },
        .b01_boolean, .b07_general_binary => if (bits <= 32)
            .{ .binary_arg_eax = .{ .op = machineBinaryOp(operation).?, .reg = .rcx } }
        else
            .{ .binary_arg_rax = .{ .op = machineBinaryOp(operation).?, .reg = .rcx } },
        .b06_wide_exact_binary => .{
            .binary_arg_rax = .{ .op = machineBinaryOp(operation).?, .reg = .rcx },
        },
    };
}

fn machineBinaryOp(operation: ir.BinaryOp) ?x86_64_types.MachineBinaryOp {
    return switch (operation) {
        .add => .add,
        .sub => .sub,
        .@"and" => .@"and",
        .@"or" => .@"or",
        .xor => .xor,
        else => null,
    };
}

fn emitNamedWrite(transaction: anytype, instruction: machine_module.Instruction) !void {
    try selector_state.emitEflagsInstruction(transaction.selector, instruction, .write);
}

fn accumulatorDefinition(bits: u16) AccumulatorDefinition {
    return if (bits <= 32)
        .zeroExtending(bits)
    else if (bits == 64)
        .fullRax()
    else
        .zeroExtendedRax(bits);
}

fn namedRequestError(
    comptime Authority: type,
    transaction: anytype,
    index: u8,
    err: Types.NamedScalarRequestError,
) Types.NamedScalarRequestError {
    Authority.noteRequestBoundaryError(Authority, transaction, index, err);
    return err;
}

fn integerBits(ty: ir.Type) ?u16 {
    return switch (ty) {
        .int => |bits| bits,
        else => null,
    };
}

fn isShift(operation: ir.BinaryOp) bool {
    return operation == .shl or operation == .lshr or operation == .ashr;
}

fn locIsAccumulator(loc: ValueLoc) bool {
    return loc == .eax or loc == .rax;
}

fn isCommutative(operation: x86_64_types.MachineBinaryOp) bool {
    return operation == .add or operation == .@"and" or
        operation == .@"or" or operation == .xor;
}

fn failNamedForTest(transaction: anytype, boundary: Types.NamedScalarTestFailure) !void {
    if (builtin.is_test and transaction.named_scalar_test_failure == boundary)
        return error.ValueUseNamedScalarTestFailure;
}

fn isExactI52ShiftCount(body: ir.Function, count_name: []const u8) bool {
    const widened = instructionByResult(body, count_name) orelse return false;
    const zext = switch (widened.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 6 }) or
        !zext.to_ty.eql(.{ .int = 52 }) or zext.value != .named)
        return false;
    const added = instructionByResult(body, zext.value.named) orelse return false;
    const add = switch (added.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.flags.nuw or !add.ty.eql(.{ .int = 6 }) or
        add.lhs != .named or !add.rhs.eql(.{ .int = 1 }))
        return false;
    const narrowed = instructionByResult(body, add.lhs.named) orelse return false;
    const trunc = switch (narrowed.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (trunc.op != .trunc or !trunc.from_ty.eql(.{ .int = 52 }) or
        !trunc.to_ty.eql(.{ .int = 6 }) or trunc.value != .named)
        return false;
    const counted = instructionByResult(body, trunc.value.named) orelse return false;
    const call = switch (counted.kind) {
        .call => |call| call,
        else => return false,
    };
    return isExactCtlzI52Envelope(call);
}

fn isExactCtlzI52Envelope(call: ir.CallInst) bool {
    if (!std.mem.eql(u8, call.callee, "llvm.ctlz.i52") or call.inline_asm != null or
        call.callee_value != null or call.callee_function_ty != null or
        call.calling_conv != null or call.raw_args != null or
        call.operand_bundle != null or !call.ret_ty.eql(.{ .int = 52 }) or
        call.args.items.len != 2)
        return false;
    if (call.tail_kind) |tail_kind| if (!std.mem.eql(u8, tail_kind, "tail")) return false;
    if (call.attrs) |attrs| {
        const trimmed = std.mem.trim(u8, attrs, " \t");
        if (trimmed.len < 2 or trimmed[0] != '#') return false;
        for (trimmed[1..]) |c| if (!std.ascii.isDigit(c)) return false;
    }
    const ret_attrs = std.mem.trim(u8, call.ret_attrs orelse return false, " \t");
    return std.mem.eql(u8, ret_attrs, "range(i52 0, 53)") and
        call.args.items[0].attrs == null and call.args.items[1].attrs == null and
        call.args.items[0].ty.eql(.{ .int = 52 }) and
        call.args.items[1].ty.eql(.{ .int = 1 }) and
        call.args.items[1].value.eql(.{ .int = 1 });
}

fn instructionByResult(body: ir.Function, name: []const u8) ?ir.Instruction {
    for (body.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            if (instruction.result) |result|
                if (std.mem.eql(u8, result, name)) return instruction;
        }
    }
    return null;
}
