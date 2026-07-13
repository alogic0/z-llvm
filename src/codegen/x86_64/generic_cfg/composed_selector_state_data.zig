const std = @import("std");
const x86_64_machine = @import("../machine.zig");
const x86_64_types = @import("../types.zig");
const ir = @import("../../../ir.zig");
const selector_types = @import("selector_types.zig");
const stage2_planning = @import("stage2_planning.zig");

const MachineFunction = x86_64_machine.MachineFunction;
const ValueBinding = selector_types.ValueBinding;
const ValueLoc = selector_types.ValueLoc;
const NameSet = stage2_planning.NameSet;
const SelectorAllocationPlan = stage2_planning.SelectorAllocationPlan;
const SpillSlotAssignment = stage2_planning.SpillSlotAssignment;

const OverflowResultLoc = struct {
    value: ValueLoc,
    overflow: ValueLoc,
    require_value_first: bool = true,
    value_extracted: bool = false,
    overflow_extracted: bool = false,
};

pub const ComposedBlockSelector = struct {
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    module_context: ?*const x86_64_types.ReadOnlyModuleContext = null,
    function: ?*const ir.Function = null,
    allocation_plan: ?*const SelectorAllocationPlan = null,
    values: std.StringHashMap(ValueBinding),
    abi_pointer_params: NameSet,
    phi_results: NameSet,
    phi_destinations: std.StringHashMap(ValueLoc),
    overflow_results: std.StringHashMap(OverflowResultLoc),
    next_virtual_reg: usize = 0,
    edge_label_count: usize = 0,
    stack_slot_allocated: bool = false,
    stack_array_allocated: bool = false,
    stack_array_count: usize = 0,
    stack_frame_bytes: u32 = 0,
    return_epilogue_label: ?[]const u8 = null,
    current_position: usize = 1,
    expired_binding_this_position: bool = false,
    enable_expired_plan_register_reuse: bool = false,
    preserve_current_position_values: bool = false,
    spill_slots: std.StringHashMap(SpillSlotAssignment),
    next_spill_slot: usize = 0,

    pub fn init(allocator: std.mem.Allocator, machine: *MachineFunction) ComposedBlockSelector {
        return .{
            .allocator = allocator,
            .machine = machine,
            .module_context = null,
            .function = null,
            .allocation_plan = null,
            .values = std.StringHashMap(ValueBinding).init(allocator),
            .abi_pointer_params = NameSet.init(allocator),
            .phi_results = NameSet.init(allocator),
            .phi_destinations = std.StringHashMap(ValueLoc).init(allocator),
            .overflow_results = std.StringHashMap(OverflowResultLoc).init(allocator),
            .spill_slots = std.StringHashMap(SpillSlotAssignment).init(allocator),
        };
    }

    pub fn deinit(selector: *ComposedBlockSelector) void {
        selector.overflow_results.deinit();
        selector.spill_slots.deinit();
        selector.phi_destinations.deinit();
        selector.phi_results.deinit();
        selector.abi_pointer_params.deinit();
        selector.values.deinit();
    }
};
