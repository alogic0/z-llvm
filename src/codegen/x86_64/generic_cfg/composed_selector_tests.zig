const std = @import("std");
const ir = @import("../../../ir.zig");
const x86_64_machine = @import("../machine.zig");
const selector_types = @import("selector_types.zig");
const stage2_planning = @import("stage2_planning.zig");
const impl = @import("composed_selector_impl.zig");

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

test "generic cfg selector virtual register metadata follows assignment class" {
    try std.testing.expectEqual(VirtualRegMetadata{ .class = .gpr32, .bits = 32 }, ComposedBlockSelector.virtualRegMetadata(.eax));
    try std.testing.expectEqual(VirtualRegMetadata{ .class = .gpr64, .bits = 64 }, ComposedBlockSelector.virtualRegMetadata(.rax));
    try std.testing.expectEqual(VirtualRegMetadata{ .class = .gpr128, .bits = 128 }, ComposedBlockSelector.virtualRegMetadata(.{ .scratch128 = pair_a }));
    try std.testing.expectEqual(VirtualRegMetadata{ .class = .stack_object, .bits = 0 }, ComposedBlockSelector.virtualRegMetadata(.{ .stack_i32_array = .{
        .base_disp = 16,
        .len = 4,
    } }));
    try std.testing.expectEqual(VirtualRegMetadata{ .class = .stack_pointer, .bits = 64 }, ComposedBlockSelector.virtualRegMetadata(.{ .stack_i32_ptr = .{ .disp = 16 } }));
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

    try selector.bindResultLoc("kept", .{ .scratch64 = .rcx });
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rcx }, selector.valueLoc("kept").?);

    try selector.bindResultLoc("deferred", .{ .scratch64 = .r8 });
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .r8 }, selector.valueLoc("deferred").?);
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

    try selector.bindValueLoc("old", .{ .arg64 = .rdi });
    try selector.bindValueLoc("source", .{ .scratch64 = .rcx });

    try selector.expireExpiredBindings();
    try std.testing.expectEqual(ValueLoc{ .arg64 = .rdi }, selector.valueLoc("old").?);

    try selector.bindResultLoc("new", .{ .scratch64 = .rcx });
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rdi }, selector.valueLoc("new").?);
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

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.enable_expired_plan_register_reuse = true;
    selector.current_position = 2;

    try selector.bindValueLoc("old", .{ .scratch64 = .r8 });
    try selector.bindValueLoc("wide", .{ .arg128 = .{ .lo = .rdi, .hi = .rsi } });

    try selector.expireExpiredBindings();
    const diagnostic = try selector.lowerCast("lo", .{
        .op = .trunc,
        .from_ty = .{ .int = 128 },
        .value = .{ .named = "wide" },
        .to_ty = .{ .int = 64 },
    });
    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .r8 }, selector.valueLoc("lo").?);
    try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_arg64_arg = .{ .dst = .r8, .src = .rdi } }, machine.instructions.items[0]);
}

test "generic cfg selector materializes mul64 lhs into planned register" {
    var machine = MachineFunction.init("planned-mul64", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.assignments.put("old", .{ .gpr64 = .r8 });
    try plan.interval_ends.put("old", 1);
    try plan.assignments.put("product", .{ .gpr64 = .r8 });
    try plan.interval_ends.put("product", 2);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.enable_expired_plan_register_reuse = true;
    selector.current_position = 2;

    try selector.bindValueLoc("old", .{ .scratch64 = .r8 });
    try selector.bindValueLoc("lhs", .{ .arg64 = .rdi });
    try selector.bindValueLoc("rhs", .{ .arg64 = .rsi });

    try selector.expireExpiredBindings();
    const diagnostic = try selector.lowerMul64("product", .{
        .op = .mul,
        .ty = .{ .int = 64 },
        .lhs = .{ .named = "lhs" },
        .rhs = .{ .named = "rhs" },
    });
    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .r8 }, selector.valueLoc("product").?);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_arg64_arg = .{ .dst = .r8, .src = .rdi } }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .imul_arg64_arg64 = .{ .dst = .r8, .src = .rsi } }, machine.instructions.items[1]);
}

test "generic cfg selector reloads spilled mul64 rhs through rax when scratch registers are live" {
    var machine = MachineFunction.init("mul64-spill-rhs-rax", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("live_rdi", 10);
    try plan.interval_ends.put("live_rsi", 10);
    try plan.interval_ends.put("lhs", 4);
    try plan.interval_ends.put("live_rcx", 10);
    try plan.interval_ends.put("live_r8", 10);
    try plan.interval_ends.put("live_r9", 10);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 4;
    selector.enable_expired_plan_register_reuse = true;
    selector.stack_frame_bytes = stage2SpillReservedBytes();

    try selector.bindValueLoc("live_rdi", .{ .scratch64 = .rdi });
    try selector.bindValueLoc("live_rsi", .{ .scratch64 = .rsi });
    try selector.bindValueLoc("lhs", .{ .scratch64 = .rdx });
    try selector.bindValueLoc("live_rcx", .{ .scratch64 = .rcx });
    try selector.bindValueLoc("live_r8", .{ .scratch64 = .r8 });
    try selector.bindValueLoc("live_r9", .{ .scratch64 = .r9 });
    try selector.bindValueLoc("rhs", .{ .spill64 = .slot2 });

    const diagnostic = try selector.lowerMul64("product", .{
        .op = .mul,
        .ty = .{ .int = 64 },
        .lhs = .{ .named = "lhs" },
        .rhs = .{ .named = "rhs" },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rdx }, selector.valueLoc("product").?);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .reload_rsp_rax = .slot2 }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .imul_arg64_rax = .rdx }, machine.instructions.items[1]);
}

test "generic cfg selector spills live mul64 lhs before reusing its scratch register" {
    var machine = MachineFunction.init("mul64-spill-live-lhs", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("live_rdi", 10);
    try plan.interval_ends.put("rhs", 10);
    try plan.interval_ends.put("lhs", 10);
    try plan.interval_ends.put("live_rcx", 10);
    try plan.interval_ends.put("live_r8", 10);
    try plan.interval_ends.put("live_r9", 10);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 4;
    selector.enable_expired_plan_register_reuse = true;
    selector.stack_frame_bytes = stage2SpillReservedBytes();

    try selector.bindValueLoc("live_rdi", .{ .scratch64 = .rdi });
    try selector.bindValueLoc("rhs", .{ .scratch64 = .rsi });
    try selector.bindValueLoc("lhs", .{ .scratch64 = .rdx });
    try selector.bindValueLoc("live_rcx", .{ .scratch64 = .rcx });
    try selector.bindValueLoc("live_r8", .{ .scratch64 = .r8 });
    try selector.bindValueLoc("live_r9", .{ .scratch64 = .r9 });

    const diagnostic = try selector.lowerMul64("product", .{
        .op = .mul,
        .ty = .{ .int = 64 },
        .lhs = .{ .named = "lhs" },
        .rhs = .{ .named = "rhs" },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot0 }, selector.valueLoc("lhs").?);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rdx }, selector.valueLoc("product").?);
    try std.testing.expectEqual(@as(usize, 3), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .spill_arg64_rsp = .{ .frame_index = .slot0, .reg = .rdx } }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .reload_arg64_rsp = .{ .reg = .rdx, .frame_index = .slot0 } }, machine.instructions.items[1]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .imul_arg64_arg64 = .{ .dst = .rdx, .src = .rsi } }, machine.instructions.items[2]);
}

test "generic cfg selector reloads spilled mul64 lhs through rax when scratch registers are live" {
    var machine = MachineFunction.init("mul64-spill-lhs-rax", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("live_rax", 10);
    try plan.interval_ends.put("live_rdi", 10);
    try plan.interval_ends.put("live_rsi", 10);
    try plan.interval_ends.put("live_rdx", 10);
    try plan.interval_ends.put("live_rcx", 10);
    try plan.interval_ends.put("live_r8", 10);
    try plan.interval_ends.put("live_r9", 10);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 4;
    selector.enable_expired_plan_register_reuse = true;
    selector.stack_frame_bytes = stage2SpillReservedBytes();

    try selector.bindValueLoc("live_rax", .rax);
    try selector.bindValueLoc("live_rdi", .{ .scratch64 = .rdi });
    try selector.bindValueLoc("live_rsi", .{ .scratch64 = .rsi });
    try selector.bindValueLoc("live_rdx", .{ .scratch64 = .rdx });
    try selector.bindValueLoc("live_rcx", .{ .scratch64 = .rcx });
    try selector.bindValueLoc("live_r8", .{ .scratch64 = .r8 });
    try selector.bindValueLoc("live_r9", .{ .scratch64 = .r9 });
    try selector.bindValueLoc("lhs", .{ .spill64 = .slot10 });
    try selector.bindValueLoc("rhs", .{ .spill64 = .slot12 });

    const diagnostic = try selector.lowerMul64("product", .{
        .op = .mul,
        .ty = .{ .int = 64 },
        .lhs = .{ .named = "lhs" },
        .rhs = .{ .named = "rhs" },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot0 }, selector.valueLoc("live_rax").?);
    try std.testing.expectEqual(ValueLoc.rax, selector.valueLoc("product").?);
    try std.testing.expectEqual(@as(usize, 3), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .spill_rax_rsp = .slot0 }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .reload_rsp_rax = .slot10 }, machine.instructions.items[1]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .imul_rax_rsp = .slot12 }, machine.instructions.items[2]);
}

test "generic cfg selector assigns deterministic spill slot per scalar value" {
    var machine = MachineFunction.init("spill-slot-deterministic", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("value", 10);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 4;
    selector.stack_frame_bytes = stage2SpillReservedBytes();

    try selector.bindValueLoc("value", .rax);

    const diagnostic = try selector.spillValue("value");

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot0 }, selector.valueLoc("value").?);
    try std.testing.expectEqual(SpillSlotAssignment{ .base = 0, .slots = 1 }, selector.spill_slots.get("value").?);
    try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .spill_rax_rsp = .slot0 }, machine.instructions.items[0]);
}

test "generic cfg selector spills and reloads 32-bit accumulator scalar values" {
    var machine = MachineFunction.init("spill-eax-scalar", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("value", 10);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 4;
    selector.stack_frame_bytes = stage2SpillReservedBytes();

    try selector.bindValueLoc("value", .eax);

    const diagnostic = try selector.spillValue("value");
    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot0 }, selector.valueLoc("value").?);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .spill_eax_rsp = .slot0 }, machine.instructions.items[0]);

    try selector.emitValueIntoEax(.{ .named = "value" });
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .reload_rsp_eax = .slot0 }, machine.instructions.items[1]);
}

test "generic cfg selector spills 32-bit scratch values into scalar spill slots" {
    var machine = MachineFunction.init("spill-scratch32-scalar", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("value", 10);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 4;
    selector.stack_frame_bytes = stage2SpillReservedBytes();

    try selector.bindValueLoc("value", .{ .scratch32 = .rcx });

    const diagnostic = try selector.spillValue("value");
    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot0 }, selector.valueLoc("value").?);
    try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .spill_arg_rsp = .{ .frame_index = .slot0, .reg = .rcx } }, machine.instructions.items[0]);
}

test "generic cfg selector materializes 32-bit spill slot into scratch register" {
    var machine = MachineFunction.init("reload-spill32-scratch", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();

    try selector.materializeLocIntoLoc(.{ .spill64 = .slot2 }, .{ .scratch32 = .rcx });

    try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .reload_arg_rsp = .{ .reg = .rcx, .frame_index = .slot2 } }, machine.instructions.items[0]);
}

test "generic cfg selector reloads 32-bit spill rhs for binary accumulator op" {
    var machine = MachineFunction.init("reload-spill32-rhs", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();

    try selector.bindValueLoc("lhs", .{ .scratch32 = .rdi });
    try selector.bindValueLoc("rhs", .{ .spill64 = .slot4 });

    const diagnostic = try selector.lowerBinary("sum", .{
        .op = .add,
        .ty = .{ .int = 32 },
        .lhs = .{ .named = "lhs" },
        .rhs = .{ .named = "rhs" },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc.eax, selector.valueLoc("sum").?);
    try std.testing.expectEqual(@as(usize, 3), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_arg_eax = .rdi }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .reload_arg_rsp = .{ .reg = .rcx, .frame_index = .slot4 } }, machine.instructions.items[1]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .binary_arg_eax = .{ .op = .add, .reg = .rcx } }, machine.instructions.items[2]);
}

test "generic cfg selector reloads spilled pair for i128 lshr immediate" {
    var machine = MachineFunction.init("spill-pair-lshr", .{ .int = 128 });
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();

    try selector.bindValueLoc("wide", .{ .spill128 = .{ .lo = .slot6, .hi = .slot8 } });
    try selector.emitPairLshrImmediate("shifted", .{ .named = "wide" }, 64);

    const dst = pair_a;
    try std.testing.expectEqual(ValueLoc{ .scratch128 = dst }, selector.valueLoc("shifted").?);
    try std.testing.expectEqual(@as(usize, 4), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .reload_arg64_rsp = .{ .reg = dst.lo, .frame_index = .slot6 } }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .reload_arg64_rsp = .{ .reg = dst.hi, .frame_index = .slot8 } }, machine.instructions.items[1]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_arg64_arg = .{ .dst = dst.lo, .src = dst.hi } }, machine.instructions.items[2]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_imm_rdx = 0 }, machine.instructions.items[3]);
}

test "generic cfg selector pair lshr avoids live scalar scratch values" {
    var machine = MachineFunction.init("pair-lshr-avoid-live-scalar", .{ .int = 128 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("lo", 10);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 2;
    selector.enable_expired_plan_register_reuse = true;

    try selector.bindValueLoc("wide", .{ .arg128 = .{ .lo = .rdi, .hi = .rsi } });
    try selector.bindValueLoc("other_wide", .{ .arg128 = .{ .lo = .rdx, .hi = .rcx } });
    try selector.bindValueLoc("lo", .{ .scratch64 = .rcx });

    try selector.emitPairLshrImmediate("hi", .{ .named = "wide" }, 64);

    try std.testing.expectEqual(ValueLoc{ .scratch128 = pair_b }, selector.valueLoc("hi").?);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rcx }, selector.valueLoc("lo").?);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_arg64_arg = .{ .dst = pair_b.lo, .src = .rsi } }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_imm_r9 = 0 }, machine.instructions.items[1]);
}

test "generic cfg selector reloads spilled pair for i128 shl immediate" {
    var machine = MachineFunction.init("spill-pair-shl", .{ .int = 128 });
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();

    try selector.bindValueLoc("wide", .{ .spill128 = .{ .lo = .slot6, .hi = .slot8 } });
    try selector.emitPairShlImmediate("shifted", .{ .named = "wide" }, 64);

    try std.testing.expectEqual(ValueLoc{ .scratch128 = pair_a }, selector.valueLoc("shifted").?);
    try std.testing.expectEqual(@as(usize, 4), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .reload_arg64_rsp = .{ .reg = pair_a.lo, .frame_index = .slot6 } }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .reload_arg64_rsp = .{ .reg = pair_a.hi, .frame_index = .slot8 } }, machine.instructions.items[1]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_arg64_arg = .{ .dst = pair_a.hi, .src = pair_a.lo } }, machine.instructions.items[2]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_imm_rcx = 0 }, machine.instructions.items[3]);
}

test "generic cfg selector reloads spilled pair for i128 trunc" {
    var machine = MachineFunction.init("spill-pair-trunc", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();

    try selector.bindValueLoc("wide", .{ .spill128 = .{ .lo = .slot6, .hi = .slot8 } });
    const diagnostic = try selector.lowerCast("lo", .{
        .op = .trunc,
        .value = .{ .named = "wide" },
        .from_ty = .{ .int = 128 },
        .to_ty = .{ .int = 64 },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rdi }, selector.valueLoc("lo").?);
    try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .reload_arg64_rsp = .{ .reg = .rdi, .frame_index = .slot6 } }, machine.instructions.items[0]);
}

test "generic cfg selector i128 trunc reuses source low lane without clobbering live scalar" {
    var machine = MachineFunction.init("pair-trunc-avoid-live-scalar", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("lo", 10);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 3;
    selector.enable_expired_plan_register_reuse = true;

    try selector.bindValueLoc("lo", .{ .scratch64 = .rcx });
    try selector.bindValueLoc("shifted", .{ .scratch128 = .{ .lo = .rdi, .hi = .rsi } });

    const diagnostic = try selector.lowerCast("hi", .{
        .op = .trunc,
        .value = .{ .named = "shifted" },
        .from_ty = .{ .int = 128 },
        .to_ty = .{ .int = 64 },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rdi }, selector.valueLoc("hi").?);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rcx }, selector.valueLoc("lo").?);
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}

test "generic cfg selector masks reloaded i64 spill low half" {
    var machine = MachineFunction.init("spill-mask", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();

    try selector.bindValueLoc("wide_lo", .{ .spill64 = .slot6 });
    const diagnostic = try selector.lowerBinaryImmediateRhs("masked", .{
        .op = .@"and",
        .ty = .{ .int = 64 },
        .lhs = .{ .named = "wide_lo" },
        .rhs = .{ .int = std.math.maxInt(u32) },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc.rax, selector.valueLoc("masked").?);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .reload_rsp_rax = .slot6 }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .and_eax_imm32 = -1 }, machine.instructions.items[1]);
}

test "generic cfg selector preserves live rax before another i64 low-half mask" {
    var machine = MachineFunction.init("preserve-rax-mask", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("left_masked", 10);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 4;
    selector.stack_frame_bytes = stage2SpillReservedBytes();

    try selector.bindValueLoc("left_masked", .rax);
    try selector.bindValueLoc("right", .{ .scratch64 = .rsi });

    const diagnostic = try selector.lowerBinaryImmediateRhs("right_masked", .{
        .op = .@"and",
        .ty = .{ .int = 64 },
        .lhs = .{ .named = "right" },
        .rhs = .{ .int = std.math.maxInt(u32) },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot0 }, selector.valueLoc("left_masked").?);
    try std.testing.expectEqual(ValueLoc.rax, selector.valueLoc("right_masked").?);
    try std.testing.expectEqual(@as(usize, 3), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .spill_rax_rsp = .slot0 }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_arg_rax = .rsi }, machine.instructions.items[1]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .and_eax_imm32 = -1 }, machine.instructions.items[2]);
}

test "generic cfg selector lshr64 avoids live scalar scratch values" {
    var machine = MachineFunction.init("lshr64-avoid-live-scalar", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("live", 10);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 4;
    selector.enable_expired_plan_register_reuse = true;

    try selector.bindValueLoc("live", .{ .scratch64 = .rcx });
    try selector.bindValueLoc("source", .{ .scratch64 = .r8 });

    const diagnostic = try selector.lowerBinaryImmediateRhs("shifted", .{
        .op = .lshr,
        .ty = .{ .int = 64 },
        .lhs = .{ .named = "source" },
        .rhs = .{ .int = 32 },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rcx }, selector.valueLoc("live").?);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rdi }, selector.valueLoc("shifted").?);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_arg64_arg = .{ .dst = .rdi, .src = .r8 } }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .shr_arg64_imm6 = .{ .reg = .rdi, .amount = 32 } }, machine.instructions.items[1]);
}

test "generic cfg selector lshr64 reuses dead source scratch register" {
    var machine = MachineFunction.init("lshr64-reuse-dead-source", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("source", 4);
    try plan.interval_ends.put("live_rdi", 10);
    try plan.interval_ends.put("live_rsi", 10);
    try plan.interval_ends.put("live_rdx", 10);
    try plan.interval_ends.put("live_r8", 10);
    try plan.interval_ends.put("live_r9", 10);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 4;
    selector.enable_expired_plan_register_reuse = true;

    try selector.bindValueLoc("source", .{ .scratch64 = .rcx });
    try selector.bindValueLoc("live_rdi", .{ .scratch64 = .rdi });
    try selector.bindValueLoc("live_rsi", .{ .scratch64 = .rsi });
    try selector.bindValueLoc("live_rdx", .{ .scratch64 = .rdx });
    try selector.bindValueLoc("live_r8", .{ .scratch64 = .r8 });
    try selector.bindValueLoc("live_r9", .{ .scratch64 = .r9 });

    const diagnostic = try selector.lowerBinaryImmediateRhs("shifted", .{
        .op = .lshr,
        .ty = .{ .int = 64 },
        .lhs = .{ .named = "source" },
        .rhs = .{ .int = 32 },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rcx }, selector.valueLoc("shifted").?);
    try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .shr_arg64_imm6 = .{ .reg = .rcx, .amount = 32 } }, machine.instructions.items[0]);
}

test "generic cfg selector shl64 spills live rax source before destructive shift" {
    var machine = MachineFunction.init("shl64-preserve-rax-source", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("source", 10);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 4;
    selector.enable_expired_plan_register_reuse = true;
    selector.stack_frame_bytes = stage2SpillReservedBytes();

    try selector.bindValueLoc("source", .rax);

    const diagnostic = try selector.lowerBinaryImmediateRhs("shifted", .{
        .op = .shl,
        .ty = .{ .int = 64 },
        .lhs = .{ .named = "source" },
        .rhs = .{ .int = 32 },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot0 }, selector.valueLoc("source").?);
    try std.testing.expectEqual(ValueLoc.rax, selector.valueLoc("shifted").?);
    try std.testing.expectEqual(@as(usize, 3), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .spill_rax_rsp = .slot0 }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .reload_rsp_rax = .slot0 }, machine.instructions.items[1]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .shl_rax_imm6 = 32 }, machine.instructions.items[2]);
}

test "generic cfg selector lshr64 spills live source before reusing its scratch register" {
    var machine = MachineFunction.init("lshr64-spill-live-source", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("source", 10);
    try plan.interval_ends.put("live_rdi", 10);
    try plan.interval_ends.put("live_rsi", 10);
    try plan.interval_ends.put("live_rdx", 10);
    try plan.interval_ends.put("live_r8", 10);
    try plan.interval_ends.put("live_r9", 10);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 4;
    selector.enable_expired_plan_register_reuse = true;
    selector.stack_frame_bytes = stage2SpillReservedBytes();

    try selector.bindValueLoc("source", .{ .scratch64 = .rcx });
    try selector.bindValueLoc("live_rdi", .{ .scratch64 = .rdi });
    try selector.bindValueLoc("live_rsi", .{ .scratch64 = .rsi });
    try selector.bindValueLoc("live_rdx", .{ .scratch64 = .rdx });
    try selector.bindValueLoc("live_r8", .{ .scratch64 = .r8 });
    try selector.bindValueLoc("live_r9", .{ .scratch64 = .r9 });

    const diagnostic = try selector.lowerBinaryImmediateRhs("shifted", .{
        .op = .lshr,
        .ty = .{ .int = 64 },
        .lhs = .{ .named = "source" },
        .rhs = .{ .int = 32 },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot0 }, selector.valueLoc("source").?);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rcx }, selector.valueLoc("shifted").?);
    try std.testing.expectEqual(@as(usize, 3), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .spill_arg64_rsp = .{ .frame_index = .slot0, .reg = .rcx } }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = .slot0 } }, machine.instructions.items[1]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .shr_arg64_imm6 = .{ .reg = .rcx, .amount = 32 } }, machine.instructions.items[2]);
}

test "generic cfg selector lshr64 reloads spilled source through rax when scratch registers are live" {
    var machine = MachineFunction.init("lshr64-spill-source-rax", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("live_rax", 10);
    try plan.interval_ends.put("live_rdi", 10);
    try plan.interval_ends.put("live_rsi", 10);
    try plan.interval_ends.put("live_rdx", 10);
    try plan.interval_ends.put("live_rcx", 10);
    try plan.interval_ends.put("live_r8", 10);
    try plan.interval_ends.put("live_r9", 10);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 4;
    selector.enable_expired_plan_register_reuse = true;
    selector.stack_frame_bytes = stage2SpillReservedBytes();

    try selector.bindValueLoc("live_rax", .rax);
    try selector.bindValueLoc("live_rdi", .{ .scratch64 = .rdi });
    try selector.bindValueLoc("live_rsi", .{ .scratch64 = .rsi });
    try selector.bindValueLoc("live_rdx", .{ .scratch64 = .rdx });
    try selector.bindValueLoc("live_rcx", .{ .scratch64 = .rcx });
    try selector.bindValueLoc("live_r8", .{ .scratch64 = .r8 });
    try selector.bindValueLoc("live_r9", .{ .scratch64 = .r9 });
    try selector.bindValueLoc("source", .{ .spill64 = .slot10 });

    const diagnostic = try selector.lowerBinaryImmediateRhs("shifted", .{
        .op = .lshr,
        .ty = .{ .int = 64 },
        .lhs = .{ .named = "source" },
        .rhs = .{ .int = 32 },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot0 }, selector.valueLoc("live_rax").?);
    try std.testing.expectEqual(ValueLoc.rax, selector.valueLoc("shifted").?);
    try std.testing.expectEqual(@as(usize, 3), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .spill_rax_rsp = .slot0 }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .reload_rsp_rax = .slot10 }, machine.instructions.items[1]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .shr_rax_imm6 = 32 }, machine.instructions.items[2]);
}

test "generic cfg selector returns spilled i128 pair" {
    var machine = MachineFunction.init("spill-pair-return", .{ .int = 128 });
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();

    try selector.bindValueLoc("wide", .{ .spill128 = .{ .lo = .slot6, .hi = .slot8 } });
    try selector.emitValueIntoI128Return(.{ .named = "wide" });

    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .reload_arg64_rsp = .{ .reg = .rdx, .frame_index = .slot8 } }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .reload_rsp_rax = .slot6 }, machine.instructions.items[1]);
}

test "generic cfg selector returns overlapping i128 pair without scratch envelope" {
    var machine = MachineFunction.init("overlap-pair-return", .{ .int = 128 });
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();

    try selector.bindValueLoc("wide", .{ .scratch128 = pair_a });
    try selector.emitValueIntoI128Return(.{ .named = "wide" });

    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_arg64_arg = .{ .dst = .rdi, .src = .rcx } }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_arg_rax = .rdi }, machine.instructions.items[1]);
}

test "generic cfg selector stores scalar planned spills in deterministic frame slots" {
    var machine = MachineFunction.init("planned-spill", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.assignments.put("spilled", .{ .spill = 2 });

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = stage2SpillReservedBytes();

    try selector.bindResultLoc("spilled", .{ .scratch64 = .rcx });
    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot4 }, selector.valueLoc("spilled").?);
    try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .spill_arg64_rsp = .{ .frame_index = .slot4, .reg = .rcx } }, machine.instructions.items[0]);
}

test "generic cfg selector stores planned pair spills in deterministic frame slots" {
    var machine = MachineFunction.init("planned-pair-spill", .{ .int = 128 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.assignments.put("pair", .{ .spill = 3 });

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = stage2SpillReservedBytes();

    try selector.bindResultLoc("pair", .{ .scratch128 = pair_a });
    try std.testing.expectEqual(ValueLoc{ .spill128 = .{ .lo = .slot6, .hi = .slot8 } }, selector.valueLoc("pair").?);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .spill_arg64_rsp = .{ .frame_index = .slot6, .reg = pair_a.lo } }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .spill_arg64_rsp = .{ .frame_index = .slot8, .reg = pair_a.hi } }, machine.instructions.items[1]);
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

test "generic cfg selector lowers i32 unsigned-add overflow components" {
    var machine = MachineFunction.init("uadd-overflow-i32", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    try selector.bindValueLoc("lhs", .{ .arg32 = .rdi });
    try selector.bindValueLoc("rhs", .{ .arg32 = .rsi });

    var call = ir.CallInst{
        .ret_ty = .{ .aggregate = "{ i32, i1 }" },
        .callee = "llvm.uadd.with.overflow.i32",
        .tail_kind = "tail",
        .args = .empty,
    };
    defer call.deinit(std.testing.allocator);
    try call.args.append(std.testing.allocator, .{ .ty = .{ .int = 32 }, .value = .{ .named = "lhs" } });
    try call.args.append(std.testing.allocator, .{ .ty = .{ .int = 32 }, .value = .{ .named = "rhs" } });

    try std.testing.expect((try selector.lowerInstruction(.{ .result = "pair", .kind = .{ .call = call } })) == null);
    try std.testing.expect((try selector.lowerInstruction(.{
        .result = "sum",
        .kind = .{ .extractvalue = .{
            .aggregate_ty = .{ .aggregate = "{ i32, i1 }" },
            .aggregate = .{ .named = "pair" },
            .indices = "0",
            .result_ty = .{ .int = 32 },
        } },
    })) == null);
    try std.testing.expect((try selector.lowerInstruction(.{
        .result = "carry",
        .kind = .{ .extractvalue = .{
            .aggregate_ty = .{ .aggregate = "{ i32, i1 }" },
            .aggregate = .{ .named = "pair" },
            .indices = "1",
            .result_ty = .{ .int = 1 },
        } },
    })) == null);

    try std.testing.expectEqual(ValueLoc{ .scratch32 = .rdx }, selector.valueLoc("sum").?);
    try std.testing.expectEqual(ValueLoc.eax, selector.valueLoc("carry").?);
    try std.testing.expectEqual(@as(usize, 5), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_arg_arg = .{ .dst = .rcx, .src = .rsi } }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_arg_eax = .rdi }, machine.instructions.items[1]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .binary_arg_eax = .{ .op = .add, .reg = .rcx } }, machine.instructions.items[2]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_eax_to_arg = .rdx }, machine.instructions.items[3]);
    try std.testing.expectEqual(x86_64_machine.Instruction.setb_eax, machine.instructions.items[4]);
}
