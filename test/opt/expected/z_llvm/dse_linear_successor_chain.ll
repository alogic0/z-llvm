define void @dse_linear_successor_chain(ptr %p) {
entry:
  br label %mid
mid:
  br label %exit
exit:
  store i32 2, ptr %p
  ret void
}
