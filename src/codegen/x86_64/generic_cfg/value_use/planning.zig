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
const control_compare = @import("actions/control_compare.zig");

const NodeList = struct {
    items: [6]Types.PhysicalNode = undefined,
    len: u8 = 0,

    fn append(list: *NodeList, node: Types.PhysicalNode) !void {
        if (list.len == list.items.len) return error.ValueUseInvalidDestination;
        list.items[list.len] = node;
        list.len += 1;
    }

    fn slice(list: *const NodeList) []const Types.PhysicalNode {
        return list.items[0..list.len];
    }
};

const Mapping = struct {
    source: ?Types.PhysicalNode,
    destination: Types.PhysicalNode,
    source_request_index: ?u8,
};

const MappingList = struct {
    items: [6]Mapping = undefined,
    len: u8 = 0,

    fn append(list: *MappingList, mapping: Mapping) void {
        list.items[list.len] = mapping;
        list.len += 1;
    }

    fn slice(list: *const MappingList) []const Mapping {
        return list.items[0..list.len];
    }
};

const CopyVisitState = enum { unseen, visiting, complete };

pub fn seal(comptime Authority: type, transaction: anytype) !void {
    try Authority.requireActive(Authority, transaction);
    if (transaction.request_phase != .registering) return error.ValueUsePlanAlreadySealed;
    errdefer resetSemanticOrderPlan(Authority, transaction);
    // Validate the action-owned role graph before destination planning can
    // obscure a semantic ownership contradiction with a physical conflict.
    try validateSemanticOrderTopology(Authority, transaction);
    var destinations = [_]bool{false} ** physical_node_count;
    var graph = [_][physical_node_count]bool{[_]bool{false} ** physical_node_count} ** physical_node_count;
    var writes = [_]bool{false} ** physical_node_count;
    var mappings: [max_mappings]Mapping = undefined;
    var mapping_count: usize = 0;

    for (transaction.requests[0..transaction.request_count], 0..) |*request, request_index_usize| {
        const request_index: u8 = @intCast(request_index_usize);
        const deferred_switch = request.prepared_action != null and
            request.prepared_action.? == .switch_compare_chain;
        if (deferred_switch) validateDeferredSwitchRequest(request) catch |err| {
            Authority.noteRequestBoundaryError(Authority, transaction, request_index, err);
            return err;
        };
        const current = if (deferred_switch) null else try validateRequestAt(Authority, transaction, request_index);
        const destination_nodes = requestDestinationNodes(Authority, transaction, request, current) catch |err| {
            Authority.noteRequestBoundaryError(Authority, transaction, request_index, err);
            return err;
        };
        for (destination_nodes.slice()) |destination_node| {
            const node_index = @intFromEnum(destination_node);
            if (destinations[node_index]) return error.ValueUseConflictingDestination;
            destinations[node_index] = true;
        }
        const request_mappings = requestMappings(Authority, transaction, request, request_index, current) catch |err| {
            Authority.noteRequestBoundaryError(Authority, transaction, request_index, err);
            return err;
        };
        const deferred_writes = request.prepared_action != null and
            actionOwnsOrderedWrites(request.prepared_action.?);
        for (request_mappings.slice()) |mapping| {
            if (mapping_count == mappings.len) return error.ValueUseMappingCapacityExceeded;
            mappings[mapping_count] = mapping;
            mapping_count += 1;
            if (mapping.source == null) {
                if (!deferred_writes) writes[@intFromEnum(mapping.destination)] = true;
                continue;
            }
            const source = mapping.source.?;
            if (source == mapping.destination) continue;
            graph[@intFromEnum(source)][@intFromEnum(mapping.destination)] = true;
            if (!deferred_writes) writes[@intFromEnum(mapping.destination)] = true;
        }
    }
    try rejectCopyCycles(graph);
    try planEarlyMaterializations(Authority, transaction, mappings[0..mapping_count]);
    transaction.write_nodes = writes;
    transaction.request_phase = .sealed;
}
pub fn validateRequestAt(comptime Authority: type, transaction: anytype, index: u8) !?ValueLoc {
    return validateRequest(Authority, transaction, &transaction.requests[index]) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, index, err);
        return err;
    };
}
pub fn validateRequest(comptime Authority: type, transaction: anytype, request: *const StoredRequest) !?ValueLoc {
    try validateFormAndDestination(request);
    switch (request.source) {
        .unsupported => return error.ValueUseUnsupportedSource,
        .int => |value| {
            const action = request.prepared_action orelse return error.ValueUseUnsupportedSource;
            if (request.form == .switch_condition and action == .switch_compare_chain) {
                try validateExpectedType(request.expected, request.form);
                _ = std.math.cast(i32, value) orelse return error.ValueUseSwitchImmediateOutOfRange;
                return null;
            }
            if (request.form == .accumulator_scalar_cast_operand and
                action == .accumulator_scalar_cast)
            {
                try validateExpectedType(request.expected, request.form);
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
            const binding = transaction.selector.values.get(name.slice()) orelse return error.ValueUseUnresolvedSource;
            const current = try Authority.materialization.resolveNamedCurrent(Authority, transaction, name.slice());
            try selector_state.validateAddressDependenciesForUse(transaction.selector, name.slice());
            if (!try selector_state.valueIsLiveAtOrAfterCurrent(transaction.selector, name.slice()))
                return error.ValueUseExpiredSource;
            try validateBindingCompatibility(binding, request, current);
            try validateSourceView(current, request.form);
            return current;
        },
    }
}
pub fn validateSemanticOrderTopology(comptime Authority: type, transaction: anytype) !void {
    var owners = [_]?u8{null} ** max_requests;
    var edges = [_][max_requests]bool{[_]bool{false} ** max_requests} ** max_requests;
    for (transaction.requests[0..transaction.request_count], 0..) |*request, index_usize| {
        const action = request.prepared_action orelse continue;
        const index: u8 = @intCast(index_usize);
        if (owners[index]) |owner| {
            if (owner != index) return error.ValueUseEarlyOrderingConflict;
        }
        owners[index] = index;
        const secondary = try actionSecondaryOperand(Authority, transaction, action) orelse continue;
        if (secondary == index) return error.ValueUseEarlyOrderingCycle;
        if (owners[secondary]) |owner| {
            if (owner != index) return error.ValueUseEarlyOrderingConflict;
        }
        owners[secondary] = index;
        edges[index][secondary] = true;
        if (try actionTertiaryOperand(Authority, transaction, action)) |tertiary| {
            if (tertiary == index or tertiary == secondary) return error.ValueUseEarlyOrderingCycle;
            if (owners[tertiary]) |owner| {
                if (owner != index) return error.ValueUseEarlyOrderingConflict;
            }
            owners[tertiary] = index;
            edges[secondary][tertiary] = true;
        }
    }
    try rejectSemanticOrderCycles(edges, transaction.request_count);
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
        .immediate_rhs_scalar => null,
        .immediate_lhs_scalar => null,
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
        .immediate_rhs_scalar,
        .immediate_lhs_scalar,
        => null,
    };
}
fn resetSemanticOrderPlan(comptime _: type, transaction: anytype) void {
    transaction.semantic_order_edges =
        [_][max_requests]bool{[_]bool{false} ** max_requests} ** max_requests;
    transaction.ordered_operand_count = 0;
}
pub fn planEarlyMaterializations(comptime Authority: type, transaction: anytype, mappings: []const Mapping) !void {
    var source_counts = [_]u8{0} ** max_requests;
    var source_nodes = [_]bool{false} ** physical_node_count;
    for (mappings) |mapping| {
        if (mapping.source) |source| source_nodes[@intFromEnum(source)] = true;
        if (mapping.source_request_index) |mapped_index| {
            for (transaction.requests[0..transaction.request_count], 0..) |*request, request_index| {
                if (!request.source.eql(&transaction.requests[mapped_index].source)) continue;
                if (source_counts[request_index] == std.math.maxInt(u8))
                    return error.ValueUseMappingCapacityExceeded;
                source_counts[request_index] += 1;
            }
        }
    }

    var owners = [_]?u8{null} ** max_requests;
    var roots: [max_requests]u8 = undefined;
    var root_count: u8 = 0;
    resetSemanticOrderPlan(Authority, transaction);

    // Actions own their semantic operands. A secondary request cannot be
    // silently shared by two instruction authorities.
    for (transaction.requests[0..transaction.request_count], 0..) |*request, index_usize| {
        const action = request.prepared_action orelse continue;
        const index: u8 = @intCast(index_usize);
        owners[index] = index;
        roots[root_count] = index;
        root_count += 1;
        if (try actionSecondaryOperand(Authority, transaction, action)) |secondary| {
            if (owners[secondary]) |owner| {
                if (owner != index) return error.ValueUseEarlyOrderingConflict;
            }
            owners[secondary] = index;
            transaction.semantic_order_edges[index][secondary] = true;
        }
        if (try actionTertiaryOperand(Authority, transaction, action)) |tertiary| {
            const secondary = (try actionSecondaryOperand(Authority, transaction, action)) orelse
                return error.ValueUseEarlyOrderingConflict;
            if (owners[tertiary]) |owner| {
                if (owner != index) return error.ValueUseEarlyOrderingConflict;
            }
            owners[tertiary] = index;
            transaction.semantic_order_edges[secondary][tertiary] = true;
        }
    }
    for (transaction.requests[0..transaction.request_count], 0..) |_, index_usize| {
        const index: u8 = @intCast(index_usize);
        if (owners[index] != null) continue;
        owners[index] = index;
        roots[root_count] = index;
        root_count += 1;
    }
    try rejectSemanticOrderCycles(transaction.semantic_order_edges, transaction.request_count);
    try sortSemanticRoots(Authority, transaction, roots[0..root_count], mappings);

    for (roots[0..root_count]) |root| {
        var prefix_open = true;
        try appendOrderedOperand(
            Authority,
            transaction,
            root,
            .primary,
            &prefix_open,
            mappings,
            source_counts,
            source_nodes,
        );
        if (transaction.requests[root].prepared_action) |action| {
            if (try actionSecondaryOperand(Authority, transaction, action)) |secondary| try appendOrderedOperand(
                Authority,
                transaction,
                secondary,
                .secondary,
                &prefix_open,
                mappings,
                source_counts,
                source_nodes,
            );
            if (try actionTertiaryOperand(Authority, transaction, action)) |tertiary| try appendOrderedOperand(
                Authority,
                transaction,
                tertiary,
                .tertiary,
                &prefix_open,
                mappings,
                source_counts,
                source_nodes,
            );
        }
    }
}
fn appendOrderedOperand(
    comptime Authority: type,
    transaction: anytype,
    request_index: u8,
    role: SemanticRole,
    prefix_open: *bool,
    mappings: []const Mapping,
    source_counts: [max_requests]u8,
    source_nodes: [physical_node_count]bool,
) !void {
    if (transaction.ordered_operand_count == max_requests)
        return error.ValueUseMappingCapacityExceeded;
    var operand_phase: OperandPhase = .no_op;
    var destination: ?ArgReg = null;
    var matching_mapping: ?Mapping = null;
    var matching_count: u8 = 0;
    for (mappings) |mapping| {
        if (mapping.source_request_index != request_index) continue;
        matching_count += 1;
        matching_mapping = mapping;
    }
    if (matching_count == 0 and
        transaction.requests[request_index].destination != .prepared_source and
        transaction.requests[request_index].destination != .prepared_view)
    {
        operand_phase = .ordinary;
    } else if (matching_count > 1) {
        operand_phase = .ordinary;
    } else if (matching_mapping) |mapping| {
        if (mapping.source == mapping.destination) {
            operand_phase = .no_op;
        } else if (source_counts[request_index] == 1 and
            !source_nodes[@intFromEnum(mapping.destination)] and
            argRegForNode(mapping.destination) != null and
            selector_state.scratchRegIsProvenFree(
                transaction.selector,
                argRegForNode(mapping.destination).?,
            ))
        {
            const request = &transaction.requests[request_index];
            const current = switch (request.source) {
                .named => try validateRequestAt(Authority, transaction, request_index) orelse null,
                .int, .null_value, .unsupported => null,
            };
            if (current != null and earlySequencingCandidate(current.?, request.form)) {
                operand_phase = .safe_early;
                destination = argRegForNode(mapping.destination).?;
            } else {
                operand_phase = .ordinary;
            }
        } else {
            operand_phase = .ordinary;
        }
    }
    if (operand_phase == .ordinary) prefix_open.* = false;
    if (operand_phase == .safe_early and !prefix_open.*) {
        operand_phase = .ordinary;
        destination = null;
    }
    if (operand_phase == .safe_early)
        transaction.early_plans[request_index].destination = destination;
    transaction.ordered_operands[transaction.ordered_operand_count] = .{
        .request_index = request_index,
        .role = role,
        .phase = operand_phase,
    };
    transaction.ordered_operand_count += 1;
}
fn sortSemanticRoots(
    comptime Authority: type,
    transaction: anytype,
    roots: []u8,
    mappings: []const Mapping,
) !void {
    if (roots.len < 2) return;
    for (1..roots.len) |index| {
        const current = roots[index];
        var insertion = index;
        while (insertion > 0 and semanticRootLessThan(Authority, transaction, current, roots[insertion - 1], mappings)) {
            roots[insertion] = roots[insertion - 1];
            insertion -= 1;
        }
        roots[insertion] = current;
    }
    for (roots[1..], roots[0 .. roots.len - 1]) |current, previous| {
        if (!semanticRootLessThan(Authority, transaction, previous, current, mappings) and
            !semanticRootLessThan(Authority, transaction, current, previous, mappings))
        {
            return error.ValueUseEarlyOrderingConflict;
        }
    }
}
fn semanticRootLessThan(
    comptime Authority: type,
    transaction: anytype,
    lhs: u8,
    rhs: u8,
    mappings: []const Mapping,
) bool {
    const lhs_node = firstStructuralDestination(Authority, transaction, lhs, mappings);
    const rhs_node = firstStructuralDestination(Authority, transaction, rhs, mappings);
    if (@intFromEnum(lhs_node) != @intFromEnum(rhs_node))
        return @intFromEnum(lhs_node) < @intFromEnum(rhs_node);
    const lhs_source = &transaction.requests[lhs].source;
    const rhs_source = &transaction.requests[rhs].source;
    return sourceStructuralOrder(lhs_source, rhs_source) == .lt;
}
fn firstStructuralDestination(
    comptime _: type,
    transaction: anytype,
    request_index: u8,
    mappings: []const Mapping,
) PhysicalNode {
    if (firstMappingDestination(request_index, mappings)) |node| return node;
    return switch (transaction.requests[request_index].destination) {
        .gpr32, .gpr64 => |reg| nodeForArgReg(reg),
        .eax, .rax => .accumulator,
        .pair => |pair| @enumFromInt(@min(
            @intFromEnum(nodeForArgReg(pair.lo)),
            @intFromEnum(nodeForArgReg(pair.hi)),
        )),
        .prepared_source, .prepared_view, .stack_argument, .new_pair => .accumulator,
    };
}
pub fn validateEarlyHome(comptime Authority: type, transaction: anytype, index: u8) !void {
    return validateEarlyHomeUnchecked(Authority, transaction, index) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, index, err);
        return err;
    };
}
fn validateEarlyHomeUnchecked(comptime Authority: type, transaction: anytype, index: u8) !void {
    if (!transaction.early_home_valid[index]) return error.ValueUseEarlyHomeMissing;
    const request = &transaction.requests[index];
    const name = switch (request.source) {
        .named => |*identity| identity.slice(),
        .int, .null_value, .unsupported => return error.ValueUseEarlySourceNotNamed,
    };
    const binding = transaction.selector.values.get(name) orelse
        return error.ValueUseUnresolvedSource;
    if (!std.meta.eql(binding.vreg, transaction.early_homes[index].source_vreg))
        return error.ValueUsePreparedViewStale;
    _ = try validateRequestAt(Authority, transaction, index);
    try validateExpectedType(request.expected, request.form);
    try validateSourceView(transaction.early_homes[index].loc, request.form);
}
fn validateDeferredSwitchRequest(request: *const Types.StoredRequest) !void {
    try validateFormAndDestination(request);
    if (request.form != .switch_condition or request.destination != .prepared_view or
        request.prepared_action == null or request.prepared_action.? != .switch_compare_chain)
    {
        return error.ValueUsePreparedActionFormMismatch;
    }
    try validateExpectedType(request.expected, .switch_condition);
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
            => {},
            .stack_argument => return error.ValueUseStackArgumentUnsupported,
            .new_pair_ownership => return error.ValueUseNewPairOwnershipUnsupported,
        }
        return switch (action) {
            .validate_shape => if (request.form == .stack_f32_pair_byte_address)
                error.ValueUsePreparedActionFormMismatch,
            .emit_copy_to => |destination| validateCopyActionForm(request.form, destination),
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
        => false,
        .pair_low_high, .pair_high_low => request.destination == .pair,
        .stack_argument => return error.ValueUseStackArgumentUnsupported,
        .new_pair_ownership => return error.ValueUseNewPairOwnershipUnsupported,
    };
    if (!valid) return error.ValueUseDestinationFormMismatch;
}
fn earlySequencingCandidate(loc: ValueLoc, form: Types.UseForm) bool {
    return switch (form) {
        .gpr32, .gpr64 => loc == .spill64,
        .pointer => switch (loc) {
            .spill64 => true,
            .readonly_table_ptr => |ptr| ptr.storage == .spill,
            else => false,
        },
        .branch_condition, .switch_condition => false,
        .load_address => false,
        .scratch_compare_operand => false,
        .current_home_eq_zero_operand => false,
        .setcc_eax_compare_operand => false,
        .current_home_sign_bit_operand => false,
        .i128_icmp_pair_operand => false,
        .pair_low_scalar_cast_operand => false,
        .accumulator_scalar_cast_operand => false,
        .sign_extend_scratch_operand => false,
        .immediate_rhs_scalar_operand => false,
        .immediate_lhs_scalar_operand => false,
        else => false,
    };
}
pub fn requestDestinationNodes(
    comptime Authority: type,
    transaction: anytype,
    request: *const Types.StoredRequest,
    current: ?ValueLoc,
) !NodeList {
    var result: NodeList = .{};
    switch (request.destination) {
        .gpr32, .gpr64 => |reg| try result.append(nodeForArgReg(reg)),
        .eax, .rax => try result.append(.accumulator),
        .pair => |pair| {
            try result.append(nodeForArgReg(pair.lo));
            try result.append(nodeForArgReg(pair.hi));
        },
        .prepared_source => {},
        .prepared_view => switch (request.prepared_action orelse return error.ValueUsePreparedActionMissing) {
            .validate_shape => {},
            .emit_copy_to => |destination| switch (destination) {
                .gpr32, .gpr64 => |reg| try result.append(nodeForArgReg(reg)),
                .eax, .rax => try result.append(.accumulator),
            },
            .form_byte_address => |address| switch (address.offset) {
                .constant => switch (current orelse return error.ValueUseUnresolvedSource) {
                    .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr => {},
                    else => try result.append(.rcx),
                },
                .request => |handle| {
                    _ = try Authority.validateRegisteredOperandHandle(Authority, transaction, handle);
                    try result.append(.r8);
                    try result.append(.rcx);
                },
            },
            .form_scaled_address => |address| switch (current orelse return error.ValueUseUnresolvedSource) {
                .stack_i32_array => switch (address.index) {
                    .constant => {},
                    .request => |handle| {
                        _ = try Authority.validateRegisteredOperandHandle(Authority, transaction, handle);
                        try result.append(.rcx);
                    },
                },
                .stack_i32_ptr => switch (address.index) {
                    .constant => {},
                    .request => |handle| _ = try Authority.validateRegisteredOperandHandle(Authority, transaction, handle),
                },
                else => switch (address.index) {
                    .constant => try result.append(.rcx),
                    .request => |handle| {
                        _ = try Authority.validateRegisteredOperandHandle(Authority, transaction, handle);
                        try result.append(.rcx);
                        try result.append(.r8);
                    },
                },
            },
            .form_readonly_table_address => {
                try result.append(.rcx);
                try result.append(.r8);
            },
            .store_scalar => |store| {
                try result.append(.accumulator);
                appendStorePointerDestinationNodes(
                    &result,
                    try Authority.registeredOperandCurrent(Authority, transaction, store.pointer),
                    store.bits,
                ) catch |err| {
                    Authority.noteRegisteredOperandBoundaryError(Authority, transaction, store.pointer, err);
                    return err;
                };
            },
            .store_immediate => |store| {
                try result.append(.accumulator);
                try appendStorePointerDestinationNodes(
                    &result,
                    current orelse return error.ValueUseUnresolvedSource,
                    store.bits,
                );
            },
            .store_i64 => {
                try result.append(.rcx);
                try result.append(.accumulator);
            },
            .store_stack_pointer => try result.append(.rcx),
            .branch_condition => switch (current orelse return error.ValueUseUnresolvedSource) {
                .spill64 => try result.append(.rcx),
                else => {},
            },
            .switch_compare_chain => try result.append(.accumulator),
            .inline_memcpy => {
                try result.append(.rdi);
                try result.append(.rsi);
                try result.append(.rdx);
            },
            .load_scalar => |load| {
                try result.append(.accumulator);
                const source = current orelse return error.ValueUseUnresolvedSource;
                switch (load.kind) {
                    .ordinary => switch (source) {
                        .spill64 => try result.append(.rcx),
                        .stack_i32_ptr => |ptr| if (ptr.index != null) {
                            try result.append(.rcx);
                            if (ptr.index.?.addend_name != null) try result.append(.r8);
                        },
                        else => {},
                    },
                    .readonly_pointer => {
                        const pointer_reg: ?ArgReg = switch (source) {
                            .arg64, .scratch64 => |reg| reg,
                            .spill64 => blk: {
                                try result.append(.rdi);
                                break :blk .rdi;
                            },
                            else => null,
                        };
                        if (load.bits == 56) {
                            try result.append(if (pointer_reg == .rcx) .r8 else .rcx);
                        }
                    },
                }
            },
            .load_readonly_pair => {
                const source = current orelse return error.ValueUseUnresolvedSource;
                try result.append(.accumulator);
                for (selector_types.selector_allocatable_pairs) |pair| {
                    try result.append(nodeForArgReg(pair.lo));
                    try result.append(nodeForArgReg(pair.hi));
                }
                switch (source) {
                    .spill64 => try result.append(.rdi),
                    .arg64, .scratch64 => |reg| {
                        for (selector_types.selector_allocatable_pairs) |pair| {
                            if (pair.contains(reg)) {
                                try result.append(.rdi);
                                break;
                            }
                        }
                    },
                    else => return error.ValueUseLoadReadonlyPointerProvenance,
                }
            },
            .load_stack_i128_alias => {},
            .load_readonly_table_i16 => {
                try result.append(.r8);
                switch (current orelse return error.ValueUseUnresolvedSource) {
                    .readonly_table_ptr => |ptr| if (ptr.storage == .spill) try result.append(.rcx),
                    else => return error.ValueUseLoadReadonlyTableType,
                }
            },
            .scratch_compare => |*compare| {
                const plan = try control_compare.classifyScratchCompare(compare);
                try result.append(.accumulator);
                try result.append(nodeForArgReg(plan.lhs_register));
                if (plan.rhs_register) |reg| try result.append(nodeForArgReg(reg));
                if (plan.immediate_register) |reg| {
                    if (plan.rhs_register == null or plan.rhs_register.? != reg)
                        try result.append(nodeForArgReg(reg));
                }
            },
            .current_home_eq_zero => {
                try result.append(.rcx);
                try result.append(.accumulator);
            },
            .setcc_eax_compare => try result.append(.accumulator),
            .current_home_sign_bit => try result.append(.accumulator),
            .i128_eq_min => {
                const source_pair: ?RegPair = switch (current orelse
                    return error.ValueUseUnresolvedSource) {
                    .arg128, .scratch128 => |pair| pair,
                    .stack128_value, .spill128 => null,
                    else => return error.ValueUseI128PairLocationUnsupported,
                };
                const pair = if (source_pair) |source|
                    if (source.contains(selector_types.pair_a.lo) or
                        source.contains(selector_types.pair_a.hi))
                        selector_types.pair_b
                    else
                        selector_types.pair_a
                else
                    selector_types.pair_a;
                try result.append(nodeForArgReg(pair.lo));
                try result.append(nodeForArgReg(pair.hi));
                try result.append(nodeForArgReg(if (pair.contains(.r8)) .rcx else .r8));
                try result.append(.accumulator);
            },
            .i128_sign_bit => try result.append(.accumulator),
            .pair_low_scalar_cast => |*cast| try result.append(nodeForArgReg(
                try pairLowScalarCastDestination(transaction.selector, current, &cast.result),
            )),
            .accumulator_scalar_cast => |cast| {
                try result.append(.accumulator);
                if ((cast.from_bits > 32 and cast.from_bits != 52) or
                    (cast.from_bits == 64 and cast.to_bits == 52))
                {
                    try result.append(.rcx);
                }
            },
            .sign_extend_scratch => try result.append(nodeForArgReg(
                try signExtendScratchDestination(current orelse return error.ValueUseUnresolvedSource),
            )),
            .immediate_rhs_scalar => |*immediate| try appendImmediateRhsDestinationNodes(
                transaction.selector,
                current orelse return error.ValueUseUnresolvedSource,
                &request.source,
                immediate,
                &result,
            ),
            .immediate_lhs_scalar => {
                try result.append(.rcx);
                try result.append(.accumulator);
            },
        },
        .stack_argument => return error.ValueUseStackArgumentUnsupported,
        .new_pair => return error.ValueUseNewPairOwnershipUnsupported,
    }
    return result;
}

fn appendImmediateRhsDestinationNodes(
    selector: *ComposedBlockSelector,
    current: ValueLoc,
    source: *const Types.Source,
    action: *const Types.ImmediateRhsScalarAction,
    result: *NodeList,
) !void {
    const bits = switch (action.integer_ty) {
        .int => |value| value,
        else => return error.ValueUseImmediateScalarWidthUnsupported,
    };
    switch (action.operation) {
        .sdiv => {
            try result.append(.rcx);
            try result.append(.accumulator);
        },
        .lshr => if (bits <= 32) {
            try result.append(.rcx);
        } else {
            const destination = immediateScratch64PlanningDestination(
                selector,
                current,
                source,
                &action.result,
            );
            if (destination) |reg|
                try result.append(nodeForArgReg(reg))
            else if (current == .spill64)
                try result.append(.accumulator)
            else
                return error.ValueUseImmediateScalarScratchUnavailable;
        },
        .shl => if (bits <= 32 and current == .scratch32) {
            try result.append(.accumulator);
            try result.append(nodeForArgReg(current.scratch32));
        } else {
            try result.append(.accumulator);
        },
        .ashr => if (bits <= 32)
            try result.append(.accumulator)
        else
            try result.append(.rcx),
        .@"and" => if (bits <= 32 or action.literal == std.math.maxInt(u32)) {
            try result.append(.accumulator);
        } else {
            try result.append(.accumulator);
            try result.append(.rcx);
        },
        .@"or", .xor => if (bits <= 32) {
            try result.append(.accumulator);
            if (action.operation == .xor) try result.append(.rcx);
        } else {
            try result.append(.accumulator);
            try result.append(.rcx);
        },
        .add, .sub => if (bits == 64 and immediateFitsI32(action.literal)) {
            try result.append(.rcx);
        } else if (bits <= 32) {
            try result.append(.accumulator);
        } else {
            try result.append(.accumulator);
            try result.append(.rcx);
        },
        else => return error.ValueUseImmediateScalarFormUnsupported,
    }
}

fn immediateScratch64PlanningDestination(
    selector: *ComposedBlockSelector,
    current: ValueLoc,
    source: *const Types.Source,
    result: *const ActionIdentity,
) ?ArgReg {
    if (selector.allocation_plan) |plan| {
        if (plan.assignment(result.slice())) |assignment| {
            if (assignment == .gpr64 and scalarCastScratchAvailable(selector, assignment.gpr64))
                return assignment.gpr64;
        }
    }
    for (selector_types.selector_allocatable_regs) |reg|
        if (scalarCastScratchAvailable(selector, reg)) return reg;
    switch (current) {
        .scratch64 => |reg| if (selector_state.regConflictStatus(selector, reg) orelse true)
            return reg,
        else => {},
    }
    const source_value: ir.Value = switch (source.*) {
        .named => |*identity| .{ .named = identity.slice() },
        else => return null,
    };
    if (selector_state.spillScratch64SourceForInPlace(selector, source_value)) |spill_source|
        return spill_source.reg;
    return null;
}

fn immediateFitsI32(value: i128) bool {
    return value >= std.math.minInt(i32) and value <= std.math.maxInt(i32);
}

fn pairLowScalarCastDestination(
    selector: *const ComposedBlockSelector,
    current: ?ValueLoc,
    result: *const ActionIdentity,
) !ArgReg {
    if (selector.allocation_plan) |plan| {
        if (plan.assignment(result.slice())) |assignment| {
            if (assignment == .gpr64 and scalarCastScratchAvailable(selector, assignment.gpr64))
                return assignment.gpr64;
        }
    }
    switch (current orelse return error.ValueUseUnresolvedSource) {
        .arg128, .scratch128 => |pair| return pair.lo,
        .stack128_value, .spill128 => {},
        else => return error.ValueUseScalarCastLocationUnsupported,
    }
    for (selector_types.selector_allocatable_regs) |reg| {
        if (scalarCastScratchAvailable(selector, reg)) return reg;
    }
    return error.ValueUseScalarCastScratchUnavailable;
}

fn signExtendScratchDestination(current: ValueLoc) !ArgReg {
    const source = switch (current) {
        .arg32, .scratch32 => |reg| reg,
        else => return error.ValueUseScalarCastLocationUnsupported,
    };
    return switch (source) {
        .rdi => .r8,
        .rsi => .r9,
        .rdx => .rcx,
        .rcx => .r8,
        .r8 => .r9,
        .r9 => .r8,
    };
}

fn scalarCastScratchAvailable(selector: *const ComposedBlockSelector, reg: ArgReg) bool {
    return selector_state.regConflictStatus(selector, reg) orelse true;
}

pub fn requestMappings(
    comptime Authority: type,
    transaction: anytype,
    request: *const Types.StoredRequest,
    request_index: u8,
    current: ?ValueLoc,
) !MappingList {
    var mappings: MappingList = .{};
    if (request.destination == .prepared_source or
        (request.destination == .prepared_view and request.prepared_action.? == .validate_shape)) return mappings;
    if (request.destination == .prepared_view) {
        const action = request.prepared_action.?;
        switch (action) {
            .form_byte_address => |address| switch (address.offset) {
                .constant => switch (current orelse return error.ValueUseUnresolvedSource) {
                    .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr => return mappings,
                    else => mappings.append(.{
                        .source = scalarSourceNode(current.?),
                        .destination = .rcx,
                        .source_request_index = request_index,
                    }),
                },
                .request => |handle| {
                    const offset_current = try Authority.registeredOperandCurrent(Authority, transaction, handle);
                    mappings.append(.{
                        .source = scalarSourceNode(current orelse return error.ValueUseUnresolvedSource),
                        .destination = .r8,
                        .source_request_index = request_index,
                    });
                    mappings.append(.{
                        .source = scalarSourceNode(offset_current),
                        .destination = .rcx,
                        .source_request_index = handle.index,
                    });
                },
            },
            .form_scaled_address => |address| {
                switch (current orelse return error.ValueUseUnresolvedSource) {
                    .stack_i32_array => switch (address.index) {
                        .constant => return mappings,
                        .request => |handle| mappings.append(.{
                            .source = scalarSourceNode(try Authority.registeredOperandCurrent(Authority, transaction, handle)),
                            .destination = .rcx,
                            .source_request_index = handle.index,
                        }),
                    },
                    .stack_i32_ptr => return mappings,
                    else => switch (address.index) {
                        .constant => mappings.append(.{
                            .source = scalarSourceNode(current.?),
                            .destination = .rcx,
                            .source_request_index = request_index,
                        }),
                        .request => |handle| {
                            mappings.append(.{
                                .source = scalarSourceNode(current.?),
                                .destination = .rcx,
                                .source_request_index = request_index,
                            });
                            mappings.append(.{
                                .source = scalarSourceNode(try Authority.registeredOperandCurrent(Authority, transaction, handle)),
                                .destination = .r8,
                                .source_request_index = handle.index,
                            });
                        },
                    },
                }
            },
            .form_readonly_table_address => {
                mappings.append(.{
                    .source = scalarSourceNode(current orelse return error.ValueUseUnresolvedSource),
                    .destination = .r8,
                    .source_request_index = request_index,
                });
                mappings.append(.{ .source = null, .destination = .rcx, .source_request_index = null });
            },
            .store_scalar => |store| {
                mappings.append(.{
                    .source = scalarSourceNode(current orelse return error.ValueUseUnresolvedSource),
                    .destination = .accumulator,
                    .source_request_index = request_index,
                });
                appendStorePointerMappings(
                    Authority,
                    transaction,
                    &mappings,
                    try Authority.registeredOperandCurrent(Authority, transaction, store.pointer),
                    store.pointer.index,
                    store.bits,
                ) catch |err| {
                    Authority.noteRegisteredOperandBoundaryError(Authority, transaction, store.pointer, err);
                    return err;
                };
            },
            .store_immediate => |store| {
                mappings.append(.{ .source = null, .destination = .accumulator, .source_request_index = null });
                try appendStorePointerMappings(
                    Authority,
                    transaction,
                    &mappings,
                    current orelse return error.ValueUseUnresolvedSource,
                    null,
                    store.bits,
                );
            },
            .store_i64 => |store| {
                const pointer = current orelse return error.ValueUseUnresolvedSource;
                try validateI64StorePointer(pointer);
                mappings.append(.{
                    .source = scalarSourceNode(pointer),
                    .destination = .rcx,
                    .source_request_index = request_index,
                });
                mappings.append(.{
                    .source = scalarSourceNode(try Authority.registeredOperandCurrent(Authority, transaction, store.value)),
                    .destination = .accumulator,
                    .source_request_index = store.value.index,
                });
            },
            .store_stack_pointer => |store| {
                try validateStackPointerStoreViews(
                    current orelse return error.ValueUseUnresolvedSource,
                    try Authority.registeredOperandCurrent(Authority, transaction, store.destination),
                );
                mappings.append(.{ .source = null, .destination = .rcx, .source_request_index = request_index });
            },
            .branch_condition => switch (current orelse return error.ValueUseUnresolvedSource) {
                .spill64 => mappings.append(.{
                    .source = scalarSourceNode(current.?),
                    .destination = .rcx,
                    .source_request_index = request_index,
                }),
                else => {},
            },
            .switch_compare_chain => return mappings,
            .inline_memcpy => |memcpy| {
                mappings.append(.{
                    .source = scalarSourceNode(current orelse return error.ValueUseUnresolvedSource),
                    .destination = .rdi,
                    .source_request_index = request_index,
                });
                mappings.append(.{
                    .source = scalarSourceNode(try Authority.registeredOperandCurrent(Authority, transaction, memcpy.source)),
                    .destination = .rsi,
                    .source_request_index = memcpy.source.index,
                });
                mappings.append(.{
                    .source = scalarSourceNode(try Authority.registeredOperandCurrent(Authority, transaction, memcpy.length)),
                    .destination = .rdx,
                    .source_request_index = memcpy.length.index,
                });
            },
            .load_scalar => |load| {
                const source = current orelse return error.ValueUseUnresolvedSource;
                mappings.append(.{ .source = null, .destination = .accumulator, .source_request_index = null });
                switch (load.kind) {
                    .ordinary => switch (source) {
                        .spill64 => mappings.append(.{
                            .source = scalarSourceNode(source),
                            .destination = .rcx,
                            .source_request_index = request_index,
                        }),
                        .stack_i32_ptr => |ptr| if (ptr.index) |index| {
                            const index_loc = try Authority.materialization.resolveNamedCurrent(Authority, transaction, index.name);
                            mappings.append(.{
                                .source = scalarSourceNode(index_loc),
                                .destination = .rcx,
                                .source_request_index = request_index,
                            });
                            if (index.addend_name) |addend_name| {
                                mappings.append(.{
                                    .source = scalarSourceNode(try Authority.materialization.resolveNamedCurrent(Authority, transaction, addend_name)),
                                    .destination = .r8,
                                    .source_request_index = request_index,
                                });
                            }
                        },
                        else => {},
                    },
                    .readonly_pointer => {
                        const pointer_reg: ?ArgReg = switch (source) {
                            .arg64, .scratch64 => |reg| reg,
                            .spill64 => blk: {
                                mappings.append(.{
                                    .source = scalarSourceNode(source),
                                    .destination = .rdi,
                                    .source_request_index = request_index,
                                });
                                break :blk .rdi;
                            },
                            else => null,
                        };
                        if (load.bits == 56) mappings.append(.{
                            .source = null,
                            .destination = if (pointer_reg == .rcx) .r8 else .rcx,
                            .source_request_index = null,
                        });
                    },
                }
            },
            .load_readonly_pair => {
                mappings.append(.{ .source = null, .destination = .accumulator, .source_request_index = null });
                for (selector_types.selector_allocatable_pairs) |pair| {
                    mappings.append(.{ .source = null, .destination = nodeForArgReg(pair.lo), .source_request_index = null });
                    mappings.append(.{ .source = null, .destination = nodeForArgReg(pair.hi), .source_request_index = null });
                }
                switch (current orelse return error.ValueUseUnresolvedSource) {
                    .spill64 => |frame_index| mappings.append(.{
                        .source = scalarSourceNode(.{ .spill64 = frame_index }),
                        .destination = .rdi,
                        .source_request_index = request_index,
                    }),
                    .arg64, .scratch64 => |reg| {
                        for (selector_types.selector_allocatable_pairs) |pair| {
                            if (pair.contains(reg)) {
                                mappings.append(.{
                                    .source = scalarSourceNode(current.?),
                                    .destination = .rdi,
                                    .source_request_index = request_index,
                                });
                                break;
                            }
                        }
                    },
                    else => return error.ValueUseLoadReadonlyPointerProvenance,
                }
            },
            .load_stack_i128_alias => {},
            .load_readonly_table_i16 => {
                mappings.append(.{ .source = null, .destination = .r8, .source_request_index = null });
                switch (current orelse return error.ValueUseUnresolvedSource) {
                    .readonly_table_ptr => |ptr| switch (ptr.storage) {
                        .reg => {},
                        .spill => |frame_index| mappings.append(.{
                            .source = scalarSourceNode(.{ .spill64 = frame_index }),
                            .destination = .rcx,
                            .source_request_index = request_index,
                        }),
                    },
                    else => return error.ValueUseLoadReadonlyTableType,
                }
            },
            .scratch_compare => |*compare| {
                const plan = try control_compare.classifyScratchCompare(compare);
                mappings.append(.{
                    .source = scalarSourceNode(current orelse return error.ValueUseUnresolvedSource),
                    .destination = nodeForArgReg(plan.lhs_register),
                    .source_request_index = request_index,
                });
                switch (compare.rhs) {
                    .named => |handle| mappings.append(.{
                        .source = scalarSourceNode(try Authority.registeredOperandCurrent(Authority, transaction, handle)),
                        .destination = nodeForArgReg(plan.rhs_register orelse
                            return error.ValueUseScratchCompareFormUnsupported),
                        .source_request_index = handle.index,
                    }),
                    .immediate => if (plan.immediate_register) |reg| mappings.append(.{
                        .source = null,
                        .destination = nodeForArgReg(reg),
                        .source_request_index = null,
                    }),
                    .null_pointer => {},
                }
                mappings.append(.{
                    .source = null,
                    .destination = .accumulator,
                    .source_request_index = null,
                });
            },
            .current_home_eq_zero => {
                mappings.append(.{
                    .source = null,
                    .destination = .rcx,
                    .source_request_index = null,
                });
                mappings.append(.{
                    .source = null,
                    .destination = .accumulator,
                    .source_request_index = null,
                });
            },
            .setcc_eax_compare => mappings.append(.{
                .source = scalarSourceNode(current orelse return error.ValueUseUnresolvedSource),
                .destination = .accumulator,
                .source_request_index = request_index,
            }),
            .current_home_sign_bit => mappings.append(.{
                .source = scalarSourceNode(current orelse return error.ValueUseUnresolvedSource),
                .destination = .accumulator,
                .source_request_index = request_index,
            }),
            .i128_eq_min, .i128_sign_bit => {
                const destinations = try requestDestinationNodes(Authority, transaction, request, current);
                for (destinations.slice()) |destination| mappings.append(.{
                    .source = null,
                    .destination = destination,
                    .source_request_index = null,
                });
            },
            .pair_low_scalar_cast,
            .accumulator_scalar_cast,
            .sign_extend_scratch,
            .immediate_rhs_scalar,
            .immediate_lhs_scalar,
            => {
                const destinations = try requestDestinationNodes(Authority, transaction, request, current);
                for (destinations.slice()) |destination| mappings.append(.{
                    .source = null,
                    .destination = destination,
                    .source_request_index = null,
                });
            },
            .validate_shape, .emit_copy_to => {},
        }
        if (action != .emit_copy_to) return mappings;
    }
    const destinations = try requestDestinationNodes(Authority, transaction, request, current);
    if (current == null) {
        for (destinations.slice()) |destination| mappings.append(.{
            .source = null,
            .destination = destination,
            .source_request_index = null,
        });
        return mappings;
    }
    if (request.form == .pair_low_high or request.form == .pair_high_low) {
        const source_nodes = pairSourceNodes(current.?);
        const low = source_nodes[0];
        const high = source_nodes[1];
        if (request.form == .pair_low_high) {
            mappings.append(.{ .source = low, .destination = destinations.items[0], .source_request_index = request_index });
            mappings.append(.{ .source = high, .destination = destinations.items[1], .source_request_index = request_index });
        } else {
            mappings.append(.{ .source = high, .destination = destinations.items[0], .source_request_index = request_index });
            mappings.append(.{ .source = low, .destination = destinations.items[1], .source_request_index = request_index });
        }
        return mappings;
    }
    mappings.append(.{
        .source = scalarSourceNode(current.?),
        .destination = destinations.items[0],
        .source_request_index = request_index,
    });
    return mappings;
}
pub fn actionOwnsOrderedWrites(action: Types.PreparedAction) bool {
    return switch (action) {
        .store_scalar,
        .store_immediate,
        .store_i64,
        .store_stack_pointer,
        .branch_condition,
        .switch_compare_chain,
        .inline_memcpy,
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
        .immediate_rhs_scalar,
        .immediate_lhs_scalar,
        => true,
        .validate_shape,
        .emit_copy_to,
        .form_byte_address,
        .form_scaled_address,
        .form_readonly_table_address,
        => false,
    };
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
fn appendStorePointerDestinationNodes(
    nodes: *NodeList,
    pointer: ValueLoc,
    bits: u8,
) !void {
    switch (pointer) {
        .stack_scalar => |stack| if (bits != 1 or stack.kind != .integer or stack.bits != 8)
            return error.ValueUseStorePointerFormUnsupported,
        .arg64, .scratch64 => if (bits != 32)
            return error.ValueUseStorePointerFormUnsupported,
        .spill64 => {
            if (bits != 32) return error.ValueUseStorePointerFormUnsupported;
            try nodes.append(.rcx);
        },
        .stack_i32_ptr => |ptr| {
            if (bits != 32) return error.ValueUseStorePointerFormUnsupported;
            if (ptr.index != null) try nodes.append(.rcx);
            if (ptr.index != null and ptr.index.?.addend_name != null) try nodes.append(.r8);
        },
        .stack_i32_array => if (bits != 32)
            return error.ValueUseStorePointerFormUnsupported,
        .readonly_table_ptr => return error.ValueUseStoreReadOnlyPointer,
        else => return error.ValueUseStorePointerFormUnsupported,
    }
}
fn appendStorePointerMappings(
    comptime Authority: type,
    transaction: anytype,
    mappings: *MappingList,
    pointer: ValueLoc,
    source_request_index: ?u8,
    bits: u8,
) !void {
    switch (pointer) {
        .stack_scalar => |stack| if (bits != 1 or stack.kind != .integer or stack.bits != 8)
            return error.ValueUseStorePointerFormUnsupported,
        .arg64, .scratch64 => if (bits != 32)
            return error.ValueUseStorePointerFormUnsupported,
        .spill64 => {
            if (bits != 32) return error.ValueUseStorePointerFormUnsupported;
            mappings.append(.{ .source = null, .destination = .rcx, .source_request_index = source_request_index });
        },
        .stack_i32_ptr => |ptr| {
            if (bits != 32) return error.ValueUseStorePointerFormUnsupported;
            if (ptr.index) |index| {
                mappings.append(.{
                    .source = scalarSourceNode(try Authority.materialization.resolveNamedCurrent(Authority, transaction, index.name)),
                    .destination = .rcx,
                    .source_request_index = source_request_index,
                });
                if (index.addend_name) |addend_name| mappings.append(.{
                    .source = scalarSourceNode(try Authority.materialization.resolveNamedCurrent(Authority, transaction, addend_name)),
                    .destination = .r8,
                    .source_request_index = source_request_index,
                });
            }
        },
        .stack_i32_array => if (bits != 32)
            return error.ValueUseStorePointerFormUnsupported,
        .readonly_table_ptr => return error.ValueUseStoreReadOnlyPointer,
        else => return error.ValueUseStorePointerFormUnsupported,
    }
}
fn validateI64StorePointer(pointer: ValueLoc) !void {
    switch (pointer) {
        .arg64, .scratch64, .spill64 => {},
        else => return error.ValueUseStorePointerFormUnsupported,
    }
}
fn validateStackPointerStoreViews(source: ValueLoc, destination: ValueLoc) !void {
    const source_stack = switch (source) {
        .stack_scalar => |stack| stack,
        else => return error.ValueUseStorePointerFormUnsupported,
    };
    const destination_stack = switch (destination) {
        .stack_scalar => |stack| stack,
        else => return error.ValueUseStorePointerFormUnsupported,
    };
    _ = source_stack;
    if (destination_stack.kind != .integer or destination_stack.bits != 64) {
        return error.ValueUseStorePointerFormUnsupported;
    }
}
fn validateCopyActionForm(
    form: Types.UseForm,
    destination: Types.CopyDestination,
) !void {
    const valid = switch (form) {
        .gpr32 => destination == .gpr32 or destination == .eax,
        .gpr64, .pointer, .stack_object_address => destination == .gpr64 or destination == .rax,
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
        .immediate_rhs_scalar_operand,
        .immediate_lhs_scalar_operand,
        => false,
        .stack_argument => return error.ValueUseStackArgumentUnsupported,
        .new_pair_ownership => return error.ValueUseNewPairOwnershipUnsupported,
    };
    if (!valid) return error.ValueUsePreparedActionFormMismatch;
}
fn rejectCopyCycles(graph: [Types.physical_node_count][Types.physical_node_count]bool) !void {
    var states = [_]CopyVisitState{.unseen} ** Types.physical_node_count;
    for (0..Types.physical_node_count) |node| try visitCopyNode(graph, node, &states);
}
fn visitCopyNode(
    graph: [Types.physical_node_count][Types.physical_node_count]bool,
    node: usize,
    states: *[Types.physical_node_count]CopyVisitState,
) !void {
    switch (states[node]) {
        .complete => return,
        .visiting => return error.ValueUseCopyCycleRequiresO4,
        .unseen => states[node] = .visiting,
    }
    for (graph[node], 0..) |edge, destination| if (edge) try visitCopyNode(graph, destination, states);
    states[node] = .complete;
}
fn rejectSemanticOrderCycles(
    graph: [Types.max_requests][Types.max_requests]bool,
    request_count: u8,
) !void {
    var states = [_]CopyVisitState{.unseen} ** Types.max_requests;
    for (0..request_count) |node| try visitSemanticOrderNode(graph, node, request_count, &states);
}
fn visitSemanticOrderNode(
    graph: [Types.max_requests][Types.max_requests]bool,
    node: usize,
    request_count: u8,
    states: *[Types.max_requests]CopyVisitState,
) !void {
    switch (states[node]) {
        .complete => return,
        .visiting => return error.ValueUseEarlyOrderingCycle,
        .unseen => states[node] = .visiting,
    }
    for (graph[node][0..request_count], 0..) |edge, destination| {
        if (edge) try visitSemanticOrderNode(graph, destination, request_count, states);
    }
    states[node] = .complete;
}
fn firstMappingDestination(request_index: u8, mappings: []const Mapping) ?Types.PhysicalNode {
    var result: ?Types.PhysicalNode = null;
    for (mappings) |mapping| {
        if (mapping.source_request_index != request_index) continue;
        if (result == null or @intFromEnum(mapping.destination) < @intFromEnum(result.?))
            result = mapping.destination;
    }
    return result;
}
fn sourceStructuralOrder(
    lhs: *const Types.Source,
    rhs: *const Types.Source,
) std.math.Order {
    const lhs_tag = std.meta.activeTag(lhs.*);
    const rhs_tag = std.meta.activeTag(rhs.*);
    if (@intFromEnum(lhs_tag) < @intFromEnum(rhs_tag)) return .lt;
    if (@intFromEnum(lhs_tag) > @intFromEnum(rhs_tag)) return .gt;
    return switch (lhs.*) {
        .named => |*name| std.mem.order(u8, name.slice(), rhs.named.slice()),
        .int => |integer| std.math.order(integer, rhs.int),
        .null_value, .unsupported => .eq,
    };
}
pub fn validateBindingCompatibility(
    binding: ValueBinding,
    request: *const Types.StoredRequest,
    current: ValueLoc,
) !void {
    if (request.form == .scratch_compare_operand) {
        try validateScratchCompareBinding(binding, request.expected, current);
        return;
    }
    if (request.form == .current_home_eq_zero_operand) {
        // The canonical post-preamble home is the authority. Resolution and
        // liveness happen now; width/location classification is intentionally
        // deferred until the action refreshes after accumulator preservation.
        try validateExpectedType(request.expected, request.form);
        return;
    }
    if (request.form == .setcc_eax_compare_operand) {
        // The action re-resolves after its live-accumulator preamble. Only
        // semantic typing is stable at seal; canonical width/home admission
        // is request-scoped and happens after that relocation.
        try validateExpectedType(request.expected, request.form);
        return;
    }
    if (request.form == .current_home_sign_bit_operand) {
        // Width and canonical-home admission occur after both action-owned
        // preservation phases. Seal validates only the stable semantic type.
        try validateExpectedType(request.expected, request.form);
        return;
    }
    if (request.form == .i128_icmp_pair_operand) {
        // The pair wrapper owns the strict post-preamble home fence. Seal
        // checks only the stable semantic i128 request and its binding width.
        try validateExpectedType(request.expected, request.form);
        if (binding.vreg.class != .gpr128 or binding.vreg.bits < 128)
            return error.ValueUseI128PairWidthUnsupported;
        return;
    }
    if (request.form == .pair_low_scalar_cast_operand) {
        try validateExpectedType(request.expected, request.form);
        if (binding.vreg.class != .gpr128 or binding.vreg.bits < 128)
            return error.ValueUseScalarCastWidthUnsupported;
        return;
    }
    if (request.form == .accumulator_scalar_cast_operand) {
        try validateExpectedType(request.expected, request.form);
        const bits = request.expected.ty.int;
        const valid_class = if (bits <= 32)
            binding.vreg.class == .gpr32 or binding.vreg.class == .gpr64
        else
            binding.vreg.class == .gpr64;
        if (!valid_class or binding.vreg.bits < bits)
            return error.ValueUseScalarCastWidthUnsupported;
        return;
    }
    if (request.form == .sign_extend_scratch_operand) {
        try validateExpectedType(request.expected, request.form);
        if (binding.vreg.class != .gpr32 or binding.vreg.bits < 32)
            return error.ValueUseScalarCastWidthUnsupported;
        return;
    }
    if (request.form == .immediate_rhs_scalar_operand or
        request.form == .immediate_lhs_scalar_operand)
    {
        try validateExpectedType(request.expected, request.form);
        const bits = request.expected.ty.int;
        const valid_class = if (bits <= 32)
            binding.vreg.class == .gpr32 or binding.vreg.class == .gpr64
        else
            binding.vreg.class == .gpr64;
        if (!valid_class or binding.vreg.bits < bits)
            return error.ValueUseImmediateScalarWidthUnsupported;
        return;
    }
    if (request.form == .load_address) {
        try validateExpectedType(request.expected, request.form);
        const action = request.prepared_action orelse
            return error.ValueUsePreparedActionMissing;
        switch (action) {
            .load_scalar => |load| switch (load.kind) {
                .ordinary => try validateOrdinaryLoadHome(binding, current, load.bits, false),
                .readonly_pointer => try validateReadOnlyPointerLoadHome(binding, current),
            },
            .load_readonly_pair => try validateReadOnlyPointerLoadHome(binding, current),
            .load_stack_i128_alias => try validateOrdinaryLoadHome(binding, current, 128, true),
            .load_readonly_table_i16 => try validateReadOnlyTableLoadHome(binding, current),
            else => return error.ValueUsePreparedActionFormMismatch,
        }
        return;
    }
    if (request.form == .memcpy_pointer or request.form == .memcpy_length) {
        try validateExpectedType(request.expected, request.form);
        if (binding.vreg.bits < 64) return if (request.form == .memcpy_pointer)
            error.ValueUseMemcpyPointerWidthMismatch
        else
            error.ValueUseMemcpyLengthWidthMismatch;
        const accepted_class = binding.vreg.class == .gpr64 or binding.vreg.class == .gpr128;
        const accepted_home = switch (current) {
            .arg64, .scratch64, .rax, .spill64, .arg128, .scratch128 => true,
            else => false,
        };
        if (!accepted_class or !accepted_home)
            return if (request.form == .memcpy_pointer)
                error.ValueUseMemcpyPointerHomeUnsupported
            else
                error.ValueUseMemcpyLengthHomeUnsupported;
        return;
    }
    if (request.form == .branch_condition) {
        try validateExpectedType(request.expected, request.form);
        if (binding.vreg.bits < 1) return error.ValueUseBranchConditionWidthMismatch;
        const accepted = switch (current) {
            .eax, .arg32, .scratch32 => binding.vreg.class == .gpr32,
            .spill64 => binding.vreg.class == .gpr32 or binding.vreg.class == .gpr64,
            else => false,
        };
        if (!accepted) return error.ValueUseBranchConditionHomeUnsupported;
        return;
    }
    if (request.form == .switch_condition) {
        try validateExpectedType(request.expected, request.form);
        const bits = request.expected.ty.int;
        if (binding.vreg.bits < bits) return error.ValueUseSwitchConditionWidthMismatch;
        const accepted = switch (current) {
            .eax, .arg32, .scratch32 => binding.vreg.class == .gpr32,
            .arg64, .scratch64, .rax, .spill64 => binding.vreg.class == .gpr32 or binding.vreg.class == .gpr64,
            .arg128, .scratch128 => binding.vreg.class == .gpr128,
            else => false,
        };
        if (!accepted) return error.ValueUseSwitchConditionHomeUnsupported;
        return;
    }
    if (binding.vreg.class == request.expected.register_class) {
        try validateExpectedType(request.expected, request.form);
        return;
    }
    if (request.form != .gpr32 or request.expected.register_class != .gpr32 or
        request.expected.ty != .int or request.expected.ty.int == 0 or
        request.expected.ty.int > 32 or binding.vreg.class != .gpr64 or
        binding.vreg.bits < request.expected.ty.int or !hasLow32View(current))
    {
        return error.ValueUseRegisterClassMismatch;
    }
    try validateExpectedType(request.expected, request.form);
}
fn validateScratchCompareBinding(
    binding: ValueBinding,
    expected: Types.Expected,
    current: ValueLoc,
) !void {
    try validateExpectedType(expected, .scratch_compare_operand);
    const bits: u16 = switch (expected.ty) {
        .int => |value| value,
        .ptr => 64,
        else => unreachable,
    };
    if (binding.vreg.bits < bits) return error.ValueUseScratchCompareWidthMismatch;
    const accepted = if (bits <= 32) switch (current) {
        .eax, .arg32, .scratch32 => binding.vreg.class == .gpr32,
        .rax, .arg64, .scratch64, .spill64 => binding.vreg.class == .gpr32 or
            binding.vreg.class == .gpr64,
        .arg128, .scratch128 => binding.vreg.class == .gpr128,
        else => false,
    } else switch (current) {
        .rax, .arg64, .scratch64, .spill64 => binding.vreg.class == .gpr64,
        .arg128, .scratch128 => binding.vreg.class == .gpr128,
        else => false,
    };
    if (!accepted) return error.ValueUseScratchCompareHomeUnsupported;
}
fn validateOrdinaryLoadHome(
    binding: ValueBinding,
    current: ValueLoc,
    bits: u16,
    alias_i128: bool,
) !void {
    switch (current) {
        .stack_scalar => |stack| {
            if (alias_i128 or binding.vreg.class != .stack_object or stack.kind != .integer or
                stack.bits != bits or (bits != 8 and bits != 64))
            {
                return error.ValueUseLoadOrdinaryStackWidth;
            }
        },
        .stack128 => {
            if (!alias_i128 or binding.vreg.class != .stack_object)
                return error.ValueUseLoadOrdinaryStackWidth;
        },
        .stack_i32_array => {
            if (alias_i128 or binding.vreg.class != .stack_object or bits != 32)
                return error.ValueUseLoadOrdinaryStackArrayWidth;
        },
        .stack_i32_ptr => {
            if (alias_i128 or binding.vreg.class != .stack_pointer or bits != 32)
                return error.ValueUseLoadOrdinaryStackArrayWidth;
        },
        .arg64, .scratch64, .spill64 => {
            if (alias_i128 or binding.vreg.class != .gpr64 or binding.vreg.bits < 64 or bits != 32)
                return error.ValueUseLoadOrdinaryPointerWidth;
        },
        else => return error.ValueUseLoadOrdinaryPointerRejected,
    }
}
fn validateReadOnlyPointerLoadHome(binding: ValueBinding, current: ValueLoc) !void {
    switch (current) {
        .arg64, .scratch64, .spill64 => if (binding.vreg.class != .gpr64 or binding.vreg.bits < 64)
            return error.ValueUseLoadReadonlyPointerProvenance,
        else => return error.ValueUseLoadReadonlyPointerProvenance,
    }
}
fn validateReadOnlyTableLoadHome(binding: ValueBinding, current: ValueLoc) !void {
    switch (current) {
        .readonly_table_ptr => |ptr| {
            if (binding.vreg.class != .stack_pointer)
                return error.ValueUseLoadReadonlyTableType;
            if (!ptr.shape.allowsOffset(ptr.offset))
                return error.ValueUseLoadReadonlyTableOffset;
        },
        else => return error.ValueUseLoadReadonlyTableType,
    }
}
fn hasLow32View(loc: ValueLoc) bool {
    return switch (loc) {
        .arg64, .scratch64, .rax, .spill64 => true,
        else => false,
    };
}
fn validateExpectedType(expected: Types.Expected, form: Types.UseForm) !void {
    switch (form) {
        .gpr32 => if (expected.ty != .int or expected.ty.int == 0 or expected.ty.int > 32 or expected.register_class != .gpr32)
            return error.ValueUseTypeMismatch,
        .gpr64 => if (expected.ty != .int or expected.ty.int <= 32 or expected.ty.int > 64 or expected.register_class != .gpr64)
            return error.ValueUseTypeMismatch,
        .pointer => {
            if (expected.ty != .ptr or
                (expected.register_class != .gpr64 and expected.register_class != .stack_pointer) or
                expected.pointer_address_space == null or expected.pointer_address_space.? != 0)
            {
                return error.ValueUseTypeMismatch;
            }
        },
        .stack_f32_pair_byte_address => {
            if (expected.ty != .ptr or
                expected.register_class != .stack_pointer or
                expected.pointer_address_space == null or expected.pointer_address_space.? != 0)
            {
                return error.ValueUseTypeMismatch;
            }
        },
        .stack_object_address => {
            if (expected.ty != .ptr or
                expected.register_class != .stack_object or
                expected.pointer_address_space == null or expected.pointer_address_space.? != 0)
            {
                return error.ValueUseTypeMismatch;
            }
        },
        .pair_low_high, .pair_high_low => if (!expected.ty.eql(.{ .int = 128 }) or expected.register_class != .gpr128)
            return error.ValueUseTypeMismatch,
        .branch_condition => if (!expected.ty.eql(.{ .int = 1 }) or expected.register_class != .gpr32)
            return error.ValueUseTypeMismatch,
        .switch_condition => if (expected.ty != .int or expected.ty.int == 0 or
            expected.ty.int > 32 or expected.register_class != .gpr32)
        {
            return error.ValueUseTypeMismatch;
        },
        .memcpy_pointer => {
            if (expected.ty != .ptr or expected.register_class != .gpr64 or
                expected.pointer_address_space == null or expected.pointer_address_space.? != 0)
            {
                return error.ValueUseTypeMismatch;
            }
        },
        .memcpy_length => if (!expected.ty.eql(.{ .int = 64 }) or expected.register_class != .gpr64)
            return error.ValueUseTypeMismatch,
        .load_address => if (expected.ty != .ptr or expected.register_class != .stack_pointer or
            expected.pointer_address_space == null or expected.pointer_address_space.? != 0)
        {
            return error.ValueUseTypeMismatch;
        },
        .scratch_compare_operand => switch (expected.ty) {
            .int => |bits| {
                if (bits == 0 or bits > 64 or
                    expected.register_class != if (bits <= 32)
                        VirtualRegClass.gpr32
                    else
                        VirtualRegClass.gpr64)
                {
                    return error.ValueUseTypeMismatch;
                }
            },
            .ptr => {
                if (expected.register_class != .gpr64 or
                    expected.pointer_address_space == null or
                    expected.pointer_address_space.? != 0)
                {
                    return error.ValueUseTypeMismatch;
                }
            },
            else => return error.ValueUseTypeMismatch,
        },
        .current_home_eq_zero_operand => switch (expected.ty) {
            .int => |bits| {
                if (bits == 0 or bits > 64 or
                    expected.register_class != if (bits <= 32)
                        VirtualRegClass.gpr32
                    else
                        VirtualRegClass.gpr64)
                {
                    return error.ValueUseTypeMismatch;
                }
            },
            else => return error.ValueUseTypeMismatch,
        },
        .setcc_eax_compare_operand => switch (expected.ty) {
            .int => |bits| {
                if (bits == 0 or bits > 64 or
                    expected.register_class != if (bits <= 32)
                        VirtualRegClass.gpr32
                    else
                        VirtualRegClass.gpr64)
                {
                    return error.ValueUseTypeMismatch;
                }
            },
            else => return error.ValueUseTypeMismatch,
        },
        .current_home_sign_bit_operand => switch (expected.ty) {
            .int => |bits| {
                if (bits == 0 or bits > 64 or
                    expected.register_class != if (bits <= 32)
                        VirtualRegClass.gpr32
                    else
                        VirtualRegClass.gpr64)
                {
                    return error.ValueUseTypeMismatch;
                }
            },
            else => return error.ValueUseTypeMismatch,
        },
        .i128_icmp_pair_operand => if (!expected.ty.eql(.{ .int = 128 }) or
            expected.register_class != .gpr128 or
            expected.pointer_address_space != null)
        {
            return error.ValueUseTypeMismatch;
        },
        .pair_low_scalar_cast_operand => if (!expected.ty.eql(.{ .int = 128 }) or
            expected.register_class != .gpr128 or expected.pointer_address_space != null)
        {
            return error.ValueUseTypeMismatch;
        },
        .accumulator_scalar_cast_operand => switch (expected.ty) {
            .int => |bits| {
                if (bits == 0 or bits > 64 or
                    expected.register_class != if (bits <= 32)
                        VirtualRegClass.gpr32
                    else
                        VirtualRegClass.gpr64)
                {
                    return error.ValueUseTypeMismatch;
                }
            },
            else => return error.ValueUseTypeMismatch,
        },
        .sign_extend_scratch_operand => if (!expected.ty.eql(.{ .int = 32 }) or
            expected.register_class != .gpr32 or expected.pointer_address_space != null)
        {
            return error.ValueUseTypeMismatch;
        },
        .immediate_rhs_scalar_operand, .immediate_lhs_scalar_operand => switch (expected.ty) {
            .int => |bits| {
                if (bits == 0 or bits > 64 or
                    expected.register_class != if (bits <= 32)
                        VirtualRegClass.gpr32
                    else
                        VirtualRegClass.gpr64)
                {
                    return error.ValueUseTypeMismatch;
                }
            },
            else => return error.ValueUseTypeMismatch,
        },
        .stack_argument => return error.ValueUseStackArgumentUnsupported,
        .new_pair_ownership => return error.ValueUseNewPairOwnershipUnsupported,
    }
}
fn validateSourceView(loc: ValueLoc, form: Types.UseForm) !void {
    switch (form) {
        .gpr32 => switch (loc) {
            .arg32, .scratch32, .arg64, .scratch64, .eax, .rax, .spill64 => {},
            .xmm => return error.ValueUseXmmUnsupported,
            .aggregate_sse => return error.ValueUseAggregateUnsupported,
            else => return error.ValueUseSourceViewMismatch,
        },
        .gpr64 => switch (loc) {
            .arg64, .scratch64, .rax, .spill64 => {},
            .xmm => return error.ValueUseXmmUnsupported,
            .aggregate_sse => return error.ValueUseAggregateUnsupported,
            else => return error.ValueUseSourceViewMismatch,
        },
        .pointer, .stack_object_address => switch (loc) {
            .arg64, .scratch64, .rax, .spill64, .stack_scalar, .stack128, .stack_i32_array, .stack_i32_ptr, .readonly_table_ptr => {},
            .stack_f32_pair_ptr, .stack128_value => return error.ValueUseUnsupportedAddressForm,
            .xmm => return error.ValueUseXmmUnsupported,
            .aggregate_sse => return error.ValueUseAggregateUnsupported,
            else => return error.ValueUseSourceViewMismatch,
        },
        .stack_f32_pair_byte_address => switch (loc) {
            .stack_f32_pair_ptr => {},
            else => return error.ValueUseSourceViewMismatch,
        },
        .pair_low_high, .pair_high_low => switch (loc) {
            .arg128, .scratch128, .spill128 => {},
            .xmm => return error.ValueUseXmmUnsupported,
            .aggregate_sse => return error.ValueUseAggregateUnsupported,
            else => return error.ValueUseSourceViewMismatch,
        },
        .branch_condition => switch (loc) {
            .eax, .arg32, .scratch32, .spill64 => {},
            else => return error.ValueUseBranchConditionHomeUnsupported,
        },
        .switch_condition => switch (loc) {
            .eax,
            .rax,
            .arg32,
            .scratch32,
            .arg64,
            .scratch64,
            .arg128,
            .scratch128,
            .spill64,
            => {},
            else => return error.ValueUseSwitchConditionHomeUnsupported,
        },
        .memcpy_pointer, .memcpy_length => switch (loc) {
            .arg64, .scratch64, .rax, .spill64, .arg128, .scratch128 => {},
            else => return error.ValueUseSourceViewMismatch,
        },
        .load_address => switch (loc) {
            .arg64,
            .scratch64,
            .spill64,
            .stack_scalar,
            .stack128,
            .stack_i32_array,
            .stack_i32_ptr,
            .readonly_table_ptr,
            => {},
            .xmm => return error.ValueUseXmmUnsupported,
            .aggregate_sse => return error.ValueUseAggregateUnsupported,
            else => return error.ValueUseLoadAddressHomeUnsupported,
        },
        .scratch_compare_operand => switch (loc) {
            .eax,
            .rax,
            .arg32,
            .scratch32,
            .arg64,
            .scratch64,
            .arg128,
            .scratch128,
            .spill64,
            => {},
            else => return error.ValueUseScratchCompareHomeUnsupported,
        },
        // The action must inspect the canonical home only after the accepted
        // live-accumulator preamble. No home is admitted by this generic
        // validation layer.
        .current_home_eq_zero_operand => {},
        // Canonical admission occurs after the action-owned preamble. Pair
        // and spill128 homes are rejected there, preserving the O2-6 frontier.
        .setcc_eax_compare_operand => {},
        // The action owns both preservation phases and classifies the
        // canonical i32/i64 home only after re-resolution.
        .current_home_sign_bit_operand => {},
        // Strict pair-home admission follows the established preamble and
        // canonical refresh inside the two closed wrapper actions. Their
        // exact semantic classifiers fence the admitted spill128 view.
        .i128_icmp_pair_operand => {},
        .pair_low_scalar_cast_operand,
        .accumulator_scalar_cast_operand,
        .sign_extend_scratch_operand,
        .immediate_rhs_scalar_operand,
        .immediate_lhs_scalar_operand,
        => {},
        .stack_argument => return error.ValueUseStackArgumentUnsupported,
        .new_pair_ownership => return error.ValueUseNewPairOwnershipUnsupported,
    }
}
fn earlyCopyIsFlagsPreserving(loc: ValueLoc, form: Types.UseForm) bool {
    return switch (form) {
        .gpr32 => switch (loc) {
            .arg32, .scratch32, .arg64, .scratch64, .eax, .rax, .spill64 => true,
            else => false,
        },
        .gpr64 => switch (loc) {
            .arg64, .scratch64, .rax, .spill64 => true,
            else => false,
        },
        .pointer => switch (loc) {
            .arg64, .scratch64, .rax, .spill64, .readonly_table_ptr => true,
            else => false,
        },
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
        .stack_argument,
        .new_pair_ownership,
        => false,
    };
}
pub fn scalarSourceNode(loc: ValueLoc) ?Types.PhysicalNode {
    return Types.PhysicalNode.scalarSource(loc);
}
pub fn pairSourceNodes(loc: ValueLoc) [2]?Types.PhysicalNode {
    return Types.PhysicalNode.pairSources(loc);
}
pub fn nodeForArgReg(reg: ArgReg) Types.PhysicalNode {
    return Types.PhysicalNode.fromArgReg(reg);
}
pub fn argRegForNode(node: Types.PhysicalNode) ?ArgReg {
    return node.argReg();
}
