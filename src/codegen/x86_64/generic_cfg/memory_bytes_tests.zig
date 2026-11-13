const std = @import("std");
const ir = @import("../../../ir.zig");
const bytes = @import("memory_bytes.zig");
const machine = @import("../machine.zig");
const layout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128";
fn context(module: ir.Module) machine.ReadOnlyModuleContext {
    return .{ .globals = module.globals.items, .aliases = module.aliases.items, .functions = module.functions.items, .declarations = module.declarations.items, .named_types = module.named_types.items, .target_datalayout = layout };
}
test "memory byte comparisons have bounded IR and repair outgoing PHI predecessors" {
    const a = std.testing.allocator;
    for ([_]usize{ 1025, 65528, 65529, 65535, 65536 }) |bits| {
        const text = try std.fmt.allocPrint(a, "target datalayout = \"{s}\"\ndeclare void @llvm.memcpy.p0.p0.i64(ptr,ptr,i64,i1)\ndeclare void @llvm.memset.p0.i64(ptr,i8,i64,i1)\ndefine i1 @compare(ptr %p,ptr %q) {{\nentry:\n %x = load i{d},ptr %p,align 1\n %y = load i{d},ptr %q,align 1\n %same = icmp eq i{d} %x,%y\n br i1 %same,label %join,label %other\nother:\n br label %join\njoin:\n %answer = phi i1 [%same,%entry],[false,%other]\n ret i1 %answer\n}}\n", .{ layout, bits, bits, bits });
        defer a.free(text);
        var module = try ir.Module.parse(a, text);
        defer module.deinit();
        try module.verify();
        var before: std.Io.Writer.Allocating = .init(a);
        defer before.deinit();
        try module.print(&before.writer);
        var arena = std.heap.ArenaAllocator.init(a);
        defer arena.deinit();
        const own = arena.allocator();
        const ctx = context(module);
        const view = (try bytes.legalize(own, module.functions.items[0], &ctx)) orelse return error.ExpectedSnapshotView;
        var private = module;
        private.functions = try module.functions.clone(own);
        private.functions.items[0] = view;
        try private.verify();
        var instructions: usize = 0;
        for (view.blocks.items) |block| instructions += block.instructions.items.len;
        try std.testing.expect(instructions < 512);
        var after: std.Io.Writer.Allocating = .init(a);
        defer after.deinit();
        try module.print(&after.writer);
        try std.testing.expectEqualStrings(before.written(), after.written());
        try std.testing.expect(try bytes.legalize(own, view, &ctx) == null);
    }
}
test "memory byte views keep arithmetic ABI calls volatile accesses and excessive alignment closed" {
    const a = std.testing.allocator;
    for ([_][]const u8{
        "define i2048 @f(i2048 %x) {\nentry:\n ret i2048 %x\n}\n",
        "define void @f(ptr %p) {\nentry:\n %x = load i2048,ptr %p,align 1\n %y = add i2048 %x,1\n store i2048 %y,ptr %p,align 1\n ret void\n}\n",
        "declare void @callee(i2048)\ndefine void @f(ptr %p) {\nentry:\n %x = load i2048,ptr %p,align 1\n call void @callee(i2048 %x)\n ret void\n}\n",
        "define void @f(ptr %p) {\nentry:\n %x = load volatile i2048,ptr %p,align 1\n store i2048 %x,ptr %p,align 1\n ret void\n}\n",
        "define void @f() {\nentry:\n %x = alloca <1 x i65535>,align 16384\n ret void\n}\n",
    }) |body| {
        const text = try std.fmt.allocPrint(a, "target datalayout = \"{s}\"\ndeclare void @llvm.memcpy.p0.p0.i64(ptr,ptr,i64,i1)\ndeclare void @llvm.memset.p0.i64(ptr,i8,i64,i1)\n{s}", .{ layout, body });
        defer a.free(text);
        var module = try ir.Module.parse(a, text);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(a);
        defer arena.deinit();
        const ctx = context(module);
        const function = module.functions.items[0];
        try std.testing.expect(try bytes.legalize(arena.allocator(), function, &ctx) == null);
    }
}
