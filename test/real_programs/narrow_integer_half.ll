target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
define i64 @narrow_half_body_0(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i1
 %value = uitofp i1 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_0(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_0(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_1(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i1
 %value = uitofp i1 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_1(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_1(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_2(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i1
 %value = uitofp i1 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_2(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_2(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_3(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i1
 %value = uitofp i1 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_3(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_3(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_4(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i1
 %value = uitofp i1 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_4(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_4(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_5(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i1
 %value = uitofp i1 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_5(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_5(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_6(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i1
 %value = uitofp i1 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_6(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_6(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_7(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i1
 %value = uitofp i1 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_7(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_7(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_8(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i1
 %value = uitofp i1 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_8(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_8(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_9(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i1
 %value = uitofp i1 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_9(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_9(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_10(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i1
 %value = uitofp i1 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_10(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_10(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_11(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i1
 %value = uitofp i1 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_11(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_11(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_12(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i1
 %value = sitofp i1 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_12(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_12(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_13(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i1
 %value = sitofp i1 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_13(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_13(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_14(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i1
 %value = sitofp i1 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_14(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_14(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_15(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i1
 %value = sitofp i1 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_15(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_15(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_16(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i1
 %value = sitofp i1 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_16(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_16(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_17(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i1
 %value = sitofp i1 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_17(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_17(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_18(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i1
 %value = sitofp i1 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_18(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_18(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_19(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i1
 %value = sitofp i1 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_19(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_19(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_20(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i1
 %value = sitofp i1 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_20(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_20(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_21(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i1
 %value = sitofp i1 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_21(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_21(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_22(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i1
 %value = sitofp i1 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_22(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_22(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_23(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i1
 %value = sitofp i1 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_23(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_23(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_24(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i2
 %value = uitofp i2 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_24(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_24(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_25(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i2
 %value = uitofp i2 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_25(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_25(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_26(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i2
 %value = uitofp i2 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_26(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_26(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_27(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i2
 %value = uitofp i2 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_27(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_27(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_28(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i2
 %value = uitofp i2 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_28(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_28(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_29(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i2
 %value = uitofp i2 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_29(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_29(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_30(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i2
 %value = uitofp i2 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_30(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_30(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_31(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i2
 %value = uitofp i2 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_31(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_31(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_32(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i2
 %value = uitofp i2 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_32(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_32(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_33(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i2
 %value = uitofp i2 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_33(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_33(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_34(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i2
 %value = uitofp i2 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_34(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_34(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_35(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i2
 %value = uitofp i2 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_35(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_35(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_36(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i2
 %value = sitofp i2 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_36(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_36(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_37(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i2
 %value = sitofp i2 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_37(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_37(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_38(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i2
 %value = sitofp i2 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_38(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_38(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_39(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i2
 %value = sitofp i2 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_39(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_39(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_40(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i2
 %value = sitofp i2 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_40(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_40(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_41(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i2
 %value = sitofp i2 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_41(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_41(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_42(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i2
 %value = sitofp i2 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_42(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_42(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_43(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i2
 %value = sitofp i2 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_43(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_43(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_44(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i2
 %value = sitofp i2 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_44(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_44(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_45(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i2
 %value = sitofp i2 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_45(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_45(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_46(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i2
 %value = sitofp i2 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_46(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_46(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_47(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i2
 %value = sitofp i2 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_47(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_47(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_48(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i3
 %value = uitofp i3 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_48(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_48(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_49(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i3
 %value = uitofp i3 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_49(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_49(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_50(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i3
 %value = uitofp i3 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_50(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_50(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_51(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i3
 %value = uitofp i3 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_51(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_51(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_52(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i3
 %value = uitofp i3 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_52(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_52(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_53(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i3
 %value = uitofp i3 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_53(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_53(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_54(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i3
 %value = uitofp i3 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_54(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_54(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_55(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i3
 %value = uitofp i3 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_55(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_55(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_56(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i3
 %value = uitofp i3 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_56(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_56(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_57(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i3
 %value = uitofp i3 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_57(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_57(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_58(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i3
 %value = uitofp i3 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_58(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_58(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_59(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i3
 %value = uitofp i3 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_59(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_59(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_60(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i3
 %value = sitofp i3 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_60(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_60(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_61(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i3
 %value = sitofp i3 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_61(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_61(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_62(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i3
 %value = sitofp i3 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_62(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_62(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_63(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i3
 %value = sitofp i3 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_63(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_63(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_64(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i3
 %value = sitofp i3 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_64(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_64(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_65(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i3
 %value = sitofp i3 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_65(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_65(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_66(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i3
 %value = sitofp i3 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_66(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_66(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_67(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i3
 %value = sitofp i3 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_67(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_67(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_68(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i3
 %value = sitofp i3 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_68(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_68(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_69(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i3
 %value = sitofp i3 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_69(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_69(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_70(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i3
 %value = sitofp i3 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_70(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_70(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_71(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i3
 %value = sitofp i3 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_71(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_71(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_72(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i7
 %value = uitofp i7 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_72(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_72(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_73(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i7
 %value = uitofp i7 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_73(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_73(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_74(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i7
 %value = uitofp i7 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_74(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_74(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_75(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i7
 %value = uitofp i7 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_75(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_75(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_76(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i7
 %value = uitofp i7 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_76(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_76(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_77(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i7
 %value = uitofp i7 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_77(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_77(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_78(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i7
 %value = uitofp i7 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_78(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_78(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_79(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i7
 %value = uitofp i7 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_79(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_79(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_80(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i7
 %value = uitofp i7 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_80(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_80(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_81(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i7
 %value = uitofp i7 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_81(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_81(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_82(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i7
 %value = uitofp i7 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_82(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_82(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_83(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i7
 %value = uitofp i7 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_83(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_83(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_84(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i7
 %value = sitofp i7 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_84(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_84(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_85(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i7
 %value = sitofp i7 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_85(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_85(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_86(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i7
 %value = sitofp i7 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_86(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_86(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_87(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i7
 %value = sitofp i7 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_87(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_87(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_88(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i7
 %value = sitofp i7 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_88(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_88(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_89(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i7
 %value = sitofp i7 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_89(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_89(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_90(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i7
 %value = sitofp i7 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_90(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_90(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_91(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i7
 %value = sitofp i7 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_91(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_91(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_92(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i7
 %value = sitofp i7 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_92(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_92(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_93(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i7
 %value = sitofp i7 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_93(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_93(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_94(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i7
 %value = sitofp i7 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_94(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_94(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_95(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i7
 %value = sitofp i7 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_95(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_95(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_96(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i8
 %value = uitofp i8 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_96(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_96(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_97(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i8
 %value = uitofp i8 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_97(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_97(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_98(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i8
 %value = uitofp i8 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_98(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_98(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_99(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i8
 %value = uitofp i8 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_99(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_99(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_100(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i8
 %value = uitofp i8 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_100(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_100(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_101(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i8
 %value = uitofp i8 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_101(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_101(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_102(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i8
 %value = uitofp i8 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_102(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_102(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_103(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i8
 %value = uitofp i8 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_103(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_103(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_104(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i8
 %value = uitofp i8 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_104(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_104(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_105(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i8
 %value = uitofp i8 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_105(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_105(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_106(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i8
 %value = uitofp i8 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_106(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_106(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_107(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i8
 %value = uitofp i8 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_107(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_107(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_108(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i8
 %value = sitofp i8 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_108(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_108(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_109(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i8
 %value = sitofp i8 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_109(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_109(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_110(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i8
 %value = sitofp i8 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_110(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_110(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_111(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i8
 %value = sitofp i8 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_111(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_111(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_112(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i8
 %value = sitofp i8 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_112(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_112(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_113(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i8
 %value = sitofp i8 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_113(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_113(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_114(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i8
 %value = sitofp i8 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_114(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_114(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_115(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i8
 %value = sitofp i8 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_115(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_115(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_116(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i8
 %value = sitofp i8 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_116(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_116(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_117(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i8
 %value = sitofp i8 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_117(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_117(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_118(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i8
 %value = sitofp i8 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_118(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_118(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_119(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i8
 %value = sitofp i8 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_119(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_119(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_120(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i11
 %value = uitofp i11 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_120(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_120(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_121(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i11
 %value = uitofp i11 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_121(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_121(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_122(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i11
 %value = uitofp i11 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_122(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_122(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_123(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i11
 %value = uitofp i11 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_123(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_123(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_124(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i11
 %value = uitofp i11 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_124(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_124(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_125(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i11
 %value = uitofp i11 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_125(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_125(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_126(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i11
 %value = uitofp i11 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_126(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_126(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_127(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i11
 %value = uitofp i11 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_127(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_127(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_128(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i11
 %value = uitofp i11 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_128(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_128(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_129(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i11
 %value = uitofp i11 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_129(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_129(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_130(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i11
 %value = uitofp i11 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_130(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_130(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_131(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i11
 %value = uitofp i11 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_131(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_131(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_132(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i11
 %value = sitofp i11 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_132(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_132(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_133(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i11
 %value = sitofp i11 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_133(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_133(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_134(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i11
 %value = sitofp i11 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_134(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_134(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_135(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i11
 %value = sitofp i11 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_135(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_135(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_136(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i11
 %value = sitofp i11 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_136(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_136(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_137(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i11
 %value = sitofp i11 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_137(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_137(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_138(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i11
 %value = sitofp i11 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_138(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_138(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_139(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i11
 %value = sitofp i11 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_139(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_139(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_140(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i11
 %value = sitofp i11 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_140(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_140(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_141(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i11
 %value = sitofp i11 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_141(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_141(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_142(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i11
 %value = sitofp i11 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_142(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_142(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_143(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i11
 %value = sitofp i11 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_143(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_143(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_144(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i12
 %value = uitofp i12 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_144(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_144(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_145(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i12
 %value = uitofp i12 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_145(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_145(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_146(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i12
 %value = uitofp i12 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_146(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_146(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_147(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i12
 %value = uitofp i12 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_147(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_147(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_148(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i12
 %value = uitofp i12 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_148(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_148(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_149(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i12
 %value = uitofp i12 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_149(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_149(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_150(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i12
 %value = uitofp i12 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_150(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_150(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_151(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i12
 %value = uitofp i12 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_151(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_151(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_152(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i12
 %value = uitofp i12 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_152(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_152(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_153(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i12
 %value = uitofp i12 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_153(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_153(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_154(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i12
 %value = uitofp i12 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_154(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_154(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_155(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i12
 %value = uitofp i12 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_155(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_155(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_156(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i12
 %value = sitofp i12 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_156(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_156(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_157(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i12
 %value = sitofp i12 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_157(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_157(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_158(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i12
 %value = sitofp i12 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_158(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_158(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_159(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i12
 %value = sitofp i12 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_159(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_159(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_160(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i12
 %value = sitofp i12 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_160(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_160(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_161(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i12
 %value = sitofp i12 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_161(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_161(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_162(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i12
 %value = sitofp i12 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_162(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_162(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_163(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i12
 %value = sitofp i12 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_163(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_163(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_164(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i12
 %value = sitofp i12 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_164(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_164(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_165(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i12
 %value = sitofp i12 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_165(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_165(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_166(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i12
 %value = sitofp i12 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_166(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_166(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_167(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i12
 %value = sitofp i12 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_167(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_167(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_168(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i15
 %value = uitofp i15 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_168(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_168(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_169(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i15
 %value = uitofp i15 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_169(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_169(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_170(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i15
 %value = uitofp i15 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_170(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_170(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_171(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i15
 %value = uitofp i15 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_171(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_171(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_172(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i15
 %value = uitofp i15 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_172(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_172(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_173(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i15
 %value = uitofp i15 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_173(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_173(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_174(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i15
 %value = uitofp i15 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_174(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_174(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_175(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i15
 %value = uitofp i15 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_175(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_175(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_176(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i15
 %value = uitofp i15 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_176(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_176(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_177(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i15
 %value = uitofp i15 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_177(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_177(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_178(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i15
 %value = uitofp i15 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_178(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_178(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_179(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i15
 %value = uitofp i15 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_179(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_179(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_180(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i15
 %value = sitofp i15 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_180(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_180(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_181(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i15
 %value = sitofp i15 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_181(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_181(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_182(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i15
 %value = sitofp i15 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_182(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_182(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_183(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i15
 %value = sitofp i15 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_183(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_183(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_184(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i15
 %value = sitofp i15 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_184(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_184(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_185(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i15
 %value = sitofp i15 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_185(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_185(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_186(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i15
 %value = sitofp i15 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_186(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_186(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_187(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i15
 %value = sitofp i15 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_187(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_187(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_188(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i15
 %value = sitofp i15 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_188(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_188(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_189(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i15
 %value = sitofp i15 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_189(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_189(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_190(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i15
 %value = sitofp i15 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_190(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_190(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_191(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i15
 %value = sitofp i15 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_191(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_191(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_192(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i16
 %value = uitofp i16 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_192(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_192(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_193(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i16
 %value = uitofp i16 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_193(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_193(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_194(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i16
 %value = uitofp i16 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_194(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_194(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_195(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i16
 %value = uitofp i16 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_195(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_195(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_196(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i16
 %value = uitofp i16 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_196(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_196(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_197(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i16
 %value = uitofp i16 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_197(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_197(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_198(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i16
 %value = uitofp i16 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_198(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_198(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_199(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i16
 %value = uitofp i16 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_199(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_199(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_200(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i16
 %value = uitofp i16 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_200(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_200(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_201(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i16
 %value = uitofp i16 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_201(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_201(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_202(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i16
 %value = uitofp i16 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_202(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_202(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_203(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i16
 %value = uitofp i16 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_203(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_203(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_204(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i16
 %value = sitofp i16 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_204(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_204(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_205(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i16
 %value = sitofp i16 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_205(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_205(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_206(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i16
 %value = sitofp i16 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_206(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_206(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_207(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i16
 %value = sitofp i16 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_207(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_207(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_208(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i16
 %value = sitofp i16 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_208(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_208(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_209(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i16
 %value = sitofp i16 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_209(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_209(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_210(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i16
 %value = sitofp i16 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_210(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_210(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_211(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i16
 %value = sitofp i16 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_211(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_211(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_212(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i16
 %value = sitofp i16 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_212(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_212(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_213(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i16
 %value = sitofp i16 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_213(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_213(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_214(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i16
 %value = sitofp i16 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_214(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_214(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_215(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i16
 %value = sitofp i16 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_215(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_215(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_216(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i17
 %value = uitofp i17 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_216(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_216(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_217(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i17
 %value = uitofp i17 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_217(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_217(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_218(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i17
 %value = uitofp i17 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_218(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_218(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_219(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i17
 %value = uitofp i17 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_219(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_219(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_220(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i17
 %value = uitofp i17 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_220(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_220(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_221(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i17
 %value = uitofp i17 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_221(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_221(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_222(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i17
 %value = uitofp i17 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_222(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_222(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_223(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i17
 %value = uitofp i17 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_223(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_223(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_224(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i17
 %value = uitofp i17 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_224(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_224(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_225(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i17
 %value = uitofp i17 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_225(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_225(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_226(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i17
 %value = uitofp i17 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_226(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_226(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_227(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i17
 %value = uitofp i17 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_227(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_227(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_228(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i17
 %value = sitofp i17 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_228(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_228(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_229(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i17
 %value = sitofp i17 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_229(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_229(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_230(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i17
 %value = sitofp i17 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_230(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_230(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_231(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i17
 %value = sitofp i17 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_231(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_231(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_232(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i17
 %value = sitofp i17 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_232(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_232(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_233(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i17
 %value = sitofp i17 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_233(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_233(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_234(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i17
 %value = sitofp i17 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_234(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_234(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_235(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i17
 %value = sitofp i17 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_235(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_235(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_236(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i17
 %value = sitofp i17 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_236(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_236(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_237(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i17
 %value = sitofp i17 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_237(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_237(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_238(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i17
 %value = sitofp i17 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_238(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_238(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_239(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i17
 %value = sitofp i17 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_239(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_239(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_240(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i24
 %value = uitofp i24 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_240(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_240(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_241(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i24
 %value = uitofp i24 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_241(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_241(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_242(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i24
 %value = uitofp i24 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_242(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_242(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_243(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i24
 %value = uitofp i24 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_243(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_243(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_244(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i24
 %value = uitofp i24 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_244(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_244(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_245(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i24
 %value = uitofp i24 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_245(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_245(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_246(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i24
 %value = uitofp i24 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_246(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_246(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_247(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i24
 %value = uitofp i24 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_247(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_247(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_248(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i24
 %value = uitofp i24 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_248(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_248(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_249(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i24
 %value = uitofp i24 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_249(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_249(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_250(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i24
 %value = uitofp i24 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_250(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_250(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_251(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i24
 %value = uitofp i24 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_251(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_251(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_252(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i24
 %value = sitofp i24 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_252(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_252(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_253(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i24
 %value = sitofp i24 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_253(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_253(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_254(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i24
 %value = sitofp i24 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_254(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_254(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_255(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i24
 %value = sitofp i24 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_255(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_255(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_256(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i24
 %value = sitofp i24 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_256(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_256(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_257(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i24
 %value = sitofp i24 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_257(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_257(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_258(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i24
 %value = sitofp i24 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_258(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_258(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_259(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i24
 %value = sitofp i24 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_259(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_259(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_260(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i24
 %value = sitofp i24 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_260(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_260(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_261(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i24
 %value = sitofp i24 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_261(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_261(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_262(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i24
 %value = sitofp i24 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_262(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_262(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_263(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i24
 %value = sitofp i24 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_263(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_263(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_264(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i31
 %value = uitofp i31 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_264(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_264(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_265(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i31
 %value = uitofp i31 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_265(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_265(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_266(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i31
 %value = uitofp i31 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_266(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_266(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_267(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i31
 %value = uitofp i31 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_267(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_267(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_268(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i31
 %value = uitofp i31 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_268(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_268(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_269(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i31
 %value = uitofp i31 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_269(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_269(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_270(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i31
 %value = uitofp i31 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_270(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_270(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_271(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i31
 %value = uitofp i31 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_271(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_271(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_272(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i31
 %value = uitofp i31 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_272(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_272(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_273(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i31
 %value = uitofp i31 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_273(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_273(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_274(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i31
 %value = uitofp i31 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_274(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_274(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_275(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i31
 %value = uitofp i31 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_275(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_275(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_276(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i31
 %value = sitofp i31 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_276(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_276(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_277(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p0 to i31
 %value = sitofp i31 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_277(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_277(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_278(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i31
 %value = sitofp i31 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_278(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_278(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_279(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p1 to i31
 %value = sitofp i31 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_279(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_279(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_280(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i31
 %value = sitofp i31 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_280(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_280(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_281(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p2 to i31
 %value = sitofp i31 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_281(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_281(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_282(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i31
 %value = sitofp i31 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_282(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_282(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_283(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p3 to i31
 %value = sitofp i31 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_283(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_283(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_284(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i31
 %value = sitofp i31 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_284(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_284(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_285(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p4 to i31
 %value = sitofp i31 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_285(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_285(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @narrow_half_body_286(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i31
 %value = sitofp i31 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_286(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call i64 @narrow_half_body_286(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @narrow_half_body_287(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %input = trunc i64 %p5 to i31
 %value = sitofp i31 %input to half
 %raw = bitcast half %value to i16
 %wide = zext i16 %raw to i64
 %m0 = mul i64 %wide,1099511628211
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
define i64 @narrow_half_probe_287(ptr %input,ptr %out,i64 %salt) {
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
 %answer = call fastcc i64 @narrow_half_body_287(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
