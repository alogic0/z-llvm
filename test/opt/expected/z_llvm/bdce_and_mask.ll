define i32 @bdce_and_mask(i32 %x) {
entry:
  %narrow = and i32 %x, 15
  ret i32 %narrow
}
