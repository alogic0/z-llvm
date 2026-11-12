target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
define i64 @limb_divisions_140(ptr %out,ptr %xp,ptr %yp,i64 %live) {
entry:
 %x = load i140,ptr %xp,align 1
 %y = load i140,ptr %yp,align 1
 %v0 = udiv i140 %x,%y
 %p0 = getelementptr i8,ptr %out,i64 0
 store i140 %v0,ptr %p0,align 1
 %v1 = urem i140 %x,%y
 %p1 = getelementptr i8,ptr %out,i64 64
 store i140 %v1,ptr %p1,align 1
 %v2 = sdiv i140 %x,%y
 %p2 = getelementptr i8,ptr %out,i64 128
 store i140 %v2,ptr %p2,align 1
 %v3 = srem i140 %x,%y
 %p3 = getelementptr i8,ptr %out,i64 192
 store i140 %v3,ptr %p3,align 1
 %a = trunc i140 %x to i64
 %b = trunc i140 %y to i64
 %c = xor i64 %a,%b
 %r = xor i64 %c,%live
 ret i64 %r
}
define i64 @limb_divisions_200(ptr %out,ptr %xp,ptr %yp,i64 %live) {
entry:
 %x = load i200,ptr %xp,align 1
 %y = load i200,ptr %yp,align 1
 %v0 = udiv i200 %x,%y
 %p0 = getelementptr i8,ptr %out,i64 0
 store i200 %v0,ptr %p0,align 1
 %v1 = urem i200 %x,%y
 %p1 = getelementptr i8,ptr %out,i64 64
 store i200 %v1,ptr %p1,align 1
 %v2 = sdiv i200 %x,%y
 %p2 = getelementptr i8,ptr %out,i64 128
 store i200 %v2,ptr %p2,align 1
 %v3 = srem i200 %x,%y
 %p3 = getelementptr i8,ptr %out,i64 192
 store i200 %v3,ptr %p3,align 1
 %a = trunc i200 %x to i64
 %b = trunc i200 %y to i64
 %c = xor i64 %a,%b
 %r = xor i64 %c,%live
 ret i64 %r
}
define i64 @limb_divisions_256(ptr %out,ptr %xp,ptr %yp,i64 %live) {
entry:
 %x = load i256,ptr %xp,align 1
 %y = load i256,ptr %yp,align 1
 %v0 = udiv i256 %x,%y
 %p0 = getelementptr i8,ptr %out,i64 0
 store i256 %v0,ptr %p0,align 1
 %v1 = urem i256 %x,%y
 %p1 = getelementptr i8,ptr %out,i64 64
 store i256 %v1,ptr %p1,align 1
 %v2 = sdiv i256 %x,%y
 %p2 = getelementptr i8,ptr %out,i64 128
 store i256 %v2,ptr %p2,align 1
 %v3 = srem i256 %x,%y
 %p3 = getelementptr i8,ptr %out,i64 192
 store i256 %v3,ptr %p3,align 1
 %a = trunc i256 %x to i64
 %b = trunc i256 %y to i64
 %c = xor i64 %a,%b
 %r = xor i64 %c,%live
 ret i64 %r
}
define i64 @limb_divisions_495(ptr %out,ptr %xp,ptr %yp,i64 %live) {
entry:
 %x = load i495,ptr %xp,align 1
 %y = load i495,ptr %yp,align 1
 %v0 = udiv i495 %x,%y
 %p0 = getelementptr i8,ptr %out,i64 0
 store i495 %v0,ptr %p0,align 1
 %v1 = urem i495 %x,%y
 %p1 = getelementptr i8,ptr %out,i64 64
 store i495 %v1,ptr %p1,align 1
 %v2 = sdiv i495 %x,%y
 %p2 = getelementptr i8,ptr %out,i64 128
 store i495 %v2,ptr %p2,align 1
 %v3 = srem i495 %x,%y
 %p3 = getelementptr i8,ptr %out,i64 192
 store i495 %v3,ptr %p3,align 1
 %a = trunc i495 %x to i64
 %b = trunc i495 %y to i64
 %c = xor i64 %a,%b
 %r = xor i64 %c,%live
 ret i64 %r
}
