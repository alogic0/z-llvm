define i32 @simplifycfg_diamond_select(i1 %cond, i32 %a, i32 %b) {
entry:
  %a.b = select i1 %cond, i32 %a, i32 %b
  ret i32 %a.b
}
