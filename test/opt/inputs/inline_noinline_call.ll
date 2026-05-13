define internal i32 @inc_noinline(i32 %x) {
entry:
  %a = add i32 %x, 1
  ret i32 %a
}

define i32 @inline_noinline_call(i32 %x) {
entry:
  %y = call i32 @inc_noinline(i32 %x) #0
  ret i32 %y
}

attributes #0 = { noinline }
