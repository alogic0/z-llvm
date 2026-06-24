const impl = @import("core_impl.zig");
const std = impl.std;
const ir = impl.ir;

const MachineFunction = impl.MachineFunction;
const ArgReg = impl.ArgReg;
const SysVCallPlanCounts = impl.SysVCallPlanCounts;
const SysVParamCursor = impl.SysVParamCursor;
const SysVAggregateClassification = impl.SysVAggregateClassification;
const max_sysv_stack_call_args = impl.max_sysv_stack_call_args;

pub fn appendAlignedDirectCallPreservingI32Param(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    symbol: []const u8,
    ret_ty: ir.Type,
    live_param: ?ArgReg,
) !void {
    try impl.appendStackFrame(allocator, machine, 8);
    if (live_param) |reg| try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{
        .frame_index = .slot0,
        .reg = reg,
    } });
    try impl.appendDirectCall(allocator, machine, symbol, ret_ty);
    if (live_param) |reg| try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{
        .reg = reg,
        .frame_index = .slot0,
    } });
    try impl.appendStackFrameEnd(allocator, machine, 8);
}

pub fn appendI32CallArgs(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    call: ir.CallInst,
) !usize {
    var plan = try impl.planSysVCall(allocator, function, call);
    defer plan.deinit(allocator);
    if (plan.has_non_i32_arg) return error.UnsupportedCodegenType;
    if (plan.counts.stack_args > max_sysv_stack_call_args) return error.UnsupportedCodegenAbi;

    var stack_args: [max_sysv_stack_call_args]impl.StackScalarCallArg = undefined;
    var stack_arg_count: usize = 0;
    for (call.args.items, 0..) |arg, index| {
        const assignment = plan.assignments.items[index];
        switch (assignment) {
            .gpr => |dst| switch (arg.value) {
                .int => |int| try impl.appendMoveImmToArgReg(allocator, machine, dst, try impl.i64Value(int)),
                .named => |name| {
                    if (paramRegOrNull(function, name, .{ .int = 32 }) catch |err| switch (err) {
                        error.UnsupportedCodegenAbi => null,
                        else => return err,
                    }) |src| {
                        if (src != dst) try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = dst, .src = src } });
                    } else {
                        try impl.appendLoadStackDispArg32(allocator, machine, dst, try scalarParamStackDisp8(function, name, .{ .int = 32 }));
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
            .sse, .aggregate_register_passthrough, .aggregate_stack_passthrough => return error.UnsupportedCodegenType,
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
        try impl.appendStackScalarCallArg(allocator, machine, function, null, stack_args[index], reserved_stack_bytes);
        reserved_stack_bytes += 8;
    }
    return stack_arg_count;
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

    var stack_args: [max_sysv_stack_call_args]impl.StackScalarCallArg = undefined;
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
        try impl.appendStackScalarCallArg(allocator, machine, function, null, stack_args[stack_index], reserved_stack_bytes);
        reserved_stack_bytes += 8;
    }
    return stack_arg_count;
}

pub fn appendSysVScalarCallArgs(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    call: ir.CallInst,
) !usize {
    return try appendSysVScalarCallArgsWithBlock(allocator, machine, function, null, call);
}

pub fn appendSysVScalarCallArgsWithBlock(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    maybe_block: ?ir.BasicBlock,
    call: ir.CallInst,
) anyerror!usize {
    var plan = try impl.planSysVCall(allocator, function, call);
    defer plan.deinit(allocator);
    if (plan.counts.stack_args > max_sysv_stack_call_args) return error.UnsupportedCodegenAbi;

    var stack_args: [max_sysv_stack_call_args]impl.StackScalarCallArg = undefined;
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
                if (impl.sysvIntegerParamRegOrNull(function, name, arg.ty) catch |err| switch (err) {
                    error.UnsupportedCodegenAbi => null,
                    else => return err,
                }) |src| {
                    stack_args[stack_arg_count] = .{ .arg_reg = src };
                } else if (impl.scalarParamStackDisp8(function, name, arg.ty) catch |err| switch (err) {
                    error.UnsupportedCodegenValue => null,
                    else => return err,
                }) |disp| {
                    stack_args[stack_arg_count] = .{ .stack_disp = disp };
                } else if (arg.ty.eql(.{ .int = 32 })) {
                    const block = maybe_block orelse return error.UnsupportedCodegenAbi;
                    if (!impl.genericCfgSupportsSingleBlockI32Value(function, block, .{ .named = name })) return error.UnsupportedCodegenValue;
                    stack_args[stack_arg_count] = .{ .computed_i32 = .{ .named = name } };
                } else if (arg.ty.eql(.{ .int = 64 })) {
                    _ = maybe_block orelse return error.UnsupportedCodegenAbi;
                    if (!impl.genericCfgSupportsI64Value(function, .{ .named = name })) return error.UnsupportedCodegenValue;
                    stack_args[stack_arg_count] = .{ .computed_i64 = .{ .named = name } };
                } else {
                    return error.UnsupportedCodegenAbi;
                }
                stack_arg_count += 1;
            },
            .aggregate_stack_passthrough => |aggregate| {
                try appendSysVStackAggregatePassThroughArgs(&stack_args, &stack_arg_count, aggregate);
            },
        }
    }
    var precomputed_stack_arg = false;
    for (stack_args[0..stack_arg_count]) |*stack_arg| {
        switch (stack_arg.*) {
            .computed_i32 => |value| {
                if (precomputed_stack_arg) return error.UnsupportedCodegenAbi;
                const block = maybe_block orelse return error.UnsupportedCodegenAbi;
                try impl.emitGenericCfgI32ValueIntoEax(allocator, machine, function, block, value);
                stack_arg.* = .precomputed_rax;
                precomputed_stack_arg = true;
            },
            .computed_i64 => |value| {
                if (precomputed_stack_arg) return error.UnsupportedCodegenAbi;
                const block = maybe_block orelse return error.UnsupportedCodegenAbi;
                try impl.emitGenericCfgI64ValueIntoRax(allocator, machine, function, block, value);
                stack_arg.* = .precomputed_rax;
                precomputed_stack_arg = true;
            },
            else => {},
        }
    }

    var reserved_stack_bytes: usize = 0;
    if (stack_arg_count != 0 and stack_arg_count % 2 == 0) {
        try machine.instructions.append(allocator, .sub_rsp_8);
        reserved_stack_bytes = 8;
    }
    var stack_index = stack_arg_count;
    while (stack_index > 0) {
        stack_index -= 1;
        try impl.appendStackScalarCallArg(allocator, machine, function, maybe_block, stack_args[stack_index], reserved_stack_bytes);
        reserved_stack_bytes += 8;
    }
    const incoming_stack_adjust = reserved_stack_bytes;

    for (call.args.items, 0..) |arg, index| {
        const assignment = plan.assignments.items[index];
        switch (assignment) {
            .gpr => |dst| {
                if (!arg.ty.eql(.{ .int = 32 }) and !arg.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
                switch (arg.value) {
                    .int => |int| try impl.appendMoveImmToArgReg(allocator, machine, dst, try impl.i64Value(int)),
                    .named => |name| {
                        if (impl.sysvIntegerParamRegOrNull(function, name, arg.ty) catch |err| switch (err) {
                            error.UnsupportedCodegenAbi => null,
                            else => return err,
                        }) |src| {
                            if (src != dst) {
                                try machine.instructions.append(allocator, if (arg.ty.eql(.{ .int = 64 }))
                                    .{ .mov_arg64_arg = .{ .dst = dst, .src = src } }
                                else
                                    .{ .mov_arg_arg = .{ .dst = dst, .src = src } });
                            }
                        } else if (arg.ty.eql(.{ .int = 32 })) {
                            try impl.appendLoadStackDispArg32(
                                allocator,
                                machine,
                                dst,
                                @as(usize, try impl.scalarParamStackDisp8(function, name, .{ .int = 32 })) +
                                    incoming_stack_adjust,
                            );
                        } else if (arg.ty.eql(.{ .int = 64 })) {
                            try impl.appendLoadStackDispArg64(
                                allocator,
                                machine,
                                dst,
                                @as(usize, try impl.scalarParamStackDisp8(function, name, .{ .int = 64 })) +
                                    incoming_stack_adjust,
                            );
                        }
                    },
                    .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
                }
            },
            .sse => |dst| {
                if (!arg.ty.eql(.float) and !arg.ty.eql(.double)) return error.UnsupportedCodegenType;
                switch (arg.value) {
                    .fp => if (arg.ty.eql(.float))
                        try impl.appendMoveImm32ToXmm(allocator, machine, dst, try impl.fp32TextBits(arg.value))
                    else
                        try impl.appendMoveImm64ToXmm(allocator, machine, dst, try impl.fp64TextBits(arg.value)),
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
                                try machine.instructions.append(allocator, .{ .movapd_xmm = .{
                                    .dst = dst,
                                    .src = try impl.XmmReg.fromIndex(src_index),
                                } });
                            }
                        } else if (arg.ty.eql(.double)) {
                            try appendLoadStackDispXmm(
                                allocator,
                                machine,
                                dst,
                                try adjustedIncomingStackDisp8(try impl.scalarParamStackDisp8(function, name, .double), incoming_stack_adjust),
                            );
                        } else {
                            return error.UnsupportedCodegenAbi;
                        }
                    },
                    .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
                }
            },
            .aggregate_register_passthrough => |aggregate| {
                try impl.appendSysVRegisterAggregatePassThroughArg(allocator, machine, aggregate, incoming_stack_adjust);
            },
            .stack_i32_const, .stack_i32_param, .aggregate_stack_passthrough => {},
        }
    }
    return stack_arg_count;
}

fn appendLoadStackDispXmm(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    dst: impl.XmmReg,
    offset: u8,
) !void {
    if (offset <= std.math.maxInt(i8)) {
        try machine.instructions.append(allocator, .{ .load_stack_disp8_xmm = .{ .reg = dst, .disp = @intCast(offset) } });
    } else if (offset <= std.math.maxInt(u32)) {
        try machine.instructions.append(allocator, .{ .load_stack_disp32_xmm = .{ .reg = dst, .disp = @intCast(offset) } });
    } else {
        return error.UnsupportedCodegenAbi;
    }
}

fn appendSysVStackAggregatePassThroughArgs(
    stack_args: *[max_sysv_stack_call_args]impl.StackScalarCallArg,
    stack_arg_count: *usize,
    pass: impl.SysVRegisterAggregatePassThrough,
) !void {
    return try impl.appendSysVStackAggregatePassThroughArgs(stack_args, stack_arg_count, pass);
}

fn adjustedIncomingStackDisp8(base_offset: u8, incoming_stack_adjust: usize) !u8 {
    const adjusted = @as(usize, base_offset) + incoming_stack_adjust;
    if (adjusted > std.math.maxInt(u8)) return error.UnsupportedCodegenAbi;
    return @intCast(adjusted);
}

pub fn blockIndex(function: ir.Function, name: []const u8) ?usize {
    return impl.blockIndex(function, name);
}

pub fn findInstruction(block: ir.BasicBlock, result_name: []const u8) ?ir.Instruction {
    return impl.findInstruction(block, result_name);
}

pub fn fpParamIndex(function: ir.Function, name: []const u8, ty: ir.Type) !usize {
    return impl.fpParamIndex(function, name, ty);
}

pub fn identityCastFrom(instruction: ir.Instruction, value_name: []const u8, from_ty: ir.Type, to_ty: ir.Type) ?[]const u8 {
    return impl.identityCastFrom(instruction, value_name, from_ty, to_ty);
}

pub fn isSelectI1ToI32ZeroOne(instruction: ir.Instruction, cond_name: []const u8) bool {
    return impl.isSelectI1ToI32ZeroOne(instruction, cond_name);
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
        .int => |int| try machine.instructions.append(allocator, .{ .mov_imm_eax = try impl.i32Value(int) }),
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        .named => |name| {
            if (try emitI32ParamOrStackIntoEax(allocator, machine, function, name)) {
                return;
            }
            const instruction = findInstruction(block, name) orelse return error.UnsupportedCodegenValue;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (!binary.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
                    const op = impl.machineBinaryOp(binary.op) orelse return error.UnsupportedCodegenInstruction;
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
                            try machine.instructions.append(allocator, .{ .mov_imm_eax = try impl.i32Value(lhs) });
                            switch (op) {
                                .add => try machine.instructions.append(allocator, .{ .add_eax_imm32 = try impl.i32Value(rhs) }),
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
                .select => |select| try impl.lowerGenericCfgSelectReturnValue(allocator, machine, function, block, select, 0),
                .cast, .freeze, .icmp, .fcmp, .phi, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => return error.UnsupportedCodegenInstruction,
            }
        },
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
    return impl.lowerBinaryReturnAfterCall(allocator, machine, function, block, binary, eax_name);
}

pub fn lowerI32AddTreeReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    binary: ir.BinaryInst,
) !bool {
    return impl.lowerI32AddTreeReturn(allocator, machine, function, block, binary);
}

pub fn emitI32ParamOrStackIntoEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    name: []const u8,
) !bool {
    return impl.emitI32ParamOrStackIntoEax(allocator, machine, function, name);
}

pub fn appendI32AddTermToEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    term: ir.Value,
) !void {
    return impl.appendI32AddTermToEax(allocator, machine, function, term);
}

pub fn paramValueReg(function: ir.Function, value: ir.Value, ty: ir.Type) !ArgReg {
    return impl.paramValueReg(function, value, ty);
}

pub fn matchIcmpEqParamImm(
    instruction: ir.Instruction,
    param_name: []const u8,
    ty: ir.Type,
    imm: i128,
) bool {
    return impl.matchIcmpEqParamImm(instruction, param_name, ty, imm);
}

pub fn phiHasIncoming(phi: ir.PhiInst, value_name: []const u8, block_name: []const u8) bool {
    return impl.phiHasIncoming(phi, value_name, block_name);
}

pub fn phiHasIncomingInt(phi: ir.PhiInst, value: i128, block_name: []const u8) bool {
    return impl.phiHasIncomingInt(phi, value, block_name);
}

pub fn singleLiveParamAfter(function: ir.Function, block: ir.BasicBlock, instruction_index: usize) !?ArgReg {
    return impl.singleLiveParamAfter(function, block, instruction_index);
}

pub fn sysvCallPlanCountsForTest(
    allocator: std.mem.Allocator,
    function: ir.Function,
    call: ir.CallInst,
) !SysVCallPlanCounts {
    return try impl.sysv_abi.callPlanCountsForTest(allocator, function, call);
}

pub fn sysvIntegerParamReg(function: ir.Function, name: []const u8, ty: ir.Type) !ArgReg {
    return try impl.sysvIntegerParamReg(function, name, ty);
}

pub fn sysvParamCursorForWithInitial(
    function: ir.Function,
    name: []const u8,
    ty: ir.Type,
    initial: SysVParamCursor,
) !SysVParamCursor {
    var cursor: SysVParamCursor = initial;
    for (function.params.items) |param| {
        if (std.mem.eql(u8, param.name, name)) {
            if (!param.ty.eql(ty)) return error.UnsupportedCodegenType;
            return cursor;
        }
        try impl.advanceSysVParamCursors(param.ty, &cursor.gpr, &cursor.sse, &cursor.stack_eightbytes);
    }
    return error.UnsupportedCodegenValue;
}

pub fn valueReferencesGlobal(value: ir.Value, name: []const u8) bool {
    return impl.valueReferencesGlobal(value, name);
}

fn scalarParamStackDisp8(function: ir.Function, name: []const u8, ty: ir.Type) !u8 {
    return impl.scalarParamStackDisp8(function, name, ty);
}

pub fn paramReg(function: ir.Function, name: []const u8, ty: ir.Type) !ArgReg {
    return try paramRegOrNull(function, name, ty) orelse error.UnsupportedCodegenValue;
}

pub fn paramRegOrNull(function: ir.Function, name: []const u8, ty: ir.Type) !?ArgReg {
    return try impl.paramRegOrNullWithInitialGpr(function, name, ty, 0);
}

pub fn paramRegWithInitialGpr(function: ir.Function, name: []const u8, ty: ir.Type, initial_gpr: usize) !ArgReg {
    return try impl.paramRegOrNullWithInitialGpr(function, name, ty, initial_gpr) orelse error.UnsupportedCodegenValue;
}
