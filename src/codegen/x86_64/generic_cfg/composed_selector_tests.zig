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

test "generic cfg selector virtual register metadata follows assignment class" {
    try std.testing.expectEqual(VirtualRegMetadata{ .class = .gpr32, .bits = 32 }, selector_state.virtualRegMetadata(.eax));
    try std.testing.expectEqual(VirtualRegMetadata{ .class = .gpr64, .bits = 64 }, selector_state.virtualRegMetadata(.rax));
    try std.testing.expectEqual(VirtualRegMetadata{ .class = .gpr128, .bits = 128 }, selector_state.virtualRegMetadata(.{ .scratch128 = pair_a }));
    try std.testing.expectEqual(VirtualRegMetadata{ .class = .stack_object, .bits = 0 }, selector_state.virtualRegMetadata(.{ .stack_i32_array = .{
        .base_disp = 16,
        .len = 4,
    } }));
    try std.testing.expectEqual(VirtualRegMetadata{ .class = .stack_pointer, .bits = 64 }, selector_state.virtualRegMetadata(.{ .stack_i32_ptr = .{ .disp = 16 } }));
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

    try selector_state.bindValueLoc(&selector, "old", .{ .scratch64 = .r8 });
    try selector_state.bindValueLoc(&selector, "lhs", .{ .arg64 = .rdi });
    try selector_state.bindValueLoc(&selector, "rhs", .{ .arg64 = .rsi });

    try selector_state.expireExpiredBindings(&selector);
    const diagnostic = try selector_scalar.lowerMul64(&selector, "product", .{
        .op = .mul,
        .ty = .{ .int = 64 },
        .lhs = .{ .named = "lhs" },
        .rhs = .{ .named = "rhs" },
    });
    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .r8 }, selector_state.valueLoc(&selector, "product").?);
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

    try selector_state.bindValueLoc(&selector, "live_rdi", .{ .scratch64 = .rdi });
    try selector_state.bindValueLoc(&selector, "live_rsi", .{ .scratch64 = .rsi });
    try selector_state.bindValueLoc(&selector, "lhs", .{ .scratch64 = .rdx });
    try selector_state.bindValueLoc(&selector, "live_rcx", .{ .scratch64 = .rcx });
    try selector_state.bindValueLoc(&selector, "live_r8", .{ .scratch64 = .r8 });
    try selector_state.bindValueLoc(&selector, "live_r9", .{ .scratch64 = .r9 });
    try selector_state.bindValueLoc(&selector, "rhs", .{ .spill64 = .slot2 });

    const diagnostic = try selector_scalar.lowerMul64(&selector, "product", .{
        .op = .mul,
        .ty = .{ .int = 64 },
        .lhs = .{ .named = "lhs" },
        .rhs = .{ .named = "rhs" },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rdx }, selector_state.valueLoc(&selector, "product").?);
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

    try selector_state.bindValueLoc(&selector, "live_rdi", .{ .scratch64 = .rdi });
    try selector_state.bindValueLoc(&selector, "rhs", .{ .scratch64 = .rsi });
    try selector_state.bindValueLoc(&selector, "lhs", .{ .scratch64 = .rdx });
    try selector_state.bindValueLoc(&selector, "live_rcx", .{ .scratch64 = .rcx });
    try selector_state.bindValueLoc(&selector, "live_r8", .{ .scratch64 = .r8 });
    try selector_state.bindValueLoc(&selector, "live_r9", .{ .scratch64 = .r9 });

    const diagnostic = try selector_scalar.lowerMul64(&selector, "product", .{
        .op = .mul,
        .ty = .{ .int = 64 },
        .lhs = .{ .named = "lhs" },
        .rhs = .{ .named = "rhs" },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot0 }, selector_state.valueLoc(&selector, "lhs").?);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rdx }, selector_state.valueLoc(&selector, "product").?);
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

    try selector_state.bindValueLoc(&selector, "live_rax", .rax);
    try selector_state.bindValueLoc(&selector, "live_rdi", .{ .scratch64 = .rdi });
    try selector_state.bindValueLoc(&selector, "live_rsi", .{ .scratch64 = .rsi });
    try selector_state.bindValueLoc(&selector, "live_rdx", .{ .scratch64 = .rdx });
    try selector_state.bindValueLoc(&selector, "live_rcx", .{ .scratch64 = .rcx });
    try selector_state.bindValueLoc(&selector, "live_r8", .{ .scratch64 = .r8 });
    try selector_state.bindValueLoc(&selector, "live_r9", .{ .scratch64 = .r9 });
    try selector_state.bindValueLoc(&selector, "lhs", .{ .spill64 = .slot10 });
    try selector_state.bindValueLoc(&selector, "rhs", .{ .spill64 = .slot12 });

    const diagnostic = try selector_scalar.lowerMul64(&selector, "product", .{
        .op = .mul,
        .ty = .{ .int = 64 },
        .lhs = .{ .named = "lhs" },
        .rhs = .{ .named = "rhs" },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot0 }, selector_state.valueLoc(&selector, "live_rax").?);
    try std.testing.expectEqual(ValueLoc.rax, selector_state.valueLoc(&selector, "product").?);
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

    try selector_state.bindValueLoc(&selector, "value", .rax);

    const diagnostic = try selector_state.spillValue(&selector, "value");

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot0 }, selector_state.valueLoc(&selector, "value").?);
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

    try selector_state.bindValueLoc(&selector, "value", .eax);

    const diagnostic = try selector_state.spillValue(&selector, "value");
    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot0 }, selector_state.valueLoc(&selector, "value").?);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .spill_eax_rsp = .slot0 }, machine.instructions.items[0]);

    try selector_state.emitValueIntoEax(&selector, .{ .named = "value" });
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

    try selector_state.bindValueLoc(&selector, "value", .{ .scratch32 = .rcx });

    const diagnostic = try selector_state.spillValue(&selector, "value");
    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot0 }, selector_state.valueLoc(&selector, "value").?);
    try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .spill_arg_rsp = .{ .frame_index = .slot0, .reg = .rcx } }, machine.instructions.items[0]);
}

test "generic cfg selector materializes 32-bit spill slot into scratch register" {
    var machine = MachineFunction.init("reload-spill32-scratch", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();

    try selector_state.materializeLocIntoLoc(&selector, .{ .spill64 = .slot2 }, .{ .scratch32 = .rcx });

    try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .reload_arg_rsp = .{ .reg = .rcx, .frame_index = .slot2 } }, machine.instructions.items[0]);
}

test "generic cfg selector reloads 32-bit spill rhs for binary accumulator op" {
    var machine = MachineFunction.init("reload-spill32-rhs", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();

    try selector_state.bindValueLoc(&selector, "lhs", .{ .scratch32 = .rdi });
    try selector_state.bindValueLoc(&selector, "rhs", .{ .spill64 = .slot4 });

    const diagnostic = try selector_scalar.lowerBinary(&selector, "sum", .{
        .op = .add,
        .ty = .{ .int = 32 },
        .lhs = .{ .named = "lhs" },
        .rhs = .{ .named = "rhs" },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc.eax, selector_state.valueLoc(&selector, "sum").?);
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

    try selector_state.bindValueLoc(&selector, "wide", .{ .spill128 = .{ .lo = .slot6, .hi = .slot8 } });
    try selector_state.emitPairLshrImmediate(&selector, "shifted", .{ .named = "wide" }, 64);

    const dst = pair_a;
    try std.testing.expectEqual(ValueLoc{ .scratch128 = dst }, selector_state.valueLoc(&selector, "shifted").?);
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

    try selector_state.bindValueLoc(&selector, "wide", .{ .arg128 = .{ .lo = .rdi, .hi = .rsi } });
    try selector_state.bindValueLoc(&selector, "other_wide", .{ .arg128 = .{ .lo = .rdx, .hi = .rcx } });
    try selector_state.bindValueLoc(&selector, "lo", .{ .scratch64 = .rcx });

    try selector_state.emitPairLshrImmediate(&selector, "hi", .{ .named = "wide" }, 64);

    try std.testing.expectEqual(ValueLoc{ .scratch128 = pair_b }, selector_state.valueLoc(&selector, "hi").?);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rcx }, selector_state.valueLoc(&selector, "lo").?);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_arg64_arg = .{ .dst = pair_b.lo, .src = .rsi } }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_imm_r9 = 0 }, machine.instructions.items[1]);
}

test "generic cfg selector reloads spilled pair for i128 shl immediate" {
    var machine = MachineFunction.init("spill-pair-shl", .{ .int = 128 });
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();

    try selector_state.bindValueLoc(&selector, "wide", .{ .spill128 = .{ .lo = .slot6, .hi = .slot8 } });
    try selector_state.emitPairShlImmediate(&selector, "shifted", .{ .named = "wide" }, 64);

    try std.testing.expectEqual(ValueLoc{ .scratch128 = pair_a }, selector_state.valueLoc(&selector, "shifted").?);
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

    try selector_state.bindValueLoc(&selector, "wide", .{ .spill128 = .{ .lo = .slot6, .hi = .slot8 } });
    const diagnostic = try selector_scalar.lowerCast(&selector, "lo", .{
        .op = .trunc,
        .value = .{ .named = "wide" },
        .from_ty = .{ .int = 128 },
        .to_ty = .{ .int = 64 },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rdi }, selector_state.valueLoc(&selector, "lo").?);
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

    try selector_state.bindValueLoc(&selector, "lo", .{ .scratch64 = .rcx });
    try selector_state.bindValueLoc(&selector, "shifted", .{ .scratch128 = .{ .lo = .rdi, .hi = .rsi } });

    const diagnostic = try selector_scalar.lowerCast(&selector, "hi", .{
        .op = .trunc,
        .value = .{ .named = "shifted" },
        .from_ty = .{ .int = 128 },
        .to_ty = .{ .int = 64 },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rdi }, selector_state.valueLoc(&selector, "hi").?);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rcx }, selector_state.valueLoc(&selector, "lo").?);
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}

test "generic cfg selector masks reloaded i64 spill low half" {
    var machine = MachineFunction.init("spill-mask", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();

    try selector_state.bindValueLoc(&selector, "wide_lo", .{ .spill64 = .slot6 });
    const diagnostic = try selector_scalar.lowerBinaryImmediateRhs(&selector, "masked", .{
        .op = .@"and",
        .ty = .{ .int = 64 },
        .lhs = .{ .named = "wide_lo" },
        .rhs = .{ .int = std.math.maxInt(u32) },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc.rax, selector_state.valueLoc(&selector, "masked").?);
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

    try selector_state.bindValueLoc(&selector, "left_masked", .rax);
    try selector_state.bindValueLoc(&selector, "right", .{ .scratch64 = .rsi });

    const diagnostic = try selector_scalar.lowerBinaryImmediateRhs(&selector, "right_masked", .{
        .op = .@"and",
        .ty = .{ .int = 64 },
        .lhs = .{ .named = "right" },
        .rhs = .{ .int = std.math.maxInt(u32) },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot0 }, selector_state.valueLoc(&selector, "left_masked").?);
    try std.testing.expectEqual(ValueLoc.rax, selector_state.valueLoc(&selector, "right_masked").?);
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

    try selector_state.bindValueLoc(&selector, "live", .{ .scratch64 = .rcx });
    try selector_state.bindValueLoc(&selector, "source", .{ .scratch64 = .r8 });

    const diagnostic = try selector_scalar.lowerBinaryImmediateRhs(&selector, "shifted", .{
        .op = .lshr,
        .ty = .{ .int = 64 },
        .lhs = .{ .named = "source" },
        .rhs = .{ .int = 32 },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rcx }, selector_state.valueLoc(&selector, "live").?);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rdi }, selector_state.valueLoc(&selector, "shifted").?);
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

    try selector_state.bindValueLoc(&selector, "source", .{ .scratch64 = .rcx });
    try selector_state.bindValueLoc(&selector, "live_rdi", .{ .scratch64 = .rdi });
    try selector_state.bindValueLoc(&selector, "live_rsi", .{ .scratch64 = .rsi });
    try selector_state.bindValueLoc(&selector, "live_rdx", .{ .scratch64 = .rdx });
    try selector_state.bindValueLoc(&selector, "live_r8", .{ .scratch64 = .r8 });
    try selector_state.bindValueLoc(&selector, "live_r9", .{ .scratch64 = .r9 });

    const diagnostic = try selector_scalar.lowerBinaryImmediateRhs(&selector, "shifted", .{
        .op = .lshr,
        .ty = .{ .int = 64 },
        .lhs = .{ .named = "source" },
        .rhs = .{ .int = 32 },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rcx }, selector_state.valueLoc(&selector, "shifted").?);
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

    try selector_state.bindValueLoc(&selector, "source", .rax);

    const diagnostic = try selector_scalar.lowerBinaryImmediateRhs(&selector, "shifted", .{
        .op = .shl,
        .ty = .{ .int = 64 },
        .lhs = .{ .named = "source" },
        .rhs = .{ .int = 32 },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot0 }, selector_state.valueLoc(&selector, "source").?);
    try std.testing.expectEqual(ValueLoc.rax, selector_state.valueLoc(&selector, "shifted").?);
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

    try selector_state.bindValueLoc(&selector, "source", .{ .scratch64 = .rcx });
    try selector_state.bindValueLoc(&selector, "live_rdi", .{ .scratch64 = .rdi });
    try selector_state.bindValueLoc(&selector, "live_rsi", .{ .scratch64 = .rsi });
    try selector_state.bindValueLoc(&selector, "live_rdx", .{ .scratch64 = .rdx });
    try selector_state.bindValueLoc(&selector, "live_r8", .{ .scratch64 = .r8 });
    try selector_state.bindValueLoc(&selector, "live_r9", .{ .scratch64 = .r9 });

    const diagnostic = try selector_scalar.lowerBinaryImmediateRhs(&selector, "shifted", .{
        .op = .lshr,
        .ty = .{ .int = 64 },
        .lhs = .{ .named = "source" },
        .rhs = .{ .int = 32 },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot0 }, selector_state.valueLoc(&selector, "source").?);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rcx }, selector_state.valueLoc(&selector, "shifted").?);
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

    try selector_state.bindValueLoc(&selector, "live_rax", .rax);
    try selector_state.bindValueLoc(&selector, "live_rdi", .{ .scratch64 = .rdi });
    try selector_state.bindValueLoc(&selector, "live_rsi", .{ .scratch64 = .rsi });
    try selector_state.bindValueLoc(&selector, "live_rdx", .{ .scratch64 = .rdx });
    try selector_state.bindValueLoc(&selector, "live_rcx", .{ .scratch64 = .rcx });
    try selector_state.bindValueLoc(&selector, "live_r8", .{ .scratch64 = .r8 });
    try selector_state.bindValueLoc(&selector, "live_r9", .{ .scratch64 = .r9 });
    try selector_state.bindValueLoc(&selector, "source", .{ .spill64 = .slot10 });

    const diagnostic = try selector_scalar.lowerBinaryImmediateRhs(&selector, "shifted", .{
        .op = .lshr,
        .ty = .{ .int = 64 },
        .lhs = .{ .named = "source" },
        .rhs = .{ .int = 32 },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot0 }, selector_state.valueLoc(&selector, "live_rax").?);
    try std.testing.expectEqual(ValueLoc.rax, selector_state.valueLoc(&selector, "shifted").?);
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

    try selector_state.bindResultLoc(&selector, "spilled", .{ .scratch64 = .rcx });
    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot4 }, selector_state.valueLoc(&selector, "spilled").?);
    try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .spill_arg64_rsp = .{ .frame_index = .slot4, .reg = .rcx } }, machine.instructions.items[0]);
}

test "generic cfg selector stores i32 planned spills in deterministic frame slots" {
    var machine = MachineFunction.init("planned-spill-i32", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.assignments.put("spilled", .{ .spill = 2 });

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = stage2SpillReservedBytes();

    try selector_state.bindResultLoc(&selector, "spilled", .{ .scratch32 = .rcx });
    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot4 }, selector_state.valueLoc(&selector, "spilled").?);
    try std.testing.expectEqual(@as(u16, 32), selector.values.get("spilled").?.vreg.bits);
    try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .spill_arg_rsp = .{ .frame_index = .slot4, .reg = .rcx } }, machine.instructions.items[0]);
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

    try selector_state.bindResultLoc(&selector, "pair", .{ .scratch128 = pair_a });
    try std.testing.expectEqual(ValueLoc{ .spill128 = .{ .lo = .slot6, .hi = .slot8 } }, selector_state.valueLoc(&selector, "pair").?);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .spill_arg64_rsp = .{ .frame_index = .slot6, .reg = pair_a.lo } }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .spill_arg64_rsp = .{ .frame_index = .slot8, .reg = pair_a.hi } }, machine.instructions.items[1]);
}

test "generic cfg selector relocates fixed full-product definitions" {
    var machine = MachineFunction.init("relocate-full-product", .{ .int = 128 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.assignments.put("product", .{ .gpr128 = pair_b });

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;

    try machine.instructions.append(std.testing.allocator, .{ .mov_arg_rax = .rdi });
    try selector_state.prepareFixedProductDefs(&selector);
    try machine.instructions.append(std.testing.allocator, .{ .mul_rax_arg64_full = .rsi });
    try selector_state.bindFixedProductResult(&selector, "product");
    try selector_state.emitValueIntoI128Return(&selector, .{ .named = "product" });
    try machine.instructions.append(std.testing.allocator, .ret);

    try std.testing.expectEqual(ValueLoc{ .scratch128 = pair_b }, selector_state.valueLoc(&selector, "product").?);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_rax_to_arg = pair_b.lo }, machine.instructions.items[2]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_arg64_arg = .{ .dst = pair_b.hi, .src = .rdx } }, machine.instructions.items[3]);

    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(
        null,
        bytes.len,
        .{ .READ = true, .WRITE = true, .EXEC = true },
        .{ .TYPE = .PRIVATE, .ANONYMOUS = true },
        -1,
        0,
    );
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const fullProduct: *const fn (u64, u64) callconv(.c) u128 = @ptrCast(mapping.ptr);
    const lhs = std.math.maxInt(u64);
    const rhs: u64 = 3;
    try std.testing.expectEqual(@as(u128, lhs) * rhs, fullProduct(lhs, rhs));
}

test "generic cfg selector displaces live fixed full-product register owners" {
    var machine = MachineFunction.init("prepare-full-product", .{ .int = 128 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("accumulator", 2);
    try plan.interval_ends.put("rdx_pair", 2);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = stage2SpillReservedBytes();
    try selector_state.bindValueLoc(&selector, "accumulator", .rax);
    try selector_state.bindValueLoc(&selector, "rdx_pair", .{ .scratch128 = pair_a });

    try selector_state.prepareFixedProductDefs(&selector);

    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot0 }, selector_state.valueLoc(&selector, "accumulator").?);
    try std.testing.expectEqual(ValueLoc{ .spill128 = .{ .lo = .slot2, .hi = .slot4 } }, selector_state.valueLoc(&selector, "rdx_pair").?);
    try std.testing.expectEqual(@as(usize, 3), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .spill_rax_rsp = .slot0 }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .spill_arg64_rsp = .{ .frame_index = .slot2, .reg = pair_a.lo } }, machine.instructions.items[1]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .spill_arg64_rsp = .{ .frame_index = .slot4, .reg = pair_a.hi } }, machine.instructions.items[2]);
}

test "generic cfg selector spills fixed full-product definitions" {
    var machine = MachineFunction.init("spill-full-product", .{ .int = 128 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.assignments.put("product", .{ .spill = 3 });

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = stage2SpillReservedBytes();

    try selector_state.prepareFixedProductDefs(&selector);
    try selector_state.bindFixedProductResult(&selector, "product");

    try std.testing.expectEqual(ValueLoc{ .spill128 = .{ .lo = .slot6, .hi = .slot8 } }, selector_state.valueLoc(&selector, "product").?);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .spill_rax_rsp = .slot6 }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .spill_arg64_rsp = .{ .frame_index = .slot8, .reg = .rdx } }, machine.instructions.items[1]);
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

test "spill materialization validates the concrete frame index" {
    var machine = MachineFunction.init("spill_frame_index", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.stack_frame_bytes = 16;
    selector.next_spill_slot = 64;

    try selector_state.materializeLocIntoLoc(&selector, .{ .scratch64 = .rdi }, .{ .spill64 = .slot0 });
    try std.testing.expectEqual(x86_64_machine.Instruction{ .spill_arg64_rsp = .{ .frame_index = .slot0, .reg = .rdi } }, machine.instructions.items[0]);
}

test "dynamic spill allocation rejects a frame index beyond the frame" {
    var machine = MachineFunction.init("spill_frame_limit", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.stack_frame_bytes = 16;
    selector.next_spill_slot = 2;
    try selector_state.bindValueLoc(&selector, "live", .{ .scratch64 = .rdi });

    try std.testing.expect((try selector_state.spillValue(&selector, "live")) != null);
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}

test "spill reservation covers secondary homes for planned values" {
    var machine = MachineFunction.init("planned-value-homes", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    for (0..20) |index| {
        var name_buffer: [16]u8 = undefined;
        const name = try std.fmt.bufPrint(&name_buffer, "value{}", .{index});
        try plan.assignments.put(try std.testing.allocator.dupe(u8, name), .{ .gpr64 = .rdi });
    }
    defer {
        var names = plan.assignments.keyIterator();
        while (names.next()) |name| std.testing.allocator.free(name.*);
    }

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;

    try std.testing.expectEqual(@as(u32, 320), selector_frame.spillReservedBytes(&selector, true).?);
}

test "i32 spill relocation preserves its width" {
    var machine = MachineFunction.init("spill_i32_copy", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.stack_frame_bytes = 16;

    try selector_state.materializeLocIntoLocWithBits(&selector, .{ .spill64 = .slot0 }, .{ .spill64 = .slot2 }, 32);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .reload_rsp_eax = .slot0 }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .spill_eax_rsp = .slot2 }, machine.instructions.items[1]);
}

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

test "generic cfg selector lowers i32 unsigned-add overflow components" {
    var machine = MachineFunction.init("uadd-overflow-i32", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    try selector_state.bindValueLoc(&selector, "lhs", .{ .arg32 = .rdi });
    try selector_state.bindValueLoc(&selector, "rhs", .{ .arg32 = .rsi });

    var call = ir.CallInst{
        .ret_ty = .{ .aggregate = "{ i32, i1 }" },
        .callee = "llvm.uadd.with.overflow.i32",
        .tail_kind = "tail",
        .args = .empty,
    };
    defer call.deinit(std.testing.allocator);
    try call.args.append(std.testing.allocator, .{ .ty = .{ .int = 32 }, .value = .{ .named = "lhs" } });
    try call.args.append(std.testing.allocator, .{ .ty = .{ .int = 32 }, .value = .{ .named = "rhs" } });

    try std.testing.expect((try impl.lowerInstruction(&selector, .{ .result = "pair", .kind = .{ .call = call } })) == null);
    try std.testing.expect((try impl.lowerInstruction(&selector, .{
        .result = "sum",
        .kind = .{ .extractvalue = .{
            .aggregate_ty = .{ .aggregate = "{ i32, i1 }" },
            .aggregate = .{ .named = "pair" },
            .indices = "0",
            .result_ty = .{ .int = 32 },
        } },
    })) == null);
    try std.testing.expect((try impl.lowerInstruction(&selector, .{
        .result = "carry",
        .kind = .{ .extractvalue = .{
            .aggregate_ty = .{ .aggregate = "{ i32, i1 }" },
            .aggregate = .{ .named = "pair" },
            .indices = "1",
            .result_ty = .{ .int = 1 },
        } },
    })) == null);

    try std.testing.expectEqual(ValueLoc{ .scratch32 = .rdx }, selector_state.valueLoc(&selector, "sum").?);
    try std.testing.expectEqual(ValueLoc.eax, selector_state.valueLoc(&selector, "carry").?);
    try std.testing.expectEqual(@as(usize, 5), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_arg_arg = .{ .dst = .rcx, .src = .rsi } }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_arg_eax = .rdi }, machine.instructions.items[1]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .binary_arg_eax = .{ .op = .add, .reg = .rcx } }, machine.instructions.items[2]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_eax_to_arg = .rdx }, machine.instructions.items[3]);
    try std.testing.expectEqual(x86_64_machine.Instruction.setb_eax, machine.instructions.items[4]);
}

test "generic cfg selector lowers i32 unsigned-subtract overflow components" {
    var machine = MachineFunction.init("usub-overflow-i32", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    try selector_state.bindValueLoc(&selector, "lhs", .{ .arg32 = .rdi });
    try selector_state.bindValueLoc(&selector, "rhs", .{ .arg32 = .rsi });

    var call = ir.CallInst{
        .ret_ty = .{ .aggregate = "{ i32, i1 }" },
        .callee = "llvm.usub.with.overflow.i32",
        .tail_kind = "tail",
        .args = .empty,
    };
    defer call.deinit(std.testing.allocator);
    try call.args.append(std.testing.allocator, .{ .ty = .{ .int = 32 }, .value = .{ .named = "lhs" } });
    try call.args.append(std.testing.allocator, .{ .ty = .{ .int = 32 }, .value = .{ .named = "rhs" } });

    try std.testing.expect((try impl.lowerInstruction(&selector, .{ .result = "pair", .kind = .{ .call = call } })) == null);
    try std.testing.expect((try impl.lowerInstruction(&selector, .{
        .result = "value",
        .kind = .{ .extractvalue = .{
            .aggregate_ty = .{ .aggregate = "{ i32, i1 }" },
            .aggregate = .{ .named = "pair" },
            .indices = "0",
            .result_ty = .{ .int = 32 },
        } },
    })) == null);
    try std.testing.expect((try impl.lowerInstruction(&selector, .{
        .result = "borrow",
        .kind = .{ .extractvalue = .{
            .aggregate_ty = .{ .aggregate = "{ i32, i1 }" },
            .aggregate = .{ .named = "pair" },
            .indices = "1",
            .result_ty = .{ .int = 1 },
        } },
    })) == null);

    try std.testing.expectEqual(ValueLoc{ .scratch32 = .rdx }, selector_state.valueLoc(&selector, "value").?);
    try std.testing.expectEqual(ValueLoc.eax, selector_state.valueLoc(&selector, "borrow").?);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .binary_arg_eax = .{ .op = .sub, .reg = .rcx } }, machine.instructions.items[2]);
    try std.testing.expectEqual(x86_64_machine.Instruction.setb_eax, machine.instructions.items[4]);
}

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

test "generic cfg selector lowers named i32 unsigned less-than" {
    var machine = MachineFunction.init("ult-i32-named", .{ .int = 1 });
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    try selector_state.bindValueLoc(&selector, "lhs", .{ .arg32 = .rdi });
    try selector_state.bindValueLoc(&selector, "rhs", .{ .arg32 = .rsi });

    const diagnostic = try selector_scalar.lowerIcmp(&selector, "cmp", .{
        .predicate = .ult,
        .operand_ty = .{ .int = 32 },
        .lhs = .{ .named = "lhs" },
        .rhs = .{ .named = "rhs" },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc.eax, selector_state.valueLoc(&selector, "cmp").?);
    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .mov_arg_arg = .{ .dst = .r8, .src = .rdi } },
        .{ .mov_arg_arg = .{ .dst = .rcx, .src = .rsi } },
        .{ .cmp_ecx_arg32 = .r8 },
        .setb_eax,
    }, machine.instructions.items);
}

test "generic cfg selector lowers named i32 unsigned division and remainder" {
    var quotient_machine = MachineFunction.init("udiv-i32-named", .{ .int = 32 });
    defer quotient_machine.deinit(std.testing.allocator);
    var quotient_selector = ComposedBlockSelector.init(std.testing.allocator, &quotient_machine);
    defer quotient_selector.deinit();
    try selector_state.bindValueLoc(&quotient_selector, "lhs", .{ .arg32 = .rdi });
    try selector_state.bindValueLoc(&quotient_selector, "rhs", .{ .arg32 = .rsi });

    try std.testing.expect((try selector_scalar.lowerBinary(&quotient_selector, "quotient", .{
        .op = .udiv,
        .ty = .{ .int = 32 },
        .lhs = .{ .named = "lhs" },
        .rhs = .{ .named = "rhs" },
    })) == null);
    try std.testing.expectEqual(ValueLoc.eax, selector_state.valueLoc(&quotient_selector, "quotient").?);
    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .mov_arg_eax = .rdi },
        .{ .mov_arg_arg = .{ .dst = .rcx, .src = .rsi } },
        .xor_edx_edx,
        .{ .div_arg32 = .rcx },
    }, quotient_machine.instructions.items);

    var remainder_machine = MachineFunction.init("urem-i32-named", .{ .int = 32 });
    defer remainder_machine.deinit(std.testing.allocator);
    var remainder_selector = ComposedBlockSelector.init(std.testing.allocator, &remainder_machine);
    defer remainder_selector.deinit();
    try selector_state.bindValueLoc(&remainder_selector, "lhs", .{ .arg32 = .rdi });
    try selector_state.bindValueLoc(&remainder_selector, "rhs", .{ .arg32 = .rsi });

    try std.testing.expect((try selector_scalar.lowerBinary(&remainder_selector, "remainder", .{
        .op = .urem,
        .ty = .{ .int = 32 },
        .lhs = .{ .named = "lhs" },
        .rhs = .{ .named = "rhs" },
    })) == null);
    try std.testing.expectEqual(ValueLoc{ .scratch32 = .rdx }, selector_state.valueLoc(&remainder_selector, "remainder").?);
    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .mov_arg_eax = .rdi },
        .{ .mov_arg_arg = .{ .dst = .rcx, .src = .rsi } },
        .xor_edx_edx,
        .{ .div_arg32 = .rcx },
    }, remainder_machine.instructions.items);
}

test "generic cfg selector lowers named i32 unsigned greater-than" {
    var machine = MachineFunction.init("ugt-i32-named", .{ .int = 1 });
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    try selector_state.bindValueLoc(&selector, "lhs", .{ .arg32 = .rdi });
    try selector_state.bindValueLoc(&selector, "rhs", .{ .arg32 = .rsi });

    const diagnostic = try selector_scalar.lowerIcmp(&selector, "cmp", .{
        .predicate = .ugt,
        .operand_ty = .{ .int = 32 },
        .lhs = .{ .named = "lhs" },
        .rhs = .{ .named = "rhs" },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc.eax, selector_state.valueLoc(&selector, "cmp").?);
    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .mov_arg_arg = .{ .dst = .rcx, .src = .rdi } },
        .{ .mov_arg_arg = .{ .dst = .r8, .src = .rsi } },
        .{ .cmp_ecx_arg32 = .r8 },
        .setb_eax,
    }, machine.instructions.items);
}

test "generic cfg selector lays out mixed scalar and array frame objects" {
    var function = ir.Function.init("mixed-frame", .void);
    defer function.deinit(std.testing.allocator);
    var entry = ir.BasicBlock.init("Entry");
    try entry.instructions.append(std.testing.allocator, .{
        .result = "flag4",
        .kind = .{ .alloca = .{ .allocated_ty = .{ .int = 8 }, .attrs = "align 4" } },
    });
    try entry.instructions.append(std.testing.allocator, .{
        .result = "words3",
        .kind = .{ .alloca = .{ .allocated_ty = .{ .aggregate = "[3 x i32]" }, .attrs = "align 4" } },
    });
    try entry.instructions.append(std.testing.allocator, .{
        .result = "flag1",
        .kind = .{ .alloca = .{ .allocated_ty = .{ .int = 8 }, .attrs = "align 1" } },
    });
    try entry.instructions.append(std.testing.allocator, .{
        .result = "words2",
        .kind = .{ .alloca = .{ .allocated_ty = .{ .aggregate = "[2 x i32]" }, .attrs = "align 4" } },
    });
    entry.terminator = .{ .ret = .{ .ty = .void, .value = null } };
    try function.blocks.append(std.testing.allocator, entry);

    var machine = MachineFunction.init("mixed-frame", .void);
    defer machine.deinit(std.testing.allocator);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();

    try std.testing.expect((try selector_frame.prepareStackFrame(&selector, function)) == null);
    try std.testing.expectEqual(ValueLoc{ .stack_scalar = .{ .base_disp = 256, .bits = 8 } }, selector_state.valueLoc(&selector, "flag4").?);
    try std.testing.expectEqual(ValueLoc{ .stack_i32_array = .{ .base_disp = 260, .len = 3 } }, selector_state.valueLoc(&selector, "words3").?);
    try std.testing.expectEqual(ValueLoc{ .stack_scalar = .{ .base_disp = 272, .bits = 8 } }, selector_state.valueLoc(&selector, "flag1").?);
    try std.testing.expectEqual(ValueLoc{ .stack_i32_array = .{ .base_disp = 276, .len = 2 } }, selector_state.valueLoc(&selector, "words2").?);
    try std.testing.expectEqual(@as(u32, 296), selector.stack_frame_bytes);
    try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .sub_rsp_imm32 = 296 }, machine.instructions.items[0]);
}
