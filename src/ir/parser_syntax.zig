const std = @import("std");
const core = @import("core.zig");
const fp_semantics = @import("../analysis/fp_semantics.zig");

pub fn findLineCommentStart(line: []const u8) ?usize {
    var in_string = false;
    var escaped = false;
    for (line, 0..) |byte, index| {
        if (in_string) {
            if (escaped) {
                escaped = false;
            } else if (byte == '\\') {
                escaped = true;
            } else if (byte == '"') {
                in_string = false;
            }
            continue;
        }
        if (byte == '"') {
            in_string = true;
        } else if (byte == ';') {
            return index;
        }
    }
    return null;
}

pub fn findAssignmentSeparator(line: []const u8) ?usize {
    var in_string = false;
    var escaped = false;
    for (line, 0..) |byte, index| {
        if (in_string) {
            if (escaped) {
                escaped = false;
            } else if (byte == '\\') {
                escaped = true;
            } else if (byte == '"') {
                in_string = false;
            }
            continue;
        }
        if (byte == '"') {
            in_string = true;
        } else if (byte == '=') {
            return index;
        }
    }
    return null;
}

pub fn findClosingQuote(text: []const u8, quote_index: usize) ?usize {
    if (quote_index >= text.len or text[quote_index] != '"') return null;
    var escaped = false;
    var index = quote_index + 1;
    while (index < text.len) : (index += 1) {
        const byte = text[index];
        if (escaped) {
            escaped = false;
        } else if (byte == '\\') {
            escaped = true;
        } else if (byte == '"') {
            return index;
        }
    }
    return null;
}

pub fn findMatchingParen(text: []const u8, open_index: usize) ?usize {
    return findMatchingDelimiter(text, open_index, '(', ')');
}

fn findMatchingDelimiter(text: []const u8, open_index: usize, open: u8, close: u8) ?usize {
    if (open_index >= text.len or text[open_index] != open) return null;
    var depth: usize = 0;
    var in_string = false;
    var escaped = false;
    for (text[open_index..], open_index..) |byte, index| {
        if (in_string) {
            if (escaped) {
                escaped = false;
            } else if (byte == '\\') {
                escaped = true;
            } else if (byte == '"') {
                in_string = false;
            }
            continue;
        }
        if (byte == '"') {
            in_string = true;
            continue;
        }
        if (byte == open) {
            depth += 1;
        } else if (byte == close) {
            depth -= 1;
            if (depth == 0) return index;
        }
    }
    return null;
}

pub fn findOpenParenOutsideString(text: []const u8, start_index: usize) ?usize {
    return findByteOutsideString(text, start_index, '(');
}

pub fn findByteOutsideString(text: []const u8, start_index: usize, wanted: u8) ?usize {
    var in_string = false;
    var escaped = false;
    var index = start_index;
    while (index < text.len) : (index += 1) {
        const byte = text[index];
        if (in_string) {
            if (escaped) {
                escaped = false;
            } else if (byte == '\\') {
                escaped = true;
            } else if (byte == '"') {
                in_string = false;
            }
            continue;
        }
        if (byte == '"') {
            in_string = true;
            continue;
        }
        if (byte == wanted) return index;
    }
    return null;
}

pub fn findMatchingBracket(text: []const u8, open_index: usize) ?usize {
    return findMatchingDelimiter(text, open_index, '[', ']');
}

pub fn findMatchingBrace(text: []const u8, open_index: usize) ?usize {
    return findMatchingDelimiter(text, open_index, '{', '}');
}

pub fn findMatchingBracketOpen(text: []const u8, close_index: usize) ?usize {
    return findMatchingOpen(text, close_index, '[', ']');
}

pub fn findMatchingBraceOpen(text: []const u8, close_index: usize) ?usize {
    return findMatchingOpen(text, close_index, '{', '}');
}

pub fn findMatchingOpen(text: []const u8, close_index: usize, open_byte: u8, close_byte: u8) ?usize {
    if (close_index >= text.len or text[close_index] != close_byte) return null;
    var depth: usize = 0;
    var index = close_index + 1;
    while (index > 0) {
        index -= 1;
        const byte = text[index];
        if (byte == close_byte) depth += 1;
        if (byte == open_byte) {
            depth -= 1;
            if (depth == 0) return index;
        }
    }
    return null;
}

pub fn firstToken(text: []const u8) ?[]const u8 {
    const trimmed = std.mem.trim(u8, text, " \t");
    if (trimmed.len == 0) return null;
    const end = std.mem.indexOfAny(u8, trimmed, " \t") orelse trimmed.len;
    return trimmed[0..end];
}

pub fn trimFirstToken(text: []const u8) []const u8 {
    const trimmed = std.mem.trim(u8, text, " \t");
    const end = std.mem.indexOfAny(u8, trimmed, " \t") orelse return "";
    return std.mem.trim(u8, trimmed[end..], " \t");
}

pub fn findTopLevelTo(text: []const u8) ?usize {
    var brace_depth: usize = 0;
    var bracket_depth: usize = 0;
    var angle_depth: usize = 0;
    var paren_depth: usize = 0;
    var index: usize = 0;
    while (index < text.len) : (index += 1) {
        switch (text[index]) {
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
            '(' => paren_depth += 1,
            ')' => {
                if (paren_depth == 0) return null;
                paren_depth -= 1;
            },
            ' ' => if (brace_depth == 0 and bracket_depth == 0 and angle_depth == 0 and paren_depth == 0 and
                index + " to ".len <= text.len and std.mem.eql(u8, text[index .. index + " to ".len], " to "))
            {
                return index;
            },
            else => {},
        }
    }
    return null;
}

pub fn parseQuotedPrefix(rest: *[]const u8) ?[]const u8 {
    const text = std.mem.trim(u8, rest.*, " \t");
    if (text.len == 0 or text[0] != '"') return null;
    var index: usize = 1;
    while (index < text.len) : (index += 1) {
        if (text[index] == '"' and text[index - 1] != '\\') {
            rest.* = text[index + 1 ..];
            return text[1..index];
        }
    }
    return null;
}

pub fn firstTokenFromEnd(text: []const u8) ?[]const u8 {
    const trimmed = std.mem.trim(u8, text, " \t");
    if (trimmed.len == 0) return null;
    const start = std.mem.lastIndexOfAny(u8, trimmed, " \t");
    return if (start) |index| trimmed[index + 1 ..] else trimmed;
}

pub fn findMatchingAngle(text: []const u8, open_index: usize) ?usize {
    if (text[open_index] != '<') return null;
    var depth: usize = 0;
    for (text[open_index..], open_index..) |byte, index| {
        if (byte == '<') depth += 1;
        if (byte == '>') {
            depth -= 1;
            if (depth == 0) return index;
        }
    }
    return null;
}

pub fn findMatchingAngleOpen(text: []const u8, close_index: usize) ?usize {
    if (text[close_index] != '>') return null;
    var depth: usize = 0;
    var index = close_index + 1;
    while (index > 0) {
        index -= 1;
        const byte = text[index];
        if (byte == '>') depth += 1;
        if (byte == '<') {
            depth -= 1;
            if (depth == 0) return index;
        }
    }
    return null;
}

pub fn findTopLevelComma(text: []const u8) ?usize {
    var brace_depth: usize = 0;
    var bracket_depth: usize = 0;
    var angle_depth: usize = 0;
    var paren_depth: usize = 0;
    var in_string = false;
    var escaped = false;
    for (text, 0..) |byte, index| {
        if (in_string) {
            if (escaped) {
                escaped = false;
            } else if (byte == '\\') {
                escaped = true;
            } else if (byte == '"') {
                in_string = false;
            }
            continue;
        }
        switch (byte) {
            '"' => in_string = true,
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
            '(' => paren_depth += 1,
            ')' => {
                if (paren_depth == 0) return null;
                paren_depth -= 1;
            },
            ',' => if (brace_depth == 0 and bracket_depth == 0 and angle_depth == 0 and paren_depth == 0) return index,
            else => {},
        }
    }
    return null;
}

pub fn findTopLevelTokenEnd(text: []const u8) ?usize {
    var brace_depth: usize = 0;
    var bracket_depth: usize = 0;
    var angle_depth: usize = 0;
    var paren_depth: usize = 0;
    var in_string = false;
    var escaped = false;
    for (text, 0..) |byte, index| {
        if (in_string) {
            if (escaped) {
                escaped = false;
            } else if (byte == '\\') {
                escaped = true;
            } else if (byte == '"') {
                in_string = false;
            }
            continue;
        }
        switch (byte) {
            '"' => in_string = true,
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
            '(' => paren_depth += 1,
            ')' => {
                if (paren_depth == 0) return null;
                paren_depth -= 1;
            },
            ' ', '\t' => if (brace_depth == 0 and bracket_depth == 0 and angle_depth == 0 and paren_depth == 0) return index,
            else => {},
        }
    }
    if (brace_depth != 0 or bracket_depth != 0 or angle_depth != 0 or paren_depth != 0 or in_string) return null;
    return text.len;
}
