const shared = @import("core_shared.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");
const call_lowering = @import("cabi_call_lowering.zig");
const std = shared.std;
const ir = shared.ir;
const MachineFunction = shared.MachineFunction;

const isNamed = shared.isNamed;
const isInt = shared.isInt;
const isCalleeName = shared.isCalleeName;
const paramReg = cabi_abi_helpers.paramReg;
const phiHasIncoming = call_lowering.phiHasIncoming;
const phiHasIncomingInt = call_lowering.phiHasIncomingInt;
const loop_matchers = @import("core_loop_matchers.zig");
const matchI64BinaryNamedImm = loop_matchers.matchI64BinaryNamedImm;
const functionHasNoRemovedInstructions = loop_matchers.functionHasNoRemovedInstructions;
const scalarAtomicCompareExchangeBits = loop_matchers.scalarAtomicCompareExchangeBits;
const matchExtractValue = loop_matchers.matchExtractValue;
const matchByteGep = loop_matchers.matchByteGep;
const matchPlainI8Load = loop_matchers.matchPlainI8Load;
const matchSpinlockAcquireLoop = loop_matchers.matchSpinlockAcquireLoop;
const matchSpinlockGep = loop_matchers.matchSpinlockGep;
const isSpinlockedMemcpyCall = loop_matchers.isSpinlockedMemcpyCall;

pub fn lowerAtomicCompareExchangeFamily(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (try matchSpinlockedVariableCompareExchange(function)) |spinlock_symbol| {
        const len_reg = try paramReg(function, function.params.items[0].name, .{ .int = 32 });
        const ptr_reg = try paramReg(function, function.params.items[1].name, .ptr);
        const expected_reg = try paramReg(function, function.params.items[2].name, .ptr);
        const desired_reg = try paramReg(function, function.params.items[3].name, .ptr);
        if (len_reg != .rdi or ptr_reg != .rsi or expected_reg != .rdx or desired_reg != .rcx) return error.UnsupportedCodegenAbi;
        try machine.instructions.append(allocator, .{ .spinlocked_var_cmpxchg_edi_rsi_rdx_rcx_eax = spinlock_symbol });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    if (try matchAtomicCompareExchangeScalar(function)) |bits| {
        const ptr_reg = try paramReg(function, function.params.items[0].name, .ptr);
        const expected_reg = try paramReg(function, function.params.items[1].name, .ptr);
        const desired_reg = try paramReg(function, function.params.items[2].name, .{ .int = bits });
        if (ptr_reg != .rdi or expected_reg != .rsi or desired_reg != .rdx) return error.UnsupportedCodegenAbi;
        try machine.instructions.append(allocator, switch (bits) {
            8 => .cmpxchg_ptr_expected_desired_i8_eax,
            16 => .cmpxchg_ptr_expected_desired_i16_eax,
            32 => .cmpxchg_ptr_expected_desired_i32_eax,
            64 => .cmpxchg_ptr_expected_desired_i64_eax,
            else => unreachable,
        });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    if (try matchSpinlockedCompareExchangeI128(function)) |spinlock_symbol| {
        const ptr_reg = try paramReg(function, function.params.items[0].name, .ptr);
        const expected_reg = try paramReg(function, function.params.items[1].name, .ptr);
        if (ptr_reg != .rdi or expected_reg != .rsi) return error.UnsupportedCodegenAbi;
        try machine.instructions.append(allocator, .{ .spinlocked_cmpxchg_i128_rdi_rsi_rdx_rcx_eax = spinlock_symbol });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    return false;
}

fn matchSpinlockedVariableCompareExchange(function: ir.Function) !?[]const u8 {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 6) return null;
    if (!function.params.items[0].ty.eql(.{ .int = 32 }) or
        !function.params.items[1].ty.eql(.ptr) or
        !function.params.items[2].ty.eql(.ptr) or
        !function.params.items[3].ty.eql(.ptr) or
        !function.params.items[4].ty.eql(.{ .int = 32 }) or
        !function.params.items[5].ty.eql(.{ .int = 32 })) return null;
    if (function.blocks.items.len != 8) return null;
    if (!functionHasNoRemovedInstructions(function)) return null;

    const len_name = function.params.items[0].name;
    const ptr_name = function.params.items[1].name;
    const expected_name = function.params.items[2].name;
    const desired_name = function.params.items[3].name;
    const entry = function.blocks.items[0];
    const lock_loop = function.blocks.items[1];
    const after_lock = function.blocks.items[2];
    const ret_block = function.blocks.items[3];
    const increment_block = function.blocks.items[4];
    const compare_block = function.blocks.items[5];
    const success_block = function.blocks.items[6];
    const fail_block = function.blocks.items[7];
    if (entry.instructions.items.len != 4 or lock_loop.instructions.items.len != 2 or
        after_lock.instructions.items.len != 2 or ret_block.instructions.items.len != 2 or
        increment_block.instructions.items.len != 2 or compare_block.instructions.items.len != 6 or
        success_block.instructions.items.len != 1 or
        fail_block.instructions.items.len != 1) return null;

    const ptr_int_name = entry.instructions.items[0].result orelse return null;
    const ptr_int = switch (entry.instructions.items[0].kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (ptr_int.op != .ptrtoint or !ptr_int.from_ty.eql(.ptr) or !ptr_int.to_ty.eql(.{ .int = 64 }) or !isNamed(ptr_int.value, ptr_name)) return null;
    const shifted_name = entry.instructions.items[1].result orelse return null;
    if (!matchI64BinaryNamedImm(entry.instructions.items[1], .lshr, ptr_int_name, 3)) return null;
    const slot_name = entry.instructions.items[2].result orelse return null;
    if (!matchI64BinaryNamedImm(entry.instructions.items[2], .@"and", shifted_name, 63)) return null;
    const lock_ptr_name = entry.instructions.items[3].result orelse return null;
    const spinlock_symbol = try matchSpinlockGep(entry.instructions.items[3], slot_name);
    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return null,
    };
    if (!std.mem.eql(u8, entry_br.target, lock_loop.name)) return null;
    if (!matchSpinlockAcquireLoop(lock_loop, lock_ptr_name, after_lock.name)) return null;

    const len64_name = after_lock.instructions.items[0].result orelse return null;
    const len64 = switch (after_lock.instructions.items[0].kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (len64.op != .zext or !len64.from_ty.eql(.{ .int = 32 }) or !len64.to_ty.eql(.{ .int = 64 }) or !isNamed(len64.value, len_name)) return null;
    const zero_len_name = after_lock.instructions.items[1].result orelse return null;
    const zero_len = switch (after_lock.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (zero_len.predicate != .eq or !zero_len.operand_ty.eql(.{ .int = 32 }) or !isNamed(zero_len.lhs, len_name) or !isInt(zero_len.rhs, 0)) return null;
    const after_lock_br = switch (after_lock.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!after_lock_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(after_lock_br.cond, zero_len_name) or
        !std.mem.eql(u8, after_lock_br.then_target, success_block.name) or
        !std.mem.eql(u8, after_lock_br.else_target, compare_block.name)) return null;

    const phi_name = ret_block.instructions.items[0].result orelse return null;
    const phi = switch (ret_block.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return null,
    };
    if (!phi.ty.eql(.{ .int = 32 }) or !phiHasIncomingInt(phi, 1, success_block.name) or !phiHasIncomingInt(phi, 0, fail_block.name)) return null;
    const release = switch (ret_block.instructions.items[1].kind) {
        .store => |store| store,
        else => return null,
    };
    if (!release.ty.eql(.{ .int = 64 }) or !isInt(release.value, 0) or !isNamed(release.ptr, lock_ptr_name) or
        release.attrs.atomic_ordering == null or !std.mem.eql(u8, release.attrs.atomic_ordering.?, "release") or
        release.attrs.@"align" != 64 or release.attrs.is_volatile) return null;
    const ret = switch (ret_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return null, phi_name)) return null;

    const idx_name = compare_block.instructions.items[0].result orelse return null;
    const idx = switch (compare_block.instructions.items[0].kind) {
        .phi => |idx_phi| idx_phi,
        else => return null,
    };
    if (!idx.ty.eql(.{ .int = 64 })) return null;
    const next_name = increment_block.instructions.items[0].result orelse return null;
    if (!phiHasIncomingInt(idx, 0, after_lock.name) or !phiHasIncoming(idx, next_name, increment_block.name)) return null;

    const object_gep_name = compare_block.instructions.items[1].result orelse return null;
    if (!matchByteGep(compare_block.instructions.items[1], ptr_name, idx_name)) return null;
    const object_byte_name = compare_block.instructions.items[2].result orelse return null;
    if (!matchPlainI8Load(compare_block.instructions.items[2], object_gep_name)) return null;
    const expected_gep_name = compare_block.instructions.items[3].result orelse return null;
    if (!matchByteGep(compare_block.instructions.items[3], expected_name, idx_name)) return null;
    const expected_byte_name = compare_block.instructions.items[4].result orelse return null;
    if (!matchPlainI8Load(compare_block.instructions.items[4], expected_gep_name)) return null;
    const equal_name = compare_block.instructions.items[5].result orelse return null;
    const equal = switch (compare_block.instructions.items[5].kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (equal.predicate != .eq or !equal.operand_ty.eql(.{ .int = 8 }) or
        !isNamed(equal.lhs, expected_byte_name) or !isNamed(equal.rhs, object_byte_name)) return null;
    const compare_br = switch (compare_block.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!compare_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(compare_br.cond, equal_name) or
        !std.mem.eql(u8, compare_br.then_target, increment_block.name) or
        !std.mem.eql(u8, compare_br.else_target, fail_block.name)) return null;

    const next = switch (increment_block.instructions.items[0].kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (next.op != .add or !next.ty.eql(.{ .int = 64 }) or !isNamed(next.lhs, idx_name) or !isInt(next.rhs, 1)) return null;
    const exit_name = increment_block.instructions.items[1].result orelse return null;
    const exit_cmp = switch (increment_block.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (exit_cmp.predicate != .eq or !exit_cmp.operand_ty.eql(.{ .int = 64 }) or !isNamed(exit_cmp.lhs, next_name) or !isNamed(exit_cmp.rhs, len64_name)) return null;
    const increment_br = switch (increment_block.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!increment_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(increment_br.cond, exit_name) or
        !std.mem.eql(u8, increment_br.then_target, success_block.name) or
        !std.mem.eql(u8, increment_br.else_target, compare_block.name)) return null;

    const success_copy = switch (success_block.instructions.items[0].kind) {
        .call => |call| call,
        else => return null,
    };
    if (!isSpinlockedMemcpyCall(success_copy, ptr_name, desired_name, len64_name)) return null;
    const success_br = switch (success_block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return null,
    };
    if (!std.mem.eql(u8, success_br.target, ret_block.name)) return null;

    const fail_copy = switch (fail_block.instructions.items[0].kind) {
        .call => |call| call,
        else => return null,
    };
    if (!isSpinlockedMemcpyCall(fail_copy, expected_name, ptr_name, len64_name)) return null;
    const fail_br = switch (fail_block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return null,
    };
    if (!std.mem.eql(u8, fail_br.target, ret_block.name)) return null;

    return spinlock_symbol;
}

pub fn lowerAtomicExchangeFamily(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (try matchSpinlockedVariableExchange(function)) |spinlock_symbol| {
        const len_reg = try paramReg(function, function.params.items[0].name, .{ .int = 32 });
        const ptr_reg = try paramReg(function, function.params.items[1].name, .ptr);
        const desired_reg = try paramReg(function, function.params.items[2].name, .ptr);
        const output_reg = try paramReg(function, function.params.items[3].name, .ptr);
        if (len_reg != .rdi or ptr_reg != .rsi or desired_reg != .rdx or output_reg != .rcx) return error.UnsupportedCodegenAbi;
        try machine.instructions.append(allocator, .{ .spinlocked_var_xchg_edi_rsi_rdx_rcx = spinlock_symbol });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    if (try matchAtomicExchangeScalar(function)) |bits| {
        const ptr_reg = try paramReg(function, function.params.items[0].name, .ptr);
        const value_reg = try paramReg(function, function.params.items[1].name, .{ .int = bits });
        if (ptr_reg != .rdi or value_reg != .rsi) return error.UnsupportedCodegenAbi;
        try machine.instructions.append(allocator, switch (bits) {
            8 => .xchg_ptr_value_i8_eax,
            16 => .xchg_ptr_value_i16_eax,
            32 => .xchg_ptr_value_i32_eax,
            64 => .xchg_ptr_value_i64_rax,
            else => unreachable,
        });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    if (try matchSpinlockedExchangeI128(function)) |spinlock_symbol| {
        const ptr_reg = try paramReg(function, function.params.items[0].name, .ptr);
        if (ptr_reg != .rdi) return error.UnsupportedCodegenAbi;
        try machine.instructions.append(allocator, .{ .spinlocked_xchg_i128_rdi_rsi_rdx_rax = spinlock_symbol });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    return false;
}

fn matchSpinlockedVariableExchange(function: ir.Function) !?[]const u8 {
    if (function.ret_ty != .void or function.params.items.len != 5) return null;
    if (!function.params.items[0].ty.eql(.{ .int = 32 }) or
        !function.params.items[1].ty.eql(.ptr) or
        !function.params.items[2].ty.eql(.ptr) or
        !function.params.items[3].ty.eql(.ptr) or
        !function.params.items[4].ty.eql(.{ .int = 32 })) return null;
    if (function.blocks.items.len != 3) return null;
    if (!functionHasNoRemovedInstructions(function)) return null;

    const len_name = function.params.items[0].name;
    const ptr_name = function.params.items[1].name;
    const desired_name = function.params.items[2].name;
    const output_name = function.params.items[3].name;
    const entry = function.blocks.items[0];
    const loop = function.blocks.items[1];
    const exit = function.blocks.items[2];
    if (entry.instructions.items.len != 4 or loop.instructions.items.len != 2 or exit.instructions.items.len != 4) return null;

    const ptr_int_name = entry.instructions.items[0].result orelse return null;
    const ptr_int = switch (entry.instructions.items[0].kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (ptr_int.op != .ptrtoint or !ptr_int.from_ty.eql(.ptr) or !ptr_int.to_ty.eql(.{ .int = 64 }) or !isNamed(ptr_int.value, ptr_name)) return null;
    const shifted_name = entry.instructions.items[1].result orelse return null;
    if (!matchI64BinaryNamedImm(entry.instructions.items[1], .lshr, ptr_int_name, 3)) return null;
    const slot_name = entry.instructions.items[2].result orelse return null;
    if (!matchI64BinaryNamedImm(entry.instructions.items[2], .@"and", shifted_name, 63)) return null;
    const lock_ptr_name = entry.instructions.items[3].result orelse return null;
    const spinlock_symbol = try matchSpinlockGep(entry.instructions.items[3], slot_name);
    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return null,
    };
    if (!std.mem.eql(u8, entry_br.target, loop.name)) return null;
    if (!matchSpinlockAcquireLoop(loop, lock_ptr_name, exit.name)) return null;

    const len64_name = exit.instructions.items[0].result orelse return null;
    const len64 = switch (exit.instructions.items[0].kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (len64.op != .zext or !len64.from_ty.eql(.{ .int = 32 }) or !len64.to_ty.eql(.{ .int = 64 }) or !isNamed(len64.value, len_name)) return null;
    const old_copy = switch (exit.instructions.items[1].kind) {
        .call => |call| call,
        else => return null,
    };
    if (!isSpinlockedMemcpyCall(old_copy, output_name, ptr_name, len64_name)) return null;
    const new_copy = switch (exit.instructions.items[2].kind) {
        .call => |call| call,
        else => return null,
    };
    if (!isSpinlockedMemcpyCall(new_copy, ptr_name, desired_name, len64_name)) return null;
    const release = switch (exit.instructions.items[3].kind) {
        .store => |store| store,
        else => return null,
    };
    if (!release.ty.eql(.{ .int = 64 }) or !isInt(release.value, 0) or !isNamed(release.ptr, lock_ptr_name) or
        release.attrs.atomic_ordering == null or !std.mem.eql(u8, release.attrs.atomic_ordering.?, "release") or
        release.attrs.@"align" != 64 or release.attrs.is_volatile) return null;
    const ret = switch (exit.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return null,
    };
    if (ret.ty != .void or ret.value != null) return null;
    return spinlock_symbol;
}

pub fn lowerAtomicStoreFamily(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (try matchSpinlockedVariableStore(function)) |spinlock_symbol| {
        const len_reg = try paramReg(function, function.params.items[0].name, .{ .int = 32 });
        const ptr_reg = try paramReg(function, function.params.items[1].name, .ptr);
        const desired_reg = try paramReg(function, function.params.items[2].name, .ptr);
        if (len_reg != .rdi or ptr_reg != .rsi or desired_reg != .rdx) return error.UnsupportedCodegenAbi;
        try machine.instructions.append(allocator, .{ .spinlocked_var_store_edi_rsi_rdx = spinlock_symbol });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    if (try matchAtomicStoreScalar(function)) |bits| {
        const ptr_reg = try paramReg(function, function.params.items[0].name, .ptr);
        const value_reg = try paramReg(function, function.params.items[1].name, .{ .int = bits });
        if (ptr_reg != .rdi or value_reg != .rsi) return error.UnsupportedCodegenAbi;
        try machine.instructions.append(allocator, switch (bits) {
            8 => .xchg_ptr_value_i8_eax,
            16 => .xchg_ptr_value_i16_eax,
            32 => .xchg_ptr_value_i32_eax,
            64 => .xchg_ptr_value_i64_rax,
            else => unreachable,
        });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    if (try matchSpinlockedStoreI128(function)) |spinlock_symbol| {
        const ptr_reg = try paramReg(function, function.params.items[0].name, .ptr);
        if (ptr_reg != .rdi) return error.UnsupportedCodegenAbi;
        try machine.instructions.append(allocator, .{ .spinlocked_store_i128_rdi_rsi_rdx = spinlock_symbol });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    return false;
}

fn matchSpinlockedVariableStore(function: ir.Function) !?[]const u8 {
    if (function.ret_ty != .void or function.params.items.len != 4) return null;
    if (!function.params.items[0].ty.eql(.{ .int = 32 }) or
        !function.params.items[1].ty.eql(.ptr) or
        !function.params.items[2].ty.eql(.ptr) or
        !function.params.items[3].ty.eql(.{ .int = 32 })) return null;
    if (function.blocks.items.len != 3) return null;
    if (!functionHasNoRemovedInstructions(function)) return null;

    const len_name = function.params.items[0].name;
    const ptr_name = function.params.items[1].name;
    const desired_name = function.params.items[2].name;
    const entry = function.blocks.items[0];
    const loop = function.blocks.items[1];
    const exit = function.blocks.items[2];
    if (entry.instructions.items.len != 4 or loop.instructions.items.len != 2 or exit.instructions.items.len != 3) return null;

    const ptr_int_name = entry.instructions.items[0].result orelse return null;
    const ptr_int = switch (entry.instructions.items[0].kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (ptr_int.op != .ptrtoint or !ptr_int.from_ty.eql(.ptr) or !ptr_int.to_ty.eql(.{ .int = 64 }) or !isNamed(ptr_int.value, ptr_name)) return null;
    const shifted_name = entry.instructions.items[1].result orelse return null;
    if (!matchI64BinaryNamedImm(entry.instructions.items[1], .lshr, ptr_int_name, 3)) return null;
    const slot_name = entry.instructions.items[2].result orelse return null;
    if (!matchI64BinaryNamedImm(entry.instructions.items[2], .@"and", shifted_name, 63)) return null;
    const lock_ptr_name = entry.instructions.items[3].result orelse return null;
    const spinlock_symbol = try matchSpinlockGep(entry.instructions.items[3], slot_name);
    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return null,
    };
    if (!std.mem.eql(u8, entry_br.target, loop.name)) return null;
    if (!matchSpinlockAcquireLoop(loop, lock_ptr_name, exit.name)) return null;

    const len64_name = exit.instructions.items[0].result orelse return null;
    const len64 = switch (exit.instructions.items[0].kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (len64.op != .zext or !len64.from_ty.eql(.{ .int = 32 }) or !len64.to_ty.eql(.{ .int = 64 }) or !isNamed(len64.value, len_name)) return null;
    const new_copy = switch (exit.instructions.items[1].kind) {
        .call => |call| call,
        else => return null,
    };
    if (!isSpinlockedMemcpyCall(new_copy, ptr_name, desired_name, len64_name)) return null;
    const release = switch (exit.instructions.items[2].kind) {
        .store => |store| store,
        else => return null,
    };
    if (!release.ty.eql(.{ .int = 64 }) or !isInt(release.value, 0) or !isNamed(release.ptr, lock_ptr_name) or
        release.attrs.atomic_ordering == null or !std.mem.eql(u8, release.attrs.atomic_ordering.?, "release") or
        release.attrs.@"align" != 64 or release.attrs.is_volatile) return null;
    const ret = switch (exit.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return null,
    };
    if (ret.ty != .void or ret.value != null) return null;
    return spinlock_symbol;
}

pub fn lowerAtomicLoadFamily(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (try matchAtomicLoadScalar(function)) |bits| {
        const ptr_reg = try paramReg(function, function.params.items[0].name, .ptr);
        if (ptr_reg != .rdi) return error.UnsupportedCodegenAbi;
        try machine.instructions.append(allocator, switch (bits) {
            8 => .load_rdi_ptr_u8_eax,
            16 => .load_rdi_ptr_u16_eax,
            32 => .load_rdi_ptr_eax,
            64 => .load_rdi_ptr_rax,
            else => unreachable,
        });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    if (try matchSpinlockedLoadI128(function)) |spinlock_symbol| {
        const ptr_reg = try paramReg(function, function.params.items[0].name, .ptr);
        if (ptr_reg != .rdi) return error.UnsupportedCodegenAbi;
        try machine.instructions.append(allocator, .{ .spinlocked_load_i128_rdi_rax_rdx = spinlock_symbol });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    return false;
}

pub fn lowerAtomicFetchUminFamily(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (try matchAtomicFetchUminScalar(function)) |bits| {
        const ptr_reg = try paramReg(function, function.params.items[0].name, .ptr);
        const value_reg = try paramReg(function, function.params.items[1].name, .{ .int = bits });
        if (ptr_reg != .rdi or value_reg != .rsi) return error.UnsupportedCodegenAbi;
        try machine.instructions.append(allocator, switch (bits) {
            8 => .atomic_fetch_umin_i8_rdi_sil_eax,
            16 => .atomic_fetch_umin_i16_rdi_si_eax,
            32 => .atomic_fetch_umin_i32_rdi_esi_eax,
            64 => .atomic_fetch_umin_i64_rdi_rsi_rax,
            else => unreachable,
        });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    if (try matchSpinlockedFetchUminI128(function)) |spinlock_symbol| {
        const ptr_reg = try paramReg(function, function.params.items[0].name, .ptr);
        if (ptr_reg != .rdi) return error.UnsupportedCodegenAbi;
        try machine.instructions.append(allocator, .{ .spinlocked_fetch_umin_i128_rdi_rsi_rdx_rax_rdx = spinlock_symbol });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    return false;
}

pub fn lowerAtomicFetchUmaxFamily(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (try matchAtomicFetchUmaxScalar(function)) |bits| {
        const ptr_reg = try paramReg(function, function.params.items[0].name, .ptr);
        const value_reg = try paramReg(function, function.params.items[1].name, .{ .int = bits });
        if (ptr_reg != .rdi or value_reg != .rsi) return error.UnsupportedCodegenAbi;
        try machine.instructions.append(allocator, switch (bits) {
            8 => .atomic_fetch_umax_i8_rdi_sil_eax,
            16 => .atomic_fetch_umax_i16_rdi_si_eax,
            32 => .atomic_fetch_umax_i32_rdi_esi_eax,
            64 => .atomic_fetch_umax_i64_rdi_rsi_rax,
            else => unreachable,
        });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    if (try matchSpinlockedFetchUmaxI128(function)) |spinlock_symbol| {
        const ptr_reg = try paramReg(function, function.params.items[0].name, .ptr);
        if (ptr_reg != .rdi) return error.UnsupportedCodegenAbi;
        try machine.instructions.append(allocator, .{ .spinlocked_fetch_umax_i128_rdi_rsi_rdx_rax_rdx = spinlock_symbol });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    return false;
}

pub fn lowerAtomicFetchNandFamily(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (try matchAtomicFetchNandScalar(function)) |bits| {
        const ptr_reg = try paramReg(function, function.params.items[0].name, .ptr);
        const value_reg = try paramReg(function, function.params.items[1].name, .{ .int = bits });
        if (ptr_reg != .rdi or value_reg != .rsi) return error.UnsupportedCodegenAbi;
        try machine.instructions.append(allocator, switch (bits) {
            8 => .atomic_fetch_nand_i8_rdi_sil_eax,
            16 => .atomic_fetch_nand_i16_rdi_si_eax,
            32 => .atomic_fetch_nand_i32_rdi_esi_eax,
            64 => .atomic_fetch_nand_i64_rdi_rsi_rax,
            else => unreachable,
        });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    if (try matchSpinlockedFetchNandI128(function)) |spinlock_symbol| {
        const ptr_reg = try paramReg(function, function.params.items[0].name, .ptr);
        if (ptr_reg != .rdi) return error.UnsupportedCodegenAbi;
        try machine.instructions.append(allocator, .{ .spinlocked_fetch_nand_i128_rdi_rsi_rdx_rax_rdx = spinlock_symbol });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    return false;
}

pub fn lowerAtomicFetchXorFamily(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (try matchAtomicFetchXorScalar(function)) |bits| {
        const ptr_reg = try paramReg(function, function.params.items[0].name, .ptr);
        const value_reg = try paramReg(function, function.params.items[1].name, .{ .int = bits });
        if (ptr_reg != .rdi or value_reg != .rsi) return error.UnsupportedCodegenAbi;
        try machine.instructions.append(allocator, switch (bits) {
            8 => .atomic_fetch_xor_i8_rdi_sil_eax,
            16 => .atomic_fetch_xor_i16_rdi_si_eax,
            32 => .atomic_fetch_xor_i32_rdi_esi_eax,
            64 => .atomic_fetch_xor_i64_rdi_rsi_rax,
            else => unreachable,
        });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    if (try matchSpinlockedFetchXorI128(function)) |spinlock_symbol| {
        const ptr_reg = try paramReg(function, function.params.items[0].name, .ptr);
        if (ptr_reg != .rdi) return error.UnsupportedCodegenAbi;
        try machine.instructions.append(allocator, .{ .spinlocked_fetch_xor_i128_rdi_rsi_rdx_rax_rdx = spinlock_symbol });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    return false;
}

pub fn lowerAtomicFetchOrFamily(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (try matchAtomicFetchOrScalar(function)) |bits| {
        const ptr_reg = try paramReg(function, function.params.items[0].name, .ptr);
        const value_reg = try paramReg(function, function.params.items[1].name, .{ .int = bits });
        if (ptr_reg != .rdi or value_reg != .rsi) return error.UnsupportedCodegenAbi;
        try machine.instructions.append(allocator, switch (bits) {
            8 => .atomic_fetch_or_i8_rdi_sil_eax,
            16 => .atomic_fetch_or_i16_rdi_si_eax,
            32 => .atomic_fetch_or_i32_rdi_esi_eax,
            64 => .atomic_fetch_or_i64_rdi_rsi_rax,
            else => unreachable,
        });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    if (try matchSpinlockedFetchOrI128(function)) |spinlock_symbol| {
        const ptr_reg = try paramReg(function, function.params.items[0].name, .ptr);
        if (ptr_reg != .rdi) return error.UnsupportedCodegenAbi;
        try machine.instructions.append(allocator, .{ .spinlocked_fetch_or_i128_rdi_rsi_rdx_rax_rdx = spinlock_symbol });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    return false;
}

pub fn lowerAtomicFetchAndFamily(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (try matchAtomicFetchAndScalar(function)) |bits| {
        const ptr_reg = try paramReg(function, function.params.items[0].name, .ptr);
        const value_reg = try paramReg(function, function.params.items[1].name, .{ .int = bits });
        if (ptr_reg != .rdi or value_reg != .rsi) return error.UnsupportedCodegenAbi;
        try machine.instructions.append(allocator, switch (bits) {
            8 => .atomic_fetch_and_i8_rdi_sil_eax,
            16 => .atomic_fetch_and_i16_rdi_si_eax,
            32 => .atomic_fetch_and_i32_rdi_esi_eax,
            64 => .atomic_fetch_and_i64_rdi_rsi_rax,
            else => unreachable,
        });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    if (try matchSpinlockedFetchAndI128(function)) |spinlock_symbol| {
        const ptr_reg = try paramReg(function, function.params.items[0].name, .ptr);
        if (ptr_reg != .rdi) return error.UnsupportedCodegenAbi;
        try machine.instructions.append(allocator, .{ .spinlocked_fetch_and_i128_rdi_rsi_rdx_rax_rdx = spinlock_symbol });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    return false;
}

pub fn lowerAtomicFetchSubFamily(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (try matchAtomicFetchSubScalar(function)) |bits| {
        const ptr_reg = try paramReg(function, function.params.items[0].name, .ptr);
        const value_reg = try paramReg(function, function.params.items[1].name, .{ .int = bits });
        if (ptr_reg != .rdi or value_reg != .rsi) return error.UnsupportedCodegenAbi;
        try machine.instructions.append(allocator, switch (bits) {
            8 => .atomic_fetch_sub_i8_rdi_sil_eax,
            16 => .atomic_fetch_sub_i16_rdi_si_eax,
            32 => .atomic_fetch_sub_i32_rdi_esi_eax,
            64 => .atomic_fetch_sub_i64_rdi_rsi_rax,
            else => unreachable,
        });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    if (try matchSpinlockedFetchSubI128(function)) |spinlock_symbol| {
        const ptr_reg = try paramReg(function, function.params.items[0].name, .ptr);
        if (ptr_reg != .rdi) return error.UnsupportedCodegenAbi;
        try machine.instructions.append(allocator, .{ .spinlocked_fetch_sub_i128_rdi_rsi_rdx_rax_rdx = spinlock_symbol });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    return false;
}

pub fn lowerAtomicFetchAddFamily(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (try matchAtomicFetchAddScalar(function)) |bits| {
        const ptr_reg = try paramReg(function, function.params.items[0].name, .ptr);
        const value_reg = try paramReg(function, function.params.items[1].name, .{ .int = bits });
        if (ptr_reg != .rdi or value_reg != .rsi) return error.UnsupportedCodegenAbi;
        try machine.instructions.append(allocator, switch (bits) {
            8 => .atomic_fetch_add_i8_rdi_sil_eax,
            16 => .atomic_fetch_add_i16_rdi_si_eax,
            32 => .atomic_fetch_add_i32_rdi_esi_eax,
            64 => .atomic_fetch_add_i64_rdi_rsi_rax,
            else => unreachable,
        });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    if (try matchSpinlockedFetchAddI128(function)) |spinlock_symbol| {
        const ptr_reg = try paramReg(function, function.params.items[0].name, .ptr);
        if (ptr_reg != .rdi) return error.UnsupportedCodegenAbi;
        try machine.instructions.append(allocator, .{ .spinlocked_fetch_add_i128_rdi_rsi_rdx_rax_rdx = spinlock_symbol });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    return false;
}

fn matchAtomicCompareExchangeScalar(function: ir.Function) !?u16 {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 5) return null;
    const bits = scalarAtomicCompareExchangeBits(function.params.items[2].ty) orelse return null;
    if (bits == 128) return null;
    if (!function.params.items[0].ty.eql(.ptr) or
        !function.params.items[1].ty.eql(.ptr) or
        !function.params.items[3].ty.eql(.{ .int = 32 }) or
        !function.params.items[4].ty.eql(.{ .int = 32 })) return null;
    if (function.blocks.items.len != 3) return null;
    if (!functionHasNoRemovedInstructions(function)) return null;

    const ptr_name = function.params.items[0].name;
    const expected_ptr_name = function.params.items[1].name;
    const desired_name = function.params.items[2].name;
    const entry = function.blocks.items[0];
    const ret_block = function.blocks.items[1];
    const fail_block = function.blocks.items[2];
    if (entry.instructions.items.len != 8 or ret_block.instructions.items.len != 1 or fail_block.instructions.items.len != 2) return null;

    const scratch_name = entry.instructions.items[0].result orelse return null;
    const scratch = switch (entry.instructions.items[0].kind) {
        .alloca => |alloca| alloca,
        else => return null,
    };
    if (!scratch.allocated_ty.eql(.{ .int = 8 })) return null;

    const expected_value_name = entry.instructions.items[1].result orelse return null;
    const expected_load = switch (entry.instructions.items[1].kind) {
        .load => |load| load,
        else => return null,
    };
    if (!expected_load.ty.eql(.{ .int = bits }) or !isNamed(expected_load.ptr, expected_ptr_name) or expected_load.attrs.isBarrier()) return null;

    const cmpxchg_name = entry.instructions.items[2].result orelse return null;
    const cmpxchg = switch (entry.instructions.items[2].kind) {
        .cmpxchg => |cmpxchg| cmpxchg,
        else => return null,
    };
    if (!cmpxchg.ty.eql(.{ .int = bits }) or !isNamed(cmpxchg.ptr, ptr_name) or
        !isNamed(cmpxchg.expected, expected_value_name) or !isNamed(cmpxchg.replacement, desired_name) or
        !std.mem.eql(u8, cmpxchg.success_ordering, "seq_cst") or
        !std.mem.eql(u8, cmpxchg.failure_ordering, "seq_cst") or
        cmpxchg.syncscope != null or cmpxchg.is_weak or cmpxchg.is_volatile or cmpxchg.@"align" != bits / 8) return null;

    const success_name = entry.instructions.items[3].result orelse return null;
    if (!matchExtractValue(entry.instructions.items[3], cmpxchg_name, "1", .{ .int = 1 })) return null;

    const failure_flag_name = entry.instructions.items[4].result orelse return null;
    const failure_flag = switch (entry.instructions.items[4].kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (failure_flag.op != .xor or !failure_flag.ty.eql(.{ .int = 1 }) or
        !isNamed(failure_flag.lhs, success_name) or !isInt(failure_flag.rhs, 1)) return null;

    const scratch_store = switch (entry.instructions.items[5].kind) {
        .store => |store| store,
        else => return null,
    };
    if (!scratch_store.ty.eql(.{ .int = 1 }) or !isNamed(scratch_store.value, failure_flag_name) or
        !isNamed(scratch_store.ptr, scratch_name) or scratch_store.attrs.isBarrier()) return null;

    const scratch_loaded_name = entry.instructions.items[6].result orelse return null;
    const scratch_load = switch (entry.instructions.items[6].kind) {
        .load => |load| load,
        else => return null,
    };
    if (!scratch_load.ty.eql(.{ .int = 8 }) or !isNamed(scratch_load.ptr, scratch_name) or scratch_load.attrs.isBarrier()) return null;

    const branch_cond_name = entry.instructions.items[7].result orelse return null;
    const branch_cond = switch (entry.instructions.items[7].kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (branch_cond.predicate != .eq or !branch_cond.operand_ty.eql(.{ .int = 8 }) or
        !isNamed(branch_cond.lhs, scratch_loaded_name) or !isInt(branch_cond.rhs, 0)) return null;

    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, branch_cond_name) or
        !std.mem.eql(u8, entry_br.then_target, ret_block.name) or !std.mem.eql(u8, entry_br.else_target, fail_block.name)) return null;

    const phi_name = ret_block.instructions.items[0].result orelse return null;
    const phi = switch (ret_block.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return null,
    };
    if (!phi.ty.eql(.{ .int = 32 }) or !phiHasIncomingInt(phi, 1, entry.name) or !phiHasIncomingInt(phi, 0, fail_block.name)) return null;
    const ret = switch (ret_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return null, phi_name)) return null;

    const old_value_name = fail_block.instructions.items[0].result orelse return null;
    if (!matchExtractValue(fail_block.instructions.items[0], cmpxchg_name, "0", .{ .int = bits })) return null;
    const old_store = switch (fail_block.instructions.items[1].kind) {
        .store => |store| store,
        else => return null,
    };
    if (!old_store.ty.eql(.{ .int = bits }) or !isNamed(old_store.value, old_value_name) or
        !isNamed(old_store.ptr, expected_ptr_name) or old_store.attrs.isBarrier()) return null;
    const fail_br = switch (fail_block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return null,
    };
    if (!std.mem.eql(u8, fail_br.target, ret_block.name)) return null;
    return bits;
}

fn matchSpinlockedCompareExchangeI128(function: ir.Function) !?[]const u8 {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 5) return null;
    if (!function.params.items[0].ty.eql(.ptr) or
        !function.params.items[1].ty.eql(.ptr) or
        !function.params.items[2].ty.eql(.{ .int = 128 }) or
        !function.params.items[3].ty.eql(.{ .int = 32 }) or
        !function.params.items[4].ty.eql(.{ .int = 32 })) return null;
    if (function.blocks.items.len != 6) return null;
    if (!functionHasNoRemovedInstructions(function)) return null;

    const ptr_name = function.params.items[0].name;
    const expected_ptr_name = function.params.items[1].name;
    const desired_name = function.params.items[2].name;
    const entry = function.blocks.items[0];
    const loop = function.blocks.items[1];
    const compare = function.blocks.items[2];
    const ret_block = function.blocks.items[3];
    const success_block = function.blocks.items[4];
    const fail_block = function.blocks.items[5];
    if (entry.instructions.items.len != 4 or loop.instructions.items.len != 2 or
        compare.instructions.items.len != 3 or ret_block.instructions.items.len != 2 or
        success_block.instructions.items.len != 1 or fail_block.instructions.items.len != 1) return null;

    const ptr_int_name = entry.instructions.items[0].result orelse return null;
    const ptr_int = switch (entry.instructions.items[0].kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (ptr_int.op != .ptrtoint or !ptr_int.from_ty.eql(.ptr) or !ptr_int.to_ty.eql(.{ .int = 64 }) or !isNamed(ptr_int.value, ptr_name)) return null;
    const shifted_name = entry.instructions.items[1].result orelse return null;
    if (!matchI64BinaryNamedImm(entry.instructions.items[1], .lshr, ptr_int_name, 3)) return null;
    const slot_name = entry.instructions.items[2].result orelse return null;
    if (!matchI64BinaryNamedImm(entry.instructions.items[2], .@"and", shifted_name, 62)) return null;
    const lock_ptr_name = entry.instructions.items[3].result orelse return null;
    const spinlock_symbol = try matchSpinlockGep(entry.instructions.items[3], slot_name);
    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return null,
    };
    if (!std.mem.eql(u8, entry_br.target, loop.name)) return null;

    if (!matchSpinlockAcquireLoop(loop, lock_ptr_name, compare.name)) return null;

    const loaded_name = compare.instructions.items[0].result orelse return null;
    const loaded = switch (compare.instructions.items[0].kind) {
        .load => |load| load,
        else => return null,
    };
    if (!loaded.ty.eql(.{ .int = 128 }) or !isNamed(loaded.ptr, ptr_name) or loaded.attrs.isBarrier()) return null;
    const expected_name = compare.instructions.items[1].result orelse return null;
    const expected = switch (compare.instructions.items[1].kind) {
        .load => |load| load,
        else => return null,
    };
    if (!expected.ty.eql(.{ .int = 128 }) or !isNamed(expected.ptr, expected_ptr_name) or expected.attrs.isBarrier()) return null;
    const equal_name = compare.instructions.items[2].result orelse return null;
    const equal = switch (compare.instructions.items[2].kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (equal.predicate != .eq or !equal.operand_ty.eql(.{ .int = 128 }) or
        !isNamed(equal.lhs, loaded_name) or !isNamed(equal.rhs, expected_name)) return null;
    const compare_br = switch (compare.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return null,
    };
    if (!compare_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(compare_br.cond, equal_name) or
        !std.mem.eql(u8, compare_br.then_target, success_block.name) or
        !std.mem.eql(u8, compare_br.else_target, fail_block.name)) return null;

    const phi_name = ret_block.instructions.items[0].result orelse return null;
    const phi = switch (ret_block.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return null,
    };
    if (!phi.ty.eql(.{ .int = 32 }) or !phiHasIncomingInt(phi, 1, success_block.name) or !phiHasIncomingInt(phi, 0, fail_block.name)) return null;
    const release = switch (ret_block.instructions.items[1].kind) {
        .store => |store| store,
        else => return null,
    };
    if (!release.ty.eql(.{ .int = 64 }) or !isInt(release.value, 0) or !isNamed(release.ptr, lock_ptr_name) or
        release.attrs.atomic_ordering == null or !std.mem.eql(u8, release.attrs.atomic_ordering.?, "release") or
        release.attrs.@"align" != 64 or release.attrs.is_volatile) return null;
    const ret = switch (ret_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return null, phi_name)) return null;

    const success_store = switch (success_block.instructions.items[0].kind) {
        .store => |store| store,
        else => return null,
    };
    if (!success_store.ty.eql(.{ .int = 128 }) or !isNamed(success_store.value, desired_name) or
        !isNamed(success_store.ptr, ptr_name) or success_store.attrs.isBarrier()) return null;
    const success_br = switch (success_block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return null,
    };
    if (!std.mem.eql(u8, success_br.target, ret_block.name)) return null;

    const fail_store = switch (fail_block.instructions.items[0].kind) {
        .store => |store| store,
        else => return null,
    };
    if (!fail_store.ty.eql(.{ .int = 128 }) or !isNamed(fail_store.value, loaded_name) or
        !isNamed(fail_store.ptr, expected_ptr_name) or fail_store.attrs.isBarrier()) return null;
    const fail_br = switch (fail_block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return null,
    };
    if (!std.mem.eql(u8, fail_br.target, ret_block.name)) return null;
    return spinlock_symbol;
}

fn matchAtomicExchangeScalar(function: ir.Function) !?u16 {
    const bits = scalarAtomicCompareExchangeBits(function.ret_ty) orelse return null;
    if (bits == 128) return null;
    if (function.params.items.len != 3 or
        !function.params.items[0].ty.eql(.ptr) or
        !function.params.items[1].ty.eql(.{ .int = bits }) or
        !function.params.items[2].ty.eql(.{ .int = 32 })) return null;
    if (function.blocks.items.len != 1) return null;
    if (!functionHasNoRemovedInstructions(function)) return null;

    const ptr_name = function.params.items[0].name;
    const value_name = function.params.items[1].name;
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 1) return null;
    const old_name = entry.instructions.items[0].result orelse return null;
    const atomic = switch (entry.instructions.items[0].kind) {
        .atomicrmw => |atomicrmw| atomicrmw,
        else => return null,
    };
    if (!std.mem.eql(u8, atomic.op, "xchg") or
        !atomic.ty.eql(.{ .int = bits }) or
        !isNamed(atomic.ptr, ptr_name) or
        !isNamed(atomic.value, value_name) or
        !std.mem.eql(u8, atomic.ordering, "seq_cst") or
        atomic.syncscope != null or
        atomic.is_volatile or
        atomic.@"align" != bits / 8) return null;
    const ret = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = bits }) or !isNamed(ret.value orelse return null, old_name)) return null;
    return bits;
}

fn matchSpinlockedExchangeI128(function: ir.Function) !?[]const u8 {
    if (!function.ret_ty.eql(.{ .int = 128 }) or function.params.items.len != 3) return null;
    if (!function.params.items[0].ty.eql(.ptr) or
        !function.params.items[1].ty.eql(.{ .int = 128 }) or
        !function.params.items[2].ty.eql(.{ .int = 32 })) return null;
    if (function.blocks.items.len != 3) return null;
    if (!functionHasNoRemovedInstructions(function)) return null;

    const ptr_name = function.params.items[0].name;
    const value_name = function.params.items[1].name;
    const entry = function.blocks.items[0];
    const loop = function.blocks.items[1];
    const exit = function.blocks.items[2];
    if (entry.instructions.items.len != 4 or loop.instructions.items.len != 2 or exit.instructions.items.len != 3) return null;

    const ptr_int_name = entry.instructions.items[0].result orelse return null;
    const ptr_int = switch (entry.instructions.items[0].kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (ptr_int.op != .ptrtoint or !ptr_int.from_ty.eql(.ptr) or !ptr_int.to_ty.eql(.{ .int = 64 }) or !isNamed(ptr_int.value, ptr_name)) return null;
    const shifted_name = entry.instructions.items[1].result orelse return null;
    if (!matchI64BinaryNamedImm(entry.instructions.items[1], .lshr, ptr_int_name, 3)) return null;
    const slot_name = entry.instructions.items[2].result orelse return null;
    if (!matchI64BinaryNamedImm(entry.instructions.items[2], .@"and", shifted_name, 62)) return null;
    const lock_ptr_name = entry.instructions.items[3].result orelse return null;
    const spinlock_symbol = try matchSpinlockGep(entry.instructions.items[3], slot_name);
    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return null,
    };
    if (!std.mem.eql(u8, entry_br.target, loop.name)) return null;

    if (!matchSpinlockAcquireLoop(loop, lock_ptr_name, exit.name)) return null;

    const old_name = exit.instructions.items[0].result orelse return null;
    const old = switch (exit.instructions.items[0].kind) {
        .load => |load| load,
        else => return null,
    };
    if (!old.ty.eql(.{ .int = 128 }) or !isNamed(old.ptr, ptr_name) or old.attrs.isBarrier()) return null;
    const replacement = switch (exit.instructions.items[1].kind) {
        .store => |store| store,
        else => return null,
    };
    if (!replacement.ty.eql(.{ .int = 128 }) or !isNamed(replacement.value, value_name) or
        !isNamed(replacement.ptr, ptr_name) or replacement.attrs.isBarrier()) return null;
    const release = switch (exit.instructions.items[2].kind) {
        .store => |store| store,
        else => return null,
    };
    if (!release.ty.eql(.{ .int = 64 }) or !isInt(release.value, 0) or !isNamed(release.ptr, lock_ptr_name) or
        release.attrs.atomic_ordering == null or !std.mem.eql(u8, release.attrs.atomic_ordering.?, "release") or
        release.attrs.@"align" != 64 or release.attrs.is_volatile) return null;
    const ret = switch (exit.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 128 }) or !isNamed(ret.value orelse return null, old_name)) return null;
    return spinlock_symbol;
}

fn matchAtomicStoreScalar(function: ir.Function) !?u16 {
    if (function.ret_ty != .void or function.params.items.len != 3) return null;
    if (!function.params.items[0].ty.eql(.ptr) or !function.params.items[2].ty.eql(.{ .int = 32 })) return null;
    const bits = scalarAtomicCompareExchangeBits(function.params.items[1].ty) orelse return null;
    if (bits == 128) return null;
    if (function.blocks.items.len != 1) return null;
    if (!functionHasNoRemovedInstructions(function)) return null;

    const ptr_name = function.params.items[0].name;
    const value_name = function.params.items[1].name;
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 1) return null;
    const store = switch (entry.instructions.items[0].kind) {
        .store => |store| store,
        else => return null,
    };
    if (!store.ty.eql(.{ .int = bits }) or
        !isNamed(store.value, value_name) or
        !isNamed(store.ptr, ptr_name) or
        store.attrs.atomic_ordering == null or
        !std.mem.eql(u8, store.attrs.atomic_ordering.?, "seq_cst") or
        store.attrs.@"align" != bits / 8 or
        store.attrs.is_volatile) return null;
    const ret = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return null,
    };
    if (ret.ty != .void or ret.value != null) return null;
    return bits;
}

fn matchSpinlockedStoreI128(function: ir.Function) !?[]const u8 {
    if (function.ret_ty != .void or function.params.items.len != 3) return null;
    if (!function.params.items[0].ty.eql(.ptr) or
        !function.params.items[1].ty.eql(.{ .int = 128 }) or
        !function.params.items[2].ty.eql(.{ .int = 32 })) return null;
    if (function.blocks.items.len != 3) return null;
    if (!functionHasNoRemovedInstructions(function)) return null;

    const ptr_name = function.params.items[0].name;
    const value_name = function.params.items[1].name;
    const entry = function.blocks.items[0];
    const loop = function.blocks.items[1];
    const exit = function.blocks.items[2];
    if (entry.instructions.items.len != 4 or loop.instructions.items.len != 2 or exit.instructions.items.len != 2) return null;

    const ptr_int_name = entry.instructions.items[0].result orelse return null;
    const ptr_int = switch (entry.instructions.items[0].kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (ptr_int.op != .ptrtoint or !ptr_int.from_ty.eql(.ptr) or !ptr_int.to_ty.eql(.{ .int = 64 }) or !isNamed(ptr_int.value, ptr_name)) return null;
    const shifted_name = entry.instructions.items[1].result orelse return null;
    if (!matchI64BinaryNamedImm(entry.instructions.items[1], .lshr, ptr_int_name, 3)) return null;
    const slot_name = entry.instructions.items[2].result orelse return null;
    if (!matchI64BinaryNamedImm(entry.instructions.items[2], .@"and", shifted_name, 62)) return null;
    const lock_ptr_name = entry.instructions.items[3].result orelse return null;
    const spinlock_symbol = try matchSpinlockGep(entry.instructions.items[3], slot_name);
    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return null,
    };
    if (!std.mem.eql(u8, entry_br.target, loop.name)) return null;

    if (!matchSpinlockAcquireLoop(loop, lock_ptr_name, exit.name)) return null;

    const value_store = switch (exit.instructions.items[0].kind) {
        .store => |store| store,
        else => return null,
    };
    if (!value_store.ty.eql(.{ .int = 128 }) or !isNamed(value_store.value, value_name) or
        !isNamed(value_store.ptr, ptr_name) or value_store.attrs.isBarrier()) return null;
    const release = switch (exit.instructions.items[1].kind) {
        .store => |store| store,
        else => return null,
    };
    if (!release.ty.eql(.{ .int = 64 }) or !isInt(release.value, 0) or !isNamed(release.ptr, lock_ptr_name) or
        release.attrs.atomic_ordering == null or !std.mem.eql(u8, release.attrs.atomic_ordering.?, "release") or
        release.attrs.@"align" != 64 or release.attrs.is_volatile) return null;
    const ret = switch (exit.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return null,
    };
    if (ret.ty != .void or ret.value != null) return null;
    return spinlock_symbol;
}

fn matchAtomicLoadScalar(function: ir.Function) !?u16 {
    if (function.params.items.len != 2 or !function.params.items[0].ty.eql(.ptr) or !function.params.items[1].ty.eql(.{ .int = 32 })) return null;
    const bits = scalarAtomicCompareExchangeBits(function.ret_ty) orelse return null;
    if (bits == 128) return null;
    if (function.blocks.items.len != 1) return null;
    if (!functionHasNoRemovedInstructions(function)) return null;

    const ptr_name = function.params.items[0].name;
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 1) return null;
    const load_name = entry.instructions.items[0].result orelse return null;
    const load = switch (entry.instructions.items[0].kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = bits }) or
        !isNamed(load.ptr, ptr_name) or
        load.attrs.atomic_ordering == null or
        !std.mem.eql(u8, load.attrs.atomic_ordering.?, "seq_cst") or
        load.attrs.@"align" != bits / 8 or
        load.attrs.is_volatile) return null;
    const ret = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = bits }) or !isNamed(ret.value orelse return error.InvalidRet, load_name)) return null;
    return bits;
}

fn matchSpinlockedLoadI128(function: ir.Function) !?[]const u8 {
    if (!function.ret_ty.eql(.{ .int = 128 }) or function.params.items.len != 2) return null;
    if (!function.params.items[0].ty.eql(.ptr) or !function.params.items[1].ty.eql(.{ .int = 32 })) return null;
    if (function.blocks.items.len != 3) return null;
    if (!functionHasNoRemovedInstructions(function)) return null;

    const ptr_name = function.params.items[0].name;
    const entry = function.blocks.items[0];
    const loop = function.blocks.items[1];
    const exit = function.blocks.items[2];
    if (entry.instructions.items.len != 4 or loop.instructions.items.len != 2 or exit.instructions.items.len != 2) return null;

    const ptr_int_name = entry.instructions.items[0].result orelse return null;
    const ptr_int = switch (entry.instructions.items[0].kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (ptr_int.op != .ptrtoint or !ptr_int.from_ty.eql(.ptr) or !ptr_int.to_ty.eql(.{ .int = 64 }) or !isNamed(ptr_int.value, ptr_name)) return null;
    const shifted_name = entry.instructions.items[1].result orelse return null;
    if (!matchI64BinaryNamedImm(entry.instructions.items[1], .lshr, ptr_int_name, 3)) return null;
    const slot_name = entry.instructions.items[2].result orelse return null;
    if (!matchI64BinaryNamedImm(entry.instructions.items[2], .@"and", shifted_name, 62)) return null;
    const lock_ptr_name = entry.instructions.items[3].result orelse return null;
    const spinlock_symbol = try matchSpinlockGep(entry.instructions.items[3], slot_name);
    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return null,
    };
    if (!std.mem.eql(u8, entry_br.target, loop.name)) return null;

    if (!matchSpinlockAcquireLoop(loop, lock_ptr_name, exit.name)) return null;

    const load_name = exit.instructions.items[0].result orelse return null;
    const load = switch (exit.instructions.items[0].kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 128 }) or !isNamed(load.ptr, ptr_name) or load.attrs.isBarrier()) return null;
    const release = switch (exit.instructions.items[1].kind) {
        .store => |store| store,
        else => return null,
    };
    if (!release.ty.eql(.{ .int = 64 }) or !isInt(release.value, 0) or !isNamed(release.ptr, lock_ptr_name) or
        release.attrs.atomic_ordering == null or !std.mem.eql(u8, release.attrs.atomic_ordering.?, "release") or
        release.attrs.@"align" != 64 or release.attrs.is_volatile) return null;
    const ret = switch (exit.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 128 }) or !isNamed(ret.value orelse return error.InvalidRet, load_name)) return null;
    return spinlock_symbol;
}

fn matchAtomicFetchUminScalar(function: ir.Function) !?u16 {
    return matchAtomicFetchScalar(function, "umin");
}

fn matchAtomicFetchUmaxScalar(function: ir.Function) !?u16 {
    return matchAtomicFetchScalar(function, "umax");
}

fn matchAtomicFetchNandScalar(function: ir.Function) !?u16 {
    return matchAtomicFetchScalar(function, "nand");
}

fn matchAtomicFetchXorScalar(function: ir.Function) !?u16 {
    return matchAtomicFetchScalar(function, "xor");
}

fn matchAtomicFetchOrScalar(function: ir.Function) !?u16 {
    return matchAtomicFetchScalar(function, "or");
}

fn matchAtomicFetchAndScalar(function: ir.Function) !?u16 {
    return matchAtomicFetchScalar(function, "and");
}

fn matchAtomicFetchSubScalar(function: ir.Function) !?u16 {
    return matchAtomicFetchScalar(function, "sub");
}

fn matchAtomicFetchAddScalar(function: ir.Function) !?u16 {
    return matchAtomicFetchScalar(function, "add");
}

fn matchAtomicFetchScalar(function: ir.Function, op: []const u8) !?u16 {
    if (function.params.items.len != 3 or !function.params.items[0].ty.eql(.ptr) or !function.params.items[2].ty.eql(.{ .int = 32 })) return null;
    const bits = scalarAtomicCompareExchangeBits(function.ret_ty) orelse return null;
    if (bits == 128 or !function.params.items[1].ty.eql(.{ .int = bits })) return null;
    if (function.blocks.items.len != 1) return null;
    if (!functionHasNoRemovedInstructions(function)) return null;

    const ptr_name = function.params.items[0].name;
    const value_name = function.params.items[1].name;
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 1) return null;
    const atomic_name = entry.instructions.items[0].result orelse return null;
    const atomic = switch (entry.instructions.items[0].kind) {
        .atomicrmw => |atomicrmw| atomicrmw,
        else => return null,
    };
    if (!std.mem.eql(u8, atomic.op, op) or !atomic.ty.eql(.{ .int = bits }) or
        !isNamed(atomic.ptr, ptr_name) or !isNamed(atomic.value, value_name) or
        !std.mem.eql(u8, atomic.ordering, "seq_cst") or atomic.syncscope != null or
        atomic.is_volatile or atomic.@"align" != bits / 8) return null;
    const ret = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = bits }) or !isNamed(ret.value orelse return error.InvalidRet, atomic_name)) return null;
    return bits;
}

fn matchSpinlockedFetchUminI128(function: ir.Function) !?[]const u8 {
    return matchSpinlockedFetchExtremumI128(function, "llvm.umin.i128");
}

fn matchSpinlockedFetchUmaxI128(function: ir.Function) !?[]const u8 {
    return matchSpinlockedFetchExtremumI128(function, "llvm.umax.i128");
}

fn matchSpinlockedFetchNandI128(function: ir.Function) !?[]const u8 {
    if (!function.ret_ty.eql(.{ .int = 128 }) or function.params.items.len != 3) return null;
    if (!function.params.items[0].ty.eql(.ptr) or
        !function.params.items[1].ty.eql(.{ .int = 128 }) or
        !function.params.items[2].ty.eql(.{ .int = 32 })) return null;
    if (function.blocks.items.len != 3) return null;
    if (!functionHasNoRemovedInstructions(function)) return null;

    const ptr_name = function.params.items[0].name;
    const value_name = function.params.items[1].name;
    const entry = function.blocks.items[0];
    const loop = function.blocks.items[1];
    const exit = function.blocks.items[2];
    if (entry.instructions.items.len != 4 or loop.instructions.items.len != 2 or exit.instructions.items.len != 5) return null;

    const ptr_int_name = entry.instructions.items[0].result orelse return null;
    const ptr_int = switch (entry.instructions.items[0].kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (ptr_int.op != .ptrtoint or !ptr_int.from_ty.eql(.ptr) or !ptr_int.to_ty.eql(.{ .int = 64 }) or !isNamed(ptr_int.value, ptr_name)) return null;
    const shifted_name = entry.instructions.items[1].result orelse return null;
    if (!matchI64BinaryNamedImm(entry.instructions.items[1], .lshr, ptr_int_name, 3)) return null;
    const slot_name = entry.instructions.items[2].result orelse return null;
    if (!matchI64BinaryNamedImm(entry.instructions.items[2], .@"and", shifted_name, 62)) return null;
    const lock_ptr_name = entry.instructions.items[3].result orelse return null;
    const spinlock_symbol = try matchSpinlockGep(entry.instructions.items[3], slot_name);
    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return null,
    };
    if (!std.mem.eql(u8, entry_br.target, loop.name)) return null;

    if (!matchSpinlockAcquireLoop(loop, lock_ptr_name, exit.name)) return null;

    const old_name = exit.instructions.items[0].result orelse return null;
    const old_load = switch (exit.instructions.items[0].kind) {
        .load => |load| load,
        else => return null,
    };
    if (!old_load.ty.eql(.{ .int = 128 }) or !isNamed(old_load.ptr, ptr_name) or old_load.attrs.isBarrier()) return null;
    const and_name = exit.instructions.items[1].result orelse return null;
    const and_inst = switch (exit.instructions.items[1].kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (and_inst.op != .@"and" or !and_inst.ty.eql(.{ .int = 128 }) or
        !isNamed(and_inst.lhs, old_name) or !isNamed(and_inst.rhs, value_name)) return null;
    const nand_name = exit.instructions.items[2].result orelse return null;
    const xor_inst = switch (exit.instructions.items[2].kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (xor_inst.op != .xor or !xor_inst.ty.eql(.{ .int = 128 }) or
        !isNamed(xor_inst.lhs, and_name) or !isInt(xor_inst.rhs, -1)) return null;
    const value_store = switch (exit.instructions.items[3].kind) {
        .store => |store| store,
        else => return null,
    };
    if (!value_store.ty.eql(.{ .int = 128 }) or !isNamed(value_store.value, nand_name) or
        !isNamed(value_store.ptr, ptr_name) or value_store.attrs.isBarrier()) return null;
    const release = switch (exit.instructions.items[4].kind) {
        .store => |store| store,
        else => return null,
    };
    if (!release.ty.eql(.{ .int = 64 }) or !isInt(release.value, 0) or !isNamed(release.ptr, lock_ptr_name) or
        release.attrs.atomic_ordering == null or !std.mem.eql(u8, release.attrs.atomic_ordering.?, "release") or
        release.attrs.@"align" != 64 or release.attrs.is_volatile) return null;
    const ret = switch (exit.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 128 }) or !isNamed(ret.value orelse return error.InvalidRet, old_name)) return null;
    return spinlock_symbol;
}

fn matchSpinlockedFetchXorI128(function: ir.Function) !?[]const u8 {
    if (!function.ret_ty.eql(.{ .int = 128 }) or function.params.items.len != 3) return null;
    if (!function.params.items[0].ty.eql(.ptr) or
        !function.params.items[1].ty.eql(.{ .int = 128 }) or
        !function.params.items[2].ty.eql(.{ .int = 32 })) return null;
    if (function.blocks.items.len != 3) return null;
    if (!functionHasNoRemovedInstructions(function)) return null;

    const ptr_name = function.params.items[0].name;
    const value_name = function.params.items[1].name;
    const entry = function.blocks.items[0];
    const loop = function.blocks.items[1];
    const exit = function.blocks.items[2];
    if (entry.instructions.items.len != 4 or loop.instructions.items.len != 2 or exit.instructions.items.len != 4) return null;

    const ptr_int_name = entry.instructions.items[0].result orelse return null;
    const ptr_int = switch (entry.instructions.items[0].kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (ptr_int.op != .ptrtoint or !ptr_int.from_ty.eql(.ptr) or !ptr_int.to_ty.eql(.{ .int = 64 }) or !isNamed(ptr_int.value, ptr_name)) return null;
    const shifted_name = entry.instructions.items[1].result orelse return null;
    if (!matchI64BinaryNamedImm(entry.instructions.items[1], .lshr, ptr_int_name, 3)) return null;
    const slot_name = entry.instructions.items[2].result orelse return null;
    if (!matchI64BinaryNamedImm(entry.instructions.items[2], .@"and", shifted_name, 62)) return null;
    const lock_ptr_name = entry.instructions.items[3].result orelse return null;
    const spinlock_symbol = try matchSpinlockGep(entry.instructions.items[3], slot_name);
    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return null,
    };
    if (!std.mem.eql(u8, entry_br.target, loop.name)) return null;

    if (!matchSpinlockAcquireLoop(loop, lock_ptr_name, exit.name)) return null;

    const old_name = exit.instructions.items[0].result orelse return null;
    const old_load = switch (exit.instructions.items[0].kind) {
        .load => |load| load,
        else => return null,
    };
    if (!old_load.ty.eql(.{ .int = 128 }) or !isNamed(old_load.ptr, ptr_name) or old_load.attrs.isBarrier()) return null;
    const xor_name = exit.instructions.items[1].result orelse return null;
    const xor_inst = switch (exit.instructions.items[1].kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (xor_inst.op != .xor or !xor_inst.ty.eql(.{ .int = 128 }) or
        !isNamed(xor_inst.lhs, old_name) or !isNamed(xor_inst.rhs, value_name)) return null;
    const value_store = switch (exit.instructions.items[2].kind) {
        .store => |store| store,
        else => return null,
    };
    if (!value_store.ty.eql(.{ .int = 128 }) or !isNamed(value_store.value, xor_name) or
        !isNamed(value_store.ptr, ptr_name) or value_store.attrs.isBarrier()) return null;
    const release = switch (exit.instructions.items[3].kind) {
        .store => |store| store,
        else => return null,
    };
    if (!release.ty.eql(.{ .int = 64 }) or !isInt(release.value, 0) or !isNamed(release.ptr, lock_ptr_name) or
        release.attrs.atomic_ordering == null or !std.mem.eql(u8, release.attrs.atomic_ordering.?, "release") or
        release.attrs.@"align" != 64 or release.attrs.is_volatile) return null;
    const ret = switch (exit.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 128 }) or !isNamed(ret.value orelse return error.InvalidRet, old_name)) return null;
    return spinlock_symbol;
}

fn matchSpinlockedFetchOrI128(function: ir.Function) !?[]const u8 {
    if (!function.ret_ty.eql(.{ .int = 128 }) or function.params.items.len != 3) return null;
    if (!function.params.items[0].ty.eql(.ptr) or
        !function.params.items[1].ty.eql(.{ .int = 128 }) or
        !function.params.items[2].ty.eql(.{ .int = 32 })) return null;
    if (function.blocks.items.len != 3) return null;
    if (!functionHasNoRemovedInstructions(function)) return null;

    const ptr_name = function.params.items[0].name;
    const value_name = function.params.items[1].name;
    const entry = function.blocks.items[0];
    const loop = function.blocks.items[1];
    const exit = function.blocks.items[2];
    if (entry.instructions.items.len != 4 or loop.instructions.items.len != 2 or exit.instructions.items.len != 4) return null;

    const ptr_int_name = entry.instructions.items[0].result orelse return null;
    const ptr_int = switch (entry.instructions.items[0].kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (ptr_int.op != .ptrtoint or !ptr_int.from_ty.eql(.ptr) or !ptr_int.to_ty.eql(.{ .int = 64 }) or !isNamed(ptr_int.value, ptr_name)) return null;
    const shifted_name = entry.instructions.items[1].result orelse return null;
    if (!matchI64BinaryNamedImm(entry.instructions.items[1], .lshr, ptr_int_name, 3)) return null;
    const slot_name = entry.instructions.items[2].result orelse return null;
    if (!matchI64BinaryNamedImm(entry.instructions.items[2], .@"and", shifted_name, 62)) return null;
    const lock_ptr_name = entry.instructions.items[3].result orelse return null;
    const spinlock_symbol = try matchSpinlockGep(entry.instructions.items[3], slot_name);
    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return null,
    };
    if (!std.mem.eql(u8, entry_br.target, loop.name)) return null;

    if (!matchSpinlockAcquireLoop(loop, lock_ptr_name, exit.name)) return null;

    const old_name = exit.instructions.items[0].result orelse return null;
    const old_load = switch (exit.instructions.items[0].kind) {
        .load => |load| load,
        else => return null,
    };
    if (!old_load.ty.eql(.{ .int = 128 }) or !isNamed(old_load.ptr, ptr_name) or old_load.attrs.isBarrier()) return null;
    const or_name = exit.instructions.items[1].result orelse return null;
    const or_inst = switch (exit.instructions.items[1].kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (or_inst.op != .@"or" or !or_inst.ty.eql(.{ .int = 128 }) or
        !isNamed(or_inst.lhs, old_name) or !isNamed(or_inst.rhs, value_name)) return null;
    const value_store = switch (exit.instructions.items[2].kind) {
        .store => |store| store,
        else => return null,
    };
    if (!value_store.ty.eql(.{ .int = 128 }) or !isNamed(value_store.value, or_name) or
        !isNamed(value_store.ptr, ptr_name) or value_store.attrs.isBarrier()) return null;
    const release = switch (exit.instructions.items[3].kind) {
        .store => |store| store,
        else => return null,
    };
    if (!release.ty.eql(.{ .int = 64 }) or !isInt(release.value, 0) or !isNamed(release.ptr, lock_ptr_name) or
        release.attrs.atomic_ordering == null or !std.mem.eql(u8, release.attrs.atomic_ordering.?, "release") or
        release.attrs.@"align" != 64 or release.attrs.is_volatile) return null;
    const ret = switch (exit.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 128 }) or !isNamed(ret.value orelse return error.InvalidRet, old_name)) return null;
    return spinlock_symbol;
}

fn matchSpinlockedFetchAndI128(function: ir.Function) !?[]const u8 {
    if (!function.ret_ty.eql(.{ .int = 128 }) or function.params.items.len != 3) return null;
    if (!function.params.items[0].ty.eql(.ptr) or
        !function.params.items[1].ty.eql(.{ .int = 128 }) or
        !function.params.items[2].ty.eql(.{ .int = 32 })) return null;
    if (function.blocks.items.len != 3) return null;
    if (!functionHasNoRemovedInstructions(function)) return null;

    const ptr_name = function.params.items[0].name;
    const value_name = function.params.items[1].name;
    const entry = function.blocks.items[0];
    const loop = function.blocks.items[1];
    const exit = function.blocks.items[2];
    if (entry.instructions.items.len != 4 or loop.instructions.items.len != 2 or exit.instructions.items.len != 4) return null;

    const ptr_int_name = entry.instructions.items[0].result orelse return null;
    const ptr_int = switch (entry.instructions.items[0].kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (ptr_int.op != .ptrtoint or !ptr_int.from_ty.eql(.ptr) or !ptr_int.to_ty.eql(.{ .int = 64 }) or !isNamed(ptr_int.value, ptr_name)) return null;
    const shifted_name = entry.instructions.items[1].result orelse return null;
    if (!matchI64BinaryNamedImm(entry.instructions.items[1], .lshr, ptr_int_name, 3)) return null;
    const slot_name = entry.instructions.items[2].result orelse return null;
    if (!matchI64BinaryNamedImm(entry.instructions.items[2], .@"and", shifted_name, 62)) return null;
    const lock_ptr_name = entry.instructions.items[3].result orelse return null;
    const spinlock_symbol = try matchSpinlockGep(entry.instructions.items[3], slot_name);
    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return null,
    };
    if (!std.mem.eql(u8, entry_br.target, loop.name)) return null;

    if (!matchSpinlockAcquireLoop(loop, lock_ptr_name, exit.name)) return null;

    const old_name = exit.instructions.items[0].result orelse return null;
    const old_load = switch (exit.instructions.items[0].kind) {
        .load => |load| load,
        else => return null,
    };
    if (!old_load.ty.eql(.{ .int = 128 }) or !isNamed(old_load.ptr, ptr_name) or old_load.attrs.isBarrier()) return null;
    const and_name = exit.instructions.items[1].result orelse return null;
    const and_inst = switch (exit.instructions.items[1].kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (and_inst.op != .@"and" or !and_inst.ty.eql(.{ .int = 128 }) or
        !isNamed(and_inst.lhs, old_name) or !isNamed(and_inst.rhs, value_name)) return null;
    const value_store = switch (exit.instructions.items[2].kind) {
        .store => |store| store,
        else => return null,
    };
    if (!value_store.ty.eql(.{ .int = 128 }) or !isNamed(value_store.value, and_name) or
        !isNamed(value_store.ptr, ptr_name) or value_store.attrs.isBarrier()) return null;
    const release = switch (exit.instructions.items[3].kind) {
        .store => |store| store,
        else => return null,
    };
    if (!release.ty.eql(.{ .int = 64 }) or !isInt(release.value, 0) or !isNamed(release.ptr, lock_ptr_name) or
        release.attrs.atomic_ordering == null or !std.mem.eql(u8, release.attrs.atomic_ordering.?, "release") or
        release.attrs.@"align" != 64 or release.attrs.is_volatile) return null;
    const ret = switch (exit.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 128 }) or !isNamed(ret.value orelse return error.InvalidRet, old_name)) return null;
    return spinlock_symbol;
}

fn matchSpinlockedFetchSubI128(function: ir.Function) !?[]const u8 {
    if (!function.ret_ty.eql(.{ .int = 128 }) or function.params.items.len != 3) return null;
    if (!function.params.items[0].ty.eql(.ptr) or
        !function.params.items[1].ty.eql(.{ .int = 128 }) or
        !function.params.items[2].ty.eql(.{ .int = 32 })) return null;
    if (function.blocks.items.len != 3) return null;
    if (!functionHasNoRemovedInstructions(function)) return null;

    const ptr_name = function.params.items[0].name;
    const value_name = function.params.items[1].name;
    const entry = function.blocks.items[0];
    const loop = function.blocks.items[1];
    const exit = function.blocks.items[2];
    if (entry.instructions.items.len != 4 or loop.instructions.items.len != 2 or exit.instructions.items.len != 4) return null;

    const ptr_int_name = entry.instructions.items[0].result orelse return null;
    const ptr_int = switch (entry.instructions.items[0].kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (ptr_int.op != .ptrtoint or !ptr_int.from_ty.eql(.ptr) or !ptr_int.to_ty.eql(.{ .int = 64 }) or !isNamed(ptr_int.value, ptr_name)) return null;
    const shifted_name = entry.instructions.items[1].result orelse return null;
    if (!matchI64BinaryNamedImm(entry.instructions.items[1], .lshr, ptr_int_name, 3)) return null;
    const slot_name = entry.instructions.items[2].result orelse return null;
    if (!matchI64BinaryNamedImm(entry.instructions.items[2], .@"and", shifted_name, 62)) return null;
    const lock_ptr_name = entry.instructions.items[3].result orelse return null;
    const spinlock_symbol = try matchSpinlockGep(entry.instructions.items[3], slot_name);
    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return null,
    };
    if (!std.mem.eql(u8, entry_br.target, loop.name)) return null;

    if (!matchSpinlockAcquireLoop(loop, lock_ptr_name, exit.name)) return null;

    const old_name = exit.instructions.items[0].result orelse return null;
    const old_load = switch (exit.instructions.items[0].kind) {
        .load => |load| load,
        else => return null,
    };
    if (!old_load.ty.eql(.{ .int = 128 }) or !isNamed(old_load.ptr, ptr_name) or old_load.attrs.isBarrier()) return null;
    const sub_name = exit.instructions.items[1].result orelse return null;
    const sub_inst = switch (exit.instructions.items[1].kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (sub_inst.op != .sub or !sub_inst.ty.eql(.{ .int = 128 }) or
        !isNamed(sub_inst.lhs, old_name) or !isNamed(sub_inst.rhs, value_name)) return null;
    const value_store = switch (exit.instructions.items[2].kind) {
        .store => |store| store,
        else => return null,
    };
    if (!value_store.ty.eql(.{ .int = 128 }) or !isNamed(value_store.value, sub_name) or
        !isNamed(value_store.ptr, ptr_name) or value_store.attrs.isBarrier()) return null;
    const release = switch (exit.instructions.items[3].kind) {
        .store => |store| store,
        else => return null,
    };
    if (!release.ty.eql(.{ .int = 64 }) or !isInt(release.value, 0) or !isNamed(release.ptr, lock_ptr_name) or
        release.attrs.atomic_ordering == null or !std.mem.eql(u8, release.attrs.atomic_ordering.?, "release") or
        release.attrs.@"align" != 64 or release.attrs.is_volatile) return null;
    const ret = switch (exit.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 128 }) or !isNamed(ret.value orelse return error.InvalidRet, old_name)) return null;
    return spinlock_symbol;
}

fn matchSpinlockedFetchAddI128(function: ir.Function) !?[]const u8 {
    if (!function.ret_ty.eql(.{ .int = 128 }) or function.params.items.len != 3) return null;
    if (!function.params.items[0].ty.eql(.ptr) or
        !function.params.items[1].ty.eql(.{ .int = 128 }) or
        !function.params.items[2].ty.eql(.{ .int = 32 })) return null;
    if (function.blocks.items.len != 3) return null;
    if (!functionHasNoRemovedInstructions(function)) return null;

    const ptr_name = function.params.items[0].name;
    const value_name = function.params.items[1].name;
    const entry = function.blocks.items[0];
    const loop = function.blocks.items[1];
    const exit = function.blocks.items[2];
    if (entry.instructions.items.len != 4 or loop.instructions.items.len != 2 or exit.instructions.items.len != 4) return null;

    const ptr_int_name = entry.instructions.items[0].result orelse return null;
    const ptr_int = switch (entry.instructions.items[0].kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (ptr_int.op != .ptrtoint or !ptr_int.from_ty.eql(.ptr) or !ptr_int.to_ty.eql(.{ .int = 64 }) or !isNamed(ptr_int.value, ptr_name)) return null;
    const shifted_name = entry.instructions.items[1].result orelse return null;
    if (!matchI64BinaryNamedImm(entry.instructions.items[1], .lshr, ptr_int_name, 3)) return null;
    const slot_name = entry.instructions.items[2].result orelse return null;
    if (!matchI64BinaryNamedImm(entry.instructions.items[2], .@"and", shifted_name, 62)) return null;
    const lock_ptr_name = entry.instructions.items[3].result orelse return null;
    const spinlock_symbol = try matchSpinlockGep(entry.instructions.items[3], slot_name);
    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return null,
    };
    if (!std.mem.eql(u8, entry_br.target, loop.name)) return null;

    if (!matchSpinlockAcquireLoop(loop, lock_ptr_name, exit.name)) return null;

    const old_name = exit.instructions.items[0].result orelse return null;
    const old_load = switch (exit.instructions.items[0].kind) {
        .load => |load| load,
        else => return null,
    };
    if (!old_load.ty.eql(.{ .int = 128 }) or !isNamed(old_load.ptr, ptr_name) or old_load.attrs.isBarrier()) return null;
    const add_name = exit.instructions.items[1].result orelse return null;
    const add_inst = switch (exit.instructions.items[1].kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (add_inst.op != .add or !add_inst.ty.eql(.{ .int = 128 }) or
        !isNamed(add_inst.lhs, old_name) or !isNamed(add_inst.rhs, value_name)) return null;
    const value_store = switch (exit.instructions.items[2].kind) {
        .store => |store| store,
        else => return null,
    };
    if (!value_store.ty.eql(.{ .int = 128 }) or !isNamed(value_store.value, add_name) or
        !isNamed(value_store.ptr, ptr_name) or value_store.attrs.isBarrier()) return null;
    const release = switch (exit.instructions.items[3].kind) {
        .store => |store| store,
        else => return null,
    };
    if (!release.ty.eql(.{ .int = 64 }) or !isInt(release.value, 0) or !isNamed(release.ptr, lock_ptr_name) or
        release.attrs.atomic_ordering == null or !std.mem.eql(u8, release.attrs.atomic_ordering.?, "release") or
        release.attrs.@"align" != 64 or release.attrs.is_volatile) return null;
    const ret = switch (exit.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 128 }) or !isNamed(ret.value orelse return error.InvalidRet, old_name)) return null;
    return spinlock_symbol;
}

fn matchSpinlockedFetchExtremumI128(function: ir.Function, callee: []const u8) !?[]const u8 {
    if (!function.ret_ty.eql(.{ .int = 128 }) or function.params.items.len != 3) return null;
    if (!function.params.items[0].ty.eql(.ptr) or
        !function.params.items[1].ty.eql(.{ .int = 128 }) or
        !function.params.items[2].ty.eql(.{ .int = 32 })) return null;
    if (function.blocks.items.len != 3) return null;
    if (!functionHasNoRemovedInstructions(function)) return null;

    const ptr_name = function.params.items[0].name;
    const value_name = function.params.items[1].name;
    const entry = function.blocks.items[0];
    const loop = function.blocks.items[1];
    const exit = function.blocks.items[2];
    if (entry.instructions.items.len != 4 or loop.instructions.items.len != 2 or exit.instructions.items.len != 4) return null;

    const ptr_int_name = entry.instructions.items[0].result orelse return null;
    const ptr_int = switch (entry.instructions.items[0].kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (ptr_int.op != .ptrtoint or !ptr_int.from_ty.eql(.ptr) or !ptr_int.to_ty.eql(.{ .int = 64 }) or !isNamed(ptr_int.value, ptr_name)) return null;
    const shifted_name = entry.instructions.items[1].result orelse return null;
    if (!matchI64BinaryNamedImm(entry.instructions.items[1], .lshr, ptr_int_name, 3)) return null;
    const slot_name = entry.instructions.items[2].result orelse return null;
    if (!matchI64BinaryNamedImm(entry.instructions.items[2], .@"and", shifted_name, 62)) return null;
    const lock_ptr_name = entry.instructions.items[3].result orelse return null;
    const spinlock_symbol = try matchSpinlockGep(entry.instructions.items[3], slot_name);
    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return null,
    };
    if (!std.mem.eql(u8, entry_br.target, loop.name)) return null;

    if (!matchSpinlockAcquireLoop(loop, lock_ptr_name, exit.name)) return null;

    const old_name = exit.instructions.items[0].result orelse return null;
    const old_load = switch (exit.instructions.items[0].kind) {
        .load => |load| load,
        else => return null,
    };
    if (!old_load.ty.eql(.{ .int = 128 }) or !isNamed(old_load.ptr, ptr_name) or old_load.attrs.isBarrier()) return null;
    const min_name = exit.instructions.items[1].result orelse return null;
    const min_call = switch (exit.instructions.items[1].kind) {
        .call => |call| call,
        else => return null,
    };
    if (min_call.callee_value != null or min_call.inline_asm != null or !min_call.ret_ty.eql(.{ .int = 128 }) or
        min_call.args.items.len != 2 or !isCalleeName(min_call.callee, callee) or
        !min_call.args.items[0].ty.eql(.{ .int = 128 }) or !isNamed(min_call.args.items[0].value, old_name) or
        !min_call.args.items[1].ty.eql(.{ .int = 128 }) or !isNamed(min_call.args.items[1].value, value_name)) return null;
    const value_store = switch (exit.instructions.items[2].kind) {
        .store => |store| store,
        else => return null,
    };
    if (!value_store.ty.eql(.{ .int = 128 }) or !isNamed(value_store.value, min_name) or
        !isNamed(value_store.ptr, ptr_name) or value_store.attrs.isBarrier()) return null;
    const release = switch (exit.instructions.items[3].kind) {
        .store => |store| store,
        else => return null,
    };
    if (!release.ty.eql(.{ .int = 64 }) or !isInt(release.value, 0) or !isNamed(release.ptr, lock_ptr_name) or
        release.attrs.atomic_ordering == null or !std.mem.eql(u8, release.attrs.atomic_ordering.?, "release") or
        release.attrs.@"align" != 64 or release.attrs.is_volatile) return null;
    const ret = switch (exit.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 128 }) or !isNamed(ret.value orelse return error.InvalidRet, old_name)) return null;
    return spinlock_symbol;
}
