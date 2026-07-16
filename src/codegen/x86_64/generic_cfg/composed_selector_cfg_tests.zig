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

test "exact EI scalar family requires readonly pointer and i64 width" {
    const input =
        \\define double @exact(ptr readonly %input, i64 %bits) {
        \\entry:
        \\  %key = trunc i64 %bits to i16
        \\  switch i16 %key, label %done [
        \\    i16 0, label %done
        \\    i16 1, label %done
        \\    i16 2, label %done
        \\    i16 3, label %done
        \\    i16 4, label %done
        \\  ]
        \\done:
        \\  ret double 0.000000e+00
        \\}
        \\define double @mutable(ptr %input, i64 %bits) {
        \\entry:
        \\  %key = trunc i64 %bits to i16
        \\  switch i16 %key, label %done [
        \\    i16 0, label %done
        \\    i16 1, label %done
        \\    i16 2, label %done
        \\    i16 3, label %done
        \\    i16 4, label %done
        \\  ]
        \\done:
        \\  ret double 0.000000e+00
        \\}
        \\define double @wrong_width(ptr readonly %input, i32 %bits) {
        \\entry:
        \\  %key = trunc i32 %bits to i16
        \\  switch i16 %key, label %done [
        \\    i16 0, label %done
        \\    i16 1, label %done
        \\    i16 2, label %done
        \\    i16 3, label %done
        \\    i16 4, label %done
        \\  ]
        \\done:
        \\  ret double 0.000000e+00
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    try std.testing.expect(stage2_planning.isExactEiScalarFamily(module.functions.items[0]));
    try std.testing.expect(!stage2_planning.isExactEiScalarFamily(module.functions.items[1]));
    try std.testing.expect(!stage2_planning.isExactEiScalarFamily(module.functions.items[2]));
}

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

test "generic cfg selector materializes exact i128 phi literals into pair spills" {
    var machine = MachineFunction.init("pair-phi-literal", .{ .int = 128 });
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.stack_frame_bytes = 16;

    const dst: ValueLoc = .{ .spill128 = .{ .lo = .slot0, .hi = .slot2 } };
    try std.testing.expect((try selector_cfg.emitValueIntoLoc(&selector, .{ .int = std.math.minInt(i128) }, dst, "result", 128)) == null);
    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .mov_imm_rax = 0 },
        .{ .spill_rax_rsp = .slot0 },
        .{ .mov_imm_rax = std.math.minInt(i64) },
        .{ .spill_rax_rsp = .slot2 },
    }, machine.instructions.items);

    const diagnostic = (try selector_cfg.emitValueIntoLoc(&selector, .zero_initializer, dst, "rejected", 128)).?;
    try std.testing.expectEqualStrings("stage2-phi-src", diagnostic.detail());
}

test "composed selector executes multiway and crossed i128 phi sources" {
    const input =
        \\define i128 @multiway_i128_phi(i32 %selector, i128 %named) {
        \\entry:
        \\  %is_zero = icmp eq i32 %selector, 0
        \\  br i1 %is_zero, label %zero, label %check_one
        \\zero:
        \\  br label %merge
        \\check_one:
        \\  %is_one = icmp eq i32 %selector, 1
        \\  br i1 %is_one, label %minus_one, label %check_two
        \\minus_one:
        \\  br label %merge
        \\check_two:
        \\  %is_two = icmp eq i32 %selector, 2
        \\  br i1 %is_two, label %named_value, label %minimum
        \\named_value:
        \\  br label %merge
        \\minimum:
        \\  br label %merge
        \\merge:
        \\  %result = phi i128 [ 0, %zero ], [ -1, %minus_one ], [ %named, %named_value ], [ -170141183460469231731687303715884105728, %minimum ]
        \\  ret i128 %result
        \\}
        \\define i128 @crossed_i128_phi(i32 %count, i128 %left_arg, i128 %right_arg) {
        \\entry:
        \\  br label %loop
        \\loop:
        \\  %index = phi i32 [ 0, %entry ], [ %next, %loop ]
        \\  %left = phi i128 [ %left_arg, %entry ], [ %right, %loop ]
        \\  %right = phi i128 [ %right_arg, %entry ], [ %left, %loop ]
        \\  %next = add i32 %index, 1
        \\  %again = icmp ult i32 %next, %count
        \\  br i1 %again, label %loop, label %exit
        \\exit:
        \\  ret i128 %left
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    for (module.functions.items, 0..) |function, index| {
        var machine = MachineFunction.init(function.name, function.ret_ty);
        defer machine.deinit(std.testing.allocator);
        const selection = try impl.tryLowerComposedCfg(std.testing.allocator, &machine, function);
        switch (selection) {
            .selected => {},
            .unsupported => |diagnostic| {
                std.debug.print("i128 phi diagnostic={s}/{s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
                return error.TestUnexpectedResult;
            },
        }
        try x86_64_verify.verifyFunction(machine);

        const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
        defer std.testing.allocator.free(bytes);
        const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(mapping);
        @memcpy(mapping, bytes);
        if (index == 0) {
            const multiway: *const fn (u32, i128) callconv(.c) i128 = @ptrCast(mapping.ptr);
            const named = @as(i128, 0x1234_5678_9abc_def0) << 64 | 0x0fed_cba9_8765_4321;
            try std.testing.expectEqual(@as(i128, 0), multiway(0, named));
            try std.testing.expectEqual(@as(i128, -1), multiway(1, named));
            try std.testing.expectEqual(named, multiway(2, named));
            try std.testing.expectEqual(std.math.minInt(i128), multiway(3, named));
            try std.testing.expectEqual(std.math.minInt(i128), multiway(std.math.maxInt(u32), named));
        } else {
            const crossed: *const fn (u32, i128, i128) callconv(.c) i128 = @ptrCast(mapping.ptr);
            const left = @as(i128, 0x1111_2222_3333_4444) << 64 | 0x5555_6666_7777_8888;
            const right: i128 = @bitCast(@as(u128, 0xaaaa_bbbb_cccc_dddd) << 64 | 0xeeee_ffff_0000_1111);
            try std.testing.expectEqual(left, crossed(1, left, right));
            try std.testing.expectEqual(right, crossed(2, left, right));
            try std.testing.expectEqual(left, crossed(3, left, right));
        }
    }
}

test "composed selector executes captured multiway scalar phi shapes" {
    const input =
        \\define double @seven_way_f64_phi(i32 %which, double %v0, double %v1, double %v2, double %v3, double %v4, double %v5, double %v6) {
        \\entry:
        \\  %is0 = icmp eq i32 %which, 0
        \\  br i1 %is0, label %p0, label %c1
        \\c1:
        \\  %is1 = icmp eq i32 %which, 1
        \\  br i1 %is1, label %p1, label %c2
        \\c2:
        \\  %is2 = icmp eq i32 %which, 2
        \\  br i1 %is2, label %p2, label %c3
        \\c3:
        \\  %is3 = icmp eq i32 %which, 3
        \\  br i1 %is3, label %p3, label %c4
        \\c4:
        \\  %is4 = icmp eq i32 %which, 4
        \\  br i1 %is4, label %p4, label %c5
        \\c5:
        \\  %is5 = icmp eq i32 %which, 5
        \\  br i1 %is5, label %p5, label %p6
        \\p0:
        \\  br label %merge
        \\p1:
        \\  br label %merge
        \\p2:
        \\  br label %merge
        \\p3:
        \\  br label %merge
        \\p4:
        \\  br label %merge
        \\p5:
        \\  br label %merge
        \\p6:
        \\  br label %merge
        \\merge:
        \\  %result = phi double [ %v0, %p0 ], [ %v1, %p1 ], [ %v2, %p2 ], [ %v3, %p3 ], [ %v4, %p4 ], [ %v5, %p5 ], [ %v6, %p6 ]
        \\  ret double %result
        \\}
        \\define i64 @paired_integer_phis(i32 %which, i32 %a32, i32 %b32, i64 %a64, i64 %b64) {
        \\entry:
        \\  %low = and i32 %which, 3
        \\  %is0 = icmp eq i32 %low, 0
        \\  br i1 %is0, label %p0, label %c1
        \\c1:
        \\  %is1 = icmp eq i32 %low, 1
        \\  br i1 %is1, label %p1, label %c2
        \\c2:
        \\  %is2 = icmp eq i32 %low, 2
        \\  br i1 %is2, label %p2, label %p3
        \\p0:
        \\  br label %merge
        \\p1:
        \\  br label %merge
        \\p2:
        \\  br label %merge
        \\p3:
        \\  br label %merge
        \\merge:
        \\  %small = phi i32 [ %a32, %p0 ], [ %b32, %p1 ], [ %a32, %p2 ], [ -1, %p3 ]
        \\  %large = phi i64 [ %a64, %p0 ], [ %a64, %p1 ], [ %b64, %p2 ], [ -1, %p3 ]
        \\  %extended = zext i32 %small to i64
        \\  %shifted = shl i64 %extended, 32
        \\  %result = xor i64 %shifted, %large
        \\  ret i64 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    for (module.functions.items, 0..) |function, index| {
        var machine = MachineFunction.init(function.name, function.ret_ty);
        defer machine.deinit(std.testing.allocator);
        const selection = try impl.tryLowerComposedCfg(std.testing.allocator, &machine, function);
        try std.testing.expectEqual(impl.SelectionResult.selected, selection);
        try x86_64_verify.verifyFunction(machine);

        const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
        defer std.testing.allocator.free(bytes);
        const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(mapping);
        @memcpy(mapping, bytes);
        if (index == 0) {
            const seven_way: *const fn (u32, f64, f64, f64, f64, f64, f64, f64) callconv(.c) f64 = @ptrCast(mapping.ptr);
            const values = [7]u64{
                0x0000_0000_0000_0000,
                0x8000_0000_0000_0000,
                0x0000_0000_0000_0001,
                0x3ff0_0000_0000_0000,
                0xfff0_0000_0000_0000,
                0x7ff8_1234_5678_9abc,
                0xfff0_0000_0000_0001,
            };
            for (0..7) |which| {
                const actual = seven_way(
                    @intCast(which),
                    @bitCast(values[0]),
                    @bitCast(values[1]),
                    @bitCast(values[2]),
                    @bitCast(values[3]),
                    @bitCast(values[4]),
                    @bitCast(values[5]),
                    @bitCast(values[6]),
                );
                try std.testing.expectEqual(values[which], @as(u64, @bitCast(actual)));
            }
            try std.testing.expectEqual(values[6], @as(u64, @bitCast(seven_way(
                std.math.maxInt(u32),
                @bitCast(values[0]),
                @bitCast(values[1]),
                @bitCast(values[2]),
                @bitCast(values[3]),
                @bitCast(values[4]),
                @bitCast(values[5]),
                @bitCast(values[6]),
            ))));
        } else {
            const paired: *const fn (u32, u32, u32, u64, u64) callconv(.c) u64 = @ptrCast(mapping.ptr);
            const a32: u32 = 0x1234_5678;
            const b32: u32 = 0xfedc_ba98;
            const a64: u64 = 0x0123_4567_89ab_cdef;
            const b64: u64 = 0xfedc_ba98_7654_3210;
            try std.testing.expectEqual((@as(u64, a32) << 32) ^ a64, paired(0, a32, b32, a64, b64));
            try std.testing.expectEqual((@as(u64, b32) << 32) ^ a64, paired(1, a32, b32, a64, b64));
            try std.testing.expectEqual((@as(u64, a32) << 32) ^ b64, paired(2, a32, b32, a64, b64));
            try std.testing.expectEqual(@as(u64, 0x0000_0000_ffff_ffff), paired(3, a32, b32, a64, b64));
        }
    }
}

test "composed selector executes reduced compare setcc test branch phi sequence" {
    const input =
        \\define i32 @compare_branch_phi(i32 %value) {
        \\entry:
        \\  %is_zero = icmp eq i32 %value, 0
        \\  br i1 %is_zero, label %zero, label %nonzero
        \\zero:
        \\  br label %merge
        \\nonzero:
        \\  br label %merge
        \\merge:
        \\  %result = phi i32 [ 7, %zero ], [ 9, %nonzero ]
        \\  ret i32 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const function = module.functions.items[0];
    var machine = MachineFunction.init(function.name, function.ret_ty);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(
        impl.SelectionResult.selected,
        try impl.tryLowerComposedCfg(std.testing.allocator, &machine, function),
    );
    try x86_64_verify.verifyFunction(machine);

    var sequence_index: usize = 0;
    for (machine.instructions.items) |instruction| {
        const tag = std.meta.activeTag(instruction);
        switch (sequence_index) {
            0 => {
                if (tag == .test_arg32) sequence_index = 1;
            },
            1 => {
                if (tag == .sete_eax) sequence_index = 2;
            },
            2 => {
                if (tag == .test_eax_eax) sequence_index = 3;
            },
            3 => {
                if (tag == .jne) sequence_index = 4;
            },
            else => break,
        }
    }
    try std.testing.expectEqual(@as(usize, 4), sequence_index);

    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const compare_branch_phi: *const fn (u32) callconv(.c) u32 = @ptrCast(mapping.ptr);
    try std.testing.expectEqual(@as(u32, 7), compare_branch_phi(0));
    try std.testing.expectEqual(@as(u32, 9), compare_branch_phi(1));
    try std.testing.expectEqual(@as(u32, 9), compare_branch_phi(std.math.maxInt(u32)));
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

test "composed selector keeps excluded phi forms fail closed" {
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
        \\define i64 @pointer_phi(i1 %condition, ptr %a, ptr %b) {
        \\entry:
        \\  br i1 %condition, label %left, label %right
        \\left:
        \\  br label %merge
        \\right:
        \\  br label %merge
        \\merge:
        \\  %joined = phi ptr [ %a, %left ], [ %b, %right ]
        \\  %result = ptrtoint ptr %joined to i64
        \\  ret i64 %result
        \\}
        \\define i64 @poison_phi(i1 %condition) {
        \\entry:
        \\  br i1 %condition, label %left, label %right
        \\left:
        \\  br label %merge
        \\right:
        \\  br label %merge
        \\merge:
        \\  %joined = phi i64 [ poison, %left ], [ undef, %right ]
        \\  ret i64 %joined
        \\}
        \\define double @nonzero_fp_constant_phi(i1 %condition) {
        \\entry:
        \\  br i1 %condition, label %left, label %right
        \\left:
        \\  br label %merge
        \\right:
        \\  br label %merge
        \\merge:
        \\  %joined = phi double [ 1.000000e+00, %left ], [ 2.000000e+00, %right ]
        \\  ret double %joined
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

test "composed selector executes exact EI entry switch phi edges" {
    const input =
        \\define half @choose_half(i32 %which, half %v1, half %v2, half %v3, half %v4, half %v5) {
        \\entry:
        \\  %key = trunc i32 %which to i16
        \\  switch i16 %key, label %default [
        \\    i16 0, label %merge
        \\    i16 1, label %case1
        \\    i16 2, label %case2
        \\    i16 3, label %case3
        \\    i16 4, label %case4
        \\  ]
        \\merge:
        \\  %result = phi half [ 0xH0000, %entry ], [ %v1, %case1 ], [ %v2, %case2 ], [ %v3, %case3 ], [ %v4, %case4 ], [ %v5, %default.exit ]
        \\  ret half %result
        \\case1:
        \\  br label %merge
        \\case2:
        \\  br label %merge
        \\case3:
        \\  br label %merge
        \\case4:
        \\  br label %merge
        \\default:
        \\  br label %default.exit
        \\default.exit:
        \\  br label %merge
        \\}
        \\define float @choose_float(i32 %which, float %v1, float %v2, float %v3, float %v4, float %v5) {
        \\entry:
        \\  %key = trunc i32 %which to i16
        \\  switch i16 %key, label %default [
        \\    i16 0, label %merge
        \\    i16 1, label %case1
        \\    i16 2, label %case2
        \\    i16 3, label %case3
        \\    i16 4, label %case4
        \\  ]
        \\merge:
        \\  %result = phi float [ 0.000000e+00, %entry ], [ %v1, %case1 ], [ %v2, %case2 ], [ %v3, %case3 ], [ %v4, %case4 ], [ %v5, %default.exit ]
        \\  ret float %result
        \\case1:
        \\  br label %merge
        \\case2:
        \\  br label %merge
        \\case3:
        \\  br label %merge
        \\case4:
        \\  br label %merge
        \\default:
        \\  br label %default.exit
        \\default.exit:
        \\  br label %merge
        \\}
        \\define double @choose_double(i32 %which, double %v1, double %v2, double %v3, double %v4, double %v5) {
        \\entry:
        \\  %key = trunc i32 %which to i16
        \\  switch i16 %key, label %default [
        \\    i16 0, label %merge
        \\    i16 1, label %case1
        \\    i16 2, label %case2
        \\    i16 3, label %case3
        \\    i16 4, label %case4
        \\  ]
        \\merge:
        \\  %result = phi double [ 0.000000e+00, %entry ], [ %v1, %case1 ], [ %v2, %case2 ], [ %v3, %case3 ], [ %v4, %case4 ], [ %v5, %default.exit ]
        \\  ret double %result
        \\case1:
        \\  br label %merge
        \\case2:
        \\  br label %merge
        \\case3:
        \\  br label %merge
        \\case4:
        \\  br label %merge
        \\default:
        \\  br label %default.exit
        \\default.exit:
        \\  br label %merge
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
        switch (function_index) {
            0 => {
                const switch_fn: *const fn (u32, f16, f16, f16, f16, f16) callconv(.c) f16 = @ptrCast(mapping.ptr);
                const values = [5]u16{ 0x8000, 0x0001, 0x7c00, 0x7e55, 0xfc00 };
                try std.testing.expectEqual(@as(u16, 0), @as(u16, @bitCast(switch_fn(0, @bitCast(values[0]), @bitCast(values[1]), @bitCast(values[2]), @bitCast(values[3]), @bitCast(values[4])))));
                for (values, 1..) |expected, which| {
                    const actual = switch_fn(@intCast(which), @bitCast(values[0]), @bitCast(values[1]), @bitCast(values[2]), @bitCast(values[3]), @bitCast(values[4]));
                    try std.testing.expectEqual(expected, @as(u16, @bitCast(actual)));
                }
                try std.testing.expectEqual(values[4], @as(u16, @bitCast(switch_fn(99, @bitCast(values[0]), @bitCast(values[1]), @bitCast(values[2]), @bitCast(values[3]), @bitCast(values[4])))));
            },
            1 => {
                const switch_fn: *const fn (u32, f32, f32, f32, f32, f32) callconv(.c) f32 = @ptrCast(mapping.ptr);
                const values = [5]u32{ 0x8000_0000, 0x0000_0001, 0x7f80_0000, 0x7fc1_2345, 0xff80_0000 };
                try std.testing.expectEqual(@as(u32, 0), @as(u32, @bitCast(switch_fn(0, @bitCast(values[0]), @bitCast(values[1]), @bitCast(values[2]), @bitCast(values[3]), @bitCast(values[4])))));
                for (values, 1..) |expected, which| {
                    const actual = switch_fn(@intCast(which), @bitCast(values[0]), @bitCast(values[1]), @bitCast(values[2]), @bitCast(values[3]), @bitCast(values[4]));
                    try std.testing.expectEqual(expected, @as(u32, @bitCast(actual)));
                }
                try std.testing.expectEqual(values[4], @as(u32, @bitCast(switch_fn(99, @bitCast(values[0]), @bitCast(values[1]), @bitCast(values[2]), @bitCast(values[3]), @bitCast(values[4])))));
            },
            2 => {
                const switch_fn: *const fn (u32, f64, f64, f64, f64, f64) callconv(.c) f64 = @ptrCast(mapping.ptr);
                const values = [5]u64{ 0x8000_0000_0000_0000, 0x0000_0000_0000_0001, 0x7ff0_0000_0000_0000, 0x7ff8_1234_5678_9abc, 0xfff0_0000_0000_0000 };
                try std.testing.expectEqual(@as(u64, 0), @as(u64, @bitCast(switch_fn(0, @bitCast(values[0]), @bitCast(values[1]), @bitCast(values[2]), @bitCast(values[3]), @bitCast(values[4])))));
                for (values, 1..) |expected, which| {
                    const actual = switch_fn(@intCast(which), @bitCast(values[0]), @bitCast(values[1]), @bitCast(values[2]), @bitCast(values[3]), @bitCast(values[4]));
                    try std.testing.expectEqual(expected, @as(u64, @bitCast(actual)));
                }
                try std.testing.expectEqual(values[4], @as(u64, @bitCast(switch_fn(99, @bitCast(values[0]), @bitCast(values[1]), @bitCast(values[2]), @bitCast(values[3]), @bitCast(values[4])))));
            },
            else => unreachable,
        }
    }
}

test "composed selector executes exact frexp switch phi edge" {
    const input =
        \\define void @frexp_edge(i64 %bits, i32 %subnormal, ptr %out_exp, ptr %out_bits) {
        \\entry:
        \\  %high = lshr i64 %bits, 52
        \\  %kind = trunc i64 %high to i11
        \\  switch i11 %kind, label %default [
        \\    i11 0, label %case_zero
        \\    i11 -1, label %join
        \\  ]
        \\case_zero:
        \\  %use_subnormal = icmp ne i32 %subnormal, 0
        \\  br i1 %use_subnormal, label %subnormal_path, label %join
        \\subnormal_path:
        \\  %sub_exp = add i32 %subnormal, -1023
        \\  %sub_bits = or i64 %bits, 4602678819172646912
        \\  br label %join
        \\default:
        \\  %default_exp = add i32 %subnormal, 17
        \\  %default_bits = xor i64 %bits, 4602678819172646912
        \\  br label %join
        \\join:
        \\  %exp = phi i32 [ %default_exp, %default ], [ %sub_exp, %subnormal_path ], [ 0, %case_zero ], [ 0, %entry ]
        \\  %result_bits = phi i64 [ %default_bits, %default ], [ %sub_bits, %subnormal_path ], [ %bits, %case_zero ], [ %bits, %entry ]
        \\  store i32 %exp, ptr %out_exp, align 4
        \\  store i64 %result_bits, ptr %out_bits, align 8
        \\  ret void
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = MachineFunction.init("frexp_edge", .void);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));
    try x86_64_verify.verifyFunction(machine);
    var saw_scalar_spill = false;
    for (machine.instructions.items) |instruction| switch (instruction) {
        .spill_arg64_rsp, .spill_rax_rsp => saw_scalar_spill = true,
        else => {},
    };
    try std.testing.expect(saw_scalar_spill);

    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const frexp_edge: *const fn (u64, u32, *u32, *u64) callconv(.c) void = @ptrCast(mapping.ptr);
    const Case = struct { bits: u64, subnormal: u32, exp: u32, result_bits: u64 };
    const cases = [_]Case{
        .{ .bits = 0, .subnormal = 0, .exp = 0, .result_bits = 0 },
        .{ .bits = 1, .subnormal = 1, .exp = @bitCast(@as(i32, -1022)), .result_bits = 0x3fe0_0000_0000_0001 },
        .{ .bits = 0x0010_0000_0000_0123, .subnormal = 2, .exp = 19, .result_bits = 0x3ff0_0000_0000_0123 },
        .{ .bits = 0x7ff0_0000_0000_0456, .subnormal = 3, .exp = 0, .result_bits = 0x7ff0_0000_0000_0456 },
    };
    for (cases) |case| {
        var exp: u32 = 0xdead_beef;
        var result_bits: u64 = 0xdead_beef_dead_beef;
        frexp_edge(case.bits, case.subnormal, &exp, &result_bits);
        try std.testing.expectEqual(case.exp, exp);
        try std.testing.expectEqual(case.result_bits, result_bits);
    }
}

test "composed selector keeps near-miss frexp switch phi edges fail closed" {
    const input =
        \\define i64 @wrong_width(i64 %bits) {
        \\entry:
        \\  %high = lshr i64 %bits, 52
        \\  %kind = trunc i64 %high to i12
        \\  switch i12 %kind, label %default [
        \\    i12 0, label %case_zero
        \\    i12 -1, label %join
        \\  ]
        \\case_zero:
        \\  br label %join
        \\default:
        \\  br label %join
        \\join:
        \\  %exp = phi i32 [ 1, %default ], [ 2, %case_zero ], [ 0, %entry ]
        \\  %result = phi i64 [ %bits, %default ], [ %bits, %case_zero ], [ %bits, %entry ]
        \\  ret i64 %result
        \\}
        \\define i64 @poison_source(i64 %bits) {
        \\entry:
        \\  %high = lshr i64 %bits, 52
        \\  %kind = trunc i64 %high to i11
        \\  switch i11 %kind, label %default [
        \\    i11 0, label %case_zero
        \\    i11 -1, label %join
        \\  ]
        \\case_zero:
        \\  br label %join
        \\subnormal:
        \\  br label %join
        \\default:
        \\  br label %join
        \\join:
        \\  %exp = phi i32 [ 1, %default ], [ 2, %subnormal ], [ 0, %case_zero ], [ 0, %entry ]
        \\  %result = phi i64 [ %bits, %default ], [ poison, %subnormal ], [ %bits, %case_zero ], [ %bits, %entry ]
        \\  ret i64 %result
        \\}
        \\define i64 @second_phi_target(i64 %bits) {
        \\entry:
        \\  %high = lshr i64 %bits, 52
        \\  %kind = trunc i64 %high to i11
        \\  switch i11 %kind, label %default [
        \\    i11 0, label %case_zero
        \\    i11 -1, label %join
        \\  ]
        \\case_zero:
        \\  %other = phi i64 [ %bits, %entry ]
        \\  br label %join
        \\subnormal:
        \\  br label %join
        \\default:
        \\  br label %join
        \\join:
        \\  %exp = phi i32 [ 1, %default ], [ 2, %subnormal ], [ 0, %case_zero ], [ 0, %entry ]
        \\  %result = phi i64 [ %bits, %default ], [ %bits, %subnormal ], [ %other, %case_zero ], [ %bits, %entry ]
        \\  ret i64 %result
        \\}
        \\define i64 @wrong_cases(i64 %bits) {
        \\entry:
        \\  %high = lshr i64 %bits, 52
        \\  %kind = trunc i64 %high to i11
        \\  switch i11 %kind, label %default [
        \\    i11 0, label %case_zero
        \\    i11 -2, label %join
        \\  ]
        \\case_zero:
        \\  br label %join
        \\subnormal:
        \\  br label %join
        \\default:
        \\  br label %join
        \\join:
        \\  %exp = phi i32 [ 1, %default ], [ 2, %subnormal ], [ 0, %case_zero ], [ 0, %entry ]
        \\  %result = phi i64 [ %bits, %default ], [ %bits, %subnormal ], [ %bits, %case_zero ], [ %bits, %entry ]
        \\  ret i64 %result
        \\}
        \\define i64 @wrong_phi_type(i64 %bits) {
        \\entry:
        \\  %high = lshr i64 %bits, 52
        \\  %kind = trunc i64 %high to i11
        \\  switch i11 %kind, label %default [
        \\    i11 0, label %case_zero
        \\    i11 -1, label %join
        \\  ]
        \\case_zero:
        \\  br label %join
        \\subnormal:
        \\  br label %join
        \\default:
        \\  br label %join
        \\join:
        \\  %exp = phi i16 [ 1, %default ], [ 2, %subnormal ], [ 0, %case_zero ], [ 0, %entry ]
        \\  %result = phi i64 [ %bits, %default ], [ %bits, %subnormal ], [ %bits, %case_zero ], [ %bits, %entry ]
        \\  ret i64 %result
        \\}
        \\define i64 @wrong_phi_count(i64 %bits) {
        \\entry:
        \\  %high = lshr i64 %bits, 52
        \\  %kind = trunc i64 %high to i11
        \\  switch i11 %kind, label %default [
        \\    i11 0, label %case_zero
        \\    i11 -1, label %join
        \\  ]
        \\case_zero:
        \\  br label %join
        \\subnormal:
        \\  br label %join
        \\default:
        \\  br label %join
        \\join:
        \\  %result = phi i64 [ %bits, %default ], [ %bits, %subnormal ], [ %bits, %case_zero ], [ %bits, %entry ]
        \\  ret i64 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    for (module.functions.items) |function| {
        var machine = MachineFunction.init(function.name, function.ret_ty);
        defer machine.deinit(std.testing.allocator);
        switch (try impl.tryLowerComposedCfg(std.testing.allocator, &machine, function)) {
            .unsupported => |diagnostic| try std.testing.expectEqualStrings("stage2-switch-phi-edge", diagnostic.detail()),
            .selected => return error.TestUnexpectedResult,
        }
    }
}

test "composed selector executes guarded i52 normalization family" {
    const input =
        \\declare i52 @llvm.ctlz.i52(i52, i1 immarg)
        \\define void @normalize_i52(i64 %raw, ptr %out_shifted, ptr %out_count, ptr %out_predicate, ptr %out_shift) {
        \\entry:
        \\  %zero64 = and i64 %raw, 0
        \\  %zero32 = trunc i64 %zero64 to i32
        \\  %guard_count = add i32 %zero32, 52
        \\  %fraction = trunc i64 %raw to i52
        \\  %is_zero = icmp eq i52 %fraction, 0
        \\  br i1 %is_zero, label %guard, label %nonzero
        \\guard:
        \\  store i64 %zero64, ptr %out_shifted, align 8
        \\  store i32 %guard_count, ptr %out_count, align 4
        \\  store i32 %zero32, ptr %out_predicate, align 4
        \\  store i32 %zero32, ptr %out_shift, align 4
        \\  br label %done
        \\nonzero:
        \\  %count = tail call range(i52 0, 53) i52 @llvm.ctlz.i52(i52 %fraction, i1 true)
        \\  %count6 = trunc nuw i52 %count to i6
        \\  %shift6 = add nuw i6 %count6, 1
        \\  %in_range = icmp ult i6 %count6, -13
        \\  %shift52 = zext i6 %shift6 to i52
        \\  %shifted52 = shl i52 %fraction, %shift52
        \\  %shifted64 = zext i52 %shifted52 to i64
        \\  %selected = select i1 %in_range, i64 %shifted64, i64 0
        \\  %count32 = trunc nuw nsw i52 %count to i32
        \\  %predicate32 = zext i1 %in_range to i32
        \\  %shift32 = zext i6 %shift6 to i32
        \\  store i64 %selected, ptr %out_shifted, align 8
        \\  store i32 %count32, ptr %out_count, align 4
        \\  store i32 %predicate32, ptr %out_predicate, align 4
        \\  store i32 %shift32, ptr %out_shift, align 4
        \\  br label %done
        \\done:
        \\  ret void
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = MachineFunction.init("normalize_i52", .void);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));
    try x86_64_verify.verifyFunction(machine);

    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const normalize: *const fn (u64, *u64, *u32, *u32, *u32) callconv(.c) void = @ptrCast(mapping.ptr);
    const Case = struct { raw: u64, shifted: u64, count: u32, predicate: u32, shift: u32 };
    const dense_cases = [_]Case{
        .{ .raw = 0, .shifted = 0, .count = 52, .predicate = 0, .shift = 0 },
        .{ .raw = 1, .shifted = 0, .count = 51, .predicate = 0, .shift = 52 },
        .{ .raw = 2, .shifted = 0, .count = 50, .predicate = 1, .shift = 51 },
        .{ .raw = 3, .shifted = 0x8000_0000_0000_0, .count = 50, .predicate = 1, .shift = 51 },
        .{ .raw = 0xaaaa_aaaa_aaaa_a, .shifted = 0x5555_5555_5555_4, .count = 0, .predicate = 1, .shift = 1 },
        .{ .raw = 0x5555_5555_5555_5, .shifted = 0x5555_5555_5555_4, .count = 1, .predicate = 1, .shift = 2 },
        .{ .raw = 0xffff_ffff_ffff_f, .shifted = 0xffff_ffff_ffff_e, .count = 0, .predicate = 1, .shift = 1 },
        .{ .raw = 0xf0f0_f0f0_f0f0_f, .shifted = 0xe1e1_e1e1_e1e1_e, .count = 0, .predicate = 1, .shift = 1 },
        .{ .raw = 0xfff0_0000_0000_0000, .shifted = 0, .count = 52, .predicate = 0, .shift = 0 },
        .{ .raw = 0xabc1_2345_6789_abcd, .shifted = 0x2345_6789_abcd_0, .count = 3, .predicate = 1, .shift = 4 },
    };
    for (dense_cases) |case| try expectI52Normalization(normalize, case.raw, case.shifted, case.count, case.predicate, case.shift);
    for (0..52) |bit| {
        const raw = @as(u64, 1) << @intCast(bit);
        const count: u32 = @intCast(51 - bit);
        try expectI52Normalization(normalize, raw, 0, count, @intFromBool(bit != 0), count + 1);
    }
}

fn expectI52Normalization(
    normalize: *const fn (u64, *u64, *u32, *u32, *u32) callconv(.c) void,
    raw: u64,
    expected_shifted: u64,
    expected_count: u32,
    expected_predicate: u32,
    expected_shift: u32,
) !void {
    var shifted: u64 = 0xdead_beef_dead_beef;
    var count: u32 = 0xdead_beef;
    var predicate: u32 = 0xdead_beef;
    var shift: u32 = 0xdead_beef;
    normalize(raw, &shifted, &count, &predicate, &shift);
    try std.testing.expectEqual(expected_shifted, shifted);
    try std.testing.expectEqual(expected_count, count);
    try std.testing.expectEqual(expected_predicate, predicate);
    try std.testing.expectEqual(expected_shift, shift);
}

test "composed selector keeps excluded i52 forms fail closed" {
    const input =
        \\declare i52 @llvm.ctlz.i52(i52, i1 immarg)
        \\define i64 @ctlz_false(i64 %raw) {
        \\entry:
        \\  %fraction = trunc i64 %raw to i52
        \\  %count = call range(i52 0, 53) i52 @llvm.ctlz.i52(i52 %fraction, i1 false)
        \\  %result = zext i52 %count to i64
        \\  ret i64 %result
        \\}
        \\define i64 @ctlz_wrong_range(i64 %raw) {
        \\entry:
        \\  %fraction = trunc i64 %raw to i52
        \\  %count = call range(i52 0, 52) i52 @llvm.ctlz.i52(i52 %fraction, i1 true)
        \\  %result = zext i52 %count to i64
        \\  ret i64 %result
        \\}
        \\define i64 @ctlz_nonliteral(i64 %raw, i1 %zero_is_poison) {
        \\entry:
        \\  %fraction = trunc i64 %raw to i52
        \\  %count = call range(i52 0, 53) i52 @llvm.ctlz.i52(i52 %fraction, i1 %zero_is_poison)
        \\  %result = zext i52 %count to i64
        \\  ret i64 %result
        \\}
        \\define i64 @ctlz_abi_attr(i64 %raw) {
        \\entry:
        \\  %fraction = trunc i64 %raw to i52
        \\  %count = call zeroext range(i52 0, 53) i52 @llvm.ctlz.i52(i52 %fraction, i1 true)
        \\  %result = zext i52 %count to i64
        \\  ret i64 %result
        \\}
        \\define i64 @other_odd_width(i64 %raw) {
        \\entry:
        \\  %fraction = trunc i64 %raw to i51
        \\  %result = zext i51 %fraction to i64
        \\  ret i64 %result
        \\}
        \\define i64 @arbitrary_add(i64 %raw) {
        \\entry:
        \\  %fraction = trunc i64 %raw to i52
        \\  %sum = add i52 %fraction, 1
        \\  %result = zext i52 %sum to i64
        \\  ret i64 %result
        \\}
        \\define i1 @signed_compare(i64 %raw) {
        \\entry:
        \\  %fraction = trunc i64 %raw to i52
        \\  %result = icmp slt i52 %fraction, 0
        \\  ret i1 %result
        \\}
        \\define i64 @unknown_shift(i64 %raw, i64 %amount) {
        \\entry:
        \\  %fraction = trunc i64 %raw to i52
        \\  %narrow_amount = trunc i64 %amount to i6
        \\  %wide_amount = zext i6 %narrow_amount to i52
        \\  %shifted = shl i52 %fraction, %wide_amount
        \\  %result = zext i52 %shifted to i64
        \\  ret i64 %result
        \\}
        \\define i52 @i52_return(i64 %raw) {
        \\entry:
        \\  %fraction = trunc i64 %raw to i52
        \\  ret i52 %fraction
        \\}
        \\define i64 @i52_param(i52 %fraction) {
        \\entry:
        \\  %result = zext i52 %fraction to i64
        \\  ret i64 %result
        \\}
        \\define i64 @i52_memory(i64 %raw) {
        \\entry:
        \\  %slot = alloca i52, align 8
        \\  %fraction = trunc i64 %raw to i52
        \\  store i52 %fraction, ptr %slot, align 8
        \\  %loaded = load i52, ptr %slot, align 8
        \\  %result = zext i52 %loaded to i64
        \\  ret i64 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    for (module.functions.items) |function| {
        var machine = MachineFunction.init(function.name, function.ret_ty);
        defer machine.deinit(std.testing.allocator);
        switch (try impl.tryLowerComposedCfg(std.testing.allocator, &machine, function)) {
            .unsupported => {},
            .selected => return error.TestUnexpectedResult,
        }
    }
}

test "composed selector keeps non-EI switch phi shapes fail closed" {
    const input =
        \\define double @wrong_width(i32 %which, double %v1, double %v2, double %v3, double %v4, double %v5) {
        \\entry:
        \\  switch i32 %which, label %default [
        \\    i32 0, label %merge
        \\    i32 1, label %case1
        \\    i32 2, label %case2
        \\    i32 3, label %case3
        \\    i32 4, label %case4
        \\  ]
        \\merge:
        \\  %result = phi double [ 0.000000e+00, %entry ], [ %v1, %case1 ], [ %v2, %case2 ], [ %v3, %case3 ], [ %v4, %case4 ], [ %v5, %default.exit ]
        \\  ret double %result
        \\case1:
        \\  br label %merge
        \\case2:
        \\  br label %merge
        \\case3:
        \\  br label %merge
        \\case4:
        \\  br label %merge
        \\default:
        \\  br label %default.exit
        \\default.exit:
        \\  br label %merge
        \\}
        \\define float @incomplete_join(i32 %which, float %v1, float %v2, float %v3, float %v4) {
        \\entry:
        \\  %key = trunc i32 %which to i16
        \\  switch i16 %key, label %case4 [
        \\    i16 0, label %merge
        \\    i16 1, label %case1
        \\    i16 2, label %case2
        \\    i16 3, label %case3
        \\  ]
        \\merge:
        \\  %result = phi float [ 0.000000e+00, %entry ], [ %v1, %case1 ], [ %v2, %case2 ], [ %v3, %case3 ], [ %v4, %case4 ]
        \\  ret float %result
        \\case1:
        \\  br label %merge
        \\case2:
        \\  br label %merge
        \\case3:
        \\  br label %merge
        \\case4:
        \\  br label %merge
        \\}
        \\define half @nonzero_entry(i32 %which, half %v1, half %v2, half %v3, half %v4, half %v5) {
        \\entry:
        \\  %key = trunc i32 %which to i16
        \\  switch i16 %key, label %default [
        \\    i16 0, label %merge
        \\    i16 1, label %case1
        \\    i16 2, label %case2
        \\    i16 3, label %case3
        \\    i16 4, label %case4
        \\  ]
        \\merge:
        \\  %result = phi half [ 0xH3C00, %entry ], [ %v1, %case1 ], [ %v2, %case2 ], [ %v3, %case3 ], [ %v4, %case4 ], [ %v5, %default.exit ]
        \\  ret half %result
        \\case1:
        \\  br label %merge
        \\case2:
        \\  br label %merge
        \\case3:
        \\  br label %merge
        \\case4:
        \\  br label %merge
        \\default:
        \\  br label %default.exit
        \\default.exit:
        \\  br label %merge
        \\}
        \\define double @unproven_default(i32 %which, double %v1, double %v2, double %v3, double %v4, double %v5) {
        \\entry:
        \\  %key = trunc i32 %which to i16
        \\  switch i16 %key, label %default [
        \\    i16 0, label %merge
        \\    i16 1, label %case1
        \\    i16 2, label %case2
        \\    i16 3, label %case3
        \\    i16 4, label %case4
        \\  ]
        \\merge:
        \\  %result = phi double [ 0.000000e+00, %entry ], [ %v1, %case1 ], [ %v2, %case2 ], [ %v3, %case3 ], [ %v4, %case4 ], [ %v5, %dead ]
        \\  ret double %result
        \\case1:
        \\  br label %merge
        \\case2:
        \\  br label %merge
        \\case3:
        \\  br label %merge
        \\case4:
        \\  br label %merge
        \\default:
        \\  unreachable
        \\dead:
        \\  br label %merge
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    for (module.functions.items) |function| {
        var machine = MachineFunction.init(function.name, function.ret_ty);
        defer machine.deinit(std.testing.allocator);
        switch (try impl.tryLowerComposedCfg(std.testing.allocator, &machine, function)) {
            .unsupported => {},
            .selected => return error.TestUnexpectedResult,
        }
    }
}

test "composed selector rejects duplicate EI switch cases before phi admission" {
    const input =
        \\define double @duplicate(i32 %which) {
        \\entry:
        \\  %key = trunc i32 %which to i16
        \\  switch i16 %key, label %default [
        \\    i16 0, label %merge
        \\    i16 0, label %other
        \\    i16 2, label %other
        \\    i16 3, label %other
        \\    i16 4, label %other
        \\  ]
        \\merge:
        \\  %result = phi double [ 0.000000e+00, %entry ]
        \\  ret double %result
        \\other:
        \\  ret double 1.000000e+00
        \\default:
        \\  ret double 2.000000e+00
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    var machine = MachineFunction.init("duplicate", .double);
    defer machine.deinit(std.testing.allocator);
    const selection = try impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]);
    switch (selection) {
        .unsupported => |diagnostic| try std.testing.expectEqualStrings("stage2-switch-duplicate-case", diagnostic.detail()),
        .selected => return error.TestUnexpectedResult,
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
