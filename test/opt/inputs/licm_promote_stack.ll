define i32 @licm_promote_stack(i32 %n) {
entry:
  %slot = alloca i32
  store i32 0, ptr %slot
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i.next, %loop ]
  %v = load i32, ptr %slot
  %inc = add i32 %v, 1
  store i32 %inc, ptr %slot
  %i.next = add i32 %i, 1
  %cmp = icmp eq i32 %i.next, %n
  br i1 %cmp, label %exit, label %loop

exit:
  %out = load i32, ptr %slot
  ret i32 %out
}
