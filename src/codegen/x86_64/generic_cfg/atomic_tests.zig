const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const selector = @import("../generic_cfg_selector.zig");
const verify = @import("../verify.zig");
const encoding = @import("../../../mc/encoding.zig");

fn executable(module: ir.Module) ![]align(std.heap.page_size_min) u8 {
    const function = module.functions.items[0];
    var output = machine.MachineFunction.init(function.name, function.ret_ty);
    defer output.deinit(std.testing.allocator);
    const selected = try selector.tryLower(std.testing.allocator, &output, function);
    if (selected == .unsupported) std.debug.print("scalar atomics {s}: {s}\n", .{ function.name, selected.unsupported.detail() });
    try std.testing.expectEqual(selector.SelectionResult.selected, selected);
    try verify.verifyFunction(output);
    const code = try encoding.encodeFunction(std.testing.allocator, output);
    defer std.testing.allocator.free(code);
    const memory = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    @memcpy(memory[0..code.len], code);
    return memory;
}

test "scalar atomics read-modify-write preserves width memory and live operands" {
    for ([_]u16{ 8, 16, 32, 64 }) |bits| for ([_][]const u8{ "xchg", "add", "sub", "and", "or", "xor", "nand", "umin", "umax" }, 0..) |op, op_index| for ([_][]const u8{ "", "syncscope(\"singlethread\") " }, 0..) |scope, scope_index| {
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const allocator = arena.allocator();
        const input = if (bits == 64) "  %value = add i64 %input, 0\n" else try std.fmt.allocPrint(allocator, "  %value = trunc i64 %input to i{d}\n", .{bits});
        const output = if (bits == 64) "  %wide = add i64 %old, 0\n" else try std.fmt.allocPrint(allocator, "  %wide = zext i{d} %old to i64\n", .{bits});
        const text = try std.fmt.allocPrint(allocator, "define i64 @probe(ptr %p, i64 %input, ptr %out, i64 %salt) {{\nentry:\n{s}  %old = atomicrmw {s}{s} ptr %p, i{d} %value {s}seq_cst, align {d}\n{s}  store i64 %wide, ptr %out\n  %next = getelementptr i8, ptr %out, i64 8\n  %live = xor i64 %input, %salt\n  store i64 %live, ptr %next\n  ret i64 %wide\n}}\n", .{ input, if (scope_index == 1) "volatile " else "", op, bits, scope, bits / 8, output });
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const code = try executable(module);
        defer std.posix.munmap(code);
        const run: *const fn (*u64, u64, *[2]u64, u64) callconv(.c) u64 = @ptrCast(code.ptr);
        const mask: u64 = if (bits == 64) std.math.maxInt(u64) else (@as(u64, 1) << @as(u6, @intCast(bits))) - 1;
        const sign = @as(u64, 1) << @as(u6, @intCast(bits - 1));
        const inputs = [_]u64{ 0, 1, sign - 1, sign, mask - 1, mask, 0xdeadbeefcafe0123, std.math.maxInt(u64) };
        for (inputs) |a| for (inputs) |b| {
            const original = (a & mask) | (0xa5a5a5a5a5a5a5a5 & ~mask);
            var cell: u64 = original;
            var out: [2]u64 = .{ 0, 0 };
            const x = a & mask;
            const y = b & mask;
            const new = switch (op_index) {
                0 => y,
                1 => x +% y,
                2 => x -% y,
                3 => x & y,
                4 => x | y,
                5 => x ^ y,
                6 => ~(x & y),
                7 => @min(x, y),
                8 => @max(x, y),
                else => unreachable,
            } & mask;
            try std.testing.expectEqual(x, run(&cell, b, &out, 0x123456789abcdef0));
            try std.testing.expectEqual(x, out[0]);
            try std.testing.expectEqual(b ^ 0x123456789abcdef0, out[1]);
            try std.testing.expectEqual((original & ~mask) | new, cell);
        };
    };
}

test "scalar atomics compare exchange preserves old value success and live inputs" {
    for ([_]u16{ 8, 16, 32, 64, 0 }) |kind| for ([_]bool{ false, true }) |weak| for ([_]bool{ false, true }) |flag_first| {
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const allocator = arena.allocator();
        const bits: u16 = if (kind == 0) 64 else kind;
        const ty = if (kind == 0) "ptr" else try std.fmt.allocPrint(allocator, "i{d}", .{bits});
        const inputs = if (kind == 0) "  %expected = inttoptr i64 %input_expected to ptr\n  %desired = inttoptr i64 %input_desired to ptr\n" else if (bits == 64) "  %expected = add i64 %input_expected, 0\n  %desired = add i64 %input_desired, 0\n" else try std.fmt.allocPrint(allocator, "  %expected = trunc i64 %input_expected to i{d}\n  %desired = trunc i64 %input_desired to i{d}\n", .{ bits, bits });
        const value_extract = try std.fmt.allocPrint(allocator, "  %old = extractvalue {{ {s}, i1 }} %pair, 0\n", .{ty});
        const flag_extract = try std.fmt.allocPrint(allocator, "  %flag = extractvalue {{ {s}, i1 }} %pair, 1\n", .{ty});
        const output = if (kind == 0) "  %wide = ptrtoint ptr %old to i64\n" else if (bits == 64) "  %wide = add i64 %old, 0\n" else try std.fmt.allocPrint(allocator, "  %wide = zext i{d} %old to i64\n", .{bits});
        const text = try std.fmt.allocPrint(allocator, "define i64 @probe(ptr %p, i64 %input_expected, i64 %input_desired, ptr %out, i64 %salt) {{\nentry:\n{s}  %pair = cmpxchg {s}ptr %p, {s} %expected, {s} %desired syncscope(\"singlethread\") seq_cst acquire, align {d}\n{s}{s}{s}  %flagwide = zext i1 %flag to i64\n  store i64 %wide, ptr %out\n  %next = getelementptr i8, ptr %out, i64 8\n  store i64 %flagwide, ptr %next\n  %last = getelementptr i8, ptr %out, i64 16\n  %xor = xor i64 %input_expected, %input_desired\n  %live = xor i64 %xor, %salt\n  store i64 %live, ptr %last\n  ret i64 %wide\n}}\n", .{ inputs, if (weak) "weak volatile " else "", ty, ty, bits / 8, if (flag_first) flag_extract else value_extract, if (flag_first) value_extract else flag_extract, output });
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const code = try executable(module);
        defer std.posix.munmap(code);
        const run: *const fn (*u64, u64, u64, *[3]u64, u64) callconv(.c) u64 = @ptrCast(code.ptr);
        const mask: u64 = if (bits == 64) std.math.maxInt(u64) else (@as(u64, 1) << @as(u6, @intCast(bits))) - 1;
        const samples = [_]u64{ 0, 1, mask, 0x8000000000000000, 0xdeadbeefcafe0123 };
        for (samples) |a| for (samples) |b| {
            const original = (a & mask) | (0xa5a5a5a5a5a5a5a5 & ~mask);
            var cell: u64 = original;
            var out: [3]u64 = .{ 0, 0, 0 };
            const desired = a ^ 0x123456789abcdef0;
            const success = (a & mask) == (b & mask);
            try std.testing.expectEqual(a & mask, run(&cell, b, desired, &out, 0xfedcba9876543210));
            try std.testing.expectEqual(a & mask, out[0]);
            try std.testing.expectEqual(@as(u64, @intFromBool(success)), out[1]);
            try std.testing.expectEqual(b ^ desired ^ 0xfedcba9876543210, out[2]);
            try std.testing.expectEqual(if (success) (original & ~mask) | (desired & mask) else original, cell);
        };
    };
}

test "scalar atomics constant compare exchange normalizes expected and old values" {
    for ([_]u16{ 8, 16, 32, 64 }) |bits| {
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const allocator = arena.allocator();
        const output = if (bits == 64) "  %wide = add i64 %old, 0\n" else try std.fmt.allocPrint(allocator, "  %wide = zext i{d} %old to i64\n", .{bits});
        const text = try std.fmt.allocPrint(allocator, "define i64 @probe(ptr %p, ptr %out) {{\nentry:\n  %pair = cmpxchg ptr %p, i{d} -1, i{d} 7 seq_cst monotonic, align {d}\n  %old = extractvalue {{ i{d}, i1 }} %pair, 0\n  %success = extractvalue {{ i{d}, i1 }} %pair, 1\n{s}  %flag = zext i1 %success to i64\n  store i64 %flag, ptr %out\n  ret i64 %wide\n}}\n", .{ bits, bits, bits / 8, bits, bits, output });
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const code = try executable(module);
        defer std.posix.munmap(code);
        const run: *const fn (*u64, *u64) callconv(.c) u64 = @ptrCast(code.ptr);
        const mask: u64 = if (bits == 64) std.math.maxInt(u64) else (@as(u64, 1) << @as(u6, @intCast(bits))) - 1;
        for ([_]u64{ 0, 1, mask - 1, mask }) |a| {
            var cell: u64 = a;
            var flag: u64 = 99;
            try std.testing.expectEqual(a, run(&cell, &flag));
            try std.testing.expectEqual(@as(u64, @intFromBool(a == mask)), flag);
            try std.testing.expectEqual(if (a == mask) @as(u64, 7) else a, cell);
        }
    }
}

test "scalar atomics reject unknown scopes insufficient alignment and unsupported widths" {
    const atomics = @import("composed_selector_atomic.zig");
    const core_ir = @import("../../../ir/core.zig");
    const accepted: core_ir.AtomicRmwInst = .{ .op = "add", .ty = .{ .int = 64 }, .ptr = .{ .named = "p" }, .value = .{ .int = 1 }, .ordering = "seq_cst", .@"align" = 8 };
    try std.testing.expect(atomics.inspectRmw(accepted) == null);
    var changed = accepted;
    changed.syncscope = "syncscope(\"agent\")";
    try std.testing.expect(atomics.inspectRmw(changed) != null);
    changed = accepted;
    changed.@"align" = 4;
    try std.testing.expect(atomics.inspectRmw(changed) != null);
    changed = accepted;
    changed.ty = .{ .int = 128 };
    try std.testing.expect(atomics.inspectRmw(changed) != null);
    changed = accepted;
    changed.ordering = "unordered";
    try std.testing.expect(atomics.inspectRmw(changed) != null);
    changed = accepted;
    changed.op = "fadd";
    try std.testing.expect(atomics.inspectRmw(changed) != null);
    try std.testing.expect(!atomics.supportedMemoryAccess(.{ .int = 128 }, .{ .atomic_ordering = "acquire", .@"align" = 16 }));
}
