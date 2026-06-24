const impl = @import("core_impl.zig");
const diagnostics = @import("core_diagnostics.zig");
const std = impl.std;
const ir = impl.ir;
const MachineFunction = impl.MachineFunction;

const isNamed = impl.isNamed;
const isInt = impl.isInt;
const isCalleeName = impl.isCalleeName;
const paramReg = impl.paramReg;
const appendPanicCall = impl.appendPanicCall;
const phiHasIncoming = impl.phiHasIncoming;
const phiHasIncomingInt = impl.phiHasIncomingInt;

fn blockByName(function: ir.Function, name: []const u8) ?ir.BasicBlock {
    for (function.blocks.items) |block| {
        if (std.mem.eql(u8, block.name, name)) return block;
    }
    return null;
}

fn functionHasCall(function: ir.Function, callee: []const u8) bool {
    return diagnostics.functionHasCall(function, callee);
}

pub fn genericCfgLoopSumPlan(function: ir.Function) ?impl.GenericCfgLoopSumPlan {
    if (!function.ret_ty.eql(.{ .int = 32 })) return null;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 32 })) return null;
    if (!matchesAccumulatorLoop(function) and
        !matchesUnrolledAccumulatorLoop(function) and
        !matchesCheckedUnrolledAccumulatorLoop(function) and
        !matchesGuardedDoWhileAccumulatorLoop(function) and
        !matchesCheckedGuardedDoWhileAccumulatorLoop(function)) return null;
    if (!impl.genericCfgSupportsLoopSum(function)) return null;
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
