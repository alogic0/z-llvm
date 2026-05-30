define i32 @simplifycfg_hoist_commuted_diamond_phi_ret(i1 %c, i32 %x) {
entry:
  %a = add i32 %x, 1
  ret i32 %a
}
