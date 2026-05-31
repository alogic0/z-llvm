source_filename = "inherit_want_safety"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@entry = alias i64 (), ptr @inherit_want_safety.entry

define private noundef range(i64 2, 0) i64 @inherit_want_safety.entry() unnamed_addr #0 align 1 {
0:
  ret i64 4
}

attributes #0 = { minsize mustprogress nofree norecurse nosync nounwind optsize willreturn memory(none) uwtable "frame-pointer"="all" }

!llvm.module.flags = !{}
