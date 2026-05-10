define i32 @instcombine(i32 %a) {
entry:
  %x = add i32 %a, 0
  %y = mul i32 %x, 1
  ret i32 %y
}
