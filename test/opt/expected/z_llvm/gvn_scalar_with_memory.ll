define i32 @gvn_scalar_with_memory(i32 %a, ptr %p) {
entry:
  %x = add i32 %a, 1
  store volatile i32 %a, ptr %p, align 4
  ret i32 %x
}
