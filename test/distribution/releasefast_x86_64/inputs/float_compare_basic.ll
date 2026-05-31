source_filename = "float_compare"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@float_mul = alias double (double, double), ptr @float_compare.float_mul
@float_less = alias i1 (float, float), ptr @float_compare.float_less

define private double @float_compare.float_mul(double %0, double %1) unnamed_addr #0 align 1 {
2:
  %3 = fmul double %0, %1
  ret double %3
}

define private i1 @float_compare.float_less(float %0, float %1) unnamed_addr #0 align 1 {
2:
  %3 = fcmp olt float %0, %1
  ret i1 %3
}

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "frame-pointer"="all" "target-cpu"="x86-64" }

!llvm.module.flags = !{}
