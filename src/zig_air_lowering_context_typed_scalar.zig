const std = @import("std");

const air_export = @import("zig_air_export.zig");
const air_capabilities = @import("zig_air_capabilities.zig");
const air_model = @import("zig_air_model.zig");
const air_semantics = @import("zig_air_semantics.zig");
const air_types = @import("zig_air_types.zig");
const air_text = @import("zig_air_text.zig");
const ir = @import("ir.zig");

const parseZigType = air_types.parseZigType;
const isOpaqueNominalTypeSurface = air_types.isOpaqueNominalTypeSurface;
const ownPrint = air_model.ownPrint;
const binaryOp = air_semantics.binaryOp;
const isFpType = air_semantics.isFpType;
const intPredicate = air_semantics.intPredicate;
const fpPredicate = air_semantics.fpPredicate;
const castOp = air_semantics.castOp;
const isShiftOpcode = air_capabilities.isShiftOpcode;

pub fn lowerTypedScalarSemanticInstruction(self: anytype, instruction: air_export.TypedInstruction) !bool {
    switch (air_capabilities.scalarSemanticOpForOpcode(instruction.opcode)) {
        .arg => try self.lowerTypedArg(instruction),
        .add_with_overflow, .sub_with_overflow, .mul_with_overflow, .shl_with_overflow => try self.lowerTypedArithmeticWithOverflow(instruction),
        .binary => try self.lowerTypedBinary(instruction),
        .compare => try self.lowerTypedCompare(instruction),
        .cast => try self.lowerTypedCast(instruction),
        .byte_swap => try self.lowerTypedByteSwap(instruction),
        .max => try self.lowerTypedMax(instruction),
        .min => try self.lowerTypedMin(instruction),
        .abs => try self.lowerTypedAbs(instruction),
        .neg => try self.lowerTypedNeg(instruction),
        .shl_sat => try self.lowerTypedShlSat(instruction),
        .clz => try self.lowerTypedClz(instruction),
        .ctz => try self.lowerTypedCtz(instruction),
        .popcount => try self.lowerTypedPopcount(instruction),
        .bit_reverse => try self.lowerTypedBitReverse(instruction),
        .none => return false,
    }
    return true;
}

pub fn lowerTypedArg(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (instruction.operands.len != 0) return air_model.LowerError.UnsupportedAir;
    const param_index = self.next_arg_index;
    self.next_arg_index += 1;
    if (param_index >= self.function_type.params.len) return air_model.LowerError.UnsupportedAir;
    const parsed_type = parseZigType(instruction.result_type) orelse
        (self.opaqueBitcastNominalArgType(instruction.index, instruction.result_type, param_index) orelse
            (self.unusedOpaqueNominalArgType(instruction.index, instruction.result_type, param_index) orelse
                (self.unionTagOnlyOpaqueNominalArgType(instruction.index, instruction.result_type, param_index) orelse
                    return air_model.LowerError.UnsupportedAir)));
    if (!parsed_type.ir_type.eql(self.function_type.params[param_index].ir_type)) return air_model.LowerError.UnsupportedAir;
    self.values[instruction.index] = .{
        .ty = parsed_type,
        .value = .{ .named = self.blockParamName(param_index) },
    };
}

pub fn lowerTypedBinary(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (instruction.operands.len != 2) return air_model.LowerError.UnsupportedAir;
    const lhs = try self.resolveTypedOperand(instruction, 0);
    var rhs = try self.resolveTypedOperand(instruction, 1);
    if (!lhs.ty.ir_type.eql(rhs.ty.ir_type)) {
        if (!isShiftOpcode(instruction.opcode)) return air_model.LowerError.UnsupportedAir;
        rhs = try self.extendShiftCount(instruction.index, lhs.ty, rhs);
    }
    const op = binaryOp(instruction.opcode, lhs.ty) orelse return air_model.LowerError.UnsupportedAir;
    const result_name = try self.resultName(instruction.index);
    try self.block.instructions.append(self.allocator, .{
        .result = result_name,
        .kind = .{ .binary = .{
            .op = op,
            .ty = lhs.ty.ir_type,
            .lhs = lhs.value,
            .rhs = rhs.value,
        } },
    });
    self.values[instruction.index] = .{
        .ty = lhs.ty,
        .value = .{ .named = result_name },
    };
}

pub fn lowerTypedArithmeticWithOverflow(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (instruction.operands.len != 2) return air_model.LowerError.UnsupportedAir;
    const lhs = try self.resolveTypedOperand(instruction, 0);
    var rhs = try self.resolveTypedOperand(instruction, 1);
    const is_shl = std.mem.eql(u8, instruction.opcode, "shl_with_overflow");
    if (!lhs.ty.ir_type.eql(.{ .int = 32 })) return air_model.LowerError.UnsupportedAir;
    if (!rhs.ty.ir_type.eql(.{ .int = 32 })) {
        if (!is_shl) return air_model.LowerError.UnsupportedAir;
        rhs = switch (rhs.value) {
            .int => .{
                .ty = .{ .ir_type = lhs.ty.ir_type },
                .value = rhs.value,
            },
            else => try self.extendShiftCount(instruction.index, lhs.ty, rhs),
        };
    }
    if (!lhs.ty.ir_type.eql(rhs.ty.ir_type)) return air_model.LowerError.UnsupportedAir;
    const result_type = parseZigType(instruction.result_type) orelse return air_model.LowerError.UnsupportedAir;
    if (!result_type.ir_type.eql(.{ .aggregate = "{ i32, i1 }" })) return air_model.LowerError.UnsupportedAir;

    const result_name = try self.resultName(instruction.index);
    const callee = if (std.mem.eql(u8, instruction.opcode, "add_with_overflow"))
        if (lhs.ty.signed) "llvm.sadd.with.overflow.i32" else "llvm.uadd.with.overflow.i32"
    else if (std.mem.eql(u8, instruction.opcode, "sub_with_overflow"))
        if (lhs.ty.signed) "llvm.ssub.with.overflow.i32" else "llvm.usub.with.overflow.i32"
    else if (std.mem.eql(u8, instruction.opcode, "mul_with_overflow"))
        if (lhs.ty.signed) "llvm.smul.with.overflow.i32" else "llvm.umul.with.overflow.i32"
    else if (std.mem.eql(u8, instruction.opcode, "shl_with_overflow"))
        if (!lhs.ty.signed) "llvm.ushl.with.overflow.i32" else return air_model.LowerError.UnsupportedAir
    else
        return air_model.LowerError.UnsupportedAir;
    var call: ir.CallInst = .{
        .ret_ty = result_type.ir_type,
        .callee = callee,
        .args = .empty,
    };
    errdefer call.deinit(self.allocator);
    try call.args.append(self.allocator, .{ .ty = lhs.ty.ir_type, .value = lhs.value });
    try call.args.append(self.allocator, .{ .ty = rhs.ty.ir_type, .value = rhs.value });
    try self.block.instructions.append(self.allocator, .{
        .result = result_name,
        .kind = .{ .call = call },
    });
    self.values[instruction.index] = .{
        .ty = result_type,
        .value = .{ .named = result_name },
    };
}

pub fn lowerTypedCompare(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (instruction.operands.len != 2) return air_model.LowerError.UnsupportedAir;
    const lhs = try self.resolveTypedOperand(instruction, 0);
    const rhs = try self.resolveTypedOperand(instruction, 1);
    if (!lhs.ty.ir_type.eql(rhs.ty.ir_type)) return air_model.LowerError.UnsupportedAir;
    const result_name = try self.resultName(instruction.index);
    if (isFpType(lhs.ty.ir_type)) {
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .fcmp = .{
                .predicate = fpPredicate(instruction.opcode) orelse return air_model.LowerError.UnsupportedAir,
                .operand_ty = lhs.ty.ir_type,
                .lhs = lhs.value,
                .rhs = rhs.value,
            } },
        });
    } else {
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .icmp = .{
                .predicate = intPredicate(instruction.opcode, lhs.ty.signed) orelse return air_model.LowerError.UnsupportedAir,
                .operand_ty = lhs.ty.ir_type,
                .lhs = lhs.value,
                .rhs = rhs.value,
            } },
        });
    }
    self.values[instruction.index] = .{
        .ty = .{ .ir_type = .{ .int = 1 } },
        .value = .{ .named = result_name },
    };
}

pub fn lowerTypedCast(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (std.mem.eql(u8, instruction.opcode, "ptr_cast") and instruction.operands.len == 0) {
        try lowerTypedPtrCastOpaque(self, instruction);
        return;
    }
    if (instruction.operands.len != 1) return air_model.LowerError.UnsupportedAir;
    const source = try self.resolveTypedOperand(instruction, 0);
    const target_type = parseZigType(instruction.result_type) orelse
        (opaqueCastResultType(instruction, source.ty) orelse return air_model.LowerError.UnsupportedAir);
    if (source.ty.ir_type.eql(target_type.ir_type)) {
        if (source.ty.ir_type == .ptr and instruction.index < self.synthetic_vector_slots.len) {
            if (air_model.typedInstOperandIndex(instruction.operands[0])) |source_index| {
                if (source_index < self.synthetic_vector_slots.len) {
                    self.synthetic_vector_slots[instruction.index] = self.synthetic_vector_slots[source_index];
                }
                if (source_index < self.synthetic_vector_element_ptrs.len) {
                    self.synthetic_vector_element_ptrs[instruction.index] = self.synthetic_vector_element_ptrs[source_index];
                }
            }
        }
        if (source.ty.ir_type == .ptr and instruction.index < self.synthetic_union_tag_slots.len) {
            if (air_model.typedInstOperandIndex(instruction.operands[0])) |source_index| {
                if (source_index < self.synthetic_union_tag_slots.len) {
                    self.synthetic_union_tag_slots[instruction.index] = self.synthetic_union_tag_slots[source_index];
                }
            }
        }
        self.values[instruction.index] = .{
            .ty = target_type,
            .value = source.value,
        };
        return;
    }
    if (air_capabilities.isBitcastOpcode(instruction.opcode) and
        source.ty.ir_type == .ptr and target_type.ir_type == .ptr)
    {
        if (instruction.index < self.synthetic_vector_slots.len) {
            if (air_model.typedInstOperandIndex(instruction.operands[0])) |source_index| {
                if (source_index < self.synthetic_vector_slots.len) {
                    self.synthetic_vector_slots[instruction.index] = self.synthetic_vector_slots[source_index];
                }
                if (source_index < self.synthetic_vector_element_ptrs.len) {
                    self.synthetic_vector_element_ptrs[instruction.index] = self.synthetic_vector_element_ptrs[source_index];
                }
            }
        }
        if (instruction.index < self.synthetic_union_tag_slots.len) {
            if (air_model.typedInstOperandIndex(instruction.operands[0])) |source_index| {
                if (source_index < self.synthetic_union_tag_slots.len) {
                    self.synthetic_union_tag_slots[instruction.index] = self.synthetic_union_tag_slots[source_index];
                }
            }
        }
        self.values[instruction.index] = .{
            .ty = target_type,
            .value = source.value,
        };
        return;
    }
    const op = castOp(instruction.opcode, source.ty, target_type) orelse return air_model.LowerError.UnsupportedAir;
    const result_name = try self.resultName(instruction.index);
    try self.block.instructions.append(self.allocator, .{
        .result = result_name,
        .kind = .{ .cast = .{
            .op = op,
            .from_ty = source.ty.ir_type,
            .value = source.value,
            .to_ty = target_type.ir_type,
        } },
    });
    self.values[instruction.index] = .{
        .ty = target_type,
        .value = .{ .named = result_name },
    };
}

pub fn lowerTypedPtrCastOpaque(self: anytype, instruction: air_export.TypedInstruction) !void {
    const raw = rawInstructionByIndex(self.air_function, instruction.index) orelse return air_model.LowerError.UnsupportedAir;
    if (!std.mem.eql(u8, raw.opcode, "ptr_cast")) return air_model.LowerError.UnsupportedAir;

    var fields = air_text.splitTopLevel(raw.payload, ',');
    const target_type_text = std.mem.trim(u8, fields.next() orelse return air_model.LowerError.UnsupportedAir, " ");
    const source_text = std.mem.trim(u8, fields.next() orelse return air_model.LowerError.UnsupportedAir, " ");
    if (fields.next() != null) return air_model.LowerError.UnsupportedAir;

    const source_index = air_text.instructionRef(source_text) orelse return air_model.LowerError.UnsupportedAir;
    if (source_index >= self.values.len) return air_model.LowerError.UnsupportedAir;
    const source = self.values[source_index] orelse return air_model.LowerError.UnsupportedAir;

    const target_type = parseZigType(target_type_text) orelse return air_model.LowerError.UnsupportedAir;
    if (source.ty.ir_type != .ptr or target_type.ir_type != .ptr) return air_model.LowerError.UnsupportedAir;

    if (instruction.index < self.synthetic_vector_slots.len and source_index < self.synthetic_vector_slots.len) {
        self.synthetic_vector_slots[instruction.index] = self.synthetic_vector_slots[source_index];
    }
    if (instruction.index < self.synthetic_vector_element_ptrs.len and source_index < self.synthetic_vector_element_ptrs.len) {
        self.synthetic_vector_element_ptrs[instruction.index] = self.synthetic_vector_element_ptrs[source_index];
    }
    if (instruction.index < self.synthetic_union_tag_slots.len and source_index < self.synthetic_union_tag_slots.len) {
        self.synthetic_union_tag_slots[instruction.index] = self.synthetic_union_tag_slots[source_index];
    }
    if (instruction.index < self.synthetic_pointer_payloads.len and source_index < self.synthetic_pointer_payloads.len) {
        self.synthetic_pointer_payloads[instruction.index] = self.synthetic_pointer_payloads[source_index];
    }
    const source_value = if (source_index < self.synthetic_pointer_payloads.len and self.synthetic_pointer_payloads[source_index] != null)
        self.synthetic_pointer_payloads[source_index].?.value
    else
        source.value;
    self.values[instruction.index] = .{
        .ty = target_type,
        .value = source_value,
    };
}

fn rawInstructionByIndex(function: air_export.Function, index: u32) ?air_export.Instruction {
    for (function.instructions) |instruction| {
        if (instruction.index == index) return instruction;
    }
    return null;
}

fn opaqueCastResultType(instruction: air_export.TypedInstruction, source_type: air_model.ZigType) ?air_model.ZigType {
    if (std.mem.eql(u8, instruction.opcode, "ptr_cast")) {
        return switch (source_type.ir_type) {
            .ptr => source_type,
            else => null,
        };
    }
    if (!air_capabilities.isBitcastOpcode(instruction.opcode) and
        !std.mem.eql(u8, instruction.opcode, "intcast") and
        !std.mem.eql(u8, instruction.opcode, "intcast_safe") and
        !std.mem.eql(u8, instruction.opcode, "int_cast") and
        !std.mem.eql(u8, instruction.opcode, "int_cast_safe")) return null;
    if (!isOpaqueNominalTypeSurface(instruction.result_type)) return null;
    return switch (source_type.ir_type) {
        .int, .ptr, .float, .double => source_type,
        .void, .half, .x86_fp80, .fp128, .metadata, .aggregate, .vector => null,
    };
}

pub fn lowerTypedByteSwap(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (instruction.operands.len != 1) return air_model.LowerError.UnsupportedAir;
    const source = try self.resolveTypedOperand(instruction, 0);
    const result_type = parseZigType(instruction.result_type) orelse return air_model.LowerError.UnsupportedAir;
    const bits = switch (source.ty.ir_type) {
        .int => |width| width,
        else => return air_model.LowerError.UnsupportedAir,
    };
    if (!result_type.ir_type.eql(source.ty.ir_type)) return air_model.LowerError.UnsupportedAir;
    switch (bits) {
        16, 32, 64 => {},
        else => return air_model.LowerError.UnsupportedAir,
    }

    const result_name = try self.resultName(instruction.index);
    var call: ir.CallInst = .{
        .ret_ty = result_type.ir_type,
        .callee = switch (bits) {
            16 => "llvm.bswap.i16",
            32 => "llvm.bswap.i32",
            64 => "llvm.bswap.i64",
            else => unreachable,
        },
        .args = .empty,
    };
    errdefer call.deinit(self.allocator);
    try call.args.append(self.allocator, .{ .ty = source.ty.ir_type, .value = source.value });
    try self.block.instructions.append(self.allocator, .{
        .result = result_name,
        .kind = .{ .call = call },
    });
    self.values[instruction.index] = .{
        .ty = result_type,
        .value = .{ .named = result_name },
    };
}

pub fn lowerTypedMax(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (instruction.operands.len != 2) return air_model.LowerError.UnsupportedAir;
    const lhs = try self.resolveTypedOperand(instruction, 0);
    const rhs = try self.resolveTypedOperand(instruction, 1);
    const result_type = parseZigType(instruction.result_type) orelse return air_model.LowerError.UnsupportedAir;
    if (!lhs.ty.ir_type.eql(rhs.ty.ir_type) or !result_type.ir_type.eql(lhs.ty.ir_type)) return air_model.LowerError.UnsupportedAir;
    switch (lhs.ty.ir_type) {
        .int => |bits| if (bits != 8 and bits != 16 and bits != 32 and bits != 64 and bits != 128) return air_model.LowerError.UnsupportedAir,
        else => return air_model.LowerError.UnsupportedAir,
    }

    var eff_lhs = lhs;
    var eff_rhs = rhs;
    if (eff_lhs.value == .int and eff_rhs.value != .int) {
        eff_lhs = rhs;
        eff_rhs = lhs;
    }

    const cmp_name = try ownPrint(self.module, "air{}_max_cmp", .{instruction.index});
    const result_name = try self.resultName(instruction.index);
    try self.block.instructions.append(self.allocator, .{
        .result = cmp_name,
        .kind = .{ .icmp = .{
            .predicate = if (eff_lhs.ty.signed) .slt else .ult,
            .operand_ty = eff_lhs.ty.ir_type,
            .lhs = eff_lhs.value,
            .rhs = eff_rhs.value,
        } },
    });
    try self.block.instructions.append(self.allocator, .{
        .result = result_name,
        .kind = .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = cmp_name },
            .ty = eff_lhs.ty.ir_type,
            .true_value = eff_rhs.value,
            .false_value = eff_lhs.value,
        } },
    });
    self.values[instruction.index] = .{
        .ty = result_type,
        .value = .{ .named = result_name },
    };
}

pub fn lowerTypedMin(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (instruction.operands.len != 2) return air_model.LowerError.UnsupportedAir;
    const lhs = try self.resolveTypedOperand(instruction, 0);
    const rhs = try self.resolveTypedOperand(instruction, 1);
    const result_type = parseZigType(instruction.result_type) orelse return air_model.LowerError.UnsupportedAir;
    if (!lhs.ty.ir_type.eql(rhs.ty.ir_type) or !result_type.ir_type.eql(lhs.ty.ir_type)) return air_model.LowerError.UnsupportedAir;
    switch (lhs.ty.ir_type) {
        .int => |bits| if (bits != 8 and bits != 16 and bits != 32 and bits != 64 and bits != 128) return air_model.LowerError.UnsupportedAir,
        else => return air_model.LowerError.UnsupportedAir,
    }

    var eff_lhs = lhs;
    var eff_rhs = rhs;
    if (eff_lhs.value == .int and eff_rhs.value != .int) {
        eff_lhs = rhs;
        eff_rhs = lhs;
    }

    const cmp_name = try ownPrint(self.module, "air{}_min_cmp", .{instruction.index});
    const result_name = try self.resultName(instruction.index);
    try self.block.instructions.append(self.allocator, .{
        .result = cmp_name,
        .kind = .{ .icmp = .{
            .predicate = if (eff_lhs.ty.signed) .slt else .ult,
            .operand_ty = eff_lhs.ty.ir_type,
            .lhs = eff_lhs.value,
            .rhs = eff_rhs.value,
        } },
    });
    try self.block.instructions.append(self.allocator, .{
        .result = result_name,
        .kind = .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = cmp_name },
            .ty = eff_lhs.ty.ir_type,
            .true_value = eff_lhs.value,
            .false_value = eff_rhs.value,
        } },
    });
    self.values[instruction.index] = .{
        .ty = result_type,
        .value = .{ .named = result_name },
    };
}

pub fn lowerTypedAbs(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (instruction.operands.len != 1) return air_model.LowerError.UnsupportedAir;
    const source = try self.resolveTypedOperand(instruction, 0);
    const result_type = parseZigType(instruction.result_type) orelse return air_model.LowerError.UnsupportedAir;
    if (!source.ty.signed) return air_model.LowerError.UnsupportedAir;
    switch (source.ty.ir_type) {
        .int => |bits| if (bits != 32 and bits != 64) return air_model.LowerError.UnsupportedAir,
        else => return air_model.LowerError.UnsupportedAir,
    }
    if (result_type.signed or !result_type.ir_type.eql(source.ty.ir_type)) return air_model.LowerError.UnsupportedAir;

    const cmp_name = try ownPrint(self.module, "air{}_abs_cmp", .{instruction.index});
    const neg_name = try ownPrint(self.module, "air{}_abs_neg", .{instruction.index});
    const result_name = try self.resultName(instruction.index);
    try self.block.instructions.append(self.allocator, .{
        .result = cmp_name,
        .kind = .{ .icmp = .{
            .predicate = .slt,
            .operand_ty = source.ty.ir_type,
            .lhs = source.value,
            .rhs = .{ .int = 0 },
        } },
    });
    try self.block.instructions.append(self.allocator, .{
        .result = neg_name,
        .kind = .{ .binary = .{
            .op = .sub,
            .ty = source.ty.ir_type,
            .lhs = .{ .int = 0 },
            .rhs = source.value,
        } },
    });
    try self.block.instructions.append(self.allocator, .{
        .result = result_name,
        .kind = .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = cmp_name },
            .ty = source.ty.ir_type,
            .true_value = .{ .named = neg_name },
            .false_value = source.value,
        } },
    });
    self.values[instruction.index] = .{
        .ty = result_type,
        .value = .{ .named = result_name },
    };
}

pub fn lowerTypedNeg(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (instruction.operands.len != 1) return air_model.LowerError.UnsupportedAir;
    const source = try self.resolveTypedOperand(instruction, 0);
    const result_type = parseZigType(instruction.result_type) orelse return air_model.LowerError.UnsupportedAir;
    if (!result_type.ir_type.eql(source.ty.ir_type)) return air_model.LowerError.UnsupportedAir;
    if (!source.ty.ir_type.eql(.float) and !source.ty.ir_type.eql(.double)) return air_model.LowerError.UnsupportedAir;

    const result_name = try self.resultName(instruction.index);
    try self.block.instructions.append(self.allocator, .{
        .result = result_name,
        .kind = .{ .binary = .{
            .op = .fsub,
            .ty = source.ty.ir_type,
            .lhs = .{ .fp = "0.000000e+00" },
            .rhs = source.value,
        } },
    });
    self.values[instruction.index] = .{
        .ty = result_type,
        .value = .{ .named = result_name },
    };
}

pub fn lowerTypedShlSat(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (instruction.operands.len != 2) return air_model.LowerError.UnsupportedAir;
    const lhs = try self.resolveTypedOperand(instruction, 0);
    var rhs = try self.resolveTypedOperand(instruction, 1);
    const result_type = parseZigType(instruction.result_type) orelse return air_model.LowerError.UnsupportedAir;
    if (lhs.ty.signed or !lhs.ty.ir_type.eql(.{ .int = 32 }) or !result_type.ir_type.eql(lhs.ty.ir_type)) {
        return air_model.LowerError.UnsupportedAir;
    }
    if (!rhs.ty.ir_type.eql(lhs.ty.ir_type)) {
        rhs = switch (rhs.value) {
            .int => .{
                .ty = .{ .ir_type = lhs.ty.ir_type },
                .value = rhs.value,
            },
            else => try self.extendShiftCount(instruction.index, lhs.ty, rhs),
        };
    }
    if (!rhs.ty.ir_type.eql(lhs.ty.ir_type)) return air_model.LowerError.UnsupportedAir;

    const result_name = try self.resultName(instruction.index);
    var call: ir.CallInst = .{
        .ret_ty = result_type.ir_type,
        .callee = "llvm.ushl.sat.i32",
        .args = .empty,
    };
    errdefer call.deinit(self.allocator);
    try call.args.append(self.allocator, .{ .ty = lhs.ty.ir_type, .value = lhs.value });
    try call.args.append(self.allocator, .{ .ty = rhs.ty.ir_type, .value = rhs.value });
    try self.block.instructions.append(self.allocator, .{
        .result = result_name,
        .kind = .{ .call = call },
    });
    self.values[instruction.index] = .{
        .ty = result_type,
        .value = .{ .named = result_name },
    };
}

pub fn lowerTypedClz(self: anytype, instruction: air_export.TypedInstruction) !void {
    try self.lowerTypedZeroCount(instruction, "llvm.ctlz.i32", "clz");
}

pub fn lowerTypedCtz(self: anytype, instruction: air_export.TypedInstruction) !void {
    try self.lowerTypedZeroCount(instruction, "llvm.cttz.i32", "ctz");
}

pub fn lowerTypedPopcount(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (instruction.operands.len != 1) return air_model.LowerError.UnsupportedAir;
    const source = try self.resolveTypedOperand(instruction, 0);
    const source_bits = switch (source.ty.ir_type) {
        .int => |bits| bits,
        else => return air_model.LowerError.UnsupportedAir,
    };
    if (source_bits <= 32) {
        try self.lowerTypedBitCount(instruction, "llvm.ctpop.i32", "popcount", false);
    } else if (source_bits <= 64) {
        try self.lowerTypedBitCount(instruction, "llvm.ctpop.i64", "popcount", false);
    } else {
        return air_model.LowerError.UnsupportedAir;
    }
}

pub fn lowerTypedBitReverse(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (instruction.operands.len != 1) return air_model.LowerError.UnsupportedAir;
    const source = try self.resolveTypedOperand(instruction, 0);
    const result_type = parseZigType(instruction.result_type) orelse return air_model.LowerError.UnsupportedAir;
    const bit_width = switch (source.ty.ir_type) {
        .int => |bits| bits,
        else => return air_model.LowerError.UnsupportedAir,
    };
    if (!result_type.ir_type.eql(source.ty.ir_type)) {
        return air_model.LowerError.UnsupportedAir;
    }

    if (bit_width == 32) {
        const result_name = try self.resultName(instruction.index);
        var call: ir.CallInst = .{
            .ret_ty = result_type.ir_type,
            .callee = "llvm.bitreverse.i32",
            .args = .empty,
        };
        errdefer call.deinit(self.allocator);
        try call.args.append(self.allocator, .{ .ty = source.ty.ir_type, .value = source.value });
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .call = call },
        });
        self.values[instruction.index] = .{
            .ty = result_type,
            .value = .{ .named = result_name },
        };
        return;
    }

    if (bit_width == 64) {
        const result_name = try self.resultName(instruction.index);
        var call: ir.CallInst = .{
            .ret_ty = result_type.ir_type,
            .callee = "llvm.bitreverse.i64",
            .args = .empty,
        };
        errdefer call.deinit(self.allocator);
        try call.args.append(self.allocator, .{ .ty = source.ty.ir_type, .value = source.value });
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .call = call },
        });
        self.values[instruction.index] = .{
            .ty = result_type,
            .value = .{ .named = result_name },
        };
        return;
    }

    if (bit_width < 32) {
        const zext_name = try ownPrint(self.module, "air{}_bitrev_zext", .{instruction.index});
        try self.block.instructions.append(self.allocator, .{
            .result = zext_name,
            .kind = .{ .cast = .{
                .op = .zext,
                .from_ty = source.ty.ir_type,
                .to_ty = .{ .int = 32 },
                .value = source.value,
            } },
        });

        const rev_name = try ownPrint(self.module, "air{}_bitrev_i32", .{instruction.index});
        var call: ir.CallInst = .{
            .ret_ty = .{ .int = 32 },
            .callee = "llvm.bitreverse.i32",
            .args = .empty,
        };
        errdefer call.deinit(self.allocator);
        try call.args.append(self.allocator, .{ .ty = .{ .int = 32 }, .value = .{ .named = zext_name } });
        try self.block.instructions.append(self.allocator, .{
            .result = rev_name,
            .kind = .{ .call = call },
        });

        const shift_amt: i128 = @as(i128, 32 - bit_width);
        const lshr_name = try ownPrint(self.module, "air{}_bitrev_lshr", .{instruction.index});
        try self.block.instructions.append(self.allocator, .{
            .result = lshr_name,
            .kind = .{ .binary = .{
                .op = .lshr,
                .ty = .{ .int = 32 },
                .lhs = .{ .named = rev_name },
                .rhs = .{ .int = shift_amt },
            } },
        });

        const result_name = try self.resultName(instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .cast = .{
                .op = .trunc,
                .from_ty = .{ .int = 32 },
                .to_ty = result_type.ir_type,
                .value = .{ .named = lshr_name },
            } },
        });
        self.values[instruction.index] = .{
            .ty = result_type,
            .value = .{ .named = result_name },
        };
        return;
    }

    return air_model.LowerError.UnsupportedAir;
}

pub fn lowerTypedZeroCount(self: anytype, instruction: air_export.TypedInstruction, callee: []const u8, label: []const u8) !void {
    try self.lowerTypedBitCount(instruction, callee, label, true);
}

pub fn lowerTypedBitCount(self: anytype, instruction: air_export.TypedInstruction, callee: []const u8, label: []const u8, has_zero_is_poison_arg: bool) !void {
    if (instruction.operands.len != 1) return air_model.LowerError.UnsupportedAir;
    const source = try self.resolveTypedOperand(instruction, 0);
    const result_type = parseZigType(instruction.result_type) orelse return air_model.LowerError.UnsupportedAir;
    const result_bits = switch (result_type.ir_type) {
        .int => |bits| bits,
        else => return air_model.LowerError.UnsupportedAir,
    };
    const source_bits = switch (source.ty.ir_type) {
        .int => |bits| bits,
        else => return air_model.LowerError.UnsupportedAir,
    };
    const callee_bits: u16 = if (std.mem.endsWith(u8, callee, ".i64")) 64 else 32;
    if (source.ty.signed or result_type.signed or source_bits > callee_bits) {
        return air_model.LowerError.UnsupportedAir;
    }

    const callee_ty: ir.Type = .{ .int = callee_bits };
    const call_source_value = if (source_bits == callee_bits)
        source.value
    else value: {
        const zext_name = try ownPrint(self.module, "air{}_{s}_zext", .{ instruction.index, label });
        try self.block.instructions.append(self.allocator, .{
            .result = zext_name,
            .kind = .{ .cast = .{
                .op = .zext,
                .from_ty = source.ty.ir_type,
                .to_ty = callee_ty,
                .value = source.value,
            } },
        });
        break :value ir.Value{ .named = zext_name };
    };

    const call_result_name = if (result_bits == callee_bits)
        try self.resultName(instruction.index)
    else
        try ownPrint(self.module, "air{}_{s}_{s}", .{ instruction.index, label, if (callee_bits == 64) "i64" else "i32" });
    var call: ir.CallInst = .{
        .ret_ty = callee_ty,
        .callee = callee,
        .args = .empty,
    };
    errdefer call.deinit(self.allocator);
    try call.args.append(self.allocator, .{ .ty = callee_ty, .value = call_source_value });
    if (has_zero_is_poison_arg) {
        try call.args.append(self.allocator, .{ .ty = .{ .int = 1 }, .value = .{ .int = 0 } });
    }
    try self.block.instructions.append(self.allocator, .{
        .result = call_result_name,
        .kind = .{ .call = call },
    });

    const result_name = if (result_bits == callee_bits) call_result_name else name: {
        const adjusted_name = try self.resultName(instruction.index);
        const op: ir.CastOp = if (result_bits < callee_bits) .trunc else .zext;
        try self.block.instructions.append(self.allocator, .{
            .result = adjusted_name,
            .kind = .{ .cast = .{
                .op = op,
                .from_ty = callee_ty,
                .value = .{ .named = call_result_name },
                .to_ty = result_type.ir_type,
            } },
        });
        break :name adjusted_name;
    };
    self.values[instruction.index] = .{
        .ty = result_type,
        .value = .{ .named = result_name },
    };
}
