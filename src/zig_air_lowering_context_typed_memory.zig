const std = @import("std");
const air_export = @import("zig_air_export.zig");
const air_capabilities = @import("zig_air_capabilities.zig");
const air_model = @import("zig_air_model.zig");
const air_text = @import("zig_air_text.zig");
const air_types = @import("zig_air_types.zig");
const air_values = @import("zig_air_values.zig");

const parseZigType = air_types.parseZigType;
const pointerLoadResultType = air_types.pointerLoadResultType;
const ir = @import("ir.zig");
const type_layout = @import("zig_air_type_layout.zig");
const target = @import("target.zig");
const ownPrint = air_model.ownPrint;

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
    if (allocated_type == .vector) {
        self.values[instruction.index] = .{
            .ty = pointer_type,
            .value = .poison,
        };
        self.synthetic_vector_slots[instruction.index] = .{
            .ty = .{ .ir_type = allocated_type },
            .value = .undef,
        };
        return;
    }
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

fn atomicLoadOrdering(raw_payload: []const u8) ?[]const u8 {
    var fields = air_text.splitTopLevel(raw_payload, ',');
    _ = fields.next() orelse return null;
    const ordering = std.mem.trim(u8, fields.next() orelse return null, " ");
    if (fields.next() != null) return null;
    if (std.mem.eql(u8, ordering, "unordered")) return "unordered";
    if (std.mem.eql(u8, ordering, "monotonic")) return "monotonic";
    if (std.mem.eql(u8, ordering, "acquire")) return "acquire";
    if (std.mem.eql(u8, ordering, "seq_cst")) return "seq_cst";
    return null;
}

pub fn lowerTypedLoad(self: anytype, instruction: air_export.TypedInstruction) !void {
    const is_atomic = std.mem.eql(u8, instruction.opcode, "atomic_load");
    const raw_atomic = if (is_atomic)
        rawInstructionByIndex(self.air_function, instruction.index) orelse return air_model.LowerError.UnsupportedAir
    else
        null;
    const atomic_ordering: ?[]const u8 = if (raw_atomic) |raw|
        atomicLoadOrdering(raw.payload) orelse return air_model.LowerError.UnsupportedAir
    else
        null;

    if (instruction.operands.len == 1) {
        if (try self.lowerTypedLoadFromSyntheticPointerPayload(instruction)) return;
        if (try self.lowerTypedLoadFromSyntheticErrorUnionSlot(instruction)) return;
        if (try self.lowerTypedLoadFromSyntheticUnionTagSlot(instruction)) return;
        if (try self.lowerTypedLoadFromSyntheticVectorSlot(instruction)) return;
        if (try self.lowerTypedLoadFromSyntheticVectorElement(instruction)) return;
        if (try self.lowerTypedLoadFromSlicePtrPtr(instruction)) return;
        if (try self.lowerTypedLoadFromSliceLenPtr(instruction)) return;
        if (try self.lowerTypedLoadFromSyntheticBitfield(instruction)) return;
    }

    const pointer = if (instruction.operands.len == 1)
        try self.resolveTypedOperand(instruction, 0)
    else if (instruction.operands.len == 0 and raw_atomic != null) blk: {
        var fields = air_text.splitTopLevel(raw_atomic.?.payload, ',');
        const ptr_text = std.mem.trim(u8, fields.next() orelse return air_model.LowerError.UnsupportedAir, " ");
        const ptr_idx = air_text.instructionRef(ptr_text) orelse return air_model.LowerError.UnsupportedAir;
        if (ptr_idx >= self.values.len) return air_model.LowerError.UnsupportedAir;
        break :blk self.values[ptr_idx] orelse return air_model.LowerError.UnsupportedAir;
    } else return air_model.LowerError.UnsupportedAir;

    if (pointer.ty.ir_type != .ptr) return air_model.LowerError.UnsupportedAir;
    const result_type = try typedLoadResultType(instruction, pointer.ty);
    if (result_type.ir_type == .aggregate) {
        if (instruction.index < self.synthetic_aggregate_ptrs.len) {
            self.synthetic_aggregate_ptrs[instruction.index] = pointer.value;
        }
        self.values[instruction.index] = .{
            .ty = result_type,
            .value = pointer.value,
        };
        return;
    }
    const result_name = try self.resultName(instruction.index);
    try self.block.instructions.append(self.allocator, .{
        .result = result_name,
        .kind = .{ .load = .{
            .ty = result_type.ir_type,
            .ptr = pointer.value,
            .attrs = .{
                .is_volatile = pointer.ty.is_volatile_pointer,
                .atomic_ordering = atomic_ordering,
            },
        } },
    });
    self.values[instruction.index] = .{
        .ty = result_type,
        .value = .{ .named = result_name },
    };
}

pub fn lowerTypedLoadFromSyntheticVectorSlot(self: anytype, instruction: air_export.TypedInstruction) !bool {
    const pointer_index = air_model.typedInstOperandIndex(instruction.operands[0]) orelse return false;
    if (pointer_index >= self.synthetic_vector_slots.len) return air_model.LowerError.UnsupportedAir;
    const loaded = self.synthetic_vector_slots[pointer_index] orelse return false;
    const pointer = try self.resolveTypedOperand(instruction, 0);
    const result_type = try typedLoadResultType(instruction, pointer.ty);
    if (!result_type.ir_type.eql(loaded.ty.ir_type)) return air_model.LowerError.UnsupportedAir;
    self.values[instruction.index] = loaded;
    return true;
}

pub fn lowerTypedLoadFromSyntheticVectorElement(self: anytype, instruction: air_export.TypedInstruction) !bool {
    const pointer_index = air_model.typedInstOperandIndex(instruction.operands[0]) orelse return false;
    if (pointer_index >= self.synthetic_vector_element_ptrs.len) return air_model.LowerError.UnsupportedAir;
    const element_ptr = self.synthetic_vector_element_ptrs[pointer_index] orelse return false;
    if (element_ptr.slot_index >= self.synthetic_vector_slots.len) return air_model.LowerError.UnsupportedAir;
    const vector = self.synthetic_vector_slots[element_ptr.slot_index] orelse return air_model.LowerError.UnsupportedAir;
    const vector_ty = switch (vector.ty.ir_type) {
        .vector => |vector_ty| vector_ty,
        .void, .int, .half, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .aggregate => return air_model.LowerError.UnsupportedAir,
    };
    if (element_ptr.lane_index >= vector_ty.len) return air_model.LowerError.UnsupportedAir;
    const pointer = try self.resolveTypedOperand(instruction, 0);
    const result_type = try typedLoadResultType(instruction, pointer.ty);
    if (!result_type.ir_type.eql(vector_ty.elem_ty.toType())) return air_model.LowerError.UnsupportedAir;
    const result_name = try self.resultName(instruction.index);
    try self.block.instructions.append(self.allocator, .{
        .result = result_name,
        .kind = .{ .extractelement = .{
            .vector_ty = vector.ty.ir_type,
            .vector = vector.value,
            .index_ty = .{ .int = 64 },
            .index = .{ .int = element_ptr.lane_index },
        } },
    });
    self.values[instruction.index] = .{
        .ty = result_type,
        .value = .{ .named = result_name },
    };
    return true;
}

pub fn lowerTypedLoadFromSyntheticBitfield(self: anytype, instruction: air_export.TypedInstruction) !bool {
    const pointer_index = air_model.typedInstOperandIndex(instruction.operands[0]) orelse return false;
    if (pointer_index >= self.synthetic_bitfield_ptrs.len) return false;
    const bitfield = self.synthetic_bitfield_ptrs[pointer_index] orelse return false;
    const result_type = parseZigType(instruction.result_type) orelse return air_model.LowerError.UnsupportedAir;

    const host_bits: u16 = @intCast(bitfield.info.host_bytes * 8);
    const host_ty: ir.Type = .{ .int = host_bits };

    const host_load_name = try ownPrint(self.module, "air{}_bitfield_host", .{instruction.index});
    try self.block.instructions.append(self.allocator, .{
        .result = host_load_name,
        .kind = .{ .load = .{
            .ty = host_ty,
            .ptr = bitfield.base_ptr,
        } },
    });

    var current_val: ir.Value = .{ .named = host_load_name };
    const current_ty = host_ty;

    if (bitfield.info.bit_offset > 0) {
        const shifted_name = try ownPrint(self.module, "air{}_bitfield_shifted", .{instruction.index});
        try self.block.instructions.append(self.allocator, .{
            .result = shifted_name,
            .kind = .{ .binary = .{
                .op = .lshr,
                .ty = host_ty,
                .lhs = current_val,
                .rhs = .{ .int = bitfield.info.bit_offset },
            } },
        });
        current_val = .{ .named = shifted_name };
    }

    if (bitfield.info.field_bits < host_bits) {
        const mask = (@as(i128, 1) << @intCast(bitfield.info.field_bits)) - 1;
        const masked_name = try ownPrint(self.module, "air{}_bitfield_masked", .{instruction.index});
        try self.block.instructions.append(self.allocator, .{
            .result = masked_name,
            .kind = .{ .binary = .{
                .op = .@"and",
                .ty = host_ty,
                .lhs = current_val,
                .rhs = .{ .int = mask },
            } },
        });
        current_val = .{ .named = masked_name };
    }

    const result_bits = switch (result_type.ir_type) {
        .int => |b| b,
        else => return air_model.LowerError.UnsupportedAir,
    };

    const result_name = try self.resultName(instruction.index);
    if (result_bits < host_bits) {
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .cast = .{
                .op = .trunc,
                .from_ty = current_ty,
                .value = current_val,
                .to_ty = result_type.ir_type,
            } },
        });
    } else {
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .binary = .{
                .op = .@"or",
                .ty = host_ty,
                .lhs = current_val,
                .rhs = .{ .int = 0 },
            } },
        });
    }

    self.values[instruction.index] = .{
        .ty = result_type,
        .value = .{ .named = result_name },
    };
    return true;
}

fn typedLoadResultType(instruction: air_export.TypedInstruction, pointer_type: air_model.ZigType) air_model.LowerError!air_model.ZigType {
    return parseZigType(instruction.result_type) orelse blk: {
        const typed_child = if (instruction.operands.len != 0)
            pointerLoadResultType(instruction.operands[0].type_text)
        else
            null;
        if (typed_child) |child| break :blk child;
        const child = pointer_type.pointer_child orelse return air_model.LowerError.UnsupportedAir;
        break :blk air_model.ZigType{ .ir_type = child };
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
    if (std.mem.eql(u8, instruction.opcode, "atomic_store_monotonic") or
        std.mem.eql(u8, instruction.opcode, "atomic_store_unordered"))
    {
        try lowerTypedAtomicStore(self, instruction);
        return;
    }
    if (instruction.operands.len != 2) return air_model.LowerError.UnsupportedAir;
    const pointer = try self.resolveTypedOperand(instruction, 0);
    if (pointer.ty.ir_type != .ptr) return air_model.LowerError.UnsupportedAir;
    if (try self.lowerTypedStoreToSyntheticVectorElement(instruction)) return;
    if (try self.lowerTypedStoreToSyntheticUnionField(instruction)) return;
    if (try self.lowerTypedStoreToSyntheticBitfield(instruction)) return;
    const value = try self.resolveTypedOperand(instruction, 1);
    if (try self.lowerTypedStoreToSyntheticErrorUnionSlot(instruction, value)) return;
    if (try self.lowerTypedStoreToSyntheticVectorSlot(instruction, value)) return;
    if (air_model.typedInstOperandIndex(instruction.operands[0])) |idx| {
        if (idx < self.synthetic_pointer_payloads.len) {
            self.synthetic_pointer_payloads[idx] = value;
        }
    }
    if (value.ty.ir_type == .aggregate) {
        if (air_model.typedInstOperandIndex(instruction.operands[1])) |val_idx| {
            if (val_idx < self.synthetic_aggregate_ptrs.len) {
                if (self.synthetic_aggregate_ptrs[val_idx]) |ptr_val| {
                    try self.lowerTypedAggregateCopy(instruction.index, pointer.value, ptr_val, value.ty.ir_type);
                    return;
                }
            }
        }
    }
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

pub fn lowerTypedAggregateCopy(
    self: anytype,
    instruction_index: u32,
    dest_ptr: ir.Value,
    src_ptr: ir.Value,
    aggregate_ty: ir.Type,
) !void {
    const layout_text = self.module.target_datalayout orelse "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128";
    const dl = target.DataLayout.parse(layout_text) catch return air_model.LowerError.UnsupportedAir;
    const normalized = type_layout.normalizeAggregateTypeChecked(aggregate_ty) catch aggregate_ty;
    const size_bytes: u64 = blk: {
        if (dl.typeStoreSizeBytes(normalized)) |sz| break :blk sz else |_| {}
        if (type_layout.aggregateLayoutPlan(dl, aggregate_ty)) |plan| break :blk plan.size_bytes else |_| {}
        return air_model.LowerError.UnsupportedAir;
    };
    if (size_bytes == 0) return;

    var offset: u64 = 0;
    while (offset < size_bytes) {
        const remaining = size_bytes - offset;
        const chunk_bytes: u64 = if (remaining >= 8)
            8
        else if (remaining >= 4)
            4
        else if (remaining >= 2)
            2
        else
            1;
        const chunk_ty: ir.Type = switch (chunk_bytes) {
            8 => .{ .int = 64 },
            4 => .{ .int = 32 },
            2 => .{ .int = 16 },
            1 => .{ .int = 8 },
            else => unreachable,
        };

        const src_addr: ir.Value = if (offset == 0)
            src_ptr
        else blk: {
            const gep_name = try ownPrint(self.module, "air{}_copy_src_{}", .{ instruction_index, offset });
            var gep: ir.GepInst = .{
                .source_ty = .{ .int = 8 },
                .ptr = src_ptr,
                .indices = .empty,
            };
            errdefer gep.deinit(self.allocator);
            try gep.indices.append(self.allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = @intCast(offset) } });
            try self.block.instructions.append(self.allocator, .{
                .result = gep_name,
                .kind = .{ .gep = gep },
            });
            break :blk .{ .named = gep_name };
        };

        const dst_addr: ir.Value = if (offset == 0)
            dest_ptr
        else blk: {
            const gep_name = try ownPrint(self.module, "air{}_copy_dst_{}", .{ instruction_index, offset });
            var gep: ir.GepInst = .{
                .source_ty = .{ .int = 8 },
                .ptr = dest_ptr,
                .indices = .empty,
            };
            errdefer gep.deinit(self.allocator);
            try gep.indices.append(self.allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = @intCast(offset) } });
            try self.block.instructions.append(self.allocator, .{
                .result = gep_name,
                .kind = .{ .gep = gep },
            });
            break :blk .{ .named = gep_name };
        };

        const load_name = try ownPrint(self.module, "air{}_copy_chunk_{}", .{ instruction_index, offset });
        try self.block.instructions.append(self.allocator, .{
            .result = load_name,
            .kind = .{ .load = .{
                .ty = chunk_ty,
                .ptr = src_addr,
            } },
        });

        try self.block.instructions.append(self.allocator, .{
            .result = null,
            .kind = .{ .store = .{
                .ty = chunk_ty,
                .value = .{ .named = load_name },
                .ptr = dst_addr,
            } },
        });

        offset += chunk_bytes;
    }
}

pub const lowerTypedAtomicStoreMonotonic = lowerTypedAtomicStore;

pub fn lowerTypedAtomicStore(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (instruction.operands.len != 0) return air_model.LowerError.UnsupportedAir;
    const raw = rawInstructionByIndex(self.air_function, instruction.index) orelse return air_model.LowerError.UnsupportedAir;
    if (!std.mem.eql(u8, raw.opcode, instruction.opcode)) return air_model.LowerError.UnsupportedAir;

    var fields = air_text.splitTopLevel(raw.payload, ',');
    const pointer_text = std.mem.trim(u8, fields.next() orelse return air_model.LowerError.UnsupportedAir, " ");
    const value_text = std.mem.trim(u8, fields.next() orelse return air_model.LowerError.UnsupportedAir, " ");
    const ordering = std.mem.trim(u8, fields.next() orelse return air_model.LowerError.UnsupportedAir, " ");
    if (fields.next() != null) return air_model.LowerError.UnsupportedAir;
    if (!std.mem.eql(u8, ordering, "monotonic") and !std.mem.eql(u8, ordering, "unordered")) return air_model.LowerError.UnsupportedAir;

    const pointer_index = air_text.instructionRef(pointer_text) orelse return air_model.LowerError.UnsupportedAir;
    if (pointer_index >= self.values.len) return air_model.LowerError.UnsupportedAir;
    const pointer = self.values[pointer_index] orelse return air_model.LowerError.UnsupportedAir;
    if (pointer.ty.ir_type != .ptr) return air_model.LowerError.UnsupportedAir;

    const value = air_values.parseConstant(value_text) orelse return air_model.LowerError.UnsupportedAir;
    const child_ty = pointer.ty.pointer_child orelse return air_model.LowerError.UnsupportedAir;
    if (!child_ty.eql(value.ty.ir_type)) return air_model.LowerError.UnsupportedAir;

    const atomic_ordering: []const u8 = if (std.mem.eql(u8, ordering, "monotonic")) "monotonic" else "unordered";
    try self.block.instructions.append(self.allocator, .{
        .result = null,
        .kind = .{ .store = .{
            .ty = value.ty.ir_type,
            .value = value.value,
            .ptr = pointer.value,
            .attrs = .{
                .is_volatile = pointer.ty.is_volatile_pointer,
                .atomic_ordering = atomic_ordering,
            },
        } },
    });
}

fn rawInstructionByIndex(function: air_export.Function, index: u32) ?air_export.Instruction {
    for (function.instructions) |instruction| {
        if (instruction.index == index) return instruction;
    }
    return null;
}

pub fn lowerTypedStoreToSyntheticVectorSlot(
    self: anytype,
    instruction: air_export.TypedInstruction,
    value: anytype,
) !bool {
    const pointer_index = air_model.typedInstOperandIndex(instruction.operands[0]) orelse return false;
    if (pointer_index >= self.synthetic_vector_slots.len) return air_model.LowerError.UnsupportedAir;
    const slot = self.synthetic_vector_slots[pointer_index] orelse return false;
    if (!value.ty.ir_type.eql(slot.ty.ir_type)) return air_model.LowerError.UnsupportedAir;
    self.synthetic_vector_slots[pointer_index] = value;
    return true;
}

pub fn lowerTypedStoreToSyntheticVectorElement(
    self: anytype,
    instruction: air_export.TypedInstruction,
) !bool {
    const pointer_index = air_model.typedInstOperandIndex(instruction.operands[0]) orelse return false;
    if (pointer_index >= self.synthetic_vector_element_ptrs.len) return air_model.LowerError.UnsupportedAir;
    const element_ptr = self.synthetic_vector_element_ptrs[pointer_index] orelse return false;
    if (element_ptr.slot_index >= self.synthetic_vector_slots.len) return air_model.LowerError.UnsupportedAir;
    const vector = self.synthetic_vector_slots[element_ptr.slot_index] orelse return air_model.LowerError.UnsupportedAir;
    const vector_ty = switch (vector.ty.ir_type) {
        .vector => |vector_ty| vector_ty,
        .void, .int, .half, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .aggregate => return air_model.LowerError.UnsupportedAir,
    };
    if (element_ptr.lane_index >= vector_ty.len) return air_model.LowerError.UnsupportedAir;
    const value = try self.resolveTypedOperand(instruction, 1);
    if (!value.ty.ir_type.eql(vector_ty.elem_ty.toType())) return air_model.LowerError.UnsupportedAir;
    const result_name = try self.resultName(instruction.index);
    try self.block.instructions.append(self.allocator, .{
        .result = result_name,
        .kind = .{ .insertelement = .{
            .vector_ty = vector.ty.ir_type,
            .vector = vector.value,
            .value_ty = value.ty.ir_type,
            .value = value.value,
            .index_ty = .{ .int = 64 },
            .index = .{ .int = element_ptr.lane_index },
        } },
    });
    self.synthetic_vector_slots[element_ptr.slot_index] = .{
        .ty = vector.ty,
        .value = .{ .named = result_name },
    };
    return true;
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

pub fn lowerTypedStoreToSyntheticBitfield(
    self: anytype,
    instruction: air_export.TypedInstruction,
) !bool {
    const pointer_index = air_model.typedInstOperandIndex(instruction.operands[0]) orelse return false;
    if (pointer_index >= self.synthetic_bitfield_ptrs.len) return false;
    const bitfield = self.synthetic_bitfield_ptrs[pointer_index] orelse return false;
    const value = try self.resolveTypedOperand(instruction, 1);

    const host_bits: u16 = @intCast(bitfield.info.host_bytes * 8);
    const host_ty: ir.Type = .{ .int = host_bits };

    const host_load_name = try ownPrint(self.module, "air{}_bitfield_store_host", .{instruction.index});
    try self.block.instructions.append(self.allocator, .{
        .result = host_load_name,
        .kind = .{ .load = .{
            .ty = host_ty,
            .ptr = bitfield.base_ptr,
        } },
    });

    const field_mask: u128 = if (bitfield.info.field_bits >= 128)
        std.math.maxInt(u128)
    else
        ((@as(u128, 1) << @intCast(bitfield.info.field_bits)) - 1) << @intCast(bitfield.info.bit_offset);
    const host_mask: u128 = if (host_bits >= 128) std.math.maxInt(u128) else (@as(u128, 1) << @intCast(host_bits)) - 1;
    const clear_mask: i128 = @intCast((~field_mask) & host_mask);

    const cleared_name = try ownPrint(self.module, "air{}_bitfield_store_cleared", .{instruction.index});
    try self.block.instructions.append(self.allocator, .{
        .result = cleared_name,
        .kind = .{ .binary = .{
            .op = .@"and",
            .ty = host_ty,
            .lhs = .{ .named = host_load_name },
            .rhs = .{ .int = clear_mask },
        } },
    });

    var insert_val: ir.Value = .{ .named = cleared_name };

    const val_bits: u16 = switch (value.ty.ir_type) {
        .int => |b| b,
        else => return air_model.LowerError.UnsupportedAir,
    };

    switch (value.value) {
        .int => |const_int| {
            const raw_uint: u128 = if (const_int >= 0) @intCast(const_int) else @bitCast(@as(i128, const_int));
            const field_val = raw_uint & ((@as(u128, 1) << @intCast(bitfield.info.field_bits)) - 1);
            if (field_val != 0) {
                const shifted_val: i128 = @intCast(field_val << @intCast(bitfield.info.bit_offset));
                const inserted_name = try ownPrint(self.module, "air{}_bitfield_store_inserted", .{instruction.index});
                try self.block.instructions.append(self.allocator, .{
                    .result = inserted_name,
                    .kind = .{ .binary = .{
                        .op = .@"or",
                        .ty = host_ty,
                        .lhs = insert_val,
                        .rhs = .{ .int = shifted_val },
                    } },
                });
                insert_val = .{ .named = inserted_name };
            }
        },
        else => {
            var prepared_val = value.value;
            if (val_bits < host_bits) {
                const ext_name = try ownPrint(self.module, "air{}_bitfield_store_zext", .{instruction.index});
                try self.block.instructions.append(self.allocator, .{
                    .result = ext_name,
                    .kind = .{ .cast = .{
                        .op = .zext,
                        .from_ty = value.ty.ir_type,
                        .value = prepared_val,
                        .to_ty = host_ty,
                    } },
                });
                prepared_val = .{ .named = ext_name };
            }

            if (bitfield.info.field_bits < host_bits) {
                const val_mask: i128 = @intCast((@as(u128, 1) << @intCast(bitfield.info.field_bits)) - 1);
                const masked_name = try ownPrint(self.module, "air{}_bitfield_store_val_masked", .{instruction.index});
                try self.block.instructions.append(self.allocator, .{
                    .result = masked_name,
                    .kind = .{ .binary = .{
                        .op = .@"and",
                        .ty = host_ty,
                        .lhs = prepared_val,
                        .rhs = .{ .int = val_mask },
                    } },
                });
                prepared_val = .{ .named = masked_name };
            }

            if (bitfield.info.bit_offset > 0) {
                const shifted_name = try ownPrint(self.module, "air{}_bitfield_store_val_shifted", .{instruction.index});
                try self.block.instructions.append(self.allocator, .{
                    .result = shifted_name,
                    .kind = .{ .binary = .{
                        .op = .shl,
                        .ty = host_ty,
                        .lhs = prepared_val,
                        .rhs = .{ .int = bitfield.info.bit_offset },
                    } },
                });
                prepared_val = .{ .named = shifted_name };
            }

            const inserted_name = try ownPrint(self.module, "air{}_bitfield_store_inserted", .{instruction.index});
            try self.block.instructions.append(self.allocator, .{
                .result = inserted_name,
                .kind = .{ .binary = .{
                    .op = .@"or",
                    .ty = host_ty,
                    .lhs = insert_val,
                    .rhs = prepared_val,
                } },
            });
            insert_val = .{ .named = inserted_name };
        },
    }

    try self.block.instructions.append(self.allocator, .{
        .result = null,
        .kind = .{ .store = .{
            .ty = host_ty,
            .value = insert_val,
            .ptr = bitfield.base_ptr,
        } },
    });
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
