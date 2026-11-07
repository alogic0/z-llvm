const std = @import("std");
const ir = @import("../ir.zig");
const parser = @import("../ir/parser_types_values.zig");
const layout = @import("../target/datalayout.zig");
const memory = @import("../analysis/memory_location.zig");
const globals = @import("../mc/global_data.zig");

test "packed structures parse as aggregates and preserve constants across serialization" {
    const source =
        \\%Empty = type <{}>
        \\@empty = global <{}> <{}>
        \\@array = global [2 x <{ i8, i32 }>] [<{ i8, i32 }> <{ i8 1, i32 287454020 }>, <{ i8, i32 }> zeroinitializer]
        \\define <{ i8, i32 }> @identity(<{ i8, i32 }> %value) {
        \\entry:
        \\  ret <{ i8, i32 }> %value
        \\}
        \\define <{ i8, i32 }> @literal() {
        \\entry:
        \\  ret <{ i8, i32 }> <{ i8 1, i32 2 }>
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    try module.verify();
    try std.testing.expect(module.functions.items[0].ret_ty == .aggregate);
    try std.testing.expect(module.functions.items[1].blocks.items[0].terminator.?.ret.value.? == .constant_expr);
    var output: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer output.deinit();
    try module.print(&output.writer);
    var reparsed = try ir.Module.parse(std.testing.allocator, output.written());
    defer reparsed.deinit();
    try reparsed.verify();
    for (reparsed.globals.items, 0..) |global, index| {
        var decoded = try globals.decode(std.testing.allocator, .{ .globals = &.{}, .named_types = &.{}, .target_datalayout = null }, global);
        defer decoded.deinit(std.testing.allocator);
        if (index == 0) try std.testing.expectEqual(@as(usize, 0), decoded.bytes.len) else try std.testing.expectEqualSlices(u8, &.{ 1, 0x44, 0x33, 0x22, 0x11, 0, 0, 0, 0, 0 }, decoded.bytes);
    }
    try std.testing.expect((try parser.parseType("<2 x i32>")) == .vector);
    try std.testing.expect((try parser.parseValue("<i32 1, i32 2>")) == .vector);
}

test "packed structures preserve allocation padding inside each member" {
    const dl = try layout.DataLayout.parse("e-p:64:64-i24:32-i64:64");
    for ([_]struct { text: []const u8, offset: i128, size: u64, alignment: u16 }{
        .{ .text = "<{ i8, i64 }>", .offset = 1, .size = 9, .alignment = 8 },
        .{ .text = "<{ i24, i8 }>", .offset = 4, .size = 5, .alignment = 8 },
        .{ .text = "<{ x86_fp80, i8 }>", .offset = 16, .size = 17, .alignment = 8 },
        .{ .text = "<{ { i8, i64 }, i8 }>", .offset = 16, .size = 17, .alignment = 8 },
        .{ .text = "{ <{ i8, i64 }>, i64 }", .offset = 16, .size = 24, .alignment = 64 },
        .{ .text = "[2 x <{ i8, i64 }>]", .offset = 9, .size = 18, .alignment = 8 },
    }) |case| {
        const ty = try parser.parseType(case.text);
        try std.testing.expectEqual(case.offset, try dl.aggregateFieldOffsetBytes(ty, 1));
        try std.testing.expectEqual(case.size, try dl.typeAllocSizeBytes(ty));
        try std.testing.expectEqual(case.alignment, try dl.typeAbiAlignmentBits(ty));
        try std.testing.expect(memory.aggregateFieldType(ty, 1) != null);
    }
    try std.testing.expectEqual(@as(u64, 0), try dl.typeAllocSizeBytes(try parser.parseType("<{}>")));
    try std.testing.expectEqual(@as(?i128, null), memory.aggregateFieldOffset(try parser.parseType("<{ i24, i8 }>"), 1));
    try std.testing.expectEqual(@as(?u64, null), memory.typeSize(try parser.parseType("<{ i24, i8 }>")));
}

test "packed structures retain the complete compiler's first rejected global" {
    const bytes = try std.Io.Dir.cwd().readFileAlloc(std.testing.io, "test/whole_compiler/packed_global.ll", std.testing.allocator, .limited(4096));
    defer std.testing.allocator.free(bytes);
    var module = try ir.Module.parse(std.testing.allocator, bytes);
    defer module.deinit();
    try module.verify();
    var decoded = try globals.decode(std.testing.allocator, .{ .globals = &.{}, .named_types = &.{}, .target_datalayout = null }, module.globals.items[0]);
    defer decoded.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 14), decoded.bytes.len);
    try std.testing.expectEqual(@as(u8, 15), decoded.bytes[3]);
    try std.testing.expectEqual(@as(u8, 15), decoded.bytes[7]);
    try std.testing.expectEqual(@as(u8, 0), decoded.bytes[11]);
    try std.testing.expectEqual(@as(u32, 2), decoded.alignment);
}

test "packed structures reject incomplete constants and layout overflow" {
    for ([_][]const u8{
        "@bad = global <{ i8, i64 }> { i8 1, i64 2 }",
        "@bad = global <{ i8, i64 }> <{ i8 1 }>",
        "@bad = global <{ i8 }> <{ i16 1 }>",
        "@bad = global <{ i8 }> <{ i8 1, }>",
        "@bad = global <{ i8, }> <{ i8 1 }>",
    }) |source| {
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        try std.testing.expectError(error.UnsupportedGlobalData, globals.decode(std.testing.allocator, .{ .globals = &.{}, .named_types = &.{}, .target_datalayout = null }, module.globals.items[0]));
    }
    const dl = try layout.DataLayout.parse("");
    try std.testing.expectError(error.UnsupportedDataLayoutQuery, dl.typeAllocSizeBytes(.{ .aggregate = "<{ [18446744073709551615 x i8], i8 }>" }));
    try std.testing.expectError(error.UnsupportedType, parser.parseType("<{ i8 }"));
}
