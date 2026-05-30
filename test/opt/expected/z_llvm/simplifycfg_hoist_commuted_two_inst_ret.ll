define i32 @simplifycfg_hoist_commuted_two_inst_ret(i1 %c, i32 %x) {
entry:
  %a = add i32 %x, 1
  %b = mul i32 3, %a
  %c1 = add i32 %x, 1
  %d = mul i32 %c1, 3
  %common.ret.op = select i1 %c, i32 %b, i32 %d
  ret i32 %common.ret.op
}
