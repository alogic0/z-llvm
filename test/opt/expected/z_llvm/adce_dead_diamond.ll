define i32 @adce_dead_diamond(i1 %cond, i32 %a) {
entry:
  br label %left
left:
  br label %exit
right:
  br label %exit
exit:
  ret i32 %a
}
