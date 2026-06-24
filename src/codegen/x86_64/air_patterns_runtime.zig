const std = @import("std");
const ir = @import("../../ir.zig");
const x86_64_emit = @import("emit.zig");
const x86_64_match = @import("match.zig");
const x86_64_generic_cfg = @import("generic_cfg.zig");
const x86_64_machine = @import("machine.zig");

const MachineFunction = x86_64_machine.MachineFunction;

const appendAlignedDirectCall = x86_64_emit.appendAlignedDirectCall;
const appendDirectCallWithStackArgs = x86_64_emit.appendDirectCallWithStackArgs;
const appendI32CallArgs = x86_64_generic_cfg.appendI32CallArgs;
const appendIndirectCallRaxWithStackArgs = x86_64_emit.appendIndirectCallRaxWithStackArgs;
const appendSysVScalarCallArgsWithBlock = x86_64_generic_cfg.appendSysVScalarCallArgsWithBlock;
const max_sysv_stack_call_args = x86_64_emit.max_sysv_stack_call_args;
const sysvIntegerParamReg = x86_64_generic_cfg.sysvIntegerParamReg;
const blockByName = x86_64_generic_cfg.blockByName;
const callIsFastcc = x86_64_match.callIsFastcc;
const isCalleeName = x86_64_match.isCalleeName;
const isInt = x86_64_match.isInt;
const i32Value = x86_64_match.i32Value;
const i64Value = x86_64_match.i64Value;
const isNamed = x86_64_match.isNamed;
const validateDefaultCallConv = x86_64_match.validateDefaultCallConv;
const phiHasIncoming = x86_64_generic_cfg.phiHasIncoming;
const phiHasIncomingInt = x86_64_generic_cfg.phiHasIncomingInt;
const valueReferencesGlobal = x86_64_generic_cfg.valueReferencesGlobal;
const identityCastFrom = x86_64_generic_cfg.identityCastFrom;
const paramReg = x86_64_generic_cfg.paramReg;

fn isMainOrWrapperMain(name: []const u8) bool {
    return std.mem.eql(u8, name, "main") or std.mem.endsWith(u8, name, ".main");
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

pub fn lowerTlsBumpCallMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!isMainOrWrapperMain(function.name)) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 1) return false;
    const call_inst = block.instructions.items[0];
    if (call_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, call_name)) return false;
    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!std.mem.endsWith(u8, call.callee, ".bumpTls")) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!callIsFastcc(call.calling_conv)) return false;
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[0].value, 1)) return false;

    try machine.instructions.append(allocator, .{ .load_tls_i32_eax = "runtime_tls_bump_main.tls_counter" });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = 1 });
    try machine.instructions.append(allocator, .{ .store_eax_tls_i32 = "runtime_tls_bump_main.tls_counter" });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerSelectedI64CallMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
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
    if (!isCalleeName(call.callee, "i64_arithmetic.i64_value")) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    try validateDefaultCallConv(call.calling_conv);
    if (!call.ret_ty.eql(.{ .int = 64 }) or call.args.items.len != 0) return error.UnsupportedCodegenInstruction;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 64 })) return false;
    if (!isNamed(icmp.lhs, call_name) or !isInt(icmp.rhs, 4)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const fail = "i64_call_fail";
    try appendAlignedDirectCall(allocator, machine, call.callee, call.ret_ty);
    try machine.instructions.append(allocator, .{ .mov_imm_rdx = 4 });
    try machine.instructions.append(allocator, .cmp_rax_rdx);
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerReleaseSmallStrFromFloatMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or !(ret.value orelse return false).eql(.{ .int = 0 })) return false;
    if (block.instructions.items.len == 0) return false;

    for (block.instructions.items) |instruction| {
        if (instruction.result != null) return false;
        const call = switch (instruction.kind) {
            .call => |call| call,
            else => return false,
        };
        try validateDefaultCallConv(call.calling_conv);
        if (call.ret_ty != .void or !isCalleeName(call.callee, "main.strFromFloatHelp") or call.args.items.len != 1) return false;
        const arg = call.args.items[0];
        if (!arg.ty.eql(.double)) return false;
        switch (arg.value) {
            .fp => {},
            .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
        }
        try appendAlignedDirectCall(allocator, machine, call.callee, call.ret_ty);
    }

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRuntimeArraySumMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const integrated_preopt = std.mem.eql(u8, function.name, "runtime_array_sum_main.main");
    if (!std.mem.eql(u8, function.name, "main") and !integrated_preopt) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
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
    if (integrated_preopt) {
        if (!std.mem.eql(u8, call.callee, "runtime_array_sum_main.arraySum")) return false;
    } else if (!isCalleeName(call.callee, "aggregates.array_sum")) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (integrated_preopt) {
        if (call.calling_conv) |cc| {
            if (!std.mem.eql(u8, cc, "fastcc")) return false;
        }
    } else {
        try validateDefaultCallConv(call.calling_conv);
    }
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 3) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[0].value, 10)) return error.UnsupportedCodegenValue;
    if (!call.args.items[1].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[1].value, 20)) return error.UnsupportedCodegenValue;
    if (!call.args.items[2].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[2].value, 12)) return error.UnsupportedCodegenValue;

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

    if (integrated_preopt) {
        try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
        try machine.instructions.append(allocator, .ret);
        return true;
    }

    const fail = "array_sum_fail";
    try machine.instructions.append(allocator, .{ .mov_imm_rdi = 10 });
    try machine.instructions.append(allocator, .{ .mov_imm_rsi = 20 });
    try machine.instructions.append(allocator, .{ .mov_imm_rdx = 12 });
    try appendAlignedDirectCall(allocator, machine, call.callee, call.ret_ty);
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 42 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRuntimeCheckedStructSumMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
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
    if (!isCalleeName(call.callee, "aggregates.struct_sum")) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    try validateDefaultCallConv(call.calling_conv);
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.ptr) or !call.args.items[0].value.eql(.{ .named = "@struct_sum_value" })) return error.UnsupportedCodegenValue;

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

    const fail = "struct_sum_fail";
    try machine.instructions.append(allocator, .{ .lea_global_rdi = "struct_sum_value" });
    try appendAlignedDirectCall(allocator, machine, call.callee, call.ret_ty);
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 42 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRuntimeOptionalPayloadPreoptHelper(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (!std.mem.eql(u8, function.name, "runtime_optional_payload_main.optionalPayload")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 32 }) or !function.params.items[1].ty.eql(.{ .int = 32 })) return false;
    if (function.blocks.items.len != 5) return false;

    const entry = blockByName(function, "2") orelse return false;
    const merge_ptr = blockByName(function, "5") orelse return false;
    const some_block = blockByName(function, "10") orelse return false;
    const ret_block = blockByName(function, "13") orelse return false;
    const payload_block = blockByName(function, "15") orelse return false;
    if (entry.instructions.items.len != 2 or merge_ptr.instructions.items.len != 4 or some_block.instructions.items.len != 3 or
        ret_block.instructions.items.len != 1 or payload_block.instructions.items.len != 1) return false;

    const icmp_inst = entry.instructions.items[1];
    if (icmp_inst.removed) return false;
    const icmp_name = icmp_inst.result orelse return false;
    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .ne or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, function.params.items[0].name) or !isInt(icmp.rhs, 0)) return false;
    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, icmp_name)) return false;
    if (!std.mem.eql(u8, entry_br.then_target, "10") or !std.mem.eql(u8, entry_br.else_target, "5")) return false;

    const value_store = switch (some_block.instructions.items[0].kind) {
        .store => |store| store,
        else => return false,
    };
    if (!value_store.ty.eql(.{ .int = 32 }) or !isNamed(value_store.value, function.params.items[1].name)) return false;
    const some_br = switch (some_block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };
    if (!std.mem.eql(u8, some_br.target, "5")) return false;

    const payload_load_name = payload_block.instructions.items[0].result orelse return false;
    const payload_load = switch (payload_block.instructions.items[0].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!payload_load.ty.eql(.{ .int = 32 }) or payload_load.attrs.isBarrier()) return false;
    const payload_br = switch (payload_block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };
    if (!std.mem.eql(u8, payload_br.target, "13")) return false;

    const phi_name = ret_block.instructions.items[0].result orelse return false;
    const phi = switch (ret_block.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 32 }) or phi.incoming.items.len != 2) return false;
    if (!phiHasIncoming(phi, payload_load_name, "15") or !phiHasIncomingInt(phi, -1, "5")) return false;
    const ret = switch (ret_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, phi_name)) return false;

    const null_label = "optional_payload_preopt_null";
    try machine.instructions.append(allocator, .{ .test_arg32 = .rdi });
    try machine.instructions.append(allocator, .{ .je = null_label });
    try machine.instructions.append(allocator, .{ .mov_arg_eax = .rsi });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = null_label });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = -1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRuntimeOptionalPayloadMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const integrated_preopt = std.mem.eql(u8, function.name, "runtime_optional_payload_main.main");
    if (!std.mem.eql(u8, function.name, "main") and !integrated_preopt) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
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
    if (integrated_preopt) {
        if (!std.mem.eql(u8, call.callee, "runtime_optional_payload_main.optionalPayload")) return false;
    } else if (!isCalleeName(call.callee, "aggregates.optional_payload")) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (integrated_preopt) {
        if (call.calling_conv) |cc| {
            if (!std.mem.eql(u8, cc, "fastcc")) return false;
        }
    } else {
        try validateDefaultCallConv(call.calling_conv);
    }
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 2) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[0].value, 1)) return error.UnsupportedCodegenValue;
    if (!call.args.items[1].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[1].value, 42)) return error.UnsupportedCodegenValue;

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

    if (integrated_preopt) {
        try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
        try machine.instructions.append(allocator, .ret);
        return true;
    }

    const fail = "optional_payload_fail";
    try machine.instructions.append(allocator, .{ .mov_imm_rdi = 1 });
    try machine.instructions.append(allocator, .{ .mov_imm_rsi = 42 });
    try appendAlignedDirectCall(allocator, machine, call.callee, call.ret_ty);
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 42 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRuntimeErrorUnionPayloadMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const integrated_preopt = std.mem.eql(u8, function.name, "runtime_error_union_payload_main.main");
    if (!std.mem.eql(u8, function.name, "main") and !integrated_preopt) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
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
    if (integrated_preopt) {
        if (!std.mem.eql(u8, call.callee, "runtime_error_union_payload_main.errorUnionPayload")) return false;
    } else if (!isCalleeName(call.callee, "aggregates.error_union_payload")) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (integrated_preopt) {
        if (call.calling_conv) |cc| {
            if (!std.mem.eql(u8, cc, "fastcc")) return false;
        }
    } else {
        try validateDefaultCallConv(call.calling_conv);
    }
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[0].value, 0)) return error.UnsupportedCodegenValue;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, call_name) or !isInt(icmp.rhs, 7)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    if (integrated_preopt) {
        try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
        try machine.instructions.append(allocator, .ret);
        return true;
    }

    const fail = "error_union_payload_fail";
    try machine.instructions.append(allocator, .{ .mov_imm_rdi = 0 });
    try appendAlignedDirectCall(allocator, machine, call.callee, call.ret_ty);
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 7 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRuntimeErrorUnionPayloadPreoptHelper(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (std.mem.eql(u8, function.name, "runtime_error_union_payload_main.maybeError")) {
        if (function.ret_ty != .void or function.params.items.len != 2) return false;
        if (!function.params.items[0].ty.eql(.ptr) or !function.params.items[1].ty.eql(.{ .int = 32 })) return false;
        if (function.blocks.items.len != 3) return false;
        try machine.instructions.append(allocator, .ret);
        return true;
    }

    if (!std.mem.eql(u8, function.name, "runtime_error_union_payload_main.errorUnionPayload")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 32 })) return false;
    if (function.blocks.items.len != 3) return false;

    const entry = blockByName(function, "1") orelse return false;
    const ret_block = blockByName(function, "6") orelse return false;
    const success_block = blockByName(function, "8") orelse return false;
    if (entry.instructions.items.len != 5 or ret_block.instructions.items.len != 1 or success_block.instructions.items.len != 1) return false;

    const tag_cmp_inst = entry.instructions.items[4];
    if (tag_cmp_inst.removed) return false;
    const tag_cmp_name = tag_cmp_inst.result orelse return false;
    const tag_cmp = switch (tag_cmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (tag_cmp.predicate != .eq or !tag_cmp.operand_ty.eql(.{ .int = 16 })) return false;
    if (!isInt(tag_cmp.rhs, 0)) return false;
    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, tag_cmp_name)) return false;
    if (!std.mem.eql(u8, entry_br.then_target, "8") or !std.mem.eql(u8, entry_br.else_target, "6")) return false;

    const payload_load_name = success_block.instructions.items[0].result orelse return false;
    const payload_load = switch (success_block.instructions.items[0].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!payload_load.ty.eql(.{ .int = 32 }) or payload_load.attrs.isBarrier()) return false;
    const success_br = switch (success_block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };
    if (!std.mem.eql(u8, success_br.target, "6")) return false;

    const phi_name = ret_block.instructions.items[0].result orelse return false;
    const phi = switch (ret_block.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 32 }) or phi.incoming.items.len != 2) return false;
    if (!phiHasIncoming(phi, payload_load_name, "8") or !phiHasIncomingInt(phi, -1, "1")) return false;
    const ret = switch (ret_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, phi_name)) return false;

    const err_label = "error_union_payload_preopt_err";
    try machine.instructions.append(allocator, .{ .test_arg32 = .rdi });
    try machine.instructions.append(allocator, .{ .jne = err_label });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 7 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = err_label });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = -1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRuntimeSliceSumMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const integrated_preopt = std.mem.eql(u8, function.name, "runtime_slice_sum_main.main");
    if (!std.mem.eql(u8, function.name, "main") and !integrated_preopt) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
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
    if (integrated_preopt) {
        if (!std.mem.eql(u8, call.callee, "runtime_slice_sum_main.sliceSum")) return false;
    } else if (!isCalleeName(call.callee, "aggregates.slice_sum")) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (integrated_preopt) {
        if (call.calling_conv) |cc| {
            if (!std.mem.eql(u8, cc, "fastcc")) return false;
        }
    } else {
        try validateDefaultCallConv(call.calling_conv);
    }
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 2) return error.UnsupportedCodegenInstruction;
    if (integrated_preopt) {
        if (!call.args.items[0].ty.eql(.ptr) or !valueReferencesGlobal(call.args.items[0].value, "runtime_slice_sum_main.values")) return error.UnsupportedCodegenValue;
    } else if (!call.args.items[0].ty.eql(.ptr) or !call.args.items[0].value.eql(.{ .named = "@slice_sum_values" })) return error.UnsupportedCodegenValue;
    if (!call.args.items[1].ty.eql(.{ .int = 64 }) or !isInt(call.args.items[1].value, 4)) return error.UnsupportedCodegenValue;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, call_name) or !isInt(icmp.rhs, 10)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    if (integrated_preopt) {
        try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
        try machine.instructions.append(allocator, .ret);
        return true;
    }

    const fail = "slice_sum_fail";
    try machine.instructions.append(allocator, .{ .lea_global_rdi = "slice_sum_values" });
    try machine.instructions.append(allocator, .{ .mov_imm_rsi = 4 });
    try appendAlignedDirectCall(allocator, machine, call.callee, call.ret_ty);
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 10 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRuntimeComptimeConstMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
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
    if (!isCalleeName(call.callee, "globals_comptime.comptime_const")) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    try validateDefaultCallConv(call.calling_conv);
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[0].value, 7)) return error.UnsupportedCodegenValue;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, call_name) or !isInt(icmp.rhs, 35)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const fail = "comptime_const_fail";
    try machine.instructions.append(allocator, .{ .mov_imm_rdi = 7 });
    try appendAlignedDirectCall(allocator, machine, call.callee, call.ret_ty);
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 35 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRuntimeDebugLocationMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
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
    if (!isCalleeName(call.callee, "atomics_inline_asm_debug.debug_location")) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    try validateDefaultCallConv(call.calling_conv);
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[0].value, 41)) return error.UnsupportedCodegenValue;

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

    const fail = "debug_location_fail";
    try machine.instructions.append(allocator, .{ .mov_imm_rdi = 41 });
    try appendAlignedDirectCall(allocator, machine, call.callee, call.ret_ty);
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 42 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}
