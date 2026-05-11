define void @adce_store_branch_reject(i1 %cond, ptr %p) {
entry:
  br i1 %cond, label %then, label %exit
then:
  store i32 1, ptr %p
  br label %exit
exit:
  ret void
}
