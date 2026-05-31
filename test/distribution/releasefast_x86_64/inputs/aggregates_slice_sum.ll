source_filename = "aggregates"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@slice_sum = alias i32 (ptr, i64), ptr @aggregates.slice_sum

define private i32 @aggregates.slice_sum(ptr nonnull readonly captures(none) %0, i64 %1) unnamed_addr #0 align 1 {
2:
  %.not = icmp eq i64 %1, 0
  br i1 %.not, label %._crit_edge, label %.lr.ph
.lr.ph:
  %.010 = phi i32 [ 0, %2 ], [ %5, %.lr.ph ]
  %.089 = phi i64 [ 0, %2 ], [ %6, %.lr.ph ]
  %3 = getelementptr [4 x i8], ptr %0, i64 %.089
  %4 = load i32, ptr %3, align 4
  %5 = add nsw i32 %4, %.010
  %6 = add nuw i64 %.089, 1
  %7 = icmp eq i64 %6, %1
  br i1 %7, label %._crit_edge, label %.lr.ph
._crit_edge:
  %.0.lcssa = phi i32 [ 0, %2 ], [ %5, %.lr.ph ]
  ret i32 %.0.lcssa
}

!llvm.module.flags = !{}
