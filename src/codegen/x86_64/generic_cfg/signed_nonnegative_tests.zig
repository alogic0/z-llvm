const std = @import("std");
const ir = @import("../../../ir.zig");
const encoding = @import("../../../mc/encoding.zig");
const machine = @import("../machine.zig");
const verify = @import("../verify.zig");
const selector = @import("../generic_cfg_selector.zig");
const support = @import("value_use/test_support.zig");

test "signed nonnegative comparisons execute i32 i64 extrema with live values" {
    const bytes = try std.Io.Dir.cwd().readFileAlloc(std.testing.io, "test/real_programs/signed_nonnegative.ll", std.testing.allocator, .limited(1024 * 1024));
    defer std.testing.allocator.free(bytes);
    var module = try ir.Module.parse(std.testing.allocator, bytes);
    defer module.deinit();
    try module.verify();
    const ctx: machine.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout };
    const values32 = [_]i32{ std.math.minInt(i32), -65537, -1, 0, 1, 65535, std.math.maxInt(i32), std.math.minInt(i32) + 1 };
    const values64 = [_]i64{ std.math.minInt(i64), -4294967296, -1, 0, 1, std.math.maxInt(i32), 4294967296, std.math.maxInt(i64) };
    const lives = [_]u64{ 0, 1, 127, 128, std.math.maxInt(u32), 1 << 63, std.math.maxInt(u64), 0xdead_beef_0123_4567 };
    for (module.functions.items) |function| {
        const narrow = std.mem.eql(u8, function.name, "nonnegative_i32");
        if (!narrow and !std.mem.eql(u8, function.name, "nonnegative_i64")) continue;
        var lowered = machine.MachineFunction.init(function.name, function.ret_ty);
        defer lowered.deinit(std.testing.allocator);
        switch (try selector.tryLowerWithContext(std.testing.allocator, &lowered, function, &ctx)) {
            .selected => {},
            .unsupported => |diagnostic| {
                std.debug.print("signed nonnegative selection {s}: {s}\n", .{ function.name, diagnostic.detail() });
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
        for (0..values32.len) |index| for (lives) |live| {
            var output: u64 = undefined;
            const expected: u64 = @intFromBool(if (narrow) values32[index] >= 0 else values64[index] >= 0);
            const actual = if (narrow) blk: {
                const run: *const fn (i32, u64, *u64) callconv(.c) u64 = @ptrCast(executable.ptr);
                break :blk run(values32[index], live, &output);
            } else blk: {
                const run: *const fn (i64, u64, *u64) callconv(.c) u64 = @ptrCast(executable.ptr);
                break :blk run(values64[index], live, &output);
            };
            try std.testing.expectEqual(expected ^ live, actual);
            try std.testing.expectEqual(expected, output);
        };
    }
}

test "signed nonnegative action restores source aliases flags and output after failure" {
    inline for ([_]u16{ 32, 64 }) |bits| {
        inline for (std.meta.tags(support.Transaction.CurrentHomeSignBitTestFailure)) |boundary| {
            var output = support.MachineFunction.init("nonnegative-rollback", .{ .int = 1 });
            defer output.deinit(std.testing.allocator);
            var plan = support.SelectorAllocationPlan.init(std.testing.allocator);
            defer plan.deinit();
            inline for (&.{ "source", "witness", "condition" }) |name| try support.addLive(&plan, name);
            var state = support.ComposedBlockSelector.init(std.testing.allocator, &output);
            defer state.deinit();
            state.allocation_plan = &plan;
            state.current_position = 1;
            state.stack_frame_bytes = 128;
            try support.selector_state.bindValueLoc(&state, "source", if (bits == 32) .{ .arg32 = .rdi } else .{ .arg64 = .rdi });
            try support.selector_state.bindValueLoc(&state, "witness", .rax);
            try support.selector_state.emitEflagsInstruction(&state, .{ .cmp_eax_imm32 = 7 }, .definition);
            try state.eflags.apply(.use);
            const flags = state.eflags.snapshot();
            const source = state.values.get("source").?;
            const witness = state.values.get("witness").?;
            const next_vreg = state.next_virtual_reg;
            const next_spill = state.next_spill_slot;
            const domain = state.address_dependencies;
            var transaction = try support.Transaction.begin(&state);
            defer transaction.deinit();
            transaction.current_home_sign_bit_test_failure = boundary;
            const handle = try transaction.register(support.preparedRequest("source", .{ .int = bits }, if (bits == 32) .gpr32 else .gpr64, .current_home_sign_bit_operand, .{ .current_home_sign_bit = .{
                .result = try support.actionIdentity("condition"),
                .operand_ty = .{ .int = bits },
                .invert = true,
            } }));
            try transaction.seal();
            _ = try transaction.beginAccumulatorSession();
            try transaction.prepare();
            try transaction.materializeAll();
            try std.testing.expectError(error.ValueUseCurrentHomeSignBitTestFailure, transaction.executePreparedAction(try transaction.preparedView(handle)));
            try std.testing.expectEqual(source, state.values.get("source").?);
            try std.testing.expectEqual(witness, state.values.get("witness").?);
            try std.testing.expect(!state.values.contains("condition"));
            try std.testing.expectEqual(next_vreg, state.next_virtual_reg);
            try std.testing.expectEqual(next_spill, state.next_spill_slot);
            try std.testing.expectEqualDeep(domain, state.address_dependencies);
            try std.testing.expectEqual(@as(usize, 1), output.instructions.items.len);
            try std.testing.expectEqual(@as(usize, 1), state.eflags_semantics.items.len);
            try state.eflags.validateSnapshot(flags);
        }
    }
}

test "signed nonnegative classifier rejects unproved widths flags operands and constants" {
    const valid: ir.IcmpInst = .{ .predicate = .sge, .operand_ty = .{ .int = 32 }, .lhs = .{ .named = "source" }, .rhs = .{ .int = 0 } };
    for ([_]u16{ 1, 8, 16, 52, 128 }) |bits| {
        var cmp = valid;
        cmp.operand_ty = .{ .int = bits };
        try std.testing.expect(!support.Transaction.isCurrentHomeSignBitIcmp(cmp));
    }
    var cmp = valid;
    cmp.samesign = true;
    try std.testing.expect(!support.Transaction.isCurrentHomeSignBitIcmp(cmp));
    cmp = valid;
    cmp.rhs = .{ .int = -1 };
    try std.testing.expect(!support.Transaction.isCurrentHomeSignBitIcmp(cmp));
    cmp.rhs = .{ .named = "other" };
    try std.testing.expect(!support.Transaction.isCurrentHomeSignBitIcmp(cmp));
    cmp = valid;
    cmp.lhs = .{ .int = 0 };
    try std.testing.expect(!support.Transaction.isCurrentHomeSignBitIcmp(cmp));
}
