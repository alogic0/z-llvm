extern fn __multi3(i128, i128) callconv(.c) i128;
extern fn __modti3(i128, i128) callconv(.c) i128;
extern fn zllvm_freeze_i128(i128) callconv(.c) i128;
extern fn zllvm_ne_zero_i16(u32) callconv(.c) u32;
extern fn zllvm_store_i32_index([*]u32, u64, u32) callconv(.c) u32;
extern fn zllvm_load_i32_index([*]u32, u64) callconv(.c) u32;
extern fn zllvm_ptr_eq([*]u32, [*]u32) callconv(.c) u32;
extern fn zllvm_load_i32_spilled_ptr([*]u32) callconv(.c) u32;
extern fn zllvm_store_i32_spilled_ptr([*]u32, u32) callconv(.c) u32;
extern fn zllvm_store_array_base(u32) callconv(.c) u32;
extern fn zllvm_select_shifted(u32, u32, u32) callconv(.c) u32;
extern fn zllvm_or_i64_imm(u64) callconv(.c) u64;
extern fn zllvm_stack_index_dependency(u64, u32, u32) callconv(.c) u32;
extern fn zllvm_sub_rhs_accumulator(u64, u64, u64) callconv(.c) u64;
extern fn zllvm_sum_loaded_i32([*]u32, u64) callconv(.c) u64;
extern fn zllvm_add_truncated_rhs(u32, u64) callconv(.c) u32;
extern fn zllvm_double_use(u32, u32) callconv(.c) u32;
extern fn zllvm_inline_memcpy([*]u32, [*]u32, u64) callconv(.c) void;
extern fn zllvm_spilled_trunc_after_memcpy([*]u32, [*]u32, u64, u32) callconv(.c) u32;
extern fn zllvm_framed_early_return(u64, u32) callconv(.c) u32;
extern fn zllvm_branch_chain_65(u32) callconv(.c) u32;
extern fn zllvm_backward_layout_phi(u32) callconv(.c) u32;
extern fn zllvm_ugt_i64(u64, u64) callconv(.c) u32;
extern fn zllvm_ugt_i64_imm(u64) callconv(.c) u32;
extern fn zllvm_nonnegative_i6(u32) callconv(.c) u32;
extern fn zllvm_negative_i64(i64) callconv(.c) u32;
extern fn zllvm_negative_i32(i32) callconv(.c) u32;
extern fn zllvm_nonnegative_i32(i32) callconv(.c) u32;
extern fn zllvm_stack_i1_roundtrip(u32) callconv(.c) u32;
extern fn zllvm_xor_i32_ones(u32) callconv(.c) u32;
extern fn zllvm_and_i8_one(u32) callconv(.c) u32;
extern fn zllvm_byte_array_gep_eq([*]u8, [*]u8, u64) callconv(.c) u32;
extern fn zllvm_select_ptr_eq(u32, [*]u8, [*]u8, [*]u8) callconv(.c) u32;
extern fn zllvm_ne_zero_i64(i64) callconv(.c) u32;
extern fn zllvm_ctlz_i32(u32) callconv(.c) u32;
extern fn zllvm_sub_i6(u32) callconv(.c) u32;
extern fn zllvm_spilled_cond(u32) callconv(.c) u32;
extern fn zllvm_variable_shl_i32(u32, u32) callconv(.c) u32;
extern fn zllvm_variable_lshr_i32(u32, u32) callconv(.c) u32;
extern fn zllvm_stack_byte_gep(u64, u32) callconv(.c) u32;
extern fn zllvm_stack_chained_gep(u64, u64, u32) callconv(.c) u32;
extern fn zllvm_stack_element_gep(u64, u32) callconv(.c) u32;
extern fn zllvm_spilled_phi(u64, u32, u32) callconv(.c) u64;
extern fn zllvm_uadd_i32_sum(u32, u32) callconv(.c) u32;
extern fn zllvm_uadd_i32_carry(u32, u32) callconv(.c) u32;
extern fn zllvm_smul_i128_value(i128, i128) callconv(.c) i128;
extern fn zllvm_smul_i128_overflow(i128, i128) callconv(.c) u32;
extern fn zllvm_smul_i64_value(i64, i64) callconv(.c) i64;
extern fn zllvm_smul_i64_overflow(i64, i64) callconv(.c) u32;
extern fn zllvm_add_i64_large_imm(i64) callconv(.c) i64;
extern fn zllvm_multi_use_i64_binary(i64, i64) callconv(.c) i64;
extern fn zllvm_eq_min_i32(i32) callconv(.c) u32;
extern fn zllvm_neg_i32(i32) callconv(.c) i32;
extern fn zllvm_neg_i128(i128) callconv(.c) i128;
extern fn zllvm_negative_i128(i128) callconv(.c) u32;
extern fn zllvm_eq_min_i128(i128) callconv(.c) u32;
extern fn zllvm_i128_guard_and(i128, i128) callconv(.c) u32;
extern fn zllvm_mixed_frame_first(u32) callconv(.c) u32;
extern fn zllvm_mixed_frame_second(u32) callconv(.c) u32;

var multi_lhs: i128 = 4294967299;
var multi_rhs: i128 = -8589934597;
var mod_lhs: i128 = 123456789;
var mod_rhs: i128 = 4294967299;
var predicate_zero: u32 = 65536;
var predicate_nonzero: u32 = 65537;
var element_values = [3]u32{ 11, 22, 33 };
var spill_values = [7]u32{ 10, 20, 30, 40, 50, 60, 70 };
var loaded_sum_values = [2]u32{ 3, 4 };
var memcpy_source = [4]u32{ 11, 22, 33, 44 };
var memcpy_dest = [4]u32{ 0, 0, 0, 0 };
var byte_gep_values = [8]u8{ 0, 1, 2, 3, 4, 5, 6, 7 };

const expected_product: i128 = -36893488194663743503;
const expected_remainder: i128 = 123456789;
const max_i128: i128 = 170141183460469231731687303715884105727;
const min_i128: i128 = -170141183460469231731687303715884105728;

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
    const spilled_stored = zllvm_store_i32_spilled_ptr(&spill_values, 77);
    const spill_store_bad: usize = @intFromBool(spilled_stored != 83 or spill_values[0] != 10 or spill_values[1] != 20 or spill_values[2] != 30 or spill_values[3] != 40 or spill_values[4] != 50 or spill_values[5] != 60 or spill_values[6] != 77);
    const store_array_base_bad: usize = @intFromBool(zllvm_store_array_base(91) != 91);
    const select_shifted_true_bad: usize = @intFromBool(zllvm_select_shifted(5, 3, 0) != 40);
    const select_shifted_false_bad: usize = @intFromBool(zllvm_select_shifted(5, 3, 1) != 0);
    const or_i64_clear_bad: usize = @intFromBool(zllvm_or_i64_imm(8) != 9);
    const or_i64_set_bad: usize = @intFromBool(zllvm_or_i64_imm(9) != 9);
    const stack_index_dependency_bad: usize = @intFromBool(zllvm_stack_index_dependency(0, 5, 2) != 11);
    const sub_rhs_accumulator_bad: usize = @intFromBool(zllvm_sub_rhs_accumulator(20, 3, 4) != 13);
    const sum_loaded_i32_bad: usize = @intFromBool(zllvm_sum_loaded_i32(&loaded_sum_values, 10) != 17);
    const add_truncated_rhs_bad: usize = @intFromBool(zllvm_add_truncated_rhs(5, 0x100000002) != 7);
    const double_use_bad: usize = @intFromBool(zllvm_double_use(7, 5) != 24);
    zllvm_inline_memcpy(&memcpy_dest, &memcpy_source, 16);
    const inline_memcpy_bad: usize = @intFromBool(memcpy_dest[0] != 11 or memcpy_dest[1] != 22 or memcpy_dest[2] != 33 or memcpy_dest[3] != 44);
    const spilled_trunc_after_memcpy_bad: usize = @intFromBool(zllvm_spilled_trunc_after_memcpy(&memcpy_dest, &memcpy_source, 16, 67) != 3);
    const framed_early_return_bad: usize = @intFromBool(zllvm_framed_early_return(0, 77) != 1);
    const framed_later_return_bad: usize = @intFromBool(zllvm_framed_early_return(2, 77) != 77);
    const branch_chain_65_bad: usize = @intFromBool(zllvm_branch_chain_65(91) != 91);
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
    const sub_i6_zero_bad: usize = @intFromBool(zllvm_sub_i6(0) != 32);
    const sub_i6_one_bad: usize = @intFromBool(zllvm_sub_i6(1) != 31);
    const sub_i6_wrap_bad: usize = @intFromBool(zllvm_sub_i6(32) != 0);
    const spilled_cond_true_bad: usize = @intFromBool(zllvm_spilled_cond(1) != 27);
    const spilled_cond_false_bad: usize = @intFromBool(zllvm_spilled_cond(0) != 0);
    const variable_shl_bad: usize = @intFromBool(zllvm_variable_shl_i32(8, 2) != 32);
    const variable_lshr_bad: usize = @intFromBool(zllvm_variable_lshr_i32(0x80000000, 31) != 1);
    const stack_byte_gep_bad: usize = @intFromBool(zllvm_stack_byte_gep(0, 77) != 11);
    const stack_chained_gep_bad: usize = @intFromBool(zllvm_stack_chained_gep(0, 1, 77) != 11);
    const stack_element_gep_bad: usize = @intFromBool(zllvm_stack_element_gep(1, 77) != 11);
    const spilled_phi_bad: usize = @intFromBool(zllvm_spilled_phi(2, 3, 1) != 13);
    const uadd_sum_plain_bad: usize = @intFromBool(zllvm_uadd_i32_sum(7, 5) != 12);
    const uadd_carry_plain_bad: usize = @intFromBool(zllvm_uadd_i32_carry(7, 5) != 0);
    const uadd_sum_wrap_bad: usize = @intFromBool(zllvm_uadd_i32_sum(0xffffffff, 1) != 0);
    const uadd_carry_wrap_bad: usize = @intFromBool(zllvm_uadd_i32_carry(0xffffffff, 1) != 1);
    const mixed_frame_first_bad: usize = @intFromBool(zllvm_mixed_frame_first(77) != 11);
    const mixed_frame_second_bad: usize = @intFromBool(zllvm_mixed_frame_second(77) != 77);
    const negative_i32_true_bad: usize = @intFromBool(zllvm_negative_i32(-1) != 1);
    const negative_i32_false_bad: usize = @intFromBool(zllvm_negative_i32(0) != 0);
    const stack_i1_true_bad: usize = @intFromBool(zllvm_stack_i1_roundtrip(1) != 1);
    const stack_i1_false_bad: usize = @intFromBool(zllvm_stack_i1_roundtrip(0) != 0);
    const xor_i32_bad: usize = @intFromBool(zllvm_xor_i32_ones(0x1234_5678) != 0xedcb_a987);
    const and_i8_odd_bad: usize = @intFromBool(zllvm_and_i8_one(0x101) != 1);
    const and_i8_even_bad: usize = @intFromBool(zllvm_and_i8_one(0x102) != 0);
    const byte_array_gep_bad: usize = @intFromBool(zllvm_byte_array_gep_eq(&byte_gep_values, @as([*]u8, &byte_gep_values) + 5, 5) != 1);
    const nonnegative_i32_true_bad: usize = @intFromBool(zllvm_nonnegative_i32(0) != 1);
    const nonnegative_i32_false_bad: usize = @intFromBool(zllvm_nonnegative_i32(-1) != 0);
    const byte_values_ptr: [*]u8 = &byte_gep_values;
    const select_ptr_true_bad: usize = @intFromBool(zllvm_select_ptr_eq(0, byte_values_ptr, byte_values_ptr, byte_values_ptr + 1) != 1);
    const select_ptr_false_bad: usize = @intFromBool(zllvm_select_ptr_eq(1, byte_values_ptr + 1, byte_values_ptr, byte_values_ptr + 1) != 1);
    const freeze_i128_bad: usize = @intFromBool(zllvm_freeze_i128(loadI128(&multi_rhs)) != multi_rhs);
    const smul_positive_plain_bad: usize = @intFromBool(zllvm_smul_i128_value(12, 11) != 132 or zllvm_smul_i128_overflow(12, 11) != 0);
    const smul_negative_plain_bad: usize = @intFromBool(zllvm_smul_i128_value(-12, 11) != -132 or zllvm_smul_i128_overflow(-12, 11) != 0);
    const smul_positive_overflow_bad: usize = @intFromBool(zllvm_smul_i128_value(max_i128, 2) != -2 or zllvm_smul_i128_overflow(max_i128, 2) != 1);
    const smul_negative_overflow_bad: usize = @intFromBool(zllvm_smul_i128_value(min_i128, 2) != 0 or zllvm_smul_i128_overflow(min_i128, 2) != 1);
    const negative_i128_true_bad: usize = @intFromBool(zllvm_negative_i128(-1) != 1);
    const negative_i128_false_bad: usize = @intFromBool(zllvm_negative_i128(0) != 0);
    const eq_min_i128_true_bad: usize = @intFromBool(zllvm_eq_min_i128(min_i128) != 1);
    const eq_min_i128_false_bad: usize = @intFromBool(zllvm_eq_min_i128(min_i128 + 1) != 0);
    const i128_guard_and_true_bad: usize = @intFromBool(zllvm_i128_guard_and(-1, min_i128) != 1);
    const i128_guard_and_false_bad: usize = @intFromBool(zllvm_i128_guard_and(0, min_i128) != 0 or zllvm_i128_guard_and(-1, min_i128 + 1) != 0);
    const smul_i64_positive_plain_bad: usize = @intFromBool(zllvm_smul_i64_value(12, 11) != 132 or zllvm_smul_i64_overflow(12, 11) != 0);
    const smul_i64_negative_plain_bad: usize = @intFromBool(zllvm_smul_i64_value(-12, 11) != -132 or zllvm_smul_i64_overflow(-12, 11) != 0);
    const max_i64: i64 = 9223372036854775807;
    const min_i64: i64 = -9223372036854775808;
    const smul_i64_positive_overflow_bad: usize = @intFromBool(zllvm_smul_i64_value(max_i64, 2) != -2 or zllvm_smul_i64_overflow(max_i64, 2) != 1);
    const smul_i64_negative_overflow_bad: usize = @intFromBool(zllvm_smul_i64_value(min_i64, 2) != 0 or zllvm_smul_i64_overflow(min_i64, 2) != 1);
    const add_i64_large_imm_bad: usize = @intFromBool(zllvm_add_i64_large_imm(5) != 2147483653);
    const multi_use_i64_binary_bad: usize = @intFromBool(zllvm_multi_use_i64_binary(7, 3) != 9);
    const eq_min_i32_bad: usize = @intFromBool(zllvm_eq_min_i32(-2147483648) != 1 or zllvm_eq_min_i32(-2147483647) != 0);
    const neg_i32_bad: usize = @intFromBool(zllvm_neg_i32(12) != -12 or zllvm_neg_i32(-12) != 12);
    const neg_i128_bad: usize = @intFromBool(zllvm_neg_i128(12) != -12 or zllvm_neg_i128(-12) != 12);
    exit(product_bad * 11 + remainder_bad * 12 + ne_zero_bad * 13 + ne_nonzero_bad * 14 + gep_bad * 15 + ptr_eq_bad * 16 + ptr_ne_bad * 17 + spill_load_bad * 18 + phi_bad * 19 + ugt_true_bad * 20 + ugt_false_bad * 21 + i6_positive_bad * 22 + i6_negative_bad * 23 + ugt_imm_true_bad * 24 + ugt_imm_false_bad * 25 + negative_true_bad * 26 + negative_false_bad * 27 + ne64_true_bad * 28 + ne64_false_bad * 29 + ctlz_one_bad * 30 + ctlz_sixteen_bad * 31 + sub_i6_zero_bad * 32 + sub_i6_one_bad * 33 + sub_i6_wrap_bad * 34 + spilled_cond_true_bad * 35 + spilled_cond_false_bad * 36 + variable_shl_bad * 37 + variable_lshr_bad * 38 + stack_byte_gep_bad * 39 + stack_chained_gep_bad * 40 + stack_element_gep_bad * 41 + spilled_phi_bad * 42 + spill_store_bad * 43 + store_array_base_bad * 44 + select_shifted_true_bad * 45 + select_shifted_false_bad * 46 + or_i64_clear_bad * 47 + or_i64_set_bad * 48 + stack_index_dependency_bad * 49 + sub_rhs_accumulator_bad * 50 + sum_loaded_i32_bad * 51 + add_truncated_rhs_bad * 52 + framed_early_return_bad * 53 + framed_later_return_bad * 54 + branch_chain_65_bad * 55 + inline_memcpy_bad * 56 + spilled_trunc_after_memcpy_bad * 57 + double_use_bad * 58 + uadd_sum_plain_bad * 59 + uadd_carry_plain_bad * 60 + uadd_sum_wrap_bad * 61 + uadd_carry_wrap_bad * 62 + mixed_frame_first_bad * 63 + mixed_frame_second_bad * 64 + negative_i32_true_bad * 65 + negative_i32_false_bad * 66 + stack_i1_true_bad * 67 + stack_i1_false_bad * 68 + xor_i32_bad * 69 + and_i8_odd_bad * 70 + and_i8_even_bad * 71 + byte_array_gep_bad * 72 + nonnegative_i32_true_bad * 73 + nonnegative_i32_false_bad * 74 + select_ptr_true_bad * 75 + select_ptr_false_bad * 76 + freeze_i128_bad * 77 + smul_positive_plain_bad * 78 + smul_negative_plain_bad * 79 + smul_positive_overflow_bad * 80 + smul_negative_overflow_bad * 81 + negative_i128_true_bad * 82 + negative_i128_false_bad * 83 + eq_min_i128_true_bad * 84 + eq_min_i128_false_bad * 85 + i128_guard_and_true_bad * 86 + i128_guard_and_false_bad * 87 + smul_i64_positive_plain_bad * 88 + smul_i64_negative_plain_bad * 89 + smul_i64_positive_overflow_bad * 90 + smul_i64_negative_overflow_bad * 91 + add_i64_large_imm_bad * 92 + multi_use_i64_binary_bad * 93 + eq_min_i32_bad * 94 + neg_i32_bad * 95 + neg_i128_bad * 96);
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
