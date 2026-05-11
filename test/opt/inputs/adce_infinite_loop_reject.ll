define void @adce_infinite_loop_reject(i1 %cond) {
entry:
  br i1 %cond, label %loop, label %exit
loop:
  br label %loop
exit:
  ret void
}
