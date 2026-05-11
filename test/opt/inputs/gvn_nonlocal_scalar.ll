define i32 @gvn_nonlocal_scalar(i1 %cond, i32 %a) {
entry:
  %x = add i32 %a, 7
  br i1 %cond, label %left, label %right
left:
  %y = add i32 %a, 7
  ret i32 %y
right:
  ret i32 %x
}
