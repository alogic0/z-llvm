define i32 @simplifycfg_hoist_same_add_ret(i1 %c, i32 %x) {
entry:
  br i1 %c, label %left, label %right

left:
  %a = add i32 %x, 1
  ret i32 %a

right:
  %b = add i32 %x, 1
  ret i32 %b
}
