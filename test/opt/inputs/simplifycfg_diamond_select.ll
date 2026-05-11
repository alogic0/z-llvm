define i32 @simplifycfg_diamond_select(i1 %cond, i32 %a, i32 %b) {
entry:
  br i1 %cond, label %then, label %else
then:
  br label %merge
else:
  br label %merge
merge:
  %v = phi i32 [ %a, %then ], [ %b, %else ]
  ret i32 %v
}
