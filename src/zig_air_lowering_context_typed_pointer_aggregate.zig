const std = @import("std");
const air_export = @import("zig_air_export.zig");
const air_capabilities = @import("zig_air_capabilities.zig");
const air_model = @import("zig_air_model.zig");
const air_types = @import("zig_air_types.zig");
const typed_v2_fallbacks = @import("zig_air_lowering_typed_v2_fallbacks.zig");
const ir = @import("ir.zig");

const parseZigType = air_types.parseZigType;
const aggregateFieldByteOffset = air_model.aggregateFieldByteOffset;
const genericTypedGepIndex = air_model.genericTypedGepIndex;
const isPlainFieldPointerChild = air_model.plainFieldPointerChild;
const isSupportedTypedGepElementType = air_model.supportedTypedGepElementType;
const ownPrint = air_model.ownPrint;
const ensureBase64LookupGlobal = typed_v2_fallbacks.ensureBase64LookupGlobal;

pub fn lowerTypedPointerAggregateSemanticInstruction(
    self: anytype,
    instruction: air_export.TypedInstruction,
) !bool {
    switch (air_capabilities.pointerAggregateSemanticOpForOpcode(instruction.opcode)) {
        .slice => try self.lowerTypedSlice(instruction),
        .array_to_slice => try self.lowerTypedArrayToSlice(instruction),
        .slice_ptr => try self.lowerTypedSlicePtr(instruction),
        .slice_ptr_ptr => try self.lowerTypedSlicePtrPtr(instruction),
        .slice_elem_ptr => try self.lowerTypedSliceElemPtr(instruction),
        .slice_len => try self.lowerTypedSliceLen(instruction),
        .slice_len_ptr => try self.lowerTypedSliceLenPtr(instruction),
        .ptr_gep => try self.lowerTypedPtrGep(instruction),
        .runtime_nav_ptr => try self.lowerTypedRuntimeNavPtr(instruction),
        .array_elem_val => try self.lowerTypedArrayElemVal(instruction),
        .field_ptr => try self.lowerTypedFieldPtr(instruction),
        .none => return false,
    }
    return true;
}

pub fn lowerTypedSlice(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (instruction.operands.len != 2) return air_model.LowerError.UnsupportedAir;
    const ptr = try self.resolveTypedOperand(instruction, 0);
    const len = try self.resolveTypedOperand(instruction, 1);
    if (ptr.ty.ir_type != .ptr or !len.ty.ir_type.eql(.{ .int = 64 })) return air_model.LowerError.UnsupportedAir;
    const result_type = parseZigType(instruction.result_type) orelse return air_model.LowerError.UnsupportedAir;
    if (!result_type.ir_type.eql(.{ .aggregate = "{ ptr, i64 }" })) return air_model.LowerError.UnsupportedAir;

    const ptr_name = try ownPrint(self.module, "air{}_slice_ptr", .{instruction.index});
    try self.block.instructions.append(self.allocator, .{
        .result = ptr_name,
        .kind = .{ .insertvalue = .{
            .aggregate_ty = result_type.ir_type,
            .aggregate = .undef,
            .value_ty = .ptr,
            .value = ptr.value,
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
            .value = len.value,
            .indices = "1",
        } },
    });
    self.values[instruction.index] = .{
        .ty = result_type,
        .value = .{ .named = result_name },
    };
}

pub fn lowerTypedArrayToSlice(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (instruction.operands.len != 1) return air_model.LowerError.UnsupportedAir;
    const ptr = try self.resolveTypedOperand(instruction, 0);
    if (ptr.ty.ir_type != .ptr) return air_model.LowerError.UnsupportedAir;
    const result_type = parseZigType(instruction.result_type) orelse return air_model.LowerError.UnsupportedAir;
    if (!result_type.ir_type.eql(.{ .aggregate = "{ ptr, i64 }" })) return air_model.LowerError.UnsupportedAir;

    const array_len = air_types.arrayLengthFromTypeText(instruction.operands[0].type_text) orelse return air_model.LowerError.UnsupportedAir;
    if (array_len > std.math.maxInt(i64)) return air_model.LowerError.UnsupportedAir;

    const ptr_name = try ownPrint(self.module, "air{}_array_to_slice_ptr", .{instruction.index});
    try self.block.instructions.append(self.allocator, .{
        .result = ptr_name,
        .kind = .{ .insertvalue = .{
            .aggregate_ty = result_type.ir_type,
            .aggregate = .undef,
            .value_ty = .ptr,
            .value = ptr.value,
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
            .value = .{ .int = @intCast(array_len) },
            .indices = "1",
        } },
    });
    self.values[instruction.index] = .{
        .ty = result_type,
        .value = .{ .named = result_name },
    };
}

pub fn lowerTypedSliceLenPtr(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (instruction.operands.len != 1) return air_model.LowerError.UnsupportedAir;
    const slice = try self.resolveTypedOperand(instruction, 0);
    if (!slice.ty.ir_type.eql(.{ .aggregate = "{ ptr, i64 }" }) and
        !(slice.ty.ir_type == .ptr and (slice.ty.pointer_child orelse return air_model.LowerError.UnsupportedAir).eql(.{ .aggregate = "{ ptr, i64 }" })))
    {
        return air_model.LowerError.UnsupportedAir;
    }
    const result_type = parseZigType(instruction.result_type) orelse return air_model.LowerError.UnsupportedAir;
    if (result_type.ir_type != .ptr) return air_model.LowerError.UnsupportedAir;
    if (result_type.pointer_child) |child| {
        if (!child.eql(.{ .int = 64 })) return air_model.LowerError.UnsupportedAir;
    }
    self.values[instruction.index] = .{
        .ty = result_type,
        .value = .poison,
    };
}

pub fn lowerTypedSlicePtr(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (instruction.operands.len != 1) return air_model.LowerError.UnsupportedAir;
    const slice = try self.resolveTypedOperand(instruction, 0);
    const result_type = parseZigType(instruction.result_type) orelse return air_model.LowerError.UnsupportedAir;
    if (result_type.ir_type != .ptr) return air_model.LowerError.UnsupportedAir;

    const slice_value = try self.materializeSliceAggregate(instruction.index, "slice_ptr_aggregate", slice);
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
}

pub fn lowerTypedSliceLen(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (instruction.operands.len != 1) return air_model.LowerError.UnsupportedAir;
    const slice = try self.resolveTypedOperand(instruction, 0);
    const result_type = parseZigType(instruction.result_type) orelse return air_model.LowerError.UnsupportedAir;
    if (!result_type.ir_type.eql(.{ .int = 64 })) return air_model.LowerError.UnsupportedAir;

    const slice_value = try self.materializeSliceAggregate(instruction.index, "slice_len_aggregate", slice);
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
}

pub fn lowerTypedSlicePtrPtr(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (instruction.operands.len != 1) return air_model.LowerError.UnsupportedAir;
    const slice = try self.resolveTypedOperand(instruction, 0);
    if (!slice.ty.ir_type.eql(.{ .aggregate = "{ ptr, i64 }" }) and
        !(slice.ty.ir_type == .ptr and (slice.ty.pointer_child orelse return air_model.LowerError.UnsupportedAir).eql(.{ .aggregate = "{ ptr, i64 }" })))
    {
        return air_model.LowerError.UnsupportedAir;
    }
    const result_type = parseZigType(instruction.result_type) orelse return air_model.LowerError.UnsupportedAir;
    if (result_type.ir_type != .ptr) return air_model.LowerError.UnsupportedAir;
    self.values[instruction.index] = .{
        .ty = result_type,
        .value = .poison,
    };
}

pub fn lowerTypedSliceElemPtr(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (instruction.operands.len != 2) return air_model.LowerError.UnsupportedAir;
    const slice = try self.resolveTypedOperand(instruction, 0);
    const index = try self.resolveTypedOperand(instruction, 1);
    if (!index.ty.ir_type.eql(.{ .int = 64 })) return air_model.LowerError.UnsupportedAir;
    const result_type = parseZigType(instruction.result_type) orelse return air_model.LowerError.UnsupportedAir;
    if (result_type.ir_type != .ptr) return air_model.LowerError.UnsupportedAir;
    const element_type = result_type.pointer_child orelse return air_model.LowerError.UnsupportedAir;
    if (!isSupportedTypedGepElementType(element_type)) return air_model.LowerError.UnsupportedAir;
    if (!genericTypedGepIndex(index.value)) return air_model.LowerError.UnsupportedAir;

    const slice_value = try self.materializeSliceAggregate(instruction.index, "slice_elem_aggregate", slice);
    const ptr_name = try ownPrint(self.module, "air{}_slice_elem_base", .{instruction.index});
    try self.block.instructions.append(self.allocator, .{
        .result = ptr_name,
        .kind = .{ .extractvalue = .{
            .aggregate_ty = .{ .aggregate = "{ ptr, i64 }" },
            .aggregate = slice_value,
            .indices = "0",
            .result_ty = .ptr,
        } },
    });

    if (typedGepIndexIsZero(index.value)) {
        self.values[instruction.index] = .{
            .ty = result_type,
            .value = .{ .named = ptr_name },
        };
        return;
    }

    const result_name = try self.resultName(instruction.index);
    var gep: ir.GepInst = .{
        .source_ty = element_type,
        .ptr = .{ .named = ptr_name },
        .indices = .empty,
    };
    errdefer gep.deinit(self.allocator);
    try gep.indices.append(self.allocator, .{ .ty = .{ .int = 64 }, .value = index.value });
    try self.block.instructions.append(self.allocator, .{
        .result = result_name,
        .kind = .{ .gep = gep },
    });
    self.values[instruction.index] = .{
        .ty = result_type,
        .value = .{ .named = result_name },
    };
}

pub fn materializeSliceAggregate(
    self: anytype,
    instruction_index: u32,
    suffix: []const u8,
    slice: anytype,
) !ir.Value {
    if (slice.ty.ir_type.eql(.{ .aggregate = "{ ptr, i64 }" })) return slice.value;
    if (slice.ty.ir_type == .ptr and (slice.ty.pointer_child orelse return air_model.LowerError.UnsupportedAir).eql(.{ .aggregate = "{ ptr, i64 }" })) {
        const aggregate_name = try ownPrint(self.module, "air{}_{s}", .{ instruction_index, suffix });
        try self.block.instructions.append(self.allocator, .{
            .result = aggregate_name,
            .kind = .{ .load = .{
                .ty = .{ .aggregate = "{ ptr, i64 }" },
                .ptr = slice.value,
            } },
        });
        return .{ .named = aggregate_name };
    }
    return air_model.LowerError.UnsupportedAir;
}

pub fn materializeSliceAggregateForLen(self: anytype, instruction_index: u32, slice: anytype) !ir.Value {
    return self.materializeSliceAggregate(instruction_index, "slice_len_aggregate", slice);
}

pub fn lowerTypedPtrGep(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (instruction.operands.len != 2) return air_model.LowerError.UnsupportedAir;
    if (try self.lowerTypedSyntheticVectorElemPtr(instruction)) return;
    const base = try self.resolveTypedOperand(instruction, 0);
    const index = try self.resolveTypedOperand(instruction, 1);
    const is_ptr_sub = std.mem.eql(u8, instruction.opcode, "ptr_sub");
    const result_type = parseZigType(instruction.result_type) orelse return air_model.LowerError.UnsupportedAir;
    if (base.ty.ir_type != .ptr or result_type.ir_type != .ptr) return air_model.LowerError.UnsupportedAir;
    if (!index.ty.ir_type.eql(.{ .int = 64 })) return air_model.LowerError.UnsupportedAir;
    const element_type = result_type.pointer_child orelse base.ty.pointer_child orelse return air_model.LowerError.UnsupportedAir;
    if (!isSupportedTypedGepElementType(element_type)) return air_model.LowerError.UnsupportedAir;
    const gep_index = if (is_ptr_sub) blk: {
        switch (index.value) {
            .int => |int| {
                if (int < 0) return air_model.LowerError.UnsupportedAir;
                break :blk ir.Value{ .int = -int };
            },
            .named => {
                const negative_index_name = try ownPrint(self.module, "air{}_ptr_sub_index", .{instruction.index});
                try self.block.instructions.append(self.allocator, .{
                    .result = negative_index_name,
                    .kind = .{ .binary = .{
                        .op = .sub,
                        .ty = .{ .int = 64 },
                        .lhs = .{ .int = 0 },
                        .rhs = index.value,
                    } },
                });
                break :blk ir.Value{ .named = negative_index_name };
            },
            .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return air_model.LowerError.UnsupportedAir,
        }
    } else index.value;
    if (is_ptr_sub) {
        switch (gep_index) {
            .int, .named => {},
            .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return air_model.LowerError.UnsupportedAir,
        }
    } else if (!genericTypedGepIndex(gep_index)) return air_model.LowerError.UnsupportedAir;

    if (typedGepIndexIsZero(gep_index)) {
        self.values[instruction.index] = .{
            .ty = result_type,
            .value = base.value,
        };
        return;
    }

    const result_name = try self.resultName(instruction.index);
    var gep: ir.GepInst = .{
        .source_ty = element_type,
        .ptr = base.value,
        .indices = .empty,
    };
    errdefer gep.deinit(self.allocator);
    try gep.indices.append(self.allocator, .{ .ty = .{ .int = 64 }, .value = gep_index });
    try self.block.instructions.append(self.allocator, .{
        .result = result_name,
        .kind = .{ .gep = gep },
    });
    self.values[instruction.index] = .{
        .ty = result_type,
        .value = .{ .named = result_name },
    };
}

pub fn lowerTypedSyntheticVectorElemPtr(self: anytype, instruction: air_export.TypedInstruction) !bool {
    if (!std.mem.eql(u8, instruction.opcode, "ptr_elem_ptr")) return false;
    const base_index = air_model.typedInstOperandIndex(instruction.operands[0]) orelse return false;
    if (base_index >= self.synthetic_vector_slots.len) return air_model.LowerError.UnsupportedAir;
    const slot = self.synthetic_vector_slots[base_index] orelse return false;
    const vector_ty = switch (slot.ty.ir_type) {
        .vector => |vector_ty| vector_ty,
        .void, .int, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .aggregate => return air_model.LowerError.UnsupportedAir,
    };
    const index = try self.resolveTypedOperand(instruction, 1);
    const lane = switch (index.value) {
        .int => |value| blk: {
            if (value < 0 or value > std.math.maxInt(u32)) return air_model.LowerError.UnsupportedAir;
            break :blk @as(u32, @intCast(value));
        },
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return air_model.LowerError.UnsupportedAir,
    };
    if (lane >= vector_ty.len) return air_model.LowerError.UnsupportedAir;
    const result_type = parseZigType(instruction.result_type) orelse return air_model.LowerError.UnsupportedAir;
    if (result_type.ir_type != .ptr) return air_model.LowerError.UnsupportedAir;
    if (result_type.pointer_child) |child| {
        if (!child.eql(vector_ty.elem_ty.toType())) return air_model.LowerError.UnsupportedAir;
    }
    self.values[instruction.index] = .{
        .ty = result_type,
        .value = .poison,
    };
    self.synthetic_vector_element_ptrs[instruction.index] = .{
        .slot_index = base_index,
        .lane_index = lane,
    };
    return true;
}

pub fn lowerTypedRuntimeNavPtr(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (instruction.operands.len != 0) return air_model.LowerError.UnsupportedAir;
    const pointer_type = parseZigType(instruction.result_type) orelse return air_model.LowerError.UnsupportedAir;
    if (pointer_type.ir_type != .ptr) return air_model.LowerError.UnsupportedAir;
    const nav_fqn = air_model.runtimeNavFqn(instruction) orelse return air_model.LowerError.UnsupportedAir;
    const symbol = try ownPrint(self.module, "@{s}", .{nav_fqn});
    self.values[instruction.index] = .{
        .ty = pointer_type,
        .value = .{ .named = symbol },
    };
}

pub fn lowerTypedArrayElemVal(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (instruction.operands.len != 2) return air_model.LowerError.UnsupportedAir;
    const table_text = air_model.arrayElemTableText(instruction) orelse return air_model.LowerError.UnsupportedAir;
    const index = try self.resolveTypedOperand(instruction, 1);
    if (!index.ty.ir_type.eql(.{ .int = 64 })) return air_model.LowerError.UnsupportedAir;
    if (!std.mem.eql(u8, table_text, "<[4]u8, \"\\x00\\x04\\x08\\x0c\".*>")) return air_model.LowerError.UnsupportedAir;
    try ensureBase64LookupGlobal(self.allocator, self.module);

    const gep_name = try ownPrint(self.module, "air{}_ptr", .{instruction.index});
    var gep: ir.GepInst = .{
        .source_ty = .{ .aggregate = "[4 x i8]" },
        .ptr = .{ .named = "@__anon_base64_table" },
        .indices = .empty,
    };
    errdefer gep.deinit(self.allocator);
    try gep.indices.append(self.allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = 0 } });
    try gep.indices.append(self.allocator, .{ .ty = .{ .int = 64 }, .value = index.value });
    try self.block.instructions.append(self.allocator, .{ .result = gep_name, .kind = .{ .gep = gep } });

    const result_type = parseZigType(instruction.result_type) orelse return air_model.LowerError.UnsupportedAir;
    if (!result_type.ir_type.eql(.{ .int = 8 })) return air_model.LowerError.UnsupportedAir;
    const result_name = try self.resultName(instruction.index);
    try self.block.instructions.append(self.allocator, .{
        .result = result_name,
        .kind = .{ .load = .{ .ty = .{ .int = 8 }, .ptr = .{ .named = gep_name } } },
    });
    self.values[instruction.index] = .{
        .ty = result_type,
        .value = .{ .named = result_name },
    };
}

pub fn lowerTypedFieldPtr(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (instruction.operands.len != 1) return air_model.LowerError.UnsupportedAir;
    const aggregate_ptr = try self.resolveTypedOperand(instruction, 0);
    if (aggregate_ptr.ty.ir_type != .ptr) return air_model.LowerError.UnsupportedAir;
    const result_type = parseZigType(instruction.result_type) orelse return air_model.LowerError.UnsupportedAir;
    if (result_type.ir_type != .ptr) return air_model.LowerError.UnsupportedAir;
    const field_child = result_type.pointer_child orelse return air_model.LowerError.UnsupportedAir;
    const field_index = air_model.fieldIndex(instruction) orelse return air_model.LowerError.UnsupportedAir;
    if (try self.lowerTypedSyntheticUnionFieldPtr(instruction, result_type, field_index)) return;
    const source_ty = aggregate_ptr.ty.pointer_child;
    if (source_ty) |known_source_ty| {
        if (aggregateFieldByteOffset(known_source_ty, field_child, field_index)) |offset| {
            if (offset == 0) {
                self.values[instruction.index] = .{
                    .ty = result_type,
                    .value = aggregate_ptr.value,
                };
                return;
            }
            const result_name = try self.resultName(instruction.index);
            var gep: ir.GepInst = .{
                .source_ty = .{ .int = 8 },
                .ptr = aggregate_ptr.value,
                .indices = .empty,
            };
            errdefer gep.deinit(self.allocator);
            try gep.indices.append(self.allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = offset } });
            try self.block.instructions.append(self.allocator, .{
                .result = result_name,
                .kind = .{ .gep = gep },
            });
            self.values[instruction.index] = .{
                .ty = result_type,
                .value = .{ .named = result_name },
            };
            return;
        }
    }

    if (field_index == 0 and isPlainFieldPointerChild(field_child)) {
        self.values[instruction.index] = .{
            .ty = result_type,
            .value = aggregate_ptr.value,
        };
        return;
    }

    if (!isPlainFieldPointerChild(field_child)) return air_model.LowerError.UnsupportedAir;
    const known_source_ty = source_ty orelse return air_model.LowerError.UnsupportedAir;

    const result_name = try self.resultName(instruction.index);
    var gep: ir.GepInst = .{
        .source_ty = known_source_ty,
        .ptr = aggregate_ptr.value,
        .indices = .empty,
    };
    errdefer gep.deinit(self.allocator);
    try gep.indices.append(self.allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = 0 } });
    try gep.indices.append(self.allocator, .{ .ty = .{ .int = 32 }, .value = .{ .int = field_index } });
    try self.block.instructions.append(self.allocator, .{
        .result = result_name,
        .kind = .{ .gep = gep },
    });
    self.values[instruction.index] = .{
        .ty = result_type,
        .value = .{ .named = result_name },
    };
}

pub fn lowerTypedSyntheticUnionFieldPtr(
    self: anytype,
    instruction: air_export.TypedInstruction,
    result_type: air_model.ZigType,
    field_index: i128,
) !bool {
    const field_index_u32 = std.math.cast(u32, field_index) orelse return air_model.LowerError.UnsupportedAir;
    const slot_index = air_model.typedInstOperandIndex(instruction.operands[0]) orelse return false;
    if (slot_index >= self.synthetic_union_tag_slots.len or instruction.index >= self.synthetic_union_field_ptrs.len) {
        return air_model.LowerError.UnsupportedAir;
    }
    if (self.synthetic_union_tag_slots[slot_index] == null and !typedUnionTagSlotAlloc(self, slot_index)) return false;
    self.synthetic_union_field_ptrs[instruction.index] = .{
        .slot_index = slot_index,
        .field_index = field_index_u32,
    };
    self.values[instruction.index] = .{
        .ty = result_type,
        .value = .undef,
    };
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

fn typedGepIndexIsZero(value: ir.Value) bool {
    return switch (value) {
        .int => |int| int == 0,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}
