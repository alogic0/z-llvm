const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const selector = @import("../generic_cfg_selector.zig");
const encoding = @import("../../../mc/encoding.zig");
const order = @import("block_order.zig");
const addresses = @import("address_forms.zig");

fn executable(module: ir.Module) ![]align(std.heap.page_size_min) u8 {
    const function = module.functions.items[0];
    var output = machine.MachineFunction.init(function.name, function.ret_ty);
    defer output.deinit(std.testing.allocator);
    const context: machine.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout };
    const selected = try selector.tryLowerWithContext(std.testing.allocator, &output, function, &context);
    if (selected == .unsupported) std.debug.print("address flow {s}: {s}\n", .{ function.name, selected.unsupported.detail() });
    try std.testing.expectEqual(selector.SelectionResult.selected, selected);
    const code = try encoding.encodeFunction(std.testing.allocator, output);
    defer std.testing.allocator.free(code);
    const memory = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    @memcpy(memory[0..code.len], code);
    return memory;
}

test "address flow named struct fields use complete padded and packed layouts" {
    for ([_][]const u8{ "{ i8, i64, i32 }", "<{ i8, i64, i32 }>" }, [_]u64{ 16, 9 }) |body, offset| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "%Record = type {s}\ndefine i64 @field(ptr %p) {{\nentry:\n %q = getelementptr %Record, ptr %p, i32 0, i32 2\n %bits = ptrtoint ptr %q to i64\n ret i64 %bits\n}}\n", .{body});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const memory = try executable(module);
        defer std.posix.munmap(memory);
        const run: *const fn (u64) callconv(.c) u64 = @ptrCast(memory.ptr);
        for ([_]u64{ 0, 1000, std.math.maxInt(u64) - 3 }) |base| try std.testing.expectEqual(base +% offset, run(base));
        const storage = @import("storage_layout.zig");
        const context: machine.ReadOnlyModuleContext = .{ .globals = &.{}, .named_types = module.named_types.items, .target_datalayout = null };
        try std.testing.expectEqual(@as(?u32, @intCast(offset)), storage.fieldOffset(&context, .{ .aggregate = "%Record" }, 2));
        try std.testing.expect(storage.fieldOffset(&context, .{ .aggregate = "%Record" }, 3) == null);
        try std.testing.expect(storage.fieldOffset(&context, .{ .aggregate = "%Missing" }, 0) == null);
        try std.testing.expect(storage.fieldOffset(&context, .{ .aggregate = "{ i8, %Missing }" }, 0) == null);
    }
}

test "address flow array elements preserve padded vector strides and wrapping indices" {
    const Case = struct { ty: []const u8, stride: u64 };
    for ([_]Case{ .{ .ty = "<3 x i64>", .stride = 32 }, .{ .ty = "<17 x i32>", .stride = 128 }, .{ .ty = "<64 x double>", .stride = 512 }, .{ .ty = "{ i8, i64 }", .stride = 16 } }) |case| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "define i64 @element(ptr %p,i64 %index) {{\nentry:\n %q = getelementptr [3 x {s}],ptr %p,i64 0,i64 %index\n %bits = ptrtoint ptr %q to i64\n ret i64 %bits\n}}\n", .{case.ty});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const code = try executable(module);
        defer std.posix.munmap(code);
        const run: *const fn (u64, u64) callconv(.c) u64 = @ptrCast(code.ptr);
        for ([_]u64{ 0, 1, std.math.maxInt(u64) - 3 }) |base| for ([_]u64{ 0, 1, 2, 0x8000000000000000, std.math.maxInt(u64) }) |index|
            try std.testing.expectEqual(base +% index *% case.stride, run(base, index));
        try module.verify();
        try std.testing.expect(module.functions.items[0].blocks.items[0].instructions.items[0].kind.gep.source_ty == .aggregate);
    }
}

test "packed structures compose runtime strides and nested member offsets" {
    for ([_][]const u8{ "<{ i8, { i8, i64 }, i16 }>", "{ i8, { i8, i64 }, i16 }" }, [_]u64{ 19, 32 }, [_]u64{ 9, 16 }) |body, stride, offset| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "define i64 @field(ptr %p, i64 %index) {{\nentry:\n %q = getelementptr {s}, ptr %p, i64 %index, i32 1, i32 1\n %bits = ptrtoint ptr %q to i64\n ret i64 %bits\n}}\n", .{body});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const code = try executable(module);
        defer std.posix.munmap(code);
        const run: *const fn (u64, u64) callconv(.c) u64 = @ptrCast(code.ptr);
        for ([_]u64{ 0, 1000, std.math.maxInt(u64) - 3 }) |base| {
            for ([_]u64{ 0, 1, 3, 0x8000000000000000, std.math.maxInt(u64) }) |index|
                try std.testing.expectEqual(base +% index *% stride +% offset, run(base, index));
        }
        try module.verify();
        try std.testing.expectEqual(@as(usize, 2), module.functions.items[0].blocks.items[0].instructions.items.len);
    }
}

test "packed structures keep unresolved and invalid member addressing unsupported" {
    for ([_][]const u8{
        "getelementptr <{}>, ptr %p, i64 %index, i32 0",
        "getelementptr <{ i8, %Missing }>, ptr %p, i64 %index, i32 0",
        "getelementptr <{ i8, i64 }>, ptr %p, i64 %index, i32 -1",
        "getelementptr <{ i8, i64 }>, ptr %p, i64 %index, i32 2",
        "getelementptr <{ i8, i64 }>, ptr %p, i64 %index, i64 1",
    }) |gep| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "define ptr @field(ptr %p, i64 %index) {{\nentry:\n %q = {s}\n ret ptr %q\n}}\n", .{gep});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect(try addresses.legalize(arena.allocator(), module.functions.items[0], null) == null);
    }
}

test "address flow schedules late dominators and retains every unreachable block" {
    const text =
        \\define i64 @f(i64 %a, i64 %b) {
        \\entry:
        \\  br label %define
        \\use:
        \\  %r = add i64 %late, %a
        \\  ret i64 %r
        \\dead:
        \\  ret i64 123
        \\define:
        \\  %late = mul i64 %b, 3
        \\  br label %use
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const view = (try order.legalize(arena.allocator(), module.functions.items[0])).?;
    try std.testing.expectEqual(@as(usize, 4), view.blocks.items.len);
    for (view.blocks.items, [_][]const u8{ "entry", "define", "use", "dead" }) |block, expected|
        try std.testing.expectEqualStrings(expected, block.name);
    try std.testing.expect(try order.legalize(arena.allocator(), view) == null);
    try std.testing.expectEqualStrings("use", module.functions.items[0].blocks.items[1].name);
    const memory = try executable(module);
    defer std.posix.munmap(memory);
    const run: *const fn (u64, u64) callconv(.c) u64 = @ptrCast(memory.ptr);
    for ([_]u64{ 0, 1, 255, 0x8000000000000000, std.math.maxInt(u64) }) |a| {
        for ([_]u64{ 0, 2, 0xdeadbeef12345678, std.math.maxInt(u64) }) |b|
            try std.testing.expectEqual(a +% b *% 3, run(a, b));
    }
    try module.verify();
}

test "address flow byte offsets preserve exact scalar aggregate and large strides" {
    const Case = struct { spelling: []const u8, size: u64 };
    for ([_]Case{ .{ .spelling = "i32", .size = 4 }, .{ .spelling = "i64", .size = 8 }, .{ .spelling = "[0 x i8]", .size = 0 }, .{ .spelling = "[257 x i8]", .size = 257 }, .{ .spelling = "{ i8, i64 }", .size = 16 } }) |case| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "define i64 @f(ptr %p, i64 %index) {{\nentry:\n  %q = getelementptr {s}, ptr %p, i64 %index\n  %bits = ptrtoint ptr %q to i64\n  ret i64 %bits\n}}\n", .{case.spelling});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const view = (try addresses.legalize(arena.allocator(), module.functions.items[0], null)).?;
        try std.testing.expect(try addresses.legalize(arena.allocator(), view, null) == null);
        const memory = try executable(module);
        defer std.posix.munmap(memory);
        const run: *const fn (u64, u64) callconv(.c) u64 = @ptrCast(memory.ptr);
        for ([_]u64{ 0, 1, 3, 0x8000000000000000, std.math.maxInt(u64) }) |index|
            try std.testing.expectEqual(@as(u64, 4096) +% index *% case.size, run(4096, index));
        try module.verify();
    }
}

test "address flow materializes scalar frame pointers for bounded memory intrinsics" {
    for ([_]u16{ 8, 16, 32, 64 }) |bits| {
        const text = try std.fmt.allocPrint(std.testing.allocator,
            \\declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)
            \\define i64 @f(ptr %p) {{
            \\entry:
            \\  %slot = alloca i{d}, align 8
            \\  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %slot, ptr align 1 %p, i64 {d}, i1 false)
            \\  %loaded = load i{d}, ptr %slot, align 8
            \\{s}
            \\  ret i64 {s}
            \\}}
        , .{ bits, bits / 8, bits, if (bits == 64) "" else switch (bits) {
            8 => "  %extended = zext i8 %loaded to i64",
            16 => "  %extended = zext i16 %loaded to i64",
            32 => "  %extended = zext i32 %loaded to i64",
            else => unreachable,
        }, if (bits == 64) "%loaded" else "%extended" });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const memory = try executable(module);
        defer std.posix.munmap(memory);
        const run: *const fn (*const u64) callconv(.c) u64 = @ptrCast(memory.ptr);
        for ([_]u64{ 0, 1, 0xdeadbeef01234567, std.math.maxInt(u64) }) |input| {
            const mask = if (bits == 64) std.math.maxInt(u64) else (@as(u64, 1) << @as(u6, @intCast(bits))) - 1;
            try std.testing.expectEqual(input & mask, run(&input));
        }
    }
}

test "address flow byte-array elements retain signed offsets and checked layout" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\define i64 @f(ptr %p, i64 %index) {
        \\entry:
        \\ %q = getelementptr [4 x i8], ptr %p, i64 0, i64 %index
        \\ %bits = ptrtoint ptr %q to i64
        \\ ret i64 %bits
        \\}
    );
    defer module.deinit();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const view = (try addresses.legalize(arena.allocator(), module.functions.items[0], null)).?;
    try std.testing.expect(try addresses.legalize(arena.allocator(), view, null) == null);
    try std.testing.expectEqual(@as(usize, 2), module.functions.items[0].blocks.items[0].instructions.items[0].kind.gep.indices.items.len);
    const memory = try executable(module);
    defer std.posix.munmap(memory);
    const run: *const fn (u64, u64) callconv(.c) u64 = @ptrCast(memory.ptr);
    for ([_]u64{ 0, 1, 3, 255, 0x8000000000000000, std.math.maxInt(u64) }) |index|
        try std.testing.expectEqual(@as(u64, 4096) +% index, run(4096, index));
    for ([_][]const u8{ "E-p:64:64", "e-p:32:32", "e-ni:0", "e-i8:16:16" }) |layout| {
        const context: machine.ReadOnlyModuleContext = .{ .globals = &.{}, .named_types = &.{}, .target_datalayout = layout };
        try std.testing.expect(try addresses.legalize(arena.allocator(), module.functions.items[0], &context) == null);
    }
    module.functions.items[0].blocks.items[0].instructions.items[0].kind.gep.indices.items[0].value = .{ .int = 1 };
    try std.testing.expect(try addresses.legalize(arena.allocator(), module.functions.items[0], null) == null);
}

test "address flow rejects nonintegral narrow big endian and unproved pointee layouts" {
    const text = "define ptr @f(ptr %p, i64 %i) {\nentry:\n  %q = getelementptr i64, ptr %p, i64 %i\n  ret ptr %q\n}\n";
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    for ([_][]const u8{ "E-p:64:64", "e-p:32:32", "e-ni:0", "e-p:64:64:64:32" }) |layout| {
        const context: machine.ReadOnlyModuleContext = .{ .globals = &.{}, .named_types = &.{}, .target_datalayout = layout };
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect(try addresses.legalize(arena.allocator(), module.functions.items[0], &context) == null);
    }
    module.functions.items[0].blocks.items[0].instructions.items[0].kind.gep.source_ty = .{ .aggregate = "%unknown" };
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    try std.testing.expect(try addresses.legalize(arena.allocator(), module.functions.items[0], null) == null);
}

test "address flow keeps scalar frame memory extents bounded when a load also uses the slot" {
    const frames = @import("stack_addresses.zig");
    for ([_][]const u8{ "1", "8", "9", "-1", "%length" }, 0..) |length, index| {
        const text = try std.fmt.allocPrint(std.testing.allocator,
            \\declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)
            \\define i64 @f(ptr %p, i64 %length) {{
            \\entry:
            \\  %slot = alloca i64, align 8
            \\  call void @llvm.memcpy.p0.p0.i64(ptr %slot, ptr %p, i64 {s}, i1 false)
            \\  %loaded = load i64, ptr %slot, align 8
            \\  ret i64 %loaded
            \\}}
        , .{length});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expectEqual(index < 2, try frames.legalize(arena.allocator(), module.functions.items[0], null) != null);
        try module.verify();
    }
}
