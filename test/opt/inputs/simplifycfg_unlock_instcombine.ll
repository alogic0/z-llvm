define i32 @simplifycfg_unlock_instcombine(i1 %cond, i32 %a) {
entry:
  br i1 %cond, label %then, label %else
then:
  br label %merge
else:
  br label %merge
merge:
  %v = phi i32 [ %a, %then ], [ %a, %else ]
  %x = add i32 %v, 0
  ret i32 %x
}
