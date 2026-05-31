source_filename = "illegal_operation_on_logical_ptr"
target datalayout = "e-m:e-p270:32:32-p271:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@ptrIntArithmetic = alias void (), ptr @illegal_operation_on_logical_ptr.ptrIntArithmetic
@ptrPtrArithmetic = alias void (), ptr @illegal_operation_on_logical_ptr.ptrPtrArithmetic
@ptrFromInt = alias void (), ptr @illegal_operation_on_logical_ptr.ptrFromInt
@intFromPtr = alias void (), ptr @illegal_operation_on_logical_ptr.intFromPtr
@elemVal = alias void (), ptr @illegal_operation_on_logical_ptr.elemVal
@elemPtr = alias void (), ptr @illegal_operation_on_logical_ptr.elemPtr

define private void @illegal_operation_on_logical_ptr.ptrIntArithmetic() unnamed_addr #0 align 1 {
  %1 = alloca ptr, align 8
  call void @llvm.memset.p0.i64(ptr align 8 %1, i8 -86, i64 8, i1 false)
  ret void
}

declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)

define private void @illegal_operation_on_logical_ptr.ptrPtrArithmetic() unnamed_addr #0 align 1 {
  %1 = alloca i8, align 1
  %2 = alloca i8, align 1
  store i8 0, ptr %2, align 1
  store i8 0, ptr %1, align 1
  ret void
}

define private void @illegal_operation_on_logical_ptr.ptrFromInt() unnamed_addr #0 align 1 {
  %1 = alloca ptr, align 8
  %2 = alloca i32, align 4
  store i32 4660, ptr %2, align 4
  %3 = load i32, ptr %2, align 4
  %4 = zext i32 %3 to i64
  %5 = icmp ne i64 %4, 0
  br i1 %5, label %8, label %9

6:
  %7 = inttoptr i64 %4 to ptr
  store ptr %7, ptr %1, align 8
  ret void

8:
  br label %6

9:
  call void @llvm.assume(i1 true)
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).castToNull"()
  unreachable
}

declare void @llvm.assume(i1)
declare fastcc void @"debug.FullPanic((function 'defaultPanic')).castToNull"()

define private void @illegal_operation_on_logical_ptr.intFromPtr() unnamed_addr #0 align 1 {
  %1 = alloca i8, align 1
  store i8 0, ptr %1, align 1
  ret void
}

define private void @illegal_operation_on_logical_ptr.elemVal() unnamed_addr #0 align 1 {
  %1 = alloca i8, align 1
  %2 = alloca ptr, align 8
  call void @llvm.memset.p0.i64(ptr align 8 %2, i8 -86, i64 8, i1 false)
  %3 = load ptr, ptr %2, align 8
  %4 = getelementptr inbounds [1 x i8], ptr %3, i64 0
  %5 = load i8, ptr %4, align 1
  store i8 %5, ptr %1, align 1
  ret void
}

define private void @illegal_operation_on_logical_ptr.elemPtr() unnamed_addr #0 align 1 {
  %1 = alloca ptr, align 8
  call void @llvm.memset.p0.i64(ptr align 8 %1, i8 -86, i64 8, i1 false)
  %2 = load ptr, ptr %1, align 8
  %3 = getelementptr inbounds [1 x i8], ptr %2, i64 0
  store i8 0, ptr %3, align 1
  ret void
}

attributes #0 = { nounwind uwtable }
