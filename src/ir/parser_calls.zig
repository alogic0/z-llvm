const std = @import("std");
const core = @import("core.zig");
const syntax = @import("parser_syntax.zig");
const types_values = @import("parser_types_values.zig");
const common = @import("parser_common.zig");
const findMatchingParen = syntax.findMatchingParen;
const findOpenParenOutsideString = syntax.findOpenParenOutsideString;
const findMatchingBracket = syntax.findMatchingBracket;
const firstToken = syntax.firstToken;
const trimFirstToken = syntax.trimFirstToken;
const parseQuotedPrefix = syntax.parseQuotedPrefix;
const findTopLevelComma = syntax.findTopLevelComma;
const findTopLevelTokenEnd = syntax.findTopLevelTokenEnd;
const parseTypedValue = types_values.parseTypedValue;
const parseLeadingType = types_values.parseLeadingType;
const parseValue = types_values.parseValue;
const isSupportedConstantExpr = types_values.isSupportedConstantExpr;
const isUnsupportedDebugIntrinsicCallee = common.isUnsupportedDebugIntrinsicCallee;
const isSupportedDebugIntrinsicCallee = common.isSupportedDebugIntrinsicCallee;

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

pub fn isUnsupportedInstrumentationCallee(name: []const u8) bool {
    return std.mem.startsWith(u8, name, "__sanitizer_") or
        std.mem.startsWith(u8, name, "__tsan_") or
        std.mem.startsWith(u8, name, "__ubsan_") or
        std.mem.startsWith(u8, name, "llvm.ubsan.");
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
    const quoted_identifier = value_text.len > 1 and (value_text[0] == '@' or value_text[0] == '%') and
        @import("identifiers.zig").isValid(value_text[1..]);
    if (std.mem.indexOfAny(u8, value_text, " \t") != null and !isSupportedConstantExpr(value_text) and !quoted_identifier) {
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
    var rest = std.mem.trim(u8, text, " \t");
    var last: ?usize = null;
    while (rest.len != 0) {
        last = @intFromPtr(rest.ptr) - @intFromPtr(text.ptr);
        const end = findTopLevelTokenEnd(rest) orelse return null;
        if (end == 0) return null;
        rest = std.mem.trimStart(u8, rest[end..], " \t");
    }
    return last;
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
