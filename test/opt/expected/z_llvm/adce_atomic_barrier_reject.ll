define void @adce_atomic_barrier_reject(ptr %p, i32 %v) {
entry:
  store atomic i32 %v, ptr %p release, align 4
  ret void
}
