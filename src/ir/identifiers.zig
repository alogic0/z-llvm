//! Identity for supported complete LLVM identifier spellings, without @ or %.
//! Quoting and hexadecimal escapes do not change a named identifier. Numeric
//! slots are a separate namespace from quoted numeric names. Text is borrowed;
//! Unsupported or malformed spellings cannot prove references are different.
const std = @import("std");

const Bytes = struct {
    text: []const u8,
    quoted: bool,
    index: usize = 0,

    fn next(bytes: *Bytes) ?u8 {
        if (bytes.index == bytes.text.len) return null;
        const byte = bytes.text[bytes.index];
        bytes.index += 1;
        if (!bytes.quoted or byte != '\\') return byte;
        const decoded = std.fmt.parseInt(u8, bytes.text[bytes.index..][0..2], 16) catch unreachable;
        bytes.index += 2;
        return decoded;
    }
};

const Name = union(enum) {
    numbered: u32,
    named: Bytes,
};

fn parse(text: []const u8) ?Name {
    if (text.len == 0) return null;
    if (text[0] == '"') {
        if (text.len <= 2 or text[text.len - 1] != '"') return null;
        const body = text[1 .. text.len - 1];
        var index: usize = 0;
        while (index < body.len) {
            switch (body[index]) {
                0, '\r', '\n', '"' => return null,
                '\\' => {
                    if (body.len - index < 3) return null;
                    for (body[index + 1 ..][0..2]) |digit| {
                        if (!std.ascii.isDigit(digit) and !(digit >= 'a' and digit <= 'f') and !(digit >= 'A' and digit <= 'F')) return null;
                    }
                    const decoded = std.fmt.parseInt(u8, body[index + 1 ..][0..2], 16) catch return null;
                    if (decoded == 0) return null;
                    index += 3;
                },
                else => index += 1,
            }
        }
        return .{ .named = .{ .text = body, .quoted = true } };
    }
    if (std.ascii.isDigit(text[0])) {
        for (text) |byte| if (!std.ascii.isDigit(byte)) return null;
        return .{ .numbered = std.fmt.parseInt(u32, text, 10) catch return null };
    }
    for (text) |byte| {
        if (!std.ascii.isAlphanumeric(byte) and std.mem.indexOfScalar(u8, "-.$_", byte) == null) return null;
    }
    return .{ .named = .{ .text = text, .quoted = false } };
}

/// The bounded grammar accepts nonempty names and hexadecimal escapes. Other
/// LLVM spellings (such as literal backslashes) remain unknown to this helper.
pub fn isValid(text: []const u8) bool {
    return parse(text) != null;
}

/// A false result establishes different identities only when both spellings
/// are supported. Reference walkers must report other input as unknown.
pub fn eql(left: []const u8, right: []const u8) bool {
    const a = parse(left) orelse return false;
    const b = parse(right) orelse return false;
    if (a == .numbered) return b == .numbered and a.numbered == b.numbered;
    if (b != .named) return false;
    var a_bytes = a.named;
    var b_bytes = b.named;
    while (a_bytes.next()) |byte| {
        if (byte != (b_bytes.next() orelse return false)) return false;
    }
    return b_bytes.next() == null;
}
