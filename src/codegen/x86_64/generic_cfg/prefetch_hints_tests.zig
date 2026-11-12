const std = @import("std");
const ir = @import("../../../ir.zig");
const hints = @import("prefetch_hints.zig");
const compilation = @import("../../../compilation.zig");
const encoding = @import("../../../mc/encoding.zig");
const verify = @import("../verify.zig");
test "data prefetch hints keep memory and live operands without dereferencing addresses" {
    const a = std.testing.allocator;
    for (0..2) |rw| for (0..4) |locality| {
        const source = try std.fmt.allocPrint(
            a,
            "declare void @llvm.prefetch.p0(ptr,i32,i32,i32)\n" ++
                "define i64 @hint(ptr %address,ptr %out,i64 %value) {{\nentry:\n" ++
                " call void @llvm.prefetch.p0(ptr %address,i32 {d},i32 {d},i32 1)\n" ++
                " store i64 %value,ptr %out,align 1\n ret i64 %value\n}}\n",
            .{ rw, locality },
        );
        defer a.free(source);
        var module = try ir.Module.parse(a, source);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(a);
        defer arena.deinit();
        const original = module.functions.items[0];
        const revised = (try hints.legalize(arena.allocator(), original)).?;
        try std.testing.expect((try hints.legalize(arena.allocator(), revised)) == null);
        try std.testing.expect(original.blocks.items.ptr != revised.blocks.items.ptr);
        try std.testing.expectEqual(@as(usize, 2), original.blocks.items[0].instructions.items.len);
        try std.testing.expectEqual(@as(usize, 1), revised.blocks.items[0].instructions.items.len);
        try module.verify();
        var machine = try compilation.select(a, "x86_64-unknown-linux-gnu", original, .{ .generic_cfg_selector = true });
        defer machine.deinit(a);
        try verify.verifyFunction(machine);
        const code = try encoding.encodeFunction(a, machine);
        defer a.free(code);
        const mapping = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(mapping);
        @memcpy(mapping[0..code.len], code);
        const run: *const fn (?*const anyopaque, *u64, u64) callconv(.c) u64 = @ptrCast(mapping.ptr);
        for ([_]u64{ 0, 1, 0x8000000000000000, 0x123456789abcdef0, std.math.maxInt(u64) }) |value| {
            var out: u64 = 0;
            try std.testing.expectEqual(value, run(null, &out, value));
            try std.testing.expectEqual(value, out);
        }
    };
}

test "prefetch hints reject unproved signatures and envelopes without partial rewriting" {
    const a = std.testing.allocator;
    for ([_][]const u8{
        "ptr %address,i32 2,i32 3,i32 1",        "ptr %address,i32 0,i32 4,i32 1", "ptr %address,i32 0,i32 3,i32 0",
        "ptr %address,i32 %dynamic,i32 3,i32 1", "ptr %address,i64 0,i32 3,i32 1", "ptr %address,i32 0,i32 3",
    }) |arguments| {
        const source = try std.fmt.allocPrint(
            a,
            "define void @closed(ptr %address,i32 %dynamic) {{\nentry:\n" ++
                " call void @llvm.prefetch.p0(ptr %address,i32 0,i32 3,i32 1)\n" ++
                " call void @llvm.prefetch.p0({s})\n ret void\n}}\n",
            .{arguments},
        );
        defer a.free(source);
        var module = try ir.Module.parse(a, source);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(a);
        defer arena.deinit();
        try std.testing.expect((try hints.legalize(arena.allocator(), module.functions.items[0])) == null);
        try std.testing.expectEqual(@as(usize, 2), module.functions.items[0].blocks.items[0].instructions.items.len);
    }
}
