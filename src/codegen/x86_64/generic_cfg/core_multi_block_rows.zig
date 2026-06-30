const shared = @import("core_shared.zig");
const core_cfg_emit = @import("core_cfg_emit.zig");
const core_loop_rows = @import("core_loop_rows.zig");
const core_value_support = @import("core_value_support.zig");
const core_value_emit = @import("core_value_emit.zig");
const core_memory_lowering = @import("core_memory_lowering.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");
const cabi_call_lowering = @import("cabi_call_lowering.zig");
const error_union_rows = @import("error_union_rows.zig");
const pointer_slice_rows = @import("pointer_slice_rows.zig");
const aggregate_rows = @import("aggregate_rows.zig");
const terminal_values = @import("terminal_values.zig");

const std = shared.std;
const ir = shared.ir;
const MachineFunction = shared.MachineFunction;
const MachineBinaryOp = shared.MachineBinaryOp;
const ArgReg = shared.ArgReg;

const appendAlignedDirectCall = shared.appendAlignedDirectCall;
const appendDirectCallWithStackArgs = shared.appendDirectCallWithStackArgs;
const appendStackFrame = shared.appendStackFrame;
const appendStackFrameEnd = shared.appendStackFrameEnd;
const appendGenericCfgBlockLabel = core_cfg_emit.appendGenericCfgBlockLabel;
const appendGenericCfgConditionalBranch = core_cfg_emit.appendGenericCfgConditionalBranch;
const appendGenericCfgI32Zero = core_cfg_emit.appendGenericCfgI32Zero;
const appendGenericCfgAccumulatorAdd = core_cfg_emit.appendGenericCfgAccumulatorAdd;
const appendGenericCfgAccumulatorIncrement = core_cfg_emit.appendGenericCfgAccumulatorIncrement;
const appendGenericCfgCompareParamZero = core_cfg_emit.appendGenericCfgCompareParamZero;
const appendGenericCfgCompareLocalImm = core_cfg_emit.appendGenericCfgCompareLocalImm;
const appendGenericCfgCompareLocalParam = core_cfg_emit.appendGenericCfgCompareLocalParam;
const appendGenericCfgReturn = core_cfg_emit.appendGenericCfgReturn;
const appendPanicCall = shared.appendPanicCall;
const appendMoveImmToArgReg = shared.appendMoveImmToArgReg;
const callIsFastcc = shared.callIsFastcc;
const emitGenericCfgLoadI32IntoEax = core_value_emit.emitGenericCfgLoadI32IntoEax;
const emitGenericCfgIcmpCondition = cabi_call_lowering.emitGenericCfgIcmpCondition;
const findInstruction = cabi_call_lowering.findInstruction;
const globalSymbolName = shared.globalSymbolName;
const globalSymbolNameFromValue = shared.globalSymbolNameFromValue;
const i32Value = shared.i32Value;
const i64Value = shared.i64Value;
const isCalleeName = shared.isCalleeName;
const isInt = shared.isInt;
const isNamed = shared.isNamed;
const machineBinaryOp = cabi_call_lowering.machineBinaryOp;
const appendSysVScalarCallArgsWithBlock = cabi_call_lowering.appendSysVScalarCallArgsWithBlock;
const phiHasIncoming = cabi_call_lowering.phiHasIncoming;
const phiHasIncomingInt = cabi_call_lowering.phiHasIncomingInt;
const paramReg = cabi_abi_helpers.paramReg;
const paramRegOrNull = cabi_abi_helpers.paramRegOrNull;
const paramValueReg = cabi_abi_helpers.paramValueReg;
const blockIndex = cabi_abi_helpers.blockIndex;
const validateDefaultCallConv = shared.validateDefaultCallConv;

pub const GenericCfgLoopSumPlan = core_loop_rows.GenericCfgLoopSumPlan;
const genericCfgSupportsBranchIcmp = core_value_support.genericCfgSupportsBranchIcmp;
const genericCfgSupportsPointerNullIcmp = core_value_support.genericCfgSupportsPointerNullIcmp;
const genericCfgSupportsI32Value = core_value_support.genericCfgSupportsI32Value;

pub const lowerGenericCfgLoopTryReturn = error_union_rows.lowerGenericCfgLoopTryReturn;
pub const lowerGenericCfgLinearErrorUnionTryChainReturn = error_union_rows.lowerGenericCfgLinearErrorUnionTryChainReturn;
pub const lowerGenericCfgErrorUnionTryRewrapErrorReturn = error_union_rows.lowerGenericCfgErrorUnionTryRewrapErrorReturn;
pub const lowerGenericCfgErrorUnionTrySlotUpdateReturn = error_union_rows.lowerGenericCfgErrorUnionTrySlotUpdateReturn;
pub const lowerGenericCfgStructBranchUpdateReturn = aggregate_rows.lowerGenericCfgStructBranchUpdateReturn;
pub const genericCfgStructFieldZeroUpdateAdd = aggregate_rows.genericCfgStructFieldZeroUpdateAdd;
pub const genericCfgStructFieldZeroMergeReturn = aggregate_rows.genericCfgStructFieldZeroMergeReturn;
pub const emitGenericCfgStructFieldZeroUpdatePath = aggregate_rows.emitGenericCfgStructFieldZeroUpdatePath;
const terminalCondParamReg = terminal_values.terminalCondParamReg;
const genericCfgTerminalBranchExtraBlocksAreUnreachable = terminal_values.genericCfgTerminalBranchExtraBlocksAreUnreachable;
const singleBrTarget = terminal_values.singleBrTarget;
const blockIsUnreachable = terminal_values.blockIsUnreachable;
const blockHasCondbr = terminal_values.blockHasCondbr;
const linearTerminalBranchUsesAllBlocks = terminal_values.linearTerminalBranchUsesAllBlocks;
const genericCfgSupportsTerminalReturnBlock = terminal_values.genericCfgSupportsTerminalReturnBlock;
const genericCfgSupportsNestedTerminalReturnBlock = terminal_values.genericCfgSupportsNestedTerminalReturnBlock;
const emitGenericCfgTerminalConditionTrueBranch = terminal_values.emitGenericCfgTerminalConditionTrueBranch;
const emitGenericCfgTerminalReturnBlock = terminal_values.emitGenericCfgTerminalReturnBlock;
const emitGenericCfgTerminalReturnBlockInScope = terminal_values.emitGenericCfgTerminalReturnBlockInScope;
const emitGenericCfgTerminalI32ValueIntoEax = terminal_values.emitGenericCfgTerminalI32ValueIntoEax;
const emitGenericCfgTerminalI64ValueIntoRax = terminal_values.emitGenericCfgTerminalI64ValueIntoRax;
const ownedMachineLabel = terminal_values.ownedMachineLabel;

fn validateAssumeColdCall(instruction: ir.Instruction) !void {
    if (instruction.removed) return error.UnsupportedCodegenInstruction;
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!std.mem.eql(u8, call.callee, "llvm.assume")) return error.UnsupportedCodegenInstruction;
    if (call.ret_ty != .void or call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 1 }) or !isInt(call.args.items[0].value, 1)) return error.UnsupportedCodegenValue;
}

fn blockByName(function: ir.Function, name: []const u8) ?ir.BasicBlock {
    for (function.blocks.items) |block| {
        if (std.mem.eql(u8, block.name, name)) return block;
    }
    return null;
}

pub fn lowerGenericCfgOptionalPointerUnwrapReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = genericCfgOptionalPointerUnwrapPlan(function) orelse return false;
    const load_label = "generic_cfg_optional_unwrap_load";
    const null_label = "generic_cfg_optional_unwrap_null";
    try emitGenericCfgConditionTrueBranch(allocator, machine, function, plan.entry, plan.entry_cond, if (plan.true_is_ptr) load_label else null_label);
    if (plan.true_is_ptr) {
        try emitGenericCfgOptionalPointerUnwrapNullPath(allocator, machine, function, plan);
        try appendGenericCfgBlockLabel(allocator, machine, load_label);
        try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = plan.ptr_reg });
        try appendGenericCfgReturn(allocator, machine);
    } else {
        try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = plan.ptr_reg });
        try appendGenericCfgReturn(allocator, machine);
        try appendGenericCfgBlockLabel(allocator, machine, null_label);
        try emitGenericCfgOptionalPointerUnwrapNullPath(allocator, machine, function, plan);
    }
    return true;
}

pub fn lowerGenericCfgOptionalPointerReturn(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.blocks.items.len != 3) return false;
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 1) return false;
    const cond_result = entry.instructions.items[0].result orelse return false;
    const icmp = switch (entry.instructions.items[0].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (!genericCfgSupportsPointerNullIcmp(function, icmp)) return false;
    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, cond_result)) return false;

    const then_block = function.blocks.items[blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget];
    const else_block = function.blocks.items[blockIndex(function, condbr.else_target) orelse return error.InvalidBranchTarget];
    const then_is_merge = genericCfgOptionalPointerMergeValue(then_block, entry.name) != null;
    const else_is_merge = genericCfgOptionalPointerMergeValue(else_block, entry.name) != null;
    if (then_is_merge == else_is_merge) return false;
    const merge_block = if (then_is_merge) then_block else else_block;
    const load_block = if (then_is_merge) else_block else then_block;
    const null_value = genericCfgOptionalPointerMergeValue(merge_block, entry.name) orelse return false;
    const load_value = genericCfgOptionalPointerLoadValue(function, load_block, merge_block.name) orelse return false;
    if (!genericCfgOptionalPointerMergeHasIncoming(merge_block, load_block.name, load_value)) return false;

    const branch_kind = try emitGenericCfgIcmpCondition(allocator, machine, function, icmp);
    if (then_is_merge) {
        const null_label = "generic_cfg_optional_pointer_null";
        try appendGenericCfgConditionalBranch(allocator, machine, branch_kind, null_label);
        try emitGenericCfgI32ValueIntoEax(allocator, machine, function, load_block, load_value);
        try appendGenericCfgReturn(allocator, machine);
        try appendGenericCfgBlockLabel(allocator, machine, null_label);
        try emitGenericCfgI32ValueIntoEax(allocator, machine, function, merge_block, null_value);
        try appendGenericCfgReturn(allocator, machine);
    } else {
        const load_label = "generic_cfg_optional_pointer_load";
        try appendGenericCfgConditionalBranch(allocator, machine, branch_kind, load_label);
        try emitGenericCfgI32ValueIntoEax(allocator, machine, function, merge_block, null_value);
        try appendGenericCfgReturn(allocator, machine);
        try appendGenericCfgBlockLabel(allocator, machine, load_label);
        try emitGenericCfgI32ValueIntoEax(allocator, machine, function, load_block, load_value);
        try appendGenericCfgReturn(allocator, machine);
    }
    return true;
}

const GenericCfgOptionalPointerUnwrapPlan = struct {
    entry: ir.BasicBlock,
    entry_cond: ir.Value,
    true_is_ptr: bool,
    ptr_reg: ArgReg,
    panic_block: ?ir.BasicBlock,
};

fn genericCfgOptionalPointerUnwrapPlan(function: ir.Function) ?GenericCfgOptionalPointerUnwrapPlan {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len < 2) return null;
    if (!function.params.items[0].ty.eql(.{ .int = 1 }) or !function.params.items[1].ty.eql(.ptr)) return null;
    if (function.blocks.items.len != 4 and function.blocks.items.len != 6) return null;
    const entry = function.blocks.items[0];
    const condbr = switch (entry.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const then_block = blockByName(function, condbr.then_target) orelse return null;
    const else_block = blockByName(function, condbr.else_target) orelse return null;
    const then_target = singleBrTarget(then_block) orelse return null;
    const else_target = singleBrTarget(else_block) orelse return null;
    if (!std.mem.eql(u8, then_target, else_target)) return null;
    const merge_block = blockByName(function, then_target) orelse return null;
    if (merge_block.instructions.items.len < 2) return null;
    const phi_name = merge_block.instructions.items[0].result orelse return null;
    const phi = switch (merge_block.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return null,
    };
    if (!phi.ty.eql(.ptr) or phi.incoming.items.len != 2) return null;

    var ptr_block: ?[]const u8 = null;
    var ptr_reg: ?ArgReg = null;
    var null_block: ?[]const u8 = null;
    for (phi.incoming.items) |incoming| {
        if (incoming.value == .null_value) {
            null_block = incoming.block;
            continue;
        }
        const reg = paramRegOrNull(function, switch (incoming.value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
        }, .ptr) catch return null;
        ptr_reg = reg orelse return null;
        ptr_block = incoming.block;
    }
    const ptr_block_name = ptr_block orelse return null;
    _ = null_block orelse return null;
    const true_is_ptr = std.mem.eql(u8, condbr.then_target, ptr_block_name);
    if (!true_is_ptr and !std.mem.eql(u8, condbr.else_target, ptr_block_name)) return null;

    if (function.blocks.items.len == 4) {
        const load_name = merge_block.instructions.items[1].result orelse return null;
        const load = switch (merge_block.instructions.items[1].kind) {
            .load => |load| load,
            else => return null,
        };
        if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier() or !isNamed(load.ptr, phi_name)) return null;
        const ret = switch (merge_block.terminator orelse return null) {
            .ret => |ret| ret,
            else => return null,
        };
        if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return null, load_name)) return null;
        return .{ .entry = entry, .entry_cond = condbr.cond, .true_is_ptr = true_is_ptr, .ptr_reg = ptr_reg orelse return null, .panic_block = null };
    }

    const icmp_name = merge_block.instructions.items[1].result orelse return null;
    const icmp = switch (merge_block.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (icmp.predicate != .ne or !icmp.operand_ty.eql(.ptr) or !isNamed(icmp.lhs, phi_name) or icmp.rhs != .null_value) return null;
    const guard = switch (merge_block.terminator orelse return null) {
        .condbr => |guard| guard,
        else => return null,
    };
    if (!guard.cond_ty.eql(.{ .int = 1 }) or !isNamed(guard.cond, icmp_name)) return null;
    const cont_block = blockByName(function, guard.then_target) orelse return null;
    const panic_block = blockByName(function, guard.else_target) orelse return null;
    if (!genericCfgOptionalPointerUnwrapContReturn(cont_block, phi_name)) return null;
    if (!genericCfgNoreturnBlock(panic_block)) return null;
    return .{ .entry = entry, .entry_cond = condbr.cond, .true_is_ptr = true_is_ptr, .ptr_reg = ptr_reg orelse return null, .panic_block = panic_block };
}

fn genericCfgOptionalPointerUnwrapContReturn(block: ir.BasicBlock, phi_name: []const u8) bool {
    if (block.instructions.items.len != 1) return false;
    const load_name = block.instructions.items[0].result orelse return false;
    const load = switch (block.instructions.items[0].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier() or !isNamed(load.ptr, phi_name)) return false;
    const ret = switch (block.terminator orelse return false) {
        .ret => |ret| ret,
        else => return false,
    };
    return ret.ty.eql(.{ .int = 32 }) and isNamed(ret.value orelse return false, load_name);
}

fn genericCfgNoreturnBlock(block: ir.BasicBlock) bool {
    if (block.instructions.items.len == 0 or block.instructions.items.len > 2) return false;
    const call_index: usize = if (block.instructions.items.len == 2) 1 else 0;
    const call = switch (block.instructions.items[call_index].kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null or call.inline_asm != null or call.ret_ty != .void) return false;
    if (call.args.items.len != 0) return false;
    switch (block.terminator orelse return false) {
        .@"unreachable" => return true,
        else => return false,
    }
}

fn emitGenericCfgOptionalPointerUnwrapNullPath(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    plan: GenericCfgOptionalPointerUnwrapPlan,
) !void {
    if (plan.panic_block) |panic_block| {
        try emitGenericCfgNoreturnCallBlock(allocator, machine, function, panic_block);
    } else {
        try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
        try appendGenericCfgReturn(allocator, machine);
    }
}

pub fn lowerGenericCfgGuardReturnNoreturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.blocks.items.len == 5) return try lowerGenericCfgGuardReturnBoundsThenNoreturn(allocator, machine, function);
    if (function.blocks.items.len != 3) return false;
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 0) return false;
    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 })) return false;
    const cond_reg = paramValueReg(function, condbr.cond, .{ .int = 1 }) catch return false;

    const then_block = blockByName(function, condbr.then_target) orelse return false;
    const else_block = blockByName(function, condbr.else_target) orelse return false;
    const then_ret = genericCfgConstI32Return(then_block);
    const else_ret = genericCfgConstI32Return(else_block);
    if (then_ret == null and else_ret == null) return false;
    const ret_block = if (then_ret != null) then_block else else_block;
    const panic_block = if (then_ret != null) else_block else then_block;
    const ret_value = then_ret orelse else_ret.?;

    _ = validateNoreturnSliceRuntimeCall(panic_block) catch return false;
    try machine.instructions.append(allocator, .{ .test_arg8 = cond_reg });
    if (then_ret != null) {
        try appendGenericCfgConditionalBranch(allocator, machine, .jne, ret_block.name);
    } else {
        try appendGenericCfgConditionalBranch(allocator, machine, .je, ret_block.name);
    }
    try appendGenericCfgBlockLabel(allocator, machine, panic_block.name);
    try emitGenericCfgNoreturnCallBlock(allocator, machine, function, panic_block);
    try appendGenericCfgBlockLabel(allocator, machine, ret_block.name);
    try machine.instructions.append(allocator, .{ .mov_imm_eax = ret_value });
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

fn lowerGenericCfgGuardReturnBoundsThenNoreturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 0) return false;
    const entry_condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_condbr.cond_ty.eql(.{ .int = 1 })) return false;
    const cond_reg = paramValueReg(function, entry_condbr.cond, .{ .int = 1 }) catch return false;

    const then_block = blockByName(function, entry_condbr.then_target) orelse return false;
    const else_block = blockByName(function, entry_condbr.else_target) orelse return false;
    const then_ret = genericCfgConstI32Return(then_block);
    const else_ret = genericCfgConstI32Return(else_block);
    if (then_ret == null and else_ret == null) return false;
    const ret_block = if (then_ret != null) then_block else else_block;
    const guard_block = if (then_ret != null) else_block else then_block;
    const ret_value = then_ret orelse else_ret.?;

    const guard = try genericCfgBoundsGuard(function, guard_block);
    const panic_block = blockByName(function, guard.panic_target) orelse return false;
    const cont_block = blockByName(function, guard.cont_target) orelse return false;
    _ = validateNoreturnSliceRuntimeCall(cont_block) catch return false;
    try validateI64NoreturnCallBlock(panic_block);

    try machine.instructions.append(allocator, .{ .test_arg8 = cond_reg });
    if (then_ret != null) {
        try appendGenericCfgConditionalBranch(allocator, machine, .jne, ret_block.name);
    } else {
        try appendGenericCfgConditionalBranch(allocator, machine, .je, ret_block.name);
    }

    try appendGenericCfgBlockLabel(allocator, machine, guard_block.name);
    try emitI64ValueIntoArgReg(allocator, machine, function, guard_block, .rdi, guard.len_value);
    try machine.instructions.append(allocator, .{ .cmp_arg64_imm64 = .{ .reg = .rdi, .imm = guard.max_value + 1 } });
    try appendGenericCfgConditionalBranch(allocator, machine, .jae, panic_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, cont_block.name);
    try emitGenericCfgNoreturnCallBlock(allocator, machine, function, cont_block);

    try appendGenericCfgBlockLabel(allocator, machine, panic_block.name);
    try emitI64ValueIntoArgReg(allocator, machine, function, guard_block, .rdi, guard.len_value);
    try appendMoveImmToArgReg(allocator, machine, .rsi, guard.max_value);
    try emitValidatedI64NoreturnCallBlock(allocator, machine, panic_block);

    try appendGenericCfgBlockLabel(allocator, machine, ret_block.name);
    try machine.instructions.append(allocator, .{ .mov_imm_eax = ret_value });
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

const GenericCfgBoundsGuard = struct {
    len_value: ir.Value,
    max_value: i64,
    cont_target: []const u8,
    panic_target: []const u8,
};

fn genericCfgBoundsGuard(function: ir.Function, block: ir.BasicBlock) !GenericCfgBoundsGuard {
    if (block.instructions.items.len == 0) return error.UnsupportedCodegenControlFlow;
    const condbr = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 })) return error.UnsupportedCodegenControlFlow;
    const icmp_name = switch (condbr.cond) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    const instruction = findInstructionInFunction(function, block, icmp_name) orelse return error.UnsupportedCodegenInstruction;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (icmp.predicate != .ule or !icmp.operand_ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenInstruction;
    const max_value = switch (icmp.rhs) {
        .int => |int| try i64Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    if (max_value == std.math.maxInt(i64)) return error.UnsupportedCodegenValue;
    return .{
        .len_value = icmp.lhs,
        .max_value = max_value,
        .cont_target = condbr.then_target,
        .panic_target = condbr.else_target,
    };
}

fn validateI64NoreturnCallBlock(block: ir.BasicBlock) !void {
    if (block.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    const call = switch (block.instructions.items[0].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (call.callee_value != null or call.inline_asm != null or call.ret_ty != .void) return error.UnsupportedCodegenInstruction;
    if (!callIsFastcc(call.calling_conv)) try validateDefaultCallConv(call.calling_conv);
    if (call.args.items.len != 2) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 64 }) or !call.args.items[1].ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
    switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .@"unreachable" => {},
        else => return error.UnsupportedCodegenControlFlow,
    }
}

fn emitValidatedI64NoreturnCallBlock(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    block: ir.BasicBlock,
) !void {
    try validateI64NoreturnCallBlock(block);
    const call = switch (block.instructions.items[0].kind) {
        .call => |call| call,
        else => unreachable,
    };
    try appendAlignedDirectCall(allocator, machine, call.callee, .void);
    try machine.instructions.append(allocator, .ud2);
}

fn emitValidatedI64NoreturnCallBlockWithArgs(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    entry: ir.BasicBlock,
    block: ir.BasicBlock,
) !void {
    try validateI64NoreturnCallBlock(block);
    const call = switch (block.instructions.items[0].kind) {
        .call => |call| call,
        else => unreachable,
    };
    const first = call.args.items[0].value;
    const second = call.args.items[1].value;
    if (directI64ParamReg(function, first) == .rsi or directI64ParamReg(function, second) == .rdi) {
        return error.UnsupportedCodegenAbi;
    }
    try emitI64ValueIntoArgReg(allocator, machine, function, entry, .rdi, first);
    try emitI64ValueIntoArgReg(allocator, machine, function, entry, .rsi, second);
    try appendAlignedDirectCall(allocator, machine, call.callee, .void);
    try machine.instructions.append(allocator, .ud2);
}

fn directI64ParamReg(function: ir.Function, value: ir.Value) ?ArgReg {
    const name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    return paramRegOrNull(function, name, .{ .int = 64 }) catch null;
}

fn genericCfgConstI32Return(block: ir.BasicBlock) ?i32 {
    if (block.instructions.items.len != 0) return null;
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return null;
    const value = switch (ret.value orelse return null) {
        .int => |int| int,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    return i32Value(value) catch null;
}

pub fn lowerGenericCfgGuardedDynamicPointerLoadReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 3) return false;
    if (!function.params.items[0].ty.eql(.ptr) or
        !function.params.items[1].ty.eql(.{ .int = 64 }) or
        !function.params.items[2].ty.eql(.{ .int = 64 })) return false;
    if (function.blocks.items.len != 3) return false;

    const entry = function.blocks.items[0];
    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 })) return false;
    const cond_name = switch (condbr.cond) {
        .named => |name| name,
        else => return false,
    };
    const cond_instruction = findInstruction(entry, cond_name) orelse return false;
    const icmp = switch (cond_instruction.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .uge or !icmp.operand_ty.eql(.{ .int = 64 })) return false;

    const true_block = blockByName(function, condbr.then_target) orelse return false;
    const false_block = blockByName(function, condbr.else_target) orelse return false;
    const true_const = genericCfgConstantI32Return(true_block);
    const false_const = genericCfgConstantI32Return(false_block);
    if ((true_const == null) == (false_const == null)) return false;
    const const_block = if (true_const != null) true_block else false_block;
    const load_block = if (true_const != null) false_block else true_block;
    const const_value = true_const orelse false_const orelse return false;

    const address = core_memory_lowering.genericCfgDynamicI32LoadReturnAddress(function, entry, load_block) orelse return false;
    const lhs_reg = genericCfgI64ParamRegThroughIdentityCast(function, entry, icmp.lhs) orelse return false;
    const rhs_reg = genericCfgI64ParamRegThroughIdentityCast(function, entry, icmp.rhs) orelse return false;
    if ((address.index_reg orelse return false) != lhs_reg) return false;

    try emitGenericCfgUgeI64ParamCondition(allocator, machine, lhs_reg, rhs_reg);
    const branch_to_const = true_const != null;
    if (branch_to_const) {
        try appendGenericCfgConditionalBranch(allocator, machine, .jae, const_block.name);
        try core_memory_lowering.emitGenericCfgDynamicI32LoadIntoEax(allocator, machine, address);
        try appendGenericCfgReturn(allocator, machine);
        try appendGenericCfgBlockLabel(allocator, machine, const_block.name);
        try machine.instructions.append(allocator, .{ .mov_imm_eax = const_value });
        try appendGenericCfgReturn(allocator, machine);
    } else {
        try appendGenericCfgConditionalBranch(allocator, machine, .jae, load_block.name);
        try machine.instructions.append(allocator, .{ .mov_imm_eax = const_value });
        try appendGenericCfgReturn(allocator, machine);
        try appendGenericCfgBlockLabel(allocator, machine, load_block.name);
        try core_memory_lowering.emitGenericCfgDynamicI32LoadIntoEax(allocator, machine, address);
        try appendGenericCfgReturn(allocator, machine);
    }
    return true;
}

pub fn lowerGenericCfgGuardedDynamicPointerLoadPanicReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 3) return false;
    if (!function.params.items[0].ty.eql(.ptr) or
        !function.params.items[1].ty.eql(.{ .int = 64 }) or
        !function.params.items[2].ty.eql(.{ .int = 64 })) return false;
    if (function.blocks.items.len != 3) return false;

    const entry = function.blocks.items[0];
    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 })) return false;
    const cond_name = switch (condbr.cond) {
        .named => |name| name,
        else => return false,
    };
    const cond_instruction = findInstruction(entry, cond_name) orelse return false;
    const icmp = switch (cond_instruction.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    switch (icmp.predicate) {
        .uge, .ult => {},
        else => return false,
    }
    if (!icmp.operand_ty.eql(.{ .int = 64 })) return false;

    const true_block = blockByName(function, condbr.then_target) orelse return false;
    const false_block = blockByName(function, condbr.else_target) orelse return false;
    const true_panic = if (validateNoreturnSliceRuntimeCall(true_block)) |_| true else |_| if (validateI64NoreturnCallBlock(true_block)) |_| true else |_| false;
    const false_panic = if (validateNoreturnSliceRuntimeCall(false_block)) |_| true else |_| if (validateI64NoreturnCallBlock(false_block)) |_| true else |_| false;
    if (true_panic == false_panic) return false;
    const panic_block = if (true_panic) true_block else false_block;
    const load_block = if (true_panic) false_block else true_block;

    const width = core_memory_lowering.GenericCfgScalarWidth.fromType(function.ret_ty) orelse return false;
    const address = core_memory_lowering.genericCfgTypedScalarLoadReturnAddressAcrossBlocks(function, entry, load_block, width) orelse return false;
    const lhs_reg = genericCfgI64ParamRegThroughIdentityCast(function, entry, icmp.lhs) orelse return false;
    if (address.add_index_reg != lhs_reg or address.sub_index_reg != null) return false;

    switch (icmp.predicate) {
        .uge => {
            try emitGenericCfgUgeI64ValueCondition(allocator, machine, function, entry, lhs_reg, icmp.rhs);
            if (true_panic) {
                try appendGenericCfgConditionalBranch(allocator, machine, .jae, panic_block.name);
                try core_memory_lowering.emitGenericCfgTypedScalarLoadIntoReturn(allocator, machine, address);
                try appendGenericCfgReturn(allocator, machine);
                try appendGenericCfgBlockLabel(allocator, machine, panic_block.name);
                try emitGenericCfgNoreturnPanicBlock(allocator, machine, function, entry, panic_block);
            } else {
                try appendGenericCfgConditionalBranch(allocator, machine, .jae, load_block.name);
                try emitGenericCfgNoreturnPanicBlock(allocator, machine, function, entry, panic_block);
                try appendGenericCfgBlockLabel(allocator, machine, load_block.name);
                try core_memory_lowering.emitGenericCfgTypedScalarLoadIntoReturn(allocator, machine, address);
                try appendGenericCfgReturn(allocator, machine);
            }
        },
        .ult => {
            try emitGenericCfgUgeI64ValueCondition(allocator, machine, function, entry, lhs_reg, icmp.rhs);
            if (true_panic) {
                try appendGenericCfgConditionalBranch(allocator, machine, .jae, load_block.name);
                try emitGenericCfgNoreturnPanicBlock(allocator, machine, function, entry, panic_block);
                try appendGenericCfgBlockLabel(allocator, machine, load_block.name);
                try core_memory_lowering.emitGenericCfgTypedScalarLoadIntoReturn(allocator, machine, address);
                try appendGenericCfgReturn(allocator, machine);
            } else {
                try appendGenericCfgConditionalBranch(allocator, machine, .jae, panic_block.name);
                try core_memory_lowering.emitGenericCfgTypedScalarLoadIntoReturn(allocator, machine, address);
                try appendGenericCfgReturn(allocator, machine);
                try appendGenericCfgBlockLabel(allocator, machine, panic_block.name);
                try emitGenericCfgNoreturnPanicBlock(allocator, machine, function, entry, panic_block);
            }
        },
        else => return false,
    }
    return true;
}

pub fn lowerGenericCfgCheckedSliceStoreLoadReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 4) return false;
    if (!function.params.items[0].ty.eql(.ptr) or
        !function.params.items[1].ty.eql(.{ .int = 64 }) or
        !function.params.items[2].ty.eql(.{ .int = 64 }) or
        !function.params.items[3].ty.eql(.{ .int = 32 })) return false;
    if (function.blocks.items.len != 5) return false;

    const entry = function.blocks.items[0];
    const first_guard = genericCfgSliceBoundsGuard(function, entry) orelse return false;
    const store_block = blockByName(function, first_guard.cont_target) orelse return false;
    const first_panic = blockByName(function, first_guard.panic_target) orelse return false;
    try validateSliceBoundsPanicBlock(function, entry, first_panic, first_guard.index_value, first_guard.len_value);

    const store_step = genericCfgCheckedSliceStoreStep(function, entry, store_block) orelse return false;
    if (!first_guard.index_value.eql(store_step.index_value)) return false;
    const second_panic = blockByName(function, store_step.guard.panic_target) orelse return false;
    const load_block = blockByName(function, store_step.guard.cont_target) orelse return false;
    try validateSliceBoundsPanicBlock(function, entry, second_panic, store_step.guard.index_value, store_step.guard.len_value);

    const load_address = genericCfgCheckedSliceReturnLoadAddress(function, entry, store_block, load_block) orelse return false;
    if (!core_memory_lowering.sameGenericCfgTypedAddress(store_step.store_address, load_address)) return false;

    const index_reg = genericCfgI64ParamRegThroughIdentityCast(function, entry, first_guard.index_value) orelse return false;
    if (store_step.store_address.add_index_reg != index_reg or store_step.store_address.sub_index_reg != null) return false;

    try core_memory_lowering.emitGenericCfgScalarValueIntoReturnReg(allocator, machine, function, store_step.store_value, .i32);
    try emitGenericCfgUgeI64ValueCondition(allocator, machine, function, entry, index_reg, first_guard.len_value);
    try appendGenericCfgConditionalBranch(allocator, machine, .jae, first_panic.name);
    try core_memory_lowering.emitGenericCfgTypedAddressIntoRcx(allocator, machine, store_step.store_address);
    try core_memory_lowering.emitGenericCfgTypedScalarStoreReturnReg(allocator, machine, .i32);

    try emitGenericCfgUgeI64ValueCondition(allocator, machine, function, entry, index_reg, store_step.guard.len_value);
    try appendGenericCfgConditionalBranch(allocator, machine, .jae, second_panic.name);
    try core_memory_lowering.emitGenericCfgTypedScalarLoadIntoReturn(allocator, machine, load_address);
    try appendGenericCfgReturn(allocator, machine);

    try appendGenericCfgBlockLabel(allocator, machine, first_panic.name);
    try emitValidatedI64NoreturnCallBlockWithArgs(allocator, machine, function, entry, first_panic);
    try appendGenericCfgBlockLabel(allocator, machine, second_panic.name);
    try emitValidatedI64NoreturnCallBlockWithArgs(allocator, machine, function, entry, second_panic);
    return true;
}

const GenericCfgSliceBoundsGuard = struct {
    index_value: ir.Value,
    len_value: ir.Value,
    cont_target: []const u8,
    panic_target: []const u8,
};

const GenericCfgCheckedSliceStoreStep = struct {
    store_address: core_memory_lowering.GenericCfgTypedAddress,
    store_value: ir.Value,
    index_value: ir.Value,
    guard: GenericCfgSliceBoundsGuard,
};

fn genericCfgSliceBoundsGuard(function: ir.Function, block: ir.BasicBlock) ?GenericCfgSliceBoundsGuard {
    const condbr = switch (block.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const cond_name = switch (condbr.cond) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const cond_inst = findInstructionInFunction(function, block, cond_name) orelse return null;
    const icmp = switch (cond_inst.kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (icmp.predicate != .ult or !icmp.operand_ty.eql(.{ .int = 64 })) return null;
    return .{
        .index_value = icmp.lhs,
        .len_value = icmp.rhs,
        .cont_target = condbr.then_target,
        .panic_target = condbr.else_target,
    };
}

fn genericCfgCheckedSliceStoreStep(
    function: ir.Function,
    entry: ir.BasicBlock,
    block: ir.BasicBlock,
) ?GenericCfgCheckedSliceStoreStep {
    const guard = genericCfgSliceBoundsGuard(function, block) orelse return null;
    var store_inst: ?ir.StoreInst = null;
    for (block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        const store = switch (instruction.kind) {
            .store => |store| store,
            else => continue,
        };
        if (store_inst != null) return null;
        store_inst = store;
    }
    const store = store_inst orelse return null;
    if (!store.ty.eql(.{ .int = 32 }) or store.attrs.isBarrier()) return null;
    const address = core_memory_lowering.genericCfgTypedScalarAddressAcrossBlocks(function, entry, block, store.ptr, .i32) orelse return null;
    return .{
        .store_address = address,
        .store_value = store.value,
        .index_value = guard.index_value,
        .guard = guard,
    };
}

fn genericCfgCheckedSliceReturnLoadAddress(
    function: ir.Function,
    entry: ir.BasicBlock,
    store_block: ir.BasicBlock,
    block: ir.BasicBlock,
) ?core_memory_lowering.GenericCfgTypedAddress {
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return null;
    const ret_name = switch (ret.value orelse return null) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const ret_inst = findInstruction(block, ret_name) orelse return null;
    const load = switch (ret_inst.kind) {
        .load => |load| load,
        else => return null,
    };
    return core_memory_lowering.genericCfgTypedScalarLoadAddressAcrossScopes(function, entry, store_block, block, load, .i32);
}

fn validateSliceBoundsPanicBlock(
    function: ir.Function,
    entry: ir.BasicBlock,
    block: ir.BasicBlock,
    index_value: ir.Value,
    len_value: ir.Value,
) !void {
    try validateI64NoreturnCallBlock(block);
    const call = switch (block.instructions.items[0].kind) {
        .call => |call| call,
        else => unreachable,
    };
    if (!call.args.items[0].value.eql(index_value) or !call.args.items[1].value.eql(len_value)) {
        return error.UnsupportedCodegenValue;
    }
    _ = genericCfgI64ParamRegThroughIdentityCast(function, entry, index_value) orelse return error.UnsupportedCodegenValue;
    if (directI64ParamReg(function, index_value) == .rsi or directI64ParamReg(function, len_value) == .rdi) {
        return error.UnsupportedCodegenAbi;
    }
}

pub fn genericCfgConstantI32Return(block: ir.BasicBlock) ?i32 {
    if (block.instructions.items.len != 0) return null;
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return null;
    return switch (ret.value orelse return null) {
        .int => |int| i32Value(int) catch null,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
    };
}

pub fn genericCfgI64ParamRegThroughIdentityCast(function: ir.Function, block: ir.BasicBlock, value: ir.Value) ?ArgReg {
    const name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (paramRegOrNull(function, name, .{ .int = 64 }) catch null) |reg| return reg;
    const instruction = findInstruction(block, name) orelse return null;
    const cast = switch (instruction.kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (cast.op != .bitcast or !cast.from_ty.eql(.{ .int = 64 }) or !cast.to_ty.eql(.{ .int = 64 })) return null;
    return genericCfgI64ParamRegThroughIdentityCast(function, block, cast.value);
}

pub fn emitGenericCfgUgeI64ParamCondition(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    lhs_reg: ArgReg,
    rhs_reg: ArgReg,
) !void {
    if (lhs_reg == .rcx) return error.UnsupportedCodegenAbi;
    try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = .rcx, .src = rhs_reg } });
    try machine.instructions.append(allocator, .{ .cmp_rcx_arg64 = lhs_reg });
}

fn emitGenericCfgUgeI64ValueCondition(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    entry: ir.BasicBlock,
    lhs_reg: ArgReg,
    rhs: ir.Value,
) !void {
    if (lhs_reg == .rcx) return error.UnsupportedCodegenAbi;
    try emitI64ValueIntoArgReg(allocator, machine, function, entry, .rcx, rhs);
    try machine.instructions.append(allocator, .{ .cmp_rcx_arg64 = lhs_reg });
}

fn emitGenericCfgNoreturnPanicBlock(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    entry: ir.BasicBlock,
    block: ir.BasicBlock,
) !void {
    if (validateI64NoreturnCallBlock(block)) |_| {
        try emitValidatedI64NoreturnCallBlockWithArgs(allocator, machine, function, entry, block);
    } else |_| {
        try emitGenericCfgNoreturnCallBlock(allocator, machine, function, block);
    }
}

pub fn genericCfgOptionalPointerMergeValue(block: ir.BasicBlock, entry_name: []const u8) ?ir.Value {
    if (block.instructions.items.len != 1) return null;
    const instruction = block.instructions.items[0];
    if (instruction.removed) return null;
    const phi_name = instruction.result orelse return null;
    const phi = switch (instruction.kind) {
        .phi => |phi| phi,
        else => return null,
    };
    if (!phi.ty.eql(.{ .int = 32 }) or phi.incoming.items.len != 2) return null;
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return null, phi_name)) return null;
    for (phi.incoming.items) |incoming| {
        if (std.mem.eql(u8, incoming.block, entry_name)) return incoming.value;
    }
    return null;
}

pub fn genericCfgOptionalPointerLoadValue(function: ir.Function, block: ir.BasicBlock, merge_name: []const u8) ?ir.Value {
    if (block.instructions.items.len == 0 or block.instructions.items.len > 2) return null;
    const load_instruction = block.instructions.items[0];
    if (load_instruction.removed) return null;
    const load_name = load_instruction.result orelse return null;
    const load = switch (load_instruction.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return null;
    const ptr_name = switch (load.ptr) {
        .named => |name| name,
        else => return null,
    };
    if ((paramRegOrNull(function, ptr_name, .ptr) catch null) == null) return null;
    if (!std.mem.eql(u8, singleBrTarget(block) orelse return null, merge_name)) return null;
    if (block.instructions.items.len == 2) {
        const add_instruction = block.instructions.items[1];
        if (add_instruction.removed) return null;
        const add_name = add_instruction.result orelse return null;
        const binary = switch (add_instruction.kind) {
            .binary => |binary| binary,
            else => return null,
        };
        if (binary.op != .add or !binary.ty.eql(.{ .int = 32 }) or !isNamed(binary.lhs, load_name)) return null;
        switch (binary.rhs) {
            .int => {},
            else => return null,
        }
        return .{ .named = add_name };
    }
    return .{ .named = load_name };
}

pub fn genericCfgOptionalPointerMergeHasIncoming(block: ir.BasicBlock, incoming_block: []const u8, expected: ir.Value) bool {
    const phi = switch (block.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    for (phi.incoming.items) |incoming| {
        if (std.mem.eql(u8, incoming.block, incoming_block)) return incoming.value.eql(expected);
    }
    return false;
}

pub fn lowerGenericCfgGuardedOptionalPointerBranchReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 32 }) or !function.params.items[1].ty.eql(.ptr)) return false;
    if (function.blocks.items.len != 6) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 1) return false;
    const outer_cond_name = entry.instructions.items[0].result orelse return false;
    const outer_icmp = switch (entry.instructions.items[0].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (!genericCfgSupportsBranchIcmp(function, outer_icmp)) return false;
    const outer_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!outer_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(outer_br.cond, outer_cond_name)) return false;

    const then_block = blockByName(function, outer_br.then_target) orelse return false;
    const else_block = blockByName(function, outer_br.else_target) orelse return false;
    if (then_block.instructions.items.len != 1) return false;
    const guard_cond_name = then_block.instructions.items[0].result orelse return false;
    const guard_icmp = switch (then_block.instructions.items[0].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (guard_icmp.predicate != .ne) return false;
    if (!genericCfgSupportsPointerNullIcmp(function, guard_icmp)) return false;
    const guard_br = switch (then_block.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!guard_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(guard_br.cond, guard_cond_name)) return false;
    const cont_block = blockByName(function, guard_br.then_target) orelse return false;
    const panic_block = blockByName(function, guard_br.else_target) orelse return false;
    if (!genericCfgGuardPanicBlock(panic_block)) return false;

    const merge_name = singleBrTarget(cont_block) orelse return false;
    if (!std.mem.eql(u8, singleBrTarget(else_block) orelse return false, merge_name)) return false;
    const merge_block = blockByName(function, merge_name) orelse return false;
    const phi_binary = genericCfgPhiBinaryReturn(merge_block) orelse return false;

    if (cont_block.instructions.items.len != 1) return false;
    const load_name = cont_block.instructions.items[0].result orelse return false;
    const load = switch (cont_block.instructions.items[0].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
    const ptr_name = switch (load.ptr) {
        .named => |name| name,
        else => return false,
    };
    if ((paramRegOrNull(function, ptr_name, .ptr) catch null) == null) return false;

    var loaded_incoming = false;
    var fallback_value: ?ir.Value = null;
    for (phi_binary.phi.incoming.items) |incoming| {
        if (std.mem.eql(u8, incoming.block, cont_block.name)) {
            if (!isNamed(incoming.value, load_name)) return false;
            loaded_incoming = true;
        } else if (std.mem.eql(u8, incoming.block, else_block.name)) {
            fallback_value = incoming.value;
        } else {
            return false;
        }
    }
    if (!loaded_incoming) return false;
    const fallback = fallback_value orelse return false;

    const outer_branch_kind = try emitGenericCfgIcmpCondition(allocator, machine, function, outer_icmp);
    try appendGenericCfgConditionalBranch(allocator, machine, outer_branch_kind, then_block.name);
    try emitGenericCfgI32ValueIntoEax(allocator, machine, function, else_block, fallback);
    try appendGenericCfgPhiBinaryImmediate(allocator, machine, phi_binary);
    try appendGenericCfgReturn(allocator, machine);

    try appendGenericCfgBlockLabel(allocator, machine, then_block.name);
    const guard_branch_kind = try emitGenericCfgIcmpCondition(allocator, machine, function, guard_icmp);
    try appendGenericCfgConditionalBranch(allocator, machine, guard_branch_kind, cont_block.name);
    try appendGenericCfgBlockLabel(allocator, machine, panic_block.name);
    const panic_call = switch (panic_block.instructions.items[0].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    try appendAlignedDirectCall(allocator, machine, panic_call.callee, .void);
    try machine.instructions.append(allocator, .ud2);

    try appendGenericCfgBlockLabel(allocator, machine, cont_block.name);
    try core_value_emit.emitGenericCfgLoadI32IntoEax(allocator, machine, function, load.ptr);
    try appendGenericCfgPhiBinaryImmediate(allocator, machine, phi_binary);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub fn genericCfgGuardPanicBlock(block: ir.BasicBlock) bool {
    if (block.instructions.items.len == 4) return genericCfgGuardSlicePanicBlock(block);
    if (block.instructions.items.len == 0 or block.instructions.items.len > 2) return false;
    var call_index: usize = 0;
    if (block.instructions.items.len == 2) {
        validateAssumeColdCall(block.instructions.items[0]) catch return false;
        call_index = 1;
    }
    const call = switch (block.instructions.items[call_index].kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.ret_ty != .void or call.callee_value != null or call.inline_asm != null) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;
    if (call.args.items.len == 2) {
        if (call.args.items[0].ty != .ptr) return false;
        if (!call.args.items[1].ty.eql(.{ .int = 64 })) return false;
        switch (call.args.items[0].value) {
            .named => {},
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
        }
        switch (call.args.items[1].value) {
            .int => |int| _ = i64Value(int) catch return false,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
        }
    } else if (call.args.items.len != 0) {
        return false;
    }
    return switch (block.terminator orelse return false) {
        .@"unreachable" => true,
        else => false,
    };
}

fn genericCfgGuardSlicePanicBlock(block: ir.BasicBlock) bool {
    validateAssumeColdCall(block.instructions.items[0]) catch return false;
    const ptr_name = block.instructions.items[1].result orelse return false;
    const len_name = block.instructions.items[2].result orelse return false;
    const ptr_extract = switch (block.instructions.items[1].kind) {
        .extractvalue => |extractvalue| extractvalue,
        else => return false,
    };
    const len_extract = switch (block.instructions.items[2].kind) {
        .extractvalue => |extractvalue| extractvalue,
        else => return false,
    };
    if (!ptr_extract.result_ty.eql(.ptr) or !std.mem.eql(u8, ptr_extract.indices, "0")) return false;
    if (!len_extract.result_ty.eql(.{ .int = 64 }) or !std.mem.eql(u8, len_extract.indices, "1")) return false;
    if (!ptr_extract.aggregate.eql(len_extract.aggregate)) return false;
    _ = globalSymbolNameFromValue(ptr_extract.aggregate) catch return false;

    const call = switch (block.instructions.items[3].kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.ret_ty != .void or call.callee_value != null or call.inline_asm != null) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;
    if (call.args.items.len != 3) return false;
    if (call.args.items[0].ty != .ptr or !isNamed(call.args.items[0].value, ptr_name)) return false;
    if (!call.args.items[1].ty.eql(.{ .int = 64 }) or !isNamed(call.args.items[1].value, len_name)) return false;
    if (call.args.items[2].ty != .ptr) return false;
    return switch (block.terminator orelse return false) {
        .@"unreachable" => true,
        else => false,
    };
}

pub fn lowerGenericCfgGuardedGlobalAddReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 32 })) return false;
    if (function.blocks.items.len != 3 and function.blocks.items.len != 5) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 1) return false;
    const guard_name = entry.instructions.items[0].result orelse return false;
    const guard_icmp = switch (entry.instructions.items[0].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (!genericCfgSupportsNegativeI32Guard(function, guard_icmp)) return false;
    const guard_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!guard_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(guard_br.cond, guard_name)) return false;

    const panic_block = blockByName(function, guard_br.then_target) orelse return false;
    const ok_block = blockByName(function, guard_br.else_target) orelse return false;

    const branch_kind = try emitGenericCfgIcmpCondition(allocator, machine, function, guard_icmp);
    if (branch_kind != .js) return false;
    try appendGenericCfgConditionalBranch(allocator, machine, branch_kind, panic_block.name);

    if (function.blocks.items.len == 3) {
        try emitGenericCfgGlobalAddOkReturn(allocator, machine, function, ok_block);
        try appendGenericCfgBlockLabel(allocator, machine, panic_block.name);
        try emitGenericCfgNoreturnCallBlock(allocator, machine, function, panic_block);
        return true;
    }

    const checked = try genericCfgCheckedGlobalAdd(ok_block);
    try emitGenericCfgGlobalLoadParamAdd(allocator, machine, function, checked.load, checked.call);
    try appendGenericCfgConditionalBranch(allocator, machine, .jo, checked.overflow_target);
    try genericCfgValidateCheckedAddRet(function, checked.ret_target, checked.call_name);
    try appendGenericCfgReturn(allocator, machine);

    try appendGenericCfgBlockLabel(allocator, machine, panic_block.name);
    try emitGenericCfgNoreturnCallBlock(allocator, machine, function, panic_block);

    const overflow_block = blockByName(function, checked.overflow_target) orelse return false;
    try appendGenericCfgBlockLabel(allocator, machine, overflow_block.name);
    try emitGenericCfgNoreturnCallBlock(allocator, machine, function, overflow_block);
    return true;
}

pub fn lowerGenericCfgStackCheckedAddReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 32 })) return false;
    if (function.blocks.items.len != 3) return false;

    const entry = function.blocks.items[0];
    const checked = genericCfgStackCheckedAdd(entry) catch |err| switch (err) {
        error.UnsupportedCodegenInstruction,
        error.UnsupportedCodegenType,
        error.UnsupportedCodegenValue,
        error.BlockWithoutTerminator,
        error.UnsupportedCodegenControlFlow,
        => return false,
    };

    const panic_block = blockByName(function, checked.overflow_target) orelse return error.InvalidBranchTarget;
    const ok_block = blockByName(function, checked.ret_target) orelse return error.InvalidBranchTarget;
    try genericCfgValidateStackCheckedAddRet(ok_block, checked.slot_name);

    try emitGenericCfgCheckedAddIntoEax(allocator, machine, function, checked.call);
    try appendGenericCfgConditionalBranch(allocator, machine, checked.branch_kind, panic_block.name);
    try appendGenericCfgReturn(allocator, machine);

    try appendGenericCfgBlockLabel(allocator, machine, panic_block.name);
    try emitGenericCfgNoreturnCallBlock(allocator, machine, function, panic_block);
    return true;
}

const GenericCfgStackCheckedAdd = struct {
    call: ir.CallInst,
    branch_kind: core_cfg_emit.GenericCfgBranchKind,
    slot_name: []const u8,
    overflow_target: []const u8,
    ret_target: []const u8,
};

fn genericCfgStackCheckedAdd(entry: ir.BasicBlock) !GenericCfgStackCheckedAdd {
    if (entry.instructions.items.len != 6) return error.UnsupportedCodegenInstruction;
    const call_name = entry.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const slot_name = entry.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    const flag_ptr_name = entry.instructions.items[3].result orelse return error.UnsupportedCodegenInstruction;
    const flag_name = entry.instructions.items[4].result orelse return error.UnsupportedCodegenInstruction;
    const cond_name = entry.instructions.items[5].result orelse return error.UnsupportedCodegenInstruction;

    const call = switch (entry.instructions.items[0].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (call.callee_value != null or call.inline_asm != null or call.args.items.len != 2) return error.UnsupportedCodegenInstruction;
    if (!call.ret_ty.eql(.{ .aggregate = "{ i32, i1 }" })) return error.UnsupportedCodegenType;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !call.args.items[1].ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
    const branch_kind: core_cfg_emit.GenericCfgBranchKind = if (isCalleeName(call.callee, "llvm.sadd.with.overflow.i32"))
        .jo
    else if (isCalleeName(call.callee, "llvm.uadd.with.overflow.i32"))
        .jc
    else
        return error.UnsupportedCodegenInstruction;

    const alloca = switch (entry.instructions.items[1].kind) {
        .alloca => |alloca| alloca,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!alloca.allocated_ty.eql(.{ .aggregate = "{ i32, i1 }" })) return error.UnsupportedCodegenType;

    const store = switch (entry.instructions.items[2].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!store.ty.eql(.{ .aggregate = "{ i32, i1 }" }) or !isNamed(store.value, call_name) or !isNamed(store.ptr, slot_name)) {
        return error.UnsupportedCodegenInstruction;
    }

    const flag_gep = switch (entry.instructions.items[3].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!flag_gep.source_ty.eql(.{ .int = 8 }) or !isNamed(flag_gep.ptr, slot_name) or flag_gep.indices.items.len != 1) {
        return error.UnsupportedCodegenInstruction;
    }
    const flag_offset = flag_gep.indices.items[0];
    if (!flag_offset.ty.eql(.{ .int = 64 }) or !isInt(flag_offset.value, 4)) return error.UnsupportedCodegenValue;

    const flag_load = switch (entry.instructions.items[4].kind) {
        .load => |load| load,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!flag_load.ty.eql(.{ .int = 1 }) or flag_load.attrs.isBarrier() or !isNamed(flag_load.ptr, flag_ptr_name)) {
        return error.UnsupportedCodegenInstruction;
    }

    const flag_cmp = switch (entry.instructions.items[5].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (flag_cmp.predicate != .ne or !flag_cmp.operand_ty.eql(.{ .int = 1 }) or
        !isNamed(flag_cmp.lhs, flag_name) or !isInt(flag_cmp.rhs, 0))
    {
        return error.UnsupportedCodegenInstruction;
    }

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, cond_name)) return error.UnsupportedCodegenValue;

    return .{
        .call = call,
        .branch_kind = branch_kind,
        .slot_name = slot_name,
        .overflow_target = condbr.then_target,
        .ret_target = condbr.else_target,
    };
}

fn genericCfgValidateStackCheckedAddRet(ok: ir.BasicBlock, slot_name: []const u8) !void {
    if (ok.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    const load_name = ok.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const load = switch (ok.instructions.items[0].kind) {
        .load => |load| load,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier() or !isNamed(load.ptr, slot_name)) return error.UnsupportedCodegenInstruction;
    const ret = switch (ok.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, load_name)) return error.UnsupportedCodegenValue;
}

fn emitGenericCfgCheckedAddIntoEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    call: ir.CallInst,
) !void {
    const lhs = call.args.items[0].value;
    const rhs = call.args.items[1].value;
    if ((paramValueReg(function, lhs, .{ .int = 32 }) catch null)) |reg| {
        try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
        try emitGenericCfgCheckedAddOperand(allocator, machine, function, rhs);
        return;
    }
    if ((paramValueReg(function, rhs, .{ .int = 32 }) catch null)) |reg| {
        try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
        try emitGenericCfgCheckedAddOperand(allocator, machine, function, lhs);
        return;
    }
    return error.UnsupportedCodegenValue;
}

fn emitGenericCfgCheckedAddOperand(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    value: ir.Value,
) !void {
    if ((paramValueReg(function, value, .{ .int = 32 }) catch null)) |reg| {
        try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = reg } });
        return;
    }
    switch (value) {
        .int => |int| try machine.instructions.append(allocator, .{ .add_eax_imm32 = try i32Value(int) }),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn genericCfgSupportsNegativeI32Guard(function: ir.Function, icmp: ir.IcmpInst) bool {
    if (icmp.predicate != .slt or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isInt(icmp.rhs, 0)) return false;
    return (paramValueReg(function, icmp.lhs, .{ .int = 32 }) catch null) != null;
}

pub fn emitGenericCfgGlobalAddOkReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    ok: ir.BasicBlock,
) !void {
    if (ok.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    const load_name = ok.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const add_name = ok.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    const load = switch (ok.instructions.items[0].kind) {
        .load => |load| load,
        else => return error.UnsupportedCodegenInstruction,
    };
    const add = switch (ok.instructions.items[1].kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
    if (!((isNamed(add.lhs, load_name) and genericCfgSupportsI32ParamValue(function, add.rhs)) or
        (isNamed(add.rhs, load_name) and genericCfgSupportsI32ParamValue(function, add.lhs)))) return error.UnsupportedCodegenValue;
    const ret = switch (ok.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, add_name)) return error.UnsupportedCodegenValue;
    try emitGenericCfgGlobalLoadParamAdd(allocator, machine, function, load, add);
    try appendGenericCfgReturn(allocator, machine);
}

pub const GenericCfgCheckedGlobalAdd = struct {
    load: ir.LoadInst,
    call: ir.CallInst,
    call_name: []const u8,
    overflow_target: []const u8,
    ret_target: []const u8,
};

pub fn genericCfgCheckedGlobalAdd(ok: ir.BasicBlock) !GenericCfgCheckedGlobalAdd {
    if (ok.instructions.items.len != 3) return error.UnsupportedCodegenInstruction;
    const load_name = ok.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const call_name = ok.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    const overflow_name = ok.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    const load = switch (ok.instructions.items[0].kind) {
        .load => |load| load,
        else => return error.UnsupportedCodegenInstruction,
    };
    const call = switch (ok.instructions.items[1].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!isCalleeName(call.callee, "llvm.sadd.with.overflow.i32")) return error.UnsupportedCodegenInstruction;
    if (!call.ret_ty.eql(.{ .aggregate = "{ i32, i1 }" }) or call.args.items.len != 2) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !call.args.items[1].ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
    if (!isNamed(call.args.items[0].value, load_name) and !isNamed(call.args.items[1].value, load_name)) return error.UnsupportedCodegenValue;
    const overflow_extract = switch (ok.instructions.items[2].kind) {
        .extractvalue => |extractvalue| extractvalue,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!overflow_extract.aggregate_ty.eql(.{ .aggregate = "{ i32, i1 }" }) or
        !overflow_extract.result_ty.eql(.{ .int = 1 }) or
        !isNamed(overflow_extract.aggregate, call_name) or
        !std.mem.eql(u8, overflow_extract.indices, "1"))
    {
        return error.UnsupportedCodegenInstruction;
    }
    const overflow_br = switch (ok.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!overflow_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(overflow_br.cond, overflow_name)) return error.UnsupportedCodegenValue;
    return .{
        .load = load,
        .call = call,
        .call_name = call_name,
        .overflow_target = overflow_br.then_target,
        .ret_target = overflow_br.else_target,
    };
}

pub fn genericCfgValidateCheckedAddRet(function: ir.Function, ret_target: []const u8, call_name: []const u8) !void {
    const ret_block = blockByName(function, ret_target) orelse return error.InvalidBranchTarget;
    if (ret_block.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    const value_name = ret_block.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const value_extract = switch (ret_block.instructions.items[0].kind) {
        .extractvalue => |extractvalue| extractvalue,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!value_extract.aggregate_ty.eql(.{ .aggregate = "{ i32, i1 }" }) or
        !value_extract.result_ty.eql(.{ .int = 32 }) or
        !isNamed(value_extract.aggregate, call_name) or
        !std.mem.eql(u8, value_extract.indices, "0"))
    {
        return error.UnsupportedCodegenInstruction;
    }
    const ret = switch (ret_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, value_name)) return error.UnsupportedCodegenValue;
}

pub fn emitGenericCfgGlobalLoadParamAdd(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    load: ir.LoadInst,
    add: anytype,
) !void {
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return error.UnsupportedCodegenInstruction;
    const global_name = try globalSymbolNameFromValue(load.ptr);
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = global_name });

    if (@TypeOf(add) == ir.BinaryInst) {
        const arg = if (isNamed(add.lhs, "zig_k"))
            add.rhs
        else if (isNamed(add.rhs, "zig_k"))
            add.lhs
        else if ((paramValueReg(function, add.lhs, .{ .int = 32 }) catch null) != null)
            add.lhs
        else
            add.rhs;
        try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = try paramValueReg(function, arg, .{ .int = 32 }) } });
        return;
    }

    const arg = if (isNamed(add.args.items[0].value, "zig_k"))
        add.args.items[1].value
    else if (isNamed(add.args.items[1].value, "zig_k"))
        add.args.items[0].value
    else if ((paramValueReg(function, add.args.items[0].value, .{ .int = 32 }) catch null) != null)
        add.args.items[0].value
    else
        add.args.items[1].value;
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = try paramValueReg(function, arg, .{ .int = 32 }) } });
}

pub fn genericCfgSupportsI32ParamValue(function: ir.Function, value: ir.Value) bool {
    return (paramValueReg(function, value, .{ .int = 32 }) catch null) != null;
}

pub const emitGenericCfgNoreturnCallBlock = pointer_slice_rows.emitGenericCfgNoreturnCallBlock;
pub const validateNoreturnSliceRuntimeCall = pointer_slice_rows.validateNoreturnSliceRuntimeCall;
pub const SlicePointerValue = pointer_slice_rows.SlicePointerValue;
pub const resolveSlicePointerValue = pointer_slice_rows.resolveSlicePointerValue;
pub const SliceLengthValue = pointer_slice_rows.SliceLengthValue;
pub const resolveSliceLengthValue = pointer_slice_rows.resolveSliceLengthValue;
pub const emitSlicePointerIntoRdi = pointer_slice_rows.emitSlicePointerIntoRdi;
pub const emitSliceLengthIntoRsi = pointer_slice_rows.emitSliceLengthIntoRsi;
pub const emitI64ValueIntoArgReg = pointer_slice_rows.emitI64ValueIntoArgReg;
pub const emitNamedI64ValueIntoArgReg = pointer_slice_rows.emitNamedI64ValueIntoArgReg;
pub const emitLoadedI64IntoArgReg = pointer_slice_rows.emitLoadedI64IntoArgReg;
pub const emitComputedI64IntoArgReg = pointer_slice_rows.emitComputedI64IntoArgReg;
const emitRaxIntoArgReg = pointer_slice_rows.emitRaxIntoArgReg;
const findInstructionInFunction = pointer_slice_rows.findInstructionInFunction;

pub fn appendGenericCfgPhiBinaryImmediate(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    phi_binary: GenericCfgPhiBinaryReturn,
) !void {
    switch (phi_binary.op) {
        .add => try machine.instructions.append(allocator, .{ .add_eax_imm32 = phi_binary.imm }),
        .sub => try machine.instructions.append(allocator, .{ .add_eax_imm32 = -phi_binary.imm }),
        else => return error.UnsupportedCodegenInstruction,
    }
}

pub fn lowerGenericCfgBranchMergeReturn(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.blocks.items.len != 4) return false;
    const entry = function.blocks.items[0];
    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 })) return false;
    const then_index = blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget;
    const else_index = blockIndex(function, condbr.else_target) orelse return error.InvalidBranchTarget;
    const then_block = function.blocks.items[then_index];
    const else_block = function.blocks.items[else_index];
    const then_target = singleBrTarget(then_block) orelse return false;
    const else_target = singleBrTarget(else_block) orelse return false;
    if (!std.mem.eql(u8, then_target, else_target)) return false;
    const merge_index = blockIndex(function, then_target) orelse return error.InvalidBranchTarget;
    const merge_block = function.blocks.items[merge_index];
    if (!genericCfgSupportsBranchMergeBlock(function, entry, then_block, else_block, merge_block)) return false;

    try emitGenericCfgConditionTrueBranch(allocator, machine, function, entry, condbr.cond, then_block.name);
    try emitGenericCfgBranchPathReturn(allocator, machine, function, else_block, merge_block);
    try appendGenericCfgBlockLabel(allocator, machine, then_block.name);
    try emitGenericCfgBranchPathReturn(allocator, machine, function, then_block, merge_block);
    return true;
}

pub fn lowerGenericCfgTerminalBranchReturn(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) and !function.ret_ty.eql(.{ .int = 64 })) return false;
    if (function.blocks.items.len < 3 or function.blocks.items.len > 4) return false;
    if (try lowerGenericCfgErrorUnionPayloadBranchReturn(allocator, machine, function)) return true;
    const entry = function.blocks.items[0];
    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 })) return false;
    const then_index = blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget;
    const else_index = blockIndex(function, condbr.else_target) orelse return error.InvalidBranchTarget;
    const then_block = function.blocks.items[then_index];
    const else_block = function.blocks.items[else_index];
    if (!genericCfgTerminalBranchExtraBlocksAreUnreachable(function, then_index, else_index)) return false;
    if (!genericCfgSupportsTerminalReturnBlock(function, entry, then_block)) return false;
    if (!genericCfgSupportsTerminalReturnBlock(function, entry, else_block)) return false;

    if (terminalCondParamReg(function, condbr.cond)) |cond_reg| {
        try machine.instructions.append(allocator, .{ .test_arg8 = cond_reg });
        try appendGenericCfgConditionalBranch(allocator, machine, .je, else_block.name);
        try appendGenericCfgBlockLabel(allocator, machine, then_block.name);
        try emitGenericCfgTerminalReturnBlock(allocator, machine, function, entry, then_block);
        try appendGenericCfgBlockLabel(allocator, machine, else_block.name);
        try emitGenericCfgTerminalReturnBlock(allocator, machine, function, entry, else_block);
        return true;
    }

    try emitGenericCfgTerminalConditionTrueBranch(allocator, machine, function, entry, entry, condbr.cond, then_block.name);
    try emitGenericCfgTerminalReturnBlock(allocator, machine, function, entry, else_block);
    try appendGenericCfgBlockLabel(allocator, machine, then_block.name);
    try emitGenericCfgTerminalReturnBlock(allocator, machine, function, entry, then_block);
    return true;
}

pub const lowerGenericCfgErrorUnionPayloadBranchReturn = error_union_rows.lowerGenericCfgErrorUnionPayloadBranchReturn;
const terminalConstI32Return = error_union_rows.terminalConstI32Return;

pub fn lowerGenericCfgLinearTerminalBranchReturn(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) and !function.ret_ty.eql(.{ .int = 64 })) return false;
    if (try lowerGenericCfgLinearErrorUnionTryChainReturn(allocator, machine, function)) return true;
    if (try lowerGenericCfgErrorUnionTrySwitchReturn(allocator, machine, function)) return true;
    if (try lowerGenericCfgErrorUnionSwitchPhiReturn(allocator, machine, function)) return true;
    if (try lowerGenericCfgErrorUnionErrorTagSwitchReturn(allocator, machine, function)) return true;
    if (try lowerGenericCfgErrorUnionErrorTagBranchReturn(allocator, machine, function)) return true;
    if (try lowerGenericCfgErrorUnionCatchValueMergeReturn(allocator, machine, function)) return true;
    if (try lowerGenericCfgErrorUnionCatchSwitchReturn(allocator, machine, function)) return true;
    if (try lowerGenericCfgErrorUnionTryRewrapErrorReturn(allocator, machine, function)) return true;
    if (try lowerGenericCfgErrorUnionTryPayloadCallReturn(allocator, machine, function)) return true;
    if (try lowerGenericCfgErrorUnionTryPhiSlotOverrideReturn(allocator, machine, function)) return true;
    if (try lowerGenericCfgErrorUnionTrySlotUpdateReturn(allocator, machine, function)) return true;
    if (try lowerGenericCfgErrorUnionTryPayloadBranchReturn(allocator, machine, function)) return true;
    if (try lowerGenericCfgBranchBothErrorUnionTryReturn(allocator, machine, function)) return true;
    if (try lowerGenericCfgBranchThenErrorUnionTryReturn(allocator, machine, function)) return true;
    if (try lowerGenericCfgSwitchBothErrorUnionTryReturn(allocator, machine, function)) return true;
    if (try lowerGenericCfgSwitchThenErrorUnionTryReturn(allocator, machine, function)) return true;
    if (function.blocks.items.len < 5) return false;
    const entry = function.blocks.items[0];
    const entry_condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_condbr.cond_ty.eql(.{ .int = 1 })) return false;

    const then_index = blockIndex(function, entry_condbr.then_target) orelse return error.InvalidBranchTarget;
    const else_index = blockIndex(function, entry_condbr.else_target) orelse return error.InvalidBranchTarget;
    const then_block = function.blocks.items[then_index];
    const else_block = function.blocks.items[else_index];
    const then_is_cont = blockHasCondbr(then_block);
    const else_is_cont = blockHasCondbr(else_block);
    if (then_is_cont == else_is_cont) return false;

    const continuation_index = if (then_is_cont) then_index else else_index;
    const first_return_index = if (then_is_cont) else_index else then_index;
    const continuation = function.blocks.items[continuation_index];
    const first_return = function.blocks.items[first_return_index];
    const continuation_condbr = switch (continuation.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!continuation_condbr.cond_ty.eql(.{ .int = 1 })) return false;
    if (!genericCfgSupportsTerminalReturnBlock(function, entry, first_return)) return false;

    const second_then_index = blockIndex(function, continuation_condbr.then_target) orelse return error.InvalidBranchTarget;
    const second_else_index = blockIndex(function, continuation_condbr.else_target) orelse return error.InvalidBranchTarget;
    if (second_then_index == 0 or second_else_index == 0 or
        second_then_index == continuation_index or second_else_index == continuation_index or
        second_then_index == first_return_index or second_else_index == first_return_index)
    {
        return false;
    }
    const second_then = function.blocks.items[second_then_index];
    const second_else = function.blocks.items[second_else_index];
    if (!genericCfgSupportsNestedTerminalReturnBlock(function, entry, continuation, second_then)) return false;
    if (!genericCfgSupportsNestedTerminalReturnBlock(function, entry, continuation, second_else)) return false;
    if (!linearTerminalBranchUsesAllBlocks(function, continuation_index, first_return_index, second_then_index, second_else_index)) return false;

    if (then_is_cont) {
        try emitGenericCfgTerminalConditionTrueBranch(allocator, machine, function, entry, entry, entry_condbr.cond, continuation.name);
        try emitGenericCfgTerminalReturnBlock(allocator, machine, function, entry, first_return);
        try appendGenericCfgBlockLabel(allocator, machine, continuation.name);
        try emitGenericCfgNestedTerminalBranch(
            allocator,
            machine,
            function,
            entry,
            continuation,
            continuation_condbr.cond,
            continuation_condbr.then_target,
            continuation_condbr.else_target,
        );
    } else {
        try emitGenericCfgTerminalConditionTrueBranch(allocator, machine, function, entry, entry, entry_condbr.cond, first_return.name);
        try appendGenericCfgBlockLabel(allocator, machine, continuation.name);
        try emitGenericCfgNestedTerminalBranch(
            allocator,
            machine,
            function,
            entry,
            continuation,
            continuation_condbr.cond,
            continuation_condbr.then_target,
            continuation_condbr.else_target,
        );
        try appendGenericCfgBlockLabel(allocator, machine, first_return.name);
        try emitGenericCfgTerminalReturnBlock(allocator, machine, function, entry, first_return);
    }
    return true;
}

const ErrorUnionSwitchPhiCase = struct {
    value: i32,
    block: ir.BasicBlock,
    incoming: ir.Value,
};

const ErrorUnionSwitchCond = union(enum) {
    param: ArgReg,
    masked_param: struct {
        reg: ArgReg,
        mask: i32,
    },
};

const ErrorUnionSwitchPhiReturn = struct {
    entry: ir.BasicBlock,
    cond: ErrorUnionSwitchCond,
    cases: [8]ErrorUnionSwitchPhiCase,
    case_count: usize,
    default_block: ir.BasicBlock,
    default_incoming: ir.Value,
};

const ErrorUnionErrorTagSwitchReturn = struct {
    entry: ir.BasicBlock,
    call_name: []const u8,
    call: ir.CallInst,
    payload_block: ir.BasicBlock,
    payload_return: ErrorUnionI32ReturnValue,
    switch_block: ir.BasicBlock,
    cases: [8]ErrorUnionSwitchPhiCase,
    case_count: usize,
    default_block: ir.BasicBlock,
    merge_block: ir.BasicBlock,
    live_param_reg: ?ArgReg,
};

const ErrorUnionErrorTagBranchReturn = struct {
    entry: ir.BasicBlock,
    call_name: []const u8,
    call: ir.CallInst,
    payload_block: ir.BasicBlock,
    payload_return: ErrorUnionI32ReturnValue,
    branch_block: ir.BasicBlock,
    error_value: i32,
    true_block: ir.BasicBlock,
    true_value: i32,
    false_block: ir.BasicBlock,
    false_value: i32,
};

const ErrorUnionCatchValueMergeReturn = struct {
    entry: ir.BasicBlock,
    call_name: []const u8,
    call: ir.CallInst,
    payload_block: ir.BasicBlock,
    fallback_block: ir.BasicBlock,
    merge_block: ir.BasicBlock,
    fallback: ErrorUnionCatchFallbackValue,
    add_imm: i32,
};

const ErrorUnionCatchFallbackValue = union(enum) {
    int: i32,
    param: ArgReg,
};

const NamedPhi = struct {
    name: []const u8,
    phi: ir.PhiInst,
};

const ErrorUnionI32ReturnValue = union(enum) {
    generic: ir.Value,
    payload_add_imm: i32,
    payload_binary: PayloadBinaryWrapReturn,
};

const ErrorUnionCatchSwitchReturn = struct {
    entry: ir.BasicBlock,
    call_name: []const u8,
    call: ir.CallInst,
    payload_block: ir.BasicBlock,
    payload_add_imm: u8,
    switch_block: ir.BasicBlock,
    cases: [8]ErrorUnionSwitchPhiCase,
    case_count: usize,
    default_block: ir.BasicBlock,
    merge_block: ir.BasicBlock,
};

fn lowerGenericCfgErrorUnionSwitchPhiReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = errorUnionSwitchPhiReturn(function) orelse return false;
    try emitErrorUnionSwitchCondIntoEax(allocator, machine, plan.cond);
    for (plan.cases[0..plan.case_count]) |case| {
        try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = case.value });
        try appendGenericCfgConditionalBranch(allocator, machine, .je, case.block.name);
    }
    try machine.instructions.append(allocator, .{ .jmp = plan.default_block.name });

    for (plan.cases[0..plan.case_count]) |case| {
        try appendGenericCfgBlockLabel(allocator, machine, case.block.name);
        try emitGenericCfgTerminalI64ValueIntoRax(allocator, machine, function, plan.entry, case.block, case.incoming);
        try appendGenericCfgReturn(allocator, machine);
    }
    try appendGenericCfgBlockLabel(allocator, machine, plan.default_block.name);
    try emitGenericCfgTerminalI64ValueIntoRax(allocator, machine, function, plan.entry, plan.default_block, plan.default_incoming);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

fn errorUnionSwitchPhiReturn(function: ir.Function) ?ErrorUnionSwitchPhiReturn {
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.blocks.items.len < 4) return null;
    const entry = function.blocks.items[0];
    const switch_term = blockSwitchTerminator(entry) orelse return null;
    if (!switch_term.cond_ty.eql(.{ .int = 32 })) return null;
    const cond = errorUnionSwitchCond(function, entry, switch_term.cond) orelse return null;
    if (switch_term.cases.items.len == 0 or switch_term.cases.items.len > 8) return null;
    const merge_block = commonSwitchMergeBlock(function, switch_term) orelse return null;
    const phi = firstPhiReturn(function, merge_block) orelse return null;
    if (!phi.ty.eql(.{ .int = 64 })) return null;

    var cases: [8]ErrorUnionSwitchPhiCase = undefined;
    for (switch_term.cases.items, 0..) |case, case_index| {
        if (!case.value_ty.eql(.{ .int = 32 })) return null;
        const value = switch (case.value) {
            .int => |int| i32Value(int) catch return null,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
        };
        const block = function.blocks.items[blockIndex(function, case.target) orelse return null];
        if (!blockBranchesTo(block, merge_block.name)) return null;
        cases[case_index] = .{
            .value = value,
            .block = block,
            .incoming = phiIncomingForBlock(phi, block.name) orelse return null,
        };
    }
    const default_block = function.blocks.items[blockIndex(function, switch_term.default_target) orelse return null];
    if (!blockBranchesTo(default_block, merge_block.name)) return null;
    if (!switchPhiUsesAllBlocks(function, merge_block.name, switch_term)) return null;

    return .{
        .entry = entry,
        .cond = cond,
        .cases = cases,
        .case_count = switch_term.cases.items.len,
        .default_block = default_block,
        .default_incoming = phiIncomingForBlock(phi, default_block.name) orelse return null,
    };
}

fn errorUnionSwitchCond(function: ir.Function, entry: ir.BasicBlock, value: ir.Value) ?ErrorUnionSwitchCond {
    const name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (entry.instructions.items.len == 0) {
        const reg = paramRegOrNull(function, name, .{ .int = 32 }) catch return null;
        return .{ .param = reg orelse return null };
    }
    if (entry.instructions.items.len != 1) return null;
    const instruction = findInstruction(entry, name) orelse return null;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (binary.op != .@"and" or !binary.ty.eql(.{ .int = 32 })) return null;
    const reg = switch (binary.lhs) {
        .named => |lhs| paramRegOrNull(function, lhs, .{ .int = 32 }) catch return null,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    } orelse return null;
    const mask = switch (binary.rhs) {
        .int => |int| i32Value(int) catch return null,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    return .{ .masked_param = .{ .reg = reg, .mask = mask } };
}

fn emitErrorUnionSwitchCondIntoEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    cond: ErrorUnionSwitchCond,
) !void {
    switch (cond) {
        .param => |reg| try machine.instructions.append(allocator, .{ .mov_arg_eax = reg }),
        .masked_param => |masked| {
            try machine.instructions.append(allocator, .{ .mov_arg_eax = masked.reg });
            try machine.instructions.append(allocator, .{ .and_eax_imm32 = masked.mask });
        },
    }
}

fn lowerGenericCfgErrorUnionErrorTagSwitchReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = errorUnionErrorTagSwitchReturn(function) orelse return false;
    const frame_bytes: u8 = if (plan.live_param_reg != null) 24 else 8;
    const epilogue_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_error_tag_switch_{}_generic_cfg_select_end",
        .{machine.instructions.items.len},
    );

    try appendStackFrame(allocator, machine, frame_bytes);
    if (plan.live_param_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{ .frame_index = .slot2, .reg = reg } });
    }
    try emitTwoI32ArgCallIntoRax(allocator, machine, function, plan.entry, plan.call);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, .je, plan.payload_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, plan.switch_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    for (plan.cases[0..plan.case_count]) |case| {
        try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = case.value });
        try appendGenericCfgConditionalBranch(allocator, machine, .je, case.block.name);
    }
    try machine.instructions.append(allocator, .{ .jmp = plan.default_block.name });

    for (plan.cases[0..plan.case_count]) |case| {
        try appendGenericCfgBlockLabel(allocator, machine, case.block.name);
        try emitErrorUnionI32ReturnValueIntoEax(allocator, machine, function, plan.entry, case.block, .{ .generic = case.incoming }, plan.live_param_reg);
        try machine.instructions.append(allocator, .{ .jmp = epilogue_label });
    }

    try appendGenericCfgBlockLabel(allocator, machine, plan.payload_block.name);
    try emitErrorUnionI32ReturnValueIntoEax(allocator, machine, function, plan.entry, plan.payload_block, plan.payload_return, plan.live_param_reg);
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);

    try appendGenericCfgBlockLabel(allocator, machine, plan.default_block.name);
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerGenericCfgErrorUnionErrorTagBranchReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = errorUnionErrorTagBranchReturn(function) orelse return false;
    const frame_bytes: u8 = 8;
    const epilogue_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_error_tag_branch_{}_generic_cfg_select_end",
        .{machine.instructions.items.len},
    );

    try appendStackFrame(allocator, machine, frame_bytes);
    try emitTwoI32ArgCallIntoRax(allocator, machine, function, plan.entry, plan.call);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, .je, plan.payload_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, plan.branch_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = plan.error_value });
    try appendGenericCfgConditionalBranch(allocator, machine, .je, plan.true_block.name);
    try appendGenericCfgBlockLabel(allocator, machine, plan.false_block.name);
    try machine.instructions.append(allocator, .{ .mov_imm_eax = plan.false_value });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, plan.true_block.name);
    try machine.instructions.append(allocator, .{ .mov_imm_eax = plan.true_value });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, plan.payload_block.name);
    try emitErrorUnionI32ReturnValueIntoEax(allocator, machine, function, plan.entry, plan.payload_block, plan.payload_return, null);
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

fn lowerGenericCfgErrorUnionCatchValueMergeReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = errorUnionCatchValueMergeReturn(function) orelse return false;
    const live_fallback_reg: ?ArgReg = switch (plan.fallback) {
        .param => |reg| reg,
        .int => null,
    };
    const frame_bytes: u8 = if (live_fallback_reg != null) 24 else 8;
    const fallback_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_error_catch_value_{}_fallback",
        .{machine.instructions.items.len},
    );
    const epilogue_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_error_catch_value_{}_generic_cfg_select_end",
        .{machine.instructions.items.len},
    );

    try appendStackFrame(allocator, machine, frame_bytes);
    if (live_fallback_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{ .frame_index = .slot2, .reg = reg } });
    }
    try emitTwoI32ArgCallIntoRax(allocator, machine, function, plan.entry, plan.call);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, .jne, fallback_label);

    try appendGenericCfgBlockLabel(allocator, machine, plan.payload_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 16 });
    if (plan.add_imm != 0) try machine.instructions.append(allocator, .{ .add_eax_imm32 = plan.add_imm });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, fallback_label);
    switch (plan.fallback) {
        .int => |value| try machine.instructions.append(allocator, .{ .mov_imm_eax = value }),
        .param => |reg| {
            try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{ .frame_index = .slot2, .reg = reg } });
            try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
        },
    }
    if (plan.add_imm != 0) try machine.instructions.append(allocator, .{ .add_eax_imm32 = plan.add_imm });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

fn lowerGenericCfgErrorUnionCatchSwitchReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = errorUnionCatchSwitchReturn(function) orelse return false;
    const frame_bytes: u8 = 8;
    const epilogue_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_error_catch_switch_{}_generic_cfg_select_end",
        .{machine.instructions.items.len},
    );

    try appendStackFrame(allocator, machine, frame_bytes);
    try emitTwoI32ArgCallIntoRax(allocator, machine, function, plan.entry, plan.call);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, .je, plan.payload_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, plan.switch_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    for (plan.cases[0..plan.case_count]) |case| {
        try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = case.value });
        try appendGenericCfgConditionalBranch(allocator, machine, .je, case.block.name);
    }
    try machine.instructions.append(allocator, .{ .jmp = plan.default_block.name });

    for (plan.cases[0..plan.case_count]) |case| {
        try appendGenericCfgBlockLabel(allocator, machine, case.block.name);
        try emitGenericCfgTerminalI64ValueIntoRax(allocator, machine, function, plan.entry, case.block, case.incoming);
        try machine.instructions.append(allocator, .{ .jmp = epilogue_label });
    }

    try appendGenericCfgBlockLabel(allocator, machine, plan.payload_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 16 });
    if (plan.payload_add_imm != 0) try machine.instructions.append(allocator, .{ .add_rax_imm8 = plan.payload_add_imm });
    try machine.instructions.append(allocator, .{ .shl_rax_imm6 = 16 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);

    try appendGenericCfgBlockLabel(allocator, machine, plan.default_block.name);
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn errorUnionErrorTagSwitchReturn(function: ir.Function) ?ErrorUnionErrorTagSwitchReturn {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.blocks.items.len < 6) return null;
    const entry = function.blocks.items[0];
    const entry_condbr = switch (entry.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!entry_condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const call_name = errorUnionTryGuardCallResult(entry, entry_condbr.cond) orelse return null;
    const call_instruction = findInstruction(entry, call_name) orelse return null;
    const call = switch (call_instruction.kind) {
        .call => |call| call,
        else => return null,
    };
    if (!supportsDirectI64Call(call) or call.args.items.len != 2) return null;

    const then_block = function.blocks.items[blockIndex(function, entry_condbr.then_target) orelse return null];
    const else_block = function.blocks.items[blockIndex(function, entry_condbr.else_target) orelse return null];
    const then_payload_return = errorUnionPayloadI32Return(function, then_block, call_name);
    const else_payload_return = errorUnionPayloadI32Return(function, else_block, call_name);
    if ((then_payload_return != null) == (else_payload_return != null)) return null;
    const payload_block = if (then_payload_return != null) then_block else else_block;
    const switch_block = if (then_payload_return != null) else_block else then_block;
    const payload_return = then_payload_return orelse else_payload_return.?;

    const switch_term = blockSwitchTerminator(switch_block) orelse return null;
    if (!switch_term.cond_ty.eql(.{ .int = 16 })) return null;
    if (!errorTagValueFromCallResult(switch_block, switch_term.cond, call_name)) return null;
    if (switch_term.cases.items.len == 0 or switch_term.cases.items.len > 8) return null;
    const merge_block = exhaustiveSwitchMergeBlock(function, switch_term) orelse return null;
    const phi = firstPhiReturn(function, merge_block) orelse return null;
    if (!phi.ty.eql(.{ .int = 32 })) return null;

    var cases: [8]ErrorUnionSwitchPhiCase = undefined;
    var live_param_reg = errorUnionI32ReturnLiveParam(function, payload_block, payload_return);
    for (switch_term.cases.items, 0..) |case, case_index| {
        if (!case.value_ty.eql(.{ .int = 16 })) return null;
        const value = switch (case.value) {
            .int => |int| i32Value(int) catch return null,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
        };
        const block = function.blocks.items[blockIndex(function, case.target) orelse return null];
        if (!blockBranchesTo(block, merge_block.name)) return null;
        const incoming = phiIncomingForBlock(phi, block.name) orelse return null;
        if (!mergeLiveParam(&live_param_reg, errorUnionI32ReturnLiveParam(function, block, .{ .generic = incoming }))) return null;
        cases[case_index] = .{
            .value = value,
            .block = block,
            .incoming = incoming,
        };
    }
    const default_block = function.blocks.items[blockIndex(function, switch_term.default_target) orelse return null];
    if (!blockIsUnreachable(default_block)) return null;
    if (!errorTagSwitchUsesAllBlocks(function, payload_block.name, switch_block.name, merge_block.name, switch_term)) return null;

    return .{
        .entry = entry,
        .call_name = call_name,
        .call = call,
        .payload_block = payload_block,
        .payload_return = payload_return,
        .switch_block = switch_block,
        .cases = cases,
        .case_count = switch_term.cases.items.len,
        .default_block = default_block,
        .merge_block = merge_block,
        .live_param_reg = live_param_reg,
    };
}

fn errorUnionErrorTagBranchReturn(function: ir.Function) ?ErrorUnionErrorTagBranchReturn {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.blocks.items.len < 5) return null;
    const entry = function.blocks.items[0];
    const entry_condbr = switch (entry.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!entry_condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const call_name = errorUnionTryGuardCallResult(entry, entry_condbr.cond) orelse return null;
    const call_instruction = findInstruction(entry, call_name) orelse return null;
    const call = switch (call_instruction.kind) {
        .call => |call| call,
        else => return null,
    };
    if (!supportsDirectI64Call(call) or call.args.items.len != 2) return null;

    const then_block = function.blocks.items[blockIndex(function, entry_condbr.then_target) orelse return null];
    const else_block = function.blocks.items[blockIndex(function, entry_condbr.else_target) orelse return null];
    const then_payload_return = errorUnionPayloadI32Return(function, then_block, call_name);
    const else_payload_return = errorUnionPayloadI32Return(function, else_block, call_name);
    if ((then_payload_return != null) == (else_payload_return != null)) return null;
    const payload_block = if (then_payload_return != null) then_block else else_block;
    const branch_block = if (then_payload_return != null) else_block else then_block;
    const payload_return = then_payload_return orelse else_payload_return.?;
    if (errorUnionI32ReturnLiveParam(function, payload_block, payload_return) != null) return null;

    const branch_condbr = switch (branch_block.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!branch_condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const error_value = errorTagIcmpValueFromCallResult(branch_block, branch_condbr.cond, call_name) orelse return null;
    const true_block = function.blocks.items[blockIndex(function, branch_condbr.then_target) orelse return null];
    const false_block = function.blocks.items[blockIndex(function, branch_condbr.else_target) orelse return null];
    const true_value = terminalConstI32Return(true_block) orelse return null;
    const false_value = terminalConstI32Return(false_block) orelse return null;
    if (!errorTagBranchUsesOnlyExpectedBlocks(function, entry.name, payload_block.name, branch_block.name, true_block.name, false_block.name)) return null;

    return .{
        .entry = entry,
        .call_name = call_name,
        .call = call,
        .payload_block = payload_block,
        .payload_return = payload_return,
        .branch_block = branch_block,
        .error_value = error_value,
        .true_block = true_block,
        .true_value = true_value,
        .false_block = false_block,
        .false_value = false_value,
    };
}

fn errorUnionCatchValueMergeReturn(function: ir.Function) ?ErrorUnionCatchValueMergeReturn {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.blocks.items.len < 4) return null;
    const entry = function.blocks.items[0];
    const entry_condbr = switch (entry.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!entry_condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const call_name = errorUnionTryGuardCallResult(entry, entry_condbr.cond) orelse return null;
    const call_instruction = findInstruction(entry, call_name) orelse return null;
    const call = switch (call_instruction.kind) {
        .call => |call| call,
        else => return null,
    };
    if (!supportsDirectI64Call(call) or call.args.items.len != 2) return null;

    const then_block = function.blocks.items[blockIndex(function, entry_condbr.then_target) orelse return null];
    const else_block = function.blocks.items[blockIndex(function, entry_condbr.else_target) orelse return null];
    const then_target = singleBrTarget(then_block) orelse return null;
    const else_target = singleBrTarget(else_block) orelse return null;
    if (!std.mem.eql(u8, then_target, else_target)) return null;
    const merge_block = function.blocks.items[blockIndex(function, then_target) orelse return null];
    const named_phi = firstNamedPhi(merge_block) orelse return null;
    const phi = named_phi.phi;
    if (!phi.ty.eql(.{ .int = 32 })) return null;

    const then_incoming = phiIncomingForBlock(phi, then_block.name) orelse return null;
    const else_incoming = phiIncomingForBlock(phi, else_block.name) orelse return null;
    const then_is_payload = payloadValueFromCallResult(then_block, then_incoming, call_name);
    const else_is_payload = payloadValueFromCallResult(else_block, else_incoming, call_name);
    if (then_is_payload == else_is_payload) return null;
    const payload_block = if (then_is_payload) then_block else else_block;
    const fallback_block = if (then_is_payload) else_block else then_block;
    const fallback_value = if (then_is_payload) else_incoming else then_incoming;
    const fallback = catchFallbackValue(function, fallback_value) orelse return null;
    const add_imm = phiAddReturnImm(merge_block, named_phi.name) orelse return null;
    if (!catchValueMergeUsesOnlyExpectedBlocks(function, entry.name, payload_block.name, fallback_block.name, merge_block.name)) return null;

    return .{
        .entry = entry,
        .call_name = call_name,
        .call = call,
        .payload_block = payload_block,
        .fallback_block = fallback_block,
        .merge_block = merge_block,
        .fallback = fallback,
        .add_imm = add_imm,
    };
}

fn errorUnionCatchSwitchReturn(function: ir.Function) ?ErrorUnionCatchSwitchReturn {
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.blocks.items.len < 6) return null;
    const entry = function.blocks.items[0];
    const entry_condbr = switch (entry.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!entry_condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const call_name = errorUnionTryGuardCallResult(entry, entry_condbr.cond) orelse return null;
    const call_instruction = findInstruction(entry, call_name) orelse return null;
    const call = switch (call_instruction.kind) {
        .call => |call| call,
        else => return null,
    };
    if (!supportsDirectI64Call(call) or call.args.items.len != 2) return null;

    const then_block = function.blocks.items[blockIndex(function, entry_condbr.then_target) orelse return null];
    const else_block = function.blocks.items[blockIndex(function, entry_condbr.else_target) orelse return null];
    const then_payload_add = payloadAddWrapReturnFromCallResult(then_block, call_name);
    const else_payload_add = payloadAddWrapReturnFromCallResult(else_block, call_name);
    if ((then_payload_add != null) == (else_payload_add != null)) return null;
    const payload_block = if (then_payload_add != null) then_block else else_block;
    const switch_block = if (then_payload_add != null) else_block else then_block;
    const payload_add_imm = then_payload_add orelse else_payload_add.?;

    const switch_term = blockSwitchTerminator(switch_block) orelse return null;
    if (!switch_term.cond_ty.eql(.{ .int = 16 })) return null;
    if (!errorTagValueFromCallResult(switch_block, switch_term.cond, call_name)) return null;
    if (switch_term.cases.items.len == 0 or switch_term.cases.items.len > 8) return null;
    const merge_block = exhaustiveSwitchMergeBlock(function, switch_term) orelse return null;
    const phi = firstPhiReturn(function, merge_block) orelse return null;
    if (!phi.ty.eql(.{ .int = 64 })) return null;

    var cases: [8]ErrorUnionSwitchPhiCase = undefined;
    for (switch_term.cases.items, 0..) |case, case_index| {
        if (!case.value_ty.eql(.{ .int = 16 })) return null;
        const value = switch (case.value) {
            .int => |int| i32Value(int) catch return null,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
        };
        const block = function.blocks.items[blockIndex(function, case.target) orelse return null];
        if (!blockBranchesTo(block, merge_block.name)) return null;
        cases[case_index] = .{
            .value = value,
            .block = block,
            .incoming = phiIncomingForBlock(phi, block.name) orelse return null,
        };
    }
    const default_block = function.blocks.items[blockIndex(function, switch_term.default_target) orelse return null];
    if (!blockIsUnreachable(default_block)) return null;
    if (!errorTagSwitchUsesAllBlocks(function, payload_block.name, switch_block.name, merge_block.name, switch_term)) return null;

    return .{
        .entry = entry,
        .call_name = call_name,
        .call = call,
        .payload_block = payload_block,
        .payload_add_imm = payload_add_imm,
        .switch_block = switch_block,
        .cases = cases,
        .case_count = switch_term.cases.items.len,
        .default_block = default_block,
        .merge_block = merge_block,
    };
}

fn errorUnionPayloadI32Return(function: ir.Function, block: ir.BasicBlock, call_name: []const u8) ?ErrorUnionI32ReturnValue {
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return null;
    const ret_value = ret.value orelse return null;
    if (payloadValueFromCallResult(block, ret_value, call_name)) return .{ .payload_add_imm = 0 };
    const add_name = switch (ret_value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (payloadAddFromCallResult(block, add_name, call_name)) |imm| return .{ .payload_add_imm = imm };
    if (payloadBinaryI32Return(function, block, block, call_name)) |binary| return .{ .payload_binary = binary };
    return null;
}

fn payloadAddWrapReturnFromCallResult(block: ir.BasicBlock, call_name: []const u8) ?u8 {
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 64 })) return null;
    return payloadAddWrapValue(block, block, ret.value orelse return null, call_name);
}

fn errorUnionPayloadAddReturn(block: ir.BasicBlock, call_name: []const u8) ?i32 {
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return null;
    const ret_value = ret.value orelse return null;
    if (payloadValueFromCallResult(block, ret_value, call_name)) return 0;
    const add_name = switch (ret_value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    return payloadAddFromCallResult(block, add_name, call_name) orelse return null;
}

fn payloadBinaryI32Return(
    function: ir.Function,
    payload_scope: ir.BasicBlock,
    block: ir.BasicBlock,
    call_name: []const u8,
) ?PayloadBinaryWrapReturn {
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return null;
    const binary_name = switch (ret.value orelse return null) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const binary_inst = findInstruction(block, binary_name) orelse return null;
    const binary = switch (binary_inst.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (!binary.ty.eql(.{ .int = 32 }) or (binary.op != .add and binary.op != .sub)) return null;
    const payload_on_lhs = payloadValueFromCallResult(payload_scope, binary.lhs, call_name);
    const payload_on_rhs = payloadValueFromCallResult(payload_scope, binary.rhs, call_name);
    if (payload_on_lhs == payload_on_rhs) return null;
    if (binary.op == .sub and !payload_on_lhs) return null;
    const other_value = if (payload_on_lhs) binary.rhs else binary.lhs;
    const reg = switch (other_value) {
        .named => |name| paramReg(function, name, .{ .int = 32 }) catch return null,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const op: MachineBinaryOp = switch (binary.op) {
        .add => .add,
        .sub => .sub,
        else => unreachable,
    };
    return .{ .op = op, .reg = reg };
}

fn errorUnionI32ReturnLiveParam(function: ir.Function, block: ir.BasicBlock, value: ErrorUnionI32ReturnValue) ?ArgReg {
    return switch (value) {
        .payload_binary => |binary| binary.reg,
        .payload_add_imm => null,
        .generic => |generic| i32ValueLiveParam(function, block, generic),
    };
}

fn i32ValueLiveParam(function: ir.Function, block: ir.BasicBlock, value: ir.Value) ?ArgReg {
    switch (value) {
        .int => return null,
        .named => |name| {
            if (paramRegOrNull(function, name, .{ .int = 32 }) catch null) |reg| return reg;
            const instruction = findInstruction(block, name) orelse return null;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (!binary.ty.eql(.{ .int = 32 })) return null;
                    const lhs = i32ValueLiveParam(function, block, binary.lhs);
                    const rhs = i32ValueLiveParam(function, block, binary.rhs);
                    if (lhs != null and rhs != null) return null;
                    return lhs orelse rhs;
                },
                else => return null,
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    }
}

fn mergeLiveParam(existing: *?ArgReg, candidate: ?ArgReg) bool {
    const candidate_reg = candidate orelse return true;
    if (existing.*) |existing_reg| return existing_reg == candidate_reg;
    existing.* = candidate_reg;
    return true;
}

fn emitErrorUnionI32ReturnValueIntoEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    entry: ir.BasicBlock,
    block: ir.BasicBlock,
    value: ErrorUnionI32ReturnValue,
    live_param_reg: ?ArgReg,
) !void {
    switch (value) {
        .payload_add_imm => |imm| {
            try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
            try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 16 });
            if (imm != 0) try machine.instructions.append(allocator, .{ .add_eax_imm32 = imm });
        },
        .payload_binary => |binary| {
            const live_reg = live_param_reg orelse return error.UnsupportedLiveAcrossCall;
            if (live_reg != binary.reg) return error.UnsupportedLiveAcrossCall;
            try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
            try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 16 });
            try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{ .frame_index = .slot2, .reg = binary.reg } });
            try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = binary.op, .reg = binary.reg } });
        },
        .generic => |generic| {
            if (live_param_reg) |reg| {
                try emitI32ValueWithLiveParamIntoEax(allocator, machine, function, entry, block, generic, reg);
            } else {
                try emitGenericCfgTerminalI32ValueIntoEax(allocator, machine, function, entry, block, generic);
            }
        },
    }
}

fn emitI32ValueWithLiveParamIntoEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    entry: ir.BasicBlock,
    block: ir.BasicBlock,
    value: ir.Value,
    live_param_reg: ArgReg,
) !void {
    switch (value) {
        .int => |int| try machine.instructions.append(allocator, .{ .mov_imm_eax = try i32Value(int) }),
        .named => |name| {
            if ((paramRegOrNull(function, name, .{ .int = 32 }) catch null)) |reg| {
                if (reg == live_param_reg) {
                    try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{ .frame_index = .slot2, .reg = reg } });
                }
                try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
                return;
            }
            const instruction = findInstruction(block, name) orelse return error.UnsupportedCodegenValue;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (!binary.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
                    try emitI32ValueWithLiveParamIntoEax(allocator, machine, function, entry, block, binary.lhs, live_param_reg);
                    switch (binary.rhs) {
                        .int => |int| switch (binary.op) {
                            .add => try machine.instructions.append(allocator, .{ .add_eax_imm32 = try i32Value(int) }),
                            .sub => try machine.instructions.append(allocator, .{ .add_eax_imm32 = -try i32Value(int) }),
                            else => return error.UnsupportedCodegenInstruction,
                        },
                        .named => |rhs_name| {
                            const rhs_reg = try paramReg(function, rhs_name, .{ .int = 32 });
                            if (rhs_reg == live_param_reg) {
                                try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{ .frame_index = .slot2, .reg = rhs_reg } });
                            }
                            const op = machineBinaryOp(binary.op) orelse return error.UnsupportedCodegenInstruction;
                            try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = op, .reg = rhs_reg } });
                        },
                        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
                    }
                },
                else => try emitGenericCfgTerminalI32ValueIntoEax(allocator, machine, function, entry, block, value),
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

fn errorTagValueFromCallResult(block: ir.BasicBlock, value: ir.Value, call_name: []const u8) bool {
    const trunc_name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const trunc_inst = findInstruction(block, trunc_name) orelse return false;
    const trunc = switch (trunc_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (trunc.op != .trunc or !trunc.from_ty.eql(.{ .int = 64 }) or !trunc.to_ty.eql(.{ .int = 16 })) return false;
    const mask_name = switch (trunc.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const mask_inst = findInstruction(block, mask_name) orelse return false;
    const mask = switch (mask_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    return mask.ty.eql(.{ .int = 64 }) and mask.op == .@"and" and isInt(mask.rhs, 65535) and isNamed(mask.lhs, call_name);
}

fn errorTagIcmpValueFromCallResult(block: ir.BasicBlock, value: ir.Value, call_name: []const u8) ?i32 {
    const icmp_name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const icmp_inst = findInstruction(block, icmp_name) orelse return null;
    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 16 })) return null;
    if (errorTagValueFromCallResult(block, icmp.lhs, call_name)) {
        return switch (icmp.rhs) {
            .int => |int| i32Value(int) catch null,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
        };
    }
    if (errorTagValueFromCallResult(block, icmp.rhs, call_name)) {
        return switch (icmp.lhs) {
            .int => |int| i32Value(int) catch null,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
        };
    }
    return null;
}

fn errorTagBranchUsesOnlyExpectedBlocks(
    function: ir.Function,
    entry_name: []const u8,
    payload_name: []const u8,
    branch_name: []const u8,
    true_name: []const u8,
    false_name: []const u8,
) bool {
    for (function.blocks.items) |block| {
        if (std.mem.eql(u8, block.name, entry_name) or
            std.mem.eql(u8, block.name, payload_name) or
            std.mem.eql(u8, block.name, branch_name) or
            std.mem.eql(u8, block.name, true_name) or
            std.mem.eql(u8, block.name, false_name))
        {
            continue;
        }
        if (!blockIsUnreachable(block)) return false;
    }
    return true;
}

fn exhaustiveSwitchMergeBlock(function: ir.Function, switch_term: ir.SwitchTerminator) ?ir.BasicBlock {
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
    return function.blocks.items[blockIndex(function, target orelse return null) orelse return null];
}

fn errorTagSwitchUsesAllBlocks(
    function: ir.Function,
    payload_block: []const u8,
    switch_block: []const u8,
    merge_block: []const u8,
    switch_term: ir.SwitchTerminator,
) bool {
    for (function.blocks.items, 0..) |block, index| {
        if (index == 0 or
            std.mem.eql(u8, block.name, payload_block) or
            std.mem.eql(u8, block.name, switch_block) or
            std.mem.eql(u8, block.name, merge_block) or
            std.mem.eql(u8, block.name, switch_term.default_target))
        {
            continue;
        }
        var matched_case = false;
        for (switch_term.cases.items) |case| {
            if (std.mem.eql(u8, block.name, case.target)) {
                matched_case = true;
                break;
            }
        }
        if (matched_case) continue;
        if (blockIsUnreachable(block)) continue;
        return false;
    }
    return true;
}

fn phiIncomingForBlock(phi: ir.PhiInst, block_name: []const u8) ?ir.Value {
    for (phi.incoming.items) |incoming| {
        if (std.mem.eql(u8, incoming.block, block_name)) return incoming.value;
    }
    return null;
}

fn firstNamedPhi(block: ir.BasicBlock) ?NamedPhi {
    if (block.instructions.items.len == 0) return null;
    const instruction = block.instructions.items[0];
    const name = instruction.result orelse return null;
    return .{
        .name = name,
        .phi = switch (instruction.kind) {
            .phi => |phi| phi,
            else => return null,
        },
    };
}

fn catchFallbackValue(function: ir.Function, value: ir.Value) ?ErrorUnionCatchFallbackValue {
    return switch (value) {
        .int => |int| .{ .int = i32Value(int) catch return null },
        .named => |name| {
            const reg = paramRegOrNull(function, name, .{ .int = 32 }) catch return null;
            return .{ .param = reg orelse return null };
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
    };
}

fn phiAddReturnImm(block: ir.BasicBlock, phi_name: []const u8) ?i32 {
    if (block.instructions.items.len != 2) return null;
    const add_name = block.instructions.items[1].result orelse return null;
    const add = switch (block.instructions.items[1].kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (!add.ty.eql(.{ .int = 32 }) or add.op != .add or !isNamed(add.lhs, phi_name)) return null;
    const imm = switch (add.rhs) {
        .int => |int| i32Value(int) catch return null,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return null, add_name)) return null;
    return imm;
}

fn catchValueMergeUsesOnlyExpectedBlocks(
    function: ir.Function,
    entry_name: []const u8,
    payload_name: []const u8,
    fallback_name: []const u8,
    merge_name: []const u8,
) bool {
    for (function.blocks.items) |block| {
        if (std.mem.eql(u8, block.name, entry_name) or
            std.mem.eql(u8, block.name, payload_name) or
            std.mem.eql(u8, block.name, fallback_name) or
            std.mem.eql(u8, block.name, merge_name))
        {
            continue;
        }
        if (!blockIsUnreachable(block)) return false;
    }
    return true;
}

fn switchPhiUsesAllBlocks(
    function: ir.Function,
    merge_block: []const u8,
    switch_term: ir.SwitchTerminator,
) bool {
    for (function.blocks.items, 0..) |block, index| {
        if (index == 0 or
            std.mem.eql(u8, block.name, merge_block) or
            std.mem.eql(u8, block.name, switch_term.default_target))
        {
            continue;
        }
        var matched_case = false;
        for (switch_term.cases.items) |case| {
            if (std.mem.eql(u8, block.name, case.target)) {
                matched_case = true;
                break;
            }
        }
        if (!matched_case) return false;
    }
    return true;
}

fn lowerGenericCfgErrorUnionTrySwitchReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = errorUnionTrySwitchReturn(function) orelse return false;
    const frame_bytes: u8 = 24;
    const epilogue_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_try_switch_{}_generic_cfg_select_end",
        .{machine.instructions.items.len},
    );

    try appendStackFrame(allocator, machine, frame_bytes);
    try emitTwoI32ArgCallIntoRax(allocator, machine, function, plan.entry, plan.call);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, .jne, plan.err_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, plan.switch_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 16 });
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot2 });
    if (plan.mask != 0) try machine.instructions.append(allocator, .{ .and_eax_imm32 = plan.mask });
    for (plan.cases[0..plan.case_count]) |case| {
        try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = case.value });
        try appendGenericCfgConditionalBranch(allocator, machine, .je, case.block.name);
    }
    try machine.instructions.append(allocator, .{ .jmp = plan.default_case.block.name });

    for (plan.cases[0..plan.case_count]) |case| {
        try appendGenericCfgBlockLabel(allocator, machine, case.block.name);
        try emitPayloadAddImmWrapFromSlot(allocator, machine, case.add_imm, epilogue_label);
    }
    try appendGenericCfgBlockLabel(allocator, machine, plan.default_case.block.name);
    try emitPayloadAddImmWrapFromSlot(allocator, machine, plan.default_case.add_imm, epilogue_label);

    try appendGenericCfgBlockLabel(allocator, machine, plan.err_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

fn emitPayloadAddImmWrapFromSlot(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    add_imm: u8,
    epilogue_label: []const u8,
) !void {
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot2 });
    if (add_imm != 0) try machine.instructions.append(allocator, .{ .add_rax_imm8 = add_imm });
    try machine.instructions.append(allocator, .{ .shl_rax_imm6 = 16 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });
}

const ErrorUnionTryPayloadBranchReturn = struct {
    entry: ir.BasicBlock,
    call_name: []const u8,
    call: ir.CallInst,
    err_block: ir.BasicBlock,
    cont_block: ir.BasicBlock,
    true_block: ir.BasicBlock,
    false_block: ir.BasicBlock,
    compare: PayloadGreaterConst,
    delta_reg: ArgReg,
    true_op: MachineBinaryOp,
    false_op: MachineBinaryOp,
};

const BranchThenErrorUnionTryReturn = struct {
    entry: ir.BasicBlock,
    try_block: ir.BasicBlock,
    direct_block: ir.BasicBlock,
    call_name: []const u8,
    call: ir.CallInst,
    success_block: ir.BasicBlock,
    err_block: ir.BasicBlock,
    success_add_imm: u8,
    try_is_then: bool,
    success_is_then: bool,
};

const BranchBothErrorUnionTryReturn = struct {
    entry: ir.BasicBlock,
    then_block: ir.BasicBlock,
    then_stage: BranchTryStage,
    else_block: ir.BasicBlock,
    else_stage: BranchTryStage,
};

const SwitchThenErrorUnionTryReturn = struct {
    entry: ir.BasicBlock,
    switch_term: ir.SwitchTerminator,
    direct_case: ErrorUnionSwitchPhiCase,
    try_block: ir.BasicBlock,
    call: ir.CallInst,
    success_block: ir.BasicBlock,
    err_block: ir.BasicBlock,
    success_add_imm: u8,
    success_is_then: bool,
};

const SwitchBothErrorUnionTryReturn = struct {
    entry: ir.BasicBlock,
    switch_term: ir.SwitchTerminator,
    case_block: ir.BasicBlock,
    case_stage: BranchTryStage,
    case_success_add_imm: u8,
    default_block: ir.BasicBlock,
    default_stage: BranchTryStage,
    default_success_add_imm: u8,
};

const ErrorUnionTrySwitchCase = struct {
    value: i32,
    block: ir.BasicBlock,
    add_imm: u8,
};

const ErrorUnionTrySwitchReturn = struct {
    entry: ir.BasicBlock,
    call_name: []const u8,
    call: ir.CallInst,
    err_block: ir.BasicBlock,
    switch_block: ir.BasicBlock,
    merge_block: ir.BasicBlock,
    mask: i32,
    cases: [8]ErrorUnionTrySwitchCase,
    case_count: usize,
    default_case: ErrorUnionTrySwitchCase,
};

fn lowerGenericCfgBranchBothErrorUnionTryReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = branchBothErrorUnionTryReturn(function) orelse return false;
    const frame_bytes: u8 = 8;
    const epilogue_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_branch_both_try_{}_generic_cfg_select_end",
        .{machine.instructions.items.len},
    );

    const entry_condbr = switch (plan.entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };

    try appendStackFrame(allocator, machine, frame_bytes);
    try emitGenericCfgTerminalConditionTrueBranch(allocator, machine, function, plan.entry, plan.entry, entry_condbr.cond, plan.then_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, plan.else_block.name);
    try emitErrorUnionTryStageToEpilogue(allocator, machine, function, plan.else_block, plan.else_stage, plan.else_stage.success_add_imm, epilogue_label);

    try appendGenericCfgBlockLabel(allocator, machine, plan.then_block.name);
    try emitErrorUnionTryStageToEpilogue(allocator, machine, function, plan.then_block, plan.then_stage, plan.then_stage.success_add_imm, epilogue_label);

    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

fn lowerGenericCfgBranchThenErrorUnionTryReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = branchThenErrorUnionTryReturn(function) orelse return false;
    const frame_bytes: u8 = 8;
    const epilogue_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_branch_then_try_{}_generic_cfg_select_end",
        .{machine.instructions.items.len},
    );

    const entry_condbr = switch (plan.entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };
    try emitGenericCfgTerminalConditionTrueBranch(allocator, machine, function, plan.entry, plan.entry, entry_condbr.cond, if (plan.try_is_then) plan.try_block.name else plan.direct_block.name);
    if (plan.try_is_then) {
        try emitGenericCfgTerminalReturnBlock(allocator, machine, function, plan.entry, plan.direct_block);
        try appendGenericCfgBlockLabel(allocator, machine, plan.try_block.name);
    }

    try appendStackFrame(allocator, machine, frame_bytes);
    const stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, plan.try_block, plan.call);
    if (stack_arg_count != 0) return error.UnsupportedLiveAcrossCall;
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = plan.call.callee, .ret_ty = plan.call.ret_ty } });
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, if (plan.success_is_then) .je else .jne, plan.success_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, plan.err_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, plan.success_block.name);
    try emitPayloadAddImmWrapFromCallSlot(allocator, machine, plan.success_add_imm, epilogue_label);

    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);

    if (!plan.try_is_then) {
        try appendGenericCfgBlockLabel(allocator, machine, plan.direct_block.name);
        try emitGenericCfgTerminalReturnBlock(allocator, machine, function, plan.entry, plan.direct_block);
    }
    return true;
}

fn emitErrorUnionTryStageToEpilogue(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    try_block: ir.BasicBlock,
    stage: BranchTryStage,
    success_add_imm: u8,
    epilogue_label: []const u8,
) !void {
    const stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, try_block, stage.call);
    if (stack_arg_count != 0) return error.UnsupportedLiveAcrossCall;
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = stage.call.callee, .ret_ty = stage.call.ret_ty } });
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, if (stage.success_is_then) .je else .jne, stage.success_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, stage.err_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, stage.success_block.name);
    try emitPayloadAddImmWrapFromCallSlot(allocator, machine, success_add_imm, epilogue_label);
}

fn lowerGenericCfgSwitchThenErrorUnionTryReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = switchThenErrorUnionTryReturn(function) orelse return false;
    const frame_bytes: u8 = 8;
    const epilogue_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_switch_then_try_{}_generic_cfg_select_end",
        .{machine.instructions.items.len},
    );

    try appendStackFrame(allocator, machine, frame_bytes);
    try emitSwitchThenTryCondition(allocator, machine, function, plan.entry, plan.switch_term);
    try appendGenericCfgConditionalBranch(allocator, machine, .je, plan.direct_case.block.name);
    try machine.instructions.append(allocator, .{ .jmp = plan.try_block.name });

    try appendGenericCfgBlockLabel(allocator, machine, plan.direct_case.block.name);
    try emitGenericCfgTerminalI64ValueIntoRax(allocator, machine, function, plan.entry, plan.direct_case.block, plan.direct_case.incoming);
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, plan.try_block.name);
    const stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, plan.try_block, plan.call);
    if (stack_arg_count != 0) return error.UnsupportedLiveAcrossCall;
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = plan.call.callee, .ret_ty = plan.call.ret_ty } });
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, if (plan.success_is_then) .je else .jne, plan.success_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, plan.err_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, plan.success_block.name);
    try emitPayloadAddImmWrapFromCallSlot(allocator, machine, plan.success_add_imm, epilogue_label);

    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

fn lowerGenericCfgSwitchBothErrorUnionTryReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = switchBothErrorUnionTryReturn(function) orelse return false;
    const frame_bytes: u8 = 8;
    const epilogue_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_switch_both_try_{}_generic_cfg_select_end",
        .{machine.instructions.items.len},
    );

    try appendStackFrame(allocator, machine, frame_bytes);
    try emitSwitchThenTryCondition(allocator, machine, function, plan.entry, plan.switch_term);
    try appendGenericCfgConditionalBranch(allocator, machine, .je, plan.case_block.name);
    try machine.instructions.append(allocator, .{ .jmp = plan.default_block.name });

    try appendGenericCfgBlockLabel(allocator, machine, plan.default_block.name);
    try emitErrorUnionTryStageToEpilogue(allocator, machine, function, plan.default_block, plan.default_stage, plan.default_success_add_imm, epilogue_label);

    try appendGenericCfgBlockLabel(allocator, machine, plan.case_block.name);
    try emitErrorUnionTryStageToEpilogue(allocator, machine, function, plan.case_block, plan.case_stage, plan.case_success_add_imm, epilogue_label);

    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

fn branchBothErrorUnionTryReturn(function: ir.Function) ?BranchBothErrorUnionTryReturn {
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.blocks.items.len != 7) return null;
    const entry = function.blocks.items[0];
    const entry_condbr = switch (entry.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!entry_condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const then_block = function.blocks.items[blockIndex(function, entry_condbr.then_target) orelse return null];
    const else_block = function.blocks.items[blockIndex(function, entry_condbr.else_target) orelse return null];
    const then_stage = branchTryStage(function, then_block) orelse return null;
    const else_stage = branchTryStage(function, else_block) orelse return null;
    if (!branchBothTryUsesAllBlocks(
        function,
        then_block.name,
        then_stage.success_block.name,
        then_stage.err_block.name,
        else_block.name,
        else_stage.success_block.name,
        else_stage.err_block.name,
    )) return null;

    return .{
        .entry = entry,
        .then_block = then_block,
        .then_stage = then_stage,
        .else_block = else_block,
        .else_stage = else_stage,
    };
}

fn switchBothErrorUnionTryReturn(function: ir.Function) ?SwitchBothErrorUnionTryReturn {
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.blocks.items.len != 8) return null;
    const entry = function.blocks.items[0];
    const switch_term = blockSwitchTerminator(entry) orelse return null;
    if (!switch_term.cond_ty.eql(.{ .int = 32 }) or switch_term.cases.items.len != 1) return null;
    const case = switch_term.cases.items[0];
    if (!case.value_ty.eql(.{ .int = 32 }) or !isInt(case.value, 0)) return null;
    if (switchMaskParamConst(function, entry, switch_term.cond) != 1) return null;

    const case_block = function.blocks.items[blockIndex(function, case.target) orelse return null];
    const default_block = function.blocks.items[blockIndex(function, switch_term.default_target) orelse return null];
    const case_stage = switchArmTryStage(function, case_block) orelse return null;
    const default_stage = switchArmTryStage(function, default_block) orelse return null;
    const merge_block = commonSwitchBothTryMergeBlock(function, case_stage.success_block, default_stage.success_block) orelse return null;
    const phi = firstPhiReturn(function, merge_block) orelse return null;
    if (!phi.ty.eql(.{ .int = 64 }) or phi.incoming.items.len != 2) return null;

    const case_incoming = phiIncomingForBlock(phi, case_stage.success_block.name) orelse return null;
    const default_incoming = phiIncomingForBlock(phi, default_stage.success_block.name) orelse return null;
    const case_success_add_imm = payloadAddWrapValue(case_stage.success_block, case_stage.success_block, case_incoming, case_stage.call_name) orelse return null;
    const default_success_add_imm = payloadAddWrapValue(default_stage.success_block, default_stage.success_block, default_incoming, default_stage.call_name) orelse return null;
    if (!switchBothTryUsesAllBlocks(
        function,
        case_block.name,
        case_stage.success_block.name,
        case_stage.err_block.name,
        default_block.name,
        default_stage.success_block.name,
        default_stage.err_block.name,
        merge_block.name,
    )) return null;

    return .{
        .entry = entry,
        .switch_term = switch_term,
        .case_block = case_block,
        .case_stage = case_stage,
        .case_success_add_imm = case_success_add_imm,
        .default_block = default_block,
        .default_stage = default_stage,
        .default_success_add_imm = default_success_add_imm,
    };
}

fn branchThenErrorUnionTryReturn(function: ir.Function) ?BranchThenErrorUnionTryReturn {
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.blocks.items.len != 5) return null;
    const entry = function.blocks.items[0];
    const entry_condbr = switch (entry.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!entry_condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const then_block = function.blocks.items[blockIndex(function, entry_condbr.then_target) orelse return null];
    const else_block = function.blocks.items[blockIndex(function, entry_condbr.else_target) orelse return null];
    const then_try = branchTryStage(function, then_block);
    const else_try = branchTryStage(function, else_block);
    if ((then_try != null) == (else_try != null)) return null;
    const try_stage = then_try orelse else_try.?;
    const try_block = if (then_try != null) then_block else else_block;
    const direct_block = if (then_try != null) else_block else then_block;
    if (!genericCfgSupportsTerminalReturnBlock(function, entry, direct_block)) return null;
    if (!branchThenTryUsesAllBlocks(function, try_block.name, direct_block.name, try_stage.success_block.name, try_stage.err_block.name)) return null;

    return .{
        .entry = entry,
        .try_block = try_block,
        .direct_block = direct_block,
        .call_name = try_stage.call_name,
        .call = try_stage.call,
        .success_block = try_stage.success_block,
        .err_block = try_stage.err_block,
        .success_add_imm = try_stage.success_add_imm,
        .try_is_then = then_try != null,
        .success_is_then = try_stage.success_is_then,
    };
}

fn switchThenErrorUnionTryReturn(function: ir.Function) ?SwitchThenErrorUnionTryReturn {
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.blocks.items.len != 6) return null;
    const entry = function.blocks.items[0];
    const switch_term = blockSwitchTerminator(entry) orelse return null;
    if (!switch_term.cond_ty.eql(.{ .int = 32 }) or switch_term.cases.items.len != 1) return null;
    const case = switch_term.cases.items[0];
    if (!case.value_ty.eql(.{ .int = 32 }) or !isInt(case.value, 0)) return null;
    if (switchMaskParamConst(function, entry, switch_term.cond) != 1) return null;

    const direct_block = function.blocks.items[blockIndex(function, case.target) orelse return null];
    const try_block = function.blocks.items[blockIndex(function, switch_term.default_target) orelse return null];
    const try_stage = switchArmTryStage(function, try_block) orelse return null;
    const merge_block = commonSwitchTryMergeBlock(function, direct_block, try_stage.success_block) orelse return null;
    const phi = firstPhiReturn(function, merge_block) orelse return null;
    if (!phi.ty.eql(.{ .int = 64 }) or phi.incoming.items.len != 2) return null;

    const direct_incoming = phiIncomingForBlock(phi, direct_block.name) orelse return null;
    if (!blockBranchesTo(direct_block, merge_block.name)) return null;
    if (!blockBranchesTo(try_stage.success_block, merge_block.name)) return null;
    const success_incoming = phiIncomingForBlock(phi, try_stage.success_block.name) orelse return null;
    const success_add_imm = payloadAddWrapValue(try_stage.success_block, try_stage.success_block, success_incoming, try_stage.call_name) orelse return null;
    if (!switchThenTryUsesAllBlocks(function, direct_block.name, try_block.name, try_stage.success_block.name, try_stage.err_block.name, merge_block.name)) return null;

    return .{
        .entry = entry,
        .switch_term = switch_term,
        .direct_case = .{ .value = 0, .block = direct_block, .incoming = direct_incoming },
        .try_block = try_block,
        .call = try_stage.call,
        .success_block = try_stage.success_block,
        .err_block = try_stage.err_block,
        .success_add_imm = success_add_imm,
        .success_is_then = try_stage.success_is_then,
    };
}

fn switchArmTryStage(function: ir.Function, block: ir.BasicBlock) ?BranchTryStage {
    const condbr = switch (block.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const call_name = errorUnionTryGuardCallResult(block, condbr.cond) orelse return null;
    const call_instruction = findInstruction(block, call_name) orelse return null;
    const call = switch (call_instruction.kind) {
        .call => |call| call,
        else => return null,
    };
    if (!supportsDirectI64Call(call)) return null;

    const then_block = function.blocks.items[blockIndex(function, condbr.then_target) orelse return null];
    const else_block = function.blocks.items[blockIndex(function, condbr.else_target) orelse return null];
    const then_is_success = singleBrTarget(then_block) != null;
    const else_is_success = singleBrTarget(else_block) != null;
    if (then_is_success == else_is_success) return null;
    const success_block = if (then_is_success) then_block else else_block;
    const err_block = if (then_is_success) else_block else then_block;
    if (!blockReturnsNamedValue(err_block, call_name, .{ .int = 64 })) return null;
    return .{
        .call_name = call_name,
        .call = call,
        .success_block = success_block,
        .err_block = err_block,
        .success_add_imm = 0,
        .success_is_then = then_is_success,
    };
}

fn switchMaskParamConst(function: ir.Function, block: ir.BasicBlock, value: ir.Value) ?i32 {
    const name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const instruction = findInstruction(block, name) orelse return null;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (!binary.ty.eql(.{ .int = 32 }) or binary.op != .@"and") return null;
    const lhs_name = switch (binary.lhs) {
        .named => |lhs_name| lhs_name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if ((paramRegOrNull(function, lhs_name, .{ .int = 32 }) catch null) == null) return null;
    return switch (binary.rhs) {
        .int => |int| i32Value(int) catch null,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
    };
}

fn emitSwitchThenTryCondition(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    switch_term: ir.SwitchTerminator,
) !void {
    const cond_name = switch (switch_term.cond) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    const instruction = findInstruction(block, cond_name) orelse return error.UnsupportedCodegenValue;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!binary.ty.eql(.{ .int = 32 }) or binary.op != .@"and") return error.UnsupportedCodegenInstruction;
    const lhs_name = switch (binary.lhs) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    const reg = try paramReg(function, lhs_name, .{ .int = 32 });
    const rhs = switch (binary.rhs) {
        .int => |int| try i32Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
    if (rhs != 0) try machine.instructions.append(allocator, .{ .and_eax_imm32 = rhs });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 0 });
}

fn commonSwitchTryMergeBlock(function: ir.Function, direct_block: ir.BasicBlock, success_block: ir.BasicBlock) ?ir.BasicBlock {
    const direct_target = singleBrTarget(direct_block) orelse return null;
    const success_target = singleBrTarget(success_block) orelse return null;
    if (!std.mem.eql(u8, direct_target, success_target)) return null;
    return function.blocks.items[blockIndex(function, direct_target) orelse return null];
}

fn commonSwitchBothTryMergeBlock(function: ir.Function, case_success_block: ir.BasicBlock, default_success_block: ir.BasicBlock) ?ir.BasicBlock {
    const case_target = singleBrTarget(case_success_block) orelse return null;
    const default_target = singleBrTarget(default_success_block) orelse return null;
    if (!std.mem.eql(u8, case_target, default_target)) return null;
    return function.blocks.items[blockIndex(function, case_target) orelse return null];
}

fn switchThenTryUsesAllBlocks(
    function: ir.Function,
    direct_block: []const u8,
    try_block: []const u8,
    success_block: []const u8,
    err_block: []const u8,
    merge_block: []const u8,
) bool {
    for (function.blocks.items, 0..) |block, index| {
        if (index == 0 or
            std.mem.eql(u8, block.name, direct_block) or
            std.mem.eql(u8, block.name, try_block) or
            std.mem.eql(u8, block.name, success_block) or
            std.mem.eql(u8, block.name, err_block) or
            std.mem.eql(u8, block.name, merge_block))
        {
            continue;
        }
        return false;
    }
    return true;
}

const BranchTryStage = struct {
    call_name: []const u8,
    call: ir.CallInst,
    success_block: ir.BasicBlock,
    err_block: ir.BasicBlock,
    success_add_imm: u8,
    success_is_then: bool,
};

fn branchTryStage(function: ir.Function, block: ir.BasicBlock) ?BranchTryStage {
    const condbr = switch (block.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const call_name = errorUnionTryGuardCallResult(block, condbr.cond) orelse return null;
    const call_instruction = findInstruction(block, call_name) orelse return null;
    const call = switch (call_instruction.kind) {
        .call => |call| call,
        else => return null,
    };
    if (!supportsDirectI64Call(call)) return null;

    const then_block = function.blocks.items[blockIndex(function, condbr.then_target) orelse return null];
    const else_block = function.blocks.items[blockIndex(function, condbr.else_target) orelse return null];
    const then_success = successReturnPayloadAdd(then_block, call_name);
    const else_success = successReturnPayloadAdd(else_block, call_name);
    if ((then_success != null) == (else_success != null)) return null;
    const success_block = if (then_success != null) then_block else else_block;
    const err_block = if (then_success != null) else_block else then_block;
    if (!blockReturnsNamedValue(err_block, call_name, .{ .int = 64 })) return null;
    return .{
        .call_name = call_name,
        .call = call,
        .success_block = success_block,
        .err_block = err_block,
        .success_add_imm = then_success orelse else_success.?,
        .success_is_then = then_success != null,
    };
}

fn branchThenTryUsesAllBlocks(
    function: ir.Function,
    try_block: []const u8,
    direct_block: []const u8,
    success_block: []const u8,
    err_block: []const u8,
) bool {
    for (function.blocks.items, 0..) |block, index| {
        if (index == 0 or
            std.mem.eql(u8, block.name, try_block) or
            std.mem.eql(u8, block.name, direct_block) or
            std.mem.eql(u8, block.name, success_block) or
            std.mem.eql(u8, block.name, err_block))
        {
            continue;
        }
        return false;
    }
    return true;
}

fn branchBothTryUsesAllBlocks(
    function: ir.Function,
    then_block: []const u8,
    then_success: []const u8,
    then_err: []const u8,
    else_block: []const u8,
    else_success: []const u8,
    else_err: []const u8,
) bool {
    for (function.blocks.items, 0..) |block, index| {
        if (index == 0 or
            std.mem.eql(u8, block.name, then_block) or
            std.mem.eql(u8, block.name, then_success) or
            std.mem.eql(u8, block.name, then_err) or
            std.mem.eql(u8, block.name, else_block) or
            std.mem.eql(u8, block.name, else_success) or
            std.mem.eql(u8, block.name, else_err))
        {
            continue;
        }
        return false;
    }
    return true;
}

fn switchBothTryUsesAllBlocks(
    function: ir.Function,
    case_block: []const u8,
    case_success: []const u8,
    case_err: []const u8,
    default_block: []const u8,
    default_success: []const u8,
    default_err: []const u8,
    merge_block: []const u8,
) bool {
    for (function.blocks.items, 0..) |block, index| {
        if (index == 0 or
            std.mem.eql(u8, block.name, case_block) or
            std.mem.eql(u8, block.name, case_success) or
            std.mem.eql(u8, block.name, case_err) or
            std.mem.eql(u8, block.name, default_block) or
            std.mem.eql(u8, block.name, default_success) or
            std.mem.eql(u8, block.name, default_err) or
            std.mem.eql(u8, block.name, merge_block))
        {
            continue;
        }
        return false;
    }
    return true;
}

fn emitPayloadAddImmWrapFromCallSlot(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    add_imm: u8,
    epilogue_label: []const u8,
) !void {
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 16 });
    if (add_imm != 0) try machine.instructions.append(allocator, .{ .add_rax_imm8 = add_imm });
    try machine.instructions.append(allocator, .{ .shl_rax_imm6 = 16 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });
}

fn errorUnionTrySwitchReturn(function: ir.Function) ?ErrorUnionTrySwitchReturn {
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.blocks.items.len < 6) return null;
    const entry = function.blocks.items[0];
    const entry_condbr = switch (entry.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!entry_condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const call_name = errorUnionTryGuardCallResult(entry, entry_condbr.cond) orelse return null;
    const call_instruction = findInstruction(entry, call_name) orelse return null;
    const call = switch (call_instruction.kind) {
        .call => |call| call,
        else => return null,
    };
    if (!supportsDirectI64Call(call) or call.args.items.len != 2) return null;

    const then_block = function.blocks.items[blockIndex(function, entry_condbr.then_target) orelse return null];
    const else_block = function.blocks.items[blockIndex(function, entry_condbr.else_target) orelse return null];
    const then_is_switch = blockSwitchTerminator(then_block) != null;
    const else_is_switch = blockSwitchTerminator(else_block) != null;
    if (then_is_switch == else_is_switch) return null;
    const switch_block = if (then_is_switch) then_block else else_block;
    const err_block = if (then_is_switch) else_block else then_block;
    if (!blockReturnsNamedValue(err_block, call_name, .{ .int = 64 })) return null;

    const switch_term = blockSwitchTerminator(switch_block) orelse return null;
    if (!switch_term.cond_ty.eql(.{ .int = 32 })) return null;
    const mask = payloadMaskConst(switch_block, switch_term.cond, call_name) orelse return null;
    if (switch_term.cases.items.len == 0 or switch_term.cases.items.len > 8) return null;
    const merge_block = commonSwitchMergeBlock(function, switch_term) orelse return null;
    const phi = firstPhiReturn(function, merge_block) orelse return null;
    if (!phi.ty.eql(.{ .int = 64 })) return null;

    var cases: [8]ErrorUnionTrySwitchCase = undefined;
    for (switch_term.cases.items, 0..) |case, case_index| {
        if (!case.value_ty.eql(.{ .int = 32 })) return null;
        const value = switch (case.value) {
            .int => |int| i32Value(int) catch return null,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
        };
        const block = function.blocks.items[blockIndex(function, case.target) orelse return null];
        if (!blockBranchesTo(block, merge_block.name)) return null;
        cases[case_index] = .{
            .value = value,
            .block = block,
            .add_imm = payloadAddWrapPhiIncoming(function, switch_block, merge_block, phi, block.name, call_name) orelse return null,
        };
    }
    const default_block = function.blocks.items[blockIndex(function, switch_term.default_target) orelse return null];
    if (!blockBranchesTo(default_block, merge_block.name)) return null;
    const default_case: ErrorUnionTrySwitchCase = .{
        .value = 0,
        .block = default_block,
        .add_imm = payloadAddWrapPhiIncoming(function, switch_block, merge_block, phi, default_block.name, call_name) orelse return null,
    };
    if (!trySwitchUsesAllBlocks(function, switch_block.name, err_block.name, merge_block.name, switch_term)) return null;

    return .{
        .entry = entry,
        .call_name = call_name,
        .call = call,
        .err_block = err_block,
        .switch_block = switch_block,
        .merge_block = merge_block,
        .mask = mask,
        .cases = cases,
        .case_count = switch_term.cases.items.len,
        .default_case = default_case,
    };
}

fn blockSwitchTerminator(block: ir.BasicBlock) ?ir.SwitchTerminator {
    return switch (block.terminator orelse return null) {
        .@"switch" => |switch_term| switch_term,
        else => null,
    };
}

fn commonSwitchMergeBlock(function: ir.Function, switch_term: ir.SwitchTerminator) ?ir.BasicBlock {
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

fn firstPhiReturn(function: ir.Function, block: ir.BasicBlock) ?ir.PhiInst {
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

fn blockBranchesTo(block: ir.BasicBlock, target: []const u8) bool {
    const branch_target = singleBrTarget(block) orelse return false;
    return std.mem.eql(u8, branch_target, target);
}

fn payloadMaskConst(block: ir.BasicBlock, value: ir.Value, call_name: []const u8) ?i32 {
    const mask_name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const mask_inst = findInstruction(block, mask_name) orelse return null;
    const mask = switch (mask_inst.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (!mask.ty.eql(.{ .int = 32 }) or mask.op != .@"and") return null;
    const rhs = switch (mask.rhs) {
        .int => |int| i32Value(int) catch return null,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!payloadValueFromCallResult(block, mask.lhs, call_name)) return null;
    return rhs;
}

fn payloadAddWrapPhiIncoming(
    function: ir.Function,
    payload_scope: ir.BasicBlock,
    merge_block: ir.BasicBlock,
    phi: ir.PhiInst,
    predecessor: []const u8,
    call_name: []const u8,
) ?u8 {
    _ = merge_block;
    for (phi.incoming.items) |incoming| {
        if (!std.mem.eql(u8, incoming.block, predecessor)) continue;
        const value_block = blockByName(function, predecessor) orelse return null;
        return payloadAddWrapValue(value_block, payload_scope, incoming.value, call_name);
    }
    return null;
}

fn payloadAddWrapValue(value_block: ir.BasicBlock, payload_scope: ir.BasicBlock, value: ir.Value, call_name: []const u8) ?u8 {
    const shl_name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const shl_inst = findInstruction(value_block, shl_name) orelse return null;
    const shl = switch (shl_inst.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (!shl.ty.eql(.{ .int = 64 }) or shl.op != .shl or !isInt(shl.rhs, 16)) return null;
    const zext_name = switch (shl.lhs) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const zext_inst = findInstruction(value_block, zext_name) orelse return null;
    const zext = switch (zext_inst.kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 32 }) or !zext.to_ty.eql(.{ .int = 64 })) return null;
    const add_name = switch (zext.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const add_inst = findInstruction(value_block, add_name) orelse return null;
    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (!add.ty.eql(.{ .int = 32 }) or add.op != .add) return null;
    const rhs = switch (add.rhs) {
        .int => |int| i32Value(int) catch return null,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (rhs < 0 or rhs > std.math.maxInt(u8)) return null;
    if (!payloadValueFromCallResult(payload_scope, add.lhs, call_name)) return null;
    return @intCast(rhs);
}

fn trySwitchUsesAllBlocks(
    function: ir.Function,
    switch_block: []const u8,
    err_block: []const u8,
    merge_block: []const u8,
    switch_term: ir.SwitchTerminator,
) bool {
    for (function.blocks.items, 0..) |block, index| {
        if (index == 0 or
            std.mem.eql(u8, block.name, switch_block) or
            std.mem.eql(u8, block.name, err_block) or
            std.mem.eql(u8, block.name, merge_block) or
            std.mem.eql(u8, block.name, switch_term.default_target))
        {
            continue;
        }
        var matched_case = false;
        for (switch_term.cases.items) |case| {
            if (std.mem.eql(u8, block.name, case.target)) {
                matched_case = true;
                break;
            }
        }
        if (!matched_case) return false;
    }
    return true;
}

const ErrorUnionTryPayloadCallReturn = struct {
    entry: ir.BasicBlock,
    call_name: []const u8,
    call: ir.CallInst,
    cont_block: ir.BasicBlock,
    err_block: ir.BasicBlock,
    payload_call: ir.CallInst,
    payload_call_args: [2]TryPayloadCallArg,
    live_arg_reg: ArgReg,
    success_is_then: bool,
};

const ErrorUnionTryPhiSlotOverrideReturn = struct {
    entry: ir.BasicBlock,
    call_name: []const u8,
    call: ir.CallInst,
    phi_name: []const u8,
    override_error: i64,
    condition_reg: ArgReg,
    branch_to_after_override: core_cfg_emit.GenericCfgBranchKind,
    cont_block: ir.BasicBlock,
    err_block: ir.BasicBlock,
    payload_add_imm: u8,
    success_is_then: bool,
};

const TryPayloadCallArg = union(enum) {
    payload,
    param: ArgReg,
};

fn lowerGenericCfgErrorUnionTryPayloadCallReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = errorUnionTryPayloadCallReturn(function) orelse return false;
    const frame_bytes: u8 = 24;
    const epilogue_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_try_payload_call_{}_generic_cfg_select_end",
        .{machine.instructions.items.len},
    );

    try appendStackFrame(allocator, machine, frame_bytes);
    try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{ .frame_index = .slot2, .reg = plan.live_arg_reg } });
    try emitTwoI32ArgCallIntoRax(allocator, machine, function, plan.entry, plan.call);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, if (plan.success_is_then) .je else .jne, plan.cont_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, plan.err_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, plan.cont_block.name);
    try emitTryPayloadCallArg(allocator, machine, .rdi, plan.payload_call_args[0]);
    try emitTryPayloadCallArg(allocator, machine, .rsi, plan.payload_call_args[1]);
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = plan.payload_call.callee, .ret_ty = plan.payload_call.ret_ty } });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = -1 });
    try machine.instructions.append(allocator, .{ .shl_rax_imm6 = 16 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

fn lowerGenericCfgErrorUnionTryPhiSlotOverrideReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = errorUnionTryPhiSlotOverrideReturn(function) orelse return false;
    const frame_bytes: u8 = 24;
    const after_override_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_try_phi_override_{}_after_override",
        .{machine.instructions.items.len},
    );
    const epilogue_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_try_phi_override_{}_generic_cfg_select_end",
        .{machine.instructions.items.len},
    );

    try appendStackFrame(allocator, machine, frame_bytes);
    try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{ .frame_index = .slot2, .reg = plan.condition_reg } });
    try emitTwoI32ArgCallIntoRax(allocator, machine, function, plan.entry, plan.call);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });

    try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{ .frame_index = .slot2, .reg = .rcx } });
    try machine.instructions.append(allocator, .{ .test_arg32 = .rcx });
    try appendGenericCfgConditionalBranch(allocator, machine, plan.branch_to_after_override, after_override_label);
    try machine.instructions.append(allocator, .{ .mov_imm_rax = plan.override_error });
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    try appendGenericCfgBlockLabel(allocator, machine, after_override_label);

    try appendGenericCfgBlockLabel(allocator, machine, "generic_cfg_try_phi_override_guard");
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, if (plan.success_is_then) .je else .jne, plan.cont_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, plan.err_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, plan.cont_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 16 });
    if (plan.payload_add_imm != 0) try machine.instructions.append(allocator, .{ .add_rax_imm8 = plan.payload_add_imm });
    try machine.instructions.append(allocator, .{ .shl_rax_imm6 = 16 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

fn emitTryPayloadCallArg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    dst: ArgReg,
    arg: TryPayloadCallArg,
) !void {
    switch (arg) {
        .payload => {
            try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
            try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 16 });
            try emitRaxIntoArgReg(allocator, machine, dst);
        },
        .param => try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{ .frame_index = .slot2, .reg = dst } }),
    }
}

fn errorUnionTryPhiSlotOverrideReturn(function: ir.Function) ?ErrorUnionTryPhiSlotOverrideReturn {
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.blocks.items.len != 6) return null;
    const entry = function.blocks.items[0];
    const entry_condbr = switch (entry.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!entry_condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const condition = branchConditionParamReg(function, entry, entry_condbr.cond) orelse return null;

    const then_block = function.blocks.items[blockIndex(function, entry_condbr.then_target) orelse return null];
    const else_block = function.blocks.items[blockIndex(function, entry_condbr.else_target) orelse return null];
    if (then_block.instructions.items.len != 0 or else_block.instructions.items.len != 0) return null;
    const merge_name = singleBrTarget(then_block) orelse return null;
    if (!std.mem.eql(u8, singleBrTarget(else_block) orelse return null, merge_name)) return null;
    const merge_block = function.blocks.items[blockIndex(function, merge_name) orelse return null];
    const merge_condbr = switch (merge_block.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!merge_condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const phi_name = errorUnionTryGuardCallResult(merge_block, merge_condbr.cond) orelse return null;
    const phi_instruction = findInstruction(merge_block, phi_name) orelse return null;
    const phi = switch (phi_instruction.kind) {
        .phi => |phi| phi,
        else => return null,
    };
    if (!phi.ty.eql(.{ .int = 64 }) or phi.incoming.items.len != 2) return null;

    var call_name: ?[]const u8 = null;
    var override_error: ?i64 = null;
    var override_block: ?[]const u8 = null;
    for (phi.incoming.items) |incoming| {
        if (!std.mem.eql(u8, incoming.block, then_block.name) and !std.mem.eql(u8, incoming.block, else_block.name)) return null;
        switch (incoming.value) {
            .named => |name| {
                if (call_name != null) return null;
                call_name = name;
            },
            .int => |int| {
                if (override_error != null) return null;
                const value = i64Value(int) catch return null;
                if (value <= 0 or value > 65535) return null;
                override_error = value;
                override_block = incoming.block;
            },
            .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
        }
    }
    const call_result_name = call_name orelse return null;
    const call_instruction = findInstruction(entry, call_result_name) orelse return null;
    const call = switch (call_instruction.kind) {
        .call => |call| call,
        else => return null,
    };
    if (!supportsDirectI64Call(call) or call.args.items.len != 2) return null;

    const then_success = successReturnPayloadAdd(function.blocks.items[blockIndex(function, merge_condbr.then_target) orelse return null], phi_name);
    const else_success = successReturnPayloadAdd(function.blocks.items[blockIndex(function, merge_condbr.else_target) orelse return null], phi_name);
    if ((then_success != null) == (else_success != null)) return null;
    const cont_block = if (then_success != null)
        function.blocks.items[blockIndex(function, merge_condbr.then_target) orelse return null]
    else
        function.blocks.items[blockIndex(function, merge_condbr.else_target) orelse return null];
    const err_block = if (then_success != null)
        function.blocks.items[blockIndex(function, merge_condbr.else_target) orelse return null]
    else
        function.blocks.items[blockIndex(function, merge_condbr.then_target) orelse return null];
    if (!blockReturnsNamedValue(err_block, phi_name, .{ .int = 64 })) return null;

    const override_is_then = std.mem.eql(u8, override_block orelse return null, then_block.name);
    return .{
        .entry = entry,
        .call_name = call_result_name,
        .call = call,
        .phi_name = phi_name,
        .override_error = override_error orelse return null,
        .condition_reg = condition.reg,
        .branch_to_after_override = branchKindToSkipOverride(condition.predicate, override_is_then) orelse return null,
        .cont_block = cont_block,
        .err_block = err_block,
        .payload_add_imm = then_success orelse else_success.?,
        .success_is_then = then_success != null,
    };
}

fn errorUnionTryPayloadCallReturn(function: ir.Function) ?ErrorUnionTryPayloadCallReturn {
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.blocks.items.len != 3) return null;
    const entry = function.blocks.items[0];
    const entry_condbr = switch (entry.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!entry_condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const call_name = errorUnionTryGuardCallResult(entry, entry_condbr.cond) orelse return null;
    const call_instruction = findInstruction(entry, call_name) orelse return null;
    const call = switch (call_instruction.kind) {
        .call => |call| call,
        else => return null,
    };
    if (!supportsDirectI64Call(call) or call.args.items.len != 2) return null;

    const then_block = function.blocks.items[blockIndex(function, entry_condbr.then_target) orelse return null];
    const else_block = function.blocks.items[blockIndex(function, entry_condbr.else_target) orelse return null];
    const then_payload_call = payloadCallWrapReturn(function, then_block, call_name);
    const else_payload_call = payloadCallWrapReturn(function, else_block, call_name);
    if ((then_payload_call != null) == (else_payload_call != null)) return null;
    const cont_block = if (then_payload_call != null) then_block else else_block;
    const err_block = if (then_payload_call != null) else_block else then_block;
    if (!blockReturnsNamedValue(err_block, call_name, .{ .int = 64 })) return null;
    const payload_call = then_payload_call orelse else_payload_call.?;

    return .{
        .entry = entry,
        .call_name = call_name,
        .call = call,
        .cont_block = cont_block,
        .err_block = err_block,
        .payload_call = payload_call.call,
        .payload_call_args = payload_call.args,
        .live_arg_reg = payload_call.live_arg_reg,
        .success_is_then = then_payload_call != null,
    };
}

const PayloadCallWrapReturn = struct {
    call: ir.CallInst,
    args: [2]TryPayloadCallArg,
    live_arg_reg: ArgReg,
};

fn payloadCallWrapReturn(function: ir.Function, block: ir.BasicBlock, call_name: []const u8) ?PayloadCallWrapReturn {
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 64 })) return null;
    const shl_name = switch (ret.value orelse return null) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const shl_inst = findInstruction(block, shl_name) orelse return null;
    const shl = switch (shl_inst.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (!shl.ty.eql(.{ .int = 64 }) or shl.op != .shl or !isInt(shl.rhs, 16)) return null;
    const zext_name = switch (shl.lhs) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const zext_inst = findInstruction(block, zext_name) orelse return null;
    const zext = switch (zext_inst.kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 32 }) or !zext.to_ty.eql(.{ .int = 64 })) return null;
    const payload_call_name = switch (zext.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const payload_call_inst = findInstruction(block, payload_call_name) orelse return null;
    const payload_call = switch (payload_call_inst.kind) {
        .call => |call| call,
        else => return null,
    };
    if (!supportsDirectI32Call(payload_call) or payload_call.args.items.len != 2) return null;

    var args: [2]TryPayloadCallArg = undefined;
    var payload_arg_count: usize = 0;
    var live_arg_reg: ?ArgReg = null;
    for (payload_call.args.items, 0..) |arg, index| {
        if (!arg.ty.eql(.{ .int = 32 })) return null;
        if (payloadValueFromCallResult(block, arg.value, call_name)) {
            args[index] = .payload;
            payload_arg_count += 1;
            continue;
        }
        const reg = switch (arg.value) {
            .named => |name| paramReg(function, name, .{ .int = 32 }) catch return null,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
        };
        if (live_arg_reg != null and live_arg_reg.? != reg) return null;
        live_arg_reg = reg;
        args[index] = .{ .param = reg };
    }
    if (payload_arg_count != 1) return null;
    return .{ .call = payload_call, .args = args, .live_arg_reg = live_arg_reg orelse return null };
}

fn lowerGenericCfgErrorUnionTryPayloadBranchReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = errorUnionTryPayloadBranchReturn(function) orelse return false;
    const frame_bytes: u8 = 24;
    const epilogue_label = try ownedMachineLabel(
        allocator,
        machine,
        "generic_cfg_try_payload_branch_{}_generic_cfg_select_end",
        .{machine.instructions.items.len},
    );

    try appendStackFrame(allocator, machine, frame_bytes);
    try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{ .frame_index = .slot2, .reg = plan.delta_reg } });

    try emitTwoI32ArgCallIntoRax(allocator, machine, function, plan.entry, plan.call);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 65535 });
    try machine.instructions.append(allocator, .test_eax_eax);
    try appendGenericCfgConditionalBranch(allocator, machine, .jne, plan.err_block.name);

    try appendGenericCfgBlockLabel(allocator, machine, plan.cont_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 16 });
    switch (plan.compare) {
        .signed_gt => |imm| {
            try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = imm });
            try machine.instructions.append(allocator, .{ .jle = plan.false_block.name });

            try appendGenericCfgBlockLabel(allocator, machine, plan.true_block.name);
            try emitPayloadBinaryWrapReturn(allocator, machine, plan.true_op, plan.delta_reg, epilogue_label);

            try appendGenericCfgBlockLabel(allocator, machine, plan.false_block.name);
            try emitPayloadBinaryWrapReturn(allocator, machine, plan.false_op, plan.delta_reg, epilogue_label);
        },
        .unsigned_gt => |imm| {
            if (imm == std.math.maxInt(i32)) return error.UnsupportedCodegenControlFlow;
            try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = imm + 1 });
            try machine.instructions.append(allocator, .{ .jae = plan.true_block.name });

            try appendGenericCfgBlockLabel(allocator, machine, plan.false_block.name);
            try emitPayloadBinaryWrapReturn(allocator, machine, plan.false_op, plan.delta_reg, epilogue_label);

            try appendGenericCfgBlockLabel(allocator, machine, plan.true_block.name);
            try emitPayloadBinaryWrapReturn(allocator, machine, plan.true_op, plan.delta_reg, epilogue_label);
        },
    }

    try appendGenericCfgBlockLabel(allocator, machine, plan.err_block.name);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });

    try appendGenericCfgBlockLabel(allocator, machine, epilogue_label);
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

fn emitPayloadBinaryWrapReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    op: MachineBinaryOp,
    delta_reg: ArgReg,
    epilogue_label: []const u8,
) !void {
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 16 });
    try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{ .frame_index = .slot2, .reg = delta_reg } });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = op, .reg = delta_reg } });
    try machine.instructions.append(allocator, .{ .shl_rax_imm6 = 16 });
    try machine.instructions.append(allocator, .{ .jmp = epilogue_label });
}

fn errorUnionTryPayloadBranchReturn(function: ir.Function) ?ErrorUnionTryPayloadBranchReturn {
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.blocks.items.len != 5) return null;
    const entry = function.blocks.items[0];
    const entry_condbr = switch (entry.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!entry_condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const call_name = errorUnionTryGuardCallResult(entry, entry_condbr.cond) orelse return null;
    const call_instruction = findInstruction(entry, call_name) orelse return null;
    const call = switch (call_instruction.kind) {
        .call => |call| call,
        else => return null,
    };
    if (!supportsDirectI64Call(call) or call.args.items.len != 2) return null;

    const then_block = function.blocks.items[blockIndex(function, entry_condbr.then_target) orelse return null];
    const else_block = function.blocks.items[blockIndex(function, entry_condbr.else_target) orelse return null];
    const then_is_cont = blockHasCondbr(then_block);
    const else_is_cont = blockHasCondbr(else_block);
    if (then_is_cont == else_is_cont) return null;
    const cont_block = if (then_is_cont) then_block else else_block;
    const err_block = if (then_is_cont) else_block else then_block;
    if (!blockReturnsNamedValue(err_block, call_name, .{ .int = 64 })) return null;

    const cont_condbr = switch (cont_block.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!cont_condbr.cond_ty.eql(.{ .int = 1 })) return null;
    const compare = payloadGreaterConst(function, cont_block, cont_condbr.cond, call_name) orelse return null;
    const true_block = function.blocks.items[blockIndex(function, cont_condbr.then_target) orelse return null];
    const false_block = function.blocks.items[blockIndex(function, cont_condbr.else_target) orelse return null];
    const true_return = payloadBinaryWrapReturn(function, cont_block, true_block, call_name) orelse return null;
    const false_return = payloadBinaryWrapReturn(function, cont_block, false_block, call_name) orelse return null;
    if (true_return.reg != false_return.reg) return null;
    if (!linearTerminalBranchUsesAllBlocks(
        function,
        blockIndex(function, cont_block.name) orelse return null,
        blockIndex(function, err_block.name) orelse return null,
        blockIndex(function, true_block.name) orelse return null,
        blockIndex(function, false_block.name) orelse return null,
    )) return null;

    return .{
        .entry = entry,
        .call_name = call_name,
        .call = call,
        .err_block = err_block,
        .cont_block = cont_block,
        .true_block = true_block,
        .false_block = false_block,
        .compare = compare,
        .delta_reg = true_return.reg,
        .true_op = true_return.op,
        .false_op = false_return.op,
    };
}

fn payloadGreaterConst(function: ir.Function, block: ir.BasicBlock, cond: ir.Value, call_name: []const u8) ?PayloadGreaterConst {
    _ = function;
    const cond_name = switch (cond) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const cond_inst = findInstruction(block, cond_name) orelse return null;
    const icmp = switch (cond_inst.kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (!icmp.operand_ty.eql(.{ .int = 32 })) return null;
    const predicate: PayloadGreaterConstPredicate = switch (icmp.predicate) {
        .sgt => .signed_gt,
        .ugt => .unsigned_gt,
        else => return null,
    };
    const rhs = switch (icmp.rhs) {
        .int => |int| i32Value(int) catch return null,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!payloadValueFromCallResult(block, icmp.lhs, call_name)) return null;
    return switch (predicate) {
        .signed_gt => .{ .signed_gt = rhs },
        .unsigned_gt => .{ .unsigned_gt = rhs },
    };
}

const PayloadGreaterConstPredicate = enum {
    signed_gt,
    unsigned_gt,
};

const PayloadGreaterConst = union(PayloadGreaterConstPredicate) {
    signed_gt: i32,
    unsigned_gt: i32,
};

const PayloadBinaryWrapReturn = error_union_rows.PayloadBinaryWrapReturn;

fn payloadBinaryWrapReturn(function: ir.Function, payload_scope: ir.BasicBlock, block: ir.BasicBlock, call_name: []const u8) ?PayloadBinaryWrapReturn {
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 64 })) return null;
    const shl_name = switch (ret.value orelse return null) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const shl_inst = findInstruction(block, shl_name) orelse return null;
    const shl = switch (shl_inst.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (!shl.ty.eql(.{ .int = 64 }) or shl.op != .shl or !isInt(shl.rhs, 16)) return null;
    const zext_name = switch (shl.lhs) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const zext_inst = findInstruction(block, zext_name) orelse return null;
    const zext = switch (zext_inst.kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 32 }) or !zext.to_ty.eql(.{ .int = 64 })) return null;
    const binary_name = switch (zext.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const binary_inst = findInstruction(block, binary_name) orelse return null;
    const binary = switch (binary_inst.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (!binary.ty.eql(.{ .int = 32 }) or (binary.op != .add and binary.op != .sub)) return null;
    if (!payloadValueFromCallResult(payload_scope, binary.lhs, call_name)) return null;
    const reg = switch (binary.rhs) {
        .named => |name| paramReg(function, name, .{ .int = 32 }) catch return null,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const op: MachineBinaryOp = switch (binary.op) {
        .add => .add,
        .sub => .sub,
        else => unreachable,
    };
    return .{ .op = op, .reg = reg };
}

const supportsDirectI64Call = error_union_rows.supportsDirectI64Call;
const supportsDirectI32Call = error_union_rows.supportsDirectI32Call;
const errorUnionTryGuardCallResult = error_union_rows.errorUnionTryGuardCallResult;
const blockReturnsNamedValue = error_union_rows.blockReturnsNamedValue;
const branchConditionParamReg = error_union_rows.branchConditionParamReg;
const branchKindToSkipOverride = error_union_rows.branchKindToSkipOverride;
const payloadAddArgFromCallResult = error_union_rows.payloadAddArgFromCallResult;
const payloadAddFromCallResult = error_union_rows.payloadAddFromCallResult;
const payloadValueFromCallResult = error_union_rows.payloadValueFromCallResult;
const successReturnPayloadAdd = error_union_rows.successReturnPayloadAdd;
const emitTwoI32ArgCallIntoRax = error_union_rows.emitTwoI32ArgCallIntoRax;

fn emitGenericCfgNestedTerminalBranch(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    entry: ir.BasicBlock,
    scope: ir.BasicBlock,
    cond: ir.Value,
    then_target: []const u8,
    else_target: []const u8,
) !void {
    const then_block = function.blocks.items[blockIndex(function, then_target) orelse return error.InvalidBranchTarget];
    const else_block = function.blocks.items[blockIndex(function, else_target) orelse return error.InvalidBranchTarget];
    try emitGenericCfgTerminalConditionTrueBranch(allocator, machine, function, entry, scope, cond, then_block.name);
    try emitGenericCfgTerminalReturnBlockInScope(allocator, machine, function, .{ .entry = entry, .middle = scope, .block = else_block });
    try appendGenericCfgBlockLabel(allocator, machine, then_block.name);
    try emitGenericCfgTerminalReturnBlockInScope(allocator, machine, function, .{ .entry = entry, .middle = scope, .block = then_block });
}

pub fn genericCfgSupportsBranchMergeBlock(
    function: ir.Function,
    entry: ir.BasicBlock,
    then_block: ir.BasicBlock,
    else_block: ir.BasicBlock,
    merge_block: ir.BasicBlock,
) bool {
    for (entry.instructions.items) |instruction| {
        if (instruction.removed) return false;
        switch (instruction.kind) {
            .icmp => |icmp| if (!genericCfgSupportsBranchIcmp(function, icmp)) return false,
            else => return false,
        }
    }
    if (!genericCfgSupportsBranchSideEffects(function, then_block)) return false;
    if (!genericCfgSupportsBranchSideEffects(function, else_block)) return false;
    const ret = switch (merge_block.terminator orelse return false) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (genericCfgPointerPhiLoadReturn(function, merge_block) != null) return true;
    if (genericCfgPhiBinaryReturn(merge_block) != null) return true;
    if (merge_block.instructions.items.len > 1) return false;
    if (merge_block.instructions.items.len == 1) {
        const instruction = merge_block.instructions.items[0];
        if (instruction.removed) return false;
        const ret_name = switch (ret.value orelse return false) {
            .named => |name| name,
            else => return false,
        };
        const result_name = instruction.result orelse return false;
        if (!std.mem.eql(u8, result_name, ret_name)) return false;
        switch (instruction.kind) {
            .phi => |phi| {
                if (!phi.ty.eql(.{ .int = 32 }) or phi.incoming.items.len != 2) return false;
            },
            .load => |load| {
                if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
                if (core_value_support.genericCfgI32Address(function, load.ptr) == null) return false;
            },
            else => return false,
        }
    }
    return true;
}

pub const GenericCfgPointerPhiLoad = struct {
    phi_name: []const u8,
    load_name: []const u8,
    phi: ir.PhiInst,
};

pub const GenericCfgPhiBinaryReturn = struct {
    phi_name: []const u8,
    binary_name: []const u8,
    phi: ir.PhiInst,
    op: ir.BinaryOp,
    imm: i32,
};

pub fn genericCfgPhiBinaryReturn(merge_block: ir.BasicBlock) ?GenericCfgPhiBinaryReturn {
    if (merge_block.instructions.items.len != 2) return null;
    const phi_instruction = merge_block.instructions.items[0];
    const binary_instruction = merge_block.instructions.items[1];
    if (phi_instruction.removed or binary_instruction.removed) return null;
    const phi_name = phi_instruction.result orelse return null;
    const binary_name = binary_instruction.result orelse return null;
    const phi = switch (phi_instruction.kind) {
        .phi => |phi| phi,
        else => return null,
    };
    if (!phi.ty.eql(.{ .int = 32 }) or phi.incoming.items.len != 2) return null;
    const binary = switch (binary_instruction.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (!binary.ty.eql(.{ .int = 32 }) or !isNamed(binary.lhs, phi_name)) return null;
    const imm = switch (binary.rhs) {
        .int => |int| i32Value(int) catch return null,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    switch (binary.op) {
        .add, .sub => {},
        else => return null,
    }
    const ret = switch (merge_block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return null, binary_name)) return null;
    return .{
        .phi_name = phi_name,
        .binary_name = binary_name,
        .phi = phi,
        .op = binary.op,
        .imm = imm,
    };
}

pub fn genericCfgPointerPhiLoadReturn(function: ir.Function, merge_block: ir.BasicBlock) ?GenericCfgPointerPhiLoad {
    if (merge_block.instructions.items.len != 2) return null;
    const phi_instruction = merge_block.instructions.items[0];
    const load_instruction = merge_block.instructions.items[1];
    if (phi_instruction.removed or load_instruction.removed) return null;
    const phi_name = phi_instruction.result orelse return null;
    const load_name = load_instruction.result orelse return null;
    const phi = switch (phi_instruction.kind) {
        .phi => |phi| phi,
        else => return null,
    };
    if (!phi.ty.eql(.ptr) or phi.incoming.items.len != 2) return null;
    for (phi.incoming.items) |incoming| {
        const ptr_name = switch (incoming.value) {
            .named => |name| name,
            else => return null,
        };
        if ((paramRegOrNull(function, ptr_name, .ptr) catch null) == null) return null;
    }
    const load = switch (load_instruction.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier() or !isNamed(load.ptr, phi_name)) return null;
    const ret = switch (merge_block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return null, load_name)) return null;
    return .{ .phi_name = phi_name, .load_name = load_name, .phi = phi };
}

pub fn lowerGenericCfgDynamicPointerLoadReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.ptr) or !function.params.items[1].ty.eql(.{ .int = 64 })) return false;
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        else => return false,
    };
    const ret_instruction = findInstruction(block, ret_name) orelse return false;
    switch (ret_instruction.kind) {
        .load => |load| {
            const address = core_memory_lowering.genericCfgDynamicI32LoadAddress(function, block, load) orelse return false;
            try core_memory_lowering.emitGenericCfgDynamicI32LoadIntoEax(allocator, machine, address);
        },
        .binary => |binary| {
            if (binary.op != .add or !binary.ty.eql(.{ .int = 32 })) return false;
            const lhs = core_memory_lowering.genericCfgDynamicI32LoadValueAddress(function, block, binary.lhs) orelse return false;
            const rhs = core_memory_lowering.genericCfgDynamicI32LoadValueAddress(function, block, binary.rhs) orelse return false;
            try core_memory_lowering.emitGenericCfgDynamicI32LoadIntoEax(allocator, machine, lhs);
            try core_memory_lowering.emitGenericCfgDynamicI32AddIntoEax(allocator, machine, rhs);
        },
        else => return false,
    }
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub fn genericCfgSupportsBranchSideEffects(function: ir.Function, block: ir.BasicBlock) bool {
    for (block.instructions.items) |instruction| {
        if (instruction.removed) return false;
        switch (instruction.kind) {
            .store => |store| {
                if (!store.ty.eql(.{ .int = 32 })) return false;
                if (!genericCfgSupportsI32Value(function, store.value)) {
                    if (store.value != .named) return false;
                }
                if (core_value_support.genericCfgI32Address(function, store.ptr) == null) return false;
            },
            .load => |load| {
                if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
                if (core_value_support.genericCfgI32Address(function, load.ptr) == null) return false;
            },
            .binary => |binary| {
                if (!binary.ty.eql(.{ .int = 32 })) return false;
                if (!genericCfgSupportsI32Value(function, binary.lhs)) return false;
                switch (binary.rhs) {
                    .int => switch (binary.op) {
                        .add, .sub => {},
                        else => return false,
                    },
                    .named => |name| {
                        if ((paramRegOrNull(function, name, .{ .int = 32 }) catch null) == null) return false;
                        if (machineBinaryOp(binary.op) == null) return false;
                    },
                    .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                }
            },
            .call => |call| {
                if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len > 4) return false;
                if (call.callee_value != null or call.inline_asm != null) return false;
                if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;
                for (call.args.items) |arg| {
                    if (!arg.ty.eql(.{ .int = 32 })) return false;
                    switch (arg.value) {
                        .int => {},
                        .named => |name| if ((paramRegOrNull(function, name, .{ .int = 32 }) catch null) == null) return false,
                        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                    }
                }
            },
            .phi, .icmp, .fcmp, .cast, .freeze, .select, .alloca, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep => return false,
        }
    }
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
    const branch_kind = try emitGenericCfgIcmpCondition(allocator, machine, function, icmp);
    try appendGenericCfgConditionalBranch(allocator, machine, branch_kind, true_label);
}

pub fn emitGenericCfgBranchPathReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    branch_block: ir.BasicBlock,
    merge_block: ir.BasicBlock,
) !void {
    try emitGenericCfgBranchSideEffects(allocator, machine, function, branch_block);
    const ret = switch (merge_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    const ret_value = ret.value orelse return error.InvalidRet;
    if (genericCfgPointerPhiLoadReturn(function, merge_block)) |pointer_load| {
        for (pointer_load.phi.incoming.items) |incoming| {
            if (!std.mem.eql(u8, incoming.block, branch_block.name)) continue;
            const ptr_reg = try paramValueReg(function, incoming.value, .ptr);
            try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = ptr_reg });
            try appendGenericCfgReturn(allocator, machine);
            return;
        }
        return error.UnsupportedCodegenValue;
    }
    if (genericCfgPhiBinaryReturn(merge_block)) |phi_binary| {
        for (phi_binary.phi.incoming.items) |incoming| {
            if (!std.mem.eql(u8, incoming.block, branch_block.name)) continue;
            try emitGenericCfgI32ValueIntoEax(allocator, machine, function, branch_block, incoming.value);
            switch (phi_binary.op) {
                .add => try machine.instructions.append(allocator, .{ .add_eax_imm32 = phi_binary.imm }),
                .sub => try machine.instructions.append(allocator, .{ .add_eax_imm32 = -phi_binary.imm }),
                else => return error.UnsupportedCodegenInstruction,
            }
            try appendGenericCfgReturn(allocator, machine);
            return;
        }
        return error.UnsupportedCodegenValue;
    }
    if (merge_block.instructions.items.len > 0) {
        const phi = switch (merge_block.instructions.items[0].kind) {
            .phi => |phi| phi,
            else => null,
        };
        if (phi) |phi_inst| {
            const ret_name = switch (ret_value) {
                .named => |name| name,
                else => return error.UnsupportedCodegenValue,
            };
            const phi_name = merge_block.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
            if (!std.mem.eql(u8, ret_name, phi_name)) return error.UnsupportedCodegenValue;
            for (phi_inst.incoming.items) |incoming| {
                if (!std.mem.eql(u8, incoming.block, branch_block.name)) continue;
                try emitGenericCfgI32ValueIntoEax(allocator, machine, function, branch_block, incoming.value);
                try appendGenericCfgReturn(allocator, machine);
                return;
            }
            return error.UnsupportedCodegenValue;
        }
    }
    try emitGenericCfgI32ValueIntoEax(allocator, machine, function, merge_block, ret_value);
    try appendGenericCfgReturn(allocator, machine);
}

pub const emitGenericCfgBranchSideEffects = core_value_emit.emitGenericCfgBranchSideEffects;
pub const emitGenericCfgI32ValueIntoEax = core_value_emit.emitGenericCfgI32ValueIntoEax;
pub const emitGenericCfgI64ValueIntoRax = core_value_emit.emitGenericCfgI64ValueIntoRax;
pub const emitGenericCfgI32AddValueToEax = core_value_emit.emitGenericCfgI32AddValueToEax;
pub const emitGenericCfgStoreEax = core_value_emit.emitGenericCfgStoreEax;
pub const emitGenericCfgI32CallIntoEax = core_value_emit.emitGenericCfgI32CallIntoEax;
pub const emitGenericCfgVoidCall = core_value_emit.emitGenericCfgVoidCall;

pub fn emitGenericCfgLoopSum(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    plan: GenericCfgLoopSumPlan,
) !void {
    const count_reg = try paramReg(function, function.params.items[0].name, .{ .int = 32 });
    if (count_reg != .rdi) return error.UnsupportedCodegenAbi;

    const loop_label = "generic_cfg_loop_sum_loop";
    const zero_label = "generic_cfg_loop_sum_zero";
    const overflow_label = "generic_cfg_loop_sum_overflow";
    const out_of_bounds_label = "generic_cfg_loop_sum_out_of_bounds";
    try appendGenericCfgCompareParamZero(allocator, machine, count_reg);
    try appendGenericCfgConditionalBranch(allocator, machine, .je, zero_label);
    try appendGenericCfgConditionalBranch(allocator, machine, .js, zero_label);
    try appendGenericCfgI32Zero(allocator, machine, .eax);
    try appendGenericCfgI32Zero(allocator, machine, .ecx);
    try appendGenericCfgBlockLabel(allocator, machine, loop_label);
    if (plan.checked) {
        try appendGenericCfgCompareLocalImm(allocator, machine, .ecx, std.math.minInt(i32));
        try appendGenericCfgConditionalBranch(allocator, machine, .je, out_of_bounds_label);
    }
    try appendGenericCfgAccumulatorAdd(allocator, machine);
    if (plan.checked) try appendGenericCfgConditionalBranch(allocator, machine, .jo, overflow_label);
    try appendGenericCfgAccumulatorIncrement(allocator, machine);
    try appendGenericCfgCompareLocalParam(allocator, machine, .ecx, count_reg);
    try appendGenericCfgConditionalBranch(allocator, machine, .jne, loop_label);
    try appendGenericCfgReturn(allocator, machine);
    try appendGenericCfgBlockLabel(allocator, machine, zero_label);
    try appendGenericCfgI32Zero(allocator, machine, .eax);
    try appendGenericCfgReturn(allocator, machine);
    if (plan.checked) {
        try appendPanicCall(allocator, machine, overflow_label, "debug.FullPanic((function 'defaultPanic')).integerOverflow");
        try appendPanicCall(allocator, machine, out_of_bounds_label, "debug.FullPanic((function 'defaultPanic')).integerOutOfBounds");
    }
}
