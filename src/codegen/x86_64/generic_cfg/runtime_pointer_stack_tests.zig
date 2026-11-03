const std = @import("std");
const ir = @import("../../../ir.zig");
const encoding = @import("../../../mc/encoding.zig");
const machine = @import("../machine.zig");
const verify = @import("../verify.zig");
const selector = @import("../generic_cfg_selector.zig");
const support = @import("value_use/test_support.zig");

test "runtime pointer stack stores preserve source ownership live aliases and flags" {
    const homes = [_]support.ValueLoc{ .{ .arg64 = .rdi }, .{ .scratch64 = .rcx }, .{ .spill64 = .slot4 }, .rax };
    for (homes) |home| {
        var output = support.MachineFunction.init("runtime-pointer-stack", .void);
        defer output.deinit(std.testing.allocator);
        var plan = support.SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try support.addLive(&plan, "value");
        try support.addLive(&plan, "witness");
        try support.addAtCurrent(&plan, "slot");
        var state = support.ComposedBlockSelector.init(std.testing.allocator, &output);
        defer state.deinit();
        state.allocation_plan = &plan;
        state.current_position = 1;
        state.stack_frame_bytes = 128;
        try support.selector_state.bindValueLoc(&state, "value", home);
        try support.selector_state.bindValueLoc(&state, "witness", .rax);
        try support.selector_state.bindValueLoc(&state, "slot", .{ .stack_scalar = .{ .base_disp = 32, .bits = 64, .kind = .integer } });
        const value_id = state.values.get("value").?.vreg;
        const witness_id = state.values.get("witness").?.vreg;
        try support.selector_state.emitEflagsInstruction(&state, .{ .cmp_eax_imm32 = 7 }, .definition);
        const flags = state.eflags.snapshot();
        var transaction = try support.Transaction.begin(&state);
        defer transaction.deinit();
        const value = try transaction.register(support.preparedSourceRequest("value", .ptr, .gpr64, .pointer));
        const action = try transaction.register(support.preparedRequest("slot", .ptr, .stack_object, .stack_object_address, .{ .store_i64 = .{ .value = value } }));
        try transaction.seal();
        try transaction.prepare();
        try transaction.materializeAll();
        try transaction.executePreparedAction(try transaction.preparedView(action));
        try transaction.commit();
        try std.testing.expectEqual(value_id, state.values.get("value").?.vreg);
        try std.testing.expectEqual(witness_id, state.values.get("witness").?.vreg);
        if (home != .rax) try std.testing.expect(state.values.get("witness").?.loc != .rax);
        try state.eflags.validateSnapshot(flags);
        try std.testing.expectEqual(machine.Instruction{ .spill_rax_rsp = .slot8 }, output.instructions.items[output.instructions.items.len - 1]);
    }
}

test "runtime pointer stack stores reject invalid destinations before mutation" {
    const invalid = [_]struct { bits: u16, kind: support.selector_types.StackScalarLoc.Kind, offset: u32, expected: anyerror }{
        .{ .bits = 32, .kind = .integer, .offset = 32, .expected = error.ValueUseStorePointerFormUnsupported },
        .{ .bits = 64, .kind = .fp, .offset = 32, .expected = error.ValueUseStorePointerFormUnsupported },
        .{ .bits = 64, .kind = .integer, .offset = 33, .expected = error.ValueUseStorePointerAlignment },
        .{ .bits = 64, .kind = .integer, .offset = 128, .expected = error.ValueUseStorePointerFrame },
    };
    for (invalid) |case| {
        var output = support.MachineFunction.init("runtime-pointer-stack-reject", .void);
        defer output.deinit(std.testing.allocator);
        var plan = support.SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        inline for (&.{ "value", "slot" }) |name| try support.addAtCurrent(&plan, name);
        var state = support.ComposedBlockSelector.init(std.testing.allocator, &output);
        defer state.deinit();
        state.allocation_plan = &plan;
        state.stack_frame_bytes = 128;
        try support.selector_state.bindValueLoc(&state, "value", .{ .arg64 = .rdi });
        try support.selector_state.bindValueLoc(&state, "slot", .{ .stack_scalar = .{ .base_disp = case.offset, .bits = case.bits, .kind = case.kind } });
        const saved = state.values.get("value").?;
        var transaction = try support.Transaction.begin(&state);
        defer transaction.deinit();
        const value = try transaction.register(support.preparedSourceRequest("value", .ptr, .gpr64, .pointer));
        const action = try transaction.register(support.preparedRequest("slot", .ptr, .stack_object, .stack_object_address, .{ .store_i64 = .{ .value = value } }));
        if (case.expected == error.ValueUseStorePointerFrame) {
            try transaction.seal();
            try transaction.prepare();
            try transaction.materializeAll();
            try std.testing.expectError(case.expected, transaction.executePreparedAction(try transaction.preparedView(action)));
        } else try std.testing.expectError(case.expected, transaction.seal());
        try std.testing.expectEqual(saved, state.values.get("value").?);
        try std.testing.expectEqual(@as(usize, 0), output.instructions.items.len);
    }
}

test "runtime pointer stack values execute with full-width live values" {
    const bytes = try std.Io.Dir.cwd().readFileAlloc(std.testing.io, "test/real_programs/runtime_pointer_stack.ll", std.testing.allocator, .limited(1024 * 1024));
    defer std.testing.allocator.free(bytes);
    var module = try ir.Module.parse(std.testing.allocator, bytes);
    defer module.deinit();
    try module.verify();
    const ctx: machine.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout };
    var buffer: [64]u8 = @splat(0);
    const pointers = [_]?*anyopaque{ null, &buffer, &buffer[1], &buffer[63] };
    const lives = [_]u64{ 0, 1, 0xffff_ffff, 0xffff_ffff_ffff_ffff, 0x8000_0000_0000_0000 };
    for (module.functions.items) |function| {
        if (!std.mem.eql(u8, function.name, "pointer_stack_roundtrip")) continue;
        var lowered = machine.MachineFunction.init(function.name, function.ret_ty);
        defer lowered.deinit(std.testing.allocator);
        switch (try selector.tryLowerWithContext(std.testing.allocator, &lowered, function, &ctx)) {
            .selected => {},
            .unsupported => |diagnostic| {
                std.debug.print("runtime pointer stack selection {s}: {s}\n", .{ function.name, diagnostic.detail() });
                return error.TestUnexpectedResult;
            },
        }
        try verify.verifyFunction(lowered);
        try std.testing.expect(lowered.selection_owner == .composed_block or lowered.selection_owner == .composed_cfg);
        const code = try encoding.encodeFunction(std.testing.allocator, lowered);
        defer std.testing.allocator.free(code);
        const executable = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(executable);
        @memcpy(executable[0..code.len], code);
        for (pointers) |pointer| for (lives) |live| {
            const run: *const fn (?*anyopaque, u64, *?*anyopaque) callconv(.c) u64 = @ptrCast(executable.ptr);
            var stored: ?*anyopaque = undefined;
            try std.testing.expectEqual(@intFromPtr(pointer) ^ live, run(pointer, live, &stored));
            try std.testing.expectEqual(pointer, stored);
        };
    }
}

test "scalar stack stores execute full-width constants values and literal null" {
    const bytes = try std.Io.Dir.cwd().readFileAlloc(std.testing.io, "test/real_programs/scalar_stack_memory.ll", std.testing.allocator, .limited(1024 * 1024));
    defer std.testing.allocator.free(bytes);
    var module = try ir.Module.parse(std.testing.allocator, bytes);
    defer module.deinit();
    try module.verify();
    const ctx: machine.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout };
    const values = [_]u64{ 0, 2147483648, 4294967295, 4294967296, 0x7fff_ffff_ffff_ffff, 0x8000_0000_0000_0000, 0xffff_ffff_ffff_ffff, 0xdead_beef_0123_4567 };
    for (module.functions.items) |function| {
        var lowered = machine.MachineFunction.init(function.name, function.ret_ty);
        defer lowered.deinit(std.testing.allocator);
        switch (try selector.tryLowerWithContext(std.testing.allocator, &lowered, function, &ctx)) {
            .selected => {},
            .unsupported => |diagnostic| {
                std.debug.print("scalar stack selection {s}: {s}\n", .{ function.name, diagnostic.detail() });
                return error.TestUnexpectedResult;
            },
        }
        try verify.verifyFunction(lowered);
        const code = try encoding.encodeFunction(std.testing.allocator, lowered);
        defer std.testing.allocator.free(code);
        const executable = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(executable);
        @memcpy(executable[0..code.len], code);
        if (std.mem.eql(u8, function.name, "scalar_stack_roundtrip")) {
            const run: *const fn (u64, u64, *u64) callconv(.c) u64 = @ptrCast(executable.ptr);
            for (values) |value| for (values) |live| {
                var stored: u64 = undefined;
                try std.testing.expectEqual(value ^ live, run(value, live, &stored));
                try std.testing.expectEqual(value, stored);
            };
        } else if (std.mem.eql(u8, function.name, "scalar_stack_constants")) {
            const run: *const fn (*[16]u64) callconv(.c) void = @ptrCast(executable.ptr);
            var stored: [16]u64 = @splat(0);
            run(&stored);
            try std.testing.expectEqualSlices(u64, &values, stored[0..8]);
            try std.testing.expectEqualSlices(u64, &values, stored[8..16]);
        } else {
            const run: *const fn (*?*anyopaque) callconv(.c) u64 = @ptrCast(executable.ptr);
            var stored: ?*anyopaque = &module;
            try std.testing.expectEqual(@as(u64, 0), run(&stored));
            try std.testing.expect(stored == null);
        }
    }
}

test "scalar frame stores reject nondefault address spaces and pointer layouts" {
    const cases = [_]struct { text: []const u8, expected: []const u8 }{
        .{
            .text =
            \\target datalayout = "e-p:64:64-p1:32:32-i64:64-n8:16:32:64-S128"
            \\define i64 @nondefault(i64 %value) {
            \\entry:
            \\  %slot = alloca i64, align 8, addrspace(1)
            \\  store i64 %value, ptr addrspace(1) %slot, align 8
            \\  %loaded = load i64, ptr addrspace(1) %slot, align 8
            \\  ret i64 %loaded
            \\}
            ,
            .expected = "composed-block-store-stack-addrspace",
        },
        .{
            .text =
            \\target datalayout = "e-p:32:32-i64:64-n8:16:32:64-S128"
            \\define i64 @pointer32(ptr %value) {
            \\entry:
            \\  %slot = alloca ptr, align 8
            \\  store ptr %value, ptr %slot, align 8
            \\  ret i64 0
            \\}
            ,
            .expected = "composed-block-store-stack-pointer-layout",
        },
    };
    for (cases) |case| {
        var module = try ir.Module.parse(std.testing.allocator, case.text);
        defer module.deinit();
        try module.verify();
        const ctx: machine.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout };
        const function = module.functions.items[0];
        var lowered = machine.MachineFunction.init(function.name, function.ret_ty);
        defer lowered.deinit(std.testing.allocator);
        switch (try selector.tryLowerWithContext(std.testing.allocator, &lowered, function, &ctx)) {
            .selected => return error.TestUnexpectedResult,
            .unsupported => |diagnostic| try std.testing.expectEqualStrings(case.expected, diagnostic.detail()),
        }
    }
}
