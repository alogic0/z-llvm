define i32 @indvars_derived_exit(i32 %n) {
entry:
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %inc, %loop ]
  %j = phi i32 [ 3, %entry ], [ %j.next, %loop ]
  %j.next = add i32 %j, 2
  %inc = add i32 %i, 1
  %cmp = icmp eq i32 %inc, %n
  br i1 %cmp, label %exit, label %loop

exit:
  ret i32 %j.next
}
