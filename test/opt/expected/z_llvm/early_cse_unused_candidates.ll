define i32 @early_cse_unused_candidates(ptr %p, i32 %a, i32 %b) {
entry:
  ret i32 %a
}
