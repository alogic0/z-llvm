const std = @import("std");
const core = @import("zig_air_model_base.zig");
const air_capabilities = @import("zig_air_capabilities.zig");
const air_export = @import("zig_air_export.zig");

const TypedOperand = air_export.TypedOperand;
const typedOpcodeCount = core.typedOpcodeCount;
const typedHasReturnOpcode = core.typedHasReturnOpcode;
const typedStoreOpcodeCount = core.typedStoreOpcodeCount;
const typedFirstI32ConstOperandForOpcodes = core.typedFirstI32ConstOperandForOpcodes;

pub const SliceSumSummary = core.SliceSumSummary;
pub const PointerSliceAddressSummary = core.PointerSliceAddressSummary;
pub const TypedSliceLoopSummary = core.TypedSliceLoopSummary;

pub fn pointerSliceAddressSummary(function: air_export.Function) ?PointerSliceAddressSummary {
    const view = core.TypedFunctionView.init(function) orelse return null;
    if (!view.operandCoverage()) return null;
    var summary: PointerSliceAddressSummary = .{};
    for (view.structured_air_v2.instructions) |instruction| {
        switch (air_capabilities.pointerAggregateSemanticOpForOpcode(instruction.opcode)) {
            .ptr_gep => {
                if (std.mem.eql(u8, instruction.opcode, "ptr_sub")) {
                    summary.ptr_sub_count += 1;
                } else {
                    summary.ptr_add_count += 1;
                }
                updatePointerSliceAddressOperands(&summary, instruction);
            },
            .slice => {
                summary.slice_count += 1;
                summary.slice_source_index = instruction.index;
                updatePointerSliceAddressOperands(&summary, instruction);
            },
            .array_to_slice => {
                summary.array_to_slice_count += 1;
                summary.slice_source_index = instruction.index;
                updatePointerSliceAddressOperands(&summary, instruction);
            },
            .slice_ptr => {
                summary.slice_ptr_count += 1;
                updatePointerSliceAddressOperands(&summary, instruction);
            },
            .slice_ptr_ptr => {
                summary.ptr_slice_ptr_ptr_count += 1;
                updatePointerSliceAddressOperands(&summary, instruction);
            },
            .slice_elem_ptr => {
                summary.slice_elem_ptr_count += 1;
                updatePointerSliceAddressOperands(&summary, instruction);
            },
            .slice_len => {
                summary.slice_len_count += 1;
                updatePointerSliceAddressOperands(&summary, instruction);
            },
            .slice_len_ptr => {
                summary.ptr_slice_len_ptr_count += 1;
                updatePointerSliceAddressOperands(&summary, instruction);
            },
            .none, .runtime_nav_ptr, .array_elem_val, .field_ptr => {},
        }
        switch (air_capabilities.memorySemanticOpForOpcode(instruction.opcode)) {
            .load => {
                summary.load_count += 1;
                summary.scalar_width_bits = summary.scalar_width_bits orelse scalarWidthFromText(instruction.result_type);
            },
            .store => summary.store_count += 1,
            .alloc, .none => {},
        }
        if (air_capabilities.isCondBrOpcode(instruction.opcode)) {
            summary.bounds_check_count += pointerSliceBoundsCheckOperandCount(instruction);
        }
    }
    return if (summary.hasPointerOrSliceAddress()) summary else null;
}

fn updatePointerSliceAddressOperands(summary: *PointerSliceAddressSummary, instruction: air_export.TypedInstruction) void {
    summary.scalar_width_bits = summary.scalar_width_bits orelse scalarWidthFromText(instruction.result_type);
    for (instruction.operands, 0..) |operand, operand_index| {
        if (summary.base_pointer_operand == null and operandLooksPointer(operand)) {
            summary.base_pointer_operand = core.operandTextDetail(instruction, operand_index) orelse operand.value;
        }
        if (summary.dynamic_index_operand == null and operandLooksRuntimeIndex(operand)) {
            summary.dynamic_index_operand = core.operandTextDetail(instruction, operand_index) orelse operand.value;
        }
        if (summary.constant_index == null and operandLooksIntegerConst(operand)) {
            const text = core.operandTextDetail(instruction, operand_index) orelse operand.value;
            summary.constant_index = parseIntegerText(text);
        }
    }
}

fn pointerSliceBoundsCheckOperandCount(instruction: air_export.TypedInstruction) usize {
    var count: usize = 0;
    for (instruction.operands) |operand| {
        if (operandLooksPointer(operand) or operandLooksRuntimeIndex(operand)) count += 1;
    }
    return count;
}

fn operandLooksPointer(operand: TypedOperand) bool {
    return std.mem.indexOf(u8, operand.type_text, "*") != null or
        std.mem.indexOf(u8, operand.type_text, "ptr") != null or
        std.mem.indexOf(u8, operand.kind, "ptr") != null;
}

fn operandLooksRuntimeIndex(operand: TypedOperand) bool {
    if (!isIntegerTypeText(operand.type_text)) return false;
    return !operandLooksIntegerConst(operand);
}

fn operandLooksIntegerConst(operand: TypedOperand) bool {
    return std.mem.eql(u8, operand.kind, "int") or
        std.mem.eql(u8, operand.kind, "comptime_int") or
        std.mem.eql(u8, operand.kind, "constant");
}

fn parseIntegerText(text: []const u8) ?i128 {
    const trimmed = std.mem.trim(u8, text, " ");
    if (trimmed.len == 0) return null;
    return std.fmt.parseInt(i128, trimmed, 10) catch null;
}

fn scalarWidthFromText(text: []const u8) ?u16 {
    const trimmed = std.mem.trim(u8, text, " ");
    if (std.mem.eql(u8, trimmed, "i8") or std.mem.eql(u8, trimmed, "u8")) return 8;
    if (std.mem.eql(u8, trimmed, "i16") or std.mem.eql(u8, trimmed, "u16")) return 16;
    if (std.mem.eql(u8, trimmed, "i32") or std.mem.eql(u8, trimmed, "u32")) return 32;
    if (std.mem.eql(u8, trimmed, "i64") or std.mem.eql(u8, trimmed, "u64") or std.mem.eql(u8, trimmed, "usize")) return 64;
    return null;
}

fn isIntegerTypeText(text: []const u8) bool {
    return scalarWidthFromText(text) != null or std.mem.indexOf(u8, text, "comptime_int") != null;
}

pub fn sliceSumSummary(function: air_export.Function) ?SliceSumSummary {
    var slice: ?u32 = null;
    var slice_elem_ptr: ?u32 = null;
    var ptr_slice_len_ptr: ?u32 = null;
    var loop: ?u32 = null;
    for (function.instructions) |instruction| {
        switch (air_capabilities.pointerAggregateSemanticOpForOpcode(instruction.opcode)) {
            .slice => slice = slice orelse instruction.index,
            .slice_elem_ptr => slice_elem_ptr = slice_elem_ptr orelse instruction.index,
            .slice_len_ptr => ptr_slice_len_ptr = ptr_slice_len_ptr orelse instruction.index,
            .none, .runtime_nav_ptr, .array_to_slice, .array_elem_val, .field_ptr, .ptr_gep, .slice_ptr, .slice_ptr_ptr, .slice_len => {},
        }
        if (loop == null and std.mem.eql(u8, instruction.opcode, "loop")) {
            loop = instruction.index;
        }
    }
    return .{
        .slice = slice orelse return null,
        .slice_elem_ptr = slice_elem_ptr orelse return null,
        .ptr_slice_len_ptr = ptr_slice_len_ptr orelse return null,
        .loop = loop orelse return null,
    };
}

pub fn selectedSliceSumShape(function: air_export.Function) bool {
    return sliceSumSummary(function) != null;
}

pub fn typedSliceSumSummary(
    function_type: core.FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?TypedSliceLoopSummary {
    if (function_type.params.len != 2 or function_type.params[0].ir_type != .ptr or
        !function_type.params[1].ir_type.eql(.{ .int = 64 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return null;
    }
    const add_count = typedOpcodeCount(structured_air_v2, "add") + typedOpcodeCount(structured_air_v2, "add_safe");
    if (typedOpcodeCount(structured_air_v2, "arg") != 2 or
        typedOpcodeCount(structured_air_v2, "ptr_add") != 1 or
        typedOpcodeCount(structured_air_v2, "slice") != 1 or
        typedOpcodeCount(structured_air_v2, "ptr_slice_len_ptr") != 1 or
        typedOpcodeCount(structured_air_v2, "slice_elem_ptr") != 1 or
        typedOpcodeCount(structured_air_v2, "loop") != 1 or
        typedOpcodeCount(structured_air_v2, "repeat") != 1 or
        typedOpcodeCount(structured_air_v2, "cond_br") < 1 or
        typedOpcodeCount(structured_air_v2, "cmp_lt") < 1 or
        add_count != 2 or
        typedOpcodeCount(structured_air_v2, "load") < 6 or
        typedStoreOpcodeCount(structured_air_v2) < 5 or
        !typedHasReturnOpcode(structured_air_v2))
    {
        return null;
    }
    return .{ .kind = .plain_sum };
}

pub fn typedConditionalSliceSumSummary(
    function_type: core.FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?TypedSliceLoopSummary {
    if (function_type.params.len != 3 or function_type.params[0].ir_type != .ptr or
        !function_type.params[1].ir_type.eql(.{ .int = 64 }) or
        !function_type.params[2].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return null;
    }
    const add_count = typedOpcodeCount(structured_air_v2, "add") + typedOpcodeCount(structured_air_v2, "add_safe");
    if (typedOpcodeCount(structured_air_v2, "arg") != 3 or
        typedOpcodeCount(structured_air_v2, "alloc") != 3 or
        typedOpcodeCount(structured_air_v2, "ptr_elem_ptr") != 1 or
        typedOpcodeCount(structured_air_v2, "loop") != 1 or
        typedOpcodeCount(structured_air_v2, "repeat") != 1 or
        typedOpcodeCount(structured_air_v2, "block") < 3 or
        typedOpcodeCount(structured_air_v2, "cond_br") != 2 or
        typedOpcodeCount(structured_air_v2, "br") < 4 or
        typedOpcodeCount(structured_air_v2, "cmp_lt") != 1 or
        typedOpcodeCount(structured_air_v2, "cmp_gt") != 1 or
        add_count != 2 or
        typedOpcodeCount(structured_air_v2, "load") < 6 or
        typedStoreOpcodeCount(structured_air_v2) < 5 or
        !typedHasReturnOpcode(structured_air_v2))
    {
        return null;
    }
    return .{ .kind = .conditional_sum };
}

pub fn typedAccumulatorLoopSummary(
    function_type: core.FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?core.TypedScalarControlSummary {
    if (function_type.params.len != 1 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return null;
    }
    const add_count = typedOpcodeCount(structured_air_v2, "add") + typedOpcodeCount(structured_air_v2, "add_safe");
    const intcast_count = typedOpcodeCount(structured_air_v2, "intcast") +
        typedOpcodeCount(structured_air_v2, "intcast_safe") +
        typedOpcodeCount(structured_air_v2, "int_cast") +
        typedOpcodeCount(structured_air_v2, "int_cast_safe");
    if (typedOpcodeCount(structured_air_v2, "arg") != 1 or
        typedOpcodeCount(structured_air_v2, "alloc") != 2 or
        typedOpcodeCount(structured_air_v2, "loop") != 1 or
        typedOpcodeCount(structured_air_v2, "repeat") != 1 or
        typedOpcodeCount(structured_air_v2, "cond_br") != 1 or
        typedOpcodeCount(structured_air_v2, "cmp_lt") != 1 or
        intcast_count != 1 or
        add_count != 2 or
        typedOpcodeCount(structured_air_v2, "load") < 4 or
        typedStoreOpcodeCount(structured_air_v2) < 4 or
        !typedHasReturnOpcode(structured_air_v2))
    {
        return null;
    }
    return .{ .kind = .accumulator_loop };
}

pub fn typedConditionalSlotUpdateSummary(
    function_type: core.FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?core.TypedScalarControlSummary {
    if (function_type.params.len != 3 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.params[1].ir_type.eql(.{ .int = 32 }) or
        !function_type.params[2].ir_type.eql(.{ .int = 1 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return null;
    }
    const add_count = typedOpcodeCount(structured_air_v2, "add") + typedOpcodeCount(structured_air_v2, "add_safe");
    const sub_count = typedOpcodeCount(structured_air_v2, "sub") + typedOpcodeCount(structured_air_v2, "sub_safe");
    if (typedOpcodeCount(structured_air_v2, "arg") != 3 or
        typedOpcodeCount(structured_air_v2, "alloc") != 1 or
        typedOpcodeCount(structured_air_v2, "block") != 1 or
        typedOpcodeCount(structured_air_v2, "cond_br") != 1 or
        typedOpcodeCount(structured_air_v2, "br") != 2 or
        add_count != 1 or
        sub_count != 1 or
        typedOpcodeCount(structured_air_v2, "load") < 3 or
        typedStoreOpcodeCount(structured_air_v2) < 4 or
        !typedHasReturnOpcode(structured_air_v2))
    {
        return null;
    }
    return .{ .kind = .conditional_slot_update };
}
