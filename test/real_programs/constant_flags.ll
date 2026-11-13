target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
define i64 @constant_flags_body_0(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_0(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_0(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_1(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_1(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_1(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_2(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i1 1,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_2(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_2(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_3(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i1 1,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_3(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_3(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_4(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i1 0,1
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_4(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_4(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_5(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i1 0,1
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_5(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_5(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_6(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_6(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_6(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_7(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_7(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_7(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_8(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_8(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_8(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_9(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_9(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_9(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_10(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_10(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_10(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_11(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_11(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_11(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_12(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i1 1,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_12(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_12(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_13(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i1 1,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_13(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_13(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_14(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i1 0,1
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_14(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_14(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_15(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i1 0,1
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_15(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_15(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_16(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_16(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_16(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_17(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_17(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_17(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_18(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_18(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_18(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_19(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_19(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_19(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_20(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_20(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_20(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_21(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_21(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_21(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_22(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i1 1,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_22(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_22(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_23(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i1 1,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_23(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_23(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_24(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i1 0,1
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_24(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_24(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_25(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i1 0,1
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_25(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_25(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_26(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_26(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_26(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_27(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_27(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_27(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_28(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_28(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_28(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_29(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_29(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_29(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_30(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_30(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_30(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_31(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_31(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_31(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_32(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i1 1,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_32(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_32(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_33(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i1 1,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_33(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_33(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_34(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_34(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_34(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_35(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_35(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_35(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_36(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_36(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_36(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_37(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_37(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_37(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_38(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_38(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_38(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_39(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_39(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_39(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_40(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i1 1,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_40(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_40(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_41(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i1 1,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_41(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_41(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_42(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_42(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_42(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_43(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_43(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_43(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_44(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_44(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_44(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_45(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_45(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_45(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_46(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_46(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_46(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_47(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_47(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_47(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_48(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i1 1,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_48(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_48(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_49(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i1 1,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_49(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_49(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_50(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_50(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_50(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_51(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_51(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_51(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_52(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_52(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_52(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_53(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_53(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_53(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_54(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_54(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_54(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_55(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_55(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_55(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_56(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i1 1,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_56(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_56(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_57(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i1 1,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_57(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_57(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_58(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i1 0,1
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_58(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_58(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_59(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i1 0,1
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_59(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_59(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_60(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_60(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_60(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_61(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_61(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_61(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_62(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_62(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_62(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_63(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_63(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_63(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_64(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_64(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_64(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_65(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_65(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_65(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_66(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i1 1,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_66(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_66(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_67(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i1 1,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_67(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_67(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_68(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i1 0,1
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_68(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_68(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_69(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i1 0,1
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_69(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_69(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_70(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_70(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_70(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_71(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_71(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_71(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_72(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_72(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_72(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_73(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_73(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_73(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_74(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_74(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_74(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_75(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_75(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_75(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_76(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i1 1,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_76(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_76(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_77(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i1 1,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_77(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_77(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_78(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i1 0,1
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_78(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_78(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_79(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i1 0,1
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_79(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_79(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_80(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_80(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_80(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_81(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_81(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_81(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_82(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_82(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_82(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_83(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i1 0,0
 %wide = zext i1 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_83(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_83(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_84(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i3 0,0
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_84(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_84(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_85(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i3 0,0
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_85(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_85(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_86(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i3 7,0
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_86(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_86(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_87(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i3 7,0
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_87(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_87(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_88(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i3 3,1
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_88(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_88(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_89(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i3 3,1
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_89(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_89(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_90(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i3 1,2
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_90(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_90(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_91(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i3 1,2
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_91(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_91(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_92(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i3 2,-4
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_92(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_92(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_93(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i3 2,-4
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_93(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_93(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_94(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i3 0,0
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_94(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_94(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_95(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i3 0,0
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_95(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_95(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_96(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i3 7,0
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_96(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_96(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_97(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i3 7,0
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_97(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_97(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_98(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i3 1,2
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_98(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_98(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_99(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i3 1,2
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_99(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_99(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_100(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i3 2,-4
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_100(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_100(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_101(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i3 2,-4
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_101(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_101(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_102(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i3 0,0
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_102(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_102(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_103(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i3 0,0
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_103(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_103(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_104(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i3 7,0
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_104(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_104(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_105(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i3 7,0
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_105(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_105(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_106(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i3 1,2
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_106(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_106(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_107(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i3 1,2
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_107(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_107(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_108(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i3 2,-4
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_108(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_108(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_109(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i3 2,-4
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_109(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_109(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_110(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i3 0,0
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_110(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_110(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_111(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i3 0,0
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_111(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_111(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_112(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i3 7,0
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_112(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_112(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_113(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i3 7,0
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_113(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_113(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_114(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i3 3,1
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_114(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_114(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_115(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i3 3,1
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_115(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_115(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_116(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i3 0,0
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_116(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_116(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_117(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i3 0,0
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_117(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_117(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_118(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i3 7,0
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_118(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_118(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_119(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i3 7,0
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_119(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_119(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_120(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i3 3,1
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_120(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_120(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_121(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i3 3,1
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_121(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_121(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_122(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i3 1,2
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_122(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_122(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_123(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i3 1,2
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_123(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_123(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_124(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i3 0,0
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_124(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_124(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_125(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i3 0,0
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_125(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_125(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_126(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i3 7,0
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_126(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_126(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_127(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i3 7,0
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_127(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_127(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_128(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i3 3,1
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_128(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_128(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_129(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i3 3,1
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_129(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_129(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_130(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i3 0,0
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_130(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_130(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_131(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i3 0,0
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_131(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_131(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_132(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i3 7,0
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_132(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_132(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_133(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i3 7,0
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_133(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_133(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_134(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i3 3,1
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_134(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_134(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_135(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i3 3,1
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_135(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_135(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_136(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i3 1,2
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_136(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_136(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_137(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i3 1,2
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_137(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_137(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_138(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i3 0,0
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_138(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_138(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_139(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i3 0,0
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_139(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_139(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_140(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i3 7,0
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_140(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_140(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_141(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i3 7,0
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_141(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_141(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_142(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i3 3,1
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_142(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_142(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_143(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i3 3,1
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_143(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_143(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_144(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i3 1,2
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_144(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_144(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_145(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i3 1,2
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_145(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_145(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_146(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i3 0,0
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_146(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_146(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_147(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i3 0,0
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_147(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_147(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_148(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i3 7,0
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_148(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_148(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_149(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i3 7,0
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_149(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_149(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_150(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i3 3,1
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_150(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_150(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_151(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i3 3,1
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_151(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_151(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_152(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i3 1,2
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_152(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_152(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_153(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i3 1,2
 %wide = zext i3 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_153(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_153(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_154(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i8 0,0
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_154(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_154(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_155(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i8 0,0
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_155(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_155(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_156(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i8 255,0
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_156(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_156(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_157(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i8 255,0
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_157(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_157(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_158(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i8 127,1
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_158(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_158(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_159(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i8 127,1
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_159(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_159(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_160(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i8 63,2
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_160(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_160(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_161(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i8 63,2
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_161(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_161(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_162(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i8 0,0
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_162(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_162(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_163(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i8 0,0
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_163(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_163(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_164(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i8 255,0
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_164(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_164(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_165(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i8 255,0
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_165(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_165(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_166(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i8 63,2
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_166(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_166(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_167(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i8 63,2
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_167(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_167(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_168(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i8 10,-4
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_168(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_168(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_169(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i8 10,-4
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_169(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_169(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_170(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i8 0,0
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_170(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_170(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_171(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i8 0,0
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_171(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_171(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_172(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i8 255,0
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_172(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_172(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_173(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i8 255,0
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_173(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_173(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_174(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i8 63,2
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_174(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_174(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_175(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i8 63,2
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_175(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_175(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_176(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i8 0,0
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_176(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_176(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_177(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i8 0,0
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_177(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_177(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_178(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i8 255,0
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_178(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_178(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_179(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i8 255,0
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_179(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_179(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_180(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i8 127,1
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_180(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_180(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_181(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i8 127,1
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_181(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_181(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_182(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i8 63,2
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_182(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_182(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_183(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i8 63,2
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_183(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_183(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_184(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i8 0,0
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_184(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_184(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_185(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i8 0,0
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_185(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_185(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_186(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i8 255,0
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_186(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_186(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_187(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i8 255,0
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_187(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_187(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_188(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i8 127,1
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_188(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_188(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_189(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i8 127,1
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_189(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_189(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_190(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i8 63,2
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_190(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_190(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_191(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i8 63,2
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_191(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_191(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_192(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i8 10,-4
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_192(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_192(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_193(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i8 10,-4
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_193(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_193(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_194(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i8 0,0
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_194(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_194(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_195(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i8 0,0
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_195(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_195(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_196(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i8 255,0
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_196(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_196(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_197(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i8 255,0
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_197(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_197(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_198(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i8 127,1
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_198(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_198(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_199(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i8 127,1
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_199(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_199(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_200(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i8 63,2
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_200(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_200(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_201(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i8 63,2
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_201(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_201(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_202(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i8 0,0
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_202(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_202(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_203(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i8 0,0
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_203(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_203(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_204(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i8 255,0
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_204(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_204(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_205(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i8 255,0
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_205(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_205(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_206(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i8 127,1
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_206(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_206(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_207(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i8 127,1
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_207(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_207(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_208(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i8 63,2
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_208(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_208(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_209(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i8 63,2
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_209(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_209(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_210(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i8 0,0
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_210(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_210(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_211(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i8 0,0
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_211(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_211(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_212(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i8 255,0
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_212(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_212(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_213(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i8 255,0
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_213(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_213(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_214(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i8 127,1
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_214(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_214(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_215(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i8 127,1
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_215(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_215(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_216(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i8 63,2
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_216(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_216(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_217(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i8 63,2
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_217(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_217(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_218(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i8 10,-4
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_218(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_218(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_219(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i8 10,-4
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_219(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_219(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_220(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i8 0,0
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_220(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_220(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_221(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i8 0,0
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_221(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_221(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_222(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i8 255,0
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_222(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_222(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_223(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i8 255,0
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_223(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_223(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_224(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i8 127,1
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_224(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_224(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_225(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i8 127,1
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_225(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_225(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_226(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i8 63,2
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_226(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_226(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_227(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i8 63,2
 %wide = zext i8 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_227(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_227(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_228(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i17 0,0
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_228(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_228(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_229(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i17 0,0
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_229(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_229(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_230(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i17 131071,0
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_230(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_230(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_231(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i17 131071,0
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_231(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_231(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_232(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i17 65535,1
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_232(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_232(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_233(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i17 65535,1
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_233(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_233(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_234(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i17 32767,2
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_234(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_234(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_235(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i17 32767,2
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_235(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_235(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_236(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i17 0,0
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_236(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_236(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_237(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i17 0,0
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_237(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_237(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_238(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i17 131071,0
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_238(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_238(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_239(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i17 131071,0
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_239(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_239(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_240(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i17 32767,2
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_240(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_240(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_241(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i17 32767,2
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_241(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_241(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_242(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i17 10,-4
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_242(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_242(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_243(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i17 10,-4
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_243(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_243(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_244(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i17 0,0
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_244(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_244(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_245(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i17 0,0
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_245(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_245(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_246(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i17 131071,0
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_246(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_246(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_247(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i17 131071,0
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_247(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_247(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_248(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i17 32767,2
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_248(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_248(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_249(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i17 32767,2
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_249(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_249(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_250(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i17 0,0
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_250(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_250(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_251(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i17 0,0
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_251(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_251(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_252(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i17 131071,0
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_252(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_252(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_253(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i17 131071,0
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_253(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_253(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_254(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i17 65535,1
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_254(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_254(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_255(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i17 65535,1
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_255(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_255(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_256(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i17 32767,2
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_256(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_256(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_257(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i17 32767,2
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_257(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_257(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_258(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i17 0,0
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_258(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_258(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_259(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i17 0,0
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_259(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_259(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_260(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i17 131071,0
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_260(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_260(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_261(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i17 131071,0
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_261(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_261(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_262(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i17 65535,1
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_262(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_262(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_263(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i17 65535,1
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_263(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_263(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_264(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i17 32767,2
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_264(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_264(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_265(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i17 32767,2
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_265(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_265(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_266(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i17 10,-4
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_266(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_266(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_267(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i17 10,-4
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_267(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_267(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_268(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i17 0,0
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_268(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_268(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_269(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i17 0,0
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_269(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_269(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_270(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i17 131071,0
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_270(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_270(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_271(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i17 131071,0
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_271(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_271(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_272(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i17 65535,1
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_272(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_272(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_273(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i17 65535,1
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_273(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_273(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_274(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i17 32767,2
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_274(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_274(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_275(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i17 32767,2
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_275(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_275(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_276(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i17 0,0
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_276(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_276(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_277(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i17 0,0
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_277(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_277(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_278(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i17 131071,0
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_278(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_278(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_279(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i17 131071,0
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_279(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_279(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_280(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i17 65535,1
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_280(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_280(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_281(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i17 65535,1
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_281(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_281(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_282(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i17 32767,2
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_282(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_282(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_283(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i17 32767,2
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_283(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_283(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_284(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i17 0,0
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_284(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_284(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_285(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i17 0,0
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_285(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_285(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_286(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i17 131071,0
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_286(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_286(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_287(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i17 131071,0
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_287(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_287(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_288(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i17 65535,1
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_288(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_288(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_289(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i17 65535,1
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_289(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_289(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_290(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i17 32767,2
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_290(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_290(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_291(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i17 32767,2
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_291(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_291(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_292(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i17 10,-4
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_292(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_292(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_293(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i17 10,-4
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_293(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_293(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_294(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i17 0,0
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_294(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_294(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_295(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i17 0,0
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_295(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_295(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_296(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i17 131071,0
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_296(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_296(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_297(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i17 131071,0
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_297(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_297(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_298(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i17 65535,1
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_298(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_298(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_299(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i17 65535,1
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_299(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_299(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_300(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i17 32767,2
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_300(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_300(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_301(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i17 32767,2
 %wide = zext i17 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_301(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_301(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_302(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i32 0,0
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_302(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_302(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_303(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i32 0,0
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_303(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_303(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_304(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i32 4294967295,0
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_304(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_304(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_305(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i32 4294967295,0
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_305(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_305(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_306(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i32 2147483647,1
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_306(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_306(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_307(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i32 2147483647,1
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_307(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_307(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_308(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i32 1073741823,2
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_308(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_308(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_309(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i32 1073741823,2
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_309(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_309(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_310(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i32 0,0
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_310(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_310(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_311(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i32 0,0
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_311(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_311(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_312(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i32 4294967295,0
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_312(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_312(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_313(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i32 4294967295,0
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_313(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_313(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_314(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i32 1073741823,2
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_314(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_314(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_315(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i32 1073741823,2
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_315(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_315(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_316(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i32 10,-4
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_316(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_316(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_317(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i32 10,-4
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_317(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_317(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_318(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i32 0,0
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_318(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_318(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_319(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i32 0,0
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_319(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_319(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_320(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i32 4294967295,0
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_320(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_320(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_321(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i32 4294967295,0
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_321(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_321(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_322(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i32 1073741823,2
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_322(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_322(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_323(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i32 1073741823,2
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_323(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_323(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_324(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i32 0,0
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_324(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_324(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_325(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i32 0,0
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_325(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_325(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_326(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i32 4294967295,0
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_326(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_326(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_327(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i32 4294967295,0
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_327(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_327(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_328(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i32 2147483647,1
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_328(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_328(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_329(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i32 2147483647,1
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_329(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_329(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_330(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i32 1073741823,2
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_330(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_330(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_331(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i32 1073741823,2
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_331(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_331(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_332(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i32 0,0
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_332(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_332(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_333(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i32 0,0
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_333(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_333(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_334(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i32 4294967295,0
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_334(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_334(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_335(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i32 4294967295,0
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_335(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_335(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_336(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i32 2147483647,1
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_336(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_336(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_337(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i32 2147483647,1
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_337(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_337(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_338(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i32 1073741823,2
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_338(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_338(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_339(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i32 1073741823,2
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_339(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_339(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_340(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i32 10,-4
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_340(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_340(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_341(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i32 10,-4
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_341(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_341(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_342(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i32 0,0
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_342(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_342(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_343(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i32 0,0
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_343(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_343(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_344(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i32 4294967295,0
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_344(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_344(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_345(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i32 4294967295,0
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_345(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_345(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_346(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i32 2147483647,1
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_346(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_346(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_347(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i32 2147483647,1
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_347(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_347(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_348(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i32 1073741823,2
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_348(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_348(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_349(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i32 1073741823,2
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_349(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_349(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_350(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i32 0,0
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_350(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_350(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_351(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i32 0,0
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_351(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_351(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_352(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i32 4294967295,0
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_352(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_352(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_353(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i32 4294967295,0
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_353(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_353(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_354(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i32 2147483647,1
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_354(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_354(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_355(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i32 2147483647,1
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_355(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_355(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_356(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i32 1073741823,2
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_356(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_356(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_357(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i32 1073741823,2
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_357(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_357(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_358(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i32 0,0
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_358(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_358(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_359(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i32 0,0
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_359(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_359(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_360(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i32 4294967295,0
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_360(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_360(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_361(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i32 4294967295,0
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_361(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_361(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_362(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i32 2147483647,1
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_362(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_362(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_363(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i32 2147483647,1
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_363(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_363(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_364(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i32 1073741823,2
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_364(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_364(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_365(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i32 1073741823,2
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_365(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_365(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_366(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i32 10,-4
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_366(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_366(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_367(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i32 10,-4
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_367(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_367(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_368(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i32 0,0
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_368(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_368(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_369(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i32 0,0
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_369(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_369(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_370(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i32 4294967295,0
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_370(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_370(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_371(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i32 4294967295,0
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_371(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_371(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_372(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i32 2147483647,1
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_372(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_372(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_373(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i32 2147483647,1
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_373(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_373(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_374(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i32 1073741823,2
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_374(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_374(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_375(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i32 1073741823,2
 %wide = zext i32 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_375(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_375(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_376(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i48 0,0
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_376(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_376(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_377(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i48 0,0
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_377(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_377(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_378(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i48 281474976710655,0
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_378(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_378(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_379(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i48 281474976710655,0
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_379(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_379(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_380(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i48 140737488355327,1
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_380(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_380(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_381(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i48 140737488355327,1
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_381(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_381(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_382(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i48 70368744177663,2
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_382(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_382(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_383(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i48 70368744177663,2
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_383(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_383(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_384(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i48 0,0
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_384(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_384(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_385(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i48 0,0
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_385(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_385(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_386(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i48 281474976710655,0
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_386(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_386(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_387(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i48 281474976710655,0
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_387(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_387(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_388(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i48 70368744177663,2
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_388(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_388(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_389(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i48 70368744177663,2
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_389(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_389(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_390(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i48 10,-4
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_390(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_390(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_391(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i48 10,-4
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_391(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_391(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_392(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i48 0,0
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_392(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_392(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_393(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i48 0,0
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_393(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_393(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_394(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i48 281474976710655,0
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_394(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_394(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_395(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i48 281474976710655,0
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_395(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_395(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_396(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i48 70368744177663,2
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_396(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_396(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_397(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i48 70368744177663,2
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_397(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_397(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_398(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i48 0,0
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_398(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_398(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_399(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i48 0,0
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_399(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_399(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_400(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i48 281474976710655,0
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_400(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_400(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_401(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i48 281474976710655,0
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_401(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_401(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_402(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i48 140737488355327,1
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_402(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_402(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_403(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i48 140737488355327,1
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_403(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_403(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_404(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i48 70368744177663,2
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_404(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_404(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_405(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i48 70368744177663,2
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_405(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_405(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_406(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i48 0,0
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_406(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_406(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_407(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i48 0,0
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_407(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_407(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_408(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i48 281474976710655,0
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_408(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_408(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_409(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i48 281474976710655,0
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_409(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_409(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_410(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i48 140737488355327,1
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_410(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_410(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_411(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i48 140737488355327,1
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_411(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_411(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_412(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i48 70368744177663,2
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_412(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_412(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_413(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i48 70368744177663,2
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_413(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_413(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_414(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i48 10,-4
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_414(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_414(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_415(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i48 10,-4
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_415(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_415(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_416(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i48 0,0
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_416(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_416(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_417(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i48 0,0
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_417(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_417(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_418(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i48 281474976710655,0
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_418(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_418(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_419(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i48 281474976710655,0
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_419(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_419(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_420(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i48 140737488355327,1
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_420(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_420(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_421(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i48 140737488355327,1
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_421(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_421(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_422(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i48 70368744177663,2
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_422(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_422(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_423(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i48 70368744177663,2
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_423(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_423(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_424(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i48 0,0
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_424(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_424(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_425(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i48 0,0
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_425(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_425(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_426(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i48 281474976710655,0
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_426(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_426(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_427(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i48 281474976710655,0
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_427(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_427(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_428(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i48 140737488355327,1
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_428(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_428(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_429(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i48 140737488355327,1
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_429(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_429(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_430(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i48 70368744177663,2
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_430(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_430(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_431(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i48 70368744177663,2
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_431(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_431(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_432(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i48 0,0
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_432(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_432(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_433(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i48 0,0
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_433(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_433(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_434(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i48 281474976710655,0
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_434(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_434(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_435(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i48 281474976710655,0
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_435(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_435(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_436(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i48 140737488355327,1
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_436(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_436(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_437(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i48 140737488355327,1
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_437(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_437(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_438(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i48 70368744177663,2
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_438(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_438(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_439(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i48 70368744177663,2
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_439(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_439(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_440(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i48 10,-4
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_440(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_440(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_441(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i48 10,-4
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_441(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_441(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_442(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i48 0,0
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_442(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_442(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_443(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i48 0,0
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_443(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_443(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_444(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i48 281474976710655,0
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_444(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_444(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_445(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i48 281474976710655,0
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_445(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_445(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_446(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i48 140737488355327,1
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_446(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_446(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_447(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i48 140737488355327,1
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_447(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_447(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_448(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i48 70368744177663,2
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_448(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_448(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_449(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i48 70368744177663,2
 %wide = zext i48 %value to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_449(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_449(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_450(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i64 0,0
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_450(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_450(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_451(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i64 0,0
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_451(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_451(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_452(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i64 18446744073709551615,0
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_452(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_452(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_453(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i64 18446744073709551615,0
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_453(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_453(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_454(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i64 9223372036854775807,1
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_454(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_454(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_455(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i64 9223372036854775807,1
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_455(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_455(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_456(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i64 4611686018427387903,2
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_456(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_456(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_457(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw i64 4611686018427387903,2
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_457(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_457(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_458(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i64 0,0
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_458(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_458(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_459(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i64 0,0
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_459(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_459(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_460(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i64 18446744073709551615,0
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_460(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_460(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_461(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i64 18446744073709551615,0
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_461(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_461(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_462(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i64 4611686018427387903,2
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_462(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_462(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_463(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i64 4611686018427387903,2
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_463(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_463(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_464(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i64 10,-4
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_464(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_464(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_465(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nsw i64 10,-4
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_465(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_465(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_466(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i64 0,0
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_466(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_466(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_467(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i64 0,0
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_467(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_467(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_468(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i64 18446744073709551615,0
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_468(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_468(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_469(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i64 18446744073709551615,0
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_469(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_469(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_470(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i64 4611686018427387903,2
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_470(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_470(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_471(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = add nuw nsw i64 4611686018427387903,2
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_471(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_471(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_472(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i64 0,0
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_472(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_472(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_473(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i64 0,0
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_473(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_473(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_474(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i64 18446744073709551615,0
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_474(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_474(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_475(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i64 18446744073709551615,0
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_475(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_475(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_476(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i64 9223372036854775807,1
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_476(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_476(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_477(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i64 9223372036854775807,1
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_477(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_477(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_478(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i64 4611686018427387903,2
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_478(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_478(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_479(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw i64 4611686018427387903,2
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_479(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_479(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_480(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i64 0,0
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_480(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_480(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_481(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i64 0,0
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_481(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_481(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_482(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i64 18446744073709551615,0
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_482(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_482(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_483(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i64 18446744073709551615,0
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_483(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_483(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_484(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i64 9223372036854775807,1
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_484(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_484(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_485(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i64 9223372036854775807,1
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_485(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_485(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_486(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i64 4611686018427387903,2
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_486(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_486(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_487(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i64 4611686018427387903,2
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_487(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_487(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_488(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i64 10,-4
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_488(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_488(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_489(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nsw i64 10,-4
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_489(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_489(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_490(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i64 0,0
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_490(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_490(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_491(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i64 0,0
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_491(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_491(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_492(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i64 18446744073709551615,0
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_492(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_492(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_493(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i64 18446744073709551615,0
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_493(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_493(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_494(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i64 9223372036854775807,1
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_494(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_494(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_495(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i64 9223372036854775807,1
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_495(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_495(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_496(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i64 4611686018427387903,2
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_496(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_496(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_497(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = sub nuw nsw i64 4611686018427387903,2
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_497(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_497(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_498(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i64 0,0
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_498(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_498(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_499(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i64 0,0
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_499(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_499(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_500(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i64 18446744073709551615,0
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_500(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_500(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_501(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i64 18446744073709551615,0
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_501(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_501(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_502(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i64 9223372036854775807,1
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_502(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_502(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_503(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i64 9223372036854775807,1
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_503(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_503(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_504(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i64 4611686018427387903,2
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_504(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_504(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_505(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw i64 4611686018427387903,2
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_505(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_505(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_506(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i64 0,0
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_506(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_506(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_507(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i64 0,0
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_507(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_507(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_508(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i64 18446744073709551615,0
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_508(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_508(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_509(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i64 18446744073709551615,0
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_509(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_509(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_510(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i64 9223372036854775807,1
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_510(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_510(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_511(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i64 9223372036854775807,1
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_511(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_511(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_512(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i64 4611686018427387903,2
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_512(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_512(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_513(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i64 4611686018427387903,2
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_513(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_513(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_514(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i64 10,-4
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_514(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_514(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_515(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nsw i64 10,-4
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_515(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_515(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_516(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i64 0,0
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_516(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_516(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_517(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i64 0,0
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_517(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_517(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_518(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i64 18446744073709551615,0
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_518(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_518(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_519(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i64 18446744073709551615,0
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_519(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_519(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_520(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i64 9223372036854775807,1
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_520(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_520(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_521(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i64 9223372036854775807,1
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_521(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_521(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define i64 @constant_flags_body_522(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i64 4611686018427387903,2
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_522(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call i64 @constant_flags_body_522(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
define fastcc i64 @constant_flags_body_523(i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,ptr %out) noinline {
entry:
 %value = mul nuw nsw i64 4611686018427387903,2
 %wide = add i64 %value,0
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 ret i64 %r5
}
define i64 @constant_flags_probe_523(ptr %input,ptr %out,i64 %salt) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %v0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %v1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %v2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %v3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %v4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %v5 = load i64,ptr %a5,align 1
 %answer = call fastcc i64 @constant_flags_body_523(i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,ptr %out)
 store i64 %answer,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %v0,ptr %o2,align 1
 %r = xor i64 %answer,%salt
 ret i64 %r
}
