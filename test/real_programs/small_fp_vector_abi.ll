target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
define <1 x half> @small_fp_body_1_16_c(<1 x half> %a,<1 x half> %b) noinline {
entry:
 %r = shufflevector <1 x half> %a,<1 x half> %b,<1 x i32> <i32 1>
 ret <1 x half> %r
}
declare <1 x half> @small_fp_provider_1_16_c(<1 x half>,<1 x half>)
define i64 @small_fp_probe_1_16_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <1 x half>,ptr %ap,align 1
 %b = load <1 x half>,ptr %bp,align 1
 %local = call <1 x half> @small_fp_body_1_16_c(<1 x half> %a,<1 x half> %b)
 %external = call <1 x half> @small_fp_provider_1_16_c(<1 x half> %a,<1 x half> %b)
 store <1 x half> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <1 x half> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <1 x half> @small_fp_body_1_16_fast(<1 x half> %a,<1 x half> %b) noinline {
entry:
 %r = shufflevector <1 x half> %a,<1 x half> %b,<1 x i32> <i32 1>
 ret <1 x half> %r
}
declare fastcc <1 x half> @small_fp_provider_1_16_fast(<1 x half>,<1 x half>)
define i64 @small_fp_probe_1_16_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <1 x half>,ptr %ap,align 1
 %b = load <1 x half>,ptr %bp,align 1
 %local = call fastcc <1 x half> @small_fp_body_1_16_fast(<1 x half> %a,<1 x half> %b)
 %external = call fastcc <1 x half> @small_fp_provider_1_16_fast(<1 x half> %a,<1 x half> %b)
 store <1 x half> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <1 x half> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x half> @small_fp_body_2_16_c(<2 x half> %a,<2 x half> %b) noinline {
entry:
 %r = shufflevector <2 x half> %a,<2 x half> %b,<2 x i32> <i32 3,i32 0>
 ret <2 x half> %r
}
declare <2 x half> @small_fp_provider_2_16_c(<2 x half>,<2 x half>)
define i64 @small_fp_probe_2_16_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x half>,ptr %ap,align 1
 %b = load <2 x half>,ptr %bp,align 1
 %local = call <2 x half> @small_fp_body_2_16_c(<2 x half> %a,<2 x half> %b)
 %external = call <2 x half> @small_fp_provider_2_16_c(<2 x half> %a,<2 x half> %b)
 store <2 x half> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x half> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x half> @small_fp_body_2_16_fast(<2 x half> %a,<2 x half> %b) noinline {
entry:
 %r = shufflevector <2 x half> %a,<2 x half> %b,<2 x i32> <i32 3,i32 0>
 ret <2 x half> %r
}
declare fastcc <2 x half> @small_fp_provider_2_16_fast(<2 x half>,<2 x half>)
define i64 @small_fp_probe_2_16_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x half>,ptr %ap,align 1
 %b = load <2 x half>,ptr %bp,align 1
 %local = call fastcc <2 x half> @small_fp_body_2_16_fast(<2 x half> %a,<2 x half> %b)
 %external = call fastcc <2 x half> @small_fp_provider_2_16_fast(<2 x half> %a,<2 x half> %b)
 store <2 x half> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x half> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <4 x half> @small_fp_body_4_16_c(<4 x half> %a,<4 x half> %b) noinline {
entry:
 %r = shufflevector <4 x half> %a,<4 x half> %b,<4 x i32> <i32 7,i32 2,i32 5,i32 0>
 ret <4 x half> %r
}
declare <4 x half> @small_fp_provider_4_16_c(<4 x half>,<4 x half>)
define i64 @small_fp_probe_4_16_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x half>,ptr %ap,align 1
 %b = load <4 x half>,ptr %bp,align 1
 %local = call <4 x half> @small_fp_body_4_16_c(<4 x half> %a,<4 x half> %b)
 %external = call <4 x half> @small_fp_provider_4_16_c(<4 x half> %a,<4 x half> %b)
 store <4 x half> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x half> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <4 x half> @small_fp_body_4_16_fast(<4 x half> %a,<4 x half> %b) noinline {
entry:
 %r = shufflevector <4 x half> %a,<4 x half> %b,<4 x i32> <i32 7,i32 2,i32 5,i32 0>
 ret <4 x half> %r
}
declare fastcc <4 x half> @small_fp_provider_4_16_fast(<4 x half>,<4 x half>)
define i64 @small_fp_probe_4_16_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x half>,ptr %ap,align 1
 %b = load <4 x half>,ptr %bp,align 1
 %local = call fastcc <4 x half> @small_fp_body_4_16_fast(<4 x half> %a,<4 x half> %b)
 %external = call fastcc <4 x half> @small_fp_provider_4_16_fast(<4 x half> %a,<4 x half> %b)
 store <4 x half> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x half> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <8 x half> @small_fp_body_8_16_c(<8 x half> %a,<8 x half> %b) noinline {
entry:
 %r = shufflevector <8 x half> %a,<8 x half> %b,<8 x i32> <i32 15,i32 6,i32 13,i32 4,i32 11,i32 2,i32 9,i32 0>
 ret <8 x half> %r
}
declare <8 x half> @small_fp_provider_8_16_c(<8 x half>,<8 x half>)
define i64 @small_fp_probe_8_16_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <8 x half>,ptr %ap,align 1
 %b = load <8 x half>,ptr %bp,align 1
 %local = call <8 x half> @small_fp_body_8_16_c(<8 x half> %a,<8 x half> %b)
 %external = call <8 x half> @small_fp_provider_8_16_c(<8 x half> %a,<8 x half> %b)
 store <8 x half> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <8 x half> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <8 x half> @small_fp_body_8_16_fast(<8 x half> %a,<8 x half> %b) noinline {
entry:
 %r = shufflevector <8 x half> %a,<8 x half> %b,<8 x i32> <i32 15,i32 6,i32 13,i32 4,i32 11,i32 2,i32 9,i32 0>
 ret <8 x half> %r
}
declare fastcc <8 x half> @small_fp_provider_8_16_fast(<8 x half>,<8 x half>)
define i64 @small_fp_probe_8_16_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <8 x half>,ptr %ap,align 1
 %b = load <8 x half>,ptr %bp,align 1
 %local = call fastcc <8 x half> @small_fp_body_8_16_fast(<8 x half> %a,<8 x half> %b)
 %external = call fastcc <8 x half> @small_fp_provider_8_16_fast(<8 x half> %a,<8 x half> %b)
 store <8 x half> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <8 x half> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <1 x float> @small_fp_body_1_32_c(<1 x float> %a,<1 x float> %b) noinline {
entry:
 %r = shufflevector <1 x float> %a,<1 x float> %b,<1 x i32> <i32 1>
 ret <1 x float> %r
}
declare <1 x float> @small_fp_provider_1_32_c(<1 x float>,<1 x float>)
define i64 @small_fp_probe_1_32_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <1 x float>,ptr %ap,align 1
 %b = load <1 x float>,ptr %bp,align 1
 %local = call <1 x float> @small_fp_body_1_32_c(<1 x float> %a,<1 x float> %b)
 %external = call <1 x float> @small_fp_provider_1_32_c(<1 x float> %a,<1 x float> %b)
 store <1 x float> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <1 x float> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <1 x float> @small_fp_body_1_32_fast(<1 x float> %a,<1 x float> %b) noinline {
entry:
 %r = shufflevector <1 x float> %a,<1 x float> %b,<1 x i32> <i32 1>
 ret <1 x float> %r
}
declare fastcc <1 x float> @small_fp_provider_1_32_fast(<1 x float>,<1 x float>)
define i64 @small_fp_probe_1_32_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <1 x float>,ptr %ap,align 1
 %b = load <1 x float>,ptr %bp,align 1
 %local = call fastcc <1 x float> @small_fp_body_1_32_fast(<1 x float> %a,<1 x float> %b)
 %external = call fastcc <1 x float> @small_fp_provider_1_32_fast(<1 x float> %a,<1 x float> %b)
 store <1 x float> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <1 x float> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <3 x float> @small_fp_body_3_32_c(<3 x float> %a,<3 x float> %b) noinline {
entry:
 %r = shufflevector <3 x float> %a,<3 x float> %b,<3 x i32> <i32 5,i32 1,i32 3>
 ret <3 x float> %r
}
declare <3 x float> @small_fp_provider_3_32_c(<3 x float>,<3 x float>)
define i64 @small_fp_probe_3_32_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <3 x float>,ptr %ap,align 1
 %b = load <3 x float>,ptr %bp,align 1
 %local = call <3 x float> @small_fp_body_3_32_c(<3 x float> %a,<3 x float> %b)
 %external = call <3 x float> @small_fp_provider_3_32_c(<3 x float> %a,<3 x float> %b)
 store <3 x float> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <3 x float> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <3 x float> @small_fp_body_3_32_fast(<3 x float> %a,<3 x float> %b) noinline {
entry:
 %r = shufflevector <3 x float> %a,<3 x float> %b,<3 x i32> <i32 5,i32 1,i32 3>
 ret <3 x float> %r
}
declare fastcc <3 x float> @small_fp_provider_3_32_fast(<3 x float>,<3 x float>)
define i64 @small_fp_probe_3_32_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <3 x float>,ptr %ap,align 1
 %b = load <3 x float>,ptr %bp,align 1
 %local = call fastcc <3 x float> @small_fp_body_3_32_fast(<3 x float> %a,<3 x float> %b)
 %external = call fastcc <3 x float> @small_fp_provider_3_32_fast(<3 x float> %a,<3 x float> %b)
 store <3 x float> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <3 x float> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <1 x double> @small_fp_body_1_64_c(<1 x double> %a,<1 x double> %b) noinline {
entry:
 %r = shufflevector <1 x double> %a,<1 x double> %b,<1 x i32> <i32 1>
 ret <1 x double> %r
}
declare <1 x double> @small_fp_provider_1_64_c(<1 x double>,<1 x double>)
define i64 @small_fp_probe_1_64_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <1 x double>,ptr %ap,align 1
 %b = load <1 x double>,ptr %bp,align 1
 %local = call <1 x double> @small_fp_body_1_64_c(<1 x double> %a,<1 x double> %b)
 %external = call <1 x double> @small_fp_provider_1_64_c(<1 x double> %a,<1 x double> %b)
 store <1 x double> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <1 x double> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <1 x double> @small_fp_body_1_64_fast(<1 x double> %a,<1 x double> %b) noinline {
entry:
 %r = shufflevector <1 x double> %a,<1 x double> %b,<1 x i32> <i32 1>
 ret <1 x double> %r
}
declare fastcc <1 x double> @small_fp_provider_1_64_fast(<1 x double>,<1 x double>)
define i64 @small_fp_probe_1_64_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <1 x double>,ptr %ap,align 1
 %b = load <1 x double>,ptr %bp,align 1
 %local = call fastcc <1 x double> @small_fp_body_1_64_fast(<1 x double> %a,<1 x double> %b)
 %external = call fastcc <1 x double> @small_fp_provider_1_64_fast(<1 x double> %a,<1 x double> %b)
 store <1 x double> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <1 x double> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x float> @small_fp_body_2_32_c(<2 x float> %a,<2 x float> %b) noinline {
entry:
 %r = shufflevector <2 x float> %a,<2 x float> %b,<2 x i32> <i32 3,i32 0>
 ret <2 x float> %r
}
declare <2 x float> @small_fp_provider_2_32_c(<2 x float>,<2 x float>)
define i64 @small_fp_probe_2_32_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x float>,ptr %ap,align 1
 %b = load <2 x float>,ptr %bp,align 1
 %local = call <2 x float> @small_fp_body_2_32_c(<2 x float> %a,<2 x float> %b)
 %external = call <2 x float> @small_fp_provider_2_32_c(<2 x float> %a,<2 x float> %b)
 store <2 x float> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x float> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x float> @small_fp_body_2_32_fast(<2 x float> %a,<2 x float> %b) noinline {
entry:
 %r = shufflevector <2 x float> %a,<2 x float> %b,<2 x i32> <i32 3,i32 0>
 ret <2 x float> %r
}
declare fastcc <2 x float> @small_fp_provider_2_32_fast(<2 x float>,<2 x float>)
define i64 @small_fp_probe_2_32_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x float>,ptr %ap,align 1
 %b = load <2 x float>,ptr %bp,align 1
 %local = call fastcc <2 x float> @small_fp_body_2_32_fast(<2 x float> %a,<2 x float> %b)
 %external = call fastcc <2 x float> @small_fp_provider_2_32_fast(<2 x float> %a,<2 x float> %b)
 store <2 x float> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x float> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
