const shared = @import("core_shared.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");
const cabi_call_lowering = @import("cabi_call_lowering.zig");
const cabi_aggregate_lowering = @import("cabi_aggregate_lowering.zig");

const std = shared.std;
const ir = shared.ir;
const MachineFunction = shared.MachineFunction;
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

pub fn lowerGenericCfgFpVoidCallBinaryReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if ((!function.ret_ty.eql(.float) and !function.ret_ty.eql(.double)) or !ret.ty.eql(function.ret_ty) or
        block.instructions.items.len < 2 or block.instructions.items.len > 6) return false;
    const call_inst = block.instructions.items[0];
    if (call_inst.removed) return false;

    const call = switch (call_inst.kind) {
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

    const addend_count = try collectFpVoidCallFaddParamChain(function, block, ret.value orelse return error.InvalidRet);
    if (addend_count < 2 or addend_count > 6) return error.UnsupportedLiveAcrossCall;

    const frame_bytes = try fpLiveAddendFrameBytes(function.ret_ty, addend_count);
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
    try setupSysVCallTarget(allocator, machine, call_target);
    _ = try appendSysVScalarCallArgs(allocator, machine, function, call);
    try appendSysVCallTarget(allocator, machine, call_target, call.ret_ty);
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

pub fn collectFpVoidCallFaddParamChain(function: ir.Function, block: ir.BasicBlock, ret_value: ir.Value) !usize {
    const binary_count = block.instructions.items.len - 1;
    if (binary_count < 1 or binary_count > 5) return error.UnsupportedCodegenInstruction;

    var addend_seen = [_]bool{false} ** 6;
    var addend_count: usize = 0;
    var previous_name: ?[]const u8 = null;

    for (block.instructions.items[1..], 0..) |instruction, index| {
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

pub fn fpLiveAddendFrameBytes(ty: ir.Type, addend_count: usize) !u8 {
    if (addend_count < 2 or addend_count > 6) return error.UnsupportedLiveAcrossCall;
    if (ty.eql(.float)) {
        return if (addend_count == 2) 8 else if (addend_count <= 4) 24 else 40;
    }
    if (ty.eql(.double)) {
        return if (addend_count == 2) 24 else if (addend_count <= 4) 40 else 56;
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
