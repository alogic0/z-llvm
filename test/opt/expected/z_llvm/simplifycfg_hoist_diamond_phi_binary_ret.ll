define i32 @simplifycfg_hoist_diamond_phi_binary_ret(i1 %c, i32 %x) {
entry:
  %a = add i32 %x, 1
  %r = mul i32 %a, 2
  ret i32 %r
}
