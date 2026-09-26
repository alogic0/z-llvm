const std = @import("std");
const ir = @import("../ir.zig");
const globaldce = @import("../passes/globaldce.zig");
const pass_manager = @import("../pass_manager.zig");

fn optimize(module: *ir.Module, allocator: std.mem.Allocator) !void {
    try module.verify();
    var context: pass_manager.Context = .{ .allocator = allocator };
    _ = try globaldce.pass.run(module, &context);
    try module.verify();
}

const alias_chain =
    \\@value = internal global i32 7
    \\@middle = internal alias i32, ptr @value
    \\@export = alias i32, ptr @middle
    \\@callback = global ptr @fn_alias
    \\@fn_alias = internal alias i32 (), ptr @leaf
    \\define internal i32 @leaf() {
    \\entry:
    \\  ret i32 19
    \\}
;

test "globaldce references: exported alias chains and initializer alias edges survive" {
    var module = try ir.Module.parse(std.testing.allocator, alias_chain);
    defer module.deinit();
    try optimize(&module, std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 2), module.globals.items.len);
    try std.testing.expectEqual(@as(usize, 3), module.aliases.items.len);
    try std.testing.expectEqual(@as(usize, 1), module.functions.items.len);
}

test "globaldce references: function operands and terminators keep aliases live" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\@value = internal global i32 7
        \\@a = internal alias i32, ptr @value
        \\@b = internal alias i32, ptr @a
        \\define ptr @get() {
        \\entry:
        \\  ret ptr @b
        \\}
        \\define ptr @vector_element() {
        \\entry:
        \\  %v = insertelement <2 x ptr> poison, ptr @a, i32 0
        \\  %p = extractelement <2 x ptr> %v, i32 0
        \\  ret ptr %p
        \\}
    );
    defer module.deinit();
    try optimize(&module, std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 2), module.aliases.items.len);
    try std.testing.expectEqual(@as(usize, 1), module.globals.items.len);
}

test "globaldce references: local names and dead cycles do not root definitions" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\@g = internal global i32 1
        \\@a = internal global ptr @b
        \\@b = internal global ptr @a
        \\@unused = internal alias i32, ptr @g
        \\@bytes = constant [2 x i8] c"@g"
        \\define internal void @first() {
        \\entry:
        \\  call void @second()
        \\  ret void
        \\}
        \\define internal void @second() {
        \\entry:
        \\  call void @first()
        \\  ret void
        \\}
        \\define i32 @entry(ptr %g) {
        \\entry:
        \\  %v = load i32, ptr %g
        \\  ret i32 %v
        \\}
    );
    defer module.deinit();
    try optimize(&module, std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 1), module.functions.items.len);
    try std.testing.expectEqual(@as(usize, 1), module.globals.items.len);
    try std.testing.expectEqualStrings("bytes", module.globals.items[0].name);
    try std.testing.expectEqual(@as(usize, 0), module.aliases.items.len);
}

test "globaldce references: opaque initializers block deletion only when live" {
    for ([_][]const u8{ "[1 x ptr] [ptr @g]", "{ ptr } { ptr @g }", "ptr getelementptr (i32, ptr @g, i64 0)", "{ i32 } { i32 0 }" }) |initializer| {
        for ([_]bool{ false, true }) |live| {
            const input = try std.fmt.allocPrint(std.testing.allocator, "@g = internal global i32 1\n@p = {s}global {s}\n", .{ if (live) "" else "internal ", initializer });
            defer std.testing.allocator.free(input);
            var module = try ir.Module.parse(std.testing.allocator, input);
            defer module.deinit();
            try optimize(&module, std.testing.allocator);
            try std.testing.expectEqual(@as(usize, if (live) 2 else 0), module.globals.items.len);
        }
    }
}

test "globaldce references: live function unknowns retain definitions but dead functions vanish" {
    for ([_][]const u8{
        "call void asm sideeffect \"\", \"~{memory}\"()",
        "call void @sink() [ \"deopt\"() ]",
        "%p = freeze ptr getelementptr (i32, ptr @g, i64 0)",
    }) |body| {
        for ([_]bool{ false, true }) |live| {
            const input = try std.fmt.allocPrint(
                std.testing.allocator,
                "@g = internal global i32 1\ndeclare void @sink()\ndefine {s}void @f() {{\nentry:\n  {s}\n  ret void\n}}\n",
                .{ if (live) "" else "internal ", body },
            );
            defer std.testing.allocator.free(input);
            var module = try ir.Module.parse(std.testing.allocator, input);
            defer module.deinit();
            try optimize(&module, std.testing.allocator);
            try std.testing.expectEqual(@as(usize, if (live) 1 else 0), module.globals.items.len);
            try std.testing.expectEqual(@as(usize, if (live) 1 else 0), module.functions.items.len);
        }
    }
}

test "globaldce references: module scope unknowns retain globals functions aliases and comdats" {
    for ([_][]const u8{ "module asm \".quad g\"", "attributes #0 = { nounwind }", "!0 = !{ptr @g}", "declare void @sink() #0\nattributes #0 = { nounwind }" }) |text| {
        const input = try std.fmt.allocPrint(
            std.testing.allocator,
            "{s}\n$grp = comdat any\n@g = internal global i32 1, comdat($grp)\n@a = internal alias i32, ptr @g\ndefine internal void @f() {{\nentry:\n  ret void\n}}\n",
            .{text},
        );
        defer std.testing.allocator.free(input);
        var module = try ir.Module.parse(std.testing.allocator, input);
        defer module.deinit();
        try optimize(&module, std.testing.allocator);
        try std.testing.expectEqual(@as(usize, 1), module.globals.items.len);
        try std.testing.expectEqual(@as(usize, 1), module.functions.items.len);
        try std.testing.expectEqual(@as(usize, 1), module.aliases.items.len);
        try std.testing.expectEqual(@as(usize, 1), module.comdats.items.len);
    }
}

test "globaldce references: removed instructions and replacement bookkeeping are not roots" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\@g = internal global i32 1
        \\define void @f() {
        \\entry:
        \\  %p = freeze ptr @g
        \\  ret void
        \\}
    );
    defer module.deinit();
    const inst = &module.functions.items[0].blocks.items[0].instructions.items[0];
    inst.removed = true;
    inst.replacement = .{ .named = "@g" };
    try optimize(&module, std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 0), module.globals.items.len);
}

fn allocationFailure(allocator: std.mem.Allocator) !void {
    var module = try ir.Module.parse(std.testing.allocator, alias_chain ++ "\n" ++
        \\define internal void @dead() {
        \\entry:
        \\  ret void
        \\}
    );
    defer module.deinit();
    try module.verify();
    var context: pass_manager.Context = .{ .allocator = allocator };
    _ = globaldce.pass.run(&module, &context) catch |err| {
        // Allocation failures must precede destructive edits.
        try module.verify();
        try std.testing.expectEqual(@as(usize, 2), module.functions.items.len);
        return err;
    };
    try module.verify();
    try std.testing.expectEqual(@as(usize, 1), module.functions.items.len);
}

test "globaldce references: allocation failures clean up graph edges and worklists" {
    try std.testing.checkAllAllocationFailures(std.testing.allocator, allocationFailure, .{});
}
