target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
define <16 x i1> @promoted_body_16_1_c(<16 x i1> %a,<16 x i1> %b) noinline {
entry:
 %r = add <16 x i1> %a,%b
 ret <16 x i1> %r
}
declare <16 x i1> @promoted_provider_16_1_c(<16 x i1>,<16 x i1>)
define i64 @promoted_probe_16_1_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <16 x i1>,ptr %ap,align 1
 %b = load <16 x i1>,ptr %bp,align 1
 %local = call <16 x i1> @promoted_body_16_1_c(<16 x i1> %a,<16 x i1> %b)
 %external = call <16 x i1> @promoted_provider_16_1_c(<16 x i1> %a,<16 x i1> %b)
 store <16 x i1> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <16 x i1> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <16 x i1> @promoted_body_16_1_fast(<16 x i1> %a,<16 x i1> %b) noinline {
entry:
 %r = add <16 x i1> %a,%b
 ret <16 x i1> %r
}
declare fastcc <16 x i1> @promoted_provider_16_1_fast(<16 x i1>,<16 x i1>)
define i64 @promoted_probe_16_1_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <16 x i1>,ptr %ap,align 1
 %b = load <16 x i1>,ptr %bp,align 1
 %local = call fastcc <16 x i1> @promoted_body_16_1_fast(<16 x i1> %a,<16 x i1> %b)
 %external = call fastcc <16 x i1> @promoted_provider_16_1_fast(<16 x i1> %a,<16 x i1> %b)
 store <16 x i1> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <16 x i1> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <16 x i2> @promoted_body_16_2_c(<16 x i2> %a,<16 x i2> %b) noinline {
entry:
 %r = add <16 x i2> %a,%b
 ret <16 x i2> %r
}
declare <16 x i2> @promoted_provider_16_2_c(<16 x i2>,<16 x i2>)
define i64 @promoted_probe_16_2_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <16 x i2>,ptr %ap,align 1
 %b = load <16 x i2>,ptr %bp,align 1
 %local = call <16 x i2> @promoted_body_16_2_c(<16 x i2> %a,<16 x i2> %b)
 %external = call <16 x i2> @promoted_provider_16_2_c(<16 x i2> %a,<16 x i2> %b)
 store <16 x i2> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <16 x i2> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <16 x i2> @promoted_body_16_2_fast(<16 x i2> %a,<16 x i2> %b) noinline {
entry:
 %r = add <16 x i2> %a,%b
 ret <16 x i2> %r
}
declare fastcc <16 x i2> @promoted_provider_16_2_fast(<16 x i2>,<16 x i2>)
define i64 @promoted_probe_16_2_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <16 x i2>,ptr %ap,align 1
 %b = load <16 x i2>,ptr %bp,align 1
 %local = call fastcc <16 x i2> @promoted_body_16_2_fast(<16 x i2> %a,<16 x i2> %b)
 %external = call fastcc <16 x i2> @promoted_provider_16_2_fast(<16 x i2> %a,<16 x i2> %b)
 store <16 x i2> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <16 x i2> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <16 x i3> @promoted_body_16_3_c(<16 x i3> %a,<16 x i3> %b) noinline {
entry:
 %r = add <16 x i3> %a,%b
 ret <16 x i3> %r
}
declare <16 x i3> @promoted_provider_16_3_c(<16 x i3>,<16 x i3>)
define i64 @promoted_probe_16_3_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <16 x i3>,ptr %ap,align 1
 %b = load <16 x i3>,ptr %bp,align 1
 %local = call <16 x i3> @promoted_body_16_3_c(<16 x i3> %a,<16 x i3> %b)
 %external = call <16 x i3> @promoted_provider_16_3_c(<16 x i3> %a,<16 x i3> %b)
 store <16 x i3> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <16 x i3> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <16 x i3> @promoted_body_16_3_fast(<16 x i3> %a,<16 x i3> %b) noinline {
entry:
 %r = add <16 x i3> %a,%b
 ret <16 x i3> %r
}
declare fastcc <16 x i3> @promoted_provider_16_3_fast(<16 x i3>,<16 x i3>)
define i64 @promoted_probe_16_3_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <16 x i3>,ptr %ap,align 1
 %b = load <16 x i3>,ptr %bp,align 1
 %local = call fastcc <16 x i3> @promoted_body_16_3_fast(<16 x i3> %a,<16 x i3> %b)
 %external = call fastcc <16 x i3> @promoted_provider_16_3_fast(<16 x i3> %a,<16 x i3> %b)
 store <16 x i3> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <16 x i3> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <16 x i4> @promoted_body_16_4_c(<16 x i4> %a,<16 x i4> %b) noinline {
entry:
 %r = add <16 x i4> %a,%b
 ret <16 x i4> %r
}
declare <16 x i4> @promoted_provider_16_4_c(<16 x i4>,<16 x i4>)
define i64 @promoted_probe_16_4_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <16 x i4>,ptr %ap,align 1
 %b = load <16 x i4>,ptr %bp,align 1
 %local = call <16 x i4> @promoted_body_16_4_c(<16 x i4> %a,<16 x i4> %b)
 %external = call <16 x i4> @promoted_provider_16_4_c(<16 x i4> %a,<16 x i4> %b)
 store <16 x i4> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <16 x i4> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <16 x i4> @promoted_body_16_4_fast(<16 x i4> %a,<16 x i4> %b) noinline {
entry:
 %r = add <16 x i4> %a,%b
 ret <16 x i4> %r
}
declare fastcc <16 x i4> @promoted_provider_16_4_fast(<16 x i4>,<16 x i4>)
define i64 @promoted_probe_16_4_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <16 x i4>,ptr %ap,align 1
 %b = load <16 x i4>,ptr %bp,align 1
 %local = call fastcc <16 x i4> @promoted_body_16_4_fast(<16 x i4> %a,<16 x i4> %b)
 %external = call fastcc <16 x i4> @promoted_provider_16_4_fast(<16 x i4> %a,<16 x i4> %b)
 store <16 x i4> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <16 x i4> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <16 x i5> @promoted_body_16_5_c(<16 x i5> %a,<16 x i5> %b) noinline {
entry:
 %r = add <16 x i5> %a,%b
 ret <16 x i5> %r
}
declare <16 x i5> @promoted_provider_16_5_c(<16 x i5>,<16 x i5>)
define i64 @promoted_probe_16_5_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <16 x i5>,ptr %ap,align 1
 %b = load <16 x i5>,ptr %bp,align 1
 %local = call <16 x i5> @promoted_body_16_5_c(<16 x i5> %a,<16 x i5> %b)
 %external = call <16 x i5> @promoted_provider_16_5_c(<16 x i5> %a,<16 x i5> %b)
 store <16 x i5> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <16 x i5> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <16 x i5> @promoted_body_16_5_fast(<16 x i5> %a,<16 x i5> %b) noinline {
entry:
 %r = add <16 x i5> %a,%b
 ret <16 x i5> %r
}
declare fastcc <16 x i5> @promoted_provider_16_5_fast(<16 x i5>,<16 x i5>)
define i64 @promoted_probe_16_5_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <16 x i5>,ptr %ap,align 1
 %b = load <16 x i5>,ptr %bp,align 1
 %local = call fastcc <16 x i5> @promoted_body_16_5_fast(<16 x i5> %a,<16 x i5> %b)
 %external = call fastcc <16 x i5> @promoted_provider_16_5_fast(<16 x i5> %a,<16 x i5> %b)
 store <16 x i5> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <16 x i5> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <16 x i6> @promoted_body_16_6_c(<16 x i6> %a,<16 x i6> %b) noinline {
entry:
 %r = add <16 x i6> %a,%b
 ret <16 x i6> %r
}
declare <16 x i6> @promoted_provider_16_6_c(<16 x i6>,<16 x i6>)
define i64 @promoted_probe_16_6_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <16 x i6>,ptr %ap,align 1
 %b = load <16 x i6>,ptr %bp,align 1
 %local = call <16 x i6> @promoted_body_16_6_c(<16 x i6> %a,<16 x i6> %b)
 %external = call <16 x i6> @promoted_provider_16_6_c(<16 x i6> %a,<16 x i6> %b)
 store <16 x i6> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <16 x i6> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <16 x i6> @promoted_body_16_6_fast(<16 x i6> %a,<16 x i6> %b) noinline {
entry:
 %r = add <16 x i6> %a,%b
 ret <16 x i6> %r
}
declare fastcc <16 x i6> @promoted_provider_16_6_fast(<16 x i6>,<16 x i6>)
define i64 @promoted_probe_16_6_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <16 x i6>,ptr %ap,align 1
 %b = load <16 x i6>,ptr %bp,align 1
 %local = call fastcc <16 x i6> @promoted_body_16_6_fast(<16 x i6> %a,<16 x i6> %b)
 %external = call fastcc <16 x i6> @promoted_provider_16_6_fast(<16 x i6> %a,<16 x i6> %b)
 store <16 x i6> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <16 x i6> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <16 x i7> @promoted_body_16_7_c(<16 x i7> %a,<16 x i7> %b) noinline {
entry:
 %r = add <16 x i7> %a,%b
 ret <16 x i7> %r
}
declare <16 x i7> @promoted_provider_16_7_c(<16 x i7>,<16 x i7>)
define i64 @promoted_probe_16_7_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <16 x i7>,ptr %ap,align 1
 %b = load <16 x i7>,ptr %bp,align 1
 %local = call <16 x i7> @promoted_body_16_7_c(<16 x i7> %a,<16 x i7> %b)
 %external = call <16 x i7> @promoted_provider_16_7_c(<16 x i7> %a,<16 x i7> %b)
 store <16 x i7> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <16 x i7> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <16 x i7> @promoted_body_16_7_fast(<16 x i7> %a,<16 x i7> %b) noinline {
entry:
 %r = add <16 x i7> %a,%b
 ret <16 x i7> %r
}
declare fastcc <16 x i7> @promoted_provider_16_7_fast(<16 x i7>,<16 x i7>)
define i64 @promoted_probe_16_7_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <16 x i7>,ptr %ap,align 1
 %b = load <16 x i7>,ptr %bp,align 1
 %local = call fastcc <16 x i7> @promoted_body_16_7_fast(<16 x i7> %a,<16 x i7> %b)
 %external = call fastcc <16 x i7> @promoted_provider_16_7_fast(<16 x i7> %a,<16 x i7> %b)
 store <16 x i7> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <16 x i7> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
