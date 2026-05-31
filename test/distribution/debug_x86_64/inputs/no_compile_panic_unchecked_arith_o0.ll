source_filename = "no_compile_panic_for_unchecked_arith"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@entry = alias i64 (), ptr @no_compile_panic_for_unchecked_arith.entry

define private i64 @no_compile_panic_for_unchecked_arith.entry() unnamed_addr #0 align 1 {
  %1 = alloca i64, align 8
  store i64 0, ptr %1, align 8
  %2 = load i64, ptr %1, align 8
  %3 = add i64 %2, 1
  store i64 %3, ptr %1, align 8
  %4 = load i64, ptr %1, align 8
  %5 = sub i64 %4, 1
  store i64 %5, ptr %1, align 8
  %6 = load i64, ptr %1, align 8
  %7 = mul i64 %6, 2
  store i64 %7, ptr %1, align 8
  %8 = load i64, ptr %1, align 8
  %9 = call i64 @llvm.uadd.sat.i64(i64 %8, i64 1)
  store i64 %9, ptr %1, align 8
  %10 = load i64, ptr %1, align 8
  %11 = call i64 @llvm.usub.sat.i64(i64 %10, i64 1)
  store i64 %11, ptr %1, align 8
  %12 = load i64, ptr %1, align 8
  %13 = call i64 @llvm.umul.fix.sat.i64(i64 %12, i64 2, i32 0)
  store i64 %13, ptr %1, align 8
  %14 = load i64, ptr %1, align 8
  ret i64 %14
}

declare i64 @llvm.uadd.sat.i64(i64, i64)
declare i64 @llvm.usub.sat.i64(i64, i64)
declare i64 @llvm.umul.fix.sat.i64(i64, i64, i32)

attributes #0 = { nounwind uwtable }
