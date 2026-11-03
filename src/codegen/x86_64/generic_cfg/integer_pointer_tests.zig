const std = @import("std");
const ir = @import("../../../ir.zig");
const encoding = @import("../../../mc/encoding.zig");
const machine = @import("../machine.zig");
const verify = @import("../verify.zig");
const selector = @import("../generic_cfg_selector.zig");
const support = @import("value_use/test_support.zig");

test "integer pointer action preserves live flags and rolls back a failed definition" {
    for ([_]bool{ false, true }) |fail| {
        var output = support.MachineFunction.init("integer-pointer-action", .void);
        defer output.deinit(std.testing.allocator);
        var plan = support.SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        inline for (&.{ "source", "witness", "pointer" }) |name| try support.addLive(&plan, name);
        var state = support.ComposedBlockSelector.init(std.testing.allocator, &output);
        defer state.deinit();
        state.allocation_plan = &plan;
        state.current_position = 1;
        state.stack_frame_bytes = 128;
        try support.selector_state.bindValueLoc(&state, "source", .{ .arg64 = .rdi });
        try support.selector_state.bindValueLoc(&state, "witness", .rax);
        try support.selector_state.emitEflagsInstruction(&state, .{ .cmp_eax_imm32 = 7 }, .definition);
        const flags = state.eflags.snapshot();
        const source = state.values.get("source").?;
        const witness = state.values.get("witness").?;
        var transaction = try support.Transaction.begin(&state);
        defer transaction.deinit();
        if (fail) transaction.scalar_cast_test_failure = .after_result_definition;
        const action = try transaction.register(support.preparedRequest("source", .{ .int = 64 }, .gpr64, .accumulator_scalar_cast_operand, .{ .accumulator_scalar_cast = .{
            .result = try support.actionIdentity("pointer"),
            .op = .inttoptr,
            .from_bits = 64,
            .to_bits = 64,
        } }));
        try transaction.seal();
        _ = try transaction.beginAccumulatorSession();
        try transaction.prepare();
        try transaction.materializeAll();
        if (fail) {
            try std.testing.expectError(error.ValueUseScalarCastTestFailure, transaction.executePreparedAction(try transaction.preparedView(action)));
            try std.testing.expectEqual(source, state.values.get("source").?);
            try std.testing.expectEqual(witness, state.values.get("witness").?);
            try std.testing.expect(!state.values.contains("pointer"));
            try std.testing.expectEqual(@as(usize, 1), output.instructions.items.len);
        } else {
            try transaction.executePreparedAction(try transaction.preparedView(action));
            try transaction.commit();
            try std.testing.expectEqual(source.vreg, state.values.get("source").?.vreg);
            try std.testing.expectEqual(witness.vreg, state.values.get("witness").?.vreg);
            try std.testing.expect(state.values.contains("pointer"));
            try std.testing.expect(state.values.get("witness").?.loc != .rax);
        }
        try state.eflags.validateSnapshot(flags);
    }
}

test "integer pointer aliases execute full-width roundtrips and pointer returns" {
    const bytes = try std.Io.Dir.cwd().readFileAlloc(std.testing.io, "test/real_programs/integer_pointer.ll", std.testing.allocator, .limited(1024 * 1024));
    defer std.testing.allocator.free(bytes);
    var module = try ir.Module.parse(std.testing.allocator, bytes);
    defer module.deinit();
    try module.verify();
    const ctx: machine.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout };
    const values = [_]u64{ 0, 1, 2147483648, 4294967295, 4294967296, 0x8000_0000_0000_0000, 0xffff_ffff_ffff_ffff, 0xdead_beef_0123_4567 };
    for (module.functions.items) |function| {
        const identity = std.mem.eql(u8, function.name, "integer_pointer_identity");
        if (!identity and !std.mem.eql(u8, function.name, "integer_pointer_roundtrip")) continue;
        var lowered = machine.MachineFunction.init(function.name, function.ret_ty);
        defer lowered.deinit(std.testing.allocator);
        switch (try selector.tryLowerWithContext(std.testing.allocator, &lowered, function, &ctx)) {
            .selected => {},
            .unsupported => |diagnostic| {
                std.debug.print("integer pointer selection {s}: {s}\n", .{ function.name, diagnostic.detail() });
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
        for (values) |bits| for (values) |live| {
            if (identity) {
                const run: *const fn (u64) callconv(.c) ?*anyopaque = @ptrCast(executable.ptr);
                try std.testing.expectEqual(bits, @intFromPtr(run(bits)));
            } else {
                const run: *const fn (u64, u64, *?*anyopaque) callconv(.c) u64 = @ptrCast(executable.ptr);
                var output: ?*anyopaque = undefined;
                try std.testing.expectEqual((bits +% bits) ^ live, run(bits, live, &output));
                try std.testing.expectEqual(bits, @intFromPtr(output));
            }
        };
    }
}

test "integer pointer casts reject unproved widths flags immediates and layouts" {
    const cases = [_]struct { from: []const u8, value: []const u8 = "%bits", layout: []const u8 = "e-p:64:64-i64:64", expected: []const u8, flag: bool = false }{
        .{ .from = "i32", .expected = "composed-block-inttoptr-form" },
        .{ .from = "i128", .expected = "composed-block-inttoptr-form" },
        .{ .from = "i64", .value = "0", .expected = "composed-block-inttoptr-form" },
        .{ .from = "i64", .layout = "e-p:32:32-i64:64", .expected = "composed-block-inttoptr-layout" },
        .{ .from = "i64", .flag = true, .expected = "composed-block-inttoptr-form" },
    };
    for (cases) |case| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "target datalayout = \"{s}\"\ndefine ptr @cast({s} %bits) {{\nentry:\n  %pointer = inttoptr {s} {s} to ptr\n  ret ptr %pointer\n}}\n", .{ case.layout, case.from, case.from, case.value });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        if (case.flag) module.functions.items[0].blocks.items[0].instructions.items[0].kind.cast.flags.nuw = true;
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

test "integer pointer nondefault targets remain a parser boundary" {
    const text =
        \\define void @nondefault(i64 %bits) {
        \\entry:
        \\  %pointer = inttoptr i64 %bits to ptr addrspace(1)
        \\  ret void
        \\}
    ;
    try std.testing.expectError(error.UnsupportedType, ir.Module.parse(std.testing.allocator, text));
}
