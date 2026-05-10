define i32 @commute(i32 %x) {
entry:
  %a = add i32 %x, 1
  ret i32 %a
}
