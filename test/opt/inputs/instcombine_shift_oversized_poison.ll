define i8 @shl_oversized() {
entry:
  %x = shl i8 1, 8
  ret i8 %x
}

define i8 @lshr_oversized() {
entry:
  %x = lshr i8 1, 8
  ret i8 %x
}

define i8 @ashr_oversized() {
entry:
  %x = ashr i8 1, 8
  ret i8 %x
}
