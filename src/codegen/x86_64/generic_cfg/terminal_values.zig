const shared = @import("core_shared.zig");
const core_cfg_emit = @import("core_cfg_emit.zig");
const core_value_support = @import("core_value_support.zig");
const core_value_emit = @import("core_value_emit.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");
const cabi_call_lowering = @import("cabi_call_lowering.zig");
const pointer_slice_rows = @import("pointer_slice_rows.zig");

const std = shared.std;
const ir = shared.ir;
const MachineFunction = shared.MachineFunction;
const ArgReg = shared.ArgReg;

const appendDirectCallWithStackArgs = shared.appendDirectCallWithStackArgs;
const appendGenericCfgBlockLabel = core_cfg_emit.appendGenericCfgBlockLabel;
const appendGenericCfgCompareLocalImm = core_cfg_emit.appendGenericCfgCompareLocalImm;
const appendGenericCfgCompareParamZero = core_cfg_emit.appendGenericCfgCompareParamZero;
const appendGenericCfgConditionalBranch = core_cfg_emit.appendGenericCfgConditionalBranch;
const appendGenericCfgReturn = core_cfg_emit.appendGenericCfgReturn;
const appendSysVScalarCallArgsWithBlock = cabi_call_lowering.appendSysVScalarCallArgsWithBlock;
const callIsFastcc = shared.callIsFastcc;
const emitGenericCfgI32AddValueToEax = core_value_emit.emitGenericCfgI32AddValueToEax;
const emitGenericCfgI32ValueIntoEax = core_value_emit.emitGenericCfgI32ValueIntoEax;
const emitGenericCfgIcmpCondition = cabi_call_lowering.emitGenericCfgIcmpCondition;
const findInstruction = cabi_call_lowering.findInstruction;
const genericCfgSupportsSingleBlockI32Value = core_value_support.genericCfgSupportsSingleBlockI32Value;
const genericCfgSupportsSingleBlockIcmp = core_value_support.genericCfgSupportsSingleBlockIcmp;
const i32BitPattern = shared.i32BitPattern;
const i32Value = shared.i32Value;
const i64Value = shared.i64Value;
const isInt = shared.isInt;
const machineBinaryOp = cabi_call_lowering.machineBinaryOp;
const paramRegOrNull = cabi_abi_helpers.paramRegOrNull;
const validateDefaultCallConv = shared.validateDefaultCallConv;
const blockIndex = cabi_abi_helpers.blockIndex;
const isNamed = shared.isNamed;

pub fn terminalCondParamReg(function: ir.Function, cond: ir.Value) ?ArgReg {
    const cond_name = switch (cond) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    return paramRegOrNull(function, cond_name, .{ .int = 1 }) catch null;
}

pub fn genericCfgTerminalBranchExtraBlocksAreUnreachable(function: ir.Function, then_index: usize, else_index: usize) bool {
    for (function.blocks.items, 0..) |block, index| {
        if (index == 0 or index == then_index or index == else_index) continue;
        switch (block.terminator orelse return false) {
            .@"unreachable" => {},
            else => return false,
        }
    }
    return true;
}

pub fn singleBrTarget(block: ir.BasicBlock) ?[]const u8 {
    return switch (block.terminator orelse return null) {
        .br => |br| br.target,
        else => null,
    };
}

pub fn blockIsUnreachable(block: ir.BasicBlock) bool {
    return switch (block.terminator orelse return false) {
        .@"unreachable" => true,
        else => false,
    };
}

pub fn blockHasCondbr(block: ir.BasicBlock) bool {
    return switch (block.terminator orelse return false) {
        .condbr => true,
        else => false,
    };
}

pub fn blockSwitchTerminator(block: ir.BasicBlock) ?ir.SwitchTerminator {
    return switch (block.terminator orelse return null) {
        .@"switch" => |switch_term| switch_term,
        else => null,
    };
}

pub fn commonSwitchMergeBlock(function: ir.Function, switch_term: ir.SwitchTerminator) ?ir.BasicBlock {
    var target: ?[]const u8 = null;
    for (switch_term.cases.items) |case| {
        const block = function.blocks.items[blockIndex(function, case.target) orelse return null];
        const branch_target = singleBrTarget(block) orelse return null;
        if (target) |existing| {
            if (!std.mem.eql(u8, existing, branch_target)) return null;
        } else {
            target = branch_target;
        }
    }
    const default_block = function.blocks.items[blockIndex(function, switch_term.default_target) orelse return null];
    const default_target = singleBrTarget(default_block) orelse return null;
    if (target) |existing| {
        if (!std.mem.eql(u8, existing, default_target)) return null;
    } else {
        target = default_target;
    }
    return function.blocks.items[blockIndex(function, target orelse return null) orelse return null];
}

pub fn firstPhiReturn(function: ir.Function, block: ir.BasicBlock) ?ir.PhiInst {
    if (block.instructions.items.len != 1) return null;
    const phi_name = block.instructions.items[0].result orelse return null;
    const phi = switch (block.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return null,
    };
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(function.ret_ty) or !isNamed(ret.value orelse return null, phi_name)) return null;
    return phi;
}

pub fn phiIncomingForBlock(phi: ir.PhiInst, block_name: []const u8) ?ir.Value {
    for (phi.incoming.items) |incoming| {
        if (std.mem.eql(u8, incoming.block, block_name)) return incoming.value;
    }
    return null;
}

pub fn blockBranchesTo(block: ir.BasicBlock, target: []const u8) bool {
    const branch_target = singleBrTarget(block) orelse return false;
    return std.mem.eql(u8, branch_target, target);
}

pub fn linearTerminalBranchUsesAllBlocks(
    function: ir.Function,
    continuation_index: usize,
    first_return_index: usize,
    second_then_index: usize,
    second_else_index: usize,
) bool {
    for (function.blocks.items, 0..) |block, index| {
        if (index == 0 or index == continuation_index or index == first_return_index or
            index == second_then_index or index == second_else_index)
        {
            continue;
        }
        switch (block.terminator orelse return false) {
            .@"unreachable" => {},
            else => return false,
        }
    }
    return second_then_index != second_else_index;
}

pub fn genericCfgSupportsTerminalReturnBlock(function: ir.Function, entry: ir.BasicBlock, block: ir.BasicBlock) bool {
    return genericCfgSupportsTerminalReturnBlockInScope(function, .{ .entry = entry, .block = block });
}

pub fn genericCfgSupportsNestedTerminalReturnBlock(function: ir.Function, entry: ir.BasicBlock, middle: ir.BasicBlock, block: ir.BasicBlock) bool {
    return genericCfgSupportsTerminalReturnBlockInScope(function, .{ .entry = entry, .middle = middle, .block = block });
}

pub fn genericCfgSupportsTerminalReturnBlockInScope(function: ir.Function, scope: TerminalValueScope) bool {
    const ret = switch (scope.block.terminator orelse return false) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(function.ret_ty)) return false;
    const ret_value = ret.value orelse return false;
    if (function.ret_ty.eql(.{ .int = 32 })) {
        return genericCfgSupportsSingleBlockI32Value(function, scope.block, ret_value) or
            terminalBlockCanMaterializeI32Value(function, scope, ret_value);
    }
    return terminalBlockCanMaterializeI64Value(function, scope, ret_value);
}

pub const TerminalValueScope = struct {
    entry: ir.BasicBlock,
    middle: ?ir.BasicBlock = null,
    block: ir.BasicBlock,
};

pub fn terminalScopeInstruction(scope: TerminalValueScope, name: []const u8) ?ir.Instruction {
    if (findInstruction(scope.block, name)) |instruction| return instruction;
    if (scope.middle) |middle| {
        if (findInstruction(middle, name)) |instruction| return instruction;
    }
    return findInstruction(scope.entry, name);
}

const TerminalScopeInstruction = struct {
    instruction: ir.Instruction,
    block: ir.BasicBlock,
};

fn terminalScopeInstructionWithBlock(scope: TerminalValueScope, name: []const u8) ?TerminalScopeInstruction {
    if (findInstruction(scope.block, name)) |instruction| return .{ .instruction = instruction, .block = scope.block };
    if (scope.middle) |middle| {
        if (findInstruction(middle, name)) |instruction| return .{ .instruction = instruction, .block = middle };
    }
    if (findInstruction(scope.entry, name)) |instruction| return .{ .instruction = instruction, .block = scope.entry };
    return null;
}

pub fn terminalBlockCanMaterializeI32Value(function: ir.Function, scope: TerminalValueScope, value: ir.Value) bool {
    return switch (value) {
        .int => true,
        .named => |name| blk: {
            if ((paramRegOrNull(function, name, .{ .int = 32 }) catch null) != null) break :blk true;
            const instruction = terminalScopeInstruction(scope, name) orelse break :blk false;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (!binary.ty.eql(.{ .int = 32 })) break :blk false;
                    if (binary.op == .shl or binary.op == .lshr) {
                        const shift = terminalScopeI32Constant(scope, binary.rhs) orelse break :blk false;
                        if (shift < 0 or shift > 31) break :blk false;
                        break :blk terminalBlockCanMaterializeI32Value(function, scope, binary.lhs);
                    }
                    if (machineBinaryOp(binary.op) == null) break :blk false;
                    break :blk terminalBlockCanMaterializeI32Value(function, scope, binary.lhs) and
                        terminalBlockCanMaterializeI32Value(function, scope, binary.rhs);
                },
                .cast => |cast| {
                    if (!cast.to_ty.eql(.{ .int = 32 })) break :blk false;
                    switch (cast.op) {
                        .trunc => {
                            if (!cast.from_ty.eql(.{ .int = 64 })) break :blk false;
                            break :blk terminalBlockCanMaterializeI64Value(function, scope, cast.value);
                        },
                        .zext => {
                            const bits = switch (cast.from_ty) {
                                .int => |bits| bits,
                                else => break :blk false,
                            };
                            if (bits > 32) break :blk false;
                            break :blk terminalBlockCanMaterializeIntBitsValue(function, scope, cast.value, bits);
                        },
                        .bitcast => {
                            if (!cast.from_ty.eql(.{ .int = 32 })) break :blk false;
                            break :blk terminalBlockCanMaterializeI32Value(function, scope, cast.value);
                        },
                        else => break :blk false,
                    }
                },
                else => break :blk false,
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

pub fn terminalBlockCanMaterializeI64Value(function: ir.Function, scope: TerminalValueScope, value: ir.Value) bool {
    return switch (value) {
        .int => true,
        .named => |name| blk: {
            if ((paramRegOrNull(function, name, .{ .int = 64 }) catch null) != null) break :blk true;
            const instruction = terminalScopeInstruction(scope, name) orelse break :blk false;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (!binary.ty.eql(.{ .int = 64 })) break :blk false;
                    switch (binary.op) {
                        .lshr, .shl => {
                            const shift = terminalScopeI64Constant(scope, binary.rhs) orelse break :blk false;
                            if (shift < 0 or shift > 63) break :blk false;
                            break :blk terminalBlockCanMaterializeI64Value(function, scope, binary.lhs);
                        },
                        .add, .@"and" => {},
                        else => break :blk false,
                    }
                    if (binary.rhs != .int) break :blk false;
                    break :blk terminalBlockCanMaterializeI64Value(function, scope, binary.lhs);
                },
                .cast => |cast| {
                    if (cast.op != .zext or !cast.to_ty.eql(.{ .int = 64 })) break :blk false;
                    switch (cast.from_ty) {
                        .int => |bits| {
                            if (bits > 32) break :blk false;
                            if (bits == 16) break :blk terminalBlockCanMaterializeU16Value(function, scope, cast.value);
                        },
                        else => break :blk false,
                    }
                    break :blk terminalBlockCanMaterializeI32Value(function, scope, cast.value);
                },
                .select => |select| {
                    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 64 })) break :blk false;
                    break :blk terminalBlockCanMaterializeI64Value(function, scope, select.true_value) and
                        terminalBlockCanMaterializeI64Value(function, scope, select.false_value);
                },
                .call => |call| {
                    break :blk call.ret_ty.eql(.{ .int = 64 }) and call.inline_asm == null and call.callee_value == null;
                },
                .extractvalue => |extract| {
                    if (!extract.result_ty.eql(.{ .int = 64 }) or !std.mem.eql(u8, extract.indices, "1")) break :blk false;
                    _ = pointer_slice_rows.resolveSliceLengthValue(function, scope.block, value) catch break :blk false;
                    break :blk true;
                },
                else => break :blk false,
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

pub fn emitGenericCfgTerminalConditionTrueBranch(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    entry: ir.BasicBlock,
    block: ir.BasicBlock,
    cond: ir.Value,
    true_label: []const u8,
) !void {
    const cond_name = switch (cond) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    const cond_inst = findInstruction(block, cond_name) orelse {
        try emitGenericCfgConditionTrueBranch(allocator, machine, function, block, cond, true_label);
        return;
    };
    if (try emitGenericCfgAndConditionTrueBranch(allocator, machine, function, block, cond_inst, true_label)) return;
    const icmp = switch (cond_inst.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (try emitGenericCfgTerminalI16IcmpConditionTrueBranch(allocator, machine, function, .{ .entry = entry, .block = block }, icmp, true_label)) return;
    if (icmp.predicate == .ugt and icmp.operand_ty.eql(.{ .int = 32 })) {
        const rhs = switch (icmp.rhs) {
            .int => |int| try i32Value(int),
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        if (rhs == std.math.maxInt(i32)) return error.UnsupportedCodegenValue;
        try emitGenericCfgTerminalI32ValueIntoEax(allocator, machine, function, entry, block, icmp.lhs);
        try appendGenericCfgCompareLocalImm(allocator, machine, .eax, rhs + 1);
        try appendGenericCfgConditionalBranch(allocator, machine, .jae, true_label);
        return;
    }
    if (icmp.operand_ty.eql(.{ .int = 64 }) and (icmp.predicate == .eq or icmp.predicate == .ne)) {
        const value = if (isInt(icmp.rhs, 0)) icmp.lhs else if (isInt(icmp.lhs, 0)) icmp.rhs else return error.UnsupportedCodegenValue;
        try emitGenericCfgTerminalI64ValueIntoRax(allocator, machine, function, entry, block, value);
        try machine.instructions.append(allocator, .test_rax_rax);
        try appendGenericCfgConditionalBranch(allocator, machine, if (icmp.predicate == .eq) .je else .jne, true_label);
        return;
    }
    try emitGenericCfgConditionTrueBranch(allocator, machine, function, block, cond, true_label);
}

fn emitGenericCfgTerminalI16IcmpConditionTrueBranch(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    scope: TerminalValueScope,
    icmp: ir.IcmpInst,
    true_label: []const u8,
) !bool {
    if (!icmp.operand_ty.eql(.{ .int = 16 })) return false;
    switch (icmp.predicate) {
        .eq, .ne, .slt => {},
        .ugt, .uge, .ult, .ule, .sgt, .sge, .sle => return false,
    }
    const lhs_reg = terminalI16ValueReg(function, scope, icmp.lhs) orelse return false;
    const rhs_imm = switch (icmp.rhs) {
        .int => |int| try u16TerminalImm(if (icmp.predicate == .slt) int - 1 else int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    try machine.instructions.append(allocator, .{ .cmp_arg16_imm16 = .{ .reg = lhs_reg, .imm = rhs_imm } });
    const branch_kind: core_cfg_emit.GenericCfgBranchKind = switch (icmp.predicate) {
        .eq => .je,
        .ne => .jne,
        .slt => .jle,
        else => unreachable,
    };
    try appendGenericCfgConditionalBranch(allocator, machine, branch_kind, true_label);
    return true;
}

fn terminalBlockCanMaterializeU16Value(function: ir.Function, scope: TerminalValueScope, value: ir.Value) bool {
    return switch (value) {
        .int => |int| int >= 0 and int <= std.math.maxInt(u16),
        .named => |name| blk: {
            if ((paramRegOrNull(function, name, .{ .int = 16 }) catch null) != null) break :blk true;
            const instruction = terminalScopeInstruction(scope, name) orelse break :blk false;
            switch (instruction.kind) {
                .select => |select| {
                    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 16 })) break :blk false;
                    const cond_name = switch (select.cond) {
                        .named => |cond_name| cond_name,
                        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => break :blk false,
                    };
                    const cond_instruction = terminalScopeInstruction(scope, cond_name) orelse break :blk false;
                    const icmp = switch (cond_instruction.kind) {
                        .icmp => |icmp| icmp,
                        else => break :blk false,
                    };
                    if (!terminalBlockCanBranchOnIcmp(function, scope, icmp)) break :blk false;
                    break :blk terminalBlockCanMaterializeU16Value(function, scope, select.true_value) and
                        terminalBlockCanMaterializeU16Value(function, scope, select.false_value);
                },
                else => break :blk false,
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

fn terminalBlockCanBranchOnIcmp(function: ir.Function, scope: TerminalValueScope, icmp: ir.IcmpInst) bool {
    if (genericCfgSupportsSingleBlockIcmp(function, null, icmp)) return true;
    if (!icmp.operand_ty.eql(.{ .int = 16 })) return false;
    switch (icmp.predicate) {
        .eq, .ne, .slt => {},
        .ugt, .uge, .ult, .ule, .sgt, .sge, .sle => return false,
    }
    if (terminalI16ValueReg(function, scope, icmp.lhs) == null) return false;
    const rhs = switch (icmp.rhs) {
        .int => |int| if (icmp.predicate == .slt) int - 1 else int,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    return rhs >= 0 and rhs <= std.math.maxInt(u16);
}

fn terminalBlockCanMaterializeIntBitsValue(function: ir.Function, scope: TerminalValueScope, value: ir.Value, bits: u16) bool {
    if (bits == 0 or bits > 32) return false;
    if (bits == 32) return terminalBlockCanMaterializeI32Value(function, scope, value);
    return switch (value) {
        .int => |int| intFitsUnsignedBits(int, bits),
        .named => |name| blk: {
            if ((paramRegOrNull(function, name, .{ .int = bits }) catch null) != null) break :blk true;
            const instruction = terminalScopeInstruction(scope, name) orelse break :blk false;
            const cast = switch (instruction.kind) {
                .cast => |cast| cast,
                else => break :blk false,
            };
            if (cast.op != .bitcast or !cast.to_ty.eql(.{ .int = bits }) or !cast.from_ty.eql(.{ .int = bits })) break :blk false;
            break :blk terminalBlockCanMaterializeIntBitsValue(function, scope, cast.value, bits);
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

fn terminalI16ValueReg(function: ir.Function, scope: TerminalValueScope, value: ir.Value) ?ArgReg {
    const name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if ((paramRegOrNull(function, name, .{ .int = 16 }) catch null)) |reg| return reg;
    const instruction = terminalScopeInstruction(scope, name) orelse return null;
    const cast = switch (instruction.kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (cast.op != .bitcast or !cast.from_ty.eql(.{ .int = 16 }) or !cast.to_ty.eql(.{ .int = 16 })) return null;
    return terminalI16ValueReg(function, scope, cast.value);
}

fn u16TerminalImm(value: i128) !u16 {
    if (value < 0 or value > std.math.maxInt(u16)) return error.UnsupportedCodegenValue;
    return @intCast(value);
}

fn emitGenericCfgAndConditionTrueBranch(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    cond_inst: ir.Instruction,
    true_label: []const u8,
) !bool {
    const result_name = cond_inst.result orelse return false;
    const binary = switch (cond_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (binary.op != .@"and" or !binary.ty.eql(.{ .int = 1 })) return false;
    const rhs_label = try ownedMachineLabel(allocator, machine, ".L_{s}_and_rhs", .{result_name});
    try emitGenericCfgConditionTrueBranch(allocator, machine, function, block, binary.lhs, rhs_label);
    try appendGenericCfgBlockLabel(allocator, machine, rhs_label);
    try emitGenericCfgConditionTrueBranch(allocator, machine, function, block, binary.rhs, true_label);
    return true;
}

pub fn emitGenericCfgConditionTrueBranch(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    cond: ir.Value,
    true_label: []const u8,
) !void {
    const cond_name = switch (cond) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    if (paramRegOrNull(function, cond_name, .{ .int = 1 }) catch null) |reg| {
        try appendGenericCfgCompareParamZero(allocator, machine, reg);
        try appendGenericCfgConditionalBranch(allocator, machine, .jne, true_label);
        return;
    }
    const cond_inst = findInstruction(block, cond_name) orelse return error.UnsupportedCodegenValue;
    const icmp = switch (cond_inst.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!genericCfgSupportsSingleBlockIcmp(function, null, icmp)) return error.UnsupportedCodegenValue;
    const branch_kind = try emitGenericCfgIcmpCondition(allocator, machine, function, icmp);
    try appendGenericCfgConditionalBranch(allocator, machine, branch_kind, true_label);
}

pub fn emitGenericCfgTerminalReturnBlock(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    entry: ir.BasicBlock,
    block: ir.BasicBlock,
) !void {
    try emitGenericCfgTerminalReturnBlockInScope(allocator, machine, function, .{ .entry = entry, .block = block });
}

pub fn emitGenericCfgTerminalReturnBlockInScope(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    scope: TerminalValueScope,
) !void {
    const ret = switch (scope.block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (function.ret_ty.eql(.{ .int = 32 })) {
        try emitGenericCfgTerminalI32ValueIntoEaxInScope(allocator, machine, function, scope, ret.value orelse return error.InvalidRet);
    } else if (function.ret_ty.eql(.{ .int = 64 })) {
        try emitGenericCfgTerminalI64ValueIntoRaxInScope(allocator, machine, function, scope, ret.value orelse return error.InvalidRet);
    } else {
        return error.UnsupportedCodegenType;
    }
    try appendGenericCfgReturn(allocator, machine);
}

pub fn emitGenericCfgTerminalI32ValueIntoEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    entry: ir.BasicBlock,
    block: ir.BasicBlock,
    value: ir.Value,
) !void {
    try emitGenericCfgTerminalI32ValueIntoEaxInScope(allocator, machine, function, .{ .entry = entry, .block = block }, value);
}

pub fn emitGenericCfgTerminalI32ValueIntoEaxInScope(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    scope: TerminalValueScope,
    value: ir.Value,
) !void {
    switch (value) {
        .int => |int| try machine.instructions.append(allocator, .{ .mov_imm_eax = try i32Value(int) }),
        .named => |name| {
            if ((paramRegOrNull(function, name, .{ .int = 32 }) catch null)) |reg| {
                try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
                return;
            }
            const instruction = terminalScopeInstruction(scope, name) orelse return error.UnsupportedCodegenValue;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (!binary.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
                    try emitGenericCfgTerminalI32ValueIntoEaxInScope(allocator, machine, function, scope, binary.lhs);
                    switch (binary.rhs) {
                        .int => |int| switch (binary.op) {
                            .add => try machine.instructions.append(allocator, .{ .add_eax_imm32 = try i32Value(int) }),
                            .sub => try machine.instructions.append(allocator, .{ .add_eax_imm32 = -try i32Value(int) }),
                            .@"and" => try machine.instructions.append(allocator, .{ .and_eax_imm32 = try i32BitPattern(int) }),
                            .@"or" => try machine.instructions.append(allocator, .{ .or_eax_imm32 = try i32BitPattern(int) }),
                            .shl, .lshr => {
                                const shift = try i32Value(int);
                                if (shift < 0 or shift > 31) return error.UnsupportedCodegenValue;
                                if (shift != 0) {
                                    if (binary.op == .shl) {
                                        try machine.instructions.append(allocator, .{ .shl_eax_imm5 = @intCast(shift) });
                                    } else {
                                        try machine.instructions.append(allocator, .{ .shr_eax_imm5 = @intCast(shift) });
                                    }
                                }
                            },
                            else => return error.UnsupportedCodegenInstruction,
                        },
                        .named => |rhs_name| {
                            if (binary.op == .shl or binary.op == .lshr) {
                                const shift = terminalScopeI32Constant(scope, .{ .named = rhs_name }) orelse return error.UnsupportedCodegenValue;
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
                            if (paramRegOrNull(function, rhs_name, .{ .int = 32 }) catch null) |rhs_reg| {
                                try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = op, .reg = rhs_reg } });
                                return;
                            }
                            if (op != .add) return error.UnsupportedCodegenInstruction;
                            const rhs_instruction = terminalScopeInstruction(scope, rhs_name) orelse return error.UnsupportedCodegenValue;
                            switch (rhs_instruction.kind) {
                                .load => {
                                    try emitGenericCfgTerminalI32ValueIntoEaxInScope(allocator, machine, function, scope, binary.rhs);
                                    try emitGenericCfgI32AddValueToEax(allocator, machine, function, scope.block, binary.lhs);
                                },
                                else => return error.UnsupportedCodegenInstruction,
                            }
                        },
                        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
                    }
                },
                .cast => |cast| {
                    if (!cast.to_ty.eql(.{ .int = 32 })) {
                        return error.UnsupportedCodegenInstruction;
                    }
                    switch (cast.op) {
                        .trunc => {
                            if (!cast.from_ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenInstruction;
                            try emitGenericCfgTerminalI64ValueIntoRaxInScope(allocator, machine, function, scope, cast.value);
                        },
                        .zext => {
                            const bits = switch (cast.from_ty) {
                                .int => |bits| bits,
                                else => return error.UnsupportedCodegenType,
                            };
                            if (bits > 32) return error.UnsupportedCodegenType;
                            try emitGenericCfgTerminalIntBitsValueIntoEax(allocator, machine, function, scope, cast.value, bits);
                            if (try zextMaskI32(bits)) |mask| try machine.instructions.append(allocator, .{ .and_eax_imm32 = mask });
                        },
                        .bitcast => {
                            if (!cast.from_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
                            try emitGenericCfgTerminalI32ValueIntoEaxInScope(allocator, machine, function, scope, cast.value);
                        },
                        else => return error.UnsupportedCodegenInstruction,
                    }
                },
                else => try emitGenericCfgI32ValueIntoEax(allocator, machine, function, scope.block, value),
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

fn emitGenericCfgTerminalIntBitsValueIntoEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    scope: TerminalValueScope,
    value: ir.Value,
    bits: u16,
) anyerror!void {
    if (bits == 0 or bits > 32) return error.UnsupportedCodegenType;
    if (bits == 32) return emitGenericCfgTerminalI32ValueIntoEaxInScope(allocator, machine, function, scope, value);
    switch (value) {
        .int => |int| {
            if (!intFitsUnsignedBits(int, bits)) return error.UnsupportedCodegenValue;
            try machine.instructions.append(allocator, .{ .mov_imm_eax = @intCast(int) });
        },
        .named => |name| {
            if ((paramRegOrNull(function, name, .{ .int = bits }) catch null)) |reg| {
                try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
                return;
            }
            const instruction = terminalScopeInstruction(scope, name) orelse return error.UnsupportedCodegenValue;
            const cast = switch (instruction.kind) {
                .cast => |cast| cast,
                else => return error.UnsupportedCodegenInstruction,
            };
            if (cast.op != .bitcast or !cast.to_ty.eql(.{ .int = bits }) or !cast.from_ty.eql(.{ .int = bits })) {
                return error.UnsupportedCodegenInstruction;
            }
            try emitGenericCfgTerminalIntBitsValueIntoEax(allocator, machine, function, scope, cast.value, bits);
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

fn terminalScopeI32Constant(scope: TerminalValueScope, value: ir.Value) ?i64 {
    switch (value) {
        .int => |int| return i64Value(int) catch null,
        .named => |name| {
            const instruction = terminalScopeInstruction(scope, name) orelse return null;
            return switch (instruction.kind) {
                .cast => |cast| blk: {
                    switch (cast.op) {
                        .zext, .sext, .bitcast => {},
                        else => break :blk null,
                    }
                    if (!cast.to_ty.eql(.{ .int = 32 })) break :blk null;
                    switch (cast.from_ty) {
                        .int => |bits| if (bits > 32) break :blk null,
                        else => break :blk null,
                    }
                    break :blk terminalScopeI32Constant(scope, cast.value);
                },
                else => null,
            };
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    }
}

fn terminalScopeI64Constant(scope: TerminalValueScope, value: ir.Value) ?i64 {
    switch (value) {
        .int => |int| return i64Value(int) catch null,
        .named => |name| {
            const instruction = terminalScopeInstruction(scope, name) orelse return null;
            return switch (instruction.kind) {
                .cast => |cast| blk: {
                    switch (cast.op) {
                        .zext, .sext, .bitcast => {},
                        else => break :blk null,
                    }
                    if (!cast.to_ty.eql(.{ .int = 64 })) break :blk null;
                    switch (cast.from_ty) {
                        .int => |bits| if (bits > 64) break :blk null,
                        else => break :blk null,
                    }
                    break :blk terminalScopeI64Constant(scope, cast.value);
                },
                else => null,
            };
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    }
}

pub fn emitGenericCfgTerminalI64ValueIntoRax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    entry: ir.BasicBlock,
    block: ir.BasicBlock,
    value: ir.Value,
) anyerror!void {
    try emitGenericCfgTerminalI64ValueIntoRaxInScope(allocator, machine, function, .{ .entry = entry, .block = block }, value);
}

pub fn emitGenericCfgTerminalI64ValueIntoRaxInScope(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    scope: TerminalValueScope,
    value: ir.Value,
) anyerror!void {
    switch (value) {
        .int => |int| try machine.instructions.append(allocator, .{ .mov_imm_rax = try i64Value(int) }),
        .named => |name| {
            if (paramRegOrNull(function, name, .{ .int = 64 }) catch null) |reg| {
                try machine.instructions.append(allocator, .{ .mov_arg_rax = reg });
                return;
            }
            const scoped_instruction = terminalScopeInstructionWithBlock(scope, name) orelse return error.UnsupportedCodegenValue;
            switch (scoped_instruction.instruction.kind) {
                .binary => |binary| {
                    if (!binary.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
                    const rhs = switch (binary.op) {
                        .lshr, .shl => terminalScopeI64Constant(scope, binary.rhs) orelse return error.UnsupportedCodegenValue,
                        else => switch (binary.rhs) {
                            .int => |int| try i64Value(int),
                            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
                        },
                    };
                    try emitGenericCfgTerminalI64ValueIntoRaxInScope(allocator, machine, function, scope, binary.lhs);
                    switch (binary.op) {
                        .add => {
                            if (rhs < 0 or rhs > 127) return error.UnsupportedCodegenValue;
                            if (rhs != 0) try machine.instructions.append(allocator, .{ .add_rax_imm8 = @intCast(rhs) });
                        },
                        .@"and" => {
                            if (rhs < std.math.minInt(i32) or rhs > std.math.maxInt(i32)) return error.UnsupportedCodegenValue;
                            try machine.instructions.append(allocator, .{ .and_eax_imm32 = @intCast(rhs) });
                        },
                        .lshr => {
                            if (rhs < 0 or rhs > 63) return error.UnsupportedCodegenValue;
                            if (rhs != 0) try machine.instructions.append(allocator, .{ .shr_rax_imm6 = @intCast(rhs) });
                        },
                        .shl => {
                            if (rhs < 0 or rhs > 63) return error.UnsupportedCodegenValue;
                            if (rhs != 0) try machine.instructions.append(allocator, .{ .shl_rax_imm6 = @intCast(rhs) });
                        },
                        else => return error.UnsupportedCodegenInstruction,
                    }
                },
                .cast => |cast| {
                    if (cast.op != .zext or !cast.to_ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenInstruction;
                    switch (cast.from_ty) {
                        .int => |bits| {
                            if (bits > 32) return error.UnsupportedCodegenType;
                            if (bits == 16) {
                                try emitGenericCfgTerminalU16ValueIntoRax(allocator, machine, function, scope, cast.value);
                                return;
                            }
                        },
                        else => return error.UnsupportedCodegenType,
                    }
                    try emitGenericCfgTerminalI32ValueIntoEaxInScope(allocator, machine, function, scope, cast.value);
                },
                .select => |select| try emitGenericCfgTerminalI64SelectIntoRax(allocator, machine, function, scope, name, select),
                .call => |call| try emitGenericCfgTerminalI64CallIntoRax(allocator, machine, function, scoped_instruction.block, call),
                .extractvalue => try emitGenericCfgTerminalSliceLengthIntoRax(allocator, machine, function, scope, value),
                else => return error.UnsupportedCodegenInstruction,
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

fn emitGenericCfgTerminalU16ValueIntoRax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    scope: TerminalValueScope,
    value: ir.Value,
) !void {
    switch (value) {
        .int => |int| try machine.instructions.append(allocator, .{ .mov_imm_rax = try u16TerminalImm(int) }),
        .named => |name| {
            if (paramRegOrNull(function, name, .{ .int = 16 }) catch null) |reg| {
                try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
                try machine.instructions.append(allocator, .{ .and_eax_imm32 = 0xffff });
                return;
            }
            const instruction = terminalScopeInstruction(scope, name) orelse return error.UnsupportedCodegenValue;
            switch (instruction.kind) {
                .select => |select| try emitGenericCfgTerminalU16SelectIntoRax(allocator, machine, function, scope, name, select),
                else => return error.UnsupportedCodegenInstruction,
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

fn emitGenericCfgTerminalU16SelectIntoRax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    scope: TerminalValueScope,
    result_name: []const u8,
    select: ir.SelectInst,
) !void {
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 16 })) return error.UnsupportedCodegenType;
    const true_value = switch (select.true_value) {
        .int => |int| try u16TerminalImm(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    const false_value = switch (select.false_value) {
        .int => |int| try u16TerminalImm(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    const cond_name = switch (select.cond) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    const cond_instruction = terminalScopeInstruction(scope, cond_name) orelse return error.UnsupportedCodegenValue;
    const icmp = switch (cond_instruction.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    const label_suffix = machine.instructions.items.len;
    const true_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_terminal_u16_select_{s}_{s}_{}_true",
        .{ scope.block.name, result_name, label_suffix },
    );
    const end_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_terminal_u16_select_{s}_{s}_{}_generic_cfg_select_end",
        .{ scope.block.name, result_name, label_suffix },
    );
    if (!try emitGenericCfgTerminalI16IcmpConditionTrueBranch(allocator, machine, function, scope, icmp, true_label)) {
        const branch_kind = try emitGenericCfgIcmpCondition(allocator, machine, function, icmp);
        try appendGenericCfgConditionalBranch(allocator, machine, branch_kind, true_label);
    }
    try machine.instructions.append(allocator, .{ .mov_imm_rax = false_value });
    try machine.instructions.append(allocator, .{ .jmp = end_label });
    try appendGenericCfgBlockLabel(allocator, machine, true_label);
    try machine.instructions.append(allocator, .{ .mov_imm_rax = true_value });
    try appendGenericCfgBlockLabel(allocator, machine, end_label);
}

fn emitGenericCfgTerminalSliceLengthIntoRax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    scope: TerminalValueScope,
    value: ir.Value,
) !void {
    const len = try pointer_slice_rows.resolveSliceLengthValue(function, scope.block, value);
    switch (len) {
        .imm => |imm| try machine.instructions.append(allocator, .{ .mov_imm_rax = imm }),
        .reg => |reg| try machine.instructions.append(allocator, .{ .mov_arg_rax = reg }),
        .materialize => |materialized| try emitGenericCfgTerminalI64ValueIntoRaxInScope(allocator, machine, function, scope, materialized),
    }
}

pub fn emitGenericCfgTerminalI64CallIntoRax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    call: ir.CallInst,
) !void {
    if (!call.ret_ty.eql(.{ .int = 64 }) or call.inline_asm != null or call.callee_value != null) {
        return error.UnsupportedCodegenInstruction;
    }
    if (!callIsFastcc(call.calling_conv)) try validateDefaultCallConv(call.calling_conv);
    const stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, call);
    try appendDirectCallWithStackArgs(allocator, machine, call.callee, call.ret_ty, stack_arg_count);
}

pub fn emitGenericCfgTerminalI64SelectIntoRax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    scope: TerminalValueScope,
    result_name: []const u8,
    select: ir.SelectInst,
) anyerror!void {
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
    const cond_name = switch (select.cond) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    const cond_instruction = terminalScopeInstruction(scope, cond_name) orelse return error.UnsupportedCodegenValue;
    const icmp = switch (cond_instruction.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    const label_suffix = machine.instructions.items.len;
    const true_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_terminal_i64_select_{s}_{s}_{}_true",
        .{ scope.block.name, result_name, label_suffix },
    );
    const end_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_terminal_i64_select_{s}_{s}_{}_generic_cfg_select_end",
        .{ scope.block.name, result_name, label_suffix },
    );
    if (!try emitGenericCfgTerminalI16IcmpConditionTrueBranch(allocator, machine, function, scope, icmp, true_label)) {
        const branch_kind = try emitGenericCfgIcmpCondition(allocator, machine, function, icmp);
        try appendGenericCfgConditionalBranch(allocator, machine, branch_kind, true_label);
    }
    try emitGenericCfgTerminalI64ValueIntoRaxInScope(allocator, machine, function, scope, select.false_value);
    try machine.instructions.append(allocator, .{ .jmp = end_label });
    try appendGenericCfgBlockLabel(allocator, machine, true_label);
    try emitGenericCfgTerminalI64ValueIntoRaxInScope(allocator, machine, function, scope, select.true_value);
    try appendGenericCfgBlockLabel(allocator, machine, end_label);
}

pub fn ownedMachineLabel(
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
