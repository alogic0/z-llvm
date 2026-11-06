const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const encoding = @import("../../../mc/encoding.zig");
const support = @import("value_use/test_support.zig");
const compare = @import("value_use/actions/control_compare.zig");

test "scratch comparison executes swapped operand homes with final uses and live aliases" {
    for ([_]u16{ 32, 64 }) |bits| for ([_]ir.IcmpPredicate{ .eq, .ne, .ult, .ule, .ugt, .uge, .slt, .sgt }) |predicate| for ([_]bool{ false, true }) |live| {
        var output = machine.MachineFunction.init("compare-cycle", .{ .int = 32 });
        defer output.deinit(std.testing.allocator);
        var plan = support.SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        for ([_][]const u8{ "lhs", "rhs", "lhs-alias", "rhs-alias" }) |name| try plan.interval_ends.put(name, if (live) 10 else 1);
        var state = support.ComposedBlockSelector.init(std.testing.allocator, &output);
        defer state.deinit();
        state.allocation_plan = &plan;
        state.stack_frame_bytes = 136;
        var transaction = try support.Transaction.begin(&state);
        defer transaction.deinit();
        const requests = try support.registerScratchCompare(&transaction, .{ .named = "lhs" }, .{ .named = .{ .named = "rhs" } }, "answer", .{ .int = bits }, predicate, false);
        const action = &transaction.requests[requests.lhs.index].prepared_action.?.scratch_compare;
        const selected = try compare.classifyScratchCompare(action);
        const lhs_home = selected.rhs_register.?;
        const rhs_home = selected.lhs_register;
        const lhs: support.ValueLoc = if (bits == 64) .{ .arg64 = lhs_home } else .{ .arg32 = lhs_home };
        const rhs: support.ValueLoc = if (bits == 64) .{ .arg64 = rhs_home } else .{ .arg32 = rhs_home };
        try support.selector_state.bindValueLoc(&state, "lhs", lhs);
        try support.selector_state.bindValueLoc(&state, "rhs", rhs);
        try support.selector_state.bindValueLoc(&state, "lhs-alias", lhs);
        try support.selector_state.bindValueLoc(&state, "rhs-alias", rhs);
        try output.instructions.appendSlice(std.testing.allocator, &.{
            .{ .sub_rsp_imm32 = 136 },
            .{ .mov_arg64_arg = .{ .dst = lhs_home, .src = .rdi } },
            .{ .mov_arg64_arg = .{ .dst = rhs_home, .src = .rsi } },
        });
        try transaction.seal();
        _ = try transaction.beginAccumulatorSession();
        try transaction.prepare();
        try transaction.materializeAll();
        try transaction.executePreparedAction(try transaction.preparedView(requests.lhs));
        try transaction.commit();
        try output.instructions.appendSlice(std.testing.allocator, &.{ .{ .add_rsp_imm32 = 136 }, .ret });
        const code = try encoding.encodeFunction(std.testing.allocator, output);
        defer std.testing.allocator.free(code);
        const executable = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(executable);
        @memcpy(executable[0..code.len], code);
        const run: *const fn (u64, u64) callconv(.c) u32 = @ptrCast(executable.ptr);
        const values = [_]u64{ 0, 1, 2, 0x7fff_ffff, 0x8000_0000, 0xffff_ffff, 0x7fff_ffff_ffff_ffff, 0x8000_0000_0000_0000, 0xffff_ffff_0000_0001, 0xffff_ffff_ffff_ffff };
        for (values) |a| for (values) |b| {
            const mask: u64 = if (bits == 64) std.math.maxInt(u64) else 0xffff_ffff;
            const x = a & mask;
            const y = b & mask;
            const signed_x: i64 = if (bits == 64) @bitCast(x) else @as(i32, @bitCast(@as(u32, @truncate(x))));
            const signed_y: i64 = if (bits == 64) @bitCast(y) else @as(i32, @bitCast(@as(u32, @truncate(y))));
            const expected = switch (predicate) {
                .eq => x == y,
                .ne => x != y,
                .ult => x < y,
                .ule => x <= y,
                .ugt => x > y,
                .uge => x >= y,
                .slt => signed_x < signed_y,
                .sgt => signed_x > signed_y,
                else => unreachable,
            };
            try std.testing.expectEqual(@as(u32, @intFromBool(expected)), run(a, b));
        };
    };
}
