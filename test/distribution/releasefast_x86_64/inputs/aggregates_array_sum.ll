source_filename = "aggregates"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@array_sum = alias i32 (i32, i32, i32), ptr @aggregates.array_sum

define private i32 @aggregates.array_sum(i32 %0, i32 %1, i32 %2) unnamed_addr #0 align 1 {
3:
  %4 = add nsw i32 %1, %0
  %5 = add nsw i32 %4, %2
  ret i32 %5
}

!llvm.module.flags = !{}
