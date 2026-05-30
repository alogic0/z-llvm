define i32 @simplifycfg_hoist_diamond_phi_ret(i1 %c, i32 %x) {
entry:
  br i1 %c, label %left, label %right

left:
  %a = add i32 %x, 1
  br label %merge

right:
  %b = add i32 %x, 1
  br label %merge

merge:
  %p = phi i32 [ %a, %left ], [ %b, %right ]
  ret i32 %p
}
