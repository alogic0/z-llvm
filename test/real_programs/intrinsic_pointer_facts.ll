target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare i64 @complete_clobber(i64,i64,i64,i64,i64,i64,i64,i64)
declare void @llvm.prefetch.p0(ptr,i32,i32,i32)
declare void @llvm.va_start.p0(ptr)
declare void @llvm.va_copy.p0(ptr,ptr)
declare void @llvm.va_end.p0(ptr)
attributes #7 = { nounwind }
define i64 @intrinsic_pointer_probe_0(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 call void @llvm.prefetch.p0(ptr nonnull %source,i32 0,i32 0,i32 1) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @intrinsic_pointer_probe_1(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 call void @llvm.prefetch.p0(ptr nonnull %source,i32 0,i32 1,i32 1) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @intrinsic_pointer_probe_2(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 call void @llvm.prefetch.p0(ptr nonnull %source,i32 0,i32 2,i32 1) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @intrinsic_pointer_probe_3(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 call void @llvm.prefetch.p0(ptr nonnull %source,i32 0,i32 3,i32 1) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @intrinsic_pointer_probe_4(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 call void @llvm.prefetch.p0(ptr nonnull %source,i32 1,i32 0,i32 1) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @intrinsic_pointer_probe_5(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 call void @llvm.prefetch.p0(ptr nonnull %source,i32 1,i32 1,i32 1) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @intrinsic_pointer_probe_6(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 call void @llvm.prefetch.p0(ptr nonnull %source,i32 1,i32 2,i32 1) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @intrinsic_pointer_probe_7(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 call void @llvm.prefetch.p0(ptr nonnull %source,i32 1,i32 3,i32 1) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @intrinsic_pointer_probe_8(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 call void @llvm.prefetch.p0(ptr noundef nonnull %source,i32 0,i32 0,i32 1) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @intrinsic_pointer_probe_9(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 call void @llvm.prefetch.p0(ptr noundef nonnull %source,i32 0,i32 1,i32 1) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @intrinsic_pointer_probe_10(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 call void @llvm.prefetch.p0(ptr noundef nonnull %source,i32 0,i32 2,i32 1) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @intrinsic_pointer_probe_11(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 call void @llvm.prefetch.p0(ptr noundef nonnull %source,i32 0,i32 3,i32 1) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @intrinsic_pointer_probe_12(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 call void @llvm.prefetch.p0(ptr noundef nonnull %source,i32 1,i32 0,i32 1) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @intrinsic_pointer_probe_13(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 call void @llvm.prefetch.p0(ptr noundef nonnull %source,i32 1,i32 1,i32 1) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @intrinsic_pointer_probe_14(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 call void @llvm.prefetch.p0(ptr noundef nonnull %source,i32 1,i32 2,i32 1) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @intrinsic_pointer_probe_15(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 call void @llvm.prefetch.p0(ptr noundef nonnull %source,i32 1,i32 3,i32 1) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @intrinsic_pointer_probe_16(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 call void @llvm.prefetch.p0(ptr nonnull align 8 dereferenceable(8) %source,i32 0,i32 0,i32 1) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @intrinsic_pointer_probe_17(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 call void @llvm.prefetch.p0(ptr nonnull align 8 dereferenceable(8) %source,i32 0,i32 1,i32 1) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @intrinsic_pointer_probe_18(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 call void @llvm.prefetch.p0(ptr nonnull align 8 dereferenceable(8) %source,i32 0,i32 2,i32 1) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @intrinsic_pointer_probe_19(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 call void @llvm.prefetch.p0(ptr nonnull align 8 dereferenceable(8) %source,i32 0,i32 3,i32 1) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @intrinsic_pointer_probe_20(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 call void @llvm.prefetch.p0(ptr nonnull align 8 dereferenceable(8) %source,i32 1,i32 0,i32 1) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @intrinsic_pointer_probe_21(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 call void @llvm.prefetch.p0(ptr nonnull align 8 dereferenceable(8) %source,i32 1,i32 1,i32 1) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @intrinsic_pointer_probe_22(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 call void @llvm.prefetch.p0(ptr nonnull align 8 dereferenceable(8) %source,i32 1,i32 2,i32 1) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @intrinsic_pointer_probe_23(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 call void @llvm.prefetch.p0(ptr nonnull align 8 dereferenceable(8) %source,i32 1,i32 3,i32 1) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @intrinsic_pointer_probe_24(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 call void @llvm.prefetch.p0(ptr noundef nonnull align 8 dereferenceable_or_null(8) %source,i32 0,i32 0,i32 1) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @intrinsic_pointer_probe_25(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 call void @llvm.prefetch.p0(ptr noundef nonnull align 8 dereferenceable_or_null(8) %source,i32 0,i32 1,i32 1) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @intrinsic_pointer_probe_26(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 call void @llvm.prefetch.p0(ptr noundef nonnull align 8 dereferenceable_or_null(8) %source,i32 0,i32 2,i32 1) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @intrinsic_pointer_probe_27(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 call void @llvm.prefetch.p0(ptr noundef nonnull align 8 dereferenceable_or_null(8) %source,i32 0,i32 3,i32 1) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @intrinsic_pointer_probe_28(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 call void @llvm.prefetch.p0(ptr noundef nonnull align 8 dereferenceable_or_null(8) %source,i32 1,i32 0,i32 1) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @intrinsic_pointer_probe_29(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 call void @llvm.prefetch.p0(ptr noundef nonnull align 8 dereferenceable_or_null(8) %source,i32 1,i32 1,i32 1) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @intrinsic_pointer_probe_30(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 call void @llvm.prefetch.p0(ptr noundef nonnull align 8 dereferenceable_or_null(8) %source,i32 1,i32 2,i32 1) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define i64 @intrinsic_pointer_probe_31(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 call void @llvm.prefetch.p0(ptr noundef nonnull align 8 dereferenceable_or_null(8) %source,i32 1,i32 3,i32 1) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 ret i64 %token
}
define internal i64 @intrinsic_pointer_body_32(ptr %out,i64 %salt,i32 %count,...) noinline {
entry:
 %list = alloca [24 x i8],align 16
 %copy = alloca [24 x i8],align 16
 call void @llvm.va_start.p0(ptr nonnull %list) #7
 %v0 = va_arg ptr %list,i64
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %v0,ptr %p0,align 1
 %sum0 = add i64 0,%v0
 call void @llvm.va_end.p0(ptr nonnull %list) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %answer = xor i64 %sum0,%token
 ret i64 %answer
}
define i64 @intrinsic_pointer_probe_32(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %source,i64 0
 %v0 = load i64,ptr %p0,align 1
 %answer = call i64 (ptr,i64,i32,...) @intrinsic_pointer_body_32(ptr %out,i64 %salt,i32 1,i64 %v0)
 ret i64 %answer
}
define internal i64 @intrinsic_pointer_body_33(ptr %out,i64 %salt,i32 %count,...) noinline {
entry:
 %list = alloca [24 x i8],align 16
 %copy = alloca [24 x i8],align 16
 call void @llvm.va_start.p0(ptr nonnull %list) #7
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list) #7
 %first = va_arg ptr %list,i64
 %v0 = va_arg ptr %copy,i64
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %v0,ptr %p0,align 1
 %sum0 = add i64 %first,%v0
 call void @llvm.va_end.p0(ptr nonnull %copy) #7
 call void @llvm.va_end.p0(ptr nonnull %list) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %answer = xor i64 %sum0,%token
 ret i64 %answer
}
define i64 @intrinsic_pointer_probe_33(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %source,i64 0
 %v0 = load i64,ptr %p0,align 1
 %answer = call i64 (ptr,i64,i32,...) @intrinsic_pointer_body_33(ptr %out,i64 %salt,i32 1,i64 %v0)
 ret i64 %answer
}
define internal i64 @intrinsic_pointer_body_34(ptr %out,i64 %salt,i32 %count,...) noinline {
entry:
 %list = alloca [24 x i8],align 16
 %copy = alloca [24 x i8],align 16
 call void @llvm.va_start.p0(ptr nonnull %list) #7
 %v0 = va_arg ptr %list,i64
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %v0,ptr %p0,align 1
 %sum0 = add i64 0,%v0
 %v1 = va_arg ptr %list,i64
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %v1,ptr %p1,align 1
 %sum1 = add i64 %sum0,%v1
 %v2 = va_arg ptr %list,i64
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %v2,ptr %p2,align 1
 %sum2 = add i64 %sum1,%v2
 %v3 = va_arg ptr %list,i64
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %v3,ptr %p3,align 1
 %sum3 = add i64 %sum2,%v3
 call void @llvm.va_end.p0(ptr nonnull %list) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %answer = xor i64 %sum3,%token
 ret i64 %answer
}
define i64 @intrinsic_pointer_probe_34(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %source,i64 0
 %v0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %source,i64 8
 %v1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %source,i64 16
 %v2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %source,i64 24
 %v3 = load i64,ptr %p3,align 1
 %answer = call i64 (ptr,i64,i32,...) @intrinsic_pointer_body_34(ptr %out,i64 %salt,i32 4,i64 %v0,i64 %v1,i64 %v2,i64 %v3)
 ret i64 %answer
}
define internal i64 @intrinsic_pointer_body_35(ptr %out,i64 %salt,i32 %count,...) noinline {
entry:
 %list = alloca [24 x i8],align 16
 %copy = alloca [24 x i8],align 16
 call void @llvm.va_start.p0(ptr nonnull %list) #7
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list) #7
 %first = va_arg ptr %list,i64
 %v0 = va_arg ptr %copy,i64
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %v0,ptr %p0,align 1
 %sum0 = add i64 %first,%v0
 %v1 = va_arg ptr %copy,i64
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %v1,ptr %p1,align 1
 %sum1 = add i64 %sum0,%v1
 %v2 = va_arg ptr %copy,i64
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %v2,ptr %p2,align 1
 %sum2 = add i64 %sum1,%v2
 %v3 = va_arg ptr %copy,i64
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %v3,ptr %p3,align 1
 %sum3 = add i64 %sum2,%v3
 call void @llvm.va_end.p0(ptr nonnull %copy) #7
 call void @llvm.va_end.p0(ptr nonnull %list) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %answer = xor i64 %sum3,%token
 ret i64 %answer
}
define i64 @intrinsic_pointer_probe_35(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %source,i64 0
 %v0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %source,i64 8
 %v1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %source,i64 16
 %v2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %source,i64 24
 %v3 = load i64,ptr %p3,align 1
 %answer = call i64 (ptr,i64,i32,...) @intrinsic_pointer_body_35(ptr %out,i64 %salt,i32 4,i64 %v0,i64 %v1,i64 %v2,i64 %v3)
 ret i64 %answer
}
define internal i64 @intrinsic_pointer_body_36(ptr %out,i64 %salt,i32 %count,...) noinline {
entry:
 %list = alloca [24 x i8],align 16
 %copy = alloca [24 x i8],align 16
 call void @llvm.va_start.p0(ptr nonnull %list) #7
 %v0 = va_arg ptr %list,i64
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %v0,ptr %p0,align 1
 %sum0 = add i64 0,%v0
 %v1 = va_arg ptr %list,i64
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %v1,ptr %p1,align 1
 %sum1 = add i64 %sum0,%v1
 %v2 = va_arg ptr %list,i64
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %v2,ptr %p2,align 1
 %sum2 = add i64 %sum1,%v2
 %v3 = va_arg ptr %list,i64
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %v3,ptr %p3,align 1
 %sum3 = add i64 %sum2,%v3
 %v4 = va_arg ptr %list,i64
 %p4 = getelementptr i8,ptr %out,i64 32
 store i64 %v4,ptr %p4,align 1
 %sum4 = add i64 %sum3,%v4
 call void @llvm.va_end.p0(ptr nonnull %list) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %answer = xor i64 %sum4,%token
 ret i64 %answer
}
define i64 @intrinsic_pointer_probe_36(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %source,i64 0
 %v0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %source,i64 8
 %v1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %source,i64 16
 %v2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %source,i64 24
 %v3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %source,i64 32
 %v4 = load i64,ptr %p4,align 1
 %answer = call i64 (ptr,i64,i32,...) @intrinsic_pointer_body_36(ptr %out,i64 %salt,i32 5,i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4)
 ret i64 %answer
}
define internal i64 @intrinsic_pointer_body_37(ptr %out,i64 %salt,i32 %count,...) noinline {
entry:
 %list = alloca [24 x i8],align 16
 %copy = alloca [24 x i8],align 16
 call void @llvm.va_start.p0(ptr nonnull %list) #7
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list) #7
 %first = va_arg ptr %list,i64
 %v0 = va_arg ptr %copy,i64
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %v0,ptr %p0,align 1
 %sum0 = add i64 %first,%v0
 %v1 = va_arg ptr %copy,i64
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %v1,ptr %p1,align 1
 %sum1 = add i64 %sum0,%v1
 %v2 = va_arg ptr %copy,i64
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %v2,ptr %p2,align 1
 %sum2 = add i64 %sum1,%v2
 %v3 = va_arg ptr %copy,i64
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %v3,ptr %p3,align 1
 %sum3 = add i64 %sum2,%v3
 %v4 = va_arg ptr %copy,i64
 %p4 = getelementptr i8,ptr %out,i64 32
 store i64 %v4,ptr %p4,align 1
 %sum4 = add i64 %sum3,%v4
 call void @llvm.va_end.p0(ptr nonnull %copy) #7
 call void @llvm.va_end.p0(ptr nonnull %list) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %answer = xor i64 %sum4,%token
 ret i64 %answer
}
define i64 @intrinsic_pointer_probe_37(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %source,i64 0
 %v0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %source,i64 8
 %v1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %source,i64 16
 %v2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %source,i64 24
 %v3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %source,i64 32
 %v4 = load i64,ptr %p4,align 1
 %answer = call i64 (ptr,i64,i32,...) @intrinsic_pointer_body_37(ptr %out,i64 %salt,i32 5,i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4)
 ret i64 %answer
}
define internal i64 @intrinsic_pointer_body_38(ptr %out,i64 %salt,i32 %count,...) noinline {
entry:
 %list = alloca [24 x i8],align 16
 %copy = alloca [24 x i8],align 16
 call void @llvm.va_start.p0(ptr nonnull %list) #7
 %v0 = va_arg ptr %list,i64
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %v0,ptr %p0,align 1
 %sum0 = add i64 0,%v0
 %v1 = va_arg ptr %list,i64
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %v1,ptr %p1,align 1
 %sum1 = add i64 %sum0,%v1
 %v2 = va_arg ptr %list,i64
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %v2,ptr %p2,align 1
 %sum2 = add i64 %sum1,%v2
 %v3 = va_arg ptr %list,i64
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %v3,ptr %p3,align 1
 %sum3 = add i64 %sum2,%v3
 %v4 = va_arg ptr %list,i64
 %p4 = getelementptr i8,ptr %out,i64 32
 store i64 %v4,ptr %p4,align 1
 %sum4 = add i64 %sum3,%v4
 %v5 = va_arg ptr %list,i64
 %p5 = getelementptr i8,ptr %out,i64 40
 store i64 %v5,ptr %p5,align 1
 %sum5 = add i64 %sum4,%v5
 %v6 = va_arg ptr %list,i64
 %p6 = getelementptr i8,ptr %out,i64 48
 store i64 %v6,ptr %p6,align 1
 %sum6 = add i64 %sum5,%v6
 %v7 = va_arg ptr %list,i64
 %p7 = getelementptr i8,ptr %out,i64 56
 store i64 %v7,ptr %p7,align 1
 %sum7 = add i64 %sum6,%v7
 %v8 = va_arg ptr %list,i64
 %p8 = getelementptr i8,ptr %out,i64 64
 store i64 %v8,ptr %p8,align 1
 %sum8 = add i64 %sum7,%v8
 %v9 = va_arg ptr %list,i64
 %p9 = getelementptr i8,ptr %out,i64 72
 store i64 %v9,ptr %p9,align 1
 %sum9 = add i64 %sum8,%v9
 call void @llvm.va_end.p0(ptr nonnull %list) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %answer = xor i64 %sum9,%token
 ret i64 %answer
}
define i64 @intrinsic_pointer_probe_38(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %source,i64 0
 %v0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %source,i64 8
 %v1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %source,i64 16
 %v2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %source,i64 24
 %v3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %source,i64 32
 %v4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %source,i64 40
 %v5 = load i64,ptr %p5,align 1
 %p6 = getelementptr i8,ptr %source,i64 48
 %v6 = load i64,ptr %p6,align 1
 %p7 = getelementptr i8,ptr %source,i64 56
 %v7 = load i64,ptr %p7,align 1
 %p8 = getelementptr i8,ptr %source,i64 64
 %v8 = load i64,ptr %p8,align 1
 %p9 = getelementptr i8,ptr %source,i64 72
 %v9 = load i64,ptr %p9,align 1
 %answer = call i64 (ptr,i64,i32,...) @intrinsic_pointer_body_38(ptr %out,i64 %salt,i32 10,i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,i64 %v6,i64 %v7,i64 %v8,i64 %v9)
 ret i64 %answer
}
define internal i64 @intrinsic_pointer_body_39(ptr %out,i64 %salt,i32 %count,...) noinline {
entry:
 %list = alloca [24 x i8],align 16
 %copy = alloca [24 x i8],align 16
 call void @llvm.va_start.p0(ptr nonnull %list) #7
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list) #7
 %first = va_arg ptr %list,i64
 %v0 = va_arg ptr %copy,i64
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %v0,ptr %p0,align 1
 %sum0 = add i64 %first,%v0
 %v1 = va_arg ptr %copy,i64
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %v1,ptr %p1,align 1
 %sum1 = add i64 %sum0,%v1
 %v2 = va_arg ptr %copy,i64
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %v2,ptr %p2,align 1
 %sum2 = add i64 %sum1,%v2
 %v3 = va_arg ptr %copy,i64
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %v3,ptr %p3,align 1
 %sum3 = add i64 %sum2,%v3
 %v4 = va_arg ptr %copy,i64
 %p4 = getelementptr i8,ptr %out,i64 32
 store i64 %v4,ptr %p4,align 1
 %sum4 = add i64 %sum3,%v4
 %v5 = va_arg ptr %copy,i64
 %p5 = getelementptr i8,ptr %out,i64 40
 store i64 %v5,ptr %p5,align 1
 %sum5 = add i64 %sum4,%v5
 %v6 = va_arg ptr %copy,i64
 %p6 = getelementptr i8,ptr %out,i64 48
 store i64 %v6,ptr %p6,align 1
 %sum6 = add i64 %sum5,%v6
 %v7 = va_arg ptr %copy,i64
 %p7 = getelementptr i8,ptr %out,i64 56
 store i64 %v7,ptr %p7,align 1
 %sum7 = add i64 %sum6,%v7
 %v8 = va_arg ptr %copy,i64
 %p8 = getelementptr i8,ptr %out,i64 64
 store i64 %v8,ptr %p8,align 1
 %sum8 = add i64 %sum7,%v8
 %v9 = va_arg ptr %copy,i64
 %p9 = getelementptr i8,ptr %out,i64 72
 store i64 %v9,ptr %p9,align 1
 %sum9 = add i64 %sum8,%v9
 call void @llvm.va_end.p0(ptr nonnull %copy) #7
 call void @llvm.va_end.p0(ptr nonnull %list) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %answer = xor i64 %sum9,%token
 ret i64 %answer
}
define i64 @intrinsic_pointer_probe_39(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %source,i64 0
 %v0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %source,i64 8
 %v1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %source,i64 16
 %v2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %source,i64 24
 %v3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %source,i64 32
 %v4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %source,i64 40
 %v5 = load i64,ptr %p5,align 1
 %p6 = getelementptr i8,ptr %source,i64 48
 %v6 = load i64,ptr %p6,align 1
 %p7 = getelementptr i8,ptr %source,i64 56
 %v7 = load i64,ptr %p7,align 1
 %p8 = getelementptr i8,ptr %source,i64 64
 %v8 = load i64,ptr %p8,align 1
 %p9 = getelementptr i8,ptr %source,i64 72
 %v9 = load i64,ptr %p9,align 1
 %answer = call i64 (ptr,i64,i32,...) @intrinsic_pointer_body_39(ptr %out,i64 %salt,i32 10,i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,i64 %v6,i64 %v7,i64 %v8,i64 %v9)
 ret i64 %answer
}
define internal i64 @intrinsic_pointer_body_40(ptr %out,i64 %salt,i32 %count,...) noinline {
entry:
 %list = alloca [24 x i8],align 16
 %copy = alloca [24 x i8],align 16
 call void @llvm.va_start.p0(ptr noundef nonnull %list) #7
 %v0 = va_arg ptr %list,i64
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %v0,ptr %p0,align 1
 %sum0 = add i64 0,%v0
 call void @llvm.va_end.p0(ptr noundef nonnull %list) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %answer = xor i64 %sum0,%token
 ret i64 %answer
}
define i64 @intrinsic_pointer_probe_40(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %source,i64 0
 %v0 = load i64,ptr %p0,align 1
 %answer = call i64 (ptr,i64,i32,...) @intrinsic_pointer_body_40(ptr %out,i64 %salt,i32 1,i64 %v0)
 ret i64 %answer
}
define internal i64 @intrinsic_pointer_body_41(ptr %out,i64 %salt,i32 %count,...) noinline {
entry:
 %list = alloca [24 x i8],align 16
 %copy = alloca [24 x i8],align 16
 call void @llvm.va_start.p0(ptr noundef nonnull %list) #7
 call void @llvm.va_copy.p0(ptr noundef nonnull %copy,ptr noundef nonnull %list) #7
 %first = va_arg ptr %list,i64
 %v0 = va_arg ptr %copy,i64
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %v0,ptr %p0,align 1
 %sum0 = add i64 %first,%v0
 call void @llvm.va_end.p0(ptr noundef nonnull %copy) #7
 call void @llvm.va_end.p0(ptr noundef nonnull %list) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %answer = xor i64 %sum0,%token
 ret i64 %answer
}
define i64 @intrinsic_pointer_probe_41(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %source,i64 0
 %v0 = load i64,ptr %p0,align 1
 %answer = call i64 (ptr,i64,i32,...) @intrinsic_pointer_body_41(ptr %out,i64 %salt,i32 1,i64 %v0)
 ret i64 %answer
}
define internal i64 @intrinsic_pointer_body_42(ptr %out,i64 %salt,i32 %count,...) noinline {
entry:
 %list = alloca [24 x i8],align 16
 %copy = alloca [24 x i8],align 16
 call void @llvm.va_start.p0(ptr noundef nonnull %list) #7
 %v0 = va_arg ptr %list,i64
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %v0,ptr %p0,align 1
 %sum0 = add i64 0,%v0
 %v1 = va_arg ptr %list,i64
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %v1,ptr %p1,align 1
 %sum1 = add i64 %sum0,%v1
 %v2 = va_arg ptr %list,i64
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %v2,ptr %p2,align 1
 %sum2 = add i64 %sum1,%v2
 %v3 = va_arg ptr %list,i64
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %v3,ptr %p3,align 1
 %sum3 = add i64 %sum2,%v3
 call void @llvm.va_end.p0(ptr noundef nonnull %list) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %answer = xor i64 %sum3,%token
 ret i64 %answer
}
define i64 @intrinsic_pointer_probe_42(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %source,i64 0
 %v0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %source,i64 8
 %v1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %source,i64 16
 %v2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %source,i64 24
 %v3 = load i64,ptr %p3,align 1
 %answer = call i64 (ptr,i64,i32,...) @intrinsic_pointer_body_42(ptr %out,i64 %salt,i32 4,i64 %v0,i64 %v1,i64 %v2,i64 %v3)
 ret i64 %answer
}
define internal i64 @intrinsic_pointer_body_43(ptr %out,i64 %salt,i32 %count,...) noinline {
entry:
 %list = alloca [24 x i8],align 16
 %copy = alloca [24 x i8],align 16
 call void @llvm.va_start.p0(ptr noundef nonnull %list) #7
 call void @llvm.va_copy.p0(ptr noundef nonnull %copy,ptr noundef nonnull %list) #7
 %first = va_arg ptr %list,i64
 %v0 = va_arg ptr %copy,i64
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %v0,ptr %p0,align 1
 %sum0 = add i64 %first,%v0
 %v1 = va_arg ptr %copy,i64
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %v1,ptr %p1,align 1
 %sum1 = add i64 %sum0,%v1
 %v2 = va_arg ptr %copy,i64
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %v2,ptr %p2,align 1
 %sum2 = add i64 %sum1,%v2
 %v3 = va_arg ptr %copy,i64
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %v3,ptr %p3,align 1
 %sum3 = add i64 %sum2,%v3
 call void @llvm.va_end.p0(ptr noundef nonnull %copy) #7
 call void @llvm.va_end.p0(ptr noundef nonnull %list) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %answer = xor i64 %sum3,%token
 ret i64 %answer
}
define i64 @intrinsic_pointer_probe_43(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %source,i64 0
 %v0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %source,i64 8
 %v1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %source,i64 16
 %v2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %source,i64 24
 %v3 = load i64,ptr %p3,align 1
 %answer = call i64 (ptr,i64,i32,...) @intrinsic_pointer_body_43(ptr %out,i64 %salt,i32 4,i64 %v0,i64 %v1,i64 %v2,i64 %v3)
 ret i64 %answer
}
define internal i64 @intrinsic_pointer_body_44(ptr %out,i64 %salt,i32 %count,...) noinline {
entry:
 %list = alloca [24 x i8],align 16
 %copy = alloca [24 x i8],align 16
 call void @llvm.va_start.p0(ptr noundef nonnull %list) #7
 %v0 = va_arg ptr %list,i64
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %v0,ptr %p0,align 1
 %sum0 = add i64 0,%v0
 %v1 = va_arg ptr %list,i64
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %v1,ptr %p1,align 1
 %sum1 = add i64 %sum0,%v1
 %v2 = va_arg ptr %list,i64
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %v2,ptr %p2,align 1
 %sum2 = add i64 %sum1,%v2
 %v3 = va_arg ptr %list,i64
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %v3,ptr %p3,align 1
 %sum3 = add i64 %sum2,%v3
 %v4 = va_arg ptr %list,i64
 %p4 = getelementptr i8,ptr %out,i64 32
 store i64 %v4,ptr %p4,align 1
 %sum4 = add i64 %sum3,%v4
 call void @llvm.va_end.p0(ptr noundef nonnull %list) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %answer = xor i64 %sum4,%token
 ret i64 %answer
}
define i64 @intrinsic_pointer_probe_44(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %source,i64 0
 %v0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %source,i64 8
 %v1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %source,i64 16
 %v2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %source,i64 24
 %v3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %source,i64 32
 %v4 = load i64,ptr %p4,align 1
 %answer = call i64 (ptr,i64,i32,...) @intrinsic_pointer_body_44(ptr %out,i64 %salt,i32 5,i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4)
 ret i64 %answer
}
define internal i64 @intrinsic_pointer_body_45(ptr %out,i64 %salt,i32 %count,...) noinline {
entry:
 %list = alloca [24 x i8],align 16
 %copy = alloca [24 x i8],align 16
 call void @llvm.va_start.p0(ptr noundef nonnull %list) #7
 call void @llvm.va_copy.p0(ptr noundef nonnull %copy,ptr noundef nonnull %list) #7
 %first = va_arg ptr %list,i64
 %v0 = va_arg ptr %copy,i64
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %v0,ptr %p0,align 1
 %sum0 = add i64 %first,%v0
 %v1 = va_arg ptr %copy,i64
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %v1,ptr %p1,align 1
 %sum1 = add i64 %sum0,%v1
 %v2 = va_arg ptr %copy,i64
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %v2,ptr %p2,align 1
 %sum2 = add i64 %sum1,%v2
 %v3 = va_arg ptr %copy,i64
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %v3,ptr %p3,align 1
 %sum3 = add i64 %sum2,%v3
 %v4 = va_arg ptr %copy,i64
 %p4 = getelementptr i8,ptr %out,i64 32
 store i64 %v4,ptr %p4,align 1
 %sum4 = add i64 %sum3,%v4
 call void @llvm.va_end.p0(ptr noundef nonnull %copy) #7
 call void @llvm.va_end.p0(ptr noundef nonnull %list) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %answer = xor i64 %sum4,%token
 ret i64 %answer
}
define i64 @intrinsic_pointer_probe_45(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %source,i64 0
 %v0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %source,i64 8
 %v1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %source,i64 16
 %v2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %source,i64 24
 %v3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %source,i64 32
 %v4 = load i64,ptr %p4,align 1
 %answer = call i64 (ptr,i64,i32,...) @intrinsic_pointer_body_45(ptr %out,i64 %salt,i32 5,i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4)
 ret i64 %answer
}
define internal i64 @intrinsic_pointer_body_46(ptr %out,i64 %salt,i32 %count,...) noinline {
entry:
 %list = alloca [24 x i8],align 16
 %copy = alloca [24 x i8],align 16
 call void @llvm.va_start.p0(ptr noundef nonnull %list) #7
 %v0 = va_arg ptr %list,i64
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %v0,ptr %p0,align 1
 %sum0 = add i64 0,%v0
 %v1 = va_arg ptr %list,i64
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %v1,ptr %p1,align 1
 %sum1 = add i64 %sum0,%v1
 %v2 = va_arg ptr %list,i64
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %v2,ptr %p2,align 1
 %sum2 = add i64 %sum1,%v2
 %v3 = va_arg ptr %list,i64
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %v3,ptr %p3,align 1
 %sum3 = add i64 %sum2,%v3
 %v4 = va_arg ptr %list,i64
 %p4 = getelementptr i8,ptr %out,i64 32
 store i64 %v4,ptr %p4,align 1
 %sum4 = add i64 %sum3,%v4
 %v5 = va_arg ptr %list,i64
 %p5 = getelementptr i8,ptr %out,i64 40
 store i64 %v5,ptr %p5,align 1
 %sum5 = add i64 %sum4,%v5
 %v6 = va_arg ptr %list,i64
 %p6 = getelementptr i8,ptr %out,i64 48
 store i64 %v6,ptr %p6,align 1
 %sum6 = add i64 %sum5,%v6
 %v7 = va_arg ptr %list,i64
 %p7 = getelementptr i8,ptr %out,i64 56
 store i64 %v7,ptr %p7,align 1
 %sum7 = add i64 %sum6,%v7
 %v8 = va_arg ptr %list,i64
 %p8 = getelementptr i8,ptr %out,i64 64
 store i64 %v8,ptr %p8,align 1
 %sum8 = add i64 %sum7,%v8
 %v9 = va_arg ptr %list,i64
 %p9 = getelementptr i8,ptr %out,i64 72
 store i64 %v9,ptr %p9,align 1
 %sum9 = add i64 %sum8,%v9
 call void @llvm.va_end.p0(ptr noundef nonnull %list) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %answer = xor i64 %sum9,%token
 ret i64 %answer
}
define i64 @intrinsic_pointer_probe_46(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %source,i64 0
 %v0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %source,i64 8
 %v1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %source,i64 16
 %v2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %source,i64 24
 %v3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %source,i64 32
 %v4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %source,i64 40
 %v5 = load i64,ptr %p5,align 1
 %p6 = getelementptr i8,ptr %source,i64 48
 %v6 = load i64,ptr %p6,align 1
 %p7 = getelementptr i8,ptr %source,i64 56
 %v7 = load i64,ptr %p7,align 1
 %p8 = getelementptr i8,ptr %source,i64 64
 %v8 = load i64,ptr %p8,align 1
 %p9 = getelementptr i8,ptr %source,i64 72
 %v9 = load i64,ptr %p9,align 1
 %answer = call i64 (ptr,i64,i32,...) @intrinsic_pointer_body_46(ptr %out,i64 %salt,i32 10,i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,i64 %v6,i64 %v7,i64 %v8,i64 %v9)
 ret i64 %answer
}
define internal i64 @intrinsic_pointer_body_47(ptr %out,i64 %salt,i32 %count,...) noinline {
entry:
 %list = alloca [24 x i8],align 16
 %copy = alloca [24 x i8],align 16
 call void @llvm.va_start.p0(ptr noundef nonnull %list) #7
 call void @llvm.va_copy.p0(ptr noundef nonnull %copy,ptr noundef nonnull %list) #7
 %first = va_arg ptr %list,i64
 %v0 = va_arg ptr %copy,i64
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %v0,ptr %p0,align 1
 %sum0 = add i64 %first,%v0
 %v1 = va_arg ptr %copy,i64
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %v1,ptr %p1,align 1
 %sum1 = add i64 %sum0,%v1
 %v2 = va_arg ptr %copy,i64
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %v2,ptr %p2,align 1
 %sum2 = add i64 %sum1,%v2
 %v3 = va_arg ptr %copy,i64
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %v3,ptr %p3,align 1
 %sum3 = add i64 %sum2,%v3
 %v4 = va_arg ptr %copy,i64
 %p4 = getelementptr i8,ptr %out,i64 32
 store i64 %v4,ptr %p4,align 1
 %sum4 = add i64 %sum3,%v4
 %v5 = va_arg ptr %copy,i64
 %p5 = getelementptr i8,ptr %out,i64 40
 store i64 %v5,ptr %p5,align 1
 %sum5 = add i64 %sum4,%v5
 %v6 = va_arg ptr %copy,i64
 %p6 = getelementptr i8,ptr %out,i64 48
 store i64 %v6,ptr %p6,align 1
 %sum6 = add i64 %sum5,%v6
 %v7 = va_arg ptr %copy,i64
 %p7 = getelementptr i8,ptr %out,i64 56
 store i64 %v7,ptr %p7,align 1
 %sum7 = add i64 %sum6,%v7
 %v8 = va_arg ptr %copy,i64
 %p8 = getelementptr i8,ptr %out,i64 64
 store i64 %v8,ptr %p8,align 1
 %sum8 = add i64 %sum7,%v8
 %v9 = va_arg ptr %copy,i64
 %p9 = getelementptr i8,ptr %out,i64 72
 store i64 %v9,ptr %p9,align 1
 %sum9 = add i64 %sum8,%v9
 call void @llvm.va_end.p0(ptr noundef nonnull %copy) #7
 call void @llvm.va_end.p0(ptr noundef nonnull %list) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %answer = xor i64 %sum9,%token
 ret i64 %answer
}
define i64 @intrinsic_pointer_probe_47(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %source,i64 0
 %v0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %source,i64 8
 %v1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %source,i64 16
 %v2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %source,i64 24
 %v3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %source,i64 32
 %v4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %source,i64 40
 %v5 = load i64,ptr %p5,align 1
 %p6 = getelementptr i8,ptr %source,i64 48
 %v6 = load i64,ptr %p6,align 1
 %p7 = getelementptr i8,ptr %source,i64 56
 %v7 = load i64,ptr %p7,align 1
 %p8 = getelementptr i8,ptr %source,i64 64
 %v8 = load i64,ptr %p8,align 1
 %p9 = getelementptr i8,ptr %source,i64 72
 %v9 = load i64,ptr %p9,align 1
 %answer = call i64 (ptr,i64,i32,...) @intrinsic_pointer_body_47(ptr %out,i64 %salt,i32 10,i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,i64 %v6,i64 %v7,i64 %v8,i64 %v9)
 ret i64 %answer
}
define internal i64 @intrinsic_pointer_body_48(ptr %out,i64 %salt,i32 %count,...) noinline {
entry:
 %list = alloca [24 x i8],align 16
 %copy = alloca [24 x i8],align 16
 call void @llvm.va_start.p0(ptr nonnull align 8 dereferenceable(8) %list) #7
 %v0 = va_arg ptr %list,i64
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %v0,ptr %p0,align 1
 %sum0 = add i64 0,%v0
 call void @llvm.va_end.p0(ptr nonnull align 8 dereferenceable(8) %list) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %answer = xor i64 %sum0,%token
 ret i64 %answer
}
define i64 @intrinsic_pointer_probe_48(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %source,i64 0
 %v0 = load i64,ptr %p0,align 1
 %answer = call i64 (ptr,i64,i32,...) @intrinsic_pointer_body_48(ptr %out,i64 %salt,i32 1,i64 %v0)
 ret i64 %answer
}
define internal i64 @intrinsic_pointer_body_49(ptr %out,i64 %salt,i32 %count,...) noinline {
entry:
 %list = alloca [24 x i8],align 16
 %copy = alloca [24 x i8],align 16
 call void @llvm.va_start.p0(ptr nonnull align 8 dereferenceable(8) %list) #7
 call void @llvm.va_copy.p0(ptr nonnull align 8 dereferenceable(8) %copy,ptr nonnull align 8 dereferenceable(8) %list) #7
 %first = va_arg ptr %list,i64
 %v0 = va_arg ptr %copy,i64
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %v0,ptr %p0,align 1
 %sum0 = add i64 %first,%v0
 call void @llvm.va_end.p0(ptr nonnull align 8 dereferenceable(8) %copy) #7
 call void @llvm.va_end.p0(ptr nonnull align 8 dereferenceable(8) %list) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %answer = xor i64 %sum0,%token
 ret i64 %answer
}
define i64 @intrinsic_pointer_probe_49(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %source,i64 0
 %v0 = load i64,ptr %p0,align 1
 %answer = call i64 (ptr,i64,i32,...) @intrinsic_pointer_body_49(ptr %out,i64 %salt,i32 1,i64 %v0)
 ret i64 %answer
}
define internal i64 @intrinsic_pointer_body_50(ptr %out,i64 %salt,i32 %count,...) noinline {
entry:
 %list = alloca [24 x i8],align 16
 %copy = alloca [24 x i8],align 16
 call void @llvm.va_start.p0(ptr nonnull align 8 dereferenceable(8) %list) #7
 %v0 = va_arg ptr %list,i64
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %v0,ptr %p0,align 1
 %sum0 = add i64 0,%v0
 %v1 = va_arg ptr %list,i64
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %v1,ptr %p1,align 1
 %sum1 = add i64 %sum0,%v1
 %v2 = va_arg ptr %list,i64
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %v2,ptr %p2,align 1
 %sum2 = add i64 %sum1,%v2
 %v3 = va_arg ptr %list,i64
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %v3,ptr %p3,align 1
 %sum3 = add i64 %sum2,%v3
 call void @llvm.va_end.p0(ptr nonnull align 8 dereferenceable(8) %list) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %answer = xor i64 %sum3,%token
 ret i64 %answer
}
define i64 @intrinsic_pointer_probe_50(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %source,i64 0
 %v0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %source,i64 8
 %v1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %source,i64 16
 %v2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %source,i64 24
 %v3 = load i64,ptr %p3,align 1
 %answer = call i64 (ptr,i64,i32,...) @intrinsic_pointer_body_50(ptr %out,i64 %salt,i32 4,i64 %v0,i64 %v1,i64 %v2,i64 %v3)
 ret i64 %answer
}
define internal i64 @intrinsic_pointer_body_51(ptr %out,i64 %salt,i32 %count,...) noinline {
entry:
 %list = alloca [24 x i8],align 16
 %copy = alloca [24 x i8],align 16
 call void @llvm.va_start.p0(ptr nonnull align 8 dereferenceable(8) %list) #7
 call void @llvm.va_copy.p0(ptr nonnull align 8 dereferenceable(8) %copy,ptr nonnull align 8 dereferenceable(8) %list) #7
 %first = va_arg ptr %list,i64
 %v0 = va_arg ptr %copy,i64
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %v0,ptr %p0,align 1
 %sum0 = add i64 %first,%v0
 %v1 = va_arg ptr %copy,i64
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %v1,ptr %p1,align 1
 %sum1 = add i64 %sum0,%v1
 %v2 = va_arg ptr %copy,i64
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %v2,ptr %p2,align 1
 %sum2 = add i64 %sum1,%v2
 %v3 = va_arg ptr %copy,i64
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %v3,ptr %p3,align 1
 %sum3 = add i64 %sum2,%v3
 call void @llvm.va_end.p0(ptr nonnull align 8 dereferenceable(8) %copy) #7
 call void @llvm.va_end.p0(ptr nonnull align 8 dereferenceable(8) %list) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %answer = xor i64 %sum3,%token
 ret i64 %answer
}
define i64 @intrinsic_pointer_probe_51(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %source,i64 0
 %v0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %source,i64 8
 %v1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %source,i64 16
 %v2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %source,i64 24
 %v3 = load i64,ptr %p3,align 1
 %answer = call i64 (ptr,i64,i32,...) @intrinsic_pointer_body_51(ptr %out,i64 %salt,i32 4,i64 %v0,i64 %v1,i64 %v2,i64 %v3)
 ret i64 %answer
}
define internal i64 @intrinsic_pointer_body_52(ptr %out,i64 %salt,i32 %count,...) noinline {
entry:
 %list = alloca [24 x i8],align 16
 %copy = alloca [24 x i8],align 16
 call void @llvm.va_start.p0(ptr nonnull align 8 dereferenceable(8) %list) #7
 %v0 = va_arg ptr %list,i64
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %v0,ptr %p0,align 1
 %sum0 = add i64 0,%v0
 %v1 = va_arg ptr %list,i64
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %v1,ptr %p1,align 1
 %sum1 = add i64 %sum0,%v1
 %v2 = va_arg ptr %list,i64
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %v2,ptr %p2,align 1
 %sum2 = add i64 %sum1,%v2
 %v3 = va_arg ptr %list,i64
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %v3,ptr %p3,align 1
 %sum3 = add i64 %sum2,%v3
 %v4 = va_arg ptr %list,i64
 %p4 = getelementptr i8,ptr %out,i64 32
 store i64 %v4,ptr %p4,align 1
 %sum4 = add i64 %sum3,%v4
 call void @llvm.va_end.p0(ptr nonnull align 8 dereferenceable(8) %list) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %answer = xor i64 %sum4,%token
 ret i64 %answer
}
define i64 @intrinsic_pointer_probe_52(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %source,i64 0
 %v0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %source,i64 8
 %v1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %source,i64 16
 %v2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %source,i64 24
 %v3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %source,i64 32
 %v4 = load i64,ptr %p4,align 1
 %answer = call i64 (ptr,i64,i32,...) @intrinsic_pointer_body_52(ptr %out,i64 %salt,i32 5,i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4)
 ret i64 %answer
}
define internal i64 @intrinsic_pointer_body_53(ptr %out,i64 %salt,i32 %count,...) noinline {
entry:
 %list = alloca [24 x i8],align 16
 %copy = alloca [24 x i8],align 16
 call void @llvm.va_start.p0(ptr nonnull align 8 dereferenceable(8) %list) #7
 call void @llvm.va_copy.p0(ptr nonnull align 8 dereferenceable(8) %copy,ptr nonnull align 8 dereferenceable(8) %list) #7
 %first = va_arg ptr %list,i64
 %v0 = va_arg ptr %copy,i64
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %v0,ptr %p0,align 1
 %sum0 = add i64 %first,%v0
 %v1 = va_arg ptr %copy,i64
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %v1,ptr %p1,align 1
 %sum1 = add i64 %sum0,%v1
 %v2 = va_arg ptr %copy,i64
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %v2,ptr %p2,align 1
 %sum2 = add i64 %sum1,%v2
 %v3 = va_arg ptr %copy,i64
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %v3,ptr %p3,align 1
 %sum3 = add i64 %sum2,%v3
 %v4 = va_arg ptr %copy,i64
 %p4 = getelementptr i8,ptr %out,i64 32
 store i64 %v4,ptr %p4,align 1
 %sum4 = add i64 %sum3,%v4
 call void @llvm.va_end.p0(ptr nonnull align 8 dereferenceable(8) %copy) #7
 call void @llvm.va_end.p0(ptr nonnull align 8 dereferenceable(8) %list) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %answer = xor i64 %sum4,%token
 ret i64 %answer
}
define i64 @intrinsic_pointer_probe_53(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %source,i64 0
 %v0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %source,i64 8
 %v1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %source,i64 16
 %v2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %source,i64 24
 %v3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %source,i64 32
 %v4 = load i64,ptr %p4,align 1
 %answer = call i64 (ptr,i64,i32,...) @intrinsic_pointer_body_53(ptr %out,i64 %salt,i32 5,i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4)
 ret i64 %answer
}
define internal i64 @intrinsic_pointer_body_54(ptr %out,i64 %salt,i32 %count,...) noinline {
entry:
 %list = alloca [24 x i8],align 16
 %copy = alloca [24 x i8],align 16
 call void @llvm.va_start.p0(ptr nonnull align 8 dereferenceable(8) %list) #7
 %v0 = va_arg ptr %list,i64
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %v0,ptr %p0,align 1
 %sum0 = add i64 0,%v0
 %v1 = va_arg ptr %list,i64
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %v1,ptr %p1,align 1
 %sum1 = add i64 %sum0,%v1
 %v2 = va_arg ptr %list,i64
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %v2,ptr %p2,align 1
 %sum2 = add i64 %sum1,%v2
 %v3 = va_arg ptr %list,i64
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %v3,ptr %p3,align 1
 %sum3 = add i64 %sum2,%v3
 %v4 = va_arg ptr %list,i64
 %p4 = getelementptr i8,ptr %out,i64 32
 store i64 %v4,ptr %p4,align 1
 %sum4 = add i64 %sum3,%v4
 %v5 = va_arg ptr %list,i64
 %p5 = getelementptr i8,ptr %out,i64 40
 store i64 %v5,ptr %p5,align 1
 %sum5 = add i64 %sum4,%v5
 %v6 = va_arg ptr %list,i64
 %p6 = getelementptr i8,ptr %out,i64 48
 store i64 %v6,ptr %p6,align 1
 %sum6 = add i64 %sum5,%v6
 %v7 = va_arg ptr %list,i64
 %p7 = getelementptr i8,ptr %out,i64 56
 store i64 %v7,ptr %p7,align 1
 %sum7 = add i64 %sum6,%v7
 %v8 = va_arg ptr %list,i64
 %p8 = getelementptr i8,ptr %out,i64 64
 store i64 %v8,ptr %p8,align 1
 %sum8 = add i64 %sum7,%v8
 %v9 = va_arg ptr %list,i64
 %p9 = getelementptr i8,ptr %out,i64 72
 store i64 %v9,ptr %p9,align 1
 %sum9 = add i64 %sum8,%v9
 call void @llvm.va_end.p0(ptr nonnull align 8 dereferenceable(8) %list) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %answer = xor i64 %sum9,%token
 ret i64 %answer
}
define i64 @intrinsic_pointer_probe_54(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %source,i64 0
 %v0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %source,i64 8
 %v1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %source,i64 16
 %v2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %source,i64 24
 %v3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %source,i64 32
 %v4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %source,i64 40
 %v5 = load i64,ptr %p5,align 1
 %p6 = getelementptr i8,ptr %source,i64 48
 %v6 = load i64,ptr %p6,align 1
 %p7 = getelementptr i8,ptr %source,i64 56
 %v7 = load i64,ptr %p7,align 1
 %p8 = getelementptr i8,ptr %source,i64 64
 %v8 = load i64,ptr %p8,align 1
 %p9 = getelementptr i8,ptr %source,i64 72
 %v9 = load i64,ptr %p9,align 1
 %answer = call i64 (ptr,i64,i32,...) @intrinsic_pointer_body_54(ptr %out,i64 %salt,i32 10,i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,i64 %v6,i64 %v7,i64 %v8,i64 %v9)
 ret i64 %answer
}
define internal i64 @intrinsic_pointer_body_55(ptr %out,i64 %salt,i32 %count,...) noinline {
entry:
 %list = alloca [24 x i8],align 16
 %copy = alloca [24 x i8],align 16
 call void @llvm.va_start.p0(ptr nonnull align 8 dereferenceable(8) %list) #7
 call void @llvm.va_copy.p0(ptr nonnull align 8 dereferenceable(8) %copy,ptr nonnull align 8 dereferenceable(8) %list) #7
 %first = va_arg ptr %list,i64
 %v0 = va_arg ptr %copy,i64
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %v0,ptr %p0,align 1
 %sum0 = add i64 %first,%v0
 %v1 = va_arg ptr %copy,i64
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %v1,ptr %p1,align 1
 %sum1 = add i64 %sum0,%v1
 %v2 = va_arg ptr %copy,i64
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %v2,ptr %p2,align 1
 %sum2 = add i64 %sum1,%v2
 %v3 = va_arg ptr %copy,i64
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %v3,ptr %p3,align 1
 %sum3 = add i64 %sum2,%v3
 %v4 = va_arg ptr %copy,i64
 %p4 = getelementptr i8,ptr %out,i64 32
 store i64 %v4,ptr %p4,align 1
 %sum4 = add i64 %sum3,%v4
 %v5 = va_arg ptr %copy,i64
 %p5 = getelementptr i8,ptr %out,i64 40
 store i64 %v5,ptr %p5,align 1
 %sum5 = add i64 %sum4,%v5
 %v6 = va_arg ptr %copy,i64
 %p6 = getelementptr i8,ptr %out,i64 48
 store i64 %v6,ptr %p6,align 1
 %sum6 = add i64 %sum5,%v6
 %v7 = va_arg ptr %copy,i64
 %p7 = getelementptr i8,ptr %out,i64 56
 store i64 %v7,ptr %p7,align 1
 %sum7 = add i64 %sum6,%v7
 %v8 = va_arg ptr %copy,i64
 %p8 = getelementptr i8,ptr %out,i64 64
 store i64 %v8,ptr %p8,align 1
 %sum8 = add i64 %sum7,%v8
 %v9 = va_arg ptr %copy,i64
 %p9 = getelementptr i8,ptr %out,i64 72
 store i64 %v9,ptr %p9,align 1
 %sum9 = add i64 %sum8,%v9
 call void @llvm.va_end.p0(ptr nonnull align 8 dereferenceable(8) %copy) #7
 call void @llvm.va_end.p0(ptr nonnull align 8 dereferenceable(8) %list) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %answer = xor i64 %sum9,%token
 ret i64 %answer
}
define i64 @intrinsic_pointer_probe_55(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %source,i64 0
 %v0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %source,i64 8
 %v1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %source,i64 16
 %v2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %source,i64 24
 %v3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %source,i64 32
 %v4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %source,i64 40
 %v5 = load i64,ptr %p5,align 1
 %p6 = getelementptr i8,ptr %source,i64 48
 %v6 = load i64,ptr %p6,align 1
 %p7 = getelementptr i8,ptr %source,i64 56
 %v7 = load i64,ptr %p7,align 1
 %p8 = getelementptr i8,ptr %source,i64 64
 %v8 = load i64,ptr %p8,align 1
 %p9 = getelementptr i8,ptr %source,i64 72
 %v9 = load i64,ptr %p9,align 1
 %answer = call i64 (ptr,i64,i32,...) @intrinsic_pointer_body_55(ptr %out,i64 %salt,i32 10,i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,i64 %v6,i64 %v7,i64 %v8,i64 %v9)
 ret i64 %answer
}
define internal i64 @intrinsic_pointer_body_56(ptr %out,i64 %salt,i32 %count,...) noinline {
entry:
 %list = alloca [24 x i8],align 16
 %copy = alloca [24 x i8],align 16
 call void @llvm.va_start.p0(ptr noundef nonnull align 8 dereferenceable_or_null(8) %list) #7
 %v0 = va_arg ptr %list,i64
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %v0,ptr %p0,align 1
 %sum0 = add i64 0,%v0
 call void @llvm.va_end.p0(ptr noundef nonnull align 8 dereferenceable_or_null(8) %list) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %answer = xor i64 %sum0,%token
 ret i64 %answer
}
define i64 @intrinsic_pointer_probe_56(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %source,i64 0
 %v0 = load i64,ptr %p0,align 1
 %answer = call i64 (ptr,i64,i32,...) @intrinsic_pointer_body_56(ptr %out,i64 %salt,i32 1,i64 %v0)
 ret i64 %answer
}
define internal i64 @intrinsic_pointer_body_57(ptr %out,i64 %salt,i32 %count,...) noinline {
entry:
 %list = alloca [24 x i8],align 16
 %copy = alloca [24 x i8],align 16
 call void @llvm.va_start.p0(ptr noundef nonnull align 8 dereferenceable_or_null(8) %list) #7
 call void @llvm.va_copy.p0(ptr noundef nonnull align 8 dereferenceable_or_null(8) %copy,ptr noundef nonnull align 8 dereferenceable_or_null(8) %list) #7
 %first = va_arg ptr %list,i64
 %v0 = va_arg ptr %copy,i64
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %v0,ptr %p0,align 1
 %sum0 = add i64 %first,%v0
 call void @llvm.va_end.p0(ptr noundef nonnull align 8 dereferenceable_or_null(8) %copy) #7
 call void @llvm.va_end.p0(ptr noundef nonnull align 8 dereferenceable_or_null(8) %list) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %answer = xor i64 %sum0,%token
 ret i64 %answer
}
define i64 @intrinsic_pointer_probe_57(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %source,i64 0
 %v0 = load i64,ptr %p0,align 1
 %answer = call i64 (ptr,i64,i32,...) @intrinsic_pointer_body_57(ptr %out,i64 %salt,i32 1,i64 %v0)
 ret i64 %answer
}
define internal i64 @intrinsic_pointer_body_58(ptr %out,i64 %salt,i32 %count,...) noinline {
entry:
 %list = alloca [24 x i8],align 16
 %copy = alloca [24 x i8],align 16
 call void @llvm.va_start.p0(ptr noundef nonnull align 8 dereferenceable_or_null(8) %list) #7
 %v0 = va_arg ptr %list,i64
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %v0,ptr %p0,align 1
 %sum0 = add i64 0,%v0
 %v1 = va_arg ptr %list,i64
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %v1,ptr %p1,align 1
 %sum1 = add i64 %sum0,%v1
 %v2 = va_arg ptr %list,i64
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %v2,ptr %p2,align 1
 %sum2 = add i64 %sum1,%v2
 %v3 = va_arg ptr %list,i64
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %v3,ptr %p3,align 1
 %sum3 = add i64 %sum2,%v3
 call void @llvm.va_end.p0(ptr noundef nonnull align 8 dereferenceable_or_null(8) %list) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %answer = xor i64 %sum3,%token
 ret i64 %answer
}
define i64 @intrinsic_pointer_probe_58(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %source,i64 0
 %v0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %source,i64 8
 %v1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %source,i64 16
 %v2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %source,i64 24
 %v3 = load i64,ptr %p3,align 1
 %answer = call i64 (ptr,i64,i32,...) @intrinsic_pointer_body_58(ptr %out,i64 %salt,i32 4,i64 %v0,i64 %v1,i64 %v2,i64 %v3)
 ret i64 %answer
}
define internal i64 @intrinsic_pointer_body_59(ptr %out,i64 %salt,i32 %count,...) noinline {
entry:
 %list = alloca [24 x i8],align 16
 %copy = alloca [24 x i8],align 16
 call void @llvm.va_start.p0(ptr noundef nonnull align 8 dereferenceable_or_null(8) %list) #7
 call void @llvm.va_copy.p0(ptr noundef nonnull align 8 dereferenceable_or_null(8) %copy,ptr noundef nonnull align 8 dereferenceable_or_null(8) %list) #7
 %first = va_arg ptr %list,i64
 %v0 = va_arg ptr %copy,i64
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %v0,ptr %p0,align 1
 %sum0 = add i64 %first,%v0
 %v1 = va_arg ptr %copy,i64
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %v1,ptr %p1,align 1
 %sum1 = add i64 %sum0,%v1
 %v2 = va_arg ptr %copy,i64
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %v2,ptr %p2,align 1
 %sum2 = add i64 %sum1,%v2
 %v3 = va_arg ptr %copy,i64
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %v3,ptr %p3,align 1
 %sum3 = add i64 %sum2,%v3
 call void @llvm.va_end.p0(ptr noundef nonnull align 8 dereferenceable_or_null(8) %copy) #7
 call void @llvm.va_end.p0(ptr noundef nonnull align 8 dereferenceable_or_null(8) %list) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %answer = xor i64 %sum3,%token
 ret i64 %answer
}
define i64 @intrinsic_pointer_probe_59(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %source,i64 0
 %v0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %source,i64 8
 %v1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %source,i64 16
 %v2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %source,i64 24
 %v3 = load i64,ptr %p3,align 1
 %answer = call i64 (ptr,i64,i32,...) @intrinsic_pointer_body_59(ptr %out,i64 %salt,i32 4,i64 %v0,i64 %v1,i64 %v2,i64 %v3)
 ret i64 %answer
}
define internal i64 @intrinsic_pointer_body_60(ptr %out,i64 %salt,i32 %count,...) noinline {
entry:
 %list = alloca [24 x i8],align 16
 %copy = alloca [24 x i8],align 16
 call void @llvm.va_start.p0(ptr noundef nonnull align 8 dereferenceable_or_null(8) %list) #7
 %v0 = va_arg ptr %list,i64
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %v0,ptr %p0,align 1
 %sum0 = add i64 0,%v0
 %v1 = va_arg ptr %list,i64
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %v1,ptr %p1,align 1
 %sum1 = add i64 %sum0,%v1
 %v2 = va_arg ptr %list,i64
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %v2,ptr %p2,align 1
 %sum2 = add i64 %sum1,%v2
 %v3 = va_arg ptr %list,i64
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %v3,ptr %p3,align 1
 %sum3 = add i64 %sum2,%v3
 %v4 = va_arg ptr %list,i64
 %p4 = getelementptr i8,ptr %out,i64 32
 store i64 %v4,ptr %p4,align 1
 %sum4 = add i64 %sum3,%v4
 call void @llvm.va_end.p0(ptr noundef nonnull align 8 dereferenceable_or_null(8) %list) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %answer = xor i64 %sum4,%token
 ret i64 %answer
}
define i64 @intrinsic_pointer_probe_60(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %source,i64 0
 %v0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %source,i64 8
 %v1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %source,i64 16
 %v2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %source,i64 24
 %v3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %source,i64 32
 %v4 = load i64,ptr %p4,align 1
 %answer = call i64 (ptr,i64,i32,...) @intrinsic_pointer_body_60(ptr %out,i64 %salt,i32 5,i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4)
 ret i64 %answer
}
define internal i64 @intrinsic_pointer_body_61(ptr %out,i64 %salt,i32 %count,...) noinline {
entry:
 %list = alloca [24 x i8],align 16
 %copy = alloca [24 x i8],align 16
 call void @llvm.va_start.p0(ptr noundef nonnull align 8 dereferenceable_or_null(8) %list) #7
 call void @llvm.va_copy.p0(ptr noundef nonnull align 8 dereferenceable_or_null(8) %copy,ptr noundef nonnull align 8 dereferenceable_or_null(8) %list) #7
 %first = va_arg ptr %list,i64
 %v0 = va_arg ptr %copy,i64
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %v0,ptr %p0,align 1
 %sum0 = add i64 %first,%v0
 %v1 = va_arg ptr %copy,i64
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %v1,ptr %p1,align 1
 %sum1 = add i64 %sum0,%v1
 %v2 = va_arg ptr %copy,i64
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %v2,ptr %p2,align 1
 %sum2 = add i64 %sum1,%v2
 %v3 = va_arg ptr %copy,i64
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %v3,ptr %p3,align 1
 %sum3 = add i64 %sum2,%v3
 %v4 = va_arg ptr %copy,i64
 %p4 = getelementptr i8,ptr %out,i64 32
 store i64 %v4,ptr %p4,align 1
 %sum4 = add i64 %sum3,%v4
 call void @llvm.va_end.p0(ptr noundef nonnull align 8 dereferenceable_or_null(8) %copy) #7
 call void @llvm.va_end.p0(ptr noundef nonnull align 8 dereferenceable_or_null(8) %list) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %answer = xor i64 %sum4,%token
 ret i64 %answer
}
define i64 @intrinsic_pointer_probe_61(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %source,i64 0
 %v0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %source,i64 8
 %v1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %source,i64 16
 %v2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %source,i64 24
 %v3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %source,i64 32
 %v4 = load i64,ptr %p4,align 1
 %answer = call i64 (ptr,i64,i32,...) @intrinsic_pointer_body_61(ptr %out,i64 %salt,i32 5,i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4)
 ret i64 %answer
}
define internal i64 @intrinsic_pointer_body_62(ptr %out,i64 %salt,i32 %count,...) noinline {
entry:
 %list = alloca [24 x i8],align 16
 %copy = alloca [24 x i8],align 16
 call void @llvm.va_start.p0(ptr noundef nonnull align 8 dereferenceable_or_null(8) %list) #7
 %v0 = va_arg ptr %list,i64
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %v0,ptr %p0,align 1
 %sum0 = add i64 0,%v0
 %v1 = va_arg ptr %list,i64
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %v1,ptr %p1,align 1
 %sum1 = add i64 %sum0,%v1
 %v2 = va_arg ptr %list,i64
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %v2,ptr %p2,align 1
 %sum2 = add i64 %sum1,%v2
 %v3 = va_arg ptr %list,i64
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %v3,ptr %p3,align 1
 %sum3 = add i64 %sum2,%v3
 %v4 = va_arg ptr %list,i64
 %p4 = getelementptr i8,ptr %out,i64 32
 store i64 %v4,ptr %p4,align 1
 %sum4 = add i64 %sum3,%v4
 %v5 = va_arg ptr %list,i64
 %p5 = getelementptr i8,ptr %out,i64 40
 store i64 %v5,ptr %p5,align 1
 %sum5 = add i64 %sum4,%v5
 %v6 = va_arg ptr %list,i64
 %p6 = getelementptr i8,ptr %out,i64 48
 store i64 %v6,ptr %p6,align 1
 %sum6 = add i64 %sum5,%v6
 %v7 = va_arg ptr %list,i64
 %p7 = getelementptr i8,ptr %out,i64 56
 store i64 %v7,ptr %p7,align 1
 %sum7 = add i64 %sum6,%v7
 %v8 = va_arg ptr %list,i64
 %p8 = getelementptr i8,ptr %out,i64 64
 store i64 %v8,ptr %p8,align 1
 %sum8 = add i64 %sum7,%v8
 %v9 = va_arg ptr %list,i64
 %p9 = getelementptr i8,ptr %out,i64 72
 store i64 %v9,ptr %p9,align 1
 %sum9 = add i64 %sum8,%v9
 call void @llvm.va_end.p0(ptr noundef nonnull align 8 dereferenceable_or_null(8) %list) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %answer = xor i64 %sum9,%token
 ret i64 %answer
}
define i64 @intrinsic_pointer_probe_62(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %source,i64 0
 %v0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %source,i64 8
 %v1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %source,i64 16
 %v2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %source,i64 24
 %v3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %source,i64 32
 %v4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %source,i64 40
 %v5 = load i64,ptr %p5,align 1
 %p6 = getelementptr i8,ptr %source,i64 48
 %v6 = load i64,ptr %p6,align 1
 %p7 = getelementptr i8,ptr %source,i64 56
 %v7 = load i64,ptr %p7,align 1
 %p8 = getelementptr i8,ptr %source,i64 64
 %v8 = load i64,ptr %p8,align 1
 %p9 = getelementptr i8,ptr %source,i64 72
 %v9 = load i64,ptr %p9,align 1
 %answer = call i64 (ptr,i64,i32,...) @intrinsic_pointer_body_62(ptr %out,i64 %salt,i32 10,i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,i64 %v6,i64 %v7,i64 %v8,i64 %v9)
 ret i64 %answer
}
define internal i64 @intrinsic_pointer_body_63(ptr %out,i64 %salt,i32 %count,...) noinline {
entry:
 %list = alloca [24 x i8],align 16
 %copy = alloca [24 x i8],align 16
 call void @llvm.va_start.p0(ptr noundef nonnull align 8 dereferenceable_or_null(8) %list) #7
 call void @llvm.va_copy.p0(ptr noundef nonnull align 8 dereferenceable_or_null(8) %copy,ptr noundef nonnull align 8 dereferenceable_or_null(8) %list) #7
 %first = va_arg ptr %list,i64
 %v0 = va_arg ptr %copy,i64
 %p0 = getelementptr i8,ptr %out,i64 0
 store i64 %v0,ptr %p0,align 1
 %sum0 = add i64 %first,%v0
 %v1 = va_arg ptr %copy,i64
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %v1,ptr %p1,align 1
 %sum1 = add i64 %sum0,%v1
 %v2 = va_arg ptr %copy,i64
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %v2,ptr %p2,align 1
 %sum2 = add i64 %sum1,%v2
 %v3 = va_arg ptr %copy,i64
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %v3,ptr %p3,align 1
 %sum3 = add i64 %sum2,%v3
 %v4 = va_arg ptr %copy,i64
 %p4 = getelementptr i8,ptr %out,i64 32
 store i64 %v4,ptr %p4,align 1
 %sum4 = add i64 %sum3,%v4
 %v5 = va_arg ptr %copy,i64
 %p5 = getelementptr i8,ptr %out,i64 40
 store i64 %v5,ptr %p5,align 1
 %sum5 = add i64 %sum4,%v5
 %v6 = va_arg ptr %copy,i64
 %p6 = getelementptr i8,ptr %out,i64 48
 store i64 %v6,ptr %p6,align 1
 %sum6 = add i64 %sum5,%v6
 %v7 = va_arg ptr %copy,i64
 %p7 = getelementptr i8,ptr %out,i64 56
 store i64 %v7,ptr %p7,align 1
 %sum7 = add i64 %sum6,%v7
 %v8 = va_arg ptr %copy,i64
 %p8 = getelementptr i8,ptr %out,i64 64
 store i64 %v8,ptr %p8,align 1
 %sum8 = add i64 %sum7,%v8
 %v9 = va_arg ptr %copy,i64
 %p9 = getelementptr i8,ptr %out,i64 72
 store i64 %v9,ptr %p9,align 1
 %sum9 = add i64 %sum8,%v9
 call void @llvm.va_end.p0(ptr noundef nonnull align 8 dereferenceable_or_null(8) %copy) #7
 call void @llvm.va_end.p0(ptr noundef nonnull align 8 dereferenceable_or_null(8) %list) #7
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %answer = xor i64 %sum9,%token
 ret i64 %answer
}
define i64 @intrinsic_pointer_probe_63(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %source,i64 0
 %v0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %source,i64 8
 %v1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %source,i64 16
 %v2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %source,i64 24
 %v3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %source,i64 32
 %v4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %source,i64 40
 %v5 = load i64,ptr %p5,align 1
 %p6 = getelementptr i8,ptr %source,i64 48
 %v6 = load i64,ptr %p6,align 1
 %p7 = getelementptr i8,ptr %source,i64 56
 %v7 = load i64,ptr %p7,align 1
 %p8 = getelementptr i8,ptr %source,i64 64
 %v8 = load i64,ptr %p8,align 1
 %p9 = getelementptr i8,ptr %source,i64 72
 %v9 = load i64,ptr %p9,align 1
 %answer = call i64 (ptr,i64,i32,...) @intrinsic_pointer_body_63(ptr %out,i64 %salt,i32 10,i64 %v0,i64 %v1,i64 %v2,i64 %v3,i64 %v4,i64 %v5,i64 %v6,i64 %v7,i64 %v8,i64 %v9)
 ret i64 %answer
}
