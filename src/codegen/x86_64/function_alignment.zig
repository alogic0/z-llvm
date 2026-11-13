//! Explicit function placement, independent of stack and global alignment.
const std = @import("std");
const Cursor = @import("../../analysis/reference_syntax.zig").Cursor;
pub const maximum: u32 = 4096;
pub fn validate(value: u32) !void {
    if (value == 0 or value > maximum or !std.math.isPowerOfTwo(value)) return error.UnsupportedFunctionAlignment;
}
pub fn fromAttributes(attrs: ?[]const u8) !u32 {
    const text = attrs orelse return 1;
    var cursor: Cursor = .{ .text = text };
    var closes: [64]u8 = undefined;
    var depth: usize = 0;
    var result: ?u32 = null;
    while (!cursor.done()) {
        const ch = cursor.peek().?;
        if (ch == '"') {
            _ = cursor.string() orelse return error.UnsupportedFunctionAlignment;
            continue;
        }
        if (ch == ';') {
            while (cursor.index < text.len and text[cursor.index] != '\n') : (cursor.index += 1) {}
            continue;
        }
        if (ch == '@' or ch == '%' or ch == '!') {
            cursor.index += 1;
            if (cursor.identifier() != null) continue;
            // Metadata tuples are nested opaque operands, not attributes.
            if (cursor.peek() != '{') return error.UnsupportedFunctionAlignment;
            continue;
        }
        if (std.mem.indexOfScalar(u8, "([{<", ch)) |index| {
            if (depth == closes.len) return error.UnsupportedFunctionAlignment;
            const endings = [_]u8{ ')', ']', '}', '>' };
            closes[depth] = endings[index];
            depth += 1;
            cursor.index += 1;
            continue;
        }
        if (std.mem.indexOfScalar(u8, ")]}>", ch) != null) {
            if (depth == 0 or closes[depth - 1] != ch) return error.UnsupportedFunctionAlignment;
            depth -= 1;
            cursor.index += 1;
            continue;
        }
        if (std.ascii.isAlphanumeric(ch) or ch == '_' or ch == '-') {
            const start = cursor.index;
            while (cursor.index < text.len and (std.ascii.isAlphanumeric(text[cursor.index]) or std.mem.indexOfScalar(u8, "_.-$", text[cursor.index]) != null)) : (cursor.index += 1) {}
            if (depth == 0 and std.mem.eql(u8, text[start..cursor.index], "align")) {
                if (result != null or cursor.index == text.len or !std.ascii.isWhitespace(text[cursor.index])) return error.UnsupportedFunctionAlignment;
                const value = cursor.number(u32) orelse return error.UnsupportedFunctionAlignment;
                try validate(value);
                result = value;
            }
            continue;
        }
        cursor.index += 1;
    }
    if (depth != 0) return error.UnsupportedFunctionAlignment;
    return result orelse 1;
}
test "function alignment reads only top-level placement attributes" {
    try std.testing.expectEqual(@as(u32, 1), try fromAttributes(null));
    try std.testing.expectEqual(@as(u32, 1), try fromAttributes("#4 !align !0 \"hint\"=\"align 256\" alignstack(32)"));
    try std.testing.expectEqual(@as(u32, 64), try fromAttributes("#4 align 64 !dbg !17 \"hint\"=\"align 256\""));
    try std.testing.expectEqual(maximum, try fromAttributes("align 4096"));
    try std.testing.expectEqual(@as(u32, 8), try fromAttributes("prefix {i32,i32} {i32 7,i32 9} align 8"));
}
test "function alignment keeps invalid duplicate and excessive requests closed" {
    for ([_][]const u8{ "align", "align -1", "align 0", "align 3", "align 8192", "align 4294967296", "align 4 align 4", "align(4)", "align 4suffix" }) |text| try std.testing.expectError(error.UnsupportedFunctionAlignment, fromAttributes(text));
}
