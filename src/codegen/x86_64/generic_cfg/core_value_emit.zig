const shared = @import("core_shared.zig");
const core_cfg_emit = @import("core_cfg_emit.zig");
const support = @import("core_value_support.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");
const cabi_call_lowering = @import("cabi_call_lowering.zig");

const std = shared.std;
const ir = shared.ir;
const sysv_abi = shared.sysv_abi;
const MachineFunction = shared.MachineFunction;

const appendDirectCallWithStackArgs = shared.appendDirectCallWithStackArgs;
const appendIndirectCallRaxWithStackArgs = shared.appendIndirectCallRaxWithStackArgs;
const appendGenericCfgBlockLabel = core_cfg_emit.appendGenericCfgBlockLabel;
const appendGenericCfgCompareParamZero = core_cfg_emit.appendGenericCfgCompareParamZero;
const appendGenericCfgConditionalBranch = core_cfg_emit.appendGenericCfgConditionalBranch;
const callIsFastcc = shared.callIsFastcc;
const i32BitPattern = shared.i32BitPattern;
const i32Value = shared.i32Value;
const i64Value = shared.i64Value;
const isCalleeName = shared.isCalleeName;
const isNamed = shared.isNamed;
const validateDefaultCallConv = shared.validateDefaultCallConv;

const paramReg = cabi_abi_helpers.paramReg;
const bitcastScalarParamRegOrNull = cabi_abi_helpers.bitcastScalarParamRegOrNull;
const registerParamRegOrNull = cabi_abi_helpers.registerParamRegOrNull;
const scalarParamStackDisp8 = cabi_abi_helpers.scalarParamStackDisp8;
const stackParamDisp8OrNull = cabi_abi_helpers.stackParamDisp8OrNull;
const sysvIntegerParamRegOrNull = cabi_abi_helpers.sysvIntegerParamRegOrNull;

const appendAlignedCallPreservingI32Params = cabi_call_lowering.appendAlignedCallPreservingI32Params;
const appendSysVScalarCallArgsWithBlock = cabi_call_lowering.appendSysVScalarCallArgsWithBlock;
const emitI32ParamOrStackIntoEax = cabi_call_lowering.emitI32ParamOrStackIntoEax;
const findInstruction = cabi_call_lowering.findInstruction;
const findInstructionIndex = cabi_call_lowering.findInstructionIndex;
const liveParamsAfter = cabi_call_lowering.liveParamsAfter;
const lowerGenericCfgSelectReturnValue = cabi_call_lowering.lowerGenericCfgSelectReturnValue;
const machineBinaryOp = cabi_call_lowering.machineBinaryOp;
const sysvScalarCallNeedsStackArgs = cabi_call_lowering.sysvScalarCallNeedsStackArgs;

const genericCfgSupportsSingleBlockI32Value = support.genericCfgSupportsSingleBlockI32Value;
const genericCfgSupportsSminIntrinsicCall = support.genericCfgSupportsSminIntrinsicCall;
const genericCfgLocalAggregateFieldLoad = support.genericCfgLocalAggregateFieldLoad;

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
            .load, .binary, .cast, .call => {},
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
                    try emitGenericCfgLoadI32IntoEax(allocator, machine, function, block, load.ptr);
                },
                .binary => |binary| {
                    if (!binary.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
                    try emitGenericCfgI32ValueIntoEax(allocator, machine, function, block, binary.lhs);
                    switch (binary.rhs) {
                        .int => |int| switch (binary.op) {
                            .add => try machine.instructions.append(allocator, .{ .add_eax_imm32 = try i32Value(int) }),
                            .sub => try machine.instructions.append(allocator, .{ .add_eax_imm32 = -try i32Value(int) }),
                            .@"and" => try machine.instructions.append(allocator, .{ .and_eax_imm32 = try i32BitPattern(int) }),
                            .@"or" => try machine.instructions.append(allocator, .{ .or_eax_imm32 = try i32BitPattern(int) }),
                            .shl => {
                                const shift = try i32Value(int);
                                if (shift < 0 or shift > 31) return error.UnsupportedCodegenValue;
                                if (shift != 0) try machine.instructions.append(allocator, .{ .shl_eax_imm5 = @intCast(shift) });
                            },
                            .lshr => {
                                const shift = try i32Value(int);
                                if (shift < 0 or shift > 31) return error.UnsupportedCodegenValue;
                                if (shift != 0) try machine.instructions.append(allocator, .{ .shr_eax_imm5 = @intCast(shift) });
                            },
                            else => return error.UnsupportedCodegenInstruction,
                        },
                        .named => |rhs_name| {
                            if (binary.op == .shl or binary.op == .lshr) {
                                const shift = singleBlockI32Constant(block, .{ .named = rhs_name }) orelse return error.UnsupportedCodegenValue;
                                if (shift < 0 or shift > 31) return error.UnsupportedCodegenValue;
                                if (shift != 0) {
                                    if (binary.op == .shl) {
                                        try machine.instructions.append(allocator, .{ .shl_eax_imm5 = @intCast(shift) });
                                    } else {
                                        try machine.instructions.append(allocator, .{ .shr_eax_imm5 = @intCast(shift) });
                                    }
                                }
                                return;
                            }
                            const op = machineBinaryOp(binary.op) orelse return error.UnsupportedCodegenInstruction;
                            if (try registerParamRegOrNull(function, rhs_name, .{ .int = 32 })) |rhs| {
                                try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = op, .reg = rhs } });
                                return;
                            }
                            if (try stackParamDisp8OrNull(function, rhs_name, .{ .int = 32 })) |offset| {
                                if (op != .add) return error.UnsupportedCodegenInstruction;
                                if (offset <= std.math.maxInt(i8)) {
                                    try machine.instructions.append(allocator, .{ .add_stack_disp8_eax = @intCast(offset) });
                                } else {
                                    try machine.instructions.append(allocator, .{ .add_stack_disp32_eax = offset });
                                }
                                return;
                            }
                            if (op != .add) return error.UnsupportedCodegenInstruction;
                            const rhs_instruction = findInstruction(block, rhs_name) orelse return error.UnsupportedCodegenValue;
                            switch (rhs_instruction.kind) {
                                .load => |rhs_load| switch (genericCfgI32Address(function, rhs_load.ptr) orelse return error.UnsupportedCodegenValue) {
                                    .tls => |symbol| try machine.instructions.append(allocator, .{ .add_tls_i32_eax = symbol }),
                                    .global => {
                                        if (!genericCfgSupportsSingleBlockI32Value(function, block, binary.lhs)) return error.UnsupportedCodegenValue;
                                        try emitGenericCfgI32ValueIntoEax(allocator, machine, function, block, binary.rhs);
                                        try emitGenericCfgI32AddValueToEax(allocator, machine, function, block, binary.lhs);
                                    },
                                    .param => return error.UnsupportedCodegenValue,
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
                .cast => |cast| {
                    switch (cast.op) {
                        .zext => {
                            if (!cast.to_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
                            const bits = switch (cast.from_ty) {
                                .int => |bits| bits,
                                else => return error.UnsupportedCodegenType,
                            };
                            if (bits > 32) return error.UnsupportedCodegenType;
                            try emitGenericCfgIntBitsValueIntoEax(allocator, machine, function, block, cast.value, bits);
                            if (try zextMaskI32(bits)) |mask| try machine.instructions.append(allocator, .{ .and_eax_imm32 = mask });
                        },
                        .bitcast => {
                            if (!cast.to_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
                            if (!cast.from_ty.eql(.{ .int = 32 })) {
                                const source_name = switch (cast.value) {
                                    .named => |source_name| source_name,
                                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
                                };
                                const reg = try bitcastScalarParamRegOrNull(function, source_name, cast.from_ty, cast.to_ty) orelse
                                    return error.UnsupportedCodegenValue;
                                try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
                                return;
                            }
                            try emitGenericCfgI32ValueIntoEax(allocator, machine, function, block, cast.value);
                        },
                        .sext => {
                            const constant = singleBlockI32CastConstant(block, cast) orelse return error.UnsupportedCodegenInstruction;
                            try machine.instructions.append(allocator, .{ .mov_imm_eax = try i32Value(constant) });
                        },
                        else => return error.UnsupportedCodegenInstruction,
                    }
                },
                .phi, .icmp, .fcmp, .freeze, .alloca, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep => return error.UnsupportedCodegenInstruction,
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn emitGenericCfgBoolValueIntoEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    value: ir.Value,
) !void {
    switch (value) {
        .int => |int| switch (int) {
            0, 1 => try machine.instructions.append(allocator, .{ .mov_imm_eax = @intCast(int) }),
            else => return error.UnsupportedCodegenValue,
        },
        .named => |name| {
            const instruction = findInstruction(block, name) orelse return error.UnsupportedCodegenValue;
            const icmp = switch (instruction.kind) {
                .icmp => |icmp| icmp,
                else => return error.UnsupportedCodegenInstruction,
            };
            const label_suffix = machine.instructions.items.len;
            const true_label = try ownedMachineLabel(
                allocator,
                machine,
                "generic_cfg_bool_return_{}_true",
                .{label_suffix},
            );
            const end_label = try ownedMachineLabel(
                allocator,
                machine,
                "generic_cfg_bool_return_{}_generic_cfg_select_end",
                .{label_suffix},
            );
            const branch_kind = try cabi_call_lowering.emitGenericCfgIcmpConditionWithBlock(
                allocator,
                machine,
                function,
                block,
                icmp,
            );
            try appendGenericCfgConditionalBranch(allocator, machine, branch_kind, true_label);
            try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
            try machine.instructions.append(allocator, .{ .jmp = end_label });
            try appendGenericCfgBlockLabel(allocator, machine, true_label);
            try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
            try appendGenericCfgBlockLabel(allocator, machine, end_label);
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn emitGenericCfgIntBitsValueIntoEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    value: ir.Value,
    bits: u16,
) anyerror!void {
    if (bits == 0 or bits > 32) return error.UnsupportedCodegenType;
    if (bits == 32) return emitGenericCfgI32ValueIntoEax(allocator, machine, function, block, value);
    switch (value) {
        .int => |int| {
            if (!intFitsUnsignedBits(int, bits)) return error.UnsupportedCodegenValue;
            try machine.instructions.append(allocator, .{ .mov_imm_eax = @intCast(int) });
        },
        .named => |name| {
            if (try registerParamRegOrNull(function, name, .{ .int = bits })) |reg| {
                try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
                return;
            }
            const instruction = findInstruction(block, name) orelse return error.UnsupportedCodegenValue;
            switch (instruction.kind) {
                .cast => |cast| {
                    if (cast.op != .bitcast or !cast.to_ty.eql(.{ .int = bits }) or !cast.from_ty.eql(.{ .int = bits })) {
                        return error.UnsupportedCodegenInstruction;
                    }
                    try emitGenericCfgIntBitsValueIntoEax(allocator, machine, function, block, cast.value, bits);
                },
                .binary => |binary| {
                    if (!binary.ty.eql(.{ .int = bits }) or binary.op != .@"and") return error.UnsupportedCodegenInstruction;
                    const rhs = switch (binary.rhs) {
                        .int => |int| int,
                        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
                    };
                    if (!intFitsUnsignedBits(rhs, bits)) return error.UnsupportedCodegenValue;
                    try emitGenericCfgIntBitsValueIntoEax(allocator, machine, function, block, binary.lhs, bits);
                    try machine.instructions.append(allocator, .{ .and_eax_imm32 = @intCast(rhs) });
                },
                else => return error.UnsupportedCodegenInstruction,
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

fn intFitsUnsignedBits(value: i128, bits: u16) bool {
    if (bits == 0 or bits > 32 or value < 0) return false;
    if (bits == 32) return value <= std.math.maxInt(u32);
    const shift: u5 = @intCast(bits);
    return value < (@as(i128, 1) << shift);
}

fn zextMaskI32(bits: u16) !?i32 {
    if (bits == 0 or bits > 32) return error.UnsupportedCodegenType;
    if (bits == 32) return null;
    const shift: u5 = @intCast(bits);
    const mask = (@as(u32, 1) << shift) - 1;
    return @intCast(mask);
}

fn singleBlockI32Constant(block: ir.BasicBlock, value: ir.Value) ?i64 {
    return switch (value) {
        .int => |int| i64Value(int) catch null,
        .named => |name| blk: {
            const instruction = findInstruction(block, name) orelse break :blk null;
            break :blk switch (instruction.kind) {
                .cast => |cast| singleBlockI32CastConstant(block, cast),
                else => null,
            };
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
    };
}

fn singleBlockI32CastConstant(block: ir.BasicBlock, cast: ir.CastInst) ?i64 {
    switch (cast.op) {
        .zext, .sext, .bitcast => {},
        else => return null,
    }
    if (!cast.to_ty.eql(.{ .int = 32 })) return null;
    switch (cast.from_ty) {
        .int => |bits| if (bits > 32) return null,
        else => return null,
    }
    return singleBlockI32Constant(block, cast.value);
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
                if (offset <= std.math.maxInt(i8)) {
                    try machine.instructions.append(allocator, .{ .load_stack_disp8_rax = @intCast(offset) });
                } else {
                    try machine.instructions.append(allocator, .{ .load_stack_disp32_rax = offset });
                }
                return;
            }
            const instruction = findInstruction(block, name) orelse return error.UnsupportedCodegenValue;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (!binary.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenInstruction;
                    const rhs = switch (binary.rhs) {
                        .int => |int| try i64Value(int),
                        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
                    };
                    try emitGenericCfgI64ValueIntoRax(allocator, machine, function, block, binary.lhs);
                    switch (binary.op) {
                        .add => {
                            if (rhs < 0 or rhs > 127) return error.UnsupportedCodegenValue;
                            if (rhs != 0) try machine.instructions.append(allocator, .{ .add_rax_imm8 = @intCast(rhs) });
                        },
                        .sub => {
                            if (rhs < 0 or rhs > 127) return error.UnsupportedCodegenValue;
                            if (rhs != 0) try machine.instructions.append(allocator, .{ .add_rax_imm8 = @intCast(-rhs) });
                        },
                        .@"and" => {
                            if (rhs < std.math.minInt(i32) or rhs > std.math.maxInt(i32)) return error.UnsupportedCodegenValue;
                            try machine.instructions.append(allocator, .{ .and_eax_imm32 = @intCast(rhs) });
                        },
                        .lshr => {
                            if (rhs < 0 or rhs > 63) return error.UnsupportedCodegenValue;
                            if (rhs != 0) try machine.instructions.append(allocator, .{ .shr_rax_imm6 = @intCast(rhs) });
                        },
                        else => return error.UnsupportedCodegenInstruction,
                    }
                },
                .cast => |cast| {
                    if (cast.op != .zext or !cast.to_ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenInstruction;
                    switch (cast.from_ty) {
                        .int => |bits| if (bits > 32) return error.UnsupportedCodegenType,
                        else => return error.UnsupportedCodegenType,
                    }
                    switch (cast.value) {
                        .int => |int| try machine.instructions.append(allocator, .{ .mov_imm_rax = try i64Value(int) }),
                        .named => try emitGenericCfgI64ValueIntoRax(allocator, machine, function, block, cast.value),
                        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
                    }
                },
                .select => |select| try emitGenericCfgI64SelectIntoRax(allocator, machine, function, block, name, select),
                else => return error.UnsupportedCodegenInstruction,
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

fn emitGenericCfgI64SelectIntoRax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    result_name: []const u8,
    select: ir.SelectInst,
) anyerror!void {
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
    const cond_name = switch (select.cond) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    const cond_instruction = findInstruction(block, cond_name) orelse return error.UnsupportedCodegenValue;
    const icmp = switch (cond_instruction.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    const label_suffix = machine.instructions.items.len;
    const true_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_i64_select_{s}_{}_true",
        .{ result_name, label_suffix },
    );
    const end_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_i64_select_{s}_{}_generic_cfg_select_end",
        .{ result_name, label_suffix },
    );
    const branch_kind = try cabi_call_lowering.emitGenericCfgIcmpCondition(allocator, machine, function, icmp);
    try appendGenericCfgConditionalBranch(allocator, machine, branch_kind, true_label);
    try emitGenericCfgI64ValueIntoRax(allocator, machine, function, block, select.false_value);
    try machine.instructions.append(allocator, .{ .jmp = end_label });
    try appendGenericCfgBlockLabel(allocator, machine, true_label);
    try emitGenericCfgI64ValueIntoRax(allocator, machine, function, block, select.true_value);
    try appendGenericCfgBlockLabel(allocator, machine, end_label);
}

fn ownedMachineLabel(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    comptime fmt: []const u8,
    args: anytype,
) ![]const u8 {
    const label = try std.fmt.allocPrint(allocator, fmt, args);
    errdefer allocator.free(label);
    try machine.owned_labels.append(allocator, label);
    return label;
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
                if (offset <= std.math.maxInt(i8)) {
                    try machine.instructions.append(allocator, .{ .add_stack_disp8_eax = @intCast(offset) });
                } else {
                    try machine.instructions.append(allocator, .{ .add_stack_disp32_eax = offset });
                }
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
    maybe_block: ?ir.BasicBlock,
    ptr: ir.Value,
) !void {
    if (maybe_block) |block| {
        const ptr_name = switch (ptr) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
        };
        if (ptr_name) |name| {
            const instruction = findInstruction(block, name) orelse null;
            if (instruction) |alloca_instruction| switch (alloca_instruction.kind) {
                .alloca => {
                    const synthetic_load: ir.LoadInst = .{
                        .ty = .{ .int = 32 },
                        .ptr = ptr,
                    };
                    if (genericCfgLocalAggregateFieldLoad(function, block, synthetic_load)) |field| {
                        try emitSysVIntegerAggregateFieldLoadIntoEax(allocator, machine, function, field);
                        return;
                    }
                },
                else => {},
            };
        }
    }
    switch (genericCfgI32Address(function, ptr) orelse return error.UnsupportedCodegenValue) {
        .param => |name| try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = try paramReg(function, name, .ptr) }),
        .global => |symbol| try machine.instructions.append(allocator, .{ .load_global_i32_eax = symbol }),
        .tls => |symbol| try machine.instructions.append(allocator, .{ .load_tls_i32_eax = symbol }),
    }
}

fn emitSysVIntegerAggregateFieldLoadIntoEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    field: support.GenericCfgLocalAggregateField,
) !void {
    const location = try cabi_abi_helpers.sysvIntegerAggregateFieldLocation(
        function,
        field.param_name,
        field.aggregate_ty,
        field.offset,
        .{ .int = 32 },
    );
    switch (location) {
        .gpr => |gpr| switch (gpr.offset_in_eightbyte) {
            0 => try machine.instructions.append(allocator, .{ .mov_arg_eax = gpr.reg }),
            4 => {
                try machine.instructions.append(allocator, .{ .mov_arg_rax = gpr.reg });
                try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 32 });
            },
            else => return error.UnsupportedCodegenAbi,
        },
        .stack => |offset| {
            if (offset <= std.math.maxInt(i8)) {
                try machine.instructions.append(allocator, .{ .load_stack_disp8_eax = @intCast(offset) });
            } else {
                try machine.instructions.append(allocator, .{ .load_stack_disp32_eax = offset });
            }
        },
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
    if (isCalleeName(call.callee, "llvm.bitreverse.i32")) {
        if (call.callee_value != null or call.inline_asm != null or !call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
        if (!call.args.items[0].ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
        const source_name = switch (call.args.items[0].value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        if ((try paramReg(function, source_name, .{ .int = 32 })) != .rdi) return error.UnsupportedCodegenAbi;
        try machine.instructions.append(allocator, .bit_reverse_i32_edi_eax);
        return;
    }
    if (isUshlSatI32Callee(call.callee)) {
        if (call.callee_value != null or call.inline_asm != null or !call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 2) return error.UnsupportedCodegenInstruction;
        if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !call.args.items[1].ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
        const source_name = switch (call.args.items[0].value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        const amount_i128 = switch (call.args.items[1].value) {
            .int => |value| value,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        if (amount_i128 < 0 or amount_i128 > 31) return error.UnsupportedCodegenValue;
        if ((try paramReg(function, source_name, .{ .int = 32 })) != .rdi) return error.UnsupportedCodegenAbi;
        try machine.instructions.append(allocator, .{ .ushl_sat_i32_edi_imm_eax = @intCast(amount_i128) });
        return;
    }
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
            const stack_arg_count = if (sysv_abi.callHasByvalArgAttrs(call)) count: {
                const count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, call);
                try machine.instructions.append(allocator, .{ .mov_arg_rax = callee_reg });
                break :count count;
            } else count: {
                try machine.instructions.append(allocator, .{ .mov_arg_rax = callee_reg });
                break :count try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, call);
            };
            try appendIndirectCallRaxWithStackArgs(allocator, machine, call.ret_ty, stack_arg_count);
            return;
        }
        const stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, call);
        try appendDirectCallWithStackArgs(allocator, machine, call.callee, call.ret_ty, stack_arg_count);
    } else {
        if (sysvScalarCallNeedsStackArgs(call)) return error.UnsupportedLiveAcrossCall;
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

pub fn isUshlSatI32Callee(callee: []const u8) bool {
    if (isCalleeName(callee, "llvm.ushl.sat.i32")) return true;
    return std.mem.indexOf(u8, callee, "llvm.ushl.sat.i32") != null;
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
    if (std.mem.eql(u8, call.callee, "debug.assert")) {
        try emitGenericCfgDebugAssert(allocator, machine, function, block, call);
        return;
    }
    const live_params = try liveParamsAfter(function, block, instruction_index);
    if (live_params.count == 0) {
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
            try appendIndirectCallRaxWithStackArgs(allocator, machine, .void, stack_arg_count);
            return;
        }
        const stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, call);
        try appendDirectCallWithStackArgs(allocator, machine, call.callee, .void, stack_arg_count);
        return;
    }
    if (sysvScalarCallNeedsStackArgs(call)) return error.UnsupportedLiveAcrossCall;
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

fn emitGenericCfgDebugAssert(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    call: ir.CallInst,
) !void {
    if (call.callee_value != null or call.args.items.len != 1 or
        !call.args.items[0].ty.eql(.{ .int = 1 })) return error.UnsupportedCodegenInstruction;
    switch (call.args.items[0].value) {
        .int => |int| {
            if (int == 1) return;
            if (int != 0) return error.UnsupportedCodegenValue;
            try machine.instructions.append(allocator, .ud2);
            return;
        },
        else => {},
    }
    const ok_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_debug_assert_{}_ok",
        .{machine.instructions.items.len},
    );
    switch (call.args.items[0].value) {
        .int => unreachable,
        .named => |name| {
            if (findInstruction(block, name)) |instruction| {
                const icmp = switch (instruction.kind) {
                    .icmp => |icmp| icmp,
                    else => return error.UnsupportedCodegenInstruction,
                };
                const branch_kind = try cabi_call_lowering.emitGenericCfgIcmpConditionWithBlock(
                    allocator,
                    machine,
                    function,
                    block,
                    icmp,
                );
                try appendGenericCfgConditionalBranch(allocator, machine, branch_kind, ok_label);
            } else {
                try appendGenericCfgCompareParamZero(allocator, machine, try paramReg(function, name, .{ .int = 1 }));
                try appendGenericCfgConditionalBranch(allocator, machine, .jne, ok_label);
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
    try machine.instructions.append(allocator, .ud2);
    try appendGenericCfgBlockLabel(allocator, machine, ok_label);
}
