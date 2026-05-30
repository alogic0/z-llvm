define i32 @instcombine_unused_chain(ptr %p, i32 %a) {
entry:
  %l = load i32, ptr %p
  %x = add i32 %a, 1
  %y = add i32 %x, 2
  ret i32 %a
}
