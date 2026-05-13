define internal i32 @inc(i32 %x) {
entry:
  %a = add i32 %x, 1
  ret i32 %a
}

define i32 @inline_direct_small(i32 %x) {
entry:
  %y = call i32 @inc(i32 %x)
  ret i32 %y
}
