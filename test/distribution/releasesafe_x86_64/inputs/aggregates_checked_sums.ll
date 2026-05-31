source_filename = "aggregates"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@slice_sum = alias i32 (ptr, i64), ptr @aggregates.slice_sum
@struct_sum = alias i32 (ptr), ptr @aggregates.struct_sum
@array_sum = alias i32 (i32, i32, i32), ptr @aggregates.array_sum

declare { i32, i1 } @llvm.sadd.with.overflow.i32(i32, i32)
declare void @llvm.assume(i1)
declare fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"()

define private i32 @aggregates.slice_sum(ptr nonnull readonly captures(none) %0, i64 %1) unnamed_addr #0 align 1 {
2:
  %.not = icmp eq i64 %1, 0
  br i1 %.not, label %._crit_edge, label %.lr.ph
._crit_edge:
  %.0.lcssa = phi i32 [ 0, %2 ], [ %10, %8 ]
  ret i32 %.0.lcssa
.lr.ph:
  %.012 = phi i32 [ %10, %8 ], [ 0, %2 ]
  %.0811 = phi i64 [ %9, %8 ], [ 0, %2 ]
  %3 = getelementptr [4 x i8], ptr %0, i64 %.0811
  %4 = load i32, ptr %3, align 4
  %5 = tail call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %.012, i32 %4)
  %6 = extractvalue { i32, i1 } %5, 1
  br i1 %6, label %7, label %8
7:
  call void @llvm.assume(i1 1) [ "cold"() ]
  tail call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"()
  unreachable
8:
  %9 = add nuw i64 %.0811, 1
  %10 = extractvalue { i32, i1 } %5, 0
  %exitcond.not = icmp eq i64 %9, %1
  br i1 %exitcond.not, label %._crit_edge, label %.lr.ph
}

define private i32 @aggregates.struct_sum(ptr nonnull readonly align 4 captures(none) %0) unnamed_addr #0 align 1 {
1:
  %2 = load i32, ptr %0, align 4
  %3 = getelementptr i8, ptr %0, i64 4
  %4 = load i32, ptr %3, align 4
  %5 = tail call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %2, i32 %4)
  %6 = extractvalue { i32, i1 } %5, 1
  br i1 %6, label %7, label %8
7:
  call void @llvm.assume(i1 1) [ "cold"() ]
  tail call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"()
  unreachable
8:
  %9 = extractvalue { i32, i1 } %5, 0
  ret i32 %9
}

define private i32 @aggregates.array_sum(i32 %0, i32 %1, i32 %2) unnamed_addr #0 align 1 {
3:
  %4 = tail call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %0, i32 %1)
  %5 = extractvalue { i32, i1 } %4, 1
  br i1 %5, label %6, label %7
6:
  call void @llvm.assume(i1 1) [ "cold"() ]
  tail call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"()
  unreachable
7:
  %8 = extractvalue { i32, i1 } %4, 0
  %9 = tail call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %8, i32 %2)
  %10 = extractvalue { i32, i1 } %9, 1
  br i1 %10, label %11, label %12
11:
  call void @llvm.assume(i1 1) [ "cold"() ]
  tail call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"()
  unreachable
12:
  %13 = extractvalue { i32, i1 } %9, 0
  ret i32 %13
}

attributes #0 = { nounwind uwtable "frame-pointer"="all" "target-cpu"="x86-64" }

!llvm.module.flags = !{}
