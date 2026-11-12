target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare {i140,i1} @llvm.umul.with.overflow.i140(i140,i140)
declare {i140,i1} @llvm.smul.with.overflow.i140(i140,i140)
define i64 @limb_multiply_140(ptr %out,ptr %flags,ptr %xp,ptr %yp,i64 %salt) {
entry:
 %x = load i140,ptr %xp,align 1
 %y = load i140,ptr %yp,align 1
 %t0 = call {i140,i1} @llvm.umul.with.overflow.i140(i140 %x,i140 %y)
 %v0 = extractvalue {i140,i1} %t0,0
 %f0 = extractvalue {i140,i1} %t0,1
 %b0 = zext i1 %f0 to i8
 %p0 = getelementptr i8,ptr %out,i64 0
 store i140 %v0,ptr %p0,align 1
 %fp0 = getelementptr i8,ptr %flags,i64 0
 store i8 %b0,ptr %fp0,align 1
 %t1 = call {i140,i1} @llvm.smul.with.overflow.i140(i140 %x,i140 %y)
 %v1 = extractvalue {i140,i1} %t1,0
 %f1 = extractvalue {i140,i1} %t1,1
 %b1 = zext i1 %f1 to i8
 %p1 = getelementptr i8,ptr %out,i64 64
 store i140 %v1,ptr %p1,align 1
 %fp1 = getelementptr i8,ptr %flags,i64 1
 store i8 %b1,ptr %fp1,align 1
 %m = mul i140 %x,%y
 %mp = getelementptr i8,ptr %out,i64 128
 store i140 %m,ptr %mp,align 1
 %r = xor i64 %salt,90
 ret i64 %r
}
declare {i200,i1} @llvm.umul.with.overflow.i200(i200,i200)
declare {i200,i1} @llvm.smul.with.overflow.i200(i200,i200)
define i64 @limb_multiply_200(ptr %out,ptr %flags,ptr %xp,ptr %yp,i64 %salt) {
entry:
 %x = load i200,ptr %xp,align 1
 %y = load i200,ptr %yp,align 1
 %t0 = call {i200,i1} @llvm.umul.with.overflow.i200(i200 %x,i200 %y)
 %v0 = extractvalue {i200,i1} %t0,0
 %f0 = extractvalue {i200,i1} %t0,1
 %b0 = zext i1 %f0 to i8
 %p0 = getelementptr i8,ptr %out,i64 0
 store i200 %v0,ptr %p0,align 1
 %fp0 = getelementptr i8,ptr %flags,i64 0
 store i8 %b0,ptr %fp0,align 1
 %t1 = call {i200,i1} @llvm.smul.with.overflow.i200(i200 %x,i200 %y)
 %v1 = extractvalue {i200,i1} %t1,0
 %f1 = extractvalue {i200,i1} %t1,1
 %b1 = zext i1 %f1 to i8
 %p1 = getelementptr i8,ptr %out,i64 64
 store i200 %v1,ptr %p1,align 1
 %fp1 = getelementptr i8,ptr %flags,i64 1
 store i8 %b1,ptr %fp1,align 1
 %m = mul i200 %x,%y
 %mp = getelementptr i8,ptr %out,i64 128
 store i200 %m,ptr %mp,align 1
 %r = xor i64 %salt,90
 ret i64 %r
}
declare {i256,i1} @llvm.umul.with.overflow.i256(i256,i256)
declare {i256,i1} @llvm.smul.with.overflow.i256(i256,i256)
define i64 @limb_multiply_256(ptr %out,ptr %flags,ptr %xp,ptr %yp,i64 %salt) {
entry:
 %x = load i256,ptr %xp,align 1
 %y = load i256,ptr %yp,align 1
 %t0 = call {i256,i1} @llvm.umul.with.overflow.i256(i256 %x,i256 %y)
 %v0 = extractvalue {i256,i1} %t0,0
 %f0 = extractvalue {i256,i1} %t0,1
 %b0 = zext i1 %f0 to i8
 %p0 = getelementptr i8,ptr %out,i64 0
 store i256 %v0,ptr %p0,align 1
 %fp0 = getelementptr i8,ptr %flags,i64 0
 store i8 %b0,ptr %fp0,align 1
 %t1 = call {i256,i1} @llvm.smul.with.overflow.i256(i256 %x,i256 %y)
 %v1 = extractvalue {i256,i1} %t1,0
 %f1 = extractvalue {i256,i1} %t1,1
 %b1 = zext i1 %f1 to i8
 %p1 = getelementptr i8,ptr %out,i64 64
 store i256 %v1,ptr %p1,align 1
 %fp1 = getelementptr i8,ptr %flags,i64 1
 store i8 %b1,ptr %fp1,align 1
 %m = mul i256 %x,%y
 %mp = getelementptr i8,ptr %out,i64 128
 store i256 %m,ptr %mp,align 1
 %r = xor i64 %salt,90
 ret i64 %r
}
declare {i495,i1} @llvm.umul.with.overflow.i495(i495,i495)
declare {i495,i1} @llvm.smul.with.overflow.i495(i495,i495)
define i64 @limb_multiply_495(ptr %out,ptr %flags,ptr %xp,ptr %yp,i64 %salt) {
entry:
 %x = load i495,ptr %xp,align 1
 %y = load i495,ptr %yp,align 1
 %t0 = call {i495,i1} @llvm.umul.with.overflow.i495(i495 %x,i495 %y)
 %v0 = extractvalue {i495,i1} %t0,0
 %f0 = extractvalue {i495,i1} %t0,1
 %b0 = zext i1 %f0 to i8
 %p0 = getelementptr i8,ptr %out,i64 0
 store i495 %v0,ptr %p0,align 1
 %fp0 = getelementptr i8,ptr %flags,i64 0
 store i8 %b0,ptr %fp0,align 1
 %t1 = call {i495,i1} @llvm.smul.with.overflow.i495(i495 %x,i495 %y)
 %v1 = extractvalue {i495,i1} %t1,0
 %f1 = extractvalue {i495,i1} %t1,1
 %b1 = zext i1 %f1 to i8
 %p1 = getelementptr i8,ptr %out,i64 64
 store i495 %v1,ptr %p1,align 1
 %fp1 = getelementptr i8,ptr %flags,i64 1
 store i8 %b1,ptr %fp1,align 1
 %m = mul i495 %x,%y
 %mp = getelementptr i8,ptr %out,i64 128
 store i495 %m,ptr %mp,align 1
 %r = xor i64 %salt,90
 ret i64 %r
}
