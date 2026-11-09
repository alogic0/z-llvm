const std = @import("std");
const ir = @import("../../../ir.zig");
const forms = @import("integer_memory.zig");
const machine = @import("../machine.zig");

test "integer memory expansion preserves source types and exact private byte extents" {
    for ([_]u16{ 2, 3, 7, 9, 24, 40, 56, 65, 80, 96, 120, 127 }) |bits| {
        const source = try std.fmt.allocPrint(
            std.testing.allocator,
            "define i{d} @copy(ptr %input, ptr %output) {{\nentry:\n %value = load i{d}, ptr %input, align 1\n store i{d} %value, ptr %output, align 1\n ret i{d} %value\n}}\n",
            .{ bits, bits, bits, bits },
        );
        defer std.testing.allocator.free(source);
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        try module.verify();
        const original = module.functions.items[0];
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const view = (try forms.legalize(arena.allocator(), original, null)).?;
        try std.testing.expectEqual(original.params.items.ptr, view.params.items.ptr);
        try std.testing.expectEqual(original.ret_ty, view.ret_ty);
        try std.testing.expectEqual(bits, original.blocks.items[0].instructions.items[0].kind.load.ty.int);
        var loaded_bytes: u16 = 0;
        var stored_bytes: u16 = 0;
        for (view.blocks.items[0].instructions.items) |inst| switch (inst.kind) {
            .load => |load| {
                try std.testing.expect(load.ty.int == 8 or load.ty.int == 16 or load.ty.int == 32 or load.ty.int == 64);
                loaded_bytes += load.ty.int / 8;
            },
            .store => |store| {
                try std.testing.expect(store.ty.int == 8 or store.ty.int == 16 or store.ty.int == 32 or store.ty.int == 64);
                stored_bytes += store.ty.int / 8;
            },
            else => {},
        };
        try std.testing.expectEqual((bits + 7) / 8, loaded_bytes);
        try std.testing.expectEqual(loaded_bytes, stored_bytes);
        try std.testing.expect(try forms.legalize(arena.allocator(), view, null) == null);
        var private = module;
        private.functions = try module.functions.clone(arena.allocator());
        private.functions.items[0] = view;
        try private.verify();
        try module.verify();
    }
}

test "integer memory expansion retains native widths barriers address spaces and layout bounds" {
    for ([_][]const u8{
        "define i64 @native(ptr %p) {\nentry:\n %v = load i64, ptr %p\n ret i64 %v\n}\n",
        "define i24 @volatile(ptr %p) {\nentry:\n %v = load volatile i24, ptr %p\n ret i24 %v\n}\n",
        "define void @scope(ptr %p) {\nentry:\n store atomic i24 0, ptr %p syncscope(\"singlethread\") unordered, align 4\n ret void\n}\n",
        "define i24 @space(ptr %p) {\nentry:\n %v = load i24, ptr addrspace(1) %p\n ret i24 %v\n}\n",
        "define i129 @large(ptr %p) {\nentry:\n %v = load i129, ptr %p\n ret i129 %v\n}\n",
    }) |source| {
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect(try forms.legalize(arena.allocator(), module.functions.items[0], null) == null);
    }
    var module = try ir.Module.parse(std.testing.allocator, "define i24 @f(ptr %p) {\nentry:\n %v = load i24, ptr %p\n ret i24 %v\n}\n");
    defer module.deinit();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    for ([_][]const u8{ "E", "e-p:32:32", "e-ni:0" }) |layout| {
        const context: machine.ReadOnlyModuleContext = .{ .globals = &.{}, .named_types = &.{}, .target_datalayout = layout };
        try std.testing.expect(try forms.legalize(arena.allocator(), module.functions.items[0], &context) == null);
    }
}
