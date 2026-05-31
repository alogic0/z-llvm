source_filename = "tls_concurrency"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

@tls_concurrency.tls_counter = private thread_local unnamed_addr global i32 1, align 4

@bump_tls = alias i32 (i32), ptr @tls_concurrency.bump_tls
@read_tls = alias i32 (), ptr @tls_concurrency.read_tls

define private i32 @tls_concurrency.bump_tls(i32 %0) unnamed_addr #0 align 1 {
1:
  %2 = load i32, ptr @tls_concurrency.tls_counter, align 4
  %3 = add nsw i32 %2, %0
  store i32 %3, ptr @tls_concurrency.tls_counter, align 4
  ret i32 %3
}

define private i32 @tls_concurrency.read_tls() unnamed_addr #1 align 1 {
0:
  %1 = load i32, ptr @tls_concurrency.tls_counter, align 4
  ret i32 %1
}

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(readwrite, argmem: none, inaccessiblemem: none, target_mem0: none, target_mem1: none) uwtable "frame-pointer"="all" "target-cpu"="x86-64" }
attributes #1 = { mustprogress nofree norecurse nosync nounwind willreturn memory(read, argmem: none, inaccessiblemem: none, target_mem0: none, target_mem1: none) uwtable "frame-pointer"="all" "target-cpu"="x86-64" }

!llvm.module.flags = !{}
