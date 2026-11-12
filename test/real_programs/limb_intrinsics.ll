target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
declare i64 @llvm.ctpop.i64(i64)
declare i64 @llvm.ctlz.i64(i64,i1)
declare i64 @llvm.cttz.i64(i64,i1)
declare i64 @llvm.bswap.i64(i64)
declare i64 @llvm.bitreverse.i64(i64)
declare i140 @llvm.abs.i140(i140, i1)
declare i140 @llvm.ctpop.i140(i140)
declare i140 @llvm.ctlz.i140(i140, i1)
declare i140 @llvm.cttz.i140(i140, i1)
declare i140 @llvm.bitreverse.i140(i140)
declare i140 @llvm.uadd.sat.i140(i140, i140)
declare i140 @llvm.usub.sat.i140(i140, i140)
declare i140 @llvm.sadd.sat.i140(i140, i140)
declare i140 @llvm.ssub.sat.i140(i140, i140)
declare i140 @llvm.fshl.i140(i140, i140, i140)
declare i140 @llvm.fshr.i140(i140, i140, i140)
define i64 @limb_intrinsics_140(ptr %out, ptr %xp, ptr %yp, ptr %np, i64 %salt) {
entry:
 %x = load i140, ptr %xp, align 1
 %y = load i140, ptr %yp, align 1
 %n = load i140, ptr %np, align 1
 %r0 = call i140 @llvm.abs.i140(i140 %x, i1 0)
 %p0 = getelementptr i8, ptr %out, i64 0
 store i140 %r0, ptr %p0, align 1
 %r1 = call i140 @llvm.ctpop.i140(i140 %x)
 %p1 = getelementptr i8, ptr %out, i64 64
 store i140 %r1, ptr %p1, align 1
 %r2 = call i140 @llvm.ctlz.i140(i140 %x, i1 0)
 %p2 = getelementptr i8, ptr %out, i64 128
 store i140 %r2, ptr %p2, align 1
 %r3 = call i140 @llvm.cttz.i140(i140 %x, i1 0)
 %p3 = getelementptr i8, ptr %out, i64 192
 store i140 %r3, ptr %p3, align 1
 %r4 = call i140 @llvm.bitreverse.i140(i140 %x)
 %p4 = getelementptr i8, ptr %out, i64 256
 store i140 %r4, ptr %p4, align 1
 %r6 = call i140 @llvm.uadd.sat.i140(i140 %x, i140 %y)
 %p6 = getelementptr i8, ptr %out, i64 384
 store i140 %r6, ptr %p6, align 1
 %r7 = call i140 @llvm.usub.sat.i140(i140 %x, i140 %y)
 %p7 = getelementptr i8, ptr %out, i64 448
 store i140 %r7, ptr %p7, align 1
 %r8 = call i140 @llvm.sadd.sat.i140(i140 %x, i140 %y)
 %p8 = getelementptr i8, ptr %out, i64 512
 store i140 %r8, ptr %p8, align 1
 %r9 = call i140 @llvm.ssub.sat.i140(i140 %x, i140 %y)
 %p9 = getelementptr i8, ptr %out, i64 576
 store i140 %r9, ptr %p9, align 1
 %r10 = call i140 @llvm.fshl.i140(i140 %x, i140 %y, i140 %n)
 %p10 = getelementptr i8, ptr %out, i64 640
 store i140 %r10, ptr %p10, align 1
 %r11 = call i140 @llvm.fshr.i140(i140 %x, i140 %y, i140 %n)
 %p11 = getelementptr i8, ptr %out, i64 704
 store i140 %r11, ptr %p11, align 1
 %live = xor i64 %salt, 90
 ret i64 %live
}
declare i200 @llvm.abs.i200(i200, i1)
declare i200 @llvm.ctpop.i200(i200)
declare i200 @llvm.ctlz.i200(i200, i1)
declare i200 @llvm.cttz.i200(i200, i1)
declare i200 @llvm.bitreverse.i200(i200)
declare i200 @llvm.uadd.sat.i200(i200, i200)
declare i200 @llvm.usub.sat.i200(i200, i200)
declare i200 @llvm.sadd.sat.i200(i200, i200)
declare i200 @llvm.ssub.sat.i200(i200, i200)
declare i200 @llvm.fshl.i200(i200, i200, i200)
declare i200 @llvm.fshr.i200(i200, i200, i200)
define i64 @limb_intrinsics_200(ptr %out, ptr %xp, ptr %yp, ptr %np, i64 %salt) {
entry:
 %x = load i200, ptr %xp, align 1
 %y = load i200, ptr %yp, align 1
 %n = load i200, ptr %np, align 1
 %r0 = call i200 @llvm.abs.i200(i200 %x, i1 0)
 %p0 = getelementptr i8, ptr %out, i64 0
 store i200 %r0, ptr %p0, align 1
 %r1 = call i200 @llvm.ctpop.i200(i200 %x)
 %p1 = getelementptr i8, ptr %out, i64 64
 store i200 %r1, ptr %p1, align 1
 %r2 = call i200 @llvm.ctlz.i200(i200 %x, i1 0)
 %p2 = getelementptr i8, ptr %out, i64 128
 store i200 %r2, ptr %p2, align 1
 %r3 = call i200 @llvm.cttz.i200(i200 %x, i1 0)
 %p3 = getelementptr i8, ptr %out, i64 192
 store i200 %r3, ptr %p3, align 1
 %r4 = call i200 @llvm.bitreverse.i200(i200 %x)
 %p4 = getelementptr i8, ptr %out, i64 256
 store i200 %r4, ptr %p4, align 1
 %r6 = call i200 @llvm.uadd.sat.i200(i200 %x, i200 %y)
 %p6 = getelementptr i8, ptr %out, i64 384
 store i200 %r6, ptr %p6, align 1
 %r7 = call i200 @llvm.usub.sat.i200(i200 %x, i200 %y)
 %p7 = getelementptr i8, ptr %out, i64 448
 store i200 %r7, ptr %p7, align 1
 %r8 = call i200 @llvm.sadd.sat.i200(i200 %x, i200 %y)
 %p8 = getelementptr i8, ptr %out, i64 512
 store i200 %r8, ptr %p8, align 1
 %r9 = call i200 @llvm.ssub.sat.i200(i200 %x, i200 %y)
 %p9 = getelementptr i8, ptr %out, i64 576
 store i200 %r9, ptr %p9, align 1
 %r10 = call i200 @llvm.fshl.i200(i200 %x, i200 %y, i200 %n)
 %p10 = getelementptr i8, ptr %out, i64 640
 store i200 %r10, ptr %p10, align 1
 %r11 = call i200 @llvm.fshr.i200(i200 %x, i200 %y, i200 %n)
 %p11 = getelementptr i8, ptr %out, i64 704
 store i200 %r11, ptr %p11, align 1
 %live = xor i64 %salt, 90
 ret i64 %live
}
declare i256 @llvm.abs.i256(i256, i1)
declare i256 @llvm.ctpop.i256(i256)
declare i256 @llvm.ctlz.i256(i256, i1)
declare i256 @llvm.cttz.i256(i256, i1)
declare i256 @llvm.bitreverse.i256(i256)
declare i256 @llvm.bswap.i256(i256)
declare i256 @llvm.uadd.sat.i256(i256, i256)
declare i256 @llvm.usub.sat.i256(i256, i256)
declare i256 @llvm.sadd.sat.i256(i256, i256)
declare i256 @llvm.ssub.sat.i256(i256, i256)
declare i256 @llvm.fshl.i256(i256, i256, i256)
declare i256 @llvm.fshr.i256(i256, i256, i256)
define i64 @limb_intrinsics_256(ptr %out, ptr %xp, ptr %yp, ptr %np, i64 %salt) {
entry:
 %x = load i256, ptr %xp, align 1
 %y = load i256, ptr %yp, align 1
 %n = load i256, ptr %np, align 1
 %r0 = call i256 @llvm.abs.i256(i256 %x, i1 0)
 %p0 = getelementptr i8, ptr %out, i64 0
 store i256 %r0, ptr %p0, align 1
 %r1 = call i256 @llvm.ctpop.i256(i256 %x)
 %p1 = getelementptr i8, ptr %out, i64 64
 store i256 %r1, ptr %p1, align 1
 %r2 = call i256 @llvm.ctlz.i256(i256 %x, i1 0)
 %p2 = getelementptr i8, ptr %out, i64 128
 store i256 %r2, ptr %p2, align 1
 %r3 = call i256 @llvm.cttz.i256(i256 %x, i1 0)
 %p3 = getelementptr i8, ptr %out, i64 192
 store i256 %r3, ptr %p3, align 1
 %r4 = call i256 @llvm.bitreverse.i256(i256 %x)
 %p4 = getelementptr i8, ptr %out, i64 256
 store i256 %r4, ptr %p4, align 1
 %r5 = call i256 @llvm.bswap.i256(i256 %x)
 %p5 = getelementptr i8, ptr %out, i64 320
 store i256 %r5, ptr %p5, align 1
 %r6 = call i256 @llvm.uadd.sat.i256(i256 %x, i256 %y)
 %p6 = getelementptr i8, ptr %out, i64 384
 store i256 %r6, ptr %p6, align 1
 %r7 = call i256 @llvm.usub.sat.i256(i256 %x, i256 %y)
 %p7 = getelementptr i8, ptr %out, i64 448
 store i256 %r7, ptr %p7, align 1
 %r8 = call i256 @llvm.sadd.sat.i256(i256 %x, i256 %y)
 %p8 = getelementptr i8, ptr %out, i64 512
 store i256 %r8, ptr %p8, align 1
 %r9 = call i256 @llvm.ssub.sat.i256(i256 %x, i256 %y)
 %p9 = getelementptr i8, ptr %out, i64 576
 store i256 %r9, ptr %p9, align 1
 %r10 = call i256 @llvm.fshl.i256(i256 %x, i256 %y, i256 %n)
 %p10 = getelementptr i8, ptr %out, i64 640
 store i256 %r10, ptr %p10, align 1
 %r11 = call i256 @llvm.fshr.i256(i256 %x, i256 %y, i256 %n)
 %p11 = getelementptr i8, ptr %out, i64 704
 store i256 %r11, ptr %p11, align 1
 %live = xor i64 %salt, 90
 ret i64 %live
}
declare i495 @llvm.abs.i495(i495, i1)
declare i495 @llvm.ctpop.i495(i495)
declare i495 @llvm.ctlz.i495(i495, i1)
declare i495 @llvm.cttz.i495(i495, i1)
declare i495 @llvm.bitreverse.i495(i495)
declare i495 @llvm.uadd.sat.i495(i495, i495)
declare i495 @llvm.usub.sat.i495(i495, i495)
declare i495 @llvm.sadd.sat.i495(i495, i495)
declare i495 @llvm.ssub.sat.i495(i495, i495)
declare i495 @llvm.fshl.i495(i495, i495, i495)
declare i495 @llvm.fshr.i495(i495, i495, i495)
define i64 @limb_intrinsics_495(ptr %out, ptr %xp, ptr %yp, ptr %np, i64 %salt) {
entry:
 %x = load i495, ptr %xp, align 1
 %y = load i495, ptr %yp, align 1
 %n = load i495, ptr %np, align 1
 %r0 = call i495 @llvm.abs.i495(i495 %x, i1 0)
 %p0 = getelementptr i8, ptr %out, i64 0
 store i495 %r0, ptr %p0, align 1
 %r1 = call i495 @llvm.ctpop.i495(i495 %x)
 %p1 = getelementptr i8, ptr %out, i64 64
 store i495 %r1, ptr %p1, align 1
 %r2 = call i495 @llvm.ctlz.i495(i495 %x, i1 0)
 %p2 = getelementptr i8, ptr %out, i64 128
 store i495 %r2, ptr %p2, align 1
 %r3 = call i495 @llvm.cttz.i495(i495 %x, i1 0)
 %p3 = getelementptr i8, ptr %out, i64 192
 store i495 %r3, ptr %p3, align 1
 %r4 = call i495 @llvm.bitreverse.i495(i495 %x)
 %p4 = getelementptr i8, ptr %out, i64 256
 store i495 %r4, ptr %p4, align 1
 %r6 = call i495 @llvm.uadd.sat.i495(i495 %x, i495 %y)
 %p6 = getelementptr i8, ptr %out, i64 384
 store i495 %r6, ptr %p6, align 1
 %r7 = call i495 @llvm.usub.sat.i495(i495 %x, i495 %y)
 %p7 = getelementptr i8, ptr %out, i64 448
 store i495 %r7, ptr %p7, align 1
 %r8 = call i495 @llvm.sadd.sat.i495(i495 %x, i495 %y)
 %p8 = getelementptr i8, ptr %out, i64 512
 store i495 %r8, ptr %p8, align 1
 %r9 = call i495 @llvm.ssub.sat.i495(i495 %x, i495 %y)
 %p9 = getelementptr i8, ptr %out, i64 576
 store i495 %r9, ptr %p9, align 1
 %r10 = call i495 @llvm.fshl.i495(i495 %x, i495 %y, i495 %n)
 %p10 = getelementptr i8, ptr %out, i64 640
 store i495 %r10, ptr %p10, align 1
 %r11 = call i495 @llvm.fshr.i495(i495 %x, i495 %y, i495 %n)
 %p11 = getelementptr i8, ptr %out, i64 704
 store i495 %r11, ptr %p11, align 1
 %live = xor i64 %salt, 90
 ret i64 %live
}
