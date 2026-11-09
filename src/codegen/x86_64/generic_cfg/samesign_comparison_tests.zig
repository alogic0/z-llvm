const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const selector = @import("../generic_cfg_selector.zig");
const normalization = @import("semantic_normalization.zig");
const verify = @import("../verify.zig");
const encoding = @import("../../../mc/encoding.zig");

fn executable(function: machine.MachineFunction) ![]align(std.heap.page_size_min) u8 {
    try verify.verifyFunction(function);
    const bytes = try encoding.encodeFunction(std.testing.allocator, function);
    defer std.testing.allocator.free(bytes);
    const code = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    @memcpy(code[0..bytes.len], bytes);
    return code;
}

fn compare(predicate: ir.IcmpPredicate, a: u64, b: u64, sign_bit: u64) bool {
    const sa = a ^ sign_bit;
    const sb = b ^ sign_bit;
    return switch (predicate) {
        .eq => a == b,
        .ne => a != b,
        .ult => a < b,
        .ule => a <= b,
        .ugt => a > b,
        .uge => a >= b,
        .slt => sa < sb,
        .sle => sa <= sb,
        .sgt => sa > sb,
        .sge => sa >= sb,
    };
}

test "samesign comparisons normalize dirty carriers and preserve every defined input" {
    for ([_]u16{ 1, 3, 6, 7, 8, 11, 16, 21, 31, 32, 37, 52, 63, 64 }) |bits|
        for (std.enums.values(ir.IcmpPredicate)) |predicate| {
            const text = try std.fmt.allocPrint(std.testing.allocator, "define i64 @compare(i64 %input_a, i64 %input_b) {{\nentry:\n" ++
                " %a = {s} i64 %input_a to i{d}\n %b = {s} i64 %input_b to i{d}\n" ++
                " %flag = icmp samesign {s} i{d} %a, %b\n %result = zext i1 %flag to i64\n ret i64 %result\n}}\n", .{ if (bits == 64) "bitcast" else "trunc", bits, if (bits == 64) "bitcast" else "trunc", bits, @tagName(predicate), bits });
            defer std.testing.allocator.free(text);
            var module = try ir.Module.parse(std.testing.allocator, text);
            defer module.deinit();
            try module.verify();
            const original = module.functions.items[0];
            var output = machine.MachineFunction.init("compare", .{ .int = 64 });
            defer output.deinit(std.testing.allocator);
            const selected = try selector.tryLower(std.testing.allocator, &output, original);
            if (selected == .unsupported) std.debug.print("samesign i{d} {s}: {s}\n", .{ bits, @tagName(predicate), selected.unsupported.detail() });
            try std.testing.expect(selected == .selected);
            const code = try executable(output);
            defer std.posix.munmap(code);
            const run: *const fn (u64, u64) callconv(.c) u64 = @ptrCast(code.ptr);
            const sign_bit = @as(u64, 1) << @as(u6, @intCast(bits - 1));
            const mask = if (bits == 64) std.math.maxInt(u64) else (sign_bit << 1) - 1;
            const values = [_]u64{ 0, 1, 2, 3, sign_bit - 1, sign_bit, mask, 0xdeadbeef00000100, 0x123456789abcdef0, std.math.maxInt(u64) };
            for (values) |input_a| for (values) |input_b| {
                const a = input_a & mask;
                const b = input_b & mask;
                if ((a ^ b) & sign_bit != 0) continue; // Other source inputs produce poison.
                try std.testing.expectEqual(@as(u64, @intFromBool(compare(predicate, a, b, sign_bit))), run(input_a, input_b));
            };
            try std.testing.expect(original.blocks.items[0].instructions.items[2].kind.icmp.samesign);
            try std.testing.expectEqual(bits, original.blocks.items[0].instructions.items[2].kind.icmp.operand_ty.int);
        };
}

test "samesign immediate comparisons accept negative and unsigned-spelled bit patterns" {
    for ([_]u16{ 8, 11, 16, 21, 32, 37, 63 }) |bits| for ([_]ir.IcmpPredicate{ .ult, .ule, .ugt, .uge, .slt, .sle, .sgt, .sge }) |predicate| {
        const sign_bit = @as(u64, 1) << @as(u6, @intCast(bits - 1));
        const mask = (sign_bit << 1) - 1;
        for ([_]i128{ -1, -7, 100, sign_bit, mask }) |literal| {
            const text = try std.fmt.allocPrint(std.testing.allocator, "define i64 @compare(i64 %input) {{\nentry:\n %a = trunc i64 %input to i{d}\n" ++
                " %flag = icmp samesign {s} i{d} %a, {d}\n %result = zext i1 %flag to i64\n ret i64 %result\n}}\n", .{ bits, @tagName(predicate), bits, literal });
            defer std.testing.allocator.free(text);
            var module = try ir.Module.parse(std.testing.allocator, text);
            defer module.deinit();
            try module.verify();
            var output = machine.MachineFunction.init("compare", .{ .int = 64 });
            defer output.deinit(std.testing.allocator);
            const selected = try selector.tryLower(std.testing.allocator, &output, module.functions.items[0]);
            if (selected == .unsupported) std.debug.print("samesign literal i{d} {s} {d}: {s}\n", .{ bits, @tagName(predicate), literal, selected.unsupported.detail() });
            try std.testing.expect(selected == .selected);
            const code = try executable(output);
            defer std.posix.munmap(code);
            const run: *const fn (u64) callconv(.c) u64 = @ptrCast(code.ptr);
            const rhs = @as(u64, @truncate(@as(u128, @bitCast(literal)))) & mask;
            for ([_]u64{ 0, 1, sign_bit - 1, sign_bit, mask - 1, mask, 0xdeadbeef00000100, std.math.maxInt(u64) }) |input| {
                const lhs = input & mask;
                if ((lhs ^ rhs) & sign_bit != 0) continue;
                try std.testing.expectEqual(@as(u64, @intFromBool(compare(predicate, lhs, rhs, sign_bit))), run(input));
            }
        }
    };
}
