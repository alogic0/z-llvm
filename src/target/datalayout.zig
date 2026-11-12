const std = @import("std");
const ir = @import("../ir/core.zig");

pub const DataLayout = struct {
    text: []const u8,
    pointer_size_bits: ?u16 = 64,
    pointer_abi_align_bits: ?u16 = 64,
    pointer_preferred_align_bits: ?u16 = 64,

    pub fn parse(text: []const u8) !DataLayout {
        var layout: DataLayout = .{ .text = text };

        var parts = std.mem.splitScalar(u8, text, '-');
        while (parts.next()) |part| {
            if (part.len == 0) continue;
            if (part[0] == 'p') try parsePointerSpec(&layout, part);
        }

        return layout;
    }

    pub fn pointerSizeBits(layout: DataLayout) !u16 {
        return layout.pointer_size_bits orelse error.UnsupportedDataLayoutQuery;
    }

    pub fn pointerAbiAlignmentBits(layout: DataLayout) !u16 {
        return layout.pointer_abi_align_bits orelse error.UnsupportedDataLayoutQuery;
    }

    pub fn pointerPreferredAlignmentBits(layout: DataLayout) !u16 {
        return layout.pointer_preferred_align_bits orelse error.UnsupportedDataLayoutQuery;
    }

    pub fn integerAbiAlignmentBits(layout: DataLayout, bits: u16) !u16 {
        const spec = try layout.integerAlignmentSpec(bits);
        return spec.abi_bits;
    }

    pub fn integerPreferredAlignmentBits(layout: DataLayout, bits: u16) !u16 {
        const spec = try layout.integerAlignmentSpec(bits);
        return spec.preferred_bits;
    }

    pub fn typeStoreSizeBytes(layout: DataLayout, ty: ir.Type) anyerror!u64 {
        return switch (ty) {
            .void => 0,
            .int => |bits| byteWidth(bits) orelse error.UnsupportedDataLayoutQuery,
            .half => 2,
            .float => 4,
            .double => 8,
            .x86_fp80 => 10,
            .fp128 => 16,
            .ptr => byteWidth(try layout.pointerSizeBits()) orelse error.UnsupportedDataLayoutQuery,
            .aggregate => try layout.aggregateSizeBytes(ty),
            .vector => |vector| (try layout.vectorSizeBits(vector) + 7) / 8,
            .metadata => return error.UnsupportedDataLayoutQuery,
        };
    }

    /// Allocation stride includes trailing padding required by the ABI.
    pub fn typeAllocSizeBytes(layout: DataLayout, ty: ir.Type) anyerror!u64 {
        return alignForward(try layout.typeStoreSizeBytes(ty), bitsToBytes(try layout.typeAbiAlignmentBits(ty)));
    }

    pub fn typeAbiAlignmentBits(layout: DataLayout, ty: ir.Type) anyerror!u16 {
        return switch (ty) {
            .void => 8,
            .int => |bits| try layout.integerAbiAlignmentBits(bits),
            .half => 16,
            .float => 32,
            .double => 64,
            .x86_fp80 => 128,
            .fp128 => 128,
            .ptr => try layout.pointerAbiAlignmentBits(),
            .aggregate => try layout.aggregateAlignmentBits(ty, .abi),
            .vector => |vector| (try layout.vectorAlignmentSpec(vector)).abi_bits,
            .metadata => return error.UnsupportedDataLayoutQuery,
        };
    }

    pub fn typePreferredAlignmentBits(layout: DataLayout, ty: ir.Type) anyerror!u16 {
        return switch (ty) {
            .void => 8,
            .int => |bits| try layout.integerPreferredAlignmentBits(bits),
            .half => 16,
            .float => 32,
            .double => 64,
            .x86_fp80 => 128,
            .fp128 => 128,
            .ptr => try layout.pointerPreferredAlignmentBits(),
            .aggregate => try layout.aggregateAlignmentBits(ty, .preferred),
            .vector => |vector| (try layout.vectorAlignmentSpec(vector)).preferred_bits,
            .metadata => return error.UnsupportedDataLayoutQuery,
        };
    }

    pub fn aggregateFieldOffsetBytes(layout: DataLayout, ty: ir.Type, field_index: usize) anyerror!i128 {
        const text = switch (ty) {
            .aggregate => |text| text,
            .void, .int, .half, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .vector => return error.UnsupportedDataLayoutQuery,
        };
        if (arrayInfo(text)) |array| {
            const stride = try layout.arrayElementStrideBytes(array.element_ty);
            return @intCast(std.math.mul(u64, @intCast(field_index), stride) catch return error.UnsupportedDataLayoutQuery);
        }

        var fields = aggregateFields(text) orelse return error.UnsupportedDataLayoutQuery;
        var index: usize = 0;
        var offset: u64 = 0;
        while (nextAggregateField(&fields)) |field_text| : (index += 1) {
            const field_ty = parseTypeLiteral(field_text) orelse return error.UnsupportedDataLayoutQuery;
            if (!fields.packed_type) offset = try alignForward(offset, bitsToBytes(try layout.typeAbiAlignmentBits(field_ty)));
            if (index == field_index) return @intCast(offset);
            offset = std.math.add(u64, offset, try layout.typeAllocSizeBytes(field_ty)) catch return error.UnsupportedDataLayoutQuery;
        }
        return error.UnsupportedDataLayoutQuery;
    }

    fn aggregateSizeBytes(layout: DataLayout, ty: ir.Type) anyerror!u64 {
        const text = switch (ty) {
            .aggregate => |text| text,
            .void, .int, .half, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .vector => return error.UnsupportedDataLayoutQuery,
        };
        if (arrayInfo(text)) |array| return std.math.mul(u64, array.count, try layout.arrayElementStrideBytes(array.element_ty)) catch error.UnsupportedDataLayoutQuery;

        var fields = aggregateFields(text) orelse return error.UnsupportedDataLayoutQuery;
        var size: u64 = 0;
        var max_align: u64 = 1;
        while (nextAggregateField(&fields)) |field_text| {
            const field_ty = parseTypeLiteral(field_text) orelse return error.UnsupportedDataLayoutQuery;
            const field_align = if (fields.packed_type) 1 else bitsToBytes(try layout.typeAbiAlignmentBits(field_ty));
            max_align = @max(max_align, field_align);
            size = try alignForward(size, field_align);
            size = std.math.add(u64, size, try layout.typeAllocSizeBytes(field_ty)) catch return error.UnsupportedDataLayoutQuery;
        }
        return alignForward(size, max_align);
    }

    fn aggregateAlignmentBits(layout: DataLayout, ty: ir.Type, kind: AlignmentKind) anyerror!u16 {
        const text = switch (ty) {
            .aggregate => |text| text,
            .void, .int, .half, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .vector => return error.UnsupportedDataLayoutQuery,
        };
        if (arrayInfo(text)) |array| return switch (kind) {
            .abi => try layout.typeAbiAlignmentBits(array.element_ty),
            .preferred => try layout.typePreferredAlignmentBits(array.element_ty),
        };

        var fields = aggregateFields(text) orelse return error.UnsupportedDataLayoutQuery;
        if (fields.packed_type) return 8;
        var max_align: u16 = 8;
        while (nextAggregateField(&fields)) |field_text| {
            const field_ty = parseTypeLiteral(field_text) orelse return error.UnsupportedDataLayoutQuery;
            const field_align = switch (kind) {
                .abi => try layout.typeAbiAlignmentBits(field_ty),
                .preferred => try layout.typePreferredAlignmentBits(field_ty),
            };
            max_align = @max(max_align, field_align);
        }
        return max_align;
    }

    fn arrayElementStrideBytes(layout: DataLayout, element_ty: ir.Type) anyerror!u64 {
        return layout.typeAllocSizeBytes(element_ty);
    }

    fn vectorSizeBits(layout: DataLayout, vector: ir.VectorType) !u64 {
        if (vector.len == 0) return error.UnsupportedDataLayoutQuery;
        const element: u64 = switch (vector.elem_ty) {
            .int => |bits| if (bits == 0) return error.UnsupportedDataLayoutQuery else bits,
            .half => 16,
            .float => 32,
            .double => 64,
            .x86_fp80 => 80,
            .fp128 => 128,
            .ptr => try layout.pointerSizeBits(),
        };
        return @as(u64, vector.len) * element;
    }

    fn vectorAlignmentSpec(layout: DataLayout, vector: ir.VectorType) !AlignmentSpec {
        const bits = try layout.vectorSizeBits(vector);
        var parts = std.mem.splitScalar(u8, layout.text, '-');
        while (parts.next()) |part| {
            if (part.len < 3 or part[0] != 'v') continue;
            const colon = std.mem.indexOfScalar(u8, part, ':') orelse return error.InvalidDataLayout;
            const width = try std.fmt.parseInt(u64, part[1..colon], 10);
            var fields = std.mem.splitScalar(u8, part[colon + 1 ..], ':');
            const abi = try std.fmt.parseInt(u16, fields.next() orelse return error.InvalidDataLayout, 10);
            const preferred = if (fields.next()) |text| try std.fmt.parseInt(u16, text, 10) else abi;
            if (fields.next() != null or abi < 8 or !std.math.isPowerOfTwo(abi) or
                preferred < abi or !std.math.isPowerOfTwo(preferred)) return error.InvalidDataLayout;
            if (width == bits) return .{ .abi_bits = abi, .preferred_bits = preferred };
        }
        // LLVM's natural vector alignment rounds the complete store size,
        // without inserting each scalar element's allocation padding.
        const bytes = try std.math.ceilPowerOfTwo(u64, (bits + 7) / 8);
        const alignment = std.math.cast(u16, bytes * 8) orelse return error.UnsupportedDataLayoutQuery;
        return .{ .abi_bits = alignment, .preferred_bits = alignment };
    }

    fn integerAlignmentSpec(layout: DataLayout, bits: u16) !AlignmentSpec {
        var parts = std.mem.splitScalar(u8, layout.text, '-');
        while (parts.next()) |part| {
            if (part.len < 3 or part[0] != 'i') continue;
            const colon = std.mem.indexOfScalar(u8, part, ':') orelse continue;
            const width = try std.fmt.parseInt(u16, part[1..colon], 10);
            if (width != bits) continue;
            const rest = part[colon + 1 ..];
            var fields = std.mem.splitScalar(u8, rest, ':');
            const abi_text = fields.next() orelse return error.InvalidDataLayout;
            const abi_bits = try std.fmt.parseInt(u16, abi_text, 10);
            const preferred_bits = if (fields.next()) |preferred_text|
                try std.fmt.parseInt(u16, preferred_text, 10)
            else
                abi_bits;
            return .{ .abi_bits = abi_bits, .preferred_bits = preferred_bits };
        }
        if (defaultIntegerAlignment(bits)) |alignment| {
            return .{ .abi_bits = alignment, .preferred_bits = alignment };
        }
        return error.UnsupportedDataLayoutQuery;
    }
};

const AlignmentKind = enum {
    abi,
    preferred,
};

const AlignmentSpec = struct {
    abi_bits: u16,
    preferred_bits: u16,
};

fn defaultIntegerAlignment(bits: u16) ?u16 {
    if (bits == 0) return 8;
    if (bits <= 8) return 8;
    if (bits <= 16) return 16;
    if (bits <= 32) return 32;
    if (bits <= 64) return 64;
    if (bits <= 128) return 128;
    return null;
}

fn parsePointerSpec(layout: *DataLayout, part: []const u8) !void {
    if (part.len < 2 or part[1] != ':') return;
    const colon = std.mem.indexOfScalar(u8, part, ':') orelse return;
    const rest = part[colon + 1 ..];
    var fields = std.mem.splitScalar(u8, rest, ':');
    const size_text = fields.next() orelse return error.InvalidDataLayout;
    const abi_text = fields.next() orelse return error.InvalidDataLayout;
    layout.pointer_size_bits = try std.fmt.parseInt(u16, size_text, 10);
    layout.pointer_abi_align_bits = try std.fmt.parseInt(u16, abi_text, 10);
    layout.pointer_preferred_align_bits = if (fields.next()) |preferred_text|
        try std.fmt.parseInt(u16, preferred_text, 10)
    else
        layout.pointer_abi_align_bits;
}

fn byteWidth(bits: u16) ?u64 {
    if (bits == 0) return 0;
    return (@as(u64, bits) + 7) / 8;
}

fn bitsToBytes(bits: u16) u64 {
    return @max(@as(u64, 1), (@as(u64, bits) + 7) / 8);
}

fn alignForward(value: u64, alignment: u64) !u64 {
    if (alignment <= 1) return value;
    const remainder = value % alignment;
    if (remainder == 0) return value;
    return std.math.add(u64, value, alignment - remainder) catch error.UnsupportedDataLayoutQuery;
}

const AggregateFields = @import("../ir/structure.zig").Fields;
const aggregateFields = AggregateFields.init;

const ArrayInfo = struct {
    count: u64,
    element_ty: ir.Type,
};

fn arrayInfo(text: []const u8) ?ArrayInfo {
    const trimmed = std.mem.trim(u8, text, " \t");
    if (trimmed.len < 5 or trimmed[0] != '[' or trimmed[trimmed.len - 1] != ']') return null;
    const body = std.mem.trim(u8, trimmed[1 .. trimmed.len - 1], " \t");
    const x_index = std.mem.indexOf(u8, body, " x ") orelse return null;
    const count = std.fmt.parseInt(u64, std.mem.trim(u8, body[0..x_index], " \t"), 10) catch return null;
    const element_ty = parseTypeLiteral(std.mem.trim(u8, body[x_index + " x ".len ..], " \t")) orelse return null;
    return .{ .count = count, .element_ty = element_ty };
}

fn nextAggregateField(fields: *AggregateFields) ?[]const u8 {
    return fields.next();
}

fn parseTypeLiteral(text: []const u8) ?ir.Type {
    return @import("../ir/parser_types_values.zig").parseType(text) catch null;
}

test "fixed vectors use packed store sizes and whole-vector allocation alignment" {
    const layout = try DataLayout.parse("e-p:64:64");
    const cases = [_]struct { len: u32, element: ir.VectorElementType, store: u64, alloc: u64, align_bits: u16 }{
        .{ .len = 1, .element = .x86_fp80, .store = 10, .alloc = 16, .align_bits = 128 },
        .{ .len = 2, .element = .x86_fp80, .store = 20, .alloc = 32, .align_bits = 256 },
        .{ .len = 3, .element = .x86_fp80, .store = 30, .alloc = 32, .align_bits = 256 },
        .{ .len = 3, .element = .float, .store = 12, .alloc = 16, .align_bits = 128 },
        .{ .len = 9, .element = .{ .int = 1 }, .store = 2, .alloc = 2, .align_bits = 16 },
        .{ .len = 3, .element = .ptr, .store = 24, .alloc = 32, .align_bits = 256 },
    };
    for (cases) |case| {
        const ty: ir.Type = .{ .vector = .{ .len = case.len, .elem_ty = case.element } };
        try std.testing.expectEqual(case.store, try layout.typeStoreSizeBytes(ty));
        try std.testing.expectEqual(case.alloc, try layout.typeAllocSizeBytes(ty));
        try std.testing.expectEqual(case.align_bits, try layout.typeAbiAlignmentBits(ty));
    }
    const override = try DataLayout.parse("e-v160:128:256");
    const extended: ir.Type = .{ .vector = .{ .len = 2, .elem_ty = .x86_fp80 } };
    try std.testing.expectEqual(@as(u64, 32), try override.typeAllocSizeBytes(extended));
    try std.testing.expectEqual(@as(u16, 128), try override.typeAbiAlignmentBits(extended));
    try std.testing.expectEqual(@as(u16, 256), try override.typePreferredAlignmentBits(extended));
    const malformed = try DataLayout.parse("e-v160:24");
    try std.testing.expectError(error.InvalidDataLayout, malformed.typeAllocSizeBytes(extended));
}

test "aggregate fields advance by allocation size including scalar tail padding" {
    const layout = try DataLayout.parse("e-p:64:64-i24:32-i64:64");
    try std.testing.expectEqual(@as(u64, 3), try layout.typeStoreSizeBytes(.{ .int = 24 }));
    try std.testing.expectEqual(@as(u64, 4), try layout.typeAllocSizeBytes(.{ .int = 24 }));
    try std.testing.expectEqual(@as(u64, 10), try layout.typeStoreSizeBytes(.x86_fp80));
    try std.testing.expectEqual(@as(u64, 16), try layout.typeAllocSizeBytes(.x86_fp80));
    const cases = [_]struct { text: []const u8, offset: i128, size: u64 }{
        .{ .text = "{ i24, i8 }", .offset = 4, .size = 8 },
        .{ .text = "{ x86_fp80, i8 }", .offset = 16, .size = 32 },
        .{ .text = "{ { i24, i8 }, i16 }", .offset = 8, .size = 12 },
        .{ .text = "{ [2 x { i24, i8 }], i8 }", .offset = 16, .size = 20 },
    };
    for (cases) |case| {
        const ty: ir.Type = .{ .aggregate = case.text };
        try std.testing.expectEqual(case.offset, try layout.aggregateFieldOffsetBytes(ty, 1));
        try std.testing.expectEqual(case.size, try layout.typeStoreSizeBytes(ty));
        try std.testing.expectEqual(case.size, try layout.typeAllocSizeBytes(ty));
    }
}

test "allocation and aggregate layout queries reject arithmetic overflow" {
    const layout = try DataLayout.parse("e-p:64:64-i64:64");
    try std.testing.expectError(error.UnsupportedDataLayoutQuery, layout.typeStoreSizeBytes(.{ .aggregate = "[18446744073709551615 x i16]" }));
    try std.testing.expectError(error.UnsupportedDataLayoutQuery, layout.aggregateFieldOffsetBytes(.{ .aggregate = "[2 x i64]" }, std.math.maxInt(usize)));
    const overflow: ir.Type = .{ .aggregate = "{ [18446744073709551615 x i8], i64 }" };
    try std.testing.expectError(error.UnsupportedDataLayoutQuery, layout.aggregateFieldOffsetBytes(overflow, 1));
    try std.testing.expectError(error.UnsupportedDataLayoutQuery, layout.typeStoreSizeBytes(overflow));
    try std.testing.expectError(error.UnsupportedDataLayoutQuery, alignForward(std.math.maxInt(u64), 8));
}
