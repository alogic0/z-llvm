//! Reference discovery for a bounded constant grammar, not constant folding or
//! a semantic type verifier. Unsupported operators, tokens and excessive nesting
//! return incomplete coverage. Visitors receive borrowed symbol spellings.
const std = @import("std");
const ir = @import("../ir.zig");
const Cursor = @import("reference_syntax.zig").Cursor;

pub const max_depth = 64;
pub const Kind = enum { integer, floating, pointer, array, structure, vector, named };

pub fn value(text: []const u8, ty: ir.Type, visitor: anytype) @TypeOf(visitor).Error!bool {
    const kind: Kind = switch (ty) {
        .int => .integer,
        .half, .float, .double, .x86_fp80, .fp128 => .floating,
        .ptr => .pointer,
        .vector => .vector,
        .aggregate => |raw| blk: {
            var type_cursor: Cursor = .{ .text = raw };
            const result = typeName(&type_cursor, 0) orelse return false;
            if (!type_cursor.done()) return false;
            break :blk result;
        },
        .void, .metadata => return false,
    };
    var cursor: Cursor = .{ .text = text };
    return try untyped(&cursor, kind, visitor, 0) and cursor.done();
}

pub fn typed(cursor: *Cursor, visitor: anytype, depth: usize) @TypeOf(visitor).Error!bool {
    const kind = typeName(cursor, depth) orelse return false;
    return untyped(cursor, kind, visitor, depth);
}

pub fn typeName(cursor: *Cursor, depth: usize) ?Kind {
    if (depth >= max_depth) return null;
    if (cursor.take('%')) {
        _ = cursor.identifier() orelse return null;
        return .named;
    }
    if (cursor.take('[')) {
        _ = cursor.number(u64) orelse return null;
        if (!cursor.keyword("x")) return null;
        _ = typeName(cursor, depth + 1) orelse return null;
        return if (cursor.take(']')) .array else null;
    }
    if (cursor.take('{')) return if (typeList(cursor, depth + 1)) .structure else null;
    if (cursor.take('<')) {
        if (cursor.take('{')) {
            return if (typeList(cursor, depth + 1) and cursor.take('>')) .structure else null;
        }
        const count = cursor.number(u32) orelse return null;
        if (count == 0 or !cursor.keyword("x")) return null;
        const element = typeName(cursor, depth + 1) orelse return null;
        if (element != .integer and element != .floating and element != .pointer) return null;
        return if (cursor.take('>')) .vector else null;
    }
    const word = cursor.word() orelse return null;
    if (std.mem.eql(u8, word, "ptr")) {
        if (cursor.keyword("addrspace")) {
            if (!cursor.take('(')) return null;
            _ = cursor.number(u32) orelse return null;
            if (!cursor.take(')')) return null;
        }
        return .pointer;
    }
    if (word.len > 1 and word[0] == 'i') {
        for (word[1..]) |byte| if (!std.ascii.isDigit(byte)) return null;
        const bits = std.fmt.parseInt(u32, word[1..], 10) catch return null;
        return if (bits > 0 and bits <= 1 << 23) .integer else null;
    }
    if (oneOf(word, &.{ "half", "bfloat", "float", "double", "x86_fp80", "fp128", "ppc_fp128" })) return .floating;
    return null;
}

fn typeList(cursor: *Cursor, depth: usize) bool {
    if (cursor.take('}')) return true;
    while (true) {
        _ = typeName(cursor, depth) orelse return false;
        if (cursor.take('}')) return true;
        if (!cursor.take(',')) return false;
    }
}

fn untyped(cursor: *Cursor, kind: Kind, visitor: anytype, depth: usize) @TypeOf(visitor).Error!bool {
    if (depth >= max_depth) return false;
    if (cursor.take('@')) {
        if (kind != .pointer) return false;
        const name = cursor.identifier() orelse return false;
        try visitor.symbol(name);
        return true;
    }
    if (cursor.keyword("null")) return kind == .pointer;
    if (cursor.keyword("undef") or cursor.keyword("poison") or cursor.keyword("zeroinitializer")) return true;
    if (cursor.keyword("getelementptr")) {
        var flags: u3 = 0;
        while (true) {
            const flag: u3 = if (cursor.keyword("inbounds")) 1 else if (cursor.keyword("nuw")) 2 else if (cursor.keyword("nusw")) 4 else break;
            if (flags & flag != 0) return false;
            flags |= flag;
        }
        if (!cursor.take('(')) return false;
        _ = typeName(cursor, depth + 1) orelse return false;
        if (!cursor.take(',') or !try typed(cursor, visitor, depth + 1)) return false;
        while (cursor.take(',')) {
            if (!try typed(cursor, visitor, depth + 1)) return false;
        }
        return cursor.take(')');
    }
    const saved = cursor.index;
    if (cursor.word()) |opcode| {
        if (oneOf(opcode, &.{ "bitcast", "addrspacecast", "ptrtoint", "inttoptr", "trunc", "zext", "sext", "fptrunc", "fpext", "fptoui", "fptosi", "uitofp", "sitofp" })) {
            if (!cursor.take('(') or !try typed(cursor, visitor, depth + 1) or !cursor.keyword("to")) return false;
            _ = typeName(cursor, depth + 1) orelse return false;
            return cursor.take(')');
        }
    }
    cursor.index = saved;
    if (kind == .array or kind == .named) {
        if (cursor.keyword("c")) return cursor.byteString() != null;
        if (cursor.take('[')) return valueList(cursor, ']', visitor, depth + 1);
    }
    if (kind == .structure or kind == .named) {
        if (cursor.take('{')) return valueList(cursor, '}', visitor, depth + 1);
        if (cursor.take('<')) {
            if (!cursor.take('{')) return false;
            return try valueList(cursor, '}', visitor, depth + 1) and cursor.take('>');
        }
    }
    if (kind == .vector and cursor.take('<')) return valueList(cursor, '>', visitor, depth + 1);
    if (kind == .integer) {
        if (cursor.keyword("true") or cursor.keyword("false")) return true;
        return cursor.integer() != null;
    }
    if (kind == .floating) return floating(cursor);
    return false;
}

fn valueList(cursor: *Cursor, close: u8, visitor: anytype, depth: usize) @TypeOf(visitor).Error!bool {
    if (cursor.take(close)) return true;
    while (true) {
        if (!try typed(cursor, visitor, depth)) return false;
        if (cursor.take(close)) return true;
        if (!cursor.take(',')) return false;
    }
}

fn floating(cursor: *Cursor) bool {
    cursor.whitespace();
    const start = cursor.index;
    while (!cursor.boundary()) : (cursor.index += 1) {}
    const token = cursor.text[start..cursor.index];
    if (token.len == 0) return false;
    if (token.len == 18 and std.mem.startsWith(u8, token, "0x")) {
        for (token[2..]) |byte| if (!std.ascii.isHex(byte)) return false;
        return true;
    }
    if (!std.ascii.isDigit(token[0]) and token[0] != '-' and token[0] != '+') return false;
    _ = std.fmt.parseFloat(f64, token) catch return false;
    return true;
}

pub fn oneOf(word: []const u8, choices: []const []const u8) bool {
    for (choices) |choice| if (std.mem.eql(u8, word, choice)) return true;
    return false;
}
