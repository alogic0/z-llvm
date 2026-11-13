const std = @import("std");
const ir = @import("../../../ir.zig");
const addresses = @import("../symbol_address.zig");
test "symbolic pointer round trips use exact typed modular offsets and bounded relocations" {
    for ([_]struct { text: []const u8, symbol: []const u8, offset: i32 }{
        .{ .text = "inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8, ptr @object, i64 4) to i64), i64 4) to ptr)", .symbol = "object", .offset = 0 },
        .{ .text = "inttoptr (i64 add (i64 ptrtoint (ptr @object to i64), i64 -8) to ptr)", .symbol = "object", .offset = -8 },
        .{ .text = "inttoptr (i64 sub (i64 ptrtoint (ptr @object to i64), i64 18446744073709551615) to ptr)", .symbol = "object", .offset = 1 },
        .{ .text = "inttoptr (i64 add (i64 ptrtoint (ptr getelementptr (i8, ptr @\"a,b c\", i64 1) to i64), i64 18446744073709551615) to ptr)", .symbol = "\"a,b c\"", .offset = 0 },
        .{ .text = "inttoptr (i64 add (i64 ptrtoint (ptr @object to i64), i64 2147483647) to ptr)", .symbol = "object", .offset = 2147483647 },
        .{ .text = "inttoptr (i64 sub (i64 ptrtoint (ptr @object to i64), i64 2147483648) to ptr)", .symbol = "object", .offset = -2147483648 },
    }) |row| {
        const found = addresses.fromValue(.{ .constant_expr = row.text }) orelse return error.AddressMissing;
        try std.testing.expectEqualStrings(row.symbol, found.symbol);
        try std.testing.expectEqual(row.offset, found.addend);
    }
}
test "symbolic pointer round trips reject unproved widths nesting flags and relocation overflow" {
    for ([_][]const u8{
        "inttoptr (i32 add (i32 ptrtoint (ptr @object to i32), i32 1) to ptr)",
        "inttoptr (i64 sub (i32 ptrtoint (ptr @object to i32), i64 1) to ptr)",
        "inttoptr (i64 sub (i64 ptrtoint (ptr addrspace(1) @object to i64), i64 1) to ptr)",
        "inttoptr (i64 sub (i64 ptrtoint (ptr %local to i64), i64 1) to ptr)",
        "inttoptr (i64 sub (i64 ptrtoint (ptr @object to i64), i32 1) to ptr)",
        "inttoptr (i64 sub (i64 ptrtoint (ptr @object to i64), i64 %dynamic) to ptr)",
        "inttoptr (i64 sub (i64 ptrtoint (ptr @object to i64), i64 ptrtoint (ptr @other to i64)) to ptr)",
        "inttoptr (i64 add nsw (i64 ptrtoint (ptr @object to i64), i64 1) to ptr)",
        "inttoptr (i64 mul (i64 ptrtoint (ptr @object to i64), i64 1) to ptr)",
        "inttoptr (i64 add (i64 ptrtoint (ptr @object to i64), i64 2147483648) to ptr)",
        "inttoptr (i64 sub (i64 ptrtoint (ptr @object to i64), i64 2147483649) to ptr)",
        "inttoptr (i64 sub (i64 ptrtoint (ptr @object to i64), i64 18446744073709551616) to ptr)",
        "inttoptr (i64 sub (i64 ptrtoint (ptr inttoptr (i64 add (i64 ptrtoint (ptr @object to i64), i64 1) to ptr) to i64), i64 1) to ptr)",
        "inttoptr (i64 sub (i64 ptrtoint (ptr @object to i64), i64 1, i64 2) to ptr)",
        "inttoptr (i64 sub (i64 ptrtoint (ptr @object to i64), i64 1) to ptr) trailing",
    }) |text| try std.testing.expect(addresses.fromValue(.{ .constant_expr = text }) == null);
}
test "symbolic pointer views retain source expressions and require integral native layout" {
    const a = std.testing.allocator;
    var module = try ir.Module.parse(a,
        \\@object = global [16 x i8] zeroinitializer,align 8
        \\define i1 @probe(ptr %expected) {
        \\entry:
        \\ %equal = icmp eq ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @object,i64 4) to i64),i64 4) to ptr),%expected
        \\ ret i1 %equal
        \\}
    );
    defer module.deinit();
    try module.verify();
    const machine = @import("../machine.zig");
    var context: machine.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = &.{}, .target_datalayout = null };
    var arena = std.heap.ArenaAllocator.init(a);
    defer arena.deinit();
    const original = module.functions.items[0];
    const before = original.blocks.items[0].instructions.items[0].kind.icmp.lhs.constant_expr;
    const view = (try @import("pointer_values.zig").legalize(arena.allocator(), original, &context)).?;
    try std.testing.expect(view.blocks.items[0].instructions.items[0].kind == .gep);
    try std.testing.expectEqualStrings(before, original.blocks.items[0].instructions.items[0].kind.icmp.lhs.constant_expr);
    var selected = try @import("../../../compilation.zig").select(a, "x86_64-unknown-linux-gnu", original, .{ .generic_cfg_selector = true, .module_context = &context });
    defer selected.deinit(a);
    try @import("../verify.zig").verifyFunction(selected);
    for ([_][]const u8{ "E-p:64:64", "e-p:32:32", "e-p:64:64-ni:0" }) |layout| {
        context.target_datalayout = layout;
        try std.testing.expect((try @import("pointer_values.zig").legalize(arena.allocator(), original, &context)) == null);
    }
    try module.verify();
}
