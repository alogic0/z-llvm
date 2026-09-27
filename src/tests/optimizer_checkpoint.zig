const std = @import("std");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");
const pipelines = @import("../pipelines.zig");

fn optimize(source: []const u8, passes: []const u8) !ir.Module {
    var module = try ir.Module.parse(std.testing.allocator, source);
    errdefer module.deinit();
    try module.verify();
    var pm = pass_manager.ModulePassManager.init(std.testing.allocator);
    defer pm.deinit();
    try pipelines.addPasses(&pm, passes);
    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    var output = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer output.deinit();
    _ = try pm.run(&module, &context, &output.writer, false);
    try module.verify();
    return module;
}

test "correctness checkpoint: folded backedges and forward alias chains stay defined" {
    for ([_][]const u8{ "instcombine", "release-o3" }) |passes| {
        var module = try optimize(
            \\define i32 @loop(i1 %again) {
            \\entry:
            \\ br label %loop
            \\loop:
            \\ %i = phi i32 [ 0, %entry ], [ %next, %loop ]
            \\ %next = add i32 %i, 0
            \\ br i1 %again, label %loop, label %exit
            \\exit:
            \\ ret i32 %i
            \\}
            \\define i32 @forward(i32 %x) {
            \\entry:
            \\ br label %producer
            \\exit:
            \\ ret i32 %a
            \\middle:
            \\ %a = add i32 %b, 0
            \\ br label %exit
            \\producer:
            \\ %b = add i32 %x, 0
            \\ br label %middle
            \\}
        , passes);
        defer module.deinit();
    }
}

test "correctness checkpoint: constmerge retains opaque references" {
    for ([_][]const u8{
        "@p = global ptr getelementptr (i32, ptr @a, i64 0)",
        "@p = global { ptr } { ptr @a }",
        "!0 = !{ptr @a}",
    }) |opaque_source| {
        const source = try std.fmt.allocPrint(std.testing.allocator, "@a = private unnamed_addr constant i32 7\n@b = private unnamed_addr constant i32 7\n{s}\n", .{opaque_source});
        defer std.testing.allocator.free(source);
        var module = try optimize(source, "constmerge");
        defer module.deinit();
        var found = false;
        for (module.globals.items) |global| if (std.mem.eql(u8, global.name, "a")) {
            found = true;
        };
        try std.testing.expect(found);
    }
}

test "correctness checkpoint: constmerge still rewrites structured uses and aliases" {
    var module = try optimize(
        \\@a = private unnamed_addr constant i32 7
        \\@b = private unnamed_addr constant i32 7
        \\@p = global ptr @a
        \\@alias = alias i32, ptr @a
        \\define i32 @f() {
        \\entry:
        \\ %v = load i32, ptr @a
        \\ ret i32 %v
        \\}
    , "constmerge");
    defer module.deinit();
    try std.testing.expectEqual(@as(usize, 2), module.globals.items.len);
    try std.testing.expectEqualStrings("b", module.aliases.items[0].target);
    try std.testing.expectEqualStrings("@b", module.globals.items[1].initializer.scalar.named);
    try std.testing.expectEqualStrings("@b", module.functions.items[0].blocks.items[0].instructions.items[0].kind.load.ptr.named);
}

test "correctness checkpoint: vector index spellings use their own widths" {
    for ([_][]const u8{ "instcombine", "vector-combine", "release-o3" }) |passes| {
        for ([_][]const u8{ "i1 3", "i1 -1", "i8 257", "i128 1" }) |index| {
            const source = try std.fmt.allocPrint(std.testing.allocator, "define i32 @f() {{\nentry:\n %v = insertelement <4 x i32> zeroinitializer, i32 42, {s}\n %r = extractelement <4 x i32> %v, i32 1\n ret i32 %r\n}}\n", .{index});
            defer std.testing.allocator.free(source);
            var module = try optimize(source, passes);
            defer module.deinit();
            try std.testing.expect(module.functions.items[0].blocks.items[0].terminator.?.ret.value.?.eql(.{ .int = 42 }));
        }
    }
}

test "correctness checkpoint: vector bypass preserves the normalized extract index" {
    for ([_][]const u8{ "instcombine", "vector-combine" }) |passes| {
        var module = try optimize(
            \\define i32 @f(<4 x i32> %input) {
            \\entry:
            \\ %v = insertelement <4 x i32> %input, i32 42, i32 0
            \\ %r = extractelement <4 x i32> %v, i1 3
            \\ ret i32 %r
            \\}
        , passes);
        defer module.deinit();
        const extract = module.functions.items[0].blocks.items[0].instructions.items[1].kind.extractelement;
        const integer = @import("../analysis/integer_semantics.zig").Integer.init(extract.index_ty).?;
        try std.testing.expectEqual(@as(u128, 1), integer.unsigned(extract.index.int));
        try std.testing.expectEqualStrings("input", extract.vector.named);
    }
}

test "correctness checkpoint: shuffle extraction normalizes its lane" {
    var module = try optimize(
        \\define i32 @f(<4 x i32> %input) {
        \\entry:
        \\ %v = shufflevector <4 x i32> %input, <4 x i32> poison, <4 x i32> <i32 3, i32 2, i32 1, i32 0>
        \\ %r = extractelement <4 x i32> %v, i1 3
        \\ ret i32 %r
        \\}
    , "instcombine");
    defer module.deinit();
    const extract = module.functions.items[0].blocks.items[0].instructions.items[1].kind.extractelement;
    try std.testing.expectEqual(@as(i128, 2), extract.index.int);
}

test "correctness checkpoint: shifts normalize counts before poison checks" {
    const simplify = @import("../passes/inst_simplify.zig").simplify;
    for ([_]ir.BinaryOp{ .shl, .lshr, .ashr }) |op| {
        for ([_]i128{ 256, -256 }) |count| {
            const result = simplify(.{ .result = "v", .kind = .{ .binary = .{
                .op = op,
                .ty = .{ .int = 8 },
                .lhs = .{ .int = 4 },
                .rhs = .{ .int = count },
            } } }).?;
            try std.testing.expect(result.eql(.{ .int = 4 }));
        }
        for ([_]i128{ 8, 264, -1 }) |count| {
            const result = simplify(.{ .result = "v", .kind = .{ .binary = .{
                .op = op,
                .ty = .{ .int = 8 },
                .lhs = .{ .int = 4 },
                .rhs = .{ .int = count },
            } } }).?;
            try std.testing.expect(result == .poison);
        }
    }
}
