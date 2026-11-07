//! Borrowed field view for LLVM literal structures and structure constants.
//! Packing affects placement of members, not each member's allocation size.
const std = @import("std");
const syntax = @import("parser_syntax.zig");

pub const Fields = struct {
    rest: []const u8,
    packed_type: bool,
    trailing_empty: bool = false,

    pub fn init(raw: []const u8) ?Fields {
        var text = std.mem.trim(u8, raw, " \t\r\n");
        const packed_type = text.len >= 2 and text[0] == '<' and text[text.len - 1] == '>';
        if (packed_type) text = std.mem.trim(u8, text[1 .. text.len - 1], " \t\r\n");
        if (text.len < 2 or text[0] != '{' or text[text.len - 1] != '}') return null;
        if ((syntax.findMatchingBrace(text, 0) orelse return null) != text.len - 1) return null;
        return .{ .rest = text[1 .. text.len - 1], .packed_type = packed_type };
    }

    pub fn next(fields: *Fields) ?[]const u8 {
        if (fields.trailing_empty) {
            fields.trailing_empty = false;
            return "";
        }
        const text = std.mem.trim(u8, fields.rest, " \t\r\n");
        if (text.len == 0) return null;
        const comma = syntax.findTopLevelComma(text);
        const field = std.mem.trim(u8, if (comma) |at| text[0..at] else text, " \t\r\n");
        // Retain a trailing empty field so consumers reject it as an invalid
        // type/value instead of silently accepting a shortened initializer.
        fields.rest = if (comma) |at| text[at + 1 ..] else "";
        fields.trailing_empty = comma != null and std.mem.trim(u8, fields.rest, " \t\r\n").len == 0;
        return field;
    }
};
