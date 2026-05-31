; Reduced from standalone_load_dynamic_library_add.zig.Debug.x86_64.ll captured in
; tmp/zig_ir/debug_object_probe_continuous_prefix400_20260531/ir/.
; Keeps the public add alias and the Debug/O0 checked sadd-with-overflow panic
; edge that first blocked the continuous prefix-400 object probe after libfuzzer.
source_filename = "add"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@add = alias i32 (i32, i32), ptr @add.add

define private i32 @add.add(i32 %0, i32 %1) {
  %3 = call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %0, i32 %1)
  %4 = extractvalue { i32, i1 } %3, 1
  br i1 %4, label %5, label %6

5:
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"()
  unreachable

6:
  %7 = extractvalue { i32, i1 } %3, 0
  ret i32 %7
}

declare { i32, i1 } @llvm.sadd.with.overflow.i32(i32, i32)
declare void @llvm.assume(i1)
declare fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"()

!llvm.module.flags = !{}
