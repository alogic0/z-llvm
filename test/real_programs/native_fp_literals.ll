target triple = "x86_64-unknown-linux-gnu"
define half @fp_literal_body_16_0_c(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret half 0xH0000
no:
 ret half 0xH8000
}
declare half @fp_literal_provider_16_0_c(i1)
define i64 @fp_literal_probe_16_0_c(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call half @fp_literal_body_16_0_c(i1 %take,i64 %salt,ptr %effect)
 %external = call half @fp_literal_provider_16_0_c(i1 %take)
 store half %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store half %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc half @fp_literal_body_16_0_fast(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret half 0xH0000
no:
 ret half 0xH8000
}
declare half @fp_literal_provider_16_0_fast(i1)
define i64 @fp_literal_probe_16_0_fast(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call fastcc half @fp_literal_body_16_0_fast(i1 %take,i64 %salt,ptr %effect)
 %external = call half @fp_literal_provider_16_0_fast(i1 %take)
 store half %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store half %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define half @fp_literal_body_16_1_c(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret half 0xH8000
no:
 ret half 0xH8000
}
declare half @fp_literal_provider_16_1_c(i1)
define i64 @fp_literal_probe_16_1_c(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call half @fp_literal_body_16_1_c(i1 %take,i64 %salt,ptr %effect)
 %external = call half @fp_literal_provider_16_1_c(i1 %take)
 store half %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store half %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc half @fp_literal_body_16_1_fast(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret half 0xH8000
no:
 ret half 0xH8000
}
declare half @fp_literal_provider_16_1_fast(i1)
define i64 @fp_literal_probe_16_1_fast(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call fastcc half @fp_literal_body_16_1_fast(i1 %take,i64 %salt,ptr %effect)
 %external = call half @fp_literal_provider_16_1_fast(i1 %take)
 store half %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store half %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define half @fp_literal_body_16_2_c(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret half 0xH0001
no:
 ret half 0xH8000
}
declare half @fp_literal_provider_16_2_c(i1)
define i64 @fp_literal_probe_16_2_c(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call half @fp_literal_body_16_2_c(i1 %take,i64 %salt,ptr %effect)
 %external = call half @fp_literal_provider_16_2_c(i1 %take)
 store half %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store half %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc half @fp_literal_body_16_2_fast(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret half 0xH0001
no:
 ret half 0xH8000
}
declare half @fp_literal_provider_16_2_fast(i1)
define i64 @fp_literal_probe_16_2_fast(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call fastcc half @fp_literal_body_16_2_fast(i1 %take,i64 %salt,ptr %effect)
 %external = call half @fp_literal_provider_16_2_fast(i1 %take)
 store half %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store half %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define half @fp_literal_body_16_3_c(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret half 0xH7C00
no:
 ret half 0xH8000
}
declare half @fp_literal_provider_16_3_c(i1)
define i64 @fp_literal_probe_16_3_c(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call half @fp_literal_body_16_3_c(i1 %take,i64 %salt,ptr %effect)
 %external = call half @fp_literal_provider_16_3_c(i1 %take)
 store half %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store half %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc half @fp_literal_body_16_3_fast(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret half 0xH7C00
no:
 ret half 0xH8000
}
declare half @fp_literal_provider_16_3_fast(i1)
define i64 @fp_literal_probe_16_3_fast(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call fastcc half @fp_literal_body_16_3_fast(i1 %take,i64 %salt,ptr %effect)
 %external = call half @fp_literal_provider_16_3_fast(i1 %take)
 store half %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store half %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define half @fp_literal_body_16_4_c(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret half 0xH7C01
no:
 ret half 0xH8000
}
declare half @fp_literal_provider_16_4_c(i1)
define i64 @fp_literal_probe_16_4_c(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call half @fp_literal_body_16_4_c(i1 %take,i64 %salt,ptr %effect)
 %external = call half @fp_literal_provider_16_4_c(i1 %take)
 store half %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store half %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc half @fp_literal_body_16_4_fast(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret half 0xH7C01
no:
 ret half 0xH8000
}
declare half @fp_literal_provider_16_4_fast(i1)
define i64 @fp_literal_probe_16_4_fast(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call fastcc half @fp_literal_body_16_4_fast(i1 %take,i64 %salt,ptr %effect)
 %external = call half @fp_literal_provider_16_4_fast(i1 %take)
 store half %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store half %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define half @fp_literal_body_16_5_c(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret half 0xH7E23
no:
 ret half 0xH8000
}
declare half @fp_literal_provider_16_5_c(i1)
define i64 @fp_literal_probe_16_5_c(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call half @fp_literal_body_16_5_c(i1 %take,i64 %salt,ptr %effect)
 %external = call half @fp_literal_provider_16_5_c(i1 %take)
 store half %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store half %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc half @fp_literal_body_16_5_fast(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret half 0xH7E23
no:
 ret half 0xH8000
}
declare half @fp_literal_provider_16_5_fast(i1)
define i64 @fp_literal_probe_16_5_fast(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call fastcc half @fp_literal_body_16_5_fast(i1 %take,i64 %salt,ptr %effect)
 %external = call half @fp_literal_provider_16_5_fast(i1 %take)
 store half %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store half %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define half @fp_literal_body_16_6_c(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret half 0xH3555
no:
 ret half 0xH8000
}
declare half @fp_literal_provider_16_6_c(i1)
define i64 @fp_literal_probe_16_6_c(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call half @fp_literal_body_16_6_c(i1 %take,i64 %salt,ptr %effect)
 %external = call half @fp_literal_provider_16_6_c(i1 %take)
 store half %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store half %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc half @fp_literal_body_16_6_fast(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret half 0xH3555
no:
 ret half 0xH8000
}
declare half @fp_literal_provider_16_6_fast(i1)
define i64 @fp_literal_probe_16_6_fast(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call fastcc half @fp_literal_body_16_6_fast(i1 %take,i64 %salt,ptr %effect)
 %external = call half @fp_literal_provider_16_6_fast(i1 %take)
 store half %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store half %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define float @fp_literal_body_32_0_c(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret float 0.000000e+00
no:
 ret float -0.000000e+00
}
declare float @fp_literal_provider_32_0_c(i1)
define i64 @fp_literal_probe_32_0_c(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call float @fp_literal_body_32_0_c(i1 %take,i64 %salt,ptr %effect)
 %external = call float @fp_literal_provider_32_0_c(i1 %take)
 store float %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store float %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc float @fp_literal_body_32_0_fast(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret float 0.000000e+00
no:
 ret float -0.000000e+00
}
declare float @fp_literal_provider_32_0_fast(i1)
define i64 @fp_literal_probe_32_0_fast(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call fastcc float @fp_literal_body_32_0_fast(i1 %take,i64 %salt,ptr %effect)
 %external = call float @fp_literal_provider_32_0_fast(i1 %take)
 store float %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store float %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define float @fp_literal_body_32_1_c(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret float -0.000000e+00
no:
 ret float -0.000000e+00
}
declare float @fp_literal_provider_32_1_c(i1)
define i64 @fp_literal_probe_32_1_c(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call float @fp_literal_body_32_1_c(i1 %take,i64 %salt,ptr %effect)
 %external = call float @fp_literal_provider_32_1_c(i1 %take)
 store float %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store float %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc float @fp_literal_body_32_1_fast(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret float -0.000000e+00
no:
 ret float -0.000000e+00
}
declare float @fp_literal_provider_32_1_fast(i1)
define i64 @fp_literal_probe_32_1_fast(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call fastcc float @fp_literal_body_32_1_fast(i1 %take,i64 %salt,ptr %effect)
 %external = call float @fp_literal_provider_32_1_fast(i1 %take)
 store float %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store float %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define float @fp_literal_body_32_2_c(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret float 0x36A0000000000000
no:
 ret float -0.000000e+00
}
declare float @fp_literal_provider_32_2_c(i1)
define i64 @fp_literal_probe_32_2_c(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call float @fp_literal_body_32_2_c(i1 %take,i64 %salt,ptr %effect)
 %external = call float @fp_literal_provider_32_2_c(i1 %take)
 store float %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store float %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc float @fp_literal_body_32_2_fast(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret float 0x36A0000000000000
no:
 ret float -0.000000e+00
}
declare float @fp_literal_provider_32_2_fast(i1)
define i64 @fp_literal_probe_32_2_fast(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call fastcc float @fp_literal_body_32_2_fast(i1 %take,i64 %salt,ptr %effect)
 %external = call float @fp_literal_provider_32_2_fast(i1 %take)
 store float %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store float %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define float @fp_literal_body_32_3_c(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret float 0x7FF0000000000000
no:
 ret float -0.000000e+00
}
declare float @fp_literal_provider_32_3_c(i1)
define i64 @fp_literal_probe_32_3_c(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call float @fp_literal_body_32_3_c(i1 %take,i64 %salt,ptr %effect)
 %external = call float @fp_literal_provider_32_3_c(i1 %take)
 store float %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store float %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc float @fp_literal_body_32_3_fast(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret float 0x7FF0000000000000
no:
 ret float -0.000000e+00
}
declare float @fp_literal_provider_32_3_fast(i1)
define i64 @fp_literal_probe_32_3_fast(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call fastcc float @fp_literal_body_32_3_fast(i1 %take,i64 %salt,ptr %effect)
 %external = call float @fp_literal_provider_32_3_fast(i1 %take)
 store float %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store float %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define float @fp_literal_body_32_4_c(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret float 0x7FF0000020000000
no:
 ret float -0.000000e+00
}
declare float @fp_literal_provider_32_4_c(i1)
define i64 @fp_literal_probe_32_4_c(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call float @fp_literal_body_32_4_c(i1 %take,i64 %salt,ptr %effect)
 %external = call float @fp_literal_provider_32_4_c(i1 %take)
 store float %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store float %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc float @fp_literal_body_32_4_fast(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret float 0x7FF0000020000000
no:
 ret float -0.000000e+00
}
declare float @fp_literal_provider_32_4_fast(i1)
define i64 @fp_literal_probe_32_4_fast(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call fastcc float @fp_literal_body_32_4_fast(i1 %take,i64 %salt,ptr %effect)
 %external = call float @fp_literal_provider_32_4_fast(i1 %take)
 store float %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store float %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define float @fp_literal_body_32_5_c(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret float 0x7FF8002460000000
no:
 ret float -0.000000e+00
}
declare float @fp_literal_provider_32_5_c(i1)
define i64 @fp_literal_probe_32_5_c(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call float @fp_literal_body_32_5_c(i1 %take,i64 %salt,ptr %effect)
 %external = call float @fp_literal_provider_32_5_c(i1 %take)
 store float %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store float %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc float @fp_literal_body_32_5_fast(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret float 0x7FF8002460000000
no:
 ret float -0.000000e+00
}
declare float @fp_literal_provider_32_5_fast(i1)
define i64 @fp_literal_probe_32_5_fast(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call fastcc float @fp_literal_body_32_5_fast(i1 %take,i64 %salt,ptr %effect)
 %external = call float @fp_literal_provider_32_5_fast(i1 %take)
 store float %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store float %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define float @fp_literal_body_32_6_c(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret float 0x3FD5555560000000
no:
 ret float -0.000000e+00
}
declare float @fp_literal_provider_32_6_c(i1)
define i64 @fp_literal_probe_32_6_c(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call float @fp_literal_body_32_6_c(i1 %take,i64 %salt,ptr %effect)
 %external = call float @fp_literal_provider_32_6_c(i1 %take)
 store float %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store float %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc float @fp_literal_body_32_6_fast(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret float 0x3FD5555560000000
no:
 ret float -0.000000e+00
}
declare float @fp_literal_provider_32_6_fast(i1)
define i64 @fp_literal_probe_32_6_fast(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call fastcc float @fp_literal_body_32_6_fast(i1 %take,i64 %salt,ptr %effect)
 %external = call float @fp_literal_provider_32_6_fast(i1 %take)
 store float %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store float %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define double @fp_literal_body_64_0_c(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret double 0x0000000000000000
no:
 ret double 0x8000000000000000
}
declare double @fp_literal_provider_64_0_c(i1)
define i64 @fp_literal_probe_64_0_c(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call double @fp_literal_body_64_0_c(i1 %take,i64 %salt,ptr %effect)
 %external = call double @fp_literal_provider_64_0_c(i1 %take)
 store double %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store double %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc double @fp_literal_body_64_0_fast(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret double 0x0000000000000000
no:
 ret double 0x8000000000000000
}
declare double @fp_literal_provider_64_0_fast(i1)
define i64 @fp_literal_probe_64_0_fast(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call fastcc double @fp_literal_body_64_0_fast(i1 %take,i64 %salt,ptr %effect)
 %external = call double @fp_literal_provider_64_0_fast(i1 %take)
 store double %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store double %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define double @fp_literal_body_64_1_c(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret double 0x8000000000000000
no:
 ret double 0x8000000000000000
}
declare double @fp_literal_provider_64_1_c(i1)
define i64 @fp_literal_probe_64_1_c(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call double @fp_literal_body_64_1_c(i1 %take,i64 %salt,ptr %effect)
 %external = call double @fp_literal_provider_64_1_c(i1 %take)
 store double %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store double %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc double @fp_literal_body_64_1_fast(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret double 0x8000000000000000
no:
 ret double 0x8000000000000000
}
declare double @fp_literal_provider_64_1_fast(i1)
define i64 @fp_literal_probe_64_1_fast(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call fastcc double @fp_literal_body_64_1_fast(i1 %take,i64 %salt,ptr %effect)
 %external = call double @fp_literal_provider_64_1_fast(i1 %take)
 store double %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store double %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define double @fp_literal_body_64_2_c(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret double 0x0000000000000001
no:
 ret double 0x8000000000000000
}
declare double @fp_literal_provider_64_2_c(i1)
define i64 @fp_literal_probe_64_2_c(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call double @fp_literal_body_64_2_c(i1 %take,i64 %salt,ptr %effect)
 %external = call double @fp_literal_provider_64_2_c(i1 %take)
 store double %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store double %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc double @fp_literal_body_64_2_fast(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret double 0x0000000000000001
no:
 ret double 0x8000000000000000
}
declare double @fp_literal_provider_64_2_fast(i1)
define i64 @fp_literal_probe_64_2_fast(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call fastcc double @fp_literal_body_64_2_fast(i1 %take,i64 %salt,ptr %effect)
 %external = call double @fp_literal_provider_64_2_fast(i1 %take)
 store double %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store double %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define double @fp_literal_body_64_3_c(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret double 0x7FF0000000000000
no:
 ret double 0x8000000000000000
}
declare double @fp_literal_provider_64_3_c(i1)
define i64 @fp_literal_probe_64_3_c(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call double @fp_literal_body_64_3_c(i1 %take,i64 %salt,ptr %effect)
 %external = call double @fp_literal_provider_64_3_c(i1 %take)
 store double %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store double %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc double @fp_literal_body_64_3_fast(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret double 0x7FF0000000000000
no:
 ret double 0x8000000000000000
}
declare double @fp_literal_provider_64_3_fast(i1)
define i64 @fp_literal_probe_64_3_fast(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call fastcc double @fp_literal_body_64_3_fast(i1 %take,i64 %salt,ptr %effect)
 %external = call double @fp_literal_provider_64_3_fast(i1 %take)
 store double %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store double %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define double @fp_literal_body_64_4_c(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret double 0x7FF0000000000001
no:
 ret double 0x8000000000000000
}
declare double @fp_literal_provider_64_4_c(i1)
define i64 @fp_literal_probe_64_4_c(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call double @fp_literal_body_64_4_c(i1 %take,i64 %salt,ptr %effect)
 %external = call double @fp_literal_provider_64_4_c(i1 %take)
 store double %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store double %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc double @fp_literal_body_64_4_fast(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret double 0x7FF0000000000001
no:
 ret double 0x8000000000000000
}
declare double @fp_literal_provider_64_4_fast(i1)
define i64 @fp_literal_probe_64_4_fast(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call fastcc double @fp_literal_body_64_4_fast(i1 %take,i64 %salt,ptr %effect)
 %external = call double @fp_literal_provider_64_4_fast(i1 %take)
 store double %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store double %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define double @fp_literal_body_64_5_c(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret double 0x7FF8000000000123
no:
 ret double 0x8000000000000000
}
declare double @fp_literal_provider_64_5_c(i1)
define i64 @fp_literal_probe_64_5_c(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call double @fp_literal_body_64_5_c(i1 %take,i64 %salt,ptr %effect)
 %external = call double @fp_literal_provider_64_5_c(i1 %take)
 store double %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store double %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc double @fp_literal_body_64_5_fast(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret double 0x7FF8000000000123
no:
 ret double 0x8000000000000000
}
declare double @fp_literal_provider_64_5_fast(i1)
define i64 @fp_literal_probe_64_5_fast(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call fastcc double @fp_literal_body_64_5_fast(i1 %take,i64 %salt,ptr %effect)
 %external = call double @fp_literal_provider_64_5_fast(i1 %take)
 store double %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store double %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define double @fp_literal_body_64_6_c(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret double 0x3FD5555555555555
no:
 ret double 0x8000000000000000
}
declare double @fp_literal_provider_64_6_c(i1)
define i64 @fp_literal_probe_64_6_c(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call double @fp_literal_body_64_6_c(i1 %take,i64 %salt,ptr %effect)
 %external = call double @fp_literal_provider_64_6_c(i1 %take)
 store double %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store double %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc double @fp_literal_body_64_6_fast(i1 %choice,i64 %salt,ptr %effect) noinline {
entry:
 store volatile i64 %salt,ptr %effect,align 1
 br i1 %choice,label %yes,label %no
yes:
 ret double 0x3FD5555555555555
no:
 ret double 0x8000000000000000
}
declare double @fp_literal_provider_64_6_fast(i1)
define i64 @fp_literal_probe_64_6_fast(ptr %out,ptr %effect,i64 %choice,i64 %salt) {
entry:
 %take = trunc i64 %choice to i1
 %local = call fastcc double @fp_literal_body_64_6_fast(i1 %take,i64 %salt,ptr %effect)
 %external = call double @fp_literal_provider_64_6_fast(i1 %take)
 store double %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store double %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
