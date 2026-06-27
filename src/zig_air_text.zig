pub fn findMatching(text: []const u8, open_index: usize, open: u8, close: u8) ?usize {
    var depth: usize = 0;
    for (text[open_index..], open_index..) |char, index| {
        if (char == open) depth += 1;
        if (char == close) {
            if (depth == 0) return null;
            depth -= 1;
            if (depth == 0) return index;
        }
    }
    return null;
}

pub const TopLevelSplit = struct {
    text: []const u8,
    separator: u8,
    offset: usize = 0,

    pub fn next(self: *TopLevelSplit) ?[]const u8 {
        if (self.offset > self.text.len) return null;
        const start = self.offset;
        var paren_depth: usize = 0;
        var bracket_depth: usize = 0;
        var brace_depth: usize = 0;
        var angle_depth: usize = 0;
        var quote: ?u8 = null;
        var index = start;
        while (index < self.text.len) : (index += 1) {
            const char = self.text[index];
            if (quote) |active_quote| {
                if (char == active_quote and (index == 0 or self.text[index - 1] != '\\')) quote = null;
                continue;
            }
            switch (char) {
                '\'', '"' => quote = char,
                '(' => paren_depth += 1,
                ')' => if (paren_depth > 0) {
                    paren_depth -= 1;
                },
                '[' => bracket_depth += 1,
                ']' => if (bracket_depth > 0) {
                    bracket_depth -= 1;
                },
                '{' => brace_depth += 1,
                '}' => if (brace_depth > 0) {
                    brace_depth -= 1;
                },
                '<' => angle_depth += 1,
                '>' => if (angle_depth > 0) {
                    angle_depth -= 1;
                },
                else => {},
            }
            if (char == self.separator and paren_depth == 0 and bracket_depth == 0 and
                brace_depth == 0 and angle_depth == 0 and quote == null)
            {
                self.offset = index + 1;
                return self.text[start..index];
            }
        }
        self.offset = self.text.len + 1;
        return self.text[start..];
    }
};

pub fn splitTopLevel(text: []const u8, separator: u8) TopLevelSplit {
    return .{ .text = text, .separator = separator };
}
