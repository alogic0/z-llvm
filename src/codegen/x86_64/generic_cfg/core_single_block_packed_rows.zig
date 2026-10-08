const shared = @import("core_shared.zig");
const std = shared.std;
const ir = shared.ir;
const MachineFunction = shared.MachineFunction;
const Instruction = shared.x86_64_machine.Instruction;

const i32Value = shared.i32Value;
const i64Value = shared.i64Value;
const isInt = shared.isInt;
const isNamed = shared.isNamed;
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");
const cabi_call_lowering = @import("cabi_call_lowering.zig");
const paramReg = cabi_abi_helpers.paramReg;
const findInstruction = cabi_call_lowering.findInstruction;

pub fn lowerGenericCfgSingleBlockPackedBits(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (try lowerGenericCfgPackedReplaceLowReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgPackedReadFlagReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgPackedU8LtImmReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgAsciiPredicateReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgNarrowBinaryImmReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgGrowCapacityReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgCmpUltU32Return(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgMaskBitReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgEnumIndexOfReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgPackedBitfieldStoreReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgMulShiftAddReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgPointerStoreConstReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    return false;
}

fn resolveIntConst(block: ir.BasicBlock, val: ir.Value) ?i64 {
    switch (val) {
        .int => |int| return i64Value(int) catch null,
        .named => |name| {
            const inst = findInstruction(block, name) orelse return null;
            switch (inst.kind) {
                .cast => |cast| {
                    if (cast.op == .zext or cast.op == .sext) {
                        return resolveIntConst(block, cast.value);
                    }
                    return null;
                },
                else => return null,
            }
        },
        else => return null,
    }
}

pub fn lowerGenericCfgMulShiftAddReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(function.ret_ty)) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1) return false;
    const param = function.params.items[0];
    if (!param.ty.eql(.{ .int = 32 })) return false;

    const ret_val = ret.value orelse return false;
    const ret_name = switch (ret_val) {
        .named => |n| n,
        else => return false,
    };

    const add_inst = findInstruction(block, ret_name) orelse return false;
    const add = switch (add_inst.kind) {
        .binary => |b| b,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 })) return false;

    var add_imm: i32 = 0;
    var shift_name: []const u8 = undefined;
    if (resolveIntConst(block, add.lhs)) |const_val| {
        if (const_val < std.math.minInt(i32) or const_val > std.math.maxInt(i32)) return false;
        add_imm = @intCast(const_val);
        shift_name = switch (add.rhs) {
            .named => |n| n,
            else => return false,
        };
    } else if (resolveIntConst(block, add.rhs)) |const_val| {
        if (const_val < std.math.minInt(i32) or const_val > std.math.maxInt(i32)) return false;
        add_imm = @intCast(const_val);
        shift_name = switch (add.lhs) {
            .named => |n| n,
            else => return false,
        };
    } else return false;

    const shift_inst = findInstruction(block, shift_name) orelse return false;
    const shift = switch (shift_inst.kind) {
        .binary => |b| b,
        else => return false,
    };
    if (shift.op != .ashr and shift.op != .lshr) return false;
    if (!shift.ty.eql(.{ .int = 32 })) return false;
    const mul_name = switch (shift.lhs) {
        .named => |n| n,
        else => return false,
    };
    const shift_val = resolveIntConst(block, shift.rhs) orelse return false;
    if (shift_val < 0 or shift_val > 31) return false;
    const shift_imm: u5 = @intCast(shift_val);

    const mul_inst = findInstruction(block, mul_name) orelse return false;
    const mul = switch (mul_inst.kind) {
        .binary => |b| b,
        else => return false,
    };
    if (mul.op != .mul or !mul.ty.eql(.{ .int = 32 })) return false;
    var mul_imm: i32 = 0;
    if (isNamed(mul.lhs, param.name)) {
        const c = resolveIntConst(block, mul.rhs) orelse return false;
        if (c < std.math.minInt(i32) or c > std.math.maxInt(i32)) return false;
        mul_imm = @intCast(c);
    } else if (isNamed(mul.rhs, param.name)) {
        const c = resolveIntConst(block, mul.lhs) orelse return false;
        if (c < std.math.minInt(i32) or c > std.math.maxInt(i32)) return false;
        mul_imm = @intCast(c);
    } else return false;

    const src = try paramReg(function, param.name, param.ty);

    try machine.instructions.append(allocator, .{ .mov_arg_eax = src });
    try machine.instructions.append(allocator, .{ .imul_eax_imm32 = mul_imm });
    if (shift.op == .ashr) {
        try machine.instructions.append(allocator, .{ .sar_eax_imm5 = shift_imm });
    } else {
        try machine.instructions.append(allocator, .{ .shr_eax_imm5 = shift_imm });
    }
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = add_imm });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgPackedBitfieldStoreReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.void) or ret.value != null) return false;
    if (function.params.items.len != 1) return false;
    const param = function.params.items[0];
    if (!param.ty.eql(.ptr)) return false;
    if (block.instructions.items.len != 3) return false;

    const inst0 = block.instructions.items[0];
    const inst1 = block.instructions.items[1];
    const inst2 = block.instructions.items[2];
    if (inst0.removed or inst1.removed or inst2.removed) return false;

    const load = switch (inst0.kind) {
        .load => |l| l,
        else => return false,
    };
    if (!isNamed(load.ptr, param.name)) return false;
    const load_res = inst0.result orelse return false;

    const binary = switch (inst1.kind) {
        .binary => |b| b,
        else => return false,
    };
    if (binary.op != .@"or" and binary.op != .@"and") return false;
    if (!binary.ty.eql(load.ty)) return false;
    if (!isNamed(binary.lhs, load_res)) return false;
    const mask = switch (binary.rhs) {
        .int => |val| try i64Value(val),
        else => return false,
    };
    const binary_res = inst1.result orelse return false;

    const store = switch (inst2.kind) {
        .store => |s| s,
        else => return false,
    };
    if (!store.ty.eql(load.ty)) return false;
    if (!isNamed(store.ptr, param.name)) return false;
    if (!isNamed(store.value, binary_res)) return false;

    const src = try paramReg(function, param.name, param.ty);

    const bits = switch (load.ty) {
        .int => |b| b,
        else => return false,
    };

    if (bits == 16) {
        try machine.instructions.append(allocator, .{ .load_arg_ptr_disp8_u16_eax = .{ .reg = src, .offset = 0 } });
        if (binary.op == .@"or") {
            try machine.instructions.append(allocator, .{ .or_eax_imm32 = @intCast(mask) });
        } else {
            try machine.instructions.append(allocator, .{ .and_eax_imm32 = @intCast(mask) });
        }
        try machine.instructions.append(allocator, .{ .store_ax_arg_ptr_disp8 = .{ .reg = src, .offset = 0 } });
        try machine.instructions.append(allocator, .ret);
        return true;
    } else if (bits == 8) {
        try machine.instructions.append(allocator, .{ .load_arg_ptr_disp8_u8_eax = .{ .reg = src, .offset = 0 } });
        if (binary.op == .@"or") {
            try machine.instructions.append(allocator, .{ .or_eax_imm32 = @intCast(mask) });
        } else {
            try machine.instructions.append(allocator, .{ .and_eax_imm32 = @intCast(mask) });
        }
        try machine.instructions.append(allocator, .{ .store_al_arg_ptr_disp8 = .{ .reg = src, .offset = 0 } });
        try machine.instructions.append(allocator, .ret);
        return true;
    } else if (bits == 32) {
        try machine.instructions.append(allocator, .{ .load_arg_ptr_disp8_eax = .{ .reg = src, .offset = 0 } });
        if (binary.op == .@"or") {
            try machine.instructions.append(allocator, .{ .or_eax_imm32 = @intCast(mask) });
        } else {
            try machine.instructions.append(allocator, .{ .and_eax_imm32 = @intCast(mask) });
        }
        try machine.instructions.append(allocator, .{ .store_eax_arg_ptr_disp8 = .{ .reg = src, .offset = 0 } });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    return false;
}

pub fn lowerGenericCfgPointerStoreConstReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.void) or ret.value != null) return false;
    if (function.params.items.len != 1) return false;
    const param = function.params.items[0];
    if (!param.ty.eql(.ptr)) return false;

    var store_inst_opt: ?ir.Instruction = null;
    for (block.instructions.items) |inst| {
        if (inst.removed) continue;
        switch (inst.kind) {
            .store => |s| {
                if (isNamed(s.ptr, param.name)) {
                    if (store_inst_opt != null) return false;
                    store_inst_opt = inst;
                }
            },
            .alloca, .load => continue,
            else => return false,
        }
    }

    const store_inst = store_inst_opt orelse return false;
    const store = switch (store_inst.kind) {
        .store => |s| s,
        else => return false,
    };
    if (store.attrs.isBarrier()) return false;

    const imm_val = switch (store.value) {
        .int => |int| try i64Value(int),
        else => return false,
    };
    if (imm_val < std.math.minInt(i32) or imm_val > std.math.maxInt(i32)) return false;

    const bits = switch (store.ty) {
        .int => |b| b,
        else => return false,
    };

    const reg = try paramReg(function, param.name, .ptr);

    if (bits == 64) {
        try machine.instructions.append(allocator, .{
            .store_imm64_arg_ptr_disp8 = .{
                .reg = reg,
                .offset = 0,
                .imm = @intCast(imm_val),
            },
        });
    } else {
        return false;
    }

    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgEnumIndexOfReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(function.ret_ty)) return false;
    if (!function.ret_ty.eql(.{ .int = 64 })) return false;
    if (function.params.items.len != 1) return false;
    const param = function.params.items[0];
    const param_bits = switch (param.ty) {
        .int => |bits| bits,
        else => return false,
    };
    if (param_bits == 0 or param_bits > 64) return false;

    var sub_literal: i64 = 0;
    var final_result_name: []const u8 = undefined;

    if (block.instructions.items.len == 1) {
        const inst0 = block.instructions.items[0];
        if (inst0.removed) return false;
        const cast = switch (inst0.kind) {
            .cast => |c| c,
            else => return false,
        };
        if (cast.op != .zext) return false;
        if (!cast.from_ty.eql(param.ty) or !cast.to_ty.eql(function.ret_ty)) return false;
        if (!isNamed(cast.value, param.name)) return false;
        final_result_name = inst0.result orelse return false;
    } else if (block.instructions.items.len == 2) {
        const inst0 = block.instructions.items[0];
        const inst1 = block.instructions.items[1];
        if (inst0.removed or inst1.removed) return false;

        if (inst0.kind == .binary and inst1.kind == .cast) {
            const binary = inst0.kind.binary;
            const cast = inst1.kind.cast;
            if (binary.op != .sub) return false;
            if (!binary.ty.eql(param.ty)) return false;
            if (!isNamed(binary.lhs, param.name)) return false;
            sub_literal = switch (binary.rhs) {
                .int => |val| try i64Value(val),
                else => return false,
            };
            const sub_res = inst0.result orelse return false;
            if (cast.op != .zext) return false;
            if (!cast.from_ty.eql(param.ty) or !cast.to_ty.eql(function.ret_ty)) return false;
            if (!isNamed(cast.value, sub_res)) return false;
            final_result_name = inst1.result orelse return false;
        } else if (inst0.kind == .cast and inst1.kind == .binary) {
            const cast = inst0.kind.cast;
            const binary = inst1.kind.binary;
            if (cast.op != .zext) return false;
            if (!cast.from_ty.eql(param.ty) or !cast.to_ty.eql(function.ret_ty)) return false;
            if (!isNamed(cast.value, param.name)) return false;
            const zext_res = inst0.result orelse return false;
            if (binary.op != .sub) return false;
            if (!binary.ty.eql(function.ret_ty)) return false;
            if (!isNamed(binary.lhs, zext_res)) return false;
            sub_literal = switch (binary.rhs) {
                .int => |val| try i64Value(val),
                else => return false,
            };
            final_result_name = inst1.result orelse return false;
        } else {
            return false;
        }
    } else {
        return false;
    }

    const ret_val = ret.value orelse return false;
    if (!isNamed(ret_val, final_result_name)) return false;

    const src = try paramReg(function, param.name, param.ty);

    if (param_bits == 64) {
        try machine.instructions.append(allocator, .{ .mov_arg_rax = src });
        if (sub_literal != 0) {
            return false;
        }
    } else {
        try machine.instructions.append(allocator, .{ .mov_arg_eax = src });
        if (param_bits < 32) {
            const mask: i32 = @intCast((@as(u32, 1) << @intCast(param_bits)) - 1);
            try machine.instructions.append(allocator, .{ .and_eax_imm32 = mask });
        }
        if (sub_literal != 0) {
            const imm32: i32 = -@as(i32, @intCast(sub_literal));
            try machine.instructions.append(allocator, .{ .add_eax_imm32 = imm32 });
        }
    }

    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgCmpUltU32Return(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 1 }) or !ret.ty.eql(.{ .int = 1 })) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 32 }) or !function.params.items[1].ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 1) return false;
    const icmp_inst = block.instructions.items[0];
    if (icmp_inst.removed) return false;
    const icmp_result = icmp_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, icmp_result)) return false;
    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .ult or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, function.params.items[0].name) or
        !isNamed(icmp.rhs, function.params.items[1].name)) return false;

    try machine.instructions.append(allocator, .cmp_ult_u32_edi_esi_al);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgPackedReplaceLowReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 8 }) or !ret.ty.eql(.{ .int = 8 })) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 8 }) or !function.params.items[1].ty.eql(.{ .int = 8 })) return false;
    if (block.instructions.items.len != 3) return false;
    const high_mask_inst = block.instructions.items[0];
    const low_mask_inst = block.instructions.items[1];
    const or_inst = block.instructions.items[2];
    if (high_mask_inst.removed or low_mask_inst.removed or or_inst.removed) return false;
    const high_result = high_mask_inst.result orelse return false;
    const low_result = low_mask_inst.result orelse return false;
    const or_result = or_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, or_result)) return false;

    const high_mask = switch (high_mask_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (high_mask.op != .@"and" or !high_mask.ty.eql(.{ .int = 8 })) return false;
    if (!isNamed(high_mask.lhs, function.params.items[0].name) or !isInt(high_mask.rhs, -8)) return false;

    const low_mask = switch (low_mask_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (low_mask.op != .@"and" or !low_mask.ty.eql(.{ .int = 8 })) return false;
    if (!isNamed(low_mask.lhs, function.params.items[1].name) or !isInt(low_mask.rhs, 7)) return false;

    const or_binary = switch (or_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (or_binary.op != .@"or" or !or_binary.ty.eql(.{ .int = 8 })) return false;
    if (!((isNamed(or_binary.lhs, low_result) and isNamed(or_binary.rhs, high_result)) or
        (isNamed(or_binary.lhs, high_result) and isNamed(or_binary.rhs, low_result)))) return false;

    try machine.instructions.append(allocator, .replace_low_i8_dil_sil_al);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgPackedReadFlagReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 1 }) or !ret.ty.eql(.{ .int = 1 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 8 })) return false;
    if (block.instructions.items.len != 1) return false;
    const icmp_inst = block.instructions.items[0];
    if (icmp_inst.removed) return false;
    const icmp_result = icmp_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, icmp_result)) return false;
    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .slt or !icmp.operand_ty.eql(.{ .int = 8 })) return false;
    if (!isNamed(icmp.lhs, function.params.items[0].name) or !isInt(icmp.rhs, 0)) return false;

    try machine.instructions.append(allocator, .read_flag_i8_dil_al);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgPackedU8LtImmReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 1 }) or !ret.ty.eql(.{ .int = 1 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 8 })) return false;
    if (block.instructions.items.len != 1) return false;
    const icmp_inst = block.instructions.items[0];
    if (icmp_inst.removed) return false;
    const icmp_result = icmp_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, icmp_result)) return false;
    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .ult or !icmp.operand_ty.eql(.{ .int = 8 })) return false;
    if (!isNamed(icmp.lhs, function.params.items[0].name)) return false;
    const imm = switch (icmp.rhs) {
        .int => |int| try i64Value(int),
        else => return false,
    };
    if (imm < 0 or imm > std.math.maxInt(u8)) return false;

    try machine.instructions.append(allocator, .{ .ult_i8_dil_imm8_al = @intCast(imm) });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgAsciiPredicateReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 1 }) or !ret.ty.eql(.{ .int = 1 })) return false;
    if (function.params.items.len != 1) return false;
    const is_i8 = function.params.items[0].ty.eql(.{ .int = 8 });
    const is_i32 = function.params.items[0].ty.eql(.{ .int = 32 });
    if (!is_i8 and !is_i32) return false;
    const arg0_name = function.params.items[0].name;

    // Pattern 1: Single range check (isUpper, isLower, isDigit, isSurrogateCodepoint)
    // %sub = sub iN %arg0, <low>
    // %cmp = icmp ult iN %sub, <len>
    // ret i1 %cmp
    if (block.instructions.items.len == 2) {
        const sub_inst = block.instructions.items[0];
        const cmp_inst = block.instructions.items[1];
        if (sub_inst.removed or cmp_inst.removed) return false;
        const sub_result = sub_inst.result orelse return false;
        const cmp_result = cmp_inst.result orelse return false;
        if (!isNamed(ret.value orelse return error.InvalidRet, cmp_result)) return false;

        const sub = switch (sub_inst.kind) {
            .binary => |binary| binary,
            else => return false,
        };
        if (sub.op != .sub) return false;
        if (!isNamed(sub.lhs, arg0_name)) return false;
        const low = switch (sub.rhs) {
            .int => |int| try i64Value(int),
            else => return false,
        };

        const icmp = switch (cmp_inst.kind) {
            .icmp => |icmp| icmp,
            else => return false,
        };
        if (icmp.predicate != .ult) return false;
        if (!isNamed(icmp.lhs, sub_result)) return false;
        const len = switch (icmp.rhs) {
            .int => |int| try i64Value(int),
            else => return false,
        };

        if (is_i8) {
            if (!sub.ty.eql(.{ .int = 8 }) or !icmp.operand_ty.eql(.{ .int = 8 })) return false;
            if (low < 0 or low > 255 or len < 0 or len > 255) return false;
            try machine.instructions.append(allocator, .{
                .ascii_range_u8_dil_imm8_imm8_al = .{
                    .low = @intCast(low),
                    .len = @intCast(len),
                },
            });
            try machine.instructions.append(allocator, .ret);
            return true;
        } else if (is_i32) {
            if (!sub.ty.eql(.{ .int = 32 }) or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
            if (low < 0 or low > std.math.maxInt(u32) or len < 0 or len > std.math.maxInt(u32)) return false;
            try machine.instructions.append(allocator, .{
                .range_u32_edi_imm32_imm32_al = .{
                    .low = @intCast(low),
                    .len = @intCast(len),
                },
            });
            try machine.instructions.append(allocator, .ret);
            return true;
        }
        return false;
    }

    // Pattern 2: Alphabetic check (isAlphabetic)
    // %masked = and i8 %arg0, -33 (or 223 / 0xdf)
    // %sub = sub i8 %masked, 65
    // %cmp = icmp ult i8 %sub, 26
    // ret i1 %cmp
    if (block.instructions.items.len == 3) {
        const mask_inst = block.instructions.items[0];
        const sub_inst = block.instructions.items[1];
        const cmp_inst = block.instructions.items[2];
        if (mask_inst.removed or sub_inst.removed or cmp_inst.removed) return false;
        const mask_result = mask_inst.result orelse return false;
        const sub_result = sub_inst.result orelse return false;
        const cmp_result = cmp_inst.result orelse return false;
        if (!isNamed(ret.value orelse return error.InvalidRet, cmp_result)) return false;

        const mask = switch (mask_inst.kind) {
            .binary => |binary| binary,
            else => return false,
        };
        if (mask.op != .@"and" or !mask.ty.eql(.{ .int = 8 })) return false;
        if (!isNamed(mask.lhs, arg0_name)) return false;
        const mask_val = switch (mask.rhs) {
            .int => |int| try i64Value(int),
            else => return false,
        };
        if (mask_val != -33 and mask_val != 223 and mask_val != 0xdf) return false;

        const sub = switch (sub_inst.kind) {
            .binary => |binary| binary,
            else => return false,
        };
        if (sub.op != .sub or !sub.ty.eql(.{ .int = 8 })) return false;
        if (!isNamed(sub.lhs, mask_result) or !isInt(sub.rhs, 65)) return false;

        const icmp = switch (cmp_inst.kind) {
            .icmp => |icmp| icmp,
            else => return false,
        };
        if (icmp.predicate != .ult or !icmp.operand_ty.eql(.{ .int = 8 })) return false;
        if (!isNamed(icmp.lhs, sub_result) or !isInt(icmp.rhs, 26)) return false;

        try machine.instructions.append(allocator, .ascii_alphabetic_dil_al);
        try machine.instructions.append(allocator, .ret);
        return true;
    }

    // Pattern 3: Whitespace check (isWhitespace)
    // %is_space = icmp eq i8 %arg0, 32
    // %ctrl_sub = sub i8 %arg0, 9
    // %is_ctrl = icmp ult i8 %ctrl_sub, 5
    // %res = or i1 %is_space, %is_ctrl
    // ret i1 %res
    if (block.instructions.items.len == 4) {
        const space_inst = block.instructions.items[0];
        const sub_inst = block.instructions.items[1];
        const ctrl_inst = block.instructions.items[2];
        const or_inst = block.instructions.items[3];
        if (space_inst.removed or sub_inst.removed or ctrl_inst.removed or or_inst.removed) return false;
        const space_result = space_inst.result orelse return false;
        const sub_result = sub_inst.result orelse return false;
        const ctrl_result = ctrl_inst.result orelse return false;
        const or_result = or_inst.result orelse return false;
        if (!isNamed(ret.value orelse return error.InvalidRet, or_result)) return false;

        const space_cmp = switch (space_inst.kind) {
            .icmp => |icmp| icmp,
            else => return false,
        };
        if (space_cmp.predicate != .eq or !space_cmp.operand_ty.eql(.{ .int = 8 })) return false;
        if (!isNamed(space_cmp.lhs, arg0_name) or !isInt(space_cmp.rhs, 32)) return false;

        const sub = switch (sub_inst.kind) {
            .binary => |binary| binary,
            else => return false,
        };
        if (sub.op != .sub or !sub.ty.eql(.{ .int = 8 })) return false;
        if (!isNamed(sub.lhs, arg0_name) or !isInt(sub.rhs, 9)) return false;

        const ctrl_cmp = switch (ctrl_inst.kind) {
            .icmp => |icmp| icmp,
            else => return false,
        };
        if (ctrl_cmp.predicate != .ult or !ctrl_cmp.operand_ty.eql(.{ .int = 8 })) return false;
        if (!isNamed(ctrl_cmp.lhs, sub_result) or !isInt(ctrl_cmp.rhs, 5)) return false;

        const or_bin = switch (or_inst.kind) {
            .binary => |binary| binary,
            else => return false,
        };
        if (or_bin.op != .@"or" or !or_bin.ty.eql(.{ .int = 1 })) return false;
        if (!((isNamed(or_bin.lhs, space_result) and isNamed(or_bin.rhs, ctrl_result)) or
            (isNamed(or_bin.lhs, ctrl_result) and isNamed(or_bin.rhs, space_result)))) return false;

        try machine.instructions.append(allocator, .ascii_whitespace_dil_al);
        try machine.instructions.append(allocator, .ret);
        return true;
    }

    // Pattern 4: Alphanumeric check (isAlphanumeric)
    // %digit_sub = sub i8 %arg0, 48
    // %is_digit = icmp ult i8 %digit_sub, 10
    // %alpha_mask = and i8 %arg0, -33
    // %alpha_sub = sub i8 %alpha_mask, 65
    // %is_alpha = icmp ult i8 %alpha_sub, 26
    // %res = or i1 %is_digit, %is_alpha
    // ret i1 %res
    if (block.instructions.items.len == 6) {
        const dsub_inst = block.instructions.items[0];
        const dcmp_inst = block.instructions.items[1];
        const amask_inst = block.instructions.items[2];
        const asub_inst = block.instructions.items[3];
        const acmp_inst = block.instructions.items[4];
        const or_inst = block.instructions.items[5];
        if (dsub_inst.removed or dcmp_inst.removed or amask_inst.removed or asub_inst.removed or acmp_inst.removed or or_inst.removed) return false;
        const dsub_result = dsub_inst.result orelse return false;
        const dcmp_result = dcmp_inst.result orelse return false;
        const amask_result = amask_inst.result orelse return false;
        const asub_result = asub_inst.result orelse return false;
        const acmp_result = acmp_inst.result orelse return false;
        const or_result = or_inst.result orelse return false;
        if (!isNamed(ret.value orelse return error.InvalidRet, or_result)) return false;

        const dsub = switch (dsub_inst.kind) {
            .binary => |binary| binary,
            else => return false,
        };
        if (dsub.op != .sub or !dsub.ty.eql(.{ .int = 8 })) return false;
        if (!isNamed(dsub.lhs, arg0_name) or !isInt(dsub.rhs, 48)) return false;

        const dcmp = switch (dcmp_inst.kind) {
            .icmp => |icmp| icmp,
            else => return false,
        };
        if (dcmp.predicate != .ult or !dcmp.operand_ty.eql(.{ .int = 8 })) return false;
        if (!isNamed(dcmp.lhs, dsub_result) or !isInt(dcmp.rhs, 10)) return false;

        const amask = switch (amask_inst.kind) {
            .binary => |binary| binary,
            else => return false,
        };
        if (amask.op != .@"and" or !amask.ty.eql(.{ .int = 8 })) return false;
        if (!isNamed(amask.lhs, arg0_name)) return false;
        const mask_val = switch (amask.rhs) {
            .int => |int| try i64Value(int),
            else => return false,
        };
        if (mask_val != -33 and mask_val != 223 and mask_val != 0xdf) return false;

        const asub = switch (asub_inst.kind) {
            .binary => |binary| binary,
            else => return false,
        };
        if (asub.op != .sub or !asub.ty.eql(.{ .int = 8 })) return false;
        if (!isNamed(asub.lhs, amask_result) or !isInt(asub.rhs, 65)) return false;

        const acmp = switch (acmp_inst.kind) {
            .icmp => |icmp| icmp,
            else => return false,
        };
        if (acmp.predicate != .ult or !acmp.operand_ty.eql(.{ .int = 8 })) return false;
        if (!isNamed(acmp.lhs, asub_result) or !isInt(acmp.rhs, 26)) return false;

        const or_bin = switch (or_inst.kind) {
            .binary => |binary| binary,
            else => return false,
        };
        if (or_bin.op != .@"or" or !or_bin.ty.eql(.{ .int = 1 })) return false;
        if (!((isNamed(or_bin.lhs, dcmp_result) and isNamed(or_bin.rhs, acmp_result)) or
            (isNamed(or_bin.lhs, acmp_result) and isNamed(or_bin.rhs, dcmp_result)))) return false;

        try machine.instructions.append(allocator, .ascii_alphanumeric_dil_al);
        try machine.instructions.append(allocator, .ret);
        return true;
    }

    return false;
}

pub fn lowerGenericCfgNarrowBinaryImmReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const ret_bits = switch (function.ret_ty) {
        .int => |bits| bits,
        else => return false,
    };
    if (ret_bits == 0 or ret_bits > 32) return false;
    if (!ret.ty.eql(function.ret_ty)) return false;
    if (function.params.items.len != 1) return false;
    const param_bits = switch (function.params.items[0].ty) {
        .int => |bits| bits,
        else => return false,
    };
    if (param_bits == 0 or param_bits > ret_bits) return false;
    const param_name = function.params.items[0].name;

    var binary_inst: ir.Instruction = undefined;
    var base_name: []const u8 = undefined;

    if (block.instructions.items.len == 1) {
        if (param_bits != ret_bits) return false;
        binary_inst = block.instructions.items[0];
        base_name = param_name;
    } else if (block.instructions.items.len == 2) {
        const inst0 = block.instructions.items[0];
        if (inst0.removed) return false;
        const cast = switch (inst0.kind) {
            .cast => |c| c,
            else => return false,
        };
        if (cast.op != .zext) return false;
        if (!cast.to_ty.eql(function.ret_ty)) return false;
        if (!isNamed(cast.value, param_name)) return false;
        const zext_res = inst0.result orelse return false;

        binary_inst = block.instructions.items[1];
        base_name = zext_res;
    } else {
        return false;
    }

    if (binary_inst.removed) return false;
    const inst_result = binary_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, inst_result)) return false;

    const binary = switch (binary_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    const binary_bits = switch (binary.ty) {
        .int => |bits| bits,
        else => return false,
    };
    if (binary_bits != ret_bits) return false;

    var literal: i64 = 0;
    const op = binary.op;

    if (isNamed(binary.lhs, base_name)) {
        literal = switch (binary.rhs) {
            .int => |int| try i64Value(int),
            else => return false,
        };
    } else if (isNamed(binary.rhs, base_name)) {
        if (op != .add and op != .xor and op != .@"and" and op != .@"or") return false;
        literal = switch (binary.lhs) {
            .int => |int| try i64Value(int),
            else => return false,
        };
    } else {
        return false;
    }

    if (literal < std.math.minInt(i32) or literal > std.math.maxInt(u32)) return false;
    const imm32: i32 = if (literal > std.math.maxInt(i32))
        @bitCast(@as(u32, @intCast(literal)))
    else
        @intCast(literal);

    try machine.instructions.append(allocator, .{ .mov_arg_eax = .rdi });

    if (param_bits < ret_bits and param_bits < 32) {
        const param_mask: i32 = @intCast((@as(u64, 1) << @intCast(param_bits)) - 1);
        try machine.instructions.append(allocator, .{ .and_eax_imm32 = param_mask });
    }

    switch (op) {
        .add => try machine.instructions.append(allocator, .{ .add_eax_imm32 = imm32 }),
        .sub => {
            const neg_literal = -literal;
            if (neg_literal < std.math.minInt(i32) or neg_literal > std.math.maxInt(i32)) return false;
            try machine.instructions.append(allocator, .{ .add_eax_imm32 = @intCast(neg_literal) });
        },
        .xor => try machine.instructions.append(allocator, .{ .xor_eax_imm32 = imm32 }),
        .@"and" => try machine.instructions.append(allocator, .{ .and_eax_imm32 = imm32 }),
        .@"or" => try machine.instructions.append(allocator, .{ .or_eax_imm32 = imm32 }),
        else => return false,
    }

    if (ret_bits < 32) {
        const mask: i32 = @intCast((@as(u64, 1) << @intCast(ret_bits)) - 1);
        try machine.instructions.append(allocator, .{ .and_eax_imm32 = mask });
    }

    try machine.instructions.append(allocator, .ret);
    return true;
}

fn isIntEqual(val: ir.Value, target: i64) bool {
    return switch (val) {
        .int => |int| (i64Value(int) catch return false) == target,
        else => false,
    };
}

fn isAddPairExtractImm(bin: ir.BinaryInst, named_name: []const u8, extracted_imm: *i32) bool {
    if (bin.op != .add) return false;
    if (isNamed(bin.lhs, named_name)) {
        const val = switch (bin.rhs) {
            .int => |int| i64Value(int) catch return false,
            else => return false,
        };
        if (val < std.math.minInt(i32) or val > std.math.maxInt(i32)) return false;
        extracted_imm.* = @intCast(val);
        return true;
    } else if (isNamed(bin.rhs, named_name)) {
        const val = switch (bin.lhs) {
            .int => |int| i64Value(int) catch return false,
            else => return false,
        };
        if (val < std.math.minInt(i32) or val > std.math.maxInt(i32)) return false;
        extracted_imm.* = @intCast(val);
        return true;
    }
    return false;
}

fn isAddPairNamed(bin: ir.BinaryInst, name_a: []const u8, name_b: []const u8) bool {
    if (bin.op != .add) return false;
    return (isNamed(bin.lhs, name_a) and isNamed(bin.rhs, name_b)) or
        (isNamed(bin.lhs, name_b) and isNamed(bin.rhs, name_a));
}

pub fn lowerGenericCfgGrowCapacityReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const ret_bits = switch (function.ret_ty) {
        .int => |bits| bits,
        else => return false,
    };
    if (ret_bits != 64) return false;
    if (!ret.ty.eql(function.ret_ty)) return false;
    if (function.params.items.len != 1) return false;
    const param = function.params.items[0];
    const param_bits = switch (param.ty) {
        .int => |bits| bits,
        else => return false,
    };
    if (param_bits != 64) return false;
    const param_name = param.name;

    if (block.instructions.items.len != 3) return false;
    const inst0 = block.instructions.items[0];
    const inst1 = block.instructions.items[1];
    const inst2 = block.instructions.items[2];
    if (inst0.removed or inst1.removed or inst2.removed) return false;

    const res0 = inst0.result orelse return false;
    const res1 = inst1.result orelse return false;
    const res2 = inst2.result orelse return false;

    const ret_val = ret.value orelse return error.InvalidRet;
    if (!isNamed(ret_val, res2)) return false;

    const bin0 = switch (inst0.kind) {
        .binary => |b| b,
        else => return false,
    };
    if (!isNamed(bin0.lhs, param_name)) return false;
    const is_div2 = (bin0.op == .udiv and isIntEqual(bin0.rhs, 2)) or
        (bin0.op == .lshr and isIntEqual(bin0.rhs, 1));
    if (!is_div2) return false;

    const bin1 = switch (inst1.kind) {
        .binary => |b| b,
        else => return false,
    };
    if (bin1.op != .add) return false;

    const bin2 = switch (inst2.kind) {
        .binary => |b| b,
        else => return false,
    };
    if (bin2.op != .add) return false;

    var imm: i32 = 0;
    var matched = false;
    if (isAddPairExtractImm(bin1, res0, &imm) and isAddPairNamed(bin2, param_name, res1)) {
        matched = true;
    } else if (isAddPairNamed(bin1, param_name, res0) and isAddPairExtractImm(bin2, res1, &imm)) {
        matched = true;
    } else if (isAddPairExtractImm(bin1, param_name, &imm) and isAddPairNamed(bin2, res1, res0)) {
        matched = true;
    }

    if (!matched) return false;

    try machine.instructions.append(allocator, .{ .grow_capacity_u64_rdi_imm32_rax = imm });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgMaskBitReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (function.params.items.len != 1) return false;
    const arg_param = function.params.items[0];
    const arg_bits = switch (arg_param.ty) {
        .int => |bits| bits,
        else => return false,
    };
    if (arg_bits != 32 and arg_bits != 64) return false;

    const ret_bits = switch (ret.ty) {
        .int => |bits| bits,
        else => return false,
    };
    if (ret_bits == 0 or ret_bits > 64) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        else => return false,
    };

    const shl_inst = findInstruction(block, ret_name) orelse return false;
    const shl_binary = switch (shl_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (shl_binary.op != .shl or !shl_binary.ty.eql(ret.ty)) return false;
    if (!isInt(shl_binary.lhs, 1)) return false;

    var current_value = shl_binary.rhs;
    while (true) {
        const name = switch (current_value) {
            .named => |n| n,
            else => return false,
        };
        if (std.mem.eql(u8, name, arg_param.name)) break;
        const inst = findInstruction(block, name) orelse return false;
        switch (inst.kind) {
            .cast => |cast| {
                if (cast.op != .trunc and cast.op != .zext) return false;
                current_value = cast.value;
            },
            .binary => |binary| {
                if (binary.op == .@"and") {
                    current_value = binary.lhs;
                } else return false;
            },
            else => return false,
        }
    }

    const arg_reg = try paramReg(function, arg_param.name, arg_param.ty);
    try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = .rcx, .src = arg_reg } });
    if (ret_bits <= 32) {
        try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
        try machine.instructions.append(allocator, .shl_eax_cl);
    } else {
        try machine.instructions.append(allocator, .{ .mov_imm_rax = 1 });
        try machine.instructions.append(allocator, .shl_rax_cl);
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}
