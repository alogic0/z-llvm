const std = @import("std");
const ir = @import("../../../ir.zig");
const x86_64_machine = @import("../machine.zig");
const x86_64_verify = @import("../verify.zig");
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

test "generic cfg selector multiplies by an rax-resident i64 rhs" {
    var machine = MachineFunction.init("mul64-rax-rhs", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    try machine.instructions.append(std.testing.allocator, .{ .mov_arg_rax = .rsi });

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    try selector_state.bindValueLoc(&selector, "lhs", .{ .arg64 = .rdi });
    try selector_state.bindValueLoc(&selector, "rhs", .rax);

    const diagnostic = try selector_scalar.lowerMul64(&selector, "product", .{
        .op = .mul,
        .ty = .{ .int = 64 },
        .lhs = .{ .named = "lhs" },
        .rhs = .{ .named = "rhs" },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rdi }, selector_state.valueLoc(&selector, "product").?);
    try std.testing.expectEqual(ValueLoc.rax, selector_state.valueLoc(&selector, "rhs").?);
    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .mov_arg_rax = .rsi },
        .{ .imul_arg64_rax = .rdi },
    }, machine.instructions.items);

    try machine.instructions.append(std.testing.allocator, .{ .mov_arg_rax = .rdi });
    try machine.instructions.append(std.testing.allocator, .ret);
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const function: *const fn (u64, u64) callconv(.c) u64 = @ptrCast(mapping.ptr);
    try std.testing.expectEqual(@as(u64, 42), function(6, 7));
    try std.testing.expectEqual(@as(u64, 0xffff_ffff_ffff_fffe), function(2, 0x7fff_ffff_ffff_ffff));

    var near_miss_machine = MachineFunction.init("mul64-eax-rhs", .{ .int = 64 });
    defer near_miss_machine.deinit(std.testing.allocator);
    var near_miss_selector = ComposedBlockSelector.init(std.testing.allocator, &near_miss_machine);
    defer near_miss_selector.deinit();
    try selector_state.bindValueLoc(&near_miss_selector, "lhs", .{ .arg64 = .rdi });
    try selector_state.bindValueLoc(&near_miss_selector, "rhs", .eax);
    const near_miss = (try selector_scalar.lowerMul64(&near_miss_selector, "product", .{
        .op = .mul,
        .ty = .{ .int = 64 },
        .lhs = .{ .named = "lhs" },
        .rhs = .{ .named = "rhs" },
    })).?;
    try std.testing.expectEqualStrings("composed-block-mul64-rhs", near_miss.detail());
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

test "generic cfg selector executes exact i16 greater-than negative one" {
    const input =
        \\define i32 @is_nonnegative_i16(i32 %wide_value) {
        \\entry:
        \\  %value = trunc i32 %wide_value to i16
        \\  %comparison = icmp sgt i16 %value, -1
        \\  %result = zext i1 %comparison to i32
        \\  ret i32 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = MachineFunction.init("is_nonnegative_i16", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const function: *const fn (u32) callconv(.c) u32 = @ptrCast(mapping.ptr);
    const cases = [_]struct { input: u32, expected: u32 }{
        .{ .input = 0x0000, .expected = 1 },
        .{ .input = 0x0001, .expected = 1 },
        .{ .input = 0x7fff, .expected = 1 },
        .{ .input = 0x8000, .expected = 0 },
        .{ .input = 0xffff, .expected = 0 },
    };
    for (cases) |case| try std.testing.expectEqual(case.expected, function(case.input));

    var near_miss_machine = MachineFunction.init("i16-sgt-other-immediate", .{ .int = 1 });
    defer near_miss_machine.deinit(std.testing.allocator);
    var near_miss_selector = ComposedBlockSelector.init(std.testing.allocator, &near_miss_machine);
    defer near_miss_selector.deinit();
    try selector_state.bindValueLoc(&near_miss_selector, "value", .{ .arg32 = .rdi });
    const diagnostic = (try selector_scalar.lowerIcmp(&near_miss_selector, "cmp", .{
        .predicate = .sgt,
        .operand_ty = .{ .int = 16 },
        .lhs = .{ .named = "value" },
        .rhs = .{ .int = 0 },
    })).?;
    try std.testing.expectEqualStrings("composed-block-icmp-form", diagnostic.detail());
}

test "generic cfg selector lowers plain signed i64 greater-than immediate" {
    var machine = MachineFunction.init("sgt-i64-imm", .{ .int = 1 });
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    try selector_state.bindValueLoc(&selector, "value", .{ .arg64 = .rdi });

    const diagnostic = try selector_scalar.lowerIcmp(&selector, "cmp", .{
        .predicate = .sgt,
        .operand_ty = .{ .int = 64 },
        .lhs = .{ .named = "value" },
        .rhs = .{ .int = -1 },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc.eax, selector_state.valueLoc(&selector, "cmp").?);
    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .mov_arg64_arg = .{ .dst = .rcx, .src = .rdi } },
        .{ .cmp_arg64_imm64 = .{ .reg = .rcx, .imm = -1 } },
        .setg_eax,
    }, machine.instructions.items);

    var near_miss_machine = MachineFunction.init("samesign-sgt-i64-imm", .{ .int = 1 });
    defer near_miss_machine.deinit(std.testing.allocator);
    var near_miss_selector = ComposedBlockSelector.init(std.testing.allocator, &near_miss_machine);
    defer near_miss_selector.deinit();
    try selector_state.bindValueLoc(&near_miss_selector, "value", .{ .arg64 = .rdi });
    const near_miss = (try selector_scalar.lowerIcmp(&near_miss_selector, "cmp", .{
        .predicate = .sgt,
        .samesign = true,
        .operand_ty = .{ .int = 64 },
        .lhs = .{ .named = "value" },
        .rhs = .{ .int = -1 },
    })).?;
    try std.testing.expectEqualStrings("composed-block-icmp-form", near_miss.detail());
}

test "generic cfg selector executes signed i64 greater-than immediate boundaries" {
    const input =
        \\define i32 @compare(i64 %value) {
        \\entry:
        \\  %comparison = icmp sgt i64 %value, -1
        \\  %result = zext i1 %comparison to i32
        \\  ret i32 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = MachineFunction.init("compare", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const function: *const fn (i64) callconv(.c) u32 = @ptrCast(mapping.ptr);
    const cases = [_]struct { input: i64, expected: u32 }{
        .{ .input = std.math.minInt(i64), .expected = 0 },
        .{ .input = -2, .expected = 0 },
        .{ .input = -1, .expected = 0 },
        .{ .input = 0, .expected = 1 },
        .{ .input = std.math.maxInt(i64), .expected = 1 },
    };
    for (cases) |case| try std.testing.expectEqual(case.expected, function(case.input));
}

test "generic cfg selector lowers plain signed less-than immediates" {
    inline for (.{
        .{ .bits = 32, .rhs = 8_388_608 },
        .{ .bits = 64, .rhs = 4_503_599_627_370_496 },
    }) |case| {
        var machine = MachineFunction.init("slt-imm", .{ .int = 1 });
        defer machine.deinit(std.testing.allocator);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        try selector_state.bindValueLoc(&selector, "value", if (case.bits == 32) .{ .arg32 = .rdi } else .{ .arg64 = .rdi });

        const diagnostic = try selector_scalar.lowerIcmp(&selector, "cmp", .{
            .predicate = .slt,
            .operand_ty = .{ .int = case.bits },
            .lhs = .{ .named = "value" },
            .rhs = .{ .int = case.rhs },
        });

        try std.testing.expect(diagnostic == null);
        try std.testing.expectEqual(ValueLoc.eax, selector_state.valueLoc(&selector, "cmp").?);
        if (case.bits == 32) {
            try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
                .{ .mov_arg_eax = .rdi },
                .{ .cmp_eax_imm32 = 8_388_608 },
                .setl_eax,
            }, machine.instructions.items);
        } else {
            try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
                .{ .mov_arg64_arg = .{ .dst = .rcx, .src = .rdi } },
                .{ .cmp_arg64_imm64 = .{ .reg = .rcx, .imm = 4_503_599_627_370_496 } },
                .setl_eax,
            }, machine.instructions.items);
        }
    }

    var machine = MachineFunction.init("samesign-slt-imm", .{ .int = 1 });
    defer machine.deinit(std.testing.allocator);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    try selector_state.bindValueLoc(&selector, "value", .{ .arg32 = .rdi });
    const diagnostic = (try selector_scalar.lowerIcmp(&selector, "cmp", .{
        .predicate = .slt,
        .samesign = true,
        .operand_ty = .{ .int = 32 },
        .lhs = .{ .named = "value" },
        .rhs = .{ .int = 8_388_608 },
    })).?;
    try std.testing.expectEqualStrings("composed-block-icmp-form", diagnostic.detail());
}

test "generic cfg selector executes signed less-than immediate boundaries" {
    const wide_input =
        \\define i32 @compare_wide(i64 %value) {
        \\entry:
        \\  %comparison = icmp slt i64 %value, 4503599627370496
        \\  %result = zext i1 %comparison to i32
        \\  ret i32 %result
        \\}
        \\
    ;
    var wide_module = try ir.Module.parse(std.testing.allocator, wide_input);
    defer wide_module.deinit();
    try wide_module.verify();
    var wide_machine = MachineFunction.init("compare_wide", .{ .int = 32 });
    defer wide_machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &wide_machine, wide_module.functions.items[0]));
    const wide_bytes = try encoding.encodeFunction(std.testing.allocator, wide_machine);
    defer std.testing.allocator.free(wide_bytes);
    const wide_mapping = try std.posix.mmap(null, wide_bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(wide_mapping);
    @memcpy(wide_mapping, wide_bytes);
    const wide_function: *const fn (i64) callconv(.c) u32 = @ptrCast(wide_mapping.ptr);
    const wide_cases = [_]struct { input: i64, expected: u32 }{
        .{ .input = -1, .expected = 1 },
        .{ .input = 4_503_599_627_370_495, .expected = 1 },
        .{ .input = 4_503_599_627_370_496, .expected = 0 },
        .{ .input = std.math.maxInt(i64), .expected = 0 },
    };
    for (wide_cases) |case| try std.testing.expectEqual(case.expected, wide_function(case.input));

    const narrow_input =
        \\define i32 @compare_narrow(i32 %value) {
        \\entry:
        \\  %comparison = icmp slt i32 %value, 8388608
        \\  %result = zext i1 %comparison to i32
        \\  ret i32 %result
        \\}
        \\
    ;
    var narrow_module = try ir.Module.parse(std.testing.allocator, narrow_input);
    defer narrow_module.deinit();
    try narrow_module.verify();
    var narrow_machine = MachineFunction.init("compare_narrow", .{ .int = 32 });
    defer narrow_machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &narrow_machine, narrow_module.functions.items[0]));
    const narrow_bytes = try encoding.encodeFunction(std.testing.allocator, narrow_machine);
    defer std.testing.allocator.free(narrow_bytes);
    const narrow_mapping = try std.posix.mmap(null, narrow_bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(narrow_mapping);
    @memcpy(narrow_mapping, narrow_bytes);
    const narrow_function: *const fn (i32) callconv(.c) u32 = @ptrCast(narrow_mapping.ptr);
    const narrow_cases = [_]struct { input: i32, expected: u32 }{
        .{ .input = -1, .expected = 1 },
        .{ .input = 8_388_607, .expected = 1 },
        .{ .input = 8_388_608, .expected = 0 },
        .{ .input = std.math.maxInt(i32), .expected = 0 },
    };
    for (narrow_cases) |case| try std.testing.expectEqual(case.expected, narrow_function(case.input));
}

test "generic cfg selector lowers plain named signed comparisons" {
    inline for (.{
        .{ .bits = 32, .predicate = ir.IcmpPredicate.slt },
        .{ .bits = 32, .predicate = ir.IcmpPredicate.sgt },
        .{ .bits = 64, .predicate = ir.IcmpPredicate.slt },
        .{ .bits = 64, .predicate = ir.IcmpPredicate.sgt },
    }) |case| {
        var machine = MachineFunction.init("signed-named", .{ .int = 1 });
        defer machine.deinit(std.testing.allocator);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        try selector_state.bindValueLoc(&selector, "lhs", if (case.bits == 32) .{ .arg32 = .rdi } else .{ .arg64 = .rdi });
        try selector_state.bindValueLoc(&selector, "rhs", if (case.bits == 32) .{ .arg32 = .rsi } else .{ .arg64 = .rsi });

        const diagnostic = try selector_scalar.lowerIcmp(&selector, "cmp", .{
            .predicate = case.predicate,
            .operand_ty = .{ .int = case.bits },
            .lhs = .{ .named = "lhs" },
            .rhs = .{ .named = "rhs" },
        });

        try std.testing.expect(diagnostic == null);
        try std.testing.expectEqual(ValueLoc.eax, selector_state.valueLoc(&selector, "cmp").?);
        try std.testing.expectEqual(@as(usize, 4), machine.instructions.items.len);
        try std.testing.expectEqual(if (case.bits == 32)
            x86_64_machine.Instruction{ .cmp_ecx_arg32 = .r8 }
        else
            x86_64_machine.Instruction{ .cmp_rcx_arg64 = .r8 }, machine.instructions.items[2]);
        try std.testing.expectEqual(if (case.predicate == .slt)
            x86_64_machine.Instruction.setg_eax
        else
            x86_64_machine.Instruction.setl_eax, machine.instructions.items[3]);
    }

    inline for (.{
        .{ .bits = 32, .samesign = true },
        .{ .bits = 16, .samesign = false },
    }) |case| {
        var machine = MachineFunction.init("signed-named-near-miss", .{ .int = 1 });
        defer machine.deinit(std.testing.allocator);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        try selector_state.bindValueLoc(&selector, "lhs", .{ .arg32 = .rdi });
        try selector_state.bindValueLoc(&selector, "rhs", .{ .arg32 = .rsi });
        const diagnostic = (try selector_scalar.lowerIcmp(&selector, "cmp", .{
            .predicate = .slt,
            .samesign = case.samesign,
            .operand_ty = .{ .int = case.bits },
            .lhs = .{ .named = "lhs" },
            .rhs = .{ .named = "rhs" },
        })).?;
        try std.testing.expectEqualStrings("composed-block-icmp-form", diagnostic.detail());
    }
}

test "generic cfg selector executes plain named signed comparison boundaries" {
    const input =
        \\define i32 @less_i32(i32 %lhs, i32 %rhs) {
        \\entry:
        \\  %comparison = icmp slt i32 %lhs, %rhs
        \\  %result = zext i1 %comparison to i32
        \\  ret i32 %result
        \\}
        \\define i32 @greater_i64(i64 %lhs, i64 %rhs) {
        \\entry:
        \\  %comparison = icmp sgt i64 %lhs, %rhs
        \\  %result = zext i1 %comparison to i32
        \\  ret i32 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const cases = [_]struct { lhs: i64, rhs: i64 }{
        .{ .lhs = std.math.minInt(i32), .rhs = std.math.maxInt(i32) },
        .{ .lhs = -1, .rhs = 0 },
        .{ .lhs = 0, .rhs = 0 },
        .{ .lhs = 0, .rhs = -1 },
        .{ .lhs = std.math.maxInt(i32), .rhs = std.math.minInt(i32) },
    };

    for (module.functions.items, 0..) |function_ir, function_index| {
        var machine = MachineFunction.init(function_ir.name, .{ .int = 32 });
        defer machine.deinit(std.testing.allocator);
        try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, function_ir));
        const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
        defer std.testing.allocator.free(bytes);
        const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(mapping);
        @memcpy(mapping, bytes);
        if (function_index == 0) {
            const function: *const fn (i32, i32) callconv(.c) u32 = @ptrCast(mapping.ptr);
            for (cases) |case| try std.testing.expectEqual(@intFromBool(case.lhs < case.rhs), function(@intCast(case.lhs), @intCast(case.rhs)));
        } else {
            const function: *const fn (i64, i64) callconv(.c) u32 = @ptrCast(mapping.ptr);
            for (cases) |case| try std.testing.expectEqual(@intFromBool(case.lhs > case.rhs), function(case.lhs, case.rhs));
        }
    }
}

test "generic cfg selector lowers exact plain named integer inequality" {
    inline for (.{ 32, 64 }) |bits| {
        var machine = MachineFunction.init("named-ne", .{ .int = 1 });
        defer machine.deinit(std.testing.allocator);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        try selector_state.bindValueLoc(&selector, "lhs", if (bits == 32) .{ .arg32 = .rdi } else .{ .arg64 = .rdi });
        try selector_state.bindValueLoc(&selector, "rhs", if (bits == 32) .{ .arg32 = .rsi } else .{ .arg64 = .rsi });

        const diagnostic = try selector_scalar.lowerIcmp(&selector, "cmp", .{
            .predicate = .ne,
            .operand_ty = .{ .int = bits },
            .lhs = .{ .named = "lhs" },
            .rhs = .{ .named = "rhs" },
        });

        try std.testing.expect(diagnostic == null);
        try std.testing.expectEqual(ValueLoc.eax, selector_state.valueLoc(&selector, "cmp").?);
        try std.testing.expectEqual(@as(usize, 4), machine.instructions.items.len);
        try std.testing.expectEqual(if (bits == 32)
            x86_64_machine.Instruction{ .cmp_ecx_arg32 = .r8 }
        else
            x86_64_machine.Instruction{ .cmp_rcx_arg64 = .r8 }, machine.instructions.items[2]);
        try std.testing.expectEqual(x86_64_machine.Instruction.setne_eax, machine.instructions.items[3]);
    }

    inline for (.{
        .{ .bits = 16, .samesign = false },
        .{ .bits = 32, .samesign = true },
    }) |case| {
        var machine = MachineFunction.init("named-ne-near-miss", .{ .int = 1 });
        defer machine.deinit(std.testing.allocator);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        try selector_state.bindValueLoc(&selector, "lhs", .{ .arg32 = .rdi });
        try selector_state.bindValueLoc(&selector, "rhs", .{ .arg32 = .rsi });
        const diagnostic = (try selector_scalar.lowerIcmp(&selector, "cmp", .{
            .predicate = .ne,
            .samesign = case.samesign,
            .operand_ty = .{ .int = case.bits },
            .lhs = .{ .named = "lhs" },
            .rhs = .{ .named = "rhs" },
        })).?;
        try std.testing.expectEqualStrings("composed-block-icmp-form", diagnostic.detail());
    }
}

test "generic cfg selector executes named integer inequality branch and select" {
    const input =
        \\define i32 @branch_ne_i32(i32 %lhs, i32 %rhs) {
        \\entry:
        \\  %comparison = icmp ne i32 %lhs, %rhs
        \\  br i1 %comparison, label %unequal, label %equal
        \\unequal:
        \\  ret i32 11
        \\equal:
        \\  ret i32 22
        \\}
        \\define i32 @select_ne_i32(i32 %lhs, i32 %rhs) {
        \\entry:
        \\  %comparison = icmp ne i32 %lhs, %rhs
        \\  %result = select i1 %comparison, i32 33, i32 44
        \\  ret i32 %result
        \\}
        \\define i32 @branch_ne_i64(i64 %lhs, i64 %rhs) {
        \\entry:
        \\  %comparison = icmp ne i64 %lhs, %rhs
        \\  br i1 %comparison, label %unequal, label %equal
        \\unequal:
        \\  ret i32 55
        \\equal:
        \\  ret i32 66
        \\}
        \\define i32 @select_ne_i64(i64 %lhs, i64 %rhs) {
        \\entry:
        \\  %comparison = icmp ne i64 %lhs, %rhs
        \\  %result = select i1 %comparison, i32 77, i32 88
        \\  ret i32 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const i32_cases = [_]struct { lhs: i32, rhs: i32 }{
        .{ .lhs = std.math.minInt(i32), .rhs = std.math.minInt(i32) },
        .{ .lhs = std.math.minInt(i32), .rhs = std.math.maxInt(i32) },
        .{ .lhs = std.math.maxInt(i32), .rhs = std.math.minInt(i32) },
        .{ .lhs = std.math.maxInt(i32), .rhs = std.math.maxInt(i32) },
    };
    const i64_cases = [_]struct { lhs: i64, rhs: i64 }{
        .{ .lhs = std.math.minInt(i64), .rhs = std.math.minInt(i64) },
        .{ .lhs = std.math.minInt(i64), .rhs = std.math.maxInt(i64) },
        .{ .lhs = std.math.maxInt(i64), .rhs = std.math.minInt(i64) },
        .{ .lhs = std.math.maxInt(i64), .rhs = std.math.maxInt(i64) },
    };

    for (module.functions.items, 0..) |function_ir, function_index| {
        var machine = MachineFunction.init(function_ir.name, function_ir.ret_ty);
        defer machine.deinit(std.testing.allocator);
        try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, function_ir));
        const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
        defer std.testing.allocator.free(bytes);
        const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(mapping);
        @memcpy(mapping, bytes);
        if (function_index < 2) {
            const function: *const fn (i32, i32) callconv(.c) i32 = @ptrCast(mapping.ptr);
            for (i32_cases) |case| {
                const expected: i32 = if (function_index == 0)
                    if (case.lhs != case.rhs) 11 else 22
                else if (case.lhs != case.rhs) 33 else 44;
                try std.testing.expectEqual(expected, function(case.lhs, case.rhs));
            }
        } else {
            const function: *const fn (i64, i64) callconv(.c) i32 = @ptrCast(mapping.ptr);
            for (i64_cases) |case| {
                const expected: i32 = if (function_index == 2)
                    if (case.lhs != case.rhs) 55 else 66
                else if (case.lhs != case.rhs) 77 else 88;
                try std.testing.expectEqual(expected, function(case.lhs, case.rhs));
            }
        }
    }
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

test "generic cfg selector lowers unsigned i16 immediate comparisons" {
    inline for (.{ .ult, .ugt }) |predicate| {
        var machine = MachineFunction.init("unsigned-i16-imm", .{ .int = 1 });
        defer machine.deinit(std.testing.allocator);

        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        try selector_state.bindValueLoc(&selector, "value", .{ .arg32 = .rdi });

        const diagnostic = try selector_scalar.lowerIcmp(&selector, "cmp", .{
            .predicate = predicate,
            .operand_ty = .{ .int = 16 },
            .lhs = .{ .named = "value" },
            .rhs = .{ .int = 0x7800 },
        });

        try std.testing.expect(diagnostic == null);
        try std.testing.expectEqual(ValueLoc.eax, selector_state.valueLoc(&selector, "cmp").?);
        try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
            .{ .mov_arg_arg = .{ .dst = .rcx, .src = .rdi } },
            .{ .cmp_arg16_imm16 = .{ .reg = .rcx, .imm = 0x7800 } },
            if (predicate == .ult) .setb_eax else .seta_eax,
        }, machine.instructions.items);
    }
}

test "generic cfg selector lowers variable i16 shifts" {
    inline for (.{ .shl, .lshr }) |op| {
        var machine = MachineFunction.init("variable-i16-shift", .{ .int = 16 });
        defer machine.deinit(std.testing.allocator);

        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        try selector_state.bindValueLoc(&selector, "value", .{ .arg32 = .rdi });
        try selector_state.bindValueLoc(&selector, "amount", .{ .arg32 = .rsi });

        const diagnostic = try selector_scalar.lowerBinary(&selector, "result", .{
            .op = op,
            .ty = .{ .int = 16 },
            .lhs = .{ .named = "value" },
            .rhs = .{ .named = "amount" },
        });

        try std.testing.expect(diagnostic == null);
        try std.testing.expectEqual(ValueLoc.eax, selector_state.valueLoc(&selector, "result").?);
        try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
            .{ .mov_arg_arg = .{ .dst = .rcx, .src = .rsi } },
            .{ .mov_arg_eax = .rdi },
            if (op == .shl) .shl_eax_cl else .shr_eax_cl,
        }, machine.instructions.items);
    }
}

test "generic cfg selector lowers i64 immediate-left variable lshr" {
    var machine = MachineFunction.init("variable-i64-lshr", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    try selector_state.bindValueLoc(&selector, "amount", .{ .arg64 = .rdi });

    try std.testing.expect((try selector_scalar.lowerBinary(&selector, "result", .{
        .op = .lshr,
        .ty = .{ .int = 64 },
        .lhs = .{ .int = -1 },
        .rhs = .{ .named = "amount" },
    })) == null);
    try std.testing.expectEqual(ValueLoc.rax, selector_state.valueLoc(&selector, "result").?);
    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .mov_arg64_arg = .{ .dst = .rcx, .src = .rdi } },
        .{ .mov_imm_rax = -1 },
        .shr_rax_cl,
    }, machine.instructions.items);
}

test "generic cfg selector lowers exact i16 and i32 immediate-left variable shl" {
    inline for (.{ 16, 32 }) |bits| {
        var machine = MachineFunction.init("variable-immediate-left-shl", .{ .int = bits });
        defer machine.deinit(std.testing.allocator);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        try selector_state.bindValueLoc(&selector, "amount", .{ .arg32 = .rdi });

        try std.testing.expect((try selector_scalar.lowerBinary(&selector, "result", .{
            .op = .shl,
            .ty = .{ .int = bits },
            .lhs = .{ .int = -1 },
            .rhs = .{ .named = "amount" },
        })) == null);
        try std.testing.expectEqual(ValueLoc.eax, selector_state.valueLoc(&selector, "result").?);
        if (bits == 16) {
            try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
                .{ .mov_arg_arg = .{ .dst = .rcx, .src = .rdi } },
                .{ .mov_imm_eax = -1 },
                .shl_eax_cl,
                .{ .and_eax_imm32 = 0xffff },
            }, machine.instructions.items);
        } else {
            try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
                .{ .mov_arg_arg = .{ .dst = .rcx, .src = .rdi } },
                .{ .mov_imm_eax = -1 },
                .shl_eax_cl,
            }, machine.instructions.items);
        }
    }

    inline for (.{64}) |bits| {
        var near_miss_machine = MachineFunction.init("variable-immediate-left-shl-near-miss", .{ .int = bits });
        defer near_miss_machine.deinit(std.testing.allocator);
        var near_miss_selector = ComposedBlockSelector.init(std.testing.allocator, &near_miss_machine);
        defer near_miss_selector.deinit();
        try selector_state.bindValueLoc(&near_miss_selector, "amount", .{ .arg64 = .rdi });
        const diagnostic = (try selector_scalar.lowerBinary(&near_miss_selector, "result", .{
            .op = .shl,
            .ty = .{ .int = bits },
            .lhs = .{ .int = -1 },
            .rhs = .{ .named = "amount" },
        })).?;
        try std.testing.expectEqualStrings("composed-block-binary-imm-lhs", diagnostic.detail());
    }
}

test "generic cfg selector executes i16 immediate-left variable shl boundaries" {
    const input =
        \\define i32 @shift_mask(i32 %amount) {
        \\entry:
        \\  %narrow_amount = trunc i32 %amount to i16
        \\  %result = shl nsw i16 -1, %narrow_amount
        \\  %wide_result = zext i16 %result to i32
        \\  ret i32 %wide_result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = MachineFunction.init("shift_mask", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const function: *const fn (u32) callconv(.c) u32 = @ptrCast(mapping.ptr);
    inline for (0..16) |amount| {
        const expected: u32 = @as(u16, @truncate(@as(u32, 0xffff) << @intCast(amount)));
        try std.testing.expectEqual(expected, function(amount));
    }
}

test "generic cfg selector executes i32 immediate-left variable shl boundaries" {
    const input =
        \\define i32 @shift_mask(i32 %amount) {
        \\entry:
        \\  %result = shl nsw i32 -1, %amount
        \\  ret i32 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = MachineFunction.init("shift_mask", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const function: *const fn (u32) callconv(.c) u32 = @ptrCast(mapping.ptr);
    inline for (.{
        .{ @as(u32, 0), @as(u32, 0xffff_ffff) },
        .{ @as(u32, 1), @as(u32, 0xffff_fffe) },
        .{ @as(u32, 15), @as(u32, 0xffff_8000) },
        .{ @as(u32, 30), @as(u32, 0xc000_0000) },
        .{ @as(u32, 31), @as(u32, 0x8000_0000) },
    }) |case| try std.testing.expectEqual(case[1], function(case[0]));
}

test "generic cfg selector lowers i64 immediate xor" {
    var machine = MachineFunction.init("i64-immediate-xor", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    try selector_state.bindValueLoc(&selector, "value", .{ .arg64 = .rdi });

    try std.testing.expect((try selector_scalar.lowerBinary(&selector, "result", .{
        .op = .xor,
        .ty = .{ .int = 64 },
        .lhs = .{ .named = "value" },
        .rhs = .{ .int = -1 },
    })) == null);
    try std.testing.expectEqual(ValueLoc.rax, selector_state.valueLoc(&selector, "result").?);
    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .mov_arg_rax = .rdi },
        .{ .mov_imm_rcx = -1 },
        .{ .binary_arg_rax = .{ .op = .xor, .reg = .rcx } },
    }, machine.instructions.items);
}

test "generic cfg selector preserves live accumulator across comparison" {
    const input =
        \\declare void @llvm.assume(i1)
        \\define i64 @preserve(i32 %input) {
        \\entry:
        \\  %selected = add i32 %input, 0
        \\  %valid = icmp sgt i32 %selected, -1
        \\  call void @llvm.assume(i1 %valid)
        \\  %wide = zext i32 %selected to i64
        \\  ret i64 %wide
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = MachineFunction.init("preserve", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const function: *const fn (u32) callconv(.c) u64 = @ptrCast(mapping.ptr);
    try std.testing.expectEqual(@as(u64, 17), function(17));
}

test "generic cfg selector lowers i32 arithmetic-right shifts" {
    inline for (.{ ir.Value{ .int = 7 }, ir.Value{ .named = "amount" } }) |rhs| {
        var machine = MachineFunction.init("i32-ashr", .{ .int = 32 });
        defer machine.deinit(std.testing.allocator);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        try selector_state.bindValueLoc(&selector, "value", .{ .arg32 = .rdi });
        try selector_state.bindValueLoc(&selector, "amount", .{ .arg32 = .rsi });

        try std.testing.expect((try selector_scalar.lowerBinary(&selector, "result", .{
            .op = .ashr,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "value" },
            .rhs = rhs,
        })) == null);
        try std.testing.expectEqual(ValueLoc.eax, selector_state.valueLoc(&selector, "result").?);
        const expected: x86_64_machine.Instruction = switch (rhs) {
            .int => .{ .sar_eax_imm5 = 7 },
            .named => .sar_eax_cl,
            else => unreachable,
        };
        try std.testing.expectEqual(expected, machine.instructions.items[machine.instructions.items.len - 1]);
    }
}

test "generic cfg selector preserves live accumulator across immediate binary" {
    const input =
        \\define i32 @live_immediate(i32 %value) {
        \\entry:
        \\  %source = add i32 %value, 1
        \\  %derived = add i32 %source, 2
        \\  %result = add i32 %source, %derived
        \\  ret i32 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = MachineFunction.init("live_immediate", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const function: *const fn (u32) callconv(.c) u32 = @ptrCast(mapping.ptr);

    try std.testing.expectEqual(@as(u32, 12), function(4));
}

test "generic cfg selector executes named i1 or through branch and select" {
    const input =
        \\define i32 @or_branch(i32 %lhs, i32 %rhs) {
        \\entry:
        \\  %left = icmp ne i32 %lhs, 0
        \\  %right = icmp ne i32 %rhs, 0
        \\  %combined = or i1 %left, %right
        \\  br i1 %combined, label %yes, label %no
        \\yes:
        \\  ret i32 1
        \\no:
        \\  ret i32 0
        \\}
        \\define i32 @or_select(i32 %lhs, i32 %rhs) {
        \\entry:
        \\  %left = icmp ne i32 %lhs, 0
        \\  %right = icmp ne i32 %rhs, 0
        \\  %combined = or i1 %right, %left
        \\  %selected = select i1 %combined, i32 1, i32 0
        \\  ret i32 %selected
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const cases = [_]struct {
        lhs: u32,
        rhs: u32,
        expected: u32,
    }{
        .{ .lhs = 0, .rhs = 0, .expected = 0 },
        .{ .lhs = 0, .rhs = 9, .expected = 1 },
        .{ .lhs = 7, .rhs = 0, .expected = 1 },
        .{ .lhs = 7, .rhs = 9, .expected = 1 },
    };

    for (module.functions.items) |function_ir| {
        var machine = MachineFunction.init(function_ir.name, .{ .int = 32 });
        defer machine.deinit(std.testing.allocator);
        try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, function_ir));

        var saw_or = false;
        for (machine.instructions.items) |instruction| switch (instruction) {
            .binary_arg_eax => |binary| saw_or = saw_or or binary.op == .@"or",
            else => {},
        };
        try std.testing.expect(saw_or);

        const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
        defer std.testing.allocator.free(bytes);
        const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(mapping);
        @memcpy(mapping, bytes);
        const function: *const fn (u32, u32) callconv(.c) u32 = @ptrCast(mapping.ptr);
        for (cases) |case| try std.testing.expectEqual(case.expected, function(case.lhs, case.rhs));
    }
}

test "generic cfg selector keeps unadmitted narrow or forms fail closed" {
    var machine = MachineFunction.init("unadmitted-or", .{ .int = 1 });
    defer machine.deinit(std.testing.allocator);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    try selector_state.bindValueLoc(&selector, "lhs", .{ .arg32 = .rdi });
    try selector_state.bindValueLoc(&selector, "rhs", .{ .arg32 = .rsi });

    const immediate = (try selector_scalar.lowerBinary(&selector, "i1_result", .{
        .op = .@"or",
        .ty = .{ .int = 1 },
        .lhs = .{ .named = "lhs" },
        .rhs = .{ .int = 1 },
    })).?;
    try std.testing.expectEqualStrings("composed-block-binary-width", immediate.detail());

    const i8_named = (try selector_scalar.lowerBinary(&selector, "i8_result", .{
        .op = .@"or",
        .ty = .{ .int = 8 },
        .lhs = .{ .named = "lhs" },
        .rhs = .{ .named = "rhs" },
    })).?;
    try std.testing.expectEqualStrings("composed-block-binary-width", i8_named.detail());
}

test "generic cfg selector executes i7 immediate binary operations modulo 128" {
    const input =
        \\define i32 @narrow_binary(i64 %input) {
        \\entry:
        \\  %narrow = trunc i64 %input to i7
        \\  %adjusted = add i7 %narrow, -11
        \\  %flipped = xor i7 %adjusted, 63
        \\  %wide = zext i7 %flipped to i32
        \\  ret i32 %wide
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = MachineFunction.init("narrow_binary", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));
    try x86_64_verify.verifyFunction(machine);
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const narrow_binary: *const fn (u64) callconv(.c) u32 = @ptrCast(mapping.ptr);
    inline for (.{
        .{ @as(u64, 0), @as(u32, 74) },
        .{ @as(u64, 10), @as(u32, 64) },
        .{ @as(u64, 11), @as(u32, 63) },
        .{ @as(u64, 64), @as(u32, 10) },
        .{ @as(u64, 127), @as(u32, 75) },
        .{ @as(u64, 128), @as(u32, 74) },
    }) |case| try std.testing.expectEqual(case[1], narrow_binary(case[0]));

    var rejected_machine = MachineFunction.init("rejected-narrow-binary", .{ .int = 5 });
    defer rejected_machine.deinit(std.testing.allocator);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &rejected_machine);
    defer selector.deinit();
    try selector_state.bindValueLoc(&selector, "value", .{ .arg32 = .rdi });
    const diagnostic = (try selector_scalar.lowerBinary(&selector, "result", .{
        .op = .xor,
        .ty = .{ .int = 5 },
        .lhs = .{ .named = "value" },
        .rhs = .{ .int = 15 },
    })).?;
    try std.testing.expectEqualStrings("composed-block-binary-width", diagnostic.detail());
    try std.testing.expectEqual(@as(usize, 0), rejected_machine.instructions.items.len);
}

test "generic cfg selector preserves every live accumulator alias across immediate binary operations" {
    const input =
        \\declare i32 @llvm.ctlz.i32(i32, i1 immarg)
        \\
        \\define i32 @trunc_alias(i32 %input) {
        \\entry:
        \\  %leading = call i32 @llvm.ctlz.i32(i32 %input, i1 true)
        \\  %narrow = trunc i32 %leading to i6
        \\  %flipped = xor i6 %narrow, 31
        \\  %sum = add i6 %narrow, %flipped
        \\  %sum_wide = zext i6 %sum to i32
        \\  %leading_shifted = shl i32 %leading, 12
        \\  %combined = or i32 %leading_shifted, %sum_wide
        \\  ret i32 %combined
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = MachineFunction.init("trunc_alias", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));
    try x86_64_verify.verifyFunction(machine);
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const trunc_alias: *const fn (u32) callconv(.c) u32 = @ptrCast(mapping.ptr);
    inline for (.{
        .{ @as(u32, 1), @as(u32, 127007) },
        .{ @as(u32, 2), @as(u32, 122911) },
        .{ @as(u32, 0x10000), @as(u32, 61471) },
        .{ @as(u32, 0x80000000), @as(u32, 31) },
    }) |case| try std.testing.expectEqual(case[1], trunc_alias(case[0]));
}

test "generic cfg selector executes signed i32 division by two toward zero" {
    const input =
        \\define i32 @divide_by_two(i32 %value) {
        \\entry:
        \\  %quotient = sdiv i32 %value, 2
        \\  ret i32 %quotient
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = MachineFunction.init("divide_by_two", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));
    try x86_64_verify.verifyFunction(machine);
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const divide_by_two: *const fn (i32) callconv(.c) i32 = @ptrCast(mapping.ptr);

    inline for (.{
        .{ std.math.minInt(i32), -1073741824 },
        .{ -8, -4 },
        .{ -7, -3 },
        .{ -5, -2 },
        .{ -3, -1 },
        .{ -1, 0 },
        .{ 0, 0 },
        .{ 1, 0 },
        .{ 2, 1 },
        .{ 3, 1 },
        .{ 7, 3 },
        .{ std.math.maxInt(i32), 1073741823 },
    }) |case| try std.testing.expectEqual(@as(i32, case[1]), divide_by_two(case[0]));
}

test "generic cfg selector keeps other signed division forms fail closed" {
    const Case = struct { bits: u16, lhs: ir.Value, rhs: ir.Value };
    const cases = [_]Case{
        .{ .bits = 32, .lhs = .{ .named = "value" }, .rhs = .{ .int = 3 } },
        .{ .bits = 64, .lhs = .{ .named = "value" }, .rhs = .{ .int = 2 } },
        .{ .bits = 32, .lhs = .{ .int = 8 }, .rhs = .{ .named = "value" } },
        .{ .bits = 32, .lhs = .{ .named = "value" }, .rhs = .{ .named = "divisor" } },
    };
    for (cases) |case| {
        var machine = MachineFunction.init("rejected-sdiv", .{ .int = case.bits });
        defer machine.deinit(std.testing.allocator);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        try selector_state.bindValueLoc(&selector, "value", if (case.bits == 64) .{ .arg64 = .rdi } else .{ .arg32 = .rdi });
        try selector_state.bindValueLoc(&selector, "divisor", .{ .arg32 = .rsi });
        const diagnostic = (try selector_scalar.lowerBinary(&selector, "result", .{
            .op = .sdiv,
            .ty = .{ .int = case.bits },
            .lhs = case.lhs,
            .rhs = case.rhs,
        })).?;
        try std.testing.expect(std.mem.startsWith(u8, diagnostic.detail(), "composed-block-"));
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    }
}
