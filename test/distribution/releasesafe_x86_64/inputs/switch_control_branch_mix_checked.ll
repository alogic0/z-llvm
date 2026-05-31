source_filename = "switch_control"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@branch_mix = alias i32 (i32, i32, i1), ptr @switch_control.branch_mix

define private i32 @switch_control.branch_mix(i32 %0, i32 %1, i1 %2) unnamed_addr #0 align 1 {
3:
  br i1 %2, label %5, label %8
4:
  %.pn = phi { i32, i1 } [ %6, %5 ], [ %9, %8 ]
  %.0 = extractvalue { i32, i1 } %.pn, 0
  ret i32 %.0
5:
  %6 = tail call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %0, i32 %1)
  %7 = extractvalue { i32, i1 } %6, 1
  br i1 %7, label %11, label %4
8:
  %9 = tail call { i32, i1 } @llvm.ssub.with.overflow.i32(i32 %0, i32 %1)
  %10 = extractvalue { i32, i1 } %9, 1
  br i1 %10, label %12, label %4
11:
  call void @llvm.assume(i1 1) [ "cold"() ]
  tail call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"()
  unreachable
12:
  call void @llvm.assume(i1 1) [ "cold"() ]
  tail call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"()
  unreachable
}

declare { i32, i1 } @llvm.sadd.with.overflow.i32(i32, i32) #1
declare { i32, i1 } @llvm.ssub.with.overflow.i32(i32, i32) #1
declare void @llvm.assume(i1 noundef) #2
declare fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"() #3

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "frame-pointer"="all" "target-cpu"="x86-64" }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: readwrite) }
attributes #3 = { cold noreturn nounwind }

!llvm.module.flags = !{}
