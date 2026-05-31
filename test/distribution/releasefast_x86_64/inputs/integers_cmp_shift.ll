source_filename = "integers"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@cmp_select = alias i32 (i32, i32), ptr @integers.cmp_select
@shift_mix = alias i32 (i32, i32), ptr @integers.shift_mix

declare i32 @llvm.smin.i32(i32, i32) #1

define private i32 @integers.cmp_select(i32 %0, i32 %1) unnamed_addr #0 align 1 {
2:
  %. = tail call i32 @llvm.smin.i32(i32 %0, i32 %1)
  ret i32 %.
}

define private i32 @integers.shift_mix(i32 %0, i32 %1) unnamed_addr #0 align 1 {
2:
  %3 = and i32 %1, 31
  %4 = shl i32 %0, %3
  %5 = lshr i32 %0, %3
  %6 = xor i32 %4, %5
  ret i32 %6
}

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "frame-pointer"="all" "target-cpu"="x86-64" }
attributes #1 = { nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }

!llvm.module.flags = !{}
