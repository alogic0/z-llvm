define i32 @loop_deletion_dead_counted() #0 {
entry:
  br label %header

header:
  %i = phi i32 [ 0, %entry ], [ %inc, %latch ]
  %cond = icmp slt i32 %i, 10
  br i1 %cond, label %body, label %exit

body:
  br label %latch

latch:
  %inc = add i32 %i, 1
  br label %header

exit:
  ret i32 0
}

attributes #0 = { mustprogress }
