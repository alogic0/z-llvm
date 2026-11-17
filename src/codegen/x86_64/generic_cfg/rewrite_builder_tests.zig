const std = @import("std");
const ir = @import("../../../ir.zig");
const floating = @import("floating_pair_loads.zig");
const bitcasts = @import("memory_bitcasts.zig");
const Builder = @import("rewrite_builder.zig").Builder;

const floating_source =
    \\define { double, double } @snapshot(ptr %p, i64 %__zllvm_fp_pair_load_0) {
    \\entry:
    \\ %before = load double, ptr %p, align 8
    \\ %pair = load { double, double }, ptr %p, align 16, !dbg !0
    \\ store double 0.0, ptr %p, align 8
    \\ ret { double, double } %pair
    \\}
    \\!0 = !{i32 7}
;

const bitcast_source =
    \\define i256 @snapshot(<4 x i64> %value, i64 %__zllvm_bitcast_memory_0) {
    \\entry:
    \\ %before = add i64 %__zllvm_bitcast_memory_0, 0
    \\ br label %work
    \\work:
    \\ %input = phi <4 x i64> [ %value, %entry ]
    \\ %bits = bitcast <4 x i64> %input to i256, !dbg !0
    \\ %later = add i256 %bits, 0
    \\ ret i256 %later
    \\}
    \\!0 = !{i32 9}
;

fn snapshot(a: std.mem.Allocator, module: ir.Module) ![]u8 {
    var output: std.Io.Writer.Allocating = .init(a);
    defer output.deinit();
    try module.print(&output.writer);
    return output.toOwnedSlice();
}

fn verifyPrivate(a: std.mem.Allocator, module: ir.Module, function: ir.Function) !void {
    var private = module;
    private.functions = try module.functions.clone(a);
    private.functions.items[0] = function;
    try private.verify();
}

fn allocationCase(a: std.mem.Allocator, module: ir.Module, pair: bool) !void {
    var arena = std.heap.ArenaAllocator.init(a);
    defer arena.deinit();
    const candidate = (if (pair)
        try floating.legalize(arena.allocator(), module.functions.items[0], null)
    else
        try bitcasts.legalize(arena.allocator(), module.functions.items[0], null)).?;
    try verifyPrivate(arena.allocator(), module, candidate);
}

test "rewrite builder consumers preserve complete source through all allocation failures" {
    const a = std.testing.allocator;
    for ([_]bool{ false, true }) |pair| {
        var module = try ir.Module.parse(a, if (pair) floating_source else bitcast_source);
        defer module.deinit();
        try module.verify();
        const before = try snapshot(a, module);
        defer a.free(before);
        var moving = std.testing.FailingAllocator.init(a, .{ .resize_fail_index = 0 });
        try std.testing.checkAllAllocationFailures(moving.allocator(), allocationCase, .{ module, pair });
        const after = try snapshot(a, module);
        defer a.free(after);
        try std.testing.expectEqualStrings(before, after);
        try module.verify();
    }
}

test "rewrite builder keeps snapshot SSA metadata PHIs and entry prefixes" {
    const a = std.testing.allocator;
    for ([_]bool{ false, true }) |pair| {
        var module = try ir.Module.parse(a, if (pair) floating_source else bitcast_source);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(a);
        defer arena.deinit();
        const original = module.functions.items[0];
        const rewritten = (if (pair)
            try floating.legalize(arena.allocator(), original, null)
        else
            try bitcasts.legalize(arena.allocator(), original, null)).?;
        try verifyPrivate(arena.allocator(), module, rewritten);
        try std.testing.expect(original.blocks.items.ptr != rewritten.blocks.items.ptr);
        try std.testing.expectEqual(original.params.items.ptr, rewritten.params.items.ptr);
        if (pair) {
            const instructions = rewritten.blocks.items[0].instructions.items;
            try std.testing.expectEqual(@as(usize, 7), instructions.len);
            try std.testing.expectEqualStrings("before", instructions[0].result.?);
            try std.testing.expectEqualStrings("__zllvm_fp_pair_load_1", instructions[1].result.?);
            try std.testing.expectEqualStrings("pair", instructions[5].result.?);
            try std.testing.expectEqualStrings(original.blocks.items[0].instructions.items[1].metadata.?, instructions[5].metadata.?);
            try std.testing.expect(instructions[6].kind == .store);
            try std.testing.expect((try floating.legalize(arena.allocator(), rewritten, null)) == null);
        } else {
            const entry = rewritten.blocks.items[0].instructions.items;
            const work = rewritten.blocks.items[1].instructions.items;
            try std.testing.expect(entry[0].kind == .alloca);
            try std.testing.expectEqualStrings("__zllvm_bitcast_memory_1", entry[0].result.?);
            try std.testing.expectEqualStrings("before", entry[1].result.?);
            try std.testing.expect(work[0].kind == .phi);
            try std.testing.expectEqual(original.blocks.items[1].instructions.items[0].kind.phi.incoming.items.ptr, work[0].kind.phi.incoming.items.ptr);
            try std.testing.expect(work[1].kind == .store);
            try std.testing.expect(work[2].kind == .load);
            try std.testing.expectEqualStrings("bits", work[2].result.?);
            try std.testing.expectEqualStrings(original.blocks.items[1].instructions.items[1].metadata.?, work[2].metadata.?);
            try std.testing.expectEqualStrings("later", work[3].result.?);
            try std.testing.expect((try bitcasts.legalize(arena.allocator(), rewritten, null)) == null);
        }
        try module.verify();
    }
}

test "rewrite builder unchanged attempts allocate no candidate arrays" {
    var module = try ir.Module.parse(std.testing.allocator, "define i32 @unchanged(i32 %x) {\nentry:\n ret i32 %x\n}\n");
    defer module.deinit();
    const source = module.functions.items[0];
    var builder = Builder.init(std.testing.failing_allocator, source, "unused_");
    defer builder.deinit();
    try std.testing.expect((try builder.finish()) == null);
    try std.testing.expect((try floating.legalize(std.testing.failing_allocator, source, null)) == null);
    try std.testing.expect((try bitcasts.legalize(std.testing.failing_allocator, source, null)) == null);
}
