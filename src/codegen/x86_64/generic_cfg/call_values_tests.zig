const std = @import("std");
const ir = @import("../../../ir.zig");
const values = @import("call_values.zig");
const normalization = @import("semantic_normalization.zig");

test "undefined call values refine privately without changing defined operands or call facts" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\declare fastcc i64 @callee(i32, i64, ptr, i128, i64)
        \\define i64 @caller(i64 %input) {
        \\entry:
        \\  %a = call fastcc i64 @callee(i32 noundef undef, i64 poison, ptr nonnull align 8 poison, i128 undef, i64 %input)
        \\  %b = call fastcc i64 @callee(i32 7, i64 %a, ptr null, i128 9, i64 %input)
        \\  ret i64 %b
        \\}
    );
    defer module.deinit();
    try module.verify();
    const source = module.functions.items[0];
    const original = source.blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expect(values.requiresNormalization(source));
    try std.testing.expectError(error.UnsupportedSemanticNormalization, normalization.check(source));
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const converted = try values.normalize(arena.allocator(), source);
    const call = converted.blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expect(source.blocks.items.ptr != converted.blocks.items.ptr);
    try std.testing.expectEqual(source.params.items.ptr, converted.params.items.ptr);
    try std.testing.expect(source.ret_ty.eql(converted.ret_ty));
    try std.testing.expect(original.args.items.ptr != call.args.items.ptr);
    for (call.args.items[0..4], original.args.items[0..4]) |arg, before| {
        try std.testing.expect(arg.ty.eql(before.ty));
        try std.testing.expectEqual(before.attrs, arg.attrs);
        try std.testing.expect(arg.value.eql(if (arg.ty == .ptr) .null_value else .{ .int = 0 }));
    }
    try std.testing.expectEqualDeep(original.args.items[4], call.args.items[4]);
    var facts = original;
    facts.args = call.args;
    try std.testing.expectEqualDeep(facts, call);
    try std.testing.expectEqual(source.blocks.items[0].instructions.items[1].kind.call.args.items.ptr, converted.blocks.items[0].instructions.items[1].kind.call.args.items.ptr);
    try std.testing.expect(original.args.items[0].value == .undef);
    try std.testing.expect(original.args.items[1].value == .poison);
    try std.testing.expect(original.args.items[2].value == .poison);
    try std.testing.expect(original.args.items[3].value == .undef);
    try std.testing.expect(!values.requiresNormalization(converted));
    const repeated = try values.normalize(arena.allocator(), converted);
    try std.testing.expectEqual(converted.blocks.items.ptr, repeated.blocks.items.ptr);
    try normalization.check(converted);
    module.functions.items[0] = converted;
    const verified = module.verify();
    module.functions.items[0] = source;
    try verified;
    try module.verify();
}

test "undefined call values retain unsupported types and removed instructions" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\declare void @wide(i129, double, <2 x i64>)
        \\declare void @scalar(i32)
        \\define void @caller() {
        \\entry:
        \\  call void @wide(i129 undef, double poison, <2 x i64> undef)
        \\  call void @scalar(i32 undef)
        \\  ret void
        \\}
    );
    defer module.deinit();
    try module.verify();
    module.functions.items[0].blocks.items[0].instructions.items[1].removed = true;
    const source = module.functions.items[0];
    try std.testing.expect(!values.requiresNormalization(source));
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const converted = try values.normalize(arena.allocator(), source);
    try std.testing.expectEqual(source.blocks.items.ptr, converted.blocks.items.ptr);
}

test "undefined call values discharge before legacy recognition in every scalar width" {
    for ([_]u16{ 1, 7, 8, 16, 21, 32, 37, 64, 65, 128 }) |bits| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "declare void @sink(i{d})\ndefine void @caller() {{\nentry:\n call void @sink(i{d} poison)\n ret void\n}}\n", .{ bits, bits });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const converted = try normalization.normalize(arena.allocator(), module.functions.items[0], null);
        try std.testing.expect(!values.requiresNormalization(converted.ir_function));
        try normalization.check(converted.ir_function);
        try std.testing.expect(module.functions.items[0].blocks.items[0].instructions.items[0].kind.call.args.items[0].value == .poison);
    }
}
