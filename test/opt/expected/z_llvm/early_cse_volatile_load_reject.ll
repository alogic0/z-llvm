define i32 @early_cse_volatile_load_reject(ptr %p) {
entry:
  %x = load volatile i32, ptr %p
  %y = load volatile i32, ptr %p
  ret i32 %y
}
