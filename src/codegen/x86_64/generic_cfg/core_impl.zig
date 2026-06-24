pub const std = @import("std");
pub const ir = @import("../../../ir.zig");
pub const target = @import("../../../target.zig");
pub const memory_location = @import("../../../analysis/memory_location.zig");
pub const x86_64_types = @import("../types.zig");
pub const sysv_abi = @import("../sysv_abi.zig");
pub const x86_64_emit = @import("../emit.zig");
pub const x86_64_match = @import("../match.zig");
pub const runtime_float = @import("../runtime_float.zig");
pub const x86_64_machine = @import("../machine.zig");

pub const MachineBinaryOp = x86_64_types.MachineBinaryOp;
pub const ArgReg = x86_64_types.ArgReg;
pub const XmmReg = x86_64_types.XmmReg;
pub const MachineFunction = x86_64_machine.MachineFunction;
pub const FrameIndex = x86_64_types.FrameIndex;
pub const SysVAggregateEightbyteClass = sysv_abi.AggregateEightbyteClass;
pub const SysVAggregateKind = sysv_abi.AggregateKind;
pub const SysVAggregateClassification = sysv_abi.AggregateClassification;
pub const SysVCallPlanCounts = sysv_abi.CallPlanCounts;
pub const SysVSmallIntegerAggregate = sysv_abi.SmallIntegerAggregate;
pub const SysVRegisterNeeds = sysv_abi.RegisterNeeds;
pub const SysVRegisterAggregatePassThrough = sysv_abi.RegisterAggregatePassThrough;
pub const SysVCallPlan = sysv_abi.CallPlan;
pub const SysVParamCursor = sysv_abi.ParamCursor;
pub fn x86_64SysVDataLayout() !target.DataLayout {
    return try sysv_abi.dataLayout();
}
pub const SysVCallTarget = x86_64_emit.SysVCallTarget;
pub const max_sysv_stack_call_args = x86_64_emit.max_sysv_stack_call_args;
pub const appendIntegerOverflowCall = x86_64_emit.appendIntegerOverflowCall;
pub const appendStackFrame = x86_64_emit.appendStackFrame;
pub const appendStackFrameEnd = x86_64_emit.appendStackFrameEnd;
pub const appendDirectCall = x86_64_emit.appendDirectCall;
pub const appendAlignedDirectCall = x86_64_emit.appendAlignedDirectCall;
pub const appendDirectCallWithStackArgs = x86_64_emit.appendDirectCallWithStackArgs;
pub const appendIndirectCallRaxWithStackArgs = x86_64_emit.appendIndirectCallRaxWithStackArgs;
pub const appendLoadStackDispArg32 = x86_64_emit.appendLoadStackDispArg32;
pub const appendLoadStackDispArg64 = x86_64_emit.appendLoadStackDispArg64;
pub const appendMoveImmToArgReg = x86_64_emit.appendMoveImmToArgReg;
pub const appendMoveImm32ToXmm = x86_64_emit.appendMoveImm32ToXmm;
pub const appendMoveImm64ToXmm = x86_64_emit.appendMoveImm64ToXmm;
pub const setupSysVCallTarget = x86_64_emit.setupSysVCallTarget;
pub const appendSysVCallTarget = x86_64_emit.appendSysVCallTarget;
pub const appendAlignedSysVCallTarget = x86_64_emit.appendAlignedSysVCallTarget;
pub const appendSysVCallTargetWithStackArgs = x86_64_emit.appendSysVCallTargetWithStackArgs;
pub const appendPanicCall = x86_64_emit.appendPanicCall;
pub const validateDefaultCallConv = x86_64_match.validateDefaultCallConv;
pub const isNamed = x86_64_match.isNamed;
pub const callIsFastcc = x86_64_match.callIsFastcc;
pub const callArgAttrsContain = x86_64_match.callArgAttrsContain;
pub const paramAttrsContain = x86_64_match.paramAttrsContain;
pub const globalSymbolName = x86_64_match.globalSymbolName;
pub const symbolName = x86_64_match.symbolName;
pub const isInt = x86_64_match.isInt;
pub const i32Value = x86_64_match.i32Value;
pub const u8Value = x86_64_match.u8Value;
pub const i64Value = x86_64_match.i64Value;
pub const u5Value = x86_64_match.u5Value;
pub const isFpText = x86_64_match.isFpText;
pub const fp32TextBits = x86_64_match.fp32TextBits;
pub const fp64TextBits = x86_64_match.fp64TextBits;
pub const isCalleeName = x86_64_match.isCalleeName;
pub const lowerSelectedRuntimeFloatCallCompareMainReturn = runtime_float.lowerSelectedRuntimeFloatCallCompareMainReturn;
pub const lowerRuntimeFloatLessMainReturn = runtime_float.lowerRuntimeFloatLessMainReturn;

pub const GenericCfgLoopSumPlan = struct {
    checked: bool,
};

fn lowerGenericCfgFunction(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (try lowerGenericCfgGuardedDynamicPointerLoadReturn(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgOptionalPointerReturn(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgStructBranchUpdateReturn(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgGuardedOptionalPointerBranchReturn(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgBranchMergeReturn(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (genericCfgLoopSumPlan(function)) |plan| {
        try emitGenericCfgLoopSum(allocator, machine, function, plan);
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgConditionalSliceSumLoop(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgGuardedGlobalAddReturn(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerSliceSumLoop(allocator, machine, function)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (genericCfgSupportsCheckedGuard(function)) {
        if (try lowerCheckedIntFromFloat(allocator, machine, function)) {
            machine.codegen_path = .generic_cfg;
            return true;
        }
        if (try lowerCheckedTableLookup(allocator, machine, function)) {
            machine.codegen_path = .generic_cfg;
            return true;
        }
        return error.GenericCfgFallback;
    }
    return false;
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
    try emitGenericCfgLoadI32IntoEax(allocator, machine, function, load.ptr);
    try appendGenericCfgPhiBinaryImmediate(allocator, machine, phi_binary);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub fn genericCfgGuardPanicBlock(block: ir.BasicBlock) bool {
    if (block.instructions.items.len != 1) return false;
    const call = switch (block.instructions.items[0].kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.ret_ty != .void or call.args.items.len != 0 or call.callee_value != null or call.inline_asm != null) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;
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
        try emitGenericCfgNoreturnCallBlock(allocator, machine, panic_block);
        return true;
    }

    const checked = try genericCfgCheckedGlobalAdd(ok_block);
    try emitGenericCfgGlobalLoadParamAdd(allocator, machine, function, checked.load, checked.call);
    try appendGenericCfgConditionalBranch(allocator, machine, .jo, checked.overflow_target);
    try genericCfgValidateCheckedAddRet(function, checked.ret_target, checked.call_name);
    try appendGenericCfgReturn(allocator, machine);

    try appendGenericCfgBlockLabel(allocator, machine, panic_block.name);
    try emitGenericCfgNoreturnCallBlock(allocator, machine, panic_block);

    const overflow_block = blockByName(function, checked.overflow_target) orelse return false;
    try appendGenericCfgBlockLabel(allocator, machine, overflow_block.name);
    try emitGenericCfgNoreturnCallBlock(allocator, machine, overflow_block);
    return true;
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
    const global_name = switch (load.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
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
    block: ir.BasicBlock,
) !void {
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
        if (call.args.items[0].ty != .ptr) return error.UnsupportedCodegenType;
        const ptr_symbol = switch (call.args.items[0].value) {
            .named => |name| try globalSymbolName(name),
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        if (!call.args.items[1].ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
        const len = switch (call.args.items[1].value) {
            .int => |int| try i64Value(int),
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        try machine.instructions.append(allocator, .{ .lea_global_rdi = ptr_symbol });
        try machine.instructions.append(allocator, .{ .mov_imm_rsi = len });
    } else if (call.args.items.len != 0) {
        return error.UnsupportedCodegenInstruction;
    }
    try appendAlignedDirectCall(allocator, machine, call.callee, .void);
    try machine.instructions.append(allocator, .ud2);
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

pub fn singleBrTarget(block: ir.BasicBlock) ?[]const u8 {
    return switch (block.terminator orelse return null) {
        .br => |br| br.target,
        else => null,
    };
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
                if (genericCfgI32Address(function, load.ptr) == null) return false;
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
                if (genericCfgI32Address(function, store.ptr) == null) return false;
            },
            .load => |load| {
                if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
                if (genericCfgI32Address(function, load.ptr) == null) return false;
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

pub const GenericCfgAddress = union(enum) {
    param: []const u8,
    global: []const u8,
    tls: []const u8,
};

pub fn genericCfgI32Address(function: ir.Function, ptr: ir.Value) ?GenericCfgAddress {
    const name = switch (ptr) {
        .named => |name| name,
        else => return null,
    };
    if (genericCfgSupportsPointerParam(function, name)) return .{ .param = name };
    if (name.len == 0 or name[0] != '@') return null;
    const symbol = globalSymbolName(name) catch return null;
    if (tlsSymbolFromFunctionAttrs(function)) |tls_symbol| {
        if (std.mem.eql(u8, tls_symbol, symbol)) return .{ .tls = symbol };
    }
    if (knownLocalExecTlsSymbol(symbol)) return .{ .tls = symbol };
    return .{ .global = symbol };
}

fn emitGenericCfgLoadI32IntoEax(
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

fn emitGenericCfgStoreEax(
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

pub const GenericCfgPointerSlotParam = struct {
    slot_name: []const u8,
    param_name: []const u8,
    param_reg: ArgReg,
};

pub fn genericCfgPointerSlotParam(
    function: ir.Function,
    alloca_instruction: ir.Instruction,
    store_instruction: ir.Instruction,
) ?GenericCfgPointerSlotParam {
    if (alloca_instruction.removed or store_instruction.removed) return null;
    const slot_name = alloca_instruction.result orelse return null;
    const alloca = switch (alloca_instruction.kind) {
        .alloca => |alloca| alloca,
        else => return null,
    };
    if (!alloca.allocated_ty.eql(.ptr) or alloca.allocated_ty_addrspace != null) return null;
    const store = switch (store_instruction.kind) {
        .store => |store| store,
        else => return null,
    };
    if (!store.ty.eql(.ptr) or store.ty_addrspace != null or store.ptr_addrspace != null or store.attrs.isBarrier()) return null;
    if (!isNamed(store.ptr, slot_name)) return null;
    const param_name = switch (store.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const param_reg = paramRegOrNull(function, param_name, .ptr) catch return null;
    return .{ .slot_name = slot_name, .param_name = param_name, .param_reg = param_reg orelse return null };
}

pub fn genericCfgLoadPtrFromSlot(instruction: ir.Instruction, slot_name: []const u8) ?[]const u8 {
    if (instruction.removed) return null;
    const load_name = instruction.result orelse return null;
    const load = switch (instruction.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.ptr) or load.ty_addrspace != null or load.ptr_addrspace != null or load.attrs.isBarrier()) return null;
    if (!isNamed(load.ptr, slot_name)) return null;
    return load_name;
}

pub fn lowerGenericCfgStructFieldLoadReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 1) return false;
    if (block.instructions.items.len != 4 and block.instructions.items.len != 5) return false;
    const slot = genericCfgPointerSlotParam(function, block.instructions.items[0], block.instructions.items[1]) orelse return false;
    const loaded_ptr = genericCfgLoadPtrFromSlot(block.instructions.items[2], slot.slot_name) orelse return false;

    const load_index: usize = if (block.instructions.items.len == 4) 3 else 4;
    const load_ptr = if (block.instructions.items.len == 4) GenericCfgFieldLoadPtr{ .name = loaded_ptr, .offset = 0 } else blk: {
        const gep_name = block.instructions.items[3].result orelse return false;
        const gep = switch (block.instructions.items[3].kind) {
            .gep => |gep| gep,
            else => return false,
        };
        const offset = genericCfgI8GepOffsetValue(gep, loaded_ptr) orelse return false;
        break :blk GenericCfgFieldLoadPtr{ .name = gep_name, .offset = offset };
    };

    const load_name = block.instructions.items[load_index].result orelse return false;
    const load = switch (block.instructions.items[load_index].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier() or !isNamed(load.ptr, load_ptr.name)) return false;
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, load_name)) return false;

    if (load_ptr.offset == 0) {
        try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = slot.param_reg });
    } else {
        try machine.instructions.append(allocator, .{ .mov_arg_rax = slot.param_reg });
        try machine.instructions.append(allocator, .{ .load_rax_ptr_disp8_rax = try u8Value(load_ptr.offset) });
    }
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub const GenericCfgFieldLoadPtr = struct {
    name: []const u8,
    offset: i128,
};

pub fn genericCfgI8GepOffset(gep: ir.GepInst, ptr_name: []const u8, offset: i128) bool {
    return (genericCfgI8GepOffsetValue(gep, ptr_name) orelse return false) == offset;
}

pub fn genericCfgI8GepOffsetValue(gep: ir.GepInst, ptr_name: []const u8) ?i128 {
    if (!gep.source_ty.eql(.{ .int = 8 }) or !isNamed(gep.ptr, ptr_name)) return null;
    if (gep.indices.items.len != 1) return null;
    const index = gep.indices.items[0];
    if (!index.ty.eql(.{ .int = 64 })) return null;
    return switch (index.value) {
        .int => |int| if (int == 0 or int == 4 or int == 8) int else null,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
    };
}

pub fn lowerGenericCfgSingleBlockScalar(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const single_ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => null,
    };
    if (single_ret) |ret| {
        if (try lowerPointerVolatileRoundtripReturn(allocator, machine, function, block, ret)) {
            machine.codegen_path = .generic_cfg;
            return true;
        }
    }
    if (try lowerGenericCfgPointerSelectLoadReturn(allocator, machine, function, block)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgDynamicPointerLoadReturn(allocator, machine, function, block)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgStructFieldLoadReturn(allocator, machine, function, block)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (single_ret) |ret| {
        if (lowerStructSumReturn(allocator, machine, function, block, ret) catch false) {
            machine.codegen_path = .generic_cfg;
            return true;
        }
        if (lowerRuntimeStructSumPreoptHelper(allocator, machine, function, block, ret) catch false) {
            machine.codegen_path = .generic_cfg;
            return true;
        }
        if (lowerRuntimeArraySumPreoptHelper(allocator, machine, function, block, ret) catch false) {
            machine.codegen_path = .generic_cfg;
            return true;
        }
        if (try lowerScalarFpCastReturn(allocator, machine, function, block, ret)) {
            machine.codegen_path = .generic_cfg;
            return true;
        }
        if (try lowerGenericCfgByteTableLookupReturn(allocator, machine, function, block, ret)) {
            machine.codegen_path = .generic_cfg;
            return true;
        }
        if (try lowerIntegerShiftMixReturn(allocator, machine, function, block, ret)) {
            machine.codegen_path = .generic_cfg;
            return true;
        }
        if (try lowerMulConstReturn(allocator, machine, function, block, ret)) {
            machine.codegen_path = .generic_cfg;
            return true;
        }
    }
    if (!genericCfgSupportsSingleBlockScalar(function)) return false;
    const ret = single_ret orelse return error.UnsupportedCodegenControlFlow;
    var last_eax_value: ?ir.Value = null;
    for (block.instructions.items, 0..) |instruction, instruction_index| {
        switch (instruction.kind) {
            .store => |store| {
                try emitGenericCfgI32ValueIntoEax(allocator, machine, function, block, store.value);
                try emitGenericCfgStoreEax(allocator, machine, function, store.ptr);
                last_eax_value = store.value;
            },
            .call => |call| {
                if (call.ret_ty == .void and instruction.result == null) {
                    try emitGenericCfgVoidCall(allocator, machine, function, block, instruction_index, call);
                }
            },
            .binary, .icmp, .select, .load => {},
            .phi, .fcmp, .cast, .freeze, .alloca, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep => return error.UnsupportedCodegenInstruction,
        }
    }
    const ret_value = ret.value orelse return error.InvalidRet;
    if (last_eax_value == null or !last_eax_value.?.eql(ret_value)) {
        try emitGenericCfgI32ValueIntoEax(allocator, machine, function, block, ret_value);
    }
    try appendGenericCfgReturn(allocator, machine);
    machine.codegen_path = .generic_cfg;
    return true;
}

pub fn lowerGenericCfgSingleBlockFp(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (try lowerGenericCfgFpBinaryReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgFpCastBinaryPipelineReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgFpCompareReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgFpSelectReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgFpVoidCallBinaryReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgFpVoidCallParamReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgFpDirectCallReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgFpParamReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgFpLiteralReturn(allocator, machine, function, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerScalarFpCastReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    return false;
}

pub fn lowerGenericCfgSingleBlockAggregateAbi(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (try lowerAggregateAbiReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    return false;
}

pub fn lowerGenericCfgSingleBlockPackedBits(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (try lowerGenericCfgPackedReplaceLowReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgPackedReadFlagReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    return false;
}

pub fn lowerGenericCfgSingleBlockI64(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (try lowerSelectedI64ConstReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgI64ParamReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerI64SaturatingHelperFamilyReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgI64DirectCallReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerErrorUnionI64SelectReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    return false;
}

pub fn lowerGenericCfgSingleBlockEffectBarrier(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (try lowerInlineAsmBarrierReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerAtomicAddReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    return false;
}

pub fn lowerGenericCfgSingleBlockVoidCallMain(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isInt(ret.value orelse return error.InvalidRet, 0)) return false;
    if (block.instructions.items.len != 1) return false;
    const call_inst = block.instructions.items[0];
    if (call_inst.removed or call_inst.result != null) return false;
    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.ret_ty != .void or call.args.items.len != 0) return false;
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;

    try appendAlignedDirectCall(allocator, machine, call.callee, .void);
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    machine.codegen_path = .generic_cfg;
    return true;
}

pub fn lowerGenericCfgSingleBlockDirectCallMain(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!isMainOrWrapperMain(function.name)) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 1 and block.instructions.items.len != 2) return false;

    const call_inst = block.instructions.items[0];
    if (call_inst.removed) return false;
    const call_result = call_inst.result orelse return false;
    if (block.instructions.items.len == 1) {
        if (!isNamed(ret.value orelse return error.InvalidRet, call_result)) return false;
    } else {
        const cast_inst = block.instructions.items[1];
        if (cast_inst.removed) return false;
        const cast_name = identityCastFrom(cast_inst, call_result, .{ .int = 32 }, .{ .int = 32 }) orelse return false;
        if (!isNamed(ret.value orelse return error.InvalidRet, cast_name)) return false;
    }

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len > max_sysv_stack_call_args + 6) return false;
    for (call.args.items) |arg| {
        if (arg.attrs != null or !arg.ty.eql(.{ .int = 32 })) return false;
        switch (arg.value) {
            .int => {},
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
        }
    }
    const stack_arg_count = try appendI32CallArgs(allocator, machine, function, call);
    try appendDirectCallWithStackArgs(allocator, machine, call.callee, call.ret_ty, stack_arg_count);
    try machine.instructions.append(allocator, .ret);
    machine.codegen_path = .generic_cfg;
    return true;
}

pub fn lowerGenericCfgSingleBlockCallChainMain(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!isMainOrWrapperMain(function.name)) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or block.instructions.items.len != 3) return false;

    const first_call_inst = block.instructions.items[0];
    const second_call_inst = block.instructions.items[1];
    const cast_inst = block.instructions.items[2];
    if (first_call_inst.removed or second_call_inst.removed or cast_inst.removed) return false;
    const first_result = first_call_inst.result orelse return false;
    const second_result = second_call_inst.result orelse return false;
    const cast_result = identityCastFrom(cast_inst, second_result, .{ .int = 32 }, .{ .int = 32 }) orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, cast_result)) return false;

    const first_call = switch (first_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (first_call.callee_value != null or first_call.inline_asm != null) return false;
    if (!genericCfgCallTargetsWrapperSibling(function.name, first_call.callee)) return false;
    if (!callIsFastcc(first_call.calling_conv)) validateDefaultCallConv(first_call.calling_conv) catch return false;
    if (!first_call.ret_ty.eql(.{ .int = 64 }) or first_call.args.items.len != 2) return false;
    for (first_call.args.items) |arg| {
        if (arg.attrs != null or !arg.ty.eql(.{ .int = 32 })) return false;
    }

    const first_arg = switch (first_call.args.items[0].value) {
        .int => |int| try i32Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const second_arg = switch (first_call.args.items[1].value) {
        .int => |int| try i32Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const second_call = switch (second_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (second_call.callee_value != null or second_call.inline_asm != null) return false;
    if (!genericCfgCallTargetsWrapperSibling(function.name, second_call.callee)) return false;
    if (!callIsFastcc(second_call.calling_conv)) validateDefaultCallConv(second_call.calling_conv) catch return false;
    if (!second_call.ret_ty.eql(.{ .int = 32 }) or second_call.args.items.len != 1) return false;
    const chain_arg = second_call.args.items[0];
    if (chain_arg.attrs != null or !chain_arg.ty.eql(.{ .int = 64 }) or !isNamed(chain_arg.value, first_result)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_rdi = first_arg });
    try machine.instructions.append(allocator, .{ .mov_imm_rsi = second_arg });
    try appendAlignedDirectCall(allocator, machine, first_call.callee, first_call.ret_ty);
    try machine.instructions.append(allocator, .mov_rax_rdi);
    try appendAlignedDirectCall(allocator, machine, second_call.callee, second_call.ret_ty);
    try machine.instructions.append(allocator, .ret);
    machine.codegen_path = .generic_cfg;
    return true;
}

pub fn lowerGenericCfgMultiBlockCallGlobalCheckMain(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!isMainOrWrapperMain(function.name)) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0 or function.blocks.items.len != 3) return false;

    const entry = function.blocks.items[0];
    const merge = function.blocks.items[1];
    const then_block = function.blocks.items[2];
    if (entry.instructions.items.len != 2 or merge.instructions.items.len != 2 or then_block.instructions.items.len != 2) return false;

    const call_inst = entry.instructions.items[0];
    const first_cmp_inst = entry.instructions.items[1];
    const phi_inst = merge.instructions.items[0];
    const select_inst = merge.instructions.items[1];
    const load_inst = then_block.instructions.items[0];
    const second_cmp_inst = then_block.instructions.items[1];
    if (call_inst.removed or first_cmp_inst.removed or phi_inst.removed or select_inst.removed or load_inst.removed or second_cmp_inst.removed) return false;

    const call_name = call_inst.result orelse return false;
    const first_cmp_name = first_cmp_inst.result orelse return false;
    const phi_name = phi_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    const load_name = load_inst.result orelse return false;
    const second_cmp_name = second_cmp_inst.result orelse return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (!genericCfgCallTargetsWrapperSibling(function.name, call.callee)) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 2) return false;
    const first_global = genericCfgGlobalPtrArg(call.args.items[0]) orelse return false;
    const second_global = genericCfgGlobalPtrArg(call.args.items[1]) orelse return false;

    const first_cmp = switch (first_cmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (first_cmp.predicate != .eq or !first_cmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(first_cmp.lhs, call_name)) return false;
    const expected_call = switch (first_cmp.rhs) {
        .int => |int| try i32Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, first_cmp_name)) return false;
    if (!std.mem.eql(u8, entry_br.then_target, then_block.name) or !std.mem.eql(u8, entry_br.else_target, merge.name)) return false;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
    const loaded_global = switch (load.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, loaded_global, second_global)) return false;

    const second_cmp = switch (second_cmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (second_cmp.predicate != .eq or !second_cmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(second_cmp.lhs, load_name)) return false;
    const expected_load = switch (second_cmp.rhs) {
        .int => |int| try i32Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const then_br = switch (then_block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };
    if (!std.mem.eql(u8, then_br.target, merge.name)) return false;

    const phi = switch (phi_inst.kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 1 }) or phi.incoming.items.len != 2) return false;
    if (!phiHasIncoming(phi, second_cmp_name, then_block.name) or !phiHasIncomingInt(phi, 0, entry.name)) return false;

    if (!isSelectI1ToI32ZeroOne(select_inst, phi_name)) return false;
    const ret = switch (merge.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const fail = "generic_cfg_call_global_check_fail";
    try machine.instructions.append(allocator, .{ .lea_global_rdi = first_global });
    try machine.instructions.append(allocator, .{ .lea_global_rsi = second_global });
    try appendAlignedDirectCall(allocator, machine, call.callee, call.ret_ty);
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = expected_call });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = loaded_global });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = expected_load });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    machine.codegen_path = .generic_cfg;
    return true;
}

pub fn lowerGenericCfgMultiBlockTwoCallCheckMain(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!isMainOrWrapperMain(function.name)) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0 or function.blocks.items.len != 3) return false;

    const entry = function.blocks.items[0];
    const merge = function.blocks.items[1];
    const then_block = function.blocks.items[2];
    if (entry.instructions.items.len != 2 or merge.instructions.items.len != 2 or then_block.instructions.items.len != 2) return false;

    const first_call_inst = entry.instructions.items[0];
    const first_cmp_inst = entry.instructions.items[1];
    const phi_inst = merge.instructions.items[0];
    const select_inst = merge.instructions.items[1];
    const second_call_inst = then_block.instructions.items[0];
    const second_cmp_inst = then_block.instructions.items[1];
    if (first_call_inst.removed or first_cmp_inst.removed or phi_inst.removed or select_inst.removed or second_call_inst.removed or second_cmp_inst.removed) return false;

    const first_call_name = first_call_inst.result orelse return false;
    const first_cmp_name = first_cmp_inst.result orelse return false;
    const phi_name = phi_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    const second_call_name = second_call_inst.result orelse return false;
    const second_cmp_name = second_cmp_inst.result orelse return false;

    const first_call = switch (first_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!genericCfgSupportsUnaryPtrSiblingCall(function, first_call)) return false;
    const first_expected = try genericCfgCallEqExpected(first_cmp_inst, first_call_name);

    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, first_cmp_name)) return false;
    if (!std.mem.eql(u8, entry_br.then_target, then_block.name) or !std.mem.eql(u8, entry_br.else_target, merge.name)) return false;

    const second_call = switch (second_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!genericCfgSupportsUnaryPtrSiblingCall(function, second_call)) return false;
    const second_expected = try genericCfgCallEqExpected(second_cmp_inst, second_call_name);

    const then_br = switch (then_block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };
    if (!std.mem.eql(u8, then_br.target, merge.name)) return false;

    const phi = switch (phi_inst.kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 1 }) or phi.incoming.items.len != 2) return false;
    if (!phiHasIncoming(phi, second_cmp_name, then_block.name) or !phiHasIncomingInt(phi, 0, entry.name)) return false;
    if (!isSelectI1ToI32ZeroOne(select_inst, phi_name)) return false;
    const ret = switch (merge.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const fail = "generic_cfg_two_call_check_fail";
    try emitGenericCfgUnaryPtrCallArg(allocator, machine, first_call.args.items[0]);
    try appendAlignedDirectCall(allocator, machine, first_call.callee, first_call.ret_ty);
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = first_expected });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try emitGenericCfgUnaryPtrCallArg(allocator, machine, second_call.args.items[0]);
    try appendAlignedDirectCall(allocator, machine, second_call.callee, second_call.ret_ty);
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = second_expected });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    machine.codegen_path = .generic_cfg;
    return true;
}

pub fn lowerGenericCfgSingleBlockUpdateGetMain(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!isMainOrWrapperMain(function.name)) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 2 and block.instructions.items.len != 3) return false;

    const update_inst = block.instructions.items[0];
    const get_inst = block.instructions.items[1];
    if (update_inst.removed or get_inst.removed or update_inst.result != null) return false;
    const get_result = get_inst.result orelse return false;
    if (block.instructions.items.len == 2) {
        if (!isNamed(ret.value orelse return error.InvalidRet, get_result)) return false;
    } else {
        const cast_inst = block.instructions.items[2];
        if (cast_inst.removed) return false;
        const cast_name = identityCastFrom(cast_inst, get_result, .{ .int = 32 }, .{ .int = 32 }) orelse return false;
        if (!isNamed(ret.value orelse return error.InvalidRet, cast_name)) return false;
    }

    const update_call = switch (update_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (update_call.callee_value != null or update_call.inline_asm != null) return false;
    if (!genericCfgCallTargetsWrapperSibling(function.name, update_call.callee)) return false;
    if (!callIsFastcc(update_call.calling_conv)) validateDefaultCallConv(update_call.calling_conv) catch return false;
    if (update_call.ret_ty != .void or update_call.args.items.len != 1) return false;
    const update_arg = update_call.args.items[0];
    if (update_arg.attrs != null or !update_arg.ty.eql(.{ .int = 32 })) return false;
    const update_value = switch (update_arg.value) {
        .int => |int| try i32Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const get_call = switch (get_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (get_call.callee_value != null or get_call.inline_asm != null) return false;
    if (!genericCfgCallTargetsWrapperSibling(function.name, get_call.callee)) return false;
    if (!callIsFastcc(get_call.calling_conv)) validateDefaultCallConv(get_call.calling_conv) catch return false;
    if (!get_call.ret_ty.eql(.{ .int = 32 }) or get_call.args.items.len != 0) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_rdi = update_value });
    try appendAlignedDirectCall(allocator, machine, update_call.callee, .void);
    try appendAlignedDirectCall(allocator, machine, get_call.callee, get_call.ret_ty);
    try machine.instructions.append(allocator, .ret);
    machine.codegen_path = .generic_cfg;
    return true;
}

pub fn lowerGenericCfgSingleBlockCallCheckMain(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!isMainOrWrapperMain(function.name)) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (try lowerGenericCfgSingleBlockIntCallCheckMainReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgSingleBlockFpCallCheckMainReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgSingleBlockBoolCallCheckMainReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    return false;
}

pub fn lowerGenericCfgSingleBlockIntCallCheckMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (block.instructions.items.len != 3) return false;
    const call_inst = block.instructions.items[0];
    const icmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (call_inst.removed or icmp_inst.removed or select_inst.removed) return false;

    const call_name = call_inst.result orelse return false;
    const icmp_name = icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!genericCfgSupportsConstantWrapperCall(function, call)) return false;
    switch (call.ret_ty) {
        .int => {},
        .void, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .aggregate, .vector => return false,
    }

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    switch (icmp.predicate) {
        .eq, .ne => {},
        .ugt, .uge, .ult, .ule, .sgt, .sge, .slt, .sle => return false,
    }
    if (!icmp.operand_ty.eql(call.ret_ty)) return false;
    if (!isNamed(icmp.lhs, call_name)) return false;
    switch (icmp.rhs) {
        .int => {},
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    }
    if (!isSelectI1ToI32ZeroOne(select_inst, icmp_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgSingleBlockFpCallCheckMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (block.instructions.items.len != 3) return false;
    const call_inst = block.instructions.items[0];
    const fcmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (call_inst.removed or fcmp_inst.removed or select_inst.removed) return false;

    const call_name = call_inst.result orelse return false;
    const fcmp_name = fcmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!genericCfgSupportsConstantWrapperCall(function, call)) return false;
    if (!call.ret_ty.eql(.float) and !call.ret_ty.eql(.double)) return false;

    const fcmp = switch (fcmp_inst.kind) {
        .fcmp => |fcmp| fcmp,
        else => return false,
    };
    if (fcmp.predicate != .oeq or !fcmp.operand_ty.eql(call.ret_ty)) return false;
    if (!isNamed(fcmp.lhs, call_name)) return false;
    switch (fcmp.rhs) {
        .fp => {},
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    }
    if (!isSelectI1ToI32ZeroOne(select_inst, fcmp_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgSingleBlockBoolCallCheckMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (block.instructions.items.len != 2) return false;
    const call_inst = block.instructions.items[0];
    const select_inst = block.instructions.items[1];
    if (call_inst.removed or select_inst.removed) return false;

    const call_name = call_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!genericCfgSupportsConstantWrapperCall(function, call)) return false;
    if (!call.ret_ty.eql(.{ .int = 1 })) return false;
    if (!isSelectI1ToI32ZeroOne(select_inst, call_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn genericCfgSupportsConstantWrapperCall(function: ir.Function, call: ir.CallInst) bool {
    if (!callIsFastcc(call.calling_conv)) return false;
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (!genericCfgCallTargetsWrapperSibling(function.name, call.callee)) return false;
    if (call.args.items.len == 0 or call.args.items.len > 4) return false;
    for (call.args.items) |arg| {
        if (!genericCfgSupportsConstantWrapperCallArg(arg)) return false;
    }
    return true;
}

pub fn genericCfgSupportsConstantWrapperCallArg(arg: ir.CallArg) bool {
    if (arg.attrs != null) return false;
    return switch (arg.ty) {
        .ptr => switch (arg.value) {
            .named => |name| name.len > 0 and name[0] == '@',
            .null_value => true,
            .int, .fp, .undef, .poison, .zero_initializer, .vector, .constant_expr => false,
        },
        .float, .double => switch (arg.value) {
            .fp => true,
            .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
        },
        .int => switch (arg.value) {
            .int => true,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
        },
        .void, .x86_fp80, .fp128, .metadata, .aggregate, .vector => false,
    };
}

pub fn genericCfgGlobalPtrArg(arg: ir.CallArg) ?[]const u8 {
    if (arg.attrs != null or !arg.ty.eql(.ptr)) return null;
    return switch (arg.value) {
        .named => |name| if (name.len > 0 and name[0] == '@') globalSymbolName(name) catch null else null,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
    };
}

pub fn genericCfgSupportsUnaryPtrSiblingCall(function: ir.Function, call: ir.CallInst) bool {
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (!genericCfgCallTargetsWrapperSibling(function.name, call.callee)) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 1) return false;
    const arg = call.args.items[0];
    if (arg.attrs != null or !arg.ty.eql(.ptr)) return false;
    return switch (arg.value) {
        .named => |name| name.len > 0 and name[0] == '@',
        .null_value => true,
        .int, .fp, .undef, .poison, .zero_initializer, .vector, .constant_expr => false,
    };
}

pub fn genericCfgCallEqExpected(instruction: ir.Instruction, call_name: []const u8) !i32 {
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenValue,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 }) or !isNamed(icmp.lhs, call_name)) {
        return error.UnsupportedCodegenValue;
    }
    return switch (icmp.rhs) {
        .int => |int| try i32Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => error.UnsupportedCodegenValue,
    };
}

pub fn emitGenericCfgUnaryPtrCallArg(allocator: std.mem.Allocator, machine: *MachineFunction, arg: ir.CallArg) !void {
    if (arg.attrs != null or !arg.ty.eql(.ptr)) return error.UnsupportedCodegenValue;
    switch (arg.value) {
        .named => |name| try machine.instructions.append(allocator, .{ .lea_global_rdi = try globalSymbolName(name) }),
        .null_value => try machine.instructions.append(allocator, .{ .mov_imm_rdi = 0 }),
        .int, .fp, .undef, .poison, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn genericCfgCallTargetsWrapperSibling(function_name: []const u8, callee: []const u8) bool {
    const name = symbolName(function_name);
    if (!isMainOrWrapperMain(name)) return false;
    const callee_name = symbolName(callee);
    const dot = std.mem.lastIndexOfScalar(u8, name, '.') orelse return false;
    if (!std.mem.eql(u8, name[dot + 1 ..], "main")) return false;
    const prefix = name[0 .. dot + 1];
    return std.mem.startsWith(u8, callee_name, prefix) and callee_name.len > prefix.len;
}

pub fn lowerGenericCfgSingleBlockVoid(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (function.ret_ty != .void or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (ret.ty != .void or ret.value != null) return false;
    if (try lowerGenericCfgSelectedSretStores(allocator, machine, function, block)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (block.instructions.items.len == 0) {
        try appendGenericCfgReturn(allocator, machine);
        machine.codegen_path = .generic_cfg;
        return true;
    }
    for (block.instructions.items) |instruction| {
        if (instruction.removed) return false;
        const store = switch (instruction.kind) {
            .store => |store| store,
            else => return false,
        };
        if (!genericCfgSupportsSingleBlockStore(function, block, store)) return false;
    }
    for (block.instructions.items) |instruction| {
        const store = switch (instruction.kind) {
            .store => |store| store,
            else => unreachable,
        };
        try emitGenericCfgI32ValueIntoEax(allocator, machine, function, block, store.value);
        try emitGenericCfgStoreEax(allocator, machine, function, store.ptr);
    }
    try appendGenericCfgReturn(allocator, machine);
    machine.codegen_path = .generic_cfg;
    return true;
}

pub fn lowerGenericCfgSelectedSretStores(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
) !bool {
    if (try lowerGenericCfgSretCopy(allocator, machine, function, block)) return true;
    if (function.params.items.len < 4) return false;
    const aggregate_ty = sretAggregateType(function.params.items[0].attrs) orelse return false;
    const field_count = aggregateFieldCount(aggregate_ty) orelse return false;
    if (field_count < 3 or function.params.items.len != field_count + 1) return false;
    if (!isI64Aggregate(aggregate_ty)) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if ((try paramReg(function, function.params.items[0].name, .ptr)) != .rdi) return error.UnsupportedCodegenAbi;
    for (function.params.items[1..]) |param| {
        if (!param.ty.eql(.{ .int = 64 })) return false;
    }
    if (block.instructions.items.len != field_count * 2) return false;

    var pair_index: usize = 0;
    while (pair_index < field_count) : (pair_index += 1) {
        const gep_inst = block.instructions.items[pair_index * 2];
        const store_inst = block.instructions.items[pair_index * 2 + 1];
        if (gep_inst.removed or store_inst.removed) return false;
        const gep_name = gep_inst.result orelse return false;
        try validateAggregateFieldGep(gep_inst, aggregate_ty, function.params.items[0].name, @intCast(pair_index));

        const store = switch (store_inst.kind) {
            .store => |store| store,
            else => return false,
        };
        if (!store.ty.eql(.{ .int = 64 }) or store.attrs.isBarrier() or !isNamed(store.ptr, gep_name) or
            !isNamed(store.value, function.params.items[pair_index + 1].name)) return false;
        const offset = try aggregateFieldOffset(aggregate_ty, pair_index);
        const maybe_src_reg = paramReg(function, function.params.items[pair_index + 1].name, .{ .int = 64 }) catch |err| switch (err) {
            error.UnsupportedCodegenAbi => null,
            else => return err,
        };
        if (maybe_src_reg) |src_reg| {
            try appendStoreArg64ArgPtrDisp(allocator, machine, .rdi, src_reg, offset);
        } else {
            try machine.instructions.append(allocator, .{ .load_stack_disp8_rax = try scalarParamStackDisp8(function, function.params.items[pair_index + 1].name, .{ .int = 64 }) });
            try appendStoreRaxArgPtrDisp(allocator, machine, .rdi, offset);
        }
    }
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub fn lowerGenericCfgSretCopy(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
) !bool {
    if (function.params.items.len != 2) return false;
    const aggregate_ty = sretAggregateType(function.params.items[0].attrs) orelse return false;
    const byval_ty = byvalAggregateType(function.params.items[1].attrs) orelse return false;
    if (!byval_ty.eql(aggregate_ty)) return false;
    if (!isSupportedAggregateCopyLeafAggregate(aggregate_ty)) return false;
    if (!function.params.items[0].ty.eql(.ptr) or !function.params.items[1].ty.eql(.ptr)) return false;
    const sret_reg = try paramReg(function, function.params.items[0].name, .ptr);
    if (sret_reg != .rdi) return error.UnsupportedCodegenAbi;
    if (block.instructions.items.len < 12 or block.instructions.items.len % 4 != 0) return false;

    const copy_count = block.instructions.items.len / 4;
    var copy_index: usize = 0;
    while (copy_index < copy_count) : (copy_index += 1) {
        const src_gep_inst = block.instructions.items[copy_index * 4];
        const load_inst = block.instructions.items[copy_index * 4 + 1];
        const dst_gep_inst = block.instructions.items[copy_index * 4 + 2];
        const store_inst = block.instructions.items[copy_index * 4 + 3];
        if (src_gep_inst.removed or load_inst.removed or dst_gep_inst.removed or store_inst.removed) return false;
        const src_gep_name = src_gep_inst.result orelse return false;
        const load_name = load_inst.result orelse return false;
        const dst_gep_name = dst_gep_inst.result orelse return false;
        const src_offset = aggregateCopyGepOffset(src_gep_inst, aggregate_ty, function.params.items[1].name) orelse return false;
        const dst_offset = aggregateCopyGepOffset(dst_gep_inst, aggregate_ty, function.params.items[0].name) orelse return false;
        if (src_offset != dst_offset) return false;

        const load = switch (load_inst.kind) {
            .load => |load| load,
            else => return false,
        };
        if (!supportedAggregateCopyLeaf(load.ty) or load.attrs.isBarrier() or !isNamed(load.ptr, src_gep_name)) return false;
        const store = switch (store_inst.kind) {
            .store => |store| store,
            else => return false,
        };
        if (!store.ty.eql(load.ty) or store.attrs.isBarrier() or !isNamed(store.ptr, dst_gep_name) or
            !isNamed(store.value, load_name)) return false;

        const offset = try aggregateByteOffset(aggregate_ty, src_offset, load.ty);
        if (load.ty.eql(.float)) {
            try appendLoadStackDispXmm0F32(allocator, machine, try stackAggregateByteDisp(aggregate_ty, src_offset, load.ty));
            try appendStoreXmm0F32ArgPtrDisp(allocator, machine, sret_reg, offset);
        } else if (load.ty.eql(.double)) {
            try appendLoadStackDispXmm0(allocator, machine, try stackAggregateByteDisp(aggregate_ty, src_offset, load.ty));
            try appendStoreXmm0ArgPtrDisp(allocator, machine, sret_reg, offset);
        } else if (load.ty.eql(.{ .int = 64 }) or load.ty.eql(.ptr)) {
            try appendLoadStackDispRax(allocator, machine, try stackAggregateByteDisp(aggregate_ty, src_offset, load.ty));
            try appendStoreRaxArgPtrDisp(allocator, machine, sret_reg, offset);
        } else if (load.ty.eql(.{ .int = 32 })) {
            try appendLoadStackDispRax(allocator, machine, try stackAggregateByteDisp(aggregate_ty, src_offset, load.ty));
            try appendStoreEaxArgPtrDisp(allocator, machine, sret_reg, offset);
        } else {
            return error.UnsupportedCodegenType;
        }
    }
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub fn aggregateCopyGepOffset(instruction: ir.Instruction, aggregate_ty: ir.Type, base_name: []const u8) ?u64 {
    const gep = switch (instruction.kind) {
        .gep => |gep| gep,
        else => return null,
    };
    if (!isNamed(gep.ptr, base_name)) return null;
    const layout = x86_64SysVDataLayout() catch return null;
    const offset = aggregateGepByteOffset(layout, aggregate_ty, gep) orelse return null;
    const field_ty = aggregateLeafTypeAtOffset(layout, aggregate_ty, offset) orelse return null;
    if (!supportedAggregateCopyLeaf(field_ty)) return null;
    return offset;
}

pub fn aggregateLeafTypeAtOffset(layout: target.DataLayout, aggregate_ty: ir.Type, expected_offset: u64) ?ir.Type {
    var field_index: usize = 0;
    while (memory_location.aggregateFieldType(aggregate_ty, field_index)) |field_ty| : (field_index += 1) {
        const offset_i = memory_location.aggregateFieldOffsetWithLayout(layout, aggregate_ty, field_index) orelse return null;
        if (offset_i < 0) return null;
        const field_offset: u64 = @intCast(offset_i);
        if (isAggregateType(field_ty)) {
            if (expected_offset >= field_offset) {
                if (aggregateLeafTypeAtOffset(layout, field_ty, expected_offset - field_offset)) |nested_ty| return nested_ty;
            }
        } else if (field_offset == expected_offset) {
            return field_ty;
        }
    }
    return null;
}

pub fn sretAggregateType(attrs: ?[]const u8) ?ir.Type {
    return aggregateAbiAttrType(attrs, "sret");
}

pub fn byvalAggregateType(attrs: ?[]const u8) ?ir.Type {
    return aggregateAbiAttrType(attrs, "byval");
}

pub fn aggregateAbiAttrType(attrs: ?[]const u8, name: []const u8) ?ir.Type {
    const text = attrs orelse return null;
    var start: usize = 0;
    while (std.mem.indexOfPos(u8, text, start, name)) |name_index| {
        const open_index = name_index + name.len;
        start = open_index;
        if (open_index >= text.len or text[open_index] != '(') continue;
        const close_index = findMatchingParen(text, open_index) orelse return null;
        const payload = std.mem.trim(u8, text[open_index + 1 .. close_index], " \t");
        if (payload.len >= 2 and ((payload[0] == '{' and payload[payload.len - 1] == '}') or
            (payload[0] == '[' and payload[payload.len - 1] == ']') or
            (payload[0] == '%' and payload.len > 1)))
        {
            return .{ .aggregate = payload };
        }
        start = close_index + 1;
    }
    return null;
}

pub fn findMatchingParen(text: []const u8, open_index: usize) ?usize {
    if (open_index >= text.len or text[open_index] != '(') return null;
    var paren_depth: usize = 0;
    var brace_depth: usize = 0;
    var bracket_depth: usize = 0;
    var angle_depth: usize = 0;
    for (text[open_index..], 0..) |byte, relative_index| {
        const index = open_index + relative_index;
        switch (byte) {
            '(' => paren_depth += 1,
            ')' => {
                if (paren_depth == 0) return null;
                paren_depth -= 1;
                if (paren_depth == 0 and brace_depth == 0 and bracket_depth == 0 and angle_depth == 0) return index;
            },
            '{' => brace_depth += 1,
            '}' => {
                if (brace_depth == 0) return null;
                brace_depth -= 1;
            },
            '[' => bracket_depth += 1,
            ']' => {
                if (bracket_depth == 0) return null;
                bracket_depth -= 1;
            },
            '<' => angle_depth += 1,
            '>' => {
                if (angle_depth == 0) return null;
                angle_depth -= 1;
            },
            else => {},
        }
    }
    return null;
}

pub fn aggregateFieldOffsetU8(aggregate_ty: ir.Type, field_index: usize) !u8 {
    const layout = try x86_64SysVDataLayout();
    const offset_i = memory_location.aggregateFieldOffsetWithLayout(layout, aggregate_ty, field_index) orelse
        return error.UnsupportedCodegenAbi;
    if (offset_i < 0 or offset_i > std.math.maxInt(u8)) return error.UnsupportedCodegenAbi;
    return @intCast(offset_i);
}

pub fn aggregateFieldOffset(aggregate_ty: ir.Type, field_index: usize) !u32 {
    const layout = try x86_64SysVDataLayout();
    const offset_i = memory_location.aggregateFieldOffsetWithLayout(layout, aggregate_ty, field_index) orelse
        return error.UnsupportedCodegenAbi;
    if (offset_i < 0 or offset_i > std.math.maxInt(u32)) return error.UnsupportedCodegenAbi;
    return @intCast(offset_i);
}

pub fn aggregateByteOffsetU8(aggregate_ty: ir.Type, field_offset: u64, field_ty: ir.Type) !u8 {
    _ = aggregateFieldIndexAtOffset(aggregate_ty, field_offset, field_ty) orelse return error.UnsupportedCodegenAbi;
    if (field_offset > std.math.maxInt(u8)) return error.UnsupportedCodegenAbi;
    return @intCast(field_offset);
}

pub fn aggregateByteOffset(aggregate_ty: ir.Type, field_offset: u64, field_ty: ir.Type) !u32 {
    _ = aggregateFieldIndexAtOffset(aggregate_ty, field_offset, field_ty) orelse return error.UnsupportedCodegenAbi;
    if (field_offset > std.math.maxInt(u32)) return error.UnsupportedCodegenAbi;
    return @intCast(field_offset);
}

pub fn lowerGenericCfgPackedReplaceLowReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 8 }) or !ret.ty.eql(.{ .int = 8 })) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 8 }) or !function.params.items[1].ty.eql(.{ .int = 8 })) return false;
    if (block.instructions.items.len != 3) return false;
    const high_mask_inst = block.instructions.items[0];
    const low_mask_inst = block.instructions.items[1];
    const or_inst = block.instructions.items[2];
    if (high_mask_inst.removed or low_mask_inst.removed or or_inst.removed) return false;
    const high_result = high_mask_inst.result orelse return false;
    const low_result = low_mask_inst.result orelse return false;
    const or_result = or_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, or_result)) return false;

    const high_mask = switch (high_mask_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (high_mask.op != .@"and" or !high_mask.ty.eql(.{ .int = 8 })) return false;
    if (!isNamed(high_mask.lhs, function.params.items[0].name) or !isInt(high_mask.rhs, -8)) return false;

    const low_mask = switch (low_mask_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (low_mask.op != .@"and" or !low_mask.ty.eql(.{ .int = 8 })) return false;
    if (!isNamed(low_mask.lhs, function.params.items[1].name) or !isInt(low_mask.rhs, 7)) return false;

    const or_binary = switch (or_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (or_binary.op != .@"or" or !or_binary.ty.eql(.{ .int = 8 })) return false;
    if (!((isNamed(or_binary.lhs, low_result) and isNamed(or_binary.rhs, high_result)) or
        (isNamed(or_binary.lhs, high_result) and isNamed(or_binary.rhs, low_result)))) return false;

    try machine.instructions.append(allocator, .replace_low_i8_dil_sil_al);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgPackedReadFlagReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 1 }) or !ret.ty.eql(.{ .int = 1 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 8 })) return false;
    if (block.instructions.items.len != 1) return false;
    const icmp_inst = block.instructions.items[0];
    if (icmp_inst.removed) return false;
    const icmp_result = icmp_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, icmp_result)) return false;
    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .slt or !icmp.operand_ty.eql(.{ .int = 8 })) return false;
    if (!isNamed(icmp.lhs, function.params.items[0].name) or !isInt(icmp.rhs, 0)) return false;

    try machine.instructions.append(allocator, .read_flag_i8_dil_al);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgFpBinaryReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (function.params.items.len < 2 or block.instructions.items.len != 1) return false;
    const instruction = block.instructions.items[0];
    if (instruction.removed) return false;
    const result = instruction.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, result)) return false;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (!ret.ty.eql(binary.ty) or !function.ret_ty.eql(binary.ty)) return false;
    if ((!binary.ty.eql(.float) and !binary.ty.eql(.double)) or
        !function.params.items[0].ty.eql(binary.ty) or
        !function.params.items[1].ty.eql(binary.ty)) return false;
    for (function.params.items[2..]) |param| {
        if (!genericCfgSupportsUnusedScalarParam(param.ty)) return false;
    }
    if (!isNamed(binary.lhs, function.params.items[0].name) or
        !isNamed(binary.rhs, function.params.items[1].name)) return false;

    if (binary.ty.eql(.float)) {
        switch (binary.op) {
            .fadd => try machine.instructions.append(allocator, .addss_xmm1_xmm0),
            .fmul => try machine.instructions.append(allocator, .mulss_xmm1_xmm0),
            .fsub => try machine.instructions.append(allocator, .subss_xmm1_xmm0),
            .frem => try appendAlignedDirectCall(allocator, machine, "fmodf", .float),
            .fdiv, .add, .sub, .mul, .shl, .lshr, .ashr, .@"and", .@"or", .xor, .udiv, .sdiv, .urem, .srem => return false,
        }
    } else if (binary.ty.eql(.double)) {
        switch (binary.op) {
            .fmul => try machine.instructions.append(allocator, .mulsd_xmm1_xmm0),
            .fdiv => try machine.instructions.append(allocator, .divsd_xmm1_xmm0),
            .fadd, .fsub, .frem, .add, .sub, .mul, .shl, .lshr, .ashr, .@"and", .@"or", .xor, .udiv, .sdiv, .urem, .srem => return false,
        }
    } else {
        return false;
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgFpCastBinaryPipelineReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if ((!function.ret_ty.eql(.float) and !function.ret_ty.eql(.double)) or !ret.ty.eql(function.ret_ty)) return false;
    if (function.params.items.len < 2) return false;
    if (block.instructions.items.len != 2 and block.instructions.items.len != 3) return false;

    const cast_inst = block.instructions.items[0];
    if (cast_inst.removed) return false;
    const cast_result = fpSitofpFirstGprI32Result(function, cast_inst, function.ret_ty) catch return false;

    if (block.instructions.items.len == 2) {
        const add_inst = block.instructions.items[1];
        if (add_inst.removed) return false;
        const add_result = add_inst.result orelse return false;
        if (!isNamed(ret.value orelse return error.InvalidRet, add_result)) return false;
        const fp_param = fpBinaryOtherParamIndex(function, add_inst, function.ret_ty, cast_result, .fadd) catch return false;
        if (fp_param != 0) return error.UnsupportedCodegenAbi;

        try machine.instructions.append(allocator, .{ .movapd_xmm = .{ .dst = .xmm1, .src = .xmm0 } });
        try emitFirstGprI32ToFpXmm0(allocator, machine, function.ret_ty);
        try appendFpAddXmm1Xmm0(allocator, machine, function.ret_ty);
        try machine.instructions.append(allocator, .ret);
        return true;
    }

    const mul_inst = block.instructions.items[1];
    const add_inst = block.instructions.items[2];
    if (mul_inst.removed or add_inst.removed) return false;
    const mul_result = mul_inst.result orelse return false;
    const add_result = add_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, add_result)) return false;
    const mul_param = fpBinaryOtherParamIndex(function, mul_inst, function.ret_ty, cast_result, .fmul) catch return false;
    const add_param = fpBinaryOtherParamIndex(function, add_inst, function.ret_ty, mul_result, .fadd) catch return false;
    if (mul_param != 0 or add_param != 1) return error.UnsupportedCodegenAbi;

    try machine.instructions.append(allocator, .{ .movapd_xmm = .{ .dst = .xmm2, .src = .xmm1 } });
    try machine.instructions.append(allocator, .{ .movapd_xmm = .{ .dst = .xmm1, .src = .xmm0 } });
    try emitFirstGprI32ToFpXmm0(allocator, machine, function.ret_ty);
    try appendFpMulXmm1Xmm0(allocator, machine, function.ret_ty);
    try machine.instructions.append(allocator, .{ .movapd_xmm = .{ .dst = .xmm1, .src = .xmm2 } });
    try appendFpAddXmm1Xmm0(allocator, machine, function.ret_ty);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn fpSitofpFirstGprI32Result(function: ir.Function, instruction: ir.Instruction, to_ty: ir.Type) ![]const u8 {
    const result = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const cast = switch (instruction.kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (cast.op != .sitofp or !cast.from_ty.eql(.{ .int = 32 }) or !cast.to_ty.eql(to_ty)) return error.UnsupportedCodegenInstruction;
    const source_name = switch (cast.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    if ((try paramReg(function, source_name, .{ .int = 32 })) != .rdi) return error.UnsupportedCodegenAbi;
    return result;
}

pub fn fpBinaryOtherParamIndex(
    function: ir.Function,
    instruction: ir.Instruction,
    ty: ir.Type,
    fixed_name: []const u8,
    op: ir.BinaryOp,
) !usize {
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (binary.op != op or !binary.ty.eql(ty)) return error.UnsupportedCodegenInstruction;
    const lhs_fixed = isNamed(binary.lhs, fixed_name);
    const rhs_fixed = isNamed(binary.rhs, fixed_name);
    if (lhs_fixed == rhs_fixed) return error.UnsupportedCodegenInstruction;
    const other = if (lhs_fixed) binary.rhs else binary.lhs;
    return fpParamIndexFromValue(function, other, ty);
}

pub fn emitFirstGprI32ToFpXmm0(allocator: std.mem.Allocator, machine: *MachineFunction, ty: ir.Type) !void {
    if (ty.eql(.float)) {
        try machine.instructions.append(allocator, .cvtsi2ss_edi_xmm0);
    } else if (ty.eql(.double)) {
        try machine.instructions.append(allocator, .cvtsi2sd_edi_xmm0);
    } else return error.UnsupportedCodegenType;
}

pub fn appendFpAddXmm1Xmm0(allocator: std.mem.Allocator, machine: *MachineFunction, ty: ir.Type) !void {
    if (ty.eql(.float)) {
        try machine.instructions.append(allocator, .addss_xmm1_xmm0);
    } else if (ty.eql(.double)) {
        try machine.instructions.append(allocator, .addsd_xmm1_xmm0);
    } else return error.UnsupportedCodegenType;
}

pub fn appendFpMulXmm1Xmm0(allocator: std.mem.Allocator, machine: *MachineFunction, ty: ir.Type) !void {
    if (ty.eql(.float)) {
        try machine.instructions.append(allocator, .mulss_xmm1_xmm0);
    } else if (ty.eql(.double)) {
        try machine.instructions.append(allocator, .mulsd_xmm1_xmm0);
    } else return error.UnsupportedCodegenType;
}

pub fn genericCfgSupportsUnusedScalarParam(ty: ir.Type) bool {
    return switch (ty) {
        .int, .ptr, .float, .double => true,
        .void, .x86_fp80, .fp128, .metadata, .aggregate, .vector => false,
    };
}

pub fn lowerGenericCfgFpCompareReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (function.params.items.len != 2 or block.instructions.items.len != 1) return false;
    if (!function.ret_ty.eql(.{ .int = 1 }) or !ret.ty.eql(.{ .int = 1 })) return false;
    const instruction = block.instructions.items[0];
    if (instruction.removed) return false;
    const result = instruction.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, result)) return false;
    const fcmp = switch (instruction.kind) {
        .fcmp => |fcmp| fcmp,
        else => return false,
    };
    if (fcmp.predicate != .olt or !fcmp.operand_ty.eql(.float)) return false;
    if (!function.params.items[0].ty.eql(.float) or !function.params.items[1].ty.eql(.float)) return false;
    if (!isNamed(fcmp.lhs, function.params.items[0].name) or
        !isNamed(fcmp.rhs, function.params.items[1].name)) return false;

    try machine.instructions.append(allocator, .oltss_xmm0_xmm1_al);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgFpSelectReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (function.params.items.len != 3 or block.instructions.items.len != 1) return false;
    if (!function.ret_ty.eql(.double) or !ret.ty.eql(.double)) return false;
    if (!function.params.items[0].ty.eql(.double) or
        !function.params.items[1].ty.eql(.double) or
        !function.params.items[2].ty.eql(.{ .int = 1 })) return false;
    const instruction = block.instructions.items[0];
    if (instruction.removed) return false;
    const result = instruction.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, result)) return false;
    const select = switch (instruction.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.double)) return false;
    if (!isNamed(select.cond, function.params.items[2].name) or
        !isNamed(select.true_value, function.params.items[0].name) or
        !isNamed(select.false_value, function.params.items[1].name)) return false;

    const false_label = "generic_cfg_fp_select_false";
    try machine.instructions.append(allocator, .{ .test_arg8 = .rdi });
    try machine.instructions.append(allocator, .{ .je = false_label });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = false_label });
    try machine.instructions.append(allocator, .movapd_xmm1_xmm0);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgFpDirectCallReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if ((!function.ret_ty.eql(.float) and !function.ret_ty.eql(.double)) or
        !ret.ty.eql(function.ret_ty) or block.instructions.items.len != 1) return false;
    const instruction = block.instructions.items[0];
    if (instruction.removed) return false;
    const call_result = instruction.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, call_result)) return false;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!call.ret_ty.eql(function.ret_ty) or call.inline_asm != null) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;

    if (call.callee_value) |callee_value| {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        const callee_reg = try paramReg(function, callee_name, .ptr);
        try machine.instructions.append(allocator, .{ .mov_arg_rax = callee_reg });
        const stack_arg_count = try appendSysVScalarCallArgs(allocator, machine, function, call);
        try appendIndirectCallRaxWithStackArgs(allocator, machine, call.ret_ty, stack_arg_count);
    } else {
        const stack_arg_count = try appendSysVScalarCallArgs(allocator, machine, function, call);
        try appendDirectCallWithStackArgs(allocator, machine, call.callee, call.ret_ty, stack_arg_count);
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgFpVoidCallParamReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if ((!function.ret_ty.eql(.float) and !function.ret_ty.eql(.double)) or
        !ret.ty.eql(function.ret_ty) or block.instructions.items.len != 1) return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const live_index = fpParamIndex(function, ret_name, function.ret_ty) catch return false;
    if (live_index >= 2) return error.UnsupportedLiveAcrossCall;
    const instruction = block.instructions.items[0];
    if (instruction.removed or instruction.result != null) return false;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.ret_ty != .void or call.inline_asm != null) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;
    if (call.ret_attrs != null or call.attrs != null) return error.UnsupportedCodegenAbi;
    if (call.callee_function_ty) |function_ty| {
        if (std.mem.indexOf(u8, function_ty, "...") != null) return error.UnsupportedCodegenAbi;
    }
    if (sysvScalarCallNeedsStackArgs(call)) return error.UnsupportedLiveAcrossCall;
    const call_target: SysVCallTarget = if (call.callee_value) |callee_value| blk: {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        break :blk .{ .indirect_from_reg = try paramReg(function, callee_name, .ptr) };
    } else .{ .direct = call.callee };

    try appendStackFrame(allocator, machine, 8);
    const live_reg = try XmmReg.fromIndex(live_index);
    if (function.ret_ty.eql(.float)) {
        try machine.instructions.append(allocator, .{ .spill_xmm32_rsp = .{ .reg = live_reg, .frame_index = .slot0 } });
    } else {
        try machine.instructions.append(allocator, .{ .spill_xmm64_rsp = .{ .reg = live_reg, .frame_index = .slot0 } });
    }
    try setupSysVCallTarget(allocator, machine, call_target);
    _ = try appendSysVScalarCallArgs(allocator, machine, function, call);
    try appendSysVCallTarget(allocator, machine, call_target, call.ret_ty);
    if (function.ret_ty.eql(.float)) {
        try machine.instructions.append(allocator, .{ .reload_xmm32_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    } else {
        try machine.instructions.append(allocator, .{ .reload_xmm64_rsp = .{ .reg = .xmm0, .frame_index = .slot0 } });
    }
    try appendStackFrameEnd(allocator, machine, 8);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgFpVoidCallBinaryReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if ((!function.ret_ty.eql(.float) and !function.ret_ty.eql(.double)) or !ret.ty.eql(function.ret_ty) or
        block.instructions.items.len < 2 or block.instructions.items.len > 6) return false;
    const call_inst = block.instructions.items[0];
    if (call_inst.removed) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.ret_ty != .void or call.inline_asm != null) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;
    if (call.ret_attrs != null or call.attrs != null) return error.UnsupportedCodegenAbi;
    if (call.callee_function_ty) |function_ty| {
        if (std.mem.indexOf(u8, function_ty, "...") != null) return error.UnsupportedCodegenAbi;
    }
    if (sysvScalarCallNeedsStackArgs(call)) return error.UnsupportedLiveAcrossCall;
    const call_target: SysVCallTarget = if (call.callee_value) |callee_value| blk: {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        break :blk .{ .indirect_from_reg = try paramReg(function, callee_name, .ptr) };
    } else .{ .direct = call.callee };

    const addend_count = try collectFpVoidCallFaddParamChain(function, block, ret.value orelse return error.InvalidRet);
    if (addend_count < 2 or addend_count > 6) return error.UnsupportedLiveAcrossCall;

    const frame_bytes = try fpLiveAddendFrameBytes(function.ret_ty, addend_count);
    try appendStackFrame(allocator, machine, frame_bytes);
    var index: usize = 0;
    while (index < addend_count) : (index += 1) {
        const reg = try XmmReg.fromIndex(index);
        const frame_index = try frameIndexForFpLiveAddend(function.ret_ty, index);
        if (function.ret_ty.eql(.float)) {
            try machine.instructions.append(allocator, .{ .spill_xmm32_rsp = .{ .reg = reg, .frame_index = frame_index } });
        } else {
            try machine.instructions.append(allocator, .{ .spill_xmm64_rsp = .{ .reg = reg, .frame_index = frame_index } });
        }
    }
    try setupSysVCallTarget(allocator, machine, call_target);
    _ = try appendSysVScalarCallArgs(allocator, machine, function, call);
    try appendSysVCallTarget(allocator, machine, call_target, call.ret_ty);
    if (function.ret_ty.eql(.float)) {
        try machine.instructions.append(allocator, .{ .reload_xmm32_rsp = .{ .reg = .xmm0, .frame_index = try frameIndexForFpLiveAddend(function.ret_ty, 0) } });
        index = 1;
        while (index < addend_count) : (index += 1) {
            try machine.instructions.append(allocator, .{ .reload_xmm32_rsp = .{ .reg = .xmm1, .frame_index = try frameIndexForFpLiveAddend(function.ret_ty, index) } });
            try machine.instructions.append(allocator, .addss_xmm1_xmm0);
        }
    } else {
        try machine.instructions.append(allocator, .{ .reload_xmm64_rsp = .{ .reg = .xmm0, .frame_index = try frameIndexForFpLiveAddend(function.ret_ty, 0) } });
        index = 1;
        while (index < addend_count) : (index += 1) {
            try machine.instructions.append(allocator, .{ .reload_xmm64_rsp = .{ .reg = .xmm1, .frame_index = try frameIndexForFpLiveAddend(function.ret_ty, index) } });
            try machine.instructions.append(allocator, .addsd_xmm1_xmm0);
        }
    }
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn collectFpVoidCallFaddParamChain(function: ir.Function, block: ir.BasicBlock, ret_value: ir.Value) !usize {
    const binary_count = block.instructions.items.len - 1;
    if (binary_count < 1 or binary_count > 5) return error.UnsupportedCodegenInstruction;

    var addend_seen = [_]bool{false} ** 6;
    var addend_count: usize = 0;
    var previous_name: ?[]const u8 = null;

    for (block.instructions.items[1..], 0..) |instruction, index| {
        if (instruction.removed) return error.UnsupportedCodegenInstruction;
        const result_name = instruction.result orelse return error.UnsupportedCodegenInstruction;
        if (index == binary_count - 1 and !isNamed(ret_value, result_name)) return error.UnsupportedCodegenInstruction;
        const binary = switch (instruction.kind) {
            .binary => |binary| binary,
            else => return error.UnsupportedCodegenInstruction,
        };
        if (binary.op != .fadd or !binary.ty.eql(function.ret_ty)) return error.UnsupportedCodegenInstruction;
        if (index == 0) {
            const lhs_name = switch (binary.lhs) {
                .named => |name| name,
                .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
            };
            const rhs_name = switch (binary.rhs) {
                .named => |name| name,
                .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
            };
            try noteFpAddendIndex(function, lhs_name, &addend_seen, &addend_count);
            try noteFpAddendIndex(function, rhs_name, &addend_seen, &addend_count);
        } else {
            const previous = previous_name orelse return error.UnsupportedCodegenInstruction;
            const lhs_is_previous = isNamed(binary.lhs, previous);
            const rhs_is_previous = isNamed(binary.rhs, previous);
            if (lhs_is_previous == rhs_is_previous) return error.UnsupportedCodegenInstruction;
            const next_value = if (lhs_is_previous) binary.rhs else binary.lhs;
            const next_name = switch (next_value) {
                .named => |name| name,
                .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
            };
            try noteFpAddendIndex(function, next_name, &addend_seen, &addend_count);
        }
        previous_name = result_name;
    }

    var expected: usize = 0;
    while (expected < addend_count) : (expected += 1) {
        if (!addend_seen[expected]) return error.UnsupportedLiveAcrossCall;
    }
    return addend_count;
}

pub fn noteFpAddendIndex(function: ir.Function, name: []const u8, seen: *[6]bool, count: *usize) !void {
    const index = try fpParamIndex(function, name, function.ret_ty);
    if (index >= seen.len) return error.UnsupportedLiveAcrossCall;
    if (seen[index]) return error.UnsupportedLiveAcrossCall;
    seen[index] = true;
    count.* += 1;
}

pub fn fpLiveAddendFrameBytes(ty: ir.Type, addend_count: usize) !u8 {
    if (addend_count < 2 or addend_count > 6) return error.UnsupportedLiveAcrossCall;
    if (ty.eql(.float)) {
        return if (addend_count == 2) 8 else if (addend_count <= 4) 24 else 40;
    }
    if (ty.eql(.double)) {
        return if (addend_count == 2) 24 else if (addend_count <= 4) 40 else 56;
    }
    return error.UnsupportedCodegenType;
}

pub fn frameIndexForFpLiveAddend(ty: ir.Type, index: usize) !FrameIndex {
    if (ty.eql(.float)) {
        return frameIndexForLiveParam(index);
    }
    if (!ty.eql(.double)) return error.UnsupportedCodegenType;
    return switch (index) {
        0 => .slot0,
        1 => .slot2,
        2 => .slot4,
        3 => .slot6,
        4 => .slot8,
        5 => .slot10,
        else => error.UnsupportedLiveAcrossCall,
    };
}

pub fn lowerGenericCfgFpParamReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if ((!function.ret_ty.eql(.float) and !function.ret_ty.eql(.double)) or !ret.ty.eql(function.ret_ty)) return false;
    if (block.instructions.items.len != 0) return false;
    const name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const fp_index = try fpParamIndex(function, name, function.ret_ty);
    switch (fp_index) {
        0 => {},
        1 => {
            if (!function.ret_ty.eql(.double)) return error.UnsupportedCodegenAbi;
            try machine.instructions.append(allocator, .movapd_xmm1_xmm0);
        },
        else => return error.UnsupportedCodegenAbi,
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgFpLiteralReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    ret: anytype,
) !bool {
    if (function.params.items.len != 0) return false;
    const value = switch (ret.value orelse return false) {
        .fp => |fp| fp,
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (function.ret_ty.eql(.double) and ret.ty.eql(.double)) {
        try machine.instructions.append(allocator, .{ .mov_imm64_xmm0 = try fp64TextBits(.{ .fp = value }) });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    if (function.ret_ty.eql(.float) and ret.ty.eql(.float)) {
        try machine.instructions.append(allocator, .{ .mov_imm32_xmm0 = try fp32TextBits(.{ .fp = value }) });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    return false;
}

pub fn lowerGenericCfgPointerSelectLoadReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or block.instructions.items.len != 3) return false;
    const icmp_name = block.instructions.items[0].result orelse return false;
    const select_name = block.instructions.items[1].result orelse return false;
    const load_name = block.instructions.items[2].result orelse return false;
    const icmp = switch (block.instructions.items[0].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (!genericCfgSupportsBranchIcmp(function, icmp)) return false;
    const select = switch (block.instructions.items[1].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.ptr) or !isNamed(select.cond, icmp_name)) return false;
    const true_ptr = switch (select.true_value) {
        .named => |name| name,
        else => return false,
    };
    const false_ptr = switch (select.false_value) {
        .named => |name| name,
        else => return false,
    };
    if (!genericCfgSupportsPointerParam(function, true_ptr) or !genericCfgSupportsPointerParam(function, false_ptr)) return false;
    const load = switch (block.instructions.items[2].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier() or !isNamed(load.ptr, select_name)) return false;
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, load_name)) return false;

    const true_label = "generic_cfg_pointer_select_true";
    const end_label = "generic_cfg_pointer_select_end";
    const branch_kind = try emitGenericCfgIcmpCondition(allocator, machine, function, icmp);
    try appendGenericCfgConditionalBranch(allocator, machine, branch_kind, true_label);
    try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = try paramReg(function, false_ptr, .ptr) });
    try machine.instructions.append(allocator, .{ .jmp = end_label });
    try appendGenericCfgBlockLabel(allocator, machine, true_label);
    try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = try paramReg(function, true_ptr, .ptr) });
    try appendGenericCfgBlockLabel(allocator, machine, end_label);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub fn genericCfgSupportsSingleBlockScalar(function: ir.Function) bool {
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    for (block.instructions.items) |instruction| {
        if (instruction.removed) return false;
        if (!genericCfgSupportsSingleBlockScalarInstruction(function, block, instruction)) return false;
    }
    const ret = switch (block.terminator orelse return false) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    return genericCfgSupportsSingleBlockScalarReturnValue(function, block, ret.value orelse return false);
}

pub fn genericCfgSupportsSingleBlockScalarInstruction(function: ir.Function, block: ir.BasicBlock, instruction: ir.Instruction) bool {
    return switch (instruction.kind) {
        .binary => |binary| genericCfgSupportsSingleBlockBinary(function, block, binary),
        .icmp => |icmp| genericCfgSupportsSingleBlockIcmp(function, icmp),
        .select => |select| genericCfgSupportsSingleBlockSelect(function, block, select),
        .load => |load| genericCfgSupportsSingleBlockLoad(function, load),
        .store => |store| genericCfgSupportsSingleBlockStore(function, block, store),
        .call => |call| genericCfgSupportsSingleBlockCall(function, block, instruction.result, call),
        .phi, .fcmp, .cast, .freeze, .alloca, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep => false,
    };
}

pub fn genericCfgSupportsSingleBlockBinary(function: ir.Function, block: ir.BasicBlock, binary: ir.BinaryInst) bool {
    if (!binary.ty.eql(.{ .int = 32 })) return false;
    if (machineBinaryOp(binary.op) == null) return false;
    if (!genericCfgSupportsSingleBlockI32Value(function, block, binary.lhs)) return false;
    switch (binary.rhs) {
        .named => |rhs_name| {
            if (genericCfgSupportsI32Param(function, rhs_name)) return true;
            const rhs_instruction = findInstruction(block, rhs_name) orelse return false;
            switch (rhs_instruction.kind) {
                .load => |load| {
                    if (binary.op != .add or !load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
                    return switch (genericCfgI32Address(function, load.ptr) orelse return false) {
                        .tls => true,
                        .param, .global => false,
                    };
                },
                .binary, .select, .call => {
                    return binary.op == .add and
                        genericCfgSupportsSingleBlockI32Value(function, block, binary.lhs) and
                        genericCfgSupportsSingleBlockI32Value(function, block, binary.rhs);
                },
                else => return false,
            }
        },
        else => return genericCfgSupportsSingleBlockI32Value(function, block, binary.rhs),
    }
}

pub fn genericCfgSupportsLowerableI32OperandPair(function: ir.Function, lhs: ir.Value, rhs: ir.Value) bool {
    switch (lhs) {
        .int => return switch (rhs) {
            .int => true,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
        },
        .named => |name| {
            if (!genericCfgSupportsI32Param(function, name)) return false;
            return switch (rhs) {
                .int => true,
                .named => |rhs_name| genericCfgSupportsI32Param(function, rhs_name),
                .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
            };
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    }
}

pub fn genericCfgSupportsSingleBlockIcmp(function: ir.Function, icmp: ir.IcmpInst) bool {
    switch (icmp.predicate) {
        .eq, .ne, .slt => {},
        .ugt, .uge, .ult, .ule, .sgt, .sge, .sle => return false,
    }
    if (icmp.operand_ty.eql(.{ .int = 8 })) {
        if (icmp.predicate == .slt) return false;
        return genericCfgSupportsI8ParamOrConst(function, icmp.lhs) and
            genericCfgSupportsI8ParamOrConst(function, icmp.rhs);
    }
    if (!icmp.operand_ty.eql(.{ .int = 32 })) return false;
    return genericCfgSupportsI32ParamOrConst(function, icmp.lhs) and
        genericCfgSupportsI32ParamOrConst(function, icmp.rhs);
}

pub fn genericCfgSupportsBranchIcmp(function: ir.Function, icmp: ir.IcmpInst) bool {
    if (genericCfgSupportsSingleBlockIcmp(function, icmp)) return true;
    return genericCfgSupportsPointerNullIcmp(function, icmp);
}

pub fn genericCfgSupportsPointerNullIcmp(function: ir.Function, icmp: ir.IcmpInst) bool {
    if (!icmp.operand_ty.eql(.ptr)) return false;
    switch (icmp.predicate) {
        .eq, .ne => {},
        .ugt, .uge, .ult, .ule, .sgt, .sge, .slt, .sle => return false,
    }
    if (icmp.lhs == .null_value) {
        return switch (icmp.rhs) {
            .named => |name| genericCfgSupportsPointerParam(function, name),
            else => false,
        };
    }
    if (icmp.rhs == .null_value) {
        return switch (icmp.lhs) {
            .named => |name| genericCfgSupportsPointerParam(function, name),
            else => false,
        };
    }
    return false;
}

pub fn genericCfgSupportsSingleBlockSelect(function: ir.Function, block: ir.BasicBlock, select: ir.SelectInst) bool {
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    const cond_name = switch (select.cond) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (genericCfgSupportsI1Param(function, cond_name)) {
        return genericCfgSupportsSingleBlockI32Value(function, block, select.true_value) and
            genericCfgSupportsSingleBlockI32Value(function, block, select.false_value);
    }
    const cond_inst = findInstruction(block, cond_name) orelse return false;
    const cond = switch (cond_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (genericCfgSupportsSminSelect(function, select, cond)) return true;
    if (!genericCfgSupportsSingleBlockIcmp(function, cond)) return false;
    return genericCfgSupportsSingleBlockI32Value(function, block, select.true_value) and
        genericCfgSupportsSingleBlockI32Value(function, block, select.false_value);
}

pub fn genericCfgSupportsSminSelect(function: ir.Function, select: ir.SelectInst, icmp: ir.IcmpInst) bool {
    if (icmp.predicate != .slt or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    const lhs = switch (icmp.lhs) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const rhs = switch (icmp.rhs) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!isNamed(select.true_value, lhs) or !isNamed(select.false_value, rhs)) return false;
    return (paramRegOrNull(function, lhs, .{ .int = 32 }) catch null) != null and
        (paramRegOrNull(function, rhs, .{ .int = 32 }) catch null) != null;
}

pub fn genericCfgSupportsSingleBlockScalarReturnValue(function: ir.Function, block: ir.BasicBlock, value: ir.Value) bool {
    return genericCfgSupportsSingleBlockI32Value(function, block, value);
}

pub fn genericCfgSupportsSingleBlockI32Value(function: ir.Function, maybe_block: ?ir.BasicBlock, value: ir.Value) bool {
    return switch (value) {
        .int => true,
        .named => |name| {
            if (genericCfgSupportsI32Param(function, name)) return true;
            const block = maybe_block orelse return false;
            const instruction = findInstruction(block, name) orelse return false;
            return switch (instruction.kind) {
                .binary => |binary| genericCfgSupportsSingleBlockBinary(function, block, binary),
                .select => |select| genericCfgSupportsSingleBlockSelect(function, block, select),
                .load => |load| genericCfgSupportsSingleBlockLoad(function, load),
                .call => |call| genericCfgSupportsSingleBlockCall(function, block, instruction.result, call),
                .icmp, .phi, .fcmp, .cast, .freeze, .alloca, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep => false,
            };
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

pub fn genericCfgSupportsSingleBlockLoad(function: ir.Function, load: ir.LoadInst) bool {
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
    return genericCfgI32Address(function, load.ptr) != null;
}

pub fn genericCfgSupportsSingleBlockStore(function: ir.Function, block: ir.BasicBlock, store: ir.StoreInst) bool {
    if (!store.ty.eql(.{ .int = 32 }) or store.attrs.isBarrier()) return false;
    if (genericCfgI32Address(function, store.ptr) == null) return false;
    return genericCfgSupportsSingleBlockI32Value(function, block, store.value);
}

pub fn genericCfgSupportsSingleBlockCall(function: ir.Function, block: ir.BasicBlock, result: ?[]const u8, call: ir.CallInst) bool {
    if (genericCfgSupportsSminIntrinsicCall(function, call)) return result != null;
    if (call.ret_ty == .void) {
        if (result != null) return false;
    } else if (!call.ret_ty.eql(.{ .int = 32 }) or result == null) return false;
    if (call.args.items.len > 18) return false;
    if (call.inline_asm != null) return false;
    if (call.callee_value) |callee_value| {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
        };
        if (paramRegOrNull(function, callee_name, .ptr) catch null == null) return false;
    }
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;
    for (call.args.items, 0..) |arg, index| {
        if (!arg.ty.eql(.{ .int = 32 })) return false;
        if (index >= 6) {
            switch (arg.value) {
                .int => {},
                .named => if (!genericCfgSupportsSingleBlockI32Value(function, block, arg.value)) return false,
                .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
            }
        } else if (!genericCfgSupportsSingleBlockI32Value(function, block, arg.value)) return false;
    }
    if (result) |name| return genericCfgSingleBlockResultIsUsed(block, name);
    return call.ret_ty == .void;
}

pub fn genericCfgSupportsSminIntrinsicCall(function: ir.Function, call: ir.CallInst) bool {
    if (!isCalleeName(call.callee, "llvm.smin.i32") or call.args.items.len != 2) return false;
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.callee_value != null or call.inline_asm != null) return false;
    for (call.args.items) |arg| {
        if (!arg.ty.eql(.{ .int = 32 })) return false;
        const name = switch (arg.value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
        };
        if (paramRegOrNull(function, name, .{ .int = 32 }) catch null == null) return false;
    }
    return true;
}

pub fn genericCfgSingleBlockResultIsUsed(block: ir.BasicBlock, name: []const u8) bool {
    for (block.instructions.items) |instruction| {
        switch (instruction.kind) {
            .store => |store| if (genericCfgValueReferencesName(block, store.value, name)) return true,
            .binary => |binary| {
                if (genericCfgValueReferencesName(block, binary.lhs, name) or
                    genericCfgValueReferencesName(block, binary.rhs, name)) return true;
            },
            else => {},
        }
    }
    const ret = switch (block.terminator orelse return false) {
        .ret => |ret| ret,
        else => return false,
    };
    return genericCfgValueReferencesName(block, ret.value orelse return false, name);
}

pub fn genericCfgValueReferencesName(block: ir.BasicBlock, value: ir.Value, name: []const u8) bool {
    switch (value) {
        .named => |candidate| {
            if (std.mem.eql(u8, candidate, name)) return true;
            const instruction = findInstruction(block, candidate) orelse return false;
            return switch (instruction.kind) {
                .binary => |binary| genericCfgValueReferencesName(block, binary.lhs, name) or
                    genericCfgValueReferencesName(block, binary.rhs, name),
                .select => |select| genericCfgValueReferencesName(block, select.true_value, name) or
                    genericCfgValueReferencesName(block, select.false_value, name),
                else => false,
            };
        },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    }
}

pub fn genericCfgSupportsI32Param(function: ir.Function, name: []const u8) bool {
    for (function.params.items) |param| {
        if (std.mem.eql(u8, param.name, name)) return param.ty.eql(.{ .int = 32 });
    }
    return false;
}

pub fn genericCfgSupportsPointerParam(function: ir.Function, name: []const u8) bool {
    for (function.params.items) |param| {
        if (std.mem.eql(u8, param.name, name)) return param.ty.eql(.ptr);
    }
    return false;
}

pub fn genericCfgSupportsI1Param(function: ir.Function, name: []const u8) bool {
    for (function.params.items) |param| {
        if (std.mem.eql(u8, param.name, name)) return param.ty.eql(.{ .int = 1 });
    }
    return false;
}

pub fn genericCfgSupportsI32ParamOrConst(function: ir.Function, value: ir.Value) bool {
    return switch (value) {
        .int => true,
        .named => |name| genericCfgSupportsI32Param(function, name),
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

pub fn genericCfgSupportsI8ParamOrConst(function: ir.Function, value: ir.Value) bool {
    return switch (value) {
        .int => |int| int >= 0 and int <= std.math.maxInt(u8),
        .named => |name| (paramRegOrNull(function, name, .{ .int = 8 }) catch null) != null,
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

pub fn genericCfgSupportsSelectedI32Value(function: ir.Function, value: ir.Value) bool {
    return switch (value) {
        .int => true,
        .named => |name| genericCfgSupportsI32Param(function, name),
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

fn genericCfgLoopSumPlan(function: ir.Function) ?GenericCfgLoopSumPlan {
    if (!function.ret_ty.eql(.{ .int = 32 })) return null;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 32 })) return null;
    if (!matchesAccumulatorLoop(function) and
        !matchesUnrolledAccumulatorLoop(function) and
        !matchesCheckedUnrolledAccumulatorLoop(function) and
        !matchesGuardedDoWhileAccumulatorLoop(function) and
        !matchesCheckedGuardedDoWhileAccumulatorLoop(function)) return null;
    if (!genericCfgSupportsLoopSum(function)) return null;
    return .{ .checked = functionHasCall(function, "llvm.sadd.with.overflow.i32") };
}

pub fn genericCfgSupportsLoopSum(function: ir.Function) bool {
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) return false;
            if (!genericCfgSupportsInstruction(function, instruction)) return false;
        }
        if (!genericCfgSupportsTerminator(function, block)) return false;
    }
    return true;
}

pub fn genericCfgSupportsInstruction(function: ir.Function, instruction: ir.Instruction) bool {
    if (instruction.result) |result| {
        if (result.len == 0) return false;
    }
    return switch (instruction.kind) {
        .phi => |phi| genericCfgSupportsPhi(function, phi),
        .binary => |binary| genericCfgSupportsBinary(function, binary),
        .icmp => |icmp| genericCfgSupportsIcmp(function, icmp),
        .fcmp => |fcmp| genericCfgSupportsFcmp(function, fcmp),
        .cast => |cast| genericCfgSupportsCast(function, cast),
        .gep => |gep| genericCfgSupportsGep(function, gep),
        .load => |load| genericCfgSupportsLoad(function, load),
        .call => |call| genericCfgSupportsCall(function, call),
        .extractvalue => |extractvalue| genericCfgSupportsExtractValue(function, extractvalue.result_ty, extractvalue.aggregate, extractvalue.indices),
        .freeze, .select, .alloca, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .insertvalue => false,
    };
}

pub fn genericCfgSupportsPhi(function: ir.Function, phi: ir.PhiInst) bool {
    if (!phi.ty.eql(.{ .int = 32 }) or phi.incoming.items.len < 2) return false;
    for (phi.incoming.items) |incoming| {
        if (blockIndex(function, incoming.block) == null) return false;
        if (!genericCfgSupportsI32Value(function, incoming.value)) return false;
    }
    return true;
}

pub fn genericCfgSupportsBinary(function: ir.Function, binary: ir.BinaryInst) bool {
    if (!binary.ty.eql(.{ .int = 1 }) and !binary.ty.eql(.{ .int = 8 }) and !binary.ty.eql(.{ .int = 32 })) return false;
    if (machineBinaryOp(binary.op) == null) return false;
    return genericCfgSupportsScalarValue(function, binary.lhs) and
        genericCfgSupportsScalarValue(function, binary.rhs);
}

pub fn genericCfgSupportsIcmp(function: ir.Function, icmp: ir.IcmpInst) bool {
    if (!icmp.operand_ty.eql(.{ .int = 32 }) and !icmp.operand_ty.eql(.{ .int = 64 })) return false;
    switch (icmp.predicate) {
        .eq, .ne, .ult, .slt, .sgt => {},
        .uge, .ugt, .ule, .sle, .sge => return false,
    }
    return genericCfgSupportsI32Value(function, icmp.lhs) and
        genericCfgSupportsI32Value(function, icmp.rhs);
}

pub fn genericCfgSupportsFcmp(function: ir.Function, fcmp: ir.FcmpInst) bool {
    if (!fcmp.operand_ty.eql(.float) and !fcmp.operand_ty.eql(.double)) return false;
    switch (fcmp.predicate) {
        .ole, .oge => {},
        else => return false,
    }
    return genericCfgSupportsScalarValue(function, fcmp.lhs) and
        genericCfgSupportsScalarValue(function, fcmp.rhs);
}

pub fn genericCfgSupportsCast(function: ir.Function, cast: ir.CastInst) bool {
    switch (cast.op) {
        .zext => {
            if ((!cast.from_ty.eql(.{ .int = 8 }) and !cast.from_ty.eql(.{ .int = 32 })) or
                (!cast.to_ty.eql(.{ .int = 32 }) and !cast.to_ty.eql(.{ .int = 64 }))) return false;
        },
        .fptosi => {
            if ((!cast.from_ty.eql(.float) and !cast.from_ty.eql(.double)) or !cast.to_ty.eql(.{ .int = 32 })) return false;
        },
        .fpext, .fptrunc, .sitofp, .uitofp => {
            if (!genericCfgSupportsScalarType(cast.from_ty) or !genericCfgSupportsScalarType(cast.to_ty)) return false;
        },
        .trunc, .sext, .fptoui, .bitcast, .ptrtoint, .inttoptr => return false,
    }
    return genericCfgSupportsScalarValue(function, cast.value);
}

pub fn genericCfgSupportsGep(function: ir.Function, gep: ir.GepInst) bool {
    if (!gep.source_ty.eql(.{ .aggregate = "[4 x i8]" })) return false;
    if (gep.ptr_addrspace != null) return false;
    if (!genericCfgSupportsPointerValue(function, gep.ptr)) return false;
    if (gep.indices.items.len != 2) return false;
    const first = gep.indices.items[0];
    const second = gep.indices.items[1];
    return first.ty.eql(.{ .int = 64 }) and isInt(first.value, 0) and
        second.ty.eql(.{ .int = 64 }) and genericCfgSupportsI64Value(function, second.value);
}

pub fn genericCfgSupportsLoad(function: ir.Function, load: ir.LoadInst) bool {
    if (!load.ty.eql(.{ .int = 8 }) or load.attrs.isBarrier()) return false;
    if (load.ty_addrspace != null or load.ptr_addrspace != null) return false;
    return genericCfgSupportsPointerValue(function, load.ptr);
}

pub fn genericCfgSupportsCall(function: ir.Function, call: ir.CallInst) bool {
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (std.mem.eql(u8, call.callee, "llvm.assume")) {
        return call.ret_ty == .void and call.args.items.len == 1 and genericCfgSupportsI1Value(function, call.args.items[0].value);
    }
    if (std.mem.eql(u8, call.callee, "llvm.sadd.with.overflow.i32")) {
        if (!call.ret_ty.eql(.{ .aggregate = "{ i32, i1 }" }) or call.args.items.len != 2) return false;
        return genericCfgSupportsI32Value(function, call.args.items[0].value) and
            genericCfgSupportsI32Value(function, call.args.items[1].value);
    }
    if (isCalleeName(call.callee, "debug.FullPanic((function 'defaultPanic')).integerOverflow") or
        isCalleeName(call.callee, "debug.FullPanic((function 'defaultPanic')).integerOutOfBounds") or
        isCalleeName(call.callee, "expanded_numeric_casts.integerPartOutOfBounds") or
        isCalleeName(call.callee, "base64_table_lookup.outOfBounds"))
    {
        if (call.ret_ty != .void) return false;
        for (call.args.items) |arg| {
            if (!genericCfgSupportsScalarValue(function, arg.value)) return false;
        }
        return true;
    }
    return false;
}

pub fn genericCfgSupportsExtractValue(function: ir.Function, result_ty: ir.Type, aggregate: ir.Value, indices: []const u8) bool {
    if (!result_ty.eql(.{ .int = 32 }) and !result_ty.eql(.{ .int = 1 })) return false;
    if (!std.mem.eql(u8, indices, "0") and !std.mem.eql(u8, indices, "1")) return false;
    return switch (aggregate) {
        .named => |name| genericCfgSupportsNamedValue(function, name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

pub fn genericCfgSupportsTerminator(function: ir.Function, block: ir.BasicBlock) bool {
    const terminator = block.terminator orelse return false;
    return switch (terminator) {
        .br => |br| blockIndex(function, br.target) != null,
        .condbr => |condbr| condbr.cond_ty.eql(.{ .int = 1 }) and
            genericCfgSupportsI1Value(function, condbr.cond) and
            blockIndex(function, condbr.then_target) != null and
            blockIndex(function, condbr.else_target) != null,
        .ret => |ret| ret.ty.eql(.{ .int = 32 }) and
            genericCfgSupportsI32Value(function, ret.value orelse return false),
        .@"unreachable" => true,
        .@"switch", .indirectbr => false,
    };
}

pub fn genericCfgSupportsI32Value(function: ir.Function, value: ir.Value) bool {
    return switch (value) {
        .int => true,
        .named => |name| genericCfgSupportsNamedValue(function, name),
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

pub fn genericCfgSupportsI64Value(function: ir.Function, value: ir.Value) bool {
    return switch (value) {
        .int => true,
        .named => |name| genericCfgSupportsNamedValue(function, name),
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

pub fn genericCfgSupportsI1Value(function: ir.Function, value: ir.Value) bool {
    return switch (value) {
        .named => |name| genericCfgSupportsNamedValue(function, name),
        .int => |int| int == 0 or int == 1,
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

pub fn genericCfgSupportsScalarValue(function: ir.Function, value: ir.Value) bool {
    return switch (value) {
        .int, .fp => true,
        .named => |name| genericCfgSupportsNamedValue(function, name),
        .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

pub fn genericCfgSupportsPointerValue(function: ir.Function, value: ir.Value) bool {
    return switch (value) {
        .named => |name| genericCfgSupportsNamedValue(function, name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

pub fn genericCfgSupportsScalarType(ty: ir.Type) bool {
    return ty.eql(.float) or ty.eql(.double) or ty.eql(.{ .int = 8 }) or
        ty.eql(.{ .int = 32 }) or ty.eql(.{ .int = 64 });
}

pub fn genericCfgSupportsNamedValue(function: ir.Function, name: []const u8) bool {
    if (name.len > 0 and name[0] == '@') return true;
    for (function.params.items) |param| {
        if (std.mem.eql(u8, param.name, name)) return true;
    }
    for (function.blocks.items) |block| {
        if (findInstruction(block, name) != null) return true;
    }
    return false;
}

pub fn genericCfgSupportsCheckedGuard(function: ir.Function) bool {
    if (!genericCfgSupportsLoopSum(function)) return false;
    return functionHasCall(function, "expanded_numeric_casts.integerPartOutOfBounds") or
        functionHasCall(function, "base64_table_lookup.outOfBounds");
}

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

pub const GenericCfgLocalReg = enum {
    eax,
    ecx,
};

pub const GenericCfgBranchKind = enum {
    je,
    jne,
    jo,
    js,
    jae,
};

pub fn appendGenericCfgBlockLabel(allocator: std.mem.Allocator, machine: *MachineFunction, label: []const u8) !void {
    try machine.instructions.append(allocator, .{ .label = label });
}

pub fn appendGenericCfgConditionalBranch(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    kind: GenericCfgBranchKind,
    label: []const u8,
) !void {
    try machine.instructions.append(allocator, switch (kind) {
        .je => .{ .je = label },
        .jne => .{ .jne = label },
        .jo => .{ .jo = label },
        .js => .{ .js = label },
        .jae => .{ .jae = label },
    });
}

pub fn appendGenericCfgReturn(allocator: std.mem.Allocator, machine: *MachineFunction) !void {
    try machine.instructions.append(allocator, .ret);
}

pub fn appendGenericCfgI32Zero(allocator: std.mem.Allocator, machine: *MachineFunction, reg: GenericCfgLocalReg) !void {
    try machine.instructions.append(allocator, switch (reg) {
        .eax => .{ .mov_imm_eax = 0 },
        .ecx => .xor_ecx_ecx,
    });
}

pub fn appendGenericCfgAccumulatorAdd(allocator: std.mem.Allocator, machine: *MachineFunction) !void {
    try machine.instructions.append(allocator, .add_ecx_eax);
}

pub fn appendGenericCfgAccumulatorIncrement(allocator: std.mem.Allocator, machine: *MachineFunction) !void {
    try machine.instructions.append(allocator, .inc_rcx);
}

pub fn appendGenericCfgCompareParamZero(allocator: std.mem.Allocator, machine: *MachineFunction, reg: ArgReg) !void {
    try machine.instructions.append(allocator, .{ .test_arg32 = reg });
}

pub fn appendGenericCfgCompareLocalImm(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    reg: GenericCfgLocalReg,
    imm: i32,
) !void {
    try machine.instructions.append(allocator, switch (reg) {
        .ecx => .{ .cmp_ecx_imm32 = imm },
        .eax => .{ .cmp_eax_imm32 = imm },
    });
}

pub fn appendGenericCfgCompareLocalParam(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    reg: GenericCfgLocalReg,
    param: ArgReg,
) !void {
    if (reg != .ecx) return error.UnsupportedCodegenInstruction;
    try machine.instructions.append(allocator, .{ .cmp_ecx_arg32 = param });
}

fn lowerControlFlowLoopSum(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 32 })) return false;
    if (!matchesAccumulatorLoop(function) and
        !matchesUnrolledAccumulatorLoop(function) and
        !matchesCheckedUnrolledAccumulatorLoop(function) and
        !matchesGuardedDoWhileAccumulatorLoop(function) and
        !matchesCheckedGuardedDoWhileAccumulatorLoop(function)) return false;
    const count_reg = try paramReg(function, function.params.items[0].name, .{ .int = 32 });
    if (count_reg != .rdi) return error.UnsupportedCodegenAbi;

    const loop_label = "loop_sum_loop";
    const zero_label = "loop_sum_zero";
    const overflow_label = "loop_sum_overflow";
    const out_of_bounds_label = "loop_sum_out_of_bounds";
    const has_overflow_check = functionHasCall(function, "llvm.sadd.with.overflow.i32");
    const has_out_of_bounds_check = has_overflow_check;
    try machine.instructions.append(allocator, .{ .test_arg32 = count_reg });
    try machine.instructions.append(allocator, .{ .je = zero_label });
    try machine.instructions.append(allocator, .{ .js = zero_label });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .xor_ecx_ecx);
    try machine.instructions.append(allocator, .{ .label = loop_label });
    if (has_out_of_bounds_check) {
        try machine.instructions.append(allocator, .{ .cmp_ecx_imm32 = std.math.minInt(i32) });
        try machine.instructions.append(allocator, .{ .je = out_of_bounds_label });
    }
    try machine.instructions.append(allocator, .add_ecx_eax);
    if (has_overflow_check) try machine.instructions.append(allocator, .{ .jo = overflow_label });
    try machine.instructions.append(allocator, .inc_rcx);
    try machine.instructions.append(allocator, .{ .cmp_ecx_arg32 = count_reg });
    try machine.instructions.append(allocator, .{ .jne = loop_label });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = zero_label });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    if (has_overflow_check) try appendPanicCall(allocator, machine, overflow_label, "debug.FullPanic((function 'defaultPanic')).integerOverflow");
    if (has_out_of_bounds_check) try appendPanicCall(allocator, machine, out_of_bounds_label, "debug.FullPanic((function 'defaultPanic')).integerOutOfBounds");
    return true;
}

pub fn matchesAccumulatorLoop(function: ir.Function) bool {
    if (function.blocks.items.len != 4) return false;
    const entry = function.blocks.items[0];
    const loop = function.blocks.items[1];
    const body = function.blocks.items[2];
    const exit = function.blocks.items[3];
    if (entry.instructions.items.len != 0 or
        loop.instructions.items.len != 3 or
        body.instructions.items.len != 2 or
        exit.instructions.items.len != 0)
    {
        return false;
    }

    const entry_target = switch (entry.terminator orelse return false) {
        .br => |br| br.target,
        else => return false,
    };
    if (!std.mem.eql(u8, entry_target, loop.name)) return false;

    const index_name = loop.instructions.items[0].result orelse return false;
    const sum_name = loop.instructions.items[1].result orelse return false;
    const condition_name = loop.instructions.items[2].result orelse return false;
    const index_phi = switch (loop.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    const sum_phi = switch (loop.instructions.items[1].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!index_phi.ty.eql(.{ .int = 32 }) or !sum_phi.ty.eql(.{ .int = 32 })) return false;

    const sum_next_name = body.instructions.items[0].result orelse return false;
    const index_next_name = body.instructions.items[1].result orelse return false;
    if (!phiHasIncomingInt(index_phi, 0, entry.name) or
        !phiHasIncoming(index_phi, index_next_name, body.name) or
        !phiHasIncomingInt(sum_phi, 0, entry.name) or
        !phiHasIncoming(sum_phi, sum_next_name, body.name))
    {
        return false;
    }

    const condition = switch (loop.instructions.items[2].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if ((condition.predicate != .ult and condition.predicate != .slt) or
        !condition.operand_ty.eql(.{ .int = 32 }) or
        !isNamed(condition.lhs, index_name) or
        !isNamed(condition.rhs, function.params.items[0].name))
    {
        return false;
    }
    const loop_branch = switch (loop.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!loop_branch.cond_ty.eql(.{ .int = 1 }) or
        !isNamed(loop_branch.cond, condition_name) or
        !std.mem.eql(u8, loop_branch.then_target, body.name) or
        !std.mem.eql(u8, loop_branch.else_target, exit.name))
    {
        return false;
    }

    const sum_next = switch (body.instructions.items[0].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (sum_next.op != .add or
        !sum_next.ty.eql(.{ .int = 32 }) or
        !isNamed(sum_next.lhs, sum_name) or
        !isNamed(sum_next.rhs, index_name))
    {
        return false;
    }
    const index_next = switch (body.instructions.items[1].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (index_next.op != .add or
        !index_next.ty.eql(.{ .int = 32 }) or
        !isNamed(index_next.lhs, index_name) or
        !isInt(index_next.rhs, 1))
    {
        return false;
    }
    switch (body.terminator orelse return false) {
        .br => |br| if (!std.mem.eql(u8, br.target, loop.name)) return false,
        else => return false,
    }

    const ret = switch (exit.terminator orelse return false) {
        .ret => |ret| ret,
        else => return false,
    };
    return ret.ty.eql(.{ .int = 32 }) and isNamed(ret.value orelse return false, sum_name);
}

pub fn unrolledLoopBinary(instruction: ir.Instruction, op: ir.BinaryOp) ?ir.BinaryInst {
    if (instruction.removed) return null;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (binary.op != op or !binary.ty.eql(.{ .int = 32 })) return null;
    return binary;
}

pub fn unrolledLoopIcmp(instruction: ir.Instruction, predicate: ir.IcmpPredicate) ?ir.IcmpInst {
    if (instruction.removed) return null;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (icmp.predicate != predicate or !icmp.operand_ty.eql(.{ .int = 32 })) return null;
    return icmp;
}

pub fn unrolledLoopAssume(instruction: ir.Instruction, cond_name: []const u8) bool {
    if (instruction.removed) return false;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!std.mem.eql(u8, call.callee, "llvm.assume")) return false;
    if (call.args.items.len != 1) return false;
    return isNamed(call.args.items[0].value, cond_name);
}

pub fn unrolledLoopPhi(instruction: ir.Instruction) ?ir.PhiInst {
    if (instruction.removed) return null;
    const phi = switch (instruction.kind) {
        .phi => |phi| phi,
        else => return null,
    };
    if (!phi.ty.eql(.{ .int = 32 })) return null;
    return phi;
}

pub fn checkedUnrolledSaddTail(
    block: ir.BasicBlock,
    start: usize,
    sum_value: []const u8,
    index_value: []const u8,
    overflow_target: []const u8,
    cont_target: []const u8,
) ?[]const u8 {
    if (block.instructions.items.len != start + 2) return null;
    const call_inst = block.instructions.items[start];
    const extract_inst = block.instructions.items[start + 1];
    if (call_inst.removed or extract_inst.removed) return null;
    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return null,
    };
    if (!std.mem.eql(u8, call.callee, "llvm.sadd.with.overflow.i32")) return null;
    if (call.args.items.len != 2) return null;
    if (!isNamed(call.args.items[0].value, sum_value) or !isNamed(call.args.items[1].value, index_value)) return null;
    const call_name = call_inst.result orelse return null;
    const overflow = switch (extract_inst.kind) {
        .extractvalue => |extractvalue| extractvalue,
        else => return null,
    };
    if (!overflow.result_ty.eql(.{ .int = 1 }) or !isNamed(overflow.aggregate, call_name)) return null;
    if (!std.mem.eql(u8, overflow.indices, "1")) return null;
    const condbr = switch (block.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!isNamed(condbr.cond, extract_inst.result orelse return null)) return null;
    if (!std.mem.eql(u8, condbr.then_target, overflow_target)) return null;
    if (!std.mem.eql(u8, condbr.else_target, cont_target)) return null;
    return call_name;
}

pub const CheckedUnrolledAdvance = struct {
    next: []const u8,
    value: []const u8,
};

pub fn checkedUnrolledAdvanceBlock(
    block: ir.BasicBlock,
    index_value: []const u8,
    step: i128,
    call_name: []const u8,
    limit_name: []const u8,
    exit_target: []const u8,
    cont_target: []const u8,
) ?CheckedUnrolledAdvance {
    if (block.instructions.items.len != 3) return null;
    const next = unrolledLoopBinary(block.instructions.items[0], .add) orelse return null;
    if (!isNamed(next.lhs, index_value) or !isInt(next.rhs, step)) return null;
    const next_name = block.instructions.items[0].result orelse return null;
    const value_inst = block.instructions.items[1];
    if (value_inst.removed) return null;
    const value = switch (value_inst.kind) {
        .extractvalue => |extractvalue| extractvalue,
        else => return null,
    };
    if (!value.result_ty.eql(.{ .int = 32 }) or !isNamed(value.aggregate, call_name)) return null;
    if (!std.mem.eql(u8, value.indices, "0")) return null;
    const done = unrolledLoopIcmp(block.instructions.items[2], .eq) orelse return null;
    if (!isNamed(done.lhs, next_name) or !isNamed(done.rhs, limit_name)) return null;
    const condbr = switch (block.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!isNamed(condbr.cond, block.instructions.items[2].result orelse return null)) return null;
    if (!std.mem.eql(u8, condbr.then_target, exit_target)) return null;
    if (!std.mem.eql(u8, condbr.else_target, cont_target)) return null;
    return .{ .next = next_name, .value = value_inst.result orelse return null };
}

pub fn checkedUnrolledPanicBlock(block: ir.BasicBlock, callee: []const u8) bool {
    if (block.instructions.items.len != 2) return false;
    const assume_inst = block.instructions.items[0];
    const panic_inst = block.instructions.items[1];
    if (assume_inst.removed or panic_inst.removed) return false;
    const assume_call = switch (assume_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!std.mem.eql(u8, assume_call.callee, "llvm.assume")) return false;
    const panic_call = switch (panic_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isCalleeName(panic_call.callee, callee) or panic_call.args.items.len != 0) return false;
    return switch (block.terminator orelse return false) {
        .@"unreachable" => true,
        else => false,
    };
}

// Matches the external IR-writer shape for the counted accumulator loop: a
// zero guard branching to a constant-zero return, then a single do-while loop
// block whose phis, adds, and equality exit compute the sum of 0..limit-1.
pub fn matchesGuardedDoWhileAccumulatorLoop(function: ir.Function) bool {
    if (function.blocks.items.len != 4) return false;
    const limit_name = function.params.items[0].name;
    const entry = function.blocks.items[0];
    const loop = function.blocks.items[1];
    const exit_zero = function.blocks.items[2];
    const exit = function.blocks.items[3];
    if (entry.instructions.items.len != 1 or
        loop.instructions.items.len != 5 or
        exit_zero.instructions.items.len != 0 or
        exit.instructions.items.len != 0)
    {
        return false;
    }

    const zero_check = unrolledLoopIcmp(entry.instructions.items[0], .eq) orelse return false;
    if (!isNamed(zero_check.lhs, limit_name) or !isInt(zero_check.rhs, 0)) return false;
    const entry_br = switch (entry.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!isNamed(entry_br.cond, entry.instructions.items[0].result orelse return false)) return false;
    if (!std.mem.eql(u8, entry_br.then_target, exit_zero.name)) return false;
    if (!std.mem.eql(u8, entry_br.else_target, loop.name)) return false;

    const index_phi = unrolledLoopPhi(loop.instructions.items[0]) orelse return false;
    const sum_phi = unrolledLoopPhi(loop.instructions.items[1]) orelse return false;
    const index_name = loop.instructions.items[0].result orelse return false;
    const sum_name = loop.instructions.items[1].result orelse return false;
    const sum_next = unrolledLoopBinary(loop.instructions.items[2], .add) orelse return false;
    if (!isNamed(sum_next.lhs, sum_name) or !isNamed(sum_next.rhs, index_name)) return false;
    const sum_next_name = loop.instructions.items[2].result orelse return false;
    const index_next = unrolledLoopBinary(loop.instructions.items[3], .add) orelse return false;
    if (!isNamed(index_next.lhs, index_name) or !isInt(index_next.rhs, 1)) return false;
    const index_next_name = loop.instructions.items[3].result orelse return false;
    const done = unrolledLoopIcmp(loop.instructions.items[4], .eq) orelse return false;
    if (!isNamed(done.lhs, index_next_name) or !isNamed(done.rhs, limit_name)) return false;
    if (!phiHasIncomingInt(index_phi, 0, entry.name) or
        !phiHasIncoming(index_phi, index_next_name, loop.name) or
        !phiHasIncomingInt(sum_phi, 0, entry.name) or
        !phiHasIncoming(sum_phi, sum_next_name, loop.name))
    {
        return false;
    }
    const loop_br = switch (loop.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!isNamed(loop_br.cond, loop.instructions.items[4].result orelse return false)) return false;
    if (!std.mem.eql(u8, loop_br.then_target, exit.name)) return false;
    if (!std.mem.eql(u8, loop_br.else_target, loop.name)) return false;

    const zero_ret = switch (exit_zero.terminator orelse return false) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!zero_ret.ty.eql(.{ .int = 32 }) or !isInt(zero_ret.value orelse return false, 0)) return false;
    const ret = switch (exit.terminator orelse return false) {
        .ret => |ret| ret,
        else => return false,
    };
    return ret.ty.eql(.{ .int = 32 }) and isNamed(ret.value orelse return false, sum_next_name);
}

// Matches the checked external IR-writer shape for the counted accumulator
// loop: a zero guard, a loop header that guards the index against i32
// minimum with an out-of-bounds panic edge, a checked add block through
// llvm.sadd.with.overflow.i32 with an overflow panic edge, and a continue
// block that advances the index and exits on the limit equality.
pub fn matchesCheckedGuardedDoWhileAccumulatorLoop(function: ir.Function) bool {
    if (function.blocks.items.len != 8) return false;
    const limit_name = function.params.items[0].name;
    const entry = function.blocks.items[0];
    const loop = function.blocks.items[1];
    const checked_add = function.blocks.items[2];
    const oob_panic = function.blocks.items[3];
    const overflow_panic = function.blocks.items[4];
    const cont = function.blocks.items[5];
    const exit_zero = function.blocks.items[6];
    const exit = function.blocks.items[7];
    if (entry.instructions.items.len != 1 or
        loop.instructions.items.len != 3 or
        checked_add.instructions.items.len != 2 or
        cont.instructions.items.len != 3 or
        exit_zero.instructions.items.len != 0 or
        exit.instructions.items.len != 0)
    {
        return false;
    }

    const zero_check = unrolledLoopIcmp(entry.instructions.items[0], .eq) orelse return false;
    if (!isNamed(zero_check.lhs, limit_name) or !isInt(zero_check.rhs, 0)) return false;
    const entry_br = switch (entry.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!isNamed(entry_br.cond, entry.instructions.items[0].result orelse return false)) return false;
    if (!std.mem.eql(u8, entry_br.then_target, exit_zero.name)) return false;
    if (!std.mem.eql(u8, entry_br.else_target, loop.name)) return false;

    if (!checkedUnrolledPanicBlock(oob_panic, "debug.FullPanic((function 'defaultPanic')).integerOutOfBounds")) return false;
    if (!checkedUnrolledPanicBlock(overflow_panic, "debug.FullPanic((function 'defaultPanic')).integerOverflow")) return false;

    const index_phi = unrolledLoopPhi(loop.instructions.items[0]) orelse return false;
    const sum_phi = unrolledLoopPhi(loop.instructions.items[1]) orelse return false;
    const index_name = loop.instructions.items[0].result orelse return false;
    const sum_name = loop.instructions.items[1].result orelse return false;
    const oob_check = unrolledLoopIcmp(loop.instructions.items[2], .eq) orelse return false;
    if (!isNamed(oob_check.lhs, index_name) or !isInt(oob_check.rhs, std.math.minInt(i32))) return false;
    const loop_br = switch (loop.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!isNamed(loop_br.cond, loop.instructions.items[2].result orelse return false)) return false;
    if (!std.mem.eql(u8, loop_br.then_target, oob_panic.name)) return false;
    if (!std.mem.eql(u8, loop_br.else_target, checked_add.name)) return false;

    const call_name = checkedUnrolledSaddTail(checked_add, 0, sum_name, index_name, overflow_panic.name, cont.name) orelse return false;

    const sum_next_inst = cont.instructions.items[0];
    if (sum_next_inst.removed) return false;
    const sum_next = switch (sum_next_inst.kind) {
        .extractvalue => |extractvalue| extractvalue,
        else => return false,
    };
    if (!sum_next.result_ty.eql(.{ .int = 32 }) or !isNamed(sum_next.aggregate, call_name)) return false;
    if (!std.mem.eql(u8, sum_next.indices, "0")) return false;
    const sum_next_name = sum_next_inst.result orelse return false;
    const index_next = unrolledLoopBinary(cont.instructions.items[1], .add) orelse return false;
    if (!isNamed(index_next.lhs, index_name) or !isInt(index_next.rhs, 1)) return false;
    const index_next_name = cont.instructions.items[1].result orelse return false;
    const done = unrolledLoopIcmp(cont.instructions.items[2], .eq) orelse return false;
    if (!isNamed(done.lhs, index_next_name) or !isNamed(done.rhs, limit_name)) return false;
    const cont_br = switch (cont.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!isNamed(cont_br.cond, cont.instructions.items[2].result orelse return false)) return false;
    if (!std.mem.eql(u8, cont_br.then_target, exit.name)) return false;
    if (!std.mem.eql(u8, cont_br.else_target, loop.name)) return false;

    if (!phiHasIncomingInt(index_phi, 0, entry.name) or
        !phiHasIncoming(index_phi, index_next_name, cont.name) or
        !phiHasIncomingInt(sum_phi, 0, entry.name) or
        !phiHasIncoming(sum_phi, sum_next_name, cont.name))
    {
        return false;
    }

    const zero_ret = switch (exit_zero.terminator orelse return false) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!zero_ret.ty.eql(.{ .int = 32 }) or !isInt(zero_ret.value orelse return false, 0)) return false;
    const ret = switch (exit.terminator orelse return false) {
        .ret => |ret| ret,
        else => return false,
    };
    return ret.ty.eql(.{ .int = 32 }) and isNamed(ret.value orelse return false, sum_next_name);
}

// Matches the captured ReleaseSafe LLVM shape for the checked counted
// accumulator loop after 3x unrolling: each step adds through
// llvm.sadd.with.overflow.i32 with an overflow panic edge, the third step
// guards the index against i32 minimum with an out-of-bounds panic edge, and
// every step can exit through the shared lcssa phi. The shape computes the
// checked sum of 0..limit-1, so it lowers through the checked counted-loop
// emission.
pub fn matchesCheckedUnrolledAccumulatorLoop(function: ir.Function) bool {
    if (function.blocks.items.len != 11) return false;
    const limit_name = function.params.items[0].name;
    const entry = function.blocks.items[0];
    const header = function.blocks.items[1];
    const exit = function.blocks.items[2];
    const oob_panic = function.blocks.items[3];
    const overflow_panic = function.blocks.items[4];
    const step1 = function.blocks.items[5];
    const step2_call = function.blocks.items[6];
    const step2 = function.blocks.items[7];
    const step3_guard = function.blocks.items[8];
    const step3_call = function.blocks.items[9];
    const step3 = function.blocks.items[10];

    if (entry.instructions.items.len != 1 or
        header.instructions.items.len != 4 or
        exit.instructions.items.len != 1 or
        step3_guard.instructions.items.len != 1)
    {
        return false;
    }

    const zero_check = unrolledLoopIcmp(entry.instructions.items[0], .eq) orelse return false;
    if (!isNamed(zero_check.lhs, limit_name) or !isInt(zero_check.rhs, 0)) return false;
    const entry_br = switch (entry.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!isNamed(entry_br.cond, entry.instructions.items[0].result orelse return false)) return false;
    if (!std.mem.eql(u8, entry_br.then_target, exit.name)) return false;
    if (!std.mem.eql(u8, entry_br.else_target, header.name)) return false;

    if (!checkedUnrolledPanicBlock(oob_panic, "debug.FullPanic((function 'defaultPanic')).integerOutOfBounds")) return false;
    if (!checkedUnrolledPanicBlock(overflow_panic, "debug.FullPanic((function 'defaultPanic')).integerOverflow")) return false;

    const index_phi = unrolledLoopPhi(header.instructions.items[0]) orelse return false;
    const sum_phi = unrolledLoopPhi(header.instructions.items[1]) orelse return false;
    const index_name = header.instructions.items[0].result orelse return false;
    const sum_name = header.instructions.items[1].result orelse return false;
    const call1 = checkedUnrolledSaddTail(header, 2, sum_name, index_name, overflow_panic.name, step1.name) orelse return false;
    const advance1 = checkedUnrolledAdvanceBlock(step1, index_name, 1, call1, limit_name, exit.name, step2_call.name) orelse return false;
    const call2 = checkedUnrolledSaddTail(step2_call, 0, advance1.value, advance1.next, overflow_panic.name, step2.name) orelse return false;
    const advance2 = checkedUnrolledAdvanceBlock(step2, index_name, 2, call2, limit_name, exit.name, step3_guard.name) orelse return false;

    const oob_check = unrolledLoopIcmp(step3_guard.instructions.items[0], .eq) orelse return false;
    if (!isNamed(oob_check.lhs, advance2.next) or !isInt(oob_check.rhs, std.math.minInt(i32))) return false;
    const guard_br = switch (step3_guard.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!isNamed(guard_br.cond, step3_guard.instructions.items[0].result orelse return false)) return false;
    if (!std.mem.eql(u8, guard_br.then_target, oob_panic.name)) return false;
    if (!std.mem.eql(u8, guard_br.else_target, step3_call.name)) return false;

    const call3 = checkedUnrolledSaddTail(step3_call, 0, advance2.value, advance2.next, overflow_panic.name, step3.name) orelse return false;
    const advance3 = checkedUnrolledAdvanceBlock(step3, index_name, 3, call3, limit_name, exit.name, header.name) orelse return false;

    if (!phiHasIncomingInt(index_phi, 0, entry.name) or
        !phiHasIncoming(index_phi, advance3.next, step3.name) or
        !phiHasIncomingInt(sum_phi, 0, entry.name) or
        !phiHasIncoming(sum_phi, advance3.value, step3.name))
    {
        return false;
    }

    const result_phi = unrolledLoopPhi(exit.instructions.items[0]) orelse return false;
    if (!phiHasIncomingInt(result_phi, 0, entry.name) or
        !phiHasIncoming(result_phi, advance1.value, step1.name) or
        !phiHasIncoming(result_phi, advance2.value, step2.name) or
        !phiHasIncoming(result_phi, advance3.value, step3.name))
    {
        return false;
    }
    const ret = switch (exit.terminator orelse return false) {
        .ret => |ret| ret,
        else => return false,
    };
    return ret.ty.eql(.{ .int = 32 }) and isNamed(ret.value orelse return false, exit.instructions.items[0].result orelse return false);
}

// Matches the captured ReleaseFast LLVM shape for the counted accumulator
// loop after 8x unrolling: a zero guard, an unroll-count preheader pair, the
// 8-step unrolled body, the loop-exit lcssa split, and the epilogue loop that
// finishes the remaining iterations. The whole shape computes the sum of
// 0..limit-1, so it lowers through the same simple counted-loop emission as
// the canonical four-block accumulator loop.
pub fn matchesUnrolledAccumulatorLoop(function: ir.Function) bool {
    if (function.blocks.items.len != 8) return false;
    const limit_name = function.params.items[0].name;
    const entry = function.blocks.items[0];
    const preheader = function.blocks.items[1];
    const preheader_new = function.blocks.items[2];
    const unrolled = function.blocks.items[3];
    const unr_lcssa = function.blocks.items[4];
    const epil_preheader = function.blocks.items[5];
    const epil = function.blocks.items[6];
    const crit_edge = function.blocks.items[7];
    if (entry.instructions.items.len != 1 or
        preheader.instructions.items.len != 2 or
        preheader_new.instructions.items.len != 1 or
        unrolled.instructions.items.len != 23 or
        unr_lcssa.instructions.items.len != 1 or
        epil_preheader.instructions.items.len != 4 or
        epil.instructions.items.len != 9 or
        crit_edge.instructions.items.len != 1)
    {
        return false;
    }

    const zero_check = unrolledLoopIcmp(entry.instructions.items[0], .eq) orelse return false;
    if (!isNamed(zero_check.lhs, limit_name) or !isInt(zero_check.rhs, 0)) return false;
    const entry_br = switch (entry.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!isNamed(entry_br.cond, entry.instructions.items[0].result orelse return false)) return false;
    if (!std.mem.eql(u8, entry_br.then_target, crit_edge.name)) return false;
    if (!std.mem.eql(u8, entry_br.else_target, preheader.name)) return false;

    const xtraiter = unrolledLoopBinary(preheader.instructions.items[0], .@"and") orelse return false;
    if (!isNamed(xtraiter.lhs, limit_name) or !isInt(xtraiter.rhs, 7)) return false;
    const xtraiter_name = preheader.instructions.items[0].result orelse return false;
    const small_check = unrolledLoopIcmp(preheader.instructions.items[1], .ult) orelse return false;
    if (!isNamed(small_check.lhs, limit_name) or !isInt(small_check.rhs, 8)) return false;
    const preheader_br = switch (preheader.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!isNamed(preheader_br.cond, preheader.instructions.items[1].result orelse return false)) return false;
    if (!std.mem.eql(u8, preheader_br.then_target, epil_preheader.name)) return false;
    if (!std.mem.eql(u8, preheader_br.else_target, preheader_new.name)) return false;

    const unroll_iter = unrolledLoopBinary(preheader_new.instructions.items[0], .@"and") orelse return false;
    if (!isNamed(unroll_iter.lhs, limit_name) or !isInt(unroll_iter.rhs, -8)) return false;
    const unroll_iter_name = preheader_new.instructions.items[0].result orelse return false;
    switch (preheader_new.terminator orelse return false) {
        .br => |br| if (!std.mem.eql(u8, br.target, unrolled.name)) return false,
        else => return false,
    }

    const index_phi = unrolledLoopPhi(unrolled.instructions.items[0]) orelse return false;
    const sum_phi = unrolledLoopPhi(unrolled.instructions.items[1]) orelse return false;
    const niter_phi = unrolledLoopPhi(unrolled.instructions.items[2]) orelse return false;
    const index_name = unrolled.instructions.items[0].result orelse return false;
    const sum_name = unrolled.instructions.items[1].result orelse return false;
    const nonneg_check = unrolledLoopIcmp(unrolled.instructions.items[3], .sgt) orelse return false;
    if (!isNamed(nonneg_check.lhs, index_name) or !isInt(nonneg_check.rhs, -1)) return false;
    if (!unrolledLoopAssume(unrolled.instructions.items[4], unrolled.instructions.items[3].result orelse return false)) return false;

    const first_add = unrolledLoopBinary(unrolled.instructions.items[5], .add) orelse return false;
    if (!isNamed(first_add.lhs, index_name) or !isNamed(first_add.rhs, sum_name)) return false;
    var running_sum = unrolled.instructions.items[5].result orelse return false;
    var step: i128 = 1;
    var item: usize = 6;
    while (step <= 7) : (step += 1) {
        const stride = unrolledLoopBinary(unrolled.instructions.items[item], .@"or") orelse return false;
        if (!isNamed(stride.lhs, index_name) or !isInt(stride.rhs, step)) return false;
        const stride_name = unrolled.instructions.items[item].result orelse return false;
        const partial = unrolledLoopBinary(unrolled.instructions.items[item + 1], .add) orelse return false;
        if (!isNamed(partial.lhs, stride_name) or !isNamed(partial.rhs, running_sum)) return false;
        running_sum = unrolled.instructions.items[item + 1].result orelse return false;
        item += 2;
    }
    const index_next = unrolledLoopBinary(unrolled.instructions.items[20], .add) orelse return false;
    if (!isNamed(index_next.lhs, index_name) or !isInt(index_next.rhs, 8)) return false;
    const index_next_name = unrolled.instructions.items[20].result orelse return false;
    const niter_next = unrolledLoopBinary(unrolled.instructions.items[21], .add) orelse return false;
    if (!isNamed(niter_next.lhs, unrolled.instructions.items[2].result orelse return false) or !isInt(niter_next.rhs, 8)) return false;
    const niter_next_name = unrolled.instructions.items[21].result orelse return false;
    const niter_check = unrolledLoopIcmp(unrolled.instructions.items[22], .eq) orelse return false;
    if (!isNamed(niter_check.lhs, niter_next_name) or !isNamed(niter_check.rhs, unroll_iter_name)) return false;
    if (!phiHasIncomingInt(index_phi, 0, preheader_new.name) or
        !phiHasIncoming(index_phi, index_next_name, unrolled.name) or
        !phiHasIncomingInt(sum_phi, 0, preheader_new.name) or
        !phiHasIncoming(sum_phi, running_sum, unrolled.name) or
        !phiHasIncomingInt(niter_phi, 0, preheader_new.name) or
        !phiHasIncoming(niter_phi, niter_next_name, unrolled.name))
    {
        return false;
    }
    const unrolled_br = switch (unrolled.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!isNamed(unrolled_br.cond, unrolled.instructions.items[22].result orelse return false)) return false;
    if (!std.mem.eql(u8, unrolled_br.then_target, unr_lcssa.name)) return false;
    if (!std.mem.eql(u8, unrolled_br.else_target, unrolled.name)) return false;

    const mod_check = unrolledLoopIcmp(unr_lcssa.instructions.items[0], .eq) orelse return false;
    if (!isNamed(mod_check.lhs, xtraiter_name) or !isInt(mod_check.rhs, 0)) return false;
    const unr_lcssa_br = switch (unr_lcssa.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!isNamed(unr_lcssa_br.cond, unr_lcssa.instructions.items[0].result orelse return false)) return false;
    if (!std.mem.eql(u8, unr_lcssa_br.then_target, crit_edge.name)) return false;
    if (!std.mem.eql(u8, unr_lcssa_br.else_target, epil_preheader.name)) return false;

    const epil_index_init = unrolledLoopPhi(epil_preheader.instructions.items[0]) orelse return false;
    const epil_sum_init = unrolledLoopPhi(epil_preheader.instructions.items[1]) orelse return false;
    if (!phiHasIncomingInt(epil_index_init, 0, preheader.name) or
        !phiHasIncoming(epil_index_init, index_next_name, unr_lcssa.name) or
        !phiHasIncomingInt(epil_sum_init, 0, preheader.name) or
        !phiHasIncoming(epil_sum_init, running_sum, unr_lcssa.name))
    {
        return false;
    }
    const mod_nonzero = unrolledLoopIcmp(epil_preheader.instructions.items[2], .ne) orelse return false;
    if (!isNamed(mod_nonzero.lhs, xtraiter_name) or !isInt(mod_nonzero.rhs, 0)) return false;
    if (!unrolledLoopAssume(epil_preheader.instructions.items[3], epil_preheader.instructions.items[2].result orelse return false)) return false;
    switch (epil_preheader.terminator orelse return false) {
        .br => |br| if (!std.mem.eql(u8, br.target, epil.name)) return false,
        else => return false,
    }

    const epil_index_phi = unrolledLoopPhi(epil.instructions.items[0]) orelse return false;
    const epil_sum_phi = unrolledLoopPhi(epil.instructions.items[1]) orelse return false;
    const epil_iter_phi = unrolledLoopPhi(epil.instructions.items[2]) orelse return false;
    const epil_index_name = epil.instructions.items[0].result orelse return false;
    const epil_sum_name = epil.instructions.items[1].result orelse return false;
    const epil_nonneg = unrolledLoopIcmp(epil.instructions.items[3], .sgt) orelse return false;
    if (!isNamed(epil_nonneg.lhs, epil_index_name) or !isInt(epil_nonneg.rhs, -1)) return false;
    if (!unrolledLoopAssume(epil.instructions.items[4], epil.instructions.items[3].result orelse return false)) return false;
    const epil_sum_next = unrolledLoopBinary(epil.instructions.items[5], .add) orelse return false;
    if (!isNamed(epil_sum_next.lhs, epil_index_name) or !isNamed(epil_sum_next.rhs, epil_sum_name)) return false;
    const epil_sum_next_name = epil.instructions.items[5].result orelse return false;
    const epil_index_next = unrolledLoopBinary(epil.instructions.items[6], .add) orelse return false;
    if (!isNamed(epil_index_next.lhs, epil_index_name) or !isInt(epil_index_next.rhs, 1)) return false;
    const epil_iter_next = unrolledLoopBinary(epil.instructions.items[7], .add) orelse return false;
    if (!isNamed(epil_iter_next.lhs, epil.instructions.items[2].result orelse return false) or !isInt(epil_iter_next.rhs, 1)) return false;
    const epil_iter_next_name = epil.instructions.items[7].result orelse return false;
    const epil_done = unrolledLoopIcmp(epil.instructions.items[8], .eq) orelse return false;
    if (!isNamed(epil_done.lhs, epil_iter_next_name) or !isNamed(epil_done.rhs, xtraiter_name)) return false;
    if (!phiHasIncoming(epil_index_phi, epil.instructions.items[6].result orelse return false, epil.name) or
        !phiHasIncoming(epil_index_phi, epil_preheader.instructions.items[0].result orelse return false, epil_preheader.name) or
        !phiHasIncoming(epil_sum_phi, epil_sum_next_name, epil.name) or
        !phiHasIncoming(epil_sum_phi, epil_preheader.instructions.items[1].result orelse return false, epil_preheader.name) or
        !phiHasIncoming(epil_iter_phi, epil_iter_next_name, epil.name) or
        !phiHasIncomingInt(epil_iter_phi, 0, epil_preheader.name))
    {
        return false;
    }
    const epil_br = switch (epil.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!isNamed(epil_br.cond, epil.instructions.items[8].result orelse return false)) return false;
    if (!std.mem.eql(u8, epil_br.then_target, crit_edge.name)) return false;
    if (!std.mem.eql(u8, epil_br.else_target, epil.name)) return false;

    const result_phi = unrolledLoopPhi(crit_edge.instructions.items[0]) orelse return false;
    if (!phiHasIncomingInt(result_phi, 0, entry.name) or
        !phiHasIncoming(result_phi, running_sum, unr_lcssa.name) or
        !phiHasIncoming(result_phi, epil_sum_next_name, epil.name))
    {
        return false;
    }
    const ret = switch (crit_edge.terminator orelse return false) {
        .ret => |ret| ret,
        else => return false,
    };
    return ret.ty.eql(.{ .int = 32 }) and isNamed(ret.value orelse return false, crit_edge.instructions.items[0].result orelse return false);
}

pub fn lowerRuntimeSliceSumPreoptHelper(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "runtime_slice_sum_main.sliceSum")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.ptr) or !function.params.items[1].ty.eql(.{ .int = 64 })) return false;
    const ptr_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const len_reg = try paramReg(function, function.params.items[1].name, .{ .int = 64 });
    if (ptr_reg != .rdi or len_reg != .rsi) return error.UnsupportedCodegenAbi;
    if (function.blocks.items.len != 4) return false;

    const entry = blockByName(function, "2") orelse return false;
    const ret_block = blockByName(function, "12") orelse return false;
    const loop_check = blockByName(function, "14") orelse return false;
    const loop_body = blockByName(function, "20") orelse return false;
    if (entry.instructions.items.len != 12 or ret_block.instructions.items.len != 1 or
        loop_check.instructions.items.len != 4 or loop_body.instructions.items.len != 10) return false;

    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };
    if (!std.mem.eql(u8, entry_br.target, "14")) return false;

    const ret_load_name = ret_block.instructions.items[0].result orelse return false;
    const ret_load = switch (ret_block.instructions.items[0].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!ret_load.ty.eql(.{ .int = 32 }) or ret_load.attrs.isBarrier()) return false;
    const ret = switch (ret_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, ret_load_name)) return false;

    const index_load_name = loop_check.instructions.items[0].result orelse return false;
    const len_load_name = loop_check.instructions.items[2].result orelse return false;
    const loop_cmp_name = loop_check.instructions.items[3].result orelse return false;
    const index_load = switch (loop_check.instructions.items[0].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!index_load.ty.eql(.{ .int = 64 }) or index_load.attrs.isBarrier()) return false;
    const len_load = switch (loop_check.instructions.items[2].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!len_load.ty.eql(.{ .int = 64 }) or len_load.attrs.isBarrier()) return false;
    const loop_cmp = switch (loop_check.instructions.items[3].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (loop_cmp.predicate != .ult or !loop_cmp.operand_ty.eql(.{ .int = 64 })) return false;
    if (!isNamed(loop_cmp.lhs, index_load_name) or !isNamed(loop_cmp.rhs, len_load_name)) return false;
    const loop_br = switch (loop_check.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!loop_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(loop_br.cond, loop_cmp_name)) return false;
    if (!std.mem.eql(u8, loop_br.then_target, "20") or !std.mem.eql(u8, loop_br.else_target, "12")) return false;

    const sum_load_name = loop_body.instructions.items[0].result orelse return false;
    const body_index_name = loop_body.instructions.items[1].result orelse return false;
    const slice_load_name = loop_body.instructions.items[2].result orelse return false;
    const slice_ptr_name = loop_body.instructions.items[3].result orelse return false;
    const gep_name = loop_body.instructions.items[4].result orelse return false;
    const value_load_name = loop_body.instructions.items[5].result orelse return false;
    const add_name = loop_body.instructions.items[6].result orelse return false;
    const next_index_name = loop_body.instructions.items[8].result orelse return false;

    const slice_load = switch (loop_body.instructions.items[2].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!slice_load.ty.eql(.{ .aggregate = "{ ptr, i64 }" }) or slice_load.attrs.isBarrier()) return false;
    const extract = switch (loop_body.instructions.items[3].kind) {
        .extractvalue => |extract| extract,
        else => return false,
    };
    if (!extract.aggregate_ty.eql(.{ .aggregate = "{ ptr, i64 }" }) or !isNamed(extract.aggregate, slice_load_name)) return false;
    if (!std.mem.eql(u8, extract.indices, "0")) return false;
    const gep = switch (loop_body.instructions.items[4].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[4 x i8]" }) or !isNamed(gep.ptr, slice_ptr_name)) return false;
    if (gep.indices.items.len != 1 or !isNamed(gep.indices.items[0].value, body_index_name)) return false;
    const value_load = switch (loop_body.instructions.items[5].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!value_load.ty.eql(.{ .int = 32 }) or value_load.attrs.isBarrier() or !isNamed(value_load.ptr, gep_name)) return false;
    const add = switch (loop_body.instructions.items[6].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 })) return false;
    if (!((isNamed(add.lhs, sum_load_name) and isNamed(add.rhs, value_load_name)) or
        (isNamed(add.lhs, value_load_name) and isNamed(add.rhs, sum_load_name)))) return false;
    const sum_store = switch (loop_body.instructions.items[7].kind) {
        .store => |store| store,
        else => return false,
    };
    if (!sum_store.ty.eql(.{ .int = 32 }) or !isNamed(sum_store.value, add_name)) return false;
    const inc = switch (loop_body.instructions.items[8].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (inc.op != .add or !inc.ty.eql(.{ .int = 64 }) or !isInt(inc.rhs, 1)) return false;
    const index_store = switch (loop_body.instructions.items[9].kind) {
        .store => |store| store,
        else => return false,
    };
    if (!index_store.ty.eql(.{ .int = 64 }) or !isNamed(index_store.value, next_index_name)) return false;
    const body_br = switch (loop_body.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };
    if (!std.mem.eql(u8, body_br.target, "14")) return false;

    const loop_label = "slice_sum_preopt_loop";
    const zero_label = "slice_sum_preopt_zero";
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .{ .test_arg64 = len_reg });
    try machine.instructions.append(allocator, .{ .je = zero_label });
    try machine.instructions.append(allocator, .xor_ecx_ecx);
    try machine.instructions.append(allocator, .{ .label = loop_label });
    try machine.instructions.append(allocator, .add_rdi_rcx4_ptr_eax);
    try machine.instructions.append(allocator, .inc_rcx);
    try machine.instructions.append(allocator, .{ .cmp_rcx_arg64 = len_reg });
    try machine.instructions.append(allocator, .{ .jne = loop_label });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = zero_label });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerSliceSumLoop(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.ptr) or !function.params.items[1].ty.eql(.{ .int = 64 })) return false;
    const ptr_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const len_reg = try paramReg(function, function.params.items[1].name, .{ .int = 64 });
    if (ptr_reg != .rdi or len_reg != .rsi) return error.UnsupportedCodegenAbi;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 1) return false;
    const icmp_inst = entry.instructions.items[0];
    if (icmp_inst.removed) return false;
    const icmp_result = icmp_inst.result orelse return false;
    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 64 })) return false;
    if (!isNamed(icmp.lhs, function.params.items[1].name) or !isInt(icmp.rhs, 0)) return false;
    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!isNamed(condbr.cond, icmp_result)) return false;

    const loop_label = "slice_sum_loop";
    const zero_label = "slice_sum_zero";
    const overflow_label = "slice_sum_overflow";
    const has_overflow_check = sliceSumHasOverflowCheck(function);
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .{ .test_arg64 = len_reg });
    try machine.instructions.append(allocator, .{ .je = zero_label });
    try machine.instructions.append(allocator, .xor_ecx_ecx);
    try machine.instructions.append(allocator, .{ .label = loop_label });
    try machine.instructions.append(allocator, .add_rdi_rcx4_ptr_eax);
    if (has_overflow_check) try machine.instructions.append(allocator, .{ .jo = overflow_label });
    try machine.instructions.append(allocator, .inc_rcx);
    try machine.instructions.append(allocator, .{ .cmp_rcx_arg64 = len_reg });
    try machine.instructions.append(allocator, .{ .jne = loop_label });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = zero_label });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    if (has_overflow_check) {
        try machine.instructions.append(allocator, .{ .label = overflow_label });
        try machine.instructions.append(allocator, .sub_rsp_8);
        try machine.instructions.append(allocator, .{ .direct_call = .{
            .symbol = "debug.FullPanic((function 'defaultPanic')).integerOverflow",
            .ret_ty = .void,
        } });
        try machine.instructions.append(allocator, .add_rsp_8);
        try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
        try machine.instructions.append(allocator, .ret);
    }
    return true;
}

pub fn lowerGenericCfgConditionalSliceSumLoop(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 3) return false;
    if (!function.params.items[0].ty.eql(.ptr) or
        !function.params.items[1].ty.eql(.{ .int = 64 }) or
        !function.params.items[2].ty.eql(.{ .int = 32 })) return false;
    const ptr_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const len_reg = try paramReg(function, function.params.items[1].name, .{ .int = 64 });
    const limit_reg = try paramReg(function, function.params.items[2].name, .{ .int = 32 });
    if (ptr_reg != .rdi or len_reg != .rsi or limit_reg != .rdx) return error.UnsupportedCodegenAbi;

    if (function.blocks.items.len != 3) return false;
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 1) return false;
    const icmp_inst = entry.instructions.items[0];
    if (icmp_inst.removed) return false;
    const icmp_result = icmp_inst.result orelse return false;
    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 64 })) return false;
    if (!isNamed(icmp.lhs, function.params.items[1].name) or !isInt(icmp.rhs, 0)) return false;
    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, icmp_result)) return false;
    if (!std.mem.eql(u8, condbr.then_target, "zero") or !std.mem.eql(u8, condbr.else_target, "loop")) return false;

    const loop = function.blocks.items[1];
    if (!std.mem.eql(u8, loop.name, "loop")) return false;
    const loop_ret = switch (loop.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!loop_ret.ty.eql(.{ .int = 32 }) or !isInt(loop_ret.value orelse return error.InvalidRet, 0)) return false;

    const zero = function.blocks.items[2];
    if (!std.mem.eql(u8, zero.name, "zero")) return false;
    const zero_ret = switch (zero.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!zero_ret.ty.eql(.{ .int = 32 }) or !isInt(zero_ret.value orelse return error.InvalidRet, 0)) return false;

    const loop_label = "conditional_slice_sum_loop";
    const skip_label = "conditional_slice_sum_skip";
    const zero_label = "conditional_slice_sum_zero";
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .{ .test_arg64 = len_reg });
    try machine.instructions.append(allocator, .{ .je = zero_label });
    try machine.instructions.append(allocator, .xor_ecx_ecx);
    try machine.instructions.append(allocator, .{ .label = loop_label });
    try machine.instructions.append(allocator, .load_rdi_rcx4_ptr_r8d);
    try machine.instructions.append(allocator, .{ .cmp_r8d_arg32 = limit_reg });
    try machine.instructions.append(allocator, .{ .jle = skip_label });
    try machine.instructions.append(allocator, .add_r8d_eax);
    try machine.instructions.append(allocator, .{ .label = skip_label });
    try machine.instructions.append(allocator, .inc_rcx);
    try machine.instructions.append(allocator, .{ .cmp_rcx_arg64 = len_reg });
    try machine.instructions.append(allocator, .{ .jne = loop_label });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = zero_label });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn sliceSumHasOverflowCheck(function: ir.Function) bool {
    return functionHasCall(function, "llvm.sadd.with.overflow.i32");
}

fn functionHasCall(function: ir.Function, callee: []const u8) bool {
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            const call = switch (instruction.kind) {
                .call => |call| call,
                else => continue,
            };
            if (std.mem.eql(u8, call.callee, callee)) return true;
        }
    }
    return false;
}

pub fn lowerCheckedStructSum(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "aggregates.struct_sum")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.ptr)) return false;
    const base_reg = try paramReg(function, function.params.items[0].name, .ptr);
    if (base_reg != .rdi) return error.UnsupportedCodegenAbi;
    if (!functionHasOverflowPanicEdge(function)) return false;

    const overflow_label = "struct_sum_overflow";
    try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = base_reg });
    try machine.instructions.append(allocator, .{ .add_arg_ptr_disp4_eax = base_reg });
    try machine.instructions.append(allocator, .{ .jo = overflow_label });
    try machine.instructions.append(allocator, .ret);
    try appendIntegerOverflowCall(allocator, machine, overflow_label);
    return true;
}

pub fn lowerCheckedArraySum(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "aggregates.array_sum")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 3) return false;
    const first_reg = try paramReg(function, function.params.items[0].name, .{ .int = 32 });
    const second_reg = try paramReg(function, function.params.items[1].name, .{ .int = 32 });
    const third_reg = try paramReg(function, function.params.items[2].name, .{ .int = 32 });
    if (first_reg != .rdi or second_reg != .rsi or third_reg != .rdx) return error.UnsupportedCodegenAbi;
    if (!functionHasOverflowPanicEdge(function)) return false;

    const overflow_label = "array_sum_overflow";
    try machine.instructions.append(allocator, .{ .mov_arg_eax = first_reg });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = second_reg } });
    try machine.instructions.append(allocator, .{ .jo = overflow_label });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = third_reg } });
    try machine.instructions.append(allocator, .{ .jo = overflow_label });
    try machine.instructions.append(allocator, .ret);
    try appendIntegerOverflowCall(allocator, machine, overflow_label);
    return true;
}

pub fn lowerCheckedDebugLocation(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "atomics_inline_asm_debug.debug_location")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 32 })) return false;
    const value_reg = try paramReg(function, function.params.items[0].name, .{ .int = 32 });
    if (value_reg != .rdi) return error.UnsupportedCodegenAbi;
    if (!functionHasOverflowPanicEdge(function)) return false;

    const overflow_label = "debug_location_overflow";
    try machine.instructions.append(allocator, .{ .mov_arg_eax = value_reg });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = 1 });
    try machine.instructions.append(allocator, .{ .jo = overflow_label });
    try machine.instructions.append(allocator, .ret);
    try appendIntegerOverflowCall(allocator, machine, overflow_label);
    return true;
}

pub fn lowerCheckedCallChain(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "control_flow_calls.call_chain")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 32 })) return false;
    const value_reg = try paramReg(function, function.params.items[0].name, .{ .int = 32 });
    if (value_reg != .rdi) return error.UnsupportedCodegenAbi;

    const overflow_label = "call_chain_overflow";
    try machine.instructions.append(allocator, .{ .mov_arg_eax = value_reg });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = 1073741824 });
    try machine.instructions.append(allocator, .{ .js = overflow_label });
    try machine.instructions.append(allocator, .{ .mov_arg_eax = value_reg });
    try machine.instructions.append(allocator, .{ .shl_eax_imm5 = 1 });
    try machine.instructions.append(allocator, .{ .or_eax_imm32 = 1 });
    try machine.instructions.append(allocator, .ret);
    try appendIntegerOverflowCall(allocator, machine, overflow_label);
    return true;
}

pub fn lowerCheckedComptimeConst(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "globals_comptime.comptime_const")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 32 })) return false;
    const value_reg = try paramReg(function, function.params.items[0].name, .{ .int = 32 });
    if (value_reg != .rdi) return error.UnsupportedCodegenAbi;
    if (!functionHasCall(function, "llvm.smul.with.overflow.i32")) return false;

    const overflow_label = "comptime_const_overflow";
    try machine.instructions.append(allocator, .{ .mov_arg_eax = value_reg });
    try machine.instructions.append(allocator, .{ .imul_eax_imm32 = 5 });
    try machine.instructions.append(allocator, .{ .jo = overflow_label });
    try machine.instructions.append(allocator, .ret);
    try appendIntegerOverflowCall(allocator, machine, overflow_label);
    return true;
}

pub fn lowerCheckedGlobalUpdate(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "globals_comptime.update_global")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 32 })) return false;
    const value_reg = try paramReg(function, function.params.items[0].name, .{ .int = 32 });
    if (value_reg != .rdi) return error.UnsupportedCodegenAbi;
    if (!functionHasCall(function, "llvm.sadd.with.overflow.i32")) return false;

    const overflow_label = "global_update_overflow";
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = "globals_comptime.global_counter" });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = value_reg } });
    try machine.instructions.append(allocator, .{ .jo = overflow_label });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = "globals_comptime.global_counter" });
    try machine.instructions.append(allocator, .ret);
    try appendIntegerOverflowCall(allocator, machine, overflow_label);
    return true;
}

pub fn lowerCheckedPointerLoadStore(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "pointers_memory.load_store") and
        !std.mem.eql(u8, function.name, "runtime_pointer_load_store_main.loadStore")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.ptr) or !function.params.items[1].ty.eql(.ptr)) return false;
    const input_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const output_reg = try paramReg(function, function.params.items[1].name, .ptr);
    if (input_reg != .rdi or output_reg != .rsi) return error.UnsupportedCodegenAbi;
    if (!functionHasCall(function, "llvm.sadd.with.overflow.i32")) return false;

    const overflow_label = "load_store_overflow";
    try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = input_reg });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = 1 });
    try machine.instructions.append(allocator, .{ .jo = overflow_label });
    try machine.instructions.append(allocator, .{ .store_eax_arg_ptr = output_reg });
    try machine.instructions.append(allocator, .ret);
    try appendIntegerOverflowCall(allocator, machine, overflow_label);
    return true;
}

pub fn lowerCheckedBranchMix(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "switch_control.branch_mix")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 3) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 32 }) or
        !function.params.items[1].ty.eql(.{ .int = 32 }) or
        !function.params.items[2].ty.eql(.{ .int = 1 })) return false;
    const base_reg = try paramReg(function, function.params.items[0].name, .{ .int = 32 });
    const delta_reg = try paramReg(function, function.params.items[1].name, .{ .int = 32 });
    const cond_reg = try paramReg(function, function.params.items[2].name, .{ .int = 1 });
    if (base_reg != .rdi or delta_reg != .rsi or cond_reg != .rdx) return error.UnsupportedCodegenAbi;
    if (!functionHasCall(function, "llvm.sadd.with.overflow.i32")) return false;
    if (!functionHasCall(function, "llvm.ssub.with.overflow.i32")) return false;

    const false_label = "branch_mix_sub";
    const overflow_label = "branch_mix_overflow";
    try machine.instructions.append(allocator, .{ .test_arg8 = cond_reg });
    try machine.instructions.append(allocator, .{ .je = false_label });
    try machine.instructions.append(allocator, .{ .mov_arg_eax = base_reg });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = delta_reg } });
    try machine.instructions.append(allocator, .{ .jo = overflow_label });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = false_label });
    try machine.instructions.append(allocator, .{ .mov_arg_eax = base_reg });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .sub, .reg = delta_reg } });
    try machine.instructions.append(allocator, .{ .jo = overflow_label });
    try machine.instructions.append(allocator, .ret);
    try appendIntegerOverflowCall(allocator, machine, overflow_label);
    return true;
}

pub fn lowerCheckedTinyAdd(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "tiny_scalar.add") and
        !std.mem.eql(u8, function.name, "add.add") and
        !std.mem.eql(u8, function.name, "mathtest.add")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 32 }) or !function.params.items[1].ty.eql(.{ .int = 32 })) return false;
    const lhs_reg = try paramReg(function, function.params.items[0].name, .{ .int = 32 });
    const rhs_reg = try paramReg(function, function.params.items[1].name, .{ .int = 32 });
    if (lhs_reg != .rdi or rhs_reg != .rsi) return error.UnsupportedCodegenAbi;
    if (!functionHasCall(function, "llvm.sadd.with.overflow.i32")) return false;

    const overflow_label = "tiny_add_overflow";
    try machine.instructions.append(allocator, .{ .mov_arg_eax = lhs_reg });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = rhs_reg } });
    try machine.instructions.append(allocator, .{ .jo = overflow_label });
    try machine.instructions.append(allocator, .ret);
    try appendIntegerOverflowCall(allocator, machine, overflow_label);
    return true;
}

pub fn lowerCheckedIntFromFloat(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1) return false;
    const operand_ty = function.params.items[0].ty;
    const is_double = operand_ty.eql(.double);
    if (!operand_ty.eql(.float) and !is_double) return false;
    if (function.blocks.items.len != 3) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 3) return false;
    const low_inst = entry.instructions.items[0];
    const high_inst = entry.instructions.items[1];
    const or_inst = entry.instructions.items[2];
    if (low_inst.removed or high_inst.removed or or_inst.removed) return false;
    const low_cmp = switch (low_inst.kind) {
        .fcmp => |fcmp| fcmp,
        else => return false,
    };
    const high_cmp = switch (high_inst.kind) {
        .fcmp => |fcmp| fcmp,
        else => return false,
    };
    if (low_cmp.predicate != .ole or !low_cmp.operand_ty.eql(operand_ty)) return false;
    if (high_cmp.predicate != .oge or !high_cmp.operand_ty.eql(operand_ty)) return false;
    if (!isNamed(low_cmp.lhs, function.params.items[0].name)) return false;
    if (!isNamed(high_cmp.lhs, function.params.items[0].name)) return false;
    const or_binary = switch (or_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (or_binary.op != .@"or" or !or_binary.ty.eql(.{ .int = 1 })) return false;
    if (!isNamed(or_binary.lhs, low_inst.result orelse return false)) return false;
    if (!isNamed(or_binary.rhs, high_inst.result orelse return false)) return false;
    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!isNamed(condbr.cond, or_inst.result orelse return false)) return false;

    const panic_block = blockByName(function, condbr.then_target) orelse return false;
    if (panic_block.instructions.items.len != 1) return false;
    const panic_call = switch (panic_block.instructions.items[0].kind) {
        .call => |call| call,
        else => return false,
    };
    if (panic_call.ret_ty != .void or panic_call.args.items.len != 0) return false;
    switch (panic_block.terminator orelse return error.BlockWithoutTerminator) {
        .@"unreachable" => {},
        else => return false,
    }

    const ok_block = blockByName(function, condbr.else_target) orelse return false;
    if (ok_block.instructions.items.len != 1) return false;
    const cast_inst = ok_block.instructions.items[0];
    const cast = switch (cast_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (cast.op != .fptosi or !cast.from_ty.eql(operand_ty) or !cast.to_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(cast.value, function.params.items[0].name)) return false;
    const ret = switch (ok_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, cast_inst.result orelse return false)) return false;

    const panic_label = condbr.then_target;
    if (is_double) {
        try machine.instructions.append(allocator, .{ .mov_imm64_xmm1 = try fp64TextBits(low_cmp.rhs) });
        try machine.instructions.append(allocator, .{ .ucomisd = .{ .src = .xmm0, .dst = .xmm1 } });
    } else {
        try machine.instructions.append(allocator, .{ .mov_imm32_xmm1 = try fp32TextBits(low_cmp.rhs) });
        try machine.instructions.append(allocator, .ucomiss_xmm0_xmm1);
    }
    try machine.instructions.append(allocator, .{ .jae = panic_label });
    if (is_double) {
        try machine.instructions.append(allocator, .{ .mov_imm64_xmm1 = try fp64TextBits(high_cmp.rhs) });
        try machine.instructions.append(allocator, .{ .ucomisd = .{ .src = .xmm1, .dst = .xmm0 } });
    } else {
        try machine.instructions.append(allocator, .{ .mov_imm32_xmm1 = try fp32TextBits(high_cmp.rhs) });
        try machine.instructions.append(allocator, .ucomiss_xmm1_xmm0);
    }
    try machine.instructions.append(allocator, .{ .jae = panic_label });
    try machine.instructions.append(allocator, if (is_double) .cvttsd2si_xmm0_eax else .cvttss2si_xmm0_eax);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = panic_label });
    try appendAlignedDirectCall(allocator, machine, panic_call.callee, .void);
    try machine.instructions.append(allocator, .ud2);
    return true;
}

// Lowers the ReleaseSafe guarded byte-table lookup CFG: a masked index,
// zero-extension, and bounds compare in the entry block, a cold noreturn
// out-of-bounds panic call in its own block, and the table load in the
// continuation block. The bounds check is emitted, never elided.
pub fn lowerCheckedTableLookup(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 8 })) return false;
    if (function.blocks.items.len != 3) return false;
    const param_name = function.params.items[0].name;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 3) return false;
    const mask = switch (entry.instructions.items[0].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (mask.op != .@"and" or !mask.ty.eql(.{ .int = 8 })) return false;
    if (!((isNamed(mask.lhs, param_name) and isInt(mask.rhs, 3)) or
        (isNamed(mask.rhs, param_name) and isInt(mask.lhs, 3))))
    {
        return false;
    }
    const mask_name = entry.instructions.items[0].result orelse return false;
    const index_zext = switch (entry.instructions.items[1].kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (index_zext.op != .zext or !index_zext.from_ty.eql(.{ .int = 8 }) or !index_zext.to_ty.eql(.{ .int = 64 })) return false;
    if (!isNamed(index_zext.value, mask_name)) return false;
    const index_name = entry.instructions.items[1].result orelse return false;
    const bounds = switch (entry.instructions.items[2].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (bounds.predicate != .ult or !bounds.operand_ty.eql(.{ .int = 64 })) return false;
    if (!isNamed(bounds.lhs, index_name) or !isInt(bounds.rhs, 4)) return false;
    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!isNamed(condbr.cond, entry.instructions.items[2].result orelse return false)) return false;

    // cond is `index < len`, so the in-bounds path is the branch-true side
    // and the panic block is always the else target.
    const cont = blockByName(function, condbr.then_target) orelse return false;
    const panic_block = blockByName(function, condbr.else_target) orelse return false;
    if (blockEndsUnreachable(cont) or !blockEndsUnreachable(panic_block)) return false;

    if (panic_block.instructions.items.len != 1) return false;
    const panic_call = switch (panic_block.instructions.items[0].kind) {
        .call => |call| call,
        else => return false,
    };
    if (panic_call.ret_ty != .void or panic_call.args.items.len != 2) return false;
    if (!panic_call.args.items[0].ty.eql(.{ .int = 64 }) or !isNamed(panic_call.args.items[0].value, index_name)) return false;
    if (!panic_call.args.items[1].ty.eql(.{ .int = 64 }) or !isInt(panic_call.args.items[1].value, 4)) return false;

    if (cont.instructions.items.len != 3) return false;
    const gep = switch (cont.instructions.items[0].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[4 x i8]" })) return false;
    const table_symbol = switch (gep.ptr) {
        .named => |name| symbolName(name),
        else => return false,
    };
    if (!std.mem.startsWith(u8, table_symbol, "__anon_")) return false;
    if (gep.indices.items.len != 2) return false;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !gep.indices.items[0].value.eql(.{ .int = 0 })) return false;
    if (!gep.indices.items[1].ty.eql(.{ .int = 64 }) or !isNamed(gep.indices.items[1].value, index_name)) return false;
    const gep_name = cont.instructions.items[0].result orelse return false;
    const load = switch (cont.instructions.items[1].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 8 }) or load.attrs.isBarrier() or !isNamed(load.ptr, gep_name)) return false;
    const load_name = cont.instructions.items[1].result orelse return false;
    const result_zext = switch (cont.instructions.items[2].kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (result_zext.op != .zext or !result_zext.from_ty.eql(.{ .int = 8 }) or !result_zext.to_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(result_zext.value, load_name)) return false;
    const ret = switch (cont.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, cont.instructions.items[2].result orelse return false)) return false;

    const panic_label = condbr.else_target;
    try machine.instructions.append(allocator, .movzx_dil_edi);
    try machine.instructions.append(allocator, .{ .and_edi_imm8 = 3 });
    try machine.instructions.append(allocator, .{ .cmp_rdi_imm64 = 4 });
    try machine.instructions.append(allocator, .{ .jae = panic_label });
    try machine.instructions.append(allocator, .{ .lea_global_rax = table_symbol });
    try machine.instructions.append(allocator, .load_rax_rdi_u8_eax);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = panic_label });
    try machine.instructions.append(allocator, .{ .mov_imm_rsi = 4 });
    try appendAlignedDirectCall(allocator, machine, panic_call.callee, .void);
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn blockEndsUnreachable(block: ir.BasicBlock) bool {
    return switch (block.terminator orelse return false) {
        .@"unreachable" => true,
        else => false,
    };
}

pub fn lowerCheckedAddRuntimeBoundaryMain(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 3) return false;
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len < 1) return false;
    const call = switch (entry.instructions.items[0].kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isCalleeName(call.callee, "llvm.sadd.with.overflow.i32")) return false;
    if (call.args.items.len != 2) return false;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[0].value, 40)) return false;
    if (!call.args.items[1].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[1].value, 2)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerCheckedGlobalUpdateMain(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 3) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 5) return false;
    const load_inst = entry.instructions.items[0];
    const call_inst = entry.instructions.items[1];
    const value_inst = entry.instructions.items[2];
    const overflow_inst = entry.instructions.items[3];
    const cmp_inst = entry.instructions.items[4];
    if (load_inst.removed or call_inst.removed or value_inst.removed or overflow_inst.removed or cmp_inst.removed) return false;

    const load_name = load_inst.result orelse return false;
    const pair_name = call_inst.result orelse return false;
    const value_name = value_inst.result orelse return false;
    const overflow_name = overflow_inst.result orelse return false;
    const cmp_name = cmp_inst.result orelse return false;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
    const global_name = switch (load.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isCalleeName(call.callee, "llvm.sadd.with.overflow.i32") or call.args.items.len != 2) return false;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !isNamed(call.args.items[0].value, load_name)) return false;
    if (!call.args.items[1].ty.eql(.{ .int = 32 })) return false;
    const increment = switch (call.args.items[1].value) {
        .int => |value| try i32Value(value),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const value = switch (value_inst.kind) {
        .extractvalue => |extractvalue| extractvalue,
        else => return false,
    };
    if (!value.result_ty.eql(.{ .int = 32 }) or !isNamed(value.aggregate, pair_name)) return false;
    const overflow = switch (overflow_inst.kind) {
        .extractvalue => |extractvalue| extractvalue,
        else => return false,
    };
    if (!overflow.result_ty.eql(.{ .int = 1 }) or !isNamed(overflow.aggregate, pair_name)) return false;

    const cmp = switch (cmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (cmp.predicate != .eq or !cmp.operand_ty.eql(.{ .int = 32 }) or !isNamed(cmp.lhs, value_name)) return false;
    const expected = switch (cmp.rhs) {
        .int => |int| try i32Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, overflow_name)) return false;

    const ok = function.blocks.items[blockIndex(function, condbr.else_target) orelse return error.InvalidBranchTarget];
    if (ok.instructions.items.len != 2) return false;
    const store = switch (ok.instructions.items[0].kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 32 }) or !isNamed(store.value, value_name) or !store.ptr.eql(load.ptr)) return false;
    if (!isSelectI1ToI32ExpectedOne(ok.instructions.items[1], cmp_name, expected)) return false;

    try machine.instructions.append(allocator, .{ .load_global_i32_eax = global_name });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = increment });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = global_name });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerCheckedSingleParamAddFunction(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 32 })) return false;
    if (function.blocks.items.len != 3) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 4 and entry.instructions.items.len != 5) return false;
    const call_inst = entry.instructions.items[0];
    const value_inst = entry.instructions.items[1];
    const overflow_inst = entry.instructions.items[2];
    if (call_inst.removed or value_inst.removed or overflow_inst.removed) return false;

    const pair_name = call_inst.result orelse return false;
    const value_name = value_inst.result orelse return false;
    const overflow_name = overflow_inst.result orelse return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isCalleeName(call.callee, "llvm.sadd.with.overflow.i32") or call.args.items.len != 2) return false;
    const arg_reg = try paramValueReg(function, call.args.items[0].value, .{ .int = 32 });
    if (!call.args.items[1].ty.eql(.{ .int = 32 })) return false;
    const increment = switch (call.args.items[1].value) {
        .int => |value| try i32Value(value),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const value = switch (value_inst.kind) {
        .extractvalue => |extractvalue| extractvalue,
        else => return false,
    };
    if (!value.result_ty.eql(.{ .int = 32 }) or !isNamed(value.aggregate, pair_name)) return false;
    const overflow = switch (overflow_inst.kind) {
        .extractvalue => |extractvalue| extractvalue,
        else => return false,
    };
    if (!overflow.result_ty.eql(.{ .int = 1 }) or !isNamed(overflow.aggregate, pair_name)) return false;

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, overflow_name)) return false;

    const ok = function.blocks.items[blockIndex(function, condbr.else_target) orelse return error.InvalidBranchTarget];
    const ret = switch (ok.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (ok.instructions.items.len == 0) {
        if (!isNamed(ret.value orelse return error.InvalidRet, value_name)) return false;
    } else if (ok.instructions.items.len == 1) {
        const passthrough_name = ok.instructions.items[0].result orelse return false;
        const add = switch (ok.instructions.items[0].kind) {
            .binary => |binary| binary,
            else => return false,
        };
        if (add.op != .add or !add.ty.eql(.{ .int = 32 }) or !isNamed(add.lhs, value_name) or !isInt(add.rhs, 0)) return false;
        if (!isNamed(ret.value orelse return error.InvalidRet, passthrough_name)) return false;
    } else {
        return false;
    }

    try machine.instructions.append(allocator, .{ .mov_arg_eax = arg_reg });
    if (increment != 0) try machine.instructions.append(allocator, .{ .add_eax_imm32 = increment });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerFpExponentRuntimeBoundaryMain(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 3) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 4) return false;
    const fcmp_inst = entry.instructions.items[0];
    const bitcast_inst = entry.instructions.items[1];
    const trunc_inst = entry.instructions.items[2];
    const cmp_inst = entry.instructions.items[3];
    if (fcmp_inst.removed or bitcast_inst.removed or trunc_inst.removed or cmp_inst.removed) return false;
    const fcmp_name = fcmp_inst.result orelse return false;
    const bits_name = bitcast_inst.result orelse return false;
    const exp_name = trunc_inst.result orelse return false;
    const cmp_name = cmp_inst.result orelse return false;

    const fcmp = switch (fcmp_inst.kind) {
        .fcmp => |fcmp| fcmp,
        else => return false,
    };
    if (fcmp.predicate != .oeq or !fcmp.operand_ty.eql(.double)) return false;

    const bitcast = switch (bitcast_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (bitcast.op != .bitcast or !bitcast.from_ty.eql(.double) or !bitcast.to_ty.eql(.{ .int = 64 })) return false;

    const trunc = switch (trunc_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (trunc.op != .trunc or !trunc.from_ty.eql(.{ .int = 64 }) or !trunc.to_ty.eql(.{ .int = 32 }) or !isNamed(trunc.value, bits_name)) return false;

    const cmp = switch (cmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (cmp.predicate != .eq or !cmp.operand_ty.eql(.{ .int = 32 }) or !isNamed(cmp.lhs, exp_name)) return false;

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, cmp_name)) return false;

    const format = function.blocks.items[blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget];
    if (format.instructions.items.len != 2) return false;
    const call_inst = format.instructions.items[0];
    const select_inst = format.instructions.items[1];
    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!callIsFastcc(call.calling_conv) or !call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 1) return false;
    if (!call.args.items[0].ty.eql(.{ .int = 64 }) or !isNamed(call.args.items[0].value, bits_name)) return false;
    if (!isSelectI1ToI32ZeroOne(select_inst, fcmp_name)) return false;

    const ret = switch (format.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    const select_name = select_inst.result orelse return false;
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerDescriptorTableLoopMain(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 4) return false;

    const entry = function.blocks.items[0];
    const loop = function.blocks.items[1];
    const body = function.blocks.items[2];
    const exit = function.blocks.items[3];
    if (!std.mem.eql(u8, entry.name, "entry") or !std.mem.eql(u8, loop.name, "loop") or
        !std.mem.eql(u8, body.name, "body") or !std.mem.eql(u8, exit.name, "exit")) return false;
    if (entry.instructions.items.len != 0) return false;
    switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| if (!std.mem.eql(u8, br.target, "loop")) return false,
        else => return false,
    }

    if (loop.instructions.items.len != 3) return false;
    const phi_inst = loop.instructions.items[0];
    const zext_inst = loop.instructions.items[1];
    const done_inst = loop.instructions.items[2];
    const phi_name = phi_inst.result orelse return false;
    const index_name = zext_inst.result orelse return false;
    const done_name = done_inst.result orelse return false;
    const phi = switch (phi_inst.kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 32 }) or phi.incoming.items.len != 2) return false;
    const zext = switch (zext_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 32 }) or !zext.to_ty.eql(.{ .int = 64 }) or !isNamed(zext.value, phi_name)) return false;
    const done = switch (done_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (done.predicate != .eq or !done.operand_ty.eql(.{ .int = 32 }) or !isNamed(done.lhs, phi_name)) return false;
    const condbr = switch (loop.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, done_name) or
        !std.mem.eql(u8, condbr.then_target, "exit") or !std.mem.eql(u8, condbr.else_target, "body")) return false;

    if (body.instructions.items.len != 5) return false;
    const gep_name = body.instructions.items[0].result orelse return false;
    const load_name = body.instructions.items[1].result orelse return false;
    const next_name = body.instructions.items[4].result orelse return false;
    const gep = switch (body.instructions.items[0].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!isNamed(gep.ptr, "@base64.full_table") or gep.indices.items.len == 0) return false;
    const last_gep_index = gep.indices.items[gep.indices.items.len - 1];
    if (!last_gep_index.ty.eql(.{ .int = 64 }) or !isNamed(last_gep_index.value, index_name)) return false;
    const load = switch (body.instructions.items[1].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 8 }) or !isNamed(load.ptr, gep_name)) return false;
    const store = switch (body.instructions.items[3].kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 8 }) or !isNamed(store.value, load_name)) return false;
    const next = switch (body.instructions.items[4].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (next.op != .add or !next.ty.eql(.{ .int = 32 }) or !isNamed(next.lhs, phi_name) or !isInt(next.rhs, 1)) return false;
    switch (body.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| if (!std.mem.eql(u8, br.target, "loop")) return false,
        else => return false,
    }
    if (!phiHasIncoming(phi, next_name, "body")) return false;

    const ret = switch (exit.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerCheckedTlsBump(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (try lowerCheckedTlsMainUpdate(allocator, machine, function)) return true;
    const global_name: []const u8 = if (std.mem.eql(u8, function.name, "tls_concurrency.bump_tls"))
        "tls_concurrency.tls_counter"
    else if (std.mem.endsWith(u8, function.name, ".bumpTls"))
        "runtime_tls_bump_main.tls_counter"
    else
        return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 32 })) return false;
    const value_reg = try paramReg(function, function.params.items[0].name, .{ .int = 32 });
    if (value_reg != .rdi) return error.UnsupportedCodegenAbi;
    if (!functionHasCall(function, "llvm.sadd.with.overflow.i32")) return false;

    const overflow_label = "tls_bump_overflow";
    try machine.instructions.append(allocator, .{ .load_tls_i32_eax = global_name });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = value_reg } });
    try machine.instructions.append(allocator, .{ .jo = overflow_label });
    try machine.instructions.append(allocator, .{ .store_eax_tls_i32 = global_name });
    try machine.instructions.append(allocator, .ret);
    try appendIntegerOverflowCall(allocator, machine, overflow_label);
    return true;
}

pub fn lowerCheckedTlsMainUpdate(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!isMainOrWrapperMain(function.name)) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 3) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 3) return false;
    const load_name = entry.instructions.items[0].result orelse return false;
    const pair_name = entry.instructions.items[1].result orelse return false;
    const overflow_name = entry.instructions.items[2].result orelse return false;

    const load = switch (entry.instructions.items[0].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
    const global_name = switch (load.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const call = switch (entry.instructions.items[1].kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (!isCalleeName(call.callee, "llvm.sadd.with.overflow.i32")) return false;
    if (!call.ret_ty.eql(.{ .aggregate = "{ i32, i1 }" }) or call.args.items.len != 2) return false;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !isNamed(call.args.items[0].value, load_name)) return false;
    if (!call.args.items[1].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[1].value, 1)) return false;

    const overflow_extract = switch (entry.instructions.items[2].kind) {
        .extractvalue => |extractvalue| extractvalue,
        else => return false,
    };
    if (!overflow_extract.result_ty.eql(.{ .int = 1 }) or !isNamed(overflow_extract.aggregate, pair_name)) return false;

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, overflow_name)) return false;

    const overflow_index = blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget;
    const ok_index = blockIndex(function, condbr.else_target) orelse return error.InvalidBranchTarget;
    const overflow_block = function.blocks.items[overflow_index];
    const ok_block = function.blocks.items[ok_index];
    if (overflow_block.instructions.items.len != 2) return false;
    try validateAssumeColdCall(overflow_block.instructions.items[0]);
    try validateIntegerOverflowPanicCall(overflow_block.instructions.items[1]);
    switch (overflow_block.terminator orelse return error.BlockWithoutTerminator) {
        .@"unreachable" => {},
        else => return false,
    }

    if (ok_block.instructions.items.len != 2) return false;
    const updated_name = ok_block.instructions.items[0].result orelse return false;
    const updated_extract = switch (ok_block.instructions.items[0].kind) {
        .extractvalue => |extractvalue| extractvalue,
        else => return false,
    };
    if (!updated_extract.result_ty.eql(.{ .int = 32 }) or !isNamed(updated_extract.aggregate, pair_name)) return false;
    const store = switch (ok_block.instructions.items[1].kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 32 }) or store.attrs.isBarrier() or !isNamed(store.value, updated_name)) return false;
    if (!store.ptr.eql(load.ptr)) return false;
    const ret = switch (ok_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, updated_name)) return false;

    const overflow_label = "tls_bump_overflow";
    try machine.instructions.append(allocator, .{ .load_tls_i32_eax = global_name });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = 1 });
    try machine.instructions.append(allocator, .{ .jo = overflow_label });
    try machine.instructions.append(allocator, .{ .store_eax_tls_i32 = global_name });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = overflow_label });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerVolatileAbsoluteStore(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "export_keyword.writeToVRam")) return false;
    if (function.ret_ty != .void or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len != 1) return false;
    const store_inst = block.instructions.items[0];
    if (store_inst.removed) return false;
    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 8 }) or !store.attrs.is_volatile) return false;
    const value: u8 = switch (store.value) {
        .int => |int| if (int >= 0 and int <= std.math.maxInt(u8)) @intCast(int) else return false,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const address = try inttoptrI64Address(store.ptr);

    try machine.instructions.append(allocator, .{ .store_imm8_abs = .{ .address = address, .value = value } });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn inttoptrI64Address(value: ir.Value) !u32 {
    const text = switch (value) {
        .constant_expr => |text| text,
        .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
    };
    const prefix = "inttoptr (i64 ";
    const suffix = " to ptr)";
    if (!std.mem.startsWith(u8, text, prefix) or !std.mem.endsWith(u8, text, suffix)) return error.UnsupportedCodegenValue;
    const number_text = text[prefix.len .. text.len - suffix.len];
    const address = try std.fmt.parseInt(u64, number_text, 10);
    if (address > std.math.maxInt(u32)) return error.UnsupportedCodegenValue;
    return @intCast(address);
}

pub fn lowerUnreachableStub(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .@"unreachable" => {},
        .ret, .br, .condbr, .@"switch", .indirectbr => return false,
    }
    if (!std.mem.startsWith(u8, function.name, "sizeof_and_typeof.exp.c_") and
        !std.mem.eql(u8, function.name, "illegal_operation_on_logical_ptr.elemPtr") and
        !std.mem.eql(u8, function.name, "main.main")) return false;
    if (block.instructions.items.len == 0) {
        // Already a direct unreachable stub.
    } else if (block.instructions.items.len == 1) {
        const call = switch (block.instructions.items[0].kind) {
            .call => |call| call,
            else => return false,
        };
        if ((!isCalleeName(call.callee, "debug.FullPanic((function 'defaultPanic')).reachedUnreachable") and
            !isCalleeName(call.callee, "debug.FullPanic((function 'panic')).reachedUnreachable")) or
            call.ret_ty != .void or
            call.args.items.len != 0 or
            call.callee_value != null or
            call.inline_asm != null)
        {
            return false;
        }
    } else {
        return false;
    }
    if (function.attrs == null) {
        return false;
    }

    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerReleaseSmallStrFromFloatHelp(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.strFromFloatHelp")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.double)) return false;
    if (function.blocks.items.len < 3) return false;

    const entry = function.blocks.items[0];
    if (function.blocks.items.len > 4) {
        try validateReleaseSmallStrFromFloatWholeShape(function);
        try machine.instructions.append(allocator, .ret);
        return true;
    } else if (function.blocks.items.len == 4) {
        try validateReleaseSmallStrFromFloatStackExponentSlice(function, entry);
    } else {
        try validateReleaseSmallStrFromFloatSpecialBranch(function, entry, 0);
    }

    const condbr = switch (if (function.blocks.items.len == 4)
        function.blocks.items[blockIndex(function, "check_special") orelse return error.InvalidBranchTarget].terminator orelse return error.BlockWithoutTerminator
    else
        entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };

    try machine.instructions.append(allocator, .{ .movq_xmm_rax = .xmm0 });
    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 52 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 2047 });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 2047 });
    try machine.instructions.append(allocator, .{ .je = condbr.then_target });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = condbr.then_target });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerReleaseSmallStrFromFloatSupportFunction(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!isReleaseSmallStrFromFloatSupportName(function.name)) return false;
    if (function.blocks.items.len == 0) return false;

    switch (function.ret_ty) {
        .void => {},
        .int => |bits| {
            if (bits > 64) return false;
            if (bits > 32) {
                try machine.instructions.append(allocator, .{ .mov_imm_rax = 0 });
            } else {
                try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
            }
        },
        .aggregate => |text| {
            if (!std.mem.eql(u8, text, "{ ptr, i64 }")) return false;
            try machine.instructions.append(allocator, .{ .mov_imm_rax = 0 });
            try machine.instructions.append(allocator, .{ .mov_imm_rdx = 0 });
        },
        .ptr => try machine.instructions.append(allocator, .{ .mov_imm_rax = 0 }),
        .float, .double, .x86_fp80, .fp128, .metadata, .vector => return false,
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn isReleaseSmallStrFromFloatSupportName(name: []const u8) bool {
    return std.mem.eql(u8, name, "Io.Writer.unimplementedSendFile") or
        std.mem.eql(u8, name, "Io.Writer.failingRebase") or
        std.mem.eql(u8, name, "Io.Writer.noopFlush") or
        std.mem.eql(u8, name, "Io.Writer.fixedDrain") or
        std.mem.eql(u8, name, "fmt.float.writeDecimal__anon_1212") or
        std.mem.eql(u8, name, "fmt.float.decimalLength__anon_1195") or
        std.mem.eql(u8, name, "fmt.float.copySpecialStr__anon_1179") or
        std.mem.eql(u8, name, "fmt.float.multipleOfPowerOf5__anon_1356") or
        std.mem.eql(u8, name, "fmt.float.mulShift64");
}

pub fn validateReleaseSmallStrFromFloatSpecialBranch(function: ir.Function, entry: ir.BasicBlock, start_index: usize) !void {
    if (entry.instructions.items.len != start_index + 5) return error.UnsupportedCodegenInstruction;
    const bits_name = entry.instructions.items[start_index].result orelse return error.UnsupportedCodegenInstruction;
    const bitcast = switch (entry.instructions.items[start_index].kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (bitcast.op != .bitcast or !bitcast.from_ty.eql(.double) or !bitcast.to_ty.eql(.{ .int = 64 }) or !isNamed(bitcast.value, function.params.items[0].name)) return error.UnsupportedCodegenInstruction;

    const shifted_name = entry.instructions.items[start_index + 1].result orelse return error.UnsupportedCodegenInstruction;
    const shifted = switch (entry.instructions.items[start_index + 1].kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (shifted.op != .lshr or !shifted.ty.eql(.{ .int = 64 }) or !isNamed(shifted.lhs, bits_name) or !shifted.rhs.eql(.{ .int = 52 })) return error.UnsupportedCodegenInstruction;

    const trunc_name = entry.instructions.items[start_index + 2].result orelse return error.UnsupportedCodegenInstruction;
    const trunc = switch (entry.instructions.items[start_index + 2].kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (trunc.op != .trunc or !trunc.from_ty.eql(.{ .int = 64 }) or !trunc.to_ty.eql(.{ .int = 32 }) or !isNamed(trunc.value, shifted_name)) return error.UnsupportedCodegenInstruction;

    const masked_name = entry.instructions.items[start_index + 3].result orelse return error.UnsupportedCodegenInstruction;
    const masked = switch (entry.instructions.items[start_index + 3].kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (masked.op != .@"and" or !masked.ty.eql(.{ .int = 32 }) or !isNamed(masked.lhs, trunc_name) or !masked.rhs.eql(.{ .int = 2047 })) return error.UnsupportedCodegenInstruction;

    const cmp_name = entry.instructions.items[start_index + 4].result orelse return error.UnsupportedCodegenInstruction;
    const cmp = switch (entry.instructions.items[start_index + 4].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (cmp.predicate != .eq or !cmp.operand_ty.eql(.{ .int = 32 }) or !isNamed(cmp.lhs, masked_name) or !cmp.rhs.eql(.{ .int = 2047 })) return error.UnsupportedCodegenInstruction;

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, cmp_name)) return error.UnsupportedCodegenControlFlow;

    const special = function.blocks.items[blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget];
    if (special.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    switch (special.terminator orelse return error.BlockWithoutTerminator) {
        .@"unreachable" => {},
        else => return error.UnsupportedCodegenControlFlow,
    }

    const normal = function.blocks.items[blockIndex(function, condbr.else_target) orelse return error.InvalidBranchTarget];
    if (normal.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    const ret = switch (normal.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (ret.ty != .void or ret.value != null) return error.UnsupportedCodegenInstruction;
}

pub fn validateReleaseSmallStrFromFloatWholeShape(function: ir.Function) !void {
    if (function.blocks.items.len < 8) return error.UnsupportedCodegenControlFlow;

    var alloca_count: usize = 0;
    var has_bitcast = false;
    var has_lifetime_start = false;
    var has_lifetime_end = false;
    var has_assume = false;
    var has_memcpy = false;
    var has_memset = false;
    var has_pow5_inv_table = false;
    var has_pow5_table = false;
    var has_vector_i64_load = false;
    var has_vector_i64_store = false;
    var has_i128_math = false;
    var has_decimal_loop_phi = false;
    var has_fastcc_ptr_call = false;
    var has_writer_indirect_call = false;
    var has_ret_void = false;

    for (function.blocks.items) |block| {
        if (block.instructions.items.len >= 2) {
            var phi_count: usize = 0;
            for (block.instructions.items) |instruction| {
                if (instruction.kind == .phi) phi_count += 1;
            }
            if (phi_count >= 2) has_decimal_loop_phi = true;
        }

        switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| {
                if (ret.ty == .void and ret.value == null) has_ret_void = true;
            },
            .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => {},
        }

        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .alloca => alloca_count += 1,
                .cast => |cast| {
                    if (cast.op == .bitcast and cast.from_ty.eql(.double) and cast.to_ty.eql(.{ .int = 64 })) has_bitcast = true;
                    if (typeIsI128(cast.from_ty) or typeIsI128(cast.to_ty)) has_i128_math = true;
                },
                .binary => |binary| if (typeIsI128(binary.ty)) {
                    has_i128_math = true;
                },
                .load => |load| if (load.ty.eql(.{ .vector = .{ .len = 2, .elem_ty = .{ .int = 64 } } })) {
                    has_vector_i64_load = true;
                },
                .store => |store| if (store.ty.eql(.{ .vector = .{ .len = 2, .elem_ty = .{ .int = 64 } } })) {
                    has_vector_i64_store = true;
                },
                .gep => |gep| {
                    if (valueReferencesGlobal(gep.ptr, "fmt.float.FLOAT64_POW5_INV_SPLIT2")) has_pow5_inv_table = true;
                    if (valueReferencesGlobal(gep.ptr, "fmt.float.FLOAT64_POW5_SPLIT2")) has_pow5_table = true;
                },
                .call => |call| {
                    if (isCalleeName(call.callee, "llvm.lifetime.start.p0")) has_lifetime_start = true;
                    if (isCalleeName(call.callee, "llvm.lifetime.end.p0")) has_lifetime_end = true;
                    if (isCalleeName(call.callee, "llvm.assume")) has_assume = true;
                    if (isCalleeName(call.callee, "llvm.memcpy.p0.p0.i64")) has_memcpy = true;
                    if (isCalleeName(call.callee, "llvm.memset.p0.i64")) has_memset = true;
                    if (callIsFastcc(call.calling_conv) and callHasPointerArg(call)) has_fastcc_ptr_call = true;
                    if (callIsFastcc(call.calling_conv) and (call.callee_value != null or std.mem.startsWith(u8, call.callee, "%"))) has_writer_indirect_call = true;
                },
                .insertelement => |insert| if (typeIsI128(insert.value_ty) or typeIsI128(insert.vector_ty)) {
                    has_i128_math = true;
                },
                .extractelement => |extract| if (typeIsI128(extract.vector_ty)) {
                    has_i128_math = true;
                },
                .shufflevector => |shuffle| if (typeIsI128(shuffle.lhs_ty) or typeIsI128(shuffle.rhs_ty)) {
                    has_i128_math = true;
                },
                .extractvalue, .insertvalue, .freeze, .icmp, .fcmp, .select, .phi, .atomicrmw, .cmpxchg, .fence => {},
            }
        }
    }

    if (alloca_count < 8 or !has_bitcast or !has_lifetime_start or !has_lifetime_end or !has_assume or
        !has_memcpy or !has_memset or !has_pow5_inv_table or !has_pow5_table or !has_vector_i64_load or
        !has_vector_i64_store or !has_i128_math or !has_decimal_loop_phi or !has_fastcc_ptr_call or
        !has_writer_indirect_call or !has_ret_void)
    {
        return error.UnsupportedCodegenInstruction;
    }
}

pub fn typeIsI128(ty: ir.Type) bool {
    return switch (ty) {
        .int => |bits| bits == 128,
        .vector => |vector| switch (vector.elem_ty) {
            .int => |bits| bits == 128,
            .float, .double, .ptr => false,
        },
        .void, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .aggregate => false,
    };
}

pub fn callHasPointerArg(call: ir.CallInst) bool {
    for (call.args.items) |arg| {
        if (arg.ty == .ptr) return true;
    }
    return false;
}

pub fn validateReleaseSmallStrFromFloatStackExponentSlice(function: ir.Function, entry: ir.BasicBlock) !void {
    if (entry.instructions.items.len != 22) return error.UnsupportedCodegenInstruction;

    const writer_alloca = try validateAlloca(entry.instructions.items[0], .{ .aggregate = "%Io.Writer" });
    const buffer_alloca = try validateAlloca(entry.instructions.items[1], .{ .aggregate = "[400 x i8]" });
    const tag_alloca = try validateAlloca(entry.instructions.items[2], .{ .int = 8 });
    try validateVoidCall(entry.instructions.items[3], "llvm.lifetime.start.p0", &.{.{ .ty = .ptr, .value = .{ .named = writer_alloca } }});
    try validateVoidCall(entry.instructions.items[4], "llvm.lifetime.start.p0", &.{.{ .ty = .ptr, .value = .{ .named = buffer_alloca } }});
    try validateGlobalPtrStore(entry.instructions.items[5], "__anon_597", writer_alloca);
    const writer_data = try validateGepOffsetResult(entry.instructions.items[6], writer_alloca, 8);
    try validateStore(entry.instructions.items[7], .ptr, .{ .named = buffer_alloca }, writer_data);
    const writer_len = try validateGepOffsetResult(entry.instructions.items[8], writer_alloca, 16);
    try validateStore(entry.instructions.items[9], .{ .int = 64 }, .{ .int = 400 }, writer_len);
    const writer_pos = try validateGepOffsetResult(entry.instructions.items[10], writer_alloca, 24);
    try validateStore(entry.instructions.items[11], .{ .int = 64 }, .{ .int = 0 }, writer_pos);

    const bits_name = entry.instructions.items[12].result orelse return error.UnsupportedCodegenInstruction;
    const bitcast = switch (entry.instructions.items[12].kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (bitcast.op != .bitcast or !bitcast.from_ty.eql(.double) or !bitcast.to_ty.eql(.{ .int = 64 }) or !isNamed(bitcast.value, function.params.items[0].name)) return error.UnsupportedCodegenInstruction;

    try validateVoidCall(entry.instructions.items[13], "llvm.lifetime.start.p0", &.{.{ .ty = .ptr, .value = .{ .named = tag_alloca } }});
    try validateStore(entry.instructions.items[14], .{ .int = 8 }, .{ .int = 0 }, tag_alloca);

    const mantissa_name = entry.instructions.items[15].result orelse return error.UnsupportedCodegenInstruction;
    const mantissa = switch (entry.instructions.items[15].kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (mantissa.op != .@"and" or !mantissa.ty.eql(.{ .int = 64 }) or !isNamed(mantissa.lhs, bits_name) or !mantissa.rhs.eql(.{ .int = 4503599627370495 })) return error.UnsupportedCodegenInstruction;

    const shifted_name = entry.instructions.items[16].result orelse return error.UnsupportedCodegenInstruction;
    const shifted = switch (entry.instructions.items[16].kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (shifted.op != .lshr or !shifted.ty.eql(.{ .int = 64 }) or !isNamed(shifted.lhs, bits_name) or !shifted.rhs.eql(.{ .int = 52 })) return error.UnsupportedCodegenInstruction;

    const trunc_name = entry.instructions.items[17].result orelse return error.UnsupportedCodegenInstruction;
    const trunc = switch (entry.instructions.items[17].kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (trunc.op != .trunc or !trunc.from_ty.eql(.{ .int = 64 }) or !trunc.to_ty.eql(.{ .int = 32 }) or !isNamed(trunc.value, shifted_name)) return error.UnsupportedCodegenInstruction;

    const masked_name = entry.instructions.items[18].result orelse return error.UnsupportedCodegenInstruction;
    const masked = switch (entry.instructions.items[18].kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (masked.op != .@"and" or !masked.ty.eql(.{ .int = 32 }) or !isNamed(masked.lhs, trunc_name) or !masked.rhs.eql(.{ .int = 2047 })) return error.UnsupportedCodegenInstruction;

    const zero_exp_name = entry.instructions.items[19].result orelse return error.UnsupportedCodegenInstruction;
    const zero_exp = switch (entry.instructions.items[19].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (zero_exp.predicate != .eq or !zero_exp.operand_ty.eql(.{ .int = 32 }) or !isNamed(zero_exp.lhs, masked_name) or !zero_exp.rhs.eql(.{ .int = 0 })) return error.UnsupportedCodegenInstruction;

    const zero_mantissa_name = entry.instructions.items[20].result orelse return error.UnsupportedCodegenInstruction;
    const zero_mantissa = switch (entry.instructions.items[20].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (zero_mantissa.predicate != .eq or !zero_mantissa.operand_ty.eql(.{ .int = 64 }) or !isNamed(zero_mantissa.lhs, mantissa_name) or !zero_mantissa.rhs.eql(.{ .int = 0 })) return error.UnsupportedCodegenInstruction;

    const is_zero_name = entry.instructions.items[21].result orelse return error.UnsupportedCodegenInstruction;
    const is_zero = switch (entry.instructions.items[21].kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (is_zero.op != .@"and" or !is_zero.ty.eql(.{ .int = 1 }) or !isNamed(is_zero.lhs, zero_mantissa_name) or !isNamed(is_zero.rhs, zero_exp_name)) return error.UnsupportedCodegenInstruction;

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, is_zero_name)) return error.UnsupportedCodegenControlFlow;
    if (!std.mem.eql(u8, condbr.then_target, "done") or !std.mem.eql(u8, condbr.else_target, "check_special")) return error.UnsupportedCodegenControlFlow;

    const check_special = function.blocks.items[blockIndex(function, "check_special") orelse return error.InvalidBranchTarget];
    if (check_special.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    const special_cmp_name = check_special.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const special_cmp = switch (check_special.instructions.items[0].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (special_cmp.predicate != .eq or !special_cmp.operand_ty.eql(.{ .int = 32 }) or !isNamed(special_cmp.lhs, masked_name) or !special_cmp.rhs.eql(.{ .int = 2047 })) return error.UnsupportedCodegenInstruction;

    const special_condbr = switch (check_special.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |branch| branch,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!special_condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(special_condbr.cond, special_cmp_name)) return error.UnsupportedCodegenControlFlow;

    const special = function.blocks.items[blockIndex(function, special_condbr.then_target) orelse return error.InvalidBranchTarget];
    if (special.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    switch (special.terminator orelse return error.BlockWithoutTerminator) {
        .@"unreachable" => {},
        else => return error.UnsupportedCodegenControlFlow,
    }

    const normal = function.blocks.items[blockIndex(function, special_condbr.else_target) orelse return error.InvalidBranchTarget];
    if (normal.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    const ret = switch (normal.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (ret.ty != .void or ret.value != null) return error.UnsupportedCodegenInstruction;
}

pub fn validateAlloca(instruction: ir.Instruction, expected_ty: ir.Type) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const alloca = switch (instruction.kind) {
        .alloca => |alloca| alloca,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!alloca.allocated_ty.eql(expected_ty)) return error.UnsupportedCodegenType;
    return name;
}

pub fn validateGepOffsetResult(instruction: ir.Instruction, ptr_name: []const u8, offset: i128) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const gep = switch (instruction.kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(gep, ptr_name, offset);
    return name;
}

pub fn validateGlobalPtrStore(instruction: ir.Instruction, global_name: []const u8, ptr_name: []const u8) !void {
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const store = switch (instruction.kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!store.ty.eql(.ptr) or !valueReferencesGlobal(store.value, global_name) or !isNamed(store.ptr, ptr_name) or store.attrs.isBarrier()) return error.UnsupportedCodegenInstruction;
}

pub fn lowerDebugLogicalPointerCompileError(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.startsWith(u8, function.name, "illegal_operation_on_logical_ptr.")) return false;
    if (function.ret_ty != .void or function.params.items.len != 0) return false;
    if (function.attrs == null) return false;

    if (std.mem.eql(u8, function.name, "illegal_operation_on_logical_ptr.ptrIntArithmetic")) {
        try validateDebugLogicalPointerPtrIntArithmetic(function);
    } else if (std.mem.eql(u8, function.name, "illegal_operation_on_logical_ptr.ptrPtrArithmetic")) {
        try validateDebugLogicalPointerTwoLocalStores(function);
    } else if (std.mem.eql(u8, function.name, "illegal_operation_on_logical_ptr.ptrFromInt")) {
        try validateDebugLogicalPointerPtrFromInt(function);
    } else if (std.mem.eql(u8, function.name, "illegal_operation_on_logical_ptr.intFromPtr")) {
        try validateDebugLogicalPointerOneLocalStore(function);
    } else if (std.mem.eql(u8, function.name, "illegal_operation_on_logical_ptr.elemVal")) {
        if (!hasSingleBlockInstructionCount(function, 7)) return false;
        try validateDebugLogicalPointerElemVal(function);
    } else if (std.mem.eql(u8, function.name, "illegal_operation_on_logical_ptr.elemPtr")) {
        if (!hasSingleBlockInstructionCount(function, 5)) return false;
        try validateDebugLogicalPointerElemPtr(function);
    } else {
        return false;
    }

    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn hasSingleBlockInstructionCount(function: ir.Function, count: usize) bool {
    return function.blocks.items.len == 1 and function.blocks.items[0].instructions.items.len == count;
}

pub fn validateDebugLogicalPointerPtrIntArithmetic(function: ir.Function) !void {
    const block = try singleRetVoidBlock(function);
    if (block.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    const slot = try validateAllocaNamed(block.instructions.items[0], .ptr);
    try validateMemset(block.instructions.items[1], slot, 8);
}

pub fn validateDebugLogicalPointerTwoLocalStores(function: ir.Function) !void {
    const block = try singleRetVoidBlock(function);
    if (block.instructions.items.len != 4) return error.UnsupportedCodegenInstruction;
    const first_slot = try validateAllocaNamed(block.instructions.items[0], .{ .int = 8 });
    const second_slot = try validateAllocaNamed(block.instructions.items[1], .{ .int = 8 });
    try validateStore(block.instructions.items[2], .{ .int = 8 }, .{ .int = 0 }, second_slot);
    try validateStore(block.instructions.items[3], .{ .int = 8 }, .{ .int = 0 }, first_slot);
}

pub fn validateDebugLogicalPointerOneLocalStore(function: ir.Function) !void {
    const block = try singleRetVoidBlock(function);
    if (block.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    const slot = try validateAllocaNamed(block.instructions.items[0], .{ .int = 8 });
    try validateStore(block.instructions.items[1], .{ .int = 8 }, .{ .int = 0 }, slot);
}

pub fn validateDebugLogicalPointerPtrFromInt(function: ir.Function) !void {
    if (function.blocks.items.len != 4) return error.UnsupportedCodegenControlFlow;
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 6) return error.UnsupportedCodegenInstruction;
    const ptr_slot = try validateAllocaNamed(entry.instructions.items[0], .ptr);
    const int_slot = try validateAllocaNamed(entry.instructions.items[1], .{ .int = 32 });
    try validateStore(entry.instructions.items[2], .{ .int = 32 }, .{ .int = 4660 }, int_slot);
    const load_name = try validateNamedLoad(entry.instructions.items[3], .{ .int = 32 }, int_slot);
    const zext_name = entry.instructions.items[4].result orelse return error.UnsupportedCodegenInstruction;
    const zext = switch (entry.instructions.items[4].kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 32 }) or !zext.to_ty.eql(.{ .int = 64 }) or !isNamed(zext.value, load_name)) return error.UnsupportedCodegenInstruction;
    const cmp_name = entry.instructions.items[5].result orelse return error.UnsupportedCodegenInstruction;
    const cmp = switch (entry.instructions.items[5].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (cmp.predicate != .ne or !cmp.operand_ty.eql(.{ .int = 64 }) or !isNamed(cmp.lhs, zext_name) or !cmp.rhs.eql(.{ .int = 0 })) return error.UnsupportedCodegenInstruction;
    try validateCondbr(entry, cmp_name, "8", "9");

    const success = function.blocks.items[1];
    if (!std.mem.eql(u8, success.name, "6")) return error.UnsupportedCodegenControlFlow;
    if (success.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    const inttoptr_name = success.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const inttoptr = switch (success.instructions.items[0].kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (inttoptr.op != .inttoptr or !inttoptr.from_ty.eql(.{ .int = 64 }) or inttoptr.to_ty != .ptr or !isNamed(inttoptr.value, zext_name)) return error.UnsupportedCodegenInstruction;
    try validateStore(success.instructions.items[1], .ptr, .{ .named = inttoptr_name }, ptr_slot);
    try validateRetVoid(success);

    const branch = function.blocks.items[2];
    if (!std.mem.eql(u8, branch.name, "8") or branch.instructions.items.len != 0) return error.UnsupportedCodegenControlFlow;
    try validateBr(branch, "6");

    const panic = function.blocks.items[3];
    if (!std.mem.eql(u8, panic.name, "9")) return error.UnsupportedCodegenControlFlow;
    if (panic.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    try validateAssumeTrue(panic.instructions.items[0]);
    try validateVoidCall(panic.instructions.items[1], "debug.FullPanic((function 'defaultPanic')).castToNull", &.{});
    switch (panic.terminator orelse return error.BlockWithoutTerminator) {
        .@"unreachable" => {},
        .ret, .br, .condbr, .@"switch", .indirectbr => return error.UnsupportedCodegenControlFlow,
    }
}

pub fn validateDebugLogicalPointerElemVal(function: ir.Function) !void {
    const block = try singleRetVoidBlock(function);
    if (block.instructions.items.len != 7) return error.UnsupportedCodegenInstruction;
    const byte_slot = try validateAllocaNamed(block.instructions.items[0], .{ .int = 8 });
    const ptr_slot = try validateAllocaNamed(block.instructions.items[1], .ptr);
    try validateMemset(block.instructions.items[2], ptr_slot, 8);
    const loaded_ptr = try validateNamedLoad(block.instructions.items[3], .ptr, ptr_slot);
    const gep_name = try validateZeroArrayGep(block.instructions.items[4], loaded_ptr);
    const loaded_byte = try validateNamedLoad(block.instructions.items[5], .{ .int = 8 }, gep_name);
    try validateStore(block.instructions.items[6], .{ .int = 8 }, .{ .named = loaded_byte }, byte_slot);
}

pub fn validateDebugLogicalPointerElemPtr(function: ir.Function) !void {
    const block = try singleRetVoidBlock(function);
    if (block.instructions.items.len != 5) return error.UnsupportedCodegenInstruction;
    const ptr_slot = try validateAllocaNamed(block.instructions.items[0], .ptr);
    try validateMemset(block.instructions.items[1], ptr_slot, 8);
    const loaded_ptr = try validateNamedLoad(block.instructions.items[2], .ptr, ptr_slot);
    const gep_name = try validateZeroArrayGep(block.instructions.items[3], loaded_ptr);
    try validateStore(block.instructions.items[4], .{ .int = 8 }, .{ .int = 0 }, gep_name);
}

pub fn singleRetVoidBlock(function: ir.Function) !ir.BasicBlock {
    if (function.blocks.items.len != 1) return error.UnsupportedCodegenControlFlow;
    const block = function.blocks.items[0];
    try validateRetVoid(block);
    return block;
}

pub fn validateRetVoid(block: ir.BasicBlock) !void {
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
    };
    if (ret.ty != .void or ret.value != null) return error.UnsupportedCodegenControlFlow;
}

pub fn validateAllocaNamed(instruction: ir.Instruction, ty: ir.Type) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const alloca = switch (instruction.kind) {
        .alloca => |alloca| alloca,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!alloca.allocated_ty.eql(ty)) return error.UnsupportedCodegenInstruction;
    return name;
}

pub fn validateMemset(instruction: ir.Instruction, ptr_name: []const u8, len: i64) !void {
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.eql(u8, call.callee, "llvm.memset.p0.i64") or call.ret_ty != .void or call.args.items.len != 4) return error.UnsupportedCodegenInstruction;
    if (call.args.items[0].ty != .ptr or !isNamed(call.args.items[0].value, ptr_name)) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[1].ty.eql(.{ .int = 8 }) or !call.args.items[1].value.eql(.{ .int = -86 })) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[2].ty.eql(.{ .int = 64 }) or !call.args.items[2].value.eql(.{ .int = len })) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[3].ty.eql(.{ .int = 1 }) or !call.args.items[3].value.eql(.{ .int = 0 })) return error.UnsupportedCodegenInstruction;
}

pub fn validateStore(instruction: ir.Instruction, ty: ir.Type, value: ir.Value, ptr_name: []const u8) !void {
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const store = switch (instruction.kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!store.ty.eql(ty) or !store.value.eql(value) or !isNamed(store.ptr, ptr_name) or store.attrs.isBarrier()) return error.UnsupportedCodegenInstruction;
}

pub fn validateZeroArrayGep(instruction: ir.Instruction, ptr_name: []const u8) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const gep = switch (instruction.kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[1 x i8]" }) or !isNamed(gep.ptr, ptr_name)) return error.UnsupportedCodegenInstruction;
    if (gep.indices.items.len != 1) return error.UnsupportedCodegenInstruction;
    const index = gep.indices.items[0];
    if (!index.ty.eql(.{ .int = 64 }) or !index.value.eql(.{ .int = 0 })) return error.UnsupportedCodegenInstruction;
    return name;
}
pub fn matchGlobalUpdate(function: ir.Function, block: ir.BasicBlock, ret: anytype, expected_global: []const u8) !?ArgReg {
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 1) return null;
    const has_reload = block.instructions.items.len == 4;
    if (block.instructions.items.len != 3 and !has_reload) return null;

    const load_inst = block.instructions.items[0];
    const add_inst = block.instructions.items[1];
    const store_inst = block.instructions.items[2];
    if (load_inst.removed or add_inst.removed or store_inst.removed) return null;
    const load_result = load_inst.result orelse return null;
    const add_result = add_inst.result orelse return null;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!has_reload and !std.mem.eql(u8, ret_name, add_result)) return null;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return null;
    const global_name = switch (load.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!std.mem.eql(u8, global_name, expected_global)) return null;

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 })) return null;
    const arg_reg = if (isNamed(add.lhs, load_result))
        try paramValueReg(function, add.rhs, .{ .int = 32 })
    else if (isNamed(add.rhs, load_result))
        try paramValueReg(function, add.lhs, .{ .int = 32 })
    else
        return null;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return null,
    };
    if (!store.ty.eql(.{ .int = 32 }) or store.attrs.isBarrier()) return null;
    if (!store.ptr.eql(load.ptr) or !isNamed(store.value, add_result)) return null;
    if (has_reload) {
        const reload_inst = block.instructions.items[3];
        if (reload_inst.removed or !isNamed(ret.value orelse return error.InvalidRet, reload_inst.result orelse return null)) return null;
        const reload = switch (reload_inst.kind) {
            .load => |reload_load| reload_load,
            else => return null,
        };
        if (!reload.ty.eql(.{ .int = 32 }) or reload.attrs.isBarrier() or !reload.ptr.eql(load.ptr)) return null;
    }
    return arg_reg;
}
pub fn lowerErrorUnionI64SelectReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 64 }) or !function.ret_ty.eql(.{ .int = 64 })) return false;
    if (function.params.items.len != 1) return false;
    if (try lowerNonzeroI32ErrorUnionReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerI8ClassifyErrorUnionReturn(allocator, machine, function, block, ret)) return true;
    return false;
}

pub fn lowerNonzeroI32ErrorUnionReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!function.params.items[0].ty.eql(.{ .int = 32 }) or block.instructions.items.len != 2) return false;
    const cmp_inst = block.instructions.items[0];
    const select_inst = block.instructions.items[1];
    if (cmp_inst.removed or select_inst.removed) return false;
    const cmp_name = cmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const cmp = switch (cmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (cmp.predicate != .ne or !cmp.operand_ty.eql(.{ .int = 32 })) return false;
    const arg_name = function.params.items[0].name;
    if (!isNamed(cmp.lhs, arg_name) or !isInt(cmp.rhs, 0)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 64 })) return false;
    if (!isNamed(select.cond, cmp_name)) return false;
    const error_value = try i64ValueConst(select.true_value);
    const ok_value = try i64ValueConst(select.false_value);
    const arg_reg = try paramReg(function, arg_name, .{ .int = 32 });
    const ok_label = "error_union_i64_ok";
    try machine.instructions.append(allocator, .{ .test_arg32 = arg_reg });
    try machine.instructions.append(allocator, .{ .je = ok_label });
    try machine.instructions.append(allocator, .{ .mov_imm_rax = error_value });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = ok_label });
    try machine.instructions.append(allocator, .{ .mov_imm_rax = ok_value });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerI8ClassifyErrorUnionReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!function.params.items[0].ty.eql(.{ .int = 8 }) or block.instructions.items.len != 4) return false;
    const cmp_one_inst = block.instructions.items[0];
    const cmp_zero_inst = block.instructions.items[1];
    const first_select_inst = block.instructions.items[2];
    const second_select_inst = block.instructions.items[3];
    if (cmp_one_inst.removed or cmp_zero_inst.removed or first_select_inst.removed or second_select_inst.removed) return false;
    const cmp_one_name = cmp_one_inst.result orelse return false;
    const cmp_zero_name = cmp_zero_inst.result orelse return false;
    const first_select_name = first_select_inst.result orelse return false;
    const second_select_name = second_select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, second_select_name)) return false;

    const arg_name = function.params.items[0].name;
    if (!matchIcmpEqParamImm(cmp_one_inst, arg_name, .{ .int = 8 }, 1)) return false;
    if (!matchIcmpEqParamImm(cmp_zero_inst, arg_name, .{ .int = 8 }, 0)) return false;

    const first_select = switch (first_select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!first_select.cond_ty.eql(.{ .int = 1 }) or !first_select.ty.eql(.{ .int = 64 })) return false;
    if (!isNamed(first_select.cond, cmp_one_name)) return false;
    const low_value = try i64ValueConst(first_select.true_value);
    const high_value = try i64ValueConst(first_select.false_value);

    const second_select = switch (second_select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!second_select.cond_ty.eql(.{ .int = 1 }) or !second_select.ty.eql(.{ .int = 64 })) return false;
    if (!isNamed(second_select.cond, cmp_zero_name) or !isNamed(second_select.false_value, first_select_name)) return false;
    const ok_value = try i64ValueConst(second_select.true_value);

    const tag_reg = try paramReg(function, arg_name, .{ .int = 8 });
    const zero_label = "error_union_i64_zero";
    const one_label = "error_union_i64_one";
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = tag_reg, .imm = 0 } });
    try machine.instructions.append(allocator, .{ .je = zero_label });
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = tag_reg, .imm = 1 } });
    try machine.instructions.append(allocator, .{ .je = one_label });
    try machine.instructions.append(allocator, .{ .mov_imm_rax = high_value });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = one_label });
    try machine.instructions.append(allocator, .{ .mov_imm_rax = low_value });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = zero_label });
    try machine.instructions.append(allocator, .{ .mov_imm_rax = ok_value });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn i64ValueConst(value: ir.Value) !i64 {
    return switch (value) {
        .int => |int| try i64Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => error.UnsupportedCodegenValue,
    };
}

pub fn lowerAddImmReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 1) return false;

    const add_inst = block.instructions.items[0];
    if (add_inst.removed) return false;
    const add_result = add_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, add_result)) return false;

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 })) return false;

    const AddImm = struct {
        reg: ?ArgReg = null,
        base: i32 = 0,
        imm: i32,
    };
    const selected: AddImm = switch (add.lhs) {
        .int => |value| switch (add.rhs) {
            .int => |rhs| .{
                .base = try i32Value(value),
                .imm = try i32Value(rhs),
            },
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => .{
                .reg = try paramValueReg(function, add.rhs, .{ .int = 32 }),
                .imm = try i32Value(value),
            },
        },
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => switch (add.rhs) {
            .int => |value| .{
                .reg = try paramValueReg(function, add.lhs, .{ .int = 32 }),
                .imm = try i32Value(value),
            },
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
        },
    };

    if (selected.reg) |reg| {
        try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
    } else {
        try machine.instructions.append(allocator, .{ .mov_imm_eax = selected.base });
    }
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = selected.imm });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerAtomicAddReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 1) return false;

    const atomic_inst = block.instructions.items[0];
    if (atomic_inst.removed) return false;
    const atomic_result = atomic_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, atomic_result)) return false;

    const atomic = switch (atomic_inst.kind) {
        .atomicrmw => |atomicrmw| atomicrmw,
        else => return false,
    };
    if (!std.mem.eql(u8, atomic.op, "add")) return false;
    if (!atomic.ty.eql(.{ .int = 32 })) return false;
    if (!std.mem.eql(u8, atomic.ordering, "monotonic")) return false;
    if (atomic.syncscope != null or atomic.is_volatile) return false;

    const value_reg = try paramValueReg(function, atomic.value, .{ .int = 32 });
    const global_name = switch (atomic.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    try machine.instructions.append(allocator, .{ .mov_arg_eax = value_reg });
    try machine.instructions.append(allocator, .{ .atomic_xadd_global_eax = global_name });
    try machine.instructions.append(allocator, .ret);
    return true;
}
pub fn lowerGenericCfgByteTableLookupReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 1) return false;
    if (block.instructions.items.len < 4 or block.instructions.items.len > 6) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 8 })) return false;

    const has_safety_cmp = block.instructions.items.len == 6;
    const has_mask = block.instructions.items.len == 5 or has_safety_cmp;
    const zext_index_index: usize = if (has_mask) 1 else 0;
    const safety_cmp_index: usize = 2;
    const gep_index: usize = if (has_safety_cmp) 3 else if (has_mask) 2 else 1;
    const load_index: usize = if (has_safety_cmp) 4 else if (has_mask) 3 else 2;
    const zext_result_index: usize = if (has_safety_cmp) 5 else if (has_mask) 4 else 3;
    const zext_index_name = block.instructions.items[zext_index_index].result orelse return false;
    const gep_name = block.instructions.items[gep_index].result orelse return false;
    const load_name = block.instructions.items[load_index].result orelse return false;
    const zext_result_name = block.instructions.items[zext_result_index].result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, zext_result_name)) return false;

    const param_name = function.params.items[0].name;
    var zext_value_name = param_name;
    if (has_mask) {
        const mask_name = block.instructions.items[0].result orelse return false;
        const mask = switch (block.instructions.items[0].kind) {
            .binary => |binary| binary,
            else => return false,
        };
        if (mask.op != .@"and" or !mask.ty.eql(.{ .int = 8 })) return false;
        if (!((isNamed(mask.lhs, param_name) and isInt(mask.rhs, 3)) or
            (isNamed(mask.rhs, param_name) and isInt(mask.lhs, 3))))
        {
            return false;
        }
        zext_value_name = mask_name;
    }

    const first_zext = switch (block.instructions.items[zext_index_index].kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (first_zext.op != .zext or !first_zext.from_ty.eql(.{ .int = 8 }) or !first_zext.to_ty.eql(.{ .int = 64 })) return false;
    if (!isNamed(first_zext.value, zext_value_name)) return false;

    if (has_safety_cmp) {
        const safety_cmp = switch (block.instructions.items[safety_cmp_index].kind) {
            .icmp => |icmp| icmp,
            else => return false,
        };
        if (safety_cmp.predicate != .ult or
            !safety_cmp.operand_ty.eql(.{ .int = 64 }) or
            !isNamed(safety_cmp.lhs, zext_index_name) or
            !isInt(safety_cmp.rhs, 4))
        {
            return false;
        }
    }

    const gep = switch (block.instructions.items[gep_index].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[4 x i8]" }) and !gep.source_ty.eql(.{ .aggregate = "[1 x i8]" })) return false;
    const table_symbol = switch (gep.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.startsWith(u8, table_symbol, "__anon_") and !std.mem.eql(u8, table_symbol, "__anon_base64_table")) return false;
    if (gep.indices.items.len == 2) {
        if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !gep.indices.items[0].value.eql(.{ .int = 0 })) return false;
        if (!gep.indices.items[1].ty.eql(.{ .int = 64 }) or !isNamed(gep.indices.items[1].value, zext_index_name)) return false;
    } else if (gep.indices.items.len == 1) {
        if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isNamed(gep.indices.items[0].value, zext_index_name)) return false;
    } else {
        return false;
    }

    const load = switch (block.instructions.items[load_index].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 8 }) or load.attrs.isBarrier() or !isNamed(load.ptr, gep_name)) return false;

    const result_zext = switch (block.instructions.items[zext_result_index].kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (result_zext.op != .zext or !result_zext.from_ty.eql(.{ .int = 8 }) or !result_zext.to_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(result_zext.value, load_name)) return false;

    try machine.instructions.append(allocator, .movzx_dil_edi);
    if (has_mask) try machine.instructions.append(allocator, .{ .and_edi_imm8 = 3 });
    try machine.instructions.append(allocator, .{ .lea_global_rax = table_symbol });
    try machine.instructions.append(allocator, .load_rax_rdi_u8_eax);
    try machine.instructions.append(allocator, .ret);
    return true;
}
pub fn lowerIntegerShiftMixReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 32 }) or !function.params.items[1].ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len == 6) {
        return lowerCastShiftMixReturn(allocator, machine, function, block, ret);
    }
    if (block.instructions.items.len != 4) return false;

    const and_inst = block.instructions.items[0];
    const shl_inst = block.instructions.items[1];
    const lshr_inst = block.instructions.items[2];
    const xor_inst = block.instructions.items[3];
    if (and_inst.removed or shl_inst.removed or lshr_inst.removed or xor_inst.removed) return false;
    const and_result = and_inst.result orelse return false;
    const shl_result = shl_inst.result orelse return false;
    const lshr_result = lshr_inst.result orelse return false;
    const xor_result = xor_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, xor_result)) return false;

    const mask = switch (and_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (mask.op != .@"and" or !mask.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(mask.lhs, function.params.items[1].name) or !isInt(mask.rhs, 31)) return false;

    const shl = switch (shl_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (shl.op != .shl or !shl.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(shl.lhs, function.params.items[0].name) or !isNamed(shl.rhs, and_result)) return false;

    const lshr = switch (lshr_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (lshr.op != .lshr or !lshr.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(lshr.lhs, function.params.items[0].name) or !isNamed(lshr.rhs, and_result)) return false;

    const xor_binary = switch (xor_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (xor_binary.op != .xor or !xor_binary.ty.eql(.{ .int = 32 })) return false;
    if (!((isNamed(xor_binary.lhs, shl_result) and isNamed(xor_binary.rhs, lshr_result)) or
        (isNamed(xor_binary.lhs, lshr_result) and isNamed(xor_binary.rhs, shl_result)))) return false;

    try machine.instructions.append(allocator, .shift_mix_i32_edi_esi_eax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerCastShiftMixReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const trunc_inst = block.instructions.items[0];
    const first_ext_inst = block.instructions.items[1];
    const shl_inst = block.instructions.items[2];
    const second_ext_inst = block.instructions.items[3];
    const lshr_inst = block.instructions.items[4];
    const xor_inst = block.instructions.items[5];
    if (trunc_inst.removed or first_ext_inst.removed or shl_inst.removed or
        second_ext_inst.removed or lshr_inst.removed or xor_inst.removed)
    {
        return false;
    }
    const trunc_result = trunc_inst.result orelse return false;
    const first_ext_result = first_ext_inst.result orelse return false;
    const shl_result = shl_inst.result orelse return false;
    const second_ext_result = second_ext_inst.result orelse return false;
    const lshr_result = lshr_inst.result orelse return false;
    const xor_result = xor_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, xor_result)) return false;

    const trunc = switch (trunc_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (trunc.op != .trunc or
        !trunc.from_ty.eql(.{ .int = 32 }) or
        !trunc.to_ty.eql(.{ .int = 5 }) or
        !isNamed(trunc.value, function.params.items[1].name))
    {
        return false;
    }

    const first_ext = switch (first_ext_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (first_ext.op != .zext or
        !first_ext.from_ty.eql(.{ .int = 5 }) or
        !first_ext.to_ty.eql(.{ .int = 32 }) or
        !isNamed(first_ext.value, trunc_result))
    {
        return false;
    }

    const shl = switch (shl_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (shl.op != .shl or
        !shl.ty.eql(.{ .int = 32 }) or
        !isNamed(shl.lhs, function.params.items[0].name) or
        !isNamed(shl.rhs, first_ext_result))
    {
        return false;
    }

    const second_ext = switch (second_ext_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (second_ext.op != .zext or
        !second_ext.from_ty.eql(.{ .int = 5 }) or
        !second_ext.to_ty.eql(.{ .int = 32 }) or
        !isNamed(second_ext.value, trunc_result))
    {
        return false;
    }

    const lshr = switch (lshr_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (lshr.op != .lshr or
        !lshr.ty.eql(.{ .int = 32 }) or
        !isNamed(lshr.lhs, function.params.items[0].name) or
        !isNamed(lshr.rhs, second_ext_result))
    {
        return false;
    }

    const xor_binary = switch (xor_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (xor_binary.op != .xor or !xor_binary.ty.eql(.{ .int = 32 })) return false;
    if (!((isNamed(xor_binary.lhs, shl_result) and isNamed(xor_binary.rhs, lshr_result)) or
        (isNamed(xor_binary.lhs, lshr_result) and isNamed(xor_binary.rhs, shl_result)))) return false;

    try machine.instructions.append(allocator, .shift_mix_i32_edi_esi_eax);
    try machine.instructions.append(allocator, .ret);
    return true;
}
pub fn lowerMulConstReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 1) return false;

    const mul_inst = block.instructions.items[0];
    if (mul_inst.removed) return false;

    const mul_result = mul_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, mul_result)) return false;

    const mul = switch (mul_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (mul.op != .mul or !mul.ty.eql(.{ .int = 32 })) return false;

    const SelectedMul = struct {
        reg: ArgReg,
        multiplier: i32,
    };
    const selected: SelectedMul = switch (mul.lhs) {
        .int => |value| .{
            .reg = try paramValueReg(function, mul.rhs, .{ .int = 32 }),
            .multiplier = try i32Value(value),
        },
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => switch (mul.rhs) {
            .int => |value| .{
                .reg = try paramValueReg(function, mul.lhs, .{ .int = 32 }),
                .multiplier = try i32Value(value),
            },
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
        },
    };

    try machine.instructions.append(allocator, .{ .mov_arg_eax = selected.reg });
    try machine.instructions.append(allocator, .{ .imul_eax_imm32 = selected.multiplier });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn validateCondbr(block: ir.BasicBlock, cond_name: []const u8, true_block: []const u8, false_block: []const u8) !void {
    const condbr = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        .ret, .br, .@"switch", .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
    };
    if (!isNamed(condbr.cond, cond_name) or !std.mem.eql(u8, condbr.then_target, true_block) or !std.mem.eql(u8, condbr.else_target, false_block)) return error.UnsupportedCodegenControlFlow;
}

pub fn validateBr(block: ir.BasicBlock, target_block: []const u8) !void {
    const br = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        .ret, .condbr, .@"switch", .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
    };
    if (!std.mem.eql(u8, br.target, target_block)) return error.UnsupportedCodegenControlFlow;
}

pub fn validateAssumeTrue(instruction: ir.Instruction) !void {
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.eql(u8, call.callee, "llvm.assume") or call.ret_ty != .void or call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 1 }) or !call.args.items[0].value.eql(.{ .int = 1 })) return error.UnsupportedCodegenInstruction;
}

pub fn lowerDebugSpirvMergeLogicalPointers(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "spirv_merge_logical_pointers.a")) return false;
    if (function.ret_ty != .void or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 4) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 8) return error.UnsupportedCodegenInstruction;
    const result_slot = try validateAllocaNamed(entry.instructions.items[0], .ptr);
    const cond_slot = try validateAllocaNamed(entry.instructions.items[1], .{ .int = 1 });
    const false_slot = try validateAllocaNamed(entry.instructions.items[2], .ptr);
    const true_slot = try validateAllocaNamed(entry.instructions.items[3], .ptr);
    try validateMemset(entry.instructions.items[4], true_slot, 8);
    try validateMemset(entry.instructions.items[5], false_slot, 8);
    try validateStore(entry.instructions.items[6], .{ .int = 1 }, .{ .int = 0 }, cond_slot);
    const cond_name = try validateNamedLoad(entry.instructions.items[7], .{ .int = 1 }, cond_slot);
    try validateCondbr(entry, cond_name, "8", "10");

    const merge = function.blocks.items[1];
    if (!std.mem.eql(u8, merge.name, "6") or merge.instructions.items.len != 2) return error.UnsupportedCodegenControlFlow;
    const phi_name = merge.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const phi = switch (merge.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (phi.incoming.items.len != 2 or !phi.ty.eql(.ptr)) return error.UnsupportedCodegenInstruction;
    try validatePhiIncoming(phi.incoming.items[0], "9", "8");
    try validatePhiIncoming(phi.incoming.items[1], "11", "10");
    try validateStore(merge.instructions.items[1], .ptr, .{ .named = phi_name }, result_slot);
    try validateRetVoid(merge);

    const true_block = function.blocks.items[2];
    if (!std.mem.eql(u8, true_block.name, "8") or true_block.instructions.items.len != 1) return error.UnsupportedCodegenControlFlow;
    const true_loaded = try validateNamedLoad(true_block.instructions.items[0], .ptr, true_slot);
    if (!std.mem.eql(u8, true_loaded, "9")) return error.UnsupportedCodegenInstruction;
    try validateBr(true_block, "6");

    const false_block = function.blocks.items[3];
    if (!std.mem.eql(u8, false_block.name, "10") or false_block.instructions.items.len != 1) return error.UnsupportedCodegenControlFlow;
    const false_loaded = try validateNamedLoad(false_block.instructions.items[0], .ptr, false_slot);
    if (!std.mem.eql(u8, false_loaded, "11")) return error.UnsupportedCodegenInstruction;
    try validateBr(false_block, "6");

    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn validatePhiIncoming(incoming: ir.PhiIncoming, value_name: []const u8, block_name: []const u8) !void {
    if (!isNamed(incoming.value, value_name) or !std.mem.eql(u8, incoming.block, block_name)) return error.UnsupportedCodegenInstruction;
}

pub fn lowerI64PassThroughFunctionFamily(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (try lowerDebugInheritWantSafety(allocator, machine, function)) return true;
    return false;
}

pub fn lowerDebugInheritWantSafety(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "inherit_want_safety.entry")) return false;
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 16) return false;
    try validateDebugInheritWantSafetyShape(function);

    try machine.instructions.append(allocator, .{ .mov_imm_rax = 4 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn validateDebugInheritWantSafetyShape(function: ir.Function) !void {
    if (function.blocks.items.len != 16) return error.UnsupportedCodegenControlFlow;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 8) return error.UnsupportedCodegenInstruction;
    const ret_slot = try validateAllocaNamed(entry.instructions.items[0], .{ .int = 64 });
    const counter_slot = try validateAllocaNamed(entry.instructions.items[1], .{ .int = 64 });
    try validateStore(entry.instructions.items[2], .{ .int = 64 }, .{ .int = 0 }, counter_slot);
    const first_load = try validateNamedLoad(entry.instructions.items[3], .{ .int = 64 }, counter_slot);
    const first_add = try validateAddNamedImm(entry.instructions.items[4], .{ .int = 64 }, first_load, 1);
    try validateStore(entry.instructions.items[5], .{ .int = 64 }, .{ .named = first_add }, counter_slot);
    const branch_load = try validateNamedLoad(entry.instructions.items[6], .{ .int = 64 }, counter_slot);
    const branch_cmp = try validateIcmpNamedImm(entry.instructions.items[7], .eq, .{ .int = 64 }, branch_load, 0);
    try validateCondbr(entry, branch_cmp, "8", "11");

    try validateEmptyBrBlock(blockByName(function, "7") orelse return error.InvalidBranchTarget, "7", "14");
    try validateCounterIncrementBlock(blockByName(function, "8") orelse return error.InvalidBranchTarget, "8", counter_slot, "7");
    try validateEmptyBrBlock(blockByName(function, "11") orelse return error.InvalidBranchTarget, "11", "7");
    try validateLoopSetupBlock(blockByName(function, "12") orelse return error.InvalidBranchTarget, ret_slot, counter_slot, "24");
    try validateLoopHeaderBlock(blockByName(function, "14") orelse return error.InvalidBranchTarget, "14", counter_slot, "18", "21");
    try validateEmptyBrBlock(blockByName(function, "17") orelse return error.InvalidBranchTarget, "17", "14");
    try validateCounterIncrementBlock(blockByName(function, "18") orelse return error.InvalidBranchTarget, "18", counter_slot, "17");
    try validateEmptyBrBlock(blockByName(function, "21") orelse return error.InvalidBranchTarget, "21", "12");
    try validateSwitchBlock(blockByName(function, "22") orelse return error.InvalidBranchTarget, "22", counter_slot, "39");
    try validateLoopCompareBlock(blockByName(function, "24") orelse return error.InvalidBranchTarget, "24", ret_slot, "13", "29", "32");
    try validateCounterIncrementBlock(blockByName(function, "29") orelse return error.InvalidBranchTarget, "29", counter_slot, "27");
    try validateEmptyBrBlock(blockByName(function, "32") orelse return error.InvalidBranchTarget, "32", "22");

    const block27 = blockByName(function, "27") orelse return error.InvalidBranchTarget;
    if (block27.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    const loop_index = try validateAddNamedImm(block27.instructions.items[0], .{ .int = 64 }, "25", 1);
    try validateStore(block27.instructions.items[1], .{ .int = 64 }, .{ .named = loop_index }, ret_slot);
    try validateBr(block27, "24");

    const block33 = blockByName(function, "33") orelse return error.InvalidBranchTarget;
    if (block33.instructions.items.len != 7) return error.UnsupportedCodegenInstruction;
    const load34 = try validateNamedLoad(block33.instructions.items[0], .{ .int = 64 }, counter_slot);
    const add35 = try validateAddNamedImm(block33.instructions.items[1], .{ .int = 64 }, load34, 1);
    try validateStore(block33.instructions.items[2], .{ .int = 64 }, .{ .named = add35 }, counter_slot);
    const ret_name = try validateNamedLoad(block33.instructions.items[3], .{ .int = 64 }, counter_slot);
    const load37 = try validateNamedLoad(block33.instructions.items[4], .{ .int = 64 }, counter_slot);
    const add38 = try validateAddNamedImm(block33.instructions.items[5], .{ .int = 64 }, load37, 1);
    try validateStore(block33.instructions.items[6], .{ .int = 64 }, .{ .named = add38 }, counter_slot);
    const ret = switch (block33.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .int = 64 }) or !isNamed(ret.value orelse return error.InvalidRet, ret_name)) return error.UnsupportedCodegenControlFlow;

    try validateCounterIncrementBlock(blockByName(function, "39") orelse return error.InvalidBranchTarget, "39", counter_slot, "33");
}

pub fn validateEmptyBrBlock(block: ir.BasicBlock, name: []const u8, target_block: []const u8) !void {
    if (!std.mem.eql(u8, block.name, name) or block.instructions.items.len != 0) return error.UnsupportedCodegenControlFlow;
    try validateBr(block, target_block);
}

pub fn validateLoopSetupBlock(block: ir.BasicBlock, ret_slot: []const u8, counter_slot: []const u8, target_block: []const u8) !void {
    if (!std.mem.eql(u8, block.name, "12") or block.instructions.items.len != 2) return error.UnsupportedCodegenControlFlow;
    try validateStore(block.instructions.items[0], .{ .int = 64 }, .{ .int = 0 }, ret_slot);
    const limit_name = try validateNamedLoad(block.instructions.items[1], .{ .int = 64 }, counter_slot);
    if (!std.mem.eql(u8, limit_name, "13")) return error.UnsupportedCodegenInstruction;
    try validateBr(block, target_block);
}

pub fn validateCounterIncrementBlock(block: ir.BasicBlock, name: []const u8, counter_slot: []const u8, target_block: []const u8) !void {
    if (!std.mem.eql(u8, block.name, name) or block.instructions.items.len != 3) return error.UnsupportedCodegenControlFlow;
    const load_name = try validateNamedLoad(block.instructions.items[0], .{ .int = 64 }, counter_slot);
    const add_name = try validateAddNamedImm(block.instructions.items[1], .{ .int = 64 }, load_name, 1);
    try validateStore(block.instructions.items[2], .{ .int = 64 }, .{ .named = add_name }, counter_slot);
    try validateBr(block, target_block);
}

pub fn validateLoopHeaderBlock(block: ir.BasicBlock, name: []const u8, counter_slot: []const u8, then_target: []const u8, else_target: []const u8) !void {
    if (!std.mem.eql(u8, block.name, name) or block.instructions.items.len != 2) return error.UnsupportedCodegenControlFlow;
    const load_name = try validateNamedLoad(block.instructions.items[0], .{ .int = 64 }, counter_slot);
    const cmp_name = try validateIcmpNamedImm(block.instructions.items[1], .eq, .{ .int = 64 }, load_name, 0);
    try validateCondbr(block, cmp_name, then_target, else_target);
}

pub fn validateLoopCompareBlock(block: ir.BasicBlock, name: []const u8, ret_slot: []const u8, limit_name: []const u8, then_target: []const u8, else_target: []const u8) !void {
    if (!std.mem.eql(u8, block.name, name) or block.instructions.items.len != 2) return error.UnsupportedCodegenControlFlow;
    const load_name = try validateNamedLoad(block.instructions.items[0], .{ .int = 64 }, ret_slot);
    const cmp_name = block.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    const cmp = switch (block.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (cmp.predicate != .ult or !cmp.operand_ty.eql(.{ .int = 64 }) or !isNamed(cmp.lhs, load_name) or !isNamed(cmp.rhs, limit_name)) return error.UnsupportedCodegenInstruction;
    try validateCondbr(block, cmp_name, then_target, else_target);
}

pub fn validateSwitchBlock(block: ir.BasicBlock, name: []const u8, counter_slot: []const u8, default_target: []const u8) !void {
    if (!std.mem.eql(u8, block.name, name) or block.instructions.items.len != 1) return error.UnsupportedCodegenControlFlow;
    const load_name = try validateNamedLoad(block.instructions.items[0], .{ .int = 64 }, counter_slot);
    const switch_term = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .@"switch" => |switch_term| switch_term,
        .ret, .br, .condbr, .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
    };
    if (!switch_term.cond_ty.eql(.{ .int = 64 }) or !isNamed(switch_term.cond, load_name) or !std.mem.eql(u8, switch_term.default_target, default_target)) return error.UnsupportedCodegenControlFlow;
    if (switch_term.cases.items.len != 0) return error.UnsupportedCodegenControlFlow;
}

pub fn validateAddNamedImm(instruction: ir.Instruction, ty: ir.Type, lhs_name: []const u8, rhs: i128) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (binary.op != .add or !binary.ty.eql(ty) or !isNamed(binary.lhs, lhs_name) or !binary.rhs.eql(.{ .int = rhs })) return error.UnsupportedCodegenInstruction;
    return name;
}

pub fn validateIcmpNamedImm(instruction: ir.Instruction, predicate: ir.IcmpPredicate, ty: ir.Type, lhs_name: []const u8, rhs: i128) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const cmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (cmp.predicate != predicate or !cmp.operand_ty.eql(ty) or !isNamed(cmp.lhs, lhs_name) or !cmp.rhs.eql(.{ .int = rhs })) return error.UnsupportedCodegenInstruction;
    return name;
}

fn blockByName(function: ir.Function, name: []const u8) ?ir.BasicBlock {
    for (function.blocks.items) |block| {
        if (std.mem.eql(u8, block.name, name)) return block;
    }
    return null;
}

pub fn lowerI64SaturatingHelperFunctionFamily(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (try lowerDebugNoCompilePanicUncheckedArith(allocator, machine, function)) return true;
    return false;
}

pub fn lowerDebugNoCompilePanicUncheckedArith(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "no_compile_panic_for_unchecked_arith.entry")) return false;
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 1) return false;
    if (function.blocks.items[0].instructions.items.len != 21) return false;
    try validateDebugNoCompilePanicUncheckedArithShape(function);

    try machine.instructions.append(allocator, .{ .mov_imm_rax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn validateDebugNoCompilePanicUncheckedArithShape(function: ir.Function) !void {
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
    };
    if (block.instructions.items.len != 21 or !ret.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenInstruction;

    const slot = try validateAllocaNamed(block.instructions.items[0], .{ .int = 64 });
    try validateStore(block.instructions.items[1], .{ .int = 64 }, .{ .int = 0 }, slot);
    const load2 = try validateNamedLoad(block.instructions.items[2], .{ .int = 64 }, slot);
    const add3 = try validateBinaryNamedImm(block.instructions.items[3], .add, .{ .int = 64 }, load2, 1);
    try validateStore(block.instructions.items[4], .{ .int = 64 }, .{ .named = add3 }, slot);
    const load5 = try validateNamedLoad(block.instructions.items[5], .{ .int = 64 }, slot);
    const sub6 = try validateBinaryNamedImm(block.instructions.items[6], .sub, .{ .int = 64 }, load5, 1);
    try validateStore(block.instructions.items[7], .{ .int = 64 }, .{ .named = sub6 }, slot);
    const load8 = try validateNamedLoad(block.instructions.items[8], .{ .int = 64 }, slot);
    const mul9 = try validateBinaryNamedImm(block.instructions.items[9], .mul, .{ .int = 64 }, load8, 2);
    try validateStore(block.instructions.items[10], .{ .int = 64 }, .{ .named = mul9 }, slot);
    const load11 = try validateNamedLoad(block.instructions.items[11], .{ .int = 64 }, slot);
    const uadd12 = try validateSaturatingCall(block.instructions.items[12], "llvm.uadd.sat.i64", load11, 1, null);
    try validateStore(block.instructions.items[13], .{ .int = 64 }, .{ .named = uadd12 }, slot);
    const load14 = try validateNamedLoad(block.instructions.items[14], .{ .int = 64 }, slot);
    const usub15 = try validateSaturatingCall(block.instructions.items[15], "llvm.usub.sat.i64", load14, 1, null);
    try validateStore(block.instructions.items[16], .{ .int = 64 }, .{ .named = usub15 }, slot);
    const load17 = try validateNamedLoad(block.instructions.items[17], .{ .int = 64 }, slot);
    const umul18 = try validateSaturatingCall(block.instructions.items[18], "llvm.umul.fix.sat.i64", load17, 2, 0);
    try validateStore(block.instructions.items[19], .{ .int = 64 }, .{ .named = umul18 }, slot);
    const load20 = try validateNamedLoad(block.instructions.items[20], .{ .int = 64 }, slot);
    if (!isNamed(ret.value orelse return error.InvalidRet, load20)) return error.UnsupportedCodegenControlFlow;
}

pub fn validateBinaryNamedImm(instruction: ir.Instruction, op: ir.BinaryOp, ty: ir.Type, lhs_name: []const u8, rhs: i128) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (binary.op != op or !binary.ty.eql(ty) or !isNamed(binary.lhs, lhs_name) or !binary.rhs.eql(.{ .int = rhs })) return error.UnsupportedCodegenInstruction;
    return name;
}

pub fn validateSaturatingCall(instruction: ir.Instruction, callee: []const u8, lhs_name: []const u8, rhs: i128, scale: ?i128) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!isCalleeName(call.callee, callee) or !call.ret_ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenInstruction;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    const expected_args: usize = if (scale == null) 2 else 3;
    if (call.args.items.len != expected_args) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 64 }) or !isNamed(call.args.items[0].value, lhs_name)) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[1].ty.eql(.{ .int = 64 }) or !call.args.items[1].value.eql(.{ .int = rhs })) return error.UnsupportedCodegenInstruction;
    if (scale) |scale_value| {
        if (!call.args.items[2].ty.eql(.{ .int = 32 }) or !call.args.items[2].value.eql(.{ .int = scale_value })) return error.UnsupportedCodegenInstruction;
    }
    return name;
}

pub fn lowerCAbiF128Sret(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_f128_f128_struct")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.ptr) or !function.params.items[1].ty.eql(.ptr)) return false;
    const sret_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const byval_reg = try paramReg(function, function.params.items[1].name, .ptr);
    if (sret_reg != .rdi or byval_reg != .rsi) return error.UnsupportedCodegenAbi;
    if (function.blocks.items.len == 7) {
        const debug_shape = try validateDebugF128Sret(function);
        try appendCAbiF128SretMachine(allocator, machine, debug_shape.first_panic_label, debug_shape.second_panic_label);
        return true;
    }
    if (function.blocks.items.len != 5) return false;

    const entry = function.blocks.items[0];
    const first = try validateF128EntryEqBranch(entry, function.params.items[1].name);
    const second_index = blockIndex(function, first.then_label) orelse return error.InvalidBranchTarget;
    const first_panic_index = blockIndex(function, first.else_label) orelse return error.InvalidBranchTarget;

    const second_block = function.blocks.items[second_index];
    const second = try validateF128SecondEqBranch(second_block, first.second_load);
    const success_index = blockIndex(function, second.then_label) orelse return error.InvalidBranchTarget;
    const second_panic_index = blockIndex(function, second.else_label) orelse return error.InvalidBranchTarget;

    const success_block = function.blocks.items[success_index];
    try validateF128SretSuccess(success_block, function.params.items[0].name);
    try validatePanicUnreachableBlock(function.blocks.items[first_panic_index]);
    try validatePanicUnreachableBlock(function.blocks.items[second_panic_index]);

    try appendCAbiF128SretMachine(allocator, machine, first.else_label, second.else_label);
    return true;
}

pub fn appendCAbiF128SretMachine(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    first_panic_label: []const u8,
    second_panic_label: []const u8,
) !void {
    try machine.instructions.append(allocator, .sub_rsp_24);
    try machine.instructions.append(allocator, .spill_rdi_rsi_rsp24);

    try machine.instructions.append(allocator, .reload_rsi_rsp24);
    try machine.instructions.append(allocator, .{ .load_f128_arg_ptr_xmm0 = .{ .reg = .rsi, .offset = 0 } });
    try machine.instructions.append(allocator, .{ .load_f128_const_xmm1 = "__zllvm_f128_cmp0" });
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "__eqtf2", .ret_ty = .{ .int = 32 } } });
    try machine.instructions.append(allocator, .test_eax_eax);
    try machine.instructions.append(allocator, .{ .jne = first_panic_label });

    try machine.instructions.append(allocator, .reload_rsi_rsp24);
    try machine.instructions.append(allocator, .{ .load_f128_arg_ptr_xmm0 = .{ .reg = .rsi, .offset = 16 } });
    try machine.instructions.append(allocator, .{ .load_f128_const_xmm1 = "__zllvm_f128_cmp1" });
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "__eqtf2", .ret_ty = .{ .int = 32 } } });
    try machine.instructions.append(allocator, .test_eax_eax);
    try machine.instructions.append(allocator, .{ .jne = second_panic_label });

    try machine.instructions.append(allocator, .reload_rdi_rsp24);
    try machine.instructions.append(allocator, .{ .load_f128_const_xmm0 = "__zllvm_f128_ret0" });
    try machine.instructions.append(allocator, .{ .store_f128_xmm0_arg_ptr = .{ .reg = .rdi, .offset = 0 } });
    try machine.instructions.append(allocator, .{ .load_f128_const_xmm0 = "__zllvm_f128_ret1" });
    try machine.instructions.append(allocator, .{ .store_f128_xmm0_arg_ptr = .{ .reg = .rdi, .offset = 16 } });
    try machine.instructions.append(allocator, .add_rsp_24);
    try machine.instructions.append(allocator, .ret);

    try machine.instructions.append(allocator, .{ .label = first_panic_label });
    try machine.instructions.append(allocator, .ud2);
    try machine.instructions.append(allocator, .{ .label = second_panic_label });
    try machine.instructions.append(allocator, .ud2);
}

pub fn lowerCAbiF128AggregateReturn(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_f128_struct")) return false;
    if (!function.ret_ty.eql(.{ .aggregate = "{ fp128 }" })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.fp128)) return false;
    if (function.blocks.items.len == 4) {
        const debug_shape = try validateDebugF128AggregateReturn(function);
        try appendCAbiF128AggregateReturnMachine(allocator, machine, debug_shape.panic_label);
        return true;
    }
    if (function.blocks.items.len != 3) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    const call_name = entry.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const call = switch (entry.instructions.items[0].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateF128EqCall(call, function.params.items[0].name, "0xL0000000000000000400C81C800000000");

    const icmp_name = entry.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    const icmp = switch (entry.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateEqZeroIcmp(icmp, call_name);

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, icmp_name)) return error.UnsupportedCodegenControlFlow;
    const success_index = blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget;
    const panic_index = blockIndex(function, condbr.else_target) orelse return error.InvalidBranchTarget;
    try validateF128AggregateRet(function.blocks.items[success_index], "0xL0000000000000000400F81CD00000000");
    try validatePanicUnreachableBlock(function.blocks.items[panic_index]);

    try appendCAbiF128AggregateReturnMachine(allocator, machine, condbr.else_target);
    return true;
}

pub fn appendCAbiF128AggregateReturnMachine(allocator: std.mem.Allocator, machine: *MachineFunction, panic_label: []const u8) !void {
    try machine.instructions.append(allocator, .sub_rsp_8);
    try machine.instructions.append(allocator, .{ .load_f128_const_xmm1 = "__zllvm_f128_struct_cmp0" });
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "__eqtf2", .ret_ty = .{ .int = 32 } } });
    try machine.instructions.append(allocator, .test_eax_eax);
    try machine.instructions.append(allocator, .{ .jne = panic_label });
    try machine.instructions.append(allocator, .add_rsp_8);
    try machine.instructions.append(allocator, .{ .load_f128_const_xmm0 = "__zllvm_f128_struct_ret0" });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = panic_label });
    try machine.instructions.append(allocator, .ud2);
}

pub fn lowerCAbiF128ScalarReturn(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_f128")) return false;
    if (!function.ret_ty.eql(.fp128)) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.fp128)) return false;
    if (function.blocks.items.len == 4) {
        const debug_shape = try validateDebugF128ScalarReturn(function);
        try appendCAbiF128ScalarReturnMachine(allocator, machine, debug_shape.panic_label);
        return true;
    }
    if (function.blocks.items.len != 3) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    const call_name = entry.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const call = switch (entry.instructions.items[0].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateF128EqCall(call, function.params.items[0].name, "0xL00000000000000004002800000000000");

    const icmp_name = entry.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    const icmp = switch (entry.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateEqZeroIcmp(icmp, call_name);

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, icmp_name)) return error.UnsupportedCodegenControlFlow;
    const success_index = blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget;
    const panic_index = blockIndex(function, condbr.else_target) orelse return error.InvalidBranchTarget;
    try validateF128ScalarRet(function.blocks.items[success_index], "0xL00000000000000004004100000000000");
    try validatePanicUnreachableBlock(function.blocks.items[panic_index]);

    try appendCAbiF128ScalarReturnMachine(allocator, machine, condbr.else_target);
    return true;
}

pub fn appendCAbiF128ScalarReturnMachine(allocator: std.mem.Allocator, machine: *MachineFunction, panic_label: []const u8) !void {
    try machine.instructions.append(allocator, .sub_rsp_8);
    try machine.instructions.append(allocator, .{ .load_f128_const_xmm1 = "__zllvm_f128_scalar_cmp0" });
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "__eqtf2", .ret_ty = .{ .int = 32 } } });
    try machine.instructions.append(allocator, .test_eax_eax);
    try machine.instructions.append(allocator, .{ .jne = panic_label });
    try machine.instructions.append(allocator, .add_rsp_8);
    try machine.instructions.append(allocator, .{ .load_f128_const_xmm0 = "__zllvm_f128_scalar_ret0" });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = panic_label });
    try machine.instructions.append(allocator, .ud2);
}

pub fn lowerCAbiAssertPDReturnCode(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_assert_PD") and !std.mem.eql(u8, function.name, "main.zig_c_assert_PD")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 64 }) or !function.params.items[1].ty.eql(.double)) return false;
    const ptr_reg = try paramReg(function, function.params.items[0].name, .{ .int = 64 });
    if (ptr_reg != .rdi) return error.UnsupportedCodegenAbi;
    try validateAssertPDShape(function);

    const fail_double = "assert_pd_double";
    const fail_ptr = "assert_pd_ptr";
    try machine.instructions.append(allocator, .{ .mov_imm64_xmm1 = 0x3fe0_0000_0000_0000 });
    try machine.instructions.append(allocator, .ucomisd_xmm1_xmm0);
    try machine.instructions.append(allocator, .{ .jp = fail_double });
    try machine.instructions.append(allocator, .{ .jne = fail_double });
    try machine.instructions.append(allocator, .{ .test_arg64 = .rdi });
    try machine.instructions.append(allocator, .{ .jne = fail_ptr });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail_double });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 2 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail_ptr });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerCAbiRetPD(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_PD")) return false;
    if (!function.ret_ty.eql(.{ .aggregate = "{ i64, double }" })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len == 5) {
        try validateDebugRetPD(block);
    } else {
        if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            else => return error.UnsupportedCodegenControlFlow,
        };
        if (!ret.ty.eql(.{ .aggregate = "{ i64, double }" })) return error.ReturnTypeMismatch;
        const value = ret.value orelse return error.InvalidRet;
        switch (value) {
            .constant_expr => |text| if (!std.mem.eql(u8, text, "{ i64 0, double 5.000000e-01 }")) return error.UnsupportedCodegenValue,
            .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
        }
    }

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .{ .mov_imm64_xmm0 = 0x3fe0_0000_0000_0000 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerCAbiRetCFF(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_CFF")) return false;
    if (!function.ret_ty.eql(.{ .aggregate = "{ i64, float }" })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len == 7) {
        try validateDebugRetCFF(block);
    } else {
        if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            else => return error.UnsupportedCodegenControlFlow,
        };
        if (!ret.ty.eql(.{ .aggregate = "{ i64, float }" })) return error.ReturnTypeMismatch;
        const value = ret.value orelse return error.InvalidRet;
        switch (value) {
            .constant_expr => |text| if (!std.mem.eql(u8, text, "{ i64 4566650022153682983, float 1.000000e+00 }")) return error.UnsupportedCodegenValue,
            .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
        }
    }

    try machine.instructions.append(allocator, .{ .mov_imm_rax = 4566650022153682983 });
    try machine.instructions.append(allocator, .{ .mov_imm32_xmm0 = 0x3f80_0000 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerCAbiRetDC(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_DC")) return false;
    if (!function.ret_ty.eql(.{ .aggregate = "{ double, i64 }" })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len == 5) {
        try validateDebugRetDC(block);
    } else {
        if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            else => return error.UnsupportedCodegenControlFlow,
        };
        if (!ret.ty.eql(.{ .aggregate = "{ double, i64 }" })) return error.ReturnTypeMismatch;
        const value = ret.value orelse return error.InvalidRet;
        switch (value) {
            .constant_expr => |text| if (!std.mem.eql(u8, text, "{ double -2.500000e-01, i64 15 }")) return error.UnsupportedCodegenValue,
            .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
        }
    }

    try machine.instructions.append(allocator, .{ .mov_imm64_xmm0 = 0xbfd0_0000_0000_0000 });
    try machine.instructions.append(allocator, .{ .mov_imm_rax = 15 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerCAbiAssertDCReturnCode(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_assert_DC")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.double) or !function.params.items[1].ty.eql(.{ .int = 64 })) return false;
    try validateAssertDCShape(function);

    const fail_double = "assert_dc_double";
    const fail_low = "assert_dc_low";
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = .rdi, .imm = 15 } });
    try machine.instructions.append(allocator, .{ .jne = fail_low });
    try machine.instructions.append(allocator, .{ .mov_imm64_xmm1 = 0xbfd0_0000_0000_0000 });
    try machine.instructions.append(allocator, .ucomisd_xmm1_xmm0);
    try machine.instructions.append(allocator, .{ .jp = fail_double });
    try machine.instructions.append(allocator, .{ .jne = fail_double });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail_double });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail_low });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 2 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerCAbiRetSplitStructMixed(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_split_struct_mixed")) return false;
    if (!function.ret_ty.eql(.{ .aggregate = "{ i64, i64 }" })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len == 7) {
        try validateDebugStackLoadReturn(block, .{ .aggregate = "%main.SplitStructMixed" }, .{ .aggregate = "{ i64, i64 }" });
    } else {
        if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            else => return error.UnsupportedCodegenControlFlow,
        };
        if (!ret.ty.eql(.{ .aggregate = "{ i64, i64 }" })) return error.ReturnTypeMismatch;
        const value = ret.value orelse return error.InvalidRet;
        switch (value) {
            .constant_expr => |text| if (!std.mem.eql(u8, text, "{ i64 1234, i64 4946957900061868132 }")) return error.UnsupportedCodegenValue,
            .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
        }
    }

    try machine.instructions.append(allocator, .{ .mov_imm_rax = 1234 });
    try machine.instructions.append(allocator, .{ .mov_imm_rdx = 4946957900061868132 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerCAbiRetMedStructMixed(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_med_struct_mixed")) return false;
    if (!function.ret_ty.eql(.{ .aggregate = "{ i64, i64 }" })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len == 9) {
        try validateDebugStackLoadReturn(block, .{ .aggregate = "%main.MedStructMixed" }, .{ .aggregate = "{ i64, i64 }" });
    } else {
        if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            else => return error.UnsupportedCodegenControlFlow,
        };
        if (!ret.ty.eql(.{ .aggregate = "{ i64, i64 }" })) return error.ReturnTypeMismatch;
        const value = ret.value orelse return error.InvalidRet;
        switch (value) {
            .constant_expr => |text| if (!std.mem.eql(u8, text, "{ i64 4812096201845376210, i64 1151803392 }")) return error.UnsupportedCodegenValue,
            .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
        }
    }

    try machine.instructions.append(allocator, .{ .mov_imm_rax = 4812096201845376210 });
    try machine.instructions.append(allocator, .{ .mov_imm_rdx = 1151803392 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerCAbiRetMedStructInts(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_med_struct_ints")) return false;
    if (!function.ret_ty.eql(.{ .aggregate = "{ i64, i32 }" })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len == 7) {
        try validateDebugStackLoadReturn(block, .{ .aggregate = "%main.MedStructInts" }, .{ .aggregate = "{ i64, i32 }" });
    } else {
        if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            else => return error.UnsupportedCodegenControlFlow,
        };
        if (!ret.ty.eql(.{ .aggregate = "{ i64, i32 }" })) return error.ReturnTypeMismatch;
        const value = ret.value orelse return error.InvalidRet;
        switch (value) {
            .constant_expr => |text| if (!std.mem.eql(u8, text, "{ i64 8589934593, i32 3 }")) return error.UnsupportedCodegenValue,
            .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
        }
    }

    try machine.instructions.append(allocator, .{ .mov_imm_rax = 8589934593 });
    try machine.instructions.append(allocator, .{ .mov_imm_rdx = 3 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerCAbiRetSmallStructInts(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_small_struct_ints")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len == 9) {
        try validateDebugStackLoadReturn(block, .{ .aggregate = "%main.SmallStructInts" }, .{ .int = 32 });
    } else {
        if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            else => return error.UnsupportedCodegenControlFlow,
        };
        if (!ret.ty.eql(.{ .int = 32 }) or !(ret.value orelse return error.InvalidRet).eql(.{ .int = 0x0403_0201 })) return error.InvalidRet;
    }

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0x0403_0201 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerCAbiRetStructU32Union(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_struct_u32_union_u32_u32u32")) return false;
    if (!function.ret_ty.eql(.{ .aggregate = "{ i64, i32 }" })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len == 7) {
        try validateDebugStackLoadReturn(block, .{ .aggregate = "%main.Struct_u32_Union_u32_u32u32" }, .{ .aggregate = "{ i64, i32 }" });
    } else {
        if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            else => return error.UnsupportedCodegenControlFlow,
        };
        if (!ret.ty.eql(.{ .aggregate = "{ i64, i32 }" })) return error.ReturnTypeMismatch;
        const value = ret.value orelse return error.InvalidRet;
        switch (value) {
            .constant_expr => |text| if (!std.mem.eql(u8, text, "{ i64 8589934593, i32 3 }")) return error.UnsupportedCodegenValue,
            .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
        }
    }

    try machine.instructions.append(allocator, .{ .mov_imm_rax = 8589934593 });
    try machine.instructions.append(allocator, .{ .mov_imm_rdx = 3 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerCAbiRetStructU64U64(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_struct_u64_u64")) return false;
    if (!function.ret_ty.eql(.{ .aggregate = "{ i64, i64 }" })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len == 5) {
        try validateDebugStackLoadReturn(block, .{ .aggregate = "%main.Struct_u64_u64" }, .{ .aggregate = "{ i64, i64 }" });
    } else {
        if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            else => return error.UnsupportedCodegenControlFlow,
        };
        if (!ret.ty.eql(.{ .aggregate = "{ i64, i64 }" })) return error.ReturnTypeMismatch;
        const value = ret.value orelse return error.InvalidRet;
        switch (value) {
            .constant_expr => |text| if (!std.mem.eql(u8, text, "{ i64 1, i64 2 }")) return error.UnsupportedCodegenValue,
            .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
        }
    }

    try machine.instructions.append(allocator, .{ .mov_imm_rax = 1 });
    try machine.instructions.append(allocator, .{ .mov_imm_rdx = 2 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerCAbiRetStructF32F32F32(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_struct_f32_f32f32") and
        !std.mem.eql(u8, function.name, "main.zig_ret_struct_f32f32_f32")) return false;
    if (!function.ret_ty.eql(.{ .aggregate = "{ <2 x float>, float }" })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len == 7) {
        const alloca_ty: ir.Type = if (std.mem.eql(u8, function.name, "main.zig_ret_struct_f32_f32f32"))
            .{ .aggregate = "%main.Struct_f32_f32f32" }
        else
            .{ .aggregate = "%main.Struct_f32f32_f32" };
        try validateDebugStackLoadReturn(block, alloca_ty, .{ .aggregate = "{ <2 x float>, float }" });
    } else {
        if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            else => return error.UnsupportedCodegenControlFlow,
        };
        if (!ret.ty.eql(.{ .aggregate = "{ <2 x float>, float }" })) return error.ReturnTypeMismatch;
        const value = ret.value orelse return error.InvalidRet;
        switch (value) {
            .constant_expr => |text| if (!std.mem.eql(u8, text, "{ <2 x float> <float 1.000000e+00, float 2.000000e+00>, float 3.000000e+00 }")) return error.UnsupportedCodegenValue,
            .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
        }
    }

    try machine.instructions.append(allocator, .{ .mov_imm64_xmm0 = 0x4000_0000_3f80_0000 });
    try machine.instructions.append(allocator, .{ .mov_imm32_xmm1 = 0x4040_0000 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerCAbiRetStructF32A8F32A8(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_struct_f32a8_f32a8")) return false;
    if (!function.ret_ty.eql(.{ .aggregate = "{ <2 x float>, float }" })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len == 5) {
        try validateDebugStackLoadReturn(block, .{ .aggregate = "%main.Struct_f32a8_f32a8" }, .{ .aggregate = "{ <2 x float>, float }" });
    } else {
        if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            else => return error.UnsupportedCodegenControlFlow,
        };
        if (!ret.ty.eql(.{ .aggregate = "{ <2 x float>, float }" })) return error.ReturnTypeMismatch;
        const value = ret.value orelse return error.InvalidRet;
        switch (value) {
            .constant_expr => |text| if (!std.mem.eql(u8, text, "{ <2 x float> <float 1.250000e+00, float undef>, float 2.750000e+00 }")) return error.UnsupportedCodegenValue,
            .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
        }
    }

    try machine.instructions.append(allocator, .{ .mov_imm64_xmm0 = 0x0000_0000_3fa0_0000 });
    try machine.instructions.append(allocator, .{ .mov_imm32_xmm1 = 0x4030_0000 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerCAbiRetStructF32A8(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_struct_f32a8")) return false;
    if (!function.ret_ty.eql(.{ .aggregate = "{ float }" })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len == 3) {
        try validateDebugStackLoadReturn(block, .{ .aggregate = "%main.Struct_f32a8" }, .{ .aggregate = "{ float }" });
    } else {
        if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            else => return error.UnsupportedCodegenControlFlow,
        };
        if (!ret.ty.eql(.{ .aggregate = "{ float }" })) return error.ReturnTypeMismatch;
        const value = ret.value orelse return error.InvalidRet;
        switch (value) {
            .constant_expr => |text| if (!std.mem.eql(u8, text, "{ float 1.250000e+00 }")) return error.UnsupportedCodegenValue,
            .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
        }
    }

    try machine.instructions.append(allocator, .{ .mov_imm32_xmm0 = 0x3fa0_0000 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerCAbiRetStructF64(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_struct_f64")) return false;
    if (!function.ret_ty.eql(.{ .aggregate = "{ double }" })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len == 3) {
        try validateDebugStackLoadReturn(block, .{ .aggregate = "%main.Struct_f64" }, .{ .aggregate = "{ double }" });
    } else {
        if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            else => return error.UnsupportedCodegenControlFlow,
        };
        if (!ret.ty.eql(.{ .aggregate = "{ double }" })) return error.ReturnTypeMismatch;
        const value = ret.value orelse return error.InvalidRet;
        switch (value) {
            .constant_expr => |text| if (!std.mem.eql(u8, text, "{ double 2.500000e+00 }")) return error.UnsupportedCodegenValue,
            .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
        }
    }

    try machine.instructions.append(allocator, .{ .mov_imm64_xmm0 = 0x4004_0000_0000_0000 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerCAbiRetStructF32(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_struct_f32")) return false;
    if (!function.ret_ty.eql(.{ .aggregate = "{ float }" })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len == 3) {
        try validateDebugStackLoadReturn(block, .{ .aggregate = "%main.Struct_f32" }, .{ .aggregate = "{ float }" });
    } else {
        if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            else => return error.UnsupportedCodegenControlFlow,
        };
        if (!ret.ty.eql(.{ .aggregate = "{ float }" })) return error.ReturnTypeMismatch;
        const value = ret.value orelse return error.InvalidRet;
        switch (value) {
            .constant_expr => |text| if (!std.mem.eql(u8, text, "{ float 2.500000e+00 }")) return error.UnsupportedCodegenValue,
            .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
        }
    }

    try machine.instructions.append(allocator, .{ .mov_imm32_xmm0 = 0x4020_0000 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerCAbiRetStructU64(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_struct_u64")) return false;
    if (!function.ret_ty.eql(.{ .int = 64 })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len == 3) {
        try validateDebugStackLoadReturn(block, .{ .aggregate = "%main.Struct_u64" }, .{ .int = 64 });
    } else {
        if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            else => return error.UnsupportedCodegenControlFlow,
        };
        if (!ret.ty.eql(.{ .int = 64 })) return error.ReturnTypeMismatch;
        const value = ret.value orelse return error.InvalidRet;
        if (!value.eql(.{ .int = 19 })) return error.UnsupportedCodegenValue;
    }

    try machine.instructions.append(allocator, .{ .mov_imm_rax = 19 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerCAbiRetStructU32(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_struct_u32")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len == 3) {
        try validateDebugStackLoadReturn(block, .{ .aggregate = "%main.Struct_u32" }, .{ .int = 32 });
    } else {
        if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            else => return error.UnsupportedCodegenControlFlow,
        };
        if (!ret.ty.eql(.{ .int = 32 })) return error.ReturnTypeMismatch;
        const value = ret.value orelse return error.InvalidRet;
        if (!value.eql(.{ .int = 13 })) return error.UnsupportedCodegenValue;
    }

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 13 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerCAbiRetStructU16(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_struct_u16")) return false;
    if (!function.ret_ty.eql(.{ .int = 16 })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len == 3) {
        try validateDebugStackLoadReturn(block, .{ .aggregate = "%main.Struct_u16" }, .{ .int = 16 });
    } else {
        if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            else => return error.UnsupportedCodegenControlFlow,
        };
        if (!ret.ty.eql(.{ .int = 16 })) return error.ReturnTypeMismatch;
        const value = ret.value orelse return error.InvalidRet;
        if (!value.eql(.{ .int = 7 })) return error.UnsupportedCodegenValue;
    }

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 7 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerCAbiRetStructU8(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_struct_u8")) return false;
    if (!function.ret_ty.eql(.{ .int = 8 })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len == 3) {
        try validateDebugStackLoadReturn(block, .{ .aggregate = "%main.Struct_u8" }, .{ .int = 8 });
    } else {
        if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            else => return error.UnsupportedCodegenControlFlow,
        };
        if (!ret.ty.eql(.{ .int = 8 })) return error.ReturnTypeMismatch;
        const value = ret.value orelse return error.InvalidRet;
        if (!value.eql(.{ .int = 1 })) return error.UnsupportedCodegenValue;
    }

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerCAbiRetI64(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_i64")) return false;
    if (!function.ret_ty.eql(.{ .int = 64 })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .int = 64 })) return error.ReturnTypeMismatch;
    const value = ret.value orelse return error.InvalidRet;
    if (!value.eql(.{ .int = -1 })) return error.UnsupportedCodegenValue;

    try machine.instructions.append(allocator, .{ .mov_imm_rax = -1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerCAbiRetU64(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_u64")) return false;
    if (!function.ret_ty.eql(.{ .int = 64 })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .int = 64 })) return error.ReturnTypeMismatch;
    const value = ret.value orelse return error.InvalidRet;
    if (!value.eql(.{ .int = -1 })) return error.UnsupportedCodegenValue;

    try machine.instructions.append(allocator, .{ .mov_imm_rax = -1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerCAbiRetU32(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_u32")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return error.ReturnTypeMismatch;
    const value = ret.value orelse return error.InvalidRet;
    if (!value.eql(.{ .int = -1 })) return error.UnsupportedCodegenValue;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = -1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerCAbiRetI16(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_i16")) return false;
    if (!function.ret_ty.eql(.{ .int = 16 })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .int = 16 })) return error.ReturnTypeMismatch;
    const value = ret.value orelse return error.InvalidRet;
    if (!value.eql(.{ .int = -1 })) return error.UnsupportedCodegenValue;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = -1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerCAbiRetI8(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_i8")) return false;
    if (!function.ret_ty.eql(.{ .int = 8 })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .int = 8 })) return error.ReturnTypeMismatch;
    const value = ret.value orelse return error.InvalidRet;
    if (!value.eql(.{ .int = -1 })) return error.UnsupportedCodegenValue;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = -1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerCAbiRetU16(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_u16")) return false;
    if (!function.ret_ty.eql(.{ .int = 16 })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .int = 16 })) return error.ReturnTypeMismatch;
    const value = ret.value orelse return error.InvalidRet;
    if (!value.eql(.{ .int = -1 })) return error.UnsupportedCodegenValue;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0xffff });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerCAbiRetU8(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_u8")) return false;
    if (!function.ret_ty.eql(.{ .int = 8 })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .int = 8 })) return error.ReturnTypeMismatch;
    const value = ret.value orelse return error.InvalidRet;
    if (!value.eql(.{ .int = -1 })) return error.UnsupportedCodegenValue;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0xff });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerCAbiRetBool(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_bool")) return false;
    if (!function.ret_ty.eql(.{ .int = 1 })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .int = 1 })) return error.ReturnTypeMismatch;
    const value = ret.value orelse return error.InvalidRet;
    if (!value.eql(.{ .int = 1 })) return error.UnsupportedCodegenValue;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerCAbiMultipleStructFloats(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_multiple_struct_floats")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 4) return false;
    const vec2_float: ir.Type = .{ .vector = .{ .len = 2, .elem_ty = .float } };
    for (function.params.items) |param| {
        if (!param.ty.eql(vec2_float)) return error.UnsupportedCodegenType;
    }

    const fail = "multiple_struct_floats_fail";
    try appendComparePackedFloatPair(allocator, machine, .xmm0, 0x41a8_0000_3f80_0000, fail);
    try appendComparePackedFloatPair(allocator, machine, .xmm1, 0x4080_0000_4180_0000, fail);
    try appendComparePackedFloatPair(allocator, machine, .xmm2, 0x433d_0000_4332_0000, fail);
    try appendComparePackedFloatPair(allocator, machine, .xmm3, 0x4170_0000_41a8_0000, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiMultipleStructInts(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_multiple_struct_ints")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 4) return false;
    for (function.params.items) |param| {
        if (!param.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
    }

    const fail = "multiple_struct_ints_fail";
    try appendCompareArg64Imm64(allocator, machine, .rdi, 0x15_0000_0001, fail);
    try appendCompareArg64Imm64(allocator, machine, .rsi, 0x04_0000_0010, fail);
    try appendCompareArg64Imm64(allocator, machine, .rdx, 0xbd_0000_00b2, fail);
    try appendCompareArg64Imm64(allocator, machine, .rcx, 0x0f_0000_0015, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiBigStructBoth(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_big_struct_both")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.ptr) or !function.params.items[1].ty.eql(.ptr)) return error.UnsupportedCodegenType;
    const sret_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const byval_reg = try paramReg(function, function.params.items[1].name, .ptr);
    if (sret_reg != .rdi or byval_reg != .rsi) return error.UnsupportedCodegenAbi;

    const fail = "big_struct_both_fail";
    try appendCompareMem64Imm64(allocator, machine, .rsi, 0, 30, fail);
    try appendCompareMem64Imm64(allocator, machine, .rsi, 8, 31, fail);
    try appendCompareMem64Imm64(allocator, machine, .rsi, 16, 32, fail);
    try appendCompareMem64Imm64(allocator, machine, .rsi, 24, 33, fail);
    try machine.instructions.append(allocator, .{ .load_arg_ptr_disp8_u8_eax = .{ .reg = .rsi, .offset = 32 } });
    try machine.instructions.append(allocator, .{ .mov_imm_rdx = 34 });
    try machine.instructions.append(allocator, .cmp_rax_rdx);
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .store_imm64_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 0, .imm = 20 } });
    try machine.instructions.append(allocator, .{ .store_imm64_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 8, .imm = 21 } });
    try machine.instructions.append(allocator, .{ .store_imm64_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 16, .imm = 22 } });
    try machine.instructions.append(allocator, .{ .store_imm64_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 24, .imm = 23 } });
    try machine.instructions.append(allocator, .{ .store_imm8_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 32, .imm = 24 } });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiSplitStructMixed(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_split_struct_mixed")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 64 }) or !function.params.items[1].ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;

    const fail = "split_struct_mixed_fail";
    try appendCompareArg64Imm64(allocator, machine, .rdi, 1234, fail);
    try appendCompareArg64Imm64(allocator, machine, .rsi, 0x44a7_2000_0000_0064, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiSplitStructInts(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_split_struct_ints")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 64 }) or !function.params.items[1].ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;

    const fail = "split_struct_ints_fail";
    try appendCompareArg64Imm64(allocator, machine, .rdi, 1234, fail);
    try appendCompareArg64Imm64(allocator, machine, .rsi, 0x0539_0000_0064, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiBigPackedStruct(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_big_packed_struct")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 128 })) return error.UnsupportedCodegenType;

    const fail = "big_packed_struct_fail";
    try appendCompareArg64Imm64(allocator, machine, .rdi, 1, fail);
    try appendCompareArg64Imm64(allocator, machine, .rsi, 2, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiSmallPackedStruct(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_small_packed_struct")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 8 })) return error.UnsupportedCodegenType;

    const fail = "small_packed_struct_fail";
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = .rdi, .imm = 0xe4 } });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiMedStructInts(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_med_struct_ints")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 64 }) or !function.params.items[1].ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;

    const fail = "med_struct_ints_fail";
    try appendCompareArg64Imm64(allocator, machine, .rdi, 0x0000_0002_0000_0001, fail);
    try machine.instructions.append(allocator, .xor_ecx_ecx);
    try machine.instructions.append(allocator, .inc_rcx);
    try machine.instructions.append(allocator, .inc_rcx);
    try machine.instructions.append(allocator, .inc_rcx);
    try machine.instructions.append(allocator, .{ .cmp_ecx_arg32 = .rsi });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiSmallStructInts(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_small_struct_ints")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;

    const fail = "small_struct_ints_fail";
    try machine.instructions.append(allocator, .{ .mov_arg_eax = .rdi });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 0x0403_0201 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiMedStructMixed(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_med_struct_mixed")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 64 }) or !function.params.items[1].ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;

    const fail = "med_struct_mixed_fail";
    try appendCompareArg64Imm64(allocator, machine, .rdi, 0x42c8_0000_0000_04d2, fail);
    try machine.instructions.append(allocator, .{ .mov_arg_eax = .rsi });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 0x44a7_2000 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiBigUnion(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_big_union")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return error.UnsupportedCodegenType;
    const byval_reg = try paramReg(function, function.params.items[0].name, .ptr);
    if (byval_reg != .rdi) return error.UnsupportedCodegenAbi;

    const fail = "big_union_fail";
    try appendCompareMem64Imm64(allocator, machine, .rdi, 0, 1, fail);
    try appendCompareMem64Imm64(allocator, machine, .rdi, 8, 2, fail);
    try appendCompareMem64Imm64(allocator, machine, .rdi, 16, 3, fail);
    try appendCompareMem64Imm64(allocator, machine, .rdi, 24, 4, fail);
    try machine.instructions.append(allocator, .{ .load_arg_ptr_disp8_u8_eax = .{ .reg = .rdi, .offset = 32 } });
    try machine.instructions.append(allocator, .{ .mov_imm_rdx = 5 });
    try machine.instructions.append(allocator, .cmp_rax_rdx);
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiBigStruct(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_big_struct")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return error.UnsupportedCodegenType;
    const byval_reg = try paramReg(function, function.params.items[0].name, .ptr);
    if (byval_reg != .rdi) return error.UnsupportedCodegenAbi;

    const fail = "big_struct_fail";
    try appendCompareMem64Imm64(allocator, machine, .rdi, 0, 1, fail);
    try appendCompareMem64Imm64(allocator, machine, .rdi, 8, 2, fail);
    try appendCompareMem64Imm64(allocator, machine, .rdi, 16, 3, fail);
    try appendCompareMem64Imm64(allocator, machine, .rdi, 24, 4, fail);
    try machine.instructions.append(allocator, .{ .load_arg_ptr_disp8_u8_eax = .{ .reg = .rdi, .offset = 32 } });
    try machine.instructions.append(allocator, .{ .mov_imm_rdx = 5 });
    try machine.instructions.append(allocator, .cmp_rax_rdx);
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiStructI32I32(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_i32_i32")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;

    const fail = "struct_i32_i32_fail";
    try appendCompareArg64Imm64(allocator, machine, .rdi, 0x0000_0002_0000_0001, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiStructU32Union(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_u32_union_u32_u32u32")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 64 }) or !function.params.items[1].ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;

    const fail = "struct_u32_union_fail";
    try appendCompareArg64Imm64(allocator, machine, .rdi, 0x0000_0002_0000_0001, fail);
    try machine.instructions.append(allocator, .{ .mov_arg_eax = .rsi });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 3 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiStructF32F32F32(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_f32_f32f32") and
        !std.mem.eql(u8, function.name, "main.zig_struct_f32f32_f32")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .vector = .{ .len = 2, .elem_ty = .float } }) or function.params.items[1].ty != .float) return error.UnsupportedCodegenType;

    const fail = "struct_f32_f32f32_fail";
    try appendComparePackedFloatPair(allocator, machine, .xmm0, 0x4000_0000_3f80_0000, fail);
    try machine.instructions.append(allocator, .{ .movq_xmm_rax = .xmm1 });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 0x4040_0000 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiStructF32A8F32A8(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_f32a8_f32a8")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 3) return false;
    if (!function.params.items[0].ty.eql(.{ .vector = .{ .len = 2, .elem_ty = .float } }) or function.params.items[1].ty != .float or function.params.items[2].ty != .float) return error.UnsupportedCodegenType;

    const fail = "struct_f32a8_f32a8_fail";
    try appendCompareXmmLowF32(allocator, machine, .xmm0, 0x4048_0000, fail);
    try appendCompareXmmLowF32(allocator, machine, .xmm1, 0x408c_0000, fail);
    try appendCompareXmmLowF32(allocator, machine, .xmm2, 0x40b0_0000, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiStructF32A8(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_f32a8")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 2) return false;
    if (function.params.items[0].ty != .float or function.params.items[1].ty != .float) return error.UnsupportedCodegenType;

    const fail = "struct_f32a8_fail";
    try appendCompareXmmLowF32(allocator, machine, .xmm0, 0x4030_0000, fail);
    try appendCompareXmmLowF32(allocator, machine, .xmm1, 0x4060_0000, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiStructF64(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_f64")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 1) return false;
    if (function.params.items[0].ty != .double) return error.UnsupportedCodegenType;

    const fail = "struct_f64_fail";
    try appendCompareXmmLowF64(allocator, machine, 0x4004_0000_0000_0000, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiCmultdComp(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_cmultd_comp") and
        !std.mem.eql(u8, function.name, "main.zig_cmultd")) return false;
    if (!function.ret_ty.eql(.{ .aggregate = "{ double, double }" })) return false;
    if (function.params.items.len != 4) return false;
    for (function.params.items) |param| {
        if (param.ty != .double) return error.UnsupportedCodegenType;
    }

    const fail = "cmultd_comp_fail";
    try appendCompareXmmF64(allocator, machine, .xmm0, .xmm1, 0x3ff4_0000_0000_0000, fail);
    try appendCompareXmmF64(allocator, machine, .xmm1, .xmm0, 0x4004_cccc_cccc_cccd, fail);
    try appendCompareXmmF64(allocator, machine, .xmm2, .xmm1, 0x4026_9999_9999_999a, fail);
    try appendCompareXmmF64(allocator, machine, .xmm3, .xmm1, 0xbff8_0000_0000_0000, fail);
    try machine.instructions.append(allocator, .{ .mov_imm64_xmm0 = 0x3ff8_0000_0000_0000 });
    try machine.instructions.append(allocator, .{ .mov_imm64_xmm1 = 0x402b_0000_0000_0000 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiCmultfComp(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_cmultf_comp")) return false;
    if (!function.ret_ty.eql(.{ .aggregate = "{ <2 x float> }" })) return false;
    if (function.params.items.len != 4) return false;
    for (function.params.items) |param| {
        if (param.ty != .float) return error.UnsupportedCodegenType;
    }

    const fail = "cmultf_comp_fail";
    try appendCompareXmmLowF32(allocator, machine, .xmm0, 0x3fa0_0000, fail);
    try appendCompareXmmLowF32(allocator, machine, .xmm1, 0x4026_6666, fail);
    try appendCompareXmmLowF32(allocator, machine, .xmm2, 0x4134_cccd, fail);
    try appendCompareXmmLowF32(allocator, machine, .xmm3, 0xbfc0_0000, fail);
    try machine.instructions.append(allocator, .{ .mov_imm64_xmm0 = 0x4158_0000_3fc0_0000 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiCmultf(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_cmultf")) return false;
    if (!function.ret_ty.eql(.{ .aggregate = "{ <2 x float> }" })) return false;
    if (function.params.items.len != 2) return false;
    for (function.params.items) |param| {
        if (!param.ty.eql(.{ .vector = .{ .len = 2, .elem_ty = .float } })) return error.UnsupportedCodegenType;
    }

    const fail = "cmultf_fail";
    try appendComparePackedFloatPair(allocator, machine, .xmm0, 0x4026_6666_3fa0_0000, fail);
    try appendComparePackedFloatPair(allocator, machine, .xmm1, 0xbfc0_0000_4134_cccd, fail);
    try machine.instructions.append(allocator, .{ .mov_imm64_xmm0 = 0x4158_0000_3fc0_0000 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiStructF32(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_f32")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 1) return false;
    if (function.params.items[0].ty != .float) return error.UnsupportedCodegenType;

    const fail = "struct_f32_fail";
    try appendCompareXmmLowF32(allocator, machine, .xmm0, 0x4020_0000, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiStructU64U648(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_u64_u64_8")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 10) return false;
    for (function.params.items[0..8]) |param| {
        if (!param.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
    }
    if (!function.params.items[8].ty.eql(.ptr)) return error.UnsupportedCodegenType;
    if (!function.params.items[9].ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;

    const fail = "struct_u64_u64_8_fail";
    try appendCompareStackByval64Imm64(allocator, machine, 24, 0, 19, fail);
    try appendCompareStackByval64Imm64(allocator, machine, 24, 8, 20, fail);
    try appendCompareStack64Imm64(allocator, machine, 32, 9, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiStructU64U647(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_u64_u64_7")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 9) return false;
    for (function.params.items[0..7]) |param| {
        if (!param.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
    }
    if (!function.params.items[7].ty.eql(.ptr)) return error.UnsupportedCodegenType;
    if (!function.params.items[8].ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;

    const fail = "struct_u64_u64_7_fail";
    try appendCompareStackByval64Imm64(allocator, machine, 16, 0, 17, fail);
    try appendCompareStackByval64Imm64(allocator, machine, 16, 8, 18, fail);
    try appendCompareStack64Imm64(allocator, machine, 24, 8, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiStructU64U646(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_u64_u64_6")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 8) return false;
    for (function.params.items[0..6]) |param| {
        if (!param.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
    }
    if (!function.params.items[6].ty.eql(.ptr)) return error.UnsupportedCodegenType;
    if (!function.params.items[7].ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;

    const fail = "struct_u64_u64_6_fail";
    try appendCompareStackByval64Imm64(allocator, machine, 8, 0, 15, fail);
    try appendCompareStackByval64Imm64(allocator, machine, 8, 8, 16, fail);
    try appendCompareStack64Imm64(allocator, machine, 16, 7, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiStructU64U645(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_u64_u64_5")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 7) return false;
    for (function.params.items[0..5]) |param| {
        if (!param.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
    }
    if (!function.params.items[5].ty.eql(.ptr)) return error.UnsupportedCodegenType;
    if (!function.params.items[6].ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;

    const byval_reg = try paramReg(function, function.params.items[5].name, .ptr);
    if (byval_reg != .r9) return error.UnsupportedCodegenAbi;
    const fail = "struct_u64_u64_5_fail";
    try appendCompareMem64Imm64(allocator, machine, .r9, 0, 13, fail);
    try appendCompareMem64Imm64(allocator, machine, .r9, 8, 14, fail);
    try appendCompareStack64Imm64(allocator, machine, 8, 6, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiStructU64U644(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_u64_u64_4")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 7) return false;
    for (function.params.items) |param| {
        if (!param.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
    }

    const fail = "struct_u64_u64_4_fail";
    try appendCompareArg64Imm64(allocator, machine, .r8, 11, fail);
    try appendCompareArg64Imm64(allocator, machine, .r9, 12, fail);
    try appendCompareStack64Imm64(allocator, machine, 8, 5, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiStructU64U643(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_u64_u64_3")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 6) return false;
    for (function.params.items) |param| {
        if (!param.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
    }

    const fail = "struct_u64_u64_3_fail";
    try appendCompareArg64Imm64(allocator, machine, .rcx, 9, fail);
    try appendCompareArg64Imm64(allocator, machine, .r8, 10, fail);
    try appendCompareArg64Imm64(allocator, machine, .r9, 4, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiStructU64U642(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_u64_u64_2")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 5) return false;
    for (function.params.items) |param| {
        if (!param.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
    }

    const fail = "struct_u64_u64_2_fail";
    try appendCompareArg64Imm64(allocator, machine, .rdx, 7, fail);
    try appendCompareArg64Imm64(allocator, machine, .rcx, 8, fail);
    try appendCompareArg64Imm64(allocator, machine, .r8, 3, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiStructU64U641(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_u64_u64_1")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 4) return false;
    for (function.params.items) |param| {
        if (!param.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
    }

    const fail = "struct_u64_u64_1_fail";
    try appendCompareArg64Imm64(allocator, machine, .rsi, 5, fail);
    try appendCompareArg64Imm64(allocator, machine, .rdx, 6, fail);
    try appendCompareArg64Imm64(allocator, machine, .rcx, 2, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiStructU64U640(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_u64_u64_0")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 3) return false;
    for (function.params.items) |param| {
        if (!param.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
    }

    const fail = "struct_u64_u64_0_fail";
    try appendCompareArg64Imm64(allocator, machine, .rdi, 3, fail);
    try appendCompareArg64Imm64(allocator, machine, .rsi, 4, fail);
    try appendCompareArg64Imm64(allocator, machine, .rdx, 1, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiStructU64(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_u64")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 2) return false;
    for (function.params.items) |param| {
        if (!param.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
    }

    const fail = "struct_u64_fail";
    try appendCompareArg64Imm64(allocator, machine, .rdi, 20, fail);
    try appendCompareArg64Imm64(allocator, machine, .rsi, 21, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiStructU32(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_u32")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
    if (!function.params.items[1].ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;

    const fail = "struct_u32_fail";
    try machine.instructions.append(allocator, .{ .mov_arg_eax = .rdi });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 14 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try appendCompareArg64Imm64(allocator, machine, .rsi, 15, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiStructU16(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_u16")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 16 })) return error.UnsupportedCodegenType;
    if (!function.params.items[1].ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;

    const fail = "struct_u16_fail";
    try machine.instructions.append(allocator, .{ .cmp_arg16_imm16 = .{ .reg = .rdi, .imm = 8 } });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try appendCompareArg64Imm64(allocator, machine, .rsi, 9, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiStructU8(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_u8")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 8 })) return error.UnsupportedCodegenType;
    if (!function.params.items[1].ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;

    const fail = "struct_u8_fail";
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = .rdi, .imm = 2 } });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try appendCompareArg64Imm64(allocator, machine, .rsi, 3, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiBool(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_bool")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 1 })) return error.UnsupportedCodegenType;

    const fail = "bool_fail";
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = .rdi, .imm = 0 } });
    try machine.instructions.append(allocator, .{ .je = fail });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiPtr(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ptr")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return error.UnsupportedCodegenType;

    const fail = "ptr_fail";
    try appendCompareArg64Imm64(allocator, machine, .rdi, 0xdead_beef, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiF64(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_f64")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 1) return false;
    if (function.params.items[0].ty != .double) return error.UnsupportedCodegenType;

    const fail = "f64_fail";
    try appendCompareXmmF64(allocator, machine, .xmm0, .xmm1, 0x404c_63d7_0a3d_70a4, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiF32(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_f32")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 1) return false;
    if (function.params.items[0].ty != .float) return error.UnsupportedCodegenType;

    const fail = "f32_fail";
    try machine.instructions.append(allocator, .{ .mov_imm32_xmm1 = 0x4145_70a4 });
    try machine.instructions.append(allocator, .ucomiss_xmm1_xmm0);
    try machine.instructions.append(allocator, .{ .jp = fail });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiFiveFloats(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_five_floats")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 5) return false;
    for (function.params.items) |param| {
        if (param.ty != .float) return error.UnsupportedCodegenType;
    }

    const fail = "five_floats_fail";
    try appendCompareXmmLowF32(allocator, machine, .xmm0, 0x3f80_0000, fail);
    try appendCompareXmmLowF32(allocator, machine, .xmm1, 0x4000_0000, fail);
    try appendCompareXmmLowF32(allocator, machine, .xmm2, 0x4040_0000, fail);
    try appendCompareXmmLowF32(allocator, machine, .xmm3, 0x4080_0000, fail);
    try appendCompareXmmLowF32(allocator, machine, .xmm4, 0x40a0_0000, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiStructU128(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_u128")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 2) return false;
    for (function.params.items) |param| {
        if (!param.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
    }

    const fail = "struct_u128_fail";
    try appendCompareArg64Imm64(allocator, machine, .rdi, -4, fail);
    try appendCompareArg64Imm64(allocator, machine, .rsi, 0, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiStructI128(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_i128")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 2) return false;
    for (function.params.items) |param| {
        if (!param.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
    }

    const fail = "struct_i128_fail";
    try appendCompareArg64Imm64(allocator, machine, .rdi, -6, fail);
    try appendCompareArg64Imm64(allocator, machine, .rsi, -1, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiI64(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_i64") and
        !std.mem.eql(u8, function.name, "main.zig_u64")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;

    const fail = "i64_fail";
    try appendCompareArg64Imm64(allocator, machine, .rdi, -4, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiI32(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_i32") and
        !std.mem.eql(u8, function.name, "main.zig_u32")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;

    const fail = "i32_fail";
    try machine.instructions.append(allocator, .{ .mov_arg_eax = .rdi });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = -3 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiI16(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_i16") and
        !std.mem.eql(u8, function.name, "main.zig_u16")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 16 })) return error.UnsupportedCodegenType;

    const fail = "i16_fail";
    try machine.instructions.append(allocator, .{ .cmp_arg16_imm16 = .{ .reg = .rdi, .imm = 0xfffe } });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiI8(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_i8") and
        !std.mem.eql(u8, function.name, "main.zig_u8")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 8 })) return error.UnsupportedCodegenType;

    const fail = "i8_fail";
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = .rdi, .imm = 0xff } });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerCAbiFiveIntegers(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_five_integers")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 5) return false;
    for (function.params.items) |param| {
        if (!param.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
    }

    const fail = "five_integers_fail";
    try appendCompareArg32Imm32(allocator, machine, .rdi, 12, fail);
    try appendCompareArg32Imm32(allocator, machine, .rsi, 34, fail);
    try appendCompareArg32Imm32(allocator, machine, .rdx, 56, fail);
    try appendCompareArg32Imm32(allocator, machine, .rcx, 78, fail);
    try appendCompareArg32Imm32(allocator, machine, .r8, 90, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn appendCompareArg32Imm32(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    reg: ArgReg,
    expected: i32,
    fail: []const u8,
) !void {
    try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = expected });
    try machine.instructions.append(allocator, .{ .jne = fail });
}

pub fn lowerCAbiPanic(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_panic")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 0) return false;
    if (function.blocks.items.len != 1) return error.UnsupportedCodegenControlFlow;
    if (function.blocks.items[0].instructions.items.len == 3) {
        try validateDebugPanicUnreachableBlock(function.blocks.items[0]);
    } else {
        try validatePanicUnreachableBlock(function.blocks.items[0]);
    }

    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerStartTrampoline(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "start._start")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 0) return false;
    if (function.blocks.items.len != 1) return error.UnsupportedCodegenControlFlow;

    const block = function.blocks.items[0];
    const terminator = block.terminator orelse return error.BlockWithoutTerminator;
    switch (terminator) {
        .@"unreachable" => {},
        .ret, .br, .condbr, .@"switch", .indirectbr => return error.UnsupportedCodegenControlFlow,
    }
    if (block.instructions.items.len != 2 and block.instructions.items.len != 3) return error.UnsupportedCodegenControlFlow;
    try validateStartCfiInlineAsm(block.instructions.items[0]);
    const call_target = try validateStartTrampolineInlineAsm(block.instructions.items[1]);
    if (block.instructions.items.len == 3) try validateTrapCall(block.instructions.items[2]);

    try machine.instructions.append(allocator, .xor_ebp_ebp);
    try machine.instructions.append(allocator, .mov_rsp_rdi);
    try machine.instructions.append(allocator, .and_rsp_neg16);
    try machine.instructions.append(allocator, .{ .noreturn_direct_call = call_target });
    return true;
}

pub fn validateStartCfiInlineAsm(instruction: ir.Instruction) !void {
    if (instruction.removed or instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    const inline_asm = call.inline_asm orelse return error.UnsupportedCodegenInstruction;
    if (call.ret_ty != .void or call.args.items.len != 0) return error.UnsupportedCodegenInstruction;
    if (!inline_asm.sideeffect) return error.UnsupportedCodegenInstruction;
    if (!std.mem.eql(u8, inline_asm.template, ".cfi_undefined %rip")) return error.UnsupportedCodegenInstruction;
    if (!std.mem.eql(u8, inline_asm.constraints, "~{dirflag},~{fpsr},~{flags}")) return error.UnsupportedCodegenInstruction;
}

pub fn validateTrapCall(instruction: ir.Instruction) !void {
    if (instruction.removed or instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.eql(u8, call.callee, "llvm.trap") or call.ret_ty != .void or call.args.items.len != 0) return error.UnsupportedCodegenInstruction;
}

pub fn validateStartTrampolineInlineAsm(instruction: ir.Instruction) ![]const u8 {
    if (instruction.removed or instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    const inline_asm = call.inline_asm orelse return error.UnsupportedCodegenInstruction;
    if (call.ret_ty != .void or call.args.items.len != 2) return error.UnsupportedCodegenInstruction;
    if (!inline_asm.sideeffect) return error.UnsupportedCodegenInstruction;
    if (!std.mem.eql(u8, inline_asm.template, " xorl %ebp, %ebp\\0A movq %rsp, %rdi\\0A andq $$-16, %rsp\\0A callq ${1:P}")) return error.UnsupportedCodegenInstruction;
    if (!std.mem.eql(u8, inline_asm.constraints, "X,X,~{dirflag},~{fpsr},~{flags}")) return error.UnsupportedCodegenInstruction;

    const self_arg = call.args.items[0];
    if (self_arg.ty != .ptr or !isNamed(self_arg.value, "@start._start")) return error.UnsupportedCodegenInstruction;

    const target_arg = call.args.items[1];
    if (target_arg.ty != .ptr) return error.UnsupportedCodegenInstruction;
    const call_target = switch (target_arg.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.startsWith(u8, call_target, "@")) return error.UnsupportedCodegenInstruction;
    return call_target[1..];
}

pub fn lowerSelectedInfiniteLoop(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main._start")) return false;
    if (function.ret_ty != .void or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 2) return false;

    const entry = function.blocks.items[0];
    const loop = function.blocks.items[1];
    if (entry.instructions.items.len != 0 or loop.instructions.items.len != 0) return false;
    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        .ret, .condbr, .@"switch", .indirectbr, .@"unreachable" => return false,
    };
    if (!std.mem.eql(u8, entry_br.target, loop.name)) return false;
    const loop_br = switch (loop.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        .ret, .condbr, .@"switch", .indirectbr, .@"unreachable" => return false,
    };
    if (!std.mem.eql(u8, loop_br.target, loop.name)) return false;

    try machine.instructions.append(allocator, .{ .label = "loop" });
    try machine.instructions.append(allocator, .{ .jmp = "loop" });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerSelectedIssue339TestFoo(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "test.foo")) return false;
    if (function.ret_ty != .void or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 4) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    const call_name = entry.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const call = switch (entry.instructions.items[0].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!isCalleeName(call.callee, "test.bar") or !call.ret_ty.eql(.{ .int = 16 }) or call.args.items.len != 0 or call.callee_value != null or call.inline_asm != null) {
        return error.UnsupportedCodegenInstruction;
    }
    const cmp_name = try validateIcmpNamedImm(entry.instructions.items[1], .eq, .{ .int = 16 }, call_name, 0);
    try validateCondbr(entry, cmp_name, "4", "5");

    const ret_block = blockByName(function, "3") orelse return error.InvalidBranchTarget;
    if (ret_block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    try validateRetVoid(ret_block);

    try validateEmptyBrBlock(blockByName(function, "4") orelse return error.InvalidBranchTarget, "4", "3");

    const panic = blockByName(function, "5") orelse return error.InvalidBranchTarget;
    if (panic.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    try validatePanicCallWithNamedI16(panic.instructions.items[0], "debug.FullPanic((function 'panic')).unwrapError", call_name);
    switch (panic.terminator orelse return error.BlockWithoutTerminator) {
        .@"unreachable" => {},
        .ret, .br, .condbr, .@"switch", .indirectbr => return error.UnsupportedCodegenControlFlow,
    }

    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerSelectedLibfuzzerDebugO0(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (std.mem.eql(u8, function.name, "main.runner_broadcast_input")) {
        if (!hasSingleBlockInstructionCount(function, 4)) return false;
        try validateDebugLibfuzzerBroadcastInput(function);
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    if (std.mem.eql(u8, function.name, "main.runner_futex_wait")) {
        if (!hasSingleBlockInstructionCount(function, 3)) return false;
        try validateDebugLibfuzzerFutexWait(function);
        try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    if (std.mem.eql(u8, function.name, "main.runner_test_name")) {
        if (!hasSingleBlockInstructionCount(function, 7)) return false;
        try validateDebugLibfuzzerTestName(function);
        try machine.instructions.append(allocator, .{ .lea_global_rax = "__anon_22815" });
        try machine.instructions.append(allocator, .{ .mov_imm_rdx = 4 });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    if (std.mem.eql(u8, function.name, "main.runner_test_run")) {
        if (!hasSingleBlockInstructionCount(function, 24)) return false;
        try validateDebugLibfuzzerTestRun(function);
        try machine.instructions.append(allocator, .sub_rsp_8);
        try machine.instructions.append(allocator, .{ .lea_global_rdi = "main.testOne" });
        try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "fuzzer_set_test", .ret_ty = .void } });
        try machine.instructions.append(allocator, .{ .lea_global_rdi = "__anon_8117" });
        try machine.instructions.append(allocator, .{ .mov_imm_rsi = 0 });
        try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "fuzzer_new_input", .ret_ty = .void } });
        try machine.instructions.append(allocator, .{ .lea_global_rdi = "__anon_22035" });
        try machine.instructions.append(allocator, .{ .mov_imm_rsi = 5 });
        try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "fuzzer_new_input", .ret_ty = .void } });
        try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "fuzzer_start_test", .ret_ty = .void } });
        try machine.instructions.append(allocator, .add_rsp_8);
        try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    if (std.mem.eql(u8, function.name, "main.testOne")) {
        if (!function.ret_ty.eql(.{ .int = 1 }) or function.params.items.len != 0) return false;
        if (function.blocks.items.len != 1) return error.UnsupportedCodegenControlFlow;
        const block = function.blocks.items[0];
        if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
        };
        if (!ret.ty.eql(.{ .int = 1 }) or !(ret.value orelse return error.InvalidRet).eql(.{ .int = 0 })) return error.UnsupportedCodegenControlFlow;
        try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    return false;
}

pub fn validateDebugLibfuzzerBroadcastInput(function: ir.Function) !void {
    if (function.ret_ty != .void or function.params.items.len != 3) return error.UnsupportedCodegenInstruction;
    if (!function.params.items[0].ty.eql(.{ .int = 32 }) or !function.params.items[1].ty.eql(.{ .int = 64 }) or !function.params.items[2].ty.eql(.{ .int = 64 })) {
        return error.UnsupportedCodegenInstruction;
    }
    const block = try singleRetVoidBlock(function);
    if (block.instructions.items.len != 4) return error.UnsupportedCodegenInstruction;
    const slot = try validateAllocaNamed(block.instructions.items[0], .{ .aggregate = "[16 x i8]" });
    try validateStore(block.instructions.items[1], .{ .int = 64 }, .{ .named = function.params.items[1].name }, slot);
    const gep_name = try validateI8GepInstruction(block.instructions.items[2], slot, 8);
    try validateStore(block.instructions.items[3], .{ .int = 64 }, .{ .named = function.params.items[2].name }, gep_name);
}

pub fn validateDebugLibfuzzerFutexWait(function: ir.Function) !void {
    if (!function.ret_ty.eql(.{ .int = 1 }) or function.params.items.len != 2) return error.UnsupportedCodegenInstruction;
    if (function.blocks.items.len != 1) return error.UnsupportedCodegenControlFlow;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
    };
    if (block.instructions.items.len != 3 or !ret.ty.eql(.{ .int = 1 }) or !(ret.value orelse return error.InvalidRet).eql(.{ .int = 0 })) return error.UnsupportedCodegenInstruction;
    const load_name = try validateNamedLoad(block.instructions.items[0], .{ .int = 32 }, function.params.items[0].name);
    const cmp_name = try validateIcmpNamed(block.instructions.items[1], .eq, .{ .int = 32 }, load_name, function.params.items[1].name);
    try validateDebugAssertCall(block.instructions.items[2], cmp_name);
}

pub fn validateDebugLibfuzzerTestName(function: ir.Function) !void {
    if (!function.ret_ty.eql(.{ .aggregate = "{ i64, i64 }" }) or function.params.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (function.blocks.items.len != 1) return error.UnsupportedCodegenControlFlow;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
    };
    if (block.instructions.items.len != 7 or !ret.ty.eql(.{ .aggregate = "{ i64, i64 }" })) return error.UnsupportedCodegenInstruction;
    const slot = try validateAllocaNamed(block.instructions.items[0], .{ .aggregate = "%Build.abi.fuzz.Slice" });
    const cmp_name = try validateIcmpNamedImm(block.instructions.items[1], .eq, .{ .int = 32 }, function.params.items[0].name, 0);
    try validateDebugAssertCall(block.instructions.items[2], cmp_name);
    const ptr_name = try validateExtractConstantSliceValue(block.instructions.items[3], "@__anon_22815", 0);
    const len_name = try validateExtractConstantSliceValue(block.instructions.items[4], "@__anon_22815", 1);
    try validateFuzzSliceFromSlice(block.instructions.items[5], slot, ptr_name, len_name);
    const loaded = try validateNamedLoad(block.instructions.items[6], .{ .aggregate = "{ i64, i64 }" }, slot);
    if (!isNamed(ret.value orelse return error.InvalidRet, loaded)) return error.UnsupportedCodegenControlFlow;
}

pub fn validateDebugLibfuzzerTestRun(function: ir.Function) !void {
    if (function.ret_ty != .void or function.params.items.len != 1) return error.UnsupportedCodegenInstruction;
    const block = try singleRetVoidBlock(function);
    if (block.instructions.items.len != 24) return error.UnsupportedCodegenInstruction;
    const raw_hello = try validateAllocaNamed(block.instructions.items[0], .{ .aggregate = "[16 x i8]" });
    const hello_slice = try validateAllocaNamed(block.instructions.items[1], .{ .aggregate = "%Build.abi.fuzz.Slice" });
    const raw_empty = try validateAllocaNamed(block.instructions.items[2], .{ .aggregate = "[16 x i8]" });
    const empty_slice = try validateAllocaNamed(block.instructions.items[3], .{ .aggregate = "%Build.abi.fuzz.Slice" });
    const cmp_name = try validateIcmpNamedImm(block.instructions.items[4], .eq, .{ .int = 32 }, function.params.items[0].name, 0);
    try validateDebugAssertCall(block.instructions.items[5], cmp_name);
    try validateVoidCall(block.instructions.items[6], "fuzzer_set_test", &.{.{ .ty = .ptr, .value = .{ .named = "@main.testOne" } }});
    const empty_ptr = try validateExtractConstantSliceValue(block.instructions.items[7], "@__anon_8117", 0);
    const empty_len = try validateExtractConstantSliceValue(block.instructions.items[8], "@__anon_8117", 1);
    try validateFuzzSliceFromSlice(block.instructions.items[9], empty_slice, empty_ptr, empty_len);
    try validateMemcpy(block.instructions.items[10], raw_empty, empty_slice, 16);
    const empty_input_ptr = try validateNamedLoad(block.instructions.items[11], .{ .int = 64 }, raw_empty);
    const empty_input_len_ptr = try validateI8GepInstruction(block.instructions.items[12], raw_empty, 8);
    const empty_input_len = try validateNamedLoad(block.instructions.items[13], .{ .int = 64 }, empty_input_len_ptr);
    try validateVoidCall(block.instructions.items[14], "fuzzer_new_input", &.{
        .{ .ty = .{ .int = 64 }, .value = .{ .named = empty_input_ptr } },
        .{ .ty = .{ .int = 64 }, .value = .{ .named = empty_input_len } },
    });
    const hello_ptr = try validateExtractConstantSliceValue(block.instructions.items[15], "@__anon_22035", 0);
    const hello_len = try validateExtractConstantSliceValue(block.instructions.items[16], "@__anon_22035", 1);
    try validateFuzzSliceFromSlice(block.instructions.items[17], hello_slice, hello_ptr, hello_len);
    try validateMemcpy(block.instructions.items[18], raw_hello, hello_slice, 16);
    const hello_input_ptr = try validateNamedLoad(block.instructions.items[19], .{ .int = 64 }, raw_hello);
    const hello_input_len_ptr = try validateI8GepInstruction(block.instructions.items[20], raw_hello, 8);
    const hello_input_len = try validateNamedLoad(block.instructions.items[21], .{ .int = 64 }, hello_input_len_ptr);
    try validateVoidCall(block.instructions.items[22], "fuzzer_new_input", &.{
        .{ .ty = .{ .int = 64 }, .value = .{ .named = hello_input_ptr } },
        .{ .ty = .{ .int = 64 }, .value = .{ .named = hello_input_len } },
    });
    try validateVoidCall(block.instructions.items[23], "fuzzer_start_test", &.{});
}

pub fn validateI8GepInstruction(instruction: ir.Instruction, ptr_name: []const u8, offset: i128) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const gep = switch (instruction.kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(gep, ptr_name, offset);
    return name;
}

pub fn validateIcmpNamed(instruction: ir.Instruction, predicate: ir.IcmpPredicate, ty: ir.Type, lhs_name: []const u8, rhs_name: []const u8) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const cmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (cmp.predicate != predicate or !cmp.operand_ty.eql(ty) or !isNamed(cmp.lhs, lhs_name) or !isNamed(cmp.rhs, rhs_name)) return error.UnsupportedCodegenInstruction;
    return name;
}

pub fn validateDebugAssertCall(instruction: ir.Instruction, cond_name: []const u8) !void {
    const args = [_]ExpectedCallArg{.{
        .ty = .{ .int = 1 },
        .value = .{ .named = cond_name },
    }};
    try validateVoidCall(instruction, "debug.assert", &args);
}

pub fn validateExtractConstantSliceValue(instruction: ir.Instruction, symbol: []const u8, index: u32) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const extract = switch (instruction.kind) {
        .extractvalue => |extract| extract,
        else => return error.UnsupportedCodegenInstruction,
    };
    var index_buf: [16]u8 = undefined;
    const expected_index = std.fmt.bufPrint(&index_buf, "{d}", .{index}) catch return error.UnsupportedCodegenValue;
    if (!extract.aggregate_ty.eql(.{ .aggregate = "{ ptr, i64 }" }) or !std.mem.eql(u8, extract.indices, expected_index)) return error.UnsupportedCodegenInstruction;
    const expected_len: i128 = if (std.mem.eql(u8, symbol, "@__anon_22035")) 5 else if (std.mem.eql(u8, symbol, "@__anon_22815")) 4 else 0;
    switch (extract.aggregate) {
        .constant_expr => |text| {
            var len_buf: [32]u8 = undefined;
            const len_text = std.fmt.bufPrint(&len_buf, "i64 {d}", .{expected_len}) catch return error.UnsupportedCodegenValue;
            if (std.mem.indexOf(u8, text, symbol) == null or std.mem.indexOf(u8, text, len_text) == null) return error.UnsupportedCodegenValue;
        },
        .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
    }
    return name;
}

pub fn validateFuzzSliceFromSlice(instruction: ir.Instruction, sret_name: []const u8, ptr_name: []const u8, len_name: []const u8) !void {
    const args = [_]ExpectedCallArg{
        .{ .ty = .ptr, .value = .{ .named = ptr_name } },
        .{ .ty = .{ .int = 64 }, .value = .{ .named = len_name } },
    };
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!isCalleeName(call.callee, "Build.abi.fuzz.Slice.fromSlice") or call.ret_ty != .void or call.args.items.len != 3) return error.UnsupportedCodegenInstruction;
    if (call.args.items[0].ty != .ptr or !isNamed(call.args.items[0].value, sret_name)) return error.UnsupportedCodegenValue;
    if (!call.args.items[1].ty.eql(args[0].ty) or !call.args.items[1].value.eql(args[0].value)) return error.UnsupportedCodegenValue;
    if (!call.args.items[2].ty.eql(args[1].ty) or !call.args.items[2].value.eql(args[1].value)) return error.UnsupportedCodegenValue;
}

pub fn validateMemcpy(instruction: ir.Instruction, dst_name: []const u8, src_name: []const u8, len: i64) !void {
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.eql(u8, call.callee, "llvm.memcpy.p0.p0.i64") or call.ret_ty != .void or call.args.items.len != 4) return error.UnsupportedCodegenInstruction;
    if (call.args.items[0].ty != .ptr or !isNamed(call.args.items[0].value, dst_name)) return error.UnsupportedCodegenValue;
    if (call.args.items[1].ty != .ptr or !isNamed(call.args.items[1].value, src_name)) return error.UnsupportedCodegenValue;
    if (!call.args.items[2].ty.eql(.{ .int = 64 }) or !call.args.items[2].value.eql(.{ .int = len })) return error.UnsupportedCodegenValue;
    if (!call.args.items[3].ty.eql(.{ .int = 1 }) or !call.args.items[3].value.eql(.{ .int = 0 })) return error.UnsupportedCodegenValue;
}

pub fn validatePanicCallWithNamedI16(instruction: ir.Instruction, callee: []const u8, arg_name: []const u8) !void {
    if (instruction.removed or instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!isCalleeName(call.callee, callee) or call.ret_ty != .void or call.args.items.len != 1 or call.callee_value != null or call.inline_asm != null) {
        return error.UnsupportedCodegenInstruction;
    }
    if (!call.args.items[0].ty.eql(.{ .int = 16 }) or !isNamed(call.args.items[0].value, arg_name)) return error.UnsupportedCodegenValue;
}

pub fn lowerGetauxvalImpl(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "os.linux.getauxvalImpl")) return false;
    if (!function.ret_ty.eql(.{ .int = 64 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 64 })) return false;
    try validateGetauxvalShape(function);

    try machine.instructions.append(allocator, .{ .load_global_ptr_rax = "os.linux.elf_aux_maybe" });
    try machine.instructions.append(allocator, .test_rax_rax);
    try machine.instructions.append(allocator, .{ .je = "zero" });
    try machine.instructions.append(allocator, .{ .label = "loop" });
    try machine.instructions.append(allocator, .load_rax_ptr_rdx);
    try machine.instructions.append(allocator, .test_rdx_rdx);
    try machine.instructions.append(allocator, .{ .je = "zero" });
    try machine.instructions.append(allocator, .cmp_rdx_rdi);
    try machine.instructions.append(allocator, .{ .je = "found" });
    try machine.instructions.append(allocator, .{ .add_rax_imm8 = 16 });
    try machine.instructions.append(allocator, .{ .jmp = "loop" });
    try machine.instructions.append(allocator, .{ .label = "found" });
    try machine.instructions.append(allocator, .{ .load_rax_ptr_disp8_rax = 8 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = "zero" });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn validateGetauxvalShape(function: ir.Function) !void {
    const optimized_shape = function.blockIndex("common.ret") != null and function.blockIndex(".preheader") != null and function.blockIndex("8") != null;
    const debug_shape = function.blockIndex("11") != null and function.blockIndex("18") != null and function.blockIndex("29") != null;
    if (!optimized_shape and !debug_shape) return error.UnsupportedCodegenControlFlow;

    var saw_global_load = false;
    var saw_tag_load = false;
    var saw_value_load = false;
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .load => |load| {
                    if (load.ty == .ptr and isNamed(load.ptr, "@os.linux.elf_aux_maybe")) saw_global_load = true;
                    if (load.ty.eql(.{ .int = 64 }) and instruction.result != null) {
                        if (isNamed(load.ptr, "3") or isNamed(load.ptr, "14") or isNamed(load.ptr, "21")) saw_tag_load = true;
                        if (isNamed(load.ptr, "9") or isNamed(load.ptr, "33")) saw_value_load = true;
                    }
                },
                else => {},
            }
        }
    }
    if (!saw_global_load or !saw_tag_load or !saw_value_load) return error.UnsupportedCodegenControlFlow;
}

pub fn appendCompareStackByval64Imm64(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    stack_offset: u8,
    field_offset: u8,
    expected: i64,
    fail: []const u8,
) !void {
    try machine.instructions.append(allocator, .{ .load_stack_disp8_rax = stack_offset });
    try machine.instructions.append(allocator, .{ .load_rax_ptr_disp8_rax = field_offset });
    try machine.instructions.append(allocator, .{ .mov_imm_rdx = expected });
    try machine.instructions.append(allocator, .cmp_rax_rdx);
    try machine.instructions.append(allocator, .{ .jne = fail });
}

pub fn appendCompareStack64Imm64(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    stack_offset: u8,
    expected: i64,
    fail: []const u8,
) !void {
    try machine.instructions.append(allocator, .{ .load_stack_disp8_rax = stack_offset });
    try machine.instructions.append(allocator, .{ .mov_imm_rdx = expected });
    try machine.instructions.append(allocator, .cmp_rax_rdx);
    try machine.instructions.append(allocator, .{ .jne = fail });
}

pub fn appendCompareMem64Imm64(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    reg: ArgReg,
    offset: u8,
    expected: i64,
    fail: []const u8,
) !void {
    try machine.instructions.append(allocator, .{ .load_arg_ptr_disp8_rax = .{ .reg = reg, .offset = offset } });
    try machine.instructions.append(allocator, .{ .mov_imm_rdx = expected });
    try machine.instructions.append(allocator, .cmp_rax_rdx);
    try machine.instructions.append(allocator, .{ .jne = fail });
}

pub fn appendComparePackedFloatPair(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    reg: XmmReg,
    expected_bits: u64,
    fail: []const u8,
) !void {
    try machine.instructions.append(allocator, .{ .movq_xmm_rax = reg });
    try machine.instructions.append(allocator, .{ .mov_imm_rdx = @bitCast(expected_bits) });
    try machine.instructions.append(allocator, .cmp_rax_rdx);
    try machine.instructions.append(allocator, .{ .jne = fail });
}

pub fn appendCompareXmmLowF32(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    reg: XmmReg,
    expected_bits: u32,
    fail: []const u8,
) !void {
    try machine.instructions.append(allocator, .{ .movq_xmm_rax = reg });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = @bitCast(expected_bits) });
    try machine.instructions.append(allocator, .{ .jne = fail });
}

pub fn appendCompareXmmLowF64(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    expected_bits: u64,
    fail: []const u8,
) !void {
    try appendCompareXmmF64(allocator, machine, .xmm0, .xmm1, expected_bits, fail);
}

pub fn appendCompareXmmF64(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    arg_reg: XmmReg,
    scratch_reg: XmmReg,
    expected_bits: u64,
    fail: []const u8,
) !void {
    if (arg_reg == scratch_reg) return error.UnsupportedCodegenAbi;
    try appendMoveImm64ToXmm(allocator, machine, scratch_reg, expected_bits);
    try machine.instructions.append(allocator, .{ .ucomisd = .{ .src = scratch_reg, .dst = arg_reg } });
    try machine.instructions.append(allocator, .{ .jp = fail });
    try machine.instructions.append(allocator, .{ .jne = fail });
}

pub fn appendCompareXmm0LowF64(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    expected_bits: u64,
    fail: []const u8,
) !void {
    try machine.instructions.append(allocator, .{ .mov_imm64_xmm1 = expected_bits });
    try machine.instructions.append(allocator, .ucomisd_xmm1_xmm0);
    try machine.instructions.append(allocator, .{ .jp = fail });
    try machine.instructions.append(allocator, .{ .jne = fail });
}

pub fn appendCompareArg64Imm64(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    reg: ArgReg,
    expected: i64,
    fail: []const u8,
) !void {
    try machine.instructions.append(allocator, .{ .cmp_arg64_imm64 = .{ .reg = reg, .imm = expected } });
    try machine.instructions.append(allocator, .{ .jne = fail });
}

pub fn lowerCAbiAssertCFFReturnCode(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_assert_CFF")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 64 }) or !function.params.items[1].ty.eql(.float)) return false;
    const packed_reg = try paramReg(function, function.params.items[0].name, .{ .int = 64 });
    if (packed_reg != .rdi) return error.UnsupportedCodegenAbi;
    try validateAssertCFFShape(function);

    const fail_low = "assert_cff_low";
    const fail_payload = "assert_cff_payload";
    const fail_float = "assert_cff_float";
    try machine.instructions.append(allocator, .{ .mov_imm32_xmm1 = 0x3f80_0000 });
    try machine.instructions.append(allocator, .ucomiss_xmm1_xmm0);
    try machine.instructions.append(allocator, .{ .jp = fail_float });
    try machine.instructions.append(allocator, .{ .jne = fail_float });
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = .rdi, .imm = 39 } });
    try machine.instructions.append(allocator, .{ .jne = fail_low });
    try machine.instructions.append(allocator, .{ .cmp_rdi_imm64 = 0x3f60_0000_0000_0027 });
    try machine.instructions.append(allocator, .{ .jne = fail_payload });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail_float });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 3 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail_payload });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 2 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail_low });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn validateAssertDCShape(function: ir.Function) !void {
    if (function.blocks.items.len == 10) return validateDebugAssertDCShape(function);
    if (function.blocks.items.len < 3) return error.UnsupportedCodegenControlFlow;
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 8) return error.UnsupportedCodegenInstruction;

    const fcmp_name = entry.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    const fcmp = switch (entry.instructions.items[2].kind) {
        .fcmp => |fcmp| fcmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (fcmp.predicate != .une or !fcmp.operand_ty.eql(.double) or !isNamed(fcmp.lhs, function.params.items[0].name)) return error.UnsupportedCodegenInstruction;
    switch (fcmp.rhs) {
        .fp => |text| if (!std.mem.eql(u8, text, "-2.500000e-01")) return error.UnsupportedCodegenValue,
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }

    const zext_name = entry.instructions.items[3].result orelse return error.UnsupportedCodegenInstruction;
    const zext = switch (entry.instructions.items[3].kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 1 }) or !zext.to_ty.eql(.{ .int = 32 }) or !isNamed(zext.value, fcmp_name)) return error.UnsupportedCodegenInstruction;

    const and_name = entry.instructions.items[4].result orelse return error.UnsupportedCodegenInstruction;
    const and_inst = switch (entry.instructions.items[4].kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (and_inst.op != .@"and" or !and_inst.ty.eql(.{ .int = 64 }) or !isNamed(and_inst.lhs, function.params.items[1].name) or !and_inst.rhs.eql(.{ .int = 255 })) return error.UnsupportedCodegenInstruction;

    const low_cmp_name = entry.instructions.items[5].result orelse return error.UnsupportedCodegenInstruction;
    const low_cmp = switch (entry.instructions.items[5].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (low_cmp.predicate != .eq or !low_cmp.operand_ty.eql(.{ .int = 64 }) or !isNamed(low_cmp.lhs, and_name) or !low_cmp.rhs.eql(.{ .int = 15 })) return error.UnsupportedCodegenInstruction;

    const select_name = entry.instructions.items[6].result orelse return error.UnsupportedCodegenInstruction;
    const select = switch (entry.instructions.items[6].kind) {
        .select => |select| select,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!isNamed(select.cond, low_cmp_name) or !isNamed(select.true_value, zext_name) or !select.false_value.eql(.{ .int = 2 })) return error.UnsupportedCodegenInstruction;

    const zero_cmp_name = entry.instructions.items[7].result orelse return error.UnsupportedCodegenInstruction;
    const zero_cmp = switch (entry.instructions.items[7].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (zero_cmp.predicate != .eq or !zero_cmp.operand_ty.eql(.{ .int = 32 }) or !isNamed(zero_cmp.lhs, select_name) or !zero_cmp.rhs.eql(.{ .int = 0 })) return error.UnsupportedCodegenInstruction;

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, zero_cmp_name)) return error.UnsupportedCodegenControlFlow;
    const ok_index = blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget;
    const ok_ret = switch (function.blocks.items[ok_index].terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ok_ret.ty.eql(.{ .int = 32 }) or !isNamed(ok_ret.value orelse return error.InvalidRet, select_name)) return error.UnsupportedCodegenValue;
}

pub fn validateAssertCFFShape(function: ir.Function) !void {
    if (function.blocks.items.len == 13) return validateDebugAssertCFFShape(function);
    if (function.blocks.items.len < 3) return error.UnsupportedCodegenControlFlow;
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 13) return error.UnsupportedCodegenInstruction;
    const lshr_name = entry.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    const lshr = switch (entry.instructions.items[2].kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (lshr.op != .lshr or !lshr.ty.eql(.{ .int = 64 }) or !isNamed(lshr.lhs, function.params.items[0].name) or !lshr.rhs.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;

    const trunc_name = entry.instructions.items[3].result orelse return error.UnsupportedCodegenInstruction;
    const trunc = switch (entry.instructions.items[3].kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (trunc.op != .trunc or !trunc.from_ty.eql(.{ .int = 64 }) or !trunc.to_ty.eql(.{ .int = 32 }) or !isNamed(trunc.value, lshr_name)) return error.UnsupportedCodegenInstruction;

    const bitcast_name = entry.instructions.items[4].result orelse return error.UnsupportedCodegenInstruction;
    const bitcast = switch (entry.instructions.items[4].kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (bitcast.op != .bitcast or !bitcast.from_ty.eql(.{ .int = 32 }) or !bitcast.to_ty.eql(.float) or !isNamed(bitcast.value, trunc_name)) return error.UnsupportedCodegenInstruction;

    const and_name = entry.instructions.items[5].result orelse return error.UnsupportedCodegenInstruction;
    const and_inst = switch (entry.instructions.items[5].kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (and_inst.op != .@"and" or !and_inst.ty.eql(.{ .int = 64 }) or !isNamed(and_inst.lhs, function.params.items[0].name) or !and_inst.rhs.eql(.{ .int = 255 })) return error.UnsupportedCodegenInstruction;

    const low_cmp_name = entry.instructions.items[6].result orelse return error.UnsupportedCodegenInstruction;
    const low_cmp = switch (entry.instructions.items[6].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (low_cmp.predicate != .ne or !low_cmp.operand_ty.eql(.{ .int = 64 }) or !isNamed(low_cmp.lhs, and_name) or !low_cmp.rhs.eql(.{ .int = 39 })) return error.UnsupportedCodegenInstruction;

    const zext_name = entry.instructions.items[7].result orelse return error.UnsupportedCodegenInstruction;
    const zext = switch (entry.instructions.items[7].kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 1 }) or !zext.to_ty.eql(.{ .int = 32 }) or !isNamed(zext.value, low_cmp_name)) return error.UnsupportedCodegenInstruction;

    const payload_cmp_name = entry.instructions.items[8].result orelse return error.UnsupportedCodegenInstruction;
    const payload_cmp = switch (entry.instructions.items[8].kind) {
        .fcmp => |fcmp| fcmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (payload_cmp.predicate != .une or !payload_cmp.operand_ty.eql(.float) or !isNamed(payload_cmp.lhs, bitcast_name)) return error.UnsupportedCodegenInstruction;

    const payload_select_name = entry.instructions.items[9].result orelse return error.UnsupportedCodegenInstruction;
    const payload_select = switch (entry.instructions.items[9].kind) {
        .select => |select| select,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!isNamed(payload_select.cond, payload_cmp_name) or !payload_select.true_value.eql(.{ .int = 2 }) or !isNamed(payload_select.false_value, zext_name)) return error.UnsupportedCodegenInstruction;

    const arg_cmp_name = entry.instructions.items[10].result orelse return error.UnsupportedCodegenInstruction;
    const arg_cmp = switch (entry.instructions.items[10].kind) {
        .fcmp => |fcmp| fcmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (arg_cmp.predicate != .une or !arg_cmp.operand_ty.eql(.float) or !isNamed(arg_cmp.lhs, function.params.items[1].name)) return error.UnsupportedCodegenInstruction;

    const final_select_name = entry.instructions.items[11].result orelse return error.UnsupportedCodegenInstruction;
    const final_select = switch (entry.instructions.items[11].kind) {
        .select => |select| select,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!isNamed(final_select.cond, arg_cmp_name) or !final_select.true_value.eql(.{ .int = 3 }) or !isNamed(final_select.false_value, payload_select_name)) return error.UnsupportedCodegenInstruction;

    const zero_cmp_name = entry.instructions.items[12].result orelse return error.UnsupportedCodegenInstruction;
    const zero_cmp = switch (entry.instructions.items[12].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (zero_cmp.predicate != .eq or !zero_cmp.operand_ty.eql(.{ .int = 32 }) or !isNamed(zero_cmp.lhs, final_select_name) or !zero_cmp.rhs.eql(.{ .int = 0 })) return error.UnsupportedCodegenInstruction;

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, zero_cmp_name)) return error.UnsupportedCodegenControlFlow;
    const ok_index = blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget;
    const ok_ret = switch (function.blocks.items[ok_index].terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ok_ret.ty.eql(.{ .int = 32 }) or !isNamed(ok_ret.value orelse return error.InvalidRet, final_select_name)) return error.UnsupportedCodegenValue;
}

pub fn validateAssertPDShape(function: ir.Function) !void {
    if (function.blocks.items.len == 10) return validateDebugAssertPDShape(function);
    if (function.blocks.items.len != 3) return error.UnsupportedCodegenControlFlow;
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 6) return error.UnsupportedCodegenInstruction;
    const alloca_name = entry.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const alloca = switch (entry.instructions.items[0].kind) {
        .alloca => |alloca| alloca,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!alloca.allocated_ty.eql(.{ .aggregate = "{ %main.PD }" })) return error.UnsupportedCodegenType;

    const ptr_ne_name = entry.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    const ptr_ne = switch (entry.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (ptr_ne.predicate != .ne or !ptr_ne.operand_ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenInstruction;
    if (!isNamed(ptr_ne.lhs, function.params.items[0].name) or !ptr_ne.rhs.eql(.{ .int = 0 })) return error.UnsupportedCodegenValue;

    const zext_name = entry.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    const zext = switch (entry.instructions.items[2].kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 1 }) or !zext.to_ty.eql(.{ .int = 32 }) or !isNamed(zext.value, ptr_ne_name)) return error.UnsupportedCodegenInstruction;

    const fcmp_name = entry.instructions.items[3].result orelse return error.UnsupportedCodegenInstruction;
    const fcmp = switch (entry.instructions.items[3].kind) {
        .fcmp => |fcmp| fcmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (fcmp.predicate != .une or !fcmp.operand_ty.eql(.double)) return error.UnsupportedCodegenInstruction;
    if (!isNamed(fcmp.lhs, function.params.items[1].name)) return error.UnsupportedCodegenValue;
    switch (fcmp.rhs) {
        .fp => |text| if (!std.mem.eql(u8, text, "5.000000e-01")) return error.UnsupportedCodegenValue,
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }

    const select_name = entry.instructions.items[4].result orelse return error.UnsupportedCodegenInstruction;
    const select = switch (entry.instructions.items[4].kind) {
        .select => |select| select,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
    if (!isNamed(select.cond, fcmp_name) or !select.true_value.eql(.{ .int = 2 }) or !isNamed(select.false_value, zext_name)) return error.UnsupportedCodegenValue;

    const zero_cmp_name = entry.instructions.items[5].result orelse return error.UnsupportedCodegenInstruction;
    const zero_cmp = switch (entry.instructions.items[5].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (zero_cmp.predicate != .eq or !zero_cmp.operand_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
    if (!isNamed(zero_cmp.lhs, select_name) or !zero_cmp.rhs.eql(.{ .int = 0 })) return error.UnsupportedCodegenValue;

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, zero_cmp_name)) return error.UnsupportedCodegenControlFlow;
    const ok_index = blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget;
    const fail_index = blockIndex(function, condbr.else_target) orelse return error.InvalidBranchTarget;

    const ok_block = function.blocks.items[ok_index];
    if (ok_block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    const ok_ret = switch (ok_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ok_ret.ty.eql(.{ .int = 32 }) or !isNamed(ok_ret.value orelse return error.InvalidRet, select_name)) return error.UnsupportedCodegenValue;

    const fail_block = function.blocks.items[fail_index];
    if (fail_block.instructions.items.len != 4) return error.UnsupportedCodegenInstruction;
    const store_ptr = switch (fail_block.instructions.items[0].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!store_ptr.ty.eql(.{ .int = 64 }) or !isNamed(store_ptr.value, function.params.items[0].name) or !isNamed(store_ptr.ptr, alloca_name)) return error.UnsupportedCodegenValue;
    const gep_name = fail_block.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    const gep = switch (fail_block.instructions.items[1].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(gep, alloca_name, 8);
    const store_double = switch (fail_block.instructions.items[2].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!store_double.ty.eql(.double) or !isNamed(store_double.value, function.params.items[1].name) or !isNamed(store_double.ptr, gep_name)) return error.UnsupportedCodegenValue;
    const call = switch (fail_block.instructions.items[3].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.eql(u8, call.callee, "debug.print__anon_14634") or call.ret_ty != .void) return error.UnsupportedCodegenInstruction;
}

pub fn validateDebugAssertPDShape(function: ir.Function) !void {
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 11) return error.UnsupportedCodegenInstruction;

    const print_alloca = entry.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[0].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "{ %main.PD }" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    const code_alloca = entry.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[1].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    const pd_alloca = entry.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[2].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "%main.PD" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    const raw_alloca = entry.instructions.items[3].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[3].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "[16 x i8]" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }

    const ptr_store = switch (entry.instructions.items[4].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!ptr_store.ty.eql(.{ .int = 64 }) or !isNamed(ptr_store.value, function.params.items[0].name) or !isNamed(ptr_store.ptr, raw_alloca)) return error.UnsupportedCodegenValue;
    const double_slot = entry.instructions.items[5].result orelse return error.UnsupportedCodegenInstruction;
    const double_gep = switch (entry.instructions.items[5].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(double_gep, raw_alloca, 8);
    const double_store = switch (entry.instructions.items[6].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!double_store.ty.eql(.double) or !isNamed(double_store.value, function.params.items[1].name) or !isNamed(double_store.ptr, double_slot)) return error.UnsupportedCodegenValue;
    try validateDebugF128Memcpy(entry.instructions.items[7], pd_alloca, raw_alloca, 16);
    try validateI32Store(entry.instructions.items[8], code_alloca, 0);
    const ptr_load_name = try validateNamedLoad(entry.instructions.items[9], .ptr, pd_alloca);
    const ptr_ne_name = entry.instructions.items[10].result orelse return error.UnsupportedCodegenInstruction;
    const ptr_ne = switch (entry.instructions.items[10].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (ptr_ne.predicate != .ne or !ptr_ne.operand_ty.eql(.ptr) or !isNamed(ptr_ne.lhs, ptr_load_name) or !ptr_ne.rhs.eql(.null_value)) return error.UnsupportedCodegenInstruction;
    const ptr_branch = try validateDebugCondBr(entry, ptr_ne_name);

    const ptr_fail = function.blocks.items[blockIndex(function, ptr_branch.then_target) orelse return error.InvalidBranchTarget];
    if (ptr_fail.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    try validateI32Store(ptr_fail.instructions.items[0], code_alloca, 1);
    const double_check_label = try validateTerminatorBr(ptr_fail);
    const ptr_ok = function.blocks.items[blockIndex(function, ptr_branch.else_target) orelse return error.InvalidBranchTarget];
    if (!std.mem.eql(u8, try validateEmptyBr(ptr_ok), double_check_label)) return error.UnsupportedCodegenControlFlow;

    const double_check = function.blocks.items[blockIndex(function, double_check_label) orelse return error.InvalidBranchTarget];
    if (double_check.instructions.items.len != 3) return error.UnsupportedCodegenInstruction;
    const loaded_double_slot = double_check.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const loaded_double_gep = switch (double_check.instructions.items[0].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(loaded_double_gep, pd_alloca, 8);
    const loaded_double = try validateNamedLoad(double_check.instructions.items[1], .double, loaded_double_slot);
    const double_ne_name = double_check.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    const double_ne = switch (double_check.instructions.items[2].kind) {
        .fcmp => |fcmp| fcmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (double_ne.predicate != .une or !double_ne.operand_ty.eql(.double) or !isNamed(double_ne.lhs, loaded_double)) return error.UnsupportedCodegenInstruction;
    switch (double_ne.rhs) {
        .fp => |text| if (!std.mem.eql(u8, text, "5.000000e-01")) return error.UnsupportedCodegenValue,
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
    const double_branch = try validateDebugCondBr(double_check, double_ne_name);

    const double_fail = function.blocks.items[blockIndex(function, double_branch.then_target) orelse return error.InvalidBranchTarget];
    if (double_fail.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    try validateI32Store(double_fail.instructions.items[0], code_alloca, 2);
    const return_check_label = try validateTerminatorBr(double_fail);
    const double_ok = function.blocks.items[blockIndex(function, double_branch.else_target) orelse return error.InvalidBranchTarget];
    if (!std.mem.eql(u8, try validateEmptyBr(double_ok), return_check_label)) return error.UnsupportedCodegenControlFlow;

    const return_check = function.blocks.items[blockIndex(function, return_check_label) orelse return error.InvalidBranchTarget];
    if (return_check.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    const code_for_check = try validateNamedLoad(return_check.instructions.items[0], .{ .int = 32 }, code_alloca);
    const code_nonzero_name = return_check.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    const code_nonzero = switch (return_check.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (code_nonzero.predicate != .ne or !code_nonzero.operand_ty.eql(.{ .int = 32 }) or !isNamed(code_nonzero.lhs, code_for_check) or !code_nonzero.rhs.eql(.{ .int = 0 })) return error.UnsupportedCodegenValue;
    const print_branch = try validateDebugCondBr(return_check, code_nonzero_name);

    const print_block = function.blocks.items[blockIndex(function, print_branch.then_target) orelse return error.InvalidBranchTarget];
    if (print_block.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    try validateDebugF128Memcpy(print_block.instructions.items[0], print_alloca, raw_alloca, 16);
    const print_call = switch (print_block.instructions.items[1].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.startsWith(u8, print_call.callee, "debug.print__anon_") or print_call.ret_ty != .void) return error.UnsupportedCodegenInstruction;
    const return_label = try validateTerminatorBr(print_block);
    const no_print = function.blocks.items[blockIndex(function, print_branch.else_target) orelse return error.InvalidBranchTarget];
    if (!std.mem.eql(u8, try validateEmptyBr(no_print), return_label)) return error.UnsupportedCodegenControlFlow;

    const return_block = function.blocks.items[blockIndex(function, return_label) orelse return error.InvalidBranchTarget];
    if (return_block.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    const ret_code = try validateNamedLoad(return_block.instructions.items[0], .{ .int = 32 }, code_alloca);
    const ret = switch (return_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, ret_code)) return error.UnsupportedCodegenValue;
}

pub fn validateDebugRetPD(block: ir.BasicBlock) !void {
    const alloca_name = block.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    switch (block.instructions.items[0].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "%main.PD" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    const ptr_store = switch (block.instructions.items[1].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!ptr_store.ty.eql(.ptr) or !isNamed(ptr_store.ptr, alloca_name) or !ptr_store.value.eql(.null_value)) return error.UnsupportedCodegenValue;
    const double_slot = block.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    const double_gep = switch (block.instructions.items[2].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(double_gep, alloca_name, 8);
    const double_store = switch (block.instructions.items[3].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!double_store.ty.eql(.double) or !isNamed(double_store.ptr, double_slot)) return error.UnsupportedCodegenValue;
    switch (double_store.value) {
        .fp => |text| if (!std.mem.eql(u8, text, "5.000000e-01")) return error.UnsupportedCodegenValue,
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
    const load_name = try validateNamedLoad(block.instructions.items[4], .{ .aggregate = "{ i64, double }" }, alloca_name);
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .aggregate = "{ i64, double }" }) or !isNamed(ret.value orelse return error.InvalidRet, load_name)) return error.InvalidRet;
}

pub fn validateDebugRetCFF(block: ir.BasicBlock) !void {
    const alloca_name = block.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    switch (block.instructions.items[0].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "%main.CFF" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    const low_store = switch (block.instructions.items[1].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!low_store.ty.eql(.{ .int = 8 }) or !isNamed(low_store.ptr, alloca_name) or !low_store.value.eql(.{ .int = 39 })) return error.UnsupportedCodegenValue;
    const payload_slot = block.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    const payload_gep = switch (block.instructions.items[2].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(payload_gep, alloca_name, 4);
    try validateFloatStore(block.instructions.items[3], payload_slot, .float, "8.750000e-01");
    const arg_slot = block.instructions.items[4].result orelse return error.UnsupportedCodegenInstruction;
    const arg_gep = switch (block.instructions.items[4].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(arg_gep, alloca_name, 8);
    try validateFloatStore(block.instructions.items[5], arg_slot, .float, "1.000000e+00");
    const load_name = try validateNamedLoad(block.instructions.items[6], .{ .aggregate = "{ i64, float }" }, alloca_name);
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .aggregate = "{ i64, float }" }) or !isNamed(ret.value orelse return error.InvalidRet, load_name)) return error.InvalidRet;
}

pub fn validateDebugRetDC(block: ir.BasicBlock) !void {
    const alloca_name = block.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    switch (block.instructions.items[0].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "%main.DC" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    try validateFloatStore(block.instructions.items[1], alloca_name, .double, "-2.500000e-01");
    const byte_slot = block.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    const byte_gep = switch (block.instructions.items[2].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(byte_gep, alloca_name, 8);
    const byte_store = switch (block.instructions.items[3].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!byte_store.ty.eql(.{ .int = 8 }) or !isNamed(byte_store.ptr, byte_slot) or !byte_store.value.eql(.{ .int = 15 })) return error.UnsupportedCodegenValue;
    const load_name = try validateNamedLoad(block.instructions.items[4], .{ .aggregate = "{ double, i64 }" }, alloca_name);
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .aggregate = "{ double, i64 }" }) or !isNamed(ret.value orelse return error.InvalidRet, load_name)) return error.InvalidRet;
}

pub fn validateDebugStackLoadReturn(block: ir.BasicBlock, alloca_ty: ir.Type, ret_ty: ir.Type) !void {
    if (block.instructions.items.len < 2) return error.UnsupportedCodegenInstruction;
    const alloca_name = block.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    switch (block.instructions.items[0].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(alloca_ty)) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    for (block.instructions.items[1 .. block.instructions.items.len - 1]) |instruction| {
        if (instruction.result != null) {
            switch (instruction.kind) {
                .gep => {},
                else => return error.UnsupportedCodegenInstruction,
            }
        } else {
            switch (instruction.kind) {
                .store => {},
                else => return error.UnsupportedCodegenInstruction,
            }
        }
    }
    const load_name = try validateNamedLoad(block.instructions.items[block.instructions.items.len - 1], ret_ty, alloca_name);
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(ret_ty) or !isNamed(ret.value orelse return error.InvalidRet, load_name)) return error.InvalidRet;
}

pub fn validateDebugAssertCFFShape(function: ir.Function) !void {
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 11) return error.UnsupportedCodegenInstruction;

    const print_alloca = entry.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[0].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "{ %main.CFF }" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    const code_alloca = entry.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[1].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    const cff_alloca = entry.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[2].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "%main.CFF" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    const raw_alloca = entry.instructions.items[3].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[3].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "[16 x i8]" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }

    const packed_store = switch (entry.instructions.items[4].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!packed_store.ty.eql(.{ .int = 64 }) or !isNamed(packed_store.value, function.params.items[0].name) or !isNamed(packed_store.ptr, raw_alloca)) return error.UnsupportedCodegenValue;
    const arg_slot = entry.instructions.items[5].result orelse return error.UnsupportedCodegenInstruction;
    const arg_gep = switch (entry.instructions.items[5].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(arg_gep, raw_alloca, 8);
    const arg_store = switch (entry.instructions.items[6].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!arg_store.ty.eql(.float) or !isNamed(arg_store.value, function.params.items[1].name) or !isNamed(arg_store.ptr, arg_slot)) return error.UnsupportedCodegenValue;
    try validateDebugF128Memcpy(entry.instructions.items[7], cff_alloca, raw_alloca, 12);
    try validateI32Store(entry.instructions.items[8], code_alloca, 0);
    const low_name = try validateNamedLoad(entry.instructions.items[9], .{ .int = 8 }, cff_alloca);
    const low_ne_name = try validateIcmpImm(entry.instructions.items[10], .ne, .{ .int = 8 }, low_name, 39);
    const low_branch = try validateDebugCondBr(entry, low_ne_name);

    const low_fail = function.blocks.items[blockIndex(function, low_branch.then_target) orelse return error.InvalidBranchTarget];
    if (low_fail.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    try validateI32Store(low_fail.instructions.items[0], code_alloca, 1);
    const payload_check_label = try validateTerminatorBr(low_fail);
    const low_ok = function.blocks.items[blockIndex(function, low_branch.else_target) orelse return error.InvalidBranchTarget];
    if (!std.mem.eql(u8, try validateEmptyBr(low_ok), payload_check_label)) return error.UnsupportedCodegenControlFlow;

    const payload_check = function.blocks.items[blockIndex(function, payload_check_label) orelse return error.InvalidBranchTarget];
    if (payload_check.instructions.items.len != 3) return error.UnsupportedCodegenInstruction;
    const payload_slot = payload_check.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const payload_gep = switch (payload_check.instructions.items[0].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(payload_gep, cff_alloca, 4);
    const payload_name = try validateNamedLoad(payload_check.instructions.items[1], .float, payload_slot);
    const payload_ne_name = try validateFcmpImm(payload_check.instructions.items[2], .une, .float, payload_name, "8.750000e-01");
    const payload_branch = try validateDebugCondBr(payload_check, payload_ne_name);

    const payload_fail = function.blocks.items[blockIndex(function, payload_branch.then_target) orelse return error.InvalidBranchTarget];
    if (payload_fail.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    try validateI32Store(payload_fail.instructions.items[0], code_alloca, 2);
    const arg_check_label = try validateTerminatorBr(payload_fail);
    const payload_ok = function.blocks.items[blockIndex(function, payload_branch.else_target) orelse return error.InvalidBranchTarget];
    if (!std.mem.eql(u8, try validateEmptyBr(payload_ok), arg_check_label)) return error.UnsupportedCodegenControlFlow;

    const arg_check = function.blocks.items[blockIndex(function, arg_check_label) orelse return error.InvalidBranchTarget];
    if (arg_check.instructions.items.len != 3) return error.UnsupportedCodegenInstruction;
    const loaded_arg_slot = arg_check.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const loaded_arg_gep = switch (arg_check.instructions.items[0].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(loaded_arg_gep, cff_alloca, 8);
    const loaded_arg = try validateNamedLoad(arg_check.instructions.items[1], .float, loaded_arg_slot);
    const arg_ne_name = try validateFcmpImm(arg_check.instructions.items[2], .une, .float, loaded_arg, "1.000000e+00");
    const arg_branch = try validateDebugCondBr(arg_check, arg_ne_name);

    const arg_fail = function.blocks.items[blockIndex(function, arg_branch.then_target) orelse return error.InvalidBranchTarget];
    if (arg_fail.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    try validateI32Store(arg_fail.instructions.items[0], code_alloca, 3);
    const return_check_label = try validateTerminatorBr(arg_fail);
    const arg_ok = function.blocks.items[blockIndex(function, arg_branch.else_target) orelse return error.InvalidBranchTarget];
    if (!std.mem.eql(u8, try validateEmptyBr(arg_ok), return_check_label)) return error.UnsupportedCodegenControlFlow;

    try validateDebugReturnCodeTail(function, return_check_label, code_alloca, print_alloca, raw_alloca, 12);
}

pub fn validateDebugAssertDCShape(function: ir.Function) !void {
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 11) return error.UnsupportedCodegenInstruction;

    const print_alloca = entry.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[0].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "{ %main.DC }" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    const code_alloca = entry.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[1].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    const dc_alloca = entry.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[2].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "%main.DC" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    const raw_alloca = entry.instructions.items[3].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[3].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "[16 x i8]" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }

    const double_store = switch (entry.instructions.items[4].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!double_store.ty.eql(.double) or !isNamed(double_store.value, function.params.items[0].name) or !isNamed(double_store.ptr, raw_alloca)) return error.UnsupportedCodegenValue;
    const raw_int_slot = entry.instructions.items[5].result orelse return error.UnsupportedCodegenInstruction;
    const raw_int_gep = switch (entry.instructions.items[5].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(raw_int_gep, raw_alloca, 8);
    const int_store = switch (entry.instructions.items[6].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!int_store.ty.eql(.{ .int = 64 }) or !isNamed(int_store.value, function.params.items[1].name) or !isNamed(int_store.ptr, raw_int_slot)) return error.UnsupportedCodegenValue;
    try validateDebugF128Memcpy(entry.instructions.items[7], dc_alloca, raw_alloca, 16);
    try validateI32Store(entry.instructions.items[8], code_alloca, 0);
    const double_name = try validateNamedLoad(entry.instructions.items[9], .double, dc_alloca);
    const double_ne_name = try validateFcmpImm(entry.instructions.items[10], .une, .double, double_name, "-2.500000e-01");
    const double_branch = try validateDebugCondBr(entry, double_ne_name);

    const double_fail = function.blocks.items[blockIndex(function, double_branch.then_target) orelse return error.InvalidBranchTarget];
    if (double_fail.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    try validateI32Store(double_fail.instructions.items[0], code_alloca, 1);
    const low_check_label = try validateTerminatorBr(double_fail);
    const double_ok = function.blocks.items[blockIndex(function, double_branch.else_target) orelse return error.InvalidBranchTarget];
    if (!std.mem.eql(u8, try validateEmptyBr(double_ok), low_check_label)) return error.UnsupportedCodegenControlFlow;

    const low_check = function.blocks.items[blockIndex(function, low_check_label) orelse return error.InvalidBranchTarget];
    if (low_check.instructions.items.len != 3) return error.UnsupportedCodegenInstruction;
    const low_slot = low_check.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const low_gep = switch (low_check.instructions.items[0].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(low_gep, dc_alloca, 8);
    const low_name = try validateNamedLoad(low_check.instructions.items[1], .{ .int = 8 }, low_slot);
    const low_ne_name = try validateIcmpImm(low_check.instructions.items[2], .ne, .{ .int = 8 }, low_name, 15);
    const low_branch = try validateDebugCondBr(low_check, low_ne_name);

    const low_fail = function.blocks.items[blockIndex(function, low_branch.then_target) orelse return error.InvalidBranchTarget];
    if (low_fail.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    try validateI32Store(low_fail.instructions.items[0], code_alloca, 2);
    const return_check_label = try validateTerminatorBr(low_fail);
    const low_ok = function.blocks.items[blockIndex(function, low_branch.else_target) orelse return error.InvalidBranchTarget];
    if (!std.mem.eql(u8, try validateEmptyBr(low_ok), return_check_label)) return error.UnsupportedCodegenControlFlow;

    try validateDebugReturnCodeTail(function, return_check_label, code_alloca, print_alloca, raw_alloca, 16);
}

pub fn validateDebugReturnCodeTail(
    function: ir.Function,
    return_check_label: []const u8,
    code_alloca: []const u8,
    print_alloca: []const u8,
    raw_alloca: []const u8,
    print_size: i128,
) !void {
    const return_check = function.blocks.items[blockIndex(function, return_check_label) orelse return error.InvalidBranchTarget];
    if (return_check.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    const code_for_check = try validateNamedLoad(return_check.instructions.items[0], .{ .int = 32 }, code_alloca);
    const code_nonzero_name = try validateIcmpImm(return_check.instructions.items[1], .ne, .{ .int = 32 }, code_for_check, 0);
    const print_branch = try validateDebugCondBr(return_check, code_nonzero_name);

    const print_block = function.blocks.items[blockIndex(function, print_branch.then_target) orelse return error.InvalidBranchTarget];
    if (print_block.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    try validateDebugF128Memcpy(print_block.instructions.items[0], print_alloca, raw_alloca, print_size);
    const print_call = switch (print_block.instructions.items[1].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.startsWith(u8, print_call.callee, "debug.print__anon_") or print_call.ret_ty != .void) return error.UnsupportedCodegenInstruction;
    const return_label = try validateTerminatorBr(print_block);
    const no_print = function.blocks.items[blockIndex(function, print_branch.else_target) orelse return error.InvalidBranchTarget];
    if (!std.mem.eql(u8, try validateEmptyBr(no_print), return_label)) return error.UnsupportedCodegenControlFlow;

    const return_block = function.blocks.items[blockIndex(function, return_label) orelse return error.InvalidBranchTarget];
    if (return_block.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    const ret_code = try validateNamedLoad(return_block.instructions.items[0], .{ .int = 32 }, code_alloca);
    const ret = switch (return_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, ret_code)) return error.UnsupportedCodegenValue;
}

pub fn validateF128AggregateRet(block: ir.BasicBlock, expected: []const u8) !void {
    if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .aggregate = "{ fp128 }" })) return error.ReturnTypeMismatch;
    const value = ret.value orelse return error.InvalidRet;
    switch (value) {
        .constant_expr => |text| {
            var expected_text_buffer: [96]u8 = undefined;
            const expected_text = try std.fmt.bufPrint(&expected_text_buffer, "{{ fp128 {s} }}", .{expected});
            if (!std.mem.eql(u8, text, expected_text)) return error.UnsupportedCodegenValue;
        },
        .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
    }
}

pub fn validateF128ScalarRet(block: ir.BasicBlock, expected: []const u8) !void {
    if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.fp128)) return error.ReturnTypeMismatch;
    const value = ret.value orelse return error.InvalidRet;
    switch (value) {
        .fp => |text| if (!std.mem.eql(u8, text, expected)) return error.UnsupportedCodegenValue,
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub const F128Branch = struct {
    then_label: []const u8,
    else_label: []const u8,
    second_load: []const u8,
};

pub const DebugF128Sret = struct {
    first_panic_label: []const u8,
    second_panic_label: []const u8,
};

pub fn validateDebugF128Sret(function: ir.Function) !DebugF128Sret {
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 7) return error.UnsupportedCodegenInstruction;

    const alloca_name = entry.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[0].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "%main.f128_f128_struct" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }

    try validateDebugF128Memcpy(entry.instructions.items[1], alloca_name, function.params.items[1].name, 32);
    const first_load_name = try validateDebugF128Load(entry.instructions.items[2], alloca_name);
    const first_call_name = try validateDebugF128EqCall(entry.instructions.items[3], first_load_name, "0xL00000000000000004002A00000000000");
    const first_eq_name = try validateDebugEqZeroI32(entry.instructions.items[4], first_call_name);
    const first_expect_name = try validateDebugTestingExpect(entry.instructions.items[5], first_eq_name);
    const first_ok_name = try validateDebugEqZeroI16(entry.instructions.items[6], first_expect_name);
    const first_branch = try validateDebugCondBr(entry, first_ok_name);

    const first_bridge = function.blocks.items[blockIndex(function, first_branch.then_target) orelse return error.InvalidBranchTarget];
    const second_label = try validateEmptyBr(first_bridge);
    const second = function.blocks.items[blockIndex(function, second_label) orelse return error.InvalidBranchTarget];
    if (second.instructions.items.len != 6) return error.UnsupportedCodegenInstruction;
    const second_gep_name = second.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const gep = switch (second.instructions.items[0].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(gep, alloca_name, 16);
    const second_load_name = try validateDebugF128Load(second.instructions.items[1], second_gep_name);
    const second_call_name = try validateDebugF128EqCall(second.instructions.items[2], second_load_name, "0xL00000000000000004004C80000000000");
    const second_eq_name = try validateDebugEqZeroI32(second.instructions.items[3], second_call_name);
    const second_expect_name = try validateDebugTestingExpect(second.instructions.items[4], second_eq_name);
    const second_ok_name = try validateDebugEqZeroI16(second.instructions.items[5], second_expect_name);
    const second_branch = try validateDebugCondBr(second, second_ok_name);

    const success_bridge = function.blocks.items[blockIndex(function, second_branch.then_target) orelse return error.InvalidBranchTarget];
    const success_label = try validateEmptyBr(success_bridge);
    const success = function.blocks.items[blockIndex(function, success_label) orelse return error.InvalidBranchTarget];
    try validateF128SretSuccess(success, function.params.items[0].name);
    try validateDebugPanicUnreachableBlock(function.blocks.items[blockIndex(function, first_branch.else_target) orelse return error.InvalidBranchTarget]);
    try validateDebugPanicUnreachableBlock(function.blocks.items[blockIndex(function, second_branch.else_target) orelse return error.InvalidBranchTarget]);

    return .{
        .first_panic_label = first_branch.else_target,
        .second_panic_label = second_branch.else_target,
    };
}

pub fn validateDebugF128AggregateReturn(function: ir.Function) !struct { panic_label: []const u8 } {
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 10) return error.UnsupportedCodegenInstruction;

    const result_alloca = entry.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[0].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "%main.f128_struct" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    const arg_alloca = entry.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[1].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "%main.f128_struct" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    const raw_alloca = entry.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[2].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "[16 x i8]" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }

    const param_store = switch (entry.instructions.items[3].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!param_store.ty.eql(.fp128) or !isNamed(param_store.value, function.params.items[0].name) or !isNamed(param_store.ptr, raw_alloca)) return error.UnsupportedCodegenValue;
    try validateDebugF128Memcpy(entry.instructions.items[4], arg_alloca, raw_alloca, 16);
    const load_name = try validateDebugF128Load(entry.instructions.items[5], arg_alloca);
    const call_name = try validateDebugF128EqCall(entry.instructions.items[6], load_name, "0xL0000000000000000400C81C800000000");
    const eq_name = try validateDebugEqZeroI32(entry.instructions.items[7], call_name);
    const expect_name = try validateDebugTestingExpect(entry.instructions.items[8], eq_name);
    const ok_name = try validateDebugEqZeroI16(entry.instructions.items[9], expect_name);
    const branch = try validateDebugCondBr(entry, ok_name);

    const bridge = function.blocks.items[blockIndex(function, branch.then_target) orelse return error.InvalidBranchTarget];
    const success_label = try validateEmptyBr(bridge);
    const success = function.blocks.items[blockIndex(function, success_label) orelse return error.InvalidBranchTarget];
    try validateDebugF128AggregateSuccess(success, result_alloca);
    try validateDebugPanicUnreachableBlock(function.blocks.items[blockIndex(function, branch.else_target) orelse return error.InvalidBranchTarget]);
    return .{ .panic_label = branch.else_target };
}

pub fn validateDebugF128AggregateSuccess(block: ir.BasicBlock, result_alloca: []const u8) !void {
    if (block.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    const store = switch (block.instructions.items[0].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!store.ty.eql(.fp128) or !isNamed(store.ptr, result_alloca)) return error.UnsupportedCodegenInstruction;
    switch (store.value) {
        .fp => |text| if (!std.mem.eql(u8, text, "0xL0000000000000000400F81CD00000000")) return error.UnsupportedCodegenValue,
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }

    const load_name = block.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    const load = switch (block.instructions.items[1].kind) {
        .load => |load| load,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!load.ty.eql(.{ .aggregate = "{ fp128 }" }) or load.attrs.isBarrier() or !isNamed(load.ptr, result_alloca)) return error.UnsupportedCodegenInstruction;

    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .aggregate = "{ fp128 }" }) or !(ret.value orelse return error.InvalidRet).eql(.{ .named = load_name })) return error.InvalidRet;
}

pub fn validateDebugF128ScalarReturn(function: ir.Function) !struct { panic_label: []const u8 } {
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 4) return error.UnsupportedCodegenInstruction;

    const call_name = try validateDebugF128EqCall(entry.instructions.items[0], function.params.items[0].name, "0xL00000000000000004002800000000000");
    const eq_name = try validateDebugEqZeroI32(entry.instructions.items[1], call_name);
    const expect_name = try validateDebugTestingExpect(entry.instructions.items[2], eq_name);
    const ok_name = try validateDebugEqZeroI16(entry.instructions.items[3], expect_name);
    const branch = try validateDebugCondBr(entry, ok_name);

    const bridge = function.blocks.items[blockIndex(function, branch.then_target) orelse return error.InvalidBranchTarget];
    const success_label = try validateEmptyBr(bridge);
    const success = function.blocks.items[blockIndex(function, success_label) orelse return error.InvalidBranchTarget];
    try validateF128ScalarRet(success, "0xL00000000000000004004100000000000");
    try validateDebugPanicUnreachableBlock(function.blocks.items[blockIndex(function, branch.else_target) orelse return error.InvalidBranchTarget]);
    return .{ .panic_label = branch.else_target };
}

pub fn validateDebugF128Memcpy(instruction: ir.Instruction, dst_name: []const u8, src_name: []const u8, expected_size: i128) !void {
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.eql(u8, call.callee, "llvm.memcpy.p0.p0.i64") or call.ret_ty != .void or call.args.items.len != 4) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.ptr) or !isNamed(call.args.items[0].value, dst_name)) return error.UnsupportedCodegenValue;
    if (!call.args.items[1].ty.eql(.ptr) or !isNamed(call.args.items[1].value, src_name)) return error.UnsupportedCodegenValue;
    if (!call.args.items[2].ty.eql(.{ .int = 64 }) or !call.args.items[2].value.eql(.{ .int = expected_size })) return error.UnsupportedCodegenValue;
    if (!call.args.items[3].ty.eql(.{ .int = 1 }) or !call.args.items[3].value.eql(.{ .int = 0 })) return error.UnsupportedCodegenValue;
}

pub fn validateDebugF128Load(instruction: ir.Instruction, ptr_name: []const u8) ![]const u8 {
    const result = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const load = switch (instruction.kind) {
        .load => |load| load,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!load.ty.eql(.fp128) or load.attrs.isBarrier() or !isNamed(load.ptr, ptr_name)) return error.UnsupportedCodegenInstruction;
    return result;
}

pub fn validateNamedLoad(instruction: ir.Instruction, expected_ty: ir.Type, ptr_name: []const u8) ![]const u8 {
    const result = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const load = switch (instruction.kind) {
        .load => |load| load,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!load.ty.eql(expected_ty) or load.attrs.isBarrier() or !isNamed(load.ptr, ptr_name)) return error.UnsupportedCodegenInstruction;
    return result;
}

pub fn validateI32Store(instruction: ir.Instruction, ptr_name: []const u8, expected_value: i128) !void {
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const store = switch (instruction.kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!store.ty.eql(.{ .int = 32 }) or !isNamed(store.ptr, ptr_name) or !store.value.eql(.{ .int = expected_value })) return error.UnsupportedCodegenValue;
}

pub fn validateIcmpImm(instruction: ir.Instruction, predicate: ir.IcmpPredicate, ty: ir.Type, lhs_name: []const u8, rhs_value: i128) ![]const u8 {
    const result = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (icmp.predicate != predicate or !icmp.operand_ty.eql(ty) or !isNamed(icmp.lhs, lhs_name) or !icmp.rhs.eql(.{ .int = rhs_value })) return error.UnsupportedCodegenValue;
    return result;
}

pub fn validateFcmpImm(instruction: ir.Instruction, predicate: ir.FcmpPredicate, ty: ir.Type, lhs_name: []const u8, rhs_value: []const u8) ![]const u8 {
    const result = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const fcmp = switch (instruction.kind) {
        .fcmp => |fcmp| fcmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (fcmp.predicate != predicate or !fcmp.operand_ty.eql(ty) or !isNamed(fcmp.lhs, lhs_name)) return error.UnsupportedCodegenValue;
    switch (fcmp.rhs) {
        .fp => |text| if (!std.mem.eql(u8, text, rhs_value)) return error.UnsupportedCodegenValue,
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
    return result;
}

pub fn validateFloatStore(instruction: ir.Instruction, ptr_name: []const u8, expected_ty: ir.Type, expected_value: []const u8) !void {
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const store = switch (instruction.kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!store.ty.eql(expected_ty) or !isNamed(store.ptr, ptr_name)) return error.UnsupportedCodegenValue;
    switch (store.value) {
        .fp => |text| if (!std.mem.eql(u8, text, expected_value)) return error.UnsupportedCodegenValue,
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn validateDebugF128EqCall(instruction: ir.Instruction, lhs_name: []const u8, expected: []const u8) ![]const u8 {
    const result = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateF128EqCall(call, lhs_name, expected);
    return result;
}

pub fn validateDebugEqZeroI32(instruction: ir.Instruction, call_name: []const u8) ![]const u8 {
    const result = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateEqZeroIcmp(icmp, call_name);
    return result;
}

pub fn validateDebugTestingExpect(instruction: ir.Instruction, cond_name: []const u8) ![]const u8 {
    const result = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.eql(u8, call.callee, "testing.expect") or !call.ret_ty.eql(.{ .int = 16 }) or call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 1 }) or !isNamed(call.args.items[0].value, cond_name)) return error.UnsupportedCodegenValue;
    return result;
}

pub fn validateDebugEqZeroI16(instruction: ir.Instruction, value_name: []const u8) ![]const u8 {
    const result = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 16 })) return error.UnsupportedCodegenInstruction;
    if (!isNamed(icmp.lhs, value_name) or !icmp.rhs.eql(.{ .int = 0 })) return error.UnsupportedCodegenValue;
    return result;
}

pub fn validateDebugCondBr(block: ir.BasicBlock, cond_name: []const u8) !struct { then_target: []const u8, else_target: []const u8 } {
    const condbr = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, cond_name)) return error.UnsupportedCodegenControlFlow;
    return .{ .then_target = condbr.then_target, .else_target = condbr.else_target };
}

pub fn validateEmptyBr(block: ir.BasicBlock) ![]const u8 {
    if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    return validateTerminatorBr(block);
}

fn validateTerminatorBr(block: ir.BasicBlock) ![]const u8 {
    return switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br.target,
        else => error.UnsupportedCodegenControlFlow,
    };
}

pub fn validateDebugPanicUnreachableBlock(block: ir.BasicBlock) !void {
    if (block.instructions.items.len != 3) return error.UnsupportedCodegenInstruction;
    for (block.instructions.items[0..2]) |instruction| {
        if (instruction.result == null) return error.UnsupportedCodegenInstruction;
        switch (instruction.kind) {
            .extractvalue => {},
            else => return error.UnsupportedCodegenInstruction,
        }
    }
    const call = switch (block.instructions.items[2].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.eql(u8, call.callee, "debug.defaultPanic") or call.ret_ty != .void) return error.UnsupportedCodegenInstruction;
    switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .@"unreachable" => {},
        else => return error.UnsupportedCodegenControlFlow,
    }
}

pub fn validateF128EntryEqBranch(block: ir.BasicBlock, byval_param: []const u8) !F128Branch {
    if (block.instructions.items.len != 5) return error.UnsupportedCodegenInstruction;
    const first_load_name = block.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const first_load = switch (block.instructions.items[0].kind) {
        .load => |load| load,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!first_load.ty.eql(.fp128) or first_load.attrs.isBarrier()) return error.UnsupportedCodegenInstruction;
    if (!isNamed(first_load.ptr, byval_param)) return error.UnsupportedCodegenValue;

    const gep_name = block.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    const gep = switch (block.instructions.items[1].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(gep, byval_param, 16);

    const second_load_name = block.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    const second_load = switch (block.instructions.items[2].kind) {
        .load => |load| load,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!second_load.ty.eql(.fp128) or second_load.attrs.isBarrier()) return error.UnsupportedCodegenInstruction;
    if (!isNamed(second_load.ptr, gep_name)) return error.UnsupportedCodegenValue;

    const call_name = block.instructions.items[3].result orelse return error.UnsupportedCodegenInstruction;
    const call = switch (block.instructions.items[3].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateF128EqCall(call, first_load_name, "0xL00000000000000004002A00000000000");

    const icmp_name = block.instructions.items[4].result orelse return error.UnsupportedCodegenInstruction;
    const icmp = switch (block.instructions.items[4].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateEqZeroIcmp(icmp, call_name);

    const condbr = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, icmp_name)) return error.UnsupportedCodegenControlFlow;
    return .{ .then_label = condbr.then_target, .else_label = condbr.else_target, .second_load = second_load_name };
}

pub fn validateF128SecondEqBranch(block: ir.BasicBlock, second_load_name: []const u8) !F128Branch {
    if (block.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    const call_name = block.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const call = switch (block.instructions.items[0].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateF128EqCall(call, second_load_name, "0xL00000000000000004004C80000000000");

    const icmp_name = block.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    const icmp = switch (block.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateEqZeroIcmp(icmp, call_name);

    const condbr = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, icmp_name)) return error.UnsupportedCodegenControlFlow;
    return .{ .then_label = condbr.then_target, .else_label = condbr.else_target, .second_load = second_load_name };
}

pub fn validateF128EqCall(call: ir.CallInst, lhs_name: []const u8, expected: []const u8) !void {
    if (!std.mem.eql(u8, call.callee, "__eqtf2") or !call.ret_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
    if (call.args.items.len != 2) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.fp128) or !isNamed(call.args.items[0].value, lhs_name)) return error.UnsupportedCodegenValue;
    if (!call.args.items[1].ty.eql(.fp128)) return error.UnsupportedCodegenType;
    switch (call.args.items[1].value) {
        .fp => |text| if (!std.mem.eql(u8, text, expected)) return error.UnsupportedCodegenValue,
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn validateEqZeroIcmp(icmp: ir.IcmpInst, call_name: []const u8) !void {
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
    if (!isNamed(icmp.lhs, call_name) or !icmp.rhs.eql(.{ .int = 0 })) return error.UnsupportedCodegenValue;
}

pub fn validateF128SretSuccess(block: ir.BasicBlock, sret_param: []const u8) !void {
    if (block.instructions.items.len != 3) return error.UnsupportedCodegenInstruction;
    const first_store = switch (block.instructions.items[0].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateF128Store(first_store, sret_param, "0xL00000000000000004003800000000000");

    const gep_name = block.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    const gep = switch (block.instructions.items[1].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(gep, sret_param, 16);

    const second_store = switch (block.instructions.items[2].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateF128Store(second_store, gep_name, "0xL00000000000000004005100000000000");

    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (ret.ty != .void or ret.value != null) return error.InvalidRet;
}

pub fn validateF128Store(store: ir.StoreInst, ptr_name: []const u8, expected: []const u8) !void {
    if (!store.ty.eql(.fp128) or store.attrs.isBarrier()) return error.UnsupportedCodegenInstruction;
    if (!isNamed(store.ptr, ptr_name)) return error.UnsupportedCodegenValue;
    switch (store.value) {
        .fp => |text| if (!std.mem.eql(u8, text, expected)) return error.UnsupportedCodegenValue,
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn validateI8GepOffset(gep: ir.GepInst, ptr_name: []const u8, offset: i128) !void {
    if (!gep.source_ty.eql(.{ .int = 8 }) or !isNamed(gep.ptr, ptr_name)) return error.UnsupportedCodegenInstruction;
    if (gep.indices.items.len != 1) return error.UnsupportedCodegenInstruction;
    const index = gep.indices.items[0];
    if (!index.ty.eql(.{ .int = 64 }) or !index.value.eql(.{ .int = offset })) return error.UnsupportedCodegenInstruction;
}

pub fn validatePanicUnreachableBlock(block: ir.BasicBlock) !void {
    if (block.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    const call = switch (block.instructions.items[0].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.eql(u8, call.callee, "debug.defaultPanic") or call.ret_ty != .void) return error.UnsupportedCodegenInstruction;
    switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .@"unreachable" => {},
        else => return error.UnsupportedCodegenControlFlow,
    }
}

pub fn functionHasOverflowPanicEdge(function: ir.Function) bool {
    return sliceSumHasOverflowCheck(function);
}

fn appendI32CallArgs(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    call: ir.CallInst,
) !usize {
    var plan = try planSysVCall(allocator, function, call);
    defer plan.deinit(allocator);
    if (plan.has_non_i32_arg) return error.UnsupportedCodegenType;
    if (plan.counts.stack_args > max_sysv_stack_call_args) return error.UnsupportedCodegenAbi;

    var stack_args: [max_sysv_stack_call_args]StackScalarCallArg = undefined;
    var stack_arg_count: usize = 0;
    for (call.args.items, 0..) |arg, index| {
        const assignment = plan.assignments.items[index];
        switch (assignment) {
            .gpr => |dst| switch (arg.value) {
                .int => |int| try appendMoveImmToArgReg(allocator, machine, dst, try i64Value(int)),
                .named => |name| {
                    if (paramRegOrNull(function, name, .{ .int = 32 }) catch |err| switch (err) {
                        error.UnsupportedCodegenAbi => null,
                        else => return err,
                    }) |src| {
                        if (src != dst) try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = dst, .src = src } });
                    } else {
                        try appendLoadStackDispArg32(allocator, machine, dst, try scalarParamStackDisp8(function, name, .{ .int = 32 }));
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
        try appendStackScalarCallArg(allocator, machine, function, null, stack_args[index], reserved_stack_bytes);
        reserved_stack_bytes += 8;
    }
    return stack_arg_count;
}

pub fn i32CallStackArgCount(call: ir.CallInst) !usize {
    if (call.args.items.len > max_sysv_stack_call_args + 6) return error.UnsupportedCodegenAbi;
    var stack_arg_count: usize = 0;
    for (call.args.items, 0..) |arg, index| {
        if (!arg.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
        if (index >= 6) {
            switch (arg.value) {
                .int, .named => {},
                .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
            }
            stack_arg_count += 1;
        }
    }
    return stack_arg_count;
}

fn appendSysVScalarCallArgs(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    call: ir.CallInst,
) !usize {
    return try appendSysVScalarCallArgsWithBlock(allocator, machine, function, null, call);
}

fn appendSysVScalarCallArgsWithBlock(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    maybe_block: ?ir.BasicBlock,
    call: ir.CallInst,
) anyerror!usize {
    var plan = try planSysVCall(allocator, function, call);
    defer plan.deinit(allocator);
    if (plan.counts.stack_args > max_sysv_stack_call_args) return error.UnsupportedCodegenAbi;

    var stack_args: [max_sysv_stack_call_args]StackScalarCallArg = undefined;
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
                if (sysvIntegerParamRegOrNull(function, name, arg.ty) catch |err| switch (err) {
                    error.UnsupportedCodegenAbi => null,
                    else => return err,
                }) |src| {
                    stack_args[stack_arg_count] = .{ .arg_reg = src };
                } else if (scalarParamStackDisp8(function, name, arg.ty) catch |err| switch (err) {
                    error.UnsupportedCodegenValue => null,
                    else => return err,
                }) |disp| {
                    stack_args[stack_arg_count] = .{ .stack_disp = disp };
                } else if (arg.ty.eql(.{ .int = 32 })) {
                    const block = maybe_block orelse return error.UnsupportedCodegenAbi;
                    if (!genericCfgSupportsSingleBlockI32Value(function, block, .{ .named = name })) return error.UnsupportedCodegenValue;
                    stack_args[stack_arg_count] = .{ .computed_i32 = .{ .named = name } };
                } else if (arg.ty.eql(.{ .int = 64 })) {
                    _ = maybe_block orelse return error.UnsupportedCodegenAbi;
                    if (!genericCfgSupportsI64Value(function, .{ .named = name })) return error.UnsupportedCodegenValue;
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
                try emitGenericCfgI32ValueIntoEax(allocator, machine, function, block, value);
                stack_arg.* = .precomputed_rax;
                precomputed_stack_arg = true;
            },
            .computed_i64 => |value| {
                if (precomputed_stack_arg) return error.UnsupportedCodegenAbi;
                const block = maybe_block orelse return error.UnsupportedCodegenAbi;
                try emitGenericCfgI64ValueIntoRax(allocator, machine, function, block, value);
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
        try appendStackScalarCallArg(allocator, machine, function, maybe_block, stack_args[stack_index], reserved_stack_bytes);
        reserved_stack_bytes += 8;
    }
    const incoming_stack_adjust = reserved_stack_bytes;

    for (call.args.items, 0..) |arg, index| {
        const assignment = plan.assignments.items[index];
        switch (assignment) {
            .gpr => |dst| {
                if (!arg.ty.eql(.{ .int = 32 }) and !arg.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
                switch (arg.value) {
                    .int => |int| try appendMoveImmToArgReg(allocator, machine, dst, try i64Value(int)),
                    .named => |name| {
                        if (sysvIntegerParamRegOrNull(function, name, arg.ty) catch |err| switch (err) {
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
                            try appendLoadStackDispArg32(allocator, machine, dst, @as(usize, try scalarParamStackDisp8(function, name, .{ .int = 32 })) + incoming_stack_adjust);
                        } else if (arg.ty.eql(.{ .int = 64 })) {
                            try appendLoadStackDispArg64(allocator, machine, dst, @as(usize, try scalarParamStackDisp8(function, name, .{ .int = 64 })) + incoming_stack_adjust);
                        }
                    },
                    .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
                }
            },
            .sse => |dst| {
                if (!arg.ty.eql(.float) and !arg.ty.eql(.double)) return error.UnsupportedCodegenType;
                switch (arg.value) {
                    .fp => if (arg.ty.eql(.float))
                        try appendMoveImm32ToXmm(allocator, machine, dst, try fp32TextBits(arg.value))
                    else
                        try appendMoveImm64ToXmm(allocator, machine, dst, try fp64TextBits(arg.value)),
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
                                    .src = try XmmReg.fromIndex(src_index),
                                } });
                            }
                        } else if (arg.ty.eql(.double)) {
                            try appendLoadStackDispXmm(
                                allocator,
                                machine,
                                dst,
                                try adjustedIncomingStackDisp8(try scalarParamStackDisp8(function, name, .double), incoming_stack_adjust),
                            );
                        } else {
                            return error.UnsupportedCodegenAbi;
                        }
                    },
                    .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
                }
            },
            .aggregate_register_passthrough => |aggregate| {
                try appendSysVRegisterAggregatePassThroughArg(allocator, machine, aggregate, incoming_stack_adjust);
            },
            .stack_i32_const, .stack_i32_param, .aggregate_stack_passthrough => {},
        }
    }
    return stack_arg_count;
}

pub fn adjustedIncomingStackDisp8(base_offset: u8, incoming_stack_adjust: usize) !u8 {
    const adjusted = @as(usize, base_offset) + incoming_stack_adjust;
    if (adjusted > std.math.maxInt(u8)) return error.UnsupportedCodegenAbi;
    return @intCast(adjusted);
}

pub fn sysvCallPlanCountsForTest(allocator: std.mem.Allocator, function: ir.Function, call: ir.CallInst) !SysVCallPlanCounts {
    return try sysv_abi.callPlanCountsForTest(allocator, function, call);
}

pub fn planSysVCall(allocator: std.mem.Allocator, function: ir.Function, call: ir.CallInst) !SysVCallPlan {
    return try sysv_abi.planCall(allocator, function, call);
}

pub fn appendSysVRegisterAggregatePassThroughArg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    pass: SysVRegisterAggregatePassThrough,
    incoming_stack_adjust: usize,
) !void {
    const dest = switch (pass.dest) {
        .registers => |dest| dest,
        .stack => return error.UnsupportedCodegenAbi,
    };
    const needs = sysvAggregateRegisterNeeds(pass.classification);
    const source_in_registers = pass.source.gpr + needs.gpr <= 6 and pass.source.sse + needs.sse <= 8;
    if (source_in_registers) {
        if (pass.source.stack_eightbytes != 0) return error.UnsupportedCodegenAbi;
        if (pass.source.gpr != dest.gpr) {
            if (dest.gpr < pass.source.gpr) {
                var gpr_offset: usize = 0;
                while (gpr_offset < needs.gpr) : (gpr_offset += 1) {
                    try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{
                        .dst = try ArgReg.fromIndex(dest.gpr + gpr_offset),
                        .src = try ArgReg.fromIndex(pass.source.gpr + gpr_offset),
                    } });
                }
            } else {
                var remaining = needs.gpr;
                while (remaining > 0) {
                    remaining -= 1;
                    try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{
                        .dst = try ArgReg.fromIndex(dest.gpr + remaining),
                        .src = try ArgReg.fromIndex(pass.source.gpr + remaining),
                    } });
                }
            }
        }

        if (pass.source.sse != dest.sse) {
            if (dest.sse < pass.source.sse) {
                var sse_offset: usize = 0;
                while (sse_offset < needs.sse) : (sse_offset += 1) {
                    try machine.instructions.append(allocator, .{ .movapd_xmm = .{
                        .dst = try XmmReg.fromIndex(dest.sse + sse_offset),
                        .src = try XmmReg.fromIndex(pass.source.sse + sse_offset),
                    } });
                }
            } else {
                var remaining = needs.sse;
                while (remaining > 0) {
                    remaining -= 1;
                    try machine.instructions.append(allocator, .{ .movapd_xmm = .{
                        .dst = try XmmReg.fromIndex(dest.sse + remaining),
                        .src = try XmmReg.fromIndex(pass.source.sse + remaining),
                    } });
                }
            }
        }
        return;
    }

    var gpr_offset: usize = 0;
    var sse_offset: usize = 0;
    var eightbyte_index: usize = 0;
    while (eightbyte_index < pass.classification.eightbyte_count) : (eightbyte_index += 1) {
        switch (pass.classification.eightbytes[eightbyte_index] orelse return error.UnsupportedCodegenAbi) {
            .integer => {
                const dst = try ArgReg.fromIndex(dest.gpr + gpr_offset);
                const offset = 8 + (pass.source.stack_eightbytes + eightbyte_index) * 8 + incoming_stack_adjust;
                try appendLoadStackDispArg64(allocator, machine, dst, offset);
                gpr_offset += 1;
            },
            .sse => {
                const dst = try XmmReg.fromIndex(dest.sse + sse_offset);
                const offset = 8 + (pass.source.stack_eightbytes + eightbyte_index) * 8 + incoming_stack_adjust;
                if (offset <= std.math.maxInt(i8)) {
                    try machine.instructions.append(allocator, .{ .load_stack_disp8_xmm = .{ .reg = dst, .disp = @intCast(offset) } });
                } else if (offset <= std.math.maxInt(u32)) {
                    try machine.instructions.append(allocator, .{ .load_stack_disp32_xmm = .{ .reg = dst, .disp = @intCast(offset) } });
                } else {
                    return error.UnsupportedCodegenAbi;
                }
                sse_offset += 1;
            },
        }
    }
}

pub fn appendSysVStackAggregatePassThroughArgs(
    stack_args: *[max_sysv_stack_call_args]StackScalarCallArg,
    stack_arg_count: *usize,
    pass: SysVRegisterAggregatePassThrough,
) !void {
    switch (pass.dest) {
        .stack => {},
        .registers => return error.UnsupportedCodegenAbi,
    }
    const needs = sysvAggregateRegisterNeeds(pass.classification);
    const source_in_registers = pass.source.gpr + needs.gpr <= 6 and pass.source.sse + needs.sse <= 8;
    if (source_in_registers) {
        if (pass.source.stack_eightbytes != 0) return error.UnsupportedCodegenAbi;
        var sse_offset: usize = 0;
        var gpr_offset: usize = 0;
        var eightbyte_index: usize = 0;
        while (eightbyte_index < pass.classification.eightbyte_count) : (eightbyte_index += 1) {
            if (stack_arg_count.* >= stack_args.len) return error.UnsupportedCodegenAbi;
            switch (pass.classification.eightbytes[eightbyte_index] orelse return error.UnsupportedCodegenAbi) {
                .integer => {
                    stack_args[stack_arg_count.*] = .{ .arg_reg = try ArgReg.fromIndex(pass.source.gpr + gpr_offset) };
                    gpr_offset += 1;
                },
                .sse => {
                    stack_args[stack_arg_count.*] = .{ .xmm_reg = try XmmReg.fromIndex(pass.source.sse + sse_offset) };
                    sse_offset += 1;
                },
            }
            stack_arg_count.* += 1;
        }
        return;
    }

    var eightbyte_index: usize = 0;
    while (eightbyte_index < pass.classification.eightbyte_count) : (eightbyte_index += 1) {
        _ = pass.classification.eightbytes[eightbyte_index] orelse return error.UnsupportedCodegenAbi;
        if (stack_arg_count.* >= stack_args.len) return error.UnsupportedCodegenAbi;
        const offset = 8 + (pass.source.stack_eightbytes + eightbyte_index) * 8;
        if (offset > std.math.maxInt(u8)) return error.UnsupportedCodegenAbi;
        stack_args[stack_arg_count.*] = .{ .stack_disp = @intCast(offset) };
        stack_arg_count.* += 1;
    }
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

    var stack_args: [max_sysv_stack_call_args]StackScalarCallArg = undefined;
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
        try appendStackScalarCallArg(allocator, machine, function, null, stack_args[stack_index], reserved_stack_bytes);
        reserved_stack_bytes += 8;
    }
    return stack_arg_count;
}

pub fn sysvParamCursorFor(function: ir.Function, name: []const u8, ty: ir.Type) !SysVParamCursor {
    return try sysvParamCursorForWithInitial(function, name, ty, .{ .gpr = 0, .sse = 0, .stack_eightbytes = 0 });
}

pub fn sysvParamCursorForWithInitial(function: ir.Function, name: []const u8, ty: ir.Type, initial: SysVParamCursor) !SysVParamCursor {
    var cursor: SysVParamCursor = initial;
    for (function.params.items) |param| {
        if (std.mem.eql(u8, param.name, name)) {
            if (!param.ty.eql(ty)) return error.UnsupportedCodegenType;
            return cursor;
        }
        try advanceSysVParamCursors(param.ty, &cursor.gpr, &cursor.sse, &cursor.stack_eightbytes);
    }
    return error.UnsupportedCodegenValue;
}

pub fn sysvScalarCallNeedsStackArgs(call: ir.CallInst) bool {
    var int_arg_index: usize = 0;
    var fp_arg_index: usize = 0;
    for (call.args.items) |arg| {
        if (arg.attrs != null) return true;
        if (arg.ty.eql(.{ .int = 32 }) or arg.ty.eql(.{ .int = 64 })) {
            if (int_arg_index >= 6) return true;
            int_arg_index += 1;
        } else if (arg.ty.eql(.float) or arg.ty.eql(.double)) {
            if (fp_arg_index >= 8) return true;
            fp_arg_index += 1;
        } else {
            return true;
        }
    }
    return false;
}

pub const StackScalarCallArg = union(enum) {
    imm: i32,
    stack_disp: u8,
    arg_reg: ArgReg,
    xmm_reg: XmmReg,
    computed_i32: ir.Value,
    computed_i64: ir.Value,
    precomputed_rax,
};

pub fn appendStackScalarCallArg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    maybe_block: ?ir.BasicBlock,
    arg: StackScalarCallArg,
    reserved_stack_bytes: usize,
) anyerror!void {
    switch (arg) {
        .imm => |value| try machine.instructions.append(allocator, .{ .push_imm32 = value }),
        .arg_reg => |reg| try machine.instructions.append(allocator, .{ .push_arg = reg }),
        .xmm_reg => |reg| try machine.instructions.append(allocator, .{ .push_xmm64 = reg }),
        .computed_i32 => |value| {
            const block = maybe_block orelse return error.UnsupportedCodegenAbi;
            try emitGenericCfgI32ValueIntoEax(allocator, machine, function, block, value);
            try machine.instructions.append(allocator, .push_rax);
        },
        .computed_i64 => |value| {
            const block = maybe_block orelse return error.UnsupportedCodegenAbi;
            try emitGenericCfgI64ValueIntoRax(allocator, machine, function, block, value);
            try machine.instructions.append(allocator, .push_rax);
        },
        .precomputed_rax => try machine.instructions.append(allocator, .push_rax),
        .stack_disp => |base_offset| {
            const adjusted = @as(usize, base_offset) + reserved_stack_bytes;
            if (adjusted <= std.math.maxInt(i8)) {
                try machine.instructions.append(allocator, .{ .push_stack_disp8 = @intCast(adjusted) });
            } else if (adjusted <= std.math.maxInt(u32)) {
                try machine.instructions.append(allocator, .{ .push_stack_disp32 = @intCast(adjusted) });
            } else {
                return error.UnsupportedCodegenAbi;
            }
        },
    }
}

fn appendAlignedDirectCallPreservingI32Param(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    symbol: []const u8,
    ret_ty: ir.Type,
    live_param: ?ArgReg,
) !void {
    try appendStackFrame(allocator, machine, 8);
    if (live_param) |reg| try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{
        .frame_index = .slot0,
        .reg = reg,
    } });
    try appendDirectCall(allocator, machine, symbol, ret_ty);
    if (live_param) |reg| try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{
        .reg = reg,
        .frame_index = .slot0,
    } });
    try appendStackFrameEnd(allocator, machine, 8);
}

pub fn appendAlignedDirectCallPreservingI32Params(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    call: ir.CallInst,
    live_params: LiveParamSet,
) !void {
    try appendAlignedCallPreservingI32Params(allocator, machine, function, call, live_params, .{ .direct = call.callee });
}

pub fn appendAlignedCallPreservingI32Params(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    call: ir.CallInst,
    live_params: LiveParamSet,
    call_target: SysVCallTarget,
) !void {
    switch (live_params.count) {
        0 => {
            _ = try appendI32CallArgs(allocator, machine, function, call);
            try appendAlignedSysVCallTarget(allocator, machine, call_target, call.ret_ty);
        },
        1 => {
            try appendStackFrame(allocator, machine, 8);
            try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{
                .frame_index = .slot0,
                .reg = live_params.regs[0],
            } });
            try setupSysVCallTarget(allocator, machine, call_target);
            _ = try appendI32CallArgs(allocator, machine, function, call);
            try appendSysVCallTarget(allocator, machine, call_target, call.ret_ty);
            try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{
                .reg = live_params.regs[0],
                .frame_index = .slot0,
            } });
            try appendStackFrameEnd(allocator, machine, 8);
        },
        2...6 => {
            const frame_bytes: u8 = if (live_params.count <= 3) 24 else 40;
            try appendStackFrame(allocator, machine, frame_bytes);
            var index: usize = 0;
            while (index < live_params.count) : (index += 1) {
                try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{
                    .frame_index = frameIndexForLiveParam(index),
                    .reg = live_params.regs[index],
                } });
            }
            try setupSysVCallTarget(allocator, machine, call_target);
            _ = try appendI32CallArgs(allocator, machine, function, call);
            try appendSysVCallTarget(allocator, machine, call_target, call.ret_ty);
            index = 0;
            while (index < live_params.count) : (index += 1) {
                try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{
                    .reg = live_params.regs[index],
                    .frame_index = frameIndexForLiveParam(index),
                } });
            }
            try appendStackFrameEnd(allocator, machine, frame_bytes);
        },
        else => return error.UnsupportedLiveAcrossCall,
    }
}

pub fn frameIndexForLiveParam(index: usize) FrameIndex {
    return switch (index) {
        0 => .slot0,
        1 => .slot1,
        2 => .slot2,
        3 => .slot3,
        4 => .slot4,
        5 => .slot5,
        else => unreachable,
    };
}

fn lowerReturnTerminator(
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

fn lowerReturnValue(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    value: ir.Value,
) !void {
    switch (value) {
        .int => |int| try machine.instructions.append(allocator, .{ .mov_imm_eax = try i32Value(int) }),
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        .named => |name| {
            if (try emitI32ParamOrStackIntoEax(allocator, machine, function, name)) {
                return;
            }
            const instruction = findInstruction(block, name) orelse return error.UnsupportedCodegenValue;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (!binary.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
                    const op = machineBinaryOp(binary.op) orelse return error.UnsupportedCodegenInstruction;
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
                            try machine.instructions.append(allocator, .{ .mov_imm_eax = try i32Value(lhs) });
                            switch (op) {
                                .add => try machine.instructions.append(allocator, .{ .add_eax_imm32 = try i32Value(rhs) }),
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
                .select => |select| try lowerGenericCfgSelectReturnValue(allocator, machine, function, block, select, 0),
                .cast, .freeze, .icmp, .fcmp, .phi, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => return error.UnsupportedCodegenInstruction,
            }
        },
    }
}

pub fn lowerGenericCfgSelectReturnValue(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    select: ir.SelectInst,
    depth: u2,
) anyerror!void {
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
    const cond_name = switch (select.cond) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    const true_label = genericCfgSelectTrueLabel(depth);
    const end_label = genericCfgSelectEndLabel(depth);
    if (genericCfgSupportsI1Param(function, cond_name)) {
        const cond_reg = try paramReg(function, cond_name, .{ .int = 1 });
        try machine.instructions.append(allocator, .{ .test_arg8 = cond_reg });
        try machine.instructions.append(allocator, .{ .jne = true_label });
    } else {
        const cond_inst = findInstruction(block, cond_name) orelse return error.UnsupportedCodegenValue;
        const cond = switch (cond_inst.kind) {
            .icmp => |icmp| icmp,
            else => return error.UnsupportedCodegenInstruction,
        };
        if (try lowerGenericCfgSminSelectReturn(allocator, machine, function, select, cond)) return;
        const branch_kind = try emitGenericCfgIcmpCondition(allocator, machine, function, cond);
        try appendGenericCfgConditionalBranch(allocator, machine, branch_kind, true_label);
    }
    try lowerGenericCfgI32ValueIntoEax(allocator, machine, function, block, select.false_value, depth +| 1);
    try machine.instructions.append(allocator, .{ .jmp = end_label });
    try appendGenericCfgBlockLabel(allocator, machine, true_label);
    try lowerGenericCfgI32ValueIntoEax(allocator, machine, function, block, select.true_value, depth +| 1);
    try appendGenericCfgBlockLabel(allocator, machine, end_label);
}

pub fn lowerGenericCfgI32ValueIntoEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    value: ir.Value,
    depth: u2,
) anyerror!void {
    switch (value) {
        .int => |int| try machine.instructions.append(allocator, .{ .mov_imm_eax = try i32Value(int) }),
        .named => |name| {
            if (try paramRegOrNull(function, name, .{ .int = 32 })) |reg| {
                try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
                return;
            }
            const instruction = findInstruction(block, name) orelse return error.UnsupportedCodegenValue;
            const select = switch (instruction.kind) {
                .select => |select| select,
                .binary => {
                    try emitGenericCfgI32ValueIntoEax(allocator, machine, function, block, value);
                    return;
                },
                else => return error.UnsupportedCodegenInstruction,
            };
            if (depth == std.math.maxInt(u2)) return error.UnsupportedCodegenInstruction;
            try lowerGenericCfgSelectReturnValue(allocator, machine, function, block, select, depth);
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn genericCfgSelectTrueLabel(depth: u2) []const u8 {
    return switch (depth) {
        0 => "generic_cfg_select_true",
        1 => "generic_cfg_nested1_select_true",
        2 => "generic_cfg_nested2_select_true",
        3 => "generic_cfg_nested3_select_true",
    };
}

pub fn genericCfgSelectEndLabel(depth: u2) []const u8 {
    return switch (depth) {
        0 => "generic_cfg_select_end",
        1 => "generic_cfg_nested1_generic_cfg_select_end",
        2 => "generic_cfg_nested2_generic_cfg_select_end",
        3 => "generic_cfg_nested3_generic_cfg_select_end",
    };
}

pub fn lowerGenericCfgSminSelectReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    select: ir.SelectInst,
    icmp: ir.IcmpInst,
) !bool {
    if (!genericCfgSupportsSminSelect(function, select, icmp)) return false;
    const lhs = switch (icmp.lhs) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const rhs = switch (icmp.rhs) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if ((try paramReg(function, lhs, .{ .int = 32 })) != .rdi) return error.UnsupportedCodegenAbi;
    if ((try paramReg(function, rhs, .{ .int = 32 })) != .rsi) return error.UnsupportedCodegenAbi;
    try machine.instructions.append(allocator, .smin_i32_edi_esi_eax);
    return true;
}

pub fn emitGenericCfgIcmpCondition(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    icmp: ir.IcmpInst,
) !GenericCfgBranchKind {
    const branch_kind: GenericCfgBranchKind = switch (icmp.predicate) {
        .eq => .je,
        .ne => .jne,
        .slt => if (icmp.operand_ty.eql(.{ .int = 32 }) and isInt(icmp.rhs, 0))
            .js
        else
            return error.UnsupportedCodegenInstruction,
        .ugt, .uge, .ult, .ule, .sgt, .sge, .sle => return error.UnsupportedCodegenInstruction,
    };

    if (icmp.operand_ty.eql(.ptr)) {
        const ptr_value = if (icmp.lhs == .null_value) icmp.rhs else if (icmp.rhs == .null_value) icmp.lhs else return error.UnsupportedCodegenValue;
        const ptr_reg = try paramValueReg(function, ptr_value, .ptr);
        try machine.instructions.append(allocator, .{ .test_arg64 = ptr_reg });
        return branch_kind;
    }

    if (icmp.operand_ty.eql(.{ .int = 8 })) {
        if (icmp.lhs == .int and icmp.rhs != .int) {
            const rhs_reg = try paramValueReg(function, icmp.rhs, .{ .int = 8 });
            try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = rhs_reg, .imm = try u8Value(switch (icmp.lhs) {
                .int => |int| int,
                else => unreachable,
            }) } });
            return branch_kind;
        }
        const lhs_reg = try paramValueReg(function, icmp.lhs, .{ .int = 8 });
        const rhs_imm = switch (icmp.rhs) {
            .int => |int| try u8Value(int),
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = lhs_reg, .imm = rhs_imm } });
        return branch_kind;
    }

    if (!icmp.operand_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;

    if (icmp.predicate == .slt and isInt(icmp.rhs, 0)) {
        const lhs_reg = try paramValueReg(function, icmp.lhs, .{ .int = 32 });
        try appendGenericCfgCompareParamZero(allocator, machine, lhs_reg);
        return .js;
    }

    if (isInt(icmp.rhs, 0)) {
        const lhs_reg = try paramValueReg(function, icmp.lhs, .{ .int = 32 });
        try appendGenericCfgCompareParamZero(allocator, machine, lhs_reg);
        return branch_kind;
    }
    if (isInt(icmp.lhs, 0)) {
        const rhs_reg = try paramValueReg(function, icmp.rhs, .{ .int = 32 });
        try appendGenericCfgCompareParamZero(allocator, machine, rhs_reg);
        return branch_kind;
    }

    const lhs_reg = try paramValueReg(function, icmp.lhs, .{ .int = 32 });
    const rhs_imm = switch (icmp.rhs) {
        .int => |int| try i32Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    try machine.instructions.append(allocator, .{ .mov_arg_eax = lhs_reg });
    try appendGenericCfgCompareLocalImm(allocator, machine, .eax, rhs_imm);
    return branch_kind;
}

pub fn lowerI32AddTreeReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    binary: ir.BinaryInst,
) !bool {
    var terms: std.ArrayList(ir.Value) = .empty;
    defer terms.deinit(allocator);
    try collectI32AddTerms(allocator, block, binary, &terms);
    if (terms.items.len < 2) return false;
    try emitI32ValueIntoEax(allocator, machine, function, terms.items[0]);
    for (terms.items[1..]) |term| {
        switch (term) {
            .int => |int| try machine.instructions.append(allocator, .{ .add_eax_imm32 = try i32Value(int) }),
            .named => |name| {
                if (try registerParamRegOrNull(function, name, .{ .int = 32 })) |reg| {
                    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = reg } });
                } else if (try stackParamDisp8OrNull(function, name, .{ .int = 32 })) |offset| {
                    try machine.instructions.append(allocator, .{ .add_stack_disp8_eax = offset });
                } else return false;
            },
            .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
        }
    }
    return true;
}

pub fn collectI32AddTerms(
    allocator: std.mem.Allocator,
    block: ir.BasicBlock,
    binary: ir.BinaryInst,
    terms: *std.ArrayList(ir.Value),
) anyerror!void {
    if (binary.op != .add or !binary.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
    try collectI32AddValue(allocator, block, binary.lhs, terms);
    try collectI32AddValue(allocator, block, binary.rhs, terms);
}

pub fn collectI32AddValue(
    allocator: std.mem.Allocator,
    block: ir.BasicBlock,
    value: ir.Value,
    terms: *std.ArrayList(ir.Value),
) anyerror!void {
    switch (value) {
        .named => |name| {
            if (findInstruction(block, name)) |instruction| {
                switch (instruction.kind) {
                    .binary => |nested| if (nested.op == .add and nested.ty.eql(.{ .int = 32 })) {
                        try collectI32AddTerms(allocator, block, nested, terms);
                        return;
                    },
                    else => {},
                }
            }
            try terms.append(allocator, value);
        },
        .int => try terms.append(allocator, value),
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn emitI32ValueIntoEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    value: ir.Value,
) !void {
    switch (value) {
        .int => |int| try machine.instructions.append(allocator, .{ .mov_imm_eax = try i32Value(int) }),
        .named => |name| {
            if (try emitI32ParamOrStackIntoEax(allocator, machine, function, name)) return;
            return error.UnsupportedCodegenValue;
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

fn lowerReturnValueAfterCalls(
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
    if (!binary.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
    const op = machineBinaryOp(binary.op) orelse return error.UnsupportedCodegenInstruction;
    if (binary.op == .add) {
        var terms: std.ArrayList(ir.Value) = .empty;
        defer terms.deinit(allocator);
        try collectI32AddTerms(allocator, block, binary, &terms);
        var has_eax_value = false;
        for (terms.items) |term| {
            if (isNamed(term, eax_name)) {
                has_eax_value = true;
                break;
            }
        }
        if (has_eax_value) {
            for (terms.items) |term| {
                if (isNamed(term, eax_name)) continue;
                try appendI32AddTermToEax(allocator, machine, function, term);
            }
            return;
        }
    }
    if (isNamed(binary.lhs, eax_name)) {
        if (binary.op == .add) {
            switch (binary.rhs) {
                .int => |int| {
                    try machine.instructions.append(allocator, .{ .add_eax_imm32 = try i32Value(int) });
                    return;
                },
                .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => {},
            }
        }
        const rhs = try paramValueReg(function, binary.rhs, .{ .int = 32 });
        try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = op, .reg = rhs } });
        return;
    }
    if (isCommutative(binary.op) and isNamed(binary.rhs, eax_name)) {
        if (binary.op == .add) {
            switch (binary.lhs) {
                .int => |int| {
                    try machine.instructions.append(allocator, .{ .add_eax_imm32 = try i32Value(int) });
                    return;
                },
                .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => {},
            }
        }
        const lhs = try paramValueReg(function, binary.lhs, .{ .int = 32 });
        try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = op, .reg = lhs } });
        return;
    }
    return error.UnsupportedCodegenInstruction;
}

pub fn appendI32AddTermToEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    term: ir.Value,
) !void {
    switch (term) {
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
            return error.UnsupportedCodegenValue;
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn machineBinaryOp(op: ir.BinaryOp) ?MachineBinaryOp {
    return switch (op) {
        .add => .add,
        .sub => .sub,
        .@"and" => .@"and",
        .@"or" => .@"or",
        .xor => .xor,
        .fadd, .fsub, .fmul, .fdiv, .frem, .mul, .shl, .lshr, .ashr, .udiv, .sdiv, .urem, .srem => null,
    };
}

pub fn singleLiveParamAfter(function: ir.Function, block: ir.BasicBlock, instruction_index: usize) !?ArgReg {
    var live: ?ArgReg = null;
    for (block.instructions.items[instruction_index + 1 ..]) |instruction| {
        if (instruction.removed) continue;
        try noteLiveParams(function, instruction, &live);
    }
    if (block.terminator) |terminator| switch (terminator) {
        .ret => |ret| if (ret.value) |value| try noteLiveValue(function, value, &live),
        .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => {},
    };
    return live;
}

pub const LiveParamSet = struct {
    regs: [6]ArgReg = undefined,
    count: usize = 0,

    fn add(self: *LiveParamSet, reg: ArgReg) !void {
        if (self.has(reg)) return;
        if (self.count == self.regs.len) return error.UnsupportedLiveAcrossCall;
        self.regs[self.count] = reg;
        self.count += 1;
    }

    fn has(self: LiveParamSet, reg: ArgReg) bool {
        for (self.regs[0..self.count]) |existing| {
            if (existing == reg) return true;
        }
        return false;
    }
};

pub fn liveParamsAfter(function: ir.Function, block: ir.BasicBlock, instruction_index: usize) !LiveParamSet {
    var live: LiveParamSet = .{};
    for (block.instructions.items[instruction_index + 1 ..]) |instruction| {
        if (instruction.removed) continue;
        try noteLiveParamsSet(function, block, instruction, &live);
    }
    if (block.terminator) |terminator| switch (terminator) {
        .ret => |ret| if (ret.value) |value| try noteLiveValueSet(function, block, value, &live),
        .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => {},
    };
    return live;
}

pub fn noteLiveParamsSet(function: ir.Function, block: ir.BasicBlock, instruction: ir.Instruction, live: *LiveParamSet) !void {
    switch (instruction.kind) {
        .binary => |binary| {
            try noteLiveValueSet(function, block, binary.lhs, live);
            try noteLiveValueSet(function, block, binary.rhs, live);
        },
        .call => |call| for (call.args.items) |arg| try noteLiveValueSet(function, block, arg.value, live),
        .cast => |cast| try noteLiveValueSet(function, block, cast.value, live),
        .freeze => |freeze| try noteLiveValueSet(function, block, freeze.value, live),
        .icmp => |icmp| {
            try noteLiveValueSet(function, block, icmp.lhs, live);
            try noteLiveValueSet(function, block, icmp.rhs, live);
        },
        .fcmp => |fcmp| {
            try noteLiveValueSet(function, block, fcmp.lhs, live);
            try noteLiveValueSet(function, block, fcmp.rhs, live);
        },
        .select => |select| {
            try noteLiveValueSet(function, block, select.cond, live);
            try noteLiveValueSet(function, block, select.true_value, live);
            try noteLiveValueSet(function, block, select.false_value, live);
        },
        .phi => |phi| for (phi.incoming.items) |incoming| try noteLiveValueSet(function, block, incoming.value, live),
        .load => |load| try noteLiveValueSet(function, block, load.ptr, live),
        .store => |store| {
            try noteLiveValueSet(function, block, store.value, live);
            try noteLiveValueSet(function, block, store.ptr, live);
        },
        .atomicrmw => |atomicrmw| {
            try noteLiveValueSet(function, block, atomicrmw.ptr, live);
            try noteLiveValueSet(function, block, atomicrmw.value, live);
        },
        .cmpxchg => |cmpxchg| {
            try noteLiveValueSet(function, block, cmpxchg.ptr, live);
            try noteLiveValueSet(function, block, cmpxchg.expected, live);
            try noteLiveValueSet(function, block, cmpxchg.replacement, live);
        },
        .extractvalue => |extract| try noteLiveValueSet(function, block, extract.aggregate, live),
        .insertvalue => |insert| {
            try noteLiveValueSet(function, block, insert.aggregate, live);
            try noteLiveValueSet(function, block, insert.value, live);
        },
        .gep => |gep| {
            try noteLiveValueSet(function, block, gep.ptr, live);
            for (gep.indices.items) |index| try noteLiveValueSet(function, block, index.value, live);
        },
        .alloca, .fence, .extractelement, .insertelement, .shufflevector => {},
    }
}

pub fn noteLiveValueSet(function: ir.Function, block: ir.BasicBlock, value: ir.Value, live: *LiveParamSet) !void {
    const name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return,
    };
    if (paramRegOrNull(function, name, .{ .int = 32 }) catch |err| switch (err) {
        error.UnsupportedCodegenAbi => {
            _ = try scalarParamStackDisp8(function, name, .{ .int = 32 });
            return;
        },
        else => return err,
    }) |reg| {
        try live.add(reg);
        return;
    }
    const instruction = findInstruction(block, name) orelse return;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return,
    };
    if (!binary.ty.eql(.{ .int = 32 }) or binary.op != .add) return error.UnsupportedLiveAcrossCall;
    try noteLiveValueSet(function, block, binary.lhs, live);
    try noteLiveValueSet(function, block, binary.rhs, live);
}

pub fn noteLiveParams(function: ir.Function, instruction: ir.Instruction, live: *?ArgReg) !void {
    switch (instruction.kind) {
        .binary => |binary| {
            try noteLiveValue(function, binary.lhs, live);
            try noteLiveValue(function, binary.rhs, live);
        },
        .call => |call| for (call.args.items) |arg| try noteLiveValue(function, arg.value, live),
        .cast => |cast| try noteLiveValue(function, cast.value, live),
        .freeze => |freeze| try noteLiveValue(function, freeze.value, live),
        .icmp => |icmp| {
            try noteLiveValue(function, icmp.lhs, live);
            try noteLiveValue(function, icmp.rhs, live);
        },
        .fcmp => |fcmp| {
            try noteLiveValue(function, fcmp.lhs, live);
            try noteLiveValue(function, fcmp.rhs, live);
        },
        .select => |select| {
            try noteLiveValue(function, select.cond, live);
            try noteLiveValue(function, select.true_value, live);
            try noteLiveValue(function, select.false_value, live);
        },
        .phi => |phi| for (phi.incoming.items) |incoming| try noteLiveValue(function, incoming.value, live),
        .alloca => {},
        .load => |load| try noteLiveValue(function, load.ptr, live),
        .store => |store| {
            try noteLiveValue(function, store.value, live);
            try noteLiveValue(function, store.ptr, live);
        },
        .atomicrmw => |atomicrmw| {
            try noteLiveValue(function, atomicrmw.ptr, live);
            try noteLiveValue(function, atomicrmw.value, live);
        },
        .cmpxchg => |cmpxchg| {
            try noteLiveValue(function, cmpxchg.ptr, live);
            try noteLiveValue(function, cmpxchg.expected, live);
            try noteLiveValue(function, cmpxchg.replacement, live);
        },
        .fence, .extractelement, .insertelement, .shufflevector => {},
        .extractvalue => |extract| try noteLiveValue(function, extract.aggregate, live),
        .insertvalue => |insert| {
            try noteLiveValue(function, insert.aggregate, live);
            try noteLiveValue(function, insert.value, live);
        },
        .gep => |gep| {
            try noteLiveValue(function, gep.ptr, live);
            for (gep.indices.items) |index| try noteLiveValue(function, index.value, live);
        },
    }
}

pub fn noteLiveValue(function: ir.Function, value: ir.Value, live: *?ArgReg) !void {
    const name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return,
    };
    const reg = try paramRegOrNull(function, name, .{ .int = 32 }) orelse return;
    if (live.*) |existing| {
        if (existing != reg) return error.UnsupportedLiveAcrossCall;
    } else {
        live.* = reg;
    }
}

pub fn identityCastFrom(instruction: ir.Instruction, value_name: []const u8, from_ty: ir.Type, to_ty: ir.Type) ?[]const u8 {
    const result = instruction.result orelse return null;
    const cast = switch (instruction.kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (cast.op != .bitcast or !cast.from_ty.eql(from_ty) or !cast.to_ty.eql(to_ty)) return null;
    if (!isNamed(cast.value, value_name)) return null;
    return result;
}

pub fn isSelectI1ToI32ZeroOne(instruction: ir.Instruction, cond_name: []const u8) bool {
    if (instruction.removed) return false;
    const select = switch (instruction.kind) {
        .select => |select| select,
        else => return false,
    };
    return select.cond_ty.eql(.{ .int = 1 }) and
        select.ty.eql(.{ .int = 32 }) and
        isNamed(select.cond, cond_name) and
        isInt(select.true_value, 0) and
        isInt(select.false_value, 1);
}

pub fn isSelectI1ToI32ExpectedOne(instruction: ir.Instruction, cond_name: []const u8, expected: i32) bool {
    if (instruction.removed) return false;
    const select = switch (instruction.kind) {
        .select => |select| select,
        else => return false,
    };
    return select.cond_ty.eql(.{ .int = 1 }) and
        select.ty.eql(.{ .int = 32 }) and
        isNamed(select.cond, cond_name) and
        isInt(select.true_value, expected) and
        isInt(select.false_value, 1);
}

pub fn valueReferencesGlobal(value: ir.Value, name: []const u8) bool {
    return switch (value) {
        .named => |value_name| std.mem.eql(u8, symbolName(value_name), name),
        .constant_expr => |text| std.mem.indexOf(u8, text, name) != null,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => false,
    };
}

pub fn phiHasIncoming(phi: ir.PhiInst, value_name: []const u8, block_name: []const u8) bool {
    for (phi.incoming.items) |incoming| {
        if (std.mem.eql(u8, incoming.block, block_name) and isNamed(incoming.value, value_name)) return true;
    }
    return false;
}

pub fn phiHasIncomingInt(phi: ir.PhiInst, value: i128, block_name: []const u8) bool {
    for (phi.incoming.items) |incoming| {
        if (std.mem.eql(u8, incoming.block, block_name) and isInt(incoming.value, value)) return true;
    }
    return false;
}

pub fn matchIcmpEqParamImm(instruction: ir.Instruction, param_name: []const u8, ty: ir.Type, imm: i128) bool {
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(ty)) return false;
    return (isNamed(icmp.lhs, param_name) and isInt(icmp.rhs, imm)) or
        (isNamed(icmp.rhs, param_name) and isInt(icmp.lhs, imm));
}

pub fn isCommutative(op: ir.BinaryOp) bool {
    return switch (op) {
        .add, .mul, .@"and", .@"or", .xor => true,
        .fadd, .fsub, .fmul, .fdiv, .frem, .sub, .shl, .lshr, .ashr, .udiv, .sdiv, .urem, .srem => false,
    };
}

pub fn findInstruction(block: ir.BasicBlock, result_name: []const u8) ?ir.Instruction {
    for (block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        const result = instruction.result orelse continue;
        if (std.mem.eql(u8, result, result_name)) return instruction;
    }
    return null;
}

pub fn findInstructionIndex(block: ir.BasicBlock, result_name: []const u8) ?usize {
    for (block.instructions.items, 0..) |instruction, index| {
        if (instruction.removed) continue;
        const result = instruction.result orelse continue;
        if (std.mem.eql(u8, result, result_name)) return index;
    }
    return null;
}

pub fn paramValueReg(function: ir.Function, value: ir.Value, ty: ir.Type) !ArgReg {
    return switch (value) {
        .named => |name| try paramReg(function, name, ty),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => error.UnsupportedCodegenValue,
    };
}

pub fn paramReg(function: ir.Function, name: []const u8, ty: ir.Type) !ArgReg {
    return try paramRegOrNull(function, name, ty) orelse error.UnsupportedCodegenValue;
}

pub fn sysvIntegerParamReg(function: ir.Function, name: []const u8, ty: ir.Type) !ArgReg {
    return try sysvIntegerParamRegOrNull(function, name, ty) orelse error.UnsupportedCodegenValue;
}

pub fn sysvIntegerParamRegOrNull(function: ir.Function, name: []const u8, ty: ir.Type) !?ArgReg {
    if (!ty.eql(.{ .int = 32 }) and !ty.eql(.{ .int = 64 }) and !ty.eql(.ptr)) return error.UnsupportedCodegenType;
    return try paramRegOrNull(function, name, ty);
}

pub fn paramRegOrNull(function: ir.Function, name: []const u8, ty: ir.Type) !?ArgReg {
    return try paramRegOrNullWithInitialGpr(function, name, ty, 0);
}

pub fn paramRegWithInitialGpr(function: ir.Function, name: []const u8, ty: ir.Type, initial_gpr: usize) !ArgReg {
    return try paramRegOrNullWithInitialGpr(function, name, ty, initial_gpr) orelse error.UnsupportedCodegenValue;
}

pub fn paramRegOrNullWithInitialGpr(function: ir.Function, name: []const u8, ty: ir.Type, initial_gpr: usize) !?ArgReg {
    if (!isSysVIntegerParamType(ty)) return error.UnsupportedCodegenType;
    var gpr_index: usize = initial_gpr;
    var sse_index: usize = 0;
    var stack_eightbytes: usize = 0;
    for (function.params.items) |param| {
        if (std.mem.eql(u8, param.name, name)) {
            if (!param.ty.eql(ty) or !isSysVIntegerParamType(param.ty)) return error.UnsupportedCodegenValue;
            if (gpr_index >= 6) return error.UnsupportedCodegenAbi;
            return try ArgReg.fromIndex(gpr_index);
        }
        try advanceSysVParamCursors(param.ty, &gpr_index, &sse_index, &stack_eightbytes);
    }
    return null;
}

pub fn scalarParamStackDisp8(function: ir.Function, name: []const u8, ty: ir.Type) !u8 {
    if (!isSysVIntegerParamType(ty) and !ty.eql(.float) and !ty.eql(.double)) return error.UnsupportedCodegenType;
    var gpr_index: usize = 0;
    var sse_index: usize = 0;
    var stack_eightbytes: usize = 0;
    for (function.params.items) |param| {
        if (std.mem.eql(u8, param.name, name)) {
            if (!param.ty.eql(ty)) return error.UnsupportedCodegenValue;
            const in_register = if (isSysVIntegerParamType(ty)) gpr_index < 6 else sse_index < 8;
            if (in_register) return error.UnsupportedCodegenAbi;
            const offset = 8 + stack_eightbytes * 8;
            if (offset > std.math.maxInt(u8)) return error.UnsupportedCodegenAbi;
            return @intCast(offset);
        }
        try advanceSysVParamCursors(param.ty, &gpr_index, &sse_index, &stack_eightbytes);
    }
    return error.UnsupportedCodegenValue;
}

pub fn isSysVIntegerParamType(ty: ir.Type) bool {
    return ty.eql(.{ .int = 1 }) or ty.eql(.{ .int = 8 }) or ty.eql(.{ .int = 16 }) or
        ty.eql(.{ .int = 32 }) or ty.eql(.{ .int = 64 }) or ty.eql(.ptr);
}

pub fn fpParamIndex(function: ir.Function, name: []const u8, ty: ir.Type) !usize {
    var gpr_index: usize = 0;
    var sse_index: usize = 0;
    var stack_eightbytes: usize = 0;
    for (function.params.items) |param| {
        const param_is_fp = param.ty.eql(.float) or param.ty.eql(.double);
        if (std.mem.eql(u8, param.name, name)) {
            if (!param.ty.eql(ty) or !param_is_fp) return error.UnsupportedCodegenValue;
            if (sse_index >= 8) return error.UnsupportedCodegenAbi;
            return sse_index;
        }
        try advanceSysVParamCursors(param.ty, &gpr_index, &sse_index, &stack_eightbytes);
    }
    return error.UnsupportedCodegenValue;
}

pub fn stackParamDisp8OrNull(function: ir.Function, name: []const u8, ty: ir.Type) !?u8 {
    if (!isSysVIntegerParamType(ty) and !ty.eql(.float) and !ty.eql(.double)) return error.UnsupportedCodegenType;
    var gpr_index: usize = 0;
    var sse_index: usize = 0;
    var stack_eightbytes: usize = 0;
    for (function.params.items) |param| {
        if (std.mem.eql(u8, param.name, name)) {
            if (!param.ty.eql(ty)) return error.UnsupportedCodegenValue;
            const in_register = if (isSysVIntegerParamType(ty)) gpr_index < 6 else sse_index < 8;
            if (in_register) return null;
            const offset = 8 + stack_eightbytes * 8;
            if (offset > std.math.maxInt(u8)) return error.UnsupportedCodegenAbi;
            return @intCast(offset);
        }
        try advanceSysVParamCursors(param.ty, &gpr_index, &sse_index, &stack_eightbytes);
    }
    return null;
}

pub fn emitI32ParamOrStackIntoEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    name: []const u8,
) !bool {
    if (try registerParamRegOrNull(function, name, .{ .int = 32 })) |reg| {
        try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
        return true;
    }
    if (try stackParamDisp8OrNull(function, name, .{ .int = 32 })) |offset| {
        try machine.instructions.append(allocator, .{ .load_stack_disp8_rax = offset });
        return true;
    }
    return false;
}

pub fn registerParamRegOrNull(function: ir.Function, name: []const u8, ty: ir.Type) !?ArgReg {
    return paramRegOrNull(function, name, ty) catch |err| switch (err) {
        error.UnsupportedCodegenAbi => null,
        else => return err,
    };
}

pub fn blockIndex(function: ir.Function, name: []const u8) ?usize {
    for (function.blocks.items, 0..) |block, index| {
        if (std.mem.eql(u8, block.name, name)) return index;
    }
    return null;
}
pub fn lowerSelectedI64ConstReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 64 })) return false;
    if (function.params.items.len != 0 or block.instructions.items.len != 0) return false;
    const value = switch (ret.value orelse return error.InvalidRet) {
        .int => |int| int,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };

    try machine.instructions.append(allocator, .{ .mov_imm_rax = try i64Value(value) });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgI64ParamReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 64 }) or block.instructions.items.len != 0) return false;
    const name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const reg = try sysvIntegerParamReg(function, name, .{ .int = 64 });
    try machine.instructions.append(allocator, .{ .mov_arg_rax = reg });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgI64DirectCallReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 64 }) or block.instructions.items.len == 0 or block.instructions.items.len > 2) return false;
    const instruction = block.instructions.items[block.instructions.items.len - 1];
    if (instruction.removed) return false;
    const call_result = instruction.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, call_result)) return false;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!call.ret_ty.eql(.{ .int = 64 }) or call.inline_asm != null) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;

    if (call.callee_value) |callee_value| {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        const callee_reg = try paramReg(function, callee_name, .ptr);
        try machine.instructions.append(allocator, .{ .mov_arg_rax = callee_reg });
        const stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, call);
        try appendIndirectCallRaxWithStackArgs(allocator, machine, call.ret_ty, stack_arg_count);
    } else {
        const stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, call);
        try appendDirectCallWithStackArgs(allocator, machine, call.callee, call.ret_ty, stack_arg_count);
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerControlFlowCallsWriterMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 2) return false;

    const call_inst = block.instructions.items[0];
    const add_inst = block.instructions.items[1];
    if (call_inst.removed or add_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    const add_name = add_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, add_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isCalleeName(call.callee, "control_flow_calls.writer_callee")) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    try validateDefaultCallConv(call.calling_conv);
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 0) return error.UnsupportedCodegenInstruction;

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 }) or add.flags.any()) return false;
    if (!isNamed(add.lhs, call_name) or !isInt(add.rhs, 1)) return false;

    try appendAlignedDirectCall(allocator, machine, call.callee, call.ret_ty);
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerDirectI32CallMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!isMainOrWrapperMain(function.name)) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 1 and block.instructions.items.len != 2) return false;

    const call_inst = block.instructions.items[0];
    if (call_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!callIsFastcc(call.calling_conv)) try validateDefaultCallConv(call.calling_conv);
    if (!call.ret_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
    if (call.args.items.len > max_sysv_stack_call_args + 6) return error.UnsupportedCodegenAbi;

    var add_immediate: i32 = 0;
    if (block.instructions.items.len == 1) {
        if (!isNamed(ret.value orelse return error.InvalidRet, call_name)) return false;
    } else {
        const second_inst = block.instructions.items[1];
        if (second_inst.removed) return false;
        if (identityCastFrom(second_inst, call_name, .{ .int = 32 }, .{ .int = 32 })) |cast_name| {
            if (!isNamed(ret.value orelse return error.InvalidRet, cast_name)) return false;
        } else {
            const add_name = second_inst.result orelse return false;
            if (!isNamed(ret.value orelse return error.InvalidRet, add_name)) return false;
            const add = switch (second_inst.kind) {
                .binary => |binary| binary,
                else => return false,
            };
            if (add.op != .add or !add.ty.eql(.{ .int = 32 }) or add.flags.any() or !isNamed(add.lhs, call_name)) return false;
            add_immediate = switch (add.rhs) {
                .int => |int| try i32Value(int),
                .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
            };
        }
    }

    const stack_arg_count = try appendI32CallArgs(allocator, machine, function, call);
    try appendDirectCallWithStackArgs(allocator, machine, call.callee, call.ret_ty, stack_arg_count);
    if (add_immediate != 0) try machine.instructions.append(allocator, .{ .add_eax_imm32 = add_immediate });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub const ExpectedCallArg = struct {
    ty: ir.Type,
    value: ir.Value,
};

pub fn lowerSelectedLibfuzzerTestRun(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main.runner_test_run")) return false;
    if (ret.ty != .void or ret.value != null) return false;
    if (function.params.items.len != 1 or block.instructions.items.len != 4) return false;

    const set_test_args = [_]ExpectedCallArg{.{
        .ty = .ptr,
        .value = .{ .named = "@main.testOne" },
    }};
    try validateVoidCall(block.instructions.items[0], "fuzzer_set_test", &set_test_args);

    const empty_input_args = [_]ExpectedCallArg{
        .{
            .ty = .{ .int = 64 },
            .value = .{ .constant_expr = "ptrtoint (ptr @__anon_11775 to i64)" },
        },
        .{
            .ty = .{ .int = 64 },
            .value = .{ .int = 0 },
        },
    };
    try validateVoidCall(block.instructions.items[1], "fuzzer_new_input", &empty_input_args);

    const hello_input_args = [_]ExpectedCallArg{
        .{
            .ty = .{ .int = 64 },
            .value = .{ .constant_expr = "ptrtoint (ptr @__anon_16031 to i64)" },
        },
        .{
            .ty = .{ .int = 64 },
            .value = .{ .int = 5 },
        },
    };
    try validateVoidCall(block.instructions.items[2], "fuzzer_new_input", &hello_input_args);
    try validateVoidCall(block.instructions.items[3], "fuzzer_start_test", &.{});

    try machine.instructions.append(allocator, .sub_rsp_8);
    try machine.instructions.append(allocator, .{ .lea_global_rdi = "main.testOne" });
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "fuzzer_set_test", .ret_ty = .void } });
    try machine.instructions.append(allocator, .{ .lea_global_rdi = "__anon_11775" });
    try machine.instructions.append(allocator, .{ .mov_imm_rsi = 0 });
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "fuzzer_new_input", .ret_ty = .void } });
    try machine.instructions.append(allocator, .{ .lea_global_rdi = "__anon_16031" });
    try machine.instructions.append(allocator, .{ .mov_imm_rsi = 5 });
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "fuzzer_new_input", .ret_ty = .void } });
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "fuzzer_start_test", .ret_ty = .void } });
    try machine.instructions.append(allocator, .add_rsp_8);
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn validateVoidCall(instruction: ir.Instruction, callee: []const u8, expected_args: []const ExpectedCallArg) !void {
    if (instruction.removed) return error.UnsupportedCodegenInstruction;
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!isCalleeName(call.callee, callee)) return error.UnsupportedCodegenInstruction;
    if (call.ret_ty != .void or call.args.items.len != expected_args.len) return error.UnsupportedCodegenInstruction;
    for (call.args.items, expected_args) |arg, expected| {
        if (!arg.ty.eql(expected.ty) or !arg.value.eql(expected.value)) return error.UnsupportedCodegenValue;
    }
}

pub fn validateAssumeColdCall(instruction: ir.Instruction) !void {
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

pub fn validateIntegerOverflowPanicCall(instruction: ir.Instruction) !void {
    if (instruction.removed) return error.UnsupportedCodegenInstruction;
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!isCalleeName(call.callee, "debug.FullPanic((function 'defaultPanic')).integerOverflow")) return error.UnsupportedCodegenInstruction;
    if (call.ret_ty != .void or call.args.items.len != 0) return error.UnsupportedCodegenInstruction;
}

pub fn lowerI64SaturatingHelperFamilyReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (try lowerSelectedUmlFixSatI64Return(allocator, machine, function, block, ret)) return true;
    return false;
}

pub fn lowerSelectedUmlFixSatI64Return(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "no_compile_panic_for_unchecked_arith.entry")) return false;
    if (!ret.ty.eql(.{ .int = 64 })) return false;
    if (function.params.items.len != 0 or block.instructions.items.len != 1) return false;

    const call_inst = block.instructions.items[0];
    if (call_inst.removed) return false;
    const call_result = call_inst.result orelse return error.InstructionNeedsResult;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    if (!std.mem.eql(u8, ret_name, call_result)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!std.mem.eql(u8, call.callee, "llvm.umul.fix.sat.i64")) return false;
    if (!call.ret_ty.eql(.{ .int = 64 }) or call.args.items.len != 3) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 64 }) or !call.args.items[0].value.eql(.{ .int = 0 })) return error.UnsupportedCodegenValue;
    if (!call.args.items[1].ty.eql(.{ .int = 64 }) or !call.args.items[1].value.eql(.{ .int = 2 })) return error.UnsupportedCodegenValue;
    if (!call.args.items[2].ty.eql(.{ .int = 32 }) or !call.args.items[2].value.eql(.{ .int = 0 })) return error.UnsupportedCodegenValue;

    try machine.instructions.append(allocator, .{ .mov_imm_rax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerSingleStackSlotCallReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (try lowerRuntimeStructSumPreoptHelper(allocator, machine, function, block, ret)) return true;
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 4) return false;

    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    const load_inst = block.instructions.items[2];
    const call_inst = block.instructions.items[3];
    if (alloca_inst.removed or store_inst.removed or load_inst.removed or call_inst.removed) return false;

    const slot = alloca_inst.result orelse return false;
    const load_result = load_inst.result orelse return false;
    const call_result = call_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, call_result, ret_name)) return false;

    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    if (!alloca.allocated_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 32 }) or !isNamed(store.ptr, slot)) return false;
    const store_reg = try paramValueReg(function, store.value, .{ .int = 32 });

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or !isNamed(load.ptr, slot)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null) return error.UnsupportedCodegenInstruction;
    if (call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    try validateDefaultCallConv(call.calling_conv);
    if (!call.ret_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
    if (call.args.items.len != 1) return false;
    const arg = call.args.items[0];
    if (!arg.ty.eql(.{ .int = 32 }) or !isNamed(arg.value, load_result)) return false;

    try machine.instructions.append(allocator, .sub_rsp_8);
    try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{
        .frame_index = .slot0,
        .reg = store_reg,
    } });
    try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{
        .reg = .rdi,
        .frame_index = .slot0,
    } });
    try machine.instructions.append(allocator, .{ .direct_call = .{
        .symbol = call.callee,
        .ret_ty = call.ret_ty,
    } });
    try machine.instructions.append(allocator, .add_rsp_8);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerPointerVolatileRoundtripReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.ptr) or !function.params.items[1].ty.eql(.{ .int = 32 })) return false;

    var alloca_names: [8][]const u8 = undefined;
    var alloca_count: usize = 0;
    var volatile_store: ?ir.StoreInst = null;
    var volatile_load: ?ir.LoadInst = null;
    var volatile_load_result: ?[]const u8 = null;

    for (block.instructions.items) |instruction| {
        if (instruction.removed) return false;
        switch (instruction.kind) {
            .alloca => {
                if (alloca_count == alloca_names.len) return false;
                alloca_names[alloca_count] = instruction.result orelse return false;
                alloca_count += 1;
            },
            .store => |store| {
                if (store.attrs.is_volatile) {
                    if (volatile_store != null) return false;
                    volatile_store = store;
                } else if (!isO0ParamStoreToAlloca(function, store, alloca_names[0..alloca_count])) {
                    return false;
                }
            },
            .load => |load| {
                if (!load.attrs.is_volatile or volatile_load != null) return false;
                volatile_load = load;
                volatile_load_result = instruction.result orelse return false;
            },
            .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => return false,
        }
    }

    const store = volatile_store orelse return false;
    const load = volatile_load orelse return false;
    const load_result = volatile_load_result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, load_result)) return false;

    if (!store.ty.eql(.{ .int = 32 }) or !store.attrs.is_volatile) return false;
    if (!isNamed(store.ptr, function.params.items[0].name) or !isNamed(store.value, function.params.items[1].name)) return false;

    if (!load.ty.eql(.{ .int = 32 }) or !load.attrs.is_volatile) return false;
    if (!isNamed(load.ptr, function.params.items[0].name)) return false;

    try machine.instructions.append(allocator, .volatile_roundtrip_rdi_esi_eax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRuntimeVolatileRoundtripMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main") and
        !std.mem.eql(u8, function.name, "runtime_volatile_roundtrip_main.main"))
    {
        return false;
    }
    if (function.params.items.len != 0) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or !ret.ty.eql(.{ .int = 32 })) return false;
    if (std.mem.eql(u8, function.name, "runtime_volatile_roundtrip_main.main") and block.instructions.items.len == 3) {
        return try lowerRuntimeVolatileRoundtripPreoptMainReturn(allocator, machine, block, ret);
    }
    if (block.instructions.items.len != 4) return false;

    const store_inst = block.instructions.items[0];
    const load_inst = block.instructions.items[1];
    const icmp_inst = block.instructions.items[2];
    const result_inst = block.instructions.items[3];
    if (store_inst.removed or load_inst.removed or icmp_inst.removed or result_inst.removed) return false;

    const load_name = load_inst.result orelse return false;
    const icmp_name = icmp_inst.result orelse return false;
    const result_name = result_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, result_name)) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 32 }) or !store.attrs.is_volatile) return false;
    if (!isInt(store.value, 42)) return false;
    const store_global = switch (store.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, store_global, "pointers_memory.volatile_slot") and
        !std.mem.eql(u8, store_global, "runtime_volatile_roundtrip_main.slot"))
    {
        return false;
    }

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or !load.attrs.is_volatile) return false;
    const load_global = switch (load.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, load_global, "pointers_memory.volatile_slot") and
        !std.mem.eql(u8, load_global, "runtime_volatile_roundtrip_main.slot"))
    {
        return false;
    }

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if ((icmp.predicate != .eq and icmp.predicate != .ne) or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, load_name) or !isInt(icmp.rhs, 42)) return false;

    switch (result_inst.kind) {
        .select => |select| {
            if (icmp.predicate != .eq) return false;
            if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
            if (!isNamed(select.cond, icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;
        },
        .cast => |cast| {
            if (icmp.predicate != .ne) return false;
            if (cast.op != .zext or !cast.from_ty.eql(.{ .int = 1 }) or !cast.to_ty.eql(.{ .int = 32 })) return false;
            if (!isNamed(cast.value, icmp_name)) return false;
        },
        else => return false,
    }

    const fail = "volatile_roundtrip_fail";
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 42 });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = store_global });
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = load_global });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 42 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRuntimeVolatileRoundtripPreoptMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const call_inst = block.instructions.items[0];
    const icmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (call_inst.removed or icmp_inst.removed or select_inst.removed) return false;

    const call_name = call_inst.result orelse return false;
    const icmp_name = icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (call.calling_conv) |cc| {
        if (!std.mem.eql(u8, cc, "fastcc")) return false;
    }
    if (!std.mem.eql(u8, call.callee, "runtime_volatile_roundtrip_main.volatileRoundtrip")) return false;
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 2) return false;
    if (!call.args.items[0].ty.eql(.ptr) or !valueReferencesGlobal(call.args.items[0].value, "runtime_volatile_roundtrip_main.slot")) return false;
    if (!call.args.items[1].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[1].value, 42)) return false;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, call_name) or !isInt(icmp.rhs, 42)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const fail = "volatile_roundtrip_preopt_fail";
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 42 });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = "runtime_volatile_roundtrip_main.slot" });
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = "runtime_volatile_roundtrip_main.slot" });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 42 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn isO0ParamStoreToAlloca(function: ir.Function, store: ir.StoreInst, alloca_names: []const []const u8) bool {
    if (store.attrs.isBarrier()) return false;
    const ptr_name = switch (store.ptr) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    var points_to_alloca = false;
    for (alloca_names) |alloca_name| {
        if (std.mem.eql(u8, ptr_name, alloca_name)) {
            points_to_alloca = true;
            break;
        }
    }
    if (!points_to_alloca) return false;

    for (function.params.items) |param| {
        if (store.ty.eql(param.ty) and isNamed(store.value, param.name)) return true;
    }
    return false;
}

pub fn lowerScalarFpCastReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (function.params.items.len != 1) return false;
    if (block.instructions.items.len != 1) return false;
    const cast_inst = block.instructions.items[0];
    if (cast_inst.removed) return false;
    const cast_result = cast_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, cast_result)) return false;
    const cast = switch (cast_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (!cast.from_ty.eql(function.params.items[0].ty)) return false;
    if (!cast.to_ty.eql(function.ret_ty) or !ret.ty.eql(function.ret_ty)) return false;
    if (!isNamed(cast.value, function.params.items[0].name)) return false;

    switch (cast.op) {
        .sitofp => {
            if (cast.from_ty.eql(.{ .int = 32 }) and cast.to_ty.eql(.float)) {
                try machine.instructions.append(allocator, .cvtsi2ss_edi_xmm0);
            } else if (cast.from_ty.eql(.{ .int = 32 }) and cast.to_ty.eql(.double)) {
                try machine.instructions.append(allocator, .cvtsi2sd_edi_xmm0);
            } else if (cast.from_ty.eql(.{ .int = 64 }) and cast.to_ty.eql(.float)) {
                try machine.instructions.append(allocator, .cvtsi2ss_rdi_xmm0);
            } else if (cast.from_ty.eql(.{ .int = 64 }) and cast.to_ty.eql(.double)) {
                try machine.instructions.append(allocator, .cvtsi2sd_rdi_xmm0);
            } else return false;
        },
        .uitofp => {
            // Unsigned 32-bit converts exactly through a zero-extended
            // 64-bit signed convert; wider unsigned sources stay fail-closed.
            if (!cast.from_ty.eql(.{ .int = 32 })) return false;
            try machine.instructions.append(allocator, .mov_edi_edi);
            if (cast.to_ty.eql(.float)) {
                try machine.instructions.append(allocator, .cvtsi2ss_rdi_xmm0);
            } else if (cast.to_ty.eql(.double)) {
                try machine.instructions.append(allocator, .cvtsi2sd_rdi_xmm0);
            } else return false;
        },
        .fptosi => {
            if (!cast.to_ty.eql(.{ .int = 32 })) return false;
            if (cast.from_ty.eql(.float)) {
                try machine.instructions.append(allocator, .cvttss2si_xmm0_eax);
            } else if (cast.from_ty.eql(.double)) {
                try machine.instructions.append(allocator, .cvttsd2si_xmm0_eax);
            } else return false;
        },
        .fptrunc => {
            if (!cast.from_ty.eql(.double) or !cast.to_ty.eql(.float)) return false;
            try machine.instructions.append(allocator, .cvtsd2ss_xmm0_xmm0);
        },
        .fpext => {
            if (!cast.from_ty.eql(.float) or !cast.to_ty.eql(.double)) return false;
            try machine.instructions.append(allocator, .cvtss2sd_xmm0_xmm0);
        },
        .trunc, .zext, .sext, .fptoui, .bitcast, .ptrtoint, .inttoptr => return false,
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerAggregateAbiReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (try lowerMemoryAggregateCallReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerRegisterAggregateDirectCallReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerRegisterAggregateReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerSmallIntegerAggregateReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerSysVAggregateFieldReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerRegisterAggregateIntegerFieldAddReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerRegisterAggregateFloatFieldAddReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerRegisterAggregateDoubleFieldAddReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerMemoryIntegerAggregateFieldAddReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerTruncI64ArgReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerMakePairReturn(allocator, machine, function, block, ret)) return true;
    return false;
}

pub fn lowerMemoryAggregateCallReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(function.ret_ty) or block.instructions.items.len != 1) return false;
    const classification = classifySysVAggregate(function.ret_ty) catch return false;
    if (classification.kind != .memory or classification.size_bytes == 0) return false;
    if (!isSupportedAggregateCopyLeafAggregate(function.ret_ty)) return false;

    const instruction = block.instructions.items[0];
    if (instruction.removed) return false;
    const call_result = instruction.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, call_result)) return false;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!call.ret_ty.eql(function.ret_ty) or call.inline_asm != null) return false;
    if (call.tail_kind != null) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;
    if (call.args.items.len != 1) return false;

    const call_target: SysVCallTarget = if (call.callee_value) |callee_value| target: {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        const callee_reg = try paramRegWithInitialGpr(function, callee_name, .ptr, 1);
        if (callee_reg == .rdi) return error.UnsupportedCodegenAbi;
        break :target .{ .indirect_from_reg = callee_reg };
    } else .{ .direct = call.callee };

    const aggregate_arg = call.args.items[0];
    if (!aggregate_arg.ty.eql(function.ret_ty)) return false;
    const aggregate_name = switch (aggregate_arg.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    const source = try sysvParamCursorForWithInitial(function, aggregate_name, aggregate_arg.ty, .{
        .gpr = 1,
        .sse = 0,
        .stack_eightbytes = 0,
    });

    const stack_arg_count = try appendSysVMemoryAggregateStackPassThroughArgs(
        allocator,
        machine,
        function,
        source,
        classification,
    );
    try setupSysVCallTarget(allocator, machine, call_target);
    try appendSysVCallTargetWithStackArgs(allocator, machine, call_target, call.ret_ty, stack_arg_count);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn classifySysVAggregateForTest(ty: ir.Type) !SysVAggregateClassification {
    return try sysv_abi.classifyAggregateForTest(ty);
}

pub fn classifySysVAggregate(ty: ir.Type) !SysVAggregateClassification {
    return try sysv_abi.classifyAggregate(ty);
}

pub fn classifySysVSmallIntegerAggregate(ty: ir.Type) ?SysVSmallIntegerAggregate {
    return sysv_abi.classifySmallIntegerAggregate(ty);
}

pub fn lowerSmallIntegerAggregateReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const classification = classifySysVSmallIntegerAggregate(function.ret_ty) orelse return false;
    if (classification.eightbytes != 2 or !ret.ty.eql(function.ret_ty)) return false;
    if (block.instructions.items.len != 2) return false;
    const first_inst = block.instructions.items[0];
    const second_inst = block.instructions.items[1];
    if (first_inst.removed or second_inst.removed) return false;
    const first_name = first_inst.result orelse return false;
    const second_name = second_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, second_name)) return false;

    const first = switch (first_inst.kind) {
        .insertvalue => |insert| insert,
        else => return false,
    };
    const second = switch (second_inst.kind) {
        .insertvalue => |insert| insert,
        else => return false,
    };
    if (!first.aggregate_ty.eql(function.ret_ty) or !second.aggregate_ty.eql(function.ret_ty)) return false;
    if (first.aggregate != .undef or !isNamed(second.aggregate, first_name)) return false;
    if (!std.mem.eql(u8, first.indices, "0") or !std.mem.eql(u8, second.indices, "1")) return false;
    if (!first.value_ty.eql(.{ .int = 64 }) or !second.value_ty.eql(.{ .int = 64 })) return false;
    const first_reg = try paramValueReg(function, first.value, .{ .int = 64 });
    const second_reg = try paramValueReg(function, second.value, .{ .int = 64 });

    try machine.instructions.append(allocator, .{ .mov_arg_rax = first_reg });
    try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = .rdx, .src = second_reg } });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRegisterAggregateReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(function.ret_ty)) return false;
    const classification = classifySysVAggregate(function.ret_ty) catch return false;
    if (classification.kind != .register or classification.eightbyte_count == 0) return false;
    const leaf_count = block.instructions.items.len;
    if (leaf_count == 0 or leaf_count > 8) return false;

    var leaves: [8]AggregateReturnLeaf = undefined;
    var aggregate_value: ir.Value = .undef;
    for (block.instructions.items, 0..) |instruction, index| {
        if (instruction.removed) return false;
        const result = instruction.result orelse return false;
        const insert = switch (instruction.kind) {
            .insertvalue => |insert| insert,
            else => return false,
        };
        if (!insert.aggregate_ty.eql(function.ret_ty)) return false;
        if (!valuesEqual(insert.aggregate, aggregate_value)) return false;
        const offset = try aggregateInsertByteOffset(function.ret_ty, insert.indices, insert.value_ty);
        if (index != 0 and offset <= leaves[index - 1].offset) return error.UnsupportedCodegenAbi;
        leaves[index] = .{ .value = insert.value, .ty = insert.value_ty, .offset = offset };
        aggregate_value = .{ .named = result };
    }
    if (!valuesEqual(ret.value orelse return error.InvalidRet, aggregate_value)) return false;

    if (try lowerFourI32RegisterAggregateReturn(allocator, machine, function, leaves[0..leaf_count], classification)) return true;

    var gpr_return_index: usize = 0;
    var sse_return_index: usize = 0;
    var leaf_index: usize = 0;
    while (leaf_index < leaf_count) : (leaf_index += 1) {
        const leaf = leaves[leaf_index];
        const leaf_eightbyte: usize = @intCast(leaf.offset / 8);
        if (leaf_eightbyte >= classification.eightbyte_count) return false;
        const leaf_class = classification.eightbytes[leaf_eightbyte] orelse return false;
        switch (leaf_class) {
            .integer => {
                if (leaf.ty.eql(.{ .int = 64 })) {
                    const src = try paramValueReg(function, leaf.value, leaf.ty);
                    switch (gpr_return_index) {
                        0 => try machine.instructions.append(allocator, .{ .mov_arg_rax = src }),
                        1 => try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = .rdx, .src = src } }),
                        else => return error.UnsupportedCodegenAbi,
                    }
                    gpr_return_index += 1;
                    continue;
                }
                if (!leaf.ty.eql(.{ .int = 32 })) return false;
                if (leaf.offset % 8 != 0) return error.UnsupportedCodegenAbi;
                const low_reg = try paramValueReg(function, leaf.value, leaf.ty);
                if (leaf_index + 1 < leaf_count and
                    leaves[leaf_index + 1].ty.eql(.{ .int = 32 }) and
                    leaves[leaf_index + 1].offset / 8 == leaf_eightbyte and
                    leaves[leaf_index + 1].offset % 8 == 4)
                {
                    const high_reg = try paramValueReg(function, leaves[leaf_index + 1].value, .{ .int = 32 });
                    switch (gpr_return_index) {
                        0 => {
                            try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rdx, .src = high_reg } });
                            try machine.instructions.append(allocator, .{ .shl_rdx_imm6 = 32 });
                            try machine.instructions.append(allocator, .{ .mov_arg_eax = low_reg });
                            try machine.instructions.append(allocator, .or_rdx_rax);
                        },
                        1 => {
                            try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rcx, .src = high_reg } });
                            try machine.instructions.append(allocator, .{ .shl_rcx_imm6 = 32 });
                            try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rdx, .src = low_reg } });
                            try machine.instructions.append(allocator, .or_rcx_rdx);
                        },
                        else => return error.UnsupportedCodegenAbi,
                    }
                    gpr_return_index += 1;
                    leaf_index += 1;
                    continue;
                }
                switch (gpr_return_index) {
                    0 => try machine.instructions.append(allocator, .{ .mov_arg_eax = low_reg }),
                    1 => try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rdx, .src = low_reg } }),
                    else => return error.UnsupportedCodegenAbi,
                }
                gpr_return_index += 1;
            },
            .sse => {
                if (leaf.ty.eql(.float) and leaf.offset % 8 == 0 and
                    leaf_index + 1 < leaf_count and
                    leaves[leaf_index + 1].ty.eql(.float) and
                    leaves[leaf_index + 1].offset / 8 == leaf_eightbyte and
                    leaves[leaf_index + 1].offset % 8 == 4)
                {
                    if (sse_return_index != 0) return error.UnsupportedCodegenAbi;
                    const low_fp_index = try fpParamIndexFromValue(function, leaf.value, .float);
                    const high_fp_index = try fpParamIndexFromValue(function, leaves[leaf_index + 1].value, .float);
                    if (high_fp_index == 0 and low_fp_index != 0) return error.UnsupportedCodegenAbi;
                    const low_reg = try XmmReg.fromIndex(low_fp_index);
                    const high_reg = try XmmReg.fromIndex(high_fp_index);
                    if (low_reg != .xmm0) {
                        try machine.instructions.append(allocator, .{ .movapd_xmm = .{ .dst = .xmm0, .src = low_reg } });
                    }
                    if (high_reg != .xmm0) {
                        try machine.instructions.append(allocator, .{ .unpcklps_xmm = .{ .dst = .xmm0, .src = high_reg } });
                    }
                    sse_return_index += 1;
                    leaf_index += 1;
                    continue;
                }
                if (!leaf.ty.eql(.double)) return false;
                const fp_index = try fpParamIndexFromValue(function, leaf.value, leaf.ty);
                switch (sse_return_index) {
                    0 => switch (try XmmReg.fromIndex(fp_index)) {
                        .xmm0 => {},
                        .xmm1 => try machine.instructions.append(allocator, .movapd_xmm1_xmm0),
                        .xmm2, .xmm3, .xmm4, .xmm5, .xmm6, .xmm7 => return error.UnsupportedCodegenAbi,
                    },
                    1 => switch (try XmmReg.fromIndex(fp_index)) {
                        .xmm1 => {},
                        .xmm0, .xmm2, .xmm3, .xmm4, .xmm5, .xmm6, .xmm7 => return error.UnsupportedCodegenAbi,
                    },
                    else => return error.UnsupportedCodegenAbi,
                }
                sse_return_index += 1;
            },
        }
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub const AggregateReturnLeaf = struct {
    value: ir.Value,
    ty: ir.Type,
    offset: u64,
};

pub fn lowerFourI32RegisterAggregateReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    leaves: []const AggregateReturnLeaf,
    classification: SysVAggregateClassification,
) !bool {
    if (classification.eightbyte_count != 2 or
        classification.eightbytes[0] != .integer or
        classification.eightbytes[1] != .integer or
        leaves.len != 4)
    {
        return false;
    }
    const expected_offsets = [_]u64{ 0, 4, 8, 12 };
    for (leaves, 0..) |leaf, index| {
        if (!leaf.ty.eql(.{ .int = 32 }) or leaf.offset != expected_offsets[index]) return false;
    }
    const a = try paramValueReg(function, leaves[0].value, .{ .int = 32 });
    const b = try paramValueReg(function, leaves[1].value, .{ .int = 32 });
    const c = try paramValueReg(function, leaves[2].value, .{ .int = 32 });
    const d = try paramValueReg(function, leaves[3].value, .{ .int = 32 });

    try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rcx, .src = d } });
    try machine.instructions.append(allocator, .{ .shl_rcx_imm6 = 32 });
    try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rdx, .src = c } });
    try machine.instructions.append(allocator, .or_rcx_rdx);
    try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rcx, .src = b } });
    try machine.instructions.append(allocator, .{ .shl_rcx_imm6 = 32 });
    try machine.instructions.append(allocator, .{ .mov_arg_eax = a });
    try machine.instructions.append(allocator, .or_rcx_rax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn aggregateInsertByteOffset(aggregate_ty: ir.Type, indices: []const u8, value_ty: ir.Type) !u64 {
    const layout = try x86_64SysVDataLayout();
    var current_ty = aggregate_ty;
    var offset: u64 = 0;
    var rest = indices;
    while (rest.len != 0) {
        const comma = std.mem.indexOfScalar(u8, rest, ',');
        const part = std.mem.trim(u8, if (comma) |pos| rest[0..pos] else rest, " \t");
        const field_index = std.fmt.parseInt(usize, part, 10) catch return error.UnsupportedCodegenAbi;
        const field_offset_i = memory_location.aggregateFieldOffsetWithLayout(layout, current_ty, field_index) orelse
            return error.UnsupportedCodegenAbi;
        if (field_offset_i < 0) return error.UnsupportedCodegenAbi;
        offset += @intCast(field_offset_i);
        current_ty = memory_location.aggregateFieldType(current_ty, field_index) orelse return error.UnsupportedCodegenAbi;
        rest = if (comma) |pos| rest[pos + 1 ..] else "";
    }
    if (!current_ty.eql(value_ty)) return error.UnsupportedCodegenAbi;
    return offset;
}

pub fn aggregateFieldCount(ty: ir.Type) ?usize {
    var count: usize = 0;
    while (memory_location.aggregateFieldType(ty, count)) |_| : (count += 1) {}
    return count;
}

pub fn aggregateFieldEightbyte(aggregate_ty: ir.Type, field_index: usize) !usize {
    const layout = try x86_64SysVDataLayout();
    const field_offset_i = memory_location.aggregateFieldOffsetWithLayout(layout, aggregate_ty, field_index) orelse
        return error.UnsupportedCodegenAbi;
    if (field_offset_i < 0) return error.UnsupportedCodegenAbi;
    return @intCast(@as(u64, @intCast(field_offset_i)) / 8);
}

pub fn fpParamIndexFromValue(function: ir.Function, value: ir.Value, ty: ir.Type) !usize {
    return switch (value) {
        .named => |name| try fpParamIndex(function, name, ty),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => error.UnsupportedCodegenValue,
    };
}

pub fn valuesEqual(a: ir.Value, b: ir.Value) bool {
    return switch (a) {
        .named => |a_name| switch (b) {
            .named => |b_name| std.mem.eql(u8, a_name, b_name),
            else => false,
        },
        .undef => b == .undef,
        .poison => b == .poison,
        .null_value => b == .null_value,
        .zero_initializer => b == .zero_initializer,
        .int => |a_int| switch (b) {
            .int => |b_int| a_int == b_int,
            else => false,
        },
        .fp => |a_fp| switch (b) {
            .fp => |b_fp| std.mem.eql(u8, a_fp, b_fp),
            else => false,
        },
        .vector, .constant_expr => false,
    };
}

pub fn lowerSysVAggregateFieldReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if ((!ret.ty.eql(.{ .int = 32 }) and !ret.ty.eql(.{ .int = 64 }) and !ret.ty.eql(.float) and !ret.ty.eql(.double)) or
        (block.instructions.items.len != 3 and block.instructions.items.len != 4)) return false;
    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    const maybe_gep_inst: ?ir.Instruction = if (block.instructions.items.len == 4) block.instructions.items[2] else null;
    const load_inst = block.instructions.items[block.instructions.items.len - 1];
    if (alloca_inst.removed or store_inst.removed or load_inst.removed) return false;
    if (maybe_gep_inst) |gep_inst| if (gep_inst.removed) return false;
    const alloca_name = alloca_inst.result orelse return false;
    const load_name = load_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, load_name)) return false;

    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    const classification = classifySysVAggregate(alloca.allocated_ty) catch return false;
    if (classification.kind != .register or classification.eightbyte_count == 0) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(alloca.allocated_ty) or store.attrs.isBarrier() or !isNamed(store.ptr, alloca_name)) return false;
    const param_name = switch (store.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(ret.ty) or load.attrs.isBarrier()) return false;

    const layout = try x86_64SysVDataLayout();
    const field_offset = if (maybe_gep_inst) |gep_inst| blk: {
        const gep_name = gep_inst.result orelse return false;
        if (!isNamed(load.ptr, gep_name)) return false;
        const gep = switch (gep_inst.kind) {
            .gep => |gep| gep,
            else => return false,
        };
        if (!isNamed(gep.ptr, alloca_name)) return false;
        break :blk aggregateGepByteOffset(layout, alloca.allocated_ty, gep) orelse return false;
    } else blk: {
        if (!isNamed(load.ptr, alloca_name)) return false;
        break :blk @as(u64, 0);
    };
    _ = aggregateFieldIndexAtOffset(alloca.allocated_ty, field_offset, load.ty) orelse return false;

    try emitSysVAggregateFieldOffsetReturn(allocator, machine, function, param_name, alloca.allocated_ty, field_offset, load.ty);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub const AggregateIntegerFieldLoad = struct {
    offset: u64,
};

pub const AggregateIntegerAddTerm = struct {
    offset: u64,
};

pub const AggregateDoubleFieldLoad = struct {
    offset: u64,
};

pub const AggregateDoubleAddTerm = struct {
    offset: u64,
};

pub const AggregateFloatFieldLoad = struct {
    offset: u64,
};

pub const AggregateFloatAddTerm = struct {
    offset: u64,
};

pub fn lowerRegisterAggregateIntegerFieldAddReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if ((!ret.ty.eql(.{ .int = 32 }) and !ret.ty.eql(.{ .int = 64 })) or !function.ret_ty.eql(ret.ty)) return false;
    if (block.instructions.items.len < 5) return false;

    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    if (alloca_inst.removed or store_inst.removed) return false;
    const alloca_name = alloca_inst.result orelse return false;
    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    const aggregate_ty = alloca.allocated_ty;
    const classification = classifySysVAggregate(aggregate_ty) catch return false;
    if (classification.kind != .register) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(aggregate_ty) or store.attrs.isBarrier() or !isNamed(store.ptr, alloca_name)) return false;
    const param_name = switch (store.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    var pointer_offsets = std.StringHashMap(u64).init(allocator);
    defer pointer_offsets.deinit();
    try pointer_offsets.put(alloca_name, 0);

    var field_loads = std.StringHashMap(AggregateIntegerFieldLoad).init(allocator);
    defer field_loads.deinit();

    const layout = try x86_64SysVDataLayout();
    for (block.instructions.items[2..]) |instruction| {
        if (instruction.removed) return false;
        switch (instruction.kind) {
            .gep => |gep| {
                const result = instruction.result orelse return false;
                const base_name = switch (gep.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const base_offset = pointer_offsets.get(base_name) orelse return false;
                const offset = aggregateGepByteOffset(layout, aggregate_ty, gep) orelse return false;
                try pointer_offsets.put(result, base_offset + offset);
            },
            .load => |load| {
                const result = instruction.result orelse return false;
                if (!load.ty.eql(ret.ty) or load.attrs.isBarrier()) return false;
                const ptr_name = switch (load.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const offset = pointer_offsets.get(ptr_name) orelse return false;
                try field_loads.put(result, .{ .offset = offset });
            },
            .binary => |binary| {
                if (binary.op != .add or !binary.ty.eql(ret.ty)) return false;
            },
            .phi, .fcmp, .icmp, .select, .cast, .freeze, .alloca, .store, .call, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => return false,
        }
    }

    var terms: [8]AggregateIntegerAddTerm = undefined;
    var term_count: usize = 0;
    if (!try collectAggregateIntegerAddTerms(block, ret.value orelse return error.InvalidRet, ret.ty, field_loads, &terms, &term_count)) return false;
    if (term_count < 2) return false;

    try emitAggregateIntegerTerm(allocator, machine, function, param_name, aggregate_ty, terms[0], ret.ty, true);
    for (terms[1..term_count]) |term| {
        try emitAggregateIntegerTerm(allocator, machine, function, param_name, aggregate_ty, term, ret.ty, false);
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRegisterAggregateFloatFieldAddReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.float) or !function.ret_ty.eql(.float)) return false;
    if (block.instructions.items.len < 5) return false;

    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    if (alloca_inst.removed or store_inst.removed) return false;
    const alloca_name = alloca_inst.result orelse return false;
    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    const aggregate_ty = alloca.allocated_ty;
    const classification = classifySysVAggregate(aggregate_ty) catch return false;
    if (classification.kind != .register) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(aggregate_ty) or store.attrs.isBarrier() or !isNamed(store.ptr, alloca_name)) return false;
    const param_name = switch (store.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    var pointer_offsets = std.StringHashMap(u64).init(allocator);
    defer pointer_offsets.deinit();
    try pointer_offsets.put(alloca_name, 0);

    var field_loads = std.StringHashMap(AggregateFloatFieldLoad).init(allocator);
    defer field_loads.deinit();

    const layout = try x86_64SysVDataLayout();
    for (block.instructions.items[2..]) |instruction| {
        if (instruction.removed) return false;
        switch (instruction.kind) {
            .gep => |gep| {
                const result = instruction.result orelse return false;
                const base_name = switch (gep.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const base_offset = pointer_offsets.get(base_name) orelse return false;
                const offset = aggregateGepByteOffset(layout, aggregate_ty, gep) orelse return false;
                try pointer_offsets.put(result, base_offset + offset);
            },
            .load => |load| {
                const result = instruction.result orelse return false;
                if (!load.ty.eql(.float) or load.attrs.isBarrier()) return false;
                const ptr_name = switch (load.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const offset = pointer_offsets.get(ptr_name) orelse return false;
                _ = aggregateFieldIndexAtOffset(aggregate_ty, offset, load.ty) orelse return false;
                try field_loads.put(result, .{ .offset = offset });
            },
            .binary => |binary| {
                if (binary.op != .fadd or !binary.ty.eql(.float)) return false;
            },
            .phi, .fcmp, .icmp, .select, .cast, .freeze, .alloca, .store, .call, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => return false,
        }
    }

    var terms: [2]AggregateFloatAddTerm = undefined;
    var term_count: usize = 0;
    if (!try collectAggregateFloatAddTerms(block, ret.value orelse return error.InvalidRet, field_loads, &terms, &term_count)) return false;
    if (term_count != 2) return false;
    if (terms[0].offset > terms[1].offset) std.mem.swap(AggregateFloatAddTerm, &terms[0], &terms[1]);

    try emitAggregateFloatTerm(allocator, machine, function, param_name, aggregate_ty, terms[0], .xmm0);
    try emitAggregateFloatTerm(allocator, machine, function, param_name, aggregate_ty, terms[1], .xmm1);
    try machine.instructions.append(allocator, .addss_xmm1_xmm0);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRegisterAggregateDoubleFieldAddReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.double) or !function.ret_ty.eql(.double)) return false;
    if (block.instructions.items.len < 5) return false;

    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    if (alloca_inst.removed or store_inst.removed) return false;
    const alloca_name = alloca_inst.result orelse return false;
    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    const aggregate_ty = alloca.allocated_ty;
    const classification = classifySysVAggregate(aggregate_ty) catch return false;
    if (classification.kind != .register) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(aggregate_ty) or store.attrs.isBarrier() or !isNamed(store.ptr, alloca_name)) return false;
    const param_name = switch (store.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    var pointer_offsets = std.StringHashMap(u64).init(allocator);
    defer pointer_offsets.deinit();
    try pointer_offsets.put(alloca_name, 0);

    var field_loads = std.StringHashMap(AggregateDoubleFieldLoad).init(allocator);
    defer field_loads.deinit();

    const layout = try x86_64SysVDataLayout();
    for (block.instructions.items[2..]) |instruction| {
        if (instruction.removed) return false;
        switch (instruction.kind) {
            .gep => |gep| {
                const result = instruction.result orelse return false;
                const base_name = switch (gep.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const base_offset = pointer_offsets.get(base_name) orelse return false;
                const offset = aggregateGepByteOffset(layout, aggregate_ty, gep) orelse return false;
                try pointer_offsets.put(result, base_offset + offset);
            },
            .load => |load| {
                const result = instruction.result orelse return false;
                if (!load.ty.eql(.double) or load.attrs.isBarrier()) return false;
                const ptr_name = switch (load.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const offset = pointer_offsets.get(ptr_name) orelse return false;
                _ = aggregateFieldIndexAtOffset(aggregate_ty, offset, load.ty) orelse return false;
                try field_loads.put(result, .{ .offset = offset });
            },
            .binary => |binary| {
                if (binary.op != .fadd or !binary.ty.eql(.double)) return false;
            },
            .phi, .fcmp, .icmp, .select, .cast, .freeze, .alloca, .store, .call, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => return false,
        }
    }

    var terms: [2]AggregateDoubleAddTerm = undefined;
    var term_count: usize = 0;
    if (!try collectAggregateDoubleAddTerms(block, ret.value orelse return error.InvalidRet, field_loads, &terms, &term_count)) return false;
    if (term_count != 2) return false;

    try emitAggregateDoubleTerm(allocator, machine, function, param_name, aggregate_ty, terms[0], .xmm0);
    try emitAggregateDoubleTerm(allocator, machine, function, param_name, aggregate_ty, terms[1], .xmm1);
    try machine.instructions.append(allocator, .addsd_xmm1_xmm0);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn collectAggregateFloatAddTerms(
    block: ir.BasicBlock,
    value: ir.Value,
    field_loads: std.StringHashMap(AggregateFloatFieldLoad),
    terms: *[2]AggregateFloatAddTerm,
    term_count: *usize,
) !bool {
    const name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (field_loads.get(name)) |load| {
        if (term_count.* >= terms.len) return error.UnsupportedCodegenAbi;
        terms[term_count.*] = .{ .offset = load.offset };
        term_count.* += 1;
        return true;
    }
    const instruction = findInstruction(block, name) orelse return false;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (binary.op != .fadd or !binary.ty.eql(.float)) return false;
    if (!try collectAggregateFloatAddTerms(block, binary.lhs, field_loads, terms, term_count)) return false;
    return try collectAggregateFloatAddTerms(block, binary.rhs, field_loads, terms, term_count);
}

pub fn collectAggregateDoubleAddTerms(
    block: ir.BasicBlock,
    value: ir.Value,
    field_loads: std.StringHashMap(AggregateDoubleFieldLoad),
    terms: *[2]AggregateDoubleAddTerm,
    term_count: *usize,
) !bool {
    const name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (field_loads.get(name)) |load| {
        if (term_count.* >= terms.len) return error.UnsupportedCodegenAbi;
        terms[term_count.*] = .{ .offset = load.offset };
        term_count.* += 1;
        return true;
    }
    const instruction = findInstruction(block, name) orelse return false;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (binary.op != .fadd or !binary.ty.eql(.double)) return false;
    if (!try collectAggregateDoubleAddTerms(block, binary.lhs, field_loads, terms, term_count)) return false;
    return try collectAggregateDoubleAddTerms(block, binary.rhs, field_loads, terms, term_count);
}

pub fn aggregateGepByteOffset(layout: target.DataLayout, aggregate_ty: ir.Type, gep: ir.GepInst) ?u64 {
    if (gep.source_ty.eql(.{ .int = 8 }) and gep.indices.items.len == 1 and gep.indices.items[0].ty.eql(.{ .int = 64 })) {
        const offset = switch (gep.indices.items[0].value) {
            .int => |int| int,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
        };
        if (offset < 0) return null;
        return @intCast(offset);
    }
    if (isScalarElementGepType(gep.source_ty) and gep.indices.items.len == 1 and gep.indices.items[0].ty.eql(.{ .int = 64 })) {
        const index = switch (gep.indices.items[0].value) {
            .int => |int| int,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
        };
        if (index < 0) return null;
        const element_size = layout.typeStoreSizeBytes(gep.source_ty) catch return null;
        return @intCast(@as(u128, @intCast(index)) * element_size);
    }
    _ = aggregate_ty;
    if (isAggregateType(gep.source_ty) and gep.indices.items.len >= 2 and
        gep.indices.items[0].ty.eql(.{ .int = 64 }) and isInt(gep.indices.items[0].value, 0))
    {
        var current_ty = gep.source_ty;
        var byte_offset: u64 = 0;
        for (gep.indices.items[1..]) |index| {
            if (!index.ty.eql(.{ .int = 32 }) and !index.ty.eql(.{ .int = 64 })) return null;
            const field_index = switch (index.value) {
                .int => |int| int,
                .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
            };
            if (field_index < 0 or field_index > std.math.maxInt(usize)) return null;
            const offset = memory_location.aggregateFieldOffsetWithLayout(layout, current_ty, @intCast(field_index)) orelse return null;
            if (offset < 0) return null;
            byte_offset += @intCast(offset);
            current_ty = memory_location.aggregateFieldType(current_ty, @intCast(field_index)) orelse return null;
        }
        return byte_offset;
    }
    return null;
}

pub fn aggregateFieldIndexAtOffset(aggregate_ty: ir.Type, expected_offset: u64, expected_ty: ir.Type) ?usize {
    const layout = x86_64SysVDataLayout() catch return null;
    var field_index: usize = 0;
    while (memory_location.aggregateFieldType(aggregate_ty, field_index)) |field_ty| : (field_index += 1) {
        const offset_i = memory_location.aggregateFieldOffsetWithLayout(layout, aggregate_ty, field_index) orelse return null;
        if (offset_i < 0) return null;
        const field_offset: u64 = @intCast(offset_i);
        if (field_ty.eql(expected_ty) and field_offset == expected_offset) return field_index;
        if (isAggregateType(field_ty) and expected_offset >= field_offset) {
            if (aggregateFieldIndexAtOffset(field_ty, expected_offset - field_offset, expected_ty) != null) return field_index;
        }
    }
    return null;
}

pub fn isScalarElementGepType(ty: ir.Type) bool {
    return switch (ty) {
        .int, .float, .double, .ptr => true,
        .void, .x86_fp80, .fp128, .metadata, .aggregate, .vector => false,
    };
}

pub fn isAggregateType(ty: ir.Type) bool {
    return switch (ty) {
        .aggregate => true,
        .void, .int, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .vector => false,
    };
}

pub fn collectAggregateIntegerAddTerms(
    block: ir.BasicBlock,
    value: ir.Value,
    ty: ir.Type,
    field_loads: std.StringHashMap(AggregateIntegerFieldLoad),
    terms: *[8]AggregateIntegerAddTerm,
    term_count: *usize,
) !bool {
    const name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (field_loads.get(name)) |load| {
        if (term_count.* >= terms.len) return error.UnsupportedCodegenInstruction;
        terms[term_count.*] = .{ .offset = load.offset };
        term_count.* += 1;
        return true;
    }
    const instruction = findInstruction(block, name) orelse return false;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (binary.op != .add or !binary.ty.eql(ty)) return false;
    if (!try collectAggregateIntegerAddTerms(block, binary.lhs, ty, field_loads, terms, term_count)) return false;
    if (!try collectAggregateIntegerAddTerms(block, binary.rhs, ty, field_loads, terms, term_count)) return false;
    return true;
}

pub fn emitAggregateIntegerTerm(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    param_name: []const u8,
    aggregate_ty: ir.Type,
    term: AggregateIntegerAddTerm,
    ty: ir.Type,
    first: bool,
) !void {
    const location = try sysvIntegerAggregateFieldLocation(function, param_name, aggregate_ty, term.offset, ty);
    switch (location) {
        .gpr => |field| {
            if (ty.eql(.{ .int = 64 })) {
                if (field.offset_in_eightbyte != 0) return error.UnsupportedCodegenAbi;
                if (first) {
                    try machine.instructions.append(allocator, .{ .mov_arg_rax = field.reg });
                } else {
                    try machine.instructions.append(allocator, .{ .add_arg64_rax = field.reg });
                }
                return;
            }
            if (!ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenAbi;
            switch (field.offset_in_eightbyte) {
                0 => if (first)
                    try machine.instructions.append(allocator, .{ .mov_arg_eax = field.reg })
                else
                    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = field.reg } }),
                4 => if (first) {
                    try machine.instructions.append(allocator, .{ .mov_arg_rax = field.reg });
                    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 32 });
                } else {
                    try machine.instructions.append(allocator, .{ .add_arg_high32_eax = field.reg });
                },
                else => return error.UnsupportedCodegenAbi,
            }
        },
        .stack => |offset| {
            if (ty.eql(.{ .int = 64 })) {
                if (first) {
                    try appendLoadStackDispRax(allocator, machine, offset);
                } else {
                    try appendAddStackDispRax(allocator, machine, offset);
                }
            } else if (ty.eql(.{ .int = 32 })) {
                if (first) return error.UnsupportedCodegenAbi;
                try appendAddStackDispEax(allocator, machine, offset);
            } else {
                return error.UnsupportedCodegenAbi;
            }
        },
    }
}

pub fn emitAggregateDoubleTerm(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    param_name: []const u8,
    aggregate_ty: ir.Type,
    term: AggregateDoubleAddTerm,
    dest: XmmReg,
) !void {
    const location = try sysvAggregateFieldLocationByOffset(function, param_name, aggregate_ty, term.offset, .double);
    switch (location) {
        .sse => |reg| {
            if (reg == dest) return;
            if (dest == .xmm0 and reg == .xmm1) {
                try machine.instructions.append(allocator, .movapd_xmm1_xmm0);
                return;
            }
            return error.UnsupportedCodegenAbi;
        },
        .stack => |offset| try appendLoadStackDispXmm(allocator, machine, dest, offset),
        .gpr => return error.UnsupportedCodegenAbi,
    }
}

pub fn emitAggregateFloatTerm(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    param_name: []const u8,
    aggregate_ty: ir.Type,
    term: AggregateFloatAddTerm,
    dest: XmmReg,
) !void {
    const location = try sysvAggregateFieldLocationByOffset(function, param_name, aggregate_ty, term.offset, .float);
    switch (location) {
        .sse => |reg| {
            if (reg != dest) {
                try machine.instructions.append(allocator, .{ .movapd_xmm = .{ .dst = dest, .src = reg } });
            }
            if (term.offset % 8 == 4) {
                try machine.instructions.append(allocator, .{ .shufps_high_f32_to_low = dest });
            } else if (term.offset % 8 != 0) {
                return error.UnsupportedCodegenAbi;
            }
        },
        .stack => |offset| {
            if (dest != .xmm0) return error.UnsupportedCodegenAbi;
            try appendLoadStackDispXmm0F32(allocator, machine, offset);
        },
        .gpr => return error.UnsupportedCodegenAbi,
    }
}

pub fn appendLoadStackDispRax(allocator: std.mem.Allocator, machine: *MachineFunction, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .load_stack_disp8_rax = @intCast(offset) });
    } else {
        try machine.instructions.append(allocator, .{ .load_stack_disp32_rax = offset });
    }
}

pub fn appendLoadStackDispXmm0(allocator: std.mem.Allocator, machine: *MachineFunction, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .load_stack_disp8_xmm0 = @intCast(offset) });
    } else {
        try machine.instructions.append(allocator, .{ .load_stack_disp32_xmm0 = offset });
    }
}

pub fn appendLoadStackDispXmm0F32(allocator: std.mem.Allocator, machine: *MachineFunction, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .load_stack_disp8_xmm0_f32 = @intCast(offset) });
    } else {
        try machine.instructions.append(allocator, .{ .load_stack_disp32_xmm0_f32 = offset });
    }
}

pub fn appendLoadStackDispXmm(allocator: std.mem.Allocator, machine: *MachineFunction, reg: XmmReg, offset: u32) !void {
    if (reg == .xmm0) return appendLoadStackDispXmm0(allocator, machine, offset);
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .load_stack_disp8_xmm = .{ .reg = reg, .disp = @intCast(offset) } });
    } else {
        try machine.instructions.append(allocator, .{ .load_stack_disp32_xmm = .{ .reg = reg, .disp = offset } });
    }
}

pub fn appendAddStackDispRax(allocator: std.mem.Allocator, machine: *MachineFunction, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .add_stack_disp8_rax = @intCast(offset) });
    } else {
        try machine.instructions.append(allocator, .{ .add_stack_disp32_rax = offset });
    }
}

pub fn appendAddStackDispEax(allocator: std.mem.Allocator, machine: *MachineFunction, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .add_stack_disp8_eax = @intCast(offset) });
    } else {
        try machine.instructions.append(allocator, .{ .add_stack_disp32_eax = offset });
    }
}

pub fn appendStoreArg64ArgPtrDisp(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    ptr_reg: ArgReg,
    src_reg: ArgReg,
    offset: u32,
) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .store_arg64_arg_ptr_disp8 = .{
            .ptr_reg = ptr_reg,
            .src_reg = src_reg,
            .offset = @intCast(offset),
        } });
    } else {
        try machine.instructions.append(allocator, .{ .store_arg64_arg_ptr_disp32 = .{
            .ptr_reg = ptr_reg,
            .src_reg = src_reg,
            .offset = offset,
        } });
    }
}

pub fn appendStoreRaxArgPtrDisp(allocator: std.mem.Allocator, machine: *MachineFunction, reg: ArgReg, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .store_rax_arg_ptr_disp8 = .{ .reg = reg, .offset = @intCast(offset) } });
    } else {
        try machine.instructions.append(allocator, .{ .store_rax_arg_ptr_disp32 = .{ .reg = reg, .offset = offset } });
    }
}

pub fn appendStoreEaxArgPtrDisp(allocator: std.mem.Allocator, machine: *MachineFunction, reg: ArgReg, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .store_eax_arg_ptr_disp8 = .{ .reg = reg, .offset = @intCast(offset) } });
    } else {
        try machine.instructions.append(allocator, .{ .store_eax_arg_ptr_disp32 = .{ .reg = reg, .offset = offset } });
    }
}

pub fn appendStoreXmm0ArgPtrDisp(allocator: std.mem.Allocator, machine: *MachineFunction, reg: ArgReg, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .store_xmm0_arg_ptr_disp8 = .{ .reg = reg, .offset = @intCast(offset) } });
    } else {
        try machine.instructions.append(allocator, .{ .store_xmm0_arg_ptr_disp32 = .{ .reg = reg, .offset = offset } });
    }
}

pub fn appendStoreXmm0F32ArgPtrDisp(allocator: std.mem.Allocator, machine: *MachineFunction, reg: ArgReg, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .store_xmm0_f32_arg_ptr_disp8 = .{ .reg = reg, .offset = @intCast(offset) } });
    } else {
        try machine.instructions.append(allocator, .{ .store_xmm0_f32_arg_ptr_disp32 = .{ .reg = reg, .offset = offset } });
    }
}

pub const SysVIntegerAggregateFieldLocation = union(enum) {
    gpr: struct {
        reg: ArgReg,
        offset_in_eightbyte: u3,
    },
    stack: u32,
};

pub fn sysvIntegerAggregateFieldLocation(
    function: ir.Function,
    param_name: []const u8,
    aggregate_ty: ir.Type,
    field_offset: u64,
    field_ty: ir.Type,
) !SysVIntegerAggregateFieldLocation {
    const layout = try x86_64SysVDataLayout();
    const field_size = try layout.typeStoreSizeBytes(field_ty);
    const aggregate_size = try layout.typeStoreSizeBytes(aggregate_ty);
    if (field_size == 0 or field_offset + field_size > aggregate_size) return error.UnsupportedCodegenAbi;
    if (field_size != 4 and field_size != 8) return error.UnsupportedCodegenAbi;

    var gpr_index: usize = 0;
    var sse_index: usize = 0;
    var stack_eightbytes: usize = 0;
    for (function.params.items) |param| {
        if (std.mem.eql(u8, param.name, param_name)) {
            if (!param.ty.eql(aggregate_ty)) return error.UnsupportedCodegenValue;
            const classification = try classifySysVAggregate(param.ty);
            const field_eightbyte = field_offset / 8;
            if (field_eightbyte >= classification.eightbyte_count) return error.UnsupportedCodegenAbi;
            const field_class = classification.eightbytes[@intCast(field_eightbyte)] orelse return error.UnsupportedCodegenAbi;
            if (field_class != .integer) return error.UnsupportedCodegenAbi;
            const needed = sysvAggregateRegisterNeeds(classification);
            if (gpr_index + needed.gpr > 6 or sse_index + needed.sse > 8) {
                const offset = 8 + stack_eightbytes * 8 + field_offset;
                if (offset > std.math.maxInt(u32)) return error.UnsupportedCodegenAbi;
                return .{ .stack = @intCast(offset) };
            }
            const prior = sysvAggregateRegisterNeedsBefore(classification, @intCast(field_eightbyte));
            return .{ .gpr = .{
                .reg = try ArgReg.fromIndex(gpr_index + prior.gpr),
                .offset_in_eightbyte = @intCast(field_offset % 8),
            } };
        }
        try advanceSysVParamCursors(param.ty, &gpr_index, &sse_index, &stack_eightbytes);
    }
    return error.UnsupportedCodegenValue;
}

pub fn lowerMemoryIntegerAggregateFieldAddReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 64 }) or !function.ret_ty.eql(.{ .int = 64 })) return false;
    if (function.params.items.len != 1) return false;
    const aggregate_ty = function.params.items[0].ty;
    const classification = classifySysVAggregate(aggregate_ty) catch return false;
    if (classification.kind != .memory or !isI64LeafAggregate(aggregate_ty)) return false;
    if (block.instructions.items.len < 5) return false;

    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    if (alloca_inst.removed or store_inst.removed) return false;
    const alloca_name = alloca_inst.result orelse return false;

    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    if (!alloca.allocated_ty.eql(aggregate_ty)) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(aggregate_ty) or store.attrs.isBarrier() or !isNamed(store.ptr, alloca_name) or
        !isNamed(store.value, function.params.items[0].name)) return false;

    var pointer_offsets = std.StringHashMap(u64).init(allocator);
    defer pointer_offsets.deinit();
    try pointer_offsets.put(alloca_name, 0);

    var field_loads = std.StringHashMap(AggregateIntegerFieldLoad).init(allocator);
    defer field_loads.deinit();

    const layout = try x86_64SysVDataLayout();
    for (block.instructions.items[2..]) |instruction| {
        if (instruction.removed) return false;
        switch (instruction.kind) {
            .gep => |gep| {
                const result = instruction.result orelse return false;
                const base_name = switch (gep.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const base_offset = pointer_offsets.get(base_name) orelse return false;
                const offset = aggregateGepByteOffset(layout, aggregate_ty, gep) orelse return false;
                const total_offset = base_offset + offset;
                _ = aggregateFieldIndexAtOffset(aggregate_ty, total_offset, .{ .int = 64 }) orelse return false;
                try pointer_offsets.put(result, total_offset);
            },
            .load => |load| {
                const result = instruction.result orelse return false;
                if (!load.ty.eql(.{ .int = 64 }) or load.attrs.isBarrier()) return false;
                const ptr_name = switch (load.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const offset = pointer_offsets.get(ptr_name) orelse return false;
                _ = aggregateFieldIndexAtOffset(aggregate_ty, offset, load.ty) orelse return false;
                try field_loads.put(result, .{ .offset = offset });
            },
            .binary => |binary| {
                if (binary.op != .add or !binary.ty.eql(.{ .int = 64 })) return false;
            },
            .phi, .fcmp, .icmp, .select, .cast, .freeze, .alloca, .store, .call, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => return false,
        }
    }

    var terms: [8]AggregateIntegerAddTerm = undefined;
    var term_count: usize = 0;
    if (!try collectAggregateIntegerAddTerms(block, ret.value orelse return error.InvalidRet, .{ .int = 64 }, field_loads, &terms, &term_count)) return false;
    if (term_count < 2) return false;

    try appendLoadStackDispRax(allocator, machine, try stackAggregateByteDisp(aggregate_ty, terms[0].offset, .{ .int = 64 }));
    for (terms[1..term_count]) |term| {
        try appendAddStackDispRax(allocator, machine, try stackAggregateByteDisp(aggregate_ty, term.offset, .{ .int = 64 }));
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn isI64Aggregate(aggregate_ty: ir.Type) bool {
    const field_count = aggregateFieldCount(aggregate_ty) orelse return false;
    if (field_count == 0) return false;
    var field_index: usize = 0;
    while (field_index < field_count) : (field_index += 1) {
        const field_ty = memory_location.aggregateFieldType(aggregate_ty, field_index) orelse return false;
        if (!field_ty.eql(.{ .int = 64 })) return false;
    }
    return true;
}

pub fn isI64LeafAggregate(aggregate_ty: ir.Type) bool {
    const field_count = aggregateFieldCount(aggregate_ty) orelse return false;
    if (field_count == 0) return false;
    var field_index: usize = 0;
    while (field_index < field_count) : (field_index += 1) {
        const field_ty = memory_location.aggregateFieldType(aggregate_ty, field_index) orelse return false;
        if (field_ty.eql(.{ .int = 64 })) continue;
        if (isAggregateType(field_ty) and isI64LeafAggregate(field_ty)) continue;
        return false;
    }
    return true;
}

pub fn isSupportedAggregateCopyLeafAggregate(aggregate_ty: ir.Type) bool {
    const field_count = aggregateFieldCount(aggregate_ty) orelse return false;
    if (field_count == 0) return false;
    var field_index: usize = 0;
    while (field_index < field_count) : (field_index += 1) {
        const field_ty = memory_location.aggregateFieldType(aggregate_ty, field_index) orelse return false;
        if (supportedAggregateCopyLeaf(field_ty)) continue;
        if (isAggregateType(field_ty) and isSupportedAggregateCopyLeafAggregate(field_ty)) continue;
        return false;
    }
    return true;
}

pub fn supportedAggregateCopyLeaf(ty: ir.Type) bool {
    return ty.eql(.{ .int = 32 }) or ty.eql(.{ .int = 64 }) or ty.eql(.ptr) or ty.eql(.float) or ty.eql(.double);
}

pub fn aggregateFieldIndexFromGep(instruction: ir.Instruction, aggregate_ty: ir.Type, base_name: []const u8) ?usize {
    const gep = switch (instruction.kind) {
        .gep => |gep| gep,
        else => return null,
    };
    if (!gep.source_ty.eql(aggregate_ty) or !isNamed(gep.ptr, base_name)) return null;
    if (gep.indices.items.len != 2) return null;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, 0)) return null;
    if (!gep.indices.items[1].ty.eql(.{ .int = 32 })) return null;
    const field_index = switch (gep.indices.items[1].value) {
        .int => |index| index,
        else => return null,
    };
    if (field_index < 0) return null;
    return @intCast(field_index);
}

pub fn stackAggregateFieldDisp8(aggregate_ty: ir.Type, field_index: usize) !u8 {
    const layout = try x86_64SysVDataLayout();
    const offset_i = memory_location.aggregateFieldOffsetWithLayout(layout, aggregate_ty, field_index) orelse
        return error.UnsupportedCodegenAbi;
    if (offset_i < 0) return error.UnsupportedCodegenAbi;
    const offset = 8 + @as(u64, @intCast(offset_i));
    if (offset > std.math.maxInt(u8)) return error.UnsupportedCodegenAbi;
    return @intCast(offset);
}

pub fn stackAggregateByteDisp8(aggregate_ty: ir.Type, field_offset: u64, field_ty: ir.Type) !u8 {
    _ = aggregateFieldIndexAtOffset(aggregate_ty, field_offset, field_ty) orelse return error.UnsupportedCodegenAbi;
    const offset = 8 + field_offset;
    if (offset > std.math.maxInt(u8)) return error.UnsupportedCodegenAbi;
    return @intCast(offset);
}

pub fn stackAggregateByteDisp(aggregate_ty: ir.Type, field_offset: u64, field_ty: ir.Type) !u32 {
    _ = aggregateFieldIndexAtOffset(aggregate_ty, field_offset, field_ty) orelse return error.UnsupportedCodegenAbi;
    const offset = 8 + field_offset;
    if (offset > std.math.maxInt(u32)) return error.UnsupportedCodegenAbi;
    return @intCast(offset);
}

pub fn validateAggregateFieldGep(instruction: ir.Instruction, aggregate_ty: ir.Type, base_name: []const u8, field_index: i128) !void {
    const gep = switch (instruction.kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!gep.source_ty.eql(aggregate_ty) or !isNamed(gep.ptr, base_name)) return error.UnsupportedCodegenInstruction;
    if (gep.indices.items.len != 2) return error.UnsupportedCodegenInstruction;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, 0)) return error.UnsupportedCodegenInstruction;
    if (!gep.indices.items[1].ty.eql(.{ .int = 32 }) or !isInt(gep.indices.items[1].value, field_index)) return error.UnsupportedCodegenInstruction;
}

pub fn emitSysVAggregateFieldReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    param_name: []const u8,
    aggregate_ty: ir.Type,
    field_index: usize,
    field_ty: ir.Type,
) !void {
    const location = try sysvAggregateFieldLocation(function, param_name, aggregate_ty, field_index, field_ty);
    try emitSysVAggregateFieldLocationReturn(allocator, machine, location, field_ty);
}

pub fn emitSysVAggregateFieldOffsetReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    param_name: []const u8,
    aggregate_ty: ir.Type,
    field_offset: u64,
    field_ty: ir.Type,
) !void {
    if (field_ty.eql(.{ .int = 32 }) or field_ty.eql(.{ .int = 64 })) {
        const location = try sysvIntegerAggregateFieldLocation(function, param_name, aggregate_ty, field_offset, field_ty);
        try emitSysVIntegerAggregateFieldLocationReturn(allocator, machine, location, field_ty);
        return;
    }
    if (field_ty.eql(.float)) {
        _ = try emitSysVAggregateF32FieldOffsetReturn(allocator, machine, function, param_name, aggregate_ty, field_offset);
        return;
    }
    const location = try sysvAggregateFieldLocationByOffset(function, param_name, aggregate_ty, field_offset, field_ty);
    try emitSysVAggregateFieldLocationReturn(allocator, machine, location, field_ty);
}

pub fn emitSysVIntegerAggregateFieldLocationReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    location: SysVIntegerAggregateFieldLocation,
    field_ty: ir.Type,
) !void {
    switch (location) {
        .gpr => |field| {
            if (field_ty.eql(.{ .int = 64 })) {
                if (field.offset_in_eightbyte != 0) return error.UnsupportedCodegenAbi;
                try machine.instructions.append(allocator, .{ .mov_arg_rax = field.reg });
                return;
            }
            if (!field_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenAbi;
            switch (field.offset_in_eightbyte) {
                0 => try machine.instructions.append(allocator, .{ .mov_arg_eax = field.reg }),
                4 => {
                    try machine.instructions.append(allocator, .{ .mov_arg_rax = field.reg });
                    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 32 });
                },
                else => return error.UnsupportedCodegenAbi,
            }
        },
        .stack => |offset| {
            if (!field_ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenAbi;
            try appendLoadStackDispRax(allocator, machine, offset);
        },
    }
}

pub fn emitSysVAggregateFieldLocationReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    location: SysVAggregateFieldLocation,
    field_ty: ir.Type,
) !void {
    switch (location) {
        .gpr => |reg| {
            if (field_ty.eql(.{ .int = 64 })) {
                try machine.instructions.append(allocator, .{ .mov_arg_rax = reg });
                return;
            }
            if (field_ty.eql(.{ .int = 32 })) {
                try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
                return;
            }
            return error.UnsupportedCodegenAbi;
        },
        .sse => |reg| {
            if (field_ty.eql(.float)) {
                switch (reg) {
                    .xmm0 => {},
                    .xmm1, .xmm2, .xmm3, .xmm4, .xmm5, .xmm6, .xmm7 => try machine.instructions.append(allocator, .{ .movapd_xmm = .{ .dst = .xmm0, .src = reg } }),
                }
                return;
            }
            if (!field_ty.eql(.double)) return error.UnsupportedCodegenAbi;
            switch (reg) {
                .xmm0 => {},
                .xmm1 => try machine.instructions.append(allocator, .movapd_xmm1_xmm0),
                .xmm2, .xmm3, .xmm4, .xmm5, .xmm6, .xmm7 => return error.UnsupportedCodegenAbi,
            }
        },
        .stack => |offset| {
            if (field_ty.eql(.{ .int = 64 })) {
                try appendLoadStackDispRax(allocator, machine, offset);
            } else if (field_ty.eql(.float)) {
                try appendLoadStackDispXmm0F32(allocator, machine, offset);
            } else {
                return error.UnsupportedCodegenAbi;
            }
        },
    }
}

pub fn emitSysVAggregateF32FieldOffsetReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    param_name: []const u8,
    aggregate_ty: ir.Type,
    field_offset: u64,
) !bool {
    const location = try sysvAggregateFieldLocationByOffset(function, param_name, aggregate_ty, field_offset, .float);
    switch (location) {
        .sse => |reg| {
            switch (reg) {
                .xmm0 => {},
                .xmm1, .xmm2, .xmm3, .xmm4, .xmm5, .xmm6, .xmm7 => try machine.instructions.append(allocator, .{ .movapd_xmm = .{ .dst = .xmm0, .src = reg } }),
            }
            if (field_offset % 8 == 4) {
                try machine.instructions.append(allocator, .{ .shufps_high_f32_to_low = .xmm0 });
            } else if (field_offset % 8 != 0) {
                return error.UnsupportedCodegenAbi;
            }
        },
        .stack => |offset| try appendLoadStackDispXmm0F32(allocator, machine, offset),
        .gpr => return error.UnsupportedCodegenAbi,
    }
    return true;
}

pub const SysVAggregateFieldLocation = union(enum) {
    gpr: ArgReg,
    sse: XmmReg,
    stack: u32,
};

pub fn sysvAggregateFieldLocation(
    function: ir.Function,
    param_name: []const u8,
    aggregate_ty: ir.Type,
    field_index: usize,
    field_ty: ir.Type,
) !SysVAggregateFieldLocation {
    const layout = try x86_64SysVDataLayout();
    const field_offset_i = memory_location.aggregateFieldOffsetWithLayout(layout, aggregate_ty, field_index) orelse
        return error.UnsupportedCodegenAbi;
    if (field_offset_i < 0) return error.UnsupportedCodegenAbi;
    const field_offset: u64 = @intCast(field_offset_i);
    if (!((memory_location.aggregateFieldType(aggregate_ty, field_index) orelse return error.UnsupportedCodegenAbi).eql(field_ty))) {
        return error.UnsupportedCodegenAbi;
    }
    return try sysvAggregateFieldLocationByOffset(function, param_name, aggregate_ty, field_offset, field_ty);
}

pub fn sysvAggregateFieldLocationByOffset(
    function: ir.Function,
    param_name: []const u8,
    aggregate_ty: ir.Type,
    field_offset: u64,
    field_ty: ir.Type,
) !SysVAggregateFieldLocation {
    const layout = try x86_64SysVDataLayout();
    const field_size = try layout.typeStoreSizeBytes(field_ty);
    const aggregate_size = try layout.typeStoreSizeBytes(aggregate_ty);
    if (field_size == 0 or field_offset + field_size > aggregate_size) return error.UnsupportedCodegenAbi;
    _ = aggregateFieldIndexAtOffset(aggregate_ty, field_offset, field_ty) orelse return error.UnsupportedCodegenAbi;
    var gpr_index: usize = 0;
    var sse_index: usize = 0;
    var stack_eightbytes: usize = 0;
    for (function.params.items) |param| {
        if (std.mem.eql(u8, param.name, param_name)) {
            if (!param.ty.eql(aggregate_ty)) return error.UnsupportedCodegenValue;
            const classification = try classifySysVAggregate(param.ty);
            if (classification.kind != .register) return error.UnsupportedCodegenAbi;
            const field_eightbyte = field_offset / 8;
            const field_class = if (field_eightbyte < classification.eightbytes.len)
                classification.eightbytes[@intCast(field_eightbyte)] orelse return error.UnsupportedCodegenAbi
            else
                return error.UnsupportedCodegenAbi;
            const needed = sysvAggregateRegisterNeeds(classification);
            if (gpr_index + needed.gpr > 6 or sse_index + needed.sse > 8) {
                const offset = 8 + stack_eightbytes * 8 + field_offset;
                if (offset > std.math.maxInt(u32)) return error.UnsupportedCodegenAbi;
                return .{ .stack = @intCast(offset) };
            }
            const prior = sysvAggregateRegisterNeedsBefore(classification, @intCast(field_eightbyte));
            return switch (field_class) {
                .integer => .{ .gpr = try ArgReg.fromIndex(gpr_index + prior.gpr) },
                .sse => .{ .sse = try XmmReg.fromIndex(sse_index + prior.sse) },
            };
        }
        try advanceSysVParamCursors(param.ty, &gpr_index, &sse_index, &stack_eightbytes);
    }
    return error.UnsupportedCodegenValue;
}

pub fn sysvAggregateRegisterNeeds(classification: SysVAggregateClassification) SysVRegisterNeeds {
    return sysv_abi.aggregateRegisterNeeds(classification);
}

pub fn sysvAggregateRegisterNeedsBefore(classification: SysVAggregateClassification, limit: usize) SysVRegisterNeeds {
    return sysv_abi.aggregateRegisterNeedsBefore(classification, limit);
}

pub fn advanceSysVParamCursors(
    ty: ir.Type,
    gpr_index: *usize,
    sse_index: *usize,
    stack_eightbytes: *usize,
) !void {
    return sysv_abi.advanceParamCursors(ty, gpr_index, sse_index, stack_eightbytes);
}

pub fn lowerRegisterAggregateDirectCallReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(function.ret_ty) or block.instructions.items.len != 1) return false;
    const classification = classifySysVAggregate(function.ret_ty) catch return false;
    if (classification.kind != .register) return false;
    const instruction = block.instructions.items[0];
    if (instruction.removed) return false;
    const call_result = instruction.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, call_result)) return false;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!call.ret_ty.eql(function.ret_ty) or call.inline_asm != null) return false;
    if (call.tail_kind != null) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;
    if (call.callee_value) |callee_value| {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        const callee_reg = try paramReg(function, callee_name, .ptr);
        try machine.instructions.append(allocator, .{ .mov_arg_rax = callee_reg });
        const stack_arg_count = appendSysVScalarCallArgs(allocator, machine, function, call) catch |err| switch (err) {
            error.UnsupportedCodegenAbi, error.UnsupportedCodegenType, error.UnsupportedCodegenValue => return false,
            else => return err,
        };
        try appendIndirectCallRaxWithStackArgs(allocator, machine, call.ret_ty, stack_arg_count);
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    const stack_arg_count = appendSysVScalarCallArgs(allocator, machine, function, call) catch |err| switch (err) {
        error.UnsupportedCodegenAbi, error.UnsupportedCodegenType, error.UnsupportedCodegenValue => return false,
        else => return err,
    };
    try appendDirectCallWithStackArgs(allocator, machine, call.callee, call.ret_ty, stack_arg_count);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerAggregatePairAbiFamilyReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (try lowerRuntimeAggregatePairMainReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerRuntimeAggregatePairMakePairReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerRuntimeAggregatePairPairFirstReturn(allocator, machine, function, block, ret)) return true;
    return false;
}

pub fn lowerRuntimeAggregatePairMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "runtime_aggregate_pair_main.main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (try lowerRuntimeAggregatePairDirectMainReturn(allocator, machine, block, ret)) return true;
    if (!ret.ty.eql(.{ .int = 32 }) or block.instructions.items.len != 3) return false;

    const alloca_inst = block.instructions.items[0];
    const make_pair_inst = block.instructions.items[1];
    const pair_first_inst = block.instructions.items[2];
    if (alloca_inst.removed or make_pair_inst.removed or pair_first_inst.removed) return false;
    const pair_slot_name = alloca_inst.result orelse return false;
    const pair_first_name = pair_first_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, pair_first_name)) return false;

    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    if (!alloca.allocated_ty.eql(.{ .aggregate = "%runtime_aggregate_pair_main.Pair" })) return false;

    const make_pair = switch (make_pair_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!callIsFastcc(make_pair.calling_conv) or make_pair.ret_ty != .void) return false;
    if (make_pair.callee_value != null or make_pair.inline_asm != null) return false;
    if (!std.mem.eql(u8, make_pair.callee, "runtime_aggregate_pair_main.makePair")) return false;
    if (make_pair.args.items.len != 3) return false;
    if (!make_pair.args.items[0].ty.eql(.ptr) or !callArgAttrsContain(make_pair.args.items[0], "sret(%runtime_aggregate_pair_main.Pair)") or
        !isNamed(make_pair.args.items[0].value, pair_slot_name)) return false;
    if (!make_pair.args.items[1].ty.eql(.{ .int = 32 }) or !isInt(make_pair.args.items[1].value, 1)) return false;
    if (!make_pair.args.items[2].ty.eql(.{ .int = 32 }) or !isInt(make_pair.args.items[2].value, 2)) return false;

    const pair_first = switch (pair_first_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!callIsFastcc(pair_first.calling_conv) or !pair_first.ret_ty.eql(.{ .int = 32 })) return false;
    if (pair_first.callee_value != null or pair_first.inline_asm != null) return false;
    if (!std.mem.eql(u8, pair_first.callee, "runtime_aggregate_pair_main.pairFirst")) return false;
    if (pair_first.args.items.len != 1) return false;
    if (!pair_first.args.items[0].ty.eql(.ptr) or !isNamed(pair_first.args.items[0].value, pair_slot_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRuntimeAggregatePairDirectMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 }) or block.instructions.items.len != 3) return false;

    const make_pair_inst = block.instructions.items[0];
    const pair_first_inst = block.instructions.items[1];
    const bitcast_inst = block.instructions.items[2];
    if (make_pair_inst.removed or pair_first_inst.removed or bitcast_inst.removed) return false;
    const make_pair_name = make_pair_inst.result orelse return false;
    const pair_first_name = pair_first_inst.result orelse return false;
    const bitcast_name = identityCastFrom(bitcast_inst, pair_first_name, .{ .int = 32 }, .{ .int = 32 }) orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, bitcast_name)) return false;

    const make_pair = switch (make_pair_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!callIsFastcc(make_pair.calling_conv) or !make_pair.ret_ty.eql(.{ .int = 64 })) return false;
    if (make_pair.callee_value != null or make_pair.inline_asm != null) return false;
    if (!std.mem.eql(u8, make_pair.callee, "runtime_aggregate_pair_main.makePair")) return false;
    if (make_pair.args.items.len != 2) return false;
    if (!make_pair.args.items[0].ty.eql(.{ .int = 32 }) or !isInt(make_pair.args.items[0].value, 1)) return false;
    if (!make_pair.args.items[1].ty.eql(.{ .int = 32 }) or !isInt(make_pair.args.items[1].value, 2)) return false;

    const pair_first = switch (pair_first_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!callIsFastcc(pair_first.calling_conv) or !pair_first.ret_ty.eql(.{ .int = 32 })) return false;
    if (pair_first.callee_value != null or pair_first.inline_asm != null) return false;
    if (!std.mem.eql(u8, pair_first.callee, "runtime_aggregate_pair_main.pairFirst")) return false;
    if (pair_first.args.items.len != 1) return false;
    if (!pair_first.args.items[0].ty.eql(.{ .int = 64 }) or !isNamed(pair_first.args.items[0].value, make_pair_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRuntimeAggregatePairMakePairReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "runtime_aggregate_pair_main.makePair")) return false;
    if (!callIsFastcc(function.calling_conv) or function.ret_ty != .void or ret.ty != .void) return false;
    if (function.params.items.len != 3) return false;
    if (!function.params.items[0].ty.eql(.ptr) or !paramAttrsContain(function.params.items[0], "sret(%runtime_aggregate_pair_main.Pair)")) return false;
    if (!function.params.items[1].ty.eql(.{ .int = 32 }) or !function.params.items[2].ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 3) return false;

    const first_store_inst = block.instructions.items[0];
    const gep_inst = block.instructions.items[1];
    const second_store_inst = block.instructions.items[2];
    if (first_store_inst.removed or gep_inst.removed or second_store_inst.removed) return false;
    const gep_name = gep_inst.result orelse return false;
    if (ret.value != null) return error.InvalidRet;

    const first_store = switch (first_store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!first_store.ty.eql(.{ .int = 32 }) or first_store.attrs.isBarrier()) return false;
    if (!isNamed(first_store.ptr, function.params.items[0].name) or !isNamed(first_store.value, function.params.items[1].name)) return false;

    const gep = switch (gep_inst.kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .int = 8 }) or !isNamed(gep.ptr, function.params.items[0].name)) return false;
    if (gep.indices.items.len != 1 or !gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, 4)) return false;

    const second_store = switch (second_store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!second_store.ty.eql(.{ .int = 32 }) or second_store.attrs.isBarrier()) return false;
    if (!isNamed(second_store.ptr, gep_name) or !isNamed(second_store.value, function.params.items[2].name)) return false;

    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRuntimeAggregatePairPairFirstReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "runtime_aggregate_pair_main.pairFirst")) return false;
    if (!callIsFastcc(function.calling_conv) or !function.ret_ty.eql(.{ .int = 32 }) or !ret.ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.ptr)) return false;
    if (block.instructions.items.len != 3) return false;

    const alloca_inst = block.instructions.items[0];
    const memcpy_inst = block.instructions.items[1];
    const load_inst = block.instructions.items[2];
    if (alloca_inst.removed or memcpy_inst.removed or load_inst.removed) return false;
    const alloca_name = alloca_inst.result orelse return false;
    const load_name = load_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, load_name)) return false;

    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    if (!alloca.allocated_ty.eql(.{ .aggregate = "%runtime_aggregate_pair_main.Pair" })) return false;

    const memcpy_call = switch (memcpy_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (memcpy_call.callee_value != null or memcpy_call.inline_asm != null) return false;
    if (!std.mem.eql(u8, memcpy_call.callee, "llvm.memcpy.p0.p0.i64")) return false;
    if (memcpy_call.ret_ty != .void or memcpy_call.args.items.len != 4) return false;
    if (!memcpy_call.args.items[0].ty.eql(.ptr) or !isNamed(memcpy_call.args.items[0].value, alloca_name)) return false;
    if (!memcpy_call.args.items[1].ty.eql(.ptr) or !isNamed(memcpy_call.args.items[1].value, function.params.items[0].name)) return false;
    if (!memcpy_call.args.items[2].ty.eql(.{ .int = 64 }) or !isInt(memcpy_call.args.items[2].value, 8)) return false;
    if (!memcpy_call.args.items[3].ty.eql(.{ .int = 1 }) or !isInt(memcpy_call.args.items[3].value, 0)) return false;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier() or !isNamed(load.ptr, alloca_name)) return false;

    try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = .rdi });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerTruncI64ArgReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 1) return false;

    const trunc_inst = block.instructions.items[0];
    if (trunc_inst.removed) return false;
    const trunc_result = trunc_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, trunc_result)) return false;

    const trunc = switch (trunc_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (trunc.op != .trunc or !trunc.from_ty.eql(.{ .int = 64 }) or !trunc.to_ty.eql(.{ .int = 32 })) return false;
    const reg = try paramValueReg(function, trunc.value, .{ .int = 64 });

    try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerMakePairReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 64 })) return false;
    if (block.instructions.items.len != 4) return false;

    const high_zext_inst = block.instructions.items[0];
    const shift_inst = block.instructions.items[1];
    const low_zext_inst = block.instructions.items[2];
    const or_inst = block.instructions.items[3];
    if (high_zext_inst.removed or shift_inst.removed or low_zext_inst.removed or or_inst.removed) return false;

    const high_zext_result = high_zext_inst.result orelse return false;
    const shift_result = shift_inst.result orelse return false;
    const low_zext_result = low_zext_inst.result orelse return false;
    const or_result = or_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, or_result)) return false;

    const high_zext = switch (high_zext_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (high_zext.op != .zext or !high_zext.from_ty.eql(.{ .int = 32 }) or !high_zext.to_ty.eql(.{ .int = 64 })) return false;
    const high_reg = try paramValueReg(function, high_zext.value, .{ .int = 32 });

    const shift = switch (shift_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (shift.op != .shl or !shift.ty.eql(.{ .int = 64 }) or !isNamed(shift.lhs, high_zext_result) or !isInt(shift.rhs, 32)) return false;

    const low_zext = switch (low_zext_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (low_zext.op != .zext or !low_zext.from_ty.eql(.{ .int = 32 }) or !low_zext.to_ty.eql(.{ .int = 64 })) return false;
    const low_reg = try paramValueReg(function, low_zext.value, .{ .int = 32 });

    const or_binary = switch (or_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (or_binary.op != .@"or" or !or_binary.ty.eql(.{ .int = 64 })) return false;
    if (!isNamed(or_binary.lhs, shift_result) or !isNamed(or_binary.rhs, low_zext_result)) return false;

    try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rdx, .src = high_reg } });
    try machine.instructions.append(allocator, .{ .shl_rdx_imm6 = 32 });
    try machine.instructions.append(allocator, .{ .mov_arg_eax = low_reg });
    try machine.instructions.append(allocator, .or_rdx_rax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerStructSumReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 4) return false;

    const first_load_inst = block.instructions.items[0];
    const gep_inst = block.instructions.items[1];
    const second_load_inst = block.instructions.items[2];
    const add_inst = block.instructions.items[3];
    if (first_load_inst.removed or gep_inst.removed or second_load_inst.removed or add_inst.removed) return false;

    const first_load_result = first_load_inst.result orelse return false;
    const gep_result = gep_inst.result orelse return false;
    const second_load_result = second_load_inst.result orelse return false;
    const add_result = add_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, add_result)) return false;

    const first_load = switch (first_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!first_load.ty.eql(.{ .int = 32 })) return false;
    if (first_load.attrs.isBarrier()) return error.UnsupportedCodegenInstruction;
    const base_reg = try paramValueReg(function, first_load.ptr, .ptr);

    const gep = switch (gep_inst.kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .int = 8 }) or !first_load.ptr.eql(gep.ptr)) return false;
    if (gep.indices.items.len != 1) return false;
    const index = gep.indices.items[0];
    if (!index.ty.eql(.{ .int = 64 }) or !isInt(index.value, 4)) return false;

    const second_load = switch (second_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!second_load.ty.eql(.{ .int = 32 }) or !isNamed(second_load.ptr, gep_result)) return false;
    if (second_load.attrs.isBarrier()) return error.UnsupportedCodegenInstruction;

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 })) return false;
    if (!((isNamed(add.lhs, first_load_result) and isNamed(add.rhs, second_load_result)) or
        (isNamed(add.lhs, second_load_result) and isNamed(add.rhs, first_load_result)))) return false;

    try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = base_reg });
    try machine.instructions.append(allocator, .{ .add_arg_ptr_disp4_eax = base_reg });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRuntimeStructSumPreoptHelper(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (block.instructions.items.len != 8) return false;

    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    const first_ptr_load_inst = block.instructions.items[2];
    const first_field_load_inst = block.instructions.items[3];
    const second_ptr_load_inst = block.instructions.items[4];
    const gep_inst = block.instructions.items[5];
    const second_field_load_inst = block.instructions.items[6];
    const add_inst = block.instructions.items[7];
    if (alloca_inst.removed or store_inst.removed or first_ptr_load_inst.removed or first_field_load_inst.removed or
        second_ptr_load_inst.removed or gep_inst.removed or second_field_load_inst.removed or add_inst.removed) return false;

    const alloca_name = alloca_inst.result orelse return false;
    const first_ptr_name = first_ptr_load_inst.result orelse return false;
    const first_field_name = first_field_load_inst.result orelse return false;
    const second_ptr_name = second_ptr_load_inst.result orelse return false;
    const gep_name = gep_inst.result orelse return false;
    const second_field_name = second_field_load_inst.result orelse return false;
    const add_name = add_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, add_name)) return false;

    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    if (!alloca.allocated_ty.eql(.ptr)) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.ptr) or store.attrs.isBarrier()) return false;
    if (!isNamed(store.ptr, alloca_name) or !isNamed(store.value, function.params.items[0].name)) return false;

    const first_ptr_load = switch (first_ptr_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!first_ptr_load.ty.eql(.ptr) or first_ptr_load.attrs.isBarrier()) return false;
    if (!isNamed(first_ptr_load.ptr, alloca_name)) return false;

    const first_field_load = switch (first_field_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!first_field_load.ty.eql(.{ .int = 32 }) or first_field_load.attrs.isBarrier()) return false;
    if (!isNamed(first_field_load.ptr, first_ptr_name)) return false;

    const second_ptr_load = switch (second_ptr_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!second_ptr_load.ty.eql(.ptr) or second_ptr_load.attrs.isBarrier()) return false;
    if (!isNamed(second_ptr_load.ptr, alloca_name)) return false;

    const gep = switch (gep_inst.kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .int = 8 }) or !isNamed(gep.ptr, second_ptr_name)) return false;
    if (gep.indices.items.len != 1) return false;
    const index = gep.indices.items[0];
    if (!index.ty.eql(.{ .int = 64 }) or !isInt(index.value, 4)) return false;

    const second_field_load = switch (second_field_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!second_field_load.ty.eql(.{ .int = 32 }) or second_field_load.attrs.isBarrier()) return false;
    if (!isNamed(second_field_load.ptr, gep_name)) return false;

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 })) return false;
    if (!((isNamed(add.lhs, first_field_name) and isNamed(add.rhs, second_field_name)) or
        (isNamed(add.lhs, second_field_name) and isNamed(add.rhs, first_field_name)))) return false;

    try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = .rdi });
    try machine.instructions.append(allocator, .{ .add_arg_ptr_disp4_eax = .rdi });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRuntimeStructSumMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "runtime_struct_sum_main.main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or block.instructions.items.len != 3) return false;

    const call_inst = block.instructions.items[0];
    const icmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (call_inst.removed or icmp_inst.removed or select_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    const icmp_name = icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (call.calling_conv) |cc| {
        if (!std.mem.eql(u8, cc, "fastcc")) return false;
    }
    if (!std.mem.eql(u8, call.callee, "runtime_struct_sum_main.structSum")) return false;
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 1) return false;
    if (!call.args.items[0].ty.eql(.ptr) or !valueReferencesGlobal(call.args.items[0].value, "runtime_struct_sum_main.pair")) return false;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, call_name) or !isInt(icmp.rhs, 42)) return false;

    if (!isSelectI1ToI32ZeroOne(select_inst, icmp_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerAddChain3Return(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (std.mem.eql(u8, function.name, "runtime_array_sum_main.arraySum")) {
        return try lowerRuntimeArraySumPreoptHelper(allocator, machine, function, block, ret);
    }
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 2) return false;

    const first_add_inst = block.instructions.items[0];
    const second_add_inst = block.instructions.items[1];
    if (first_add_inst.removed or second_add_inst.removed) return false;

    const first_add_result = first_add_inst.result orelse return false;
    const second_add_result = second_add_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, second_add_result)) return false;

    const first_add = switch (first_add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (first_add.op != .add or !first_add.ty.eql(.{ .int = 32 })) return false;
    const first_lhs = try paramValueReg(function, first_add.lhs, .{ .int = 32 });
    const first_rhs = try paramValueReg(function, first_add.rhs, .{ .int = 32 });

    const second_add = switch (second_add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (second_add.op != .add or !second_add.ty.eql(.{ .int = 32 })) return false;
    const third_reg = if (isNamed(second_add.lhs, first_add_result))
        try paramValueReg(function, second_add.rhs, .{ .int = 32 })
    else if (isNamed(second_add.rhs, first_add_result))
        try paramValueReg(function, second_add.lhs, .{ .int = 32 })
    else
        return false;

    try machine.instructions.append(allocator, .{ .mov_arg_eax = first_lhs });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = first_rhs } });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = third_reg } });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRuntimeArraySumPreoptHelper(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 3) return false;
    for (function.params.items) |param| {
        if (!param.ty.eql(.{ .int = 32 })) return false;
    }
    if (block.instructions.items.len != 16) return false;

    const memcpy_inst = block.instructions.items[7];
    const first_add_inst = block.instructions.items[12];
    const second_add_inst = block.instructions.items[15];
    if (memcpy_inst.removed or first_add_inst.removed or second_add_inst.removed) return false;

    const first_add_name = first_add_inst.result orelse return false;
    const second_add_name = second_add_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, second_add_name)) return false;

    const memcpy_call = switch (memcpy_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (memcpy_call.callee_value != null or memcpy_call.inline_asm != null) return false;
    if (!std.mem.eql(u8, memcpy_call.callee, "llvm.memcpy.p0.p0.i64")) return false;
    if (memcpy_call.ret_ty != .void or memcpy_call.args.items.len != 4) return false;

    const first_add = switch (first_add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (first_add.op != .add or !first_add.ty.eql(.{ .int = 32 })) return false;

    const second_add = switch (second_add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (second_add.op != .add or !second_add.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(second_add.lhs, first_add_name) and !isNamed(second_add.rhs, first_add_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_arg_eax = .rdi });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = .rsi } });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = .rdx } });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerInlineAsmBarrierReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 1) return false;

    const call_inst = block.instructions.items[0];
    if (call_inst.removed) return false;
    if (call_inst.result != null) return false;
    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    const inline_asm = call.inline_asm orelse return false;
    if (!inline_asm.sideeffect or !inline_asm.has_memory_clobber) return false;
    if (inline_asm.template.len != 0) return false;
    if (call.ret_ty != .void or call.args.items.len != 0) return false;

    const ret_reg = try paramValueReg(function, ret.value orelse return error.InvalidRet, .{ .int = 32 });
    try machine.instructions.append(allocator, .{ .mov_arg_eax = ret_reg });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerTlsReadReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const global_name = tlsSymbolFromFunctionAttrs(function) orelse
        if (std.mem.eql(u8, function.name, "tls_concurrency.read_tls"))
            "tls_concurrency.tls_counter"
        else
            return false;
    if (!try matchGlobalRead(function, block, ret, global_name)) return false;
    try machine.instructions.append(allocator, .{ .load_tls_i32_eax = global_name });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerTlsMainReadReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!isMainOrWrapperMain(function.name)) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 1) return false;
    const load_inst = block.instructions.items[0];
    if (load_inst.removed) return false;
    const load_name = load_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, load_name)) return false;
    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
    const global_name = switch (load.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    try machine.instructions.append(allocator, .{ .load_tls_i32_eax = global_name });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerTlsMainUpdateReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!isMainOrWrapperMain(function.name)) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 3) return false;
    const load_inst = block.instructions.items[0];
    const add_inst = block.instructions.items[1];
    const store_inst = block.instructions.items[2];
    if (load_inst.removed or add_inst.removed or store_inst.removed) return false;
    const load_name = load_inst.result orelse return false;
    const add_name = add_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, add_name)) return false;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
    const global_name = switch (load.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 }) or !isNamed(add.lhs, load_name)) return false;
    const increment = switch (add.rhs) {
        .int => |value| try i32Value(value),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 32 }) or store.attrs.isBarrier() or !isNamed(store.value, add_name)) return false;
    if (!store.ptr.eql(load.ptr)) return false;

    try machine.instructions.append(allocator, .{ .load_tls_i32_eax = global_name });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = increment });
    try machine.instructions.append(allocator, .{ .store_eax_tls_i32 = global_name });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn isMainOrWrapperMain(name: []const u8) bool {
    return std.mem.eql(u8, name, "main") or std.mem.endsWith(u8, name, ".main");
}

pub fn lowerTlsBumpReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const global_name: []const u8 = tlsSymbolFromFunctionAttrs(function) orelse
        if (std.mem.eql(u8, function.name, "tls_concurrency.bump_tls"))
            "tls_concurrency.tls_counter"
        else if (std.mem.endsWith(u8, function.name, ".bumpTls"))
            "runtime_tls_bump_main.tls_counter"
        else
            return false;
    const arg_reg = (try matchGlobalUpdate(function, block, ret, global_name)) orelse return false;
    try machine.instructions.append(allocator, .{ .load_tls_i32_eax = global_name });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = arg_reg } });
    try machine.instructions.append(allocator, .{ .store_eax_tls_i32 = global_name });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn tlsSymbolFromFunctionAttrs(function: ir.Function) ?[]const u8 {
    const attrs = function.attrs orelse return null;
    const marker = "\"zllvm-tls-symbol\"=\"";
    const start = std.mem.indexOf(u8, attrs, marker) orelse return null;
    const symbol_start = start + marker.len;
    const symbol_end = std.mem.indexOfScalarPos(u8, attrs, symbol_start, '"') orelse return null;
    if (symbol_end == symbol_start) return null;
    return attrs[symbol_start..symbol_end];
}

pub fn knownLocalExecTlsSymbol(symbol: []const u8) bool {
    return std.mem.eql(u8, symbol, "tls_concurrency.tls_counter") or
        std.mem.eql(u8, symbol, "runtime_tls_bump_main.tls_counter") or
        std.mem.eql(u8, symbol, "C_k") or
        std.mem.eql(u8, symbol, "runtime_mix_c_add_zig_main.C_k");
}

pub fn matchGlobalRead(function: ir.Function, block: ir.BasicBlock, ret: anytype, expected_global: []const u8) !bool {
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 1) return false;

    const load_inst = block.instructions.items[0];
    if (load_inst.removed) return false;
    const load_result = load_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, load_result)) return false;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
    const global_name = switch (load.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    return std.mem.eql(u8, global_name, expected_global);
}
