const std = @import("std");
const ir = @import("../../../../../ir.zig");
const x86_64_types = @import("../../../types.zig");
const selector_types = @import("../../selector_types.zig");
const state_data = @import("../../composed_selector_state_data.zig");
const selector_state = @import("../../composed_selector_state.zig");
const Types = @import("../model.zig");
const control_compare = @import("../actions/control_compare.zig");
const planning_model = @import("model.zig");
const compatibility = @import("compatibility.zig");
const lifetime_admission = @import("lifetime_admission.zig");
const semantic_ordering = @import("semantic_ordering.zig");

const ArgReg = x86_64_types.ArgReg;
const RegPair = selector_types.RegPair;
const ValueLoc = selector_types.ValueLoc;
const ComposedBlockSelector = state_data.ComposedBlockSelector;
const Mapping = planning_model.Mapping;
const CopyVisitState = planning_model.CopyVisitState;
const ActionIdentity = Types.ActionIdentity;
const physical_node_count = Types.physical_node_count;
const max_mappings = Types.max_mappings;
const NodeList = struct {
    items: [7]Types.PhysicalNode = undefined,
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

const MappingList = struct {
    items: [7]Mapping = undefined,
    len: u8 = 0,

    fn append(list: *MappingList, mapping: Mapping) void {
        list.items[list.len] = mapping;
        list.len += 1;
    }

    fn slice(list: *const MappingList) []const Mapping {
        return list.items[0..list.len];
    }
};

pub fn seal(comptime Authority: type, transaction: anytype) !void {
    try Authority.requireActive(Authority, transaction);
    if (transaction.request_phase != .registering) return error.ValueUsePlanAlreadySealed;
    errdefer semantic_ordering.resetSemanticOrderPlan(Authority, transaction);
    // Validate the action-owned role graph before destination planning can
    // obscure a semantic ownership contradiction with a physical conflict.
    try semantic_ordering.validateSemanticOrderTopology(Authority, transaction);
    var destinations: [physical_node_count]bool = @splat(false);
    var graph: [physical_node_count][physical_node_count]bool = @splat(@splat(false));
    var writes: [physical_node_count]bool = @splat(false);
    var mappings: [max_mappings]Mapping = undefined;
    var mapping_count: usize = 0;

    for (transaction.requests[0..transaction.request_count], 0..) |*request, request_index_usize| {
        const request_index: u8 = @intCast(request_index_usize);
        const deferred_switch = request.prepared_action != null and
            request.prepared_action.? == .switch_compare_chain;
        if (deferred_switch) lifetime_admission.validateDeferredSwitchRequest(request) catch |err| {
            Authority.noteRequestBoundaryError(Authority, transaction, request_index, err);
            return err;
        };
        const current = if (deferred_switch) null else try lifetime_admission.validateRequestAt(Authority, transaction, request_index);
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
            semantic_ordering.actionOwnsOrderedWrites(request.prepared_action.?);
        for (request_mappings.slice()) |mapping| {
            if (mapping_count == mappings.len) return error.ValueUseMappingCapacityExceeded;
            mappings[mapping_count] = mapping;
            mapping_count += 1;
            if (mapping.source == null) {
                if (!deferred_writes) writes[@intFromEnum(mapping.destination)] = true;
                continue;
            }
            const source = mapping.source.?;
            if (source == mapping.destination) {
                // Byte GEP changes rcx even when staging its base/index is a
                // no-op. Preserve that canonical source before exposing views.
                if (mapping.destination == .rcx) if (request.prepared_action) |action| {
                    if (action == .form_byte_address) switch (action.form_byte_address.offset) {
                        .constant => |offset| if (offset != 0) {
                            writes[@intFromEnum(mapping.destination)] = true;
                        },
                        .request => writes[@intFromEnum(mapping.destination)] = true,
                    };
                };
                continue;
            }
            graph[@intFromEnum(source)][@intFromEnum(mapping.destination)] = true;
            if (!deferred_writes) writes[@intFromEnum(mapping.destination)] = true;
        }
    }
    try rejectCopyCycles(graph);
    try semantic_ordering.planEarlyMaterializations(Authority, transaction, mappings[0..mapping_count]);
    transaction.write_nodes = writes;
    transaction.request_phase = .sealed;
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
            .inline_memcpy, .inline_memset => {
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
            .named_scalar_binary, .exact_i52_binary => {
                try result.append(.rcx);
                try result.append(.rdx);
                try result.append(.accumulator);
            },
            .scalar_multiply => {
                for (selector_types.selector_allocatable_regs) |reg|
                    try result.append(nodeForArgReg(reg));
                try result.append(.accumulator);
            },
            .unsigned_quotient => {
                for (selector_types.selector_allocatable_regs) |reg|
                    try result.append(nodeForArgReg(reg));
                try result.append(.accumulator);
            },
            .direct_call, .int_byte_size_call => return error.ValueUsePreparedActionFormMismatch,
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
                try compatibility.validateI64StorePointer(pointer);
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
                try compatibility.validateStackPointerStoreViews(
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
            .inline_memset => |fill| {
                mappings.append(.{
                    .source = scalarSourceNode(current orelse return error.ValueUseUnresolvedSource),
                    .destination = .rdi,
                    .source_request_index = request_index,
                });
                mappings.append(.{
                    .source = if (fill.fill) |handle| scalarSourceNode(try Authority.registeredOperandCurrent(Authority, transaction, handle)) else null,
                    .destination = .rsi,
                    .source_request_index = if (fill.fill) |handle| handle.index else null,
                });
                mappings.append(.{
                    .source = if (fill.length) |handle| scalarSourceNode(try Authority.registeredOperandCurrent(Authority, transaction, handle)) else null,
                    .destination = .rdx,
                    .source_request_index = if (fill.length) |handle| handle.index else null,
                });
            },
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
            .named_scalar_binary,
            .exact_i52_binary,
            .scalar_multiply,
            .unsigned_quotient,
            => {
                const destinations = try requestDestinationNodes(Authority, transaction, request, current);
                for (destinations.slice()) |destination| mappings.append(.{
                    .source = null,
                    .destination = destination,
                    .source_request_index = null,
                });
            },
            .direct_call, .int_byte_size_call => return error.ValueUsePreparedActionFormMismatch,
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
fn appendStorePointerDestinationNodes(
    nodes: *NodeList,
    pointer: ValueLoc,
    bits: u8,
) !void {
    switch (pointer) {
        .stack_scalar => |stack| if ((bits != 1 and bits != 8) or stack.kind != .integer or stack.bits != 8)
            return error.ValueUseStorePointerFormUnsupported,
        .arg64, .scratch64 => if (bits != 8 and bits != 32 and bits != 64)
            return error.ValueUseStorePointerFormUnsupported,
        .spill64 => {
            if (bits != 8 and bits != 32 and bits != 64) return error.ValueUseStorePointerFormUnsupported;
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
        .stack_scalar => |stack| if ((bits != 1 and bits != 8) or stack.kind != .integer or stack.bits != 8)
            return error.ValueUseStorePointerFormUnsupported,
        .arg64, .scratch64 => if (bits != 8 and bits != 32 and bits != 64)
            return error.ValueUseStorePointerFormUnsupported,
        .spill64 => {
            if (bits != 8 and bits != 32 and bits != 64) return error.ValueUseStorePointerFormUnsupported;
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
fn rejectCopyCycles(graph: [Types.physical_node_count][Types.physical_node_count]bool) !void {
    var states: [Types.physical_node_count]CopyVisitState = @splat(.unseen);
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
