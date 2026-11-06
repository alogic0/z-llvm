const std = @import("std");
const ir = @import("../../../ir.zig");
const forms = @import("aligned_stack.zig");

test "aligned stack expansion preserves source and verifies bounded private storage" {
    const source = try std.Io.Dir.cwd().readFileAlloc(std.testing.io, "test/real_programs/aligned_stack.ll", std.testing.allocator, .limited(1024 * 1024));
    defer std.testing.allocator.free(source);
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var private = module;
    private.functions = try module.functions.clone(arena.allocator());
    for (module.functions.items, private.functions.items) |original, *replacement| {
        replacement.* = (try forms.legalize(arena.allocator(), original, null)).?;
        try std.testing.expect((try forms.legalize(arena.allocator(), replacement.*, null)) == null);
        try std.testing.expect(replacement.blocks.items.ptr != original.blocks.items.ptr);
        try std.testing.expectEqualStrings("align 16", replacement.blocks.items[0].instructions.items[0].kind.alloca.attrs.?);
    }
    try private.verify();
    try module.verify();
    try std.testing.expectEqualStrings("align 32", module.functions.items[0].blocks.items[0].instructions.items[0].kind.alloca.attrs.?);
}

test "aligned stack expansion leaves dynamic huge and address space objects closed" {
    for ([_][]const u8{
        "alloca [4 x i8], align 8192",
        "alloca [65536 x i8], align 32",
        "alloca [4 x i8], i64 %count, align 32",
        "alloca [4 x i8], align 32, addrspace(1)",
    }) |alloca| {
        const source = try std.fmt.allocPrint(std.testing.allocator, "define void @f(i64 %count) {{\nentry:\n %v = {s}\n ret void\n}}\n", .{alloca});
        defer std.testing.allocator.free(source);
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect((try forms.legalize(arena.allocator(), module.functions.items[0], null)) == null);
    }
}
