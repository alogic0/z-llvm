; Reduced from standalone_mix_c_files_main.zig.Debug.x86_64.ll captured in
; tmp/zig_ir/debug_object_probe_continuous_prefix400_20260531/ir/.
; Keeps the selected Debug/O0 mix-C public aliases that complete the
; continuous prefix-400 object probe after the dynamic-library add row.
source_filename = "main"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@C_k = external thread_local global i32, align 4
@main.zig_k = private unnamed_addr global i32 1, align 4
@__anon_17177 = private unnamed_addr constant [13 x i8] c"negative int\00", align 1
@__anon_1452 = private unnamed_addr constant { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, align 8

@add_zig = alias i32 (i32), ptr @main.add_zig
@zig_k = alias i32, ptr @main.zig_k
@add_may_panic = alias i32 (i32), ptr @main.add_may_panic

define private i32 @main.add_zig(i32 %0) {
  %2 = load i32, ptr @main.zig_k, align 4
  %3 = call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %0, i32 %2)
  %4 = extractvalue { i32, i1 } %3, 1
  br i1 %4, label %5, label %6

5:
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"()
  unreachable

6:
  %7 = extractvalue { i32, i1 } %3, 0
  %8 = load i32, ptr @C_k, align 4
  %9 = call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %7, i32 %8)
  %10 = extractvalue { i32, i1 } %9, 1
  br i1 %10, label %11, label %12

11:
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"()
  unreachable

12:
  %13 = extractvalue { i32, i1 } %9, 0
  ret i32 %13
}

define private i32 @main.add_may_panic(i32 %0) {
  %2 = icmp slt i32 %0, 0
  br i1 %2, label %7, label %10

3:
  %4 = load i32, ptr @main.zig_k, align 4
  %5 = call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %0, i32 %4)
  %6 = extractvalue { i32, i1 } %5, 1
  br i1 %6, label %11, label %12

7:
  call void @llvm.assume(i1 true) [ "cold"() ]
  %8 = extractvalue { ptr, i64 } { ptr @__anon_17177, i64 12 }, 0
  %9 = extractvalue { ptr, i64 } { ptr @__anon_17177, i64 12 }, 1
  call fastcc void @debug.defaultPanic(ptr nonnull readonly align 1 %8, i64 %9, ptr nonnull readonly align 8 @__anon_1452)
  unreachable

10:
  br label %3

11:
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"()
  unreachable

12:
  %13 = extractvalue { i32, i1 } %5, 0
  ret i32 %13
}

declare { i32, i1 } @llvm.sadd.with.overflow.i32(i32, i32)
declare void @llvm.assume(i1)
declare fastcc void @"debug.FullPanic((function 'defaultPanic')).integerOverflow"()
declare fastcc void @debug.defaultPanic(ptr nonnull readonly align 1, i64, ptr nonnull readonly align 8)

!llvm.module.flags = !{}
