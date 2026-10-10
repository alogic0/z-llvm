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
const scalarParamStackDisp8 = cabi_abi_helpers.scalarParamStackDisp8;
const sysvIntegerParamRegOrNull = cabi_abi_helpers.sysvIntegerParamRegOrNull;
const emitGenericCfgI64ValueIntoRax = core_value_emit.emitGenericCfgI64ValueIntoRax;
const emitGenericCfgI32ValueIntoEax = core_value_emit.emitGenericCfgI32ValueIntoEax;

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
            .undef, .poison, .zero_initializer => break,
            .named => |name| {
                if (count >= reversed.len) return error.UnsupportedCodegenAbi;
                const instruction = findInstruction(block, name) orelse return error.UnsupportedCodegenInstruction;
                const insert = switch (instruction.kind) {
                    .insertvalue => |insert| insert,
                    else => return error.UnsupportedCodegenInstruction,
                };
                if (!insert.aggregate_ty.eql(aggregate_ty)) return error.UnsupportedCodegenType;
                const offset = try aggregateInsertByteOffset(aggregate_ty, insert.indices, insert.value_ty);
                var already_present = false;
                for (reversed[0..count]) |existing| {
                    if (existing.offset == offset) {
                        already_present = true;
                        break;
                    }
                }
                if (!already_present) {
                    reversed[count] = .{ .value = insert.value, .ty = insert.value_ty, .offset = offset };
                    count += 1;
                }
                current = insert.aggregate;
            },
            .int, .fp, .null_value, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        }
    }
    var index: usize = 0;
    while (index < count) : (index += 1) {
        leaves[index] = reversed[count - 1 - index];
    }
    std.mem.sort(AggregateReturnLeaf, leaves[0..count], {}, struct {
        fn lessThan(_: void, a: AggregateReturnLeaf, b: AggregateReturnLeaf) bool {
            return a.offset < b.offset;
        }
    }.lessThan);
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
        .rdx, .rcx, .r8, .r9 => try machine.instructions.append(allocator, .{ .mov_rax_to_arg = dst }),
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

const IntegerReturnDst = enum { rax, rdx };

fn emitInteger64Leaf(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    leaf: AggregateReturnLeaf,
    dst: IntegerReturnDst,
) !void {
    switch (leaf.value) {
        .int => |val| {
            if (val == 0) {
                switch (dst) {
                    .rax => try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 }),
                    .rdx => try machine.instructions.append(allocator, .xor_edx_edx),
                }
            } else {
                const i64_val = try x86_64_match.i64Value(val);
                switch (dst) {
                    .rax => try machine.instructions.append(allocator, .{ .mov_imm_rax = i64_val }),
                    .rdx => try machine.instructions.append(allocator, .{ .mov_imm_rdx = i64_val }),
                }
            }
        },
        .null_value, .zero_initializer => {
            switch (dst) {
                .rax => try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 }),
                .rdx => try machine.instructions.append(allocator, .xor_edx_edx),
            }
        },
        .named => |name| {
            const resolved_name = blk: {
                if (findInstruction(block, name)) |inst| {
                    if (inst.kind == .cast and inst.kind.cast.op == .trunc) {
                        if (inst.kind.cast.value == .named) break :blk inst.kind.cast.value.named;
                    }
                }
                break :blk name;
            };
            if (try sysvIntegerParamRegOrNull(function, resolved_name, leaf.ty)) |src| {
                switch (dst) {
                    .rax => try machine.instructions.append(allocator, .{ .mov_arg_rax = src }),
                    .rdx => {
                        if (src != .rdx) {
                            try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = .rdx, .src = src } });
                        }
                    },
                }
                return;
            }
            if (scalarParamStackDisp8(function, resolved_name, leaf.ty) catch null) |offset| {
                switch (dst) {
                    .rax => try appendLoadStackDispRax(allocator, machine, offset),
                    .rdx => try appendLoadStackDispArg64(allocator, machine, .rdx, offset),
                }
                return;
            }
            switch (dst) {
                .rax => try emitGenericCfgI64ValueIntoRax(allocator, machine, function, block, leaf.value),
                .rdx => {
                    try emitGenericCfgI64ValueIntoRax(allocator, machine, function, block, leaf.value);
                    try machine.instructions.append(allocator, .{ .mov_rax_to_arg = .rdx });
                },
            }
        },
        .fp, .undef, .poison, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

fn emitInteger32Leaf(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    leaf: AggregateReturnLeaf,
    dst: IntegerReturnDst,
) !void {
    switch (leaf.value) {
        .int => |val| {
            const i32_val = try x86_64_match.i32Value(val);
            switch (dst) {
                .rax => try machine.instructions.append(allocator, .{ .mov_imm_eax = i32_val }),
                .rdx => try machine.instructions.append(allocator, .{ .mov_imm_rdx = @as(u32, @bitCast(i32_val)) }),
            }
        },
        .null_value, .zero_initializer => {
            switch (dst) {
                .rax => try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 }),
                .rdx => try machine.instructions.append(allocator, .xor_edx_edx),
            }
        },
        .named => |name| {
            const resolved_name = blk: {
                if (findInstruction(block, name)) |inst| {
                    if (inst.kind == .cast and inst.kind.cast.op == .trunc) {
                        if (inst.kind.cast.value == .named) break :blk inst.kind.cast.value.named;
                    }
                }
                break :blk name;
            };
            if (try sysvIntegerParamRegOrNull(function, resolved_name, leaf.ty)) |src| {
                switch (dst) {
                    .rax => try machine.instructions.append(allocator, .{ .mov_arg_eax = src }),
                    .rdx => try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rdx, .src = src } }),
                }
                return;
            }
            switch (dst) {
                .rax => try emitGenericCfgI32ValueIntoEax(allocator, machine, function, block, leaf.value),
                .rdx => {
                    try emitGenericCfgI32ValueIntoEax(allocator, machine, function, block, leaf.value);
                    try machine.instructions.append(allocator, .{ .mov_rax_to_arg = .rdx });
                },
            }
        },
        .fp, .undef, .poison, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

fn emitPackedTwoI32Leaves(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    low_leaf: AggregateReturnLeaf,
    high_leaf: AggregateReturnLeaf,
    dst: IntegerReturnDst,
) !void {
    if (low_leaf.value == .int and high_leaf.value == .int) {
        const low_val = @as(u64, @as(u32, @bitCast(try x86_64_match.i32Value(low_leaf.value.int))));
        const high_val = @as(u64, @as(u32, @bitCast(try x86_64_match.i32Value(high_leaf.value.int))));
        const mask: u64 = switch (high_leaf.ty) {
            .int => |bits| if (bits >= 32) 0xffff_ffff else (@as(u64, 1) << @intCast(bits)) - 1,
            else => return error.UnsupportedCodegenType,
        };
        const combined: i64 = @bitCast(((high_val & mask) << 32) | low_val);
        switch (dst) {
            .rax => try machine.instructions.append(allocator, .{ .mov_imm_rax = combined }),
            .rdx => try machine.instructions.append(allocator, .{ .mov_imm_rdx = combined }),
        }
        return;
    }
    const low_reg = try paramValueReg(function, low_leaf.value, low_leaf.ty);
    const high_reg = try paramValueReg(function, high_leaf.value, high_leaf.ty);
    switch (dst) {
        .rax => {
            if (high_leaf.ty.eql(.{ .int = 32 })) {
                try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rdx, .src = high_reg } });
                try machine.instructions.append(allocator, .{ .shl_rdx_imm6 = 32 });
                try machine.instructions.append(allocator, .{ .mov_arg_eax = low_reg });
                try machine.instructions.append(allocator, .or_rdx_rax);
            } else {
                try machine.instructions.append(allocator, .{ .mov_arg_eax = high_reg });
                const mask: i32 = switch (high_leaf.ty.int) {
                    8 => 0xff,
                    16 => 0xffff,
                    else => return error.UnsupportedCodegenAbi,
                };
                try machine.instructions.append(allocator, .{ .and_eax_imm32 = mask });
                try machine.instructions.append(allocator, .{ .shl_rax_imm6 = 32 });
                try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rdx, .src = low_reg } });
                try machine.instructions.append(allocator, .or_rdx_rax);
            }
        },
        .rdx => {
            if (high_leaf.ty.eql(.{ .int = 32 })) {
                try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rcx, .src = high_reg } });
                try machine.instructions.append(allocator, .{ .shl_rcx_imm6 = 32 });
                try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rdx, .src = low_reg } });
                try machine.instructions.append(allocator, .or_rcx_rdx);
            } else {
                return error.UnsupportedCodegenAbi;
            }
        },
    }
}

fn isLeafConstant(leaf: AggregateReturnLeaf) bool {
    return switch (leaf.value) {
        .int, .zero_initializer, .null_value => true,
        else => false,
    };
}

fn areAllLeavesConstant(leaves: []const AggregateReturnLeaf) bool {
    for (leaves) |leaf| {
        if (!isLeafConstant(leaf)) return false;
    }
    return true;
}

fn computeConstantEightbyte(leaves: []const AggregateReturnLeaf, base_offset: usize) !u64 {
    var combined: u64 = 0;
    for (leaves) |leaf| {
        if (leaf.offset < base_offset or leaf.offset >= base_offset + 8) return error.UnsupportedCodegenAbi;
        const rel_offset = leaf.offset - base_offset;
        const bit_shift: u6 = @intCast(rel_offset * 8);
        const leaf_val: u64 = switch (leaf.value) {
            .int => |val| @truncate(@as(u128, @bitCast(val))),
            .zero_initializer, .null_value => 0,
            else => return error.UnsupportedCodegenValue,
        };
        const mask: u64 = switch (leaf.ty) {
            .int => |bits| if (bits >= 64) std.math.maxInt(u64) else (@as(u64, 1) << @intCast(bits)) - 1,
            .ptr => std.math.maxInt(u64),
            else => return error.UnsupportedCodegenType,
        };
        combined |= (leaf_val & mask) << bit_shift;
    }
    return combined;
}

fn emitConstantEightbyte(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    combined: u64,
    dst: IntegerReturnDst,
) !void {
    if (combined == 0) {
        switch (dst) {
            .rax => try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 }),
            .rdx => try machine.instructions.append(allocator, .xor_edx_edx),
        }
    } else if (combined <= std.math.maxInt(u32)) {
        switch (dst) {
            .rax => try machine.instructions.append(allocator, .{ .mov_imm_eax = @as(i32, @bitCast(@as(u32, @truncate(combined)))) }),
            .rdx => try machine.instructions.append(allocator, .{ .mov_imm_rdx = @as(i64, @intCast(combined)) }),
        }
    } else {
        const i64_val: i64 = @bitCast(combined);
        switch (dst) {
            .rax => try machine.instructions.append(allocator, .{ .mov_imm_rax = i64_val }),
            .rdx => try machine.instructions.append(allocator, .{ .mov_imm_rdx = i64_val }),
        }
    }
}

fn isEightByteIntegerAggregate(ty: ir.Type) bool {
    if (ty != .aggregate) return false;
    const classification = sysv_abi.classifyAggregate(ty) catch return false;
    return classification.kind == .register and
        classification.eightbyte_count == 1 and
        classification.eightbytes[0] == .integer and
        classification.size_bytes == 8;
}

fn emitIntegerEightbyte(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    leaves: []const AggregateReturnLeaf,
    dst: IntegerReturnDst,
    base_offset: usize,
) !void {
    if (leaves.len == 0) {
        switch (dst) {
            .rax => try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 }),
            .rdx => try machine.instructions.append(allocator, .xor_edx_edx),
        }
        return;
    }

    if (areAllLeavesConstant(leaves)) {
        const combined = try computeConstantEightbyte(leaves, base_offset);
        try emitConstantEightbyte(allocator, machine, combined, dst);
        return;
    }

    var dynamic_index: ?usize = null;
    var dynamic_count: usize = 0;
    for (leaves, 0..) |leaf, i| {
        if (!isLeafConstant(leaf)) {
            dynamic_index = i;
            dynamic_count += 1;
        }
    }

    if (dynamic_count == 1) {
        const dyn_leaf = leaves[dynamic_index.?];
        if (dyn_leaf.offset < base_offset or dyn_leaf.offset >= base_offset + 8) return error.UnsupportedCodegenAbi;
        const rel_offset = dyn_leaf.offset - base_offset;
        if (rel_offset == 0) {
            if (dyn_leaf.ty.eql(.{ .int = 64 }) or dyn_leaf.ty.eql(.ptr) or isEightByteIntegerAggregate(dyn_leaf.ty)) {
                try emitInteger64Leaf(allocator, machine, function, block, dyn_leaf, dst);
            } else if (switch (dyn_leaf.ty) { .int => |bits| bits <= 32, else => false }) {
                try emitInteger32Leaf(allocator, machine, function, block, dyn_leaf, dst);
            } else {
                return error.UnsupportedCodegenType;
            }
        } else {
            if (dyn_leaf.ty.eql(.{ .int = 32 }) and rel_offset == 4) {
                try emitInteger32Leaf(allocator, machine, function, block, dyn_leaf, dst);
                const shift_amt: u6 = @intCast(rel_offset * 8);
                switch (dst) {
                    .rax => try machine.instructions.append(allocator, .{ .shl_rax_imm6 = shift_amt }),
                    .rdx => try machine.instructions.append(allocator, .{ .shl_rdx_imm6 = shift_amt }),
                }
            } else {
                return error.UnsupportedCodegenType;
            }
        }

        if (leaves.len > 1) {
            var const_combined: u64 = 0;
            for (leaves, 0..) |leaf, i| {
                if (i == dynamic_index.?) continue;
                if (leaf.offset < base_offset or leaf.offset >= base_offset + 8) return error.UnsupportedCodegenAbi;
                const c_rel = leaf.offset - base_offset;
                const bit_shift: u6 = @intCast(c_rel * 8);
                const leaf_val: u64 = switch (leaf.value) {
                    .int => |val| @truncate(@as(u128, @bitCast(val))),
                    .zero_initializer, .null_value => 0,
                    else => 0,
                };
                const mask: u64 = switch (leaf.ty) {
                    .int => |bits| if (bits >= 64) std.math.maxInt(u64) else (@as(u64, 1) << @intCast(bits)) - 1,
                    .ptr => std.math.maxInt(u64),
                    else => return error.UnsupportedCodegenType,
                };
                const_combined |= (leaf_val & mask) << bit_shift;
            }
            if (const_combined != 0) {
                try machine.instructions.append(allocator, .{ .mov_imm_rcx = @bitCast(const_combined) });
                switch (dst) {
                    .rax => try machine.instructions.append(allocator, .or_rcx_rax),
                    .rdx => try machine.instructions.append(allocator, .or_rcx_rdx),
                }
            }
        }
        return;
    }

    if (leaves.len == 2) {
        const l0 = leaves[0];
        const l1 = leaves[1];
        if (l0.ty.eql(.{ .int = 32 }) and
            (l1.ty.eql(.{ .int = 32 }) or l1.ty.eql(.{ .int = 16 }) or l1.ty.eql(.{ .int = 8 })))
        {
            try emitPackedTwoI32Leaves(allocator, machine, function, l0, l1, dst);
            return;
        }
        return error.UnsupportedCodegenType;
    }
    return error.UnsupportedCodegenAbi;
}

fn emitSseLeaf(
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
            if (src != dst) {
                try machine.instructions.append(allocator, .{ .movapd_xmm = .{ .dst = dst, .src = src } });
            }
        },
        .fp => {
            if (leaf.ty.eql(.float)) {
                const bits = try x86_64_match.fp32TextBits(leaf.value);
                if (bits == 0) {
                    try machine.instructions.append(allocator, .{ .pxor_xmm = .{ .dst = dst, .src = dst } });
                } else switch (dst) {
                    .xmm0 => try machine.instructions.append(allocator, .{ .mov_imm32_xmm0 = bits }),
                    .xmm1 => try machine.instructions.append(allocator, .{ .mov_imm32_xmm1 = bits }),
                    else => return error.UnsupportedCodegenAbi,
                }
            } else if (leaf.ty.eql(.double)) {
                const bits = try x86_64_match.fp64TextBits(leaf.value);
                if (bits == 0) {
                    try machine.instructions.append(allocator, .{ .pxor_xmm = .{ .dst = dst, .src = dst } });
                } else switch (dst) {
                    .xmm0 => try machine.instructions.append(allocator, .{ .mov_imm64_xmm0 = bits }),
                    .xmm1 => try machine.instructions.append(allocator, .{ .mov_imm64_xmm1 = bits }),
                    else => return error.UnsupportedCodegenAbi,
                }
            } else return error.UnsupportedCodegenType;
        },
        .null_value, .zero_initializer => {
            try machine.instructions.append(allocator, .{ .pxor_xmm = .{ .dst = dst, .src = dst } });
        },
        .int, .undef, .poison, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

fn emitSseEightbyte(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    leaves: []const AggregateReturnLeaf,
    dst: XmmReg,
) !void {
    if (leaves.len == 0) {
        try machine.instructions.append(allocator, .{ .pxor_xmm = .{ .dst = dst, .src = dst } });
        return;
    }
    if (leaves.len == 1) {
        try emitSseLeaf(allocator, machine, function, leaves[0], dst);
        return;
    }
    if (leaves.len == 2) {
        const l0 = leaves[0];
        const l1 = leaves[1];
        if (l0.ty.eql(.float) and l1.ty.eql(.float)) {
            const low_fp_index = try fpParamIndexFromValue(function, l0.value, .float);
            const high_fp_index = try fpParamIndexFromValue(function, l1.value, .float);
            const low_reg = try XmmReg.fromIndex(low_fp_index);
            const high_reg = try XmmReg.fromIndex(high_fp_index);
            if (low_reg != dst) {
                try machine.instructions.append(allocator, .{ .movapd_xmm = .{ .dst = dst, .src = low_reg } });
            }
            if (high_reg != dst) {
                try machine.instructions.append(allocator, .{ .unpcklps_xmm = .{ .dst = dst, .src = high_reg } });
            }
            return;
        }
        return error.UnsupportedCodegenType;
    }
    return error.UnsupportedCodegenAbi;
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

    const ret_val = ret.value orelse return false;
    if (ret_val == .zero_initializer or ret_val == .null_value) {
        for (0..classification.eightbyte_count) |i| {
            const class = classification.eightbytes[i] orelse break;
            switch (class) {
                .integer => switch (i) {
                    0 => try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 }),
                    1 => try machine.instructions.append(allocator, .xor_edx_edx),
                    else => return false,
                },
                .sse => switch (i) {
                    0 => try machine.instructions.append(allocator, .{ .pxor_xmm = .{ .dst = .xmm0, .src = .xmm0 } }),
                    1 => {
                        const dst: XmmReg = if (classification.eightbytes[0] == .sse) .xmm1 else .xmm0;
                        try machine.instructions.append(allocator, .{ .pxor_xmm = .{ .dst = dst, .src = dst } });
                    },
                    else => return false,
                },
            }
        }
        try machine.instructions.append(allocator, .ret);
        return true;
    }

    const ret_name = switch (ret_val) {
        .named => |name| name,
        else => return false,
    };

    var leaves: [8]AggregateReturnLeaf = undefined;
    const leaf_count = collectConstructedAggregateLeaves(block, function.ret_ty, ret_name, &leaves) catch return false;
    if (leaf_count == 0) return false;

    if (try lowerFourI32RegisterAggregateReturn(allocator, machine, function, leaves[0..leaf_count], classification)) return true;

    var eb0_leaves_buf: [4]AggregateReturnLeaf = undefined;
    var eb0_count: usize = 0;
    var eb1_leaves_buf: [4]AggregateReturnLeaf = undefined;
    var eb1_count: usize = 0;

    for (leaves[0..leaf_count]) |leaf| {
        if (leaf.offset < 8) {
            if (eb0_count >= eb0_leaves_buf.len) return error.UnsupportedCodegenAbi;
            eb0_leaves_buf[eb0_count] = leaf;
            eb0_count += 1;
        } else if (leaf.offset < 16) {
            if (eb1_count >= eb1_leaves_buf.len) return error.UnsupportedCodegenAbi;
            eb1_leaves_buf[eb1_count] = leaf;
            eb1_count += 1;
        } else return error.UnsupportedCodegenAbi;
    }
    const eb0_leaves = eb0_leaves_buf[0..eb0_count];
    const eb1_leaves = eb1_leaves_buf[0..eb1_count];

    const class0 = classification.eightbytes[0] orelse return error.UnsupportedCodegenAbi;

    if (classification.eightbyte_count == 1) {
        switch (class0) {
            .integer => try emitIntegerEightbyte(allocator, machine, function, block, eb0_leaves, .rax, 0),
            .sse => try emitSseEightbyte(allocator, machine, function, eb0_leaves, .xmm0),
        }
        try machine.instructions.append(allocator, .ret);
        return true;
    }

    if (classification.eightbyte_count == 2) {
        const class1 = classification.eightbytes[1] orelse return error.UnsupportedCodegenAbi;
        switch (class0) {
            .integer => switch (class1) {
                .integer => {
                    const eb1_needs_rax_scratch = eb1_leaves.len > 0 and
                        eb1_leaves[0].value == .named and
                        (sysvIntegerParamRegOrNull(function, eb1_leaves[0].value.named, eb1_leaves[0].ty) catch null) == null and
                        (scalarParamStackDisp8(function, eb1_leaves[0].value.named, eb1_leaves[0].ty) catch null) == null;

                    const eb0_uses_rdx = eb0_leaves.len > 0 and
                        eb0_leaves[0].value == .named and
                        (sysvIntegerParamRegOrNull(function, eb0_leaves[0].value.named, eb0_leaves[0].ty) catch null) == .rdx;

                    if (eb1_needs_rax_scratch) {
                        if (eb0_uses_rdx) {
                            try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = .rcx, .src = .rdx } });
                            try emitIntegerEightbyte(allocator, machine, function, block, eb1_leaves, .rdx, 8);
                            try machine.instructions.append(allocator, .{ .mov_arg_rax = .rcx });
                        } else {
                            try emitIntegerEightbyte(allocator, machine, function, block, eb1_leaves, .rdx, 8);
                            try emitIntegerEightbyte(allocator, machine, function, block, eb0_leaves, .rax, 0);
                        }
                    } else {
                        try emitIntegerEightbyte(allocator, machine, function, block, eb0_leaves, .rax, 0);
                        try emitIntegerEightbyte(allocator, machine, function, block, eb1_leaves, .rdx, 8);
                    }
                },
                .sse => {
                    try emitIntegerEightbyte(allocator, machine, function, block, eb0_leaves, .rax, 0);
                    try emitSseEightbyte(allocator, machine, function, eb1_leaves, .xmm0);
                },
            },
            .sse => switch (class1) {
                .integer => {
                    try emitSseEightbyte(allocator, machine, function, eb0_leaves, .xmm0);
                    try emitIntegerEightbyte(allocator, machine, function, block, eb1_leaves, .rax, 8);
                },
                .sse => {
                    try emitSseEightbyte(allocator, machine, function, eb0_leaves, .xmm0);
                    try emitSseEightbyte(allocator, machine, function, eb1_leaves, .xmm1);
                },
            },
        }
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    return false;
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
