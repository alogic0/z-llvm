define i32 @bdce_and_mask(i32 %x) {
entry:
  %wide = and i32 %x, 255
  %narrow = and i32 %wide, 15
  ret i32 %narrow
}
