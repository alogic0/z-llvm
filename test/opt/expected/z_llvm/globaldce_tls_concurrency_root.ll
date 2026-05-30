@tls_concurrency.tls_counter = private thread_local unnamed_addr global i32 1, align 4

@bump_tls = alias i32 (i32), ptr @tls_concurrency.bump_tls
@read_tls = alias i32 (), ptr @tls_concurrency.read_tls

define private i32 @tls_concurrency.bump_tls(i32 %0) unnamed_addr #0 align 1 {
entry:
  %2 = load i32, ptr @tls_concurrency.tls_counter, align 4
  %3 = add nsw i32 %2, %0
  store i32 %3, ptr @tls_concurrency.tls_counter, align 4
  ret i32 %3
}

define private i32 @tls_concurrency.read_tls() unnamed_addr #1 align 1 {
entry:
  %1 = load i32, ptr @tls_concurrency.tls_counter, align 4
  ret i32 %1
}

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(readwrite, argmem: none, inaccessiblemem: none, target_mem0: none, target_mem1: none) uwtable }
attributes #1 = { mustprogress nofree norecurse nosync nounwind willreturn memory(read, argmem: none, inaccessiblemem: none, target_mem0: none, target_mem1: none) uwtable }

!llvm.module.flags = !{}
