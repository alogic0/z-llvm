const std = @import("std");
const core = @import("core.zig");

pub fn parse(allocator: std.mem.Allocator, text: []const u8) !core.Module {
    var module: core.Module = .{
        .allocator = allocator,
        .source = try allocator.dupe(u8, text),
        .owned_strings = .empty,
        .functions = .empty,
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
            try function.blocks.append(allocator, core.BasicBlock.init("entry"));
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
    if (module.functions.items.len == 0) return error.EmptyModule;
    return module;
}

fn parseFunctionHeader(allocator: std.mem.Allocator, line: []const u8) !core.Function {
    if (!std.mem.endsWith(u8, line, "{")) return error.InvalidFunctionHeader;
    const body = std.mem.trim(u8, line["define ".len .. line.len - 1], " \t");
    const open_paren = std.mem.indexOfScalar(u8, body, '(') orelse return error.InvalidFunctionHeader;
    const close_paren = std.mem.lastIndexOfScalar(u8, body, ')') orelse return error.InvalidFunctionHeader;
    if (close_paren < open_paren) return error.InvalidFunctionHeader;

    const head = std.mem.trim(u8, body[0..open_paren], " \t");
    var head_parts = std.mem.tokenizeAny(u8, head, " \t");
    const ret_ty = try parseType(head_parts.next() orelse return error.InvalidFunctionHeader);
    const name_text = head_parts.next() orelse return error.InvalidFunctionHeader;
    if (head_parts.next() != null) return error.InvalidFunctionHeader;
    if (!std.mem.startsWith(u8, name_text, "@")) return error.InvalidFunctionName;

    var function = core.Function.init(name_text[1..], ret_ty);
    errdefer function.deinit(allocator);

    const params_text = std.mem.trim(u8, body[open_paren + 1 .. close_paren], " \t");
    if (params_text.len != 0) {
        var params = std.mem.splitScalar(u8, params_text, ',');
        while (params.next()) |raw_param| {
            const param_text = std.mem.trim(u8, raw_param, " \t");
            var parts = std.mem.tokenizeAny(u8, param_text, " \t");
            const param_ty = try parseType(parts.next() orelse return error.InvalidParameter);
            const param_name = parts.next() orelse return error.InvalidParameter;
            if (parts.next() != null) return error.InvalidParameter;
            if (!std.mem.startsWith(u8, param_name, "%")) return error.InvalidValueName;
            try function.params.append(allocator, .{ .ty = param_ty, .name = param_name[1..] });
        }
    }

    return function;
}

fn parseInstruction(allocator: std.mem.Allocator, line: []const u8) !core.Instruction {
    if (std.mem.startsWith(u8, line, "store ")) return parseStore(line);

    const eq_index = std.mem.indexOfScalar(u8, line, '=') orelse return error.InvalidInstruction;
    const result_text = std.mem.trim(u8, line[0..eq_index], " \t");
    if (!std.mem.startsWith(u8, result_text, "%")) return error.InvalidValueName;

    const rhs_text = std.mem.trim(u8, line[eq_index + 1 ..], " \t");
    if (std.mem.startsWith(u8, rhs_text, "phi ")) {
        return .{
            .result = result_text[1..],
            .kind = .{ .phi = try parsePhi(allocator, rhs_text) },
        };
    }

    var parts = std.mem.tokenizeAny(u8, rhs_text, " \t,");
    const op_text = parts.next() orelse return error.InvalidInstruction;

    if (std.mem.eql(u8, op_text, "atomicrmw") or std.mem.eql(u8, op_text, "cmpxchg")) return error.UnsupportedAtomicMemory;

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

    if (std.mem.eql(u8, op_text, "alloca")) {
        const allocated_ty = try parseType(parts.next() orelse return error.InvalidInstruction);
        if (parts.next() != null) return error.InvalidInstruction;
        return .{
            .result = result_text[1..],
            .kind = .{ .alloca = .{ .allocated_ty = allocated_ty } },
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

    if (std.mem.eql(u8, op_text, "getelementptr")) {
        var gep: core.GepInst = .{
            .source_ty = try parseType(parts.next() orelse return error.InvalidInstruction),
            .ptr = undefined,
            .indices = .empty,
        };
        errdefer gep.deinit(allocator);

        const ptr_ty = try parseType(parts.next() orelse return error.InvalidInstruction);
        if (ptr_ty != .ptr) return error.ExpectedPointerType;
        gep.ptr = try parseValue(parts.next() orelse return error.InvalidInstruction);

        while (parts.next()) |index_ty_text| {
            const index_ty = try parseType(index_ty_text);
            const index_value = try parseValue(parts.next() orelse return error.InvalidInstruction);
            try gep.indices.append(allocator, .{
                .ty = index_ty,
                .value = index_value,
            });
        }
        if (gep.indices.items.len == 0) return error.InvalidGetElementPtr;

        return .{
            .result = result_text[1..],
            .kind = .{ .gep = gep },
        };
    }

    const op = core.BinaryOp.parse(op_text) orelse return error.UnsupportedInstruction;
    const ty = try parseType(parts.next() orelse return error.InvalidInstruction);
    const lhs = try parseValue(parts.next() orelse return error.InvalidInstruction);
    const rhs = try parseValue(parts.next() orelse return error.InvalidInstruction);
    if (parts.next() != null) return error.InvalidInstruction;

    return .{
        .result = result_text[1..],
        .kind = .{ .binary = .{
            .op = op,
            .ty = ty,
            .lhs = lhs,
            .rhs = rhs,
        } },
    };
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
    const value = try parseValue(parts.next() orelse return error.InvalidRet);
    if (parts.next() != null) return error.InvalidRet;
    return .{ .ret = .{ .ty = ty, .value = value } };
}

fn parseBr(line: []const u8) !core.Terminator {
    var parts = std.mem.tokenizeAny(u8, line, " \t,");
    if (!std.mem.eql(u8, parts.next() orelse return error.InvalidBr, "br")) return error.InvalidBr;
    const first_ty = try parseTypeOrLabel(parts.next() orelse return error.InvalidBr);
    switch (first_ty) {
        .label => {
            const target = try parseLabel(parts.next() orelse return error.InvalidBr);
            if (parts.next() != null) return error.InvalidBr;
            return .{ .br = .{ .target = target } };
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
    if (std.mem.eql(u8, text, "ptr")) return .ptr;
    if (text.len < 2 or text[0] != 'i') return error.UnsupportedType;
    const bits = try std.fmt.parseInt(u16, text[1..], 10);
    if (bits == 0) return error.UnsupportedType;
    return .{ .int = bits };
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
    return .{ .int = try std.fmt.parseInt(i128, text, 10) };
}
