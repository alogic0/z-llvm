const std = @import("std");
const selector_types = @import("../../selector_types.zig");
const selector_state = @import("../../composed_selector_state.zig");
const Types = @import("../model.zig");
const planning_model = @import("model.zig");
const compatibility = @import("compatibility.zig");

const ValueLoc = selector_types.ValueLoc;
const StoredRequest = Types.StoredRequest;
const PhysicalNode = planning_model.PhysicalNode;
pub fn validateRequestAt(comptime Authority: type, transaction: anytype, index: u8) !?ValueLoc {
    return validateRequest(Authority, transaction, index, &transaction.requests[index]) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, index, err);
        return err;
    };
}
pub fn validateRequest(
    comptime Authority: type,
    transaction: anytype,
    index: u8,
    request: *const StoredRequest,
) !?ValueLoc {
    try validateFormAndDestination(request);
    switch (request.source) {
        .unsupported => return error.ValueUseUnsupportedSource,
        .int => |value| {
            const action = request.prepared_action orelse return error.ValueUseUnsupportedSource;
            if (request.form == .switch_condition and action == .switch_compare_chain) {
                try compatibility.validateExpectedType(request.expected, request.form);
                _ = std.math.cast(i32, value) orelse return error.ValueUseSwitchImmediateOutOfRange;
                return null;
            }
            if (request.form == .accumulator_scalar_cast_operand and
                action == .accumulator_scalar_cast)
            {
                try compatibility.validateExpectedType(request.expected, request.form);
                if (action.accumulator_scalar_cast.immediate == null or
                    action.accumulator_scalar_cast.immediate.? != value)
                {
                    return error.ValueUseScalarCastImmediateMismatch;
                }
                return null;
            }
            return error.ValueUseUnsupportedSource;
        },
        .null_value => {
            if (request.form != .pointer or request.expected.ty != .ptr or
                (request.expected.register_class != .gpr64 and request.expected.register_class != .stack_pointer) or
                request.expected.pointer_address_space == null or request.expected.pointer_address_space.? != 0)
            {
                return error.ValueUseUntypedNullPointer;
            }
            if (request.destination == .prepared_source or request.destination == .prepared_view)
                return error.ValueUsePreparedViewUnsupported;
            return null;
        },
        .named => |*name| {
            try Authority.availabilityForConsumption(Authority, transaction, index);
            const binding = transaction.selector.values.get(name.slice()) orelse return error.ValueUseUnresolvedSource;
            const current = try Authority.materialization.resolveNamedCurrent(Authority, transaction, name.slice());
            try compatibility.validateBindingCompatibility(binding, request, current);
            try compatibility.validateSourceView(current, request.form);
            return current;
        },
    }
}
pub fn validateDeferredSwitchRequest(request: *const Types.StoredRequest) !void {
    try validateFormAndDestination(request);
    if (request.form != .switch_condition or request.destination != .prepared_view or
        request.prepared_action == null or request.prepared_action.? != .switch_compare_chain)
    {
        return error.ValueUsePreparedActionFormMismatch;
    }
    try compatibility.validateExpectedType(request.expected, .switch_condition);
    switch (request.source) {
        .named => {},
        .int => |integer| {
            _ = std.math.cast(i32, integer) orelse return error.ValueUseSwitchImmediateOutOfRange;
        },
        .null_value, .unsupported => return error.ValueUseUnsupportedSource,
    }
}
pub fn validateFormAndDestination(request: *const Types.StoredRequest) !void {
    if (request.destination == .prepared_source) {
        if (request.prepared_action != null) return error.ValueUsePreparedActionUnexpected;
        return switch (request.form) {
            .gpr32,
            .gpr64,
            .pointer,
            .stack_object_address,
            .pair_low_high,
            .pair_high_low,
            .memcpy_pointer,
            .memcpy_length,
            .scratch_compare_operand,
            .named_scalar_operand,
            => {},
            .stack_f32_pair_byte_address,
            .branch_condition,
            .switch_condition,
            .load_address,
            .current_home_eq_zero_operand,
            .setcc_eax_compare_operand,
            .current_home_sign_bit_operand,
            .i128_icmp_pair_operand,
            .pair_low_scalar_cast_operand,
            .accumulator_scalar_cast_operand,
            .sign_extend_scratch_operand,
            .immediate_rhs_scalar_operand,
            .immediate_lhs_scalar_operand,
            => error.ValueUsePreparedActionRequired,
            .stack_argument => error.ValueUseStackArgumentUnsupported,
            .new_pair_ownership => error.ValueUseNewPairOwnershipUnsupported,
        };
    }
    if (request.destination == .prepared_view) {
        const action = request.prepared_action orelse return error.ValueUsePreparedActionMissing;
        switch (request.form) {
            .gpr32,
            .gpr64,
            .pointer,
            .stack_f32_pair_byte_address,
            .stack_object_address,
            .pair_low_high,
            .pair_high_low,
            .branch_condition,
            .switch_condition,
            .memcpy_pointer,
            .memcpy_length,
            .load_address,
            .scratch_compare_operand,
            .current_home_eq_zero_operand,
            .setcc_eax_compare_operand,
            .current_home_sign_bit_operand,
            .i128_icmp_pair_operand,
            .pair_low_scalar_cast_operand,
            .accumulator_scalar_cast_operand,
            .sign_extend_scratch_operand,
            .immediate_rhs_scalar_operand,
            .immediate_lhs_scalar_operand,
            .named_scalar_operand,
            => {},
            .stack_argument => return error.ValueUseStackArgumentUnsupported,
            .new_pair_ownership => return error.ValueUseNewPairOwnershipUnsupported,
        }
        return switch (action) {
            .validate_shape => if (request.form == .stack_f32_pair_byte_address)
                error.ValueUsePreparedActionFormMismatch,
            .emit_copy_to => |destination| compatibility.validateCopyActionForm(request.form, destination),
            .form_byte_address => if (request.form != .pointer and request.form != .stack_f32_pair_byte_address)
                error.ValueUsePreparedActionFormMismatch,
            .form_scaled_address => if (request.form != .pointer and request.form != .stack_object_address)
                error.ValueUsePreparedActionFormMismatch,
            .form_readonly_table_address => if (request.form != .gpr64)
                error.ValueUsePreparedActionFormMismatch,
            .store_scalar => |store| if (request.form != .gpr32 or
                request.expected.ty != .int or request.expected.ty.int != store.bits)
                error.ValueUsePreparedActionFormMismatch,
            .store_immediate => if (request.form != .pointer and request.form != .stack_object_address)
                error.ValueUsePreparedActionFormMismatch,
            .store_i64 => if (request.form != .pointer or request.expected.ty != .ptr)
                error.ValueUsePreparedActionFormMismatch,
            .store_stack_pointer => if (request.form != .stack_object_address or
                request.expected.ty != .ptr or request.expected.register_class != .stack_object)
                error.ValueUsePreparedActionFormMismatch,
            .branch_condition => if (request.form != .branch_condition)
                error.ValueUsePreparedActionFormMismatch,
            .switch_compare_chain => if (request.form != .switch_condition)
                error.ValueUsePreparedActionFormMismatch,
            .inline_memcpy => if (request.form != .memcpy_pointer or
                request.expected.ty != .ptr or request.expected.register_class != .gpr64)
                error.ValueUsePreparedActionFormMismatch,
            .load_scalar,
            .load_readonly_pair,
            .load_stack_i128_alias,
            .load_readonly_table_i16,
            => if (request.form != .load_address or request.expected.ty != .ptr or
                request.expected.register_class != .stack_pointer or
                request.expected.pointer_address_space != 0)
                error.ValueUsePreparedActionFormMismatch,
            .scratch_compare => |compare| if (request.form != .scratch_compare_operand or
                !request.expected.ty.eql(compare.operand_ty))
                error.ValueUsePreparedActionFormMismatch,
            .current_home_eq_zero => |compare| if (request.form != .current_home_eq_zero_operand or
                !request.expected.ty.eql(compare.operand_ty))
                error.ValueUsePreparedActionFormMismatch,
            .setcc_eax_compare => |compare| if (request.form != .setcc_eax_compare_operand or
                !request.expected.ty.eql(compare.operand_ty))
                error.ValueUsePreparedActionFormMismatch,
            .current_home_sign_bit => |compare| if (request.form != .current_home_sign_bit_operand or
                !request.expected.ty.eql(compare.operand_ty))
                error.ValueUsePreparedActionFormMismatch,
            .i128_eq_min, .i128_sign_bit => if (request.form != .i128_icmp_pair_operand or
                !request.expected.ty.eql(.{ .int = 128 }) or
                request.expected.register_class != .gpr128)
                error.ValueUsePreparedActionFormMismatch,
            .pair_low_scalar_cast => |cast| if (request.form != .pair_low_scalar_cast_operand or
                !request.expected.ty.eql(.{ .int = cast.from_bits }) or
                request.expected.register_class != .gpr128)
                error.ValueUsePreparedActionFormMismatch,
            .accumulator_scalar_cast => |cast| if (request.form != .accumulator_scalar_cast_operand or
                !request.expected.ty.eql(.{ .int = cast.from_bits }))
                error.ValueUsePreparedActionFormMismatch,
            .sign_extend_scratch => if (request.form != .sign_extend_scratch_operand or
                !request.expected.ty.eql(.{ .int = 32 }) or
                request.expected.register_class != .gpr32)
                error.ValueUsePreparedActionFormMismatch,
            .immediate_rhs_scalar => |immediate| if (request.form != .immediate_rhs_scalar_operand or
                !request.expected.ty.eql(immediate.integer_ty))
                error.ValueUsePreparedActionFormMismatch,
            .immediate_lhs_scalar => |immediate| if (request.form != .immediate_lhs_scalar_operand or
                !request.expected.ty.eql(immediate.integer_ty))
                error.ValueUsePreparedActionFormMismatch,
            .named_scalar_binary => |named| if (request.form != .named_scalar_operand or
                !request.expected.ty.eql(named.integer_ty))
                error.ValueUsePreparedActionFormMismatch,
            .exact_i52_binary => if (request.form != .named_scalar_operand or
                !request.expected.ty.eql(.{ .int = 52 }))
                error.ValueUsePreparedActionFormMismatch,
        };
    }
    if (request.prepared_action != null) return error.ValueUsePreparedActionUnexpected;
    const valid = switch (request.form) {
        .gpr32 => request.destination == .gpr32 or request.destination == .eax,
        .gpr64 => request.destination == .gpr64 or request.destination == .rax,
        .pointer, .stack_object_address => request.destination == .gpr64 or request.destination == .rax,
        .stack_f32_pair_byte_address,
        .branch_condition,
        .switch_condition,
        .memcpy_pointer,
        .memcpy_length,
        .load_address,
        .scratch_compare_operand,
        .current_home_eq_zero_operand,
        .setcc_eax_compare_operand,
        .current_home_sign_bit_operand,
        .i128_icmp_pair_operand,
        .pair_low_scalar_cast_operand,
        .accumulator_scalar_cast_operand,
        .sign_extend_scratch_operand,
        .immediate_rhs_scalar_operand,
        .immediate_lhs_scalar_operand,
        .named_scalar_operand,
        => false,
        .pair_low_high, .pair_high_low => request.destination == .pair,
        .stack_argument => return error.ValueUseStackArgumentUnsupported,
        .new_pair_ownership => return error.ValueUseNewPairOwnershipUnsupported,
    };
    if (!valid) return error.ValueUseDestinationFormMismatch;
}
pub fn core_availabilityForConsumption(
    comptime _: type,
    transaction: anytype,
    index: u8,
) !void {
    const request = &transaction.requests[index];
    const identity = switch (request.source) {
        .named => |*name| name,
        // Typed literals and typed null pointers have no binding lifetime.
        .int, .null_value => return,
        .unsupported => return,
    };
    const binding = transaction.selector.values.get(identity.slice()) orelse
        return error.ValueUseUnresolvedSource;
    const plan = transaction.selector.allocation_plan orelse
        return error.ValueUseSourcePlanMissing;
    _ = plan.intervalEnd(identity.slice()) orelse
        return error.ValueUseSourceIntervalMissing;
    try selector_state.validateAddressDependenciesForUse(
        transaction.selector,
        identity.slice(),
    );
    if (!try selector_state.valueIsLiveAtOrAfterCurrent(
        transaction.selector,
        identity.slice(),
    )) return error.ValueUseExpiredSource;

    if (transaction.lifetime_context.pins[index]) |*pin| {
        if (!pin.identity.eql(identity) or pin.generation != binding.vreg.index)
            return error.ValueUseSourceGenerationChanged;
    } else {
        transaction.lifetime_context.pins[index] = .{
            .identity = identity.*,
            .generation = binding.vreg.index,
        };
    }
}
pub fn core_mustSurviveInstruction(
    comptime Authority: type,
    transaction: anytype,
    index: u8,
) !bool {
    try core_availabilityForConsumption(Authority, transaction, index);
    const identity = switch (transaction.requests[index].source) {
        .named => |*name| name.slice(),
        .int, .null_value => return false,
        .unsupported => return error.ValueUseUnsupportedSource,
    };
    return selector_state.valueIsLiveAfterCurrent(transaction.selector, identity);
}
pub fn core_occupantNeedsPreservation(
    comptime _: type,
    transaction: anytype,
    destination: PhysicalNode,
    source_index: u8,
) !?[]const u8 {
    const source_name = switch (transaction.requests[source_index].source) {
        .named => |*name| name.slice(),
        .int, .null_value, .unsupported => null,
    };
    const plan = transaction.selector.allocation_plan orelse
        return error.ValueUseSourcePlanMissing;
    var iterator = transaction.selector.values.iterator();
    while (iterator.next()) |entry| {
        if (source_name) |name| {
            if (std.mem.eql(u8, entry.key_ptr.*, name)) continue;
        }
        if (PhysicalNode.scalarSource(entry.value_ptr.loc) != destination) continue;
        _ = plan.intervalEnd(entry.key_ptr.*) orelse
            return error.ValueUseSourceIntervalMissing;
        try selector_state.validateAddressDependenciesForUse(
            transaction.selector,
            entry.key_ptr.*,
        );
        if (try selector_state.valueIsLiveAfterCurrent(
            transaction.selector,
            entry.key_ptr.*,
        )) return entry.key_ptr.*;
    }
    return null;
}
