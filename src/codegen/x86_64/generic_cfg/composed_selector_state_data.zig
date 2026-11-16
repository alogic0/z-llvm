const std = @import("std");
const x86_64_machine = @import("../machine.zig");
const x86_64_types = @import("../types.zig");
const ir = @import("../../../ir.zig");
const selector_types = @import("selector_types.zig");
const stage2_planning = @import("stage2_planning.zig");
const eflags = @import("composed_selector_eflags.zig");
const address_dependencies = @import("composed_selector_address_dependencies.zig");

const MachineFunction = x86_64_machine.MachineFunction;
const AccumulatorDomain = selector_types.AccumulatorDomain;
const ValueBinding = selector_types.ValueBinding;
const ValueLoc = selector_types.ValueLoc;
const NameSet = stage2_planning.NameSet;
const SelectorAllocationPlan = stage2_planning.SelectorAllocationPlan;
const SpillSlotAssignment = stage2_planning.SpillSlotAssignment;
const AddressDependencyDomain = address_dependencies.AddressDependencyDomain;

const OverflowResultLoc = struct {
    value: ValueLoc,
    overflow: ValueLoc,
    require_value_first: bool = true,
    value_extracted: bool = false,
    overflow_extracted: bool = false,
};

pub const EflagsSemanticRecord = struct {
    instruction_index: usize,
    effect: eflags.Effect,
};

pub const ComposedBlockSelector = struct {
    rejection_observer: ?*@import("rejection_observer.zig").Observer = null,
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    module_context: ?*const x86_64_types.ReadOnlyModuleContext = null,
    function: ?*const ir.Function = null,
    allocation_plan: ?*const SelectorAllocationPlan = null,
    values: std.StringHashMap(ValueBinding),
    abi_pointer_params: NameSet,
    readonly_pointer_params: NameSet,
    phi_results: NameSet,
    phi_destinations: std.StringHashMap(ValueLoc),
    overflow_results: std.StringHashMap(OverflowResultLoc),
    next_virtual_reg: usize = 0,
    edge_label_count: usize = 0,
    stack_slot_allocated: bool = false,
    stack_array_allocated: bool = false,
    stack_array_count: usize = 0,
    stack_frame_bytes: u32 = 0,
    frame_setup_begin: usize = 0,
    frame_setup_end: usize = 0,
    return_epilogue_label: ?[]const u8 = null,
    terminal_tail_call: bool = false,
    current_position: usize = 1,
    expired_binding_this_position: bool = false,
    enable_expired_plan_register_reuse: bool = false,
    preserve_current_position_values: bool = false,
    spill_slots: std.StringHashMap(SpillSlotAssignment),
    // Insertion order is the rollback journal. Assignments are immutable once
    // inserted, and each retained key owns its independent name storage.
    owned_spill_slot_keys: std.array_hash_map.String([]u8),
    next_spill_slot: usize = 0,
    eflags: eflags.Liveness = .{},
    eflags_semantics: std.ArrayList(EflagsSemanticRecord) = .empty,
    accumulator_domain: AccumulatorDomain = .{},
    value_snapshot_buffers: selector_types.ValueSnapshotBuffers = .{},
    physical_binding_facts: selector_types.PhysicalBindingFacts = .{},
    address_dependencies: AddressDependencyDomain = .{},
    // One namespace per function/rewrite selector instance; never reset while
    // transactions or their snapshots can observe an identity.
    value_use_names: @import("value_use/scoped_names.zig").Pool = .{},

    pub fn init(allocator: std.mem.Allocator, machine: *MachineFunction) ComposedBlockSelector {
        return .{
            .allocator = allocator,
            .machine = machine,
            .module_context = null,
            .function = null,
            .allocation_plan = null,
            .values = std.StringHashMap(ValueBinding).init(allocator),
            .abi_pointer_params = NameSet.init(allocator),
            .readonly_pointer_params = NameSet.init(allocator),
            .phi_results = NameSet.init(allocator),
            .phi_destinations = std.StringHashMap(ValueLoc).init(allocator),
            .overflow_results = std.StringHashMap(OverflowResultLoc).init(allocator),
            .spill_slots = std.StringHashMap(SpillSlotAssignment).init(allocator),
            .owned_spill_slot_keys = .empty,
        };
    }

    pub fn deinit(selector: *ComposedBlockSelector) void {
        selector.value_use_names.deinit(selector.allocator);
        selector.eflags_semantics.deinit(selector.allocator);
        selector.overflow_results.deinit();
        for (selector.owned_spill_slot_keys.keys()) |owned_key| selector.allocator.free(owned_key);
        selector.owned_spill_slot_keys.deinit(selector.allocator);
        selector.spill_slots.deinit();
        selector.phi_destinations.deinit();
        selector.phi_results.deinit();
        selector.abi_pointer_params.deinit();
        selector.readonly_pointer_params.deinit();
        selector.value_snapshot_buffers.deinit(selector.allocator);
        selector.values.deinit();
    }
};
