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

test "composed remainder restores simultaneous-input preservation on spill failure" {
    var machine = MachineFunction.init("remainder-input-guard", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("lhs", 1);
    try plan.interval_ends.put("rhs", 1);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 1;
    try selector_state.bindValueLoc(&selector, "lhs", .{ .scratch32 = .rcx });
    try selector_state.bindValueLoc(&selector, "rhs", .eax);
    try std.testing.expectError(error.UnsupportedCodegenValue, selector_scalar.lowerUnsignedDivRem(&selector, "result", .{
        .op = .urem,
        .ty = .{ .int = 32 },
        .lhs = .{ .named = "lhs" },
        .rhs = .{ .named = "rhs" },
    }, 32));
    try std.testing.expect(!selector.preserve_current_position_values);
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try std.testing.expectEqual(ValueLoc{ .scratch32 = .rcx }, selector_state.valueLoc(&selector, "lhs").?);
    try std.testing.expectEqual(ValueLoc.eax, selector_state.valueLoc(&selector, "rhs").?);
    try std.testing.expect(selector_state.valueLoc(&selector, "result") == null);
}

test "flag-writing accumulator cast rejects live EFLAGS before mutating selector state" {
    var machine = MachineFunction.init("live-flags-cast", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("source", 1);
    try plan.interval_ends.put("result", 1);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "source", .{ .arg32 = .rdi });
    try machine.instructions.append(std.testing.allocator, .{ .mov_imm_eax = 7 });
    try selector.eflags.apply(.definition);

    const source_binding = selector.values.get("source").?;
    const saved_eflags = selector.eflags.snapshot();
    const saved_next_virtual_reg = selector.next_virtual_reg;
    try std.testing.expectError(
        error.EflagsClobberedWhileLive,
        selector_scalar.lowerCast(&selector, "result", .{
            .op = .zext,
            .value = .{ .named = "source" },
            .from_ty = .{ .int = 8 },
            .to_ty = .{ .int = 32 },
        }),
    );

    try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
    try std.testing.expectEqual(source_binding, selector.values.get("source").?);
    try std.testing.expect(selector.values.get("result") == null);
    try std.testing.expectEqual(saved_next_virtual_reg, selector.next_virtual_reg);
    try std.testing.expectEqual(@as(usize, 0), selector.spill_slots.count());
    try std.testing.expect(selector.accumulator_domain.occupantFor(.eax) == null);
    try selector.eflags.validateSnapshot(saved_eflags);
}

test "i52 destructive cast re-resolves the accepted spill and reload source" {
    var machine = MachineFunction.init("i52-spill-reload", .{ .int = 52 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("source", 5);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 1;
    selector.stack_frame_bytes = stage2SpillReservedBytes();
    try selector_state.bindValueLoc(&selector, "source", .rax);

    try std.testing.expect((try selector_scalar.lowerCast(&selector, "result", .{
        .op = .trunc,
        .value = .{ .named = "source" },
        .from_ty = .{ .int = 64 },
        .to_ty = .{ .int = 52 },
    })) == null);
    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .spill_rax_rsp = .slot0 },
        .{ .reload_rsp_rax = .slot0 },
        .{ .mov_imm_rcx = @bitCast(@as(u64, (@as(u64, 1) << 52) - 1)) },
        .{ .binary_arg_rax = .{ .op = .@"and", .reg = .rcx } },
    }, machine.instructions.items);
    try std.testing.expectEqual(ValueLoc.rax, selector_state.valueLoc(&selector, "result").?);
}

test "scalar cast production dispatch keeps alias and pair-result casts on O4 paths" {
    {
        var machine = MachineFunction.init("cast-alias-o4", .{ .int = 32 });
        defer machine.deinit(std.testing.allocator);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        try selector_state.bindValueLoc(&selector, "source", .{ .arg64 = .rdi });

        try std.testing.expect((try selector_scalar.lowerCast(&selector, "result", .{
            .op = .trunc,
            .value = .{ .named = "source" },
            .from_ty = .{ .int = 64 },
            .to_ty = .{ .int = 32 },
        })) == null);
        try std.testing.expectEqual(
            ValueLoc{ .scratch32 = .rdi },
            selector_state.valueLoc(&selector, "result").?,
        );
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    }
    {
        var machine = MachineFunction.init("cast-pair-result-o4", .{ .int = 128 });
        defer machine.deinit(std.testing.allocator);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        try selector_state.bindValueLoc(&selector, "source", .{ .arg64 = .rdi });

        try std.testing.expect((try selector_scalar.lowerCast(&selector, "result", .{
            .op = .zext,
            .value = .{ .named = "source" },
            .from_ty = .{ .int = 64 },
            .to_ty = .{ .int = 128 },
        })) == null);
        try std.testing.expectEqual(
            ValueLoc{ .scratch128 = pair_a },
            selector_state.valueLoc(&selector, "result").?,
        );
        try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
            .{ .mov_arg64_arg = .{ .dst = .rcx, .src = .rdi } },
            .{ .mov_imm_rdx = 0 },
        }, machine.instructions.items);
    }
}

test "sign-extend scratch cast production dispatch is byte exact and durable" {
    var machine = MachineFunction.init("cast-sign-extend-o2", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("source", 1);
    try plan.interval_ends.put("result", 1);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "source", .{ .arg32 = .rdi });

    try std.testing.expect((try selector_scalar.lowerCast(&selector, "result", .{
        .op = .sext,
        .value = .{ .named = "source" },
        .from_ty = .{ .int = 32 },
        .to_ty = .{ .int = 64 },
    })) == null);
    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .movsxd_arg32_arg64 = .{ .dst = .r8, .src = .rdi } },
    }, machine.instructions.items);
    try std.testing.expectEqual(
        ValueLoc{ .scratch64 = .r8 },
        selector_state.valueLoc(&selector, "result").?,
    );
}

test "generic cfg selector materializes mul64 lhs into planned register" {
    var machine = MachineFunction.init("planned-mul64", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.assignments.put("old", .{ .gpr64 = .r8 });
    try plan.interval_ends.put("old", 1);
    try plan.assignments.put("lhs", .{ .gpr64 = .rdi });
    try plan.interval_ends.put("lhs", 2);
    try plan.assignments.put("rhs", .{ .gpr64 = .rsi });
    try plan.interval_ends.put("rhs", 2);
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
    try plan.assignments.put("live_rdi", .{ .gpr64 = .rdi });
    try plan.interval_ends.put("live_rsi", 10);
    try plan.assignments.put("live_rsi", .{ .gpr64 = .rsi });
    try plan.interval_ends.put("lhs", 4);
    try plan.assignments.put("lhs", .{ .gpr64 = .rdx });
    try plan.interval_ends.put("rhs", 4);
    try plan.assignments.put("rhs", .{ .spill = 1 });
    try plan.interval_ends.put("live_rcx", 10);
    try plan.assignments.put("live_rcx", .{ .gpr64 = .rcx });
    try plan.interval_ends.put("live_r8", 10);
    try plan.assignments.put("live_r8", .{ .gpr64 = .r8 });
    try plan.interval_ends.put("live_r9", 10);
    try plan.assignments.put("live_r9", .{ .gpr64 = .r9 });
    try plan.interval_ends.put("product", 4);
    try plan.assignments.put("product", .{ .gpr64 = .rdx });

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

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.assignments.put("lhs", .{ .gpr64 = .rdi });
    try plan.interval_ends.put("lhs", 0);
    try plan.assignments.put("rhs", .{ .gpr64 = .rsi });
    try plan.interval_ends.put("rhs", 0);
    try plan.assignments.put("product", .{ .gpr64 = .rdi });
    try plan.interval_ends.put("product", 0);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 0;
    try selector_state.bindValueLoc(&selector, "lhs", .{ .arg64 = .rdi });
    try selector_state.bindValueLoc(&selector, "rhs", .rax);

    const diagnostic = try selector_scalar.lowerMul64(&selector, "product", .{
        .op = .mul,
        .ty = .{ .int = 64 },
        .lhs = .{ .named = "lhs" },
        .rhs = .{ .named = "rhs" },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rsi }, selector_state.valueLoc(&selector, "product").?);
    try std.testing.expectEqual(ValueLoc.rax, selector_state.valueLoc(&selector, "rhs").?);
    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .mov_arg_rax = .rsi },
        .{ .mov_arg64_arg = .{ .dst = .rsi, .src = .rdi } },
        .{ .imul_arg64_rax = .rsi },
    }, machine.instructions.items);

    try machine.instructions.append(std.testing.allocator, .{ .mov_arg_rax = .rsi });
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
    var near_miss_plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer near_miss_plan.deinit();
    try near_miss_plan.assignments.put("lhs", .{ .gpr64 = .rdi });
    try near_miss_plan.interval_ends.put("lhs", 0);
    try near_miss_plan.assignments.put("rhs", .{ .gpr64 = .rsi });
    try near_miss_plan.interval_ends.put("rhs", 0);
    try near_miss_plan.assignments.put("product", .{ .gpr64 = .rdi });
    try near_miss_plan.interval_ends.put("product", 0);
    var near_miss_selector = ComposedBlockSelector.init(std.testing.allocator, &near_miss_machine);
    defer near_miss_selector.deinit();
    near_miss_selector.allocation_plan = &near_miss_plan;
    near_miss_selector.current_position = 0;
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
    try plan.assignments.put("live_rax", .{ .spill = 0 });
    try plan.interval_ends.put("live_rdi", 10);
    try plan.assignments.put("live_rdi", .{ .gpr64 = .rdi });
    try plan.interval_ends.put("live_rsi", 10);
    try plan.assignments.put("live_rsi", .{ .gpr64 = .rsi });
    try plan.interval_ends.put("live_rdx", 10);
    try plan.assignments.put("live_rdx", .{ .gpr64 = .rdx });
    try plan.interval_ends.put("live_rcx", 10);
    try plan.assignments.put("live_rcx", .{ .gpr64 = .rcx });
    try plan.interval_ends.put("live_r8", 10);
    try plan.assignments.put("live_r8", .{ .gpr64 = .r8 });
    try plan.interval_ends.put("live_r9", 10);
    try plan.assignments.put("live_r9", .{ .gpr64 = .r9 });
    try plan.interval_ends.put("lhs", 4);
    try plan.assignments.put("lhs", .{ .spill = 5 });
    try plan.interval_ends.put("rhs", 4);
    try plan.assignments.put("rhs", .{ .spill = 6 });

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
    var plan = try allocateSelectorIntervals(std.testing.allocator, &.{
        .{ .name = "lhs", .class = .gpr32, .bits = 32, .start = 0, .end = 1 },
        .{ .name = "rhs", .class = .gpr32, .bits = 32, .start = 0, .end = 1 },
    });
    defer plan.deinit();

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 1;

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
    try plan.interval_ends.put("shifted", 3);

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

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("wide", 1);
    try plan.interval_ends.put("lo", 1);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;

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
    try plan.interval_ends.put("shifted", 3);

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

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("wide_lo", 0);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 0;

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
    try plan.interval_ends.put("right", 4);

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

test "generic cfg selector immediate i64 siblings preserve a current accumulator source at final use" {
    inline for (.{
        .{ ir.BinaryOp.@"and", @as(i128, 0x1_0000_0000), x86_64_machine.Instruction{ .binary_arg_rax = .{ .op = .@"and", .reg = .rcx } } },
        .{ ir.BinaryOp.@"or", @as(i128, 0x2_0000_0000), x86_64_machine.Instruction{ .binary_arg_rax = .{ .op = .@"or", .reg = .rcx } } },
        .{ ir.BinaryOp.add, @as(i128, 0x3_0000_0000), x86_64_machine.Instruction{ .binary_arg_rax = .{ .op = .add, .reg = .rcx } } },
        .{ ir.BinaryOp.xor, @as(i128, 0x4_0000_0000), x86_64_machine.Instruction{ .binary_arg_rax = .{ .op = .xor, .reg = .rcx } } },
    }) |case| {
        var machine = MachineFunction.init("current-rax-immediate-final-use", .{ .int = 64 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try plan.interval_ends.put("source", 0);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.current_position = 0;
        selector.stack_frame_bytes = stage2SpillReservedBytes();
        try selector_state.bindValueLoc(&selector, "source", .rax);

        try std.testing.expect((try selector_scalar.lowerBinaryImmediateRhs(&selector, "result", .{
            .op = case[0],
            .ty = .{ .int = 64 },
            .lhs = .{ .named = "source" },
            .rhs = .{ .int = case[1] },
        })) == null);
        try std.testing.expectEqual(
            ValueLoc{ .spill64 = .slot0 },
            selector_state.valueLoc(&selector, "source").?,
        );
        try std.testing.expectEqual(ValueLoc.rax, selector_state.valueLoc(&selector, "result").?);
        try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
            .{ .spill_rax_rsp = .slot0 },
            .{ .reload_rsp_rax = .slot0 },
            .{ .mov_imm_rcx = @intCast(case[1]) },
            case[2],
        }, machine.instructions.items);
    }
}

test "named wide shifts consume a final-use staged accumulator count without spilling" {
    const allocator = std.testing.allocator;
    for ([_]ir.BinaryOp{ .shl, .lshr, .ashr }) |op| {
        var machine = MachineFunction.init("shift", .{ .int = 64 });
        defer machine.deinit(allocator);
        var plan = try allocateSelectorIntervals(allocator, &.{
            .{ .name = "value", .class = .gpr64, .bits = 64, .start = 0, .end = 2 },
            .{ .name = "count", .class = .gpr64, .bits = 64, .start = 1, .end = 2 },
        });
        defer plan.deinit();
        var selector = ComposedBlockSelector.init(allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.current_position = 2;
        try selector_state.bindValueLoc(&selector, "value", .{ .arg64 = .rdi });
        try selector_state.bindValueLoc(&selector, "count", .rax);
        try std.testing.expect((try selector_scalar.lowerBinary(&selector, "result", .{
            .op = op,
            .ty = .{ .int = 64 },
            .lhs = .{ .named = "value" },
            .rhs = .{ .named = "count" },
        })) == null);
        try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
            .{ .mov_rax_to_arg = .rcx },
            .{ .mov_arg_rax = .rdi },
            switch (op) {
                .shl => .shl_rax_cl,
                .lshr => .shr_rax_cl,
                .ashr => .sar_rax_cl,
                else => unreachable,
            },
        }, machine.instructions.items);
    }
}

test "generic cfg selector executes frameless i64 shifts with a final-use extended count" {
    const allocator = std.testing.allocator;
    for ([_]ir.BinaryOp{ .shl, .lshr, .ashr }) |op| {
        const input = try std.fmt.allocPrint(allocator,
            \\define i64 @shift(i64 %x, i8 %n) {{
            \\entry:
            \\  %lo = trunc i8 %n to i4
            \\  %mid = zext i4 %lo to i6
            \\  %count = zext i6 %mid to i64
            \\  %result = {s} i64 %x, %count
            \\  ret i64 %result
            \\}}
        , .{@tagName(op)});
        defer allocator.free(input);
        var module = try ir.Module.parse(allocator, input);
        defer module.deinit();
        try module.verify();
        var machine = try @import("../../../compilation.zig").select(allocator, "x86_64-unknown-linux-gnu", module.functions.items[0], .{ .generic_cfg_selector = true });
        defer machine.deinit(allocator);
        const bytes = try encoding.encodeFunction(allocator, machine);
        defer allocator.free(bytes);
        const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(mapping);
        @memcpy(mapping, bytes);
        const shift: *const fn (u64, u8) callconv(.c) u64 = @ptrCast(mapping.ptr);
        for ([_]u64{ 0, 1, 0x7fff_ffff_ffff_ffff, 0x8000_0000_0000_0000, 0xffff_ffff_ffff_ffed }) |value| {
            for ([_]u8{ 0, 1, 7, 15, 16, 31, 0xff }) |raw_count| {
                const count: u6 = @intCast(raw_count & 15);
                const expected: u64 = switch (op) {
                    .shl => value << count,
                    .lshr => value >> count,
                    .ashr => @bitCast(@as(i64, @bitCast(value)) >> count),
                    else => unreachable,
                };
                try std.testing.expectEqual(expected, shift(value, raw_count));
            }
        }
    }
}

test "generic cfg selector exact ei binary and shift preserve a current accumulator lhs" {
    const input =
        \\define double @exact(ptr readonly %input, i64 %bits) {
        \\entry:
        \\  %tag = trunc i64 %bits to i16
        \\  switch i16 %tag, label %fallback [
        \\    i16 0, label %case0
        \\    i16 1, label %case1
        \\    i16 2, label %case2
        \\    i16 3, label %case3
        \\    i16 4, label %case4
        \\  ]
        \\case0:
        \\  ret double 0.000000e+00
        \\case1:
        \\  ret double 0.000000e+00
        \\case2:
        \\  ret double 0.000000e+00
        \\case3:
        \\  ret double 0.000000e+00
        \\case4:
        \\  ret double 0.000000e+00
        \\fallback:
        \\  ret double 0.000000e+00
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try std.testing.expect(stage2_planning.isExactEiScalarFamily(module.functions.items[0]));

    inline for (.{
        .{ ir.BinaryOp.@"or", @as(u16, 55), x86_64_machine.Instruction{ .binary_arg_rax = .{ .op = .@"or", .reg = .rcx } } },
        .{ ir.BinaryOp.shl, @as(u16, 56), x86_64_machine.Instruction.shl_rax_cl },
    }) |case| {
        var machine = MachineFunction.init("dead-rax-exact-ei", .{ .int = case[1] });
        defer machine.deinit(std.testing.allocator);
        var plan = try allocateSelectorIntervals(std.testing.allocator, &.{
            .{ .name = "source", .class = .gpr64, .bits = case[1], .start = 0, .end = 1 },
            .{ .name = "amount", .class = .gpr64, .bits = case[1], .start = 0, .end = 1 },
        });
        defer plan.deinit();
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.function = &module.functions.items[0];
        selector.allocation_plan = &plan;
        selector.current_position = 1;
        selector.stack_frame_bytes = stage2SpillReservedBytes();
        try selector_state.bindValueLoc(&selector, "source", .rax);
        try selector_state.bindValueLoc(&selector, "amount", .{ .arg64 = .rsi });

        try std.testing.expect((try selector_scalar.lowerBinary(&selector, "result", .{
            .op = case[0],
            .ty = .{ .int = case[1] },
            .lhs = .{ .named = "source" },
            .rhs = .{ .named = "amount" },
        })) == null);
        try std.testing.expectEqual(
            ValueLoc{ .spill64 = .slot0 },
            selector_state.valueLoc(&selector, "source").?,
        );
        try std.testing.expectEqual(ValueLoc.rax, selector_state.valueLoc(&selector, "result").?);
        try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
            .{ .mov_arg64_arg = .{ .dst = .rcx, .src = .rsi } },
            .{ .spill_rax_rsp = .slot0 },
            .{ .reload_rsp_rax = .slot0 },
            case[2],
        }, machine.instructions.items);
    }
}

test "exact ei shift preserves the accepted current-use accumulator rhs spill" {
    const input =
        \\define double @exact(ptr readonly %input, i64 %bits) {
        \\entry:
        \\  %tag = trunc i64 %bits to i16
        \\  switch i16 %tag, label %fallback [
        \\    i16 0, label %case0
        \\    i16 1, label %case1
        \\    i16 2, label %case2
        \\    i16 3, label %case3
        \\    i16 4, label %case4
        \\  ]
        \\case0:
        \\  ret double 0.000000e+00
        \\case1:
        \\  ret double 0.000000e+00
        \\case2:
        \\  ret double 0.000000e+00
        \\case3:
        \\  ret double 0.000000e+00
        \\case4:
        \\  ret double 0.000000e+00
        \\fallback:
        \\  ret double 0.000000e+00
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try std.testing.expect(stage2_planning.isExactEiScalarFamily(module.functions.items[0]));

    // Frameless exact-EI shifts keep their original refusal and rollback
    // when a narrow final-use count would displace RAX.
    for ([_]u16{ 55, 56 }) |bits| {
        for ([_]ir.BinaryOp{ .ashr, .lshr, .shl }) |op| {
            var narrow_machine = MachineFunction.init("frameless-exact-ei", .{ .int = bits });
            defer narrow_machine.deinit(std.testing.allocator);
            var narrow_plan = try allocateSelectorIntervals(std.testing.allocator, &.{
                .{ .name = "lhs", .class = .gpr64, .bits = bits, .start = 0, .end = 4 },
                .{ .name = "amount", .class = .gpr64, .bits = bits, .start = 1, .end = 4 },
            });
            defer narrow_plan.deinit();
            var narrow = ComposedBlockSelector.init(std.testing.allocator, &narrow_machine);
            defer narrow.deinit();
            narrow.function = &module.functions.items[0];
            narrow.allocation_plan = &narrow_plan;
            narrow.current_position = 4;
            try selector_state.bindValueLoc(&narrow, "lhs", .{ .arg64 = .rdi });
            try selector_state.bindValueLoc(&narrow, "amount", .rax);
            try std.testing.expectError(error.UnsupportedCodegenValue, selector_scalar.lowerBinary(&narrow, "result", .{
                .op = op,
                .ty = .{ .int = bits },
                .lhs = .{ .named = "lhs" },
                .rhs = .{ .named = "amount" },
            }));
            try std.testing.expectEqual(@as(usize, 0), narrow_machine.instructions.items.len);
            try std.testing.expectEqual(ValueLoc{ .arg64 = .rdi }, selector_state.valueLoc(&narrow, "lhs").?);
            try std.testing.expectEqual(ValueLoc.rax, selector_state.valueLoc(&narrow, "amount").?);
            try std.testing.expect(selector_state.valueLoc(&narrow, "result") == null);
        }
    }

    var machine = MachineFunction.init("current-rhs-exact-ei", .{ .int = 56 });
    defer machine.deinit(std.testing.allocator);
    var plan = try allocateSelectorIntervals(std.testing.allocator, &.{
        .{ .name = "lhs", .class = .gpr64, .bits = 56, .start = 0, .end = 4 },
        .{ .name = "amount", .class = .gpr64, .bits = 56, .start = 1, .end = 4 },
    });
    defer plan.deinit();
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.function = &module.functions.items[0];
    selector.allocation_plan = &plan;
    selector.current_position = 4;
    selector.stack_frame_bytes = stage2SpillReservedBytes();
    try selector_state.bindValueLoc(&selector, "lhs", .{ .spill64 = .slot6 });
    try selector_state.bindValueLoc(&selector, "amount", .rax);

    try std.testing.expect((try selector_scalar.lowerBinary(&selector, "result", .{
        .op = .shl,
        .ty = .{ .int = 56 },
        .lhs = .{ .named = "lhs" },
        .rhs = .{ .named = "amount" },
    })) == null);
    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .mov_rax_to_arg = .rcx },
        .{ .spill_rax_rsp = .slot0 },
        .{ .reload_rsp_rax = .slot6 },
        .shl_rax_cl,
    }, machine.instructions.items);
}

test "generic cfg selector lshr64 avoids live scalar scratch values" {
    var machine = MachineFunction.init("lshr64-avoid-live-scalar", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("live", 10);
    try plan.interval_ends.put("source", 4);

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
    try plan.interval_ends.put("source", 4);

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
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("lhs", 1);
    try plan.interval_ends.put("rhs", 1);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
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
    var quotient_plan = try allocateSelectorIntervals(std.testing.allocator, &.{
        .{ .name = "lhs", .class = .gpr32, .bits = 32, .start = 0, .end = 1 },
        .{ .name = "rhs", .class = .gpr32, .bits = 32, .start = 0, .end = 1 },
    });
    defer quotient_plan.deinit();
    try std.testing.expectEqual(
        PlannedValueAssignment{ .gpr32 = .rdi },
        quotient_plan.assignment("lhs").?,
    );
    try std.testing.expectEqual(
        PlannedValueAssignment{ .gpr32 = .rsi },
        quotient_plan.assignment("rhs").?,
    );
    var quotient_selector = ComposedBlockSelector.init(std.testing.allocator, &quotient_machine);
    defer quotient_selector.deinit();
    quotient_selector.allocation_plan = &quotient_plan;
    quotient_selector.current_position = 1;
    try std.testing.expectEqual(@as(usize, 0), quotient_selector.address_dependencies.count());
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
    var remainder_plan = try allocateSelectorIntervals(std.testing.allocator, &.{
        .{ .name = "lhs", .class = .gpr32, .bits = 32, .start = 0, .end = 1 },
        .{ .name = "rhs", .class = .gpr32, .bits = 32, .start = 0, .end = 1 },
    });
    defer remainder_plan.deinit();
    try std.testing.expectEqual(
        PlannedValueAssignment{ .gpr32 = .rdi },
        remainder_plan.assignment("lhs").?,
    );
    try std.testing.expectEqual(
        PlannedValueAssignment{ .gpr32 = .rsi },
        remainder_plan.assignment("rhs").?,
    );
    var remainder_selector = ComposedBlockSelector.init(std.testing.allocator, &remainder_machine);
    defer remainder_selector.deinit();
    remainder_selector.allocation_plan = &remainder_plan;
    remainder_selector.current_position = 1;
    try std.testing.expectEqual(@as(usize, 0), remainder_selector.address_dependencies.count());
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

test "accumulator-resident named i32 shifts preserve live sources and reuse final uses" {
    for ([_]bool{ false, true }) |live| {
        var machine = MachineFunction.init("shift-i32-accumulator-lhs", .{ .int = 32 });
        defer machine.deinit(std.testing.allocator);
        var plan = try allocateSelectorIntervals(std.testing.allocator, &.{
            .{ .name = "lhs", .class = .gpr32, .bits = 32, .start = 0, .end = if (live) 9 else 4 },
            .{ .name = "amount", .class = .gpr32, .bits = 32, .start = 1, .end = 4 },
        });
        defer plan.deinit();

        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.current_position = 4;
        selector.stack_frame_bytes = stage2SpillReservedBytes();
        try selector_state.bindValueLoc(&selector, "lhs", .eax);
        try selector_state.bindValueLoc(&selector, "amount", .{ .arg32 = .rsi });

        try std.testing.expect((try selector_scalar.lowerBinary(&selector, "result", .{
            .op = .shl,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "lhs" },
            .rhs = .{ .named = "amount" },
        })) == null);
        const expected: []const x86_64_machine.Instruction = if (live) &.{
            .{ .mov_arg_arg = .{ .dst = .rcx, .src = .rsi } },
            .{ .spill_eax_rsp = .slot0 },
            .{ .reload_rsp_eax = .slot0 },
            .shl_eax_cl,
        } else &.{
            .{ .mov_arg_arg = .{ .dst = .rcx, .src = .rsi } },
            .shl_eax_cl,
        };
        try std.testing.expectEqualSlices(x86_64_machine.Instruction, expected, machine.instructions.items);
        try std.testing.expectEqual(if (live) ValueLoc{ .spill64 = .slot0 } else ValueLoc.eax, selector_state.valueLoc(&selector, "lhs").?);
        try std.testing.expectEqual(ValueLoc.eax, selector_state.valueLoc(&selector, "result").?);
    }
}

test "accumulator-resident udiv lhs keeps accepted fixed-register stream" {
    var machine = MachineFunction.init("udiv-i32-accumulator-lhs", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    var plan = try allocateSelectorIntervals(std.testing.allocator, &.{
        .{ .name = "lhs", .class = .gpr32, .bits = 32, .start = 0, .end = 9 },
        .{ .name = "rhs", .class = .gpr32, .bits = 32, .start = 1, .end = 4 },
    });
    defer plan.deinit();
    try std.testing.expectEqual(
        PlannedValueAssignment{ .gpr32 = .rdi },
        plan.assignment("lhs").?,
    );
    try std.testing.expectEqual(
        PlannedValueAssignment{ .gpr32 = .rsi },
        plan.assignment("rhs").?,
    );

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 4;
    selector.stack_frame_bytes = stage2SpillReservedBytes();
    try std.testing.expectEqual(@as(usize, 0), selector.address_dependencies.count());
    try selector_state.bindValueLoc(&selector, "lhs", .eax);
    try selector_state.bindValueLoc(&selector, "rhs", .{ .arg32 = .rsi });

    try std.testing.expect((try selector_scalar.lowerBinary(&selector, "result", .{
        .op = .udiv,
        .ty = .{ .int = 32 },
        .lhs = .{ .named = "lhs" },
        .rhs = .{ .named = "rhs" },
    })) == null);
    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .mov_arg_arg = .{ .dst = .rcx, .src = .rsi } },
        .xor_edx_edx,
        .{ .div_arg32 = .rcx },
    }, machine.instructions.items);
    try std.testing.expectEqual(ValueLoc.eax, selector_state.valueLoc(&selector, "lhs").?);
    try std.testing.expectEqual(ValueLoc.eax, selector_state.valueLoc(&selector, "result").?);
}

test "named i32 multiply preserves the accepted accumulator-before-rhs order" {
    var machine = MachineFunction.init("mul-i32-preserve-order", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    var plan = try allocateSelectorIntervals(std.testing.allocator, &.{
        .{ .name = "live", .class = .gpr32, .bits = 32, .start = 0, .end = 9 },
        .{ .name = "lhs", .class = .gpr32, .bits = 32, .start = 1, .end = 4 },
        .{ .name = "rhs", .class = .gpr32, .bits = 32, .start = 2, .end = 4 },
    });
    defer plan.deinit();

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 4;
    selector.stack_frame_bytes = stage2SpillReservedBytes();
    try selector_state.bindValueLoc(&selector, "live", .eax);
    try selector_state.bindValueLoc(&selector, "lhs", .{ .spill64 = .slot2 });
    try selector_state.bindValueLoc(&selector, "rhs", .{ .spill64 = .slot3 });

    try std.testing.expect((try selector_scalar.lowerBinary(&selector, "result", .{
        .op = .mul,
        .ty = .{ .int = 32 },
        .lhs = .{ .named = "lhs" },
        .rhs = .{ .named = "rhs" },
    })) == null);
    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .mov_eax_to_arg = .rdi },
        .{ .reload_arg_rsp = .{ .reg = .rcx, .frame_index = .slot3 } },
        .{ .reload_rsp_eax = .slot2 },
        .{ .imul_eax_arg32 = .rcx },
    }, machine.instructions.items);
}

test "generic cfg selector lowers named i32 unsigned greater-than" {
    var machine = MachineFunction.init("ugt-i32-named", .{ .int = 1 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("lhs", 1);
    try plan.interval_ends.put("rhs", 1);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
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
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("value", 1);
    try plan.interval_ends.put("cmp", 2);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
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
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("value", 1);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
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
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try plan.interval_ends.put("value", 1);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
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
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try plan.interval_ends.put("lhs", 1);
        try plan.interval_ends.put("rhs", 1);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
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
        .{ .bits = 15, .samesign = false },
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
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try plan.interval_ends.put("lhs", 1);
        try plan.interval_ends.put("rhs", 1);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
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
        .{ .bits = 15, .samesign = false },
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
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("value", 1);
    try plan.interval_ends.put("cmp", 2);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
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
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try plan.interval_ends.put("value", 1);

        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
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
        var plan = try allocateSelectorIntervals(std.testing.allocator, &.{
            .{ .name = "value", .class = .gpr32, .bits = 16, .start = 0, .end = 1 },
            .{ .name = "amount", .class = .gpr32, .bits = 16, .start = 0, .end = 1 },
        });
        defer plan.deinit();

        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.current_position = 1;
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

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("amount", 0);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 0;
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

test "generic cfg selector lowers exact i16, i32, and i64 immediate-left variable shl" {
    inline for (.{ 16, 32, 64 }) |bits| {
        var machine = MachineFunction.init("variable-immediate-left-shl", .{ .int = bits });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try plan.interval_ends.put("amount", 0);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.current_position = 0;
        try selector_state.bindValueLoc(&selector, "amount", if (bits <= 32) .{ .arg32 = .rdi } else .{ .arg64 = .rdi });

        try std.testing.expect((try selector_scalar.lowerBinary(&selector, "result", .{
            .op = .shl,
            .ty = .{ .int = bits },
            .lhs = .{ .int = -1 },
            .rhs = .{ .named = "amount" },
        })) == null);
        try std.testing.expectEqual(if (bits <= 32) ValueLoc.eax else ValueLoc.rax, selector_state.valueLoc(&selector, "result").?);
        if (bits == 16) {
            try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
                .{ .mov_arg_arg = .{ .dst = .rcx, .src = .rdi } },
                .{ .mov_imm_eax = -1 },
                .shl_eax_cl,
                .{ .and_eax_imm32 = 0xffff },
            }, machine.instructions.items);
        } else if (bits == 32) {
            try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
                .{ .mov_arg_arg = .{ .dst = .rcx, .src = .rdi } },
                .{ .mov_imm_eax = -1 },
                .shl_eax_cl,
            }, machine.instructions.items);
        } else {
            try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
                .{ .mov_arg64_arg = .{ .dst = .rcx, .src = .rdi } },
                .{ .mov_imm_rax = -1 },
                .shl_rax_cl,
            }, machine.instructions.items);
        }
    }

    inline for (.{128}) |bits| {
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

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("value", 0);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 0;
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
        var plan = try allocateSelectorIntervals(std.testing.allocator, &.{
            .{ .name = "value", .class = .gpr32, .bits = 32, .start = 0, .end = 0 },
            .{ .name = "amount", .class = .gpr32, .bits = 32, .start = 0, .end = 0 },
        });
        defer plan.deinit();
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.current_position = 0;
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
        .{ .bits = 32, .lhs = .{ .named = "value" }, .rhs = .{ .int = -4 } },
        .{ .bits = 32, .lhs = .{ .named = "value" }, .rhs = .{ .int = 0 } },
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

test "generic cfg selector executes signed power of two division with live source" {
    const allocator = std.testing.allocator;
    for ([_]i32{ 4, 8, 16, 256, 1 << 30 }) |divisor| {
        const input = try std.fmt.allocPrint(allocator,
            \\define i32 @divide(i32 %value) {{
            \\entry:
            \\  %q = sdiv i32 %value, {}
            \\  %result = xor i32 %q, %value
            \\  ret i32 %result
            \\}}
        , .{divisor});
        defer allocator.free(input);
        var module = try ir.Module.parse(allocator, input);
        defer module.deinit();
        try module.verify();
        var machine = MachineFunction.init("divide", .{ .int = 32 });
        defer machine.deinit(allocator);
        try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(allocator, &machine, module.functions.items[0]));
        try x86_64_verify.verifyFunction(machine);
        const bytes = try encoding.encodeFunction(allocator, machine);
        defer allocator.free(bytes);
        const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(mapping);
        @memcpy(mapping, bytes);
        const divide: *const fn (i32) callconv(.c) i32 = @ptrCast(mapping.ptr);
        for ([_]i32{ std.math.minInt(i32), -1025, -257, -17, -9, -8, -7, -1, 0, 1, 7, 8, 9, 17, 257, 1025, std.math.maxInt(i32) }) |value| {
            try std.testing.expectEqual(@divTrunc(value, divisor) ^ value, divide(value));
        }
    }
}

test "frameless pair widening uses a free planned pair without disturbing a live accumulator" {
    for ([_]bool{ false, true }) |occupied| {
        // This fixture checks the cast's result home; its surrounding function
        // leaves that value unused. Native canaries cover the return ABI.
        var machine = MachineFunction.init("planned-pair-widen", .void);
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try plan.interval_ends.put("source", 1);
        try plan.interval_ends.put("live", 10);
        try plan.interval_ends.put("result", 2);
        try plan.assignments.put("result", .{ .gpr128 = pair_b });
        try plan.forward_values.put("result", .{ .definition_position = 1, .metadata = .{ .class = .gpr128, .bits = 128 } });
        if (occupied) try plan.interval_ends.put("occupied", 10);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.current_position = 1;
        try selector_state.bindValueLoc(&selector, "source", .{ .arg64 = .rdi });
        try selector_state.bindValueLoc(&selector, "live", .rax);
        if (occupied) try selector_state.bindValueLoc(&selector, "occupied", .{ .scratch128 = pair_b });
        const cast = ir.CastInst{ .op = .zext, .value = .{ .named = "source" }, .from_ty = .{ .int = 64 }, .to_ty = .{ .int = 128 } };
        if (occupied) {
            try std.testing.expectError(error.UnsupportedCodegenValue, selector_scalar.lowerCast(&selector, "result", cast));
            try std.testing.expectEqual(ValueLoc{ .scratch128 = pair_b }, selector_state.valueLoc(&selector, "occupied").?);
            try std.testing.expect(selector_state.valueLoc(&selector, "result") == null);
        } else {
            try std.testing.expect((try selector_scalar.lowerCast(&selector, "result", cast)) == null);
            try std.testing.expectEqual(ValueLoc{ .scratch128 = pair_b }, selector_state.valueLoc(&selector, "result").?);
            try machine.instructions.append(std.testing.allocator, .ret);
            try x86_64_verify.verifyFunction(machine);
        }
        try std.testing.expectEqual(ValueLoc.rax, selector_state.valueLoc(&selector, "live").?);
        try std.testing.expectEqual(@as(usize, 0), selector.spill_slots.count());
        try std.testing.expectEqual(@as(usize, 0), selector.stack_frame_bytes);
    }
}

test "frameless pair OR preserves full accumulator aliases before lane scratch" {
    var machine = MachineFunction.init("pair-or-live-accumulator", .{ .int = 128 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("source", 1);
    try plan.interval_ends.put("live", 10);
    try plan.interval_ends.put("alias", 10);
    try plan.interval_ends.put("rhs", 1);
    try plan.interval_ends.put("result", 2);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 1;
    try selector_state.bindValueLoc(&selector, "source", .{ .arg128 = pair_a });
    try selector_state.bindValueLoc(&selector, "rhs", .{ .arg128 = pair_b });
    try selector_state.bindValueLoc(&selector, "live", .rax);
    try selector_state.bindValueLoc(&selector, "alias", .rax);
    try std.testing.expectEqual(@as(?selector_scalar.Diagnostic, null), try selector_scalar.lowerPairBinary(&selector, "result", .{ .op = .@"or", .ty = .{ .int = 128 }, .lhs = .{ .named = "source" }, .rhs = .{ .named = "rhs" } }));
    const home = selector_state.valueLoc(&selector, "live").?;
    try std.testing.expect(home == .scratch64);
    try std.testing.expect(selector_state.valueLoc(&selector, "alias").? == .scratch64);
    try std.testing.expect(selector_state.valueLoc(&selector, "result") != null);
    try std.testing.expectEqual(@as(usize, 0), selector.spill_slots.count());
    try std.testing.expectEqual(@as(usize, 0), selector.stack_frame_bytes);
    try machine.instructions.append(std.testing.allocator, .ret);
    try x86_64_verify.verifyFunction(machine);
}

test "i64 variable shifts preserve the pending RCX operand and surviving aliases" {
    const a = std.testing.allocator;
    const Lifetime = enum { last_use, surviving_aliases, used_again };
    for ([_]ir.BinaryOp{ .shl, .lshr, .ashr }) |op| {
        for ([_]ValueLoc{ .rax, .{ .spill64 = .slot6 } }) |count_home| {
            for (std.meta.tags(Lifetime)) |lifetime| {
                var machine = MachineFunction.init("wide_shift", .void);
                defer machine.deinit(a);
                var plan = SelectorAllocationPlan.init(a);
                defer plan.deinit();
                const end: usize = if (lifetime == .used_again) 8 else 4;
                try plan.interval_ends.put("lhs", end);
                try plan.interval_ends.put("count", end);
                var selector = ComposedBlockSelector.init(a, &machine);
                defer selector.deinit();
                selector.current_position = 4;
                selector.stack_frame_bytes = 56;
                selector.allocation_plan = &plan;
                const lhs_home = ValueLoc{ .scratch64 = .rcx };
                try selector_state.bindValueLoc(&selector, "lhs", lhs_home);
                try selector_state.bindValueLoc(&selector, "count", count_home);
                if (lifetime == .surviving_aliases) {
                    try plan.interval_ends.put("saved_lhs", 8);
                    try plan.interval_ends.put("saved_count", 8);
                    try selector_state.bindValueLoc(&selector, "saved_lhs", lhs_home);
                    try selector_state.bindValueLoc(&selector, "saved_count", count_home);
                }
                try machine.instructions.appendSlice(a, &.{
                    .sub_rsp_56,
                    .{ .mov_arg64_arg = .{ .dst = .rcx, .src = .rdi } },
                    if (count_home == .rax)
                        .{ .mov_arg_rax = .rsi }
                    else
                        .{ .spill_arg64_rsp = .{ .reg = .rsi, .frame_index = count_home.spill64 } },
                });
                try std.testing.expect((try selector_scalar.lowerBinary(&selector, "answer", .{
                    .op = op,
                    .ty = .{ .int = 64 },
                    .lhs = .{ .named = "lhs" },
                    .rhs = .{ .named = "count" },
                })) == null);
                try std.testing.expectEqual(ValueLoc.rax, selector_state.valueLoc(&selector, "answer").?);
                try machine.instructions.append(a, .{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdx, .offset = 8 } });
                if (lifetime != .last_use) {
                    selector.current_position += 1;
                    const saved = if (lifetime == .surviving_aliases)
                        [2][]const u8{ "saved_lhs", "saved_count" }
                    else
                        [2][]const u8{ "lhs", "count" };
                    for (saved, [_]u8{ 16, 24 }) |name, offset| {
                        try selector_state.emitValueIntoScratch(&selector, .{ .named = name }, .rdi, 64);
                        try machine.instructions.append(a, .{ .store_arg64_arg_ptr_disp8 = .{ .ptr_reg = .rdx, .src_reg = .rdi, .offset = offset } });
                    }
                }
                try machine.instructions.appendSlice(a, &.{ .add_rsp_56, .ret });
                try x86_64_verify.verifyFunction(machine);
                const bytes = try encoding.encodeFunction(a, machine);
                defer a.free(bytes);
                const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
                defer std.posix.munmap(mapping);
                @memcpy(mapping, bytes);
                const shift: *const fn (u64, u64, *[5]u64) callconv(.c) void = @ptrCast(mapping.ptr);
                for ([_]u64{ 1, 0x8000_0000_0000_0000, 0xfedc_ba98_7654_3210 }) |value| {
                    for ([_]u6{ 0, 1, 17, 63 }) |count| {
                        const expected: u64 = switch (op) {
                            .shl => value << count,
                            .lshr => value >> count,
                            .ashr => @bitCast(@as(i64, @bitCast(value)) >> count),
                            else => unreachable,
                        };
                        const guard = 0xa5c3_169b_4ef0_872d;
                        var actual = [5]u64{ guard, guard, guard, guard, guard };
                        shift(value, count, &actual);
                        try std.testing.expectEqual([5]u64{
                            guard,                                       expected,
                            if (lifetime == .last_use) guard else value, if (lifetime == .last_use) guard else count,
                            guard,
                        }, actual);
                    }
                }
            }
        }
    }
}
