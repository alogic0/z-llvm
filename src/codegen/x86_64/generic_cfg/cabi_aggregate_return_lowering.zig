const std = @import("std");
const ir = @import("../../../ir.zig");
const target = @import("../../../target.zig");
const x86_64_types = @import("../types.zig");
const sysv_abi = @import("../sysv_abi.zig");
const x86_64_emit = @import("../emit.zig");
const x86_64_match = @import("../match.zig");
const x86_64_machine = @import("../machine.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");
const cabi_call_lowering = @import("cabi_call_lowering.zig");
const core_value_emit = @import("core_value_emit.zig");

const ArgReg = x86_64_types.ArgReg;
const XmmReg = x86_64_types.XmmReg;
const MachineFunction = x86_64_machine.MachineFunction;
const SysVAggregateClassification = sysv_abi.AggregateClassification;
const SysVCallTarget = x86_64_emit.SysVCallTarget;

const appendSysVMemoryAggregateStackPassThroughArgs = cabi_call_lowering.appendSysVMemoryAggregateStackPassThroughArgs;
const findInstruction = cabi_call_lowering.findInstruction;
const sysvParamCursorForWithInitial = cabi_call_lowering.sysvParamCursorForWithInitial;

const fpParamIndex = cabi_abi_helpers.fpParamIndex;
const paramReg = cabi_abi_helpers.paramReg;
const paramRegWithInitialGpr = cabi_abi_helpers.paramRegWithInitialGpr;
const paramValueReg = cabi_abi_helpers.paramValueReg;
const sysvIntegerParamRegOrNull = cabi_abi_helpers.sysvIntegerParamRegOrNull;
const emitGenericCfgI64ValueIntoRax = core_value_emit.emitGenericCfgI64ValueIntoRax;

const appendSysVCallTargetWithStackArgs = x86_64_emit.appendSysVCallTargetWithStackArgs;
const appendDirectCallWithStackArgs = x86_64_emit.appendDirectCallWithStackArgs;
const appendLoadStackDispArg64 = x86_64_emit.appendLoadStackDispArg64;
const appendMoveImm32ToXmm = x86_64_emit.appendMoveImm32ToXmm;
const appendMoveImm64ToXmm = x86_64_emit.appendMoveImm64ToXmm;
const setupSysVCallTarget = x86_64_emit.setupSysVCallTarget;

const callIsFastcc = x86_64_match.callIsFastcc;
const isNamed = x86_64_match.isNamed;
const validateDefaultCallConv = x86_64_match.validateDefaultCallConv;
const aggregate_classification = @import("cabi_aggregate_classification.zig");
const aggregate_fields = @import("cabi_aggregate_fields.zig");
const aggregate_copy = @import("cabi_aggregate_copy.zig");
const classifySysVAggregate = aggregate_classification.classifySysVAggregate;
const classifySysVSmallIntegerAggregate = aggregate_classification.classifySysVSmallIntegerAggregate;
const AggregateReturnLeaf = aggregate_classification.AggregateReturnLeaf;
const aggregateInsertByteOffset = aggregate_classification.aggregateInsertByteOffset;
const fpParamIndexFromValue = aggregate_classification.fpParamIndexFromValue;
const valuesEqual = aggregate_classification.valuesEqual;
const isAggregateType = aggregate_classification.isAggregateType;
const appendLoadStackDispRax = aggregate_fields.appendLoadStackDispRax;
const appendLoadStackDispXmm = aggregate_fields.appendLoadStackDispXmm;
const isSupportedAggregateCopyLeafAggregate = aggregate_copy.isSupportedAggregateCopyLeafAggregate;
const aggregate_field_returns = @import("cabi_aggregate_field_returns.zig");
const aggregate_runtime_returns = @import("cabi_aggregate_runtime_returns.zig");
pub const lowerSysVAggregateFieldReturn = aggregate_field_returns.lowerSysVAggregateFieldReturn;
pub const lowerRegisterAggregateCallIntegerFieldAddReturn = aggregate_field_returns.lowerRegisterAggregateCallIntegerFieldAddReturn;
pub const lowerRegisterAggregateIntegerFieldAddReturn = aggregate_field_returns.lowerRegisterAggregateIntegerFieldAddReturn;
pub const lowerRegisterAggregateFloatFieldAddReturn = aggregate_field_returns.lowerRegisterAggregateFloatFieldAddReturn;
pub const lowerRegisterAggregateDoubleFieldAddReturn = aggregate_field_returns.lowerRegisterAggregateDoubleFieldAddReturn;
pub const lowerMemoryIntegerAggregateFieldAddReturn = aggregate_field_returns.lowerMemoryIntegerAggregateFieldAddReturn;
pub const lowerRegisterAggregateCallFieldReturn = aggregate_field_returns.lowerRegisterAggregateCallFieldReturn;
pub const lowerRegisterAggregateDirectCallReturn = aggregate_field_returns.lowerRegisterAggregateDirectCallReturn;
pub const lowerAggregatePairAbiFamilyReturn = aggregate_runtime_returns.lowerAggregatePairAbiFamilyReturn;
pub const lowerRuntimeAggregatePairMainReturn = aggregate_runtime_returns.lowerRuntimeAggregatePairMainReturn;
pub const lowerRuntimeAggregatePairDirectMainReturn = aggregate_runtime_returns.lowerRuntimeAggregatePairDirectMainReturn;
pub const lowerRuntimeAggregatePairMakePairReturn = aggregate_runtime_returns.lowerRuntimeAggregatePairMakePairReturn;
pub const lowerRuntimeAggregatePairPairFirstReturn = aggregate_runtime_returns.lowerRuntimeAggregatePairPairFirstReturn;
pub const lowerTruncI64ArgReturn = aggregate_runtime_returns.lowerTruncI64ArgReturn;
pub const lowerMakePairReturn = aggregate_runtime_returns.lowerMakePairReturn;
pub const lowerStructSumReturn = aggregate_runtime_returns.lowerStructSumReturn;
pub const lowerRuntimeStructSumPreoptHelper = aggregate_runtime_returns.lowerRuntimeStructSumPreoptHelper;
pub const lowerRuntimeStructSumMainReturn = aggregate_runtime_returns.lowerRuntimeStructSumMainReturn;
pub const lowerAddChain3Return = aggregate_runtime_returns.lowerAddChain3Return;
pub const lowerRuntimeArraySumPreoptHelper = aggregate_runtime_returns.lowerRuntimeArraySumPreoptHelper;

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
