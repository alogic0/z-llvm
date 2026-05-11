define i32 @dse_volatile_barrier(i32 %a, i32 %b, ptr %p) {
entry:
  store i32 %a, ptr %p
  %v = load volatile i32, ptr %p, align 4
  store i32 %b, ptr %p
  ret i32 %b
}

