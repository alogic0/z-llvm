const std = @import("std");
const ir = @import("../../../ir.zig");
const normalization = @import("semantic_normalization.zig");

test "semantic normalization checks widths before selection and is repeatable" {
    for ([_]u16{ 1, 7, 8, 16, 17, 31, 33, 52, 63 }) |bits| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "define i{d} @f(i{d} %a, i{d} %b) {{\nentry:\n %s = ashr i{d} %a, 0\n %c = icmp ule i{d} %s, %b\n %v = select i1 %c, i{d} %s, i{d} %b\n ret i{d} %v\n}}\n", .{ bits, bits, bits, bits, bits, bits, bits, bits });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const original = module.functions.items[0];
        try std.testing.expectError(error.UnsupportedSemanticNormalization, normalization.check(original));
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const normalized = try normalization.normalize(arena.allocator(), original, null);
        try normalization.check(normalized.ir_function);
        const repeated = try normalization.normalize(arena.allocator(), normalized.ir_function, null);
        try std.testing.expectEqual(normalized.ir_function.blocks.items.ptr, repeated.ir_function.blocks.items.ptr);
        try std.testing.expectEqual(@as(usize, 3), original.blocks.items[0].instructions.items.len);
        try std.testing.expectEqual(bits, original.blocks.items[0].instructions.items[0].kind.binary.ty.int);
        try std.testing.expectEqual(original.params.items.ptr, normalized.ir_function.params.items.ptr);
        try std.testing.expect(original.ret_ty.eql(normalized.ir_function.ret_ty));
        // Verify the private function in its original module context without
        // transferring ownership of borrowed names, parameters or declarations.
        module.functions.items[0] = normalized.ir_function;
        const verified = module.verify();
        module.functions.items[0] = original;
        try verified;
    }
}

test "semantic normalization rejects an undischargeable invariant" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\define i7 @f(i7 %a) {
        \\entry:
        \\ %r = ashr i7 %a, undef
        \\ ret i7 %r
        \\}
    );
    defer module.deinit();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    try std.testing.expectError(error.UnsupportedSemanticNormalization, normalization.normalize(arena.allocator(), module.functions.items[0], null));
}

test "semantic normalization refines undefined PHI edges and preserves every defined path" {
    const machine = @import("../machine.zig");
    const selector = @import("../generic_cfg_selector.zig");
    const encoding = @import("../../../mc/encoding.zig");
    for ([_]u16{ 1, 8, 16, 32, 64, 128 }) |bits| for ([_][]const u8{ "undef", "poison" }) |unknown| {
        const cast_in = if (bits < 64) "trunc" else if (bits > 64) "zext" else "bitcast";
        const cast_out = if (bits < 64) "zext" else if (bits > 64) "trunc" else "bitcast";
        const text = try std.fmt.allocPrint(
            std.testing.allocator,
            "define i64 @f(i64 %input, i64 %flag) {{\nentry:\n %cond = icmp ne i64 %flag, 0\n br i1 %cond, label %left, label %right\nleft:\n br label %join\nright:\n %x = {s} i64 %input to i{d}\n br label %join\njoin:\n %p = phi i{d} [ {s}, %left ], [ %x, %right ]\n %v = select i1 %cond, i{d} 0, i{d} %p\n %wide = {s} i{d} %v to i64\n ret i64 %wide\n}}\n",
            .{ cast_in, bits, bits, unknown, bits, bits, cast_out, bits },
        );
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const original = module.functions.items[0];
        const normalized = try normalization.normalize(arena.allocator(), original, null);
        try normalization.check(normalized.ir_function);
        const expected_unknown: ir.Value = if (std.mem.eql(u8, unknown, "undef")) .undef else .poison;
        try std.testing.expect(original.blocks.items[3].instructions.items[0].kind.phi.incoming.items[0].value.eql(expected_unknown));
        const repeated = try normalization.normalize(arena.allocator(), normalized.ir_function, null);
        try std.testing.expectEqual(normalized.ir_function.blocks.items.ptr, repeated.ir_function.blocks.items.ptr);
        var output = machine.MachineFunction.init("f", .{ .int = 64 });
        defer output.deinit(std.testing.allocator);
        const selected = try selector.tryLower(std.testing.allocator, &output, original);
        try std.testing.expectEqual(selector.SelectionResult.selected, selected);
        const bytes = try encoding.encodeFunction(std.testing.allocator, output);
        defer std.testing.allocator.free(bytes);
        const memory = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(memory);
        @memcpy(memory[0..bytes.len], bytes);
        const call: *const fn (u64, u64) callconv(.c) u64 = @ptrCast(memory.ptr);
        for (0..64) |i| {
            const value = @as(u64, 0x91e5d7c3092fb6a8) +% (i *% 0x531bb);
            const mask = if (bits >= 64) std.math.maxInt(u64) else (@as(u64, 1) << @as(u6, @intCast(bits))) - 1;
            try std.testing.expectEqual(value & mask, call(value, 0));
            try std.testing.expectEqual(@as(u64, 0), call(value, 1));
        }
    };
}
