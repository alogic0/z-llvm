define i32 @gvn_scalar_pre_reject(i1 %cond, i32 %a, i32 %b) {
entry:
  br i1 %cond, label %left, label %right
left:
  %x = add i32 %a, %b
  br label %join
right:
  br label %join
join:
  %y = add i32 %a, %b
  ret i32 %y
}
