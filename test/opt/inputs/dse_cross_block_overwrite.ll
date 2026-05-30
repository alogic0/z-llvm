define void @dse_cross_block_overwrite(ptr %p, i32 %a, i32 %b) {
entry:
  store i32 %a, ptr %p
  br label %next
next:
  store i32 %b, ptr %p
  ret void
}
