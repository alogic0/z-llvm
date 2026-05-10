const std = @import("std");
const ir = @import("ir.zig");
const pass_manager = @import("pass_manager.zig");
const instcombine = @import("passes/instcombine.zig");
const dce = @import("passes/dce.zig");

test "instcombine and dce remove identity arithmetic" {
    const input =
        \\define i32 @add_mul(i32 %a) {
        \\entry:
        \\  %x = add i32 %a, 0
        \\  %y = mul i32 %x, 1
        \\  ret i32 %y
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(instcombine.pass);
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @add_mul(i32 %a) {
        \\entry:
        \\  ret i32 %a
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}

test "constant folding rewrites return value" {
    const input =
        \\define i32 @constant() {
        \\entry:
        \\  %x = add i32 1, 2
        \\  %y = mul i32 %x, 4
        \\  ret i32 %y
        \\}
        \\
    ;

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();

    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pm.add(instcombine.pass);
    try pm.add(dce.pass);

    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();

    _ = try pm.run(&module, &context, &output.writer, false);
    try module.print(&output.writer);

    const expected =
        \\define i32 @constant() {
        \\entry:
        \\  ret i32 12
        \\}
        \\
    ;
    try std.testing.expectEqualStrings(expected, output.writer.buffered());
}
