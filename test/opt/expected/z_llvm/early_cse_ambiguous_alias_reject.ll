define i32 @early_cse_ambiguous_alias_reject(i32 %a, ptr %p, ptr %q) {
entry:
  store i32 %a, ptr %p
  %x = load i32, ptr %q
  ret i32 %x
}
