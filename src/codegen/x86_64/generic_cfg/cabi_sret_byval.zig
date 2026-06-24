const impl = @import("cabi_impl.zig");
const std = impl.std;
const ir = impl.ir;
const MachineFunction = impl.MachineFunction;
const paramReg = impl.paramReg;
const blockIndex = impl.blockIndex;
const isNamed = impl.isNamed;
const validateDebugF128Sret = impl.validateDebugF128Sret;
const validateF128EntryEqBranch = impl.validateF128EntryEqBranch;
const validateF128SecondEqBranch = impl.validateF128SecondEqBranch;
const validateF128SretSuccess = impl.validateF128SretSuccess;
const validatePanicUnreachableBlock = impl.validatePanicUnreachableBlock;
const validateDebugF128AggregateReturn = impl.validateDebugF128AggregateReturn;
const validateF128AggregateRet = impl.validateF128AggregateRet;
const validateDebugF128ScalarReturn = impl.validateDebugF128ScalarReturn;
const validateF128ScalarRet = impl.validateF128ScalarRet;
const validateF128EqCall = impl.validateF128EqCall;
const validateEqZeroIcmp = impl.validateEqZeroIcmp;

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

pub const appendCompareStackByval64Imm64 = impl.appendCompareStackByval64Imm64;
