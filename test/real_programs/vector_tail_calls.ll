target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare i64 @complete_clobber(i64,i64,i64,i64,i64,i64,i64,i64)
define internal i64 @vector_tail_body_0(ptr %out,<2 x i8> noundef range(i8 4, 21) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <2 x i8> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_0(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <2 x i8>,ptr %source,align 1
 %r = tail call i64 @vector_tail_body_0(ptr %out,<2 x i8> noundef range(i8 4, 21) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal i64 @vector_tail_body_1(ptr %out,<2 x i8> noundef range(i8 4, 21) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <2 x i8> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_1(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <2 x i8>,ptr %source,align 1
 %r = notail call i64 @vector_tail_body_1(ptr %out,<2 x i8> noundef range(i8 4, 21) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_2(ptr %out,<2 x i8> noundef range(i8 4, 21) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <2 x i8> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_2(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <2 x i8>,ptr %source,align 1
 %r = tail call fastcc i64 @vector_tail_body_2(ptr %out,<2 x i8> noundef range(i8 4, 21) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_3(ptr %out,<2 x i8> noundef range(i8 4, 21) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <2 x i8> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_3(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <2 x i8>,ptr %source,align 1
 %r = notail call fastcc i64 @vector_tail_body_3(ptr %out,<2 x i8> noundef range(i8 4, 21) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal i64 @vector_tail_body_4(ptr %out,<2 x i8> noundef range(i8 -5, 5) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <2 x i8> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_4(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <2 x i8>,ptr %source,align 1
 %r = tail call i64 @vector_tail_body_4(ptr %out,<2 x i8> noundef range(i8 -5, 5) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal i64 @vector_tail_body_5(ptr %out,<2 x i8> noundef range(i8 -5, 5) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <2 x i8> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_5(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <2 x i8>,ptr %source,align 1
 %r = notail call i64 @vector_tail_body_5(ptr %out,<2 x i8> noundef range(i8 -5, 5) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_6(ptr %out,<2 x i8> noundef range(i8 -5, 5) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <2 x i8> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_6(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <2 x i8>,ptr %source,align 1
 %r = tail call fastcc i64 @vector_tail_body_6(ptr %out,<2 x i8> noundef range(i8 -5, 5) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_7(ptr %out,<2 x i8> noundef range(i8 -5, 5) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <2 x i8> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_7(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <2 x i8>,ptr %source,align 1
 %r = notail call fastcc i64 @vector_tail_body_7(ptr %out,<2 x i8> noundef range(i8 -5, 5) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal i64 @vector_tail_body_8(ptr %out,<2 x i8> noundef range(i8 -4, 4) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <2 x i8> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_8(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <2 x i8>,ptr %source,align 1
 %r = tail call i64 @vector_tail_body_8(ptr %out,<2 x i8> noundef range(i8 -4, 4) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal i64 @vector_tail_body_9(ptr %out,<2 x i8> noundef range(i8 -4, 4) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <2 x i8> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_9(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <2 x i8>,ptr %source,align 1
 %r = notail call i64 @vector_tail_body_9(ptr %out,<2 x i8> noundef range(i8 -4, 4) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_10(ptr %out,<2 x i8> noundef range(i8 -4, 4) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <2 x i8> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_10(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <2 x i8>,ptr %source,align 1
 %r = tail call fastcc i64 @vector_tail_body_10(ptr %out,<2 x i8> noundef range(i8 -4, 4) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_11(ptr %out,<2 x i8> noundef range(i8 -4, 4) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <2 x i8> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_11(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <2 x i8>,ptr %source,align 1
 %r = notail call fastcc i64 @vector_tail_body_11(ptr %out,<2 x i8> noundef range(i8 -4, 4) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal i64 @vector_tail_body_12(ptr %out,<2 x i8> noundef range(i8 1, 0) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <2 x i8> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_12(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <2 x i8>,ptr %source,align 1
 %r = tail call i64 @vector_tail_body_12(ptr %out,<2 x i8> noundef range(i8 1, 0) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal i64 @vector_tail_body_13(ptr %out,<2 x i8> noundef range(i8 1, 0) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <2 x i8> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_13(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <2 x i8>,ptr %source,align 1
 %r = notail call i64 @vector_tail_body_13(ptr %out,<2 x i8> noundef range(i8 1, 0) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_14(ptr %out,<2 x i8> noundef range(i8 1, 0) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <2 x i8> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_14(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <2 x i8>,ptr %source,align 1
 %r = tail call fastcc i64 @vector_tail_body_14(ptr %out,<2 x i8> noundef range(i8 1, 0) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_15(ptr %out,<2 x i8> noundef range(i8 1, 0) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <2 x i8> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_15(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <2 x i8>,ptr %source,align 1
 %r = notail call fastcc i64 @vector_tail_body_15(ptr %out,<2 x i8> noundef range(i8 1, 0) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal i64 @vector_tail_body_16(ptr %out,<32 x i8> noundef range(i8 4, 21) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <32 x i8> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 32
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_16(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <32 x i8>,ptr %source,align 1
 %r = tail call i64 @vector_tail_body_16(ptr %out,<32 x i8> noundef range(i8 4, 21) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal i64 @vector_tail_body_17(ptr %out,<32 x i8> noundef range(i8 4, 21) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <32 x i8> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 32
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_17(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <32 x i8>,ptr %source,align 1
 %r = notail call i64 @vector_tail_body_17(ptr %out,<32 x i8> noundef range(i8 4, 21) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_18(ptr %out,<32 x i8> noundef range(i8 4, 21) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <32 x i8> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 32
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_18(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <32 x i8>,ptr %source,align 1
 %r = tail call fastcc i64 @vector_tail_body_18(ptr %out,<32 x i8> noundef range(i8 4, 21) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_19(ptr %out,<32 x i8> noundef range(i8 4, 21) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <32 x i8> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 32
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_19(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <32 x i8>,ptr %source,align 1
 %r = notail call fastcc i64 @vector_tail_body_19(ptr %out,<32 x i8> noundef range(i8 4, 21) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal i64 @vector_tail_body_20(ptr %out,<32 x i8> noundef range(i8 -5, 5) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <32 x i8> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 32
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_20(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <32 x i8>,ptr %source,align 1
 %r = tail call i64 @vector_tail_body_20(ptr %out,<32 x i8> noundef range(i8 -5, 5) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal i64 @vector_tail_body_21(ptr %out,<32 x i8> noundef range(i8 -5, 5) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <32 x i8> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 32
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_21(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <32 x i8>,ptr %source,align 1
 %r = notail call i64 @vector_tail_body_21(ptr %out,<32 x i8> noundef range(i8 -5, 5) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_22(ptr %out,<32 x i8> noundef range(i8 -5, 5) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <32 x i8> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 32
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_22(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <32 x i8>,ptr %source,align 1
 %r = tail call fastcc i64 @vector_tail_body_22(ptr %out,<32 x i8> noundef range(i8 -5, 5) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_23(ptr %out,<32 x i8> noundef range(i8 -5, 5) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <32 x i8> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 32
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_23(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <32 x i8>,ptr %source,align 1
 %r = notail call fastcc i64 @vector_tail_body_23(ptr %out,<32 x i8> noundef range(i8 -5, 5) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal i64 @vector_tail_body_24(ptr %out,<32 x i8> noundef range(i8 -4, 4) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <32 x i8> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 32
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_24(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <32 x i8>,ptr %source,align 1
 %r = tail call i64 @vector_tail_body_24(ptr %out,<32 x i8> noundef range(i8 -4, 4) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal i64 @vector_tail_body_25(ptr %out,<32 x i8> noundef range(i8 -4, 4) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <32 x i8> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 32
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_25(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <32 x i8>,ptr %source,align 1
 %r = notail call i64 @vector_tail_body_25(ptr %out,<32 x i8> noundef range(i8 -4, 4) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_26(ptr %out,<32 x i8> noundef range(i8 -4, 4) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <32 x i8> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 32
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_26(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <32 x i8>,ptr %source,align 1
 %r = tail call fastcc i64 @vector_tail_body_26(ptr %out,<32 x i8> noundef range(i8 -4, 4) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_27(ptr %out,<32 x i8> noundef range(i8 -4, 4) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <32 x i8> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 32
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_27(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <32 x i8>,ptr %source,align 1
 %r = notail call fastcc i64 @vector_tail_body_27(ptr %out,<32 x i8> noundef range(i8 -4, 4) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal i64 @vector_tail_body_28(ptr %out,<32 x i8> noundef range(i8 1, 0) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <32 x i8> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 32
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_28(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <32 x i8>,ptr %source,align 1
 %r = tail call i64 @vector_tail_body_28(ptr %out,<32 x i8> noundef range(i8 1, 0) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal i64 @vector_tail_body_29(ptr %out,<32 x i8> noundef range(i8 1, 0) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <32 x i8> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 32
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_29(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <32 x i8>,ptr %source,align 1
 %r = notail call i64 @vector_tail_body_29(ptr %out,<32 x i8> noundef range(i8 1, 0) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_30(ptr %out,<32 x i8> noundef range(i8 1, 0) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <32 x i8> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 32
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_30(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <32 x i8>,ptr %source,align 1
 %r = tail call fastcc i64 @vector_tail_body_30(ptr %out,<32 x i8> noundef range(i8 1, 0) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_31(ptr %out,<32 x i8> noundef range(i8 1, 0) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <32 x i8> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 32
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_31(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <32 x i8>,ptr %source,align 1
 %r = notail call fastcc i64 @vector_tail_body_31(ptr %out,<32 x i8> noundef range(i8 1, 0) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal i64 @vector_tail_body_32(ptr %out,<3 x i32> noundef range(i32 4, 21) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <3 x i32> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 12
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_32(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <3 x i32>,ptr %source,align 1
 %r = tail call i64 @vector_tail_body_32(ptr %out,<3 x i32> noundef range(i32 4, 21) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal i64 @vector_tail_body_33(ptr %out,<3 x i32> noundef range(i32 4, 21) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <3 x i32> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 12
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_33(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <3 x i32>,ptr %source,align 1
 %r = notail call i64 @vector_tail_body_33(ptr %out,<3 x i32> noundef range(i32 4, 21) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_34(ptr %out,<3 x i32> noundef range(i32 4, 21) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <3 x i32> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 12
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_34(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <3 x i32>,ptr %source,align 1
 %r = tail call fastcc i64 @vector_tail_body_34(ptr %out,<3 x i32> noundef range(i32 4, 21) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_35(ptr %out,<3 x i32> noundef range(i32 4, 21) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <3 x i32> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 12
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_35(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <3 x i32>,ptr %source,align 1
 %r = notail call fastcc i64 @vector_tail_body_35(ptr %out,<3 x i32> noundef range(i32 4, 21) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal i64 @vector_tail_body_36(ptr %out,<3 x i32> noundef range(i32 -5, 5) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <3 x i32> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 12
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_36(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <3 x i32>,ptr %source,align 1
 %r = tail call i64 @vector_tail_body_36(ptr %out,<3 x i32> noundef range(i32 -5, 5) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal i64 @vector_tail_body_37(ptr %out,<3 x i32> noundef range(i32 -5, 5) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <3 x i32> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 12
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_37(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <3 x i32>,ptr %source,align 1
 %r = notail call i64 @vector_tail_body_37(ptr %out,<3 x i32> noundef range(i32 -5, 5) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_38(ptr %out,<3 x i32> noundef range(i32 -5, 5) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <3 x i32> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 12
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_38(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <3 x i32>,ptr %source,align 1
 %r = tail call fastcc i64 @vector_tail_body_38(ptr %out,<3 x i32> noundef range(i32 -5, 5) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_39(ptr %out,<3 x i32> noundef range(i32 -5, 5) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <3 x i32> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 12
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_39(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <3 x i32>,ptr %source,align 1
 %r = notail call fastcc i64 @vector_tail_body_39(ptr %out,<3 x i32> noundef range(i32 -5, 5) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal i64 @vector_tail_body_40(ptr %out,<3 x i32> noundef range(i32 -4, 4) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <3 x i32> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 12
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_40(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <3 x i32>,ptr %source,align 1
 %r = tail call i64 @vector_tail_body_40(ptr %out,<3 x i32> noundef range(i32 -4, 4) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal i64 @vector_tail_body_41(ptr %out,<3 x i32> noundef range(i32 -4, 4) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <3 x i32> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 12
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_41(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <3 x i32>,ptr %source,align 1
 %r = notail call i64 @vector_tail_body_41(ptr %out,<3 x i32> noundef range(i32 -4, 4) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_42(ptr %out,<3 x i32> noundef range(i32 -4, 4) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <3 x i32> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 12
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_42(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <3 x i32>,ptr %source,align 1
 %r = tail call fastcc i64 @vector_tail_body_42(ptr %out,<3 x i32> noundef range(i32 -4, 4) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_43(ptr %out,<3 x i32> noundef range(i32 -4, 4) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <3 x i32> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 12
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_43(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <3 x i32>,ptr %source,align 1
 %r = notail call fastcc i64 @vector_tail_body_43(ptr %out,<3 x i32> noundef range(i32 -4, 4) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal i64 @vector_tail_body_44(ptr %out,<3 x i32> noundef range(i32 1, 0) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <3 x i32> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 12
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_44(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <3 x i32>,ptr %source,align 1
 %r = tail call i64 @vector_tail_body_44(ptr %out,<3 x i32> noundef range(i32 1, 0) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal i64 @vector_tail_body_45(ptr %out,<3 x i32> noundef range(i32 1, 0) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <3 x i32> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 12
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_45(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <3 x i32>,ptr %source,align 1
 %r = notail call i64 @vector_tail_body_45(ptr %out,<3 x i32> noundef range(i32 1, 0) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_46(ptr %out,<3 x i32> noundef range(i32 1, 0) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <3 x i32> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 12
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_46(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <3 x i32>,ptr %source,align 1
 %r = tail call fastcc i64 @vector_tail_body_46(ptr %out,<3 x i32> noundef range(i32 1, 0) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_47(ptr %out,<3 x i32> noundef range(i32 1, 0) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <3 x i32> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 12
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_47(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <3 x i32>,ptr %source,align 1
 %r = notail call fastcc i64 @vector_tail_body_47(ptr %out,<3 x i32> noundef range(i32 1, 0) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_48(ptr %out,<64 x i32> noundef range(i32 4, 21) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <64 x i32> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 256
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_48(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <64 x i32>,ptr %source,align 1
 %r = tail call fastcc i64 @vector_tail_body_48(ptr %out,<64 x i32> noundef range(i32 4, 21) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_49(ptr %out,<64 x i32> noundef range(i32 4, 21) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <64 x i32> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 256
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_49(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <64 x i32>,ptr %source,align 1
 %r = notail call fastcc i64 @vector_tail_body_49(ptr %out,<64 x i32> noundef range(i32 4, 21) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_50(ptr %out,<64 x i32> noundef range(i32 -5, 5) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <64 x i32> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 256
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_50(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <64 x i32>,ptr %source,align 1
 %r = tail call fastcc i64 @vector_tail_body_50(ptr %out,<64 x i32> noundef range(i32 -5, 5) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_51(ptr %out,<64 x i32> noundef range(i32 -5, 5) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <64 x i32> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 256
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_51(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <64 x i32>,ptr %source,align 1
 %r = notail call fastcc i64 @vector_tail_body_51(ptr %out,<64 x i32> noundef range(i32 -5, 5) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_52(ptr %out,<64 x i32> noundef range(i32 -4, 4) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <64 x i32> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 256
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_52(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <64 x i32>,ptr %source,align 1
 %r = tail call fastcc i64 @vector_tail_body_52(ptr %out,<64 x i32> noundef range(i32 -4, 4) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_53(ptr %out,<64 x i32> noundef range(i32 -4, 4) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <64 x i32> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 256
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_53(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <64 x i32>,ptr %source,align 1
 %r = notail call fastcc i64 @vector_tail_body_53(ptr %out,<64 x i32> noundef range(i32 -4, 4) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_54(ptr %out,<64 x i32> noundef range(i32 1, 0) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <64 x i32> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 256
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_54(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <64 x i32>,ptr %source,align 1
 %r = tail call fastcc i64 @vector_tail_body_54(ptr %out,<64 x i32> noundef range(i32 1, 0) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_55(ptr %out,<64 x i32> noundef range(i32 1, 0) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <64 x i32> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 256
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_55(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <64 x i32>,ptr %source,align 1
 %r = notail call fastcc i64 @vector_tail_body_55(ptr %out,<64 x i32> noundef range(i32 1, 0) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal i64 @vector_tail_body_56(ptr %out,<8 x i64> noundef range(i64 4, 21) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <8 x i64> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 64
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_56(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <8 x i64>,ptr %source,align 1
 %r = tail call i64 @vector_tail_body_56(ptr %out,<8 x i64> noundef range(i64 4, 21) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal i64 @vector_tail_body_57(ptr %out,<8 x i64> noundef range(i64 4, 21) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <8 x i64> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 64
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_57(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <8 x i64>,ptr %source,align 1
 %r = notail call i64 @vector_tail_body_57(ptr %out,<8 x i64> noundef range(i64 4, 21) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_58(ptr %out,<8 x i64> noundef range(i64 4, 21) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <8 x i64> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 64
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_58(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <8 x i64>,ptr %source,align 1
 %r = tail call fastcc i64 @vector_tail_body_58(ptr %out,<8 x i64> noundef range(i64 4, 21) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_59(ptr %out,<8 x i64> noundef range(i64 4, 21) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <8 x i64> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 64
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_59(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <8 x i64>,ptr %source,align 1
 %r = notail call fastcc i64 @vector_tail_body_59(ptr %out,<8 x i64> noundef range(i64 4, 21) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal i64 @vector_tail_body_60(ptr %out,<8 x i64> noundef range(i64 -5, 5) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <8 x i64> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 64
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_60(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <8 x i64>,ptr %source,align 1
 %r = tail call i64 @vector_tail_body_60(ptr %out,<8 x i64> noundef range(i64 -5, 5) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal i64 @vector_tail_body_61(ptr %out,<8 x i64> noundef range(i64 -5, 5) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <8 x i64> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 64
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_61(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <8 x i64>,ptr %source,align 1
 %r = notail call i64 @vector_tail_body_61(ptr %out,<8 x i64> noundef range(i64 -5, 5) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_62(ptr %out,<8 x i64> noundef range(i64 -5, 5) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <8 x i64> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 64
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_62(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <8 x i64>,ptr %source,align 1
 %r = tail call fastcc i64 @vector_tail_body_62(ptr %out,<8 x i64> noundef range(i64 -5, 5) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_63(ptr %out,<8 x i64> noundef range(i64 -5, 5) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <8 x i64> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 64
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_63(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <8 x i64>,ptr %source,align 1
 %r = notail call fastcc i64 @vector_tail_body_63(ptr %out,<8 x i64> noundef range(i64 -5, 5) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal i64 @vector_tail_body_64(ptr %out,<8 x i64> noundef range(i64 -4, 4) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <8 x i64> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 64
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_64(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <8 x i64>,ptr %source,align 1
 %r = tail call i64 @vector_tail_body_64(ptr %out,<8 x i64> noundef range(i64 -4, 4) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal i64 @vector_tail_body_65(ptr %out,<8 x i64> noundef range(i64 -4, 4) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <8 x i64> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 64
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_65(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <8 x i64>,ptr %source,align 1
 %r = notail call i64 @vector_tail_body_65(ptr %out,<8 x i64> noundef range(i64 -4, 4) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_66(ptr %out,<8 x i64> noundef range(i64 -4, 4) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <8 x i64> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 64
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_66(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <8 x i64>,ptr %source,align 1
 %r = tail call fastcc i64 @vector_tail_body_66(ptr %out,<8 x i64> noundef range(i64 -4, 4) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_67(ptr %out,<8 x i64> noundef range(i64 -4, 4) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <8 x i64> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 64
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_67(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <8 x i64>,ptr %source,align 1
 %r = notail call fastcc i64 @vector_tail_body_67(ptr %out,<8 x i64> noundef range(i64 -4, 4) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal i64 @vector_tail_body_68(ptr %out,<8 x i64> noundef range(i64 1, 0) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <8 x i64> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 64
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_68(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <8 x i64>,ptr %source,align 1
 %r = tail call i64 @vector_tail_body_68(ptr %out,<8 x i64> noundef range(i64 1, 0) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal i64 @vector_tail_body_69(ptr %out,<8 x i64> noundef range(i64 1, 0) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <8 x i64> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 64
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_69(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <8 x i64>,ptr %source,align 1
 %r = notail call i64 @vector_tail_body_69(ptr %out,<8 x i64> noundef range(i64 1, 0) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_70(ptr %out,<8 x i64> noundef range(i64 1, 0) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <8 x i64> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 64
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_70(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <8 x i64>,ptr %source,align 1
 %r = tail call fastcc i64 @vector_tail_body_70(ptr %out,<8 x i64> noundef range(i64 1, 0) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_71(ptr %out,<8 x i64> noundef range(i64 1, 0) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <8 x i64> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 64
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_71(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <8 x i64>,ptr %source,align 1
 %r = notail call fastcc i64 @vector_tail_body_71(ptr %out,<8 x i64> noundef range(i64 1, 0) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_72(ptr %out,<16 x i128> noundef range(i128 4, 21) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <16 x i128> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 256
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_72(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <16 x i128>,ptr %source,align 1
 %r = tail call fastcc i64 @vector_tail_body_72(ptr %out,<16 x i128> noundef range(i128 4, 21) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_73(ptr %out,<16 x i128> noundef range(i128 4, 21) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <16 x i128> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 256
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_73(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <16 x i128>,ptr %source,align 1
 %r = notail call fastcc i64 @vector_tail_body_73(ptr %out,<16 x i128> noundef range(i128 4, 21) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_74(ptr %out,<16 x i128> noundef range(i128 -5, 5) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <16 x i128> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 256
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_74(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <16 x i128>,ptr %source,align 1
 %r = tail call fastcc i64 @vector_tail_body_74(ptr %out,<16 x i128> noundef range(i128 -5, 5) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_75(ptr %out,<16 x i128> noundef range(i128 -5, 5) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <16 x i128> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 256
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_75(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <16 x i128>,ptr %source,align 1
 %r = notail call fastcc i64 @vector_tail_body_75(ptr %out,<16 x i128> noundef range(i128 -5, 5) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_76(ptr %out,<16 x i128> noundef range(i128 -4, 4) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <16 x i128> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 256
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_76(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <16 x i128>,ptr %source,align 1
 %r = tail call fastcc i64 @vector_tail_body_76(ptr %out,<16 x i128> noundef range(i128 -4, 4) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_77(ptr %out,<16 x i128> noundef range(i128 -4, 4) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <16 x i128> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 256
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_77(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <16 x i128>,ptr %source,align 1
 %r = notail call fastcc i64 @vector_tail_body_77(ptr %out,<16 x i128> noundef range(i128 -4, 4) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_78(ptr %out,<16 x i128> noundef range(i128 1, 0) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <16 x i128> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 256
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_78(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <16 x i128>,ptr %source,align 1
 %r = tail call fastcc i64 @vector_tail_body_78(ptr %out,<16 x i128> noundef range(i128 1, 0) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
define internal fastcc i64 @vector_tail_body_79(ptr %out,<16 x i128> noundef range(i128 1, 0) %input,i64 %salt) noinline {
entry:
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store <16 x i128> %input,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 256
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @vector_tail_probe_79(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load <16 x i128>,ptr %source,align 1
 %r = notail call fastcc i64 @vector_tail_body_79(ptr %out,<16 x i128> noundef range(i128 1, 0) %input,i64 %salt)
 %answer = xor i64 %r,%salt
 ret i64 %answer
}
