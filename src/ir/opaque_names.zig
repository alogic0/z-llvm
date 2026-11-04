//! Tokens needed to preserve local spelling in opaque IR text. This is not
//! general reference analysis: only blockaddress's closed grammar is decoded.
const std = @import("std");

pub const BlockAddress = struct {
    function: []const u8,
    block: []const u8,
    block_start: usize,
    block_end: usize,
};

pub const Token = union(enum) { local: []const u8, block_address: BlockAddress };
pub const Error = error{UnsupportedOpaqueNameSyntax};

pub const Iterator = struct {
    raw: []const u8,
    index: usize = 0,

    pub fn next(it: *Iterator) Error!?Token {
        while (it.index < it.raw.len) {
            const byte = it.raw[it.index];
            if (byte == '"') {
                _ = try it.identifier();
            } else if (byte == '!') {
                it.index += 1;
                if (it.index < it.raw.len and (it.raw[it.index] == '"' or identifierByte(it.raw[it.index]))) _ = try it.identifier();
            } else if (byte == '%' or byte == '@') {
                it.index += 1;
                const name = try it.identifier();
                if (byte == '%') return .{ .local = name };
            } else if (identifierByte(byte)) {
                const start = it.index;
                while (it.index < it.raw.len and identifierByte(it.raw[it.index])) : (it.index += 1) {}
                if (!std.mem.eql(u8, it.raw[start..it.index], "blockaddress")) continue;
                try it.punctuation('(');
                try it.punctuation('@');
                const function = try it.identifier();
                try it.punctuation(',');
                try it.punctuation('%');
                const block_start = it.index;
                const block = try it.identifier();
                const block_end = it.index;
                try it.punctuation(')');
                return .{ .block_address = .{ .function = function, .block = block, .block_start = block_start, .block_end = block_end } };
            } else {
                it.index += 1;
            }
        }
        return null;
    }

    fn punctuation(it: *Iterator, expected: u8) Error!void {
        while (it.index < it.raw.len and std.ascii.isWhitespace(it.raw[it.index])) : (it.index += 1) {}
        if (it.index == it.raw.len or it.raw[it.index] != expected) return error.UnsupportedOpaqueNameSyntax;
        it.index += 1;
    }

    fn identifier(it: *Iterator) Error![]const u8 {
        const start = it.index;
        if (start == it.raw.len) return error.UnsupportedOpaqueNameSyntax;
        if (it.raw[start] == '"') {
            it.index += 1;
            while (it.index < it.raw.len) {
                const byte = it.raw[it.index];
                it.index += 1;
                if (byte == '\\') {
                    if (it.index == it.raw.len) return error.UnsupportedOpaqueNameSyntax;
                    it.index += 1;
                } else if (byte == '"') return it.raw[start..it.index];
            }
            return error.UnsupportedOpaqueNameSyntax;
        }
        while (it.index < it.raw.len and identifierByte(it.raw[it.index])) : (it.index += 1) {}
        if (it.index == start) return error.UnsupportedOpaqueNameSyntax;
        return it.raw[start..it.index];
    }
};

fn identifierByte(byte: u8) bool {
    return std.ascii.isAlphanumeric(byte) or byte == '_' or byte == '-' or byte == '$' or byte == '.';
}
