define i32 @simplifycfg_diamond_select_prof(i1 %cond, i32 %a, i32 %b) {
entry:
  %a.b = select i1 %cond, i32 %a, i32 %b, !prof !0
  ret i32 %a.b
}

!0 = !{!"branch_weights", i32 99, i32 1}

