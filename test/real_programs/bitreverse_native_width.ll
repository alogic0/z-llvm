target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare i32 @llvm.bitreverse.i32(i32)
define i64 @bitreverse_native_width_body_0(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5) noinline {
entry:
 %input = trunc i64 %a0 to i32
 %v = call i32 @llvm.bitreverse.i32(i32 %input)
 %wide = zext i32 %v to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 ret i64 %r5
}
define i64 @bitreverse_native_width_probe_0(ptr %input,ptr %out,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %v = call i64 @bitreverse_native_width_body_0(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5)
 store i64 %v,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %next,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %a0,ptr %tail,align 1
 %r = xor i64 %v,%salt
 ret i64 %r
}
define fastcc i64 @bitreverse_native_width_body_1(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5) noinline {
entry:
 %input = trunc i64 %a0 to i32
 %v = call i32 @llvm.bitreverse.i32(i32 %input)
 %wide = zext i32 %v to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 ret i64 %r5
}
define i64 @bitreverse_native_width_probe_1(ptr %input,ptr %out,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %v = call fastcc i64 @bitreverse_native_width_body_1(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5)
 store i64 %v,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %next,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %a0,ptr %tail,align 1
 %r = xor i64 %v,%salt
 ret i64 %r
}
define i64 @bitreverse_native_width_body_2(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5) noinline {
entry:
 %input = trunc i64 %a1 to i32
 %v = call i32 @llvm.bitreverse.i32(i32 %input)
 %wide = zext i32 %v to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 ret i64 %r5
}
define i64 @bitreverse_native_width_probe_2(ptr %input,ptr %out,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %v = call i64 @bitreverse_native_width_body_2(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5)
 store i64 %v,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %next,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %a0,ptr %tail,align 1
 %r = xor i64 %v,%salt
 ret i64 %r
}
define fastcc i64 @bitreverse_native_width_body_3(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5) noinline {
entry:
 %input = trunc i64 %a1 to i32
 %v = call i32 @llvm.bitreverse.i32(i32 %input)
 %wide = zext i32 %v to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 ret i64 %r5
}
define i64 @bitreverse_native_width_probe_3(ptr %input,ptr %out,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %v = call fastcc i64 @bitreverse_native_width_body_3(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5)
 store i64 %v,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %next,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %a0,ptr %tail,align 1
 %r = xor i64 %v,%salt
 ret i64 %r
}
define i64 @bitreverse_native_width_body_4(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5) noinline {
entry:
 %input = trunc i64 %a2 to i32
 %v = call i32 @llvm.bitreverse.i32(i32 %input)
 %wide = zext i32 %v to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 ret i64 %r5
}
define i64 @bitreverse_native_width_probe_4(ptr %input,ptr %out,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %v = call i64 @bitreverse_native_width_body_4(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5)
 store i64 %v,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %next,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %a0,ptr %tail,align 1
 %r = xor i64 %v,%salt
 ret i64 %r
}
define fastcc i64 @bitreverse_native_width_body_5(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5) noinline {
entry:
 %input = trunc i64 %a2 to i32
 %v = call i32 @llvm.bitreverse.i32(i32 %input)
 %wide = zext i32 %v to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 ret i64 %r5
}
define i64 @bitreverse_native_width_probe_5(ptr %input,ptr %out,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %v = call fastcc i64 @bitreverse_native_width_body_5(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5)
 store i64 %v,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %next,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %a0,ptr %tail,align 1
 %r = xor i64 %v,%salt
 ret i64 %r
}
define i64 @bitreverse_native_width_body_6(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5) noinline {
entry:
 %input = trunc i64 %a3 to i32
 %v = call i32 @llvm.bitreverse.i32(i32 %input)
 %wide = zext i32 %v to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 ret i64 %r5
}
define i64 @bitreverse_native_width_probe_6(ptr %input,ptr %out,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %v = call i64 @bitreverse_native_width_body_6(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5)
 store i64 %v,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %next,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %a0,ptr %tail,align 1
 %r = xor i64 %v,%salt
 ret i64 %r
}
define fastcc i64 @bitreverse_native_width_body_7(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5) noinline {
entry:
 %input = trunc i64 %a3 to i32
 %v = call i32 @llvm.bitreverse.i32(i32 %input)
 %wide = zext i32 %v to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 ret i64 %r5
}
define i64 @bitreverse_native_width_probe_7(ptr %input,ptr %out,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %v = call fastcc i64 @bitreverse_native_width_body_7(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5)
 store i64 %v,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %next,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %a0,ptr %tail,align 1
 %r = xor i64 %v,%salt
 ret i64 %r
}
define i64 @bitreverse_native_width_body_8(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5) noinline {
entry:
 %input = trunc i64 %a4 to i32
 %v = call i32 @llvm.bitreverse.i32(i32 %input)
 %wide = zext i32 %v to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 ret i64 %r5
}
define i64 @bitreverse_native_width_probe_8(ptr %input,ptr %out,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %v = call i64 @bitreverse_native_width_body_8(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5)
 store i64 %v,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %next,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %a0,ptr %tail,align 1
 %r = xor i64 %v,%salt
 ret i64 %r
}
define fastcc i64 @bitreverse_native_width_body_9(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5) noinline {
entry:
 %input = trunc i64 %a4 to i32
 %v = call i32 @llvm.bitreverse.i32(i32 %input)
 %wide = zext i32 %v to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 ret i64 %r5
}
define i64 @bitreverse_native_width_probe_9(ptr %input,ptr %out,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %v = call fastcc i64 @bitreverse_native_width_body_9(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5)
 store i64 %v,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %next,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %a0,ptr %tail,align 1
 %r = xor i64 %v,%salt
 ret i64 %r
}
define i64 @bitreverse_native_width_body_10(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5) noinline {
entry:
 %input = trunc i64 %a5 to i32
 %v = call i32 @llvm.bitreverse.i32(i32 %input)
 %wide = zext i32 %v to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 ret i64 %r5
}
define i64 @bitreverse_native_width_probe_10(ptr %input,ptr %out,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %v = call i64 @bitreverse_native_width_body_10(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5)
 store i64 %v,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %next,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %a0,ptr %tail,align 1
 %r = xor i64 %v,%salt
 ret i64 %r
}
define fastcc i64 @bitreverse_native_width_body_11(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5) noinline {
entry:
 %input = trunc i64 %a5 to i32
 %v = call i32 @llvm.bitreverse.i32(i32 %input)
 %wide = zext i32 %v to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 ret i64 %r5
}
define i64 @bitreverse_native_width_probe_11(ptr %input,ptr %out,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %v = call fastcc i64 @bitreverse_native_width_body_11(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5)
 store i64 %v,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %next,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %a0,ptr %tail,align 1
 %r = xor i64 %v,%salt
 ret i64 %r
}
define i64 @bitreverse_native_width_body_12(i32 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5) noinline {
entry:
 %v = call i32 @llvm.bitreverse.i32(i32 %a0)
 %wide = zext i32 %v to i64
 %logical = zext i32 %a0 to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%logical
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 ret i64 %r5
}
define i64 @bitreverse_native_width_probe_12(ptr %input,ptr %out,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %logical = trunc i64 %a0 to i32
 %v = call i64 @bitreverse_native_width_body_12(i32 %logical,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5)
 store i64 %v,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %next,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %a0,ptr %tail,align 1
 %r = xor i64 %v,%salt
 ret i64 %r
}
define fastcc i64 @bitreverse_native_width_body_13(i32 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5) noinline {
entry:
 %v = call i32 @llvm.bitreverse.i32(i32 %a0)
 %wide = zext i32 %v to i64
 %logical = zext i32 %a0 to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%logical
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 ret i64 %r5
}
define i64 @bitreverse_native_width_probe_13(ptr %input,ptr %out,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %logical = trunc i64 %a0 to i32
 %v = call fastcc i64 @bitreverse_native_width_body_13(i32 %logical,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5)
 store i64 %v,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %next,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %a0,ptr %tail,align 1
 %r = xor i64 %v,%salt
 ret i64 %r
}
define i64 @bitreverse_native_width_body_14(i64 %a0,i32 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5) noinline {
entry:
 %v = call i32 @llvm.bitreverse.i32(i32 %a1)
 %wide = zext i32 %v to i64
 %logical = zext i32 %a1 to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%logical
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 ret i64 %r5
}
define i64 @bitreverse_native_width_probe_14(ptr %input,ptr %out,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %logical = trunc i64 %a1 to i32
 %v = call i64 @bitreverse_native_width_body_14(i64 %a0,i32 %logical,i64 %a2,i64 %a3,i64 %a4,i64 %a5)
 store i64 %v,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %next,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %a0,ptr %tail,align 1
 %r = xor i64 %v,%salt
 ret i64 %r
}
define fastcc i64 @bitreverse_native_width_body_15(i64 %a0,i32 %a1,i64 %a2,i64 %a3,i64 %a4,i64 %a5) noinline {
entry:
 %v = call i32 @llvm.bitreverse.i32(i32 %a1)
 %wide = zext i32 %v to i64
 %logical = zext i32 %a1 to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%logical
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 ret i64 %r5
}
define i64 @bitreverse_native_width_probe_15(ptr %input,ptr %out,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %logical = trunc i64 %a1 to i32
 %v = call fastcc i64 @bitreverse_native_width_body_15(i64 %a0,i32 %logical,i64 %a2,i64 %a3,i64 %a4,i64 %a5)
 store i64 %v,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %next,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %a0,ptr %tail,align 1
 %r = xor i64 %v,%salt
 ret i64 %r
}
define i64 @bitreverse_native_width_body_16(i64 %a0,i64 %a1,i32 %a2,i64 %a3,i64 %a4,i64 %a5) noinline {
entry:
 %v = call i32 @llvm.bitreverse.i32(i32 %a2)
 %wide = zext i32 %v to i64
 %logical = zext i32 %a2 to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%logical
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 ret i64 %r5
}
define i64 @bitreverse_native_width_probe_16(ptr %input,ptr %out,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %logical = trunc i64 %a2 to i32
 %v = call i64 @bitreverse_native_width_body_16(i64 %a0,i64 %a1,i32 %logical,i64 %a3,i64 %a4,i64 %a5)
 store i64 %v,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %next,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %a0,ptr %tail,align 1
 %r = xor i64 %v,%salt
 ret i64 %r
}
define fastcc i64 @bitreverse_native_width_body_17(i64 %a0,i64 %a1,i32 %a2,i64 %a3,i64 %a4,i64 %a5) noinline {
entry:
 %v = call i32 @llvm.bitreverse.i32(i32 %a2)
 %wide = zext i32 %v to i64
 %logical = zext i32 %a2 to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%logical
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 ret i64 %r5
}
define i64 @bitreverse_native_width_probe_17(ptr %input,ptr %out,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %logical = trunc i64 %a2 to i32
 %v = call fastcc i64 @bitreverse_native_width_body_17(i64 %a0,i64 %a1,i32 %logical,i64 %a3,i64 %a4,i64 %a5)
 store i64 %v,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %next,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %a0,ptr %tail,align 1
 %r = xor i64 %v,%salt
 ret i64 %r
}
define i64 @bitreverse_native_width_body_18(i64 %a0,i64 %a1,i64 %a2,i32 %a3,i64 %a4,i64 %a5) noinline {
entry:
 %v = call i32 @llvm.bitreverse.i32(i32 %a3)
 %wide = zext i32 %v to i64
 %logical = zext i32 %a3 to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%logical
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 ret i64 %r5
}
define i64 @bitreverse_native_width_probe_18(ptr %input,ptr %out,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %logical = trunc i64 %a3 to i32
 %v = call i64 @bitreverse_native_width_body_18(i64 %a0,i64 %a1,i64 %a2,i32 %logical,i64 %a4,i64 %a5)
 store i64 %v,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %next,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %a0,ptr %tail,align 1
 %r = xor i64 %v,%salt
 ret i64 %r
}
define fastcc i64 @bitreverse_native_width_body_19(i64 %a0,i64 %a1,i64 %a2,i32 %a3,i64 %a4,i64 %a5) noinline {
entry:
 %v = call i32 @llvm.bitreverse.i32(i32 %a3)
 %wide = zext i32 %v to i64
 %logical = zext i32 %a3 to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%logical
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 ret i64 %r5
}
define i64 @bitreverse_native_width_probe_19(ptr %input,ptr %out,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %logical = trunc i64 %a3 to i32
 %v = call fastcc i64 @bitreverse_native_width_body_19(i64 %a0,i64 %a1,i64 %a2,i32 %logical,i64 %a4,i64 %a5)
 store i64 %v,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %next,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %a0,ptr %tail,align 1
 %r = xor i64 %v,%salt
 ret i64 %r
}
define i64 @bitreverse_native_width_body_20(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i32 %a4,i64 %a5) noinline {
entry:
 %v = call i32 @llvm.bitreverse.i32(i32 %a4)
 %wide = zext i32 %v to i64
 %logical = zext i32 %a4 to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%logical
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 ret i64 %r5
}
define i64 @bitreverse_native_width_probe_20(ptr %input,ptr %out,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %logical = trunc i64 %a4 to i32
 %v = call i64 @bitreverse_native_width_body_20(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i32 %logical,i64 %a5)
 store i64 %v,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %next,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %a0,ptr %tail,align 1
 %r = xor i64 %v,%salt
 ret i64 %r
}
define fastcc i64 @bitreverse_native_width_body_21(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i32 %a4,i64 %a5) noinline {
entry:
 %v = call i32 @llvm.bitreverse.i32(i32 %a4)
 %wide = zext i32 %v to i64
 %logical = zext i32 %a4 to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%logical
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%a5
 ret i64 %r5
}
define i64 @bitreverse_native_width_probe_21(ptr %input,ptr %out,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %logical = trunc i64 %a4 to i32
 %v = call fastcc i64 @bitreverse_native_width_body_21(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i32 %logical,i64 %a5)
 store i64 %v,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %next,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %a0,ptr %tail,align 1
 %r = xor i64 %v,%salt
 ret i64 %r
}
define i64 @bitreverse_native_width_body_22(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i32 %a5) noinline {
entry:
 %v = call i32 @llvm.bitreverse.i32(i32 %a5)
 %wide = zext i32 %v to i64
 %logical = zext i32 %a5 to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%logical
 ret i64 %r5
}
define i64 @bitreverse_native_width_probe_22(ptr %input,ptr %out,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %logical = trunc i64 %a5 to i32
 %v = call i64 @bitreverse_native_width_body_22(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i32 %logical)
 store i64 %v,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %next,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %a0,ptr %tail,align 1
 %r = xor i64 %v,%salt
 ret i64 %r
}
define fastcc i64 @bitreverse_native_width_body_23(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i32 %a5) noinline {
entry:
 %v = call i32 @llvm.bitreverse.i32(i32 %a5)
 %wide = zext i32 %v to i64
 %logical = zext i32 %a5 to i64
 %m0 = mul i64 %wide,1099511628211
 %r0 = xor i64 %m0,%a0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%a1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%a2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%a3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%a4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%logical
 ret i64 %r5
}
define i64 @bitreverse_native_width_probe_23(ptr %input,ptr %out,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %logical = trunc i64 %a5 to i32
 %v = call fastcc i64 @bitreverse_native_width_body_23(i64 %a0,i64 %a1,i64 %a2,i64 %a3,i64 %a4,i32 %logical)
 store i64 %v,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %next,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %a0,ptr %tail,align 1
 %r = xor i64 %v,%salt
 ret i64 %r
}
