const std = @import("std");
const syntax = @import("parser_syntax.zig");

pub fn contains(text: []const u8, groups: []const []const u8, name: []const u8) bool {
    var rest = std.mem.trim(u8, text, " \t");
    while (rest.len != 0) {
        const end = syntax.findTopLevelTokenEnd(rest) orelse return false;
        const word = rest[0..end];
        if (std.mem.eql(u8, word, name)) return true;
        if (word[0] == '#') for (groups) |record| {
            const eq = std.mem.indexOfScalar(u8, record, '=') orelse continue;
            const prefix = std.mem.trim(u8, record[0..eq], " \t");
            if (!std.mem.startsWith(u8, prefix, "attributes ")) continue;
            if (!std.mem.eql(u8, word, std.mem.trim(u8, prefix["attributes ".len..], " \t"))) continue;
            const body = std.mem.trim(u8, record[eq + 1 ..], " \t");
            if (body.len >= 2 and body[0] == '{' and body[body.len - 1] == '}' and
                contains(body[1 .. body.len - 1], &.{}, name)) return true;
            break;
        };
        rest = std.mem.trimStart(u8, rest[end..], " \t");
    }
    return false;
}
