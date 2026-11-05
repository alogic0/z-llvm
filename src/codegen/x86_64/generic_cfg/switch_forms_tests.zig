const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const selector = @import("../generic_cfg_selector.zig");
const verify = @import("../verify.zig");
const encoding = @import("../../../mc/encoding.zig");
const forms = @import("switch_forms.zig");
const edges = @import("switch_phi_edges.zig");

fn append(text: *std.ArrayList(u8), comptime format: []const u8, args: anytype) !void {
    const part = try std.fmt.allocPrint(std.testing.allocator, format, args);
    defer std.testing.allocator.free(part);
    try text.appendSlice(std.testing.allocator, part);
}

fn executable(module: ir.Module) ![]align(std.heap.page_size_min) u8 {
    const function = module.functions.items[0];
    var output = machine.MachineFunction.init(function.name, function.ret_ty);
    defer output.deinit(std.testing.allocator);
    const selected = try selector.tryLower(std.testing.allocator, &output, function);
    if (selected == .unsupported) std.debug.print("switch forms {s}: {s}\n", .{ function.name, selected.unsupported.detail() });
    try std.testing.expectEqual(selector.SelectionResult.selected, selected);
    try verify.verifyFunction(output);
    const bytes = try encoding.encodeFunction(std.testing.allocator, output);
    defer std.testing.allocator.free(bytes);
    const code = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    @memcpy(code[0..bytes.len], bytes);
    return code;
}

test "switch forms execute large and wide case sets with exact input widths" {
    for ([_]u16{ 8, 32, 64 }) |bits| for ([_]usize{ 0, 1, 8, 9, 61, 127 }) |count| {
        var text: std.ArrayList(u8) = .empty;
        defer text.deinit(std.testing.allocator);
        const sign: u64 = @as(u64, 1) << @intCast(bits - 1);
        try append(&text, "define i64 @probe(i64 %input, i64 %salt) {{\nentry:\n", .{});
        if (bits < 64) try append(&text, "  %narrow = trunc i64 %input to i{d}\n", .{bits});
        try append(&text, "  switch i{d} %{s}, label %fallback [\n", .{ bits, if (bits < 64) "narrow" else "input" });
        for (0..count) |i| try append(&text, "    i{d} {d}, label %case{d}\n", .{ bits, sign + i, i });
        try append(&text, "  ]\nfallback:\n  %default = add i64 %salt, 999\n  ret i64 %default\n", .{});
        for (0..count) |i| try append(&text, "case{d}:\n  %result{d} = add i64 %salt, {d}\n  ret i64 %result{d}\n", .{ i, i, i, i });
        try append(&text, "}}\n", .{});
        var module = try ir.Module.parse(std.testing.allocator, text.items);
        defer module.deinit();
        try module.verify();
        const code = try executable(module);
        defer std.posix.munmap(code);
        const run: *const fn (u64, u64) callconv(.c) u64 = @ptrCast(code.ptr);
        const salt: u64 = 0x123456789abcdef0;
        for (0..count) |i| {
            try std.testing.expectEqual(salt + i, run(sign + i, salt));
            if (bits < 64) try std.testing.expectEqual(salt + i, run((sign + i) | (~@as(u64, 0) << @intCast(bits)), salt));
        }
        for ([_]u64{ 0, 1, sign - 1, sign + count }) |value| try std.testing.expectEqual(salt + 999, run(value, salt));
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        if (try forms.legalize(arena.allocator(), module.functions.items[0])) |view| {
            try std.testing.expect(try forms.legalize(arena.allocator(), view) == null);
            var private = module;
            private.functions = try module.functions.clone(arena.allocator());
            private.functions.items[0] = view;
            try private.verify();
        }
        try std.testing.expect(module.functions.items[0].blocks.items[0].terminator.? == .@"switch");
        try module.verify();
    };
}

test "switch forms retain duplicate PHI edges and private labels" {
    const text =
        \\define i64 @probe(i64 %__zllvm_scalar_form_0) {
        \\__zllvm_scalar_form_1:
        \\  switch i64 %__zllvm_scalar_form_0, label %merge [
        \\    i64 0, label %merge
        \\    i64 9223372036854775808, label %one
        \\    i64 18446744073709551615, label %merge
        \\  ]
        \\one:
        \\  %value = add i64 %__zllvm_scalar_form_0, 7
        \\  br label %merge
        \\merge:
        \\  %result = phi i64 [ 55, %__zllvm_scalar_form_1 ], [ 55, %__zllvm_scalar_form_1 ], [ 55, %__zllvm_scalar_form_1 ], [ %value, %one ]
        \\  ret i64 %result
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    try std.testing.expect(try forms.legalize(arena.allocator(), module.functions.items[0]) == null);
    const edge_view = (try edges.legalize(arena.allocator(), module.functions.items[0])).?;
    const view = (try forms.legalize(arena.allocator(), edge_view)).?;
    var private = module;
    private.functions = try module.functions.clone(arena.allocator());
    private.functions.items[0] = view;
    try private.verify();
    const code = try executable(module);
    defer std.posix.munmap(code);
    const run: *const fn (u64) callconv(.c) u64 = @ptrCast(code.ptr);
    for ([_]u64{ 0, 1, 0x8000000000000000, 0xffffffffffffffff }) |x|
        try std.testing.expectEqual(@as(u64, if (x == 0x8000000000000000) x + 7 else 55), run(x));
}

test "switch forms execute bounded large control flow" {
    for ([_]usize{ 129, 779, 1024 }) |count| {
        var text: std.ArrayList(u8) = .empty;
        defer text.deinit(std.testing.allocator);
        try append(&text, "define i64 @probe(i64 %input) {{\nb0:\n  br label %b1\n", .{});
        for (1..count) |index| {
            try append(&text, "b{d}:\n", .{index});
            if (index + 1 == count) try append(&text, "  %result = add i64 %input, 7\n  ret i64 %result\n", .{}) else try append(&text, "  br label %b{d}\n", .{index + 1});
        }
        try append(&text, "}}\n", .{});
        var module = try ir.Module.parse(std.testing.allocator, text.items);
        defer module.deinit();
        try module.verify();
        const code = try executable(module);
        defer std.posix.munmap(code);
        const run: *const fn (u64) callconv(.c) u64 = @ptrCast(code.ptr);
        for ([_]u64{ 0, 1, 0xffffffffffffffff, 0x8000000000000000 }) |x| try std.testing.expectEqual(x +% 7, run(x));
    }
}
