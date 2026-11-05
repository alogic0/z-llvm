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
    r00_signed_divide_by_power_of_two,
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

const ImmediateAccumulatorPreamble = enum {
    none,
    scratch_preferred,
    spill_source,
};

const ImmediateDisplacementAuthority = enum {
    none,
    liveness_aware,
    inclusive_preserve_current,
    hardcoded,
};

const isPositivePowerOfTwoDivisor = @import("../../composed_helpers.zig").isPositivePowerOfTwoDivisor;

pub fn isImmediateRhsScalar(binary: ir.BinaryInst) bool {
    if (binary.lhs != .named or binary.rhs != .int) return false;
    const bits = integerBits(binary.ty) orelse return false;
    if (bits == 0 or bits > 64) return false;
    const literal = binary.rhs.int;
    return switch (binary.op) {
        .sdiv => bits == 32 and isPositivePowerOfTwoDivisor(literal),
        .lshr => bits <= 32 or bits == 64,
        .shl, .ashr => bits <= 32 or bits == 64,
        .@"and", .@"or", .add, .sub, .xor => bits <= 64,
        .mul => bits <= 64,
        else => false,
    };
}

pub fn isImmediateLhsScalar(binary: ir.BinaryInst) bool {
    if (binary.lhs != .int or binary.rhs != .named) return false;
    const bits = integerBits(binary.ty) orelse return false;
    if (bits == 0 or bits > 64) return false;
    return switch (binary.op) {
        .sub => bits <= 32 or bits == 64,
        .shl => bits == 16 or bits == 32 or bits == 64,
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
    try preserveImmediateUnrelatedAccumulator(
        Authority,
        transaction,
        source_index,
        source_name,
        immediateAccumulatorPreamble(semantic_plan, bits),
    );

    switch (semantic_plan) {
        .r00_signed_divide_by_power_of_two => try executeImmediateR00(
            Authority,
            transaction,
            source_index,
            source_name,
            action,
            semantic_plan,
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
            semantic_plan,
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
            semantic_plan,
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
            semantic_plan,
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
            try emitImmediateWrite(
                transaction,
                if (bits <= 32) .shl_eax_cl else .shl_rax_cl,
            );
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
        .sdiv => if (bits == 32 and isPositivePowerOfTwoDivisor(action.literal))
            .r00_signed_divide_by_power_of_two
        else
            error.ValueUseImmediateScalarFormUnsupported,
        .lshr => if (bits <= 32 or bits == 64)
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
        else if (action.operation == .sub)
            if (fitsI32(action.literal))
                .r06_wide_scratch_immediate
            else
                error.ValueUseImmediateScalarLiteralOutOfRange
        else if (action.operation == .add and fitsI32(action.literal))
            .r06_wide_scratch_immediate
        else
            .r05_wide_accumulator_immediate,
        .mul => if (bits <= 64)
            .r04_narrow_accumulator_immediate
        else
            error.ValueUseImmediateScalarWidthUnsupported,
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
        .shl => if (bits == 16 or bits == 32 or bits == 64)
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

fn immediateAccumulatorPreamble(
    plan: ImmediateScalarPlan,
    bits: u16,
) ImmediateAccumulatorPreamble {
    return switch (plan) {
        .r02_shift_left_accumulator => if (bits <= 32) .scratch_preferred else .spill_source,
        .r03_arithmetic_shift_right_accumulator,
        .r04_narrow_accumulator_immediate,
        => .scratch_preferred,
        .r05_wide_accumulator_immediate => .spill_source,
        .r00_signed_divide_by_power_of_two,
        .r01_logical_shift_right_scratch,
        .r01_logical_shift_right_accumulator,
        .r02_shift_left_scratch32_writeback,
        .r03_arithmetic_shift_right_scratch64,
        .r06_wide_scratch_immediate,
        .l01_reverse_subtract,
        .l02_variable_shift_left,
        .l03_variable_logical_shift_right,
        => .none,
    };
}

fn preserveImmediateUnrelatedAccumulator(
    comptime Authority: type,
    transaction: anytype,
    source_index: u8,
    source_name: []const u8,
    preamble: ImmediateAccumulatorPreamble,
) !void {
    if (preamble == .none) return;
    const flags_before = transaction.selector.eflags.snapshot();
    const semantic_records_before = transaction.selector.eflags_semantics.items.len;
    const live_name = try Authority.occupantNeedsPreservation(
        Authority,
        transaction,
        .accumulator,
        source_index,
    ) orelse return;
    var preserve_name = switch (preamble) {
        .scratch_preferred => live_name,
        .spill_source => switch (transaction.selector.values.get(source_name).?.loc) {
            .eax, .rax => source_name,
            else => live_name,
        },
        .none => unreachable,
    };
    // A narrow alias does not describe the full physical value. Preserve a
    // RAX binding whenever one shares this home, so a later 64-bit spill or
    // use cannot observe truncated bits or an unwritten half of a stack slot.
    var aliases = transaction.selector.values.iterator();
    while (aliases.next()) |entry| {
        if (entry.value_ptr.loc == .rax) {
            preserve_name = entry.key_ptr.*;
            break;
        }
    }
    switch (preamble) {
        .scratch_preferred => {
            if (try selector_state.preserveLiveAccumulatorValue(
                transaction.selector,
                preserve_name,
            )) |diagnostic| {
                transaction.action_diagnostic = diagnostic;
                return error.ValueUseActionDiagnostic;
            }
        },
        .spill_source => {
            if (try selector_state.spillValue(
                transaction.selector,
                preserve_name,
            )) |diagnostic| {
                transaction.action_diagnostic = diagnostic;
                return error.ValueUseActionDiagnostic;
            }
        },
        .none => unreachable,
    }
    const preserved_loc = transaction.selector.values.get(preserve_name).?.loc;

    // EAX and RAX are one physical value. Move it once, then update every
    // logical alias of that physical home—including the semantic source—so
    // later materialization re-resolves the canonical preserved home.
    while (true) {
        var alias_name: ?[]const u8 = null;
        var iterator = transaction.selector.values.iterator();
        while (iterator.next()) |entry| {
            if (std.mem.eql(u8, entry.key_ptr.*, preserve_name)) continue;
            switch (entry.value_ptr.loc) {
                .eax, .rax => {
                    alias_name = entry.key_ptr.*;
                    break;
                },
                else => {},
            }
        }
        const name = alias_name orelse break;
        const alias_loc: selector_types.ValueLoc = if (transaction.selector.values.get(name).?.loc == .eax and
            preserved_loc == .scratch64)
            .{ .scratch32 = preserved_loc.scratch64 }
        else
            preserved_loc;
        try selector_state.bindValueLoc(transaction.selector, name, alias_loc);
    }
    try failImmediateScalarForTest(transaction, .after_preservation);
    try refreshImmediateScalarSource(Authority, transaction, source_index);
    try validateImmediateScalarSource(Authority, transaction, source_index, switch (transaction.requests[source_index].expected.ty) {
        .int => |bits| bits,
        else => unreachable,
    });
    try failImmediateScalarForTest(transaction, .after_canonical_refresh);
    try transaction.selector.eflags.validateSnapshot(flags_before);
    if (transaction.selector.eflags_semantics.items.len != semantic_records_before)
        return error.EflagsImmediateScalarPreambleChanged;
}

fn executeImmediateR00(
    comptime Authority: type,
    transaction: anytype,
    source_index: u8,
    source_name: []const u8,
    action: *const Types.ImmediateRhsScalarAction,
    plan: ImmediateScalarPlan,
) !void {
    selector_state.clobberArgReg(transaction.selector, .rcx) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, source_index, err);
        return err;
    };
    const session = try beginImmediateAccumulatorSession(Authority, transaction);
    if (try session.prepare(
        .preserve,
        try immediateSourceDisplacement(
            Authority,
            transaction,
            source_index,
            plan,
            32,
            .scratch_preferred,
        ),
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
    // Truncation toward zero needs a bias of divisor-1 for negative inputs.
    // Keep the divide-by-two stream unchanged for existing canary identities.
    const shift: u5 = @intCast(@ctz(@as(u32, @intCast(action.literal))));
    if (shift > 1) try emitImmediateWrite(transaction, .{ .sar_eax_imm5 = 31 });
    try emitImmediateWrite(transaction, .{ .shr_eax_imm5 = @intCast(@as(u6, 32) - shift) });
    try failImmediateScalarForTest(transaction, .after_second_instruction);
    try emitImmediateWrite(transaction, .add_ecx_eax);
    try failImmediateScalarForTest(transaction, .after_third_instruction);
    try emitImmediateWrite(transaction, .{ .sar_eax_imm5 = shift });
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
    plan: ImmediateScalarPlan,
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
        try immediateSourceDisplacement(
            Authority,
            transaction,
            source_index,
            plan,
            bits,
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
    plan: ImmediateScalarPlan,
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
        try immediateSourceDisplacement(
            Authority,
            transaction,
            source_index,
            plan,
            bits,
            .spill_live,
        ),
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
    plan: ImmediateScalarPlan,
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
        try immediateSourceDisplacement(
            Authority,
            transaction,
            source_index,
            plan,
            bits,
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
            .mul => try emitImmediateWrite(transaction, .{ .imul_eax_imm32 = literal }),
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
        if (action.operation == .mul) {
            try emitImmediateWrite(transaction, .{ .imul_rax_arg64 = .rcx });
        } else {
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
        }
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
    Authority.availabilityForConsumption(
        Authority,
        transaction,
        source_index,
    ) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, source_index, err);
        return err;
    };
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
    Authority.availabilityForConsumption(
        Authority,
        transaction,
        source_index,
    ) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, source_index, err);
        return err;
    };
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

fn immediateDisplacementAuthority(
    plan: ImmediateScalarPlan,
    bits: u16,
) ImmediateDisplacementAuthority {
    return switch (plan) {
        .r00_signed_divide_by_power_of_two,
        .r03_arithmetic_shift_right_accumulator,
        .r04_narrow_accumulator_immediate,
        => .liveness_aware,
        .r02_shift_left_accumulator => if (bits <= 32)
            .liveness_aware
        else
            .inclusive_preserve_current,
        .r05_wide_accumulator_immediate => .inclusive_preserve_current,
        .r01_logical_shift_right_accumulator,
        .l01_reverse_subtract,
        .l02_variable_shift_left,
        .l03_variable_logical_shift_right,
        => .hardcoded,
        .r01_logical_shift_right_scratch,
        .r02_shift_left_scratch32_writeback,
        .r03_arithmetic_shift_right_scratch64,
        .r06_wide_scratch_immediate,
        => .none,
    };
}

fn immediateSourceDisplacement(
    comptime Authority: type,
    transaction: anytype,
    source_index: u8,
    plan: ImmediateScalarPlan,
    bits: u16,
    fallback: AccumulatorDisplacementPolicy,
) !AccumulatorDisplacementPolicy {
    const identity = switch (transaction.requests[source_index].source) {
        .named => |*name| name.slice(),
        else => return fallback,
    };
    const current = transaction.prepared_views[source_index].canonical_source_loc;
    return switch (immediateDisplacementAuthority(plan, bits)) {
        .liveness_aware => switch (current) {
            .eax, .rax => if (!try Authority.mustSurviveInstruction(
                Authority,
                transaction,
                source_index,
            ))
                .{ .reuse_source = identity }
            else
                fallback,
            else => fallback,
        },
        .inclusive_preserve_current => switch (current) {
            .eax, .rax => .{ .spill_source = identity },
            else => fallback,
        },
        .hardcoded, .none => fallback,
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
    else if (bits == 64)
        .fullRax()
    else
        .zeroExtendedRax(bits);
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
    if (fitsI32(literal)) return @intCast(literal);
    if (literal > std.math.maxInt(i32) and literal <= std.math.maxInt(u32))
        return @bitCast(@as(u32, @intCast(literal)));
    return error.ValueUseImmediateScalarLiteralOutOfRange;
}

fn immediateI64(literal: i128) Types.ImmediateScalarRequestError!i64 {
    if (literal >= std.math.minInt(i64) and literal <= std.math.maxInt(i64))
        return @intCast(literal);
    if (literal > std.math.maxInt(i64) and literal <= std.math.maxInt(u64))
        return @bitCast(@as(u64, @intCast(literal)));
    return error.ValueUseImmediateScalarLiteralOutOfRange;
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
