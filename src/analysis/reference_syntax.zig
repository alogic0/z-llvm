//! Borrowed tokens for bounded reference grammars. Every consumer must consume
//! its entire region; an unrecognized suffix never proves reference absence.
const std = @import("std");
const identifiers = @import("../ir/identifiers.zig");

pub const Cursor = struct {
    text: []const u8,
    index: usize = 0,

    pub fn whitespace(cursor: *Cursor) void {
        while (cursor.index < cursor.text.len and std.ascii.isWhitespace(cursor.text[cursor.index])) : (cursor.index += 1) {}
    }

    pub fn done(cursor: *Cursor) bool {
        cursor.whitespace();
        return cursor.index == cursor.text.len;
    }

    pub fn peek(cursor: *Cursor) ?u8 {
        return if (cursor.done()) null else cursor.text[cursor.index];
    }

    pub fn take(cursor: *Cursor, byte: u8) bool {
        if (cursor.peek() != byte) return false;
        cursor.index += 1;
        return true;
    }

    pub fn word(cursor: *Cursor) ?[]const u8 {
        cursor.whitespace();
        const start = cursor.index;
        while (cursor.index < cursor.text.len) : (cursor.index += 1) {
            const byte = cursor.text[cursor.index];
            if (!std.ascii.isAlphanumeric(byte) and byte != '_' and byte != '-') break;
        }
        return if (cursor.index == start) null else cursor.text[start..cursor.index];
    }

    pub fn keyword(cursor: *Cursor, expected: []const u8) bool {
        const saved = cursor.index;
        if (cursor.word()) |token| {
            if (std.mem.eql(u8, token, expected)) return true;
        }
        cursor.index = saved;
        return false;
    }

    pub fn number(cursor: *Cursor, comptime T: type) ?T {
        cursor.whitespace();
        const start = cursor.index;
        while (cursor.index < cursor.text.len and std.ascii.isDigit(cursor.text[cursor.index])) : (cursor.index += 1) {}
        if (cursor.index == start or !cursor.boundary()) return null;
        return std.fmt.parseInt(T, cursor.text[start..cursor.index], 10) catch null;
    }

    pub fn integer(cursor: *Cursor) ?[]const u8 {
        cursor.whitespace();
        const start = cursor.index;
        _ = cursor.take('-');
        const digits = cursor.index;
        while (cursor.index < cursor.text.len and std.ascii.isDigit(cursor.text[cursor.index])) : (cursor.index += 1) {}
        if (cursor.index == digits or !cursor.boundary()) return null;
        const token = cursor.text[start..cursor.index];
        if (token[0] == '-') {
            _ = std.fmt.parseInt(i128, token, 10) catch return null;
        } else {
            _ = std.fmt.parseInt(u128, token, 10) catch return null;
        }
        return token;
    }

    pub fn boundary(cursor: Cursor) bool {
        return cursor.index == cursor.text.len or std.ascii.isWhitespace(cursor.text[cursor.index]) or
            std.mem.indexOfScalar(u8, ",)=}]:>|", cursor.text[cursor.index]) != null;
    }

    /// Returns spelling without a preceding @, %, or !. The identifier helper
    /// distinguishes numbered slots from quoted names and validates escapes.
    pub fn identifier(cursor: *Cursor) ?[]const u8 {
        cursor.whitespace();
        const start = cursor.index;
        if (cursor.peek() == '"') {
            _ = cursor.string() orelse return null;
        } else {
            while (cursor.index < cursor.text.len) : (cursor.index += 1) {
                const byte = cursor.text[cursor.index];
                if (!std.ascii.isAlphanumeric(byte) and std.mem.indexOfScalar(u8, "_.$-", byte) == null) break;
            }
        }
        const name = cursor.text[start..cursor.index];
        return if (identifiers.isValid(name)) name else null;
    }

    pub fn string(cursor: *Cursor) ?[]const u8 {
        return cursor.quoted(false);
    }

    pub fn byteString(cursor: *Cursor) ?[]const u8 {
        return cursor.quoted(true);
    }

    fn quoted(cursor: *Cursor, allow_null: bool) ?[]const u8 {
        cursor.whitespace();
        const start = cursor.index;
        if (!cursor.take('"')) return null;
        while (cursor.index < cursor.text.len) {
            const byte = cursor.text[cursor.index];
            cursor.index += 1;
            switch (byte) {
                '"' => return cursor.text[start..cursor.index],
                0, '\n', '\r' => return null,
                '\\' => {
                    if (cursor.text.len - cursor.index < 2) return null;
                    for (cursor.text[cursor.index..][0..2]) |digit| {
                        if (!std.ascii.isHex(digit)) return null;
                    }
                    const decoded = std.fmt.parseInt(u8, cursor.text[cursor.index..][0..2], 16) catch return null;
                    if (decoded == 0 and !allow_null) return null;
                    cursor.index += 2;
                },
                else => {},
            }
        }
        return null;
    }
};
