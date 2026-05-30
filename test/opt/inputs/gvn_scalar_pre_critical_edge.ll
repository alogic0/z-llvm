define i32 @gvn_scalar_pre_critical_edge(i1 %c, i1 %d, i32 %a, i32 %b) {
entry:
  br i1 %c, label %left, label %right

left:
  br i1 %d, label %join, label %exit

right:
  %x = add i32 %a, %b
  br label %join

join:
  %y = add i32 %a, %b
  ret i32 %y

exit:
  ret i32 0
}
