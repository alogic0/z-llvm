define i32 @gvn_scalar_pre_critical_edge(i1 %c, i1 %d, i32 %a, i32 %b) {
entry:
  br i1 %c, label %left, label %right
left:
  br i1 %d, label %left.join_crit_edge, label %exit
left.join_crit_edge:
  %.pre = add i32 %a, %b
  br label %join
right:
  %x = add i32 %a, %b
  br label %join
join:
  %y.pre-phi = phi i32 [ %.pre, %left.join_crit_edge ], [ %x, %right ]
  ret i32 %y.pre-phi
exit:
  ret i32 0
}
