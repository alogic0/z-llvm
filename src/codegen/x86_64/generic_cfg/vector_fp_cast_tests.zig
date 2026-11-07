const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const selector = @import("../generic_cfg_selector.zig");
const encoding = @import("../../../mc/encoding.zig");
const vector = @import("composed_selector_vector.zig");
const state = @import("composed_selector_state.zig");
const data = @import("composed_selector_state_data.zig");

fn executable(function: ir.Function) ![]align(std.heap.page_size_min) u8 {
    var output = machine.MachineFunction.init(function.name, function.ret_ty);
    defer output.deinit(std.testing.allocator);
    const selected = try selector.tryLower(std.testing.allocator, &output, function);
    if (selected == .unsupported) std.debug.print("vector fp casts {s}: {s}\n", .{ function.name, selected.unsupported.detail() });
    try std.testing.expectEqual(selector.SelectionResult.selected, selected);
    try @import("../verify.zig").verifyFunction(output);
    const code = try encoding.encodeFunction(std.testing.allocator, output);
    defer std.testing.allocator.free(code);
    const memory = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    @memcpy(memory[0..code.len], code);
    return memory;
}

test "runtime vector casts execute rounding boundaries and preserve source aliases" {
    const source = try std.Io.Dir.cwd().readFileAlloc(std.testing.io, "test/real_programs/vector_fp_casts.ll", std.testing.allocator, .limited(16384));
    defer std.testing.allocator.free(source);
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    try module.verify();
    const narrow_code = try executable(module.functions.items[0]);
    defer std.posix.munmap(narrow_code);
    const widen_code = try executable(module.functions.items[1]);
    defer std.posix.munmap(widen_code);
    const phi_code = try executable(module.functions.items[2]);
    defer std.posix.munmap(phi_code);
    const narrow: *const fn (*const [2]f64, *[2]f32, *[2]f64) callconv(.c) void = @ptrCast(narrow_code.ptr);
    const widen: *const fn (*const [2]f32, *[2]f64, *[2]f32) callconv(.c) void = @ptrCast(widen_code.ptr);
    const phi: *const fn (*const [2]f64, *[2]f64, u64) callconv(.c) void = @ptrCast(phi_code.ptr);
    const cases = [_]struct { from: u64, to: u32 }{
        .{ .from = 0, .to = 0 },
        .{ .from = 0x8000000000000000, .to = 0x80000000 },
        .{ .from = 0x3ff0000010000000, .to = 0x3f800000 },
        .{ .from = 0x3ff0000020000000, .to = 0x3f800001 },
        .{ .from = 0x3ff0000030000000, .to = 0x3f800002 },
        .{ .from = 0x3690000000000000, .to = 0 },
        .{ .from = 0x36a0000000000000, .to = 1 },
        .{ .from = 0x36b0000000000000, .to = 2 },
        .{ .from = 0x47efffffe0000000, .to = 0x7f7fffff },
        .{ .from = 0x47f0000000000000, .to = 0x7f800000 },
        .{ .from = 0x7ff0000000000000, .to = 0x7f800000 },
        .{ .from = 0xfff0000000000000, .to = 0xff800000 },
    };
    for (cases) |left| for (cases) |right| {
        const input: [2]f64 = .{ @bitCast(left.from), @bitCast(right.from) };
        var output: [2]f32 = undefined;
        var preserved: [2]f64 = undefined;
        narrow(&input, &output, &preserved);
        try std.testing.expectEqual(left.to, @as(u32, @bitCast(output[0])));
        try std.testing.expectEqual(right.to, @as(u32, @bitCast(output[1])));
        try std.testing.expectEqualSlices(u8, std.mem.asBytes(&input), std.mem.asBytes(&preserved));
        var widened: [2]f64 = undefined;
        var saved: [2]f32 = undefined;
        widen(&output, &widened, &saved);
        for (output, widened) |value, actual| try std.testing.expectEqual(@as(u64, @bitCast(@as(f64, value))), @as(u64, @bitCast(actual)));
        try std.testing.expectEqualSlices(u8, std.mem.asBytes(&output), std.mem.asBytes(&saved));
        for (0..2) |choice| {
            var selected: [2]f64 = undefined;
            phi(&input, &selected, choice);
            for (0..2) |lane| try std.testing.expectEqual(widened[lane ^ choice], selected[lane]);
        }
    };
}

test "runtime vector casts retain defined lanes and reject unsupported conversion shapes" {
    var output = machine.MachineFunction.init("partial", .void);
    defer output.deinit(std.testing.allocator);
    var block = data.ComposedBlockSelector.init(std.testing.allocator, &output);
    defer block.deinit();
    const pair64: ir.Type = .{ .vector = .{ .len = 2, .elem_ty = .double } };
    const pair32: ir.Type = .{ .vector = .{ .len = 2, .elem_ty = .float } };
    try std.testing.expect((try vector.lowerCast(&block, "result", .{
        .op = .fptrunc,
        .from_ty = pair64,
        .to_ty = pair32,
        .value = .{ .vector = "<double 1.000000e+00, double poison>" },
    })) == null);
    const location = state.resolveValue(&block, .{ .named = "result" }).?;
    try std.testing.expectEqual(@as(u4, 1), location.xmm.vectorShape().?.defined_lanes);
    const count = output.instructions.items.len;
    try std.testing.expect((try vector.lowerCast(&block, "unsupported", .{
        .op = .fpext,
        .from_ty = .{ .vector = .{ .len = 4, .elem_ty = .float } },
        .to_ty = .{ .vector = .{ .len = 4, .elem_ty = .double } },
        .value = .poison,
    })) != null);
    try std.testing.expectEqual(count, output.instructions.items.len);
}

test "runtime vector memory keeps barriers address spaces and wider shapes unsupported" {
    for ([_][]const u8{
        "define void @f(ptr %p) {\nentry:\n %v = load volatile <2 x double>, ptr %p\n ret void\n}\n",
        "define void @f(ptr %p) {\nentry:\n %v = load <2 x double>, ptr addrspace(1) %p\n ret void\n}\n",
        "define void @f(ptr %p) {\nentry:\n store volatile <2 x float> zeroinitializer, ptr %p\n ret void\n}\n",
        "define void @f(ptr %p) {\nentry:\n %v = load <4 x double>, ptr %p\n ret void\n}\n",
    }) |source| {
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect((try @import("pair_memory.zig").legalize(arena.allocator(), module.functions.items[0], null)) == null);
    }
}
