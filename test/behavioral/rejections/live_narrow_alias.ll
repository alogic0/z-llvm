define i32 @probe(i32 %x, i32 %y) {
entry:
  %a = add i32 %x, 1
  %b = xor i32 %a, %y
  %q = sdiv i32 %b, 8
  %n = trunc i32 %q to i16
  %wide = zext i16 %n to i32
  %s = ashr i32 %q, 2
  %u = lshr i32 %b, 3
  %t = add i32 %wide, %s
  %r = xor i32 %t, %u
  ret i32 %r
}