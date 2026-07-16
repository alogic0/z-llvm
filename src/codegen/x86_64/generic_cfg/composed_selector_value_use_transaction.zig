const std = @import("std");
const ir = @import("../../../ir.zig");
const x86_64_machine = @import("../machine.zig");
const x86_64_types = @import("../types.zig");
const selector_types = @import("selector_types.zig");
const state_data = @import("composed_selector_state_data.zig");
const selector_state = @import("composed_selector_state.zig");
const stage2_planning = @import("stage2_planning.zig");
const address_dependencies = @import("composed_selector_address_dependencies.zig");
const eflags = @import("composed_selector_eflags.zig");

const ArgReg = x86_64_types.ArgReg;
const FrameIndex = x86_64_types.FrameIndex;
const RegPair = selector_types.RegPair;
const ValueBinding = selector_types.ValueBinding;
const ValueLoc = selector_types.ValueLoc;
const VirtualRegClass = selector_types.VirtualRegClass;
const ComposedBlockSelector = state_data.ComposedBlockSelector;
const AddressDependencyDomain = address_dependencies.AddressDependencyDomain;

/// Dormant instruction-level authority for planning several value uses before
/// any selector mutation. O2-2 deliberately wires no production consumer to
/// this skeleton.
pub const ValueUseTransaction = struct {
    pub const max_requests = 16;
    pub const max_identity_bytes = 192;
    pub const address_domain_snapshot_copies: usize = 1;
    pub const address_domain_copies_per_request: usize = 0;
    pub const address_domain_snapshot_bytes: usize = @sizeOf(AddressDependencyDomain);

    selector: *ComposedBlockSelector,
    snapshot: Snapshot,
    requests: [max_requests]StoredRequest = undefined,
    request_count: u8 = 0,
    request_phase: RequestPhase = .registering,
    lifecycle: Lifecycle = .active,
    write_nodes: [physical_node_count]bool = [_]bool{false} ** physical_node_count,

    pub const Expected = struct {
        ty: ir.Type,
        register_class: VirtualRegClass,
        pointer_address_space: ?u32 = null,

        fn eql(expected: Expected, other: Expected) bool {
            return expected.ty.eql(other.ty) and
                expected.register_class == other.register_class and
                expected.pointer_address_space == other.pointer_address_space;
        }
    };

    pub const UseForm = enum {
        gpr32,
        gpr64,
        pointer,
        stack_object_address,
        pair_low_high,
        pair_high_low,
        stack_argument,
        new_pair_ownership,
    };

    pub const Destination = union(enum) {
        gpr32: ArgReg,
        gpr64: ArgReg,
        eax,
        rax,
        pair: RegPair,
        stack_argument: u32,
        new_pair,

        fn eql(destination: Destination, other: Destination) bool {
            if (std.meta.activeTag(destination) != std.meta.activeTag(other)) return false;
            return switch (destination) {
                .gpr32 => |reg| reg == other.gpr32,
                .gpr64 => |reg| reg == other.gpr64,
                .pair => |pair| pair.eql(other.pair),
                .stack_argument => |slot| slot == other.stack_argument,
                .eax, .rax, .new_pair => true,
            };
        }
    };

    pub const Request = struct {
        source: ir.Value,
        expected: Expected,
        form: UseForm,
        destination: Destination,
    };

    pub const RequestPhase = enum {
        registering,
        sealed,
        prepared,
        materializing,
        materialized,
        committed,
    };

    const Lifecycle = enum { active, committed, rolled_back };

    const Identity = struct {
        bytes: [max_identity_bytes]u8 = undefined,
        len: u8 = 0,

        fn init(name: []const u8) !Identity {
            if (name.len == 0) return error.ValueUseEmptyIdentity;
            if (name.len > max_identity_bytes) return error.ValueUseIdentityTooLong;
            var identity: Identity = .{};
            @memcpy(identity.bytes[0..name.len], name);
            identity.len = @intCast(name.len);
            return identity;
        }

        fn slice(identity: *const Identity) []const u8 {
            return identity.bytes[0..identity.len];
        }

        fn eql(identity: *const Identity, other: *const Identity) bool {
            return std.mem.eql(u8, identity.slice(), other.slice());
        }
    };

    const Source = union(enum) {
        named: Identity,
        null_value,
        unsupported,

        fn from(input: ir.Value) !Source {
            return switch (input) {
                .named => |name| .{ .named = try Identity.init(name) },
                .null_value => .null_value,
                .int, .fp, .undef, .poison, .zero_initializer, .vector, .constant_expr => .unsupported,
            };
        }

        fn eql(source: *const Source, other: *const Source) bool {
            if (std.meta.activeTag(source.*) != std.meta.activeTag(other.*)) return false;
            return switch (source.*) {
                .named => |*name| name.eql(&other.named),
                .null_value, .unsupported => true,
            };
        }

        fn value(source: *const Source) ir.Value {
            return switch (source.*) {
                .named => |*name| .{ .named = name.slice() },
                .null_value => .null_value,
                .unsupported => .undef,
            };
        }
    };

    const StoredRequest = struct {
        source: Source,
        expected: Expected,
        form: UseForm,
        destination: Destination,

        fn eql(request: *const StoredRequest, other: *const StoredRequest) bool {
            return request.source.eql(&other.source) and
                request.expected.eql(other.expected) and
                request.form == other.form and
                request.destination.eql(other.destination);
        }
    };

    const ValueEntry = struct {
        name: []const u8,
        binding: ValueBinding,
    };

    const SpillEntry = struct {
        name: []const u8,
        assignment: stage2_planning.SpillSlotAssignment,
    };

    const Snapshot = struct {
        instruction_len: usize,
        values: []ValueEntry,
        spill_slots: []SpillEntry,
        next_virtual_reg: usize,
        next_spill_slot: usize,
        edge_label_count: usize,
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

        fn init(selector: *ComposedBlockSelector) !Snapshot {
            const values = try selector.allocator.alloc(ValueEntry, selector.values.count());
            errdefer selector.allocator.free(values);
            const spill_slots = try selector.allocator.alloc(SpillEntry, selector.spill_slots.count());
            errdefer selector.allocator.free(spill_slots);

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
            return .{
                .instruction_len = selector.machine.instructions.items.len,
                .values = values,
                .spill_slots = spill_slots,
                .next_virtual_reg = selector.next_virtual_reg,
                .next_spill_slot = selector.next_spill_slot,
                .edge_label_count = selector.edge_label_count,
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

        fn restore(snapshot: *const Snapshot, selector: *ComposedBlockSelector) void {
            selector.machine.instructions.items.len = snapshot.instruction_len;
            selector.values.clearRetainingCapacity();
            for (snapshot.values) |entry| selector.values.putAssumeCapacity(entry.name, entry.binding);
            selector.spill_slots.clearRetainingCapacity();
            for (snapshot.spill_slots) |entry| selector.spill_slots.putAssumeCapacity(entry.name, entry.assignment);
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

        fn deinit(snapshot: *Snapshot, selector: *ComposedBlockSelector) void {
            selector.allocator.free(snapshot.spill_slots);
            selector.allocator.free(snapshot.values);
        }
    };

    const PhysicalNode = enum(u8) {
        rdi,
        rsi,
        rdx,
        rcx,
        r8,
        r9,
        accumulator,
    };
    const physical_node_count = std.meta.fields(PhysicalNode).len;

    pub fn begin(selector: *ComposedBlockSelector) !ValueUseTransaction {
        return .{ .selector = selector, .snapshot = try Snapshot.init(selector) };
    }

    pub fn deinit(transaction: *ValueUseTransaction) void {
        if (transaction.lifecycle == .active) transaction.rollbackInternal();
        transaction.snapshot.deinit(transaction.selector);
    }

    /// Registers a request without touching selector state. Identical requests
    /// for one source coalesce into the existing record.
    pub fn register(transaction: *ValueUseTransaction, request: Request) !usize {
        try transaction.requireActive();
        if (transaction.request_phase != .registering) return error.ValueUseLateRegistration;
        const stored = StoredRequest{
            .source = try Source.from(request.source),
            .expected = request.expected,
            .form = request.form,
            .destination = request.destination,
        };
        for (transaction.requests[0..transaction.request_count], 0..) |*existing, index| {
            if (!stored.source.eql(&existing.source)) continue;
            if (stored.eql(existing)) return index;
            return error.ValueUseIncompatibleDuplicate;
        }
        if (transaction.request_count == max_requests) return error.ValueUseRequestCapacityExceeded;
        const index = transaction.request_count;
        transaction.requests[index] = stored;
        transaction.request_count += 1;
        return index;
    }

    /// Seals and validates the complete plan before selector mutation. Current
    /// locations are inspected only to validate types, conflicts, and cycles;
    /// they are never stored for later materialization.
    pub fn seal(transaction: *ValueUseTransaction) !void {
        try transaction.requireActive();
        if (transaction.request_phase != .registering) return error.ValueUsePlanAlreadySealed;
        var destinations = [_]bool{false} ** physical_node_count;
        var graph = [_][physical_node_count]bool{[_]bool{false} ** physical_node_count} ** physical_node_count;
        var writes = [_]bool{false} ** physical_node_count;

        for (transaction.requests[0..transaction.request_count]) |*request| {
            const current = try transaction.validateRequest(request);
            const destination_nodes = try requestDestinationNodes(request);
            for (destination_nodes.slice()) |destination_node| {
                const node_index = @intFromEnum(destination_node);
                if (destinations[node_index]) return error.ValueUseConflictingDestination;
                destinations[node_index] = true;
            }
            const mappings = try requestMappings(request, current);
            for (mappings.slice()) |mapping| {
                if (mapping.source == null) {
                    writes[@intFromEnum(mapping.destination)] = true;
                    continue;
                }
                const source = mapping.source.?;
                if (source == mapping.destination) continue;
                graph[@intFromEnum(source)][@intFromEnum(mapping.destination)] = true;
                writes[@intFromEnum(mapping.destination)] = true;
            }
        }
        try rejectCopyCycles(graph);
        transaction.write_nodes = writes;
        transaction.request_phase = .sealed;
    }

    pub fn prepare(transaction: *ValueUseTransaction) !void {
        try transaction.requireActive();
        if (transaction.request_phase != .sealed) return error.ValueUsePrepareBeforeSeal;
        errdefer transaction.rollbackInternal();

        const saved_preserve = transaction.selector.preserve_current_position_values;
        transaction.selector.preserve_current_position_values = true;
        defer transaction.selector.preserve_current_position_values = saved_preserve;

        var nodes = transaction.write_nodes;
        for (transaction.requests[0..transaction.request_count]) |*request| {
            if (request.form != .pointer and request.form != .stack_object_address) continue;
            const current = switch (request.source) {
                .named => |*name| selector_state.resolveValue(transaction.selector, .{ .named = name.slice() }) orelse
                    return error.ValueUseUnresolvedSource,
                .null_value, .unsupported => continue,
            };
            if (current == .stack_i32_ptr or current == .stack_scalar or current == .stack128 or current == .stack_i32_array) {
                nodes[@intFromEnum(PhysicalNode.rcx)] = true;
                if (current == .stack_i32_ptr and current.stack_i32_ptr.index != null)
                    nodes[@intFromEnum(PhysicalNode.r8)] = true;
            }
        }
        for (nodes, 0..) |needed, index| {
            if (!needed) continue;
            try clobberPhysicalNode(transaction.selector, @enumFromInt(index));
        }
        transaction.request_phase = .prepared;
    }

    pub fn materializeAll(transaction: *ValueUseTransaction) !void {
        try transaction.requireActive();
        if (transaction.request_phase != .prepared) return error.ValueUseMaterializeBeforePrepare;
        transaction.request_phase = .materializing;
        errdefer transaction.rollbackInternal();
        for (transaction.requests[0..transaction.request_count]) |*request| {
            try transaction.materializeRequest(request);
        }
        transaction.request_phase = .materialized;
    }

    pub fn commit(transaction: *ValueUseTransaction) !void {
        try transaction.requireActive();
        if (transaction.request_phase != .materialized) return error.ValueUseCommitBeforeMaterialization;
        transaction.request_phase = .committed;
        transaction.lifecycle = .committed;
    }

    pub fn rollback(transaction: *ValueUseTransaction) !void {
        try transaction.requireActive();
        transaction.rollbackInternal();
    }

    pub fn requestCount(transaction: *const ValueUseTransaction) usize {
        return transaction.request_count;
    }

    pub fn phase(transaction: *const ValueUseTransaction) RequestPhase {
        return transaction.request_phase;
    }

    fn requireActive(transaction: *const ValueUseTransaction) !void {
        if (transaction.lifecycle != .active) return error.ValueUseTransactionClosed;
    }

    fn rollbackInternal(transaction: *ValueUseTransaction) void {
        transaction.snapshot.restore(transaction.selector);
        transaction.request_count = 0;
        transaction.request_phase = .registering;
        transaction.write_nodes = [_]bool{false} ** physical_node_count;
        transaction.lifecycle = .rolled_back;
    }

    fn validateRequest(transaction: *ValueUseTransaction, request: *const StoredRequest) !?ValueLoc {
        try validateFormAndDestination(request);
        switch (request.source) {
            .unsupported => return error.ValueUseUnsupportedSource,
            .null_value => {
                if (request.form != .pointer or request.expected.ty != .ptr or
                    (request.expected.register_class != .gpr64 and request.expected.register_class != .stack_pointer) or
                    request.expected.pointer_address_space == null or request.expected.pointer_address_space.? != 0)
                {
                    return error.ValueUseUntypedNullPointer;
                }
                return null;
            },
            .named => |*name| {
                const binding = transaction.selector.values.get(name.slice()) orelse
                    return error.ValueUseUnresolvedSource;
                const current = selector_state.resolveValue(transaction.selector, .{ .named = name.slice() }) orelse
                    return error.ValueUseUnresolvedSource;
                try selector_state.validateAddressDependenciesForUse(transaction.selector, name.slice());
                if (!try selector_state.valueIsLiveAtOrAfterCurrent(transaction.selector, name.slice()))
                    return error.ValueUseExpiredSource;
                if (binding.vreg.class != request.expected.register_class)
                    return error.ValueUseRegisterClassMismatch;
                try validateExpectedType(request.expected, request.form);
                try validateSourceView(current, request.form);
                return current;
            },
        }
    }

    fn materializeRequest(transaction: *ValueUseTransaction, request: *const StoredRequest) !void {
        const current = switch (request.source) {
            .named => |*name| blk: {
                // Deliberately resolve after all preparation/spill mutations.
                const binding = transaction.selector.values.get(name.slice()) orelse
                    return error.ValueUseUnresolvedSource;
                if (binding.vreg.class != request.expected.register_class)
                    return error.ValueUseRegisterClassMismatch;
                try selector_state.validateAddressDependenciesForUse(transaction.selector, name.slice());
                break :blk selector_state.resolveValue(transaction.selector, .{ .named = name.slice() }) orelse
                    return error.ValueUseUnresolvedSource;
            },
            .null_value => {
                try materializeNull(transaction.selector, request.destination);
                return;
            },
            .unsupported => return error.ValueUseUnsupportedSource,
        };
        try validateSourceView(current, request.form);
        switch (request.form) {
            .gpr32 => try materializeScalar32(transaction.selector, current, request.destination),
            .gpr64 => try materializeScalar64(transaction.selector, current, request.destination),
            .pointer, .stack_object_address => try materializePointer(transaction.selector, current, request.destination),
            .pair_low_high, .pair_high_low => try materializePair(transaction.selector, current, request.form, request.destination),
            .stack_argument => return error.ValueUseStackArgumentUnsupported,
            .new_pair_ownership => return error.ValueUseNewPairOwnershipUnsupported,
        }
    }
};

const NodeList = struct {
    items: [2]ValueUseTransaction.PhysicalNode = undefined,
    len: u8 = 0,

    fn append(list: *NodeList, node: ValueUseTransaction.PhysicalNode) !void {
        if (list.len == list.items.len) return error.ValueUseInvalidDestination;
        list.items[list.len] = node;
        list.len += 1;
    }

    fn slice(list: *const NodeList) []const ValueUseTransaction.PhysicalNode {
        return list.items[0..list.len];
    }
};

const Mapping = struct {
    source: ?ValueUseTransaction.PhysicalNode,
    destination: ValueUseTransaction.PhysicalNode,
};

const MappingList = struct {
    items: [2]Mapping = undefined,
    len: u8 = 0,

    fn append(list: *MappingList, mapping: Mapping) void {
        list.items[list.len] = mapping;
        list.len += 1;
    }

    fn slice(list: *const MappingList) []const Mapping {
        return list.items[0..list.len];
    }
};

fn validateFormAndDestination(request: *const ValueUseTransaction.StoredRequest) !void {
    const valid = switch (request.form) {
        .gpr32 => request.destination == .gpr32 or request.destination == .eax,
        .gpr64 => request.destination == .gpr64 or request.destination == .rax,
        .pointer, .stack_object_address => request.destination == .gpr64 or request.destination == .rax,
        .pair_low_high, .pair_high_low => request.destination == .pair,
        .stack_argument => return error.ValueUseStackArgumentUnsupported,
        .new_pair_ownership => return error.ValueUseNewPairOwnershipUnsupported,
    };
    if (!valid) return error.ValueUseDestinationFormMismatch;
}

fn validateExpectedType(expected: ValueUseTransaction.Expected, form: ValueUseTransaction.UseForm) !void {
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
        .stack_argument => return error.ValueUseStackArgumentUnsupported,
        .new_pair_ownership => return error.ValueUseNewPairOwnershipUnsupported,
    }
}

fn validateSourceView(loc: ValueLoc, form: ValueUseTransaction.UseForm) !void {
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
        .pair_low_high, .pair_high_low => switch (loc) {
            .arg128, .scratch128, .spill128 => {},
            .xmm => return error.ValueUseXmmUnsupported,
            .aggregate_sse => return error.ValueUseAggregateUnsupported,
            else => return error.ValueUseSourceViewMismatch,
        },
        .stack_argument => return error.ValueUseStackArgumentUnsupported,
        .new_pair_ownership => return error.ValueUseNewPairOwnershipUnsupported,
    }
}

fn requestDestinationNodes(request: *const ValueUseTransaction.StoredRequest) !NodeList {
    var result: NodeList = .{};
    switch (request.destination) {
        .gpr32, .gpr64 => |reg| try result.append(nodeForArgReg(reg)),
        .eax, .rax => try result.append(.accumulator),
        .pair => |pair| {
            try result.append(nodeForArgReg(pair.lo));
            try result.append(nodeForArgReg(pair.hi));
        },
        .stack_argument => return error.ValueUseStackArgumentUnsupported,
        .new_pair => return error.ValueUseNewPairOwnershipUnsupported,
    }
    return result;
}

fn requestMappings(request: *const ValueUseTransaction.StoredRequest, current: ?ValueLoc) !MappingList {
    var mappings: MappingList = .{};
    const destinations = try requestDestinationNodes(request);
    if (current == null) {
        for (destinations.slice()) |destination| mappings.append(.{ .source = null, .destination = destination });
        return mappings;
    }
    if (request.form == .pair_low_high or request.form == .pair_high_low) {
        const source_nodes = pairSourceNodes(current.?);
        const low = source_nodes[0];
        const high = source_nodes[1];
        if (request.form == .pair_low_high) {
            mappings.append(.{ .source = low, .destination = destinations.items[0] });
            mappings.append(.{ .source = high, .destination = destinations.items[1] });
        } else {
            mappings.append(.{ .source = high, .destination = destinations.items[0] });
            mappings.append(.{ .source = low, .destination = destinations.items[1] });
        }
        return mappings;
    }
    mappings.append(.{ .source = scalarSourceNode(current.?), .destination = destinations.items[0] });
    return mappings;
}

fn scalarSourceNode(loc: ValueLoc) ?ValueUseTransaction.PhysicalNode {
    return switch (loc) {
        .arg32, .arg64, .scratch32, .scratch64 => |reg| nodeForArgReg(reg),
        .eax, .rax => .accumulator,
        .readonly_table_ptr => |ptr| switch (ptr.storage) {
            .reg => |reg| nodeForArgReg(reg),
            .spill => null,
        },
        else => null,
    };
}

fn pairSourceNodes(loc: ValueLoc) [2]?ValueUseTransaction.PhysicalNode {
    return switch (loc) {
        .arg128, .scratch128 => |pair| .{ nodeForArgReg(pair.lo), nodeForArgReg(pair.hi) },
        .spill128 => .{ null, null },
        else => .{ null, null },
    };
}

fn nodeForArgReg(reg: ArgReg) ValueUseTransaction.PhysicalNode {
    return switch (reg) {
        .rdi => .rdi,
        .rsi => .rsi,
        .rdx => .rdx,
        .rcx => .rcx,
        .r8 => .r8,
        .r9 => .r9,
    };
}

fn argRegForNode(node: ValueUseTransaction.PhysicalNode) ?ArgReg {
    return switch (node) {
        .rdi => .rdi,
        .rsi => .rsi,
        .rdx => .rdx,
        .rcx => .rcx,
        .r8 => .r8,
        .r9 => .r9,
        .accumulator => null,
    };
}

fn rejectCopyCycles(graph: [ValueUseTransaction.physical_node_count][ValueUseTransaction.physical_node_count]bool) !void {
    var states = [_]CopyVisitState{.unseen} ** ValueUseTransaction.physical_node_count;
    for (0..ValueUseTransaction.physical_node_count) |node| try visitCopyNode(graph, node, &states);
}

fn visitCopyNode(
    graph: [ValueUseTransaction.physical_node_count][ValueUseTransaction.physical_node_count]bool,
    node: usize,
    states: *[ValueUseTransaction.physical_node_count]CopyVisitState,
) !void {
    switch (states[node]) {
        .complete => return,
        .visiting => return error.ValueUseCopyCycleRequiresO4,
        .unseen => states[node] = .visiting,
    }
    for (graph[node], 0..) |edge, destination| if (edge) try visitCopyNode(graph, destination, states);
    states[node] = .complete;
}

const CopyVisitState = enum { unseen, visiting, complete };

fn clobberPhysicalNode(selector: *ComposedBlockSelector, node: ValueUseTransaction.PhysicalNode) !void {
    if (argRegForNode(node)) |reg| {
        try selector_state.clobberArgReg(selector, reg);
    } else {
        try selector_state.clobberAccumulator(selector);
        selector.accumulator_domain.invalidate();
    }
}

fn materializeScalar32(selector: *ComposedBlockSelector, current: ValueLoc, destination: ValueUseTransaction.Destination) !void {
    switch (destination) {
        .gpr32 => |reg| try selector_state.materializeLocIntoLoc(selector, current, .{ .scratch32 = reg }),
        .eax => switch (current) {
            .arg32, .scratch32, .arg64, .scratch64 => |reg| try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_eax = reg }),
            .spill64 => |frame_index| try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_eax = frame_index }),
            .eax, .rax => {},
            else => return error.ValueUseSourceViewMismatch,
        },
        else => return error.ValueUseDestinationFormMismatch,
    }
}

fn materializeScalar64(selector: *ComposedBlockSelector, current: ValueLoc, destination: ValueUseTransaction.Destination) !void {
    switch (destination) {
        .gpr64 => |reg| try selector_state.materializeLocIntoLoc(selector, current, .{ .scratch64 = reg }),
        .rax => switch (current) {
            .arg64, .scratch64 => |reg| try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = reg }),
            .spill64 => |frame_index| try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = frame_index }),
            .rax => {},
            else => return error.ValueUseSourceViewMismatch,
        },
        else => return error.ValueUseDestinationFormMismatch,
    }
}

fn materializePointer(selector: *ComposedBlockSelector, current: ValueLoc, destination: ValueUseTransaction.Destination) !void {
    switch (current) {
        .arg64, .scratch64, .rax, .spill64 => try materializeScalar64(selector, current, destination),
        .readonly_table_ptr => |ptr| switch (destination) {
            .gpr64 => |reg| try selector_state.materializeLocIntoLoc(selector, .{ .readonly_table_ptr = ptr }, .{ .scratch64 = reg }),
            .rax => switch (ptr.storage) {
                .reg => |reg| try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = reg }),
                .spill => |frame_index| try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = frame_index }),
            },
            else => return error.ValueUseDestinationFormMismatch,
        },
        .stack_scalar => |stack| try materializeStackAddress(selector, stack.base_disp, null, destination),
        .stack128 => |disp| try materializeStackAddress(selector, disp, null, destination),
        .stack_i32_array => |array| try materializeStackAddress(selector, array.base_disp, null, destination),
        .stack_i32_ptr => |ptr| try materializeStackAddress(selector, ptr.disp, ptr, destination),
        else => return error.ValueUseUnsupportedAddressForm,
    }
}

fn materializeStackAddress(
    selector: *ComposedBlockSelector,
    disp: u32,
    stack_ptr: ?selector_types.StackPtrLoc,
    destination: ValueUseTransaction.Destination,
) !void {
    if (stack_ptr) |ptr| {
        if (ptr.index) |index| {
            try selector_state.emitValueIntoScratch(selector, .{ .named = index.name }, .rcx, 64);
            if (index.addend_name) |addend_name| {
                try selector_state.emitValueIntoScratch(selector, .{ .named = addend_name }, .r8, 64);
                try selector_state.emitEflagsInstruction(selector, .add_r8_rcx, .write);
            }
            try selector_state.emitEflagsInstruction(selector, .{ .shl_rcx_imm6 = 2 }, .write);
            try selector.machine.instructions.append(selector.allocator, .{ .mov_rsp_arg64 = .r8 });
            try selector_state.emitEflagsInstruction(selector, .add_r8_rcx, .write);
        } else {
            try selector.machine.instructions.append(selector.allocator, .{ .mov_rsp_arg64 = .rcx });
        }
    } else {
        try selector.machine.instructions.append(selector.allocator, .{ .mov_rsp_arg64 = .rcx });
    }
    if (disp != 0) {
        const immediate = std.math.cast(i32, disp) orelse return error.ValueUseUnsupportedAddressForm;
        try selector_state.emitEflagsInstruction(selector, .{ .add_arg64_imm32 = .{ .reg = .rcx, .imm = immediate } }, .write);
    }
    switch (destination) {
        .gpr64 => |reg| if (reg != .rcx) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = reg, .src = .rcx } }),
        .rax => try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = .rcx }),
        else => return error.ValueUseDestinationFormMismatch,
    }
}

fn materializePair(
    selector: *ComposedBlockSelector,
    current: ValueLoc,
    form: ValueUseTransaction.UseForm,
    destination: ValueUseTransaction.Destination,
) !void {
    const pair = switch (destination) {
        .pair => |pair| pair,
        else => return error.ValueUseDestinationFormMismatch,
    };
    if (form == .pair_low_high) {
        try materializePairLimb(selector, current, false, pair.lo);
        try materializePairLimb(selector, current, true, pair.hi);
    } else {
        try materializePairLimb(selector, current, true, pair.lo);
        try materializePairLimb(selector, current, false, pair.hi);
    }
}

fn materializePairLimb(selector: *ComposedBlockSelector, current: ValueLoc, high: bool, destination: ArgReg) !void {
    switch (current) {
        .arg128, .scratch128 => |source| {
            const reg = if (high) source.hi else source.lo;
            if (reg != destination) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = destination, .src = reg } });
        },
        .spill128 => |spill| try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{
            .reg = destination,
            .frame_index = if (high) spill.hi else spill.lo,
        } }),
        else => return error.ValueUseSourceViewMismatch,
    }
}

fn materializeNull(selector: *ComposedBlockSelector, destination: ValueUseTransaction.Destination) !void {
    switch (destination) {
        .gpr64 => |reg| try selector.machine.instructions.append(selector.allocator, switch (reg) {
            .rdi => .{ .mov_imm_rdi = 0 },
            .rsi => .{ .mov_imm_rsi = 0 },
            .rdx => .{ .mov_imm_rdx = 0 },
            .rcx => .{ .mov_imm_rcx = 0 },
            .r8 => .{ .mov_imm_r8 = 0 },
            .r9 => .{ .mov_imm_r9 = 0 },
        }),
        .rax => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rax = 0 }),
        else => return error.ValueUseDestinationFormMismatch,
    }
}
