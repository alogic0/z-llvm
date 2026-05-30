define i32 @gvn_scalar_pre_reject(i1 %cond, i32 %a, i32 %b) {
entry:
  br i1 %cond, label %left, label %right
left:
  %x = add i32 %a, %b
  br label %join
right:
  %.pre = add i32 %a, %b
  br label %join
join:
  %y.pre-phi = phi i32 [ %.pre, %right ], [ %x, %left ]
  ret i32 %y.pre-phi
}
