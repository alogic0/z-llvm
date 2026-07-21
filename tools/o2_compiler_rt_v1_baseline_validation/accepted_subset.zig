const std = @import("std");

const Linkage = enum {
    private,
    internal,
};

fn functionName(header: []const u8) ![]const u8 {
    if (!std.mem.startsWith(u8, header, "define ")) return error.MalformedDefinition;
    const at = std.mem.indexOfScalar(u8, header, '@') orelse return error.MalformedDefinition;
    const start = at + 1;
    if (start == header.len) return error.MalformedDefinition;
    if (header[start] == '"') {
        var index = start + 1;
        while (index < header.len) : (index += 1) {
            if (header[index] == '\\') {
                index += 1;
                if (index >= header.len) return error.MalformedDefinition;
                continue;
            }
            if (header[index] != '"') continue;
            if (index + 1 >= header.len or header[index + 1] != '(')
                return error.MalformedDefinition;
            return header[start .. index + 1];
        }
        return error.MalformedDefinition;
    }
    const end = std.mem.indexOfScalarPos(u8, header, start, '(') orelse
        return error.MalformedDefinition;
    if (end == start) return error.MalformedDefinition;
    return header[start..end];
}

fn originalLinkage(header: []const u8) ?Linkage {
    const at = std.mem.indexOfScalar(u8, header, '@') orelse return null;
    var tokens = std.mem.tokenizeScalar(u8, header["define ".len..at], ' ');
    while (tokens.next()) |token| {
        if (std.mem.eql(u8, token, "private")) return .private;
        if (std.mem.eql(u8, token, "internal")) return .internal;
    }
    return null;
}

fn globalName(line: []const u8) ![]const u8 {
    if (line.len < 2 or line[0] != '@') return error.MalformedDefinition;
    const equals = std.mem.indexOf(u8, line, " = ") orelse return error.MalformedDefinition;
    if (equals == 1) return error.MalformedDefinition;
    return line[1..equals];
}

fn globalLinkage(line: []const u8) ?Linkage {
    const equals = std.mem.indexOf(u8, line, " = ") orelse return null;
    const value = line[equals + " = ".len ..];
    if (std.mem.startsWith(u8, value, "private ")) return .private;
    if (std.mem.startsWith(u8, value, "internal ")) return .internal;
    return null;
}

pub fn restorePrivateLinkage(
    allocator: std.mem.Allocator,
    raw_input: []const u8,
    extracted: []const u8,
) ![]u8 {
    var originals = std.StringHashMap(Linkage).init(allocator);
    defer originals.deinit();
    var raw_lines = std.mem.splitScalar(u8, raw_input, '\n');
    while (raw_lines.next()) |line| {
        const linkage, const name = if (std.mem.startsWith(u8, line, "define ")) .{
            originalLinkage(line) orelse continue,
            try functionName(line),
        } else if (line.len != 0 and line[0] == '@') .{
            globalLinkage(line) orelse continue,
            try globalName(line),
        } else continue;
        const entry = try originals.getOrPut(name);
        if (entry.found_existing) return error.DuplicateDefinition;
        entry.value_ptr.* = linkage;
    }
    if (originals.count() == 0) return error.MissingPrivateDefinitions;

    var output: std.Io.Writer.Allocating = .init(allocator);
    errdefer output.deinit();
    var restored: usize = 0;
    var offset: usize = 0;
    while (offset < extracted.len) {
        const end = std.mem.indexOfScalarPos(u8, extracted, offset, '\n') orelse extracted.len;
        const line = extracted[offset..end];
        if (std.mem.startsWith(u8, line, "define ")) {
            const name = try functionName(line);
            if (originals.get(name)) |linkage| {
                const hidden = "define hidden ";
                const original = switch (linkage) {
                    .private => "define private ",
                    .internal => "define internal ",
                };
                if (std.mem.startsWith(u8, line, hidden)) {
                    try output.writer.writeAll(original);
                    try output.writer.writeAll(line[hidden.len..]);
                    restored += 1;
                } else if (std.mem.startsWith(u8, line, original)) {
                    try output.writer.writeAll(line);
                } else {
                    return error.LinkageMismatch;
                }
            } else {
                try output.writer.writeAll(line);
            }
        } else if (line.len != 0 and line[0] == '@') {
            const name = try globalName(line);
            if (originals.get(name)) |linkage| {
                const equals = std.mem.indexOf(u8, line, " = ") orelse
                    return error.MalformedDefinition;
                const value_start = equals + " = ".len;
                const hidden = "hidden ";
                const original = switch (linkage) {
                    .private => "private ",
                    .internal => "internal ",
                };
                const value = line[value_start..];
                try output.writer.writeAll(line[0..value_start]);
                if (std.mem.startsWith(u8, value, hidden)) {
                    try output.writer.writeAll(original);
                    try output.writer.writeAll(value[hidden.len..]);
                    restored += 1;
                } else if (std.mem.startsWith(u8, value, original)) {
                    try output.writer.writeAll(value);
                } else {
                    return error.LinkageMismatch;
                }
            } else {
                try output.writer.writeAll(line);
            }
        } else {
            try output.writer.writeAll(line);
        }
        if (end < extracted.len) try output.writer.writeByte('\n');
        offset = if (end < extracted.len) end + 1 else end;
    }
    if (restored == 0) return error.MissingPromotedDefinitions;
    return output.toOwnedSlice();
}

test "accepted subset restores private and internal functions without changing other bytes" {
    const raw =
        "@table = private constant [1 x i8] c\"x\"\n" ++
        "@alias = alias i32 (), ptr @private_root\n" ++
        "define private i32 @private_root() {\n  ret i32 1\n}\n" ++
        "define internal i32 @\"internal helper\"() {\n  ret i32 2\n}\n" ++
        "define hidden i32 @public_root() {\n  ret i32 3\n}\n";
    const extracted =
        "@table = hidden constant [1 x i8] c\"x\"\n" ++
        "@alias = alias i32 (), ptr @private_root\n" ++
        "define hidden i32 @private_root() {\n  ret i32 1\n}\n" ++
        "define hidden i32 @\"internal helper\"() {\n  ret i32 2\n}\n" ++
        "define hidden i32 @public_root() {\n  ret i32 3\n}\n";
    const restored = try restorePrivateLinkage(std.testing.allocator, raw, extracted);
    defer std.testing.allocator.free(restored);
    try std.testing.expectEqualStrings(raw, restored);
}

test "accepted subset rejects malformed duplicate and unexpected linkage" {
    try std.testing.expectError(
        error.DuplicateDefinition,
        restorePrivateLinkage(
            std.testing.allocator,
            "define private i32 @same() { ret i32 1 }\ndefine internal i32 @same() { ret i32 2 }\n",
            "define hidden i32 @same() { ret i32 1 }\n",
        ),
    );
    try std.testing.expectError(
        error.LinkageMismatch,
        restorePrivateLinkage(
            std.testing.allocator,
            "define private i32 @same() { ret i32 1 }\n",
            "define protected i32 @same() { ret i32 1 }\n",
        ),
    );
    try std.testing.expectError(
        error.MalformedDefinition,
        restorePrivateLinkage(
            std.testing.allocator,
            "define private i32 @\"unterminated() { ret i32 1 }\n",
            "define hidden i32 @same() { ret i32 1 }\n",
        ),
    );
}
