source_filename = "spirv_merge_logical_pointers"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@a = alias void (), ptr @spirv_merge_logical_pointers.a

define private void @spirv_merge_logical_pointers.a() unnamed_addr #0 align 1 {
  %1 = alloca ptr, align 8
  %2 = alloca i1, align 1
  %3 = alloca ptr, align 8
  %4 = alloca ptr, align 8
  call void @llvm.memset.p0.i64(ptr align 8 %4, i8 -86, i64 8, i1 false)
  call void @llvm.memset.p0.i64(ptr align 8 %3, i8 -86, i64 8, i1 false)
  store i1 false, ptr %2, align 1
  %5 = load i1, ptr %2, align 1
  br i1 %5, label %8, label %10

6:
  %7 = phi ptr [ %9, %8 ], [ %11, %10 ]
  store ptr %7, ptr %1, align 8
  ret void

8:
  %9 = load ptr, ptr %4, align 8
  br label %6

10:
  %11 = load ptr, ptr %3, align 8
  br label %6
}

declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)

attributes #0 = { nounwind uwtable }
