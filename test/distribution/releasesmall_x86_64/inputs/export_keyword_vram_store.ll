source_filename = "export_keyword"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@testPackedStuff = alias void (ptr, ptr), ptr @export_keyword.testPackedStuff
@writeToVRam = alias void (), ptr @export_keyword.writeToVRam

define private void @export_keyword.testPackedStuff(ptr nonnull readonly captures(none) %0, ptr nonnull readonly align 1 captures(none) %1) unnamed_addr #0 align 1 {
2:
  ret void
}

define private void @export_keyword.writeToVRam() unnamed_addr #1 align 1 {
0:
  store volatile i8 88, ptr inttoptr (i64 536870912 to ptr), align 536870912
  ret void
}

attributes #0 = { minsize mustprogress nofree norecurse nosync nounwind optsize willreturn memory(none) uwtable "frame-pointer"="all" "target-cpu"="x86-64" }
attributes #1 = { minsize nofree norecurse nounwind optsize memory(readwrite, target_mem0: none, target_mem1: none) uwtable "frame-pointer"="all" "target-cpu"="x86-64" }

!llvm.module.flags = !{}
