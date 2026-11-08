target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare ptr @llvm.load.relative.i64(ptr, i64)
define ptr @relative_load(ptr %base, i64 %offset) {
entry:
  %result = call ptr @llvm.load.relative.i64(ptr %base, i64 %offset)
  ret ptr %result
}
define i64 @relative_load_live(ptr %base, i64 %offset, i64 %live) {
entry:
  %address = call ptr @llvm.load.relative.i64(ptr %base, i64 %offset)
  %value = load i8, ptr %address, align 1
  %wide = zext i8 %value to i64
  %result = xor i64 %wide, %live
  ret i64 %result
}
