source_filename = "main"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@__anon_16879 = private unnamed_addr constant [5 x i8] c"test\00", align 1

@runner_test_name = alias { i64, i64 } (i32), ptr @main.runner_test_name

define private { i64, i64 } @main.runner_test_name(i32 %0) unnamed_addr #0 align 1 {
1:
  ret { i64, i64 } { i64 ptrtoint (ptr @__anon_16879 to i64), i64 4 }
}

attributes #0 = { minsize mustprogress nofree norecurse nosync nounwind optsize willreturn memory(none) uwtable "frame-pointer"="all" }

!llvm.module.flags = !{}
