#include <stdint.h>
#include <stdio.h>
#include <pthread.h>
typedef uint64_t (*probe)(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint8_t atomic_global8;
extern uint16_t atomic_global16;
extern uint32_t atomic_global32;
extern uint64_t atomic_global64;
extern uint64_t atomic_xchg8_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xchg8_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xchg8_0_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xchg8_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xchg8_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xchg8_1_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_add8_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_add8_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_add8_0_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_add8_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_add8_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_add8_1_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_sub8_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_sub8_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_sub8_0_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_sub8_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_sub8_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_sub8_1_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_and8_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_and8_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_and8_0_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_and8_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_and8_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_and8_1_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_or8_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_or8_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_or8_0_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_or8_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_or8_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_or8_1_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xor8_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xor8_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xor8_0_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xor8_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xor8_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xor8_1_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_nand8_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_nand8_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_nand8_0_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_nand8_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_nand8_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_nand8_1_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umin8_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umin8_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umin8_0_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umin8_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umin8_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umin8_1_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umax8_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umax8_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umax8_0_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umax8_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umax8_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umax8_1_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_global_xchg8(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_global_add8(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xchg16_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xchg16_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xchg16_0_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xchg16_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xchg16_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xchg16_1_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_add16_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_add16_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_add16_0_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_add16_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_add16_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_add16_1_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_sub16_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_sub16_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_sub16_0_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_sub16_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_sub16_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_sub16_1_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_and16_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_and16_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_and16_0_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_and16_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_and16_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_and16_1_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_or16_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_or16_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_or16_0_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_or16_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_or16_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_or16_1_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xor16_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xor16_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xor16_0_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xor16_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xor16_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xor16_1_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_nand16_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_nand16_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_nand16_0_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_nand16_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_nand16_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_nand16_1_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umin16_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umin16_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umin16_0_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umin16_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umin16_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umin16_1_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umax16_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umax16_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umax16_0_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umax16_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umax16_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umax16_1_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_global_xchg16(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_global_add16(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xchg32_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xchg32_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xchg32_0_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xchg32_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xchg32_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xchg32_1_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_add32_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_add32_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_add32_0_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_add32_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_add32_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_add32_1_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_sub32_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_sub32_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_sub32_0_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_sub32_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_sub32_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_sub32_1_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_and32_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_and32_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_and32_0_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_and32_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_and32_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_and32_1_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_or32_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_or32_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_or32_0_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_or32_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_or32_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_or32_1_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xor32_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xor32_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xor32_0_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xor32_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xor32_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xor32_1_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_nand32_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_nand32_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_nand32_0_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_nand32_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_nand32_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_nand32_1_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umin32_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umin32_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umin32_0_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umin32_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umin32_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umin32_1_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umax32_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umax32_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umax32_0_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umax32_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umax32_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umax32_1_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_global_xchg32(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_global_add32(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xchg64_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xchg64_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xchg64_0_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xchg64_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xchg64_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xchg64_1_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_add64_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_add64_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_add64_0_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_add64_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_add64_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_add64_1_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_sub64_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_sub64_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_sub64_0_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_sub64_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_sub64_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_sub64_1_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_and64_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_and64_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_and64_0_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_and64_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_and64_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_and64_1_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_or64_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_or64_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_or64_0_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_or64_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_or64_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_or64_1_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xor64_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xor64_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xor64_0_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xor64_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xor64_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_xor64_1_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_nand64_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_nand64_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_nand64_0_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_nand64_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_nand64_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_nand64_1_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umin64_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umin64_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umin64_0_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umin64_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umin64_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umin64_1_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umax64_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umax64_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umax64_0_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umax64_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umax64_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_umax64_1_2(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_global_xchg64(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_global_add64(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_cmp8_0_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_cmp8_0_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_cmp8_0_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_cmp8_0_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_memory8_0_monotonic(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_memory8_0_release(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_memory8_0_seq_cst(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_cmp8_1_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_cmp8_1_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_cmp8_1_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_cmp8_1_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_memory8_1_monotonic(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_memory8_1_release(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_memory8_1_seq_cst(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_cmp16_0_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_cmp16_0_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_cmp16_0_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_cmp16_0_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_memory16_0_monotonic(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_memory16_0_release(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_memory16_0_seq_cst(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_cmp16_1_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_cmp16_1_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_cmp16_1_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_cmp16_1_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_memory16_1_monotonic(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_memory16_1_release(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_memory16_1_seq_cst(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_cmp32_0_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_cmp32_0_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_cmp32_0_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_cmp32_0_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_memory32_0_monotonic(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_memory32_0_release(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_memory32_0_seq_cst(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_cmp32_1_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_cmp32_1_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_cmp32_1_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_cmp32_1_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_memory32_1_monotonic(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_memory32_1_release(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_memory32_1_seq_cst(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_cmp64_0_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_cmp64_0_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_cmp64_0_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_cmp64_0_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_memory64_0_monotonic(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_memory64_0_release(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_memory64_0_seq_cst(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_cmp64_1_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_cmp64_1_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_cmp64_1_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_cmp64_1_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_memory64_1_monotonic(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_memory64_1_release(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_memory64_1_seq_cst(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_cmp0_0_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_cmp0_0_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_cmp0_0_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_cmp0_0_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_memory0_0_monotonic(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_memory0_0_release(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_memory0_0_seq_cst(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_cmp0_1_0_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_cmp0_1_0_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_cmp0_1_1_0(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_cmp0_1_1_1(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_memory0_1_monotonic(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_memory0_1_release(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
extern uint64_t atomic_memory0_1_seq_cst(uint64_t*,uint64_t,uint64_t,uint64_t*,uint64_t);
struct row {probe run;unsigned bits,op,side,global;};
static const struct row rows[]={
{atomic_xchg8_0_0,8,0,0,0},
{atomic_xchg8_0_1,8,0,1,0},
{atomic_xchg8_0_2,8,0,2,0},
{atomic_xchg8_1_0,8,0,0,0},
{atomic_xchg8_1_1,8,0,1,0},
{atomic_xchg8_1_2,8,0,2,0},
{atomic_add8_0_0,8,1,0,0},
{atomic_add8_0_1,8,1,1,0},
{atomic_add8_0_2,8,1,2,0},
{atomic_add8_1_0,8,1,0,0},
{atomic_add8_1_1,8,1,1,0},
{atomic_add8_1_2,8,1,2,0},
{atomic_sub8_0_0,8,2,0,0},
{atomic_sub8_0_1,8,2,1,0},
{atomic_sub8_0_2,8,2,2,0},
{atomic_sub8_1_0,8,2,0,0},
{atomic_sub8_1_1,8,2,1,0},
{atomic_sub8_1_2,8,2,2,0},
{atomic_and8_0_0,8,3,0,0},
{atomic_and8_0_1,8,3,1,0},
{atomic_and8_0_2,8,3,2,0},
{atomic_and8_1_0,8,3,0,0},
{atomic_and8_1_1,8,3,1,0},
{atomic_and8_1_2,8,3,2,0},
{atomic_or8_0_0,8,4,0,0},
{atomic_or8_0_1,8,4,1,0},
{atomic_or8_0_2,8,4,2,0},
{atomic_or8_1_0,8,4,0,0},
{atomic_or8_1_1,8,4,1,0},
{atomic_or8_1_2,8,4,2,0},
{atomic_xor8_0_0,8,5,0,0},
{atomic_xor8_0_1,8,5,1,0},
{atomic_xor8_0_2,8,5,2,0},
{atomic_xor8_1_0,8,5,0,0},
{atomic_xor8_1_1,8,5,1,0},
{atomic_xor8_1_2,8,5,2,0},
{atomic_nand8_0_0,8,6,0,0},
{atomic_nand8_0_1,8,6,1,0},
{atomic_nand8_0_2,8,6,2,0},
{atomic_nand8_1_0,8,6,0,0},
{atomic_nand8_1_1,8,6,1,0},
{atomic_nand8_1_2,8,6,2,0},
{atomic_umin8_0_0,8,7,0,0},
{atomic_umin8_0_1,8,7,1,0},
{atomic_umin8_0_2,8,7,2,0},
{atomic_umin8_1_0,8,7,0,0},
{atomic_umin8_1_1,8,7,1,0},
{atomic_umin8_1_2,8,7,2,0},
{atomic_umax8_0_0,8,8,0,0},
{atomic_umax8_0_1,8,8,1,0},
{atomic_umax8_0_2,8,8,2,0},
{atomic_umax8_1_0,8,8,0,0},
{atomic_umax8_1_1,8,8,1,0},
{atomic_umax8_1_2,8,8,2,0},
{atomic_global_xchg8,8,0,0,8},
{atomic_global_add8,8,1,0,8},
{atomic_xchg16_0_0,16,0,0,0},
{atomic_xchg16_0_1,16,0,1,0},
{atomic_xchg16_0_2,16,0,2,0},
{atomic_xchg16_1_0,16,0,0,0},
{atomic_xchg16_1_1,16,0,1,0},
{atomic_xchg16_1_2,16,0,2,0},
{atomic_add16_0_0,16,1,0,0},
{atomic_add16_0_1,16,1,1,0},
{atomic_add16_0_2,16,1,2,0},
{atomic_add16_1_0,16,1,0,0},
{atomic_add16_1_1,16,1,1,0},
{atomic_add16_1_2,16,1,2,0},
{atomic_sub16_0_0,16,2,0,0},
{atomic_sub16_0_1,16,2,1,0},
{atomic_sub16_0_2,16,2,2,0},
{atomic_sub16_1_0,16,2,0,0},
{atomic_sub16_1_1,16,2,1,0},
{atomic_sub16_1_2,16,2,2,0},
{atomic_and16_0_0,16,3,0,0},
{atomic_and16_0_1,16,3,1,0},
{atomic_and16_0_2,16,3,2,0},
{atomic_and16_1_0,16,3,0,0},
{atomic_and16_1_1,16,3,1,0},
{atomic_and16_1_2,16,3,2,0},
{atomic_or16_0_0,16,4,0,0},
{atomic_or16_0_1,16,4,1,0},
{atomic_or16_0_2,16,4,2,0},
{atomic_or16_1_0,16,4,0,0},
{atomic_or16_1_1,16,4,1,0},
{atomic_or16_1_2,16,4,2,0},
{atomic_xor16_0_0,16,5,0,0},
{atomic_xor16_0_1,16,5,1,0},
{atomic_xor16_0_2,16,5,2,0},
{atomic_xor16_1_0,16,5,0,0},
{atomic_xor16_1_1,16,5,1,0},
{atomic_xor16_1_2,16,5,2,0},
{atomic_nand16_0_0,16,6,0,0},
{atomic_nand16_0_1,16,6,1,0},
{atomic_nand16_0_2,16,6,2,0},
{atomic_nand16_1_0,16,6,0,0},
{atomic_nand16_1_1,16,6,1,0},
{atomic_nand16_1_2,16,6,2,0},
{atomic_umin16_0_0,16,7,0,0},
{atomic_umin16_0_1,16,7,1,0},
{atomic_umin16_0_2,16,7,2,0},
{atomic_umin16_1_0,16,7,0,0},
{atomic_umin16_1_1,16,7,1,0},
{atomic_umin16_1_2,16,7,2,0},
{atomic_umax16_0_0,16,8,0,0},
{atomic_umax16_0_1,16,8,1,0},
{atomic_umax16_0_2,16,8,2,0},
{atomic_umax16_1_0,16,8,0,0},
{atomic_umax16_1_1,16,8,1,0},
{atomic_umax16_1_2,16,8,2,0},
{atomic_global_xchg16,16,0,0,16},
{atomic_global_add16,16,1,0,16},
{atomic_xchg32_0_0,32,0,0,0},
{atomic_xchg32_0_1,32,0,1,0},
{atomic_xchg32_0_2,32,0,2,0},
{atomic_xchg32_1_0,32,0,0,0},
{atomic_xchg32_1_1,32,0,1,0},
{atomic_xchg32_1_2,32,0,2,0},
{atomic_add32_0_0,32,1,0,0},
{atomic_add32_0_1,32,1,1,0},
{atomic_add32_0_2,32,1,2,0},
{atomic_add32_1_0,32,1,0,0},
{atomic_add32_1_1,32,1,1,0},
{atomic_add32_1_2,32,1,2,0},
{atomic_sub32_0_0,32,2,0,0},
{atomic_sub32_0_1,32,2,1,0},
{atomic_sub32_0_2,32,2,2,0},
{atomic_sub32_1_0,32,2,0,0},
{atomic_sub32_1_1,32,2,1,0},
{atomic_sub32_1_2,32,2,2,0},
{atomic_and32_0_0,32,3,0,0},
{atomic_and32_0_1,32,3,1,0},
{atomic_and32_0_2,32,3,2,0},
{atomic_and32_1_0,32,3,0,0},
{atomic_and32_1_1,32,3,1,0},
{atomic_and32_1_2,32,3,2,0},
{atomic_or32_0_0,32,4,0,0},
{atomic_or32_0_1,32,4,1,0},
{atomic_or32_0_2,32,4,2,0},
{atomic_or32_1_0,32,4,0,0},
{atomic_or32_1_1,32,4,1,0},
{atomic_or32_1_2,32,4,2,0},
{atomic_xor32_0_0,32,5,0,0},
{atomic_xor32_0_1,32,5,1,0},
{atomic_xor32_0_2,32,5,2,0},
{atomic_xor32_1_0,32,5,0,0},
{atomic_xor32_1_1,32,5,1,0},
{atomic_xor32_1_2,32,5,2,0},
{atomic_nand32_0_0,32,6,0,0},
{atomic_nand32_0_1,32,6,1,0},
{atomic_nand32_0_2,32,6,2,0},
{atomic_nand32_1_0,32,6,0,0},
{atomic_nand32_1_1,32,6,1,0},
{atomic_nand32_1_2,32,6,2,0},
{atomic_umin32_0_0,32,7,0,0},
{atomic_umin32_0_1,32,7,1,0},
{atomic_umin32_0_2,32,7,2,0},
{atomic_umin32_1_0,32,7,0,0},
{atomic_umin32_1_1,32,7,1,0},
{atomic_umin32_1_2,32,7,2,0},
{atomic_umax32_0_0,32,8,0,0},
{atomic_umax32_0_1,32,8,1,0},
{atomic_umax32_0_2,32,8,2,0},
{atomic_umax32_1_0,32,8,0,0},
{atomic_umax32_1_1,32,8,1,0},
{atomic_umax32_1_2,32,8,2,0},
{atomic_global_xchg32,32,0,0,32},
{atomic_global_add32,32,1,0,32},
{atomic_xchg64_0_0,64,0,0,0},
{atomic_xchg64_0_1,64,0,1,0},
{atomic_xchg64_0_2,64,0,2,0},
{atomic_xchg64_1_0,64,0,0,0},
{atomic_xchg64_1_1,64,0,1,0},
{atomic_xchg64_1_2,64,0,2,0},
{atomic_add64_0_0,64,1,0,0},
{atomic_add64_0_1,64,1,1,0},
{atomic_add64_0_2,64,1,2,0},
{atomic_add64_1_0,64,1,0,0},
{atomic_add64_1_1,64,1,1,0},
{atomic_add64_1_2,64,1,2,0},
{atomic_sub64_0_0,64,2,0,0},
{atomic_sub64_0_1,64,2,1,0},
{atomic_sub64_0_2,64,2,2,0},
{atomic_sub64_1_0,64,2,0,0},
{atomic_sub64_1_1,64,2,1,0},
{atomic_sub64_1_2,64,2,2,0},
{atomic_and64_0_0,64,3,0,0},
{atomic_and64_0_1,64,3,1,0},
{atomic_and64_0_2,64,3,2,0},
{atomic_and64_1_0,64,3,0,0},
{atomic_and64_1_1,64,3,1,0},
{atomic_and64_1_2,64,3,2,0},
{atomic_or64_0_0,64,4,0,0},
{atomic_or64_0_1,64,4,1,0},
{atomic_or64_0_2,64,4,2,0},
{atomic_or64_1_0,64,4,0,0},
{atomic_or64_1_1,64,4,1,0},
{atomic_or64_1_2,64,4,2,0},
{atomic_xor64_0_0,64,5,0,0},
{atomic_xor64_0_1,64,5,1,0},
{atomic_xor64_0_2,64,5,2,0},
{atomic_xor64_1_0,64,5,0,0},
{atomic_xor64_1_1,64,5,1,0},
{atomic_xor64_1_2,64,5,2,0},
{atomic_nand64_0_0,64,6,0,0},
{atomic_nand64_0_1,64,6,1,0},
{atomic_nand64_0_2,64,6,2,0},
{atomic_nand64_1_0,64,6,0,0},
{atomic_nand64_1_1,64,6,1,0},
{atomic_nand64_1_2,64,6,2,0},
{atomic_umin64_0_0,64,7,0,0},
{atomic_umin64_0_1,64,7,1,0},
{atomic_umin64_0_2,64,7,2,0},
{atomic_umin64_1_0,64,7,0,0},
{atomic_umin64_1_1,64,7,1,0},
{atomic_umin64_1_2,64,7,2,0},
{atomic_umax64_0_0,64,8,0,0},
{atomic_umax64_0_1,64,8,1,0},
{atomic_umax64_0_2,64,8,2,0},
{atomic_umax64_1_0,64,8,0,0},
{atomic_umax64_1_1,64,8,1,0},
{atomic_umax64_1_2,64,8,2,0},
{atomic_global_xchg64,64,0,0,64},
{atomic_global_add64,64,1,0,64},
{atomic_cmp8_0_0_0,8,9,0,0},
{atomic_cmp8_0_0_1,8,9,0,0},
{atomic_cmp8_0_1_0,8,9,0,0},
{atomic_cmp8_0_1_1,8,9,0,0},
{atomic_memory8_0_monotonic,8,10,0,0},
{atomic_memory8_0_release,8,10,0,0},
{atomic_memory8_0_seq_cst,8,10,0,0},
{atomic_cmp8_1_0_0,8,9,0,0},
{atomic_cmp8_1_0_1,8,9,0,0},
{atomic_cmp8_1_1_0,8,9,0,0},
{atomic_cmp8_1_1_1,8,9,0,0},
{atomic_memory8_1_monotonic,8,10,0,0},
{atomic_memory8_1_release,8,10,0,0},
{atomic_memory8_1_seq_cst,8,10,0,0},
{atomic_cmp16_0_0_0,16,9,0,0},
{atomic_cmp16_0_0_1,16,9,0,0},
{atomic_cmp16_0_1_0,16,9,0,0},
{atomic_cmp16_0_1_1,16,9,0,0},
{atomic_memory16_0_monotonic,16,10,0,0},
{atomic_memory16_0_release,16,10,0,0},
{atomic_memory16_0_seq_cst,16,10,0,0},
{atomic_cmp16_1_0_0,16,9,0,0},
{atomic_cmp16_1_0_1,16,9,0,0},
{atomic_cmp16_1_1_0,16,9,0,0},
{atomic_cmp16_1_1_1,16,9,0,0},
{atomic_memory16_1_monotonic,16,10,0,0},
{atomic_memory16_1_release,16,10,0,0},
{atomic_memory16_1_seq_cst,16,10,0,0},
{atomic_cmp32_0_0_0,32,9,0,0},
{atomic_cmp32_0_0_1,32,9,0,0},
{atomic_cmp32_0_1_0,32,9,0,0},
{atomic_cmp32_0_1_1,32,9,0,0},
{atomic_memory32_0_monotonic,32,10,0,0},
{atomic_memory32_0_release,32,10,0,0},
{atomic_memory32_0_seq_cst,32,10,0,0},
{atomic_cmp32_1_0_0,32,9,0,0},
{atomic_cmp32_1_0_1,32,9,0,0},
{atomic_cmp32_1_1_0,32,9,0,0},
{atomic_cmp32_1_1_1,32,9,0,0},
{atomic_memory32_1_monotonic,32,10,0,0},
{atomic_memory32_1_release,32,10,0,0},
{atomic_memory32_1_seq_cst,32,10,0,0},
{atomic_cmp64_0_0_0,64,9,0,0},
{atomic_cmp64_0_0_1,64,9,0,0},
{atomic_cmp64_0_1_0,64,9,0,0},
{atomic_cmp64_0_1_1,64,9,0,0},
{atomic_memory64_0_monotonic,64,10,0,0},
{atomic_memory64_0_release,64,10,0,0},
{atomic_memory64_0_seq_cst,64,10,0,0},
{atomic_cmp64_1_0_0,64,9,0,0},
{atomic_cmp64_1_0_1,64,9,0,0},
{atomic_cmp64_1_1_0,64,9,0,0},
{atomic_cmp64_1_1_1,64,9,0,0},
{atomic_memory64_1_monotonic,64,10,0,0},
{atomic_memory64_1_release,64,10,0,0},
{atomic_memory64_1_seq_cst,64,10,0,0},
{atomic_cmp0_0_0_0,64,9,0,0},
{atomic_cmp0_0_0_1,64,9,0,0},
{atomic_cmp0_0_1_0,64,9,0,0},
{atomic_cmp0_0_1_1,64,9,0,0},
{atomic_memory0_0_monotonic,64,10,0,0},
{atomic_memory0_0_release,64,10,0,0},
{atomic_memory0_0_seq_cst,64,10,0,0},
{atomic_cmp0_1_0_0,64,9,0,0},
{atomic_cmp0_1_0_1,64,9,0,0},
{atomic_cmp0_1_1_0,64,9,0,0},
{atomic_cmp0_1_1_1,64,9,0,0},
{atomic_memory0_1_monotonic,64,10,0,0},
{atomic_memory0_1_release,64,10,0,0},
{atomic_memory0_1_seq_cst,64,10,0,0},
};
struct worker {uint64_t *cell;probe run;uint64_t sum;unsigned cas;int failed;};
static void *increment(void *raw){
 struct worker *w=raw;
 for(unsigned i=0;i<8192;++i){uint64_t out[3],old;
  if(!w->cas)old=w->run(w->cell,1,0,out,0);
  else{uint64_t expected=__atomic_load_n(w->cell,__ATOMIC_SEQ_CST);unsigned attempts=0;
   for(;;){old=w->run(w->cell,expected,expected+1,out,0);if(out[1])break;expected=old;
    if(++attempts>1000000){w->failed=1;return 0;}}}
  w->sum+=old;
 }return 0;
}
static int concurrent(probe run,unsigned cas){
 uint64_t cell=0,sum=0;pthread_t threads[4];struct worker workers[4];
 for(unsigned i=0;i<4;++i){workers[i]=(struct worker){&cell,run,0,cas,0};if(pthread_create(threads+i,0,increment,workers+i))return 1;}
 for(unsigned i=0;i<4;++i){if(pthread_join(threads[i],0)||workers[i].failed)return 1;sum+=workers[i].sum;}
 return cell!=32768||sum!=UINT64_C(32768)*32767/2;
}
static uint64_t *global_cell(unsigned bits,uint64_t value){
 if(bits==8){atomic_global8=(uint8_t)value;return (uint64_t*)&atomic_global8;}
 if(bits==16){atomic_global16=(uint16_t)value;return (uint64_t*)&atomic_global16;}
 if(bits==32){atomic_global32=(uint32_t)value;return (uint64_t*)&atomic_global32;}
 atomic_global64=value;return &atomic_global64;
}
static uint64_t global_value(unsigned bits){if(bits==8)return atomic_global8;if(bits==16)return atomic_global16;if(bits==32)return atomic_global32;return atomic_global64;}
int main(void){
 const uint64_t guard=UINT64_C(0xa5a5a5a5a5a5a5a5);unsigned observations=0;
 for(unsigned f=0;f<sizeof rows/sizeof *rows;++f){
  struct row r=rows[f];uint64_t sign=UINT64_C(1)<<(r.bits-1),mask=(sign-1)|sign;
  const uint64_t values[]={0,1,2,sign-1,sign,mask-1,mask,UINT64_MAX};
  for(unsigned i=0;i<8;++i)for(unsigned j=0;j<8;++j){
   uint64_t a=values[i],b=values[j],before=a&mask,x=b&mask,expected=before,aux=0;
   uint64_t arg_a=b,arg_b=a^UINT64_C(0xfedcba9876543210),salt=UINT64_C(0x123456789abcdef0);
   if(r.side==1)x=1;if(r.side==2)x=mask;
   switch(r.op){
    case 0:expected=x;break;case 1:expected=before+x;break;case 2:expected=before-x;break;
    case 3:expected=before&x;break;case 4:expected=before|x;break;case 5:expected=before^x;break;
    case 6:expected=~(before&x);break;case 7:expected=before<x?before:x;break;case 8:expected=before>x?before:x;break;
    case 9:aux=before==(arg_a&mask);if(aux)expected=arg_b;break;case 10:expected=arg_b;aux=arg_b&mask;break;
   }expected&=mask;
   uint64_t cell=(guard&~mask)|before,*p=r.global?global_cell(r.global,before):&cell;
   uint64_t out[]={guard,0,0,0,guard},result=r.run(p,arg_a,arg_b,out+1,salt);
   uint64_t actual=r.global?global_value(r.global):cell,expected_cell=(r.global?0:guard&~mask)|expected;
   if(result!=before||out[1]!=before||out[2]!=aux||out[3]!=(arg_a^arg_b^salt)||out[0]!=guard||out[4]!=guard||actual!=expected_cell){
    fprintf(stderr,"atomic row=%u a=%llx b=%llx old=%llx/%llx cell=%llx/%llx flag=%llx/%llx live=%llx/%llx\n",f,(unsigned long long)a,(unsigned long long)b,(unsigned long long)result,(unsigned long long)before,(unsigned long long)actual,(unsigned long long)expected_cell,(unsigned long long)out[2],(unsigned long long)aux,(unsigned long long)out[3],(unsigned long long)(arg_a^arg_b^salt));return 1;
   }++observations;
  }
 }
 if(concurrent(atomic_add64_0_0,0)||concurrent(atomic_cmp64_0_0_0,1)){fputs("atomic concurrency mismatch\n",stderr);return 1;}observations+=2;
 printf("scalar-atomics observations=%u widths=scope=volatile=old=success=memory=live=guards=concurrent-preserved\n",observations);return 0;
}

