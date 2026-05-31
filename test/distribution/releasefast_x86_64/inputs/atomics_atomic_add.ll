source_filename = "atomics_inline_asm_debug"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@atomics_inline_asm_debug.atomic_counter = private unnamed_addr global i32 0, align 4

@atomic_add = alias i32 (i32), ptr @atomics_inline_asm_debug.atomic_add

define private i32 @atomics_inline_asm_debug.atomic_add(i32 %0) unnamed_addr #0 align 1 {
1:
  %2 = atomicrmw add ptr @atomics_inline_asm_debug.atomic_counter, i32 %0 monotonic, align 4
  ret i32 %2
}

attributes #0 = { mustprogress nofree norecurse nounwind willreturn memory(readwrite, argmem: none, inaccessiblemem: none, target_mem0: none, target_mem1: none) uwtable "frame-pointer"="all" "target-cpu"="x86-64" }

!llvm.module.flags = !{}
