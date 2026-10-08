const core = @import("zig_air_model_base.zig");
const std = @import("std");
const untyped = @import("zig_air_model_error_union_untyped.zig");
const typed_recognizers_impl = @import("zig_air_model_typed_recognizers_impl.zig");
const air_export = @import("zig_air_export.zig");
const air_text = @import("zig_air_text.zig");

pub const ErrorSwitchSummary = core.ErrorSwitchSummary;
pub const TypedErrorSwitchSummary = core.TypedErrorSwitchSummary;
pub const TypedErrorUnionSummary = core.TypedErrorUnionSummary;
pub const TypedErrorUnionPayloadKind = core.TypedErrorUnionPayloadKind;
pub const TypedErrorUnionFlowDiagnostic = core.TypedErrorUnionFlowDiagnostic;
pub const TypedErrorUnionFlow = core.TypedErrorUnionFlow;
pub const TypedErrorUnionFlowResult = core.TypedErrorUnionFlowResult;
pub const TypedLoopTrySummary = core.TypedLoopTrySummary;
pub const TypedLoopTryPostBranchSummary = core.TypedLoopTryPostBranchSummary;
pub const TypedLoopTryPostSwitchSummary = core.TypedLoopTryPostSwitchSummary;

pub const TypedErrorNameSummary = struct {
    instruction_index: u32,
    operand_index: u32,
    error_set_type: []const u8,
    result_type: []const u8,
};

pub const TypedErrorSetHasValueSummary = struct {
    instruction_index: u32,
    operand_index: u32,
    error_set_type: []const u8,
    allowed_count: usize,
    result_type: []const u8,
};

pub const TypedCmpLteErrorsLenSummary = struct {
    instruction_index: u32,
    operand_index: u32,
    global_error_count: usize,
    result_type: []const u8,
};

pub const errorUnionPayloadSummary = untyped.errorUnionPayloadSummary;
pub const selectedErrorUnionPayloadShape = untyped.selectedErrorUnionPayloadShape;
pub const maybeErrorSummary = untyped.maybeErrorSummary;
pub const selectedMaybeErrorShape = untyped.selectedMaybeErrorShape;
pub const errorSwitchSummary = untyped.errorSwitchSummary;
pub const selectedErrorSwitchShape = untyped.selectedErrorSwitchShape;
pub const errorClassifySummary = untyped.errorClassifySummary;
pub const selectedErrorClassifyShape = untyped.selectedErrorClassifyShape;
pub const typedErrorSwitchSummary = typed_recognizers_impl.typedErrorSwitchSummary;
pub const typedErrorClassifierSummary = typed_recognizers_impl.typedErrorClassifierSummary;
pub const typedErrorUnionPayloadSummary = typed_recognizers_impl.typedErrorUnionPayloadSummary;
pub const typedErrorUnionFlow = typed_recognizers_impl.typedErrorUnionFlow;
pub const typedErrorUnionFlowDiagnosticName = typed_recognizers_impl.typedErrorUnionFlowDiagnosticName;
pub const typedMaybeErrorSummary = typed_recognizers_impl.typedMaybeErrorSummary;
pub const typedLoopTrySummary = typed_recognizers_impl.typedLoopTrySummary;

pub fn typedErrorNameSummary(instruction: air_export.TypedInstruction) ?TypedErrorNameSummary {
    if (!std.mem.eql(u8, instruction.opcode, "error_name")) return null;
    if (instruction.operands.len != 1) return null;
    if (!std.mem.eql(u8, instruction.data_kind, "un_op")) return null;
    const operand_index = core.typedInstOperandIndex(instruction.operands[0]) orelse return null;
    const error_set_type = std.mem.trim(u8, instruction.operands[0].type_text, " ");
    if (!isErrorSetType(error_set_type)) return null;
    const result_type = std.mem.trim(u8, instruction.result_type, " ");
    if (!isSentinelU8SliceType(result_type)) return null;
    return .{
        .instruction_index = instruction.index,
        .operand_index = operand_index,
        .error_set_type = error_set_type,
        .result_type = result_type,
    };
}

pub fn typedErrorNameSummaryFromV2(
    structured_air_v2: air_export.StructuredAirV2,
    instruction: air_export.TypedInstruction,
) ?TypedErrorNameSummary {
    if (!std.mem.eql(u8, instruction.opcode, "error_name")) return null;
    if (instruction.operands.len != 1) return null;
    if (!std.mem.eql(u8, instruction.data_kind, "un_op")) return null;
    const operand_index = core.typedInstOperandIndex(instruction.operands[0]) orelse return null;
    const result_type = std.mem.trim(u8, instruction.result_type, " ");
    if (!isSentinelU8SliceType(result_type)) return null;
    const error_set_type = concreteErrorSetType(structured_air_v2, instruction.operands[0], operand_index) orelse return null;
    return .{
        .instruction_index = instruction.index,
        .operand_index = operand_index,
        .error_set_type = error_set_type,
        .result_type = result_type,
    };
}

pub fn typedErrorSetHasValueSummary(instruction: air_export.TypedInstruction) ?TypedErrorSetHasValueSummary {
    if (!std.mem.eql(u8, instruction.opcode, "error_set_has_value")) return null;
    if (instruction.operands.len != 1) return null;
    if (!std.mem.eql(u8, instruction.data_kind, "ty_op")) return null;
    if (!std.mem.eql(u8, instruction.result_type, "bool")) return null;
    const contract = core.detail(instruction, "error_set_has_value_contract") orelse return null;
    if (!std.mem.eql(u8, contract, "zllvm-error-set-has-value-v1")) return null;
    const error_set_type = std.mem.trim(u8, core.detail(instruction, "error_set_type") orelse return null, " ");
    if (!isErrorSetType(error_set_type)) return null;
    const operand_index = core.typedInstOperandIndex(instruction.operands[0]) orelse return null;
    if (!std.mem.eql(u8, std.mem.trim(u8, instruction.operands[0].type_text, " "), "u16")) return null;
    const allowed_count = errorSetNameCount(error_set_type) orelse return null;
    return .{
        .instruction_index = instruction.index,
        .operand_index = operand_index,
        .error_set_type = error_set_type,
        .allowed_count = allowed_count,
        .result_type = instruction.result_type,
    };
}

pub fn typedCmpLteErrorsLenSummary(instruction: air_export.TypedInstruction) ?TypedCmpLteErrorsLenSummary {
    if (!std.mem.eql(u8, instruction.opcode, "cmp_lte_errors_len")) return null;
    if (instruction.operands.len != 1) return null;
    if (!std.mem.eql(u8, instruction.data_kind, "un_op")) return null;
    if (!std.mem.eql(u8, instruction.result_type, "bool")) return null;
    const contract = core.detail(instruction, "cmp_lte_errors_len_contract") orelse return null;
    if (!std.mem.eql(u8, contract, "zllvm-cmp-lte-errors-len-v1")) return null;
    const count_text = core.detail(instruction, "global_error_count") orelse return null;
    const global_error_count = std.fmt.parseUnsigned(usize, count_text, 10) catch return null;
    const operand_index = core.typedInstOperandIndex(instruction.operands[0]) orelse return null;
    if (!std.mem.eql(u8, std.mem.trim(u8, instruction.operands[0].type_text, " "), "u16")) return null;
    return .{
        .instruction_index = instruction.index,
        .operand_index = operand_index,
        .global_error_count = global_error_count,
        .result_type = instruction.result_type,
    };
}

pub fn errorSetNameForCode(type_text: []const u8, code: i128) ?[]const u8 {
    if (code <= 0) return null;
    var fields = errorSetNameIterator(type_text) orelse return null;
    var current: i128 = 1;
    while (fields.next()) |field| : (current += 1) {
        const name = std.mem.trim(u8, field, " ");
        if (current == code and name.len != 0) return name;
    }
    return null;
}

pub fn errorSetNameCount(type_text: []const u8) ?usize {
    var fields = errorSetNameIterator(type_text) orelse return null;
    var count: usize = 0;
    while (fields.next()) |field| {
        const name = std.mem.trim(u8, field, " ");
        if (name.len == 0) return null;
        count += 1;
    }
    if (count == 0) return null;
    return count;
}

pub fn errorSetFirstTwoNames(type_text: []const u8) ?[2][]const u8 {
    var fields = errorSetNameIterator(type_text) orelse return null;
    const first = std.mem.trim(u8, fields.next() orelse return null, " ");
    const second = std.mem.trim(u8, fields.next() orelse return null, " ");
    if (first.len == 0 or second.len == 0 or fields.next() != null) return null;
    return .{ first, second };
}

pub fn errorSetNamesAlloc(allocator: std.mem.Allocator, type_text: []const u8) !?[][]const u8 {
    var fields = errorSetNameIterator(type_text) orelse return null;
    var names: std.ArrayList([]const u8) = .empty;
    errdefer names.deinit(allocator);
    while (fields.next()) |field| {
        const name = std.mem.trim(u8, field, " ");
        if (name.len == 0) return null;
        try names.append(allocator, name);
    }
    if (names.items.len == 0) return null;
    return try names.toOwnedSlice(allocator);
}

fn isErrorSetType(type_text: []const u8) bool {
    return std.mem.startsWith(u8, type_text, "error{") and std.mem.endsWith(u8, type_text, "}");
}

fn isSentinelU8SliceType(type_text: []const u8) bool {
    return std.mem.eql(u8, type_text, "[:0]const u8") or
        std.mem.eql(u8, type_text, "[]const u8") or
        std.mem.eql(u8, type_text, "{ ptr, i64 }");
}

fn concreteErrorSetType(
    structured_air_v2: air_export.StructuredAirV2,
    operand: air_export.TypedOperand,
    operand_index: u32,
) ?[]const u8 {
    const direct_type = std.mem.trim(u8, operand.type_text, " ");
    if (isErrorSetType(direct_type)) return direct_type;
    if (!std.mem.eql(u8, direct_type, "anyerror")) return null;
    const cast = typedInstructionByIndex(structured_air_v2, operand_index) orelse return null;
    if ((!std.mem.eql(u8, cast.opcode, "bitcast") and !std.mem.eql(u8, cast.opcode, "bit_cast")) or cast.operands.len != 1) return null;
    const source_type = std.mem.trim(u8, cast.operands[0].type_text, " ");
    if (!isErrorSetType(source_type)) return null;
    return source_type;
}

fn typedInstructionByIndex(
    structured_air_v2: air_export.StructuredAirV2,
    index: u32,
) ?air_export.TypedInstruction {
    for (structured_air_v2.instructions) |candidate| {
        if (candidate.index == index) return candidate;
    }
    return null;
}

fn errorSetNameIterator(type_text: []const u8) ?air_text.TopLevelSplit {
    const trimmed = std.mem.trim(u8, type_text, " ");
    if (!isErrorSetType(trimmed)) return null;
    return air_text.splitTopLevel(trimmed["error{".len .. trimmed.len - 1], ',');
}
