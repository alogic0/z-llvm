const std = @import("std");
const builtin = @import("builtin");
const ir = @import("../../../../ir.zig");
const x86_64_machine = @import("../../machine.zig");
const x86_64_types = @import("../../types.zig");
const selector_types = @import("../selector_types.zig");
const state_data = @import("../composed_selector_state_data.zig");
const selector_state = @import("../composed_selector_state.zig");
const stage2_planning = @import("../stage2_planning.zig");
const address_dependencies = @import("../composed_selector_address_dependencies.zig");
const eflags = @import("../composed_selector_eflags.zig");
const constant_table = @import("../../constant_table.zig");
const aggregate_object = @import("../aggregate_object.zig");
const composed_helpers = @import("../composed_helpers.zig");
const Diagnostic = @import("../inspection.zig").Diagnostic;

const ArgReg = x86_64_types.ArgReg;
const FrameIndex = x86_64_types.FrameIndex;
const RegPair = selector_types.RegPair;
const ValueBinding = selector_types.ValueBinding;
const ValueLoc = selector_types.ValueLoc;
const VirtualReg = selector_types.VirtualReg;
const VirtualRegClass = selector_types.VirtualRegClass;
const ComposedBlockSelector = state_data.ComposedBlockSelector;
const AddressDependencyDomain = address_dependencies.AddressDependencyDomain;
const AccumulatorDefinition = selector_state.AccumulatorDefinition;
const AccumulatorDefinitionSession = selector_state.AccumulatorDefinitionSession;
const AccumulatorDisplacementPolicy = selector_state.AccumulatorDisplacementPolicy;
const AccumulatorPreparationEffect = selector_state.AccumulatorPreparationEffect;
const model = @import("model.zig");
const Types = model;
const max_requests = Types.max_requests;
const max_identity_bytes = Types.max_identity_bytes;
const address_domain_snapshot_copies = Types.address_domain_snapshot_copies;
const address_domain_copies_per_request = Types.address_domain_copies_per_request;
const address_domain_snapshot_bytes = Types.address_domain_snapshot_bytes;
const Expected = Types.Expected;
const UseForm = Types.UseForm;
const Destination = Types.Destination;
const RequestHandle = Types.RequestHandle;
const AccumulatorSessionHandle = Types.AccumulatorSessionHandle;
const PreparedViewLease = Types.PreparedViewLease;
const ActionIdentity = Types.ActionIdentity;
const AddressOffset = Types.AddressOffset;
const PreparedShape = Types.PreparedShape;
const ByteAddressAction = Types.ByteAddressAction;
const ScaledAddressAction = Types.ScaledAddressAction;
const ReadOnlyTableAddressAction = Types.ReadOnlyTableAddressAction;
const StoreScalarAction = Types.StoreScalarAction;
const StoreImmediateAction = Types.StoreImmediateAction;
const StoreI64Action = Types.StoreI64Action;
const StoreStackPointerAction = Types.StoreStackPointerAction;
const MemcpyAction = Types.MemcpyAction;
const MemcpyTestFailure = Types.MemcpyTestFailure;
const ScalarLoadKind = Types.ScalarLoadKind;
const ScalarLoadAction = Types.ScalarLoadAction;
const ReadOnlyPairLoadAction = Types.ReadOnlyPairLoadAction;
const StackI128AliasLoadAction = Types.StackI128AliasLoadAction;
const ReadOnlyTableI16LoadAction = Types.ReadOnlyTableI16LoadAction;
const LoadRequestError = Types.LoadRequestError;
const LoadTestFailure = Types.LoadTestFailure;
const ScratchCompareRhs = Types.ScratchCompareRhs;
const ScratchCompareAction = Types.ScratchCompareAction;
const ScratchCompareTestFailure = Types.ScratchCompareTestFailure;
const CurrentHomeEqZeroAction = Types.CurrentHomeEqZeroAction;
const CurrentHomeEqZeroRequestError = Types.CurrentHomeEqZeroRequestError;
const CurrentHomeEqZeroTestFailure = Types.CurrentHomeEqZeroTestFailure;
const SetccEaxCompareStructure = Types.SetccEaxCompareStructure;
const SetccEaxCompareAction = Types.SetccEaxCompareAction;
const SetccEaxCompareRequestError = Types.SetccEaxCompareRequestError;
const SetccEaxCompareTestFailure = Types.SetccEaxCompareTestFailure;
const CurrentHomeSignBitAction = Types.CurrentHomeSignBitAction;
const CurrentHomeSignBitRequestError = Types.CurrentHomeSignBitRequestError;
const CurrentHomeSignBitTestFailure = Types.CurrentHomeSignBitTestFailure;
const I128EqMinAction = Types.I128EqMinAction;
const I128SignBitAction = Types.I128SignBitAction;
const I128PairRequestError = Types.I128PairRequestError;
const I128EqMinTestFailure = Types.I128EqMinTestFailure;
const I128SignBitTestFailure = Types.I128SignBitTestFailure;
const ScalarCastTestFailure = Types.ScalarCastTestFailure;
const max_switch_cases = Types.max_switch_cases;
const SwitchCaseIntent = Types.SwitchCaseIntent;
const SwitchCompareChainAction = Types.SwitchCompareChainAction;
const PreparedAction = Types.PreparedAction;
const CopyDestination = Types.CopyDestination;
const PreparedIdentity = Types.PreparedIdentity;
const PreparedRegister = Types.PreparedRegister;
const PreparedScalarHome = Types.PreparedScalarHome;
const PreparedStackObject = Types.PreparedStackObject;
const PreparedAddressComponent = Types.PreparedAddressComponent;
const PreparedAddressDescriptor = Types.PreparedAddressDescriptor;
const PreparedStackF32PairAddress = Types.PreparedStackF32PairAddress;
const PreparedTablePointer = Types.PreparedTablePointer;
const PreparedPairLimb = Types.PreparedPairLimb;
const PreparedReadOnlyPair = Types.PreparedReadOnlyPair;
const PreparedCondition = Types.PreparedCondition;
const PreparedView = Types.PreparedView;
const PreparedRecord = Types.PreparedRecord;
const EarlyPlan = Types.EarlyPlan;
const OperandPhase = Types.OperandPhase;
const OrderedOperand = Types.OrderedOperand;
const SemanticRole = Types.SemanticRole;
const EarlyPreparedHome = Types.EarlyPreparedHome;
const Request = Types.Request;
const RequestPhase = Types.RequestPhase;
const Lifecycle = Types.Lifecycle;
const Identity = Types.Identity;
const Source = Types.Source;
const StoredRequest = Types.StoredRequest;
const PhysicalNode = Types.PhysicalNode;
const physical_node_count = Types.physical_node_count;
const max_mappings = Types.max_mappings;
const planning_module = @import("planning.zig");
const materialization_module = @import("materialization.zig");
const composition_module = @import("composition.zig");
const address_memory = @import("actions/address_memory.zig");
const control_compare_module = @import("actions/control_compare.zig");
const scalar_arithmetic_module = @import("actions/scalar_arithmetic.zig");
const calls = @import("actions/calls.zig");

const ValueEntry = struct {
    name: []const u8,
    binding: ValueBinding,
};

const SpillEntry = struct {
    name: []const u8,
    assignment: stage2_planning.SpillSlotAssignment,
};

const PhiDestinationEntry = struct {
    name: []const u8,
    loc: ValueLoc,
};

const CoreSnapshot = struct {
    instruction_len: usize,
    values: []ValueEntry,
    spill_slots: []SpillEntry,
    phi_destinations: []PhiDestinationEntry,
    next_virtual_reg: usize,
    next_spill_slot: usize,
    edge_label_count: usize,
    owned_labels_len: usize,
    stack_slot_allocated: bool,
    stack_array_allocated: bool,
    stack_array_count: usize,
    stack_frame_bytes: u32,
    expired_binding_this_position: bool,
    accumulator_domain: selector_types.AccumulatorDomain,
    address_dependencies: AddressDependencyDomain,
    eflags_snapshot: eflags.Liveness.Snapshot,
    eflags_semantics_len: usize,
    preserve_current_position_values: bool,

    fn init(selector: *ComposedBlockSelector) !CoreSnapshot {
        const values = try selector.allocator.alloc(ValueEntry, selector.values.count());
        errdefer selector.allocator.free(values);
        const spill_slots = try selector.allocator.alloc(SpillEntry, selector.spill_slots.count());
        errdefer selector.allocator.free(spill_slots);
        const phi_destinations = try selector.allocator.alloc(PhiDestinationEntry, selector.phi_destinations.count());
        errdefer selector.allocator.free(phi_destinations);

        var value_index: usize = 0;
        var value_it = selector.values.iterator();
        while (value_it.next()) |entry| : (value_index += 1) {
            values[value_index] = .{ .name = entry.key_ptr.*, .binding = entry.value_ptr.* };
        }
        var spill_index: usize = 0;
        var spill_it = selector.spill_slots.iterator();
        while (spill_it.next()) |entry| : (spill_index += 1) {
            spill_slots[spill_index] = .{ .name = entry.key_ptr.*, .assignment = entry.value_ptr.* };
        }
        var phi_index: usize = 0;
        var phi_it = selector.phi_destinations.iterator();
        while (phi_it.next()) |entry| : (phi_index += 1) {
            phi_destinations[phi_index] = .{ .name = entry.key_ptr.*, .loc = entry.value_ptr.* };
        }
        return .{
            .instruction_len = selector.machine.instructions.items.len,
            .values = values,
            .spill_slots = spill_slots,
            .phi_destinations = phi_destinations,
            .next_virtual_reg = selector.next_virtual_reg,
            .next_spill_slot = selector.next_spill_slot,
            .edge_label_count = selector.edge_label_count,
            .owned_labels_len = selector.machine.owned_labels.items.len,
            .stack_slot_allocated = selector.stack_slot_allocated,
            .stack_array_allocated = selector.stack_array_allocated,
            .stack_array_count = selector.stack_array_count,
            .stack_frame_bytes = selector.stack_frame_bytes,
            .expired_binding_this_position = selector.expired_binding_this_position,
            .accumulator_domain = selector.accumulator_domain,
            // Exactly one whole-domain copy per transaction, independent
            // of request count.
            .address_dependencies = selector.address_dependencies,
            .eflags_snapshot = selector.eflags.snapshot(),
            .eflags_semantics_len = selector.eflags_semantics.items.len,
            .preserve_current_position_values = selector.preserve_current_position_values,
        };
    }

    fn restore(snapshot: *const CoreSnapshot, selector: *ComposedBlockSelector) void {
        // Instructions must stop referring to speculative labels before
        // their owned storage is released.
        selector.machine.instructions.items.len = snapshot.instruction_len;
        std.debug.assert(selector.machine.owned_labels.items.len >= snapshot.owned_labels_len);
        for (selector.machine.owned_labels.items[snapshot.owned_labels_len..]) |label|
            selector.allocator.free(label);
        selector.machine.owned_labels.items.len = snapshot.owned_labels_len;
        selector.values.clearRetainingCapacity();
        for (snapshot.values) |entry| selector.values.putAssumeCapacity(entry.name, entry.binding);
        selector.spill_slots.clearRetainingCapacity();
        for (snapshot.spill_slots) |entry| selector.spill_slots.putAssumeCapacity(entry.name, entry.assignment);
        selector.phi_destinations.clearRetainingCapacity();
        for (snapshot.phi_destinations) |entry| selector.phi_destinations.putAssumeCapacity(entry.name, entry.loc);
        selector.next_virtual_reg = snapshot.next_virtual_reg;
        selector.next_spill_slot = snapshot.next_spill_slot;
        selector.edge_label_count = snapshot.edge_label_count;
        selector.stack_slot_allocated = snapshot.stack_slot_allocated;
        selector.stack_array_allocated = snapshot.stack_array_allocated;
        selector.stack_array_count = snapshot.stack_array_count;
        selector.stack_frame_bytes = snapshot.stack_frame_bytes;
        selector.expired_binding_this_position = snapshot.expired_binding_this_position;
        selector.accumulator_domain = snapshot.accumulator_domain;
        selector.address_dependencies = snapshot.address_dependencies;
        selector.eflags.restore(snapshot.eflags_snapshot);
        selector.eflags_semantics.items.len = snapshot.eflags_semantics_len;
        selector.preserve_current_position_values = snapshot.preserve_current_position_values;
    }

    fn deinit(snapshot: *CoreSnapshot, selector: *ComposedBlockSelector) void {
        selector.allocator.free(snapshot.phi_destinations);
        selector.allocator.free(snapshot.spill_slots);
        selector.allocator.free(snapshot.values);
    }
};

fn core_begin(comptime Transaction: type, selector: *ComposedBlockSelector) !Transaction {
    return .{ .selector = selector, .snapshot = try CoreSnapshot.init(selector) };
}
fn core_deinit(comptime Authority: type, transaction: anytype) void {
    if (transaction.lifecycle == .active) Authority.rollbackInternal(Authority, transaction);
    transaction.snapshot.deinit(transaction.selector);
}
fn core_register(comptime Authority: type, transaction: anytype, request: Request) !RequestHandle {
    try Authority.requireActive(Authority, transaction);
    if (transaction.request_phase != .registering) return error.ValueUseLateRegistration;
    if (request.prepared_action) |action| try Authority.validateActionRegistration(Authority, transaction, action);
    const stored = StoredRequest{
        .source = try Source.from(request.source),
        .expected = request.expected,
        .form = request.form,
        .destination = request.destination,
        .prepared_action = request.prepared_action,
    };
    for (transaction.requests[0..transaction.request_count], 0..) |*existing, index| {
        if (!stored.source.eql(&existing.source)) continue;
        if (!stored.expected.eql(existing.expected) or stored.form != existing.form)
            return error.ValueUseIncompatibleDuplicate;
        if (stored.destination.eql(existing.destination) and
            coreOptionalPreparedActionEql(stored.prepared_action, existing.prepared_action))
        {
            return Authority.handleFor(Authority, transaction, @intCast(index));
        }
    }
    if (transaction.request_count == max_requests) return error.ValueUseRequestCapacityExceeded;
    const index = transaction.request_count;
    transaction.requests[index] = stored;
    transaction.request_count += 1;
    return Authority.handleFor(Authority, transaction, index);
}
fn core_attachScratchCompareAction(
    comptime Authority: type,
    transaction: anytype,
    lhs: RequestHandle,
    action: ScratchCompareAction,
) !void {
    try Authority.requireActive(Authority, transaction);
    if (transaction.request_phase != .registering) return error.ValueUseLateRegistration;
    const lhs_index = try Authority.validateHandle(Authority, transaction, lhs);
    const lhs_request = &transaction.requests[lhs_index];
    if (lhs_request.destination != .prepared_view or
        lhs_request.form != .scratch_compare_operand or
        lhs_request.prepared_action != null)
    {
        return error.ValueUsePreparedActionFormMismatch;
    }
    try action.result.validate();
    _ = try control_compare_module.classifyScratchCompare(&action);
    switch (action.rhs) {
        .named => |rhs| {
            const rhs_index = try Authority.validateRegisteredOperandHandle(Authority, transaction, rhs);
            if (rhs_index <= lhs_index or
                transaction.requests[rhs_index].form != .scratch_compare_operand)
            {
                return error.ValueUseScratchCompareSourceOrder;
            }
        },
        .immediate, .null_pointer => {},
    }
    lhs_request.prepared_action = .{ .scratch_compare = action };
}
fn core_applySwitchBoundary(
    comptime Authority: type,
    transaction: anytype,
    handle: RequestHandle,
) !void {
    try Authority.requireActive(Authority, transaction);
    if (transaction.request_phase != .sealed) return error.ValueUseSwitchBoundaryPhase;
    errdefer Authority.rollbackInternal(Authority, transaction);
    const index = try Authority.validateHandle(Authority, transaction, handle);
    _ = switch (transaction.requests[index].prepared_action orelse
        return error.ValueUsePreparedActionMissing) {
        .switch_compare_chain => |action| action,
        else => return error.ValueUseSwitchBoundaryActionMismatch,
    };
    if (transaction.switch_boundary_applied[index]) return error.ValueUseSwitchBoundaryAlreadyApplied;

    if (transaction.selector.stack_frame_bytes != 0) {
        try selector_state.spillLiveValuesForCfgBoundary(transaction.selector);
    } else {
        try restoreSwitchDisplacedPhiDestinations(transaction.selector);
    }
    _ = try Authority.planning.validateRequestAt(Authority, transaction, index);
    transaction.switch_boundary_applied[index] = true;
}
fn core_preparedView(comptime Authority: type, transaction: anytype, handle: RequestHandle) !PreparedViewLease {
    try Authority.requireActive(Authority, transaction);
    if (transaction.request_phase != .materialized and transaction.request_phase != .views_exposed)
        return error.ValueUsePreparedViewUnavailable;
    errdefer Authority.rollbackInternal(Authority, transaction);
    const index = try Authority.validateHandle(Authority, transaction, handle);
    if (transaction.requests[index].destination != .prepared_view or !transaction.prepared_view_valid[index]) {
        Authority.recordRequestFailure(Authority, transaction, index);
        return error.ValueUsePreparedViewMissing;
    }
    transaction.request_phase = .views_exposed;
    return .{ .request = handle, .view_generation = transaction.view_generation };
}
fn core_executePreparedAction(comptime Authority: type, transaction: anytype, lease: PreparedViewLease) !void {
    try Authority.requireActive(Authority, transaction);
    if (lease.view_generation != transaction.view_generation)
        return error.ValueUsePreparedViewStale;
    if (transaction.request_phase != .views_exposed)
        return error.ValueUsePreparedViewUnavailable;
    errdefer Authority.rollbackInternal(Authority, transaction);
    const index = try Authority.validateHandle(Authority, transaction, lease.request);
    if (!transaction.prepared_view_valid[index]) {
        Authority.recordRequestFailure(Authority, transaction, index);
        return error.ValueUsePreparedViewMissing;
    }
    const refreshed = try Authority.materialization.buildPreparedRecord(Authority, transaction, index);
    if (!materialization_module.preparedRecordEql(&transaction.prepared_views[index], &refreshed)) {
        Authority.recordRequestFailure(Authority, transaction, index);
        return error.ValueUsePreparedViewStale;
    }
    const action = transaction.requests[index].prepared_action orelse {
        Authority.recordRequestFailure(Authority, transaction, index);
        return error.ValueUsePreparedActionMissing;
    };
    try Authority.validateActionDependenciesCanonical(Authority, transaction, action);
    executePreparedActionInternal(Authority, transaction, index, &refreshed.view, &transaction.requests[index], action) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, index, err);
        return err;
    };
    // Defense in depth: even the closed internal action must not relocate
    // or rebind its source. Any violation rolls back speculative emission.
    if (planning_module.actionOwnsOrderedWrites(action)) {
        try Authority.validateConsumedActionAfter(Authority, transaction, index, action);
    } else {
        const after_consumption = try Authority.materialization.buildPreparedRecord(Authority, transaction, index);
        if (!materialization_module.preparedRecordEql(&transaction.prepared_views[index], &after_consumption)) {
            Authority.recordRequestFailure(Authority, transaction, index);
            return error.ValueUsePreparedViewStale;
        }
        try Authority.validateActionDependenciesCanonical(Authority, transaction, action);
    }
    transaction.prepared_view_valid[index] = false;
}
fn core_commit(comptime Authority: type, transaction: anytype) !void {
    try Authority.requireActive(Authority, transaction);
    if (transaction.request_phase != .materialized and transaction.request_phase != .views_exposed)
        return error.ValueUseCommitBeforeMaterialization;
    if (transaction.accumulator_session) |*session| {
        if (!session.isFinalized()) return error.ValueUseAccumulatorResultNotFinalized;
    }
    transaction.request_phase = .committed;
    transaction.lifecycle = .committed;
}
fn core_rollback(comptime Authority: type, transaction: anytype) !void {
    try Authority.requireActive(Authority, transaction);
    Authority.rollbackInternal(Authority, transaction);
}
fn core_requestCount(comptime _: type, transaction: anytype) usize {
    return transaction.request_count;
}
fn core_phase(comptime _: type, transaction: anytype) RequestPhase {
    return transaction.request_phase;
}
fn core_actionDiagnostic(comptime _: type, transaction: anytype) ?Diagnostic {
    return transaction.action_diagnostic;
}
fn core_failedRequestIs(
    comptime _: type,
    transaction: anytype,
    handle: RequestHandle,
) bool {
    const failed = transaction.failed_request orelse return false;
    return failed.authority == @intFromPtr(transaction) and
        failed.authority == handle.authority and
        failed.index == handle.index and
        failed.generation == handle.generation;
}
fn core_setMemcpyTestFailure(
    comptime _: type,
    transaction: anytype,
    failure: ?MemcpyTestFailure,
) !void {
    if (!builtin.is_test) return error.ValueUseTestHookUnavailable;
    transaction.memcpy_test_failure = failure;
}
fn core_setLoadTestFailure(
    comptime _: type,
    transaction: anytype,
    failure: ?LoadTestFailure,
) !void {
    if (!builtin.is_test) return error.ValueUseTestHookUnavailable;
    transaction.load_test_failure = failure;
}
fn core_setScratchCompareTestFailure(
    comptime _: type,
    transaction: anytype,
    failure: ?ScratchCompareTestFailure,
) !void {
    if (!builtin.is_test) return error.ValueUseTestHookUnavailable;
    transaction.scratch_compare_test_failure = failure;
}
fn core_setCurrentHomeEqZeroTestFailure(
    comptime _: type,
    transaction: anytype,
    failure: ?CurrentHomeEqZeroTestFailure,
) !void {
    if (!builtin.is_test) return error.ValueUseTestHookUnavailable;
    transaction.current_home_eq_zero_test_failure = failure;
}
fn core_setSetccEaxCompareTestFailure(
    comptime _: type,
    transaction: anytype,
    failure: ?SetccEaxCompareTestFailure,
) !void {
    if (!builtin.is_test) return error.ValueUseTestHookUnavailable;
    transaction.setcc_eax_compare_test_failure = failure;
}
fn core_setCurrentHomeSignBitTestFailure(
    comptime _: type,
    transaction: anytype,
    failure: ?CurrentHomeSignBitTestFailure,
) !void {
    if (!builtin.is_test) return error.ValueUseTestHookUnavailable;
    transaction.current_home_sign_bit_test_failure = failure;
}
fn core_setI128EqMinTestFailure(
    comptime _: type,
    transaction: anytype,
    failure: ?I128EqMinTestFailure,
) !void {
    if (!builtin.is_test) return error.ValueUseTestHookUnavailable;
    transaction.i128_eq_min_test_failure = failure;
}
fn core_setI128SignBitTestFailure(
    comptime _: type,
    transaction: anytype,
    failure: ?I128SignBitTestFailure,
) !void {
    if (!builtin.is_test) return error.ValueUseTestHookUnavailable;
    transaction.i128_sign_bit_test_failure = failure;
}
fn core_setScalarCastTestFailure(
    comptime _: type,
    transaction: anytype,
    failure: ?ScalarCastTestFailure,
) !void {
    if (!builtin.is_test) return error.ValueUseTestHookUnavailable;
    transaction.scalar_cast_test_failure = failure;
}
fn core_requireActive(comptime _: type, transaction: anytype) !void {
    if (transaction.lifecycle != .active) return error.ValueUseTransactionClosed;
}
fn core_rollbackInternal(comptime Authority: type, transaction: anytype) void {
    transaction.snapshot.restore(transaction.selector);
    transaction.accumulator_session = null;
    transaction.request_count = 0;
    transaction.request_phase = .registering;
    transaction.write_nodes = [_]bool{false} ** physical_node_count;
    transaction.early_plans = [_]EarlyPlan{.{}} ** max_requests;
    resetSemanticOrderPlan(Authority, transaction);
    transaction.early_home_valid = [_]bool{false} ** max_requests;
    transaction.prepared_view_valid = [_]bool{false} ** max_requests;
    transaction.switch_boundary_applied = [_]bool{false} ** max_requests;
    transaction.view_generation +%= 1;
    if (transaction.view_generation == 0) transaction.view_generation = 1;
    transaction.lifecycle = .rolled_back;
}
fn core_handleFor(comptime _: type, transaction: anytype, index: u8) RequestHandle {
    return .{
        .authority = @intFromPtr(transaction),
        .index = index,
        .generation = transaction.view_generation,
    };
}
fn core_validateHandle(comptime _: type, transaction: anytype, handle: RequestHandle) !u8 {
    if (handle.authority != @intFromPtr(transaction) or handle.generation != transaction.view_generation)
        return error.ValueUsePreparedViewStale;
    if (handle.index >= transaction.request_count) return error.ValueUsePreparedViewMissing;
    return handle.index;
}
fn core_recordRequestFailure(comptime Authority: type, transaction: anytype, index: u8) void {
    if (transaction.failed_request == null)
        transaction.failed_request = Authority.handleFor(Authority, transaction, index);
}
fn core_noteRequestBoundaryError(
    comptime Authority: type,
    transaction: anytype,
    index: u8,
    err: anyerror,
) void {
    if (std.mem.startsWith(u8, @errorName(err), "Eflags")) return;
    // These errors describe the authority or complete plan rather than a
    // unique operand. They intentionally leave provenance empty.
    switch (err) {
        error.OutOfMemory,
        error.ValueUseRequestCapacityExceeded,
        error.ValueUseMappingCapacityExceeded,
        error.ValueUseConflictingDestination,
        error.ValueUseCopyCycleRequiresO4,
        error.ValueUseEarlyOrderingConflict,
        error.ValueUseEarlyOrderingCycle,
        error.ValueUseActionDiagnostic,
        error.ValueUseMemcpyTestFailure,
        error.ValueUseScratchCompareTestFailure,
        error.ValueUseScratchCompareImmediateOutOfRange,
        error.ValueUseScratchCompareFormUnsupported,
        error.ValueUseCurrentHomeEqZeroTestFailure,
        error.ValueUseSetccEaxCompareTestFailure,
        error.ValueUseCurrentHomeSignBitTestFailure,
        error.ValueUseCurrentHomeSignBitAccumulatorSessionRequired,
        error.ValueUseI128EqMinTestFailure,
        error.ValueUseI128EqMinAccumulatorSessionRequired,
        error.ValueUseI128SignBitTestFailure,
        error.ValueUseI128SignBitAccumulatorSessionRequired,
        error.ValueUseSetccEaxCompareFormUnsupported,
        error.ValueUseSetccEaxCompareImmediateOutOfRange,
        error.ValueUseSetccEaxCompareExactEiWidthUnsupported,
        error.ValueUseSetccEaxComparePredicateUnsupported,
        error.ValueUseLateRegistration,
        error.ValueUsePlanAlreadySealed,
        error.ValueUsePrepareBeforeSeal,
        error.ValueUseMaterializeBeforePrepare,
        error.ValueUseCommitBeforeMaterialization,
        error.ValueUseTransactionClosed,
        error.ValueUseSwitchBoundaryPhase,
        error.ValueUseSwitchBoundaryAlreadyApplied,
        error.ValueUseSwitchBoundaryRequired,
        => {},
        else => Authority.recordRequestFailure(Authority, transaction, index),
    }
}
fn core_validateActionRegistration(comptime Authority: type, transaction: anytype, action: PreparedAction) !void {
    switch (action) {
        .validate_shape, .emit_copy_to => {},
        .form_byte_address => |address| {
            try address.result.validate();
            switch (address.offset) {
                .constant => {},
                .request => |handle| _ = try Authority.validateRegisteredOperandHandle(Authority, transaction, handle),
            }
        },
        .form_scaled_address => |address| {
            try address.result.validate();
            _ = try scaleShift(address.scale);
            switch (address.index) {
                .constant => {},
                .request => |handle| _ = try Authority.validateRegisteredOperandHandle(Authority, transaction, handle),
            }
        },
        .form_readonly_table_address => |address| {
            try address.result.validate();
            try address.symbol.validate();
            _ = try scaleShift(address.scale);
            if (address.scale != address.shape.stride()) return error.ValueUseAddressScaleMismatch;
        },
        .store_scalar => |store| {
            if (store.bits != 1 and store.bits != 32) return error.ValueUseStoreWidthUnsupported;
            const index = try Authority.validateRegisteredOperandHandle(Authority, transaction, store.pointer);
            validateStorePointerOperand(&transaction.requests[index], true) catch |err| {
                Authority.noteRequestBoundaryError(Authority, transaction, index, err);
                return err;
            };
        },
        .store_immediate => |store| {
            if (store.bits != 1 and store.bits != 32) return error.ValueUseStoreWidthUnsupported;
            if (store.bits == 1 and store.value != 0 and store.value != 1)
                return error.ValueUseStoreImmediateOutOfRange;
        },
        .store_i64 => |store| {
            const index = try Authority.validateRegisteredOperandHandle(Authority, transaction, store.value);
            validateStoreI64ValueOperand(&transaction.requests[index]) catch |err| {
                Authority.noteRequestBoundaryError(Authority, transaction, index, err);
                return err;
            };
        },
        .store_stack_pointer => |store| {
            const index = try Authority.validateRegisteredOperandHandle(Authority, transaction, store.destination);
            validateStoreStackObjectOperand(&transaction.requests[index]) catch |err| {
                Authority.noteRequestBoundaryError(Authority, transaction, index, err);
                return err;
            };
        },
        .branch_condition => {},
        .switch_compare_chain => |*switch_action| try switch_action.validate(),
        .inline_memcpy => |memcpy| {
            const source = try Authority.validateRegisteredOperandHandle(Authority, transaction, memcpy.source);
            const length = try Authority.validateRegisteredOperandHandle(Authority, transaction, memcpy.length);
            validateMemcpyPointerOperand(&transaction.requests[source]) catch |err| {
                Authority.noteRequestBoundaryError(Authority, transaction, source, err);
                return err;
            };
            validateMemcpyLengthOperand(&transaction.requests[length]) catch |err| {
                Authority.noteRequestBoundaryError(Authority, transaction, length, err);
                return err;
            };
            if (source == length) return error.ValueUseIncompatibleDuplicate;
        },
        // Load widths are classified only after the canonical named
        // source resolves. This preserves the legacy precedence between
        // unresolved sources, source-home diagnostics, and width errors.
        .load_scalar => {},
        .load_readonly_pair => |*load| {
            try load.result.validate();
        },
        .load_stack_i128_alias => |*load| try load.result.validate(),
        .load_readonly_table_i16 => |*load| try load.result.validate(),
        .scratch_compare => return error.ValueUseScratchCompareAttachRequired,
        .current_home_eq_zero => |*compare| try compare.result.validate(),
        .setcc_eax_compare => |*compare| try compare.result.validate(),
        .current_home_sign_bit => |*compare| try compare.result.validate(),
        .i128_eq_min => |*compare| try compare.result.validate(),
        .i128_sign_bit => |*compare| try compare.result.validate(),
        .pair_low_scalar_cast => |*cast| {
            try cast.result.validate();
            try scalar_arithmetic_module.validatePairLowScalarCastAction(cast);
        },
        .accumulator_scalar_cast => |*cast| {
            try cast.result.validate();
            try scalar_arithmetic_module.validateAccumulatorScalarCastAction(cast);
        },
        .sign_extend_scratch => |*cast| try cast.result.validate(),
    }
}
fn core_validateRegisteredOperandHandle(comptime _: type, transaction: anytype, handle: RequestHandle) !u8 {
    if (handle.authority != @intFromPtr(transaction) or handle.generation != transaction.view_generation or
        handle.index >= transaction.request_count)
    {
        return error.ValueUseActionOperandNotRegistered;
    }
    if (transaction.requests[handle.index].destination != .prepared_source)
        return error.ValueUseActionOperandNotPreparedSource;
    return handle.index;
}
fn core_noteRegisteredOperandBoundaryError(
    comptime Authority: type,
    transaction: anytype,
    handle: RequestHandle,
    err: anyerror,
) void {
    const index = Authority.validateRegisteredOperandHandle(Authority, transaction, handle) catch return;
    Authority.noteRequestBoundaryError(Authority, transaction, index, err);
}
fn core_validateActionDependenciesCanonical(comptime Authority: type, transaction: anytype, action: PreparedAction) !void {
    switch (action) {
        .form_byte_address => |address| switch (address.offset) {
            .constant => {},
            .request => |handle| try Authority.validateOperandCanonical(Authority, transaction, handle),
        },
        .form_scaled_address => |address| switch (address.index) {
            .constant => {},
            .request => |handle| try Authority.validateOperandCanonical(Authority, transaction, handle),
        },
        .store_scalar => |store| try Authority.validateOperandCanonical(Authority, transaction, store.pointer),
        .store_i64 => |store| try Authority.validateOperandCanonical(Authority, transaction, store.value),
        .store_stack_pointer => |store| try Authority.validateOperandCanonical(Authority, transaction, store.destination),
        .inline_memcpy => |memcpy| {
            try Authority.validateOperandCanonical(Authority, transaction, memcpy.source);
            try Authority.validateOperandCanonical(Authority, transaction, memcpy.length);
        },
        .scratch_compare => |compare| switch (compare.rhs) {
            .named => |handle| try Authority.validateOperandCanonical(Authority, transaction, handle),
            .immediate, .null_pointer => {},
        },
        .current_home_eq_zero => {},
        .setcc_eax_compare => {},
        .current_home_sign_bit => {},
        .i128_eq_min => {},
        .i128_sign_bit => {},
        .pair_low_scalar_cast => {},
        .accumulator_scalar_cast => {},
        .sign_extend_scratch => {},
        .validate_shape,
        .emit_copy_to,
        .form_readonly_table_address,
        .store_immediate,
        .branch_condition,
        .switch_compare_chain,
        .load_scalar,
        .load_readonly_pair,
        .load_stack_i128_alias,
        .load_readonly_table_i16,
        => {},
    }
}
fn core_validateConsumedActionAfter(
    comptime Authority: type,
    transaction: anytype,
    owner_index: u8,
    action: PreparedAction,
) !void {
    try Authority.validateConsumedOperandAfter(Authority, transaction, owner_index);
    if (try actionSecondaryOperand(Authority, transaction, action)) |secondary|
        try Authority.validateConsumedOperandAfter(Authority, transaction, secondary);
    if (try actionTertiaryOperand(Authority, transaction, action)) |tertiary|
        try Authority.validateConsumedOperandAfter(Authority, transaction, tertiary);
}
fn core_validateConsumedOperandAfter(comptime Authority: type, transaction: anytype, index: u8) !void {
    return Authority.validateConsumedOperandAfterUnchecked(Authority, transaction, index) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, index, err);
        return err;
    };
}
fn core_validateConsumedOperandAfterUnchecked(comptime Authority: type, transaction: anytype, index: u8) !void {
    const request = &transaction.requests[index];
    const name = switch (request.source) {
        .named => |*identity| identity.slice(),
        .int, .null_value, .unsupported => return,
    };
    const binding = transaction.selector.values.get(name) orelse {
        if (try selector_state.valueIsLiveAfterCurrent(transaction.selector, name))
            return error.ValueUsePreparedViewStale;
        return;
    };
    if (!std.meta.eql(binding.vreg, transaction.prepared_views[index].source_vreg))
        return error.ValueUsePreparedViewStale;
    const refreshed = try Authority.materialization.buildPreparedRecord(Authority, transaction, index);
    if (materialization_module.preparedRecordEql(&transaction.prepared_views[index], &refreshed)) return;
    // A source genuinely live after the consuming instruction may be
    // durably relocated by the ordinary clobber-preservation authority.
    // The stable vreg, typed request validation, and canonical dependency
    // re-derivation above distinguish that relocation from a rebind.
    if (!try selector_state.valueIsLiveAfterCurrent(transaction.selector, name))
        return error.ValueUsePreparedViewStale;
}
fn core_validateOperandCanonical(comptime Authority: type, transaction: anytype, handle: RequestHandle) !void {
    const index = try Authority.validateRegisteredOperandHandle(Authority, transaction, handle);
    if (!transaction.prepared_view_valid[index]) {
        Authority.recordRequestFailure(Authority, transaction, index);
        return error.ValueUsePreparedViewMissing;
    }
    const refreshed = try Authority.materialization.buildPreparedRecord(Authority, transaction, index);
    if (!materialization_module.preparedRecordEql(&transaction.prepared_views[index], &refreshed)) {
        Authority.recordRequestFailure(Authority, transaction, index);
        return error.ValueUsePreparedViewStale;
    }
}
fn executePreparedActionInternal(
    comptime Authority: type,
    transaction: anytype,
    request_index: u8,
    view: *const Types.PreparedView,
    request: *const Types.StoredRequest,
    action: Types.PreparedAction,
) !void {
    switch (action) {
        .validate_shape => |expected_shape| try materialization_module.validatePreparedShape(view, expected_shape),
        .emit_copy_to => |destination| {
            const current = try materialization_module.preparedViewLoc(view);
            const target = destination.asDestination();
            switch (request.form) {
                .gpr32 => try materialization_module.materializeScalar32(transaction.selector, current, target),
                .gpr64 => try materialization_module.materializeScalar64(transaction.selector, current, target),
                .pointer, .stack_object_address => try materialization_module.materializePointer(transaction.selector, current, target),
                .stack_f32_pair_byte_address,
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
                => return error.ValueUsePreparedActionFormMismatch,
                .stack_argument => return error.ValueUseStackArgumentUnsupported,
                .new_pair_ownership => return error.ValueUseNewPairOwnershipUnsupported,
            }
        },
        .form_byte_address => |address| try address_memory.executeByteAddress(Authority, transaction, view, request, address),
        .form_scaled_address => |address| try address_memory.executeScaledAddress(Authority, transaction, view, request, address),
        .form_readonly_table_address => |address| try address_memory.executeReadOnlyTableAddress(Authority, transaction, view, request, address),
        .store_scalar => |store| try address_memory.executeStoreScalar(Authority, transaction, view, store),
        .store_immediate => |store| try address_memory.executeStoreImmediate(Authority, transaction, view, store),
        .store_i64 => |store| try address_memory.executeStoreI64(Authority, transaction, view, store),
        .store_stack_pointer => |store| try address_memory.executeStoreStackPointer(Authority, transaction, view, store),
        .branch_condition => try control_compare_module.executeBranchCondition(Authority, transaction, view),
        .switch_compare_chain => |switch_action| try control_compare_module.executeSwitchCompareChain(Authority, transaction, view, &switch_action),
        .inline_memcpy => |memcpy| try calls.executeInlineMemcpy(Authority, transaction, request_index, memcpy),
        .load_scalar => |load| try address_memory.executeScalarLoad(Authority, transaction, request_index, view, load),
        .load_readonly_pair => |load| try address_memory.executeReadOnlyPairLoad(Authority, transaction, request_index, view, &load),
        .load_stack_i128_alias => |load| try address_memory.executeStackI128AliasLoad(Authority, transaction, view, &load),
        .load_readonly_table_i16 => |load| try address_memory.executeReadOnlyTableI16Load(Authority, transaction, view, &load),
        .scratch_compare => |compare| try control_compare_module.executeScratchCompare(Authority, transaction, request_index, view, &compare),
        .current_home_eq_zero => |compare| try control_compare_module.executeCurrentHomeEqZero(
            Authority,
            transaction,
            request_index,
            view,
            &compare,
        ),
        .setcc_eax_compare => |compare| try control_compare_module.executeSetccEaxCompare(
            Authority,
            transaction,
            request_index,
            view,
            &compare,
        ),
        .current_home_sign_bit => |compare| try control_compare_module.executeCurrentHomeSignBit(
            Authority,
            transaction,
            request_index,
            view,
            &compare,
        ),
        .i128_eq_min => |compare| try control_compare_module.executeI128EqMin(
            Authority,
            transaction,
            request_index,
            view,
            &compare,
        ),
        .i128_sign_bit => |compare| try control_compare_module.executeI128SignBit(
            Authority,
            transaction,
            request_index,
            view,
            &compare,
        ),
        .pair_low_scalar_cast => |cast| try scalar_arithmetic_module.executePairLowScalarCast(
            Authority,
            transaction,
            request_index,
            view,
            &cast,
        ),
        .accumulator_scalar_cast => |cast| try scalar_arithmetic_module.executeAccumulatorScalarCast(
            Authority,
            transaction,
            request_index,
            view,
            &cast,
        ),
        .sign_extend_scratch => |cast| try scalar_arithmetic_module.executeSignExtendScratch(
            Authority,
            transaction,
            request_index,
            view,
            &cast,
        ),
    }
}
fn core_registeredOperandCurrent(comptime Authority: type, transaction: anytype, handle: RequestHandle) !ValueLoc {
    const index = try Authority.validateRegisteredOperandHandle(Authority, transaction, handle);
    return (try Authority.planning.validateRequestAt(Authority, transaction, index)) orelse {
        Authority.recordRequestFailure(Authority, transaction, index);
        return error.ValueUseUnsupportedSource;
    };
}
fn actionSecondaryOperand(
    comptime Authority: type,
    transaction: anytype,
    action: PreparedAction,
) !?u8 {
    return switch (action) {
        .form_byte_address => |address| switch (address.offset) {
            .constant => null,
            .request => |handle| try Authority.validateRegisteredOperandHandle(Authority, transaction, handle),
        },
        .form_scaled_address => |address| switch (address.index) {
            .constant => null,
            .request => |handle| try Authority.validateRegisteredOperandHandle(Authority, transaction, handle),
        },
        .store_scalar => |store| try Authority.validateRegisteredOperandHandle(Authority, transaction, store.pointer),
        .store_i64 => |store| try Authority.validateRegisteredOperandHandle(Authority, transaction, store.value),
        .store_stack_pointer => |store| try Authority.validateRegisteredOperandHandle(Authority, transaction, store.destination),
        .inline_memcpy => |memcpy| try Authority.validateRegisteredOperandHandle(Authority, transaction, memcpy.source),
        .scratch_compare => |compare| switch (compare.rhs) {
            .named => |handle| try Authority.validateRegisteredOperandHandle(Authority, transaction, handle),
            .immediate, .null_pointer => null,
        },
        .current_home_eq_zero => null,
        .setcc_eax_compare => null,
        .current_home_sign_bit => null,
        .i128_eq_min => null,
        .i128_sign_bit => null,
        .pair_low_scalar_cast => null,
        .accumulator_scalar_cast => null,
        .sign_extend_scratch => null,
        .load_scalar,
        .load_readonly_pair,
        .load_stack_i128_alias,
        .load_readonly_table_i16,
        => null,
        .validate_shape,
        .emit_copy_to,
        .form_readonly_table_address,
        .store_immediate,
        .branch_condition,
        .switch_compare_chain,
        => null,
    };
}
fn resetSemanticOrderPlan(comptime _: type, transaction: anytype) void {
    transaction.semantic_order_edges =
        [_][max_requests]bool{[_]bool{false} ** max_requests} ** max_requests;
    transaction.ordered_operand_count = 0;
}
fn core_registeredOperandView(
    comptime Authority: type,
    transaction: anytype,
    handle: RequestHandle,
) !*const PreparedView {
    const index = try Authority.validateRegisteredOperandHandle(Authority, transaction, handle);
    if (!transaction.prepared_view_valid[index]) {
        Authority.recordRequestFailure(Authority, transaction, index);
        return error.ValueUsePreparedViewMissing;
    }
    return &transaction.prepared_views[index].view;
}
fn actionTertiaryOperand(
    comptime Authority: type,
    transaction: anytype,
    action: PreparedAction,
) !?u8 {
    return switch (action) {
        .inline_memcpy => |memcpy| try Authority.validateRegisteredOperandHandle(Authority, transaction, memcpy.length),
        .validate_shape,
        .emit_copy_to,
        .form_byte_address,
        .form_scaled_address,
        .form_readonly_table_address,
        .store_scalar,
        .store_immediate,
        .store_i64,
        .store_stack_pointer,
        .branch_condition,
        .switch_compare_chain,
        .load_scalar,
        .load_readonly_pair,
        .load_stack_i128_alias,
        .load_readonly_table_i16,
        .scratch_compare,
        .current_home_eq_zero,
        .setcc_eax_compare,
        .current_home_sign_bit,
        .i128_eq_min,
        .i128_sign_bit,
        .pair_low_scalar_cast,
        .accumulator_scalar_cast,
        .sign_extend_scratch,
        => null,
    };
}
fn restoreSwitchDisplacedPhiDestinations(selector: *ComposedBlockSelector) !void {
    var it = selector.phi_destinations.iterator();
    while (it.next()) |entry| {
        const name = entry.key_ptr.*;
        if (!try selector_state.valueIsLiveAfterCurrent(selector, name)) continue;
        const destination = entry.value_ptr.*;
        const actual = selector_state.valueLoc(selector, name) orelse
            return error.ValueUseSwitchPhiDestinationMissing;
        if (composed_helpers.valueLocEql(actual, destination)) continue;
        const bits = selector_state.valueBits(selector, name) orelse
            return error.ValueUseSwitchPhiDestinationBitsMissing;
        try selector_state.materializeLocIntoLocWithBits(selector, actual, destination, bits);
        try selector_state.bindValueLoc(selector, name, destination);
    }
}
fn scaleShift(scale: u8) !u6 {
    if (scale == 0 or !std.math.isPowerOfTwo(scale)) return error.ValueUseAddressScaleInvalid;
    var value = scale;
    var shift: u6 = 0;
    while (value > 1) : (value >>= 1) shift += 1;
    return shift;
}
fn validateStorePointerOperand(
    request: *const Types.StoredRequest,
    allow_stack_object: bool,
) !void {
    if (request.expected.ty != .ptr or request.expected.pointer_address_space != 0)
        return error.ValueUsePreparedActionFormMismatch;
    if (request.form == .pointer) {
        if (request.expected.register_class != .gpr64 and
            request.expected.register_class != .stack_pointer)
            return error.ValueUsePreparedActionFormMismatch;
        return;
    }
    if (allow_stack_object and request.form == .stack_object_address and
        request.expected.register_class == .stack_object) return;
    return error.ValueUsePreparedActionFormMismatch;
}
fn validateStoreI64ValueOperand(request: *const Types.StoredRequest) !void {
    if (request.form != .gpr64 or !request.expected.ty.eql(.{ .int = 64 }) or
        request.expected.register_class != .gpr64)
        return error.ValueUsePreparedActionFormMismatch;
}
fn validateStoreStackObjectOperand(request: *const Types.StoredRequest) !void {
    if (request.form != .stack_object_address or request.expected.ty != .ptr or
        request.expected.register_class != .stack_object or
        request.expected.pointer_address_space != 0)
        return error.ValueUsePreparedActionFormMismatch;
}
fn validateMemcpyPointerOperand(request: *const Types.StoredRequest) !void {
    if (request.form != .memcpy_pointer or request.expected.ty != .ptr or
        request.expected.register_class != .gpr64 or
        request.expected.pointer_address_space != 0)
    {
        return error.ValueUsePreparedActionFormMismatch;
    }
}
fn validateMemcpyLengthOperand(request: *const Types.StoredRequest) !void {
    if (request.form != .memcpy_length or !request.expected.ty.eql(.{ .int = 64 }) or
        request.expected.register_class != .gpr64 or request.expected.pointer_address_space != null)
    {
        return error.ValueUsePreparedActionFormMismatch;
    }
}
fn coreOptionalPreparedActionEql(
    lhs: ?PreparedAction,
    rhs: ?PreparedAction,
) bool {
    if ((lhs == null) != (rhs == null)) return false;
    return if (lhs) |action| action.eql(rhs.?) else true;
}

const Implementation = struct {
    pub const Snapshot = CoreSnapshot;
    pub const planning = planning_module;
    pub const materialization = materialization_module;
    pub const composition = composition_module;
    pub const control_compare = control_compare_module;
    pub const scalar_arithmetic = scalar_arithmetic_module;
    pub const registeredOperandCurrent = core_registeredOperandCurrent;
    pub const registeredOperandView = core_registeredOperandView;
    pub const validateRequest = planning_module.validateRequest;
    pub const validateRequestAt = planning_module.validateRequestAt;
    pub const validateEarlyHome = planning_module.validateEarlyHome;
    pub const begin = core_begin;
    pub const deinit = core_deinit;
    pub const register = core_register;
    pub const attachScratchCompareAction = core_attachScratchCompareAction;
    pub const applySwitchBoundary = core_applySwitchBoundary;
    pub const preparedView = core_preparedView;
    pub const executePreparedAction = core_executePreparedAction;
    pub const commit = core_commit;
    pub const rollback = core_rollback;
    pub const requestCount = core_requestCount;
    pub const phase = core_phase;
    pub const actionDiagnostic = core_actionDiagnostic;
    pub const failedRequestIs = core_failedRequestIs;
    pub const setMemcpyTestFailure = core_setMemcpyTestFailure;
    pub const setLoadTestFailure = core_setLoadTestFailure;
    pub const setScratchCompareTestFailure = core_setScratchCompareTestFailure;
    pub const setCurrentHomeEqZeroTestFailure = core_setCurrentHomeEqZeroTestFailure;
    pub const setSetccEaxCompareTestFailure = core_setSetccEaxCompareTestFailure;
    pub const setCurrentHomeSignBitTestFailure = core_setCurrentHomeSignBitTestFailure;
    pub const setI128EqMinTestFailure = core_setI128EqMinTestFailure;
    pub const setI128SignBitTestFailure = core_setI128SignBitTestFailure;
    pub const setScalarCastTestFailure = core_setScalarCastTestFailure;
    pub const requireActive = core_requireActive;
    pub const rollbackInternal = core_rollbackInternal;
    pub const handleFor = core_handleFor;
    pub const validateHandle = core_validateHandle;
    pub const recordRequestFailure = core_recordRequestFailure;
    pub const noteRequestBoundaryError = core_noteRequestBoundaryError;
    pub const validateActionRegistration = core_validateActionRegistration;
    pub const validateRegisteredOperandHandle = core_validateRegisteredOperandHandle;
    pub const noteRegisteredOperandBoundaryError = core_noteRegisteredOperandBoundaryError;
    pub const validateActionDependenciesCanonical = core_validateActionDependenciesCanonical;
    pub const validateConsumedActionAfter = core_validateConsumedActionAfter;
    pub const validateConsumedOperandAfter = core_validateConsumedOperandAfter;
    pub const validateConsumedOperandAfterUnchecked = core_validateConsumedOperandAfterUnchecked;
    pub const validateOperandCanonical = core_validateOperandCanonical;
};

pub const ValueUseTransaction = model.Transaction(Implementation);
