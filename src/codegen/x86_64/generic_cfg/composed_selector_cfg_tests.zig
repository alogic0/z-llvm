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

test "generic cfg selector preserves scalar half ABI values exactly" {
    const input =
        \\define half @identity(half %value) {
        \\entry:
        \\  ret half %value
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = MachineFunction.init("identity", .half);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const identity: *const fn (f16) callconv(.c) f16 = @ptrCast(mapping.ptr);

    inline for (.{ @as(u16, 0x0000), @as(u16, 0x3e00), @as(u16, 0xc000), @as(u16, 0x7c00), @as(u16, 0x7e01) }) |bits| {
        try std.testing.expectEqual(bits, @as(u16, @bitCast(identity(@as(f16, @bitCast(bits))))));
    }
}

test "generic cfg selector returns spilled i128 pair" {
    var machine = MachineFunction.init("spill-pair-return", .{ .int = 128 });
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();

    try selector_state.bindValueLoc(&selector, "wide", .{ .spill128 = .{ .lo = .slot6, .hi = .slot8 } });
    try selector_state.emitValueIntoI128Return(&selector, .{ .named = "wide" });

    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .reload_arg64_rsp = .{ .reg = .rdx, .frame_index = .slot8 } }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .reload_rsp_rax = .slot6 }, machine.instructions.items[1]);
}

test "generic cfg selector returns overlapping i128 pair without scratch envelope" {
    var machine = MachineFunction.init("overlap-pair-return", .{ .int = 128 });
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();

    try selector_state.bindValueLoc(&selector, "wide", .{ .scratch128 = pair_a });
    try selector_state.emitValueIntoI128Return(&selector, .{ .named = "wide" });

    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_arg64_arg = .{ .dst = .rdi, .src = .rcx } }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_arg_rax = .rdi }, machine.instructions.items[1]);
}

test "generic cfg selector copies named i128 phi source into pair spill" {
    var machine = MachineFunction.init("pair-phi-spill", .{ .int = 128 });
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.stack_frame_bytes = 16;

    try selector_state.bindValueLoc(&selector, "incoming", .{ .scratch128 = pair_a });
    try std.testing.expect((try selector_cfg.emitValueIntoLoc(
        &selector,
        .{ .named = "incoming" },
        .{ .spill128 = .{ .lo = .slot0, .hi = .slot2 } },
        "result",
        128,
    )) == null);

    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .spill_arg64_rsp = .{ .frame_index = .slot0, .reg = pair_a.lo } },
        .{ .spill_arg64_rsp = .{ .frame_index = .slot2, .reg = pair_a.hi } },
    }, machine.instructions.items);
}

test "generic cfg selector copies overlapping pair-spilled phi source safely" {
    var machine = MachineFunction.init("pair-phi-spill-copy", .{ .int = 128 });
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.stack_frame_bytes = 24;

    try selector_state.bindValueLoc(&selector, "incoming", .{ .spill128 = .{ .lo = .slot0, .hi = .slot2 } });
    try std.testing.expect((try selector_cfg.emitValueIntoLoc(
        &selector,
        .{ .named = "incoming" },
        .{ .spill128 = .{ .lo = .slot2, .hi = .slot4 } },
        "result",
        128,
    )) == null);

    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .reload_rsp_rax = .slot2 },
        .{ .spill_rax_rsp = .slot4 },
        .{ .reload_rsp_rax = .slot0 },
        .{ .spill_rax_rsp = .slot2 },
    }, machine.instructions.items);
}

test "generic cfg selector restores only live displaced phi destinations" {
    var machine = MachineFunction.init("live-phi-restore", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("expired", 2);
    try plan.interval_ends.put("live", 4);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 2;
    try selector.phi_destinations.put("expired", .{ .scratch64 = .r8 });
    try selector.phi_destinations.put("live", .{ .scratch64 = .rcx });
    try selector_state.bindValueLoc(&selector, "expired", .{ .spill64 = .slot0 });
    try selector_state.bindValueLoc(&selector, "live", .{ .spill64 = .slot2 });

    try std.testing.expect((try selector_cfg.restoreDisplacedPhiDestinations(&selector)) == null);
    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot0 }, selector_state.valueLoc(&selector, "expired").?);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rcx }, selector_state.valueLoc(&selector, "live").?);
    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = .slot2 } },
    }, machine.instructions.items);
}

test "generic cfg selector makes framed boundary-spilled phi destinations stable" {
    var machine = MachineFunction.init("stable-boundary-phi", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("acc", 4);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 2;
    selector.stack_frame_bytes = 24;
    try selector.phi_results.put("acc", {});
    try selector.phi_destinations.put("acc", .{ .scratch64 = .r8 });
    try selector_state.bindValueLoc(&selector, "acc", .{ .scratch64 = .r8 });

    try selector_state.spillLiveValuesForCfgBoundary(&selector);

    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot0 }, selector_state.valueLoc(&selector, "acc").?);
    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot0 }, selector.phi_destinations.get("acc").?);
    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .spill_arg64_rsp = .{ .reg = .r8, .frame_index = .slot0 } },
    }, machine.instructions.items);
}
