define i32 @dead_chain(i32 %x) {
entry:
  %a = add i32 %x, 1
  %b = mul i32 %a, 2
  %c = sub i32 %b, %x
  ret i32 %x
}
