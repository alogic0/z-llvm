const std = @import("std");
const ir = @import("../../../ir.zig");
const pairs = @import("word_pair_values.zig");
const machine = @import("../machine.zig");

test "constant pair stores split complete fields without an SSA constructor" {
    for ([_]struct { ty: []const u8, value: []const u8 }{
        .{ .ty = "{ ptr, i64 }", .value = "{ ptr inttoptr (i64 8 to ptr), i64 -1 }" },
        .{ .ty = "{ i64, ptr }", .value = "{ i64 4294967296, ptr null }" },
        .{ .ty = "{ ptr, ptr }", .value = "{ ptr null, ptr inttoptr (i64 1 to ptr) }" },
        .{ .ty = "{ i64, i64 }", .value = "zeroinitializer" },
    }) |case| {
        const text = try std.fmt.allocPrint(std.testing.allocator,
            \\define void @store_pair(ptr %destination) {{
            \\entry:
            \\  store {s} {s}, ptr %destination, align 16
            \\  ret void
            \\}}
        , .{ case.ty, case.value });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const original = module.functions.items[0];
        const expanded = (try pairs.legalize(arena.allocator(), original, null)).?;
        try std.testing.expectEqual(@as(usize, 1), original.blocks.items[0].instructions.items.len);
        var stores: usize = 0;
        var addresses: usize = 0;
        for (expanded.blocks.items[0].instructions.items) |inst| switch (inst.kind) {
            .store => |store| {
                try std.testing.expect(store.ty == .ptr or store.ty.eql(.{ .int = 64 }));
                try std.testing.expectEqual(@as(?u64, 8), store.attrs.@"align");
                stores += 1;
            },
            .gep => |gep| {
                try std.testing.expectEqual(@as(i128, @intCast(addresses * 8)), gep.indices.items[0].value.int);
                addresses += 1;
            },
            else => return error.TestUnexpectedResult,
        };
        try std.testing.expectEqual(@as(usize, 2), stores);
        try std.testing.expectEqual(@as(usize, 2), addresses);
        try std.testing.expect((try pairs.legalize(arena.allocator(), expanded, null)) == null);
    }
}

test "constant pair stores retain memory layout and field-list boundaries" {
    for ([_][]const u8{
        "define void @store_pair(ptr %p) {\nentry:\n store volatile { ptr, i64 } zeroinitializer, ptr %p, align 8\n ret void\n}\n",
        "define void @store_pair(ptr addrspace(1) %p) {\nentry:\n store { ptr, i64 } zeroinitializer, ptr addrspace(1) %p, align 8\n ret void\n}\n",
        "define void @store_pair(ptr %p) {\nentry:\n store { ptr, i64, i8 } zeroinitializer, ptr %p, align 8\n ret void\n}\n",
    }) |text| {
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect((try pairs.legalize(arena.allocator(), module.functions.items[0], null)) == null);
    }
    var module = try ir.Module.parse(std.testing.allocator, "define void @store_pair(ptr %p) {\nentry:\n store { ptr, i64 } zeroinitializer, ptr %p, align 8\n ret void\n}\n");
    defer module.deinit();
    for ([_][]const u8{ "E-p:64:64-i64:64", "e-p:32:32-i64:64", "e-p:64:64-i64:64-a:128:128" }) |layout| {
        const context: machine.ReadOnlyModuleContext = .{ .globals = &.{}, .named_types = &.{}, .target_datalayout = layout };
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect((try pairs.legalize(arena.allocator(), module.functions.items[0], &context)) == null);
    }
}
