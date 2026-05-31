source_filename = "globals_comptime"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@globals_comptime.global_counter = private unnamed_addr global i32 3, align 4

@update_global = alias i32 (i32), ptr @globals_comptime.update_global
@read_global = alias i32 (), ptr @globals_comptime.read_global

define private i32 @globals_comptime.update_global(i32 %0) unnamed_addr #0 align 1 {
1:
  %2 = load i32, ptr @globals_comptime.global_counter, align 4
  %3 = add nsw i32 %2, %0
  store i32 %3, ptr @globals_comptime.global_counter, align 4
  ret i32 %3
}

define private i32 @globals_comptime.read_global() unnamed_addr #1 align 1 {
0:
  %1 = load i32, ptr @globals_comptime.global_counter, align 4
  ret i32 %1
}

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(readwrite, argmem: none, inaccessiblemem: none, target_mem0: none, target_mem1: none) uwtable "frame-pointer"="all" "target-cpu"="x86-64" }
attributes #1 = { mustprogress nofree norecurse nosync nounwind willreturn memory(read, argmem: none, inaccessiblemem: none, target_mem0: none, target_mem1: none) uwtable "frame-pointer"="all" "target-cpu"="x86-64" }

!llvm.module.flags = !{}
