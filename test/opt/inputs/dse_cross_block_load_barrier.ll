define i32 @dse_cross_block_load_barrier(ptr %p, i32 %a, i32 %b) {
entry:
  store i32 %a, ptr %p
  br label %next
next:
  %v = load i32, ptr %p
  store i32 %b, ptr %p
  ret i32 %v
}
