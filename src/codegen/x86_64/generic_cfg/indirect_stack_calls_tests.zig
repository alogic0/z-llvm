const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const selector = @import("../generic_cfg_selector.zig");
const verify = @import("../verify.zig");
const encoding = @import("../../../mc/encoding.zig");
const forms = @import("scalar_forms.zig");

fn executable(module: ir.Module) ![]align(std.heap.page_size_min) u8 {
    const function = module.functions.items[0];
    var output = machine.MachineFunction.init(function.name, function.ret_ty);
    defer output.deinit(std.testing.allocator);
    const selected = try selector.tryLower(std.testing.allocator, &output, function);
    if (selected == .unsupported) std.debug.print("call ABI {s}: {s}\n", .{ function.name, selected.unsupported.detail() });
    try std.testing.expectEqual(selector.SelectionResult.selected, selected);
    try verify.verifyFunction(output);
    const code = try encoding.encodeFunction(std.testing.allocator, output);
    defer std.testing.allocator.free(code);
    const memory = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    @memcpy(memory[0..code.len], code);
    return memory;
}

fn callback(a: u64, b: u64) callconv(.c) u64 {
    return a +% (b *% 3);
}

test "call ABI indirect target survives final use argument permutations and live sources" {
    const text =
        \\define i64 @caller(ptr %callee, i64 %a, i64 %b, ptr %out) {
        \\entry:
        \\  %r = call i64 %callee(i64 %b, i64 %a)
        \\  store i64 %r, ptr %out, align 8
        \\  %live = xor i64 %a, %b
        \\  %result = add i64 %live, %r
        \\  ret i64 %result
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    const code = try executable(module);
    defer std.posix.munmap(code);
    const run: *const fn (*const fn (u64, u64) callconv(.c) u64, u64, u64, *u64) callconv(.c) u64 = @ptrCast(code.ptr);
    const values = [_]u64{ 0, 1, 0x8000000000000000, std.math.maxInt(u64) };
    for (values) |a| for (values) |b| {
        var out: u64 = 0;
        try std.testing.expectEqual((a ^ b) +% callback(b, a), run(callback, a, b, &out));
        try std.testing.expectEqual(callback(b, a), out);
    };
}

test "call ABI saturating subtraction handles underflow high bits and equal loaded operands" {
    for ([_]u16{ 32, 64 }) |bits| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "declare i{d} @llvm.usub.sat.i{d}(i{d}, i{d})\n" ++
            "define i{d} @sat(ptr %ap, ptr %bp, ptr %out) {{\nentry:\n" ++
            "  %a = load i{d}, ptr %ap\n  %b = load i{d}, ptr %bp\n" ++
            "  %r = call i{d} @llvm.usub.sat.i{d}(i{d} %a, i{d} %b)\n" ++
            "  store i{d} %r, ptr %out\n  %live = xor i{d} %a, %b\n  ret i{d} %live\n}}\n", .{ bits, bits, bits, bits, bits, bits, bits, bits, bits, bits, bits, bits, bits, bits });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const code = try executable(module);
        defer std.posix.munmap(code);
        const values = [_]u64{ 0, 1, 0xffffffff, 0x8000000000000000, std.math.maxInt(u64) };
        for (values) |a| for (values) |b| {
            if (bits == 32) {
                const x: u32 = @truncate(a);
                const y: u32 = @truncate(b);
                var out: u32 = 0;
                const run: *const fn (*const u32, *const u32, *u32) callconv(.c) u32 = @ptrCast(code.ptr);
                try std.testing.expectEqual(x ^ y, run(&x, &y, &out));
                try std.testing.expectEqual(x -| y, out);
            } else {
                var out: u64 = 0;
                const run: *const fn (*const u64, *const u64, *u64) callconv(.c) u64 = @ptrCast(code.ptr);
                try std.testing.expectEqual(a ^ b, run(&a, &b, &out));
                try std.testing.expectEqual(a -| b, out);
            }
        };
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const view = (try forms.legalize(arena.allocator(), module.functions.items[0])).?;
        try std.testing.expect(try forms.legalize(arena.allocator(), view) == null);
        try std.testing.expect(module.functions.items[0].blocks.items[0].instructions.items[2].kind == .call);
        try module.verify();
    }
}

test "call ABI constant identities and reversed equality preserve live values and exact width" {
    for ([_]u16{ 32, 64 }) |bits| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "define i{d} @constant(i{d} %a, ptr %out) {{\nentry:\n" ++
            "  %live = xor i{d} %a, 55\n  %constant = add nuw nsw i{d} -1, 0\n" ++
            "  store i{d} %constant, ptr %out\n  %c = icmp eq i{d} 0, %a\n" ++
            "  %bit = zext i1 %c to i{d}\n  %result = add i{d} %live, %bit\n  ret i{d} %result\n}}\n", .{ bits, bits, bits, bits, bits, bits, bits, bits, bits });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const code = try executable(module);
        defer std.posix.munmap(code);
        for ([_]u64{ 0, 1, 0xffffffff, 0x8000000000000000, std.math.maxInt(u64) }) |x| {
            if (bits == 32) {
                const a: u32 = @truncate(x);
                var out: u32 = 0;
                const run: *const fn (u32, *u32) callconv(.c) u32 = @ptrCast(code.ptr);
                try std.testing.expectEqual((a ^ 55) +% @as(u32, @intFromBool(a == 0)), run(a, &out));
                try std.testing.expectEqual(std.math.maxInt(u32), out);
            } else {
                var out: u64 = 0;
                const run: *const fn (u64, *u64) callconv(.c) u64 = @ptrCast(code.ptr);
                try std.testing.expectEqual((x ^ 55) +% @as(u64, @intFromBool(x == 0)), run(x, &out));
                try std.testing.expectEqual(std.math.maxInt(u64), out);
            }
        }
    }
}

test "call ABI indirect unsupported envelopes roll back without publishing machine code" {
    const cases = [_][]const u8{
        "define i64 @f(ptr %p) {\nentry:\n  %r = musttail call i64 %p()\n  ret i64 %r\n}\n",
        "define i64 @f(ptr %p) {\nentry:\n  %r = call coldcc i64 %p()\n  ret i64 %r\n}\n",
        "define i64 @f(ptr %p) {\nentry:\n  %r = call i64 (i64, ...) %p(i64 1, i64 2)\n  ret i64 %r\n}\n",
        "define double @f(ptr %p) {\nentry:\n  %r = call double %p()\n  ret double %r\n}\n",
        "define i64 @f(ptr %p, ptr %a) {\nentry:\n  %r = call i64 %p(ptr byval(i64) %a)\n  ret i64 %r\n}\n",
        "define i64 @f(ptr %p) {\nentry:\n  %r = call i64 %p() [ \"deopt\"() ]\n  ret i64 %r\n}\n",
        "define i64 @f(ptr %p) {\nentry:\n  %r = call i64 %p(i64 1, i64 2, i64 3, i64 4, i64 5, i64 6, i128 7)\n  ret i64 %r\n}\n",
        "define i64 @f(ptr %p) {\nentry:\n  %r = call i64 %p(i64 1, i64 2, i64 3, i64 4, i64 5, i64 6, i64 7, i64 8, i64 9, i64 10, i64 11, i64 12, i64 13, i64 14, i64 15, i64 16, i64 17)\n  ret i64 %r\n}\n",
    };
    for (cases) |text| {
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        var output = machine.MachineFunction.init("f", module.functions.items[0].ret_ty);
        defer output.deinit(std.testing.allocator);
        const selected = selector.tryLower(std.testing.allocator, &output, module.functions.items[0]) catch null;
        if (selected) |result| {
            if (result != .unsupported) std.debug.print("unexpected call admission: {s}\n", .{text});
            try std.testing.expect(result == .unsupported);
        }
        try std.testing.expectEqual(@as(usize, 0), output.instructions.items.len);
        try std.testing.expectEqual(@as(usize, 0), output.owned_labels.items.len);
    }
}
