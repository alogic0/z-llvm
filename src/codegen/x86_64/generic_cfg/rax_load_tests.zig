const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const verify = @import("../verify.zig");
const selector = @import("../generic_cfg_selector.zig");
const encoding = @import("../../../mc/encoding.zig");
const support = @import("value_use/test_support.zig");

test "RAX ordinary loads execute exact widths with dying and live pointers" {
    const Case = struct { ty: []const u8, conversion: []const u8, mask: u64 };
    const cases = [_]Case{
        .{ .ty = "i8", .conversion = "%value = zext i8 %loaded to i64", .mask = 0xff },
        .{ .ty = "i16", .conversion = "%value = zext i16 %loaded to i64", .mask = 0xffff },
        .{ .ty = "i32", .conversion = "%value = zext i32 %loaded to i64", .mask = 0xffffffff },
        .{ .ty = "i64", .conversion = "%value = add i64 %loaded, 0", .mask = std.math.maxInt(u64) },
        .{ .ty = "ptr", .conversion = "%value = ptrtoint ptr %loaded to i64", .mask = std.math.maxInt(u64) },
    };
    for (cases) |case| for ([_]bool{ false, true }) |live| {
        const text = try std.fmt.allocPrint(std.testing.allocator,
            \\define i64 @read(ptr %slot, i64 %take) {{
            \\entry:
            \\  %condition = icmp ne i64 %take, 0
            \\  br i1 %condition, label %load, label %empty
            \\load:
            \\  %pointer = load ptr, ptr %slot, align 8
            \\  %loaded = load {s}, ptr %pointer, align 8
            \\  {s}
            \\  {s}
            \\empty:
            \\  ret i64 0
            \\}}
        , .{ case.ty, case.conversion, if (live) "%address = ptrtoint ptr %pointer to i64\n  %result = xor i64 %value, %address\n  ret i64 %result" else "ret i64 %value" });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var output = machine.MachineFunction.init("read", .{ .int = 64 });
        defer output.deinit(std.testing.allocator);
        try std.testing.expectEqual(selector.SelectionResult.selected, try selector.tryLower(std.testing.allocator, &output, module.functions.items[0]));
        try std.testing.expectEqual(machine.SelectionOwner.composed_cfg, output.selection_owner);
        try verify.verifyFunction(output);
        const bytes = try encoding.encodeFunction(std.testing.allocator, output);
        defer std.testing.allocator.free(bytes);
        const executable = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(executable);
        @memcpy(executable[0..bytes.len], bytes);
        const run: *const fn (*const *const u64, u64) callconv(.c) u64 = @ptrCast(executable.ptr);
        for ([_]u64{ 0, 1, 0x80, 0x8000, 0x80000000, 0x8000000000000000, 0x123456789abcdef0, std.math.maxInt(u64) }) |value| {
            const storage = value;
            const pointer = &storage;
            const expected = (value & case.mask) ^ (if (live) @as(u64, @intFromPtr(pointer)) else 0);
            try std.testing.expectEqual(expected, run(&pointer, 1));
            try std.testing.expectEqual(expected, run(&pointer, std.math.maxInt(u64)));
            try std.testing.expectEqual(@as(u64, 0), run(&pointer, 0));
        }
    };
}

test "RAX ordinary load rejection retains width class and readonly restrictions" {
    const Case = struct { loc: support.ValueLoc, action: support.Transaction.PreparedAction, expected_error: anyerror };
    const cases = [_]Case{
        .{ .loc = .eax, .action = .{ .load_scalar = .{ .kind = .ordinary, .bits = 32 } }, .expected_error = error.ValueUseLoadOrdinaryPointerRejected },
        .{ .loc = .rax, .action = .{ .load_scalar = .{ .kind = .ordinary, .bits = 24 } }, .expected_error = error.ValueUseLoadOrdinaryPointerWidth },
        .{ .loc = .rax, .action = .{ .load_scalar = .{ .kind = .ordinary, .bits = 32, .is_ptr = true } }, .expected_error = error.ValueUseLoadOrdinaryPointerWidth },
        .{ .loc = .rax, .action = .{ .load_scalar = .{ .kind = .readonly_pointer, .bits = 64 } }, .expected_error = error.ValueUseLoadReadonlyPointerProvenance },
        .{ .loc = .rax, .action = .{ .load_stack_i128_alias = .{ .result = try support.actionIdentity("result") } }, .expected_error = error.ValueUseLoadOrdinaryPointerWidth },
    };
    for (cases) |case| {
        var output = machine.MachineFunction.init("rejected-load", .{ .int = 64 });
        defer output.deinit(std.testing.allocator);
        var plan = support.SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try support.addAtCurrent(&plan, "pointer");
        var state = support.ComposedBlockSelector.init(std.testing.allocator, &output);
        defer state.deinit();
        state.allocation_plan = &plan;
        try support.selector_state.bindValueLoc(&state, "pointer", case.loc);
        const before = state.values.get("pointer").?;
        var transaction = try support.Transaction.begin(&state);
        defer transaction.deinit();
        const action = try transaction.register(support.loadActionRequest("pointer", case.action));
        try std.testing.expectError(case.expected_error, transaction.seal());
        try std.testing.expect(transaction.failedRequestIs(action));
        try std.testing.expectEqual(before, state.values.get("pointer").?);
        try std.testing.expectEqual(@as(usize, 0), output.instructions.items.len);
    }
}

test "RAX ordinary loads roll back scratch staging accumulator preservation and result definition" {
    const Boundary = enum { staging, preservation, result };
    for ([_]Boundary{ .staging, .preservation, .result }) |boundary| for ([_]bool{ false, true }) |live| {
        var output = machine.MachineFunction.init("rollback-load", .{ .int = 64 });
        defer output.deinit(std.testing.allocator);
        var plan = support.SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        if (live) try support.addLive(&plan, "pointer") else try support.addAtCurrent(&plan, "pointer");
        try support.addLive(&plan, "scratch");
        var state = support.ComposedBlockSelector.init(std.testing.allocator, &output);
        defer state.deinit();
        state.allocation_plan = &plan;
        state.stack_frame_bytes = 128;
        try support.selector_state.bindValueLoc(&state, "pointer", .rax);
        try support.selector_state.bindValueLoc(&state, "scratch", .{ .scratch64 = .rcx });
        try state.eflags.apply(.definition);
        const pointer = state.values.get("pointer").?;
        const scratch = state.values.get("scratch").?;
        const domain = state.accumulator_domain;
        const flags = state.eflags.snapshot();
        const next_vreg = state.next_virtual_reg;
        const next_spill = state.next_spill_slot;
        var transaction = try support.Transaction.begin(&state);
        defer transaction.deinit();
        const action = try transaction.register(support.loadActionRequest("pointer", .{ .load_scalar = .{ .kind = .ordinary, .bits = 64 } }));
        try transaction.seal();
        const accumulator = try transaction.beginAccumulatorSession();
        try transaction.prepare();
        try transaction.materializeAll();
        if (boundary == .result) {
            try transaction.executePreparedAction(try transaction.preparedView(action));
            try transaction.defineAccumulatorResult(accumulator, "result", .fullRax());
            try transaction.finalizeAccumulatorResult(accumulator);
            try transaction.rollback();
        } else {
            try transaction.setLoadTestFailure(if (boundary == .staging) .after_pointer_staging else .after_preservation);
            try std.testing.expectError(error.ValueUseLoadTestFailure, transaction.executePreparedAction(try transaction.preparedView(action)));
        }
        try std.testing.expectEqual(pointer, state.values.get("pointer").?);
        try std.testing.expectEqual(scratch, state.values.get("scratch").?);
        try std.testing.expectEqualDeep(domain, state.accumulator_domain);
        try state.eflags.validateSnapshot(flags);
        try std.testing.expectEqual(next_vreg, state.next_virtual_reg);
        try std.testing.expectEqual(next_spill, state.next_spill_slot);
        try std.testing.expectEqual(@as(usize, 0), state.spill_slots.count());
        try std.testing.expectEqual(@as(usize, 0), output.instructions.items.len);
        try std.testing.expect(!state.values.contains("result"));
        try std.testing.expectError(error.ValueUseTransactionClosed, transaction.rollback());
    };
}

test "RAX ordinary load rejects conflicting staging writes before mutation" {
    var output = machine.MachineFunction.init("load-staging-conflict", .{ .int = 64 });
    defer output.deinit(std.testing.allocator);
    var plan = support.SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try support.addAtCurrent(&plan, "pointer");
    try support.addAtCurrent(&plan, "other");
    var state = support.ComposedBlockSelector.init(std.testing.allocator, &output);
    defer state.deinit();
    state.allocation_plan = &plan;
    try support.selector_state.bindValueLoc(&state, "pointer", .rax);
    try support.selector_state.bindValueLoc(&state, "other", .{ .arg64 = .rdi });
    const pointer = state.values.get("pointer").?;
    var transaction = try support.Transaction.begin(&state);
    defer transaction.deinit();
    _ = try transaction.register(support.loadActionRequest("pointer", .{ .load_scalar = .{ .kind = .ordinary, .bits = 32 } }));
    _ = try transaction.register(support.request("other", .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = .rcx }));
    try std.testing.expectError(error.ValueUseConflictingDestination, transaction.seal());
    try std.testing.expectEqual(pointer, state.values.get("pointer").?);
    try std.testing.expectEqual(@as(usize, 0), output.instructions.items.len);
}
