define internal i32 @callee(i32 %x) alwaysinline {
entry:
  %y = add i32 %x, 1
  ret i32 %y
}

define i32 @caller(i32 %a) {
entry:
  %r = call i32 @callee(i32 %a)
  ret i32 %r
}
