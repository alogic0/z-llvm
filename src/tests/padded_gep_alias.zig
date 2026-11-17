const std = @import("std");
const ir = @import("../ir.zig");
const alias = @import("../analysis/alias.zig");
const locations = @import("../analysis/memory_location.zig");
const target = @import("../target.zig");
const pm = @import("../pass_manager.zig");
const pipelines = @import("../pipelines.zig");

const cases = [_]struct { ty: []const u8, store: i128, stride: i128 }{
    .{ .ty = "i24", .store = 3, .stride = 4 },
    .{ .ty = "x86_fp80", .store = 10, .stride = 16 },
    .{ .ty = "i40", .store = 5, .stride = 8 },
    .{ .ty = "<3 x i32>", .store = 12, .stride = 16 },
};

fn input(a: std.mem.Allocator, ty: []const u8, direction: i128, nearby: i128) ![]u8 {
    return std.fmt.allocPrint(a,
        \\target datalayout = "e-m:e-p:64:64-i24:32-i64:64-f80:128-n8:16:32:64-S128"
        \\target triple = "x86_64-unknown-linux-gnu"
        \\define i8 @probe(ptr %base) {{
        \\entry:
        \\ %p = getelementptr {s}, ptr %base, i64 {d}
        \\ %q = getelementptr i8, ptr %base, i64 {d}
        \\ store i8 11, ptr %q, align 1
        \\ store i8 22, ptr %p, align 1
        \\ %v = load i8, ptr %q, align 1
        \\ ret i8 %v
        \\}}
        \\
    , .{ ty, direction, nearby });
}

test "layout stride locations distinguish allocation padding from access width" {
    const a = std.testing.allocator;
    for (cases) |case| for ([_]i128{ 1, -1 }) |direction| {
        const source = try input(a, case.ty, direction, case.store * direction);
        defer a.free(source);
        var module = try ir.Module.parse(a, source);
        defer module.deinit();
        try module.verify();
        const layout = try target.DataLayout.parse(module.target_datalayout.?);
        const function = module.functions.items[0];
        const gep = function.blocks.items[0].instructions.items[0].kind.gep;
        try std.testing.expectEqual(@as(u64, @intCast(case.store)), locations.typeSizeWithLayout(layout, gep.source_ty).?);
        try std.testing.expectEqual(case.stride * direction, locations.gepOffsetWithLayout(layout, gep).?);
        const access = locations.forAccessInModuleWithLayout(module, function, layout, .{ .named = "p" }, .{ .int = 8 }).?;
        try std.testing.expectEqual(case.stride * direction, access.offset.?);
        try std.testing.expectEqual(@as(u64, 1), access.size.?);
        try std.testing.expectEqual(alias.AliasResult.no_alias, alias.accessAliasInModule(module, function, .{ .named = "p" }, .{ .int = 8 }, .{ .named = "q" }, .{ .int = 8 }));
    };
}

test "layout stride optimizer keeps distinct padded byte stores" {
    const a = std.testing.allocator;
    for (cases) |case| for ([_]i128{ 1, -1 }) |direction| {
        const source = try input(a, case.ty, direction, case.store * direction);
        defer a.free(source);
        for ([_][]const u8{ "early-cse", "gvn", "dse,early-cse", "release-o3" }) |passes| {
            var module = try ir.Module.parse(a, source);
            defer module.deinit();
            try module.verify();
            var manager = pm.ModulePassManager.init(a);
            defer manager.deinit();
            try pipelines.addPasses(&manager, passes);
            var context: pm.Context = .{ .allocator = a };
            var output = std.Io.Writer.Allocating.init(a);
            defer output.deinit();
            _ = try manager.run(&module, &context, &output.writer, false);
            try module.verify();
            const result = module.functions.items[0].blocks.items[0].terminator.?.ret.value.?;
            try std.testing.expect(result == .int);
            try std.testing.expectEqual(@as(i128, 11), result.int);
        }
    };
}

test "layout stride target-free padded scalars retain unknown offsets" {
    const a = std.testing.allocator;
    for (cases) |case| for ([_]i128{ 1, -1 }) |direction| {
        const source = try input(a, case.ty, direction, case.store * direction);
        defer a.free(source);
        const line = std.mem.indexOfScalar(u8, source, '\n').? + 1;
        var module = try ir.Module.parse(a, source[line..]);
        defer module.deinit();
        try module.verify();
        const function = module.functions.items[0];
        const gep = function.blocks.items[0].instructions.items[0].kind.gep;
        try std.testing.expect(locations.gepOffset(gep) == null);
        const access = locations.forAccess(function, .{ .named = "p" }, .{ .int = 8 }).?;
        try std.testing.expect(access.offset == null);
        try std.testing.expect(access.rangeEnd() == null);
        try std.testing.expectEqual(@as(u64, 1), access.size.?);
        try std.testing.expectEqual(alias.AliasResult.may_alias, alias.accessAliasInModule(module, function, .{ .named = "p" }, .{ .int = 8 }, .{ .named = "q" }, .{ .int = 8 }));
    };
}
