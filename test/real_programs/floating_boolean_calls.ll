target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare i64 @complete_clobber(i64,i64,i64,i64,i64,i64,i64,i64)
define internal i1 @floating_boolean_body_0(half %a) noinline {
entry:
 %ordered = fcmp ord half %a,%a
 ret i1 %ordered
}
define i64 @floating_boolean_probe_0(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load half,ptr %source,align 1
 %r = call i1 @floating_boolean_body_0(half %a)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal i1 @floating_boolean_body_1(half %a) noinline {
entry:
 %ordered = fcmp ord half %a,%a
 ret i1 %ordered
}
define i64 @floating_boolean_probe_1(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load half,ptr %source,align 1
 %r = tail call i1 @floating_boolean_body_1(half %a)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal i1 @floating_boolean_body_2(half %a) noinline {
entry:
 %ordered = fcmp ord half %a,%a
 ret i1 %ordered
}
define i64 @floating_boolean_probe_2(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load half,ptr %source,align 1
 %r = notail call i1 @floating_boolean_body_2(half %a)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal i1 @floating_boolean_body_3(half %a,half %b) noinline {
entry:
 %ordered = fcmp ord half %a,%b
 ret i1 %ordered
}
define i64 @floating_boolean_probe_3(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load half,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 2
 %b = load half,ptr %next,align 1
 %r = call i1 @floating_boolean_body_3(half %a,half %b)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal i1 @floating_boolean_body_4(half %a,half %b) noinline {
entry:
 %ordered = fcmp ord half %a,%b
 ret i1 %ordered
}
define i64 @floating_boolean_probe_4(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load half,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 2
 %b = load half,ptr %next,align 1
 %r = tail call i1 @floating_boolean_body_4(half %a,half %b)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal i1 @floating_boolean_body_5(half %a,half %b) noinline {
entry:
 %ordered = fcmp ord half %a,%b
 ret i1 %ordered
}
define i64 @floating_boolean_probe_5(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load half,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 2
 %b = load half,ptr %next,align 1
 %r = notail call i1 @floating_boolean_body_5(half %a,half %b)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal fastcc i1 @floating_boolean_body_6(half %a) noinline {
entry:
 %ordered = fcmp ord half %a,%a
 ret i1 %ordered
}
define i64 @floating_boolean_probe_6(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load half,ptr %source,align 1
 %r = call fastcc i1 @floating_boolean_body_6(half %a)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal fastcc i1 @floating_boolean_body_7(half %a) noinline {
entry:
 %ordered = fcmp ord half %a,%a
 ret i1 %ordered
}
define i64 @floating_boolean_probe_7(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load half,ptr %source,align 1
 %r = tail call fastcc i1 @floating_boolean_body_7(half %a)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal fastcc i1 @floating_boolean_body_8(half %a) noinline {
entry:
 %ordered = fcmp ord half %a,%a
 ret i1 %ordered
}
define i64 @floating_boolean_probe_8(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load half,ptr %source,align 1
 %r = notail call fastcc i1 @floating_boolean_body_8(half %a)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal fastcc i1 @floating_boolean_body_9(half %a,half %b) noinline {
entry:
 %ordered = fcmp ord half %a,%b
 ret i1 %ordered
}
define i64 @floating_boolean_probe_9(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load half,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 2
 %b = load half,ptr %next,align 1
 %r = call fastcc i1 @floating_boolean_body_9(half %a,half %b)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal fastcc i1 @floating_boolean_body_10(half %a,half %b) noinline {
entry:
 %ordered = fcmp ord half %a,%b
 ret i1 %ordered
}
define i64 @floating_boolean_probe_10(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load half,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 2
 %b = load half,ptr %next,align 1
 %r = tail call fastcc i1 @floating_boolean_body_10(half %a,half %b)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal fastcc i1 @floating_boolean_body_11(half %a,half %b) noinline {
entry:
 %ordered = fcmp ord half %a,%b
 ret i1 %ordered
}
define i64 @floating_boolean_probe_11(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load half,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 2
 %b = load half,ptr %next,align 1
 %r = notail call fastcc i1 @floating_boolean_body_11(half %a,half %b)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal i1 @floating_boolean_body_12(float %a) noinline {
entry:
 %ordered = fcmp ord float %a,%a
 ret i1 %ordered
}
define i64 @floating_boolean_probe_12(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load float,ptr %source,align 1
 %r = call i1 @floating_boolean_body_12(float %a)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal i1 @floating_boolean_body_13(float %a) noinline {
entry:
 %ordered = fcmp ord float %a,%a
 ret i1 %ordered
}
define i64 @floating_boolean_probe_13(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load float,ptr %source,align 1
 %r = tail call i1 @floating_boolean_body_13(float %a)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal i1 @floating_boolean_body_14(float %a) noinline {
entry:
 %ordered = fcmp ord float %a,%a
 ret i1 %ordered
}
define i64 @floating_boolean_probe_14(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load float,ptr %source,align 1
 %r = notail call i1 @floating_boolean_body_14(float %a)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal i1 @floating_boolean_body_15(float %a,float %b) noinline {
entry:
 %ordered = fcmp ord float %a,%b
 ret i1 %ordered
}
define i64 @floating_boolean_probe_15(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load float,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 4
 %b = load float,ptr %next,align 1
 %r = call i1 @floating_boolean_body_15(float %a,float %b)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal i1 @floating_boolean_body_16(float %a,float %b) noinline {
entry:
 %ordered = fcmp ord float %a,%b
 ret i1 %ordered
}
define i64 @floating_boolean_probe_16(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load float,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 4
 %b = load float,ptr %next,align 1
 %r = tail call i1 @floating_boolean_body_16(float %a,float %b)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal i1 @floating_boolean_body_17(float %a,float %b) noinline {
entry:
 %ordered = fcmp ord float %a,%b
 ret i1 %ordered
}
define i64 @floating_boolean_probe_17(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load float,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 4
 %b = load float,ptr %next,align 1
 %r = notail call i1 @floating_boolean_body_17(float %a,float %b)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal fastcc i1 @floating_boolean_body_18(float %a) noinline {
entry:
 %ordered = fcmp ord float %a,%a
 ret i1 %ordered
}
define i64 @floating_boolean_probe_18(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load float,ptr %source,align 1
 %r = call fastcc i1 @floating_boolean_body_18(float %a)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal fastcc i1 @floating_boolean_body_19(float %a) noinline {
entry:
 %ordered = fcmp ord float %a,%a
 ret i1 %ordered
}
define i64 @floating_boolean_probe_19(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load float,ptr %source,align 1
 %r = tail call fastcc i1 @floating_boolean_body_19(float %a)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal fastcc i1 @floating_boolean_body_20(float %a) noinline {
entry:
 %ordered = fcmp ord float %a,%a
 ret i1 %ordered
}
define i64 @floating_boolean_probe_20(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load float,ptr %source,align 1
 %r = notail call fastcc i1 @floating_boolean_body_20(float %a)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal fastcc i1 @floating_boolean_body_21(float %a,float %b) noinline {
entry:
 %ordered = fcmp ord float %a,%b
 ret i1 %ordered
}
define i64 @floating_boolean_probe_21(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load float,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 4
 %b = load float,ptr %next,align 1
 %r = call fastcc i1 @floating_boolean_body_21(float %a,float %b)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal fastcc i1 @floating_boolean_body_22(float %a,float %b) noinline {
entry:
 %ordered = fcmp ord float %a,%b
 ret i1 %ordered
}
define i64 @floating_boolean_probe_22(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load float,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 4
 %b = load float,ptr %next,align 1
 %r = tail call fastcc i1 @floating_boolean_body_22(float %a,float %b)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal fastcc i1 @floating_boolean_body_23(float %a,float %b) noinline {
entry:
 %ordered = fcmp ord float %a,%b
 ret i1 %ordered
}
define i64 @floating_boolean_probe_23(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load float,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 4
 %b = load float,ptr %next,align 1
 %r = notail call fastcc i1 @floating_boolean_body_23(float %a,float %b)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal i1 @floating_boolean_body_24(double %a) noinline {
entry:
 %ordered = fcmp ord double %a,%a
 ret i1 %ordered
}
define i64 @floating_boolean_probe_24(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load double,ptr %source,align 1
 %r = call i1 @floating_boolean_body_24(double %a)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal i1 @floating_boolean_body_25(double %a) noinline {
entry:
 %ordered = fcmp ord double %a,%a
 ret i1 %ordered
}
define i64 @floating_boolean_probe_25(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load double,ptr %source,align 1
 %r = tail call i1 @floating_boolean_body_25(double %a)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal i1 @floating_boolean_body_26(double %a) noinline {
entry:
 %ordered = fcmp ord double %a,%a
 ret i1 %ordered
}
define i64 @floating_boolean_probe_26(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load double,ptr %source,align 1
 %r = notail call i1 @floating_boolean_body_26(double %a)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal i1 @floating_boolean_body_27(double %a,double %b) noinline {
entry:
 %ordered = fcmp ord double %a,%b
 ret i1 %ordered
}
define i64 @floating_boolean_probe_27(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load double,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 8
 %b = load double,ptr %next,align 1
 %r = call i1 @floating_boolean_body_27(double %a,double %b)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal i1 @floating_boolean_body_28(double %a,double %b) noinline {
entry:
 %ordered = fcmp ord double %a,%b
 ret i1 %ordered
}
define i64 @floating_boolean_probe_28(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load double,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 8
 %b = load double,ptr %next,align 1
 %r = tail call i1 @floating_boolean_body_28(double %a,double %b)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal i1 @floating_boolean_body_29(double %a,double %b) noinline {
entry:
 %ordered = fcmp ord double %a,%b
 ret i1 %ordered
}
define i64 @floating_boolean_probe_29(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load double,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 8
 %b = load double,ptr %next,align 1
 %r = notail call i1 @floating_boolean_body_29(double %a,double %b)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal fastcc i1 @floating_boolean_body_30(double %a) noinline {
entry:
 %ordered = fcmp ord double %a,%a
 ret i1 %ordered
}
define i64 @floating_boolean_probe_30(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load double,ptr %source,align 1
 %r = call fastcc i1 @floating_boolean_body_30(double %a)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal fastcc i1 @floating_boolean_body_31(double %a) noinline {
entry:
 %ordered = fcmp ord double %a,%a
 ret i1 %ordered
}
define i64 @floating_boolean_probe_31(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load double,ptr %source,align 1
 %r = tail call fastcc i1 @floating_boolean_body_31(double %a)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal fastcc i1 @floating_boolean_body_32(double %a) noinline {
entry:
 %ordered = fcmp ord double %a,%a
 ret i1 %ordered
}
define i64 @floating_boolean_probe_32(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load double,ptr %source,align 1
 %r = notail call fastcc i1 @floating_boolean_body_32(double %a)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal fastcc i1 @floating_boolean_body_33(double %a,double %b) noinline {
entry:
 %ordered = fcmp ord double %a,%b
 ret i1 %ordered
}
define i64 @floating_boolean_probe_33(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load double,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 8
 %b = load double,ptr %next,align 1
 %r = call fastcc i1 @floating_boolean_body_33(double %a,double %b)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal fastcc i1 @floating_boolean_body_34(double %a,double %b) noinline {
entry:
 %ordered = fcmp ord double %a,%b
 ret i1 %ordered
}
define i64 @floating_boolean_probe_34(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load double,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 8
 %b = load double,ptr %next,align 1
 %r = tail call fastcc i1 @floating_boolean_body_34(double %a,double %b)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal fastcc i1 @floating_boolean_body_35(double %a,double %b) noinline {
entry:
 %ordered = fcmp ord double %a,%b
 ret i1 %ordered
}
define i64 @floating_boolean_probe_35(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load double,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 8
 %b = load double,ptr %next,align 1
 %r = notail call fastcc i1 @floating_boolean_body_35(double %a,double %b)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal i1 @floating_boolean_body_36(x86_fp80 %a) noinline {
entry:
 %ordered = fcmp ord x86_fp80 %a,%a
 ret i1 %ordered
}
define i64 @floating_boolean_probe_36(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load x86_fp80,ptr %source,align 1
 %r = call i1 @floating_boolean_body_36(x86_fp80 %a)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal i1 @floating_boolean_body_37(x86_fp80 %a) noinline {
entry:
 %ordered = fcmp ord x86_fp80 %a,%a
 ret i1 %ordered
}
define i64 @floating_boolean_probe_37(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load x86_fp80,ptr %source,align 1
 %r = tail call i1 @floating_boolean_body_37(x86_fp80 %a)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal i1 @floating_boolean_body_38(x86_fp80 %a) noinline {
entry:
 %ordered = fcmp ord x86_fp80 %a,%a
 ret i1 %ordered
}
define i64 @floating_boolean_probe_38(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load x86_fp80,ptr %source,align 1
 %r = notail call i1 @floating_boolean_body_38(x86_fp80 %a)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal i1 @floating_boolean_body_39(x86_fp80 %a,x86_fp80 %b) noinline {
entry:
 %ordered = fcmp ord x86_fp80 %a,%b
 ret i1 %ordered
}
define i64 @floating_boolean_probe_39(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load x86_fp80,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 16
 %b = load x86_fp80,ptr %next,align 1
 %r = call i1 @floating_boolean_body_39(x86_fp80 %a,x86_fp80 %b)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal i1 @floating_boolean_body_40(x86_fp80 %a,x86_fp80 %b) noinline {
entry:
 %ordered = fcmp ord x86_fp80 %a,%b
 ret i1 %ordered
}
define i64 @floating_boolean_probe_40(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load x86_fp80,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 16
 %b = load x86_fp80,ptr %next,align 1
 %r = tail call i1 @floating_boolean_body_40(x86_fp80 %a,x86_fp80 %b)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal i1 @floating_boolean_body_41(x86_fp80 %a,x86_fp80 %b) noinline {
entry:
 %ordered = fcmp ord x86_fp80 %a,%b
 ret i1 %ordered
}
define i64 @floating_boolean_probe_41(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load x86_fp80,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 16
 %b = load x86_fp80,ptr %next,align 1
 %r = notail call i1 @floating_boolean_body_41(x86_fp80 %a,x86_fp80 %b)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal fastcc i1 @floating_boolean_body_42(x86_fp80 %a) noinline {
entry:
 %ordered = fcmp ord x86_fp80 %a,%a
 ret i1 %ordered
}
define i64 @floating_boolean_probe_42(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load x86_fp80,ptr %source,align 1
 %r = call fastcc i1 @floating_boolean_body_42(x86_fp80 %a)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal fastcc i1 @floating_boolean_body_43(x86_fp80 %a) noinline {
entry:
 %ordered = fcmp ord x86_fp80 %a,%a
 ret i1 %ordered
}
define i64 @floating_boolean_probe_43(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load x86_fp80,ptr %source,align 1
 %r = tail call fastcc i1 @floating_boolean_body_43(x86_fp80 %a)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal fastcc i1 @floating_boolean_body_44(x86_fp80 %a) noinline {
entry:
 %ordered = fcmp ord x86_fp80 %a,%a
 ret i1 %ordered
}
define i64 @floating_boolean_probe_44(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load x86_fp80,ptr %source,align 1
 %r = notail call fastcc i1 @floating_boolean_body_44(x86_fp80 %a)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal fastcc i1 @floating_boolean_body_45(x86_fp80 %a,x86_fp80 %b) noinline {
entry:
 %ordered = fcmp ord x86_fp80 %a,%b
 ret i1 %ordered
}
define i64 @floating_boolean_probe_45(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load x86_fp80,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 16
 %b = load x86_fp80,ptr %next,align 1
 %r = call fastcc i1 @floating_boolean_body_45(x86_fp80 %a,x86_fp80 %b)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal fastcc i1 @floating_boolean_body_46(x86_fp80 %a,x86_fp80 %b) noinline {
entry:
 %ordered = fcmp ord x86_fp80 %a,%b
 ret i1 %ordered
}
define i64 @floating_boolean_probe_46(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load x86_fp80,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 16
 %b = load x86_fp80,ptr %next,align 1
 %r = tail call fastcc i1 @floating_boolean_body_46(x86_fp80 %a,x86_fp80 %b)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal fastcc i1 @floating_boolean_body_47(x86_fp80 %a,x86_fp80 %b) noinline {
entry:
 %ordered = fcmp ord x86_fp80 %a,%b
 ret i1 %ordered
}
define i64 @floating_boolean_probe_47(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load x86_fp80,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 16
 %b = load x86_fp80,ptr %next,align 1
 %r = notail call fastcc i1 @floating_boolean_body_47(x86_fp80 %a,x86_fp80 %b)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal i1 @floating_boolean_body_48(fp128 %a) noinline {
entry:
 %ordered = fcmp ord fp128 %a,%a
 ret i1 %ordered
}
define i64 @floating_boolean_probe_48(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load fp128,ptr %source,align 1
 %r = call i1 @floating_boolean_body_48(fp128 %a)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal i1 @floating_boolean_body_49(fp128 %a) noinline {
entry:
 %ordered = fcmp ord fp128 %a,%a
 ret i1 %ordered
}
define i64 @floating_boolean_probe_49(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load fp128,ptr %source,align 1
 %r = tail call i1 @floating_boolean_body_49(fp128 %a)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal i1 @floating_boolean_body_50(fp128 %a) noinline {
entry:
 %ordered = fcmp ord fp128 %a,%a
 ret i1 %ordered
}
define i64 @floating_boolean_probe_50(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load fp128,ptr %source,align 1
 %r = notail call i1 @floating_boolean_body_50(fp128 %a)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal i1 @floating_boolean_body_51(fp128 %a,fp128 %b) noinline {
entry:
 %ordered = fcmp ord fp128 %a,%b
 ret i1 %ordered
}
define i64 @floating_boolean_probe_51(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load fp128,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 16
 %b = load fp128,ptr %next,align 1
 %r = call i1 @floating_boolean_body_51(fp128 %a,fp128 %b)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal i1 @floating_boolean_body_52(fp128 %a,fp128 %b) noinline {
entry:
 %ordered = fcmp ord fp128 %a,%b
 ret i1 %ordered
}
define i64 @floating_boolean_probe_52(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load fp128,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 16
 %b = load fp128,ptr %next,align 1
 %r = tail call i1 @floating_boolean_body_52(fp128 %a,fp128 %b)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal i1 @floating_boolean_body_53(fp128 %a,fp128 %b) noinline {
entry:
 %ordered = fcmp ord fp128 %a,%b
 ret i1 %ordered
}
define i64 @floating_boolean_probe_53(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load fp128,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 16
 %b = load fp128,ptr %next,align 1
 %r = notail call i1 @floating_boolean_body_53(fp128 %a,fp128 %b)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal fastcc i1 @floating_boolean_body_54(fp128 %a) noinline {
entry:
 %ordered = fcmp ord fp128 %a,%a
 ret i1 %ordered
}
define i64 @floating_boolean_probe_54(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load fp128,ptr %source,align 1
 %r = call fastcc i1 @floating_boolean_body_54(fp128 %a)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal fastcc i1 @floating_boolean_body_55(fp128 %a) noinline {
entry:
 %ordered = fcmp ord fp128 %a,%a
 ret i1 %ordered
}
define i64 @floating_boolean_probe_55(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load fp128,ptr %source,align 1
 %r = tail call fastcc i1 @floating_boolean_body_55(fp128 %a)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal fastcc i1 @floating_boolean_body_56(fp128 %a) noinline {
entry:
 %ordered = fcmp ord fp128 %a,%a
 ret i1 %ordered
}
define i64 @floating_boolean_probe_56(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load fp128,ptr %source,align 1
 %r = notail call fastcc i1 @floating_boolean_body_56(fp128 %a)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal fastcc i1 @floating_boolean_body_57(fp128 %a,fp128 %b) noinline {
entry:
 %ordered = fcmp ord fp128 %a,%b
 ret i1 %ordered
}
define i64 @floating_boolean_probe_57(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load fp128,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 16
 %b = load fp128,ptr %next,align 1
 %r = call fastcc i1 @floating_boolean_body_57(fp128 %a,fp128 %b)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal fastcc i1 @floating_boolean_body_58(fp128 %a,fp128 %b) noinline {
entry:
 %ordered = fcmp ord fp128 %a,%b
 ret i1 %ordered
}
define i64 @floating_boolean_probe_58(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load fp128,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 16
 %b = load fp128,ptr %next,align 1
 %r = tail call fastcc i1 @floating_boolean_body_58(fp128 %a,fp128 %b)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
define internal fastcc i1 @floating_boolean_body_59(fp128 %a,fp128 %b) noinline {
entry:
 %ordered = fcmp ord fp128 %a,%b
 ret i1 %ordered
}
define i64 @floating_boolean_probe_59(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %a = load fp128,ptr %source,align 1
 %next = getelementptr i8,ptr %source,i64 16
 %b = load fp128,ptr %next,align 1
 %r = notail call fastcc i1 @floating_boolean_body_59(fp128 %a,fp128 %b)
 %value = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %value,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %value,%token
 ret i64 %answer
}
