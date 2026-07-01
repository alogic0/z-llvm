const std = @import("std");
const air_export = @import("zig_air_export.zig");
const air_capabilities = @import("zig_air_capabilities.zig");
const air_model = @import("zig_air_model.zig");
const air_types = @import("zig_air_types.zig");

const parseZigType = air_types.parseZigType;

pub fn lowerTypedOptionalSemanticInstruction(self: anytype, instruction: air_export.TypedInstruction) !bool {
    switch (air_capabilities.optionalSemanticOpForOpcode(instruction.opcode)) {
        .is_non_null => try self.lowerTypedIsNonNull(instruction),
        .wrap_optional => try self.lowerTypedWrapOptional(instruction),
        .optional_payload => try self.lowerTypedOptionalPayload(instruction),
        .none => return false,
    }
    return true;
}

pub fn lowerTypedIsNonNull(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (instruction.operands.len != 1) return air_model.LowerError.UnsupportedAir;
    const pointer = try self.resolveTypedOperand(instruction, 0);
    if (pointer.ty.ir_type != .ptr) return air_model.LowerError.UnsupportedAir;
    const result_name = try self.resultName(instruction.index);
    try self.block.instructions.append(self.allocator, .{
        .result = result_name,
        .kind = .{ .icmp = .{
            .predicate = .ne,
            .operand_ty = .ptr,
            .lhs = pointer.value,
            .rhs = .null_value,
        } },
    });
    self.values[instruction.index] = .{
        .ty = .{ .ir_type = .{ .int = 1 } },
        .value = .{ .named = result_name },
    };
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
}

pub fn lowerTypedOptionalPayload(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (instruction.operands.len != 1) return air_model.LowerError.UnsupportedAir;
    const payload_type = parseZigType(instruction.result_type) orelse return air_model.LowerError.UnsupportedAir;
    const optional = try self.resolveTypedOperand(instruction, 0);
    if (!std.mem.startsWith(u8, instruction.operands[0].type_text, "?")) return air_model.LowerError.UnsupportedAir;
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
