source_filename = "aggregate_abi"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@pair_first = alias i32 (i64), ptr @aggregate_abi.pair_first
@make_pair = alias i64 (i32, i32), ptr @aggregate_abi.make_pair

define private i32 @aggregate_abi.pair_first(i64 %0) unnamed_addr #0 align 1 {
1:
  %.sroa.01.0.extract.trunc = trunc i64 %0 to i32
  ret i32 %.sroa.01.0.extract.trunc
}

define private i64 @aggregate_abi.make_pair(i32 %0, i32 %1) unnamed_addr #0 align 1 {
2:
  %.sroa.2.0.insert.ext = zext i32 %1 to i64
  %.sroa.2.0.insert.shift = shl nuw i64 %.sroa.2.0.insert.ext, 32
  %.sroa.0.0.insert.ext = zext i32 %0 to i64
  %.sroa.0.0.insert.insert = or disjoint i64 %.sroa.2.0.insert.shift, %.sroa.0.0.insert.ext
  ret i64 %.sroa.0.0.insert.insert
}

!llvm.module.flags = !{}
