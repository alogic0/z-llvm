const shared = @import("core_shared.zig");
const core_cfg_emit = @import("core_cfg_emit.zig");
const core_memory_lowering = @import("core_memory_lowering.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");
const cabi_call_lowering = @import("cabi_call_lowering.zig");

const std = shared.std;
const ir = shared.ir;
const MachineFunction = shared.MachineFunction;
const ArgReg = shared.ArgReg;

const appendGenericCfgBlockLabel = core_cfg_emit.appendGenericCfgBlockLabel;
const appendGenericCfgCompareParamZero = core_cfg_emit.appendGenericCfgCompareParamZero;
const appendGenericCfgConditionalBranch = core_cfg_emit.appendGenericCfgConditionalBranch;
const appendGenericCfgReturn = core_cfg_emit.appendGenericCfgReturn;
const emitGenericCfgIcmpCondition = cabi_call_lowering.emitGenericCfgIcmpCondition;
const findInstruction = cabi_call_lowering.findInstruction;
const genericCfgLoadPtrFromSlot = core_memory_lowering.genericCfgLoadPtrFromSlot;
const genericCfgPointerSlotParam = core_memory_lowering.genericCfgPointerSlotParam;
const i32Value = shared.i32Value;
const isNamed = shared.isNamed;
const paramRegOrNull = cabi_abi_helpers.paramRegOrNull;

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

    try emitAggregateConditionTrueBranch(allocator, machine, function, entry, condbr.cond, then_block.name);
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

fn emitAggregateConditionTrueBranch(
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

fn singleBrTarget(block: ir.BasicBlock) ?[]const u8 {
    return switch (block.terminator orelse return null) {
        .br => |br| br.target,
        else => null,
    };
}

fn blockIndex(function: ir.Function, name: []const u8) ?usize {
    for (function.blocks.items, 0..) |block, index| {
        if (std.mem.eql(u8, block.name, name)) return index;
    }
    return null;
}
