const std = @import("std");
const homes = @import("machine_stack_homes.zig");
const machine = @import("../machine.zig");
const FrameIndex = @import("../types.zig").FrameIndex;
const old_frame = 131080;
const object_base = old_frame - 8;
const first: FrameIndex = .{ .slot = 100 };
const second: FrameIndex = .{ .slot = 20000 };

fn run(code: []const machine.Instruction, frame_bytes: u32) !u32 {
    var function = machine.MachineFunction.init("machine_home_test", .{ .int = 32 });
    defer function.deinit(std.testing.allocator);
    try function.instructions.append(std.testing.allocator, .{ .sub_rsp_imm32 = frame_bytes });
    try function.instructions.appendSlice(std.testing.allocator, code);
    try @import("../verify.zig").verifyFunction(function);
    const bytes = try @import("../../../mc/encoding.zig").encodeFunction(std.testing.allocator, function);
    defer std.testing.allocator.free(bytes);
    const memory = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(memory);
    @memcpy(memory[0..bytes.len], bytes);
    const call: *const fn () callconv(.c) u32 = @ptrCast(memory.ptr);
    return call();
}

test "machine spill coloring executes disjoint stores and keeps source offsets immutable" {
    var code = [_]machine.Instruction{
        .{ .mov_imm_eax = 13 },        .{ .spill_eax_rsp = first },                         .{ .reload_rsp_eax = first },
        .{ .mov_eax_to_arg = .rdi },   .{ .mov_imm_eax = 29 },                              .{ .spill_eax_rsp = second },
        .{ .reload_rsp_eax = second }, .{ .binary_arg_eax = .{ .op = .add, .reg = .rdi } }, .{ .add_rsp_imm32 = old_frame },
        .ret,
    };
    try std.testing.expectEqual(@as(u32, 42), try run(&code, old_frame));
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const result = (try homes.analyze(arena.allocator(), &code, old_frame, object_base)) orelse return error.ExpectedMapping;
    try std.testing.expectEqual(result.mapping[first.slot], result.mapping[second.slot]);
    try std.testing.expectEqual(@as(u32, 400) % 16, result.mapping[first.slot] % 16);
    try std.testing.expectEqual(first, code[1].spill_eax_rsp);
    try std.testing.expectEqual(second, code[5].spill_eax_rsp);
    try homes.rewrite(&code, old_frame, result);
    try std.testing.expect(result.delta >= 65536);
    try std.testing.expectEqual(@as(u32, 42), try run(&code, old_frame - result.delta));
}

test "machine spill coloring retains values across backedges and conditional exits" {
    var code = [_]machine.Instruction{
        .{ .label = "entry" }, .{ .spill_eax_rsp = first },  .{ .jmp = "head" },
        .{ .label = "head" },  .{ .reload_rsp_eax = first }, .{ .je = "done" },
        .{ .label = "body" },  .{ .spill_eax_rsp = second }, .{ .reload_rsp_eax = second },
        .{ .jmp = "head" },    .{ .label = "done" },         .{ .add_rsp_imm32 = old_frame },
        .ret,
    };
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const result = (try homes.analyze(arena.allocator(), &code, old_frame, object_base)) orelse return error.ExpectedMapping;
    try std.testing.expect(result.mapping[first.slot] != result.mapping[second.slot]);
}

test "machine spill coloring keeps overlapping widths partial writes and alignment phases" {
    var code = [_]machine.Instruction{
        .{ .spill_xmm128_rsp = .{ .reg = .xmm0, .frame_index = first } },
        .{ .store_al_stack_disp32 = 405 },
        .{ .reload_arg64_rsp = .{ .reg = .rdi, .frame_index = .{ .slot = first.slot + 1 } } },
        .{ .reload_xmm128_rsp = .{ .reg = .xmm0, .frame_index = first } },
        .{ .add_rsp_imm32 = old_frame },
        .ret,
    };
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const result = (try homes.analyze(arena.allocator(), &code, old_frame, object_base)) orelse return error.ExpectedMapping;
    for (0..4) |i| try std.testing.expectEqual(result.mapping[first.slot] + i * 4, result.mapping[first.slot + i]);
    try std.testing.expectEqual(@as(u32, 400) % 16, result.mapping[first.slot] % 16);
    try homes.rewrite(&code, old_frame, result);
    try std.testing.expectEqual(result.mapping[first.slot] + 5, code[1].store_al_stack_disp32);
}

test "machine spill coloring accounts for outgoing stack bias" {
    var code = [_]machine.Instruction{
        .{ .spill_eax_rsp = first },                        .{ .push_arg = .rdi },
        .{ .reload_rsp_eax = .{ .slot = first.slot + 2 } }, .add_rsp_8,
        .{ .add_rsp_imm32 = old_frame },                    .ret,
    };
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const result = (try homes.analyze(arena.allocator(), &code, old_frame, object_base)) orelse return error.ExpectedMapping;
    try homes.rewrite(&code, old_frame, result);
    try std.testing.expectEqual(result.mapping[first.slot] + 8, try code[2].reload_rsp_eax.byteOffset());
}

test "machine spill coloring batches thousands of groups without losing interference" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    var code: std.ArrayList(machine.Instruction) = .empty;
    try code.append(a, .{ .spill_eax_rsp = first });
    for (0..5000) |i| {
        const slot = try FrameIndex.fromSlot(104 + i * 4);
        try code.append(a, .{ .spill_eax_rsp = slot });
        try code.append(a, .{ .reload_rsp_eax = slot });
    }
    try code.appendSlice(a, &.{ .{ .reload_rsp_eax = first }, .{ .add_rsp_imm32 = old_frame }, .ret });
    const result = (try homes.analyze(a, code.items, old_frame, object_base)) orelse return error.ExpectedMapping;
    try std.testing.expectEqual(@as(usize, 5001), result.groups);
    try std.testing.expect(result.liveness_bytes < 64 * 1024 * 1024);
    for (0..5000) |i| {
        try std.testing.expect(result.mapping[100] != result.mapping[104 + i * 4]);
        try std.testing.expectEqual(result.mapping[104], result.mapping[104 + i * 4]);
    }
}

test "machine spill coloring declines private address escapes opaque indices and unbalanced temporaries" {
    const cases = [_][]const machine.Instruction{
        &.{ .{ .mov_rsp_arg64 = .rdi }, .{ .add_arg64_imm32 = .{ .reg = .rdi, .imm = 400 } }, .ret },
        &.{ .{ .load_stack_rcx4_disp32_eax = 400 }, .ret },
        &.{ .{ .spill_eax_rsp = first }, .{ .push_arg = .rdi }, .ret },
    };
    for (cases) |original| {
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const code = try arena.allocator().dupe(machine.Instruction, original);
        try std.testing.expect(try homes.analyze(arena.allocator(), code, old_frame, object_base) == null);
    }
    var bounded = [_]machine.Instruction{ .{ .spill_eax_rsp = first }, .ret };
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    try std.testing.expect(try homes.analyze(arena.allocator(), &bounded, old_frame, old_frame + 16) == null);
    try std.testing.expect(try homes.analyze(arena.allocator(), &bounded, 8 * 1024 * 1024 + 8, object_base) == null);
    try std.testing.expect(try homes.analyze(arena.allocator(), &bounded, old_frame - 8, object_base) == null);
}
