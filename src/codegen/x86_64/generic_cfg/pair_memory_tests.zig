const std = @import("std");
const ir = @import("../../../ir.zig");
const forms = @import("pair_memory.zig");

test "pair memory expansion preserves access extent alignment and source IR" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\define i128 @copy(ptr %in, ptr %out) {
        \\entry:
        \\ %v = load i128, ptr %in, align 1
        \\ store i128 %v, ptr %out, align 16
        \\ ret i128 %v
        \\}
    );
    defer module.deinit();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const original = module.functions.items[0];
    const expanded = (try forms.legalize(arena.allocator(), original, null)).?;
    try std.testing.expectEqual(@as(usize, 2), original.blocks.items[0].instructions.items.len);
    try std.testing.expectEqual(@as(u16, 128), original.blocks.items[0].instructions.items[0].kind.load.ty.int);
    try std.testing.expect((try forms.legalize(arena.allocator(), expanded, null)) == null);
    var loads: usize = 0;
    var stores: usize = 0;
    for (expanded.blocks.items[0].instructions.items) |inst| {
        if (inst.kind == .load) {
            loads += 1;
            try std.testing.expectEqual(@as(u16, 64), inst.kind.load.ty.int);
            try std.testing.expectEqual(@as(u64, 1), inst.kind.load.attrs.@"align".?);
        }
        if (inst.kind == .store) {
            stores += 1;
            try std.testing.expectEqual(@as(u64, if (stores == 1) 16 else 8), inst.kind.store.attrs.@"align".?);
        }
    }
    try std.testing.expectEqual(@as(usize, 2), loads);
    try std.testing.expectEqual(@as(usize, 2), stores);
}

test "pair memory expansion leaves atomic volatile and nondefault address spaces closed" {
    for ([_][]const u8{
        "load volatile i128, ptr %p, align 16",
        "load atomic i128, ptr %p seq_cst, align 16",
        "load i128, ptr addrspace(1) %p, align 16",
        "load i96, ptr %p, align 16",
    }) |load| {
        const source = try std.fmt.allocPrint(std.testing.allocator, "define void @f(ptr %p) {{\nentry:\n %v = {s}\n ret void\n}}\n", .{load});
        defer std.testing.allocator.free(source);
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect((try forms.legalize(arena.allocator(), module.functions.items[0], null)) == null);
    }
}
