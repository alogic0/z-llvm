define i32 @unreachable_simplifycfg(i1 %cond, i32 %a) {
entry:
  br i1 0, label %live, label %trap
live:
  ret i32 %a
trap:
  unreachable
}
