const std = @import("std");
const support = @import("value_use/test_support.zig");
const encoding = @import("../../../mc/encoding.zig");
const ArgReg = @import("../types.zig").ArgReg;

test "value-use parallel transfers execute cycles fanout widths aliases and pressure" {
    const allocator = std.testing.allocator;
    const names = [_][]const u8{ "a", "b", "c", "d", "e", "f" };
    const inputs = [_][6]u64{
        .{ 1, 2, 3, 4, 5, 6 },
        .{ 0xffff_ffff_1234_5678, 0x8000_0000_7654_3210, 0xaaaa_bbbb_cccc_dddd, 0xffff_ffff, 0x8000_0000, 0 },
        .{ 0, 0xffff_ffff_ffff_ffff, 0x8000_0000_0000_0000, 7, 8, 9 },
    };
    for ([_]usize{ 2, 3 }) |cycle_size| for ([_]bool{ false, true }) |pressure| for ([_]bool{ false, true }) |narrow| for ([_]bool{ false, true }) |accumulator| {
        // Observe every destination, the fan-out copy, and both widths of a
        // live alias. The expected result depends only on the original inputs.
        for (0..cycle_size + 3) |observation| {
            var machine = support.MachineFunction.init("parallel-transfer", .{ .int = 64 });
            defer machine.deinit(allocator);
            var allocation = support.SelectorAllocationPlan.init(allocator);
            defer allocation.deinit();
            var state = support.ComposedBlockSelector.init(allocator, &machine);
            defer state.deinit();
            state.allocation_plan = &allocation;
            state.stack_frame_bytes = 136;
            for (0..(if (pressure) @as(usize, 6) else cycle_size)) |index| {
                try support.addLive(&allocation, names[index]);
                const reg = try ArgReg.fromIndex(index);
                try support.selector_state.bindValueLoc(&state, names[index], if (accumulator and index == 0)
                    (if (narrow) .eax else .rax)
                else if (narrow and index == 0)
                    .{ .arg32 = reg }
                else
                    .{ .arg64 = reg });
            }
            try support.addLive(&allocation, "wide-alias");
            try support.addLive(&allocation, "narrow-alias");
            try support.selector_state.bindValueLoc(&state, "wide-alias", if (accumulator) .rax else .{ .arg64 = .rdi });
            try support.selector_state.bindValueLoc(&state, "narrow-alias", if (accumulator) .eax else .{ .arg32 = .rdi });
            if (accumulator and pressure) {
                try support.addLive(&allocation, "occupied-rdi");
                try support.selector_state.bindValueLoc(&state, "occupied-rdi", .{ .arg64 = .rdi });
            }
            try machine.instructions.append(allocator, .{ .sub_rsp_imm32 = 136 });
            if (accumulator) try machine.instructions.append(allocator, .{ .mov_arg_rax = .rdi });
            var transfer = try support.Transaction.begin(&state);
            defer transfer.deinit();
            for (0..cycle_size) |index| {
                const bits: u16 = if (narrow and index == 0) 32 else 64;
                const reg = try ArgReg.fromIndex((index + 1) % cycle_size);
                const destination: support.Transaction.Destination = if (accumulator and index + 1 == cycle_size) .rax else if (bits == 32) .{ .gpr32 = reg } else .{ .gpr64 = reg };
                _ = try transfer.register(support.request(names[index], .{ .int = bits }, if (bits == 32) .gpr32 else .gpr64, if (bits == 32) .gpr32 else .gpr64, destination));
            }
            const fan_bits: u16 = if (narrow) 32 else 64;
            _ = try transfer.register(support.request("a", .{ .int = fan_bits }, if (narrow) .gpr32 else .gpr64, if (narrow) .gpr32 else .gpr64, if (narrow) .{ .gpr32 = .r8 } else .{ .gpr64 = .r8 }));
            try transfer.seal();
            try transfer.prepare();
            try transfer.materializeAll();
            try transfer.commit();
            if (observation < cycle_size) {
                if (!accumulator or observation + 1 != cycle_size)
                    try machine.instructions.append(allocator, .{ .mov_arg_rax = try ArgReg.fromIndex((observation + 1) % cycle_size) });
            } else if (observation == cycle_size) {
                try machine.instructions.append(allocator, .{ .mov_arg_rax = .r8 });
            } else {
                const wide = observation == cycle_size + 1;
                const alias = state.values.get(if (wide) "wide-alias" else "narrow-alias").?.loc;
                if (wide) try @import("value_use/materialization.zig").materializeScalar64(&state, alias, .rax) else try @import("value_use/materialization.zig").materializeScalar32(&state, alias, .eax);
            }
            try machine.instructions.appendSlice(allocator, &.{ .{ .add_rsp_imm32 = 136 }, .ret });
            const bytes = try encoding.encodeFunction(allocator, machine);
            defer allocator.free(bytes);
            const executable = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
            defer std.posix.munmap(executable);
            @memcpy(executable[0..bytes.len], bytes);
            const run: *const fn (u64, u64, u64, u64, u64, u64) callconv(.c) u64 = @ptrCast(executable.ptr);
            for (inputs) |values| {
                const source_index = if (observation < cycle_size) observation else 0;
                const truncate = if (observation < cycle_size) narrow and observation == 0 else if (observation == cycle_size) narrow else observation == cycle_size + 2;
                const expected = if (truncate) values[source_index] & 0xffff_ffff else values[source_index];
                try std.testing.expectEqual(expected, run(values[0], values[1], values[2], values[3], values[4], values[5]));
            }
        }
    };
}

test "value-use parallel transfer failure restores aliases spills flags and plan" {
    const allocator = std.testing.allocator;
    for ([_]bool{ false, true }) |exhausted| {
        var machine = support.MachineFunction.init("parallel-rollback", .{ .int = 64 });
        defer machine.deinit(allocator);
        var allocation = support.SelectorAllocationPlan.init(allocator);
        defer allocation.deinit();
        var state = support.ComposedBlockSelector.init(allocator, &machine);
        defer state.deinit();
        state.allocation_plan = &allocation;
        state.stack_frame_bytes = if (exhausted) 0 else 136;
        const names = [_][]const u8{ "a", "b", "c", "d", "e", "f" };
        for (names, 0..) |name, index| {
            try support.addLive(&allocation, name);
            try support.selector_state.bindValueLoc(&state, name, .{ .arg64 = try ArgReg.fromIndex(index) });
        }
        try state.eflags.apply(.definition);
        const flags = state.eflags.snapshot();
        const next_vreg = state.next_virtual_reg;
        var transfer = try support.Transaction.begin(&state);
        defer transfer.deinit();
        _ = try transfer.register(support.request("a", .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = .rsi }));
        _ = try transfer.register(support.request("b", .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = .rdi }));
        try transfer.seal();
        if (exhausted) {
            try std.testing.expectError(error.UnsupportedCodegenValue, transfer.prepare());
        } else {
            try transfer.prepare();
            state.values.getPtr("b").?.loc = .{ .xmm = .{ .reg = .xmm0, .bits = 64 } };
            try std.testing.expectError(error.ValueUseXmmUnsupported, transfer.materializeAll());
        }
        for (names, 0..) |name, index|
            try std.testing.expectEqual(support.ValueLoc{ .arg64 = try ArgReg.fromIndex(index) }, state.values.get(name).?.loc);
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
        try std.testing.expectEqual(@as(usize, 0), state.spill_slots.count());
        try std.testing.expectEqual(next_vreg, state.next_virtual_reg);
        try state.eflags.validateSnapshot(flags);
        for (transfer.parallel_sources) |needed| try std.testing.expect(!needed);
        for (transfer.transfer_nodes) |reserved| try std.testing.expect(!reserved);
    }
}
