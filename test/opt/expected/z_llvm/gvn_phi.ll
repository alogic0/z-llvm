define i32 @gvn_phi(i1 %cond, i32 %a, i32 %b) {
entry:
  br i1 %cond, label %left, label %right
left:
  br label %join
right:
  br label %join
join:
  %p0 = phi i32 [ %a, %left ], [ %b, %right ]
  ret i32 %p0
}
