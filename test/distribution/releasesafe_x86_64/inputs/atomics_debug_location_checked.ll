source_filename = "atomics_inline_asm_debug"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@debug_location = alias i32 (i32), ptr @atomics_inline_asm_debug.debug_location

declare { i32, i1 } @llvm.sadd.with.overflow.i32(i32, i32)
declare void @llvm.assume(i1)
declare fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"()

define private range(i32 -2147483647, -2147483648) i32 @atomics_inline_asm_debug.debug_location(i32 %0) unnamed_addr #0 align 1 {
1:
  %2 = tail call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %0, i32 1)
  %3 = extractvalue { i32, i1 } %2, 1
  br i1 %3, label %4, label %5
4:
  call void @llvm.assume(i1 1) [ "cold"() ]
  tail call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"()
  unreachable
5:
  %6 = extractvalue { i32, i1 } %2, 0
  ret i32 %6
}

attributes #0 = { nounwind uwtable "frame-pointer"="all" "target-cpu"="x86-64" }

!llvm.module.flags = !{}
