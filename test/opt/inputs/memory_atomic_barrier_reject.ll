define i32 @memory_atomic_barrier_reject(i32 %a, ptr %p) {
entry:
  store atomic i32 %a, ptr %p release, align 4
  ret i32 %a
}
