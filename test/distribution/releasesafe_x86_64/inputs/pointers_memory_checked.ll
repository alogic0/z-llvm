source_filename = "pointers_memory"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@load_store = alias i32 (ptr, ptr), ptr @pointers_memory.load_store

define private range(i32 -2147483647, -2147483648) i32 @pointers_memory.load_store(ptr nonnull readonly captures(none) %0, ptr nonnull writeonly captures(none) %1) unnamed_addr #0 align 1 {
2:
  %3 = load i32, ptr %0, align 4
  %4 = tail call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %3, i32 1)
  %5 = extractvalue { i32, i1 } %4, 1
  br i1 %5, label %6, label %7
6:
  call void @llvm.assume(i1 1) [ "cold"() ]
  tail call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"()
  unreachable
7:
  %8 = extractvalue { i32, i1 } %4, 0
  store i32 %8, ptr %1, align 4
  ret i32 %8
}

declare { i32, i1 } @llvm.sadd.with.overflow.i32(i32, i32) #1
declare void @llvm.assume(i1 noundef) #2
declare fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"() #3

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: readwrite) uwtable "frame-pointer"="all" "target-cpu"="x86-64" }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: readwrite) }
attributes #3 = { cold noreturn nounwind }

!llvm.module.flags = !{}
