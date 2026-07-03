const shared = @import("core_shared.zig");
const core_cfg_emit = @import("core_cfg_emit.zig");
const core_value_support = @import("core_value_support.zig");
const core_value_emit = @import("core_value_emit.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");
const cabi_call_lowering = @import("cabi_call_lowering.zig");
const pointer_slice_rows = @import("pointer_slice_rows.zig");
const safety_rows = @import("safety_rows.zig");
const branch_merge_rows = @import("branch_merge_rows.zig");
const terminal_values = @import("terminal_values.zig");

const std = shared.std;
const ir = shared.ir;
const MachineFunction = shared.MachineFunction;
const ArgReg = shared.ArgReg;

const appendGenericCfgBlockLabel = core_cfg_emit.appendGenericCfgBlockLabel;
const appendGenericCfgConditionalBranch = core_cfg_emit.appendGenericCfgConditionalBranch;
const appendGenericCfgReturn = core_cfg_emit.appendGenericCfgReturn;
const appendAlignedDirectCall = shared.appendAlignedDirectCall;
const emitGenericCfgI32ValueIntoEax = core_value_emit.emitGenericCfgI32ValueIntoEax;
const emitGenericCfgIcmpCondition = cabi_call_lowering.emitGenericCfgIcmpCondition;
const genericCfgSupportsBranchIcmp = core_value_support.genericCfgSupportsBranchIcmp;
const genericCfgSupportsPointerNullIcmp = core_value_support.genericCfgSupportsPointerNullIcmp;
const isNamed = shared.isNamed;
const paramRegOrNull = cabi_abi_helpers.paramRegOrNull;
const blockIndex = cabi_abi_helpers.blockIndex;
const emitGenericCfgNoreturnCallBlock = pointer_slice_rows.emitGenericCfgNoreturnCallBlock;
const genericCfgGuardPanicBlock = safety_rows.genericCfgGuardPanicBlock;
const appendGenericCfgPhiBinaryImmediate = branch_merge_rows.appendGenericCfgPhiBinaryImmediate;
const genericCfgPhiBinaryReturn = branch_merge_rows.genericCfgPhiBinaryReturn;
const emitGenericCfgConditionTrueBranch = terminal_values.emitGenericCfgConditionTrueBranch;
const singleBrTarget = terminal_values.singleBrTarget;
const i32Value = shared.i32Value;

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

pub fn lowerGenericCfgOptionalPointerFieldLoadReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const plan = genericCfgOptionalPointerFieldLoadPlan(function) orelse return false;
    const hot_is_then = std.mem.eql(u8, plan.then_target, plan.hot_block.name);
    const null_is_then = std.mem.eql(u8, plan.then_target, plan.null_block.name);
    if (!hot_is_then and !null_is_then) return false;

    try machine.instructions.append(allocator, .{ .load_arg_ptr_disp8_rax = .{ .reg = plan.base_reg, .offset = plan.field_offset } });
    try machine.instructions.append(allocator, .test_rax_rax);

    if (plan.non_null_is_true) {
        if (hot_is_then) {
            try appendGenericCfgConditionalBranch(allocator, machine, .je, plan.null_block.name);
            try emitGenericCfgOptionalPointerFieldHotReturn(allocator, machine, plan);
            try appendGenericCfgBlockLabel(allocator, machine, plan.null_block.name);
            try emitGenericCfgOptionalPointerFieldNullReturn(allocator, machine, plan);
        } else {
            try appendGenericCfgConditionalBranch(allocator, machine, .jne, plan.hot_block.name);
            try emitGenericCfgOptionalPointerFieldNullReturn(allocator, machine, plan);
            try appendGenericCfgBlockLabel(allocator, machine, plan.hot_block.name);
            try emitGenericCfgOptionalPointerFieldHotReturn(allocator, machine, plan);
        }
    } else {
        if (null_is_then) {
            try appendGenericCfgConditionalBranch(allocator, machine, .jne, plan.hot_block.name);
            try emitGenericCfgOptionalPointerFieldNullReturn(allocator, machine, plan);
            try appendGenericCfgBlockLabel(allocator, machine, plan.hot_block.name);
            try emitGenericCfgOptionalPointerFieldHotReturn(allocator, machine, plan);
        } else {
            try appendGenericCfgConditionalBranch(allocator, machine, .je, plan.null_block.name);
            try emitGenericCfgOptionalPointerFieldHotReturn(allocator, machine, plan);
            try appendGenericCfgBlockLabel(allocator, machine, plan.null_block.name);
            try emitGenericCfgOptionalPointerFieldNullReturn(allocator, machine, plan);
        }
    }
    return true;
}

pub fn lowerGenericCfgCheckedOptionalPointerReturn(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (function.blocks.items.len != 5) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 1) return false;
    const entry_cond_name = entry.instructions.items[0].result orelse return false;
    const entry_icmp = switch (entry.instructions.items[0].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (entry_icmp.predicate != .ne or !genericCfgSupportsPointerNullIcmp(function, entry_icmp)) return false;
    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, entry_cond_name)) return false;

    const then_block = blockByName(function, entry_br.then_target) orelse return false;
    const else_block = blockByName(function, entry_br.else_target) orelse return false;
    const then_is_guarded = checkedOptionalPointerGuardedBlock(function, then_block) != null;
    const else_is_guarded = checkedOptionalPointerGuardedBlock(function, else_block) != null;
    if (then_is_guarded == else_is_guarded) return false;
    const fallback_block = if (then_is_guarded) else_block else then_block;
    if (!checkedOptionalPointerFallbackBlock(function, fallback_block)) return false;

    const entry_branch_kind = try emitGenericCfgIcmpCondition(allocator, machine, function, entry_icmp);
    try appendGenericCfgConditionalBranch(allocator, machine, entry_branch_kind, entry_br.then_target);
    try emitCheckedOptionalPointerPath(allocator, machine, function, entry_br.else_target);
    try emitCheckedOptionalPointerPath(allocator, machine, function, entry_br.then_target);
    return true;
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
    try core_value_emit.emitGenericCfgLoadI32IntoEax(allocator, machine, function, null, load.ptr);
    try appendGenericCfgPhiBinaryImmediate(allocator, machine, phi_binary);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

fn emitCheckedOptionalPointerPath(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block_name: []const u8,
) !void {
    const block = blockByName(function, block_name) orelse return error.InvalidBranchTarget;
    try appendGenericCfgBlockLabel(allocator, machine, block.name);
    if (checkedOptionalPointerGuardedBlock(function, block)) |guard| {
        const guard_branch_kind = try emitGenericCfgIcmpCondition(allocator, machine, function, guard.icmp);
        try appendGenericCfgConditionalBranch(allocator, machine, guard_branch_kind, guard.then_target);
        try emitCheckedOptionalPointerTerminalBlock(allocator, machine, function, guard.else_target);
        try emitCheckedOptionalPointerTerminalBlock(allocator, machine, function, guard.then_target);
        return;
    }
    try emitCheckedOptionalPointerReturnBlock(allocator, machine, function, block);
}

const GenericCfgOptionalPointerFieldLoadPlan = struct {
    base_reg: ArgReg,
    field_offset: u8,
    then_target: []const u8,
    non_null_is_true: bool,
    hot_block: ir.BasicBlock,
    null_block: ir.BasicBlock,
    add_imm: i32,
    null_value: i32,
};

fn genericCfgOptionalPointerFieldLoadPlan(function: ir.Function) ?GenericCfgOptionalPointerFieldLoadPlan {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 1) return null;
    if (!function.params.items[0].ty.eql(.ptr) or function.blocks.items.len != 3) return null;
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len < 3) return null;

    const cond_inst = entry.instructions.items[entry.instructions.items.len - 1];
    const cond_name = cond_inst.result orelse return null;
    const icmp = switch (cond_inst.kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (!icmp.operand_ty.eql(.ptr)) return null;
    const non_null_is_true = switch (icmp.predicate) {
        .ne => true,
        .eq => false,
        else => return null,
    };
    const payload_name = pointerNullIcmpNamedOperand(icmp) orelse return null;
    const payload_load = findInstruction(entry, payload_name) orelse return null;
    const load_field = switch (payload_load.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load_field.ty.eql(.ptr) or load_field.attrs.isBarrier()) return null;
    const base_name = switch (load_field.ptr) {
        .named => |name| name,
        else => return null,
    };
    const base_reg = optionalPointerFieldBaseReg(function, entry, base_name) orelse return null;

    const condbr = switch (entry.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, cond_name)) return null;
    const then_block = blockByName(function, condbr.then_target) orelse return null;
    const else_block = blockByName(function, condbr.else_target) orelse return null;
    const then_hot = optionalPointerFieldHotReturn(then_block, payload_name);
    const else_hot = optionalPointerFieldHotReturn(else_block, payload_name);
    const then_null = optionalPointerFieldNullReturn(function, then_block);
    const else_null = optionalPointerFieldNullReturn(function, else_block);
    if ((then_hot != null) == (else_hot != null)) return null;
    if ((then_null != null) == (else_null != null)) return null;

    return .{
        .base_reg = base_reg,
        .field_offset = 0,
        .then_target = condbr.then_target,
        .non_null_is_true = non_null_is_true,
        .hot_block = if (then_hot != null) then_block else else_block,
        .null_block = if (then_null != null) then_block else else_block,
        .add_imm = then_hot orelse else_hot.?,
        .null_value = then_null orelse else_null.?,
    };
}

fn optionalPointerFieldBaseReg(function: ir.Function, entry: ir.BasicBlock, base_name: []const u8) ?ArgReg {
    if (paramRegOrNull(function, base_name, .ptr) catch null) |reg| return reg;
    const base_load_inst = findInstruction(entry, base_name) orelse return null;
    const base_load = switch (base_load_inst.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!base_load.ty.eql(.ptr) or base_load.attrs.isBarrier()) return null;
    const slot_name = switch (base_load.ptr) {
        .named => |name| name,
        else => return null,
    };
    for (entry.instructions.items) |instruction| {
        const store = switch (instruction.kind) {
            .store => |store| store,
            else => continue,
        };
        if (!store.ty.eql(.ptr) or store.attrs.isBarrier() or !isNamed(store.ptr, slot_name)) continue;
        const stored_name = switch (store.value) {
            .named => |name| name,
            else => return null,
        };
        return paramRegOrNull(function, stored_name, .ptr) catch null;
    }
    return null;
}

fn pointerNullIcmpNamedOperand(icmp: ir.IcmpInst) ?[]const u8 {
    if (icmp.lhs == .null_value) return switch (icmp.rhs) {
        .named => |name| name,
        else => null,
    };
    if (icmp.rhs == .null_value) return switch (icmp.lhs) {
        .named => |name| name,
        else => null,
    };
    return null;
}

fn optionalPointerFieldHotReturn(block: ir.BasicBlock, payload_name: []const u8) ?i32 {
    if (block.instructions.items.len == 0 or block.instructions.items.len > 2) return null;
    const load_name = block.instructions.items[0].result orelse return null;
    const load = switch (block.instructions.items[0].kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier() or !isNamed(load.ptr, payload_name)) return null;

    var ret_source: ir.Value = .{ .named = load_name };
    var add_imm: i32 = 0;
    if (block.instructions.items.len == 2) {
        const binary_name = block.instructions.items[1].result orelse return null;
        const binary = switch (block.instructions.items[1].kind) {
            .binary => |binary| binary,
            else => return null,
        };
        if (!binary.ty.eql(.{ .int = 32 }) or binary.op != .add or !isNamed(binary.lhs, load_name)) return null;
        add_imm = switch (binary.rhs) {
            .int => |value| i32Value(value) catch return null,
            else => return null,
        };
        ret_source = .{ .named = binary_name };
    }

    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !(ret.value orelse return null).eql(ret_source)) return null;
    return add_imm;
}

fn optionalPointerFieldNullReturn(function: ir.Function, block: ir.BasicBlock) ?i32 {
    if (block.instructions.items.len != 0) return null;
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(function.ret_ty)) return null;
    return switch (ret.value orelse return null) {
        .int => |value| i32Value(value) catch return null,
        else => null,
    };
}

fn emitGenericCfgOptionalPointerFieldHotReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    plan: GenericCfgOptionalPointerFieldLoadPlan,
) !void {
    _ = plan.hot_block;
    try machine.instructions.append(allocator, .load_rax_ptr_eax);
    if (plan.add_imm != 0) try machine.instructions.append(allocator, .{ .add_eax_imm32 = plan.add_imm });
    try appendGenericCfgReturn(allocator, machine);
}

fn emitGenericCfgOptionalPointerFieldNullReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    plan: GenericCfgOptionalPointerFieldLoadPlan,
) !void {
    _ = plan.null_block;
    try machine.instructions.append(allocator, .{ .mov_imm_eax = plan.null_value });
    try appendGenericCfgReturn(allocator, machine);
}

const CheckedOptionalPointerGuard = struct {
    icmp: ir.IcmpInst,
    then_target: []const u8,
    else_target: []const u8,
};

fn checkedOptionalPointerGuardedBlock(function: ir.Function, block: ir.BasicBlock) ?CheckedOptionalPointerGuard {
    if (block.instructions.items.len != 1) return null;
    const cond_name = block.instructions.items[0].result orelse return null;
    const icmp = switch (block.instructions.items[0].kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (icmp.predicate != .ne or !genericCfgSupportsPointerNullIcmp(function, icmp)) return null;
    const terminator = switch (block.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!terminator.cond_ty.eql(.{ .int = 1 }) or !isNamed(terminator.cond, cond_name)) return null;
    const then_block = blockByName(function, terminator.then_target) orelse return null;
    const else_block = blockByName(function, terminator.else_target) orelse return null;
    const then_is_return = checkedOptionalPointerLoadReturnBlock(function, then_block);
    const else_is_return = checkedOptionalPointerLoadReturnBlock(function, else_block);
    const then_is_panic = genericCfgNoreturnBlock(then_block);
    const else_is_panic = genericCfgNoreturnBlock(else_block);
    if (!((then_is_return and else_is_panic) or (then_is_panic and else_is_return))) return null;
    return .{ .icmp = icmp, .then_target = terminator.then_target, .else_target = terminator.else_target };
}

fn checkedOptionalPointerFallbackBlock(function: ir.Function, block: ir.BasicBlock) bool {
    if (block.instructions.items.len != 0) return false;
    const ret = switch (block.terminator orelse return false) {
        .ret => |ret| ret,
        else => return false,
    };
    return ret.ty.eql(function.ret_ty) and ret.value != null;
}

fn checkedOptionalPointerLoadReturnBlock(function: ir.Function, block: ir.BasicBlock) bool {
    if (block.instructions.items.len != 1) return false;
    const load_name = block.instructions.items[0].result orelse return false;
    const load = switch (block.instructions.items[0].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
    const ptr_name = switch (load.ptr) {
        .named => |name| name,
        else => return false,
    };
    if ((paramRegOrNull(function, ptr_name, .ptr) catch null) == null) return false;
    const ret = switch (block.terminator orelse return false) {
        .ret => |ret| ret,
        else => return false,
    };
    return ret.ty.eql(.{ .int = 32 }) and isNamed(ret.value orelse return false, load_name);
}

fn emitCheckedOptionalPointerTerminalBlock(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block_name: []const u8,
) !void {
    const block = blockByName(function, block_name) orelse return error.InvalidBranchTarget;
    try appendGenericCfgBlockLabel(allocator, machine, block.name);
    if (checkedOptionalPointerLoadReturnBlock(function, block)) {
        return try emitCheckedOptionalPointerReturnBlock(allocator, machine, function, block);
    }
    if (genericCfgNoreturnBlock(block)) {
        return try emitGenericCfgNoreturnCallBlock(allocator, machine, function, block);
    }
    return error.UnsupportedCodegenControlFlow;
}

fn emitCheckedOptionalPointerReturnBlock(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
) !void {
    if (block.instructions.items.len == 1) {
        const load = switch (block.instructions.items[0].kind) {
            .load => |load| load,
            else => return error.UnsupportedCodegenInstruction,
        };
        try core_value_emit.emitGenericCfgLoadI32IntoEax(allocator, machine, function, null, load.ptr);
    } else {
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            else => return error.UnsupportedCodegenControlFlow,
        };
        try emitGenericCfgI32ValueIntoEax(allocator, machine, function, block, ret.value orelse return error.UnsupportedCodegenValue);
    }
    try appendGenericCfgReturn(allocator, machine);
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

fn findInstruction(block: ir.BasicBlock, name: []const u8) ?ir.Instruction {
    for (block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        const result = instruction.result orelse continue;
        if (std.mem.eql(u8, result, name)) return instruction;
    }
    return null;
}
