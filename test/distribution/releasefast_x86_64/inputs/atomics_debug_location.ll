source_filename = "atomics_inline_asm_debug"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@debug_location = alias i32 (i32), ptr @atomics_inline_asm_debug.debug_location

define private range(i32 -2147483647, -2147483648) i32 @atomics_inline_asm_debug.debug_location(i32 %0) unnamed_addr #0 align 1 {
1:
  %2 = add nsw i32 %0, 1
  ret i32 %2
}

!llvm.module.flags = !{}
