define i32 @adce_dead_branch(i1 %cond, i32 %a) {
entry:
  br label %exit
then:
  br label %exit
exit:
  ret i32 %a
}
