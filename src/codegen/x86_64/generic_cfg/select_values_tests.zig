const std = @import("std");
const ir = @import("../../../ir.zig");
const values = @import("select_values.zig");
const normalization = @import("semantic_normalization.zig");

test "undefined select arms refine privately and retain conditions defined arms and signatures" {
    for ([_][]const u8{ "i1", "i8", "i24", "i64", "i80", "i128", "ptr" }) |ty| {
        const source = try std.fmt.allocPrint(
            std.testing.allocator,
            "define {s} @choose(i1 %condition, {s} %value) {{\nentry:\n %left = select i1 %condition, {s} undef, {s} %value\n %right = select i1 %condition, {s} %value, {s} poison\n %result = select i1 %condition, {s} %right, {s} %left\n ret {s} %result\n}}\n",
            .{ ty, ty, ty, ty, ty, ty, ty, ty, ty },
        );
        defer std.testing.allocator.free(source);
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        try module.verify();
        const original = module.functions.items[0];
        try std.testing.expect(values.requiresNormalization(original));
        try std.testing.expectError(error.UnsupportedSemanticNormalization, normalization.check(original));
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const normalized = (try normalization.normalize(arena.allocator(), original, null)).ir_function;
        try normalization.check(normalized);
        try std.testing.expectEqual(original.params.items.ptr, normalized.params.items.ptr);
        try std.testing.expect(original.ret_ty.eql(normalized.ret_ty));
        try std.testing.expect(original.blocks.items.ptr != normalized.blocks.items.ptr);
        const concrete: ir.Value = if (std.mem.eql(u8, ty, "ptr")) .null_value else .{ .int = 0 };
        const left = normalized.blocks.items[0].instructions.items[0].kind.select;
        const right = normalized.blocks.items[0].instructions.items[1].kind.select;
        try std.testing.expect(left.true_value.eql(concrete));
        try std.testing.expect(right.false_value.eql(concrete));
        try std.testing.expect(left.false_value.eql(.{ .named = "value" }));
        try std.testing.expect(right.true_value.eql(.{ .named = "value" }));
        try std.testing.expect(left.cond.eql(.{ .named = "condition" }));
        try std.testing.expect(right.cond.eql(.{ .named = "condition" }));
        try std.testing.expect(original.blocks.items[0].instructions.items[0].kind.select.true_value == .undef);
        try std.testing.expect(original.blocks.items[0].instructions.items[1].kind.select.false_value == .poison);
        try std.testing.expectEqual(normalized.blocks.items.ptr, (try values.normalize(arena.allocator(), normalized)).blocks.items.ptr);
        var private = module;
        private.functions = try module.functions.clone(arena.allocator());
        private.functions.items[0] = normalized;
        try private.verify();
        try module.verify();
    }
}

test "undefined select arms retain unsupported types and removed instructions" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\define void @keep(i1 %flag) {
        \\entry:
        \\ %a = select i1 %flag, i129 undef, i129 1
        \\ %b = select i1 %flag, double poison, double 0.000000e+00
        \\ %c = select i1 %flag, <2 x i64> undef, <2 x i64> zeroinitializer
        \\ %d = select i1 %flag, i32 undef, i32 7
        \\ ret void
        \\}
    );
    defer module.deinit();
    try module.verify();
    module.functions.items[0].blocks.items[0].instructions.items[3].removed = true;
    const source = module.functions.items[0];
    try std.testing.expect(!values.requiresNormalization(source));
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    try std.testing.expectEqual(source.blocks.items.ptr, (try values.normalize(arena.allocator(), source)).blocks.items.ptr);
}
