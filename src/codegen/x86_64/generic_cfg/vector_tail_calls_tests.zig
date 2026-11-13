const std = @import("std");
const ir = @import("../../../ir.zig");
const vectors = @import("integer_vectors.zig");
const machine = @import("../machine.zig");
test "vector ABI views accept optional tail hints and keep mandatory calls closed" {
    const a = std.testing.allocator;
    for ([_][]const u8{ "tail", "notail", "musttail" }) |tail| {
        const source = try std.fmt.allocPrint(a, "declare i64 @take(<32 x i8>)\n" ++
            "define i64 @probe(ptr %source,i64 %salt) {{\nentry:\n" ++
            " %v = load <32 x i8>,ptr %source,align 1\n" ++
            " %r = {s} call i64 @take(<32 x i8> %v)\n" ++
            " %answer = xor i64 %r,%salt\n ret i64 %answer\n}}\n", .{tail});
        defer a.free(source);
        var module = try ir.Module.parse(a, source);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(a);
        defer arena.deinit();
        const context: machine.ReadOnlyModuleContext = .{ .globals = &.{}, .named_types = &.{}, .target_datalayout = null, .declarations = module.declarations.items };
        const original = module.functions.items[0];
        const revised = try vectors.legalize(arena.allocator(), original, &context);
        try std.testing.expectEqualStrings(tail, original.blocks.items[0].instructions.items[1].kind.call.tail_kind.?);
        if (std.mem.eql(u8, tail, "musttail")) {
            try std.testing.expect(revised == null);
            continue;
        }
        var calls: usize = 0;
        for (revised.?.blocks.items) |block| for (block.instructions.items) |inst| {
            if (inst.kind != .call) continue;
            calls += 1;
            try std.testing.expect(inst.kind.call.tail_kind == null);
            try std.testing.expectEqual(@as(usize, 2), inst.kind.call.args.items.len);
        };
        try std.testing.expectEqual(@as(usize, 1), calls);
        var selected = try @import("../../../compilation.zig").select(a, "x86_64-unknown-linux-gnu", original, .{ .generic_cfg_selector = true, .module_context = &context });
        defer selected.deinit(a);
        try @import("../verify.zig").verifyFunction(selected);
        try module.verify();
    }
}

test "closed wide vector snapshots admit optional tail hints without changing the source" {
    const a = std.testing.allocator;
    for ([_][]const u8{ "tail", "notail", "musttail" }) |tail| {
        const text = try std.fmt.allocPrint(a, "define internal fastcc void @take(ptr %out,<16 x i128> %v) {{\nentry:\n store <16 x i128> %v,ptr %out,align 1\n ret void\n}}\n" ++
            "define void @probe(ptr %out,ptr %source) {{\nentry:\n %v = load <16 x i128>,ptr %source,align 1\n" ++
            " {s} call fastcc void @take(ptr %out,<16 x i128> %v)\n ret void\n}}\n", .{tail});
        defer a.free(text);
        var module = try ir.Module.parse(a, text);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(a);
        defer arena.deinit();
        const view = try @import("../closed_vector_calls.zig").prepare(arena.allocator(), module);
        try std.testing.expect(module.functions.items[0].params.items[1].ty == .vector);
        try std.testing.expectEqualStrings(tail, module.functions.items[1].blocks.items[0].instructions.items[1].kind.call.tail_kind.?);
        if (std.mem.eql(u8, tail, "musttail")) {
            try std.testing.expect(view == null);
            continue;
        }
        try std.testing.expectEqual(@as(usize, 1), view.?.changed_callees);
        try std.testing.expect(view.?.functions[0].params.items[1].ty == .ptr);
        var calls: usize = 0;
        for (view.?.functions[1].blocks.items) |block| for (block.instructions.items) |inst| {
            if (inst.kind != .call) continue;
            calls += 1;
            try std.testing.expect(inst.kind.call.tail_kind == null);
            try std.testing.expect(inst.kind.call.args.items[1].ty == .ptr);
        };
        try std.testing.expectEqual(@as(usize, 1), calls);
        try module.verify();
    }
}
