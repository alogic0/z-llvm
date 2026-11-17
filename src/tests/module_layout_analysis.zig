const std = @import("std");
const ir = @import("../ir.zig");
const target = @import("../target.zig");
const locations = @import("../analysis/memory_location.zig");
const pm = @import("../pass_manager.zig");
const pipelines = @import("../pipelines.zig");

const cases = [_]struct { ty: []const u8, payload: u64, stride: i128, old_stride: i128 }{
    .{ .ty = "i24", .payload = 3, .stride = 8, .old_stride = 4 },
    .{ .ty = "i9", .payload = 2, .stride = 4, .old_stride = 2 },
    .{ .ty = "{ i8, i80 }", .payload = 24, .stride = 24, .old_stride = 32 },
    .{ .ty = "{ i8, i24 }", .payload = 16, .stride = 16, .old_stride = 8 },
};

fn input(a: std.mem.Allocator, case: @TypeOf(cases[0])) ![]u8 {
    return std.fmt.allocPrint(a,
        \\target datalayout = "e-p:64:64-i16:32-i32:64-i64:64"
        \\define i8 @probe(ptr %base) {{
        \\entry:
        \\ %p = getelementptr {s}, ptr %base, i64 1
        \\ %q = getelementptr i8, ptr %base, i64 {d}
        \\ store i8 11, ptr %q, align 1
        \\ store i8 22, ptr %p, align 1
        \\ %v = load i8, ptr %q, align 1
        \\ ret i8 %v
        \\}}
        \\
    , .{ case.ty, case.old_stride });
}

test "module layout analysis uses exact integer overrides and complete fields" {
    const a = std.testing.allocator;
    for (cases) |case| {
        const text = try input(a, case);
        defer a.free(text);
        var module = try ir.Module.parse(a, text);
        defer module.deinit();
        try module.verify();
        const dl = try target.DataLayout.parse(module.target_datalayout.?);
        const gep = module.functions.items[0].blocks.items[0].instructions.items[0].kind.gep;
        try std.testing.expectEqual(case.payload, locations.typeSizeWithLayout(dl, gep.source_ty).?);
        try std.testing.expectEqual(case.stride, locations.gepOffsetWithLayout(dl, gep).?);
    }
    const dl = try target.DataLayout.parse("e-p:64:64-i32:64-i64:64");
    try std.testing.expectEqual(@as(?i128, 8), locations.aggregateFieldOffsetWithLayout(dl, .{ .aggregate = "{ i8, i24 }" }, 1));
    try std.testing.expectEqual(@as(?i128, 16), locations.aggregateFieldOffsetWithLayout(dl, .{ .aggregate = "[4 x i24]" }, 2));
    try std.testing.expect(locations.typeSizeWithLayout(dl, .{ .aggregate = "%Unknown" }) == null);
    try std.testing.expect(locations.aggregateFieldOffsetWithLayout(dl, .{ .aggregate = "{ i8, %Unknown }" }, 0) == null);
}

test "module layout analysis keeps optimizer stores distinct under integer overrides" {
    const a = std.testing.allocator;
    for (cases) |case| for ([_][]const u8{ "early-cse", "gvn", "dse,early-cse", "release-o3" }) |passes| {
        const text = try input(a, case);
        defer a.free(text);
        var module = try ir.Module.parse(a, text);
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
        const value = module.functions.items[0].blocks.items[0].terminator.?.ret.value.?;
        try std.testing.expect(value == .int);
        try std.testing.expectEqual(@as(i128, 11), value.int);
    };
}
