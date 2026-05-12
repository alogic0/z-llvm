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
            .float => 4,
            .double => 8,
            .x86_fp80 => 10,
            .fp128 => 16,
            .ptr => byteWidth(try layout.pointerSizeBits()) orelse error.UnsupportedDataLayoutQuery,
            .aggregate => try layout.aggregateSizeBytes(ty),
            .metadata, .vector => return error.UnsupportedDataLayoutQuery,
        };
    }

    pub fn typeAbiAlignmentBits(layout: DataLayout, ty: ir.Type) anyerror!u16 {
        return switch (ty) {
            .void => 8,
            .int => |bits| try layout.integerAbiAlignmentBits(bits),
            .float => 32,
            .double => 64,
            .x86_fp80 => 128,
            .fp128 => 128,
            .ptr => try layout.pointerAbiAlignmentBits(),
            .aggregate => try layout.aggregateAlignmentBits(ty, .abi),
            .metadata, .vector => return error.UnsupportedDataLayoutQuery,
        };
    }

    pub fn typePreferredAlignmentBits(layout: DataLayout, ty: ir.Type) anyerror!u16 {
        return switch (ty) {
            .void => 8,
            .int => |bits| try layout.integerPreferredAlignmentBits(bits),
            .float => 32,
            .double => 64,
            .x86_fp80 => 128,
            .fp128 => 128,
            .ptr => try layout.pointerPreferredAlignmentBits(),
            .aggregate => try layout.aggregateAlignmentBits(ty, .preferred),
            .metadata, .vector => return error.UnsupportedDataLayoutQuery,
        };
    }

    pub fn aggregateFieldOffsetBytes(layout: DataLayout, ty: ir.Type, field_index: usize) anyerror!i128 {
        const text = switch (ty) {
            .aggregate => |text| text,
            .void, .int, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .vector => return error.UnsupportedDataLayoutQuery,
        };
        if (arrayInfo(text)) |array| {
            const stride = try layout.arrayElementStrideBytes(array.element_ty);
            return @as(i128, @intCast(field_index * stride));
        }

        var fields = aggregateFields(text) orelse return error.UnsupportedDataLayoutQuery;
        var index: usize = 0;
        var offset: u64 = 0;
        while (nextAggregateField(&fields)) |field_text| : (index += 1) {
            const field_ty = parseTypeLiteral(field_text) orelse return error.UnsupportedDataLayoutQuery;
            offset = alignForward(offset, bitsToBytes(try layout.typeAbiAlignmentBits(field_ty)));
            if (index == field_index) return @intCast(offset);
            offset += try layout.typeStoreSizeBytes(field_ty);
        }
        return error.UnsupportedDataLayoutQuery;
    }

    fn aggregateSizeBytes(layout: DataLayout, ty: ir.Type) anyerror!u64 {
        const text = switch (ty) {
            .aggregate => |text| text,
            .void, .int, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .vector => return error.UnsupportedDataLayoutQuery,
        };
        if (arrayInfo(text)) |array| return array.count * try layout.arrayElementStrideBytes(array.element_ty);

        var fields = aggregateFields(text) orelse return error.UnsupportedDataLayoutQuery;
        var size: u64 = 0;
        var max_align: u64 = 1;
        while (nextAggregateField(&fields)) |field_text| {
            const field_ty = parseTypeLiteral(field_text) orelse return error.UnsupportedDataLayoutQuery;
            const field_align = bitsToBytes(try layout.typeAbiAlignmentBits(field_ty));
            max_align = @max(max_align, field_align);
            size = alignForward(size, field_align);
            size += try layout.typeStoreSizeBytes(field_ty);
        }
        return alignForward(size, max_align);
    }

    fn aggregateAlignmentBits(layout: DataLayout, ty: ir.Type, kind: AlignmentKind) anyerror!u16 {
        const text = switch (ty) {
            .aggregate => |text| text,
            .void, .int, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .vector => return error.UnsupportedDataLayoutQuery,
        };
        if (arrayInfo(text)) |array| return switch (kind) {
            .abi => try layout.typeAbiAlignmentBits(array.element_ty),
            .preferred => try layout.typePreferredAlignmentBits(array.element_ty),
        };

        var fields = aggregateFields(text) orelse return error.UnsupportedDataLayoutQuery;
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
        const size = try layout.typeStoreSizeBytes(element_ty);
        const align_bytes = bitsToBytes(try layout.typeAbiAlignmentBits(element_ty));
        return alignForward(size, align_bytes);
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
    if (bits == 0) return null;
    if (bits <= 8) return 8;
    if (bits <= 16) return 16;
    if (bits <= 32) return 32;
    if (bits <= 64) return 64;
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
    if (bits == 0 or bits % 8 != 0) return null;
    return bits / 8;
}

fn bitsToBytes(bits: u16) u64 {
    return @max(@as(u64, 1), (@as(u64, bits) + 7) / 8);
}

fn alignForward(value: u64, alignment: u64) u64 {
    if (alignment <= 1) return value;
    const remainder = value % alignment;
    if (remainder == 0) return value;
    return value + alignment - remainder;
}

const AggregateFields = struct {
    text: []const u8,
    cursor: usize = 0,
};

fn aggregateFields(text: []const u8) ?AggregateFields {
    const trimmed = std.mem.trim(u8, text, " \t");
    if (trimmed.len < 2 or trimmed[0] != '{' or trimmed[trimmed.len - 1] != '}') return null;
    return .{ .text = std.mem.trim(u8, trimmed[1 .. trimmed.len - 1], " \t") };
}

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
    if (fields.cursor >= fields.text.len) return null;
    const rest = fields.text[fields.cursor..];
    const comma = findTopLevelComma(rest);
    const field = std.mem.trim(u8, if (comma) |index| rest[0..index] else rest, " \t");
    fields.cursor = if (comma) |index| fields.cursor + index + 1 else fields.text.len;
    return field;
}

fn parseTypeLiteral(text: []const u8) ?ir.Type {
    const trimmed = std.mem.trim(u8, text, " \t");
    if (std.mem.eql(u8, trimmed, "void")) return .void;
    if (std.mem.eql(u8, trimmed, "ptr")) return .ptr;
    if (std.mem.eql(u8, trimmed, "float")) return .float;
    if (std.mem.eql(u8, trimmed, "double")) return .double;
    if (std.mem.eql(u8, trimmed, "x86_fp80")) return .x86_fp80;
    if (std.mem.eql(u8, trimmed, "fp128")) return .fp128;
    if (trimmed.len >= 2 and ((trimmed[0] == '{' and trimmed[trimmed.len - 1] == '}') or
        (trimmed[0] == '[' and trimmed[trimmed.len - 1] == ']'))) return .{ .aggregate = trimmed };
    if (trimmed.len < 2 or trimmed[0] != 'i') return null;
    const bits = std.fmt.parseInt(u16, trimmed[1..], 10) catch return null;
    if (bits == 0) return null;
    return .{ .int = bits };
}

fn findTopLevelComma(text: []const u8) ?usize {
    var brace_depth: usize = 0;
    var bracket_depth: usize = 0;
    var angle_depth: usize = 0;
    for (text, 0..) |byte, index| {
        switch (byte) {
            '{' => brace_depth += 1,
            '}' => {
                if (brace_depth == 0) return null;
                brace_depth -= 1;
            },
            '[' => bracket_depth += 1,
            ']' => {
                if (bracket_depth == 0) return null;
                bracket_depth -= 1;
            },
            '<' => angle_depth += 1,
            '>' => {
                if (angle_depth == 0) return null;
                angle_depth -= 1;
            },
            ',' => if (brace_depth == 0 and bracket_depth == 0 and angle_depth == 0) return index,
            else => {},
        }
    }
    return null;
}
