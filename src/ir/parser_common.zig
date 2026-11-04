const std = @import("std");
const core = @import("core.zig");
const syntax = @import("parser_syntax.zig");
const types_values = @import("parser_types_values.zig");
const findAssignmentSeparator = syntax.findAssignmentSeparator;
const findClosingQuote = syntax.findClosingQuote;
const findMatchingParen = syntax.findMatchingParen;
const findOpenParenOutsideString = syntax.findOpenParenOutsideString;
const findMatchingBracket = syntax.findMatchingBracket;
const findMatchingBrace = syntax.findMatchingBrace;
const firstToken = syntax.firstToken;
const trimFirstToken = syntax.trimFirstToken;
const findMatchingAngle = syntax.findMatchingAngle;
const findTopLevelComma = syntax.findTopLevelComma;
const parseType = types_values.parseType;
const parseLeadingType = types_values.parseLeadingType;
const parseTrailingType = types_values.parseTrailingType;
const parseValue = types_values.parseValue;
const isSupportedConstantExpr = types_values.isSupportedConstantExpr;
const isSupportedNamedTypeName = types_values.isSupportedNamedTypeName;

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

    var initializer = parseGlobalInitializer(module.allocator, ty, initializer_text) catch |err| switch (err) {
        error.OutOfMemory => return err,
        else => return error.UnsupportedGlobalVariable,
    };
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
        const array = parseGlobalArrayInitializer(allocator, ty, text) catch |err| switch (err) {
            error.OutOfMemory => return err,
            else => return core.GlobalInitializer{ .@"opaque" = text },
        };
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

pub fn parseModuleStringRecord(line: []const u8, key: []const u8) ![]const u8 {
    if (!std.mem.startsWith(u8, line, key)) return error.InvalidModuleRecord;
    var rest = std.mem.trim(u8, line[key.len..], " \t");
    if (!std.mem.startsWith(u8, rest, "=")) return error.InvalidModuleRecord;
    rest = std.mem.trim(u8, rest[1..], " \t");
    if (rest.len < 2 or rest[0] != '"' or rest[rest.len - 1] != '"') return error.InvalidModuleRecord;
    return rest[1 .. rest.len - 1];
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
            const after_type = std.mem.trim(u8, parsed_ty.after, " \t");
            var parts = after_type;
            var param_name_token: ?[]const u8 = null;
            while (parts.len != 0) {
                const end = syntax.findTopLevelTokenEnd(parts) orelse return error.InvalidParameter;
                const part = parts[0..end];
                parts = std.mem.trimStart(u8, parts[end..], " \t");
                if (std.mem.startsWith(u8, part, "%")) {
                    if (part.len == 1 or parts.len != 0) return error.InvalidParameter;
                    param_name_token = part;
                    break;
                }
            }
            const param_name = param_name_token orelse return error.InvalidParameter;
            const param_attrs = std.mem.trim(u8, after_type[0..(@intFromPtr(param_name.ptr) - @intFromPtr(after_type.ptr))], " \t");
            try function.params.append(allocator, .{
                .ty = parsed_ty.ty,
                .attrs = if (param_attrs.len == 0) null else param_attrs,
                .name = param_name[1..],
            });
            rest = if (comma) |index| std.mem.trim(u8, rest[index + 1 ..], " \t") else "";
        }
    }
}

pub fn containsUnsupportedEhFunctionAttr(attrs: []const u8) bool {
    var it = std.mem.tokenizeAny(u8, attrs, " \t");
    while (it.next()) |token| {
        if (std.mem.eql(u8, token, "personality")) return true;
    }
    return false;
}

pub fn isUnsupportedDebugIntrinsicCallee(name: []const u8) bool {
    return std.mem.startsWith(u8, name, "llvm.dbg.") and !isSupportedDebugIntrinsicCallee(name);
}

pub fn isSupportedDebugIntrinsicCallee(name: []const u8) bool {
    return std.mem.eql(u8, name, "llvm.dbg.value") or
        std.mem.eql(u8, name, "llvm.dbg.declare");
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
