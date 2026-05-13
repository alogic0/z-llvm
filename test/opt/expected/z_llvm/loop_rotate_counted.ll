define i32 @loop_rotate_counted(i32 %n) {
entry:
  %cond1 = icmp slt i32 0, %n
  br i1 %cond1, label %body.lr.ph, label %exit

body.lr.ph:
  br label %body

body:
  %i2 = phi i32 [ 0, %body.lr.ph ], [ %inc, %latch ]
  br label %latch

latch:
  %inc = add i32 %i2, 1
  %cond = icmp slt i32 %inc, %n
  br i1 %cond, label %body, label %header.exit_crit_edge

header.exit_crit_edge:
  %split = phi i32 [ %inc, %latch ]
  br label %exit

exit:
  %i.lcssa = phi i32 [ %split, %header.exit_crit_edge ], [ 0, %entry ]
  ret i32 %i.lcssa
}
