const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const verify = @import("../verify.zig");
const selector = @import("../generic_cfg_selector.zig");
const encoding = @import("../../../mc/encoding.zig");
const support = @import("value_use/test_support.zig");

test "accumulator stores preserve live aliases and roll back address staging" {
    const homes = [_]support.ValueLoc{ .{ .arg64 = .rdi }, .{ .scratch64 = .r8 }, .{ .scratch64 = .rcx }, .{ .spill64 = .slot4 }, .rax };
    for (homes) |home| for ([_]bool{ false, true }) |commit| {
        var output = machine.MachineFunction.init("accumulator-store", .void);
        defer output.deinit(std.testing.allocator);
        var plan = support.SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        inline for (&.{ "value", "pointer", "scratch" }) |name| try support.addLive(&plan, name);
        var state = support.ComposedBlockSelector.init(std.testing.allocator, &output);
        defer state.deinit();
        state.allocation_plan = &plan;
        state.current_position = 1;
        state.stack_frame_bytes = 128;
        state.next_spill_slot = 6;
        try support.selector_state.bindValueLoc(&state, "value", home);
        try support.selector_state.bindValueLoc(&state, "pointer", .rax);
        try support.selector_state.bindValueLoc(&state, "scratch", .{ .scratch64 = .rcx });
        try state.eflags.apply(.definition);
        const value_before = state.values.get("value").?;
        const pointer_before = state.values.get("pointer").?;
        const scratch_before = state.values.get("scratch").?;
        const flags = state.eflags.snapshot();
        const domain = state.accumulator_domain;
        const next_vreg = state.next_virtual_reg;
        var transaction = try support.Transaction.begin(&state);
        defer transaction.deinit();
        const value = try transaction.register(support.preparedSourceRequest("value", .{ .int = 64 }, .gpr64, .gpr64));
        const action = try transaction.register(support.preparedRequest("pointer", .ptr, .gpr64, .pointer, .{ .store_i64 = .{ .value = value } }));
        try transaction.seal();
        try transaction.prepare();
        try transaction.materializeAll();
        try transaction.executePreparedAction(try transaction.preparedView(action));
        const address: @import("../types.zig").ArgReg = if (home == .scratch64 and home.scratch64 == .rcx) .rdx else .rcx;
        try std.testing.expectEqual(if (address == .rcx) machine.Instruction.store_rax_rcx_ptr else machine.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = address, .offset = 0 } }, output.instructions.items[output.instructions.items.len - 1]);
        try state.eflags.validateSnapshot(flags);
        if (commit) {
            try transaction.commit();
            try std.testing.expectEqual(value_before.vreg, state.values.get("value").?.vreg);
            try std.testing.expectEqual(pointer_before.vreg, state.values.get("pointer").?.vreg);
            try std.testing.expectEqual(scratch_before.vreg, state.values.get("scratch").?.vreg);
            if (address == .rcx) try std.testing.expect(state.values.get("scratch").?.loc != .scratch64);
        } else {
            try transaction.rollback();
            try std.testing.expectEqual(value_before, state.values.get("value").?);
            try std.testing.expectEqual(pointer_before, state.values.get("pointer").?);
            try std.testing.expectEqual(scratch_before, state.values.get("scratch").?);
            try std.testing.expectEqualDeep(domain, state.accumulator_domain);
            try state.eflags.validateSnapshot(flags);
            try std.testing.expectEqual(next_vreg, state.next_virtual_reg);
            try std.testing.expectEqual(@as(usize, 6), state.next_spill_slot);
            try std.testing.expectEqual(@as(usize, 0), state.spill_slots.count());
            try std.testing.expectEqual(@as(usize, 0), output.instructions.items.len);
        }
    };
}

test "accumulator stores preserve address copy cycles and reject conflicting writes" {
    for ([_]bool{ false, true }) |conflict| {
        var output = machine.MachineFunction.init("accumulator-store-reject", .void);
        defer output.deinit(std.testing.allocator);
        var plan = support.SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        inline for (&.{ "pointer", "value", "other" }) |name| try support.addAtCurrent(&plan, name);
        var state = support.ComposedBlockSelector.init(std.testing.allocator, &output);
        defer state.deinit();
        state.allocation_plan = &plan;
        try support.selector_state.bindValueLoc(&state, "pointer", .rax);
        try support.selector_state.bindValueLoc(&state, "value", .{ .scratch64 = if (conflict) .r8 else .rcx });
        try support.selector_state.bindValueLoc(&state, "other", .{ .arg64 = if (conflict) .rdi else .rdx });
        const pointer_before = state.values.get("pointer").?;
        const value_before = state.values.get("value").?;
        var transaction = try support.Transaction.begin(&state);
        defer transaction.deinit();
        const value = try transaction.register(support.preparedSourceRequest("value", .{ .int = 64 }, .gpr64, .gpr64));
        _ = try transaction.register(support.preparedRequest("pointer", .ptr, .gpr64, .pointer, .{ .store_i64 = .{ .value = value } }));
        _ = try transaction.register(support.request("other", .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = .rcx }));
        if (conflict) {
            try std.testing.expectError(error.ValueUseConflictingDestination, transaction.seal());
        } else {
            try transaction.seal();
            try transaction.prepare();
            try transaction.materializeAll();
            try transaction.rollback();
        }
        try std.testing.expectEqual(pointer_before, state.values.get("pointer").?);
        try std.testing.expectEqual(value_before, state.values.get("value").?);
        try std.testing.expectEqual(@as(usize, 0), output.instructions.items.len);
    }
}

test "accumulator stores execute full words and pointer aliases on selected branches" {
    for ([_]bool{ false, true }) |alias| {
        const text = try std.fmt.allocPrint(std.testing.allocator,
            \\define i64 @write(ptr %slot, i64 %value, i64 %live, i64 %take) {{
            \\entry:
            \\  %condition = icmp ne i64 %take, 0
            \\  br i1 %condition, label %store, label %empty
            \\store:
            \\  %pointer = load ptr, ptr %slot, align 8
            \\  {s}
            \\  %read = load i64, ptr %pointer, align 8
            \\  %answer = xor i64 %read, %live
            \\  ret i64 %answer
            \\empty:
            \\  ret i64 %live
            \\}}
        , .{if (alias) "store ptr %pointer, ptr %pointer, align 8" else "store i64 %value, ptr %pointer, align 8"});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var output = machine.MachineFunction.init("write", .{ .int = 64 });
        defer output.deinit(std.testing.allocator);
        try std.testing.expectEqual(selector.SelectionResult.selected, try selector.tryLower(std.testing.allocator, &output, module.functions.items[0]));
        try std.testing.expectEqual(machine.SelectionOwner.composed_cfg, output.selection_owner);
        try verify.verifyFunction(output);
        const bytes = try encoding.encodeFunction(std.testing.allocator, output);
        defer std.testing.allocator.free(bytes);
        const executable = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(executable);
        @memcpy(executable[0..bytes.len], bytes);
        const run: *const fn (*const *u64, u64, u64, u64) callconv(.c) u64 = @ptrCast(executable.ptr);
        const values = [_]u64{ 0, 1, 0xffffffff, 0x100000000, 0x8000000000000000, 0xdeadbeef12345678, std.math.maxInt(u64) };
        for (values) |value| for (values) |live| {
            var storage = [_]u64{ 123, 0, 456 };
            const pointer = &storage[1];
            try std.testing.expectEqual(live, run(&pointer, value, live, 0));
            try std.testing.expectEqual(@as(u64, 0), storage[1]);
            const expected = if (alias) @as(u64, @intFromPtr(pointer)) else value;
            try std.testing.expectEqual(expected ^ live, run(&pointer, value, live, 1));
            try std.testing.expectEqual(expected, storage[1]);
            try std.testing.expectEqual(@as(u64, 123), storage[0]);
            try std.testing.expectEqual(@as(u64, 456), storage[2]);
        };
    }
}

test "accumulator stores retain the sealed address register after source relocation" {
    var output = machine.MachineFunction.init("accumulator-store-relocated", .void);
    defer output.deinit(std.testing.allocator);
    var plan = support.SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "pointer", "value", "other", "witness" }) |name| try support.addLive(&plan, name);
    var state = support.ComposedBlockSelector.init(std.testing.allocator, &output);
    defer state.deinit();
    state.allocation_plan = &plan;
    state.current_position = 1;
    state.stack_frame_bytes = 128;
    try support.selector_state.bindValueLoc(&state, "pointer", .rax);
    try support.selector_state.bindValueLoc(&state, "value", .{ .scratch64 = .rcx });
    try support.selector_state.bindValueLoc(&state, "other", .{ .arg64 = .rdi });
    try support.selector_state.bindValueLoc(&state, "witness", .{ .scratch64 = .rdx });
    const value_before = state.values.get("value").?;
    const witness_before = state.values.get("witness").?;
    var transaction = try support.Transaction.begin(&state);
    defer transaction.deinit();
    const value = try transaction.register(support.preparedSourceRequest("value", .{ .int = 64 }, .gpr64, .gpr64));
    const action = try transaction.register(support.preparedRequest("pointer", .ptr, .gpr64, .pointer, .{ .store_i64 = .{ .value = value } }));
    _ = try transaction.register(support.request("other", .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = .rcx }));
    try transaction.seal();
    try std.testing.expectEqual(@as(?@import("../types.zig").ArgReg, .rdx), transaction.store_address_registers[action.index]);
    try transaction.prepare();
    try transaction.materializeAll();
    try std.testing.expect(state.values.get("value").?.loc != .scratch64);
    try transaction.executePreparedAction(try transaction.preparedView(action));
    try std.testing.expectEqual(machine.Instruction{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdx, .offset = 0 } }, output.instructions.items[output.instructions.items.len - 1]);
    try std.testing.expectEqual(value_before.vreg, state.values.get("value").?.vreg);
    try std.testing.expectEqual(witness_before.vreg, state.values.get("witness").?.vreg);
    try transaction.rollback();
    try std.testing.expectEqual(value_before, state.values.get("value").?);
    try std.testing.expectEqual(witness_before, state.values.get("witness").?);
    for (transaction.store_address_registers) |register| try std.testing.expectEqual(null, register);
    try std.testing.expectEqual(@as(usize, 0), output.instructions.items.len);
}
