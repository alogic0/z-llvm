const core = @import("zig_air_model_base.zig");
const std = @import("std");
const untyped = @import("zig_air_model_error_union_untyped.zig");
const typed_recognizers = @import("zig_air_model_typed_recognizers.zig");
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

pub const errorUnionPayloadSummary = untyped.errorUnionPayloadSummary;
pub const selectedErrorUnionPayloadShape = untyped.selectedErrorUnionPayloadShape;
pub const maybeErrorSummary = untyped.maybeErrorSummary;
pub const selectedMaybeErrorShape = untyped.selectedMaybeErrorShape;
pub const errorSwitchSummary = untyped.errorSwitchSummary;
pub const selectedErrorSwitchShape = untyped.selectedErrorSwitchShape;
pub const errorClassifySummary = untyped.errorClassifySummary;
pub const selectedErrorClassifyShape = untyped.selectedErrorClassifyShape;
pub const typedErrorSwitchSummary = typed_recognizers.typedErrorSwitchSummary;
pub const typedErrorClassifierSummary = typed_recognizers.typedErrorClassifierSummary;
pub const typedErrorUnionPayloadSummary = typed_recognizers.typedErrorUnionPayloadSummary;
pub const typedErrorUnionFlow = typed_recognizers.typedErrorUnionFlow;
pub const typedErrorUnionFlowDiagnosticName = typed_recognizers.typedErrorUnionFlowDiagnosticName;
pub const typedMaybeErrorSummary = typed_recognizers.typedMaybeErrorSummary;
pub const typedLoopTrySummary = typed_recognizers.typedLoopTrySummary;

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

pub fn errorSetFirstTwoNames(type_text: []const u8) ?[2][]const u8 {
    var fields = errorSetNameIterator(type_text) orelse return null;
    const first = std.mem.trim(u8, fields.next() orelse return null, " ");
    const second = std.mem.trim(u8, fields.next() orelse return null, " ");
    if (first.len == 0 or second.len == 0 or fields.next() != null) return null;
    return .{ first, second };
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
    if (!std.mem.eql(u8, cast.opcode, "bitcast") or cast.operands.len != 1) return null;
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
