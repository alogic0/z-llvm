define i32 @probe(i32 %x, i32 %y) {
entry:
  %a = add i32 %x, 1
  %b = xor i32 %a, %y
  %q = sdiv i32 %b, 8
  %n = trunc i32 %q to i16
  %wide = sext i16 %n to i32
  %s = ashr i32 %wide, 2
  %u = lshr i32 %b, 3
  %r = xor i32 %s, %u
  ret i32 %r
}