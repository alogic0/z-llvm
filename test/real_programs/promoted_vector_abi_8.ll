target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
define <8 x i1> @promoted_body_8_1_c(<8 x i1> %a,<8 x i1> %b) noinline {
entry:
 %r = add <8 x i1> %a,%b
 ret <8 x i1> %r
}
declare <8 x i1> @promoted_provider_8_1_c(<8 x i1>,<8 x i1>)
define i64 @promoted_probe_8_1_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <8 x i1>,ptr %ap,align 1
 %b = load <8 x i1>,ptr %bp,align 1
 %local = call <8 x i1> @promoted_body_8_1_c(<8 x i1> %a,<8 x i1> %b)
 %external = call <8 x i1> @promoted_provider_8_1_c(<8 x i1> %a,<8 x i1> %b)
 store <8 x i1> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <8 x i1> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <8 x i1> @promoted_body_8_1_fast(<8 x i1> %a,<8 x i1> %b) noinline {
entry:
 %r = add <8 x i1> %a,%b
 ret <8 x i1> %r
}
declare fastcc <8 x i1> @promoted_provider_8_1_fast(<8 x i1>,<8 x i1>)
define i64 @promoted_probe_8_1_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <8 x i1>,ptr %ap,align 1
 %b = load <8 x i1>,ptr %bp,align 1
 %local = call fastcc <8 x i1> @promoted_body_8_1_fast(<8 x i1> %a,<8 x i1> %b)
 %external = call fastcc <8 x i1> @promoted_provider_8_1_fast(<8 x i1> %a,<8 x i1> %b)
 store <8 x i1> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <8 x i1> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <8 x i2> @promoted_body_8_2_c(<8 x i2> %a,<8 x i2> %b) noinline {
entry:
 %r = add <8 x i2> %a,%b
 ret <8 x i2> %r
}
declare <8 x i2> @promoted_provider_8_2_c(<8 x i2>,<8 x i2>)
define i64 @promoted_probe_8_2_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <8 x i2>,ptr %ap,align 1
 %b = load <8 x i2>,ptr %bp,align 1
 %local = call <8 x i2> @promoted_body_8_2_c(<8 x i2> %a,<8 x i2> %b)
 %external = call <8 x i2> @promoted_provider_8_2_c(<8 x i2> %a,<8 x i2> %b)
 store <8 x i2> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <8 x i2> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <8 x i2> @promoted_body_8_2_fast(<8 x i2> %a,<8 x i2> %b) noinline {
entry:
 %r = add <8 x i2> %a,%b
 ret <8 x i2> %r
}
declare fastcc <8 x i2> @promoted_provider_8_2_fast(<8 x i2>,<8 x i2>)
define i64 @promoted_probe_8_2_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <8 x i2>,ptr %ap,align 1
 %b = load <8 x i2>,ptr %bp,align 1
 %local = call fastcc <8 x i2> @promoted_body_8_2_fast(<8 x i2> %a,<8 x i2> %b)
 %external = call fastcc <8 x i2> @promoted_provider_8_2_fast(<8 x i2> %a,<8 x i2> %b)
 store <8 x i2> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <8 x i2> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <8 x i3> @promoted_body_8_3_c(<8 x i3> %a,<8 x i3> %b) noinline {
entry:
 %r = add <8 x i3> %a,%b
 ret <8 x i3> %r
}
declare <8 x i3> @promoted_provider_8_3_c(<8 x i3>,<8 x i3>)
define i64 @promoted_probe_8_3_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <8 x i3>,ptr %ap,align 1
 %b = load <8 x i3>,ptr %bp,align 1
 %local = call <8 x i3> @promoted_body_8_3_c(<8 x i3> %a,<8 x i3> %b)
 %external = call <8 x i3> @promoted_provider_8_3_c(<8 x i3> %a,<8 x i3> %b)
 store <8 x i3> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <8 x i3> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <8 x i3> @promoted_body_8_3_fast(<8 x i3> %a,<8 x i3> %b) noinline {
entry:
 %r = add <8 x i3> %a,%b
 ret <8 x i3> %r
}
declare fastcc <8 x i3> @promoted_provider_8_3_fast(<8 x i3>,<8 x i3>)
define i64 @promoted_probe_8_3_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <8 x i3>,ptr %ap,align 1
 %b = load <8 x i3>,ptr %bp,align 1
 %local = call fastcc <8 x i3> @promoted_body_8_3_fast(<8 x i3> %a,<8 x i3> %b)
 %external = call fastcc <8 x i3> @promoted_provider_8_3_fast(<8 x i3> %a,<8 x i3> %b)
 store <8 x i3> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <8 x i3> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <8 x i4> @promoted_body_8_4_c(<8 x i4> %a,<8 x i4> %b) noinline {
entry:
 %r = add <8 x i4> %a,%b
 ret <8 x i4> %r
}
declare <8 x i4> @promoted_provider_8_4_c(<8 x i4>,<8 x i4>)
define i64 @promoted_probe_8_4_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <8 x i4>,ptr %ap,align 1
 %b = load <8 x i4>,ptr %bp,align 1
 %local = call <8 x i4> @promoted_body_8_4_c(<8 x i4> %a,<8 x i4> %b)
 %external = call <8 x i4> @promoted_provider_8_4_c(<8 x i4> %a,<8 x i4> %b)
 store <8 x i4> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <8 x i4> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <8 x i4> @promoted_body_8_4_fast(<8 x i4> %a,<8 x i4> %b) noinline {
entry:
 %r = add <8 x i4> %a,%b
 ret <8 x i4> %r
}
declare fastcc <8 x i4> @promoted_provider_8_4_fast(<8 x i4>,<8 x i4>)
define i64 @promoted_probe_8_4_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <8 x i4>,ptr %ap,align 1
 %b = load <8 x i4>,ptr %bp,align 1
 %local = call fastcc <8 x i4> @promoted_body_8_4_fast(<8 x i4> %a,<8 x i4> %b)
 %external = call fastcc <8 x i4> @promoted_provider_8_4_fast(<8 x i4> %a,<8 x i4> %b)
 store <8 x i4> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <8 x i4> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <8 x i5> @promoted_body_8_5_c(<8 x i5> %a,<8 x i5> %b) noinline {
entry:
 %r = add <8 x i5> %a,%b
 ret <8 x i5> %r
}
declare <8 x i5> @promoted_provider_8_5_c(<8 x i5>,<8 x i5>)
define i64 @promoted_probe_8_5_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <8 x i5>,ptr %ap,align 1
 %b = load <8 x i5>,ptr %bp,align 1
 %local = call <8 x i5> @promoted_body_8_5_c(<8 x i5> %a,<8 x i5> %b)
 %external = call <8 x i5> @promoted_provider_8_5_c(<8 x i5> %a,<8 x i5> %b)
 store <8 x i5> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <8 x i5> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <8 x i5> @promoted_body_8_5_fast(<8 x i5> %a,<8 x i5> %b) noinline {
entry:
 %r = add <8 x i5> %a,%b
 ret <8 x i5> %r
}
declare fastcc <8 x i5> @promoted_provider_8_5_fast(<8 x i5>,<8 x i5>)
define i64 @promoted_probe_8_5_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <8 x i5>,ptr %ap,align 1
 %b = load <8 x i5>,ptr %bp,align 1
 %local = call fastcc <8 x i5> @promoted_body_8_5_fast(<8 x i5> %a,<8 x i5> %b)
 %external = call fastcc <8 x i5> @promoted_provider_8_5_fast(<8 x i5> %a,<8 x i5> %b)
 store <8 x i5> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <8 x i5> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <8 x i6> @promoted_body_8_6_c(<8 x i6> %a,<8 x i6> %b) noinline {
entry:
 %r = add <8 x i6> %a,%b
 ret <8 x i6> %r
}
declare <8 x i6> @promoted_provider_8_6_c(<8 x i6>,<8 x i6>)
define i64 @promoted_probe_8_6_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <8 x i6>,ptr %ap,align 1
 %b = load <8 x i6>,ptr %bp,align 1
 %local = call <8 x i6> @promoted_body_8_6_c(<8 x i6> %a,<8 x i6> %b)
 %external = call <8 x i6> @promoted_provider_8_6_c(<8 x i6> %a,<8 x i6> %b)
 store <8 x i6> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <8 x i6> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <8 x i6> @promoted_body_8_6_fast(<8 x i6> %a,<8 x i6> %b) noinline {
entry:
 %r = add <8 x i6> %a,%b
 ret <8 x i6> %r
}
declare fastcc <8 x i6> @promoted_provider_8_6_fast(<8 x i6>,<8 x i6>)
define i64 @promoted_probe_8_6_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <8 x i6>,ptr %ap,align 1
 %b = load <8 x i6>,ptr %bp,align 1
 %local = call fastcc <8 x i6> @promoted_body_8_6_fast(<8 x i6> %a,<8 x i6> %b)
 %external = call fastcc <8 x i6> @promoted_provider_8_6_fast(<8 x i6> %a,<8 x i6> %b)
 store <8 x i6> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <8 x i6> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <8 x i7> @promoted_body_8_7_c(<8 x i7> %a,<8 x i7> %b) noinline {
entry:
 %r = add <8 x i7> %a,%b
 ret <8 x i7> %r
}
declare <8 x i7> @promoted_provider_8_7_c(<8 x i7>,<8 x i7>)
define i64 @promoted_probe_8_7_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <8 x i7>,ptr %ap,align 1
 %b = load <8 x i7>,ptr %bp,align 1
 %local = call <8 x i7> @promoted_body_8_7_c(<8 x i7> %a,<8 x i7> %b)
 %external = call <8 x i7> @promoted_provider_8_7_c(<8 x i7> %a,<8 x i7> %b)
 store <8 x i7> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <8 x i7> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <8 x i7> @promoted_body_8_7_fast(<8 x i7> %a,<8 x i7> %b) noinline {
entry:
 %r = add <8 x i7> %a,%b
 ret <8 x i7> %r
}
declare fastcc <8 x i7> @promoted_provider_8_7_fast(<8 x i7>,<8 x i7>)
define i64 @promoted_probe_8_7_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <8 x i7>,ptr %ap,align 1
 %b = load <8 x i7>,ptr %bp,align 1
 %local = call fastcc <8 x i7> @promoted_body_8_7_fast(<8 x i7> %a,<8 x i7> %b)
 %external = call fastcc <8 x i7> @promoted_provider_8_7_fast(<8 x i7> %a,<8 x i7> %b)
 store <8 x i7> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <8 x i7> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <8 x i9> @promoted_body_8_9_c(<8 x i9> %a,<8 x i9> %b) noinline {
entry:
 %r = add <8 x i9> %a,%b
 ret <8 x i9> %r
}
declare <8 x i9> @promoted_provider_8_9_c(<8 x i9>,<8 x i9>)
define i64 @promoted_probe_8_9_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <8 x i9>,ptr %ap,align 1
 %b = load <8 x i9>,ptr %bp,align 1
 %local = call <8 x i9> @promoted_body_8_9_c(<8 x i9> %a,<8 x i9> %b)
 %external = call <8 x i9> @promoted_provider_8_9_c(<8 x i9> %a,<8 x i9> %b)
 store <8 x i9> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <8 x i9> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <8 x i9> @promoted_body_8_9_fast(<8 x i9> %a,<8 x i9> %b) noinline {
entry:
 %r = add <8 x i9> %a,%b
 ret <8 x i9> %r
}
declare fastcc <8 x i9> @promoted_provider_8_9_fast(<8 x i9>,<8 x i9>)
define i64 @promoted_probe_8_9_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <8 x i9>,ptr %ap,align 1
 %b = load <8 x i9>,ptr %bp,align 1
 %local = call fastcc <8 x i9> @promoted_body_8_9_fast(<8 x i9> %a,<8 x i9> %b)
 %external = call fastcc <8 x i9> @promoted_provider_8_9_fast(<8 x i9> %a,<8 x i9> %b)
 store <8 x i9> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <8 x i9> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <8 x i10> @promoted_body_8_10_c(<8 x i10> %a,<8 x i10> %b) noinline {
entry:
 %r = add <8 x i10> %a,%b
 ret <8 x i10> %r
}
declare <8 x i10> @promoted_provider_8_10_c(<8 x i10>,<8 x i10>)
define i64 @promoted_probe_8_10_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <8 x i10>,ptr %ap,align 1
 %b = load <8 x i10>,ptr %bp,align 1
 %local = call <8 x i10> @promoted_body_8_10_c(<8 x i10> %a,<8 x i10> %b)
 %external = call <8 x i10> @promoted_provider_8_10_c(<8 x i10> %a,<8 x i10> %b)
 store <8 x i10> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <8 x i10> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <8 x i10> @promoted_body_8_10_fast(<8 x i10> %a,<8 x i10> %b) noinline {
entry:
 %r = add <8 x i10> %a,%b
 ret <8 x i10> %r
}
declare fastcc <8 x i10> @promoted_provider_8_10_fast(<8 x i10>,<8 x i10>)
define i64 @promoted_probe_8_10_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <8 x i10>,ptr %ap,align 1
 %b = load <8 x i10>,ptr %bp,align 1
 %local = call fastcc <8 x i10> @promoted_body_8_10_fast(<8 x i10> %a,<8 x i10> %b)
 %external = call fastcc <8 x i10> @promoted_provider_8_10_fast(<8 x i10> %a,<8 x i10> %b)
 store <8 x i10> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <8 x i10> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <8 x i11> @promoted_body_8_11_c(<8 x i11> %a,<8 x i11> %b) noinline {
entry:
 %r = add <8 x i11> %a,%b
 ret <8 x i11> %r
}
declare <8 x i11> @promoted_provider_8_11_c(<8 x i11>,<8 x i11>)
define i64 @promoted_probe_8_11_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <8 x i11>,ptr %ap,align 1
 %b = load <8 x i11>,ptr %bp,align 1
 %local = call <8 x i11> @promoted_body_8_11_c(<8 x i11> %a,<8 x i11> %b)
 %external = call <8 x i11> @promoted_provider_8_11_c(<8 x i11> %a,<8 x i11> %b)
 store <8 x i11> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <8 x i11> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <8 x i11> @promoted_body_8_11_fast(<8 x i11> %a,<8 x i11> %b) noinline {
entry:
 %r = add <8 x i11> %a,%b
 ret <8 x i11> %r
}
declare fastcc <8 x i11> @promoted_provider_8_11_fast(<8 x i11>,<8 x i11>)
define i64 @promoted_probe_8_11_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <8 x i11>,ptr %ap,align 1
 %b = load <8 x i11>,ptr %bp,align 1
 %local = call fastcc <8 x i11> @promoted_body_8_11_fast(<8 x i11> %a,<8 x i11> %b)
 %external = call fastcc <8 x i11> @promoted_provider_8_11_fast(<8 x i11> %a,<8 x i11> %b)
 store <8 x i11> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <8 x i11> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <8 x i12> @promoted_body_8_12_c(<8 x i12> %a,<8 x i12> %b) noinline {
entry:
 %r = add <8 x i12> %a,%b
 ret <8 x i12> %r
}
declare <8 x i12> @promoted_provider_8_12_c(<8 x i12>,<8 x i12>)
define i64 @promoted_probe_8_12_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <8 x i12>,ptr %ap,align 1
 %b = load <8 x i12>,ptr %bp,align 1
 %local = call <8 x i12> @promoted_body_8_12_c(<8 x i12> %a,<8 x i12> %b)
 %external = call <8 x i12> @promoted_provider_8_12_c(<8 x i12> %a,<8 x i12> %b)
 store <8 x i12> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <8 x i12> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <8 x i12> @promoted_body_8_12_fast(<8 x i12> %a,<8 x i12> %b) noinline {
entry:
 %r = add <8 x i12> %a,%b
 ret <8 x i12> %r
}
declare fastcc <8 x i12> @promoted_provider_8_12_fast(<8 x i12>,<8 x i12>)
define i64 @promoted_probe_8_12_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <8 x i12>,ptr %ap,align 1
 %b = load <8 x i12>,ptr %bp,align 1
 %local = call fastcc <8 x i12> @promoted_body_8_12_fast(<8 x i12> %a,<8 x i12> %b)
 %external = call fastcc <8 x i12> @promoted_provider_8_12_fast(<8 x i12> %a,<8 x i12> %b)
 store <8 x i12> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <8 x i12> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <8 x i13> @promoted_body_8_13_c(<8 x i13> %a,<8 x i13> %b) noinline {
entry:
 %r = add <8 x i13> %a,%b
 ret <8 x i13> %r
}
declare <8 x i13> @promoted_provider_8_13_c(<8 x i13>,<8 x i13>)
define i64 @promoted_probe_8_13_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <8 x i13>,ptr %ap,align 1
 %b = load <8 x i13>,ptr %bp,align 1
 %local = call <8 x i13> @promoted_body_8_13_c(<8 x i13> %a,<8 x i13> %b)
 %external = call <8 x i13> @promoted_provider_8_13_c(<8 x i13> %a,<8 x i13> %b)
 store <8 x i13> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <8 x i13> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <8 x i13> @promoted_body_8_13_fast(<8 x i13> %a,<8 x i13> %b) noinline {
entry:
 %r = add <8 x i13> %a,%b
 ret <8 x i13> %r
}
declare fastcc <8 x i13> @promoted_provider_8_13_fast(<8 x i13>,<8 x i13>)
define i64 @promoted_probe_8_13_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <8 x i13>,ptr %ap,align 1
 %b = load <8 x i13>,ptr %bp,align 1
 %local = call fastcc <8 x i13> @promoted_body_8_13_fast(<8 x i13> %a,<8 x i13> %b)
 %external = call fastcc <8 x i13> @promoted_provider_8_13_fast(<8 x i13> %a,<8 x i13> %b)
 store <8 x i13> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <8 x i13> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <8 x i14> @promoted_body_8_14_c(<8 x i14> %a,<8 x i14> %b) noinline {
entry:
 %r = add <8 x i14> %a,%b
 ret <8 x i14> %r
}
declare <8 x i14> @promoted_provider_8_14_c(<8 x i14>,<8 x i14>)
define i64 @promoted_probe_8_14_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <8 x i14>,ptr %ap,align 1
 %b = load <8 x i14>,ptr %bp,align 1
 %local = call <8 x i14> @promoted_body_8_14_c(<8 x i14> %a,<8 x i14> %b)
 %external = call <8 x i14> @promoted_provider_8_14_c(<8 x i14> %a,<8 x i14> %b)
 store <8 x i14> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <8 x i14> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <8 x i14> @promoted_body_8_14_fast(<8 x i14> %a,<8 x i14> %b) noinline {
entry:
 %r = add <8 x i14> %a,%b
 ret <8 x i14> %r
}
declare fastcc <8 x i14> @promoted_provider_8_14_fast(<8 x i14>,<8 x i14>)
define i64 @promoted_probe_8_14_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <8 x i14>,ptr %ap,align 1
 %b = load <8 x i14>,ptr %bp,align 1
 %local = call fastcc <8 x i14> @promoted_body_8_14_fast(<8 x i14> %a,<8 x i14> %b)
 %external = call fastcc <8 x i14> @promoted_provider_8_14_fast(<8 x i14> %a,<8 x i14> %b)
 store <8 x i14> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <8 x i14> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define <8 x i15> @promoted_body_8_15_c(<8 x i15> %a,<8 x i15> %b) noinline {
entry:
 %r = add <8 x i15> %a,%b
 ret <8 x i15> %r
}
declare <8 x i15> @promoted_provider_8_15_c(<8 x i15>,<8 x i15>)
define i64 @promoted_probe_8_15_c(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <8 x i15>,ptr %ap,align 1
 %b = load <8 x i15>,ptr %bp,align 1
 %local = call <8 x i15> @promoted_body_8_15_c(<8 x i15> %a,<8 x i15> %b)
 %external = call <8 x i15> @promoted_provider_8_15_c(<8 x i15> %a,<8 x i15> %b)
 store <8 x i15> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <8 x i15> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc <8 x i15> @promoted_body_8_15_fast(<8 x i15> %a,<8 x i15> %b) noinline {
entry:
 %r = add <8 x i15> %a,%b
 ret <8 x i15> %r
}
declare fastcc <8 x i15> @promoted_provider_8_15_fast(<8 x i15>,<8 x i15>)
define i64 @promoted_probe_8_15_fast(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load <8 x i15>,ptr %ap,align 1
 %b = load <8 x i15>,ptr %bp,align 1
 %local = call fastcc <8 x i15> @promoted_body_8_15_fast(<8 x i15> %a,<8 x i15> %b)
 %external = call fastcc <8 x i15> @promoted_provider_8_15_fast(<8 x i15> %a,<8 x i15> %b)
 store <8 x i15> %local,ptr %out,align 1
 %out1 = getelementptr i8,ptr %out,i64 16
 store <8 x i15> %external,ptr %out1,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
