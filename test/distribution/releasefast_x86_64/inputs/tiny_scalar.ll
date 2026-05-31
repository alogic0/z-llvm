source_filename = "tiny_scalar"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@sideEffectFree = alias void (), ptr @tiny_scalar.sideEffectFree
@add = alias i32 (i32, i32), ptr @tiny_scalar.add

define private void @tiny_scalar.sideEffectFree() unnamed_addr #0 align 1 {
0:
  ret void
}

define private i32 @tiny_scalar.add(i32 %0, i32 %1) unnamed_addr #0 align 1 {
2:
  %3 = add nsw i32 %1, %0
  ret i32 %3
}

!llvm.module.flags = !{}
