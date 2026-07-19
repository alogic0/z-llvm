const std = @import("std");
const x86_64_types = @import("../../../types.zig");
const selector_types = @import("../../selector_types.zig");
const selector_state = @import("../../composed_selector_state.zig");
const Types = @import("../model.zig");
const planning_model = @import("model.zig");
const compatibility = @import("compatibility.zig");

const ArgReg = x86_64_types.ArgReg;
const ValueLoc = selector_types.ValueLoc;
const Mapping = planning_model.Mapping;
const CopyVisitState = planning_model.CopyVisitState;
const PhysicalNode = planning_model.PhysicalNode;
const max_requests = Types.max_requests;
const physical_node_count = Types.physical_node_count;
const PreparedAction = Types.PreparedAction;
const OperandPhase = Types.OperandPhase;
const SemanticRole = Types.SemanticRole;
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
        .named_scalar_binary => |named| try Authority.validateRegisteredOperandHandle(Authority, transaction, named.rhs),
        .exact_i52_binary => |named| try Authority.validateRegisteredOperandHandle(Authority, transaction, named.rhs),
        .scalar_multiply => |multiply| try Authority.validateRegisteredOperandHandle(Authority, transaction, multiply.rhs),
        .unsigned_quotient => |quotient| try Authority.validateRegisteredOperandHandle(Authority, transaction, quotient.rhs),
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
        .direct_call,
        .int_byte_size_call,
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
        .named_scalar_binary,
        .exact_i52_binary,
        .scalar_multiply,
        .unsigned_quotient,
        .direct_call,
        .int_byte_size_call,
        => null,
    };
}
pub fn resetSemanticOrderPlan(comptime _: type, transaction: anytype) void {
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
            Authority.planning.argRegForNode(mapping.destination) != null and
            selector_state.scratchRegIsProvenFree(
                transaction.selector,
                Authority.planning.argRegForNode(mapping.destination).?,
            ))
        {
            const request = &transaction.requests[request_index];
            const current = switch (request.source) {
                .named => try Authority.planning.validateRequestAt(Authority, transaction, request_index) orelse null,
                .int, .null_value, .unsupported => null,
            };
            if (current != null and earlySequencingCandidate(current.?, request.form)) {
                operand_phase = .safe_early;
                destination = Authority.planning.argRegForNode(mapping.destination).?;
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
        .gpr32, .gpr64 => |reg| PhysicalNode.fromArgReg(reg),
        .eax, .rax => .accumulator,
        .pair => |pair| @enumFromInt(@min(
            @intFromEnum(PhysicalNode.fromArgReg(pair.lo)),
            @intFromEnum(PhysicalNode.fromArgReg(pair.hi)),
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
    switch (request.source) {
        .named => {},
        .int, .null_value, .unsupported => return error.ValueUseEarlySourceNotNamed,
    }
    const binding = requestSourceBinding(transaction, index) orelse
        return if (transaction.lifetime_context.forward_snapshots[index] != null)
            error.ValueUseForwardPlanStale
        else
            error.ValueUseUnresolvedSource;
    if (!std.meta.eql(binding.vreg, transaction.early_homes[index].source_vreg))
        return error.ValueUsePreparedViewStale;
    _ = try Authority.planning.validateRequestAt(Authority, transaction, index);
    try compatibility.validateExpectedType(request.expected, request.form);
    try compatibility.validateSourceView(transaction.early_homes[index].loc, request.form);
}
fn requestSourceBinding(transaction: anytype, index: u8) ?selector_types.ValueBinding {
    const request = &transaction.requests[index];
    const name = switch (request.source) {
        .named => |*identity| identity.slice(),
        .int, .null_value, .unsupported => return null,
    };
    if (transaction.selector.values.get(name)) |binding| return binding;
    const snapshot = transaction.lifetime_context.forward_snapshots[index] orelse return null;
    return .{
        .vreg = snapshot.virtualReg(),
        .loc = switch (snapshot.assignment) {
            .gpr32 => |reg| .{ .scratch32 = reg },
            .gpr64 => |reg| .{ .scratch64 = reg },
            .spill => |spill_index| .{
                .spill64 = selector_state.spillFrameIndexMaybe(spill_index) orelse return null,
            },
        },
    };
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
        .named_scalar_operand => false,
        else => false,
    };
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
        .named_scalar_binary,
        .exact_i52_binary,
        .scalar_multiply,
        .unsigned_quotient,
        .direct_call,
        .int_byte_size_call,
        => true,
        .validate_shape,
        .emit_copy_to,
        .form_byte_address,
        .form_scaled_address,
        .form_readonly_table_address,
        => false,
    };
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
        .named_scalar_operand,
        .stack_argument,
        .new_pair_ownership,
        => false,
    };
}
