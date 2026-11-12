const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const selector = @import("../generic_cfg_selector.zig");
const verify = @import("../verify.zig");
const encoding = @import("../../../mc/encoding.zig");

fn executable(source: []const u8) ![]align(std.heap.page_size_min) u8 {
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    try module.verify();
    const function = module.functions.items[0];
    var output = machine.MachineFunction.init(function.name, function.ret_ty);
    defer output.deinit(std.testing.allocator);
    const selected = try selector.tryLower(std.testing.allocator, &output, function);
    if (selected == .unsupported) std.debug.print("integer stack ABI {s}: {s}\n", .{ function.name, selected.unsupported.detail() });
    try std.testing.expectEqual(selector.SelectionResult.selected, selected);
    try verify.verifyFunction(output);
    const bytes = try encoding.encodeFunction(std.testing.allocator, output);
    defer std.testing.allocator.free(bytes);
    const code = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    @memcpy(code[0..bytes.len], bytes);
    return code;
}

fn scalarSource(count: usize) ![]const u8 {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    var pieces: std.ArrayList([]const u8) = .empty;
    try pieces.append(a, "define i64 @words(");
    for (0..count) |i| try pieces.append(a, try std.fmt.allocPrint(a, "{s}i64 %a{d}", .{ if (i == 0) "" else ", ", i }));
    try pieces.append(a, ") {\nentry:\n  %r0 = xor i64 %a0, %a1\n");
    for (2..count) |i| try pieces.append(a, try std.fmt.allocPrint(a, "  %r{d} = xor i64 %r{d}, %a{d}\n", .{ i - 1, i - 2, i }));
    try pieces.append(a, try std.fmt.allocPrint(a, "  ret i64 %r{d}\n}}\n", .{count - 2}));
    return std.mem.concat(std.testing.allocator, u8, pieces.items);
}

test "integer stack ABI executes eighteen and thirty-two scalar parameters" {
    inline for (.{ 18, 32 }) |count| {
        const Signature = if (count == 18)
            fn (u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64) callconv(.c) u64
        else
            fn (u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64) callconv(.c) u64;
        const source = try scalarSource(count);
        defer std.testing.allocator.free(source);
        const code = try executable(source);
        defer std.posix.munmap(code);
        const run: *const Signature = @ptrCast(code.ptr);
        for ([_]u64{ 0, 1, 0x8000000000000000, std.math.maxInt(u64) }) |seed| {
            var args: std.meta.ArgsTuple(Signature) = undefined;
            var expected: u64 = 0;
            inline for (0..count) |i| {
                const value = seed +% (@as(u64, i) *% 0x9e3779b97f4a7c15);
                args[i] = value;
                expected ^= value;
            }
            try std.testing.expectEqual(expected, @call(.auto, run, args));
        }
    }
}

test "integer stack ABI executes forty and sixty-four scalar parameters" {
    inline for (.{ 40, 64 }) |count| {
        const Signature = if (count == 40)
            fn (
                u64, u64, u64, u64, u64, u64, u64, u64, u64, u64,
                u64, u64, u64, u64, u64, u64, u64, u64, u64, u64,
                u64, u64, u64, u64, u64, u64, u64, u64, u64, u64,
                u64, u64, u64, u64, u64, u64, u64, u64, u64, u64,
            ) callconv(.c) u64
        else
            fn (
                u64, u64, u64, u64, u64, u64, u64, u64,
                u64, u64, u64, u64, u64, u64, u64, u64,
                u64, u64, u64, u64, u64, u64, u64, u64,
                u64, u64, u64, u64, u64, u64, u64, u64,
                u64, u64, u64, u64, u64, u64, u64, u64,
                u64, u64, u64, u64, u64, u64, u64, u64,
                u64, u64, u64, u64, u64, u64, u64, u64,
                u64, u64, u64, u64, u64, u64, u64, u64,
            ) callconv(.c) u64;
        const source = try scalarSource(count);
        defer std.testing.allocator.free(source);
        const code = try executable(source);
        defer std.posix.munmap(code);
        const run: *const Signature = @ptrCast(code.ptr);
        for ([_]u64{ 0, 1, 0x8000000000000000, std.math.maxInt(u64) }) |seed| {
            var args: std.meta.ArgsTuple(Signature) = undefined;
            var expected: u64 = 0;
            inline for (0..count) |i| {
                args[i] = seed +% (@as(u64, i) *% 0x9e3779b97f4a7c15);
                expected ^= args[i];
            }
            try std.testing.expectEqual(expected, @call(.auto, run, args));
        }
    }
}

test "integer stack ABI captures a stacked pair before first-use register parameters" {
    const code = try executable(
        \\define i64 @pair(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i128 %wide, i64 %tail) {
        \\entry:
        \\  %first = xor i64 %a, %b
        \\  %r0 = xor i64 %first, %c
        \\  %r1 = xor i64 %r0, %d
        \\  %r2 = xor i64 %r1, %e
        \\  %lo = trunc i128 %wide to i64
        \\  %shifted = lshr i128 %wide, 64
        \\  %hi = trunc i128 %shifted to i64
        \\  %r3 = xor i64 %r2, %lo
        \\  %r4 = xor i64 %r3, %hi
        \\  %result = xor i64 %r4, %tail
        \\  ret i64 %result
        \\}
    );
    defer std.posix.munmap(code);
    const run: *const fn (u64, u64, u64, u64, u64, u128, u64) callconv(.c) u64 = @ptrCast(code.ptr);
    const values = [_]u64{ 0, 1, 0x8000000000000000, std.math.maxInt(u64) };
    for (values) |lo| for (values) |hi| {
        const wide = @as(u128, hi) << 64 | lo;
        try std.testing.expectEqual(@as(u64, 2 ^ 3 ^ 4 ^ 5 ^ 6 ^ 9) ^ lo ^ hi, run(2, 3, 4, 5, 6, wide, 9));
    };
}

test "integer stack ABI preserves scalar padding before an incoming pair" {
    const code = try executable(
        \\define i64 @padding(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %stack, i128 %wide, i64 %tail) {
        \\entry:
        \\  %first = xor i64 %a, %b
        \\  %r0 = xor i64 %first, %c
        \\  %r1 = xor i64 %r0, %d
        \\  %r2 = xor i64 %r1, %e
        \\  %r3 = xor i64 %r2, %f
        \\  %r4 = xor i64 %r3, %stack
        \\  %lo = trunc i128 %wide to i64
        \\  %shifted = lshr i128 %wide, 64
        \\  %hi = trunc i128 %shifted to i64
        \\  %r5 = xor i64 %r4, %lo
        \\  %r6 = xor i64 %r5, %hi
        \\  %result = xor i64 %r6, %tail
        \\  ret i64 %result
        \\}
    );
    defer std.posix.munmap(code);
    const run: *const fn (u64, u64, u64, u64, u64, u64, u64, u128, u64) callconv(.c) u64 = @ptrCast(code.ptr);
    const values = [_]u64{ 0, 1, 0x8000000000000000, std.math.maxInt(u64) };
    for (values) |lo| for (values) |hi| {
        const wide = @as(u128, hi) << 64 | lo;
        try std.testing.expectEqual(@as(u64, 2 ^ 3 ^ 4 ^ 5 ^ 6 ^ 7 ^ 8 ^ 9) ^ lo ^ hi, run(2, 3, 4, 5, 6, 7, 8, wide, 9));
    };
}

test "integer stack ABI reserves all incoming words even for unused wide parameters" {
    inline for (.{ 32, 64 }) |count| {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    var pieces: std.ArrayList([]const u8) = .empty;
    try pieces.append(a, "define i128 @last(");
    for (0..count) |i| try pieces.append(a, try std.fmt.allocPrint(a, "{s}i128 %a{d}", .{ if (i == 0) "" else ", ", i }));
    try pieces.append(a, try std.fmt.allocPrint(a, ") {{\nentry:\n  ret i128 %a{d}\n}}\n", .{count - 1}));
    const source = try std.mem.concat(a, u8, pieces.items);
    const code = try executable(source);
    defer std.posix.munmap(code);
    const Signature = if (count == 32) fn (u128, u128, u128, u128, u128, u128, u128, u128, u128, u128, u128, u128, u128, u128, u128, u128, u128, u128, u128, u128, u128, u128, u128, u128, u128, u128, u128, u128, u128, u128, u128, u128) callconv(.c) u128 else fn (
        u128, u128, u128, u128, u128, u128, u128, u128,
        u128, u128, u128, u128, u128, u128, u128, u128,
        u128, u128, u128, u128, u128, u128, u128, u128,
        u128, u128, u128, u128, u128, u128, u128, u128,
        u128, u128, u128, u128, u128, u128, u128, u128,
        u128, u128, u128, u128, u128, u128, u128, u128,
        u128, u128, u128, u128, u128, u128, u128, u128,
        u128, u128, u128, u128, u128, u128, u128, u128,
    ) callconv(.c) u128;
    const run: *const Signature = @ptrCast(code.ptr);
    var args: std.meta.ArgsTuple(Signature) = undefined;
    inline for (0..count) |i| args[i] = @as(u128, 0xfedcba9876543210 + i) << 64 | (0x8123456789abcdef - i);
    try std.testing.expectEqual(args[count - 1], @call(.auto, run, args));
    }
}

test "integer stack ABI masks every wide integer carrier and preserves signed shifts" {
    for ([_]u16{ 65, 66, 80, 96, 127 }) |bits| {
        const source = try std.fmt.allocPrint(std.testing.allocator, "define i128 @shift(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i{0d} %wide, i64 %tail) {{\nentry:\n" ++
            " %first = xor i64 %a, %b\n %shift = ashr i{0d} %wide, 1\n %signed = sext i{0d} %shift to i128\n" ++
            " %x0 = xor i64 %first, %c\n %x1 = xor i64 %x0, %d\n %x2 = xor i64 %x1, %e\n %x3 = xor i64 %x2, %tail\n" ++
            " %low = zext i64 %x3 to i128\n %result = xor i128 %signed, %low\n ret i128 %result\n}}\n", .{bits});
        defer std.testing.allocator.free(source);
        const code = try executable(source);
        defer std.posix.munmap(code);
        // LLVM splits non-i128 wide integers into independent i64 ABI words.
        const run: *const fn (u64, u64, u64, u64, u64, u64, u64, u64) callconv(.c) u128 = @ptrCast(code.ptr);
        const mask = (@as(u128, 1) << @as(u7, @intCast(bits))) - 1;
        const sign = @as(u128, 1) << @as(u7, @intCast(bits - 1));
        for ([_]u128{ 0, 1, sign - 1, sign, mask - 1, mask, std.math.maxInt(u128) }) |raw| {
            const value = raw & mask;
            const signed: i128 = @bitCast(if (value & sign != 0) value | ~mask else value);
            const expected: u128 = @bitCast(signed >> 1);
            try std.testing.expectEqual(expected ^ (2 ^ 3 ^ 4 ^ 5 ^ 6 ^ 9), run(2, 3, 4, 5, 6, @truncate(raw), @truncate(raw >> 64), 9));
        }
    }
}
