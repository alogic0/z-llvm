source_filename = "main"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@_start = alias void (), ptr @main._start

define private void @main._start() unnamed_addr #0 align 1 {
0:
  br label %1
1:
  br label %1
}

attributes #0 = { minsize nofree norecurse noreturn nosync nounwind optsize memory(none) uwtable "frame-pointer"="all" }

!llvm.module.flags = !{}
