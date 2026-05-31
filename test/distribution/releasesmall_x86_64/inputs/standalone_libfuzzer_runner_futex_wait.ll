source_filename = "main"
target datalayout = "e-m:e-p270:32:32-p271:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@runner_futex_wait = alias i1 (ptr, i32), ptr @main.runner_futex_wait

define private noundef i1 @main.runner_futex_wait(ptr nonnull readonly align 4 captures(none) %0, i32 %1) unnamed_addr #0 align 1 {
2:
  ret i1 0
}

attributes #0 = { minsize mustprogress nofree norecurse nosync nounwind optsize willreturn memory(none) uwtable "frame-pointer"="all" }

!llvm.module.flags = !{}
