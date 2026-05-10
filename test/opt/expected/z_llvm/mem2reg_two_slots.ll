define i32 @mem2reg_two_slots(i1 %cond, i32 %a, i32 %b, i32 %c, i32 %d) {
entry:
  br i1 %cond, label %left, label %right
left:
  br label %merge
right:
  br label %merge
merge:
  %y.0 = phi i32 [ %b, %left ], [ %d, %right ]
  %x.0 = phi i32 [ %a, %left ], [ %c, %right ]
  %sum = add i32 %x.0, %y.0
  ret i32 %sum
}
