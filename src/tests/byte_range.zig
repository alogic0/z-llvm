const std = @import("std");
const ir = @import("../ir.zig");
const ranges = @import("../analysis/byte_range.zig");
const locations = @import("../analysis/memory_location.zig");
const alias = @import("../analysis/alias.zig");
const objects = @import("../codegen/x86_64/generic_cfg/aggregate_object.zig");

test "byte ranges keep unknown facts distinct from zero and decline overflow" {
    const Range = ranges.ByteRange;
    try std.testing.expect((Range{ .offset = null, .length = 0 }).end() == null);
    try std.testing.expect(!(Range{ .offset = 0, .length = null }).within(8));
    try std.testing.expect(!(Range{ .offset = 0, .length = 0 }).within(null));
    try std.testing.expect((Range{ .offset = 0, .length = 0 }).within(0));
    try std.testing.expect((Range{ .offset = 8, .length = 0 }).within(8));
    try std.testing.expect(!(Range{ .offset = 8, .length = 1 }).within(8));
    try std.testing.expect(!(Range{ .offset = -1, .length = 1 }).within(8));
    try std.testing.expect((Range{ .offset = std.math.maxInt(i128), .length = 1 }).end() == null);
    try std.testing.expect(ranges.addOffset(std.math.minInt(i128), -1) == null);
    try std.testing.expect(ranges.addOffset(null, 0) == null);
    try std.testing.expectEqual(@as(?i128, 0), ranges.addOffset(-1, 1));
    const location: locations.MemoryLocation = .{
        .ptr = .{ .named = "p" },
        .root = "p",
        .root_kind = .parameter,
        .offset = std.math.maxInt(i128),
        .size = 1,
    };
    try std.testing.expect(location.rangeEnd() == null);
    var indices: std.ArrayList(ir.GepIndex) = .empty;
    defer indices.deinit(std.testing.allocator);
    try indices.append(std.testing.allocator, .{ .ty = .{ .int = 128 }, .value = .{ .int = std.math.maxInt(i128) } });
    try std.testing.expect(locations.gepOffset(.{ .source_ty = .{ .int = 64 }, .ptr = .{ .named = "p" }, .indices = indices }) == null);
}

const source =
    \\declare ptr @escape(ptr)
    \\define void @views(i1 %choose, ptr %external) {
    \\entry:
    \\ %left = alloca { float, float }, align 4
    \\ %right = alloca { float, float }, align 4
    \\ %l = getelementptr i8, ptr %left, i64 4
    \\ %r = getelementptr i8, ptr %right, i64 4
    \\ %end = getelementptr i8, ptr %left, i64 8
    \\ %outside = getelementptr i8, ptr %left, i64 9
    \\ %escaped = call ptr @escape(ptr %left)
    \\ br i1 %choose, label %a, label %b
    \\a:
    \\ br label %join
    \\b:
    \\ br label %join
    \\join:
    \\ %distinct = phi ptr [ %l, %a ], [ %r, %b ]
    \\ %same = phi ptr [ %l, %a ], [ %l, %b ]
    \\ %unknown = phi ptr [ %l, %a ], [ %external, %b ]
    \\ ret void
    \\}
;

test "byte bounds across same and different PHI roots grant no alias identity" {
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    try module.verify();
    const function = module.functions.items[0];
    for ([_][]const u8{ "same", "distinct" }) |name| {
        const view = objects.pointerView(function, null, .{ .named = name }).?;
        try std.testing.expectEqual(@as(u8, 4), view.offset);
        try std.testing.expect(view.allows(4));
        try std.testing.expect(!view.allows(5));
        try std.testing.expect(locations.forPointer(function, .{ .named = name }) == null);
        try std.testing.expectEqual(alias.AliasResult.may_alias, alias.accessAliasInModule(module, function, .{ .named = name }, .float, .{ .named = "left" }, .float));
    }
    for ([_][]const u8{ "unknown", "external", "escaped", "outside" }) |name|
        try std.testing.expect(objects.pointerView(function, null, .{ .named = name }) == null);
    const end = objects.pointerView(function, null, .{ .named = "end" }).?;
    try std.testing.expect(end.allows(0));
    try std.testing.expect(!end.allows(1));
    const access = locations.forAccess(function, .{ .named = "l" }, .float).?;
    try std.testing.expectEqualStrings("left", access.root);
    try std.testing.expectEqual(@as(?i128, 8), access.rangeEnd());
    try std.testing.expectEqual(@as(?u64, 4), access.size);
    try std.testing.expectEqual(alias.AliasResult.no_alias, alias.accessAliasInModule(module, function, .{ .named = "l" }, .float, .{ .named = "r" }, .float));
}
