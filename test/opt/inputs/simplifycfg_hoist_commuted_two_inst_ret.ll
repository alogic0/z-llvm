define i32 @simplifycfg_hoist_commuted_two_inst_ret(i1 %c, i32 %x) {
entry:
  br i1 %c, label %left, label %right

left:
  %a = add i32 %x, 1
  %b = mul i32 3, %a
  ret i32 %b

right:
  %c1 = add i32 %x, 1
  %d = mul i32 %c1, 3
  ret i32 %d
}
