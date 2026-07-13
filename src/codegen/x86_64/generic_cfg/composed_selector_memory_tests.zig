const std = @import("std");
const ir = @import("../../../ir.zig");
const x86_64_machine = @import("../machine.zig");
const x86_64_verify = @import("../verify.zig");
const constant_table = @import("../constant_table.zig");
const encoding = @import("../../../mc/encoding.zig");
const elf = @import("../../../mc/elf.zig");
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

test "constant table shapes execute first interior and last probes" {
    const input = try buildConstantTableModuleText(std.testing.allocator);
    defer std.testing.allocator.free(input);
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    const context: x86_64_machine.ReadOnlyModuleContext = .{
        .globals = module.globals.items,
        .named_types = module.named_types.items,
        .target_datalayout = module.target_datalayout,
    };

    const Probe = struct {
        function_name: []const u8,
        symbol: []const u8,
        indexes: [3]u64,
        element_indexes: [3]usize,
        offset: usize,
        integer: bool = false,
    };
    const probes = [_]Probe{
        .{ .function_name = "probe_i16", .symbol = "table_i16", .indexes = .{ 0, 63, 127 }, .element_indexes = .{ 0, 63, 127 }, .offset = 0, .integer = true },
        .{ .function_name = "probe_f64_16", .symbol = "table_f64_16", .indexes = .{ 0, 7, 15 }, .element_indexes = .{ 0, 7, 15 }, .offset = 0 },
        .{ .function_name = "probe_f64_512_lo", .symbol = "table_f64_512", .indexes = .{ 0, 128, 255 }, .element_indexes = .{ 0, 256, 510 }, .offset = 0 },
        .{ .function_name = "probe_f64_512_hi", .symbol = "table_f64_512", .indexes = .{ 0, 128, 255 }, .element_indexes = .{ 1, 257, 511 }, .offset = 8 },
        .{ .function_name = "probe_pair_lo", .symbol = "table_pair", .indexes = .{ 0, 64, 127 }, .element_indexes = .{ 0, 128, 254 }, .offset = 0 },
        .{ .function_name = "probe_pair_hi", .symbol = "table_pair", .indexes = .{ 0, 64, 127 }, .element_indexes = .{ 1, 129, 255 }, .offset = 8 },
    };

    for (probes) |probe| {
        const function = findFunction(module, probe.function_name) orelse return error.TestUnexpectedResult;
        var machine = MachineFunction.init(function.name, function.ret_ty);
        defer machine.deinit(std.testing.allocator);
        const selection = try impl.tryLowerComposedCfgWithContext(std.testing.allocator, &machine, function, &context);
        switch (selection) {
            .selected => {},
            .unsupported => |diagnostic| {
                std.debug.print("constant-table probe {s}: {any}\n", .{ probe.function_name, diagnostic });
                return error.TestUnexpectedResult;
            },
        }
        try x86_64_verify.verifyFunction(machine);
        const code = try encoding.encodeFunction(std.testing.allocator, machine);
        defer std.testing.allocator.free(code);
        var decoded = (try constant_table.decodeSymbol(std.testing.allocator, context, probe.symbol)).?;
        defer decoded.deinit(std.testing.allocator);

        const table_offset = std.mem.alignForward(usize, code.len, decoded.alignment);
        const mapping_len = table_offset + decoded.bytes.len;
        const mapping = try std.posix.mmap(null, mapping_len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(mapping);
        @memset(mapping, 0);
        @memcpy(mapping[0..code.len], code);
        @memcpy(mapping[table_offset..][0..decoded.bytes.len], decoded.bytes);
        const relocation_offset = findLeaPc32Offset(mapping[0..code.len]) orelse return error.TestUnexpectedResult;
        const next_ip = relocation_offset + 4;
        const displacement: i32 = @intCast(@as(isize, @intCast(table_offset)) - @as(isize, @intCast(next_ip)));
        std.mem.writeInt(i32, mapping[relocation_offset..][0..4], displacement, .little);

        for (probe.indexes, probe.element_indexes) |index, element_index| {
            if (probe.integer) {
                const call: *const fn (u64) callconv(.c) u32 = @ptrCast(mapping.ptr);
                const expected = std.mem.readInt(u16, decoded.bytes[element_index * 2 ..][0..2], .little);
                try std.testing.expectEqual(@as(u32, expected), call(index));
            } else {
                const call: *const fn (u64) callconv(.c) f64 = @ptrCast(mapping.ptr);
                const expected = std.mem.readInt(u64, decoded.bytes[element_index * 8 ..][0..8], .little);
                try std.testing.expectEqual(expected, @as(u64, @bitCast(call(index))));
            }
        }
    }

    var machines: std.ArrayList(MachineFunction) = .empty;
    defer {
        for (machines.items) |*machine| machine.deinit(std.testing.allocator);
        machines.deinit(std.testing.allocator);
    }
    for (module.functions.items) |function| {
        var machine = MachineFunction.init(function.name, function.ret_ty);
        errdefer machine.deinit(std.testing.allocator);
        try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfgWithContext(std.testing.allocator, &machine, function, &context));
        try machines.append(std.testing.allocator, machine);
    }
    const object = try elf.buildObjectWithModuleContext(std.testing.allocator, machines.items, &.{}, context);
    defer std.testing.allocator.free(object);
    inline for (.{ "table_i16", "table_f64_16", "table_f64_512", "table_pair", ".rela.text" }) |needle| {
        try std.testing.expect(std.mem.indexOf(u8, object, needle) != null);
    }
}

test "constant table admission rejects unproved indexes and writable globals" {
    const input =
        \\target datalayout = "e-m:e-i64:64-n8:16:32:64-S128"
        \\@writable = internal global [16 x double] zeroinitializer, align 8
        \\@readonly = internal constant [16 x double] [double 1.0, double 2.0, double 3.0, double 4.0, double 5.0, double 6.0, double 7.0, double 8.0, double 9.0, double 10.0, double 11.0, double 12.0, double 13.0, double 14.0, double 15.0, double 16.0], align 8
        \\define double @unproved(i64 %index) {
        \\entry:
        \\  %ptr = getelementptr [8 x i8], ptr @readonly, i64 %index
        \\  %value = load double, ptr %ptr, align 8
        \\  ret double %value
        \\}
        \\define double @writable_table(i64 %index) {
        \\entry:
        \\  %masked = and i64 %index, 15
        \\  %ptr = getelementptr [8 x i8], ptr @writable, i64 %masked
        \\  %value = load double, ptr %ptr, align 8
        \\  ret double %value
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    const context: x86_64_machine.ReadOnlyModuleContext = .{
        .globals = module.globals.items,
        .named_types = module.named_types.items,
        .target_datalayout = module.target_datalayout,
    };
    for (module.functions.items, 0..) |function, index| {
        var machine = MachineFunction.init(function.name, function.ret_ty);
        defer machine.deinit(std.testing.allocator);
        const result = try impl.tryLowerComposedCfgWithContext(std.testing.allocator, &machine, function, &context);
        switch (result) {
            .selected => return error.TestUnexpectedResult,
            .unsupported => |diagnostic| try std.testing.expectEqualStrings(
                if (index == 0) "composed-block-gep-readonly-table-range" else "composed-block-gep-readonly-table-global",
                diagnostic.no_emitter,
            ),
        }
    }
}

fn buildConstantTableModuleText(allocator: std.mem.Allocator) ![]u8 {
    var text: std.ArrayList(u8) = .empty;
    errdefer text.deinit(allocator);
    try text.appendSlice(allocator, "target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128\"\n");
    try text.appendSlice(allocator, "%pair = type { double, double }\n");
    try text.appendSlice(allocator, "@table_i16 = internal constant [128 x i16] [");
    for (0..128) |index| {
        if (index != 0) try text.appendSlice(allocator, ", ");
        try appendFmt(&text, allocator, "i16 {}", .{1000 + index});
    }
    try text.appendSlice(allocator, "], align 2\n@table_f64_16 = internal constant [16 x double] [");
    for (0..16) |index| {
        if (index != 0) try text.appendSlice(allocator, ", ");
        try appendF64Literal(&text, allocator, @floatFromInt(index + 1));
    }
    try text.appendSlice(allocator, "], align 8\n@table_f64_512 = internal constant [512 x double] [");
    for (0..512) |index| {
        if (index != 0) try text.appendSlice(allocator, ", ");
        try appendF64Literal(&text, allocator, @floatFromInt(index + 100));
    }
    try text.appendSlice(allocator, "], align 8\n@table_pair = internal constant [128 x %pair] [");
    for (0..128) |index| {
        if (index != 0) try text.appendSlice(allocator, ", ");
        try text.appendSlice(allocator, "%pair { ");
        try appendF64Literal(&text, allocator, @floatFromInt(index + 1000));
        try text.appendSlice(allocator, ", ");
        try appendF64Literal(&text, allocator, @floatFromInt(index + 2000));
        try text.appendSlice(allocator, " }");
    }
    try text.appendSlice(allocator, "], align 8\n");
    try text.appendSlice(allocator,
        \\define i32 @probe_i16(i64 %index) {
        \\entry:
        \\  %masked = and i64 %index, 127
        \\  %ptr = getelementptr [2 x i8], ptr @table_i16, i64 %masked
        \\  %value = load i16, ptr %ptr, align 2
        \\  %wide = zext i16 %value to i32
        \\  ret i32 %wide
        \\}
        \\define double @probe_f64_16(i64 %index) {
        \\entry:
        \\  %masked = and i64 %index, 15
        \\  %ptr = getelementptr [8 x i8], ptr @table_f64_16, i64 %masked
        \\  %value = load double, ptr %ptr, align 8
        \\  ret double %value
        \\}
        \\define double @probe_f64_512_lo(i32 %index) {
        \\entry:
        \\  %shifted = shl i32 %index, 1
        \\  %masked = and i32 %shifted, 510
        \\  %wide = zext i32 %masked to i64
        \\  %ptr = getelementptr [8 x i8], ptr @table_f64_512, i64 %wide
        \\  %value = load double, ptr %ptr, align 8
        \\  ret double %value
        \\}
        \\define double @probe_f64_512_hi(i32 %index) {
        \\entry:
        \\  %shifted = shl i32 %index, 1
        \\  %masked = and i32 %shifted, 510
        \\  %wide = zext i32 %masked to i64
        \\  %ptr = getelementptr [8 x i8], ptr @table_f64_512, i64 %wide
        \\  %hi = getelementptr i8, ptr %ptr, i64 8
        \\  %value = load double, ptr %hi, align 8
        \\  ret double %value
        \\}
        \\define double @probe_pair_lo(i64 %index) {
        \\entry:
        \\  %masked = and i64 %index, 127
        \\  %ptr = getelementptr [16 x i8], ptr @table_pair, i64 %masked
        \\  %value = load double, ptr %ptr, align 8
        \\  ret double %value
        \\}
        \\define double @probe_pair_hi(i64 %index) {
        \\entry:
        \\  %masked = and i64 %index, 127
        \\  %ptr = getelementptr [16 x i8], ptr @table_pair, i64 %masked
        \\  %hi = getelementptr i8, ptr %ptr, i64 8
        \\  %value = load double, ptr %hi, align 8
        \\  ret double %value
        \\}
        \\
    );
    return text.toOwnedSlice(allocator);
}

fn appendF64Literal(text: *std.ArrayList(u8), allocator: std.mem.Allocator, value: f64) !void {
    try appendFmt(text, allocator, "double 0x{X:0>16}", .{@as(u64, @bitCast(value))});
}

fn appendFmt(text: *std.ArrayList(u8), allocator: std.mem.Allocator, comptime format: []const u8, args: anytype) !void {
    const piece = try std.fmt.allocPrint(allocator, format, args);
    defer allocator.free(piece);
    try text.appendSlice(allocator, piece);
}

fn findFunction(module: ir.Module, name: []const u8) ?ir.Function {
    for (module.functions.items) |function| if (std.mem.eql(u8, function.name, name)) return function;
    return null;
}

fn findLeaPc32Offset(code: []const u8) ?usize {
    var index: usize = 0;
    while (index + 7 <= code.len) : (index += 1) {
        if (code[index] == 0x48 and code[index + 1] == 0x8d and code[index + 2] == 0x0d) return index + 3;
    }
    return null;
}
