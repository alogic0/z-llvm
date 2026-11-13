target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare i64 @complete_clobber(i64,i64,i64,i64,i64,i64,i64,i64)
declare i8 @llvm.vector.reduce.mul.v4i8(<4 x i8>)
define i64 @integer_reduction_hint_probe_0(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = load <4 x i8>,ptr %source,align 1
 %r = tail call i8 @llvm.vector.reduce.mul.v4i8(<4 x i8> %v)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 1
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_1(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = load <4 x i8>,ptr %source,align 1
 %r = notail call i8 @llvm.vector.reduce.mul.v4i8(<4 x i8> %v)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 1
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_2(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = tail call i8 @llvm.vector.reduce.mul.v4i8(<4 x i8> <i8 3,i8 5,i8 7,i8 9>)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 1
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_3(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = notail call i8 @llvm.vector.reduce.mul.v4i8(<4 x i8> <i8 3,i8 5,i8 7,i8 9>)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 1
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
declare i8 @llvm.vector.reduce.mul.v64i8(<64 x i8>)
define i64 @integer_reduction_hint_probe_4(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = load <64 x i8>,ptr %source,align 1
 %r = tail call i8 @llvm.vector.reduce.mul.v64i8(<64 x i8> %v)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 1
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_5(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = load <64 x i8>,ptr %source,align 1
 %r = notail call i8 @llvm.vector.reduce.mul.v64i8(<64 x i8> %v)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 1
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_6(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = tail call i8 @llvm.vector.reduce.mul.v64i8(<64 x i8> <i8 3,i8 5,i8 7,i8 9,i8 11,i8 13,i8 1,i8 3,i8 5,i8 7,i8 9,i8 11,i8 13,i8 1,i8 3,i8 5,i8 7,i8 9,i8 11,i8 13,i8 1,i8 3,i8 5,i8 7,i8 9,i8 11,i8 13,i8 1,i8 3,i8 5,i8 7,i8 9,i8 11,i8 13,i8 1,i8 3,i8 5,i8 7,i8 9,i8 11,i8 13,i8 1,i8 3,i8 5,i8 7,i8 9,i8 11,i8 13,i8 1,i8 3,i8 5,i8 7,i8 9,i8 11,i8 13,i8 1,i8 3,i8 5,i8 7,i8 9,i8 11,i8 13,i8 1,i8 3>)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 1
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_7(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = notail call i8 @llvm.vector.reduce.mul.v64i8(<64 x i8> <i8 3,i8 5,i8 7,i8 9,i8 11,i8 13,i8 1,i8 3,i8 5,i8 7,i8 9,i8 11,i8 13,i8 1,i8 3,i8 5,i8 7,i8 9,i8 11,i8 13,i8 1,i8 3,i8 5,i8 7,i8 9,i8 11,i8 13,i8 1,i8 3,i8 5,i8 7,i8 9,i8 11,i8 13,i8 1,i8 3,i8 5,i8 7,i8 9,i8 11,i8 13,i8 1,i8 3,i8 5,i8 7,i8 9,i8 11,i8 13,i8 1,i8 3,i8 5,i8 7,i8 9,i8 11,i8 13,i8 1,i8 3,i8 5,i8 7,i8 9,i8 11,i8 13,i8 1,i8 3>)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 1
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
declare i16 @llvm.vector.reduce.mul.v4i16(<4 x i16>)
define i64 @integer_reduction_hint_probe_8(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = load <4 x i16>,ptr %source,align 1
 %r = tail call i16 @llvm.vector.reduce.mul.v4i16(<4 x i16> %v)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 2
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_9(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = load <4 x i16>,ptr %source,align 1
 %r = notail call i16 @llvm.vector.reduce.mul.v4i16(<4 x i16> %v)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 2
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_10(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = tail call i16 @llvm.vector.reduce.mul.v4i16(<4 x i16> <i16 3,i16 5,i16 7,i16 9>)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 2
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_11(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = notail call i16 @llvm.vector.reduce.mul.v4i16(<4 x i16> <i16 3,i16 5,i16 7,i16 9>)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 2
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
declare i16 @llvm.vector.reduce.mul.v64i16(<64 x i16>)
define i64 @integer_reduction_hint_probe_12(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = load <64 x i16>,ptr %source,align 1
 %r = tail call i16 @llvm.vector.reduce.mul.v64i16(<64 x i16> %v)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 2
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_13(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = load <64 x i16>,ptr %source,align 1
 %r = notail call i16 @llvm.vector.reduce.mul.v64i16(<64 x i16> %v)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 2
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_14(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = tail call i16 @llvm.vector.reduce.mul.v64i16(<64 x i16> <i16 3,i16 5,i16 7,i16 9,i16 11,i16 13,i16 1,i16 3,i16 5,i16 7,i16 9,i16 11,i16 13,i16 1,i16 3,i16 5,i16 7,i16 9,i16 11,i16 13,i16 1,i16 3,i16 5,i16 7,i16 9,i16 11,i16 13,i16 1,i16 3,i16 5,i16 7,i16 9,i16 11,i16 13,i16 1,i16 3,i16 5,i16 7,i16 9,i16 11,i16 13,i16 1,i16 3,i16 5,i16 7,i16 9,i16 11,i16 13,i16 1,i16 3,i16 5,i16 7,i16 9,i16 11,i16 13,i16 1,i16 3,i16 5,i16 7,i16 9,i16 11,i16 13,i16 1,i16 3>)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 2
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_15(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = notail call i16 @llvm.vector.reduce.mul.v64i16(<64 x i16> <i16 3,i16 5,i16 7,i16 9,i16 11,i16 13,i16 1,i16 3,i16 5,i16 7,i16 9,i16 11,i16 13,i16 1,i16 3,i16 5,i16 7,i16 9,i16 11,i16 13,i16 1,i16 3,i16 5,i16 7,i16 9,i16 11,i16 13,i16 1,i16 3,i16 5,i16 7,i16 9,i16 11,i16 13,i16 1,i16 3,i16 5,i16 7,i16 9,i16 11,i16 13,i16 1,i16 3,i16 5,i16 7,i16 9,i16 11,i16 13,i16 1,i16 3,i16 5,i16 7,i16 9,i16 11,i16 13,i16 1,i16 3,i16 5,i16 7,i16 9,i16 11,i16 13,i16 1,i16 3>)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 2
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
declare i24 @llvm.vector.reduce.mul.v4i24(<4 x i24>)
define i64 @integer_reduction_hint_probe_16(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = load <4 x i24>,ptr %source,align 1
 %r = tail call i24 @llvm.vector.reduce.mul.v4i24(<4 x i24> %v)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i24 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 3
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_17(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = load <4 x i24>,ptr %source,align 1
 %r = notail call i24 @llvm.vector.reduce.mul.v4i24(<4 x i24> %v)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i24 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 3
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_18(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = tail call i24 @llvm.vector.reduce.mul.v4i24(<4 x i24> <i24 3,i24 5,i24 7,i24 9>)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i24 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 3
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_19(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = notail call i24 @llvm.vector.reduce.mul.v4i24(<4 x i24> <i24 3,i24 5,i24 7,i24 9>)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i24 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 3
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
declare i24 @llvm.vector.reduce.mul.v64i24(<64 x i24>)
define i64 @integer_reduction_hint_probe_20(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = load <64 x i24>,ptr %source,align 1
 %r = tail call i24 @llvm.vector.reduce.mul.v64i24(<64 x i24> %v)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i24 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 3
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_21(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = load <64 x i24>,ptr %source,align 1
 %r = notail call i24 @llvm.vector.reduce.mul.v64i24(<64 x i24> %v)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i24 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 3
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_22(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = tail call i24 @llvm.vector.reduce.mul.v64i24(<64 x i24> <i24 3,i24 5,i24 7,i24 9,i24 11,i24 13,i24 1,i24 3,i24 5,i24 7,i24 9,i24 11,i24 13,i24 1,i24 3,i24 5,i24 7,i24 9,i24 11,i24 13,i24 1,i24 3,i24 5,i24 7,i24 9,i24 11,i24 13,i24 1,i24 3,i24 5,i24 7,i24 9,i24 11,i24 13,i24 1,i24 3,i24 5,i24 7,i24 9,i24 11,i24 13,i24 1,i24 3,i24 5,i24 7,i24 9,i24 11,i24 13,i24 1,i24 3,i24 5,i24 7,i24 9,i24 11,i24 13,i24 1,i24 3,i24 5,i24 7,i24 9,i24 11,i24 13,i24 1,i24 3>)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i24 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 3
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_23(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = notail call i24 @llvm.vector.reduce.mul.v64i24(<64 x i24> <i24 3,i24 5,i24 7,i24 9,i24 11,i24 13,i24 1,i24 3,i24 5,i24 7,i24 9,i24 11,i24 13,i24 1,i24 3,i24 5,i24 7,i24 9,i24 11,i24 13,i24 1,i24 3,i24 5,i24 7,i24 9,i24 11,i24 13,i24 1,i24 3,i24 5,i24 7,i24 9,i24 11,i24 13,i24 1,i24 3,i24 5,i24 7,i24 9,i24 11,i24 13,i24 1,i24 3,i24 5,i24 7,i24 9,i24 11,i24 13,i24 1,i24 3,i24 5,i24 7,i24 9,i24 11,i24 13,i24 1,i24 3,i24 5,i24 7,i24 9,i24 11,i24 13,i24 1,i24 3>)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i24 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 3
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
declare i32 @llvm.vector.reduce.mul.v4i32(<4 x i32>)
define i64 @integer_reduction_hint_probe_24(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = load <4 x i32>,ptr %source,align 1
 %r = tail call i32 @llvm.vector.reduce.mul.v4i32(<4 x i32> %v)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 4
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_25(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = load <4 x i32>,ptr %source,align 1
 %r = notail call i32 @llvm.vector.reduce.mul.v4i32(<4 x i32> %v)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 4
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_26(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = tail call i32 @llvm.vector.reduce.mul.v4i32(<4 x i32> <i32 3,i32 5,i32 7,i32 9>)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 4
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_27(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = notail call i32 @llvm.vector.reduce.mul.v4i32(<4 x i32> <i32 3,i32 5,i32 7,i32 9>)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 4
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
declare i32 @llvm.vector.reduce.mul.v64i32(<64 x i32>)
define i64 @integer_reduction_hint_probe_28(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = load <64 x i32>,ptr %source,align 1
 %r = tail call i32 @llvm.vector.reduce.mul.v64i32(<64 x i32> %v)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 4
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_29(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = load <64 x i32>,ptr %source,align 1
 %r = notail call i32 @llvm.vector.reduce.mul.v64i32(<64 x i32> %v)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 4
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_30(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = tail call i32 @llvm.vector.reduce.mul.v64i32(<64 x i32> <i32 3,i32 5,i32 7,i32 9,i32 11,i32 13,i32 1,i32 3,i32 5,i32 7,i32 9,i32 11,i32 13,i32 1,i32 3,i32 5,i32 7,i32 9,i32 11,i32 13,i32 1,i32 3,i32 5,i32 7,i32 9,i32 11,i32 13,i32 1,i32 3,i32 5,i32 7,i32 9,i32 11,i32 13,i32 1,i32 3,i32 5,i32 7,i32 9,i32 11,i32 13,i32 1,i32 3,i32 5,i32 7,i32 9,i32 11,i32 13,i32 1,i32 3,i32 5,i32 7,i32 9,i32 11,i32 13,i32 1,i32 3,i32 5,i32 7,i32 9,i32 11,i32 13,i32 1,i32 3>)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 4
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_31(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = notail call i32 @llvm.vector.reduce.mul.v64i32(<64 x i32> <i32 3,i32 5,i32 7,i32 9,i32 11,i32 13,i32 1,i32 3,i32 5,i32 7,i32 9,i32 11,i32 13,i32 1,i32 3,i32 5,i32 7,i32 9,i32 11,i32 13,i32 1,i32 3,i32 5,i32 7,i32 9,i32 11,i32 13,i32 1,i32 3,i32 5,i32 7,i32 9,i32 11,i32 13,i32 1,i32 3,i32 5,i32 7,i32 9,i32 11,i32 13,i32 1,i32 3,i32 5,i32 7,i32 9,i32 11,i32 13,i32 1,i32 3,i32 5,i32 7,i32 9,i32 11,i32 13,i32 1,i32 3,i32 5,i32 7,i32 9,i32 11,i32 13,i32 1,i32 3>)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 4
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
declare i48 @llvm.vector.reduce.mul.v4i48(<4 x i48>)
define i64 @integer_reduction_hint_probe_32(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = load <4 x i48>,ptr %source,align 1
 %r = tail call i48 @llvm.vector.reduce.mul.v4i48(<4 x i48> %v)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i48 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 6
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_33(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = load <4 x i48>,ptr %source,align 1
 %r = notail call i48 @llvm.vector.reduce.mul.v4i48(<4 x i48> %v)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i48 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 6
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_34(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = tail call i48 @llvm.vector.reduce.mul.v4i48(<4 x i48> <i48 3,i48 5,i48 7,i48 9>)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i48 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 6
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_35(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = notail call i48 @llvm.vector.reduce.mul.v4i48(<4 x i48> <i48 3,i48 5,i48 7,i48 9>)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i48 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 6
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
declare i48 @llvm.vector.reduce.mul.v64i48(<64 x i48>)
define i64 @integer_reduction_hint_probe_36(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = load <64 x i48>,ptr %source,align 1
 %r = tail call i48 @llvm.vector.reduce.mul.v64i48(<64 x i48> %v)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i48 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 6
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_37(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = load <64 x i48>,ptr %source,align 1
 %r = notail call i48 @llvm.vector.reduce.mul.v64i48(<64 x i48> %v)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i48 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 6
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_38(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = tail call i48 @llvm.vector.reduce.mul.v64i48(<64 x i48> <i48 3,i48 5,i48 7,i48 9,i48 11,i48 13,i48 1,i48 3,i48 5,i48 7,i48 9,i48 11,i48 13,i48 1,i48 3,i48 5,i48 7,i48 9,i48 11,i48 13,i48 1,i48 3,i48 5,i48 7,i48 9,i48 11,i48 13,i48 1,i48 3,i48 5,i48 7,i48 9,i48 11,i48 13,i48 1,i48 3,i48 5,i48 7,i48 9,i48 11,i48 13,i48 1,i48 3,i48 5,i48 7,i48 9,i48 11,i48 13,i48 1,i48 3,i48 5,i48 7,i48 9,i48 11,i48 13,i48 1,i48 3,i48 5,i48 7,i48 9,i48 11,i48 13,i48 1,i48 3>)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i48 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 6
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_39(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = notail call i48 @llvm.vector.reduce.mul.v64i48(<64 x i48> <i48 3,i48 5,i48 7,i48 9,i48 11,i48 13,i48 1,i48 3,i48 5,i48 7,i48 9,i48 11,i48 13,i48 1,i48 3,i48 5,i48 7,i48 9,i48 11,i48 13,i48 1,i48 3,i48 5,i48 7,i48 9,i48 11,i48 13,i48 1,i48 3,i48 5,i48 7,i48 9,i48 11,i48 13,i48 1,i48 3,i48 5,i48 7,i48 9,i48 11,i48 13,i48 1,i48 3,i48 5,i48 7,i48 9,i48 11,i48 13,i48 1,i48 3,i48 5,i48 7,i48 9,i48 11,i48 13,i48 1,i48 3,i48 5,i48 7,i48 9,i48 11,i48 13,i48 1,i48 3>)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i48 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 6
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
declare i64 @llvm.vector.reduce.mul.v4i64(<4 x i64>)
define i64 @integer_reduction_hint_probe_40(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = load <4 x i64>,ptr %source,align 1
 %r = tail call i64 @llvm.vector.reduce.mul.v4i64(<4 x i64> %v)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_41(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = load <4 x i64>,ptr %source,align 1
 %r = notail call i64 @llvm.vector.reduce.mul.v4i64(<4 x i64> %v)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_42(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = tail call i64 @llvm.vector.reduce.mul.v4i64(<4 x i64> <i64 3,i64 5,i64 7,i64 9>)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_43(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = notail call i64 @llvm.vector.reduce.mul.v4i64(<4 x i64> <i64 3,i64 5,i64 7,i64 9>)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
declare i64 @llvm.vector.reduce.mul.v64i64(<64 x i64>)
define i64 @integer_reduction_hint_probe_44(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = load <64 x i64>,ptr %source,align 1
 %r = tail call i64 @llvm.vector.reduce.mul.v64i64(<64 x i64> %v)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_45(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = load <64 x i64>,ptr %source,align 1
 %r = notail call i64 @llvm.vector.reduce.mul.v64i64(<64 x i64> %v)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_46(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = tail call i64 @llvm.vector.reduce.mul.v64i64(<64 x i64> <i64 3,i64 5,i64 7,i64 9,i64 11,i64 13,i64 1,i64 3,i64 5,i64 7,i64 9,i64 11,i64 13,i64 1,i64 3,i64 5,i64 7,i64 9,i64 11,i64 13,i64 1,i64 3,i64 5,i64 7,i64 9,i64 11,i64 13,i64 1,i64 3,i64 5,i64 7,i64 9,i64 11,i64 13,i64 1,i64 3,i64 5,i64 7,i64 9,i64 11,i64 13,i64 1,i64 3,i64 5,i64 7,i64 9,i64 11,i64 13,i64 1,i64 3,i64 5,i64 7,i64 9,i64 11,i64 13,i64 1,i64 3,i64 5,i64 7,i64 9,i64 11,i64 13,i64 1,i64 3>)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_47(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = notail call i64 @llvm.vector.reduce.mul.v64i64(<64 x i64> <i64 3,i64 5,i64 7,i64 9,i64 11,i64 13,i64 1,i64 3,i64 5,i64 7,i64 9,i64 11,i64 13,i64 1,i64 3,i64 5,i64 7,i64 9,i64 11,i64 13,i64 1,i64 3,i64 5,i64 7,i64 9,i64 11,i64 13,i64 1,i64 3,i64 5,i64 7,i64 9,i64 11,i64 13,i64 1,i64 3,i64 5,i64 7,i64 9,i64 11,i64 13,i64 1,i64 3,i64 5,i64 7,i64 9,i64 11,i64 13,i64 1,i64 3,i64 5,i64 7,i64 9,i64 11,i64 13,i64 1,i64 3,i64 5,i64 7,i64 9,i64 11,i64 13,i64 1,i64 3>)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
declare i128 @llvm.vector.reduce.mul.v4i128(<4 x i128>)
define i64 @integer_reduction_hint_probe_48(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = load <4 x i128>,ptr %source,align 1
 %r = tail call i128 @llvm.vector.reduce.mul.v4i128(<4 x i128> %v)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_49(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = load <4 x i128>,ptr %source,align 1
 %r = notail call i128 @llvm.vector.reduce.mul.v4i128(<4 x i128> %v)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_50(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = tail call i128 @llvm.vector.reduce.mul.v4i128(<4 x i128> <i128 3,i128 5,i128 7,i128 9>)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_51(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = notail call i128 @llvm.vector.reduce.mul.v4i128(<4 x i128> <i128 3,i128 5,i128 7,i128 9>)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
declare i128 @llvm.vector.reduce.mul.v64i128(<64 x i128>)
define i64 @integer_reduction_hint_probe_52(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = load <64 x i128>,ptr %source,align 1
 %r = tail call i128 @llvm.vector.reduce.mul.v64i128(<64 x i128> %v)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_53(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = load <64 x i128>,ptr %source,align 1
 %r = notail call i128 @llvm.vector.reduce.mul.v64i128(<64 x i128> %v)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_54(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = tail call i128 @llvm.vector.reduce.mul.v64i128(<64 x i128> <i128 3,i128 5,i128 7,i128 9,i128 11,i128 13,i128 1,i128 3,i128 5,i128 7,i128 9,i128 11,i128 13,i128 1,i128 3,i128 5,i128 7,i128 9,i128 11,i128 13,i128 1,i128 3,i128 5,i128 7,i128 9,i128 11,i128 13,i128 1,i128 3,i128 5,i128 7,i128 9,i128 11,i128 13,i128 1,i128 3,i128 5,i128 7,i128 9,i128 11,i128 13,i128 1,i128 3,i128 5,i128 7,i128 9,i128 11,i128 13,i128 1,i128 3,i128 5,i128 7,i128 9,i128 11,i128 13,i128 1,i128 3,i128 5,i128 7,i128 9,i128 11,i128 13,i128 1,i128 3>)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
define i64 @integer_reduction_hint_probe_55(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %r = notail call i128 @llvm.vector.reduce.mul.v64i128(<64 x i128> <i128 3,i128 5,i128 7,i128 9,i128 11,i128 13,i128 1,i128 3,i128 5,i128 7,i128 9,i128 11,i128 13,i128 1,i128 3,i128 5,i128 7,i128 9,i128 11,i128 13,i128 1,i128 3,i128 5,i128 7,i128 9,i128 11,i128 13,i128 1,i128 3,i128 5,i128 7,i128 9,i128 11,i128 13,i128 1,i128 3,i128 5,i128 7,i128 9,i128 11,i128 13,i128 1,i128 3,i128 5,i128 7,i128 9,i128 11,i128 13,i128 1,i128 3,i128 5,i128 7,i128 9,i128 11,i128 13,i128 1,i128 3,i128 5,i128 7,i128 9,i128 11,i128 13,i128 1,i128 3>)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %r,ptr %out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 ret i64 %token
}
