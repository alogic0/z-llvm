define i32 @dce_volatile_load_reject(ptr %p) {
entry:
  %v = load volatile i32, ptr %p, align 4
  ret i32 0
}
