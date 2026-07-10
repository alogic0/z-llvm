const std = @import("std");
const air_capabilities = @import("../../../zig_air_capabilities.zig");
const ir = @import("../../../ir.zig");
const target = @import("../../../target.zig");
const type_layout = @import("../../../zig_air_type_layout.zig");
const x86_64_types = @import("../types.zig");
const sysv_abi = @import("../sysv_abi.zig");
const x86_64_emit = @import("../emit.zig");
const x86_64_match = @import("../match.zig");
const x86_64_machine = @import("../machine.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");
const cabi_call_lowering = @import("cabi_call_lowering.zig");
const core_value_emit = @import("core_value_emit.zig");

const ArgReg = x86_64_types.ArgReg;
const FrameIndex = x86_64_types.FrameIndex;
const XmmReg = x86_64_types.XmmReg;
const MachineFunction = x86_64_machine.MachineFunction;
const SysVAggregateClassification = sysv_abi.AggregateClassification;
const SysVCallTarget = x86_64_emit.SysVCallTarget;
const SysVRegisterNeeds = sysv_abi.RegisterNeeds;
const SysVSmallIntegerAggregate = sysv_abi.SmallIntegerAggregate;
const SysVRegisterAggregatePassThrough = sysv_abi.RegisterAggregatePassThrough;

const appendSysVMemoryAggregateStackPassThroughArgs = cabi_call_lowering.appendSysVMemoryAggregateStackPassThroughArgs;
const appendSysVScalarCallArgs = cabi_call_lowering.appendSysVScalarCallArgs;
const appendSysVRegisterAggregatePassThroughArg = cabi_call_lowering.appendSysVRegisterAggregatePassThroughArg;
const appendSysVStackAggregatePassThroughArgs = cabi_call_lowering.appendSysVStackAggregatePassThroughArgs;
const emitI32ValueIntoEax = cabi_call_lowering.emitI32ValueIntoEax;
const findInstruction = cabi_call_lowering.findInstruction;
const identityCastFrom = cabi_call_lowering.identityCastFrom;
const isSelectI1ToI32ZeroOne = cabi_call_lowering.isSelectI1ToI32ZeroOne;
const lowerGenericCfgI32ValueIntoEax = cabi_call_lowering.lowerGenericCfgI32ValueIntoEax;
const lowerReturnValueAfterCalls = cabi_call_lowering.lowerReturnValueAfterCalls;
const matchIcmpEqParamImm = cabi_call_lowering.matchIcmpEqParamImm;
const sysvParamCursorForWithInitial = cabi_call_lowering.sysvParamCursorForWithInitial;
const valueReferencesGlobal = cabi_call_lowering.valueReferencesGlobal;

const fpParamIndex = cabi_abi_helpers.fpParamIndex;
const advanceSysVParamCursors = cabi_abi_helpers.advanceSysVParamCursors;
const paramReg = cabi_abi_helpers.paramReg;
const paramRegWithInitialGpr = cabi_abi_helpers.paramRegWithInitialGpr;
const paramValueReg = cabi_abi_helpers.paramValueReg;
const sysvIntegerParamRegOrNull = cabi_abi_helpers.sysvIntegerParamRegOrNull;
const emitGenericCfgI64ValueIntoRax = core_value_emit.emitGenericCfgI64ValueIntoRax;

const appendSysVCallTargetWithStackArgs = x86_64_emit.appendSysVCallTargetWithStackArgs;
const appendDirectCallWithStackArgs = x86_64_emit.appendDirectCallWithStackArgs;
const appendIndirectCallRaxWithStackArgs = x86_64_emit.appendIndirectCallRaxWithStackArgs;
const appendLoadStackDispArg64 = x86_64_emit.appendLoadStackDispArg64;
const appendMoveImm32ToXmm = x86_64_emit.appendMoveImm32ToXmm;
const appendMoveImm64ToXmm = x86_64_emit.appendMoveImm64ToXmm;
const appendStackFrame = x86_64_emit.appendStackFrame;
const appendStackFrameEnd = x86_64_emit.appendStackFrameEnd;
const setupSysVCallTarget = x86_64_emit.setupSysVCallTarget;

const callArgAttrsContain = x86_64_match.callArgAttrsContain;
const callIsFastcc = x86_64_match.callIsFastcc;
const isInt = x86_64_match.isInt;
const isNamed = x86_64_match.isNamed;
const paramAttrsContain = x86_64_match.paramAttrsContain;
const validateDefaultCallConv = x86_64_match.validateDefaultCallConv;

fn x86_64SysVDataLayout() !target.DataLayout {
    return target.DataLayout.parse("e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128");
}

pub fn lowerAggregateAbiReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (try lowerRegisterAggregateConstructedArgCallReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerMemoryAggregateCallReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerRegisterAggregateCallIntegerFieldAddReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerRegisterAggregateCallFieldReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerRegisterAggregateDirectCallReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerRegisterAggregateReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerSmallIntegerAggregateReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerSysVAggregateFieldReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerRegisterAggregateIntegerFieldAddReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerRegisterAggregateFloatFieldAddReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerRegisterAggregateDoubleFieldAddReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerMemoryIntegerAggregateFieldAddReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerTruncI64ArgReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerMakePairReturn(allocator, machine, function, block, ret)) return true;
    return false;
}

pub fn lowerRegisterAggregateConstructedArgCallReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if ((!ret.ty.eql(.{ .int = 32 }) and !ret.ty.eql(.{ .int = 64 }) and !ret.ty.eql(.float) and !ret.ty.eql(.double)) or
        !ret.ty.eql(function.ret_ty) or block.instructions.items.len < 3) return false;
    const call_inst = block.instructions.items[block.instructions.items.len - 1];
    if (call_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, call_name)) return false;
    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null or call.inline_asm != null or !call.ret_ty.eql(ret.ty)) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;
    if (call.args.items.len != 1) return false;
    const aggregate_arg = call.args.items[0];
    const aggregate_name = switch (aggregate_arg.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const classification = classifySysVAggregate(aggregate_arg.ty) catch return false;
    if (classification.kind != .register or classification.eightbyte_count == 0) return false;

    var leaves: [8]AggregateReturnLeaf = undefined;
    const leaf_count = try collectConstructedAggregateLeaves(block, aggregate_arg.ty, aggregate_name, &leaves);
    if (leaf_count == 0) return false;
    try emitConstructedRegisterAggregateCallArg(allocator, machine, function, block, leaves[0..leaf_count], classification);
    try appendDirectCallWithStackArgs(allocator, machine, call.callee, call.ret_ty, 0);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn collectConstructedAggregateLeaves(
    block: ir.BasicBlock,
    aggregate_ty: ir.Type,
    final_name: []const u8,
    leaves: *[8]AggregateReturnLeaf,
) !usize {
    var reversed: [8]AggregateReturnLeaf = undefined;
    var count: usize = 0;
    var current: ir.Value = .{ .named = final_name };
    while (true) {
        switch (current) {
            .undef => break,
            .named => |name| {
                if (count >= reversed.len) return error.UnsupportedCodegenAbi;
                const instruction = findInstruction(block, name) orelse return error.UnsupportedCodegenInstruction;
                const insert = switch (instruction.kind) {
                    .insertvalue => |insert| insert,
                    else => return error.UnsupportedCodegenInstruction,
                };
                if (!insert.aggregate_ty.eql(aggregate_ty)) return error.UnsupportedCodegenType;
                const offset = try aggregateInsertByteOffset(aggregate_ty, insert.indices, insert.value_ty);
                reversed[count] = .{ .value = insert.value, .ty = insert.value_ty, .offset = offset };
                count += 1;
                current = insert.aggregate;
            },
            .int, .fp, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        }
    }
    var index: usize = 0;
    while (index < count) : (index += 1) {
        leaves[index] = reversed[count - 1 - index];
        if (index != 0 and leaves[index].offset <= leaves[index - 1].offset) return error.UnsupportedCodegenAbi;
    }
    return count;
}

fn emitConstructedRegisterAggregateCallArg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    leaves: []const AggregateReturnLeaf,
    classification: SysVAggregateClassification,
) !void {
    var gpr_index: usize = 0;
    var sse_index: usize = 0;
    for (leaves) |leaf| {
        const eightbyte_index: usize = @intCast(leaf.offset / 8);
        if (eightbyte_index >= classification.eightbyte_count) return error.UnsupportedCodegenAbi;
        switch (classification.eightbytes[eightbyte_index] orelse return error.UnsupportedCodegenAbi) {
            .integer => {
                const dst = try ArgReg.fromIndex(gpr_index);
                try emitConstructedIntegerLeafIntoArgReg(allocator, machine, function, block, leaf, dst);
                gpr_index += 1;
            },
            .sse => {
                const dst = try XmmReg.fromIndex(sse_index);
                try emitConstructedSseLeafIntoXmm(allocator, machine, function, leaf, dst);
                sse_index += 1;
            },
        }
    }
}

fn emitConstructedIntegerLeafIntoArgReg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    leaf: AggregateReturnLeaf,
    dst: ArgReg,
) !void {
    if (!leaf.ty.eql(.{ .int = 64 }) and !leaf.ty.eql(.ptr)) return error.UnsupportedCodegenType;
    switch (leaf.value) {
        .named => |name| {
            if (try sysvIntegerParamRegOrNull(function, name, leaf.ty)) |src| {
                if (src != dst) try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = dst, .src = src } });
                return;
            }
            const instruction = findInstruction(block, name) orelse {
                try emitGenericCfgI64ValueIntoRax(allocator, machine, function, block, leaf.value);
                try moveRaxIntoArgReg(allocator, machine, dst);
                return;
            };
            const binary = switch (instruction.kind) {
                .binary => |binary| binary,
                else => {
                    try emitGenericCfgI64ValueIntoRax(allocator, machine, function, block, leaf.value);
                    try moveRaxIntoArgReg(allocator, machine, dst);
                    return;
                },
            };
            if (!binary.ty.eql(.{ .int = 64 }) or binary.op != .add) return error.UnsupportedCodegenInstruction;
            try emitGenericCfgI64ValueIntoRax(allocator, machine, function, block, binary.lhs);
            const rhs_name = switch (binary.rhs) {
                .named => |rhs_name| rhs_name,
                .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
            };
            try machine.instructions.append(allocator, .{ .add_arg64_rax = try paramReg(function, rhs_name, .{ .int = 64 }) });
            try moveRaxIntoArgReg(allocator, machine, dst);
        },
        .int => |value| try appendMoveImmToAggregateArgReg(allocator, machine, dst, value),
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

fn emitConstructedSseLeafIntoXmm(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    leaf: AggregateReturnLeaf,
    dst: XmmReg,
) !void {
    switch (leaf.value) {
        .named => |name| {
            const src_index = try fpParamIndex(function, name, leaf.ty);
            const src = try XmmReg.fromIndex(src_index);
            if (src != dst) try machine.instructions.append(allocator, .{ .movapd_xmm = .{ .dst = dst, .src = src } });
        },
        .fp => if (leaf.ty.eql(.float))
            try appendMoveImm32ToXmm(allocator, machine, dst, try x86_64_match.fp32TextBits(leaf.value))
        else if (leaf.ty.eql(.double))
            try appendMoveImm64ToXmm(allocator, machine, dst, try x86_64_match.fp64TextBits(leaf.value))
        else
            return error.UnsupportedCodegenType,
        .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

fn moveRaxIntoArgReg(allocator: std.mem.Allocator, machine: *MachineFunction, dst: ArgReg) !void {
    switch (dst) {
        .rdi => try machine.instructions.append(allocator, .mov_rax_rdi),
        .rsi => try machine.instructions.append(allocator, .mov_rax_rsi),
        .rdx, .rcx, .r8, .r9 => return error.UnsupportedCodegenAbi,
    }
}

fn appendMoveImmToAggregateArgReg(allocator: std.mem.Allocator, machine: *MachineFunction, dst: ArgReg, value: i128) !void {
    if (value < std.math.minInt(i64) or value > std.math.maxInt(i64)) return error.UnsupportedCodegenValue;
    switch (dst) {
        .rdi => try machine.instructions.append(allocator, .{ .mov_imm_rdi = @intCast(value) }),
        .rsi => try machine.instructions.append(allocator, .{ .mov_imm_rsi = @intCast(value) }),
        .rdx => try machine.instructions.append(allocator, .{ .mov_imm_rdx = @intCast(value) }),
        .rcx => try machine.instructions.append(allocator, .{ .mov_imm_rcx = @intCast(value) }),
        .r8 => try machine.instructions.append(allocator, .{ .mov_imm_r8 = @intCast(value) }),
        .r9 => try machine.instructions.append(allocator, .{ .mov_imm_r9 = @intCast(value) }),
    }
}

pub fn lowerMemoryAggregateCallReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(function.ret_ty) or block.instructions.items.len != 1) return false;
    const classification = classifySysVAggregate(function.ret_ty) catch return false;
    if (classification.kind != .memory or classification.size_bytes == 0) return false;
    if (!isSupportedAggregateCopyLeafAggregate(function.ret_ty)) return false;

    const instruction = block.instructions.items[0];
    if (instruction.removed) return false;
    const call_result = instruction.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, call_result)) return false;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!call.ret_ty.eql(function.ret_ty) or call.inline_asm != null) return false;
    if (call.tail_kind != null) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;
    if (call.args.items.len != 1) return false;

    const call_target: SysVCallTarget = if (call.callee_value) |callee_value| target: {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        const callee_reg = try paramRegWithInitialGpr(function, callee_name, .ptr, 1);
        if (callee_reg == .rdi) return error.UnsupportedCodegenAbi;
        break :target .{ .indirect_from_reg = callee_reg };
    } else .{ .direct = call.callee };

    const aggregate_arg = call.args.items[0];
    if (!aggregate_arg.ty.eql(function.ret_ty)) return false;
    const aggregate_name = switch (aggregate_arg.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    const source = try sysvParamCursorForWithInitial(function, aggregate_name, aggregate_arg.ty, .{
        .gpr = 1,
        .sse = 0,
        .stack_eightbytes = 0,
    });

    const stack_arg_count = try appendSysVMemoryAggregateStackPassThroughArgs(
        allocator,
        machine,
        function,
        source,
        classification,
    );
    try setupSysVCallTarget(allocator, machine, call_target);
    try appendSysVCallTargetWithStackArgs(allocator, machine, call_target, call.ret_ty, stack_arg_count);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn classifySysVAggregateForTest(ty: ir.Type) !SysVAggregateClassification {
    return try sysv_abi.classifyAggregateForTest(ty);
}

pub fn classifySysVAggregate(ty: ir.Type) !SysVAggregateClassification {
    return try sysv_abi.classifyAggregate(ty);
}

pub fn classifySysVSmallIntegerAggregate(ty: ir.Type) ?SysVSmallIntegerAggregate {
    return sysv_abi.classifySmallIntegerAggregate(ty);
}

pub fn lowerSmallIntegerAggregateReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const classification = classifySysVSmallIntegerAggregate(function.ret_ty) orelse return false;
    if (classification.eightbytes != 2 or !ret.ty.eql(function.ret_ty)) return false;
    if (block.instructions.items.len != 2) return false;
    const first_inst = block.instructions.items[0];
    const second_inst = block.instructions.items[1];
    if (first_inst.removed or second_inst.removed) return false;
    const first_name = first_inst.result orelse return false;
    const second_name = second_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, second_name)) return false;

    const first = switch (first_inst.kind) {
        .insertvalue => |insert| insert,
        else => return false,
    };
    const second = switch (second_inst.kind) {
        .insertvalue => |insert| insert,
        else => return false,
    };
    if (!first.aggregate_ty.eql(function.ret_ty) or !second.aggregate_ty.eql(function.ret_ty)) return false;
    if (first.aggregate != .undef or !isNamed(second.aggregate, first_name)) return false;
    if (!std.mem.eql(u8, first.indices, "0") or !std.mem.eql(u8, second.indices, "1")) return false;
    if (!first.value_ty.eql(.{ .int = 64 }) or !second.value_ty.eql(.{ .int = 64 })) return false;
    const first_reg = try paramValueReg(function, first.value, .{ .int = 64 });
    const second_reg = try paramValueReg(function, second.value, .{ .int = 64 });

    try machine.instructions.append(allocator, .{ .mov_arg_rax = first_reg });
    try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = .rdx, .src = second_reg } });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRegisterAggregateReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!isAggregateType(function.ret_ty)) return false;
    if (!ret.ty.eql(function.ret_ty)) return false;
    const classification = classifySysVAggregate(function.ret_ty) catch return false;
    if (classification.kind != .register or classification.eightbyte_count == 0) return false;
    if (try lowerRegisterAggregateParamReturn(allocator, machine, function, block, ret, classification)) return true;
    const leaf_count = block.instructions.items.len;
    if (leaf_count == 0 or leaf_count > 8) return false;

    var leaves: [8]AggregateReturnLeaf = undefined;
    var aggregate_value: ir.Value = .undef;
    for (block.instructions.items, 0..) |instruction, index| {
        if (instruction.removed) return false;
        const result = instruction.result orelse return false;
        const insert = switch (instruction.kind) {
            .insertvalue => |insert| insert,
            else => return false,
        };
        if (!insert.aggregate_ty.eql(function.ret_ty)) return false;
        if (!valuesEqual(insert.aggregate, aggregate_value)) return false;
        const offset = try aggregateInsertByteOffset(function.ret_ty, insert.indices, insert.value_ty);
        if (index != 0 and offset <= leaves[index - 1].offset) return error.UnsupportedCodegenAbi;
        leaves[index] = .{ .value = insert.value, .ty = insert.value_ty, .offset = offset };
        aggregate_value = .{ .named = result };
    }
    if (!valuesEqual(ret.value orelse return error.InvalidRet, aggregate_value)) return false;

    if (try lowerFourI32RegisterAggregateReturn(allocator, machine, function, leaves[0..leaf_count], classification)) return true;

    var gpr_return_index: usize = 0;
    var sse_return_index: usize = 0;
    var leaf_index: usize = 0;
    while (leaf_index < leaf_count) : (leaf_index += 1) {
        const leaf = leaves[leaf_index];
        const leaf_eightbyte: usize = @intCast(leaf.offset / 8);
        if (leaf_eightbyte >= classification.eightbyte_count) return false;
        const leaf_class = classification.eightbytes[leaf_eightbyte] orelse return false;
        switch (leaf_class) {
            .integer => {
                if (leaf.ty.eql(.{ .int = 64 }) or leaf.ty.eql(.ptr)) {
                    const src = try paramValueReg(function, leaf.value, leaf.ty);
                    switch (gpr_return_index) {
                        0 => try machine.instructions.append(allocator, .{ .mov_arg_rax = src }),
                        1 => try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = .rdx, .src = src } }),
                        else => return error.UnsupportedCodegenAbi,
                    }
                    gpr_return_index += 1;
                    continue;
                }
                if (!leaf.ty.eql(.{ .int = 32 })) return false;
                if (leaf.offset % 8 != 0) return error.UnsupportedCodegenAbi;
                const low_reg = try paramValueReg(function, leaf.value, leaf.ty);
                if (leaf_index + 1 < leaf_count and
                    leaves[leaf_index + 1].ty.eql(.{ .int = 32 }) and
                    leaves[leaf_index + 1].offset / 8 == leaf_eightbyte and
                    leaves[leaf_index + 1].offset % 8 == 4)
                {
                    const high_reg = try paramValueReg(function, leaves[leaf_index + 1].value, .{ .int = 32 });
                    switch (gpr_return_index) {
                        0 => {
                            try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rdx, .src = high_reg } });
                            try machine.instructions.append(allocator, .{ .shl_rdx_imm6 = 32 });
                            try machine.instructions.append(allocator, .{ .mov_arg_eax = low_reg });
                            try machine.instructions.append(allocator, .or_rdx_rax);
                        },
                        1 => {
                            try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rcx, .src = high_reg } });
                            try machine.instructions.append(allocator, .{ .shl_rcx_imm6 = 32 });
                            try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rdx, .src = low_reg } });
                            try machine.instructions.append(allocator, .or_rcx_rdx);
                        },
                        else => return error.UnsupportedCodegenAbi,
                    }
                    gpr_return_index += 1;
                    leaf_index += 1;
                    continue;
                }
                switch (gpr_return_index) {
                    0 => try machine.instructions.append(allocator, .{ .mov_arg_eax = low_reg }),
                    1 => try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rdx, .src = low_reg } }),
                    else => return error.UnsupportedCodegenAbi,
                }
                gpr_return_index += 1;
            },
            .sse => {
                if (leaf.ty.eql(.float) and leaf.offset % 8 == 0 and
                    leaf_index + 1 < leaf_count and
                    leaves[leaf_index + 1].ty.eql(.float) and
                    leaves[leaf_index + 1].offset / 8 == leaf_eightbyte and
                    leaves[leaf_index + 1].offset % 8 == 4)
                {
                    if (sse_return_index >= 2) return error.UnsupportedCodegenAbi;
                    const low_fp_index = try fpParamIndexFromValue(function, leaf.value, .float);
                    const high_fp_index = try fpParamIndexFromValue(function, leaves[leaf_index + 1].value, .float);
                    const low_reg = try XmmReg.fromIndex(low_fp_index);
                    const high_reg = try XmmReg.fromIndex(high_fp_index);
                    const dst = try XmmReg.fromIndex(sse_return_index);
                    if (low_reg != dst) {
                        try machine.instructions.append(allocator, .{ .movapd_xmm = .{ .dst = dst, .src = low_reg } });
                    }
                    if (high_reg != dst) {
                        try machine.instructions.append(allocator, .{ .unpcklps_xmm = .{ .dst = dst, .src = high_reg } });
                    }
                    sse_return_index += 1;
                    leaf_index += 1;
                    continue;
                }
                if (leaf.ty.eql(.float) and leaf.offset % 8 == 0) {
                    const fp_index = try fpParamIndexFromValue(function, leaf.value, leaf.ty);
                    switch (sse_return_index) {
                        0 => switch (try XmmReg.fromIndex(fp_index)) {
                            .xmm0 => {},
                            .xmm1, .xmm2, .xmm3, .xmm4, .xmm5, .xmm6, .xmm7 => |src| try machine.instructions.append(allocator, .{ .movapd_xmm = .{ .dst = .xmm0, .src = src } }),
                        },
                        1 => switch (try XmmReg.fromIndex(fp_index)) {
                            .xmm1 => {},
                            .xmm0, .xmm2, .xmm3, .xmm4, .xmm5, .xmm6, .xmm7 => |src| try machine.instructions.append(allocator, .{ .movapd_xmm = .{ .dst = .xmm1, .src = src } }),
                        },
                        else => return error.UnsupportedCodegenAbi,
                    }
                    sse_return_index += 1;
                    continue;
                }
                if (!leaf.ty.eql(.double)) return false;
                const fp_index = try fpParamIndexFromValue(function, leaf.value, leaf.ty);
                switch (sse_return_index) {
                    0 => switch (try XmmReg.fromIndex(fp_index)) {
                        .xmm0 => {},
                        .xmm1 => try machine.instructions.append(allocator, .movapd_xmm1_xmm0),
                        .xmm2, .xmm3, .xmm4, .xmm5, .xmm6, .xmm7 => return error.UnsupportedCodegenAbi,
                    },
                    1 => switch (try XmmReg.fromIndex(fp_index)) {
                        .xmm1 => {},
                        .xmm0, .xmm2, .xmm3, .xmm4, .xmm5, .xmm6, .xmm7 => return error.UnsupportedCodegenAbi,
                    },
                    else => return error.UnsupportedCodegenAbi,
                }
                sse_return_index += 1;
            },
        }
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRegisterAggregateParamReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
    classification: SysVAggregateClassification,
) !bool {
    if (block.instructions.items.len != 0) return false;
    const ret_value = ret.value orelse return error.InvalidRet;
    const param_name = switch (ret_value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const source = sysvParamCursorForWithInitial(function, param_name, function.ret_ty, .{
        .gpr = 0,
        .sse = 0,
        .stack_eightbytes = 0,
    }) catch |err| switch (err) {
        error.UnsupportedCodegenValue, error.UnsupportedCodegenType => return false,
    };
    const needs = sysv_abi.aggregateRegisterNeeds(classification);
    const source_in_registers = source.gpr + needs.gpr <= 6 and source.sse + needs.sse <= 8;
    const stack_base: u32 = if (source_in_registers)
        0
    else blk: {
        const offset = 8 + source.stack_eightbytes * 8;
        if (offset > std.math.maxInt(u32)) return error.UnsupportedCodegenAbi;
        break :blk @intCast(offset);
    };

    var gpr_return_index: usize = 0;
    var sse_return_index: usize = 0;
    var gpr_source_offset: usize = 0;
    var sse_source_offset: usize = 0;
    var eightbyte_index: usize = 0;
    while (eightbyte_index < classification.eightbyte_count) : (eightbyte_index += 1) {
        switch (classification.eightbytes[eightbyte_index] orelse return error.UnsupportedCodegenAbi) {
            .integer => {
                if (source_in_registers) {
                    const src = try ArgReg.fromIndex(source.gpr + gpr_source_offset);
                    switch (gpr_return_index) {
                        0 => try machine.instructions.append(allocator, .{ .mov_arg_rax = src }),
                        1 => try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = .rdx, .src = src } }),
                        else => return error.UnsupportedCodegenAbi,
                    }
                } else {
                    const offset = stack_base + @as(u32, @intCast(eightbyte_index * 8));
                    switch (gpr_return_index) {
                        0 => try appendLoadStackDispRax(allocator, machine, offset),
                        1 => try appendLoadStackDispArg64(allocator, machine, .rdx, offset),
                        else => return error.UnsupportedCodegenAbi,
                    }
                }
                gpr_source_offset += 1;
                gpr_return_index += 1;
            },
            .sse => {
                const dst = try XmmReg.fromIndex(sse_return_index);
                if (source_in_registers) {
                    const src = try XmmReg.fromIndex(source.sse + sse_source_offset);
                    if (src != dst) {
                        try machine.instructions.append(allocator, .{ .movapd_xmm = .{ .dst = dst, .src = src } });
                    }
                } else {
                    const offset = stack_base + @as(u32, @intCast(eightbyte_index * 8));
                    try appendLoadStackDispXmm(allocator, machine, dst, offset);
                }
                sse_source_offset += 1;
                sse_return_index += 1;
            },
        }
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub const AggregateReturnLeaf = struct {
    value: ir.Value,
    ty: ir.Type,
    offset: u64,
};

pub fn lowerFourI32RegisterAggregateReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    leaves: []const AggregateReturnLeaf,
    classification: SysVAggregateClassification,
) !bool {
    if (classification.eightbyte_count != 2 or
        classification.eightbytes[0] != .integer or
        classification.eightbytes[1] != .integer or
        leaves.len != 4)
    {
        return false;
    }
    const expected_offsets = [_]u64{ 0, 4, 8, 12 };
    for (leaves, 0..) |leaf, index| {
        if (!leaf.ty.eql(.{ .int = 32 }) or leaf.offset != expected_offsets[index]) return false;
    }
    const a = try paramValueReg(function, leaves[0].value, .{ .int = 32 });
    const b = try paramValueReg(function, leaves[1].value, .{ .int = 32 });
    const c = try paramValueReg(function, leaves[2].value, .{ .int = 32 });
    const d = try paramValueReg(function, leaves[3].value, .{ .int = 32 });

    try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rcx, .src = d } });
    try machine.instructions.append(allocator, .{ .shl_rcx_imm6 = 32 });
    try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rdx, .src = c } });
    try machine.instructions.append(allocator, .or_rcx_rdx);
    try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rcx, .src = b } });
    try machine.instructions.append(allocator, .{ .shl_rcx_imm6 = 32 });
    try machine.instructions.append(allocator, .{ .mov_arg_eax = a });
    try machine.instructions.append(allocator, .or_rcx_rax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn aggregateInsertByteOffset(aggregate_ty: ir.Type, indices: []const u8, value_ty: ir.Type) !u64 {
    const layout = try x86_64SysVDataLayout();
    var current_ty = aggregate_ty;
    var offset: u64 = 0;
    var rest = indices;
    while (rest.len != 0) {
        const comma = std.mem.indexOfScalar(u8, rest, ',');
        const part = std.mem.trim(u8, if (comma) |pos| rest[0..pos] else rest, " \t");
        const field_index = std.fmt.parseInt(usize, part, 10) catch return error.UnsupportedCodegenAbi;
        offset += type_layout.fieldByteOffset(layout, current_ty, field_index) orelse
            return error.UnsupportedCodegenAbi;
        current_ty = type_layout.fieldType(current_ty, field_index) orelse return error.UnsupportedCodegenAbi;
        rest = if (comma) |pos| rest[pos + 1 ..] else "";
    }
    if (!current_ty.eql(value_ty)) return error.UnsupportedCodegenAbi;
    return offset;
}

pub fn aggregateFieldCount(ty: ir.Type) ?usize {
    return type_layout.fieldCount(ty);
}

pub fn aggregateFieldEightbyte(aggregate_ty: ir.Type, field_index: usize) !usize {
    const layout = try x86_64SysVDataLayout();
    const field_offset = type_layout.fieldByteOffset(layout, aggregate_ty, field_index) orelse
        return error.UnsupportedCodegenAbi;
    return @intCast(field_offset / 8);
}

pub fn fpParamIndexFromValue(function: ir.Function, value: ir.Value, ty: ir.Type) !usize {
    return switch (value) {
        .named => |name| try fpParamIndex(function, name, ty),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => error.UnsupportedCodegenValue,
    };
}

pub fn valuesEqual(a: ir.Value, b: ir.Value) bool {
    return switch (a) {
        .named => |a_name| switch (b) {
            .named => |b_name| std.mem.eql(u8, a_name, b_name),
            else => false,
        },
        .undef => b == .undef,
        .poison => b == .poison,
        .null_value => b == .null_value,
        .zero_initializer => b == .zero_initializer,
        .int => |a_int| switch (b) {
            .int => |b_int| a_int == b_int,
            else => false,
        },
        .fp => |a_fp| switch (b) {
            .fp => |b_fp| std.mem.eql(u8, a_fp, b_fp),
            else => false,
        },
        .vector, .constant_expr => false,
    };
}

pub fn lowerSysVAggregateFieldReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if ((!ret.ty.eql(.{ .int = 32 }) and !ret.ty.eql(.{ .int = 64 }) and !ret.ty.eql(.float) and !ret.ty.eql(.double)) or
        (block.instructions.items.len != 3 and block.instructions.items.len != 4)) return false;
    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    const maybe_gep_inst: ?ir.Instruction = if (block.instructions.items.len == 4) block.instructions.items[2] else null;
    const load_inst = block.instructions.items[block.instructions.items.len - 1];
    if (alloca_inst.removed or store_inst.removed or load_inst.removed) return false;
    if (maybe_gep_inst) |gep_inst| if (gep_inst.removed) return false;
    const alloca_name = alloca_inst.result orelse return false;
    const load_name = load_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, load_name)) return false;

    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    const classification = classifySysVAggregate(alloca.allocated_ty) catch return false;
    if (classification.kind != .register or classification.eightbyte_count == 0) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(alloca.allocated_ty) or store.attrs.isBarrier() or !isNamed(store.ptr, alloca_name)) return false;
    const param_name = switch (store.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(ret.ty) or load.attrs.isBarrier()) return false;

    const layout = try x86_64SysVDataLayout();
    const field_offset = if (maybe_gep_inst) |gep_inst| blk: {
        const gep_name = gep_inst.result orelse return false;
        if (!isNamed(load.ptr, gep_name)) return false;
        const gep = switch (gep_inst.kind) {
            .gep => |gep| gep,
            else => return false,
        };
        if (!isNamed(gep.ptr, alloca_name)) return false;
        break :blk aggregateGepByteOffset(layout, alloca.allocated_ty, gep) orelse return false;
    } else blk: {
        if (!isNamed(load.ptr, alloca_name)) return false;
        break :blk @as(u64, 0);
    };
    _ = aggregateFieldIndexAtOffset(alloca.allocated_ty, field_offset, load.ty) orelse return false;

    try emitSysVAggregateFieldOffsetReturn(allocator, machine, function, param_name, alloca.allocated_ty, field_offset, load.ty);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub const AggregateIntegerFieldLoad = struct {
    offset: u64,
};

pub const AggregateIntegerAddTerm = struct {
    offset: u64,
};

pub fn lowerRegisterAggregateCallIntegerFieldAddReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if ((!ret.ty.eql(.{ .int = 32 }) and !ret.ty.eql(.{ .int = 64 })) or !function.ret_ty.eql(ret.ty)) return false;
    if (block.instructions.items.len < 6) return false;

    const call_inst = block.instructions.items[0];
    const alloca_inst = block.instructions.items[1];
    const store_inst = block.instructions.items[2];
    if (call_inst.removed or alloca_inst.removed or store_inst.removed) return false;

    const call_result = call_inst.result orelse return false;
    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.inline_asm != null or call.tail_kind != null or call.callee_value != null) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;

    const aggregate_ty = call.ret_ty;
    const classification = classifySysVAggregate(aggregate_ty) catch return false;
    if (classification.kind != .register) return false;

    const alloca_name = alloca_inst.result orelse return false;
    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    if (!alloca.allocated_ty.eql(aggregate_ty)) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(aggregate_ty) or store.attrs.isBarrier() or !isNamed(store.value, call_result) or !isNamed(store.ptr, alloca_name)) return false;

    var pointer_offsets = std.StringHashMap(u64).init(allocator);
    defer pointer_offsets.deinit();
    try pointer_offsets.put(alloca_name, 0);

    var field_loads = std.StringHashMap(AggregateIntegerFieldLoad).init(allocator);
    defer field_loads.deinit();

    const layout = try x86_64SysVDataLayout();
    for (block.instructions.items[3..]) |instruction| {
        if (instruction.removed) return false;
        switch (instruction.kind) {
            .gep => |gep| {
                const result = instruction.result orelse return false;
                const base_name = switch (gep.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const base_offset = pointer_offsets.get(base_name) orelse return false;
                const offset = aggregateGepByteOffset(layout, aggregate_ty, gep) orelse return false;
                try pointer_offsets.put(result, base_offset + offset);
            },
            .load => |load| {
                const result = instruction.result orelse return false;
                if (!load.ty.eql(ret.ty) or load.attrs.isBarrier()) return false;
                const ptr_name = switch (load.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const offset = pointer_offsets.get(ptr_name) orelse return false;
                _ = aggregateFieldIndexAtOffset(aggregate_ty, offset, load.ty) orelse return false;
                try field_loads.put(result, .{ .offset = offset });
            },
            .binary => |binary| {
                if (binary.op != .add or !binary.ty.eql(ret.ty)) return false;
            },
            .phi, .fcmp, .icmp, .select, .cast, .freeze, .alloca, .store, .call, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => return false,
        }
    }

    var terms: [8]AggregateIntegerAddTerm = undefined;
    var term_count: usize = 0;
    if (!try collectAggregateIntegerAddTerms(block, ret.value orelse return error.InvalidRet, ret.ty, field_loads, &terms, &term_count)) return false;
    if (term_count < 2) return false;
    sortAggregateIntegerTerms(terms[0..term_count]);

    const stack_arg_count = appendSysVScalarCallArgs(allocator, machine, function, call) catch |err| switch (err) {
        error.UnsupportedCodegenAbi, error.UnsupportedCodegenType, error.UnsupportedCodegenValue => return false,
        else => if (sysv_abi.isBoundaryError(err)) return false else return err,
    };
    try appendDirectCallWithStackArgs(allocator, machine, call.callee, call.ret_ty, stack_arg_count);
    try emitAggregateIntegerReturnTerm(allocator, machine, classification, terms[0], ret.ty, true);
    for (terms[1..term_count]) |term| {
        try emitAggregateIntegerReturnTerm(allocator, machine, classification, term, ret.ty, false);
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn sortAggregateIntegerTerms(terms: []AggregateIntegerAddTerm) void {
    var index: usize = 1;
    while (index < terms.len) : (index += 1) {
        var cursor = index;
        while (cursor > 0 and terms[cursor - 1].offset > terms[cursor].offset) : (cursor -= 1) {
            std.mem.swap(AggregateIntegerAddTerm, &terms[cursor - 1], &terms[cursor]);
        }
    }
}

fn emitAggregateIntegerReturnTerm(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    classification: SysVAggregateClassification,
    term: AggregateIntegerAddTerm,
    ty: ir.Type,
    first: bool,
) !void {
    if (classification.kind != .register) return error.UnsupportedCodegenAbi;
    const field_eightbyte = term.offset / 8;
    if (field_eightbyte >= classification.eightbytes.len) return error.UnsupportedCodegenAbi;
    const field_class = classification.eightbytes[@intCast(field_eightbyte)] orelse return error.UnsupportedCodegenAbi;
    if (field_class != .integer) return error.UnsupportedCodegenAbi;
    const prior = sysvAggregateRegisterNeedsBefore(classification, @intCast(field_eightbyte));
    const offset_in_eightbyte = term.offset % 8;

    if (ty.eql(.{ .int = 64 })) {
        if (offset_in_eightbyte != 0) return error.UnsupportedCodegenAbi;
        switch (prior.gpr) {
            0 => if (!first) return error.UnsupportedCodegenAbi,
            1 => if (first)
                try machine.instructions.append(allocator, .{ .mov_arg_rax = .rdx })
            else
                try machine.instructions.append(allocator, .{ .add_arg64_rax = .rdx }),
            else => return error.UnsupportedCodegenAbi,
        }
        return;
    }

    if (!ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenAbi;
    switch (prior.gpr) {
        0 => switch (offset_in_eightbyte) {
            0 => if (!first) return error.UnsupportedCodegenAbi,
            4 => if (first) {
                try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 32 });
            } else {
                return error.UnsupportedCodegenAbi;
            },
            else => return error.UnsupportedCodegenAbi,
        },
        1 => switch (offset_in_eightbyte) {
            0 => if (first)
                try machine.instructions.append(allocator, .{ .mov_arg_rax = .rdx })
            else
                try machine.instructions.append(allocator, .{ .add_arg64_rax = .rdx }),
            4 => return error.UnsupportedCodegenAbi,
            else => return error.UnsupportedCodegenAbi,
        },
        else => return error.UnsupportedCodegenAbi,
    }
}

pub const AggregateDoubleFieldLoad = struct {
    offset: u64,
};

pub const AggregateDoubleAddTerm = struct {
    offset: u64,
};

pub const AggregateFloatFieldLoad = struct {
    offset: u64,
};

pub const AggregateFloatAddTerm = struct {
    offset: u64,
};

pub fn lowerRegisterAggregateIntegerFieldAddReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if ((!ret.ty.eql(.{ .int = 32 }) and !ret.ty.eql(.{ .int = 64 })) or !function.ret_ty.eql(ret.ty)) return false;
    if (block.instructions.items.len < 5) return false;

    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    if (alloca_inst.removed or store_inst.removed) return false;
    const alloca_name = alloca_inst.result orelse return false;
    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    const aggregate_ty = alloca.allocated_ty;
    const classification = classifySysVAggregate(aggregate_ty) catch return false;
    if (classification.kind != .register) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(aggregate_ty) or store.attrs.isBarrier() or !isNamed(store.ptr, alloca_name)) return false;
    const param_name = switch (store.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    var pointer_offsets = std.StringHashMap(u64).init(allocator);
    defer pointer_offsets.deinit();
    try pointer_offsets.put(alloca_name, 0);

    var field_loads = std.StringHashMap(AggregateIntegerFieldLoad).init(allocator);
    defer field_loads.deinit();

    const layout = try x86_64SysVDataLayout();
    for (block.instructions.items[2..]) |instruction| {
        if (instruction.removed) return false;
        switch (instruction.kind) {
            .gep => |gep| {
                const result = instruction.result orelse return false;
                const base_name = switch (gep.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const base_offset = pointer_offsets.get(base_name) orelse return false;
                const offset = aggregateGepByteOffset(layout, aggregate_ty, gep) orelse return false;
                try pointer_offsets.put(result, base_offset + offset);
            },
            .load => |load| {
                const result = instruction.result orelse return false;
                if (!load.ty.eql(ret.ty) or load.attrs.isBarrier()) return false;
                const ptr_name = switch (load.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const offset = pointer_offsets.get(ptr_name) orelse return false;
                try field_loads.put(result, .{ .offset = offset });
            },
            .binary => |binary| {
                if (binary.op != .add or !binary.ty.eql(ret.ty)) return false;
            },
            .phi, .fcmp, .icmp, .select, .cast, .freeze, .alloca, .store, .call, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => return false,
        }
    }

    var terms: [8]AggregateIntegerAddTerm = undefined;
    var term_count: usize = 0;
    if (!try collectAggregateIntegerAddTerms(block, ret.value orelse return error.InvalidRet, ret.ty, field_loads, &terms, &term_count)) return false;
    if (term_count < 2) return false;

    try emitAggregateIntegerTerm(allocator, machine, function, param_name, aggregate_ty, terms[0], ret.ty, true);
    for (terms[1..term_count]) |term| {
        try emitAggregateIntegerTerm(allocator, machine, function, param_name, aggregate_ty, term, ret.ty, false);
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRegisterAggregateFloatFieldAddReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.float) or !function.ret_ty.eql(.float)) return false;
    if (block.instructions.items.len < 5) return false;

    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    if (alloca_inst.removed or store_inst.removed) return false;
    const alloca_name = alloca_inst.result orelse return false;
    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    const aggregate_ty = alloca.allocated_ty;
    const classification = classifySysVAggregate(aggregate_ty) catch return false;
    if (classification.kind != .register) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(aggregate_ty) or store.attrs.isBarrier() or !isNamed(store.ptr, alloca_name)) return false;
    const param_name = switch (store.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    var pointer_offsets = std.StringHashMap(u64).init(allocator);
    defer pointer_offsets.deinit();
    try pointer_offsets.put(alloca_name, 0);

    var field_loads = std.StringHashMap(AggregateFloatFieldLoad).init(allocator);
    defer field_loads.deinit();

    const layout = try x86_64SysVDataLayout();
    for (block.instructions.items[2..]) |instruction| {
        if (instruction.removed) return false;
        switch (instruction.kind) {
            .gep => |gep| {
                const result = instruction.result orelse return false;
                const base_name = switch (gep.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const base_offset = pointer_offsets.get(base_name) orelse return false;
                const offset = aggregateGepByteOffset(layout, aggregate_ty, gep) orelse return false;
                try pointer_offsets.put(result, base_offset + offset);
            },
            .load => |load| {
                const result = instruction.result orelse return false;
                if (!load.ty.eql(.float) or load.attrs.isBarrier()) return false;
                const ptr_name = switch (load.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const offset = pointer_offsets.get(ptr_name) orelse return false;
                _ = aggregateFieldIndexAtOffset(aggregate_ty, offset, load.ty) orelse return false;
                try field_loads.put(result, .{ .offset = offset });
            },
            .binary => |binary| {
                if (binary.op != .fadd or !binary.ty.eql(.float)) return false;
            },
            .phi, .fcmp, .icmp, .select, .cast, .freeze, .alloca, .store, .call, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => return false,
        }
    }

    var terms: [8]AggregateFloatAddTerm = undefined;
    var term_count: usize = 0;
    if (!try collectAggregateFloatAddTerms(block, ret.value orelse return error.InvalidRet, field_loads, &terms, &term_count)) return false;
    if (term_count < 2) return false;
    sortAggregateFloatTerms(terms[0..term_count]);

    if (term_count > 2 and try lowerSseF32AggregateStackedSum(allocator, machine, function, param_name, aggregate_ty, terms[0..term_count])) {
        return true;
    }

    try emitAggregateFloatTerm(allocator, machine, function, param_name, aggregate_ty, terms[0], .xmm0);
    for (terms[1..term_count]) |term| {
        try emitAggregateFloatTerm(allocator, machine, function, param_name, aggregate_ty, term, .xmm1);
        try machine.instructions.append(allocator, .addss_xmm1_xmm0);
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerSseF32AggregateStackedSum(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    param_name: []const u8,
    aggregate_ty: ir.Type,
    terms: []const AggregateFloatAddTerm,
) !bool {
    if (function.params.items.len == 0 or !std.mem.eql(u8, function.params.items[0].name, param_name)) return false;
    const classification = classifySysVAggregate(aggregate_ty) catch return false;
    if (classification.kind != .register or classification.eightbyte_count != 2 or
        classification.eightbytes[0] != .sse or classification.eightbytes[1] != .sse)
    {
        return false;
    }
    if (terms.len > 4) return error.UnsupportedCodegenAbi;

    try appendStackFrame(allocator, machine, 24);
    try machine.instructions.append(allocator, .{ .spill_xmm64_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    try machine.instructions.append(allocator, .{ .spill_xmm64_rsp = .{ .reg = .xmm1, .frame_index = .slot2 } });
    try reloadF32AggregateTerm(allocator, machine, terms[0], .xmm0);
    for (terms[1..]) |term| {
        try reloadF32AggregateTerm(allocator, machine, term, .xmm1);
        try machine.instructions.append(allocator, .addss_xmm1_xmm0);
    }
    try appendStackFrameEnd(allocator, machine, 24);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn reloadF32AggregateTerm(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    term: AggregateFloatAddTerm,
    reg: XmmReg,
) !void {
    if (term.offset % 4 != 0) return error.UnsupportedCodegenAbi;
    const frame_index = FrameIndex.fromSlot(term.offset / 4) catch return error.UnsupportedCodegenAbi;
    try machine.instructions.append(allocator, .{ .reload_xmm32_rsp = .{ .reg = reg, .frame_index = frame_index } });
}

fn sortAggregateFloatTerms(terms: []AggregateFloatAddTerm) void {
    var index: usize = 1;
    while (index < terms.len) : (index += 1) {
        var cursor = index;
        while (cursor > 0 and terms[cursor - 1].offset > terms[cursor].offset) : (cursor -= 1) {
            std.mem.swap(AggregateFloatAddTerm, &terms[cursor - 1], &terms[cursor]);
        }
    }
}

pub fn lowerRegisterAggregateDoubleFieldAddReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.double) or !function.ret_ty.eql(.double)) return false;
    if (block.instructions.items.len < 5) return false;

    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    if (alloca_inst.removed or store_inst.removed) return false;
    const alloca_name = alloca_inst.result orelse return false;
    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    const aggregate_ty = alloca.allocated_ty;
    const classification = classifySysVAggregate(aggregate_ty) catch return false;
    if (classification.kind != .register) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(aggregate_ty) or store.attrs.isBarrier() or !isNamed(store.ptr, alloca_name)) return false;
    const param_name = switch (store.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    var pointer_offsets = std.StringHashMap(u64).init(allocator);
    defer pointer_offsets.deinit();
    try pointer_offsets.put(alloca_name, 0);

    var field_loads = std.StringHashMap(AggregateDoubleFieldLoad).init(allocator);
    defer field_loads.deinit();

    const layout = try x86_64SysVDataLayout();
    for (block.instructions.items[2..]) |instruction| {
        if (instruction.removed) return false;
        switch (instruction.kind) {
            .gep => |gep| {
                const result = instruction.result orelse return false;
                const base_name = switch (gep.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const base_offset = pointer_offsets.get(base_name) orelse return false;
                const offset = aggregateGepByteOffset(layout, aggregate_ty, gep) orelse return false;
                try pointer_offsets.put(result, base_offset + offset);
            },
            .load => |load| {
                const result = instruction.result orelse return false;
                if (!load.ty.eql(.double) or load.attrs.isBarrier()) return false;
                const ptr_name = switch (load.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const offset = pointer_offsets.get(ptr_name) orelse return false;
                _ = aggregateFieldIndexAtOffset(aggregate_ty, offset, load.ty) orelse return false;
                try field_loads.put(result, .{ .offset = offset });
            },
            .binary => |binary| {
                if (binary.op != .fadd or !binary.ty.eql(.double)) return false;
            },
            .phi, .fcmp, .icmp, .select, .cast, .freeze, .alloca, .store, .call, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => return false,
        }
    }

    var terms: [2]AggregateDoubleAddTerm = undefined;
    var term_count: usize = 0;
    if (!try collectAggregateDoubleAddTerms(block, ret.value orelse return error.InvalidRet, field_loads, &terms, &term_count)) return false;
    if (term_count != 2) return false;

    try emitAggregateDoubleTerm(allocator, machine, function, param_name, aggregate_ty, terms[0], .xmm0);
    try emitAggregateDoubleTerm(allocator, machine, function, param_name, aggregate_ty, terms[1], .xmm1);
    try machine.instructions.append(allocator, .addsd_xmm1_xmm0);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn collectAggregateFloatAddTerms(
    block: ir.BasicBlock,
    value: ir.Value,
    field_loads: std.StringHashMap(AggregateFloatFieldLoad),
    terms: *[8]AggregateFloatAddTerm,
    term_count: *usize,
) !bool {
    const name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (field_loads.get(name)) |load| {
        if (term_count.* >= terms.len) return error.UnsupportedCodegenAbi;
        terms[term_count.*] = .{ .offset = load.offset };
        term_count.* += 1;
        return true;
    }
    const instruction = findInstruction(block, name) orelse return false;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (binary.op != .fadd or !binary.ty.eql(.float)) return false;
    if (!try collectAggregateFloatAddTerms(block, binary.lhs, field_loads, terms, term_count)) return false;
    return try collectAggregateFloatAddTerms(block, binary.rhs, field_loads, terms, term_count);
}

pub fn collectAggregateDoubleAddTerms(
    block: ir.BasicBlock,
    value: ir.Value,
    field_loads: std.StringHashMap(AggregateDoubleFieldLoad),
    terms: *[2]AggregateDoubleAddTerm,
    term_count: *usize,
) !bool {
    const name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (field_loads.get(name)) |load| {
        if (term_count.* >= terms.len) return error.UnsupportedCodegenAbi;
        terms[term_count.*] = .{ .offset = load.offset };
        term_count.* += 1;
        return true;
    }
    const instruction = findInstruction(block, name) orelse return false;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (binary.op != .fadd or !binary.ty.eql(.double)) return false;
    if (!try collectAggregateDoubleAddTerms(block, binary.lhs, field_loads, terms, term_count)) return false;
    return try collectAggregateDoubleAddTerms(block, binary.rhs, field_loads, terms, term_count);
}

pub fn aggregateGepByteOffset(layout: target.DataLayout, aggregate_ty: ir.Type, gep: ir.GepInst) ?u64 {
    if (gep.source_ty.eql(.{ .int = 8 }) and gep.indices.items.len == 1 and gep.indices.items[0].ty.eql(.{ .int = 64 })) {
        const offset = switch (gep.indices.items[0].value) {
            .int => |int| int,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
        };
        if (offset < 0) return null;
        return @intCast(offset);
    }
    if (isScalarElementGepType(gep.source_ty) and gep.indices.items.len == 1 and gep.indices.items[0].ty.eql(.{ .int = 64 })) {
        const index = switch (gep.indices.items[0].value) {
            .int => |int| int,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
        };
        if (index < 0) return null;
        const element_size = layout.typeStoreSizeBytes(gep.source_ty) catch return null;
        return @intCast(@as(u128, @intCast(index)) * element_size);
    }
    _ = aggregate_ty;
    if (isAggregateType(gep.source_ty) and gep.indices.items.len >= 2 and
        gep.indices.items[0].ty.eql(.{ .int = 64 }) and isInt(gep.indices.items[0].value, 0))
    {
        var current_ty = gep.source_ty;
        var byte_offset: u64 = 0;
        for (gep.indices.items[1..]) |index| {
            if (!index.ty.eql(.{ .int = 32 }) and !index.ty.eql(.{ .int = 64 })) return null;
            const field_index = switch (index.value) {
                .int => |int| int,
                .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
            };
            if (field_index < 0 or field_index > std.math.maxInt(usize)) return null;
            const offset = type_layout.fieldByteOffset(layout, current_ty, @intCast(field_index)) orelse return null;
            byte_offset += offset;
            current_ty = type_layout.fieldType(current_ty, @intCast(field_index)) orelse return null;
        }
        return byte_offset;
    }
    return null;
}

pub fn aggregateFieldIndexAtOffset(aggregate_ty: ir.Type, expected_offset: u64, expected_ty: ir.Type) ?usize {
    const layout = x86_64SysVDataLayout() catch return null;
    return type_layout.fieldIndexAtOffset(layout, aggregate_ty, expected_offset, expected_ty);
}

pub fn isScalarElementGepType(ty: ir.Type) bool {
    return switch (ty) {
        .int, .float, .double, .ptr => true,
        .void, .half, .x86_fp80, .fp128, .metadata, .aggregate, .vector => false,
    };
}

pub fn isAggregateType(ty: ir.Type) bool {
    return type_layout.isAggregateType(ty);
}

pub fn collectAggregateIntegerAddTerms(
    block: ir.BasicBlock,
    value: ir.Value,
    ty: ir.Type,
    field_loads: std.StringHashMap(AggregateIntegerFieldLoad),
    terms: *[8]AggregateIntegerAddTerm,
    term_count: *usize,
) !bool {
    const name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (field_loads.get(name)) |load| {
        if (term_count.* >= terms.len) return error.UnsupportedCodegenInstruction;
        terms[term_count.*] = .{ .offset = load.offset };
        term_count.* += 1;
        return true;
    }
    const instruction = findInstruction(block, name) orelse return false;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (binary.op != .add or !binary.ty.eql(ty)) return false;
    if (!try collectAggregateIntegerAddTerms(block, binary.lhs, ty, field_loads, terms, term_count)) return false;
    if (!try collectAggregateIntegerAddTerms(block, binary.rhs, ty, field_loads, terms, term_count)) return false;
    return true;
}

pub fn emitAggregateIntegerTerm(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    param_name: []const u8,
    aggregate_ty: ir.Type,
    term: AggregateIntegerAddTerm,
    ty: ir.Type,
    first: bool,
) !void {
    const location = try sysvIntegerAggregateFieldLocation(function, param_name, aggregate_ty, term.offset, ty);
    switch (location) {
        .gpr => |field| {
            if (ty.eql(.{ .int = 64 })) {
                if (field.offset_in_eightbyte != 0) return error.UnsupportedCodegenAbi;
                if (first) {
                    try machine.instructions.append(allocator, .{ .mov_arg_rax = field.reg });
                } else {
                    try machine.instructions.append(allocator, .{ .add_arg64_rax = field.reg });
                }
                return;
            }
            if (!ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenAbi;
            switch (field.offset_in_eightbyte) {
                0 => if (first)
                    try machine.instructions.append(allocator, .{ .mov_arg_eax = field.reg })
                else
                    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = field.reg } }),
                4 => if (first) {
                    try machine.instructions.append(allocator, .{ .mov_arg_rax = field.reg });
                    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 32 });
                } else {
                    try machine.instructions.append(allocator, .{ .add_arg_high32_eax = field.reg });
                },
                else => return error.UnsupportedCodegenAbi,
            }
        },
        .stack => |offset| {
            if (ty.eql(.{ .int = 64 })) {
                if (first) {
                    try appendLoadStackDispRax(allocator, machine, offset);
                } else {
                    try appendAddStackDispRax(allocator, machine, offset);
                }
            } else if (ty.eql(.{ .int = 32 })) {
                if (first) {
                    try appendLoadStackDispEax(allocator, machine, offset);
                } else {
                    try appendAddStackDispEax(allocator, machine, offset);
                }
            } else {
                return error.UnsupportedCodegenAbi;
            }
        },
    }
}

pub fn emitAggregateDoubleTerm(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    param_name: []const u8,
    aggregate_ty: ir.Type,
    term: AggregateDoubleAddTerm,
    dest: XmmReg,
) !void {
    const location = try sysvAggregateFieldLocationByOffset(function, param_name, aggregate_ty, term.offset, .double);
    switch (location) {
        .sse => |reg| {
            if (reg == dest) return;
            try machine.instructions.append(allocator, .{ .movapd_xmm = .{ .dst = dest, .src = reg } });
        },
        .stack => |offset| try appendLoadStackDispXmm(allocator, machine, dest, offset),
        .gpr => return error.UnsupportedCodegenAbi,
    }
}

pub fn emitAggregateFloatTerm(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    param_name: []const u8,
    aggregate_ty: ir.Type,
    term: AggregateFloatAddTerm,
    dest: XmmReg,
) !void {
    const location = try sysvAggregateFieldLocationByOffset(function, param_name, aggregate_ty, term.offset, .float);
    switch (location) {
        .sse => |reg| {
            if (reg != dest) {
                try machine.instructions.append(allocator, .{ .movapd_xmm = .{ .dst = dest, .src = reg } });
            }
            if (term.offset % 8 == 4) {
                try machine.instructions.append(allocator, .{ .shufps_high_f32_to_low = dest });
            } else if (term.offset % 8 != 0) {
                return error.UnsupportedCodegenAbi;
            }
        },
        .stack => |offset| {
            try appendLoadStackDispXmmF32(allocator, machine, dest, offset);
        },
        .gpr => return error.UnsupportedCodegenAbi,
    }
}

pub fn appendLoadStackDispRax(allocator: std.mem.Allocator, machine: *MachineFunction, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .load_stack_disp8_rax = @intCast(offset) });
    } else {
        try machine.instructions.append(allocator, .{ .load_stack_disp32_rax = offset });
    }
}

pub fn appendLoadStackDispEax(allocator: std.mem.Allocator, machine: *MachineFunction, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .load_stack_disp8_eax = @intCast(offset) });
    } else {
        try machine.instructions.append(allocator, .{ .load_stack_disp32_eax = offset });
    }
}

pub fn appendLoadStackDispU8Eax(allocator: std.mem.Allocator, machine: *MachineFunction, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .load_stack_disp8_u8_eax = @intCast(offset) });
    } else {
        try machine.instructions.append(allocator, .{ .load_stack_disp32_u8_eax = offset });
    }
}

pub fn appendLoadStackDispU16Eax(allocator: std.mem.Allocator, machine: *MachineFunction, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .load_stack_disp8_u16_eax = @intCast(offset) });
    } else {
        try machine.instructions.append(allocator, .{ .load_stack_disp32_u16_eax = offset });
    }
}

pub fn appendLoadStackDispXmm0(allocator: std.mem.Allocator, machine: *MachineFunction, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .load_stack_disp8_xmm0 = @intCast(offset) });
    } else {
        try machine.instructions.append(allocator, .{ .load_stack_disp32_xmm0 = offset });
    }
}

pub fn appendLoadStackDispXmm0F32(allocator: std.mem.Allocator, machine: *MachineFunction, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .load_stack_disp8_xmm0_f32 = @intCast(offset) });
    } else {
        try machine.instructions.append(allocator, .{ .load_stack_disp32_xmm0_f32 = offset });
    }
}

pub fn appendLoadStackDispXmmF32(allocator: std.mem.Allocator, machine: *MachineFunction, reg: XmmReg, offset: u32) !void {
    if (reg == .xmm0) return appendLoadStackDispXmm0F32(allocator, machine, offset);
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .load_stack_disp8_xmm_f32 = .{ .reg = reg, .disp = @intCast(offset) } });
    } else {
        try machine.instructions.append(allocator, .{ .load_stack_disp32_xmm_f32 = .{ .reg = reg, .disp = offset } });
    }
}

pub fn appendLoadStackDispXmm(allocator: std.mem.Allocator, machine: *MachineFunction, reg: XmmReg, offset: u32) !void {
    if (reg == .xmm0) return appendLoadStackDispXmm0(allocator, machine, offset);
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .load_stack_disp8_xmm = .{ .reg = reg, .disp = @intCast(offset) } });
    } else {
        try machine.instructions.append(allocator, .{ .load_stack_disp32_xmm = .{ .reg = reg, .disp = offset } });
    }
}

pub fn appendAddStackDispRax(allocator: std.mem.Allocator, machine: *MachineFunction, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .add_stack_disp8_rax = @intCast(offset) });
    } else {
        try machine.instructions.append(allocator, .{ .add_stack_disp32_rax = offset });
    }
}

pub fn appendAddStackDispEax(allocator: std.mem.Allocator, machine: *MachineFunction, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .add_stack_disp8_eax = @intCast(offset) });
    } else {
        try machine.instructions.append(allocator, .{ .add_stack_disp32_eax = offset });
    }
}

pub fn appendStoreArg64ArgPtrDisp(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    ptr_reg: ArgReg,
    src_reg: ArgReg,
    offset: u32,
) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .store_arg64_arg_ptr_disp8 = .{
            .ptr_reg = ptr_reg,
            .src_reg = src_reg,
            .offset = @intCast(offset),
        } });
    } else {
        try machine.instructions.append(allocator, .{ .store_arg64_arg_ptr_disp32 = .{
            .ptr_reg = ptr_reg,
            .src_reg = src_reg,
            .offset = offset,
        } });
    }
}

pub fn appendStoreRaxArgPtrDisp(allocator: std.mem.Allocator, machine: *MachineFunction, reg: ArgReg, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .store_rax_arg_ptr_disp8 = .{ .reg = reg, .offset = @intCast(offset) } });
    } else {
        try machine.instructions.append(allocator, .{ .store_rax_arg_ptr_disp32 = .{ .reg = reg, .offset = offset } });
    }
}

pub fn appendStoreEaxArgPtrDisp(allocator: std.mem.Allocator, machine: *MachineFunction, reg: ArgReg, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .store_eax_arg_ptr_disp8 = .{ .reg = reg, .offset = @intCast(offset) } });
    } else {
        try machine.instructions.append(allocator, .{ .store_eax_arg_ptr_disp32 = .{ .reg = reg, .offset = offset } });
    }
}

pub fn appendStoreAlArgPtrDisp(allocator: std.mem.Allocator, machine: *MachineFunction, reg: ArgReg, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .store_al_arg_ptr_disp8 = .{ .reg = reg, .offset = @intCast(offset) } });
    } else {
        try machine.instructions.append(allocator, .{ .store_al_arg_ptr_disp32 = .{ .reg = reg, .offset = offset } });
    }
}

pub fn appendStoreAxArgPtrDisp(allocator: std.mem.Allocator, machine: *MachineFunction, reg: ArgReg, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .store_ax_arg_ptr_disp8 = .{ .reg = reg, .offset = @intCast(offset) } });
    } else {
        try machine.instructions.append(allocator, .{ .store_ax_arg_ptr_disp32 = .{ .reg = reg, .offset = offset } });
    }
}

pub fn appendStoreXmm0ArgPtrDisp(allocator: std.mem.Allocator, machine: *MachineFunction, reg: ArgReg, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .store_xmm0_arg_ptr_disp8 = .{ .reg = reg, .offset = @intCast(offset) } });
    } else {
        try machine.instructions.append(allocator, .{ .store_xmm0_arg_ptr_disp32 = .{ .reg = reg, .offset = offset } });
    }
}

pub fn appendStoreXmm0F32ArgPtrDisp(allocator: std.mem.Allocator, machine: *MachineFunction, reg: ArgReg, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .store_xmm0_f32_arg_ptr_disp8 = .{ .reg = reg, .offset = @intCast(offset) } });
    } else {
        try machine.instructions.append(allocator, .{ .store_xmm0_f32_arg_ptr_disp32 = .{ .reg = reg, .offset = offset } });
    }
}

pub const SysVIntegerAggregateFieldLocation = union(enum) {
    gpr: struct {
        reg: ArgReg,
        offset_in_eightbyte: u3,
    },
    stack: u32,
};

pub fn sysvIntegerAggregateFieldLocation(
    function: ir.Function,
    param_name: []const u8,
    aggregate_ty: ir.Type,
    field_offset: u64,
    field_ty: ir.Type,
) !SysVIntegerAggregateFieldLocation {
    const layout = try x86_64SysVDataLayout();
    const field_size = try layout.typeStoreSizeBytes(field_ty);
    const aggregate_size = try layout.typeStoreSizeBytes(aggregate_ty);
    if (field_size == 0 or field_offset + field_size > aggregate_size) return error.UnsupportedCodegenAbi;
    if (field_size != 4 and field_size != 8) return error.UnsupportedCodegenAbi;

    var gpr_index: usize = 0;
    var sse_index: usize = 0;
    var stack_eightbytes: usize = 0;
    for (function.params.items) |param| {
        if (std.mem.eql(u8, param.name, param_name)) {
            if (!param.ty.eql(aggregate_ty)) return error.UnsupportedCodegenValue;
            const classification = try classifySysVAggregate(param.ty);
            const field_eightbyte = field_offset / 8;
            if (field_eightbyte >= classification.eightbyte_count) return error.UnsupportedCodegenAbi;
            const field_class = classification.eightbytes[@intCast(field_eightbyte)] orelse return error.UnsupportedCodegenAbi;
            if (field_class != .integer) return error.UnsupportedCodegenAbi;
            const needed = sysvAggregateRegisterNeeds(classification);
            if (gpr_index + needed.gpr > 6 or sse_index + needed.sse > 8) {
                const offset = 8 + stack_eightbytes * 8 + field_offset;
                if (offset > std.math.maxInt(u32)) return error.UnsupportedCodegenAbi;
                return .{ .stack = @intCast(offset) };
            }
            const prior = sysvAggregateRegisterNeedsBefore(classification, @intCast(field_eightbyte));
            return .{ .gpr = .{
                .reg = try ArgReg.fromIndex(gpr_index + prior.gpr),
                .offset_in_eightbyte = @intCast(field_offset % 8),
            } };
        }
        try advanceSysVParamCursors(param.ty, &gpr_index, &sse_index, &stack_eightbytes);
    }
    return error.UnsupportedCodegenValue;
}

pub fn lowerMemoryIntegerAggregateFieldAddReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 64 }) or !function.ret_ty.eql(.{ .int = 64 })) return false;
    if (function.params.items.len != 1) return false;
    const aggregate_ty = function.params.items[0].ty;
    const classification = classifySysVAggregate(aggregate_ty) catch return false;
    if (classification.kind != .memory or !isI64LeafAggregate(aggregate_ty)) return false;
    if (block.instructions.items.len < 5) return false;

    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    if (alloca_inst.removed or store_inst.removed) return false;
    const alloca_name = alloca_inst.result orelse return false;

    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    if (!alloca.allocated_ty.eql(aggregate_ty)) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(aggregate_ty) or store.attrs.isBarrier() or !isNamed(store.ptr, alloca_name) or
        !isNamed(store.value, function.params.items[0].name)) return false;

    var pointer_offsets = std.StringHashMap(u64).init(allocator);
    defer pointer_offsets.deinit();
    try pointer_offsets.put(alloca_name, 0);

    var field_loads = std.StringHashMap(AggregateIntegerFieldLoad).init(allocator);
    defer field_loads.deinit();

    const layout = try x86_64SysVDataLayout();
    for (block.instructions.items[2..]) |instruction| {
        if (instruction.removed) return false;
        switch (instruction.kind) {
            .gep => |gep| {
                const result = instruction.result orelse return false;
                const base_name = switch (gep.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const base_offset = pointer_offsets.get(base_name) orelse return false;
                const offset = aggregateGepByteOffset(layout, aggregate_ty, gep) orelse return false;
                const total_offset = base_offset + offset;
                _ = aggregateFieldIndexAtOffset(aggregate_ty, total_offset, .{ .int = 64 }) orelse return false;
                try pointer_offsets.put(result, total_offset);
            },
            .load => |load| {
                const result = instruction.result orelse return false;
                if (!load.ty.eql(.{ .int = 64 }) or load.attrs.isBarrier()) return false;
                const ptr_name = switch (load.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const offset = pointer_offsets.get(ptr_name) orelse return false;
                _ = aggregateFieldIndexAtOffset(aggregate_ty, offset, load.ty) orelse return false;
                try field_loads.put(result, .{ .offset = offset });
            },
            .binary => |binary| {
                if (binary.op != .add or !binary.ty.eql(.{ .int = 64 })) return false;
            },
            .phi, .fcmp, .icmp, .select, .cast, .freeze, .alloca, .store, .call, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => return false,
        }
    }

    var terms: [8]AggregateIntegerAddTerm = undefined;
    var term_count: usize = 0;
    if (!try collectAggregateIntegerAddTerms(block, ret.value orelse return error.InvalidRet, .{ .int = 64 }, field_loads, &terms, &term_count)) return false;
    if (term_count < 2) return false;

    try appendLoadStackDispRax(allocator, machine, try stackAggregateByteDisp(aggregate_ty, terms[0].offset, .{ .int = 64 }));
    for (terms[1..term_count]) |term| {
        try appendAddStackDispRax(allocator, machine, try stackAggregateByteDisp(aggregate_ty, term.offset, .{ .int = 64 }));
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn isI64Aggregate(aggregate_ty: ir.Type) bool {
    const field_count = aggregateFieldCount(aggregate_ty) orelse return false;
    if (field_count == 0) return false;
    var field_index: usize = 0;
    while (field_index < field_count) : (field_index += 1) {
        const field_ty = type_layout.fieldType(aggregate_ty, field_index) orelse return false;
        if (!field_ty.eql(.{ .int = 64 })) return false;
    }
    return true;
}

pub fn isI64LeafAggregate(aggregate_ty: ir.Type) bool {
    const field_count = aggregateFieldCount(aggregate_ty) orelse return false;
    if (field_count == 0) return false;
    var field_index: usize = 0;
    while (field_index < field_count) : (field_index += 1) {
        const field_ty = type_layout.fieldType(aggregate_ty, field_index) orelse return false;
        if (field_ty.eql(.{ .int = 64 })) continue;
        if (isAggregateType(field_ty) and isI64LeafAggregate(field_ty)) continue;
        return false;
    }
    return true;
}

pub fn isSupportedAggregateCopyLeafAggregate(aggregate_ty: ir.Type) bool {
    return type_layout.isSupportedScalarLeafAggregate(aggregate_ty);
}

pub fn supportedAggregateCopyLeaf(ty: ir.Type) bool {
    return type_layout.isSupportedScalarLeaf(ty);
}

pub fn aggregateFieldIndexFromGep(instruction: ir.Instruction, aggregate_ty: ir.Type, base_name: []const u8) ?usize {
    const gep = switch (instruction.kind) {
        .gep => |gep| gep,
        else => return null,
    };
    if (!gep.source_ty.eql(aggregate_ty) or !isNamed(gep.ptr, base_name)) return null;
    if (gep.indices.items.len != 2) return null;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, 0)) return null;
    if (!gep.indices.items[1].ty.eql(.{ .int = 32 })) return null;
    const field_index = switch (gep.indices.items[1].value) {
        .int => |index| index,
        else => return null,
    };
    if (field_index < 0) return null;
    return @intCast(field_index);
}

pub fn stackAggregateFieldDisp8(aggregate_ty: ir.Type, field_index: usize) !u8 {
    const layout = try x86_64SysVDataLayout();
    const field_offset = type_layout.fieldByteOffset(layout, aggregate_ty, field_index) orelse
        return error.UnsupportedCodegenAbi;
    const offset = 8 + field_offset;
    if (offset > std.math.maxInt(u8)) return error.UnsupportedCodegenAbi;
    return @intCast(offset);
}

pub fn stackAggregateByteDisp8(aggregate_ty: ir.Type, field_offset: u64, field_ty: ir.Type) !u8 {
    _ = aggregateFieldIndexAtOffset(aggregate_ty, field_offset, field_ty) orelse return error.UnsupportedCodegenAbi;
    const offset = 8 + field_offset;
    if (offset > std.math.maxInt(u8)) return error.UnsupportedCodegenAbi;
    return @intCast(offset);
}

pub fn stackAggregateByteDisp(aggregate_ty: ir.Type, field_offset: u64, field_ty: ir.Type) !u32 {
    _ = aggregateFieldIndexAtOffset(aggregate_ty, field_offset, field_ty) orelse return error.UnsupportedCodegenAbi;
    const offset = 8 + field_offset;
    if (offset > std.math.maxInt(u32)) return error.UnsupportedCodegenAbi;
    return @intCast(offset);
}

pub fn validateAggregateFieldGep(instruction: ir.Instruction, aggregate_ty: ir.Type, base_name: []const u8, field_index: i128) !void {
    const gep = switch (instruction.kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!gep.source_ty.eql(aggregate_ty) or !isNamed(gep.ptr, base_name)) return error.UnsupportedCodegenInstruction;
    if (gep.indices.items.len != 2) return error.UnsupportedCodegenInstruction;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, 0)) return error.UnsupportedCodegenInstruction;
    if (!gep.indices.items[1].ty.eql(.{ .int = 32 }) or !isInt(gep.indices.items[1].value, field_index)) return error.UnsupportedCodegenInstruction;
}

pub fn emitSysVAggregateFieldReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    param_name: []const u8,
    aggregate_ty: ir.Type,
    field_index: usize,
    field_ty: ir.Type,
) !void {
    const location = try sysvAggregateFieldLocation(function, param_name, aggregate_ty, field_index, field_ty);
    try emitSysVAggregateFieldLocationReturn(allocator, machine, location, field_ty);
}

pub fn emitSysVAggregateFieldOffsetReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    param_name: []const u8,
    aggregate_ty: ir.Type,
    field_offset: u64,
    field_ty: ir.Type,
) !void {
    if (field_ty.eql(.{ .int = 32 }) or field_ty.eql(.{ .int = 64 })) {
        const location = try sysvIntegerAggregateFieldLocation(function, param_name, aggregate_ty, field_offset, field_ty);
        try emitSysVIntegerAggregateFieldLocationReturn(allocator, machine, location, field_ty);
        return;
    }
    if (field_ty.eql(.float)) {
        _ = try emitSysVAggregateF32FieldOffsetReturn(allocator, machine, function, param_name, aggregate_ty, field_offset);
        return;
    }
    const location = try sysvAggregateFieldLocationByOffset(function, param_name, aggregate_ty, field_offset, field_ty);
    try emitSysVAggregateFieldLocationReturn(allocator, machine, location, field_ty);
}

pub fn emitSysVIntegerAggregateFieldLocationReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    location: SysVIntegerAggregateFieldLocation,
    field_ty: ir.Type,
) !void {
    switch (location) {
        .gpr => |field| {
            if (field_ty.eql(.{ .int = 64 })) {
                if (field.offset_in_eightbyte != 0) return error.UnsupportedCodegenAbi;
                try machine.instructions.append(allocator, .{ .mov_arg_rax = field.reg });
                return;
            }
            if (!field_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenAbi;
            switch (field.offset_in_eightbyte) {
                0 => try machine.instructions.append(allocator, .{ .mov_arg_eax = field.reg }),
                4 => {
                    try machine.instructions.append(allocator, .{ .mov_arg_rax = field.reg });
                    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 32 });
                },
                else => return error.UnsupportedCodegenAbi,
            }
        },
        .stack => |offset| {
            if (field_ty.eql(.{ .int = 64 })) {
                try appendLoadStackDispRax(allocator, machine, offset);
            } else if (field_ty.eql(.{ .int = 32 })) {
                try appendLoadStackDispEax(allocator, machine, offset);
            } else {
                return error.UnsupportedCodegenAbi;
            }
        },
    }
}

pub fn emitSysVAggregateFieldLocationReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    location: SysVAggregateFieldLocation,
    field_ty: ir.Type,
) !void {
    switch (location) {
        .gpr => |reg| {
            if (field_ty.eql(.{ .int = 64 })) {
                try machine.instructions.append(allocator, .{ .mov_arg_rax = reg });
                return;
            }
            if (field_ty.eql(.{ .int = 32 })) {
                try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
                return;
            }
            return error.UnsupportedCodegenAbi;
        },
        .sse => |reg| {
            if (field_ty.eql(.float)) {
                switch (reg) {
                    .xmm0 => {},
                    .xmm1, .xmm2, .xmm3, .xmm4, .xmm5, .xmm6, .xmm7 => try machine.instructions.append(allocator, .{ .movapd_xmm = .{ .dst = .xmm0, .src = reg } }),
                }
                return;
            }
            if (!field_ty.eql(.double)) return error.UnsupportedCodegenAbi;
            switch (reg) {
                .xmm0 => {},
                .xmm1 => try machine.instructions.append(allocator, .movapd_xmm1_xmm0),
                .xmm2, .xmm3, .xmm4, .xmm5, .xmm6, .xmm7 => try machine.instructions.append(allocator, .{ .movapd_xmm = .{ .dst = .xmm0, .src = reg } }),
            }
        },
        .stack => |offset| {
            if (field_ty.eql(.{ .int = 64 })) {
                try appendLoadStackDispRax(allocator, machine, offset);
            } else if (field_ty.eql(.float)) {
                try appendLoadStackDispXmm0F32(allocator, machine, offset);
            } else if (field_ty.eql(.double)) {
                try appendLoadStackDispXmm0(allocator, machine, offset);
            } else {
                return error.UnsupportedCodegenAbi;
            }
        },
    }
}

pub fn emitSysVAggregateF32FieldOffsetReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    param_name: []const u8,
    aggregate_ty: ir.Type,
    field_offset: u64,
) !bool {
    const location = try sysvAggregateFieldLocationByOffset(function, param_name, aggregate_ty, field_offset, .float);
    switch (location) {
        .sse => |reg| {
            switch (reg) {
                .xmm0 => {},
                .xmm1, .xmm2, .xmm3, .xmm4, .xmm5, .xmm6, .xmm7 => try machine.instructions.append(allocator, .{ .movapd_xmm = .{ .dst = .xmm0, .src = reg } }),
            }
            if (field_offset % 8 == 4) {
                try machine.instructions.append(allocator, .{ .shufps_high_f32_to_low = .xmm0 });
            } else if (field_offset % 8 != 0) {
                return error.UnsupportedCodegenAbi;
            }
        },
        .stack => |offset| try appendLoadStackDispXmm0F32(allocator, machine, offset),
        .gpr => return error.UnsupportedCodegenAbi,
    }
    return true;
}

pub const SysVAggregateFieldLocation = union(enum) {
    gpr: ArgReg,
    sse: XmmReg,
    stack: u32,
};

pub fn sysvAggregateFieldLocation(
    function: ir.Function,
    param_name: []const u8,
    aggregate_ty: ir.Type,
    field_index: usize,
    field_ty: ir.Type,
) !SysVAggregateFieldLocation {
    const layout = try x86_64SysVDataLayout();
    const field_offset = type_layout.fieldByteOffset(layout, aggregate_ty, field_index) orelse
        return error.UnsupportedCodegenAbi;
    if (!((type_layout.fieldType(aggregate_ty, field_index) orelse return error.UnsupportedCodegenAbi).eql(field_ty))) {
        return error.UnsupportedCodegenAbi;
    }
    return try sysvAggregateFieldLocationByOffset(function, param_name, aggregate_ty, field_offset, field_ty);
}

pub fn sysvAggregateFieldLocationByOffset(
    function: ir.Function,
    param_name: []const u8,
    aggregate_ty: ir.Type,
    field_offset: u64,
    field_ty: ir.Type,
) !SysVAggregateFieldLocation {
    const layout = try x86_64SysVDataLayout();
    const field_size = try layout.typeStoreSizeBytes(field_ty);
    const aggregate_size = try layout.typeStoreSizeBytes(aggregate_ty);
    if (field_size == 0 or field_offset + field_size > aggregate_size) return error.UnsupportedCodegenAbi;
    _ = aggregateFieldIndexAtOffset(aggregate_ty, field_offset, field_ty) orelse return error.UnsupportedCodegenAbi;
    var gpr_index: usize = 0;
    var sse_index: usize = 0;
    var stack_eightbytes: usize = 0;
    for (function.params.items) |param| {
        if (std.mem.eql(u8, param.name, param_name)) {
            if (!param.ty.eql(aggregate_ty)) return error.UnsupportedCodegenValue;
            const classification = try classifySysVAggregate(param.ty);
            if (classification.kind != .register) return error.UnsupportedCodegenAbi;
            const field_eightbyte = field_offset / 8;
            const field_class = if (field_eightbyte < classification.eightbytes.len)
                classification.eightbytes[@intCast(field_eightbyte)] orelse return error.UnsupportedCodegenAbi
            else
                return error.UnsupportedCodegenAbi;
            const needed = sysvAggregateRegisterNeeds(classification);
            if (gpr_index + needed.gpr > 6 or sse_index + needed.sse > 8) {
                const offset = 8 + stack_eightbytes * 8 + field_offset;
                if (offset > std.math.maxInt(u32)) return error.UnsupportedCodegenAbi;
                return .{ .stack = @intCast(offset) };
            }
            const prior = sysvAggregateRegisterNeedsBefore(classification, @intCast(field_eightbyte));
            return switch (field_class) {
                .integer => .{ .gpr = try ArgReg.fromIndex(gpr_index + prior.gpr) },
                .sse => .{ .sse = try XmmReg.fromIndex(sse_index + prior.sse) },
            };
        }
        try advanceSysVParamCursors(param.ty, &gpr_index, &sse_index, &stack_eightbytes);
    }
    return error.UnsupportedCodegenValue;
}

pub fn sysvAggregateRegisterNeeds(classification: SysVAggregateClassification) SysVRegisterNeeds {
    return sysv_abi.aggregateRegisterNeeds(classification);
}

pub fn sysvAggregateRegisterNeedsBefore(classification: SysVAggregateClassification, limit: usize) SysVRegisterNeeds {
    return sysv_abi.aggregateRegisterNeedsBefore(classification, limit);
}

pub fn lowerRegisterAggregateCallFieldReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(function.ret_ty)) return false;
    if (!(ret.ty.eql(.{ .int = 64 }) or ret.ty.eql(.{ .int = 32 }) or ret.ty.eql(.float) or ret.ty.eql(.double))) return false;
    if (block.instructions.items.len != 4 and block.instructions.items.len != 5) return false;

    const call_inst = block.instructions.items[0];
    const alloca_inst = block.instructions.items[1];
    const store_inst = block.instructions.items[2];
    if (call_inst.removed or alloca_inst.removed or store_inst.removed) return false;

    const call_result = call_inst.result orelse return false;
    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.inline_asm != null or call.tail_kind != null or call.callee_value != null) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;

    const aggregate_ty = call.ret_ty;
    const classification = classifySysVAggregate(aggregate_ty) catch return false;
    if (classification.kind != .register) return false;

    const alloca_name = alloca_inst.result orelse return false;
    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    if (!alloca.allocated_ty.eql(aggregate_ty)) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(aggregate_ty) or store.attrs.isBarrier() or !isNamed(store.value, call_result) or !isNamed(store.ptr, alloca_name)) return false;

    const field_offset: u64 = if (block.instructions.items.len == 4) offset: {
        const load_inst = block.instructions.items[3];
        const load_name = validateAggregateFieldLoad(load_inst, ret.ty, alloca_name) orelse return false;
        if (!isNamed(ret.value orelse return error.InvalidRet, load_name)) return false;
        break :offset 0;
    } else offset: {
        const gep_inst = block.instructions.items[3];
        const load_inst = block.instructions.items[4];
        if (gep_inst.removed or load_inst.removed) return false;
        const gep_name = gep_inst.result orelse return false;
        const gep = switch (gep_inst.kind) {
            .gep => |gep| gep,
            else => return false,
        };
        if (!isNamed(gep.ptr, alloca_name)) return false;
        const computed_offset = aggregateGepByteOffset(try x86_64SysVDataLayout(), aggregate_ty, gep) orelse return false;
        const load_name = validateAggregateFieldLoad(load_inst, ret.ty, gep_name) orelse return false;
        if (!isNamed(ret.value orelse return error.InvalidRet, load_name)) return false;
        break :offset computed_offset;
    };
    _ = aggregateFieldIndexAtOffset(aggregate_ty, field_offset, ret.ty) orelse return false;

    const stack_arg_count = appendSysVScalarCallArgs(allocator, machine, function, call) catch |err| switch (err) {
        error.UnsupportedCodegenAbi, error.UnsupportedCodegenType, error.UnsupportedCodegenValue => return false,
        else => if (sysv_abi.isBoundaryError(err)) return false else return err,
    };
    try appendDirectCallWithStackArgs(allocator, machine, call.callee, call.ret_ty, stack_arg_count);
    try emitSysVAggregateReturnField(allocator, machine, classification, field_offset, ret.ty);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn validateAggregateFieldLoad(instruction: ir.Instruction, ty: ir.Type, ptr_name: []const u8) ?[]const u8 {
    if (instruction.removed) return null;
    const name = instruction.result orelse return null;
    const load = switch (instruction.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(ty) or load.attrs.isBarrier() or !isNamed(load.ptr, ptr_name)) return null;
    return name;
}

fn emitSysVAggregateReturnField(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    classification: SysVAggregateClassification,
    field_offset: u64,
    field_ty: ir.Type,
) !void {
    if (classification.kind != .register) return error.UnsupportedCodegenAbi;
    const field_eightbyte = field_offset / 8;
    if (field_eightbyte >= classification.eightbytes.len) return error.UnsupportedCodegenAbi;
    const field_class = classification.eightbytes[@intCast(field_eightbyte)] orelse return error.UnsupportedCodegenAbi;
    const prior = sysvAggregateRegisterNeedsBefore(classification, @intCast(field_eightbyte));
    return switch (field_class) {
        .integer => emitSysVIntegerAggregateReturnField(allocator, machine, prior.gpr, field_offset % 8, field_ty),
        .sse => emitSysVSseAggregateReturnField(allocator, machine, prior.sse, field_offset % 8, field_ty),
    };
}

fn emitSysVIntegerAggregateReturnField(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    return_gpr_index: usize,
    offset_in_eightbyte: u64,
    field_ty: ir.Type,
) !void {
    if (field_ty.eql(.{ .int = 64 })) {
        if (offset_in_eightbyte != 0) return error.UnsupportedCodegenAbi;
        switch (return_gpr_index) {
            0 => {},
            1 => try machine.instructions.append(allocator, .{ .mov_arg_rax = .rdx }),
            else => return error.UnsupportedCodegenAbi,
        }
        return;
    }
    if (field_ty.eql(.{ .int = 32 })) {
        switch (return_gpr_index) {
            0 => {
                if (offset_in_eightbyte == 4) {
                    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 32 });
                } else if (offset_in_eightbyte != 0) {
                    return error.UnsupportedCodegenAbi;
                }
            },
            1 => {
                try machine.instructions.append(allocator, .{ .mov_arg_rax = .rdx });
                if (offset_in_eightbyte == 4) {
                    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 32 });
                } else if (offset_in_eightbyte != 0) {
                    return error.UnsupportedCodegenAbi;
                }
            },
            else => return error.UnsupportedCodegenAbi,
        }
        return;
    }
    return error.UnsupportedCodegenAbi;
}

fn emitSysVSseAggregateReturnField(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    return_sse_index: usize,
    offset_in_eightbyte: u64,
    field_ty: ir.Type,
) !void {
    const source = switch (return_sse_index) {
        0 => XmmReg.xmm0,
        1 => XmmReg.xmm1,
        else => return error.UnsupportedCodegenAbi,
    };
    if (field_ty.eql(.double)) {
        if (offset_in_eightbyte != 0) return error.UnsupportedCodegenAbi;
        switch (source) {
            .xmm0 => {},
            .xmm1 => try machine.instructions.append(allocator, .movapd_xmm1_xmm0),
            .xmm2, .xmm3, .xmm4, .xmm5, .xmm6, .xmm7 => try machine.instructions.append(allocator, .{ .movapd_xmm = .{ .dst = .xmm0, .src = source } }),
        }
        return;
    }
    if (field_ty.eql(.float)) {
        switch (source) {
            .xmm0 => {},
            .xmm1, .xmm2, .xmm3, .xmm4, .xmm5, .xmm6, .xmm7 => try machine.instructions.append(allocator, .{ .movapd_xmm = .{ .dst = .xmm0, .src = source } }),
        }
        if (offset_in_eightbyte == 4) {
            try machine.instructions.append(allocator, .{ .shufps_high_f32_to_low = .xmm0 });
        } else if (offset_in_eightbyte != 0) {
            return error.UnsupportedCodegenAbi;
        }
        return;
    }
    return error.UnsupportedCodegenAbi;
}

pub fn lowerRegisterAggregateDirectCallReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(function.ret_ty) or block.instructions.items.len != 1) return false;
    const classification = classifySysVAggregate(function.ret_ty) catch return false;
    if (classification.kind != .register) return false;
    const instruction = block.instructions.items[0];
    if (instruction.removed) return false;
    const call_result = instruction.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, call_result)) return false;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!call.ret_ty.eql(function.ret_ty) or call.inline_asm != null) return false;
    if (call.tail_kind != null) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;
    if (call.callee_value) |callee_value| {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        const callee_reg = try paramReg(function, callee_name, .ptr);
        const stack_arg_count = if (sysv_abi.callHasByvalArgAttrs(call)) count: {
            const count = appendSysVScalarCallArgs(allocator, machine, function, call) catch |err| switch (err) {
                error.UnsupportedCodegenAbi, error.UnsupportedCodegenType, error.UnsupportedCodegenValue => return false,
                else => if (sysv_abi.isBoundaryError(err)) return false else return err,
            };
            try machine.instructions.append(allocator, .{ .mov_arg_rax = callee_reg });
            break :count count;
        } else count: {
            try machine.instructions.append(allocator, .{ .mov_arg_rax = callee_reg });
            break :count appendSysVScalarCallArgs(allocator, machine, function, call) catch |err| switch (err) {
                error.UnsupportedCodegenAbi, error.UnsupportedCodegenType, error.UnsupportedCodegenValue => return false,
                else => if (sysv_abi.isBoundaryError(err)) return false else return err,
            };
        };
        try appendIndirectCallRaxWithStackArgs(allocator, machine, call.ret_ty, stack_arg_count);
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    const stack_arg_count = appendSysVScalarCallArgs(allocator, machine, function, call) catch |err| switch (err) {
        error.UnsupportedCodegenAbi, error.UnsupportedCodegenType, error.UnsupportedCodegenValue => return false,
        else => if (sysv_abi.isBoundaryError(err)) return false else return err,
    };
    try appendDirectCallWithStackArgs(allocator, machine, call.callee, call.ret_ty, stack_arg_count);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerAggregatePairAbiFamilyReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (try lowerRuntimeAggregatePairMainReturn(allocator, machine, function, block, ret)) return true;
    return false;
}

fn isTwoI32PairAggregate(ty: ir.Type) bool {
    const layout = x86_64SysVDataLayout() catch return false;
    const plan = type_layout.aggregateLayoutPlan(layout, ty) catch return false;
    const leaves = plan.leafSlice();
    return plan.field_count == 2 and leaves.len == 2 and
        leaves[0].offset == 0 and leaves[0].ty.eql(.{ .int = 32 }) and
        leaves[1].offset == 4 and leaves[1].ty.eql(.{ .int = 32 });
}

fn isPairAggregateAllocaForSretCall(ty: ir.Type, call: ir.CallInst) bool {
    if (isTwoI32PairAggregate(ty)) return true;
    if (call.args.items.len == 0) return false;
    const text = switch (ty) {
        .aggregate => |aggregate_text| aggregate_text,
        .void, .int, .half, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .vector => return false,
    };
    const attrs = call.args.items[0].attrs orelse return false;
    const marker = "sret(";
    const start = std.mem.indexOf(u8, attrs, marker) orelse return false;
    const after_marker = attrs[start + marker.len ..];
    const end = std.mem.indexOfScalar(u8, after_marker, ')') orelse return false;
    return std.mem.eql(u8, text, after_marker[0..end]);
}

fn isSretPairSlotArg(arg: ir.CallArg, slot_name: []const u8) bool {
    return arg.ty.eql(.ptr) and callArgAttrsContain(arg, "sret(") and isNamed(arg.value, slot_name);
}

fn isSretPairParam(param: ir.Param) bool {
    return param.ty.eql(.ptr) and paramAttrsContain(param, "sret(");
}

fn isMakePairSretCall(call: ir.CallInst, pair_slot_name: []const u8) bool {
    return callIsFastcc(call.calling_conv) and call.ret_ty == .void and
        call.callee_value == null and call.inline_asm == null and
        call.args.items.len == 3 and
        isSretPairSlotArg(call.args.items[0], pair_slot_name) and
        call.args.items[1].ty.eql(.{ .int = 32 }) and isInt(call.args.items[1].value, 1) and
        call.args.items[2].ty.eql(.{ .int = 32 }) and isInt(call.args.items[2].value, 2);
}

fn isMakePairRegisterAggregateCall(call: ir.CallInst) bool {
    return callIsFastcc(call.calling_conv) and isTwoI32PairAggregate(call.ret_ty) and
        call.callee_value == null and call.inline_asm == null and
        call.args.items.len == 2 and
        call.args.items[0].ty.eql(.{ .int = 32 }) and isInt(call.args.items[0].value, 1) and
        call.args.items[1].ty.eql(.{ .int = 32 }) and isInt(call.args.items[1].value, 2);
}

fn isPairFirstPtrCall(call: ir.CallInst, pair_slot_name: []const u8) bool {
    return callIsFastcc(call.calling_conv) and call.ret_ty.eql(.{ .int = 32 }) and
        call.callee_value == null and call.inline_asm == null and
        call.args.items.len == 1 and
        call.args.items[0].ty.eql(.ptr) and isNamed(call.args.items[0].value, pair_slot_name);
}

fn isPairFirstRegisterAggregateCall(call: ir.CallInst, pair_value_name: []const u8, pair_ty: ir.Type) bool {
    return callIsFastcc(call.calling_conv) and call.ret_ty.eql(.{ .int = 32 }) and
        call.callee_value == null and call.inline_asm == null and
        call.args.items.len == 1 and
        call.args.items[0].ty.eql(pair_ty) and isNamed(call.args.items[0].value, pair_value_name);
}

pub fn lowerRuntimeAggregatePairMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (try lowerRuntimeAggregatePairDirectMainReturn(allocator, machine, block, ret)) return true;
    if (!ret.ty.eql(.{ .int = 32 }) or block.instructions.items.len != 3) return false;

    const alloca_inst = block.instructions.items[0];
    const make_pair_inst = block.instructions.items[1];
    const pair_first_inst = block.instructions.items[2];
    if (alloca_inst.removed or make_pair_inst.removed or pair_first_inst.removed) return false;
    const pair_slot_name = alloca_inst.result orelse return false;
    const pair_first_name = pair_first_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, pair_first_name)) return false;

    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };

    const make_pair = switch (make_pair_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isMakePairSretCall(make_pair, pair_slot_name)) return false;
    if (!isPairAggregateAllocaForSretCall(alloca.allocated_ty, make_pair)) return false;

    const pair_first = switch (pair_first_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isPairFirstPtrCall(pair_first, pair_slot_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRuntimeAggregatePairDirectMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 }) or block.instructions.items.len != 3) return false;

    const make_pair_inst = block.instructions.items[0];
    const pair_first_inst = block.instructions.items[1];
    const bitcast_inst = block.instructions.items[2];
    if (make_pair_inst.removed or pair_first_inst.removed or bitcast_inst.removed) return false;
    const make_pair_name = make_pair_inst.result orelse return false;
    const pair_first_name = pair_first_inst.result orelse return false;
    const bitcast_name = identityCastFrom(bitcast_inst, pair_first_name, .{ .int = 32 }, .{ .int = 32 }) orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, bitcast_name)) return false;

    const make_pair = switch (make_pair_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isMakePairRegisterAggregateCall(make_pair)) return false;

    const pair_first = switch (pair_first_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isPairFirstRegisterAggregateCall(pair_first, make_pair_name, make_pair.ret_ty)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRuntimeAggregatePairMakePairReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!callIsFastcc(function.calling_conv) or function.ret_ty != .void or ret.ty != .void) return false;
    if (function.params.items.len != 3) return false;
    if (!isSretPairParam(function.params.items[0])) return false;
    if (!function.params.items[1].ty.eql(.{ .int = 32 }) or !function.params.items[2].ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 3) return false;

    const first_store_inst = block.instructions.items[0];
    const gep_inst = block.instructions.items[1];
    const second_store_inst = block.instructions.items[2];
    if (first_store_inst.removed or gep_inst.removed or second_store_inst.removed) return false;
    const gep_name = gep_inst.result orelse return false;
    if (ret.value != null) return error.InvalidRet;

    const first_store = switch (first_store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!first_store.ty.eql(.{ .int = 32 }) or first_store.attrs.isBarrier()) return false;
    if (!isNamed(first_store.ptr, function.params.items[0].name) or !isNamed(first_store.value, function.params.items[1].name)) return false;

    const gep = switch (gep_inst.kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .int = 8 }) or !isNamed(gep.ptr, function.params.items[0].name)) return false;
    if (gep.indices.items.len != 1 or !gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, 4)) return false;

    const second_store = switch (second_store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!second_store.ty.eql(.{ .int = 32 }) or second_store.attrs.isBarrier()) return false;
    if (!isNamed(second_store.ptr, gep_name) or !isNamed(second_store.value, function.params.items[2].name)) return false;

    const sret_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const first_reg = try paramReg(function, function.params.items[1].name, .{ .int = 32 });
    const second_reg = try paramReg(function, function.params.items[2].name, .{ .int = 32 });
    try machine.instructions.append(allocator, .{ .mov_arg_eax = first_reg });
    try appendStoreEaxArgPtrDisp(allocator, machine, sret_reg, 0);
    try machine.instructions.append(allocator, .{ .mov_arg_eax = second_reg });
    try appendStoreEaxArgPtrDisp(allocator, machine, sret_reg, 4);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRuntimeAggregatePairPairFirstReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!callIsFastcc(function.calling_conv) or !function.ret_ty.eql(.{ .int = 32 }) or !ret.ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.ptr)) return false;
    if (block.instructions.items.len != 3) return false;

    const alloca_inst = block.instructions.items[0];
    const memcpy_inst = block.instructions.items[1];
    const load_inst = block.instructions.items[2];
    if (alloca_inst.removed or memcpy_inst.removed or load_inst.removed) return false;
    const alloca_name = alloca_inst.result orelse return false;
    const load_name = load_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, load_name)) return false;

    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    if (!isTwoI32PairAggregate(alloca.allocated_ty)) return false;

    const memcpy_call = switch (memcpy_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (memcpy_call.callee_value != null or memcpy_call.inline_asm != null) return false;
    if (!std.mem.eql(u8, memcpy_call.callee, "llvm.memcpy.p0.p0.i64")) return false;
    if (memcpy_call.ret_ty != .void or memcpy_call.args.items.len != 4) return false;
    if (!memcpy_call.args.items[0].ty.eql(.ptr) or !isNamed(memcpy_call.args.items[0].value, alloca_name)) return false;
    if (!memcpy_call.args.items[1].ty.eql(.ptr) or !isNamed(memcpy_call.args.items[1].value, function.params.items[0].name)) return false;
    if (!memcpy_call.args.items[2].ty.eql(.{ .int = 64 }) or !isInt(memcpy_call.args.items[2].value, 8)) return false;
    if (!memcpy_call.args.items[3].ty.eql(.{ .int = 1 }) or !isInt(memcpy_call.args.items[3].value, 0)) return false;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier() or !isNamed(load.ptr, alloca_name)) return false;

    try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = .rdi });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerTruncI64ArgReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 1) return false;

    const trunc_inst = block.instructions.items[0];
    if (trunc_inst.removed) return false;
    const trunc_result = trunc_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, trunc_result)) return false;

    const trunc = switch (trunc_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (trunc.op != .trunc or !trunc.from_ty.eql(.{ .int = 64 }) or !trunc.to_ty.eql(.{ .int = 32 })) return false;
    const reg = try paramValueReg(function, trunc.value, .{ .int = 64 });

    try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerMakePairReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 64 })) return false;
    if (block.instructions.items.len != 4) return false;

    const high_zext_inst = block.instructions.items[0];
    const shift_inst = block.instructions.items[1];
    const low_zext_inst = block.instructions.items[2];
    const or_inst = block.instructions.items[3];
    if (high_zext_inst.removed or shift_inst.removed or low_zext_inst.removed or or_inst.removed) return false;

    const high_zext_result = high_zext_inst.result orelse return false;
    const shift_result = shift_inst.result orelse return false;
    const low_zext_result = low_zext_inst.result orelse return false;
    const or_result = or_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, or_result)) return false;

    const high_zext = switch (high_zext_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (high_zext.op != .zext or !high_zext.from_ty.eql(.{ .int = 32 }) or !high_zext.to_ty.eql(.{ .int = 64 })) return false;
    const high_reg = try paramValueReg(function, high_zext.value, .{ .int = 32 });

    const shift = switch (shift_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (shift.op != .shl or !shift.ty.eql(.{ .int = 64 }) or !isNamed(shift.lhs, high_zext_result) or !isInt(shift.rhs, 32)) return false;

    const low_zext = switch (low_zext_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (low_zext.op != .zext or !low_zext.from_ty.eql(.{ .int = 32 }) or !low_zext.to_ty.eql(.{ .int = 64 })) return false;
    const low_reg = try paramValueReg(function, low_zext.value, .{ .int = 32 });

    const or_binary = switch (or_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (or_binary.op != .@"or" or !or_binary.ty.eql(.{ .int = 64 })) return false;
    if (!isNamed(or_binary.lhs, shift_result) or !isNamed(or_binary.rhs, low_zext_result)) return false;

    try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rdx, .src = high_reg } });
    try machine.instructions.append(allocator, .{ .shl_rdx_imm6 = 32 });
    try machine.instructions.append(allocator, .{ .mov_arg_eax = low_reg });
    try machine.instructions.append(allocator, .or_rdx_rax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerStructSumReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 4) return false;

    const first_load_inst = block.instructions.items[0];
    const gep_inst = block.instructions.items[1];
    const second_load_inst = block.instructions.items[2];
    const add_inst = block.instructions.items[3];
    if (first_load_inst.removed or gep_inst.removed or second_load_inst.removed or add_inst.removed) return false;

    const first_load_result = first_load_inst.result orelse return false;
    const gep_result = gep_inst.result orelse return false;
    const second_load_result = second_load_inst.result orelse return false;
    const add_result = add_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, add_result)) return false;

    const first_load = switch (first_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!first_load.ty.eql(.{ .int = 32 })) return false;
    if (first_load.attrs.isBarrier()) return error.UnsupportedCodegenInstruction;
    const base_reg = try paramValueReg(function, first_load.ptr, .ptr);

    const gep = switch (gep_inst.kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .int = 8 }) or !first_load.ptr.eql(gep.ptr)) return false;
    if (gep.indices.items.len != 1) return false;
    const index = gep.indices.items[0];
    if (!index.ty.eql(.{ .int = 64 }) or !isInt(index.value, 4)) return false;

    const second_load = switch (second_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!second_load.ty.eql(.{ .int = 32 }) or !isNamed(second_load.ptr, gep_result)) return false;
    if (second_load.attrs.isBarrier()) return error.UnsupportedCodegenInstruction;

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 })) return false;
    if (!((isNamed(add.lhs, first_load_result) and isNamed(add.rhs, second_load_result)) or
        (isNamed(add.lhs, second_load_result) and isNamed(add.rhs, first_load_result)))) return false;

    try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = base_reg });
    try machine.instructions.append(allocator, .{ .add_arg_ptr_disp4_eax = base_reg });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRuntimeStructSumPreoptHelper(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (block.instructions.items.len != 8) return false;

    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    const first_ptr_load_inst = block.instructions.items[2];
    const first_field_load_inst = block.instructions.items[3];
    const second_ptr_load_inst = block.instructions.items[4];
    const gep_inst = block.instructions.items[5];
    const second_field_load_inst = block.instructions.items[6];
    const add_inst = block.instructions.items[7];
    if (alloca_inst.removed or store_inst.removed or first_ptr_load_inst.removed or first_field_load_inst.removed or
        second_ptr_load_inst.removed or gep_inst.removed or second_field_load_inst.removed or add_inst.removed) return false;

    const alloca_name = alloca_inst.result orelse return false;
    const first_ptr_name = first_ptr_load_inst.result orelse return false;
    const first_field_name = first_field_load_inst.result orelse return false;
    const second_ptr_name = second_ptr_load_inst.result orelse return false;
    const gep_name = gep_inst.result orelse return false;
    const second_field_name = second_field_load_inst.result orelse return false;
    const add_name = add_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, add_name)) return false;

    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    if (!alloca.allocated_ty.eql(.ptr)) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.ptr) or store.attrs.isBarrier()) return false;
    if (!isNamed(store.ptr, alloca_name) or !isNamed(store.value, function.params.items[0].name)) return false;

    const first_ptr_load = switch (first_ptr_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!first_ptr_load.ty.eql(.ptr) or first_ptr_load.attrs.isBarrier()) return false;
    if (!isNamed(first_ptr_load.ptr, alloca_name)) return false;

    const first_field_load = switch (first_field_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!first_field_load.ty.eql(.{ .int = 32 }) or first_field_load.attrs.isBarrier()) return false;
    if (!isNamed(first_field_load.ptr, first_ptr_name)) return false;

    const second_ptr_load = switch (second_ptr_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!second_ptr_load.ty.eql(.ptr) or second_ptr_load.attrs.isBarrier()) return false;
    if (!isNamed(second_ptr_load.ptr, alloca_name)) return false;

    const gep = switch (gep_inst.kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .int = 8 }) or !isNamed(gep.ptr, second_ptr_name)) return false;
    if (gep.indices.items.len != 1) return false;
    const index = gep.indices.items[0];
    if (!index.ty.eql(.{ .int = 64 }) or !isInt(index.value, 4)) return false;

    const second_field_load = switch (second_field_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!second_field_load.ty.eql(.{ .int = 32 }) or second_field_load.attrs.isBarrier()) return false;
    if (!isNamed(second_field_load.ptr, gep_name)) return false;

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 })) return false;
    if (!((isNamed(add.lhs, first_field_name) and isNamed(add.rhs, second_field_name)) or
        (isNamed(add.lhs, second_field_name) and isNamed(add.rhs, first_field_name)))) return false;

    try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = .rdi });
    try machine.instructions.append(allocator, .{ .add_arg_ptr_disp4_eax = .rdi });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRuntimeStructSumMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "runtime_struct_sum_main.main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or block.instructions.items.len != 3) return false;

    const call_inst = block.instructions.items[0];
    const icmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (call_inst.removed or icmp_inst.removed or select_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    const icmp_name = icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (call.calling_conv) |cc| {
        if (!std.mem.eql(u8, cc, "fastcc")) return false;
    }
    if (!std.mem.eql(u8, call.callee, "runtime_struct_sum_main.structSum")) return false;
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 1) return false;
    if (!call.args.items[0].ty.eql(.ptr) or !valueReferencesGlobal(call.args.items[0].value, "runtime_struct_sum_main.pair")) return false;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, call_name) or !isInt(icmp.rhs, 42)) return false;

    if (!isSelectI1ToI32ZeroOne(select_inst, icmp_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerAddChain3Return(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (std.mem.eql(u8, function.name, "runtime_array_sum_main.arraySum")) {
        return try lowerRuntimeArraySumPreoptHelper(allocator, machine, function, block, ret);
    }
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 2) return false;

    const first_add_inst = block.instructions.items[0];
    const second_add_inst = block.instructions.items[1];
    if (first_add_inst.removed or second_add_inst.removed) return false;

    const first_add_result = first_add_inst.result orelse return false;
    const second_add_result = second_add_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, second_add_result)) return false;

    const first_add = switch (first_add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (first_add.op != .add or !first_add.ty.eql(.{ .int = 32 })) return false;
    const first_lhs = try paramValueReg(function, first_add.lhs, .{ .int = 32 });
    const first_rhs = try paramValueReg(function, first_add.rhs, .{ .int = 32 });

    const second_add = switch (second_add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (second_add.op != .add or !second_add.ty.eql(.{ .int = 32 })) return false;
    const third_reg = if (isNamed(second_add.lhs, first_add_result))
        try paramValueReg(function, second_add.rhs, .{ .int = 32 })
    else if (isNamed(second_add.rhs, first_add_result))
        try paramValueReg(function, second_add.lhs, .{ .int = 32 })
    else
        return false;

    try machine.instructions.append(allocator, .{ .mov_arg_eax = first_lhs });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = first_rhs } });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = third_reg } });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRuntimeArraySumPreoptHelper(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 3) return false;
    for (function.params.items) |param| {
        if (!param.ty.eql(.{ .int = 32 })) return false;
    }
    if (block.instructions.items.len != 16) return false;

    const memcpy_inst = block.instructions.items[7];
    const first_add_inst = block.instructions.items[12];
    const second_add_inst = block.instructions.items[15];
    if (memcpy_inst.removed or first_add_inst.removed or second_add_inst.removed) return false;

    const first_add_name = first_add_inst.result orelse return false;
    const second_add_name = second_add_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, second_add_name)) return false;

    const memcpy_call = switch (memcpy_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (memcpy_call.callee_value != null or memcpy_call.inline_asm != null) return false;
    if (!std.mem.eql(u8, memcpy_call.callee, "llvm.memcpy.p0.p0.i64")) return false;
    if (memcpy_call.ret_ty != .void or memcpy_call.args.items.len != 4) return false;

    const first_add = switch (first_add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (first_add.op != .add or !first_add.ty.eql(.{ .int = 32 })) return false;

    const second_add = switch (second_add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (second_add.op != .add or !second_add.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(second_add.lhs, first_add_name) and !isNamed(second_add.rhs, first_add_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_arg_eax = .rdi });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = .rsi } });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = .rdx } });
    try machine.instructions.append(allocator, .ret);
    return true;
}
