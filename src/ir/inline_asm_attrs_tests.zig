const std = @import("std");
const ir = @import("../ir.zig");
test "inline assembly element types combine with checked ordinary pointer facts" {
    for ([_][]const u8{ "nonnull elementtype(i32)", "elementtype(i32) noundef nonnull align 4 dereferenceable(4)", "noundef elementtype(i32) dereferenceable_or_null(4)" }) |attrs| {
        const element = (try ir.verifyInlineAsmParameterAttrs(.ptr, attrs)).?;
        try std.testing.expect(element.eql(.{ .int = 32 }));
    }
    for ([_][]const u8{ "nonnull nonnull elementtype(i32)", "elementtype(i32) elementtype(i32)", "align 3 elementtype(i32)", "elementtype(void)", "elementtype(metadata)", "elementtype(i32) byval(i32)", "returned elementtype(i32)", "nonnull elementtype(i32) unknown" }) |attrs| {
        if (std.mem.eql(u8, attrs, "align 3 elementtype(i32)")) try std.testing.expectError(error.InvalidAlignment, ir.verifyInlineAsmParameterAttrs(.ptr, attrs)) else try std.testing.expectError(error.UnsupportedCallAttribute, ir.verifyInlineAsmParameterAttrs(.ptr, attrs));
    }
    try std.testing.expectError(error.UnsupportedCallAttribute, ir.verifyParameterAttrs(.ptr, "nonnull elementtype(i32)"));
    try std.testing.expectError(error.UnsupportedCallAttribute, ir.verifyInlineAsmParameterAttrs(.{ .int = 32 }, "elementtype(i32)"));
}
test "annotated empty assembly remains a memory barrier through private lowering" {
    const a = std.testing.allocator;
    var module = try ir.Module.parse(a, "define i32 @barrier(ptr %p,i32 %v) {\nentry:\n store i32 %v,ptr %p,align 4\n call void asm sideeffect \"\", \"=*r|m,r|m,~{dirflag},~{fpsr},~{flags}\"(ptr nonnull noundef align 4 elementtype(i32) %p,i32 %v) #7\n %r = load i32,ptr %p,align 4\n ret i32 %r\n}\nattributes #7 = { nounwind }\n");
    defer module.deinit();
    try module.verify();
    var selected = try @import("../compilation.zig").select(a, "x86_64-unknown-linux-gnu", module.functions.items[0], .{ .generic_cfg_selector = true });
    defer selected.deinit(a);
    const code = try @import("../mc/encoding.zig").encodeFunction(a, selected);
    defer a.free(code);
    const memory = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(memory);
    @memcpy(memory[0..code.len], code);
    const run: *const fn (*u32, u32) callconv(.c) u32 = @ptrCast(memory.ptr);
    for (0..64) |seed| {
        var words = [_]u32{ 0xa5a5a5a5, 0, 0xa5a5a5a5 };
        const expected = @as(u32, @intCast(seed)) *% 0x9e3779b1;
        try std.testing.expectEqual(expected, run(&words[1], expected));
        try std.testing.expectEqual(expected, words[1]);
        try std.testing.expectEqual(@as(u32, 0xa5a5a5a5), words[0]);
        try std.testing.expectEqual(words[0], words[2]);
    }
    try module.verify();
    try std.testing.expect(module.functions.items[0].blocks.items[0].instructions.items[1].kind.call.args.items[0].attrs != null);
}
