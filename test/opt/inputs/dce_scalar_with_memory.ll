define i32 @dce_scalar_with_memory(i32 %a, ptr %p) {
entry:
  %dead = add i32 %a, 1
  %v = load i32, ptr %p, align 4
  store volatile i32 %a, ptr %p, align 4
  ret i32 %a
}
