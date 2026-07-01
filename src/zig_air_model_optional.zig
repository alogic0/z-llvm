const std = @import("std");
const core = @import("zig_air_model_base.zig");
const air_export = @import("zig_air_export.zig");
const air_capabilities = @import("zig_air_capabilities.zig");

const FunctionType = core.FunctionType;
const typedOpcodeCount = core.typedOpcodeCount;
const typedReturnOpcodeCount = core.typedReturnOpcodeCount;
const typedHasReturnOpcode = core.typedHasReturnOpcode;
const typedInstOperandIndex = core.typedInstOperandIndex;
const typedConstI32Operand = core.typedConstI32Operand;
const typedFirstI32ConstOperandForOpcodes = core.typedFirstI32ConstOperandForOpcodes;
const typedCalleeNameCount = core.typedCalleeNameCount;
const callDetails = core.callDetails;
const untypedReturnRef = core.untypedReturnRef;
const untypedFindAnyLoadFromSlot = core.untypedFindAnyLoadFromSlot;

pub const OptionalShapeSummary = core.OptionalShapeSummary;
pub const TypedOptionalPayloadBranchSummary = core.TypedOptionalPayloadBranchSummary;
pub const TypedOptionalPayloadSummary = core.TypedOptionalPayloadSummary;
pub const TypedOptionalPointerSummary = core.TypedOptionalPointerSummary;

pub const TypedWrapOptionalSummary = struct {
    instruction_index: u32,
    payload_index: u32,
    optional_type_text: []const u8,
    payload_type_text: []const u8,
};

pub const TypedOptionalPayloadExtractionSummary = struct {
    instruction_index: u32,
    optional_index: u32,
    optional_type_text: []const u8,
    payload_type_text: []const u8,
};

pub const TypedOptionalPointerCheckSummary = struct {
    instruction_index: u32,
    pointer_index: ?u32,
    pointer_operand_text: []const u8,
    pointer_type_text: []const u8,
};

pub const TypedOptionalPointerPayloadExtractionSummary = TypedOptionalPayloadExtractionSummary;

fn untypedFieldPtrIndex(instruction: air_export.Instruction) ?usize {
    const prefix = "struct_field_ptr_index_";
    if (!std.mem.startsWith(u8, instruction.opcode, prefix)) return null;
    return std.fmt.parseInt(usize, instruction.opcode[prefix.len..], 10) catch null;
}

fn untypedFirstRefOperand(instruction: air_export.Instruction) ?u32 {
    var fields = core.air_text.splitTopLevel(instruction.payload, ',');
    return core.air_text.instructionRef(fields.next() orelse return null);
}

fn optionalSource(instruction: air_export.Instruction) ?u32 {
    if (air_capabilities.optionalSemanticOpForOpcode(instruction.opcode) == .none) return null;
    return untypedFirstRefOperand(instruction);
}

pub fn optionalPointerSummary(function: air_export.Function) ?OptionalShapeSummary {
    for (function.instructions) |condition| {
        if (air_capabilities.optionalSemanticOpForOpcode(condition.opcode) != .is_non_null) continue;
        const source = optionalSource(condition);
        for (function.instructions) |payload| {
            if (air_capabilities.optionalSemanticOpForOpcode(payload.opcode) != .optional_payload) continue;
            if (source != null and optionalSource(payload) != source) continue;
            const load = untypedFindAnyLoadFromSlot(function, payload.index) orelse continue;
            const returned = for (function.instructions) |ret| {
                if (untypedReturnRef(ret)) |value| break value;
            } else continue;
            return .{
                .kind = .pointer_payload,
                .optional_value = source,
                .condition = condition.index,
                .payload = payload.index,
                .load = load,
                .return_value = returned,
            };
        }
    }
    return null;
}

pub fn selectedOptionalPointerShape(function: air_export.Function) bool {
    return optionalPointerSummary(function) != null;
}

pub fn optionalPayloadSummary(function: air_export.Function) ?OptionalShapeSummary {
    for (function.instructions) |wrap| {
        if (air_capabilities.optionalSemanticOpForOpcode(wrap.opcode) != .wrap_optional) continue;
        for (function.instructions) |condition| {
            if (air_capabilities.optionalSemanticOpForOpcode(condition.opcode) != .is_non_null) continue;
            if (optionalSource(condition) != wrap.index) continue;
            for (function.instructions) |payload| {
                if (air_capabilities.optionalSemanticOpForOpcode(payload.opcode) != .optional_payload) continue;
                if (optionalSource(payload) != wrap.index) continue;
                return .{
                    .kind = .scalar_payload,
                    .optional_value = wrap.index,
                    .condition = condition.index,
                    .payload = payload.index,
                    .wrap = wrap.index,
                };
            }
        }
    }
    return null;
}

pub fn selectedOptionalPayloadShape(function: air_export.Function) bool {
    return optionalPayloadSummary(function) != null;
}

pub fn typedWrapOptionalSummary(instruction: air_export.TypedInstruction) ?TypedWrapOptionalSummary {
    if (!std.mem.eql(u8, instruction.opcode, "wrap_optional")) return null;
    if (instruction.operands.len != 1) return null;
    const optional_type = std.mem.trim(u8, instruction.result_type, " ");
    if (!std.mem.startsWith(u8, optional_type, "?")) return null;
    const payload_type = std.mem.trim(u8, instruction.operands[0].type_text, " ");
    const optional_payload_type = std.mem.trim(u8, optional_type[1..], " ");
    if (!std.mem.eql(u8, payload_type, optional_payload_type)) return null;
    return .{
        .instruction_index = instruction.index,
        .payload_index = typedInstOperandIndex(instruction.operands[0]) orelse return null,
        .optional_type_text = optional_type,
        .payload_type_text = payload_type,
    };
}

pub fn typedOptionalPayloadExtractionSummary(instruction: air_export.TypedInstruction) ?TypedOptionalPayloadExtractionSummary {
    if (!std.mem.eql(u8, instruction.opcode, "optional_payload")) return null;
    if (instruction.operands.len != 1) return null;
    const payload_type = std.mem.trim(u8, instruction.result_type, " ");
    const optional_type = std.mem.trim(u8, instruction.operands[0].type_text, " ");
    if (!std.mem.startsWith(u8, optional_type, "?")) return null;
    const optional_payload_type = std.mem.trim(u8, optional_type[1..], " ");
    if (!std.mem.eql(u8, payload_type, optional_payload_type)) return null;
    return .{
        .instruction_index = instruction.index,
        .optional_index = typedInstOperandIndex(instruction.operands[0]) orelse return null,
        .optional_type_text = optional_type,
        .payload_type_text = payload_type,
    };
}

pub fn typedOptionalPointerCheckSummary(instruction: air_export.TypedInstruction) ?TypedOptionalPointerCheckSummary {
    if (air_capabilities.optionalSemanticOpForOpcode(instruction.opcode) != .is_non_null) return null;
    if (instruction.operands.len != 1) return null;
    const result_type = std.mem.trim(u8, instruction.result_type, " ");
    if (!isBoolLikeResultTypeText(result_type)) return null;
    const pointer_type = std.mem.trim(u8, instruction.operands[0].type_text, " ");
    const payload_type = if (std.mem.startsWith(u8, pointer_type, "?"))
        std.mem.trim(u8, pointer_type[1..], " ")
    else
        pointer_type;
    if (!isPointerLikeTypeText(payload_type)) return null;
    return .{
        .instruction_index = instruction.index,
        .pointer_index = typedInstOperandIndex(instruction.operands[0]),
        .pointer_operand_text = instruction.operands[0].value,
        .pointer_type_text = pointer_type,
    };
}

pub fn typedOptionalPointerPayloadExtractionSummary(instruction: air_export.TypedInstruction) ?TypedOptionalPointerPayloadExtractionSummary {
    const summary = typedOptionalPayloadExtractionSummary(instruction) orelse return null;
    if (!isPointerLikeTypeText(summary.payload_type_text)) return null;
    return summary;
}

pub fn typedOptionalPayloadBranchSummary(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?TypedOptionalPayloadBranchSummary {
    if (function_type.params.len != 3 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.params[1].ir_type.eql(.{ .int = 32 }) or
        !function_type.params[2].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return null;
    }
    if (typedOpcodeCount(structured_air_v2, "arg") != 3 or
        typedOpcodeCount(structured_air_v2, "wrap_optional") != 1 or
        typedOpcodeCount(structured_air_v2, "is_non_null") != 1 or
        typedOpcodeCount(structured_air_v2, "optional_payload") != 1 or
        typedOpcodeCount(structured_air_v2, "cond_br") != 3 or
        typedReturnOpcodeCount(structured_air_v2) != 3)
    {
        return null;
    }

    const arg0 = typedNthI32ArgIndex(structured_air_v2, 0) orelse return null;
    const arg1 = typedNthI32ArgIndex(structured_air_v2, 1) orelse return null;
    const arg2 = typedNthI32ArgIndex(structured_air_v2, 2) orelse return null;

    const maybe_guard = typedBinaryInstConstRhs(structured_air_v2, "cmp_neq", arg0, 0) orelse return null;
    if (!typedCondBrUses(structured_air_v2, maybe_guard)) return null;

    const wrap_optional = singleInstructionByOpcode(structured_air_v2, "wrap_optional") orelse return null;
    if (wrap_optional.operands.len != 1 or typedInstOperandIndex(wrap_optional.operands[0]) != arg1) return null;

    const is_non_null = singleInstructionByOpcode(structured_air_v2, "is_non_null") orelse return null;
    const optional_payload = singleInstructionByOpcode(structured_air_v2, "optional_payload") orelse return null;
    if (is_non_null.operands.len != 1 or optional_payload.operands.len != 1) return null;
    const optional_value = typedInstOperandIndex(is_non_null.operands[0]) orelse return null;
    if (typedInstOperandIndex(optional_payload.operands[0]) != optional_value) return null;
    if (!typedCondBrUses(structured_air_v2, is_non_null.index)) return null;

    const threshold = typedBinaryInstConstRhsValue(structured_air_v2, "cmp_gt", optional_payload.index) orelse return null;
    const payload_guard = typedBinaryInstConstRhs(structured_air_v2, "cmp_gt", optional_payload.index, threshold) orelse return null;
    if (!typedCondBrUses(structured_air_v2, payload_guard)) return null;
    _ = typedBinaryInstInstRhsPrefix(structured_air_v2, "add", optional_payload.index, arg2) orelse return null;
    _ = typedBinaryInstInstRhsPrefix(structured_air_v2, "sub", optional_payload.index, arg2) orelse return null;

    const fallback = typedRetI32Const(structured_air_v2) orelse return null;
    return .{ .threshold = threshold, .fallback = fallback };
}

pub fn typedOptionalPayloadSummary(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?TypedOptionalPayloadSummary {
    if (function_type.params.len != 2 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.params[1].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return null;
    }
    if (typedOpcodeCount(structured_air_v2, "arg") != 2 or
        typedOpcodeCount(structured_air_v2, "block") != 2 or
        typedOpcodeCount(structured_air_v2, "cmp_neq") != 1 or
        typedOpcodeCount(structured_air_v2, "wrap_optional") != 1 or
        typedOpcodeCount(structured_air_v2, "is_non_null") != 1 or
        typedOpcodeCount(structured_air_v2, "optional_payload") != 1 or
        typedOpcodeCount(structured_air_v2, "br") != 4 or
        typedOpcodeCount(structured_air_v2, "cond_br") != 2 or
        !typedHasReturnOpcode(structured_air_v2))
    {
        return null;
    }
    return .{ .fallback = typedLastBranchI32ConstValue(structured_air_v2) orelse return null };
}

pub fn typedOptionalPointerSummary(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?TypedOptionalPointerSummary {
    if (function_type.params.len != 1 or function_type.params[0].ir_type != .ptr or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return null;
    }

    const ret_count = typedReturnOpcodeCount(structured_air_v2);
    const block_count = typedOpcodeCount(structured_air_v2, "block");
    const non_null_count = typedOpcodeCount(structured_air_v2, "is_non_null");
    const br_count = typedOpcodeCount(structured_air_v2, "br");
    const cond_br_count = typedOpcodeCount(structured_air_v2, "cond_br");
    const release_fast_shape = block_count == 1 and non_null_count == 1 and br_count == 1 and cond_br_count == 1;
    const checked_unwrap_shape = block_count == 2 and
        non_null_count == 2 and
        br_count == 2 and
        cond_br_count == 2 and
        typedCalleeNameCount(structured_air_v2, "unwrapNull") == 1 and
        typedOpcodeCount(structured_air_v2, "unreach") == 1;
    if (typedOpcodeCount(structured_air_v2, "arg") != 1 or
        typedOpcodeCount(structured_air_v2, "optional_payload") != 1 or
        typedOpcodeCount(structured_air_v2, "load") != 1 or
        ret_count != 2 or
        !(release_fast_shape or checked_unwrap_shape))
    {
        return null;
    }
    const payload = singleInstructionByOpcode(structured_air_v2, "optional_payload") orelse return null;
    _ = typedOptionalPointerPayloadExtractionSummary(payload) orelse return null;

    return .{
        .add_imm = typedFirstI32ConstOperandForOpcodes(structured_air_v2, &.{ "add", "add_safe" }, 1) orelse 0,
        .fallback = typedLastBranchOrReturnI32ConstValue(structured_air_v2) orelse return null,
        .checked_unwrap = checked_unwrap_shape,
    };
}

fn singleInstructionByOpcode(structured_air_v2: air_export.StructuredAirV2, expected_opcode: []const u8) ?air_export.TypedInstruction {
    var found: ?air_export.TypedInstruction = null;
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, expected_opcode)) continue;
        if (found != null) return null;
        found = instruction;
    }
    return found;
}

fn typedBinaryInstConstRhs(
    structured_air_v2: air_export.StructuredAirV2,
    opcode: []const u8,
    lhs_index: u32,
    rhs_value: i32,
) ?u32 {
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, opcode)) continue;
        if (instruction.operands.len != 2) continue;
        if (typedInstOperandIndex(instruction.operands[0]) != lhs_index) continue;
        const constant = typedConstI32Operand(instruction, 1) orelse continue;
        if (constant != rhs_value) continue;
        return instruction.index;
    }
    return null;
}

fn typedBinaryInstConstRhsValue(
    structured_air_v2: air_export.StructuredAirV2,
    opcode: []const u8,
    lhs_index: u32,
) ?i32 {
    var found: ?i32 = null;
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, opcode)) continue;
        if (instruction.operands.len != 2) continue;
        if (typedInstOperandIndex(instruction.operands[0]) != lhs_index) continue;
        const constant = typedConstI32Operand(instruction, 1) orelse continue;
        if (found != null) return null;
        found = constant;
    }
    return found;
}

fn typedBinaryInstInstRhsPrefix(
    structured_air_v2: air_export.StructuredAirV2,
    opcode_prefix: []const u8,
    lhs_index: u32,
    rhs_index: u32,
) ?u32 {
    var found: ?u32 = null;
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.startsWith(u8, instruction.opcode, opcode_prefix)) continue;
        if (instruction.operands.len != 2) continue;
        if (typedInstOperandIndex(instruction.operands[0]) != lhs_index) continue;
        if (typedInstOperandIndex(instruction.operands[1]) != rhs_index) continue;
        if (found != null) return null;
        found = instruction.index;
    }
    return found;
}

fn typedCondBrUses(structured_air_v2: air_export.StructuredAirV2, condition_index: u32) bool {
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "cond_br")) continue;
        if (instruction.operands.len == 0) continue;
        if (typedInstOperandIndex(instruction.operands[0]) == condition_index) return true;
    }
    return false;
}

fn typedRetI32Const(structured_air_v2: air_export.StructuredAirV2) ?i32 {
    var found: ?i32 = null;
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "ret") and !std.mem.eql(u8, instruction.opcode, "ret_safe")) continue;
        if (instruction.operands.len != 1) continue;
        const constant = typedConstI32Operand(instruction, 0) orelse continue;
        if (found != null) return null;
        found = constant;
    }
    return found;
}

fn typedLastBranchI32ConstValue(structured_air_v2: air_export.StructuredAirV2) ?i32 {
    var found: ?i32 = null;
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "br")) continue;
        if (instruction.operands.len != 2) continue;
        const constant = typedConstI32Operand(instruction, 1) orelse continue;
        if (found != null) return null;
        found = constant;
    }
    return found;
}

fn typedLastBranchOrReturnI32ConstValue(structured_air_v2: air_export.StructuredAirV2) ?i32 {
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "ret") and !std.mem.eql(u8, instruction.opcode, "ret_safe")) {
            if (!std.mem.eql(u8, instruction.opcode, "br")) continue;
        }
        if (instruction.operands.len != 1 and instruction.operands.len != 2) continue;
        const index: usize = if (instruction.operands.len == 1) 0 else 1;
        return typedConstI32Operand(instruction, index) orelse return null;
    }
    return null;
}

fn typedNthI32ArgIndex(structured_air_v2: air_export.StructuredAirV2, wanted: usize) ?u32 {
    var seen: usize = 0;
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "arg")) continue;
        if (!std.mem.eql(u8, instruction.result_type, "i32")) continue;
        if (seen == wanted) return instruction.index;
        seen += 1;
    }
    return null;
}

fn isPointerLikeTypeText(text: []const u8) bool {
    return std.mem.startsWith(u8, text, "*") or
        std.mem.startsWith(u8, text, "[*") or
        std.mem.startsWith(u8, text, "[:") or
        std.mem.startsWith(u8, text, "[]");
}

fn isBoolLikeResultTypeText(text: []const u8) bool {
    return std.mem.eql(u8, text, "bool") or
        std.mem.eql(u8, text, "i1") or
        std.mem.eql(u8, text, "typed-result");
}

test "typed optional model recognizes wrap_optional operand relation" {
    const operand = [_]air_export.TypedOperand{.{
        .kind = "inst",
        .value = "0",
        .type_text = "i32",
    }};
    const instruction = air_export.TypedInstruction{
        .index = 4,
        .opcode = "wrap_optional",
        .result_type = "?i32",
        .data_kind = "ty_op",
        .operands = &operand,
    };

    const summary = typedWrapOptionalSummary(instruction).?;
    try std.testing.expectEqual(@as(u32, 4), summary.instruction_index);
    try std.testing.expectEqual(@as(u32, 0), summary.payload_index);
    try std.testing.expectEqualStrings("?i32", summary.optional_type_text);
    try std.testing.expectEqualStrings("i32", summary.payload_type_text);
}

test "typed optional model rejects unrelated wrap_optional types" {
    const operand = [_]air_export.TypedOperand{.{
        .kind = "inst",
        .value = "0",
        .type_text = "i64",
    }};
    const instruction = air_export.TypedInstruction{
        .index = 4,
        .opcode = "wrap_optional",
        .result_type = "?i32",
        .data_kind = "ty_op",
        .operands = &operand,
    };

    try std.testing.expect(typedWrapOptionalSummary(instruction) == null);
}

test "typed optional model recognizes optional_payload operand relation" {
    const operand = [_]air_export.TypedOperand{.{
        .kind = "inst",
        .value = "4",
        .type_text = "?*const i32",
    }};
    const instruction = air_export.TypedInstruction{
        .index = 6,
        .opcode = "optional_payload",
        .result_type = "*const i32",
        .data_kind = "ty_op",
        .operands = &operand,
    };

    const summary = typedOptionalPayloadExtractionSummary(instruction).?;
    try std.testing.expectEqual(@as(u32, 6), summary.instruction_index);
    try std.testing.expectEqual(@as(u32, 4), summary.optional_index);
    try std.testing.expectEqualStrings("?*const i32", summary.optional_type_text);
    try std.testing.expectEqualStrings("*const i32", summary.payload_type_text);
}

test "typed optional model rejects unrelated optional_payload types" {
    const operand = [_]air_export.TypedOperand{.{
        .kind = "inst",
        .value = "4",
        .type_text = "?i32",
    }};
    const instruction = air_export.TypedInstruction{
        .index = 6,
        .opcode = "optional_payload",
        .result_type = "i64",
        .data_kind = "ty_op",
        .operands = &operand,
    };

    try std.testing.expect(typedOptionalPayloadExtractionSummary(instruction) == null);
}

test "typed optional model recognizes optional pointer payload extraction" {
    const operand = [_]air_export.TypedOperand{.{
        .kind = "inst",
        .value = "9",
        .type_text = "?*const i32",
    }};
    const instruction = air_export.TypedInstruction{
        .index = 11,
        .opcode = "optional_payload",
        .result_type = "*const i32",
        .data_kind = "ty_op",
        .operands = &operand,
    };

    const summary = typedOptionalPointerPayloadExtractionSummary(instruction).?;
    try std.testing.expectEqual(@as(u32, 11), summary.instruction_index);
    try std.testing.expectEqual(@as(u32, 9), summary.optional_index);
    try std.testing.expectEqualStrings("*const i32", summary.payload_type_text);
}

test "typed optional model rejects scalar optional payload as pointer payload" {
    const operand = [_]air_export.TypedOperand{.{
        .kind = "inst",
        .value = "4",
        .type_text = "?i32",
    }};
    const instruction = air_export.TypedInstruction{
        .index = 15,
        .opcode = "optional_payload",
        .result_type = "i32",
        .data_kind = "ty_op",
        .operands = &operand,
    };

    try std.testing.expect(typedOptionalPointerPayloadExtractionSummary(instruction) == null);
}

test "typed optional model recognizes optional pointer check" {
    const operand = [_]air_export.TypedOperand{.{
        .kind = "inst",
        .value = "2",
        .type_text = "?*const i32",
    }};
    const instruction = air_export.TypedInstruction{
        .index = 7,
        .opcode = "is_non_null",
        .result_type = "bool",
        .data_kind = "un_op",
        .operands = &operand,
    };

    const summary = typedOptionalPointerCheckSummary(instruction).?;
    try std.testing.expectEqual(@as(u32, 7), summary.instruction_index);
    try std.testing.expectEqual(@as(?u32, 2), summary.pointer_index);
    try std.testing.expectEqualStrings("2", summary.pointer_operand_text);
    try std.testing.expectEqualStrings("?*const i32", summary.pointer_type_text);
}

test "typed optional model recognizes raw pointer null check opcode" {
    const operand = [_]air_export.TypedOperand{.{
        .kind = "inst",
        .value = "2",
        .type_text = "*const i32",
    }};
    const instruction = air_export.TypedInstruction{
        .index = 7,
        .opcode = "is_non_null_ptr",
        .result_type = "i1",
        .data_kind = "un_op",
        .operands = &operand,
    };

    const summary = typedOptionalPointerCheckSummary(instruction).?;
    try std.testing.expectEqual(@as(?u32, 2), summary.pointer_index);
    try std.testing.expectEqualStrings("*const i32", summary.pointer_type_text);
}

test "typed optional model recognizes argument pointer null check" {
    const operand = [_]air_export.TypedOperand{.{
        .kind = "arg",
        .value = "arg0",
        .type_text = "?*const i32",
    }};
    const instruction = air_export.TypedInstruction{
        .index = 7,
        .opcode = "is_non_null",
        .result_type = "bool",
        .data_kind = "un_op",
        .operands = &operand,
    };

    const summary = typedOptionalPointerCheckSummary(instruction).?;
    try std.testing.expect(summary.pointer_index == null);
    try std.testing.expectEqualStrings("arg0", summary.pointer_operand_text);
}

test "typed optional model recognizes exported typed-result pointer check" {
    const operand = [_]air_export.TypedOperand{.{
        .kind = "inst",
        .value = "3",
        .type_text = "?*const i32",
    }};
    const instruction = air_export.TypedInstruction{
        .index = 4,
        .opcode = "is_non_null",
        .result_type = "typed-result",
        .data_kind = "un_op",
        .operands = &operand,
    };

    const summary = typedOptionalPointerCheckSummary(instruction).?;
    try std.testing.expectEqual(@as(?u32, 3), summary.pointer_index);
    try std.testing.expectEqualStrings("?*const i32", summary.pointer_type_text);
}

test "typed optional model rejects scalar optional check as pointer check" {
    const operand = [_]air_export.TypedOperand{.{
        .kind = "inst",
        .value = "2",
        .type_text = "?i32",
    }};
    const instruction = air_export.TypedInstruction{
        .index = 7,
        .opcode = "is_non_null",
        .result_type = "bool",
        .data_kind = "un_op",
        .operands = &operand,
    };

    try std.testing.expect(typedOptionalPointerCheckSummary(instruction) == null);
}
