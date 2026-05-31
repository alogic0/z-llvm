source_filename = "atomics_inline_asm_debug"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@inline_asm_barrier = alias i32 (i32), ptr @atomics_inline_asm_debug.inline_asm_barrier

define private i32 @atomics_inline_asm_debug.inline_asm_barrier(i32 returned %0) unnamed_addr #0 align 1 {
1:
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #1
  ret i32 %0
}

!llvm.module.flags = !{}
