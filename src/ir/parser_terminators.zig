const std = @import("std");
const core = @import("core.zig");
const syntax = @import("parser_syntax.zig");
const types_values = @import("parser_types_values.zig");
const common = @import("parser_common.zig");
const findLineCommentStart = syntax.findLineCommentStart;
const findClosingQuote = syntax.findClosingQuote;
const findMatchingBracket = syntax.findMatchingBracket;
const firstToken = syntax.firstToken;
const trimFirstToken = syntax.trimFirstToken;
const findTopLevelComma = syntax.findTopLevelComma;
const parseType = types_values.parseType;
const parseTypedValue = types_values.parseTypedValue;
const parseLeadingType = types_values.parseLeadingType;
const parseValue = types_values.parseValue;
const isAddressSpaceToken = types_values.isAddressSpaceToken;
const validateInstructionMetadata = common.validateInstructionMetadata;

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
    const open = syntax.findByteOutsideString(first_line, 0, '[') orelse return error.InvalidSwitch;
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
    return syntax.findByteOutsideString(line, 0, ']');
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
    try indirectbr.targets.append(allocator, try parseLabelOperand(text, error.InvalidBr));
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
