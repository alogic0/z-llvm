const std = @import("std");
const core = @import("core.zig");
const syntax = @import("parser_syntax.zig");
const types_values = @import("parser_types_values.zig");
const common = @import("parser_common.zig");
const findMatchingParen = syntax.findMatchingParen;
const findOpenParenOutsideString = syntax.findOpenParenOutsideString;
const firstToken = syntax.firstToken;
const trimFirstToken = syntax.trimFirstToken;
const findTopLevelComma = syntax.findTopLevelComma;
const parseType = types_values.parseType;
const parseTypedValue = types_values.parseTypedValue;
const parseLeadingType = types_values.parseLeadingType;
const parseValue = types_values.parseValue;
const isAddressSpaceToken = types_values.isAddressSpaceToken;
const parseArrayType = common.parseArrayType;

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
    inline for (.{ "xchg", "add", "sub", "and", "nand", "or", "xor", "max", "min", "umax", "umin", "fadd", "fsub", "fmax", "fmin" }) |candidate| {
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
