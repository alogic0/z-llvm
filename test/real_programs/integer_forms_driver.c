#include <stdint.h>
#include <stdio.h>
#include <inttypes.h>
static void clobber(void) { __asm__ volatile ("xor %%eax, %%eax; xor %%ecx, %%ecx; xor %%edx, %%edx; xor %%esi, %%esi; xor %%edi, %%edi; xor %%r8d, %%r8d; xor %%r9d, %%r9d; xor %%r10d, %%r10d; xor %%r11d, %%r11d" ::: "rax", "rcx", "rdx", "rsi", "rdi", "r8", "r9", "r10", "r11", "cc"); }
uint64_t integer_forms_clobber(uint64_t value) { uint64_t result = value ^ UINT64_C(0x13579bdf2468ace0); clobber(); return result; }
uint32_t integer_forms_narrow_return_17(uint64_t value) { uint32_t result=(uint32_t)value ^ UINT32_C(0xabc5def0); clobber(); return result; }
uint32_t integer_forms_narrow_return_18(uint64_t value) { uint32_t result=(uint32_t)value ^ UINT32_C(0xabc5def0); clobber(); return result; }
uint32_t integer_forms_narrow_return_23(uint64_t value) { uint32_t result=(uint32_t)value ^ UINT32_C(0xabc5def0); clobber(); return result; }
uint32_t integer_forms_narrow_return_24(uint64_t value) { uint32_t result=(uint32_t)value ^ UINT32_C(0xabc5def0); clobber(); return result; }
uint32_t integer_forms_narrow_return_30(uint64_t value) { uint32_t result=(uint32_t)value ^ UINT32_C(0xabc5def0); clobber(); return result; }
uint32_t integer_forms_narrow_return_31(uint64_t value) { uint32_t result=(uint32_t)value ^ UINT32_C(0xabc5def0); clobber(); return result; }
extern uint64_t integer_forms_add_1(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sub_1(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_mul_1(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_and_1(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_or_1(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_xor_1(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_shl_1(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_lshr_1(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_ashr_1(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_udiv_1(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_urem_1(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_add_2(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sub_2(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_mul_2(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_and_2(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_or_2(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_xor_2(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_shl_2(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_lshr_2(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_ashr_2(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_udiv_2(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_urem_2(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sdiv_2(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_srem_2(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_add_7(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sub_7(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_mul_7(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_and_7(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_or_7(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_xor_7(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_shl_7(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_lshr_7(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_ashr_7(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_udiv_7(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_urem_7(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sdiv_7(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_srem_7(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_add_8(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sub_8(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_mul_8(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_and_8(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_or_8(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_xor_8(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_shl_8(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_lshr_8(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_ashr_8(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_udiv_8(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_urem_8(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sdiv_8(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_srem_8(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_add_16(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sub_16(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_mul_16(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_and_16(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_or_16(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_xor_16(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_shl_16(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_lshr_16(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_ashr_16(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_udiv_16(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_urem_16(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sdiv_16(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_srem_16(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_add_17(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sub_17(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_mul_17(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_and_17(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_or_17(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_xor_17(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_shl_17(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_lshr_17(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_ashr_17(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_udiv_17(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_urem_17(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sdiv_17(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_srem_17(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_add_24(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sub_24(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_mul_24(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_and_24(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_or_24(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_xor_24(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_shl_24(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_lshr_24(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_ashr_24(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_udiv_24(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_urem_24(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sdiv_24(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_srem_24(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_add_31(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sub_31(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_mul_31(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_and_31(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_or_31(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_xor_31(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_shl_31(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_lshr_31(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_ashr_31(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_udiv_31(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_urem_31(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sdiv_31(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_srem_31(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_add_33(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sub_33(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_mul_33(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_and_33(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_or_33(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_xor_33(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_shl_33(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_lshr_33(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_ashr_33(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_udiv_33(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_urem_33(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sdiv_33(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_srem_33(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_add_63(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sub_63(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_mul_63(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_and_63(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_or_63(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_xor_63(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_shl_63(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_lshr_63(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_ashr_63(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_udiv_63(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_urem_63(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sdiv_63(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_srem_63(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sdiv_32(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_srem_32(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sdiv_64(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_srem_64(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_cmp_eq_33(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_cmp_ne_33(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_cmp_ult_33(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_cmp_ule_33(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_cmp_ugt_33(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_cmp_uge_33(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_cmp_slt_33(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_cmp_sle_33(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_cmp_sgt_33(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_cmp_sge_33(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_cmp_eq_51(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_cmp_ne_51(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_cmp_ult_51(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_cmp_ule_51(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_cmp_ugt_51(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_cmp_uge_51(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_cmp_slt_51(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_cmp_sle_51(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_cmp_sgt_51(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_cmp_sge_51(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_cmp_eq_52(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_cmp_ne_52(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_cmp_ult_52(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_cmp_ule_52(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_cmp_ugt_52(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_cmp_uge_52(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_cmp_slt_52(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_cmp_sle_52(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_cmp_sgt_52(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_cmp_sge_52(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_cmp_eq_63(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_cmp_ne_63(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_cmp_ult_63(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_cmp_ule_63(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_cmp_ugt_63(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_cmp_uge_63(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_cmp_slt_63(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_cmp_sle_63(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_cmp_sgt_63(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_cmp_sge_63(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sext_1_31(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sext_1_32(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sext_1_64(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sext_2_31(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sext_2_32(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sext_2_64(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sext_7_31(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sext_7_32(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sext_7_64(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sext_8_31(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sext_8_32(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sext_8_64(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sext_16_31(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sext_16_32(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sext_16_64(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sext_17_31(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sext_17_32(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sext_17_64(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sext_24_31(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sext_24_32(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sext_24_64(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sext_31_32(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sext_31_64(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sext_32_64(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sext_33_64(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_sext_63_64(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_abi_17(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_abi_18(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_abi_23(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_abi_24(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_abi_30(uint64_t, uint64_t, uint64_t, uint64_t *);
extern uint64_t integer_forms_abi_31(uint64_t, uint64_t, uint64_t, uint64_t *);
typedef uint64_t (*run_fn)(uint64_t,uint64_t,uint64_t,uint64_t *);
struct Case { const char *name; run_fn run; unsigned op,bits,destination; };
static const struct Case cases[] = {
  {"integer_forms_add_1", integer_forms_add_1, 0, 1, 0},
  {"integer_forms_sub_1", integer_forms_sub_1, 1, 1, 0},
  {"integer_forms_mul_1", integer_forms_mul_1, 2, 1, 0},
  {"integer_forms_and_1", integer_forms_and_1, 3, 1, 0},
  {"integer_forms_or_1", integer_forms_or_1, 4, 1, 0},
  {"integer_forms_xor_1", integer_forms_xor_1, 5, 1, 0},
  {"integer_forms_shl_1", integer_forms_shl_1, 6, 1, 0},
  {"integer_forms_lshr_1", integer_forms_lshr_1, 7, 1, 0},
  {"integer_forms_ashr_1", integer_forms_ashr_1, 8, 1, 0},
  {"integer_forms_udiv_1", integer_forms_udiv_1, 9, 1, 0},
  {"integer_forms_urem_1", integer_forms_urem_1, 10, 1, 0},
  {"integer_forms_add_2", integer_forms_add_2, 0, 2, 0},
  {"integer_forms_sub_2", integer_forms_sub_2, 1, 2, 0},
  {"integer_forms_mul_2", integer_forms_mul_2, 2, 2, 0},
  {"integer_forms_and_2", integer_forms_and_2, 3, 2, 0},
  {"integer_forms_or_2", integer_forms_or_2, 4, 2, 0},
  {"integer_forms_xor_2", integer_forms_xor_2, 5, 2, 0},
  {"integer_forms_shl_2", integer_forms_shl_2, 6, 2, 0},
  {"integer_forms_lshr_2", integer_forms_lshr_2, 7, 2, 0},
  {"integer_forms_ashr_2", integer_forms_ashr_2, 8, 2, 0},
  {"integer_forms_udiv_2", integer_forms_udiv_2, 9, 2, 0},
  {"integer_forms_urem_2", integer_forms_urem_2, 10, 2, 0},
  {"integer_forms_sdiv_2", integer_forms_sdiv_2, 11, 2, 0},
  {"integer_forms_srem_2", integer_forms_srem_2, 12, 2, 0},
  {"integer_forms_add_7", integer_forms_add_7, 0, 7, 0},
  {"integer_forms_sub_7", integer_forms_sub_7, 1, 7, 0},
  {"integer_forms_mul_7", integer_forms_mul_7, 2, 7, 0},
  {"integer_forms_and_7", integer_forms_and_7, 3, 7, 0},
  {"integer_forms_or_7", integer_forms_or_7, 4, 7, 0},
  {"integer_forms_xor_7", integer_forms_xor_7, 5, 7, 0},
  {"integer_forms_shl_7", integer_forms_shl_7, 6, 7, 0},
  {"integer_forms_lshr_7", integer_forms_lshr_7, 7, 7, 0},
  {"integer_forms_ashr_7", integer_forms_ashr_7, 8, 7, 0},
  {"integer_forms_udiv_7", integer_forms_udiv_7, 9, 7, 0},
  {"integer_forms_urem_7", integer_forms_urem_7, 10, 7, 0},
  {"integer_forms_sdiv_7", integer_forms_sdiv_7, 11, 7, 0},
  {"integer_forms_srem_7", integer_forms_srem_7, 12, 7, 0},
  {"integer_forms_add_8", integer_forms_add_8, 0, 8, 0},
  {"integer_forms_sub_8", integer_forms_sub_8, 1, 8, 0},
  {"integer_forms_mul_8", integer_forms_mul_8, 2, 8, 0},
  {"integer_forms_and_8", integer_forms_and_8, 3, 8, 0},
  {"integer_forms_or_8", integer_forms_or_8, 4, 8, 0},
  {"integer_forms_xor_8", integer_forms_xor_8, 5, 8, 0},
  {"integer_forms_shl_8", integer_forms_shl_8, 6, 8, 0},
  {"integer_forms_lshr_8", integer_forms_lshr_8, 7, 8, 0},
  {"integer_forms_ashr_8", integer_forms_ashr_8, 8, 8, 0},
  {"integer_forms_udiv_8", integer_forms_udiv_8, 9, 8, 0},
  {"integer_forms_urem_8", integer_forms_urem_8, 10, 8, 0},
  {"integer_forms_sdiv_8", integer_forms_sdiv_8, 11, 8, 0},
  {"integer_forms_srem_8", integer_forms_srem_8, 12, 8, 0},
  {"integer_forms_add_16", integer_forms_add_16, 0, 16, 0},
  {"integer_forms_sub_16", integer_forms_sub_16, 1, 16, 0},
  {"integer_forms_mul_16", integer_forms_mul_16, 2, 16, 0},
  {"integer_forms_and_16", integer_forms_and_16, 3, 16, 0},
  {"integer_forms_or_16", integer_forms_or_16, 4, 16, 0},
  {"integer_forms_xor_16", integer_forms_xor_16, 5, 16, 0},
  {"integer_forms_shl_16", integer_forms_shl_16, 6, 16, 0},
  {"integer_forms_lshr_16", integer_forms_lshr_16, 7, 16, 0},
  {"integer_forms_ashr_16", integer_forms_ashr_16, 8, 16, 0},
  {"integer_forms_udiv_16", integer_forms_udiv_16, 9, 16, 0},
  {"integer_forms_urem_16", integer_forms_urem_16, 10, 16, 0},
  {"integer_forms_sdiv_16", integer_forms_sdiv_16, 11, 16, 0},
  {"integer_forms_srem_16", integer_forms_srem_16, 12, 16, 0},
  {"integer_forms_add_17", integer_forms_add_17, 0, 17, 0},
  {"integer_forms_sub_17", integer_forms_sub_17, 1, 17, 0},
  {"integer_forms_mul_17", integer_forms_mul_17, 2, 17, 0},
  {"integer_forms_and_17", integer_forms_and_17, 3, 17, 0},
  {"integer_forms_or_17", integer_forms_or_17, 4, 17, 0},
  {"integer_forms_xor_17", integer_forms_xor_17, 5, 17, 0},
  {"integer_forms_shl_17", integer_forms_shl_17, 6, 17, 0},
  {"integer_forms_lshr_17", integer_forms_lshr_17, 7, 17, 0},
  {"integer_forms_ashr_17", integer_forms_ashr_17, 8, 17, 0},
  {"integer_forms_udiv_17", integer_forms_udiv_17, 9, 17, 0},
  {"integer_forms_urem_17", integer_forms_urem_17, 10, 17, 0},
  {"integer_forms_sdiv_17", integer_forms_sdiv_17, 11, 17, 0},
  {"integer_forms_srem_17", integer_forms_srem_17, 12, 17, 0},
  {"integer_forms_add_24", integer_forms_add_24, 0, 24, 0},
  {"integer_forms_sub_24", integer_forms_sub_24, 1, 24, 0},
  {"integer_forms_mul_24", integer_forms_mul_24, 2, 24, 0},
  {"integer_forms_and_24", integer_forms_and_24, 3, 24, 0},
  {"integer_forms_or_24", integer_forms_or_24, 4, 24, 0},
  {"integer_forms_xor_24", integer_forms_xor_24, 5, 24, 0},
  {"integer_forms_shl_24", integer_forms_shl_24, 6, 24, 0},
  {"integer_forms_lshr_24", integer_forms_lshr_24, 7, 24, 0},
  {"integer_forms_ashr_24", integer_forms_ashr_24, 8, 24, 0},
  {"integer_forms_udiv_24", integer_forms_udiv_24, 9, 24, 0},
  {"integer_forms_urem_24", integer_forms_urem_24, 10, 24, 0},
  {"integer_forms_sdiv_24", integer_forms_sdiv_24, 11, 24, 0},
  {"integer_forms_srem_24", integer_forms_srem_24, 12, 24, 0},
  {"integer_forms_add_31", integer_forms_add_31, 0, 31, 0},
  {"integer_forms_sub_31", integer_forms_sub_31, 1, 31, 0},
  {"integer_forms_mul_31", integer_forms_mul_31, 2, 31, 0},
  {"integer_forms_and_31", integer_forms_and_31, 3, 31, 0},
  {"integer_forms_or_31", integer_forms_or_31, 4, 31, 0},
  {"integer_forms_xor_31", integer_forms_xor_31, 5, 31, 0},
  {"integer_forms_shl_31", integer_forms_shl_31, 6, 31, 0},
  {"integer_forms_lshr_31", integer_forms_lshr_31, 7, 31, 0},
  {"integer_forms_ashr_31", integer_forms_ashr_31, 8, 31, 0},
  {"integer_forms_udiv_31", integer_forms_udiv_31, 9, 31, 0},
  {"integer_forms_urem_31", integer_forms_urem_31, 10, 31, 0},
  {"integer_forms_sdiv_31", integer_forms_sdiv_31, 11, 31, 0},
  {"integer_forms_srem_31", integer_forms_srem_31, 12, 31, 0},
  {"integer_forms_add_33", integer_forms_add_33, 0, 33, 0},
  {"integer_forms_sub_33", integer_forms_sub_33, 1, 33, 0},
  {"integer_forms_mul_33", integer_forms_mul_33, 2, 33, 0},
  {"integer_forms_and_33", integer_forms_and_33, 3, 33, 0},
  {"integer_forms_or_33", integer_forms_or_33, 4, 33, 0},
  {"integer_forms_xor_33", integer_forms_xor_33, 5, 33, 0},
  {"integer_forms_shl_33", integer_forms_shl_33, 6, 33, 0},
  {"integer_forms_lshr_33", integer_forms_lshr_33, 7, 33, 0},
  {"integer_forms_ashr_33", integer_forms_ashr_33, 8, 33, 0},
  {"integer_forms_udiv_33", integer_forms_udiv_33, 9, 33, 0},
  {"integer_forms_urem_33", integer_forms_urem_33, 10, 33, 0},
  {"integer_forms_sdiv_33", integer_forms_sdiv_33, 11, 33, 0},
  {"integer_forms_srem_33", integer_forms_srem_33, 12, 33, 0},
  {"integer_forms_add_63", integer_forms_add_63, 0, 63, 0},
  {"integer_forms_sub_63", integer_forms_sub_63, 1, 63, 0},
  {"integer_forms_mul_63", integer_forms_mul_63, 2, 63, 0},
  {"integer_forms_and_63", integer_forms_and_63, 3, 63, 0},
  {"integer_forms_or_63", integer_forms_or_63, 4, 63, 0},
  {"integer_forms_xor_63", integer_forms_xor_63, 5, 63, 0},
  {"integer_forms_shl_63", integer_forms_shl_63, 6, 63, 0},
  {"integer_forms_lshr_63", integer_forms_lshr_63, 7, 63, 0},
  {"integer_forms_ashr_63", integer_forms_ashr_63, 8, 63, 0},
  {"integer_forms_udiv_63", integer_forms_udiv_63, 9, 63, 0},
  {"integer_forms_urem_63", integer_forms_urem_63, 10, 63, 0},
  {"integer_forms_sdiv_63", integer_forms_sdiv_63, 11, 63, 0},
  {"integer_forms_srem_63", integer_forms_srem_63, 12, 63, 0},
  {"integer_forms_sdiv_32", integer_forms_sdiv_32, 11, 32, 0},
  {"integer_forms_srem_32", integer_forms_srem_32, 12, 32, 0},
  {"integer_forms_sdiv_64", integer_forms_sdiv_64, 11, 64, 0},
  {"integer_forms_srem_64", integer_forms_srem_64, 12, 64, 0},
  {"integer_forms_cmp_eq_33", integer_forms_cmp_eq_33, 15, 33, 0},
  {"integer_forms_cmp_ne_33", integer_forms_cmp_ne_33, 16, 33, 0},
  {"integer_forms_cmp_ult_33", integer_forms_cmp_ult_33, 17, 33, 0},
  {"integer_forms_cmp_ule_33", integer_forms_cmp_ule_33, 18, 33, 0},
  {"integer_forms_cmp_ugt_33", integer_forms_cmp_ugt_33, 19, 33, 0},
  {"integer_forms_cmp_uge_33", integer_forms_cmp_uge_33, 20, 33, 0},
  {"integer_forms_cmp_slt_33", integer_forms_cmp_slt_33, 21, 33, 0},
  {"integer_forms_cmp_sle_33", integer_forms_cmp_sle_33, 22, 33, 0},
  {"integer_forms_cmp_sgt_33", integer_forms_cmp_sgt_33, 23, 33, 0},
  {"integer_forms_cmp_sge_33", integer_forms_cmp_sge_33, 24, 33, 0},
  {"integer_forms_cmp_eq_51", integer_forms_cmp_eq_51, 15, 51, 0},
  {"integer_forms_cmp_ne_51", integer_forms_cmp_ne_51, 16, 51, 0},
  {"integer_forms_cmp_ult_51", integer_forms_cmp_ult_51, 17, 51, 0},
  {"integer_forms_cmp_ule_51", integer_forms_cmp_ule_51, 18, 51, 0},
  {"integer_forms_cmp_ugt_51", integer_forms_cmp_ugt_51, 19, 51, 0},
  {"integer_forms_cmp_uge_51", integer_forms_cmp_uge_51, 20, 51, 0},
  {"integer_forms_cmp_slt_51", integer_forms_cmp_slt_51, 21, 51, 0},
  {"integer_forms_cmp_sle_51", integer_forms_cmp_sle_51, 22, 51, 0},
  {"integer_forms_cmp_sgt_51", integer_forms_cmp_sgt_51, 23, 51, 0},
  {"integer_forms_cmp_sge_51", integer_forms_cmp_sge_51, 24, 51, 0},
  {"integer_forms_cmp_eq_52", integer_forms_cmp_eq_52, 15, 52, 0},
  {"integer_forms_cmp_ne_52", integer_forms_cmp_ne_52, 16, 52, 0},
  {"integer_forms_cmp_ult_52", integer_forms_cmp_ult_52, 17, 52, 0},
  {"integer_forms_cmp_ule_52", integer_forms_cmp_ule_52, 18, 52, 0},
  {"integer_forms_cmp_ugt_52", integer_forms_cmp_ugt_52, 19, 52, 0},
  {"integer_forms_cmp_uge_52", integer_forms_cmp_uge_52, 20, 52, 0},
  {"integer_forms_cmp_slt_52", integer_forms_cmp_slt_52, 21, 52, 0},
  {"integer_forms_cmp_sle_52", integer_forms_cmp_sle_52, 22, 52, 0},
  {"integer_forms_cmp_sgt_52", integer_forms_cmp_sgt_52, 23, 52, 0},
  {"integer_forms_cmp_sge_52", integer_forms_cmp_sge_52, 24, 52, 0},
  {"integer_forms_cmp_eq_63", integer_forms_cmp_eq_63, 15, 63, 0},
  {"integer_forms_cmp_ne_63", integer_forms_cmp_ne_63, 16, 63, 0},
  {"integer_forms_cmp_ult_63", integer_forms_cmp_ult_63, 17, 63, 0},
  {"integer_forms_cmp_ule_63", integer_forms_cmp_ule_63, 18, 63, 0},
  {"integer_forms_cmp_ugt_63", integer_forms_cmp_ugt_63, 19, 63, 0},
  {"integer_forms_cmp_uge_63", integer_forms_cmp_uge_63, 20, 63, 0},
  {"integer_forms_cmp_slt_63", integer_forms_cmp_slt_63, 21, 63, 0},
  {"integer_forms_cmp_sle_63", integer_forms_cmp_sle_63, 22, 63, 0},
  {"integer_forms_cmp_sgt_63", integer_forms_cmp_sgt_63, 23, 63, 0},
  {"integer_forms_cmp_sge_63", integer_forms_cmp_sge_63, 24, 63, 0},
  {"integer_forms_sext_1_31", integer_forms_sext_1_31, 13, 1, 31},
  {"integer_forms_sext_1_32", integer_forms_sext_1_32, 13, 1, 32},
  {"integer_forms_sext_1_64", integer_forms_sext_1_64, 13, 1, 64},
  {"integer_forms_sext_2_31", integer_forms_sext_2_31, 13, 2, 31},
  {"integer_forms_sext_2_32", integer_forms_sext_2_32, 13, 2, 32},
  {"integer_forms_sext_2_64", integer_forms_sext_2_64, 13, 2, 64},
  {"integer_forms_sext_7_31", integer_forms_sext_7_31, 13, 7, 31},
  {"integer_forms_sext_7_32", integer_forms_sext_7_32, 13, 7, 32},
  {"integer_forms_sext_7_64", integer_forms_sext_7_64, 13, 7, 64},
  {"integer_forms_sext_8_31", integer_forms_sext_8_31, 13, 8, 31},
  {"integer_forms_sext_8_32", integer_forms_sext_8_32, 13, 8, 32},
  {"integer_forms_sext_8_64", integer_forms_sext_8_64, 13, 8, 64},
  {"integer_forms_sext_16_31", integer_forms_sext_16_31, 13, 16, 31},
  {"integer_forms_sext_16_32", integer_forms_sext_16_32, 13, 16, 32},
  {"integer_forms_sext_16_64", integer_forms_sext_16_64, 13, 16, 64},
  {"integer_forms_sext_17_31", integer_forms_sext_17_31, 13, 17, 31},
  {"integer_forms_sext_17_32", integer_forms_sext_17_32, 13, 17, 32},
  {"integer_forms_sext_17_64", integer_forms_sext_17_64, 13, 17, 64},
  {"integer_forms_sext_24_31", integer_forms_sext_24_31, 13, 24, 31},
  {"integer_forms_sext_24_32", integer_forms_sext_24_32, 13, 24, 32},
  {"integer_forms_sext_24_64", integer_forms_sext_24_64, 13, 24, 64},
  {"integer_forms_sext_31_32", integer_forms_sext_31_32, 13, 31, 32},
  {"integer_forms_sext_31_64", integer_forms_sext_31_64, 13, 31, 64},
  {"integer_forms_sext_32_64", integer_forms_sext_32_64, 13, 32, 64},
  {"integer_forms_sext_33_64", integer_forms_sext_33_64, 13, 33, 64},
  {"integer_forms_sext_63_64", integer_forms_sext_63_64, 13, 63, 64},
  {"integer_forms_abi_17", integer_forms_abi_17, 14, 17, 0},
  {"integer_forms_abi_18", integer_forms_abi_18, 14, 18, 0},
  {"integer_forms_abi_23", integer_forms_abi_23, 14, 23, 0},
  {"integer_forms_abi_24", integer_forms_abi_24, 14, 24, 0},
  {"integer_forms_abi_30", integer_forms_abi_30, 14, 30, 0},
  {"integer_forms_abi_31", integer_forms_abi_31, 14, 31, 0},
};

static uint64_t mask(unsigned bits) { return bits == 64 ? UINT64_MAX : (UINT64_C(1) << bits)-1; }
static __int128 signed_value(uint64_t value,unsigned bits) { uint64_t sign=UINT64_C(1)<<(bits-1); return (__int128)(value^sign)-sign; }
static uint64_t expect(const struct Case *c,uint64_t input,uint64_t other) {
 uint64_t m=mask(c->bits),a=input&m,b=other&m; unsigned shift=(unsigned)(other%c->bits);
 __int128 sa=signed_value(a,c->bits),sb;
 if (c->op>=9 && c->op<=12) b|=1;
 sb=signed_value(b,c->bits);
 if ((c->op==11||c->op==12) && sa==-((__int128)1<<(c->bits-1)) && sb==-1) sa=0;
 switch (c->op) {
  case 0:return (a+b)&m;case 1:return (a-b)&m;case 2:return (a*b)&m;
  case 3:return a&b;case 4:return a|b;case 5:return a^b;
  case 6:return (a<<shift)&m;case 7:return a>>shift;case 8:return (uint64_t)(sa>>shift)&m;
  case 9:return a/b;case 10:return a%b;case 11:return (uint64_t)(sa/sb)&m;case 12:return (uint64_t)(sa%sb)&m;
  case 13:return (uint64_t)sa&mask(c->destination);
  case 14:return ((a+17)&m)^((other^UINT64_C(0xabc5def0))&m);
  case 15:return a==b;case 16:return a!=b;case 17:return a<b;case 18:return a<=b;case 19:return a>b;case 20:return a>=b;
  case 21:return sa<sb;case 22:return sa<=sb;case 23:return sa>sb;case 24:return sa>=sb;
  default:return 0;
 }
}
int main(void) {
 unsigned observations=0;
 for (unsigned c=0;c<sizeof(cases)/sizeof(cases[0]);c++) {
  const struct Case *item=&cases[c];uint64_t sign=UINT64_C(1)<<(item->bits-1);
  const uint64_t values[]={0,1,2,sign-1,sign,sign+1,mask(item->bits),UINT64_C(0xdeadbeef12345678)};
  for (unsigned i=0;i<8;i++) for (unsigned j=0;j<8;j++) {
   uint64_t a=values[i],b=values[j],live=values[(i+j)%8]^UINT64_C(0xdada5555abcd1234);
   struct {uint64_t before,value,after;} output={123,0,456};
   uint64_t got=item->run(a,b,live,&output.value),expected=expect(item,a,b)^live;
   if(got!=expected || output.value!=(live^UINT64_C(0x13579bdf2468ace0)) || output.before!=123 || output.after!=456) {
    fprintf(stderr,"%s i=%u j=%u got=%" PRIx64 " expected=%" PRIx64 " out=%" PRIx64 "\n",item->name,i,j,got,expected,output.value);return 1;
   }
   observations++;
  }
 }
 printf("integer-forms observations=%u widths=signs=division=abi=live=guards=preserved\n",observations);return 0;
}
