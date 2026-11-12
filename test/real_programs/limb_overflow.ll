target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
declare {i140,i1} @llvm.uadd.with.overflow.i140(i140,i140)
declare {i140,i1} @llvm.usub.with.overflow.i140(i140,i140)
declare {i140,i1} @llvm.sadd.with.overflow.i140(i140,i140)
declare {i140,i1} @llvm.ssub.with.overflow.i140(i140,i140)
define i64 @limb_overflow_140(ptr %out,ptr %flags,ptr %xp,ptr %yp,i64 %salt) {
entry:
 %x = load i140,ptr %xp,align 1
 %y = load i140,ptr %yp,align 1
 %t0 = call {i140,i1} @llvm.uadd.with.overflow.i140(i140 %x,i140 %y)
 %f0 = extractvalue {i140,i1} %t0,1
 %v0 = extractvalue {i140,i1} %t0,0
 %byte0 = zext i1 %f0 to i8
 %fp0 = getelementptr i8,ptr %flags,i64 0
 store i8 %byte0,ptr %fp0,align 1
 %vp0 = getelementptr i8,ptr %out,i64 0
 store i140 %v0,ptr %vp0,align 1
 %t1 = call {i140,i1} @llvm.usub.with.overflow.i140(i140 %x,i140 %y)
 %f1 = extractvalue {i140,i1} %t1,1
 %v1 = extractvalue {i140,i1} %t1,0
 %byte1 = zext i1 %f1 to i8
 %fp1 = getelementptr i8,ptr %flags,i64 1
 store i8 %byte1,ptr %fp1,align 1
 %vp1 = getelementptr i8,ptr %out,i64 64
 store i140 %v1,ptr %vp1,align 1
 %t2 = call {i140,i1} @llvm.sadd.with.overflow.i140(i140 %x,i140 %y)
 %f2 = extractvalue {i140,i1} %t2,1
 %v2 = extractvalue {i140,i1} %t2,0
 %byte2 = zext i1 %f2 to i8
 %fp2 = getelementptr i8,ptr %flags,i64 2
 store i8 %byte2,ptr %fp2,align 1
 %vp2 = getelementptr i8,ptr %out,i64 128
 store i140 %v2,ptr %vp2,align 1
 %t3 = call {i140,i1} @llvm.ssub.with.overflow.i140(i140 %x,i140 %y)
 %f3 = extractvalue {i140,i1} %t3,1
 %v3 = extractvalue {i140,i1} %t3,0
 %byte3 = zext i1 %f3 to i8
 %fp3 = getelementptr i8,ptr %flags,i64 3
 store i8 %byte3,ptr %fp3,align 1
 %vp3 = getelementptr i8,ptr %out,i64 192
 store i140 %v3,ptr %vp3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare {i200,i1} @llvm.uadd.with.overflow.i200(i200,i200)
declare {i200,i1} @llvm.usub.with.overflow.i200(i200,i200)
declare {i200,i1} @llvm.sadd.with.overflow.i200(i200,i200)
declare {i200,i1} @llvm.ssub.with.overflow.i200(i200,i200)
define i64 @limb_overflow_200(ptr %out,ptr %flags,ptr %xp,ptr %yp,i64 %salt) {
entry:
 %x = load i200,ptr %xp,align 1
 %y = load i200,ptr %yp,align 1
 %t0 = call {i200,i1} @llvm.uadd.with.overflow.i200(i200 %x,i200 %y)
 %f0 = extractvalue {i200,i1} %t0,1
 %v0 = extractvalue {i200,i1} %t0,0
 %byte0 = zext i1 %f0 to i8
 %fp0 = getelementptr i8,ptr %flags,i64 0
 store i8 %byte0,ptr %fp0,align 1
 %vp0 = getelementptr i8,ptr %out,i64 0
 store i200 %v0,ptr %vp0,align 1
 %t1 = call {i200,i1} @llvm.usub.with.overflow.i200(i200 %x,i200 %y)
 %f1 = extractvalue {i200,i1} %t1,1
 %v1 = extractvalue {i200,i1} %t1,0
 %byte1 = zext i1 %f1 to i8
 %fp1 = getelementptr i8,ptr %flags,i64 1
 store i8 %byte1,ptr %fp1,align 1
 %vp1 = getelementptr i8,ptr %out,i64 64
 store i200 %v1,ptr %vp1,align 1
 %t2 = call {i200,i1} @llvm.sadd.with.overflow.i200(i200 %x,i200 %y)
 %f2 = extractvalue {i200,i1} %t2,1
 %v2 = extractvalue {i200,i1} %t2,0
 %byte2 = zext i1 %f2 to i8
 %fp2 = getelementptr i8,ptr %flags,i64 2
 store i8 %byte2,ptr %fp2,align 1
 %vp2 = getelementptr i8,ptr %out,i64 128
 store i200 %v2,ptr %vp2,align 1
 %t3 = call {i200,i1} @llvm.ssub.with.overflow.i200(i200 %x,i200 %y)
 %f3 = extractvalue {i200,i1} %t3,1
 %v3 = extractvalue {i200,i1} %t3,0
 %byte3 = zext i1 %f3 to i8
 %fp3 = getelementptr i8,ptr %flags,i64 3
 store i8 %byte3,ptr %fp3,align 1
 %vp3 = getelementptr i8,ptr %out,i64 192
 store i200 %v3,ptr %vp3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare {i256,i1} @llvm.uadd.with.overflow.i256(i256,i256)
declare {i256,i1} @llvm.usub.with.overflow.i256(i256,i256)
declare {i256,i1} @llvm.sadd.with.overflow.i256(i256,i256)
declare {i256,i1} @llvm.ssub.with.overflow.i256(i256,i256)
define i64 @limb_overflow_256(ptr %out,ptr %flags,ptr %xp,ptr %yp,i64 %salt) {
entry:
 %x = load i256,ptr %xp,align 1
 %y = load i256,ptr %yp,align 1
 %t0 = call {i256,i1} @llvm.uadd.with.overflow.i256(i256 %x,i256 %y)
 %f0 = extractvalue {i256,i1} %t0,1
 %v0 = extractvalue {i256,i1} %t0,0
 %byte0 = zext i1 %f0 to i8
 %fp0 = getelementptr i8,ptr %flags,i64 0
 store i8 %byte0,ptr %fp0,align 1
 %vp0 = getelementptr i8,ptr %out,i64 0
 store i256 %v0,ptr %vp0,align 1
 %t1 = call {i256,i1} @llvm.usub.with.overflow.i256(i256 %x,i256 %y)
 %f1 = extractvalue {i256,i1} %t1,1
 %v1 = extractvalue {i256,i1} %t1,0
 %byte1 = zext i1 %f1 to i8
 %fp1 = getelementptr i8,ptr %flags,i64 1
 store i8 %byte1,ptr %fp1,align 1
 %vp1 = getelementptr i8,ptr %out,i64 64
 store i256 %v1,ptr %vp1,align 1
 %t2 = call {i256,i1} @llvm.sadd.with.overflow.i256(i256 %x,i256 %y)
 %f2 = extractvalue {i256,i1} %t2,1
 %v2 = extractvalue {i256,i1} %t2,0
 %byte2 = zext i1 %f2 to i8
 %fp2 = getelementptr i8,ptr %flags,i64 2
 store i8 %byte2,ptr %fp2,align 1
 %vp2 = getelementptr i8,ptr %out,i64 128
 store i256 %v2,ptr %vp2,align 1
 %t3 = call {i256,i1} @llvm.ssub.with.overflow.i256(i256 %x,i256 %y)
 %f3 = extractvalue {i256,i1} %t3,1
 %v3 = extractvalue {i256,i1} %t3,0
 %byte3 = zext i1 %f3 to i8
 %fp3 = getelementptr i8,ptr %flags,i64 3
 store i8 %byte3,ptr %fp3,align 1
 %vp3 = getelementptr i8,ptr %out,i64 192
 store i256 %v3,ptr %vp3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
declare {i495,i1} @llvm.uadd.with.overflow.i495(i495,i495)
declare {i495,i1} @llvm.usub.with.overflow.i495(i495,i495)
declare {i495,i1} @llvm.sadd.with.overflow.i495(i495,i495)
declare {i495,i1} @llvm.ssub.with.overflow.i495(i495,i495)
define i64 @limb_overflow_495(ptr %out,ptr %flags,ptr %xp,ptr %yp,i64 %salt) {
entry:
 %x = load i495,ptr %xp,align 1
 %y = load i495,ptr %yp,align 1
 %t0 = call {i495,i1} @llvm.uadd.with.overflow.i495(i495 %x,i495 %y)
 %f0 = extractvalue {i495,i1} %t0,1
 %v0 = extractvalue {i495,i1} %t0,0
 %byte0 = zext i1 %f0 to i8
 %fp0 = getelementptr i8,ptr %flags,i64 0
 store i8 %byte0,ptr %fp0,align 1
 %vp0 = getelementptr i8,ptr %out,i64 0
 store i495 %v0,ptr %vp0,align 1
 %t1 = call {i495,i1} @llvm.usub.with.overflow.i495(i495 %x,i495 %y)
 %f1 = extractvalue {i495,i1} %t1,1
 %v1 = extractvalue {i495,i1} %t1,0
 %byte1 = zext i1 %f1 to i8
 %fp1 = getelementptr i8,ptr %flags,i64 1
 store i8 %byte1,ptr %fp1,align 1
 %vp1 = getelementptr i8,ptr %out,i64 64
 store i495 %v1,ptr %vp1,align 1
 %t2 = call {i495,i1} @llvm.sadd.with.overflow.i495(i495 %x,i495 %y)
 %f2 = extractvalue {i495,i1} %t2,1
 %v2 = extractvalue {i495,i1} %t2,0
 %byte2 = zext i1 %f2 to i8
 %fp2 = getelementptr i8,ptr %flags,i64 2
 store i8 %byte2,ptr %fp2,align 1
 %vp2 = getelementptr i8,ptr %out,i64 128
 store i495 %v2,ptr %vp2,align 1
 %t3 = call {i495,i1} @llvm.ssub.with.overflow.i495(i495 %x,i495 %y)
 %f3 = extractvalue {i495,i1} %t3,1
 %v3 = extractvalue {i495,i1} %t3,0
 %byte3 = zext i1 %f3 to i8
 %fp3 = getelementptr i8,ptr %flags,i64 3
 store i8 %byte3,ptr %fp3,align 1
 %vp3 = getelementptr i8,ptr %out,i64 192
 store i495 %v3,ptr %vp3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
