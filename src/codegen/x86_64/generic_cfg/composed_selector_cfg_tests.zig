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

test "generic cfg selector executes framed backward phi edges from stable homes" {
    const input =
        \\define i32 @backward_phi(i32 %value, i32 %flag) {
        \\entry:
        \\  %slot = alloca double, align 8
        \\  store double 0.000000e+00, ptr %slot, align 8
        \\  %condition = icmp ne i32 %flag, 0
        \\  br i1 %condition, label %pred, label %other
        \\merge:
        \\  %merged = phi i32 [ %incremented, %pred ], [ %value, %other ]
        \\  %result = add i32 %merged, 100
        \\  ret i32 %result
        \\pred:
        \\  %incremented = add i32 %value, 1
        \\  br label %merge
        \\other:
        \\  br label %merge
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = MachineFunction.init("backward_phi", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    const selection = try impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]);
    switch (selection) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("backward phi diagnostic={s}\n", .{diagnostic.detail()});
            return error.TestUnexpectedResult;
        },
    }
    try x86_64_verify.verifyFunction(machine);
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const backward_phi: *const fn (u32, u32) callconv(.c) u32 = @ptrCast(mapping.ptr);
    try std.testing.expectEqual(@as(u32, 107), backward_phi(7, 0));
    try std.testing.expectEqual(@as(u32, 108), backward_phi(7, 1));
    try std.testing.expectEqual(@as(u32, 100), backward_phi(0, 0));
    try std.testing.expectEqual(@as(u32, 101), backward_phi(0, 1));
}

test "generic cfg selector stabilizes shared conditional phi sources before branching" {
    const input =
        \\define double @conditional_phi(double %value, i32 %flag) {
        \\entry:
        \\  %slot = alloca double, align 8
        \\  store double 0.000000e+00, ptr %slot, align 8
        \\  %updated = fmul double %value, 2.000000e+00
        \\  %condition = icmp ne i32 %flag, 0
        \\  br i1 %condition, label %on_true, label %on_false
        \\on_true:
        \\  %true_value = phi double [ %updated, %entry ]
        \\  ret double %true_value
        \\on_false:
        \\  %false_value = phi double [ %updated, %entry ]
        \\  %result = fmul double %false_value, 4.000000e+00
        \\  ret double %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = MachineFunction.init("conditional_phi", .double);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));
    try x86_64_verify.verifyFunction(machine);
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const conditional_phi: *const fn (f64, i32) callconv(.c) f64 = @ptrCast(mapping.ptr);

    try std.testing.expectEqual(@as(u64, @bitCast(@as(f64, 6.0))), @as(u64, @bitCast(conditional_phi(3.0, 1))));
    try std.testing.expectEqual(@as(u64, @bitCast(@as(f64, 24.0))), @as(u64, @bitCast(conditional_phi(3.0, 0))));
    try std.testing.expectEqual(@as(u64, @bitCast(@as(f64, -5.0))), @as(u64, @bitCast(conditional_phi(-2.5, 1))));
    try std.testing.expectEqual(@as(u64, @bitCast(@as(f64, -20.0))), @as(u64, @bitCast(conditional_phi(-2.5, 0))));
}

test "composed selector preserves scalar FP select values exactly" {
    const input =
        \\define half @select_f16(i32 %flag, half %on_true, half %on_false) {
        \\entry:
        \\  %cond = icmp ne i32 %flag, 0
        \\  %selected = select i1 %cond, half %on_true, half %on_false
        \\  ret half %selected
        \\}
        \\define float @select_f32(i32 %flag, float %on_true, float %on_false) {
        \\entry:
        \\  %cond = icmp ne i32 %flag, 0
        \\  %selected = select i1 %cond, float %on_true, float %on_false
        \\  ret float %selected
        \\}
        \\define double @select_f64(i32 %flag, double %on_true, double %on_false) {
        \\entry:
        \\  %cond = icmp ne i32 %flag, 0
        \\  %selected = select i1 %cond, double %on_true, double %on_false
        \\  ret double %selected
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    for (module.functions.items, 0..) |function, index| {
        var machine = MachineFunction.init(function.name, function.ret_ty);
        defer machine.deinit(std.testing.allocator);
        try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, function));
        try x86_64_verify.verifyFunction(machine);

        const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
        defer std.testing.allocator.free(bytes);
        const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(mapping);
        @memcpy(mapping, bytes);
        if (index == 0) {
            const select: *const fn (u32, f16, f16) callconv(.c) f16 = @ptrCast(mapping.ptr);
            const true_bits: u16 = 0x7e45;
            const false_bits: u16 = 0x8000;
            try std.testing.expectEqual(true_bits, @as(u16, @bitCast(select(1, @bitCast(true_bits), @bitCast(false_bits)))));
            try std.testing.expectEqual(false_bits, @as(u16, @bitCast(select(0, @bitCast(true_bits), @bitCast(false_bits)))));
        } else if (index == 1) {
            const select: *const fn (u32, f32, f32) callconv(.c) f32 = @ptrCast(mapping.ptr);
            const true_bits: u32 = 0x7fc1_2345;
            const false_bits: u32 = 0x8000_0000;
            try std.testing.expectEqual(true_bits, @as(u32, @bitCast(select(1, @bitCast(true_bits), @bitCast(false_bits)))));
            try std.testing.expectEqual(false_bits, @as(u32, @bitCast(select(0, @bitCast(true_bits), @bitCast(false_bits)))));
        } else {
            const select: *const fn (u32, f64, f64) callconv(.c) f64 = @ptrCast(mapping.ptr);
            const true_bits: u64 = 0xfff8_1234_5678_9abc;
            const false_bits: u64 = 0x0000_0000_0000_0000;
            try std.testing.expectEqual(true_bits, @as(u64, @bitCast(select(1, @bitCast(true_bits), @bitCast(false_bits)))));
            try std.testing.expectEqual(false_bits, @as(u64, @bitCast(select(0, @bitCast(true_bits), @bitCast(false_bits)))));
        }
    }
}

test "composed selector executes exact i64 immediate select values" {
    const input =
        \\define i64 @select_i64_immediate(i32 %flag) {
        \\entry:
        \\  %condition = icmp ne i32 %flag, 0
        \\  %selected = select i1 %condition, i64 -9223372036854775808, i64 9223372036854775807
        \\  ret i64 %selected
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = MachineFunction.init("select_i64_immediate", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));
    try x86_64_verify.verifyFunction(machine);

    var saw_min = false;
    var saw_max = false;
    for (machine.instructions.items) |instruction| switch (instruction) {
        .mov_imm_rax => |value| {
            saw_min = saw_min or value == std.math.minInt(i64);
            saw_max = saw_max or value == std.math.maxInt(i64);
        },
        else => {},
    };
    try std.testing.expect(saw_min and saw_max);

    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const select: *const fn (u32) callconv(.c) i64 = @ptrCast(mapping.ptr);
    try std.testing.expectEqual(std.math.maxInt(i64), select(0));
    try std.testing.expectEqual(std.math.minInt(i64), select(1));
    try std.testing.expectEqual(std.math.minInt(i64), select(std.math.maxInt(u32)));
}

test "composed selector keeps unsupported immediate select widths fail closed" {
    const input =
        \\define i128 @select_i128_immediate(i32 %flag) {
        \\entry:
        \\  %condition = icmp ne i32 %flag, 0
        \\  %selected = select i1 %condition, i128 1, i128 2
        \\  ret i128 %selected
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = MachineFunction.init("select_i128_immediate", .{ .int = 128 });
    defer machine.deinit(std.testing.allocator);
    const diagnostic = switch (try impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0])) {
        .selected => return error.TestUnexpectedResult,
        .unsupported => |diagnostic| diagnostic,
    };
    try std.testing.expectEqualStrings("composed-block-select-width", diagnostic.detail());
}

test "composed selector materializes exact half literals in selects" {
    const input =
        \\define half @select_negative_one(i32 %flag, half %value) {
        \\entry:
        \\  %cond = icmp ne i32 %flag, 0
        \\  %selected = select i1 %cond, half %value, half 0xHBC00
        \\  ret half %selected
        \\}
        \\define half @select_positive_one(i32 %flag, half %value) {
        \\entry:
        \\  %cond = icmp ne i32 %flag, 0
        \\  %selected = select i1 %cond, half %value, half 0xH3C00
        \\  ret half %selected
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    for (module.functions.items, 0..) |function, index| {
        var machine = MachineFunction.init(function.name, .half);
        defer machine.deinit(std.testing.allocator);
        try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, function));
        try x86_64_verify.verifyFunction(machine);
        const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
        defer std.testing.allocator.free(bytes);
        const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(mapping);
        @memcpy(mapping, bytes);
        const select: *const fn (u32, f16) callconv(.c) f16 = @ptrCast(mapping.ptr);
        const payload: u16 = 0x7e45;
        try std.testing.expectEqual(payload, @as(u16, @bitCast(select(1, @bitCast(payload)))));
        try std.testing.expectEqual(if (index == 0) @as(u16, 0xbc00) else 0x3c00, @as(u16, @bitCast(select(0, @bitCast(payload)))));
    }
}

test "composed selector carries scalar FP phi values around loops" {
    const input =
        \\define float @phi_f32(i32 %count, float %first, float %second) {
        \\entry:
        \\  br label %loop
        \\loop:
        \\  %index = phi i32 [ 0, %entry ], [ %next, %loop ]
        \\  %left = phi float [ %first, %entry ], [ %right, %loop ]
        \\  %right = phi float [ %second, %entry ], [ %left, %loop ]
        \\  %next = add i32 %index, 1
        \\  %again = icmp ult i32 %next, %count
        \\  br i1 %again, label %loop, label %exit
        \\exit:
        \\  ret float %left
        \\}
        \\define double @phi_f64(i32 %count, double %first) {
        \\entry:
        \\  br label %loop
        \\loop:
        \\  %index = phi i32 [ 0, %entry ], [ %next, %loop ]
        \\  %value = phi double [ %first, %entry ], [ 0x8000000000000000, %loop ]
        \\  %next = add i32 %index, 1
        \\  %again = icmp ult i32 %next, %count
        \\  br i1 %again, label %loop, label %exit
        \\exit:
        \\  ret double %value
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    for (module.functions.items, 0..) |function, index| {
        var machine = MachineFunction.init(function.name, function.ret_ty);
        defer machine.deinit(std.testing.allocator);
        try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, function));
        try x86_64_verify.verifyFunction(machine);

        const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
        defer std.testing.allocator.free(bytes);
        const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(mapping);
        @memcpy(mapping, bytes);
        if (index == 0) {
            const phi: *const fn (u32, f32, f32) callconv(.c) f32 = @ptrCast(mapping.ptr);
            const first: u32 = 0x7fc1_2345;
            const second: u32 = 0x8000_0000;
            try std.testing.expectEqual(first, @as(u32, @bitCast(phi(1, @bitCast(first), @bitCast(second)))));
            try std.testing.expectEqual(second, @as(u32, @bitCast(phi(2, @bitCast(first), @bitCast(second)))));
            try std.testing.expectEqual(first, @as(u32, @bitCast(phi(3, @bitCast(first), @bitCast(second)))));
        } else {
            const phi: *const fn (u32, f64) callconv(.c) f64 = @ptrCast(mapping.ptr);
            const first: u64 = 0x7ff8_1234_5678_9abc;
            try std.testing.expectEqual(first, @as(u64, @bitCast(phi(1, @bitCast(first)))));
            try std.testing.expectEqual(@as(u64, 0x8000_0000_0000_0000), @as(u64, @bitCast(phi(2, @bitCast(first)))));
        }
    }
}

test "composed selector executes crossed fully defined f64x2 phis through pair spills" {
    const input =
        \\define { double, double } @crossed_phi(i32 %count, double %a, double %b, double %c, double %d) {
        \\entry:
        \\  %left0 = insertelement <2 x double> poison, double %a, i64 0
        \\  %left1 = insertelement <2 x double> %left0, double %b, i64 1
        \\  %right0 = insertelement <2 x double> poison, double %c, i64 0
        \\  %right1 = insertelement <2 x double> %right0, double %d, i64 1
        \\  br label %loop
        \\loop:
        \\  %index = phi i32 [ 0, %entry ], [ %next, %loop ]
        \\  %left = phi <2 x double> [ %left1, %entry ], [ %right, %loop ]
        \\  %right = phi <2 x double> [ %right1, %entry ], [ %left, %loop ]
        \\  %next = add i32 %index, 1
        \\  %again = icmp ult i32 %next, %count
        \\  br i1 %again, label %loop, label %exit
        \\exit:
        \\  %low = extractelement <2 x double> %left, i64 0
        \\  %high = extractelement <2 x double> %left, i64 1
        \\  %result0 = insertvalue { double, double } poison, double %low, 0
        \\  %result1 = insertvalue { double, double } %result0, double %high, 1
        \\  ret { double, double } %result1
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = MachineFunction.init("crossed_phi", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);
    const selection = try impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]);
    switch (selection) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("crossed f64x2 phi diagnostic={s}/{s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestUnexpectedResult;
        },
    }
    try x86_64_verify.verifyFunction(machine);

    var vector_spills: usize = 0;
    var vector_reloads: usize = 0;
    for (machine.instructions.items) |instruction| switch (instruction) {
        .spill_xmm128_rsp => vector_spills += 1,
        .reload_xmm128_rsp => vector_reloads += 1,
        else => {},
    };
    try std.testing.expect(vector_spills >= 2);
    try std.testing.expect(vector_reloads >= 2);

    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const DoublePair = extern struct { low: f64, high: f64 };
    const crossed: *const fn (u32, f64, f64, f64, f64) callconv(.c) DoublePair = @ptrCast(mapping.ptr);

    const left = [2]u64{ 0x7ff8_1234_5678_9abc, 0x8000_0000_0000_0001 };
    const right = [2]u64{ 0xfff0_0000_0000_0000, 0x000f_ffff_ffff_ffff };
    const output1 = crossed(1, @bitCast(left[0]), @bitCast(left[1]), @bitCast(right[0]), @bitCast(right[1]));
    try std.testing.expectEqual(left, [2]u64{ @bitCast(output1.low), @bitCast(output1.high) });
    const output2 = crossed(2, @bitCast(left[0]), @bitCast(left[1]), @bitCast(right[0]), @bitCast(right[1]));
    try std.testing.expectEqual(right, [2]u64{ @bitCast(output2.low), @bitCast(output2.high) });
    const output3 = crossed(3, @bitCast(left[0]), @bitCast(left[1]), @bitCast(right[0]), @bitCast(right[1]));
    try std.testing.expectEqual(left, [2]u64{ @bitCast(output3.low), @bitCast(output3.high) });
}

test "generic cfg selector preserves equal and overlapping f64x2 phi locations" {
    const shape = selector_types.VectorShape.f64x2(0b11);
    var machine = MachineFunction.init("f64x2-phi-locations", .void);
    defer machine.deinit(std.testing.allocator);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.stack_frame_bytes = 32;

    const same: ValueLoc = .{ .xmm = .{ .reg = .xmm2, .bits = 128, .shape = .{ .vector = shape } } };
    try selector_state.bindValueLoc(&selector, "same", same);
    try std.testing.expect((try selector_cfg.emitValueIntoLoc(&selector, .{ .named = "same" }, same, "same-result", 128)) == null);
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);

    const source: ValueLoc = .{ .spill_vector = .{ .frames = .{ .lo = .slot0, .hi = .slot2 }, .shape = shape } };
    const destination: ValueLoc = .{ .spill_vector = .{ .frames = .{ .lo = .slot2, .hi = .slot4 }, .shape = shape } };
    try selector_state.bindValueLoc(&selector, "spilled", source);
    try std.testing.expect((try selector_cfg.emitValueIntoLoc(&selector, .{ .named = "spilled" }, destination, "spill-result", 128)) == null);
    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .reload_xmm128_rsp = .{ .frame_index = .slot0, .reg = .xmm0 } },
        .{ .spill_xmm128_rsp = .{ .frame_index = .slot2, .reg = .xmm0 } },
    }, machine.instructions.items);
}

test "composed selector preserves a duplicated f64x2 phi source on either selected edge" {
    const input =
        \\define { double, double } @duplicate_phi(i32 %flag, double %low, double %high) {
        \\entry:
        \\  %v0 = insertelement <2 x double> poison, double %low, i64 0
        \\  %v1 = insertelement <2 x double> %v0, double %high, i64 1
        \\  %condition = icmp ne i32 %flag, 0
        \\  br i1 %condition, label %left, label %right
        \\left:
        \\  br label %merge
        \\right:
        \\  br label %merge
        \\merge:
        \\  %joined = phi <2 x double> [ %v1, %left ], [ %v1, %right ]
        \\  %lane0 = extractelement <2 x double> %joined, i64 0
        \\  %lane1 = extractelement <2 x double> %joined, i64 1
        \\  %result0 = insertvalue { double, double } poison, double %lane0, 0
        \\  %result1 = insertvalue { double, double } %result0, double %lane1, 1
        \\  ret { double, double } %result1
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = MachineFunction.init("duplicate_phi", module.functions.items[0].ret_ty);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));
    try x86_64_verify.verifyFunction(machine);
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const DoublePair = extern struct { low: f64, high: f64 };
    const duplicate: *const fn (u32, f64, f64) callconv(.c) DoublePair = @ptrCast(mapping.ptr);
    const expected = [2]u64{ 0x7ff0_0000_0000_0042, 0x8000_0000_0000_0000 };
    inline for (.{ @as(u32, 0), @as(u32, 1) }) |flag| {
        const result = duplicate(flag, @bitCast(expected[0]), @bitCast(expected[1]));
        try std.testing.expectEqual(expected, [2]u64{ @bitCast(result.low), @bitCast(result.high) });
    }
}

test "composed selector keeps excluded vector phis fail closed" {
    const input =
        \\define double @partial_f64x2_phi(double %value) {
        \\entry:
        \\  %partial = insertelement <2 x double> poison, double %value, i64 0
        \\  br label %merge
        \\merge:
        \\  %vector = phi <2 x double> [ %partial, %entry ]
        \\  %lane = extractelement <2 x double> %vector, i64 0
        \\  ret double %lane
        \\}
        \\define float @f32x2_phi(float %a, float %b) {
        \\entry:
        \\  %v0 = insertelement <2 x float> poison, float %a, i64 0
        \\  %v1 = insertelement <2 x float> %v0, float %b, i64 1
        \\  br label %merge
        \\merge:
        \\  %vector = phi <2 x float> [ %v1, %entry ]
        \\  %lane = extractelement <2 x float> %vector, i64 0
        \\  ret float %lane
        \\}
        \\define i32 @mask_phi(double %a, double %b) {
        \\entry:
        \\  %v0 = insertelement <2 x double> poison, double %a, i64 0
        \\  %v1 = insertelement <2 x double> %v0, double %b, i64 1
        \\  %mask = fcmp oeq <2 x double> %v1, zeroinitializer
        \\  br label %merge
        \\merge:
        \\  %joined = phi <2 x i1> [ %mask, %entry ]
        \\  %lane = extractelement <2 x i1> %joined, i64 0
        \\  %result = zext i1 %lane to i32
        \\  ret i32 %result
        \\}
        \\define float @f32x4_phi(float %a, float %b, float %c, float %d) {
        \\entry:
        \\  %v0 = insertelement <4 x float> poison, float %a, i64 0
        \\  %v1 = insertelement <4 x float> %v0, float %b, i64 1
        \\  %v2 = insertelement <4 x float> %v1, float %c, i64 2
        \\  %v3 = insertelement <4 x float> %v2, float %d, i64 3
        \\  br label %merge
        \\merge:
        \\  %vector = phi <4 x float> [ %v3, %entry ]
        \\  %lane = extractelement <4 x float> %vector, i64 0
        \\  ret float %lane
        \\}
        \\define double @constant_f64x2_phi() {
        \\entry:
        \\  br label %merge
        \\merge:
        \\  %vector = phi <2 x double> [ zeroinitializer, %entry ]
        \\  %lane = extractelement <2 x double> %vector, i64 0
        \\  ret double %lane
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    for (module.functions.items) |function| {
        var machine = MachineFunction.init(function.name, function.ret_ty);
        defer machine.deinit(std.testing.allocator);
        const selection = try impl.tryLowerComposedCfg(std.testing.allocator, &machine, function);
        switch (selection) {
            .unsupported => {},
            .selected => return error.TestUnexpectedResult,
        }
    }

    const shape = selector_types.VectorShape.f64x2(0b11);
    var machine = MachineFunction.init("non-vector-phi-spill", .void);
    defer machine.deinit(std.testing.allocator);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.stack_frame_bytes = 16;
    try selector_state.bindValueLoc(&selector, "vector", .{ .xmm = .{ .reg = .xmm1, .bits = 128, .shape = .{ .vector = shape } } });
    try std.testing.expect((try selector_cfg.emitValueIntoLoc(&selector, .{ .named = "vector" }, .{ .spill64 = .slot0 }, "result", 128)) != null);
}

test "composed selector lowers typed i32 switches as compare chains" {
    const input =
        \\define i32 @masked_switch(i32 %input) {
        \\entry:
        \\  %key = and i32 %input, 3
        \\  switch i32 %key, label %impossible [
        \\    i32 0, label %case0
        \\    i32 1, label %case1
        \\    i32 2, label %case2
        \\    i32 3, label %case3
        \\  ]
        \\case0:
        \\  ret i32 11
        \\case1:
        \\  ret i32 13
        \\case2:
        \\  ret i32 17
        \\impossible:
        \\  unreachable
        \\case3:
        \\  ret i32 19
        \\}
        \\define i32 @ordinary_switch(i32 %input) {
        \\entry:
        \\  %narrow = trunc i32 %input to i16
        \\  switch i16 %narrow, label %default [
        \\    i16 -1, label %negative
        \\    i16 7, label %seven
        \\  ]
        \\negative:
        \\  ret i32 23
        \\seven:
        \\  ret i32 29
        \\default:
        \\  ret i32 31
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    for (module.functions.items, 0..) |function, function_index| {
        var machine = MachineFunction.init(function.name, function.ret_ty);
        defer machine.deinit(std.testing.allocator);
        try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, function));
        try x86_64_verify.verifyFunction(machine);

        const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
        defer std.testing.allocator.free(bytes);
        const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(mapping);
        @memcpy(mapping, bytes);
        if (function_index == 0) {
            const switch_fn: *const fn (i32) callconv(.c) i32 = @ptrCast(mapping.ptr);
            const expected = [_]i32{ 11, 13, 17, 19, 11, 13, 17, 19 };
            for (expected, 0..) |value, input_value| try std.testing.expectEqual(value, switch_fn(@intCast(input_value)));
            try std.testing.expectEqual(@as(i32, 19), switch_fn(-1));
        } else {
            const switch_fn: *const fn (i32) callconv(.c) i32 = @ptrCast(mapping.ptr);
            try std.testing.expectEqual(@as(i32, 23), switch_fn(-1));
            try std.testing.expectEqual(@as(i32, 29), switch_fn(7));
            try std.testing.expectEqual(@as(i32, 31), switch_fn(0));
            try std.testing.expectEqual(@as(i32, 31), switch_fn(99));
        }
    }
}

test "composed selector rejects an unproven unreachable switch default" {
    const input =
        \\define i32 @missing_mask_case(i32 %input) {
        \\entry:
        \\  %key = and i32 %input, 3
        \\  switch i32 %key, label %impossible [
        \\    i32 0, label %case0
        \\    i32 1, label %case1
        \\    i32 2, label %case2
        \\  ]
        \\case0:
        \\  ret i32 11
        \\case1:
        \\  ret i32 13
        \\case2:
        \\  ret i32 17
        \\impossible:
        \\  unreachable
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = MachineFunction.init("missing_mask_case", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    const selection = try impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]);
    switch (selection) {
        .unsupported => {},
        .selected => return error.TestUnexpectedResult,
    }
}

test "generic cfg selector preserves same-block FP results across framed phi edges" {
    const input =
        \\define float @choose_computed(float %value, i32 %pick) {
        \\entry:
        \\  %condition = icmp ne i32 %pick, 0
        \\  br i1 %condition, label %left, label %right
        \\left:
        \\  %left_value = fdiv float -1.000000e+00, %value
        \\  br label %merge
        \\right:
        \\  %right_value = fadd float %value, 2.000000e+00
        \\  br label %merge
        \\merge:
        \\  %result = phi float [ %left_value, %left ], [ %right_value, %right ]
        \\  ret float %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = MachineFunction.init("choose_computed", .float);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const choose: *const fn (f32, u32) callconv(.c) f32 = @ptrCast(mapping.ptr);

    const zero: f32 = @bitCast(@as(u32, 0));
    try std.testing.expectEqual(@as(u32, 0xff80_0000), @as(u32, @bitCast(choose(zero, 1))));
    try std.testing.expectEqual(@as(u32, 0x4000_0000), @as(u32, @bitCast(choose(zero, 0))));
}
