const std = @import("std");
const integers = @import("wide_integers.zig");
const ir = @import("../ir.zig");

test "wide decimal payload retains exact sign bit and final partial word" {
    const a = std.testing.allocator;
    const negative = try integers.decode(a, 257, .{ .constant_expr = "-115792089237316195423570985008687907853269984665640564039457584007913129639936" });
    defer a.free(negative);
    try std.testing.expectEqualSlices(u64, &.{ 0, 0, 0, 0, 1 }, negative);
    const positive = try integers.decode(a, 257, .{ .constant_expr = "115792089237316195423570985008687907853269984665640564039457584007913129639935" });
    defer a.free(positive);
    const all = std.math.maxInt(u64);
    try std.testing.expectEqualSlices(u64, &.{ all, all, all, all, 0 }, positive);
    const small = try integers.decode(a, 140, .{ .int = -1 });
    defer a.free(small);
    try std.testing.expectEqualSlices(u64, &.{ all, all, 4095 }, small);
    try std.testing.expectError(error.WideIntegerLiteralOverflow, integers.decode(a, 129, .{ .constant_expr = "680564733841876926926749214863536422912" }));
}

test "wide source spelling and variadic opcodes preserve typed operands" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\define i1 @wide(ptr %p) {
        \\entry:
        \\ %x = load i65536, ptr %p
        \\ %y = trunc nuw i65536 %x to i65528
        \\ %z = zext i65528 %y to i65536
        \\ %eq = icmp eq i65536 %x, %z
        \\ ret i1 %eq
        \\}
    );
    defer module.deinit();
    try module.verify();
    const ty = module.functions.items[0].blocks.items[0].instructions.items[0].kind.load.ty;
    try std.testing.expectEqual(@as(?u32, 65536), integers.width(ty));
    try std.testing.expectEqualStrings("i65536", ty.aggregate);
}
