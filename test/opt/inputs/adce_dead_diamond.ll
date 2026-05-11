define i32 @adce_dead_diamond(i1 %cond, i32 %a) {
entry:
  br i1 %cond, label %left, label %right
left:
  %x = add i32 %a, 1
  br label %exit
right:
  %y = add i32 %a, 2
  br label %exit
exit:
  ret i32 %a
}
