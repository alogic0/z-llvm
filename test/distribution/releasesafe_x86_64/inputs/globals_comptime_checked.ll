source_filename = "globals_comptime"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@globals_comptime.global_counter = private unnamed_addr global i32 3, align 4

@comptime_const = alias i32 (i32), ptr @globals_comptime.comptime_const
@update_global = alias i32 (i32), ptr @globals_comptime.update_global
@read_global = alias i32 (), ptr @globals_comptime.read_global

define private range(i32 -2147483645, 2147483646) i32 @globals_comptime.comptime_const(i32 %0) unnamed_addr #0 align 1 {
1:
  %2 = tail call { i32, i1 } @llvm.smul.with.overflow.i32(i32 %0, i32 5)
  %3 = extractvalue { i32, i1 } %2, 1
  br i1 %3, label %4, label %5
4:
  call void @llvm.assume(i1 1) [ "cold"() ]
  tail call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"()
  unreachable
5:
  %6 = extractvalue { i32, i1 } %2, 0
  ret i32 %6
}

define private i32 @globals_comptime.update_global(i32 %0) unnamed_addr #0 align 1 {
1:
  %2 = load i32, ptr @globals_comptime.global_counter, align 4
  %3 = tail call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %2, i32 %0)
  %4 = extractvalue { i32, i1 } %3, 1
  br i1 %4, label %5, label %6
5:
  call void @llvm.assume(i1 1) [ "cold"() ]
  tail call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"()
  unreachable
6:
  %7 = extractvalue { i32, i1 } %3, 0
  store i32 %7, ptr @globals_comptime.global_counter, align 4
  ret i32 %7
}

define private i32 @globals_comptime.read_global() unnamed_addr #1 align 1 {
0:
  %1 = load i32, ptr @globals_comptime.global_counter, align 4
  ret i32 %1
}

declare { i32, i1 } @llvm.smul.with.overflow.i32(i32, i32) #2
declare { i32, i1 } @llvm.sadd.with.overflow.i32(i32, i32) #2
declare void @llvm.assume(i1 noundef) #3
declare fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"() #4

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(readwrite, argmem: none, inaccessiblemem: none, target_mem0: none, target_mem1: none) uwtable "frame-pointer"="all" "target-cpu"="x86-64" }
attributes #1 = { mustprogress nofree norecurse nosync nounwind willreturn memory(read, argmem: none, target_mem0: none, target_mem1: none) uwtable "frame-pointer"="all" "target-cpu"="x86-64" }
attributes #2 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: readwrite) }
attributes #4 = { cold noreturn nounwind }

!llvm.module.flags = !{}
