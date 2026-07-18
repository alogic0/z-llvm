const std = @import("std");
const ir = @import("../../../ir.zig");
const x86_64_machine = @import("../machine.zig");
const x86_64_types = @import("../types.zig");
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
const selectorValueMetadata = stage2_planning.selectorValueMetadata;

test "generic cfg selector virtual register metadata follows assignment class" {
    try std.testing.expectEqual(VirtualRegMetadata{ .class = .gpr32, .bits = 32 }, selector_state.virtualRegMetadata(.eax));
    try std.testing.expectEqual(VirtualRegMetadata{ .class = .gpr64, .bits = 64 }, selector_state.virtualRegMetadata(.rax));
    try std.testing.expectEqual(VirtualRegMetadata{ .class = .gpr128, .bits = 128 }, selector_state.virtualRegMetadata(.{ .scratch128 = pair_a }));
    try std.testing.expectEqual(VirtualRegMetadata{ .class = .stack_object, .bits = 0 }, selector_state.virtualRegMetadata(.{ .stack_i32_array = .{
        .base_disp = 16,
        .len = 4,
    } }));
    try std.testing.expectEqual(VirtualRegMetadata{ .class = .stack_pointer, .bits = 64 }, selector_state.virtualRegMetadata(.{ .stack_i32_ptr = .{ .disp = 16 } }));
    try std.testing.expectEqual(VirtualRegMetadata{ .class = .fp16, .bits = 16 }, selector_state.virtualRegMetadata(.{ .xmm = .{ .reg = .xmm0, .bits = 16 } }));
    try std.testing.expectEqual(VirtualRegMetadata{ .class = .fp32, .bits = 32 }, selector_state.virtualRegMetadata(.{ .xmm = .{ .reg = .xmm1, .bits = 32 } }));
    try std.testing.expectEqual(VirtualRegMetadata{ .class = .fp64, .bits = 64 }, selector_state.virtualRegMetadata(.{ .spill_fp = .{ .frame_index = .slot0, .bits = 64 } }));
}

test "generic cfg selector state authority owns scratch XMM and value-bit queries" {
    var machine = MachineFunction.init("state-queries", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("source", 1);
    try plan.interval_ends.put("live-alias", 3);
    try plan.interval_ends.put("live-xmm", 3);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 2;
    try selector_state.bindValueLoc(&selector, "source", .{ .scratch64 = .r8 });

    try std.testing.expectEqual(
        @as(?x86_64_types.ArgReg, .r8),
        selector_state.reusableScratch64RegForInPlace(&selector, .{ .named = "source" }),
    );
    const spill_source = selector_state.spillScratch64SourceForInPlace(&selector, .{ .named = "source" }).?;
    try std.testing.expectEqualStrings("source", spill_source.name);
    try std.testing.expectEqual(x86_64_types.ArgReg.r8, spill_source.reg);
    try std.testing.expectEqual(@as(?u16, 64), selector_state.valueBits(&selector, "source"));
    try std.testing.expect(selector_state.valueBits(&selector, "missing") == null);

    try selector_state.bindValueLoc(&selector, "live-alias", .{ .scratch32 = .r8 });
    try std.testing.expect(selector_state.reusableScratch64RegForInPlace(&selector, .{ .named = "source" }) == null);
    try std.testing.expect(selector_state.spillScratch64SourceForInPlace(&selector, .{ .named = "source" }) == null);

    try selector_state.bindValueLoc(&selector, "live-xmm", .{ .xmm = .{ .reg = .xmm2, .bits = 64 } });
    try std.testing.expect(!try selector_state.xmmRegAvailable(&selector, .xmm2));
    try std.testing.expect(try selector_state.xmmRegAvailable(&selector, .xmm1));
}

test "generic cfg selector derives supported FP classes from types" {
    try std.testing.expectEqual(VirtualRegMetadata{ .class = .fp16, .bits = 16 }, selectorValueMetadata(.half).?);
    try std.testing.expectEqual(VirtualRegMetadata{ .class = .fp32, .bits = 32 }, selectorValueMetadata(.float).?);
    try std.testing.expectEqual(VirtualRegMetadata{ .class = .fp64, .bits = 64 }, selectorValueMetadata(.double).?);
    try std.testing.expect(selectorValueMetadata(.x86_fp80) == null);
    try std.testing.expect(selectorValueMetadata(.fp128) == null);
}

test "generic cfg selector allocates GPR and XMM classes independently" {
    const intervals = [_]SelectorValueInterval{
        .{ .name = "g0", .class = .gpr64, .bits = 64, .start = 0, .end = 10 },
        .{ .name = "f0", .class = .fp16, .bits = 16, .start = 0, .end = 10 },
        .{ .name = "f1", .class = .fp32, .bits = 32, .start = 0, .end = 10 },
        .{ .name = "f2", .class = .fp64, .bits = 64, .start = 0, .end = 10 },
        .{ .name = "f3", .class = .fp32, .bits = 32, .start = 0, .end = 10 },
        .{ .name = "f4", .class = .fp32, .bits = 32, .start = 0, .end = 10 },
        .{ .name = "f5", .class = .fp32, .bits = 32, .start = 0, .end = 10 },
        .{ .name = "f6", .class = .fp32, .bits = 32, .start = 0, .end = 10 },
        .{ .name = "f7", .class = .fp32, .bits = 32, .start = 0, .end = 10 },
        .{ .name = "f8", .class = .fp32, .bits = 32, .start = 0, .end = 10 },
    };
    var plan = try allocateSelectorIntervals(std.testing.allocator, intervals[0..]);
    defer plan.deinit();

    try std.testing.expectEqual(PlannedValueAssignment{ .gpr64 = .rdi }, plan.assignment("g0").?);
    try std.testing.expectEqual(PlannedValueAssignment{ .fp16 = .xmm0 }, plan.assignment("f0").?);
    try std.testing.expectEqual(PlannedValueAssignment{ .fp32 = .xmm7 }, plan.assignment("f7").?);
    try std.testing.expectEqual(PlannedValueAssignment{ .spill = 0 }, plan.assignment("f8").?);
    try std.testing.expectEqual(@as(usize, 1), plan.spill_slots);
}

test "generic cfg selector spills half values through the shared frame" {
    var machine = MachineFunction.init("spill-half", .half);
    defer machine.deinit(std.testing.allocator);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.stack_frame_bytes = 24;
    try selector_state.bindValueLoc(&selector, "value", .{ .xmm = .{ .reg = .xmm2, .bits = 16 } });

    try std.testing.expect((try selector_state.spillValue(&selector, "value")) == null);
    try std.testing.expectEqual(ValueLoc{ .spill_fp = .{ .frame_index = .slot0, .bits = 16 } }, selector_state.valueLoc(&selector, "value").?);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .spill_xmm32_rsp = .{ .frame_index = .slot0, .reg = .xmm2 } }, machine.instructions.items[0]);
}

test "generic cfg selector preserves live XMM values across calls" {
    var machine = MachineFunction.init("call-spill-fp", .float);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("live", 3);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 1;
    selector.stack_frame_bytes = 24;
    try selector_state.bindValueLoc(&selector, "live", .{ .xmm = .{ .reg = .xmm3, .bits = 32 } });

    try std.testing.expect((try selector_state.spillLiveCallerClobbersForCall(&selector)) == null);
    try std.testing.expectEqual(ValueLoc{ .spill_fp = .{ .frame_index = .slot0, .bits = 32 } }, selector_state.valueLoc(&selector, "live").?);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .spill_xmm32_rsp = .{ .frame_index = .slot0, .reg = .xmm3 } }, machine.instructions.items[0]);
}

test "generic cfg selector materializes planned FP registers and spills" {
    var machine = MachineFunction.init("move-fp", .double);
    defer machine.deinit(std.testing.allocator);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.stack_frame_bytes = 24;

    try selector_state.materializeLocIntoLoc(&selector, .{ .xmm = .{ .reg = .xmm2, .bits = 64 } }, .{ .spill_fp = .{ .frame_index = .slot0, .bits = 64 } });
    try selector_state.materializeLocIntoLoc(&selector, .{ .spill_fp = .{ .frame_index = .slot0, .bits = 64 } }, .{ .xmm = .{ .reg = .xmm4, .bits = 64 } });
    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .spill_xmm64_rsp = .{ .frame_index = .slot0, .reg = .xmm2 } },
        .{ .reload_xmm64_rsp = .{ .frame_index = .slot0, .reg = .xmm4 } },
    }, machine.instructions.items);
}

test "generic cfg selector consumes matching no-spill planned result locations" {
    var machine = MachineFunction.init("planned", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.assignments.put("kept", .{ .gpr64 = .rcx });
    try plan.assignments.put("deferred", .{ .gpr64 = .rdx });

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;

    try selector_state.bindResultLoc(&selector, "kept", .{ .scratch64 = .rcx });
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rcx }, selector_state.valueLoc(&selector, "kept").?);

    try selector_state.bindResultLoc(&selector, "deferred", .{ .scratch64 = .r8 });
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .r8 }, selector_state.valueLoc(&selector, "deferred").?);
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}

test "generic cfg selector expires planned intervals before register reuse" {
    var machine = MachineFunction.init("planned-reuse", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.assignments.put("old", .{ .gpr64 = .rdi });
    try plan.interval_ends.put("old", 1);
    try plan.assignments.put("new", .{ .gpr64 = .rdi });
    try plan.interval_ends.put("new", 2);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.enable_expired_plan_register_reuse = true;
    selector.current_position = 2;

    try selector_state.bindValueLoc(&selector, "old", .{ .arg64 = .rdi });
    try selector_state.bindValueLoc(&selector, "source", .{ .scratch64 = .rcx });

    try selector_state.expireExpiredBindings(&selector);
    try std.testing.expectEqual(ValueLoc{ .arg64 = .rdi }, selector_state.valueLoc(&selector, "old").?);

    try selector_state.bindResultLoc(&selector, "new", .{ .scratch64 = .rcx });
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rdi }, selector_state.valueLoc(&selector, "new").?);
    try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_arg64_arg = .{ .dst = .rdi, .src = .rcx } }, machine.instructions.items[0]);
}

test "generic cfg selector routes i128 trunc through planned expired register" {
    var machine = MachineFunction.init("planned-trunc", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.assignments.put("old", .{ .gpr64 = .r8 });
    try plan.interval_ends.put("old", 1);
    try plan.assignments.put("lo", .{ .gpr64 = .r8 });
    try plan.interval_ends.put("lo", 2);
    try plan.interval_ends.put("wide", 2);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.enable_expired_plan_register_reuse = true;
    selector.current_position = 2;

    try selector_state.bindValueLoc(&selector, "old", .{ .scratch64 = .r8 });
    try selector_state.bindValueLoc(&selector, "wide", .{ .arg128 = .{ .lo = .rdi, .hi = .rsi } });

    try selector_state.expireExpiredBindings(&selector);
    const diagnostic = try selector_scalar.lowerCast(&selector, "lo", .{
        .op = .trunc,
        .from_ty = .{ .int = 128 },
        .value = .{ .named = "wide" },
        .to_ty = .{ .int = 64 },
    });
    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .r8 }, selector_state.valueLoc(&selector, "lo").?);
    try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_arg64_arg = .{ .dst = .r8, .src = .rdi } }, machine.instructions.items[0]);
}

test "generic cfg selector allocation plan reuses expired registers deterministically" {
    const intervals = [_]SelectorValueInterval{
        .{ .name = "a", .class = .gpr64, .bits = 64, .start = 0, .end = 1 },
        .{ .name = "b", .class = .gpr64, .bits = 64, .start = 2, .end = 3 },
    };
    var plan = try allocateSelectorIntervals(std.testing.allocator, intervals[0..]);
    defer plan.deinit();

    try std.testing.expectEqual(@as(usize, 0), plan.spill_slots);
    try std.testing.expectEqual(PlannedValueAssignment{ .gpr64 = .rdi }, plan.assignment("a").?);
    try std.testing.expectEqual(PlannedValueAssignment{ .gpr64 = .rdi }, plan.assignment("b").?);
    try std.testing.expectEqual(@as(usize, 1), plan.intervalEnd("a").?);
    try std.testing.expectEqual(@as(usize, 3), plan.intervalEnd("b").?);
}

test "generic cfg selector allocation plan spills beyond register pool" {
    const intervals = [_]SelectorValueInterval{
        .{ .name = "v0", .class = .gpr64, .bits = 64, .start = 0, .end = 10 },
        .{ .name = "v1", .class = .gpr64, .bits = 64, .start = 0, .end = 10 },
        .{ .name = "v2", .class = .gpr64, .bits = 64, .start = 0, .end = 10 },
        .{ .name = "v3", .class = .gpr64, .bits = 64, .start = 0, .end = 10 },
        .{ .name = "v4", .class = .gpr64, .bits = 64, .start = 0, .end = 10 },
        .{ .name = "v5", .class = .gpr64, .bits = 64, .start = 0, .end = 10 },
        .{ .name = "v6", .class = .gpr64, .bits = 64, .start = 0, .end = 10 },
    };
    var plan = try allocateSelectorIntervals(std.testing.allocator, intervals[0..]);
    defer plan.deinit();

    try std.testing.expectEqual(@as(usize, 1), plan.spill_slots);
    try std.testing.expectEqual(PlannedValueAssignment{ .gpr64 = .rdi }, plan.assignment("v0").?);
    try std.testing.expectEqual(PlannedValueAssignment{ .gpr64 = .rsi }, plan.assignment("v1").?);
    try std.testing.expectEqual(PlannedValueAssignment{ .spill = 0 }, plan.assignment("v6").?);
}

test "generic cfg selector allocation plan reserves two slots for pair spills" {
    const intervals = [_]SelectorValueInterval{
        .{ .name = "a0", .class = .gpr64, .bits = 64, .start = 0, .end = 10 },
        .{ .name = "a1", .class = .gpr64, .bits = 64, .start = 0, .end = 10 },
        .{ .name = "a2", .class = .gpr64, .bits = 64, .start = 0, .end = 10 },
        .{ .name = "a3", .class = .gpr64, .bits = 64, .start = 0, .end = 10 },
        .{ .name = "a4", .class = .gpr64, .bits = 64, .start = 0, .end = 10 },
        .{ .name = "a5", .class = .gpr64, .bits = 64, .start = 0, .end = 10 },
        .{ .name = "zwide", .class = .gpr128, .bits = 128, .start = 0, .end = 10 },
        .{ .name = "zzscalar", .class = .gpr64, .bits = 64, .start = 0, .end = 10 },
    };
    var plan = try allocateSelectorIntervals(std.testing.allocator, intervals[0..]);
    defer plan.deinit();

    try std.testing.expectEqual(@as(usize, 3), plan.spill_slots);
    try std.testing.expectEqual(PlannedValueAssignment{ .spill = 0 }, plan.assignment("zwide").?);
    try std.testing.expectEqual(PlannedValueAssignment{ .spill = 2 }, plan.assignment("zzscalar").?);
}

test "generic cfg selector preserves current-position accumulator on phi edges" {
    var machine = MachineFunction.init("current-position-phi-source", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("incoming", 3);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 3;
    selector.stack_frame_bytes = 24;
    selector.preserve_current_position_values = true;
    try selector_state.bindValueLoc(&selector, "incoming", .eax);

    try selector_state.clobberAccumulator(&selector);

    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot0 }, selector_state.valueLoc(&selector, "incoming").?);
    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .spill_eax_rsp = .slot0 },
    }, machine.instructions.items);
}
