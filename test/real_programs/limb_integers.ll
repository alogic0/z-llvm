target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare fastcc i256 @oracle256(i140, i495, i64)

define fastcc i64 @wide_in140(ptr %out, i140 %a, i128 %b, i64 %tail) {
entry:
 store i140 %a, ptr %out, align 1
 %p = getelementptr i8, ptr %out, i64 32
 store i128 %b, ptr %p, align 1
 %a0 = trunc i140 %a to i64
 %b0 = trunc i128 %b to i64
 %x = xor i64 %a0, %b0
 %r = xor i64 %x, %tail
 ret i64 %r
}
define fastcc i64 @wide_in495(ptr %out, i495 %a, i9 %shift) {
entry:
 store i495 %a, ptr %out, align 1
 %p = getelementptr i8, ptr %out, i64 64
 store i9 %shift, ptr %p, align 1
 %low = trunc i495 %a to i64
 %s = zext i9 %shift to i64
 %r = xor i64 %low, %s
 ret i64 %r
}
define i64 @wide_in200(ptr %out, i200 %a, i128 %b, i64 %tail) {
entry:
 store i200 %a, ptr %out, align 1
 %p = getelementptr i8, ptr %out, i64 32
 store i128 %b, ptr %p, align 1
 %a0 = trunc i200 %a to i64
 %b0 = trunc i128 %b to i64
 %x = xor i64 %a0, %b0
 %r = xor i64 %x, %tail
 ret i64 %r
}
define fastcc i256 @wide_ret256(i256 %a, i64 %salt) {
entry:
 %s = zext i64 %salt to i256
 %r = xor i256 %a, %s
 ret i256 %r
}
define i64 @wide_outbound(ptr %out, ptr %a, ptr %b, i64 %salt) {
entry:
 %x = load i140, ptr %a, align 1
 %y = load i495, ptr %b, align 1
 %result = call fastcc i256 @oracle256(i140 %x, i495 %y, i64 %salt)
 store i256 %result, ptr %out, align 1
 %low = trunc i256 %result to i64
 ret i64 %low
}
define i256 @wide_ret256_default(i256 %a, i64 %salt) {
entry:
 %s = zext i64 %salt to i256
 %r = xor i256 %a, %s
 ret i256 %r
}
