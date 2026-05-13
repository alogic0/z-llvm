define i32 @simplifycfg_same_target_phi(i1 %cond, i32 %a) {
entry:
  br i1 %cond, label %merge, label %merge
merge:
  %v = phi i32 [ %a, %entry ], [ %a, %entry ]
  ret i32 %v
}
