const std = @import("std");
const ir = @import("../../../ir.zig");
const x86_64_match = @import("../match.zig");
const x86_64_types = @import("../types.zig");
const x86_64_machine = @import("../machine.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");

const MachineBinaryOp = x86_64_types.MachineBinaryOp;
const ArgReg = x86_64_types.ArgReg;
const MachineFunction = x86_64_machine.MachineFunction;
const isNamed = x86_64_match.isNamed;
const isInt = x86_64_match.isInt;
const symbolName = x86_64_match.symbolName;
const paramRegOrNull = cabi_abi_helpers.paramRegOrNull;
const scalarParamStackDisp8 = cabi_abi_helpers.scalarParamStackDisp8;
const stackParamDisp8OrNull = cabi_abi_helpers.stackParamDisp8OrNull;
const registerParamRegOrNull = cabi_abi_helpers.registerParamRegOrNull;

pub fn machineBinaryOp(op: ir.BinaryOp) ?MachineBinaryOp {
    return switch (op) {
        .add => .add,
        .sub => .sub,
        .@"and" => .@"and",
        .@"or" => .@"or",
        .xor => .xor,
        .fadd, .fsub, .fmul, .fdiv, .frem, .mul, .shl, .lshr, .ashr, .udiv, .sdiv, .urem, .srem => null,
    };
}

pub fn singleLiveParamAfter(function: ir.Function, block: ir.BasicBlock, instruction_index: usize) !?ArgReg {
    var live: ?ArgReg = null;
    for (block.instructions.items[instruction_index + 1 ..]) |instruction| {
        if (instruction.removed) continue;
        try noteLiveParams(function, instruction, &live);
    }
    if (block.terminator) |terminator| switch (terminator) {
        .ret => |ret| if (ret.value) |value| try noteLiveValue(function, value, &live),
        .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => {},
    };
    return live;
}

pub const LiveParamSet = struct {
    regs: [6]ArgReg = undefined,
    count: usize = 0,

    fn add(self: *LiveParamSet, reg: ArgReg) !void {
        if (self.has(reg)) return;
        if (self.count == self.regs.len) return error.UnsupportedLiveAcrossCall;
        self.regs[self.count] = reg;
        self.count += 1;
    }

    fn has(self: LiveParamSet, reg: ArgReg) bool {
        for (self.regs[0..self.count]) |existing| {
            if (existing == reg) return true;
        }
        return false;
    }
};

pub fn liveParamsAfter(function: ir.Function, block: ir.BasicBlock, instruction_index: usize) !LiveParamSet {
    var live: LiveParamSet = .{};
    for (block.instructions.items[instruction_index + 1 ..]) |instruction| {
        if (instruction.removed) continue;
        try noteLiveParamsSet(function, block, instruction, &live);
    }
    if (block.terminator) |terminator| switch (terminator) {
        .ret => |ret| if (ret.value) |value| try noteLiveValueSet(function, block, value, &live),
        .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => {},
    };
    return live;
}

pub fn noteLiveParamsSet(function: ir.Function, block: ir.BasicBlock, instruction: ir.Instruction, live: *LiveParamSet) !void {
    switch (instruction.kind) {
        .binary => |binary| {
            try noteLiveValueSet(function, block, binary.lhs, live);
            try noteLiveValueSet(function, block, binary.rhs, live);
        },
        .call => |call| for (call.args.items) |arg| try noteLiveValueSet(function, block, arg.value, live),
        .cast => |cast| try noteLiveValueSet(function, block, cast.value, live),
        .freeze => |freeze| try noteLiveValueSet(function, block, freeze.value, live),
        .icmp => |icmp| {
            try noteLiveValueSet(function, block, icmp.lhs, live);
            try noteLiveValueSet(function, block, icmp.rhs, live);
        },
        .fcmp => |fcmp| {
            try noteLiveValueSet(function, block, fcmp.lhs, live);
            try noteLiveValueSet(function, block, fcmp.rhs, live);
        },
        .select => |select| {
            try noteLiveValueSet(function, block, select.cond, live);
            try noteLiveValueSet(function, block, select.true_value, live);
            try noteLiveValueSet(function, block, select.false_value, live);
        },
        .phi => |phi| for (phi.incoming.items) |incoming| try noteLiveValueSet(function, block, incoming.value, live),
        .load => |load| try noteLiveValueSet(function, block, load.ptr, live),
        .store => |store| {
            try noteLiveValueSet(function, block, store.value, live);
            try noteLiveValueSet(function, block, store.ptr, live);
        },
        .atomicrmw => |atomicrmw| {
            try noteLiveValueSet(function, block, atomicrmw.ptr, live);
            try noteLiveValueSet(function, block, atomicrmw.value, live);
        },
        .cmpxchg => |cmpxchg| {
            try noteLiveValueSet(function, block, cmpxchg.ptr, live);
            try noteLiveValueSet(function, block, cmpxchg.expected, live);
            try noteLiveValueSet(function, block, cmpxchg.replacement, live);
        },
        .extractvalue => |extract| try noteLiveValueSet(function, block, extract.aggregate, live),
        .insertvalue => |insert| {
            try noteLiveValueSet(function, block, insert.aggregate, live);
            try noteLiveValueSet(function, block, insert.value, live);
        },
        .gep => |gep| {
            try noteLiveValueSet(function, block, gep.ptr, live);
            for (gep.indices.items) |index| try noteLiveValueSet(function, block, index.value, live);
        },
        .alloca, .fence, .extractelement, .insertelement, .shufflevector => {},
    }
}

pub fn noteLiveValueSet(function: ir.Function, block: ir.BasicBlock, value: ir.Value, live: *LiveParamSet) !void {
    const name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return,
    };
    if (paramRegOrNull(function, name, .{ .int = 32 }) catch |err| switch (err) {
        error.UnsupportedCodegenAbi => {
            _ = try scalarParamStackDisp8(function, name, .{ .int = 32 });
            return;
        },
        else => return err,
    }) |reg| {
        try live.add(reg);
        return;
    }
    const instruction = findInstruction(block, name) orelse return;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return,
    };
    if (!binary.ty.eql(.{ .int = 32 }) or binary.op != .add) return error.UnsupportedLiveAcrossCall;
    try noteLiveValueSet(function, block, binary.lhs, live);
    try noteLiveValueSet(function, block, binary.rhs, live);
}

pub fn noteLiveParams(function: ir.Function, instruction: ir.Instruction, live: *?ArgReg) !void {
    switch (instruction.kind) {
        .binary => |binary| {
            try noteLiveValue(function, binary.lhs, live);
            try noteLiveValue(function, binary.rhs, live);
        },
        .call => |call| for (call.args.items) |arg| try noteLiveValue(function, arg.value, live),
        .cast => |cast| try noteLiveValue(function, cast.value, live),
        .freeze => |freeze| try noteLiveValue(function, freeze.value, live),
        .icmp => |icmp| {
            try noteLiveValue(function, icmp.lhs, live);
            try noteLiveValue(function, icmp.rhs, live);
        },
        .fcmp => |fcmp| {
            try noteLiveValue(function, fcmp.lhs, live);
            try noteLiveValue(function, fcmp.rhs, live);
        },
        .select => |select| {
            try noteLiveValue(function, select.cond, live);
            try noteLiveValue(function, select.true_value, live);
            try noteLiveValue(function, select.false_value, live);
        },
        .phi => |phi| for (phi.incoming.items) |incoming| try noteLiveValue(function, incoming.value, live),
        .alloca => {},
        .load => |load| try noteLiveValue(function, load.ptr, live),
        .store => |store| {
            try noteLiveValue(function, store.value, live);
            try noteLiveValue(function, store.ptr, live);
        },
        .atomicrmw => |atomicrmw| {
            try noteLiveValue(function, atomicrmw.ptr, live);
            try noteLiveValue(function, atomicrmw.value, live);
        },
        .cmpxchg => |cmpxchg| {
            try noteLiveValue(function, cmpxchg.ptr, live);
            try noteLiveValue(function, cmpxchg.expected, live);
            try noteLiveValue(function, cmpxchg.replacement, live);
        },
        .fence, .extractelement, .insertelement, .shufflevector => {},
        .extractvalue => |extract| try noteLiveValue(function, extract.aggregate, live),
        .insertvalue => |insert| {
            try noteLiveValue(function, insert.aggregate, live);
            try noteLiveValue(function, insert.value, live);
        },
        .gep => |gep| {
            try noteLiveValue(function, gep.ptr, live);
            for (gep.indices.items) |index| try noteLiveValue(function, index.value, live);
        },
    }
}

pub fn noteLiveValue(function: ir.Function, value: ir.Value, live: *?ArgReg) !void {
    const name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return,
    };
    const reg = try paramRegOrNull(function, name, .{ .int = 32 }) orelse return;
    if (live.*) |existing| {
        if (existing != reg) return error.UnsupportedLiveAcrossCall;
    } else {
        live.* = reg;
    }
}

pub fn identityCastFrom(instruction: ir.Instruction, value_name: []const u8, from_ty: ir.Type, to_ty: ir.Type) ?[]const u8 {
    const result = instruction.result orelse return null;
    const cast = switch (instruction.kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (cast.op != .bitcast or !cast.from_ty.eql(from_ty) or !cast.to_ty.eql(to_ty)) return null;
    if (!isNamed(cast.value, value_name)) return null;
    return result;
}

pub fn isSelectI1ToI32ZeroOne(instruction: ir.Instruction, cond_name: []const u8) bool {
    if (instruction.removed) return false;
    const select = switch (instruction.kind) {
        .select => |select| select,
        else => return false,
    };
    return select.cond_ty.eql(.{ .int = 1 }) and
        select.ty.eql(.{ .int = 32 }) and
        isNamed(select.cond, cond_name) and
        isInt(select.true_value, 0) and
        isInt(select.false_value, 1);
}

pub fn isSelectI1ToI32ExpectedOne(instruction: ir.Instruction, cond_name: []const u8, expected: i32) bool {
    if (instruction.removed) return false;
    const select = switch (instruction.kind) {
        .select => |select| select,
        else => return false,
    };
    return select.cond_ty.eql(.{ .int = 1 }) and
        select.ty.eql(.{ .int = 32 }) and
        isNamed(select.cond, cond_name) and
        isInt(select.true_value, expected) and
        isInt(select.false_value, 1);
}

pub fn valueReferencesGlobal(value: ir.Value, name: []const u8) bool {
    return switch (value) {
        .named => |value_name| std.mem.eql(u8, symbolName(value_name), name),
        .constant_expr => |text| std.mem.indexOf(u8, text, name) != null,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => false,
    };
}

pub fn phiHasIncoming(phi: ir.PhiInst, value_name: []const u8, block_name: []const u8) bool {
    for (phi.incoming.items) |incoming| {
        if (std.mem.eql(u8, incoming.block, block_name) and isNamed(incoming.value, value_name)) return true;
    }
    return false;
}

pub fn phiHasIncomingInt(phi: ir.PhiInst, value: i128, block_name: []const u8) bool {
    for (phi.incoming.items) |incoming| {
        if (std.mem.eql(u8, incoming.block, block_name) and isInt(incoming.value, value)) return true;
    }
    return false;
}

pub fn matchIcmpEqParamImm(instruction: ir.Instruction, param_name: []const u8, ty: ir.Type, imm: i128) bool {
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(ty)) return false;
    return (isNamed(icmp.lhs, param_name) and isInt(icmp.rhs, imm)) or
        (isNamed(icmp.rhs, param_name) and isInt(icmp.lhs, imm));
}

pub fn isCommutative(op: ir.BinaryOp) bool {
    return switch (op) {
        .add, .mul, .@"and", .@"or", .xor => true,
        .fadd, .fsub, .fmul, .fdiv, .frem, .sub, .shl, .lshr, .ashr, .udiv, .sdiv, .urem, .srem => false,
    };
}

pub fn findInstruction(block: ir.BasicBlock, result_name: []const u8) ?ir.Instruction {
    for (block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        const result = instruction.result orelse continue;
        if (std.mem.eql(u8, result, result_name)) return instruction;
    }
    return null;
}

pub fn findInstructionIndex(block: ir.BasicBlock, result_name: []const u8) ?usize {
    for (block.instructions.items, 0..) |instruction, index| {
        if (instruction.removed) continue;
        const result = instruction.result orelse continue;
        if (std.mem.eql(u8, result, result_name)) return index;
    }
    return null;
}

pub fn emitI32ParamOrStackIntoEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    name: []const u8,
) !bool {
    if (try registerParamRegOrNull(function, name, .{ .int = 32 })) |reg| {
        try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
        return true;
    }
    if (try stackParamDisp8OrNull(function, name, .{ .int = 32 })) |offset| {
        if (offset <= std.math.maxInt(i8)) {
            try machine.instructions.append(allocator, .{ .load_stack_disp8_rax = @intCast(offset) });
        } else {
            try machine.instructions.append(allocator, .{ .load_stack_disp32_rax = offset });
        }
        return true;
    }
    return false;
}
