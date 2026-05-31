source_filename = "error_switch"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@error_switch = alias i32 (i8), ptr @error_switch.error_switch

define private range(i32 -2, 1) i32 @error_switch.error_switch(i8 zeroext %0) unnamed_addr #0 align 1 {
switch.lookup:
  %switch.selectcmp.i = icmp eq i8 %0, 1
  %switch.selectcmp1.i = icmp eq i8 %0, 0
  %.neg = select i1 %switch.selectcmp.i, i32 -1, i32 -2
  %switch.idx.cast.neg = select i1 %switch.selectcmp1.i, i32 0, i32 %.neg
  ret i32 %switch.idx.cast.neg
}

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "frame-pointer"="all" "target-cpu"="x86-64" }

!llvm.module.flags = !{}
