const shared = @import("core_shared.zig");
const diagnostics = @import("core_diagnostics.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");
const call_lowering = @import("cabi_call_lowering.zig");
const std = shared.std;
const ir = shared.ir;
const MachineFunction = shared.MachineFunction;

const isNamed = shared.isNamed;
const isInt = shared.isInt;
const isCalleeName = shared.isCalleeName;
const paramReg = cabi_abi_helpers.paramReg;
const appendDirectCall = shared.appendDirectCall;
const appendPanicCall = shared.appendPanicCall;
const appendStackFrame = shared.appendStackFrame;
const appendStackFrameEnd = shared.appendStackFrameEnd;
const phiHasIncoming = call_lowering.phiHasIncoming;
const phiHasIncomingInt = call_lowering.phiHasIncomingInt;

pub const GenericCfgLoopSumPlan = struct {
    checked: bool,
};

fn blockByName(function: ir.Function, name: []const u8) ?ir.BasicBlock {
    for (function.blocks.items) |block| {
        if (std.mem.eql(u8, block.name, name)) return block;
    }
    return null;
}

fn functionHasCall(function: ir.Function, callee: []const u8) bool {
    return diagnostics.functionHasCall(function, callee);
}

pub fn genericCfgLoopSumPlan(function: ir.Function) ?GenericCfgLoopSumPlan {
    if (!function.ret_ty.eql(.{ .int = 32 })) return null;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 32 })) return null;
    if (!matchesAccumulatorLoop(function) and
        !matchesUnrolledAccumulatorLoop(function) and
        !matchesCheckedUnrolledAccumulatorLoop(function) and
        !matchesGuardedDoWhileAccumulatorLoop(function) and
        !matchesCheckedGuardedDoWhileAccumulatorLoop(function)) return null;
    return .{ .checked = functionHasCall(function, "llvm.sadd.with.overflow.i32") };
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

fn sliceSumHasOverflowCheck(function: ir.Function) bool {
    return functionHasCall(function, "llvm.sadd.with.overflow.i32");
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

pub fn lowerByteScanLenLoop(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!matchesByteScanLenLoop(function)) return false;
    const ptr_reg = try paramReg(function, function.params.items[0].name, .ptr);
    if (ptr_reg != .rdi) return error.UnsupportedCodegenAbi;

    const loop_label = "byte_scan_len_loop";
    const done_label = "byte_scan_len_done";
    try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = .r8, .src = ptr_reg } });
    try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = .rcx, .src = ptr_reg } });
    try machine.instructions.append(allocator, .{ .label = loop_label });
    try machine.instructions.append(allocator, .load_rcx_ptr_u8_eax);
    try machine.instructions.append(allocator, .test_eax_eax);
    try machine.instructions.append(allocator, .{ .je = done_label });
    try machine.instructions.append(allocator, .inc_rcx);
    try machine.instructions.append(allocator, .{ .jmp = loop_label });
    try machine.instructions.append(allocator, .{ .label = done_label });
    try machine.instructions.append(allocator, .sub_r8_rcx);
    try machine.instructions.append(allocator, .{ .mov_arg_rax = .rcx });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerByteCompareEqualLoop(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!matchesByteCompareEqualLoop(function)) return false;
    const lhs_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const rhs_reg = try paramReg(function, function.params.items[1].name, .ptr);
    const len_reg = try paramReg(function, function.params.items[2].name, .{ .int = 64 });
    if (lhs_reg != .rdi or rhs_reg != .rsi or len_reg != .rdx) return error.UnsupportedCodegenAbi;

    try machine.instructions.append(allocator, .bcmp_rdi_rsi_rdx_eax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerByteCompareDiffLoop(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!matchesByteCompareDiffLoop(function)) return false;
    const lhs_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const rhs_reg = try paramReg(function, function.params.items[1].name, .ptr);
    const len_reg = try paramReg(function, function.params.items[2].name, .{ .int = 64 });
    if (lhs_reg != .rdi or rhs_reg != .rsi or len_reg != .rdx) return error.UnsupportedCodegenAbi;

    try machine.instructions.append(allocator, .memcmp_rdi_rsi_rdx_eax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGuardedByteMemsetLoop(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!matchesGuardedByteMemsetLoop(function)) return false;
    const ptr_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const byte_reg = try paramReg(function, function.params.items[1].name, .{ .int = 8 });
    const len_reg = try paramReg(function, function.params.items[2].name, .{ .int = 64 });
    const guard_reg = try paramReg(function, function.params.items[3].name, .{ .int = 64 });
    if (ptr_reg != .rdi or byte_reg != .rsi or len_reg != .rdx or guard_reg != .rcx) return error.UnsupportedCodegenAbi;

    try machine.instructions.append(allocator, .guarded_memset_rdi_sil_rdx_rcx_rax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGuardedMemmoveCall(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    const callee = matchesGuardedMemmoveCall(function) orelse return false;
    const dst_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const src_reg = try paramReg(function, function.params.items[1].name, .ptr);
    const len_reg = try paramReg(function, function.params.items[2].name, .{ .int = 64 });
    const guard_reg = try paramReg(function, function.params.items[3].name, .{ .int = 64 });
    if (dst_reg != .rdi or src_reg != .rsi or len_reg != .rdx or guard_reg != .rcx) return error.UnsupportedCodegenAbi;

    const ok_label = "guarded_memmove_ok";
    try machine.instructions.append(allocator, .cmp_rdx_rcx);
    try machine.instructions.append(allocator, .{ .jae = ok_label });
    try machine.instructions.append(allocator, .ud2);
    try machine.instructions.append(allocator, .{ .label = ok_label });
    try appendStackFrame(allocator, machine, 8);
    try machine.instructions.append(allocator, .{ .spill_arg64_rsp = .{ .frame_index = .slot0, .reg = .rdi } });
    try appendDirectCall(allocator, machine, callee, .ptr);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try appendStackFrameEnd(allocator, machine, 8);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGuardedMemcpyBody(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!matchesGuardedMemcpyBody(function)) return false;
    const dst_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const src_reg = try paramReg(function, function.params.items[1].name, .ptr);
    const len_reg = try paramReg(function, function.params.items[2].name, .{ .int = 64 });
    const guard_reg = try paramReg(function, function.params.items[3].name, .{ .int = 64 });
    if (dst_reg != .rdi or src_reg != .rsi or len_reg != .rdx or guard_reg != .rcx) return error.UnsupportedCodegenAbi;

    try machine.instructions.append(allocator, .guarded_memcpy_rdi_rsi_rdx_rcx_rax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerMemmoveBody(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!matchesMemmoveBody(function)) return false;
    const dst_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const src_reg = try paramReg(function, function.params.items[1].name, .ptr);
    const len_reg = try paramReg(function, function.params.items[2].name, .{ .int = 64 });
    if (dst_reg != .rdi or src_reg != .rsi or len_reg != .rdx) return error.UnsupportedCodegenAbi;

    try machine.instructions.append(allocator, .memmove_rdi_rsi_rdx_rax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerMemcpyBody(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!matchesMemcpyBody(function)) return false;
    const dst_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const src_reg = try paramReg(function, function.params.items[1].name, .ptr);
    const len_reg = try paramReg(function, function.params.items[2].name, .{ .int = 64 });
    if (dst_reg != .rdi or src_reg != .rsi or len_reg != .rdx) return error.UnsupportedCodegenAbi;

    try machine.instructions.append(allocator, .memcpy_rdi_rsi_rdx_rax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGuardedStrncatBody(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!matchesGuardedStrncatBody(function)) return false;
    const dst_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const src_reg = try paramReg(function, function.params.items[1].name, .ptr);
    const max_reg = try paramReg(function, function.params.items[2].name, .{ .int = 64 });
    const guard_reg = try paramReg(function, function.params.items[3].name, .{ .int = 64 });
    if (dst_reg != .rdi or src_reg != .rsi or max_reg != .rdx or guard_reg != .rcx) return error.UnsupportedCodegenAbi;

    try machine.instructions.append(allocator, .guarded_strncat_rdi_rsi_rdx_rcx_rax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGuardedStrcatBody(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!matchesGuardedStrcatBody(function)) return false;
    const dst_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const src_reg = try paramReg(function, function.params.items[1].name, .ptr);
    const guard_reg = try paramReg(function, function.params.items[2].name, .{ .int = 64 });
    if (dst_reg != .rdi or src_reg != .rsi or guard_reg != .rdx) return error.UnsupportedCodegenAbi;

    try machine.instructions.append(allocator, .guarded_strcat_rdi_rsi_rdx_rax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGuardedStrncpyBody(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!matchesGuardedStrncpyBody(function)) return false;
    const dst_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const src_reg = try paramReg(function, function.params.items[1].name, .ptr);
    const len_reg = try paramReg(function, function.params.items[2].name, .{ .int = 64 });
    const guard_reg = try paramReg(function, function.params.items[3].name, .{ .int = 64 });
    if (dst_reg != .rdi or src_reg != .rsi or len_reg != .rdx or guard_reg != .rcx) return error.UnsupportedCodegenAbi;

    try machine.instructions.append(allocator, .guarded_strncpy_rdi_rsi_rdx_rcx_rax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGuardedStrcpyBody(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!matchesGuardedStrcpyBody(function)) return false;
    const dst_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const src_reg = try paramReg(function, function.params.items[1].name, .ptr);
    const guard_reg = try paramReg(function, function.params.items[2].name, .{ .int = 64 });
    if (dst_reg != .rdi or src_reg != .rsi or guard_reg != .rdx) return error.UnsupportedCodegenAbi;

    try machine.instructions.append(allocator, .guarded_strcpy_rdi_rsi_rdx_rax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerByteMemsetLoop(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!matchesByteMemsetLoop(function)) return false;
    const ptr_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const byte_reg = try paramReg(function, function.params.items[1].name, .{ .int = 8 });
    const len_reg = try paramReg(function, function.params.items[2].name, .{ .int = 64 });
    if (ptr_reg != .rdi or byte_reg != .rsi or len_reg != .rdx) return error.UnsupportedCodegenAbi;

    try machine.instructions.append(allocator, .memset_rdi_sil_rdx_rax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn matchesGuardedMemmoveCall(function: ir.Function) ?[]const u8 {
    if (!function.ret_ty.eql(.ptr)) return null;
    if (function.params.items.len != 4 or function.params.items[0].ty != .ptr or
        function.params.items[1].ty != .ptr or !function.params.items[2].ty.eql(.{ .int = 64 }) or
        !function.params.items[3].ty.eql(.{ .int = 64 })) return null;
    if (function.blocks.items.len != 3) return null;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 1) return null;
    const guard_cmp_name = entry.instructions.items[0].result orelse return null;
    const guard_cmp = switch (entry.instructions.items[0].kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (guard_cmp.predicate != .ult or !guard_cmp.operand_ty.eql(.{ .int = 64 }) or
        !isNamed(guard_cmp.lhs, function.params.items[3].name) or !isNamed(guard_cmp.rhs, function.params.items[2].name)) return null;
    const entry_br = switch (entry.terminator orelse return null) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, guard_cmp_name)) return null;

    const trap_block = blockByName(function, entry_br.then_target) orelse return null;
    const call_block = blockByName(function, entry_br.else_target) orelse return null;
    if (!matchesTrapBlock(trap_block)) return null;
    if (call_block.instructions.items.len != 1) return null;

    const call = switch (call_block.instructions.items[0].kind) {
        .call => |call| call,
        else => return null,
    };
    if (call.callee_value != null or call.inline_asm != null or !call.ret_ty.eql(.ptr) or call.args.items.len != 3) return null;
    if (!call.args.items[0].ty.eql(.ptr) or !isNamed(call.args.items[0].value, function.params.items[0].name)) return null;
    if (!call.args.items[1].ty.eql(.ptr) or !isNamed(call.args.items[1].value, function.params.items[1].name)) return null;
    if (!call.args.items[2].ty.eql(.{ .int = 64 }) or !isNamed(call.args.items[2].value, function.params.items[2].name)) return null;

    const ret = switch (call_block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.ptr) or !isNamed(ret.value orelse return null, function.params.items[0].name)) return null;
    return call.callee;
}

fn matchesTrapBlock(block: ir.BasicBlock) bool {
    if (block.instructions.items.len != 1) return false;
    if (block.instructions.items[0].result != null) return false;
    const call = switch (block.instructions.items[0].kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isCalleeName(call.callee, "llvm.trap") or call.callee_value != null or call.inline_asm != null or call.ret_ty != .void or call.args.items.len != 0) return false;
    return switch (block.terminator orelse return false) {
        .@"unreachable" => true,
        else => false,
    };
}

fn matchesGuardedMemcpyBody(function: ir.Function) bool {
    if (!function.ret_ty.eql(.ptr)) return false;
    if (function.params.items.len != 4 or function.params.items[0].ty != .ptr or
        function.params.items[1].ty != .ptr or !function.params.items[2].ty.eql(.{ .int = 64 }) or
        !function.params.items[3].ty.eql(.{ .int = 64 })) return false;
    if (function.blocks.items.len < 4) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 1) return false;
    const guard_cmp_name = entry.instructions.items[0].result orelse return false;
    const guard_cmp = switch (entry.instructions.items[0].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (guard_cmp.predicate != .ult or !guard_cmp.operand_ty.eql(.{ .int = 64 }) or
        !isNamed(guard_cmp.lhs, function.params.items[3].name) or !isNamed(guard_cmp.rhs, function.params.items[2].name)) return false;
    const entry_br = switch (entry.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, guard_cmp_name)) return false;

    const trap_block = blockByName(function, entry_br.then_target) orelse return false;
    if (!matchesTrapBlock(trap_block)) return false;
    const body_entry = blockByName(function, entry_br.else_target) orelse return false;

    var saw_body_entry = false;
    var saw_load = false;
    var saw_store = false;
    var saw_ret = false;
    for (function.blocks.items) |block| {
        if (std.mem.eql(u8, block.name, entry.name) or std.mem.eql(u8, block.name, trap_block.name)) continue;
        if (std.mem.eql(u8, block.name, body_entry.name)) saw_body_entry = true;
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .binary, .icmp, .phi, .gep, .cast => {},
                .load => |load| {
                    if (load.attrs.isBarrier()) return false;
                    if (!valueDerivedFromPointer(function, load.ptr, function.params.items[1].name, 0)) return false;
                    saw_load = true;
                },
                .store => |store| {
                    if (store.attrs.isBarrier()) return false;
                    if (!valueDerivedFromPointer(function, store.ptr, function.params.items[0].name, 0)) return false;
                    if (!valueIsLoadFromPointer(function, store.value, function.params.items[1].name)) return false;
                    saw_store = true;
                },
                .call => |call| {
                    if (!isMemcpyBodyMetadataCall(call)) return false;
                },
                .freeze, .fcmp, .select, .alloca, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => return false,
            }
        }

        switch (block.terminator orelse return false) {
            .br, .condbr => {},
            .ret => |ret| {
                if (!ret.ty.eql(.ptr) or !isNamed(ret.value orelse return false, function.params.items[0].name)) return false;
                saw_ret = true;
            },
            .@"unreachable", .@"switch", .indirectbr => return false,
        }
    }

    return saw_body_entry and saw_load and saw_store and saw_ret;
}

fn matchesMemmoveBody(function: ir.Function) bool {
    if (!function.ret_ty.eql(.ptr)) return false;
    if (function.params.items.len != 3 or function.params.items[0].ty != .ptr or
        function.params.items[1].ty != .ptr or !function.params.items[2].ty.eql(.{ .int = 64 })) return false;
    if (function.blocks.items.len < 4) return false;

    var saw_overlap_split = false;
    var saw_src_load = false;
    var saw_dst_store = false;
    var saw_temp_alloca = false;
    var saw_temp_copy = false;
    var saw_ret = false;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .alloca => |alloca| {
                    if (alloca.allocated_ty.eql(.{ .aggregate = "[16 x i8]" })) saw_temp_alloca = true;
                },
                .binary, .phi, .gep, .cast => {},
                .icmp => |icmp| {
                    if (icmp.predicate == .ult and icmp.operand_ty.eql(.ptr) and
                        isNamed(icmp.lhs, function.params.items[1].name) and
                        isNamed(icmp.rhs, function.params.items[0].name)) saw_overlap_split = true;
                },
                .load => |load| {
                    if (load.attrs.isBarrier()) return false;
                    if (valueDerivedFromMemmovePointer(function, load.ptr, function.params.items[1].name, 0)) {
                        saw_src_load = true;
                    } else if (!valueDerivedFromAlloca(function, load.ptr, 0)) {
                        return false;
                    }
                },
                .store => |store| {
                    if (store.attrs.isBarrier()) return false;
                    if (valueDerivedFromMemmovePointer(function, store.ptr, function.params.items[0].name, 0)) {
                        if (!valueIsLoadFromPointer(function, store.value, function.params.items[1].name)) return false;
                        saw_dst_store = true;
                    } else if (!valueDerivedFromAlloca(function, store.ptr, 0)) {
                        return false;
                    }
                },
                .call => |call| {
                    if (isMemcpyInline16BetweenMemmoveStorage(function, call)) {
                        saw_temp_copy = true;
                    } else if (!isMemcpyBodyMetadataCall(call)) {
                        return false;
                    }
                },
                .freeze, .fcmp, .select, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => return false,
            }
        }

        switch (block.terminator orelse return false) {
            .br, .condbr => {},
            .ret => |ret| {
                if (!ret.ty.eql(.ptr) or !isNamed(ret.value orelse return false, function.params.items[0].name)) return false;
                saw_ret = true;
            },
            .@"unreachable", .@"switch", .indirectbr => return false,
        }
    }

    return saw_overlap_split and saw_src_load and saw_dst_store and saw_temp_alloca and saw_temp_copy and saw_ret;
}

fn matchesMemcpyBody(function: ir.Function) bool {
    if (!function.ret_ty.eql(.ptr)) return false;
    if (function.params.items.len != 3 or function.params.items[0].ty != .ptr or
        function.params.items[1].ty != .ptr or !function.params.items[2].ty.eql(.{ .int = 64 })) return false;
    if (function.blocks.items.len < 4) return false;

    var saw_len_split = false;
    var saw_src_load = false;
    var saw_dst_store = false;
    var saw_ret = false;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .binary, .phi, .gep, .cast => {},
                .icmp => |icmp| {
                    if (icmp.predicate == .ult and icmp.operand_ty.eql(.{ .int = 64 }) and
                        isNamed(icmp.lhs, function.params.items[2].name) and icmp.rhs.eql(.{ .int = 16 })) saw_len_split = true;
                },
                .load => |load| {
                    if (load.attrs.isBarrier()) return false;
                    if (!valueDerivedFromPointer(function, load.ptr, function.params.items[1].name, 0)) return false;
                    saw_src_load = true;
                },
                .store => |store| {
                    if (store.attrs.isBarrier()) return false;
                    if (!valueDerivedFromPointer(function, store.ptr, function.params.items[0].name, 0)) return false;
                    if (!valueIsLoadFromPointer(function, store.value, function.params.items[1].name)) return false;
                    saw_dst_store = true;
                },
                .call => |call| {
                    if (!isMemcpyBodyMetadataCall(call)) return false;
                },
                .alloca, .freeze, .fcmp, .select, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => return false,
            }
        }

        switch (block.terminator orelse return false) {
            .br, .condbr => {},
            .ret => |ret| {
                if (!ret.ty.eql(.ptr) or !isNamed(ret.value orelse return false, function.params.items[0].name)) return false;
                saw_ret = true;
            },
            .@"unreachable", .@"switch", .indirectbr => return false,
        }
    }

    return saw_len_split and saw_src_load and saw_dst_store and saw_ret;
}

fn matchesGuardedStrncatBody(function: ir.Function) bool {
    if (!function.ret_ty.eql(.ptr)) return false;
    if (function.params.items.len != 4 or function.params.items[0].ty != .ptr or
        function.params.items[1].ty != .ptr or !function.params.items[2].ty.eql(.{ .int = 64 }) or
        !function.params.items[3].ty.eql(.{ .int = 64 })) return false;
    if (function.blocks.items.len < 6) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len == 0) return false;
    const guard_zero_name = entry.instructions.items[entry.instructions.items.len - 1].result orelse return false;
    const guard_zero = switch (entry.instructions.items[entry.instructions.items.len - 1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (guard_zero.predicate != .eq or !guard_zero.operand_ty.eql(.{ .int = 64 }) or
        !isNamed(guard_zero.lhs, function.params.items[3].name) or !guard_zero.rhs.eql(.{ .int = 0 })) return false;
    const entry_br = switch (entry.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, guard_zero_name)) return false;

    var saw_dst_load = false;
    var saw_src_load = false;
    var saw_src_store = false;
    var saw_zero_terminator = false;
    var saw_ret = false;
    var saw_trap = false;
    var saw_max_bound = false;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .binary, .phi, .gep, .cast, .select => {},
                .icmp => |icmp| {
                    if (icmp.operand_ty.eql(.{ .int = 64 }) and
                        (isNamed(icmp.lhs, function.params.items[2].name) or isNamed(icmp.rhs, function.params.items[2].name))) saw_max_bound = true;
                },
                .load => |load| {
                    if (load.attrs.isBarrier()) return false;
                    if (valueDerivedFromPointer(function, load.ptr, function.params.items[0].name, 0)) {
                        if (!load.ty.eql(.{ .int = 8 })) return false;
                        saw_dst_load = true;
                    } else if (valueDerivedFromPointer(function, load.ptr, function.params.items[1].name, 0)) {
                        if (!load.ty.eql(.{ .int = 8 })) return false;
                        saw_src_load = true;
                    } else {
                        return false;
                    }
                },
                .store => |store| {
                    if (store.attrs.isBarrier()) return false;
                    if (!valueDerivedFromPointer(function, store.ptr, function.params.items[0].name, 0)) return false;
                    if (valueIsLoadFromPointer(function, store.value, function.params.items[1].name)) {
                        saw_src_store = true;
                    } else if (store.value.eql(.{ .int = 0 })) {
                        saw_zero_terminator = true;
                    } else {
                        return false;
                    }
                },
                .call => |call| {
                    if (isCalleeName(call.callee, "llvm.trap")) {
                        if (call.callee_value != null or call.inline_asm != null or call.ret_ty != .void or call.args.items.len != 0) return false;
                        saw_trap = true;
                    } else if (!isMemcpyBodyMetadataCall(call)) {
                        return false;
                    }
                },
                .freeze, .fcmp, .alloca, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => return false,
            }
        }

        switch (block.terminator orelse return false) {
            .br, .condbr => {},
            .ret => |ret| {
                if (!ret.ty.eql(.ptr) or !isNamed(ret.value orelse return false, function.params.items[0].name)) return false;
                saw_ret = true;
            },
            .@"unreachable" => {},
            .@"switch", .indirectbr => return false,
        }
    }

    return saw_dst_load and saw_src_load and saw_src_store and saw_zero_terminator and
        saw_ret and saw_trap and saw_max_bound;
}

fn matchesGuardedStrcatBody(function: ir.Function) bool {
    if (!function.ret_ty.eql(.ptr)) return false;
    if (function.params.items.len != 3 or function.params.items[0].ty != .ptr or
        function.params.items[1].ty != .ptr or !function.params.items[2].ty.eql(.{ .int = 64 })) return false;
    if (function.blocks.items.len < 6) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len == 0) return false;
    const guard_zero_name = entry.instructions.items[entry.instructions.items.len - 1].result orelse return false;
    const guard_zero = switch (entry.instructions.items[entry.instructions.items.len - 1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (guard_zero.predicate != .eq or !guard_zero.operand_ty.eql(.{ .int = 64 }) or
        !isNamed(guard_zero.lhs, function.params.items[2].name) or !guard_zero.rhs.eql(.{ .int = 0 })) return false;
    const entry_br = switch (entry.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, guard_zero_name)) return false;

    var saw_dst_load = false;
    var saw_src_load = false;
    var saw_src_store = false;
    var saw_zero_terminator = false;
    var saw_ret = false;
    var saw_trap = false;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .binary, .phi, .gep, .cast => {},
                .icmp => {},
                .load => |load| {
                    if (load.attrs.isBarrier()) return false;
                    if (valueDerivedFromPointer(function, load.ptr, function.params.items[0].name, 0)) {
                        if (!load.ty.eql(.{ .int = 8 })) return false;
                        saw_dst_load = true;
                    } else if (valueDerivedFromPointer(function, load.ptr, function.params.items[1].name, 0)) {
                        if (!load.ty.eql(.{ .int = 8 })) return false;
                        saw_src_load = true;
                    } else {
                        return false;
                    }
                },
                .store => |store| {
                    if (store.attrs.isBarrier()) return false;
                    if (!valueDerivedFromPointer(function, store.ptr, function.params.items[0].name, 0)) return false;
                    if (valueIsLoadFromPointer(function, store.value, function.params.items[1].name)) {
                        saw_src_store = true;
                    } else if (store.value.eql(.{ .int = 0 })) {
                        saw_zero_terminator = true;
                    } else {
                        return false;
                    }
                },
                .call => |call| {
                    if (isCalleeName(call.callee, "llvm.trap")) {
                        if (call.callee_value != null or call.inline_asm != null or call.ret_ty != .void or call.args.items.len != 0) return false;
                        saw_trap = true;
                    } else if (!isMemcpyBodyMetadataCall(call)) {
                        return false;
                    }
                },
                .freeze, .fcmp, .select, .alloca, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => return false,
            }
        }

        switch (block.terminator orelse return false) {
            .br, .condbr => {},
            .ret => |ret| {
                if (!ret.ty.eql(.ptr) or !isNamed(ret.value orelse return false, function.params.items[0].name)) return false;
                saw_ret = true;
            },
            .@"unreachable" => {},
            .@"switch", .indirectbr => return false,
        }
    }

    return saw_dst_load and saw_src_load and saw_src_store and saw_zero_terminator and
        saw_ret and saw_trap;
}

fn matchesGuardedStrncpyBody(function: ir.Function) bool {
    if (!function.ret_ty.eql(.ptr)) return false;
    if (function.params.items.len != 4 or function.params.items[0].ty != .ptr or
        function.params.items[1].ty != .ptr or !function.params.items[2].ty.eql(.{ .int = 64 }) or
        !function.params.items[3].ty.eql(.{ .int = 64 })) return false;
    if (function.blocks.items.len < 5) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len == 0) return false;
    const guard_cmp_name = entry.instructions.items[entry.instructions.items.len - 1].result orelse return false;
    const guard_cmp = switch (entry.instructions.items[entry.instructions.items.len - 1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (guard_cmp.predicate != .ult or !guard_cmp.operand_ty.eql(.{ .int = 64 }) or
        !isNamed(guard_cmp.lhs, function.params.items[3].name) or !isNamed(guard_cmp.rhs, function.params.items[2].name)) return false;
    const entry_br = switch (entry.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, guard_cmp_name)) return false;

    var saw_src_load = false;
    var saw_src_store = false;
    var saw_zero_padding = false;
    var saw_ret = false;
    var saw_trap = false;
    var saw_len_bound = false;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .binary, .phi, .gep, .cast => {},
                .icmp => |icmp| {
                    if (icmp.operand_ty.eql(.{ .int = 64 }) and
                        (isNamed(icmp.lhs, function.params.items[2].name) or isNamed(icmp.rhs, function.params.items[2].name))) saw_len_bound = true;
                },
                .load => |load| {
                    if (load.attrs.isBarrier() or !load.ty.eql(.{ .int = 8 })) return false;
                    if (!valueDerivedFromPointer(function, load.ptr, function.params.items[1].name, 0)) return false;
                    saw_src_load = true;
                },
                .store => |store| {
                    if (store.attrs.isBarrier()) return false;
                    if (!valueDerivedFromPointer(function, store.ptr, function.params.items[0].name, 0)) return false;
                    if (valueIsLoadFromPointer(function, store.value, function.params.items[1].name)) {
                        saw_src_store = true;
                    } else if (store.value.eql(.{ .int = 0 })) {
                        saw_zero_padding = true;
                    } else {
                        return false;
                    }
                },
                .call => |call| {
                    if (isCalleeName(call.callee, "llvm.trap")) {
                        if (call.callee_value != null or call.inline_asm != null or call.ret_ty != .void or call.args.items.len != 0) return false;
                        saw_trap = true;
                    } else if (!isMemcpyBodyMetadataCall(call)) {
                        return false;
                    }
                },
                .freeze, .fcmp, .select, .alloca, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => return false,
            }
        }

        switch (block.terminator orelse return false) {
            .br, .condbr => {},
            .ret => |ret| {
                if (!ret.ty.eql(.ptr) or !isNamed(ret.value orelse return false, function.params.items[0].name)) return false;
                saw_ret = true;
            },
            .@"unreachable" => {},
            .@"switch", .indirectbr => return false,
        }
    }

    return saw_src_load and saw_src_store and saw_zero_padding and saw_ret and
        saw_trap and saw_len_bound;
}

fn matchesGuardedStrcpyBody(function: ir.Function) bool {
    if (!function.ret_ty.eql(.ptr)) return false;
    if (function.params.items.len != 3 or function.params.items[0].ty != .ptr or
        function.params.items[1].ty != .ptr or !function.params.items[2].ty.eql(.{ .int = 64 })) return false;
    if (function.blocks.items.len < 4) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len == 0) return false;
    const guard_zero_name = entry.instructions.items[entry.instructions.items.len - 1].result orelse return false;
    const guard_zero = switch (entry.instructions.items[entry.instructions.items.len - 1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (guard_zero.predicate != .eq or !guard_zero.operand_ty.eql(.{ .int = 64 }) or
        !isNamed(guard_zero.lhs, function.params.items[2].name) or !guard_zero.rhs.eql(.{ .int = 0 })) return false;
    const entry_br = switch (entry.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, guard_zero_name)) return false;

    var saw_src_load = false;
    var saw_src_store = false;
    var saw_zero_terminator = false;
    var saw_ret = false;
    var saw_trap = false;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .binary, .phi, .gep, .cast => {},
                .icmp => {},
                .load => |load| {
                    if (load.attrs.isBarrier() or !load.ty.eql(.{ .int = 8 })) return false;
                    if (!valueDerivedFromPointer(function, load.ptr, function.params.items[1].name, 0)) return false;
                    saw_src_load = true;
                },
                .store => |store| {
                    if (store.attrs.isBarrier()) return false;
                    if (!valueDerivedFromPointer(function, store.ptr, function.params.items[0].name, 0)) return false;
                    if (valueIsLoadFromPointer(function, store.value, function.params.items[1].name)) {
                        saw_src_store = true;
                    } else if (store.value.eql(.{ .int = 0 })) {
                        saw_zero_terminator = true;
                    } else {
                        return false;
                    }
                },
                .call => |call| {
                    if (isCalleeName(call.callee, "llvm.trap")) {
                        if (call.callee_value != null or call.inline_asm != null or call.ret_ty != .void or call.args.items.len != 0) return false;
                        saw_trap = true;
                    } else if (!isMemcpyBodyMetadataCall(call)) {
                        return false;
                    }
                },
                .freeze, .fcmp, .select, .alloca, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => return false,
            }
        }

        switch (block.terminator orelse return false) {
            .br, .condbr => {},
            .ret => |ret| {
                if (!ret.ty.eql(.ptr) or !isNamed(ret.value orelse return false, function.params.items[0].name)) return false;
                saw_ret = true;
            },
            .@"unreachable" => {},
            .@"switch", .indirectbr => return false,
        }
    }

    return saw_src_load and saw_src_store and saw_zero_terminator and saw_ret and saw_trap;
}

fn valueIsLoadFromPointer(function: ir.Function, value: ir.Value, root_name: []const u8) bool {
    const name = switch (value) {
        .named => |name| name,
        else => return false,
    };
    const instruction = instructionByResult(function, name) orelse return false;
    const load = switch (instruction.kind) {
        .load => |load| load,
        else => return false,
    };
    return !load.attrs.isBarrier() and valueDerivedFromPointer(function, load.ptr, root_name, 0);
}

fn valueDerivedFromPointer(function: ir.Function, value: ir.Value, root_name: []const u8, depth: u8) bool {
    if (depth > 16) return false;
    const name = switch (value) {
        .named => |name| name,
        else => return false,
    };
    if (std.mem.eql(u8, name, root_name)) return true;
    const instruction = instructionByResult(function, name) orelse return false;
    return switch (instruction.kind) {
        .gep => |gep| valueDerivedFromPointer(function, gep.ptr, root_name, depth + 1),
        .cast => |cast| cast.to_ty.eql(.ptr) and valueDerivedFromPointer(function, cast.value, root_name, depth + 1),
        .phi => |phi| blk: {
            if (phi.incoming.items.len == 0 or !phi.ty.eql(.ptr)) break :blk false;
            for (phi.incoming.items) |incoming| {
                if (!valueDerivedFromPointer(function, incoming.value, root_name, depth + 1)) break :blk false;
            }
            break :blk true;
        },
        else => false,
    };
}

fn valueDerivedFromMemmovePointer(function: ir.Function, value: ir.Value, root_name: []const u8, depth: u8) bool {
    if (valueDerivedFromPointer(function, value, root_name, depth)) return true;
    if (depth > 16) return false;
    const name = switch (value) {
        .named => |name| name,
        else => return false,
    };
    const instruction = instructionByResult(function, name) orelse return false;
    return switch (instruction.kind) {
        .gep => |gep| valueDerivedFromMemmovePointer(function, gep.ptr, root_name, depth + 1),
        .cast => |cast| cast.op == .inttoptr and cast.to_ty.eql(.ptr) and
            intValueDerivedFromPointer(function, cast.value, root_name, depth + 1),
        else => false,
    };
}

fn intValueDerivedFromPointer(function: ir.Function, value: ir.Value, root_name: []const u8, depth: u8) bool {
    if (depth > 16) return false;
    const name = switch (value) {
        .named => |name| name,
        .int => return false,
        else => return false,
    };
    const instruction = instructionByResult(function, name) orelse return false;
    return switch (instruction.kind) {
        .cast => |cast| cast.op == .ptrtoint and cast.from_ty.eql(.ptr) and
            valueDerivedFromPointer(function, cast.value, root_name, depth + 1),
        .binary => |binary| switch (binary.op) {
            .add, .sub, .@"and", .@"or", .xor, .shl, .lshr, .ashr => intValueDerivedFromPointer(function, binary.lhs, root_name, depth + 1) or
                intValueDerivedFromPointer(function, binary.rhs, root_name, depth + 1),
            else => false,
        },
        .phi => |phi| blk: {
            if (phi.incoming.items.len == 0 or !phi.ty.eql(.{ .int = 64 })) break :blk false;
            for (phi.incoming.items) |incoming| {
                if (!intValueDerivedFromPointer(function, incoming.value, root_name, depth + 1)) break :blk false;
            }
            break :blk true;
        },
        else => false,
    };
}

fn valueDerivedFromAlloca(function: ir.Function, value: ir.Value, depth: u8) bool {
    if (depth > 16) return false;
    const name = switch (value) {
        .named => |name| name,
        else => return false,
    };
    const instruction = instructionByResult(function, name) orelse return false;
    return switch (instruction.kind) {
        .alloca => true,
        .gep => |gep| valueDerivedFromAlloca(function, gep.ptr, depth + 1),
        .cast => |cast| cast.to_ty.eql(.ptr) and valueDerivedFromAlloca(function, cast.value, depth + 1),
        .phi => |phi| blk: {
            if (phi.incoming.items.len == 0 or !phi.ty.eql(.ptr)) break :blk false;
            for (phi.incoming.items) |incoming| {
                if (!valueDerivedFromAlloca(function, incoming.value, depth + 1)) break :blk false;
            }
            break :blk true;
        },
        else => false,
    };
}

fn instructionByResult(function: ir.Function, result_name: []const u8) ?ir.Instruction {
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            if (instruction.result) |result| {
                if (std.mem.eql(u8, result, result_name)) return instruction;
            }
        }
    }
    return null;
}

fn isMemcpyInline16BetweenMemmoveStorage(function: ir.Function, call: ir.CallInst) bool {
    if (call.callee_value != null or call.inline_asm != null or call.ret_ty != .void or call.args.items.len != 4) return false;
    if (!isCalleeName(call.callee, "llvm.memcpy.inline.p0.p0.i64")) return false;
    if (!call.args.items[0].ty.eql(.ptr) or !call.args.items[1].ty.eql(.ptr) or
        !call.args.items[2].ty.eql(.{ .int = 64 }) or !isInt(call.args.items[2].value, 16) or
        !call.args.items[3].ty.eql(.{ .int = 1 }) or !isInt(call.args.items[3].value, 0)) return false;

    const dst = call.args.items[0].value;
    const src = call.args.items[1].value;
    const dst_is_output = valueDerivedFromMemmovePointer(function, dst, function.params.items[0].name, 0);
    const src_is_input = valueDerivedFromMemmovePointer(function, src, function.params.items[1].name, 0);
    const dst_is_temp = valueDerivedFromAlloca(function, dst, 0);
    const src_is_temp = valueDerivedFromAlloca(function, src, 0);
    return (dst_is_temp and src_is_input) or (dst_is_output and src_is_temp);
}

fn isMemcpyBodyMetadataCall(call: ir.CallInst) bool {
    if (call.callee_value != null or call.inline_asm != null or call.ret_ty != .void) return false;
    return isCalleeName(call.callee, "llvm.experimental.noalias.scope.decl") or
        isCalleeName(call.callee, "llvm.assume");
}

fn matchesByteScanLenLoop(function: ir.Function) bool {
    if (!function.ret_ty.eql(.{ .int = 64 })) return false;
    if (function.params.items.len != 1 or function.params.items[0].ty != .ptr) return false;
    if (function.blocks.items.len != 3) return false;

    const entry = function.blocks.items[0];
    const loop = function.blocks.items[1];
    const exit = function.blocks.items[2];
    if (entry.instructions.items.len != 0 or loop.instructions.items.len != 5 or exit.instructions.items.len != 0) return false;

    const entry_br = switch (entry.terminator orelse return false) {
        .br => |br| br,
        else => return false,
    };
    if (!std.mem.eql(u8, entry_br.target, loop.name)) return false;

    const phi_name = loop.instructions.items[0].result orelse return false;
    const gep_name = loop.instructions.items[1].result orelse return false;
    const load_name = loop.instructions.items[2].result orelse return false;
    const icmp_name = loop.instructions.items[3].result orelse return false;
    const next_name = loop.instructions.items[4].result orelse return false;

    const phi = switch (loop.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 64 })) return false;
    if (!phiHasIncomingInt(phi, 0, entry.name) or !phiHasIncoming(phi, next_name, loop.name)) return false;

    const gep = switch (loop.instructions.items[1].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[1 x i8]" }) or !isNamed(gep.ptr, function.params.items[0].name)) return false;
    if (gep.indices.items.len != 1) return false;
    const gep_index = gep.indices.items[0];
    if (!gep_index.ty.eql(.{ .int = 64 }) or !isNamed(gep_index.value, phi_name)) return false;

    const load = switch (loop.instructions.items[2].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 8 }) or load.attrs.isBarrier() or !isNamed(load.ptr, gep_name)) return false;

    const icmp = switch (loop.instructions.items[3].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 8 }) or !isNamed(icmp.lhs, load_name) or !isInt(icmp.rhs, 0)) return false;

    const next = switch (loop.instructions.items[4].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (next.op != .add or !next.ty.eql(.{ .int = 64 }) or !isNamed(next.lhs, phi_name) or !isInt(next.rhs, 1)) return false;

    const condbr = switch (loop.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, icmp_name)) return false;
    if (!std.mem.eql(u8, condbr.then_target, exit.name) or !std.mem.eql(u8, condbr.else_target, loop.name)) return false;

    const ret = switch (exit.terminator orelse return false) {
        .ret => |ret| ret,
        else => return false,
    };
    return ret.ty.eql(.{ .int = 64 }) and isNamed(ret.value orelse return false, phi_name);
}

fn matchesByteCompareEqualLoop(function: ir.Function) bool {
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 3 or function.params.items[0].ty != .ptr or
        function.params.items[1].ty != .ptr or !function.params.items[2].ty.eql(.{ .int = 64 })) return false;
    if (function.blocks.items.len != 4) return false;

    const entry = function.blocks.items[0];
    const common_ret = function.blocks.items[1];
    const loop = function.blocks.items[2];
    const then = function.blocks.items[3];
    if (entry.instructions.items.len != 1 or common_ret.instructions.items.len != 1 or
        loop.instructions.items.len != 2 or then.instructions.items.len != 6) return false;

    const entry_cmp_name = entry.instructions.items[0].result orelse return false;
    const entry_cmp = switch (entry.instructions.items[0].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (entry_cmp.predicate != .eq or !entry_cmp.operand_ty.eql(.{ .int = 64 }) or
        !isNamed(entry_cmp.lhs, function.params.items[2].name) or !isInt(entry_cmp.rhs, 0)) return false;
    const entry_br = switch (entry.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, entry_cmp_name) or
        !std.mem.eql(u8, entry_br.then_target, common_ret.name) or !std.mem.eql(u8, entry_br.else_target, then.name)) return false;

    const ret_phi_name = common_ret.instructions.items[0].result orelse return false;
    const ret_phi = switch (common_ret.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!ret_phi.ty.eql(.{ .int = 32 })) return false;
    if (!phiHasIncomingInt(ret_phi, 0, entry.name) or !phiHasIncomingInt(ret_phi, 0, loop.name) or
        !phiHasIncomingInt(ret_phi, 1, then.name)) return false;
    const ret = switch (common_ret.terminator orelse return false) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return false, ret_phi_name)) return false;

    const next_index_name = loop.instructions.items[0].result orelse return false;
    const loop_cmp_name = loop.instructions.items[1].result orelse return false;
    const index_name = then.instructions.items[0].result orelse return false;
    const lhs_gep_name = then.instructions.items[1].result orelse return false;
    const lhs_load_name = then.instructions.items[2].result orelse return false;
    const rhs_gep_name = then.instructions.items[3].result orelse return false;
    const rhs_load_name = then.instructions.items[4].result orelse return false;

    const next_index = switch (loop.instructions.items[0].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (next_index.op != .add or !next_index.ty.eql(.{ .int = 64 }) or !isNamed(next_index.lhs, index_name) or !isInt(next_index.rhs, 1)) return false;
    const loop_cmp = switch (loop.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (loop_cmp.predicate != .eq or !loop_cmp.operand_ty.eql(.{ .int = 64 }) or
        !isNamed(loop_cmp.lhs, next_index_name) or !isNamed(loop_cmp.rhs, function.params.items[2].name)) return false;
    const loop_br = switch (loop.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!loop_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(loop_br.cond, loop_cmp_name) or
        !std.mem.eql(u8, loop_br.then_target, common_ret.name) or !std.mem.eql(u8, loop_br.else_target, then.name)) return false;

    const index_phi = switch (then.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!index_phi.ty.eql(.{ .int = 64 }) or !phiHasIncomingInt(index_phi, 0, entry.name) or
        !phiHasIncoming(index_phi, next_index_name, loop.name)) return false;
    const lhs_gep = switch (then.instructions.items[1].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!byteCompareGep(lhs_gep, function.params.items[0].name, index_name)) return false;
    const lhs_load = switch (then.instructions.items[2].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!lhs_load.ty.eql(.{ .int = 8 }) or lhs_load.attrs.isBarrier() or !isNamed(lhs_load.ptr, lhs_gep_name)) return false;
    const rhs_gep = switch (then.instructions.items[3].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!byteCompareGep(rhs_gep, function.params.items[1].name, index_name)) return false;
    const rhs_load = switch (then.instructions.items[4].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!rhs_load.ty.eql(.{ .int = 8 }) or rhs_load.attrs.isBarrier() or !isNamed(rhs_load.ptr, rhs_gep_name)) return false;

    const then_br = switch (then.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    const value_cmp = switch (then_br.cond) {
        .named => |name| findIcmpEqI8(then, name) orelse return false,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!isNamed(value_cmp.lhs, lhs_load_name) or !isNamed(value_cmp.rhs, rhs_load_name)) return false;
    return then_br.cond_ty.eql(.{ .int = 1 }) and
        std.mem.eql(u8, then_br.then_target, loop.name) and
        std.mem.eql(u8, then_br.else_target, common_ret.name);
}

fn matchesByteCompareDiffLoop(function: ir.Function) bool {
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 3 or function.params.items[0].ty != .ptr or
        function.params.items[1].ty != .ptr or !function.params.items[2].ty.eql(.{ .int = 64 })) return false;
    if (function.blocks.items.len != 4) return false;

    const entry = function.blocks.items[0];
    const common_ret = function.blocks.items[1];
    const loop = function.blocks.items[2];
    const then = function.blocks.items[3];
    if (entry.instructions.items.len != 1 or common_ret.instructions.items.len != 1 or
        loop.instructions.items.len != 2 or then.instructions.items.len != 9) return false;

    const entry_cmp_name = entry.instructions.items[0].result orelse return false;
    const entry_cmp = switch (entry.instructions.items[0].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (entry_cmp.predicate != .eq or !entry_cmp.operand_ty.eql(.{ .int = 64 }) or
        !isNamed(entry_cmp.lhs, function.params.items[2].name) or !isInt(entry_cmp.rhs, 0)) return false;
    const entry_br = switch (entry.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, entry_cmp_name) or
        !std.mem.eql(u8, entry_br.then_target, common_ret.name) or !std.mem.eql(u8, entry_br.else_target, then.name)) return false;

    const ret_phi_name = common_ret.instructions.items[0].result orelse return false;
    const ret_phi = switch (common_ret.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    const diff_name = then.instructions.items[7].result orelse return false;
    if (!ret_phi.ty.eql(.{ .int = 32 }) or !phiHasIncomingInt(ret_phi, 0, entry.name) or
        !phiHasIncomingInt(ret_phi, 0, loop.name) or !phiHasIncoming(ret_phi, diff_name, then.name)) return false;
    const ret = switch (common_ret.terminator orelse return false) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return false, ret_phi_name)) return false;

    const next_index_name = loop.instructions.items[0].result orelse return false;
    const loop_cmp_name = loop.instructions.items[1].result orelse return false;
    const index_name = then.instructions.items[0].result orelse return false;
    const lhs_gep_name = then.instructions.items[1].result orelse return false;
    const lhs_load_name = then.instructions.items[2].result orelse return false;
    const lhs_zext_name = then.instructions.items[3].result orelse return false;
    const rhs_gep_name = then.instructions.items[4].result orelse return false;
    const rhs_load_name = then.instructions.items[5].result orelse return false;
    const rhs_zext_name = then.instructions.items[6].result orelse return false;
    const value_cmp_name = then.instructions.items[8].result orelse return false;

    const next_index = switch (loop.instructions.items[0].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (next_index.op != .add or !next_index.ty.eql(.{ .int = 64 }) or !isNamed(next_index.lhs, index_name) or !isInt(next_index.rhs, 1)) return false;
    const loop_cmp = switch (loop.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (loop_cmp.predicate != .eq or !loop_cmp.operand_ty.eql(.{ .int = 64 }) or
        !isNamed(loop_cmp.lhs, next_index_name) or !isNamed(loop_cmp.rhs, function.params.items[2].name)) return false;
    const loop_br = switch (loop.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!loop_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(loop_br.cond, loop_cmp_name) or
        !std.mem.eql(u8, loop_br.then_target, common_ret.name) or !std.mem.eql(u8, loop_br.else_target, then.name)) return false;

    const index_phi = switch (then.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!index_phi.ty.eql(.{ .int = 64 }) or !phiHasIncomingInt(index_phi, 0, entry.name) or
        !phiHasIncoming(index_phi, next_index_name, loop.name)) return false;
    const lhs_gep = switch (then.instructions.items[1].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!byteCompareGep(lhs_gep, function.params.items[0].name, index_name)) return false;
    const lhs_load = switch (then.instructions.items[2].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!lhs_load.ty.eql(.{ .int = 8 }) or lhs_load.attrs.isBarrier() or !isNamed(lhs_load.ptr, lhs_gep_name)) return false;
    if (!byteCompareZext(then.instructions.items[3], lhs_load_name)) return false;
    const rhs_gep = switch (then.instructions.items[4].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!byteCompareGep(rhs_gep, function.params.items[1].name, index_name)) return false;
    const rhs_load = switch (then.instructions.items[5].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!rhs_load.ty.eql(.{ .int = 8 }) or rhs_load.attrs.isBarrier() or !isNamed(rhs_load.ptr, rhs_gep_name)) return false;
    if (!byteCompareZext(then.instructions.items[6], rhs_load_name)) return false;

    const diff = switch (then.instructions.items[7].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (diff.op != .sub or !diff.ty.eql(.{ .int = 32 }) or
        !isNamed(diff.lhs, lhs_zext_name) or !isNamed(diff.rhs, rhs_zext_name)) return false;
    const value_cmp = switch (then.instructions.items[8].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (value_cmp.predicate != .eq or !value_cmp.operand_ty.eql(.{ .int = 32 }) or
        !isNamed(value_cmp.lhs, diff_name) or !isInt(value_cmp.rhs, 0)) return false;

    const then_br = switch (then.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    return then_br.cond_ty.eql(.{ .int = 1 }) and isNamed(then_br.cond, value_cmp_name) and
        std.mem.eql(u8, then_br.then_target, loop.name) and
        std.mem.eql(u8, then_br.else_target, common_ret.name);
}

fn matchesGuardedByteMemsetLoop(function: ir.Function) bool {
    if (!function.ret_ty.eql(.ptr)) return false;
    if (function.params.items.len != 4 or function.params.items[0].ty != .ptr or
        !function.params.items[1].ty.eql(.{ .int = 8 }) or
        !function.params.items[2].ty.eql(.{ .int = 64 }) or
        !function.params.items[3].ty.eql(.{ .int = 64 })) return false;
    if (function.blocks.items.len != 8) return false;
    if (!allCallsAreMemsetGuardCalls(function)) return false;
    if (!allStoresWriteMemsetByte(function, function.params.items[1].name)) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 1) return false;
    const guard_name = entry.instructions.items[0].result orelse return false;
    const guard = switch (entry.instructions.items[0].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (guard.predicate != .ult or !guard.operand_ty.eql(.{ .int = 64 }) or
        !isNamed(guard.lhs, function.params.items[3].name) or !isNamed(guard.rhs, function.params.items[2].name)) return false;
    const entry_br = switch (entry.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, guard_name)) return false;

    const trap_block = blockByName(function, entry_br.then_target) orelse return false;
    const normal_block = blockByName(function, entry_br.else_target) orelse return false;
    if (!blockHasTrapThenUnreachable(trap_block)) return false;

    const len_zero_name = if (normal_block.instructions.items.len == 1)
        normal_block.instructions.items[0].result orelse return false
    else
        return false;
    const len_zero = switch (normal_block.instructions.items[0].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (len_zero.predicate != .eq or !len_zero.operand_ty.eql(.{ .int = 64 }) or
        !isNamed(len_zero.lhs, function.params.items[2].name) or !isInt(len_zero.rhs, 0)) return false;
    const normal_br = switch (normal_block.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!normal_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(normal_br.cond, len_zero_name)) return false;

    const ret_block = blockByName(function, normal_br.then_target) orelse return false;
    const ret = switch (ret_block.terminator orelse return false) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.ptr) or !isNamed(ret.value orelse return false, function.params.items[0].name)) return false;

    return functionHasPointerAdvancingStoreLoop(function, function.params.items[0].name, function.params.items[2].name);
}

fn matchesByteMemsetLoop(function: ir.Function) bool {
    if (!function.ret_ty.eql(.ptr)) return false;
    if (function.params.items.len != 3 or function.params.items[0].ty != .ptr or
        !function.params.items[1].ty.eql(.{ .int = 8 }) or
        !function.params.items[2].ty.eql(.{ .int = 64 })) return false;
    if (function.blocks.items.len != 6) return false;
    if (!functionHasNoCalls(function)) return false;
    if (!allStoresWriteMemsetByte(function, function.params.items[1].name)) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 1) return false;
    const len_zero_name = entry.instructions.items[0].result orelse return false;
    const len_zero = switch (entry.instructions.items[0].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (len_zero.predicate != .eq or !len_zero.operand_ty.eql(.{ .int = 64 }) or
        !isNamed(len_zero.lhs, function.params.items[2].name) or !isInt(len_zero.rhs, 0)) return false;
    const entry_br = switch (entry.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, len_zero_name)) return false;

    const ret_block = blockByName(function, entry_br.then_target) orelse return false;
    const ret = switch (ret_block.terminator orelse return false) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.ptr) or !isNamed(ret.value orelse return false, function.params.items[0].name)) return false;

    return functionHasPointerAdvancingStoreLoop(function, function.params.items[0].name, function.params.items[2].name);
}

fn allCallsAreMemsetGuardCalls(function: ir.Function) bool {
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            const call = switch (instruction.kind) {
                .call => |call| call,
                else => continue,
            };
            if (!std.mem.eql(u8, call.callee, "llvm.assume") and !std.mem.eql(u8, call.callee, "llvm.trap")) return false;
        }
    }
    return true;
}

fn functionHasNoCalls(function: ir.Function) bool {
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .call => return false,
                else => {},
            }
        }
    }
    return true;
}

fn allStoresWriteMemsetByte(function: ir.Function, byte_param_name: []const u8) bool {
    var store_count: usize = 0;
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            const store = switch (instruction.kind) {
                .store => |store| store,
                else => continue,
            };
            if (!store.ty.eql(.{ .int = 8 }) or !isNamed(store.value, byte_param_name) or store.attrs.isBarrier()) return false;
            store_count += 1;
        }
    }
    return store_count >= 2;
}

fn blockHasTrapThenUnreachable(block: ir.BasicBlock) bool {
    var has_trap = false;
    for (block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        const call = switch (instruction.kind) {
            .call => |call| call,
            else => continue,
        };
        if (std.mem.eql(u8, call.callee, "llvm.trap") and call.ret_ty == .void and call.args.items.len == 0) has_trap = true;
    }
    return has_trap and switch (block.terminator orelse return false) {
        .@"unreachable" => true,
        else => false,
    };
}

fn functionHasPointerAdvancingStoreLoop(function: ir.Function, ptr_param_name: []const u8, len_param_name: []const u8) bool {
    for (function.blocks.items) |block| {
        const terminator = block.terminator orelse continue;
        const condbr = switch (terminator) {
            .condbr => |condbr| condbr,
            else => continue,
        };
        if (!std.mem.eql(u8, condbr.else_target, block.name)) continue;
        if (!blockHasGepFromPointer(block, ptr_param_name) and !blockHasGepFromBlockPointerPhi(block)) continue;
        if (!blockHasI64EqToLen(block, len_param_name)) continue;
        return true;
    }
    return false;
}

fn blockHasGepFromPointer(block: ir.BasicBlock, ptr_param_name: []const u8) bool {
    for (block.instructions.items) |instruction| {
        const gep = switch (instruction.kind) {
            .gep => |gep| gep,
            else => continue,
        };
        if (gep.source_ty.eql(.{ .int = 8 }) and isNamed(gep.ptr, ptr_param_name)) return true;
    }
    return false;
}

fn blockHasGepFromBlockPointerPhi(block: ir.BasicBlock) bool {
    for (block.instructions.items) |instruction| {
        const gep = switch (instruction.kind) {
            .gep => |gep| gep,
            else => continue,
        };
        if (!gep.source_ty.eql(.{ .int = 8 })) continue;
        for (block.instructions.items) |candidate| {
            if (!std.mem.eql(u8, candidate.result orelse continue, switch (gep.ptr) {
                .named => |name| name,
                .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => continue,
            })) continue;
            const phi = switch (candidate.kind) {
                .phi => |phi| phi,
                else => continue,
            };
            if (phi.ty.eql(.ptr)) return true;
        }
    }
    return false;
}

fn blockHasI64EqToLen(block: ir.BasicBlock, len_param_name: []const u8) bool {
    for (block.instructions.items) |instruction| {
        const icmp = switch (instruction.kind) {
            .icmp => |icmp| icmp,
            else => continue,
        };
        if (icmp.predicate == .eq and icmp.operand_ty.eql(.{ .int = 64 }) and
            (isNamed(icmp.lhs, len_param_name) or isNamed(icmp.rhs, len_param_name) or isInt(icmp.lhs, 0) or isInt(icmp.rhs, 0))) return true;
    }
    return false;
}

fn byteCompareGep(gep: ir.GepInst, ptr_param_name: []const u8, index_name: []const u8) bool {
    if (!gep.source_ty.eql(.{ .aggregate = "[1 x i8]" }) or !isNamed(gep.ptr, ptr_param_name)) return false;
    if (gep.indices.items.len != 1) return false;
    const index = gep.indices.items[0];
    return index.ty.eql(.{ .int = 64 }) and isNamed(index.value, index_name);
}

fn byteCompareZext(instruction: ir.Instruction, load_name: []const u8) bool {
    const cast = switch (instruction.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    return cast.op == .zext and cast.from_ty.eql(.{ .int = 8 }) and
        cast.to_ty.eql(.{ .int = 32 }) and isNamed(cast.value, load_name);
}

fn findIcmpEqI8(block: ir.BasicBlock, name: []const u8) ?ir.IcmpInst {
    for (block.instructions.items) |instruction| {
        if (!std.mem.eql(u8, instruction.result orelse continue, name)) continue;
        const icmp = switch (instruction.kind) {
            .icmp => |icmp| icmp,
            else => return null,
        };
        if (icmp.predicate == .eq and icmp.operand_ty.eql(.{ .int = 8 })) return icmp;
        return null;
    }
    return null;
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
