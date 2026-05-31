source_filename = "control_flow_calls"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@loop_sum = alias i32 (i32), ptr @control_flow_calls.loop_sum

declare void @llvm.assume(i1 noundef) #1

define private range(i32 0, -2147483648) i32 @control_flow_calls.loop_sum(i32 %0) unnamed_addr #0 align 1 {
1:
  %.not = icmp eq i32 %0, 0
  br i1 %.not, label %._crit_edge, label %.lr.ph.preheader
.lr.ph.preheader:
  %xtraiter = and i32 %0, 7
  %2 = icmp ult i32 %0, 8
  br i1 %2, label %.lr.ph.epil.preheader, label %.lr.ph.preheader.new
.lr.ph.preheader.new:
  %unroll_iter = and i32 %0, -8
  br label %.lr.ph
.lr.ph:
  %.07 = phi i32 [ 0, %.lr.ph.preheader.new ], [ %19, %.lr.ph ]
  %.056 = phi i32 [ 0, %.lr.ph.preheader.new ], [ %18, %.lr.ph ]
  %niter = phi i32 [ 0, %.lr.ph.preheader.new ], [ %niter.next.7, %.lr.ph ]
  %3 = icmp sgt i32 %.07, -1
  tail call void @llvm.assume(i1 %3)
  %4 = add nsw nuw i32 %.07, %.056
  %5 = or disjoint i32 %.07, 1
  %6 = add nsw nuw i32 %5, %4
  %7 = or disjoint i32 %.07, 2
  %8 = add nsw nuw i32 %7, %6
  %9 = or disjoint i32 %.07, 3
  %10 = add nsw nuw i32 %9, %8
  %11 = or disjoint i32 %.07, 4
  %12 = add nsw nuw i32 %11, %10
  %13 = or disjoint i32 %.07, 5
  %14 = add nsw nuw i32 %13, %12
  %15 = or disjoint i32 %.07, 6
  %16 = add nsw nuw i32 %15, %14
  %17 = or disjoint i32 %.07, 7
  %18 = add nsw nuw i32 %17, %16
  %19 = add nuw i32 %.07, 8
  %niter.next.7 = add nuw i32 %niter, 8
  %niter.ncmp.7 = icmp eq i32 %niter.next.7, %unroll_iter
  br i1 %niter.ncmp.7, label %._crit_edge.loopexit.unr-lcssa, label %.lr.ph
._crit_edge.loopexit.unr-lcssa:
  %lcmp.mod.not = icmp eq i32 %xtraiter, 0
  br i1 %lcmp.mod.not, label %._crit_edge, label %.lr.ph.epil.preheader
.lr.ph.epil.preheader:
  %.07.epil.init = phi i32 [ 0, %.lr.ph.preheader ], [ %19, %._crit_edge.loopexit.unr-lcssa ]
  %.056.epil.init = phi i32 [ 0, %.lr.ph.preheader ], [ %18, %._crit_edge.loopexit.unr-lcssa ]
  %lcmp.mod9 = icmp ne i32 %xtraiter, 0
  tail call void @llvm.assume(i1 %lcmp.mod9)
  br label %.lr.ph.epil
.lr.ph.epil:
  %.07.epil = phi i32 [ %22, %.lr.ph.epil ], [ %.07.epil.init, %.lr.ph.epil.preheader ]
  %.056.epil = phi i32 [ %21, %.lr.ph.epil ], [ %.056.epil.init, %.lr.ph.epil.preheader ]
  %epil.iter = phi i32 [ %epil.iter.next, %.lr.ph.epil ], [ 0, %.lr.ph.epil.preheader ]
  %20 = icmp sgt i32 %.07.epil, -1
  tail call void @llvm.assume(i1 %20)
  %21 = add nsw nuw i32 %.07.epil, %.056.epil
  %22 = add nuw i32 %.07.epil, 1
  %epil.iter.next = add i32 %epil.iter, 1
  %epil.iter.cmp.not = icmp eq i32 %epil.iter.next, %xtraiter
  br i1 %epil.iter.cmp.not, label %._crit_edge, label %.lr.ph.epil, !llvm.loop !0
._crit_edge:
  %.05.lcssa = phi i32 [ 0, %1 ], [ %18, %._crit_edge.loopexit.unr-lcssa ], [ %21, %.lr.ph.epil ]
  ret i32 %.05.lcssa
}

attributes #0 = { nofree norecurse nosync nounwind memory(inaccessiblemem: write) uwtable "frame-pointer"="all" "target-cpu"="x86-64" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write) }

!llvm.module.flags = !{}
!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.unroll.disable"}
