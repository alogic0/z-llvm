define i32 @early_cse_unused_candidates(ptr %p, i32 %a, i32 %b) {
entry:
  %x = load i32, ptr %p
  %y = add i32 %a, %b
  ret i32 %a
}
