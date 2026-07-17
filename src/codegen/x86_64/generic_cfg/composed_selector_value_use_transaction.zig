const std = @import("std");
const builtin = @import("builtin");
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
const composed_helpers = @import("composed_helpers.zig");

const ArgReg = x86_64_types.ArgReg;
const FrameIndex = x86_64_types.FrameIndex;
const RegPair = selector_types.RegPair;
const ValueBinding = selector_types.ValueBinding;
const ValueLoc = selector_types.ValueLoc;
const VirtualReg = selector_types.VirtualReg;
const VirtualRegClass = selector_types.VirtualRegClass;
const ComposedBlockSelector = state_data.ComposedBlockSelector;
const AddressDependencyDomain = address_dependencies.AddressDependencyDomain;
const Diagnostic = @import("inspection.zig").Diagnostic;
const AccumulatorDefinition = selector_state.AccumulatorDefinition;
const AccumulatorDefinitionSession = selector_state.AccumulatorDefinitionSession;
const AccumulatorDisplacementPolicy = selector_state.AccumulatorDisplacementPolicy;
const AccumulatorPreparationEffect = selector_state.AccumulatorPreparationEffect;

/// Instruction-level authority for planning several value uses before any
/// selector mutation. Newly added action variants remain dormant until their
/// complete semantic consumer family is separately reviewed and wired.
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
    semantic_order_edges: [max_requests][max_requests]bool =
        [_][max_requests]bool{[_]bool{false} ** max_requests} ** max_requests,
    ordered_operands: [max_requests]OrderedOperand = undefined,
    ordered_operand_count: u8 = 0,
    early_homes: [max_requests]EarlyPreparedHome = undefined,
    early_home_valid: [max_requests]bool = [_]bool{false} ** max_requests,
    prepared_views: [max_requests]PreparedRecord = undefined,
    prepared_view_valid: [max_requests]bool = [_]bool{false} ** max_requests,
    switch_boundary_applied: [max_requests]bool = [_]bool{false} ** max_requests,
    view_generation: u32 = 1,
    action_diagnostic: ?Diagnostic = null,
    /// First request to which a transaction failure can be attributed. This
    /// diagnostic-only identity deliberately survives automatic rollback.
    failed_request: ?RequestHandle = null,
    accumulator_session: ?AccumulatorDefinitionSession = null,
    memcpy_test_failure: if (builtin.is_test) ?MemcpyTestFailure else void = if (builtin.is_test) null else {},
    load_test_failure: if (builtin.is_test) ?LoadTestFailure else void = if (builtin.is_test) null else {},

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
        /// Exact legacy branch-condition homes only. This is intentionally
        /// narrower than the generic semantic low32 relation.
        branch_condition,
        /// Exact legacy compare-chain switch homes, including the read-only
        /// low limb of an existing pair and an action-owned immediate.
        switch_condition,
        /// Exact legacy inline-memcpy pointer homes. This action-specific form
        /// deliberately excludes generic stack/table/null pointer capability.
        memcpy_pointer,
        /// Exact legacy inline-memcpy i64 length homes.
        memcpy_length,
        /// Action-only load address. Compatibility is derived from the
        /// closed load action and canonical binding/home; consumers neither
        /// discover nor choose a physical source representation.
        load_address,
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

    /// Opaque identity for the snapshot-free accumulator state-transition
    /// session owned by this instruction authority.
    pub const AccumulatorSessionHandle = struct {
        authority: usize,
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

    /// Store a named i1/i32 value. The action is owned by the value request;
    /// the pointer is the semantic secondary operand, preserving the accepted
    /// value-before-address staging order.
    pub const StoreScalarAction = struct {
        pointer: RequestHandle,
        bits: u8,
    };

    /// Store an inline i1/i32 value. The immediate is semantic intent rather
    /// than a discovered source home and is emitted before pointer staging.
    pub const StoreImmediateAction = struct {
        value: i32,
        bits: u8,
    };

    /// Store a named i64 value. The action is owned by the pointer request and
    /// stages that pointer before the value, matching the accepted helper.
    pub const StoreI64Action = struct {
        value: RequestHandle,
    };

    /// Store the address of one stack object into another stack object. Both
    /// operands are semantic requests; no stack descriptor escapes.
    pub const StoreStackPointerAction = struct {
        destination: RequestHandle,
    };

    /// Complete inline-memcpy semantic intent. The action is owned by the
    /// destination-pointer request; source and length are already-registered
    /// operands. No discovered home, call result, or general-call detail is
    /// supplied by the consumer.
    pub const MemcpyAction = struct {
        source: RequestHandle,
        length: RequestHandle,
    };

    pub const MemcpyTestFailure = enum {
        after_preservation,
        after_destination,
        after_source,
        after_length,
        after_call_append,
    };

    pub const ScalarLoadKind = enum {
        ordinary,
        readonly_pointer,
    };

    /// A genuine EAX/RAX integer load. Result ownership remains with the
    /// subordinate accumulator session; this action owns only the complete
    /// source-home-dependent load sequence.
    pub const ScalarLoadAction = struct {
        kind: ScalarLoadKind,
        bits: u16,
    };

    /// Existing readonly-pointer i96/i128 result semantics. The planner
    /// freezes the pair selected by the pre-existing pair authority; the
    /// action neither allocates a new pair kind nor changes result ownership.
    pub const ReadOnlyPairLoadAction = struct {
        result: ActionIdentity,
        bits: u16,
    };

    /// Alias-only i128 load from an existing stack object.
    pub const StackI128AliasLoadAction = struct {
        result: ActionIdentity,
    };

    /// Non-accumulator i16 table load into the accepted R8 scratch result.
    pub const ReadOnlyTableI16LoadAction = struct {
        result: ActionIdentity,
    };

    /// Closed, semantic load-request failures. These variants disclose only
    /// the accepted diagnostic class; no source home, binding, register, spill
    /// slot, or retry capability crosses the transaction boundary.
    pub const LoadRequestError = error{
        ValueUseLoadOrdinaryStackWidth,
        ValueUseLoadOrdinaryStackArrayWidth,
        ValueUseLoadOrdinaryPointerWidth,
        ValueUseLoadOrdinaryPointerRejected,
        ValueUseLoadReadonlyPointerProvenance,
        ValueUseLoadReadonlyPointerSpill,
        ValueUseLoadReadonlyPointerAlias,
        ValueUseLoadReadonlyWidth,
        ValueUseLoadReadonlyPairUnavailable,
        ValueUseLoadReadonlyTableOffset,
        ValueUseLoadReadonlyTableType,
        ValueUseLoadReadonlyTableSpill,
    };

    pub const LoadTestFailure = enum {
        after_pointer_staging,
        after_preservation,
        after_first_partial_load,
    };

    pub const max_switch_cases = 8;

    pub const SwitchCaseIntent = struct {
        value: i32,
        target: []const u8,
    };

    /// Fixed-owned compare-chain semantics. Input target slices are copied by
    /// init; no borrowed case/target storage survives registration.
    pub const SwitchCompareChainAction = struct {
        bits: u8,
        case_count: u8,
        case_values: [max_switch_cases]i32 = [_]i32{0} ** max_switch_cases,
        case_targets: [max_switch_cases]ActionIdentity = [_]ActionIdentity{.{}} ** max_switch_cases,
        default_target: ActionIdentity,
        exhaustive_case: ?u8 = null,

        pub fn init(
            bits: u8,
            cases: []const SwitchCaseIntent,
            default_target: []const u8,
            exhaustive_case: ?u8,
        ) !SwitchCompareChainAction {
            if (bits == 0 or bits > 32) return error.ValueUseSwitchWidthUnsupported;
            if (cases.len == 0 or cases.len > max_switch_cases)
                return error.ValueUseSwitchCaseCountUnsupported;
            var result = SwitchCompareChainAction{
                .bits = bits,
                .case_count = @intCast(cases.len),
                .default_target = try ActionIdentity.init(default_target),
                .exhaustive_case = exhaustive_case,
            };
            for (cases, 0..) |case, index| {
                for (result.case_values[0..index]) |previous| {
                    if (previous == case.value) return error.ValueUseSwitchDuplicateCase;
                }
                result.case_values[index] = case.value;
                result.case_targets[index] = try ActionIdentity.init(case.target);
            }
            if (exhaustive_case) |index| {
                if (index >= cases.len) return error.ValueUseSwitchExhaustiveCaseOutOfRange;
            }
            return result;
        }

        fn validate(action: *const SwitchCompareChainAction) !void {
            if (action.bits == 0 or action.bits > 32) return error.ValueUseSwitchWidthUnsupported;
            if (action.case_count == 0 or action.case_count > max_switch_cases)
                return error.ValueUseSwitchCaseCountUnsupported;
            try action.default_target.validate();
            for (0..action.case_count) |index| {
                try action.case_targets[index].validate();
                for (action.case_values[0..index]) |previous| {
                    if (previous == action.case_values[index])
                        return error.ValueUseSwitchDuplicateCase;
                }
            }
            if (action.exhaustive_case) |index| {
                if (index >= action.case_count) return error.ValueUseSwitchExhaustiveCaseOutOfRange;
            }
        }
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
        store_scalar: StoreScalarAction,
        store_immediate: StoreImmediateAction,
        store_i64: StoreI64Action,
        store_stack_pointer: StoreStackPointerAction,
        branch_condition,
        switch_compare_chain: SwitchCompareChainAction,
        inline_memcpy: MemcpyAction,
        load_scalar: ScalarLoadAction,
        load_readonly_pair: ReadOnlyPairLoadAction,
        load_stack_i128_alias: StackI128AliasLoadAction,
        load_readonly_table_i16: ReadOnlyTableI16LoadAction,

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

    const PreparedCondition = union(enum) {
        eax,
        rax_low32,
        register32: ArgReg,
        register64_low32: ArgReg,
        pair_low32: ArgReg,
        spill_low32: FrameIndex,
        immediate: i32,
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
        condition: PreparedCondition,
    };

    const PreparedRecord = struct {
        view: PreparedView,
        source_vreg: VirtualReg,
        canonical_source_loc: ValueLoc,
    };

    const EarlyPlan = struct {
        destination: ?ArgReg = null,
    };

    const OperandPhase = enum {
        no_op,
        safe_early,
        ordinary,
    };

    const OrderedOperand = struct {
        request_index: u8,
        role: SemanticRole,
        phase: OperandPhase,
    };

    const SemanticRole = enum(u8) {
        primary,
        secondary,
        tertiary,
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
        int: i128,
        null_value,
        unsupported,

        fn from(input: ir.Value) !Source {
            return switch (input) {
                .named => |name| .{ .named = try Identity.init(name) },
                .int => |integer| .{ .int = integer },
                .null_value => .null_value,
                .fp, .undef, .poison, .zero_initializer, .vector, .constant_expr => .unsupported,
            };
        }

        fn eql(source: *const Source, other: *const Source) bool {
            if (std.meta.activeTag(source.*) != std.meta.activeTag(other.*)) return false;
            return switch (source.*) {
                .named => |*name| name.eql(&other.named),
                .int => |integer| integer == other.int,
                .null_value, .unsupported => true,
            };
        }

        fn value(source: *const Source) ir.Value {
            return switch (source.*) {
                .named => |*name| .{ .named = name.slice() },
                .int => |integer| .{ .int = integer },
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

    const PhiDestinationEntry = struct {
        name: []const u8,
        loc: ValueLoc,
    };

    const Snapshot = struct {
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

        fn init(selector: *ComposedBlockSelector) !Snapshot {
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

        fn deinit(snapshot: *Snapshot, selector: *ComposedBlockSelector) void {
            selector.allocator.free(snapshot.phi_destinations);
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
    const max_mappings = max_requests * 3;

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
        errdefer transaction.resetSemanticOrderPlan();
        // Validate the action-owned role graph before destination planning can
        // obscure a semantic ownership contradiction with a physical conflict.
        try transaction.validateSemanticOrderTopology();
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
                transaction.noteRequestBoundaryError(request_index, err);
                return err;
            };
            const current = if (deferred_switch) null else try transaction.validateRequestAt(request_index);
            const destination_nodes = requestDestinationNodes(transaction, request, current) catch |err| {
                transaction.noteRequestBoundaryError(request_index, err);
                return err;
            };
            for (destination_nodes.slice()) |destination_node| {
                const node_index = @intFromEnum(destination_node);
                if (destinations[node_index]) return error.ValueUseConflictingDestination;
                destinations[node_index] = true;
            }
            const request_mappings = requestMappings(transaction, request, request_index, current) catch |err| {
                transaction.noteRequestBoundaryError(request_index, err);
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
        try transaction.planEarlyMaterializations(mappings[0..mapping_count]);
        transaction.write_nodes = writes;
        transaction.request_phase = .sealed;
    }

    pub fn prepare(transaction: *ValueUseTransaction) !void {
        try transaction.requireActive();
        if (transaction.request_phase != .sealed) return error.ValueUsePrepareBeforeSeal;
        errdefer transaction.rollbackInternal();

        for (transaction.requests[0..transaction.request_count], 0..) |request, index| {
            if (request.prepared_action != null and request.prepared_action.? == .switch_compare_chain and
                !transaction.switch_boundary_applied[index])
            {
                return error.ValueUseSwitchBoundaryRequired;
            }
        }

        const saved_preserve = transaction.selector.preserve_current_position_values;
        transaction.selector.preserve_current_position_values = true;
        defer transaction.selector.preserve_current_position_values = saved_preserve;

        try transaction.materializeEarlyPlans();
        var nodes = transaction.write_nodes;
        for (transaction.requests[0..transaction.request_count], 0..) |*request, request_index_usize| {
            if (request.destination == .prepared_source) continue;
            if (request.destination == .prepared_view and request.prepared_action.? != .emit_copy_to) continue;
            if (request.form != .pointer and request.form != .stack_object_address) continue;
            const request_index: u8 = @intCast(request_index_usize);
            const current = switch (request.source) {
                .named => |*name| transaction.resolveNamedCurrent(name.slice()) catch |err| {
                    transaction.noteRequestBoundaryError(request_index, err);
                    return err;
                },
                .int, .null_value, .unsupported => continue,
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

    /// Applies the accepted ordinary-switch CFG boundary inside the existing
    /// instruction authority. The switch condition is intentionally not
    /// resolved during seal; this method performs the boundary first, then
    /// validates the canonical post-boundary home.
    pub fn applySwitchBoundary(
        transaction: *ValueUseTransaction,
        handle: RequestHandle,
    ) !void {
        try transaction.requireActive();
        if (transaction.request_phase != .sealed) return error.ValueUseSwitchBoundaryPhase;
        errdefer transaction.rollbackInternal();
        const index = try transaction.validateHandle(handle);
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
        _ = try transaction.validateRequestAt(index);
        transaction.switch_boundary_applied[index] = true;
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
            try transaction.materializeRequest(@intCast(index), request);
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
        if (transaction.requests[index].destination != .prepared_view or !transaction.prepared_view_valid[index]) {
            transaction.recordRequestFailure(index);
            return error.ValueUsePreparedViewMissing;
        }
        transaction.request_phase = .views_exposed;
        return .{ .request = handle, .view_generation = transaction.view_generation };
    }

    /// Opens the subordinate result-definition core only after the complete
    /// use plan has sealed. No selector state or address domain is copied.
    pub fn beginAccumulatorSession(
        transaction: *ValueUseTransaction,
    ) !AccumulatorSessionHandle {
        try transaction.requireActive();
        if (transaction.request_phase != .sealed)
            return error.ValueUseAccumulatorSessionRequiresSealedPlan;
        if (transaction.accumulator_session != null)
            return error.ValueUseAccumulatorSessionAlreadyOpen;
        transaction.accumulator_session = AccumulatorDefinitionSession.init(transaction.selector);
        return .{
            .authority = @intFromPtr(transaction),
            .generation = transaction.view_generation,
        };
    }

    pub fn prepareAccumulator(
        transaction: *ValueUseTransaction,
        handle: AccumulatorSessionHandle,
        effect: AccumulatorPreparationEffect,
        displacement: AccumulatorDisplacementPolicy,
    ) !?Diagnostic {
        const session = try transaction.validateAccumulatorSession(handle);
        errdefer transaction.rollbackInternal();
        if (try session.prepare(effect, displacement)) |diagnostic| {
            transaction.rollbackInternal();
            return diagnostic;
        }
        return null;
    }

    pub fn prepareAccumulatorCallBeforeArguments(
        transaction: *ValueUseTransaction,
        handle: AccumulatorSessionHandle,
        effect: AccumulatorPreparationEffect,
    ) !?Diagnostic {
        const session = try transaction.validateAccumulatorSession(handle);
        errdefer transaction.rollbackInternal();
        if (try session.prepareCallBeforeArguments(effect)) |diagnostic| {
            transaction.rollbackInternal();
            return diagnostic;
        }
        return null;
    }

    pub fn finishAccumulatorCallPreparationAfterArguments(
        transaction: *ValueUseTransaction,
        handle: AccumulatorSessionHandle,
    ) !void {
        const session = try transaction.validateAccumulatorSession(handle);
        errdefer transaction.rollbackInternal();
        try session.finishCallPreparationAfterArguments();
    }

    pub fn materializeAccumulator(
        transaction: *ValueUseTransaction,
        handle: AccumulatorSessionHandle,
        source: ir.Value,
        definition: AccumulatorDefinition,
    ) !void {
        const session = try transaction.validateAccumulatorSession(handle);
        errdefer transaction.rollbackInternal();
        try session.materialize(source, definition);
    }

    pub fn spillAccumulatorValue(
        transaction: *ValueUseTransaction,
        handle: AccumulatorSessionHandle,
        name: []const u8,
    ) !void {
        const session = try transaction.validateAccumulatorSession(handle);
        errdefer transaction.rollbackInternal();
        try session.spill(name);
    }

    pub fn defineAccumulatorResult(
        transaction: *ValueUseTransaction,
        handle: AccumulatorSessionHandle,
        name: []const u8,
        definition: AccumulatorDefinition,
    ) !void {
        const session = try transaction.validateAccumulatorSession(handle);
        errdefer transaction.rollbackInternal();
        try session.define(name, definition);
    }

    pub fn finalizeAccumulatorResult(
        transaction: *ValueUseTransaction,
        handle: AccumulatorSessionHandle,
    ) !void {
        const session = try transaction.validateAccumulatorSession(handle);
        errdefer transaction.rollbackInternal();
        try session.finalize();
    }

    /// The subordinate session never owns commit. This explicit rejection is
    /// stable even after definition; only the outer transaction may commit.
    pub fn commitAccumulatorSession(
        transaction: *ValueUseTransaction,
        handle: AccumulatorSessionHandle,
    ) !void {
        _ = try transaction.validateAccumulatorSession(handle);
        return error.ValueUseAccumulatorIndependentCommit;
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
        if (!transaction.prepared_view_valid[index]) {
            transaction.recordRequestFailure(index);
            return error.ValueUsePreparedViewMissing;
        }
        const refreshed = try transaction.buildPreparedRecord(index);
        if (!preparedRecordEql(&transaction.prepared_views[index], &refreshed)) {
            transaction.recordRequestFailure(index);
            return error.ValueUsePreparedViewStale;
        }
        const action = transaction.requests[index].prepared_action orelse {
            transaction.recordRequestFailure(index);
            return error.ValueUsePreparedActionMissing;
        };
        try transaction.validateActionDependenciesCanonical(action);
        executePreparedActionInternal(transaction, index, &refreshed.view, &transaction.requests[index], action) catch |err| {
            transaction.noteRequestBoundaryError(index, err);
            return err;
        };
        // Defense in depth: even the closed internal action must not relocate
        // or rebind its source. Any violation rolls back speculative emission.
        if (actionOwnsOrderedWrites(action)) {
            try transaction.validateConsumedActionAfter(index, action);
        } else {
            const after_consumption = try transaction.buildPreparedRecord(index);
            if (!preparedRecordEql(&transaction.prepared_views[index], &after_consumption)) {
                transaction.recordRequestFailure(index);
                return error.ValueUsePreparedViewStale;
            }
            try transaction.validateActionDependenciesCanonical(action);
        }
        transaction.prepared_view_valid[index] = false;
    }

    pub fn commit(transaction: *ValueUseTransaction) !void {
        try transaction.requireActive();
        if (transaction.request_phase != .materialized and transaction.request_phase != .views_exposed)
            return error.ValueUseCommitBeforeMaterialization;
        if (transaction.accumulator_session) |*session| {
            if (!session.isFinalized()) return error.ValueUseAccumulatorResultNotFinalized;
        }
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

    /// Returns the original caller-clobber preservation diagnostic when a
    /// closed action reports ValueUseActionDiagnostic. The transaction has
    /// already rolled back when this is observed.
    pub fn actionDiagnostic(transaction: *const ValueUseTransaction) ?Diagnostic {
        return transaction.action_diagnostic;
    }

    /// Answers only whether `handle` is the first request-specific failure.
    /// No request identity, index, source, home, or retry capability escapes.
    pub fn failedRequestIs(
        transaction: *const ValueUseTransaction,
        handle: RequestHandle,
    ) bool {
        const failed = transaction.failed_request orelse return false;
        return failed.authority == @intFromPtr(transaction) and
            failed.authority == handle.authority and
            failed.index == handle.index and
            failed.generation == handle.generation;
    }

    /// White-box rollback boundary control. This is unavailable in every
    /// production build and is guarded from production consumers.
    pub fn setMemcpyTestFailure(
        transaction: *ValueUseTransaction,
        failure: ?MemcpyTestFailure,
    ) !void {
        if (!builtin.is_test) return error.ValueUseTestHookUnavailable;
        transaction.memcpy_test_failure = failure;
    }

    /// White-box load-action rollback boundary control. Unavailable in every
    /// production build and guarded from production consumers.
    pub fn setLoadTestFailure(
        transaction: *ValueUseTransaction,
        failure: ?LoadTestFailure,
    ) !void {
        if (!builtin.is_test) return error.ValueUseTestHookUnavailable;
        transaction.load_test_failure = failure;
    }

    fn requireActive(transaction: *const ValueUseTransaction) !void {
        if (transaction.lifecycle != .active) return error.ValueUseTransactionClosed;
    }

    fn rollbackInternal(transaction: *ValueUseTransaction) void {
        transaction.snapshot.restore(transaction.selector);
        transaction.accumulator_session = null;
        transaction.request_count = 0;
        transaction.request_phase = .registering;
        transaction.write_nodes = [_]bool{false} ** physical_node_count;
        transaction.early_plans = [_]EarlyPlan{.{}} ** max_requests;
        transaction.resetSemanticOrderPlan();
        transaction.early_home_valid = [_]bool{false} ** max_requests;
        transaction.prepared_view_valid = [_]bool{false} ** max_requests;
        transaction.switch_boundary_applied = [_]bool{false} ** max_requests;
        transaction.view_generation +%= 1;
        if (transaction.view_generation == 0) transaction.view_generation = 1;
        transaction.lifecycle = .rolled_back;
    }

    fn validateAccumulatorSession(
        transaction: *ValueUseTransaction,
        handle: AccumulatorSessionHandle,
    ) !*AccumulatorDefinitionSession {
        try transaction.requireActive();
        if (handle.authority != @intFromPtr(transaction) or
            handle.generation != transaction.view_generation)
        {
            return error.ValueUseAccumulatorSessionStale;
        }
        return if (transaction.accumulator_session) |*session|
            session
        else
            error.ValueUseAccumulatorSessionMissing;
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

    fn recordRequestFailure(transaction: *ValueUseTransaction, index: u8) void {
        if (transaction.failed_request == null)
            transaction.failed_request = transaction.handleFor(index);
    }

    fn noteRequestBoundaryError(
        transaction: *ValueUseTransaction,
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
            else => transaction.recordRequestFailure(index),
        }
    }

    fn validateRequestAt(transaction: *ValueUseTransaction, index: u8) !?ValueLoc {
        return transaction.validateRequest(&transaction.requests[index]) catch |err| {
            transaction.noteRequestBoundaryError(index, err);
            return err;
        };
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
            .store_scalar => |store| {
                if (store.bits != 1 and store.bits != 32) return error.ValueUseStoreWidthUnsupported;
                const index = try transaction.validateRegisteredOperandHandle(store.pointer);
                validateStorePointerOperand(&transaction.requests[index], true) catch |err| {
                    transaction.noteRequestBoundaryError(index, err);
                    return err;
                };
            },
            .store_immediate => |store| {
                if (store.bits != 1 and store.bits != 32) return error.ValueUseStoreWidthUnsupported;
                if (store.bits == 1 and store.value != 0 and store.value != 1)
                    return error.ValueUseStoreImmediateOutOfRange;
            },
            .store_i64 => |store| {
                const index = try transaction.validateRegisteredOperandHandle(store.value);
                validateStoreI64ValueOperand(&transaction.requests[index]) catch |err| {
                    transaction.noteRequestBoundaryError(index, err);
                    return err;
                };
            },
            .store_stack_pointer => |store| {
                const index = try transaction.validateRegisteredOperandHandle(store.destination);
                validateStoreStackObjectOperand(&transaction.requests[index]) catch |err| {
                    transaction.noteRequestBoundaryError(index, err);
                    return err;
                };
            },
            .branch_condition => {},
            .switch_compare_chain => |*switch_action| try switch_action.validate(),
            .inline_memcpy => |memcpy| {
                const source = try transaction.validateRegisteredOperandHandle(memcpy.source);
                const length = try transaction.validateRegisteredOperandHandle(memcpy.length);
                validateMemcpyPointerOperand(&transaction.requests[source]) catch |err| {
                    transaction.noteRequestBoundaryError(source, err);
                    return err;
                };
                validateMemcpyLengthOperand(&transaction.requests[length]) catch |err| {
                    transaction.noteRequestBoundaryError(length, err);
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

    fn noteRegisteredOperandBoundaryError(
        transaction: *ValueUseTransaction,
        handle: RequestHandle,
        err: anyerror,
    ) void {
        const index = transaction.validateRegisteredOperandHandle(handle) catch return;
        transaction.noteRequestBoundaryError(index, err);
    }

    fn registeredOperandCurrent(transaction: *ValueUseTransaction, handle: RequestHandle) !ValueLoc {
        const index = try transaction.validateRegisteredOperandHandle(handle);
        return (try transaction.validateRequestAt(index)) orelse {
            transaction.recordRequestFailure(index);
            return error.ValueUseUnsupportedSource;
        };
    }

    fn registeredOperandView(
        transaction: *ValueUseTransaction,
        handle: RequestHandle,
    ) !*const PreparedView {
        const index = try transaction.validateRegisteredOperandHandle(handle);
        if (!transaction.prepared_view_valid[index]) {
            transaction.recordRequestFailure(index);
            return error.ValueUsePreparedViewMissing;
        }
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
            .store_scalar => |store| try transaction.validateOperandCanonical(store.pointer),
            .store_i64 => |store| try transaction.validateOperandCanonical(store.value),
            .store_stack_pointer => |store| try transaction.validateOperandCanonical(store.destination),
            .inline_memcpy => |memcpy| {
                try transaction.validateOperandCanonical(memcpy.source);
                try transaction.validateOperandCanonical(memcpy.length);
            },
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

    fn validateConsumedActionAfter(
        transaction: *ValueUseTransaction,
        owner_index: u8,
        action: PreparedAction,
    ) !void {
        try transaction.validateConsumedOperandAfter(owner_index);
        if (try transaction.actionSecondaryOperand(action)) |secondary|
            try transaction.validateConsumedOperandAfter(secondary);
        if (try transaction.actionTertiaryOperand(action)) |tertiary|
            try transaction.validateConsumedOperandAfter(tertiary);
    }

    fn validateConsumedOperandAfter(transaction: *ValueUseTransaction, index: u8) !void {
        return transaction.validateConsumedOperandAfterUnchecked(index) catch |err| {
            transaction.noteRequestBoundaryError(index, err);
            return err;
        };
    }

    fn validateConsumedOperandAfterUnchecked(transaction: *ValueUseTransaction, index: u8) !void {
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
        const refreshed = try transaction.buildPreparedRecord(index);
        if (preparedRecordEql(&transaction.prepared_views[index], &refreshed)) return;
        // A source genuinely live after the consuming instruction may be
        // durably relocated by the ordinary clobber-preservation authority.
        // The stable vreg, typed request validation, and canonical dependency
        // re-derivation above distinguish that relocation from a rebind.
        if (!try selector_state.valueIsLiveAfterCurrent(transaction.selector, name))
            return error.ValueUsePreparedViewStale;
    }

    fn validateOperandCanonical(transaction: *ValueUseTransaction, handle: RequestHandle) !void {
        const index = try transaction.validateRegisteredOperandHandle(handle);
        if (!transaction.prepared_view_valid[index]) {
            transaction.recordRequestFailure(index);
            return error.ValueUsePreparedViewMissing;
        }
        const refreshed = try transaction.buildPreparedRecord(index);
        if (!preparedRecordEql(&transaction.prepared_views[index], &refreshed)) {
            transaction.recordRequestFailure(index);
            return error.ValueUsePreparedViewStale;
        }
    }

    fn validateRequest(transaction: *ValueUseTransaction, request: *const StoredRequest) !?ValueLoc {
        try validateFormAndDestination(request);
        switch (request.source) {
            .unsupported => return error.ValueUseUnsupportedSource,
            .int => |value| {
                if (request.form != .switch_condition or request.prepared_action == null or
                    request.prepared_action.? != .switch_compare_chain)
                {
                    return error.ValueUseUnsupportedSource;
                }
                try validateExpectedType(request.expected, request.form);
                _ = std.math.cast(i32, value) orelse return error.ValueUseSwitchImmediateOutOfRange;
                return null;
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
                const current = try transaction.resolveNamedCurrent(name.slice());
                try selector_state.validateAddressDependenciesForUse(transaction.selector, name.slice());
                if (!try selector_state.valueIsLiveAtOrAfterCurrent(transaction.selector, name.slice()))
                    return error.ValueUseExpiredSource;
                try validateBindingCompatibility(binding, request, current);
                try validateSourceView(current, request.form);
                return current;
            },
        }
    }

    fn validateSemanticOrderTopology(transaction: *ValueUseTransaction) !void {
        var owners = [_]?u8{null} ** max_requests;
        var edges = [_][max_requests]bool{[_]bool{false} ** max_requests} ** max_requests;
        for (transaction.requests[0..transaction.request_count], 0..) |*request, index_usize| {
            const action = request.prepared_action orelse continue;
            const index: u8 = @intCast(index_usize);
            if (owners[index]) |owner| {
                if (owner != index) return error.ValueUseEarlyOrderingConflict;
            }
            owners[index] = index;
            const secondary = try transaction.actionSecondaryOperand(action) orelse continue;
            if (secondary == index) return error.ValueUseEarlyOrderingCycle;
            if (owners[secondary]) |owner| {
                if (owner != index) return error.ValueUseEarlyOrderingConflict;
            }
            owners[secondary] = index;
            edges[index][secondary] = true;
            if (try transaction.actionTertiaryOperand(action)) |tertiary| {
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
        transaction: *ValueUseTransaction,
        action: PreparedAction,
    ) !?u8 {
        return switch (action) {
            .form_byte_address => |address| switch (address.offset) {
                .constant => null,
                .request => |handle| try transaction.validateRegisteredOperandHandle(handle),
            },
            .form_scaled_address => |address| switch (address.index) {
                .constant => null,
                .request => |handle| try transaction.validateRegisteredOperandHandle(handle),
            },
            .store_scalar => |store| try transaction.validateRegisteredOperandHandle(store.pointer),
            .store_i64 => |store| try transaction.validateRegisteredOperandHandle(store.value),
            .store_stack_pointer => |store| try transaction.validateRegisteredOperandHandle(store.destination),
            .inline_memcpy => |memcpy| try transaction.validateRegisteredOperandHandle(memcpy.source),
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
        transaction: *ValueUseTransaction,
        action: PreparedAction,
    ) !?u8 {
        return switch (action) {
            .inline_memcpy => |memcpy| try transaction.validateRegisteredOperandHandle(memcpy.length),
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
            => null,
        };
    }

    fn resetSemanticOrderPlan(transaction: *ValueUseTransaction) void {
        transaction.semantic_order_edges =
            [_][max_requests]bool{[_]bool{false} ** max_requests} ** max_requests;
        transaction.ordered_operand_count = 0;
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

        var owners = [_]?u8{null} ** max_requests;
        var roots: [max_requests]u8 = undefined;
        var root_count: u8 = 0;
        transaction.resetSemanticOrderPlan();

        // Actions own their semantic operands. A secondary request cannot be
        // silently shared by two instruction authorities.
        for (transaction.requests[0..transaction.request_count], 0..) |*request, index_usize| {
            const action = request.prepared_action orelse continue;
            const index: u8 = @intCast(index_usize);
            owners[index] = index;
            roots[root_count] = index;
            root_count += 1;
            if (try transaction.actionSecondaryOperand(action)) |secondary| {
                if (owners[secondary]) |owner| {
                    if (owner != index) return error.ValueUseEarlyOrderingConflict;
                }
                owners[secondary] = index;
                transaction.semantic_order_edges[index][secondary] = true;
            }
            if (try transaction.actionTertiaryOperand(action)) |tertiary| {
                const secondary = (try transaction.actionSecondaryOperand(action)) orelse
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
        try transaction.sortSemanticRoots(roots[0..root_count], mappings);

        for (roots[0..root_count]) |root| {
            var prefix_open = true;
            try transaction.appendOrderedOperand(
                root,
                .primary,
                &prefix_open,
                mappings,
                source_counts,
                source_nodes,
            );
            if (transaction.requests[root].prepared_action) |action| {
                if (try transaction.actionSecondaryOperand(action)) |secondary| try transaction.appendOrderedOperand(
                    secondary,
                    .secondary,
                    &prefix_open,
                    mappings,
                    source_counts,
                    source_nodes,
                );
                if (try transaction.actionTertiaryOperand(action)) |tertiary| try transaction.appendOrderedOperand(
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
        transaction: *ValueUseTransaction,
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
                    .named => try transaction.validateRequestAt(request_index) orelse null,
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
        transaction: *ValueUseTransaction,
        roots: []u8,
        mappings: []const Mapping,
    ) !void {
        if (roots.len < 2) return;
        for (1..roots.len) |index| {
            const current = roots[index];
            var insertion = index;
            while (insertion > 0 and transaction.semanticRootLessThan(current, roots[insertion - 1], mappings)) {
                roots[insertion] = roots[insertion - 1];
                insertion -= 1;
            }
            roots[insertion] = current;
        }
        for (roots[1..], roots[0 .. roots.len - 1]) |current, previous| {
            if (!transaction.semanticRootLessThan(previous, current, mappings) and
                !transaction.semanticRootLessThan(current, previous, mappings))
            {
                return error.ValueUseEarlyOrderingConflict;
            }
        }
    }

    /// Fixed structural ordering for independent authorities. It is derived
    /// from physical destinations and stable semantic source identities, never
    /// function names or request-registration order.
    fn semanticRootLessThan(
        transaction: *ValueUseTransaction,
        lhs: u8,
        rhs: u8,
        mappings: []const Mapping,
    ) bool {
        const lhs_node = transaction.firstStructuralDestination(lhs, mappings);
        const rhs_node = transaction.firstStructuralDestination(rhs, mappings);
        if (@intFromEnum(lhs_node) != @intFromEnum(rhs_node))
            return @intFromEnum(lhs_node) < @intFromEnum(rhs_node);
        const lhs_source = &transaction.requests[lhs].source;
        const rhs_source = &transaction.requests[rhs].source;
        return sourceStructuralOrder(lhs_source, rhs_source) == .lt;
    }

    fn firstStructuralDestination(
        transaction: *ValueUseTransaction,
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

    fn materializeEarlyPlans(transaction: *ValueUseTransaction) !void {
        for (transaction.ordered_operands[0..transaction.ordered_operand_count]) |ordered| {
            if (ordered.phase != .safe_early) continue;
            const index = ordered.request_index;
            transaction.materializeEarlyPlan(index) catch |err| {
                transaction.noteRequestBoundaryError(index, err);
                return err;
            };
        }
    }

    fn materializeEarlyPlan(transaction: *ValueUseTransaction, index: u8) !void {
        const plan = transaction.early_plans[index];
        const destination_reg = plan.destination orelse return;
        if (!selector_state.scratchRegIsProvenFree(transaction.selector, destination_reg))
            return error.ValueUseEarlyDestinationNoLongerFree;
        const request = &transaction.requests[index];
        const name = switch (request.source) {
            .named => |*identity| identity.slice(),
            .int, .null_value, .unsupported => return error.ValueUseEarlySourceNotNamed,
        };
        const binding = transaction.selector.values.get(name) orelse
            return error.ValueUseUnresolvedSource;
        const current = (try transaction.validateRequestAt(index)) orelse
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

    fn validateEarlyHome(transaction: *ValueUseTransaction, index: u8) !void {
        return transaction.validateEarlyHomeUnchecked(index) catch |err| {
            transaction.noteRequestBoundaryError(index, err);
            return err;
        };
    }

    fn validateEarlyHomeUnchecked(transaction: *ValueUseTransaction, index: u8) !void {
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
        _ = try transaction.validateRequestAt(index);
        try validateExpectedType(request.expected, request.form);
        try validateSourceView(transaction.early_homes[index].loc, request.form);
    }

    fn materializeRequest(
        transaction: *ValueUseTransaction,
        index: u8,
        request: *const StoredRequest,
    ) !void {
        return transaction.materializeRequestUnchecked(request) catch |err| {
            transaction.noteRequestBoundaryError(index, err);
            return err;
        };
    }

    fn materializeRequestUnchecked(transaction: *ValueUseTransaction, request: *const StoredRequest) !void {
        const current = switch (request.source) {
            .named => |*name| blk: {
                // Deliberately resolve after all preparation/spill mutations.
                const binding = transaction.selector.values.get(name.slice()) orelse return error.ValueUseUnresolvedSource;
                try selector_state.validateAddressDependenciesForUse(transaction.selector, name.slice());
                const current = try transaction.resolveNamedCurrent(name.slice());
                try validateBindingCompatibility(binding, request, current);
                break :blk current;
            },
            .null_value => {
                try materializeNull(transaction.selector, request.destination);
                return;
            },
            .int => return error.ValueUseUnsupportedSource,
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
            .stack_f32_pair_byte_address,
            .branch_condition,
            .switch_condition,
            .memcpy_pointer,
            .memcpy_length,
            .load_address,
            => return error.ValueUsePreparedActionRequired,
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
        return transaction.buildPreparedRecordUnchecked(index) catch |err| {
            transaction.noteRequestBoundaryError(index, err);
            return err;
        };
    }

    fn buildPreparedRecordUnchecked(transaction: *ValueUseTransaction, index: u8) !PreparedRecord {
        const request = &transaction.requests[index];
        if (request.destination != .prepared_source and request.destination != .prepared_view)
            return error.ValueUsePreparedViewMissing;
        const name = switch (request.source) {
            .named => |*identity| identity.slice(),
            .int => |value| {
                if (request.form != .switch_condition or request.prepared_action == null or
                    request.prepared_action.? != .switch_compare_chain)
                {
                    return error.ValueUsePreparedViewUnsupported;
                }
                try validateExpectedType(request.expected, request.form);
                const immediate = std.math.cast(i32, value) orelse
                    return error.ValueUseSwitchImmediateOutOfRange;
                return .{
                    .view = .{ .condition = .{ .immediate = immediate } },
                    .source_vreg = .{
                        .index = std.math.maxInt(usize),
                        .class = .gpr32,
                        .bits = request.expected.ty.int,
                    },
                    .canonical_source_loc = .eax,
                };
            },
            else => return error.ValueUsePreparedViewUnsupported,
        };
        const binding = transaction.selector.values.get(name) orelse return error.ValueUseUnresolvedSource;
        const current = (try transaction.validateRequestAt(index)) orelse
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
        .pointer, .load_address => preparedPointerView(transaction, request, loc),
        .stack_f32_pair_byte_address => preparedStackF32PairAddressView(loc),
        .stack_object_address => preparedStackObjectView(loc),
        .pair_low_high, .pair_high_low => preparedPairView(loc, request.form),
        .branch_condition, .switch_condition => preparedConditionView(loc),
        .memcpy_pointer, .memcpy_length => preparedMemcpyScalarView(loc),
        .stack_argument => error.ValueUseStackArgumentUnsupported,
        .new_pair_ownership => error.ValueUseNewPairOwnershipUnsupported,
    };
}

fn preparedMemcpyScalarView(loc: ValueLoc) !ValueUseTransaction.PreparedView {
    return switch (loc) {
        .arg64, .scratch64, .rax, .spill64 => preparedScalarView(loc),
        .arg128, .scratch128 => |pair| .{
            .register = .{ .register = .{ .gpr64 = pair.lo }, .bits = 64 },
        },
        else => error.ValueUseSourceViewMismatch,
    };
}

fn preparedConditionView(loc: ValueLoc) !ValueUseTransaction.PreparedView {
    return .{ .condition = switch (loc) {
        .eax => .eax,
        .rax => .rax_low32,
        .arg32, .scratch32 => |reg| .{ .register32 = reg },
        .arg64, .scratch64 => |reg| .{ .register64_low32 = reg },
        .arg128, .scratch128 => |pair| .{ .pair_low32 = pair.lo },
        .spill64 => |frame_index| .{ .spill_low32 = frame_index },
        else => return error.ValueUseSourceViewMismatch,
    } };
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
    request_index: u8,
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
                .stack_f32_pair_byte_address,
                .pair_low_high,
                .pair_high_low,
                .branch_condition,
                .switch_condition,
                .memcpy_pointer,
                .memcpy_length,
                .load_address,
                => return error.ValueUsePreparedActionFormMismatch,
                .stack_argument => return error.ValueUseStackArgumentUnsupported,
                .new_pair_ownership => return error.ValueUseNewPairOwnershipUnsupported,
            }
        },
        .form_byte_address => |address| try executeByteAddress(transaction, view, request, address),
        .form_scaled_address => |address| try executeScaledAddress(transaction, view, request, address),
        .form_readonly_table_address => |address| try executeReadOnlyTableAddress(transaction, view, request, address),
        .store_scalar => |store| try executeStoreScalar(transaction, view, store),
        .store_immediate => |store| try executeStoreImmediate(transaction, view, store),
        .store_i64 => |store| try executeStoreI64(transaction, view, store),
        .store_stack_pointer => |store| try executeStoreStackPointer(transaction, view, store),
        .branch_condition => try executeBranchCondition(transaction, view),
        .switch_compare_chain => |switch_action| try executeSwitchCompareChain(transaction, view, &switch_action),
        .inline_memcpy => |memcpy| try executeInlineMemcpy(transaction, request_index, memcpy),
        .load_scalar => |load| try executeScalarLoad(transaction, request_index, view, load),
        .load_readonly_pair => |load| try executeReadOnlyPairLoad(transaction, request_index, view, &load),
        .load_stack_i128_alias => |load| try executeStackI128AliasLoad(transaction, view, &load),
        .load_readonly_table_i16 => |load| try executeReadOnlyTableI16Load(transaction, view, &load),
    }
}

fn executeScalarLoad(
    transaction: *ValueUseTransaction,
    request_index: u8,
    view: *const ValueUseTransaction.PreparedView,
    action: ValueUseTransaction.ScalarLoadAction,
) !void {
    const session = if (transaction.accumulator_session) |*session| session else return error.ValueUseLoadAccumulatorSessionRequired;

    switch (action.kind) {
        .ordinary => {
            try prepareScalarLoadAccumulator(transaction, session);
            try refreshLoadPreparedOperand(transaction, request_index);
            try executeOrdinaryScalarLoad(
                transaction,
                &transaction.prepared_views[request_index].view,
                action.bits,
            );
        },
        .readonly_pointer => {
            const ptr_reg = try stageReadOnlyScalarLoadPointer(transaction, view);
            try prepareScalarLoadAccumulator(transaction, session);
            try refreshLoadPreparedOperand(transaction, request_index);
            try executeReadOnlyScalarLoad(transaction, ptr_reg, action.bits);
        },
    }
}

fn prepareScalarLoadAccumulator(
    transaction: *ValueUseTransaction,
    session: *AccumulatorDefinitionSession,
) !void {
    if (try session.prepare(.preserve, .spill_live)) |diagnostic| {
        transaction.action_diagnostic = diagnostic;
        return error.ValueUseActionDiagnostic;
    }
    try failLoadForTest(transaction, .after_preservation);
}

fn refreshLoadPreparedOperand(transaction: *ValueUseTransaction, request_index: u8) !void {
    if (!transaction.prepared_view_valid[request_index]) {
        transaction.recordRequestFailure(request_index);
        return error.ValueUsePreparedViewMissing;
    }
    transaction.prepared_views[request_index] = try transaction.buildPreparedRecord(request_index);
}

fn executeOrdinaryScalarLoad(
    transaction: *ValueUseTransaction,
    view: *const ValueUseTransaction.PreparedView,
    bits: u16,
) !void {
    switch (view.*) {
        .stack_object => |stack| switch (stack) {
            .scalar => |scalar| switch (bits) {
                8 => if (scalar.base_disp <= std.math.maxInt(u8))
                    try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
                        .load_stack_disp8_u8_eax = @intCast(scalar.base_disp),
                    })
                else
                    try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
                        .load_stack_disp32_u8_eax = scalar.base_disp,
                    }),
                64 => try appendPreparedLoadStackU64IntoRax(transaction.selector, scalar.base_disp),
                else => return error.ValueUseLoadOrdinaryStackWidth,
            },
            .integer32_array => |array| try appendPreparedLoadStackI32(
                transaction,
                .{ .disp = array.base_disp },
            ),
            .integer128 => return error.ValueUseLoadOrdinaryStackWidth,
        },
        .address_descriptor => |descriptor| try appendPreparedLoadStackI32(transaction, descriptor),
        .register => |prepared| {
            if (bits != 32) return error.ValueUseLoadOrdinaryPointerWidth;
            const reg = switch (prepared.register) {
                .gpr64 => |reg| reg,
                else => return error.ValueUseLoadOrdinaryPointerRejected,
            };
            try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
                .load_arg_ptr_eax = reg,
            });
        },
        .spill => |spill| {
            if (bits != 32 or spill.bits < 64) return error.ValueUseLoadOrdinaryPointerWidth;
            try materializeScalar64(
                transaction.selector,
                .{ .spill64 = spill.frame_index },
                .{ .gpr64 = .rcx },
            );
            try failLoadForTest(transaction, .after_pointer_staging);
            try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
                .load_arg_ptr_eax = .rcx,
            });
        },
        else => return error.ValueUseLoadOrdinaryPointerRejected,
    }
}

fn appendPreparedLoadStackI32(
    transaction: *ValueUseTransaction,
    descriptor: ValueUseTransaction.PreparedAddressDescriptor,
) !void {
    if (descriptor.index) |index| {
        try materializeScalar64(
            transaction.selector,
            preparedScalarHomeLoc(index.home),
            .{ .gpr64 = .rcx },
        );
        if (descriptor.addend) |addend| {
            try materializeScalar64(
                transaction.selector,
                preparedScalarHomeLoc(addend.home),
                .{ .gpr64 = .r8 },
            );
            try selector_state.emitEflagsInstruction(transaction.selector, .add_r8_rcx, .write);
        }
        if (descriptor.disp <= std.math.maxInt(u8)) {
            try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
                .load_stack_rcx4_disp8_eax = @intCast(descriptor.disp),
            });
        } else {
            try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
                .load_stack_rcx4_disp32_eax = descriptor.disp,
            });
        }
    } else if (descriptor.disp <= std.math.maxInt(u8)) {
        try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
            .load_stack_disp8_eax = @intCast(descriptor.disp),
        });
    } else {
        try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
            .load_stack_disp32_eax = descriptor.disp,
        });
    }
}

fn appendPreparedLoadStackU64IntoRax(selector: *ComposedBlockSelector, disp: u32) !void {
    if (disp <= std.math.maxInt(u8)) {
        try selector.machine.instructions.append(selector.allocator, .{
            .load_stack_disp8_rax = @intCast(disp),
        });
    } else {
        try selector.machine.instructions.append(selector.allocator, .{
            .load_stack_disp32_rax = disp,
        });
    }
}

fn preparedScalarHomeLoc(home: ValueUseTransaction.PreparedScalarHome) ValueLoc {
    return switch (home) {
        .register => |reg| switch (reg) {
            .gpr32 => |value| .{ .scratch32 = value },
            .gpr64 => |value| .{ .scratch64 = value },
            .eax => .eax,
            .rax => .rax,
        },
        .spill => |frame_index| .{ .spill64 = frame_index },
    };
}

fn executeReadOnlyScalarLoad(
    transaction: *ValueUseTransaction,
    ptr_reg: ArgReg,
    bits: u16,
) !void {
    switch (bits) {
        8 => try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
            .load_arg_ptr_disp8_u8_eax = .{ .reg = ptr_reg, .offset = 0 },
        }),
        16 => try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
            .load_arg_ptr_disp8_u16_eax = .{ .reg = ptr_reg, .offset = 0 },
        }),
        32 => try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
            .load_arg_ptr_disp8_eax = .{ .reg = ptr_reg, .offset = 0 },
        }),
        56 => {
            const scratch: ArgReg = if (ptr_reg == .rcx) .r8 else .rcx;
            try selector_state.clobberArgReg(transaction.selector, scratch);
            try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
                .load_arg_ptr_disp8_u16_eax = .{ .reg = ptr_reg, .offset = 4 },
            });
            try failLoadForTest(transaction, .after_first_partial_load);
            try selector_state.emitEflagsInstruction(transaction.selector, .{ .shl_rax_imm6 = 32 }, .write);
            try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
                .mov_rax_to_arg = scratch,
            });
            try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
                .load_arg_ptr_disp8_u8_eax = .{ .reg = ptr_reg, .offset = 6 },
            });
            try selector_state.emitEflagsInstruction(transaction.selector, .{ .shl_rax_imm6 = 48 }, .write);
            try selector_state.emitEflagsInstruction(transaction.selector, .{
                .binary_arg_rax = .{ .op = .@"or", .reg = scratch },
            }, .write);
            try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
                .mov_rax_to_arg = scratch,
            });
            try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
                .load_arg_ptr_disp8_eax = .{ .reg = ptr_reg, .offset = 0 },
            });
            try selector_state.emitEflagsInstruction(transaction.selector, .{
                .binary_arg_rax = .{ .op = .@"or", .reg = scratch },
            }, .write);
        },
        64 => try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
            .load_arg_ptr_disp8_rax = .{ .reg = ptr_reg, .offset = 0 },
        }),
        else => return error.ValueUseLoadReadonlyWidth,
    }
}

fn stageReadOnlyScalarLoadPointer(
    transaction: *ValueUseTransaction,
    view: *const ValueUseTransaction.PreparedView,
) !ArgReg {
    return materializePreparedLoadPointer(transaction, view, .rdi) catch |err|
        return if (err == error.OutOfMemory) err else error.ValueUseLoadReadonlyPointerSpill;
}

fn materializePreparedLoadPointer(
    transaction: *ValueUseTransaction,
    view: *const ValueUseTransaction.PreparedView,
    spill_destination: ArgReg,
) !ArgReg {
    return switch (view.*) {
        .register => |prepared| switch (prepared.register) {
            .gpr64 => |reg| reg,
            else => error.ValueUseLoadReadonlyPointerProvenance,
        },
        .spill => |spill| blk: {
            if (spill.bits < 64) return error.ValueUseLoadReadonlyPointerProvenance;
            try materializeScalar64(
                transaction.selector,
                .{ .spill64 = spill.frame_index },
                .{ .gpr64 = spill_destination },
            );
            try failLoadForTest(transaction, .after_pointer_staging);
            break :blk spill_destination;
        },
        else => error.ValueUseLoadReadonlyPointerProvenance,
    };
}

fn executeReadOnlyPairLoad(
    transaction: *ValueUseTransaction,
    request_index: u8,
    view: *const ValueUseTransaction.PreparedView,
    action: *const ValueUseTransaction.ReadOnlyPairLoadAction,
) !void {
    _ = request_index;
    var ptr_reg = materializePreparedLoadPointer(transaction, view, .rdi) catch |err|
        return if (err == error.OutOfMemory) err else error.ValueUseLoadReadonlyPointerSpill;
    if (action.bits != 96 and action.bits != 128)
        return error.ValueUseLoadReadonlyWidth;
    // Preserve the accepted authority and timing exactly: spill-backed
    // pointers stage first, then the existing pair chooser observes the
    // resulting selector/spill state. Seal conservatively declared every
    // pair register the chooser can return, so this late read-only decision
    // cannot introduce an unplanned physical write.
    const pair = try selector_state.choosePairScratchForClobber(transaction.selector, null) orelse
        return error.ValueUseLoadReadonlyPairUnavailable;
    if (pair.contains(ptr_reg)) {
        const current = switch (view.*) {
            .register => |prepared| switch (prepared.register) {
                .gpr64 => |reg| ValueLoc{ .scratch64 = reg },
                else => return error.ValueUseLoadReadonlyPointerProvenance,
            },
            else => return error.ValueUseLoadReadonlyPointerProvenance,
        };
        materializeScalar64(transaction.selector, current, .{ .gpr64 = .rdi }) catch |err|
            return if (err == error.OutOfMemory) err else error.ValueUseLoadReadonlyPointerAlias;
        ptr_reg = .rdi;
        try failLoadForTest(transaction, .after_pointer_staging);
    }
    try selector_state.clobberArgReg(transaction.selector, pair.lo);
    try selector_state.clobberArgReg(transaction.selector, pair.hi);
    try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
        .load_arg_ptr_disp8_rax = .{ .reg = ptr_reg, .offset = 0 },
    });
    try failLoadForTest(transaction, .after_first_partial_load);
    try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
        .mov_rax_to_arg = pair.lo,
    });
    try transaction.selector.machine.instructions.append(transaction.selector.allocator, if (action.bits == 96)
        .{ .load_arg_ptr_disp8_eax = .{ .reg = ptr_reg, .offset = 8 } }
    else
        .{ .load_arg_ptr_disp8_rax = .{ .reg = ptr_reg, .offset = 8 } });
    try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
        .mov_rax_to_arg = pair.hi,
    });
    const result_name = try ownActionIdentity(transaction, &action.result);
    try selector_state.bindResultLoc(transaction.selector, result_name, .{ .scratch128 = pair });
}

fn executeStackI128AliasLoad(
    transaction: *ValueUseTransaction,
    view: *const ValueUseTransaction.PreparedView,
    action: *const ValueUseTransaction.StackI128AliasLoadAction,
) !void {
    const disp = switch (view.*) {
        .stack_object => |stack| switch (stack) {
            .integer128 => |disp| disp,
            else => return error.ValueUseLoadOrdinaryStackWidth,
        },
        else => return error.ValueUseLoadOrdinaryPointerRejected,
    };
    const result_name = try ownActionIdentity(transaction, &action.result);
    try selector_state.bindResultLoc(transaction.selector, result_name, .{ .stack128_value = disp });
}

fn executeReadOnlyTableI16Load(
    transaction: *ValueUseTransaction,
    view: *const ValueUseTransaction.PreparedView,
    action: *const ValueUseTransaction.ReadOnlyTableI16LoadAction,
) !void {
    const table = switch (view.*) {
        .table_pointer => |table| table,
        else => return error.ValueUseLoadReadonlyTableType,
    };
    const base: ArgReg = switch (table.storage) {
        .register => |reg| reg,
        .spill => |frame_index| blk: {
            materializeScalar64(
                transaction.selector,
                .{ .spill64 = frame_index },
                .{ .gpr64 = .rcx },
            ) catch |err| return if (err == error.OutOfMemory) err else error.ValueUseLoadReadonlyTableSpill;
            failLoadForTest(transaction, .after_pointer_staging) catch
                return error.ValueUseLoadReadonlyTableSpill;
            break :blk .rcx;
        },
    };
    if (table.shape != .i16_128 or table.offset != 0)
        return error.ValueUseLoadReadonlyTableType;
    try selector_state.clobberArgReg(transaction.selector, .r8);
    try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
        .load_arg_ptr_disp8_u16_arg = .{ .base = base, .dst = .r8, .offset = 0 },
    });
    const result_name = try ownActionIdentity(transaction, &action.result);
    try selector_state.bindResultLoc(transaction.selector, result_name, .{ .scratch32 = .r8 });
}

fn failLoadForTest(
    transaction: *ValueUseTransaction,
    boundary: ValueUseTransaction.LoadTestFailure,
) !void {
    if (builtin.is_test) {
        if (transaction.load_test_failure == boundary)
            return error.ValueUseLoadTestFailure;
    }
}

fn executeInlineMemcpy(
    transaction: *ValueUseTransaction,
    destination_index: u8,
    action: ValueUseTransaction.MemcpyAction,
) !void {
    // Validate the final call clobber before caller preservation or argument
    // staging mutates selector state. The emission authority repeats this
    // check while applying the semantic record immediately before append.
    var next_eflags = transaction.selector.eflags;
    try next_eflags.apply(.clobber);

    if (try selector_state.spillLiveCallerClobbersForCall(transaction.selector)) |diagnostic| {
        transaction.action_diagnostic = diagnostic;
        return error.ValueUseActionDiagnostic;
    }
    // Caller preservation may durably relocate an operand that dies at this
    // call (the legacy accumulator path is the notable case). Refresh the
    // transaction-owned canonical records immediately after that sole
    // authority, so later argument staging remains subject to strict
    // no-rebind post-validation without inventing post-call liveness.
    try refreshMemcpyPreparedOperand(transaction, destination_index);
    try refreshMemcpyPreparedOperand(transaction, action.source.index);
    try refreshMemcpyPreparedOperand(transaction, action.length.index);
    try failMemcpyForTest(transaction, .after_preservation);

    try materializeMemcpyRequest(transaction, destination_index, .rdi);
    try failMemcpyForTest(transaction, .after_destination);
    try materializeMemcpyHandle(transaction, action.source, .rsi);
    try failMemcpyForTest(transaction, .after_source);
    try materializeMemcpyHandle(transaction, action.length, .rdx);
    try failMemcpyForTest(transaction, .after_length);

    try selector_state.emitEflagsInstruction(
        transaction.selector,
        .memcpy_rdi_rsi_rdx_rax,
        .clobber,
    );
    try failMemcpyForTest(transaction, .after_call_append);
}

fn refreshMemcpyPreparedOperand(transaction: *ValueUseTransaction, index: u8) !void {
    if (!transaction.prepared_view_valid[index]) {
        transaction.recordRequestFailure(index);
        return error.ValueUsePreparedViewMissing;
    }
    transaction.prepared_views[index] = try transaction.buildPreparedRecord(index);
}

fn materializeMemcpyHandle(
    transaction: *ValueUseTransaction,
    handle: ValueUseTransaction.RequestHandle,
    destination: ArgReg,
) !void {
    const index = try transaction.validateRegisteredOperandHandle(handle);
    try materializeMemcpyRequest(transaction, index, destination);
}

fn materializeMemcpyRequest(
    transaction: *ValueUseTransaction,
    index: u8,
    destination: ArgReg,
) !void {
    return materializeMemcpyRequestUnchecked(transaction, index, destination) catch |err| {
        transaction.noteRequestBoundaryError(index, err);
        return err;
    };
}

fn materializeMemcpyRequestUnchecked(
    transaction: *ValueUseTransaction,
    index: u8,
    destination: ArgReg,
) !void {
    const current = (try transaction.validateRequestAt(index)) orelse {
        transaction.recordRequestFailure(index);
        return error.ValueUseUnsupportedSource;
    };
    switch (current) {
        .arg128, .scratch128 => |pair| {
            if (pair.lo == destination) return;
            try selector_state.clobberArgReg(transaction.selector, destination);
            try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
                .mov_arg64_arg = .{ .dst = destination, .src = pair.lo },
            });
        },
        else => try materializeScalar64(
            transaction.selector,
            current,
            .{ .gpr64 = destination },
        ),
    }
}

fn failMemcpyForTest(
    transaction: *ValueUseTransaction,
    boundary: ValueUseTransaction.MemcpyTestFailure,
) !void {
    if (builtin.is_test) {
        if (transaction.memcpy_test_failure == boundary)
            return error.ValueUseMemcpyTestFailure;
    }
}

fn executeBranchCondition(
    transaction: *ValueUseTransaction,
    view: *const ValueUseTransaction.PreparedView,
) !void {
    const condition = switch (view.*) {
        .condition => |condition| condition,
        else => return error.ValueUseBranchConditionHomeUnsupported,
    };
    switch (condition) {
        .eax => try selector_state.emitEflagsInstruction(
            transaction.selector,
            .test_eax_eax,
            .definition,
        ),
        .register32 => |reg| try selector_state.emitEflagsInstruction(
            transaction.selector,
            .{ .test_arg8 = reg },
            .definition,
        ),
        .spill_low32 => |frame_index| {
            try clobberPhysicalNode(transaction.selector, .rcx);
            try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
                .reload_arg_rsp = .{ .reg = .rcx, .frame_index = frame_index },
            });
            try selector_state.emitEflagsInstruction(
                transaction.selector,
                .{ .test_arg8 = .rcx },
                .definition,
            );
        },
        .rax_low32,
        .register64_low32,
        .pair_low32,
        .immediate,
        => return error.ValueUseBranchConditionHomeUnsupported,
    }
}

fn executeSwitchCompareChain(
    transaction: *ValueUseTransaction,
    view: *const ValueUseTransaction.PreparedView,
    action: *const ValueUseTransaction.SwitchCompareChainAction,
) !void {
    var targets: [ValueUseTransaction.max_switch_cases][]const u8 = undefined;
    for (0..action.case_count) |index|
        targets[index] = try ownActionIdentity(transaction, &action.case_targets[index]);
    const default_target = try ownActionIdentity(transaction, &action.default_target);

    const condition = switch (view.*) {
        .condition => |condition| condition,
        else => return error.ValueUseSwitchConditionHomeUnsupported,
    };
    switch (condition) {
        .eax, .rax_low32 => {},
        .register32, .register64_low32, .pair_low32 => |reg| {
            try clobberPhysicalNode(transaction.selector, .accumulator);
            try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
                .mov_arg_eax = reg,
            });
        },
        .spill_low32 => |frame_index| {
            try clobberPhysicalNode(transaction.selector, .accumulator);
            try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
                .reload_rsp_eax = frame_index,
            });
        },
        .immediate => |value| {
            try clobberPhysicalNode(transaction.selector, .accumulator);
            try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
                .mov_imm_eax = value,
            });
        },
    }
    if (action.bits < 32) try selector_state.emitEflagsInstruction(
        transaction.selector,
        .{ .and_eax_imm32 = switchConditionMask(action.bits) },
        .write,
    );
    for (0..action.case_count) |index| {
        if (action.exhaustive_case != null and action.exhaustive_case.? == index) continue;
        try selector_state.emitEflagsInstruction(
            transaction.selector,
            .{ .cmp_eax_imm32 = action.case_values[index] },
            .definition,
        );
        try selector_state.emitEflagsInstruction(
            transaction.selector,
            .{ .je = targets[index] },
            .use,
        );
    }
    try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
        .jmp = if (action.exhaustive_case) |index| targets[index] else default_target,
    });
}

fn switchConditionMask(bits: u8) i32 {
    std.debug.assert(bits > 0 and bits < 32);
    const shift: u5 = @intCast(bits);
    return @bitCast((@as(u32, 1) << shift) - 1);
}

fn validateDeferredSwitchRequest(request: *const ValueUseTransaction.StoredRequest) !void {
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

fn executeStoreScalar(
    transaction: *ValueUseTransaction,
    value_view: *const ValueUseTransaction.PreparedView,
    action: ValueUseTransaction.StoreScalarAction,
) !void {
    try materializeActionScalar32(transaction, value_view, .accumulator);
    const pointer_view = try transaction.registeredOperandView(action.pointer);
    executeStoreEaxToPointer(transaction, pointer_view, action.bits) catch |err| {
        transaction.noteRegisteredOperandBoundaryError(action.pointer, err);
        return err;
    };
}

fn executeStoreImmediate(
    transaction: *ValueUseTransaction,
    pointer_view: *const ValueUseTransaction.PreparedView,
    action: ValueUseTransaction.StoreImmediateAction,
) !void {
    try clobberPhysicalNode(transaction.selector, .accumulator);
    try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
        .mov_imm_eax = action.value,
    });
    try executeStoreEaxToPointer(transaction, pointer_view, action.bits);
}

fn executeStoreI64(
    transaction: *ValueUseTransaction,
    pointer_view: *const ValueUseTransaction.PreparedView,
    action: ValueUseTransaction.StoreI64Action,
) !void {
    const pointer = try preparedViewLoc(pointer_view);
    switch (pointer) {
        .arg64, .scratch64, .spill64 => {},
        else => return error.ValueUseStorePointerFormUnsupported,
    }
    try materializeActionPointer(transaction, pointer, .rcx);
    const value_view = try transaction.registeredOperandView(action.value);
    materializeActionScalar64(transaction, value_view, .accumulator) catch |err| {
        transaction.noteRegisteredOperandBoundaryError(action.value, err);
        return err;
    };
    try transaction.selector.machine.instructions.append(
        transaction.selector.allocator,
        .store_rax_rcx_ptr,
    );
}

fn executeStoreStackPointer(
    transaction: *ValueUseTransaction,
    source_view: *const ValueUseTransaction.PreparedView,
    action: ValueUseTransaction.StoreStackPointerAction,
) !void {
    const source = try stackScalarFromPreparedView(source_view);
    const destination_view = try transaction.registeredOperandView(action.destination);
    const destination = stackScalarFromPreparedView(destination_view) catch |err| {
        transaction.noteRegisteredOperandBoundaryError(action.destination, err);
        return err;
    };
    if (destination.kind != .integer or destination.bits != 64) {
        transaction.noteRegisteredOperandBoundaryError(
            action.destination,
            error.ValueUseStorePointerFormUnsupported,
        );
        return error.ValueUseStorePointerFormUnsupported;
    }

    try clobberPhysicalNode(transaction.selector, .rcx);
    try transaction.selector.machine.instructions.append(
        transaction.selector.allocator,
        .{ .mov_rsp_arg64 = .rcx },
    );
    if (source.base_disp != 0) {
        const offset = std.math.cast(i32, source.base_disp) orelse
            return error.ValueUseStorePointerFormUnsupported;
        try selector_state.emitEflagsInstruction(
            transaction.selector,
            .{ .add_arg64_imm32 = .{ .reg = .rcx, .imm = offset } },
            .write,
        );
    }
    if (destination.base_disp % 4 != 0) {
        transaction.noteRegisteredOperandBoundaryError(action.destination, error.ValueUseStorePointerAlignment);
        return error.ValueUseStorePointerAlignment;
    }
    const frame_index = FrameIndex.fromSlot(destination.base_disp / 4) catch {
        transaction.noteRegisteredOperandBoundaryError(action.destination, error.ValueUseStorePointerFrame);
        return error.ValueUseStorePointerFrame;
    };
    try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
        .spill_arg64_rsp = .{ .frame_index = frame_index, .reg = .rcx },
    });
}

fn executeStoreEaxToPointer(
    transaction: *ValueUseTransaction,
    pointer_view: *const ValueUseTransaction.PreparedView,
    bits: u8,
) !void {
    const pointer = try preparedViewLoc(pointer_view);
    switch (pointer) {
        .stack_scalar => |stack| {
            if (bits != 1 or stack.kind != .integer or stack.bits != 8)
                return error.ValueUseStorePointerFormUnsupported;
            try transaction.selector.machine.instructions.append(
                transaction.selector.allocator,
                if (stack.base_disp <= std.math.maxInt(u8))
                    .{ .store_al_stack_disp8 = @intCast(stack.base_disp) }
                else
                    .{ .store_al_stack_disp32 = stack.base_disp },
            );
        },
        .arg64, .scratch64 => |reg| {
            if (bits != 32) return error.ValueUseStorePointerFormUnsupported;
            try transaction.selector.machine.instructions.append(
                transaction.selector.allocator,
                .{ .store_eax_arg_ptr = reg },
            );
        },
        .spill64 => {
            if (bits != 32) return error.ValueUseStorePointerFormUnsupported;
            try materializeActionPointer(transaction, pointer, .rcx);
            try transaction.selector.machine.instructions.append(
                transaction.selector.allocator,
                .{ .store_eax_arg_ptr = .rcx },
            );
        },
        .stack_i32_ptr => |stack_ptr| {
            if (bits != 32) return error.ValueUseStorePointerFormUnsupported;
            try executeStoreStackI32(transaction, pointer_view, stack_ptr.disp);
        },
        .stack_i32_array => |array| {
            if (bits != 32) return error.ValueUseStorePointerFormUnsupported;
            try appendStoreEaxStack(transaction, array.base_disp, false);
        },
        .readonly_table_ptr => return error.ValueUseStoreReadOnlyPointer,
        else => return error.ValueUseStorePointerFormUnsupported,
    }
}

fn executeStoreStackI32(
    transaction: *ValueUseTransaction,
    pointer_view: *const ValueUseTransaction.PreparedView,
    disp: u32,
) !void {
    const descriptor = switch (pointer_view.*) {
        .address_descriptor => |*value| value,
        else => return error.ValueUseStorePointerFormUnsupported,
    };
    if (descriptor.index) |*index| {
        try materializeActionScalarHome(transaction, index.home, .rcx);
        if (descriptor.addend) |*addend| {
            try materializeActionScalarHome(transaction, addend.home, .r8);
            try selector_state.emitEflagsInstruction(transaction.selector, .add_r8_rcx, .write);
        }
        try appendStoreEaxStack(transaction, disp, true);
    } else {
        try appendStoreEaxStack(transaction, disp, false);
    }
}

fn appendStoreEaxStack(
    transaction: *ValueUseTransaction,
    disp: u32,
    indexed: bool,
) !void {
    try transaction.selector.machine.instructions.append(transaction.selector.allocator, if (indexed)
        if (disp <= std.math.maxInt(u8))
            .{ .store_eax_stack_rcx4_disp8 = @intCast(disp) }
        else
            .{ .store_eax_stack_rcx4_disp32 = disp }
    else if (disp <= std.math.maxInt(u8))
        .{ .store_eax_stack_disp8 = @intCast(disp) }
    else
        .{ .store_eax_stack_disp32 = disp });
}

fn materializeActionScalar32(
    transaction: *ValueUseTransaction,
    view: *const ValueUseTransaction.PreparedView,
    destination: ValueUseTransaction.PhysicalNode,
) !void {
    const current = try preparedViewLoc(view);
    try clobberActionDestination(transaction, current, destination);
    try materializeScalar32(transaction.selector, current, .eax);
}

fn materializeActionScalar64(
    transaction: *ValueUseTransaction,
    view: *const ValueUseTransaction.PreparedView,
    destination: ValueUseTransaction.PhysicalNode,
) !void {
    const current = try preparedViewLoc(view);
    try clobberActionDestination(transaction, current, destination);
    try materializeScalar64(transaction.selector, current, .rax);
}

fn materializeActionPointer(
    transaction: *ValueUseTransaction,
    current: ValueLoc,
    destination: ArgReg,
) !void {
    try clobberActionDestination(transaction, current, nodeForArgReg(destination));
    try materializePointer(transaction.selector, current, .{ .gpr64 = destination });
}

fn materializeActionScalarHome(
    transaction: *ValueUseTransaction,
    home: ValueUseTransaction.PreparedScalarHome,
    destination: ArgReg,
) !void {
    const current: ValueLoc = switch (home) {
        .register => |register| switch (register) {
            .gpr32 => |reg| .{ .scratch32 = reg },
            .gpr64 => |reg| .{ .scratch64 = reg },
            .eax => .eax,
            .rax => .rax,
        },
        .spill => |frame_index| .{ .spill64 = frame_index },
    };
    try clobberActionDestination(transaction, current, nodeForArgReg(destination));
    try materializeScalar64(transaction.selector, current, .{ .gpr64 = destination });
}

fn clobberActionDestination(
    transaction: *ValueUseTransaction,
    current: ValueLoc,
    destination: ValueUseTransaction.PhysicalNode,
) !void {
    if (scalarSourceNode(current)) |source| if (source == destination) return;
    try clobberPhysicalNode(transaction.selector, destination);
}

fn stackScalarFromPreparedView(
    view: *const ValueUseTransaction.PreparedView,
) !selector_types.StackScalarLoc {
    return switch (view.*) {
        .stack_object => |object| switch (object) {
            .scalar => |stack| stack,
            else => error.ValueUseStorePointerFormUnsupported,
        },
        else => error.ValueUseStorePointerFormUnsupported,
    };
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
            const offset_loc = preparedViewLoc(offset_view) catch |err| {
                transaction.noteRegisteredOperandBoundaryError(offset_handle, err);
                return err;
            };
            materializeScalar64(transaction.selector, offset_loc, .{ .gpr64 = .rcx }) catch |err| {
                transaction.noteRegisteredOperandBoundaryError(offset_handle, err);
                return err;
            };
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
                    const index_loc = preparedViewLoc(index_view) catch |err| {
                        transaction.noteRegisteredOperandBoundaryError(index_handle, err);
                        return err;
                    };
                    materializeScalar64(transaction.selector, index_loc, .{ .gpr64 = .rcx }) catch |err| {
                        transaction.noteRegisteredOperandBoundaryError(index_handle, err);
                        return err;
                    };
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
                    const index_loc = preparedViewLoc(index_view) catch |err| {
                        transaction.noteRegisteredOperandBoundaryError(index_handle, err);
                        return err;
                    };
                    materializeScalar64(transaction.selector, index_loc, .{ .gpr64 = .r8 }) catch |err| {
                        transaction.noteRegisteredOperandBoundaryError(index_handle, err);
                        return err;
                    };
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
        .int, .null_value, .unsupported => {
            transaction.recordRequestFailure(index);
            return error.ValueUseActionOperandNotNamed;
        },
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
        .read_only_pair, .condition => error.ValueUsePreparedActionFormMismatch,
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
        .condition => |value| std.meta.eql(value, rhs.condition),
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
    items: [6]ValueUseTransaction.PhysicalNode = undefined,
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

fn validateFormAndDestination(request: *const ValueUseTransaction.StoredRequest) !void {
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
            => {},
            .stack_f32_pair_byte_address,
            .branch_condition,
            .switch_condition,
            .load_address,
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
        => false,
        .pair_low_high, .pair_high_low => request.destination == .pair,
        .stack_argument => return error.ValueUseStackArgumentUnsupported,
        .new_pair_ownership => return error.ValueUseNewPairOwnershipUnsupported,
    };
    if (!valid) return error.ValueUseDestinationFormMismatch;
}

/// Validates the canonical binding against semantic request intent. Exact
/// class matches retain the ordinary contract. The sole compatible mismatch
/// is an integer <=32 requested as gpr32 through a wider scalar GPR binding
/// whose defined width covers the semantic value and whose current home has a
/// native low32 view. This is a use-only interpretation: it neither changes
/// the binding nor grants a durable relocation at the narrower class.
fn validateBindingCompatibility(
    binding: ValueBinding,
    request: *const ValueUseTransaction.StoredRequest,
    current: ValueLoc,
) !void {
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
        .branch_condition,
        .switch_condition,
        .memcpy_pointer,
        .memcpy_length,
        .load_address,
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
        .branch_condition, .switch_condition => false,
        .load_address => false,
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
            .store_scalar => |store| {
                try result.append(.accumulator);
                appendStorePointerDestinationNodes(
                    &result,
                    try transaction.registeredOperandCurrent(store.pointer),
                    store.bits,
                ) catch |err| {
                    transaction.noteRegisteredOperandBoundaryError(store.pointer, err);
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
            .store_scalar => |store| {
                mappings.append(.{
                    .source = scalarSourceNode(current orelse return error.ValueUseUnresolvedSource),
                    .destination = .accumulator,
                    .source_request_index = request_index,
                });
                appendStorePointerMappings(
                    transaction,
                    &mappings,
                    try transaction.registeredOperandCurrent(store.pointer),
                    store.pointer.index,
                    store.bits,
                ) catch |err| {
                    transaction.noteRegisteredOperandBoundaryError(store.pointer, err);
                    return err;
                };
            },
            .store_immediate => |store| {
                mappings.append(.{ .source = null, .destination = .accumulator, .source_request_index = null });
                try appendStorePointerMappings(
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
                    .source = scalarSourceNode(try transaction.registeredOperandCurrent(store.value)),
                    .destination = .accumulator,
                    .source_request_index = store.value.index,
                });
            },
            .store_stack_pointer => |store| {
                try validateStackPointerStoreViews(
                    current orelse return error.ValueUseUnresolvedSource,
                    try transaction.registeredOperandCurrent(store.destination),
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
                    .source = scalarSourceNode(try transaction.registeredOperandCurrent(memcpy.source)),
                    .destination = .rsi,
                    .source_request_index = memcpy.source.index,
                });
                mappings.append(.{
                    .source = scalarSourceNode(try transaction.registeredOperandCurrent(memcpy.length)),
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
                            const index_loc = try transaction.resolveNamedCurrent(index.name);
                            mappings.append(.{
                                .source = scalarSourceNode(index_loc),
                                .destination = .rcx,
                                .source_request_index = request_index,
                            });
                            if (index.addend_name) |addend_name| {
                                mappings.append(.{
                                    .source = scalarSourceNode(try transaction.resolveNamedCurrent(addend_name)),
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

fn actionOwnsOrderedWrites(action: ValueUseTransaction.PreparedAction) bool {
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
    request: *const ValueUseTransaction.StoredRequest,
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

fn validateStoreI64ValueOperand(request: *const ValueUseTransaction.StoredRequest) !void {
    if (request.form != .gpr64 or !request.expected.ty.eql(.{ .int = 64 }) or
        request.expected.register_class != .gpr64)
        return error.ValueUsePreparedActionFormMismatch;
}

fn validateStoreStackObjectOperand(request: *const ValueUseTransaction.StoredRequest) !void {
    if (request.form != .stack_object_address or request.expected.ty != .ptr or
        request.expected.register_class != .stack_object or
        request.expected.pointer_address_space != 0)
        return error.ValueUsePreparedActionFormMismatch;
}

fn validateMemcpyPointerOperand(request: *const ValueUseTransaction.StoredRequest) !void {
    if (request.form != .memcpy_pointer or request.expected.ty != .ptr or
        request.expected.register_class != .gpr64 or
        request.expected.pointer_address_space != 0)
    {
        return error.ValueUsePreparedActionFormMismatch;
    }
}

fn validateMemcpyLengthOperand(request: *const ValueUseTransaction.StoredRequest) !void {
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
    transaction: *ValueUseTransaction,
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
                    .source = scalarSourceNode(try transaction.resolveNamedCurrent(index.name)),
                    .destination = .rcx,
                    .source_request_index = source_request_index,
                });
                if (index.addend_name) |addend_name| mappings.append(.{
                    .source = scalarSourceNode(try transaction.resolveNamedCurrent(addend_name)),
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
    form: ValueUseTransaction.UseForm,
    destination: ValueUseTransaction.CopyDestination,
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
        => false,
        .stack_argument => return error.ValueUseStackArgumentUnsupported,
        .new_pair_ownership => return error.ValueUseNewPairOwnershipUnsupported,
    };
    if (!valid) return error.ValueUsePreparedActionFormMismatch;
}

fn scalarSourceNode(loc: ValueLoc) ?ValueUseTransaction.PhysicalNode {
    return switch (loc) {
        .arg32, .arg64, .scratch32, .scratch64 => |reg| nodeForArgReg(reg),
        .arg128, .scratch128 => |pair| nodeForArgReg(pair.lo),
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

fn rejectSemanticOrderCycles(
    graph: [ValueUseTransaction.max_requests][ValueUseTransaction.max_requests]bool,
    request_count: u8,
) !void {
    var states = [_]CopyVisitState{.unseen} ** ValueUseTransaction.max_requests;
    for (0..request_count) |node| try visitSemanticOrderNode(graph, node, request_count, &states);
}

fn visitSemanticOrderNode(
    graph: [ValueUseTransaction.max_requests][ValueUseTransaction.max_requests]bool,
    node: usize,
    request_count: u8,
    states: *[ValueUseTransaction.max_requests]CopyVisitState,
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

fn firstMappingDestination(request_index: u8, mappings: []const Mapping) ?ValueUseTransaction.PhysicalNode {
    var result: ?ValueUseTransaction.PhysicalNode = null;
    for (mappings) |mapping| {
        if (mapping.source_request_index != request_index) continue;
        if (result == null or @intFromEnum(mapping.destination) < @intFromEnum(result.?))
            result = mapping.destination;
    }
    return result;
}

fn sourceStructuralOrder(
    lhs: *const ValueUseTransaction.Source,
    rhs: *const ValueUseTransaction.Source,
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
