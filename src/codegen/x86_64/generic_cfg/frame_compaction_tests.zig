const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const state = @import("composed_selector_state.zig");
const compact = @import("frame_compaction.zig");
const encode = @import("../../../mc/encoding.zig");
const FrameIndex = @import("../types.zig").FrameIndex;

test "late spill homes remain disjoint from live owned objects across page boundaries" {
    const a = std.testing.allocator;
    var module = try ir.Module.parse(a, "define i64 @separate() {\nentry:\n %box = alloca [4 x i32],align 16\n ret i64 0\n}\n");
    defer module.deinit();
    try module.verify();
    for ([_]u32{ 72, 4088, 65528 }) |frame| {
        var output = machine.MachineFunction.init("separate", .{ .int = 64 });
        defer output.deinit(a);
        var selector = state.ComposedBlockSelector.init(a, &output);
        defer selector.deinit();
        selector.stack_frame_bytes = frame;
        selector.next_spill_slot = 7;
        selector.frame_setup_begin = 0;
        selector.frame_setup_end = 1;
        try state.bindValueLoc(&selector, "box", .{ .stack_i32_array = .{ .base_disp = 32, .len = 4 } });
        try output.instructions.appendSlice(a, &.{
            .{ .sub_rsp_imm32 = frame },
            .{ .mov_rsp_arg64 = .rcx },
            .{ .add_arg64_imm32 = .{ .reg = .rcx, .imm = 32 } },
            .{ .mov_imm_rax = 0x123456789abcdef },
            .store_rax_rcx_ptr,
            .{ .mov_imm_rax = 0xdeadbeef },
            .{ .spill_rax_rsp = try FrameIndex.fromSlot(8) },
            .{ .load_stack_disp32_rax = 32 },
            .{ .add_rsp_imm32 = frame },
            .ret,
        });
        try @import("../verify.zig").verifyFunction(output);
        try compact.compact(&selector, module.functions.items[0]);
        try std.testing.expectEqual(frame + 32, selector.stack_frame_bytes);
        try std.testing.expectEqual(frame + 32, output.instructions.items[output.instructions.items.len - 2].add_rsp_imm32);
        const bytes = try encode.encodeFunction(a, output);
        defer a.free(bytes);
        const memory = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(memory);
        @memcpy(memory[0..bytes.len], bytes);
        const run: *const fn () callconv(.c) u64 = @ptrCast(memory.ptr);
        try std.testing.expectEqual(@as(u64, 0x123456789abcdef), run());
    }
}

test "frame gap compaction executes rebased objects incoming words and biased private spills" {
    var module = try ir.Module.parse(std.testing.allocator, "define i64 @gap() {\nentry:\n %box = alloca [8 x i32], align 16\n ret i64 0\n}\n");
    defer module.deinit();
    var output = machine.MachineFunction.init("gap", .{ .int = 64 });
    defer output.deinit(std.testing.allocator);
    var selector = state.ComposedBlockSelector.init(std.testing.allocator, &output);
    defer selector.deinit();
    selector.stack_frame_bytes = 131112;
    selector.next_spill_slot = 4;
    selector.frame_setup_begin = 0;
    selector.frame_setup_end = 1;
    try state.bindValueLoc(&selector, "box", .{ .stack_i32_array = .{ .base_disp = 131072, .len = 8 } });
    try output.instructions.appendSlice(std.testing.allocator, &.{
        .{ .sub_rsp_imm32 = 131112 },
        .{ .spill_arg64_rsp = .{ .reg = .rdi, .frame_index = FrameIndex.slot0 } },
        .{ .mov_rsp_arg64 = .rcx },
        .{ .add_arg64_imm32 = .{ .reg = .rcx, .imm = 131072 } },
        .{ .mov_arg_rax = .rdi },
        .store_rax_rcx_ptr,
        .{ .load_stack_disp32_rax = 131072 },
        .{ .push_imm32 = 0 },
        .{ .push_imm32 = 0 },
        .{ .load_stack_disp32_arg64 = .{ .reg = .rdx, .disp = 131136 } },
        .{ .reload_rsp_rax = FrameIndex.slot4 },
        .{ .add_rsp_imm8 = 16 },
        .{ .binary_arg_rax = .{ .op = .xor, .reg = .rdx } },
        .{ .store_rax_arg_ptr_disp8 = .{ .reg = .rsi, .offset = 0 } },
        .{ .add_rsp_imm32 = 131112 },
        .ret,
    });
    try @import("../verify.zig").verifyFunction(output);
    try compact.compact(&selector, module.functions.items[0]);
    try std.testing.expectEqual(@as(u32, 56), selector.stack_frame_bytes);
    try std.testing.expectEqual(@as(i32, 16), output.instructions.items[3].add_arg64_imm32.imm);
    try std.testing.expectEqual(@as(u32, 80), output.instructions.items[9].load_stack_disp32_arg64.disp);
    try std.testing.expectEqual(FrameIndex.slot4, output.instructions.items[10].reload_rsp_rax);
    const bytes = try encode.encodeFunction(std.testing.allocator, output);
    defer std.testing.allocator.free(bytes);
    const memory = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(memory);
    @memcpy(memory[0..bytes.len], bytes);
    const run: *const fn (u64, *u64, u64, u64, u64, u64, u64) callconv(.c) u64 = @ptrCast(memory.ptr);
    for ([_]u64{ 0, 1, 0x0123456789abcdef, std.math.maxInt(u64) }) |input| for ([_]u64{ 0, 17, 0xfedcba9876543210 }) |last| {
        var observed: [3]u64 = @splat(0xa55aa55aa55aa55a);
        const expected = input ^ last;
        try std.testing.expectEqual(expected, run(input, &observed[1], 2, 3, 4, 5, last));
        try std.testing.expectEqual(expected, observed[1]);
        try std.testing.expectEqual(@as(u64, 0xa55aa55aa55aa55a), observed[0]);
        try std.testing.expectEqual(@as(u64, 0xa55aa55aa55aa55a), observed[2]);
    };
}

test "frame gap compaction retains opaque escapes and malformed stack regions" {
    var module = try ir.Module.parse(std.testing.allocator, "define void @gap() {\nentry:\n ret void\n}\n");
    defer module.deinit();
    const cases = [_][]const machine.Instruction{
        &.{ .{ .mov_rsp_arg64 = .rdi }, .ret },
        &.{ .{ .load_stack_rcx4_disp32_eax = 8 }, .ret },
        &.{ .{ .push_imm32 = 0 }, .{ .label = "unbalanced" }, .ret },
        &.{ .and_rsp_neg16, .ret },
    };
    for (cases) |body| {
        var output = machine.MachineFunction.init("gap", .void);
        defer output.deinit(std.testing.allocator);
        var selector = state.ComposedBlockSelector.init(std.testing.allocator, &output);
        defer selector.deinit();
        selector.stack_frame_bytes = 131080;
        selector.frame_setup_begin = 0;
        selector.frame_setup_end = 1;
        try output.instructions.append(std.testing.allocator, .{ .sub_rsp_imm32 = 131080 });
        try output.instructions.appendSlice(std.testing.allocator, body);
        const before = output.instructions.items.ptr;
        try compact.compact(&selector, module.functions.items[0]);
        try std.testing.expectEqual(@as(u32, 131080), selector.stack_frame_bytes);
        try std.testing.expectEqual(before, output.instructions.items.ptr);
    }
}

test "late spill separation preserves incoming words with temporary outgoing stack bias" {
    const a = std.testing.allocator;
    var module = try ir.Module.parse(a, "define i64 @incoming() {\nentry:\n %box = alloca [4 x i32],align 16\n ret i64 0\n}\n");
    defer module.deinit();
    var output = machine.MachineFunction.init("incoming", .{ .int = 64 });
    defer output.deinit(a);
    var selector = state.ComposedBlockSelector.init(a, &output);
    defer selector.deinit();
    selector.stack_frame_bytes = 72;
    selector.next_spill_slot = 7;
    selector.frame_setup_begin = 0;
    selector.frame_setup_end = 1;
    try state.bindValueLoc(&selector, "box", .{ .stack_i32_array = .{ .base_disp = 32, .len = 4 } });
    try output.instructions.appendSlice(a, &.{
        .{ .sub_rsp_imm32 = 72 },                                     .{ .mov_rsp_arg64 = .rcx },                          .{ .add_arg64_imm32 = .{ .reg = .rcx, .imm = 32 } },
        .{ .mov_arg_rax = .rdi },                                     .store_rax_rcx_ptr,                                  .{ .mov_imm_rax = 0xdeadbeef },
        .{ .spill_rax_rsp = try FrameIndex.fromSlot(8) },             .{ .push_imm32 = 0 },                                .{ .push_imm32 = 0 },
        .{ .load_stack_disp32_arg64 = .{ .reg = .rdx, .disp = 96 } }, .{ .reload_rsp_rax = try FrameIndex.fromSlot(24) },  .{ .add_rsp_imm8 = 16 },
        .{ .binary_arg_rax = .{ .op = .add, .reg = .rdi } },          .{ .binary_arg_rax = .{ .op = .xor, .reg = .rdx } }, .{ .load_stack_disp32_arg64 = .{ .reg = .rcx, .disp = 32 } },
        .{ .binary_arg_rax = .{ .op = .xor, .reg = .rcx } },          .{ .add_rsp_imm32 = 72 },                            .ret,
    });
    try compact.compact(&selector, module.functions.items[0]);
    try @import("../verify.zig").verifyFunction(output);
    const bytes = try encode.encodeFunction(a, output);
    defer a.free(bytes);
    const memory = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(memory);
    @memcpy(memory[0..bytes.len], bytes);
    const run: *const fn (u64, u64, u64, u64, u64, u64, u64) callconv(.c) u64 = @ptrCast(memory.ptr);
    for ([_]u64{ 0, 1, 0x9182736455aaccdd, std.math.maxInt(u64) }) |input| for ([_]u64{ 0, 17, 0xfedcba9876543210 }) |last| {
        try std.testing.expectEqual(((last +% input) ^ last) ^ input, run(input, 2, 3, 4, 5, 6, last));
    };
}

test "late spill separation keeps safe streams exact and rejects opaque or oversized repairs" {
    const a = std.testing.allocator;
    var module = try ir.Module.parse(a, "define void @closed() {\nentry:\n %box = alloca [4 x i32],align 16\n ret void\n}\n");
    defer module.deinit();
    for (0..3) |variant| {
        var output = machine.MachineFunction.init("closed", .void);
        defer output.deinit(a);
        var selector = state.ComposedBlockSelector.init(a, &output);
        defer selector.deinit();
        const frame: u32 = if (variant == 2) @import("selector_types.zig").max_stack_frame_bytes - 8 else 72;
        selector.stack_frame_bytes = frame;
        selector.next_spill_slot = if (variant == 0) 4 else 7;
        selector.frame_setup_begin = 0;
        selector.frame_setup_end = 1;
        try state.bindValueLoc(&selector, "box", .{ .stack_i32_array = .{ .base_disp = 32, .len = 4 } });
        try output.instructions.appendSlice(a, &.{ .{ .sub_rsp_imm32 = frame }, .mov_rsp_rdi, .{ .add_rsp_imm32 = frame }, .ret });
        const before = output.instructions.items.ptr;
        if (variant == 0) try compact.compact(&selector, module.functions.items[0]) else if (variant == 1) try std.testing.expectError(error.OpaqueStackUse, compact.compact(&selector, module.functions.items[0])) else try std.testing.expectError(error.InvalidFrameSetup, compact.compact(&selector, module.functions.items[0]));
        try std.testing.expectEqual(before, output.instructions.items.ptr);
        try std.testing.expectEqual(frame, selector.stack_frame_bytes);
        try std.testing.expectEqual(frame, output.instructions.items[0].sub_rsp_imm32);
    }
}

test "late spill separation distinguishes private and incoming stack argument sources" {
    const a = std.testing.allocator;
    var module = try ir.Module.parse(a, "define i64 @argument_sources() {\nentry:\n %box = alloca [4 x i32],align 16\n ret i64 0\n}\n");
    defer module.deinit();
    var output = machine.MachineFunction.init("argument_sources", .{ .int = 64 });
    defer output.deinit(a);
    var selector = state.ComposedBlockSelector.init(a, &output);
    defer selector.deinit();
    selector.stack_frame_bytes = 72;
    selector.next_spill_slot = 7;
    selector.frame_setup_begin = 0;
    selector.frame_setup_end = 1;
    try state.bindValueLoc(&selector, "box", .{ .stack_i32_array = .{ .base_disp = 32, .len = 4 } });
    try output.instructions.appendSlice(a, &.{
        .{ .sub_rsp_imm32 = 72 },                            .{ .mov_rsp_arg64 = .rcx },                                   .{ .add_arg64_imm32 = .{ .reg = .rcx, .imm = 32 } },
        .{ .mov_arg_rax = .rdi },                            .store_rax_rcx_ptr,                                           .{ .mov_imm_rax = 0xdeadbeef },
        .{ .spill_rax_rsp = try FrameIndex.fromSlot(8) },    .{ .push_stack_disp32 = 32 },                                 .{ .push_stack_disp32 = 88 },
        .{ .pop_arg = .rdx },                                .{ .pop_arg = .rcx },                                         .{ .mov_arg_rax = .rcx },
        .{ .binary_arg_rax = .{ .op = .xor, .reg = .rdx } }, .{ .load_stack_disp32_arg64 = .{ .reg = .rcx, .disp = 32 } }, .{ .binary_arg_rax = .{ .op = .xor, .reg = .rcx } },
        .{ .add_rsp_imm32 = 72 },                            .ret,
    });
    try compact.compact(&selector, module.functions.items[0]);
    const bytes = try encode.encodeFunction(a, output);
    defer a.free(bytes);
    const memory = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(memory);
    @memcpy(memory[0..bytes.len], bytes);
    const run: *const fn (u64, u64, u64, u64, u64, u64, u64) callconv(.c) u64 = @ptrCast(memory.ptr);
    for ([_]u64{ 0, 1, 0x9182736455aaccdd, std.math.maxInt(u64) }) |input| for ([_]u64{ 0, 17, 0xfedcba9876543210 }) |last| {
        try std.testing.expectEqual(@as(u64, 0xdeadbeef) ^ last ^ input, run(input, 2, 3, 4, 5, 6, last));
    };
}
