define void @dse_atomic_store_barrier_reject(ptr %p, i32 %v) {
entry:
  store atomic i32 1, ptr %p, release, align 4
  store i32 %v, ptr %p, align 4
  ret void
}
