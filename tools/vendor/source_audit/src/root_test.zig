const std = @import("std");
const audit = @import("root.zig");
const a = std.testing.allocator;
const rule = audit.boundaries.Rule{
    .name = "core stays independent",
    .from = &.{.{ .prefix = "src/core/", .tests = .exclude }},
    .deny = &.{ .{ .prefix = "src/ui/" }, .{ .tests = .only } },
};

test "owned report retains copied inputs and transitive diagnostic paths" {
    var report = blk: {
        const source = try a.dupe(u8, "const bridge = @import(\"../bridge.zig\");");
        defer a.free(source);
        const path = try a.dupe(u8, "src/core/entry.zig");
        defer a.free(path);
        break :blk try audit.analyze(a, &.{
            .{ .path = path, .text = source },
            .{ .path = "src/bridge.zig", .text = "const ui = @import(\"ui/card.zig\");" },
            .{ .path = "src/ui/card.zig", .text = "fn draw() void {}" },
        });
    };
    defer report.deinit();
    try std.testing.expectEqual(@as(usize, 0), report.syntax_errors);
    const failures = try report.check(&.{rule});
    try std.testing.expectEqual(@as(usize, 1), failures.len);
    const expected = [_][]const u8{ "src/core/entry.zig", "src/bridge.zig", "src/ui/card.zig" };
    try std.testing.expectEqual(expected.len, failures[0].chain.len);
    for (expected, failures[0].chain) |want, actual| try std.testing.expectEqualStrings(want, actual);
    try std.testing.expectEqualStrings("draw", report.files[2].structure.?.functions[0].name);
}

fn allocationPaths(allocator: std.mem.Allocator) !void {
    var report = try audit.analyze(allocator, &.{
        .{ .path = "src/core/main.zig", .text = "const bridge = @import(\"../bridge.zig\");" },
        .{ .path = "src/bridge.zig", .text = "const ui = @import(\"ui/card.zig\");" },
        .{ .path = "src/ui/card.zig", .text = "const = ;" },
    });
    defer report.deinit();
    try std.testing.expectEqual(@as(usize, 1), report.syntax_errors);
    try std.testing.expectEqual(@as(usize, 1), (try report.check(&.{rule})).len);
}
test "owned analysis and configured boundaries release every injected allocation" {
    try std.testing.checkAllAllocationFailures(a, allocationPaths, .{});
}

test "invalid source paths and duplicate sources fail without retained owners" {
    for ([_][]const u8{ "", "/outside.zig", "../outside.zig", "src//file.zig", "src/./file.zig", "src\\file.zig" }) |path| {
        try std.testing.expectError(error.InvalidSourcePath, audit.analyze(a, &.{.{ .path = path, .text = "" }}));
    }
    try std.testing.expectError(error.DuplicateSource, audit.analyze(a, &.{ .{ .path = "same.zig", .text = "" }, .{ .path = "same.zig", .text = "" } }));
}

test "rule selector constraints combine and overlapping rules yield one path diagnostic" {
    var report = try audit.analyze(a, &.{
        .{ .path = "src/core/main.zig", .text = "const helper = @import(\"helper.zig\");" },
        .{ .path = "src/core/helper.zig", .text = "const ui = @import(\"../ui/card.zig\");" },
        .{ .path = "src/ui/card.zig", .text = "" },
    });
    defer report.deinit();
    const specific = audit.boundaries.Rule{
        .name = "entry only",
        .from = &.{.{ .prefix = "src/core/", .suffix = "main.zig", .exclude_paths = &.{"src/core/helper.zig"} }},
        .deny = &.{.{ .prefix = "src/ui/" }},
    };
    const failures = try report.check(&.{ specific, specific });
    try std.testing.expectEqual(@as(usize, 1), failures.len);
    try std.testing.expectEqualStrings("entry only", failures[0].rule);
}

test "configured rules check selected test origins and cycle-closing edges" {
    var report = try audit.analyze(a, &.{
        .{ .path = "src/a.zig", .text = "const b = @import(\"b.zig\");" },
        .{ .path = "src/b.zig", .text = "const a = @import(\"a.zig\");" },
        .{ .path = "src/a_test.zig", .text = "test { _ = @import(\"a.zig\"); }" },
    });
    defer report.deinit();
    const violations = try report.check(&.{
        .{ .name = "no return edge", .from = &.{.{ .exact = "src/a.zig" }}, .deny = &.{.{ .exact = "src/a.zig" }} },
        .{ .name = "selected tests", .from = &.{.{ .tests = .only }}, .deny = &.{.{ .exact = "src/a.zig" }} },
    });
    try std.testing.expectEqual(@as(usize, 2), violations.len);
    try std.testing.expectEqual(@as(usize, 3), violations[0].chain.len);
    try std.testing.expectEqualStrings("src/a.zig", violations[0].chain[2]);
    try std.testing.expectEqualStrings("selected tests", violations[1].rule);
}
