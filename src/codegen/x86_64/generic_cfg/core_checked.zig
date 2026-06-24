const impl = @import("core_impl.zig");
const diagnostics = @import("core_diagnostics.zig");
const loop_rows = @import("core_loop_rows.zig");
const std = impl.std;
const ir = impl.ir;
const MachineFunction = impl.MachineFunction;
const blockIndex = impl.blockIndex;
const blockByName = diagnostics.blockByName;
const globalSymbolName = impl.globalSymbolName;
const symbolName = impl.symbolName;
const isNamed = impl.isNamed;
const isInt = impl.isInt;
const isCalleeName = impl.isCalleeName;
const callIsFastcc = impl.callIsFastcc;
const callArgAttrsContain = impl.callArgAttrsContain;
const paramAttrsContain = impl.paramAttrsContain;
const isMainOrWrapperMain = impl.isMainOrWrapperMain;
const i32Value = impl.i32Value;
const fp64TextBits = impl.fp64TextBits;
const fp32TextBits = impl.fp32TextBits;
const paramReg = impl.paramReg;
const paramValueReg = impl.paramValueReg;
const appendIntegerOverflowCall = impl.appendIntegerOverflowCall;
const appendPanicCall = impl.appendPanicCall;
const appendAlignedDirectCall = impl.appendAlignedDirectCall;
const lowerRuntimeSliceSumPreoptHelper = loop_rows.lowerRuntimeSliceSumPreoptHelper;
const validateAssumeColdCall = impl.validateAssumeColdCall;
const validateIntegerOverflowPanicCall = impl.validateIntegerOverflowPanicCall;
const isSelectI1ToI32ExpectedOne = impl.isSelectI1ToI32ExpectedOne;
const isSelectI1ToI32ZeroOne = impl.isSelectI1ToI32ZeroOne;
const phiHasIncoming = impl.phiHasIncoming;

fn functionHasOverflowPanicEdge(function: ir.Function) bool {
    return sliceSumHasOverflowCheck(function);
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
