define i32 @mem2reg_if(i1 %cond, i32 %a, i32 %b) {
entry:
  br i1 %cond, label %left, label %right
left:
  br label %merge
right:
  br label %merge
merge:
  %slot.0 = phi i32 [ %a, %left ], [ %b, %right ]
  ret i32 %slot.0
}
