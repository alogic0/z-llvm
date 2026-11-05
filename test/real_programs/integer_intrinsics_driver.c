#include <stdint.h>
#include <stdio.h>
typedef uint64_t (*probe)(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_uadd_sat1_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_uadd_sat1_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_uadd_sat1_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_usub_sat1_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_usub_sat1_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_usub_sat1_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umin1_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umin1_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umin1_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umax1_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umax1_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umax1_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smin1_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smin1_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smin1_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smax1_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smax1_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smax1_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_bitreverse1_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_bitreverse1_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_uadd_sat2_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_uadd_sat2_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_uadd_sat2_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_usub_sat2_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_usub_sat2_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_usub_sat2_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umin2_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umin2_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umin2_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umax2_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umax2_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umax2_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smin2_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smin2_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smin2_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smax2_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smax2_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smax2_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_bitreverse2_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_bitreverse2_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_uadd_sat7_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_uadd_sat7_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_uadd_sat7_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_usub_sat7_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_usub_sat7_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_usub_sat7_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umin7_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umin7_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umin7_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umax7_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umax7_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umax7_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smin7_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smin7_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smin7_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smax7_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smax7_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smax7_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_bitreverse7_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_bitreverse7_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_uadd_sat8_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_uadd_sat8_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_uadd_sat8_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_usub_sat8_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_usub_sat8_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_usub_sat8_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umin8_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umin8_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umin8_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umax8_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umax8_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umax8_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smin8_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smin8_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smin8_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smax8_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smax8_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smax8_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_bitreverse8_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_bitreverse8_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_uadd_sat9_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_uadd_sat9_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_uadd_sat9_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_usub_sat9_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_usub_sat9_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_usub_sat9_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umin9_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umin9_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umin9_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umax9_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umax9_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umax9_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smin9_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smin9_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smin9_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smax9_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smax9_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smax9_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_bitreverse9_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_bitreverse9_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_uadd_sat15_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_uadd_sat15_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_uadd_sat15_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_usub_sat15_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_usub_sat15_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_usub_sat15_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umin15_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umin15_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umin15_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umax15_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umax15_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umax15_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smin15_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smin15_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smin15_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smax15_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smax15_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smax15_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_bitreverse15_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_bitreverse15_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_uadd_sat16_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_uadd_sat16_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_uadd_sat16_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_usub_sat16_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_usub_sat16_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_usub_sat16_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umin16_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umin16_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umin16_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umax16_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umax16_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umax16_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smin16_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smin16_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smin16_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smax16_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smax16_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smax16_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_bitreverse16_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_bitreverse16_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_uadd_sat31_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_uadd_sat31_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_uadd_sat31_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_usub_sat31_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_usub_sat31_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_usub_sat31_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umin31_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umin31_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umin31_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umax31_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umax31_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umax31_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smin31_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smin31_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smin31_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smax31_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smax31_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smax31_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_bitreverse31_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_bitreverse31_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_uadd_sat32_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_uadd_sat32_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_uadd_sat32_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_usub_sat32_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_usub_sat32_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_usub_sat32_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umin32_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umin32_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umin32_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umax32_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umax32_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umax32_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smin32_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smin32_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smin32_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smax32_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smax32_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smax32_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_bitreverse32_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_bitreverse32_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umin33_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umin33_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umin33_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umax33_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umax33_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umax33_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smin33_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smin33_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smin33_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smax33_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smax33_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smax33_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_bitreverse33_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_bitreverse33_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umin63_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umin63_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umin63_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umax63_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umax63_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umax63_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smin63_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smin63_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smin63_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smax63_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smax63_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smax63_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_bitreverse63_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_bitreverse63_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_uadd_sat64_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_uadd_sat64_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_uadd_sat64_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_usub_sat64_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_usub_sat64_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_usub_sat64_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umin64_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umin64_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umin64_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umax64_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umax64_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_umax64_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smin64_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smin64_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smin64_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smax64_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smax64_1(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_smax64_2(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_bitreverse64_0(uint64_t,uint64_t,uint64_t *,uint64_t);
extern uint64_t intrinsic_bitreverse64_1(uint64_t,uint64_t,uint64_t *,uint64_t);
struct row {probe run;unsigned bits,op,side;};
static const struct row rows[]={
{intrinsic_uadd_sat1_0,1,0,0},
{intrinsic_uadd_sat1_1,1,0,1},
{intrinsic_uadd_sat1_2,1,0,2},
{intrinsic_usub_sat1_0,1,1,0},
{intrinsic_usub_sat1_1,1,1,1},
{intrinsic_usub_sat1_2,1,1,2},
{intrinsic_umin1_0,1,2,0},
{intrinsic_umin1_1,1,2,1},
{intrinsic_umin1_2,1,2,2},
{intrinsic_umax1_0,1,3,0},
{intrinsic_umax1_1,1,3,1},
{intrinsic_umax1_2,1,3,2},
{intrinsic_smin1_0,1,4,0},
{intrinsic_smin1_1,1,4,1},
{intrinsic_smin1_2,1,4,2},
{intrinsic_smax1_0,1,5,0},
{intrinsic_smax1_1,1,5,1},
{intrinsic_smax1_2,1,5,2},
{intrinsic_bitreverse1_0,1,6,0},
{intrinsic_bitreverse1_1,1,6,1},
{intrinsic_uadd_sat2_0,2,0,0},
{intrinsic_uadd_sat2_1,2,0,1},
{intrinsic_uadd_sat2_2,2,0,2},
{intrinsic_usub_sat2_0,2,1,0},
{intrinsic_usub_sat2_1,2,1,1},
{intrinsic_usub_sat2_2,2,1,2},
{intrinsic_umin2_0,2,2,0},
{intrinsic_umin2_1,2,2,1},
{intrinsic_umin2_2,2,2,2},
{intrinsic_umax2_0,2,3,0},
{intrinsic_umax2_1,2,3,1},
{intrinsic_umax2_2,2,3,2},
{intrinsic_smin2_0,2,4,0},
{intrinsic_smin2_1,2,4,1},
{intrinsic_smin2_2,2,4,2},
{intrinsic_smax2_0,2,5,0},
{intrinsic_smax2_1,2,5,1},
{intrinsic_smax2_2,2,5,2},
{intrinsic_bitreverse2_0,2,6,0},
{intrinsic_bitreverse2_1,2,6,1},
{intrinsic_uadd_sat7_0,7,0,0},
{intrinsic_uadd_sat7_1,7,0,1},
{intrinsic_uadd_sat7_2,7,0,2},
{intrinsic_usub_sat7_0,7,1,0},
{intrinsic_usub_sat7_1,7,1,1},
{intrinsic_usub_sat7_2,7,1,2},
{intrinsic_umin7_0,7,2,0},
{intrinsic_umin7_1,7,2,1},
{intrinsic_umin7_2,7,2,2},
{intrinsic_umax7_0,7,3,0},
{intrinsic_umax7_1,7,3,1},
{intrinsic_umax7_2,7,3,2},
{intrinsic_smin7_0,7,4,0},
{intrinsic_smin7_1,7,4,1},
{intrinsic_smin7_2,7,4,2},
{intrinsic_smax7_0,7,5,0},
{intrinsic_smax7_1,7,5,1},
{intrinsic_smax7_2,7,5,2},
{intrinsic_bitreverse7_0,7,6,0},
{intrinsic_bitreverse7_1,7,6,1},
{intrinsic_uadd_sat8_0,8,0,0},
{intrinsic_uadd_sat8_1,8,0,1},
{intrinsic_uadd_sat8_2,8,0,2},
{intrinsic_usub_sat8_0,8,1,0},
{intrinsic_usub_sat8_1,8,1,1},
{intrinsic_usub_sat8_2,8,1,2},
{intrinsic_umin8_0,8,2,0},
{intrinsic_umin8_1,8,2,1},
{intrinsic_umin8_2,8,2,2},
{intrinsic_umax8_0,8,3,0},
{intrinsic_umax8_1,8,3,1},
{intrinsic_umax8_2,8,3,2},
{intrinsic_smin8_0,8,4,0},
{intrinsic_smin8_1,8,4,1},
{intrinsic_smin8_2,8,4,2},
{intrinsic_smax8_0,8,5,0},
{intrinsic_smax8_1,8,5,1},
{intrinsic_smax8_2,8,5,2},
{intrinsic_bitreverse8_0,8,6,0},
{intrinsic_bitreverse8_1,8,6,1},
{intrinsic_uadd_sat9_0,9,0,0},
{intrinsic_uadd_sat9_1,9,0,1},
{intrinsic_uadd_sat9_2,9,0,2},
{intrinsic_usub_sat9_0,9,1,0},
{intrinsic_usub_sat9_1,9,1,1},
{intrinsic_usub_sat9_2,9,1,2},
{intrinsic_umin9_0,9,2,0},
{intrinsic_umin9_1,9,2,1},
{intrinsic_umin9_2,9,2,2},
{intrinsic_umax9_0,9,3,0},
{intrinsic_umax9_1,9,3,1},
{intrinsic_umax9_2,9,3,2},
{intrinsic_smin9_0,9,4,0},
{intrinsic_smin9_1,9,4,1},
{intrinsic_smin9_2,9,4,2},
{intrinsic_smax9_0,9,5,0},
{intrinsic_smax9_1,9,5,1},
{intrinsic_smax9_2,9,5,2},
{intrinsic_bitreverse9_0,9,6,0},
{intrinsic_bitreverse9_1,9,6,1},
{intrinsic_uadd_sat15_0,15,0,0},
{intrinsic_uadd_sat15_1,15,0,1},
{intrinsic_uadd_sat15_2,15,0,2},
{intrinsic_usub_sat15_0,15,1,0},
{intrinsic_usub_sat15_1,15,1,1},
{intrinsic_usub_sat15_2,15,1,2},
{intrinsic_umin15_0,15,2,0},
{intrinsic_umin15_1,15,2,1},
{intrinsic_umin15_2,15,2,2},
{intrinsic_umax15_0,15,3,0},
{intrinsic_umax15_1,15,3,1},
{intrinsic_umax15_2,15,3,2},
{intrinsic_smin15_0,15,4,0},
{intrinsic_smin15_1,15,4,1},
{intrinsic_smin15_2,15,4,2},
{intrinsic_smax15_0,15,5,0},
{intrinsic_smax15_1,15,5,1},
{intrinsic_smax15_2,15,5,2},
{intrinsic_bitreverse15_0,15,6,0},
{intrinsic_bitreverse15_1,15,6,1},
{intrinsic_uadd_sat16_0,16,0,0},
{intrinsic_uadd_sat16_1,16,0,1},
{intrinsic_uadd_sat16_2,16,0,2},
{intrinsic_usub_sat16_0,16,1,0},
{intrinsic_usub_sat16_1,16,1,1},
{intrinsic_usub_sat16_2,16,1,2},
{intrinsic_umin16_0,16,2,0},
{intrinsic_umin16_1,16,2,1},
{intrinsic_umin16_2,16,2,2},
{intrinsic_umax16_0,16,3,0},
{intrinsic_umax16_1,16,3,1},
{intrinsic_umax16_2,16,3,2},
{intrinsic_smin16_0,16,4,0},
{intrinsic_smin16_1,16,4,1},
{intrinsic_smin16_2,16,4,2},
{intrinsic_smax16_0,16,5,0},
{intrinsic_smax16_1,16,5,1},
{intrinsic_smax16_2,16,5,2},
{intrinsic_bitreverse16_0,16,6,0},
{intrinsic_bitreverse16_1,16,6,1},
{intrinsic_uadd_sat31_0,31,0,0},
{intrinsic_uadd_sat31_1,31,0,1},
{intrinsic_uadd_sat31_2,31,0,2},
{intrinsic_usub_sat31_0,31,1,0},
{intrinsic_usub_sat31_1,31,1,1},
{intrinsic_usub_sat31_2,31,1,2},
{intrinsic_umin31_0,31,2,0},
{intrinsic_umin31_1,31,2,1},
{intrinsic_umin31_2,31,2,2},
{intrinsic_umax31_0,31,3,0},
{intrinsic_umax31_1,31,3,1},
{intrinsic_umax31_2,31,3,2},
{intrinsic_smin31_0,31,4,0},
{intrinsic_smin31_1,31,4,1},
{intrinsic_smin31_2,31,4,2},
{intrinsic_smax31_0,31,5,0},
{intrinsic_smax31_1,31,5,1},
{intrinsic_smax31_2,31,5,2},
{intrinsic_bitreverse31_0,31,6,0},
{intrinsic_bitreverse31_1,31,6,1},
{intrinsic_uadd_sat32_0,32,0,0},
{intrinsic_uadd_sat32_1,32,0,1},
{intrinsic_uadd_sat32_2,32,0,2},
{intrinsic_usub_sat32_0,32,1,0},
{intrinsic_usub_sat32_1,32,1,1},
{intrinsic_usub_sat32_2,32,1,2},
{intrinsic_umin32_0,32,2,0},
{intrinsic_umin32_1,32,2,1},
{intrinsic_umin32_2,32,2,2},
{intrinsic_umax32_0,32,3,0},
{intrinsic_umax32_1,32,3,1},
{intrinsic_umax32_2,32,3,2},
{intrinsic_smin32_0,32,4,0},
{intrinsic_smin32_1,32,4,1},
{intrinsic_smin32_2,32,4,2},
{intrinsic_smax32_0,32,5,0},
{intrinsic_smax32_1,32,5,1},
{intrinsic_smax32_2,32,5,2},
{intrinsic_bitreverse32_0,32,6,0},
{intrinsic_bitreverse32_1,32,6,1},
{intrinsic_umin33_0,33,2,0},
{intrinsic_umin33_1,33,2,1},
{intrinsic_umin33_2,33,2,2},
{intrinsic_umax33_0,33,3,0},
{intrinsic_umax33_1,33,3,1},
{intrinsic_umax33_2,33,3,2},
{intrinsic_smin33_0,33,4,0},
{intrinsic_smin33_1,33,4,1},
{intrinsic_smin33_2,33,4,2},
{intrinsic_smax33_0,33,5,0},
{intrinsic_smax33_1,33,5,1},
{intrinsic_smax33_2,33,5,2},
{intrinsic_bitreverse33_0,33,6,0},
{intrinsic_bitreverse33_1,33,6,1},
{intrinsic_umin63_0,63,2,0},
{intrinsic_umin63_1,63,2,1},
{intrinsic_umin63_2,63,2,2},
{intrinsic_umax63_0,63,3,0},
{intrinsic_umax63_1,63,3,1},
{intrinsic_umax63_2,63,3,2},
{intrinsic_smin63_0,63,4,0},
{intrinsic_smin63_1,63,4,1},
{intrinsic_smin63_2,63,4,2},
{intrinsic_smax63_0,63,5,0},
{intrinsic_smax63_1,63,5,1},
{intrinsic_smax63_2,63,5,2},
{intrinsic_bitreverse63_0,63,6,0},
{intrinsic_bitreverse63_1,63,6,1},
{intrinsic_uadd_sat64_0,64,0,0},
{intrinsic_uadd_sat64_1,64,0,1},
{intrinsic_uadd_sat64_2,64,0,2},
{intrinsic_usub_sat64_0,64,1,0},
{intrinsic_usub_sat64_1,64,1,1},
{intrinsic_usub_sat64_2,64,1,2},
{intrinsic_umin64_0,64,2,0},
{intrinsic_umin64_1,64,2,1},
{intrinsic_umin64_2,64,2,2},
{intrinsic_umax64_0,64,3,0},
{intrinsic_umax64_1,64,3,1},
{intrinsic_umax64_2,64,3,2},
{intrinsic_smin64_0,64,4,0},
{intrinsic_smin64_1,64,4,1},
{intrinsic_smin64_2,64,4,2},
{intrinsic_smax64_0,64,5,0},
{intrinsic_smax64_1,64,5,1},
{intrinsic_smax64_2,64,5,2},
{intrinsic_bitreverse64_0,64,6,0},
{intrinsic_bitreverse64_1,64,6,1},
};
int main(void) {
    const uint64_t guard=UINT64_C(0xa5a5a5a5a5a5a5a5);
    unsigned observations=0;
    for(unsigned f=0;f<sizeof rows/sizeof *rows;++f) {
        struct row r=rows[f];uint64_t sign=UINT64_C(1)<<(r.bits-1),mask=(sign-1)|sign;
        const uint64_t values[]={0,1,2,sign-1,sign,mask-1,mask,UINT64_MAX};
        for(unsigned i=0;i<8;++i) for(unsigned j=0;j<8;++j) {
            uint64_t a=values[i],b=values[j],salt=(a<<7)^(b>>3)^UINT64_C(0x123456789abcdef0);
            uint64_t x=r.side==1?mask:a&mask,y=r.side==2?mask:b&mask,value=0;
            if(r.op==0) {__uint128_t full=(__uint128_t)x+y;value=full>mask?mask:(uint64_t)full;}
            else if(r.op==1)value=x<y?0:x-y;
            else if(r.op==2)value=x<y?x:y;
            else if(r.op==3)value=x>y?x:y;
            else if(r.op==4)value=(x^sign)<(y^sign)?x:y;
            else if(r.op==5)value=(x^sign)>(y^sign)?x:y;
            else for(unsigned bit=0;bit<r.bits;++bit)value=(value<<1)|((x>>bit)&1);
            uint64_t out[]={guard,0,0,guard},result=r.run(a,b,out+1,salt);
            if(result!=value || out[1]!=value || out[2]!=(a^b^salt) || out[0]!=guard || out[3]!=guard) {
                fprintf(stderr,"integer intrinsic row=%u a=%llx b=%llx result=%llx/%llx value=%llx live=%llx/%llx\n",f,(unsigned long long)a,(unsigned long long)b,(unsigned long long)result,(unsigned long long)value,(unsigned long long)out[1],(unsigned long long)out[2],(unsigned long long)(a^b^salt));return 1;
            }
            ++observations;
        }
    }
    printf("integer-intrinsics observations=%u saturation=extrema=bits=constants=live=guards=preserved\n",observations);
    return 0;
}

