target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
define <4 x i1> @promoted_body_4_1_c(<4 x i1> %a,<4 x i1> %b) noinline {
entry:
 %r = add <4 x i1> %a,%b
 ret <4 x i1> %r
}
declare <4 x i1> @promoted_provider_4_1_c(<4 x i1>,<4 x i1>)
define i64 @promoted_probe_4_1_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i1>,ptr %ap,align 1
 %b = load <4 x i1>,ptr %bp,align 1
 %local = call <4 x i1> @promoted_body_4_1_c(<4 x i1> %a,<4 x i1> %b)
 %external = call <4 x i1> @promoted_provider_4_1_c(<4 x i1> %a,<4 x i1> %b)
 store <4 x i1> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i1> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <4 x i1> @promoted_body_4_1_fast(<4 x i1> %a,<4 x i1> %b) noinline {
entry:
 %r = add <4 x i1> %a,%b
 ret <4 x i1> %r
}
declare fastcc <4 x i1> @promoted_provider_4_1_fast(<4 x i1>,<4 x i1>)
define i64 @promoted_probe_4_1_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i1>,ptr %ap,align 1
 %b = load <4 x i1>,ptr %bp,align 1
 %local = call fastcc <4 x i1> @promoted_body_4_1_fast(<4 x i1> %a,<4 x i1> %b)
 %external = call fastcc <4 x i1> @promoted_provider_4_1_fast(<4 x i1> %a,<4 x i1> %b)
 store <4 x i1> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i1> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <4 x i2> @promoted_body_4_2_c(<4 x i2> %a,<4 x i2> %b) noinline {
entry:
 %r = add <4 x i2> %a,%b
 ret <4 x i2> %r
}
declare <4 x i2> @promoted_provider_4_2_c(<4 x i2>,<4 x i2>)
define i64 @promoted_probe_4_2_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i2>,ptr %ap,align 1
 %b = load <4 x i2>,ptr %bp,align 1
 %local = call <4 x i2> @promoted_body_4_2_c(<4 x i2> %a,<4 x i2> %b)
 %external = call <4 x i2> @promoted_provider_4_2_c(<4 x i2> %a,<4 x i2> %b)
 store <4 x i2> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i2> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <4 x i2> @promoted_body_4_2_fast(<4 x i2> %a,<4 x i2> %b) noinline {
entry:
 %r = add <4 x i2> %a,%b
 ret <4 x i2> %r
}
declare fastcc <4 x i2> @promoted_provider_4_2_fast(<4 x i2>,<4 x i2>)
define i64 @promoted_probe_4_2_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i2>,ptr %ap,align 1
 %b = load <4 x i2>,ptr %bp,align 1
 %local = call fastcc <4 x i2> @promoted_body_4_2_fast(<4 x i2> %a,<4 x i2> %b)
 %external = call fastcc <4 x i2> @promoted_provider_4_2_fast(<4 x i2> %a,<4 x i2> %b)
 store <4 x i2> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i2> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <4 x i3> @promoted_body_4_3_c(<4 x i3> %a,<4 x i3> %b) noinline {
entry:
 %r = add <4 x i3> %a,%b
 ret <4 x i3> %r
}
declare <4 x i3> @promoted_provider_4_3_c(<4 x i3>,<4 x i3>)
define i64 @promoted_probe_4_3_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i3>,ptr %ap,align 1
 %b = load <4 x i3>,ptr %bp,align 1
 %local = call <4 x i3> @promoted_body_4_3_c(<4 x i3> %a,<4 x i3> %b)
 %external = call <4 x i3> @promoted_provider_4_3_c(<4 x i3> %a,<4 x i3> %b)
 store <4 x i3> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i3> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <4 x i3> @promoted_body_4_3_fast(<4 x i3> %a,<4 x i3> %b) noinline {
entry:
 %r = add <4 x i3> %a,%b
 ret <4 x i3> %r
}
declare fastcc <4 x i3> @promoted_provider_4_3_fast(<4 x i3>,<4 x i3>)
define i64 @promoted_probe_4_3_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i3>,ptr %ap,align 1
 %b = load <4 x i3>,ptr %bp,align 1
 %local = call fastcc <4 x i3> @promoted_body_4_3_fast(<4 x i3> %a,<4 x i3> %b)
 %external = call fastcc <4 x i3> @promoted_provider_4_3_fast(<4 x i3> %a,<4 x i3> %b)
 store <4 x i3> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i3> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <4 x i4> @promoted_body_4_4_c(<4 x i4> %a,<4 x i4> %b) noinline {
entry:
 %r = add <4 x i4> %a,%b
 ret <4 x i4> %r
}
declare <4 x i4> @promoted_provider_4_4_c(<4 x i4>,<4 x i4>)
define i64 @promoted_probe_4_4_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i4>,ptr %ap,align 1
 %b = load <4 x i4>,ptr %bp,align 1
 %local = call <4 x i4> @promoted_body_4_4_c(<4 x i4> %a,<4 x i4> %b)
 %external = call <4 x i4> @promoted_provider_4_4_c(<4 x i4> %a,<4 x i4> %b)
 store <4 x i4> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i4> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <4 x i4> @promoted_body_4_4_fast(<4 x i4> %a,<4 x i4> %b) noinline {
entry:
 %r = add <4 x i4> %a,%b
 ret <4 x i4> %r
}
declare fastcc <4 x i4> @promoted_provider_4_4_fast(<4 x i4>,<4 x i4>)
define i64 @promoted_probe_4_4_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i4>,ptr %ap,align 1
 %b = load <4 x i4>,ptr %bp,align 1
 %local = call fastcc <4 x i4> @promoted_body_4_4_fast(<4 x i4> %a,<4 x i4> %b)
 %external = call fastcc <4 x i4> @promoted_provider_4_4_fast(<4 x i4> %a,<4 x i4> %b)
 store <4 x i4> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i4> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <4 x i5> @promoted_body_4_5_c(<4 x i5> %a,<4 x i5> %b) noinline {
entry:
 %r = add <4 x i5> %a,%b
 ret <4 x i5> %r
}
declare <4 x i5> @promoted_provider_4_5_c(<4 x i5>,<4 x i5>)
define i64 @promoted_probe_4_5_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i5>,ptr %ap,align 1
 %b = load <4 x i5>,ptr %bp,align 1
 %local = call <4 x i5> @promoted_body_4_5_c(<4 x i5> %a,<4 x i5> %b)
 %external = call <4 x i5> @promoted_provider_4_5_c(<4 x i5> %a,<4 x i5> %b)
 store <4 x i5> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i5> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <4 x i5> @promoted_body_4_5_fast(<4 x i5> %a,<4 x i5> %b) noinline {
entry:
 %r = add <4 x i5> %a,%b
 ret <4 x i5> %r
}
declare fastcc <4 x i5> @promoted_provider_4_5_fast(<4 x i5>,<4 x i5>)
define i64 @promoted_probe_4_5_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i5>,ptr %ap,align 1
 %b = load <4 x i5>,ptr %bp,align 1
 %local = call fastcc <4 x i5> @promoted_body_4_5_fast(<4 x i5> %a,<4 x i5> %b)
 %external = call fastcc <4 x i5> @promoted_provider_4_5_fast(<4 x i5> %a,<4 x i5> %b)
 store <4 x i5> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i5> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <4 x i6> @promoted_body_4_6_c(<4 x i6> %a,<4 x i6> %b) noinline {
entry:
 %r = add <4 x i6> %a,%b
 ret <4 x i6> %r
}
declare <4 x i6> @promoted_provider_4_6_c(<4 x i6>,<4 x i6>)
define i64 @promoted_probe_4_6_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i6>,ptr %ap,align 1
 %b = load <4 x i6>,ptr %bp,align 1
 %local = call <4 x i6> @promoted_body_4_6_c(<4 x i6> %a,<4 x i6> %b)
 %external = call <4 x i6> @promoted_provider_4_6_c(<4 x i6> %a,<4 x i6> %b)
 store <4 x i6> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i6> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <4 x i6> @promoted_body_4_6_fast(<4 x i6> %a,<4 x i6> %b) noinline {
entry:
 %r = add <4 x i6> %a,%b
 ret <4 x i6> %r
}
declare fastcc <4 x i6> @promoted_provider_4_6_fast(<4 x i6>,<4 x i6>)
define i64 @promoted_probe_4_6_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i6>,ptr %ap,align 1
 %b = load <4 x i6>,ptr %bp,align 1
 %local = call fastcc <4 x i6> @promoted_body_4_6_fast(<4 x i6> %a,<4 x i6> %b)
 %external = call fastcc <4 x i6> @promoted_provider_4_6_fast(<4 x i6> %a,<4 x i6> %b)
 store <4 x i6> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i6> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <4 x i7> @promoted_body_4_7_c(<4 x i7> %a,<4 x i7> %b) noinline {
entry:
 %r = add <4 x i7> %a,%b
 ret <4 x i7> %r
}
declare <4 x i7> @promoted_provider_4_7_c(<4 x i7>,<4 x i7>)
define i64 @promoted_probe_4_7_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i7>,ptr %ap,align 1
 %b = load <4 x i7>,ptr %bp,align 1
 %local = call <4 x i7> @promoted_body_4_7_c(<4 x i7> %a,<4 x i7> %b)
 %external = call <4 x i7> @promoted_provider_4_7_c(<4 x i7> %a,<4 x i7> %b)
 store <4 x i7> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i7> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <4 x i7> @promoted_body_4_7_fast(<4 x i7> %a,<4 x i7> %b) noinline {
entry:
 %r = add <4 x i7> %a,%b
 ret <4 x i7> %r
}
declare fastcc <4 x i7> @promoted_provider_4_7_fast(<4 x i7>,<4 x i7>)
define i64 @promoted_probe_4_7_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i7>,ptr %ap,align 1
 %b = load <4 x i7>,ptr %bp,align 1
 %local = call fastcc <4 x i7> @promoted_body_4_7_fast(<4 x i7> %a,<4 x i7> %b)
 %external = call fastcc <4 x i7> @promoted_provider_4_7_fast(<4 x i7> %a,<4 x i7> %b)
 store <4 x i7> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i7> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <4 x i9> @promoted_body_4_9_c(<4 x i9> %a,<4 x i9> %b) noinline {
entry:
 %r = add <4 x i9> %a,%b
 ret <4 x i9> %r
}
declare <4 x i9> @promoted_provider_4_9_c(<4 x i9>,<4 x i9>)
define i64 @promoted_probe_4_9_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i9>,ptr %ap,align 1
 %b = load <4 x i9>,ptr %bp,align 1
 %local = call <4 x i9> @promoted_body_4_9_c(<4 x i9> %a,<4 x i9> %b)
 %external = call <4 x i9> @promoted_provider_4_9_c(<4 x i9> %a,<4 x i9> %b)
 store <4 x i9> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i9> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <4 x i9> @promoted_body_4_9_fast(<4 x i9> %a,<4 x i9> %b) noinline {
entry:
 %r = add <4 x i9> %a,%b
 ret <4 x i9> %r
}
declare fastcc <4 x i9> @promoted_provider_4_9_fast(<4 x i9>,<4 x i9>)
define i64 @promoted_probe_4_9_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i9>,ptr %ap,align 1
 %b = load <4 x i9>,ptr %bp,align 1
 %local = call fastcc <4 x i9> @promoted_body_4_9_fast(<4 x i9> %a,<4 x i9> %b)
 %external = call fastcc <4 x i9> @promoted_provider_4_9_fast(<4 x i9> %a,<4 x i9> %b)
 store <4 x i9> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i9> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <4 x i10> @promoted_body_4_10_c(<4 x i10> %a,<4 x i10> %b) noinline {
entry:
 %r = add <4 x i10> %a,%b
 ret <4 x i10> %r
}
declare <4 x i10> @promoted_provider_4_10_c(<4 x i10>,<4 x i10>)
define i64 @promoted_probe_4_10_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i10>,ptr %ap,align 1
 %b = load <4 x i10>,ptr %bp,align 1
 %local = call <4 x i10> @promoted_body_4_10_c(<4 x i10> %a,<4 x i10> %b)
 %external = call <4 x i10> @promoted_provider_4_10_c(<4 x i10> %a,<4 x i10> %b)
 store <4 x i10> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i10> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <4 x i10> @promoted_body_4_10_fast(<4 x i10> %a,<4 x i10> %b) noinline {
entry:
 %r = add <4 x i10> %a,%b
 ret <4 x i10> %r
}
declare fastcc <4 x i10> @promoted_provider_4_10_fast(<4 x i10>,<4 x i10>)
define i64 @promoted_probe_4_10_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i10>,ptr %ap,align 1
 %b = load <4 x i10>,ptr %bp,align 1
 %local = call fastcc <4 x i10> @promoted_body_4_10_fast(<4 x i10> %a,<4 x i10> %b)
 %external = call fastcc <4 x i10> @promoted_provider_4_10_fast(<4 x i10> %a,<4 x i10> %b)
 store <4 x i10> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i10> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <4 x i11> @promoted_body_4_11_c(<4 x i11> %a,<4 x i11> %b) noinline {
entry:
 %r = add <4 x i11> %a,%b
 ret <4 x i11> %r
}
declare <4 x i11> @promoted_provider_4_11_c(<4 x i11>,<4 x i11>)
define i64 @promoted_probe_4_11_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i11>,ptr %ap,align 1
 %b = load <4 x i11>,ptr %bp,align 1
 %local = call <4 x i11> @promoted_body_4_11_c(<4 x i11> %a,<4 x i11> %b)
 %external = call <4 x i11> @promoted_provider_4_11_c(<4 x i11> %a,<4 x i11> %b)
 store <4 x i11> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i11> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <4 x i11> @promoted_body_4_11_fast(<4 x i11> %a,<4 x i11> %b) noinline {
entry:
 %r = add <4 x i11> %a,%b
 ret <4 x i11> %r
}
declare fastcc <4 x i11> @promoted_provider_4_11_fast(<4 x i11>,<4 x i11>)
define i64 @promoted_probe_4_11_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i11>,ptr %ap,align 1
 %b = load <4 x i11>,ptr %bp,align 1
 %local = call fastcc <4 x i11> @promoted_body_4_11_fast(<4 x i11> %a,<4 x i11> %b)
 %external = call fastcc <4 x i11> @promoted_provider_4_11_fast(<4 x i11> %a,<4 x i11> %b)
 store <4 x i11> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i11> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <4 x i12> @promoted_body_4_12_c(<4 x i12> %a,<4 x i12> %b) noinline {
entry:
 %r = add <4 x i12> %a,%b
 ret <4 x i12> %r
}
declare <4 x i12> @promoted_provider_4_12_c(<4 x i12>,<4 x i12>)
define i64 @promoted_probe_4_12_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i12>,ptr %ap,align 1
 %b = load <4 x i12>,ptr %bp,align 1
 %local = call <4 x i12> @promoted_body_4_12_c(<4 x i12> %a,<4 x i12> %b)
 %external = call <4 x i12> @promoted_provider_4_12_c(<4 x i12> %a,<4 x i12> %b)
 store <4 x i12> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i12> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <4 x i12> @promoted_body_4_12_fast(<4 x i12> %a,<4 x i12> %b) noinline {
entry:
 %r = add <4 x i12> %a,%b
 ret <4 x i12> %r
}
declare fastcc <4 x i12> @promoted_provider_4_12_fast(<4 x i12>,<4 x i12>)
define i64 @promoted_probe_4_12_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i12>,ptr %ap,align 1
 %b = load <4 x i12>,ptr %bp,align 1
 %local = call fastcc <4 x i12> @promoted_body_4_12_fast(<4 x i12> %a,<4 x i12> %b)
 %external = call fastcc <4 x i12> @promoted_provider_4_12_fast(<4 x i12> %a,<4 x i12> %b)
 store <4 x i12> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i12> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <4 x i13> @promoted_body_4_13_c(<4 x i13> %a,<4 x i13> %b) noinline {
entry:
 %r = add <4 x i13> %a,%b
 ret <4 x i13> %r
}
declare <4 x i13> @promoted_provider_4_13_c(<4 x i13>,<4 x i13>)
define i64 @promoted_probe_4_13_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i13>,ptr %ap,align 1
 %b = load <4 x i13>,ptr %bp,align 1
 %local = call <4 x i13> @promoted_body_4_13_c(<4 x i13> %a,<4 x i13> %b)
 %external = call <4 x i13> @promoted_provider_4_13_c(<4 x i13> %a,<4 x i13> %b)
 store <4 x i13> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i13> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <4 x i13> @promoted_body_4_13_fast(<4 x i13> %a,<4 x i13> %b) noinline {
entry:
 %r = add <4 x i13> %a,%b
 ret <4 x i13> %r
}
declare fastcc <4 x i13> @promoted_provider_4_13_fast(<4 x i13>,<4 x i13>)
define i64 @promoted_probe_4_13_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i13>,ptr %ap,align 1
 %b = load <4 x i13>,ptr %bp,align 1
 %local = call fastcc <4 x i13> @promoted_body_4_13_fast(<4 x i13> %a,<4 x i13> %b)
 %external = call fastcc <4 x i13> @promoted_provider_4_13_fast(<4 x i13> %a,<4 x i13> %b)
 store <4 x i13> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i13> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <4 x i14> @promoted_body_4_14_c(<4 x i14> %a,<4 x i14> %b) noinline {
entry:
 %r = add <4 x i14> %a,%b
 ret <4 x i14> %r
}
declare <4 x i14> @promoted_provider_4_14_c(<4 x i14>,<4 x i14>)
define i64 @promoted_probe_4_14_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i14>,ptr %ap,align 1
 %b = load <4 x i14>,ptr %bp,align 1
 %local = call <4 x i14> @promoted_body_4_14_c(<4 x i14> %a,<4 x i14> %b)
 %external = call <4 x i14> @promoted_provider_4_14_c(<4 x i14> %a,<4 x i14> %b)
 store <4 x i14> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i14> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <4 x i14> @promoted_body_4_14_fast(<4 x i14> %a,<4 x i14> %b) noinline {
entry:
 %r = add <4 x i14> %a,%b
 ret <4 x i14> %r
}
declare fastcc <4 x i14> @promoted_provider_4_14_fast(<4 x i14>,<4 x i14>)
define i64 @promoted_probe_4_14_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i14>,ptr %ap,align 1
 %b = load <4 x i14>,ptr %bp,align 1
 %local = call fastcc <4 x i14> @promoted_body_4_14_fast(<4 x i14> %a,<4 x i14> %b)
 %external = call fastcc <4 x i14> @promoted_provider_4_14_fast(<4 x i14> %a,<4 x i14> %b)
 store <4 x i14> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i14> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <4 x i15> @promoted_body_4_15_c(<4 x i15> %a,<4 x i15> %b) noinline {
entry:
 %r = add <4 x i15> %a,%b
 ret <4 x i15> %r
}
declare <4 x i15> @promoted_provider_4_15_c(<4 x i15>,<4 x i15>)
define i64 @promoted_probe_4_15_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i15>,ptr %ap,align 1
 %b = load <4 x i15>,ptr %bp,align 1
 %local = call <4 x i15> @promoted_body_4_15_c(<4 x i15> %a,<4 x i15> %b)
 %external = call <4 x i15> @promoted_provider_4_15_c(<4 x i15> %a,<4 x i15> %b)
 store <4 x i15> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i15> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <4 x i15> @promoted_body_4_15_fast(<4 x i15> %a,<4 x i15> %b) noinline {
entry:
 %r = add <4 x i15> %a,%b
 ret <4 x i15> %r
}
declare fastcc <4 x i15> @promoted_provider_4_15_fast(<4 x i15>,<4 x i15>)
define i64 @promoted_probe_4_15_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i15>,ptr %ap,align 1
 %b = load <4 x i15>,ptr %bp,align 1
 %local = call fastcc <4 x i15> @promoted_body_4_15_fast(<4 x i15> %a,<4 x i15> %b)
 %external = call fastcc <4 x i15> @promoted_provider_4_15_fast(<4 x i15> %a,<4 x i15> %b)
 store <4 x i15> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i15> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <4 x i17> @promoted_body_4_17_c(<4 x i17> %a,<4 x i17> %b) noinline {
entry:
 %r = add <4 x i17> %a,%b
 ret <4 x i17> %r
}
declare <4 x i17> @promoted_provider_4_17_c(<4 x i17>,<4 x i17>)
define i64 @promoted_probe_4_17_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i17>,ptr %ap,align 1
 %b = load <4 x i17>,ptr %bp,align 1
 %local = call <4 x i17> @promoted_body_4_17_c(<4 x i17> %a,<4 x i17> %b)
 %external = call <4 x i17> @promoted_provider_4_17_c(<4 x i17> %a,<4 x i17> %b)
 store <4 x i17> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i17> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <4 x i17> @promoted_body_4_17_fast(<4 x i17> %a,<4 x i17> %b) noinline {
entry:
 %r = add <4 x i17> %a,%b
 ret <4 x i17> %r
}
declare fastcc <4 x i17> @promoted_provider_4_17_fast(<4 x i17>,<4 x i17>)
define i64 @promoted_probe_4_17_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i17>,ptr %ap,align 1
 %b = load <4 x i17>,ptr %bp,align 1
 %local = call fastcc <4 x i17> @promoted_body_4_17_fast(<4 x i17> %a,<4 x i17> %b)
 %external = call fastcc <4 x i17> @promoted_provider_4_17_fast(<4 x i17> %a,<4 x i17> %b)
 store <4 x i17> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i17> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <4 x i18> @promoted_body_4_18_c(<4 x i18> %a,<4 x i18> %b) noinline {
entry:
 %r = add <4 x i18> %a,%b
 ret <4 x i18> %r
}
declare <4 x i18> @promoted_provider_4_18_c(<4 x i18>,<4 x i18>)
define i64 @promoted_probe_4_18_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i18>,ptr %ap,align 1
 %b = load <4 x i18>,ptr %bp,align 1
 %local = call <4 x i18> @promoted_body_4_18_c(<4 x i18> %a,<4 x i18> %b)
 %external = call <4 x i18> @promoted_provider_4_18_c(<4 x i18> %a,<4 x i18> %b)
 store <4 x i18> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i18> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <4 x i18> @promoted_body_4_18_fast(<4 x i18> %a,<4 x i18> %b) noinline {
entry:
 %r = add <4 x i18> %a,%b
 ret <4 x i18> %r
}
declare fastcc <4 x i18> @promoted_provider_4_18_fast(<4 x i18>,<4 x i18>)
define i64 @promoted_probe_4_18_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i18>,ptr %ap,align 1
 %b = load <4 x i18>,ptr %bp,align 1
 %local = call fastcc <4 x i18> @promoted_body_4_18_fast(<4 x i18> %a,<4 x i18> %b)
 %external = call fastcc <4 x i18> @promoted_provider_4_18_fast(<4 x i18> %a,<4 x i18> %b)
 store <4 x i18> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i18> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <4 x i19> @promoted_body_4_19_c(<4 x i19> %a,<4 x i19> %b) noinline {
entry:
 %r = add <4 x i19> %a,%b
 ret <4 x i19> %r
}
declare <4 x i19> @promoted_provider_4_19_c(<4 x i19>,<4 x i19>)
define i64 @promoted_probe_4_19_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i19>,ptr %ap,align 1
 %b = load <4 x i19>,ptr %bp,align 1
 %local = call <4 x i19> @promoted_body_4_19_c(<4 x i19> %a,<4 x i19> %b)
 %external = call <4 x i19> @promoted_provider_4_19_c(<4 x i19> %a,<4 x i19> %b)
 store <4 x i19> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i19> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <4 x i19> @promoted_body_4_19_fast(<4 x i19> %a,<4 x i19> %b) noinline {
entry:
 %r = add <4 x i19> %a,%b
 ret <4 x i19> %r
}
declare fastcc <4 x i19> @promoted_provider_4_19_fast(<4 x i19>,<4 x i19>)
define i64 @promoted_probe_4_19_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i19>,ptr %ap,align 1
 %b = load <4 x i19>,ptr %bp,align 1
 %local = call fastcc <4 x i19> @promoted_body_4_19_fast(<4 x i19> %a,<4 x i19> %b)
 %external = call fastcc <4 x i19> @promoted_provider_4_19_fast(<4 x i19> %a,<4 x i19> %b)
 store <4 x i19> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i19> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <4 x i20> @promoted_body_4_20_c(<4 x i20> %a,<4 x i20> %b) noinline {
entry:
 %r = add <4 x i20> %a,%b
 ret <4 x i20> %r
}
declare <4 x i20> @promoted_provider_4_20_c(<4 x i20>,<4 x i20>)
define i64 @promoted_probe_4_20_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i20>,ptr %ap,align 1
 %b = load <4 x i20>,ptr %bp,align 1
 %local = call <4 x i20> @promoted_body_4_20_c(<4 x i20> %a,<4 x i20> %b)
 %external = call <4 x i20> @promoted_provider_4_20_c(<4 x i20> %a,<4 x i20> %b)
 store <4 x i20> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i20> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <4 x i20> @promoted_body_4_20_fast(<4 x i20> %a,<4 x i20> %b) noinline {
entry:
 %r = add <4 x i20> %a,%b
 ret <4 x i20> %r
}
declare fastcc <4 x i20> @promoted_provider_4_20_fast(<4 x i20>,<4 x i20>)
define i64 @promoted_probe_4_20_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i20>,ptr %ap,align 1
 %b = load <4 x i20>,ptr %bp,align 1
 %local = call fastcc <4 x i20> @promoted_body_4_20_fast(<4 x i20> %a,<4 x i20> %b)
 %external = call fastcc <4 x i20> @promoted_provider_4_20_fast(<4 x i20> %a,<4 x i20> %b)
 store <4 x i20> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i20> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <4 x i21> @promoted_body_4_21_c(<4 x i21> %a,<4 x i21> %b) noinline {
entry:
 %r = add <4 x i21> %a,%b
 ret <4 x i21> %r
}
declare <4 x i21> @promoted_provider_4_21_c(<4 x i21>,<4 x i21>)
define i64 @promoted_probe_4_21_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i21>,ptr %ap,align 1
 %b = load <4 x i21>,ptr %bp,align 1
 %local = call <4 x i21> @promoted_body_4_21_c(<4 x i21> %a,<4 x i21> %b)
 %external = call <4 x i21> @promoted_provider_4_21_c(<4 x i21> %a,<4 x i21> %b)
 store <4 x i21> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i21> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <4 x i21> @promoted_body_4_21_fast(<4 x i21> %a,<4 x i21> %b) noinline {
entry:
 %r = add <4 x i21> %a,%b
 ret <4 x i21> %r
}
declare fastcc <4 x i21> @promoted_provider_4_21_fast(<4 x i21>,<4 x i21>)
define i64 @promoted_probe_4_21_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i21>,ptr %ap,align 1
 %b = load <4 x i21>,ptr %bp,align 1
 %local = call fastcc <4 x i21> @promoted_body_4_21_fast(<4 x i21> %a,<4 x i21> %b)
 %external = call fastcc <4 x i21> @promoted_provider_4_21_fast(<4 x i21> %a,<4 x i21> %b)
 store <4 x i21> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i21> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <4 x i22> @promoted_body_4_22_c(<4 x i22> %a,<4 x i22> %b) noinline {
entry:
 %r = add <4 x i22> %a,%b
 ret <4 x i22> %r
}
declare <4 x i22> @promoted_provider_4_22_c(<4 x i22>,<4 x i22>)
define i64 @promoted_probe_4_22_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i22>,ptr %ap,align 1
 %b = load <4 x i22>,ptr %bp,align 1
 %local = call <4 x i22> @promoted_body_4_22_c(<4 x i22> %a,<4 x i22> %b)
 %external = call <4 x i22> @promoted_provider_4_22_c(<4 x i22> %a,<4 x i22> %b)
 store <4 x i22> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i22> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <4 x i22> @promoted_body_4_22_fast(<4 x i22> %a,<4 x i22> %b) noinline {
entry:
 %r = add <4 x i22> %a,%b
 ret <4 x i22> %r
}
declare fastcc <4 x i22> @promoted_provider_4_22_fast(<4 x i22>,<4 x i22>)
define i64 @promoted_probe_4_22_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i22>,ptr %ap,align 1
 %b = load <4 x i22>,ptr %bp,align 1
 %local = call fastcc <4 x i22> @promoted_body_4_22_fast(<4 x i22> %a,<4 x i22> %b)
 %external = call fastcc <4 x i22> @promoted_provider_4_22_fast(<4 x i22> %a,<4 x i22> %b)
 store <4 x i22> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i22> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <4 x i23> @promoted_body_4_23_c(<4 x i23> %a,<4 x i23> %b) noinline {
entry:
 %r = add <4 x i23> %a,%b
 ret <4 x i23> %r
}
declare <4 x i23> @promoted_provider_4_23_c(<4 x i23>,<4 x i23>)
define i64 @promoted_probe_4_23_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i23>,ptr %ap,align 1
 %b = load <4 x i23>,ptr %bp,align 1
 %local = call <4 x i23> @promoted_body_4_23_c(<4 x i23> %a,<4 x i23> %b)
 %external = call <4 x i23> @promoted_provider_4_23_c(<4 x i23> %a,<4 x i23> %b)
 store <4 x i23> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i23> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <4 x i23> @promoted_body_4_23_fast(<4 x i23> %a,<4 x i23> %b) noinline {
entry:
 %r = add <4 x i23> %a,%b
 ret <4 x i23> %r
}
declare fastcc <4 x i23> @promoted_provider_4_23_fast(<4 x i23>,<4 x i23>)
define i64 @promoted_probe_4_23_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i23>,ptr %ap,align 1
 %b = load <4 x i23>,ptr %bp,align 1
 %local = call fastcc <4 x i23> @promoted_body_4_23_fast(<4 x i23> %a,<4 x i23> %b)
 %external = call fastcc <4 x i23> @promoted_provider_4_23_fast(<4 x i23> %a,<4 x i23> %b)
 store <4 x i23> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i23> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <4 x i24> @promoted_body_4_24_c(<4 x i24> %a,<4 x i24> %b) noinline {
entry:
 %r = add <4 x i24> %a,%b
 ret <4 x i24> %r
}
declare <4 x i24> @promoted_provider_4_24_c(<4 x i24>,<4 x i24>)
define i64 @promoted_probe_4_24_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i24>,ptr %ap,align 1
 %b = load <4 x i24>,ptr %bp,align 1
 %local = call <4 x i24> @promoted_body_4_24_c(<4 x i24> %a,<4 x i24> %b)
 %external = call <4 x i24> @promoted_provider_4_24_c(<4 x i24> %a,<4 x i24> %b)
 store <4 x i24> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i24> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <4 x i24> @promoted_body_4_24_fast(<4 x i24> %a,<4 x i24> %b) noinline {
entry:
 %r = add <4 x i24> %a,%b
 ret <4 x i24> %r
}
declare fastcc <4 x i24> @promoted_provider_4_24_fast(<4 x i24>,<4 x i24>)
define i64 @promoted_probe_4_24_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i24>,ptr %ap,align 1
 %b = load <4 x i24>,ptr %bp,align 1
 %local = call fastcc <4 x i24> @promoted_body_4_24_fast(<4 x i24> %a,<4 x i24> %b)
 %external = call fastcc <4 x i24> @promoted_provider_4_24_fast(<4 x i24> %a,<4 x i24> %b)
 store <4 x i24> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i24> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <4 x i25> @promoted_body_4_25_c(<4 x i25> %a,<4 x i25> %b) noinline {
entry:
 %r = add <4 x i25> %a,%b
 ret <4 x i25> %r
}
declare <4 x i25> @promoted_provider_4_25_c(<4 x i25>,<4 x i25>)
define i64 @promoted_probe_4_25_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i25>,ptr %ap,align 1
 %b = load <4 x i25>,ptr %bp,align 1
 %local = call <4 x i25> @promoted_body_4_25_c(<4 x i25> %a,<4 x i25> %b)
 %external = call <4 x i25> @promoted_provider_4_25_c(<4 x i25> %a,<4 x i25> %b)
 store <4 x i25> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i25> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <4 x i25> @promoted_body_4_25_fast(<4 x i25> %a,<4 x i25> %b) noinline {
entry:
 %r = add <4 x i25> %a,%b
 ret <4 x i25> %r
}
declare fastcc <4 x i25> @promoted_provider_4_25_fast(<4 x i25>,<4 x i25>)
define i64 @promoted_probe_4_25_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i25>,ptr %ap,align 1
 %b = load <4 x i25>,ptr %bp,align 1
 %local = call fastcc <4 x i25> @promoted_body_4_25_fast(<4 x i25> %a,<4 x i25> %b)
 %external = call fastcc <4 x i25> @promoted_provider_4_25_fast(<4 x i25> %a,<4 x i25> %b)
 store <4 x i25> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i25> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <4 x i26> @promoted_body_4_26_c(<4 x i26> %a,<4 x i26> %b) noinline {
entry:
 %r = add <4 x i26> %a,%b
 ret <4 x i26> %r
}
declare <4 x i26> @promoted_provider_4_26_c(<4 x i26>,<4 x i26>)
define i64 @promoted_probe_4_26_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i26>,ptr %ap,align 1
 %b = load <4 x i26>,ptr %bp,align 1
 %local = call <4 x i26> @promoted_body_4_26_c(<4 x i26> %a,<4 x i26> %b)
 %external = call <4 x i26> @promoted_provider_4_26_c(<4 x i26> %a,<4 x i26> %b)
 store <4 x i26> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i26> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <4 x i26> @promoted_body_4_26_fast(<4 x i26> %a,<4 x i26> %b) noinline {
entry:
 %r = add <4 x i26> %a,%b
 ret <4 x i26> %r
}
declare fastcc <4 x i26> @promoted_provider_4_26_fast(<4 x i26>,<4 x i26>)
define i64 @promoted_probe_4_26_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i26>,ptr %ap,align 1
 %b = load <4 x i26>,ptr %bp,align 1
 %local = call fastcc <4 x i26> @promoted_body_4_26_fast(<4 x i26> %a,<4 x i26> %b)
 %external = call fastcc <4 x i26> @promoted_provider_4_26_fast(<4 x i26> %a,<4 x i26> %b)
 store <4 x i26> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i26> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <4 x i27> @promoted_body_4_27_c(<4 x i27> %a,<4 x i27> %b) noinline {
entry:
 %r = add <4 x i27> %a,%b
 ret <4 x i27> %r
}
declare <4 x i27> @promoted_provider_4_27_c(<4 x i27>,<4 x i27>)
define i64 @promoted_probe_4_27_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i27>,ptr %ap,align 1
 %b = load <4 x i27>,ptr %bp,align 1
 %local = call <4 x i27> @promoted_body_4_27_c(<4 x i27> %a,<4 x i27> %b)
 %external = call <4 x i27> @promoted_provider_4_27_c(<4 x i27> %a,<4 x i27> %b)
 store <4 x i27> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i27> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <4 x i27> @promoted_body_4_27_fast(<4 x i27> %a,<4 x i27> %b) noinline {
entry:
 %r = add <4 x i27> %a,%b
 ret <4 x i27> %r
}
declare fastcc <4 x i27> @promoted_provider_4_27_fast(<4 x i27>,<4 x i27>)
define i64 @promoted_probe_4_27_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i27>,ptr %ap,align 1
 %b = load <4 x i27>,ptr %bp,align 1
 %local = call fastcc <4 x i27> @promoted_body_4_27_fast(<4 x i27> %a,<4 x i27> %b)
 %external = call fastcc <4 x i27> @promoted_provider_4_27_fast(<4 x i27> %a,<4 x i27> %b)
 store <4 x i27> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i27> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <4 x i28> @promoted_body_4_28_c(<4 x i28> %a,<4 x i28> %b) noinline {
entry:
 %r = add <4 x i28> %a,%b
 ret <4 x i28> %r
}
declare <4 x i28> @promoted_provider_4_28_c(<4 x i28>,<4 x i28>)
define i64 @promoted_probe_4_28_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i28>,ptr %ap,align 1
 %b = load <4 x i28>,ptr %bp,align 1
 %local = call <4 x i28> @promoted_body_4_28_c(<4 x i28> %a,<4 x i28> %b)
 %external = call <4 x i28> @promoted_provider_4_28_c(<4 x i28> %a,<4 x i28> %b)
 store <4 x i28> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i28> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <4 x i28> @promoted_body_4_28_fast(<4 x i28> %a,<4 x i28> %b) noinline {
entry:
 %r = add <4 x i28> %a,%b
 ret <4 x i28> %r
}
declare fastcc <4 x i28> @promoted_provider_4_28_fast(<4 x i28>,<4 x i28>)
define i64 @promoted_probe_4_28_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i28>,ptr %ap,align 1
 %b = load <4 x i28>,ptr %bp,align 1
 %local = call fastcc <4 x i28> @promoted_body_4_28_fast(<4 x i28> %a,<4 x i28> %b)
 %external = call fastcc <4 x i28> @promoted_provider_4_28_fast(<4 x i28> %a,<4 x i28> %b)
 store <4 x i28> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i28> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <4 x i29> @promoted_body_4_29_c(<4 x i29> %a,<4 x i29> %b) noinline {
entry:
 %r = add <4 x i29> %a,%b
 ret <4 x i29> %r
}
declare <4 x i29> @promoted_provider_4_29_c(<4 x i29>,<4 x i29>)
define i64 @promoted_probe_4_29_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i29>,ptr %ap,align 1
 %b = load <4 x i29>,ptr %bp,align 1
 %local = call <4 x i29> @promoted_body_4_29_c(<4 x i29> %a,<4 x i29> %b)
 %external = call <4 x i29> @promoted_provider_4_29_c(<4 x i29> %a,<4 x i29> %b)
 store <4 x i29> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i29> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <4 x i29> @promoted_body_4_29_fast(<4 x i29> %a,<4 x i29> %b) noinline {
entry:
 %r = add <4 x i29> %a,%b
 ret <4 x i29> %r
}
declare fastcc <4 x i29> @promoted_provider_4_29_fast(<4 x i29>,<4 x i29>)
define i64 @promoted_probe_4_29_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i29>,ptr %ap,align 1
 %b = load <4 x i29>,ptr %bp,align 1
 %local = call fastcc <4 x i29> @promoted_body_4_29_fast(<4 x i29> %a,<4 x i29> %b)
 %external = call fastcc <4 x i29> @promoted_provider_4_29_fast(<4 x i29> %a,<4 x i29> %b)
 store <4 x i29> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i29> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <4 x i30> @promoted_body_4_30_c(<4 x i30> %a,<4 x i30> %b) noinline {
entry:
 %r = add <4 x i30> %a,%b
 ret <4 x i30> %r
}
declare <4 x i30> @promoted_provider_4_30_c(<4 x i30>,<4 x i30>)
define i64 @promoted_probe_4_30_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i30>,ptr %ap,align 1
 %b = load <4 x i30>,ptr %bp,align 1
 %local = call <4 x i30> @promoted_body_4_30_c(<4 x i30> %a,<4 x i30> %b)
 %external = call <4 x i30> @promoted_provider_4_30_c(<4 x i30> %a,<4 x i30> %b)
 store <4 x i30> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i30> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <4 x i30> @promoted_body_4_30_fast(<4 x i30> %a,<4 x i30> %b) noinline {
entry:
 %r = add <4 x i30> %a,%b
 ret <4 x i30> %r
}
declare fastcc <4 x i30> @promoted_provider_4_30_fast(<4 x i30>,<4 x i30>)
define i64 @promoted_probe_4_30_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i30>,ptr %ap,align 1
 %b = load <4 x i30>,ptr %bp,align 1
 %local = call fastcc <4 x i30> @promoted_body_4_30_fast(<4 x i30> %a,<4 x i30> %b)
 %external = call fastcc <4 x i30> @promoted_provider_4_30_fast(<4 x i30> %a,<4 x i30> %b)
 store <4 x i30> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i30> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <4 x i31> @promoted_body_4_31_c(<4 x i31> %a,<4 x i31> %b) noinline {
entry:
 %r = add <4 x i31> %a,%b
 ret <4 x i31> %r
}
declare <4 x i31> @promoted_provider_4_31_c(<4 x i31>,<4 x i31>)
define i64 @promoted_probe_4_31_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i31>,ptr %ap,align 1
 %b = load <4 x i31>,ptr %bp,align 1
 %local = call <4 x i31> @promoted_body_4_31_c(<4 x i31> %a,<4 x i31> %b)
 %external = call <4 x i31> @promoted_provider_4_31_c(<4 x i31> %a,<4 x i31> %b)
 store <4 x i31> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i31> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <4 x i31> @promoted_body_4_31_fast(<4 x i31> %a,<4 x i31> %b) noinline {
entry:
 %r = add <4 x i31> %a,%b
 ret <4 x i31> %r
}
declare fastcc <4 x i31> @promoted_provider_4_31_fast(<4 x i31>,<4 x i31>)
define i64 @promoted_probe_4_31_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <4 x i31>,ptr %ap,align 1
 %b = load <4 x i31>,ptr %bp,align 1
 %local = call fastcc <4 x i31> @promoted_body_4_31_fast(<4 x i31> %a,<4 x i31> %b)
 %external = call fastcc <4 x i31> @promoted_provider_4_31_fast(<4 x i31> %a,<4 x i31> %b)
 store <4 x i31> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <4 x i31> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
