const table_descriptions = @import("../constant_table.zig").Description;
const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const verify = @import("../verify.zig");
const selector = @import("../generic_cfg_selector.zig");
const encoding = @import("../../../mc/encoding.zig");
const support = @import("value_use/test_support.zig");
const memory = @import("composed_selector_memory.zig");

test "general array strides execute all 255 scales against wrapping multiplication" {
    for (1..256) |scale| {
        const text = try std.fmt.allocPrint(std.testing.allocator,
            \\define i64 @address(ptr %base, i64 %index) {{
            \\entry:
            \\  %p = getelementptr [{d} x i8], ptr %base, i64 %index
            \\  %bits = ptrtoint ptr %p to i64
            \\  ret i64 %bits
            \\}}
        , .{scale});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var output = machine.MachineFunction.init("address", .{ .int = 64 });
        defer output.deinit(std.testing.allocator);
        try std.testing.expectEqual(selector.SelectionResult.selected, try selector.tryLower(std.testing.allocator, &output, module.functions.items[0]));
        try verify.verifyFunction(output);
        try std.testing.expect(output.selection_owner == .composed_block or output.selection_owner == .composed_cfg);
        const bytes = try encoding.encodeFunction(std.testing.allocator, output);
        defer std.testing.allocator.free(bytes);
        const executable = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(executable);
        @memcpy(executable[0..bytes.len], bytes);
        const run: *const fn (u64, u64) callconv(.c) u64 = @ptrCast(executable.ptr);
        for ([_]u64{ 0, 1, 4096, std.math.maxInt(u64), 0x8000000000000000 }) |base|
            for ([_]u64{ 0, 1, 2, 3, 7, std.math.maxInt(u64), std.math.maxInt(u64) - 1, 0x8000000000000000, 0x123456789abcdef0 }) |index|
                try std.testing.expectEqual(base +% (index *% @as(u64, scale)), run(base, index));
    }
}

test "general array strides preserve descriptor and readonly table restrictions before mutation" {
    const locations = [_]support.ValueLoc{
        .{ .stack_i32_array = .{ .base_disp = 32, .len = 6 } },
        .{ .stack_i32_ptr = .{ .disp = 32 } },
    };
    for (locations) |location| {
        var output = machine.MachineFunction.init("descriptor-boundary", .ptr);
        defer output.deinit(std.testing.allocator);
        var plan = support.SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        inline for (&.{ "base", "index", "result" }) |name| try support.addLive(&plan, name);
        var state = support.ComposedBlockSelector.init(std.testing.allocator, &output);
        defer state.deinit();
        state.allocation_plan = &plan;
        state.stack_frame_bytes = 128;
        try support.selector_state.bindValueLoc(&state, "base", location);
        try support.selector_state.bindValueLoc(&state, "index", .{ .arg64 = .r8 });
        const original = state.values.get("base").?;
        var transaction = try support.Transaction.begin(&state);
        defer transaction.deinit();
        const index = try transaction.register(support.preparedSourceRequest("index", .{ .int = 64 }, .gpr64, .gpr64));
        const array = location == .stack_i32_array;
        _ = try transaction.register(support.preparedRequest("base", .ptr, if (array) .stack_object else .stack_pointer, if (array) .stack_object_address else .pointer, .{ .form_scaled_address = .{
            .result = try support.actionIdentity("result"),
            .index = .{ .request = index },
            .scale = 56,
        } }));
        try std.testing.expectError(error.ValueUseAddressDescriptorScaleMismatch, transaction.seal());
        try std.testing.expectEqual(original, state.values.get("base").?);
        try std.testing.expect(!state.values.contains("result"));
        try std.testing.expectEqual(@as(usize, 0), output.instructions.items.len);
    }
    var output = machine.MachineFunction.init("scale-boundaries", .ptr);
    defer output.deinit(std.testing.allocator);
    var state = support.ComposedBlockSelector.init(std.testing.allocator, &output);
    defer state.deinit();
    var transaction = try support.Transaction.begin(&state);
    defer transaction.deinit();
    try std.testing.expectError(error.ValueUseAddressScaleInvalid, transaction.register(support.preparedRequest("base", .ptr, .gpr64, .pointer, .{ .form_scaled_address = .{
        .result = try support.actionIdentity("result"),
        .index = .{ .constant = 1 },
        .scale = 0,
    } })));
    try std.testing.expectError(error.ValueUseAddressScaleInvalid, transaction.register(support.preparedRequest("index", .{ .int = 64 }, .gpr64, .gpr64, .{ .form_readonly_table_address = .{
        .result = try support.actionIdentity("result"),
        .symbol = try support.actionIdentity("table"),
        .shape = table_descriptions.f64_16,
        .scale = 3,
    } })));
    try std.testing.expectEqual(@as(usize, 0), output.instructions.items.len);
}

test "general array strides roll back live sources and EFLAGS on rejected writes" {
    for ([_][]const u8{ "[3 x i8]", "[56 x i8]", "[255 x i8]" }) |shape| {
        var output = machine.MachineFunction.init("general-stride-rollback", .ptr);
        defer output.deinit(std.testing.allocator);
        var plan = support.SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        inline for (&.{ "base", "index", "result" }) |name| try support.addLive(&plan, name);
        var state = support.ComposedBlockSelector.init(std.testing.allocator, &output);
        defer state.deinit();
        state.allocation_plan = &plan;
        state.stack_frame_bytes = 128;
        try support.selector_state.bindValueLoc(&state, "base", .{ .arg64 = .rcx });
        try support.selector_state.bindValueLoc(&state, "index", .{ .arg64 = .r8 });
        try state.eflags.apply(.definition);
        const flags = state.eflags.snapshot();
        const base = state.values.get("base").?;
        const index = state.values.get("index").?;
        const next_vreg = state.next_virtual_reg;
        const next_spill = state.next_spill_slot;
        var indices = [_]ir.GepIndex{.{ .ty = .{ .int = 64 }, .value = .{ .named = "index" } }};
        try std.testing.expectError(error.EflagsClobberedWhileLive, memory.lowerGep(&state, "result", .{
            .source_ty = .{ .aggregate = shape },
            .ptr = .{ .named = "base" },
            .indices = .fromOwnedSlice(&indices),
        }));
        try std.testing.expectEqual(base, state.values.get("base").?);
        try std.testing.expectEqual(index, state.values.get("index").?);
        try std.testing.expectEqual(next_vreg, state.next_virtual_reg);
        try std.testing.expectEqual(next_spill, state.next_spill_slot);
        try std.testing.expectEqual(@as(usize, 0), output.instructions.items.len);
        try std.testing.expectEqual(@as(usize, 0), state.spill_slots.count());
        try std.testing.expect(!state.values.contains("result"));
        try state.eflags.validateSnapshot(flags);
    }
}
