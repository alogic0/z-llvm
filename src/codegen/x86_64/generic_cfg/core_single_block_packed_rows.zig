const shared = @import("core_shared.zig");
const std = shared.std;
const ir = shared.ir;
const MachineFunction = shared.MachineFunction;
const Instruction = shared.x86_64_machine.Instruction;

const i64Value = shared.i64Value;
const isInt = shared.isInt;
const isNamed = shared.isNamed;

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
    return false;
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
