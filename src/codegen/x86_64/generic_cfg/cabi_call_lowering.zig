const std = @import("std");
const ir = @import("../../../ir.zig");
const sysv_abi = @import("../sysv_abi.zig");
const x86_64_emit = @import("../emit.zig");
const x86_64_match = @import("../match.zig");
const x86_64_types = @import("../types.zig");
const x86_64_machine = @import("../machine.zig");
const core_value_support = @import("core_value_support.zig");
const core_value_emit = @import("core_value_emit.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");
const core_cfg_emit = @import("core_cfg_emit.zig");

const MachineBinaryOp = x86_64_types.MachineBinaryOp;
const ArgReg = x86_64_types.ArgReg;
const XmmReg = x86_64_types.XmmReg;
const MachineFunction = x86_64_machine.MachineFunction;
const FrameIndex = x86_64_types.FrameIndex;
const SysVCallPlanCounts = sysv_abi.CallPlanCounts;
const SysVRegisterNeeds = sysv_abi.RegisterNeeds;
const SysVRegisterAggregatePassThrough = sysv_abi.RegisterAggregatePassThrough;
const SysVAggregateClassification = sysv_abi.AggregateClassification;
const SysVCallPlan = sysv_abi.CallPlan;
const SysVParamCursor = sysv_abi.ParamCursor;
const SysVCallTarget = x86_64_emit.SysVCallTarget;
const max_sysv_stack_call_args = x86_64_emit.max_sysv_stack_call_args;
const appendStackFrame = x86_64_emit.appendStackFrame;
const appendStackFrameEnd = x86_64_emit.appendStackFrameEnd;
const appendDirectCall = x86_64_emit.appendDirectCall;
const appendDirectCallWithStackArgs = x86_64_emit.appendDirectCallWithStackArgs;
const appendIndirectCallRaxWithStackArgs = x86_64_emit.appendIndirectCallRaxWithStackArgs;
const appendLoadStackDispArg32 = x86_64_emit.appendLoadStackDispArg32;
const appendLoadStackDispArg64 = x86_64_emit.appendLoadStackDispArg64;
const appendMoveImmToArgReg = x86_64_emit.appendMoveImmToArgReg;
const appendMoveImm32ToXmm = x86_64_emit.appendMoveImm32ToXmm;
const appendMoveImm64ToXmm = x86_64_emit.appendMoveImm64ToXmm;
const setupSysVCallTarget = x86_64_emit.setupSysVCallTarget;
const appendSysVCallTarget = x86_64_emit.appendSysVCallTarget;
const appendAlignedSysVCallTarget = x86_64_emit.appendAlignedSysVCallTarget;
const appendSysVCallTargetWithStackArgs = x86_64_emit.appendSysVCallTargetWithStackArgs;
const validateDefaultCallConv = x86_64_match.validateDefaultCallConv;
const callIsFastcc = x86_64_match.callIsFastcc;
const isNamed = x86_64_match.isNamed;
const isCalleeName = x86_64_match.isCalleeName;
const isInt = x86_64_match.isInt;
const i32Value = x86_64_match.i32Value;
const u8Value = x86_64_match.u8Value;
const i64Value = x86_64_match.i64Value;
const symbolName = x86_64_match.symbolName;
const fp32TextBits = x86_64_match.fp32TextBits;
const fp64TextBits = x86_64_match.fp64TextBits;
const paramValueReg = cabi_abi_helpers.paramValueReg;
const paramReg = cabi_abi_helpers.paramReg;
const sysvIntegerParamReg = cabi_abi_helpers.sysvIntegerParamReg;
const sysvIntegerParamRegOrNull = cabi_abi_helpers.sysvIntegerParamRegOrNull;
const paramRegOrNull = cabi_abi_helpers.paramRegOrNull;
const paramRegWithInitialGpr = cabi_abi_helpers.paramRegWithInitialGpr;
const scalarParamStackDisp8 = cabi_abi_helpers.scalarParamStackDisp8;
const fpParamIndex = cabi_abi_helpers.fpParamIndex;
const stackParamDisp8OrNull = cabi_abi_helpers.stackParamDisp8OrNull;
const registerParamRegOrNull = cabi_abi_helpers.registerParamRegOrNull;
const advanceSysVParamCursors = cabi_abi_helpers.advanceSysVParamCursors;
const genericCfgSupportsI1Param = core_value_support.genericCfgSupportsI1Param;
const genericCfgSupportsSminSelect = core_value_support.genericCfgSupportsSminSelect;
const genericCfgSupportsSingleBlockI32Value = core_value_support.genericCfgSupportsSingleBlockI32Value;
const genericCfgSupportsI64Value = core_value_support.genericCfgSupportsI64Value;
const emitGenericCfgI32ValueIntoEax = core_value_emit.emitGenericCfgI32ValueIntoEax;
const emitGenericCfgI64ValueIntoRax = core_value_emit.emitGenericCfgI64ValueIntoRax;
const GenericCfgBranchKind = core_cfg_emit.GenericCfgBranchKind;
const appendGenericCfgBlockLabel = core_cfg_emit.appendGenericCfgBlockLabel;
const appendGenericCfgConditionalBranch = core_cfg_emit.appendGenericCfgConditionalBranch;
const appendGenericCfgCompareParamZero = core_cfg_emit.appendGenericCfgCompareParamZero;
const appendGenericCfgCompareLocalImm = core_cfg_emit.appendGenericCfgCompareLocalImm;

fn sysvAggregateRegisterNeeds(classification: SysVAggregateClassification) SysVRegisterNeeds {
    return sysv_abi.aggregateRegisterNeeds(classification);
}

fn appendLoadStackDispXmm(allocator: std.mem.Allocator, machine: *MachineFunction, reg: XmmReg, offset: u32) !void {
    if (offset <= std.math.maxInt(i8)) {
        try machine.instructions.append(allocator, .{ .load_stack_disp8_xmm = .{ .reg = reg, .disp = @intCast(offset) } });
    } else {
        try machine.instructions.append(allocator, .{ .load_stack_disp32_xmm = .{ .reg = reg, .disp = offset } });
    }
}

pub fn appendI32CallArgs(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    call: ir.CallInst,
) !usize {
    var plan = try planSysVCall(allocator, function, call);
    defer plan.deinit(allocator);
    if (plan.has_non_i32_arg) return error.UnsupportedCodegenType;
    if (plan.counts.stack_args > max_sysv_stack_call_args) return error.UnsupportedCodegenAbi;

    var stack_args: [max_sysv_stack_call_args]StackScalarCallArg = undefined;
    var stack_arg_count: usize = 0;
    for (call.args.items, 0..) |arg, index| {
        const assignment = plan.assignments.items[index];
        switch (assignment) {
            .gpr => |dst| switch (arg.value) {
                .int => |int| try appendMoveImmToArgReg(allocator, machine, dst, try i64Value(int)),
                .named => |name| {
                    if (paramRegOrNull(function, name, .{ .int = 32 }) catch |err| switch (err) {
                        error.UnsupportedCodegenAbi => null,
                        else => return err,
                    }) |src| {
                        if (src != dst) try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = dst, .src = src } });
                    } else {
                        try appendLoadStackDispArg32(allocator, machine, dst, try scalarParamStackDisp8(function, name, .{ .int = 32 }));
                    }
                },
                .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
            },
            .stack_i32_const => |value| {
                stack_args[stack_arg_count] = .{ .imm = value };
                stack_arg_count += 1;
            },
            .stack_i32_param => |name| {
                stack_args[stack_arg_count] = .{ .stack_disp = try scalarParamStackDisp8(function, name, .{ .int = 32 }) };
                stack_arg_count += 1;
            },
            .sse, .byval_stack_copy, .aggregate_register_passthrough, .aggregate_stack_passthrough => return error.UnsupportedCodegenType,
        }
    }

    var reserved_stack_bytes: usize = 0;
    if (stack_arg_count != 0 and stack_arg_count % 2 == 0) {
        try machine.instructions.append(allocator, .sub_rsp_8);
        reserved_stack_bytes = 8;
    }
    var index = stack_arg_count;
    while (index > 0) {
        index -= 1;
        try appendStackScalarCallArg(allocator, machine, function, null, stack_args[index], reserved_stack_bytes);
        reserved_stack_bytes += 8;
    }
    return stack_arg_count;
}

pub fn i32CallStackArgCount(call: ir.CallInst) !usize {
    if (call.args.items.len > max_sysv_stack_call_args + 6) return error.UnsupportedCodegenAbi;
    var stack_arg_count: usize = 0;
    for (call.args.items, 0..) |arg, index| {
        if (!arg.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
        if (index >= 6) {
            switch (arg.value) {
                .int, .named => {},
                .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
            }
            stack_arg_count += 1;
        }
    }
    return stack_arg_count;
}

pub fn appendSysVScalarCallArgs(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    call: ir.CallInst,
) !usize {
    return (try appendSysVScalarCallArgsWithBlockAndAlignment(allocator, machine, function, null, call, .entry_unaligned)).stack_arg_count;
}

pub fn appendSysVScalarCallArgsWithBlock(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    maybe_block: ?ir.BasicBlock,
    call: ir.CallInst,
) anyerror!usize {
    return (try appendSysVScalarCallArgsWithBlockAndAlignment(allocator, machine, function, maybe_block, call, .entry_unaligned)).stack_arg_count;
}

const StackArgAlignment = enum {
    entry_unaligned,
    already_aligned,
};

const StackArgEmission = struct {
    stack_arg_count: usize,
    cleanup_bytes: usize,
};

fn appendSysVScalarCallArgsWithBlockAndAlignment(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    maybe_block: ?ir.BasicBlock,
    call: ir.CallInst,
    alignment: StackArgAlignment,
) anyerror!StackArgEmission {
    var plan = try planSysVCall(allocator, function, call);
    defer plan.deinit(allocator);
    if (plan.counts.stack_args > max_sysv_stack_call_args) return error.UnsupportedCodegenAbi;
    const gpr_copy_plan = try analyzeGprArgCopyPlan(function, call, plan);
    const xmm_copy_plan = try analyzeXmmArgCopyPlan(function, call, plan);

    var stack_args: [max_sysv_stack_call_args]StackScalarCallArg = undefined;
    var stack_arg_count: usize = 0;
    for (call.args.items, 0..) |arg, index| {
        const assignment = plan.assignments.items[index];
        switch (assignment) {
            .gpr, .sse, .aggregate_register_passthrough => {},
            .stack_i32_const => |value| {
                stack_args[stack_arg_count] = .{ .imm = value };
                stack_arg_count += 1;
            },
            .stack_i32_param => |name| {
                if (sysvIntegerParamRegOrNull(function, name, arg.ty) catch |err| switch (err) {
                    error.UnsupportedCodegenAbi => null,
                    else => return err,
                }) |src| {
                    stack_args[stack_arg_count] = .{ .arg_reg = src };
                } else if (scalarParamStackDisp8(function, name, arg.ty) catch |err| switch (err) {
                    error.UnsupportedCodegenValue => null,
                    else => return err,
                }) |disp| {
                    stack_args[stack_arg_count] = .{ .stack_disp = disp };
                } else if (arg.ty.eql(.{ .int = 32 })) {
                    const block = maybe_block orelse return error.UnsupportedCodegenAbi;
                    if (!genericCfgSupportsSingleBlockI32Value(function, block, .{ .named = name })) return error.UnsupportedCodegenValue;
                    stack_args[stack_arg_count] = .{ .computed_i32 = .{ .named = name } };
                } else if (arg.ty.eql(.{ .int = 64 })) {
                    _ = maybe_block orelse return error.UnsupportedCodegenAbi;
                    if (!genericCfgSupportsI64Value(function, .{ .named = name })) return error.UnsupportedCodegenValue;
                    stack_args[stack_arg_count] = .{ .computed_i64 = .{ .named = name } };
                } else {
                    return error.UnsupportedCodegenAbi;
                }
                stack_arg_count += 1;
            },
            .aggregate_stack_passthrough => |aggregate| {
                try appendSysVStackAggregatePassThroughArgs(&stack_args, &stack_arg_count, aggregate);
            },
            .byval_stack_copy => |copy| {
                try appendSysVByvalStackCopyArgs(function, &stack_args, &stack_arg_count, copy);
            },
        }
    }
    var precomputed_stack_arg = false;
    for (stack_args[0..stack_arg_count]) |*stack_arg| {
        switch (stack_arg.*) {
            .computed_i32 => |value| {
                if (precomputed_stack_arg) return error.UnsupportedCodegenAbi;
                const block = maybe_block orelse return error.UnsupportedCodegenAbi;
                try emitGenericCfgI32ValueIntoEax(allocator, machine, function, block, value);
                stack_arg.* = .precomputed_rax;
                precomputed_stack_arg = true;
            },
            .computed_i64 => |value| {
                if (precomputed_stack_arg) return error.UnsupportedCodegenAbi;
                const block = maybe_block orelse return error.UnsupportedCodegenAbi;
                try emitGenericCfgI64ValueIntoRax(allocator, machine, function, block, value);
                stack_arg.* = .precomputed_rax;
                precomputed_stack_arg = true;
            },
            else => {},
        }
    }

    var reserved_stack_bytes: usize = 0;
    const needs_padding = stack_arg_count != 0 and switch (alignment) {
        .entry_unaligned => stack_arg_count % 2 == 0,
        .already_aligned => stack_arg_count % 2 == 1,
    };
    if (needs_padding) {
        try machine.instructions.append(allocator, .sub_rsp_8);
        reserved_stack_bytes = 8;
    }
    var stack_index = stack_arg_count;
    while (stack_index > 0) {
        stack_index -= 1;
        try appendStackScalarCallArg(allocator, machine, function, maybe_block, stack_args[stack_index], reserved_stack_bytes);
        reserved_stack_bytes += 8;
    }
    const incoming_stack_adjust = reserved_stack_bytes;

    if (gpr_copy_plan.parallel) {
        try appendParallelGprArgCopies(allocator, machine, gpr_copy_plan);
    }
    if (xmm_copy_plan.parallel) {
        try appendParallelXmmArgCopies(allocator, machine, xmm_copy_plan);
    }

    for (call.args.items, 0..) |arg, index| {
        const assignment = plan.assignments.items[index];
        switch (assignment) {
            .gpr => |dst| {
                if (!arg.ty.eql(.{ .int = 32 }) and !arg.ty.eql(.{ .int = 64 }) and arg.ty != .ptr) return error.UnsupportedCodegenType;
                switch (arg.value) {
                    .int => |int| try appendMoveImmToArgReg(allocator, machine, dst, try i64Value(int)),
                    .null_value => if (arg.ty == .ptr)
                        try appendMoveImmToArgReg(allocator, machine, dst, 0)
                    else
                        return error.UnsupportedCodegenValue,
                    .named => |name| {
                        if (sysvIntegerParamRegOrNull(function, name, arg.ty) catch |err| switch (err) {
                            error.UnsupportedCodegenAbi => null,
                            else => return err,
                        }) |src| {
                            if (gpr_copy_plan.parallel) {
                                if (src == dst) continue;
                                if (!gprCopyPlanContains(gpr_copy_plan, dst, src)) return error.UnsupportedCodegenAbi;
                            } else if (src != dst) {
                                try machine.instructions.append(allocator, if (arg.ty.eql(.{ .int = 64 }) or arg.ty == .ptr)
                                    .{ .mov_arg64_arg = .{ .dst = dst, .src = src } }
                                else
                                    .{ .mov_arg_arg = .{ .dst = dst, .src = src } });
                            }
                        } else if (arg.ty.eql(.{ .int = 32 })) {
                            try appendLoadStackDispArg32(allocator, machine, dst, @as(usize, try scalarParamStackDisp8(function, name, .{ .int = 32 })) + incoming_stack_adjust);
                        } else if (arg.ty.eql(.{ .int = 64 }) or arg.ty == .ptr) {
                            try appendLoadStackDispArg64(allocator, machine, dst, @as(usize, try scalarParamStackDisp8(function, name, arg.ty)) + incoming_stack_adjust);
                        }
                    },
                    .fp, .undef, .poison, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
                }
            },
            .sse => |dst| {
                if (!arg.ty.eql(.float) and !arg.ty.eql(.double)) return error.UnsupportedCodegenType;
                switch (arg.value) {
                    .fp => if (arg.ty.eql(.float))
                        try appendMoveImm32ToXmm(allocator, machine, dst, try fp32TextBits(arg.value))
                    else
                        try appendMoveImm64ToXmm(allocator, machine, dst, try fp64TextBits(arg.value)),
                    .named => |name| {
                        if ((if (arg.ty.eql(.float))
                            fpParamIndex(function, name, .float)
                        else
                            fpParamIndex(function, name, .double)) catch |err| switch (err) {
                            error.UnsupportedCodegenAbi => null,
                            else => return err,
                        }) |src_index| {
                            const dst_index: usize = @intFromEnum(dst);
                            if (src_index != dst_index) {
                                if (xmm_copy_plan.parallel) {
                                    if (!xmmCopyPlanContains(xmm_copy_plan, dst, try XmmReg.fromIndex(src_index))) return error.UnsupportedCodegenAbi;
                                    continue;
                                }
                                try machine.instructions.append(allocator, .{ .movapd_xmm = .{
                                    .dst = dst,
                                    .src = try XmmReg.fromIndex(src_index),
                                } });
                            }
                        } else if (arg.ty.eql(.double)) {
                            try appendLoadStackDispXmm(
                                allocator,
                                machine,
                                dst,
                                try adjustedIncomingStackDisp8(try scalarParamStackDisp8(function, name, .double), incoming_stack_adjust),
                            );
                        } else {
                            return error.UnsupportedCodegenAbi;
                        }
                    },
                    .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
                }
            },
            .aggregate_register_passthrough => |aggregate| {
                try appendSysVRegisterAggregatePassThroughArg(allocator, machine, aggregate, incoming_stack_adjust);
            },
            .stack_i32_const, .stack_i32_param, .byval_stack_copy, .aggregate_stack_passthrough => {},
        }
    }
    return .{
        .stack_arg_count = stack_arg_count,
        .cleanup_bytes = incoming_stack_adjust,
    };
}

const max_gpr_parallel_copies = 6;
const max_xmm_parallel_copies = 8;

const GprArgCopy = struct {
    dst: ArgReg,
    src: ArgReg,
};

const GprArgCopyPlan = struct {
    parallel: bool = false,
    copies: [max_gpr_parallel_copies]GprArgCopy = undefined,
    count: usize = 0,
};

fn analyzeGprArgCopyPlan(function: ir.Function, call: ir.CallInst, plan: SysVCallPlan) !GprArgCopyPlan {
    var overwritten = [_]bool{false} ** 6;
    var copy_plan = GprArgCopyPlan{};
    var needs_parallel = false;
    for (call.args.items, 0..) |arg, index| {
        const assignment = plan.assignments.items[index];
        const dst = switch (assignment) {
            .gpr => |dst| dst,
            .sse, .stack_i32_const, .stack_i32_param, .byval_stack_copy, .aggregate_register_passthrough, .aggregate_stack_passthrough => continue,
        };

        const writes_dst = switch (arg.value) {
            .int => true,
            .null_value => arg.ty == .ptr,
            .named => |name| writes: {
                const src = sysvIntegerParamRegOrNull(function, name, arg.ty) catch |err| switch (err) {
                    error.UnsupportedCodegenAbi => null,
                    else => return err,
                };
                if (src) |reg| {
                    const src_index = @intFromEnum(reg);
                    if (overwritten[src_index]) needs_parallel = true;
                    if (reg != dst and (arg.ty.eql(.{ .int = 32 }) or arg.ty.eql(.{ .int = 64 }) or arg.ty == .ptr)) {
                        if (copy_plan.count >= copy_plan.copies.len) return error.UnsupportedCodegenAbi;
                        copy_plan.copies[copy_plan.count] = .{ .dst = dst, .src = reg };
                        copy_plan.count += 1;
                    } else if (reg != dst) {
                        if (overwritten[src_index]) return error.UnsupportedCodegenAbi;
                    }
                    break :writes reg != dst;
                }
                if (needs_parallel) return error.UnsupportedCodegenAbi;
                break :writes true;
            },
            .fp, .undef, .poison, .zero_initializer, .vector, .constant_expr => false,
        };
        if (writes_dst) overwritten[@intFromEnum(dst)] = true;
    }
    if (needs_parallel and copy_plan.count == 0) return error.UnsupportedCodegenAbi;
    copy_plan.parallel = needs_parallel;
    return copy_plan;
}

fn gprCopyPlanContains(copy_plan: GprArgCopyPlan, dst: ArgReg, src: ArgReg) bool {
    for (copy_plan.copies[0..copy_plan.count]) |copy| {
        if (copy.dst == dst and copy.src == src) return true;
    }
    return false;
}

fn appendParallelGprArgCopies(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    copy_plan: GprArgCopyPlan,
) !void {
    for (copy_plan.copies[0..copy_plan.count]) |copy| {
        try machine.instructions.append(allocator, .{ .push_arg = copy.src });
    }
    var index = copy_plan.count;
    while (index > 0) {
        index -= 1;
        try machine.instructions.append(allocator, .{ .pop_arg = copy_plan.copies[index].dst });
    }
}

const XmmArgCopy = struct {
    dst: XmmReg,
    src: XmmReg,
};

const XmmArgCopyPlan = struct {
    parallel: bool = false,
    copies: [max_xmm_parallel_copies]XmmArgCopy = undefined,
    count: usize = 0,
};

fn analyzeXmmArgCopyPlan(function: ir.Function, call: ir.CallInst, plan: SysVCallPlan) !XmmArgCopyPlan {
    var overwritten = [_]bool{false} ** max_xmm_parallel_copies;
    var copy_plan = XmmArgCopyPlan{};
    var needs_parallel = false;
    for (call.args.items, 0..) |arg, index| {
        const assignment = plan.assignments.items[index];
        const dst = switch (assignment) {
            .sse => |dst| dst,
            .gpr, .stack_i32_const, .stack_i32_param, .byval_stack_copy, .aggregate_register_passthrough, .aggregate_stack_passthrough => continue,
        };

        const writes_dst = switch (arg.value) {
            .fp => true,
            .named => |name| writes: {
                const src_index = (if (arg.ty.eql(.float))
                    fpParamIndex(function, name, .float)
                else if (arg.ty.eql(.double))
                    fpParamIndex(function, name, .double)
                else
                    return error.UnsupportedCodegenType) catch |err| switch (err) {
                    error.UnsupportedCodegenAbi => null,
                    else => return err,
                };
                if (src_index) |index_value| {
                    if (index_value >= max_xmm_parallel_copies) return error.UnsupportedCodegenAbi;
                    if (overwritten[index_value]) needs_parallel = true;
                    const src = try XmmReg.fromIndex(index_value);
                    if (src != dst) {
                        if (copy_plan.count >= copy_plan.copies.len) return error.UnsupportedCodegenAbi;
                        copy_plan.copies[copy_plan.count] = .{ .dst = dst, .src = src };
                        copy_plan.count += 1;
                    }
                    break :writes src != dst;
                }
                if (needs_parallel) return error.UnsupportedCodegenAbi;
                break :writes true;
            },
            .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
        };
        if (writes_dst) overwritten[@intFromEnum(dst)] = true;
    }
    if (needs_parallel and copy_plan.count == 0) return error.UnsupportedCodegenAbi;
    copy_plan.parallel = needs_parallel;
    return copy_plan;
}

fn xmmCopyPlanContains(copy_plan: XmmArgCopyPlan, dst: XmmReg, src: XmmReg) bool {
    for (copy_plan.copies[0..copy_plan.count]) |copy| {
        if (copy.dst == dst and copy.src == src) return true;
    }
    return false;
}

fn appendParallelXmmArgCopies(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    copy_plan: XmmArgCopyPlan,
) !void {
    if (copy_plan.count == 0) return;
    for (copy_plan.copies[0..copy_plan.count]) |copy| {
        try machine.instructions.append(allocator, .{ .push_xmm64 = copy.src });
    }
    for (copy_plan.copies[0..copy_plan.count], 0..) |copy, index| {
        const stack_offset = (copy_plan.count - 1 - index) * 8;
        if (stack_offset > std.math.maxInt(u32)) return error.UnsupportedCodegenAbi;
        if (stack_offset <= std.math.maxInt(u8)) {
            try machine.instructions.append(allocator, .{ .load_stack_disp8_xmm = .{ .reg = copy.dst, .disp = @intCast(stack_offset) } });
        } else {
            try machine.instructions.append(allocator, .{ .load_stack_disp32_xmm = .{ .reg = copy.dst, .disp = @intCast(stack_offset) } });
        }
    }
    const restore_bytes = copy_plan.count * 8;
    if (restore_bytes > std.math.maxInt(u32)) return error.UnsupportedCodegenAbi;
    if (restore_bytes <= std.math.maxInt(u8)) {
        try machine.instructions.append(allocator, .{ .add_rsp_imm8 = @intCast(restore_bytes) });
    } else {
        try machine.instructions.append(allocator, .{ .add_rsp_imm32 = @intCast(restore_bytes) });
    }
}

pub fn adjustedIncomingStackDisp8(base_offset: u8, incoming_stack_adjust: usize) !u8 {
    const adjusted = @as(usize, base_offset) + incoming_stack_adjust;
    if (adjusted > std.math.maxInt(u8)) return error.UnsupportedCodegenAbi;
    return @intCast(adjusted);
}

pub fn sysvCallPlanCountsForTest(allocator: std.mem.Allocator, function: ir.Function, call: ir.CallInst) !SysVCallPlanCounts {
    return try sysv_abi.callPlanCountsForTest(allocator, function, call);
}

pub fn planSysVCall(allocator: std.mem.Allocator, function: ir.Function, call: ir.CallInst) !SysVCallPlan {
    return try sysv_abi.planCall(allocator, function, call);
}

pub fn appendSysVRegisterAggregatePassThroughArg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    pass: SysVRegisterAggregatePassThrough,
    incoming_stack_adjust: usize,
) !void {
    const dest = switch (pass.dest) {
        .registers => |dest| dest,
        .stack => return error.UnsupportedCodegenAbi,
    };
    const needs = sysvAggregateRegisterNeeds(pass.classification);
    const source_in_registers = pass.source.gpr + needs.gpr <= 6 and pass.source.sse + needs.sse <= 8;
    if (source_in_registers) {
        if (pass.source.stack_eightbytes != 0) return error.UnsupportedCodegenAbi;
        if (pass.source.gpr != dest.gpr) {
            if (dest.gpr < pass.source.gpr) {
                var gpr_offset: usize = 0;
                while (gpr_offset < needs.gpr) : (gpr_offset += 1) {
                    try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{
                        .dst = try ArgReg.fromIndex(dest.gpr + gpr_offset),
                        .src = try ArgReg.fromIndex(pass.source.gpr + gpr_offset),
                    } });
                }
            } else {
                var remaining = needs.gpr;
                while (remaining > 0) {
                    remaining -= 1;
                    try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{
                        .dst = try ArgReg.fromIndex(dest.gpr + remaining),
                        .src = try ArgReg.fromIndex(pass.source.gpr + remaining),
                    } });
                }
            }
        }

        if (pass.source.sse != dest.sse) {
            if (dest.sse < pass.source.sse) {
                var sse_offset: usize = 0;
                while (sse_offset < needs.sse) : (sse_offset += 1) {
                    try machine.instructions.append(allocator, .{ .movapd_xmm = .{
                        .dst = try XmmReg.fromIndex(dest.sse + sse_offset),
                        .src = try XmmReg.fromIndex(pass.source.sse + sse_offset),
                    } });
                }
            } else {
                var remaining = needs.sse;
                while (remaining > 0) {
                    remaining -= 1;
                    try machine.instructions.append(allocator, .{ .movapd_xmm = .{
                        .dst = try XmmReg.fromIndex(dest.sse + remaining),
                        .src = try XmmReg.fromIndex(pass.source.sse + remaining),
                    } });
                }
            }
        }
        return;
    }

    var gpr_offset: usize = 0;
    var sse_offset: usize = 0;
    var eightbyte_index: usize = 0;
    while (eightbyte_index < pass.classification.eightbyte_count) : (eightbyte_index += 1) {
        switch (pass.classification.eightbytes[eightbyte_index] orelse return error.UnsupportedCodegenAbi) {
            .integer => {
                const dst = try ArgReg.fromIndex(dest.gpr + gpr_offset);
                const offset = 8 + (pass.source.stack_eightbytes + eightbyte_index) * 8 + incoming_stack_adjust;
                try appendLoadStackDispArg64(allocator, machine, dst, offset);
                gpr_offset += 1;
            },
            .sse => {
                const dst = try XmmReg.fromIndex(dest.sse + sse_offset);
                const offset = 8 + (pass.source.stack_eightbytes + eightbyte_index) * 8 + incoming_stack_adjust;
                if (offset <= std.math.maxInt(i8)) {
                    try machine.instructions.append(allocator, .{ .load_stack_disp8_xmm = .{ .reg = dst, .disp = @intCast(offset) } });
                } else if (offset <= std.math.maxInt(u32)) {
                    try machine.instructions.append(allocator, .{ .load_stack_disp32_xmm = .{ .reg = dst, .disp = @intCast(offset) } });
                } else {
                    return error.UnsupportedCodegenAbi;
                }
                sse_offset += 1;
            },
        }
    }
}

pub fn appendSysVStackAggregatePassThroughArgs(
    stack_args: *[max_sysv_stack_call_args]StackScalarCallArg,
    stack_arg_count: *usize,
    pass: SysVRegisterAggregatePassThrough,
) !void {
    switch (pass.dest) {
        .stack => {},
        .registers => return error.UnsupportedCodegenAbi,
    }
    if (pass.classification.kind == .memory) {
        const stack_eightbytes = sysv_abi.aggregateStackEightbytes(pass.classification);
        if (stack_eightbytes == 0) return error.UnsupportedCodegenAbi;
        var index: usize = 0;
        while (index < stack_eightbytes) : (index += 1) {
            if (stack_arg_count.* >= stack_args.len) return error.UnsupportedCodegenAbi;
            const offset = 8 + (pass.source.stack_eightbytes + index) * 8;
            if (offset > std.math.maxInt(u8)) return error.UnsupportedCodegenAbi;
            stack_args[stack_arg_count.*] = .{ .stack_disp = @intCast(offset) };
            stack_arg_count.* += 1;
        }
        return;
    }
    const needs = sysvAggregateRegisterNeeds(pass.classification);
    const source_in_registers = pass.source.gpr + needs.gpr <= 6 and pass.source.sse + needs.sse <= 8;
    if (source_in_registers) {
        if (pass.source.stack_eightbytes != 0) return error.UnsupportedCodegenAbi;
        var sse_offset: usize = 0;
        var gpr_offset: usize = 0;
        var eightbyte_index: usize = 0;
        while (eightbyte_index < pass.classification.eightbyte_count) : (eightbyte_index += 1) {
            if (stack_arg_count.* >= stack_args.len) return error.UnsupportedCodegenAbi;
            switch (pass.classification.eightbytes[eightbyte_index] orelse return error.UnsupportedCodegenAbi) {
                .integer => {
                    stack_args[stack_arg_count.*] = .{ .arg_reg = try ArgReg.fromIndex(pass.source.gpr + gpr_offset) };
                    gpr_offset += 1;
                },
                .sse => {
                    stack_args[stack_arg_count.*] = .{ .xmm_reg = try XmmReg.fromIndex(pass.source.sse + sse_offset) };
                    sse_offset += 1;
                },
            }
            stack_arg_count.* += 1;
        }
        return;
    }

    var eightbyte_index: usize = 0;
    while (eightbyte_index < pass.classification.eightbyte_count) : (eightbyte_index += 1) {
        _ = pass.classification.eightbytes[eightbyte_index] orelse return error.UnsupportedCodegenAbi;
        if (stack_arg_count.* >= stack_args.len) return error.UnsupportedCodegenAbi;
        const offset = 8 + (pass.source.stack_eightbytes + eightbyte_index) * 8;
        if (offset > std.math.maxInt(u8)) return error.UnsupportedCodegenAbi;
        stack_args[stack_arg_count.*] = .{ .stack_disp = @intCast(offset) };
        stack_arg_count.* += 1;
    }
}

pub fn appendSysVByvalStackCopyArgs(
    function: ir.Function,
    stack_args: *[max_sysv_stack_call_args]StackScalarCallArg,
    stack_arg_count: *usize,
    copy: sysv_abi.ByvalStackCopy,
) !void {
    const source_reg = paramRegOrNull(function, copy.source_name, .ptr) catch |err| switch (err) {
        error.UnsupportedCodegenAbi => null,
        else => return err,
    };
    const source_stack_disp = if (source_reg == null)
        try scalarParamStackDisp8(function, copy.source_name, .ptr)
    else
        0;
    const stack_eightbytes = sysv_abi.aggregateStackEightbytes(copy.classification);
    if (stack_eightbytes == 0) return error.UnsupportedCodegenAbi;
    var index: usize = 0;
    while (index < stack_eightbytes) : (index += 1) {
        if (stack_arg_count.* >= stack_args.len) return error.UnsupportedCodegenAbi;
        const offset = index * 8;
        if (offset > std.math.maxInt(u8)) return error.UnsupportedCodegenAbi;
        const remaining = copy.classification.size_bytes - offset;
        const chunk: ByvalCopyChunk = if (remaining >= 8)
            .qword
        else if (remaining == 4)
            .dword
        else if (remaining == 2)
            .word
        else if (remaining == 1)
            .byte
        else if (remaining == 3 or remaining == 5 or remaining == 6 or remaining == 7)
            .composite
        else
            return error.UnsupportedSretByvalAbi;
        stack_args[stack_arg_count.*] = if (source_reg) |reg|
            .{ .byval_ptr_disp = .{ .reg = reg, .offset = @intCast(offset), .chunk = chunk, .len = @intCast(@min(remaining, 8)) } }
        else
            .{ .byval_stack_ptr_disp = .{ .stack_disp = source_stack_disp, .offset = @intCast(offset), .chunk = chunk, .len = @intCast(@min(remaining, 8)) } };
        stack_arg_count.* += 1;
    }
}

pub fn appendSysVMemoryAggregateStackPassThroughArgs(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    source: SysVParamCursor,
    classification: SysVAggregateClassification,
) !usize {
    if (classification.kind != .memory or classification.size_bytes == 0) return error.UnsupportedCodegenAbi;
    const stack_arg_count = @as(usize, @intCast((classification.size_bytes + 7) / 8));
    if (stack_arg_count == 0 or stack_arg_count > max_sysv_stack_call_args) return error.UnsupportedCodegenAbi;

    var stack_args: [max_sysv_stack_call_args]StackScalarCallArg = undefined;
    var index: usize = 0;
    while (index < stack_arg_count) : (index += 1) {
        const offset = 8 + (source.stack_eightbytes + index) * 8;
        if (offset > std.math.maxInt(u8)) return error.UnsupportedCodegenAbi;
        stack_args[index] = .{ .stack_disp = @intCast(offset) };
    }

    var reserved_stack_bytes: usize = 0;
    if (stack_arg_count % 2 == 0) {
        try machine.instructions.append(allocator, .sub_rsp_8);
        reserved_stack_bytes = 8;
    }
    var stack_index = stack_arg_count;
    while (stack_index > 0) {
        stack_index -= 1;
        try appendStackScalarCallArg(allocator, machine, function, null, stack_args[stack_index], reserved_stack_bytes);
        reserved_stack_bytes += 8;
    }
    return stack_arg_count;
}

pub fn sysvParamCursorFor(function: ir.Function, name: []const u8, ty: ir.Type) !SysVParamCursor {
    return try sysvParamCursorForWithInitial(function, name, ty, .{ .gpr = 0, .sse = 0, .stack_eightbytes = 0 });
}

pub fn sysvParamCursorForWithInitial(function: ir.Function, name: []const u8, ty: ir.Type, initial: SysVParamCursor) !SysVParamCursor {
    var cursor: SysVParamCursor = initial;
    for (function.params.items) |param| {
        if (std.mem.eql(u8, param.name, name)) {
            if (!param.ty.eql(ty)) return error.UnsupportedCodegenType;
            return cursor;
        }
        try advanceSysVParamCursors(param.ty, &cursor.gpr, &cursor.sse, &cursor.stack_eightbytes);
    }
    return error.UnsupportedCodegenValue;
}

pub fn sysvScalarCallNeedsStackArgs(call: ir.CallInst) bool {
    var int_arg_index: usize = 0;
    var fp_arg_index: usize = 0;
    for (call.args.items) |arg| {
        if (arg.attrs != null) sysv_abi.rejectUnsupportedCallArgAttrs(arg) catch return true;
        if (arg.ty.eql(.{ .int = 32 }) or arg.ty.eql(.{ .int = 64 }) or arg.ty == .ptr) {
            if (int_arg_index >= 6) return true;
            int_arg_index += 1;
        } else if (arg.ty.eql(.float) or arg.ty.eql(.double)) {
            if (fp_arg_index >= 8) return true;
            fp_arg_index += 1;
        } else {
            return true;
        }
    }
    return false;
}

pub const StackScalarCallArg = union(enum) {
    imm: i32,
    stack_disp: u8,
    arg_reg: ArgReg,
    xmm_reg: XmmReg,
    byval_ptr_disp: struct {
        reg: ArgReg,
        offset: u8,
        chunk: ByvalCopyChunk,
        len: u8,
    },
    byval_stack_ptr_disp: struct {
        stack_disp: u8,
        offset: u8,
        chunk: ByvalCopyChunk,
        len: u8,
    },
    computed_i32: ir.Value,
    computed_i64: ir.Value,
    precomputed_rax,
};

const ByvalCopyChunk = enum {
    qword,
    dword,
    word,
    byte,
    composite,
};

pub fn appendStackScalarCallArg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    maybe_block: ?ir.BasicBlock,
    arg: StackScalarCallArg,
    reserved_stack_bytes: usize,
) anyerror!void {
    switch (arg) {
        .imm => |value| try machine.instructions.append(allocator, .{ .push_imm32 = value }),
        .arg_reg => |reg| try machine.instructions.append(allocator, .{ .push_arg = reg }),
        .xmm_reg => |reg| try machine.instructions.append(allocator, .{ .push_xmm64 = reg }),
        .byval_ptr_disp => |source| {
            switch (source.chunk) {
                .qword => try machine.instructions.append(allocator, .{ .load_arg_ptr_disp8_rax = .{ .reg = source.reg, .offset = source.offset } }),
                .dword => try machine.instructions.append(allocator, .{ .load_arg_ptr_disp8_eax = .{ .reg = source.reg, .offset = source.offset } }),
                .word => try machine.instructions.append(allocator, .{ .load_arg_ptr_disp8_u16_eax = .{ .reg = source.reg, .offset = source.offset } }),
                .byte => try machine.instructions.append(allocator, .{ .load_arg_ptr_disp8_u8_eax = .{ .reg = source.reg, .offset = source.offset } }),
                .composite => {
                    try machine.instructions.append(allocator, .{ .push_byval_tail_arg_ptr = .{
                        .reg = source.reg,
                        .offset = source.offset,
                        .len = source.len,
                    } });
                    return;
                },
            }
            try machine.instructions.append(allocator, .push_rax);
        },
        .byval_stack_ptr_disp => |source| {
            const adjusted = @as(usize, source.stack_disp) + reserved_stack_bytes;
            if (adjusted <= std.math.maxInt(i8)) {
                try machine.instructions.append(allocator, .{ .load_stack_disp8_rax = @intCast(adjusted) });
            } else if (adjusted <= std.math.maxInt(u32)) {
                try machine.instructions.append(allocator, .{ .load_stack_disp32_rax = @intCast(adjusted) });
            } else {
                return error.UnsupportedCodegenAbi;
            }
            switch (source.chunk) {
                .qword => try machine.instructions.append(allocator, .{ .load_rax_ptr_disp8_rax = source.offset }),
                .dword => try machine.instructions.append(allocator, .{ .load_rax_ptr_disp8_eax = source.offset }),
                .word => try machine.instructions.append(allocator, .{ .load_rax_ptr_disp8_u16_eax = source.offset }),
                .byte => try machine.instructions.append(allocator, .{ .load_rax_ptr_disp8_u8_eax = source.offset }),
                .composite => {
                    if (adjusted > std.math.maxInt(u8)) return error.UnsupportedCodegenAbi;
                    try machine.instructions.append(allocator, .{ .push_byval_tail_stack_ptr = .{
                        .stack_disp = @intCast(adjusted),
                        .offset = source.offset,
                        .len = source.len,
                    } });
                    return;
                },
            }
            try machine.instructions.append(allocator, .push_rax);
        },
        .computed_i32 => |value| {
            const block = maybe_block orelse return error.UnsupportedCodegenAbi;
            try emitGenericCfgI32ValueIntoEax(allocator, machine, function, block, value);
            try machine.instructions.append(allocator, .push_rax);
        },
        .computed_i64 => |value| {
            const block = maybe_block orelse return error.UnsupportedCodegenAbi;
            try emitGenericCfgI64ValueIntoRax(allocator, machine, function, block, value);
            try machine.instructions.append(allocator, .push_rax);
        },
        .precomputed_rax => try machine.instructions.append(allocator, .push_rax),
        .stack_disp => |base_offset| {
            const adjusted = @as(usize, base_offset) + reserved_stack_bytes;
            if (adjusted <= std.math.maxInt(i8)) {
                try machine.instructions.append(allocator, .{ .push_stack_disp8 = @intCast(adjusted) });
            } else if (adjusted <= std.math.maxInt(u32)) {
                try machine.instructions.append(allocator, .{ .push_stack_disp32 = @intCast(adjusted) });
            } else {
                return error.UnsupportedCodegenAbi;
            }
        },
    }
}

pub fn appendAlignedDirectCallPreservingI32Param(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    symbol: []const u8,
    ret_ty: ir.Type,
    live_param: ?ArgReg,
) !void {
    try appendStackFrame(allocator, machine, 8);
    if (live_param) |reg| try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{
        .frame_index = .slot0,
        .reg = reg,
    } });
    try appendDirectCall(allocator, machine, symbol, ret_ty);
    if (live_param) |reg| try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{
        .reg = reg,
        .frame_index = .slot0,
    } });
    try appendStackFrameEnd(allocator, machine, 8);
}

pub fn appendAlignedDirectCallPreservingI32Params(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    call: ir.CallInst,
    live_params: LiveParamSet,
) !void {
    try appendAlignedCallPreservingI32Params(allocator, machine, function, call, live_params, .{ .direct = call.callee });
}

fn appendCallStackCleanupBytes(allocator: std.mem.Allocator, machine: *MachineFunction, bytes: usize) !void {
    if (bytes == 0) return;
    switch (bytes) {
        8 => try machine.instructions.append(allocator, .add_rsp_8),
        24 => try machine.instructions.append(allocator, .add_rsp_24),
        40 => try machine.instructions.append(allocator, .add_rsp_40),
        56 => try machine.instructions.append(allocator, .add_rsp_56),
        else => {
            if (bytes <= std.math.maxInt(u8)) {
                try machine.instructions.append(allocator, .{ .add_rsp_imm8 = @intCast(bytes) });
            } else if (bytes <= std.math.maxInt(u32)) {
                try machine.instructions.append(allocator, .{ .add_rsp_imm32 = @intCast(bytes) });
            } else {
                return error.UnsupportedCodegenAbi;
            }
        },
    }
}

pub fn appendAlignedCallPreservingI32Params(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    call: ir.CallInst,
    live_params: LiveParamSet,
    call_target: SysVCallTarget,
) !void {
    switch (live_params.count) {
        0 => {
            _ = try appendSysVScalarCallArgs(allocator, machine, function, call);
            try appendAlignedSysVCallTarget(allocator, machine, call_target, call.ret_ty);
        },
        1 => {
            try appendStackFrame(allocator, machine, 8);
            try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{
                .frame_index = .slot0,
                .reg = live_params.regs[0],
            } });
            const delayed_target_setup = callTargetNeedsDelayedSetup(call_target, call);
            if (!delayed_target_setup) try setupSysVCallTarget(allocator, machine, call_target);
            const emission = try appendSysVScalarCallArgsWithBlockAndAlignment(allocator, machine, function, null, call, .already_aligned);
            if (delayed_target_setup) try setupSysVCallTarget(allocator, machine, call_target);
            try appendSysVCallTarget(allocator, machine, call_target, call.ret_ty);
            try appendCallStackCleanupBytes(allocator, machine, emission.cleanup_bytes);
            try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{
                .reg = live_params.regs[0],
                .frame_index = .slot0,
            } });
            try appendStackFrameEnd(allocator, machine, 8);
        },
        2...6 => {
            const frame_bytes: u8 = if (live_params.count <= 3) 24 else 40;
            try appendStackFrame(allocator, machine, frame_bytes);
            var index: usize = 0;
            while (index < live_params.count) : (index += 1) {
                try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{
                    .frame_index = frameIndexForLiveParam(index),
                    .reg = live_params.regs[index],
                } });
            }
            const delayed_target_setup = callTargetNeedsDelayedSetup(call_target, call);
            if (!delayed_target_setup) try setupSysVCallTarget(allocator, machine, call_target);
            const emission = try appendSysVScalarCallArgsWithBlockAndAlignment(allocator, machine, function, null, call, .already_aligned);
            if (delayed_target_setup) try setupSysVCallTarget(allocator, machine, call_target);
            try appendSysVCallTarget(allocator, machine, call_target, call.ret_ty);
            try appendCallStackCleanupBytes(allocator, machine, emission.cleanup_bytes);
            index = 0;
            while (index < live_params.count) : (index += 1) {
                try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{
                    .reg = live_params.regs[index],
                    .frame_index = frameIndexForLiveParam(index),
                } });
            }
            try appendStackFrameEnd(allocator, machine, frame_bytes);
        },
        else => return error.UnsupportedLiveAcrossCall,
    }
}

fn callTargetNeedsDelayedSetup(call_target: SysVCallTarget, call: ir.CallInst) bool {
    return switch (call_target) {
        .direct => false,
        .indirect_from_reg => sysv_abi.callHasByvalArgAttrs(call),
    };
}

pub fn frameIndexForLiveParam(index: usize) FrameIndex {
    return switch (index) {
        0 => .slot0,
        1 => .slot1,
        2 => .slot2,
        3 => .slot3,
        4 => .slot4,
        5 => .slot5,
        else => unreachable,
    };
}

pub fn lowerReturnTerminator(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
) !void {
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(function.ret_ty)) return error.ReturnTypeMismatch;
    if (ret.ty == .void) {
        try machine.instructions.append(allocator, .ret);
        return;
    }
    if (!ret.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
    try lowerReturnValue(allocator, machine, function, block, ret.value orelse return error.InvalidRet);
    try machine.instructions.append(allocator, .ret);
}

pub fn lowerReturnValue(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    value: ir.Value,
) !void {
    switch (value) {
        .int => |int| try machine.instructions.append(allocator, .{ .mov_imm_eax = try i32Value(int) }),
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        .named => |name| {
            if (try emitI32ParamOrStackIntoEax(allocator, machine, function, name)) {
                return;
            }
            const instruction = findInstruction(block, name) orelse return error.UnsupportedCodegenValue;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (!binary.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
                    const op = machineBinaryOp(binary.op) orelse return error.UnsupportedCodegenInstruction;
                    if (binary.op == .add and try lowerI32AddTreeReturn(allocator, machine, function, block, binary)) {
                        return;
                    }
                    const lhs_const: ?i128 = switch (binary.lhs) {
                        .int => |lhs| lhs,
                        else => null,
                    };
                    const rhs_const: ?i128 = switch (binary.rhs) {
                        .int => |rhs| rhs,
                        else => null,
                    };
                    if (lhs_const) |lhs| {
                        if (rhs_const) |rhs| {
                            try machine.instructions.append(allocator, .{ .mov_imm_eax = try i32Value(lhs) });
                            switch (op) {
                                .add => try machine.instructions.append(allocator, .{ .add_eax_imm32 = try i32Value(rhs) }),
                                else => return error.UnsupportedCodegenInstruction,
                            }
                            return;
                        }
                    }
                    const lhs = try paramValueReg(function, binary.lhs, .{ .int = 32 });
                    const rhs = try paramValueReg(function, binary.rhs, .{ .int = 32 });
                    try machine.instructions.append(allocator, .{ .mov_arg_eax = lhs });
                    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = op, .reg = rhs } });
                },
                .select => |select| try lowerGenericCfgSelectReturnValue(allocator, machine, function, block, select, 0),
                .cast, .freeze, .icmp, .fcmp, .phi, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => return error.UnsupportedCodegenInstruction,
            }
        },
    }
}

pub fn lowerGenericCfgSelectReturnValue(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    select: ir.SelectInst,
    depth: u2,
) anyerror!void {
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
    const cond_name = switch (select.cond) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    const true_label = genericCfgSelectTrueLabel(depth);
    const end_label = genericCfgSelectEndLabel(depth);
    if (genericCfgSupportsI1Param(function, cond_name)) {
        const cond_reg = try paramReg(function, cond_name, .{ .int = 1 });
        try machine.instructions.append(allocator, .{ .test_arg8 = cond_reg });
        try machine.instructions.append(allocator, .{ .jne = true_label });
    } else {
        const cond_inst = findInstruction(block, cond_name) orelse return error.UnsupportedCodegenValue;
        const cond = switch (cond_inst.kind) {
            .icmp => |icmp| icmp,
            else => return error.UnsupportedCodegenInstruction,
        };
        if (try lowerGenericCfgSminSelectReturn(allocator, machine, function, select, cond)) return;
        const branch_kind = try emitGenericCfgIcmpCondition(allocator, machine, function, cond);
        try appendGenericCfgConditionalBranch(allocator, machine, branch_kind, true_label);
    }
    try lowerGenericCfgI32ValueIntoEax(allocator, machine, function, block, select.false_value, depth +| 1);
    try machine.instructions.append(allocator, .{ .jmp = end_label });
    try appendGenericCfgBlockLabel(allocator, machine, true_label);
    try lowerGenericCfgI32ValueIntoEax(allocator, machine, function, block, select.true_value, depth +| 1);
    try appendGenericCfgBlockLabel(allocator, machine, end_label);
}

pub fn lowerGenericCfgI32ValueIntoEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    value: ir.Value,
    depth: u2,
) anyerror!void {
    switch (value) {
        .int => |int| try machine.instructions.append(allocator, .{ .mov_imm_eax = try i32Value(int) }),
        .named => |name| {
            if (try paramRegOrNull(function, name, .{ .int = 32 })) |reg| {
                try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
                return;
            }
            const instruction = findInstruction(block, name) orelse return error.UnsupportedCodegenValue;
            const select = switch (instruction.kind) {
                .select => |select| select,
                .binary => {
                    try emitGenericCfgI32ValueIntoEax(allocator, machine, function, block, value);
                    return;
                },
                else => return error.UnsupportedCodegenInstruction,
            };
            if (depth == std.math.maxInt(u2)) return error.UnsupportedCodegenInstruction;
            try lowerGenericCfgSelectReturnValue(allocator, machine, function, block, select, depth);
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn genericCfgSelectTrueLabel(depth: u2) []const u8 {
    return switch (depth) {
        0 => "generic_cfg_select_true",
        1 => "generic_cfg_nested1_select_true",
        2 => "generic_cfg_nested2_select_true",
        3 => "generic_cfg_nested3_select_true",
    };
}

pub fn genericCfgSelectEndLabel(depth: u2) []const u8 {
    return switch (depth) {
        0 => "generic_cfg_select_end",
        1 => "generic_cfg_nested1_generic_cfg_select_end",
        2 => "generic_cfg_nested2_generic_cfg_select_end",
        3 => "generic_cfg_nested3_generic_cfg_select_end",
    };
}

pub fn lowerGenericCfgSminSelectReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    select: ir.SelectInst,
    icmp: ir.IcmpInst,
) !bool {
    if (!genericCfgSupportsSminSelect(function, select, icmp)) return false;
    const lhs = switch (icmp.lhs) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const rhs = switch (icmp.rhs) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if ((try paramReg(function, lhs, .{ .int = 32 })) != .rdi) return error.UnsupportedCodegenAbi;
    if ((try paramReg(function, rhs, .{ .int = 32 })) != .rsi) return error.UnsupportedCodegenAbi;
    try machine.instructions.append(allocator, .smin_i32_edi_esi_eax);
    return true;
}

pub fn emitGenericCfgIcmpCondition(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    icmp: ir.IcmpInst,
) !GenericCfgBranchKind {
    const branch_kind: GenericCfgBranchKind = switch (icmp.predicate) {
        .eq => .je,
        .ne => .jne,
        .slt => if (icmp.operand_ty.eql(.{ .int = 32 }) and isInt(icmp.rhs, 0))
            .js
        else
            return error.UnsupportedCodegenInstruction,
        .ugt, .uge, .ult, .ule, .sgt, .sge, .sle => return error.UnsupportedCodegenInstruction,
    };

    if (icmp.operand_ty.eql(.ptr)) {
        const ptr_value = if (icmp.lhs == .null_value) icmp.rhs else if (icmp.rhs == .null_value) icmp.lhs else return error.UnsupportedCodegenValue;
        const ptr_reg = try paramValueReg(function, ptr_value, .ptr);
        try machine.instructions.append(allocator, .{ .test_arg64 = ptr_reg });
        return branch_kind;
    }

    if (icmp.operand_ty.eql(.{ .int = 8 })) {
        if (icmp.lhs == .int and icmp.rhs != .int) {
            const rhs_reg = try paramValueReg(function, icmp.rhs, .{ .int = 8 });
            try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = rhs_reg, .imm = try u8Value(switch (icmp.lhs) {
                .int => |int| int,
                else => unreachable,
            }) } });
            return branch_kind;
        }
        const lhs_reg = try paramValueReg(function, icmp.lhs, .{ .int = 8 });
        const rhs_imm = switch (icmp.rhs) {
            .int => |int| try u8Value(int),
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = lhs_reg, .imm = rhs_imm } });
        return branch_kind;
    }

    if (!icmp.operand_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;

    if (icmp.predicate == .slt and isInt(icmp.rhs, 0)) {
        const lhs_reg = try paramValueReg(function, icmp.lhs, .{ .int = 32 });
        try appendGenericCfgCompareParamZero(allocator, machine, lhs_reg);
        return .js;
    }

    if (isInt(icmp.rhs, 0)) {
        const lhs_reg = try paramValueReg(function, icmp.lhs, .{ .int = 32 });
        try appendGenericCfgCompareParamZero(allocator, machine, lhs_reg);
        return branch_kind;
    }
    if (isInt(icmp.lhs, 0)) {
        const rhs_reg = try paramValueReg(function, icmp.rhs, .{ .int = 32 });
        try appendGenericCfgCompareParamZero(allocator, machine, rhs_reg);
        return branch_kind;
    }

    const lhs_reg = try paramValueReg(function, icmp.lhs, .{ .int = 32 });
    const rhs_imm = switch (icmp.rhs) {
        .int => |int| try i32Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    try machine.instructions.append(allocator, .{ .mov_arg_eax = lhs_reg });
    try appendGenericCfgCompareLocalImm(allocator, machine, .eax, rhs_imm);
    return branch_kind;
}

pub fn lowerI32AddTreeReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    binary: ir.BinaryInst,
) !bool {
    var terms: std.ArrayList(ir.Value) = .empty;
    defer terms.deinit(allocator);
    try collectI32AddTerms(allocator, block, binary, &terms);
    if (terms.items.len < 2) return false;
    try emitI32ValueIntoEax(allocator, machine, function, terms.items[0]);
    for (terms.items[1..]) |term| {
        switch (term) {
            .int => |int| try machine.instructions.append(allocator, .{ .add_eax_imm32 = try i32Value(int) }),
            .named => |name| {
                if (try registerParamRegOrNull(function, name, .{ .int = 32 })) |reg| {
                    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = reg } });
                } else if (try stackParamDisp8OrNull(function, name, .{ .int = 32 })) |offset| {
                    try machine.instructions.append(allocator, .{ .add_stack_disp8_eax = offset });
                } else return false;
            },
            .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
        }
    }
    return true;
}

pub fn collectI32AddTerms(
    allocator: std.mem.Allocator,
    block: ir.BasicBlock,
    binary: ir.BinaryInst,
    terms: *std.ArrayList(ir.Value),
) anyerror!void {
    if (binary.op != .add or !binary.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
    try collectI32AddValue(allocator, block, binary.lhs, terms);
    try collectI32AddValue(allocator, block, binary.rhs, terms);
}

pub fn collectI32AddValue(
    allocator: std.mem.Allocator,
    block: ir.BasicBlock,
    value: ir.Value,
    terms: *std.ArrayList(ir.Value),
) anyerror!void {
    switch (value) {
        .named => |name| {
            if (findInstruction(block, name)) |instruction| {
                switch (instruction.kind) {
                    .binary => |nested| if (nested.op == .add and nested.ty.eql(.{ .int = 32 })) {
                        try collectI32AddTerms(allocator, block, nested, terms);
                        return;
                    },
                    else => {},
                }
            }
            try terms.append(allocator, value);
        },
        .int => try terms.append(allocator, value),
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn emitI32ValueIntoEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    value: ir.Value,
) !void {
    switch (value) {
        .int => |int| try machine.instructions.append(allocator, .{ .mov_imm_eax = try i32Value(int) }),
        .named => |name| {
            if (try emitI32ParamOrStackIntoEax(allocator, machine, function, name)) return;
            return error.UnsupportedCodegenValue;
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn lowerReturnValueAfterCalls(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    value: ir.Value,
    last_eax_value: ?[]const u8,
    call_count: usize,
) !void {
    switch (value) {
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return lowerReturnValue(allocator, machine, function, block, value),
        .named => |name| {
            if (call_count == 0) return lowerReturnValue(allocator, machine, function, block, value);
            if (last_eax_value) |eax_name| {
                if (std.mem.eql(u8, name, eax_name)) return;
            }
            const instruction = findInstruction(block, name) orelse return lowerReturnValue(allocator, machine, function, block, value);
            switch (instruction.kind) {
                .binary => |binary| {
                    if (call_count != 1) return error.UnsupportedCodegenInstruction;
                    try lowerBinaryReturnAfterCall(allocator, machine, function, block, binary, last_eax_value orelse return error.UnsupportedCodegenValue);
                },
                else => return lowerReturnValue(allocator, machine, function, block, value),
            }
        },
    }
}

pub fn lowerBinaryReturnAfterCall(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    binary: ir.BinaryInst,
    eax_name: []const u8,
) !void {
    if (!binary.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
    const op = machineBinaryOp(binary.op) orelse return error.UnsupportedCodegenInstruction;
    if (binary.op == .add) {
        var terms: std.ArrayList(ir.Value) = .empty;
        defer terms.deinit(allocator);
        try collectI32AddTerms(allocator, block, binary, &terms);
        var has_eax_value = false;
        for (terms.items) |term| {
            if (isNamed(term, eax_name)) {
                has_eax_value = true;
                break;
            }
        }
        if (has_eax_value) {
            for (terms.items) |term| {
                if (isNamed(term, eax_name)) continue;
                try appendI32AddTermToEax(allocator, machine, function, term);
            }
            return;
        }
    }
    if (isNamed(binary.lhs, eax_name)) {
        if (binary.op == .add) {
            switch (binary.rhs) {
                .int => |int| {
                    try machine.instructions.append(allocator, .{ .add_eax_imm32 = try i32Value(int) });
                    return;
                },
                .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => {},
            }
        }
        const rhs = try paramValueReg(function, binary.rhs, .{ .int = 32 });
        try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = op, .reg = rhs } });
        return;
    }
    if (isCommutative(binary.op) and isNamed(binary.rhs, eax_name)) {
        if (binary.op == .add) {
            switch (binary.lhs) {
                .int => |int| {
                    try machine.instructions.append(allocator, .{ .add_eax_imm32 = try i32Value(int) });
                    return;
                },
                .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => {},
            }
        }
        const lhs = try paramValueReg(function, binary.lhs, .{ .int = 32 });
        try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = op, .reg = lhs } });
        return;
    }
    return error.UnsupportedCodegenInstruction;
}

pub fn appendI32AddTermToEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    term: ir.Value,
) !void {
    switch (term) {
        .int => |int| try machine.instructions.append(allocator, .{ .add_eax_imm32 = try i32Value(int) }),
        .named => |name| {
            if (try registerParamRegOrNull(function, name, .{ .int = 32 })) |reg| {
                try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = reg } });
                return;
            }
            if (try stackParamDisp8OrNull(function, name, .{ .int = 32 })) |offset| {
                try machine.instructions.append(allocator, .{ .add_stack_disp8_eax = offset });
                return;
            }
            return error.UnsupportedCodegenValue;
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

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
        try machine.instructions.append(allocator, .{ .load_stack_disp8_rax = offset });
        return true;
    }
    return false;
}

pub fn lowerSelectedI64ConstReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 64 })) return false;
    if (function.params.items.len != 0 or block.instructions.items.len != 0) return false;
    const value = switch (ret.value orelse return error.InvalidRet) {
        .int => |int| int,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };

    try machine.instructions.append(allocator, .{ .mov_imm_rax = try i64Value(value) });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn isSysVGprReturnType(ty: ir.Type) bool {
    return ty.eql(.{ .int = 64 }) or ty.eql(.ptr);
}

pub fn lowerGenericCfgGprParamReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!isSysVGprReturnType(ret.ty) or block.instructions.items.len != 0) return false;
    const name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const reg = try sysvIntegerParamReg(function, name, ret.ty);
    try machine.instructions.append(allocator, .{ .mov_arg_rax = reg });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgI64ParamReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 64 })) return false;
    return try lowerGenericCfgGprParamReturn(allocator, machine, function, block, ret);
}

pub fn lowerGenericCfgGprDirectCallReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!isSysVGprReturnType(ret.ty) or block.instructions.items.len == 0 or block.instructions.items.len > 2) return false;
    const instruction = block.instructions.items[block.instructions.items.len - 1];
    if (instruction.removed) return false;
    const call_result = instruction.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, call_result)) return false;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!call.ret_ty.eql(ret.ty) or call.inline_asm != null) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;

    if (call.callee_value) |callee_value| {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        const callee_reg = try paramReg(function, callee_name, .ptr);
        const stack_arg_count = if (sysv_abi.callHasByvalArgAttrs(call)) count: {
            const count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, call);
            try machine.instructions.append(allocator, .{ .mov_arg_rax = callee_reg });
            break :count count;
        } else count: {
            try machine.instructions.append(allocator, .{ .mov_arg_rax = callee_reg });
            break :count try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, call);
        };
        try appendIndirectCallRaxWithStackArgs(allocator, machine, call.ret_ty, stack_arg_count);
    } else {
        const stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, call);
        try appendDirectCallWithStackArgs(allocator, machine, call.callee, call.ret_ty, stack_arg_count);
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgI64DirectCallReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 64 })) return false;
    return try lowerGenericCfgGprDirectCallReturn(allocator, machine, function, block, ret);
}
