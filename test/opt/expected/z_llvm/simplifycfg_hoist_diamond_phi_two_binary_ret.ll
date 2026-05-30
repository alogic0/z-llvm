define i32 @simplifycfg_hoist_diamond_phi_two_binary_ret(i1 %c, i32 %x) {
entry:
  %a = add i32 %x, 1
  %r = mul i32 %a, 2
  %s = add i32 %r, 4
  ret i32 %s
}
