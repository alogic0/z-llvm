define i32 @licm_promote_stack(i32 %n) {
entry:
  %slot = alloca i32
  store i32 0, ptr %slot
  %slot.promoted = load i32, ptr %slot
  br label %loop

loop:
  %inc1 = phi i32 [ %slot.promoted, %entry ], [ %inc, %loop ]
  %i = phi i32 [ 0, %entry ], [ %i.next, %loop ]
  %inc = add i32 %inc1, 1
  %i.next = add i32 %i, 1
  %cmp = icmp eq i32 %i.next, %n
  br i1 %cmp, label %exit, label %loop

exit:
  %inc.lcssa = phi i32 [ %inc, %loop ]
  store i32 %inc.lcssa, ptr %slot
  %out = load i32, ptr %slot
  ret i32 %out
}
