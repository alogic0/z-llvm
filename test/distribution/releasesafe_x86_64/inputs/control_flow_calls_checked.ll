source_filename = "control_flow_calls"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@loop_sum = alias i32 (i32), ptr @control_flow_calls.loop_sum
@call_chain = alias i32 (i32), ptr @control_flow_calls.call_chain

declare { i32, i1 } @llvm.sadd.with.overflow.i32(i32, i32)
declare void @llvm.assume(i1)
declare fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOutOfBounds"()
declare fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"()

define private i32 @control_flow_calls.loop_sum(i32 %0) unnamed_addr #0 align 1 {
1:
  %.not = icmp eq i32 %0, 0
  br i1 %.not, label %._crit_edge, label %.lr.ph
.lr.ph:
  %.09 = phi i32 [ %18, %17 ], [ 0, %1 ]
  %.058 = phi i32 [ %19, %17 ], [ 0, %1 ]
  %2 = tail call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %.058, i32 %.09)
  %3 = extractvalue { i32, i1 } %2, 1
  br i1 %3, label %5, label %6
._crit_edge:
  %.05.lcssa = phi i32 [ 0, %1 ], [ %8, %6 ], [ %13, %11 ], [ %19, %17 ]
  ret i32 %.05.lcssa
4:
  call void @llvm.assume(i1 1) [ "cold"() ]
  tail call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOutOfBounds"()
  unreachable
5:
  call void @llvm.assume(i1 1) [ "cold"() ]
  tail call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"()
  unreachable
6:
  %7 = add nsw nuw i32 %.09, 1
  %8 = extractvalue { i32, i1 } %2, 0
  %exitcond10.not = icmp eq i32 %7, %0
  br i1 %exitcond10.not, label %._crit_edge, label %.lr.ph.1
.lr.ph.1:
  %9 = tail call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %8, i32 %7)
  %10 = extractvalue { i32, i1 } %9, 1
  br i1 %10, label %5, label %11
11:
  %12 = add nuw i32 %.09, 2
  %13 = extractvalue { i32, i1 } %9, 0
  %exitcond10.not.1 = icmp eq i32 %12, %0
  br i1 %exitcond10.not.1, label %._crit_edge, label %.lr.ph.2
.lr.ph.2:
  %exitcond.not.2 = icmp eq i32 %12, -2147483648
  br i1 %exitcond.not.2, label %4, label %14
14:
  %15 = tail call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %13, i32 %12)
  %16 = extractvalue { i32, i1 } %15, 1
  br i1 %16, label %5, label %17
17:
  %18 = add nuw i32 %.09, 3
  %19 = extractvalue { i32, i1 } %15, 0
  %exitcond10.not.2 = icmp eq i32 %18, %0
  br i1 %exitcond10.not.2, label %._crit_edge, label %.lr.ph
}

define private range(i32 -2147483647, -2147483648) i32 @control_flow_calls.call_chain(i32 %0) unnamed_addr #0 align 1 {
1:
  %2 = add i32 %0, 1073741824
  %3 = icmp slt i32 %2, 0
  br i1 %3, label %4, label %control_flow_calls.callee.exit
4:
  call void @llvm.assume(i1 1) [ "cold"() ]
  tail call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"()
  unreachable
control_flow_calls.callee.exit:
  %5 = shl nsw i32 %0, 1
  %6 = or disjoint i32 %5, 1
  ret i32 %6
}

attributes #0 = { nounwind uwtable "frame-pointer"="all" "target-cpu"="x86-64" }

!llvm.module.flags = !{}
