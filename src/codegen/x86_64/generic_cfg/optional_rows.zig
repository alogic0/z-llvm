const shared = @import("core_shared.zig");
const core_cfg_emit = @import("core_cfg_emit.zig");
const core_value_support = @import("core_value_support.zig");
const core_value_emit = @import("core_value_emit.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");
const cabi_call_lowering = @import("cabi_call_lowering.zig");
const pointer_slice_rows = @import("pointer_slice_rows.zig");
const terminal_values = @import("terminal_values.zig");

const std = shared.std;
const ir = shared.ir;
const MachineFunction = shared.MachineFunction;
const ArgReg = shared.ArgReg;

const appendGenericCfgBlockLabel = core_cfg_emit.appendGenericCfgBlockLabel;
const appendGenericCfgConditionalBranch = core_cfg_emit.appendGenericCfgConditionalBranch;
const appendGenericCfgReturn = core_cfg_emit.appendGenericCfgReturn;
const emitGenericCfgI32ValueIntoEax = core_value_emit.emitGenericCfgI32ValueIntoEax;
const emitGenericCfgIcmpCondition = cabi_call_lowering.emitGenericCfgIcmpCondition;
const genericCfgSupportsPointerNullIcmp = core_value_support.genericCfgSupportsPointerNullIcmp;
const isNamed = shared.isNamed;
const paramRegOrNull = cabi_abi_helpers.paramRegOrNull;
const blockIndex = cabi_abi_helpers.blockIndex;
const emitGenericCfgNoreturnCallBlock = pointer_slice_rows.emitGenericCfgNoreturnCallBlock;
const emitGenericCfgConditionTrueBranch = terminal_values.emitGenericCfgConditionTrueBranch;
const singleBrTarget = terminal_values.singleBrTarget;

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

fn blockByName(function: ir.Function, name: []const u8) ?ir.BasicBlock {
    for (function.blocks.items) |block| {
        if (std.mem.eql(u8, block.name, name)) return block;
    }
    return null;
}
