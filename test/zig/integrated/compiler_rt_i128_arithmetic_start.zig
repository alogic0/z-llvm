extern fn __multi3(i128, i128) callconv(.c) i128;
extern fn __modti3(i128, i128) callconv(.c) i128;
extern fn zllvm_ne_zero_i16(u32) callconv(.c) u32;
extern fn zllvm_store_i32_index([*]u32, u64, u32) callconv(.c) u32;
extern fn zllvm_load_i32_index([*]u32, u64) callconv(.c) u32;
extern fn zllvm_ptr_eq([*]u32, [*]u32) callconv(.c) u32;
extern fn zllvm_load_i32_spilled_ptr([*]u32) callconv(.c) u32;
extern fn zllvm_backward_layout_phi(u32) callconv(.c) u32;
extern fn zllvm_ugt_i64(u64, u64) callconv(.c) u32;
extern fn zllvm_ugt_i64_imm(u64) callconv(.c) u32;
extern fn zllvm_nonnegative_i6(u32) callconv(.c) u32;
extern fn zllvm_negative_i64(i64) callconv(.c) u32;
extern fn zllvm_ne_zero_i64(i64) callconv(.c) u32;
extern fn zllvm_ctlz_i32(u32) callconv(.c) u32;

var multi_lhs: i128 = 4294967299;
var multi_rhs: i128 = -8589934597;
var mod_lhs: i128 = 123456789;
var mod_rhs: i128 = 4294967299;
var predicate_zero: u32 = 65536;
var predicate_nonzero: u32 = 65537;
var element_values = [3]u32{ 11, 22, 33 };
var spill_values = [7]u32{ 10, 20, 30, 40, 50, 60, 70 };

const expected_product: i128 = -36893488194663743503;
const expected_remainder: i128 = 123456789;

pub export fn _start() callconv(.c) noreturn {
    @setRuntimeSafety(false);

    const product = __multi3(loadI128(&multi_lhs), loadI128(&multi_rhs));
    const remainder = __modti3(loadI128(&mod_lhs), loadI128(&mod_rhs));

    const product_bad: usize = @intFromBool(product != expected_product);
    const remainder_bad: usize = @intFromBool(remainder != expected_remainder);
    const ne_zero_bad: usize = @intFromBool(zllvm_ne_zero_i16(loadU32(&predicate_zero)) != 0);
    const ne_nonzero_bad: usize = @intFromBool(zllvm_ne_zero_i16(loadU32(&predicate_nonzero)) != 1);
    const stored = zllvm_store_i32_index(&element_values, 1, 99);
    const loaded = zllvm_load_i32_index(&element_values, 1);
    const gep_bad: usize = @intFromBool(stored != 99 or loaded != 99 or element_values[0] != 11 or element_values[1] != 99 or element_values[2] != 33);
    const element_ptr: [*]u32 = &element_values;
    const ptr_eq_bad: usize = @intFromBool(zllvm_ptr_eq(element_ptr, element_ptr) != 1);
    const ptr_ne_bad: usize = @intFromBool(zllvm_ptr_eq(element_ptr, element_ptr + 1) != 0);
    const spilled_loaded = zllvm_load_i32_spilled_ptr(&spill_values);
    const spill_load_bad: usize = @intFromBool(spilled_loaded != 76 or spill_values[0] != 10 or spill_values[1] != 20 or spill_values[2] != 30 or spill_values[3] != 40 or spill_values[4] != 50 or spill_values[5] != 60 or spill_values[6] != 70);
    const phi_bad: usize = @intFromBool(zllvm_backward_layout_phi(41) != 42);
    const ugt_true_bad: usize = @intFromBool(zllvm_ugt_i64(9, 4) != 1);
    const ugt_false_bad: usize = @intFromBool(zllvm_ugt_i64(4, 9) != 0);
    const i6_positive_bad: usize = @intFromBool(zllvm_nonnegative_i6(31) != 1);
    const i6_negative_bad: usize = @intFromBool(zllvm_nonnegative_i6(32) != 0);
    const ugt_imm_true_bad: usize = @intFromBool(zllvm_ugt_i64_imm(4294967296) != 1);
    const ugt_imm_false_bad: usize = @intFromBool(zllvm_ugt_i64_imm(4294967295) != 0);
    const negative_true_bad: usize = @intFromBool(zllvm_negative_i64(-1) != 1);
    const negative_false_bad: usize = @intFromBool(zllvm_negative_i64(0) != 0);
    const ne64_true_bad: usize = @intFromBool(zllvm_ne_zero_i64(1) != 1);
    const ne64_false_bad: usize = @intFromBool(zllvm_ne_zero_i64(0) != 0);
    const ctlz_one_bad: usize = @intFromBool(zllvm_ctlz_i32(1) != 31);
    const ctlz_sixteen_bad: usize = @intFromBool(zllvm_ctlz_i32(16) != 27);
    exit(product_bad * 11 + remainder_bad * 12 + ne_zero_bad * 13 + ne_nonzero_bad * 14 + gep_bad * 15 + ptr_eq_bad * 16 + ptr_ne_bad * 17 + spill_load_bad * 18 + phi_bad * 19 + ugt_true_bad * 20 + ugt_false_bad * 21 + i6_positive_bad * 22 + i6_negative_bad * 23 + ugt_imm_true_bad * 24 + ugt_imm_false_bad * 25 + negative_true_bad * 26 + negative_false_bad * 27 + ne64_true_bad * 28 + ne64_false_bad * 29 + ctlz_one_bad * 30 + ctlz_sixteen_bad * 31);
}

fn loadI128(ptr: *i128) i128 {
    return @as(*volatile i128, @ptrCast(ptr)).*;
}

fn loadU32(ptr: *u32) u32 {
    return @as(*volatile u32, @ptrCast(ptr)).*;
}

fn exit(code: usize) noreturn {
    _ = syscall1(60, code);
    @setRuntimeSafety(false);
    unreachable;
}

fn syscall1(number: usize, arg1: usize) usize {
    return asm volatile (
        \\syscall
        : [ret] "={rax}" (-> usize),
        : [number] "{rax}" (number),
          [arg1] "{rdi}" (arg1),
        : .{ .rcx = true, .r11 = true, .memory = true });
}
