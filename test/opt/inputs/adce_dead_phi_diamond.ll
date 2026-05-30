define i32 @adce_dead_phi_diamond(i1 %cond, i32 %a) {
entry:
  br i1 %cond, label %left, label %right
left:
  %x = add i32 %a, 1
  br label %join
right:
  %y = add i32 %a, 2
  br label %join
join:
  %z = phi i32 [ %x, %left ], [ %y, %right ]
  ret i32 0
}
