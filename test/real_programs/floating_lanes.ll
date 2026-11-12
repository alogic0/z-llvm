target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare <1 x half> @llvm.trunc.v1f16(<1 x half>)
define i64 @floating_lane_16_1_trunc(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x half>,ptr %ap,align 1
 %b = load <1 x half>,ptr %bp,align 1
 %c = load <1 x half>,ptr %cp,align 1
 %r = call <1 x half> @llvm.trunc.v1f16(<1 x half> %a)
 store <1 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x half> @llvm.round.v1f16(<1 x half>)
define i64 @floating_lane_16_1_round(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x half>,ptr %ap,align 1
 %b = load <1 x half>,ptr %bp,align 1
 %c = load <1 x half>,ptr %cp,align 1
 %r = call <1 x half> @llvm.round.v1f16(<1 x half> %a)
 store <1 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x half> @llvm.ceil.v1f16(<1 x half>)
define i64 @floating_lane_16_1_ceil(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x half>,ptr %ap,align 1
 %b = load <1 x half>,ptr %bp,align 1
 %c = load <1 x half>,ptr %cp,align 1
 %r = call <1 x half> @llvm.ceil.v1f16(<1 x half> %a)
 store <1 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x half> @llvm.floor.v1f16(<1 x half>)
define i64 @floating_lane_16_1_floor(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x half>,ptr %ap,align 1
 %b = load <1 x half>,ptr %bp,align 1
 %c = load <1 x half>,ptr %cp,align 1
 %r = call <1 x half> @llvm.floor.v1f16(<1 x half> %a)
 store <1 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x half> @llvm.log10.v1f16(<1 x half>)
define i64 @floating_lane_16_1_log10(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x half>,ptr %ap,align 1
 %b = load <1 x half>,ptr %bp,align 1
 %c = load <1 x half>,ptr %cp,align 1
 %r = call <1 x half> @llvm.log10.v1f16(<1 x half> %a)
 store <1 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x half> @llvm.log2.v1f16(<1 x half>)
define i64 @floating_lane_16_1_log2(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x half>,ptr %ap,align 1
 %b = load <1 x half>,ptr %bp,align 1
 %c = load <1 x half>,ptr %cp,align 1
 %r = call <1 x half> @llvm.log2.v1f16(<1 x half> %a)
 store <1 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x half> @llvm.log.v1f16(<1 x half>)
define i64 @floating_lane_16_1_log(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x half>,ptr %ap,align 1
 %b = load <1 x half>,ptr %bp,align 1
 %c = load <1 x half>,ptr %cp,align 1
 %r = call <1 x half> @llvm.log.v1f16(<1 x half> %a)
 store <1 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x half> @llvm.exp2.v1f16(<1 x half>)
define i64 @floating_lane_16_1_exp2(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x half>,ptr %ap,align 1
 %b = load <1 x half>,ptr %bp,align 1
 %c = load <1 x half>,ptr %cp,align 1
 %r = call <1 x half> @llvm.exp2.v1f16(<1 x half> %a)
 store <1 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x half> @llvm.exp.v1f16(<1 x half>)
define i64 @floating_lane_16_1_exp(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x half>,ptr %ap,align 1
 %b = load <1 x half>,ptr %bp,align 1
 %c = load <1 x half>,ptr %cp,align 1
 %r = call <1 x half> @llvm.exp.v1f16(<1 x half> %a)
 store <1 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x half> @llvm.tan.v1f16(<1 x half>)
define i64 @floating_lane_16_1_tan(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x half>,ptr %ap,align 1
 %b = load <1 x half>,ptr %bp,align 1
 %c = load <1 x half>,ptr %cp,align 1
 %r = call <1 x half> @llvm.tan.v1f16(<1 x half> %a)
 store <1 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x half> @llvm.cos.v1f16(<1 x half>)
define i64 @floating_lane_16_1_cos(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x half>,ptr %ap,align 1
 %b = load <1 x half>,ptr %bp,align 1
 %c = load <1 x half>,ptr %cp,align 1
 %r = call <1 x half> @llvm.cos.v1f16(<1 x half> %a)
 store <1 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x half> @llvm.sin.v1f16(<1 x half>)
define i64 @floating_lane_16_1_sin(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x half>,ptr %ap,align 1
 %b = load <1 x half>,ptr %bp,align 1
 %c = load <1 x half>,ptr %cp,align 1
 %r = call <1 x half> @llvm.sin.v1f16(<1 x half> %a)
 store <1 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x half> @llvm.sqrt.v1f16(<1 x half>)
define i64 @floating_lane_16_1_sqrt(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x half>,ptr %ap,align 1
 %b = load <1 x half>,ptr %bp,align 1
 %c = load <1 x half>,ptr %cp,align 1
 %r = call <1 x half> @llvm.sqrt.v1f16(<1 x half> %a)
 store <1 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x half> @llvm.fma.v1f16(<1 x half>,<1 x half>,<1 x half>)
define i64 @floating_lane_16_1_fma(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x half>,ptr %ap,align 1
 %b = load <1 x half>,ptr %bp,align 1
 %c = load <1 x half>,ptr %cp,align 1
 %r = call <1 x half> @llvm.fma.v1f16(<1 x half> %a,<1 x half> %b,<1 x half> %c)
 store <1 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x half> @llvm.trunc.v2f16(<2 x half>)
define i64 @floating_lane_16_2_trunc(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x half>,ptr %ap,align 1
 %b = load <2 x half>,ptr %bp,align 1
 %c = load <2 x half>,ptr %cp,align 1
 %r = call <2 x half> @llvm.trunc.v2f16(<2 x half> %a)
 store <2 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x half> @llvm.round.v2f16(<2 x half>)
define i64 @floating_lane_16_2_round(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x half>,ptr %ap,align 1
 %b = load <2 x half>,ptr %bp,align 1
 %c = load <2 x half>,ptr %cp,align 1
 %r = call <2 x half> @llvm.round.v2f16(<2 x half> %a)
 store <2 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x half> @llvm.ceil.v2f16(<2 x half>)
define i64 @floating_lane_16_2_ceil(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x half>,ptr %ap,align 1
 %b = load <2 x half>,ptr %bp,align 1
 %c = load <2 x half>,ptr %cp,align 1
 %r = call <2 x half> @llvm.ceil.v2f16(<2 x half> %a)
 store <2 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x half> @llvm.floor.v2f16(<2 x half>)
define i64 @floating_lane_16_2_floor(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x half>,ptr %ap,align 1
 %b = load <2 x half>,ptr %bp,align 1
 %c = load <2 x half>,ptr %cp,align 1
 %r = call <2 x half> @llvm.floor.v2f16(<2 x half> %a)
 store <2 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x half> @llvm.log10.v2f16(<2 x half>)
define i64 @floating_lane_16_2_log10(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x half>,ptr %ap,align 1
 %b = load <2 x half>,ptr %bp,align 1
 %c = load <2 x half>,ptr %cp,align 1
 %r = call <2 x half> @llvm.log10.v2f16(<2 x half> %a)
 store <2 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x half> @llvm.log2.v2f16(<2 x half>)
define i64 @floating_lane_16_2_log2(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x half>,ptr %ap,align 1
 %b = load <2 x half>,ptr %bp,align 1
 %c = load <2 x half>,ptr %cp,align 1
 %r = call <2 x half> @llvm.log2.v2f16(<2 x half> %a)
 store <2 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x half> @llvm.log.v2f16(<2 x half>)
define i64 @floating_lane_16_2_log(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x half>,ptr %ap,align 1
 %b = load <2 x half>,ptr %bp,align 1
 %c = load <2 x half>,ptr %cp,align 1
 %r = call <2 x half> @llvm.log.v2f16(<2 x half> %a)
 store <2 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x half> @llvm.exp2.v2f16(<2 x half>)
define i64 @floating_lane_16_2_exp2(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x half>,ptr %ap,align 1
 %b = load <2 x half>,ptr %bp,align 1
 %c = load <2 x half>,ptr %cp,align 1
 %r = call <2 x half> @llvm.exp2.v2f16(<2 x half> %a)
 store <2 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x half> @llvm.exp.v2f16(<2 x half>)
define i64 @floating_lane_16_2_exp(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x half>,ptr %ap,align 1
 %b = load <2 x half>,ptr %bp,align 1
 %c = load <2 x half>,ptr %cp,align 1
 %r = call <2 x half> @llvm.exp.v2f16(<2 x half> %a)
 store <2 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x half> @llvm.tan.v2f16(<2 x half>)
define i64 @floating_lane_16_2_tan(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x half>,ptr %ap,align 1
 %b = load <2 x half>,ptr %bp,align 1
 %c = load <2 x half>,ptr %cp,align 1
 %r = call <2 x half> @llvm.tan.v2f16(<2 x half> %a)
 store <2 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x half> @llvm.cos.v2f16(<2 x half>)
define i64 @floating_lane_16_2_cos(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x half>,ptr %ap,align 1
 %b = load <2 x half>,ptr %bp,align 1
 %c = load <2 x half>,ptr %cp,align 1
 %r = call <2 x half> @llvm.cos.v2f16(<2 x half> %a)
 store <2 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x half> @llvm.sin.v2f16(<2 x half>)
define i64 @floating_lane_16_2_sin(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x half>,ptr %ap,align 1
 %b = load <2 x half>,ptr %bp,align 1
 %c = load <2 x half>,ptr %cp,align 1
 %r = call <2 x half> @llvm.sin.v2f16(<2 x half> %a)
 store <2 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x half> @llvm.sqrt.v2f16(<2 x half>)
define i64 @floating_lane_16_2_sqrt(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x half>,ptr %ap,align 1
 %b = load <2 x half>,ptr %bp,align 1
 %c = load <2 x half>,ptr %cp,align 1
 %r = call <2 x half> @llvm.sqrt.v2f16(<2 x half> %a)
 store <2 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x half> @llvm.fma.v2f16(<2 x half>,<2 x half>,<2 x half>)
define i64 @floating_lane_16_2_fma(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x half>,ptr %ap,align 1
 %b = load <2 x half>,ptr %bp,align 1
 %c = load <2 x half>,ptr %cp,align 1
 %r = call <2 x half> @llvm.fma.v2f16(<2 x half> %a,<2 x half> %b,<2 x half> %c)
 store <2 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x half> @llvm.trunc.v3f16(<3 x half>)
define i64 @floating_lane_16_3_trunc(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x half>,ptr %ap,align 1
 %b = load <3 x half>,ptr %bp,align 1
 %c = load <3 x half>,ptr %cp,align 1
 %r = call <3 x half> @llvm.trunc.v3f16(<3 x half> %a)
 store <3 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x half> @llvm.round.v3f16(<3 x half>)
define i64 @floating_lane_16_3_round(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x half>,ptr %ap,align 1
 %b = load <3 x half>,ptr %bp,align 1
 %c = load <3 x half>,ptr %cp,align 1
 %r = call <3 x half> @llvm.round.v3f16(<3 x half> %a)
 store <3 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x half> @llvm.ceil.v3f16(<3 x half>)
define i64 @floating_lane_16_3_ceil(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x half>,ptr %ap,align 1
 %b = load <3 x half>,ptr %bp,align 1
 %c = load <3 x half>,ptr %cp,align 1
 %r = call <3 x half> @llvm.ceil.v3f16(<3 x half> %a)
 store <3 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x half> @llvm.floor.v3f16(<3 x half>)
define i64 @floating_lane_16_3_floor(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x half>,ptr %ap,align 1
 %b = load <3 x half>,ptr %bp,align 1
 %c = load <3 x half>,ptr %cp,align 1
 %r = call <3 x half> @llvm.floor.v3f16(<3 x half> %a)
 store <3 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x half> @llvm.log10.v3f16(<3 x half>)
define i64 @floating_lane_16_3_log10(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x half>,ptr %ap,align 1
 %b = load <3 x half>,ptr %bp,align 1
 %c = load <3 x half>,ptr %cp,align 1
 %r = call <3 x half> @llvm.log10.v3f16(<3 x half> %a)
 store <3 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x half> @llvm.log2.v3f16(<3 x half>)
define i64 @floating_lane_16_3_log2(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x half>,ptr %ap,align 1
 %b = load <3 x half>,ptr %bp,align 1
 %c = load <3 x half>,ptr %cp,align 1
 %r = call <3 x half> @llvm.log2.v3f16(<3 x half> %a)
 store <3 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x half> @llvm.log.v3f16(<3 x half>)
define i64 @floating_lane_16_3_log(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x half>,ptr %ap,align 1
 %b = load <3 x half>,ptr %bp,align 1
 %c = load <3 x half>,ptr %cp,align 1
 %r = call <3 x half> @llvm.log.v3f16(<3 x half> %a)
 store <3 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x half> @llvm.exp2.v3f16(<3 x half>)
define i64 @floating_lane_16_3_exp2(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x half>,ptr %ap,align 1
 %b = load <3 x half>,ptr %bp,align 1
 %c = load <3 x half>,ptr %cp,align 1
 %r = call <3 x half> @llvm.exp2.v3f16(<3 x half> %a)
 store <3 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x half> @llvm.exp.v3f16(<3 x half>)
define i64 @floating_lane_16_3_exp(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x half>,ptr %ap,align 1
 %b = load <3 x half>,ptr %bp,align 1
 %c = load <3 x half>,ptr %cp,align 1
 %r = call <3 x half> @llvm.exp.v3f16(<3 x half> %a)
 store <3 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x half> @llvm.tan.v3f16(<3 x half>)
define i64 @floating_lane_16_3_tan(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x half>,ptr %ap,align 1
 %b = load <3 x half>,ptr %bp,align 1
 %c = load <3 x half>,ptr %cp,align 1
 %r = call <3 x half> @llvm.tan.v3f16(<3 x half> %a)
 store <3 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x half> @llvm.cos.v3f16(<3 x half>)
define i64 @floating_lane_16_3_cos(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x half>,ptr %ap,align 1
 %b = load <3 x half>,ptr %bp,align 1
 %c = load <3 x half>,ptr %cp,align 1
 %r = call <3 x half> @llvm.cos.v3f16(<3 x half> %a)
 store <3 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x half> @llvm.sin.v3f16(<3 x half>)
define i64 @floating_lane_16_3_sin(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x half>,ptr %ap,align 1
 %b = load <3 x half>,ptr %bp,align 1
 %c = load <3 x half>,ptr %cp,align 1
 %r = call <3 x half> @llvm.sin.v3f16(<3 x half> %a)
 store <3 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x half> @llvm.sqrt.v3f16(<3 x half>)
define i64 @floating_lane_16_3_sqrt(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x half>,ptr %ap,align 1
 %b = load <3 x half>,ptr %bp,align 1
 %c = load <3 x half>,ptr %cp,align 1
 %r = call <3 x half> @llvm.sqrt.v3f16(<3 x half> %a)
 store <3 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x half> @llvm.fma.v3f16(<3 x half>,<3 x half>,<3 x half>)
define i64 @floating_lane_16_3_fma(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x half>,ptr %ap,align 1
 %b = load <3 x half>,ptr %bp,align 1
 %c = load <3 x half>,ptr %cp,align 1
 %r = call <3 x half> @llvm.fma.v3f16(<3 x half> %a,<3 x half> %b,<3 x half> %c)
 store <3 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x half> @llvm.trunc.v4f16(<4 x half>)
define i64 @floating_lane_16_4_trunc(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x half>,ptr %ap,align 1
 %b = load <4 x half>,ptr %bp,align 1
 %c = load <4 x half>,ptr %cp,align 1
 %r = call <4 x half> @llvm.trunc.v4f16(<4 x half> %a)
 store <4 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x half> @llvm.round.v4f16(<4 x half>)
define i64 @floating_lane_16_4_round(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x half>,ptr %ap,align 1
 %b = load <4 x half>,ptr %bp,align 1
 %c = load <4 x half>,ptr %cp,align 1
 %r = call <4 x half> @llvm.round.v4f16(<4 x half> %a)
 store <4 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x half> @llvm.ceil.v4f16(<4 x half>)
define i64 @floating_lane_16_4_ceil(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x half>,ptr %ap,align 1
 %b = load <4 x half>,ptr %bp,align 1
 %c = load <4 x half>,ptr %cp,align 1
 %r = call <4 x half> @llvm.ceil.v4f16(<4 x half> %a)
 store <4 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x half> @llvm.floor.v4f16(<4 x half>)
define i64 @floating_lane_16_4_floor(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x half>,ptr %ap,align 1
 %b = load <4 x half>,ptr %bp,align 1
 %c = load <4 x half>,ptr %cp,align 1
 %r = call <4 x half> @llvm.floor.v4f16(<4 x half> %a)
 store <4 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x half> @llvm.log10.v4f16(<4 x half>)
define i64 @floating_lane_16_4_log10(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x half>,ptr %ap,align 1
 %b = load <4 x half>,ptr %bp,align 1
 %c = load <4 x half>,ptr %cp,align 1
 %r = call <4 x half> @llvm.log10.v4f16(<4 x half> %a)
 store <4 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x half> @llvm.log2.v4f16(<4 x half>)
define i64 @floating_lane_16_4_log2(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x half>,ptr %ap,align 1
 %b = load <4 x half>,ptr %bp,align 1
 %c = load <4 x half>,ptr %cp,align 1
 %r = call <4 x half> @llvm.log2.v4f16(<4 x half> %a)
 store <4 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x half> @llvm.log.v4f16(<4 x half>)
define i64 @floating_lane_16_4_log(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x half>,ptr %ap,align 1
 %b = load <4 x half>,ptr %bp,align 1
 %c = load <4 x half>,ptr %cp,align 1
 %r = call <4 x half> @llvm.log.v4f16(<4 x half> %a)
 store <4 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x half> @llvm.exp2.v4f16(<4 x half>)
define i64 @floating_lane_16_4_exp2(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x half>,ptr %ap,align 1
 %b = load <4 x half>,ptr %bp,align 1
 %c = load <4 x half>,ptr %cp,align 1
 %r = call <4 x half> @llvm.exp2.v4f16(<4 x half> %a)
 store <4 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x half> @llvm.exp.v4f16(<4 x half>)
define i64 @floating_lane_16_4_exp(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x half>,ptr %ap,align 1
 %b = load <4 x half>,ptr %bp,align 1
 %c = load <4 x half>,ptr %cp,align 1
 %r = call <4 x half> @llvm.exp.v4f16(<4 x half> %a)
 store <4 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x half> @llvm.tan.v4f16(<4 x half>)
define i64 @floating_lane_16_4_tan(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x half>,ptr %ap,align 1
 %b = load <4 x half>,ptr %bp,align 1
 %c = load <4 x half>,ptr %cp,align 1
 %r = call <4 x half> @llvm.tan.v4f16(<4 x half> %a)
 store <4 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x half> @llvm.cos.v4f16(<4 x half>)
define i64 @floating_lane_16_4_cos(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x half>,ptr %ap,align 1
 %b = load <4 x half>,ptr %bp,align 1
 %c = load <4 x half>,ptr %cp,align 1
 %r = call <4 x half> @llvm.cos.v4f16(<4 x half> %a)
 store <4 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x half> @llvm.sin.v4f16(<4 x half>)
define i64 @floating_lane_16_4_sin(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x half>,ptr %ap,align 1
 %b = load <4 x half>,ptr %bp,align 1
 %c = load <4 x half>,ptr %cp,align 1
 %r = call <4 x half> @llvm.sin.v4f16(<4 x half> %a)
 store <4 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x half> @llvm.sqrt.v4f16(<4 x half>)
define i64 @floating_lane_16_4_sqrt(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x half>,ptr %ap,align 1
 %b = load <4 x half>,ptr %bp,align 1
 %c = load <4 x half>,ptr %cp,align 1
 %r = call <4 x half> @llvm.sqrt.v4f16(<4 x half> %a)
 store <4 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x half> @llvm.fma.v4f16(<4 x half>,<4 x half>,<4 x half>)
define i64 @floating_lane_16_4_fma(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x half>,ptr %ap,align 1
 %b = load <4 x half>,ptr %bp,align 1
 %c = load <4 x half>,ptr %cp,align 1
 %r = call <4 x half> @llvm.fma.v4f16(<4 x half> %a,<4 x half> %b,<4 x half> %c)
 store <4 x half> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x float> @llvm.trunc.v1f32(<1 x float>)
define i64 @floating_lane_32_1_trunc(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x float>,ptr %ap,align 1
 %b = load <1 x float>,ptr %bp,align 1
 %c = load <1 x float>,ptr %cp,align 1
 %r = call <1 x float> @llvm.trunc.v1f32(<1 x float> %a)
 store <1 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x float> @llvm.round.v1f32(<1 x float>)
define i64 @floating_lane_32_1_round(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x float>,ptr %ap,align 1
 %b = load <1 x float>,ptr %bp,align 1
 %c = load <1 x float>,ptr %cp,align 1
 %r = call <1 x float> @llvm.round.v1f32(<1 x float> %a)
 store <1 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x float> @llvm.ceil.v1f32(<1 x float>)
define i64 @floating_lane_32_1_ceil(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x float>,ptr %ap,align 1
 %b = load <1 x float>,ptr %bp,align 1
 %c = load <1 x float>,ptr %cp,align 1
 %r = call <1 x float> @llvm.ceil.v1f32(<1 x float> %a)
 store <1 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x float> @llvm.floor.v1f32(<1 x float>)
define i64 @floating_lane_32_1_floor(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x float>,ptr %ap,align 1
 %b = load <1 x float>,ptr %bp,align 1
 %c = load <1 x float>,ptr %cp,align 1
 %r = call <1 x float> @llvm.floor.v1f32(<1 x float> %a)
 store <1 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x float> @llvm.log10.v1f32(<1 x float>)
define i64 @floating_lane_32_1_log10(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x float>,ptr %ap,align 1
 %b = load <1 x float>,ptr %bp,align 1
 %c = load <1 x float>,ptr %cp,align 1
 %r = call <1 x float> @llvm.log10.v1f32(<1 x float> %a)
 store <1 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x float> @llvm.log2.v1f32(<1 x float>)
define i64 @floating_lane_32_1_log2(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x float>,ptr %ap,align 1
 %b = load <1 x float>,ptr %bp,align 1
 %c = load <1 x float>,ptr %cp,align 1
 %r = call <1 x float> @llvm.log2.v1f32(<1 x float> %a)
 store <1 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x float> @llvm.log.v1f32(<1 x float>)
define i64 @floating_lane_32_1_log(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x float>,ptr %ap,align 1
 %b = load <1 x float>,ptr %bp,align 1
 %c = load <1 x float>,ptr %cp,align 1
 %r = call <1 x float> @llvm.log.v1f32(<1 x float> %a)
 store <1 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x float> @llvm.exp2.v1f32(<1 x float>)
define i64 @floating_lane_32_1_exp2(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x float>,ptr %ap,align 1
 %b = load <1 x float>,ptr %bp,align 1
 %c = load <1 x float>,ptr %cp,align 1
 %r = call <1 x float> @llvm.exp2.v1f32(<1 x float> %a)
 store <1 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x float> @llvm.exp.v1f32(<1 x float>)
define i64 @floating_lane_32_1_exp(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x float>,ptr %ap,align 1
 %b = load <1 x float>,ptr %bp,align 1
 %c = load <1 x float>,ptr %cp,align 1
 %r = call <1 x float> @llvm.exp.v1f32(<1 x float> %a)
 store <1 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x float> @llvm.tan.v1f32(<1 x float>)
define i64 @floating_lane_32_1_tan(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x float>,ptr %ap,align 1
 %b = load <1 x float>,ptr %bp,align 1
 %c = load <1 x float>,ptr %cp,align 1
 %r = call <1 x float> @llvm.tan.v1f32(<1 x float> %a)
 store <1 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x float> @llvm.cos.v1f32(<1 x float>)
define i64 @floating_lane_32_1_cos(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x float>,ptr %ap,align 1
 %b = load <1 x float>,ptr %bp,align 1
 %c = load <1 x float>,ptr %cp,align 1
 %r = call <1 x float> @llvm.cos.v1f32(<1 x float> %a)
 store <1 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x float> @llvm.sin.v1f32(<1 x float>)
define i64 @floating_lane_32_1_sin(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x float>,ptr %ap,align 1
 %b = load <1 x float>,ptr %bp,align 1
 %c = load <1 x float>,ptr %cp,align 1
 %r = call <1 x float> @llvm.sin.v1f32(<1 x float> %a)
 store <1 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x float> @llvm.sqrt.v1f32(<1 x float>)
define i64 @floating_lane_32_1_sqrt(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x float>,ptr %ap,align 1
 %b = load <1 x float>,ptr %bp,align 1
 %c = load <1 x float>,ptr %cp,align 1
 %r = call <1 x float> @llvm.sqrt.v1f32(<1 x float> %a)
 store <1 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x float> @llvm.fma.v1f32(<1 x float>,<1 x float>,<1 x float>)
define i64 @floating_lane_32_1_fma(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x float>,ptr %ap,align 1
 %b = load <1 x float>,ptr %bp,align 1
 %c = load <1 x float>,ptr %cp,align 1
 %r = call <1 x float> @llvm.fma.v1f32(<1 x float> %a,<1 x float> %b,<1 x float> %c)
 store <1 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x float> @llvm.trunc.v2f32(<2 x float>)
define i64 @floating_lane_32_2_trunc(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x float>,ptr %ap,align 1
 %b = load <2 x float>,ptr %bp,align 1
 %c = load <2 x float>,ptr %cp,align 1
 %r = call <2 x float> @llvm.trunc.v2f32(<2 x float> %a)
 store <2 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x float> @llvm.round.v2f32(<2 x float>)
define i64 @floating_lane_32_2_round(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x float>,ptr %ap,align 1
 %b = load <2 x float>,ptr %bp,align 1
 %c = load <2 x float>,ptr %cp,align 1
 %r = call <2 x float> @llvm.round.v2f32(<2 x float> %a)
 store <2 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x float> @llvm.ceil.v2f32(<2 x float>)
define i64 @floating_lane_32_2_ceil(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x float>,ptr %ap,align 1
 %b = load <2 x float>,ptr %bp,align 1
 %c = load <2 x float>,ptr %cp,align 1
 %r = call <2 x float> @llvm.ceil.v2f32(<2 x float> %a)
 store <2 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x float> @llvm.floor.v2f32(<2 x float>)
define i64 @floating_lane_32_2_floor(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x float>,ptr %ap,align 1
 %b = load <2 x float>,ptr %bp,align 1
 %c = load <2 x float>,ptr %cp,align 1
 %r = call <2 x float> @llvm.floor.v2f32(<2 x float> %a)
 store <2 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x float> @llvm.log10.v2f32(<2 x float>)
define i64 @floating_lane_32_2_log10(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x float>,ptr %ap,align 1
 %b = load <2 x float>,ptr %bp,align 1
 %c = load <2 x float>,ptr %cp,align 1
 %r = call <2 x float> @llvm.log10.v2f32(<2 x float> %a)
 store <2 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x float> @llvm.log2.v2f32(<2 x float>)
define i64 @floating_lane_32_2_log2(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x float>,ptr %ap,align 1
 %b = load <2 x float>,ptr %bp,align 1
 %c = load <2 x float>,ptr %cp,align 1
 %r = call <2 x float> @llvm.log2.v2f32(<2 x float> %a)
 store <2 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x float> @llvm.log.v2f32(<2 x float>)
define i64 @floating_lane_32_2_log(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x float>,ptr %ap,align 1
 %b = load <2 x float>,ptr %bp,align 1
 %c = load <2 x float>,ptr %cp,align 1
 %r = call <2 x float> @llvm.log.v2f32(<2 x float> %a)
 store <2 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x float> @llvm.exp2.v2f32(<2 x float>)
define i64 @floating_lane_32_2_exp2(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x float>,ptr %ap,align 1
 %b = load <2 x float>,ptr %bp,align 1
 %c = load <2 x float>,ptr %cp,align 1
 %r = call <2 x float> @llvm.exp2.v2f32(<2 x float> %a)
 store <2 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x float> @llvm.exp.v2f32(<2 x float>)
define i64 @floating_lane_32_2_exp(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x float>,ptr %ap,align 1
 %b = load <2 x float>,ptr %bp,align 1
 %c = load <2 x float>,ptr %cp,align 1
 %r = call <2 x float> @llvm.exp.v2f32(<2 x float> %a)
 store <2 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x float> @llvm.tan.v2f32(<2 x float>)
define i64 @floating_lane_32_2_tan(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x float>,ptr %ap,align 1
 %b = load <2 x float>,ptr %bp,align 1
 %c = load <2 x float>,ptr %cp,align 1
 %r = call <2 x float> @llvm.tan.v2f32(<2 x float> %a)
 store <2 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x float> @llvm.cos.v2f32(<2 x float>)
define i64 @floating_lane_32_2_cos(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x float>,ptr %ap,align 1
 %b = load <2 x float>,ptr %bp,align 1
 %c = load <2 x float>,ptr %cp,align 1
 %r = call <2 x float> @llvm.cos.v2f32(<2 x float> %a)
 store <2 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x float> @llvm.sin.v2f32(<2 x float>)
define i64 @floating_lane_32_2_sin(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x float>,ptr %ap,align 1
 %b = load <2 x float>,ptr %bp,align 1
 %c = load <2 x float>,ptr %cp,align 1
 %r = call <2 x float> @llvm.sin.v2f32(<2 x float> %a)
 store <2 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x float> @llvm.sqrt.v2f32(<2 x float>)
define i64 @floating_lane_32_2_sqrt(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x float>,ptr %ap,align 1
 %b = load <2 x float>,ptr %bp,align 1
 %c = load <2 x float>,ptr %cp,align 1
 %r = call <2 x float> @llvm.sqrt.v2f32(<2 x float> %a)
 store <2 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x float> @llvm.fma.v2f32(<2 x float>,<2 x float>,<2 x float>)
define i64 @floating_lane_32_2_fma(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x float>,ptr %ap,align 1
 %b = load <2 x float>,ptr %bp,align 1
 %c = load <2 x float>,ptr %cp,align 1
 %r = call <2 x float> @llvm.fma.v2f32(<2 x float> %a,<2 x float> %b,<2 x float> %c)
 store <2 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x float> @llvm.trunc.v3f32(<3 x float>)
define i64 @floating_lane_32_3_trunc(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x float>,ptr %ap,align 1
 %b = load <3 x float>,ptr %bp,align 1
 %c = load <3 x float>,ptr %cp,align 1
 %r = call <3 x float> @llvm.trunc.v3f32(<3 x float> %a)
 store <3 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x float> @llvm.round.v3f32(<3 x float>)
define i64 @floating_lane_32_3_round(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x float>,ptr %ap,align 1
 %b = load <3 x float>,ptr %bp,align 1
 %c = load <3 x float>,ptr %cp,align 1
 %r = call <3 x float> @llvm.round.v3f32(<3 x float> %a)
 store <3 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x float> @llvm.ceil.v3f32(<3 x float>)
define i64 @floating_lane_32_3_ceil(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x float>,ptr %ap,align 1
 %b = load <3 x float>,ptr %bp,align 1
 %c = load <3 x float>,ptr %cp,align 1
 %r = call <3 x float> @llvm.ceil.v3f32(<3 x float> %a)
 store <3 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x float> @llvm.floor.v3f32(<3 x float>)
define i64 @floating_lane_32_3_floor(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x float>,ptr %ap,align 1
 %b = load <3 x float>,ptr %bp,align 1
 %c = load <3 x float>,ptr %cp,align 1
 %r = call <3 x float> @llvm.floor.v3f32(<3 x float> %a)
 store <3 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x float> @llvm.log10.v3f32(<3 x float>)
define i64 @floating_lane_32_3_log10(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x float>,ptr %ap,align 1
 %b = load <3 x float>,ptr %bp,align 1
 %c = load <3 x float>,ptr %cp,align 1
 %r = call <3 x float> @llvm.log10.v3f32(<3 x float> %a)
 store <3 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x float> @llvm.log2.v3f32(<3 x float>)
define i64 @floating_lane_32_3_log2(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x float>,ptr %ap,align 1
 %b = load <3 x float>,ptr %bp,align 1
 %c = load <3 x float>,ptr %cp,align 1
 %r = call <3 x float> @llvm.log2.v3f32(<3 x float> %a)
 store <3 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x float> @llvm.log.v3f32(<3 x float>)
define i64 @floating_lane_32_3_log(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x float>,ptr %ap,align 1
 %b = load <3 x float>,ptr %bp,align 1
 %c = load <3 x float>,ptr %cp,align 1
 %r = call <3 x float> @llvm.log.v3f32(<3 x float> %a)
 store <3 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x float> @llvm.exp2.v3f32(<3 x float>)
define i64 @floating_lane_32_3_exp2(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x float>,ptr %ap,align 1
 %b = load <3 x float>,ptr %bp,align 1
 %c = load <3 x float>,ptr %cp,align 1
 %r = call <3 x float> @llvm.exp2.v3f32(<3 x float> %a)
 store <3 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x float> @llvm.exp.v3f32(<3 x float>)
define i64 @floating_lane_32_3_exp(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x float>,ptr %ap,align 1
 %b = load <3 x float>,ptr %bp,align 1
 %c = load <3 x float>,ptr %cp,align 1
 %r = call <3 x float> @llvm.exp.v3f32(<3 x float> %a)
 store <3 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x float> @llvm.tan.v3f32(<3 x float>)
define i64 @floating_lane_32_3_tan(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x float>,ptr %ap,align 1
 %b = load <3 x float>,ptr %bp,align 1
 %c = load <3 x float>,ptr %cp,align 1
 %r = call <3 x float> @llvm.tan.v3f32(<3 x float> %a)
 store <3 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x float> @llvm.cos.v3f32(<3 x float>)
define i64 @floating_lane_32_3_cos(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x float>,ptr %ap,align 1
 %b = load <3 x float>,ptr %bp,align 1
 %c = load <3 x float>,ptr %cp,align 1
 %r = call <3 x float> @llvm.cos.v3f32(<3 x float> %a)
 store <3 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x float> @llvm.sin.v3f32(<3 x float>)
define i64 @floating_lane_32_3_sin(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x float>,ptr %ap,align 1
 %b = load <3 x float>,ptr %bp,align 1
 %c = load <3 x float>,ptr %cp,align 1
 %r = call <3 x float> @llvm.sin.v3f32(<3 x float> %a)
 store <3 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x float> @llvm.sqrt.v3f32(<3 x float>)
define i64 @floating_lane_32_3_sqrt(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x float>,ptr %ap,align 1
 %b = load <3 x float>,ptr %bp,align 1
 %c = load <3 x float>,ptr %cp,align 1
 %r = call <3 x float> @llvm.sqrt.v3f32(<3 x float> %a)
 store <3 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x float> @llvm.fma.v3f32(<3 x float>,<3 x float>,<3 x float>)
define i64 @floating_lane_32_3_fma(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x float>,ptr %ap,align 1
 %b = load <3 x float>,ptr %bp,align 1
 %c = load <3 x float>,ptr %cp,align 1
 %r = call <3 x float> @llvm.fma.v3f32(<3 x float> %a,<3 x float> %b,<3 x float> %c)
 store <3 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x float> @llvm.trunc.v4f32(<4 x float>)
define i64 @floating_lane_32_4_trunc(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x float>,ptr %ap,align 1
 %b = load <4 x float>,ptr %bp,align 1
 %c = load <4 x float>,ptr %cp,align 1
 %r = call <4 x float> @llvm.trunc.v4f32(<4 x float> %a)
 store <4 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x float> @llvm.round.v4f32(<4 x float>)
define i64 @floating_lane_32_4_round(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x float>,ptr %ap,align 1
 %b = load <4 x float>,ptr %bp,align 1
 %c = load <4 x float>,ptr %cp,align 1
 %r = call <4 x float> @llvm.round.v4f32(<4 x float> %a)
 store <4 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x float> @llvm.ceil.v4f32(<4 x float>)
define i64 @floating_lane_32_4_ceil(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x float>,ptr %ap,align 1
 %b = load <4 x float>,ptr %bp,align 1
 %c = load <4 x float>,ptr %cp,align 1
 %r = call <4 x float> @llvm.ceil.v4f32(<4 x float> %a)
 store <4 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x float> @llvm.floor.v4f32(<4 x float>)
define i64 @floating_lane_32_4_floor(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x float>,ptr %ap,align 1
 %b = load <4 x float>,ptr %bp,align 1
 %c = load <4 x float>,ptr %cp,align 1
 %r = call <4 x float> @llvm.floor.v4f32(<4 x float> %a)
 store <4 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x float> @llvm.log10.v4f32(<4 x float>)
define i64 @floating_lane_32_4_log10(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x float>,ptr %ap,align 1
 %b = load <4 x float>,ptr %bp,align 1
 %c = load <4 x float>,ptr %cp,align 1
 %r = call <4 x float> @llvm.log10.v4f32(<4 x float> %a)
 store <4 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x float> @llvm.log2.v4f32(<4 x float>)
define i64 @floating_lane_32_4_log2(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x float>,ptr %ap,align 1
 %b = load <4 x float>,ptr %bp,align 1
 %c = load <4 x float>,ptr %cp,align 1
 %r = call <4 x float> @llvm.log2.v4f32(<4 x float> %a)
 store <4 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x float> @llvm.log.v4f32(<4 x float>)
define i64 @floating_lane_32_4_log(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x float>,ptr %ap,align 1
 %b = load <4 x float>,ptr %bp,align 1
 %c = load <4 x float>,ptr %cp,align 1
 %r = call <4 x float> @llvm.log.v4f32(<4 x float> %a)
 store <4 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x float> @llvm.exp2.v4f32(<4 x float>)
define i64 @floating_lane_32_4_exp2(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x float>,ptr %ap,align 1
 %b = load <4 x float>,ptr %bp,align 1
 %c = load <4 x float>,ptr %cp,align 1
 %r = call <4 x float> @llvm.exp2.v4f32(<4 x float> %a)
 store <4 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x float> @llvm.exp.v4f32(<4 x float>)
define i64 @floating_lane_32_4_exp(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x float>,ptr %ap,align 1
 %b = load <4 x float>,ptr %bp,align 1
 %c = load <4 x float>,ptr %cp,align 1
 %r = call <4 x float> @llvm.exp.v4f32(<4 x float> %a)
 store <4 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x float> @llvm.tan.v4f32(<4 x float>)
define i64 @floating_lane_32_4_tan(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x float>,ptr %ap,align 1
 %b = load <4 x float>,ptr %bp,align 1
 %c = load <4 x float>,ptr %cp,align 1
 %r = call <4 x float> @llvm.tan.v4f32(<4 x float> %a)
 store <4 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x float> @llvm.cos.v4f32(<4 x float>)
define i64 @floating_lane_32_4_cos(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x float>,ptr %ap,align 1
 %b = load <4 x float>,ptr %bp,align 1
 %c = load <4 x float>,ptr %cp,align 1
 %r = call <4 x float> @llvm.cos.v4f32(<4 x float> %a)
 store <4 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x float> @llvm.sin.v4f32(<4 x float>)
define i64 @floating_lane_32_4_sin(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x float>,ptr %ap,align 1
 %b = load <4 x float>,ptr %bp,align 1
 %c = load <4 x float>,ptr %cp,align 1
 %r = call <4 x float> @llvm.sin.v4f32(<4 x float> %a)
 store <4 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x float> @llvm.sqrt.v4f32(<4 x float>)
define i64 @floating_lane_32_4_sqrt(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x float>,ptr %ap,align 1
 %b = load <4 x float>,ptr %bp,align 1
 %c = load <4 x float>,ptr %cp,align 1
 %r = call <4 x float> @llvm.sqrt.v4f32(<4 x float> %a)
 store <4 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x float> @llvm.fma.v4f32(<4 x float>,<4 x float>,<4 x float>)
define i64 @floating_lane_32_4_fma(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x float>,ptr %ap,align 1
 %b = load <4 x float>,ptr %bp,align 1
 %c = load <4 x float>,ptr %cp,align 1
 %r = call <4 x float> @llvm.fma.v4f32(<4 x float> %a,<4 x float> %b,<4 x float> %c)
 store <4 x float> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x double> @llvm.trunc.v1f64(<1 x double>)
define i64 @floating_lane_64_1_trunc(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x double>,ptr %ap,align 1
 %b = load <1 x double>,ptr %bp,align 1
 %c = load <1 x double>,ptr %cp,align 1
 %r = call <1 x double> @llvm.trunc.v1f64(<1 x double> %a)
 store <1 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x double> @llvm.round.v1f64(<1 x double>)
define i64 @floating_lane_64_1_round(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x double>,ptr %ap,align 1
 %b = load <1 x double>,ptr %bp,align 1
 %c = load <1 x double>,ptr %cp,align 1
 %r = call <1 x double> @llvm.round.v1f64(<1 x double> %a)
 store <1 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x double> @llvm.ceil.v1f64(<1 x double>)
define i64 @floating_lane_64_1_ceil(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x double>,ptr %ap,align 1
 %b = load <1 x double>,ptr %bp,align 1
 %c = load <1 x double>,ptr %cp,align 1
 %r = call <1 x double> @llvm.ceil.v1f64(<1 x double> %a)
 store <1 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x double> @llvm.floor.v1f64(<1 x double>)
define i64 @floating_lane_64_1_floor(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x double>,ptr %ap,align 1
 %b = load <1 x double>,ptr %bp,align 1
 %c = load <1 x double>,ptr %cp,align 1
 %r = call <1 x double> @llvm.floor.v1f64(<1 x double> %a)
 store <1 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x double> @llvm.log10.v1f64(<1 x double>)
define i64 @floating_lane_64_1_log10(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x double>,ptr %ap,align 1
 %b = load <1 x double>,ptr %bp,align 1
 %c = load <1 x double>,ptr %cp,align 1
 %r = call <1 x double> @llvm.log10.v1f64(<1 x double> %a)
 store <1 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x double> @llvm.log2.v1f64(<1 x double>)
define i64 @floating_lane_64_1_log2(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x double>,ptr %ap,align 1
 %b = load <1 x double>,ptr %bp,align 1
 %c = load <1 x double>,ptr %cp,align 1
 %r = call <1 x double> @llvm.log2.v1f64(<1 x double> %a)
 store <1 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x double> @llvm.log.v1f64(<1 x double>)
define i64 @floating_lane_64_1_log(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x double>,ptr %ap,align 1
 %b = load <1 x double>,ptr %bp,align 1
 %c = load <1 x double>,ptr %cp,align 1
 %r = call <1 x double> @llvm.log.v1f64(<1 x double> %a)
 store <1 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x double> @llvm.exp2.v1f64(<1 x double>)
define i64 @floating_lane_64_1_exp2(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x double>,ptr %ap,align 1
 %b = load <1 x double>,ptr %bp,align 1
 %c = load <1 x double>,ptr %cp,align 1
 %r = call <1 x double> @llvm.exp2.v1f64(<1 x double> %a)
 store <1 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x double> @llvm.exp.v1f64(<1 x double>)
define i64 @floating_lane_64_1_exp(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x double>,ptr %ap,align 1
 %b = load <1 x double>,ptr %bp,align 1
 %c = load <1 x double>,ptr %cp,align 1
 %r = call <1 x double> @llvm.exp.v1f64(<1 x double> %a)
 store <1 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x double> @llvm.tan.v1f64(<1 x double>)
define i64 @floating_lane_64_1_tan(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x double>,ptr %ap,align 1
 %b = load <1 x double>,ptr %bp,align 1
 %c = load <1 x double>,ptr %cp,align 1
 %r = call <1 x double> @llvm.tan.v1f64(<1 x double> %a)
 store <1 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x double> @llvm.cos.v1f64(<1 x double>)
define i64 @floating_lane_64_1_cos(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x double>,ptr %ap,align 1
 %b = load <1 x double>,ptr %bp,align 1
 %c = load <1 x double>,ptr %cp,align 1
 %r = call <1 x double> @llvm.cos.v1f64(<1 x double> %a)
 store <1 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x double> @llvm.sin.v1f64(<1 x double>)
define i64 @floating_lane_64_1_sin(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x double>,ptr %ap,align 1
 %b = load <1 x double>,ptr %bp,align 1
 %c = load <1 x double>,ptr %cp,align 1
 %r = call <1 x double> @llvm.sin.v1f64(<1 x double> %a)
 store <1 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x double> @llvm.sqrt.v1f64(<1 x double>)
define i64 @floating_lane_64_1_sqrt(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x double>,ptr %ap,align 1
 %b = load <1 x double>,ptr %bp,align 1
 %c = load <1 x double>,ptr %cp,align 1
 %r = call <1 x double> @llvm.sqrt.v1f64(<1 x double> %a)
 store <1 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x double> @llvm.fma.v1f64(<1 x double>,<1 x double>,<1 x double>)
define i64 @floating_lane_64_1_fma(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x double>,ptr %ap,align 1
 %b = load <1 x double>,ptr %bp,align 1
 %c = load <1 x double>,ptr %cp,align 1
 %r = call <1 x double> @llvm.fma.v1f64(<1 x double> %a,<1 x double> %b,<1 x double> %c)
 store <1 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x double> @llvm.trunc.v2f64(<2 x double>)
define i64 @floating_lane_64_2_trunc(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x double>,ptr %ap,align 1
 %b = load <2 x double>,ptr %bp,align 1
 %c = load <2 x double>,ptr %cp,align 1
 %r = call <2 x double> @llvm.trunc.v2f64(<2 x double> %a)
 store <2 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x double> @llvm.round.v2f64(<2 x double>)
define i64 @floating_lane_64_2_round(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x double>,ptr %ap,align 1
 %b = load <2 x double>,ptr %bp,align 1
 %c = load <2 x double>,ptr %cp,align 1
 %r = call <2 x double> @llvm.round.v2f64(<2 x double> %a)
 store <2 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x double> @llvm.ceil.v2f64(<2 x double>)
define i64 @floating_lane_64_2_ceil(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x double>,ptr %ap,align 1
 %b = load <2 x double>,ptr %bp,align 1
 %c = load <2 x double>,ptr %cp,align 1
 %r = call <2 x double> @llvm.ceil.v2f64(<2 x double> %a)
 store <2 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x double> @llvm.floor.v2f64(<2 x double>)
define i64 @floating_lane_64_2_floor(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x double>,ptr %ap,align 1
 %b = load <2 x double>,ptr %bp,align 1
 %c = load <2 x double>,ptr %cp,align 1
 %r = call <2 x double> @llvm.floor.v2f64(<2 x double> %a)
 store <2 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x double> @llvm.log10.v2f64(<2 x double>)
define i64 @floating_lane_64_2_log10(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x double>,ptr %ap,align 1
 %b = load <2 x double>,ptr %bp,align 1
 %c = load <2 x double>,ptr %cp,align 1
 %r = call <2 x double> @llvm.log10.v2f64(<2 x double> %a)
 store <2 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x double> @llvm.log2.v2f64(<2 x double>)
define i64 @floating_lane_64_2_log2(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x double>,ptr %ap,align 1
 %b = load <2 x double>,ptr %bp,align 1
 %c = load <2 x double>,ptr %cp,align 1
 %r = call <2 x double> @llvm.log2.v2f64(<2 x double> %a)
 store <2 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x double> @llvm.log.v2f64(<2 x double>)
define i64 @floating_lane_64_2_log(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x double>,ptr %ap,align 1
 %b = load <2 x double>,ptr %bp,align 1
 %c = load <2 x double>,ptr %cp,align 1
 %r = call <2 x double> @llvm.log.v2f64(<2 x double> %a)
 store <2 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x double> @llvm.exp2.v2f64(<2 x double>)
define i64 @floating_lane_64_2_exp2(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x double>,ptr %ap,align 1
 %b = load <2 x double>,ptr %bp,align 1
 %c = load <2 x double>,ptr %cp,align 1
 %r = call <2 x double> @llvm.exp2.v2f64(<2 x double> %a)
 store <2 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x double> @llvm.exp.v2f64(<2 x double>)
define i64 @floating_lane_64_2_exp(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x double>,ptr %ap,align 1
 %b = load <2 x double>,ptr %bp,align 1
 %c = load <2 x double>,ptr %cp,align 1
 %r = call <2 x double> @llvm.exp.v2f64(<2 x double> %a)
 store <2 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x double> @llvm.tan.v2f64(<2 x double>)
define i64 @floating_lane_64_2_tan(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x double>,ptr %ap,align 1
 %b = load <2 x double>,ptr %bp,align 1
 %c = load <2 x double>,ptr %cp,align 1
 %r = call <2 x double> @llvm.tan.v2f64(<2 x double> %a)
 store <2 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x double> @llvm.cos.v2f64(<2 x double>)
define i64 @floating_lane_64_2_cos(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x double>,ptr %ap,align 1
 %b = load <2 x double>,ptr %bp,align 1
 %c = load <2 x double>,ptr %cp,align 1
 %r = call <2 x double> @llvm.cos.v2f64(<2 x double> %a)
 store <2 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x double> @llvm.sin.v2f64(<2 x double>)
define i64 @floating_lane_64_2_sin(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x double>,ptr %ap,align 1
 %b = load <2 x double>,ptr %bp,align 1
 %c = load <2 x double>,ptr %cp,align 1
 %r = call <2 x double> @llvm.sin.v2f64(<2 x double> %a)
 store <2 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x double> @llvm.sqrt.v2f64(<2 x double>)
define i64 @floating_lane_64_2_sqrt(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x double>,ptr %ap,align 1
 %b = load <2 x double>,ptr %bp,align 1
 %c = load <2 x double>,ptr %cp,align 1
 %r = call <2 x double> @llvm.sqrt.v2f64(<2 x double> %a)
 store <2 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x double> @llvm.fma.v2f64(<2 x double>,<2 x double>,<2 x double>)
define i64 @floating_lane_64_2_fma(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x double>,ptr %ap,align 1
 %b = load <2 x double>,ptr %bp,align 1
 %c = load <2 x double>,ptr %cp,align 1
 %r = call <2 x double> @llvm.fma.v2f64(<2 x double> %a,<2 x double> %b,<2 x double> %c)
 store <2 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x double> @llvm.trunc.v3f64(<3 x double>)
define i64 @floating_lane_64_3_trunc(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x double>,ptr %ap,align 1
 %b = load <3 x double>,ptr %bp,align 1
 %c = load <3 x double>,ptr %cp,align 1
 %r = call <3 x double> @llvm.trunc.v3f64(<3 x double> %a)
 store <3 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x double> @llvm.round.v3f64(<3 x double>)
define i64 @floating_lane_64_3_round(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x double>,ptr %ap,align 1
 %b = load <3 x double>,ptr %bp,align 1
 %c = load <3 x double>,ptr %cp,align 1
 %r = call <3 x double> @llvm.round.v3f64(<3 x double> %a)
 store <3 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x double> @llvm.ceil.v3f64(<3 x double>)
define i64 @floating_lane_64_3_ceil(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x double>,ptr %ap,align 1
 %b = load <3 x double>,ptr %bp,align 1
 %c = load <3 x double>,ptr %cp,align 1
 %r = call <3 x double> @llvm.ceil.v3f64(<3 x double> %a)
 store <3 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x double> @llvm.floor.v3f64(<3 x double>)
define i64 @floating_lane_64_3_floor(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x double>,ptr %ap,align 1
 %b = load <3 x double>,ptr %bp,align 1
 %c = load <3 x double>,ptr %cp,align 1
 %r = call <3 x double> @llvm.floor.v3f64(<3 x double> %a)
 store <3 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x double> @llvm.log10.v3f64(<3 x double>)
define i64 @floating_lane_64_3_log10(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x double>,ptr %ap,align 1
 %b = load <3 x double>,ptr %bp,align 1
 %c = load <3 x double>,ptr %cp,align 1
 %r = call <3 x double> @llvm.log10.v3f64(<3 x double> %a)
 store <3 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x double> @llvm.log2.v3f64(<3 x double>)
define i64 @floating_lane_64_3_log2(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x double>,ptr %ap,align 1
 %b = load <3 x double>,ptr %bp,align 1
 %c = load <3 x double>,ptr %cp,align 1
 %r = call <3 x double> @llvm.log2.v3f64(<3 x double> %a)
 store <3 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x double> @llvm.log.v3f64(<3 x double>)
define i64 @floating_lane_64_3_log(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x double>,ptr %ap,align 1
 %b = load <3 x double>,ptr %bp,align 1
 %c = load <3 x double>,ptr %cp,align 1
 %r = call <3 x double> @llvm.log.v3f64(<3 x double> %a)
 store <3 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x double> @llvm.exp2.v3f64(<3 x double>)
define i64 @floating_lane_64_3_exp2(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x double>,ptr %ap,align 1
 %b = load <3 x double>,ptr %bp,align 1
 %c = load <3 x double>,ptr %cp,align 1
 %r = call <3 x double> @llvm.exp2.v3f64(<3 x double> %a)
 store <3 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x double> @llvm.exp.v3f64(<3 x double>)
define i64 @floating_lane_64_3_exp(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x double>,ptr %ap,align 1
 %b = load <3 x double>,ptr %bp,align 1
 %c = load <3 x double>,ptr %cp,align 1
 %r = call <3 x double> @llvm.exp.v3f64(<3 x double> %a)
 store <3 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x double> @llvm.tan.v3f64(<3 x double>)
define i64 @floating_lane_64_3_tan(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x double>,ptr %ap,align 1
 %b = load <3 x double>,ptr %bp,align 1
 %c = load <3 x double>,ptr %cp,align 1
 %r = call <3 x double> @llvm.tan.v3f64(<3 x double> %a)
 store <3 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x double> @llvm.cos.v3f64(<3 x double>)
define i64 @floating_lane_64_3_cos(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x double>,ptr %ap,align 1
 %b = load <3 x double>,ptr %bp,align 1
 %c = load <3 x double>,ptr %cp,align 1
 %r = call <3 x double> @llvm.cos.v3f64(<3 x double> %a)
 store <3 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x double> @llvm.sin.v3f64(<3 x double>)
define i64 @floating_lane_64_3_sin(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x double>,ptr %ap,align 1
 %b = load <3 x double>,ptr %bp,align 1
 %c = load <3 x double>,ptr %cp,align 1
 %r = call <3 x double> @llvm.sin.v3f64(<3 x double> %a)
 store <3 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x double> @llvm.sqrt.v3f64(<3 x double>)
define i64 @floating_lane_64_3_sqrt(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x double>,ptr %ap,align 1
 %b = load <3 x double>,ptr %bp,align 1
 %c = load <3 x double>,ptr %cp,align 1
 %r = call <3 x double> @llvm.sqrt.v3f64(<3 x double> %a)
 store <3 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x double> @llvm.fma.v3f64(<3 x double>,<3 x double>,<3 x double>)
define i64 @floating_lane_64_3_fma(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x double>,ptr %ap,align 1
 %b = load <3 x double>,ptr %bp,align 1
 %c = load <3 x double>,ptr %cp,align 1
 %r = call <3 x double> @llvm.fma.v3f64(<3 x double> %a,<3 x double> %b,<3 x double> %c)
 store <3 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x double> @llvm.trunc.v4f64(<4 x double>)
define i64 @floating_lane_64_4_trunc(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x double>,ptr %ap,align 1
 %b = load <4 x double>,ptr %bp,align 1
 %c = load <4 x double>,ptr %cp,align 1
 %r = call <4 x double> @llvm.trunc.v4f64(<4 x double> %a)
 store <4 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x double> @llvm.round.v4f64(<4 x double>)
define i64 @floating_lane_64_4_round(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x double>,ptr %ap,align 1
 %b = load <4 x double>,ptr %bp,align 1
 %c = load <4 x double>,ptr %cp,align 1
 %r = call <4 x double> @llvm.round.v4f64(<4 x double> %a)
 store <4 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x double> @llvm.ceil.v4f64(<4 x double>)
define i64 @floating_lane_64_4_ceil(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x double>,ptr %ap,align 1
 %b = load <4 x double>,ptr %bp,align 1
 %c = load <4 x double>,ptr %cp,align 1
 %r = call <4 x double> @llvm.ceil.v4f64(<4 x double> %a)
 store <4 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x double> @llvm.floor.v4f64(<4 x double>)
define i64 @floating_lane_64_4_floor(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x double>,ptr %ap,align 1
 %b = load <4 x double>,ptr %bp,align 1
 %c = load <4 x double>,ptr %cp,align 1
 %r = call <4 x double> @llvm.floor.v4f64(<4 x double> %a)
 store <4 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x double> @llvm.log10.v4f64(<4 x double>)
define i64 @floating_lane_64_4_log10(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x double>,ptr %ap,align 1
 %b = load <4 x double>,ptr %bp,align 1
 %c = load <4 x double>,ptr %cp,align 1
 %r = call <4 x double> @llvm.log10.v4f64(<4 x double> %a)
 store <4 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x double> @llvm.log2.v4f64(<4 x double>)
define i64 @floating_lane_64_4_log2(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x double>,ptr %ap,align 1
 %b = load <4 x double>,ptr %bp,align 1
 %c = load <4 x double>,ptr %cp,align 1
 %r = call <4 x double> @llvm.log2.v4f64(<4 x double> %a)
 store <4 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x double> @llvm.log.v4f64(<4 x double>)
define i64 @floating_lane_64_4_log(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x double>,ptr %ap,align 1
 %b = load <4 x double>,ptr %bp,align 1
 %c = load <4 x double>,ptr %cp,align 1
 %r = call <4 x double> @llvm.log.v4f64(<4 x double> %a)
 store <4 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x double> @llvm.exp2.v4f64(<4 x double>)
define i64 @floating_lane_64_4_exp2(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x double>,ptr %ap,align 1
 %b = load <4 x double>,ptr %bp,align 1
 %c = load <4 x double>,ptr %cp,align 1
 %r = call <4 x double> @llvm.exp2.v4f64(<4 x double> %a)
 store <4 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x double> @llvm.exp.v4f64(<4 x double>)
define i64 @floating_lane_64_4_exp(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x double>,ptr %ap,align 1
 %b = load <4 x double>,ptr %bp,align 1
 %c = load <4 x double>,ptr %cp,align 1
 %r = call <4 x double> @llvm.exp.v4f64(<4 x double> %a)
 store <4 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x double> @llvm.tan.v4f64(<4 x double>)
define i64 @floating_lane_64_4_tan(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x double>,ptr %ap,align 1
 %b = load <4 x double>,ptr %bp,align 1
 %c = load <4 x double>,ptr %cp,align 1
 %r = call <4 x double> @llvm.tan.v4f64(<4 x double> %a)
 store <4 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x double> @llvm.cos.v4f64(<4 x double>)
define i64 @floating_lane_64_4_cos(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x double>,ptr %ap,align 1
 %b = load <4 x double>,ptr %bp,align 1
 %c = load <4 x double>,ptr %cp,align 1
 %r = call <4 x double> @llvm.cos.v4f64(<4 x double> %a)
 store <4 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x double> @llvm.sin.v4f64(<4 x double>)
define i64 @floating_lane_64_4_sin(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x double>,ptr %ap,align 1
 %b = load <4 x double>,ptr %bp,align 1
 %c = load <4 x double>,ptr %cp,align 1
 %r = call <4 x double> @llvm.sin.v4f64(<4 x double> %a)
 store <4 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x double> @llvm.sqrt.v4f64(<4 x double>)
define i64 @floating_lane_64_4_sqrt(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x double>,ptr %ap,align 1
 %b = load <4 x double>,ptr %bp,align 1
 %c = load <4 x double>,ptr %cp,align 1
 %r = call <4 x double> @llvm.sqrt.v4f64(<4 x double> %a)
 store <4 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x double> @llvm.fma.v4f64(<4 x double>,<4 x double>,<4 x double>)
define i64 @floating_lane_64_4_fma(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x double>,ptr %ap,align 1
 %b = load <4 x double>,ptr %bp,align 1
 %c = load <4 x double>,ptr %cp,align 1
 %r = call <4 x double> @llvm.fma.v4f64(<4 x double> %a,<4 x double> %b,<4 x double> %c)
 store <4 x double> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x x86_fp80> @llvm.trunc.v1f80(<1 x x86_fp80>)
define i64 @floating_lane_80_1_trunc(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x x86_fp80>,ptr %ap,align 1
 %b = load <1 x x86_fp80>,ptr %bp,align 1
 %c = load <1 x x86_fp80>,ptr %cp,align 1
 %r = call <1 x x86_fp80> @llvm.trunc.v1f80(<1 x x86_fp80> %a)
 store <1 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x x86_fp80> @llvm.round.v1f80(<1 x x86_fp80>)
define i64 @floating_lane_80_1_round(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x x86_fp80>,ptr %ap,align 1
 %b = load <1 x x86_fp80>,ptr %bp,align 1
 %c = load <1 x x86_fp80>,ptr %cp,align 1
 %r = call <1 x x86_fp80> @llvm.round.v1f80(<1 x x86_fp80> %a)
 store <1 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x x86_fp80> @llvm.ceil.v1f80(<1 x x86_fp80>)
define i64 @floating_lane_80_1_ceil(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x x86_fp80>,ptr %ap,align 1
 %b = load <1 x x86_fp80>,ptr %bp,align 1
 %c = load <1 x x86_fp80>,ptr %cp,align 1
 %r = call <1 x x86_fp80> @llvm.ceil.v1f80(<1 x x86_fp80> %a)
 store <1 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x x86_fp80> @llvm.floor.v1f80(<1 x x86_fp80>)
define i64 @floating_lane_80_1_floor(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x x86_fp80>,ptr %ap,align 1
 %b = load <1 x x86_fp80>,ptr %bp,align 1
 %c = load <1 x x86_fp80>,ptr %cp,align 1
 %r = call <1 x x86_fp80> @llvm.floor.v1f80(<1 x x86_fp80> %a)
 store <1 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x x86_fp80> @llvm.log10.v1f80(<1 x x86_fp80>)
define i64 @floating_lane_80_1_log10(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x x86_fp80>,ptr %ap,align 1
 %b = load <1 x x86_fp80>,ptr %bp,align 1
 %c = load <1 x x86_fp80>,ptr %cp,align 1
 %r = call <1 x x86_fp80> @llvm.log10.v1f80(<1 x x86_fp80> %a)
 store <1 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x x86_fp80> @llvm.log2.v1f80(<1 x x86_fp80>)
define i64 @floating_lane_80_1_log2(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x x86_fp80>,ptr %ap,align 1
 %b = load <1 x x86_fp80>,ptr %bp,align 1
 %c = load <1 x x86_fp80>,ptr %cp,align 1
 %r = call <1 x x86_fp80> @llvm.log2.v1f80(<1 x x86_fp80> %a)
 store <1 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x x86_fp80> @llvm.log.v1f80(<1 x x86_fp80>)
define i64 @floating_lane_80_1_log(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x x86_fp80>,ptr %ap,align 1
 %b = load <1 x x86_fp80>,ptr %bp,align 1
 %c = load <1 x x86_fp80>,ptr %cp,align 1
 %r = call <1 x x86_fp80> @llvm.log.v1f80(<1 x x86_fp80> %a)
 store <1 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x x86_fp80> @llvm.exp2.v1f80(<1 x x86_fp80>)
define i64 @floating_lane_80_1_exp2(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x x86_fp80>,ptr %ap,align 1
 %b = load <1 x x86_fp80>,ptr %bp,align 1
 %c = load <1 x x86_fp80>,ptr %cp,align 1
 %r = call <1 x x86_fp80> @llvm.exp2.v1f80(<1 x x86_fp80> %a)
 store <1 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x x86_fp80> @llvm.exp.v1f80(<1 x x86_fp80>)
define i64 @floating_lane_80_1_exp(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x x86_fp80>,ptr %ap,align 1
 %b = load <1 x x86_fp80>,ptr %bp,align 1
 %c = load <1 x x86_fp80>,ptr %cp,align 1
 %r = call <1 x x86_fp80> @llvm.exp.v1f80(<1 x x86_fp80> %a)
 store <1 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x x86_fp80> @llvm.tan.v1f80(<1 x x86_fp80>)
define i64 @floating_lane_80_1_tan(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x x86_fp80>,ptr %ap,align 1
 %b = load <1 x x86_fp80>,ptr %bp,align 1
 %c = load <1 x x86_fp80>,ptr %cp,align 1
 %r = call <1 x x86_fp80> @llvm.tan.v1f80(<1 x x86_fp80> %a)
 store <1 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x x86_fp80> @llvm.cos.v1f80(<1 x x86_fp80>)
define i64 @floating_lane_80_1_cos(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x x86_fp80>,ptr %ap,align 1
 %b = load <1 x x86_fp80>,ptr %bp,align 1
 %c = load <1 x x86_fp80>,ptr %cp,align 1
 %r = call <1 x x86_fp80> @llvm.cos.v1f80(<1 x x86_fp80> %a)
 store <1 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x x86_fp80> @llvm.sin.v1f80(<1 x x86_fp80>)
define i64 @floating_lane_80_1_sin(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x x86_fp80>,ptr %ap,align 1
 %b = load <1 x x86_fp80>,ptr %bp,align 1
 %c = load <1 x x86_fp80>,ptr %cp,align 1
 %r = call <1 x x86_fp80> @llvm.sin.v1f80(<1 x x86_fp80> %a)
 store <1 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x x86_fp80> @llvm.sqrt.v1f80(<1 x x86_fp80>)
define i64 @floating_lane_80_1_sqrt(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x x86_fp80>,ptr %ap,align 1
 %b = load <1 x x86_fp80>,ptr %bp,align 1
 %c = load <1 x x86_fp80>,ptr %cp,align 1
 %r = call <1 x x86_fp80> @llvm.sqrt.v1f80(<1 x x86_fp80> %a)
 store <1 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x x86_fp80> @llvm.fma.v1f80(<1 x x86_fp80>,<1 x x86_fp80>,<1 x x86_fp80>)
define i64 @floating_lane_80_1_fma(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x x86_fp80>,ptr %ap,align 1
 %b = load <1 x x86_fp80>,ptr %bp,align 1
 %c = load <1 x x86_fp80>,ptr %cp,align 1
 %r = call <1 x x86_fp80> @llvm.fma.v1f80(<1 x x86_fp80> %a,<1 x x86_fp80> %b,<1 x x86_fp80> %c)
 store <1 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x x86_fp80> @llvm.trunc.v2f80(<2 x x86_fp80>)
define i64 @floating_lane_80_2_trunc(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x x86_fp80>,ptr %ap,align 1
 %b = load <2 x x86_fp80>,ptr %bp,align 1
 %c = load <2 x x86_fp80>,ptr %cp,align 1
 %r = call <2 x x86_fp80> @llvm.trunc.v2f80(<2 x x86_fp80> %a)
 store <2 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x x86_fp80> @llvm.round.v2f80(<2 x x86_fp80>)
define i64 @floating_lane_80_2_round(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x x86_fp80>,ptr %ap,align 1
 %b = load <2 x x86_fp80>,ptr %bp,align 1
 %c = load <2 x x86_fp80>,ptr %cp,align 1
 %r = call <2 x x86_fp80> @llvm.round.v2f80(<2 x x86_fp80> %a)
 store <2 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x x86_fp80> @llvm.ceil.v2f80(<2 x x86_fp80>)
define i64 @floating_lane_80_2_ceil(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x x86_fp80>,ptr %ap,align 1
 %b = load <2 x x86_fp80>,ptr %bp,align 1
 %c = load <2 x x86_fp80>,ptr %cp,align 1
 %r = call <2 x x86_fp80> @llvm.ceil.v2f80(<2 x x86_fp80> %a)
 store <2 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x x86_fp80> @llvm.floor.v2f80(<2 x x86_fp80>)
define i64 @floating_lane_80_2_floor(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x x86_fp80>,ptr %ap,align 1
 %b = load <2 x x86_fp80>,ptr %bp,align 1
 %c = load <2 x x86_fp80>,ptr %cp,align 1
 %r = call <2 x x86_fp80> @llvm.floor.v2f80(<2 x x86_fp80> %a)
 store <2 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x x86_fp80> @llvm.log10.v2f80(<2 x x86_fp80>)
define i64 @floating_lane_80_2_log10(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x x86_fp80>,ptr %ap,align 1
 %b = load <2 x x86_fp80>,ptr %bp,align 1
 %c = load <2 x x86_fp80>,ptr %cp,align 1
 %r = call <2 x x86_fp80> @llvm.log10.v2f80(<2 x x86_fp80> %a)
 store <2 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x x86_fp80> @llvm.log2.v2f80(<2 x x86_fp80>)
define i64 @floating_lane_80_2_log2(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x x86_fp80>,ptr %ap,align 1
 %b = load <2 x x86_fp80>,ptr %bp,align 1
 %c = load <2 x x86_fp80>,ptr %cp,align 1
 %r = call <2 x x86_fp80> @llvm.log2.v2f80(<2 x x86_fp80> %a)
 store <2 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x x86_fp80> @llvm.log.v2f80(<2 x x86_fp80>)
define i64 @floating_lane_80_2_log(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x x86_fp80>,ptr %ap,align 1
 %b = load <2 x x86_fp80>,ptr %bp,align 1
 %c = load <2 x x86_fp80>,ptr %cp,align 1
 %r = call <2 x x86_fp80> @llvm.log.v2f80(<2 x x86_fp80> %a)
 store <2 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x x86_fp80> @llvm.exp2.v2f80(<2 x x86_fp80>)
define i64 @floating_lane_80_2_exp2(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x x86_fp80>,ptr %ap,align 1
 %b = load <2 x x86_fp80>,ptr %bp,align 1
 %c = load <2 x x86_fp80>,ptr %cp,align 1
 %r = call <2 x x86_fp80> @llvm.exp2.v2f80(<2 x x86_fp80> %a)
 store <2 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x x86_fp80> @llvm.exp.v2f80(<2 x x86_fp80>)
define i64 @floating_lane_80_2_exp(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x x86_fp80>,ptr %ap,align 1
 %b = load <2 x x86_fp80>,ptr %bp,align 1
 %c = load <2 x x86_fp80>,ptr %cp,align 1
 %r = call <2 x x86_fp80> @llvm.exp.v2f80(<2 x x86_fp80> %a)
 store <2 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x x86_fp80> @llvm.tan.v2f80(<2 x x86_fp80>)
define i64 @floating_lane_80_2_tan(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x x86_fp80>,ptr %ap,align 1
 %b = load <2 x x86_fp80>,ptr %bp,align 1
 %c = load <2 x x86_fp80>,ptr %cp,align 1
 %r = call <2 x x86_fp80> @llvm.tan.v2f80(<2 x x86_fp80> %a)
 store <2 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x x86_fp80> @llvm.cos.v2f80(<2 x x86_fp80>)
define i64 @floating_lane_80_2_cos(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x x86_fp80>,ptr %ap,align 1
 %b = load <2 x x86_fp80>,ptr %bp,align 1
 %c = load <2 x x86_fp80>,ptr %cp,align 1
 %r = call <2 x x86_fp80> @llvm.cos.v2f80(<2 x x86_fp80> %a)
 store <2 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x x86_fp80> @llvm.sin.v2f80(<2 x x86_fp80>)
define i64 @floating_lane_80_2_sin(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x x86_fp80>,ptr %ap,align 1
 %b = load <2 x x86_fp80>,ptr %bp,align 1
 %c = load <2 x x86_fp80>,ptr %cp,align 1
 %r = call <2 x x86_fp80> @llvm.sin.v2f80(<2 x x86_fp80> %a)
 store <2 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x x86_fp80> @llvm.sqrt.v2f80(<2 x x86_fp80>)
define i64 @floating_lane_80_2_sqrt(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x x86_fp80>,ptr %ap,align 1
 %b = load <2 x x86_fp80>,ptr %bp,align 1
 %c = load <2 x x86_fp80>,ptr %cp,align 1
 %r = call <2 x x86_fp80> @llvm.sqrt.v2f80(<2 x x86_fp80> %a)
 store <2 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x x86_fp80> @llvm.fma.v2f80(<2 x x86_fp80>,<2 x x86_fp80>,<2 x x86_fp80>)
define i64 @floating_lane_80_2_fma(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x x86_fp80>,ptr %ap,align 1
 %b = load <2 x x86_fp80>,ptr %bp,align 1
 %c = load <2 x x86_fp80>,ptr %cp,align 1
 %r = call <2 x x86_fp80> @llvm.fma.v2f80(<2 x x86_fp80> %a,<2 x x86_fp80> %b,<2 x x86_fp80> %c)
 store <2 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x x86_fp80> @llvm.trunc.v3f80(<3 x x86_fp80>)
define i64 @floating_lane_80_3_trunc(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x x86_fp80>,ptr %ap,align 1
 %b = load <3 x x86_fp80>,ptr %bp,align 1
 %c = load <3 x x86_fp80>,ptr %cp,align 1
 %r = call <3 x x86_fp80> @llvm.trunc.v3f80(<3 x x86_fp80> %a)
 store <3 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x x86_fp80> @llvm.round.v3f80(<3 x x86_fp80>)
define i64 @floating_lane_80_3_round(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x x86_fp80>,ptr %ap,align 1
 %b = load <3 x x86_fp80>,ptr %bp,align 1
 %c = load <3 x x86_fp80>,ptr %cp,align 1
 %r = call <3 x x86_fp80> @llvm.round.v3f80(<3 x x86_fp80> %a)
 store <3 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x x86_fp80> @llvm.ceil.v3f80(<3 x x86_fp80>)
define i64 @floating_lane_80_3_ceil(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x x86_fp80>,ptr %ap,align 1
 %b = load <3 x x86_fp80>,ptr %bp,align 1
 %c = load <3 x x86_fp80>,ptr %cp,align 1
 %r = call <3 x x86_fp80> @llvm.ceil.v3f80(<3 x x86_fp80> %a)
 store <3 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x x86_fp80> @llvm.floor.v3f80(<3 x x86_fp80>)
define i64 @floating_lane_80_3_floor(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x x86_fp80>,ptr %ap,align 1
 %b = load <3 x x86_fp80>,ptr %bp,align 1
 %c = load <3 x x86_fp80>,ptr %cp,align 1
 %r = call <3 x x86_fp80> @llvm.floor.v3f80(<3 x x86_fp80> %a)
 store <3 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x x86_fp80> @llvm.log10.v3f80(<3 x x86_fp80>)
define i64 @floating_lane_80_3_log10(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x x86_fp80>,ptr %ap,align 1
 %b = load <3 x x86_fp80>,ptr %bp,align 1
 %c = load <3 x x86_fp80>,ptr %cp,align 1
 %r = call <3 x x86_fp80> @llvm.log10.v3f80(<3 x x86_fp80> %a)
 store <3 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x x86_fp80> @llvm.log2.v3f80(<3 x x86_fp80>)
define i64 @floating_lane_80_3_log2(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x x86_fp80>,ptr %ap,align 1
 %b = load <3 x x86_fp80>,ptr %bp,align 1
 %c = load <3 x x86_fp80>,ptr %cp,align 1
 %r = call <3 x x86_fp80> @llvm.log2.v3f80(<3 x x86_fp80> %a)
 store <3 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x x86_fp80> @llvm.log.v3f80(<3 x x86_fp80>)
define i64 @floating_lane_80_3_log(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x x86_fp80>,ptr %ap,align 1
 %b = load <3 x x86_fp80>,ptr %bp,align 1
 %c = load <3 x x86_fp80>,ptr %cp,align 1
 %r = call <3 x x86_fp80> @llvm.log.v3f80(<3 x x86_fp80> %a)
 store <3 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x x86_fp80> @llvm.exp2.v3f80(<3 x x86_fp80>)
define i64 @floating_lane_80_3_exp2(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x x86_fp80>,ptr %ap,align 1
 %b = load <3 x x86_fp80>,ptr %bp,align 1
 %c = load <3 x x86_fp80>,ptr %cp,align 1
 %r = call <3 x x86_fp80> @llvm.exp2.v3f80(<3 x x86_fp80> %a)
 store <3 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x x86_fp80> @llvm.exp.v3f80(<3 x x86_fp80>)
define i64 @floating_lane_80_3_exp(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x x86_fp80>,ptr %ap,align 1
 %b = load <3 x x86_fp80>,ptr %bp,align 1
 %c = load <3 x x86_fp80>,ptr %cp,align 1
 %r = call <3 x x86_fp80> @llvm.exp.v3f80(<3 x x86_fp80> %a)
 store <3 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x x86_fp80> @llvm.tan.v3f80(<3 x x86_fp80>)
define i64 @floating_lane_80_3_tan(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x x86_fp80>,ptr %ap,align 1
 %b = load <3 x x86_fp80>,ptr %bp,align 1
 %c = load <3 x x86_fp80>,ptr %cp,align 1
 %r = call <3 x x86_fp80> @llvm.tan.v3f80(<3 x x86_fp80> %a)
 store <3 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x x86_fp80> @llvm.cos.v3f80(<3 x x86_fp80>)
define i64 @floating_lane_80_3_cos(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x x86_fp80>,ptr %ap,align 1
 %b = load <3 x x86_fp80>,ptr %bp,align 1
 %c = load <3 x x86_fp80>,ptr %cp,align 1
 %r = call <3 x x86_fp80> @llvm.cos.v3f80(<3 x x86_fp80> %a)
 store <3 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x x86_fp80> @llvm.sin.v3f80(<3 x x86_fp80>)
define i64 @floating_lane_80_3_sin(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x x86_fp80>,ptr %ap,align 1
 %b = load <3 x x86_fp80>,ptr %bp,align 1
 %c = load <3 x x86_fp80>,ptr %cp,align 1
 %r = call <3 x x86_fp80> @llvm.sin.v3f80(<3 x x86_fp80> %a)
 store <3 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x x86_fp80> @llvm.sqrt.v3f80(<3 x x86_fp80>)
define i64 @floating_lane_80_3_sqrt(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x x86_fp80>,ptr %ap,align 1
 %b = load <3 x x86_fp80>,ptr %bp,align 1
 %c = load <3 x x86_fp80>,ptr %cp,align 1
 %r = call <3 x x86_fp80> @llvm.sqrt.v3f80(<3 x x86_fp80> %a)
 store <3 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x x86_fp80> @llvm.fma.v3f80(<3 x x86_fp80>,<3 x x86_fp80>,<3 x x86_fp80>)
define i64 @floating_lane_80_3_fma(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x x86_fp80>,ptr %ap,align 1
 %b = load <3 x x86_fp80>,ptr %bp,align 1
 %c = load <3 x x86_fp80>,ptr %cp,align 1
 %r = call <3 x x86_fp80> @llvm.fma.v3f80(<3 x x86_fp80> %a,<3 x x86_fp80> %b,<3 x x86_fp80> %c)
 store <3 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x x86_fp80> @llvm.trunc.v4f80(<4 x x86_fp80>)
define i64 @floating_lane_80_4_trunc(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x x86_fp80>,ptr %ap,align 1
 %b = load <4 x x86_fp80>,ptr %bp,align 1
 %c = load <4 x x86_fp80>,ptr %cp,align 1
 %r = call <4 x x86_fp80> @llvm.trunc.v4f80(<4 x x86_fp80> %a)
 store <4 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x x86_fp80> @llvm.round.v4f80(<4 x x86_fp80>)
define i64 @floating_lane_80_4_round(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x x86_fp80>,ptr %ap,align 1
 %b = load <4 x x86_fp80>,ptr %bp,align 1
 %c = load <4 x x86_fp80>,ptr %cp,align 1
 %r = call <4 x x86_fp80> @llvm.round.v4f80(<4 x x86_fp80> %a)
 store <4 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x x86_fp80> @llvm.ceil.v4f80(<4 x x86_fp80>)
define i64 @floating_lane_80_4_ceil(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x x86_fp80>,ptr %ap,align 1
 %b = load <4 x x86_fp80>,ptr %bp,align 1
 %c = load <4 x x86_fp80>,ptr %cp,align 1
 %r = call <4 x x86_fp80> @llvm.ceil.v4f80(<4 x x86_fp80> %a)
 store <4 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x x86_fp80> @llvm.floor.v4f80(<4 x x86_fp80>)
define i64 @floating_lane_80_4_floor(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x x86_fp80>,ptr %ap,align 1
 %b = load <4 x x86_fp80>,ptr %bp,align 1
 %c = load <4 x x86_fp80>,ptr %cp,align 1
 %r = call <4 x x86_fp80> @llvm.floor.v4f80(<4 x x86_fp80> %a)
 store <4 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x x86_fp80> @llvm.log10.v4f80(<4 x x86_fp80>)
define i64 @floating_lane_80_4_log10(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x x86_fp80>,ptr %ap,align 1
 %b = load <4 x x86_fp80>,ptr %bp,align 1
 %c = load <4 x x86_fp80>,ptr %cp,align 1
 %r = call <4 x x86_fp80> @llvm.log10.v4f80(<4 x x86_fp80> %a)
 store <4 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x x86_fp80> @llvm.log2.v4f80(<4 x x86_fp80>)
define i64 @floating_lane_80_4_log2(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x x86_fp80>,ptr %ap,align 1
 %b = load <4 x x86_fp80>,ptr %bp,align 1
 %c = load <4 x x86_fp80>,ptr %cp,align 1
 %r = call <4 x x86_fp80> @llvm.log2.v4f80(<4 x x86_fp80> %a)
 store <4 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x x86_fp80> @llvm.log.v4f80(<4 x x86_fp80>)
define i64 @floating_lane_80_4_log(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x x86_fp80>,ptr %ap,align 1
 %b = load <4 x x86_fp80>,ptr %bp,align 1
 %c = load <4 x x86_fp80>,ptr %cp,align 1
 %r = call <4 x x86_fp80> @llvm.log.v4f80(<4 x x86_fp80> %a)
 store <4 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x x86_fp80> @llvm.exp2.v4f80(<4 x x86_fp80>)
define i64 @floating_lane_80_4_exp2(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x x86_fp80>,ptr %ap,align 1
 %b = load <4 x x86_fp80>,ptr %bp,align 1
 %c = load <4 x x86_fp80>,ptr %cp,align 1
 %r = call <4 x x86_fp80> @llvm.exp2.v4f80(<4 x x86_fp80> %a)
 store <4 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x x86_fp80> @llvm.exp.v4f80(<4 x x86_fp80>)
define i64 @floating_lane_80_4_exp(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x x86_fp80>,ptr %ap,align 1
 %b = load <4 x x86_fp80>,ptr %bp,align 1
 %c = load <4 x x86_fp80>,ptr %cp,align 1
 %r = call <4 x x86_fp80> @llvm.exp.v4f80(<4 x x86_fp80> %a)
 store <4 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x x86_fp80> @llvm.tan.v4f80(<4 x x86_fp80>)
define i64 @floating_lane_80_4_tan(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x x86_fp80>,ptr %ap,align 1
 %b = load <4 x x86_fp80>,ptr %bp,align 1
 %c = load <4 x x86_fp80>,ptr %cp,align 1
 %r = call <4 x x86_fp80> @llvm.tan.v4f80(<4 x x86_fp80> %a)
 store <4 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x x86_fp80> @llvm.cos.v4f80(<4 x x86_fp80>)
define i64 @floating_lane_80_4_cos(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x x86_fp80>,ptr %ap,align 1
 %b = load <4 x x86_fp80>,ptr %bp,align 1
 %c = load <4 x x86_fp80>,ptr %cp,align 1
 %r = call <4 x x86_fp80> @llvm.cos.v4f80(<4 x x86_fp80> %a)
 store <4 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x x86_fp80> @llvm.sin.v4f80(<4 x x86_fp80>)
define i64 @floating_lane_80_4_sin(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x x86_fp80>,ptr %ap,align 1
 %b = load <4 x x86_fp80>,ptr %bp,align 1
 %c = load <4 x x86_fp80>,ptr %cp,align 1
 %r = call <4 x x86_fp80> @llvm.sin.v4f80(<4 x x86_fp80> %a)
 store <4 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x x86_fp80> @llvm.sqrt.v4f80(<4 x x86_fp80>)
define i64 @floating_lane_80_4_sqrt(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x x86_fp80>,ptr %ap,align 1
 %b = load <4 x x86_fp80>,ptr %bp,align 1
 %c = load <4 x x86_fp80>,ptr %cp,align 1
 %r = call <4 x x86_fp80> @llvm.sqrt.v4f80(<4 x x86_fp80> %a)
 store <4 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x x86_fp80> @llvm.fma.v4f80(<4 x x86_fp80>,<4 x x86_fp80>,<4 x x86_fp80>)
define i64 @floating_lane_80_4_fma(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x x86_fp80>,ptr %ap,align 1
 %b = load <4 x x86_fp80>,ptr %bp,align 1
 %c = load <4 x x86_fp80>,ptr %cp,align 1
 %r = call <4 x x86_fp80> @llvm.fma.v4f80(<4 x x86_fp80> %a,<4 x x86_fp80> %b,<4 x x86_fp80> %c)
 store <4 x x86_fp80> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x fp128> @llvm.trunc.v1f128(<1 x fp128>)
define i64 @floating_lane_128_1_trunc(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x fp128>,ptr %ap,align 1
 %b = load <1 x fp128>,ptr %bp,align 1
 %c = load <1 x fp128>,ptr %cp,align 1
 %r = call <1 x fp128> @llvm.trunc.v1f128(<1 x fp128> %a)
 store <1 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x fp128> @llvm.round.v1f128(<1 x fp128>)
define i64 @floating_lane_128_1_round(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x fp128>,ptr %ap,align 1
 %b = load <1 x fp128>,ptr %bp,align 1
 %c = load <1 x fp128>,ptr %cp,align 1
 %r = call <1 x fp128> @llvm.round.v1f128(<1 x fp128> %a)
 store <1 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x fp128> @llvm.ceil.v1f128(<1 x fp128>)
define i64 @floating_lane_128_1_ceil(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x fp128>,ptr %ap,align 1
 %b = load <1 x fp128>,ptr %bp,align 1
 %c = load <1 x fp128>,ptr %cp,align 1
 %r = call <1 x fp128> @llvm.ceil.v1f128(<1 x fp128> %a)
 store <1 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x fp128> @llvm.floor.v1f128(<1 x fp128>)
define i64 @floating_lane_128_1_floor(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x fp128>,ptr %ap,align 1
 %b = load <1 x fp128>,ptr %bp,align 1
 %c = load <1 x fp128>,ptr %cp,align 1
 %r = call <1 x fp128> @llvm.floor.v1f128(<1 x fp128> %a)
 store <1 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x fp128> @llvm.log10.v1f128(<1 x fp128>)
define i64 @floating_lane_128_1_log10(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x fp128>,ptr %ap,align 1
 %b = load <1 x fp128>,ptr %bp,align 1
 %c = load <1 x fp128>,ptr %cp,align 1
 %r = call <1 x fp128> @llvm.log10.v1f128(<1 x fp128> %a)
 store <1 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x fp128> @llvm.log2.v1f128(<1 x fp128>)
define i64 @floating_lane_128_1_log2(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x fp128>,ptr %ap,align 1
 %b = load <1 x fp128>,ptr %bp,align 1
 %c = load <1 x fp128>,ptr %cp,align 1
 %r = call <1 x fp128> @llvm.log2.v1f128(<1 x fp128> %a)
 store <1 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x fp128> @llvm.log.v1f128(<1 x fp128>)
define i64 @floating_lane_128_1_log(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x fp128>,ptr %ap,align 1
 %b = load <1 x fp128>,ptr %bp,align 1
 %c = load <1 x fp128>,ptr %cp,align 1
 %r = call <1 x fp128> @llvm.log.v1f128(<1 x fp128> %a)
 store <1 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x fp128> @llvm.exp2.v1f128(<1 x fp128>)
define i64 @floating_lane_128_1_exp2(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x fp128>,ptr %ap,align 1
 %b = load <1 x fp128>,ptr %bp,align 1
 %c = load <1 x fp128>,ptr %cp,align 1
 %r = call <1 x fp128> @llvm.exp2.v1f128(<1 x fp128> %a)
 store <1 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x fp128> @llvm.exp.v1f128(<1 x fp128>)
define i64 @floating_lane_128_1_exp(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x fp128>,ptr %ap,align 1
 %b = load <1 x fp128>,ptr %bp,align 1
 %c = load <1 x fp128>,ptr %cp,align 1
 %r = call <1 x fp128> @llvm.exp.v1f128(<1 x fp128> %a)
 store <1 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x fp128> @llvm.tan.v1f128(<1 x fp128>)
define i64 @floating_lane_128_1_tan(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x fp128>,ptr %ap,align 1
 %b = load <1 x fp128>,ptr %bp,align 1
 %c = load <1 x fp128>,ptr %cp,align 1
 %r = call <1 x fp128> @llvm.tan.v1f128(<1 x fp128> %a)
 store <1 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x fp128> @llvm.cos.v1f128(<1 x fp128>)
define i64 @floating_lane_128_1_cos(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x fp128>,ptr %ap,align 1
 %b = load <1 x fp128>,ptr %bp,align 1
 %c = load <1 x fp128>,ptr %cp,align 1
 %r = call <1 x fp128> @llvm.cos.v1f128(<1 x fp128> %a)
 store <1 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x fp128> @llvm.sin.v1f128(<1 x fp128>)
define i64 @floating_lane_128_1_sin(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x fp128>,ptr %ap,align 1
 %b = load <1 x fp128>,ptr %bp,align 1
 %c = load <1 x fp128>,ptr %cp,align 1
 %r = call <1 x fp128> @llvm.sin.v1f128(<1 x fp128> %a)
 store <1 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x fp128> @llvm.sqrt.v1f128(<1 x fp128>)
define i64 @floating_lane_128_1_sqrt(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x fp128>,ptr %ap,align 1
 %b = load <1 x fp128>,ptr %bp,align 1
 %c = load <1 x fp128>,ptr %cp,align 1
 %r = call <1 x fp128> @llvm.sqrt.v1f128(<1 x fp128> %a)
 store <1 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <1 x fp128> @llvm.fma.v1f128(<1 x fp128>,<1 x fp128>,<1 x fp128>)
define i64 @floating_lane_128_1_fma(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <1 x fp128>,ptr %ap,align 1
 %b = load <1 x fp128>,ptr %bp,align 1
 %c = load <1 x fp128>,ptr %cp,align 1
 %r = call <1 x fp128> @llvm.fma.v1f128(<1 x fp128> %a,<1 x fp128> %b,<1 x fp128> %c)
 store <1 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x fp128> @llvm.trunc.v2f128(<2 x fp128>)
define i64 @floating_lane_128_2_trunc(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x fp128>,ptr %ap,align 1
 %b = load <2 x fp128>,ptr %bp,align 1
 %c = load <2 x fp128>,ptr %cp,align 1
 %r = call <2 x fp128> @llvm.trunc.v2f128(<2 x fp128> %a)
 store <2 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x fp128> @llvm.round.v2f128(<2 x fp128>)
define i64 @floating_lane_128_2_round(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x fp128>,ptr %ap,align 1
 %b = load <2 x fp128>,ptr %bp,align 1
 %c = load <2 x fp128>,ptr %cp,align 1
 %r = call <2 x fp128> @llvm.round.v2f128(<2 x fp128> %a)
 store <2 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x fp128> @llvm.ceil.v2f128(<2 x fp128>)
define i64 @floating_lane_128_2_ceil(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x fp128>,ptr %ap,align 1
 %b = load <2 x fp128>,ptr %bp,align 1
 %c = load <2 x fp128>,ptr %cp,align 1
 %r = call <2 x fp128> @llvm.ceil.v2f128(<2 x fp128> %a)
 store <2 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x fp128> @llvm.floor.v2f128(<2 x fp128>)
define i64 @floating_lane_128_2_floor(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x fp128>,ptr %ap,align 1
 %b = load <2 x fp128>,ptr %bp,align 1
 %c = load <2 x fp128>,ptr %cp,align 1
 %r = call <2 x fp128> @llvm.floor.v2f128(<2 x fp128> %a)
 store <2 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x fp128> @llvm.log10.v2f128(<2 x fp128>)
define i64 @floating_lane_128_2_log10(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x fp128>,ptr %ap,align 1
 %b = load <2 x fp128>,ptr %bp,align 1
 %c = load <2 x fp128>,ptr %cp,align 1
 %r = call <2 x fp128> @llvm.log10.v2f128(<2 x fp128> %a)
 store <2 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x fp128> @llvm.log2.v2f128(<2 x fp128>)
define i64 @floating_lane_128_2_log2(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x fp128>,ptr %ap,align 1
 %b = load <2 x fp128>,ptr %bp,align 1
 %c = load <2 x fp128>,ptr %cp,align 1
 %r = call <2 x fp128> @llvm.log2.v2f128(<2 x fp128> %a)
 store <2 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x fp128> @llvm.log.v2f128(<2 x fp128>)
define i64 @floating_lane_128_2_log(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x fp128>,ptr %ap,align 1
 %b = load <2 x fp128>,ptr %bp,align 1
 %c = load <2 x fp128>,ptr %cp,align 1
 %r = call <2 x fp128> @llvm.log.v2f128(<2 x fp128> %a)
 store <2 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x fp128> @llvm.exp2.v2f128(<2 x fp128>)
define i64 @floating_lane_128_2_exp2(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x fp128>,ptr %ap,align 1
 %b = load <2 x fp128>,ptr %bp,align 1
 %c = load <2 x fp128>,ptr %cp,align 1
 %r = call <2 x fp128> @llvm.exp2.v2f128(<2 x fp128> %a)
 store <2 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x fp128> @llvm.exp.v2f128(<2 x fp128>)
define i64 @floating_lane_128_2_exp(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x fp128>,ptr %ap,align 1
 %b = load <2 x fp128>,ptr %bp,align 1
 %c = load <2 x fp128>,ptr %cp,align 1
 %r = call <2 x fp128> @llvm.exp.v2f128(<2 x fp128> %a)
 store <2 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x fp128> @llvm.tan.v2f128(<2 x fp128>)
define i64 @floating_lane_128_2_tan(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x fp128>,ptr %ap,align 1
 %b = load <2 x fp128>,ptr %bp,align 1
 %c = load <2 x fp128>,ptr %cp,align 1
 %r = call <2 x fp128> @llvm.tan.v2f128(<2 x fp128> %a)
 store <2 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x fp128> @llvm.cos.v2f128(<2 x fp128>)
define i64 @floating_lane_128_2_cos(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x fp128>,ptr %ap,align 1
 %b = load <2 x fp128>,ptr %bp,align 1
 %c = load <2 x fp128>,ptr %cp,align 1
 %r = call <2 x fp128> @llvm.cos.v2f128(<2 x fp128> %a)
 store <2 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x fp128> @llvm.sin.v2f128(<2 x fp128>)
define i64 @floating_lane_128_2_sin(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x fp128>,ptr %ap,align 1
 %b = load <2 x fp128>,ptr %bp,align 1
 %c = load <2 x fp128>,ptr %cp,align 1
 %r = call <2 x fp128> @llvm.sin.v2f128(<2 x fp128> %a)
 store <2 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x fp128> @llvm.sqrt.v2f128(<2 x fp128>)
define i64 @floating_lane_128_2_sqrt(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x fp128>,ptr %ap,align 1
 %b = load <2 x fp128>,ptr %bp,align 1
 %c = load <2 x fp128>,ptr %cp,align 1
 %r = call <2 x fp128> @llvm.sqrt.v2f128(<2 x fp128> %a)
 store <2 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x fp128> @llvm.fma.v2f128(<2 x fp128>,<2 x fp128>,<2 x fp128>)
define i64 @floating_lane_128_2_fma(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <2 x fp128>,ptr %ap,align 1
 %b = load <2 x fp128>,ptr %bp,align 1
 %c = load <2 x fp128>,ptr %cp,align 1
 %r = call <2 x fp128> @llvm.fma.v2f128(<2 x fp128> %a,<2 x fp128> %b,<2 x fp128> %c)
 store <2 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x fp128> @llvm.trunc.v3f128(<3 x fp128>)
define i64 @floating_lane_128_3_trunc(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x fp128>,ptr %ap,align 1
 %b = load <3 x fp128>,ptr %bp,align 1
 %c = load <3 x fp128>,ptr %cp,align 1
 %r = call <3 x fp128> @llvm.trunc.v3f128(<3 x fp128> %a)
 store <3 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x fp128> @llvm.round.v3f128(<3 x fp128>)
define i64 @floating_lane_128_3_round(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x fp128>,ptr %ap,align 1
 %b = load <3 x fp128>,ptr %bp,align 1
 %c = load <3 x fp128>,ptr %cp,align 1
 %r = call <3 x fp128> @llvm.round.v3f128(<3 x fp128> %a)
 store <3 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x fp128> @llvm.ceil.v3f128(<3 x fp128>)
define i64 @floating_lane_128_3_ceil(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x fp128>,ptr %ap,align 1
 %b = load <3 x fp128>,ptr %bp,align 1
 %c = load <3 x fp128>,ptr %cp,align 1
 %r = call <3 x fp128> @llvm.ceil.v3f128(<3 x fp128> %a)
 store <3 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x fp128> @llvm.floor.v3f128(<3 x fp128>)
define i64 @floating_lane_128_3_floor(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x fp128>,ptr %ap,align 1
 %b = load <3 x fp128>,ptr %bp,align 1
 %c = load <3 x fp128>,ptr %cp,align 1
 %r = call <3 x fp128> @llvm.floor.v3f128(<3 x fp128> %a)
 store <3 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x fp128> @llvm.log10.v3f128(<3 x fp128>)
define i64 @floating_lane_128_3_log10(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x fp128>,ptr %ap,align 1
 %b = load <3 x fp128>,ptr %bp,align 1
 %c = load <3 x fp128>,ptr %cp,align 1
 %r = call <3 x fp128> @llvm.log10.v3f128(<3 x fp128> %a)
 store <3 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x fp128> @llvm.log2.v3f128(<3 x fp128>)
define i64 @floating_lane_128_3_log2(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x fp128>,ptr %ap,align 1
 %b = load <3 x fp128>,ptr %bp,align 1
 %c = load <3 x fp128>,ptr %cp,align 1
 %r = call <3 x fp128> @llvm.log2.v3f128(<3 x fp128> %a)
 store <3 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x fp128> @llvm.log.v3f128(<3 x fp128>)
define i64 @floating_lane_128_3_log(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x fp128>,ptr %ap,align 1
 %b = load <3 x fp128>,ptr %bp,align 1
 %c = load <3 x fp128>,ptr %cp,align 1
 %r = call <3 x fp128> @llvm.log.v3f128(<3 x fp128> %a)
 store <3 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x fp128> @llvm.exp2.v3f128(<3 x fp128>)
define i64 @floating_lane_128_3_exp2(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x fp128>,ptr %ap,align 1
 %b = load <3 x fp128>,ptr %bp,align 1
 %c = load <3 x fp128>,ptr %cp,align 1
 %r = call <3 x fp128> @llvm.exp2.v3f128(<3 x fp128> %a)
 store <3 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x fp128> @llvm.exp.v3f128(<3 x fp128>)
define i64 @floating_lane_128_3_exp(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x fp128>,ptr %ap,align 1
 %b = load <3 x fp128>,ptr %bp,align 1
 %c = load <3 x fp128>,ptr %cp,align 1
 %r = call <3 x fp128> @llvm.exp.v3f128(<3 x fp128> %a)
 store <3 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x fp128> @llvm.tan.v3f128(<3 x fp128>)
define i64 @floating_lane_128_3_tan(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x fp128>,ptr %ap,align 1
 %b = load <3 x fp128>,ptr %bp,align 1
 %c = load <3 x fp128>,ptr %cp,align 1
 %r = call <3 x fp128> @llvm.tan.v3f128(<3 x fp128> %a)
 store <3 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x fp128> @llvm.cos.v3f128(<3 x fp128>)
define i64 @floating_lane_128_3_cos(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x fp128>,ptr %ap,align 1
 %b = load <3 x fp128>,ptr %bp,align 1
 %c = load <3 x fp128>,ptr %cp,align 1
 %r = call <3 x fp128> @llvm.cos.v3f128(<3 x fp128> %a)
 store <3 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x fp128> @llvm.sin.v3f128(<3 x fp128>)
define i64 @floating_lane_128_3_sin(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x fp128>,ptr %ap,align 1
 %b = load <3 x fp128>,ptr %bp,align 1
 %c = load <3 x fp128>,ptr %cp,align 1
 %r = call <3 x fp128> @llvm.sin.v3f128(<3 x fp128> %a)
 store <3 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x fp128> @llvm.sqrt.v3f128(<3 x fp128>)
define i64 @floating_lane_128_3_sqrt(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x fp128>,ptr %ap,align 1
 %b = load <3 x fp128>,ptr %bp,align 1
 %c = load <3 x fp128>,ptr %cp,align 1
 %r = call <3 x fp128> @llvm.sqrt.v3f128(<3 x fp128> %a)
 store <3 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x fp128> @llvm.fma.v3f128(<3 x fp128>,<3 x fp128>,<3 x fp128>)
define i64 @floating_lane_128_3_fma(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <3 x fp128>,ptr %ap,align 1
 %b = load <3 x fp128>,ptr %bp,align 1
 %c = load <3 x fp128>,ptr %cp,align 1
 %r = call <3 x fp128> @llvm.fma.v3f128(<3 x fp128> %a,<3 x fp128> %b,<3 x fp128> %c)
 store <3 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x fp128> @llvm.trunc.v4f128(<4 x fp128>)
define i64 @floating_lane_128_4_trunc(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x fp128>,ptr %ap,align 1
 %b = load <4 x fp128>,ptr %bp,align 1
 %c = load <4 x fp128>,ptr %cp,align 1
 %r = call <4 x fp128> @llvm.trunc.v4f128(<4 x fp128> %a)
 store <4 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x fp128> @llvm.round.v4f128(<4 x fp128>)
define i64 @floating_lane_128_4_round(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x fp128>,ptr %ap,align 1
 %b = load <4 x fp128>,ptr %bp,align 1
 %c = load <4 x fp128>,ptr %cp,align 1
 %r = call <4 x fp128> @llvm.round.v4f128(<4 x fp128> %a)
 store <4 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x fp128> @llvm.ceil.v4f128(<4 x fp128>)
define i64 @floating_lane_128_4_ceil(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x fp128>,ptr %ap,align 1
 %b = load <4 x fp128>,ptr %bp,align 1
 %c = load <4 x fp128>,ptr %cp,align 1
 %r = call <4 x fp128> @llvm.ceil.v4f128(<4 x fp128> %a)
 store <4 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x fp128> @llvm.floor.v4f128(<4 x fp128>)
define i64 @floating_lane_128_4_floor(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x fp128>,ptr %ap,align 1
 %b = load <4 x fp128>,ptr %bp,align 1
 %c = load <4 x fp128>,ptr %cp,align 1
 %r = call <4 x fp128> @llvm.floor.v4f128(<4 x fp128> %a)
 store <4 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x fp128> @llvm.log10.v4f128(<4 x fp128>)
define i64 @floating_lane_128_4_log10(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x fp128>,ptr %ap,align 1
 %b = load <4 x fp128>,ptr %bp,align 1
 %c = load <4 x fp128>,ptr %cp,align 1
 %r = call <4 x fp128> @llvm.log10.v4f128(<4 x fp128> %a)
 store <4 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x fp128> @llvm.log2.v4f128(<4 x fp128>)
define i64 @floating_lane_128_4_log2(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x fp128>,ptr %ap,align 1
 %b = load <4 x fp128>,ptr %bp,align 1
 %c = load <4 x fp128>,ptr %cp,align 1
 %r = call <4 x fp128> @llvm.log2.v4f128(<4 x fp128> %a)
 store <4 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x fp128> @llvm.log.v4f128(<4 x fp128>)
define i64 @floating_lane_128_4_log(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x fp128>,ptr %ap,align 1
 %b = load <4 x fp128>,ptr %bp,align 1
 %c = load <4 x fp128>,ptr %cp,align 1
 %r = call <4 x fp128> @llvm.log.v4f128(<4 x fp128> %a)
 store <4 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x fp128> @llvm.exp2.v4f128(<4 x fp128>)
define i64 @floating_lane_128_4_exp2(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x fp128>,ptr %ap,align 1
 %b = load <4 x fp128>,ptr %bp,align 1
 %c = load <4 x fp128>,ptr %cp,align 1
 %r = call <4 x fp128> @llvm.exp2.v4f128(<4 x fp128> %a)
 store <4 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x fp128> @llvm.exp.v4f128(<4 x fp128>)
define i64 @floating_lane_128_4_exp(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x fp128>,ptr %ap,align 1
 %b = load <4 x fp128>,ptr %bp,align 1
 %c = load <4 x fp128>,ptr %cp,align 1
 %r = call <4 x fp128> @llvm.exp.v4f128(<4 x fp128> %a)
 store <4 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x fp128> @llvm.tan.v4f128(<4 x fp128>)
define i64 @floating_lane_128_4_tan(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x fp128>,ptr %ap,align 1
 %b = load <4 x fp128>,ptr %bp,align 1
 %c = load <4 x fp128>,ptr %cp,align 1
 %r = call <4 x fp128> @llvm.tan.v4f128(<4 x fp128> %a)
 store <4 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x fp128> @llvm.cos.v4f128(<4 x fp128>)
define i64 @floating_lane_128_4_cos(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x fp128>,ptr %ap,align 1
 %b = load <4 x fp128>,ptr %bp,align 1
 %c = load <4 x fp128>,ptr %cp,align 1
 %r = call <4 x fp128> @llvm.cos.v4f128(<4 x fp128> %a)
 store <4 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x fp128> @llvm.sin.v4f128(<4 x fp128>)
define i64 @floating_lane_128_4_sin(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x fp128>,ptr %ap,align 1
 %b = load <4 x fp128>,ptr %bp,align 1
 %c = load <4 x fp128>,ptr %cp,align 1
 %r = call <4 x fp128> @llvm.sin.v4f128(<4 x fp128> %a)
 store <4 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x fp128> @llvm.sqrt.v4f128(<4 x fp128>)
define i64 @floating_lane_128_4_sqrt(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x fp128>,ptr %ap,align 1
 %b = load <4 x fp128>,ptr %bp,align 1
 %c = load <4 x fp128>,ptr %cp,align 1
 %r = call <4 x fp128> @llvm.sqrt.v4f128(<4 x fp128> %a)
 store <4 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x fp128> @llvm.fma.v4f128(<4 x fp128>,<4 x fp128>,<4 x fp128>)
define i64 @floating_lane_128_4_fma(ptr %out,ptr %ap,ptr %bp,ptr %cp,i64 %salt) {
entry:
 %a = load <4 x fp128>,ptr %ap,align 1
 %b = load <4 x fp128>,ptr %bp,align 1
 %c = load <4 x fp128>,ptr %cp,align 1
 %r = call <4 x fp128> @llvm.fma.v4f128(<4 x fp128> %a,<4 x fp128> %b,<4 x fp128> %c)
 store <4 x fp128> %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
