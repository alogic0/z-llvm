source_filename = "floats_math"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@float_select = alias double (double, double, i1), ptr @floats_math.float_select
@float_add = alias float (float, float), ptr @floats_math.float_add

define private double @floats_math.float_select(double %0, double %1, i1 %2) unnamed_addr #0 align 1 {
3:
  %. = select i1 %2, double %0, double %1
  ret double %.
}

define private float @floats_math.float_add(float %0, float %1) unnamed_addr #0 align 1 {
2:
  %3 = fadd float %0, %1
  ret float %3
}

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "frame-pointer"="all" "target-cpu"="x86-64" }

!llvm.module.flags = !{}
