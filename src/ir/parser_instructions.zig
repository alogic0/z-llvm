const std = @import("std");
const core = @import("core.zig");
const syntax = @import("parser_syntax.zig");
const types_values = @import("parser_types_values.zig");
const common = @import("parser_common.zig");
const calls = @import("parser_calls.zig");
const memory = @import("parser_memory.zig");
const terminators = @import("parser_terminators.zig");
const findAssignmentSeparator = syntax.findAssignmentSeparator;
const firstToken = syntax.firstToken;
const trimFirstToken = syntax.trimFirstToken;
const findTopLevelTo = syntax.findTopLevelTo;
const findTopLevelComma = syntax.findTopLevelComma;
const parseType = types_values.parseType;
const parseLeadingType = types_values.parseLeadingType;
const parseValue = types_values.parseValue;
const parseCall = calls.parseCall;
const validateInstructionMetadata = common.validateInstructionMetadata;
const isFastMathFlagToken = calls.isFastMathFlagToken;
const setFastMathFlag = calls.setFastMathFlag;
const parseStore = memory.parseStore;
const parseLoad = memory.parseLoad;
const parseAddressSpaceQualifiedType = memory.parseAddressSpaceQualifiedType;
const isAddressSpaceToken = types_values.isAddressSpaceToken;
const parseAtomicRmw = memory.parseAtomicRmw;
const parseCmpxchg = memory.parseCmpxchg;
const parseExtractElement = memory.parseExtractElement;
const parseInsertElement = memory.parseInsertElement;
const parseShuffleVector = memory.parseShuffleVector;
const parseExtractValue = memory.parseExtractValue;
const parseInsertValue = memory.parseInsertValue;
const parseSelect = memory.parseSelect;
const parsePhi = terminators.parsePhi;

pub fn parseInstruction(allocator: std.mem.Allocator, line: []const u8) !core.Instruction {
    const metadata_start = std.mem.indexOf(u8, line, ", !");
    const metadata = if (metadata_start) |index| std.mem.trim(u8, line[index + 2 ..], " \t") else null;
    const instruction_text = if (metadata_start) |index| std.mem.trim(u8, line[0..index], " \t") else line;
    if (metadata) |attachment| try validateInstructionMetadata(attachment);

    var instruction = try parseInstructionBody(allocator, instruction_text);
    instruction.metadata = metadata;
    return instruction;
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

pub fn parseAlloca(text: []const u8) !core.AllocaInst {
    const rest = std.mem.trim(u8, text["alloca ".len..], " \t");
    const comma = findTopLevelComma(rest);
    const ty_text = std.mem.trim(u8, if (comma) |index| rest[0..index] else rest, " \t");
    if (ty_text.len == 0) return error.InvalidInstruction;
    const allocated_ty = try parseAddressSpaceQualifiedType(ty_text);
    var alloca: core.AllocaInst = .{
        .allocated_ty = allocated_ty.ty,
        .allocated_ty_addrspace = allocated_ty.addrspace_text,
        .attrs = if (comma) |index| std.mem.trim(u8, rest[index + 1 ..], " \t") else null,
    };
    if (alloca.attrs) |attrs| {
        const end = findTopLevelComma(attrs) orelse attrs.len;
        const first = std.mem.trim(u8, attrs[0..end], " \t");
        if (!std.mem.eql(u8, firstToken(first) orelse "", "align") and !std.mem.startsWith(u8, first, "addrspace(")) {
            const count = try types_values.parseTypedValue(first);
            if (count.ty != .int or count.ty.int == 0) return error.InvalidAllocaCount;
            alloca.count = .{ .ty = count.ty, .value = count.value };
            alloca.attrs = if (end < attrs.len) std.mem.trim(u8, attrs[end + 1 ..], " \t") else null;
        }
    }
    return alloca;
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
        const index_arg = try parseLeadingType(item);
        const index_value = try parseValue(index_arg.after);
        if (index_value != .constant_expr and index_value != .vector and
            (syntax.findTopLevelTokenEnd(index_arg.after) orelse return error.InvalidGetElementPtr) != index_arg.after.len)
            return error.InvalidGetElementPtr;
        try gep.indices.append(allocator, .{
            .ty = index_arg.ty,
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
