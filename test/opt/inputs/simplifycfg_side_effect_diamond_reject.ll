declare void @side_effect()

define i32 @simplifycfg_side_effect_diamond_reject(i1 %cond, i32 %a, i32 %b) {
entry:
  br i1 %cond, label %then, label %else
then:
  call void @side_effect()
  br label %merge
else:
  br label %merge
merge:
  %v = phi i32 [ %a, %then ], [ %b, %else ]
  ret i32 %v
}
