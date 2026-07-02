const std = @import("std");

const air_export = @import("zig_air_export.zig");
const air_capabilities = @import("zig_air_capabilities.zig");
const air_model = @import("zig_air_model.zig");
const air_semantics = @import("zig_air_semantics.zig");
const air_types = @import("zig_air_types.zig");
const ir = @import("ir.zig");

const parseZigType = air_types.parseZigType;
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
    const parsed_type = parseZigType(instruction.result_type) orelse return air_model.LowerError.UnsupportedAir;
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
    if (instruction.operands.len != 1) return air_model.LowerError.UnsupportedAir;
    const source = try self.resolveTypedOperand(instruction, 0);
    const target_type = parseZigType(instruction.result_type) orelse return air_model.LowerError.UnsupportedAir;
    if (source.ty.ir_type.eql(target_type.ir_type)) {
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
    if (!lhs.ty.ir_type.eql(.{ .int = 32 })) return air_model.LowerError.UnsupportedAir;

    const cmp_name = try ownPrint(self.module, "air{}_max_cmp", .{instruction.index});
    const result_name = try self.resultName(instruction.index);
    try self.block.instructions.append(self.allocator, .{
        .result = cmp_name,
        .kind = .{ .icmp = .{
            .predicate = if (lhs.ty.signed) .slt else .ult,
            .operand_ty = lhs.ty.ir_type,
            .lhs = lhs.value,
            .rhs = rhs.value,
        } },
    });
    try self.block.instructions.append(self.allocator, .{
        .result = result_name,
        .kind = .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = cmp_name },
            .ty = lhs.ty.ir_type,
            .true_value = rhs.value,
            .false_value = lhs.value,
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
    if (!lhs.ty.ir_type.eql(.{ .int = 32 })) return air_model.LowerError.UnsupportedAir;

    const cmp_name = try ownPrint(self.module, "air{}_min_cmp", .{instruction.index});
    const result_name = try self.resultName(instruction.index);
    try self.block.instructions.append(self.allocator, .{
        .result = cmp_name,
        .kind = .{ .icmp = .{
            .predicate = if (lhs.ty.signed) .slt else .ult,
            .operand_ty = lhs.ty.ir_type,
            .lhs = lhs.value,
            .rhs = rhs.value,
        } },
    });
    try self.block.instructions.append(self.allocator, .{
        .result = result_name,
        .kind = .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = cmp_name },
            .ty = lhs.ty.ir_type,
            .true_value = lhs.value,
            .false_value = rhs.value,
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
    try self.lowerTypedBitCount(instruction, "llvm.ctpop.i32", "popcount", false);
}

pub fn lowerTypedBitReverse(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (instruction.operands.len != 1) return air_model.LowerError.UnsupportedAir;
    const source = try self.resolveTypedOperand(instruction, 0);
    const result_type = parseZigType(instruction.result_type) orelse return air_model.LowerError.UnsupportedAir;
    if (!source.ty.ir_type.eql(.{ .int = 32 }) or !result_type.ir_type.eql(source.ty.ir_type)) {
        return air_model.LowerError.UnsupportedAir;
    }

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
    if (!source.ty.ir_type.eql(.{ .int = 32 }) or result_type.signed or result_bits > 32) {
        return air_model.LowerError.UnsupportedAir;
    }

    const wide_result_name = if (result_type.ir_type.eql(.{ .int = 32 }))
        try self.resultName(instruction.index)
    else
        try ownPrint(self.module, "air{}_{s}_i32", .{ instruction.index, label });
    var call: ir.CallInst = .{
        .ret_ty = .{ .int = 32 },
        .callee = callee,
        .args = .empty,
    };
    errdefer call.deinit(self.allocator);
    try call.args.append(self.allocator, .{ .ty = source.ty.ir_type, .value = source.value });
    if (has_zero_is_poison_arg) {
        try call.args.append(self.allocator, .{ .ty = .{ .int = 1 }, .value = .{ .int = 0 } });
    }
    try self.block.instructions.append(self.allocator, .{
        .result = wide_result_name,
        .kind = .{ .call = call },
    });
    const result_name = if (result_type.ir_type.eql(.{ .int = 32 })) wide_result_name else name: {
        const narrowed_name = try self.resultName(instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = narrowed_name,
            .kind = .{ .cast = .{
                .op = .trunc,
                .from_ty = .{ .int = 32 },
                .value = .{ .named = wide_result_name },
                .to_ty = result_type.ir_type,
            } },
        });
        break :name narrowed_name;
    };
    self.values[instruction.index] = .{
        .ty = result_type,
        .value = .{ .named = result_name },
    };
}
