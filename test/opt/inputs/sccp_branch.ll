define i32 @sccp_branch(i32 %a) {
entry:
  %cond = icmp eq i32 1, 1
  br i1 %cond, label %then, label %else
then:
  ret i32 %a
else:
  ret i32 0
}
