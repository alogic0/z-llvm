//! Defined-value vector facts do not change physical argument representation.
const std = @import("std");
const ir = @import("../../ir.zig");
const syntax = @import("../../ir/parser_syntax.zig");
pub fn advisory(ty: ir.Type, attrs: ?[]const u8) bool {
    const text = attrs orelse return true;
    if (ty != .vector) return false;
    ir.verifyParameterAttrs(ty, text) catch return false;
    var rest = std.mem.trim(u8, text, " \t\r\n");
    while (rest.len != 0) {
        const end = syntax.findTopLevelTokenEnd(rest) orelse return false;
        if (end == 0) return false;
        const token = rest[0..end];
        rest = std.mem.trim(u8, rest[end..], " \t\r\n");
        if (std.mem.eql(u8, token, "noundef") or std.mem.startsWith(u8, token, "range(")) continue;
        return false;
    }
    return true;
}

test "vector range facts use checked scalar lane bounds without granting ABI facts" {
    const vector: ir.Type = .{ .vector = .{ .len = 32, .elem_ty = .{ .int = 8 } } };
    for ([_][]const u8{ "range(i8 1, 3)", "noundef range(i8 4, 21)", "range(i8 -7, 3)", "range(i8 250, 5)", "range(i8 0, 0)" }) |attrs| {
        try ir.verifyParameterAttrs(vector, attrs);
        try std.testing.expect(advisory(vector, attrs));
    }
    for ([_][]const u8{ "range(i16 1, 3)", "range(i8 0, 256)", "range(i8 -129, 3)", "range(i8 4, 4)", "range(i8 255, -1)", "range(i8 0, 4) range(i8 0, 4)", "noundef noundef", "zeroext", "nonnull", "range(i8 1, 3) returned" }) |attrs| try std.testing.expect(!advisory(vector, attrs));
    try std.testing.expectError(error.UnsupportedCallAttribute, ir.verifyParameterAttrs(.{ .vector = .{ .len = 2, .elem_ty = .float } }, "range(i8 1, 3)"));
    try std.testing.expectError(error.UnsupportedCallAttribute, ir.verifyParameterAttrs(.{ .vector = .{ .len = 2, .elem_ty = .ptr } }, "range(i8 1, 3)"));
}

test "vector range facts stay on the source type and leave physical carriers unconstrained" {
    const a = std.testing.allocator;
    var module = try ir.Module.parse(a, "define internal fastcc i64 @take(<2 x i8> noundef range(i8 4, 21) %value) {\nentry:\n %first = extractelement <2 x i8> %value,i32 0\n %r = zext i8 %first to i64\n ret i64 %r\n}\n");
    defer module.deinit();
    try module.verify();
    const machine = @import("machine.zig");
    const context: machine.ReadOnlyModuleContext = .{ .globals = &.{}, .named_types = &.{}, .target_datalayout = null, .functions = module.functions.items };
    var arena = std.heap.ArenaAllocator.init(a);
    defer arena.deinit();
    const view = (try @import("generic_cfg/integer_vectors.zig").legalize(arena.allocator(), module.functions.items[0], &context)).?;
    try std.testing.expect(view.params.items[0].ty == .double);
    try std.testing.expect(view.params.items[0].attrs == null);
    try std.testing.expect(module.functions.items[0].params.items[0].ty == .vector);
    try std.testing.expectEqualStrings("noundef range(i8 4, 21)", module.functions.items[0].params.items[0].attrs.?);
    var selected = try @import("../../compilation.zig").select(a, "x86_64-unknown-linux-gnu", module.functions.items[0], .{ .generic_cfg_selector = true, .module_context = &context });
    defer selected.deinit(a);
    try @import("verify.zig").verifyFunction(selected);
}
