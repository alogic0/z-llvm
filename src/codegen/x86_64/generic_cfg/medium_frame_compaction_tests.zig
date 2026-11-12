const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const state = @import("composed_selector_state.zig");
const compact = @import("frame_compaction.zig");
const FrameIndex = @import("../types.zig").FrameIndex;

test "medium frame compaction preserves objects incoming words and outgoing bias" {
    var module = try ir.Module.parse(std.testing.allocator, "define i64 @medium() {\nentry:\n %box = alloca [8 x i32], align 16\n ret i64 0\n}\n");
    defer module.deinit();
    for ([_]u32{ 32760, 49192, 65528 }) |old_frame| {
        const object_base = old_frame - 40;
        var output = machine.MachineFunction.init("medium", .{ .int = 64 });
        defer output.deinit(std.testing.allocator);
        var selector = state.ComposedBlockSelector.init(std.testing.allocator, &output);
        defer selector.deinit();
        selector.stack_frame_bytes = old_frame;
        selector.next_spill_slot = 4;
        selector.frame_setup_begin = 0;
        selector.frame_setup_end = 1;
        try state.bindValueLoc(&selector, "box", .{ .stack_i32_array = .{ .base_disp = object_base, .len = 8 } });
        try output.instructions.appendSlice(std.testing.allocator, &.{
            .{ .sub_rsp_imm32 = old_frame },
            .{ .spill_arg64_rsp = .{ .reg = .rdi, .frame_index = FrameIndex.slot0 } },
            .{ .mov_rsp_arg64 = .rcx },
            .{ .add_arg64_imm32 = .{ .reg = .rcx, .imm = @intCast(object_base) } },
            .{ .mov_arg_rax = .rdi },
            .store_rax_rcx_ptr,
            .{ .load_stack_disp32_rax = object_base },
            .{ .push_imm32 = 0 },
            .{ .push_imm32 = 0 },
            .{ .load_stack_disp32_arg64 = .{ .reg = .rdx, .disp = old_frame + 24 } },
            .{ .reload_rsp_rax = FrameIndex.slot4 },
            .{ .add_rsp_imm8 = 16 },
            .{ .binary_arg_rax = .{ .op = .xor, .reg = .rdx } },
            .{ .store_rax_arg_ptr_disp8 = .{ .reg = .rsi, .offset = 0 } },
            .{ .add_rsp_imm32 = old_frame },
            .ret,
        });
        try @import("../verify.zig").verifyFunction(output);
        try compact.compact(&selector, module.functions.items[0]);
        try std.testing.expectEqual(if (old_frame < 32768) old_frame else @as(u32, 56), selector.stack_frame_bytes);
        try @import("../verify.zig").verifyFunction(output);
        const bytes = try @import("../../../mc/encoding.zig").encodeFunction(std.testing.allocator, output);
        defer std.testing.allocator.free(bytes);
        const code = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(code);
        @memcpy(code[0..bytes.len], bytes);
        const run: *const fn (u64, *u64, u64, u64, u64, u64, u64) callconv(.c) u64 = @ptrCast(code.ptr);
        for ([_]u64{ 0, 1, 0x0123456789abcdef, std.math.maxInt(u64) }) |x| for ([_]u64{ 0, 17, 0xfedcba9876543210 }) |last| {
            var out: [3]u64 = @splat(0xa5a5a5a5a5a5a5a5);
            try std.testing.expectEqual(x ^ last, run(x, &out[1], 2, 3, 4, 5, last));
            try std.testing.expectEqual(x ^ last, out[1]);
            try std.testing.expectEqual(@as(u64, 0xa5a5a5a5a5a5a5a5), out[0]);
            try std.testing.expectEqual(out[0], out[2]);
        };
    }
}

test "medium frame compaction keeps private escapes indexed uses and unbalanced regions closed" {
    var module = try ir.Module.parse(std.testing.allocator, "define void @medium() {\nentry:\n ret void\n}\n");
    defer module.deinit();
    for ([_][]const machine.Instruction{
        &.{ .{ .mov_rsp_arg64 = .rdi }, .ret },
        &.{ .{ .load_stack_rcx4_disp32_eax = 8 }, .ret },
        &.{ .{ .push_imm32 = 0 }, .{ .label = "unbalanced" }, .ret },
        &.{ .and_rsp_neg16, .ret },
    }) |body| {
        var output = machine.MachineFunction.init("medium", .void);
        defer output.deinit(std.testing.allocator);
        var selector = state.ComposedBlockSelector.init(std.testing.allocator, &output);
        defer selector.deinit();
        selector.stack_frame_bytes = 49160;
        selector.frame_setup_begin = 0;
        selector.frame_setup_end = 1;
        try output.instructions.append(std.testing.allocator, .{ .sub_rsp_imm32 = 49160 });
        try output.instructions.appendSlice(std.testing.allocator, body);
        const before = output.instructions.items.ptr;
        try compact.compact(&selector, module.functions.items[0]);
        try std.testing.expectEqual(@as(u32, 49160), selector.stack_frame_bytes);
        try std.testing.expectEqual(before, output.instructions.items.ptr);
    }
}
