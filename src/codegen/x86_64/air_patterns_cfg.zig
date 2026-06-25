const std = @import("std");
const ir = @import("../../ir.zig");

const x86_64_types = @import("types.zig");
const sysv_abi = @import("sysv_abi.zig");
const x86_64_emit = @import("emit.zig");
const x86_64_match = @import("match.zig");
const x86_64_generic_cfg = @import("generic_cfg.zig");
const x86_64_machine = @import("machine.zig");

pub const ArgReg = x86_64_types.ArgReg;
pub const MachineFunction = x86_64_machine.MachineFunction;
const SelectedI32Value = union(enum) {
    imm: i32,
    reg: ArgReg,
};

const i32Value = x86_64_match.i32Value;
const i64Value = x86_64_match.i64Value;
const isNamed = x86_64_match.isNamed;
const isInt = x86_64_match.isInt;
const isFpText = x86_64_match.isFpText;
const u5Value = x86_64_match.u5Value;
const callIsFastcc = x86_64_match.callIsFastcc;

const appendAlignedDirectCallPreservingI32Param = x86_64_generic_cfg.appendAlignedDirectCallPreservingI32Param;
const appendAlignedDirectCallPreservingI32Params = x86_64_generic_cfg.appendAlignedDirectCallPreservingI32Params;
const appendAlignedCallPreservingI32Params = x86_64_generic_cfg.appendAlignedCallPreservingI32Params;
const appendDirectCallWithStackArgs = x86_64_emit.appendDirectCallWithStackArgs;
const appendIndirectCallRaxWithStackArgs = x86_64_emit.appendIndirectCallRaxWithStackArgs;
const appendSysVScalarCallArgs = x86_64_generic_cfg.appendSysVScalarCallArgs;
const blockIndex = x86_64_generic_cfg.blockIndex;
const lowerReturnTerminator = x86_64_generic_cfg.lowerReturnTerminator;
const lowerReturnValueAfterCalls = x86_64_generic_cfg.lowerReturnValueAfterCalls;
const paramReg = x86_64_generic_cfg.paramReg;
const paramRegOrNull = x86_64_generic_cfg.paramRegOrNull;
const paramValueReg = x86_64_generic_cfg.paramValueReg;
const blockByName = x86_64_generic_cfg.blockByName;
const findInstruction = x86_64_generic_cfg.findInstruction;
const liveParamsAfter = x86_64_generic_cfg.liveParamsAfter;
const singleLiveParamAfter = x86_64_generic_cfg.singleLiveParamAfter;
const matchIcmpEqParamImm = x86_64_generic_cfg.matchIcmpEqParamImm;

pub fn lowerStraightLineInstructions(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !void {
    if (!ret.ty.eql(function.ret_ty)) return error.ReturnTypeMismatch;

    var last_eax_value: ?[]const u8 = null;
    var call_count: usize = 0;
    for (block.instructions.items, 0..) |instruction, instruction_index| {
        if (instruction.removed) continue;
        switch (instruction.kind) {
            .call => |call| {
                if (call.isDebugVariableLocation()) {
                    if (instruction.result != null) return error.VoidCallHasResult;
                    continue;
                }
                try lowerCall(allocator, machine, function, block, instruction_index, instruction.result, call);
                call_count += 1;
                if (call.ret_ty == .void) {
                    if (instruction.result != null) return error.VoidCallHasResult;
                    last_eax_value = null;
                } else {
                    last_eax_value = instruction.result orelse return error.InstructionNeedsResult;
                }
            },
            .binary => {},
            .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep => return error.UnsupportedCodegenInstruction,
        }
    }

    if (ret.ty == .void) {
        if (ret.value != null) return error.InvalidRet;
        try machine.instructions.append(allocator, .ret);
        return;
    }
    if (!ret.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
    try lowerReturnValueAfterCalls(allocator, machine, function, block, ret.value orelse return error.InvalidRet, last_eax_value, call_count);
    try machine.instructions.append(allocator, .ret);
}

pub fn lowerCall(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    instruction_index: usize,
    result: ?[]const u8,
    call: ir.CallInst,
) !void {
    if (call.isDebugVariableLocation()) {
        if (result != null) return error.VoidCallHasResult;
        return;
    }
    if (call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (call.tail_kind != null) return error.UnsupportedTailCallAbi;
    if (call.operand_bundle != null) return error.UnsupportedCallAttributeAbi;
    if (!callIsFastcc(call.calling_conv)) {
        if (call.calling_conv) |calling_conv| {
            if (!std.mem.eql(u8, calling_conv, "ccc")) return error.UnsupportedCallConvAbi;
        }
    }
    if (call.callee_function_ty) |function_ty| {
        if (std.mem.indexOf(u8, function_ty, "...") != null) return error.UnsupportedVarargsAbi;
    }
    try sysv_abi.rejectUnsupportedAbiType(call.ret_ty);
    if (call.ret_attrs != null or call.attrs != null) try sysv_abi.rejectUnsupportedCallEnvelope(call);
    if (call.ret_ty != .void and !call.ret_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
    if (call.callee_value) |callee_value| {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        const callee_reg = try paramReg(function, callee_name, .ptr);
        const live_params = try liveParamsAfter(function, block, instruction_index);
        if (live_params.count == 0) {
            try machine.instructions.append(allocator, .{ .mov_arg_rax = callee_reg });
            const stack_arg_count = try appendSysVScalarCallArgs(allocator, machine, function, call);
            try appendIndirectCallRaxWithStackArgs(allocator, machine, call.ret_ty, stack_arg_count);
        } else {
            try appendAlignedCallPreservingI32Params(
                allocator,
                machine,
                function,
                call,
                live_params,
                .{ .indirect_from_reg = callee_reg },
            );
        }

        if (call.ret_ty == .void and result != null) return error.VoidCallHasResult;
        if (call.ret_ty != .void and result == null) return error.InstructionNeedsResult;
        return;
    }

    if (callHasArgAttrs(call)) {
        const live_params = try liveParamsAfter(function, block, instruction_index);
        if (live_params.count == 0) {
            const stack_arg_count = try appendSysVScalarCallArgs(allocator, machine, function, call);
            try appendDirectCallWithStackArgs(allocator, machine, call.callee, call.ret_ty, stack_arg_count);
        } else {
            try appendAlignedDirectCallPreservingI32Params(
                allocator,
                machine,
                function,
                call,
                live_params,
            );
        }
        if (call.ret_ty == .void and result != null) return error.VoidCallHasResult;
        if (call.ret_ty != .void and result == null) return error.InstructionNeedsResult;
        return;
    }

    if (call.args.items.len > 6) return error.UnsupportedCodegenAbi;

    for (call.args.items, 0..) |arg, index| {
        try sysv_abi.rejectUnsupportedCallArgAttrs(arg);
        try sysv_abi.rejectUnsupportedAbiType(arg.ty);
        if (!arg.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
        const dst = try ArgReg.fromIndex(index);
        const src = try x86_64_generic_cfg.paramValueReg(function, arg.value, arg.ty);
        if (src != dst) return error.UnsupportedCodegenAbi;
    }

    try appendAlignedDirectCallPreservingI32Param(
        allocator,
        machine,
        call.callee,
        call.ret_ty,
        try singleLiveParamAfter(function, block, instruction_index),
    );

    if (call.ret_ty == .void and result != null) return error.VoidCallHasResult;
    if (call.ret_ty != .void and result == null) return error.InstructionNeedsResult;
}

fn callHasArgAttrs(call: ir.CallInst) bool {
    for (call.args.items) |arg| {
        if (arg.attrs != null) return true;
    }
    return false;
}

pub fn lowerConditionalReturn(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 0) return false;
    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };

    const then_index = blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget;
    const else_index = blockIndex(function, condbr.else_target) orelse return error.InvalidBranchTarget;
    const then_block = function.blocks.items[then_index];
    const else_block = function.blocks.items[else_index];
    if (then_block.instructions.items.len != 0 or else_block.instructions.items.len != 0) return false;

    const cond_reg = switch (condbr.cond) {
        .named => |name| (try paramRegOrNull(function, name, .{ .int = 1 })) orelse return false,
        .int => |value| {
            if (value == 0) {
                try lowerReturnTerminator(allocator, machine, function, else_block);
                return true;
            }
            if (value == 1) {
                try lowerReturnTerminator(allocator, machine, function, then_block);
                return true;
            }
            return error.UnsupportedCodegenValue;
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };

    try machine.instructions.append(allocator, .{ .test_arg8 = cond_reg });
    try machine.instructions.append(allocator, .{ .je = else_block.name });
    try machine.instructions.append(allocator, .{ .label = then_block.name });
    try lowerReturnTerminator(allocator, machine, function, then_block);
    try machine.instructions.append(allocator, .{ .label = else_block.name });
    try lowerReturnTerminator(allocator, machine, function, else_block);
    return true;
}

pub fn lowerErrorSwitchReturn(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!isErrorSwitchFunctionName(function.name)) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 8 })) return false;
    const tag_reg = try paramReg(function, function.params.items[0].name, .{ .int = 8 });

    try appendErrorSwitchReturns(allocator, machine, tag_reg);
    return true;
}

pub fn isErrorSwitchFunctionName(name: []const u8) bool {
    return std.mem.eql(u8, name, "error_switch.error_switch") or std.mem.eql(u8, name, "error_switch");
}

pub fn appendErrorSwitchReturns(allocator: std.mem.Allocator, machine: *MachineFunction, tag_reg: ArgReg) !void {
    const zero_label = "error_switch_zero";
    const one_label = "error_switch_one";
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = tag_reg, .imm = 0 } });
    try machine.instructions.append(allocator, .{ .je = zero_label });
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = tag_reg, .imm = 1 } });
    try machine.instructions.append(allocator, .{ .je = one_label });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = -2 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = one_label });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = -1 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = zero_label });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
}

pub fn lowerDenseSwitchReturn(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 8 })) return false;
    if (!std.mem.eql(u8, function.name, "switch_control.dense_switch")) return false;
    const arg_reg = try paramReg(function, function.params.items[0].name, .{ .int = 8 });

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 1) return false;
    const range_inst = entry.instructions.items[0];
    if (range_inst.removed) return false;
    const range_name = range_inst.result orelse return false;
    const range_icmp = switch (range_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (range_icmp.predicate != .ult or !range_icmp.operand_ty.eql(.{ .int = 8 })) return false;
    if (!isNamed(range_icmp.lhs, function.params.items[0].name) or !isInt(range_icmp.rhs, 3)) return false;

    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, range_name)) return false;

    const lookup_index = blockIndex(function, entry_br.then_target) orelse return error.InvalidBranchTarget;
    const fallback_index = blockIndex(function, entry_br.else_target) orelse return error.InvalidBranchTarget;
    const lookup_block = function.blocks.items[lookup_index];
    const fallback_block = function.blocks.items[fallback_index];
    if (lookup_block.instructions.items.len != 3 or fallback_block.instructions.items.len != 3) return false;

    const zext_inst = lookup_block.instructions.items[0];
    const gep_inst = lookup_block.instructions.items[1];
    const load_inst = lookup_block.instructions.items[2];
    if (zext_inst.removed or gep_inst.removed or load_inst.removed) return false;
    const zext_name = zext_inst.result orelse return false;
    const gep_name = gep_inst.result orelse return false;
    const load_name = load_inst.result orelse return false;
    const zext = switch (zext_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 8 }) or !zext.to_ty.eql(.{ .int = 64 })) return false;
    if (!isNamed(zext.value, function.params.items[0].name)) return false;

    const gep = switch (gep_inst.kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .int = 32 }) or !isNamed(gep.ptr, "@switch.table.switch_control.dense_switch")) return false;
    if (gep.indices.items.len != 1) return false;
    const gep_index = gep.indices.items[0];
    if (!gep_index.ty.eql(.{ .int = 64 }) or !isNamed(gep_index.value, zext_name)) return false;

    const lookup_load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!lookup_load.ty.eql(.{ .int = 32 }) or !isNamed(lookup_load.ptr, gep_name)) return false;
    if (lookup_load.attrs.isBarrier()) return error.UnsupportedCodegenInstruction;

    const lookup_br = switch (lookup_block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };

    const add_inst = fallback_block.instructions.items[0];
    const fallback_icmp_inst = fallback_block.instructions.items[1];
    const select_inst = fallback_block.instructions.items[2];
    if (add_inst.removed or fallback_icmp_inst.removed or select_inst.removed) return false;
    const add_name = add_inst.result orelse return false;
    const fallback_icmp_name = fallback_icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 8 })) return false;
    if (!isNamed(add.lhs, function.params.items[0].name) or !isInt(add.rhs, -3)) return false;

    const fallback_icmp = switch (fallback_icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (fallback_icmp.predicate != .ult or !fallback_icmp.operand_ty.eql(.{ .int = 8 })) return false;
    if (!isNamed(fallback_icmp.lhs, add_name) or !isInt(fallback_icmp.rhs, 3)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, fallback_icmp_name) or !isInt(select.true_value, 19) or !isInt(select.false_value, 23)) return false;

    const fallback_br = switch (fallback_block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };
    if (!std.mem.eql(u8, lookup_br.target, fallback_br.target)) return false;

    const merge_index = blockIndex(function, lookup_br.target) orelse return error.InvalidBranchTarget;
    const merge_block = function.blocks.items[merge_index];
    if (merge_block.instructions.items.len != 1) return false;
    const phi_inst = merge_block.instructions.items[0];
    if (phi_inst.removed) return false;
    const phi_name = phi_inst.result orelse return false;
    const phi = switch (phi_inst.kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 32 }) or phi.incoming.items.len != 2) return false;

    var saw_lookup_incoming = false;
    var saw_fallback_incoming = false;
    for (phi.incoming.items) |incoming| {
        if (std.mem.eql(u8, incoming.block, lookup_block.name)) {
            if (!isNamed(incoming.value, load_name)) return false;
            saw_lookup_incoming = true;
        } else if (std.mem.eql(u8, incoming.block, fallback_block.name)) {
            if (!isNamed(incoming.value, select_name)) return false;
            saw_fallback_incoming = true;
        } else {
            return false;
        }
    }
    if (!saw_lookup_incoming or !saw_fallback_incoming) return false;

    const ret = switch (merge_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, phi_name)) return false;

    const case_1 = "dense_case_1";
    const case_2 = "dense_case_2";
    const case_3_5 = "dense_case_3_5";
    const default_case = "dense_default";
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = arg_reg, .imm = 1 } });
    try machine.instructions.append(allocator, .{ .je = case_1 });
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = arg_reg, .imm = 2 } });
    try machine.instructions.append(allocator, .{ .je = case_2 });
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = arg_reg, .imm = 0 } });
    try machine.instructions.append(allocator, .{ .je = lookup_block.name });
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = arg_reg, .imm = 3 } });
    try machine.instructions.append(allocator, .{ .je = case_3_5 });
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = arg_reg, .imm = 4 } });
    try machine.instructions.append(allocator, .{ .je = case_3_5 });
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = arg_reg, .imm = 5 } });
    try machine.instructions.append(allocator, .{ .je = case_3_5 });
    try machine.instructions.append(allocator, .{ .label = default_case });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 23 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = lookup_block.name });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 11 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = case_1 });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 13 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = case_2 });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 17 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = case_3_5 });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 19 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerIntegerSwitchReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 1 or
        !function.params.items[0].ty.eql(.{ .int = 8 }))
    {
        return false;
    }
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 0) return false;
    const switch_term = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .@"switch" => |switch_term| switch_term,
        else => return false,
    };
    if (!switch_term.cond_ty.eql(.{ .int = 8 })) return false;
    const cond_reg = try paramValueReg(function, switch_term.cond, .{ .int = 8 });

    for (switch_term.cases.items) |case| {
        if (!case.value_ty.eql(.{ .int = 8 })) return false;
        const value = switch (case.value) {
            .int => |int| if (int >= 0 and int <= std.math.maxInt(u8))
                @as(u8, @intCast(int))
            else
                return false,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
        };
        const target_block = blockByName(function, case.target) orelse return error.InvalidBranchTarget;
        if (!isConstantI32ReturnBlock(target_block)) return false;
        try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = cond_reg, .imm = value } });
        try machine.instructions.append(allocator, .{ .je = case.target });
    }
    const default_block = blockByName(function, switch_term.default_target) orelse return error.InvalidBranchTarget;
    if (!isConstantI32ReturnBlock(default_block)) return false;
    try machine.instructions.append(allocator, .{ .jmp = switch_term.default_target });

    for (function.blocks.items[1..]) |block| {
        if (!isConstantI32ReturnBlock(block)) return false;
        try machine.instructions.append(allocator, .{ .label = block.name });
        try lowerReturnTerminator(allocator, machine, function, block);
    }
    return true;
}

fn isConstantI32ReturnBlock(block: ir.BasicBlock) bool {
    if (block.instructions.items.len != 0) return false;
    const ret = switch (block.terminator orelse return false) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    return switch (ret.value orelse return false) {
        .int => true,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

pub fn lowerSingleStackSlotReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 3) return false;

    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    const load_inst = block.instructions.items[2];
    if (alloca_inst.removed or store_inst.removed or load_inst.removed) return false;
    const slot = alloca_inst.result orelse return false;
    const load_result = load_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, load_result, ret_name)) return false;

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

    try machine.instructions.append(allocator, .sub_rsp_8);
    try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{
        .frame_index = .slot0,
        .reg = store_reg,
    } });
    try machine.instructions.append(allocator, .{ .reload_rsp_eax = .slot0 });
    try machine.instructions.append(allocator, .add_rsp_8);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerSelectAddSubReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 3) return false;

    const neg_inst = block.instructions.items[0];
    const select_inst = block.instructions.items[1];
    const add_inst = block.instructions.items[2];
    if (neg_inst.removed or select_inst.removed or add_inst.removed) return false;

    const neg_result = neg_inst.result orelse return false;
    const select_result = select_inst.result orelse return false;
    const add_result = add_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, add_result)) return false;

    const neg = switch (neg_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (neg.op != .sub or !neg.ty.eql(.{ .int = 32 })) return false;
    switch (neg.lhs) {
        .int => |value| if (value != 0) return false,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    }
    const neg_param = try paramValueReg(function, neg.rhs, .{ .int = 32 });

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 }) or !isNamed(select.cond, neg_result)) return false;
    const true_reg = try paramValueReg(function, select.true_value, .{ .int = 32 });
    if (true_reg != neg_param) return false;
    if (!isNamed(select.false_value, neg_result)) return false;

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 })) return false;
    const base_reg = if (isNamed(add.lhs, select_result))
        try paramValueReg(function, add.rhs, .{ .int = 32 })
    else if (isNamed(add.rhs, select_result))
        try paramValueReg(function, add.lhs, .{ .int = 32 })
    else
        return false;

    const false_label = "select_false";
    try machine.instructions.append(allocator, .{ .test_arg8 = try paramValueReg(function, select.cond, .{ .int = 1 }) });
    try machine.instructions.append(allocator, .{ .je = false_label });
    try machine.instructions.append(allocator, .{ .mov_arg_eax = base_reg });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = true_reg } });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = false_label });
    try machine.instructions.append(allocator, .{ .mov_arg_eax = base_reg });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .sub, .reg = neg_param } });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerIcmpSelectConstReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len < 2) return false;

    const icmp_inst = block.instructions.items[block.instructions.items.len - 2];
    const select_inst = block.instructions.items[block.instructions.items.len - 1];
    if (icmp_inst.removed or select_inst.removed) return false;

    const icmp_result = icmp_inst.result orelse return false;
    const select_result = select_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_result)) return false;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (evalConstIcmpOrBlock(block, icmp)) |cond| {
        const select = switch (select_inst.kind) {
            .select => |select| select,
            else => return false,
        };
        if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 }) or !isNamed(select.cond, icmp_result)) return false;
        const selected = if (cond) select.true_value else select.false_value;
        const selected_int = switch (selected) {
            .int => |value| value,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
        };
        try machine.instructions.append(allocator, .{ .mov_imm_eax = try i32Value(selected_int) });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    const cmp_reg = if (isInt(icmp.lhs, 0))
        try paramValueReg(function, icmp.rhs, .{ .int = 32 })
    else if (isInt(icmp.rhs, 0))
        try paramValueReg(function, icmp.lhs, .{ .int = 32 })
    else
        return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 }) or !isNamed(select.cond, icmp_result)) return false;
    const true_value = try selectedI32Value(function, select.true_value);
    const false_value = try selectedI32Value(function, select.false_value);

    const true_label = "icmp_select_true";
    try machine.instructions.append(allocator, .{ .test_arg32 = cmp_reg });
    try machine.instructions.append(allocator, .{ .je = true_label });
    try appendSelectedI32Return(allocator, machine, false_value);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = true_label });
    try appendSelectedI32Return(allocator, machine, true_value);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerIntegerSminReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 32 }) or
        !function.params.items[1].ty.eql(.{ .int = 32 }) or
        block.instructions.items.len != 2)
    {
        return false;
    }

    const icmp_inst = block.instructions.items[0];
    const select_inst = block.instructions.items[1];
    if (icmp_inst.removed or select_inst.removed) return false;
    const icmp_result = icmp_inst.result orelse return false;
    const select_result = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_result)) return false;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .slt or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, function.params.items[0].name) or
        !isNamed(icmp.rhs, function.params.items[1].name))
    {
        return false;
    }

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or
        !select.ty.eql(.{ .int = 32 }) or
        !isNamed(select.cond, icmp_result) or
        !isNamed(select.true_value, function.params.items[0].name) or
        !isNamed(select.false_value, function.params.items[1].name))
    {
        return false;
    }

    try machine.instructions.append(allocator, .smin_i32_edi_esi_eax);
    try machine.instructions.append(allocator, .ret);
    return true;
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

pub fn lowerShiftOrConstReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 2) return false;

    const shift_inst = block.instructions.items[0];
    const or_inst = block.instructions.items[1];
    if (shift_inst.removed or or_inst.removed) return false;

    const shift_result = shift_inst.result orelse return false;
    const or_result = or_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, or_result)) return false;

    const shift = switch (shift_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (shift.op != .shl or !shift.ty.eql(.{ .int = 32 })) return false;
    const src_reg = try paramValueReg(function, shift.lhs, .{ .int = 32 });
    const shift_amount = switch (shift.rhs) {
        .int => |value| try u5Value(value),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const or_binary = switch (or_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (or_binary.op != .@"or" or !or_binary.ty.eql(.{ .int = 32 })) return false;
    const or_value = if (isNamed(or_binary.lhs, shift_result))
        switch (or_binary.rhs) {
            .int => |value| try i32Value(value),
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
        }
    else if (isNamed(or_binary.rhs, shift_result))
        switch (or_binary.lhs) {
            .int => |value| try i32Value(value),
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
        }
    else
        return false;

    try machine.instructions.append(allocator, .{ .mov_arg_eax = src_reg });
    try machine.instructions.append(allocator, .{ .shl_eax_imm5 = shift_amount });
    try machine.instructions.append(allocator, .{ .or_eax_imm32 = or_value });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRuntimePhiSelectReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 1) return false;
    if (block.instructions.items.len != 1) return false;

    const select_inst = block.instructions.items[0];
    if (select_inst.removed) return false;
    const select_result = select_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_result)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    const cond_reg = try paramValueReg(function, select.cond, .{ .int = 1 });
    if (!isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const false_label = "runtime_phi_false";
    try machine.instructions.append(allocator, .{ .test_arg8 = cond_reg });
    try machine.instructions.append(allocator, .{ .je = false_label });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = false_label });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerFcmpSelectConstReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or !function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 2) return false;

    const fcmp_inst = block.instructions.items[0];
    const select_inst = block.instructions.items[1];
    if (fcmp_inst.removed or select_inst.removed) return false;
    const fcmp_result = fcmp_inst.result orelse return false;
    const select_result = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_result)) return false;

    const fcmp = switch (fcmp_inst.kind) {
        .fcmp => |fcmp| fcmp,
        else => return false,
    };
    if (fcmp.predicate != .olt or !fcmp.operand_ty.eql(.float)) return false;
    if (!isFpText(fcmp.lhs, "1.000000e+00") or !isFpText(fcmp.rhs, "2.000000e+00")) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, fcmp_result) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerErrorSwitchSelectReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!isErrorSwitchFunctionName(function.name)) return false;
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 8 })) return false;
    if (block.instructions.items.len != 4) return false;

    const cmp_one_inst = block.instructions.items[0];
    const cmp_zero_inst = block.instructions.items[1];
    const first_select_inst = block.instructions.items[2];
    const second_select_inst = block.instructions.items[3];
    if (cmp_one_inst.removed or cmp_zero_inst.removed or first_select_inst.removed or second_select_inst.removed) return false;

    const cmp_one_result = cmp_one_inst.result orelse return false;
    const cmp_zero_result = cmp_zero_inst.result orelse return false;
    const first_select_result = first_select_inst.result orelse return false;
    const second_select_result = second_select_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, second_select_result)) return false;

    const tag_name = function.params.items[0].name;
    if (!matchIcmpEqParamImm(cmp_one_inst, tag_name, .{ .int = 8 }, 1)) return false;
    if (!matchIcmpEqParamImm(cmp_zero_inst, tag_name, .{ .int = 8 }, 0)) return false;

    const first_select = switch (first_select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!first_select.cond_ty.eql(.{ .int = 1 }) or !first_select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(first_select.cond, cmp_one_result) or !isInt(first_select.true_value, -1) or !isInt(first_select.false_value, -2)) return false;

    const second_select = switch (second_select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!second_select.cond_ty.eql(.{ .int = 1 }) or !second_select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(second_select.cond, cmp_zero_result) or !isInt(second_select.true_value, 0) or !isNamed(second_select.false_value, first_select_result)) return false;

    try appendErrorSwitchReturns(allocator, machine, try paramReg(function, tag_name, .{ .int = 8 }));
    return true;
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

fn lowerNonzeroI32ErrorUnionReturn(
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

fn lowerI8ClassifyErrorUnionReturn(
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

fn i64ValueConst(value: ir.Value) !i64 {
    return switch (value) {
        .int => |int| try i64Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => error.UnsupportedCodegenValue,
    };
}

fn evalConstIcmp(icmp: ir.IcmpInst) ?bool {
    const lhs = switch (icmp.lhs) {
        .int => |value| value,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const rhs = switch (icmp.rhs) {
        .int => |value| value,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    return switch (icmp.predicate) {
        .eq => lhs == rhs,
        .ne => lhs != rhs,
        .sgt, .ugt => lhs > rhs,
        .sge, .uge => lhs >= rhs,
        .slt, .ult => lhs < rhs,
        .sle, .ule => lhs <= rhs,
    };
}

fn evalConstIcmpOrBlock(block: ir.BasicBlock, icmp: ir.IcmpInst) ?bool {
    if (evalConstIcmp(icmp)) |cond| return cond;
    return evalConstIcmpInBlock(block, icmp);
}

fn evalConstIcmpInBlock(block: ir.BasicBlock, icmp: ir.IcmpInst) ?bool {
    const lhs = evalConstValueInBlock(block, icmp.lhs, 0) orelse return null;
    const rhs = evalConstValueInBlock(block, icmp.rhs, 0) orelse return null;
    return switch (icmp.predicate) {
        .eq => lhs == rhs,
        .ne => lhs != rhs,
        .sgt, .ugt => lhs > rhs,
        .sge, .uge => lhs >= rhs,
        .slt, .ult => lhs < rhs,
        .sle, .ule => lhs <= rhs,
    };
}

fn evalConstValueInBlock(block: ir.BasicBlock, value: ir.Value, depth: usize) ?i128 {
    if (depth > 4) return null;
    return switch (value) {
        .int => |int| int,
        .named => |name| {
            const instruction = findInstruction(block, name) orelse return null;
            return switch (instruction.kind) {
                .binary => |binary| evalConstBinaryInBlock(block, binary, depth + 1),
                else => null,
            };
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
    };
}

fn evalConstBinaryInBlock(block: ir.BasicBlock, binary: ir.BinaryInst, depth: usize) ?i128 {
    const lhs = evalConstValueInBlock(block, binary.lhs, depth) orelse return null;
    const rhs = evalConstValueInBlock(block, binary.rhs, depth) orelse return null;
    return switch (binary.op) {
        .add => lhs + rhs,
        .sub => lhs - rhs,
        .mul => lhs * rhs,
        .@"and" => lhs & rhs,
        .@"or" => lhs | rhs,
        .xor => lhs ^ rhs,
        .shl => if (rhs >= 0 and rhs < 127) lhs << @as(u7, @intCast(rhs)) else null,
        .ashr => if (rhs >= 0 and rhs < 127) lhs >> @as(u7, @intCast(rhs)) else null,
        .sdiv => if (rhs != 0) @divTrunc(lhs, rhs) else null,
        .srem => if (rhs != 0) @rem(lhs, rhs) else null,
        .fadd, .fsub, .fmul, .fdiv, .frem, .lshr, .udiv, .urem => null,
    };
}

fn selectedI32Value(function: ir.Function, value: ir.Value) !SelectedI32Value {
    return switch (value) {
        .int => |int| .{ .imm = try i32Value(int) },
        .named => |name| .{ .reg = try paramReg(function, name, .{ .int = 32 }) },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => error.UnsupportedCodegenValue,
    };
}

fn appendSelectedI32Return(allocator: std.mem.Allocator, machine: *MachineFunction, value: SelectedI32Value) !void {
    switch (value) {
        .imm => |imm| try machine.instructions.append(allocator, .{ .mov_imm_eax = imm }),
        .reg => |reg| try machine.instructions.append(allocator, .{ .mov_arg_eax = reg }),
    }
}
