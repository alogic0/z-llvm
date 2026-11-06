//! Machine symbols contain LLVM hexadecimal escapes. Legacy lowering removes
//! outer quotes; composed lowering retains them. Resolve both spellings to the
//! same object-file bytes, decoding exactly once at the MC boundary.
const std = @import("std");

const Bytes = struct {
    text: []const u8,
    index: usize = 0,

    fn init(name: []const u8) !Bytes {
        var text = name;
        if (text.len >= 2 and text[0] == '"' and text[text.len - 1] == '"')
            text = text[1 .. text.len - 1];
        if (text.len == 0) return error.InvalidSymbolName;
        var i: usize = 0;
        while (i < text.len) : (i += 1) switch (text[i]) {
            0, '"', '\r', '\n' => return error.InvalidSymbolName,
            '\\' => {
                if (text.len - i < 3) return error.InvalidSymbolName;
                const value = std.fmt.parseInt(u8, text[i + 1 ..][0..2], 16) catch return error.InvalidSymbolName;
                for (text[i + 1 ..][0..2]) |digit| if (!std.ascii.isHex(digit)) return error.InvalidSymbolName;
                if (value == 0) return error.InvalidSymbolName;
                i += 2;
            },
            else => {},
        };
        return .{ .text = text };
    }

    fn next(self: *Bytes) ?u8 {
        if (self.index == self.text.len) return null;
        const byte = self.text[self.index];
        self.index += 1;
        if (byte != '\\') return byte;
        const value = std.fmt.parseInt(u8, self.text[self.index..][0..2], 16) catch unreachable;
        self.index += 2;
        return value;
    }
};

pub const Context = struct {
    pub fn hash(_: Context, name: []const u8) u64 {
        var bytes = Bytes.init(name) catch return std.hash.Wyhash.hash(0, name);
        var result = std.hash.Wyhash.init(0);
        while (bytes.next()) |byte| result.update(&.{byte});
        return result.final();
    }

    pub fn eql(_: Context, left: []const u8, right: []const u8) bool {
        var a = Bytes.init(left) catch return std.mem.eql(u8, left, right);
        var b = Bytes.init(right) catch return std.mem.eql(u8, left, right);
        while (a.next()) |byte| if (byte != (b.next() orelse return false)) return false;
        return b.next() == null;
    }
};

pub const Index = std.HashMap([]const u8, u32, Context, std.hash_map.default_max_load_percentage);

pub fn append(allocator: std.mem.Allocator, output: *std.ArrayList(u8), name: []const u8) !void {
    var bytes = try Bytes.init(name);
    while (bytes.next()) |byte| try output.append(allocator, byte);
}

test "object symbols share quoted escaped and legacy identities and decode once" {
    const context: Context = .{};
    for ([_][2][]const u8{
        .{ "helper", "\"hel\\70er\"" },
        .{ "array_list.Aligned(u8,null).append", "\"array_list.Aligned(u8,null).append\"" },
        .{ "type.\\22union\\22", "\"type.\\22union\\22\"" },
    }) |pair| {
        try std.testing.expect(context.eql(pair[0], pair[1]));
        try std.testing.expectEqual(context.hash(pair[0]), context.hash(pair[1]));
    }
    var output: std.ArrayList(u8) = .empty;
    defer output.deinit(std.testing.allocator);
    try append(std.testing.allocator, &output, "\"quote\\22-backslash\\5C31\"");
    try std.testing.expectEqualStrings("quote\"-backslash\\31", output.items);
    for ([_][]const u8{ "", "\"\"", "\"bad\\00name\"", "\"bad\\q0\"", "\"bad\\+1\"", "\"bad\\0\"", "\"unfinished", "nul\x00name" }) |name|
        try std.testing.expectError(error.InvalidSymbolName, append(std.testing.allocator, &output, name));
}
