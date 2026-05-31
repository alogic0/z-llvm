source_filename = "globals_comptime"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@comptime_const = alias i32 (i32), ptr @globals_comptime.comptime_const

define private i32 @globals_comptime.comptime_const(i32 %0) unnamed_addr #0 align 1 {
1:
  %2 = mul nsw i32 %0, 5
  ret i32 %2
}

!llvm.module.flags = !{}
