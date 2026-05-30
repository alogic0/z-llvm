define i32 @bdce_unused_chain(ptr %p, i32 %a) {
entry:
  %l = load i32, ptr %p
  %x = add i32 %a, 1
  %y = xor i32 %x, 7
  ret i32 %a
}
