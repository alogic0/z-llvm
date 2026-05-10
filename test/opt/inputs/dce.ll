define i32 @dce(i32 %a) {
entry:
  %live = add i32 %a, 1
  %dead = mul i32 %a, 4
  ret i32 %live
}
