const shared = @import("core_shared.zig");
const core_cfg_emit = @import("core_cfg_emit.zig");
const core_value_support = @import("core_value_support.zig");
const core_value_emit = @import("core_value_emit.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");
const cabi_call_lowering = @import("cabi_call_lowering.zig");

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
const emitGenericCfgI32ValueIntoEax = core_value_emit.emitGenericCfgI32ValueIntoEax;
const emitGenericCfgIcmpCondition = cabi_call_lowering.emitGenericCfgIcmpCondition;
const findInstruction = cabi_call_lowering.findInstruction;
const genericCfgSupportsI32Value = core_value_support.genericCfgSupportsI32Value;
const i32Value = shared.i32Value;
const i64Value = shared.i64Value;
const isInt = shared.isInt;
const machineBinaryOp = cabi_call_lowering.machineBinaryOp;
const paramReg = cabi_abi_helpers.paramReg;
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
        return genericCfgSupportsI32Value(function, ret_value) or terminalBlockCanMaterializeI32Value(function, scope, ret_value);
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
                    if (machineBinaryOp(binary.op) == null) break :blk false;
                    break :blk terminalBlockCanMaterializeI32Value(function, scope, binary.lhs) and
                        terminalBlockCanMaterializeI32Value(function, scope, binary.rhs);
                },
                .cast => |cast| {
                    if (cast.op != .trunc or !cast.from_ty.eql(.{ .int = 64 }) or !cast.to_ty.eql(.{ .int = 32 })) break :blk false;
                    break :blk terminalBlockCanMaterializeI64Value(function, scope, cast.value);
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
                        .add, .@"and", .lshr, .shl => {},
                        else => break :blk false,
                    }
                    if (binary.rhs != .int) break :blk false;
                    break :blk terminalBlockCanMaterializeI64Value(function, scope, binary.lhs);
                },
                .cast => |cast| {
                    if (cast.op != .zext or !cast.to_ty.eql(.{ .int = 64 })) break :blk false;
                    switch (cast.from_ty) {
                        .int => |bits| if (bits > 32) break :blk false,
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
    const icmp = switch (cond_inst.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
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

fn emitGenericCfgConditionTrueBranch(
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
                            else => return error.UnsupportedCodegenInstruction,
                        },
                        .named => |rhs_name| {
                            const op = machineBinaryOp(binary.op) orelse return error.UnsupportedCodegenInstruction;
                            const rhs_reg = try paramReg(function, rhs_name, .{ .int = 32 });
                            try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = op, .reg = rhs_reg } });
                        },
                        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
                    }
                },
                .cast => |cast| {
                    if (cast.op != .trunc or !cast.from_ty.eql(.{ .int = 64 }) or !cast.to_ty.eql(.{ .int = 32 })) {
                        return error.UnsupportedCodegenInstruction;
                    }
                    try emitGenericCfgTerminalI64ValueIntoRaxInScope(allocator, machine, function, scope, cast.value);
                },
                else => try emitGenericCfgI32ValueIntoEax(allocator, machine, function, scope.block, value),
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
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
                    const rhs = switch (binary.rhs) {
                        .int => |int| try i64Value(int),
                        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
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
                        .int => |bits| if (bits > 32) return error.UnsupportedCodegenType,
                        else => return error.UnsupportedCodegenType,
                    }
                    try emitGenericCfgTerminalI32ValueIntoEaxInScope(allocator, machine, function, scope, cast.value);
                },
                .select => |select| try emitGenericCfgTerminalI64SelectIntoRax(allocator, machine, function, scope.entry, scope.block, name, select),
                .call => |call| try emitGenericCfgTerminalI64CallIntoRax(allocator, machine, function, scoped_instruction.block, call),
                else => return error.UnsupportedCodegenInstruction,
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
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
    entry: ir.BasicBlock,
    block: ir.BasicBlock,
    result_name: []const u8,
    select: ir.SelectInst,
) anyerror!void {
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
    const cond_name = switch (select.cond) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    const cond_instruction = terminalScopeInstruction(.{ .entry = entry, .block = block }, cond_name) orelse return error.UnsupportedCodegenValue;
    const icmp = switch (cond_instruction.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    const label_suffix = machine.instructions.items.len;
    const true_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_terminal_i64_select_{s}_{s}_{}_true",
        .{ block.name, result_name, label_suffix },
    );
    const end_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_terminal_i64_select_{s}_{s}_{}_end",
        .{ block.name, result_name, label_suffix },
    );
    const branch_kind = try emitGenericCfgIcmpCondition(allocator, machine, function, icmp);
    try appendGenericCfgConditionalBranch(allocator, machine, branch_kind, true_label);
    try emitGenericCfgTerminalI64ValueIntoRax(allocator, machine, function, entry, block, select.false_value);
    try machine.instructions.append(allocator, .{ .jmp = end_label });
    try appendGenericCfgBlockLabel(allocator, machine, true_label);
    try emitGenericCfgTerminalI64ValueIntoRax(allocator, machine, function, entry, block, select.true_value);
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
