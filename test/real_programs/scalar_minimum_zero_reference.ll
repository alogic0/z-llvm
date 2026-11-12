; Independent zero-sign oracle: pinned vector reduction supplies numeric/NaN results.
; Vector sign and zero masks repair its demonstrated zero-tie limitation.
; Candidate IR is retained unchanged in floating_minmax_mixed_zeros.ll.
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare i1 @llvm.vector.reduce.or.v2i1(<2 x i1>)
declare i1 @llvm.vector.reduce.and.v2i1(<2 x i1>)
declare i1 @llvm.vector.reduce.or.v3i1(<3 x i1>)
declare i1 @llvm.vector.reduce.and.v3i1(<3 x i1>)
declare i1 @llvm.vector.reduce.or.v4i1(<4 x i1>)
declare i1 @llvm.vector.reduce.and.v4i1(<4 x i1>)
declare half @llvm.vector.reduce.fmin.v2f16(<2 x half>)
define i64 @floating_minmax_16_2_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <2 x half>,ptr %in,align 1
 %ordinary = call half @llvm.vector.reduce.fmin.v2f16(<2 x half> %v)
 %zeros = fcmp oeq <2 x half> %v,zeroinitializer
 %raw = bitcast <2 x half> %v to <2 x i16>
 %negative = icmp slt <2 x i16> %raw,zeroinitializer
 %mask = and <2 x i1> %zeros,%negative
 %sign = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %mask)
 %correct_zero = select i1 %sign,half 0xH8000,half 0xH0000
 %is_zero = fcmp oeq half %ordinary,0xH0000
 %answer = select i1 %is_zero,half %correct_zero,half %ordinary
 store half %answer,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare half @llvm.vector.reduce.fmax.v2f16(<2 x half>)
define i64 @floating_minmax_16_2_max(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <2 x half>,ptr %in,align 1
 %ordinary = call half @llvm.vector.reduce.fmax.v2f16(<2 x half> %v)
 %zeros = fcmp oeq <2 x half> %v,zeroinitializer
 %raw = bitcast <2 x half> %v to <2 x i16>
 %negative = icmp slt <2 x i16> %raw,zeroinitializer
 %mask = select <2 x i1> %zeros,<2 x i1> %negative,<2 x i1> <i1 true,i1 true>
 %sign = call i1 @llvm.vector.reduce.and.v2i1(<2 x i1> %mask)
 %correct_zero = select i1 %sign,half 0xH8000,half 0xH0000
 %is_zero = fcmp oeq half %ordinary,0xH0000
 %answer = select i1 %is_zero,half %correct_zero,half %ordinary
 store half %answer,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare half @llvm.vector.reduce.fmin.v3f16(<3 x half>)
define i64 @floating_minmax_16_3_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <3 x half>,ptr %in,align 1
 %ordinary = call half @llvm.vector.reduce.fmin.v3f16(<3 x half> %v)
 %zeros = fcmp oeq <3 x half> %v,zeroinitializer
 %raw = bitcast <3 x half> %v to <3 x i16>
 %negative = icmp slt <3 x i16> %raw,zeroinitializer
 %mask = and <3 x i1> %zeros,%negative
 %sign = call i1 @llvm.vector.reduce.or.v3i1(<3 x i1> %mask)
 %correct_zero = select i1 %sign,half 0xH8000,half 0xH0000
 %is_zero = fcmp oeq half %ordinary,0xH0000
 %answer = select i1 %is_zero,half %correct_zero,half %ordinary
 store half %answer,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare half @llvm.vector.reduce.fmax.v3f16(<3 x half>)
define i64 @floating_minmax_16_3_max(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <3 x half>,ptr %in,align 1
 %ordinary = call half @llvm.vector.reduce.fmax.v3f16(<3 x half> %v)
 %zeros = fcmp oeq <3 x half> %v,zeroinitializer
 %raw = bitcast <3 x half> %v to <3 x i16>
 %negative = icmp slt <3 x i16> %raw,zeroinitializer
 %mask = select <3 x i1> %zeros,<3 x i1> %negative,<3 x i1> <i1 true,i1 true,i1 true>
 %sign = call i1 @llvm.vector.reduce.and.v3i1(<3 x i1> %mask)
 %correct_zero = select i1 %sign,half 0xH8000,half 0xH0000
 %is_zero = fcmp oeq half %ordinary,0xH0000
 %answer = select i1 %is_zero,half %correct_zero,half %ordinary
 store half %answer,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare half @llvm.vector.reduce.fmin.v4f16(<4 x half>)
define i64 @floating_minmax_16_4_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <4 x half>,ptr %in,align 1
 %ordinary = call half @llvm.vector.reduce.fmin.v4f16(<4 x half> %v)
 %zeros = fcmp oeq <4 x half> %v,zeroinitializer
 %raw = bitcast <4 x half> %v to <4 x i16>
 %negative = icmp slt <4 x i16> %raw,zeroinitializer
 %mask = and <4 x i1> %zeros,%negative
 %sign = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %mask)
 %correct_zero = select i1 %sign,half 0xH8000,half 0xH0000
 %is_zero = fcmp oeq half %ordinary,0xH0000
 %answer = select i1 %is_zero,half %correct_zero,half %ordinary
 store half %answer,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare half @llvm.vector.reduce.fmax.v4f16(<4 x half>)
define i64 @floating_minmax_16_4_max(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <4 x half>,ptr %in,align 1
 %ordinary = call half @llvm.vector.reduce.fmax.v4f16(<4 x half> %v)
 %zeros = fcmp oeq <4 x half> %v,zeroinitializer
 %raw = bitcast <4 x half> %v to <4 x i16>
 %negative = icmp slt <4 x i16> %raw,zeroinitializer
 %mask = select <4 x i1> %zeros,<4 x i1> %negative,<4 x i1> <i1 true,i1 true,i1 true,i1 true>
 %sign = call i1 @llvm.vector.reduce.and.v4i1(<4 x i1> %mask)
 %correct_zero = select i1 %sign,half 0xH8000,half 0xH0000
 %is_zero = fcmp oeq half %ordinary,0xH0000
 %answer = select i1 %is_zero,half %correct_zero,half %ordinary
 store half %answer,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare float @llvm.vector.reduce.fmin.v2f32(<2 x float>)
define i64 @floating_minmax_32_2_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <2 x float>,ptr %in,align 1
 %ordinary = call float @llvm.vector.reduce.fmin.v2f32(<2 x float> %v)
 %zeros = fcmp oeq <2 x float> %v,zeroinitializer
 %raw = bitcast <2 x float> %v to <2 x i32>
 %negative = icmp slt <2 x i32> %raw,zeroinitializer
 %mask = and <2 x i1> %zeros,%negative
 %sign = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %mask)
 %correct_zero = select i1 %sign,float -0.000000e+00,float 0.000000e+00
 %is_zero = fcmp oeq float %ordinary,0.000000e+00
 %answer = select i1 %is_zero,float %correct_zero,float %ordinary
 store float %answer,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare float @llvm.vector.reduce.fmax.v2f32(<2 x float>)
define i64 @floating_minmax_32_2_max(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <2 x float>,ptr %in,align 1
 %ordinary = call float @llvm.vector.reduce.fmax.v2f32(<2 x float> %v)
 %zeros = fcmp oeq <2 x float> %v,zeroinitializer
 %raw = bitcast <2 x float> %v to <2 x i32>
 %negative = icmp slt <2 x i32> %raw,zeroinitializer
 %mask = select <2 x i1> %zeros,<2 x i1> %negative,<2 x i1> <i1 true,i1 true>
 %sign = call i1 @llvm.vector.reduce.and.v2i1(<2 x i1> %mask)
 %correct_zero = select i1 %sign,float -0.000000e+00,float 0.000000e+00
 %is_zero = fcmp oeq float %ordinary,0.000000e+00
 %answer = select i1 %is_zero,float %correct_zero,float %ordinary
 store float %answer,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare float @llvm.vector.reduce.fmin.v3f32(<3 x float>)
define i64 @floating_minmax_32_3_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <3 x float>,ptr %in,align 1
 %ordinary = call float @llvm.vector.reduce.fmin.v3f32(<3 x float> %v)
 %zeros = fcmp oeq <3 x float> %v,zeroinitializer
 %raw = bitcast <3 x float> %v to <3 x i32>
 %negative = icmp slt <3 x i32> %raw,zeroinitializer
 %mask = and <3 x i1> %zeros,%negative
 %sign = call i1 @llvm.vector.reduce.or.v3i1(<3 x i1> %mask)
 %correct_zero = select i1 %sign,float -0.000000e+00,float 0.000000e+00
 %is_zero = fcmp oeq float %ordinary,0.000000e+00
 %answer = select i1 %is_zero,float %correct_zero,float %ordinary
 store float %answer,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare float @llvm.vector.reduce.fmax.v3f32(<3 x float>)
define i64 @floating_minmax_32_3_max(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <3 x float>,ptr %in,align 1
 %ordinary = call float @llvm.vector.reduce.fmax.v3f32(<3 x float> %v)
 %zeros = fcmp oeq <3 x float> %v,zeroinitializer
 %raw = bitcast <3 x float> %v to <3 x i32>
 %negative = icmp slt <3 x i32> %raw,zeroinitializer
 %mask = select <3 x i1> %zeros,<3 x i1> %negative,<3 x i1> <i1 true,i1 true,i1 true>
 %sign = call i1 @llvm.vector.reduce.and.v3i1(<3 x i1> %mask)
 %correct_zero = select i1 %sign,float -0.000000e+00,float 0.000000e+00
 %is_zero = fcmp oeq float %ordinary,0.000000e+00
 %answer = select i1 %is_zero,float %correct_zero,float %ordinary
 store float %answer,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare float @llvm.vector.reduce.fmin.v4f32(<4 x float>)
define i64 @floating_minmax_32_4_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <4 x float>,ptr %in,align 1
 %ordinary = call float @llvm.vector.reduce.fmin.v4f32(<4 x float> %v)
 %zeros = fcmp oeq <4 x float> %v,zeroinitializer
 %raw = bitcast <4 x float> %v to <4 x i32>
 %negative = icmp slt <4 x i32> %raw,zeroinitializer
 %mask = and <4 x i1> %zeros,%negative
 %sign = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %mask)
 %correct_zero = select i1 %sign,float -0.000000e+00,float 0.000000e+00
 %is_zero = fcmp oeq float %ordinary,0.000000e+00
 %answer = select i1 %is_zero,float %correct_zero,float %ordinary
 store float %answer,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare float @llvm.vector.reduce.fmax.v4f32(<4 x float>)
define i64 @floating_minmax_32_4_max(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <4 x float>,ptr %in,align 1
 %ordinary = call float @llvm.vector.reduce.fmax.v4f32(<4 x float> %v)
 %zeros = fcmp oeq <4 x float> %v,zeroinitializer
 %raw = bitcast <4 x float> %v to <4 x i32>
 %negative = icmp slt <4 x i32> %raw,zeroinitializer
 %mask = select <4 x i1> %zeros,<4 x i1> %negative,<4 x i1> <i1 true,i1 true,i1 true,i1 true>
 %sign = call i1 @llvm.vector.reduce.and.v4i1(<4 x i1> %mask)
 %correct_zero = select i1 %sign,float -0.000000e+00,float 0.000000e+00
 %is_zero = fcmp oeq float %ordinary,0.000000e+00
 %answer = select i1 %is_zero,float %correct_zero,float %ordinary
 store float %answer,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare double @llvm.vector.reduce.fmin.v2f64(<2 x double>)
define i64 @floating_minmax_64_2_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <2 x double>,ptr %in,align 1
 %ordinary = call double @llvm.vector.reduce.fmin.v2f64(<2 x double> %v)
 %zeros = fcmp oeq <2 x double> %v,zeroinitializer
 %raw = bitcast <2 x double> %v to <2 x i64>
 %negative = icmp slt <2 x i64> %raw,zeroinitializer
 %mask = and <2 x i1> %zeros,%negative
 %sign = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %mask)
 %correct_zero = select i1 %sign,double -0.000000e+00,double 0.000000e+00
 %is_zero = fcmp oeq double %ordinary,0.000000e+00
 %answer = select i1 %is_zero,double %correct_zero,double %ordinary
 store double %answer,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare double @llvm.vector.reduce.fmax.v2f64(<2 x double>)
define i64 @floating_minmax_64_2_max(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <2 x double>,ptr %in,align 1
 %ordinary = call double @llvm.vector.reduce.fmax.v2f64(<2 x double> %v)
 %zeros = fcmp oeq <2 x double> %v,zeroinitializer
 %raw = bitcast <2 x double> %v to <2 x i64>
 %negative = icmp slt <2 x i64> %raw,zeroinitializer
 %mask = select <2 x i1> %zeros,<2 x i1> %negative,<2 x i1> <i1 true,i1 true>
 %sign = call i1 @llvm.vector.reduce.and.v2i1(<2 x i1> %mask)
 %correct_zero = select i1 %sign,double -0.000000e+00,double 0.000000e+00
 %is_zero = fcmp oeq double %ordinary,0.000000e+00
 %answer = select i1 %is_zero,double %correct_zero,double %ordinary
 store double %answer,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare double @llvm.vector.reduce.fmin.v3f64(<3 x double>)
define i64 @floating_minmax_64_3_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <3 x double>,ptr %in,align 1
 %ordinary = call double @llvm.vector.reduce.fmin.v3f64(<3 x double> %v)
 %zeros = fcmp oeq <3 x double> %v,zeroinitializer
 %raw = bitcast <3 x double> %v to <3 x i64>
 %negative = icmp slt <3 x i64> %raw,zeroinitializer
 %mask = and <3 x i1> %zeros,%negative
 %sign = call i1 @llvm.vector.reduce.or.v3i1(<3 x i1> %mask)
 %correct_zero = select i1 %sign,double -0.000000e+00,double 0.000000e+00
 %is_zero = fcmp oeq double %ordinary,0.000000e+00
 %answer = select i1 %is_zero,double %correct_zero,double %ordinary
 store double %answer,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare double @llvm.vector.reduce.fmax.v3f64(<3 x double>)
define i64 @floating_minmax_64_3_max(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <3 x double>,ptr %in,align 1
 %ordinary = call double @llvm.vector.reduce.fmax.v3f64(<3 x double> %v)
 %zeros = fcmp oeq <3 x double> %v,zeroinitializer
 %raw = bitcast <3 x double> %v to <3 x i64>
 %negative = icmp slt <3 x i64> %raw,zeroinitializer
 %mask = select <3 x i1> %zeros,<3 x i1> %negative,<3 x i1> <i1 true,i1 true,i1 true>
 %sign = call i1 @llvm.vector.reduce.and.v3i1(<3 x i1> %mask)
 %correct_zero = select i1 %sign,double -0.000000e+00,double 0.000000e+00
 %is_zero = fcmp oeq double %ordinary,0.000000e+00
 %answer = select i1 %is_zero,double %correct_zero,double %ordinary
 store double %answer,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare double @llvm.vector.reduce.fmin.v4f64(<4 x double>)
define i64 @floating_minmax_64_4_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <4 x double>,ptr %in,align 1
 %ordinary = call double @llvm.vector.reduce.fmin.v4f64(<4 x double> %v)
 %zeros = fcmp oeq <4 x double> %v,zeroinitializer
 %raw = bitcast <4 x double> %v to <4 x i64>
 %negative = icmp slt <4 x i64> %raw,zeroinitializer
 %mask = and <4 x i1> %zeros,%negative
 %sign = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %mask)
 %correct_zero = select i1 %sign,double -0.000000e+00,double 0.000000e+00
 %is_zero = fcmp oeq double %ordinary,0.000000e+00
 %answer = select i1 %is_zero,double %correct_zero,double %ordinary
 store double %answer,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare double @llvm.vector.reduce.fmax.v4f64(<4 x double>)
define i64 @floating_minmax_64_4_max(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <4 x double>,ptr %in,align 1
 %ordinary = call double @llvm.vector.reduce.fmax.v4f64(<4 x double> %v)
 %zeros = fcmp oeq <4 x double> %v,zeroinitializer
 %raw = bitcast <4 x double> %v to <4 x i64>
 %negative = icmp slt <4 x i64> %raw,zeroinitializer
 %mask = select <4 x i1> %zeros,<4 x i1> %negative,<4 x i1> <i1 true,i1 true,i1 true,i1 true>
 %sign = call i1 @llvm.vector.reduce.and.v4i1(<4 x i1> %mask)
 %correct_zero = select i1 %sign,double -0.000000e+00,double 0.000000e+00
 %is_zero = fcmp oeq double %ordinary,0.000000e+00
 %answer = select i1 %is_zero,double %correct_zero,double %ordinary
 store double %answer,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare x86_fp80 @llvm.vector.reduce.fmin.v2f80(<2 x x86_fp80>)
define i64 @floating_minmax_80_2_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <2 x x86_fp80>,ptr %in,align 1
 %ordinary = call x86_fp80 @llvm.vector.reduce.fmin.v2f80(<2 x x86_fp80> %v)
 %zeros = fcmp oeq <2 x x86_fp80> %v,zeroinitializer
 %raw = bitcast <2 x x86_fp80> %v to <2 x i80>
 %negative = icmp slt <2 x i80> %raw,zeroinitializer
 %mask = and <2 x i1> %zeros,%negative
 %sign = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %mask)
 %correct_zero = select i1 %sign,x86_fp80 0xK80000000000000000000,x86_fp80 0xK00000000000000000000
 %is_zero = fcmp oeq x86_fp80 %ordinary,0xK00000000000000000000
 %answer = select i1 %is_zero,x86_fp80 %correct_zero,x86_fp80 %ordinary
 store x86_fp80 %answer,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare x86_fp80 @llvm.vector.reduce.fmax.v2f80(<2 x x86_fp80>)
define i64 @floating_minmax_80_2_max(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <2 x x86_fp80>,ptr %in,align 1
 %ordinary = call x86_fp80 @llvm.vector.reduce.fmax.v2f80(<2 x x86_fp80> %v)
 %zeros = fcmp oeq <2 x x86_fp80> %v,zeroinitializer
 %raw = bitcast <2 x x86_fp80> %v to <2 x i80>
 %negative = icmp slt <2 x i80> %raw,zeroinitializer
 %mask = select <2 x i1> %zeros,<2 x i1> %negative,<2 x i1> <i1 true,i1 true>
 %sign = call i1 @llvm.vector.reduce.and.v2i1(<2 x i1> %mask)
 %correct_zero = select i1 %sign,x86_fp80 0xK80000000000000000000,x86_fp80 0xK00000000000000000000
 %is_zero = fcmp oeq x86_fp80 %ordinary,0xK00000000000000000000
 %answer = select i1 %is_zero,x86_fp80 %correct_zero,x86_fp80 %ordinary
 store x86_fp80 %answer,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare x86_fp80 @llvm.vector.reduce.fmin.v3f80(<3 x x86_fp80>)
define i64 @floating_minmax_80_3_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <3 x x86_fp80>,ptr %in,align 1
 %ordinary = call x86_fp80 @llvm.vector.reduce.fmin.v3f80(<3 x x86_fp80> %v)
 %zeros = fcmp oeq <3 x x86_fp80> %v,zeroinitializer
 %raw = bitcast <3 x x86_fp80> %v to <3 x i80>
 %negative = icmp slt <3 x i80> %raw,zeroinitializer
 %mask = and <3 x i1> %zeros,%negative
 %sign = call i1 @llvm.vector.reduce.or.v3i1(<3 x i1> %mask)
 %correct_zero = select i1 %sign,x86_fp80 0xK80000000000000000000,x86_fp80 0xK00000000000000000000
 %is_zero = fcmp oeq x86_fp80 %ordinary,0xK00000000000000000000
 %answer = select i1 %is_zero,x86_fp80 %correct_zero,x86_fp80 %ordinary
 store x86_fp80 %answer,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare x86_fp80 @llvm.vector.reduce.fmax.v3f80(<3 x x86_fp80>)
define i64 @floating_minmax_80_3_max(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <3 x x86_fp80>,ptr %in,align 1
 %ordinary = call x86_fp80 @llvm.vector.reduce.fmax.v3f80(<3 x x86_fp80> %v)
 %zeros = fcmp oeq <3 x x86_fp80> %v,zeroinitializer
 %raw = bitcast <3 x x86_fp80> %v to <3 x i80>
 %negative = icmp slt <3 x i80> %raw,zeroinitializer
 %mask = select <3 x i1> %zeros,<3 x i1> %negative,<3 x i1> <i1 true,i1 true,i1 true>
 %sign = call i1 @llvm.vector.reduce.and.v3i1(<3 x i1> %mask)
 %correct_zero = select i1 %sign,x86_fp80 0xK80000000000000000000,x86_fp80 0xK00000000000000000000
 %is_zero = fcmp oeq x86_fp80 %ordinary,0xK00000000000000000000
 %answer = select i1 %is_zero,x86_fp80 %correct_zero,x86_fp80 %ordinary
 store x86_fp80 %answer,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare x86_fp80 @llvm.vector.reduce.fmin.v4f80(<4 x x86_fp80>)
define i64 @floating_minmax_80_4_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <4 x x86_fp80>,ptr %in,align 1
 %ordinary = call x86_fp80 @llvm.vector.reduce.fmin.v4f80(<4 x x86_fp80> %v)
 %zeros = fcmp oeq <4 x x86_fp80> %v,zeroinitializer
 %raw = bitcast <4 x x86_fp80> %v to <4 x i80>
 %negative = icmp slt <4 x i80> %raw,zeroinitializer
 %mask = and <4 x i1> %zeros,%negative
 %sign = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %mask)
 %correct_zero = select i1 %sign,x86_fp80 0xK80000000000000000000,x86_fp80 0xK00000000000000000000
 %is_zero = fcmp oeq x86_fp80 %ordinary,0xK00000000000000000000
 %answer = select i1 %is_zero,x86_fp80 %correct_zero,x86_fp80 %ordinary
 store x86_fp80 %answer,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare x86_fp80 @llvm.vector.reduce.fmax.v4f80(<4 x x86_fp80>)
define i64 @floating_minmax_80_4_max(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <4 x x86_fp80>,ptr %in,align 1
 %ordinary = call x86_fp80 @llvm.vector.reduce.fmax.v4f80(<4 x x86_fp80> %v)
 %zeros = fcmp oeq <4 x x86_fp80> %v,zeroinitializer
 %raw = bitcast <4 x x86_fp80> %v to <4 x i80>
 %negative = icmp slt <4 x i80> %raw,zeroinitializer
 %mask = select <4 x i1> %zeros,<4 x i1> %negative,<4 x i1> <i1 true,i1 true,i1 true,i1 true>
 %sign = call i1 @llvm.vector.reduce.and.v4i1(<4 x i1> %mask)
 %correct_zero = select i1 %sign,x86_fp80 0xK80000000000000000000,x86_fp80 0xK00000000000000000000
 %is_zero = fcmp oeq x86_fp80 %ordinary,0xK00000000000000000000
 %answer = select i1 %is_zero,x86_fp80 %correct_zero,x86_fp80 %ordinary
 store x86_fp80 %answer,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare fp128 @llvm.vector.reduce.fmin.v2f128(<2 x fp128>)
define i64 @floating_minmax_128_2_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <2 x fp128>,ptr %in,align 1
 %ordinary = call fp128 @llvm.vector.reduce.fmin.v2f128(<2 x fp128> %v)
 %zeros = fcmp oeq <2 x fp128> %v,zeroinitializer
 %raw = bitcast <2 x fp128> %v to <2 x i128>
 %negative = icmp slt <2 x i128> %raw,zeroinitializer
 %mask = and <2 x i1> %zeros,%negative
 %sign = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %mask)
 %correct_zero = select i1 %sign,fp128 0xL00000000000000008000000000000000,fp128 0xL00000000000000000000000000000000
 %is_zero = fcmp oeq fp128 %ordinary,0xL00000000000000000000000000000000
 %answer = select i1 %is_zero,fp128 %correct_zero,fp128 %ordinary
 store fp128 %answer,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare fp128 @llvm.vector.reduce.fmax.v2f128(<2 x fp128>)
define i64 @floating_minmax_128_2_max(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <2 x fp128>,ptr %in,align 1
 %ordinary = call fp128 @llvm.vector.reduce.fmax.v2f128(<2 x fp128> %v)
 %zeros = fcmp oeq <2 x fp128> %v,zeroinitializer
 %raw = bitcast <2 x fp128> %v to <2 x i128>
 %negative = icmp slt <2 x i128> %raw,zeroinitializer
 %mask = select <2 x i1> %zeros,<2 x i1> %negative,<2 x i1> <i1 true,i1 true>
 %sign = call i1 @llvm.vector.reduce.and.v2i1(<2 x i1> %mask)
 %correct_zero = select i1 %sign,fp128 0xL00000000000000008000000000000000,fp128 0xL00000000000000000000000000000000
 %is_zero = fcmp oeq fp128 %ordinary,0xL00000000000000000000000000000000
 %answer = select i1 %is_zero,fp128 %correct_zero,fp128 %ordinary
 store fp128 %answer,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare fp128 @llvm.vector.reduce.fmin.v3f128(<3 x fp128>)
define i64 @floating_minmax_128_3_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <3 x fp128>,ptr %in,align 1
 %ordinary = call fp128 @llvm.vector.reduce.fmin.v3f128(<3 x fp128> %v)
 %zeros = fcmp oeq <3 x fp128> %v,zeroinitializer
 %raw = bitcast <3 x fp128> %v to <3 x i128>
 %negative = icmp slt <3 x i128> %raw,zeroinitializer
 %mask = and <3 x i1> %zeros,%negative
 %sign = call i1 @llvm.vector.reduce.or.v3i1(<3 x i1> %mask)
 %correct_zero = select i1 %sign,fp128 0xL00000000000000008000000000000000,fp128 0xL00000000000000000000000000000000
 %is_zero = fcmp oeq fp128 %ordinary,0xL00000000000000000000000000000000
 %answer = select i1 %is_zero,fp128 %correct_zero,fp128 %ordinary
 store fp128 %answer,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare fp128 @llvm.vector.reduce.fmax.v3f128(<3 x fp128>)
define i64 @floating_minmax_128_3_max(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <3 x fp128>,ptr %in,align 1
 %ordinary = call fp128 @llvm.vector.reduce.fmax.v3f128(<3 x fp128> %v)
 %zeros = fcmp oeq <3 x fp128> %v,zeroinitializer
 %raw = bitcast <3 x fp128> %v to <3 x i128>
 %negative = icmp slt <3 x i128> %raw,zeroinitializer
 %mask = select <3 x i1> %zeros,<3 x i1> %negative,<3 x i1> <i1 true,i1 true,i1 true>
 %sign = call i1 @llvm.vector.reduce.and.v3i1(<3 x i1> %mask)
 %correct_zero = select i1 %sign,fp128 0xL00000000000000008000000000000000,fp128 0xL00000000000000000000000000000000
 %is_zero = fcmp oeq fp128 %ordinary,0xL00000000000000000000000000000000
 %answer = select i1 %is_zero,fp128 %correct_zero,fp128 %ordinary
 store fp128 %answer,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare fp128 @llvm.vector.reduce.fmin.v4f128(<4 x fp128>)
define i64 @floating_minmax_128_4_min(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <4 x fp128>,ptr %in,align 1
 %ordinary = call fp128 @llvm.vector.reduce.fmin.v4f128(<4 x fp128> %v)
 %zeros = fcmp oeq <4 x fp128> %v,zeroinitializer
 %raw = bitcast <4 x fp128> %v to <4 x i128>
 %negative = icmp slt <4 x i128> %raw,zeroinitializer
 %mask = and <4 x i1> %zeros,%negative
 %sign = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %mask)
 %correct_zero = select i1 %sign,fp128 0xL00000000000000008000000000000000,fp128 0xL00000000000000000000000000000000
 %is_zero = fcmp oeq fp128 %ordinary,0xL00000000000000000000000000000000
 %answer = select i1 %is_zero,fp128 %correct_zero,fp128 %ordinary
 store fp128 %answer,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare fp128 @llvm.vector.reduce.fmax.v4f128(<4 x fp128>)
define i64 @floating_minmax_128_4_max(ptr %out,ptr %in,i64 %salt) {
entry:
 %v = load <4 x fp128>,ptr %in,align 1
 %ordinary = call fp128 @llvm.vector.reduce.fmax.v4f128(<4 x fp128> %v)
 %zeros = fcmp oeq <4 x fp128> %v,zeroinitializer
 %raw = bitcast <4 x fp128> %v to <4 x i128>
 %negative = icmp slt <4 x i128> %raw,zeroinitializer
 %mask = select <4 x i1> %zeros,<4 x i1> %negative,<4 x i1> <i1 true,i1 true,i1 true,i1 true>
 %sign = call i1 @llvm.vector.reduce.and.v4i1(<4 x i1> %mask)
 %correct_zero = select i1 %sign,fp128 0xL00000000000000008000000000000000,fp128 0xL00000000000000000000000000000000
 %is_zero = fcmp oeq fp128 %ordinary,0xL00000000000000000000000000000000
 %answer = select i1 %is_zero,fp128 %correct_zero,fp128 %ordinary
 store fp128 %answer,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
