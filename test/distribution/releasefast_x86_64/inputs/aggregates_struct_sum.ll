source_filename = "aggregates"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@struct_sum = alias i32 (ptr), ptr @aggregates.struct_sum

define private i32 @aggregates.struct_sum(ptr nonnull readonly align 4 captures(none) %0) unnamed_addr #0 align 1 {
1:
  %2 = load i32, ptr %0, align 4
  %3 = getelementptr i8, ptr %0, i64 4
  %4 = load i32, ptr %3, align 4
  %5 = add nsw i32 %4, %2
  ret i32 %5
}

!llvm.module.flags = !{}
