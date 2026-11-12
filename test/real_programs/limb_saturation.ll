target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare i140 @llvm.umin.i140(i140,i140)
declare i140 @llvm.umax.i140(i140,i140)
declare i140 @llvm.smin.i140(i140,i140)
declare i140 @llvm.smax.i140(i140,i140)
declare i140 @llvm.umul.fix.sat.i140(i140,i140,i32)
declare i140 @llvm.smul.fix.sat.i140(i140,i140,i32)
declare i140 @llvm.ushl.sat.i140(i140,i140)
declare i140 @llvm.sshl.sat.i140(i140,i140)
define i64 @limb_saturation_140(ptr %out,ptr %xp,ptr %yp,i64 %amount,i64 %salt) {
entry:
 %x = load i140,ptr %xp,align 1
 %y = load i140,ptr %yp,align 1
 %a = zext i64 %amount to i140
 %v0 = call i140 @llvm.umin.i140(i140 %x,i140 %y)
 %p0 = getelementptr i8,ptr %out,i64 0
 store i140 %v0,ptr %p0,align 1
 %v1 = call i140 @llvm.umax.i140(i140 %x,i140 %y)
 %p1 = getelementptr i8,ptr %out,i64 64
 store i140 %v1,ptr %p1,align 1
 %v2 = call i140 @llvm.smin.i140(i140 %x,i140 %y)
 %p2 = getelementptr i8,ptr %out,i64 128
 store i140 %v2,ptr %p2,align 1
 %v3 = call i140 @llvm.smax.i140(i140 %x,i140 %y)
 %p3 = getelementptr i8,ptr %out,i64 192
 store i140 %v3,ptr %p3,align 1
 %v4 = call i140 @llvm.umul.fix.sat.i140(i140 %x,i140 %y,i32 0)
 %p4 = getelementptr i8,ptr %out,i64 256
 store i140 %v4,ptr %p4,align 1
 %v5 = call i140 @llvm.smul.fix.sat.i140(i140 %x,i140 %y,i32 0)
 %p5 = getelementptr i8,ptr %out,i64 320
 store i140 %v5,ptr %p5,align 1
 %v6 = call i140 @llvm.ushl.sat.i140(i140 %x,i140 %a)
 %p6 = getelementptr i8,ptr %out,i64 384
 store i140 %v6,ptr %p6,align 1
 %v7 = call i140 @llvm.sshl.sat.i140(i140 %x,i140 %a)
 %p7 = getelementptr i8,ptr %out,i64 448
 store i140 %v7,ptr %p7,align 1
 %r = xor i64 %salt,90
 ret i64 %r
}
declare i200 @llvm.umin.i200(i200,i200)
declare i200 @llvm.umax.i200(i200,i200)
declare i200 @llvm.smin.i200(i200,i200)
declare i200 @llvm.smax.i200(i200,i200)
declare i200 @llvm.umul.fix.sat.i200(i200,i200,i32)
declare i200 @llvm.smul.fix.sat.i200(i200,i200,i32)
declare i200 @llvm.ushl.sat.i200(i200,i200)
declare i200 @llvm.sshl.sat.i200(i200,i200)
define i64 @limb_saturation_200(ptr %out,ptr %xp,ptr %yp,i64 %amount,i64 %salt) {
entry:
 %x = load i200,ptr %xp,align 1
 %y = load i200,ptr %yp,align 1
 %a = zext i64 %amount to i200
 %v0 = call i200 @llvm.umin.i200(i200 %x,i200 %y)
 %p0 = getelementptr i8,ptr %out,i64 0
 store i200 %v0,ptr %p0,align 1
 %v1 = call i200 @llvm.umax.i200(i200 %x,i200 %y)
 %p1 = getelementptr i8,ptr %out,i64 64
 store i200 %v1,ptr %p1,align 1
 %v2 = call i200 @llvm.smin.i200(i200 %x,i200 %y)
 %p2 = getelementptr i8,ptr %out,i64 128
 store i200 %v2,ptr %p2,align 1
 %v3 = call i200 @llvm.smax.i200(i200 %x,i200 %y)
 %p3 = getelementptr i8,ptr %out,i64 192
 store i200 %v3,ptr %p3,align 1
 %v4 = call i200 @llvm.umul.fix.sat.i200(i200 %x,i200 %y,i32 0)
 %p4 = getelementptr i8,ptr %out,i64 256
 store i200 %v4,ptr %p4,align 1
 %v5 = call i200 @llvm.smul.fix.sat.i200(i200 %x,i200 %y,i32 0)
 %p5 = getelementptr i8,ptr %out,i64 320
 store i200 %v5,ptr %p5,align 1
 %v6 = call i200 @llvm.ushl.sat.i200(i200 %x,i200 %a)
 %p6 = getelementptr i8,ptr %out,i64 384
 store i200 %v6,ptr %p6,align 1
 %v7 = call i200 @llvm.sshl.sat.i200(i200 %x,i200 %a)
 %p7 = getelementptr i8,ptr %out,i64 448
 store i200 %v7,ptr %p7,align 1
 %r = xor i64 %salt,90
 ret i64 %r
}
declare i256 @llvm.umin.i256(i256,i256)
declare i256 @llvm.umax.i256(i256,i256)
declare i256 @llvm.smin.i256(i256,i256)
declare i256 @llvm.smax.i256(i256,i256)
declare i256 @llvm.umul.fix.sat.i256(i256,i256,i32)
declare i256 @llvm.smul.fix.sat.i256(i256,i256,i32)
declare i256 @llvm.ushl.sat.i256(i256,i256)
declare i256 @llvm.sshl.sat.i256(i256,i256)
define i64 @limb_saturation_256(ptr %out,ptr %xp,ptr %yp,i64 %amount,i64 %salt) {
entry:
 %x = load i256,ptr %xp,align 1
 %y = load i256,ptr %yp,align 1
 %a = zext i64 %amount to i256
 %v0 = call i256 @llvm.umin.i256(i256 %x,i256 %y)
 %p0 = getelementptr i8,ptr %out,i64 0
 store i256 %v0,ptr %p0,align 1
 %v1 = call i256 @llvm.umax.i256(i256 %x,i256 %y)
 %p1 = getelementptr i8,ptr %out,i64 64
 store i256 %v1,ptr %p1,align 1
 %v2 = call i256 @llvm.smin.i256(i256 %x,i256 %y)
 %p2 = getelementptr i8,ptr %out,i64 128
 store i256 %v2,ptr %p2,align 1
 %v3 = call i256 @llvm.smax.i256(i256 %x,i256 %y)
 %p3 = getelementptr i8,ptr %out,i64 192
 store i256 %v3,ptr %p3,align 1
 %v4 = call i256 @llvm.umul.fix.sat.i256(i256 %x,i256 %y,i32 0)
 %p4 = getelementptr i8,ptr %out,i64 256
 store i256 %v4,ptr %p4,align 1
 %v5 = call i256 @llvm.smul.fix.sat.i256(i256 %x,i256 %y,i32 0)
 %p5 = getelementptr i8,ptr %out,i64 320
 store i256 %v5,ptr %p5,align 1
 %v6 = call i256 @llvm.ushl.sat.i256(i256 %x,i256 %a)
 %p6 = getelementptr i8,ptr %out,i64 384
 store i256 %v6,ptr %p6,align 1
 %v7 = call i256 @llvm.sshl.sat.i256(i256 %x,i256 %a)
 %p7 = getelementptr i8,ptr %out,i64 448
 store i256 %v7,ptr %p7,align 1
 %r = xor i64 %salt,90
 ret i64 %r
}
declare i495 @llvm.umin.i495(i495,i495)
declare i495 @llvm.umax.i495(i495,i495)
declare i495 @llvm.smin.i495(i495,i495)
declare i495 @llvm.smax.i495(i495,i495)
declare i495 @llvm.umul.fix.sat.i495(i495,i495,i32)
declare i495 @llvm.smul.fix.sat.i495(i495,i495,i32)
declare i495 @llvm.ushl.sat.i495(i495,i495)
declare i495 @llvm.sshl.sat.i495(i495,i495)
define i64 @limb_saturation_495(ptr %out,ptr %xp,ptr %yp,i64 %amount,i64 %salt) {
entry:
 %x = load i495,ptr %xp,align 1
 %y = load i495,ptr %yp,align 1
 %a = zext i64 %amount to i495
 %v0 = call i495 @llvm.umin.i495(i495 %x,i495 %y)
 %p0 = getelementptr i8,ptr %out,i64 0
 store i495 %v0,ptr %p0,align 1
 %v1 = call i495 @llvm.umax.i495(i495 %x,i495 %y)
 %p1 = getelementptr i8,ptr %out,i64 64
 store i495 %v1,ptr %p1,align 1
 %v2 = call i495 @llvm.smin.i495(i495 %x,i495 %y)
 %p2 = getelementptr i8,ptr %out,i64 128
 store i495 %v2,ptr %p2,align 1
 %v3 = call i495 @llvm.smax.i495(i495 %x,i495 %y)
 %p3 = getelementptr i8,ptr %out,i64 192
 store i495 %v3,ptr %p3,align 1
 %v4 = call i495 @llvm.umul.fix.sat.i495(i495 %x,i495 %y,i32 0)
 %p4 = getelementptr i8,ptr %out,i64 256
 store i495 %v4,ptr %p4,align 1
 %v5 = call i495 @llvm.smul.fix.sat.i495(i495 %x,i495 %y,i32 0)
 %p5 = getelementptr i8,ptr %out,i64 320
 store i495 %v5,ptr %p5,align 1
 %v6 = call i495 @llvm.ushl.sat.i495(i495 %x,i495 %a)
 %p6 = getelementptr i8,ptr %out,i64 384
 store i495 %v6,ptr %p6,align 1
 %v7 = call i495 @llvm.sshl.sat.i495(i495 %x,i495 %a)
 %p7 = getelementptr i8,ptr %out,i64 448
 store i495 %v7,ptr %p7,align 1
 %r = xor i64 %salt,90
 ret i64 %r
}
