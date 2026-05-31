source_filename = "fp_extended_ops"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@float_rem = alias float (float, float), ptr @fp_extended_ops.float_rem
@double_div = alias double (double, double), ptr @fp_extended_ops.double_div
@float_sub = alias float (float, float), ptr @fp_extended_ops.float_sub

define private float @fp_extended_ops.float_rem(float %0, float %1) unnamed_addr #0 align 1 {
2:
  %3 = frem float %0, %1
  ret float %3
}

define private double @fp_extended_ops.double_div(double %0, double %1) unnamed_addr #0 align 1 {
2:
  %3 = fdiv double %0, %1
  ret double %3
}

define private float @fp_extended_ops.float_sub(float %0, float %1) unnamed_addr #0 align 1 {
2:
  %3 = fsub float %0, %1
  ret float %3
}

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "frame-pointer"="all" "target-cpu"="x86-64" }

!llvm.module.flags = !{}
