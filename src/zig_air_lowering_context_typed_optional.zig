const std = @import("std");
const air_export = @import("zig_air_export.zig");
const air_capabilities = @import("zig_air_capabilities.zig");
const air_model = @import("zig_air_model.zig");
const air_types = @import("zig_air_types.zig");
const ir = @import("ir.zig");
const optional_layout = @import("zig_air_optional_layout.zig");

const parseZigType = air_types.parseZigType;
const ownPrint = air_model.ownPrint;

pub fn lowerTypedOptionalSemanticInstruction(self: anytype, instruction: air_export.TypedInstruction) !bool {
    switch (air_capabilities.optionalSemanticOpForOpcode(instruction.opcode)) {
        .is_non_null => try self.lowerTypedIsNonNull(instruction),
        .is_null => try self.lowerTypedIsNull(instruction),
        .wrap_optional => try self.lowerTypedWrapOptional(instruction),
        .optional_payload => try self.lowerTypedOptionalPayload(instruction),
        .none => return false,
    }
    return true;
}

fn lowerTypedOptionalNullCheck(self: anytype, instruction: air_export.TypedInstruction, is_null_check: bool) !void {
    if (instruction.operands.len != 1) return air_model.LowerError.UnsupportedAir;
    const operand = try self.resolveTypedOperand(instruction, 0);
    const is_pointer = std.mem.eql(u8, instruction.opcode, "is_null_ptr") or
        std.mem.eql(u8, instruction.opcode, "is_non_null_ptr");
    var value: ir.Value = undefined;
    var value_type: ir.Type = undefined;
    if (is_pointer) {
        if (operand.ty.ir_type != .ptr) return air_model.LowerError.UnsupportedAir;
        const optional_text = air_types.pointerChildText(instruction.operands[0].type_text) orelse return air_model.LowerError.UnsupportedAir;
        const repr = optional_layout.representation(optional_text) orelse return air_model.LowerError.UnsupportedAir;
        if (repr.tag_offset) |offset| {
            value = try optional_layout.loadTag(self, instruction.index, operand.value, offset, operand.ty.is_volatile_pointer);
            value_type = .{ .int = 8 };
        } else {
            const name = try ownPrint(self.module, "air{}_optional_pointer_value", .{instruction.index});
            try self.block.instructions.append(self.allocator, .{ .result = name, .kind = .{ .load = .{
                .ty = .ptr,
                .ptr = operand.value,
                .attrs = .{ .is_volatile = operand.ty.is_volatile_pointer },
            } } });
            value = .{ .named = name };
            value_type = .ptr;
        }
    } else {
        const snapshot = if (air_model.typedInstOperandIndex(instruction.operands[0])) |idx|
            if (idx < self.synthetic_optional_ptrs.len) self.synthetic_optional_ptrs[idx] else null
        else
            null;
        if (snapshot) |captured| {
            value = captured.tag_value orelse return air_model.LowerError.UnsupportedAir;
            value_type = .{ .int = 8 };
        } else {
            const repr = optional_layout.representation(instruction.operands[0].type_text) orelse return air_model.LowerError.UnsupportedAir;
            if (repr.tag_offset != null or operand.ty.ir_type != .ptr) return air_model.LowerError.UnsupportedAir;
            value = operand.value;
            value_type = .ptr;
        }
    }
    if (value == .int or value == .null_value) {
        const is_null = value == .null_value or value.int == 0;
        self.values[instruction.index] = .{
            .ty = .{ .ir_type = .{ .int = 1 } },
            .value = .{ .int = @intFromBool(is_null == is_null_check) },
        };
        return;
    }
    const name = try self.resultName(instruction.index);
    try self.block.instructions.append(self.allocator, .{ .result = name, .kind = .{ .icmp = .{
        .predicate = if (is_null_check) .eq else .ne,
        .operand_ty = value_type,
        .lhs = value,
        .rhs = if (value_type == .ptr) .null_value else .{ .int = 0 },
    } } });
    self.values[instruction.index] = .{ .ty = .{ .ir_type = .{ .int = 1 } }, .value = .{ .named = name } };
}

pub fn lowerTypedIsNonNull(self: anytype, instruction: air_export.TypedInstruction) !void {
    try lowerTypedOptionalNullCheck(self, instruction, false);
}

pub fn lowerTypedIsNull(self: anytype, instruction: air_export.TypedInstruction) !void {
    try lowerTypedOptionalNullCheck(self, instruction, true);
}

pub fn lowerTypedWrapOptional(self: anytype, instruction: air_export.TypedInstruction) !void {
    const summary = air_model.typedWrapOptionalSummary(instruction) orelse return air_model.LowerError.UnsupportedAir;
    const optional_type = parseZigType(summary.optional_type_text) orelse return air_model.LowerError.UnsupportedAir;
    const payload = try self.resolveTypedOperand(instruction, 0);
    if (!payload.ty.ir_type.eql(optional_type.ir_type)) return air_model.LowerError.UnsupportedAir;
    self.values[instruction.index] = .{
        .ty = optional_type,
        .value = payload.value,
    };
    const repr = optional_layout.representation(summary.optional_type_text) orelse return air_model.LowerError.UnsupportedAir;
    if (repr.tag_offset != null) {
        if (instruction.index >= self.synthetic_optional_ptrs.len) return air_model.LowerError.UnsupportedAir;
        self.synthetic_optional_ptrs[instruction.index] = .{
            .base_ptr = .undef,
            .optional_type_text = summary.optional_type_text,
            .tag_value = .{ .int = 1 },
            .payload_value = payload,
        };
    }
}

pub fn lowerTypedOptionalPayload(self: anytype, instruction: air_export.TypedInstruction) !void {
    const summary = air_model.typedOptionalPayloadExtractionSummary(instruction) orelse return air_model.LowerError.UnsupportedAir;
    const payload_type = parseZigType(summary.payload_type_text) orelse return air_model.LowerError.UnsupportedAir;
    const operand_index = air_model.typedInstOperandIndex(instruction.operands[0]);
    if (operand_index) |op_idx| {
        if (op_idx < self.synthetic_optional_ptrs.len) {
            if (self.synthetic_optional_ptrs[op_idx]) |opt_info| {
                if (std.mem.eql(u8, instruction.opcode, "optional_payload_ptr")) {
                    self.values[instruction.index] = .{
                        .ty = payload_type,
                        .value = opt_info.base_ptr,
                    };
                    return;
                }
                const payload = opt_info.payload_value orelse return air_model.LowerError.UnsupportedAir;
                if (!payload.ty.ir_type.eql(payload_type.ir_type)) return air_model.LowerError.UnsupportedAir;
                self.values[instruction.index] = payload;
                return;
            }
        }
    }
    if (!air_types.optionalUsesPointerSentinel(summary.optional_type_text)) return air_model.LowerError.UnsupportedAir;
    const optional = try self.resolveTypedOperand(instruction, 0);
    if (payload_type.ir_type == .ptr) {
        if (optional.ty.ir_type != .ptr) return air_model.LowerError.UnsupportedAir;
    } else {
        if (!optional.ty.ir_type.eql(payload_type.ir_type)) return air_model.LowerError.UnsupportedAir;
    }
    self.values[instruction.index] = .{
        .ty = payload_type,
        .value = optional.value,
    };
}
