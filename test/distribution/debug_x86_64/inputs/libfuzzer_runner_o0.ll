; Reduced from standalone_libfuzzer_main.zig.Debug.x86_64.ll captured in
; tmp/zig_ir/debug_object_probe_continuous_prefix400_20260531/ir/.
; Keeps the Debug/O0 libfuzzer runner aliases and the alloca/extractvalue
; slice materialization shape that first blocked the x86_64 object probe.
source_filename = "main"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

%Build.abi.fuzz.Slice = type { i64, i64 }

@__anon_8117 = private unnamed_addr constant [1 x i8] zeroinitializer, align 1
@__anon_22815 = private unnamed_addr constant [5 x i8] c"test\00", align 1
@__anon_22035 = private unnamed_addr constant [6 x i8] c"hello\00", align 1

@runner_broadcast_input = alias void (i32, i64, i64), ptr @main.runner_broadcast_input
@runner_futex_wake = alias void (ptr, i32), ptr @main.runner_futex_wake
@runner_futex_wait = alias i1 (ptr, i32), ptr @main.runner_futex_wait
@runner_stop_input_poller = alias void (), ptr @main.runner_stop_input_poller
@runner_start_input_poller = alias void (), ptr @main.runner_start_input_poller
@runner_test_name = alias { i64, i64 } (i32), ptr @main.runner_test_name
@runner_test_run = alias void (i32), ptr @main.runner_test_run

define private void @main.runner_broadcast_input(i32 %0, i64 %1, i64 %2) {
  %4 = alloca [16 x i8], align 8
  store i64 %1, ptr %4, align 8
  %5 = getelementptr inbounds i8, ptr %4, i64 8
  store i64 %2, ptr %5, align 8
  ret void
}

define private void @main.runner_futex_wake(ptr nonnull readonly align 4 %0, i32 %1) {
  ret void
}

define private i1 @main.runner_futex_wait(ptr nonnull readonly align 4 %0, i32 %1) {
  %3 = load i32, ptr %0, align 4
  %4 = icmp eq i32 %3, %1
  call fastcc void @debug.assert(i1 %4)
  ret i1 false
}

define private void @main.runner_stop_input_poller() {
  ret void
}

define private void @main.runner_start_input_poller() {
  ret void
}

define private { i64, i64 } @main.runner_test_name(i32 %0) {
  %2 = alloca %Build.abi.fuzz.Slice, align 8
  %3 = icmp eq i32 %0, 0
  call fastcc void @debug.assert(i1 %3)
  %4 = extractvalue { ptr, i64 } { ptr @__anon_22815, i64 4 }, 0
  %5 = extractvalue { ptr, i64 } { ptr @__anon_22815, i64 4 }, 1
  call fastcc void @Build.abi.fuzz.Slice.fromSlice(ptr sret(%Build.abi.fuzz.Slice) %2, ptr nonnull readonly align 1 %4, i64 %5)
  %6 = load { i64, i64 }, ptr %2, align 8
  ret { i64, i64 } %6
}

declare void @fuzzer_set_test(ptr nonnull readonly align 1)
declare void @fuzzer_new_input(i64, i64)
declare void @fuzzer_start_test()

define private void @main.runner_test_run(i32 %0) {
  %2 = alloca [16 x i8], align 8
  %3 = alloca %Build.abi.fuzz.Slice, align 8
  %4 = alloca [16 x i8], align 8
  %5 = alloca %Build.abi.fuzz.Slice, align 8
  %6 = icmp eq i32 %0, 0
  call fastcc void @debug.assert(i1 %6)
  call void @fuzzer_set_test(ptr nonnull readonly align 1 @main.testOne)
  %7 = extractvalue { ptr, i64 } { ptr @__anon_8117, i64 0 }, 0
  %8 = extractvalue { ptr, i64 } { ptr @__anon_8117, i64 0 }, 1
  call fastcc void @Build.abi.fuzz.Slice.fromSlice(ptr sret(%Build.abi.fuzz.Slice) %5, ptr nonnull readonly align 1 %7, i64 %8)
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %4, ptr align 8 %5, i64 16, i1 false)
  %9 = load i64, ptr %4, align 8
  %10 = getelementptr inbounds i8, ptr %4, i64 8
  %11 = load i64, ptr %10, align 8
  call void @fuzzer_new_input(i64 %9, i64 %11)
  %12 = extractvalue { ptr, i64 } { ptr @__anon_22035, i64 5 }, 0
  %13 = extractvalue { ptr, i64 } { ptr @__anon_22035, i64 5 }, 1
  call fastcc void @Build.abi.fuzz.Slice.fromSlice(ptr sret(%Build.abi.fuzz.Slice) %3, ptr nonnull readonly align 1 %12, i64 %13)
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %2, ptr align 8 %3, i64 16, i1 false)
  %14 = load i64, ptr %2, align 8
  %15 = getelementptr inbounds i8, ptr %2, i64 8
  %16 = load i64, ptr %15, align 8
  call void @fuzzer_new_input(i64 %14, i64 %16)
  call void @fuzzer_start_test()
  ret void
}

define private i1 @main.testOne() {
  ret i1 false
}

declare fastcc void @debug.assert(i1)
declare fastcc void @Build.abi.fuzz.Slice.fromSlice(ptr sret(%Build.abi.fuzz.Slice), ptr nonnull readonly align 1, i64)
declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)

!llvm.module.flags = !{}
