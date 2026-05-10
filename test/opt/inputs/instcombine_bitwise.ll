define i32 @bitwise_identities(i32 %x) {
entry:
  %a = and i32 %x, -1
  %b = or i32 %a, 0
  %c = xor i32 %b, 0
  %d = shl i32 %c, 0
  %e = lshr i32 %d, 0
  %f = ashr i32 %e, 0
  ret i32 %f
}
