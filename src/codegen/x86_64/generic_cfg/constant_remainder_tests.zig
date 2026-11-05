const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const verify = @import("../verify.zig");
const selector = @import("../generic_cfg_selector.zig");
const encoding = @import("../../../mc/encoding.zig");
const helpers = @import("composed_helpers.zig");

test "constant unsigned remainder executes every power of two at exact widths" {
    for ([_]u16{ 8, 16, 32, 64 }) |bits| {
        for (0..bits) |exponent| {
            const divisor: u64 = @as(u64, 1) << @intCast(exponent);
            const conversion = if (bits == 64) "%value = add i64 %remainder, 0" else try std.fmt.allocPrint(std.testing.allocator, "%value = zext i{d} %remainder to i64", .{bits});
            defer if (bits != 64) std.testing.allocator.free(conversion);
            const text = try std.fmt.allocPrint(std.testing.allocator,
                \\define i64 @remainder(ptr %storage, i64 %take) {{
                \\entry:
                \\  %slot = alloca ptr, align 8
                \\  store ptr %storage, ptr %slot, align 8
                \\  %condition = icmp ne i64 %take, 0
                \\  br i1 %condition, label %calculate, label %empty
                \\calculate:
                \\  %pointer = load ptr, ptr %slot, align 8
                \\  %input = load i{d}, ptr %pointer, align 8
                \\  %remainder = urem i{d} %input, {d}
                \\  {s}
                \\  ret i64 %value
                \\empty:
                \\  ret i64 0
                \\}}
            , .{ bits, bits, divisor, conversion });
            defer std.testing.allocator.free(text);
            var module = try ir.Module.parse(std.testing.allocator, text);
            defer module.deinit();
            try module.verify();
            var output = machine.MachineFunction.init("remainder", .{ .int = 64 });
            defer output.deinit(std.testing.allocator);
            const selected = try selector.tryLower(std.testing.allocator, &output, module.functions.items[0]);
            if (selected == .unsupported) std.debug.print("urem i{d} by {d}: {s} {s}\n", .{ bits, divisor, selected.unsupported.tagName(), selected.unsupported.detail() });
            try std.testing.expectEqual(selector.SelectionResult.selected, selected);
            try verify.verifyFunction(output);
            const bytes = try encoding.encodeFunction(std.testing.allocator, output);
            defer std.testing.allocator.free(bytes);
            const executable = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
            defer std.posix.munmap(executable);
            @memcpy(executable[0..bytes.len], bytes);
            const run: *const fn (*const u64, u64) callconv(.c) u64 = @ptrCast(executable.ptr);
            const width_mask: u64 = if (bits == 64) std.math.maxInt(u64) else (@as(u64, 1) << @intCast(bits)) - 1;
            for ([_]u64{ 0, 1, divisor - 1, divisor, divisor +% 1, 0x8000000000000000, 0x123456789abcdef0, std.math.maxInt(u64) }) |input| {
                const storage = input;
                try std.testing.expectEqual((input & width_mask) % divisor, run(&storage, 1));
                try std.testing.expectEqual(@as(u64, 0), run(&storage, 0));
            }
            // Normalizing a private instruction copy must not rewrite the IR.
            const original = module.functions.items[0].blocks.items[1].instructions.items[2].kind.binary;
            try std.testing.expectEqual(ir.BinaryOp.urem, original.op);
            try std.testing.expectEqual(@as(i128, divisor), original.rhs.int);
        }
    }
}

test "constant unsigned remainder divisor admission respects width and signed spelling" {
    for ([_]u16{ 8, 16, 32, 64 }) |bits| {
        const top: i128 = @as(i128, 1) << @intCast(bits - 1);
        try std.testing.expectEqual(@as(?i128, top - 1), helpers.unsignedPowerOfTwoRemainderMask(bits, top));
        try std.testing.expectEqual(@as(?i128, top - 1), helpers.unsignedPowerOfTwoRemainderMask(bits, -top));
        for ([_]i128{ 0, 3, -1, -top - 1, top * 2 }) |literal|
            try std.testing.expectEqual(@as(?i128, null), helpers.unsignedPowerOfTwoRemainderMask(bits, literal));
    }
    for ([_]u16{ 0, 1, 7, 24, 52, 65, 128 }) |bits|
        try std.testing.expectEqual(@as(?i128, null), helpers.unsignedPowerOfTwoRemainderMask(bits, 2));
}

test "constant unsigned remainder single block admission rejects unsupported divisors" {
    for ([_]i128{ 1, 4096, 0x100000000, 0x8000000000000000, -0x8000000000000000, 0, 3, -1 }) |divisor| {
        const text = try std.fmt.allocPrint(std.testing.allocator,
            \\define i64 @remainder(i64 %input) {{
            \\entry:
            \\  %result = urem i64 %input, {d}
            \\  ret i64 %result
            \\}}
        , .{divisor});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var output = machine.MachineFunction.init("remainder", .{ .int = 64 });
        defer output.deinit(std.testing.allocator);
        const selected = try selector.tryLower(std.testing.allocator, &output, module.functions.items[0]);
        if (divisor == 0 or divisor == 3 or divisor == -1) {
            try std.testing.expect(selected == .unsupported);
            try std.testing.expectEqual(@as(usize, 0), output.instructions.items.len);
            continue;
        }
        try std.testing.expectEqual(selector.SelectionResult.selected, selected);
        try verify.verifyFunction(output);
        const bytes = try encoding.encodeFunction(std.testing.allocator, output);
        defer std.testing.allocator.free(bytes);
        const executable = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(executable);
        @memcpy(executable[0..bytes.len], bytes);
        const run: *const fn (u64) callconv(.c) u64 = @ptrCast(executable.ptr);
        const unsigned_divisor: u64 = @truncate(@as(u128, @bitCast(divisor)));
        for ([_]u64{ 0, 1, 4095, 4096, 0x100000001, 0x8000000000000000, std.math.maxInt(u64) }) |value|
            try std.testing.expectEqual(value % unsigned_divisor, run(value));
    }
}
