target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-Fn32"
target triple = "aarch64-unknown-linux5.10.0-gnu2.31.0"

define i32 @aarch64_scalar_identity(i32 %x) {
entry:
  %sum = add i32 %x, 0
  ret i32 %sum
}
