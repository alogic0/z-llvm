const shared = @import("core_shared.zig");
const core_cfg_emit = @import("core_cfg_emit.zig");
const core_misc_rows = @import("core_misc_rows.zig");
const core_value_support = @import("core_value_support.zig");
const core_value_emit = @import("core_value_emit.zig");
const core_memory_lowering = @import("core_memory_lowering.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");
const cabi_call_lowering = @import("cabi_call_lowering.zig");
const cabi_aggregate_lowering = @import("cabi_aggregate_lowering.zig");
const cabi_boundary_rows = @import("cabi_boundary_rows.zig");
const core_single_block_misc = @import("core_single_block_misc.zig");
const fp_rows = @import("core_single_block_fp.zig");
const terminal_values = @import("terminal_values.zig");
const pointer_slice_rows = @import("pointer_slice_rows.zig");
const std = shared.std;
const ir = shared.ir;
const MachineFunction = shared.MachineFunction;
const Instruction = shared.x86_64_machine.Instruction;
const ArgReg = shared.ArgReg;
const SysVCallTarget = shared.SysVCallTarget;

const appendDirectCall = shared.appendDirectCall;
const appendGenericCfgBlockLabel = core_cfg_emit.appendGenericCfgBlockLabel;
const appendGenericCfgConditionalBranch = core_cfg_emit.appendGenericCfgConditionalBranch;
const appendGenericCfgReturn = core_cfg_emit.appendGenericCfgReturn;
const appendStackFrame = shared.appendStackFrame;
const appendStackFrameEnd = shared.appendStackFrameEnd;
const appendSysVScalarCallArgsWithBlock = cabi_call_lowering.appendSysVScalarCallArgsWithBlock;
const appendSysVCallTarget = shared.appendSysVCallTarget;
const callIsFastcc = shared.callIsFastcc;
const emitGenericCfgI32CallIntoEax = core_value_emit.emitGenericCfgI32CallIntoEax;
const isUshlSatI32Callee = core_value_emit.isUshlSatI32Callee;
const emitGenericCfgI32ValueIntoEax = core_value_emit.emitGenericCfgI32ValueIntoEax;
const emitGenericCfgI64ValueIntoRax = core_value_emit.emitGenericCfgI64ValueIntoRax;
const emitGenericCfgBoolValueIntoEax = core_value_emit.emitGenericCfgBoolValueIntoEax;
const emitGenericCfgIcmpCondition = cabi_call_lowering.emitGenericCfgIcmpCondition;
const emitGenericCfgStoreEax = core_value_emit.emitGenericCfgStoreEax;
const emitGenericCfgVoidCall = core_value_emit.emitGenericCfgVoidCall;
const findInstruction = cabi_call_lowering.findInstruction;
const genericCfgSupportsSingleBlockScalar = core_value_support.genericCfgSupportsSingleBlockScalar;
const i32Value = shared.i32Value;
const i64Value = shared.i64Value;
const isCalleeName = shared.isCalleeName;
const isInt = shared.isInt;
const isNamed = shared.isNamed;
const paramReg = cabi_abi_helpers.paramReg;
const paramRegOrNull = cabi_abi_helpers.paramRegOrNull;
const setupSysVCallTarget = shared.setupSysVCallTarget;
const sysvScalarCallNeedsStackArgs = cabi_call_lowering.sysvScalarCallNeedsStackArgs;
const validateDefaultCallConv = shared.validateDefaultCallConv;

const lowerAggregateAbiReturn = cabi_boundary_rows.lowerAggregateAbiReturn;
const lowerErrorUnionI64SelectReturn = core_single_block_misc.lowerErrorUnionI64SelectReturn;
const lowerGenericCfgByteTableLookupReturn = core_single_block_misc.lowerGenericCfgByteTableLookupReturn;
const lowerGenericCfgI64DirectCallReturn = cabi_call_lowering.lowerGenericCfgI64DirectCallReturn;
const lowerGenericCfgGprParamReturn = cabi_call_lowering.lowerGenericCfgGprParamReturn;
const lowerGenericCfgI64ParamReturn = cabi_call_lowering.lowerGenericCfgI64ParamReturn;
const lowerGenericCfgDynamicPointerLoadReturn = core_memory_lowering.lowerGenericCfgDynamicPointerLoadReturn;
const lowerGenericCfgStructFieldLoadReturn = core_memory_lowering.lowerGenericCfgStructFieldLoadReturn;
const lowerI64SaturatingHelperFamilyReturn = cabi_boundary_rows.lowerI64SaturatingHelperFamilyReturn;
const lowerIntegerShiftMixReturn = core_misc_rows.lowerIntegerShiftMixReturn;
const lowerMulConstReturn = core_misc_rows.lowerMulConstReturn;
const lowerPointerVolatileRoundtripReturn = cabi_boundary_rows.lowerPointerVolatileRoundtripReturn;
const lowerRuntimeArraySumPreoptHelper = cabi_aggregate_lowering.lowerRuntimeArraySumPreoptHelper;
const lowerRuntimeStructSumPreoptHelper = cabi_aggregate_lowering.lowerRuntimeStructSumPreoptHelper;
const lowerAggregatePairAbiFamilyReturn = cabi_aggregate_lowering.lowerAggregatePairAbiFamilyReturn;
const lowerSliceAggregateInternalAbiReturn = pointer_slice_rows.lowerSliceAggregateInternalAbiReturn;
const lowerScalarFpCastReturn = cabi_boundary_rows.lowerScalarFpCastReturn;
const lowerSelectedI64ConstReturn = cabi_call_lowering.lowerSelectedI64ConstReturn;
const lowerStructSumReturn = cabi_aggregate_lowering.lowerStructSumReturn;
const terminalBlockCanMaterializeI64Value = terminal_values.terminalBlockCanMaterializeI64Value;
const emitGenericCfgTerminalReturnBlock = terminal_values.emitGenericCfgTerminalReturnBlock;
const pointer_rows = @import("core_single_block_pointer_rows.zig");
const lowerGenericCfgGprVoidCallStackParamReturn = pointer_rows.lowerGenericCfgGprVoidCallStackParamReturn;
const lowerGenericCfgPointerSelectLoadReturn = pointer_rows.lowerGenericCfgPointerSelectLoadReturn;

pub fn lowerGenericCfgSingleBlockScalar(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const single_ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => null,
    };
    if (try lowerGenericCfgDynamicPointerLoadReturn(allocator, machine, function, block)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (single_ret) |ret| {
        if (try lowerGenericCfgByteSwapReturn(allocator, machine, function, block, ret)) {
            machine.codegen_path = .generic_cfg;
            return true;
        }
        if (try lowerGenericCfgAbsReturn(allocator, machine, function, block, ret)) {
            machine.codegen_path = .generic_cfg;
            return true;
        }
        if (try lowerGenericCfgClzLadderReturn(allocator, machine, function, block, ret)) {
            machine.codegen_path = .generic_cfg;
            return true;
        }
        if (try lowerGenericCfgClzReturn(allocator, machine, function, block, ret)) {
            machine.codegen_path = .generic_cfg;
            return true;
        }
        if (try lowerGenericCfgCtzReturn(allocator, machine, function, block, ret)) {
            machine.codegen_path = .generic_cfg;
            return true;
        }
        if (try lowerGenericCfgPopcountReturn(allocator, machine, function, block, ret)) {
            machine.codegen_path = .generic_cfg;
            return true;
        }
        if (try lowerGenericCfgBitReverseReturn(allocator, machine, function, block, ret)) {
            machine.codegen_path = .generic_cfg;
            return true;
        }
        if (try lowerGenericCfgUshlSatReturn(allocator, machine, function, block, ret)) {
            machine.codegen_path = .generic_cfg;
            return true;
        }
        if (try lowerGenericCfgShuffleOneU8Return(allocator, machine, function, block, ret)) {
            machine.codegen_path = .generic_cfg;
            return true;
        }
        if (try lowerGenericCfgVectorI32AddReduceReturn(allocator, machine, function, block, ret)) {
            machine.codegen_path = .generic_cfg;
            return true;
        }
        if (try lowerGenericCfgI128NegParamReturn(allocator, machine, function, block, ret)) {
            machine.codegen_path = .generic_cfg;
            return true;
        }
        if (try lowerGenericCfgI64NegParamReturn(allocator, machine, function, block, ret)) {
            machine.codegen_path = .generic_cfg;
            return true;
        }
        if (!ret.ty.eql(.{ .int = 32 }) and try lowerGenericCfgGprParamReturn(allocator, machine, function, block, ret)) {
            machine.codegen_path = .generic_cfg;
            return true;
        }
    }
    if (!function.ret_ty.eql(.{ .int = 32 }) and !function.ret_ty.eql(.{ .int = 1 })) return false;
    if (function.ret_ty.eql(.{ .int = 32 })) {
        if (single_ret) |ret| {
            if (try lowerGenericCfgPointerLoadStoreReturn(allocator, machine, function, block, ret)) {
                machine.codegen_path = .generic_cfg;
                return true;
            }
            if (try lowerPointerVolatileRoundtripReturn(allocator, machine, function, block, ret)) {
                machine.codegen_path = .generic_cfg;
                return true;
            }
        }
        if (try lowerGenericCfgPointerSelectLoadReturn(allocator, machine, function, block)) {
            machine.codegen_path = .generic_cfg;
            return true;
        }
        if (try lowerGenericCfgStructFieldLoadReturn(allocator, machine, function, block)) {
            machine.codegen_path = .generic_cfg;
            return true;
        }
        if (single_ret) |ret| {
            if (lowerStructSumReturn(allocator, machine, function, block, ret) catch false) {
                machine.codegen_path = .generic_cfg;
                return true;
            }
            if (lowerRuntimeStructSumPreoptHelper(allocator, machine, function, block, ret) catch false) {
                machine.codegen_path = .generic_cfg;
                return true;
            }
            if (lowerRuntimeArraySumPreoptHelper(allocator, machine, function, block, ret) catch false) {
                machine.codegen_path = .generic_cfg;
                return true;
            }
            if (try lowerScalarFpCastReturn(allocator, machine, function, block, ret)) {
                machine.codegen_path = .generic_cfg;
                return true;
            }
            if (try lowerGenericCfgByteTableLookupReturn(allocator, machine, function, block, ret)) {
                machine.codegen_path = .generic_cfg;
                return true;
            }
            if (try lowerIntegerShiftMixReturn(allocator, machine, function, block, ret)) {
                machine.codegen_path = .generic_cfg;
                return true;
            }
            if (try lowerMulConstReturn(allocator, machine, function, block, ret)) {
                machine.codegen_path = .generic_cfg;
                return true;
            }
            if (try lowerGenericCfgCallResultAcrossVoidCall(allocator, machine, function, block, ret)) {
                machine.codegen_path = .generic_cfg;
                return true;
            }
            if (try lowerGenericCfgTwoI32CallResultsAcrossVoidCall(allocator, machine, function, block, ret)) {
                machine.codegen_path = .generic_cfg;
                return true;
            }
            if (try lowerGenericCfgI32CallResultAcrossI32Call(allocator, machine, function, block, ret)) {
                machine.codegen_path = .generic_cfg;
                return true;
            }
        }
    }
    if (!genericCfgSupportsSingleBlockScalar(function)) return false;
    const ret = single_ret orelse return error.UnsupportedCodegenControlFlow;
    var last_eax_value: ?ir.Value = null;
    for (block.instructions.items, 0..) |instruction, instruction_index| {
        switch (instruction.kind) {
            .store => |store| {
                try emitGenericCfgI32ValueIntoEax(allocator, machine, function, block, store.value);
                try emitGenericCfgStoreEax(allocator, machine, function, store.ptr);
                last_eax_value = store.value;
            },
            .call => |call| {
                if (call.ret_ty == .void and instruction.result == null) {
                    try emitGenericCfgVoidCall(allocator, machine, function, block, instruction_index, call);
                }
            },
            .binary, .icmp, .select, .load, .cast => {},
            .phi, .fcmp, .freeze, .alloca, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep => return error.UnsupportedCodegenInstruction,
        }
    }
    const ret_value = ret.value orelse return error.InvalidRet;
    if (function.ret_ty.eql(.{ .int = 1 })) {
        try emitGenericCfgBoolValueIntoEax(allocator, machine, function, block, ret_value);
    } else if (last_eax_value == null or !last_eax_value.?.eql(ret_value)) {
        try emitGenericCfgI32ValueIntoEax(allocator, machine, function, block, ret_value);
    }
    try appendGenericCfgReturn(allocator, machine);
    machine.codegen_path = .generic_cfg;
    return true;
}

pub fn lowerGenericCfgSingleBlockByteSwap(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (try lowerGenericCfgByteSwapReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    return false;
}

fn lowerGenericCfgByteSwapReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(function.ret_ty)) return false;
    const bits = switch (ret.ty) {
        .int => |width| width,
        else => return false,
    };
    switch (bits) {
        16, 32, 64 => {},
        else => return false,
    }
    if (block.instructions.items.len != 1) return false;
    const instruction = block.instructions.items[0];
    if (instruction.removed) return false;
    const result_name = instruction.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, result_name, ret_name)) return false;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isCalleeName(call.callee, byteSwapIntrinsicName(bits))) return false;
    if (call.callee_value != null or call.inline_asm != null or call.args.items.len != 1) return false;
    if (!call.ret_ty.eql(ret.ty) or !call.args.items[0].ty.eql(ret.ty)) return false;
    const operand_value = call.args.items[0].value;

    switch (bits) {
        16 => {
            try emitByteSwapOperandIntoEax(allocator, machine, function, operand_value, ret.ty);
            try machine.instructions.append(allocator, .{ .rol_ax_imm8 = 8 });
            try machine.instructions.append(allocator, .{ .and_eax_imm32 = 0xffff });
        },
        32 => {
            try emitByteSwapOperandIntoEax(allocator, machine, function, operand_value, ret.ty);
            try machine.instructions.append(allocator, .bswap_eax);
        },
        64 => {
            try emitByteSwapOperandIntoRax(allocator, machine, function, operand_value, ret.ty);
            try machine.instructions.append(allocator, .bswap_rax);
        },
        else => unreachable,
    }
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

fn lowerGenericCfgShuffleOneU8Return(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 8 }) or !ret.ty.eql(function.ret_ty)) return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const extract_inst = findInstruction(block, ret_name) orelse return false;
    const extract_name = extract_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, extract_name)) return false;
    const extract = switch (extract_inst.kind) {
        .extractelement => |extract| extract,
        else => return false,
    };
    if (!extract.vector_ty.eql(.{ .vector = .{ .len = 4, .elem_ty = .{ .int = 8 } } })) return false;
    if (!extract.index_ty.eql(.{ .int = 64 }) or extract.index != .int) return false;
    if (extract.index.int < 0 or extract.index.int > 3) return false;
    const shuffle_name = switch (extract.vector) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const shuffle_inst = findInstruction(block, shuffle_name) orelse return false;
    const shuffle = switch (shuffle_inst.kind) {
        .shufflevector => |shuffle| shuffle,
        else => return false,
    };
    if (!shuffle.lhs_ty.eql(.{ .vector = .{ .len = 4, .elem_ty = .{ .int = 8 } } })) return false;
    if (!shuffle.rhs_ty.eql(shuffle.lhs_ty)) return false;
    if (shuffle.rhs != .poison and shuffle.rhs != .undef) return false;
    if (!shuffle.mask_ty.eql(.{ .vector = .{ .len = 4, .elem_ty = .{ .int = 32 } } })) return false;
    const selected_lane = shuffleMaskLane(shuffle.mask, @intCast(extract.index.int)) orelse return false;
    if (selected_lane < 0 or selected_lane > 3) return false;
    const selected_value = vectorInsertedLaneValue(block, shuffle.lhs, @intCast(selected_lane)) orelse return false;
    const selected_name = switch (selected_value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const reg = try paramReg(function, selected_name, .{ .int = 8 });
    try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 0xff });
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

fn vectorInsertedLaneValue(block: ir.BasicBlock, vector: ir.Value, lane: u32) ?ir.Value {
    const vector_name = switch (vector) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const instruction = findInstruction(block, vector_name) orelse return null;
    const insert = switch (instruction.kind) {
        .insertelement => |insert| insert,
        else => return null,
    };
    if (!insert.vector_ty.eql(.{ .vector = .{ .len = 4, .elem_ty = .{ .int = 8 } } })) return null;
    if (!insert.value_ty.eql(.{ .int = 8 })) return null;
    if (!insert.index_ty.eql(.{ .int = 64 }) or insert.index != .int) return null;
    if (insert.index.int == lane) return insert.value;
    return vectorInsertedLaneValue(block, insert.vector, lane);
}

fn shuffleMaskLane(mask: ir.Value, lane: usize) ?i128 {
    const text = switch (mask) {
        .vector => |text| text,
        .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .constant_expr => return null,
    };
    const inner = std.mem.trim(u8, text, " \t\r\n<>");
    var parts = std.mem.splitScalar(u8, inner, ',');
    var index: usize = 0;
    while (parts.next()) |raw_part| : (index += 1) {
        if (index != lane) continue;
        const part = std.mem.trim(u8, raw_part, " \t\r\n");
        if (!std.mem.startsWith(u8, part, "i32 ")) return null;
        return std.fmt.parseInt(i128, std.mem.trim(u8, part["i32 ".len..], " \t\r\n"), 10) catch null;
    }
    return null;
}

fn lowerGenericCfgVectorI32AddReduceReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or !ret.ty.eql(function.ret_ty)) return false;
    var regs: [8]ArgReg = undefined;
    var count: usize = 0;
    if (!collectVectorI32AddReduceParamRegs(function, block, ret.value orelse return error.InvalidRet, &regs, &count)) return false;
    if (count < 2) return false;
    try machine.instructions.append(allocator, .{ .mov_arg_eax = regs[0] });
    for (regs[1..count]) |reg| {
        try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = reg } });
    }
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

fn lowerGenericCfgI128NegParamReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 128 }) or !ret.ty.eql(function.ret_ty)) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 128 })) return false;
    if (block.instructions.items.len != 1) return false;
    const instruction = block.instructions.items[0];
    if (instruction.removed) return false;
    const result_name = instruction.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, result_name)) return false;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (binary.op != .sub or !binary.ty.eql(function.ret_ty)) return false;
    if (!isInt(binary.lhs, 0) or !isNamed(binary.rhs, function.params.items[0].name)) return false;

    try machine.instructions.append(allocator, .neg_i128_rdi_rsi_rdx_rax);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

fn lowerGenericCfgI64NegParamReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 64 }) or !ret.ty.eql(function.ret_ty)) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 64 })) return false;
    if (block.instructions.items.len != 1) return false;
    const instruction = block.instructions.items[0];
    if (instruction.removed) return false;
    const result_name = instruction.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, result_name)) return false;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (binary.op != .sub or !binary.ty.eql(function.ret_ty)) return false;
    if (!isInt(binary.lhs, 0) or !isNamed(binary.rhs, function.params.items[0].name)) return false;

    try machine.instructions.append(allocator, .{ .mov_arg_rax = try paramReg(function, function.params.items[0].name, .{ .int = 64 }) });
    try machine.instructions.append(allocator, .neg_rax);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

fn collectVectorI32AddReduceParamRegs(
    function: ir.Function,
    block: ir.BasicBlock,
    value: ir.Value,
    regs: *[8]ArgReg,
    count: *usize,
) bool {
    if (count.* >= regs.len) return false;
    const value_name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const instruction = findInstruction(block, value_name) orelse return false;
    switch (instruction.kind) {
        .binary => |binary| {
            if (binary.op != .add or !binary.ty.eql(.{ .int = 32 })) return false;
            return collectVectorI32AddReduceParamRegs(function, block, binary.lhs, regs, count) and
                collectVectorI32AddReduceParamRegs(function, block, binary.rhs, regs, count);
        },
        .extractelement => |extract| {
            if (!extract.vector_ty.eql(.{ .vector = .{ .len = 4, .elem_ty = .{ .int = 32 } } })) return false;
            if (!extract.index_ty.eql(.{ .int = 64 }) or extract.index != .int) return false;
            if (extract.index.int < 0 or extract.index.int > 3) return false;
            const selected_value = vectorInsertedLaneI32Value(block, extract.vector, @intCast(extract.index.int)) orelse return false;
            const selected_name = switch (selected_value) {
                .named => |name| name,
                .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
            };
            regs[count.*] = paramReg(function, selected_name, .{ .int = 32 }) catch return false;
            count.* += 1;
            return true;
        },
        else => return false,
    }
}

fn vectorInsertedLaneI32Value(block: ir.BasicBlock, vector: ir.Value, lane: u32) ?ir.Value {
    const vector_name = switch (vector) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const instruction = findInstruction(block, vector_name) orelse return null;
    const insert = switch (instruction.kind) {
        .insertelement => |insert| insert,
        else => return null,
    };
    if (!insert.vector_ty.eql(.{ .vector = .{ .len = 4, .elem_ty = .{ .int = 32 } } })) return null;
    if (!insert.value_ty.eql(.{ .int = 32 })) return null;
    if (!insert.index_ty.eql(.{ .int = 64 }) or insert.index != .int) return null;
    if (insert.index.int == lane) return insert.value;
    return vectorInsertedLaneI32Value(block, insert.vector, lane);
}

fn lowerGenericCfgAbsReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(function.ret_ty) or !ret.ty.eql(.{ .int = 64 })) return false;
    if (block.instructions.items.len != 3) return false;
    const cmp_inst = block.instructions.items[0];
    const neg_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (cmp_inst.removed or neg_inst.removed or select_inst.removed) return false;
    const cmp_name = cmp_inst.result orelse return false;
    const neg_name = neg_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, select_name, ret_name)) return false;
    const cmp = switch (cmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (cmp.predicate != .slt or !cmp.operand_ty.eql(.{ .int = 64 }) or !isInt(cmp.rhs, 0)) return false;
    const source_name = switch (cmp.lhs) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if ((try paramReg(function, source_name, .{ .int = 64 })) != .rdi) return error.UnsupportedCodegenAbi;
    const neg = switch (neg_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (neg.op != .sub or !neg.ty.eql(.{ .int = 64 }) or !isInt(neg.lhs, 0) or !isNamed(neg.rhs, source_name)) return false;
    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 64 }) or !isNamed(select.cond, cmp_name)) return false;
    if (!isNamed(select.true_value, neg_name) or !isNamed(select.false_value, source_name)) return false;
    try machine.instructions.append(allocator, .abs_i64_rdi_rax);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

fn lowerGenericCfgClzReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    return lowerGenericCfgZeroCountReturn(allocator, machine, function, block, ret, "llvm.ctlz.i32", .clz_i32_edi_eax);
}

fn lowerGenericCfgClzLadderReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or !ret.ty.eql(function.ret_ty)) return false;
    if (function.params.items.len != 1) return false;
    const bits: u16 = switch (function.params.items[0].ty) {
        .int => |int_bits| int_bits,
        else => return false,
    };
    if (bits != 32 and bits != 64 and bits != 128) return false;
    const stage_count: usize = switch (bits) {
        32 => 3,
        64 => 4,
        128 => 5,
        else => unreachable,
    };
    const expected_instruction_count = 4 + stage_count * 5 + 6 + if (bits == 32) @as(usize, 0) else 5;
    if (block.instructions.items.len != expected_instruction_count) return false;
    for (block.instructions.items) |instruction| {
        if (instruction.removed) return false;
    }

    const param_name = function.params.items[0].name;
    var cursor: usize = 0;
    const half_bits: i128 = @divExact(@as(i128, bits), 2);

    const high_half_name = try validateIntLshrNamedImm(block.instructions.items[cursor], bits, param_name, half_bits);
    cursor += 1;
    const high_half_is_zero = try validateIntIcmpNamedImm(block.instructions.items[cursor], bits, .eq, high_half_name, 0);
    cursor += 1;
    var count_name = try validateIntSelect(block.instructions.items[cursor], bits, high_half_is_zero, .{ .int = bits }, .{ .int = half_bits });
    cursor += 1;
    var value_name = try validateIntSelect(block.instructions.items[cursor], bits, high_half_is_zero, .{ .named = param_name }, .{ .named = high_half_name });
    cursor += 1;

    var shift: i128 = @divExact(half_bits, 2);
    while (shift >= 2) : (shift = @divExact(shift, 2)) {
        const shifted_name = try validateIntLshrNamedImm(block.instructions.items[cursor], bits, value_name, shift);
        cursor += 1;
        const shifted_is_zero = try validateIntIcmpNamedImm(block.instructions.items[cursor], bits, .eq, shifted_name, 0);
        cursor += 1;
        const decremented_count = try validateIntAddNamedImm(block.instructions.items[cursor], bits, count_name, -shift);
        cursor += 1;
        count_name = try validateIntSelect(block.instructions.items[cursor], bits, shifted_is_zero, .{ .named = count_name }, .{ .named = decremented_count });
        cursor += 1;
        value_name = try validateIntSelect(block.instructions.items[cursor], bits, shifted_is_zero, .{ .named = value_name }, .{ .named = shifted_name });
        cursor += 1;
    }

    const shifted_one_name = try validateIntLshrNamedImm(block.instructions.items[cursor], bits, value_name, 1);
    cursor += 1;
    const shifted_one_nonzero = try validateIntIcmpNamedImm(block.instructions.items[cursor], bits, .ne, shifted_one_name, 0);
    cursor += 1;
    const nonzero_value = try validateI1SextToInt(block.instructions.items[cursor], bits, shifted_one_nonzero);
    cursor += 1;
    const incremented_count = try validateIntAddNamed(block.instructions.items[cursor], bits, count_name, nonzero_value);
    cursor += 1;
    const final_value = try validateIntSelect(block.instructions.items[cursor], bits, shifted_one_nonzero, .{ .named = shifted_one_name }, .{ .named = value_name });
    cursor += 1;
    const wide_result_name = try validateIntSubNamed(block.instructions.items[cursor], bits, incremented_count, final_value);
    cursor += 1;
    const result_name = if (bits == 32) wide_result_name else result: {
        const gt_i32_min = try validateIntIcmpNamedImm(block.instructions.items[cursor], bits, .sgt, wide_result_name, -2147483649);
        cursor += 1;
        try validateAssumeNamed(block.instructions.items[cursor], gt_i32_min);
        cursor += 1;
        const lt_i32_max_plus_one = try validateIntIcmpNamedImm(block.instructions.items[cursor], bits, .slt, wide_result_name, 2147483648);
        cursor += 1;
        try validateAssumeNamed(block.instructions.items[cursor], lt_i32_max_plus_one);
        cursor += 1;
        const truncated_name = try validateIntTruncToI32(block.instructions.items[cursor], bits, wide_result_name);
        cursor += 1;
        break :result truncated_name;
    };
    if (cursor != block.instructions.items.len) return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, result_name)) return false;
    if (bits != 128 and (try paramReg(function, param_name, .{ .int = bits })) != .rdi) return error.UnsupportedCodegenAbi;

    const machine_instruction: Instruction = switch (bits) {
        32 => .clz_i32_edi_eax,
        64 => .clz_i64_rdi_eax,
        128 => .clz_i128_rdi_rsi_eax,
        else => unreachable,
    };
    try machine.instructions.append(allocator, machine_instruction);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

fn validateIntLshrNamedImm(instruction: ir.Instruction, bits: u16, lhs_name: []const u8, rhs_value: i128) ![]const u8 {
    const result_name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (binary.op != .lshr or !binary.ty.eql(.{ .int = bits }) or !isNamed(binary.lhs, lhs_name) or !isInt(binary.rhs, rhs_value)) return error.UnsupportedCodegenInstruction;
    return result_name;
}

fn validateIntAddNamedImm(instruction: ir.Instruction, bits: u16, lhs_name: []const u8, rhs_value: i128) ![]const u8 {
    const result_name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (binary.op != .add or !binary.ty.eql(.{ .int = bits }) or !isNamed(binary.lhs, lhs_name) or !isInt(binary.rhs, rhs_value)) return error.UnsupportedCodegenInstruction;
    return result_name;
}

fn validateIntAddNamed(instruction: ir.Instruction, bits: u16, lhs_name: []const u8, rhs_name: []const u8) ![]const u8 {
    const result_name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (binary.op != .add or !binary.ty.eql(.{ .int = bits }) or !isNamed(binary.lhs, lhs_name) or !isNamed(binary.rhs, rhs_name)) return error.UnsupportedCodegenInstruction;
    return result_name;
}

fn validateIntSubNamed(instruction: ir.Instruction, bits: u16, lhs_name: []const u8, rhs_name: []const u8) ![]const u8 {
    const result_name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (binary.op != .sub or !binary.ty.eql(.{ .int = bits }) or !isNamed(binary.lhs, lhs_name) or !isNamed(binary.rhs, rhs_name)) return error.UnsupportedCodegenInstruction;
    return result_name;
}

fn validateIntIcmpNamedImm(instruction: ir.Instruction, bits: u16, predicate: ir.IcmpPredicate, lhs_name: []const u8, rhs_value: i128) ![]const u8 {
    const result_name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (icmp.predicate != predicate or !icmp.operand_ty.eql(.{ .int = bits }) or !isNamed(icmp.lhs, lhs_name) or !isInt(icmp.rhs, rhs_value)) return error.UnsupportedCodegenInstruction;
    return result_name;
}

fn validateIntSelect(instruction: ir.Instruction, bits: u16, cond_name: []const u8, true_value: ir.Value, false_value: ir.Value) ![]const u8 {
    const result_name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const select = switch (instruction.kind) {
        .select => |select| select,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = bits }) or !isNamed(select.cond, cond_name) or !select.true_value.eql(true_value) or !select.false_value.eql(false_value)) return error.UnsupportedCodegenInstruction;
    return result_name;
}

fn validateI1SextToInt(instruction: ir.Instruction, bits: u16, value_name: []const u8) ![]const u8 {
    const result_name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const cast = switch (instruction.kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (cast.op != .sext or !cast.from_ty.eql(.{ .int = 1 }) or !cast.to_ty.eql(.{ .int = bits }) or !isNamed(cast.value, value_name)) return error.UnsupportedCodegenInstruction;
    return result_name;
}

fn validateIntTruncToI32(instruction: ir.Instruction, bits: u16, value_name: []const u8) ![]const u8 {
    const result_name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const cast = switch (instruction.kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (cast.op != .trunc or !cast.from_ty.eql(.{ .int = bits }) or !cast.to_ty.eql(.{ .int = 32 }) or !isNamed(cast.value, value_name)) return error.UnsupportedCodegenInstruction;
    return result_name;
}

fn validateAssumeNamed(instruction: ir.Instruction, value_name: []const u8) !void {
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!isCalleeName(call.callee, "llvm.assume") or call.ret_ty != .void or call.callee_value != null or call.inline_asm != null or call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 1 }) or !isNamed(call.args.items[0].value, value_name)) return error.UnsupportedCodegenInstruction;
}

fn validateI32LshrNamedImm(instruction: ir.Instruction, lhs_name: []const u8, rhs_value: i128) ![]const u8 {
    const result_name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (binary.op != .lshr or !binary.ty.eql(.{ .int = 32 }) or !isNamed(binary.lhs, lhs_name) or !isInt(binary.rhs, rhs_value)) return error.UnsupportedCodegenInstruction;
    return result_name;
}

fn validateI32AddNamedImm(instruction: ir.Instruction, lhs_name: []const u8, rhs_value: i128) ![]const u8 {
    const result_name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (binary.op != .add or !binary.ty.eql(.{ .int = 32 }) or !isNamed(binary.lhs, lhs_name) or !isInt(binary.rhs, rhs_value)) return error.UnsupportedCodegenInstruction;
    return result_name;
}

fn validateI32AddNamed(instruction: ir.Instruction, lhs_name: []const u8, rhs_name: []const u8) ![]const u8 {
    const result_name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (binary.op != .add or !binary.ty.eql(.{ .int = 32 }) or !isNamed(binary.lhs, lhs_name) or !isNamed(binary.rhs, rhs_name)) return error.UnsupportedCodegenInstruction;
    return result_name;
}

fn validateI32SubNamed(instruction: ir.Instruction, lhs_name: []const u8, rhs_name: []const u8) ![]const u8 {
    const result_name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (binary.op != .sub or !binary.ty.eql(.{ .int = 32 }) or !isNamed(binary.lhs, lhs_name) or !isNamed(binary.rhs, rhs_name)) return error.UnsupportedCodegenInstruction;
    return result_name;
}

fn validateI32IcmpNamedImm(instruction: ir.Instruction, predicate: ir.IcmpPredicate, lhs_name: []const u8, rhs_value: i128) ![]const u8 {
    const result_name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (icmp.predicate != predicate or !icmp.operand_ty.eql(.{ .int = 32 }) or !isNamed(icmp.lhs, lhs_name) or !isInt(icmp.rhs, rhs_value)) return error.UnsupportedCodegenInstruction;
    return result_name;
}

fn validateI32Select(instruction: ir.Instruction, cond_name: []const u8, true_value: ir.Value, false_value: ir.Value) ![]const u8 {
    const result_name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const select = switch (instruction.kind) {
        .select => |select| select,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 }) or !isNamed(select.cond, cond_name) or !select.true_value.eql(true_value) or !select.false_value.eql(false_value)) return error.UnsupportedCodegenInstruction;
    return result_name;
}

fn validateI1SextToI32(instruction: ir.Instruction, value_name: []const u8) ![]const u8 {
    const result_name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const cast = switch (instruction.kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (cast.op != .sext or !cast.from_ty.eql(.{ .int = 1 }) or !cast.to_ty.eql(.{ .int = 32 }) or !isNamed(cast.value, value_name)) return error.UnsupportedCodegenInstruction;
    return result_name;
}

fn lowerGenericCfgCtzReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    return lowerGenericCfgZeroCountReturn(allocator, machine, function, block, ret, "llvm.cttz.i32", .ctz_i32_edi_eax);
}

fn lowerGenericCfgPopcountReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(function.ret_ty)) return false;
    if (!ret.ty.eql(.{ .int = 32 }) and !ret.ty.eql(.{ .int = 64 })) return false;
    if (function.params.items.len != 1) return false;
    const arg0 = function.params.items[0];

    var maybe_call: ?ir.CallInst = null;
    var maybe_call_result: ?[]const u8 = null;
    var maybe_zext_pre: ?ir.CastInst = null;
    var maybe_zext_pre_result: ?[]const u8 = null;
    var maybe_trunc: ?ir.CastInst = null;
    var maybe_trunc_result: ?[]const u8 = null;
    var maybe_zext_post: ?ir.CastInst = null;
    var maybe_zext_post_result: ?[]const u8 = null;

    for (block.instructions.items) |inst| {
        if (inst.removed) continue;
        switch (inst.kind) {
            .call => |call| {
                if (maybe_call != null) return false;
                maybe_call = call;
                maybe_call_result = inst.result orelse return false;
            },
            .cast => |cast| switch (cast.op) {
                .zext => {
                    if (maybe_call == null) {
                        if (maybe_zext_pre != null) return false;
                        maybe_zext_pre = cast;
                        maybe_zext_pre_result = inst.result orelse return false;
                    } else {
                        if (maybe_zext_post != null) return false;
                        maybe_zext_post = cast;
                        maybe_zext_post_result = inst.result orelse return false;
                    }
                },
                .trunc => {
                    if (maybe_call == null or maybe_trunc != null) return false;
                    maybe_trunc = cast;
                    maybe_trunc_result = inst.result orelse return false;
                },
                else => return false,
            },
            else => return false,
        }
    }

    const call = maybe_call orelse return false;
    const call_result = maybe_call_result orelse return false;
    const is_ctpop_i32 = isCalleeName(call.callee, "llvm.ctpop.i32");
    const is_ctpop_i64 = isCalleeName(call.callee, "llvm.ctpop.i64");
    if (!is_ctpop_i32 and !is_ctpop_i64) return false;
    if (call.callee_value != null or call.inline_asm != null or call.args.items.len != 1) return false;

    const expected_call_ty: ir.Type = if (is_ctpop_i32) .{ .int = 32 } else .{ .int = 64 };
    if (!call.ret_ty.eql(expected_call_ty) or !call.args.items[0].ty.eql(expected_call_ty)) return false;

    // Verify input chain
    if (maybe_zext_pre) |zext_pre| {
        const zext_pre_res = maybe_zext_pre_result orelse return false;
        if (!isNamed(zext_pre.value, arg0.name)) return false;
        if (!isNamed(call.args.items[0].value, zext_pre_res)) return false;
        if (!zext_pre.to_ty.eql(expected_call_ty)) return false;
    } else {
        if (!isNamed(call.args.items[0].value, arg0.name)) return false;
    }

    // Verify return chain
    const ret_val = ret.value orelse return error.InvalidRet;
    const ret_name = switch (ret_val) {
        .named => |name| name,
        else => return false,
    };

    if (maybe_trunc) |trunc| {
        const trunc_res = maybe_trunc_result orelse return false;
        if (!isNamed(trunc.value, call_result)) return false;
        if (!trunc.from_ty.eql(expected_call_ty)) return false;

        const zext_post = maybe_zext_post orelse return false;
        const zext_post_res = maybe_zext_post_result orelse return false;
        if (!isNamed(zext_post.value, trunc_res)) return false;
        if (!zext_post.from_ty.eql(trunc.to_ty)) return false;
        if (!zext_post.to_ty.eql(ret.ty)) return false;
        if (!std.mem.eql(u8, zext_post_res, ret_name)) return false;
    } else if (maybe_zext_post) |zext_post| {
        const zext_post_res = maybe_zext_post_result orelse return false;
        if (!isNamed(zext_post.value, call_result)) return false;
        if (!zext_post.from_ty.eql(expected_call_ty)) return false;
        if (!zext_post.to_ty.eql(ret.ty)) return false;
        if (!std.mem.eql(u8, zext_post_res, ret_name)) return false;
    } else {
        if (!std.mem.eql(u8, call_result, ret_name)) return false;
    }

    if (is_ctpop_i32) {
        if ((try paramReg(function, arg0.name, arg0.ty)) != .rdi) return error.UnsupportedCodegenAbi;
        try machine.instructions.append(allocator, .popcount_i32_edi_eax);
    } else {
        if ((try paramReg(function, arg0.name, arg0.ty)) != .rdi) return error.UnsupportedCodegenAbi;
        try machine.instructions.append(allocator, .{ .mov_arg_rax = .rdi });
        try machine.instructions.append(allocator, .popcount_rax);
    }
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

fn lowerGenericCfgBitReverseReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    return lowerGenericCfgBitCountReturn(allocator, machine, function, block, ret, "llvm.bitreverse.i32", .bit_reverse_i32_edi_eax, false);
}

fn lowerGenericCfgUshlSatReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(function.ret_ty) or !ret.ty.eql(.{ .int = 32 })) return false;
    var maybe_call_inst: ?ir.Instruction = null;
    for (block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        switch (instruction.kind) {
            .call => {
                if (maybe_call_inst != null) return false;
                maybe_call_inst = instruction;
            },
            else => return false,
        }
    }
    const call_inst = maybe_call_inst orelse return false;
    const call_result_name = call_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, call_result_name, ret_name)) return false;
    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isUshlSatI32Callee(call.callee)) return false;
    if (call.callee_value != null or call.inline_asm != null or !call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 2) return false;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !call.args.items[1].ty.eql(.{ .int = 32 })) return false;
    const source_name = switch (call.args.items[0].value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const amount_i128 = switch (call.args.items[1].value) {
        .int => |value| value,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (amount_i128 < 0 or amount_i128 > 31) return false;
    if ((try paramReg(function, source_name, .{ .int = 32 })) != .rdi) return error.UnsupportedCodegenAbi;
    try machine.instructions.append(allocator, .{ .ushl_sat_i32_edi_imm_eax = @intCast(amount_i128) });
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

fn lowerGenericCfgZeroCountReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
    callee_name: []const u8,
    machine_instruction: Instruction,
) !bool {
    return lowerGenericCfgBitCountReturn(allocator, machine, function, block, ret, callee_name, machine_instruction, true);
}

fn lowerGenericCfgBitCountReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
    callee_name: []const u8,
    machine_instruction: Instruction,
    has_zero_is_poison_arg: bool,
) !bool {
    if (!ret.ty.eql(function.ret_ty) or !ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 1 and block.instructions.items.len != 3) return false;
    const call_inst = block.instructions.items[0];
    if (call_inst.removed) return false;
    const call_result_name = call_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (block.instructions.items.len == 1) {
        if (!std.mem.eql(u8, call_result_name, ret_name)) return false;
    } else {
        const trunc_inst = block.instructions.items[1];
        const zext_inst = block.instructions.items[2];
        if (trunc_inst.removed or zext_inst.removed) return false;
        const trunc_name = trunc_inst.result orelse return false;
        const zext_name = zext_inst.result orelse return false;
        if (!std.mem.eql(u8, zext_name, ret_name)) return false;
        const trunc = switch (trunc_inst.kind) {
            .cast => |cast| cast,
            else => return false,
        };
        if (trunc.op != .trunc or !trunc.from_ty.eql(.{ .int = 32 }) or !trunc.to_ty.eql(.{ .int = 6 }) or !isNamed(trunc.value, call_result_name)) return false;
        const zext = switch (zext_inst.kind) {
            .cast => |cast| cast,
            else => return false,
        };
        if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 6 }) or !zext.to_ty.eql(.{ .int = 32 }) or !isNamed(zext.value, trunc_name)) return false;
    }
    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isCalleeName(call.callee, callee_name)) return false;
    const expected_arg_count: usize = if (has_zero_is_poison_arg) 2 else 1;
    if (call.callee_value != null or call.inline_asm != null or call.args.items.len != expected_arg_count) return false;
    if (!call.ret_ty.eql(.{ .int = 32 })) return false;
    if (!call.args.items[0].ty.eql(.{ .int = 32 })) return false;
    if (has_zero_is_poison_arg) {
        if (!call.args.items[1].ty.eql(.{ .int = 1 })) return false;
        if (!isInt(call.args.items[1].value, 0)) return false;
    }
    const source_name = switch (call.args.items[0].value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if ((try paramReg(function, source_name, .{ .int = 32 })) != .rdi) return error.UnsupportedCodegenAbi;
    try machine.instructions.append(allocator, machine_instruction);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

fn byteSwapIntrinsicName(bits: u16) []const u8 {
    return switch (bits) {
        16 => "llvm.bswap.i16",
        32 => "llvm.bswap.i32",
        64 => "llvm.bswap.i64",
        else => unreachable,
    };
}

fn emitByteSwapOperandIntoEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    value: ir.Value,
    ty: ir.Type,
) !void {
    switch (value) {
        .int => |int| try machine.instructions.append(allocator, .{ .mov_imm_eax = try i32Value(int) }),
        .named => |name| try machine.instructions.append(allocator, .{ .mov_arg_eax = try paramReg(function, name, ty) }),
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

fn emitByteSwapOperandIntoRax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    value: ir.Value,
    ty: ir.Type,
) !void {
    switch (value) {
        .int => |int| try machine.instructions.append(allocator, .{ .mov_imm_rax = try i64Value(int) }),
        .named => |name| try machine.instructions.append(allocator, .{ .mov_arg_rax = try paramReg(function, name, ty) }),
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn lowerGenericCfgSingleBlockPointerLoadStore(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (try lowerGenericCfgPointerLoadStoreReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    return false;
}

fn lowerGenericCfgPointerLoadStoreReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.ptr) or !function.params.items[1].ty.eql(.ptr)) return false;
    const reload_result = block.instructions.items.len == 4;
    if (block.instructions.items.len != 3 and !reload_result) return false;

    const load_inst = block.instructions.items[0];
    const add_inst = block.instructions.items[1];
    const store_inst = block.instructions.items[2];
    const reload_inst = if (reload_result) block.instructions.items[3] else null;
    if (load_inst.removed or add_inst.removed or store_inst.removed) return false;
    if (reload_inst) |instruction| if (instruction.removed) return false;

    const load_result = load_inst.result orelse return false;
    const add_result = add_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!reload_result and !std.mem.eql(u8, ret_name, add_result)) return false;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
    if (!isNamed(load.ptr, function.params.items[0].name)) return false;

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 })) return false;
    const add_imm = if (isNamed(add.lhs, load_result)) switch (add.rhs) {
        .int => |int| try i32Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    } else if (isNamed(add.rhs, load_result)) switch (add.lhs) {
        .int => |int| try i32Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    } else return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 32 }) or store.attrs.isBarrier()) return false;
    if (!isNamed(store.ptr, function.params.items[1].name) or !isNamed(store.value, add_result)) return false;

    const src_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const dst_reg = try paramReg(function, function.params.items[1].name, .ptr);
    try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = src_reg });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = add_imm });
    try machine.instructions.append(allocator, .{ .store_eax_arg_ptr = dst_reg });
    if (reload_inst) |instruction| {
        const reload_name = instruction.result orelse return false;
        if (!std.mem.eql(u8, ret_name, reload_name)) return false;
        const reload = switch (instruction.kind) {
            .load => |load_value| load_value,
            else => return false,
        };
        if (!reload.ty.eql(.{ .int = 32 }) or reload.attrs.isBarrier()) return false;
        if (!isNamed(reload.ptr, function.params.items[1].name)) return false;
        try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = dst_reg });
    }
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

fn lowerGenericCfgCallResultAcrossVoidCall(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 }) or block.instructions.items.len != 3) return false;
    const first_call_inst = block.instructions.items[0];
    const second_call_inst = block.instructions.items[1];
    const add_inst = block.instructions.items[2];
    if (first_call_inst.removed or second_call_inst.removed or add_inst.removed) return false;
    const first_result = first_call_inst.result orelse return false;
    const add_result = add_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, add_result)) return false;

    const first_call = switch (first_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!first_call.ret_ty.eql(.{ .int = 32 }) or first_call.callee_value != null or first_call.inline_asm != null) return false;
    if (!callIsFastcc(first_call.calling_conv)) try validateDefaultCallConv(first_call.calling_conv);
    if (sysvScalarCallNeedsStackArgs(first_call)) return false;

    const second_call = switch (second_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (second_call.ret_ty != .void or second_call.args.items.len != 0 or second_call.callee_value != null or second_call.inline_asm != null) return false;
    if (!callIsFastcc(second_call.calling_conv)) try validateDefaultCallConv(second_call.calling_conv);

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (!add.ty.eql(.{ .int = 32 }) or add.op != .add) return false;
    const other_value = if (isNamed(add.lhs, first_result))
        add.rhs
    else if (isNamed(add.rhs, first_result))
        add.lhs
    else
        return false;

    try emitGenericCfgI32CallIntoEax(allocator, machine, function, block, 0, first_call);
    const other_param_reg = switch (other_value) {
        .named => |name| try paramRegOrNull(function, name, .{ .int = 32 }),
        .int => null,
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    const frame_bytes: u8 = if (other_param_reg != null) 24 else 8;
    try appendStackFrame(allocator, machine, frame_bytes);
    try machine.instructions.append(allocator, .{ .spill_eax_rsp = .slot0 });
    if (other_param_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{ .frame_index = .slot1, .reg = reg } });
    }
    try appendDirectCall(allocator, machine, second_call.callee, .void);
    try machine.instructions.append(allocator, .{ .reload_rsp_eax = .slot0 });
    switch (other_value) {
        .int => |int| try machine.instructions.append(allocator, .{ .add_eax_imm32 = try i32Value(int) }),
        .named => {
            if (other_param_reg == null) return error.UnsupportedCodegenValue;
            try machine.instructions.append(allocator, .{ .add_stack_disp8_eax = 4 });
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => unreachable,
    }
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

fn lowerGenericCfgI32CallResultAcrossI32Call(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 }) or block.instructions.items.len != 4) return false;
    const first_call_inst = block.instructions.items[0];
    const second_call_inst = block.instructions.items[1];
    const first_add_inst = block.instructions.items[2];
    const second_add_inst = block.instructions.items[3];
    if (first_call_inst.removed or second_call_inst.removed or first_add_inst.removed or second_add_inst.removed) return false;
    const first_result = first_call_inst.result orelse return false;
    const second_result = second_call_inst.result orelse return false;
    const first_add_result = first_add_inst.result orelse return false;
    const second_add_result = second_add_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, second_add_result)) return false;

    const first_call = switch (first_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!first_call.ret_ty.eql(.{ .int = 32 }) or first_call.inline_asm != null) return false;
    if (!callIsFastcc(first_call.calling_conv)) try validateDefaultCallConv(first_call.calling_conv);
    const first_call_target: SysVCallTarget = if (first_call.callee_value) |callee_value| blk: {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        break :blk .{ .indirect_from_reg = try paramReg(function, callee_name, .ptr) };
    } else .{ .direct = first_call.callee };

    const second_call = switch (second_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!second_call.ret_ty.eql(.{ .int = 32 }) or second_call.inline_asm != null) return false;
    if (!callIsFastcc(second_call.calling_conv)) try validateDefaultCallConv(second_call.calling_conv);
    if (sysvScalarCallNeedsStackArgs(second_call)) return false;
    const second_call_target: SysVCallTarget = if (second_call.callee_value) |callee_value| blk: {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        break :blk .{ .indirect_from_reg = try paramReg(function, callee_name, .ptr) };
    } else .{ .direct = second_call.callee };

    const first_add = switch (first_add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    const second_add = switch (second_add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (!first_add.ty.eql(.{ .int = 32 }) or first_add.op != .add) return false;
    if (!second_add.ty.eql(.{ .int = 32 }) or second_add.op != .add) return false;
    if (!valueReferencesAddResult(second_add.lhs, first_add_result) and !valueReferencesAddResult(second_add.rhs, first_add_result)) return false;

    var leaves: [3]ir.Value = undefined;
    var leaf_count: usize = 0;
    try collectTwoAddLeaves(first_add_result, first_add, second_add, &leaves, &leaf_count);
    var has_first = false;
    var has_second = false;
    var extra_value: ?ir.Value = null;
    for (leaves[0..leaf_count]) |leaf| {
        if (isNamed(leaf, first_result)) {
            if (has_first) return false;
            has_first = true;
        } else if (isNamed(leaf, second_result)) {
            if (has_second) return false;
            has_second = true;
        } else if (extra_value == null) {
            extra_value = leaf;
        } else {
            return false;
        }
    }
    if (!has_first or !has_second) return false;

    const extra_param_reg = if (extra_value) |value| switch (value) {
        .named => |name| try paramRegOrNull(function, name, .{ .int = 32 }),
        .int => null,
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    } else null;
    const second_callee_reg: ?shared.ArgReg = switch (second_call_target) {
        .direct => null,
        .indirect_from_reg => |reg| reg,
    };
    const second_arg_live_reg = try secondCallSingleI32ParamArgReg(function, second_call);
    if (extra_value) |value| {
        if (secondCallUsesValue(second_call, value)) return false;
    }
    const frame_bytes: u8 = if (extra_param_reg != null or second_callee_reg != null or second_arg_live_reg != null) 24 else 8;

    try appendStackFrame(allocator, machine, frame_bytes);
    if (extra_param_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{ .frame_index = .slot1, .reg = reg } });
    }
    if (second_callee_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg64_rsp = .{ .frame_index = .slot2, .reg = reg } });
    }
    if (second_arg_live_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{ .frame_index = .slot4, .reg = reg } });
    }
    try setupSysVCallTarget(allocator, machine, first_call_target);
    const first_stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, first_call);
    if (first_stack_arg_count != 0) return error.UnsupportedLiveAcrossCall;
    try appendSysVCallTarget(allocator, machine, first_call_target, first_call.ret_ty);
    try machine.instructions.append(allocator, .{ .spill_eax_rsp = .slot0 });
    if (second_callee_reg) |reg| {
        try machine.instructions.append(allocator, .{ .reload_arg64_rsp = .{ .reg = reg, .frame_index = .slot2 } });
    }
    if (second_arg_live_reg) |reg| {
        try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{ .reg = reg, .frame_index = .slot4 } });
    }
    try setupSysVCallTarget(allocator, machine, second_call_target);
    const stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, second_call);
    if (stack_arg_count != 0) return error.UnsupportedLiveAcrossCall;
    try appendSysVCallTarget(allocator, machine, second_call_target, second_call.ret_ty);
    try machine.instructions.append(allocator, .{ .add_stack_disp8_eax = 0 });
    if (extra_value) |value| switch (value) {
        .int => |int| try machine.instructions.append(allocator, .{ .add_eax_imm32 = try i32Value(int) }),
        .named => {
            if (extra_param_reg == null) return error.UnsupportedCodegenValue;
            try machine.instructions.append(allocator, .{ .add_stack_disp8_eax = 4 });
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => unreachable,
    };
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

fn lowerGenericCfgTwoI32CallResultsAcrossVoidCall(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 }) or block.instructions.items.len != 5) return false;
    const first_call_inst = block.instructions.items[0];
    const second_call_inst = block.instructions.items[1];
    const third_call_inst = block.instructions.items[2];
    const first_add_inst = block.instructions.items[3];
    const second_add_inst = block.instructions.items[4];
    if (first_call_inst.removed or second_call_inst.removed or third_call_inst.removed or first_add_inst.removed or second_add_inst.removed) return false;
    const first_result = first_call_inst.result orelse return false;
    const second_result = second_call_inst.result orelse return false;
    const first_add_result = first_add_inst.result orelse return false;
    const second_add_result = second_add_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, second_add_result)) return false;

    const first_call = switch (first_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!first_call.ret_ty.eql(.{ .int = 32 }) or first_call.inline_asm != null) return false;
    if (!callIsFastcc(first_call.calling_conv)) try validateDefaultCallConv(first_call.calling_conv);
    const first_call_target: SysVCallTarget = if (first_call.callee_value) |callee_value| blk: {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        break :blk .{ .indirect_from_reg = try paramReg(function, callee_name, .ptr) };
    } else .{ .direct = first_call.callee };

    const second_call = switch (second_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!second_call.ret_ty.eql(.{ .int = 32 }) or second_call.inline_asm != null) return false;
    if (!callIsFastcc(second_call.calling_conv)) try validateDefaultCallConv(second_call.calling_conv);
    if (sysvScalarCallNeedsStackArgs(second_call)) return false;
    const second_call_target: SysVCallTarget = if (second_call.callee_value) |callee_value| blk: {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        break :blk .{ .indirect_from_reg = try paramReg(function, callee_name, .ptr) };
    } else .{ .direct = second_call.callee };

    const third_call = switch (third_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (third_call.ret_ty != .void or third_call.args.items.len != 0 or third_call.inline_asm != null) return false;
    if (!callIsFastcc(third_call.calling_conv)) try validateDefaultCallConv(third_call.calling_conv);
    const third_call_target: SysVCallTarget = if (third_call.callee_value) |callee_value| blk: {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        break :blk .{ .indirect_from_reg = try paramReg(function, callee_name, .ptr) };
    } else .{ .direct = third_call.callee };

    const first_add = switch (first_add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    const second_add = switch (second_add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (!first_add.ty.eql(.{ .int = 32 }) or first_add.op != .add) return false;
    if (!second_add.ty.eql(.{ .int = 32 }) or second_add.op != .add) return false;
    if (!valueReferencesAddResult(second_add.lhs, first_add_result) and !valueReferencesAddResult(second_add.rhs, first_add_result)) return false;

    var leaves: [3]ir.Value = undefined;
    var leaf_count: usize = 0;
    try collectTwoAddLeaves(first_add_result, first_add, second_add, &leaves, &leaf_count);
    var has_first = false;
    var has_second = false;
    var extra_value: ?ir.Value = null;
    for (leaves[0..leaf_count]) |leaf| {
        if (isNamed(leaf, first_result)) {
            if (has_first) return false;
            has_first = true;
        } else if (isNamed(leaf, second_result)) {
            if (has_second) return false;
            has_second = true;
        } else if (extra_value == null) {
            extra_value = leaf;
        } else {
            return false;
        }
    }
    if (!has_first or !has_second) return false;

    const extra_param_reg = if (extra_value) |value| switch (value) {
        .named => |name| try paramRegOrNull(function, name, .{ .int = 32 }),
        .int => null,
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    } else null;
    const second_arg_live_reg = try secondCallSingleI32ParamArgReg(function, second_call);
    if (extra_value) |value| {
        if (secondCallUsesValue(second_call, value)) return false;
    }
    const third_callee_reg: ?shared.ArgReg = switch (third_call_target) {
        .direct => null,
        .indirect_from_reg => |reg| reg,
    };
    const second_callee_reg: ?shared.ArgReg = switch (second_call_target) {
        .direct => null,
        .indirect_from_reg => |reg| reg,
    };
    const frame_bytes: u8 = if (third_callee_reg != null or second_callee_reg != null) 40 else 24;

    try appendStackFrame(allocator, machine, frame_bytes);
    if (extra_param_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{ .frame_index = .slot1, .reg = reg } });
    }
    if (second_arg_live_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{ .frame_index = .slot4, .reg = reg } });
    }
    if (second_callee_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg64_rsp = .{ .frame_index = .slot6, .reg = reg } });
    }
    if (third_callee_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg64_rsp = .{ .frame_index = .slot8, .reg = reg } });
    }
    try setupSysVCallTarget(allocator, machine, first_call_target);
    const first_stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, first_call);
    if (first_stack_arg_count != 0) return error.UnsupportedLiveAcrossCall;
    try appendSysVCallTarget(allocator, machine, first_call_target, first_call.ret_ty);
    try machine.instructions.append(allocator, .{ .spill_eax_rsp = .slot0 });
    if (second_callee_reg) |reg| {
        try machine.instructions.append(allocator, .{ .reload_arg64_rsp = .{ .reg = reg, .frame_index = .slot6 } });
    }
    try setupSysVCallTarget(allocator, machine, second_call_target);
    if (second_arg_live_reg) |reg| {
        try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{ .reg = reg, .frame_index = .slot4 } });
    }
    const second_stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, second_call);
    if (second_stack_arg_count != 0) return error.UnsupportedLiveAcrossCall;
    try appendSysVCallTarget(allocator, machine, second_call_target, second_call.ret_ty);
    try machine.instructions.append(allocator, .{ .spill_eax_rsp = .slot2 });
    if (third_callee_reg) |reg| {
        try machine.instructions.append(allocator, .{ .reload_arg64_rsp = .{ .reg = reg, .frame_index = .slot8 } });
    }
    try setupSysVCallTarget(allocator, machine, third_call_target);
    try appendSysVCallTarget(allocator, machine, third_call_target, .void);
    try machine.instructions.append(allocator, .{ .reload_rsp_eax = .slot0 });
    try machine.instructions.append(allocator, .{ .add_stack_disp8_eax = 8 });
    if (extra_value) |value| switch (value) {
        .int => |int| try machine.instructions.append(allocator, .{ .add_eax_imm32 = try i32Value(int) }),
        .named => {
            if (extra_param_reg == null) return error.UnsupportedCodegenValue;
            try machine.instructions.append(allocator, .{ .add_stack_disp8_eax = 4 });
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => unreachable,
    };
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

fn valueReferencesAddResult(value: ir.Value, add_result: []const u8) bool {
    return switch (value) {
        .named => |name| std.mem.eql(u8, name, add_result),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

fn collectTwoAddLeaves(
    first_add_result: []const u8,
    first_add: ir.BinaryInst,
    second_add: ir.BinaryInst,
    leaves: *[3]ir.Value,
    leaf_count: *usize,
) !void {
    try collectTwoAddLeaf(first_add_result, first_add, second_add.lhs, leaves, leaf_count);
    try collectTwoAddLeaf(first_add_result, first_add, second_add.rhs, leaves, leaf_count);
    if (leaf_count.* != 3) return error.UnsupportedCodegenValue;
}

fn collectTwoAddLeaf(
    first_add_result: []const u8,
    first_add: ir.BinaryInst,
    value: ir.Value,
    leaves: *[3]ir.Value,
    leaf_count: *usize,
) !void {
    if (valueReferencesAddResult(value, first_add_result)) {
        try appendTwoAddLeaf(first_add.lhs, leaves, leaf_count);
        try appendTwoAddLeaf(first_add.rhs, leaves, leaf_count);
        return;
    }
    try appendTwoAddLeaf(value, leaves, leaf_count);
}

fn appendTwoAddLeaf(value: ir.Value, leaves: *[3]ir.Value, leaf_count: *usize) !void {
    if (leaf_count.* >= leaves.len) return error.UnsupportedCodegenValue;
    leaves[leaf_count.*] = value;
    leaf_count.* += 1;
}

fn secondCallUsesValue(call: ir.CallInst, value: ir.Value) bool {
    for (call.args.items) |arg| {
        if (arg.value.eql(value)) return true;
    }
    return false;
}

fn secondCallSingleI32ParamArgReg(function: ir.Function, call: ir.CallInst) !?shared.ArgReg {
    if (call.args.items.len == 0) return null;
    if (call.args.items.len != 1) return error.UnsupportedLiveAcrossCall;
    const arg = call.args.items[0];
    if (arg.attrs != null or !arg.ty.eql(.{ .int = 32 })) return error.UnsupportedLiveAcrossCall;
    return switch (arg.value) {
        .int => null,
        .named => |name| try paramRegOrNull(function, name, .{ .int = 32 }),
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => error.UnsupportedCodegenValue,
    };
}

fn secondCallSingleI64ParamArgReg(function: ir.Function, call: ir.CallInst) !?shared.ArgReg {
    if (call.args.items.len == 0) return null;
    if (call.args.items.len != 1) return error.UnsupportedLiveAcrossCall;
    const arg = call.args.items[0];
    if (arg.attrs != null or !arg.ty.eql(.{ .int = 64 })) return error.UnsupportedLiveAcrossCall;
    return switch (arg.value) {
        .int => null,
        .named => |name| try paramRegOrNull(function, name, .{ .int = 64 }),
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => error.UnsupportedCodegenValue,
    };
}

pub fn lowerGenericCfgSingleBlockFp(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (try fp_rows.lowerGenericCfgFpNegReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try fp_rows.lowerGenericCfgFpBinaryReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try fp_rows.lowerGenericCfgFpCastBinaryPipelineReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try fp_rows.lowerGenericCfgFpCompareReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try fp_rows.lowerGenericCfgFpSelectReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try fp_rows.lowerGenericCfgFpVoidCallIntToFpAddReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try fp_rows.lowerGenericCfgFpVoidCallBinaryReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try fp_rows.lowerGenericCfgFpTwoCallResultsReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try fp_rows.lowerGenericCfgMixedFpTwoCallResultsReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try fp_rows.lowerGenericCfgI64AndFpTwoCallResultsReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try fp_rows.lowerGenericCfgFpAndI64TwoCallResultsReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try fp_rows.lowerGenericCfgFpCallResultAcrossVoidCallReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try fp_rows.lowerGenericCfgFpVoidCallParamReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try fp_rows.lowerGenericCfgFpDirectCallReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try fp_rows.lowerGenericCfgFpParamReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try fp_rows.lowerGenericCfgFpLiteralReturn(allocator, machine, function, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerScalarFpCastReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    return false;
}

pub fn lowerGenericCfgSingleBlockAggregateAbi(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (try lowerGenericCfgSliceLenReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerSliceAggregateInternalAbiReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerAggregatePairAbiFamilyReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerAggregateAbiReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    return false;
}

pub fn lowerGenericCfgSingleBlockI64(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (try lowerSelectedI64ConstReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerMulConstReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgI64ParamReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgSliceLenReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgGprVoidCallStackParamReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerI64SaturatingHelperFamilyReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgI64CallResultAcrossVoidCall(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgTwoI64CallResultsAcrossVoidCall(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgTwoI64CallResultsWithLiveReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgTwoI64CallResultsReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgByteSwapReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgI64DirectCallReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerErrorUnionI64SelectReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgSingleBlockTerminalI64Return(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    return false;
}

fn lowerGenericCfgSingleBlockTerminalI64Return(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 64 })) return false;
    const ret_value = ret.value orelse return false;
    if (!singleBlockTerminalI64InstructionsArePure(block)) return false;
    if (!terminalBlockCanMaterializeI64Value(function, .{ .entry = block, .block = block }, ret_value)) return false;
    try emitGenericCfgTerminalReturnBlock(allocator, machine, function, block, block);
    return true;
}

fn singleBlockTerminalI64InstructionsArePure(block: ir.BasicBlock) bool {
    for (block.instructions.items) |instruction| {
        switch (instruction.kind) {
            .icmp, .select, .cast, .binary => {},
            else => return false,
        }
    }
    return true;
}

pub fn lowerGenericCfgSingleBlockSliceLen(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (try lowerGenericCfgSliceLenReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    return false;
}

fn lowerGenericCfgSliceLenReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const len_value = try sliceLenReturnSource(block, ret) orelse return false;
    if (ret.ty.eql(.{ .int = 32 })) {
        if (try lowerSelectedI32SliceLenReturn(allocator, machine, function, block, len_value)) return true;
    }
    try emitGenericCfgI64ValueIntoRax(allocator, machine, function, block, len_value);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerSelectedI32SliceLenReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    len_value: ir.Value,
) !bool {
    const len_name = switch (len_value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const len_instruction = findInstruction(block, len_name) orelse return false;
    const select = switch (len_instruction.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 64 })) return false;
    const true_len = switch (select.true_value) {
        .int => |int| try i32Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const false_len = switch (select.false_value) {
        .int => |int| try i32Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const cond_name = switch (select.cond) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const cond_instruction = findInstruction(block, cond_name) orelse return false;
    const icmp = switch (cond_instruction.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    const true_label = "generic_cfg_slice_len_true";
    const end_label = "generic_cfg_slice_len_generic_cfg_select_end";
    const branch_kind = try emitGenericCfgIcmpCondition(allocator, machine, function, icmp);
    try appendGenericCfgConditionalBranch(allocator, machine, branch_kind, true_label);
    try machine.instructions.append(allocator, .{ .mov_imm_eax = false_len });
    try machine.instructions.append(allocator, .{ .jmp = end_label });
    try appendGenericCfgBlockLabel(allocator, machine, true_label);
    try machine.instructions.append(allocator, .{ .mov_imm_eax = true_len });
    try appendGenericCfgBlockLabel(allocator, machine, end_label);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn sliceLenReturnSource(block: ir.BasicBlock, ret: anytype) !?ir.Value {
    if (ret.ty.eql(.{ .int = 64 })) {
        return try sliceLenSourceFromValue(block, ret.value orelse return error.InvalidRet);
    }
    if (!ret.ty.eql(.{ .int = 32 })) return null;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const trunc_instruction = findInstruction(block, ret_name) orelse return null;
    const trunc = switch (trunc_instruction.kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (trunc.op != .trunc or !trunc.from_ty.eql(.{ .int = 64 }) or !trunc.to_ty.eql(.{ .int = 32 })) return null;
    return try sliceLenSourceFromValue(block, trunc.value);
}

fn sliceLenSourceFromValue(block: ir.BasicBlock, value: ir.Value) !?ir.Value {
    const extract_name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const extract_instruction = findInstruction(block, extract_name) orelse return null;
    const extract = switch (extract_instruction.kind) {
        .extractvalue => |extract| extract,
        else => return null,
    };
    if (!extract.aggregate_ty.eql(.{ .aggregate = "{ ptr, i64 }" }) or
        !extract.result_ty.eql(.{ .int = 64 }) or
        !std.mem.eql(u8, extract.indices, "1"))
    {
        return null;
    }
    return sliceAggregateLenValue(block, extract.aggregate, 0);
}

fn sliceAggregateLenValue(block: ir.BasicBlock, aggregate: ir.Value, depth: u3) ?ir.Value {
    if (depth == 4) return null;
    const aggregate_name = switch (aggregate) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const aggregate_instruction = findInstruction(block, aggregate_name) orelse return null;
    switch (aggregate_instruction.kind) {
        .insertvalue => |insert| {
            if (!insert.aggregate_ty.eql(.{ .aggregate = "{ ptr, i64 }" })) return null;
            if (insert.value_ty.eql(.{ .int = 64 }) and std.mem.eql(u8, insert.indices, "1")) return insert.value;
            return sliceAggregateLenValue(block, insert.aggregate, depth + 1);
        },
        .load => |load| {
            if (!load.ty.eql(.{ .aggregate = "{ ptr, i64 }" }) or load.attrs.isBarrier()) return null;
            for (block.instructions.items) |instruction| {
                const store = switch (instruction.kind) {
                    .store => |store| store,
                    else => continue,
                };
                if (!store.ty.eql(.{ .aggregate = "{ ptr, i64 }" }) or store.attrs.isBarrier()) continue;
                if (store.ptr.eql(load.ptr)) return sliceAggregateLenValue(block, store.value, depth + 1);
            }
            return null;
        },
        else => return null,
    }
}

fn lowerGenericCfgI64CallResultAcrossVoidCall(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 64 }) or block.instructions.items.len != 3) return false;
    const first_call_inst = block.instructions.items[0];
    const second_call_inst = block.instructions.items[1];
    const add_inst = block.instructions.items[2];
    if (first_call_inst.removed or second_call_inst.removed or add_inst.removed) return false;
    const first_result = first_call_inst.result orelse return false;
    const add_result = add_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, add_result)) return false;

    const first_call = switch (first_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!first_call.ret_ty.eql(.{ .int = 64 }) or first_call.inline_asm != null) return false;
    if (!callIsFastcc(first_call.calling_conv)) try validateDefaultCallConv(first_call.calling_conv);
    if (sysvScalarCallNeedsStackArgs(first_call)) return false;
    const first_call_target: SysVCallTarget = if (first_call.callee_value) |callee_value| blk: {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        break :blk .{ .indirect_from_reg = try paramReg(function, callee_name, .ptr) };
    } else .{ .direct = first_call.callee };

    const second_call = switch (second_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (second_call.ret_ty != .void or second_call.args.items.len != 0 or second_call.inline_asm != null) return false;
    if (!callIsFastcc(second_call.calling_conv)) try validateDefaultCallConv(second_call.calling_conv);
    const second_call_target: SysVCallTarget = if (second_call.callee_value) |callee_value| blk: {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        break :blk .{ .indirect_from_reg = try paramReg(function, callee_name, .ptr) };
    } else .{ .direct = second_call.callee };

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (!add.ty.eql(.{ .int = 64 }) or add.op != .add) return false;
    const other_value = if (isNamed(add.lhs, first_result))
        add.rhs
    else if (isNamed(add.rhs, first_result))
        add.lhs
    else
        return false;
    const other_param_reg = switch (other_value) {
        .named => |name| try paramReg(function, name, .{ .int = 64 }),
        .int => |int| if (try i64Value(int) >= 0 and try i64Value(int) <= std.math.maxInt(u8)) null else return false,
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    const second_callee_reg: ?ArgReg = switch (second_call_target) {
        .direct => null,
        .indirect_from_reg => |reg| reg,
    };
    const frame_bytes: u8 = if (other_param_reg != null or second_callee_reg != null) 24 else 8;

    try appendStackFrame(allocator, machine, frame_bytes);
    if (other_param_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg64_rsp = .{ .frame_index = .slot2, .reg = reg } });
    }
    if (second_callee_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg64_rsp = .{ .frame_index = .slot4, .reg = reg } });
    }
    try setupSysVCallTarget(allocator, machine, first_call_target);
    const first_stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, first_call);
    if (first_stack_arg_count != 0) return error.UnsupportedLiveAcrossCall;
    try appendSysVCallTarget(allocator, machine, first_call_target, first_call.ret_ty);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    if (second_callee_reg) |reg| {
        try machine.instructions.append(allocator, .{ .reload_arg64_rsp = .{ .reg = reg, .frame_index = .slot4 } });
    }
    try setupSysVCallTarget(allocator, machine, second_call_target);
    try appendSysVCallTarget(allocator, machine, second_call_target, .void);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    switch (other_value) {
        .named => try machine.instructions.append(allocator, .{ .add_stack_disp8_rax = 8 }),
        .int => |int| try machine.instructions.append(allocator, .{ .add_rax_imm8 = @intCast(try i64Value(int)) }),
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => unreachable,
    }
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

fn lowerGenericCfgTwoI64CallResultsAcrossVoidCall(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 64 }) or (block.instructions.items.len != 4 and block.instructions.items.len != 5)) return false;
    const first_call_inst = block.instructions.items[0];
    const second_call_inst = block.instructions.items[1];
    const third_call_inst = block.instructions.items[2];
    const add_inst = block.instructions.items[3];
    const final_add_inst: ?ir.Instruction = if (block.instructions.items.len == 5) block.instructions.items[4] else null;
    if (first_call_inst.removed or second_call_inst.removed or third_call_inst.removed or add_inst.removed) return false;
    if (final_add_inst) |inst| if (inst.removed) return false;
    const first_result = first_call_inst.result orelse return false;
    const second_result = second_call_inst.result orelse return false;
    const add_result = add_inst.result orelse return false;
    const ret_value = ret.value orelse return error.InvalidRet;
    if (final_add_inst == null and !isNamed(ret_value, add_result)) return false;

    const first_call = switch (first_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!first_call.ret_ty.eql(.{ .int = 64 }) or first_call.inline_asm != null) return false;
    if (!callIsFastcc(first_call.calling_conv)) try validateDefaultCallConv(first_call.calling_conv);
    if (sysvScalarCallNeedsStackArgs(first_call)) return false;
    const first_call_target: SysVCallTarget = if (first_call.callee_value) |callee_value| blk: {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        break :blk .{ .indirect_from_reg = try paramReg(function, callee_name, .ptr) };
    } else .{ .direct = first_call.callee };

    const second_call = switch (second_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!second_call.ret_ty.eql(.{ .int = 64 }) or second_call.inline_asm != null) return false;
    if (!callIsFastcc(second_call.calling_conv)) try validateDefaultCallConv(second_call.calling_conv);
    if (sysvScalarCallNeedsStackArgs(second_call)) return false;
    const second_arg_live_reg = try secondCallSingleI64ParamArgReg(function, second_call);
    const second_call_target: SysVCallTarget = if (second_call.callee_value) |callee_value| blk: {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        break :blk .{ .indirect_from_reg = try paramReg(function, callee_name, .ptr) };
    } else .{ .direct = second_call.callee };

    const third_call = switch (third_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (third_call.ret_ty != .void or third_call.args.items.len != 0 or third_call.inline_asm != null) return false;
    if (!callIsFastcc(third_call.calling_conv)) try validateDefaultCallConv(third_call.calling_conv);
    const third_call_target: SysVCallTarget = if (third_call.callee_value) |callee_value| blk: {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        break :blk .{ .indirect_from_reg = try paramReg(function, callee_name, .ptr) };
    } else .{ .direct = third_call.callee };

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (!add.ty.eql(.{ .int = 64 }) or add.op != .add) return false;
    var extra_value: ?ir.Value = null;
    if (final_add_inst) |inst| {
        const final_add_result = inst.result orelse return false;
        if (!isNamed(ret_value, final_add_result)) return false;
        const final_add = switch (inst.kind) {
            .binary => |binary| binary,
            else => return false,
        };
        if (!final_add.ty.eql(.{ .int = 64 }) or final_add.op != .add) return false;
        var leaves: [3]ir.Value = undefined;
        var leaf_count: usize = 0;
        try collectTwoAddLeaves(add_result, add, final_add, &leaves, &leaf_count);
        var has_first = false;
        var has_second = false;
        for (leaves[0..leaf_count]) |leaf| {
            if (isNamed(leaf, first_result)) {
                if (has_first) return false;
                has_first = true;
            } else if (isNamed(leaf, second_result)) {
                if (has_second) return false;
                has_second = true;
            } else if (extra_value == null) {
                extra_value = leaf;
            } else {
                return false;
            }
        }
        if (!has_first or !has_second or extra_value == null) return false;
        if (secondCallUsesValue(second_call, extra_value.?)) return false;
    } else {
        const add_uses_results =
            (isNamed(add.lhs, first_result) and isNamed(add.rhs, second_result)) or
            (isNamed(add.lhs, second_result) and isNamed(add.rhs, first_result));
        if (!add_uses_results) return false;
    }

    const third_callee_reg: ?ArgReg = switch (third_call_target) {
        .direct => null,
        .indirect_from_reg => |reg| reg,
    };
    const second_callee_reg: ?ArgReg = switch (second_call_target) {
        .direct => null,
        .indirect_from_reg => |reg| reg,
    };
    const extra_param_reg: ?ArgReg = if (extra_value) |value| switch (value) {
        .named => |name| try paramReg(function, name, .{ .int = 64 }),
        .int => null,
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    } else null;
    const frame_bytes: u8 = if (extra_param_reg != null) 56 else if (second_callee_reg != null or third_callee_reg != null) 40 else 24;

    try appendStackFrame(allocator, machine, frame_bytes);
    if (second_arg_live_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg64_rsp = .{ .frame_index = .slot4, .reg = reg } });
    }
    if (second_callee_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg64_rsp = .{ .frame_index = .slot6, .reg = reg } });
    }
    if (third_callee_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg64_rsp = .{ .frame_index = .slot8, .reg = reg } });
    }
    if (extra_param_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg64_rsp = .{ .frame_index = .slot10, .reg = reg } });
    }
    try setupSysVCallTarget(allocator, machine, first_call_target);
    const first_stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, first_call);
    if (first_stack_arg_count != 0) return error.UnsupportedLiveAcrossCall;
    try appendSysVCallTarget(allocator, machine, first_call_target, first_call.ret_ty);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    if (second_callee_reg) |reg| {
        try machine.instructions.append(allocator, .{ .reload_arg64_rsp = .{ .reg = reg, .frame_index = .slot6 } });
    }
    try setupSysVCallTarget(allocator, machine, second_call_target);
    if (second_arg_live_reg) |reg| {
        try machine.instructions.append(allocator, .{ .reload_arg64_rsp = .{ .reg = reg, .frame_index = .slot4 } });
    }
    const second_stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, second_call);
    if (second_stack_arg_count != 0) return error.UnsupportedLiveAcrossCall;
    try appendSysVCallTarget(allocator, machine, second_call_target, second_call.ret_ty);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot2 });
    if (third_callee_reg) |reg| {
        try machine.instructions.append(allocator, .{ .reload_arg64_rsp = .{ .reg = reg, .frame_index = .slot8 } });
    }
    try setupSysVCallTarget(allocator, machine, third_call_target);
    try appendSysVCallTarget(allocator, machine, third_call_target, .void);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .add_stack_disp8_rax = 8 });
    if (extra_value) |value| switch (value) {
        .int => |int| try machine.instructions.append(allocator, .{ .add_rax_imm8 = @intCast(try i64Value(int)) }),
        .named => {
            if (extra_param_reg == null) return error.UnsupportedCodegenValue;
            try machine.instructions.append(allocator, .{ .add_stack_disp8_rax = 40 });
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => unreachable,
    };
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

fn lowerGenericCfgTwoI64CallResultsReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 64 }) or block.instructions.items.len != 3) return false;
    const first_call_inst = block.instructions.items[0];
    const second_call_inst = block.instructions.items[1];
    const add_inst = block.instructions.items[2];
    if (first_call_inst.removed or second_call_inst.removed or add_inst.removed) return false;
    const first_result = first_call_inst.result orelse return false;
    const second_result = second_call_inst.result orelse return false;
    const add_result = add_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, add_result)) return false;

    const first_call = switch (first_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!first_call.ret_ty.eql(.{ .int = 64 }) or first_call.inline_asm != null) return false;
    if (!callIsFastcc(first_call.calling_conv)) try validateDefaultCallConv(first_call.calling_conv);
    const first_call_target: SysVCallTarget = if (first_call.callee_value) |callee_value| blk: {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        break :blk .{ .indirect_from_reg = try paramReg(function, callee_name, .ptr) };
    } else .{ .direct = first_call.callee };

    const second_call = switch (second_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!second_call.ret_ty.eql(.{ .int = 64 }) or second_call.inline_asm != null) return false;
    if (!callIsFastcc(second_call.calling_conv)) try validateDefaultCallConv(second_call.calling_conv);
    const second_call_target: SysVCallTarget = if (second_call.callee_value) |callee_value| blk: {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        break :blk .{ .indirect_from_reg = try paramReg(function, callee_name, .ptr) };
    } else .{ .direct = second_call.callee };

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (!add.ty.eql(.{ .int = 64 }) or add.op != .add) return false;
    const add_uses_results =
        (isNamed(add.lhs, first_result) and isNamed(add.rhs, second_result)) or
        (isNamed(add.lhs, second_result) and isNamed(add.rhs, first_result));
    if (!add_uses_results) return false;

    const second_callee_reg: ?ArgReg = switch (second_call_target) {
        .direct => null,
        .indirect_from_reg => |reg| reg,
    };
    const frame_bytes: u8 = if (second_callee_reg != null) 24 else 8;

    try appendStackFrame(allocator, machine, frame_bytes);
    if (second_callee_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg64_rsp = .{ .frame_index = .slot2, .reg = reg } });
    }
    try setupSysVCallTarget(allocator, machine, first_call_target);
    const first_stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, first_call);
    if (first_stack_arg_count != 0) return error.UnsupportedLiveAcrossCall;
    try appendSysVCallTarget(allocator, machine, first_call_target, first_call.ret_ty);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    if (second_callee_reg) |reg| {
        try machine.instructions.append(allocator, .{ .reload_arg64_rsp = .{ .reg = reg, .frame_index = .slot2 } });
    }
    try setupSysVCallTarget(allocator, machine, second_call_target);
    const second_stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, second_call);
    if (second_stack_arg_count != 0) return error.UnsupportedLiveAcrossCall;
    try appendSysVCallTarget(allocator, machine, second_call_target, second_call.ret_ty);
    try machine.instructions.append(allocator, .{ .add_stack_disp8_rax = 0 });
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

fn lowerGenericCfgTwoI64CallResultsWithLiveReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 64 }) or block.instructions.items.len != 4) return false;
    const first_call_inst = block.instructions.items[0];
    const second_call_inst = block.instructions.items[1];
    const first_add_inst = block.instructions.items[2];
    const second_add_inst = block.instructions.items[3];
    if (first_call_inst.removed or second_call_inst.removed or first_add_inst.removed or second_add_inst.removed) return false;
    const first_result = first_call_inst.result orelse return false;
    const second_result = second_call_inst.result orelse return false;
    const first_add_result = first_add_inst.result orelse return false;
    const second_add_result = second_add_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, second_add_result)) return false;

    const first_call = switch (first_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!first_call.ret_ty.eql(.{ .int = 64 }) or first_call.inline_asm != null) return false;
    if (!callIsFastcc(first_call.calling_conv)) try validateDefaultCallConv(first_call.calling_conv);
    if (sysvScalarCallNeedsStackArgs(first_call)) return false;
    const first_call_target: SysVCallTarget = if (first_call.callee_value) |callee_value| blk: {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        break :blk .{ .indirect_from_reg = try paramReg(function, callee_name, .ptr) };
    } else .{ .direct = first_call.callee };

    const second_call = switch (second_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!second_call.ret_ty.eql(.{ .int = 64 }) or second_call.inline_asm != null) return false;
    if (!callIsFastcc(second_call.calling_conv)) try validateDefaultCallConv(second_call.calling_conv);
    if (sysvScalarCallNeedsStackArgs(second_call)) return false;
    const second_call_target: SysVCallTarget = if (second_call.callee_value) |callee_value| blk: {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        break :blk .{ .indirect_from_reg = try paramReg(function, callee_name, .ptr) };
    } else .{ .direct = second_call.callee };

    const first_add = switch (first_add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    const second_add = switch (second_add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (!first_add.ty.eql(.{ .int = 64 }) or first_add.op != .add) return false;
    if (!second_add.ty.eql(.{ .int = 64 }) or second_add.op != .add) return false;
    if (!valueReferencesAddResult(second_add.lhs, first_add_result) and !valueReferencesAddResult(second_add.rhs, first_add_result)) return false;

    var leaves: [3]ir.Value = undefined;
    var leaf_count: usize = 0;
    try collectTwoAddLeaves(first_add_result, first_add, second_add, &leaves, &leaf_count);
    var has_first = false;
    var has_second = false;
    var extra_value: ?ir.Value = null;
    for (leaves[0..leaf_count]) |leaf| {
        if (isNamed(leaf, first_result)) {
            if (has_first) return false;
            has_first = true;
        } else if (isNamed(leaf, second_result)) {
            if (has_second) return false;
            has_second = true;
        } else if (extra_value == null) {
            extra_value = leaf;
        } else {
            return false;
        }
    }
    if (!has_first or !has_second) return false;
    const extra = extra_value orelse return false;
    if (secondCallUsesValue(second_call, extra)) return false;

    const extra_param_reg = switch (extra) {
        .named => |name| try paramReg(function, name, .{ .int = 64 }),
        .int => null,
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    const second_arg_live_reg = try secondCallSingleI64ParamArgReg(function, second_call);
    const second_callee_reg: ?ArgReg = switch (second_call_target) {
        .direct => null,
        .indirect_from_reg => |reg| reg,
    };

    try appendStackFrame(allocator, machine, 40);
    if (second_callee_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg64_rsp = .{ .frame_index = .slot2, .reg = reg } });
    }
    if (second_arg_live_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg64_rsp = .{ .frame_index = .slot4, .reg = reg } });
    }
    if (extra_param_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg64_rsp = .{ .frame_index = .slot6, .reg = reg } });
    }
    try setupSysVCallTarget(allocator, machine, first_call_target);
    const first_stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, first_call);
    if (first_stack_arg_count != 0) return error.UnsupportedLiveAcrossCall;
    try appendSysVCallTarget(allocator, machine, first_call_target, first_call.ret_ty);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    if (second_callee_reg) |reg| {
        try machine.instructions.append(allocator, .{ .reload_arg64_rsp = .{ .reg = reg, .frame_index = .slot2 } });
    }
    try setupSysVCallTarget(allocator, machine, second_call_target);
    if (second_arg_live_reg) |reg| {
        try machine.instructions.append(allocator, .{ .reload_arg64_rsp = .{ .reg = reg, .frame_index = .slot4 } });
    }
    const second_stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, second_call);
    if (second_stack_arg_count != 0) return error.UnsupportedLiveAcrossCall;
    try appendSysVCallTarget(allocator, machine, second_call_target, second_call.ret_ty);
    try machine.instructions.append(allocator, .{ .add_stack_disp8_rax = 0 });
    switch (extra) {
        .int => |int| try machine.instructions.append(allocator, .{ .add_rax_imm8 = @intCast(try i64Value(int)) }),
        .named => {
            if (extra_param_reg == null) return error.UnsupportedCodegenValue;
            try machine.instructions.append(allocator, .{ .add_stack_disp8_rax = 24 });
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => unreachable,
    }
    try appendStackFrameEnd(allocator, machine, 40);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}
