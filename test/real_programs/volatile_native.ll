target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
define i64 @volatile_native_8(ptr %p,ptr %mid,ptr %final) {
entry:
 %a = load volatile i8,ptr %p,align 1
 store volatile i8 47,ptr %p,align 1
 %unused = load volatile i8,ptr %p,align 1
 store volatile i8 undef,ptr %p,align 1
 %unspecified = load volatile i8,ptr %p,align 1
 store volatile i8 99,ptr %p,align 1
 %c = load volatile i8,ptr %p,align 1
 %a64 = zext i8 %a to i64
 %c64 = zext i8 %c to i64
 %r = add i64 %a64,%c64
 ret i64 %r
}
define i64 @volatile_native_16(ptr %p,ptr %mid,ptr %final) {
entry:
 %a = load volatile i16,ptr %p,align 1
 store volatile i16 47,ptr %p,align 1
 %unused = load volatile i16,ptr %p,align 1
 store volatile i16 undef,ptr %p,align 1
 %unspecified = load volatile i16,ptr %p,align 1
 store volatile i16 99,ptr %p,align 1
 %c = load volatile i16,ptr %p,align 1
 %a64 = zext i16 %a to i64
 %c64 = zext i16 %c to i64
 %r = add i64 %a64,%c64
 ret i64 %r
}
define i64 @volatile_native_32(ptr %p,ptr %mid,ptr %final) {
entry:
 %a = load volatile i32,ptr %p,align 1
 store volatile i32 47,ptr %p,align 1
 %unused = load volatile i32,ptr %p,align 1
 store volatile i32 undef,ptr %p,align 1
 %unspecified = load volatile i32,ptr %p,align 1
 store volatile i32 99,ptr %p,align 1
 %c = load volatile i32,ptr %p,align 1
 %a64 = zext i32 %a to i64
 %c64 = zext i32 %c to i64
 %r = add i64 %a64,%c64
 ret i64 %r
}
define i64 @volatile_native_64(ptr %p,ptr %mid,ptr %final) {
entry:
 %a = load volatile i64,ptr %p,align 1
 store volatile i64 47,ptr %p,align 1
 %unused = load volatile i64,ptr %p,align 1
 store volatile i64 undef,ptr %p,align 1
 %unspecified = load volatile i64,ptr %p,align 1
 store volatile i64 99,ptr %p,align 1
 %c = load volatile i64,ptr %p,align 1
 %a64 = bitcast i64 %a to i64
 %c64 = bitcast i64 %c to i64
 %r = add i64 %a64,%c64
 ret i64 %r
}
define i64 @volatile_native_ptr(ptr %p,ptr %mid,ptr %final) {
entry:
 %a = load volatile ptr,ptr %p,align 1
 store volatile ptr %mid,ptr %p,align 1
 %unused = load volatile ptr,ptr %p,align 1
 store volatile ptr undef,ptr %p,align 1
 %unspecified = load volatile ptr,ptr %p,align 1
 store volatile ptr %final,ptr %p,align 1
 %c = load volatile ptr,ptr %p,align 1
 %a64 = ptrtoint ptr %a to i64
 %c64 = ptrtoint ptr %c to i64
 %r = add i64 %a64,%c64
 ret i64 %r
}
