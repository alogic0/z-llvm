const std = @import("std");
const ir = @import("../ir.zig");
const constants = @import("../analysis/reference_constants.zig");
const references = @import("../analysis/module_references.zig");
const dependencies = @import("../analysis/global_dependencies.zig");
const globalopt = @import("../passes/globalopt.zig");
const pass_manager = @import("../pass_manager.zig");

const Collector = struct {
    pub const Error = std.mem.Allocator.Error;
    names: *std.ArrayList([]const u8),
    pub fn symbol(collector: Collector, name: []const u8) Error!void {
        try collector.names.append(std.testing.allocator, name);
    }
};

fn check(text: []const u8, ty: ir.Type, expected: ?[]const []const u8) !void {
    var names: std.ArrayList([]const u8) = .empty;
    defer names.deinit(std.testing.allocator);
    const complete = try constants.value(text, ty, Collector{ .names = &names });
    try std.testing.expectEqual(expected != null, complete);
    if (expected) |symbols| {
        try std.testing.expectEqual(symbols.len, names.items.len);
        for (symbols, names.items) |name, actual| try std.testing.expect(ir.identifiers.eql(name, actual));
    }
}

test "reference constants: nested typed aggregates and quoted symbols enumerate every reference" {
    try check("{ ptr @a, [2 x ptr] [ptr @\"b\\2Ec\", ptr null], <{ i8, ptr }> <{ i8 1, ptr @a }> }", .{ .aggregate = "{ ptr, [2 x ptr], <{ i8, ptr }> }" }, &.{ "a", "b.c", "a" });
    try check("{ ptr @0, ptr @\"0\", %nested { ptr @target } }", .{ .aggregate = "%root" }, &.{ "0", "\"0\"", "target" });
    try check("<ptr @left, ptr @right>", .{ .vector = .{ .len = 2, .elem_ty = .ptr } }, &.{ "left", "right" });
    try check("c\"@a blockaddress(@f, %b)\\00\"", .{ .aggregate = "[25 x i8]" }, &.{});
    try check("[i64 18446744073709551615, i64 -9223372036854775808]", .{ .aggregate = "[2 x i64]" }, &.{});
    try check("[]", .{ .aggregate = "[0 x ptr]" }, &.{});
    try check("zeroinitializer", .{ .aggregate = "%recursive" }, &.{});
}

test "reference constants: GEP and cast operands preserve global identity" {
    try check("getelementptr inbounds ([4 x i32], ptr @array, i64 0, i64 2)", .ptr, &.{"array"});
    try check("getelementptr nusw nuw (i8, ptr addrspace(1) @bytes, i64 -1)", .ptr, &.{"bytes"});
    try check("inttoptr (i64 ptrtoint (ptr @\"g\\6cobal\" to i64) to ptr)", .ptr, &.{"global"});
    try check("bitcast (ptr @function to ptr)", .ptr, &.{"function"});
    try check("addrspacecast (ptr addrspace(1) @data to ptr)", .ptr, &.{"data"});
    try check("inttoptr (i64 0 to ptr)", .ptr, &.{});
    try check("<double 1.0, double 0x8000000000000000>", .{ .vector = .{ .len = 2, .elem_ty = .double } }, &.{});
}

test "reference constants: unsupported or incomplete syntax never proves absence" {
    for ([_][]const u8{
        "",                                   "@",                                     "@\"unterminated",                          "@\"bad\\+1\"",                "@g trailing",                                                   "@g @other",
        "dso_local_equivalent @helper",       "blockaddress(@f, %b)",                  "unknown(plain)",                           "getelementptr (i8, ptr @g,)", "getelementptr (i8 ptr @g, i64 0)",                              "getelementptr inbounds inbounds (i8, ptr @g, i64 0)",
        "getelementptr (i8, ptr @g, i64 +1)", "getelementptr (i8, ptr @g, i64 1junk)", "getelementptr (i8, ptr @g, i64 %runtime)", "bitcast (ptr @g ptr)",        "inttoptr (i64 340282366920938463463374607431768211456 to ptr)", "inttoptr (i64 - 1 to ptr)",
        "bitcast (ptr @g to ptr) @hidden",
    }) |text| try check(text, .ptr, null);
    for ([_][]const u8{ "{ ptr @g, }", "{ ptr @g", "{ ptr @g } junk", "{ ptr @g, i32 unknown }", "{ %\"bad\\+1\" zeroinitializer }" }) |text|
        try check(text, .{ .aggregate = "%type" }, null);
    try check("zeroinitializer", .{ .aggregate = "{ ptr @hidden }" }, null);
    try check("<ptr @g>", .{ .aggregate = "<vscale x 1 x ptr>" }, null);
}

test "reference constants: nesting limits return unknown without recursive overflow" {
    var text: std.ArrayList(u8) = .empty;
    defer text.deinit(std.testing.allocator);
    for (0..constants.max_depth + 1) |_| try text.appendSlice(std.testing.allocator, "inttoptr (i64 ptrtoint (ptr ");
    try text.appendSlice(std.testing.allocator, "@g");
    for (0..constants.max_depth + 1) |_| try text.appendSlice(std.testing.allocator, " to i64) to ptr)");
    try check(text.items, .ptr, null);
}

test "reference constants: complete aggregate edges keep callbacks and discard unrelated definitions" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\@table = global { [1 x ptr], ptr } { [1 x ptr] [ptr @callback], ptr @value }
        \\@value = internal global i32 7
        \\@dead = internal global i32 9
        \\define internal i32 @callback() {
        \\entry:
        \\  ret i32 1
        \\}
        \\define internal i32 @unused() {
        \\entry:
        \\  ret i32 2
        \\}
    );
    defer module.deinit();
    var graph = try dependencies.Graph.build(std.testing.allocator, module);
    defer graph.deinit();
    var selection = try graph.reachable();
    defer selection.deinit();
    try std.testing.expect(!selection.has_unknown);
    try std.testing.expect(selection.contains(.global, "table"));
    try std.testing.expect(selection.contains(.global, "value"));
    try std.testing.expect(selection.contains(.function, "callback"));
    try std.testing.expect(!selection.contains(.global, "dead"));
    try std.testing.expect(!selection.contains(.function, "unused"));
}

test "reference constants: a store through a constant GEP prevents GlobalOpt folding" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\@value = internal global i32 7
        \\define i32 @entry(i32 %x) {
        \\entry:
        \\  store i32 %x, ptr getelementptr (i32, ptr @value, i64 0)
        \\  %v = load i32, ptr @value
        \\  ret i32 %v
        \\}
    );
    defer module.deinit();
    try module.verify();
    var context = try references.Context.init(std.testing.allocator, &module);
    defer context.deinit();
    const query = context.query("value");
    try std.testing.expectEqual(@as(usize, 2), query.direct_uses);
    try std.testing.expect(!query.has_unknown);
    var pass_context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    try std.testing.expectEqual(.unchanged, try globalopt.pass.run(&module, &pass_context));
    try module.verify();
    try std.testing.expectEqual(@as(usize, 1), module.globals.items.len);
    try std.testing.expect(!module.functions.items[0].blocks.items[0].instructions.items[1].removed);
}
