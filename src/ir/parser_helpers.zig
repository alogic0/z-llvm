const std = @import("std");
const core = @import("core.zig");
const fp_semantics = @import("../analysis/fp_semantics.zig");

pub fn isDebugRecord(line: []const u8) bool {
    return std.mem.startsWith(u8, line, "#dbg_");
}

pub fn parseModuleAsm(line: []const u8) !void {
    const rest = std.mem.trim(u8, line["module asm".len..], " \t");
    if (rest.len < 2 or rest[0] != '"') return error.InvalidModuleAsm;

    var escaped = false;
    for (rest[1..], 1..) |byte, index| {
        if (escaped) {
            escaped = false;
            continue;
        }
        if (byte == '\\') {
            escaped = true;
            continue;
        }
        if (byte == '"') {
            const tail = std.mem.trim(u8, rest[index + 1 ..], " \t");
            if (tail.len != 0) return error.InvalidModuleAsm;
            return;
        }
    }
    return error.InvalidModuleAsm;
}

pub fn parseNamedTypeDefinition(line: []const u8) !core.NamedTypeDefinition {
    const eq_index = findAssignmentSeparator(line) orelse return error.InvalidNamedTypeDefinition;
    const name = std.mem.trim(u8, line[0..eq_index], " \t");
    if (!isSupportedNamedTypeName(name)) return error.UnsupportedNamedTypeDefinition;

    const rest = std.mem.trim(u8, line[eq_index + 1 ..], " \t");
    if (!std.mem.startsWith(u8, rest, "type ")) return error.InvalidNamedTypeDefinition;
    const body = std.mem.trim(u8, rest["type ".len..], " \t");
    if (body.len == 0) return error.InvalidNamedTypeDefinition;
    if (!((body[0] == '{' and body[body.len - 1] == '}') or
        (body.len >= 3 and std.mem.startsWith(u8, body, "<{") and std.mem.endsWith(u8, body, "}>"))))
    {
        return error.UnsupportedNamedTypeDefinition;
    }

    return .{
        .name = name[1..],
        .body = body,
        .raw = line,
    };
}

pub fn isSupportedNamedTypeName(name: []const u8) bool {
    if (name.len <= 1 or name[0] != '%') return false;
    if (name[1] == '"') return name.len >= 3 and name[name.len - 1] == '"';
    for (name[1..]) |byte| switch (byte) {
        'a'...'z', 'A'...'Z', '0'...'9', '.', '_', '-' => {},
        else => return false,
    };
    return true;
}

pub fn parseComdat(line: []const u8) !void {
    const eq_index = std.mem.indexOfScalar(u8, line, '=') orelse return error.InvalidComdat;
    const name = std.mem.trim(u8, line[0..eq_index], " \t");
    if (name.len <= 1 or name[0] != '$') return error.InvalidComdat;

    var parts = std.mem.tokenizeAny(u8, std.mem.trim(u8, line[eq_index + 1 ..], " \t"), " \t");
    if (!std.mem.eql(u8, parts.next() orelse return error.InvalidComdat, "comdat")) return error.InvalidComdat;
    const kind = parts.next() orelse return error.InvalidComdat;
    if (!isSupportedComdatKind(kind)) return error.UnsupportedComdat;
    if (parts.next() != null) return error.InvalidComdat;
}

pub fn isSupportedComdatKind(kind: []const u8) bool {
    return std.mem.eql(u8, kind, "any") or
        std.mem.eql(u8, kind, "exactmatch") or
        std.mem.eql(u8, kind, "largest") or
        std.mem.eql(u8, kind, "nodeduplicate") or
        std.mem.eql(u8, kind, "samesize");
}

pub fn parseGlobalAlias(line: []const u8) !core.GlobalAlias {
    const eq_index = findAssignmentSeparator(line) orelse return error.NotGlobalAlias;
    const name_text = std.mem.trim(u8, line[0..eq_index], " \t");
    if (!std.mem.startsWith(u8, name_text, "@") or name_text.len == 1) return error.InvalidGlobalAlias;

    const rest = std.mem.trim(u8, line[eq_index + 1 ..], " \t");
    var parts = std.mem.tokenizeAny(u8, rest, " \t");
    var token = parts.next() orelse return error.NotGlobalAlias;

    const linkage = core.FunctionLinkage.parse(token) orelse .default;
    if (linkage != .default) token = parts.next() orelse return error.InvalidGlobalAlias;

    var visibility: core.FunctionVisibility = .default;
    if (core.FunctionVisibility.parse(token)) |parsed_visibility| {
        visibility = parsed_visibility;
        token = parts.next() orelse return error.InvalidGlobalAlias;
    }

    if (!std.mem.eql(u8, token, "alias")) return error.NotGlobalAlias;

    const alias_token_offset = @intFromPtr(token.ptr) - @intFromPtr(rest.ptr) + token.len;
    const alias_body = std.mem.trim(u8, rest[alias_token_offset..], " \t");
    const comma = findTopLevelComma(alias_body) orelse return error.InvalidGlobalAlias;
    const aliased_ty = std.mem.trim(u8, alias_body[0..comma], " \t");
    if (aliased_ty.len == 0) return error.InvalidGlobalAlias;

    const target_text = std.mem.trim(u8, alias_body[comma + 1 ..], " \t");
    const parsed_target = try parseLeadingType(target_text);
    const target_ty = parsed_target.ty;
    if (target_ty != .ptr) return error.UnsupportedGlobalAlias;
    const target_name = std.mem.trim(u8, parsed_target.after, " \t");
    if (!isSupportedGlobalIdentifier(target_name)) return error.UnsupportedGlobalAlias;

    return .{
        .name = name_text[1..],
        .linkage = linkage,
        .visibility = visibility,
        .aliased_ty = aliased_ty,
        .target_ty = target_ty,
        .target = target_name[1..],
    };
}

pub fn isSupportedGlobalIdentifier(text: []const u8) bool {
    if (!std.mem.startsWith(u8, text, "@") or text.len == 1) return false;
    if (text[1] == '"') return text.len >= 3 and text[text.len - 1] == '"';
    return std.mem.indexOfAny(u8, text, " \t") == null;
}

pub fn parseGlobal(module: *core.Module, line: []const u8) !core.Global {
    const eq_index = findAssignmentSeparator(line) orelse return error.UnsupportedGlobalVariable;
    const name_text = std.mem.trim(u8, line[0..eq_index], " \t");
    if (!std.mem.startsWith(u8, name_text, "@") or name_text.len == 1) return error.InvalidGlobalVariable;

    const rest = std.mem.trim(u8, line[eq_index + 1 ..], " \t");
    var parts = std.mem.tokenizeAny(u8, rest, " \t");
    var token = parts.next() orelse return error.UnsupportedGlobalVariable;

    const linkage = core.FunctionLinkage.parse(token) orelse .default;
    if (linkage != .default) token = parts.next() orelse return error.UnsupportedGlobalVariable;

    const address_attrs_start: ?usize = if (isGlobalAddressAttr(token))
        @intFromPtr(token.ptr) - @intFromPtr(rest.ptr)
    else
        null;
    while (isGlobalAddressAttr(token)) {
        token = parts.next() orelse return error.UnsupportedGlobalVariable;
    }
    const address_attrs = if (address_attrs_start) |start|
        std.mem.trim(u8, rest[start..(@intFromPtr(token.ptr) - @intFromPtr(rest.ptr))], " \t")
    else
        "";

    const kind = core.GlobalKind.parse(token) orelse return error.UnsupportedGlobalVariable;
    const kind_end = @intFromPtr(token.ptr) - @intFromPtr(rest.ptr) + token.len;
    const after_kind = std.mem.trim(u8, rest[kind_end..], " \t");
    const parsed_ty = parseGlobalTypePrefix(after_kind) catch return error.UnsupportedGlobalVariable;
    const ty = parsed_ty.ty;

    const initializer_and_attrs = std.mem.trim(u8, parsed_ty.rest, " \t");
    const comma = findTopLevelComma(initializer_and_attrs);
    const initializer_text = std.mem.trim(u8, if (comma) |index|
        initializer_and_attrs[0..index]
    else
        initializer_and_attrs, " \t");
    const attrs = if (comma) |index|
        std.mem.trim(u8, initializer_and_attrs[index + 1 ..], " \t")
    else
        "";

    var initializer = parseGlobalInitializer(module.allocator, ty, initializer_text) catch return error.UnsupportedGlobalVariable;
    errdefer initializer.deinit(module.allocator);
    return .{
        .name = name_text[1..],
        .linkage = linkage,
        .address_attrs = if (address_attrs.len == 0) null else address_attrs,
        .kind = kind,
        .ty = ty,
        .initializer = initializer,
        .attrs = if (attrs.len == 0) null else attrs,
    };
}

const ParsedGlobalType = struct {
    ty: core.Type,
    rest: []const u8,
};

pub fn parseGlobalTypePrefix(text: []const u8) !ParsedGlobalType {
    const trimmed = std.mem.trim(u8, text, " \t");
    if (trimmed.len == 0) return error.UnsupportedGlobalVariable;
    if (trimmed[0] == '<') {
        const close = findMatchingAngle(trimmed, 0) orelse return error.UnsupportedGlobalVariable;
        return .{
            .ty = try parseType(trimmed[0 .. close + 1]),
            .rest = trimmed[close + 1 ..],
        };
    }
    if (trimmed[0] == '[') {
        const close = findMatchingBracket(trimmed, 0) orelse return error.UnsupportedGlobalVariable;
        return .{
            .ty = try parseType(trimmed[0 .. close + 1]),
            .rest = trimmed[close + 1 ..],
        };
    }
    if (trimmed[0] == '{') {
        const close = findMatchingBrace(trimmed, 0) orelse return error.UnsupportedGlobalVariable;
        return .{
            .ty = try parseType(trimmed[0 .. close + 1]),
            .rest = trimmed[close + 1 ..],
        };
    }
    if (trimmed.len >= 2 and trimmed[0] == '%' and trimmed[1] == '"') {
        const close = findClosingQuote(trimmed, 1) orelse return error.UnsupportedGlobalVariable;
        return .{
            .ty = try parseType(trimmed[0 .. close + 1]),
            .rest = trimmed[close + 1 ..],
        };
    }

    const end = std.mem.indexOfAny(u8, trimmed, " \t,") orelse trimmed.len;
    return .{
        .ty = try parseType(trimmed[0..end]),
        .rest = trimmed[end..],
    };
}

pub fn isGlobalAddressAttr(token: []const u8) bool {
    return std.mem.eql(u8, token, "unnamed_addr") or
        std.mem.eql(u8, token, "local_unnamed_addr") or
        std.mem.eql(u8, token, "hidden") or
        std.mem.eql(u8, token, "protected") or
        std.mem.eql(u8, token, "dso_local") or
        std.mem.eql(u8, token, "dso_preemptable") or
        std.mem.eql(u8, token, "thread_local") or
        std.mem.startsWith(u8, token, "thread_local(");
}

pub fn parseGlobalInitializer(allocator: std.mem.Allocator, ty: core.Type, text: []const u8) !core.GlobalInitializer {
    if (text.len == 0) return .none;
    if (ty == .aggregate and std.mem.startsWith(u8, text, "c\"") and std.mem.endsWith(u8, text, "\"")) {
        return .{ .c_string = text };
    }
    if (ty == .aggregate and std.mem.startsWith(u8, text, "[") and std.mem.endsWith(u8, text, "]")) {
        const array = parseGlobalArrayInitializer(allocator, ty, text) catch return core.GlobalInitializer{ .@"opaque" = text };
        return .{ .array = array };
    }

    if (ty == .aggregate and std.mem.indexOfAny(u8, text, " \t") != null) return .{ .@"opaque" = text };
    if (isSupportedConstantExpr(text)) return .{ .scalar = .{ .constant_expr = text } };
    if (ty == .vector and std.mem.startsWith(u8, text, "<") and std.mem.endsWith(u8, text, ">")) {
        return .{ .scalar = .{ .vector = text } };
    }
    if (std.mem.indexOfAny(u8, text, " \t") != null) return error.UnsupportedGlobalVariable;
    const value = try parseValue(text);
    return switch (value) {
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr, .named => .{ .scalar = value },
    };
}

pub fn parseGlobalArrayInitializer(allocator: std.mem.Allocator, ty: core.Type, text: []const u8) !core.GlobalArrayInitializer {
    const array_ty = parseArrayType(ty) orelse return error.UnsupportedGlobalVariable;
    var initializer: core.GlobalArrayInitializer = .{
        .elem_ty = array_ty.elem_ty,
        .values = .empty,
    };
    errdefer initializer.deinit(allocator);

    var rest = std.mem.trim(u8, text[1 .. text.len - 1], " \t");
    while (rest.len != 0) {
        const comma = findTopLevelComma(rest);
        const item = std.mem.trim(u8, if (comma) |index| rest[0..index] else rest, " \t");
        var item_parts = std.mem.tokenizeAny(u8, item, " \t");
        const elem_ty = try parseType(item_parts.next() orelse return error.UnsupportedGlobalVariable);
        if (!elem_ty.eql(array_ty.elem_ty)) return error.UnsupportedGlobalVariable;
        const value = try parseValue(item_parts.next() orelse return error.UnsupportedGlobalVariable);
        if (item_parts.next() != null) return error.UnsupportedGlobalVariable;
        switch (value) {
            .int, .undef, .poison, .null_value => try initializer.values.append(allocator, value),
            .named, .fp, .zero_initializer, .vector, .constant_expr => return error.UnsupportedGlobalVariable,
        }
        rest = if (comma) |index| std.mem.trim(u8, rest[index + 1 ..], " \t") else "";
    }

    if (initializer.values.items.len != array_ty.len) return error.UnsupportedGlobalVariable;
    return initializer;
}

const ParsedArrayType = struct {
    len: usize,
    elem_ty: core.Type,
};

pub fn parseArrayType(ty: core.Type) ?ParsedArrayType {
    const text = switch (ty) {
        .aggregate => |aggregate| aggregate,
        .void, .int, .half, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .vector => return null,
    };
    if (text.len < 5 or text[0] != '[' or text[text.len - 1] != ']') return null;
    const body = std.mem.trim(u8, text[1 .. text.len - 1], " \t");
    const x_index = std.mem.indexOf(u8, body, " x ") orelse return null;
    const len = std.fmt.parseInt(usize, std.mem.trim(u8, body[0..x_index], " \t"), 10) catch return null;
    const elem_ty = parseType(std.mem.trim(u8, body[x_index + 3 ..], " \t")) catch return null;
    return .{ .len = len, .elem_ty = elem_ty };
}

pub fn parseAttributeGroup(line: []const u8) !void {
    var rest = std.mem.trim(u8, line["attributes ".len..], " \t");
    if (!std.mem.startsWith(u8, rest, "#")) return error.InvalidAttributeGroup;
    rest = rest[1..];

    const group_end = std.mem.indexOfAny(u8, rest, " \t") orelse return error.InvalidAttributeGroup;
    _ = try std.fmt.parseInt(u32, rest[0..group_end], 10);
    rest = std.mem.trim(u8, rest[group_end..], " \t");
    if (!std.mem.startsWith(u8, rest, "=")) return error.InvalidAttributeGroup;
    rest = std.mem.trim(u8, rest[1..], " \t");
    if (rest.len < 2 or rest[0] != '{' or rest[rest.len - 1] != '}') return error.InvalidAttributeGroup;

    const body = rest[1 .. rest.len - 1];
    if (hasUnsupportedSanitizerAttribute(body)) return error.UnsupportedAttributeGroup;
    if (std.mem.indexOf(u8, body, "safestack") != null) return error.UnsupportedAttributeGroup;
    if (std.mem.indexOf(u8, body, "shadowcallstack") != null) return error.UnsupportedAttributeGroup;
}

pub fn hasUnsupportedSanitizerAttribute(body: []const u8) bool {
    var it = std.mem.tokenizeAny(u8, body, " \t,{}");
    while (it.next()) |token| {
        if (std.mem.eql(u8, token, "nosanitize_coverage")) continue;
        if (std.mem.startsWith(u8, token, "sanitize_")) return true;
    }
    return false;
}

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

pub fn parseModuleStringRecord(line: []const u8, key: []const u8) ![]const u8 {
    if (!std.mem.startsWith(u8, line, key)) return error.InvalidModuleRecord;
    var rest = std.mem.trim(u8, line[key.len..], " \t");
    if (!std.mem.startsWith(u8, rest, "=")) return error.InvalidModuleRecord;
    rest = std.mem.trim(u8, rest[1..], " \t");
    if (rest.len < 2 or rest[0] != '"' or rest[rest.len - 1] != '"') return error.InvalidModuleRecord;
    return rest[1 .. rest.len - 1];
}

pub fn findMatchingParen(text: []const u8, open_index: usize) ?usize {
    if (open_index >= text.len or text[open_index] != '(') return null;
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
        if (byte == '(') {
            depth += 1;
        } else if (byte == ')') {
            depth -= 1;
            if (depth == 0) return index;
        }
    }
    return null;
}

pub fn findOpenParenOutsideString(text: []const u8, start_index: usize) ?usize {
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
        if (byte == '(') return index;
    }
    return null;
}

pub fn findMatchingBracket(text: []const u8, open_index: usize) ?usize {
    if (open_index >= text.len or text[open_index] != '[') return null;
    var depth: usize = 0;
    for (text[open_index..], open_index..) |byte, index| {
        if (byte == '[') {
            depth += 1;
        } else if (byte == ']') {
            depth -= 1;
            if (depth == 0) return index;
        }
    }
    return null;
}

pub fn findMatchingBrace(text: []const u8, open_index: usize) ?usize {
    if (open_index >= text.len or text[open_index] != '{') return null;
    var depth: usize = 0;
    for (text[open_index..], open_index..) |byte, index| {
        if (byte == '{') {
            depth += 1;
        } else if (byte == '}') {
            depth -= 1;
            if (depth == 0) return index;
        }
    }
    return null;
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

pub fn parseFunctionHeader(allocator: std.mem.Allocator, line: []const u8) !core.Function {
    if (!std.mem.endsWith(u8, line, "{")) return error.InvalidFunctionHeader;
    const body = std.mem.trim(u8, line["define ".len .. line.len - 1], " \t");
    const name_start = std.mem.indexOfScalar(u8, body, '@') orelse return error.InvalidFunctionHeader;
    const open_paren = findOpenParenOutsideString(body, name_start) orelse return error.InvalidFunctionHeader;
    const close_paren = findMatchingParen(body, open_paren) orelse return error.InvalidFunctionHeader;
    if (close_paren < open_paren) return error.InvalidFunctionHeader;

    const prefix = std.mem.trim(u8, body[0..name_start], " \t");
    const parsed_prefix = try parseFunctionPrefix(prefix, error.InvalidFunctionHeader);
    const name_text = std.mem.trim(u8, body[name_start..open_paren], " \t");
    if (!std.mem.startsWith(u8, name_text, "@")) return error.InvalidFunctionName;

    var function = core.Function.init(name_text[1..], parsed_prefix.ret_ty);
    function.linkage = parsed_prefix.linkage;
    function.visibility = parsed_prefix.visibility;
    function.calling_conv = parsed_prefix.calling_conv;
    function.ret_attrs = parsed_prefix.ret_attrs;
    const attrs = std.mem.trim(u8, body[close_paren + 1 ..], " \t");
    if (containsUnsupportedEhFunctionAttr(attrs)) return error.UnsupportedExceptionHandling;
    if (attrs.len != 0) function.attrs = attrs;
    errdefer function.deinit(allocator);

    try parseFunctionParams(allocator, &function, body[open_paren + 1 .. close_paren]);

    return function;
}

pub fn parseFunctionDecl(allocator: std.mem.Allocator, line: []const u8) !core.FunctionDecl {
    const body = std.mem.trim(u8, line["declare ".len..], " \t");
    const name_start = std.mem.indexOfScalar(u8, body, '@') orelse return error.InvalidFunctionDeclaration;
    const open_paren = findOpenParenOutsideString(body, name_start) orelse return error.InvalidFunctionDeclaration;
    const close_paren = findMatchingParen(body, open_paren) orelse return error.InvalidFunctionDeclaration;
    if (close_paren < open_paren) return error.InvalidFunctionDeclaration;

    const prefix = std.mem.trim(u8, body[0..name_start], " \t");
    const parsed_prefix = try parseFunctionPrefix(prefix, error.InvalidFunctionDeclaration);
    const name_text = std.mem.trim(u8, body[name_start..open_paren], " \t");
    if (!std.mem.startsWith(u8, name_text, "@")) return error.InvalidFunctionName;
    if (isUnsupportedDebugIntrinsicCallee(name_text[1..])) return error.UnsupportedDebugIntrinsic;

    var decl = core.FunctionDecl.init(name_text[1..], parsed_prefix.ret_ty);
    decl.linkage = parsed_prefix.linkage;
    decl.visibility = parsed_prefix.visibility;
    decl.calling_conv = parsed_prefix.calling_conv;
    decl.ret_attrs = parsed_prefix.ret_attrs;
    const attrs = std.mem.trim(u8, body[close_paren + 1 ..], " \t");
    if (containsUnsupportedEhFunctionAttr(attrs)) return error.UnsupportedExceptionHandling;
    if (attrs.len != 0) decl.attrs = attrs;
    errdefer decl.deinit(allocator);

    try parseDeclParams(allocator, &decl, body[open_paren + 1 .. close_paren]);

    return decl;
}

const FunctionPrefix = struct {
    linkage: core.FunctionLinkage = .default,
    visibility: core.FunctionVisibility = .default,
    calling_conv: ?[]const u8 = null,
    ret_attrs: ?[]const u8 = null,
    ret_ty: core.Type,
};

pub fn parseFunctionPrefix(prefix: []const u8, comptime invalid_error: anyerror) !FunctionPrefix {
    const typed_prefix = parseTrailingType(prefix) catch return invalid_error;
    var rest = typed_prefix.before;

    var parsed: FunctionPrefix = .{ .ret_ty = typed_prefix.ty };
    if (firstToken(rest)) |token| {
        if (core.FunctionLinkage.parse(token)) |linkage| {
            parsed.linkage = linkage;
            rest = trimFirstToken(rest);
        }
    }
    if (firstToken(rest)) |token| {
        if (core.FunctionVisibility.parse(token)) |visibility| {
            parsed.visibility = visibility;
            rest = trimFirstToken(rest);
        }
    }
    if (firstToken(rest)) |token| {
        if (core.isSupportedCallingConvention(token)) {
            parsed.calling_conv = token;
            rest = trimFirstToken(rest);
        }
    }
    if (rest.len != 0 and typed_prefix.after_ty_attrs != null) return invalid_error;
    if (rest.len != 0) {
        parsed.ret_attrs = rest;
    } else if (typed_prefix.after_ty_attrs) |attrs| {
        parsed.ret_attrs = attrs;
    }
    return parsed;
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

pub fn parseDeclParams(allocator: std.mem.Allocator, decl: *core.FunctionDecl, text: []const u8) !void {
    const params_text = std.mem.trim(u8, text, " \t");
    if (params_text.len == 0) return;
    if (std.mem.eql(u8, params_text, "...")) {
        decl.is_varargs = true;
        return;
    }

    var rest = params_text;
    while (rest.len != 0) {
        const comma = findTopLevelComma(rest);
        const raw_param = if (comma) |index| rest[0..index] else rest;
        const param_text = std.mem.trim(u8, raw_param, " \t");
        if (std.mem.eql(u8, param_text, "...")) {
            decl.is_varargs = true;
            rest = if (comma) |index| std.mem.trim(u8, rest[index + 1 ..], " \t") else "";
            if (rest.len != 0) return error.UnsupportedVarArgs;
            break;
        }
        const parsed_ty = try parseLeadingType(param_text);
        var parts = std.mem.tokenizeAny(u8, parsed_ty.after, " \t");
        const attrs_start = if (parts.next()) |part| @intFromPtr(part.ptr) - @intFromPtr(param_text.ptr) else null;
        if (attrs_start) |start| {
            try decl.params.append(allocator, .{
                .ty = parsed_ty.ty,
                .attrs = std.mem.trim(u8, param_text[start..], " \t"),
            });
        } else {
            try decl.params.append(allocator, .{ .ty = parsed_ty.ty });
        }
        rest = if (comma) |index| std.mem.trim(u8, rest[index + 1 ..], " \t") else "";
    }
}

pub fn implicitEntryBlockName(module: *core.Module, function: core.Function, first_line: []const u8) ![]const u8 {
    if (numericResultName(first_line)) |first_result| {
        if (first_result > 0) return try module.ownString(try std.fmt.allocPrint(module.allocator, "{}", .{first_result - 1}));
    }

    var max_numeric_param: ?usize = null;
    for (function.params.items) |param| {
        const number = std.fmt.parseInt(usize, param.name, 10) catch continue;
        if (max_numeric_param == null or number > max_numeric_param.?) max_numeric_param = number;
    }
    const max_param = max_numeric_param orelse return "0";
    return try module.ownString(try std.fmt.allocPrint(module.allocator, "{}", .{max_param + 1}));
}

pub fn numericResultName(line: []const u8) ?usize {
    const eq_index = findAssignmentSeparator(line) orelse return null;
    const result_text = std.mem.trim(u8, line[0..eq_index], " \t");
    if (result_text.len < 2 or result_text[0] != '%') return null;
    return std.fmt.parseInt(usize, result_text[1..], 10) catch null;
}

pub fn parseFunctionParams(allocator: std.mem.Allocator, function: *core.Function, text: []const u8) !void {
    const params_text = std.mem.trim(u8, text, " \t");
    if (params_text.len != 0) {
        var rest = params_text;
        while (rest.len != 0) {
            const comma = findTopLevelComma(rest);
            const raw_param = if (comma) |index| rest[0..index] else rest;
            const param_text = std.mem.trim(u8, raw_param, " \t");
            const parsed_ty = try parseLeadingType(param_text);
            var parts = std.mem.tokenizeAny(u8, parsed_ty.after, " \t");
            var param_attrs_start: ?usize = null;
            var param_name_token: ?[]const u8 = null;
            while (parts.next()) |part| {
                if (std.mem.startsWith(u8, part, "%")) {
                    param_name_token = part;
                    continue;
                }
                if (param_attrs_start == null) {
                    param_attrs_start = @intFromPtr(part.ptr) - @intFromPtr(param_text.ptr);
                }
            }
            const param_name = param_name_token orelse return error.InvalidParameter;
            if (!std.mem.startsWith(u8, param_name, "%")) return error.InvalidValueName;
            const param_attrs = if (param_attrs_start) |start|
                std.mem.trim(u8, param_text[start..(@intFromPtr(param_name.ptr) - @intFromPtr(param_text.ptr))], " \t")
            else
                "";
            try function.params.append(allocator, .{
                .ty = parsed_ty.ty,
                .attrs = if (param_attrs.len == 0) null else param_attrs,
                .name = param_name[1..],
            });
            rest = if (comma) |index| std.mem.trim(u8, rest[index + 1 ..], " \t") else "";
        }
    }
}

pub fn parseInstruction(allocator: std.mem.Allocator, line: []const u8) !core.Instruction {
    const metadata_start = std.mem.indexOf(u8, line, ", !");
    const metadata = if (metadata_start) |index| std.mem.trim(u8, line[index + 2 ..], " \t") else null;
    const instruction_text = if (metadata_start) |index| std.mem.trim(u8, line[0..index], " \t") else line;
    if (metadata) |attachment| try validateInstructionMetadata(attachment);

    var instruction = try parseInstructionBody(allocator, instruction_text);
    instruction.metadata = metadata;
    return instruction;
}

pub fn validateInstructionMetadata(metadata: []const u8) !void {
    var rest = std.mem.trim(u8, metadata, " \t");
    while (rest.len != 0) {
        const comma = findTopLevelComma(rest);
        const attachment = std.mem.trim(u8, if (comma) |index| rest[0..index] else rest, " \t");
        if (!isSupportedInstructionMetadataAttachment(attachment)) return error.UnsupportedInstructionMetadata;
        rest = if (comma) |index| std.mem.trim(u8, rest[index + 1 ..], " \t") else "";
    }
}

pub fn isSupportedInstructionMetadataAttachment(attachment: []const u8) bool {
    const key = firstToken(attachment) orelse return false;
    if (attachment.len == key.len) return false;
    return std.mem.eql(u8, key, "!dbg") or
        std.mem.eql(u8, key, "!prof") or
        std.mem.eql(u8, key, "!tbaa") or
        std.mem.eql(u8, key, "!alias.scope") or
        std.mem.eql(u8, key, "!noalias") or
        std.mem.eql(u8, key, "!nonnull") or
        std.mem.eql(u8, key, "!noundef") or
        std.mem.eql(u8, key, "!unpredictable");
}

pub fn parseInstructionBody(allocator: std.mem.Allocator, line: []const u8) !core.Instruction {
    if (std.mem.startsWith(u8, line, "store ")) return parseStore(line);
    if (std.mem.startsWith(u8, line, "call ")) return parseCall(allocator, null, line);
    if (std.mem.startsWith(u8, line, "tail ") or std.mem.startsWith(u8, line, "musttail ") or std.mem.startsWith(u8, line, "notail ")) return parseCall(allocator, null, line);
    if (std.mem.startsWith(u8, line, "invoke ") or std.mem.startsWith(u8, line, "callbr ")) return error.UnsupportedCallTerminator;

    const eq_index = findAssignmentSeparator(line) orelse return error.InvalidInstruction;
    const result_text = std.mem.trim(u8, line[0..eq_index], " \t");
    if (!std.mem.startsWith(u8, result_text, "%")) return error.InvalidValueName;

    const rhs_text = std.mem.trim(u8, line[eq_index + 1 ..], " \t");
    if (std.mem.startsWith(u8, rhs_text, "call ")) return parseCall(allocator, result_text[1..], rhs_text);
    if (std.mem.startsWith(u8, rhs_text, "tail ") or std.mem.startsWith(u8, rhs_text, "musttail ") or std.mem.startsWith(u8, rhs_text, "notail ")) return parseCall(allocator, result_text[1..], rhs_text);
    if (std.mem.startsWith(u8, rhs_text, "invoke ") or std.mem.startsWith(u8, rhs_text, "callbr ")) return error.UnsupportedCallTerminator;
    if (isUnsupportedEhInstruction(rhs_text)) return error.UnsupportedExceptionHandling;
    if (std.mem.startsWith(u8, rhs_text, "phi ")) {
        return .{
            .result = result_text[1..],
            .kind = .{ .phi = try parsePhi(allocator, rhs_text) },
        };
    }
    if (std.mem.startsWith(u8, rhs_text, "alloca ")) {
        return .{
            .result = result_text[1..],
            .kind = .{ .alloca = try parseAlloca(rhs_text) },
        };
    }
    if (std.mem.startsWith(u8, rhs_text, "getelementptr ")) {
        return .{
            .result = result_text[1..],
            .kind = .{ .gep = try parseGep(allocator, rhs_text) },
        };
    }

    var parts = std.mem.tokenizeAny(u8, rhs_text, " \t,");
    const op_text = parts.next() orelse return error.InvalidInstruction;

    if (std.mem.eql(u8, op_text, "atomicrmw")) {
        return .{
            .result = result_text[1..],
            .kind = .{ .atomicrmw = try parseAtomicRmw(rhs_text) },
        };
    }
    if (std.mem.eql(u8, op_text, "cmpxchg")) {
        return .{
            .result = result_text[1..],
            .kind = .{ .cmpxchg = try parseCmpxchg(allocator, rhs_text) },
        };
    }
    if (std.mem.eql(u8, op_text, "extractelement")) {
        return .{
            .result = result_text[1..],
            .kind = .{ .extractelement = try parseExtractElement(rhs_text) },
        };
    }
    if (std.mem.eql(u8, op_text, "insertelement")) {
        return .{
            .result = result_text[1..],
            .kind = .{ .insertelement = try parseInsertElement(rhs_text) },
        };
    }
    if (std.mem.eql(u8, op_text, "shufflevector")) {
        return .{
            .result = result_text[1..],
            .kind = .{ .shufflevector = try parseShuffleVector(rhs_text) },
        };
    }
    if (std.mem.eql(u8, op_text, "extractvalue")) {
        return .{
            .result = result_text[1..],
            .kind = .{ .extractvalue = try parseExtractValue(rhs_text) },
        };
    }
    if (std.mem.eql(u8, op_text, "insertvalue")) {
        return .{
            .result = result_text[1..],
            .kind = .{ .insertvalue = try parseInsertValue(rhs_text) },
        };
    }

    if (core.CastOp.parse(op_text)) |op| {
        return .{
            .result = result_text[1..],
            .kind = .{ .cast = try parseCastInst(op, rhs_text) },
        };
    }

    if (std.mem.eql(u8, op_text, "freeze")) {
        const typed = try parseLeadingType(std.mem.trim(u8, rhs_text["freeze".len..], " \t"));
        return .{
            .result = result_text[1..],
            .kind = .{ .freeze = .{
                .ty = typed.ty,
                .value = try parseValue(typed.after),
            } },
        };
    }

    if (std.mem.eql(u8, op_text, "icmp")) {
        return .{
            .result = result_text[1..],
            .kind = .{ .icmp = try parseIcmp(rhs_text) },
        };
    }

    if (std.mem.eql(u8, op_text, "fcmp")) {
        return .{
            .result = result_text[1..],
            .kind = .{ .fcmp = try parseFcmp(rhs_text) },
        };
    }

    if (std.mem.eql(u8, op_text, "fneg")) {
        return .{
            .result = result_text[1..],
            .kind = .{ .binary = try parseFnegInst(std.mem.trim(u8, rhs_text[op_text.len..], " \t")) },
        };
    }

    if (std.mem.eql(u8, op_text, "select")) {
        const select = try parseSelect(rhs_text);
        return .{
            .result = result_text[1..],
            .kind = .{ .select = .{
                .cond_ty = select.cond_ty,
                .cond = select.cond,
                .ty = select.ty,
                .true_value = select.true_value,
                .false_value = select.false_value,
            } },
        };
    }

    if (std.mem.eql(u8, op_text, "load")) {
        return parseLoad(result_text[1..], rhs_text);
    }

    const op = core.BinaryOp.parse(op_text) orelse return error.UnsupportedInstruction;
    const binary = try parseBinaryInst(op, std.mem.trim(u8, rhs_text[op_text.len..], " \t"));

    return .{
        .result = result_text[1..],
        .kind = .{ .binary = binary },
    };
}

pub fn parseFnegInst(text: []const u8) !core.BinaryInst {
    var rest = std.mem.trim(u8, text, " \t");
    var fp_flags: core.FastMathFlags = .{};
    while (firstToken(rest)) |token| {
        if (!isFastMathFlagToken(token)) break;
        try setFastMathFlag(&fp_flags, token);
        rest = trimFirstToken(rest);
    }

    const typed = try parseLeadingType(rest);
    return .{
        .op = .fsub,
        .fp_flags = fp_flags,
        .ty = typed.ty,
        .lhs = negativeZeroForFneg(typed.ty),
        .rhs = try parseValue(typed.after),
    };
}

fn negativeZeroForFneg(ty: core.Type) core.Value {
    return switch (ty) {
        .vector => |vector| switch (vector.elem_ty) {
            .half => .{ .vector = "splat (half -0.000000e+00)" },
            .float => .{ .vector = "splat (float -0.000000e+00)" },
            .double => .{ .vector = "splat (double -0.000000e+00)" },
            .fp128 => .{ .vector = "splat (fp128 -0.000000e+00)" },
            .int, .ptr => .{ .fp = "-0.000000e+00" },
        },
        .void, .int, .half, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .aggregate => .{ .fp = "-0.000000e+00" },
    };
}

pub fn isCastFlag(text: []const u8) bool {
    return std.mem.eql(u8, text, "nneg") or
        std.mem.eql(u8, text, "nsw") or
        std.mem.eql(u8, text, "nuw");
}

pub fn isUnsupportedCastFlag(text: []const u8) bool {
    return std.mem.eql(u8, text, "exact") or
        std.mem.eql(u8, text, "disjoint") or
        isFastMathFlagToken(text);
}

pub fn parseCastInst(op: core.CastOp, text: []const u8) !core.CastInst {
    var rest = std.mem.trim(u8, text, " \t");
    const op_token = firstToken(rest) orelse return error.InvalidInstruction;
    rest = std.mem.trim(u8, rest[op_token.len..], " \t");

    var flags: core.CastFlags = .{};
    while (firstToken(rest)) |token| {
        if (std.mem.eql(u8, token, "nneg")) {
            if (flags.nneg) return error.InvalidInstructionFlag;
            flags.nneg = true;
        } else if (std.mem.eql(u8, token, "nsw")) {
            if (flags.nsw) return error.InvalidInstructionFlag;
            flags.nsw = true;
        } else if (std.mem.eql(u8, token, "nuw")) {
            if (flags.nuw) return error.InvalidInstructionFlag;
            flags.nuw = true;
        } else if (isUnsupportedCastFlag(token)) {
            return error.InvalidInstructionFlag;
        } else {
            break;
        }
        rest = trimFirstToken(rest);
    }

    const from = try parseLeadingType(rest);
    const to_index = findTopLevelTo(from.after) orelse return error.InvalidInstruction;
    const value_text = std.mem.trim(u8, from.after[0..to_index], " \t");
    const to_ty = try parseType(std.mem.trim(u8, from.after[to_index + " to ".len ..], " \t"));
    if (value_text.len == 0) return error.InvalidInstruction;
    return .{
        .op = op,
        .flags = flags,
        .from_ty = from.ty,
        .value = try parseValue(value_text),
        .to_ty = to_ty,
    };
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

pub fn parseCastFlags(parts: *std.mem.TokenIterator(u8, .any)) !core.CastFlags {
    var flags: core.CastFlags = .{};
    while (parts.peek()) |token| {
        if (std.mem.eql(u8, token, "nneg")) {
            if (flags.nneg) return error.InvalidInstructionFlag;
            _ = parts.next();
            flags.nneg = true;
            continue;
        }
        if (std.mem.eql(u8, token, "nsw")) {
            if (flags.nsw) return error.InvalidInstructionFlag;
            _ = parts.next();
            flags.nsw = true;
            continue;
        }
        if (std.mem.eql(u8, token, "nuw")) {
            if (flags.nuw) return error.InvalidInstructionFlag;
            _ = parts.next();
            flags.nuw = true;
            continue;
        }
        if (isUnsupportedCastFlag(token)) return error.InvalidInstructionFlag;
        return flags;
    }
    return flags;
}

pub fn parseBinaryInst(op: core.BinaryOp, text: []const u8) !core.BinaryInst {
    var rest = std.mem.trim(u8, text, " \t");
    var flags: core.BinaryFlags = .{};
    var fp_flags: core.FastMathFlags = .{};
    while (firstToken(rest)) |token| {
        if (std.mem.eql(u8, token, "nsw")) {
            if (flags.nsw) return error.InvalidInstruction;
            flags.nsw = true;
        } else if (std.mem.eql(u8, token, "nuw")) {
            if (flags.nuw) return error.InvalidInstruction;
            flags.nuw = true;
        } else if (std.mem.eql(u8, token, "exact")) {
            if (flags.exact) return error.InvalidInstruction;
            flags.exact = true;
        } else if (std.mem.eql(u8, token, "disjoint")) {
            if (flags.disjoint) return error.InvalidInstruction;
            flags.disjoint = true;
        } else if (isFastMathFlagToken(token)) {
            try setFastMathFlag(&fp_flags, token);
        } else {
            break;
        }
        rest = trimFirstToken(rest);
    }

    const typed = try parseLeadingType(rest);
    rest = std.mem.trim(u8, typed.after, " \t");
    const comma = findTopLevelComma(rest) orelse return error.InvalidInstruction;
    const lhs = try parseValue(std.mem.trim(u8, rest[0..comma], " \t"));
    const rhs = try parseValue(std.mem.trim(u8, rest[comma + 1 ..], " \t"));

    return .{
        .op = op,
        .flags = flags,
        .fp_flags = fp_flags,
        .ty = typed.ty,
        .lhs = lhs,
        .rhs = rhs,
    };
}

pub fn parseIcmp(text: []const u8) !core.IcmpInst {
    var rest = std.mem.trim(u8, text["icmp".len..], " \t");
    const samesign = if (firstToken(rest)) |token| blk: {
        if (!std.mem.eql(u8, token, "samesign")) break :blk false;
        rest = trimFirstToken(rest);
        break :blk true;
    } else return error.InvalidInstruction;

    const predicate_text = firstToken(rest) orelse return error.InvalidInstruction;
    const predicate = core.IcmpPredicate.parse(predicate_text) orelse return error.UnsupportedPredicate;
    rest = trimFirstToken(rest);

    const typed = try parseLeadingType(rest);
    rest = std.mem.trim(u8, typed.after, " \t");
    const comma = findTopLevelComma(rest) orelse return error.InvalidInstruction;
    return .{
        .predicate = predicate,
        .samesign = samesign,
        .operand_ty = typed.ty,
        .lhs = try parseValue(std.mem.trim(u8, rest[0..comma], " \t")),
        .rhs = try parseValue(std.mem.trim(u8, rest[comma + 1 ..], " \t")),
    };
}

pub fn parseFcmp(text: []const u8) !core.FcmpInst {
    var rest = std.mem.trim(u8, text["fcmp".len..], " \t");
    var fp_flags: core.FastMathFlags = .{};
    while (firstToken(rest)) |token| {
        if (!isFastMathFlagToken(token)) break;
        try setFastMathFlag(&fp_flags, token);
        rest = trimFirstToken(rest);
    }

    const predicate_text = firstToken(rest) orelse return error.InvalidInstruction;
    const predicate = core.FcmpPredicate.parse(predicate_text) orelse return error.UnsupportedPredicate;
    rest = trimFirstToken(rest);

    const typed = try parseLeadingType(rest);
    rest = std.mem.trim(u8, typed.after, " \t");
    const comma = findTopLevelComma(rest) orelse return error.InvalidInstruction;
    return .{
        .fp_flags = fp_flags,
        .predicate = predicate,
        .operand_ty = typed.ty,
        .lhs = try parseValue(std.mem.trim(u8, rest[0..comma], " \t")),
        .rhs = try parseValue(std.mem.trim(u8, rest[comma + 1 ..], " \t")),
    };
}

pub fn isUnsupportedEhTerminator(line: []const u8) bool {
    return std.mem.startsWith(u8, line, "resume ") or
        std.mem.startsWith(u8, line, "catchswitch ") or
        std.mem.startsWith(u8, line, "catchret ") or
        std.mem.startsWith(u8, line, "cleanupret ");
}

pub fn isUnsupportedEhInstruction(text: []const u8) bool {
    return std.mem.startsWith(u8, text, "landingpad ") or
        std.mem.startsWith(u8, text, "catchpad ") or
        std.mem.startsWith(u8, text, "cleanuppad ");
}

pub fn containsUnsupportedEhFunctionAttr(attrs: []const u8) bool {
    var it = std.mem.tokenizeAny(u8, attrs, " \t");
    while (it.next()) |token| {
        if (std.mem.eql(u8, token, "personality")) return true;
    }
    return false;
}

pub fn parseAlloca(text: []const u8) !core.AllocaInst {
    const rest = std.mem.trim(u8, text["alloca ".len..], " \t");
    const comma = findTopLevelComma(rest);
    const ty_text = std.mem.trim(u8, if (comma) |index| rest[0..index] else rest, " \t");
    if (ty_text.len == 0) return error.InvalidInstruction;
    const allocated_ty = try parseAddressSpaceQualifiedType(ty_text);
    return .{
        .allocated_ty = allocated_ty.ty,
        .allocated_ty_addrspace = allocated_ty.addrspace_text,
        .attrs = if (comma) |index| std.mem.trim(u8, rest[index + 1 ..], " \t") else null,
    };
}

pub fn parseGep(allocator: std.mem.Allocator, text: []const u8) !core.GepInst {
    var rest = std.mem.trim(u8, text["getelementptr ".len..], " \t");
    rest = stripGepPrefixes(rest);
    const source_end = findTopLevelComma(rest) orelse return error.InvalidGetElementPtr;
    var gep: core.GepInst = .{
        .source_ty = try parseType(std.mem.trim(u8, rest[0..source_end], " \t")),
        .ptr = undefined,
        .indices = .empty,
    };
    errdefer gep.deinit(allocator);

    rest = std.mem.trim(u8, rest[source_end + 1 ..], " \t");
    const ptr_end = findTopLevelComma(rest) orelse return error.InvalidGetElementPtr;
    const ptr_text = std.mem.trim(u8, rest[0..ptr_end], " \t");
    const ptr_arg = try parseLeadingType(ptr_text);
    if (ptr_arg.ty != .ptr) return error.ExpectedPointerType;
    var ptr_value_text = std.mem.trim(u8, ptr_arg.after, " \t");
    if (ptr_value_text.len == 0) return error.InvalidGetElementPtr;
    if (firstToken(ptr_value_text)) |token| {
        if (isAddressSpaceToken(token)) {
            gep.ptr_addrspace = token;
            ptr_value_text = trimFirstToken(ptr_value_text);
        }
    }
    if (ptr_value_text.len == 0) return error.InvalidGetElementPtr;
    gep.ptr = try parseValue(ptr_value_text);

    rest = std.mem.trim(u8, rest[ptr_end + 1 ..], " \t");
    while (rest.len != 0) {
        const next_comma = findTopLevelComma(rest);
        const item = std.mem.trim(u8, if (next_comma) |index| rest[0..index] else rest, " \t");
        var index_parts = std.mem.tokenizeAny(u8, item, " \t");
        const index_ty = try parseType(index_parts.next() orelse return error.InvalidGetElementPtr);
        const index_value = try parseValue(index_parts.next() orelse return error.InvalidGetElementPtr);
        if (index_parts.next() != null) return error.InvalidGetElementPtr;
        try gep.indices.append(allocator, .{
            .ty = index_ty,
            .value = index_value,
        });

        if (next_comma) |index| {
            rest = std.mem.trim(u8, rest[index + 1 ..], " \t");
        } else {
            rest = "";
        }
    }
    if (gep.indices.items.len == 0) return error.InvalidGetElementPtr;
    return gep;
}

pub fn stripGepPrefixes(text: []const u8) []const u8 {
    var rest = std.mem.trim(u8, text, " \t");
    while (true) {
        const token = firstToken(rest) orelse return rest;
        if (std.mem.eql(u8, token, "inbounds") or
            std.mem.eql(u8, token, "nuw") or
            std.mem.eql(u8, token, "nusw"))
        {
            rest = trimFirstToken(rest);
            continue;
        }
        return rest;
    }
}

pub fn parseCall(allocator: std.mem.Allocator, result: ?[]const u8, text: []const u8) !core.Instruction {
    var call_text = std.mem.trim(u8, text, " \t");
    const tail_kind: ?[]const u8 = if (std.mem.startsWith(u8, call_text, "tail ")) blk: {
        call_text = std.mem.trim(u8, call_text["tail ".len..], " \t");
        break :blk "tail";
    } else if (std.mem.startsWith(u8, call_text, "musttail ")) blk: {
        call_text = std.mem.trim(u8, call_text["musttail ".len..], " \t");
        break :blk "musttail";
    } else if (std.mem.startsWith(u8, call_text, "notail ")) blk: {
        call_text = std.mem.trim(u8, call_text["notail ".len..], " \t");
        break :blk "notail";
    } else null;
    if (!std.mem.startsWith(u8, call_text, "call ")) return error.InvalidCall;

    var rest = std.mem.trim(u8, call_text["call ".len..], " \t");
    const prefix_token = firstToken(rest) orelse return error.InvalidCall;
    const calling_conv: ?[]const u8 = if (core.isSupportedCallingConvention(prefix_token)) blk: {
        rest = trimFirstToken(rest);
        break :blk prefix_token;
    } else null;

    const ret = try parseCallReturnPrefix(rest);
    if (ret.after.len == 0) return error.InvalidCall;
    const ret_ty = ret.ty;
    rest = ret.after;

    const callee_function_ty: ?[]const u8 = if (rest.len != 0 and rest[0] == '(') blk: {
        const close = findMatchingParen(rest, 0) orelse return error.InvalidCall;
        const function_ty = rest[0 .. close + 1];
        rest = std.mem.trim(u8, rest[close + 1 ..], " \t");
        break :blk function_ty;
    } else null;

    const open_paren = findOpenParenOutsideString(rest, 0) orelse return error.InvalidCall;
    const close_paren = findMatchingParen(rest, open_paren) orelse return error.InvalidCall;
    const callee_text = std.mem.trim(u8, rest[0..open_paren], " \t");
    const inline_asm = if (std.mem.startsWith(u8, callee_text, "asm "))
        try parseInlineAsm(callee_text)
    else
        null;
    const callee_value: ?core.Value = if (inline_asm == null and !std.mem.startsWith(u8, callee_text, "@"))
        try parseValue(callee_text)
    else
        null;
    if (inline_asm == null) {
        if (std.mem.startsWith(u8, callee_text, "asm")) return error.UnsupportedInlineAsm;
        if (callee_value == null) {
            if (isUnsupportedDebugIntrinsicCallee(callee_text[1..])) return error.UnsupportedDebugIntrinsic;
            if (isUnsupportedInstrumentationCallee(callee_text[1..])) return error.UnsupportedInstrumentationCall;
        }
    }
    const trailing = try parseCallTrailing(rest[close_paren + 1 ..]);

    var call: core.CallInst = .{
        .ret_ty = ret_ty,
        .callee = if (inline_asm == null and callee_value == null) callee_text[1..] else "",
        .callee_value = callee_value,
        .callee_function_ty = callee_function_ty,
        .calling_conv = calling_conv,
        .ret_attrs = ret.attrs,
        .tail_kind = tail_kind,
        .inline_asm = inline_asm,
        .attrs = trailing.attrs,
        .operand_bundle = trailing.operand_bundle,
        .raw_args = null,
        .args = .empty,
    };
    errdefer call.deinit(allocator);

    const args_text = rest[open_paren + 1 .. close_paren];
    if (inline_asm == null and isSupportedDebugIntrinsicCallee(call.callee)) {
        if (call.calling_conv != null or call.ret_attrs != null or call.tail_kind != null or call.attrs != null or call.operand_bundle != null or call.ret_ty != .void or result != null) {
            return error.UnsupportedDebugIntrinsic;
        }
        try validateDebugIntrinsicArgs(call.callee, args_text);
        call.raw_args = args_text;
    } else {
        try parseCallArgs(allocator, &call, args_text);
    }

    return .{
        .result = result,
        .kind = .{ .call = call },
    };
}

const ParsedCallReturnPrefix = struct {
    ty: core.Type,
    attrs: ?[]const u8 = null,
    after: []const u8,
};

pub fn parseCallReturnPrefix(text: []const u8) !ParsedCallReturnPrefix {
    const original = std.mem.trim(u8, text, " \t");
    var rest = original;
    while (rest.len != 0) {
        if (parseLeadingType(rest)) |typed| {
            const attrs_len = @intFromPtr(rest.ptr) - @intFromPtr(original.ptr);
            const attrs = std.mem.trim(u8, original[0..attrs_len], " \t");
            return .{
                .ty = typed.ty,
                .attrs = if (attrs.len == 0) null else attrs,
                .after = typed.after,
            };
        } else |err| switch (err) {
            error.UnsupportedType => {},
            else => return err,
        }

        const token_end = findTopLevelTokenEnd(rest) orelse return error.UnsupportedType;
        if (token_end == 0) return error.UnsupportedType;
        rest = std.mem.trim(u8, rest[token_end..], " \t");
    }
    return error.UnsupportedType;
}

const CallTrailing = struct {
    attrs: ?[]const u8 = null,
    operand_bundle: ?[]const u8 = null,
};

pub fn parseCallTrailing(text: []const u8) !CallTrailing {
    var rest = std.mem.trim(u8, text, " \t");
    var trailing: CallTrailing = .{};

    if (rest.len == 0) return trailing;

    if (rest[0] == '#') {
        const attrs = firstToken(rest) orelse return error.UnsupportedCallAttribute;
        if (!isSupportedCallAttributeRef(attrs)) return error.UnsupportedCallAttribute;
        trailing.attrs = attrs;
        rest = std.mem.trim(u8, rest[attrs.len..], " \t");
    }

    if (rest.len == 0) return trailing;
    if (rest[0] != '[') return error.UnsupportedCallAttribute;

    try validateCallOperandBundle(rest);
    trailing.operand_bundle = rest;
    return trailing;
}

pub fn isSupportedCallAttributeRef(text: []const u8) bool {
    if (text.len < 2 or text[0] != '#') return false;
    for (text[1..]) |byte| {
        if (!std.ascii.isDigit(byte)) return false;
    }
    return true;
}

pub fn validateCallOperandBundle(text: []const u8) !void {
    const trimmed = std.mem.trim(u8, text, " \t");
    if (trimmed.len < 2 or trimmed[0] != '[') return error.UnsupportedOperandBundle;
    const close = findMatchingBracket(trimmed, 0) orelse return error.UnsupportedOperandBundle;
    if (close + 1 != trimmed.len) return error.UnsupportedOperandBundle;

    var rest = std.mem.trim(u8, trimmed[1..close], " \t");
    if (rest.len == 0) return error.UnsupportedOperandBundle;
    while (rest.len != 0) {
        const comma = findTopLevelComma(rest);
        const bundle = std.mem.trim(u8, if (comma) |index| rest[0..index] else rest, " \t");
        try validateCallOperandBundleEntry(bundle);
        rest = if (comma) |index| std.mem.trim(u8, rest[index + 1 ..], " \t") else "";
    }
}

pub fn validateCallOperandBundleEntry(text: []const u8) !void {
    var rest = std.mem.trim(u8, text, " \t");
    const tag = parseQuotedPrefix(&rest) orelse return error.UnsupportedOperandBundle;
    if (tag.len == 0) return error.UnsupportedOperandBundle;

    rest = std.mem.trim(u8, rest, " \t");
    if (rest.len == 0 or rest[0] != '(') return error.UnsupportedOperandBundle;
    const close = findMatchingParen(rest, 0) orelse return error.UnsupportedOperandBundle;
    if (close + 1 != rest.len) return error.UnsupportedOperandBundle;
    if (std.mem.trim(u8, rest[1..close], " \t").len != 0) return error.UnsupportedOperandBundle;
}

pub fn parseInlineAsm(text: []const u8) !core.InlineAsm {
    var rest = std.mem.trim(u8, text["asm".len..], " \t");
    var sideeffect = false;
    if (std.mem.startsWith(u8, rest, "sideeffect")) {
        sideeffect = true;
        rest = std.mem.trim(u8, rest["sideeffect".len..], " \t");
    }

    const template = parseQuotedPrefix(&rest) orelse return error.UnsupportedInlineAsm;
    rest = std.mem.trim(u8, rest, " \t");
    if (rest.len == 0 or rest[0] != ',') return error.UnsupportedInlineAsm;
    rest = std.mem.trim(u8, rest[1..], " \t");
    const constraints = parseQuotedPrefix(&rest) orelse return error.UnsupportedInlineAsm;
    if (std.mem.trim(u8, rest, " \t").len != 0) return error.UnsupportedInlineAsm;

    const memory_effects = inlineAsmMemoryEffects(constraints);
    return .{
        .template = template,
        .constraints = constraints,
        .sideeffect = sideeffect,
        .has_memory_clobber = memory_effects.has_memory_clobber,
        .may_load = memory_effects.may_load,
        .may_store = memory_effects.may_store,
    };
}

const InlineAsmMemoryEffects = struct {
    has_memory_clobber: bool = false,
    may_load: bool = false,
    may_store: bool = false,
};

pub fn inlineAsmMemoryEffects(constraints: []const u8) InlineAsmMemoryEffects {
    var effects: InlineAsmMemoryEffects = .{};
    var rest = constraints;
    while (rest.len != 0) {
        const comma = findTopLevelComma(rest);
        const constraint = std.mem.trim(u8, if (comma) |index| rest[0..index] else rest, " \t");
        classifyInlineAsmConstraint(constraint, &effects);
        rest = if (comma) |index| std.mem.trim(u8, rest[index + 1 ..], " \t") else "";
    }
    return effects;
}

pub fn classifyInlineAsmConstraint(constraint: []const u8, effects: *InlineAsmMemoryEffects) void {
    if (std.mem.eql(u8, constraint, "~{memory}")) {
        effects.has_memory_clobber = true;
        effects.may_load = true;
        effects.may_store = true;
        return;
    }
    if (constraint.len == 0 or constraint[0] == '~') return;

    const writes = std.mem.indexOfScalar(u8, constraint, '=') != null or
        std.mem.indexOfScalar(u8, constraint, '+') != null;
    const reads = !writes or std.mem.indexOfScalar(u8, constraint, '+') != null;
    const start = inlineAsmConstraintCodeStart(constraint);
    if (hasInlineAsmMemoryConstraintCode(constraint[start..])) {
        if (reads) effects.may_load = true;
        if (writes) effects.may_store = true;
    }
}

pub fn inlineAsmConstraintCodeStart(constraint: []const u8) usize {
    var index: usize = 0;
    while (index < constraint.len) : (index += 1) {
        switch (constraint[index]) {
            '=', '+', '&', '*' => continue,
            else => return index,
        }
    }
    return index;
}

pub fn hasInlineAsmMemoryConstraintCode(text: []const u8) bool {
    var index: usize = 0;
    while (index < text.len) : (index += 1) {
        switch (text[index]) {
            'm', 'o', 'V' => return true,
            else => {},
        }
    }
    inline for (.{ "Um", "Un", "Uq", "Us", "Ut", "Uv", "Uy", "ZQ", "ZR", "ZS", "ZT" }) |code| {
        if (std.mem.indexOf(u8, text, code) != null) return true;
    }
    return false;
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

pub fn isUnsupportedInstrumentationCallee(name: []const u8) bool {
    return std.mem.startsWith(u8, name, "__sanitizer_") or
        std.mem.startsWith(u8, name, "__tsan_") or
        std.mem.startsWith(u8, name, "__ubsan_") or
        std.mem.startsWith(u8, name, "llvm.ubsan.");
}

pub fn isUnsupportedDebugIntrinsicCallee(name: []const u8) bool {
    return std.mem.startsWith(u8, name, "llvm.dbg.") and !isSupportedDebugIntrinsicCallee(name);
}

pub fn isSupportedDebugIntrinsicCallee(name: []const u8) bool {
    return std.mem.eql(u8, name, "llvm.dbg.value") or
        std.mem.eql(u8, name, "llvm.dbg.declare");
}

pub fn validateDebugIntrinsicArgs(callee: []const u8, text: []const u8) !void {
    const args_text = std.mem.trim(u8, text, " \t");
    var fields: [3][]const u8 = undefined;
    var field_count: usize = 0;
    var rest = args_text;
    while (rest.len != 0) {
        if (field_count == fields.len) return error.UnsupportedDebugIntrinsic;
        const comma = findTopLevelComma(rest);
        fields[field_count] = std.mem.trim(u8, if (comma) |index| rest[0..index] else rest, " \t");
        field_count += 1;
        rest = if (comma) |index| std.mem.trim(u8, rest[index + 1 ..], " \t") else "";
    }
    if (field_count != 3) return error.UnsupportedDebugIntrinsic;

    if (std.mem.eql(u8, callee, "llvm.dbg.value")) {
        if (!isDebugValueLocationOperand(fields[0])) return error.UnsupportedDebugIntrinsic;
    } else if (std.mem.eql(u8, callee, "llvm.dbg.declare")) {
        if (!isDebugDeclareLocationOperand(fields[0])) return error.UnsupportedDebugIntrinsic;
    } else {
        return error.UnsupportedDebugIntrinsic;
    }
    if (!isDebugMetadataReferenceOperand(fields[1])) return error.UnsupportedDebugIntrinsic;
    if (!isDebugExpressionOperand(fields[2])) return error.UnsupportedDebugIntrinsic;
}

pub fn isDebugValueLocationOperand(text: []const u8) bool {
    if (!std.mem.startsWith(u8, text, "metadata ")) return false;
    const rest = std.mem.trim(u8, text["metadata ".len..], " \t");
    if (std.mem.startsWith(u8, rest, "!")) return isDebugMetadataValue(rest);
    _ = parseTypedValue(rest) catch return false;
    return true;
}

pub fn isDebugDeclareLocationOperand(text: []const u8) bool {
    if (!std.mem.startsWith(u8, text, "metadata ")) return false;
    const rest = std.mem.trim(u8, text["metadata ".len..], " \t");
    if (std.mem.startsWith(u8, rest, "!")) return isDebugMetadataValue(rest);
    const typed = parseTypedValue(rest) catch return false;
    return typed.ty == .ptr;
}

pub fn isDebugMetadataReferenceOperand(text: []const u8) bool {
    if (!std.mem.startsWith(u8, text, "metadata ")) return false;
    return isDebugMetadataValue(std.mem.trim(u8, text["metadata ".len..], " \t"));
}

pub fn isDebugExpressionOperand(text: []const u8) bool {
    if (!std.mem.startsWith(u8, text, "metadata ")) return false;
    const rest = std.mem.trim(u8, text["metadata ".len..], " \t");
    return isDebugMetadataValue(rest) or std.mem.startsWith(u8, rest, "!DIExpression(");
}

pub fn isDebugMetadataValue(text: []const u8) bool {
    if (text.len < 2 or text[0] != '!') return false;
    for (text[1..]) |byte| {
        if (!std.ascii.isDigit(byte)) return false;
    }
    return true;
}

pub fn parseCallArgs(allocator: std.mem.Allocator, call: *core.CallInst, text: []const u8) !void {
    const args_text = std.mem.trim(u8, text, " \t");
    if (args_text.len == 0) return;
    if (std.mem.eql(u8, args_text, "...")) return error.UnsupportedVarArgs;

    var rest = args_text;
    while (rest.len != 0) {
        const comma = findTopLevelComma(rest);
        const raw_arg = if (comma) |index| rest[0..index] else rest;
        const arg_text = std.mem.trim(u8, raw_arg, " \t");
        if (std.mem.eql(u8, arg_text, "...")) return error.UnsupportedVarArgs;
        try call.args.append(allocator, try parseCallArg(arg_text));
        rest = if (comma) |index| std.mem.trim(u8, rest[index + 1 ..], " \t") else "";
    }
}

pub fn parseCallArg(text: []const u8) !core.CallArg {
    const typed = try parseLeadingType(text);
    if (typed.after.len == 0) return error.InvalidCall;
    if (callArgRemainderMayBeWholeValue(typed.after)) {
        if (parseValue(typed.after)) |value| {
            return .{
                .ty = typed.ty,
                .value = value,
            };
        } else |_| {}
    }

    if (!callArgMayContainAttrs(typed.after)) return error.InvalidCall;

    const value_start = findConstantExprValueStart(typed.after) orelse
        (findTrailingValueStart(typed.after) orelse return error.InvalidCall);
    if (value_start == 0) return error.InvalidCall;
    const attrs = std.mem.trim(u8, typed.after[0..value_start], " \t");
    const value_text = std.mem.trim(u8, typed.after[value_start..], " \t");
    if (attrs.len == 0 or value_text.len == 0) return error.InvalidCall;
    if (std.mem.indexOfAny(u8, value_text, " \t") != null and !isSupportedConstantExpr(value_text)) {
        return error.UnsupportedCallAttribute;
    }
    return .{
        .ty = typed.ty,
        .attrs = attrs,
        .value = try parseValue(value_text),
    };
}

pub fn findConstantExprValueStart(text: []const u8) ?usize {
    const needles = [_][]const u8{
        " inttoptr (",
        " ptrtoint (",
        " sub (",
        " getelementptr ",
    };
    for (needles) |needle| {
        if (std.mem.indexOf(u8, text, needle)) |index| return index + 1;
    }
    return null;
}

pub fn callArgRemainderMayBeWholeValue(text: []const u8) bool {
    const trimmed = std.mem.trim(u8, text, " \t");
    if (trimmed.len == 0) return false;
    if (trimmed[0] == '%' or trimmed[0] == '@' or trimmed[0] == '!' or trimmed[0] == '<') return true;
    if (trimmed[0] == '-' or trimmed[0] == '+' or std.ascii.isDigit(trimmed[0])) return true;
    if (std.mem.eql(u8, trimmed, "undef") or
        std.mem.eql(u8, trimmed, "poison") or
        std.mem.eql(u8, trimmed, "null") or
        std.mem.eql(u8, trimmed, "zeroinitializer") or
        std.mem.eql(u8, trimmed, "true") or
        std.mem.eql(u8, trimmed, "false") or
        std.mem.eql(u8, trimmed, "nan") or
        std.mem.eql(u8, trimmed, "+nan") or
        std.mem.eql(u8, trimmed, "-nan") or
        std.mem.eql(u8, trimmed, "inf") or
        std.mem.eql(u8, trimmed, "+inf") or
        std.mem.eql(u8, trimmed, "-inf") or
        std.mem.startsWith(u8, trimmed, "splat (") or
        isSupportedConstantExpr(trimmed))
    {
        return true;
    }
    return false;
}

pub fn callArgMayContainAttrs(text: []const u8) bool {
    if (text.len >= 2 and text[0] == '<' and text[text.len - 1] == '>') return false;
    return std.mem.indexOfAny(u8, text, " \t") != null;
}

pub fn findTrailingValueStart(text: []const u8) ?usize {
    var end = text.len;
    while (end > 0 and (text[end - 1] == ' ' or text[end - 1] == '\t')) end -= 1;
    if (end == 0) return null;

    var index = end;
    while (index > 0) {
        const byte = text[index - 1];
        if (byte == ' ' or byte == '\t') return index;
        index -= 1;
    }
    return 0;
}

pub fn parseBinaryFlags(parts: *std.mem.TokenIterator(u8, .any)) !core.BinaryFlags {
    var flags: core.BinaryFlags = .{};
    while (parts.peek()) |token| {
        if (std.mem.eql(u8, token, "nsw")) {
            if (flags.nsw) return error.InvalidInstruction;
            _ = parts.next();
            flags.nsw = true;
            continue;
        }
        if (std.mem.eql(u8, token, "nuw")) {
            if (flags.nuw) return error.InvalidInstruction;
            _ = parts.next();
            flags.nuw = true;
            continue;
        }
        if (std.mem.eql(u8, token, "exact")) {
            if (flags.exact) return error.InvalidInstruction;
            _ = parts.next();
            flags.exact = true;
            continue;
        }
        if (std.mem.eql(u8, token, "disjoint")) {
            if (flags.disjoint) return error.InvalidInstruction;
            _ = parts.next();
            flags.disjoint = true;
            continue;
        }
        return flags;
    }
    return flags;
}

pub fn parseFastMathFlagsFromParts(parts: *std.mem.TokenIterator(u8, .any)) !core.FastMathFlags {
    var flags: core.FastMathFlags = .{};
    while (parts.peek()) |token| {
        if (!isFastMathFlagToken(token)) return flags;
        try setFastMathFlag(&flags, token);
        _ = parts.next();
    }
    return flags;
}

pub fn isFastMathFlagToken(token: []const u8) bool {
    return std.mem.eql(u8, token, "fast") or
        std.mem.eql(u8, token, "nnan") or
        std.mem.eql(u8, token, "ninf") or
        std.mem.eql(u8, token, "nsz") or
        std.mem.eql(u8, token, "arcp") or
        std.mem.eql(u8, token, "contract") or
        std.mem.eql(u8, token, "afn") or
        std.mem.eql(u8, token, "reassoc");
}

pub fn setFastMathFlag(flags: *core.FastMathFlags, token: []const u8) !void {
    if (std.mem.eql(u8, token, "fast")) {
        if (flags.any()) return error.InvalidInstruction;
        flags.fast = true;
        return;
    }
    if (flags.fast) return error.InvalidInstruction;
    if (std.mem.eql(u8, token, "nnan")) {
        if (flags.nnan) return error.InvalidInstruction;
        flags.nnan = true;
    } else if (std.mem.eql(u8, token, "ninf")) {
        if (flags.ninf) return error.InvalidInstruction;
        flags.ninf = true;
    } else if (std.mem.eql(u8, token, "nsz")) {
        if (flags.nsz) return error.InvalidInstruction;
        flags.nsz = true;
    } else if (std.mem.eql(u8, token, "arcp")) {
        if (flags.arcp) return error.InvalidInstruction;
        flags.arcp = true;
    } else if (std.mem.eql(u8, token, "contract")) {
        if (flags.contract) return error.InvalidInstruction;
        flags.contract = true;
    } else if (std.mem.eql(u8, token, "afn")) {
        if (flags.afn) return error.InvalidInstruction;
        flags.afn = true;
    } else if (std.mem.eql(u8, token, "reassoc")) {
        if (flags.reassoc) return error.InvalidInstruction;
        flags.reassoc = true;
    } else {
        return error.InvalidInstruction;
    }
}

pub fn parseStore(line: []const u8) !core.Instruction {
    var rest = std.mem.trim(u8, line["store ".len..], " \t");
    var attrs = try parseMemoryPrefixText(&rest);

    const stored = try parseLeadingType(rest);
    var value_text = std.mem.trim(u8, stored.after, " \t");
    const stored_addrspace = if (stored.ty == .ptr) blk: {
        const token = firstToken(value_text) orelse break :blk null;
        if (!isAddressSpaceToken(token)) break :blk null;
        value_text = trimFirstToken(value_text);
        break :blk token;
    } else null;
    const value_comma = findTopLevelComma(value_text) orelse return error.InvalidInstruction;
    const value = try parseValue(std.mem.trim(u8, value_text[0..value_comma], " \t"));
    rest = std.mem.trim(u8, value_text[value_comma + 1 ..], " \t");

    const ptr_operand = try parseMemoryPointerOperand(rest, attrs);
    var suffix_parts = std.mem.tokenizeAny(u8, ptr_operand.suffix, " \t,");
    try parseMemorySuffix(&suffix_parts, &attrs);

    return .{
        .result = null,
        .kind = .{ .store = .{
            .ty = stored.ty,
            .ty_addrspace = stored_addrspace,
            .value = value,
            .ptr = ptr_operand.ptr,
            .ptr_addrspace = ptr_operand.ptr_addrspace,
            .attrs = attrs,
        } },
    };
}

pub fn parseLoad(result: []const u8, text: []const u8) !core.Instruction {
    var rest = std.mem.trim(u8, text["load".len..], " \t");
    var attrs = try parseMemoryPrefixText(&rest);

    const ty_comma = findTopLevelComma(rest) orelse return error.InvalidInstruction;
    const loaded_ty = try parseAddressSpaceQualifiedType(std.mem.trim(u8, rest[0..ty_comma], " \t"));
    rest = std.mem.trim(u8, rest[ty_comma + 1 ..], " \t");

    const ptr_operand = try parseMemoryPointerOperand(rest, attrs);
    var suffix_parts = std.mem.tokenizeAny(u8, ptr_operand.suffix, " \t,");
    try parseMemorySuffix(&suffix_parts, &attrs);

    return .{
        .result = result,
        .kind = .{ .load = .{
            .ty = loaded_ty.ty,
            .ty_addrspace = loaded_ty.addrspace_text,
            .ptr = ptr_operand.ptr,
            .ptr_addrspace = ptr_operand.ptr_addrspace,
            .attrs = attrs,
        } },
    };
}

const MemoryPointerOperand = struct {
    ptr: core.Value,
    ptr_addrspace: ?[]const u8 = null,
    suffix: []const u8,
};

const AddressSpaceQualifiedType = struct {
    ty: core.Type,
    addrspace_text: ?[]const u8 = null,
};

pub fn parseAddressSpaceQualifiedType(text: []const u8) !AddressSpaceQualifiedType {
    const parsed = try parseLeadingType(text);
    if (parsed.after.len == 0) return .{ .ty = parsed.ty };
    if (parsed.ty != .ptr) return error.UnsupportedType;
    const token = firstToken(parsed.after) orelse return error.UnsupportedType;
    if (!isAddressSpaceToken(token)) return error.UnsupportedType;
    if (trimFirstToken(parsed.after).len != 0) return error.UnsupportedType;
    return .{ .ty = parsed.ty, .addrspace_text = token };
}

pub fn parseMemoryPointerOperand(text: []const u8, attrs: core.MemoryAttrs) !MemoryPointerOperand {
    var rest = std.mem.trim(u8, text, " \t");
    var ptr_addrspace: ?[]const u8 = null;
    if (std.mem.startsWith(u8, rest, "ptr ")) {
        rest = std.mem.trim(u8, rest["ptr ".len..], " \t");
        if (firstToken(rest)) |token| {
            if (isAddressSpaceToken(token)) {
                ptr_addrspace = token;
                rest = std.mem.trim(u8, rest[token.len..], " \t");
            }
        }
    } else {
        const ptr_ty = try parseLeadingType(rest);
        if (ptr_ty.ty != .ptr) return error.ExpectedPointerType;
        rest = ptr_ty.after;
    }

    if (attrs.atomic_ordering != null) {
        const ptr_end = memoryPointerValueEnd(rest) orelse return error.InvalidInstruction;
        return .{
            .ptr = try parseValue(std.mem.trim(u8, rest[0..ptr_end], " \t")),
            .ptr_addrspace = ptr_addrspace,
            .suffix = std.mem.trim(u8, rest[ptr_end..], " \t,"),
        };
    }

    const suffix_comma = findTopLevelComma(rest);
    return .{
        .ptr = try parseValue(std.mem.trim(u8, if (suffix_comma) |index| rest[0..index] else rest, " \t")),
        .ptr_addrspace = ptr_addrspace,
        .suffix = if (suffix_comma) |index| std.mem.trim(u8, rest[index + 1 ..], " \t") else "",
    };
}

pub fn memoryPointerValueEnd(text: []const u8) ?usize {
    const trimmed = std.mem.trim(u8, text, " \t");
    if (trimmed.len == 0) return null;
    if (constantExprEnd(trimmed)) |end| return end;
    return firstValueEnd(trimmed);
}

pub fn constantExprEnd(text: []const u8) ?usize {
    if (!(std.mem.startsWith(u8, text, "inttoptr (") or
        std.mem.startsWith(u8, text, "ptrtoint (") or
        std.mem.startsWith(u8, text, "sub (") or
        std.mem.startsWith(u8, text, "getelementptr ")))
    {
        return null;
    }
    const open = findOpenParenOutsideString(text, 0) orelse return null;
    const close = findMatchingParen(text, open) orelse return null;
    return close + 1;
}

pub fn firstValueEnd(text: []const u8) ?usize {
    const trimmed = std.mem.trim(u8, text, " \t");
    if (trimmed.len == 0) return null;
    return std.mem.indexOfAny(u8, trimmed, " \t,") orelse trimmed.len;
}

pub fn parseMemoryPrefixText(rest: *[]const u8) !core.MemoryAttrs {
    var attrs: core.MemoryAttrs = .{};
    while (true) {
        const token = firstToken(rest.*) orelse return attrs;
        if (std.mem.eql(u8, token, "volatile")) {
            if (attrs.is_volatile) return error.InvalidAtomicMemory;
            attrs.is_volatile = true;
            rest.* = std.mem.trim(u8, rest.*[token.len..], " \t");
            continue;
        }
        if (std.mem.eql(u8, token, "atomic")) {
            if (attrs.atomic_ordering != null) return error.InvalidAtomicMemory;
            attrs.atomic_ordering = "";
            rest.* = std.mem.trim(u8, rest.*[token.len..], " \t");
            continue;
        }
        if (std.mem.startsWith(u8, token, "syncscope")) {
            if (attrs.syncscope != null or attrs.atomic_ordering == null) return error.InvalidAtomicMemory;
            attrs.syncscope = token;
            rest.* = std.mem.trim(u8, rest.*[token.len..], " \t");
            continue;
        }
        return attrs;
    }
}

pub fn isAddressSpaceToken(text: []const u8) bool {
    if (!std.mem.startsWith(u8, text, "addrspace(") or !std.mem.endsWith(u8, text, ")")) return false;
    const payload = text["addrspace(".len .. text.len - 1];
    if (payload.len == 0) return false;
    _ = std.fmt.parseInt(u32, payload, 10) catch return false;
    return true;
}

pub fn parseAtomicRmw(text: []const u8) !core.AtomicRmwInst {
    var rest = std.mem.trim(u8, text["atomicrmw".len..], " \t");
    var is_volatile = false;
    if (std.mem.startsWith(u8, rest, "volatile ")) {
        is_volatile = true;
        rest = std.mem.trim(u8, rest["volatile".len..], " \t");
    }
    if (std.mem.startsWith(u8, rest, "syncscope")) return error.UnsupportedAtomicMemory;

    const op_end = std.mem.indexOfAny(u8, rest, " \t") orelse return error.InvalidAtomicMemory;
    const op = rest[0..op_end];
    if (!isSupportedAtomicRmwOp(op)) return error.UnsupportedAtomicMemory;
    rest = std.mem.trim(u8, rest[op_end..], " \t");

    const ptr_comma = findTopLevelComma(rest) orelse return error.InvalidAtomicMemory;
    const ptr_text = std.mem.trim(u8, rest[0..ptr_comma], " \t");
    const ptr_operand = try parseMemoryPointerOperand(ptr_text, .{});
    if (ptr_operand.suffix.len != 0 or ptr_operand.ptr_addrspace != null) return error.InvalidAtomicMemory;

    rest = std.mem.trim(u8, rest[ptr_comma + 1 ..], " \t");
    const attr_comma = findTopLevelComma(rest);
    const value_text = std.mem.trim(u8, if (attr_comma) |index| rest[0..index] else rest, " \t");
    var value_parts = std.mem.tokenizeAny(u8, value_text, " \t");
    const ty = try parseType(value_parts.next() orelse return error.InvalidAtomicMemory);
    const value = try parseValue(value_parts.next() orelse return error.InvalidAtomicMemory);
    var syncscope: ?[]const u8 = null;
    var ordering = value_parts.next() orelse return error.InvalidAtomicMemory;
    if (std.mem.startsWith(u8, ordering, "syncscope")) {
        syncscope = ordering;
        ordering = value_parts.next() orelse return error.InvalidAtomicMemory;
    }
    if (!isSupportedAtomicOrdering(ordering)) return error.UnsupportedAtomicMemory;
    if (value_parts.next() != null) return error.InvalidAtomicMemory;

    const alignment = if (attr_comma) |index| try parseOptionalAlign(std.mem.trim(u8, rest[index + 1 ..], " \t")) else null;
    return .{
        .op = op,
        .ty = ty,
        .ptr = ptr_operand.ptr,
        .value = value,
        .ordering = ordering,
        .syncscope = syncscope,
        .is_volatile = is_volatile,
        .@"align" = alignment,
    };
}

pub fn parseCmpxchg(allocator: std.mem.Allocator, text: []const u8) !core.CmpxchgInst {
    var rest = std.mem.trim(u8, text["cmpxchg".len..], " \t");
    var is_volatile = false;
    var is_weak = false;
    while (true) {
        if (std.mem.startsWith(u8, rest, "weak ")) {
            is_weak = true;
            rest = std.mem.trim(u8, rest["weak".len..], " \t");
            continue;
        }
        if (std.mem.startsWith(u8, rest, "volatile ")) {
            is_volatile = true;
            rest = std.mem.trim(u8, rest["volatile".len..], " \t");
            continue;
        }
        break;
    }
    if (std.mem.startsWith(u8, rest, "syncscope")) return error.UnsupportedAtomicMemory;

    const ptr_comma = findTopLevelComma(rest) orelse return error.InvalidAtomicMemory;
    const ptr_text = std.mem.trim(u8, rest[0..ptr_comma], " \t");
    const ptr_operand = try parseMemoryPointerOperand(ptr_text, .{});
    if (ptr_operand.suffix.len != 0 or ptr_operand.ptr_addrspace != null) return error.InvalidAtomicMemory;

    rest = std.mem.trim(u8, rest[ptr_comma + 1 ..], " \t");
    const expected_comma = findTopLevelComma(rest) orelse return error.InvalidAtomicMemory;
    const expected_text = std.mem.trim(u8, rest[0..expected_comma], " \t");
    var expected_parts = std.mem.tokenizeAny(u8, expected_text, " \t");
    const ty = try parseType(expected_parts.next() orelse return error.InvalidAtomicMemory);
    const result_ty_text = try cmpxchgResultTypeText(allocator, ty);
    errdefer allocator.free(result_ty_text);
    const expected = try parseValue(expected_parts.next() orelse return error.InvalidAtomicMemory);
    if (expected_parts.next() != null) return error.InvalidAtomicMemory;

    rest = std.mem.trim(u8, rest[expected_comma + 1 ..], " \t");
    const attr_comma = findTopLevelComma(rest);
    const replacement_text = std.mem.trim(u8, if (attr_comma) |index| rest[0..index] else rest, " \t");
    var replacement_parts = std.mem.tokenizeAny(u8, replacement_text, " \t");
    const replacement_ty = try parseType(replacement_parts.next() orelse return error.InvalidAtomicMemory);
    if (!replacement_ty.eql(ty)) return error.TypeMismatch;
    const replacement = try parseValue(replacement_parts.next() orelse return error.InvalidAtomicMemory);
    var syncscope: ?[]const u8 = null;
    var success_ordering = replacement_parts.next() orelse return error.InvalidAtomicMemory;
    if (std.mem.startsWith(u8, success_ordering, "syncscope")) {
        syncscope = success_ordering;
        success_ordering = replacement_parts.next() orelse return error.InvalidAtomicMemory;
    }
    const failure_ordering = replacement_parts.next() orelse return error.InvalidAtomicMemory;
    if (!isSupportedAtomicOrdering(success_ordering) or !isSupportedAtomicOrdering(failure_ordering)) return error.UnsupportedAtomicMemory;
    if (replacement_parts.next() != null) return error.InvalidAtomicMemory;

    const alignment = if (attr_comma) |index| try parseOptionalAlign(std.mem.trim(u8, rest[index + 1 ..], " \t")) else null;
    return .{
        .ptr = ptr_operand.ptr,
        .ty = ty,
        .result_ty = .{ .aggregate = result_ty_text },
        .expected = expected,
        .replacement = replacement,
        .success_ordering = success_ordering,
        .failure_ordering = failure_ordering,
        .syncscope = syncscope,
        .is_weak = is_weak,
        .is_volatile = is_volatile,
        .@"align" = alignment,
    };
}

pub fn cmpxchgResultTypeText(allocator: std.mem.Allocator, ty: core.Type) ![]const u8 {
    var output: std.Io.Writer.Allocating = .init(allocator);
    defer output.deinit();

    try output.writer.writeAll("{ ");
    try ty.format(&output.writer);
    try output.writer.writeAll(", i1 }");
    return try allocator.dupe(u8, output.writer.buffered());
}

pub fn parseFence(text: []const u8) !core.Instruction {
    var parts = std.mem.tokenizeAny(u8, text, " \t,");
    if (!std.mem.eql(u8, parts.next() orelse return error.InvalidAtomicMemory, "fence")) return error.InvalidAtomicMemory;
    var syncscope: ?[]const u8 = null;
    var ordering = parts.next() orelse return error.InvalidAtomicMemory;
    if (std.mem.startsWith(u8, ordering, "syncscope")) {
        syncscope = ordering;
        ordering = parts.next() orelse return error.InvalidAtomicMemory;
    }
    if (!isSupportedAtomicOrdering(ordering)) return error.UnsupportedAtomicMemory;
    if (parts.next() != null) return error.InvalidAtomicMemory;
    return .{
        .result = null,
        .kind = .{ .fence = .{ .ordering = ordering, .syncscope = syncscope } },
    };
}

pub fn isSupportedAtomicRmwOp(op: []const u8) bool {
    inline for (.{ "xchg", "add", "sub", "and", "nand", "or", "xor", "max", "min", "umax", "umin", "fadd", "fsub" }) |candidate| {
        if (std.mem.eql(u8, op, candidate)) return true;
    }
    return false;
}

pub fn isSupportedAtomicOrdering(ordering: []const u8) bool {
    inline for (.{ "monotonic", "acquire", "release", "acq_rel", "seq_cst" }) |candidate| {
        if (std.mem.eql(u8, ordering, candidate)) return true;
    }
    return false;
}

pub fn parseOptionalAlign(text: []const u8) !?u64 {
    if (text.len == 0) return null;
    var parts = std.mem.tokenizeAny(u8, text, " \t,");
    if (!std.mem.eql(u8, parts.next() orelse return error.InvalidAtomicMemory, "align")) return error.InvalidAtomicMemory;
    const alignment = try std.fmt.parseInt(u64, parts.next() orelse return error.InvalidAlignment, 10);
    if (parts.next() != null) return error.InvalidAtomicMemory;
    return alignment;
}

pub fn parseMemoryPrefix(parts: *std.mem.TokenIterator(u8, .any)) !core.MemoryAttrs {
    var attrs: core.MemoryAttrs = .{};
    while (true) {
        const token = parts.peek() orelse return attrs;
        if (std.mem.eql(u8, token, "volatile")) {
            _ = parts.next();
            attrs.is_volatile = true;
            continue;
        }
        if (std.mem.eql(u8, token, "atomic")) {
            _ = parts.next();
            if (attrs.atomic_ordering != null) return error.InvalidAtomicMemory;
            attrs.atomic_ordering = "";
            continue;
        }
        if (std.mem.startsWith(u8, token, "syncscope")) return error.UnsupportedAtomicMemory;
        return attrs;
    }
}

pub fn parseExtractElement(text: []const u8) !core.ExtractElementInst {
    var rest = std.mem.trim(u8, text["extractelement".len..], " \t");
    const vector_comma = findTopLevelComma(rest) orelse return error.InvalidInstruction;
    const vector_arg = try parseTypedValue(std.mem.trim(u8, rest[0..vector_comma], " \t"));
    rest = std.mem.trim(u8, rest[vector_comma + 1 ..], " \t");
    const index_arg = try parseTypedValue(rest);
    return .{
        .vector_ty = vector_arg.ty,
        .vector = vector_arg.value,
        .index_ty = index_arg.ty,
        .index = index_arg.value,
    };
}

pub fn parseInsertElement(text: []const u8) !core.InsertElementInst {
    var rest = std.mem.trim(u8, text["insertelement".len..], " \t");
    const vector_comma = findTopLevelComma(rest) orelse return error.InvalidInstruction;
    const vector_arg = try parseTypedValue(std.mem.trim(u8, rest[0..vector_comma], " \t"));
    rest = std.mem.trim(u8, rest[vector_comma + 1 ..], " \t");
    const value_comma = findTopLevelComma(rest) orelse return error.InvalidInstruction;
    const value_arg = try parseTypedValue(std.mem.trim(u8, rest[0..value_comma], " \t"));
    rest = std.mem.trim(u8, rest[value_comma + 1 ..], " \t");
    const index_arg = try parseTypedValue(rest);
    return .{
        .vector_ty = vector_arg.ty,
        .vector = vector_arg.value,
        .value_ty = value_arg.ty,
        .value = value_arg.value,
        .index_ty = index_arg.ty,
        .index = index_arg.value,
    };
}

pub fn parseShuffleVector(text: []const u8) !core.ShuffleVectorInst {
    var rest = std.mem.trim(u8, text["shufflevector".len..], " \t");
    const lhs_comma = findTopLevelComma(rest) orelse return error.InvalidInstruction;
    const lhs_arg = try parseTypedValue(std.mem.trim(u8, rest[0..lhs_comma], " \t"));
    rest = std.mem.trim(u8, rest[lhs_comma + 1 ..], " \t");
    const rhs_comma = findTopLevelComma(rest) orelse return error.InvalidInstruction;
    const rhs_arg = try parseTypedValue(std.mem.trim(u8, rest[0..rhs_comma], " \t"));
    rest = std.mem.trim(u8, rest[rhs_comma + 1 ..], " \t");
    const mask_arg = try parseTypedValue(rest);
    return .{
        .lhs_ty = lhs_arg.ty,
        .lhs = lhs_arg.value,
        .rhs_ty = rhs_arg.ty,
        .rhs = rhs_arg.value,
        .mask_ty = mask_arg.ty,
        .mask = mask_arg.value,
    };
}

pub fn parseExtractValue(text: []const u8) !core.ExtractValueInst {
    var rest = std.mem.trim(u8, text["extractvalue".len..], " \t");
    const aggregate_comma = findTopLevelComma(rest) orelse return error.InvalidInstruction;
    const aggregate_arg = try parseTypedValue(std.mem.trim(u8, rest[0..aggregate_comma], " \t"));
    const indices = std.mem.trim(u8, rest[aggregate_comma + 1 ..], " \t");
    if (indices.len == 0) return error.InvalidInstruction;
    const result_ty = try extractValueResultType(aggregate_arg.ty, indices);
    return .{
        .aggregate_ty = aggregate_arg.ty,
        .aggregate = aggregate_arg.value,
        .indices = indices,
        .result_ty = result_ty,
    };
}

pub fn parseInsertValue(text: []const u8) !core.InsertValueInst {
    var rest = std.mem.trim(u8, text["insertvalue".len..], " \t");
    const aggregate_comma = findTopLevelComma(rest) orelse return error.InvalidInstruction;
    const aggregate_arg = try parseTypedValue(std.mem.trim(u8, rest[0..aggregate_comma], " \t"));

    rest = std.mem.trim(u8, rest[aggregate_comma + 1 ..], " \t");
    const value_comma = findTopLevelComma(rest) orelse return error.InvalidInstruction;
    const value_arg = try parseTypedValue(std.mem.trim(u8, rest[0..value_comma], " \t"));
    const indices = std.mem.trim(u8, rest[value_comma + 1 ..], " \t");
    if (indices.len == 0) return error.InvalidInstruction;

    const indexed_ty = try extractValueResultType(aggregate_arg.ty, indices);
    if (!indexed_ty.eql(value_arg.ty)) return error.TypeMismatch;
    return .{
        .aggregate_ty = aggregate_arg.ty,
        .aggregate = aggregate_arg.value,
        .value_ty = value_arg.ty,
        .value = value_arg.value,
        .indices = indices,
    };
}

pub fn extractValueResultType(aggregate_ty: core.Type, indices: []const u8) !core.Type {
    var current_ty = aggregate_ty;
    var rest = indices;
    while (rest.len != 0) {
        const comma = findTopLevelComma(rest);
        const index_text = std.mem.trim(u8, if (comma) |index| rest[0..index] else rest, " \t");
        if (index_text.len == 0) return error.InvalidInstruction;
        const index = try std.fmt.parseInt(usize, index_text, 10);
        current_ty = try aggregateElementType(current_ty, index);
        rest = if (comma) |split| std.mem.trim(u8, rest[split + 1 ..], " \t") else "";
    }
    return current_ty;
}

pub fn aggregateElementType(aggregate_ty: core.Type, index: usize) !core.Type {
    if (parseArrayType(aggregate_ty)) |array_ty| {
        if (index >= array_ty.len) return error.TypeMismatch;
        return array_ty.elem_ty;
    }

    const text = switch (aggregate_ty) {
        .aggregate => |aggregate| aggregate,
        .void, .int, .half, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .vector => return error.TypeMismatch,
    };

    const body = if (std.mem.startsWith(u8, text, "{") and std.mem.endsWith(u8, text, "}"))
        text[1 .. text.len - 1]
    else if (std.mem.startsWith(u8, text, "<{") and std.mem.endsWith(u8, text, "}>"))
        text[2 .. text.len - 2]
    else
        return error.TypeMismatch;

    var rest = std.mem.trim(u8, body, " \t");
    var field_index: usize = 0;
    while (rest.len != 0) : (field_index += 1) {
        const comma = findTopLevelComma(rest);
        const field_text = std.mem.trim(u8, if (comma) |split| rest[0..split] else rest, " \t");
        const field_ty = try parseLeadingType(field_text);
        if (field_ty.after.len != 0) return error.UnsupportedType;
        if (field_index == index) return field_ty.ty;
        rest = if (comma) |split| std.mem.trim(u8, rest[split + 1 ..], " \t") else "";
    }

    return error.TypeMismatch;
}

pub fn parseSelect(text: []const u8) !core.SelectInst {
    var rest = std.mem.trim(u8, text["select".len..], " \t");
    const cond_comma = findTopLevelComma(rest) orelse return error.InvalidInstruction;
    const cond_arg = try parseTypedValue(std.mem.trim(u8, rest[0..cond_comma], " \t"));
    rest = std.mem.trim(u8, rest[cond_comma + 1 ..], " \t");
    const true_comma = findTopLevelComma(rest) orelse return error.InvalidInstruction;
    const true_arg = try parseTypedValue(std.mem.trim(u8, rest[0..true_comma], " \t"));
    rest = std.mem.trim(u8, rest[true_comma + 1 ..], " \t");
    const false_arg = try parseTypedValue(rest);
    if (!true_arg.ty.eql(false_arg.ty)) return error.TypeMismatch;
    return .{
        .cond_ty = cond_arg.ty,
        .cond = cond_arg.value,
        .ty = true_arg.ty,
        .true_value = true_arg.value,
        .false_value = false_arg.value,
    };
}

pub fn parseMemorySuffix(parts: *std.mem.TokenIterator(u8, .any), attrs: *core.MemoryAttrs) !void {
    while (parts.next()) |token| {
        if (std.mem.eql(u8, token, "align")) {
            const align_text = parts.next() orelse return error.InvalidAlignment;
            attrs.@"align" = try std.fmt.parseInt(u64, align_text, 10);
            continue;
        }
        if (std.mem.startsWith(u8, token, "syncscope")) {
            if (attrs.syncscope != null or attrs.atomic_ordering == null) return error.InvalidAtomicMemory;
            attrs.syncscope = token;
            continue;
        }
        if (attrs.atomic_ordering) |ordering| {
            if (ordering.len != 0) return error.InvalidInstruction;
            attrs.atomic_ordering = token;
            continue;
        }
        return error.InvalidInstruction;
    }

    if (attrs.atomic_ordering) |ordering| {
        if (ordering.len == 0) return error.InvalidAtomicMemory;
    }
}

pub fn parsePhi(allocator: std.mem.Allocator, text: []const u8) !core.PhiInst {
    var rest = std.mem.trim(u8, text["phi ".len..], " \t");
    const parsed_ty = try parseLeadingType(rest);
    const ty = parsed_ty.ty;
    rest = std.mem.trim(u8, parsed_ty.after, " \t");

    var phi: core.PhiInst = .{
        .ty = ty,
        .incoming = .empty,
    };
    errdefer phi.deinit(allocator);

    while (rest.len > 0) {
        if (rest[0] != '[') return error.InvalidPhi;
        const close = findMatchingBracket(rest, 0) orelse return error.InvalidPhi;
        const incoming_text = std.mem.trim(u8, rest[1..close], " \t");
        const comma = findTopLevelComma(incoming_text) orelse return error.InvalidPhi;
        const value_text = std.mem.trim(u8, incoming_text[0..comma], " \t");
        const block_text = std.mem.trim(u8, incoming_text[comma + 1 ..], " \t");

        try phi.incoming.append(allocator, .{
            .value = try parseValue(value_text),
            .block = try parseLabel(block_text),
        });

        rest = std.mem.trim(u8, rest[close + 1 ..], " \t");
        if (rest.len == 0) break;
        if (rest[0] != ',') return error.InvalidPhi;
        rest = std.mem.trim(u8, rest[1..], " \t");
    }

    if (phi.incoming.items.len == 0) return error.EmptyPhi;
    return phi;
}

pub fn parseRet(line: []const u8) !core.Terminator {
    const metadata_start = std.mem.indexOf(u8, line, ", !");
    const metadata = if (metadata_start) |index| std.mem.trim(u8, line[index + 2 ..], " \t") else null;
    const instruction_text = if (metadata_start) |index| line[0..index] else line;
    if (metadata) |attachment| try validateInstructionMetadata(attachment);
    if (!std.mem.startsWith(u8, instruction_text, "ret ")) return error.InvalidRet;
    const typed = try parseLeadingType(instruction_text["ret ".len..]);
    const ty = typed.ty;
    if (ty == .void) {
        if (std.mem.trim(u8, typed.after, " \t").len != 0) return error.InvalidRet;
        return .{ .ret = .{ .ty = ty } };
    }
    var value_text = std.mem.trim(u8, typed.after, " \t");
    const ptr_addrspace = if (ty == .ptr) blk: {
        const token = firstToken(value_text) orelse break :blk null;
        if (!isAddressSpaceToken(token)) break :blk null;
        value_text = trimFirstToken(value_text);
        break :blk token;
    } else null;
    const value = try parseValue(value_text);
    return .{ .ret = .{ .ty = ty, .value = value, .ptr_addrspace = ptr_addrspace } };
}

pub fn parseBr(line: []const u8) !core.Terminator {
    const metadata_start = std.mem.indexOf(u8, line, ", !");
    const metadata = if (metadata_start) |index| std.mem.trim(u8, line[index + 2 ..], " \t") else null;
    const instruction_text = if (metadata_start) |index| line[0..index] else line;
    if (!std.mem.startsWith(u8, instruction_text, "br ")) return error.InvalidBr;
    var rest = std.mem.trim(u8, instruction_text["br ".len..], " \t");
    if (std.mem.startsWith(u8, rest, "label ")) {
        const target = try parseLabel(std.mem.trim(u8, rest["label ".len..], " \t"));
        return .{ .br = .{ .target = target, .metadata = metadata } };
    }

    const typed = try parseLeadingType(rest);
    rest = std.mem.trim(u8, typed.after, " \t");
    const cond_comma = findTopLevelComma(rest) orelse return error.InvalidBr;
    const cond = try parseValue(std.mem.trim(u8, rest[0..cond_comma], " \t"));

    rest = std.mem.trim(u8, rest[cond_comma + 1 ..], " \t");
    if (!std.mem.startsWith(u8, rest, "label ")) return error.InvalidBr;
    rest = std.mem.trim(u8, rest["label ".len..], " \t");
    const then_comma = findTopLevelComma(rest) orelse return error.InvalidBr;
    const then_target = try parseLabel(std.mem.trim(u8, rest[0..then_comma], " \t"));

    rest = std.mem.trim(u8, rest[then_comma + 1 ..], " \t");
    if (!std.mem.startsWith(u8, rest, "label ")) return error.InvalidBr;
    const else_target = try parseLabel(std.mem.trim(u8, rest["label ".len..], " \t"));
    return .{ .condbr = .{
        .cond_ty = typed.ty,
        .cond = cond,
        .then_target = then_target,
        .else_target = else_target,
        .metadata = metadata,
    } };
}

pub fn parseSwitch(allocator: std.mem.Allocator, first_line: []const u8, lines: *std.mem.SplitIterator(u8, .scalar)) !core.Terminator {
    const open = std.mem.indexOfScalar(u8, first_line, '[') orelse return error.InvalidSwitch;
    const header = std.mem.trim(u8, first_line["switch ".len..open], " \t");
    const comma = findTopLevelComma(header) orelse return error.InvalidSwitch;
    const cond_arg = try parseTypedValue(std.mem.trim(u8, header[0..comma], " \t"));
    const default_text = std.mem.trim(u8, header[comma + 1 ..], " \t");
    const default_target = try parseLabelOperand(default_text, error.InvalidSwitch);

    var switch_term: core.SwitchTerminator = .{
        .cond_ty = cond_arg.ty,
        .cond = cond_arg.value,
        .default_target = default_target,
        .cases = .empty,
    };
    errdefer switch_term.cases.deinit(allocator);

    var rest = std.mem.trim(u8, first_line[open + 1 ..], " \t");
    while (true) {
        if (try parseSwitchCasesLine(allocator, &switch_term, rest)) |metadata| {
            if (metadata.len != 0) switch_term.metadata = metadata;
            return .{ .@"switch" = switch_term };
        }

        const raw_line = lines.next() orelse return error.InvalidSwitch;
        const line_without_comment = if (findLineCommentStart(raw_line)) |index|
            raw_line[0..index]
        else
            raw_line;
        rest = std.mem.trim(u8, line_without_comment, " \t\r");
    }
}

pub fn parseSwitchCasesLine(allocator: std.mem.Allocator, switch_term: *core.SwitchTerminator, line: []const u8) !?[]const u8 {
    const close = findSwitchCasesClose(line);
    const cases_text = std.mem.trim(u8, if (close) |index| line[0..index] else line, " \t");
    if (cases_text.len != 0) try parseSwitchCase(allocator, switch_term, cases_text);
    if (close) |index| {
        const trailing = std.mem.trim(u8, line[index + 1 ..], " \t");
        if (trailing.len == 0) return "";
        if (!std.mem.startsWith(u8, trailing, ",")) return error.InvalidSwitch;
        const metadata = std.mem.trim(u8, trailing[1..], " \t");
        if (metadata.len == 0) return error.InvalidSwitch;
        try validateInstructionMetadata(metadata);
        return metadata;
    }
    return null;
}

pub fn findSwitchCasesClose(line: []const u8) ?usize {
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
        } else if (byte == ']') {
            return index;
        }
    }
    return null;
}

pub fn parseSwitchCase(allocator: std.mem.Allocator, switch_term: *core.SwitchTerminator, text: []const u8) !void {
    const comma = findTopLevelComma(text) orelse return error.InvalidSwitch;
    const typed = try parseTypedValue(std.mem.trim(u8, text[0..comma], " \t"));
    const label_text = std.mem.trim(u8, text[comma + 1 ..], " \t");
    const target = try parseLabelOperand(label_text, error.InvalidSwitch);
    try switch_term.cases.append(allocator, .{
        .value_ty = typed.ty,
        .value = typed.value,
        .target = target,
    });
}

pub fn parseLabelOperand(text: []const u8, comptime err: anyerror) ![]const u8 {
    const keyword = firstToken(text) orelse return err;
    if (!std.mem.eql(u8, keyword, "label")) return err;
    const target = std.mem.trim(u8, text[keyword.len..], " \t");
    if (target.len == 0) return err;
    return parseLabel(target);
}

pub fn parseIndirectBr(allocator: std.mem.Allocator, line: []const u8) !core.Terminator {
    const metadata_start = std.mem.indexOf(u8, line, ", !");
    const metadata = if (metadata_start) |index| std.mem.trim(u8, line[index + 2 ..], " \t") else null;
    const instruction_text = if (metadata_start) |index| line[0..index] else line;
    var rest = std.mem.trim(u8, instruction_text["indirectbr ".len..], " \t");

    const typed = try parseLeadingType(rest);
    rest = std.mem.trim(u8, typed.after, " \t");
    const value_comma = findTopLevelComma(rest) orelse return error.InvalidBr;
    const addr = try parseValue(std.mem.trim(u8, rest[0..value_comma], " \t"));
    rest = std.mem.trim(u8, rest[value_comma + 1 ..], " \t");

    if (rest.len == 0 or rest[0] != '[') return error.InvalidBr;
    const close = findMatchingBracket(rest, 0) orelse return error.InvalidBr;
    if (std.mem.trim(u8, rest[close + 1 ..], " \t").len != 0) return error.InvalidBr;

    var indirectbr: core.IndirectBrTerminator = .{
        .addr_ty = typed.ty,
        .addr = addr,
        .targets = .empty,
        .metadata = metadata,
    };
    errdefer indirectbr.targets.deinit(allocator);

    var targets_text = std.mem.trim(u8, rest[1..close], " \t");
    if (targets_text.len == 0) return error.InvalidBr;
    while (targets_text.len != 0) {
        const comma = findTopLevelComma(targets_text);
        const target_text = std.mem.trim(u8, if (comma) |index| targets_text[0..index] else targets_text, " \t");
        try parseIndirectBrTarget(allocator, &indirectbr, target_text);
        targets_text = if (comma) |index| std.mem.trim(u8, targets_text[index + 1 ..], " \t") else "";
    }

    return .{ .indirectbr = indirectbr };
}

pub fn parseIndirectBrTarget(allocator: std.mem.Allocator, indirectbr: *core.IndirectBrTerminator, text: []const u8) !void {
    var parts = std.mem.tokenizeAny(u8, text, " \t");
    if (!std.mem.eql(u8, parts.next() orelse return error.InvalidBr, "label")) return error.InvalidBr;
    const target = try parseLabel(parts.next() orelse return error.InvalidBr);
    if (parts.next() != null) return error.InvalidBr;
    try indirectbr.targets.append(allocator, target);
}

const TypeOrLabel = union(enum) {
    ty: core.Type,
    label,
};

pub fn parseTypeOrLabel(text: []const u8) !TypeOrLabel {
    if (std.mem.eql(u8, text, "label")) return .label;
    return .{ .ty = try parseType(text) };
}

pub fn parseLabel(text: []const u8) ![]const u8 {
    if (!std.mem.startsWith(u8, text, "%") or text.len == 1) return error.InvalidLabel;
    if (text[1] == '"') {
        if (findClosingQuote(text, 1) != text.len - 1) return error.InvalidLabel;
    } else if (std.mem.indexOfAny(u8, text, " \t") != null) {
        return error.InvalidLabel;
    }
    return text[1..];
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

pub fn firstTokenFromEnd(text: []const u8) ?[]const u8 {
    const trimmed = std.mem.trim(u8, text, " \t");
    if (trimmed.len == 0) return null;
    const start = std.mem.lastIndexOfAny(u8, trimmed, " \t");
    return if (start) |index| trimmed[index + 1 ..] else trimmed;
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
    if (std.mem.eql(u8, text, "fp128")) return .fp128;
    if (text.len < 2 or text[0] != 'i') return error.UnsupportedType;
    const bits = try std.fmt.parseInt(u16, text[1..], 10);
    if (bits == 0) return error.UnsupportedType;
    return .{ .int = bits };
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

pub fn parseValue(text: []const u8) !core.Value {
    const trimmed = std.mem.trim(u8, text, " \t");
    if (trimmed.len == 0) return error.InvalidValue;
    if (std.mem.eql(u8, trimmed, "undef")) return .undef;
    if (std.mem.eql(u8, trimmed, "poison")) return .poison;
    if (std.mem.eql(u8, trimmed, "null")) return .null_value;
    if (std.mem.eql(u8, trimmed, "zeroinitializer")) return .zero_initializer;
    if (std.mem.eql(u8, trimmed, "true")) return .{ .int = 1 };
    if (std.mem.eql(u8, trimmed, "false")) return .{ .int = 0 };
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
    if (std.mem.startsWith(u8, text, "{") and std.mem.endsWith(u8, text, "}")) return true;
    return (std.mem.startsWith(u8, text, "inttoptr (") or
        std.mem.startsWith(u8, text, "ptrtoint (") or
        std.mem.startsWith(u8, text, "sub (") or
        std.mem.startsWith(u8, text, "getelementptr ")) and
        std.mem.endsWith(u8, text, ")");
}

pub fn isFpLiteral(text: []const u8) bool {
    return fp_semantics.looksLikeFpLiteral(text);
}
