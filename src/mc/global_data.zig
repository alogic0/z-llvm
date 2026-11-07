//! Bounded default-address-space global objects and symbolic pointer fields.
const std = @import("std");
const ir = @import("../ir.zig");
const parser = @import("../ir/parser_helpers.zig");
const target = @import("../target.zig");
const constants = @import("../codegen/x86_64/constant_table.zig");
const addresses = @import("../codegen/x86_64/symbol_address.zig");

pub const max_object_bytes = 1024 * 1024;
pub const Relocation = struct { offset: u32, address: addresses.Address, block: ?[]const u8 = null };
pub const Decoded = struct {
    bytes: []u8,
    relocations: []Relocation,
    alignment: u32,
    local: bool,
    visibility: u8,

    pub fn deinit(value: *Decoded, allocator: std.mem.Allocator) void {
        allocator.free(value.relocations);
        allocator.free(value.bytes);
    }
};

const Layout = struct { size: u32, alignment: u32 };
const Array = struct { count: u32, element: ir.Type };
const Fields = @import("../ir/structure.zig").Fields;

fn trim(text: []const u8) []const u8 {
    return std.mem.trim(u8, text, " \t");
}

fn bounded(size: u64) !u32 {
    if (size > max_object_bytes) return error.UnsupportedGlobalData;
    return @intCast(size);
}

fn aligned(size: u32, alignment: u32) !u32 {
    return bounded(std.mem.alignForward(u64, size, alignment));
}

fn dataType(text: []const u8) !ir.Type {
    return parser.parseType(trim(text)) catch error.UnsupportedGlobalData;
}

fn typedField(text: []const u8) !struct { ty: ir.Type, after: []const u8 } {
    const input = trim(text);
    const parsed = parser.parseLeadingType(input) catch return error.UnsupportedGlobalData;
    return .{ .ty = parsed.ty, .after = parsed.after };
}

fn arrayType(ty: ir.Type) !Array {
    if (ty != .aggregate) return error.UnsupportedGlobalData;
    const text = trim(ty.aggregate);
    if (text.len < 5 or text[0] != '[' or text[text.len - 1] != ']') return error.UnsupportedGlobalData;
    const body = trim(text[1 .. text.len - 1]);
    const separator = std.mem.indexOf(u8, body, " x ") orelse return error.UnsupportedGlobalData;
    const count = std.fmt.parseUnsigned(u32, trim(body[0..separator]), 10) catch return error.UnsupportedGlobalData;
    if (count > max_object_bytes) return error.UnsupportedGlobalData;
    return .{ .count = count, .element = try dataType(body[separator + 3 ..]) };
}

fn fields(text: []const u8) !Fields {
    return Fields.init(text) orelse error.UnsupportedGlobalData;
}

const Encoder = struct {
    allocator: std.mem.Allocator,
    context: constants.ReadOnlyModuleContext,
    layout: target.DataLayout,
    aggregate_alignment: u32 = 1,
    bytes: []u8,
    relocations: std.ArrayList(Relocation) = .empty,

    fn resolved(encoder: *const Encoder, ty: ir.Type, depth: u8) anyerror!ir.Type {
        if (depth >= 32) return error.UnsupportedGlobalData;
        if (ty == .aggregate and std.mem.startsWith(u8, trim(ty.aggregate), "%")) {
            const name = trim(ty.aggregate)[1..];
            for (encoder.context.named_types) |named| if (std.mem.eql(u8, named.name, name))
                return encoder.resolved(.{ .aggregate = named.body }, depth + 1);
            return error.UnsupportedGlobalData;
        }
        return ty;
    }

    fn typeLayout(encoder: *const Encoder, ty: ir.Type, depth: u8) anyerror!Layout {
        if (depth >= 32) return error.UnsupportedGlobalData;
        if (ty == .aggregate and std.mem.startsWith(u8, trim(ty.aggregate), "%")) {
            const name = trim(ty.aggregate)[1..];
            for (encoder.context.named_types) |named| if (std.mem.eql(u8, named.name, name))
                return encoder.typeLayout(.{ .aggregate = named.body }, depth + 1);
            return error.UnsupportedGlobalData;
        }
        if (ty == .int or ty == .ptr) {
            const bits: u16 = if (ty == .ptr) 64 else ty.int;
            if (bits != 1 and bits != 8 and bits != 16 and bits != 32 and bits != 64 and bits != 128) return error.UnsupportedGlobalData;
            const alignment_bits = encoder.layout.typeAbiAlignmentBits(ty) catch return error.UnsupportedGlobalData;
            // Only the native scalar allocation envelope is admitted here.
            if (alignment_bits != @max(@as(u16, 8), bits)) return error.UnsupportedGlobalData;
            const alignment: u32 = alignment_bits / 8;
            if (alignment > 4096 or !std.math.isPowerOfTwo(alignment)) return error.UnsupportedGlobalData;
            return .{ .size = try aligned((@as(u32, bits) + 7) / 8, alignment), .alignment = alignment };
        }
        if (ty != .aggregate) return error.UnsupportedGlobalData;
        if (std.mem.startsWith(u8, trim(ty.aggregate), "[")) {
            const array = try arrayType(ty);
            const element = try encoder.typeLayout(array.element, depth + 1);
            return .{ .size = try bounded(@as(u64, element.size) * array.count), .alignment = element.alignment };
        }
        var items = try fields(ty.aggregate);
        var size: u32 = 0;
        var alignment: u32 = if (items.packed_type) 1 else encoder.aggregate_alignment;
        while (items.next()) |field| {
            const layout = try encoder.typeLayout(try dataType(field), depth + 1);
            size = try bounded(@as(u64, if (items.packed_type) size else try aligned(size, layout.alignment)) + layout.size);
            if (!items.packed_type) alignment = @max(alignment, layout.alignment);
        }
        return .{ .size = try aligned(size, alignment), .alignment = alignment };
    }

    fn value(encoder: *Encoder, ty: ir.Type, input: ir.Value, offset: u32) !void {
        if (input == .zero_initializer or input == .undef) return;
        if (ty == .ptr) {
            if (input == .constant_expr) {
                const expression = trim(input.constant_expr);
                if (std.mem.startsWith(u8, expression, "blockaddress(")) {
                    var names: @import("../ir/opaque_names.zig").Iterator = .{ .raw = expression };
                    const token = (try names.next()) orelse return error.UnsupportedGlobalData;
                    if (token != .block_address or names.index != expression.len) return error.UnsupportedGlobalData;
                    const address = token.block_address;
                    const symbol = encoder.context.functionAddress(address.function) orelse return error.UnsupportedGlobalData;
                    try encoder.relocations.append(encoder.allocator, .{ .offset = offset, .address = .{ .symbol = symbol }, .block = address.block });
                    return;
                }
            }
            if (addresses.fromValue(input)) |address| {
                try encoder.relocations.append(encoder.allocator, .{ .offset = offset, .address = address });
                return;
            }
            const bits = addresses.pointerBits(input) orelse return error.UnsupportedGlobalData;
            std.mem.writeInt(u64, encoder.bytes[offset..][0..8], bits, .little);
            return;
        }
        if (ty != .int or input != .int) return error.UnsupportedGlobalData;
        const bits = ty.int;
        var pattern: u128 = @bitCast(input.int);
        if (bits < 128) {
            const mask = (@as(u128, 1) << @intCast(bits)) - 1;
            const minimum = -(@as(i128, 1) << @intCast(bits - 1));
            if (input.int < minimum or (input.int >= 0 and @as(u128, @intCast(input.int)) > mask)) return error.UnsupportedGlobalData;
            pattern &= mask;
        }
        for (0..(@as(usize, bits) + 7) / 8) |index|
            encoder.bytes[offset + index] = @truncate(pattern >> @intCast(index * 8));
    }

    fn text(encoder: *Encoder, ty: ir.Type, raw: []const u8, offset: u32, depth: u8) anyerror!void {
        if (depth >= 32) return error.UnsupportedGlobalData;
        const input = trim(raw);
        if (std.mem.eql(u8, input, "zeroinitializer") or std.mem.eql(u8, input, "undef")) return;
        const actual = try encoder.resolved(ty, depth);
        if (actual == .ptr and std.mem.startsWith(u8, input, "blockaddress("))
            return encoder.value(actual, .{ .constant_expr = input }, offset);
        if (actual == .int or actual == .ptr) return encoder.value(actual, parser.parseValue(input) catch return error.UnsupportedGlobalData, offset);
        if (actual != .aggregate) return error.UnsupportedGlobalData;
        if (std.mem.startsWith(u8, trim(actual.aggregate), "[")) {
            const array = try arrayType(actual);
            const element = try encoder.typeLayout(array.element, depth + 1);
            if (std.mem.startsWith(u8, input, "c\"") and std.mem.endsWith(u8, input, "\"")) {
                if (!array.element.eql(.{ .int = 8 })) return error.UnsupportedGlobalData;
                var cursor: usize = 2;
                var written: u32 = 0;
                while (cursor < input.len - 1) {
                    if (written >= array.count) return error.UnsupportedGlobalData;
                    const byte = if (input[cursor] == '\\') blk: {
                        if (cursor + 2 >= input.len - 1) return error.UnsupportedGlobalData;
                        const parsed = std.fmt.parseUnsigned(u8, input[cursor + 1 ..][0..2], 16) catch return error.UnsupportedGlobalData;
                        cursor += 3;
                        break :blk parsed;
                    } else blk: {
                        const byte = input[cursor];
                        if (byte == '"') return error.UnsupportedGlobalData;
                        cursor += 1;
                        break :blk byte;
                    };
                    encoder.bytes[offset + written] = byte;
                    written += 1;
                }
                if (written != array.count) return error.UnsupportedGlobalData;
                return;
            }
            if (input.len < 2 or input[0] != '[' or input[input.len - 1] != ']') return error.UnsupportedGlobalData;
            var values: Fields = .{ .rest = input[1 .. input.len - 1], .packed_type = false };
            for (0..array.count) |index| {
                const field = try typedField(values.next() orelse return error.UnsupportedGlobalData);
                if (!field.ty.eql(array.element)) return error.UnsupportedGlobalData;
                try encoder.text(array.element, field.after, offset + @as(u32, @intCast(index)) * element.size, depth + 1);
            }
            if (values.next() != null) return error.UnsupportedGlobalData;
            return;
        }
        var types = try fields(actual.aggregate);
        var values = try fields(input);
        if (types.packed_type != values.packed_type) return error.UnsupportedGlobalData;
        var position: u32 = 0;
        while (types.next()) |field_text| {
            const field_ty = try dataType(field_text);
            const layout = try encoder.typeLayout(field_ty, depth + 1);
            const field = try typedField(values.next() orelse return error.UnsupportedGlobalData);
            if (!field.ty.eql(field_ty)) return error.UnsupportedGlobalData;
            if (!types.packed_type) position = try aligned(position, layout.alignment);
            try encoder.text(field_ty, field.after, offset + position, depth + 1);
            position += layout.size;
        }
        if (values.next() != null) return error.UnsupportedGlobalData;
    }
};

pub fn decode(allocator: std.mem.Allocator, context: constants.ReadOnlyModuleContext, global: ir.Global) !Decoded {
    if (!addresses.supportsLayout(context.target_datalayout) or global.initializer == .none) return error.UnsupportedGlobalData;
    const properties = addresses.globalProperties(global) catch return error.UnsupportedGlobalData;
    var encoder: Encoder = .{ .allocator = allocator, .context = context, .layout = try target.DataLayout.parse(context.target_datalayout orelse ""), .bytes = &.{} };
    var layout_parts = std.mem.splitScalar(u8, context.target_datalayout orelse "", '-');
    while (layout_parts.next()) |part| if (std.mem.startsWith(u8, part, "a:")) {
        var values = std.mem.splitScalar(u8, part[2..], ':');
        const bits = std.fmt.parseUnsigned(u16, values.next() orelse return error.UnsupportedGlobalData, 10) catch return error.UnsupportedGlobalData;
        if (bits != 0) {
            if (bits % 8 != 0 or !std.math.isPowerOfTwo(bits)) return error.UnsupportedGlobalData;
            encoder.aggregate_alignment = bits / 8;
        }
    };
    const layout = try encoder.typeLayout(global.ty, 0);
    encoder.bytes = try allocator.alloc(u8, layout.size);
    errdefer allocator.free(encoder.bytes);
    @memset(encoder.bytes, 0);
    errdefer encoder.relocations.deinit(allocator);
    switch (global.initializer) {
        .scalar => |value| if (value == .constant_expr and global.ty == .aggregate)
            try encoder.text(global.ty, value.constant_expr, 0, 0)
        else
            try encoder.value(global.ty, value, 0),
        .array => |array| {
            const actual = try arrayType(try encoder.resolved(global.ty, 0));
            if (!actual.element.eql(array.elem_ty) or actual.count != array.values.items.len) return error.UnsupportedGlobalData;
            const element = try encoder.typeLayout(actual.element, 1);
            for (array.values.items, 0..) |value, index| try encoder.value(actual.element, value, @as(u32, @intCast(index)) * element.size);
        },
        .@"opaque", .c_string => |text| try encoder.text(global.ty, text, 0, 0),
        .none => unreachable,
    }
    return .{ .bytes = encoder.bytes, .relocations = try encoder.relocations.toOwnedSlice(allocator), .alignment = properties.alignment orelse layout.alignment, .local = properties.local, .visibility = properties.visibility };
}

test "global data lays out named nested arrays and symbolic pointer fields" {
    const source =
        \\target datalayout = "e-p:64:64-i64:64-i128:128"
        \\%"pair.type" = type { ptr, i16 }
        \\%Container = type { i8, [2 x %"pair.type"], i32 }
        \\@object = internal global %Container { i8 255, [2 x %"pair.type"] [%"pair.type" { ptr null, i16 -1 }, %"pair.type" { ptr getelementptr (i8, ptr @other, i64 888), i16 123 }], i32 4294967295 }, align 1
    ;
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    var data = try decode(std.testing.allocator, .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout }, module.globals.items[0]);
    defer data.deinit(std.testing.allocator);
    var expected: [48]u8 = @splat(0);
    expected[0] = 255;
    std.mem.writeInt(u16, expected[16..18], 65535, .little);
    std.mem.writeInt(u16, expected[32..34], 123, .little);
    std.mem.writeInt(u32, expected[40..44], 4294967295, .little);
    try std.testing.expectEqualSlices(u8, &expected, data.bytes);
    try std.testing.expectEqual(@as(u32, 1), data.alignment);
    try std.testing.expect(data.local);
    try std.testing.expectEqual(@as(usize, 1), data.relocations.len);
    try std.testing.expectEqual(@as(u32, 24), data.relocations[0].offset);
    try std.testing.expectEqualStrings("other", data.relocations[0].address.symbol);
    try std.testing.expectEqual(@as(i32, 888), data.relocations[0].address.addend);
}

test "global data preserves full integer and numeric pointer bits" {
    const source =
        \\target datalayout = "e-p:64:64-i64:64-i128:128"
        \\@wide = global i128 -1, align 16
        \\@pointer = global ptr inttoptr (i64 18446744073709551615 to ptr), align 8
        \\@function = private constant ptr @callee, align 8
        \\@empty = global [0 x ptr] zeroinitializer
    ;
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    const ctx: constants.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout };
    for (module.globals.items, 0..) |global, index| {
        var data = try decode(std.testing.allocator, ctx, global);
        defer data.deinit(std.testing.allocator);
        if (index < 2) {
            try std.testing.expectEqual(@as(usize, if (index == 0) 16 else 8), data.bytes.len);
            for (data.bytes) |byte| try std.testing.expectEqual(@as(u8, 255), byte);
            try std.testing.expectEqual(@as(usize, 0), data.relocations.len);
        } else if (index == 2) {
            try std.testing.expectEqual(@as(usize, 1), data.relocations.len);
            try std.testing.expectEqualStrings("callee", data.relocations[0].address.symbol);
            try std.testing.expect(data.local);
        } else try std.testing.expectEqual(@as(usize, 0), data.bytes.len);
    }
}

test "global data decodes escaped byte strings and aggregate zero fill" {
    const source =
        \\target datalayout = "e-p:64:64-i64:64"
        \\@string = private constant [4 x i8] c"A\00\5c\ff", align 8
        \\@zeros = global { i8, [3 x ptr], i16 } zeroinitializer
    ;
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    const ctx: constants.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout };
    var string = try decode(std.testing.allocator, ctx, module.globals.items[0]);
    defer string.deinit(std.testing.allocator);
    try std.testing.expectEqualSlices(u8, &.{ 65, 0, 92, 255 }, string.bytes);
    var zeros = try decode(std.testing.allocator, ctx, module.globals.items[1]);
    defer zeros.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 40), zeros.bytes.len);
    for (zeros.bytes) |byte| try std.testing.expectEqual(@as(u8, 0), byte);
}

test "global data rejects incomplete unsupported and unbounded definitions" {
    for ([_][]const u8{
        "@bad = global i8 256",
        "@bad = global ptr poison",
        "@bad = global ptr inttoptr (i32 1 to ptr)",
        "@bad = global [2 x i8] c\"A\"",
        "@bad = global [2 x i8] [i8 1]",
        "@bad = global { i8, i64 } { i8 1 }",
        "@bad = global { i8 } { i16 1 }",
        "@bad = global double 0.0",
        "@bad = global [1048577 x i8] zeroinitializer",
        "%Recursive = type { %Recursive }\n@bad = global %Recursive zeroinitializer",
        "@bad = external global i64",
        "@bad = thread_local global i64 0",
        "@bad = weak global i64 0",
        "@bad = global i64 0, section \"custom\"",
        "target datalayout = \"e-p:32:32\"\n@bad = global ptr null",
        "target datalayout = \"e-p:64:64-i8:64\"\n@bad = global [2 x i8] c\"AB\"",
    }) |source| {
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        try std.testing.expectError(error.UnsupportedGlobalData, decode(std.testing.allocator, .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout }, module.globals.items[0]));
    }
}

test "global data preserves nested packed field offsets and unaligned relocations" {
    const source =
        \\target datalayout = "e-p:64:64-i64:64-a:64"
        \\%Packed = type <{ i8, ptr, i16 }>
        \\@packed = global { i8, [2 x %Packed], i64 } { i8 127, [2 x %Packed] [%Packed <{ i8 1, ptr @first, i16 4660 }>, %Packed <{ i8 2, ptr @second, i16 -1 }>], i64 72623859790382856 }
        \\@inline = global { i8, <{ i8, i64 }>, i16 } { i8 9, <{ i8, i64 }> <{ i8 10, i64 123 }>, i16 17 }
    ;
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    const ctx: constants.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout };
    var data = try decode(std.testing.allocator, ctx, module.globals.items[0]);
    defer data.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 32), data.bytes.len);
    try std.testing.expectEqualSlices(u8, &.{ 127, 1 }, data.bytes[0..2]);
    try std.testing.expectEqualSlices(u8, &.{ 0x34, 0x12, 2 }, data.bytes[10..13]);
    try std.testing.expectEqualSlices(u8, &.{ 255, 255, 0 }, data.bytes[21..24]);
    try std.testing.expectEqual(@as(u64, 72623859790382856), std.mem.readInt(u64, data.bytes[24..32], .little));
    try std.testing.expectEqual(@as(u32, 8), data.alignment);
    try std.testing.expectEqual(@as(usize, 2), data.relocations.len);
    try std.testing.expectEqual(@as(u32, 2), data.relocations[0].offset);
    try std.testing.expectEqual(@as(u32, 13), data.relocations[1].offset);
    try std.testing.expectEqualStrings("first", data.relocations[0].address.symbol);
    try std.testing.expectEqualStrings("second", data.relocations[1].address.symbol);
    var inline_data = try decode(std.testing.allocator, ctx, module.globals.items[1]);
    defer inline_data.deinit(std.testing.allocator);
    try std.testing.expectEqualSlices(u8, &.{ 9, 10, 123, 0, 0, 0, 0, 0, 0, 0, 17, 0, 0, 0, 0, 0 }, inline_data.bytes);
    const malformed: ir.Global = .{ .name = "mismatch", .kind = .global, .ty = .{ .aggregate = "<{ i8, i64 }>" }, .initializer = .{ .@"opaque" = "{ i8 1, i64 2 }" } };
    try std.testing.expectError(error.UnsupportedGlobalData, decode(std.testing.allocator, ctx, malformed));
}

test "global data releases partial output after allocation failures" {
    const Test = struct {
        fn run(allocator: std.mem.Allocator) !void {
            var module = try ir.Module.parse(allocator, "@object = internal global { ptr, ptr } { ptr @left, ptr @right }, align 8");
            defer module.deinit();
            var data = try decode(allocator, .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout }, module.globals.items[0]);
            defer data.deinit(allocator);
        }
    };
    try std.testing.checkAllAllocationFailures(std.testing.allocator, Test.run, .{});
}
