const std = @import("std");

pub const DataLayout = struct {
    text: []const u8,
    pointer_size_bits: ?u16 = 64,
    pointer_abi_align_bits: ?u16 = 64,

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

    pub fn integerAbiAlignmentBits(layout: DataLayout, bits: u16) !u16 {
        var parts = std.mem.splitScalar(u8, layout.text, '-');
        while (parts.next()) |part| {
            if (part.len < 3 or part[0] != 'i') continue;
            const colon = std.mem.indexOfScalar(u8, part, ':') orelse continue;
            const width = try std.fmt.parseInt(u16, part[1..colon], 10);
            if (width != bits) continue;
            const rest = part[colon + 1 ..];
            const abi_end = std.mem.indexOfScalar(u8, rest, ':') orelse rest.len;
            return try std.fmt.parseInt(u16, rest[0..abi_end], 10);
        }
        return error.UnsupportedDataLayoutQuery;
    }
};

fn parsePointerSpec(layout: *DataLayout, part: []const u8) !void {
    if (part.len < 2 or part[1] != ':') return;
    const colon = std.mem.indexOfScalar(u8, part, ':') orelse return;
    const rest = part[colon + 1 ..];
    var fields = std.mem.splitScalar(u8, rest, ':');
    const size_text = fields.next() orelse return error.InvalidDataLayout;
    const abi_text = fields.next() orelse return error.InvalidDataLayout;
    layout.pointer_size_bits = try std.fmt.parseInt(u16, size_text, 10);
    layout.pointer_abi_align_bits = try std.fmt.parseInt(u16, abi_text, 10);
}
