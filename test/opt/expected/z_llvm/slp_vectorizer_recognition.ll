define i32 @slp_seed(i32 %a, i32 %b, i32 %c, i32 %d) {
entry:
  %x0 = add i32 %a, %b
  %x1 = add i32 %c, %d
  %sum = add i32 %x0, %x1
  ret i32 %sum
}

