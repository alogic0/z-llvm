const impl = @import("core_impl.zig");
const diagnostics = @import("core_diagnostics.zig");
const loop_rows = @import("core_loop_rows.zig");
const std = impl.std;
const ir = impl.ir;

pub fn lowerControlFlowLoopSum(allocator: std.mem.Allocator, machine: *impl.MachineFunction, function: ir.Function) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 32 })) return false;
    if (!loop_rows.matchesAccumulatorLoop(function) and
        !loop_rows.matchesUnrolledAccumulatorLoop(function) and
        !loop_rows.matchesCheckedUnrolledAccumulatorLoop(function) and
        !loop_rows.matchesGuardedDoWhileAccumulatorLoop(function) and
        !loop_rows.matchesCheckedGuardedDoWhileAccumulatorLoop(function)) return false;
    const count_reg = try impl.paramReg(function, function.params.items[0].name, .{ .int = 32 });
    if (count_reg != .rdi) return error.UnsupportedCodegenAbi;

    const loop_label = "loop_sum_loop";
    const zero_label = "loop_sum_zero";
    const overflow_label = "loop_sum_overflow";
    const out_of_bounds_label = "loop_sum_out_of_bounds";
    const has_overflow_check = diagnostics.functionHasCall(function, "llvm.sadd.with.overflow.i32");
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
    if (has_overflow_check) try impl.appendPanicCall(allocator, machine, overflow_label, "debug.FullPanic((function 'defaultPanic')).integerOverflow");
    if (has_out_of_bounds_check) try impl.appendPanicCall(allocator, machine, out_of_bounds_label, "debug.FullPanic((function 'defaultPanic')).integerOutOfBounds");
    return true;
}
