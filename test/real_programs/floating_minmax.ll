target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare half @llvm.maxnum.f16(half,half)
declare half @llvm.vector.reduce.fmin.v2f16(<2 x half>)
define i64 @floating_minmax_16_2_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <2 x half>,ptr %in,align 1
 %r = call half @llvm.vector.reduce.fmin.v2f16(<2 x half> %v)
 store half %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare half @llvm.vector.reduce.fmax.v2f16(<2 x half>)
define i64 @floating_minmax_16_2_max(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <2 x half>,ptr %in,align 1
 %r = call half @llvm.vector.reduce.fmax.v2f16(<2 x half> %v)
 store half %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare half @llvm.vector.reduce.fmin.v3f16(<3 x half>)
define i64 @floating_minmax_16_3_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <3 x half>,ptr %in,align 1
 %r = call half @llvm.vector.reduce.fmin.v3f16(<3 x half> %v)
 store half %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare half @llvm.vector.reduce.fmax.v3f16(<3 x half>)
define i64 @floating_minmax_16_3_max(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <3 x half>,ptr %in,align 1
 %r = call half @llvm.vector.reduce.fmax.v3f16(<3 x half> %v)
 store half %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare half @llvm.vector.reduce.fmin.v4f16(<4 x half>)
define i64 @floating_minmax_16_4_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <4 x half>,ptr %in,align 1
 %r = call half @llvm.vector.reduce.fmin.v4f16(<4 x half> %v)
 store half %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare half @llvm.vector.reduce.fmax.v4f16(<4 x half>)
define i64 @floating_minmax_16_4_max(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <4 x half>,ptr %in,align 1
 %r = call half @llvm.vector.reduce.fmax.v4f16(<4 x half> %v)
 store half %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare float @llvm.maxnum.f32(float,float)
declare float @llvm.vector.reduce.fmin.v2f32(<2 x float>)
define i64 @floating_minmax_32_2_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <2 x float>,ptr %in,align 1
 %r = call float @llvm.vector.reduce.fmin.v2f32(<2 x float> %v)
 store float %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare float @llvm.vector.reduce.fmax.v2f32(<2 x float>)
define i64 @floating_minmax_32_2_max(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <2 x float>,ptr %in,align 1
 %r = call float @llvm.vector.reduce.fmax.v2f32(<2 x float> %v)
 store float %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare float @llvm.vector.reduce.fmin.v3f32(<3 x float>)
define i64 @floating_minmax_32_3_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <3 x float>,ptr %in,align 1
 %r = call float @llvm.vector.reduce.fmin.v3f32(<3 x float> %v)
 store float %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare float @llvm.vector.reduce.fmax.v3f32(<3 x float>)
define i64 @floating_minmax_32_3_max(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <3 x float>,ptr %in,align 1
 %r = call float @llvm.vector.reduce.fmax.v3f32(<3 x float> %v)
 store float %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare float @llvm.vector.reduce.fmin.v4f32(<4 x float>)
define i64 @floating_minmax_32_4_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <4 x float>,ptr %in,align 1
 %r = call float @llvm.vector.reduce.fmin.v4f32(<4 x float> %v)
 store float %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare float @llvm.vector.reduce.fmax.v4f32(<4 x float>)
define i64 @floating_minmax_32_4_max(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <4 x float>,ptr %in,align 1
 %r = call float @llvm.vector.reduce.fmax.v4f32(<4 x float> %v)
 store float %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare double @llvm.maxnum.f64(double,double)
declare double @llvm.vector.reduce.fmin.v2f64(<2 x double>)
define i64 @floating_minmax_64_2_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <2 x double>,ptr %in,align 1
 %r = call double @llvm.vector.reduce.fmin.v2f64(<2 x double> %v)
 store double %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare double @llvm.vector.reduce.fmax.v2f64(<2 x double>)
define i64 @floating_minmax_64_2_max(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <2 x double>,ptr %in,align 1
 %r = call double @llvm.vector.reduce.fmax.v2f64(<2 x double> %v)
 store double %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare double @llvm.vector.reduce.fmin.v3f64(<3 x double>)
define i64 @floating_minmax_64_3_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <3 x double>,ptr %in,align 1
 %r = call double @llvm.vector.reduce.fmin.v3f64(<3 x double> %v)
 store double %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare double @llvm.vector.reduce.fmax.v3f64(<3 x double>)
define i64 @floating_minmax_64_3_max(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <3 x double>,ptr %in,align 1
 %r = call double @llvm.vector.reduce.fmax.v3f64(<3 x double> %v)
 store double %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare double @llvm.vector.reduce.fmin.v4f64(<4 x double>)
define i64 @floating_minmax_64_4_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <4 x double>,ptr %in,align 1
 %r = call double @llvm.vector.reduce.fmin.v4f64(<4 x double> %v)
 store double %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare double @llvm.vector.reduce.fmax.v4f64(<4 x double>)
define i64 @floating_minmax_64_4_max(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <4 x double>,ptr %in,align 1
 %r = call double @llvm.vector.reduce.fmax.v4f64(<4 x double> %v)
 store double %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare x86_fp80 @llvm.maxnum.f80(x86_fp80,x86_fp80)
declare x86_fp80 @llvm.vector.reduce.fmin.v2f80(<2 x x86_fp80>)
define i64 @floating_minmax_80_2_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <2 x x86_fp80>,ptr %in,align 1
 %r = call x86_fp80 @llvm.vector.reduce.fmin.v2f80(<2 x x86_fp80> %v)
 store x86_fp80 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare x86_fp80 @llvm.vector.reduce.fmax.v2f80(<2 x x86_fp80>)
define i64 @floating_minmax_80_2_max(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <2 x x86_fp80>,ptr %in,align 1
 %r = call x86_fp80 @llvm.vector.reduce.fmax.v2f80(<2 x x86_fp80> %v)
 store x86_fp80 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare x86_fp80 @llvm.vector.reduce.fmin.v3f80(<3 x x86_fp80>)
define i64 @floating_minmax_80_3_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <3 x x86_fp80>,ptr %in,align 1
 %r = call x86_fp80 @llvm.vector.reduce.fmin.v3f80(<3 x x86_fp80> %v)
 store x86_fp80 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare x86_fp80 @llvm.vector.reduce.fmax.v3f80(<3 x x86_fp80>)
define i64 @floating_minmax_80_3_max(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <3 x x86_fp80>,ptr %in,align 1
 %r = call x86_fp80 @llvm.vector.reduce.fmax.v3f80(<3 x x86_fp80> %v)
 store x86_fp80 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare x86_fp80 @llvm.vector.reduce.fmin.v4f80(<4 x x86_fp80>)
define i64 @floating_minmax_80_4_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <4 x x86_fp80>,ptr %in,align 1
 %r = call x86_fp80 @llvm.vector.reduce.fmin.v4f80(<4 x x86_fp80> %v)
 store x86_fp80 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare x86_fp80 @llvm.vector.reduce.fmax.v4f80(<4 x x86_fp80>)
define i64 @floating_minmax_80_4_max(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <4 x x86_fp80>,ptr %in,align 1
 %r = call x86_fp80 @llvm.vector.reduce.fmax.v4f80(<4 x x86_fp80> %v)
 store x86_fp80 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare fp128 @llvm.maxnum.f128(fp128,fp128)
declare fp128 @llvm.vector.reduce.fmin.v2f128(<2 x fp128>)
define i64 @floating_minmax_128_2_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <2 x fp128>,ptr %in,align 1
 %r = call fp128 @llvm.vector.reduce.fmin.v2f128(<2 x fp128> %v)
 store fp128 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare fp128 @llvm.vector.reduce.fmax.v2f128(<2 x fp128>)
define i64 @floating_minmax_128_2_max(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <2 x fp128>,ptr %in,align 1
 %r = call fp128 @llvm.vector.reduce.fmax.v2f128(<2 x fp128> %v)
 store fp128 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare fp128 @llvm.vector.reduce.fmin.v3f128(<3 x fp128>)
define i64 @floating_minmax_128_3_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <3 x fp128>,ptr %in,align 1
 %r = call fp128 @llvm.vector.reduce.fmin.v3f128(<3 x fp128> %v)
 store fp128 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare fp128 @llvm.vector.reduce.fmax.v3f128(<3 x fp128>)
define i64 @floating_minmax_128_3_max(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <3 x fp128>,ptr %in,align 1
 %r = call fp128 @llvm.vector.reduce.fmax.v3f128(<3 x fp128> %v)
 store fp128 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare fp128 @llvm.vector.reduce.fmin.v4f128(<4 x fp128>)
define i64 @floating_minmax_128_4_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <4 x fp128>,ptr %in,align 1
 %r = call fp128 @llvm.vector.reduce.fmin.v4f128(<4 x fp128> %v)
 store fp128 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare fp128 @llvm.vector.reduce.fmax.v4f128(<4 x fp128>)
define i64 @floating_minmax_128_4_max(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <4 x fp128>,ptr %in,align 1
 %r = call fp128 @llvm.vector.reduce.fmax.v4f128(<4 x fp128> %v)
 store fp128 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
