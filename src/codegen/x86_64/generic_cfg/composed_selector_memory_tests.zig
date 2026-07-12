const std = @import("std");
const ir = @import("../../../ir.zig");
const x86_64_machine = @import("../machine.zig");
const encoding = @import("../../../mc/encoding.zig");
const selector_types = @import("selector_types.zig");
const stage2_planning = @import("stage2_planning.zig");
const impl = @import("composed_selector_impl.zig");
const selector_state = @import("composed_selector_state.zig");
const selector_scalar = @import("composed_selector_scalar.zig");
const selector_cfg = @import("composed_selector_cfg.zig");
const selector_frame = @import("composed_selector_frame.zig");
const selector_memory = @import("composed_selector_memory.zig");

const MachineFunction = impl.MachineFunction;
const ComposedBlockSelector = impl.ComposedBlockSelector;
const ValueLoc = selector_types.ValueLoc;
const VirtualRegMetadata = selector_types.VirtualRegMetadata;
const pair_a = selector_types.pair_a;
const pair_b = selector_types.pair_b;
const PlannedValueAssignment = stage2_planning.PlannedValueAssignment;
const SelectorAllocationPlan = stage2_planning.SelectorAllocationPlan;
const SelectorValueInterval = stage2_planning.SelectorValueInterval;
const SpillSlotAssignment = stage2_planning.SpillSlotAssignment;
const allocateSelectorIntervals = stage2_planning.allocateSelectorIntervals;
const stage2SpillReservedBytes = stage2_planning.stage2SpillReservedBytes;

test "generic cfg selector stores i64 through a spilled pointer" {
    var machine = MachineFunction.init("store-i64-spilled-ptr", .void);
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.stack_frame_bytes = 16;
    try selector_state.bindValueLoc(&selector, "out", .{ .spill64 = .slot0 });
    try selector_state.bindValueLoc(&selector, "value", .{ .arg64 = .rdi });

    const diagnostic = try selector_memory.lowerStore(&selector, .{
        .ty = .{ .int = 64 },
        .value = .{ .named = "value" },
        .ptr = .{ .named = "out" },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(@as(usize, 3), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = .slot0 } }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_arg_rax = .rdi }, machine.instructions.items[1]);
    try std.testing.expectEqual(x86_64_machine.Instruction.store_rax_rcx_ptr, machine.instructions.items[2]);
}
