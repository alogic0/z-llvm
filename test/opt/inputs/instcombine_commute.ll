define i32 @commute(i32 %x) {
entry:
  %a = add i32 1, %x
  ret i32 %a
}
