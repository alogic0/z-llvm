target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare half @llvm.minnum.f16(half,half)
declare half @llvm.maxnum.f16(half,half)
define i64 @floating_minmax_16_2_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %in,i64 0
 %v0 = load half,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %in,i64 2
 %v1 = load half,ptr %p1,align 1
 %r1 = call half @llvm.minnum.f16(half %v0,half %v1)
 store half %r1,ptr %out,align 1
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
define i64 @floating_minmax_16_3_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %in,i64 0
 %v0 = load half,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %in,i64 2
 %v1 = load half,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %in,i64 4
 %v2 = load half,ptr %p2,align 1
 %r1 = call half @llvm.minnum.f16(half %v0,half %v1)
 %r2 = call half @llvm.minnum.f16(half %r1,half %v2)
 store half %r2,ptr %out,align 1
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
define i64 @floating_minmax_16_4_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %in,i64 0
 %v0 = load half,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %in,i64 2
 %v1 = load half,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %in,i64 4
 %v2 = load half,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %in,i64 6
 %v3 = load half,ptr %p3,align 1
 %r1 = call half @llvm.minnum.f16(half %v0,half %v1)
 %r2 = call half @llvm.minnum.f16(half %r1,half %v2)
 %r3 = call half @llvm.minnum.f16(half %r2,half %v3)
 store half %r3,ptr %out,align 1
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
declare float @llvm.minnum.f32(float,float)
declare float @llvm.maxnum.f32(float,float)
define i64 @floating_minmax_32_2_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %in,i64 0
 %v0 = load float,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %in,i64 4
 %v1 = load float,ptr %p1,align 1
 %r1 = call float @llvm.minnum.f32(float %v0,float %v1)
 store float %r1,ptr %out,align 1
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
define i64 @floating_minmax_32_3_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %in,i64 0
 %v0 = load float,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %in,i64 4
 %v1 = load float,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %in,i64 8
 %v2 = load float,ptr %p2,align 1
 %r1 = call float @llvm.minnum.f32(float %v0,float %v1)
 %r2 = call float @llvm.minnum.f32(float %r1,float %v2)
 store float %r2,ptr %out,align 1
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
define i64 @floating_minmax_32_4_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %in,i64 0
 %v0 = load float,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %in,i64 4
 %v1 = load float,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %in,i64 8
 %v2 = load float,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %in,i64 12
 %v3 = load float,ptr %p3,align 1
 %r1 = call float @llvm.minnum.f32(float %v0,float %v1)
 %r2 = call float @llvm.minnum.f32(float %r1,float %v2)
 %r3 = call float @llvm.minnum.f32(float %r2,float %v3)
 store float %r3,ptr %out,align 1
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
declare double @llvm.minnum.f64(double,double)
declare double @llvm.maxnum.f64(double,double)
define i64 @floating_minmax_64_2_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %in,i64 0
 %v0 = load double,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %in,i64 8
 %v1 = load double,ptr %p1,align 1
 %r1 = call double @llvm.minnum.f64(double %v0,double %v1)
 store double %r1,ptr %out,align 1
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
define i64 @floating_minmax_64_3_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %in,i64 0
 %v0 = load double,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %in,i64 8
 %v1 = load double,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %in,i64 16
 %v2 = load double,ptr %p2,align 1
 %r1 = call double @llvm.minnum.f64(double %v0,double %v1)
 %r2 = call double @llvm.minnum.f64(double %r1,double %v2)
 store double %r2,ptr %out,align 1
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
define i64 @floating_minmax_64_4_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %in,i64 0
 %v0 = load double,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %in,i64 8
 %v1 = load double,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %in,i64 16
 %v2 = load double,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %in,i64 24
 %v3 = load double,ptr %p3,align 1
 %r1 = call double @llvm.minnum.f64(double %v0,double %v1)
 %r2 = call double @llvm.minnum.f64(double %r1,double %v2)
 %r3 = call double @llvm.minnum.f64(double %r2,double %v3)
 store double %r3,ptr %out,align 1
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
declare x86_fp80 @llvm.minnum.f80(x86_fp80,x86_fp80)
declare x86_fp80 @llvm.maxnum.f80(x86_fp80,x86_fp80)
define i64 @floating_minmax_80_2_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %in,i64 0
 %v0 = load x86_fp80,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %in,i64 10
 %v1 = load x86_fp80,ptr %p1,align 1
 %r1 = call x86_fp80 @llvm.minnum.f80(x86_fp80 %v0,x86_fp80 %v1)
 store x86_fp80 %r1,ptr %out,align 1
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
define i64 @floating_minmax_80_3_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %in,i64 0
 %v0 = load x86_fp80,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %in,i64 10
 %v1 = load x86_fp80,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %in,i64 20
 %v2 = load x86_fp80,ptr %p2,align 1
 %r1 = call x86_fp80 @llvm.minnum.f80(x86_fp80 %v0,x86_fp80 %v1)
 %r2 = call x86_fp80 @llvm.minnum.f80(x86_fp80 %r1,x86_fp80 %v2)
 store x86_fp80 %r2,ptr %out,align 1
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
define i64 @floating_minmax_80_4_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %in,i64 0
 %v0 = load x86_fp80,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %in,i64 10
 %v1 = load x86_fp80,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %in,i64 20
 %v2 = load x86_fp80,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %in,i64 30
 %v3 = load x86_fp80,ptr %p3,align 1
 %r1 = call x86_fp80 @llvm.minnum.f80(x86_fp80 %v0,x86_fp80 %v1)
 %r2 = call x86_fp80 @llvm.minnum.f80(x86_fp80 %r1,x86_fp80 %v2)
 %r3 = call x86_fp80 @llvm.minnum.f80(x86_fp80 %r2,x86_fp80 %v3)
 store x86_fp80 %r3,ptr %out,align 1
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
declare fp128 @llvm.minnum.f128(fp128,fp128)
declare fp128 @llvm.maxnum.f128(fp128,fp128)
define i64 @floating_minmax_128_2_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %in,i64 0
 %v0 = load fp128,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %in,i64 16
 %v1 = load fp128,ptr %p1,align 1
 %r1 = call fp128 @llvm.minnum.f128(fp128 %v0,fp128 %v1)
 store fp128 %r1,ptr %out,align 1
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
define i64 @floating_minmax_128_3_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %in,i64 0
 %v0 = load fp128,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %in,i64 16
 %v1 = load fp128,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %in,i64 32
 %v2 = load fp128,ptr %p2,align 1
 %r1 = call fp128 @llvm.minnum.f128(fp128 %v0,fp128 %v1)
 %r2 = call fp128 @llvm.minnum.f128(fp128 %r1,fp128 %v2)
 store fp128 %r2,ptr %out,align 1
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
define i64 @floating_minmax_128_4_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %in,i64 0
 %v0 = load fp128,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %in,i64 16
 %v1 = load fp128,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %in,i64 32
 %v2 = load fp128,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %in,i64 48
 %v3 = load fp128,ptr %p3,align 1
 %r1 = call fp128 @llvm.minnum.f128(fp128 %v0,fp128 %v1)
 %r2 = call fp128 @llvm.minnum.f128(fp128 %r1,fp128 %v2)
 %r3 = call fp128 @llvm.minnum.f128(fp128 %r2,fp128 %v3)
 store fp128 %r3,ptr %out,align 1
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
