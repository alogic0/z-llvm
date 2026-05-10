define i32 @dce_scalar_with_memory(i32 %a, ptr %p) {
entry:
  store volatile i32 %a, ptr %p, align 4
  ret i32 %a
}
