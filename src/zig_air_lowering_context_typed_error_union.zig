const std = @import("std");
const air_export = @import("zig_air_export.zig");
const air_capabilities = @import("zig_air_capabilities.zig");
const air_model = @import("zig_air_model.zig");
const air_types = @import("zig_air_types.zig");
const ir = @import("ir.zig");

const parseZigType = air_types.parseZigType;
const isErrorUnionTypeText = air_types.isErrorUnionTypeText;
const errorUnionPayloadType = air_types.errorUnionPayloadType;
const ownPrint = air_model.ownPrint;

pub fn lowerTypedErrorUnionSemanticInstruction(self: anytype, instruction: air_export.TypedInstruction) !bool {
    switch (air_capabilities.errorUnionSemanticOpForOpcode(instruction.opcode)) {
        .is_non_err => try self.lowerTypedIsNonErr(instruction),
        .wrap_payload => try self.lowerTypedWrapErrorUnionPayload(instruction),
        .wrap_err => try self.lowerTypedWrapErrorUnionErr(instruction),
        .unwrap_payload => try self.lowerTypedUnwrapErrorUnionPayload(instruction),
        .unwrap_err => try self.lowerTypedUnwrapErrorUnionErr(instruction),
        .unwrap_payload_ptr => try self.lowerTypedUnwrapErrorUnionPayloadPtr(instruction),
        .unwrap_err_ptr => try self.lowerTypedUnwrapErrorUnionErrPtr(instruction),
        .try_op => try self.lowerTypedTry(instruction),
        .try_ptr => try self.lowerTypedTryPtr(instruction),
        .none => return false,
    }
    return true;
}

pub fn lowerTypedIsNonErr(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (instruction.operands.len != 1) return air_model.LowerError.UnsupportedAir;
    const err_union = try self.resolveTypedOperand(instruction, 0);
    if (!isErrorUnionTypeText(instruction.operands[0].type_text) or !err_union.ty.ir_type.eql(.{ .int = 64 })) {
        return air_model.LowerError.UnsupportedAir;
    }
    const error_bits = try self.emitErrorUnionErrorBits(instruction.index, err_union.value, "errbits");
    const result_name = try self.resultName(instruction.index);
    try self.block.instructions.append(self.allocator, .{
        .result = result_name,
        .kind = .{ .icmp = .{
            .predicate = .eq,
            .operand_ty = .{ .int = 64 },
            .lhs = .{ .named = error_bits },
            .rhs = .{ .int = 0 },
        } },
    });
    self.values[instruction.index] = .{
        .ty = .{ .ir_type = .{ .int = 1 } },
        .value = .{ .named = result_name },
    };
}

pub fn lowerTypedWrapErrorUnionPayload(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (instruction.operands.len != 1) return air_model.LowerError.UnsupportedAir;
    const result_type = parseZigType(instruction.result_type) orelse return air_model.LowerError.UnsupportedAir;
    if (!isErrorUnionTypeText(instruction.result_type) or !result_type.ir_type.eql(.{ .int = 64 })) return air_model.LowerError.UnsupportedAir;
    const payload = try self.resolveTypedOperand(instruction, 0);
    if (!payload.ty.ir_type.eql(.{ .int = 32 })) return air_model.LowerError.UnsupportedAir;
    const result_name = try self.encodeErrorUnionPayload(instruction.index, payload.value);
    self.values[instruction.index] = .{
        .ty = result_type,
        .value = .{ .named = result_name },
    };
}

pub fn lowerTypedWrapErrorUnionErr(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (instruction.operands.len != 1) return air_model.LowerError.UnsupportedAir;
    const result_type = parseZigType(instruction.result_type) orelse return air_model.LowerError.UnsupportedAir;
    if (!isErrorUnionTypeText(instruction.result_type) or !result_type.ir_type.eql(.{ .int = 64 })) return air_model.LowerError.UnsupportedAir;
    const err = try self.resolveTypedOperand(instruction, 0);
    if (!err.ty.ir_type.eql(.{ .int = 16 })) return air_model.LowerError.UnsupportedAir;
    const result_name = try self.resultName(instruction.index);
    try self.block.instructions.append(self.allocator, .{
        .result = result_name,
        .kind = .{ .cast = .{
            .op = .zext,
            .from_ty = .{ .int = 16 },
            .value = err.value,
            .to_ty = .{ .int = 64 },
        } },
    });
    self.values[instruction.index] = .{
        .ty = result_type,
        .value = .{ .named = result_name },
    };
}

pub fn lowerTypedUnwrapErrorUnionPayload(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (instruction.operands.len != 1) return air_model.LowerError.UnsupportedAir;
    const payload_type = parseZigType(instruction.result_type) orelse return air_model.LowerError.UnsupportedAir;
    if (!payload_type.ir_type.eql(.{ .int = 32 })) return air_model.LowerError.UnsupportedAir;
    const err_union = try self.resolveTypedOperand(instruction, 0);
    if (!isErrorUnionTypeText(instruction.operands[0].type_text) or !err_union.ty.ir_type.eql(.{ .int = 64 })) {
        return air_model.LowerError.UnsupportedAir;
    }
    const result_name = try self.decodeErrorUnionPayload(instruction.index, err_union.value);
    self.values[instruction.index] = .{
        .ty = payload_type,
        .value = .{ .named = result_name },
    };
}

pub fn lowerTypedUnwrapErrorUnionErr(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (instruction.operands.len != 1) return air_model.LowerError.UnsupportedAir;
    const err_type = parseZigType(instruction.result_type) orelse return air_model.LowerError.UnsupportedAir;
    if (!err_type.ir_type.eql(.{ .int = 16 })) return air_model.LowerError.UnsupportedAir;
    const err_union = try self.resolveTypedOperand(instruction, 0);
    if (!isErrorUnionTypeText(instruction.operands[0].type_text) or !err_union.ty.ir_type.eql(.{ .int = 64 })) {
        return air_model.LowerError.UnsupportedAir;
    }
    const error_bits = try self.emitErrorUnionErrorBits(instruction.index, err_union.value, "errbits");
    const result_name = try self.resultName(instruction.index);
    try self.block.instructions.append(self.allocator, .{
        .result = result_name,
        .kind = .{ .cast = .{
            .op = .trunc,
            .from_ty = .{ .int = 64 },
            .value = .{ .named = error_bits },
            .to_ty = .{ .int = 16 },
        } },
    });
    self.values[instruction.index] = .{
        .ty = err_type,
        .value = .{ .named = result_name },
    };
}

pub fn lowerTypedUnwrapErrorUnionErrPtr(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (instruction.operands.len != 1) return air_model.LowerError.UnsupportedAir;
    const err_type = parseZigType(instruction.result_type) orelse return air_model.LowerError.UnsupportedAir;
    if (!err_type.ir_type.eql(.{ .int = 16 })) return air_model.LowerError.UnsupportedAir;
    const loaded_union = try self.loadErrorUnionPointerValue(instruction, "errptr_union");
    const error_bits = try self.emitErrorUnionErrorBits(instruction.index, .{ .named = loaded_union }, "errptr_bits");
    const result_name = try self.resultName(instruction.index);
    try self.block.instructions.append(self.allocator, .{
        .result = result_name,
        .kind = .{ .cast = .{
            .op = .trunc,
            .from_ty = .{ .int = 64 },
            .value = .{ .named = error_bits },
            .to_ty = .{ .int = 16 },
        } },
    });
    self.values[instruction.index] = .{
        .ty = err_type,
        .value = .{ .named = result_name },
    };
}

pub fn lowerTypedUnwrapErrorUnionPayloadPtr(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (instruction.operands.len != 1) return air_model.LowerError.UnsupportedAir;
    const pointer_type = parseZigType(instruction.result_type) orelse return air_model.LowerError.UnsupportedAir;
    if (pointer_type.ir_type != .ptr or pointer_type.pointer_child == null) return air_model.LowerError.UnsupportedAir;
    const loaded_union = try self.loadErrorUnionPointerValue(instruction, "payloadptr_union");
    const payload_name = try self.decodeErrorUnionPayload(instruction.index, .{ .named = loaded_union });
    self.synthetic_pointer_payloads[instruction.index] = .{
        .ty = .{ .ir_type = pointer_type.pointer_child.? },
        .value = .{ .named = payload_name },
    };
    self.values[instruction.index] = .{
        .ty = pointer_type,
        .value = .undef,
    };
}

pub fn lowerTypedTry(self: anytype, instruction: air_export.TypedInstruction) air_model.LowerError!void {
    if (instruction.operands.len != 1) return air_model.LowerError.UnsupportedAir;
    const err_union = try self.resolveTypedOperand(instruction, 0);
    if (!isErrorUnionTypeText(instruction.operands[0].type_text) or
        !err_union.ty.ir_type.eql(.{ .int = 64 }) or
        !self.function_type.return_type.ir_type.eql(err_union.ty.ir_type))
    {
        return air_model.LowerError.UnsupportedAir;
    }
    const payload_type = errorUnionPayloadType(instruction.operands[0].type_text) orelse return air_model.LowerError.UnsupportedAir;
    if (!payload_type.ir_type.eql(.{ .int = 32 })) return air_model.LowerError.UnsupportedAir;

    const error_bits = try self.emitErrorUnionErrorBits(instruction.index, err_union.value, "try_errbits");
    const ok_name = try ownPrint(self.module, "air{}_try_ok", .{instruction.index});
    try self.block.instructions.append(self.allocator, .{
        .result = ok_name,
        .kind = .{ .icmp = .{
            .predicate = .eq,
            .operand_ty = .{ .int = 64 },
            .lhs = .{ .named = error_bits },
            .rhs = .{ .int = 0 },
        } },
    });
    const err_label = try ownPrint(self.module, "try{}_err", .{instruction.index});
    const cont_label = try ownPrint(self.module, "try{}_cont", .{instruction.index});
    var finished = self.block.*;
    finished.terminator = .{ .condbr = .{
        .cond_ty = .{ .int = 1 },
        .cond = .{ .named = ok_name },
        .then_target = cont_label,
        .else_target = err_label,
    } };
    self.block.* = ir.BasicBlock.init(err_label);
    try self.function.blocks.append(self.allocator, finished);

    var err_block = self.block.*;
    err_block.terminator = .{ .ret = .{
        .ty = self.function_type.return_type.ir_type,
        .value = err_union.value,
    } };
    self.block.* = ir.BasicBlock.init(cont_label);
    try self.function.blocks.append(self.allocator, err_block);

    const payload_name = try self.decodeErrorUnionPayload(instruction.index, err_union.value);
    self.values[instruction.index] = .{
        .ty = payload_type,
        .value = .{ .named = payload_name },
    };
}

pub fn lowerTypedTryPtr(self: anytype, instruction: air_export.TypedInstruction) air_model.LowerError!void {
    if (instruction.operands.len != 1) return air_model.LowerError.UnsupportedAir;
    const pointer_type = typedTryPtrPayloadPointerType(instruction) orelse return air_model.LowerError.UnsupportedAir;
    if (pointer_type.ir_type != .ptr or pointer_type.pointer_child == null) return air_model.LowerError.UnsupportedAir;
    if (!self.function_type.return_type.ir_type.eql(.{ .int = 64 })) return air_model.LowerError.UnsupportedAir;

    const loaded_union = try self.loadErrorUnionPointerValue(instruction, "tryptr_union");
    const error_bits = try self.emitErrorUnionErrorBits(instruction.index, .{ .named = loaded_union }, "tryptr_errbits");
    const ok_name = try self.resultName(instruction.index);
    try self.block.instructions.append(self.allocator, .{
        .result = ok_name,
        .kind = .{ .icmp = .{
            .predicate = .eq,
            .operand_ty = .{ .int = 64 },
            .lhs = .{ .named = error_bits },
            .rhs = .{ .int = 0 },
        } },
    });

    const err_label = try ownPrint(self.module, "tryptr{}_err", .{instruction.index});
    const cont_label = try ownPrint(self.module, "tryptr{}_cont", .{instruction.index});
    var finished = self.block.*;
    finished.terminator = .{ .condbr = .{
        .cond_ty = .{ .int = 1 },
        .cond = .{ .named = ok_name },
        .then_target = cont_label,
        .else_target = err_label,
    } };
    self.block.* = ir.BasicBlock.init(err_label);
    try self.function.blocks.append(self.allocator, finished);

    var err_block = self.block.*;
    err_block.terminator = .{ .ret = .{
        .ty = self.function_type.return_type.ir_type,
        .value = .{ .named = loaded_union },
    } };
    self.block.* = ir.BasicBlock.init(cont_label);
    try self.function.blocks.append(self.allocator, err_block);

    const payload_name = try self.decodeErrorUnionPayload(instruction.index, .{ .named = loaded_union });
    self.synthetic_pointer_payloads[instruction.index] = .{
        .ty = .{ .ir_type = pointer_type.pointer_child.? },
        .value = .{ .named = payload_name },
    };
    self.values[instruction.index] = .{
        .ty = pointer_type,
        .value = .undef,
    };
}

pub fn loadErrorUnionPointerValue(
    self: anytype,
    instruction: air_export.TypedInstruction,
    suffix: []const u8,
) air_model.LowerError![]const u8 {
    if (try self.syntheticErrorUnionPointerValueName(instruction)) |value_name| return value_name;
    const pointer = try self.resolveTypedOperand(instruction, 0);
    if (pointer.ty.ir_type != .ptr or
        !errorUnionPointerOperandText(instruction.operands[0].type_text) or
        pointer.ty.pointer_child == null or
        !pointer.ty.pointer_child.?.eql(.{ .int = 64 }))
    {
        return air_model.LowerError.UnsupportedAir;
    }
    const loaded_name = try ownPrint(self.module, "air{}_{s}", .{ instruction.index, suffix });
    try self.block.instructions.append(self.allocator, .{
        .result = loaded_name,
        .kind = .{ .load = .{
            .ty = .{ .int = 64 },
            .ptr = pointer.value,
            .attrs = .{ .is_volatile = pointer.ty.is_volatile_pointer },
        } },
    });
    return loaded_name;
}

pub fn syntheticErrorUnionPointerValueName(
    self: anytype,
    instruction: air_export.TypedInstruction,
) air_model.LowerError!?[]const u8 {
    const pointer_index = air_model.typedInstOperandIndex(instruction.operands[0]) orelse return null;
    if (pointer_index >= self.synthetic_error_union_slots.len) return air_model.LowerError.UnsupportedAir;
    const loaded = self.synthetic_error_union_slots[pointer_index] orelse return null;
    if (!loaded.ty.ir_type.eql(.{ .int = 64 })) return air_model.LowerError.UnsupportedAir;
    return switch (loaded.value) {
        .named => |name| name,
        else => air_model.LowerError.UnsupportedAir,
    };
}

pub fn materializeErrorUnionPayloadPointer(
    self: anytype,
    instruction_index: u32,
    pointer_type: air_model.ZigType,
    err_union_value: ir.Value,
) air_model.LowerError![]const u8 {
    const payload_type = pointer_type.pointer_child orelse return air_model.LowerError.UnsupportedAir;
    if (!payload_type.eql(.{ .int = 32 })) return air_model.LowerError.UnsupportedAir;
    const pointer_name = try self.allocateErrorUnionPayloadPointer(instruction_index, pointer_type);
    try self.storeErrorUnionPayloadIntoPointer(instruction_index, pointer_type, pointer_name, err_union_value);
    return pointer_name;
}

pub fn allocateErrorUnionPayloadPointer(
    self: anytype,
    instruction_index: u32,
    pointer_type: air_model.ZigType,
) air_model.LowerError![]const u8 {
    const payload_type = pointer_type.pointer_child orelse return air_model.LowerError.UnsupportedAir;
    if (!payload_type.eql(.{ .int = 32 })) return air_model.LowerError.UnsupportedAir;
    const pointer_name = try self.resultName(instruction_index);
    try self.block.instructions.append(self.allocator, .{
        .result = pointer_name,
        .kind = .{ .alloca = .{ .allocated_ty = payload_type } },
    });
    return pointer_name;
}

pub fn storeErrorUnionPayloadIntoPointer(
    self: anytype,
    instruction_index: u32,
    pointer_type: air_model.ZigType,
    pointer_name: []const u8,
    err_union_value: ir.Value,
) air_model.LowerError!void {
    const payload_type = pointer_type.pointer_child orelse return air_model.LowerError.UnsupportedAir;
    if (!payload_type.eql(.{ .int = 32 })) return air_model.LowerError.UnsupportedAir;
    const payload_prefix = try ownPrint(self.module, "air{}_payload_value", .{instruction_index});
    const payload_name = try self.decodeErrorUnionPayloadWithPrefix(payload_prefix, err_union_value);
    try self.block.instructions.append(self.allocator, .{
        .result = null,
        .kind = .{ .store = .{
            .ty = payload_type,
            .value = .{ .named = payload_name },
            .ptr = .{ .named = pointer_name },
        } },
    });
}

pub fn emitErrorUnionErrorBits(
    self: anytype,
    instruction_index: u32,
    value: ir.Value,
    suffix: []const u8,
) ![]const u8 {
    const result_name = try ownPrint(self.module, "air{}_{s}", .{ instruction_index, suffix });
    try self.block.instructions.append(self.allocator, .{
        .result = result_name,
        .kind = .{ .binary = .{
            .op = .@"and",
            .ty = .{ .int = 64 },
            .lhs = value,
            .rhs = .{ .int = 0xffff },
        } },
    });
    return result_name;
}

pub fn encodeErrorUnionPayload(self: anytype, instruction_index: u32, payload: ir.Value) ![]const u8 {
    const prefix = try self.resultName(instruction_index);
    return try self.encodeErrorUnionPayloadWithPrefix(prefix, payload);
}

pub fn encodeErrorUnionPayloadWithPrefix(self: anytype, prefix: []const u8, payload: ir.Value) ![]const u8 {
    const wide_name = try ownPrint(self.module, "{s}_payload64", .{prefix});
    try self.block.instructions.append(self.allocator, .{
        .result = wide_name,
        .kind = .{ .cast = .{
            .op = .zext,
            .from_ty = .{ .int = 32 },
            .value = payload,
            .to_ty = .{ .int = 64 },
        } },
    });
    try self.block.instructions.append(self.allocator, .{
        .result = prefix,
        .kind = .{ .binary = .{
            .op = .shl,
            .ty = .{ .int = 64 },
            .lhs = .{ .named = wide_name },
            .rhs = .{ .int = 16 },
        } },
    });
    return prefix;
}

pub fn decodeErrorUnionPayload(self: anytype, instruction_index: u32, value: ir.Value) ![]const u8 {
    const result_name = try self.resultName(instruction_index);
    return self.decodeErrorUnionPayloadWithPrefix(result_name, value);
}

pub fn decodeErrorUnionPayloadWithPrefix(self: anytype, result_name: []const u8, value: ir.Value) ![]const u8 {
    const shifted_name = try ownPrint(self.module, "{s}_shift", .{result_name});
    try self.block.instructions.append(self.allocator, .{
        .result = shifted_name,
        .kind = .{ .binary = .{
            .op = .lshr,
            .ty = .{ .int = 64 },
            .lhs = value,
            .rhs = .{ .int = 16 },
        } },
    });
    try self.block.instructions.append(self.allocator, .{
        .result = result_name,
        .kind = .{ .cast = .{
            .op = .trunc,
            .from_ty = .{ .int = 64 },
            .value = .{ .named = shifted_name },
            .to_ty = .{ .int = 32 },
        } },
    });
    return result_name;
}

fn typedTryPtrPayloadPointerType(instruction: air_export.TypedInstruction) ?air_model.ZigType {
    if (parseZigType(instruction.result_type)) |ty| return ty;
    const detail = air_model.detail(instruction, "payload_ptr_type") orelse return null;
    const trimmed = std.mem.trim(u8, detail, " ");
    if (!std.mem.startsWith(u8, trimmed, "<type,") or !std.mem.endsWith(u8, trimmed, ">")) return null;
    const type_text = std.mem.trim(u8, trimmed["<type,".len .. trimmed.len - 1], " ");
    return parseZigType(type_text);
}

fn errorUnionPointerOperandText(type_text: []const u8) bool {
    const child_text = air_types.pointerChildText(std.mem.trim(u8, type_text, " ")) orelse return false;
    return air_types.isErrorUnionTypeText(child_text);
}
