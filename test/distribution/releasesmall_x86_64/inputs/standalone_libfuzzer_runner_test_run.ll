source_filename = "main"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@__anon_11775 = private unnamed_addr constant [1 x i8] zeroinitializer, align 1
@__anon_16031 = private unnamed_addr constant [6 x i8] c"hello\00", align 1

@runner_test_run = alias void (i32), ptr @main.runner_test_run

declare void @fuzzer_set_test(ptr nonnull readonly align 1) local_unnamed_addr #1 align 1
declare void @fuzzer_new_input(i64, i64) local_unnamed_addr #1 align 1
declare void @fuzzer_start_test() local_unnamed_addr #1 align 1
declare i1 @main.testOne()

define private void @main.runner_test_run(i32 %0) unnamed_addr #0 align 1 {
1:
  tail call void @fuzzer_set_test(ptr nonnull readonly align 1 @main.testOne)
  tail call void @fuzzer_new_input(i64 ptrtoint (ptr @__anon_11775 to i64), i64 0)
  tail call void @fuzzer_new_input(i64 ptrtoint (ptr @__anon_16031 to i64), i64 5)
  tail call void @fuzzer_start_test()
  ret void
}

attributes #0 = { minsize mustprogress nofree norecurse nosync nounwind optsize willreturn memory(none) uwtable "frame-pointer"="all" }
attributes #1 = { minsize nounwind }

!llvm.module.flags = !{}
