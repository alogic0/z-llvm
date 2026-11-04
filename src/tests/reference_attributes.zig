const std = @import("std");
const ir = @import("../ir.zig");
const attributes = @import("../analysis/reference_attributes.zig");
const references = @import("../analysis/module_references.zig");
const dependencies = @import("../analysis/global_dependencies.zig");
const globaldce = @import("../passes/globaldce.zig");
const globalopt = @import("../passes/globalopt.zig");
const constmerge = @import("../passes/constmerge.zig");
const pass_manager = @import("../pass_manager.zig");

test "reference attributes: complete bounded fields do not contain references" {
    for ([_][]const u8{
        "",                                                                                       " \t\n",                                                             "unnamed_addr nounwind",                          "align 4",                                         "align 4294967296",
        "nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write)",            "memory(argmem: readwrite, inaccessiblemem: none, errnomem: write)", "memory(read, argmem: write, argmem: readwrite)", "nocreateundeforpoison speculatable memory(none)", "nosanitize_coverage skipprofile",
        "\"frame-pointer\"=\"all\" \"target-cpu\"=\"x86-64\" \"target-features\"=\"+sse2,-avx\"", "\"frame-pointer\"=\"non-leaf\"",                                    "\"frame-pointer\"=\"none\"",                     "\"frame-poi\\6Eter\"=\"a\\6cl\"",
        // These two explicitly reference-free keys contain data, even when
        // their values resemble a symbol or blockaddress expression.
                        "\"target-cpu\"=\"@hidden\" \"target-features\"=\"blockaddress(@f, %b)\"",
        "\"target-cpu\"=\"\"",                                                                    "\"target-features\"=\"\\22\\5C\"",                                  "align 8, unnamed_addr",
    }) |text| try std.testing.expect(attributes.referenceFree(text, null));
}

test "reference attributes: unsupported and malformed fields keep unknown coverage" {
    for ([_][]const u8{
        "#0",                            "#-1",                            "#4294967296",                   "unknown_attribute",             "@g",
        "\"probe-stack\"=\"helper\"",    "\"unknown-key\"=\"plain text\"", "\"probe-sta\\63k\"=\"helper\"", "\"frame-pointer\"=\"@hidden\"", "\"frame-pointer\"",
        "\"target-cpu\"=",               "\"target-cpu\"=\"unterminated",  "\"target-cpu\"=\"bad\\+1\"",    "\"target-cpu\"=\"bad\\00\"",    "\"target-cpu\"=\"bad\nvalue\"",
        "\"target-cpu\"=\"ok\" @hidden", "align",                          "align 0",                       "align 3",                       "align -8",
        "align +8",                      "align 8junk",                    "align 8589934592",              "align 18446744073709551616",    "align=8",
        "memory",                        "memory()",                       "memory(read",                   "memory(read) trailing",         "memory(argmem read)",
        "memory(unknown: read)",         "memory(argmem: unknown)",        "memory(argmem: read, write)",   "memory(read,)",                 "memory(read,,write)",
        "nounwind,",                     ",nounwind",                      "nounwind,,nofree",              "nounwind { @hidden }",
    }) |text| try std.testing.expect(!attributes.referenceFree(text, null));
}

test "reference attributes: bounded typed parameter fields resolve without value references" {
    for ([_][]const u8{
        "dead_on_unwind noalias writeonly sret({ %os.linux.rlimit, i16, [6 x i8] }) align 8 captures(none)",
        "byval([2 x i64]) byref(<{ i32, ptr }>) inalloca({})",
        "preallocated(%\"a@b\") elementtype(<4 x i32>)",
        "dereferenceable(0) dereferenceable_or_null(18446744073709551615)",
        "elementtype(i8388608)",
    }) |text| try std.testing.expect(attributes.referenceFree(text, null));
    for ([_][]const u8{
        "sret",                           "sret()",                      "sret({ ptr @hidden })", "sret(i32 1)",
        "byval(%unterminated\")",         "byref([2 x i64)",             "inalloca(opaque)",      "elementtype(i0)",
        "elementtype(i8388609)",          "elementtype(<0 x i32>)",      "captures()",            "captures(address)",
        "captures(none, none)",           "captures(none) @hidden",      "dereferenceable(-1)",   "dereferenceable(18446744073709551616)",
        "dereferenceable_or_null(8junk)", "dereferenceable(8) trailing",
    }) |text| try std.testing.expect(!attributes.referenceFree(text, null));
}

fn checkGroups(allocator: std.mem.Allocator) !void {
    var groups = try attributes.Groups.init(allocator, &.{
        "attributes #0 = { nounwind \"frame-pointer\"=\"all\" }",
        "attributes #7 = { nocallback memory(argmem: readwrite) }",
        "attributes #4294967295 = { nofree }",
    });
    defer groups.deinit();
    try std.testing.expect(!groups.has_unknown);
    try std.testing.expect(attributes.referenceFree("unnamed_addr #0 #7", &groups));
    try std.testing.expect(attributes.referenceFree("#4294967295", &groups));
    for ([_][]const u8{ "#1", "#-1", "#+1", "#4294967296", "#7nounwind", "#0 #8" }) |text|
        try std.testing.expect(!attributes.referenceFree(text, &groups));
}

test "reference attributes: indexed groups resolve with complete coverage" {
    try checkGroups(std.testing.allocator);
}

test "reference attributes: allocation failures release group lookup storage" {
    try std.testing.checkAllAllocationFailures(std.testing.allocator, checkGroups, .{});
}

test "reference attributes: incomplete definitions and duplicate IDs stay unknown" {
    for ([_][]const u8{
        "",                                      "attributes #0 = {}",                             "attributes #0 = { }",
        "attributes #-1 = { nounwind }",         "attributes #4294967296 = { nounwind }",          "attributes #0 { nounwind }",
        "attributes #0 = nounwind",              "attributes #0 = { nounwind",                     "attributes #0 = { nounwind } junk",
        "attributes #0 = { nounwind } }",        "attributes #0 = { { nounwind } }",               "attributes #0 = { #1 }",
        "attributes #0 = { unknown_attribute }", "attributes #0 = { \"probe-stack\"=\"helper\" }", "attributes #0 = { \"unknown\"=\"plain\" }",
    }) |record| {
        var groups = try attributes.Groups.init(std.testing.allocator, &.{record});
        defer groups.deinit();
        try std.testing.expect(groups.has_unknown);
        try std.testing.expect(!attributes.referenceFree("#0", &groups));
    }
    var duplicates = try attributes.Groups.init(std.testing.allocator, &.{
        "attributes #1 = { nounwind }", "attributes #1 = { nounwind }", "attributes #1 = { nofree }",
    });
    defer duplicates.deinit();
    try std.testing.expect(duplicates.has_unknown);
    try std.testing.expect(!attributes.referenceFree("#1", &duplicates));
}

const source =
    \\@foldable = internal global i32 23, align 4
    \\@mutated = internal global i32 0
    \\@dead = internal global i32 17
    \\define internal i32 @helper(i32 noundef %x) #0 {
    \\entry:
    \\  store i32 %x, ptr @mutated
    \\  ret i32 %x
    \\}
    \\define internal void @dead_function() #0 {
    \\entry:
    \\  ret void
    \\}
    \\define i32 @entry(i32 noundef %x) unnamed_addr #0 {
    \\entry:
    \\  %constant = load i32, ptr @foldable
    \\  %called = call noundef i32 @helper(i32 noundef %x) #0
    \\  %loaded = load i32, ptr @mutated
    \\  %sum = add i32 %constant, %loaded
    \\  ret i32 %sum
    \\}
    \\attributes #0 = { nounwind "frame-pointer"="all" }
;

test "reference attributes: context resolves groups and tracks rewritten uses" {
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    try module.verify();
    var context = try references.Context.init(std.testing.allocator, &module);
    defer context.deinit();
    try std.testing.expect(references.hasUnknown(&module)); // no group context
    try std.testing.expect(!context.hasUnknown());
    try std.testing.expectEqual(@as(usize, 1), context.query("foldable").direct_uses);
    try std.testing.expectEqual(@as(usize, 2), context.query("mutated").direct_uses);
    var pass_context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    _ = try globalopt.pass.run(&module, &pass_context);
    try module.verify();
    try std.testing.expect(!context.query("foldable").mayReference());
    try std.testing.expectEqual(@as(usize, 2), context.query("mutated").direct_uses);
    try std.testing.expectEqual(@as(usize, 2), module.globals.items.len);
    try std.testing.expectEqualStrings("mutated", module.globals.items[0].name);
    try std.testing.expect(module.functions.items[2].blocks.items[0].instructions.items[0].removed);
    try std.testing.expect(!module.functions.items[2].blocks.items[0].instructions.items[2].removed);
}

fn checkSelection(allocator: std.mem.Allocator) !void {
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    var graph = try dependencies.Graph.build(allocator, module);
    defer graph.deinit();
    var selection = try graph.reachable();
    defer selection.deinit();
    try std.testing.expect(!selection.has_unknown);
    try std.testing.expect(selection.contains(.function, "entry"));
    try std.testing.expect(selection.contains(.function, "helper"));
    try std.testing.expect(selection.contains(.global, "foldable"));
    try std.testing.expect(selection.contains(.global, "mutated"));
    try std.testing.expect(!selection.contains(.function, "dead_function"));
    try std.testing.expect(!selection.contains(.global, "dead"));
    try module.verify();
    try std.testing.expectEqual(@as(usize, 3), module.globals.items.len);
}

test "reference attributes: reachable selection and its allocation failures preserve the module" {
    try checkSelection(std.testing.allocator);
    try std.testing.checkAllAllocationFailures(std.testing.allocator, checkSelection, .{});
}

fn checkPass(allocator: std.mem.Allocator, pass: pass_manager.ModulePass) !void {
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    var context: pass_manager.Context = .{ .allocator = allocator };
    _ = pass.run(&module, &context) catch |err| {
        try module.verify();
        try std.testing.expectEqual(@as(usize, 3), module.globals.items.len);
        try std.testing.expectEqual(@as(usize, 3), module.functions.items.len);
        return err;
    };
    try module.verify();
    try std.testing.expectEqual(@as(usize, 2), module.globals.items.len);
}

test "reference attributes: GlobalDCE and GlobalOpt allocate before destructive edits" {
    for ([_]pass_manager.ModulePass{ globaldce.pass, globalopt.pass }) |pass| {
        try checkPass(std.testing.allocator, pass);
        try std.testing.checkAllAllocationFailures(std.testing.allocator, checkPass, .{pass});
    }
}

test "reference attributes: unknown groups and helper strings block optimizer deletion" {
    for ([_][]const u8{
        "attributes #0 = { \"probe-stack\"=\"helper\" }",
        "attributes #0 = { \"unrecognized\"=\"plain\" }",
        "attributes #0 = { unknown_attribute }",
        "attributes #0 = { #1 }",
        // Recognized groups cannot hide an unknown or duplicate module record.
        "attributes #0 = { nounwind }\nattributes #1 = { \"probe-stack\"=\"helper\" }",
        "attributes #0 = { nounwind }\nattributes #0 = { nofree }",
        "attributes #1 = { nounwind }", // missing #0
    }) |group| {
        const prefix = source[0..std.mem.indexOf(u8, source, "attributes #0").?];
        const input = try std.fmt.allocPrint(std.testing.allocator, "{s}{s}\n", .{ prefix, group });
        defer std.testing.allocator.free(input);
        var module = try ir.Module.parse(std.testing.allocator, input);
        defer module.deinit();
        var context = try references.Context.init(std.testing.allocator, &module);
        defer context.deinit();
        try std.testing.expect(context.hasUnknown());
        var pass_context: pass_manager.Context = .{ .allocator = std.testing.allocator };
        _ = try globaldce.pass.run(&module, &pass_context);
        _ = try globalopt.pass.run(&module, &pass_context);
        try std.testing.expectEqual(@as(usize, 3), module.globals.items.len);
        try std.testing.expectEqual(@as(usize, 3), module.functions.items.len);
        try std.testing.expect(!module.functions.items[2].blocks.items[0].instructions.items[0].removed);
    }
}

test "reference attributes: declaration groups resolve while unsupported metadata remains unknown" {
    for ([_][]const u8{
        "declare noundef i32 @sink(i32 noundef) #0\nattributes #0 = { nounwind memory(none) }",
        "declare noundef i32 @sink(i32 noundef) #0\nattributes #0 = { nounwind memory(none) }\n!0 = !UnknownMetadata(value: 1)",
    }, 0..) |input, index| {
        var module = try ir.Module.parse(std.testing.allocator, input);
        defer module.deinit();
        var context = try references.Context.init(std.testing.allocator, &module);
        defer context.deinit();
        try std.testing.expectEqual(index != 0, context.hasUnknown());
    }
}

test "reference attributes: empty malformed group records cannot claim module coverage" {
    var module = try ir.Module.parse(std.testing.allocator, "declare void @sink()");
    defer module.deinit();
    try module.attribute_groups.append(std.testing.allocator, "");
    var context = try references.Context.init(std.testing.allocator, &module);
    defer context.deinit();
    try std.testing.expect(context.hasUnknown());
    try std.testing.expect(references.hasUnknown(&module));
}

test "reference attributes: constant merging rewrites uses with recognized groups only" {
    for ([_][]const u8{ "nounwind", "\"probe-stack\"=\"helper\"" }, 0..) |body, index| {
        const input = try std.fmt.allocPrint(std.testing.allocator,
            \\@a = internal unnamed_addr constant i32 7
            \\@b = internal unnamed_addr constant i32 7
            \\define ptr @get() #0 {{
            \\entry:
            \\  ret ptr @a
            \\}}
            \\attributes #0 = {{ {s} }}
        , .{body});
        defer std.testing.allocator.free(input);
        var module = try ir.Module.parse(std.testing.allocator, input);
        defer module.deinit();
        try module.verify();
        var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
        _ = try constmerge.pass.run(&module, &context);
        try module.verify();
        try std.testing.expectEqual(@as(usize, if (index == 0) 1 else 2), module.globals.items.len);
        const value = module.functions.items[0].blocks.items[0].terminator.?.ret.value.?;
        try std.testing.expectEqualStrings(if (index == 0) "@b" else "@a", value.named);
    }
}
