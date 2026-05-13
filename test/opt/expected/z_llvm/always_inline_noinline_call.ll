define internal i32 @callee(i32 %x) #0 {
entry:
  %y = add i32 %x, 1
  ret i32 %y
}

define i32 @caller(i32 %a) {
entry:
  %r = call i32 @callee(i32 %a) #1
  ret i32 %r
}

attributes #0 = { alwaysinline }
attributes #1 = { noinline }
