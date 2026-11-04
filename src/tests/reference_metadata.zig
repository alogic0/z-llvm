const std = @import("std");
const ir = @import("../ir.zig");
const metadata = @import("../analysis/reference_metadata.zig");
const references = @import("../analysis/module_references.zig");
const dependencies = @import("../analysis/global_dependencies.zig");
const globalopt = @import("../passes/globalopt.zig");
const globaldce = @import("../passes/globaldce.zig");
const constmerge = @import("../passes/constmerge.zig");
const pass_manager = @import("../pass_manager.zig");

const records: []const []const u8 = &.{
    "!llvm.dbg.cu = !{!6}",
    "!0 = !DICompositeType(tag: DW_TAG_structure_type, name: \"@fake blockaddress(@fake, %b)\", elements: !1)",
    "!1 = !{!2}",
    "!2 = !DIDerivedType(tag: DW_TAG_member, name: \"next\", scope: !0, baseType: !0, size: 64, align: 64)",
    "!3 = !DIFile(filename: \"test\\00.zig\", directory: \".\")",
    "!4 = distinct !DISubprogram(name: \"entry\", file: !3, type: !5, unit: !6, spFlags: DISPFlagDefinition | DISPFlagOptimized)",
    "!5 = !DISubroutineType(types: !1)",
    "!6 = distinct !DICompileUnit(language: DW_LANG_C99, file: !3, emissionKind: FullDebug)",
    "!7 = !{ptr @\"g\\6cobal\", i32 7, !\"@not_a_reference\", null, !0, !7}",
    "!8 = !DILocation(line: 1, column: 2, scope: !4, inlinedAt: !8)",
    "!9 = !DILocalVariable(name: \"x\", scope: !4, type: !0, arg: 1)",
    "!10 = !DILexicalBlock(scope: !4, file: !3, line: 1, column: 0)",
    "!11 = !DIBasicType(name: \"u64\", size: 64, encoding: DW_ATE_unsigned)",
    "!12 = !DIEnumerator(name: \"max\", value: 18446744073709551615, isUnsigned: true)",
    "!13 = !DISubrange(count: 4, lowerBound: -1)",
    "!14 = distinct !DIGlobalVariable(name: \"global\", scope: !6, file: !3, type: !11, isLocal: true, isDefinition: true)",
    "!15 = !DIGlobalVariableExpression(var: !14, expr: !DIExpression())",
    "!16 = !{ptr getelementptr (i8, ptr @global, i64 0)}",
};

fn checkIndex(allocator: std.mem.Allocator) !void {
    var index = try metadata.Index.init(allocator, records);
    defer index.deinit();
    try std.testing.expect(!index.has_unknown);
    try std.testing.expectEqual(@as(usize, 17), index.ids.count());
    try std.testing.expectEqual(@as(usize, 2), index.symbols.items.len);
    for (index.symbols.items) |name| try std.testing.expect(ir.identifiers.eql("global", name));
}

test "reference metadata: complete records preserve cycles forward IDs and typed global references" {
    try checkIndex(std.testing.allocator);
}

test "reference metadata: allocation failures release indexes and collected symbols" {
    try std.testing.checkAllAllocationFailures(std.testing.allocator, checkIndex, .{});
}

test "reference metadata: unsupported malformed duplicate and missing records stay unknown" {
    for ([_][]const u8{
        "",                                            "!0 = !{!99}",                                   "!0 = !1",                         "!0 = !\"string definition\"",
        "!0 = !{ptr @}",                               "!0 = !{ptr @g,}",                               "!0 = !{ptr @g} trailing",         "!0 = !{ptr @g",
        "!4294967296 = !{}",                           "!0 = !{!4294967296}",                           "!0 = !{!+1}",                     "!0 = !DIUnknown(name: \"plain\")",
        "!0 = !DIBasicType(unknown: 1)",               "!0 = !DIBasicType(name: \"a\", name: \"b\")",   "!0 = !DIBasicType(name: \"x\",)", "!0 = !DIBasicType(name: \"bad\\+1\")",
        "!0 = !DIBasicType(encoding: DW_ATE_unknown)", "!0 = !DIFile(filename: \"file\")",              "!0 = !DILocation(scope: null)",   "!0 = !DILocation(line: -1, scope: !0)",
        "!0 = !DILocation(column: 65536, scope: !0)",  "!0 = !DIBasicType(size: 18446744073709551616)", "!0 = !DICompileUnit(file: !0)",   "!0 = !DIExpression(DW_OP_addr, 1)",
        "!vendor.helpers = !{!\"helper\"}",            "!llvm.ident = distinct !{}",
    }) |record| {
        var index = try metadata.Index.init(std.testing.allocator, &.{record});
        defer index.deinit();
        try std.testing.expect(index.has_unknown);
    }
    for ([_][]const []const u8{
        &.{ "!0 = !{}", "!0 = !{}" },
        &.{ "!llvm.ident = !{}", "!llvm.ident = !{}" },
    }) |duplicates| {
        var index = try metadata.Index.init(std.testing.allocator, duplicates);
        defer index.deinit();
        try std.testing.expect(index.has_unknown);
    }
}

const source =
    \\@value = internal global i32 7
    \\@dead = internal global i32 9
    \\define i32 @entry() #0 {
    \\entry:
    \\  %v = load i32, ptr @value, !noundef !0
    \\  ret i32 %v
    \\}
    \\define internal i32 @callback() {
    \\entry:
    \\  ret i32 3
    \\}
    \\define internal i32 @unused() {
    \\entry:
    \\  ret i32 4
    \\}
    \\attributes #0 = { nounwind }
    \\!0 = !{}
    \\!1 = !{ptr @callback}
    \\!2 = !{!"@value blockaddress(@unused, %entry)"}
;

fn checkContext(allocator: std.mem.Allocator) !void {
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    var context = try references.Context.init(allocator, &module);
    defer context.deinit();
    try std.testing.expect(references.hasUnknown(&module));
    try std.testing.expect(!context.hasUnknown());
    try std.testing.expectEqual(@as(usize, 1), context.query("value").direct_uses);
    try std.testing.expectEqual(@as(usize, 1), context.query("callback").direct_uses);
    try std.testing.expect(!context.query("unused").mayReference());
    var graph = try dependencies.Graph.build(allocator, module);
    defer graph.deinit();
    var selection = try graph.reachable();
    defer selection.deinit();
    try std.testing.expect(!selection.has_unknown);
    try std.testing.expect(selection.contains(.function, "callback"));
    try std.testing.expect(!selection.contains(.function, "unused"));
    try std.testing.expect(!selection.contains(.global, "dead"));
    try module.verify();
}

test "reference metadata: module context and graph keep genuine roots and ignore string contents" {
    try checkContext(std.testing.allocator);
    try std.testing.checkAllAllocationFailures(std.testing.allocator, checkContext, .{});
}

test "reference metadata: safe metadata allows direct-load folding and dead definition deletion" {
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    _ = try globalopt.pass.run(&module, &context);
    _ = try globaldce.pass.run(&module, &context);
    try module.verify();
    try std.testing.expectEqual(@as(usize, 0), module.globals.items.len);
    try std.testing.expectEqual(@as(usize, 2), module.functions.items.len);
    try std.testing.expectEqualStrings("callback", module.functions.items[1].name);
    try std.testing.expect(module.functions.items[0].blocks.items[0].instructions.items[0].removed);
    try std.testing.expectEqual(@as(usize, 3), module.metadata.items.len);
}

test "reference metadata: raw typed metadata uses are not direct loads even on a load instruction" {
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    // Constructed IR exercises the reference walker independently of LLVM's
    // semantic restrictions on each metadata attachment's contents.
    module.functions.items[0].blocks.items[0].instructions.items[0].metadata = "!annotation !{ptr @value}";
    var context = try references.Context.init(std.testing.allocator, &module);
    defer context.deinit();
    try std.testing.expect(!context.hasUnknown());
    try std.testing.expectEqual(@as(usize, 2), context.query("value").direct_uses);
    var pass_context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    try std.testing.expectEqual(.unchanged, try globalopt.pass.run(&module, &pass_context));
    try std.testing.expect(!module.functions.items[0].blocks.items[0].instructions.items[0].removed);
}

test "reference metadata: missing IDs unknown attachment keys and unknown named metadata block deletion" {
    for ([_][]const u8{ "!annotation !99", "!vendor.helper !{!\"callback\"}", "!annotation !0 trailing", "!annotation !0," }) |attachment| {
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        module.functions.items[0].blocks.items[0].instructions.items[0].metadata = attachment;
        var context = try references.Context.init(std.testing.allocator, &module);
        defer context.deinit();
        try std.testing.expect(context.hasUnknown());
        var pass_context: pass_manager.Context = .{ .allocator = std.testing.allocator };
        try std.testing.expectEqual(.unchanged, try globalopt.pass.run(&module, &pass_context));
        _ = try globaldce.pass.run(&module, &pass_context);
        try std.testing.expectEqual(@as(usize, 2), module.globals.items.len);
        try std.testing.expectEqual(@as(usize, 3), module.functions.items.len);
    }
    var module = try ir.Module.parse(std.testing.allocator, source ++ "\n!vendor.helpers = !{!\"unused\"}\n");
    defer module.deinit();
    var context = try references.Context.init(std.testing.allocator, &module);
    defer context.deinit();
    try std.testing.expect(context.hasUnknown());
}

test "reference metadata: constant merging preserves raw references and stops reporting spurious changes" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\@a = internal unnamed_addr constant i32 7
        \\@b = internal unnamed_addr constant i32 7
        \\define ptr @entry() {
        \\entry:
        \\  ret ptr @a
        \\}
        \\!0 = !{ptr @a}
    );
    defer module.deinit();
    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    try std.testing.expectEqual(.changed, try constmerge.pass.run(&module, &context));
    try std.testing.expectEqual(@as(usize, 2), module.globals.items.len);
    try std.testing.expectEqualStrings("@b", module.functions.items[0].blocks.items[0].terminator.?.ret.value.?.named);
    try std.testing.expectEqualStrings("!0 = !{ptr @a}", module.metadata.items[0]);
    try std.testing.expectEqual(.unchanged, try constmerge.pass.run(&module, &context));
    try module.verify();
}

test "reference metadata: excessive nesting and empty constructed records stay unknown" {
    var text: std.ArrayList(u8) = .empty;
    defer text.deinit(std.testing.allocator);
    try text.appendSlice(std.testing.allocator, "!0 = ");
    for (0..70) |_| try text.appendSlice(std.testing.allocator, "!{");
    for (0..70) |_| try text.append(std.testing.allocator, '}');
    var index = try metadata.Index.init(std.testing.allocator, &.{text.items});
    defer index.deinit();
    try std.testing.expect(index.has_unknown);
    var module = try ir.Module.parse(std.testing.allocator, "declare void @sink()");
    defer module.deinit();
    try module.metadata.append(std.testing.allocator, "");
    var context = try references.Context.init(std.testing.allocator, &module);
    defer context.deinit();
    try std.testing.expect(context.hasUnknown());
    try std.testing.expect(references.hasUnknown(&module));
}
