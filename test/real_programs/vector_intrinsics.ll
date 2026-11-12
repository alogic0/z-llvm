target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
declare <8 x i16> @llvm.abs.v8i16(<8 x i16>,i1)
declare <8 x i16> @llvm.ctpop.v8i16(<8 x i16>)
declare <8 x i16> @llvm.ctlz.v8i16(<8 x i16>,i1)
declare <8 x i16> @llvm.cttz.v8i16(<8 x i16>,i1)
declare <8 x i16> @llvm.bitreverse.v8i16(<8 x i16>)
declare <8 x i16> @llvm.bswap.v8i16(<8 x i16>)
declare <8 x i16> @llvm.uadd.sat.v8i16(<8 x i16>,<8 x i16>)
declare <8 x i16> @llvm.usub.sat.v8i16(<8 x i16>,<8 x i16>)
declare <8 x i16> @llvm.sadd.sat.v8i16(<8 x i16>,<8 x i16>)
declare <8 x i16> @llvm.ssub.sat.v8i16(<8 x i16>,<8 x i16>)
declare <8 x i16> @llvm.fshl.v8i16(<8 x i16>,<8 x i16>,<8 x i16>)
declare <8 x i16> @llvm.fshr.v8i16(<8 x i16>,<8 x i16>,<8 x i16>)
declare <8 x i16> @llvm.umin.v8i16(<8 x i16>,<8 x i16>)
declare <8 x i16> @llvm.umax.v8i16(<8 x i16>,<8 x i16>)
declare <8 x i16> @llvm.smin.v8i16(<8 x i16>,<8 x i16>)
declare <8 x i16> @llvm.smax.v8i16(<8 x i16>,<8 x i16>)
declare <8 x i16> @llvm.ushl.sat.v8i16(<8 x i16>,<8 x i16>)
declare <8 x i16> @llvm.sshl.sat.v8i16(<8 x i16>,<8 x i16>)
declare <8 x i16> @llvm.umul.fix.sat.v8i16(<8 x i16>,<8 x i16>,i32)
declare <8 x i16> @llvm.smul.fix.sat.v8i16(<8 x i16>,<8 x i16>,i32)
define i64 @vector_intrinsics_16(ptr %out,ptr %xp,ptr %yp,i64 %live) {
entry:
 %x = load <8 x i16>,ptr %xp,align 1
 %y = load <8 x i16>,ptr %yp,align 1
 %counts = and <8 x i16> %y,splat (i16 15)
 %v0 = call <8 x i16> @llvm.abs.v8i16(<8 x i16> %x,i1 false)
 %p0 = getelementptr i8,ptr %out,i64 0
 store <8 x i16> %v0,ptr %p0,align 1
 %v1 = call <8 x i16> @llvm.ctpop.v8i16(<8 x i16> %x)
 %p1 = getelementptr i8,ptr %out,i64 16
 store <8 x i16> %v1,ptr %p1,align 1
 %v2 = call <8 x i16> @llvm.ctlz.v8i16(<8 x i16> %x,i1 false)
 %p2 = getelementptr i8,ptr %out,i64 32
 store <8 x i16> %v2,ptr %p2,align 1
 %v3 = call <8 x i16> @llvm.cttz.v8i16(<8 x i16> %x,i1 false)
 %p3 = getelementptr i8,ptr %out,i64 48
 store <8 x i16> %v3,ptr %p3,align 1
 %v4 = call <8 x i16> @llvm.bitreverse.v8i16(<8 x i16> %x)
 %p4 = getelementptr i8,ptr %out,i64 64
 store <8 x i16> %v4,ptr %p4,align 1
 %v5 = call <8 x i16> @llvm.bswap.v8i16(<8 x i16> %x)
 %p5 = getelementptr i8,ptr %out,i64 80
 store <8 x i16> %v5,ptr %p5,align 1
 %v6 = call <8 x i16> @llvm.uadd.sat.v8i16(<8 x i16> %x,<8 x i16> %y)
 %p6 = getelementptr i8,ptr %out,i64 96
 store <8 x i16> %v6,ptr %p6,align 1
 %v7 = call <8 x i16> @llvm.usub.sat.v8i16(<8 x i16> %x,<8 x i16> %y)
 %p7 = getelementptr i8,ptr %out,i64 112
 store <8 x i16> %v7,ptr %p7,align 1
 %v8 = call <8 x i16> @llvm.sadd.sat.v8i16(<8 x i16> %x,<8 x i16> %y)
 %p8 = getelementptr i8,ptr %out,i64 128
 store <8 x i16> %v8,ptr %p8,align 1
 %v9 = call <8 x i16> @llvm.ssub.sat.v8i16(<8 x i16> %x,<8 x i16> %y)
 %p9 = getelementptr i8,ptr %out,i64 144
 store <8 x i16> %v9,ptr %p9,align 1
 %v10 = call <8 x i16> @llvm.fshl.v8i16(<8 x i16> %x,<8 x i16> %y,<8 x i16> %y)
 %p10 = getelementptr i8,ptr %out,i64 160
 store <8 x i16> %v10,ptr %p10,align 1
 %v11 = call <8 x i16> @llvm.fshr.v8i16(<8 x i16> %x,<8 x i16> %y,<8 x i16> %y)
 %p11 = getelementptr i8,ptr %out,i64 176
 store <8 x i16> %v11,ptr %p11,align 1
 %v12 = call <8 x i16> @llvm.umin.v8i16(<8 x i16> %x,<8 x i16> %y)
 %p12 = getelementptr i8,ptr %out,i64 192
 store <8 x i16> %v12,ptr %p12,align 1
 %v13 = call <8 x i16> @llvm.umax.v8i16(<8 x i16> %x,<8 x i16> %y)
 %p13 = getelementptr i8,ptr %out,i64 208
 store <8 x i16> %v13,ptr %p13,align 1
 %v14 = call <8 x i16> @llvm.smin.v8i16(<8 x i16> %x,<8 x i16> %y)
 %p14 = getelementptr i8,ptr %out,i64 224
 store <8 x i16> %v14,ptr %p14,align 1
 %v15 = call <8 x i16> @llvm.smax.v8i16(<8 x i16> %x,<8 x i16> %y)
 %p15 = getelementptr i8,ptr %out,i64 240
 store <8 x i16> %v15,ptr %p15,align 1
 %v16 = call <8 x i16> @llvm.ushl.sat.v8i16(<8 x i16> %x,<8 x i16> %counts)
 %p16 = getelementptr i8,ptr %out,i64 256
 store <8 x i16> %v16,ptr %p16,align 1
 %v17 = call <8 x i16> @llvm.sshl.sat.v8i16(<8 x i16> %x,<8 x i16> %counts)
 %p17 = getelementptr i8,ptr %out,i64 272
 store <8 x i16> %v17,ptr %p17,align 1
 %v18 = call <8 x i16> @llvm.umul.fix.sat.v8i16(<8 x i16> %x,<8 x i16> %y,i32 0)
 %p18 = getelementptr i8,ptr %out,i64 288
 store <8 x i16> %v18,ptr %p18,align 1
 %v19 = call <8 x i16> @llvm.smul.fix.sat.v8i16(<8 x i16> %x,<8 x i16> %y,i32 0)
 %p19 = getelementptr i8,ptr %out,i64 304
 store <8 x i16> %v19,ptr %p19,align 1
 %answer = xor i64 %live,19
 ret i64 %answer
}
declare <4 x i32> @llvm.abs.v4i32(<4 x i32>,i1)
declare <4 x i32> @llvm.ctpop.v4i32(<4 x i32>)
declare <4 x i32> @llvm.ctlz.v4i32(<4 x i32>,i1)
declare <4 x i32> @llvm.cttz.v4i32(<4 x i32>,i1)
declare <4 x i32> @llvm.bitreverse.v4i32(<4 x i32>)
declare <4 x i32> @llvm.bswap.v4i32(<4 x i32>)
declare <4 x i32> @llvm.uadd.sat.v4i32(<4 x i32>,<4 x i32>)
declare <4 x i32> @llvm.usub.sat.v4i32(<4 x i32>,<4 x i32>)
declare <4 x i32> @llvm.sadd.sat.v4i32(<4 x i32>,<4 x i32>)
declare <4 x i32> @llvm.ssub.sat.v4i32(<4 x i32>,<4 x i32>)
declare <4 x i32> @llvm.fshl.v4i32(<4 x i32>,<4 x i32>,<4 x i32>)
declare <4 x i32> @llvm.fshr.v4i32(<4 x i32>,<4 x i32>,<4 x i32>)
declare <4 x i32> @llvm.umin.v4i32(<4 x i32>,<4 x i32>)
declare <4 x i32> @llvm.umax.v4i32(<4 x i32>,<4 x i32>)
declare <4 x i32> @llvm.smin.v4i32(<4 x i32>,<4 x i32>)
declare <4 x i32> @llvm.smax.v4i32(<4 x i32>,<4 x i32>)
declare <4 x i32> @llvm.ushl.sat.v4i32(<4 x i32>,<4 x i32>)
declare <4 x i32> @llvm.sshl.sat.v4i32(<4 x i32>,<4 x i32>)
declare <4 x i32> @llvm.umul.fix.sat.v4i32(<4 x i32>,<4 x i32>,i32)
declare <4 x i32> @llvm.smul.fix.sat.v4i32(<4 x i32>,<4 x i32>,i32)
define i64 @vector_intrinsics_32(ptr %out,ptr %xp,ptr %yp,i64 %live) {
entry:
 %x = load <4 x i32>,ptr %xp,align 1
 %y = load <4 x i32>,ptr %yp,align 1
 %counts = and <4 x i32> %y,splat (i32 31)
 %v0 = call <4 x i32> @llvm.abs.v4i32(<4 x i32> %x,i1 false)
 %p0 = getelementptr i8,ptr %out,i64 0
 store <4 x i32> %v0,ptr %p0,align 1
 %v1 = call <4 x i32> @llvm.ctpop.v4i32(<4 x i32> %x)
 %p1 = getelementptr i8,ptr %out,i64 16
 store <4 x i32> %v1,ptr %p1,align 1
 %v2 = call <4 x i32> @llvm.ctlz.v4i32(<4 x i32> %x,i1 false)
 %p2 = getelementptr i8,ptr %out,i64 32
 store <4 x i32> %v2,ptr %p2,align 1
 %v3 = call <4 x i32> @llvm.cttz.v4i32(<4 x i32> %x,i1 false)
 %p3 = getelementptr i8,ptr %out,i64 48
 store <4 x i32> %v3,ptr %p3,align 1
 %v4 = call <4 x i32> @llvm.bitreverse.v4i32(<4 x i32> %x)
 %p4 = getelementptr i8,ptr %out,i64 64
 store <4 x i32> %v4,ptr %p4,align 1
 %v5 = call <4 x i32> @llvm.bswap.v4i32(<4 x i32> %x)
 %p5 = getelementptr i8,ptr %out,i64 80
 store <4 x i32> %v5,ptr %p5,align 1
 %v6 = call <4 x i32> @llvm.uadd.sat.v4i32(<4 x i32> %x,<4 x i32> %y)
 %p6 = getelementptr i8,ptr %out,i64 96
 store <4 x i32> %v6,ptr %p6,align 1
 %v7 = call <4 x i32> @llvm.usub.sat.v4i32(<4 x i32> %x,<4 x i32> %y)
 %p7 = getelementptr i8,ptr %out,i64 112
 store <4 x i32> %v7,ptr %p7,align 1
 %v8 = call <4 x i32> @llvm.sadd.sat.v4i32(<4 x i32> %x,<4 x i32> %y)
 %p8 = getelementptr i8,ptr %out,i64 128
 store <4 x i32> %v8,ptr %p8,align 1
 %v9 = call <4 x i32> @llvm.ssub.sat.v4i32(<4 x i32> %x,<4 x i32> %y)
 %p9 = getelementptr i8,ptr %out,i64 144
 store <4 x i32> %v9,ptr %p9,align 1
 %v10 = call <4 x i32> @llvm.fshl.v4i32(<4 x i32> %x,<4 x i32> %y,<4 x i32> %y)
 %p10 = getelementptr i8,ptr %out,i64 160
 store <4 x i32> %v10,ptr %p10,align 1
 %v11 = call <4 x i32> @llvm.fshr.v4i32(<4 x i32> %x,<4 x i32> %y,<4 x i32> %y)
 %p11 = getelementptr i8,ptr %out,i64 176
 store <4 x i32> %v11,ptr %p11,align 1
 %v12 = call <4 x i32> @llvm.umin.v4i32(<4 x i32> %x,<4 x i32> %y)
 %p12 = getelementptr i8,ptr %out,i64 192
 store <4 x i32> %v12,ptr %p12,align 1
 %v13 = call <4 x i32> @llvm.umax.v4i32(<4 x i32> %x,<4 x i32> %y)
 %p13 = getelementptr i8,ptr %out,i64 208
 store <4 x i32> %v13,ptr %p13,align 1
 %v14 = call <4 x i32> @llvm.smin.v4i32(<4 x i32> %x,<4 x i32> %y)
 %p14 = getelementptr i8,ptr %out,i64 224
 store <4 x i32> %v14,ptr %p14,align 1
 %v15 = call <4 x i32> @llvm.smax.v4i32(<4 x i32> %x,<4 x i32> %y)
 %p15 = getelementptr i8,ptr %out,i64 240
 store <4 x i32> %v15,ptr %p15,align 1
 %v16 = call <4 x i32> @llvm.ushl.sat.v4i32(<4 x i32> %x,<4 x i32> %counts)
 %p16 = getelementptr i8,ptr %out,i64 256
 store <4 x i32> %v16,ptr %p16,align 1
 %v17 = call <4 x i32> @llvm.sshl.sat.v4i32(<4 x i32> %x,<4 x i32> %counts)
 %p17 = getelementptr i8,ptr %out,i64 272
 store <4 x i32> %v17,ptr %p17,align 1
 %v18 = call <4 x i32> @llvm.umul.fix.sat.v4i32(<4 x i32> %x,<4 x i32> %y,i32 0)
 %p18 = getelementptr i8,ptr %out,i64 288
 store <4 x i32> %v18,ptr %p18,align 1
 %v19 = call <4 x i32> @llvm.smul.fix.sat.v4i32(<4 x i32> %x,<4 x i32> %y,i32 0)
 %p19 = getelementptr i8,ptr %out,i64 304
 store <4 x i32> %v19,ptr %p19,align 1
 %answer = xor i64 %live,19
 ret i64 %answer
}
declare <2 x i64> @llvm.abs.v2i64(<2 x i64>,i1)
declare <2 x i64> @llvm.ctpop.v2i64(<2 x i64>)
declare <2 x i64> @llvm.ctlz.v2i64(<2 x i64>,i1)
declare <2 x i64> @llvm.cttz.v2i64(<2 x i64>,i1)
declare <2 x i64> @llvm.bitreverse.v2i64(<2 x i64>)
declare <2 x i64> @llvm.bswap.v2i64(<2 x i64>)
declare <2 x i64> @llvm.uadd.sat.v2i64(<2 x i64>,<2 x i64>)
declare <2 x i64> @llvm.usub.sat.v2i64(<2 x i64>,<2 x i64>)
declare <2 x i64> @llvm.sadd.sat.v2i64(<2 x i64>,<2 x i64>)
declare <2 x i64> @llvm.ssub.sat.v2i64(<2 x i64>,<2 x i64>)
declare <2 x i64> @llvm.fshl.v2i64(<2 x i64>,<2 x i64>,<2 x i64>)
declare <2 x i64> @llvm.fshr.v2i64(<2 x i64>,<2 x i64>,<2 x i64>)
declare <2 x i64> @llvm.umin.v2i64(<2 x i64>,<2 x i64>)
declare <2 x i64> @llvm.umax.v2i64(<2 x i64>,<2 x i64>)
declare <2 x i64> @llvm.smin.v2i64(<2 x i64>,<2 x i64>)
declare <2 x i64> @llvm.smax.v2i64(<2 x i64>,<2 x i64>)
declare <2 x i64> @llvm.ushl.sat.v2i64(<2 x i64>,<2 x i64>)
declare <2 x i64> @llvm.sshl.sat.v2i64(<2 x i64>,<2 x i64>)
declare <2 x i64> @llvm.umul.fix.sat.v2i64(<2 x i64>,<2 x i64>,i32)
declare <2 x i64> @llvm.smul.fix.sat.v2i64(<2 x i64>,<2 x i64>,i32)
define i64 @vector_intrinsics_64(ptr %out,ptr %xp,ptr %yp,i64 %live) {
entry:
 %x = load <2 x i64>,ptr %xp,align 1
 %y = load <2 x i64>,ptr %yp,align 1
 %counts = and <2 x i64> %y,splat (i64 63)
 %v0 = call <2 x i64> @llvm.abs.v2i64(<2 x i64> %x,i1 false)
 %p0 = getelementptr i8,ptr %out,i64 0
 store <2 x i64> %v0,ptr %p0,align 1
 %v1 = call <2 x i64> @llvm.ctpop.v2i64(<2 x i64> %x)
 %p1 = getelementptr i8,ptr %out,i64 16
 store <2 x i64> %v1,ptr %p1,align 1
 %v2 = call <2 x i64> @llvm.ctlz.v2i64(<2 x i64> %x,i1 false)
 %p2 = getelementptr i8,ptr %out,i64 32
 store <2 x i64> %v2,ptr %p2,align 1
 %v3 = call <2 x i64> @llvm.cttz.v2i64(<2 x i64> %x,i1 false)
 %p3 = getelementptr i8,ptr %out,i64 48
 store <2 x i64> %v3,ptr %p3,align 1
 %v4 = call <2 x i64> @llvm.bitreverse.v2i64(<2 x i64> %x)
 %p4 = getelementptr i8,ptr %out,i64 64
 store <2 x i64> %v4,ptr %p4,align 1
 %v5 = call <2 x i64> @llvm.bswap.v2i64(<2 x i64> %x)
 %p5 = getelementptr i8,ptr %out,i64 80
 store <2 x i64> %v5,ptr %p5,align 1
 %v6 = call <2 x i64> @llvm.uadd.sat.v2i64(<2 x i64> %x,<2 x i64> %y)
 %p6 = getelementptr i8,ptr %out,i64 96
 store <2 x i64> %v6,ptr %p6,align 1
 %v7 = call <2 x i64> @llvm.usub.sat.v2i64(<2 x i64> %x,<2 x i64> %y)
 %p7 = getelementptr i8,ptr %out,i64 112
 store <2 x i64> %v7,ptr %p7,align 1
 %v8 = call <2 x i64> @llvm.sadd.sat.v2i64(<2 x i64> %x,<2 x i64> %y)
 %p8 = getelementptr i8,ptr %out,i64 128
 store <2 x i64> %v8,ptr %p8,align 1
 %v9 = call <2 x i64> @llvm.ssub.sat.v2i64(<2 x i64> %x,<2 x i64> %y)
 %p9 = getelementptr i8,ptr %out,i64 144
 store <2 x i64> %v9,ptr %p9,align 1
 %v10 = call <2 x i64> @llvm.fshl.v2i64(<2 x i64> %x,<2 x i64> %y,<2 x i64> %y)
 %p10 = getelementptr i8,ptr %out,i64 160
 store <2 x i64> %v10,ptr %p10,align 1
 %v11 = call <2 x i64> @llvm.fshr.v2i64(<2 x i64> %x,<2 x i64> %y,<2 x i64> %y)
 %p11 = getelementptr i8,ptr %out,i64 176
 store <2 x i64> %v11,ptr %p11,align 1
 %v12 = call <2 x i64> @llvm.umin.v2i64(<2 x i64> %x,<2 x i64> %y)
 %p12 = getelementptr i8,ptr %out,i64 192
 store <2 x i64> %v12,ptr %p12,align 1
 %v13 = call <2 x i64> @llvm.umax.v2i64(<2 x i64> %x,<2 x i64> %y)
 %p13 = getelementptr i8,ptr %out,i64 208
 store <2 x i64> %v13,ptr %p13,align 1
 %v14 = call <2 x i64> @llvm.smin.v2i64(<2 x i64> %x,<2 x i64> %y)
 %p14 = getelementptr i8,ptr %out,i64 224
 store <2 x i64> %v14,ptr %p14,align 1
 %v15 = call <2 x i64> @llvm.smax.v2i64(<2 x i64> %x,<2 x i64> %y)
 %p15 = getelementptr i8,ptr %out,i64 240
 store <2 x i64> %v15,ptr %p15,align 1
 %v16 = call <2 x i64> @llvm.ushl.sat.v2i64(<2 x i64> %x,<2 x i64> %counts)
 %p16 = getelementptr i8,ptr %out,i64 256
 store <2 x i64> %v16,ptr %p16,align 1
 %v17 = call <2 x i64> @llvm.sshl.sat.v2i64(<2 x i64> %x,<2 x i64> %counts)
 %p17 = getelementptr i8,ptr %out,i64 272
 store <2 x i64> %v17,ptr %p17,align 1
 %v18 = call <2 x i64> @llvm.umul.fix.sat.v2i64(<2 x i64> %x,<2 x i64> %y,i32 0)
 %p18 = getelementptr i8,ptr %out,i64 288
 store <2 x i64> %v18,ptr %p18,align 1
 %v19 = call <2 x i64> @llvm.smul.fix.sat.v2i64(<2 x i64> %x,<2 x i64> %y,i32 0)
 %p19 = getelementptr i8,ptr %out,i64 304
 store <2 x i64> %v19,ptr %p19,align 1
 %answer = xor i64 %live,19
 ret i64 %answer
}
