target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare i128 @llvm.ushl.sat.i128(i128,i128)
declare i128 @llvm.sshl.sat.i128(i128,i128)
declare i128 @llvm.umul.fix.sat.i128(i128,i128,i32 immarg)
declare i128 @llvm.smul.fix.sat.i128(i128,i128,i32 immarg)
define i128 @pair_extended_body_0(i128 %a,i128 %b) noinline {
entry:
 %n = and i128 %b,127
 %v = call i128 @llvm.ushl.sat.i128(i128 %a,i128 %n)
 %r = xor i128 %v,%b
 ret i128 %r
}
declare i128 @pair_extended_provider_0(i128,i128)
define i64 @pair_extended_probe_0(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load i128,ptr %ap,align 1
 %b = load i128,ptr %bp,align 1
 %local = call i128 @pair_extended_body_0(i128 %a,i128 %b)
 %external = call i128 @pair_extended_provider_0(i128 %a,i128 %b)
 store i128 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 16
 store i128 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i128 @pair_extended_body_1(i128 %a,i128 %b) noinline {
entry:
 %n = and i128 %b,127
 %v = call i128 @llvm.sshl.sat.i128(i128 %a,i128 %n)
 %r = xor i128 %v,%b
 ret i128 %r
}
declare i128 @pair_extended_provider_1(i128,i128)
define i64 @pair_extended_probe_1(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load i128,ptr %ap,align 1
 %b = load i128,ptr %bp,align 1
 %local = call i128 @pair_extended_body_1(i128 %a,i128 %b)
 %external = call i128 @pair_extended_provider_1(i128 %a,i128 %b)
 store i128 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 16
 store i128 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i128 @pair_extended_body_2(i128 %a,i128 %b) noinline {
entry:
 %n = and i128 %b,127
 %v = call i128 @llvm.umul.fix.sat.i128(i128 %a,i128 %b,i32 0)
 %r = xor i128 %v,%b
 ret i128 %r
}
declare i128 @pair_extended_provider_2(i128,i128)
define i64 @pair_extended_probe_2(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load i128,ptr %ap,align 1
 %b = load i128,ptr %bp,align 1
 %local = call i128 @pair_extended_body_2(i128 %a,i128 %b)
 %external = call i128 @pair_extended_provider_2(i128 %a,i128 %b)
 store i128 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 16
 store i128 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i128 @pair_extended_body_3(i128 %a,i128 %b) noinline {
entry:
 %n = and i128 %b,127
 %v = call i128 @llvm.smul.fix.sat.i128(i128 %a,i128 %b,i32 0)
 %r = xor i128 %v,%b
 ret i128 %r
}
declare i128 @pair_extended_provider_3(i128,i128)
define i64 @pair_extended_probe_3(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load i128,ptr %ap,align 1
 %b = load i128,ptr %bp,align 1
 %local = call i128 @pair_extended_body_3(i128 %a,i128 %b)
 %external = call i128 @pair_extended_provider_3(i128 %a,i128 %b)
 store i128 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 16
 store i128 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i128 @pair_extended_body_4(i128 %a,i128 %b) noinline {
entry:
 %n = and i128 %b,127
 %v = call i128 @llvm.ushl.sat.i128(i128 %a,i128 %n)
 %r = xor i128 %v,%b
 ret i128 %r
}
declare i128 @pair_extended_provider_4(i128,i128)
define i64 @pair_extended_probe_4(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load i128,ptr %ap,align 1
 %b = load i128,ptr %bp,align 1
 %local = call fastcc i128 @pair_extended_body_4(i128 %a,i128 %b)
 %external = call i128 @pair_extended_provider_4(i128 %a,i128 %b)
 store i128 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 16
 store i128 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i128 @pair_extended_body_5(i128 %a,i128 %b) noinline {
entry:
 %n = and i128 %b,127
 %v = call i128 @llvm.sshl.sat.i128(i128 %a,i128 %n)
 %r = xor i128 %v,%b
 ret i128 %r
}
declare i128 @pair_extended_provider_5(i128,i128)
define i64 @pair_extended_probe_5(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load i128,ptr %ap,align 1
 %b = load i128,ptr %bp,align 1
 %local = call fastcc i128 @pair_extended_body_5(i128 %a,i128 %b)
 %external = call i128 @pair_extended_provider_5(i128 %a,i128 %b)
 store i128 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 16
 store i128 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i128 @pair_extended_body_6(i128 %a,i128 %b) noinline {
entry:
 %n = and i128 %b,127
 %v = call i128 @llvm.umul.fix.sat.i128(i128 %a,i128 %b,i32 0)
 %r = xor i128 %v,%b
 ret i128 %r
}
declare i128 @pair_extended_provider_6(i128,i128)
define i64 @pair_extended_probe_6(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load i128,ptr %ap,align 1
 %b = load i128,ptr %bp,align 1
 %local = call fastcc i128 @pair_extended_body_6(i128 %a,i128 %b)
 %external = call i128 @pair_extended_provider_6(i128 %a,i128 %b)
 store i128 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 16
 store i128 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define fastcc i128 @pair_extended_body_7(i128 %a,i128 %b) noinline {
entry:
 %n = and i128 %b,127
 %v = call i128 @llvm.smul.fix.sat.i128(i128 %a,i128 %b,i32 0)
 %r = xor i128 %v,%b
 ret i128 %r
}
declare i128 @pair_extended_provider_7(i128,i128)
define i64 @pair_extended_probe_7(ptr %out,ptr %ap,ptr %bp,i64 %salt) {
entry:
 %a = load i128,ptr %ap,align 1
 %b = load i128,ptr %bp,align 1
 %local = call fastcc i128 @pair_extended_body_7(i128 %a,i128 %b)
 %external = call i128 @pair_extended_provider_7(i128 %a,i128 %b)
 store i128 %local,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 16
 store i128 %external,ptr %next,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
