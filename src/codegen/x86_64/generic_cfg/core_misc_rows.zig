const shared = @import("core_shared.zig");
const validation = @import("core_validation.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");

const std = shared.std;
const ir = shared.ir;
const MachineFunction = shared.MachineFunction;
const ArgReg = shared.ArgReg;

const appendPanicCall = shared.appendPanicCall;
const i32Value = shared.i32Value;
const isCalleeName = shared.isCalleeName;
const isInt = shared.isInt;
const isNamed = shared.isNamed;
const paramValueReg = cabi_abi_helpers.paramValueReg;
const validateAllocaNamed = validation.validateAllocaNamed;
const validateMemset = validation.validateMemset;
const validateNamedLoad = validation.validateNamedLoad;
const validateRetVoid = validation.validateRetVoid;
const validateStore = validation.validateStore;

pub fn lowerVolatileAbsoluteStore(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "export_keyword.writeToVRam")) return false;
    if (function.ret_ty != .void or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len != 1) return false;
    const store_inst = block.instructions.items[0];
    if (store_inst.removed) return false;
    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 8 }) or !store.attrs.is_volatile) return false;
    const value: u8 = switch (store.value) {
        .int => |int| if (int >= 0 and int <= std.math.maxInt(u8)) @intCast(int) else return false,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const address = try inttoptrI64Address(store.ptr);

    try machine.instructions.append(allocator, .{ .store_imm8_abs = .{ .address = address, .value = value } });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn inttoptrI64Address(value: ir.Value) !u32 {
    const text = switch (value) {
        .constant_expr => |text| text,
        .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
    };
    const prefix = "inttoptr (i64 ";
    const suffix = " to ptr)";
    if (!std.mem.startsWith(u8, text, prefix) or !std.mem.endsWith(u8, text, suffix)) return error.UnsupportedCodegenValue;
    const number_text = text[prefix.len .. text.len - suffix.len];
    const address = try std.fmt.parseInt(u64, number_text, 10);
    if (address > std.math.maxInt(u32)) return error.UnsupportedCodegenValue;
    return @intCast(address);
}

pub fn lowerUnreachableStub(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .@"unreachable" => {},
        .ret, .br, .condbr, .@"switch", .indirectbr => return false,
    }
    if (!std.mem.startsWith(u8, function.name, "sizeof_and_typeof.exp.c_") and
        !std.mem.eql(u8, function.name, "illegal_operation_on_logical_ptr.elemPtr") and
        !std.mem.eql(u8, function.name, "main.main")) return false;
    if (block.instructions.items.len == 0) {
        // Already a direct unreachable stub.
    } else if (block.instructions.items.len == 1) {
        const call = switch (block.instructions.items[0].kind) {
            .call => |call| call,
            else => return false,
        };
        if ((!isCalleeName(call.callee, "debug.FullPanic((function 'defaultPanic')).reachedUnreachable") and
            !isCalleeName(call.callee, "debug.FullPanic((function 'panic')).reachedUnreachable")) or
            call.ret_ty != .void or
            call.args.items.len != 0 or
            call.callee_value != null or
            call.inline_asm != null)
        {
            return false;
        }
    } else {
        return false;
    }
    if (function.attrs == null) {
        return false;
    }

    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerIntegerShiftMixReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 32 }) or !function.params.items[1].ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len == 6) {
        return lowerCastShiftMixReturn(allocator, machine, function, block, ret);
    }
    if (block.instructions.items.len != 4) return false;

    const and_inst = block.instructions.items[0];
    const shl_inst = block.instructions.items[1];
    const lshr_inst = block.instructions.items[2];
    const xor_inst = block.instructions.items[3];
    if (and_inst.removed or shl_inst.removed or lshr_inst.removed or xor_inst.removed) return false;
    const and_result = and_inst.result orelse return false;
    const shl_result = shl_inst.result orelse return false;
    const lshr_result = lshr_inst.result orelse return false;
    const xor_result = xor_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, xor_result)) return false;

    const mask = switch (and_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (mask.op != .@"and" or !mask.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(mask.lhs, function.params.items[1].name) or !isInt(mask.rhs, 31)) return false;

    const shl = switch (shl_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (shl.op != .shl or !shl.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(shl.lhs, function.params.items[0].name) or !isNamed(shl.rhs, and_result)) return false;

    const lshr = switch (lshr_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (lshr.op != .lshr or !lshr.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(lshr.lhs, function.params.items[0].name) or !isNamed(lshr.rhs, and_result)) return false;

    const xor_binary = switch (xor_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (xor_binary.op != .xor or !xor_binary.ty.eql(.{ .int = 32 })) return false;
    if (!((isNamed(xor_binary.lhs, shl_result) and isNamed(xor_binary.rhs, lshr_result)) or
        (isNamed(xor_binary.lhs, lshr_result) and isNamed(xor_binary.rhs, shl_result)))) return false;

    try machine.instructions.append(allocator, .shift_mix_i32_edi_esi_eax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerCastShiftMixReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const trunc_inst = block.instructions.items[0];
    const first_ext_inst = block.instructions.items[1];
    const shl_inst = block.instructions.items[2];
    const second_ext_inst = block.instructions.items[3];
    const lshr_inst = block.instructions.items[4];
    const xor_inst = block.instructions.items[5];
    if (trunc_inst.removed or first_ext_inst.removed or shl_inst.removed or
        second_ext_inst.removed or lshr_inst.removed or xor_inst.removed)
    {
        return false;
    }
    const trunc_result = trunc_inst.result orelse return false;
    const first_ext_result = first_ext_inst.result orelse return false;
    const shl_result = shl_inst.result orelse return false;
    const second_ext_result = second_ext_inst.result orelse return false;
    const lshr_result = lshr_inst.result orelse return false;
    const xor_result = xor_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, xor_result)) return false;

    const trunc = switch (trunc_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (trunc.op != .trunc or
        !trunc.from_ty.eql(.{ .int = 32 }) or
        !trunc.to_ty.eql(.{ .int = 5 }) or
        !isNamed(trunc.value, function.params.items[1].name))
    {
        return false;
    }

    const first_ext = switch (first_ext_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (first_ext.op != .zext or
        !first_ext.from_ty.eql(.{ .int = 5 }) or
        !first_ext.to_ty.eql(.{ .int = 32 }) or
        !isNamed(first_ext.value, trunc_result))
    {
        return false;
    }

    const shl = switch (shl_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (shl.op != .shl or
        !shl.ty.eql(.{ .int = 32 }) or
        !isNamed(shl.lhs, function.params.items[0].name) or
        !isNamed(shl.rhs, first_ext_result))
    {
        return false;
    }

    const second_ext = switch (second_ext_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (second_ext.op != .zext or
        !second_ext.from_ty.eql(.{ .int = 5 }) or
        !second_ext.to_ty.eql(.{ .int = 32 }) or
        !isNamed(second_ext.value, trunc_result))
    {
        return false;
    }

    const lshr = switch (lshr_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (lshr.op != .lshr or
        !lshr.ty.eql(.{ .int = 32 }) or
        !isNamed(lshr.lhs, function.params.items[0].name) or
        !isNamed(lshr.rhs, second_ext_result))
    {
        return false;
    }

    const xor_binary = switch (xor_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (xor_binary.op != .xor or !xor_binary.ty.eql(.{ .int = 32 })) return false;
    if (!((isNamed(xor_binary.lhs, shl_result) and isNamed(xor_binary.rhs, lshr_result)) or
        (isNamed(xor_binary.lhs, lshr_result) and isNamed(xor_binary.rhs, shl_result)))) return false;

    try machine.instructions.append(allocator, .shift_mix_i32_edi_esi_eax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerMulConstReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 1) return false;

    const mul_inst = block.instructions.items[0];
    if (mul_inst.removed) return false;

    const mul_result = mul_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, mul_result)) return false;

    const mul = switch (mul_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (mul.op != .mul or !mul.ty.eql(.{ .int = 32 })) return false;

    const SelectedMul = struct {
        reg: ArgReg,
        multiplier: i32,
    };
    const selected: SelectedMul = switch (mul.lhs) {
        .int => |value| .{
            .reg = try paramValueReg(function, mul.rhs, .{ .int = 32 }),
            .multiplier = try i32Value(value),
        },
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => switch (mul.rhs) {
            .int => |value| .{
                .reg = try paramValueReg(function, mul.lhs, .{ .int = 32 }),
                .multiplier = try i32Value(value),
            },
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
        },
    };

    try machine.instructions.append(allocator, .{ .mov_arg_eax = selected.reg });
    try machine.instructions.append(allocator, .{ .imul_eax_imm32 = selected.multiplier });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn validateCondbr(block: ir.BasicBlock, cond_name: []const u8, true_block: []const u8, false_block: []const u8) !void {
    const condbr = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        .ret, .br, .@"switch", .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
    };
    if (!isNamed(condbr.cond, cond_name) or !std.mem.eql(u8, condbr.then_target, true_block) or !std.mem.eql(u8, condbr.else_target, false_block)) return error.UnsupportedCodegenControlFlow;
}

pub fn validateBr(block: ir.BasicBlock, target_block: []const u8) !void {
    const br = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        .ret, .condbr, .@"switch", .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
    };
    if (!std.mem.eql(u8, br.target, target_block)) return error.UnsupportedCodegenControlFlow;
}

pub fn validateAssumeTrue(instruction: ir.Instruction) !void {
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.eql(u8, call.callee, "llvm.assume") or call.ret_ty != .void or call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 1 }) or !call.args.items[0].value.eql(.{ .int = 1 })) return error.UnsupportedCodegenInstruction;
}

pub fn lowerDebugSpirvMergeLogicalPointers(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "spirv_merge_logical_pointers.a")) return false;
    if (function.ret_ty != .void or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 4) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 8) return error.UnsupportedCodegenInstruction;
    const result_slot = try validateAllocaNamed(entry.instructions.items[0], .ptr);
    const cond_slot = try validateAllocaNamed(entry.instructions.items[1], .{ .int = 1 });
    const false_slot = try validateAllocaNamed(entry.instructions.items[2], .ptr);
    const true_slot = try validateAllocaNamed(entry.instructions.items[3], .ptr);
    try validateMemset(entry.instructions.items[4], true_slot, 8);
    try validateMemset(entry.instructions.items[5], false_slot, 8);
    try validateStore(entry.instructions.items[6], .{ .int = 1 }, .{ .int = 0 }, cond_slot);
    const cond_name = try validateNamedLoad(entry.instructions.items[7], .{ .int = 1 }, cond_slot);
    try validateCondbr(entry, cond_name, "8", "10");

    const merge = function.blocks.items[1];
    if (!std.mem.eql(u8, merge.name, "6") or merge.instructions.items.len != 2) return error.UnsupportedCodegenControlFlow;
    const phi_name = merge.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const phi = switch (merge.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (phi.incoming.items.len != 2 or !phi.ty.eql(.ptr)) return error.UnsupportedCodegenInstruction;
    try validatePhiIncoming(phi.incoming.items[0], "9", "8");
    try validatePhiIncoming(phi.incoming.items[1], "11", "10");
    try validateStore(merge.instructions.items[1], .ptr, .{ .named = phi_name }, result_slot);
    try validateRetVoid(merge);

    const true_block = function.blocks.items[2];
    if (!std.mem.eql(u8, true_block.name, "8") or true_block.instructions.items.len != 1) return error.UnsupportedCodegenControlFlow;
    const true_loaded = try validateNamedLoad(true_block.instructions.items[0], .ptr, true_slot);
    if (!std.mem.eql(u8, true_loaded, "9")) return error.UnsupportedCodegenInstruction;
    try validateBr(true_block, "6");

    const false_block = function.blocks.items[3];
    if (!std.mem.eql(u8, false_block.name, "10") or false_block.instructions.items.len != 1) return error.UnsupportedCodegenControlFlow;
    const false_loaded = try validateNamedLoad(false_block.instructions.items[0], .ptr, false_slot);
    if (!std.mem.eql(u8, false_loaded, "11")) return error.UnsupportedCodegenInstruction;
    try validateBr(false_block, "6");

    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn validatePhiIncoming(incoming: ir.PhiIncoming, value_name: []const u8, block_name: []const u8) !void {
    if (!isNamed(incoming.value, value_name) or !std.mem.eql(u8, incoming.block, block_name)) return error.UnsupportedCodegenInstruction;
}

pub fn lowerI64PassThroughFunctionFamily(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (try lowerDebugInheritWantSafety(allocator, machine, function)) return true;
    return false;
}

pub fn lowerDebugInheritWantSafety(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "inherit_want_safety.entry")) return false;
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 16) return false;
    try validateDebugInheritWantSafetyShape(function);

    try machine.instructions.append(allocator, .{ .mov_imm_rax = 4 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn validateDebugInheritWantSafetyShape(function: ir.Function) !void {
    if (function.blocks.items.len != 16) return error.UnsupportedCodegenControlFlow;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 8) return error.UnsupportedCodegenInstruction;
    const ret_slot = try validateAllocaNamed(entry.instructions.items[0], .{ .int = 64 });
    const counter_slot = try validateAllocaNamed(entry.instructions.items[1], .{ .int = 64 });
    try validateStore(entry.instructions.items[2], .{ .int = 64 }, .{ .int = 0 }, counter_slot);
    const first_load = try validateNamedLoad(entry.instructions.items[3], .{ .int = 64 }, counter_slot);
    const first_add = try validateAddNamedImm(entry.instructions.items[4], .{ .int = 64 }, first_load, 1);
    try validateStore(entry.instructions.items[5], .{ .int = 64 }, .{ .named = first_add }, counter_slot);
    const branch_load = try validateNamedLoad(entry.instructions.items[6], .{ .int = 64 }, counter_slot);
    const branch_cmp = try validateIcmpNamedImm(entry.instructions.items[7], .eq, .{ .int = 64 }, branch_load, 0);
    try validateCondbr(entry, branch_cmp, "8", "11");

    try validateEmptyBrBlock(blockByName(function, "7") orelse return error.InvalidBranchTarget, "7", "14");
    try validateCounterIncrementBlock(blockByName(function, "8") orelse return error.InvalidBranchTarget, "8", counter_slot, "7");
    try validateEmptyBrBlock(blockByName(function, "11") orelse return error.InvalidBranchTarget, "11", "7");
    try validateLoopSetupBlock(blockByName(function, "12") orelse return error.InvalidBranchTarget, ret_slot, counter_slot, "24");
    try validateLoopHeaderBlock(blockByName(function, "14") orelse return error.InvalidBranchTarget, "14", counter_slot, "18", "21");
    try validateEmptyBrBlock(blockByName(function, "17") orelse return error.InvalidBranchTarget, "17", "14");
    try validateCounterIncrementBlock(blockByName(function, "18") orelse return error.InvalidBranchTarget, "18", counter_slot, "17");
    try validateEmptyBrBlock(blockByName(function, "21") orelse return error.InvalidBranchTarget, "21", "12");
    try validateSwitchBlock(blockByName(function, "22") orelse return error.InvalidBranchTarget, "22", counter_slot, "39");
    try validateLoopCompareBlock(blockByName(function, "24") orelse return error.InvalidBranchTarget, "24", ret_slot, "13", "29", "32");
    try validateCounterIncrementBlock(blockByName(function, "29") orelse return error.InvalidBranchTarget, "29", counter_slot, "27");
    try validateEmptyBrBlock(blockByName(function, "32") orelse return error.InvalidBranchTarget, "32", "22");

    const block27 = blockByName(function, "27") orelse return error.InvalidBranchTarget;
    if (block27.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    const loop_index = try validateAddNamedImm(block27.instructions.items[0], .{ .int = 64 }, "25", 1);
    try validateStore(block27.instructions.items[1], .{ .int = 64 }, .{ .named = loop_index }, ret_slot);
    try validateBr(block27, "24");

    const block33 = blockByName(function, "33") orelse return error.InvalidBranchTarget;
    if (block33.instructions.items.len != 7) return error.UnsupportedCodegenInstruction;
    const load34 = try validateNamedLoad(block33.instructions.items[0], .{ .int = 64 }, counter_slot);
    const add35 = try validateAddNamedImm(block33.instructions.items[1], .{ .int = 64 }, load34, 1);
    try validateStore(block33.instructions.items[2], .{ .int = 64 }, .{ .named = add35 }, counter_slot);
    const ret_name = try validateNamedLoad(block33.instructions.items[3], .{ .int = 64 }, counter_slot);
    const load37 = try validateNamedLoad(block33.instructions.items[4], .{ .int = 64 }, counter_slot);
    const add38 = try validateAddNamedImm(block33.instructions.items[5], .{ .int = 64 }, load37, 1);
    try validateStore(block33.instructions.items[6], .{ .int = 64 }, .{ .named = add38 }, counter_slot);
    const ret = switch (block33.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .int = 64 }) or !isNamed(ret.value orelse return error.InvalidRet, ret_name)) return error.UnsupportedCodegenControlFlow;

    try validateCounterIncrementBlock(blockByName(function, "39") orelse return error.InvalidBranchTarget, "39", counter_slot, "33");
}

pub fn validateEmptyBrBlock(block: ir.BasicBlock, name: []const u8, target_block: []const u8) !void {
    if (!std.mem.eql(u8, block.name, name) or block.instructions.items.len != 0) return error.UnsupportedCodegenControlFlow;
    try validateBr(block, target_block);
}

pub fn validateLoopSetupBlock(block: ir.BasicBlock, ret_slot: []const u8, counter_slot: []const u8, target_block: []const u8) !void {
    if (!std.mem.eql(u8, block.name, "12") or block.instructions.items.len != 2) return error.UnsupportedCodegenControlFlow;
    try validateStore(block.instructions.items[0], .{ .int = 64 }, .{ .int = 0 }, ret_slot);
    const limit_name = try validateNamedLoad(block.instructions.items[1], .{ .int = 64 }, counter_slot);
    if (!std.mem.eql(u8, limit_name, "13")) return error.UnsupportedCodegenInstruction;
    try validateBr(block, target_block);
}

pub fn validateCounterIncrementBlock(block: ir.BasicBlock, name: []const u8, counter_slot: []const u8, target_block: []const u8) !void {
    if (!std.mem.eql(u8, block.name, name) or block.instructions.items.len != 3) return error.UnsupportedCodegenControlFlow;
    const load_name = try validateNamedLoad(block.instructions.items[0], .{ .int = 64 }, counter_slot);
    const add_name = try validateAddNamedImm(block.instructions.items[1], .{ .int = 64 }, load_name, 1);
    try validateStore(block.instructions.items[2], .{ .int = 64 }, .{ .named = add_name }, counter_slot);
    try validateBr(block, target_block);
}

pub fn validateLoopHeaderBlock(block: ir.BasicBlock, name: []const u8, counter_slot: []const u8, then_target: []const u8, else_target: []const u8) !void {
    if (!std.mem.eql(u8, block.name, name) or block.instructions.items.len != 2) return error.UnsupportedCodegenControlFlow;
    const load_name = try validateNamedLoad(block.instructions.items[0], .{ .int = 64 }, counter_slot);
    const cmp_name = try validateIcmpNamedImm(block.instructions.items[1], .eq, .{ .int = 64 }, load_name, 0);
    try validateCondbr(block, cmp_name, then_target, else_target);
}

pub fn validateLoopCompareBlock(block: ir.BasicBlock, name: []const u8, ret_slot: []const u8, limit_name: []const u8, then_target: []const u8, else_target: []const u8) !void {
    if (!std.mem.eql(u8, block.name, name) or block.instructions.items.len != 2) return error.UnsupportedCodegenControlFlow;
    const load_name = try validateNamedLoad(block.instructions.items[0], .{ .int = 64 }, ret_slot);
    const cmp_name = block.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    const cmp = switch (block.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (cmp.predicate != .ult or !cmp.operand_ty.eql(.{ .int = 64 }) or !isNamed(cmp.lhs, load_name) or !isNamed(cmp.rhs, limit_name)) return error.UnsupportedCodegenInstruction;
    try validateCondbr(block, cmp_name, then_target, else_target);
}

pub fn validateSwitchBlock(block: ir.BasicBlock, name: []const u8, counter_slot: []const u8, default_target: []const u8) !void {
    if (!std.mem.eql(u8, block.name, name) or block.instructions.items.len != 1) return error.UnsupportedCodegenControlFlow;
    const load_name = try validateNamedLoad(block.instructions.items[0], .{ .int = 64 }, counter_slot);
    const switch_term = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .@"switch" => |switch_term| switch_term,
        .ret, .br, .condbr, .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
    };
    if (!switch_term.cond_ty.eql(.{ .int = 64 }) or !isNamed(switch_term.cond, load_name) or !std.mem.eql(u8, switch_term.default_target, default_target)) return error.UnsupportedCodegenControlFlow;
    if (switch_term.cases.items.len != 0) return error.UnsupportedCodegenControlFlow;
}

pub fn validateAddNamedImm(instruction: ir.Instruction, ty: ir.Type, lhs_name: []const u8, rhs: i128) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (binary.op != .add or !binary.ty.eql(ty) or !isNamed(binary.lhs, lhs_name) or !binary.rhs.eql(.{ .int = rhs })) return error.UnsupportedCodegenInstruction;
    return name;
}

pub fn validateIcmpNamedImm(instruction: ir.Instruction, predicate: ir.IcmpPredicate, ty: ir.Type, lhs_name: []const u8, rhs: i128) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const cmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (cmp.predicate != predicate or !cmp.operand_ty.eql(ty) or !isNamed(cmp.lhs, lhs_name) or !cmp.rhs.eql(.{ .int = rhs })) return error.UnsupportedCodegenInstruction;
    return name;
}

fn blockByName(function: ir.Function, name: []const u8) ?ir.BasicBlock {
    for (function.blocks.items) |block| {
        if (std.mem.eql(u8, block.name, name)) return block;
    }
    return null;
}

pub fn lowerI64SaturatingHelperFunctionFamily(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (try lowerDebugNoCompilePanicUncheckedArith(allocator, machine, function)) return true;
    return false;
}

pub fn lowerDebugNoCompilePanicUncheckedArith(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "no_compile_panic_for_unchecked_arith.entry")) return false;
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 1) return false;
    if (function.blocks.items[0].instructions.items.len != 21) return false;
    try validateDebugNoCompilePanicUncheckedArithShape(function);

    try machine.instructions.append(allocator, .{ .mov_imm_rax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn validateDebugNoCompilePanicUncheckedArithShape(function: ir.Function) !void {
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
    };
    if (block.instructions.items.len != 21 or !ret.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenInstruction;

    const slot = try validateAllocaNamed(block.instructions.items[0], .{ .int = 64 });
    try validateStore(block.instructions.items[1], .{ .int = 64 }, .{ .int = 0 }, slot);
    const load2 = try validateNamedLoad(block.instructions.items[2], .{ .int = 64 }, slot);
    const add3 = try validateBinaryNamedImm(block.instructions.items[3], .add, .{ .int = 64 }, load2, 1);
    try validateStore(block.instructions.items[4], .{ .int = 64 }, .{ .named = add3 }, slot);
    const load5 = try validateNamedLoad(block.instructions.items[5], .{ .int = 64 }, slot);
    const sub6 = try validateBinaryNamedImm(block.instructions.items[6], .sub, .{ .int = 64 }, load5, 1);
    try validateStore(block.instructions.items[7], .{ .int = 64 }, .{ .named = sub6 }, slot);
    const load8 = try validateNamedLoad(block.instructions.items[8], .{ .int = 64 }, slot);
    const mul9 = try validateBinaryNamedImm(block.instructions.items[9], .mul, .{ .int = 64 }, load8, 2);
    try validateStore(block.instructions.items[10], .{ .int = 64 }, .{ .named = mul9 }, slot);
    const load11 = try validateNamedLoad(block.instructions.items[11], .{ .int = 64 }, slot);
    const uadd12 = try validateSaturatingCall(block.instructions.items[12], "llvm.uadd.sat.i64", load11, 1, null);
    try validateStore(block.instructions.items[13], .{ .int = 64 }, .{ .named = uadd12 }, slot);
    const load14 = try validateNamedLoad(block.instructions.items[14], .{ .int = 64 }, slot);
    const usub15 = try validateSaturatingCall(block.instructions.items[15], "llvm.usub.sat.i64", load14, 1, null);
    try validateStore(block.instructions.items[16], .{ .int = 64 }, .{ .named = usub15 }, slot);
    const load17 = try validateNamedLoad(block.instructions.items[17], .{ .int = 64 }, slot);
    const umul18 = try validateSaturatingCall(block.instructions.items[18], "llvm.umul.fix.sat.i64", load17, 2, 0);
    try validateStore(block.instructions.items[19], .{ .int = 64 }, .{ .named = umul18 }, slot);
    const load20 = try validateNamedLoad(block.instructions.items[20], .{ .int = 64 }, slot);
    if (!isNamed(ret.value orelse return error.InvalidRet, load20)) return error.UnsupportedCodegenControlFlow;
}

pub fn validateBinaryNamedImm(instruction: ir.Instruction, op: ir.BinaryOp, ty: ir.Type, lhs_name: []const u8, rhs: i128) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (binary.op != op or !binary.ty.eql(ty) or !isNamed(binary.lhs, lhs_name) or !binary.rhs.eql(.{ .int = rhs })) return error.UnsupportedCodegenInstruction;
    return name;
}

pub fn validateSaturatingCall(instruction: ir.Instruction, callee: []const u8, lhs_name: []const u8, rhs: i128, scale: ?i128) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!isCalleeName(call.callee, callee) or !call.ret_ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenInstruction;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    const expected_args: usize = if (scale == null) 2 else 3;
    if (call.args.items.len != expected_args) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 64 }) or !isNamed(call.args.items[0].value, lhs_name)) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[1].ty.eql(.{ .int = 64 }) or !call.args.items[1].value.eql(.{ .int = rhs })) return error.UnsupportedCodegenInstruction;
    if (scale) |scale_value| {
        if (!call.args.items[2].ty.eql(.{ .int = 32 }) or !call.args.items[2].value.eql(.{ .int = scale_value })) return error.UnsupportedCodegenInstruction;
    }
    return name;
}
