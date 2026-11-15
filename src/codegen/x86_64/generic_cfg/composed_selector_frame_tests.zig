const std = @import("std");
const ir = @import("../../../ir.zig");
const x86_64_machine = @import("../machine.zig");
const x86_64_types = @import("../types.zig");
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

test "large frame probes every crossed page and preserves the exact final stack displacement" {
    const allocator = std.testing.allocator;
    for ([_]u32{ 262144, 1048576, 1835008, 2097082 }) |words| {
        const ty = try std.fmt.allocPrint(allocator, "[{d} x i32]", .{words});
        defer allocator.free(ty);
        var function = ir.Function.init("large-frame", .void);
        defer function.deinit(allocator);
        var entry = ir.BasicBlock.init("entry");
        try entry.instructions.append(allocator, .{
            .result = "array",
            .kind = .{ .alloca = .{ .allocated_ty = .{ .aggregate = ty }, .attrs = "align 4" } },
        });
        entry.terminator = .{ .ret = .{ .ty = .void, .value = null } };
        try function.blocks.append(allocator, entry);
        var machine = MachineFunction.init("large-frame", .void);
        defer machine.deinit(allocator);
        var selector = ComposedBlockSelector.init(allocator, &machine);
        defer selector.deinit();
        try std.testing.expect((try selector_frame.prepareStackFrame(&selector, function)) == null);
        try std.testing.expect(selector.stack_frame_bytes > 1024 * 1024);
        const array = selector_state.valueLoc(&selector, "array").?.stack_i32_array;
        try std.testing.expectEqual(words, array.len);
        try std.testing.expect(array.base_disp + 4 * words <= selector.stack_frame_bytes);
        var displacement: u32 = 0;
        var last_touch: u32 = 0;
        for (machine.instructions.items) |instruction| switch (instruction) {
            .sub_rsp_imm32 => |bytes| displacement += bytes,
            .sub_rsp_imm8 => |bytes| displacement += bytes,
            .push_imm32 => {
                displacement += 8;
                try std.testing.expect(displacement - last_touch <= 4096);
                last_touch = displacement;
            },
            else => return error.UnexpectedFramePrologueInstruction,
        };
        try std.testing.expectEqual(selector.stack_frame_bytes, displacement);
        try std.testing.expectEqual(displacement, last_touch);
        try std.testing.expectEqual(@as(u32, 8), displacement % 16);
    }
}

test "large frame resource bounds reject the first excessive array before emitting a prologue" {
    const allocator = std.testing.allocator;
    var function = ir.Function.init("excessive-frame", .void);
    defer function.deinit(allocator);
    var entry = ir.BasicBlock.init("entry");
    try entry.instructions.append(allocator, .{
        .result = "array",
        .kind = .{ .alloca = .{ .allocated_ty = .{ .aggregate = "[2097083 x i32]" }, .attrs = "align 4" } },
    });
    entry.terminator = .{ .ret = .{ .ty = .void, .value = null } };
    try function.blocks.append(allocator, entry);
    var machine = MachineFunction.init("excessive-frame", .void);
    defer machine.deinit(allocator);
    var selector = ComposedBlockSelector.init(allocator, &machine);
    defer selector.deinit();
    const diagnostic = (try selector_frame.prepareStackFrame(&selector, function)).?;
    try std.testing.expectEqualStrings("composed-block-stack-frame-limit", diagnostic.no_spill_envelope);
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try std.testing.expectEqual(@as(u32, 0), selector.stack_frame_bytes);
}

test "generic cfg selector keeps scalar allocas disjoint from emergency FP spills" {
    const input =
        \\define void @preserve_f32_across_local_store(float %value, ptr %out) {
        \\entry:
        \\  %slot = alloca double, align 8
        \\  store double 0.000000e+00, ptr %slot, align 8
        \\  store float %value, ptr %out, align 4
        \\  ret void
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const function = module.functions.items[0];
    var machine = MachineFunction.init(function.name, function.ret_ty);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, function));
    try x86_64_verify.verifyFunction(machine);

    var value_spill: ?x86_64_types.FrameIndex = null;
    var local_store: ?x86_64_types.FrameIndex = null;
    for (machine.instructions.items) |instruction| switch (instruction) {
        .spill_xmm32_rsp => |spill| value_spill = spill.frame_index,
        .spill_xmm64_rsp => |spill| local_store = spill.frame_index,
        else => {},
    };
    try std.testing.expect(value_spill != null and local_store != null);
    try std.testing.expect(!value_spill.?.eql(local_store.?));

    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const preserve: *const fn (f32, *f32) callconv(.c) void = @ptrCast(mapping.ptr);
    inline for (.{ @as(u32, 0x0000_0000), @as(u32, 0x8000_0000), @as(u32, 0x0000_0001), @as(u32, 0x7f80_0000), @as(u32, 0x7fc1_2345) }) |bits| {
        var out: f32 = undefined;
        preserve(@bitCast(bits), &out);
        try std.testing.expectEqual(bits, @as(u32, @bitCast(out)));
    }
}

test "composed selector inline memset shares the existing preservation frame and encoding" {
    for ([_]u64{ 0, 1, 2, 16, 33, 256 }) |length| {
        var reference: ?[]u8 = null;
        defer if (reference) |bytes| std.testing.allocator.free(bytes);
        for ([_][]const u8{ "", ".inline" }) |suffix| {
            const text = try std.fmt.allocPrint(std.testing.allocator, "declare void @llvm.memset.p0.i64(ptr,i8,i64,i1 immarg)\ndeclare void @llvm.memset.inline.p0.i64(ptr,i8,i64 immarg,i1 immarg)\ndefine i64 @fill(ptr %dst,i8 zeroext %byte,i64 %keep) {{\nentry:\n call void @llvm.memset{s}.p0.i64(ptr %dst,i8 %byte,i64 {d},i1 false)\n ret i64 %keep\n}}\n", .{ suffix, length });
            defer std.testing.allocator.free(text);
            var module = try ir.Module.parse(std.testing.allocator, text);
            defer module.deinit();
            try module.verify();
            var machine = MachineFunction.init("fill", .{ .int = 64 });
            defer machine.deinit(std.testing.allocator);
            const result = try impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]);
            if (result == .unsupported) std.debug.print("inline frame: {s}\n", .{result.unsupported.detail()});
            try std.testing.expectEqual(impl.SelectionResult.selected, result);
            try x86_64_verify.verifyFunction(machine);
            const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
            defer std.testing.allocator.free(bytes);
            if (reference) |expected_bytes|
                try std.testing.expectEqualSlices(u8, expected_bytes, bytes)
            else
                reference = try std.testing.allocator.dupe(u8, bytes);
        }
    }
}
