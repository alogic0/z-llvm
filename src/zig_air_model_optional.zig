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
