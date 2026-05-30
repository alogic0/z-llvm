define i32 @simplifycfg_hoist_two_inst_diamond_phi_ret(i1 %c, i32 %x) {
entry:
  %a = add i32 %x, 1
  %b = mul i32 %a, 3
  %c1 = add i32 %x, 1
  %d = mul i32 %c1, 3
  %p = select i1 %c, i32 %b, i32 %d
  ret i32 %p
}
