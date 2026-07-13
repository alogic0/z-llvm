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

test "composed selector lowers typed float and double stack roundtrips" {
    const input =
        \\define float @roundtrip_f32(float %value) {
        \\entry:
        \\  %slot = alloca float, align 4
        \\  store float %value, ptr %slot, align 4
        \\  %loaded = load float, ptr %slot, align 4
        \\  ret float %loaded
        \\}
        \\define double @roundtrip_f64(double %value) {
        \\entry:
        \\  %slot = alloca double, align 8
        \\  store double %value, ptr %slot, align 8
        \\  %loaded = load double, ptr %slot, align 8
        \\  ret double %loaded
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

        var saw_store = false;
        var saw_load = false;
        for (machine.instructions.items) |instruction| switch (instruction) {
            .spill_xmm32_rsp => if (index == 0) {
                saw_store = true;
            },
            .spill_xmm64_rsp => if (index == 1) {
                saw_store = true;
            },
            .load_stack_disp8_xmm0_f32, .load_stack_disp32_xmm0_f32 => if (index == 0) {
                saw_load = true;
            },
            .load_stack_disp8_xmm0, .load_stack_disp32_xmm0 => if (index == 1) {
                saw_load = true;
            },
            else => {},
        };
        try std.testing.expect(saw_store and saw_load);
        try x86_64_verify.verifyFunction(machine);

        const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
        defer std.testing.allocator.free(bytes);
        const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(mapping);
        @memcpy(mapping, bytes);
        if (index == 0) {
            const roundtrip: *const fn (f32) callconv(.c) f32 = @ptrCast(mapping.ptr);
            inline for (.{ @as(u32, 0x0000_0000), @as(u32, 0x8000_0000), @as(u32, 0x0000_0001), @as(u32, 0x807f_ffff), @as(u32, 0x7f80_0000), @as(u32, 0x7fc1_2345) }) |bits| {
                try std.testing.expectEqual(bits, @as(u32, @bitCast(roundtrip(@bitCast(bits)))));
            }
        } else {
            const roundtrip: *const fn (f64) callconv(.c) f64 = @ptrCast(mapping.ptr);
            inline for (.{ @as(u64, 0x0000_0000_0000_0000), @as(u64, 0x8000_0000_0000_0000), @as(u64, 0x0000_0000_0000_0001), @as(u64, 0x800f_ffff_ffff_ffff), @as(u64, 0x7ff0_0000_0000_0000), @as(u64, 0x7ff8_1234_5678_9abc) }) |bits| {
                try std.testing.expectEqual(bits, @as(u64, @bitCast(roundtrip(@bitCast(bits)))));
            }
        }
    }
}

test "composed selector stages a local FP out parameter and preserves live XMM" {
    const input =
        \\declare fastcc i32 @write_out(float, ptr)
        \\define double @caller(float %input, double %seed) {
        \\entry:
        \\  %slot = alloca double, align 8
        \\  store double %seed, ptr %slot, align 8
        \\  %live = fmul double %seed, 1.000000e+00
        \\  %code = call fastcc i32 @write_out(float %input, ptr nonnull align 8 %slot)
        \\  %reduced = and i32 %code, 1
        \\  %loaded = load double, ptr %slot, align 8
        \\  %result = fmul double %live, %loaded
        \\  ret double %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = MachineFunction.init("caller", .double);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));

    var call_index: ?usize = null;
    var saw_stack_pointer = false;
    var saw_live_spill = false;
    var saw_live_reload = false;
    var saw_out_load = false;
    var saw_reduced_result = false;
    for (machine.instructions.items, 0..) |instruction, index| switch (instruction) {
        .mov_rsp_arg64 => |reg| saw_stack_pointer = saw_stack_pointer or reg == .rdi,
        .direct_call => call_index = index,
        .spill_xmm64_rsp => if (call_index == null) {
            saw_live_spill = true;
        },
        .reload_xmm64_rsp => if (call_index) |at| {
            if (index > at) saw_live_reload = true;
        },
        .load_stack_disp8_xmm0, .load_stack_disp32_xmm0 => if (call_index != null) {
            saw_out_load = true;
        },
        .and_eax_imm32 => |imm| saw_reduced_result = saw_reduced_result or imm == 1,
        else => {},
    };
    try std.testing.expect(call_index != null and saw_stack_pointer and saw_live_spill and saw_live_reload and saw_out_load and saw_reduced_result);
    try x86_64_verify.verifyFunction(machine);
}

test "composed selector keeps unsupported FP memory fail closed" {
    var machine = MachineFunction.init("fp-memory-boundaries", .void);
    defer machine.deinit(std.testing.allocator);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.stack_frame_bytes = 24;
    try selector_state.bindValueLoc(&selector, "slot", .{ .stack_scalar = .{ .base_disp = 0, .bits = 64, .kind = .fp } });
    try selector_state.bindValueLoc(&selector, "external", .{ .arg64 = .rdi });
    try selector_state.bindValueLoc(&selector, "value", .{ .xmm = .{ .reg = .xmm0, .bits = 64 } });

    const volatile_diagnostic = (try selector_memory.lowerLoad(&selector, "loaded", .{
        .ty = .double,
        .ptr = .{ .named = "slot" },
        .attrs = .{ .is_volatile = true },
    })).?;
    try std.testing.expectEqualStrings("composed-block-load-barrier", volatile_diagnostic.no_emitter);

    const external_diagnostic = (try selector_memory.lowerStore(&selector, .{
        .ty = .double,
        .value = .{ .named = "value" },
        .ptr = .{ .named = "external" },
    })).?;
    try std.testing.expectEqualStrings("composed-block-store-fp-ptr", external_diagnostic.no_emitter);
}

test "composed selector stores scalar FP values through proven pointer parameters" {
    const input =
        \\define void @store_f32(float %value, ptr %out) {
        \\entry:
        \\  store float %value, ptr %out, align 4
        \\  ret void
        \\}
        \\define void @store_f64(double %value, ptr %out) {
        \\entry:
        \\  store double %value, ptr %out, align 8
        \\  ret void
        \\}
        \\define void @store_f32_framed(float %value, ptr %out) {
        \\entry:
        \\  %slot = alloca double, align 8
        \\  br label %body
        \\body:
        \\  store float %value, ptr %out, align 4
        \\  ret void
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
        if (index == 2) {
            var saw_fp_reload = false;
            var saw_pointer_reload = false;
            var saw_spilled_pointer_store = false;
            for (machine.instructions.items) |instruction| switch (instruction) {
                .reload_xmm32_rsp => saw_fp_reload = true,
                .reload_arg64_rsp => |reload| saw_pointer_reload = reload.reg == .rcx,
                .store_xmm0_f32_arg_ptr_disp8 => |store| saw_spilled_pointer_store = store.reg == .rcx and store.offset == 0,
                else => {},
            };
            try std.testing.expect(saw_fp_reload and saw_pointer_reload and saw_spilled_pointer_store);
        }

        const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
        defer std.testing.allocator.free(bytes);
        const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(mapping);
        @memcpy(mapping, bytes);
        if (index == 1) {
            const store: *const fn (f64, *f64) callconv(.c) void = @ptrCast(mapping.ptr);
            inline for (.{ @as(u64, 0x0000_0000_0000_0000), @as(u64, 0x8000_0000_0000_0000), @as(u64, 0x0000_0000_0000_0001), @as(u64, 0x7ff0_0000_0000_0000), @as(u64, 0x7ff8_1234_5678_9abc) }) |bits| {
                var out: f64 = undefined;
                store(@bitCast(bits), &out);
                try std.testing.expectEqual(bits, @as(u64, @bitCast(out)));
            }
        } else {
            const store: *const fn (f32, *f32) callconv(.c) void = @ptrCast(mapping.ptr);
            inline for (.{ @as(u32, 0x0000_0000), @as(u32, 0x8000_0000), @as(u32, 0x0000_0001), @as(u32, 0x7f80_0000), @as(u32, 0x7fc1_2345) }) |bits| {
                var out: f32 = undefined;
                store(@bitCast(bits), &out);
                try std.testing.expectEqual(bits, @as(u32, @bitCast(out)));
            }
        }
    }
}

test "composed selector rejects FP stores through derived pointers" {
    const input =
        \\define void @store_unproven(ptr %base, float %value) {
        \\entry:
        \\  %out = getelementptr i8, ptr %base, i64 4
        \\  store float %value, ptr %out, align 4
        \\  ret void
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = MachineFunction.init("store_unproven", .void);
    defer machine.deinit(std.testing.allocator);
    const selection = try impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]);
    switch (selection) {
        .unsupported => |diagnostic| try std.testing.expectEqualStrings("composed-block-store-fp-ptr", diagnostic.no_emitter),
        .selected => return error.TestUnexpectedResult,
    }
}
