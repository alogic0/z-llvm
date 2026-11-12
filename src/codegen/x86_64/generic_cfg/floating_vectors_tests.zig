const std = @import("std");
const ir = @import("../../../ir.zig");
const compilation = @import("../../../compilation.zig");
const encoding = @import("../../../mc/encoding.zig");
const verify = @import("../verify.zig");
const vectors = @import("floating_vectors.zig");

fn executable(source: []const u8) ![]align(std.heap.page_size_min) u8 {
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const expanded = (try vectors.legalize(arena.allocator(), module.functions.items[0], null)).?;
    try std.testing.expect((try vectors.legalize(arena.allocator(), expanded, null)) == null);
    var output = try compilation.select(std.testing.allocator, "x86_64-unknown-linux-gnu", module.functions.items[0], .{ .generic_cfg_selector = true });
    defer output.deinit(std.testing.allocator);
    try verify.verifyFunction(output);
    const bytes = try encoding.encodeFunction(std.testing.allocator, output);
    defer std.testing.allocator.free(bytes);
    const memory = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    @memcpy(memory[0..bytes.len], bytes);
    return memory;
}

test "native width floating vector allocas activate private lane lowering" {
    const a = std.testing.allocator;
    inline for (.{ .{ "half", 16, 8 }, .{ "float", 32, 4 }, .{ "double", 64, 2 } }) |shape| {
        const source = try std.fmt.allocPrint(
            a,
            "declare <{0d} x {1s}> @llvm.fabs.v{0d}f{2d}(<{0d} x {1s}>)\n" ++
                "define void @owned_absolute(ptr %input, ptr %output) {{\nentry:\n" ++
                " %slot = alloca <{0d} x {1s}>, align 16\n %value = load <{0d} x {1s}>, ptr %input, align 1\n" ++
                " store <{0d} x {1s}> %value, ptr %slot, align 16\n %again = load <{0d} x {1s}>, ptr %slot, align 16\n" ++
                " %absolute = call <{0d} x {1s}> @llvm.fabs.v{0d}f{2d}(<{0d} x {1s}> %again)\n" ++
                " store <{0d} x {1s}> %absolute, ptr %output, align 1\n ret void\n}}\n",
            .{ shape[2], shape[0], shape[1] },
        );
        defer a.free(source);
        const memory = try executable(source);
        defer std.posix.munmap(memory);
        const run: *const fn (*const u8, *u8) callconv(.c) void = @ptrCast(memory.ptr);
        var input: [18]u8 = @splat(0xa5);
        var output: [32]u8 = @splat(0xa5);
        for (0..64) |seed| {
            for (input[1..17], 0..) |*byte, i| byte.* = @truncate(seed * 71 + i * 29);
            const before = input;
            @memset(&output, 0xa5);
            run(&input[1], &output[3]);
            for (0..16) |i| {
                const expected = if (i % (shape[1] / 8) == shape[1] / 8 - 1) input[1 + i] & 0x7f else input[1 + i];
                try std.testing.expectEqual(expected, output[3 + i]);
            }
            try std.testing.expectEqualSlices(u8, &before, &input);
            for (output[0..3]) |byte| try std.testing.expectEqual(@as(u8, 0xa5), byte);
            for (output[19..]) |byte| try std.testing.expectEqual(@as(u8, 0xa5), byte);
        }
    }
}

test "floating vector owned storage keeps dynamic objects and barrier loads closed" {
    const a = std.testing.allocator;
    for ([_][]const u8{
        "define void @dynamic(i64 %count,ptr %out) {\nentry:\n %slot = alloca <4 x float>, i64 %count, align 16\n %v = load <4 x float>,ptr %slot,align 16\n store <4 x float> %v,ptr %out,align 1\n ret void\n}\n",
        "define void @barrier(ptr %input,ptr %out) {\nentry:\n %slot = alloca <4 x float>,align 16\n %v = load volatile <4 x float>,ptr %input,align 1\n store <4 x float> %v,ptr %slot,align 16\n ret void\n}\n",
    }) |source| {
        var module = try ir.Module.parse(a, source);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(a);
        defer arena.deinit();
        try std.testing.expect((try vectors.legalize(arena.allocator(), module.functions.items[0], null)) == null);
        try module.verify();
    }
}

test "owned vector activation preserves native quad argument payloads" {
    const source =
        \\define i128 @quad_bits(ptr %unused, fp128 %value) {
        \\entry:
        \\ %slot = alloca fp128, align 16
        \\ store fp128 %value, ptr %slot, align 16
        \\ %bits = bitcast fp128 %value to i128
        \\ ret i128 %bits
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    try module.verify();
    var output = try compilation.select(std.testing.allocator, "x86_64-unknown-linux-gnu", module.functions.items[0], .{ .generic_cfg_selector = true });
    defer output.deinit(std.testing.allocator);
    try verify.verifyFunction(output);
    const bytes = try encoding.encodeFunction(std.testing.allocator, output);
    defer std.testing.allocator.free(bytes);
    const memory = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(memory);
    @memcpy(memory[0..bytes.len], bytes);
    const run: *const fn (?*anyopaque, f128) callconv(.c) u128 = @ptrCast(memory.ptr);
    for ([_]u128{ 0, 1, @as(u128, 1) << 127, 0x7fff800000000000123456789abcdef0, 0xbfff13579bdf2468fedcba9876543210 }) |bits|
        try std.testing.expectEqual(bits, run(null, @bitCast(bits)));
}

test "runtime x87 vectors keep packed ten byte lanes exact under wide scalarization" {
    for ([_]u32{ 1, 3, 16, 64 }) |count| {
        const source = try std.fmt.allocPrint(std.testing.allocator, "declare <{d} x x86_fp80> @llvm.fabs.v{d}f80(<{d} x x86_fp80>)\ndefine void @absolute(ptr %input, ptr %output) {{\nentry:\n %slot = alloca <{d} x x86_fp80>, align 16\n %v = load <{d} x x86_fp80>, ptr %input, align 1\n store <{d} x x86_fp80> %v, ptr %slot, align 1\n %again = load <{d} x x86_fp80>, ptr %slot, align 1\n %positive = call <{d} x x86_fp80> @llvm.fabs.v{d}f80(<{d} x x86_fp80> %again)\n store <{d} x x86_fp80> %positive, ptr %output, align 1\n ret void\n}}\n", .{ count, count, count, count, count, count, count, count, count, count, count });
        defer std.testing.allocator.free(source);
        const memory = try executable(source);
        defer std.posix.munmap(memory);
        const run: *const fn (*const u8, *u8) callconv(.c) void = @ptrCast(memory.ptr);
        var input: [640]u8 = undefined;
        var output: [656]u8 = @splat(165);
        const payloads = [_]u80{ 0, 1 << 79, 1, 0x3fff8000000000000000, 0xbfff8000000000000000, 0xffff8000000000000000, 0xffffc000000000000123, 0xffff8000000000000001 };
        for (0..payloads.len) |seed| {
            for (0..count) |lane| std.mem.writeInt(u80, input[lane * 10 ..][0..10], payloads[(seed + lane) % payloads.len], .little);
            @memset(&output, 165);
            run(&input[0], &output[8]);
            for (0..count) |lane| try std.testing.expectEqual(payloads[(seed + lane) % payloads.len] & ((@as(u80, 1) << 79) - 1), std.mem.readInt(u80, output[8 + lane * 10 ..][0..10], .little));
            for (output[0..8]) |byte| try std.testing.expectEqual(@as(u8, 165), byte);
            for (output[8 + count * 10 ..]) |byte| try std.testing.expectEqual(@as(u8, 165), byte);
        }
    }
}

test "runtime floating vectors shuffle wide payloads without changing NaNs zeros or store guards" {
    const source =
        \\define double @shuffle(double %a,double %b,double %c,double %d,ptr %out,double %live) {
        \\entry:
        \\ %v0 = insertelement <4 x double> poison,double %a,i64 0
        \\ %v1 = insertelement <4 x double> %v0,double %b,i64 1
        \\ %v2 = insertelement <4 x double> %v1,double %c,i64 2
        \\ %v3 = insertelement <4 x double> %v2,double %d,i64 3
        \\ %v = shufflevector <4 x double> %v3,<4 x double> poison,<4 x i32> <i32 3,i32 0,i32 2,i32 1>
        \\ store <4 x double> %v,ptr %out,align 1
        \\ ret double %live
        \\}
    ;
    const memory = try executable(source);
    defer std.posix.munmap(memory);
    const run: *const fn (f64, f64, f64, f64, *anyopaque, f64) callconv(.c) f64 = @ptrCast(memory.ptr);
    const values = [_]u64{ 0, 0x8000000000000000, 1, 0x7ff0000000000123, 0xfff8000000004567 };
    for (values) |a| for (values) |b| {
        const c = a ^ 0x8000000000000000;
        const d = b ^ 0x8000000000000000;
        var output: [48]u8 = @splat(165);
        try std.testing.expectEqual(a, @as(u64, @bitCast(run(@bitCast(a), @bitCast(b), @bitCast(c), @bitCast(d), &output[8], @bitCast(a)))));
        for ([_]u64{ d, a, c, b }, 0..) |expected, i| try std.testing.expectEqual(expected, std.mem.readInt(u64, output[8 + i * 8 ..][0..8], .little));
        for (output[0..8]) |byte| try std.testing.expectEqual(@as(u8, 165), byte);
        for (output[40..48]) |byte| try std.testing.expectEqual(@as(u8, 165), byte);
    };
}

test "runtime floating vectors retain the low64 packed float return ABI" {
    const source =
        \\define <2 x float> @packed(float %a,float %b) {
        \\entry:
        \\ %v0 = insertelement <2 x float> poison,float %a,i64 0
        \\ %v1 = insertelement <2 x float> %v0,float %b,i64 1
        \\ ret <2 x float> %v1
        \\}
    ;
    const memory = try executable(source);
    defer std.posix.munmap(memory);
    const run: *const fn (f32, f32) callconv(.c) f64 = @ptrCast(memory.ptr);
    const values = [_]u32{ 0, 0x80000000, 1, 0x7f800123, 0xffc04567 };
    for (values) |a| for (values) |b| try std.testing.expectEqual((@as(u64, b) << 32) | a, @as(u64, @bitCast(run(@bitCast(a), @bitCast(b)))));
}

test "runtime floating vectors reject explicit vector layout overrides" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\define <2 x float> @packed(float %x) {
        \\entry:
        \\ %v = insertelement <2 x float> poison,float %x,i64 0
        \\ ret <2 x float> %v
        \\}
    );
    defer module.deinit();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const context: @import("../machine.zig").ReadOnlyModuleContext = .{ .globals = &.{}, .named_types = &.{}, .target_datalayout = "e-v64:128" };
    try std.testing.expect((try vectors.legalize(arena.allocator(), module.functions.items[0], &context)) == null);
}
