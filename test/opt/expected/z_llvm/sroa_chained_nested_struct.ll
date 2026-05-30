define i32 @sroa_chained_nested_struct(i32 %a, i32 %b, i32 %c) {
entry:
  %xy = add i32 %a, %b
  %sum = add i32 %xy, %c
  ret i32 %sum
}
