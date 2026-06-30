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
        .error_name => try self.lowerTypedErrorName(instruction),
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

pub fn lowerTypedErrorName(self: anytype, instruction: air_export.TypedInstruction) !void {
    const summary = (if (self.typed_view) |view|
        air_model.typedErrorNameSummaryFromV2(view.structured_air_v2, instruction)
    else
        air_model.typedErrorNameSummary(instruction)) orelse return air_model.LowerError.UnsupportedAir;
    const result_type = parseZigType(summary.result_type) orelse return air_model.LowerError.UnsupportedAir;
    if (!result_type.ir_type.eql(.{ .aggregate = "{ ptr, i64 }" })) return air_model.LowerError.UnsupportedAir;
    const err = try self.resolveTypedOperand(instruction, 0);
    if (!err.ty.ir_type.eql(.{ .int = 16 })) return air_model.LowerError.UnsupportedAir;

    const parts = try materializeErrorNameParts(self, instruction.index, summary.error_set_type, err.value);
    const ptr_name = try ownPrint(self.module, "air{}_error_name_ptr", .{instruction.index});
    try self.block.instructions.append(self.allocator, .{
        .result = ptr_name,
        .kind = .{ .insertvalue = .{
            .aggregate_ty = result_type.ir_type,
            .aggregate = .undef,
            .value_ty = .ptr,
            .value = parts.ptr,
            .indices = "0",
        } },
    });
    const result_name = try self.resultName(instruction.index);
    try self.block.instructions.append(self.allocator, .{
        .result = result_name,
        .kind = .{ .insertvalue = .{
            .aggregate_ty = result_type.ir_type,
            .aggregate = .{ .named = ptr_name },
            .value_ty = .{ .int = 64 },
            .value = parts.len,
            .indices = "1",
        } },
    });
    self.values[instruction.index] = .{
        .ty = result_type,
        .value = .{ .named = result_name },
    };
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
    const ok_name = try ownPrint(self.module, "air{}_tryptr_ok", .{instruction.index});
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

const ErrorNameParts = struct {
    ptr: ir.Value,
    len: ir.Value,
};

fn materializeErrorNameParts(
    self: anytype,
    instruction_index: u32,
    error_set_type: []const u8,
    err_value: ir.Value,
) !ErrorNameParts {
    switch (err_value) {
        .int => |code| {
            const name = air_model.errorSetNameForCode(error_set_type, code) orelse return air_model.LowerError.UnsupportedAir;
            return .{
                .ptr = try errorNameStringPointer(self, name),
                .len = .{ .int = @intCast(name.len) },
            };
        },
        .named => |name_value| {
            const names = try air_model.errorSetNamesAlloc(self.allocator, error_set_type) orelse return air_model.LowerError.UnsupportedAir;
            defer self.allocator.free(names);
            if (try materializeSelectedTwoNameErrorNameParts(self, instruction_index, name_value, names)) |parts| {
                return parts;
            }
            return try materializeDynamicErrorNameParts(self, instruction_index, name_value, names);
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return air_model.LowerError.UnsupportedAir,
    }
}

fn materializeSelectedTwoNameErrorNameParts(
    self: anytype,
    instruction_index: u32,
    name_value: []const u8,
    names: []const []const u8,
) !?ErrorNameParts {
    if (names.len != 2) return null;
    const selection = try errorNameSelectionFromValue(self, name_value) orelse return null;
    const first_ptr = try errorNameStringPointer(self, names[0]);
    const second_ptr = try errorNameStringPointer(self, names[1]);
    const ptr_name = try ownPrint(self.module, "air{}_error_name_selected_ptr", .{instruction_index});
    try self.block.instructions.append(self.allocator, .{
        .result = ptr_name,
        .kind = .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = selection.cond,
            .ty = .ptr,
            .true_value = if (selection.true_is_first) first_ptr else second_ptr,
            .false_value = if (selection.true_is_first) second_ptr else first_ptr,
        } },
    });
    const len_name = try ownPrint(self.module, "air{}_error_name_selected_len", .{instruction_index});
    try self.block.instructions.append(self.allocator, .{
        .result = len_name,
        .kind = .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = selection.cond,
            .ty = .{ .int = 64 },
            .true_value = .{ .int = @intCast(if (selection.true_is_first) names[0].len else names[1].len) },
            .false_value = .{ .int = @intCast(if (selection.true_is_first) names[1].len else names[0].len) },
        } },
    });
    return .{
        .ptr = .{ .named = ptr_name },
        .len = .{ .named = len_name },
    };
}

fn materializeDynamicErrorNameParts(
    self: anytype,
    instruction_index: u32,
    name_value: []const u8,
    names: []const []const u8,
) !ErrorNameParts {
    if (names.len == 0 or names.len > std.math.maxInt(u16)) return air_model.LowerError.UnsupportedAir;
    const code_value_name = canonicalErrorNameCodeValue(self, name_value);
    var selected_ptr = try errorNameStringPointer(self, names[names.len - 1]);
    var selected_len: ir.Value = .{ .int = @intCast(names[names.len - 1].len) };
    if (names.len == 1) {
        return .{ .ptr = selected_ptr, .len = selected_len };
    }

    var code: usize = names.len - 1;
    while (code > 0) : (code -= 1) {
        const name = names[code - 1];
        const cmp_name = try ownPrint(self.module, "air{}_error_name_is_{}", .{ instruction_index, code });
        try self.block.instructions.append(self.allocator, .{
            .result = cmp_name,
            .kind = .{ .icmp = .{
                .predicate = .eq,
                .operand_ty = .{ .int = 16 },
                .lhs = .{ .named = code_value_name },
                .rhs = .{ .int = @intCast(code) },
            } },
        });

        const ptr_name = try ownPrint(self.module, "air{}_error_name_ptr_{}", .{ instruction_index, code });
        try self.block.instructions.append(self.allocator, .{
            .result = ptr_name,
            .kind = .{ .select = .{
                .cond_ty = .{ .int = 1 },
                .cond = .{ .named = cmp_name },
                .ty = .ptr,
                .true_value = try errorNameStringPointer(self, name),
                .false_value = selected_ptr,
            } },
        });
        selected_ptr = .{ .named = ptr_name };

        const len_name = try ownPrint(self.module, "air{}_error_name_len_{}", .{ instruction_index, code });
        try self.block.instructions.append(self.allocator, .{
            .result = len_name,
            .kind = .{ .select = .{
                .cond_ty = .{ .int = 1 },
                .cond = .{ .named = cmp_name },
                .ty = .{ .int = 64 },
                .true_value = .{ .int = @intCast(name.len) },
                .false_value = selected_len,
            } },
        });
        selected_len = .{ .named = len_name };
    }
    return .{ .ptr = selected_ptr, .len = selected_len };
}

fn canonicalErrorNameCodeValue(self: anytype, name_value: []const u8) []const u8 {
    const instruction = findCurrentBlockInstruction(self, name_value) orelse return name_value;
    const cast = switch (instruction.kind) {
        .cast => |cast| cast,
        else => return name_value,
    };
    if (cast.op != .bitcast or !cast.from_ty.eql(.{ .int = 16 }) or !cast.to_ty.eql(.{ .int = 16 })) return name_value;
    const source_name = switch (cast.value) {
        .named => |source| source,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return name_value,
    };
    return canonicalErrorNameCodeValue(self, source_name);
}

const ErrorNameSelection = struct {
    cond: ir.Value,
    true_is_first: bool,
};

fn errorNameSelectionFromValue(self: anytype, name_value: []const u8) !?ErrorNameSelection {
    const instruction = findCurrentBlockInstruction(self, name_value) orelse return null;
    switch (instruction.kind) {
        .cast => |cast| {
            if (cast.op != .bitcast or !cast.from_ty.eql(.{ .int = 16 }) or !cast.to_ty.eql(.{ .int = 16 })) return null;
            const source_name = switch (cast.value) {
                .named => |source| source,
                .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
            };
            return try errorNameSelectionFromValue(self, source_name);
        },
        .select => |select| {
            if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 16 })) return null;
            const true_code = switch (select.true_value) {
                .int => |value| value,
                .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
            };
            const false_code = switch (select.false_value) {
                .int => |value| value,
                .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
            };
            if (true_code == 1 and false_code == 2) return .{ .cond = select.cond, .true_is_first = true };
            if (true_code == 2 and false_code == 1) return .{ .cond = select.cond, .true_is_first = false };
            return null;
        },
        else => return null,
    }
}

fn findCurrentBlockInstruction(self: anytype, result_name: []const u8) ?ir.Instruction {
    for (self.block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        const result = instruction.result orelse continue;
        if (std.mem.eql(u8, result, result_name)) return instruction;
    }
    return null;
}

fn errorNameStringPointer(self: anytype, name: []const u8) !ir.Value {
    const symbol = try self.ensureStringLiteralGlobal(name, name.len);
    return .{ .named = try ownPrint(self.module, "@{s}", .{symbol}) };
}

fn errorUnionPointerOperandText(type_text: []const u8) bool {
    const child_text = air_types.pointerChildText(std.mem.trim(u8, type_text, " ")) orelse return false;
    return air_types.isErrorUnionTypeText(child_text);
}
