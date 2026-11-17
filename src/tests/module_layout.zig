const std = @import("std");
const ir = @import("../ir/core.zig");
const layout = @import("../target/module_layout.zig");
const parser = @import("../ir/parser_types_values.zig");

fn facts(text: []const u8, ty: []const u8) !layout.Facts {
    return layout.Query.init(text, &.{}, .{}).?.query(try parser.parseType(ty)) orelse error.TestUnexpectedResult;
}

test "module layout separates scalar payload allocation and explicit integer alignment" {
    try std.testing.expectEqualDeep(layout.Facts{ .store_bytes = 3, .allocation_bytes = 4, .abi_alignment = 4 }, try facts("e-i24:32", "i24"));
    try std.testing.expectEqualDeep(layout.Facts{ .store_bytes = 10, .allocation_bytes = 16, .abi_alignment = 16 }, try facts("e-f80:128", "x86_fp80"));
    try std.testing.expectEqualDeep(layout.Facts{ .store_bytes = 10, .allocation_bytes = 16, .abi_alignment = 8 }, try facts("e-i64:64", "i80"));
    try std.testing.expectEqualDeep(layout.Facts{ .store_bytes = 3, .allocation_bytes = 8, .abi_alignment = 8 }, try facts("e-i32:64", "i24"));
    try std.testing.expectEqualDeep(layout.Facts{ .store_bytes = 8, .allocation_bytes = 8, .abi_alignment = 4 }, try facts("e", "i64"));
    try std.testing.expectEqual(@as(u64, 16), (try facts("e-i64:64-i128:128", "i80")).abi_alignment);
    try std.testing.expectEqual(@as(u64, 4), (try facts("e-i32:64-i32:32", "i24")).abi_alignment);
    try std.testing.expectEqual(@as(u64, 8), (try facts("e-i32:32-i32:64", "i24")).abi_alignment);
}

test "module layout covers nested named packed fields and exact module identity" {
    const names = [_]ir.NamedTypeDefinition{
        .{ .name = "Pair", .body = "{ double, double }", .raw = "" },
        .{ .name = "Outer", .body = "{ i8, %Pair, [2 x i24] }", .raw = "" },
        .{ .name = "Cycle", .body = "{ %Cycle }", .raw = "" },
        .{ .name = "Ambiguous", .body = "{ i8 }", .raw = "" },
        .{ .name = "\"Ambiguous\"", .body = "{ i64 }", .raw = "" },
    };
    const query = layout.Query.init("e-i64:64-i128:128", &names, .{}).?;
    try std.testing.expectEqualDeep(layout.Facts{ .store_bytes = 32, .allocation_bytes = 32, .abi_alignment = 8 }, query.query(.{ .aggregate = "%Outer" }).?);
    try std.testing.expectEqual(@as(u64, 8), query.field(.{ .aggregate = "%Outer" }, 1).?.offset);
    try std.testing.expectEqualStrings("%Pair", query.field(.{ .aggregate = "%Outer" }, 1).?.ty.aggregate);
    try std.testing.expect(query.query(.{ .aggregate = "%Cycle" }) == null);
    try std.testing.expect(query.query(.{ .aggregate = "%Ambiguous" }) == null);
    try std.testing.expect(query.field(.{ .aggregate = "{ i64, %Missing }" }, 0) == null);
    const spelling = layout.Query.init(query.text, &names, .{ .identifier_equality = .spelling }).?;
    try std.testing.expect(spelling.query(.{ .aggregate = "%\"Pair\"" }) == null);
    try std.testing.expectEqual(@as(u64, 1), spelling.query(.{ .aggregate = "%Ambiguous" }).?.allocation_bytes);
    const other_names = [_]ir.NamedTypeDefinition{.{ .name = "Pair", .body = "{ i8 }", .raw = "" }};
    try std.testing.expectEqual(@as(u64, 1), layout.Query.init(query.text, &other_names, .{}).?.query(.{ .aggregate = "%Pair" }).?.allocation_bytes);
    try std.testing.expectEqual(@as(u64, 16), query.query(.{ .aggregate = "%\"Pair\"" }).?.allocation_bytes);
    try std.testing.expectEqualDeep(layout.Facts{ .store_bytes = 21, .allocation_bytes = 21, .abi_alignment = 1 }, try facts("e-i64:64", "<{ i8, i24, x86_fp80 }>"));
}

test "module layout interprets floating vector aggregate and pointer overrides independently" {
    try std.testing.expectEqual(@as(u64, 16), (try facts("e-f64:128", "double")).allocation_bytes);
    try std.testing.expectEqual(@as(u64, 8), (try facts("e-f80:64", "x86_fp80")).abi_alignment);
    try std.testing.expectEqualDeep(layout.Facts{ .store_bytes = 12, .allocation_bytes = 32, .abi_alignment = 32 }, try facts("e-v96:256", "<3 x i32>"));
    try std.testing.expectEqual(@as(u64, 16), (try facts("e-i32:64", "<3 x i32>")).allocation_bytes);
    try std.testing.expectEqual(@as(u64, 16), (try facts("e-a:128", "{ double, double }")).abi_alignment);
    try std.testing.expectEqual(@as(u64, 1), (try facts("e-a:128", "<{ double, double }>")).abi_alignment);
    try std.testing.expectEqual(@as(u64, 16), (try facts("e-a:128", "[0 x { i8 }]")).abi_alignment);
    try std.testing.expectEqual(@as(u64, 4), (try facts("e-p0:32:32", "ptr")).allocation_bytes);
    try std.testing.expectEqual(@as(u64, 8), (try facts("e-p1:32:32", "ptr")).allocation_bytes);
}

fn noWideIntegers(_: []const u8, ty: ir.Type, _: layout.Facts) bool {
    return ty != .int or ty.int <= 64;
}

test "module layout rejects malformed cyclic incomplete overflowing and policy-excluded nodes" {
    for ([_][]const u8{ "e-i24", "e-i24:0", "e-i32:24", "e-i32:32:16", "e-f64:64:32", "e-v96:128:128:128", "e-a:4", "e-a:64:32", "e-p:64:0", "e-p:64:64:32", "e-p0:32:32:32:64" }) |text|
        try std.testing.expect(layout.Query.init(text, &.{}, .{}) == null);
    const query = layout.Query.init("e-i64:64-i128:128", &.{}, .{}).?;
    for ([_][]const u8{ "{ i64, }", "{ i64 } junk", "{ i64, %Missing }", "[18446744073709551615 x i64]", "{ [18446744073709551615 x i8], i64 }", "[0 x %Missing]" }) |text|
        try std.testing.expect(query.query(.{ .aggregate = text }) == null);
    const bounded = layout.Query.init(query.text, &.{}, .{ .max_extent = 16, .max_array_count = 16, .admit = noWideIntegers }).?;
    try std.testing.expect(bounded.query(.{ .aggregate = "[0 x i128]" }) == null);
    try std.testing.expect(bounded.query(.{ .aggregate = "[0 x [17 x i8]]" }) == null);
    try std.testing.expect(bounded.query(.{ .aggregate = "[17 x {}]" }) == null);
    try std.testing.expect(bounded.query(.{ .aggregate = "[0 x i64]" }) != null);
    try std.testing.expect(bounded.field(.{ .aggregate = "{ i8, [17 x i8] }" }, 0) == null);
}
