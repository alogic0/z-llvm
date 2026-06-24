const shared = @import("core_shared.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");
const cabi_call_lowering = @import("cabi_call_lowering.zig");
const cabi_aggregate_lowering = @import("cabi_aggregate_lowering.zig");

const std = shared.std;
const ir = shared.ir;
const MachineFunction = shared.MachineFunction;
const ArgReg = shared.ArgReg;
const FrameIndex = shared.FrameIndex;
const XmmReg = shared.XmmReg;
const SysVCallTarget = shared.SysVCallTarget;

const appendAlignedDirectCall = shared.appendAlignedDirectCall;
const appendDirectCallWithStackArgs = shared.appendDirectCallWithStackArgs;
const appendIndirectCallRaxWithStackArgs = shared.appendIndirectCallRaxWithStackArgs;
const appendStackFrame = shared.appendStackFrame;
const appendStackFrameEnd = shared.appendStackFrameEnd;
const appendSysVCallTarget = shared.appendSysVCallTarget;
const appendSysVScalarCallArgs = cabi_call_lowering.appendSysVScalarCallArgs;
const callIsFastcc = shared.callIsFastcc;
const fp32TextBits = shared.fp32TextBits;
const fp64TextBits = shared.fp64TextBits;
const fpParamIndex = cabi_abi_helpers.fpParamIndex;
const fpParamIndexFromValue = cabi_aggregate_lowering.fpParamIndexFromValue;
const frameIndexForLiveParam = cabi_call_lowering.frameIndexForLiveParam;
const isNamed = shared.isNamed;
const paramReg = cabi_abi_helpers.paramReg;
const setupSysVCallTarget = shared.setupSysVCallTarget;
const sysvScalarCallNeedsStackArgs = cabi_call_lowering.sysvScalarCallNeedsStackArgs;
const validateDefaultCallConv = shared.validateDefaultCallConv;

pub fn lowerGenericCfgFpBinaryReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (function.params.items.len < 2 or block.instructions.items.len != 1) return false;
    const instruction = block.instructions.items[0];
    if (instruction.removed) return false;
    const result = instruction.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, result)) return false;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (!ret.ty.eql(binary.ty) or !function.ret_ty.eql(binary.ty)) return false;
    if ((!binary.ty.eql(.float) and !binary.ty.eql(.double)) or
        !function.params.items[0].ty.eql(binary.ty) or
        !function.params.items[1].ty.eql(binary.ty)) return false;
    for (function.params.items[2..]) |param| {
        if (!genericCfgSupportsUnusedScalarParam(param.ty)) return false;
    }
    if (!isNamed(binary.lhs, function.params.items[0].name) or
        !isNamed(binary.rhs, function.params.items[1].name)) return false;

    if (binary.ty.eql(.float)) {
        switch (binary.op) {
            .fadd => try machine.instructions.append(allocator, .addss_xmm1_xmm0),
            .fmul => try machine.instructions.append(allocator, .mulss_xmm1_xmm0),
            .fsub => try machine.instructions.append(allocator, .subss_xmm1_xmm0),
            .frem => try appendAlignedDirectCall(allocator, machine, "fmodf", .float),
            .fdiv, .add, .sub, .mul, .shl, .lshr, .ashr, .@"and", .@"or", .xor, .udiv, .sdiv, .urem, .srem => return false,
        }
    } else if (binary.ty.eql(.double)) {
        switch (binary.op) {
            .fmul => try machine.instructions.append(allocator, .mulsd_xmm1_xmm0),
            .fdiv => try machine.instructions.append(allocator, .divsd_xmm1_xmm0),
            .fadd, .fsub, .frem, .add, .sub, .mul, .shl, .lshr, .ashr, .@"and", .@"or", .xor, .udiv, .sdiv, .urem, .srem => return false,
        }
    } else {
        return false;
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgFpCastBinaryPipelineReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if ((!function.ret_ty.eql(.float) and !function.ret_ty.eql(.double)) or !ret.ty.eql(function.ret_ty)) return false;
    if (function.params.items.len < 2) return false;
    if (block.instructions.items.len != 2 and block.instructions.items.len != 3) return false;

    const cast_inst = block.instructions.items[0];
    if (cast_inst.removed) return false;
    const cast_result = fpSitofpFirstGprI32Result(function, cast_inst, function.ret_ty) catch return false;

    if (block.instructions.items.len == 2) {
        const add_inst = block.instructions.items[1];
        if (add_inst.removed) return false;
        const add_result = add_inst.result orelse return false;
        if (!isNamed(ret.value orelse return error.InvalidRet, add_result)) return false;
        const fp_param = fpBinaryOtherParamIndex(function, add_inst, function.ret_ty, cast_result, .fadd) catch return false;
        if (fp_param != 0) return error.UnsupportedCodegenAbi;

        try machine.instructions.append(allocator, .{ .movapd_xmm = .{ .dst = .xmm1, .src = .xmm0 } });
        try emitFirstGprI32ToFpXmm0(allocator, machine, function.ret_ty);
        try appendFpAddXmm1Xmm0(allocator, machine, function.ret_ty);
        try machine.instructions.append(allocator, .ret);
        return true;
    }

    const mul_inst = block.instructions.items[1];
    const add_inst = block.instructions.items[2];
    if (mul_inst.removed or add_inst.removed) return false;
    const mul_result = mul_inst.result orelse return false;
    const add_result = add_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, add_result)) return false;
    const mul_param = fpBinaryOtherParamIndex(function, mul_inst, function.ret_ty, cast_result, .fmul) catch return false;
    const add_param = fpBinaryOtherParamIndex(function, add_inst, function.ret_ty, mul_result, .fadd) catch return false;
    if (mul_param != 0 or add_param != 1) return error.UnsupportedCodegenAbi;

    try machine.instructions.append(allocator, .{ .movapd_xmm = .{ .dst = .xmm2, .src = .xmm1 } });
    try machine.instructions.append(allocator, .{ .movapd_xmm = .{ .dst = .xmm1, .src = .xmm0 } });
    try emitFirstGprI32ToFpXmm0(allocator, machine, function.ret_ty);
    try appendFpMulXmm1Xmm0(allocator, machine, function.ret_ty);
    try machine.instructions.append(allocator, .{ .movapd_xmm = .{ .dst = .xmm1, .src = .xmm2 } });
    try appendFpAddXmm1Xmm0(allocator, machine, function.ret_ty);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn fpSitofpFirstGprI32Result(function: ir.Function, instruction: ir.Instruction, to_ty: ir.Type) ![]const u8 {
    const result = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const cast = switch (instruction.kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (cast.op != .sitofp or !cast.from_ty.eql(.{ .int = 32 }) or !cast.to_ty.eql(to_ty)) return error.UnsupportedCodegenInstruction;
    const source_name = switch (cast.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    if ((try paramReg(function, source_name, .{ .int = 32 })) != .rdi) return error.UnsupportedCodegenAbi;
    return result;
}

pub fn fpBinaryOtherParamIndex(
    function: ir.Function,
    instruction: ir.Instruction,
    ty: ir.Type,
    fixed_name: []const u8,
    op: ir.BinaryOp,
) !usize {
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (binary.op != op or !binary.ty.eql(ty)) return error.UnsupportedCodegenInstruction;
    const lhs_fixed = isNamed(binary.lhs, fixed_name);
    const rhs_fixed = isNamed(binary.rhs, fixed_name);
    if (lhs_fixed == rhs_fixed) return error.UnsupportedCodegenInstruction;
    const other = if (lhs_fixed) binary.rhs else binary.lhs;
    return fpParamIndexFromValue(function, other, ty);
}

pub fn emitFirstGprI32ToFpXmm0(allocator: std.mem.Allocator, machine: *MachineFunction, ty: ir.Type) !void {
    if (ty.eql(.float)) {
        try machine.instructions.append(allocator, .cvtsi2ss_edi_xmm0);
    } else if (ty.eql(.double)) {
        try machine.instructions.append(allocator, .cvtsi2sd_edi_xmm0);
    } else return error.UnsupportedCodegenType;
}

pub fn appendFpAddXmm1Xmm0(allocator: std.mem.Allocator, machine: *MachineFunction, ty: ir.Type) !void {
    if (ty.eql(.float)) {
        try machine.instructions.append(allocator, .addss_xmm1_xmm0);
    } else if (ty.eql(.double)) {
        try machine.instructions.append(allocator, .addsd_xmm1_xmm0);
    } else return error.UnsupportedCodegenType;
}

pub fn appendFpMulXmm1Xmm0(allocator: std.mem.Allocator, machine: *MachineFunction, ty: ir.Type) !void {
    if (ty.eql(.float)) {
        try machine.instructions.append(allocator, .mulss_xmm1_xmm0);
    } else if (ty.eql(.double)) {
        try machine.instructions.append(allocator, .mulsd_xmm1_xmm0);
    } else return error.UnsupportedCodegenType;
}

pub fn genericCfgSupportsUnusedScalarParam(ty: ir.Type) bool {
    return switch (ty) {
        .int, .ptr, .float, .double => true,
        .void, .x86_fp80, .fp128, .metadata, .aggregate, .vector => false,
    };
}

pub fn lowerGenericCfgFpCompareReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (function.params.items.len != 2 or block.instructions.items.len != 1) return false;
    if (!function.ret_ty.eql(.{ .int = 1 }) or !ret.ty.eql(.{ .int = 1 })) return false;
    const instruction = block.instructions.items[0];
    if (instruction.removed) return false;
    const result = instruction.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, result)) return false;
    const fcmp = switch (instruction.kind) {
        .fcmp => |fcmp| fcmp,
        else => return false,
    };
    if (fcmp.predicate != .olt or !fcmp.operand_ty.eql(.float)) return false;
    if (!function.params.items[0].ty.eql(.float) or !function.params.items[1].ty.eql(.float)) return false;
    if (!isNamed(fcmp.lhs, function.params.items[0].name) or
        !isNamed(fcmp.rhs, function.params.items[1].name)) return false;

    try machine.instructions.append(allocator, .oltss_xmm0_xmm1_al);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgFpSelectReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (function.params.items.len != 3 or block.instructions.items.len != 1) return false;
    if (!function.ret_ty.eql(.double) or !ret.ty.eql(.double)) return false;
    if (!function.params.items[0].ty.eql(.double) or
        !function.params.items[1].ty.eql(.double) or
        !function.params.items[2].ty.eql(.{ .int = 1 })) return false;
    const instruction = block.instructions.items[0];
    if (instruction.removed) return false;
    const result = instruction.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, result)) return false;
    const select = switch (instruction.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.double)) return false;
    if (!isNamed(select.cond, function.params.items[2].name) or
        !isNamed(select.true_value, function.params.items[0].name) or
        !isNamed(select.false_value, function.params.items[1].name)) return false;

    const false_label = "generic_cfg_fp_select_false";
    try machine.instructions.append(allocator, .{ .test_arg8 = .rdi });
    try machine.instructions.append(allocator, .{ .je = false_label });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = false_label });
    try machine.instructions.append(allocator, .movapd_xmm1_xmm0);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgFpDirectCallReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if ((!function.ret_ty.eql(.float) and !function.ret_ty.eql(.double)) or
        !ret.ty.eql(function.ret_ty) or block.instructions.items.len != 1) return false;
    const instruction = block.instructions.items[0];
    if (instruction.removed) return false;
    const call_result = instruction.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, call_result)) return false;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!call.ret_ty.eql(function.ret_ty) or call.inline_asm != null) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;

    if (call.callee_value) |callee_value| {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        const callee_reg = try paramReg(function, callee_name, .ptr);
        try machine.instructions.append(allocator, .{ .mov_arg_rax = callee_reg });
        const stack_arg_count = try appendSysVScalarCallArgs(allocator, machine, function, call);
        try appendIndirectCallRaxWithStackArgs(allocator, machine, call.ret_ty, stack_arg_count);
    } else {
        const stack_arg_count = try appendSysVScalarCallArgs(allocator, machine, function, call);
        try appendDirectCallWithStackArgs(allocator, machine, call.callee, call.ret_ty, stack_arg_count);
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgFpVoidCallParamReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if ((!function.ret_ty.eql(.float) and !function.ret_ty.eql(.double)) or
        !ret.ty.eql(function.ret_ty) or block.instructions.items.len != 1) return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const live_index = fpParamIndex(function, ret_name, function.ret_ty) catch return false;
    if (live_index >= 2) return error.UnsupportedLiveAcrossCall;
    const instruction = block.instructions.items[0];
    if (instruction.removed or instruction.result != null) return false;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.ret_ty != .void or call.inline_asm != null) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;
    if (call.ret_attrs != null or call.attrs != null) return error.UnsupportedCodegenAbi;
    if (call.callee_function_ty) |function_ty| {
        if (std.mem.indexOf(u8, function_ty, "...") != null) return error.UnsupportedCodegenAbi;
    }
    if (sysvScalarCallNeedsStackArgs(call)) return error.UnsupportedLiveAcrossCall;
    const call_target: SysVCallTarget = if (call.callee_value) |callee_value| blk: {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        break :blk .{ .indirect_from_reg = try paramReg(function, callee_name, .ptr) };
    } else .{ .direct = call.callee };

    try appendStackFrame(allocator, machine, 8);
    const live_reg = try XmmReg.fromIndex(live_index);
    if (function.ret_ty.eql(.float)) {
        try machine.instructions.append(allocator, .{ .spill_xmm32_rsp = .{ .reg = live_reg, .frame_index = .slot0 } });
    } else {
        try machine.instructions.append(allocator, .{ .spill_xmm64_rsp = .{ .reg = live_reg, .frame_index = .slot0 } });
    }
    try setupSysVCallTarget(allocator, machine, call_target);
    _ = try appendSysVScalarCallArgs(allocator, machine, function, call);
    try appendSysVCallTarget(allocator, machine, call_target, call.ret_ty);
    if (function.ret_ty.eql(.float)) {
        try machine.instructions.append(allocator, .{ .reload_xmm32_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    } else {
        try machine.instructions.append(allocator, .{ .reload_xmm64_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    }
    try appendStackFrameEnd(allocator, machine, 8);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgFpVoidCallIntToFpAddReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if ((!function.ret_ty.eql(.float) and !function.ret_ty.eql(.double)) or !ret.ty.eql(function.ret_ty)) return false;
    if (block.instructions.items.len < 3 or block.instructions.items.len > 4) return false;
    const call_count = try leadingFpVoidCallCount(block);
    if (call_count == 0 or block.instructions.items.len != call_count + 2) return false;

    for (block.instructions.items[0..call_count]) |call_inst| {
        const call = call_inst.kind.call;
        if (call.args.items.len != 0) return false;
    }

    const cast_inst = block.instructions.items[call_count];
    if (cast_inst.removed) return false;
    const cast_result = cast_inst.result orelse return false;
    const int_param = fpVoidCallSitofpI32Param(function, cast_inst, function.ret_ty) catch return false;

    const add_inst = block.instructions.items[call_count + 1];
    if (add_inst.removed) return false;
    const add_result = add_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, add_result)) return false;
    const fp_param_index = fpBinaryOtherParamIndex(function, add_inst, function.ret_ty, cast_result, .fadd) catch return false;
    if (fp_param_index >= 6) return error.UnsupportedLiveAcrossCall;

    const preserved_callee = try repeatedFpVoidCallPreservedCallee(function, block, call_count);
    try appendStackFrame(allocator, machine, 24);
    try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{ .reg = int_param, .frame_index = .slot0 } });
    const fp_reg = try XmmReg.fromIndex(fp_param_index);
    if (function.ret_ty.eql(.float)) {
        try machine.instructions.append(allocator, .{ .spill_xmm32_rsp = .{ .reg = fp_reg, .frame_index = .slot2 } });
    } else {
        try machine.instructions.append(allocator, .{ .spill_xmm64_rsp = .{ .reg = fp_reg, .frame_index = .slot2 } });
    }
    if (preserved_callee) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg64_rsp = .{ .reg = reg, .frame_index = .slot4 } });
    }
    var index: usize = 0;
    while (index < call_count) : (index += 1) {
        const call = block.instructions.items[index].kind.call;
        const call_target = try fpVoidCallTarget(function, call);
        if (preserved_callee) |reg| {
            if (call_target == .indirect_from_reg) {
                try machine.instructions.append(allocator, .{ .reload_arg64_rsp = .{ .reg = reg, .frame_index = .slot4 } });
            }
        }
        try setupSysVCallTarget(allocator, machine, call_target);
        _ = try appendSysVScalarCallArgs(allocator, machine, function, call);
        try appendSysVCallTarget(allocator, machine, call_target, call.ret_ty);
    }
    try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{ .reg = .rdi, .frame_index = .slot0 } });
    try emitFirstGprI32ToFpXmm0(allocator, machine, function.ret_ty);
    if (function.ret_ty.eql(.float)) {
        try machine.instructions.append(allocator, .{ .reload_xmm32_rsp = .{ .reg = .xmm1, .frame_index = .slot2 } });
        try machine.instructions.append(allocator, .addss_xmm1_xmm0);
    } else {
        try machine.instructions.append(allocator, .{ .reload_xmm64_rsp = .{ .reg = .xmm1, .frame_index = .slot2 } });
        try machine.instructions.append(allocator, .addsd_xmm1_xmm0);
    }
    try appendStackFrameEnd(allocator, machine, 24);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn fpVoidCallSitofpI32Param(function: ir.Function, instruction: ir.Instruction, to_ty: ir.Type) !ArgReg {
    const cast = switch (instruction.kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (cast.op != .sitofp or !cast.from_ty.eql(.{ .int = 32 }) or !cast.to_ty.eql(to_ty)) return error.UnsupportedCodegenInstruction;
    const source_name = switch (cast.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    return paramReg(function, source_name, .{ .int = 32 });
}

pub fn lowerGenericCfgFpVoidCallBinaryReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if ((!function.ret_ty.eql(.float) and !function.ret_ty.eql(.double)) or !ret.ty.eql(function.ret_ty) or
        block.instructions.items.len < 2 or block.instructions.items.len > 8) return false;
    const call_count = try leadingFpVoidCallCount(block);
    if (call_count == 0) return false;

    const addend_count = try collectFpVoidCallFaddParamChain(function, block, call_count, ret.value orelse return error.InvalidRet);
    if (addend_count < 2 or addend_count > 6) return error.UnsupportedLiveAcrossCall;

    const preserved_callee = try repeatedFpVoidCallPreservedCallee(function, block, call_count);
    const frame_bytes = try fpLiveAddendFrameBytes(function.ret_ty, addend_count, preserved_callee != null);
    try appendStackFrame(allocator, machine, frame_bytes);
    var index: usize = 0;
    while (index < addend_count) : (index += 1) {
        const reg = try XmmReg.fromIndex(index);
        const frame_index = try frameIndexForFpLiveAddend(function.ret_ty, index);
        if (function.ret_ty.eql(.float)) {
            try machine.instructions.append(allocator, .{ .spill_xmm32_rsp = .{ .reg = reg, .frame_index = frame_index } });
        } else {
            try machine.instructions.append(allocator, .{ .spill_xmm64_rsp = .{ .reg = reg, .frame_index = frame_index } });
        }
    }
    if (preserved_callee) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg64_rsp = .{ .reg = reg, .frame_index = try frameIndexForFpPreservedCallee(function.ret_ty, addend_count) } });
    }
    index = 0;
    while (index < call_count) : (index += 1) {
        const call = block.instructions.items[index].kind.call;
        const call_target = try fpVoidCallTarget(function, call);
        if (preserved_callee) |reg| {
            if (call_target == .indirect_from_reg) {
                try machine.instructions.append(allocator, .{ .reload_arg64_rsp = .{ .reg = reg, .frame_index = try frameIndexForFpPreservedCallee(function.ret_ty, addend_count) } });
            }
        }
        try setupSysVCallTarget(allocator, machine, call_target);
        _ = try appendSysVScalarCallArgs(allocator, machine, function, call);
        try appendSysVCallTarget(allocator, machine, call_target, call.ret_ty);
    }
    if (function.ret_ty.eql(.float)) {
        try machine.instructions.append(allocator, .{ .reload_xmm32_rsp = .{ .reg = .xmm0, .frame_index = try frameIndexForFpLiveAddend(function.ret_ty, 0) } });
        index = 1;
        while (index < addend_count) : (index += 1) {
            try machine.instructions.append(allocator, .{ .reload_xmm32_rsp = .{ .reg = .xmm1, .frame_index = try frameIndexForFpLiveAddend(function.ret_ty, index) } });
            try machine.instructions.append(allocator, .addss_xmm1_xmm0);
        }
    } else {
        try machine.instructions.append(allocator, .{ .reload_xmm64_rsp = .{ .reg = .xmm0, .frame_index = try frameIndexForFpLiveAddend(function.ret_ty, 0) } });
        index = 1;
        while (index < addend_count) : (index += 1) {
            try machine.instructions.append(allocator, .{ .reload_xmm64_rsp = .{ .reg = .xmm1, .frame_index = try frameIndexForFpLiveAddend(function.ret_ty, index) } });
            try machine.instructions.append(allocator, .addsd_xmm1_xmm0);
        }
    }
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgFpCallResultAcrossVoidCallReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if ((!function.ret_ty.eql(.float) and !function.ret_ty.eql(.double)) or
        !ret.ty.eql(function.ret_ty) or block.instructions.items.len != 3) return false;

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
    if (!first_call.ret_ty.eql(function.ret_ty) or first_call.inline_asm != null) return false;
    if (!callIsFastcc(first_call.calling_conv)) validateDefaultCallConv(first_call.calling_conv) catch return false;
    if (first_call.ret_attrs != null or first_call.attrs != null) return error.UnsupportedCodegenAbi;
    if (sysvScalarCallNeedsStackArgs(first_call)) return error.UnsupportedLiveAcrossCall;
    const first_target: SysVCallTarget = if (first_call.callee_value) |callee_value| blk: {
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
    try validateFpVoidCall(second_call);
    if (second_call.args.items.len != 0) return error.UnsupportedLiveAcrossCall;

    const fp_param_index = fpBinaryOtherParamIndex(function, add_inst, function.ret_ty, first_result, .fadd) catch return false;
    if (fp_param_index >= 6) return error.UnsupportedLiveAcrossCall;

    const second_target = try fpVoidCallTarget(function, second_call);
    const preserved_callee: ?ArgReg = switch (second_target) {
        .direct => null,
        .indirect_from_reg => |reg| reg,
    };

    const frame_bytes: u8 = if (function.ret_ty.eql(.float)) 24 else 40;
    const live_addend_slot: FrameIndex = .slot0;
    const call_result_slot: FrameIndex = if (function.ret_ty.eql(.float)) .slot2 else .slot4;
    const callee_slot: FrameIndex = if (function.ret_ty.eql(.float)) .slot4 else .slot8;

    try appendStackFrame(allocator, machine, frame_bytes);
    const fp_param_reg = try XmmReg.fromIndex(fp_param_index);
    if (function.ret_ty.eql(.float)) {
        try machine.instructions.append(allocator, .{ .spill_xmm32_rsp = .{ .reg = fp_param_reg, .frame_index = live_addend_slot } });
    } else {
        try machine.instructions.append(allocator, .{ .spill_xmm64_rsp = .{ .reg = fp_param_reg, .frame_index = live_addend_slot } });
    }
    if (preserved_callee) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg64_rsp = .{ .reg = reg, .frame_index = callee_slot } });
    }

    const first_stack_args = try appendSysVScalarCallArgs(allocator, machine, function, first_call);
    if (first_stack_args != 0) return error.UnsupportedLiveAcrossCall;
    try setupSysVCallTarget(allocator, machine, first_target);
    try appendSysVCallTarget(allocator, machine, first_target, first_call.ret_ty);
    if (function.ret_ty.eql(.float)) {
        try machine.instructions.append(allocator, .{ .spill_xmm32_rsp = .{ .reg = .xmm0, .frame_index = call_result_slot } });
    } else {
        try machine.instructions.append(allocator, .{ .spill_xmm64_rsp = .{ .reg = .xmm0, .frame_index = call_result_slot } });
    }

    if (preserved_callee) |reg| {
        try machine.instructions.append(allocator, .{ .reload_arg64_rsp = .{ .reg = reg, .frame_index = callee_slot } });
    }
    try setupSysVCallTarget(allocator, machine, second_target);
    _ = try appendSysVScalarCallArgs(allocator, machine, function, second_call);
    try appendSysVCallTarget(allocator, machine, second_target, second_call.ret_ty);

    if (function.ret_ty.eql(.float)) {
        try machine.instructions.append(allocator, .{ .reload_xmm32_rsp = .{ .reg = .xmm0, .frame_index = call_result_slot } });
        try machine.instructions.append(allocator, .{ .reload_xmm32_rsp = .{ .reg = .xmm1, .frame_index = live_addend_slot } });
        try machine.instructions.append(allocator, .addss_xmm1_xmm0);
    } else {
        try machine.instructions.append(allocator, .{ .reload_xmm64_rsp = .{ .reg = .xmm0, .frame_index = call_result_slot } });
        try machine.instructions.append(allocator, .{ .reload_xmm64_rsp = .{ .reg = .xmm1, .frame_index = live_addend_slot } });
        try machine.instructions.append(allocator, .addsd_xmm1_xmm0);
    }
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgFpTwoCallResultsReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if ((!function.ret_ty.eql(.float) and !function.ret_ty.eql(.double)) or
        !ret.ty.eql(function.ret_ty) or block.instructions.items.len != 3) return false;

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
    const second_call = switch (second_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!first_call.ret_ty.eql(function.ret_ty) or !second_call.ret_ty.eql(function.ret_ty)) return false;
    if (first_call.inline_asm != null or second_call.inline_asm != null) return false;
    if (!callIsFastcc(first_call.calling_conv)) validateDefaultCallConv(first_call.calling_conv) catch return false;
    if (!callIsFastcc(second_call.calling_conv)) validateDefaultCallConv(second_call.calling_conv) catch return false;
    if (first_call.ret_attrs != null or first_call.attrs != null or second_call.ret_attrs != null or second_call.attrs != null) return error.UnsupportedCodegenAbi;
    if (sysvScalarCallNeedsStackArgs(first_call) or sysvScalarCallNeedsStackArgs(second_call)) return error.UnsupportedLiveAcrossCall;
    if (first_call.args.items.len != 1 or second_call.args.items.len != 1) return false;
    if (!first_call.args.items[0].ty.eql(function.ret_ty) or !second_call.args.items[0].ty.eql(function.ret_ty)) return false;
    if ((try fpParamIndexFromValue(function, first_call.args.items[0].value, function.ret_ty)) != 0) return error.UnsupportedLiveAcrossCall;
    const second_arg_index = try fpParamIndexFromValue(function, second_call.args.items[0].value, function.ret_ty);
    if (second_arg_index >= 6) return error.UnsupportedLiveAcrossCall;

    const binary = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (binary.op != .fadd or !binary.ty.eql(function.ret_ty)) return false;
    const lhs_first = isNamed(binary.lhs, first_result);
    const rhs_first = isNamed(binary.rhs, first_result);
    const lhs_second = isNamed(binary.lhs, second_result);
    const rhs_second = isNamed(binary.rhs, second_result);
    if (!((lhs_first and rhs_second) or (rhs_first and lhs_second))) return false;

    const first_target = try fpCallTarget(function, first_call);
    const second_target = try fpCallTarget(function, second_call);
    const second_callee: ?ArgReg = switch (second_target) {
        .direct => null,
        .indirect_from_reg => |reg| reg,
    };

    try appendStackFrame(allocator, machine, 24);
    const second_arg_reg = try XmmReg.fromIndex(second_arg_index);
    if (function.ret_ty.eql(.float)) {
        try machine.instructions.append(allocator, .{ .spill_xmm32_rsp = .{ .reg = second_arg_reg, .frame_index = .slot0 } });
    } else {
        try machine.instructions.append(allocator, .{ .spill_xmm64_rsp = .{ .reg = second_arg_reg, .frame_index = .slot0 } });
    }
    if (second_callee) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg64_rsp = .{ .reg = reg, .frame_index = .slot4 } });
    }

    try setupSysVCallTarget(allocator, machine, first_target);
    const first_stack_args = try appendSysVScalarCallArgs(allocator, machine, function, first_call);
    if (first_stack_args != 0) return error.UnsupportedLiveAcrossCall;
    try appendSysVCallTarget(allocator, machine, first_target, first_call.ret_ty);
    if (function.ret_ty.eql(.float)) {
        try machine.instructions.append(allocator, .{ .spill_xmm32_rsp = .{ .reg = .xmm0, .frame_index = .slot2 } });
        try machine.instructions.append(allocator, .{ .reload_xmm32_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    } else {
        try machine.instructions.append(allocator, .{ .spill_xmm64_rsp = .{ .reg = .xmm0, .frame_index = .slot2 } });
        try machine.instructions.append(allocator, .{ .reload_xmm64_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    }
    if (second_callee) |reg| {
        try machine.instructions.append(allocator, .{ .reload_arg64_rsp = .{ .reg = reg, .frame_index = .slot4 } });
    }
    try setupSysVCallTarget(allocator, machine, second_target);
    try appendSysVCallTarget(allocator, machine, second_target, second_call.ret_ty);

    if (function.ret_ty.eql(.float)) {
        try machine.instructions.append(allocator, .{ .reload_xmm32_rsp = .{ .reg = .xmm1, .frame_index = .slot2 } });
        try machine.instructions.append(allocator, .addss_xmm1_xmm0);
    } else {
        try machine.instructions.append(allocator, .{ .reload_xmm64_rsp = .{ .reg = .xmm1, .frame_index = .slot2 } });
        try machine.instructions.append(allocator, .addsd_xmm1_xmm0);
    }
    try appendStackFrameEnd(allocator, machine, 24);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgMixedFpTwoCallResultsReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!function.ret_ty.eql(.double) or !ret.ty.eql(.double) or block.instructions.items.len != 4) return false;

    const first_call_inst = block.instructions.items[0];
    const second_call_inst = block.instructions.items[1];
    const cast_inst = block.instructions.items[2];
    const add_inst = block.instructions.items[3];
    if (first_call_inst.removed or second_call_inst.removed or cast_inst.removed or add_inst.removed) return false;

    const first_result = first_call_inst.result orelse return false;
    const second_result = second_call_inst.result orelse return false;
    const cast_result = cast_inst.result orelse return false;
    const add_result = add_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, add_result)) return false;

    const first_call = switch (first_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    const second_call = switch (second_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    const cast = switch (cast_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (cast.op != .fpext or !cast.from_ty.eql(.float) or !cast.to_ty.eql(.double)) return false;
    const cast_first = isNamed(cast.value, first_result);
    const cast_second = isNamed(cast.value, second_result);
    if (cast_first == cast_second) return false;

    const first_ty: ir.Type = if (cast_first) .float else .double;
    const second_ty: ir.Type = if (cast_first) .double else .float;
    if (!first_call.ret_ty.eql(first_ty) or !second_call.ret_ty.eql(second_ty)) return false;
    if (first_call.inline_asm != null or second_call.inline_asm != null) return false;
    if (!callIsFastcc(first_call.calling_conv)) validateDefaultCallConv(first_call.calling_conv) catch return false;
    if (!callIsFastcc(second_call.calling_conv)) validateDefaultCallConv(second_call.calling_conv) catch return false;
    if (first_call.ret_attrs != null or first_call.attrs != null or second_call.ret_attrs != null or second_call.attrs != null) return error.UnsupportedCodegenAbi;
    if (sysvScalarCallNeedsStackArgs(first_call) or sysvScalarCallNeedsStackArgs(second_call)) return error.UnsupportedLiveAcrossCall;
    if (first_call.args.items.len != 1 or second_call.args.items.len != 1) return false;
    if (!first_call.args.items[0].ty.eql(first_ty) or !second_call.args.items[0].ty.eql(second_ty)) return false;
    if ((try fpParamIndexFromValue(function, first_call.args.items[0].value, first_ty)) != 0) return error.UnsupportedLiveAcrossCall;
    const second_arg_index = try fpParamIndexFromValue(function, second_call.args.items[0].value, second_ty);
    if (second_arg_index >= 6) return error.UnsupportedLiveAcrossCall;

    const binary = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (binary.op != .fadd or !binary.ty.eql(.double)) return false;
    const lhs_cast = isNamed(binary.lhs, cast_result);
    const rhs_cast = isNamed(binary.rhs, cast_result);
    const lhs_first = isNamed(binary.lhs, first_result);
    const rhs_first = isNamed(binary.rhs, first_result);
    const lhs_second = isNamed(binary.lhs, second_result);
    const rhs_second = isNamed(binary.rhs, second_result);
    if (cast_first) {
        if (!((lhs_cast and rhs_second) or (rhs_cast and lhs_second))) return false;
    } else {
        if (!((lhs_first and rhs_cast) or (rhs_first and lhs_cast))) return false;
    }

    const first_target = try fpCallTarget(function, first_call);
    const second_target = try fpCallTarget(function, second_call);
    const second_callee: ?ArgReg = switch (second_target) {
        .direct => null,
        .indirect_from_reg => |reg| reg,
    };

    try appendStackFrame(allocator, machine, 24);
    const second_arg_reg = try XmmReg.fromIndex(second_arg_index);
    if (second_ty.eql(.float)) {
        try machine.instructions.append(allocator, .{ .spill_xmm32_rsp = .{ .reg = second_arg_reg, .frame_index = .slot0 } });
    } else {
        try machine.instructions.append(allocator, .{ .spill_xmm64_rsp = .{ .reg = second_arg_reg, .frame_index = .slot0 } });
    }
    if (second_callee) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg64_rsp = .{ .reg = reg, .frame_index = .slot4 } });
    }

    try setupSysVCallTarget(allocator, machine, first_target);
    const first_stack_args = try appendSysVScalarCallArgs(allocator, machine, function, first_call);
    if (first_stack_args != 0) return error.UnsupportedLiveAcrossCall;
    try appendSysVCallTarget(allocator, machine, first_target, first_call.ret_ty);
    if (first_ty.eql(.float)) {
        try machine.instructions.append(allocator, .{ .spill_xmm32_rsp = .{ .reg = .xmm0, .frame_index = .slot2 } });
    } else {
        try machine.instructions.append(allocator, .{ .spill_xmm64_rsp = .{ .reg = .xmm0, .frame_index = .slot2 } });
    }
    if (second_ty.eql(.float)) {
        try machine.instructions.append(allocator, .{ .reload_xmm32_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    } else {
        try machine.instructions.append(allocator, .{ .reload_xmm64_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    }
    if (second_callee) |reg| {
        try machine.instructions.append(allocator, .{ .reload_arg64_rsp = .{ .reg = reg, .frame_index = .slot4 } });
    }
    try setupSysVCallTarget(allocator, machine, second_target);
    try appendSysVCallTarget(allocator, machine, second_target, second_call.ret_ty);

    if (cast_first) {
        try machine.instructions.append(allocator, .{ .spill_xmm64_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
        try machine.instructions.append(allocator, .{ .reload_xmm32_rsp = .{ .reg = .xmm0, .frame_index = .slot2 } });
        try machine.instructions.append(allocator, .cvtss2sd_xmm0_xmm0);
        try machine.instructions.append(allocator, .{ .reload_xmm64_rsp = .{ .reg = .xmm1, .frame_index = .slot0 } });
    } else {
        try machine.instructions.append(allocator, .cvtss2sd_xmm0_xmm0);
        try machine.instructions.append(allocator, .{ .spill_xmm64_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
        try machine.instructions.append(allocator, .{ .reload_xmm64_rsp = .{ .reg = .xmm0, .frame_index = .slot2 } });
        try machine.instructions.append(allocator, .{ .reload_xmm64_rsp = .{ .reg = .xmm1, .frame_index = .slot0 } });
    }
    try machine.instructions.append(allocator, .addsd_xmm1_xmm0);
    try appendStackFrameEnd(allocator, machine, 24);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn fpCallTarget(function: ir.Function, call: ir.CallInst) !SysVCallTarget {
    return if (call.callee_value) |callee_value| blk: {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        break :blk .{ .indirect_from_reg = try paramReg(function, callee_name, .ptr) };
    } else .{ .direct = call.callee };
}

fn leadingFpVoidCallCount(block: ir.BasicBlock) !usize {
    var count: usize = 0;
    while (count < block.instructions.items.len) : (count += 1) {
        const instruction = block.instructions.items[count];
        if (instruction.removed or instruction.result != null) break;
        const call = switch (instruction.kind) {
            .call => |call| call,
            else => break,
        };
        try validateFpVoidCall(call);
        if (count > 0 and call.args.items.len != 0) return error.UnsupportedLiveAcrossCall;
        if (count == 2) return error.UnsupportedLiveAcrossCall;
    }
    return count;
}

fn validateFpVoidCall(call: ir.CallInst) !void {
    if (call.ret_ty != .void or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return error.UnsupportedCodegenAbi;
    if (call.ret_attrs != null or call.attrs != null) return error.UnsupportedCodegenAbi;
    if (call.callee_function_ty) |function_ty| {
        if (std.mem.indexOf(u8, function_ty, "...") != null) return error.UnsupportedCodegenAbi;
    }
    if (sysvScalarCallNeedsStackArgs(call)) return error.UnsupportedLiveAcrossCall;
}

fn fpVoidCallTarget(function: ir.Function, call: ir.CallInst) !SysVCallTarget {
    return if (call.callee_value) |callee_value| blk: {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        break :blk .{ .indirect_from_reg = try paramReg(function, callee_name, .ptr) };
    } else .{ .direct = call.callee };
}

fn repeatedFpVoidCallPreservedCallee(function: ir.Function, block: ir.BasicBlock, call_count: usize) !?shared.ArgReg {
    if (call_count < 2) return null;
    var preserved: ?shared.ArgReg = null;
    for (block.instructions.items[0..call_count], 0..) |instruction, index| {
        const call = instruction.kind.call;
        const target = try fpVoidCallTarget(function, call);
        switch (target) {
            .direct => {},
            .indirect_from_reg => |reg| {
                if (index == 0 and call_count == 1) return null;
                if (preserved) |existing| {
                    if (existing != reg) return error.UnsupportedLiveAcrossCall;
                } else {
                    preserved = reg;
                }
            },
        }
    }
    return preserved;
}

pub fn collectFpVoidCallFaddParamChain(function: ir.Function, block: ir.BasicBlock, first_binary_index: usize, ret_value: ir.Value) !usize {
    if (first_binary_index >= block.instructions.items.len) return error.UnsupportedCodegenInstruction;
    const binary_count = block.instructions.items.len - first_binary_index;
    if (binary_count < 1 or binary_count > 5) return error.UnsupportedCodegenInstruction;

    var addend_seen = [_]bool{false} ** 6;
    var addend_count: usize = 0;
    var previous_name: ?[]const u8 = null;

    for (block.instructions.items[first_binary_index..], 0..) |instruction, index| {
        if (instruction.removed) return error.UnsupportedCodegenInstruction;
        const result_name = instruction.result orelse return error.UnsupportedCodegenInstruction;
        if (index == binary_count - 1 and !isNamed(ret_value, result_name)) return error.UnsupportedCodegenInstruction;
        const binary = switch (instruction.kind) {
            .binary => |binary| binary,
            else => return error.UnsupportedCodegenInstruction,
        };
        if (binary.op != .fadd or !binary.ty.eql(function.ret_ty)) return error.UnsupportedCodegenInstruction;
        if (index == 0) {
            const lhs_name = switch (binary.lhs) {
                .named => |name| name,
                .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
            };
            const rhs_name = switch (binary.rhs) {
                .named => |name| name,
                .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
            };
            try noteFpAddendIndex(function, lhs_name, &addend_seen, &addend_count);
            try noteFpAddendIndex(function, rhs_name, &addend_seen, &addend_count);
        } else {
            const previous = previous_name orelse return error.UnsupportedCodegenInstruction;
            const lhs_is_previous = isNamed(binary.lhs, previous);
            const rhs_is_previous = isNamed(binary.rhs, previous);
            if (lhs_is_previous == rhs_is_previous) return error.UnsupportedCodegenInstruction;
            const next_value = if (lhs_is_previous) binary.rhs else binary.lhs;
            const next_name = switch (next_value) {
                .named => |name| name,
                .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
            };
            try noteFpAddendIndex(function, next_name, &addend_seen, &addend_count);
        }
        previous_name = result_name;
    }

    var expected: usize = 0;
    while (expected < addend_count) : (expected += 1) {
        if (!addend_seen[expected]) return error.UnsupportedLiveAcrossCall;
    }
    return addend_count;
}

pub fn noteFpAddendIndex(function: ir.Function, name: []const u8, seen: *[6]bool, count: *usize) !void {
    const index = try fpParamIndex(function, name, function.ret_ty);
    if (index >= seen.len) return error.UnsupportedLiveAcrossCall;
    if (seen[index]) return error.UnsupportedLiveAcrossCall;
    seen[index] = true;
    count.* += 1;
}

pub fn fpLiveAddendFrameBytes(ty: ir.Type, addend_count: usize, preserve_callee: bool) !u8 {
    if (addend_count < 2 or addend_count > 6) return error.UnsupportedLiveAcrossCall;
    if (ty.eql(.float)) {
        const base: u8 = if (addend_count == 2) 8 else if (addend_count <= 4) 24 else 40;
        if (!preserve_callee) return base;
        return if (base < 24) 24 else base;
    }
    if (ty.eql(.double)) {
        const base: u8 = if (addend_count == 2) 24 else if (addend_count <= 4) 40 else 56;
        if (!preserve_callee) return base;
        return if (base < 40) 40 else base;
    }
    return error.UnsupportedCodegenType;
}

fn frameIndexForFpPreservedCallee(ty: ir.Type, addend_count: usize) !FrameIndex {
    if (ty.eql(.float)) {
        return switch (addend_count) {
            2 => .slot2,
            3, 4 => .slot4,
            5, 6 => .slot6,
            else => error.UnsupportedLiveAcrossCall,
        };
    }
    if (ty.eql(.double)) {
        return switch (addend_count) {
            2 => .slot4,
            3, 4 => .slot8,
            else => error.UnsupportedLiveAcrossCall,
        };
    }
    return error.UnsupportedCodegenType;
}

pub fn frameIndexForFpLiveAddend(ty: ir.Type, index: usize) !FrameIndex {
    if (ty.eql(.float)) {
        return frameIndexForLiveParam(index);
    }
    if (!ty.eql(.double)) return error.UnsupportedCodegenType;
    return switch (index) {
        0 => .slot0,
        1 => .slot2,
        2 => .slot4,
        3 => .slot6,
        4 => .slot8,
        5 => .slot10,
        else => error.UnsupportedLiveAcrossCall,
    };
}

pub fn lowerGenericCfgFpParamReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if ((!function.ret_ty.eql(.float) and !function.ret_ty.eql(.double)) or !ret.ty.eql(function.ret_ty)) return false;
    if (block.instructions.items.len != 0) return false;
    const name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const fp_index = try fpParamIndex(function, name, function.ret_ty);
    switch (fp_index) {
        0 => {},
        1 => {
            if (!function.ret_ty.eql(.double)) return error.UnsupportedCodegenAbi;
            try machine.instructions.append(allocator, .movapd_xmm1_xmm0);
        },
        else => return error.UnsupportedCodegenAbi,
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgFpLiteralReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    ret: anytype,
) !bool {
    if (function.params.items.len != 0) return false;
    const value = switch (ret.value orelse return false) {
        .fp => |fp| fp,
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (function.ret_ty.eql(.double) and ret.ty.eql(.double)) {
        try machine.instructions.append(allocator, .{ .mov_imm64_xmm0 = try fp64TextBits(.{ .fp = value }) });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    if (function.ret_ty.eql(.float) and ret.ty.eql(.float)) {
        try machine.instructions.append(allocator, .{ .mov_imm32_xmm0 = try fp32TextBits(.{ .fp = value }) });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    return false;
}
