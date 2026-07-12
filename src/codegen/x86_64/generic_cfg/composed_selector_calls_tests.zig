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

test "generic cfg selector lowers lifetime markers as checked no-ops" {
    var machine = MachineFunction.init("lifetime-markers", .void);
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    try selector_state.bindValueLoc(&selector, "slot", .{ .stack_scalar = .{ .base_disp = 0, .bits = 8 } });

    inline for (.{ "llvm.lifetime.start.p0", "llvm.lifetime.end.p0" }) |callee| {
        var call = ir.CallInst{
            .ret_ty = .void,
            .callee = callee,
            .args = .empty,
        };
        defer call.deinit(std.testing.allocator);
        try call.args.append(std.testing.allocator, .{ .ty = .ptr, .value = .{ .named = "slot" } });
        try std.testing.expect((try impl.lowerInstruction(&selector, .{ .result = null, .kind = .{ .call = call } })) == null);
    }

    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}
