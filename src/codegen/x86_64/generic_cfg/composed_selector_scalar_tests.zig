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

test "generic cfg selector lowers signed i32 greater-than immediate" {
    var machine = MachineFunction.init("sgt-i32-imm", .{ .int = 1 });
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    try selector_state.bindValueLoc(&selector, "value", .{ .arg32 = .rdi });

    const diagnostic = try selector_scalar.lowerIcmp(&selector, "cmp", .{
        .predicate = .sgt,
        .operand_ty = .{ .int = 32 },
        .lhs = .{ .named = "value" },
        .rhs = .{ .int = 15 },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc.eax, selector_state.valueLoc(&selector, "cmp").?);
    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .mov_arg_eax = .rdi },
        .{ .cmp_eax_imm32 = 15 },
        .setg_eax,
    }, machine.instructions.items);
}

test "generic cfg selector lowers unsigned i32 less-than immediate" {
    var machine = MachineFunction.init("ult-i32-imm", .{ .int = 1 });
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    try selector_state.bindValueLoc(&selector, "value", .{ .arg32 = .rdi });

    const diagnostic = try selector_scalar.lowerIcmp(&selector, "cmp", .{
        .predicate = .ult,
        .operand_ty = .{ .int = 32 },
        .lhs = .{ .named = "value" },
        .rhs = .{ .int = 32 },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc.eax, selector_state.valueLoc(&selector, "cmp").?);
    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .mov_arg_eax = .rdi },
        .{ .cmp_eax_imm32 = 32 },
        .setb_eax,
    }, machine.instructions.items);
}
