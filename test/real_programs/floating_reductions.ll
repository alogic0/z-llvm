target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare half @llvm.vector.reduce.fadd.v2f16(half,<2 x half>)
define i64 @floating_reduce_16_2_add(ptr %out,ptr %in,ptr %seed,i64 %salt) {
entry:
 %v = load <2 x half>,ptr %in,align 1
 %s = load half,ptr %seed,align 1
 %r = call half @llvm.vector.reduce.fadd.v2f16(half %s,<2 x half> %v)
 store half %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare half @llvm.vector.reduce.fmul.v2f16(half,<2 x half>)
define i64 @floating_reduce_16_2_mul(ptr %out,ptr %in,ptr %seed,i64 %salt) {
entry:
 %v = load <2 x half>,ptr %in,align 1
 %s = load half,ptr %seed,align 1
 %r = call half @llvm.vector.reduce.fmul.v2f16(half %s,<2 x half> %v)
 store half %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare half @llvm.vector.reduce.fadd.v3f16(half,<3 x half>)
define i64 @floating_reduce_16_3_add(ptr %out,ptr %in,ptr %seed,i64 %salt) {
entry:
 %v = load <3 x half>,ptr %in,align 1
 %s = load half,ptr %seed,align 1
 %r = call half @llvm.vector.reduce.fadd.v3f16(half %s,<3 x half> %v)
 store half %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare half @llvm.vector.reduce.fmul.v3f16(half,<3 x half>)
define i64 @floating_reduce_16_3_mul(ptr %out,ptr %in,ptr %seed,i64 %salt) {
entry:
 %v = load <3 x half>,ptr %in,align 1
 %s = load half,ptr %seed,align 1
 %r = call half @llvm.vector.reduce.fmul.v3f16(half %s,<3 x half> %v)
 store half %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare half @llvm.vector.reduce.fadd.v4f16(half,<4 x half>)
define i64 @floating_reduce_16_4_add(ptr %out,ptr %in,ptr %seed,i64 %salt) {
entry:
 %v = load <4 x half>,ptr %in,align 1
 %s = load half,ptr %seed,align 1
 %r = call half @llvm.vector.reduce.fadd.v4f16(half %s,<4 x half> %v)
 store half %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare half @llvm.vector.reduce.fmul.v4f16(half,<4 x half>)
define i64 @floating_reduce_16_4_mul(ptr %out,ptr %in,ptr %seed,i64 %salt) {
entry:
 %v = load <4 x half>,ptr %in,align 1
 %s = load half,ptr %seed,align 1
 %r = call half @llvm.vector.reduce.fmul.v4f16(half %s,<4 x half> %v)
 store half %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare float @llvm.vector.reduce.fadd.v2f32(float,<2 x float>)
define i64 @floating_reduce_32_2_add(ptr %out,ptr %in,ptr %seed,i64 %salt) {
entry:
 %v = load <2 x float>,ptr %in,align 1
 %s = load float,ptr %seed,align 1
 %r = call float @llvm.vector.reduce.fadd.v2f32(float %s,<2 x float> %v)
 store float %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare float @llvm.vector.reduce.fmul.v2f32(float,<2 x float>)
define i64 @floating_reduce_32_2_mul(ptr %out,ptr %in,ptr %seed,i64 %salt) {
entry:
 %v = load <2 x float>,ptr %in,align 1
 %s = load float,ptr %seed,align 1
 %r = call float @llvm.vector.reduce.fmul.v2f32(float %s,<2 x float> %v)
 store float %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare float @llvm.vector.reduce.fadd.v3f32(float,<3 x float>)
define i64 @floating_reduce_32_3_add(ptr %out,ptr %in,ptr %seed,i64 %salt) {
entry:
 %v = load <3 x float>,ptr %in,align 1
 %s = load float,ptr %seed,align 1
 %r = call float @llvm.vector.reduce.fadd.v3f32(float %s,<3 x float> %v)
 store float %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare float @llvm.vector.reduce.fmul.v3f32(float,<3 x float>)
define i64 @floating_reduce_32_3_mul(ptr %out,ptr %in,ptr %seed,i64 %salt) {
entry:
 %v = load <3 x float>,ptr %in,align 1
 %s = load float,ptr %seed,align 1
 %r = call float @llvm.vector.reduce.fmul.v3f32(float %s,<3 x float> %v)
 store float %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare float @llvm.vector.reduce.fadd.v4f32(float,<4 x float>)
define i64 @floating_reduce_32_4_add(ptr %out,ptr %in,ptr %seed,i64 %salt) {
entry:
 %v = load <4 x float>,ptr %in,align 1
 %s = load float,ptr %seed,align 1
 %r = call float @llvm.vector.reduce.fadd.v4f32(float %s,<4 x float> %v)
 store float %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare float @llvm.vector.reduce.fmul.v4f32(float,<4 x float>)
define i64 @floating_reduce_32_4_mul(ptr %out,ptr %in,ptr %seed,i64 %salt) {
entry:
 %v = load <4 x float>,ptr %in,align 1
 %s = load float,ptr %seed,align 1
 %r = call float @llvm.vector.reduce.fmul.v4f32(float %s,<4 x float> %v)
 store float %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare double @llvm.vector.reduce.fadd.v2f64(double,<2 x double>)
define i64 @floating_reduce_64_2_add(ptr %out,ptr %in,ptr %seed,i64 %salt) {
entry:
 %v = load <2 x double>,ptr %in,align 1
 %s = load double,ptr %seed,align 1
 %r = call double @llvm.vector.reduce.fadd.v2f64(double %s,<2 x double> %v)
 store double %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare double @llvm.vector.reduce.fmul.v2f64(double,<2 x double>)
define i64 @floating_reduce_64_2_mul(ptr %out,ptr %in,ptr %seed,i64 %salt) {
entry:
 %v = load <2 x double>,ptr %in,align 1
 %s = load double,ptr %seed,align 1
 %r = call double @llvm.vector.reduce.fmul.v2f64(double %s,<2 x double> %v)
 store double %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare double @llvm.vector.reduce.fadd.v3f64(double,<3 x double>)
define i64 @floating_reduce_64_3_add(ptr %out,ptr %in,ptr %seed,i64 %salt) {
entry:
 %v = load <3 x double>,ptr %in,align 1
 %s = load double,ptr %seed,align 1
 %r = call double @llvm.vector.reduce.fadd.v3f64(double %s,<3 x double> %v)
 store double %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare double @llvm.vector.reduce.fmul.v3f64(double,<3 x double>)
define i64 @floating_reduce_64_3_mul(ptr %out,ptr %in,ptr %seed,i64 %salt) {
entry:
 %v = load <3 x double>,ptr %in,align 1
 %s = load double,ptr %seed,align 1
 %r = call double @llvm.vector.reduce.fmul.v3f64(double %s,<3 x double> %v)
 store double %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare double @llvm.vector.reduce.fadd.v4f64(double,<4 x double>)
define i64 @floating_reduce_64_4_add(ptr %out,ptr %in,ptr %seed,i64 %salt) {
entry:
 %v = load <4 x double>,ptr %in,align 1
 %s = load double,ptr %seed,align 1
 %r = call double @llvm.vector.reduce.fadd.v4f64(double %s,<4 x double> %v)
 store double %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare double @llvm.vector.reduce.fmul.v4f64(double,<4 x double>)
define i64 @floating_reduce_64_4_mul(ptr %out,ptr %in,ptr %seed,i64 %salt) {
entry:
 %v = load <4 x double>,ptr %in,align 1
 %s = load double,ptr %seed,align 1
 %r = call double @llvm.vector.reduce.fmul.v4f64(double %s,<4 x double> %v)
 store double %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare x86_fp80 @llvm.vector.reduce.fadd.v2f80(x86_fp80,<2 x x86_fp80>)
define i64 @floating_reduce_80_2_add(ptr %out,ptr %in,ptr %seed,i64 %salt) {
entry:
 %v = load <2 x x86_fp80>,ptr %in,align 1
 %s = load x86_fp80,ptr %seed,align 1
 %r = call x86_fp80 @llvm.vector.reduce.fadd.v2f80(x86_fp80 %s,<2 x x86_fp80> %v)
 store x86_fp80 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare x86_fp80 @llvm.vector.reduce.fmul.v2f80(x86_fp80,<2 x x86_fp80>)
define i64 @floating_reduce_80_2_mul(ptr %out,ptr %in,ptr %seed,i64 %salt) {
entry:
 %v = load <2 x x86_fp80>,ptr %in,align 1
 %s = load x86_fp80,ptr %seed,align 1
 %r = call x86_fp80 @llvm.vector.reduce.fmul.v2f80(x86_fp80 %s,<2 x x86_fp80> %v)
 store x86_fp80 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare x86_fp80 @llvm.vector.reduce.fadd.v3f80(x86_fp80,<3 x x86_fp80>)
define i64 @floating_reduce_80_3_add(ptr %out,ptr %in,ptr %seed,i64 %salt) {
entry:
 %v = load <3 x x86_fp80>,ptr %in,align 1
 %s = load x86_fp80,ptr %seed,align 1
 %r = call x86_fp80 @llvm.vector.reduce.fadd.v3f80(x86_fp80 %s,<3 x x86_fp80> %v)
 store x86_fp80 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare x86_fp80 @llvm.vector.reduce.fmul.v3f80(x86_fp80,<3 x x86_fp80>)
define i64 @floating_reduce_80_3_mul(ptr %out,ptr %in,ptr %seed,i64 %salt) {
entry:
 %v = load <3 x x86_fp80>,ptr %in,align 1
 %s = load x86_fp80,ptr %seed,align 1
 %r = call x86_fp80 @llvm.vector.reduce.fmul.v3f80(x86_fp80 %s,<3 x x86_fp80> %v)
 store x86_fp80 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare x86_fp80 @llvm.vector.reduce.fadd.v4f80(x86_fp80,<4 x x86_fp80>)
define i64 @floating_reduce_80_4_add(ptr %out,ptr %in,ptr %seed,i64 %salt) {
entry:
 %v = load <4 x x86_fp80>,ptr %in,align 1
 %s = load x86_fp80,ptr %seed,align 1
 %r = call x86_fp80 @llvm.vector.reduce.fadd.v4f80(x86_fp80 %s,<4 x x86_fp80> %v)
 store x86_fp80 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare x86_fp80 @llvm.vector.reduce.fmul.v4f80(x86_fp80,<4 x x86_fp80>)
define i64 @floating_reduce_80_4_mul(ptr %out,ptr %in,ptr %seed,i64 %salt) {
entry:
 %v = load <4 x x86_fp80>,ptr %in,align 1
 %s = load x86_fp80,ptr %seed,align 1
 %r = call x86_fp80 @llvm.vector.reduce.fmul.v4f80(x86_fp80 %s,<4 x x86_fp80> %v)
 store x86_fp80 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare fp128 @llvm.vector.reduce.fadd.v2f128(fp128,<2 x fp128>)
define i64 @floating_reduce_128_2_add(ptr %out,ptr %in,ptr %seed,i64 %salt) {
entry:
 %v = load <2 x fp128>,ptr %in,align 1
 %s = load fp128,ptr %seed,align 1
 %r = call fp128 @llvm.vector.reduce.fadd.v2f128(fp128 %s,<2 x fp128> %v)
 store fp128 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare fp128 @llvm.vector.reduce.fmul.v2f128(fp128,<2 x fp128>)
define i64 @floating_reduce_128_2_mul(ptr %out,ptr %in,ptr %seed,i64 %salt) {
entry:
 %v = load <2 x fp128>,ptr %in,align 1
 %s = load fp128,ptr %seed,align 1
 %r = call fp128 @llvm.vector.reduce.fmul.v2f128(fp128 %s,<2 x fp128> %v)
 store fp128 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare fp128 @llvm.vector.reduce.fadd.v3f128(fp128,<3 x fp128>)
define i64 @floating_reduce_128_3_add(ptr %out,ptr %in,ptr %seed,i64 %salt) {
entry:
 %v = load <3 x fp128>,ptr %in,align 1
 %s = load fp128,ptr %seed,align 1
 %r = call fp128 @llvm.vector.reduce.fadd.v3f128(fp128 %s,<3 x fp128> %v)
 store fp128 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare fp128 @llvm.vector.reduce.fmul.v3f128(fp128,<3 x fp128>)
define i64 @floating_reduce_128_3_mul(ptr %out,ptr %in,ptr %seed,i64 %salt) {
entry:
 %v = load <3 x fp128>,ptr %in,align 1
 %s = load fp128,ptr %seed,align 1
 %r = call fp128 @llvm.vector.reduce.fmul.v3f128(fp128 %s,<3 x fp128> %v)
 store fp128 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare fp128 @llvm.vector.reduce.fadd.v4f128(fp128,<4 x fp128>)
define i64 @floating_reduce_128_4_add(ptr %out,ptr %in,ptr %seed,i64 %salt) {
entry:
 %v = load <4 x fp128>,ptr %in,align 1
 %s = load fp128,ptr %seed,align 1
 %r = call fp128 @llvm.vector.reduce.fadd.v4f128(fp128 %s,<4 x fp128> %v)
 store fp128 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare fp128 @llvm.vector.reduce.fmul.v4f128(fp128,<4 x fp128>)
define i64 @floating_reduce_128_4_mul(ptr %out,ptr %in,ptr %seed,i64 %salt) {
entry:
 %v = load <4 x fp128>,ptr %in,align 1
 %s = load fp128,ptr %seed,align 1
 %r = call fp128 @llvm.vector.reduce.fmul.v4f128(fp128 %s,<4 x fp128> %v)
 store fp128 %r,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
