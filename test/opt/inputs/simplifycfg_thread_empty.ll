define i32 @thread_empty(i1 %c, i32 %x) {
entry:
  br i1 %c, label %mid, label %exit
mid:
  br label %exit
exit:
  ret i32 %x
}
