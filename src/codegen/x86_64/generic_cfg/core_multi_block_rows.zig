const shared = @import("core_shared.zig");
const core_cfg_emit = @import("core_cfg_emit.zig");
const core_loop_rows = @import("core_loop_rows.zig");
const core_value_support = @import("core_value_support.zig");
const core_value_emit = @import("core_value_emit.zig");
const core_memory_lowering = @import("core_memory_lowering.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");
const cabi_call_lowering = @import("cabi_call_lowering.zig");

const std = shared.std;
const ir = shared.ir;
const MachineFunction = shared.MachineFunction;
const ArgReg = shared.ArgReg;

const appendAlignedDirectCall = shared.appendAlignedDirectCall;
const appendDirectCallWithStackArgs = shared.appendDirectCallWithStackArgs;
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
const paramReg = cabi_abi_helpers.paramReg;
const paramRegOrNull = cabi_abi_helpers.paramRegOrNull;
const paramValueReg = cabi_abi_helpers.paramValueReg;
const blockIndex = cabi_abi_helpers.blockIndex;
const validateDefaultCallConv = shared.validateDefaultCallConv;

pub const GenericCfgLoopSumPlan = core_loop_rows.GenericCfgLoopSumPlan;
const genericCfgPointerSlotParam = core_memory_lowering.genericCfgPointerSlotParam;
const genericCfgLoadPtrFromSlot = core_memory_lowering.genericCfgLoadPtrFromSlot;
const genericCfgSupportsBranchIcmp = core_value_support.genericCfgSupportsBranchIcmp;
const genericCfgSupportsPointerNullIcmp = core_value_support.genericCfgSupportsPointerNullIcmp;
const genericCfgSupportsI32Value = core_value_support.genericCfgSupportsI32Value;

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

    const address = genericCfgDynamicI32LoadReturnAddress(function, entry, load_block) orelse return false;
    const lhs_reg = genericCfgI64ParamRegThroughIdentityCast(function, entry, icmp.lhs) orelse return false;
    const rhs_reg = genericCfgI64ParamRegThroughIdentityCast(function, entry, icmp.rhs) orelse return false;
    if (address.index_reg != lhs_reg) return false;

    try emitGenericCfgUgeI64ParamCondition(allocator, machine, lhs_reg, rhs_reg);
    const branch_to_const = true_const != null;
    if (branch_to_const) {
        try appendGenericCfgConditionalBranch(allocator, machine, .jae, const_block.name);
        try emitGenericCfgDynamicI32LoadIntoEax(allocator, machine, address);
        try appendGenericCfgReturn(allocator, machine);
        try appendGenericCfgBlockLabel(allocator, machine, const_block.name);
        try machine.instructions.append(allocator, .{ .mov_imm_eax = const_value });
        try appendGenericCfgReturn(allocator, machine);
    } else {
        try appendGenericCfgConditionalBranch(allocator, machine, .jae, load_block.name);
        try machine.instructions.append(allocator, .{ .mov_imm_eax = const_value });
        try appendGenericCfgReturn(allocator, machine);
        try appendGenericCfgBlockLabel(allocator, machine, load_block.name);
        try emitGenericCfgDynamicI32LoadIntoEax(allocator, machine, address);
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
    if (icmp.predicate != .uge or !icmp.operand_ty.eql(.{ .int = 64 })) return false;

    const true_block = blockByName(function, condbr.then_target) orelse return false;
    const false_block = blockByName(function, condbr.else_target) orelse return false;
    const true_panic = if (validateNoreturnSliceRuntimeCall(true_block)) |_| true else |_| false;
    const false_panic = if (validateNoreturnSliceRuntimeCall(false_block)) |_| true else |_| false;
    if (true_panic == false_panic) return false;
    const panic_block = if (true_panic) true_block else false_block;
    const load_block = if (true_panic) false_block else true_block;

    const address = genericCfgDynamicI32LoadReturnAddress(function, entry, load_block) orelse return false;
    const lhs_reg = genericCfgI64ParamRegThroughIdentityCast(function, entry, icmp.lhs) orelse return false;
    const rhs_reg = genericCfgI64ParamRegThroughIdentityCast(function, entry, icmp.rhs) orelse return false;
    if (address.index_reg != lhs_reg) return false;

    try emitGenericCfgUgeI64ParamCondition(allocator, machine, lhs_reg, rhs_reg);
    if (true_panic) {
        try appendGenericCfgConditionalBranch(allocator, machine, .jae, panic_block.name);
        try emitGenericCfgDynamicI32LoadIntoEax(allocator, machine, address);
        try appendGenericCfgReturn(allocator, machine);
        try appendGenericCfgBlockLabel(allocator, machine, panic_block.name);
        try emitGenericCfgNoreturnCallBlock(allocator, machine, function, panic_block);
    } else {
        try appendGenericCfgConditionalBranch(allocator, machine, .jae, load_block.name);
        try emitGenericCfgNoreturnCallBlock(allocator, machine, function, panic_block);
        try appendGenericCfgBlockLabel(allocator, machine, load_block.name);
        try emitGenericCfgDynamicI32LoadIntoEax(allocator, machine, address);
        try appendGenericCfgReturn(allocator, machine);
    }
    return true;
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

pub fn genericCfgDynamicI32LoadReturnAddress(
    function: ir.Function,
    entry: ir.BasicBlock,
    block: ir.BasicBlock,
) ?GenericCfgDynamicI32Address {
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return null;
    const ret_name = switch (ret.value orelse return null) {
        .named => |name| name,
        else => return null,
    };
    const ret_instruction = findInstruction(block, ret_name) orelse return null;
    const load = switch (ret_instruction.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return null;
    return genericCfgDynamicI32AddressAcrossBlocks(function, entry, block, load.ptr);
}

pub fn genericCfgDynamicI32AddressAcrossBlocks(
    function: ir.Function,
    entry: ir.BasicBlock,
    block: ir.BasicBlock,
    ptr: ir.Value,
) ?GenericCfgDynamicI32Address {
    const name = switch (ptr) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (paramRegOrNull(function, name, .ptr) catch null) |reg| {
        return .{ .base_reg = reg, .index_reg = .rsi, .offset_elems = 0 };
    }
    const instruction = findInstruction(block, name) orelse findInstruction(entry, name) orelse return null;
    switch (instruction.kind) {
        .gep => |gep| {
            if (!gep.source_ty.eql(.{ .int = 32 }) or gep.indices.items.len != 1) return null;
            var address = genericCfgDynamicI32AddressAcrossBlocks(function, entry, block, gep.ptr) orelse return null;
            const index = gep.indices.items[0];
            if (!index.ty.eql(.{ .int = 64 })) return null;
            switch (index.value) {
                .int => |int| address.offset_elems += int,
                .named => |index_name| {
                    if (address.offset_elems != 0) return null;
                    address.index_reg = genericCfgI64ParamRegThroughIdentityCast(function, entry, .{ .named = index_name }) orelse return null;
                },
                .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
            }
            return address;
        },
        .load => |load| {
            if (!load.ty.eql(.ptr) or load.attrs.isBarrier()) return null;
            const slot_name = switch (load.ptr) {
                .named => |slot| slot,
                .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
            };
            const stored = genericCfgStoredPointerValue(block, slot_name) orelse
                genericCfgStoredPointerValue(entry, slot_name) orelse return null;
            return genericCfgDynamicI32AddressAcrossBlocks(function, entry, block, stored);
        },
        .cast => |cast| {
            if (cast.op != .bitcast or !cast.to_ty.eql(.ptr)) return null;
            return genericCfgDynamicI32AddressAcrossBlocks(function, entry, block, cast.value);
        },
        else => return null,
    }
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

pub fn lowerGenericCfgStructBranchUpdateReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 2 or function.blocks.items.len != 4) return false;
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 3) return false;
    const slot = genericCfgPointerSlotParam(function, entry.instructions.items[0], entry.instructions.items[1]) orelse return false;
    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 })) return false;
    const then_block = function.blocks.items[blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget];
    const else_block = function.blocks.items[blockIndex(function, condbr.else_target) orelse return error.InvalidBranchTarget];
    const then_target = singleBrTarget(then_block) orelse return false;
    const else_target = singleBrTarget(else_block) orelse return false;
    if (!std.mem.eql(u8, then_target, else_target)) return false;
    const merge_block = function.blocks.items[blockIndex(function, then_target) orelse return error.InvalidBranchTarget];

    const then_add = genericCfgStructFieldZeroUpdateAdd(then_block, slot.slot_name) orelse return false;
    const else_add = genericCfgStructFieldZeroUpdateAdd(else_block, slot.slot_name) orelse return false;
    if (!genericCfgStructFieldZeroMergeReturn(merge_block, slot.slot_name)) return false;

    try emitGenericCfgConditionTrueBranch(allocator, machine, function, entry, condbr.cond, then_block.name);
    try emitGenericCfgStructFieldZeroUpdatePath(allocator, machine, slot.param_reg, else_add);
    try appendGenericCfgBlockLabel(allocator, machine, then_block.name);
    try emitGenericCfgStructFieldZeroUpdatePath(allocator, machine, slot.param_reg, then_add);
    return true;
}

pub fn genericCfgStructFieldZeroUpdateAdd(block: ir.BasicBlock, slot_name: []const u8) ?i32 {
    if (block.instructions.items.len != 4) return null;
    const loaded_ptr = genericCfgLoadPtrFromSlot(block.instructions.items[0], slot_name) orelse return null;

    const load_name = block.instructions.items[1].result orelse return null;
    const load = switch (block.instructions.items[1].kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier() or !isNamed(load.ptr, loaded_ptr)) return null;

    const add_name = block.instructions.items[2].result orelse return null;
    const add = switch (block.instructions.items[2].kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 }) or !isNamed(add.lhs, load_name)) return null;
    const add_imm = switch (add.rhs) {
        .int => |int| i32Value(int) catch return null,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };

    const store = switch (block.instructions.items[3].kind) {
        .store => |store| store,
        else => return null,
    };
    if (!store.ty.eql(.{ .int = 32 }) or store.attrs.isBarrier()) return null;
    if (!isNamed(store.value, add_name) or !isNamed(store.ptr, loaded_ptr)) return null;
    return add_imm;
}

pub fn genericCfgStructFieldZeroMergeReturn(block: ir.BasicBlock, slot_name: []const u8) bool {
    if (block.instructions.items.len != 2) return false;
    const loaded_ptr = genericCfgLoadPtrFromSlot(block.instructions.items[0], slot_name) orelse return false;
    const load_name = block.instructions.items[1].result orelse return false;
    const load = switch (block.instructions.items[1].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier() or !isNamed(load.ptr, loaded_ptr)) return false;
    const ret = switch (block.terminator orelse return false) {
        .ret => |ret| ret,
        else => return false,
    };
    return ret.ty.eql(.{ .int = 32 }) and isNamed(ret.value orelse return false, load_name);
}

pub fn emitGenericCfgStructFieldZeroUpdatePath(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    ptr_reg: ArgReg,
    add_imm: i32,
) !void {
    try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = ptr_reg });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = add_imm });
    try machine.instructions.append(allocator, .{ .store_eax_arg_ptr = ptr_reg });
    try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = ptr_reg });
    try appendGenericCfgReturn(allocator, machine);
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

pub fn emitGenericCfgNoreturnCallBlock(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
) !void {
    if (block.instructions.items.len >= 4) {
        if (validateNoreturnSliceRuntimeCall(block)) |call| {
            try emitSlicePointerIntoRdi(allocator, machine, function, block, call.args.items[0].value);
            try emitSliceLengthIntoRsi(allocator, machine, function, block, call.args.items[1].value);
            try appendAlignedDirectCall(allocator, machine, call.callee, .void);
            try machine.instructions.append(allocator, .ud2);
            return;
        } else |err| switch (err) {
            error.UnsupportedCodegenInstruction,
            error.UnsupportedCodegenType,
            error.UnsupportedCodegenValue,
            error.BlockWithoutTerminator,
            error.UnsupportedCodegenControlFlow,
            => {},
            else => return err,
        }
    }

    if (block.instructions.items.len == 0 or block.instructions.items.len > 2) return error.UnsupportedCodegenInstruction;
    var call_index: usize = 0;
    if (block.instructions.items.len == 2) {
        try validateAssumeColdCall(block.instructions.items[0]);
        call_index = 1;
    }
    const call = switch (block.instructions.items[call_index].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (call.callee_value != null or call.inline_asm != null or call.ret_ty != .void) return error.UnsupportedCodegenInstruction;
    if (!callIsFastcc(call.calling_conv)) try validateDefaultCallConv(call.calling_conv);
    switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .@"unreachable" => {},
        else => return error.UnsupportedCodegenControlFlow,
    }

    if (call.args.items.len == 2) {
        try validateSliceRuntimeCallArgs(call);
        try emitSlicePointerIntoRdi(allocator, machine, function, block, call.args.items[0].value);
        try emitSliceLengthIntoRsi(allocator, machine, function, block, call.args.items[1].value);
    } else if (call.args.items.len != 0) {
        return error.UnsupportedCodegenInstruction;
    }
    try appendAlignedDirectCall(allocator, machine, call.callee, .void);
    try machine.instructions.append(allocator, .ud2);
}

pub fn validateNoreturnSliceRuntimeCall(block: ir.BasicBlock) !ir.CallInst {
    if (block.instructions.items.len == 0) return error.UnsupportedCodegenInstruction;
    if (block.instructions.items.len > 1) {
        validateAssumeColdCall(block.instructions.items[0]) catch |err| switch (err) {
            error.UnsupportedCodegenInstruction, error.UnsupportedCodegenValue => {},
        };
    }
    const call_instruction = block.instructions.items[block.instructions.items.len - 1];
    const call = switch (call_instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (call.callee_value != null or call.inline_asm != null or call.ret_ty != .void) return error.UnsupportedCodegenInstruction;
    if (!callIsFastcc(call.calling_conv)) try validateDefaultCallConv(call.calling_conv);
    try validateSliceRuntimeCallArgs(call);
    if (call.args.items.len == 3 and call.args.items[2].ty != .ptr) return error.UnsupportedCodegenType;
    _ = try resolveSlicePointerValue(block, call.args.items[0].value);
    switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .@"unreachable" => {},
        else => return error.UnsupportedCodegenControlFlow,
    }
    return call;
}

fn validateSliceRuntimeCallArgs(call: ir.CallInst) !void {
    if (call.args.items.len != 2 and call.args.items.len != 3) return error.UnsupportedCodegenInstruction;
    if (call.args.items[0].ty != .ptr) return error.UnsupportedCodegenType;
    if (!call.args.items[1].ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
}

pub const SlicePointerValue = union(enum) {
    global: []const u8,
    materialize: ir.Value,
};

pub fn resolveSlicePointerValue(block: ir.BasicBlock, value: ir.Value) !SlicePointerValue {
    switch (value) {
        .named => |name| {
            if (std.mem.startsWith(u8, name, "@")) return .{ .global = try globalSymbolName(name) };
            const instruction = findInstruction(block, name) orelse return error.UnsupportedCodegenValue;
            const extract = switch (instruction.kind) {
                .extractvalue => |extractvalue| extractvalue,
                else => return error.UnsupportedCodegenInstruction,
            };
            if (!extract.result_ty.eql(.ptr) or !std.mem.eql(u8, extract.indices, "0")) return error.UnsupportedCodegenInstruction;
            if (resolveSlicePointerFromInsertedAggregate(block, extract.aggregate)) |resolved| return resolved;
            return .{ .global = try globalSymbolNameFromValue(extract.aggregate) };
        },
        .constant_expr => return .{ .global = try globalSymbolNameFromValue(value) },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
    }
}

fn resolveSlicePointerFromInsertedAggregate(block: ir.BasicBlock, aggregate: ir.Value) ?SlicePointerValue {
    const aggregate_name = switch (aggregate) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const len_insert = findInstruction(block, aggregate_name) orelse return null;
    const len_insertvalue = switch (len_insert.kind) {
        .insertvalue => |insertvalue| insertvalue,
        else => return null,
    };
    if (!std.mem.eql(u8, len_insertvalue.indices, "1")) return null;
    const ptr_insert_name = switch (len_insertvalue.aggregate) {
        .named => |name| name,
        .undef => return null,
        .int, .fp, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const ptr_insert = findInstruction(block, ptr_insert_name) orelse return null;
    const ptr_insertvalue = switch (ptr_insert.kind) {
        .insertvalue => |insertvalue| insertvalue,
        else => return null,
    };
    if (!std.mem.eql(u8, ptr_insertvalue.indices, "0") or !ptr_insertvalue.value_ty.eql(.ptr)) return null;
    if (globalSymbolNameFromValue(ptr_insertvalue.value)) |symbol| return .{ .global = symbol } else |_| {}
    return switch (ptr_insertvalue.value) {
        .named => .{ .materialize = ptr_insertvalue.value },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
    };
}

pub fn resolveSliceLengthValue(function: ir.Function, block: ir.BasicBlock, value: ir.Value) anyerror!SliceLengthValue {
    switch (value) {
        .int => |int| return .{ .imm = try i64Value(int) },
        .named => |name| {
            if (paramRegOrNull(function, name, .{ .int = 64 }) catch null) |reg| return .{ .reg = reg };
            const instruction = findInstructionInFunction(function, block, name) orelse return error.UnsupportedCodegenValue;
            switch (instruction.kind) {
                .extractvalue => |extract| {
                    if (!extract.result_ty.eql(.{ .int = 64 }) or !std.mem.eql(u8, extract.indices, "1")) return error.UnsupportedCodegenInstruction;
                    if (try resolveSliceLengthFromInsertedAggregate(function, block, extract.aggregate)) |len| return len;
                    return .{ .imm = try sliceLengthFromAggregateConstant(extract.aggregate) };
                },
                .cast, .load, .binary => return .{ .materialize = value },
                .phi => |phi| {
                    if (!phi.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
                    return .{ .materialize = value };
                },
                else => return error.UnsupportedCodegenInstruction,
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

fn resolveSliceLengthFromInsertedAggregate(function: ir.Function, block: ir.BasicBlock, aggregate: ir.Value) anyerror!?SliceLengthValue {
    const aggregate_name = switch (aggregate) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const instruction = findInstructionInFunction(function, block, aggregate_name) orelse return null;
    const insert = switch (instruction.kind) {
        .insertvalue => |insertvalue| insertvalue,
        else => return null,
    };
    if (!std.mem.eql(u8, insert.indices, "1") or !insert.value_ty.eql(.{ .int = 64 })) return null;
    return try resolveSliceLengthValue(function, block, insert.value);
}

pub const SliceLengthValue = union(enum) {
    imm: i64,
    reg: ArgReg,
    materialize: ir.Value,
};

pub fn emitSlicePointerIntoRdi(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    value: ir.Value,
) !void {
    switch (try resolveSlicePointerValue(block, value)) {
        .global => |symbol| try machine.instructions.append(allocator, .{ .lea_global_rdi = symbol }),
        .materialize => |materialized| try emitPointerValueIntoArgReg(allocator, machine, function, block, .rdi, materialized),
    }
}

pub fn emitSliceLengthIntoRsi(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    value: ir.Value,
) !void {
    switch (try resolveSliceLengthValue(function, block, value)) {
        .imm => |len| try appendMoveImmToArgReg(allocator, machine, .rsi, len),
        .reg => |reg| if (reg != .rsi) try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = .rsi, .src = reg } }),
        .materialize => |materialized| try emitI64ValueIntoArgReg(allocator, machine, function, block, .rsi, materialized),
    }
}

pub fn emitI64ValueIntoArgReg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    dst: ArgReg,
    value: ir.Value,
) anyerror!void {
    switch (value) {
        .int => |int| return try appendMoveImmToArgReg(allocator, machine, dst, try i64Value(int)),
        .named => |name| {
            if (try emitNamedI64ValueIntoArgReg(allocator, machine, function, block, dst, name)) return;
            return error.UnsupportedCodegenValue;
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn emitNamedI64ValueIntoArgReg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    dst: ArgReg,
    name: []const u8,
) anyerror!bool {
    if (paramRegOrNull(function, name, .{ .int = 64 }) catch null) |reg| {
        if (reg != dst) try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = dst, .src = reg } });
        return true;
    }
    const instruction = findInstructionInFunction(function, block, name) orelse return false;
    switch (instruction.kind) {
        .cast => |cast| {
            if (cast.op != .bitcast or !cast.from_ty.eql(.{ .int = 64 }) or !cast.to_ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenInstruction;
            try emitI64ValueIntoArgReg(allocator, machine, function, block, dst, cast.value);
            return true;
        },
        .load => |load| {
            try emitLoadedI64IntoArgReg(allocator, machine, function, dst, load);
            return true;
        },
        .binary => |binary| {
            try emitComputedI64IntoArgReg(allocator, machine, function, block, dst, binary);
            return true;
        },
        .select => |select| {
            try emitSelectedI64IntoArgReg(allocator, machine, function, block, dst, name, select);
            return true;
        },
        .phi => |phi| {
            try emitPhiSelectedI64IntoArgReg(allocator, machine, function, block, dst, phi);
            return true;
        },
        .extractvalue => |extract| {
            if (!extract.result_ty.eql(.{ .int = 64 }) or !std.mem.eql(u8, extract.indices, "1")) return error.UnsupportedCodegenInstruction;
            try appendMoveImmToArgReg(allocator, machine, dst, try sliceLengthFromAggregateConstant(extract.aggregate));
            return true;
        },
        else => return error.UnsupportedCodegenInstruction,
    }
}

fn emitPointerValueIntoArgReg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    dst: ArgReg,
    value: ir.Value,
) anyerror!void {
    switch (value) {
        .named => |name| {
            if (paramRegOrNull(function, name, .ptr) catch null) |reg| {
                if (reg != dst) try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = dst, .src = reg } });
                return;
            }
            const instruction = findInstructionInFunction(function, block, name) orelse return error.UnsupportedCodegenValue;
            switch (instruction.kind) {
                .load => |load| {
                    try emitLoadedPointerIntoArgReg(allocator, machine, function, dst, load);
                    return;
                },
                .cast => |cast| {
                    if (cast.op != .bitcast or cast.to_ty != .ptr) return error.UnsupportedCodegenInstruction;
                    try emitPointerValueIntoArgReg(allocator, machine, function, block, dst, cast.value);
                    return;
                },
                .extractvalue => {
                    switch (try resolveSlicePointerValue(block, value)) {
                        .global => |symbol| {
                            if (dst != .rdi) return error.UnsupportedCodegenAbi;
                            try machine.instructions.append(allocator, .{ .lea_global_rdi = symbol });
                        },
                        .materialize => |materialized| try emitPointerValueIntoArgReg(allocator, machine, function, block, dst, materialized),
                    }
                    return;
                },
                else => return error.UnsupportedCodegenInstruction,
            }
        },
        .constant_expr => {
            if (dst != .rdi) return error.UnsupportedCodegenAbi;
            try machine.instructions.append(allocator, .{ .lea_global_rdi = try globalSymbolNameFromValue(value) });
        },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
    }
}

fn emitLoadedPointerIntoArgReg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    dst: ArgReg,
    load: ir.LoadInst,
) anyerror!void {
    if (load.ty != .ptr or load.attrs.isBarrier()) return error.UnsupportedCodegenInstruction;
    switch (load.ptr) {
        .named => |name| {
            if (paramRegOrNull(function, name, .ptr) catch null) |reg| {
                try machine.instructions.append(allocator, .{ .load_arg_ptr_disp8_rax = .{ .reg = reg, .offset = 0 } });
            } else if (std.mem.startsWith(u8, name, "@")) {
                try machine.instructions.append(allocator, .{ .load_global_ptr_rax = try globalSymbolName(name) });
            } else {
                return error.UnsupportedCodegenValue;
            }
        },
        .constant_expr => try machine.instructions.append(allocator, .{ .load_global_ptr_rax = try globalSymbolNameFromValue(load.ptr) }),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
    }
    try emitRaxIntoArgReg(allocator, machine, dst);
}

pub fn emitLoadedI64IntoArgReg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    dst: ArgReg,
    load: ir.LoadInst,
) anyerror!void {
    if (!load.ty.eql(.{ .int = 64 }) or load.attrs.isBarrier()) return error.UnsupportedCodegenInstruction;
    switch (load.ptr) {
        .named => |name| {
            if (paramRegOrNull(function, name, .ptr) catch null) |reg| {
                try machine.instructions.append(allocator, .{ .load_arg_ptr_disp8_rax = .{ .reg = reg, .offset = 0 } });
            } else if (std.mem.startsWith(u8, name, "@")) {
                try machine.instructions.append(allocator, .{ .load_global_ptr_rax = try globalSymbolName(name) });
            } else {
                return error.UnsupportedCodegenValue;
            }
        },
        .constant_expr => try machine.instructions.append(allocator, .{ .load_global_ptr_rax = try globalSymbolNameFromValue(load.ptr) }),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
    }
    try emitRaxIntoArgReg(allocator, machine, dst);
}

fn emitSelectedI64IntoArgReg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    dst: ArgReg,
    result_name: []const u8,
    select: ir.SelectInst,
) anyerror!void {
    _ = result_name;
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenInstruction;
    const cond_reg = paramValueReg(function, select.cond, .{ .int = 1 }) catch return error.UnsupportedCodegenValue;
    const true_label = "generic_cfg_i64_select_true";
    const end_label = "generic_cfg_i64_select_end";
    try machine.instructions.append(allocator, .{ .test_arg8 = cond_reg });
    try appendGenericCfgConditionalBranch(allocator, machine, .jne, true_label);
    try emitI64ValueIntoArgReg(allocator, machine, function, block, dst, select.false_value);
    try machine.instructions.append(allocator, .{ .jmp = end_label });
    try appendGenericCfgBlockLabel(allocator, machine, true_label);
    try emitI64ValueIntoArgReg(allocator, machine, function, block, dst, select.true_value);
    try appendGenericCfgBlockLabel(allocator, machine, end_label);
}

pub fn emitComputedI64IntoArgReg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    dst: ArgReg,
    binary: ir.BinaryInst,
) anyerror!void {
    if (!binary.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
    switch (binary.op) {
        .add => {
            try emitGenericCfgI64ValueIntoRax(allocator, machine, function, block, binary.lhs);
            switch (binary.rhs) {
                .int => |int| {
                    const rhs = try i64Value(int);
                    if (rhs < 0 or rhs > std.math.maxInt(u8)) return error.UnsupportedCodegenValue;
                    if (rhs != 0) try machine.instructions.append(allocator, .{ .add_rax_imm8 = @intCast(rhs) });
                },
                .named => |name| {
                    const reg = (paramRegOrNull(function, name, .{ .int = 64 }) catch null) orelse return error.UnsupportedCodegenValue;
                    try machine.instructions.append(allocator, .{ .add_arg64_rax = reg });
                },
                .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
            }
        },
        .sub => {
            const rhs = switch (binary.rhs) {
                .int => |int| try i64Value(int),
                .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
            };
            if (rhs != 0) return error.UnsupportedCodegenInstruction;
            try emitI64ValueIntoArgReg(allocator, machine, function, block, dst, binary.lhs);
            return;
        },
        else => return error.UnsupportedCodegenInstruction,
    }
    try emitRaxIntoArgReg(allocator, machine, dst);
}

fn emitPhiSelectedI64IntoArgReg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    dst: ArgReg,
    phi: ir.PhiInst,
) anyerror!void {
    if (phi.incoming.items.len != 1) return error.UnsupportedCodegenControlFlow;
    try emitI64ValueIntoArgReg(allocator, machine, function, block, dst, phi.incoming.items[0].value);
}

fn emitRaxIntoArgReg(allocator: std.mem.Allocator, machine: *MachineFunction, dst: ArgReg) !void {
    switch (dst) {
        .rdi => try machine.instructions.append(allocator, .mov_rax_rdi),
        .rsi => try machine.instructions.append(allocator, .mov_rax_rsi),
        .rdx, .rcx, .r8, .r9 => return error.UnsupportedCodegenAbi,
    }
}

fn findInstructionInFunction(function: ir.Function, preferred_block: ir.BasicBlock, result_name: []const u8) ?ir.Instruction {
    if (findInstruction(preferred_block, result_name)) |instruction| return instruction;
    for (function.blocks.items) |candidate_block| {
        if (std.mem.eql(u8, candidate_block.name, preferred_block.name)) continue;
        if (findInstruction(candidate_block, result_name)) |instruction| return instruction;
    }
    return null;
}

fn sliceLengthFromAggregateConstant(value: ir.Value) !i64 {
    const text = switch (value) {
        .constant_expr => |text| text,
        .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
    };
    const marker = "i64 ";
    const start_marker = std.mem.lastIndexOf(u8, text, marker) orelse return error.UnsupportedCodegenValue;
    var start = start_marker + marker.len;
    while (start < text.len and text[start] == ' ') : (start += 1) {}
    var end = start;
    while (end < text.len and (std.ascii.isDigit(text[end]) or text[end] == '-')) : (end += 1) {}
    if (end == start) return error.UnsupportedCodegenValue;
    return std.fmt.parseInt(i64, text[start..end], 10) catch return error.UnsupportedCodegenValue;
}

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

fn terminalCondParamReg(function: ir.Function, cond: ir.Value) ?ArgReg {
    const cond_name = switch (cond) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    return paramRegOrNull(function, cond_name, .{ .int = 1 }) catch null;
}

fn genericCfgTerminalBranchExtraBlocksAreUnreachable(function: ir.Function, then_index: usize, else_index: usize) bool {
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

fn genericCfgSupportsTerminalReturnBlock(function: ir.Function, entry: ir.BasicBlock, block: ir.BasicBlock) bool {
    const ret = switch (block.terminator orelse return false) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(function.ret_ty)) return false;
    const ret_value = ret.value orelse return false;
    if (function.ret_ty.eql(.{ .int = 32 })) {
        return genericCfgSupportsI32Value(function, ret_value) or terminalBlockCanMaterializeI32Value(function, entry, block, ret_value);
    }
    return terminalBlockCanMaterializeI64Value(function, entry, block, ret_value);
}

fn terminalScopeInstruction(entry: ir.BasicBlock, block: ir.BasicBlock, name: []const u8) ?ir.Instruction {
    return findInstruction(block, name) orelse findInstruction(entry, name);
}

fn terminalBlockCanMaterializeI32Value(function: ir.Function, entry: ir.BasicBlock, block: ir.BasicBlock, value: ir.Value) bool {
    return switch (value) {
        .int => true,
        .named => |name| blk: {
            if ((paramRegOrNull(function, name, .{ .int = 32 }) catch null) != null) break :blk true;
            const instruction = terminalScopeInstruction(entry, block, name) orelse break :blk false;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (!binary.ty.eql(.{ .int = 32 })) break :blk false;
                    if (machineBinaryOp(binary.op) == null) break :blk false;
                    break :blk terminalBlockCanMaterializeI32Value(function, entry, block, binary.lhs) and
                        terminalBlockCanMaterializeI32Value(function, entry, block, binary.rhs);
                },
                .cast => |cast| {
                    if (cast.op != .trunc or !cast.from_ty.eql(.{ .int = 64 }) or !cast.to_ty.eql(.{ .int = 32 })) break :blk false;
                    break :blk terminalBlockCanMaterializeI64Value(function, entry, block, cast.value);
                },
                else => break :blk false,
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

fn terminalBlockCanMaterializeI64Value(function: ir.Function, entry: ir.BasicBlock, block: ir.BasicBlock, value: ir.Value) bool {
    return switch (value) {
        .int => true,
        .named => |name| blk: {
            if ((paramRegOrNull(function, name, .{ .int = 64 }) catch null) != null) break :blk true;
            const instruction = terminalScopeInstruction(entry, block, name) orelse break :blk false;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (!binary.ty.eql(.{ .int = 64 })) break :blk false;
                    switch (binary.op) {
                        .add, .@"and", .lshr, .shl => {},
                        else => break :blk false,
                    }
                    if (binary.rhs != .int) break :blk false;
                    break :blk terminalBlockCanMaterializeI64Value(function, entry, block, binary.lhs);
                },
                .cast => |cast| {
                    if (cast.op != .zext or !cast.to_ty.eql(.{ .int = 64 })) break :blk false;
                    switch (cast.from_ty) {
                        .int => |bits| if (bits > 32) break :blk false,
                        else => break :blk false,
                    }
                    break :blk terminalBlockCanMaterializeI32Value(function, entry, block, cast.value);
                },
                .select => |select| {
                    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 64 })) break :blk false;
                    break :blk terminalBlockCanMaterializeI64Value(function, entry, block, select.true_value) and
                        terminalBlockCanMaterializeI64Value(function, entry, block, select.false_value);
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

fn emitGenericCfgTerminalConditionTrueBranch(
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
    if (icmp.operand_ty.eql(.{ .int = 64 }) and (icmp.predicate == .eq or icmp.predicate == .ne)) {
        const value = if (isInt(icmp.rhs, 0)) icmp.lhs else if (isInt(icmp.lhs, 0)) icmp.rhs else return error.UnsupportedCodegenValue;
        try emitGenericCfgTerminalI64ValueIntoRax(allocator, machine, function, entry, block, value);
        try machine.instructions.append(allocator, .test_rax_rax);
        try appendGenericCfgConditionalBranch(allocator, machine, if (icmp.predicate == .eq) .je else .jne, true_label);
        return;
    }
    try emitGenericCfgConditionTrueBranch(allocator, machine, function, block, cond, true_label);
}

fn emitGenericCfgTerminalReturnBlock(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    entry: ir.BasicBlock,
    block: ir.BasicBlock,
) !void {
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (function.ret_ty.eql(.{ .int = 32 })) {
        try emitGenericCfgTerminalI32ValueIntoEax(allocator, machine, function, entry, block, ret.value orelse return error.InvalidRet);
    } else if (function.ret_ty.eql(.{ .int = 64 })) {
        try emitGenericCfgTerminalI64ValueIntoRax(allocator, machine, function, entry, block, ret.value orelse return error.InvalidRet);
    } else {
        return error.UnsupportedCodegenType;
    }
    try appendGenericCfgReturn(allocator, machine);
}

fn emitGenericCfgTerminalI32ValueIntoEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    entry: ir.BasicBlock,
    block: ir.BasicBlock,
    value: ir.Value,
) !void {
    switch (value) {
        .int => |int| try machine.instructions.append(allocator, .{ .mov_imm_eax = try i32Value(int) }),
        .named => |name| {
            if ((paramRegOrNull(function, name, .{ .int = 32 }) catch null)) |reg| {
                try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
                return;
            }
            const instruction = terminalScopeInstruction(entry, block, name) orelse return error.UnsupportedCodegenValue;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (!binary.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
                    try emitGenericCfgTerminalI32ValueIntoEax(allocator, machine, function, entry, block, binary.lhs);
                    switch (binary.rhs) {
                        .int => |int| switch (binary.op) {
                            .add => try machine.instructions.append(allocator, .{ .add_eax_imm32 = try i32Value(int) }),
                            .sub => try machine.instructions.append(allocator, .{ .add_eax_imm32 = -try i32Value(int) }),
                            else => return error.UnsupportedCodegenInstruction,
                        },
                        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
                    }
                },
                .cast => |cast| {
                    if (cast.op != .trunc or !cast.from_ty.eql(.{ .int = 64 }) or !cast.to_ty.eql(.{ .int = 32 })) {
                        return error.UnsupportedCodegenInstruction;
                    }
                    try emitGenericCfgTerminalI64ValueIntoRax(allocator, machine, function, entry, block, cast.value);
                },
                else => try emitGenericCfgI32ValueIntoEax(allocator, machine, function, block, value),
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

fn emitGenericCfgTerminalI64ValueIntoRax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    entry: ir.BasicBlock,
    block: ir.BasicBlock,
    value: ir.Value,
) anyerror!void {
    switch (value) {
        .int => |int| try machine.instructions.append(allocator, .{ .mov_imm_rax = try i64Value(int) }),
        .named => |name| {
            if (paramRegOrNull(function, name, .{ .int = 64 }) catch null) |reg| {
                try machine.instructions.append(allocator, .{ .mov_arg_rax = reg });
                return;
            }
            const instruction = terminalScopeInstruction(entry, block, name) orelse return error.UnsupportedCodegenValue;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (!binary.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
                    const rhs = switch (binary.rhs) {
                        .int => |int| try i64Value(int),
                        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
                    };
                    try emitGenericCfgTerminalI64ValueIntoRax(allocator, machine, function, entry, block, binary.lhs);
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
                    try emitGenericCfgTerminalI32ValueIntoEax(allocator, machine, function, entry, block, cast.value);
                },
                .select => |select| try emitGenericCfgTerminalI64SelectIntoRax(allocator, machine, function, entry, block, name, select),
                .call => |call| try emitGenericCfgTerminalI64CallIntoRax(allocator, machine, function, block, call),
                else => return error.UnsupportedCodegenInstruction,
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

fn emitGenericCfgTerminalI64CallIntoRax(
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

fn emitGenericCfgTerminalI64SelectIntoRax(
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
    const cond_instruction = terminalScopeInstruction(entry, block, cond_name) orelse return error.UnsupportedCodegenValue;
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
            const address = genericCfgDynamicI32LoadAddress(function, block, load) orelse return false;
            try emitGenericCfgDynamicI32LoadIntoEax(allocator, machine, address);
        },
        .binary => |binary| {
            if (binary.op != .add or !binary.ty.eql(.{ .int = 32 })) return false;
            const lhs = genericCfgDynamicI32LoadValueAddress(function, block, binary.lhs) orelse return false;
            const rhs = genericCfgDynamicI32LoadValueAddress(function, block, binary.rhs) orelse return false;
            try emitGenericCfgDynamicI32LoadIntoEax(allocator, machine, lhs);
            try emitGenericCfgDynamicI32AddIntoEax(allocator, machine, rhs);
        },
        else => return false,
    }
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub const GenericCfgDynamicI32Address = struct {
    base_reg: ArgReg,
    index_reg: ArgReg,
    offset_elems: i128,
};

fn genericCfgDynamicI32LoadValueAddress(function: ir.Function, block: ir.BasicBlock, value: ir.Value) ?GenericCfgDynamicI32Address {
    const name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const instruction = findInstruction(block, name) orelse return null;
    const load = switch (instruction.kind) {
        .load => |load| load,
        else => return null,
    };
    return genericCfgDynamicI32LoadAddress(function, block, load);
}

fn genericCfgDynamicI32LoadAddress(function: ir.Function, block: ir.BasicBlock, load: ir.LoadInst) ?GenericCfgDynamicI32Address {
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return null;
    return genericCfgDynamicI32Address(function, block, load.ptr);
}

fn genericCfgDynamicI32Address(function: ir.Function, block: ir.BasicBlock, ptr: ir.Value) ?GenericCfgDynamicI32Address {
    const name = switch (ptr) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (paramRegOrNull(function, name, .ptr) catch null) |reg| {
        return .{ .base_reg = reg, .index_reg = .rsi, .offset_elems = 0 };
    }
    const instruction = findInstruction(block, name) orelse return null;
    switch (instruction.kind) {
        .gep => |gep| {
            if (!gep.source_ty.eql(.{ .int = 32 }) or gep.indices.items.len != 1) return null;
            var address = genericCfgDynamicI32Address(function, block, gep.ptr) orelse return null;
            const index = gep.indices.items[0];
            if (!index.ty.eql(.{ .int = 64 })) return null;
            switch (index.value) {
                .int => |int| address.offset_elems += int,
                .named => |index_name| {
                    if (address.index_reg != .rsi or address.offset_elems != 0) return null;
                    const index_reg = paramRegOrNull(function, index_name, .{ .int = 64 }) catch return null;
                    address.index_reg = index_reg orelse return null;
                },
                .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
            }
            return address;
        },
        .load => |load| {
            if (!load.ty.eql(.ptr) or load.attrs.isBarrier()) return null;
            const slot_name = switch (load.ptr) {
                .named => |slot| slot,
                .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
            };
            const stored = genericCfgStoredPointerValue(block, slot_name) orelse return null;
            return genericCfgDynamicI32Address(function, block, stored);
        },
        else => return null,
    }
}

fn genericCfgStoredPointerValue(block: ir.BasicBlock, slot_name: []const u8) ?ir.Value {
    for (block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        const store = switch (instruction.kind) {
            .store => |store| store,
            else => continue,
        };
        if (!store.ty.eql(.ptr) or store.attrs.isBarrier() or !isNamed(store.ptr, slot_name)) continue;
        return store.value;
    }
    return null;
}

fn emitGenericCfgDynamicI32LoadIntoEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    address: GenericCfgDynamicI32Address,
) !void {
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try emitGenericCfgDynamicI32AddIntoEax(allocator, machine, address);
}

fn emitGenericCfgDynamicI32AddIntoEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    address: GenericCfgDynamicI32Address,
) !void {
    if (address.base_reg != .rdi) return error.UnsupportedCodegenAbi;
    if (address.offset_elems < 0 or address.offset_elems > 1) return error.UnsupportedCodegenValue;
    try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = .rcx, .src = address.index_reg } });
    if (address.offset_elems == 1) try machine.instructions.append(allocator, .inc_rcx);
    try machine.instructions.append(allocator, .load_rdi_rcx4_ptr_r8d);
    try machine.instructions.append(allocator, .add_r8d_eax);
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
