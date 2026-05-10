define i32 @simplifycfg(i32 %a) {
entry:
  br label %else
else:
  ret i32 %a
}
