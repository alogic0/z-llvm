target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare <2 x half> @llvm.minnum.v2f16(<2 x half>,<2 x half>)
define i64 @vector_fp_extrema_16_2_0_0(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <2 x half>,ptr %a_ptr,align 1
 %b = load <2 x half>,ptr %b_ptr,align 1
 %result = call <2 x half> @llvm.minnum.v2f16(<2 x half> %a,<2 x half> %b)
 store <2 x half> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_fp_extrema_16_2_0_1(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <2 x half>,ptr %a_ptr,align 1
 %b = load <2 x half>,ptr %b_ptr,align 1
 %result = call <2 x half> @llvm.minnum.v2f16(<2 x half> %a,<2 x half> %b)
 store <2 x half> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x half> @llvm.maxnum.v2f16(<2 x half>,<2 x half>)
define i64 @vector_fp_extrema_16_2_1_0(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <2 x half>,ptr %a_ptr,align 1
 %b = load <2 x half>,ptr %b_ptr,align 1
 %result = call <2 x half> @llvm.maxnum.v2f16(<2 x half> %a,<2 x half> %b)
 store <2 x half> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_fp_extrema_16_2_1_1(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <2 x half>,ptr %a_ptr,align 1
 %b = load <2 x half>,ptr %b_ptr,align 1
 %result = call <2 x half> @llvm.maxnum.v2f16(<2 x half> %a,<2 x half> %b)
 store <2 x half> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x half> @llvm.minnum.v3f16(<3 x half>,<3 x half>)
define i64 @vector_fp_extrema_16_3_0_0(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <3 x half>,ptr %a_ptr,align 1
 %b = load <3 x half>,ptr %b_ptr,align 1
 %result = call <3 x half> @llvm.minnum.v3f16(<3 x half> %a,<3 x half> %b)
 store <3 x half> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_fp_extrema_16_3_0_1(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <3 x half>,ptr %a_ptr,align 1
 %b = load <3 x half>,ptr %b_ptr,align 1
 %result = call <3 x half> @llvm.minnum.v3f16(<3 x half> %a,<3 x half> %b)
 store <3 x half> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x half> @llvm.maxnum.v3f16(<3 x half>,<3 x half>)
define i64 @vector_fp_extrema_16_3_1_0(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <3 x half>,ptr %a_ptr,align 1
 %b = load <3 x half>,ptr %b_ptr,align 1
 %result = call <3 x half> @llvm.maxnum.v3f16(<3 x half> %a,<3 x half> %b)
 store <3 x half> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_fp_extrema_16_3_1_1(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <3 x half>,ptr %a_ptr,align 1
 %b = load <3 x half>,ptr %b_ptr,align 1
 %result = call <3 x half> @llvm.maxnum.v3f16(<3 x half> %a,<3 x half> %b)
 store <3 x half> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x half> @llvm.minnum.v4f16(<4 x half>,<4 x half>)
define i64 @vector_fp_extrema_16_4_0_0(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <4 x half>,ptr %a_ptr,align 1
 %b = load <4 x half>,ptr %b_ptr,align 1
 %result = call <4 x half> @llvm.minnum.v4f16(<4 x half> %a,<4 x half> %b)
 store <4 x half> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_fp_extrema_16_4_0_1(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <4 x half>,ptr %a_ptr,align 1
 %b = load <4 x half>,ptr %b_ptr,align 1
 %result = call <4 x half> @llvm.minnum.v4f16(<4 x half> %a,<4 x half> %b)
 store <4 x half> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x half> @llvm.maxnum.v4f16(<4 x half>,<4 x half>)
define i64 @vector_fp_extrema_16_4_1_0(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <4 x half>,ptr %a_ptr,align 1
 %b = load <4 x half>,ptr %b_ptr,align 1
 %result = call <4 x half> @llvm.maxnum.v4f16(<4 x half> %a,<4 x half> %b)
 store <4 x half> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_fp_extrema_16_4_1_1(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <4 x half>,ptr %a_ptr,align 1
 %b = load <4 x half>,ptr %b_ptr,align 1
 %result = call <4 x half> @llvm.maxnum.v4f16(<4 x half> %a,<4 x half> %b)
 store <4 x half> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x float> @llvm.minnum.v2f32(<2 x float>,<2 x float>)
define i64 @vector_fp_extrema_32_2_0_0(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <2 x float>,ptr %a_ptr,align 1
 %b = load <2 x float>,ptr %b_ptr,align 1
 %result = call <2 x float> @llvm.minnum.v2f32(<2 x float> %a,<2 x float> %b)
 store <2 x float> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_fp_extrema_32_2_0_1(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <2 x float>,ptr %a_ptr,align 1
 %b = load <2 x float>,ptr %b_ptr,align 1
 %result = call <2 x float> @llvm.minnum.v2f32(<2 x float> %a,<2 x float> %b)
 store <2 x float> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x float> @llvm.maxnum.v2f32(<2 x float>,<2 x float>)
define i64 @vector_fp_extrema_32_2_1_0(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <2 x float>,ptr %a_ptr,align 1
 %b = load <2 x float>,ptr %b_ptr,align 1
 %result = call <2 x float> @llvm.maxnum.v2f32(<2 x float> %a,<2 x float> %b)
 store <2 x float> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_fp_extrema_32_2_1_1(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <2 x float>,ptr %a_ptr,align 1
 %b = load <2 x float>,ptr %b_ptr,align 1
 %result = call <2 x float> @llvm.maxnum.v2f32(<2 x float> %a,<2 x float> %b)
 store <2 x float> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x float> @llvm.minnum.v3f32(<3 x float>,<3 x float>)
define i64 @vector_fp_extrema_32_3_0_0(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <3 x float>,ptr %a_ptr,align 1
 %b = load <3 x float>,ptr %b_ptr,align 1
 %result = call <3 x float> @llvm.minnum.v3f32(<3 x float> %a,<3 x float> %b)
 store <3 x float> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_fp_extrema_32_3_0_1(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <3 x float>,ptr %a_ptr,align 1
 %b = load <3 x float>,ptr %b_ptr,align 1
 %result = call <3 x float> @llvm.minnum.v3f32(<3 x float> %a,<3 x float> %b)
 store <3 x float> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x float> @llvm.maxnum.v3f32(<3 x float>,<3 x float>)
define i64 @vector_fp_extrema_32_3_1_0(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <3 x float>,ptr %a_ptr,align 1
 %b = load <3 x float>,ptr %b_ptr,align 1
 %result = call <3 x float> @llvm.maxnum.v3f32(<3 x float> %a,<3 x float> %b)
 store <3 x float> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_fp_extrema_32_3_1_1(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <3 x float>,ptr %a_ptr,align 1
 %b = load <3 x float>,ptr %b_ptr,align 1
 %result = call <3 x float> @llvm.maxnum.v3f32(<3 x float> %a,<3 x float> %b)
 store <3 x float> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x float> @llvm.minnum.v4f32(<4 x float>,<4 x float>)
define i64 @vector_fp_extrema_32_4_0_0(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <4 x float>,ptr %a_ptr,align 1
 %b = load <4 x float>,ptr %b_ptr,align 1
 %result = call <4 x float> @llvm.minnum.v4f32(<4 x float> %a,<4 x float> %b)
 store <4 x float> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_fp_extrema_32_4_0_1(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <4 x float>,ptr %a_ptr,align 1
 %b = load <4 x float>,ptr %b_ptr,align 1
 %result = call <4 x float> @llvm.minnum.v4f32(<4 x float> %a,<4 x float> %b)
 store <4 x float> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x float> @llvm.maxnum.v4f32(<4 x float>,<4 x float>)
define i64 @vector_fp_extrema_32_4_1_0(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <4 x float>,ptr %a_ptr,align 1
 %b = load <4 x float>,ptr %b_ptr,align 1
 %result = call <4 x float> @llvm.maxnum.v4f32(<4 x float> %a,<4 x float> %b)
 store <4 x float> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_fp_extrema_32_4_1_1(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <4 x float>,ptr %a_ptr,align 1
 %b = load <4 x float>,ptr %b_ptr,align 1
 %result = call <4 x float> @llvm.maxnum.v4f32(<4 x float> %a,<4 x float> %b)
 store <4 x float> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x double> @llvm.minnum.v2f64(<2 x double>,<2 x double>)
define i64 @vector_fp_extrema_64_2_0_0(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <2 x double>,ptr %a_ptr,align 1
 %b = load <2 x double>,ptr %b_ptr,align 1
 %result = call <2 x double> @llvm.minnum.v2f64(<2 x double> %a,<2 x double> %b)
 store <2 x double> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_fp_extrema_64_2_0_1(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <2 x double>,ptr %a_ptr,align 1
 %b = load <2 x double>,ptr %b_ptr,align 1
 %result = call <2 x double> @llvm.minnum.v2f64(<2 x double> %a,<2 x double> %b)
 store <2 x double> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x double> @llvm.maxnum.v2f64(<2 x double>,<2 x double>)
define i64 @vector_fp_extrema_64_2_1_0(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <2 x double>,ptr %a_ptr,align 1
 %b = load <2 x double>,ptr %b_ptr,align 1
 %result = call <2 x double> @llvm.maxnum.v2f64(<2 x double> %a,<2 x double> %b)
 store <2 x double> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_fp_extrema_64_2_1_1(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <2 x double>,ptr %a_ptr,align 1
 %b = load <2 x double>,ptr %b_ptr,align 1
 %result = call <2 x double> @llvm.maxnum.v2f64(<2 x double> %a,<2 x double> %b)
 store <2 x double> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x double> @llvm.minnum.v3f64(<3 x double>,<3 x double>)
define i64 @vector_fp_extrema_64_3_0_0(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <3 x double>,ptr %a_ptr,align 1
 %b = load <3 x double>,ptr %b_ptr,align 1
 %result = call <3 x double> @llvm.minnum.v3f64(<3 x double> %a,<3 x double> %b)
 store <3 x double> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_fp_extrema_64_3_0_1(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <3 x double>,ptr %a_ptr,align 1
 %b = load <3 x double>,ptr %b_ptr,align 1
 %result = call <3 x double> @llvm.minnum.v3f64(<3 x double> %a,<3 x double> %b)
 store <3 x double> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x double> @llvm.maxnum.v3f64(<3 x double>,<3 x double>)
define i64 @vector_fp_extrema_64_3_1_0(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <3 x double>,ptr %a_ptr,align 1
 %b = load <3 x double>,ptr %b_ptr,align 1
 %result = call <3 x double> @llvm.maxnum.v3f64(<3 x double> %a,<3 x double> %b)
 store <3 x double> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_fp_extrema_64_3_1_1(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <3 x double>,ptr %a_ptr,align 1
 %b = load <3 x double>,ptr %b_ptr,align 1
 %result = call <3 x double> @llvm.maxnum.v3f64(<3 x double> %a,<3 x double> %b)
 store <3 x double> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x double> @llvm.minnum.v4f64(<4 x double>,<4 x double>)
define i64 @vector_fp_extrema_64_4_0_0(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <4 x double>,ptr %a_ptr,align 1
 %b = load <4 x double>,ptr %b_ptr,align 1
 %result = call <4 x double> @llvm.minnum.v4f64(<4 x double> %a,<4 x double> %b)
 store <4 x double> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_fp_extrema_64_4_0_1(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <4 x double>,ptr %a_ptr,align 1
 %b = load <4 x double>,ptr %b_ptr,align 1
 %result = call <4 x double> @llvm.minnum.v4f64(<4 x double> %a,<4 x double> %b)
 store <4 x double> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x double> @llvm.maxnum.v4f64(<4 x double>,<4 x double>)
define i64 @vector_fp_extrema_64_4_1_0(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <4 x double>,ptr %a_ptr,align 1
 %b = load <4 x double>,ptr %b_ptr,align 1
 %result = call <4 x double> @llvm.maxnum.v4f64(<4 x double> %a,<4 x double> %b)
 store <4 x double> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_fp_extrema_64_4_1_1(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <4 x double>,ptr %a_ptr,align 1
 %b = load <4 x double>,ptr %b_ptr,align 1
 %result = call <4 x double> @llvm.maxnum.v4f64(<4 x double> %a,<4 x double> %b)
 store <4 x double> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x x86_fp80> @llvm.minnum.v2f80(<2 x x86_fp80>,<2 x x86_fp80>)
define i64 @vector_fp_extrema_80_2_0_0(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <2 x x86_fp80>,ptr %a_ptr,align 1
 %b = load <2 x x86_fp80>,ptr %b_ptr,align 1
 %result = call <2 x x86_fp80> @llvm.minnum.v2f80(<2 x x86_fp80> %a,<2 x x86_fp80> %b)
 store <2 x x86_fp80> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_fp_extrema_80_2_0_1(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <2 x x86_fp80>,ptr %a_ptr,align 1
 %b = load <2 x x86_fp80>,ptr %b_ptr,align 1
 %result = call <2 x x86_fp80> @llvm.minnum.v2f80(<2 x x86_fp80> %a,<2 x x86_fp80> %b)
 store <2 x x86_fp80> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x x86_fp80> @llvm.maxnum.v2f80(<2 x x86_fp80>,<2 x x86_fp80>)
define i64 @vector_fp_extrema_80_2_1_0(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <2 x x86_fp80>,ptr %a_ptr,align 1
 %b = load <2 x x86_fp80>,ptr %b_ptr,align 1
 %result = call <2 x x86_fp80> @llvm.maxnum.v2f80(<2 x x86_fp80> %a,<2 x x86_fp80> %b)
 store <2 x x86_fp80> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_fp_extrema_80_2_1_1(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <2 x x86_fp80>,ptr %a_ptr,align 1
 %b = load <2 x x86_fp80>,ptr %b_ptr,align 1
 %result = call <2 x x86_fp80> @llvm.maxnum.v2f80(<2 x x86_fp80> %a,<2 x x86_fp80> %b)
 store <2 x x86_fp80> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x x86_fp80> @llvm.minnum.v3f80(<3 x x86_fp80>,<3 x x86_fp80>)
define i64 @vector_fp_extrema_80_3_0_0(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <3 x x86_fp80>,ptr %a_ptr,align 1
 %b = load <3 x x86_fp80>,ptr %b_ptr,align 1
 %result = call <3 x x86_fp80> @llvm.minnum.v3f80(<3 x x86_fp80> %a,<3 x x86_fp80> %b)
 store <3 x x86_fp80> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_fp_extrema_80_3_0_1(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <3 x x86_fp80>,ptr %a_ptr,align 1
 %b = load <3 x x86_fp80>,ptr %b_ptr,align 1
 %result = call <3 x x86_fp80> @llvm.minnum.v3f80(<3 x x86_fp80> %a,<3 x x86_fp80> %b)
 store <3 x x86_fp80> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x x86_fp80> @llvm.maxnum.v3f80(<3 x x86_fp80>,<3 x x86_fp80>)
define i64 @vector_fp_extrema_80_3_1_0(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <3 x x86_fp80>,ptr %a_ptr,align 1
 %b = load <3 x x86_fp80>,ptr %b_ptr,align 1
 %result = call <3 x x86_fp80> @llvm.maxnum.v3f80(<3 x x86_fp80> %a,<3 x x86_fp80> %b)
 store <3 x x86_fp80> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_fp_extrema_80_3_1_1(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <3 x x86_fp80>,ptr %a_ptr,align 1
 %b = load <3 x x86_fp80>,ptr %b_ptr,align 1
 %result = call <3 x x86_fp80> @llvm.maxnum.v3f80(<3 x x86_fp80> %a,<3 x x86_fp80> %b)
 store <3 x x86_fp80> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x x86_fp80> @llvm.minnum.v4f80(<4 x x86_fp80>,<4 x x86_fp80>)
define i64 @vector_fp_extrema_80_4_0_0(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <4 x x86_fp80>,ptr %a_ptr,align 1
 %b = load <4 x x86_fp80>,ptr %b_ptr,align 1
 %result = call <4 x x86_fp80> @llvm.minnum.v4f80(<4 x x86_fp80> %a,<4 x x86_fp80> %b)
 store <4 x x86_fp80> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_fp_extrema_80_4_0_1(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <4 x x86_fp80>,ptr %a_ptr,align 1
 %b = load <4 x x86_fp80>,ptr %b_ptr,align 1
 %result = call <4 x x86_fp80> @llvm.minnum.v4f80(<4 x x86_fp80> %a,<4 x x86_fp80> %b)
 store <4 x x86_fp80> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x x86_fp80> @llvm.maxnum.v4f80(<4 x x86_fp80>,<4 x x86_fp80>)
define i64 @vector_fp_extrema_80_4_1_0(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <4 x x86_fp80>,ptr %a_ptr,align 1
 %b = load <4 x x86_fp80>,ptr %b_ptr,align 1
 %result = call <4 x x86_fp80> @llvm.maxnum.v4f80(<4 x x86_fp80> %a,<4 x x86_fp80> %b)
 store <4 x x86_fp80> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_fp_extrema_80_4_1_1(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <4 x x86_fp80>,ptr %a_ptr,align 1
 %b = load <4 x x86_fp80>,ptr %b_ptr,align 1
 %result = call <4 x x86_fp80> @llvm.maxnum.v4f80(<4 x x86_fp80> %a,<4 x x86_fp80> %b)
 store <4 x x86_fp80> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x fp128> @llvm.minnum.v2f128(<2 x fp128>,<2 x fp128>)
define i64 @vector_fp_extrema_128_2_0_0(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <2 x fp128>,ptr %a_ptr,align 1
 %b = load <2 x fp128>,ptr %b_ptr,align 1
 %result = call <2 x fp128> @llvm.minnum.v2f128(<2 x fp128> %a,<2 x fp128> %b)
 store <2 x fp128> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_fp_extrema_128_2_0_1(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <2 x fp128>,ptr %a_ptr,align 1
 %b = load <2 x fp128>,ptr %b_ptr,align 1
 %result = call <2 x fp128> @llvm.minnum.v2f128(<2 x fp128> %a,<2 x fp128> %b)
 store <2 x fp128> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <2 x fp128> @llvm.maxnum.v2f128(<2 x fp128>,<2 x fp128>)
define i64 @vector_fp_extrema_128_2_1_0(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <2 x fp128>,ptr %a_ptr,align 1
 %b = load <2 x fp128>,ptr %b_ptr,align 1
 %result = call <2 x fp128> @llvm.maxnum.v2f128(<2 x fp128> %a,<2 x fp128> %b)
 store <2 x fp128> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_fp_extrema_128_2_1_1(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <2 x fp128>,ptr %a_ptr,align 1
 %b = load <2 x fp128>,ptr %b_ptr,align 1
 %result = call <2 x fp128> @llvm.maxnum.v2f128(<2 x fp128> %a,<2 x fp128> %b)
 store <2 x fp128> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x fp128> @llvm.minnum.v3f128(<3 x fp128>,<3 x fp128>)
define i64 @vector_fp_extrema_128_3_0_0(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <3 x fp128>,ptr %a_ptr,align 1
 %b = load <3 x fp128>,ptr %b_ptr,align 1
 %result = call <3 x fp128> @llvm.minnum.v3f128(<3 x fp128> %a,<3 x fp128> %b)
 store <3 x fp128> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_fp_extrema_128_3_0_1(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <3 x fp128>,ptr %a_ptr,align 1
 %b = load <3 x fp128>,ptr %b_ptr,align 1
 %result = call <3 x fp128> @llvm.minnum.v3f128(<3 x fp128> %a,<3 x fp128> %b)
 store <3 x fp128> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <3 x fp128> @llvm.maxnum.v3f128(<3 x fp128>,<3 x fp128>)
define i64 @vector_fp_extrema_128_3_1_0(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <3 x fp128>,ptr %a_ptr,align 1
 %b = load <3 x fp128>,ptr %b_ptr,align 1
 %result = call <3 x fp128> @llvm.maxnum.v3f128(<3 x fp128> %a,<3 x fp128> %b)
 store <3 x fp128> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_fp_extrema_128_3_1_1(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <3 x fp128>,ptr %a_ptr,align 1
 %b = load <3 x fp128>,ptr %b_ptr,align 1
 %result = call <3 x fp128> @llvm.maxnum.v3f128(<3 x fp128> %a,<3 x fp128> %b)
 store <3 x fp128> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x fp128> @llvm.minnum.v4f128(<4 x fp128>,<4 x fp128>)
define i64 @vector_fp_extrema_128_4_0_0(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <4 x fp128>,ptr %a_ptr,align 1
 %b = load <4 x fp128>,ptr %b_ptr,align 1
 %result = call <4 x fp128> @llvm.minnum.v4f128(<4 x fp128> %a,<4 x fp128> %b)
 store <4 x fp128> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_fp_extrema_128_4_0_1(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <4 x fp128>,ptr %a_ptr,align 1
 %b = load <4 x fp128>,ptr %b_ptr,align 1
 %result = call <4 x fp128> @llvm.minnum.v4f128(<4 x fp128> %a,<4 x fp128> %b)
 store <4 x fp128> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare <4 x fp128> @llvm.maxnum.v4f128(<4 x fp128>,<4 x fp128>)
define i64 @vector_fp_extrema_128_4_1_0(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <4 x fp128>,ptr %a_ptr,align 1
 %b = load <4 x fp128>,ptr %b_ptr,align 1
 %result = call <4 x fp128> @llvm.maxnum.v4f128(<4 x fp128> %a,<4 x fp128> %b)
 store <4 x fp128> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i64 @vector_fp_extrema_128_4_1_1(ptr %out,ptr %a_ptr,ptr %b_ptr,i64 %salt) noinline {
entry:
 %a = load <4 x fp128>,ptr %a_ptr,align 1
 %b = load <4 x fp128>,ptr %b_ptr,align 1
 %result = call <4 x fp128> @llvm.maxnum.v4f128(<4 x fp128> %a,<4 x fp128> %b)
 store <4 x fp128> %result,ptr %out,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
