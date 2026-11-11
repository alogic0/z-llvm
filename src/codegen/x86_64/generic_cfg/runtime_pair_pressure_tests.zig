const std = @import("std");
const ir = @import("../../../ir.zig");
const compilation = @import("../../../compilation.zig");
const encoding = @import("../../../mc/encoding.zig");
const verify = @import("../verify.zig");

test "runtime unsigned divide assembly preserves quotient remainder live values and guards" {
    const source =
        \\define i64 @divide(i64 %divisor,i64 %low,i64 %high,ptr %out,i64 %live) {
        \\entry:
        \\ %both = call { i64, i64 } asm "divq ${2}", "={rax},={rdx},r,{rax},{rdx},~{dirflag},~{fpsr},~{flags}"(i64 %divisor,i64 %low,i64 %high)
        \\ %quotient = extractvalue { i64, i64 } %both,0
        \\ %remainder = extractvalue { i64, i64 } %both,1
        \\ store i64 %quotient,ptr %out,align 1
        \\ %tail = getelementptr i8,ptr %out,i64 8
        \\ store i64 %remainder,ptr %tail,align 1
        \\ %answer = xor i64 %quotient,%live
        \\ ret i64 %answer
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    try module.verify();
    var machine = try compilation.select(std.testing.allocator, "x86_64-unknown-linux-gnu", module.functions.items[0], .{ .generic_cfg_selector = true });
    defer machine.deinit(std.testing.allocator);
    try verify.verifyFunction(machine);
    const code = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(code);
    const memory = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(memory);
    @memcpy(memory[0..code.len], code);
    const run: *const fn (u64, u64, u64, *anyopaque, u64) callconv(.c) u64 = @ptrCast(memory.ptr);
    for ([_]u64{ 1, 3, 4294967297, 0x8000000000000000, std.math.maxInt(u64) }) |divisor| for ([_]u64{ 0, divisor / 2, divisor - 1 }) |high| for ([_]u64{ 0, 1, 0x0123456789abcdef, std.math.maxInt(u64) }) |low| {
        const input = (@as(u128, high) << 64) | low;
        const quotient: u64 = @intCast(input / divisor);
        const remainder: u64 = @intCast(input % divisor);
        const live = high ^ low;
        var output: [32]u8 = @splat(165);
        try std.testing.expectEqual(quotient ^ live, run(divisor, low, high, &output[8], live));
        try std.testing.expectEqual(quotient, std.mem.readInt(u64, output[8..16], .little));
        try std.testing.expectEqual(remainder, std.mem.readInt(u64, output[16..24], .little));
        for (output[0..8]) |byte| try std.testing.expectEqual(@as(u8, 165), byte);
        for (output[24..32]) |byte| try std.testing.expectEqual(@as(u8, 165), byte);
    };
}

test "runtime pair pressure preserves both packed inputs scalar live values and output guards" {
    const source =
        \\define i64 @packed(i64 %a, i64 %b, i64 %c, i64 %d, ptr %out, i64 %live) {
        \\entry:
        \\ %bh = zext i64 %b to i128
        \\ %bs = shl i128 %bh, 64
        \\ %al = zext i64 %a to i128
        \\ %left = or i128 %bs, %al
        \\ %dh = zext i64 %d to i128
        \\ %ds = shl i128 %dh, 64
        \\ %cl = zext i64 %c to i128
        \\ %right = or i128 %ds, %cl
        \\ %both = xor i128 %left, %right
        \\ store i128 %both, ptr %out, align 1
        \\ %low = trunc i128 %both to i64
        \\ %answer = xor i64 %low, %live
        \\ ret i64 %answer
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    try module.verify();
    var machine = try compilation.select(std.testing.allocator, "x86_64-unknown-linux-gnu", module.functions.items[0], .{ .generic_cfg_selector = true });
    defer machine.deinit(std.testing.allocator);
    try verify.verifyFunction(machine);
    const code = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(code);
    const memory = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(memory);
    @memcpy(memory[0..code.len], code);
    const run: *const fn (u64, u64, u64, u64, *anyopaque, u64) callconv(.c) u64 = @ptrCast(memory.ptr);
    const values = [_]u64{ 0, 1, 0x8000000000000000, 0xffffffffffffffff, 0x0123456789abcdef };
    for (values) |a| for (values) |b| {
        const c = a ^ 0x9988776655443322;
        const d = b +% 127;
        const live = a +% b;
        var output: [32]u8 = @splat(165);
        try std.testing.expectEqual(a ^ c ^ live, run(a, b, c, d, &output[8], live));
        try std.testing.expectEqual(a ^ c, std.mem.readInt(u64, output[8..16], .little));
        try std.testing.expectEqual(b ^ d, std.mem.readInt(u64, output[16..24], .little));
        for (output[0..8]) |byte| try std.testing.expectEqual(@as(u8, 165), byte);
        for (output[24..32]) |byte| try std.testing.expectEqual(@as(u8, 165), byte);
    };
}
