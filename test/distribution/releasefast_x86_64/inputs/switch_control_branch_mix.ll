source_filename = "switch_control"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@branch_mix = alias i32 (i32, i32, i1), ptr @switch_control.branch_mix

define private i32 @switch_control.branch_mix(i32 %0, i32 %1, i1 %2) unnamed_addr #0 align 1 {
3:
  %4 = sub i32 0, %1
  %.0.p = select i1 %2, i32 %1, i32 %4
  %.0 = add i32 %.0.p, %0
  ret i32 %.0
}

!llvm.module.flags = !{}
