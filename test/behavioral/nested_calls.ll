define i32 @leaf(i32 %x) {
entry:
  %q = sdiv i32 %x, 16
  ret i32 %q
}
define i32 @middle(i32 %x, i32 %y) {
entry:
  %q = call i32 @leaf(i32 %x)
  %r = xor i32 %q, %y
  ret i32 %r
}
define i32 @probe(i32 %x, i32 %y) {
entry:
  %a = call i32 @middle(i32 %x, i32 %y)
  %b = call i32 @leaf(i32 %y)
  %sum = add i32 %a, %b
  ret i32 %sum
}
