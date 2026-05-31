source_filename = "integers"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@add_wrap = alias i32 (i32, i32), ptr @integers.add_wrap

define private i32 @integers.add_wrap(i32 %0, i32 %1) unnamed_addr #0 align 1 {
2:
  %3 = add i32 %1, %0
  ret i32 %3
}

!llvm.module.flags = !{}
