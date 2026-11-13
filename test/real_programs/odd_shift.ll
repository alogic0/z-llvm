target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare i64 @odd_shift_clobber(i64,i64,i64,i64,i64,i64,i64,i64)
define i64 @odd_shift_body_0(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <1 x i24>,ptr %a,align 1
 %y = load <1 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = shl <1 x i24> %x,%y
 store <1 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_0(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call i64 @odd_shift_body_0(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define fastcc i64 @odd_shift_body_1(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <1 x i24>,ptr %a,align 1
 %y = load <1 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = shl <1 x i24> %x,%y
 store <1 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_1(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call fastcc i64 @odd_shift_body_1(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define i64 @odd_shift_body_2(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <1 x i24>,ptr %a,align 1
 %y = load <1 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = lshr <1 x i24> %x,%y
 store <1 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_2(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call i64 @odd_shift_body_2(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define fastcc i64 @odd_shift_body_3(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <1 x i24>,ptr %a,align 1
 %y = load <1 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = lshr <1 x i24> %x,%y
 store <1 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_3(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call fastcc i64 @odd_shift_body_3(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define i64 @odd_shift_body_4(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <1 x i24>,ptr %a,align 1
 %y = load <1 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = ashr <1 x i24> %x,%y
 store <1 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_4(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call i64 @odd_shift_body_4(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define fastcc i64 @odd_shift_body_5(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <1 x i24>,ptr %a,align 1
 %y = load <1 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = ashr <1 x i24> %x,%y
 store <1 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_5(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call fastcc i64 @odd_shift_body_5(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define i64 @odd_shift_body_6(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <2 x i24>,ptr %a,align 1
 %y = load <2 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = shl <2 x i24> %x,%y
 store <2 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_6(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call i64 @odd_shift_body_6(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define fastcc i64 @odd_shift_body_7(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <2 x i24>,ptr %a,align 1
 %y = load <2 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = shl <2 x i24> %x,%y
 store <2 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_7(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call fastcc i64 @odd_shift_body_7(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define i64 @odd_shift_body_8(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <2 x i24>,ptr %a,align 1
 %y = load <2 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = lshr <2 x i24> %x,%y
 store <2 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_8(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call i64 @odd_shift_body_8(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define fastcc i64 @odd_shift_body_9(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <2 x i24>,ptr %a,align 1
 %y = load <2 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = lshr <2 x i24> %x,%y
 store <2 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_9(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call fastcc i64 @odd_shift_body_9(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define i64 @odd_shift_body_10(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <2 x i24>,ptr %a,align 1
 %y = load <2 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = ashr <2 x i24> %x,%y
 store <2 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_10(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call i64 @odd_shift_body_10(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define fastcc i64 @odd_shift_body_11(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <2 x i24>,ptr %a,align 1
 %y = load <2 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = ashr <2 x i24> %x,%y
 store <2 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_11(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call fastcc i64 @odd_shift_body_11(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define i64 @odd_shift_body_12(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <4 x i24>,ptr %a,align 1
 %y = load <4 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = shl <4 x i24> %x,%y
 store <4 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_12(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call i64 @odd_shift_body_12(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define fastcc i64 @odd_shift_body_13(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <4 x i24>,ptr %a,align 1
 %y = load <4 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = shl <4 x i24> %x,%y
 store <4 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_13(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call fastcc i64 @odd_shift_body_13(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define i64 @odd_shift_body_14(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <4 x i24>,ptr %a,align 1
 %y = load <4 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = lshr <4 x i24> %x,%y
 store <4 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_14(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call i64 @odd_shift_body_14(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define fastcc i64 @odd_shift_body_15(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <4 x i24>,ptr %a,align 1
 %y = load <4 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = lshr <4 x i24> %x,%y
 store <4 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_15(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call fastcc i64 @odd_shift_body_15(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define i64 @odd_shift_body_16(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <4 x i24>,ptr %a,align 1
 %y = load <4 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = ashr <4 x i24> %x,%y
 store <4 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_16(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call i64 @odd_shift_body_16(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define fastcc i64 @odd_shift_body_17(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <4 x i24>,ptr %a,align 1
 %y = load <4 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = ashr <4 x i24> %x,%y
 store <4 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_17(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call fastcc i64 @odd_shift_body_17(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define i64 @odd_shift_body_18(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <8 x i24>,ptr %a,align 1
 %y = load <8 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = shl <8 x i24> %x,%y
 store <8 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_18(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call i64 @odd_shift_body_18(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define fastcc i64 @odd_shift_body_19(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <8 x i24>,ptr %a,align 1
 %y = load <8 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = shl <8 x i24> %x,%y
 store <8 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_19(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call fastcc i64 @odd_shift_body_19(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define i64 @odd_shift_body_20(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <8 x i24>,ptr %a,align 1
 %y = load <8 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = lshr <8 x i24> %x,%y
 store <8 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_20(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call i64 @odd_shift_body_20(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define fastcc i64 @odd_shift_body_21(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <8 x i24>,ptr %a,align 1
 %y = load <8 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = lshr <8 x i24> %x,%y
 store <8 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_21(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call fastcc i64 @odd_shift_body_21(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define i64 @odd_shift_body_22(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <8 x i24>,ptr %a,align 1
 %y = load <8 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = ashr <8 x i24> %x,%y
 store <8 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_22(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call i64 @odd_shift_body_22(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define fastcc i64 @odd_shift_body_23(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <8 x i24>,ptr %a,align 1
 %y = load <8 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = ashr <8 x i24> %x,%y
 store <8 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_23(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call fastcc i64 @odd_shift_body_23(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define i64 @odd_shift_body_24(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <16 x i24>,ptr %a,align 1
 %y = load <16 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = shl <16 x i24> %x,%y
 store <16 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_24(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call i64 @odd_shift_body_24(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define fastcc i64 @odd_shift_body_25(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <16 x i24>,ptr %a,align 1
 %y = load <16 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = shl <16 x i24> %x,%y
 store <16 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_25(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call fastcc i64 @odd_shift_body_25(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define i64 @odd_shift_body_26(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <16 x i24>,ptr %a,align 1
 %y = load <16 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = lshr <16 x i24> %x,%y
 store <16 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_26(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call i64 @odd_shift_body_26(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define fastcc i64 @odd_shift_body_27(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <16 x i24>,ptr %a,align 1
 %y = load <16 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = lshr <16 x i24> %x,%y
 store <16 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_27(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call fastcc i64 @odd_shift_body_27(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define i64 @odd_shift_body_28(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <16 x i24>,ptr %a,align 1
 %y = load <16 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = ashr <16 x i24> %x,%y
 store <16 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_28(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call i64 @odd_shift_body_28(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define fastcc i64 @odd_shift_body_29(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <16 x i24>,ptr %a,align 1
 %y = load <16 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = ashr <16 x i24> %x,%y
 store <16 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_29(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call fastcc i64 @odd_shift_body_29(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define i64 @odd_shift_body_30(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <32 x i24>,ptr %a,align 1
 %y = load <32 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = shl <32 x i24> %x,%y
 store <32 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_30(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call i64 @odd_shift_body_30(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define fastcc i64 @odd_shift_body_31(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <32 x i24>,ptr %a,align 1
 %y = load <32 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = shl <32 x i24> %x,%y
 store <32 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_31(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call fastcc i64 @odd_shift_body_31(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define i64 @odd_shift_body_32(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <32 x i24>,ptr %a,align 1
 %y = load <32 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = lshr <32 x i24> %x,%y
 store <32 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_32(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call i64 @odd_shift_body_32(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define fastcc i64 @odd_shift_body_33(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <32 x i24>,ptr %a,align 1
 %y = load <32 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = lshr <32 x i24> %x,%y
 store <32 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_33(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call fastcc i64 @odd_shift_body_33(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define i64 @odd_shift_body_34(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <32 x i24>,ptr %a,align 1
 %y = load <32 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = ashr <32 x i24> %x,%y
 store <32 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_34(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call i64 @odd_shift_body_34(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define fastcc i64 @odd_shift_body_35(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <32 x i24>,ptr %a,align 1
 %y = load <32 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = ashr <32 x i24> %x,%y
 store <32 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_35(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call fastcc i64 @odd_shift_body_35(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define i64 @odd_shift_body_36(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <64 x i24>,ptr %a,align 1
 %y = load <64 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = shl <64 x i24> %x,%y
 store <64 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_36(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call i64 @odd_shift_body_36(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define fastcc i64 @odd_shift_body_37(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <64 x i24>,ptr %a,align 1
 %y = load <64 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = shl <64 x i24> %x,%y
 store <64 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_37(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call fastcc i64 @odd_shift_body_37(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define i64 @odd_shift_body_38(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <64 x i24>,ptr %a,align 1
 %y = load <64 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = lshr <64 x i24> %x,%y
 store <64 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_38(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call i64 @odd_shift_body_38(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define fastcc i64 @odd_shift_body_39(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <64 x i24>,ptr %a,align 1
 %y = load <64 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = lshr <64 x i24> %x,%y
 store <64 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_39(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call fastcc i64 @odd_shift_body_39(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define i64 @odd_shift_body_40(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <64 x i24>,ptr %a,align 1
 %y = load <64 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = ashr <64 x i24> %x,%y
 store <64 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_40(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call i64 @odd_shift_body_40(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
define fastcc i64 @odd_shift_body_41(ptr %out,ptr %a,ptr %b,i64 %salt) noinline {
entry:
 %x = load <64 x i24>,ptr %a,align 1
 %y = load <64 x i24>,ptr %b,align 1
 %token = call i64 @odd_shift_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %v = ashr <64 x i24> %x,%y
 store <64 x i24> %v,ptr %out,align 1
 %r = xor i64 %token,%salt
 ret i64 %r
}
define i64 @odd_shift_probe_41(ptr %out,ptr %a,ptr %b,i64 %salt) {
entry:
 %r = call fastcc i64 @odd_shift_body_41(ptr %out,ptr %a,ptr %b,i64 %salt)
 ret i64 %r
}
