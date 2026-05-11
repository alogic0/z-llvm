define i32 @adce_dead_branch(i1 %cond, i32 %a) {
entry:
  br i1 %cond, label %then, label %exit
then:
  %x = add i32 %a, 1
  %y = mul i32 %x, 2
  br label %exit
exit:
  ret i32 %a
}
