const std = @import("std");
const ir = @import("../../../ir.zig");
const forms = @import("pair_arithmetic.zig");

test "pair arithmetic private scalar expansion retains inputs and reaches a fixed point" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\define i128 @calculate(i128 %a, i128 %b) {
        \\entry:
        \\ %product = mul nuw i128 %a, %b
        \\ %shifted = ashr i128 %product, 65
        \\ %result = sdiv i128 %shifted, 1000000000
        \\ ret i128 %result
        \\}
    );
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const original = module.functions.items[0];
    const expanded = (try forms.legalize(arena.allocator(), original)).?;
    try std.testing.expectEqual(@as(usize, 3), original.blocks.items[0].instructions.items.len);
    try std.testing.expect(original.blocks.items[0].instructions.items[0].kind.binary.flags.nuw);
    try std.testing.expectEqual(original.params.items.ptr, expanded.params.items.ptr);
    try std.testing.expectEqual(original.ret_ty, expanded.ret_ty);
    try std.testing.expect((try forms.legalize(arena.allocator(), expanded)) == null);
    for (expanded.blocks.items[0].instructions.items) |inst| {
        try std.testing.expect(inst.kind != .call and inst.kind != .alloca);
        if (inst.kind == .binary) try std.testing.expect(!inst.kind.binary.flags.any());
    }
}

test "pair arithmetic unsupported divisors operands widths and vectors stay closed" {
    for ([_][]const u8{
        "define i128 @f(i128 %a, i128 %b) {\nentry:\n %r = udiv i128 %a, %b\n ret i128 %r\n}\n",
        "define i128 @f(i128 %a) {\nentry:\n %r = sdiv i128 %a, 0\n ret i128 %r\n}\n",
        "define i128 @f(i128 %a) {\nentry:\n %r = udiv i128 %a, 4294967296\n ret i128 %r\n}\n",
        "define i128 @f(i128 %a) {\nentry:\n %r = mul i128 %a, undef\n ret i128 %r\n}\n",
        "define i96 @f(i96 %a, i96 %b) {\nentry:\n %r = mul i96 %a, %b\n ret i96 %r\n}\n",
        "define <2 x i64> @f(<2 x i64> %a, <2 x i64> %b) {\nentry:\n %r = mul <2 x i64> %a, %b\n ret <2 x i64> %r\n}\n",
    }) |source| {
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect((try forms.legalize(arena.allocator(), module.functions.items[0])) == null);
    }
}
