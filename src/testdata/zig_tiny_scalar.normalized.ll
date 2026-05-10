source_filename = "tiny_scalar"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

define internal void @tiny_scalar.sideEffectFree() {
Entry:
  ret void
}

define internal i32 @tiny_scalar.add(i32 %0, i32 %1) {
Entry:
  %2 = add nsw i32 %1, %0
  ret i32 %2
}
