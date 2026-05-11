define i8 @instcombine_flagged_overflow_reject() {
entry:
  %x = add nsw i8 120, 10
  ret i8 %x
}
