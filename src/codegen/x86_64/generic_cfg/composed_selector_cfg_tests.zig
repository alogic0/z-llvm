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

test "composed selector preserves scalar FP select values exactly" {
    const input =
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

test "composed selector keeps vector selects and phis fail closed" {
    const input =
        \\define float @vector_select(i32 %flag) {
        \\entry:
        \\  %cond = icmp ne i32 %flag, 0
        \\  %selected = select i1 %cond, <2 x float> <float 1.000000e+00, float 2.000000e+00>, <2 x float> zeroinitializer
        \\  %lane = extractelement <2 x float> %selected, i64 0
        \\  ret float %lane
        \\}
        \\define float @vector_phi() {
        \\entry:
        \\  br label %merge
        \\merge:
        \\  %value = phi <2 x float> [ zeroinitializer, %entry ]
        \\  %lane = extractelement <2 x float> %value, i64 0
        \\  ret float %lane
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
