const std = @import("std");
const ir = @import("../ir.zig");
const dependencies = @import("../analysis/global_dependencies.zig");

const closure_source =
    \\@export = alias i32 (), ptr @middle
    \\@middle = internal alias i32 (), ptr @root
    \\@callback = global ptr @"debug.callback"
    \\@private_slot = internal global ptr @indirect_target
    \\@dead_alias = internal alias i32 (), ptr @dead
    \\declare i32 @external()
    \\define internal i32 @root() {
    \\entry:
    \\  %v = call i32 @recursive()
    \\  ret i32 %v
    \\}
    \\define internal i32 @recursive() {
    \\entry:
    \\  %v = call i32 @root()
    \\  ret i32 %v
    \\}
    \\define internal i32 @"debug.callback"() {
    \\entry:
    \\  %v = call i32 @external()
    \\  ret i32 %v
    \\}
    \\define ptr @get_slot() {
    \\entry:
    \\  ret ptr @private_slot
    \\}
    \\define internal i32 @indirect_target() {
    \\entry:
    \\  ret i32 7
    \\}
    \\define internal i32 @dead() {
    \\entry:
    \\  call void asm sideeffect "", "~{memory}"()
    \\  ret i32 0
    \\}
;

fn checkClosure(allocator: std.mem.Allocator) !void {
    var module = try ir.Module.parse(allocator, closure_source);
    defer module.deinit();
    var graph = try dependencies.Graph.build(allocator, module);
    defer graph.deinit();
    var selection = try graph.reachable();
    defer selection.deinit();
    try std.testing.expect(!selection.has_unknown);
    for ([_][]const u8{ "root", "recursive", "\"debug.callback\"", "get_slot", "indirect_target" }) |name| {
        try std.testing.expect(selection.contains(.function, name));
    }
    try std.testing.expect(selection.contains(.global, "callback"));
    try std.testing.expect(selection.contains(.global, "private_slot"));
    try std.testing.expect(selection.contains(.alias, "export"));
    try std.testing.expect(selection.contains(.alias, "middle"));
    try std.testing.expect(!selection.contains(.function, "external"));
    try std.testing.expect(!selection.contains(.function, "dead"));
    try std.testing.expect(!selection.contains(.alias, "dead_alias"));
    try std.testing.expectEqual(@as(usize, 6), module.functions.items.len);
}

test "module dependencies: transitive aliases recursion global callbacks and imports" {
    try checkClosure(std.testing.allocator);
}

test "module dependencies: allocation failures leave borrowed definitions intact" {
    try std.testing.checkAllAllocationFailures(std.testing.allocator, checkClosure, .{});
}

test "module dependencies: live opaque references conservatively retain all definitions" {
    for ([_][]const u8{
        "@callback = global [1 x ptr] [ptr @hidden]",
        "module asm \".quad hidden\"",
        "!0 = !{ptr @hidden}",
        "define void @entry() #0 {\nentry:\n  ret void\n}\nattributes #0 = { nounwind }",
    }) |opaque_root| {
        const source = try std.fmt.allocPrint(std.testing.allocator, "{s}\ndefine internal i32 @hidden() {{\nentry:\n  ret i32 9\n}}\n", .{opaque_root});
        defer std.testing.allocator.free(source);
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        var graph = try dependencies.Graph.build(std.testing.allocator, module);
        defer graph.deinit();
        var selection = try graph.reachable();
        defer selection.deinit();
        try std.testing.expect(selection.has_unknown);
        try std.testing.expect(selection.contains(.function, "hidden"));
    }
}

test "module dependencies: alias cycles terminate without inventing a function" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\@a = alias i32 (), ptr @b
        \\@b = internal alias i32 (), ptr @a
        \\define internal i32 @dead() {
        \\entry:
        \\  ret i32 1
        \\}
    );
    defer module.deinit();
    var graph = try dependencies.Graph.build(std.testing.allocator, module);
    defer graph.deinit();
    var selection = try graph.reachable();
    defer selection.deinit();
    try std.testing.expect(!selection.has_unknown);
    try std.testing.expectEqual(@as(usize, 2), selection.live.items.len);
    try std.testing.expect(!selection.contains(.function, "dead"));
}
