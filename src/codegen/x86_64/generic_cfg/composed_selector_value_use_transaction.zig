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
const constant_table = @import("../constant_table.zig");
const aggregate_object = @import("aggregate_object.zig");

const ArgReg = x86_64_types.ArgReg;
const FrameIndex = x86_64_types.FrameIndex;
const RegPair = selector_types.RegPair;
const ValueBinding = selector_types.ValueBinding;
const ValueLoc = selector_types.ValueLoc;
const VirtualReg = selector_types.VirtualReg;
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
    early_plans: [max_requests]EarlyPlan = [_]EarlyPlan{.{}} ** max_requests,
    early_homes: [max_requests]EarlyPreparedHome = undefined,
    early_home_valid: [max_requests]bool = [_]bool{false} ** max_requests,
    prepared_views: [max_requests]PreparedRecord = undefined,
    prepared_view_valid: [max_requests]bool = [_]bool{false} ** max_requests,
    view_generation: u32 = 1,

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
        /// Action-only bounded descriptor view. It is accepted exclusively by
        /// form_byte_address and is never a generic pointer materialization.
        stack_f32_pair_byte_address,
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
        prepared_source,
        prepared_view,
        stack_argument: u32,
        new_pair,

        fn eql(destination: Destination, other: Destination) bool {
            if (std.meta.activeTag(destination) != std.meta.activeTag(other)) return false;
            return switch (destination) {
                .gpr32 => |reg| reg == other.gpr32,
                .gpr64 => |reg| reg == other.gpr64,
                .pair => |pair| pair.eql(other.pair),
                .stack_argument => |slot| slot == other.stack_argument,
                .eax, .rax, .prepared_source, .prepared_view, .new_pair => true,
            };
        }
    };

    /// Opaque transaction-local identity. It contains no resolved location and
    /// is invalid outside the authority that returned it.
    pub const RequestHandle = struct {
        authority: usize,
        index: u8,
        generation: u32,
    };

    /// Phase-bound capability for executing one sealed prepared action. It
    /// contains no source location or representation.
    pub const PreparedViewLease = struct {
        request: RequestHandle,
        view_generation: u32,
    };

    /// Inline-owned semantic identity for a sealed action. Callers provide a
    /// name, never storage discovered from selector state.
    pub const ActionIdentity = struct {
        bytes: [max_identity_bytes]u8 = [_]u8{0} ** max_identity_bytes,
        len: u8 = 0,

        pub fn init(name: []const u8) !ActionIdentity {
            if (name.len == 0) return error.ValueUseEmptyIdentity;
            if (name.len > max_identity_bytes) return error.ValueUseIdentityTooLong;
            var identity: ActionIdentity = .{};
            @memcpy(identity.bytes[0..name.len], name);
            identity.len = @intCast(name.len);
            return identity;
        }

        fn slice(identity: *const ActionIdentity) []const u8 {
            return identity.bytes[0..identity.len];
        }

        fn validate(identity: *const ActionIdentity) !void {
            if (identity.len == 0) return error.ValueUseEmptyIdentity;
            if (identity.len > max_identity_bytes) return error.ValueUseIdentityTooLong;
        }
    };

    pub const AddressOffset = union(enum) {
        constant: i32,
        request: RequestHandle,
    };

    /// Closed source-view contracts used by validation actions. Every field is
    /// caller-supplied intent; the authority never returns discovered storage.
    pub const PreparedShape = union(enum) {
        register_gpr32: ArgReg,
        register_gpr64: ArgReg,
        register_eax,
        register_rax,
        scalar_spill: FrameIndex,
        stack_scalar: u32,
        stack_integer128: u32,
        stack_i32_array: selector_types.StackArrayLoc,
        address_descriptor: struct { has_index: bool, has_addend: bool },
        table_register: ArgReg,
        table_spill: FrameIndex,
        pair_register: RegPair,
        pair_spill: selector_types.PairSpillLoc,
    };

    pub const ByteAddressAction = struct {
        result: ActionIdentity,
        offset: AddressOffset,
    };

    pub const ScaledAddressAction = struct {
        result: ActionIdentity,
        index: AddressOffset,
        scale: u8,
        expected_stack_array_len: ?u32 = null,
    };

    pub const ReadOnlyTableAddressAction = struct {
        result: ActionIdentity,
        symbol: ActionIdentity,
        shape: constant_table.Shape,
        scale: u8,
    };

    /// A complete, typed operation over a prepared source. This descriptor is
    /// registered before seal, so every physical destination participates in
    /// conflict, preservation, and cycle planning. No variant exposes source
    /// storage to its caller.
    pub const PreparedAction = union(enum) {
        validate_shape: PreparedShape,
        emit_copy_to: CopyDestination,
        form_byte_address: ByteAddressAction,
        form_scaled_address: ScaledAddressAction,
        form_readonly_table_address: ReadOnlyTableAddressAction,

        fn eql(action: PreparedAction, other: PreparedAction) bool {
            return std.meta.eql(action, other);
        }
    };

    pub const CopyDestination = union(enum) {
        gpr32: ArgReg,
        gpr64: ArgReg,
        eax,
        rax,

        fn asDestination(copy_destination: CopyDestination) Destination {
            return switch (copy_destination) {
                .gpr32 => |reg| .{ .gpr32 = reg },
                .gpr64 => |reg| .{ .gpr64 = reg },
                .eax => .eax,
                .rax => .rax,
            };
        }
    };

    const PreparedIdentity = struct {
        bytes: [max_identity_bytes]u8 = undefined,
        len: u8 = 0,

        fn init(name: []const u8) !PreparedIdentity {
            if (name.len == 0) return error.ValueUseEmptyIdentity;
            if (name.len > max_identity_bytes) return error.ValueUseIdentityTooLong;
            var identity: PreparedIdentity = .{};
            @memcpy(identity.bytes[0..name.len], name);
            identity.len = @intCast(name.len);
            return identity;
        }

        fn slice(identity: *const PreparedIdentity) []const u8 {
            return identity.bytes[0..identity.len];
        }

        fn eql(identity: *const PreparedIdentity, other: *const PreparedIdentity) bool {
            return std.mem.eql(u8, identity.slice(), other.slice());
        }
    };

    const PreparedRegister = union(enum) {
        gpr32: ArgReg,
        gpr64: ArgReg,
        eax,
        rax,
    };

    const PreparedScalarHome = union(enum) {
        register: PreparedRegister,
        spill: FrameIndex,
    };

    const PreparedStackObject = union(enum) {
        scalar: selector_types.StackScalarLoc,
        integer128: u32,
        integer32_array: selector_types.StackArrayLoc,
    };

    const PreparedAddressComponent = struct {
        identity: PreparedIdentity,
        role: AddressDependencyDomain.Role,
        home: PreparedScalarHome,
        vreg: VirtualReg,
    };

    const PreparedAddressDescriptor = struct {
        disp: u32,
        index: ?PreparedAddressComponent = null,
        addend: ?PreparedAddressComponent = null,
    };

    const PreparedStackF32PairAddress = struct {
        object_base_disp: u32,
        disp: u32,
    };

    const PreparedTablePointer = struct {
        storage: union(enum) { register: ArgReg, spill: FrameIndex },
        symbol: PreparedIdentity,
        shape: constant_table.Shape,
        offset: u8,
    };

    const PreparedPairLimb = union(enum) {
        register: ArgReg,
        spill: FrameIndex,
    };

    const PreparedReadOnlyPair = struct {
        first: PreparedPairLimb,
        second: PreparedPairLimb,
    };

    /// Restricted source-derived representation. No raw ValueLoc, binding, or
    /// borrowed identity escapes the instruction-level authority.
    const PreparedView = union(enum) {
        register: struct { register: PreparedRegister, bits: u16 },
        spill: struct { frame_index: FrameIndex, bits: u16 },
        stack_object: PreparedStackObject,
        address_descriptor: PreparedAddressDescriptor,
        stack_f32_pair_address: PreparedStackF32PairAddress,
        table_pointer: PreparedTablePointer,
        read_only_pair: PreparedReadOnlyPair,
    };

    const PreparedRecord = struct {
        view: PreparedView,
        source_vreg: VirtualReg,
        canonical_source_loc: ValueLoc,
    };

    const EarlyPlan = struct {
        destination: ?ArgReg = null,
    };

    const EarlyPreparedHome = struct {
        loc: ValueLoc,
        source_vreg: VirtualReg,
    };

    pub const Request = struct {
        source: ir.Value,
        expected: Expected,
        form: UseForm,
        destination: Destination,
        prepared_action: ?PreparedAction = null,
    };

    pub const RequestPhase = enum {
        registering,
        sealed,
        prepared,
        materializing,
        materialized,
        views_exposed,
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
        prepared_action: ?PreparedAction,

        fn eql(request: *const StoredRequest, other: *const StoredRequest) bool {
            return request.source.eql(&other.source) and
                request.expected.eql(other.expected) and
                request.form == other.form and
                request.destination.eql(other.destination) and
                optionalPreparedActionEql(request.prepared_action, other.prepared_action);
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

        fn restore(snapshot: *const Snapshot, selector: *ComposedBlockSelector) void {
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
    const max_mappings = max_requests * 2;

    pub fn begin(selector: *ComposedBlockSelector) !ValueUseTransaction {
        return .{ .selector = selector, .snapshot = try Snapshot.init(selector) };
    }

    pub fn deinit(transaction: *ValueUseTransaction) void {
        if (transaction.lifecycle == .active) transaction.rollbackInternal();
        transaction.snapshot.deinit(transaction.selector);
    }

    /// Registers a request without touching selector state. Identical requests
    /// for one source coalesce into the existing record.
    pub fn register(transaction: *ValueUseTransaction, request: Request) !RequestHandle {
        try transaction.requireActive();
        if (transaction.request_phase != .registering) return error.ValueUseLateRegistration;
        if (request.prepared_action) |action| try transaction.validateActionRegistration(action);
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
                optionalPreparedActionEql(stored.prepared_action, existing.prepared_action))
            {
                return transaction.handleFor(@intCast(index));
            }
        }
        if (transaction.request_count == max_requests) return error.ValueUseRequestCapacityExceeded;
        const index = transaction.request_count;
        transaction.requests[index] = stored;
        transaction.request_count += 1;
        return transaction.handleFor(index);
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
        var mappings: [max_mappings]Mapping = undefined;
        var mapping_count: usize = 0;

        for (transaction.requests[0..transaction.request_count], 0..) |*request, request_index| {
            const current = try transaction.validateRequest(request);
            const destination_nodes = try requestDestinationNodes(transaction, request, current);
            for (destination_nodes.slice()) |destination_node| {
                const node_index = @intFromEnum(destination_node);
                if (destinations[node_index]) return error.ValueUseConflictingDestination;
                destinations[node_index] = true;
            }
            const request_mappings = try requestMappings(transaction, request, @intCast(request_index), current);
            for (request_mappings.slice()) |mapping| {
                if (mapping_count == mappings.len) return error.ValueUseMappingCapacityExceeded;
                mappings[mapping_count] = mapping;
                mapping_count += 1;
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
        try transaction.planEarlyMaterializations(mappings[0..mapping_count]);
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

        try transaction.materializeEarlyPlans();
        var nodes = transaction.write_nodes;
        for (transaction.requests[0..transaction.request_count]) |*request| {
            if (request.destination == .prepared_source) continue;
            if (request.destination == .prepared_view and request.prepared_action.? != .emit_copy_to) continue;
            if (request.form != .pointer and request.form != .stack_object_address) continue;
            const current = switch (request.source) {
                .named => |*name| try transaction.resolveNamedCurrent(name.slice()),
                .null_value, .unsupported => continue,
            };
            if (current == .stack_i32_ptr or current == .stack_scalar or current == .stack128 or current == .stack_i32_array) {
                nodes[@intFromEnum(PhysicalNode.rcx)] = true;
                if (current == .stack_i32_ptr and current.stack_i32_ptr.index != null)
                    nodes[@intFromEnum(PhysicalNode.r8)] = true;
            }
        }
        for (transaction.early_plans) |plan| {
            if (plan.destination) |reg| nodes[@intFromEnum(nodeForArgReg(reg))] = false;
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
        // Complete every mutation-producing fixed materialization first.
        for (transaction.requests[0..transaction.request_count], 0..) |*request, index| {
            if (request.destination == .prepared_source or request.destination == .prepared_view) continue;
            if (transaction.early_home_valid[index]) {
                try transaction.validateEarlyHome(@intCast(index));
                continue;
            }
            try transaction.materializeRequest(request);
        }
        // Only now expose source-derived views from canonical current state.
        for (transaction.requests[0..transaction.request_count], 0..) |*request, index| {
            if (request.destination != .prepared_source and request.destination != .prepared_view) continue;
            transaction.prepared_views[index] = try transaction.buildPreparedRecord(@intCast(index));
            transaction.prepared_view_valid[index] = true;
        }
        transaction.request_phase = .materialized;
    }

    pub fn preparedView(transaction: *ValueUseTransaction, handle: RequestHandle) !PreparedViewLease {
        try transaction.requireActive();
        if (transaction.request_phase != .materialized and transaction.request_phase != .views_exposed)
            return error.ValueUsePreparedViewUnavailable;
        errdefer transaction.rollbackInternal();
        const index = try transaction.validateHandle(handle);
        if (transaction.requests[index].destination != .prepared_view or !transaction.prepared_view_valid[index])
            return error.ValueUsePreparedViewMissing;
        transaction.request_phase = .views_exposed;
        return .{ .request = handle, .view_generation = transaction.view_generation };
    }

    /// Executes the request's sealed, typed action entirely inside the
    /// transaction authority. No private representation or source location
    /// crosses this API. Canonical pre/post derivation remains defense in
    /// depth around the internal action emission.
    pub fn executePreparedAction(transaction: *ValueUseTransaction, lease: PreparedViewLease) !void {
        try transaction.requireActive();
        if (lease.view_generation != transaction.view_generation)
            return error.ValueUsePreparedViewStale;
        if (transaction.request_phase != .views_exposed)
            return error.ValueUsePreparedViewUnavailable;
        errdefer transaction.rollbackInternal();
        const index = try transaction.validateHandle(lease.request);
        if (!transaction.prepared_view_valid[index]) return error.ValueUsePreparedViewMissing;
        const refreshed = try transaction.buildPreparedRecord(index);
        if (!preparedRecordEql(&transaction.prepared_views[index], &refreshed))
            return error.ValueUsePreparedViewStale;
        const action = transaction.requests[index].prepared_action orelse
            return error.ValueUsePreparedActionMissing;
        try transaction.validateActionDependenciesCanonical(action);
        try executePreparedActionInternal(transaction, &refreshed.view, &transaction.requests[index], action);
        // Defense in depth: even the closed internal action must not relocate
        // or rebind its source. Any violation rolls back speculative emission.
        const after_consumption = try transaction.buildPreparedRecord(index);
        if (!preparedRecordEql(&transaction.prepared_views[index], &after_consumption))
            return error.ValueUsePreparedViewStale;
        try transaction.validateActionDependenciesCanonical(action);
        transaction.prepared_view_valid[index] = false;
    }

    pub fn commit(transaction: *ValueUseTransaction) !void {
        try transaction.requireActive();
        if (transaction.request_phase != .materialized and transaction.request_phase != .views_exposed)
            return error.ValueUseCommitBeforeMaterialization;
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
        transaction.early_plans = [_]EarlyPlan{.{}} ** max_requests;
        transaction.early_home_valid = [_]bool{false} ** max_requests;
        transaction.prepared_view_valid = [_]bool{false} ** max_requests;
        transaction.view_generation +%= 1;
        if (transaction.view_generation == 0) transaction.view_generation = 1;
        transaction.lifecycle = .rolled_back;
    }

    fn handleFor(transaction: *ValueUseTransaction, index: u8) RequestHandle {
        return .{
            .authority = @intFromPtr(transaction),
            .index = index,
            .generation = transaction.view_generation,
        };
    }

    fn validateHandle(transaction: *ValueUseTransaction, handle: RequestHandle) !u8 {
        if (handle.authority != @intFromPtr(transaction) or handle.generation != transaction.view_generation)
            return error.ValueUsePreparedViewStale;
        if (handle.index >= transaction.request_count) return error.ValueUsePreparedViewMissing;
        return handle.index;
    }

    fn validateActionRegistration(transaction: *ValueUseTransaction, action: PreparedAction) !void {
        switch (action) {
            .validate_shape, .emit_copy_to => {},
            .form_byte_address => |address| {
                try address.result.validate();
                switch (address.offset) {
                    .constant => {},
                    .request => |handle| _ = try transaction.validateRegisteredOperandHandle(handle),
                }
            },
            .form_scaled_address => |address| {
                try address.result.validate();
                _ = try scaleShift(address.scale);
                switch (address.index) {
                    .constant => {},
                    .request => |handle| _ = try transaction.validateRegisteredOperandHandle(handle),
                }
            },
            .form_readonly_table_address => |address| {
                try address.result.validate();
                try address.symbol.validate();
                _ = try scaleShift(address.scale);
                if (address.scale != address.shape.stride()) return error.ValueUseAddressScaleMismatch;
            },
        }
    }

    fn validateRegisteredOperandHandle(transaction: *ValueUseTransaction, handle: RequestHandle) !u8 {
        if (handle.authority != @intFromPtr(transaction) or handle.generation != transaction.view_generation or
            handle.index >= transaction.request_count)
        {
            return error.ValueUseActionOperandNotRegistered;
        }
        if (transaction.requests[handle.index].destination != .prepared_source)
            return error.ValueUseActionOperandNotPreparedSource;
        return handle.index;
    }

    fn registeredOperandCurrent(transaction: *ValueUseTransaction, handle: RequestHandle) !ValueLoc {
        const index = try transaction.validateRegisteredOperandHandle(handle);
        return (try transaction.validateRequest(&transaction.requests[index])) orelse
            error.ValueUseUnsupportedSource;
    }

    fn registeredOperandView(
        transaction: *ValueUseTransaction,
        handle: RequestHandle,
    ) !*const PreparedView {
        const index = try transaction.validateRegisteredOperandHandle(handle);
        if (!transaction.prepared_view_valid[index]) return error.ValueUsePreparedViewMissing;
        return &transaction.prepared_views[index].view;
    }

    fn validateActionDependenciesCanonical(transaction: *ValueUseTransaction, action: PreparedAction) !void {
        switch (action) {
            .form_byte_address => |address| switch (address.offset) {
                .constant => {},
                .request => |handle| try transaction.validateOperandCanonical(handle),
            },
            .form_scaled_address => |address| switch (address.index) {
                .constant => {},
                .request => |handle| try transaction.validateOperandCanonical(handle),
            },
            .validate_shape, .emit_copy_to, .form_readonly_table_address => {},
        }
    }

    fn validateOperandCanonical(transaction: *ValueUseTransaction, handle: RequestHandle) !void {
        const index = try transaction.validateRegisteredOperandHandle(handle);
        if (!transaction.prepared_view_valid[index]) return error.ValueUsePreparedViewMissing;
        const refreshed = try transaction.buildPreparedRecord(index);
        if (!preparedRecordEql(&transaction.prepared_views[index], &refreshed))
            return error.ValueUsePreparedViewStale;
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
                if (request.destination == .prepared_source or request.destination == .prepared_view)
                    return error.ValueUsePreparedViewUnsupported;
                return null;
            },
            .named => |*name| {
                const binding = transaction.selector.values.get(name.slice()) orelse return error.ValueUseUnresolvedSource;
                const current = try transaction.resolveNamedCurrent(name.slice());
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

    fn planEarlyMaterializations(transaction: *ValueUseTransaction, mappings: []const Mapping) !void {
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

        for (mappings) |mapping| {
            const index = mapping.source_request_index orelse continue;
            if (source_counts[index] != 1) continue;
            const destination = argRegForNode(mapping.destination) orelse continue;
            if (mapping.source == mapping.destination) continue;
            if (source_nodes[@intFromEnum(mapping.destination)]) continue;
            if (!selector_state.scratchRegIsProvenFree(transaction.selector, destination)) continue;
            if (transaction.early_plans[index].destination != null) continue;

            const request = &transaction.requests[index];
            const current = switch (request.source) {
                .named => try transaction.validateRequest(request) orelse continue,
                .null_value, .unsupported => continue,
            };
            if (!earlySequencingCandidate(current, request.form)) continue;
            transaction.early_plans[index].destination = destination;
        }
    }

    fn materializeEarlyPlans(transaction: *ValueUseTransaction) !void {
        for (transaction.early_plans[0..transaction.request_count], 0..) |plan, index| {
            const destination_reg = plan.destination orelse continue;
            if (!selector_state.scratchRegIsProvenFree(transaction.selector, destination_reg))
                return error.ValueUseEarlyDestinationNoLongerFree;
            const request = &transaction.requests[index];
            const name = switch (request.source) {
                .named => |*identity| identity.slice(),
                .null_value, .unsupported => return error.ValueUseEarlySourceNotNamed,
            };
            const binding = transaction.selector.values.get(name) orelse
                return error.ValueUseUnresolvedSource;
            const current = (try transaction.validateRequest(request)) orelse
                return error.ValueUseUnsupportedSource;
            if (!earlyCopyIsFlagsPreserving(current, request.form))
                return error.ValueUseEarlyMaterializationNotFlagsPreserving;

            const instruction_start = transaction.selector.machine.instructions.items.len;
            const destination: Destination = switch (request.form) {
                .gpr32 => .{ .gpr32 = destination_reg },
                .gpr64, .pointer => .{ .gpr64 = destination_reg },
                else => return error.ValueUseEarlyMaterializationNotFlagsPreserving,
            };
            try transaction.materializeRequestFromLoc(request, current, destination);
            for (transaction.selector.machine.instructions.items[instruction_start..]) |instruction| {
                if (eflags.instructionEffect(instruction) != .preserve)
                    return error.ValueUseEarlyMaterializationClobbersEflags;
            }
            transaction.early_homes[index] = .{
                .loc = switch (request.form) {
                    .gpr32 => .{ .scratch32 = destination_reg },
                    .gpr64, .pointer => .{ .scratch64 = destination_reg },
                    else => unreachable,
                },
                .source_vreg = binding.vreg,
            };
            transaction.early_home_valid[index] = true;
        }
    }

    fn validateEarlyHome(transaction: *ValueUseTransaction, index: u8) !void {
        if (!transaction.early_home_valid[index]) return error.ValueUseEarlyHomeMissing;
        const request = &transaction.requests[index];
        const name = switch (request.source) {
            .named => |*identity| identity.slice(),
            .null_value, .unsupported => return error.ValueUseEarlySourceNotNamed,
        };
        const binding = transaction.selector.values.get(name) orelse
            return error.ValueUseUnresolvedSource;
        if (!std.meta.eql(binding.vreg, transaction.early_homes[index].source_vreg))
            return error.ValueUsePreparedViewStale;
        _ = try transaction.validateRequest(request);
        try validateExpectedType(request.expected, request.form);
        try validateSourceView(transaction.early_homes[index].loc, request.form);
    }

    fn materializeRequest(transaction: *ValueUseTransaction, request: *const StoredRequest) !void {
        const current = switch (request.source) {
            .named => |*name| blk: {
                // Deliberately resolve after all preparation/spill mutations.
                const binding = transaction.selector.values.get(name.slice()) orelse return error.ValueUseUnresolvedSource;
                if (binding.vreg.class != request.expected.register_class)
                    return error.ValueUseRegisterClassMismatch;
                try selector_state.validateAddressDependenciesForUse(transaction.selector, name.slice());
                break :blk try transaction.resolveNamedCurrent(name.slice());
            },
            .null_value => {
                try materializeNull(transaction.selector, request.destination);
                return;
            },
            .unsupported => return error.ValueUseUnsupportedSource,
        };
        try transaction.materializeRequestFromLoc(request, current, request.destination);
    }

    fn materializeRequestFromLoc(
        transaction: *ValueUseTransaction,
        request: *const StoredRequest,
        current: ValueLoc,
        destination: Destination,
    ) !void {
        try validateSourceView(current, request.form);
        switch (request.form) {
            .gpr32 => try materializeScalar32(transaction.selector, current, destination),
            .gpr64 => try materializeScalar64(transaction.selector, current, destination),
            .pointer, .stack_object_address => try materializePointer(transaction.selector, current, destination),
            .stack_f32_pair_byte_address => return error.ValueUsePreparedActionRequired,
            .pair_low_high, .pair_high_low => try materializePair(transaction.selector, current, request.form, destination),
            .stack_argument => return error.ValueUseStackArgumentUnsupported,
            .new_pair_ownership => return error.ValueUseNewPairOwnershipUnsupported,
        }
    }

    fn resolveNamedCurrent(transaction: *ValueUseTransaction, name: []const u8) !ValueLoc {
        return selector_state.resolveValue(transaction.selector, .{ .named = name }) orelse
            error.ValueUseUnresolvedSource;
    }

    fn buildPreparedRecord(transaction: *ValueUseTransaction, index: u8) !PreparedRecord {
        const request = &transaction.requests[index];
        if (request.destination != .prepared_source and request.destination != .prepared_view)
            return error.ValueUsePreparedViewMissing;
        const name = switch (request.source) {
            .named => |*identity| identity.slice(),
            else => return error.ValueUsePreparedViewUnsupported,
        };
        const binding = transaction.selector.values.get(name) orelse return error.ValueUseUnresolvedSource;
        const current = (try transaction.validateRequest(request)) orelse
            return error.ValueUsePreparedViewUnsupported;
        const prepared_loc = if (transaction.early_home_valid[index]) blk: {
            try transaction.validateEarlyHome(index);
            break :blk transaction.early_homes[index].loc;
        } else current;
        return .{
            .view = try preparedViewFromLoc(transaction, request, prepared_loc),
            .source_vreg = binding.vreg,
            .canonical_source_loc = current,
        };
    }
};

fn optionalPreparedActionEql(
    lhs: ?ValueUseTransaction.PreparedAction,
    rhs: ?ValueUseTransaction.PreparedAction,
) bool {
    if ((lhs == null) != (rhs == null)) return false;
    return if (lhs) |action| action.eql(rhs.?) else true;
}

fn preparedViewFromLoc(
    transaction: *ValueUseTransaction,
    request: *const ValueUseTransaction.StoredRequest,
    loc: ValueLoc,
) !ValueUseTransaction.PreparedView {
    try validateExpectedType(request.expected, request.form);
    try validateSourceView(loc, request.form);
    return switch (request.form) {
        .gpr32, .gpr64 => preparedScalarView(loc),
        .pointer => preparedPointerView(transaction, request, loc),
        .stack_f32_pair_byte_address => preparedStackF32PairAddressView(loc),
        .stack_object_address => preparedStackObjectView(loc),
        .pair_low_high, .pair_high_low => preparedPairView(loc, request.form),
        .stack_argument => error.ValueUseStackArgumentUnsupported,
        .new_pair_ownership => error.ValueUseNewPairOwnershipUnsupported,
    };
}

fn preparedStackF32PairAddressView(loc: ValueLoc) !ValueUseTransaction.PreparedView {
    return switch (loc) {
        .stack_f32_pair_ptr => |ptr| .{ .stack_f32_pair_address = .{
            .object_base_disp = ptr.object_base_disp,
            .disp = ptr.disp,
        } },
        else => error.ValueUseSourceViewMismatch,
    };
}

fn preparedScalarView(loc: ValueLoc) !ValueUseTransaction.PreparedView {
    return switch (loc) {
        .arg32, .scratch32 => |reg| .{ .register = .{ .register = .{ .gpr32 = reg }, .bits = 32 } },
        .arg64, .scratch64 => |reg| .{ .register = .{ .register = .{ .gpr64 = reg }, .bits = 64 } },
        .eax => .{ .register = .{ .register = .eax, .bits = 32 } },
        .rax => .{ .register = .{ .register = .rax, .bits = 64 } },
        .spill64 => |frame_index| .{ .spill = .{ .frame_index = frame_index, .bits = 64 } },
        else => error.ValueUseSourceViewMismatch,
    };
}

fn preparedPointerView(
    transaction: *ValueUseTransaction,
    request: *const ValueUseTransaction.StoredRequest,
    loc: ValueLoc,
) !ValueUseTransaction.PreparedView {
    return switch (loc) {
        .arg64, .scratch64, .rax, .spill64 => preparedScalarView(loc),
        .stack_scalar, .stack128, .stack_i32_array => preparedStackObjectView(loc),
        .stack_i32_ptr => |ptr| .{ .address_descriptor = try preparedAddressDescriptor(transaction, request, ptr) },
        .readonly_table_ptr => |ptr| .{ .table_pointer = .{
            .storage = switch (ptr.storage) {
                .reg => |reg| .{ .register = reg },
                .spill => |frame_index| .{ .spill = frame_index },
            },
            .symbol = try ValueUseTransaction.PreparedIdentity.init(ptr.symbol),
            .shape = ptr.shape,
            .offset = ptr.offset,
        } },
        else => error.ValueUseUnsupportedAddressForm,
    };
}

fn preparedStackObjectView(loc: ValueLoc) !ValueUseTransaction.PreparedView {
    return switch (loc) {
        .stack_scalar => |stack| .{ .stack_object = .{ .scalar = stack } },
        .stack128 => |disp| .{ .stack_object = .{ .integer128 = disp } },
        .stack_i32_array => |array| .{ .stack_object = .{ .integer32_array = array } },
        else => error.ValueUseSourceViewMismatch,
    };
}

fn preparedAddressDescriptor(
    transaction: *ValueUseTransaction,
    request: *const ValueUseTransaction.StoredRequest,
    ptr: selector_types.StackPtrLoc,
) !ValueUseTransaction.PreparedAddressDescriptor {
    const owner_name = switch (request.source) {
        .named => |*name| name.slice(),
        else => return error.ValueUsePreparedViewUnsupported,
    };
    var result = ValueUseTransaction.PreparedAddressDescriptor{ .disp = ptr.disp };
    if (ptr.index) |index| {
        const owner = transaction.selector.address_dependencies.ownerNamed(owner_name) orelse
            return error.AddressDependencyMissingOwner;
        try requireDependencyRole(owner, index.name, .index);
        result.index = try preparedAddressComponent(transaction, index.name, .index);
        if (index.addend_name) |addend_name| {
            try requireDependencyRole(owner, addend_name, .addend);
            result.addend = try preparedAddressComponent(transaction, addend_name, .addend);
        }
    }
    return result;
}

fn requireDependencyRole(
    owner: AddressDependencyDomain.OwnerView,
    name: []const u8,
    role: AddressDependencyDomain.Role,
) !void {
    for (owner.dependencies[0..owner.dependency_count]) |dependency| {
        if (dependency.role == role and std.mem.eql(u8, dependency.name, name)) return;
    }
    return error.AddressDependencyMissingIdentity;
}

fn preparedAddressComponent(
    transaction: *ValueUseTransaction,
    name: []const u8,
    role: AddressDependencyDomain.Role,
) !ValueUseTransaction.PreparedAddressComponent {
    const current = try transaction.resolveNamedCurrent(name);
    const binding = transaction.selector.values.get(name) orelse return error.ValueUseUnresolvedSource;
    return .{
        .identity = try ValueUseTransaction.PreparedIdentity.init(name),
        .role = role,
        .home = try preparedScalarHome(current),
        .vreg = binding.vreg,
    };
}

fn preparedScalarHome(loc: ValueLoc) !ValueUseTransaction.PreparedScalarHome {
    return switch (loc) {
        .arg32, .scratch32 => |reg| .{ .register = .{ .gpr32 = reg } },
        .arg64, .scratch64 => |reg| .{ .register = .{ .gpr64 = reg } },
        .eax => .{ .register = .eax },
        .rax => .{ .register = .rax },
        .spill64 => |frame_index| .{ .spill = frame_index },
        else => error.ValueUseSourceViewMismatch,
    };
}

fn preparedPairView(
    loc: ValueLoc,
    form: ValueUseTransaction.UseForm,
) !ValueUseTransaction.PreparedView {
    const low: ValueUseTransaction.PreparedPairLimb = switch (loc) {
        .arg128, .scratch128 => |pair| .{ .register = pair.lo },
        .spill128 => |pair| .{ .spill = pair.lo },
        else => return error.ValueUseSourceViewMismatch,
    };
    const high: ValueUseTransaction.PreparedPairLimb = switch (loc) {
        .arg128, .scratch128 => |pair| .{ .register = pair.hi },
        .spill128 => |pair| .{ .spill = pair.hi },
        else => return error.ValueUseSourceViewMismatch,
    };
    return .{ .read_only_pair = if (form == .pair_low_high)
        .{ .first = low, .second = high }
    else
        .{ .first = high, .second = low } };
}

fn executePreparedActionInternal(
    transaction: *ValueUseTransaction,
    view: *const ValueUseTransaction.PreparedView,
    request: *const ValueUseTransaction.StoredRequest,
    action: ValueUseTransaction.PreparedAction,
) !void {
    switch (action) {
        .validate_shape => |expected_shape| try validatePreparedShape(view, expected_shape),
        .emit_copy_to => |destination| {
            const current = try preparedViewLoc(view);
            const target = destination.asDestination();
            switch (request.form) {
                .gpr32 => try materializeScalar32(transaction.selector, current, target),
                .gpr64 => try materializeScalar64(transaction.selector, current, target),
                .pointer, .stack_object_address => try materializePointer(transaction.selector, current, target),
                .stack_f32_pair_byte_address => return error.ValueUsePreparedActionFormMismatch,
                .pair_low_high, .pair_high_low => return error.ValueUsePreparedActionFormMismatch,
                .stack_argument => return error.ValueUseStackArgumentUnsupported,
                .new_pair_ownership => return error.ValueUseNewPairOwnershipUnsupported,
            }
        },
        .form_byte_address => |address| try executeByteAddress(transaction, view, request, address),
        .form_scaled_address => |address| try executeScaledAddress(transaction, view, request, address),
        .form_readonly_table_address => |address| try executeReadOnlyTableAddress(transaction, view, request, address),
    }
}

fn executeByteAddress(
    transaction: *ValueUseTransaction,
    base_view: *const ValueUseTransaction.PreparedView,
    base_request: *const ValueUseTransaction.StoredRequest,
    action: ValueUseTransaction.ByteAddressAction,
) !void {
    const result_name = try ownActionIdentity(transaction, &action.result);
    switch (action.offset) {
        .constant => |offset| {
            const current = (try transaction.validateRequest(base_request)) orelse
                return error.ValueUseUnsupportedSource;
            switch (current) {
                .stack_f32_pair_ptr => |ptr| {
                    const adjusted = std.math.add(i64, ptr.disp, offset) catch
                        return error.ValueUseAddressOffsetOutOfRange;
                    const disp = std.math.cast(u32, adjusted) orelse
                        return error.ValueUseAddressOffsetOutOfRange;
                    const object_end = std.math.add(u32, ptr.object_base_disp, aggregate_object.byte_size) catch
                        return error.ValueUseAddressOffsetOutOfRange;
                    if (disp < ptr.object_base_disp or disp > object_end)
                        return error.ValueUseAddressOffsetOutOfRange;
                    try selector_state.bindValueLoc(transaction.selector, result_name, .{
                        .stack_f32_pair_ptr = .{
                            .object_base_disp = ptr.object_base_disp,
                            .disp = disp,
                        },
                    });
                },
                .stack_i32_ptr => |ptr| {
                    const adjusted = std.math.add(i64, ptr.disp, offset) catch
                        return error.ValueUseAddressOffsetOutOfRange;
                    const disp = std.math.cast(u32, adjusted) orelse
                        return error.ValueUseAddressOffsetOutOfRange;
                    try selector_state.bindValueLoc(transaction.selector, result_name, .{
                        .stack_i32_ptr = .{ .disp = disp, .index = ptr.index },
                    });
                },
                .readonly_table_ptr => |ptr| {
                    if (offset != 8 or ptr.offset != 0 or !ptr.shape.allowsOffset(8))
                        return error.ValueUseAddressOffsetOutOfRange;
                    var result = ptr;
                    result.offset = 8;
                    try selector_state.bindValueLoc(transaction.selector, result_name, .{ .readonly_table_ptr = result });
                },
                else => {
                    try materializeByteAddressPointer(transaction.selector, try preparedViewLoc(base_view), .rcx);
                    if (offset != 0) try selector_state.emitEflagsInstruction(
                        transaction.selector,
                        .{ .add_arg64_imm32 = .{ .reg = .rcx, .imm = offset } },
                        .write,
                    );
                    try selector_state.bindScratch(transaction.selector, result_name, .rcx, 64);
                },
            }
        },
        .request => |offset_handle| {
            const offset_view = try transaction.registeredOperandView(offset_handle);
            try materializeByteAddressPointer(transaction.selector, try preparedViewLoc(base_view), .r8);
            try materializeScalar64(transaction.selector, try preparedViewLoc(offset_view), .{ .gpr64 = .rcx });
            try selector_state.emitEflagsInstruction(transaction.selector, .add_r8_rcx, .write);
            try selector_state.bindScratch(transaction.selector, result_name, .rcx, 64);
        },
    }
}

fn executeScaledAddress(
    transaction: *ValueUseTransaction,
    base_view: *const ValueUseTransaction.PreparedView,
    base_request: *const ValueUseTransaction.StoredRequest,
    action: ValueUseTransaction.ScaledAddressAction,
) !void {
    const result_name = try ownActionIdentity(transaction, &action.result);
    const current = (try transaction.validateRequest(base_request)) orelse
        return error.ValueUseUnsupportedSource;
    switch (current) {
        .stack_i32_array => |array| {
            if (action.scale != 4) return error.ValueUseAddressDescriptorScaleMismatch;
            if (action.expected_stack_array_len) |expected_len| {
                if (array.len != expected_len) return error.ValueUseAddressDescriptorLengthMismatch;
            }
            switch (action.index) {
                .constant => |constant_index| {
                    const index = std.math.cast(u32, constant_index) orelse
                        return error.ValueUseAddressOffsetOutOfRange;
                    if (index >= array.len) return error.ValueUseAddressOffsetOutOfRange;
                    const byte_offset = std.math.mul(u32, index, action.scale) catch
                        return error.ValueUseAddressOffsetOutOfRange;
                    const disp = std.math.add(u32, array.base_disp, byte_offset) catch
                        return error.ValueUseAddressOffsetOutOfRange;
                    try selector_state.bindValueLoc(transaction.selector, result_name, .{
                        .stack_i32_ptr = .{ .disp = disp },
                    });
                },
                .request => |index_handle| {
                    const index_name = try ownRegisteredOperandName(transaction, index_handle);
                    const index_view = try transaction.registeredOperandView(index_handle);
                    try materializeScalar64(transaction.selector, try preparedViewLoc(index_view), .{ .gpr64 = .rcx });
                    try selector_state.bindValueLoc(transaction.selector, result_name, .{ .stack_i32_ptr = .{
                        .disp = array.base_disp,
                        .index = .{ .reg = .rcx, .name = index_name },
                    } });
                },
            }
        },
        .stack_i32_ptr => |ptr| {
            if (action.expected_stack_array_len != null)
                return error.ValueUseAddressDescriptorLengthMismatch;
            if (action.scale != 4) return error.ValueUseAddressDescriptorScaleMismatch;
            switch (action.index) {
                .constant => |constant_index| {
                    const offset = try scaledOffset(constant_index, action.scale);
                    const adjusted = std.math.add(i64, ptr.disp, offset) catch
                        return error.ValueUseAddressOffsetOutOfRange;
                    const disp = std.math.cast(u32, adjusted) orelse
                        return error.ValueUseAddressOffsetOutOfRange;
                    try selector_state.bindValueLoc(transaction.selector, result_name, .{
                        .stack_i32_ptr = .{ .disp = disp, .index = ptr.index },
                    });
                },
                .request => |index_handle| {
                    const existing = ptr.index orelse return error.ValueUseUnsupportedAddressForm;
                    if (existing.reg != .rcx) return error.ValueUseUnsupportedAddressForm;
                    if (existing.addend_name != null) return error.ValueUseUnsupportedAddressForm;
                    const addend_name = try ownRegisteredOperandName(transaction, index_handle);
                    try selector_state.bindValueLoc(transaction.selector, result_name, .{ .stack_i32_ptr = .{
                        .disp = ptr.disp,
                        .index = .{ .reg = existing.reg, .name = existing.name, .addend_name = addend_name },
                    } });
                },
            }
        },
        else => {
            if (action.expected_stack_array_len != null)
                return error.ValueUseAddressDescriptorLengthMismatch;
            try materializePointer(transaction.selector, try preparedViewLoc(base_view), .{ .gpr64 = .rcx });
            switch (action.index) {
                .constant => |constant_index| {
                    const offset = try scaledOffset(constant_index, action.scale);
                    if (offset != 0) try selector_state.emitEflagsInstruction(
                        transaction.selector,
                        .{ .add_arg64_imm32 = .{ .reg = .rcx, .imm = offset } },
                        .write,
                    );
                },
                .request => |index_handle| {
                    const index_view = try transaction.registeredOperandView(index_handle);
                    try materializeScalar64(transaction.selector, try preparedViewLoc(index_view), .{ .gpr64 = .r8 });
                    const shift = try scaleShift(action.scale);
                    if (shift != 0) try selector_state.emitEflagsInstruction(
                        transaction.selector,
                        .{ .shl_r8_imm6 = shift },
                        .write,
                    );
                    try selector_state.emitEflagsInstruction(transaction.selector, .add_r8_rcx, .write);
                },
            }
            try selector_state.bindScratch(transaction.selector, result_name, .rcx, 64);
        },
    }
}

fn executeReadOnlyTableAddress(
    transaction: *ValueUseTransaction,
    index_view: *const ValueUseTransaction.PreparedView,
    index_request: *const ValueUseTransaction.StoredRequest,
    action: ValueUseTransaction.ReadOnlyTableAddressAction,
) !void {
    _ = index_request;
    const result_name = try ownActionIdentity(transaction, &action.result);
    const symbol = try ownActionIdentity(transaction, &action.symbol);
    try materializeScalar64(transaction.selector, try preparedViewLoc(index_view), .{ .gpr64 = .r8 });
    try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
        .lea_global_arg64 = .{ .reg = .rcx, .symbol = symbol },
    });
    const shift = try scaleShift(action.scale);
    if (shift != 0) try selector_state.emitEflagsInstruction(
        transaction.selector,
        .{ .shl_r8_imm6 = shift },
        .write,
    );
    try selector_state.emitEflagsInstruction(transaction.selector, .add_r8_rcx, .write);
    try selector_state.bindValueLoc(transaction.selector, result_name, .{ .readonly_table_ptr = .{
        .storage = .{ .reg = .rcx },
        .symbol = symbol,
        .shape = action.shape,
    } });
}

fn ownActionIdentity(
    transaction: *ValueUseTransaction,
    identity: *const ValueUseTransaction.ActionIdentity,
) ![]const u8 {
    const owned = try transaction.selector.allocator.dupe(u8, identity.slice());
    errdefer transaction.selector.allocator.free(owned);
    try transaction.selector.machine.owned_labels.append(transaction.selector.allocator, owned);
    return owned;
}

fn ownRegisteredOperandName(
    transaction: *ValueUseTransaction,
    handle: ValueUseTransaction.RequestHandle,
) ![]const u8 {
    const index = try transaction.validateRegisteredOperandHandle(handle);
    const source = switch (transaction.requests[index].source) {
        .named => |*identity| identity.slice(),
        .null_value, .unsupported => return error.ValueUseActionOperandNotNamed,
    };
    const owned = try transaction.selector.allocator.dupe(u8, source);
    errdefer transaction.selector.allocator.free(owned);
    try transaction.selector.machine.owned_labels.append(transaction.selector.allocator, owned);
    return owned;
}

fn scaleShift(scale: u8) !u6 {
    if (scale == 0 or !std.math.isPowerOfTwo(scale)) return error.ValueUseAddressScaleInvalid;
    var value = scale;
    var shift: u6 = 0;
    while (value > 1) : (value >>= 1) shift += 1;
    return shift;
}

fn scaledOffset(index: i32, scale: u8) !i32 {
    _ = try scaleShift(scale);
    return std.math.mul(i32, index, scale) catch error.ValueUseAddressOffsetOutOfRange;
}

fn validatePreparedShape(
    view: *const ValueUseTransaction.PreparedView,
    expected: ValueUseTransaction.PreparedShape,
) !void {
    const matches = switch (expected) {
        .register_gpr32 => |reg| view.* == .register and
            view.register.register == .gpr32 and view.register.register.gpr32 == reg,
        .register_gpr64 => |reg| view.* == .register and
            view.register.register == .gpr64 and view.register.register.gpr64 == reg,
        .register_eax => view.* == .register and view.register.register == .eax,
        .register_rax => view.* == .register and view.register.register == .rax,
        .scalar_spill => |frame_index| view.* == .spill and view.spill.frame_index.eql(frame_index),
        .stack_scalar => |disp| view.* == .stack_object and
            view.stack_object == .scalar and view.stack_object.scalar.base_disp == disp,
        .stack_integer128 => |disp| view.* == .stack_object and
            view.stack_object == .integer128 and view.stack_object.integer128 == disp,
        .stack_i32_array => |array| view.* == .stack_object and
            view.stack_object == .integer32_array and std.meta.eql(view.stack_object.integer32_array, array),
        .address_descriptor => |shape| view.* == .address_descriptor and
            (view.address_descriptor.index != null) == shape.has_index and
            (view.address_descriptor.addend != null) == shape.has_addend,
        .table_register => |reg| view.* == .table_pointer and
            view.table_pointer.storage == .register and view.table_pointer.storage.register == reg,
        .table_spill => |frame_index| view.* == .table_pointer and
            view.table_pointer.storage == .spill and view.table_pointer.storage.spill.eql(frame_index),
        .pair_register => |pair| view.* == .read_only_pair and
            view.read_only_pair.first == .register and view.read_only_pair.second == .register and
            view.read_only_pair.first.register == pair.lo and view.read_only_pair.second.register == pair.hi,
        .pair_spill => |pair| view.* == .read_only_pair and
            view.read_only_pair.first == .spill and view.read_only_pair.second == .spill and
            view.read_only_pair.first.spill.eql(pair.lo) and view.read_only_pair.second.spill.eql(pair.hi),
    };
    if (!matches) return error.ValueUsePreparedShapeMismatch;
}

fn preparedViewLoc(view: *const ValueUseTransaction.PreparedView) !ValueLoc {
    return switch (view.*) {
        .register => |value| switch (value.register) {
            .gpr32 => |reg| .{ .scratch32 = reg },
            .gpr64 => |reg| .{ .scratch64 = reg },
            .eax => .eax,
            .rax => .rax,
        },
        .spill => |value| .{ .spill64 = value.frame_index },
        .stack_object => |object| switch (object) {
            .scalar => |stack| .{ .stack_scalar = stack },
            .integer128 => |disp| .{ .stack128 = disp },
            .integer32_array => |array| .{ .stack_i32_array = array },
        },
        .address_descriptor => |*address| .{ .stack_i32_ptr = .{
            .disp = address.disp,
            .index = if (address.index) |*index| .{
                .reg = .rcx,
                .name = index.identity.slice(),
                .addend_name = if (address.addend) |*addend| addend.identity.slice() else null,
            } else null,
        } },
        .stack_f32_pair_address => |address| .{ .stack_f32_pair_ptr = .{
            .object_base_disp = address.object_base_disp,
            .disp = address.disp,
        } },
        .table_pointer => |*table| .{ .readonly_table_ptr = .{
            .storage = switch (table.storage) {
                .register => |reg| .{ .reg = reg },
                .spill => |frame_index| .{ .spill = frame_index },
            },
            .symbol = table.symbol.slice(),
            .shape = table.shape,
            .offset = table.offset,
        } },
        .read_only_pair => error.ValueUsePreparedActionFormMismatch,
    };
}

fn preparedRecordEql(
    lhs: *const ValueUseTransaction.PreparedRecord,
    rhs: *const ValueUseTransaction.PreparedRecord,
) bool {
    return std.meta.eql(lhs.source_vreg, rhs.source_vreg) and
        std.meta.eql(lhs.canonical_source_loc, rhs.canonical_source_loc) and
        preparedViewEql(&lhs.view, &rhs.view);
}

fn preparedViewEql(
    lhs: *const ValueUseTransaction.PreparedView,
    rhs: *const ValueUseTransaction.PreparedView,
) bool {
    if (std.meta.activeTag(lhs.*) != std.meta.activeTag(rhs.*)) return false;
    return switch (lhs.*) {
        .register => |value| std.meta.eql(value, rhs.register),
        .spill => |value| std.meta.eql(value, rhs.spill),
        .stack_object => |*value| preparedStackObjectEql(value, &rhs.stack_object),
        .address_descriptor => |*value| preparedAddressDescriptorEql(value, &rhs.address_descriptor),
        .stack_f32_pair_address => |value| std.meta.eql(value, rhs.stack_f32_pair_address),
        .table_pointer => |*value| preparedTablePointerEql(value, &rhs.table_pointer),
        .read_only_pair => |value| std.meta.eql(value, rhs.read_only_pair),
    };
}

fn preparedStackObjectEql(
    lhs: *const ValueUseTransaction.PreparedStackObject,
    rhs: *const ValueUseTransaction.PreparedStackObject,
) bool {
    if (std.meta.activeTag(lhs.*) != std.meta.activeTag(rhs.*)) return false;
    return switch (lhs.*) {
        .scalar => |value| std.meta.eql(value, rhs.scalar),
        .integer128 => |value| value == rhs.integer128,
        .integer32_array => |value| std.meta.eql(value, rhs.integer32_array),
    };
}

fn preparedAddressDescriptorEql(
    lhs: *const ValueUseTransaction.PreparedAddressDescriptor,
    rhs: *const ValueUseTransaction.PreparedAddressDescriptor,
) bool {
    if (lhs.disp != rhs.disp or (lhs.index == null) != (rhs.index == null) or
        (lhs.addend == null) != (rhs.addend == null)) return false;
    if (lhs.index) |*component| {
        if (!preparedAddressComponentEql(component, &rhs.index.?)) return false;
    }
    if (lhs.addend) |*component| {
        if (!preparedAddressComponentEql(component, &rhs.addend.?)) return false;
    }
    return true;
}

fn preparedAddressComponentEql(
    lhs: *const ValueUseTransaction.PreparedAddressComponent,
    rhs: *const ValueUseTransaction.PreparedAddressComponent,
) bool {
    return lhs.identity.eql(&rhs.identity) and lhs.role == rhs.role and
        std.meta.eql(lhs.home, rhs.home) and std.meta.eql(lhs.vreg, rhs.vreg);
}

fn preparedTablePointerEql(
    lhs: *const ValueUseTransaction.PreparedTablePointer,
    rhs: *const ValueUseTransaction.PreparedTablePointer,
) bool {
    return std.meta.eql(lhs.storage, rhs.storage) and lhs.symbol.eql(&rhs.symbol) and
        lhs.shape == rhs.shape and lhs.offset == rhs.offset;
}

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
    source_request_index: ?u8,
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
    if (request.destination == .prepared_source) {
        if (request.prepared_action != null) return error.ValueUsePreparedActionUnexpected;
        return switch (request.form) {
            .gpr32, .gpr64, .pointer, .stack_object_address, .pair_low_high, .pair_high_low => {},
            .stack_f32_pair_byte_address => error.ValueUsePreparedActionRequired,
            .stack_argument => error.ValueUseStackArgumentUnsupported,
            .new_pair_ownership => error.ValueUseNewPairOwnershipUnsupported,
        };
    }
    if (request.destination == .prepared_view) {
        const action = request.prepared_action orelse return error.ValueUsePreparedActionMissing;
        switch (request.form) {
            .gpr32, .gpr64, .pointer, .stack_f32_pair_byte_address, .stack_object_address, .pair_low_high, .pair_high_low => {},
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
        };
    }
    if (request.prepared_action != null) return error.ValueUsePreparedActionUnexpected;
    const valid = switch (request.form) {
        .gpr32 => request.destination == .gpr32 or request.destination == .eax,
        .gpr64 => request.destination == .gpr64 or request.destination == .rax,
        .pointer, .stack_object_address => request.destination == .gpr64 or request.destination == .rax,
        .stack_f32_pair_byte_address => false,
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
        .stack_argument => return error.ValueUseStackArgumentUnsupported,
        .new_pair_ownership => return error.ValueUseNewPairOwnershipUnsupported,
    }
}

/// Only forms whose complete materialization is exhaustively classified by
/// the EFLAGS authority as preserving may participate in the planner's early
/// phase. Address arithmetic, generated writes, pairs, and accumulator writes
/// deliberately remain in the ordinary phase.
fn earlyCopyIsFlagsPreserving(loc: ValueLoc, form: ValueUseTransaction.UseForm) bool {
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
        .stack_argument,
        .new_pair_ownership,
        => false,
    };
}

/// The dormant sequencing amendment is intentionally narrower than the set of
/// all preserving copies: it advances reloads whose accepted ordering must
/// precede preservation of another mapped destination. In-register copies do
/// not need this phase and retain their existing order.
fn earlySequencingCandidate(loc: ValueLoc, form: ValueUseTransaction.UseForm) bool {
    return switch (form) {
        .gpr32, .gpr64 => loc == .spill64,
        .pointer => switch (loc) {
            .spill64 => true,
            .readonly_table_ptr => |ptr| ptr.storage == .spill,
            else => false,
        },
        else => false,
    };
}

fn requestDestinationNodes(
    transaction: *ValueUseTransaction,
    request: *const ValueUseTransaction.StoredRequest,
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
                    _ = try transaction.validateRegisteredOperandHandle(handle);
                    try result.append(.r8);
                    try result.append(.rcx);
                },
            },
            .form_scaled_address => |address| switch (current orelse return error.ValueUseUnresolvedSource) {
                .stack_i32_array => switch (address.index) {
                    .constant => {},
                    .request => |handle| {
                        _ = try transaction.validateRegisteredOperandHandle(handle);
                        try result.append(.rcx);
                    },
                },
                .stack_i32_ptr => switch (address.index) {
                    .constant => {},
                    .request => |handle| _ = try transaction.validateRegisteredOperandHandle(handle),
                },
                else => switch (address.index) {
                    .constant => try result.append(.rcx),
                    .request => |handle| {
                        _ = try transaction.validateRegisteredOperandHandle(handle);
                        try result.append(.rcx);
                        try result.append(.r8);
                    },
                },
            },
            .form_readonly_table_address => {
                try result.append(.rcx);
                try result.append(.r8);
            },
        },
        .stack_argument => return error.ValueUseStackArgumentUnsupported,
        .new_pair => return error.ValueUseNewPairOwnershipUnsupported,
    }
    return result;
}

fn requestMappings(
    transaction: *ValueUseTransaction,
    request: *const ValueUseTransaction.StoredRequest,
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
                    const offset_current = try transaction.registeredOperandCurrent(handle);
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
                            .source = scalarSourceNode(try transaction.registeredOperandCurrent(handle)),
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
                                .source = scalarSourceNode(try transaction.registeredOperandCurrent(handle)),
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
            .validate_shape, .emit_copy_to => {},
        }
        if (action != .emit_copy_to) return mappings;
    }
    const destinations = try requestDestinationNodes(transaction, request, current);
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

fn validateCopyActionForm(
    form: ValueUseTransaction.UseForm,
    destination: ValueUseTransaction.CopyDestination,
) !void {
    const valid = switch (form) {
        .gpr32 => destination == .gpr32 or destination == .eax,
        .gpr64, .pointer, .stack_object_address => destination == .gpr64 or destination == .rax,
        .stack_f32_pair_byte_address => false,
        .pair_low_high, .pair_high_low => false,
        .stack_argument => return error.ValueUseStackArgumentUnsupported,
        .new_pair_ownership => return error.ValueUseNewPairOwnershipUnsupported,
    };
    if (!valid) return error.ValueUsePreparedActionFormMismatch;
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

fn materializeByteAddressPointer(selector: *ComposedBlockSelector, current: ValueLoc, destination: ArgReg) !void {
    switch (current) {
        .stack_f32_pair_ptr => try selector_state.materializeLocIntoLoc(
            selector,
            current,
            .{ .scratch64 = destination },
        ),
        else => try materializePointer(selector, current, .{ .gpr64 = destination }),
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
