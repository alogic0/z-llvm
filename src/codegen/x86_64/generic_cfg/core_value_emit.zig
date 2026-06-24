const shared = @import("core_shared.zig");
const support = @import("core_value_support.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");
const cabi_call_lowering = @import("cabi_call_lowering.zig");

const std = shared.std;
const ir = shared.ir;
const MachineFunction = shared.MachineFunction;

const appendDirectCallWithStackArgs = shared.appendDirectCallWithStackArgs;
const appendIndirectCallRaxWithStackArgs = shared.appendIndirectCallRaxWithStackArgs;
const callIsFastcc = shared.callIsFastcc;
const i32Value = shared.i32Value;
const i64Value = shared.i64Value;
const isNamed = shared.isNamed;
const validateDefaultCallConv = shared.validateDefaultCallConv;

const paramReg = cabi_abi_helpers.paramReg;
const registerParamRegOrNull = cabi_abi_helpers.registerParamRegOrNull;
const scalarParamStackDisp8 = cabi_abi_helpers.scalarParamStackDisp8;
const stackParamDisp8OrNull = cabi_abi_helpers.stackParamDisp8OrNull;
const sysvIntegerParamRegOrNull = cabi_abi_helpers.sysvIntegerParamRegOrNull;

const appendAlignedCallPreservingI32Params = cabi_call_lowering.appendAlignedCallPreservingI32Params;
const appendSysVScalarCallArgsWithBlock = cabi_call_lowering.appendSysVScalarCallArgsWithBlock;
const emitI32ParamOrStackIntoEax = cabi_call_lowering.emitI32ParamOrStackIntoEax;
const findInstruction = cabi_call_lowering.findInstruction;
const findInstructionIndex = cabi_call_lowering.findInstructionIndex;
const i32CallStackArgCount = cabi_call_lowering.i32CallStackArgCount;
const liveParamsAfter = cabi_call_lowering.liveParamsAfter;
const lowerGenericCfgSelectReturnValue = cabi_call_lowering.lowerGenericCfgSelectReturnValue;
const machineBinaryOp = cabi_call_lowering.machineBinaryOp;

const genericCfgSupportsSingleBlockI32Value = support.genericCfgSupportsSingleBlockI32Value;
const genericCfgSupportsSminIntrinsicCall = support.genericCfgSupportsSminIntrinsicCall;

pub fn emitGenericCfgBranchSideEffects(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
) !void {
    for (block.instructions.items) |instruction| {
        switch (instruction.kind) {
            .store => |store| {
                try emitGenericCfgI32ValueIntoEax(allocator, machine, function, block, store.value);
                try emitGenericCfgStoreEax(allocator, machine, function, store.ptr);
            },
            .load, .binary, .call => {},
            else => return error.UnsupportedCodegenInstruction,
        }
    }
}

pub fn emitGenericCfgI32ValueIntoEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    value: ir.Value,
) !void {
    switch (value) {
        .int => |int| try machine.instructions.append(allocator, .{ .mov_imm_eax = try i32Value(int) }),
        .named => |name| {
            if (try emitI32ParamOrStackIntoEax(allocator, machine, function, name)) {
                return;
            }
            const instruction_index = findInstructionIndex(block, name) orelse return error.UnsupportedCodegenValue;
            const instruction = block.instructions.items[instruction_index];
            switch (instruction.kind) {
                .load => |load| {
                    if (!load.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
                    try emitGenericCfgLoadI32IntoEax(allocator, machine, function, load.ptr);
                },
                .binary => |binary| {
                    if (!binary.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
                    try emitGenericCfgI32ValueIntoEax(allocator, machine, function, block, binary.lhs);
                    switch (binary.rhs) {
                        .int => |int| switch (binary.op) {
                            .add => try machine.instructions.append(allocator, .{ .add_eax_imm32 = try i32Value(int) }),
                            .sub => try machine.instructions.append(allocator, .{ .add_eax_imm32 = -try i32Value(int) }),
                            else => return error.UnsupportedCodegenInstruction,
                        },
                        .named => |rhs_name| {
                            const op = machineBinaryOp(binary.op) orelse return error.UnsupportedCodegenInstruction;
                            if (try registerParamRegOrNull(function, rhs_name, .{ .int = 32 })) |rhs| {
                                try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = op, .reg = rhs } });
                                return;
                            }
                            if (try stackParamDisp8OrNull(function, rhs_name, .{ .int = 32 })) |offset| {
                                if (op != .add) return error.UnsupportedCodegenInstruction;
                                try machine.instructions.append(allocator, .{ .add_stack_disp8_eax = offset });
                                return;
                            }
                            if (op != .add) return error.UnsupportedCodegenInstruction;
                            const rhs_instruction = findInstruction(block, rhs_name) orelse return error.UnsupportedCodegenValue;
                            switch (rhs_instruction.kind) {
                                .load => |rhs_load| switch (genericCfgI32Address(function, rhs_load.ptr) orelse return error.UnsupportedCodegenValue) {
                                    .tls => |symbol| try machine.instructions.append(allocator, .{ .add_tls_i32_eax = symbol }),
                                    .param, .global => return error.UnsupportedCodegenValue,
                                },
                                .binary, .select, .call => {
                                    if (!genericCfgSupportsSingleBlockI32Value(function, block, binary.lhs)) return error.UnsupportedCodegenValue;
                                    try emitGenericCfgI32ValueIntoEax(allocator, machine, function, block, binary.rhs);
                                    try emitGenericCfgI32AddValueToEax(allocator, machine, function, block, binary.lhs);
                                },
                                else => return error.UnsupportedCodegenInstruction,
                            }
                        },
                        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
                    }
                },
                .call => |call| try emitGenericCfgI32CallIntoEax(allocator, machine, function, block, instruction_index, call),
                .select => |select| try lowerGenericCfgSelectReturnValue(allocator, machine, function, block, select, 0),
                .phi, .icmp, .fcmp, .cast, .freeze, .alloca, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep => return error.UnsupportedCodegenInstruction,
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn emitGenericCfgI64ValueIntoRax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    value: ir.Value,
) !void {
    switch (value) {
        .int => |int| try machine.instructions.append(allocator, .{ .mov_imm_rax = try i64Value(int) }),
        .named => |name| {
            if (sysvIntegerParamRegOrNull(function, name, .{ .int = 64 }) catch |err| switch (err) {
                error.UnsupportedCodegenAbi => null,
                else => return err,
            }) |reg| {
                try machine.instructions.append(allocator, .{ .mov_arg_rax = reg });
                return;
            }
            if (scalarParamStackDisp8(function, name, .{ .int = 64 }) catch |err| switch (err) {
                error.UnsupportedCodegenValue => null,
                else => return err,
            }) |offset| {
                try machine.instructions.append(allocator, .{ .load_stack_disp8_rax = offset });
                return;
            }
            const instruction = findInstruction(block, name) orelse return error.UnsupportedCodegenValue;
            const binary = switch (instruction.kind) {
                .binary => |binary| binary,
                else => return error.UnsupportedCodegenInstruction,
            };
            if (!binary.ty.eql(.{ .int = 64 }) or binary.op != .add) return error.UnsupportedCodegenInstruction;
            const rhs = switch (binary.rhs) {
                .int => |int| try i64Value(int),
                .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
            };
            if (rhs < 0 or rhs > 127) return error.UnsupportedCodegenValue;
            try emitGenericCfgI64ValueIntoRax(allocator, machine, function, block, binary.lhs);
            if (rhs != 0) try machine.instructions.append(allocator, .{ .add_rax_imm8 = @intCast(rhs) });
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn emitGenericCfgI32AddValueToEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    value: ir.Value,
) !void {
    switch (value) {
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
            const instruction = findInstruction(block, name) orelse return error.UnsupportedCodegenValue;
            const binary = switch (instruction.kind) {
                .binary => |binary| binary,
                else => return error.UnsupportedCodegenValue,
            };
            if (!binary.ty.eql(.{ .int = 32 }) or binary.op != .add) return error.UnsupportedCodegenInstruction;
            try emitGenericCfgI32AddValueToEax(allocator, machine, function, block, binary.lhs);
            try emitGenericCfgI32AddValueToEax(allocator, machine, function, block, binary.rhs);
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub const GenericCfgAddress = support.GenericCfgAddress;
pub const genericCfgI32Address = support.genericCfgI32Address;

pub fn emitGenericCfgLoadI32IntoEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    ptr: ir.Value,
) !void {
    switch (genericCfgI32Address(function, ptr) orelse return error.UnsupportedCodegenValue) {
        .param => |name| try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = try paramReg(function, name, .ptr) }),
        .global => |symbol| try machine.instructions.append(allocator, .{ .load_global_i32_eax = symbol }),
        .tls => |symbol| try machine.instructions.append(allocator, .{ .load_tls_i32_eax = symbol }),
    }
}

pub fn emitGenericCfgStoreEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    ptr: ir.Value,
) !void {
    switch (genericCfgI32Address(function, ptr) orelse return error.UnsupportedCodegenValue) {
        .param => |name| try machine.instructions.append(allocator, .{ .store_eax_arg_ptr = try paramReg(function, name, .ptr) }),
        .global => |symbol| try machine.instructions.append(allocator, .{ .store_eax_global_i32 = symbol }),
        .tls => |symbol| try machine.instructions.append(allocator, .{ .store_eax_tls_i32 = symbol }),
    }
}

pub fn emitGenericCfgI32CallIntoEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    instruction_index: usize,
    call: ir.CallInst,
) !void {
    if (genericCfgSupportsSminIntrinsicCall(function, call)) {
        const lhs_name = switch (call.args.items[0].value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        const rhs_name = switch (call.args.items[1].value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        if ((try paramReg(function, lhs_name, .{ .int = 32 })) != .rdi) return error.UnsupportedCodegenAbi;
        if ((try paramReg(function, rhs_name, .{ .int = 32 })) != .rsi) return error.UnsupportedCodegenAbi;
        try machine.instructions.append(allocator, .smin_i32_edi_esi_eax);
        return;
    }
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len > 18) return error.UnsupportedCodegenInstruction;
    if (call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!callIsFastcc(call.calling_conv)) try validateDefaultCallConv(call.calling_conv);
    const live_params = try liveParamsAfter(function, block, instruction_index);
    if (live_params.count == 0) {
        if (call.callee_value) |callee_value| {
            if (!call.ret_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
            const callee_name = switch (callee_value) {
                .named => |name| name,
                .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
            };
            const callee_reg = try paramReg(function, callee_name, .ptr);
            try machine.instructions.append(allocator, .{ .mov_arg_rax = callee_reg });
            const stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, call);
            try appendIndirectCallRaxWithStackArgs(allocator, machine, call.ret_ty, stack_arg_count);
            return;
        }
        const stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, call);
        try appendDirectCallWithStackArgs(allocator, machine, call.callee, call.ret_ty, stack_arg_count);
    } else {
        const stack_arg_count = try i32CallStackArgCount(call);
        if (stack_arg_count != 0) return error.UnsupportedLiveAcrossCall;
        if (call.callee_value) |callee_value| {
            const callee_name = switch (callee_value) {
                .named => |name| name,
                .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
            };
            try appendAlignedCallPreservingI32Params(allocator, machine, function, call, live_params, .{ .indirect_from_reg = try paramReg(function, callee_name, .ptr) });
        } else {
            try appendAlignedCallPreservingI32Params(allocator, machine, function, call, live_params, .{ .direct = call.callee });
        }
    }
}

pub fn emitGenericCfgVoidCall(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    instruction_index: usize,
    call: ir.CallInst,
) !void {
    if (call.isDebugVariableLocation()) return;
    if (call.ret_ty != .void or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!callIsFastcc(call.calling_conv)) try validateDefaultCallConv(call.calling_conv);
    const live_params = try liveParamsAfter(function, block, instruction_index);
    if (live_params.count == 0) {
        if (call.callee_value) |callee_value| {
            const callee_name = switch (callee_value) {
                .named => |name| name,
                .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
            };
            const callee_reg = try paramReg(function, callee_name, .ptr);
            try machine.instructions.append(allocator, .{ .mov_arg_rax = callee_reg });
            const stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, call);
            try appendIndirectCallRaxWithStackArgs(allocator, machine, .void, stack_arg_count);
            return;
        }
        const stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, call);
        try appendDirectCallWithStackArgs(allocator, machine, call.callee, .void, stack_arg_count);
        return;
    }
    const stack_arg_count = try i32CallStackArgCount(call);
    if (stack_arg_count != 0) return error.UnsupportedLiveAcrossCall;
    if (call.callee_value) |callee_value| {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        try appendAlignedCallPreservingI32Params(allocator, machine, function, call, live_params, .{ .indirect_from_reg = try paramReg(function, callee_name, .ptr) });
    } else {
        try appendAlignedCallPreservingI32Params(allocator, machine, function, call, live_params, .{ .direct = call.callee });
    }
}
