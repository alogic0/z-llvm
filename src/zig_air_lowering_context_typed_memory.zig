const std = @import("std");
const air_export = @import("zig_air_export.zig");
const air_capabilities = @import("zig_air_capabilities.zig");
const air_model = @import("zig_air_model.zig");
const air_types = @import("zig_air_types.zig");

const parseZigType = air_types.parseZigType;
const pointerLoadResultType = air_types.pointerLoadResultType;

pub fn lowerTypedMemorySemanticInstruction(self: anytype, instruction: air_export.TypedInstruction) !bool {
    switch (air_capabilities.memorySemanticOpForOpcode(instruction.opcode)) {
        .alloc => try self.lowerTypedAlloca(instruction),
        .load => try self.lowerTypedLoad(instruction),
        .store => try self.lowerTypedStore(instruction),
        .none => return false,
    }
    return true;
}

pub fn lowerTypedAlloca(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (instruction.operands.len != 0) return air_model.LowerError.UnsupportedAir;
    if (typedUnionTagSlotAlloc(self, instruction.index)) {
        self.values[instruction.index] = .{
            .ty = .{ .ir_type = .ptr },
            .value = .undef,
        };
        return;
    }
    const pointer_type = parseZigType(instruction.result_type) orelse return air_model.LowerError.UnsupportedAir;
    const allocated_type = pointer_type.pointer_child orelse return air_model.LowerError.UnsupportedAir;
    if (errorUnionPointerOperandText(instruction.result_type) and allocated_type.eql(.{ .int = 64 })) {
        self.values[instruction.index] = .{
            .ty = pointer_type,
            .value = .undef,
        };
        return;
    }
    const result_name = try self.resultName(instruction.index);
    try self.block.instructions.append(self.allocator, .{
        .result = result_name,
        .kind = .{ .alloca = .{ .allocated_ty = allocated_type } },
    });
    self.values[instruction.index] = .{
        .ty = pointer_type,
        .value = .{ .named = result_name },
    };
}

pub fn lowerTypedLoad(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (instruction.operands.len != 1) return air_model.LowerError.UnsupportedAir;
    if (try self.lowerTypedLoadFromSyntheticPointerPayload(instruction)) return;
    if (try self.lowerTypedLoadFromSyntheticErrorUnionSlot(instruction)) return;
    if (try self.lowerTypedLoadFromSyntheticUnionTagSlot(instruction)) return;
    if (try self.lowerTypedLoadFromSlicePtrPtr(instruction)) return;
    if (try self.lowerTypedLoadFromSliceLenPtr(instruction)) return;
    const pointer = try self.resolveTypedOperand(instruction, 0);
    if (pointer.ty.ir_type != .ptr) return air_model.LowerError.UnsupportedAir;
    const result_type = parseZigType(instruction.result_type) orelse blk: {
        const typed_child = pointerLoadResultType(instruction.operands[0].type_text);
        if (typed_child) |child| break :blk child;
        const child = pointer.ty.pointer_child orelse return air_model.LowerError.UnsupportedAir;
        break :blk air_model.ZigType{ .ir_type = child };
    };
    const result_name = try self.resultName(instruction.index);
    try self.block.instructions.append(self.allocator, .{
        .result = result_name,
        .kind = .{ .load = .{
            .ty = result_type.ir_type,
            .ptr = pointer.value,
            .attrs = .{ .is_volatile = pointer.ty.is_volatile_pointer },
        } },
    });
    self.values[instruction.index] = .{
        .ty = result_type,
        .value = .{ .named = result_name },
    };
}

pub fn lowerTypedLoadFromSyntheticPointerPayload(self: anytype, instruction: air_export.TypedInstruction) !bool {
    const pointer_index = air_model.typedInstOperandIndex(instruction.operands[0]) orelse return false;
    if (pointer_index >= self.synthetic_pointer_payloads.len) return air_model.LowerError.UnsupportedAir;
    const payload = self.synthetic_pointer_payloads[pointer_index] orelse return false;
    const result_type = parseZigType(instruction.result_type) orelse blk: {
        const typed_child = pointerLoadResultType(instruction.operands[0].type_text);
        if (typed_child) |child| break :blk child;
        break :blk payload.ty;
    };
    if (!result_type.ir_type.eql(payload.ty.ir_type)) return air_model.LowerError.UnsupportedAir;
    self.values[instruction.index] = payload;
    return true;
}

pub fn lowerTypedLoadFromSyntheticErrorUnionSlot(self: anytype, instruction: air_export.TypedInstruction) !bool {
    const pointer_index = air_model.typedInstOperandIndex(instruction.operands[0]) orelse return false;
    if (pointer_index >= self.synthetic_error_union_slots.len) return air_model.LowerError.UnsupportedAir;
    const loaded = self.synthetic_error_union_slots[pointer_index] orelse return false;
    const result_type = parseZigType(instruction.result_type) orelse blk: {
        const typed_child = pointerLoadResultType(instruction.operands[0].type_text);
        if (typed_child) |child| break :blk child;
        break :blk loaded.ty;
    };
    if (!result_type.ir_type.eql(loaded.ty.ir_type)) return air_model.LowerError.UnsupportedAir;
    self.values[instruction.index] = loaded;
    return true;
}

pub fn lowerTypedLoadFromSyntheticUnionTagSlot(self: anytype, instruction: air_export.TypedInstruction) !bool {
    const pointer_index = air_model.typedInstOperandIndex(instruction.operands[0]) orelse return false;
    if (pointer_index >= self.synthetic_union_tag_slots.len) return air_model.LowerError.UnsupportedAir;
    const loaded = self.synthetic_union_tag_slots[pointer_index] orelse return false;
    self.values[instruction.index] = loaded;
    if (instruction.index < self.synthetic_union_tag_slots.len) {
        self.synthetic_union_tag_slots[instruction.index] = loaded;
    }
    return true;
}

pub fn lowerTypedLoadFromSliceLenPtr(self: anytype, instruction: air_export.TypedInstruction) !bool {
    const view = self.typed_view orelse return false;
    const pointer_index = air_model.typedInstOperandIndex(instruction.operands[0]) orelse return false;
    const pointer_instruction = view.instruction(pointer_index) orelse return air_model.LowerError.UnsupportedAir;
    if (air_capabilities.pointerAggregateSemanticOpForOpcode(pointer_instruction.opcode) != .slice_len_ptr) return false;
    if (pointer_instruction.operands.len != 1) return air_model.LowerError.UnsupportedAir;

    const slice = try self.resolveTypedOperand(pointer_instruction, 0);
    const slice_value = try self.materializeSliceAggregateForLen(pointer_instruction.index, slice);
    const result_type = parseZigType(instruction.result_type) orelse blk: {
        const typed_child = pointerLoadResultType(instruction.operands[0].type_text);
        if (typed_child) |child| break :blk child;
        break :blk air_model.ZigType{ .ir_type = .{ .int = 64 } };
    };
    if (!result_type.ir_type.eql(.{ .int = 64 })) return air_model.LowerError.UnsupportedAir;

    const result_name = try self.resultName(instruction.index);
    try self.block.instructions.append(self.allocator, .{
        .result = result_name,
        .kind = .{ .extractvalue = .{
            .aggregate_ty = .{ .aggregate = "{ ptr, i64 }" },
            .aggregate = slice_value,
            .indices = "1",
            .result_ty = .{ .int = 64 },
        } },
    });
    self.values[instruction.index] = .{
        .ty = result_type,
        .value = .{ .named = result_name },
    };
    return true;
}

pub fn lowerTypedLoadFromSlicePtrPtr(self: anytype, instruction: air_export.TypedInstruction) !bool {
    const view = self.typed_view orelse return false;
    const pointer_index = air_model.typedInstOperandIndex(instruction.operands[0]) orelse return false;
    const pointer_instruction = view.instruction(pointer_index) orelse return air_model.LowerError.UnsupportedAir;
    if (air_capabilities.pointerAggregateSemanticOpForOpcode(pointer_instruction.opcode) != .slice_ptr_ptr) return false;
    if (pointer_instruction.operands.len != 1) return air_model.LowerError.UnsupportedAir;

    const slice = try self.resolveTypedOperand(pointer_instruction, 0);
    const slice_value = try self.materializeSliceAggregate(pointer_instruction.index, "slice_ptr_aggregate", slice);
    const result_type = parseZigType(instruction.result_type) orelse blk: {
        const typed_child = pointerLoadResultType(instruction.operands[0].type_text);
        if (typed_child) |child| break :blk child;
        break :blk air_model.ZigType{ .ir_type = .ptr };
    };
    if (result_type.ir_type != .ptr) return air_model.LowerError.UnsupportedAir;

    const result_name = try self.resultName(instruction.index);
    try self.block.instructions.append(self.allocator, .{
        .result = result_name,
        .kind = .{ .extractvalue = .{
            .aggregate_ty = .{ .aggregate = "{ ptr, i64 }" },
            .aggregate = slice_value,
            .indices = "0",
            .result_ty = .ptr,
        } },
    });
    self.values[instruction.index] = .{
        .ty = result_type,
        .value = .{ .named = result_name },
    };
    return true;
}

pub fn lowerTypedStore(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (instruction.operands.len != 2) return air_model.LowerError.UnsupportedAir;
    const pointer = try self.resolveTypedOperand(instruction, 0);
    if (pointer.ty.ir_type != .ptr) return air_model.LowerError.UnsupportedAir;
    if (try self.lowerTypedStoreToSyntheticUnionField(instruction)) return;
    const value = try self.resolveTypedOperand(instruction, 1);
    if (try self.lowerTypedStoreToSyntheticErrorUnionSlot(instruction, value)) return;
    try self.block.instructions.append(self.allocator, .{
        .result = null,
        .kind = .{ .store = .{
            .ty = value.ty.ir_type,
            .value = value.value,
            .ptr = pointer.value,
            .attrs = .{ .is_volatile = pointer.ty.is_volatile_pointer },
        } },
    });
}

pub fn lowerTypedStoreToSyntheticErrorUnionSlot(
    self: anytype,
    instruction: air_export.TypedInstruction,
    value: anytype,
) !bool {
    const pointer_index = air_model.typedInstOperandIndex(instruction.operands[0]) orelse return false;
    if (pointer_index >= self.synthetic_error_union_slots.len) return air_model.LowerError.UnsupportedAir;
    if (!errorUnionPointerOperandText(instruction.operands[0].type_text)) return false;
    if (!value.ty.ir_type.eql(.{ .int = 64 })) return air_model.LowerError.UnsupportedAir;
    self.synthetic_error_union_slots[pointer_index] = value;
    return true;
}

pub fn lowerTypedStoreToSyntheticUnionField(
    self: anytype,
    instruction: air_export.TypedInstruction,
) !bool {
    const pointer_index = air_model.typedInstOperandIndex(instruction.operands[0]) orelse return false;
    if (pointer_index >= self.synthetic_union_field_ptrs.len) return air_model.LowerError.UnsupportedAir;
    const field_ptr = self.synthetic_union_field_ptrs[pointer_index] orelse return false;
    if (field_ptr.slot_index >= self.synthetic_union_tag_slots.len) return air_model.LowerError.UnsupportedAir;
    return true;
}

fn typedUnionTagSlotAlloc(self: anytype, instruction_index: u32) bool {
    const view = self.typed_view orelse return false;
    for (view.structured_air_v2.instructions) |candidate| {
        const summary = air_model.typedUnionTagSetSummary(candidate) orelse continue;
        if (summary.pointer_index == instruction_index) return true;
    }
    return false;
}

fn errorUnionPointerOperandText(type_text: []const u8) bool {
    const child_text = air_types.pointerChildText(std.mem.trim(u8, type_text, " ")) orelse return false;
    return air_types.isErrorUnionTypeText(child_text);
}
