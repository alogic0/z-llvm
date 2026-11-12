target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare i1 @llvm.vector.reduce.or.v2i1(<2 x i1>)
declare i1 @llvm.vector.reduce.and.v2i1(<2 x i1>)
define i64 @bool_constants_2(ptr %input, ptr %out, ptr %packed) {
entry:
  %x = load <2 x i1>, ptr %input, align 1
  %flip = xor <2 x i1> %x, splat (i1 true)
  %even = select <2 x i1> %x, <2 x i1> <i1 true, i1 false>, <2 x i1> splat (i1 false)
  %expanded = zext <2 x i1> %even to <2 x i8>
  store <2 x i8> %expanded, ptr %out, align 1
  store <2 x i1> %flip, ptr %packed, align 1
  %a = call i1 @llvm.vector.reduce.or.v2i1(<2 x i1> %x)
  %b = call i1 @llvm.vector.reduce.and.v2i1(<2 x i1> %flip)
  %a64 = zext i1 %a to i64
  %b64 = zext i1 %b to i64
  %bb = shl i64 %b64, 1
  %r = or i64 %a64, %bb
  ret i64 %r
}
declare i1 @llvm.vector.reduce.or.v3i1(<3 x i1>)
declare i1 @llvm.vector.reduce.and.v3i1(<3 x i1>)
define i64 @bool_constants_3(ptr %input, ptr %out, ptr %packed) {
entry:
  %x = load <3 x i1>, ptr %input, align 1
  %flip = xor <3 x i1> %x, splat (i1 true)
  %even = select <3 x i1> %x, <3 x i1> <i1 true, i1 false, i1 true>, <3 x i1> splat (i1 false)
  %expanded = zext <3 x i1> %even to <3 x i8>
  store <3 x i8> %expanded, ptr %out, align 1
  store <3 x i1> %flip, ptr %packed, align 1
  %a = call i1 @llvm.vector.reduce.or.v3i1(<3 x i1> %x)
  %b = call i1 @llvm.vector.reduce.and.v3i1(<3 x i1> %flip)
  %a64 = zext i1 %a to i64
  %b64 = zext i1 %b to i64
  %bb = shl i64 %b64, 1
  %r = or i64 %a64, %bb
  ret i64 %r
}
declare i1 @llvm.vector.reduce.or.v4i1(<4 x i1>)
declare i1 @llvm.vector.reduce.and.v4i1(<4 x i1>)
define i64 @bool_constants_4(ptr %input, ptr %out, ptr %packed) {
entry:
  %x = load <4 x i1>, ptr %input, align 1
  %flip = xor <4 x i1> %x, splat (i1 true)
  %even = select <4 x i1> %x, <4 x i1> <i1 true, i1 false, i1 true, i1 false>, <4 x i1> splat (i1 false)
  %expanded = zext <4 x i1> %even to <4 x i8>
  store <4 x i8> %expanded, ptr %out, align 1
  store <4 x i1> %flip, ptr %packed, align 1
  %a = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %x)
  %b = call i1 @llvm.vector.reduce.and.v4i1(<4 x i1> %flip)
  %a64 = zext i1 %a to i64
  %b64 = zext i1 %b to i64
  %bb = shl i64 %b64, 1
  %r = or i64 %a64, %bb
  ret i64 %r
}
declare i1 @llvm.vector.reduce.or.v7i1(<7 x i1>)
declare i1 @llvm.vector.reduce.and.v7i1(<7 x i1>)
define i64 @bool_constants_7(ptr %input, ptr %out, ptr %packed) {
entry:
  %x = load <7 x i1>, ptr %input, align 1
  %flip = xor <7 x i1> %x, splat (i1 true)
  %even = select <7 x i1> %x, <7 x i1> <i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true>, <7 x i1> splat (i1 false)
  %expanded = zext <7 x i1> %even to <7 x i8>
  store <7 x i8> %expanded, ptr %out, align 1
  store <7 x i1> %flip, ptr %packed, align 1
  %a = call i1 @llvm.vector.reduce.or.v7i1(<7 x i1> %x)
  %b = call i1 @llvm.vector.reduce.and.v7i1(<7 x i1> %flip)
  %a64 = zext i1 %a to i64
  %b64 = zext i1 %b to i64
  %bb = shl i64 %b64, 1
  %r = or i64 %a64, %bb
  ret i64 %r
}
declare i1 @llvm.vector.reduce.or.v8i1(<8 x i1>)
declare i1 @llvm.vector.reduce.and.v8i1(<8 x i1>)
define i64 @bool_constants_8(ptr %input, ptr %out, ptr %packed) {
entry:
  %x = load <8 x i1>, ptr %input, align 1
  %flip = xor <8 x i1> %x, splat (i1 true)
  %even = select <8 x i1> %x, <8 x i1> <i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false>, <8 x i1> splat (i1 false)
  %expanded = zext <8 x i1> %even to <8 x i8>
  store <8 x i8> %expanded, ptr %out, align 1
  store <8 x i1> %flip, ptr %packed, align 1
  %a = call i1 @llvm.vector.reduce.or.v8i1(<8 x i1> %x)
  %b = call i1 @llvm.vector.reduce.and.v8i1(<8 x i1> %flip)
  %a64 = zext i1 %a to i64
  %b64 = zext i1 %b to i64
  %bb = shl i64 %b64, 1
  %r = or i64 %a64, %bb
  ret i64 %r
}
declare i1 @llvm.vector.reduce.or.v16i1(<16 x i1>)
declare i1 @llvm.vector.reduce.and.v16i1(<16 x i1>)
define i64 @bool_constants_16(ptr %input, ptr %out, ptr %packed) {
entry:
  %x = load <16 x i1>, ptr %input, align 1
  %flip = xor <16 x i1> %x, splat (i1 true)
  %even = select <16 x i1> %x, <16 x i1> <i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false>, <16 x i1> splat (i1 false)
  %expanded = zext <16 x i1> %even to <16 x i8>
  store <16 x i8> %expanded, ptr %out, align 1
  store <16 x i1> %flip, ptr %packed, align 1
  %a = call i1 @llvm.vector.reduce.or.v16i1(<16 x i1> %x)
  %b = call i1 @llvm.vector.reduce.and.v16i1(<16 x i1> %flip)
  %a64 = zext i1 %a to i64
  %b64 = zext i1 %b to i64
  %bb = shl i64 %b64, 1
  %r = or i64 %a64, %bb
  ret i64 %r
}
declare i1 @llvm.vector.reduce.or.v32i1(<32 x i1>)
declare i1 @llvm.vector.reduce.and.v32i1(<32 x i1>)
define i64 @bool_constants_32(ptr %input, ptr %out, ptr %packed) {
entry:
  %x = load <32 x i1>, ptr %input, align 1
  %flip = xor <32 x i1> %x, splat (i1 true)
  %even = select <32 x i1> %x, <32 x i1> <i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false>, <32 x i1> splat (i1 false)
  %expanded = zext <32 x i1> %even to <32 x i8>
  store <32 x i8> %expanded, ptr %out, align 1
  store <32 x i1> %flip, ptr %packed, align 1
  %a = call i1 @llvm.vector.reduce.or.v32i1(<32 x i1> %x)
  %b = call i1 @llvm.vector.reduce.and.v32i1(<32 x i1> %flip)
  %a64 = zext i1 %a to i64
  %b64 = zext i1 %b to i64
  %bb = shl i64 %b64, 1
  %r = or i64 %a64, %bb
  ret i64 %r
}
declare i1 @llvm.vector.reduce.or.v64i1(<64 x i1>)
declare i1 @llvm.vector.reduce.and.v64i1(<64 x i1>)
define i64 @bool_constants_64(ptr %input, ptr %out, ptr %packed) {
entry:
  %x = load <64 x i1>, ptr %input, align 1
  %flip = xor <64 x i1> %x, splat (i1 true)
  %even = select <64 x i1> %x, <64 x i1> <i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false, i1 true, i1 false>, <64 x i1> splat (i1 false)
  %expanded = zext <64 x i1> %even to <64 x i8>
  store <64 x i8> %expanded, ptr %out, align 1
  store <64 x i1> %flip, ptr %packed, align 1
  %a = call i1 @llvm.vector.reduce.or.v64i1(<64 x i1> %x)
  %b = call i1 @llvm.vector.reduce.and.v64i1(<64 x i1> %flip)
  %a64 = zext i1 %a to i64
  %b64 = zext i1 %b to i64
  %bb = shl i64 %b64, 1
  %r = or i64 %a64, %bb
  ret i64 %r
}
