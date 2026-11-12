target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
define <2 x i1> @promoted_body_2_1_c(<2 x i1> %a,<2 x i1> %b) noinline {
entry:
 %r = add <2 x i1> %a,%b
 ret <2 x i1> %r
}
declare <2 x i1> @promoted_provider_2_1_c(<2 x i1>,<2 x i1>)
define i64 @promoted_probe_2_1_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i1>,ptr %ap,align 1
 %b = load <2 x i1>,ptr %bp,align 1
 %local = call <2 x i1> @promoted_body_2_1_c(<2 x i1> %a,<2 x i1> %b)
 %external = call <2 x i1> @promoted_provider_2_1_c(<2 x i1> %a,<2 x i1> %b)
 store <2 x i1> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i1> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i1> @promoted_body_2_1_fast(<2 x i1> %a,<2 x i1> %b) noinline {
entry:
 %r = add <2 x i1> %a,%b
 ret <2 x i1> %r
}
declare fastcc <2 x i1> @promoted_provider_2_1_fast(<2 x i1>,<2 x i1>)
define i64 @promoted_probe_2_1_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i1>,ptr %ap,align 1
 %b = load <2 x i1>,ptr %bp,align 1
 %local = call fastcc <2 x i1> @promoted_body_2_1_fast(<2 x i1> %a,<2 x i1> %b)
 %external = call fastcc <2 x i1> @promoted_provider_2_1_fast(<2 x i1> %a,<2 x i1> %b)
 store <2 x i1> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i1> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i2> @promoted_body_2_2_c(<2 x i2> %a,<2 x i2> %b) noinline {
entry:
 %r = add <2 x i2> %a,%b
 ret <2 x i2> %r
}
declare <2 x i2> @promoted_provider_2_2_c(<2 x i2>,<2 x i2>)
define i64 @promoted_probe_2_2_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i2>,ptr %ap,align 1
 %b = load <2 x i2>,ptr %bp,align 1
 %local = call <2 x i2> @promoted_body_2_2_c(<2 x i2> %a,<2 x i2> %b)
 %external = call <2 x i2> @promoted_provider_2_2_c(<2 x i2> %a,<2 x i2> %b)
 store <2 x i2> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i2> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i2> @promoted_body_2_2_fast(<2 x i2> %a,<2 x i2> %b) noinline {
entry:
 %r = add <2 x i2> %a,%b
 ret <2 x i2> %r
}
declare fastcc <2 x i2> @promoted_provider_2_2_fast(<2 x i2>,<2 x i2>)
define i64 @promoted_probe_2_2_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i2>,ptr %ap,align 1
 %b = load <2 x i2>,ptr %bp,align 1
 %local = call fastcc <2 x i2> @promoted_body_2_2_fast(<2 x i2> %a,<2 x i2> %b)
 %external = call fastcc <2 x i2> @promoted_provider_2_2_fast(<2 x i2> %a,<2 x i2> %b)
 store <2 x i2> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i2> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i3> @promoted_body_2_3_c(<2 x i3> %a,<2 x i3> %b) noinline {
entry:
 %r = add <2 x i3> %a,%b
 ret <2 x i3> %r
}
declare <2 x i3> @promoted_provider_2_3_c(<2 x i3>,<2 x i3>)
define i64 @promoted_probe_2_3_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i3>,ptr %ap,align 1
 %b = load <2 x i3>,ptr %bp,align 1
 %local = call <2 x i3> @promoted_body_2_3_c(<2 x i3> %a,<2 x i3> %b)
 %external = call <2 x i3> @promoted_provider_2_3_c(<2 x i3> %a,<2 x i3> %b)
 store <2 x i3> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i3> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i3> @promoted_body_2_3_fast(<2 x i3> %a,<2 x i3> %b) noinline {
entry:
 %r = add <2 x i3> %a,%b
 ret <2 x i3> %r
}
declare fastcc <2 x i3> @promoted_provider_2_3_fast(<2 x i3>,<2 x i3>)
define i64 @promoted_probe_2_3_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i3>,ptr %ap,align 1
 %b = load <2 x i3>,ptr %bp,align 1
 %local = call fastcc <2 x i3> @promoted_body_2_3_fast(<2 x i3> %a,<2 x i3> %b)
 %external = call fastcc <2 x i3> @promoted_provider_2_3_fast(<2 x i3> %a,<2 x i3> %b)
 store <2 x i3> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i3> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i4> @promoted_body_2_4_c(<2 x i4> %a,<2 x i4> %b) noinline {
entry:
 %r = add <2 x i4> %a,%b
 ret <2 x i4> %r
}
declare <2 x i4> @promoted_provider_2_4_c(<2 x i4>,<2 x i4>)
define i64 @promoted_probe_2_4_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i4>,ptr %ap,align 1
 %b = load <2 x i4>,ptr %bp,align 1
 %local = call <2 x i4> @promoted_body_2_4_c(<2 x i4> %a,<2 x i4> %b)
 %external = call <2 x i4> @promoted_provider_2_4_c(<2 x i4> %a,<2 x i4> %b)
 store <2 x i4> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i4> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i4> @promoted_body_2_4_fast(<2 x i4> %a,<2 x i4> %b) noinline {
entry:
 %r = add <2 x i4> %a,%b
 ret <2 x i4> %r
}
declare fastcc <2 x i4> @promoted_provider_2_4_fast(<2 x i4>,<2 x i4>)
define i64 @promoted_probe_2_4_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i4>,ptr %ap,align 1
 %b = load <2 x i4>,ptr %bp,align 1
 %local = call fastcc <2 x i4> @promoted_body_2_4_fast(<2 x i4> %a,<2 x i4> %b)
 %external = call fastcc <2 x i4> @promoted_provider_2_4_fast(<2 x i4> %a,<2 x i4> %b)
 store <2 x i4> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i4> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i5> @promoted_body_2_5_c(<2 x i5> %a,<2 x i5> %b) noinline {
entry:
 %r = add <2 x i5> %a,%b
 ret <2 x i5> %r
}
declare <2 x i5> @promoted_provider_2_5_c(<2 x i5>,<2 x i5>)
define i64 @promoted_probe_2_5_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i5>,ptr %ap,align 1
 %b = load <2 x i5>,ptr %bp,align 1
 %local = call <2 x i5> @promoted_body_2_5_c(<2 x i5> %a,<2 x i5> %b)
 %external = call <2 x i5> @promoted_provider_2_5_c(<2 x i5> %a,<2 x i5> %b)
 store <2 x i5> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i5> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i5> @promoted_body_2_5_fast(<2 x i5> %a,<2 x i5> %b) noinline {
entry:
 %r = add <2 x i5> %a,%b
 ret <2 x i5> %r
}
declare fastcc <2 x i5> @promoted_provider_2_5_fast(<2 x i5>,<2 x i5>)
define i64 @promoted_probe_2_5_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i5>,ptr %ap,align 1
 %b = load <2 x i5>,ptr %bp,align 1
 %local = call fastcc <2 x i5> @promoted_body_2_5_fast(<2 x i5> %a,<2 x i5> %b)
 %external = call fastcc <2 x i5> @promoted_provider_2_5_fast(<2 x i5> %a,<2 x i5> %b)
 store <2 x i5> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i5> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i6> @promoted_body_2_6_c(<2 x i6> %a,<2 x i6> %b) noinline {
entry:
 %r = add <2 x i6> %a,%b
 ret <2 x i6> %r
}
declare <2 x i6> @promoted_provider_2_6_c(<2 x i6>,<2 x i6>)
define i64 @promoted_probe_2_6_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i6>,ptr %ap,align 1
 %b = load <2 x i6>,ptr %bp,align 1
 %local = call <2 x i6> @promoted_body_2_6_c(<2 x i6> %a,<2 x i6> %b)
 %external = call <2 x i6> @promoted_provider_2_6_c(<2 x i6> %a,<2 x i6> %b)
 store <2 x i6> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i6> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i6> @promoted_body_2_6_fast(<2 x i6> %a,<2 x i6> %b) noinline {
entry:
 %r = add <2 x i6> %a,%b
 ret <2 x i6> %r
}
declare fastcc <2 x i6> @promoted_provider_2_6_fast(<2 x i6>,<2 x i6>)
define i64 @promoted_probe_2_6_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i6>,ptr %ap,align 1
 %b = load <2 x i6>,ptr %bp,align 1
 %local = call fastcc <2 x i6> @promoted_body_2_6_fast(<2 x i6> %a,<2 x i6> %b)
 %external = call fastcc <2 x i6> @promoted_provider_2_6_fast(<2 x i6> %a,<2 x i6> %b)
 store <2 x i6> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i6> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i7> @promoted_body_2_7_c(<2 x i7> %a,<2 x i7> %b) noinline {
entry:
 %r = add <2 x i7> %a,%b
 ret <2 x i7> %r
}
declare <2 x i7> @promoted_provider_2_7_c(<2 x i7>,<2 x i7>)
define i64 @promoted_probe_2_7_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i7>,ptr %ap,align 1
 %b = load <2 x i7>,ptr %bp,align 1
 %local = call <2 x i7> @promoted_body_2_7_c(<2 x i7> %a,<2 x i7> %b)
 %external = call <2 x i7> @promoted_provider_2_7_c(<2 x i7> %a,<2 x i7> %b)
 store <2 x i7> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i7> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i7> @promoted_body_2_7_fast(<2 x i7> %a,<2 x i7> %b) noinline {
entry:
 %r = add <2 x i7> %a,%b
 ret <2 x i7> %r
}
declare fastcc <2 x i7> @promoted_provider_2_7_fast(<2 x i7>,<2 x i7>)
define i64 @promoted_probe_2_7_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i7>,ptr %ap,align 1
 %b = load <2 x i7>,ptr %bp,align 1
 %local = call fastcc <2 x i7> @promoted_body_2_7_fast(<2 x i7> %a,<2 x i7> %b)
 %external = call fastcc <2 x i7> @promoted_provider_2_7_fast(<2 x i7> %a,<2 x i7> %b)
 store <2 x i7> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i7> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i9> @promoted_body_2_9_c(<2 x i9> %a,<2 x i9> %b) noinline {
entry:
 %r = add <2 x i9> %a,%b
 ret <2 x i9> %r
}
declare <2 x i9> @promoted_provider_2_9_c(<2 x i9>,<2 x i9>)
define i64 @promoted_probe_2_9_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i9>,ptr %ap,align 1
 %b = load <2 x i9>,ptr %bp,align 1
 %local = call <2 x i9> @promoted_body_2_9_c(<2 x i9> %a,<2 x i9> %b)
 %external = call <2 x i9> @promoted_provider_2_9_c(<2 x i9> %a,<2 x i9> %b)
 store <2 x i9> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i9> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i9> @promoted_body_2_9_fast(<2 x i9> %a,<2 x i9> %b) noinline {
entry:
 %r = add <2 x i9> %a,%b
 ret <2 x i9> %r
}
declare fastcc <2 x i9> @promoted_provider_2_9_fast(<2 x i9>,<2 x i9>)
define i64 @promoted_probe_2_9_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i9>,ptr %ap,align 1
 %b = load <2 x i9>,ptr %bp,align 1
 %local = call fastcc <2 x i9> @promoted_body_2_9_fast(<2 x i9> %a,<2 x i9> %b)
 %external = call fastcc <2 x i9> @promoted_provider_2_9_fast(<2 x i9> %a,<2 x i9> %b)
 store <2 x i9> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i9> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i10> @promoted_body_2_10_c(<2 x i10> %a,<2 x i10> %b) noinline {
entry:
 %r = add <2 x i10> %a,%b
 ret <2 x i10> %r
}
declare <2 x i10> @promoted_provider_2_10_c(<2 x i10>,<2 x i10>)
define i64 @promoted_probe_2_10_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i10>,ptr %ap,align 1
 %b = load <2 x i10>,ptr %bp,align 1
 %local = call <2 x i10> @promoted_body_2_10_c(<2 x i10> %a,<2 x i10> %b)
 %external = call <2 x i10> @promoted_provider_2_10_c(<2 x i10> %a,<2 x i10> %b)
 store <2 x i10> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i10> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i10> @promoted_body_2_10_fast(<2 x i10> %a,<2 x i10> %b) noinline {
entry:
 %r = add <2 x i10> %a,%b
 ret <2 x i10> %r
}
declare fastcc <2 x i10> @promoted_provider_2_10_fast(<2 x i10>,<2 x i10>)
define i64 @promoted_probe_2_10_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i10>,ptr %ap,align 1
 %b = load <2 x i10>,ptr %bp,align 1
 %local = call fastcc <2 x i10> @promoted_body_2_10_fast(<2 x i10> %a,<2 x i10> %b)
 %external = call fastcc <2 x i10> @promoted_provider_2_10_fast(<2 x i10> %a,<2 x i10> %b)
 store <2 x i10> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i10> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i11> @promoted_body_2_11_c(<2 x i11> %a,<2 x i11> %b) noinline {
entry:
 %r = add <2 x i11> %a,%b
 ret <2 x i11> %r
}
declare <2 x i11> @promoted_provider_2_11_c(<2 x i11>,<2 x i11>)
define i64 @promoted_probe_2_11_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i11>,ptr %ap,align 1
 %b = load <2 x i11>,ptr %bp,align 1
 %local = call <2 x i11> @promoted_body_2_11_c(<2 x i11> %a,<2 x i11> %b)
 %external = call <2 x i11> @promoted_provider_2_11_c(<2 x i11> %a,<2 x i11> %b)
 store <2 x i11> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i11> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i11> @promoted_body_2_11_fast(<2 x i11> %a,<2 x i11> %b) noinline {
entry:
 %r = add <2 x i11> %a,%b
 ret <2 x i11> %r
}
declare fastcc <2 x i11> @promoted_provider_2_11_fast(<2 x i11>,<2 x i11>)
define i64 @promoted_probe_2_11_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i11>,ptr %ap,align 1
 %b = load <2 x i11>,ptr %bp,align 1
 %local = call fastcc <2 x i11> @promoted_body_2_11_fast(<2 x i11> %a,<2 x i11> %b)
 %external = call fastcc <2 x i11> @promoted_provider_2_11_fast(<2 x i11> %a,<2 x i11> %b)
 store <2 x i11> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i11> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i12> @promoted_body_2_12_c(<2 x i12> %a,<2 x i12> %b) noinline {
entry:
 %r = add <2 x i12> %a,%b
 ret <2 x i12> %r
}
declare <2 x i12> @promoted_provider_2_12_c(<2 x i12>,<2 x i12>)
define i64 @promoted_probe_2_12_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i12>,ptr %ap,align 1
 %b = load <2 x i12>,ptr %bp,align 1
 %local = call <2 x i12> @promoted_body_2_12_c(<2 x i12> %a,<2 x i12> %b)
 %external = call <2 x i12> @promoted_provider_2_12_c(<2 x i12> %a,<2 x i12> %b)
 store <2 x i12> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i12> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i12> @promoted_body_2_12_fast(<2 x i12> %a,<2 x i12> %b) noinline {
entry:
 %r = add <2 x i12> %a,%b
 ret <2 x i12> %r
}
declare fastcc <2 x i12> @promoted_provider_2_12_fast(<2 x i12>,<2 x i12>)
define i64 @promoted_probe_2_12_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i12>,ptr %ap,align 1
 %b = load <2 x i12>,ptr %bp,align 1
 %local = call fastcc <2 x i12> @promoted_body_2_12_fast(<2 x i12> %a,<2 x i12> %b)
 %external = call fastcc <2 x i12> @promoted_provider_2_12_fast(<2 x i12> %a,<2 x i12> %b)
 store <2 x i12> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i12> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i13> @promoted_body_2_13_c(<2 x i13> %a,<2 x i13> %b) noinline {
entry:
 %r = add <2 x i13> %a,%b
 ret <2 x i13> %r
}
declare <2 x i13> @promoted_provider_2_13_c(<2 x i13>,<2 x i13>)
define i64 @promoted_probe_2_13_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i13>,ptr %ap,align 1
 %b = load <2 x i13>,ptr %bp,align 1
 %local = call <2 x i13> @promoted_body_2_13_c(<2 x i13> %a,<2 x i13> %b)
 %external = call <2 x i13> @promoted_provider_2_13_c(<2 x i13> %a,<2 x i13> %b)
 store <2 x i13> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i13> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i13> @promoted_body_2_13_fast(<2 x i13> %a,<2 x i13> %b) noinline {
entry:
 %r = add <2 x i13> %a,%b
 ret <2 x i13> %r
}
declare fastcc <2 x i13> @promoted_provider_2_13_fast(<2 x i13>,<2 x i13>)
define i64 @promoted_probe_2_13_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i13>,ptr %ap,align 1
 %b = load <2 x i13>,ptr %bp,align 1
 %local = call fastcc <2 x i13> @promoted_body_2_13_fast(<2 x i13> %a,<2 x i13> %b)
 %external = call fastcc <2 x i13> @promoted_provider_2_13_fast(<2 x i13> %a,<2 x i13> %b)
 store <2 x i13> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i13> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i14> @promoted_body_2_14_c(<2 x i14> %a,<2 x i14> %b) noinline {
entry:
 %r = add <2 x i14> %a,%b
 ret <2 x i14> %r
}
declare <2 x i14> @promoted_provider_2_14_c(<2 x i14>,<2 x i14>)
define i64 @promoted_probe_2_14_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i14>,ptr %ap,align 1
 %b = load <2 x i14>,ptr %bp,align 1
 %local = call <2 x i14> @promoted_body_2_14_c(<2 x i14> %a,<2 x i14> %b)
 %external = call <2 x i14> @promoted_provider_2_14_c(<2 x i14> %a,<2 x i14> %b)
 store <2 x i14> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i14> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i14> @promoted_body_2_14_fast(<2 x i14> %a,<2 x i14> %b) noinline {
entry:
 %r = add <2 x i14> %a,%b
 ret <2 x i14> %r
}
declare fastcc <2 x i14> @promoted_provider_2_14_fast(<2 x i14>,<2 x i14>)
define i64 @promoted_probe_2_14_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i14>,ptr %ap,align 1
 %b = load <2 x i14>,ptr %bp,align 1
 %local = call fastcc <2 x i14> @promoted_body_2_14_fast(<2 x i14> %a,<2 x i14> %b)
 %external = call fastcc <2 x i14> @promoted_provider_2_14_fast(<2 x i14> %a,<2 x i14> %b)
 store <2 x i14> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i14> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i15> @promoted_body_2_15_c(<2 x i15> %a,<2 x i15> %b) noinline {
entry:
 %r = add <2 x i15> %a,%b
 ret <2 x i15> %r
}
declare <2 x i15> @promoted_provider_2_15_c(<2 x i15>,<2 x i15>)
define i64 @promoted_probe_2_15_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i15>,ptr %ap,align 1
 %b = load <2 x i15>,ptr %bp,align 1
 %local = call <2 x i15> @promoted_body_2_15_c(<2 x i15> %a,<2 x i15> %b)
 %external = call <2 x i15> @promoted_provider_2_15_c(<2 x i15> %a,<2 x i15> %b)
 store <2 x i15> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i15> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i15> @promoted_body_2_15_fast(<2 x i15> %a,<2 x i15> %b) noinline {
entry:
 %r = add <2 x i15> %a,%b
 ret <2 x i15> %r
}
declare fastcc <2 x i15> @promoted_provider_2_15_fast(<2 x i15>,<2 x i15>)
define i64 @promoted_probe_2_15_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i15>,ptr %ap,align 1
 %b = load <2 x i15>,ptr %bp,align 1
 %local = call fastcc <2 x i15> @promoted_body_2_15_fast(<2 x i15> %a,<2 x i15> %b)
 %external = call fastcc <2 x i15> @promoted_provider_2_15_fast(<2 x i15> %a,<2 x i15> %b)
 store <2 x i15> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i15> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i17> @promoted_body_2_17_c(<2 x i17> %a,<2 x i17> %b) noinline {
entry:
 %r = add <2 x i17> %a,%b
 ret <2 x i17> %r
}
declare <2 x i17> @promoted_provider_2_17_c(<2 x i17>,<2 x i17>)
define i64 @promoted_probe_2_17_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i17>,ptr %ap,align 1
 %b = load <2 x i17>,ptr %bp,align 1
 %local = call <2 x i17> @promoted_body_2_17_c(<2 x i17> %a,<2 x i17> %b)
 %external = call <2 x i17> @promoted_provider_2_17_c(<2 x i17> %a,<2 x i17> %b)
 store <2 x i17> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i17> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i17> @promoted_body_2_17_fast(<2 x i17> %a,<2 x i17> %b) noinline {
entry:
 %r = add <2 x i17> %a,%b
 ret <2 x i17> %r
}
declare fastcc <2 x i17> @promoted_provider_2_17_fast(<2 x i17>,<2 x i17>)
define i64 @promoted_probe_2_17_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i17>,ptr %ap,align 1
 %b = load <2 x i17>,ptr %bp,align 1
 %local = call fastcc <2 x i17> @promoted_body_2_17_fast(<2 x i17> %a,<2 x i17> %b)
 %external = call fastcc <2 x i17> @promoted_provider_2_17_fast(<2 x i17> %a,<2 x i17> %b)
 store <2 x i17> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i17> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i18> @promoted_body_2_18_c(<2 x i18> %a,<2 x i18> %b) noinline {
entry:
 %r = add <2 x i18> %a,%b
 ret <2 x i18> %r
}
declare <2 x i18> @promoted_provider_2_18_c(<2 x i18>,<2 x i18>)
define i64 @promoted_probe_2_18_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i18>,ptr %ap,align 1
 %b = load <2 x i18>,ptr %bp,align 1
 %local = call <2 x i18> @promoted_body_2_18_c(<2 x i18> %a,<2 x i18> %b)
 %external = call <2 x i18> @promoted_provider_2_18_c(<2 x i18> %a,<2 x i18> %b)
 store <2 x i18> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i18> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i18> @promoted_body_2_18_fast(<2 x i18> %a,<2 x i18> %b) noinline {
entry:
 %r = add <2 x i18> %a,%b
 ret <2 x i18> %r
}
declare fastcc <2 x i18> @promoted_provider_2_18_fast(<2 x i18>,<2 x i18>)
define i64 @promoted_probe_2_18_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i18>,ptr %ap,align 1
 %b = load <2 x i18>,ptr %bp,align 1
 %local = call fastcc <2 x i18> @promoted_body_2_18_fast(<2 x i18> %a,<2 x i18> %b)
 %external = call fastcc <2 x i18> @promoted_provider_2_18_fast(<2 x i18> %a,<2 x i18> %b)
 store <2 x i18> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i18> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i19> @promoted_body_2_19_c(<2 x i19> %a,<2 x i19> %b) noinline {
entry:
 %r = add <2 x i19> %a,%b
 ret <2 x i19> %r
}
declare <2 x i19> @promoted_provider_2_19_c(<2 x i19>,<2 x i19>)
define i64 @promoted_probe_2_19_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i19>,ptr %ap,align 1
 %b = load <2 x i19>,ptr %bp,align 1
 %local = call <2 x i19> @promoted_body_2_19_c(<2 x i19> %a,<2 x i19> %b)
 %external = call <2 x i19> @promoted_provider_2_19_c(<2 x i19> %a,<2 x i19> %b)
 store <2 x i19> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i19> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i19> @promoted_body_2_19_fast(<2 x i19> %a,<2 x i19> %b) noinline {
entry:
 %r = add <2 x i19> %a,%b
 ret <2 x i19> %r
}
declare fastcc <2 x i19> @promoted_provider_2_19_fast(<2 x i19>,<2 x i19>)
define i64 @promoted_probe_2_19_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i19>,ptr %ap,align 1
 %b = load <2 x i19>,ptr %bp,align 1
 %local = call fastcc <2 x i19> @promoted_body_2_19_fast(<2 x i19> %a,<2 x i19> %b)
 %external = call fastcc <2 x i19> @promoted_provider_2_19_fast(<2 x i19> %a,<2 x i19> %b)
 store <2 x i19> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i19> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i20> @promoted_body_2_20_c(<2 x i20> %a,<2 x i20> %b) noinline {
entry:
 %r = add <2 x i20> %a,%b
 ret <2 x i20> %r
}
declare <2 x i20> @promoted_provider_2_20_c(<2 x i20>,<2 x i20>)
define i64 @promoted_probe_2_20_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i20>,ptr %ap,align 1
 %b = load <2 x i20>,ptr %bp,align 1
 %local = call <2 x i20> @promoted_body_2_20_c(<2 x i20> %a,<2 x i20> %b)
 %external = call <2 x i20> @promoted_provider_2_20_c(<2 x i20> %a,<2 x i20> %b)
 store <2 x i20> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i20> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i20> @promoted_body_2_20_fast(<2 x i20> %a,<2 x i20> %b) noinline {
entry:
 %r = add <2 x i20> %a,%b
 ret <2 x i20> %r
}
declare fastcc <2 x i20> @promoted_provider_2_20_fast(<2 x i20>,<2 x i20>)
define i64 @promoted_probe_2_20_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i20>,ptr %ap,align 1
 %b = load <2 x i20>,ptr %bp,align 1
 %local = call fastcc <2 x i20> @promoted_body_2_20_fast(<2 x i20> %a,<2 x i20> %b)
 %external = call fastcc <2 x i20> @promoted_provider_2_20_fast(<2 x i20> %a,<2 x i20> %b)
 store <2 x i20> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i20> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i21> @promoted_body_2_21_c(<2 x i21> %a,<2 x i21> %b) noinline {
entry:
 %r = add <2 x i21> %a,%b
 ret <2 x i21> %r
}
declare <2 x i21> @promoted_provider_2_21_c(<2 x i21>,<2 x i21>)
define i64 @promoted_probe_2_21_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i21>,ptr %ap,align 1
 %b = load <2 x i21>,ptr %bp,align 1
 %local = call <2 x i21> @promoted_body_2_21_c(<2 x i21> %a,<2 x i21> %b)
 %external = call <2 x i21> @promoted_provider_2_21_c(<2 x i21> %a,<2 x i21> %b)
 store <2 x i21> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i21> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i21> @promoted_body_2_21_fast(<2 x i21> %a,<2 x i21> %b) noinline {
entry:
 %r = add <2 x i21> %a,%b
 ret <2 x i21> %r
}
declare fastcc <2 x i21> @promoted_provider_2_21_fast(<2 x i21>,<2 x i21>)
define i64 @promoted_probe_2_21_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i21>,ptr %ap,align 1
 %b = load <2 x i21>,ptr %bp,align 1
 %local = call fastcc <2 x i21> @promoted_body_2_21_fast(<2 x i21> %a,<2 x i21> %b)
 %external = call fastcc <2 x i21> @promoted_provider_2_21_fast(<2 x i21> %a,<2 x i21> %b)
 store <2 x i21> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i21> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i22> @promoted_body_2_22_c(<2 x i22> %a,<2 x i22> %b) noinline {
entry:
 %r = add <2 x i22> %a,%b
 ret <2 x i22> %r
}
declare <2 x i22> @promoted_provider_2_22_c(<2 x i22>,<2 x i22>)
define i64 @promoted_probe_2_22_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i22>,ptr %ap,align 1
 %b = load <2 x i22>,ptr %bp,align 1
 %local = call <2 x i22> @promoted_body_2_22_c(<2 x i22> %a,<2 x i22> %b)
 %external = call <2 x i22> @promoted_provider_2_22_c(<2 x i22> %a,<2 x i22> %b)
 store <2 x i22> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i22> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i22> @promoted_body_2_22_fast(<2 x i22> %a,<2 x i22> %b) noinline {
entry:
 %r = add <2 x i22> %a,%b
 ret <2 x i22> %r
}
declare fastcc <2 x i22> @promoted_provider_2_22_fast(<2 x i22>,<2 x i22>)
define i64 @promoted_probe_2_22_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i22>,ptr %ap,align 1
 %b = load <2 x i22>,ptr %bp,align 1
 %local = call fastcc <2 x i22> @promoted_body_2_22_fast(<2 x i22> %a,<2 x i22> %b)
 %external = call fastcc <2 x i22> @promoted_provider_2_22_fast(<2 x i22> %a,<2 x i22> %b)
 store <2 x i22> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i22> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i23> @promoted_body_2_23_c(<2 x i23> %a,<2 x i23> %b) noinline {
entry:
 %r = add <2 x i23> %a,%b
 ret <2 x i23> %r
}
declare <2 x i23> @promoted_provider_2_23_c(<2 x i23>,<2 x i23>)
define i64 @promoted_probe_2_23_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i23>,ptr %ap,align 1
 %b = load <2 x i23>,ptr %bp,align 1
 %local = call <2 x i23> @promoted_body_2_23_c(<2 x i23> %a,<2 x i23> %b)
 %external = call <2 x i23> @promoted_provider_2_23_c(<2 x i23> %a,<2 x i23> %b)
 store <2 x i23> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i23> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i23> @promoted_body_2_23_fast(<2 x i23> %a,<2 x i23> %b) noinline {
entry:
 %r = add <2 x i23> %a,%b
 ret <2 x i23> %r
}
declare fastcc <2 x i23> @promoted_provider_2_23_fast(<2 x i23>,<2 x i23>)
define i64 @promoted_probe_2_23_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i23>,ptr %ap,align 1
 %b = load <2 x i23>,ptr %bp,align 1
 %local = call fastcc <2 x i23> @promoted_body_2_23_fast(<2 x i23> %a,<2 x i23> %b)
 %external = call fastcc <2 x i23> @promoted_provider_2_23_fast(<2 x i23> %a,<2 x i23> %b)
 store <2 x i23> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i23> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i24> @promoted_body_2_24_c(<2 x i24> %a,<2 x i24> %b) noinline {
entry:
 %r = add <2 x i24> %a,%b
 ret <2 x i24> %r
}
declare <2 x i24> @promoted_provider_2_24_c(<2 x i24>,<2 x i24>)
define i64 @promoted_probe_2_24_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i24>,ptr %ap,align 1
 %b = load <2 x i24>,ptr %bp,align 1
 %local = call <2 x i24> @promoted_body_2_24_c(<2 x i24> %a,<2 x i24> %b)
 %external = call <2 x i24> @promoted_provider_2_24_c(<2 x i24> %a,<2 x i24> %b)
 store <2 x i24> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i24> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i24> @promoted_body_2_24_fast(<2 x i24> %a,<2 x i24> %b) noinline {
entry:
 %r = add <2 x i24> %a,%b
 ret <2 x i24> %r
}
declare fastcc <2 x i24> @promoted_provider_2_24_fast(<2 x i24>,<2 x i24>)
define i64 @promoted_probe_2_24_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i24>,ptr %ap,align 1
 %b = load <2 x i24>,ptr %bp,align 1
 %local = call fastcc <2 x i24> @promoted_body_2_24_fast(<2 x i24> %a,<2 x i24> %b)
 %external = call fastcc <2 x i24> @promoted_provider_2_24_fast(<2 x i24> %a,<2 x i24> %b)
 store <2 x i24> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i24> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i25> @promoted_body_2_25_c(<2 x i25> %a,<2 x i25> %b) noinline {
entry:
 %r = add <2 x i25> %a,%b
 ret <2 x i25> %r
}
declare <2 x i25> @promoted_provider_2_25_c(<2 x i25>,<2 x i25>)
define i64 @promoted_probe_2_25_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i25>,ptr %ap,align 1
 %b = load <2 x i25>,ptr %bp,align 1
 %local = call <2 x i25> @promoted_body_2_25_c(<2 x i25> %a,<2 x i25> %b)
 %external = call <2 x i25> @promoted_provider_2_25_c(<2 x i25> %a,<2 x i25> %b)
 store <2 x i25> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i25> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i25> @promoted_body_2_25_fast(<2 x i25> %a,<2 x i25> %b) noinline {
entry:
 %r = add <2 x i25> %a,%b
 ret <2 x i25> %r
}
declare fastcc <2 x i25> @promoted_provider_2_25_fast(<2 x i25>,<2 x i25>)
define i64 @promoted_probe_2_25_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i25>,ptr %ap,align 1
 %b = load <2 x i25>,ptr %bp,align 1
 %local = call fastcc <2 x i25> @promoted_body_2_25_fast(<2 x i25> %a,<2 x i25> %b)
 %external = call fastcc <2 x i25> @promoted_provider_2_25_fast(<2 x i25> %a,<2 x i25> %b)
 store <2 x i25> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i25> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i26> @promoted_body_2_26_c(<2 x i26> %a,<2 x i26> %b) noinline {
entry:
 %r = add <2 x i26> %a,%b
 ret <2 x i26> %r
}
declare <2 x i26> @promoted_provider_2_26_c(<2 x i26>,<2 x i26>)
define i64 @promoted_probe_2_26_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i26>,ptr %ap,align 1
 %b = load <2 x i26>,ptr %bp,align 1
 %local = call <2 x i26> @promoted_body_2_26_c(<2 x i26> %a,<2 x i26> %b)
 %external = call <2 x i26> @promoted_provider_2_26_c(<2 x i26> %a,<2 x i26> %b)
 store <2 x i26> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i26> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i26> @promoted_body_2_26_fast(<2 x i26> %a,<2 x i26> %b) noinline {
entry:
 %r = add <2 x i26> %a,%b
 ret <2 x i26> %r
}
declare fastcc <2 x i26> @promoted_provider_2_26_fast(<2 x i26>,<2 x i26>)
define i64 @promoted_probe_2_26_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i26>,ptr %ap,align 1
 %b = load <2 x i26>,ptr %bp,align 1
 %local = call fastcc <2 x i26> @promoted_body_2_26_fast(<2 x i26> %a,<2 x i26> %b)
 %external = call fastcc <2 x i26> @promoted_provider_2_26_fast(<2 x i26> %a,<2 x i26> %b)
 store <2 x i26> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i26> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i27> @promoted_body_2_27_c(<2 x i27> %a,<2 x i27> %b) noinline {
entry:
 %r = add <2 x i27> %a,%b
 ret <2 x i27> %r
}
declare <2 x i27> @promoted_provider_2_27_c(<2 x i27>,<2 x i27>)
define i64 @promoted_probe_2_27_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i27>,ptr %ap,align 1
 %b = load <2 x i27>,ptr %bp,align 1
 %local = call <2 x i27> @promoted_body_2_27_c(<2 x i27> %a,<2 x i27> %b)
 %external = call <2 x i27> @promoted_provider_2_27_c(<2 x i27> %a,<2 x i27> %b)
 store <2 x i27> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i27> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i27> @promoted_body_2_27_fast(<2 x i27> %a,<2 x i27> %b) noinline {
entry:
 %r = add <2 x i27> %a,%b
 ret <2 x i27> %r
}
declare fastcc <2 x i27> @promoted_provider_2_27_fast(<2 x i27>,<2 x i27>)
define i64 @promoted_probe_2_27_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i27>,ptr %ap,align 1
 %b = load <2 x i27>,ptr %bp,align 1
 %local = call fastcc <2 x i27> @promoted_body_2_27_fast(<2 x i27> %a,<2 x i27> %b)
 %external = call fastcc <2 x i27> @promoted_provider_2_27_fast(<2 x i27> %a,<2 x i27> %b)
 store <2 x i27> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i27> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i28> @promoted_body_2_28_c(<2 x i28> %a,<2 x i28> %b) noinline {
entry:
 %r = add <2 x i28> %a,%b
 ret <2 x i28> %r
}
declare <2 x i28> @promoted_provider_2_28_c(<2 x i28>,<2 x i28>)
define i64 @promoted_probe_2_28_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i28>,ptr %ap,align 1
 %b = load <2 x i28>,ptr %bp,align 1
 %local = call <2 x i28> @promoted_body_2_28_c(<2 x i28> %a,<2 x i28> %b)
 %external = call <2 x i28> @promoted_provider_2_28_c(<2 x i28> %a,<2 x i28> %b)
 store <2 x i28> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i28> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i28> @promoted_body_2_28_fast(<2 x i28> %a,<2 x i28> %b) noinline {
entry:
 %r = add <2 x i28> %a,%b
 ret <2 x i28> %r
}
declare fastcc <2 x i28> @promoted_provider_2_28_fast(<2 x i28>,<2 x i28>)
define i64 @promoted_probe_2_28_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i28>,ptr %ap,align 1
 %b = load <2 x i28>,ptr %bp,align 1
 %local = call fastcc <2 x i28> @promoted_body_2_28_fast(<2 x i28> %a,<2 x i28> %b)
 %external = call fastcc <2 x i28> @promoted_provider_2_28_fast(<2 x i28> %a,<2 x i28> %b)
 store <2 x i28> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i28> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i29> @promoted_body_2_29_c(<2 x i29> %a,<2 x i29> %b) noinline {
entry:
 %r = add <2 x i29> %a,%b
 ret <2 x i29> %r
}
declare <2 x i29> @promoted_provider_2_29_c(<2 x i29>,<2 x i29>)
define i64 @promoted_probe_2_29_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i29>,ptr %ap,align 1
 %b = load <2 x i29>,ptr %bp,align 1
 %local = call <2 x i29> @promoted_body_2_29_c(<2 x i29> %a,<2 x i29> %b)
 %external = call <2 x i29> @promoted_provider_2_29_c(<2 x i29> %a,<2 x i29> %b)
 store <2 x i29> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i29> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i29> @promoted_body_2_29_fast(<2 x i29> %a,<2 x i29> %b) noinline {
entry:
 %r = add <2 x i29> %a,%b
 ret <2 x i29> %r
}
declare fastcc <2 x i29> @promoted_provider_2_29_fast(<2 x i29>,<2 x i29>)
define i64 @promoted_probe_2_29_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i29>,ptr %ap,align 1
 %b = load <2 x i29>,ptr %bp,align 1
 %local = call fastcc <2 x i29> @promoted_body_2_29_fast(<2 x i29> %a,<2 x i29> %b)
 %external = call fastcc <2 x i29> @promoted_provider_2_29_fast(<2 x i29> %a,<2 x i29> %b)
 store <2 x i29> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i29> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i30> @promoted_body_2_30_c(<2 x i30> %a,<2 x i30> %b) noinline {
entry:
 %r = add <2 x i30> %a,%b
 ret <2 x i30> %r
}
declare <2 x i30> @promoted_provider_2_30_c(<2 x i30>,<2 x i30>)
define i64 @promoted_probe_2_30_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i30>,ptr %ap,align 1
 %b = load <2 x i30>,ptr %bp,align 1
 %local = call <2 x i30> @promoted_body_2_30_c(<2 x i30> %a,<2 x i30> %b)
 %external = call <2 x i30> @promoted_provider_2_30_c(<2 x i30> %a,<2 x i30> %b)
 store <2 x i30> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i30> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i30> @promoted_body_2_30_fast(<2 x i30> %a,<2 x i30> %b) noinline {
entry:
 %r = add <2 x i30> %a,%b
 ret <2 x i30> %r
}
declare fastcc <2 x i30> @promoted_provider_2_30_fast(<2 x i30>,<2 x i30>)
define i64 @promoted_probe_2_30_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i30>,ptr %ap,align 1
 %b = load <2 x i30>,ptr %bp,align 1
 %local = call fastcc <2 x i30> @promoted_body_2_30_fast(<2 x i30> %a,<2 x i30> %b)
 %external = call fastcc <2 x i30> @promoted_provider_2_30_fast(<2 x i30> %a,<2 x i30> %b)
 store <2 x i30> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i30> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i31> @promoted_body_2_31_c(<2 x i31> %a,<2 x i31> %b) noinline {
entry:
 %r = add <2 x i31> %a,%b
 ret <2 x i31> %r
}
declare <2 x i31> @promoted_provider_2_31_c(<2 x i31>,<2 x i31>)
define i64 @promoted_probe_2_31_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i31>,ptr %ap,align 1
 %b = load <2 x i31>,ptr %bp,align 1
 %local = call <2 x i31> @promoted_body_2_31_c(<2 x i31> %a,<2 x i31> %b)
 %external = call <2 x i31> @promoted_provider_2_31_c(<2 x i31> %a,<2 x i31> %b)
 store <2 x i31> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i31> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i31> @promoted_body_2_31_fast(<2 x i31> %a,<2 x i31> %b) noinline {
entry:
 %r = add <2 x i31> %a,%b
 ret <2 x i31> %r
}
declare fastcc <2 x i31> @promoted_provider_2_31_fast(<2 x i31>,<2 x i31>)
define i64 @promoted_probe_2_31_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i31>,ptr %ap,align 1
 %b = load <2 x i31>,ptr %bp,align 1
 %local = call fastcc <2 x i31> @promoted_body_2_31_fast(<2 x i31> %a,<2 x i31> %b)
 %external = call fastcc <2 x i31> @promoted_provider_2_31_fast(<2 x i31> %a,<2 x i31> %b)
 store <2 x i31> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i31> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i33> @promoted_body_2_33_c(<2 x i33> %a,<2 x i33> %b) noinline {
entry:
 %r = add <2 x i33> %a,%b
 ret <2 x i33> %r
}
declare <2 x i33> @promoted_provider_2_33_c(<2 x i33>,<2 x i33>)
define i64 @promoted_probe_2_33_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i33>,ptr %ap,align 1
 %b = load <2 x i33>,ptr %bp,align 1
 %local = call <2 x i33> @promoted_body_2_33_c(<2 x i33> %a,<2 x i33> %b)
 %external = call <2 x i33> @promoted_provider_2_33_c(<2 x i33> %a,<2 x i33> %b)
 store <2 x i33> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i33> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i33> @promoted_body_2_33_fast(<2 x i33> %a,<2 x i33> %b) noinline {
entry:
 %r = add <2 x i33> %a,%b
 ret <2 x i33> %r
}
declare fastcc <2 x i33> @promoted_provider_2_33_fast(<2 x i33>,<2 x i33>)
define i64 @promoted_probe_2_33_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i33>,ptr %ap,align 1
 %b = load <2 x i33>,ptr %bp,align 1
 %local = call fastcc <2 x i33> @promoted_body_2_33_fast(<2 x i33> %a,<2 x i33> %b)
 %external = call fastcc <2 x i33> @promoted_provider_2_33_fast(<2 x i33> %a,<2 x i33> %b)
 store <2 x i33> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i33> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i34> @promoted_body_2_34_c(<2 x i34> %a,<2 x i34> %b) noinline {
entry:
 %r = add <2 x i34> %a,%b
 ret <2 x i34> %r
}
declare <2 x i34> @promoted_provider_2_34_c(<2 x i34>,<2 x i34>)
define i64 @promoted_probe_2_34_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i34>,ptr %ap,align 1
 %b = load <2 x i34>,ptr %bp,align 1
 %local = call <2 x i34> @promoted_body_2_34_c(<2 x i34> %a,<2 x i34> %b)
 %external = call <2 x i34> @promoted_provider_2_34_c(<2 x i34> %a,<2 x i34> %b)
 store <2 x i34> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i34> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i34> @promoted_body_2_34_fast(<2 x i34> %a,<2 x i34> %b) noinline {
entry:
 %r = add <2 x i34> %a,%b
 ret <2 x i34> %r
}
declare fastcc <2 x i34> @promoted_provider_2_34_fast(<2 x i34>,<2 x i34>)
define i64 @promoted_probe_2_34_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i34>,ptr %ap,align 1
 %b = load <2 x i34>,ptr %bp,align 1
 %local = call fastcc <2 x i34> @promoted_body_2_34_fast(<2 x i34> %a,<2 x i34> %b)
 %external = call fastcc <2 x i34> @promoted_provider_2_34_fast(<2 x i34> %a,<2 x i34> %b)
 store <2 x i34> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i34> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i35> @promoted_body_2_35_c(<2 x i35> %a,<2 x i35> %b) noinline {
entry:
 %r = add <2 x i35> %a,%b
 ret <2 x i35> %r
}
declare <2 x i35> @promoted_provider_2_35_c(<2 x i35>,<2 x i35>)
define i64 @promoted_probe_2_35_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i35>,ptr %ap,align 1
 %b = load <2 x i35>,ptr %bp,align 1
 %local = call <2 x i35> @promoted_body_2_35_c(<2 x i35> %a,<2 x i35> %b)
 %external = call <2 x i35> @promoted_provider_2_35_c(<2 x i35> %a,<2 x i35> %b)
 store <2 x i35> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i35> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i35> @promoted_body_2_35_fast(<2 x i35> %a,<2 x i35> %b) noinline {
entry:
 %r = add <2 x i35> %a,%b
 ret <2 x i35> %r
}
declare fastcc <2 x i35> @promoted_provider_2_35_fast(<2 x i35>,<2 x i35>)
define i64 @promoted_probe_2_35_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i35>,ptr %ap,align 1
 %b = load <2 x i35>,ptr %bp,align 1
 %local = call fastcc <2 x i35> @promoted_body_2_35_fast(<2 x i35> %a,<2 x i35> %b)
 %external = call fastcc <2 x i35> @promoted_provider_2_35_fast(<2 x i35> %a,<2 x i35> %b)
 store <2 x i35> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i35> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i36> @promoted_body_2_36_c(<2 x i36> %a,<2 x i36> %b) noinline {
entry:
 %r = add <2 x i36> %a,%b
 ret <2 x i36> %r
}
declare <2 x i36> @promoted_provider_2_36_c(<2 x i36>,<2 x i36>)
define i64 @promoted_probe_2_36_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i36>,ptr %ap,align 1
 %b = load <2 x i36>,ptr %bp,align 1
 %local = call <2 x i36> @promoted_body_2_36_c(<2 x i36> %a,<2 x i36> %b)
 %external = call <2 x i36> @promoted_provider_2_36_c(<2 x i36> %a,<2 x i36> %b)
 store <2 x i36> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i36> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i36> @promoted_body_2_36_fast(<2 x i36> %a,<2 x i36> %b) noinline {
entry:
 %r = add <2 x i36> %a,%b
 ret <2 x i36> %r
}
declare fastcc <2 x i36> @promoted_provider_2_36_fast(<2 x i36>,<2 x i36>)
define i64 @promoted_probe_2_36_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i36>,ptr %ap,align 1
 %b = load <2 x i36>,ptr %bp,align 1
 %local = call fastcc <2 x i36> @promoted_body_2_36_fast(<2 x i36> %a,<2 x i36> %b)
 %external = call fastcc <2 x i36> @promoted_provider_2_36_fast(<2 x i36> %a,<2 x i36> %b)
 store <2 x i36> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i36> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i37> @promoted_body_2_37_c(<2 x i37> %a,<2 x i37> %b) noinline {
entry:
 %r = add <2 x i37> %a,%b
 ret <2 x i37> %r
}
declare <2 x i37> @promoted_provider_2_37_c(<2 x i37>,<2 x i37>)
define i64 @promoted_probe_2_37_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i37>,ptr %ap,align 1
 %b = load <2 x i37>,ptr %bp,align 1
 %local = call <2 x i37> @promoted_body_2_37_c(<2 x i37> %a,<2 x i37> %b)
 %external = call <2 x i37> @promoted_provider_2_37_c(<2 x i37> %a,<2 x i37> %b)
 store <2 x i37> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i37> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i37> @promoted_body_2_37_fast(<2 x i37> %a,<2 x i37> %b) noinline {
entry:
 %r = add <2 x i37> %a,%b
 ret <2 x i37> %r
}
declare fastcc <2 x i37> @promoted_provider_2_37_fast(<2 x i37>,<2 x i37>)
define i64 @promoted_probe_2_37_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i37>,ptr %ap,align 1
 %b = load <2 x i37>,ptr %bp,align 1
 %local = call fastcc <2 x i37> @promoted_body_2_37_fast(<2 x i37> %a,<2 x i37> %b)
 %external = call fastcc <2 x i37> @promoted_provider_2_37_fast(<2 x i37> %a,<2 x i37> %b)
 store <2 x i37> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i37> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i38> @promoted_body_2_38_c(<2 x i38> %a,<2 x i38> %b) noinline {
entry:
 %r = add <2 x i38> %a,%b
 ret <2 x i38> %r
}
declare <2 x i38> @promoted_provider_2_38_c(<2 x i38>,<2 x i38>)
define i64 @promoted_probe_2_38_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i38>,ptr %ap,align 1
 %b = load <2 x i38>,ptr %bp,align 1
 %local = call <2 x i38> @promoted_body_2_38_c(<2 x i38> %a,<2 x i38> %b)
 %external = call <2 x i38> @promoted_provider_2_38_c(<2 x i38> %a,<2 x i38> %b)
 store <2 x i38> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i38> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i38> @promoted_body_2_38_fast(<2 x i38> %a,<2 x i38> %b) noinline {
entry:
 %r = add <2 x i38> %a,%b
 ret <2 x i38> %r
}
declare fastcc <2 x i38> @promoted_provider_2_38_fast(<2 x i38>,<2 x i38>)
define i64 @promoted_probe_2_38_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i38>,ptr %ap,align 1
 %b = load <2 x i38>,ptr %bp,align 1
 %local = call fastcc <2 x i38> @promoted_body_2_38_fast(<2 x i38> %a,<2 x i38> %b)
 %external = call fastcc <2 x i38> @promoted_provider_2_38_fast(<2 x i38> %a,<2 x i38> %b)
 store <2 x i38> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i38> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i39> @promoted_body_2_39_c(<2 x i39> %a,<2 x i39> %b) noinline {
entry:
 %r = add <2 x i39> %a,%b
 ret <2 x i39> %r
}
declare <2 x i39> @promoted_provider_2_39_c(<2 x i39>,<2 x i39>)
define i64 @promoted_probe_2_39_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i39>,ptr %ap,align 1
 %b = load <2 x i39>,ptr %bp,align 1
 %local = call <2 x i39> @promoted_body_2_39_c(<2 x i39> %a,<2 x i39> %b)
 %external = call <2 x i39> @promoted_provider_2_39_c(<2 x i39> %a,<2 x i39> %b)
 store <2 x i39> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i39> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i39> @promoted_body_2_39_fast(<2 x i39> %a,<2 x i39> %b) noinline {
entry:
 %r = add <2 x i39> %a,%b
 ret <2 x i39> %r
}
declare fastcc <2 x i39> @promoted_provider_2_39_fast(<2 x i39>,<2 x i39>)
define i64 @promoted_probe_2_39_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i39>,ptr %ap,align 1
 %b = load <2 x i39>,ptr %bp,align 1
 %local = call fastcc <2 x i39> @promoted_body_2_39_fast(<2 x i39> %a,<2 x i39> %b)
 %external = call fastcc <2 x i39> @promoted_provider_2_39_fast(<2 x i39> %a,<2 x i39> %b)
 store <2 x i39> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i39> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i40> @promoted_body_2_40_c(<2 x i40> %a,<2 x i40> %b) noinline {
entry:
 %r = add <2 x i40> %a,%b
 ret <2 x i40> %r
}
declare <2 x i40> @promoted_provider_2_40_c(<2 x i40>,<2 x i40>)
define i64 @promoted_probe_2_40_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i40>,ptr %ap,align 1
 %b = load <2 x i40>,ptr %bp,align 1
 %local = call <2 x i40> @promoted_body_2_40_c(<2 x i40> %a,<2 x i40> %b)
 %external = call <2 x i40> @promoted_provider_2_40_c(<2 x i40> %a,<2 x i40> %b)
 store <2 x i40> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i40> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i40> @promoted_body_2_40_fast(<2 x i40> %a,<2 x i40> %b) noinline {
entry:
 %r = add <2 x i40> %a,%b
 ret <2 x i40> %r
}
declare fastcc <2 x i40> @promoted_provider_2_40_fast(<2 x i40>,<2 x i40>)
define i64 @promoted_probe_2_40_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i40>,ptr %ap,align 1
 %b = load <2 x i40>,ptr %bp,align 1
 %local = call fastcc <2 x i40> @promoted_body_2_40_fast(<2 x i40> %a,<2 x i40> %b)
 %external = call fastcc <2 x i40> @promoted_provider_2_40_fast(<2 x i40> %a,<2 x i40> %b)
 store <2 x i40> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i40> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i41> @promoted_body_2_41_c(<2 x i41> %a,<2 x i41> %b) noinline {
entry:
 %r = add <2 x i41> %a,%b
 ret <2 x i41> %r
}
declare <2 x i41> @promoted_provider_2_41_c(<2 x i41>,<2 x i41>)
define i64 @promoted_probe_2_41_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i41>,ptr %ap,align 1
 %b = load <2 x i41>,ptr %bp,align 1
 %local = call <2 x i41> @promoted_body_2_41_c(<2 x i41> %a,<2 x i41> %b)
 %external = call <2 x i41> @promoted_provider_2_41_c(<2 x i41> %a,<2 x i41> %b)
 store <2 x i41> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i41> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i41> @promoted_body_2_41_fast(<2 x i41> %a,<2 x i41> %b) noinline {
entry:
 %r = add <2 x i41> %a,%b
 ret <2 x i41> %r
}
declare fastcc <2 x i41> @promoted_provider_2_41_fast(<2 x i41>,<2 x i41>)
define i64 @promoted_probe_2_41_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i41>,ptr %ap,align 1
 %b = load <2 x i41>,ptr %bp,align 1
 %local = call fastcc <2 x i41> @promoted_body_2_41_fast(<2 x i41> %a,<2 x i41> %b)
 %external = call fastcc <2 x i41> @promoted_provider_2_41_fast(<2 x i41> %a,<2 x i41> %b)
 store <2 x i41> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i41> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i42> @promoted_body_2_42_c(<2 x i42> %a,<2 x i42> %b) noinline {
entry:
 %r = add <2 x i42> %a,%b
 ret <2 x i42> %r
}
declare <2 x i42> @promoted_provider_2_42_c(<2 x i42>,<2 x i42>)
define i64 @promoted_probe_2_42_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i42>,ptr %ap,align 1
 %b = load <2 x i42>,ptr %bp,align 1
 %local = call <2 x i42> @promoted_body_2_42_c(<2 x i42> %a,<2 x i42> %b)
 %external = call <2 x i42> @promoted_provider_2_42_c(<2 x i42> %a,<2 x i42> %b)
 store <2 x i42> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i42> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i42> @promoted_body_2_42_fast(<2 x i42> %a,<2 x i42> %b) noinline {
entry:
 %r = add <2 x i42> %a,%b
 ret <2 x i42> %r
}
declare fastcc <2 x i42> @promoted_provider_2_42_fast(<2 x i42>,<2 x i42>)
define i64 @promoted_probe_2_42_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i42>,ptr %ap,align 1
 %b = load <2 x i42>,ptr %bp,align 1
 %local = call fastcc <2 x i42> @promoted_body_2_42_fast(<2 x i42> %a,<2 x i42> %b)
 %external = call fastcc <2 x i42> @promoted_provider_2_42_fast(<2 x i42> %a,<2 x i42> %b)
 store <2 x i42> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i42> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i43> @promoted_body_2_43_c(<2 x i43> %a,<2 x i43> %b) noinline {
entry:
 %r = add <2 x i43> %a,%b
 ret <2 x i43> %r
}
declare <2 x i43> @promoted_provider_2_43_c(<2 x i43>,<2 x i43>)
define i64 @promoted_probe_2_43_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i43>,ptr %ap,align 1
 %b = load <2 x i43>,ptr %bp,align 1
 %local = call <2 x i43> @promoted_body_2_43_c(<2 x i43> %a,<2 x i43> %b)
 %external = call <2 x i43> @promoted_provider_2_43_c(<2 x i43> %a,<2 x i43> %b)
 store <2 x i43> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i43> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i43> @promoted_body_2_43_fast(<2 x i43> %a,<2 x i43> %b) noinline {
entry:
 %r = add <2 x i43> %a,%b
 ret <2 x i43> %r
}
declare fastcc <2 x i43> @promoted_provider_2_43_fast(<2 x i43>,<2 x i43>)
define i64 @promoted_probe_2_43_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i43>,ptr %ap,align 1
 %b = load <2 x i43>,ptr %bp,align 1
 %local = call fastcc <2 x i43> @promoted_body_2_43_fast(<2 x i43> %a,<2 x i43> %b)
 %external = call fastcc <2 x i43> @promoted_provider_2_43_fast(<2 x i43> %a,<2 x i43> %b)
 store <2 x i43> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i43> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i44> @promoted_body_2_44_c(<2 x i44> %a,<2 x i44> %b) noinline {
entry:
 %r = add <2 x i44> %a,%b
 ret <2 x i44> %r
}
declare <2 x i44> @promoted_provider_2_44_c(<2 x i44>,<2 x i44>)
define i64 @promoted_probe_2_44_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i44>,ptr %ap,align 1
 %b = load <2 x i44>,ptr %bp,align 1
 %local = call <2 x i44> @promoted_body_2_44_c(<2 x i44> %a,<2 x i44> %b)
 %external = call <2 x i44> @promoted_provider_2_44_c(<2 x i44> %a,<2 x i44> %b)
 store <2 x i44> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i44> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i44> @promoted_body_2_44_fast(<2 x i44> %a,<2 x i44> %b) noinline {
entry:
 %r = add <2 x i44> %a,%b
 ret <2 x i44> %r
}
declare fastcc <2 x i44> @promoted_provider_2_44_fast(<2 x i44>,<2 x i44>)
define i64 @promoted_probe_2_44_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i44>,ptr %ap,align 1
 %b = load <2 x i44>,ptr %bp,align 1
 %local = call fastcc <2 x i44> @promoted_body_2_44_fast(<2 x i44> %a,<2 x i44> %b)
 %external = call fastcc <2 x i44> @promoted_provider_2_44_fast(<2 x i44> %a,<2 x i44> %b)
 store <2 x i44> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i44> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i45> @promoted_body_2_45_c(<2 x i45> %a,<2 x i45> %b) noinline {
entry:
 %r = add <2 x i45> %a,%b
 ret <2 x i45> %r
}
declare <2 x i45> @promoted_provider_2_45_c(<2 x i45>,<2 x i45>)
define i64 @promoted_probe_2_45_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i45>,ptr %ap,align 1
 %b = load <2 x i45>,ptr %bp,align 1
 %local = call <2 x i45> @promoted_body_2_45_c(<2 x i45> %a,<2 x i45> %b)
 %external = call <2 x i45> @promoted_provider_2_45_c(<2 x i45> %a,<2 x i45> %b)
 store <2 x i45> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i45> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i45> @promoted_body_2_45_fast(<2 x i45> %a,<2 x i45> %b) noinline {
entry:
 %r = add <2 x i45> %a,%b
 ret <2 x i45> %r
}
declare fastcc <2 x i45> @promoted_provider_2_45_fast(<2 x i45>,<2 x i45>)
define i64 @promoted_probe_2_45_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i45>,ptr %ap,align 1
 %b = load <2 x i45>,ptr %bp,align 1
 %local = call fastcc <2 x i45> @promoted_body_2_45_fast(<2 x i45> %a,<2 x i45> %b)
 %external = call fastcc <2 x i45> @promoted_provider_2_45_fast(<2 x i45> %a,<2 x i45> %b)
 store <2 x i45> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i45> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i46> @promoted_body_2_46_c(<2 x i46> %a,<2 x i46> %b) noinline {
entry:
 %r = add <2 x i46> %a,%b
 ret <2 x i46> %r
}
declare <2 x i46> @promoted_provider_2_46_c(<2 x i46>,<2 x i46>)
define i64 @promoted_probe_2_46_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i46>,ptr %ap,align 1
 %b = load <2 x i46>,ptr %bp,align 1
 %local = call <2 x i46> @promoted_body_2_46_c(<2 x i46> %a,<2 x i46> %b)
 %external = call <2 x i46> @promoted_provider_2_46_c(<2 x i46> %a,<2 x i46> %b)
 store <2 x i46> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i46> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i46> @promoted_body_2_46_fast(<2 x i46> %a,<2 x i46> %b) noinline {
entry:
 %r = add <2 x i46> %a,%b
 ret <2 x i46> %r
}
declare fastcc <2 x i46> @promoted_provider_2_46_fast(<2 x i46>,<2 x i46>)
define i64 @promoted_probe_2_46_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i46>,ptr %ap,align 1
 %b = load <2 x i46>,ptr %bp,align 1
 %local = call fastcc <2 x i46> @promoted_body_2_46_fast(<2 x i46> %a,<2 x i46> %b)
 %external = call fastcc <2 x i46> @promoted_provider_2_46_fast(<2 x i46> %a,<2 x i46> %b)
 store <2 x i46> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i46> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i47> @promoted_body_2_47_c(<2 x i47> %a,<2 x i47> %b) noinline {
entry:
 %r = add <2 x i47> %a,%b
 ret <2 x i47> %r
}
declare <2 x i47> @promoted_provider_2_47_c(<2 x i47>,<2 x i47>)
define i64 @promoted_probe_2_47_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i47>,ptr %ap,align 1
 %b = load <2 x i47>,ptr %bp,align 1
 %local = call <2 x i47> @promoted_body_2_47_c(<2 x i47> %a,<2 x i47> %b)
 %external = call <2 x i47> @promoted_provider_2_47_c(<2 x i47> %a,<2 x i47> %b)
 store <2 x i47> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i47> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i47> @promoted_body_2_47_fast(<2 x i47> %a,<2 x i47> %b) noinline {
entry:
 %r = add <2 x i47> %a,%b
 ret <2 x i47> %r
}
declare fastcc <2 x i47> @promoted_provider_2_47_fast(<2 x i47>,<2 x i47>)
define i64 @promoted_probe_2_47_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i47>,ptr %ap,align 1
 %b = load <2 x i47>,ptr %bp,align 1
 %local = call fastcc <2 x i47> @promoted_body_2_47_fast(<2 x i47> %a,<2 x i47> %b)
 %external = call fastcc <2 x i47> @promoted_provider_2_47_fast(<2 x i47> %a,<2 x i47> %b)
 store <2 x i47> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i47> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i48> @promoted_body_2_48_c(<2 x i48> %a,<2 x i48> %b) noinline {
entry:
 %r = add <2 x i48> %a,%b
 ret <2 x i48> %r
}
declare <2 x i48> @promoted_provider_2_48_c(<2 x i48>,<2 x i48>)
define i64 @promoted_probe_2_48_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i48>,ptr %ap,align 1
 %b = load <2 x i48>,ptr %bp,align 1
 %local = call <2 x i48> @promoted_body_2_48_c(<2 x i48> %a,<2 x i48> %b)
 %external = call <2 x i48> @promoted_provider_2_48_c(<2 x i48> %a,<2 x i48> %b)
 store <2 x i48> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i48> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i48> @promoted_body_2_48_fast(<2 x i48> %a,<2 x i48> %b) noinline {
entry:
 %r = add <2 x i48> %a,%b
 ret <2 x i48> %r
}
declare fastcc <2 x i48> @promoted_provider_2_48_fast(<2 x i48>,<2 x i48>)
define i64 @promoted_probe_2_48_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i48>,ptr %ap,align 1
 %b = load <2 x i48>,ptr %bp,align 1
 %local = call fastcc <2 x i48> @promoted_body_2_48_fast(<2 x i48> %a,<2 x i48> %b)
 %external = call fastcc <2 x i48> @promoted_provider_2_48_fast(<2 x i48> %a,<2 x i48> %b)
 store <2 x i48> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i48> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i49> @promoted_body_2_49_c(<2 x i49> %a,<2 x i49> %b) noinline {
entry:
 %r = add <2 x i49> %a,%b
 ret <2 x i49> %r
}
declare <2 x i49> @promoted_provider_2_49_c(<2 x i49>,<2 x i49>)
define i64 @promoted_probe_2_49_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i49>,ptr %ap,align 1
 %b = load <2 x i49>,ptr %bp,align 1
 %local = call <2 x i49> @promoted_body_2_49_c(<2 x i49> %a,<2 x i49> %b)
 %external = call <2 x i49> @promoted_provider_2_49_c(<2 x i49> %a,<2 x i49> %b)
 store <2 x i49> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i49> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i49> @promoted_body_2_49_fast(<2 x i49> %a,<2 x i49> %b) noinline {
entry:
 %r = add <2 x i49> %a,%b
 ret <2 x i49> %r
}
declare fastcc <2 x i49> @promoted_provider_2_49_fast(<2 x i49>,<2 x i49>)
define i64 @promoted_probe_2_49_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i49>,ptr %ap,align 1
 %b = load <2 x i49>,ptr %bp,align 1
 %local = call fastcc <2 x i49> @promoted_body_2_49_fast(<2 x i49> %a,<2 x i49> %b)
 %external = call fastcc <2 x i49> @promoted_provider_2_49_fast(<2 x i49> %a,<2 x i49> %b)
 store <2 x i49> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i49> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i50> @promoted_body_2_50_c(<2 x i50> %a,<2 x i50> %b) noinline {
entry:
 %r = add <2 x i50> %a,%b
 ret <2 x i50> %r
}
declare <2 x i50> @promoted_provider_2_50_c(<2 x i50>,<2 x i50>)
define i64 @promoted_probe_2_50_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i50>,ptr %ap,align 1
 %b = load <2 x i50>,ptr %bp,align 1
 %local = call <2 x i50> @promoted_body_2_50_c(<2 x i50> %a,<2 x i50> %b)
 %external = call <2 x i50> @promoted_provider_2_50_c(<2 x i50> %a,<2 x i50> %b)
 store <2 x i50> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i50> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i50> @promoted_body_2_50_fast(<2 x i50> %a,<2 x i50> %b) noinline {
entry:
 %r = add <2 x i50> %a,%b
 ret <2 x i50> %r
}
declare fastcc <2 x i50> @promoted_provider_2_50_fast(<2 x i50>,<2 x i50>)
define i64 @promoted_probe_2_50_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i50>,ptr %ap,align 1
 %b = load <2 x i50>,ptr %bp,align 1
 %local = call fastcc <2 x i50> @promoted_body_2_50_fast(<2 x i50> %a,<2 x i50> %b)
 %external = call fastcc <2 x i50> @promoted_provider_2_50_fast(<2 x i50> %a,<2 x i50> %b)
 store <2 x i50> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i50> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i53> @promoted_body_2_53_c(<2 x i53> %a,<2 x i53> %b) noinline {
entry:
 %r = add <2 x i53> %a,%b
 ret <2 x i53> %r
}
declare <2 x i53> @promoted_provider_2_53_c(<2 x i53>,<2 x i53>)
define i64 @promoted_probe_2_53_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i53>,ptr %ap,align 1
 %b = load <2 x i53>,ptr %bp,align 1
 %local = call <2 x i53> @promoted_body_2_53_c(<2 x i53> %a,<2 x i53> %b)
 %external = call <2 x i53> @promoted_provider_2_53_c(<2 x i53> %a,<2 x i53> %b)
 store <2 x i53> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i53> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i53> @promoted_body_2_53_fast(<2 x i53> %a,<2 x i53> %b) noinline {
entry:
 %r = add <2 x i53> %a,%b
 ret <2 x i53> %r
}
declare fastcc <2 x i53> @promoted_provider_2_53_fast(<2 x i53>,<2 x i53>)
define i64 @promoted_probe_2_53_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i53>,ptr %ap,align 1
 %b = load <2 x i53>,ptr %bp,align 1
 %local = call fastcc <2 x i53> @promoted_body_2_53_fast(<2 x i53> %a,<2 x i53> %b)
 %external = call fastcc <2 x i53> @promoted_provider_2_53_fast(<2 x i53> %a,<2 x i53> %b)
 store <2 x i53> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i53> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i54> @promoted_body_2_54_c(<2 x i54> %a,<2 x i54> %b) noinline {
entry:
 %r = add <2 x i54> %a,%b
 ret <2 x i54> %r
}
declare <2 x i54> @promoted_provider_2_54_c(<2 x i54>,<2 x i54>)
define i64 @promoted_probe_2_54_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i54>,ptr %ap,align 1
 %b = load <2 x i54>,ptr %bp,align 1
 %local = call <2 x i54> @promoted_body_2_54_c(<2 x i54> %a,<2 x i54> %b)
 %external = call <2 x i54> @promoted_provider_2_54_c(<2 x i54> %a,<2 x i54> %b)
 store <2 x i54> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i54> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i54> @promoted_body_2_54_fast(<2 x i54> %a,<2 x i54> %b) noinline {
entry:
 %r = add <2 x i54> %a,%b
 ret <2 x i54> %r
}
declare fastcc <2 x i54> @promoted_provider_2_54_fast(<2 x i54>,<2 x i54>)
define i64 @promoted_probe_2_54_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i54>,ptr %ap,align 1
 %b = load <2 x i54>,ptr %bp,align 1
 %local = call fastcc <2 x i54> @promoted_body_2_54_fast(<2 x i54> %a,<2 x i54> %b)
 %external = call fastcc <2 x i54> @promoted_provider_2_54_fast(<2 x i54> %a,<2 x i54> %b)
 store <2 x i54> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i54> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i55> @promoted_body_2_55_c(<2 x i55> %a,<2 x i55> %b) noinline {
entry:
 %r = add <2 x i55> %a,%b
 ret <2 x i55> %r
}
declare <2 x i55> @promoted_provider_2_55_c(<2 x i55>,<2 x i55>)
define i64 @promoted_probe_2_55_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i55>,ptr %ap,align 1
 %b = load <2 x i55>,ptr %bp,align 1
 %local = call <2 x i55> @promoted_body_2_55_c(<2 x i55> %a,<2 x i55> %b)
 %external = call <2 x i55> @promoted_provider_2_55_c(<2 x i55> %a,<2 x i55> %b)
 store <2 x i55> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i55> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i55> @promoted_body_2_55_fast(<2 x i55> %a,<2 x i55> %b) noinline {
entry:
 %r = add <2 x i55> %a,%b
 ret <2 x i55> %r
}
declare fastcc <2 x i55> @promoted_provider_2_55_fast(<2 x i55>,<2 x i55>)
define i64 @promoted_probe_2_55_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i55>,ptr %ap,align 1
 %b = load <2 x i55>,ptr %bp,align 1
 %local = call fastcc <2 x i55> @promoted_body_2_55_fast(<2 x i55> %a,<2 x i55> %b)
 %external = call fastcc <2 x i55> @promoted_provider_2_55_fast(<2 x i55> %a,<2 x i55> %b)
 store <2 x i55> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i55> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i56> @promoted_body_2_56_c(<2 x i56> %a,<2 x i56> %b) noinline {
entry:
 %r = add <2 x i56> %a,%b
 ret <2 x i56> %r
}
declare <2 x i56> @promoted_provider_2_56_c(<2 x i56>,<2 x i56>)
define i64 @promoted_probe_2_56_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i56>,ptr %ap,align 1
 %b = load <2 x i56>,ptr %bp,align 1
 %local = call <2 x i56> @promoted_body_2_56_c(<2 x i56> %a,<2 x i56> %b)
 %external = call <2 x i56> @promoted_provider_2_56_c(<2 x i56> %a,<2 x i56> %b)
 store <2 x i56> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i56> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i56> @promoted_body_2_56_fast(<2 x i56> %a,<2 x i56> %b) noinline {
entry:
 %r = add <2 x i56> %a,%b
 ret <2 x i56> %r
}
declare fastcc <2 x i56> @promoted_provider_2_56_fast(<2 x i56>,<2 x i56>)
define i64 @promoted_probe_2_56_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i56>,ptr %ap,align 1
 %b = load <2 x i56>,ptr %bp,align 1
 %local = call fastcc <2 x i56> @promoted_body_2_56_fast(<2 x i56> %a,<2 x i56> %b)
 %external = call fastcc <2 x i56> @promoted_provider_2_56_fast(<2 x i56> %a,<2 x i56> %b)
 store <2 x i56> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i56> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i57> @promoted_body_2_57_c(<2 x i57> %a,<2 x i57> %b) noinline {
entry:
 %r = add <2 x i57> %a,%b
 ret <2 x i57> %r
}
declare <2 x i57> @promoted_provider_2_57_c(<2 x i57>,<2 x i57>)
define i64 @promoted_probe_2_57_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i57>,ptr %ap,align 1
 %b = load <2 x i57>,ptr %bp,align 1
 %local = call <2 x i57> @promoted_body_2_57_c(<2 x i57> %a,<2 x i57> %b)
 %external = call <2 x i57> @promoted_provider_2_57_c(<2 x i57> %a,<2 x i57> %b)
 store <2 x i57> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i57> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i57> @promoted_body_2_57_fast(<2 x i57> %a,<2 x i57> %b) noinline {
entry:
 %r = add <2 x i57> %a,%b
 ret <2 x i57> %r
}
declare fastcc <2 x i57> @promoted_provider_2_57_fast(<2 x i57>,<2 x i57>)
define i64 @promoted_probe_2_57_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i57>,ptr %ap,align 1
 %b = load <2 x i57>,ptr %bp,align 1
 %local = call fastcc <2 x i57> @promoted_body_2_57_fast(<2 x i57> %a,<2 x i57> %b)
 %external = call fastcc <2 x i57> @promoted_provider_2_57_fast(<2 x i57> %a,<2 x i57> %b)
 store <2 x i57> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i57> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i58> @promoted_body_2_58_c(<2 x i58> %a,<2 x i58> %b) noinline {
entry:
 %r = add <2 x i58> %a,%b
 ret <2 x i58> %r
}
declare <2 x i58> @promoted_provider_2_58_c(<2 x i58>,<2 x i58>)
define i64 @promoted_probe_2_58_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i58>,ptr %ap,align 1
 %b = load <2 x i58>,ptr %bp,align 1
 %local = call <2 x i58> @promoted_body_2_58_c(<2 x i58> %a,<2 x i58> %b)
 %external = call <2 x i58> @promoted_provider_2_58_c(<2 x i58> %a,<2 x i58> %b)
 store <2 x i58> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i58> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i58> @promoted_body_2_58_fast(<2 x i58> %a,<2 x i58> %b) noinline {
entry:
 %r = add <2 x i58> %a,%b
 ret <2 x i58> %r
}
declare fastcc <2 x i58> @promoted_provider_2_58_fast(<2 x i58>,<2 x i58>)
define i64 @promoted_probe_2_58_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i58>,ptr %ap,align 1
 %b = load <2 x i58>,ptr %bp,align 1
 %local = call fastcc <2 x i58> @promoted_body_2_58_fast(<2 x i58> %a,<2 x i58> %b)
 %external = call fastcc <2 x i58> @promoted_provider_2_58_fast(<2 x i58> %a,<2 x i58> %b)
 store <2 x i58> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i58> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i59> @promoted_body_2_59_c(<2 x i59> %a,<2 x i59> %b) noinline {
entry:
 %r = add <2 x i59> %a,%b
 ret <2 x i59> %r
}
declare <2 x i59> @promoted_provider_2_59_c(<2 x i59>,<2 x i59>)
define i64 @promoted_probe_2_59_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i59>,ptr %ap,align 1
 %b = load <2 x i59>,ptr %bp,align 1
 %local = call <2 x i59> @promoted_body_2_59_c(<2 x i59> %a,<2 x i59> %b)
 %external = call <2 x i59> @promoted_provider_2_59_c(<2 x i59> %a,<2 x i59> %b)
 store <2 x i59> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i59> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i59> @promoted_body_2_59_fast(<2 x i59> %a,<2 x i59> %b) noinline {
entry:
 %r = add <2 x i59> %a,%b
 ret <2 x i59> %r
}
declare fastcc <2 x i59> @promoted_provider_2_59_fast(<2 x i59>,<2 x i59>)
define i64 @promoted_probe_2_59_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i59>,ptr %ap,align 1
 %b = load <2 x i59>,ptr %bp,align 1
 %local = call fastcc <2 x i59> @promoted_body_2_59_fast(<2 x i59> %a,<2 x i59> %b)
 %external = call fastcc <2 x i59> @promoted_provider_2_59_fast(<2 x i59> %a,<2 x i59> %b)
 store <2 x i59> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i59> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i60> @promoted_body_2_60_c(<2 x i60> %a,<2 x i60> %b) noinline {
entry:
 %r = add <2 x i60> %a,%b
 ret <2 x i60> %r
}
declare <2 x i60> @promoted_provider_2_60_c(<2 x i60>,<2 x i60>)
define i64 @promoted_probe_2_60_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i60>,ptr %ap,align 1
 %b = load <2 x i60>,ptr %bp,align 1
 %local = call <2 x i60> @promoted_body_2_60_c(<2 x i60> %a,<2 x i60> %b)
 %external = call <2 x i60> @promoted_provider_2_60_c(<2 x i60> %a,<2 x i60> %b)
 store <2 x i60> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i60> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i60> @promoted_body_2_60_fast(<2 x i60> %a,<2 x i60> %b) noinline {
entry:
 %r = add <2 x i60> %a,%b
 ret <2 x i60> %r
}
declare fastcc <2 x i60> @promoted_provider_2_60_fast(<2 x i60>,<2 x i60>)
define i64 @promoted_probe_2_60_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i60>,ptr %ap,align 1
 %b = load <2 x i60>,ptr %bp,align 1
 %local = call fastcc <2 x i60> @promoted_body_2_60_fast(<2 x i60> %a,<2 x i60> %b)
 %external = call fastcc <2 x i60> @promoted_provider_2_60_fast(<2 x i60> %a,<2 x i60> %b)
 store <2 x i60> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i60> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i61> @promoted_body_2_61_c(<2 x i61> %a,<2 x i61> %b) noinline {
entry:
 %r = add <2 x i61> %a,%b
 ret <2 x i61> %r
}
declare <2 x i61> @promoted_provider_2_61_c(<2 x i61>,<2 x i61>)
define i64 @promoted_probe_2_61_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i61>,ptr %ap,align 1
 %b = load <2 x i61>,ptr %bp,align 1
 %local = call <2 x i61> @promoted_body_2_61_c(<2 x i61> %a,<2 x i61> %b)
 %external = call <2 x i61> @promoted_provider_2_61_c(<2 x i61> %a,<2 x i61> %b)
 store <2 x i61> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i61> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i61> @promoted_body_2_61_fast(<2 x i61> %a,<2 x i61> %b) noinline {
entry:
 %r = add <2 x i61> %a,%b
 ret <2 x i61> %r
}
declare fastcc <2 x i61> @promoted_provider_2_61_fast(<2 x i61>,<2 x i61>)
define i64 @promoted_probe_2_61_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i61>,ptr %ap,align 1
 %b = load <2 x i61>,ptr %bp,align 1
 %local = call fastcc <2 x i61> @promoted_body_2_61_fast(<2 x i61> %a,<2 x i61> %b)
 %external = call fastcc <2 x i61> @promoted_provider_2_61_fast(<2 x i61> %a,<2 x i61> %b)
 store <2 x i61> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i61> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i62> @promoted_body_2_62_c(<2 x i62> %a,<2 x i62> %b) noinline {
entry:
 %r = add <2 x i62> %a,%b
 ret <2 x i62> %r
}
declare <2 x i62> @promoted_provider_2_62_c(<2 x i62>,<2 x i62>)
define i64 @promoted_probe_2_62_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i62>,ptr %ap,align 1
 %b = load <2 x i62>,ptr %bp,align 1
 %local = call <2 x i62> @promoted_body_2_62_c(<2 x i62> %a,<2 x i62> %b)
 %external = call <2 x i62> @promoted_provider_2_62_c(<2 x i62> %a,<2 x i62> %b)
 store <2 x i62> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i62> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i62> @promoted_body_2_62_fast(<2 x i62> %a,<2 x i62> %b) noinline {
entry:
 %r = add <2 x i62> %a,%b
 ret <2 x i62> %r
}
declare fastcc <2 x i62> @promoted_provider_2_62_fast(<2 x i62>,<2 x i62>)
define i64 @promoted_probe_2_62_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i62>,ptr %ap,align 1
 %b = load <2 x i62>,ptr %bp,align 1
 %local = call fastcc <2 x i62> @promoted_body_2_62_fast(<2 x i62> %a,<2 x i62> %b)
 %external = call fastcc <2 x i62> @promoted_provider_2_62_fast(<2 x i62> %a,<2 x i62> %b)
 store <2 x i62> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i62> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <2 x i63> @promoted_body_2_63_c(<2 x i63> %a,<2 x i63> %b) noinline {
entry:
 %r = add <2 x i63> %a,%b
 ret <2 x i63> %r
}
declare <2 x i63> @promoted_provider_2_63_c(<2 x i63>,<2 x i63>)
define i64 @promoted_probe_2_63_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i63>,ptr %ap,align 1
 %b = load <2 x i63>,ptr %bp,align 1
 %local = call <2 x i63> @promoted_body_2_63_c(<2 x i63> %a,<2 x i63> %b)
 %external = call <2 x i63> @promoted_provider_2_63_c(<2 x i63> %a,<2 x i63> %b)
 store <2 x i63> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i63> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <2 x i63> @promoted_body_2_63_fast(<2 x i63> %a,<2 x i63> %b) noinline {
entry:
 %r = add <2 x i63> %a,%b
 ret <2 x i63> %r
}
declare fastcc <2 x i63> @promoted_provider_2_63_fast(<2 x i63>,<2 x i63>)
define i64 @promoted_probe_2_63_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <2 x i63>,ptr %ap,align 1
 %b = load <2 x i63>,ptr %bp,align 1
 %local = call fastcc <2 x i63> @promoted_body_2_63_fast(<2 x i63> %a,<2 x i63> %b)
 %external = call fastcc <2 x i63> @promoted_provider_2_63_fast(<2 x i63> %a,<2 x i63> %b)
 store <2 x i63> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <2 x i63> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
