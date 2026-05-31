source_filename = "tiny_scalar"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@sideEffectFree = alias void (), ptr @tiny_scalar.sideEffectFree
@add = alias i32 (i32, i32), ptr @tiny_scalar.add

define private void @tiny_scalar.sideEffectFree() unnamed_addr #0 align 1 {
0:
  ret void
}

define private i32 @tiny_scalar.add(i32 %0, i32 %1) unnamed_addr #1 align 1 {
2:
  %3 = tail call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %0, i32 %1)
  %4 = extractvalue { i32, i1 } %3, 1
  br i1 %4, label %5, label %6
5:
  call void @llvm.assume(i1 1) [ "cold"() ]
  tail call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"()
  unreachable
6:
  %7 = extractvalue { i32, i1 } %3, 0
  ret i32 %7
}

declare { i32, i1 } @llvm.sadd.with.overflow.i32(i32, i32) #2
declare void @llvm.assume(i1 noundef) #3
declare fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"() #4

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "frame-pointer"="all" "target-cpu"="x86-64" }
attributes #1 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "frame-pointer"="all" "target-cpu"="x86-64" }
attributes #2 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: readwrite) }
attributes #4 = { cold noreturn nounwind }

!llvm.module.flags = !{}
