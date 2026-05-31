source_filename = "fp_constants"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@double_literal = alias double (), ptr @fp_constants.double_literal
@float_literal = alias float (), ptr @fp_constants.float_literal

define private noundef double @fp_constants.double_literal() unnamed_addr #0 align 1 {
0:
  ret double 2.250000e+00
}

define private noundef float @fp_constants.float_literal() unnamed_addr #0 align 1 {
0:
  ret float 1.500000e+00
}

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "frame-pointer"="all" "target-cpu"="x86-64" }

!llvm.module.flags = !{}
