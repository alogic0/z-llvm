source_filename = "no_compile_panic_for_unchecked_arith"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@entry = alias i64 (), ptr @no_compile_panic_for_unchecked_arith.entry

declare i64 @llvm.umul.fix.sat.i64(i64, i64, i32 immarg) #1

define private i64 @no_compile_panic_for_unchecked_arith.entry() unnamed_addr #0 align 1 {
0:
  %1 = tail call i64 @llvm.umul.fix.sat.i64(i64 0, i64 2, i32 0)
  ret i64 %1
}

attributes #0 = { minsize mustprogress nofree norecurse nosync nounwind optsize willreturn memory(none) uwtable "frame-pointer"="all" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }

!llvm.module.flags = !{}
