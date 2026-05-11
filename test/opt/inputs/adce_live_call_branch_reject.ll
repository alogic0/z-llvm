declare void @side_effect()

define void @adce_live_call_branch_reject(i1 %cond) {
entry:
  br i1 %cond, label %then, label %exit
then:
  call void @side_effect()
  br label %exit
exit:
  ret void
}
