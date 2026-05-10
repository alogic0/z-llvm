define i32 @simplifycfg(i32 %a) {
entry:
  br i1 0, label %then, label %else
then:
  %dead = add i32 %a, 1
  ret i32 %dead
else:
  ret i32 %a
}
