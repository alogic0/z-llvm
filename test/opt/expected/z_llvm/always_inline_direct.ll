define i32 @caller(i32 %a) {
entry:
  %y.i = add i32 %a, 1
  ret i32 %y.i
}
