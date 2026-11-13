target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare i40 @llvm.uadd.sat.i40(i40,i40)
define i64 @unsigned_odd_body_0(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load i40,ptr %ap,align 1
 %b = load i40,ptr %bp,align 1
 %value = call i40 @llvm.uadd.sat.i40(i40 %a,i40 %b)
 store i40 %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_0(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 53
 %answer = call i64 @unsigned_odd_body_0(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 5
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 13
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 21
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_1(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load i40,ptr %ap,align 1
 %b = load i40,ptr %bp,align 1
 %value = call i40 @llvm.uadd.sat.i40(i40 %a,i40 %b)
 store i40 %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_1(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 53
 %answer = call fastcc i64 @unsigned_odd_body_1(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 5
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 13
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 21
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @unsigned_odd_body_2(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load i40,ptr %ap,align 1
 %b = load i40,ptr %bp,align 1
 %value = call i40 @llvm.uadd.sat.i40(i40 -1,i40 %b)
 store i40 %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_2(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 53
 %answer = call i64 @unsigned_odd_body_2(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 5
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 13
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 21
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_3(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load i40,ptr %ap,align 1
 %b = load i40,ptr %bp,align 1
 %value = call i40 @llvm.uadd.sat.i40(i40 -1,i40 %b)
 store i40 %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_3(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 53
 %answer = call fastcc i64 @unsigned_odd_body_3(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 5
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 13
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 21
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @unsigned_odd_body_4(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load i40,ptr %ap,align 1
 %b = load i40,ptr %bp,align 1
 %value = call i40 @llvm.uadd.sat.i40(i40 %a,i40 -1)
 store i40 %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_4(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 53
 %answer = call i64 @unsigned_odd_body_4(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 5
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 13
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 21
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_5(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load i40,ptr %ap,align 1
 %b = load i40,ptr %bp,align 1
 %value = call i40 @llvm.uadd.sat.i40(i40 %a,i40 -1)
 store i40 %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_5(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 53
 %answer = call fastcc i64 @unsigned_odd_body_5(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 5
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 13
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 21
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
declare i40 @llvm.usub.sat.i40(i40,i40)
define i64 @unsigned_odd_body_6(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load i40,ptr %ap,align 1
 %b = load i40,ptr %bp,align 1
 %value = call i40 @llvm.usub.sat.i40(i40 %a,i40 %b)
 store i40 %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_6(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 53
 %answer = call i64 @unsigned_odd_body_6(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 5
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 13
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 21
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_7(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load i40,ptr %ap,align 1
 %b = load i40,ptr %bp,align 1
 %value = call i40 @llvm.usub.sat.i40(i40 %a,i40 %b)
 store i40 %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_7(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 53
 %answer = call fastcc i64 @unsigned_odd_body_7(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 5
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 13
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 21
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @unsigned_odd_body_8(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load i40,ptr %ap,align 1
 %b = load i40,ptr %bp,align 1
 %value = call i40 @llvm.usub.sat.i40(i40 -1,i40 %b)
 store i40 %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_8(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 53
 %answer = call i64 @unsigned_odd_body_8(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 5
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 13
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 21
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_9(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load i40,ptr %ap,align 1
 %b = load i40,ptr %bp,align 1
 %value = call i40 @llvm.usub.sat.i40(i40 -1,i40 %b)
 store i40 %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_9(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 53
 %answer = call fastcc i64 @unsigned_odd_body_9(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 5
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 13
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 21
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @unsigned_odd_body_10(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load i40,ptr %ap,align 1
 %b = load i40,ptr %bp,align 1
 %value = call i40 @llvm.usub.sat.i40(i40 %a,i40 -1)
 store i40 %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_10(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 53
 %answer = call i64 @unsigned_odd_body_10(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 5
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 13
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 21
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_11(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load i40,ptr %ap,align 1
 %b = load i40,ptr %bp,align 1
 %value = call i40 @llvm.usub.sat.i40(i40 %a,i40 -1)
 store i40 %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_11(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 53
 %answer = call fastcc i64 @unsigned_odd_body_11(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 5
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 13
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 21
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
declare <2 x i40> @llvm.uadd.sat.v2i40(<2 x i40>,<2 x i40>)
define i64 @unsigned_odd_body_12(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <2 x i40>,ptr %ap,align 1
 %b = load <2 x i40>,ptr %bp,align 1
 %value = call <2 x i40> @llvm.uadd.sat.v2i40(<2 x i40> %a,<2 x i40> %b)
 store <2 x i40> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_12(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 58
 %answer = call i64 @unsigned_odd_body_12(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 10
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 18
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 26
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_13(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <2 x i40>,ptr %ap,align 1
 %b = load <2 x i40>,ptr %bp,align 1
 %value = call <2 x i40> @llvm.uadd.sat.v2i40(<2 x i40> %a,<2 x i40> %b)
 store <2 x i40> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_13(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 58
 %answer = call fastcc i64 @unsigned_odd_body_13(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 10
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 18
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 26
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @unsigned_odd_body_14(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <2 x i40>,ptr %ap,align 1
 %b = load <2 x i40>,ptr %bp,align 1
 %value = call <2 x i40> @llvm.uadd.sat.v2i40(<2 x i40> <i40 -1,i40 -1>,<2 x i40> %b)
 store <2 x i40> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_14(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 58
 %answer = call i64 @unsigned_odd_body_14(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 10
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 18
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 26
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_15(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <2 x i40>,ptr %ap,align 1
 %b = load <2 x i40>,ptr %bp,align 1
 %value = call <2 x i40> @llvm.uadd.sat.v2i40(<2 x i40> <i40 -1,i40 -1>,<2 x i40> %b)
 store <2 x i40> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_15(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 58
 %answer = call fastcc i64 @unsigned_odd_body_15(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 10
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 18
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 26
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @unsigned_odd_body_16(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <2 x i40>,ptr %ap,align 1
 %b = load <2 x i40>,ptr %bp,align 1
 %value = call <2 x i40> @llvm.uadd.sat.v2i40(<2 x i40> %a,<2 x i40> <i40 -1,i40 -1>)
 store <2 x i40> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_16(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 58
 %answer = call i64 @unsigned_odd_body_16(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 10
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 18
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 26
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_17(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <2 x i40>,ptr %ap,align 1
 %b = load <2 x i40>,ptr %bp,align 1
 %value = call <2 x i40> @llvm.uadd.sat.v2i40(<2 x i40> %a,<2 x i40> <i40 -1,i40 -1>)
 store <2 x i40> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_17(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 58
 %answer = call fastcc i64 @unsigned_odd_body_17(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 10
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 18
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 26
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
declare <2 x i40> @llvm.usub.sat.v2i40(<2 x i40>,<2 x i40>)
define i64 @unsigned_odd_body_18(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <2 x i40>,ptr %ap,align 1
 %b = load <2 x i40>,ptr %bp,align 1
 %value = call <2 x i40> @llvm.usub.sat.v2i40(<2 x i40> %a,<2 x i40> %b)
 store <2 x i40> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_18(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 58
 %answer = call i64 @unsigned_odd_body_18(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 10
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 18
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 26
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_19(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <2 x i40>,ptr %ap,align 1
 %b = load <2 x i40>,ptr %bp,align 1
 %value = call <2 x i40> @llvm.usub.sat.v2i40(<2 x i40> %a,<2 x i40> %b)
 store <2 x i40> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_19(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 58
 %answer = call fastcc i64 @unsigned_odd_body_19(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 10
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 18
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 26
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @unsigned_odd_body_20(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <2 x i40>,ptr %ap,align 1
 %b = load <2 x i40>,ptr %bp,align 1
 %value = call <2 x i40> @llvm.usub.sat.v2i40(<2 x i40> <i40 -1,i40 -1>,<2 x i40> %b)
 store <2 x i40> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_20(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 58
 %answer = call i64 @unsigned_odd_body_20(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 10
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 18
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 26
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_21(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <2 x i40>,ptr %ap,align 1
 %b = load <2 x i40>,ptr %bp,align 1
 %value = call <2 x i40> @llvm.usub.sat.v2i40(<2 x i40> <i40 -1,i40 -1>,<2 x i40> %b)
 store <2 x i40> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_21(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 58
 %answer = call fastcc i64 @unsigned_odd_body_21(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 10
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 18
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 26
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @unsigned_odd_body_22(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <2 x i40>,ptr %ap,align 1
 %b = load <2 x i40>,ptr %bp,align 1
 %value = call <2 x i40> @llvm.usub.sat.v2i40(<2 x i40> %a,<2 x i40> <i40 -1,i40 -1>)
 store <2 x i40> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_22(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 58
 %answer = call i64 @unsigned_odd_body_22(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 10
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 18
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 26
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_23(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <2 x i40>,ptr %ap,align 1
 %b = load <2 x i40>,ptr %bp,align 1
 %value = call <2 x i40> @llvm.usub.sat.v2i40(<2 x i40> %a,<2 x i40> <i40 -1,i40 -1>)
 store <2 x i40> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_23(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 58
 %answer = call fastcc i64 @unsigned_odd_body_23(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 10
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 18
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 26
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
declare <4 x i40> @llvm.uadd.sat.v4i40(<4 x i40>,<4 x i40>)
define i64 @unsigned_odd_body_24(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <4 x i40>,ptr %ap,align 1
 %b = load <4 x i40>,ptr %bp,align 1
 %value = call <4 x i40> @llvm.uadd.sat.v4i40(<4 x i40> %a,<4 x i40> %b)
 store <4 x i40> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_24(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 68
 %answer = call i64 @unsigned_odd_body_24(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 20
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 28
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 36
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_25(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <4 x i40>,ptr %ap,align 1
 %b = load <4 x i40>,ptr %bp,align 1
 %value = call <4 x i40> @llvm.uadd.sat.v4i40(<4 x i40> %a,<4 x i40> %b)
 store <4 x i40> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_25(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 68
 %answer = call fastcc i64 @unsigned_odd_body_25(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 20
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 28
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 36
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @unsigned_odd_body_26(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <4 x i40>,ptr %ap,align 1
 %b = load <4 x i40>,ptr %bp,align 1
 %value = call <4 x i40> @llvm.uadd.sat.v4i40(<4 x i40> <i40 -1,i40 -1,i40 -1,i40 -1>,<4 x i40> %b)
 store <4 x i40> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_26(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 68
 %answer = call i64 @unsigned_odd_body_26(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 20
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 28
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 36
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_27(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <4 x i40>,ptr %ap,align 1
 %b = load <4 x i40>,ptr %bp,align 1
 %value = call <4 x i40> @llvm.uadd.sat.v4i40(<4 x i40> <i40 -1,i40 -1,i40 -1,i40 -1>,<4 x i40> %b)
 store <4 x i40> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_27(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 68
 %answer = call fastcc i64 @unsigned_odd_body_27(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 20
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 28
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 36
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @unsigned_odd_body_28(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <4 x i40>,ptr %ap,align 1
 %b = load <4 x i40>,ptr %bp,align 1
 %value = call <4 x i40> @llvm.uadd.sat.v4i40(<4 x i40> %a,<4 x i40> <i40 -1,i40 -1,i40 -1,i40 -1>)
 store <4 x i40> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_28(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 68
 %answer = call i64 @unsigned_odd_body_28(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 20
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 28
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 36
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_29(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <4 x i40>,ptr %ap,align 1
 %b = load <4 x i40>,ptr %bp,align 1
 %value = call <4 x i40> @llvm.uadd.sat.v4i40(<4 x i40> %a,<4 x i40> <i40 -1,i40 -1,i40 -1,i40 -1>)
 store <4 x i40> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_29(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 68
 %answer = call fastcc i64 @unsigned_odd_body_29(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 20
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 28
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 36
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
declare <4 x i40> @llvm.usub.sat.v4i40(<4 x i40>,<4 x i40>)
define i64 @unsigned_odd_body_30(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <4 x i40>,ptr %ap,align 1
 %b = load <4 x i40>,ptr %bp,align 1
 %value = call <4 x i40> @llvm.usub.sat.v4i40(<4 x i40> %a,<4 x i40> %b)
 store <4 x i40> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_30(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 68
 %answer = call i64 @unsigned_odd_body_30(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 20
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 28
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 36
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_31(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <4 x i40>,ptr %ap,align 1
 %b = load <4 x i40>,ptr %bp,align 1
 %value = call <4 x i40> @llvm.usub.sat.v4i40(<4 x i40> %a,<4 x i40> %b)
 store <4 x i40> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_31(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 68
 %answer = call fastcc i64 @unsigned_odd_body_31(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 20
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 28
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 36
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @unsigned_odd_body_32(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <4 x i40>,ptr %ap,align 1
 %b = load <4 x i40>,ptr %bp,align 1
 %value = call <4 x i40> @llvm.usub.sat.v4i40(<4 x i40> <i40 -1,i40 -1,i40 -1,i40 -1>,<4 x i40> %b)
 store <4 x i40> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_32(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 68
 %answer = call i64 @unsigned_odd_body_32(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 20
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 28
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 36
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_33(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <4 x i40>,ptr %ap,align 1
 %b = load <4 x i40>,ptr %bp,align 1
 %value = call <4 x i40> @llvm.usub.sat.v4i40(<4 x i40> <i40 -1,i40 -1,i40 -1,i40 -1>,<4 x i40> %b)
 store <4 x i40> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_33(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 68
 %answer = call fastcc i64 @unsigned_odd_body_33(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 20
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 28
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 36
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @unsigned_odd_body_34(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <4 x i40>,ptr %ap,align 1
 %b = load <4 x i40>,ptr %bp,align 1
 %value = call <4 x i40> @llvm.usub.sat.v4i40(<4 x i40> %a,<4 x i40> <i40 -1,i40 -1,i40 -1,i40 -1>)
 store <4 x i40> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_34(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 68
 %answer = call i64 @unsigned_odd_body_34(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 20
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 28
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 36
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_35(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <4 x i40>,ptr %ap,align 1
 %b = load <4 x i40>,ptr %bp,align 1
 %value = call <4 x i40> @llvm.usub.sat.v4i40(<4 x i40> %a,<4 x i40> <i40 -1,i40 -1,i40 -1,i40 -1>)
 store <4 x i40> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_35(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 68
 %answer = call fastcc i64 @unsigned_odd_body_35(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 20
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 28
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 36
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
declare i48 @llvm.uadd.sat.i48(i48,i48)
define i64 @unsigned_odd_body_36(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load i48,ptr %ap,align 1
 %b = load i48,ptr %bp,align 1
 %value = call i48 @llvm.uadd.sat.i48(i48 %a,i48 %b)
 store i48 %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_36(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 54
 %answer = call i64 @unsigned_odd_body_36(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 6
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 14
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 22
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_37(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load i48,ptr %ap,align 1
 %b = load i48,ptr %bp,align 1
 %value = call i48 @llvm.uadd.sat.i48(i48 %a,i48 %b)
 store i48 %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_37(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 54
 %answer = call fastcc i64 @unsigned_odd_body_37(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 6
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 14
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 22
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @unsigned_odd_body_38(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load i48,ptr %ap,align 1
 %b = load i48,ptr %bp,align 1
 %value = call i48 @llvm.uadd.sat.i48(i48 -1,i48 %b)
 store i48 %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_38(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 54
 %answer = call i64 @unsigned_odd_body_38(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 6
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 14
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 22
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_39(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load i48,ptr %ap,align 1
 %b = load i48,ptr %bp,align 1
 %value = call i48 @llvm.uadd.sat.i48(i48 -1,i48 %b)
 store i48 %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_39(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 54
 %answer = call fastcc i64 @unsigned_odd_body_39(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 6
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 14
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 22
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @unsigned_odd_body_40(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load i48,ptr %ap,align 1
 %b = load i48,ptr %bp,align 1
 %value = call i48 @llvm.uadd.sat.i48(i48 %a,i48 -1)
 store i48 %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_40(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 54
 %answer = call i64 @unsigned_odd_body_40(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 6
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 14
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 22
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_41(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load i48,ptr %ap,align 1
 %b = load i48,ptr %bp,align 1
 %value = call i48 @llvm.uadd.sat.i48(i48 %a,i48 -1)
 store i48 %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_41(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 54
 %answer = call fastcc i64 @unsigned_odd_body_41(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 6
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 14
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 22
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
declare i48 @llvm.usub.sat.i48(i48,i48)
define i64 @unsigned_odd_body_42(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load i48,ptr %ap,align 1
 %b = load i48,ptr %bp,align 1
 %value = call i48 @llvm.usub.sat.i48(i48 %a,i48 %b)
 store i48 %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_42(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 54
 %answer = call i64 @unsigned_odd_body_42(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 6
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 14
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 22
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_43(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load i48,ptr %ap,align 1
 %b = load i48,ptr %bp,align 1
 %value = call i48 @llvm.usub.sat.i48(i48 %a,i48 %b)
 store i48 %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_43(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 54
 %answer = call fastcc i64 @unsigned_odd_body_43(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 6
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 14
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 22
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @unsigned_odd_body_44(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load i48,ptr %ap,align 1
 %b = load i48,ptr %bp,align 1
 %value = call i48 @llvm.usub.sat.i48(i48 -1,i48 %b)
 store i48 %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_44(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 54
 %answer = call i64 @unsigned_odd_body_44(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 6
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 14
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 22
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_45(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load i48,ptr %ap,align 1
 %b = load i48,ptr %bp,align 1
 %value = call i48 @llvm.usub.sat.i48(i48 -1,i48 %b)
 store i48 %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_45(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 54
 %answer = call fastcc i64 @unsigned_odd_body_45(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 6
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 14
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 22
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @unsigned_odd_body_46(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load i48,ptr %ap,align 1
 %b = load i48,ptr %bp,align 1
 %value = call i48 @llvm.usub.sat.i48(i48 %a,i48 -1)
 store i48 %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_46(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 54
 %answer = call i64 @unsigned_odd_body_46(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 6
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 14
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 22
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_47(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load i48,ptr %ap,align 1
 %b = load i48,ptr %bp,align 1
 %value = call i48 @llvm.usub.sat.i48(i48 %a,i48 -1)
 store i48 %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_47(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 54
 %answer = call fastcc i64 @unsigned_odd_body_47(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 6
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 14
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 22
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
declare <2 x i48> @llvm.uadd.sat.v2i48(<2 x i48>,<2 x i48>)
define i64 @unsigned_odd_body_48(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <2 x i48>,ptr %ap,align 1
 %b = load <2 x i48>,ptr %bp,align 1
 %value = call <2 x i48> @llvm.uadd.sat.v2i48(<2 x i48> %a,<2 x i48> %b)
 store <2 x i48> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_48(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 60
 %answer = call i64 @unsigned_odd_body_48(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 12
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 20
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 28
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_49(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <2 x i48>,ptr %ap,align 1
 %b = load <2 x i48>,ptr %bp,align 1
 %value = call <2 x i48> @llvm.uadd.sat.v2i48(<2 x i48> %a,<2 x i48> %b)
 store <2 x i48> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_49(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 60
 %answer = call fastcc i64 @unsigned_odd_body_49(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 12
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 20
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 28
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @unsigned_odd_body_50(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <2 x i48>,ptr %ap,align 1
 %b = load <2 x i48>,ptr %bp,align 1
 %value = call <2 x i48> @llvm.uadd.sat.v2i48(<2 x i48> <i48 -1,i48 -1>,<2 x i48> %b)
 store <2 x i48> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_50(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 60
 %answer = call i64 @unsigned_odd_body_50(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 12
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 20
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 28
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_51(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <2 x i48>,ptr %ap,align 1
 %b = load <2 x i48>,ptr %bp,align 1
 %value = call <2 x i48> @llvm.uadd.sat.v2i48(<2 x i48> <i48 -1,i48 -1>,<2 x i48> %b)
 store <2 x i48> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_51(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 60
 %answer = call fastcc i64 @unsigned_odd_body_51(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 12
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 20
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 28
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @unsigned_odd_body_52(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <2 x i48>,ptr %ap,align 1
 %b = load <2 x i48>,ptr %bp,align 1
 %value = call <2 x i48> @llvm.uadd.sat.v2i48(<2 x i48> %a,<2 x i48> <i48 -1,i48 -1>)
 store <2 x i48> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_52(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 60
 %answer = call i64 @unsigned_odd_body_52(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 12
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 20
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 28
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_53(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <2 x i48>,ptr %ap,align 1
 %b = load <2 x i48>,ptr %bp,align 1
 %value = call <2 x i48> @llvm.uadd.sat.v2i48(<2 x i48> %a,<2 x i48> <i48 -1,i48 -1>)
 store <2 x i48> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_53(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 60
 %answer = call fastcc i64 @unsigned_odd_body_53(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 12
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 20
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 28
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
declare <2 x i48> @llvm.usub.sat.v2i48(<2 x i48>,<2 x i48>)
define i64 @unsigned_odd_body_54(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <2 x i48>,ptr %ap,align 1
 %b = load <2 x i48>,ptr %bp,align 1
 %value = call <2 x i48> @llvm.usub.sat.v2i48(<2 x i48> %a,<2 x i48> %b)
 store <2 x i48> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_54(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 60
 %answer = call i64 @unsigned_odd_body_54(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 12
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 20
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 28
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_55(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <2 x i48>,ptr %ap,align 1
 %b = load <2 x i48>,ptr %bp,align 1
 %value = call <2 x i48> @llvm.usub.sat.v2i48(<2 x i48> %a,<2 x i48> %b)
 store <2 x i48> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_55(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 60
 %answer = call fastcc i64 @unsigned_odd_body_55(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 12
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 20
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 28
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @unsigned_odd_body_56(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <2 x i48>,ptr %ap,align 1
 %b = load <2 x i48>,ptr %bp,align 1
 %value = call <2 x i48> @llvm.usub.sat.v2i48(<2 x i48> <i48 -1,i48 -1>,<2 x i48> %b)
 store <2 x i48> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_56(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 60
 %answer = call i64 @unsigned_odd_body_56(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 12
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 20
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 28
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_57(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <2 x i48>,ptr %ap,align 1
 %b = load <2 x i48>,ptr %bp,align 1
 %value = call <2 x i48> @llvm.usub.sat.v2i48(<2 x i48> <i48 -1,i48 -1>,<2 x i48> %b)
 store <2 x i48> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_57(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 60
 %answer = call fastcc i64 @unsigned_odd_body_57(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 12
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 20
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 28
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @unsigned_odd_body_58(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <2 x i48>,ptr %ap,align 1
 %b = load <2 x i48>,ptr %bp,align 1
 %value = call <2 x i48> @llvm.usub.sat.v2i48(<2 x i48> %a,<2 x i48> <i48 -1,i48 -1>)
 store <2 x i48> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_58(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 60
 %answer = call i64 @unsigned_odd_body_58(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 12
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 20
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 28
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_59(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <2 x i48>,ptr %ap,align 1
 %b = load <2 x i48>,ptr %bp,align 1
 %value = call <2 x i48> @llvm.usub.sat.v2i48(<2 x i48> %a,<2 x i48> <i48 -1,i48 -1>)
 store <2 x i48> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_59(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 60
 %answer = call fastcc i64 @unsigned_odd_body_59(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 12
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 20
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 28
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
declare <4 x i48> @llvm.uadd.sat.v4i48(<4 x i48>,<4 x i48>)
define i64 @unsigned_odd_body_60(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <4 x i48>,ptr %ap,align 1
 %b = load <4 x i48>,ptr %bp,align 1
 %value = call <4 x i48> @llvm.uadd.sat.v4i48(<4 x i48> %a,<4 x i48> %b)
 store <4 x i48> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_60(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 72
 %answer = call i64 @unsigned_odd_body_60(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 24
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 32
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 40
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_61(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <4 x i48>,ptr %ap,align 1
 %b = load <4 x i48>,ptr %bp,align 1
 %value = call <4 x i48> @llvm.uadd.sat.v4i48(<4 x i48> %a,<4 x i48> %b)
 store <4 x i48> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_61(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 72
 %answer = call fastcc i64 @unsigned_odd_body_61(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 24
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 32
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 40
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @unsigned_odd_body_62(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <4 x i48>,ptr %ap,align 1
 %b = load <4 x i48>,ptr %bp,align 1
 %value = call <4 x i48> @llvm.uadd.sat.v4i48(<4 x i48> <i48 -1,i48 -1,i48 -1,i48 -1>,<4 x i48> %b)
 store <4 x i48> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_62(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 72
 %answer = call i64 @unsigned_odd_body_62(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 24
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 32
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 40
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_63(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <4 x i48>,ptr %ap,align 1
 %b = load <4 x i48>,ptr %bp,align 1
 %value = call <4 x i48> @llvm.uadd.sat.v4i48(<4 x i48> <i48 -1,i48 -1,i48 -1,i48 -1>,<4 x i48> %b)
 store <4 x i48> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_63(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 72
 %answer = call fastcc i64 @unsigned_odd_body_63(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 24
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 32
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 40
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @unsigned_odd_body_64(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <4 x i48>,ptr %ap,align 1
 %b = load <4 x i48>,ptr %bp,align 1
 %value = call <4 x i48> @llvm.uadd.sat.v4i48(<4 x i48> %a,<4 x i48> <i48 -1,i48 -1,i48 -1,i48 -1>)
 store <4 x i48> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_64(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 72
 %answer = call i64 @unsigned_odd_body_64(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 24
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 32
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 40
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_65(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <4 x i48>,ptr %ap,align 1
 %b = load <4 x i48>,ptr %bp,align 1
 %value = call <4 x i48> @llvm.uadd.sat.v4i48(<4 x i48> %a,<4 x i48> <i48 -1,i48 -1,i48 -1,i48 -1>)
 store <4 x i48> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_65(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 72
 %answer = call fastcc i64 @unsigned_odd_body_65(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 24
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 32
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 40
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
declare <4 x i48> @llvm.usub.sat.v4i48(<4 x i48>,<4 x i48>)
define i64 @unsigned_odd_body_66(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <4 x i48>,ptr %ap,align 1
 %b = load <4 x i48>,ptr %bp,align 1
 %value = call <4 x i48> @llvm.usub.sat.v4i48(<4 x i48> %a,<4 x i48> %b)
 store <4 x i48> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_66(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 72
 %answer = call i64 @unsigned_odd_body_66(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 24
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 32
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 40
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_67(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <4 x i48>,ptr %ap,align 1
 %b = load <4 x i48>,ptr %bp,align 1
 %value = call <4 x i48> @llvm.usub.sat.v4i48(<4 x i48> %a,<4 x i48> %b)
 store <4 x i48> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_67(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 72
 %answer = call fastcc i64 @unsigned_odd_body_67(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 24
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 32
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 40
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @unsigned_odd_body_68(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <4 x i48>,ptr %ap,align 1
 %b = load <4 x i48>,ptr %bp,align 1
 %value = call <4 x i48> @llvm.usub.sat.v4i48(<4 x i48> <i48 -1,i48 -1,i48 -1,i48 -1>,<4 x i48> %b)
 store <4 x i48> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_68(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 72
 %answer = call i64 @unsigned_odd_body_68(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 24
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 32
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 40
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_69(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <4 x i48>,ptr %ap,align 1
 %b = load <4 x i48>,ptr %bp,align 1
 %value = call <4 x i48> @llvm.usub.sat.v4i48(<4 x i48> <i48 -1,i48 -1,i48 -1,i48 -1>,<4 x i48> %b)
 store <4 x i48> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_69(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 72
 %answer = call fastcc i64 @unsigned_odd_body_69(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 24
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 32
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 40
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @unsigned_odd_body_70(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <4 x i48>,ptr %ap,align 1
 %b = load <4 x i48>,ptr %bp,align 1
 %value = call <4 x i48> @llvm.usub.sat.v4i48(<4 x i48> %a,<4 x i48> <i48 -1,i48 -1,i48 -1,i48 -1>)
 store <4 x i48> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_70(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 72
 %answer = call i64 @unsigned_odd_body_70(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 24
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 32
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 40
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_71(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <4 x i48>,ptr %ap,align 1
 %b = load <4 x i48>,ptr %bp,align 1
 %value = call <4 x i48> @llvm.usub.sat.v4i48(<4 x i48> %a,<4 x i48> <i48 -1,i48 -1,i48 -1,i48 -1>)
 store <4 x i48> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_71(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 72
 %answer = call fastcc i64 @unsigned_odd_body_71(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 24
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 32
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 40
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
declare i56 @llvm.uadd.sat.i56(i56,i56)
define i64 @unsigned_odd_body_72(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load i56,ptr %ap,align 1
 %b = load i56,ptr %bp,align 1
 %value = call i56 @llvm.uadd.sat.i56(i56 %a,i56 %b)
 store i56 %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_72(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 55
 %answer = call i64 @unsigned_odd_body_72(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 7
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 15
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 23
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_73(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load i56,ptr %ap,align 1
 %b = load i56,ptr %bp,align 1
 %value = call i56 @llvm.uadd.sat.i56(i56 %a,i56 %b)
 store i56 %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_73(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 55
 %answer = call fastcc i64 @unsigned_odd_body_73(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 7
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 15
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 23
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @unsigned_odd_body_74(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load i56,ptr %ap,align 1
 %b = load i56,ptr %bp,align 1
 %value = call i56 @llvm.uadd.sat.i56(i56 -1,i56 %b)
 store i56 %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_74(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 55
 %answer = call i64 @unsigned_odd_body_74(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 7
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 15
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 23
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_75(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load i56,ptr %ap,align 1
 %b = load i56,ptr %bp,align 1
 %value = call i56 @llvm.uadd.sat.i56(i56 -1,i56 %b)
 store i56 %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_75(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 55
 %answer = call fastcc i64 @unsigned_odd_body_75(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 7
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 15
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 23
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @unsigned_odd_body_76(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load i56,ptr %ap,align 1
 %b = load i56,ptr %bp,align 1
 %value = call i56 @llvm.uadd.sat.i56(i56 %a,i56 -1)
 store i56 %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_76(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 55
 %answer = call i64 @unsigned_odd_body_76(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 7
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 15
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 23
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_77(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load i56,ptr %ap,align 1
 %b = load i56,ptr %bp,align 1
 %value = call i56 @llvm.uadd.sat.i56(i56 %a,i56 -1)
 store i56 %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_77(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 55
 %answer = call fastcc i64 @unsigned_odd_body_77(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 7
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 15
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 23
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
declare i56 @llvm.usub.sat.i56(i56,i56)
define i64 @unsigned_odd_body_78(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load i56,ptr %ap,align 1
 %b = load i56,ptr %bp,align 1
 %value = call i56 @llvm.usub.sat.i56(i56 %a,i56 %b)
 store i56 %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_78(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 55
 %answer = call i64 @unsigned_odd_body_78(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 7
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 15
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 23
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_79(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load i56,ptr %ap,align 1
 %b = load i56,ptr %bp,align 1
 %value = call i56 @llvm.usub.sat.i56(i56 %a,i56 %b)
 store i56 %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_79(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 55
 %answer = call fastcc i64 @unsigned_odd_body_79(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 7
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 15
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 23
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @unsigned_odd_body_80(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load i56,ptr %ap,align 1
 %b = load i56,ptr %bp,align 1
 %value = call i56 @llvm.usub.sat.i56(i56 -1,i56 %b)
 store i56 %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_80(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 55
 %answer = call i64 @unsigned_odd_body_80(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 7
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 15
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 23
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_81(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load i56,ptr %ap,align 1
 %b = load i56,ptr %bp,align 1
 %value = call i56 @llvm.usub.sat.i56(i56 -1,i56 %b)
 store i56 %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_81(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 55
 %answer = call fastcc i64 @unsigned_odd_body_81(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 7
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 15
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 23
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @unsigned_odd_body_82(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load i56,ptr %ap,align 1
 %b = load i56,ptr %bp,align 1
 %value = call i56 @llvm.usub.sat.i56(i56 %a,i56 -1)
 store i56 %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_82(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 55
 %answer = call i64 @unsigned_odd_body_82(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 7
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 15
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 23
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_83(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load i56,ptr %ap,align 1
 %b = load i56,ptr %bp,align 1
 %value = call i56 @llvm.usub.sat.i56(i56 %a,i56 -1)
 store i56 %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_83(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 55
 %answer = call fastcc i64 @unsigned_odd_body_83(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 7
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 15
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 23
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
declare <2 x i56> @llvm.uadd.sat.v2i56(<2 x i56>,<2 x i56>)
define i64 @unsigned_odd_body_84(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <2 x i56>,ptr %ap,align 1
 %b = load <2 x i56>,ptr %bp,align 1
 %value = call <2 x i56> @llvm.uadd.sat.v2i56(<2 x i56> %a,<2 x i56> %b)
 store <2 x i56> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_84(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 62
 %answer = call i64 @unsigned_odd_body_84(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 14
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 22
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 30
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_85(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <2 x i56>,ptr %ap,align 1
 %b = load <2 x i56>,ptr %bp,align 1
 %value = call <2 x i56> @llvm.uadd.sat.v2i56(<2 x i56> %a,<2 x i56> %b)
 store <2 x i56> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_85(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 62
 %answer = call fastcc i64 @unsigned_odd_body_85(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 14
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 22
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 30
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @unsigned_odd_body_86(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <2 x i56>,ptr %ap,align 1
 %b = load <2 x i56>,ptr %bp,align 1
 %value = call <2 x i56> @llvm.uadd.sat.v2i56(<2 x i56> <i56 -1,i56 -1>,<2 x i56> %b)
 store <2 x i56> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_86(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 62
 %answer = call i64 @unsigned_odd_body_86(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 14
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 22
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 30
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_87(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <2 x i56>,ptr %ap,align 1
 %b = load <2 x i56>,ptr %bp,align 1
 %value = call <2 x i56> @llvm.uadd.sat.v2i56(<2 x i56> <i56 -1,i56 -1>,<2 x i56> %b)
 store <2 x i56> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_87(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 62
 %answer = call fastcc i64 @unsigned_odd_body_87(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 14
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 22
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 30
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @unsigned_odd_body_88(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <2 x i56>,ptr %ap,align 1
 %b = load <2 x i56>,ptr %bp,align 1
 %value = call <2 x i56> @llvm.uadd.sat.v2i56(<2 x i56> %a,<2 x i56> <i56 -1,i56 -1>)
 store <2 x i56> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_88(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 62
 %answer = call i64 @unsigned_odd_body_88(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 14
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 22
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 30
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_89(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <2 x i56>,ptr %ap,align 1
 %b = load <2 x i56>,ptr %bp,align 1
 %value = call <2 x i56> @llvm.uadd.sat.v2i56(<2 x i56> %a,<2 x i56> <i56 -1,i56 -1>)
 store <2 x i56> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_89(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 62
 %answer = call fastcc i64 @unsigned_odd_body_89(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 14
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 22
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 30
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
declare <2 x i56> @llvm.usub.sat.v2i56(<2 x i56>,<2 x i56>)
define i64 @unsigned_odd_body_90(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <2 x i56>,ptr %ap,align 1
 %b = load <2 x i56>,ptr %bp,align 1
 %value = call <2 x i56> @llvm.usub.sat.v2i56(<2 x i56> %a,<2 x i56> %b)
 store <2 x i56> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_90(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 62
 %answer = call i64 @unsigned_odd_body_90(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 14
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 22
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 30
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_91(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <2 x i56>,ptr %ap,align 1
 %b = load <2 x i56>,ptr %bp,align 1
 %value = call <2 x i56> @llvm.usub.sat.v2i56(<2 x i56> %a,<2 x i56> %b)
 store <2 x i56> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_91(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 62
 %answer = call fastcc i64 @unsigned_odd_body_91(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 14
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 22
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 30
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @unsigned_odd_body_92(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <2 x i56>,ptr %ap,align 1
 %b = load <2 x i56>,ptr %bp,align 1
 %value = call <2 x i56> @llvm.usub.sat.v2i56(<2 x i56> <i56 -1,i56 -1>,<2 x i56> %b)
 store <2 x i56> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_92(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 62
 %answer = call i64 @unsigned_odd_body_92(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 14
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 22
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 30
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_93(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <2 x i56>,ptr %ap,align 1
 %b = load <2 x i56>,ptr %bp,align 1
 %value = call <2 x i56> @llvm.usub.sat.v2i56(<2 x i56> <i56 -1,i56 -1>,<2 x i56> %b)
 store <2 x i56> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_93(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 62
 %answer = call fastcc i64 @unsigned_odd_body_93(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 14
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 22
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 30
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @unsigned_odd_body_94(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <2 x i56>,ptr %ap,align 1
 %b = load <2 x i56>,ptr %bp,align 1
 %value = call <2 x i56> @llvm.usub.sat.v2i56(<2 x i56> %a,<2 x i56> <i56 -1,i56 -1>)
 store <2 x i56> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_94(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 62
 %answer = call i64 @unsigned_odd_body_94(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 14
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 22
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 30
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_95(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <2 x i56>,ptr %ap,align 1
 %b = load <2 x i56>,ptr %bp,align 1
 %value = call <2 x i56> @llvm.usub.sat.v2i56(<2 x i56> %a,<2 x i56> <i56 -1,i56 -1>)
 store <2 x i56> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_95(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 62
 %answer = call fastcc i64 @unsigned_odd_body_95(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 14
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 22
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 30
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
declare <4 x i56> @llvm.uadd.sat.v4i56(<4 x i56>,<4 x i56>)
define i64 @unsigned_odd_body_96(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <4 x i56>,ptr %ap,align 1
 %b = load <4 x i56>,ptr %bp,align 1
 %value = call <4 x i56> @llvm.uadd.sat.v4i56(<4 x i56> %a,<4 x i56> %b)
 store <4 x i56> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_96(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 76
 %answer = call i64 @unsigned_odd_body_96(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 28
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 36
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 44
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_97(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <4 x i56>,ptr %ap,align 1
 %b = load <4 x i56>,ptr %bp,align 1
 %value = call <4 x i56> @llvm.uadd.sat.v4i56(<4 x i56> %a,<4 x i56> %b)
 store <4 x i56> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_97(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 76
 %answer = call fastcc i64 @unsigned_odd_body_97(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 28
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 36
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 44
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @unsigned_odd_body_98(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <4 x i56>,ptr %ap,align 1
 %b = load <4 x i56>,ptr %bp,align 1
 %value = call <4 x i56> @llvm.uadd.sat.v4i56(<4 x i56> <i56 -1,i56 -1,i56 -1,i56 -1>,<4 x i56> %b)
 store <4 x i56> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_98(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 76
 %answer = call i64 @unsigned_odd_body_98(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 28
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 36
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 44
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_99(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <4 x i56>,ptr %ap,align 1
 %b = load <4 x i56>,ptr %bp,align 1
 %value = call <4 x i56> @llvm.uadd.sat.v4i56(<4 x i56> <i56 -1,i56 -1,i56 -1,i56 -1>,<4 x i56> %b)
 store <4 x i56> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_99(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 76
 %answer = call fastcc i64 @unsigned_odd_body_99(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 28
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 36
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 44
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @unsigned_odd_body_100(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <4 x i56>,ptr %ap,align 1
 %b = load <4 x i56>,ptr %bp,align 1
 %value = call <4 x i56> @llvm.uadd.sat.v4i56(<4 x i56> %a,<4 x i56> <i56 -1,i56 -1,i56 -1,i56 -1>)
 store <4 x i56> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_100(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 76
 %answer = call i64 @unsigned_odd_body_100(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 28
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 36
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 44
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_101(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <4 x i56>,ptr %ap,align 1
 %b = load <4 x i56>,ptr %bp,align 1
 %value = call <4 x i56> @llvm.uadd.sat.v4i56(<4 x i56> %a,<4 x i56> <i56 -1,i56 -1,i56 -1,i56 -1>)
 store <4 x i56> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_101(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 76
 %answer = call fastcc i64 @unsigned_odd_body_101(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 28
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 36
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 44
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
declare <4 x i56> @llvm.usub.sat.v4i56(<4 x i56>,<4 x i56>)
define i64 @unsigned_odd_body_102(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <4 x i56>,ptr %ap,align 1
 %b = load <4 x i56>,ptr %bp,align 1
 %value = call <4 x i56> @llvm.usub.sat.v4i56(<4 x i56> %a,<4 x i56> %b)
 store <4 x i56> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_102(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 76
 %answer = call i64 @unsigned_odd_body_102(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 28
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 36
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 44
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_103(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <4 x i56>,ptr %ap,align 1
 %b = load <4 x i56>,ptr %bp,align 1
 %value = call <4 x i56> @llvm.usub.sat.v4i56(<4 x i56> %a,<4 x i56> %b)
 store <4 x i56> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_103(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 76
 %answer = call fastcc i64 @unsigned_odd_body_103(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 28
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 36
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 44
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @unsigned_odd_body_104(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <4 x i56>,ptr %ap,align 1
 %b = load <4 x i56>,ptr %bp,align 1
 %value = call <4 x i56> @llvm.usub.sat.v4i56(<4 x i56> <i56 -1,i56 -1,i56 -1,i56 -1>,<4 x i56> %b)
 store <4 x i56> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_104(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 76
 %answer = call i64 @unsigned_odd_body_104(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 28
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 36
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 44
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_105(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <4 x i56>,ptr %ap,align 1
 %b = load <4 x i56>,ptr %bp,align 1
 %value = call <4 x i56> @llvm.usub.sat.v4i56(<4 x i56> <i56 -1,i56 -1,i56 -1,i56 -1>,<4 x i56> %b)
 store <4 x i56> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_105(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 76
 %answer = call fastcc i64 @unsigned_odd_body_105(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 28
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 36
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 44
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define i64 @unsigned_odd_body_106(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <4 x i56>,ptr %ap,align 1
 %b = load <4 x i56>,ptr %bp,align 1
 %value = call <4 x i56> @llvm.usub.sat.v4i56(<4 x i56> %a,<4 x i56> <i56 -1,i56 -1,i56 -1,i56 -1>)
 store <4 x i56> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_106(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 76
 %answer = call i64 @unsigned_odd_body_106(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 28
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 36
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 44
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
define fastcc i64 @unsigned_odd_body_107(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %ap,ptr %bp,ptr %out) noinline {
entry:
 %a = load <4 x i56>,ptr %ap,align 1
 %b = load <4 x i56>,ptr %bp,align 1
 %value = call <4 x i56> @llvm.usub.sat.v4i56(<4 x i56> %a,<4 x i56> <i56 -1,i56 -1,i56 -1,i56 -1>)
 store <4 x i56> %value,ptr %out,align 1
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @unsigned_odd_probe_107(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %ap = getelementptr i8,ptr %input,i64 48
 %bp = getelementptr i8,ptr %input,i64 76
 %answer = call fastcc i64 @unsigned_odd_body_107(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %ap,ptr %bp,ptr %out)
 %o0 = getelementptr i8,ptr %out,i64 28
 store i64 %answer,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 36
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 44
 store i64 %v0,ptr %o2,align 1
 %result = xor i64 %answer,%salt
 ret i64 %result
}
