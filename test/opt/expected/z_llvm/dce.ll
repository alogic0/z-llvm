define i32 @dce(i32 %a) {
entry:
  %live = add i32 %a, 1
  ret i32 %live
}
