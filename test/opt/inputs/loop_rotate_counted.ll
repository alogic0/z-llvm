define i32 @loop_rotate_counted(i32 %n) {
entry:
  br label %header

header:
  %i = phi i32 [ 0, %entry ], [ %inc, %latch ]
  %cond = icmp slt i32 %i, %n
  br i1 %cond, label %body, label %exit

body:
  br label %latch

latch:
  %inc = add i32 %i, 1
  br label %header

exit:
  %i.lcssa = phi i32 [ %i, %header ]
  ret i32 %i.lcssa
}
