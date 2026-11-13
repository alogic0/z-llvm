target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare i64 @complete_clobber(i64,i64,i64,i64,i64,i64,i64,i64)
declare i1 @llvm.is.fpclass.f128(fp128,i32)
define i64 @quad_classification_probe_0(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 0)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 1)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_2(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 2)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_3(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 3)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_4(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 4)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_5(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 5)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_6(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 6)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_7(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 7)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_8(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 8)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_9(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 9)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_10(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 10)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_11(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 11)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_12(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 12)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_13(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 13)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_14(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 14)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_15(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 15)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_16(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 16)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_17(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 17)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_18(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 18)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_19(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 19)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_20(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 20)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_21(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 21)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_22(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 22)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_23(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 23)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_24(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 24)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_25(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 25)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_26(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 26)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_27(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 27)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_28(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 28)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_29(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 29)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_30(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 30)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_31(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 31)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_32(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 32)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_33(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 33)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_34(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 34)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_35(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 35)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_36(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 36)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_37(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 37)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_38(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 38)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_39(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 39)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_40(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 40)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_41(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 41)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_42(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 42)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_43(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 43)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_44(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 44)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_45(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 45)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_46(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 46)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_47(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 47)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_48(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 48)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_49(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 49)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_50(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 50)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_51(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 51)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_52(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 52)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_53(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 53)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_54(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 54)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_55(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 55)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_56(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 56)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_57(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 57)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_58(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 58)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_59(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 59)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_60(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 60)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_61(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 61)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_62(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 62)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_63(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 63)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_64(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 64)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_65(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 65)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_66(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 66)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_67(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 67)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_68(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 68)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_69(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 69)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_70(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 70)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_71(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 71)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_72(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 72)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_73(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 73)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_74(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 74)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_75(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 75)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_76(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 76)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_77(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 77)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_78(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 78)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_79(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 79)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_80(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 80)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_81(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 81)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_82(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 82)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_83(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 83)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_84(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 84)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_85(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 85)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_86(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 86)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_87(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 87)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_88(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 88)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_89(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 89)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_90(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 90)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_91(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 91)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_92(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 92)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_93(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 93)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_94(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 94)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_95(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 95)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_96(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 96)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_97(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 97)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_98(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 98)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_99(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 99)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_100(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 100)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_101(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 101)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_102(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 102)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_103(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 103)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_104(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 104)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_105(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 105)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_106(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 106)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_107(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 107)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_108(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 108)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_109(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 109)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_110(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 110)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_111(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 111)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_112(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 112)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_113(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 113)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_114(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 114)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_115(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 115)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_116(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 116)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_117(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 117)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_118(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 118)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_119(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 119)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_120(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 120)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_121(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 121)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_122(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 122)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_123(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 123)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_124(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 124)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_125(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 125)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_126(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 126)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_127(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 127)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_128(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 128)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_129(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 129)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_130(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 130)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_131(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 131)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_132(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 132)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_133(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 133)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_134(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 134)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_135(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 135)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_136(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 136)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_137(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 137)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_138(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 138)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_139(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 139)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_140(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 140)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_141(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 141)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_142(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 142)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_143(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 143)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_144(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 144)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_145(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 145)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_146(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 146)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_147(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 147)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_148(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 148)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_149(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 149)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_150(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 150)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_151(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 151)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_152(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 152)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_153(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 153)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_154(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 154)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_155(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 155)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_156(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 156)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_157(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 157)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_158(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 158)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_159(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 159)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_160(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 160)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_161(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 161)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_162(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 162)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_163(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 163)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_164(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 164)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_165(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 165)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_166(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 166)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_167(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 167)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_168(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 168)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_169(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 169)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_170(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 170)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_171(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 171)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_172(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 172)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_173(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 173)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_174(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 174)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_175(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 175)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_176(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 176)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_177(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 177)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_178(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 178)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_179(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 179)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_180(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 180)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_181(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 181)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_182(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 182)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_183(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 183)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_184(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 184)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_185(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 185)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_186(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 186)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_187(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 187)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_188(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 188)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_189(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 189)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_190(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 190)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_191(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 191)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_192(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 192)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_193(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 193)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_194(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 194)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_195(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 195)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_196(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 196)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_197(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 197)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_198(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 198)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_199(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 199)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_200(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 200)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_201(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 201)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_202(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 202)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_203(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 203)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_204(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 204)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_205(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 205)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_206(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 206)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_207(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 207)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_208(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 208)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_209(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 209)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_210(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 210)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_211(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 211)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_212(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 212)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_213(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 213)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_214(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 214)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_215(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 215)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_216(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 216)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_217(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 217)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_218(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 218)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_219(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 219)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_220(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 220)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_221(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 221)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_222(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 222)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_223(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 223)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_224(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 224)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_225(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 225)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_226(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 226)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_227(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 227)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_228(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 228)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_229(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 229)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_230(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 230)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_231(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 231)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_232(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 232)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_233(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 233)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_234(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 234)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_235(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 235)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_236(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 236)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_237(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 237)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_238(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 238)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_239(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 239)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_240(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 240)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_241(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 241)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_242(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 242)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_243(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 243)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_244(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 244)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_245(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 245)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_246(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 246)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_247(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 247)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_248(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 248)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_249(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 249)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_250(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 250)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_251(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 251)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_252(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 252)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_253(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 253)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_254(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 254)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_255(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 255)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_256(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 256)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_257(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 257)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_258(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 258)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_259(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 259)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_260(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 260)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_261(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 261)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_262(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 262)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_263(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 263)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_264(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 264)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_265(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 265)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_266(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 266)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_267(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 267)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_268(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 268)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_269(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 269)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_270(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 270)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_271(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 271)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_272(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 272)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_273(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 273)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_274(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 274)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_275(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 275)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_276(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 276)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_277(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 277)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_278(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 278)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_279(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 279)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_280(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 280)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_281(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 281)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_282(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 282)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_283(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 283)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_284(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 284)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_285(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 285)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_286(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 286)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_287(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 287)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_288(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 288)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_289(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 289)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_290(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 290)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_291(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 291)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_292(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 292)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_293(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 293)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_294(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 294)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_295(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 295)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_296(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 296)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_297(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 297)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_298(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 298)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_299(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 299)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_300(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 300)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_301(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 301)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_302(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 302)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_303(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 303)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_304(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 304)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_305(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 305)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_306(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 306)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_307(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 307)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_308(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 308)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_309(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 309)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_310(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 310)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_311(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 311)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_312(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 312)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_313(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 313)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_314(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 314)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_315(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 315)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_316(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 316)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_317(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 317)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_318(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 318)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_319(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 319)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_320(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 320)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_321(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 321)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_322(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 322)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_323(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 323)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_324(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 324)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_325(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 325)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_326(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 326)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_327(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 327)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_328(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 328)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_329(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 329)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_330(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 330)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_331(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 331)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_332(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 332)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_333(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 333)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_334(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 334)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_335(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 335)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_336(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 336)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_337(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 337)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_338(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 338)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_339(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 339)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_340(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 340)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_341(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 341)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_342(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 342)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_343(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 343)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_344(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 344)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_345(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 345)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_346(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 346)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_347(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 347)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_348(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 348)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_349(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 349)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_350(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 350)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_351(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 351)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_352(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 352)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_353(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 353)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_354(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 354)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_355(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 355)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_356(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 356)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_357(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 357)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_358(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 358)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_359(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 359)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_360(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 360)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_361(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 361)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_362(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 362)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_363(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 363)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_364(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 364)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_365(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 365)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_366(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 366)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_367(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 367)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_368(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 368)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_369(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 369)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_370(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 370)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_371(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 371)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_372(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 372)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_373(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 373)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_374(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 374)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_375(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 375)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_376(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 376)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_377(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 377)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_378(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 378)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_379(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 379)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_380(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 380)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_381(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 381)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_382(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 382)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_383(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 383)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_384(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 384)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_385(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 385)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_386(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 386)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_387(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 387)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_388(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 388)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_389(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 389)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_390(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 390)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_391(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 391)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_392(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 392)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_393(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 393)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_394(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 394)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_395(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 395)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_396(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 396)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_397(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 397)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_398(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 398)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_399(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 399)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_400(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 400)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_401(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 401)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_402(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 402)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_403(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 403)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_404(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 404)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_405(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 405)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_406(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 406)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_407(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 407)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_408(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 408)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_409(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 409)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_410(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 410)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_411(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 411)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_412(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 412)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_413(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 413)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_414(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 414)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_415(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 415)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_416(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 416)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_417(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 417)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_418(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 418)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_419(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 419)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_420(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 420)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_421(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 421)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_422(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 422)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_423(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 423)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_424(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 424)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_425(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 425)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_426(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 426)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_427(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 427)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_428(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 428)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_429(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 429)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_430(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 430)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_431(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 431)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_432(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 432)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_433(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 433)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_434(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 434)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_435(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 435)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_436(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 436)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_437(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 437)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_438(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 438)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_439(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 439)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_440(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 440)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_441(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 441)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_442(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 442)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_443(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 443)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_444(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 444)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_445(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 445)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_446(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 446)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_447(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 447)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_448(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 448)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_449(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 449)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_450(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 450)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_451(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 451)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_452(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 452)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_453(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 453)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_454(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 454)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_455(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 455)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_456(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 456)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_457(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 457)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_458(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 458)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_459(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 459)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_460(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 460)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_461(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 461)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_462(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 462)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_463(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 463)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_464(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 464)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_465(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 465)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_466(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 466)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_467(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 467)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_468(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 468)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_469(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 469)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_470(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 470)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_471(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 471)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_472(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 472)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_473(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 473)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_474(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 474)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_475(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 475)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_476(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 476)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_477(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 477)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_478(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 478)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_479(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 479)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_480(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 480)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_481(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 481)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_482(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 482)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_483(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 483)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_484(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 484)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_485(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 485)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_486(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 486)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_487(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 487)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_488(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 488)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_489(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 489)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_490(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 490)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_491(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 491)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_492(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 492)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_493(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 493)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_494(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 494)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_495(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 495)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_496(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 496)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_497(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 497)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_498(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 498)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_499(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 499)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_500(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 500)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_501(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 501)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_502(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 502)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_503(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 503)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_504(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 504)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_505(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 505)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_506(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 506)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_507(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 507)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_508(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 508)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_509(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 509)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_510(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 510)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_511(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 511)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_512(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 512)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_513(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 513)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_514(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 514)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_515(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 515)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_516(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 516)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_517(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 517)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_518(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 518)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_519(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 519)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_520(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 520)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_521(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 521)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_522(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 522)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_523(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 523)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_524(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 524)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_525(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 525)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_526(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 526)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_527(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 527)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_528(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 528)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_529(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 529)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_530(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 530)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_531(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 531)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_532(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 532)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_533(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 533)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_534(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 534)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_535(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 535)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_536(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 536)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_537(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 537)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_538(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 538)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_539(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 539)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_540(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 540)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_541(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 541)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_542(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 542)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_543(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 543)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_544(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 544)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_545(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 545)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_546(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 546)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_547(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 547)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_548(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 548)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_549(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 549)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_550(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 550)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_551(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 551)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_552(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 552)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_553(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 553)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_554(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 554)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_555(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 555)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_556(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 556)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_557(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 557)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_558(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 558)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_559(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 559)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_560(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 560)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_561(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 561)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_562(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 562)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_563(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 563)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_564(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 564)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_565(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 565)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_566(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 566)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_567(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 567)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_568(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 568)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_569(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 569)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_570(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 570)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_571(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 571)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_572(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 572)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_573(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 573)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_574(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 574)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_575(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 575)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_576(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 576)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_577(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 577)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_578(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 578)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_579(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 579)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_580(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 580)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_581(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 581)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_582(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 582)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_583(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 583)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_584(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 584)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_585(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 585)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_586(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 586)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_587(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 587)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_588(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 588)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_589(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 589)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_590(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 590)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_591(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 591)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_592(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 592)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_593(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 593)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_594(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 594)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_595(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 595)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_596(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 596)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_597(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 597)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_598(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 598)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_599(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 599)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_600(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 600)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_601(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 601)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_602(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 602)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_603(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 603)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_604(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 604)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_605(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 605)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_606(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 606)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_607(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 607)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_608(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 608)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_609(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 609)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_610(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 610)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_611(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 611)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_612(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 612)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_613(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 613)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_614(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 614)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_615(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 615)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_616(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 616)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_617(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 617)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_618(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 618)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_619(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 619)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_620(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 620)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_621(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 621)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_622(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 622)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_623(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 623)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_624(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 624)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_625(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 625)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_626(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 626)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_627(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 627)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_628(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 628)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_629(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 629)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_630(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 630)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_631(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 631)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_632(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 632)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_633(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 633)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_634(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 634)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_635(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 635)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_636(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 636)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_637(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 637)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_638(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 638)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_639(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 639)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_640(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 640)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_641(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 641)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_642(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 642)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_643(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 643)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_644(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 644)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_645(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 645)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_646(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 646)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_647(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 647)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_648(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 648)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_649(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 649)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_650(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 650)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_651(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 651)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_652(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 652)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_653(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 653)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_654(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 654)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_655(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 655)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_656(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 656)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_657(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 657)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_658(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 658)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_659(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 659)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_660(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 660)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_661(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 661)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_662(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 662)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_663(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 663)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_664(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 664)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_665(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 665)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_666(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 666)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_667(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 667)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_668(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 668)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_669(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 669)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_670(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 670)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_671(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 671)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_672(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 672)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_673(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 673)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_674(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 674)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_675(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 675)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_676(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 676)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_677(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 677)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_678(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 678)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_679(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 679)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_680(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 680)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_681(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 681)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_682(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 682)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_683(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 683)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_684(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 684)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_685(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 685)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_686(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 686)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_687(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 687)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_688(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 688)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_689(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 689)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_690(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 690)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_691(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 691)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_692(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 692)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_693(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 693)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_694(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 694)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_695(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 695)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_696(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 696)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_697(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 697)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_698(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 698)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_699(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 699)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_700(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 700)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_701(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 701)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_702(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 702)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_703(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 703)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_704(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 704)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_705(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 705)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_706(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 706)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_707(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 707)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_708(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 708)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_709(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 709)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_710(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 710)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_711(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 711)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_712(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 712)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_713(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 713)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_714(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 714)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_715(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 715)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_716(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 716)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_717(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 717)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_718(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 718)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_719(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 719)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_720(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 720)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_721(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 721)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_722(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 722)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_723(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 723)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_724(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 724)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_725(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 725)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_726(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 726)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_727(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 727)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_728(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 728)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_729(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 729)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_730(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 730)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_731(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 731)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_732(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 732)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_733(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 733)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_734(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 734)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_735(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 735)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_736(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 736)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_737(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 737)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_738(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 738)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_739(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 739)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_740(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 740)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_741(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 741)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_742(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 742)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_743(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 743)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_744(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 744)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_745(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 745)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_746(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 746)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_747(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 747)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_748(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 748)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_749(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 749)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_750(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 750)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_751(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 751)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_752(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 752)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_753(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 753)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_754(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 754)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_755(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 755)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_756(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 756)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_757(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 757)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_758(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 758)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_759(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 759)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_760(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 760)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_761(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 761)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_762(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 762)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_763(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 763)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_764(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 764)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_765(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 765)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_766(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 766)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_767(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 767)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_768(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 768)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_769(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 769)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_770(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 770)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_771(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 771)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_772(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 772)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_773(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 773)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_774(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 774)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_775(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 775)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_776(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 776)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_777(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 777)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_778(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 778)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_779(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 779)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_780(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 780)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_781(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 781)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_782(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 782)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_783(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 783)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_784(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 784)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_785(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 785)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_786(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 786)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_787(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 787)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_788(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 788)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_789(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 789)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_790(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 790)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_791(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 791)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_792(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 792)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_793(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 793)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_794(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 794)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_795(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 795)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_796(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 796)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_797(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 797)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_798(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 798)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_799(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 799)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_800(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 800)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_801(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 801)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_802(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 802)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_803(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 803)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_804(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 804)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_805(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 805)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_806(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 806)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_807(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 807)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_808(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 808)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_809(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 809)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_810(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 810)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_811(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 811)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_812(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 812)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_813(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 813)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_814(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 814)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_815(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 815)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_816(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 816)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_817(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 817)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_818(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 818)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_819(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 819)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_820(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 820)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_821(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 821)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_822(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 822)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_823(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 823)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_824(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 824)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_825(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 825)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_826(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 826)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_827(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 827)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_828(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 828)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_829(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 829)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_830(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 830)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_831(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 831)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_832(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 832)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_833(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 833)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_834(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 834)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_835(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 835)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_836(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 836)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_837(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 837)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_838(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 838)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_839(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 839)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_840(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 840)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_841(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 841)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_842(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 842)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_843(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 843)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_844(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 844)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_845(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 845)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_846(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 846)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_847(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 847)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_848(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 848)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_849(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 849)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_850(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 850)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_851(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 851)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_852(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 852)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_853(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 853)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_854(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 854)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_855(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 855)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_856(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 856)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_857(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 857)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_858(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 858)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_859(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 859)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_860(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 860)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_861(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 861)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_862(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 862)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_863(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 863)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_864(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 864)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_865(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 865)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_866(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 866)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_867(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 867)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_868(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 868)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_869(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 869)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_870(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 870)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_871(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 871)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_872(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 872)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_873(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 873)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_874(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 874)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_875(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 875)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_876(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 876)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_877(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 877)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_878(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 878)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_879(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 879)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_880(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 880)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_881(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 881)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_882(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 882)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_883(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 883)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_884(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 884)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_885(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 885)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_886(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 886)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_887(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 887)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_888(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 888)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_889(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 889)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_890(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 890)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_891(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 891)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_892(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 892)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_893(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 893)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_894(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 894)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_895(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 895)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_896(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 896)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_897(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 897)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_898(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 898)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_899(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 899)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_900(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 900)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_901(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 901)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_902(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 902)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_903(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 903)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_904(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 904)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_905(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 905)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_906(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 906)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_907(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 907)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_908(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 908)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_909(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 909)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_910(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 910)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_911(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 911)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_912(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 912)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_913(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 913)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_914(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 914)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_915(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 915)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_916(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 916)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_917(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 917)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_918(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 918)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_919(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 919)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_920(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 920)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_921(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 921)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_922(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 922)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_923(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 923)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_924(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 924)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_925(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 925)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_926(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 926)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_927(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 927)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_928(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 928)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_929(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 929)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_930(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 930)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_931(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 931)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_932(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 932)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_933(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 933)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_934(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 934)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_935(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 935)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_936(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 936)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_937(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 937)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_938(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 938)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_939(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 939)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_940(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 940)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_941(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 941)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_942(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 942)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_943(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 943)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_944(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 944)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_945(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 945)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_946(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 946)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_947(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 947)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_948(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 948)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_949(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 949)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_950(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 950)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_951(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 951)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_952(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 952)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_953(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 953)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_954(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 954)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_955(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 955)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_956(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 956)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_957(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 957)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_958(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 958)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_959(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 959)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_960(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 960)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_961(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 961)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_962(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 962)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_963(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 963)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_964(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 964)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_965(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 965)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_966(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 966)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_967(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 967)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_968(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 968)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_969(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 969)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_970(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 970)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_971(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 971)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_972(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 972)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_973(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 973)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_974(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 974)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_975(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 975)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_976(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 976)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_977(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 977)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_978(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 978)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_979(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 979)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_980(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 980)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_981(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 981)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_982(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 982)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_983(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 983)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_984(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 984)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_985(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 985)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_986(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 986)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_987(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 987)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_988(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 988)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_989(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 989)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_990(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 990)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_991(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 991)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_992(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 992)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_993(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 993)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_994(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 994)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_995(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 995)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_996(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 996)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_997(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 997)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_998(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 998)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_999(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 999)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1000(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 1000)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1001(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 1001)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1002(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 1002)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1003(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 1003)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1004(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 1004)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1005(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 1005)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1006(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 1006)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1007(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 1007)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1008(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 1008)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1009(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 1009)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1010(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 1010)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1011(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 1011)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1012(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 1012)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1013(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 1013)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1014(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 1014)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1015(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 1015)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1016(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 1016)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1017(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 1017)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1018(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 1018)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1019(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 1019)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1020(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 %value,i32 1020)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1021(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 1021)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1022(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 %value,i32 1022)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1023(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef %value,i32 1023)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1024(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 0xL00000000000000000000000000000000,i32 32)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1025(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef 0xL00000000000000008000000000000000,i32 32)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1026(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 0xL00000000000000017FFF800000000000,i32 32)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1027(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef 0xL00000000000000017FFF000000000000,i32 32)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1028(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 0xL00000000000000000000000000000000,i32 64)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1029(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef 0xL00000000000000008000000000000000,i32 64)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1030(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 0xL00000000000000017FFF800000000000,i32 64)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1031(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef 0xL00000000000000017FFF000000000000,i32 64)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1032(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 0xL00000000000000000000000000000000,i32 3)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1033(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef 0xL00000000000000008000000000000000,i32 3)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1034(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call i1 @llvm.is.fpclass.f128(fp128 0xL00000000000000017FFF800000000000,i32 3)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1035(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call noundef i1 @llvm.is.fpclass.f128(fp128 noundef 0xL00000000000000017FFF000000000000,i32 3)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1036(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call i1 @llvm.is.fpclass.f128(fp128 0xL00000000000000000000000000000000,i32 1023)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1037(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = notail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef 0xL00000000000000008000000000000000,i32 1023)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1038(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = call i1 @llvm.is.fpclass.f128(fp128 0xL00000000000000017FFF800000000000,i32 1023)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
define i64 @quad_classification_probe_1039(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %value = load fp128,ptr %source,align 1
 %r = tail call noundef i1 @llvm.is.fpclass.f128(fp128 noundef 0xL00000000000000017FFF000000000000,i32 1023)
 %flag = zext i1 %r to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %flag,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %payload_out = getelementptr i8,ptr %out,i64 16
 store fp128 %value,ptr %payload_out,align 1
 %answer = xor i64 %flag,%token
 ret i64 %answer
}
