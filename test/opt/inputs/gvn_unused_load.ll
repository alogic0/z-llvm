define i32 @gvn_unused_load(ptr %p) {
entry:
  %x = load i32, ptr %p
  ret i32 0
}
