const std = @import("std");
const ir = @import("../../../ir.zig");
const forms = @import("wide_integer_forms.zig");

test "wide integer carriers preserve source ABI declarations and reach a fixed point" {
    for ([_]u16{ 65, 96 }) |bits| {
        const source = try std.fmt.allocPrint(std.testing.allocator, "declare i{d} @callee(i{d})\ndefine i{d} @f(i{d} %a, i1 %cond) {{\nentry:\n br i1 %cond, label %left, label %right\nleft:\n %b = call i{d} @callee(i{d} %a)\n br label %join\nright:\n %c = sub i{d} %a, 1\n br label %join\njoin:\n %p = phi i{d} [ %b, %left ], [ %c, %right ]\n %r = ashr i{d} %p, 1\n ret i{d} %r\n}}\n", .{ bits, bits, bits, bits, bits, bits, bits, bits, bits, bits });
        defer std.testing.allocator.free(source);
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        try module.verify();
        const original = module.functions.items[0];
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const private = (try forms.legalize(arena.allocator(), original)).?;
        try std.testing.expectEqual(bits, original.ret_ty.int);
        try std.testing.expectEqual(bits, original.params.items[0].ty.int);
        try std.testing.expectEqual(bits, module.declarations.items[0].ret_ty.int);
        try std.testing.expectEqual(@as(u16, 128), private.ret_ty.int);
        try std.testing.expectEqual(@as(u16, 128), private.params.items[0].ty.int);
        try std.testing.expect(!std.mem.eql(u8, original.params.items[0].name, private.params.items[0].name));
        try std.testing.expect((try forms.legalize(arena.allocator(), private)) == null);
        for (private.blocks.items) |block| for (block.instructions.items) |inst| {
            if (inst.kind == .phi) try std.testing.expectEqual(@as(u16, 128), inst.kind.phi.ty.int);
            if (inst.kind == .call) {
                try std.testing.expectEqual(@as(u16, 128), inst.kind.call.ret_ty.int);
                try std.testing.expectEqual(@as(u16, 128), inst.kind.call.args.items[0].ty.int);
            }
        };
    }
}

test "wide integer carriers reject memory other widths and unsupported ABI forms" {
    for ([_][]const u8{
        "define i96 @f(ptr %p) {\nentry:\n %r = load i96, ptr %p\n ret i96 %r\n}\n",
        "define void @f(ptr %p, i65 %a) {\nentry:\n store i65 %a, ptr %p\n ret void\n}\n",
        "define i80 @f(i80 %a) {\nentry:\n %r = add i80 %a, 1\n ret i80 %r\n}\n",
        "define i96 @f(i96 signext %a) {\nentry:\n ret i96 %a\n}\n",
        "define i96 @f(i96 %a, i96 %b, i96 %c, i64 %d) {\nentry:\n ret i96 %a\n}\n",
        "declare i96 @callee(...)\ndefine i96 @f(i96 %a) {\nentry:\n %r = call i96 (...) @callee(i96 %a)\n ret i96 %r\n}\n",
    }) |source| {
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect((try forms.legalize(arena.allocator(), module.functions.items[0])) == null);
    }
}

test "physical integer carriers validate source promises and keep legacy boundaries" {
    for ([_]u16{ 65, 66, 80, 96, 127 }) |bits| {
        const source = try std.fmt.allocPrint(std.testing.allocator, "declare i{0d} @callee(i64, i64, i64, i64, i64, i{0d}, i64)\n" ++
            "define noundef i{0d} @f(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i{0d} noundef range(i{0d} -1, 0) %wide, i64 %tail) {{\nentry:\n" ++
            " %r = call noundef i{0d} @callee(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i{0d} range(i{0d} -1, 0) %wide, i64 %tail)\n ret i{0d} %r\n}}\n", .{bits});
        defer std.testing.allocator.free(source);
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        try module.verify();
        const original = module.functions.items[0];
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect((try forms.legalize(arena.allocator(), original)) == null);
        const private = (try forms.legalizeForPhysicalAbi(arena.allocator(), original)).?;
        try std.testing.expectEqual(@as(u16, 128), private.ret_ty.int);
        try std.testing.expect(private.ret_attrs == null);
        try std.testing.expect(private.params.items[5].attrs == null);
        try std.testing.expect(private.params.items[5].abi_split_integer);
        try std.testing.expect(!original.params.items[5].abi_split_integer);
        try std.testing.expect((try forms.legalizeForPhysicalAbi(arena.allocator(), private)) == null);
        try std.testing.expectEqual(bits, original.params.items[5].ty.int);
        try std.testing.expect(original.params.items[5].attrs != null);
        try std.testing.expectEqual(bits, module.declarations.items[0].params.items[5].ty.int);
        for (private.blocks.items) |block| for (block.instructions.items) |inst| if (inst.kind == .call) {
            try std.testing.expect(inst.kind.call.ret_attrs == null);
            try std.testing.expect(inst.kind.call.args.items[5].attrs == null);
            try std.testing.expect(inst.kind.call.args.items[5].abi_split_integer);
        };
    }
    for ([_][]const u8{ "signext", "zeroext", "range(i64 0, 0)", "noundef noundef", "byval(i80)" }) |attrs| {
        const source = try std.fmt.allocPrint(std.testing.allocator, "define i80 @f(i80 {s} %a) {{\nentry:\n ret i80 %a\n}}\n", .{attrs});
        defer std.testing.allocator.free(source);
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect((try forms.legalizeForPhysicalAbi(arena.allocator(), module.functions.items[0])) == null);
    }
}
