const std = @import("std");
const core = @import("core.zig");
const structure = @import("structure.zig");
const fp_semantics = @import("../analysis/fp_semantics.zig");
const syntax = @import("parser_syntax.zig");
const findClosingQuote = syntax.findClosingQuote;
const findMatchingBracket = syntax.findMatchingBracket;
const findMatchingBrace = syntax.findMatchingBrace;
const findMatchingBracketOpen = syntax.findMatchingBracketOpen;
const findMatchingBraceOpen = syntax.findMatchingBraceOpen;
const firstTokenFromEnd = syntax.firstTokenFromEnd;
const findMatchingAngle = syntax.findMatchingAngle;
const findMatchingAngleOpen = syntax.findMatchingAngleOpen;

pub fn isSupportedNamedTypeName(name: []const u8) bool {
    if (name.len <= 1 or name[0] != '%') return false;
    if (name[1] == '"') return name.len >= 3 and name[name.len - 1] == '"';
    for (name[1..]) |byte| switch (byte) {
        'a'...'z', 'A'...'Z', '0'...'9', '.', '_', '-' => {},
        else => return false,
    };
    return true;
}

pub fn isAddressSpaceToken(text: []const u8) bool {
    if (!std.mem.startsWith(u8, text, "addrspace(") or !std.mem.endsWith(u8, text, ")")) return false;
    const payload = text["addrspace(".len .. text.len - 1];
    if (payload.len == 0) return false;
    _ = std.fmt.parseInt(u32, payload, 10) catch return false;
    return true;
}

pub fn parseType(text: []const u8) !core.Type {
    const trimmed = std.mem.trim(u8, text, " \t");
    if (std.mem.eql(u8, trimmed, "void")) return .void;
    if (std.mem.eql(u8, trimmed, "ptr")) return .ptr;
    if (std.mem.eql(u8, trimmed, "half")) return .half;
    if (std.mem.eql(u8, trimmed, "float")) return .float;
    if (std.mem.eql(u8, trimmed, "double")) return .double;
    if (std.mem.eql(u8, trimmed, "x86_fp80")) return .x86_fp80;
    if (std.mem.eql(u8, trimmed, "fp128")) return .fp128;
    if (std.mem.eql(u8, trimmed, "metadata")) return .metadata;
    if (structure.Fields.init(trimmed) != null) return .{ .aggregate = trimmed };
    if (trimmed.len >= 2 and trimmed[0] == '<' and trimmed[trimmed.len - 1] == '>') return .{ .vector = try parseVectorType(trimmed) };
    if (trimmed.len >= 2 and ((trimmed[0] == '{' and trimmed[trimmed.len - 1] == '}') or
        (trimmed[0] == '[' and trimmed[trimmed.len - 1] == ']'))) return .{ .aggregate = trimmed };
    if (isSupportedNamedTypeName(trimmed)) return .{ .aggregate = trimmed };
    if (trimmed.len < 2 or trimmed[0] != 'i') return error.UnsupportedType;
    const bits = try std.fmt.parseInt(u16, trimmed[1..], 10);
    if (bits == 0) return error.UnsupportedType;
    return .{ .int = bits };
}

const ParsedLeadingType = struct {
    ty: core.Type,
    after: []const u8,
};

const ParsedTypedValue = struct {
    ty: core.Type,
    value: core.Value,
};

pub fn parseTypedValue(text: []const u8) !ParsedTypedValue {
    const typed = try parseLeadingType(text);
    return .{
        .ty = typed.ty,
        .value = try parseValue(typed.after),
    };
}

const ParsedTrailingType = struct {
    before: []const u8,
    ty: core.Type,
    after_ty_attrs: ?[]const u8 = null,
};

pub fn parseLeadingType(text: []const u8) !ParsedLeadingType {
    const trimmed = std.mem.trim(u8, text, " \t");
    if (trimmed.len == 0) return error.UnsupportedType;
    if (trimmed[0] == '<') {
        const close = findMatchingAngle(trimmed, 0) orelse return error.UnsupportedType;
        return .{
            .ty = try parseType(trimmed[0 .. close + 1]),
            .after = std.mem.trim(u8, trimmed[close + 1 ..], " \t"),
        };
    }
    if (trimmed[0] == '{') {
        const close = findMatchingBrace(trimmed, 0) orelse return error.UnsupportedType;
        return .{
            .ty = try parseType(trimmed[0 .. close + 1]),
            .after = std.mem.trim(u8, trimmed[close + 1 ..], " \t"),
        };
    }
    if (trimmed[0] == '[') {
        const close = findMatchingBracket(trimmed, 0) orelse return error.UnsupportedType;
        return .{
            .ty = try parseType(trimmed[0 .. close + 1]),
            .after = std.mem.trim(u8, trimmed[close + 1 ..], " \t"),
        };
    }
    if (trimmed.len >= 2 and trimmed[0] == '%' and trimmed[1] == '"') {
        const close = findClosingQuote(trimmed, 1) orelse return error.UnsupportedType;
        return .{
            .ty = try parseType(trimmed[0 .. close + 1]),
            .after = std.mem.trim(u8, trimmed[close + 1 ..], " \t"),
        };
    }
    const end = std.mem.indexOfAny(u8, trimmed, " \t") orelse trimmed.len;
    return .{
        .ty = try parseType(trimmed[0..end]),
        .after = std.mem.trim(u8, trimmed[end..], " \t"),
    };
}

pub fn parseTrailingType(text: []const u8) !ParsedTrailingType {
    const trimmed = std.mem.trim(u8, text, " \t");
    if (trimmed.len == 0) return error.UnsupportedType;
    if (firstTokenFromEnd(trimmed)) |last_token| {
        if (isAddressSpaceToken(last_token)) {
            const before_addrspace = std.mem.trim(u8, trimmed[0 .. @intFromPtr(last_token.ptr) - @intFromPtr(trimmed.ptr)], " \t");
            if (firstTokenFromEnd(before_addrspace)) |ptr_token| {
                if (std.mem.eql(u8, ptr_token, "ptr")) {
                    return .{
                        .before = std.mem.trim(u8, before_addrspace[0 .. @intFromPtr(ptr_token.ptr) - @intFromPtr(before_addrspace.ptr)], " \t"),
                        .ty = .ptr,
                        .after_ty_attrs = last_token,
                    };
                }
            }
        }
    }
    if (trimmed[trimmed.len - 1] == '>') {
        const open = findMatchingAngleOpen(trimmed, trimmed.len - 1) orelse return error.UnsupportedType;
        return .{
            .before = std.mem.trim(u8, trimmed[0..open], " \t"),
            .ty = try parseType(trimmed[open..]),
        };
    }
    if (trimmed[trimmed.len - 1] == '}') {
        const open = findMatchingBraceOpen(trimmed, trimmed.len - 1) orelse return error.UnsupportedType;
        return .{
            .before = std.mem.trim(u8, trimmed[0..open], " \t"),
            .ty = try parseType(trimmed[open..]),
        };
    }
    if (trimmed[trimmed.len - 1] == ']') {
        const open = findMatchingBracketOpen(trimmed, trimmed.len - 1) orelse return error.UnsupportedType;
        return .{
            .before = std.mem.trim(u8, trimmed[0..open], " \t"),
            .ty = try parseType(trimmed[open..]),
        };
    }
    const start = std.mem.lastIndexOfAny(u8, trimmed, " \t");
    return .{
        .before = if (start) |index| std.mem.trim(u8, trimmed[0..index], " \t") else "",
        .ty = try parseType(if (start) |index| trimmed[index + 1 ..] else trimmed),
    };
}

pub fn parseVectorType(text: []const u8) !core.VectorType {
    const body = std.mem.trim(u8, text[1 .. text.len - 1], " \t");
    if (std.mem.startsWith(u8, body, "vscale")) return error.UnsupportedType;
    const x_index = std.mem.indexOf(u8, body, " x ") orelse return error.UnsupportedType;
    const len = try std.fmt.parseInt(u32, std.mem.trim(u8, body[0..x_index], " \t"), 10);
    if (len == 0) return error.UnsupportedType;
    const elem_ty = try parseVectorElementType(std.mem.trim(u8, body[x_index + 3 ..], " \t"));
    return .{ .len = len, .elem_ty = elem_ty };
}

pub fn parseVectorElementType(text: []const u8) !core.VectorElementType {
    if (std.mem.eql(u8, text, "ptr")) return .ptr;
    if (std.mem.eql(u8, text, "half")) return .half;
    if (std.mem.eql(u8, text, "float")) return .float;
    if (std.mem.eql(u8, text, "double")) return .double;
    if (std.mem.eql(u8, text, "x86_fp80")) return .x86_fp80;
    if (std.mem.eql(u8, text, "fp128")) return .fp128;
    if (text.len < 2 or text[0] != 'i') return error.UnsupportedType;
    const bits = try std.fmt.parseInt(u16, text[1..], 10);
    if (bits == 0) return error.UnsupportedType;
    return .{ .int = bits };
}

pub fn parseValue(text: []const u8) !core.Value {
    const trimmed = std.mem.trim(u8, text, " \t");
    if (trimmed.len == 0) return error.InvalidValue;
    if (std.mem.eql(u8, trimmed, "undef")) return .undef;
    if (std.mem.eql(u8, trimmed, "poison")) return .poison;
    if (std.mem.eql(u8, trimmed, "null")) return .null_value;
    if (std.mem.eql(u8, trimmed, "zeroinitializer")) return .zero_initializer;
    if (std.mem.eql(u8, trimmed, "true")) return .{ .int = 1 };
    if (std.mem.eql(u8, trimmed, "false")) return .{ .int = 0 };
    if (structure.Fields.init(trimmed) != null) return .{ .constant_expr = trimmed };
    if ((trimmed[0] == '<' and trimmed[trimmed.len - 1] == '>') or
        (std.mem.startsWith(u8, trimmed, "splat (") and std.mem.endsWith(u8, trimmed, ")")))
    {
        return .{ .vector = trimmed };
    }
    if (isSupportedConstantExpr(trimmed)) return .{ .constant_expr = trimmed };
    if (trimmed[0] == '%') {
        if (trimmed.len == 1) return error.InvalidValueName;
        return .{ .named = trimmed[1..] };
    }
    if (trimmed[0] == '@') {
        if (trimmed.len == 1) return error.InvalidValueName;
        return .{ .named = trimmed };
    }
    if (trimmed[0] == '!') {
        if (trimmed.len == 1) return error.InvalidValueName;
        return .{ .named = trimmed };
    }
    if (isFpLiteral(trimmed)) return .{ .fp = trimmed };
    return .{ .int = try std.fmt.parseInt(i128, trimmed, 10) };
}

pub fn isSupportedConstantExpr(text: []const u8) bool {
    if (structure.Fields.init(text) != null) return true;
    return (std.mem.startsWith(u8, text, "inttoptr (") or
        std.mem.startsWith(u8, text, "ptrtoint (") or
        std.mem.startsWith(u8, text, "sub (") or
        std.mem.startsWith(u8, text, "getelementptr ")) and
        std.mem.endsWith(u8, text, ")");
}

pub fn isFpLiteral(text: []const u8) bool {
    return fp_semantics.looksLikeFpLiteral(text);
}
