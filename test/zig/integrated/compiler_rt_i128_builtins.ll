source_filename = "compiler_rt_i128_builtins"
target datalayout = "e-m:e-p270:32:32-p271:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i128 @llvm.abs.i128(i128, i1)
declare i128 @compiler_rt.udivmod.udivmod__anon_15304(i128, i128, ptr)

define dso_local i128 @__modti3(i128 %0, i128 %1) {
Entry:
  %2 = alloca i128, align 16
  %3 = ashr i128 %0, 127
  %4 = xor i128 %3, %0
  %5 = sub i128 %4, %3
  %6 = tail call i128 @llvm.abs.i128(i128 %1, i1 false)
  %7 = call i128 @compiler_rt.udivmod.udivmod__anon_15304(i128 %5, i128 %6, ptr nonnull align 16 %2)
  %8 = load i128, ptr %2, align 16
  %9 = xor i128 %8, %3
  %10 = sub i128 %9, %3
  ret i128 %10
}

define dso_local i128 @__multi3(i128 %0, i128 %1) {
Entry:
  %.sroa.01.0.extract.trunc = trunc i128 %0 to i64
  %.sroa.3.0.extract.shift = lshr i128 %0, 64
  %.sroa.3.0.extract.trunc = trunc nuw i128 %.sroa.3.0.extract.shift to i64
  %.sroa.04.0.extract.trunc = trunc i128 %1 to i64
  %.sroa.36.0.extract.shift = lshr i128 %1, 64
  %.sroa.36.0.extract.trunc = trunc nuw i128 %.sroa.36.0.extract.shift to i64
  %2 = and i64 %.sroa.01.0.extract.trunc, 4294967295
  %3 = and i64 %.sroa.04.0.extract.trunc, 4294967295
  %4 = mul nuw i64 %3, %2
  %5 = lshr i64 %4, 32
  %6 = and i64 %4, 4294967295
  %7 = lshr i64 %.sroa.01.0.extract.trunc, 32
  %8 = mul nuw i64 %3, %7
  %9 = add nuw i64 %5, %8
  %10 = lshr i64 %9, 32
  %11 = and i64 %9, 4294967295
  %12 = lshr i64 %.sroa.04.0.extract.trunc, 32
  %13 = mul nuw i64 %12, %2
  %14 = add nuw i64 %11, %13
  %15 = shl i64 %14, 32
  %16 = or disjoint i64 %15, %6
  %17 = lshr i64 %14, 32
  %18 = mul nuw i64 %12, %7
  %.sroa.0.0.insert.ext.i = zext i64 %16 to i128
  %19 = mul i64 %.sroa.3.0.extract.trunc, %.sroa.04.0.extract.trunc
  %20 = mul i64 %.sroa.36.0.extract.trunc, %.sroa.01.0.extract.trunc
  %21 = add i64 %20, %19
  %22 = add i64 %21, %18
  %23 = add i64 %22, %10
  %24 = add i64 %23, %17
  %.sroa.2.0.insert.ext = zext i64 %24 to i128
  %.sroa.2.0.insert.shift = shl nuw i128 %.sroa.2.0.insert.ext, 64
  %.sroa.07.0.insert.insert = or disjoint i128 %.sroa.2.0.insert.shift, %.sroa.0.0.insert.ext.i
  ret i128 %.sroa.07.0.insert.insert
}
