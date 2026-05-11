declare void @side_effect()

define i32 @simplifycfg_side_effect_diamond_reject(i1 %cond, i32 %a, i32 %b) {
entry:
  br i1 %cond, label %then, label %merge
then:
  call void @side_effect()
  br label %merge
merge:
  %v = phi i32 [ %a, %then ], [ %b, %entry ]
  ret i32 %v
}
