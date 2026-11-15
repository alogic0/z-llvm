const std = @import("std");
const ir = @import("../../../ir.zig");
const forms = @import("pair_memory.zig");

test "scalar FP memory fallback preserves recognized table loads and ordinary pointer transport" {
    const elements: [16][]const u8 = @splat("double 1.250000e+00");
    const initializer = try std.mem.join(std.testing.allocator, ",", &elements);
    defer std.testing.allocator.free(initializer);
    for ([_]struct { kind: []const u8 = "constant", stride: []const u8 = "[8 x i8]", retained: bool }{
        .{ .retained = true },
        .{ .kind = "global", .retained = false },
        .{ .stride = "double", .retained = false },
    }) |case| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128\"\n@table = private {s} [16 x double] [{s}], align 8\ndefine double @read(ptr %ordinary,i64 %input) {{\nentry:\n %index = and i64 %input,15\n %p = getelementptr {s},ptr @table,i64 %index\n %source = load double,ptr %ordinary,align 1\n %value = load double,ptr %p,align 8\n %sum = fadd double %source,%value\n ret double %sum\n}}\n", .{ case.kind, initializer, case.stride });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const context: @import("../machine.zig").ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout };
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const original = module.functions.items[0];
        const expanded = (try forms.legalizeScalarPointers(arena.allocator(), original, &context)).?;
        var loads: usize = 0;
        for (expanded.blocks.items[0].instructions.items) |inst| {
            if (inst.kind != .load) continue;
            loads += 1;
            const expected: ir.Type = if (inst.kind.load.ptr.eql(.{ .named = "p" }) and case.retained) .double else .{ .int = 64 };
            try std.testing.expect(inst.kind.load.ty.eql(expected));
        }
        try std.testing.expectEqual(@as(usize, 2), loads);
        try std.testing.expect(original.blocks.items[0].instructions.items[2].kind.load.ty == .double);
        try std.testing.expect(original.blocks.items[0].instructions.items[3].kind.load.ty == .double);
        try std.testing.expect((try forms.legalizeScalarPointers(arena.allocator(), expanded, &context)) == null);
    }
}

test "scalar pointer fallback preserves widths metadata boundaries and source" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\@table = external global [8 x i8]
        \\define double @f(i64 %index) {
        \\entry:
        \\ %p = getelementptr [8 x i8], ptr @table, i64 %index
        \\ %v = load double, ptr %p, align 1
        \\ ret double %v
        \\}
    );
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const original = module.functions.items[0];
    try std.testing.expect((try forms.legalize(arena.allocator(), original, null)) == null);
    const expanded = (try forms.legalizeScalarPointers(arena.allocator(), original, null)).?;
    try std.testing.expectEqual(ir.Type.double, original.blocks.items[0].instructions.items[1].kind.load.ty);
    const load = expanded.blocks.items[0].instructions.items[1].kind.load;
    try std.testing.expectEqual(ir.Type{ .int = 64 }, load.ty);
    try std.testing.expectEqual(@as(u64, 1), load.attrs.@"align".?);
    try std.testing.expect((try forms.legalizeScalarPointers(arena.allocator(), expanded, null)) == null);
    for ([_][]const u8{
        "load volatile double, ptr %p, align 8",
        "load atomic double, ptr %p seq_cst, align 8",
        "load double, ptr addrspace(1) %p, align 8",
    }) |access| {
        const source = try std.fmt.allocPrint(std.testing.allocator, "define double @closed(ptr %p) {{\nentry:\n %v = {s}\n ret double %v\n}}\n", .{access});
        defer std.testing.allocator.free(source);
        var closed = try ir.Module.parse(std.testing.allocator, source);
        defer closed.deinit();
        try std.testing.expect((try forms.legalizeScalarPointers(arena.allocator(), closed.functions.items[0], null)) == null);
    }
}

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
        "load volatile float, ptr %p, align 4",
        "load atomic double, ptr %p seq_cst, align 8",
        "load float, ptr addrspace(1) %p, align 4",
        "load half, ptr %p, align 2",
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

test "scalar FP memory expansion preserves typed stack owners including padded half slots" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\define double @f(ptr %ordinary) {
        \\entry:
        \\ %half_slot = alloca half, align 8
        \\ %float_slot = alloca float, align 4
        \\ store float 1.0, ptr %float_slot, align 4
        \\ %padded = load double, ptr %half_slot, align 8
        \\ %value = load double, ptr %ordinary, align 1
        \\ ret double %value
        \\}
    );
    defer module.deinit();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const original = module.functions.items[0];
    const expanded = (try forms.legalize(arena.allocator(), original, null)).?;
    try std.testing.expectEqual(ir.Type.float, expanded.blocks.items[0].instructions.items[2].kind.store.ty);
    try std.testing.expectEqual(ir.Type.double, expanded.blocks.items[0].instructions.items[3].kind.load.ty);
    try std.testing.expect(original.blocks.items[0].instructions.items[4].kind.load.ty == .double);
    try std.testing.expect((try forms.legalize(arena.allocator(), expanded, null)) == null);
}

test "scalar FP memory preserves symbolic table and stack addresses through unordered PHIs" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\@table = external global double
        \\define double @f(ptr %ordinary, i1 %choice) {
        \\entry:
        \\ %slot = alloca double
        \\ br i1 %choice, label %left, label %right
        \\join:
        \\ %p = phi ptr [ %global, %left ], [ %stack, %right ]
        \\ %v = load double, ptr %p, align 1
        \\ %r = load double, ptr %ordinary, align 1
        \\ %sum = fadd double %v, %r
        \\ ret double %sum
        \\left:
        \\ %global = getelementptr double, ptr @table, i64 0
        \\ br label %join
        \\right:
        \\ %stack = getelementptr i8, ptr %slot, i64 0
        \\ br label %join
        \\}
    );
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const expanded = (try forms.legalize(arena.allocator(), module.functions.items[0], null)).?;
    try std.testing.expectEqual(ir.Type.double, expanded.blocks.items[1].instructions.items[1].kind.load.ty);
    try std.testing.expectEqual(ir.Type{ .int = 64 }, expanded.blocks.items[1].instructions.items[2].kind.load.ty);
    var functions = [_]ir.Function{expanded};
    var view = module;
    view.functions.items = &functions;
    view.functions.capacity = functions.len;
    try view.verify();
    try std.testing.expect((try forms.legalize(arena.allocator(), expanded, null)) == null);
}
