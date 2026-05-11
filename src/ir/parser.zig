const std = @import("std");
const core = @import("core.zig");

pub fn parse(allocator: std.mem.Allocator, text: []const u8) !core.Module {
    var module: core.Module = .{
        .allocator = allocator,
        .source = try allocator.dupe(u8, text),
        .owned_strings = .empty,
        .globals = .empty,
        .aliases = .empty,
        .declarations = .empty,
        .functions = .empty,
        .attribute_groups = .empty,
        .metadata = .empty,
    };
    errdefer module.deinit();

    var current_function: ?usize = null;
    var current_block: ?usize = null;

    var lines = std.mem.splitScalar(u8, module.source, '\n');
    while (lines.next()) |raw_line| {
        const line_without_comment = if (std.mem.indexOfScalar(u8, raw_line, ';')) |index|
            raw_line[0..index]
        else
            raw_line;
        const line = std.mem.trim(u8, line_without_comment, " \t\r");
        if (line.len == 0) continue;

        if (current_function == null and std.mem.startsWith(u8, line, "source_filename")) {
            module.source_filename = try parseModuleStringRecord(line, "source_filename");
            continue;
        }

        if (current_function == null and std.mem.startsWith(u8, line, "target triple")) {
            module.target_triple = try parseModuleStringRecord(line, "target triple");
            _ = try @import("../target.zig").Triple.parse(module.target_triple.?);
            continue;
        }

        if (current_function == null and std.mem.startsWith(u8, line, "target datalayout")) {
            module.target_datalayout = try parseModuleStringRecord(line, "target datalayout");
            _ = try @import("../target.zig").DataLayout.parse(module.target_datalayout.?);
            continue;
        }

        if (current_function == null and std.mem.startsWith(u8, line, "@")) {
            if (parseGlobalAlias(line)) |alias| {
                try module.aliases.append(allocator, alias);
                continue;
            } else |err| switch (err) {
                error.NotGlobalAlias => {},
                else => return err,
            }
            const global = try parseGlobal(line);
            try module.globals.append(allocator, global);
            continue;
        }
        if (current_function == null and std.mem.startsWith(u8, line, "declare ")) {
            const decl = try parseFunctionDecl(allocator, line);
            try module.declarations.append(allocator, decl);
            continue;
        }
        if (current_function == null and std.mem.startsWith(u8, line, "attributes ")) {
            try parseAttributeGroup(line);
            try module.attribute_groups.append(allocator, line);
            continue;
        }
        if (current_function == null and std.mem.startsWith(u8, line, "!")) {
            try module.metadata.append(allocator, line);
            continue;
        }

        if (std.mem.startsWith(u8, line, "define ")) {
            if (current_function != null) return error.NestedFunction;
            const function = try parseFunctionHeader(allocator, line);
            try module.functions.append(allocator, function);
            current_function = module.functions.items.len - 1;
            current_block = null;
            continue;
        }

        if (std.mem.eql(u8, line, "}")) {
            const function_index = current_function orelse return error.UnexpectedFunctionEnd;
            const function = &module.functions.items[function_index];
            if (function.blocks.items.len == 0) return error.FunctionWithoutBlocks;
            for (function.blocks.items) |block| {
                if (block.terminator == null) return error.BlockWithoutTerminator;
            }
            current_function = null;
            current_block = null;
            continue;
        }

        const function_index = current_function orelse return error.LineOutsideFunction;
        const function = &module.functions.items[function_index];

        if (std.mem.endsWith(u8, line, ":")) {
            const name = std.mem.trim(u8, line[0 .. line.len - 1], " \t");
            if (name.len == 0) return error.EmptyBlockName;
            if (function.blockIndex(name) != null) return error.DuplicateBlock;
            try function.blocks.append(allocator, core.BasicBlock.init(name));
            current_block = function.blocks.items.len - 1;
            continue;
        }

        if (current_block == null) {
            try function.blocks.append(allocator, core.BasicBlock.init(try implicitEntryBlockName(&module, function.*)));
            current_block = function.blocks.items.len - 1;
        }
        const block = &function.blocks.items[current_block.?];

        if (std.mem.startsWith(u8, line, "ret ")) {
            if (block.terminator != null) return error.MultipleTerminators;
            block.terminator = try parseRet(line);
            continue;
        }

        if (std.mem.startsWith(u8, line, "br ")) {
            if (block.terminator != null) return error.MultipleTerminators;
            block.terminator = try parseBr(line);
            continue;
        }

        if (std.mem.eql(u8, line, "unreachable")) {
            if (block.terminator != null) return error.MultipleTerminators;
            block.terminator = .{ .@"unreachable" = {} };
            continue;
        }

        try block.instructions.append(allocator, try parseInstruction(allocator, line));
    }

    if (current_function != null) return error.UnclosedFunction;
    if (module.functions.items.len == 0 and module.globals.items.len == 0 and module.aliases.items.len == 0 and module.declarations.items.len == 0 and module.metadata.items.len == 0 and module.attribute_groups.items.len == 0) return error.EmptyModule;
    return module;
}

fn parseGlobalAlias(line: []const u8) !core.GlobalAlias {
    const eq_index = std.mem.indexOfScalar(u8, line, '=') orelse return error.NotGlobalAlias;
    const name_text = std.mem.trim(u8, line[0..eq_index], " \t");
    if (!std.mem.startsWith(u8, name_text, "@") or name_text.len == 1) return error.InvalidGlobalAlias;

    const rest = std.mem.trim(u8, line[eq_index + 1 ..], " \t");
    var parts = std.mem.tokenizeAny(u8, rest, " \t");
    var token = parts.next() orelse return error.NotGlobalAlias;

    const linkage = core.FunctionLinkage.parse(token) orelse .default;
    if (linkage != .default) token = parts.next() orelse return error.InvalidGlobalAlias;
    if (!std.mem.eql(u8, token, "alias")) return error.NotGlobalAlias;

    const alias_token_offset = @intFromPtr(token.ptr) - @intFromPtr(rest.ptr) + token.len;
    const alias_body = std.mem.trim(u8, rest[alias_token_offset..], " \t");
    const comma = findTopLevelComma(alias_body) orelse return error.InvalidGlobalAlias;
    const aliased_ty = std.mem.trim(u8, alias_body[0..comma], " \t");
    if (aliased_ty.len == 0) return error.InvalidGlobalAlias;

    const target_text = std.mem.trim(u8, alias_body[comma + 1 ..], " \t");
    var target_parts = std.mem.tokenizeAny(u8, target_text, " \t");
    const target_ty = try parseType(target_parts.next() orelse return error.InvalidGlobalAlias);
    if (target_ty != .ptr) return error.UnsupportedGlobalAlias;
    const target_name = target_parts.next() orelse return error.InvalidGlobalAlias;
    if (target_parts.next() != null) return error.UnsupportedGlobalAlias;
    if (!std.mem.startsWith(u8, target_name, "@") or target_name.len == 1) return error.UnsupportedGlobalAlias;

    return .{
        .name = name_text[1..],
        .linkage = linkage,
        .aliased_ty = aliased_ty,
        .target_ty = target_ty,
        .target = target_name[1..],
    };
}

fn parseGlobal(line: []const u8) !core.Global {
    const eq_index = std.mem.indexOfScalar(u8, line, '=') orelse return error.UnsupportedGlobalVariable;
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
    const ty_text = parts.next() orelse return error.UnsupportedGlobalVariable;
    const ty = parseType(ty_text) catch return error.UnsupportedGlobalVariable;

    const initializer_start = @intFromPtr(ty_text.ptr) - @intFromPtr(rest.ptr) + ty_text.len;
    const initializer_and_attrs = std.mem.trim(u8, rest[initializer_start..], " \t");
    if (initializer_and_attrs.len == 0) return error.UnsupportedGlobalVariable;
    const comma = std.mem.indexOfScalar(u8, initializer_and_attrs, ',');
    const initializer_text = std.mem.trim(u8, if (comma) |index|
        initializer_and_attrs[0..index]
    else
        initializer_and_attrs, " \t");
    const attrs = if (comma) |index|
        std.mem.trim(u8, initializer_and_attrs[index + 1 ..], " \t")
    else
        "";
    if (std.mem.indexOfAny(u8, initializer_text, " \t") != null) return error.UnsupportedGlobalVariable;

    const initializer = parseGlobalInitializer(initializer_text) catch return error.UnsupportedGlobalVariable;
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

fn isGlobalAddressAttr(token: []const u8) bool {
    return std.mem.eql(u8, token, "unnamed_addr") or std.mem.eql(u8, token, "local_unnamed_addr");
}

fn parseGlobalInitializer(text: []const u8) !core.Value {
    const value = try parseValue(text);
    return switch (value) {
        .int, .undef => value,
        .named => error.UnsupportedGlobalVariable,
    };
}

fn parseAttributeGroup(line: []const u8) !void {
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
    if (std.mem.indexOf(u8, body, "sanitize_") != null) return error.UnsupportedAttributeGroup;
    if (std.mem.indexOf(u8, body, "safestack") != null) return error.UnsupportedAttributeGroup;
    if (std.mem.indexOf(u8, body, "shadowcallstack") != null) return error.UnsupportedAttributeGroup;
}

fn parseModuleStringRecord(line: []const u8, key: []const u8) ![]const u8 {
    if (!std.mem.startsWith(u8, line, key)) return error.InvalidModuleRecord;
    var rest = std.mem.trim(u8, line[key.len..], " \t");
    if (!std.mem.startsWith(u8, rest, "=")) return error.InvalidModuleRecord;
    rest = std.mem.trim(u8, rest[1..], " \t");
    if (rest.len < 2 or rest[0] != '"' or rest[rest.len - 1] != '"') return error.InvalidModuleRecord;
    return rest[1 .. rest.len - 1];
}

fn parseFunctionHeader(allocator: std.mem.Allocator, line: []const u8) !core.Function {
    if (!std.mem.endsWith(u8, line, "{")) return error.InvalidFunctionHeader;
    const body = std.mem.trim(u8, line["define ".len .. line.len - 1], " \t");
    const name_start = std.mem.indexOfScalar(u8, body, '@') orelse return error.InvalidFunctionHeader;
    const open_paren = std.mem.indexOfPos(u8, body, name_start, "(") orelse return error.InvalidFunctionHeader;
    const close_paren = std.mem.lastIndexOfScalar(u8, body, ')') orelse return error.InvalidFunctionHeader;
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
    if (attrs.len != 0) function.attrs = attrs;
    errdefer function.deinit(allocator);

    try parseFunctionParams(allocator, &function, body[open_paren + 1 .. close_paren]);

    return function;
}

fn parseFunctionDecl(allocator: std.mem.Allocator, line: []const u8) !core.FunctionDecl {
    const body = std.mem.trim(u8, line["declare ".len..], " \t");
    const name_start = std.mem.indexOfScalar(u8, body, '@') orelse return error.InvalidFunctionDeclaration;
    const open_paren = std.mem.indexOfPos(u8, body, name_start, "(") orelse return error.InvalidFunctionDeclaration;
    const close_paren = std.mem.lastIndexOfScalar(u8, body, ')') orelse return error.InvalidFunctionDeclaration;
    if (close_paren < open_paren) return error.InvalidFunctionDeclaration;

    const prefix = std.mem.trim(u8, body[0..name_start], " \t");
    const parsed_prefix = try parseFunctionPrefix(prefix, error.InvalidFunctionDeclaration);
    const name_text = std.mem.trim(u8, body[name_start..open_paren], " \t");
    if (!std.mem.startsWith(u8, name_text, "@")) return error.InvalidFunctionName;

    var decl = core.FunctionDecl.init(name_text[1..], parsed_prefix.ret_ty);
    decl.linkage = parsed_prefix.linkage;
    decl.visibility = parsed_prefix.visibility;
    decl.calling_conv = parsed_prefix.calling_conv;
    decl.ret_attrs = parsed_prefix.ret_attrs;
    const attrs = std.mem.trim(u8, body[close_paren + 1 ..], " \t");
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

fn parseFunctionPrefix(prefix: []const u8, comptime invalid_error: anyerror) !FunctionPrefix {
    const ret_ty_start = std.mem.lastIndexOfAny(u8, prefix, " \t");
    const ret_ty_text = if (ret_ty_start) |start| std.mem.trim(u8, prefix[start + 1 ..], " \t") else prefix;
    var rest = if (ret_ty_start) |start| std.mem.trim(u8, prefix[0..start], " \t") else "";

    var parsed: FunctionPrefix = .{ .ret_ty = parseType(ret_ty_text) catch return invalid_error };
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
    if (rest.len != 0) parsed.ret_attrs = rest;
    return parsed;
}

fn firstToken(text: []const u8) ?[]const u8 {
    const trimmed = std.mem.trim(u8, text, " \t");
    if (trimmed.len == 0) return null;
    const end = std.mem.indexOfAny(u8, trimmed, " \t") orelse trimmed.len;
    return trimmed[0..end];
}

fn trimFirstToken(text: []const u8) []const u8 {
    const trimmed = std.mem.trim(u8, text, " \t");
    const end = std.mem.indexOfAny(u8, trimmed, " \t") orelse return "";
    return std.mem.trim(u8, trimmed[end..], " \t");
}

fn parseDeclParams(allocator: std.mem.Allocator, decl: *core.FunctionDecl, text: []const u8) !void {
    const params_text = std.mem.trim(u8, text, " \t");
    if (params_text.len == 0) return;
    if (std.mem.eql(u8, params_text, "...")) return error.UnsupportedVarArgs;

    var rest = params_text;
    while (rest.len != 0) {
        const comma = findTopLevelComma(rest);
        const raw_param = if (comma) |index| rest[0..index] else rest;
        const param_text = std.mem.trim(u8, raw_param, " \t");
        if (std.mem.eql(u8, param_text, "...")) return error.UnsupportedVarArgs;
        var parts = std.mem.tokenizeAny(u8, param_text, " \t");
        const param_ty = try parseType(parts.next() orelse return error.InvalidParameter);
        const attrs_start = if (parts.next()) |part| @intFromPtr(part.ptr) - @intFromPtr(param_text.ptr) else null;
        if (attrs_start) |start| {
            try decl.params.append(allocator, .{
                .ty = param_ty,
                .attrs = std.mem.trim(u8, param_text[start..], " \t"),
            });
        } else {
            try decl.params.append(allocator, .{ .ty = param_ty });
        }
        rest = if (comma) |index| std.mem.trim(u8, rest[index + 1 ..], " \t") else "";
    }
}

fn implicitEntryBlockName(module: *core.Module, function: core.Function) ![]const u8 {
    var max_numeric_param: ?usize = null;
    for (function.params.items) |param| {
        const number = std.fmt.parseInt(usize, param.name, 10) catch continue;
        if (max_numeric_param == null or number > max_numeric_param.?) max_numeric_param = number;
    }
    const max_param = max_numeric_param orelse return "entry";
    return try module.ownString(try std.fmt.allocPrint(module.allocator, "{}", .{max_param + 1}));
}

fn parseFunctionParams(allocator: std.mem.Allocator, function: *core.Function, text: []const u8) !void {
    const params_text = std.mem.trim(u8, text, " \t");
    if (params_text.len != 0) {
        var rest = params_text;
        while (rest.len != 0) {
            const comma = findTopLevelComma(rest);
            const raw_param = if (comma) |index| rest[0..index] else rest;
            const param_text = std.mem.trim(u8, raw_param, " \t");
            var parts = std.mem.tokenizeAny(u8, param_text, " \t");
            const param_ty = try parseType(parts.next() orelse return error.InvalidParameter);
            var param_attrs_start: ?usize = null;
            var param_name_token: ?[]const u8 = null;
            while (parts.next()) |part| {
                if (std.mem.startsWith(u8, part, "%")) {
                    param_name_token = part;
                    break;
                }
                if (param_attrs_start == null) {
                    param_attrs_start = @intFromPtr(part.ptr) - @intFromPtr(param_text.ptr);
                }
            }
            const param_name = param_name_token orelse return error.InvalidParameter;
            if (parts.next() != null) return error.InvalidParameter;
            if (!std.mem.startsWith(u8, param_name, "%")) return error.InvalidValueName;
            const param_attrs = if (param_attrs_start) |start|
                std.mem.trim(u8, param_text[start..(@intFromPtr(param_name.ptr) - @intFromPtr(param_text.ptr))], " \t")
            else
                "";
            try function.params.append(allocator, .{
                .ty = param_ty,
                .attrs = if (param_attrs.len == 0) null else param_attrs,
                .name = param_name[1..],
            });
            rest = if (comma) |index| std.mem.trim(u8, rest[index + 1 ..], " \t") else "";
        }
    }
}

fn parseInstruction(allocator: std.mem.Allocator, line: []const u8) !core.Instruction {
    if (std.mem.startsWith(u8, line, "store ")) return parseStore(line);
    if (std.mem.startsWith(u8, line, "call ")) return parseCall(allocator, null, line);
    if (std.mem.startsWith(u8, line, "tail ")) return parseCall(allocator, null, line);
    if (std.mem.startsWith(u8, line, "musttail ") or std.mem.startsWith(u8, line, "notail ")) return error.UnsupportedCallAttribute;
    if (std.mem.startsWith(u8, line, "invoke ") or std.mem.startsWith(u8, line, "callbr ")) return error.UnsupportedCallTerminator;

    const eq_index = std.mem.indexOfScalar(u8, line, '=') orelse return error.InvalidInstruction;
    const result_text = std.mem.trim(u8, line[0..eq_index], " \t");
    if (!std.mem.startsWith(u8, result_text, "%")) return error.InvalidValueName;

    const rhs_text = std.mem.trim(u8, line[eq_index + 1 ..], " \t");
    if (std.mem.startsWith(u8, rhs_text, "call ")) return parseCall(allocator, result_text[1..], rhs_text);
    if (std.mem.startsWith(u8, rhs_text, "tail ")) return parseCall(allocator, result_text[1..], rhs_text);
    if (std.mem.startsWith(u8, rhs_text, "musttail ") or std.mem.startsWith(u8, rhs_text, "notail ")) return error.UnsupportedCallAttribute;
    if (std.mem.startsWith(u8, rhs_text, "invoke ") or std.mem.startsWith(u8, rhs_text, "callbr ")) return error.UnsupportedCallTerminator;
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

    if (std.mem.eql(u8, op_text, "atomicrmw") or std.mem.eql(u8, op_text, "cmpxchg")) return error.UnsupportedAtomicMemory;

    if (core.CastOp.parse(op_text)) |op| {
        const from_ty = try parseType(parts.next() orelse return error.InvalidInstruction);
        const value = try parseValue(parts.next() orelse return error.InvalidInstruction);
        if (!std.mem.eql(u8, parts.next() orelse return error.InvalidInstruction, "to")) return error.InvalidInstruction;
        const to_ty = try parseType(parts.next() orelse return error.InvalidInstruction);
        if (parts.next() != null) return error.InvalidInstruction;
        return .{
            .result = result_text[1..],
            .kind = .{ .cast = .{
                .op = op,
                .from_ty = from_ty,
                .value = value,
                .to_ty = to_ty,
            } },
        };
    }

    if (std.mem.eql(u8, op_text, "freeze")) {
        const ty = try parseType(parts.next() orelse return error.InvalidInstruction);
        const value = try parseValue(parts.next() orelse return error.InvalidInstruction);
        if (parts.next() != null) return error.InvalidInstruction;
        return .{
            .result = result_text[1..],
            .kind = .{ .freeze = .{
                .ty = ty,
                .value = value,
            } },
        };
    }

    if (std.mem.eql(u8, op_text, "icmp")) {
        const predicate = core.IcmpPredicate.parse(parts.next() orelse return error.InvalidInstruction) orelse return error.UnsupportedPredicate;
        const operand_ty = try parseType(parts.next() orelse return error.InvalidInstruction);
        const lhs = try parseValue(parts.next() orelse return error.InvalidInstruction);
        const rhs = try parseValue(parts.next() orelse return error.InvalidInstruction);
        if (parts.next() != null) return error.InvalidInstruction;
        return .{
            .result = result_text[1..],
            .kind = .{ .icmp = .{
                .predicate = predicate,
                .operand_ty = operand_ty,
                .lhs = lhs,
                .rhs = rhs,
            } },
        };
    }

    if (std.mem.eql(u8, op_text, "select")) {
        const cond_ty = try parseType(parts.next() orelse return error.InvalidInstruction);
        const cond = try parseValue(parts.next() orelse return error.InvalidInstruction);
        const ty = try parseType(parts.next() orelse return error.InvalidInstruction);
        const true_value = try parseValue(parts.next() orelse return error.InvalidInstruction);
        const false_ty = try parseType(parts.next() orelse return error.InvalidInstruction);
        if (!ty.eql(false_ty)) return error.TypeMismatch;
        const false_value = try parseValue(parts.next() orelse return error.InvalidInstruction);
        if (parts.next() != null) return error.InvalidInstruction;
        return .{
            .result = result_text[1..],
            .kind = .{ .select = .{
                .cond_ty = cond_ty,
                .cond = cond,
                .ty = ty,
                .true_value = true_value,
                .false_value = false_value,
            } },
        };
    }

    if (std.mem.eql(u8, op_text, "load")) {
        var attrs = try parseMemoryPrefix(&parts);
        const ty = try parseType(parts.next() orelse return error.InvalidInstruction);
        const ptr_ty = try parseType(parts.next() orelse return error.InvalidInstruction);
        if (ptr_ty != .ptr) return error.ExpectedPointerType;
        const ptr = try parseValue(parts.next() orelse return error.InvalidInstruction);
        try parseMemorySuffix(&parts, &attrs);
        return .{
            .result = result_text[1..],
            .kind = .{ .load = .{
                .ty = ty,
                .ptr = ptr,
                .attrs = attrs,
            } },
        };
    }

    const op = core.BinaryOp.parse(op_text) orelse return error.UnsupportedInstruction;
    const flags = try parseBinaryFlags(&parts);
    const ty = try parseType(parts.next() orelse return error.InvalidInstruction);
    const lhs = try parseValue(parts.next() orelse return error.InvalidInstruction);
    const rhs = try parseValue(parts.next() orelse return error.InvalidInstruction);
    if (parts.next() != null) return error.InvalidInstruction;

    return .{
        .result = result_text[1..],
        .kind = .{ .binary = .{
            .op = op,
            .flags = flags,
            .ty = ty,
            .lhs = lhs,
            .rhs = rhs,
        } },
    };
}

fn parseAlloca(text: []const u8) !core.AllocaInst {
    const ty_text = std.mem.trim(u8, text["alloca ".len..], " \t");
    if (ty_text.len == 0) return error.InvalidInstruction;
    if (findTopLevelComma(ty_text) != null) return error.InvalidInstruction;
    return .{ .allocated_ty = try parseType(ty_text) };
}

fn parseGep(allocator: std.mem.Allocator, text: []const u8) !core.GepInst {
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
    var ptr_parts = std.mem.tokenizeAny(u8, ptr_text, " \t");
    const ptr_ty = try parseType(ptr_parts.next() orelse return error.InvalidGetElementPtr);
    if (ptr_ty != .ptr) return error.ExpectedPointerType;
    gep.ptr = try parseValue(ptr_parts.next() orelse return error.InvalidGetElementPtr);
    if (ptr_parts.next() != null) return error.InvalidGetElementPtr;

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

fn stripGepPrefixes(text: []const u8) []const u8 {
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

fn parseCall(allocator: std.mem.Allocator, result: ?[]const u8, text: []const u8) !core.Instruction {
    var call_text = std.mem.trim(u8, text, " \t");
    const tail_kind: ?[]const u8 = if (std.mem.startsWith(u8, call_text, "tail ")) blk: {
        call_text = std.mem.trim(u8, call_text["tail ".len..], " \t");
        break :blk "tail";
    } else null;
    if (!std.mem.startsWith(u8, call_text, "call ")) return error.InvalidCall;

    var rest = std.mem.trim(u8, call_text["call ".len..], " \t");
    var prefix_parts = std.mem.tokenizeAny(u8, rest, " \t");
    var token = prefix_parts.next() orelse return error.InvalidCall;

    const calling_conv: ?[]const u8 = if (core.isSupportedCallingConvention(token)) token else null;
    if (calling_conv != null) token = prefix_parts.next() orelse return error.InvalidCall;

    if (std.mem.indexOfScalar(u8, token, '(') != null) {
        return error.UnsupportedIndirectCall;
    }

    const ret_ty = try parseType(token);
    const ret_ty_offset = @intFromPtr(token.ptr) - @intFromPtr(rest.ptr) + token.len;
    rest = std.mem.trim(u8, rest[ret_ty_offset..], " \t");

    const open_paren = std.mem.indexOfScalar(u8, rest, '(') orelse return error.InvalidCall;
    const close_paren = std.mem.lastIndexOfScalar(u8, rest, ')') orelse return error.InvalidCall;
    if (close_paren < open_paren) return error.InvalidCall;
    const callee_text = std.mem.trim(u8, rest[0..open_paren], " \t");
    if (!std.mem.startsWith(u8, callee_text, "@")) return error.UnsupportedIndirectCall;
    const trailing = std.mem.trim(u8, rest[close_paren + 1 ..], " \t");
    if (trailing.len != 0) return error.UnsupportedCallAttribute;

    var call: core.CallInst = .{
        .ret_ty = ret_ty,
        .callee = callee_text[1..],
        .calling_conv = calling_conv,
        .tail_kind = tail_kind,
        .args = .empty,
    };
    errdefer call.deinit(allocator);

    try parseCallArgs(allocator, &call, rest[open_paren + 1 .. close_paren]);

    return .{
        .result = result,
        .kind = .{ .call = call },
    };
}

fn parseCallArgs(allocator: std.mem.Allocator, call: *core.CallInst, text: []const u8) !void {
    const args_text = std.mem.trim(u8, text, " \t");
    if (args_text.len == 0) return;
    if (std.mem.eql(u8, args_text, "...")) return error.UnsupportedVarArgs;

    var rest = args_text;
    while (rest.len != 0) {
        const comma = findTopLevelComma(rest);
        const raw_arg = if (comma) |index| rest[0..index] else rest;
        const arg_text = std.mem.trim(u8, raw_arg, " \t");
        var parts = std.mem.tokenizeAny(u8, arg_text, " \t");
        const ty = try parseType(parts.next() orelse return error.InvalidCall);
        const value = try parseValue(parts.next() orelse return error.InvalidCall);
        if (parts.next() != null) return error.UnsupportedCallAttribute;
        try call.args.append(allocator, .{
            .ty = ty,
            .value = value,
        });
        rest = if (comma) |index| std.mem.trim(u8, rest[index + 1 ..], " \t") else "";
    }
}

fn parseBinaryFlags(parts: *std.mem.TokenIterator(u8, .any)) !core.BinaryFlags {
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

fn parseStore(line: []const u8) !core.Instruction {
    var parts = std.mem.tokenizeAny(u8, line, " \t,");
    if (!std.mem.eql(u8, parts.next() orelse return error.InvalidInstruction, "store")) return error.InvalidInstruction;
    var attrs = try parseMemoryPrefix(&parts);
    const ty = try parseType(parts.next() orelse return error.InvalidInstruction);
    const value = try parseValue(parts.next() orelse return error.InvalidInstruction);
    const ptr_ty = try parseType(parts.next() orelse return error.InvalidInstruction);
    if (ptr_ty != .ptr) return error.ExpectedPointerType;
    const ptr = try parseValue(parts.next() orelse return error.InvalidInstruction);
    try parseMemorySuffix(&parts, &attrs);

    return .{
        .result = null,
        .kind = .{ .store = .{
            .ty = ty,
            .value = value,
            .ptr = ptr,
            .attrs = attrs,
        } },
    };
}

fn parseMemoryPrefix(parts: *std.mem.TokenIterator(u8, .any)) !core.MemoryAttrs {
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

fn parseMemorySuffix(parts: *std.mem.TokenIterator(u8, .any), attrs: *core.MemoryAttrs) !void {
    while (parts.next()) |token| {
        if (std.mem.eql(u8, token, "align")) {
            const align_text = parts.next() orelse return error.InvalidAlignment;
            attrs.@"align" = try std.fmt.parseInt(u32, align_text, 10);
            continue;
        }
        if (std.mem.startsWith(u8, token, "syncscope")) return error.UnsupportedAtomicMemory;
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

fn parsePhi(allocator: std.mem.Allocator, text: []const u8) !core.PhiInst {
    var rest = std.mem.trim(u8, text["phi ".len..], " \t");
    const ty_end = std.mem.indexOfAny(u8, rest, " \t") orelse return error.InvalidPhi;
    const ty = try parseType(rest[0..ty_end]);
    rest = std.mem.trim(u8, rest[ty_end..], " \t");

    var phi: core.PhiInst = .{
        .ty = ty,
        .incoming = .empty,
    };
    errdefer phi.deinit(allocator);

    while (rest.len > 0) {
        if (rest[0] != '[') return error.InvalidPhi;
        const close = std.mem.indexOfScalar(u8, rest, ']') orelse return error.InvalidPhi;
        const incoming_text = std.mem.trim(u8, rest[1..close], " \t");
        const comma = std.mem.indexOfScalar(u8, incoming_text, ',') orelse return error.InvalidPhi;
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

fn parseRet(line: []const u8) !core.Terminator {
    var parts = std.mem.tokenizeAny(u8, line, " \t");
    if (!std.mem.eql(u8, parts.next() orelse return error.InvalidRet, "ret")) return error.InvalidRet;
    const ty = try parseType(parts.next() orelse return error.InvalidRet);
    if (ty == .void) {
        if (parts.next() != null) return error.InvalidRet;
        return .{ .ret = .{ .ty = ty } };
    }
    const value = try parseValue(parts.next() orelse return error.InvalidRet);
    if (parts.next() != null) return error.InvalidRet;
    return .{ .ret = .{ .ty = ty, .value = value } };
}

fn parseBr(line: []const u8) !core.Terminator {
    const metadata_start = std.mem.indexOf(u8, line, ", !");
    const metadata = if (metadata_start) |index| std.mem.trim(u8, line[index + 2 ..], " \t") else null;
    const instruction_text = if (metadata_start) |index| line[0..index] else line;
    var parts = std.mem.tokenizeAny(u8, instruction_text, " \t,");
    if (!std.mem.eql(u8, parts.next() orelse return error.InvalidBr, "br")) return error.InvalidBr;
    const first_ty = try parseTypeOrLabel(parts.next() orelse return error.InvalidBr);
    switch (first_ty) {
        .label => {
            const target = try parseLabel(parts.next() orelse return error.InvalidBr);
            if (parts.next() != null) return error.InvalidBr;
            return .{ .br = .{ .target = target, .metadata = metadata } };
        },
        .ty => |cond_ty| {
            const cond = try parseValue(parts.next() orelse return error.InvalidBr);
            const then_label = parts.next() orelse return error.InvalidBr;
            if (!std.mem.eql(u8, then_label, "label")) return error.InvalidBr;
            const then_target = try parseLabel(parts.next() orelse return error.InvalidBr);
            const else_label = parts.next() orelse return error.InvalidBr;
            if (!std.mem.eql(u8, else_label, "label")) return error.InvalidBr;
            const else_target = try parseLabel(parts.next() orelse return error.InvalidBr);
            if (parts.next() != null) return error.InvalidBr;
            return .{ .condbr = .{
                .cond_ty = cond_ty,
                .cond = cond,
                .then_target = then_target,
                .else_target = else_target,
                .metadata = metadata,
            } };
        },
    }
}

const TypeOrLabel = union(enum) {
    ty: core.Type,
    label,
};

fn parseTypeOrLabel(text: []const u8) !TypeOrLabel {
    if (std.mem.eql(u8, text, "label")) return .label;
    return .{ .ty = try parseType(text) };
}

fn parseLabel(text: []const u8) ![]const u8 {
    if (!std.mem.startsWith(u8, text, "%") or text.len == 1) return error.InvalidLabel;
    return text[1..];
}

fn parseType(text: []const u8) !core.Type {
    const trimmed = std.mem.trim(u8, text, " \t");
    if (std.mem.eql(u8, trimmed, "void")) return .void;
    if (std.mem.eql(u8, trimmed, "ptr")) return .ptr;
    if (trimmed.len >= 2 and ((trimmed[0] == '{' and trimmed[trimmed.len - 1] == '}') or
        (trimmed[0] == '[' and trimmed[trimmed.len - 1] == ']'))) return .{ .aggregate = trimmed };
    if (trimmed.len < 2 or trimmed[0] != 'i') return error.UnsupportedType;
    const bits = try std.fmt.parseInt(u16, trimmed[1..], 10);
    if (bits == 0) return error.UnsupportedType;
    return .{ .int = bits };
}

fn findTopLevelComma(text: []const u8) ?usize {
    var brace_depth: usize = 0;
    var bracket_depth: usize = 0;
    var angle_depth: usize = 0;
    var paren_depth: usize = 0;
    for (text, 0..) |byte, index| {
        switch (byte) {
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

fn parseValue(text: []const u8) !core.Value {
    if (text.len == 0) return error.InvalidValue;
    if (std.mem.eql(u8, text, "undef")) return .undef;
    if (std.mem.eql(u8, text, "true")) return .{ .int = 1 };
    if (std.mem.eql(u8, text, "false")) return .{ .int = 0 };
    if (text[0] == '%') {
        if (text.len == 1) return error.InvalidValueName;
        return .{ .named = text[1..] };
    }
    if (text[0] == '@') {
        if (text.len == 1) return error.InvalidValueName;
        return .{ .named = text };
    }
    return .{ .int = try std.fmt.parseInt(i128, text, 10) };
}
