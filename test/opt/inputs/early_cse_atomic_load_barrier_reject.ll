define i32 @early_cse_atomic_load_barrier_reject(ptr %p) {
entry:
  %a = load atomic i32, ptr %p acquire, align 4
  %b = load atomic i32, ptr %p acquire, align 4
  %sum = add i32 %a, %b
  ret i32 %sum
}
