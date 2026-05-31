source_filename = "main"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@main = alias void (i32, i32, i32), ptr @main.main

define private void @main.main(i32 %0, i32 %1, i32 %2) unnamed_addr #0 align 1 {
3:
  unreachable
}

attributes #0 = { minsize mustprogress nofree norecurse noreturn nosync nounwind optsize willreturn memory(none) uwtable "frame-pointer"="all" }

!llvm.module.flags = !{}
