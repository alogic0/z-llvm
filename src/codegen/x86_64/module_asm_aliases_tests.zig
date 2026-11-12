const std = @import("std");
const ir = @import("../../ir.zig");
const aliases = @import("module_asm_aliases.zig");

test "module assembly function alias chains retain exact binding and type" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\module asm ".globl first; .type first, @function; .set first, second;"
        \\module asm ".set second, original; .type second, @function; .globl second;"
        \\@original = alias i64 (i64), ptr @body
        \\define internal i64 @body(i64 %x) {
        \\entry:
        \\ %y = add i64 %x, 99
        \\ ret i64 %y
        \\}
    );
    defer module.deinit();
    try module.verify();
    var result = (try aliases.parse(std.testing.allocator, module)).?;
    defer result.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 3), result.aliases.items.len);
    try std.testing.expectEqualStrings("first", result.aliases.items[1].name);
    try std.testing.expectEqualStrings("second", result.aliases.items[1].target);
    try std.testing.expectEqualStrings("i64 (i64)", result.aliases.items[1].aliased_ty);
    try std.testing.expectEqual(ir.FunctionLinkage.default, result.aliases.items[1].linkage);
    try std.testing.expectEqual(@as(usize, 1), module.aliases.items.len);
    try module.verify();
}

test "module assembly alias directives reject opaque instructions missing targets cycles and data" {
    const suffix =
        \\@data = global i64 0
        \\define i64 @body(i64 %x) {
        \\entry:
        \\ ret i64 %x
        \\}
    ;
    for ([_][]const u8{
        "module asm \"nop\"\n",
        "module asm \".globl alias; .type alias, @function; .set alias, missing;\"\n",
        "module asm \".globl alias; .type alias, @function; .set alias, alias;\"\n",
        "module asm \".globl alias; .type alias, @object; .set alias, data;\"\n",
        "module asm \".globl alias; .type alias, @function; .set alias, data;\"\n",
        "module asm \".globl alias; .set alias, body;\"\n",
        "module asm \".globl alias; .type alias, @function; .set alias, body + 1;\"\n",
    }) |prefix| {
        const text = try std.mem.concat(std.testing.allocator, u8, &.{ prefix, suffix });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        try std.testing.expectError(error.UnsupportedModuleAssembly, aliases.parse(std.testing.allocator, module));
    }
}
