//! Advisory evidence alongside physical line ceilings. Tokenization keeps HTML,
//! string literals and comments from masquerading as compressed control flow.
const std = @import("std");

pub const Metrics = struct {
    dense_lines: usize = 0,
    worst_branches: usize = 0,
    worst_line: usize = 0,

    fn observe(self: *Metrics, input: struct { line: usize, bytes: usize, branches: usize }) void {
        if (input.bytes <= 160 or input.branches < 4) return;
        self.dense_lines += 1;
        if (input.branches > self.worst_branches) {
            self.worst_branches = input.branches;
            self.worst_line = input.line;
        }
    }
};

pub fn inspect(source: [:0]const u8) Metrics {
    var tokenizer = std.zig.Tokenizer.init(source);
    var result = Metrics{};
    var start: usize = 0;
    var end = lineEnd(source, start);
    var line: usize = 1;
    var branches: usize = 0;
    while (true) {
        const token = tokenizer.next();
        while (token.loc.start > end and end < source.len) {
            result.observe(.{ .line = line, .bytes = end - start, .branches = branches });
            start = end + 1;
            end = lineEnd(source, start);
            line += 1;
            branches = 0;
        }
        switch (token.tag) {
            .keyword_if,
            .keyword_else,
            .keyword_switch,
            .keyword_for,
            .keyword_while,
            .keyword_catch,
            .keyword_orelse,
            .keyword_and,
            .keyword_or,
            => branches += 1,
            .eof => break,
            else => {},
        }
    }
    result.observe(.{ .line = line, .bytes = end - start, .branches = branches });
    return result;
}

fn lineEnd(source: []const u8, start: usize) usize {
    return if (std.mem.indexOfScalar(u8, source[start..], '\n')) |offset| start + offset else source.len;
}

test "readability ignores branching words inside long markup and comments" {
    const source =
        \\const markup = "<div>if else while for switch catch orelse and or if else while for switch catch orelse and or if else while for switch catch orelse and or</div>";
        \\// if else while for switch catch orelse and or if else while for switch catch orelse and or if else while for switch catch orelse and or if else while for switch catch orelse and or
    ;
    try std.testing.expectEqual(@as(usize, 0), inspect(source).dense_lines);
}

test "readability identifies compressed control flow at its physical line" {
    const source =
        \\const ordinary = 1;
        \\const result = if (input.first_condition and input.second_condition or input.third_condition) input.accepted_result else if (input.fourth_condition and input.fifth_condition) input.alternate_result else input.refused_result;
    ;
    const result = inspect(source);
    try std.testing.expectEqual(@as(usize, 1), result.dense_lines);
    try std.testing.expectEqual(@as(usize, 2), result.worst_line);
    try std.testing.expectEqual(@as(usize, 7), result.worst_branches);
}
