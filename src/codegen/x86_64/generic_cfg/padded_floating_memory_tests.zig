const std = @import("std");
const ir = @import("../../../ir.zig");
test "native floating vector stores survive owned byte frames with exact payloads" {
    const a = std.testing.allocator;
    const cases = [_]struct { ty: []const u8, value: []const u8, bytes: [16]u8 }{
        .{ .ty = "<4 x float>", .value = "<float 1.000000e+00,float -0.000000e+00,float 0x7FF8000020000000,float 0x7FF4000000000000>", .bytes = .{ 0, 0, 0x80, 0x3f, 0, 0, 0, 0x80, 1, 0, 0xc0, 0x7f, 0, 0, 0xa0, 0x7f } },
        .{ .ty = "<8 x half>", .value = "<half 0xH3C00,half 0xH8000,half 0xH7C00,half 0xHFC00,half 0xH7E01,half 0xH7D55,half 0xH0001,half 0xH03FF>", .bytes = .{ 0, 0x3c, 0, 0x80, 0, 0x7c, 0, 0xfc, 1, 0x7e, 0x55, 0x7d, 1, 0, 0xff, 3 } },
    };
    for (cases) |item| {
        const source = try std.fmt.allocPrint(a, "define void @probe(ptr %out) {{\nentry:\n %frame = alloca [64 x i8],align 16\n %local = getelementptr i8,ptr %frame,i64 16\n store {0s} {1s},ptr %local,align 16\n %loaded = load {0s},ptr %local,align 16\n store {0s} %loaded,ptr %out,align 1\n ret void\n}}\n", .{ item.ty, item.value });
        defer a.free(source);
        var module = try ir.Module.parse(a, source);
        defer module.deinit();
        try module.verify();
        var selected = try @import("../../../compilation.zig").select(a, "x86_64-unknown-linux-gnu", module.functions.items[0], .{ .generic_cfg_selector = true });
        defer selected.deinit(a);
        try @import("../verify.zig").verifyFunction(selected);
        const bytes = try @import("../../../mc/encoding.zig").encodeFunction(a, selected);
        defer a.free(bytes);
        const memory = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(memory);
        @memcpy(memory[0..bytes.len], bytes);
        const run: *const fn (*[16]u8) callconv(.c) void = @ptrCast(memory.ptr);
        var output: [16]u8 = @splat(0x69);
        run(&output);
        try std.testing.expectEqualSlices(u8, &item.bytes, &output);
        try std.testing.expect(module.functions.items[0].blocks.items[0].instructions.items[2].kind.store.ty == .vector);
        try module.verify();
    }
}
test "byte frames keep opaque quad carriers and volatile native vector stores outside the new trigger" {
    const a = std.testing.allocator;
    for ([_]struct { ty: []const u8, attrs: []const u8 }{ .{ .ty = "<2 x double>", .attrs = "" }, .{ .ty = "<4 x float>", .attrs = "volatile " } }) |item| {
        const source = try std.fmt.allocPrint(a, "define void @closed() {{\nentry:\n %frame = alloca [16 x i8],align 16\n store {s}{s} zeroinitializer,ptr %frame,align 16\n ret void\n}}\n", .{ item.attrs, item.ty });
        defer a.free(source);
        var module = try ir.Module.parse(a, source);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(a);
        defer arena.deinit();
        try std.testing.expect((try @import("floating_vectors.zig").legalize(arena.allocator(), module.functions.items[0], null)) == null);
    }
}
