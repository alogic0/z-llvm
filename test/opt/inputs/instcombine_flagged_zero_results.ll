define i8 @mul_zero_nsw(i8 %x) {
entry:
  %m = mul nsw i8 %x, 0
  ret i8 %m
}

define i8 @mul_zero_nuw(i8 %x) {
entry:
  %m = mul nuw i8 0, %x
  ret i8 %m
}

define i8 @shl_zero_nsw(i8 %x) {
entry:
  %s = shl nsw i8 0, %x
  ret i8 %s
}

define i8 @shl_zero_nuw(i8 %x) {
entry:
  %s = shl nuw i8 0, %x
  ret i8 %s
}

define i8 @lshr_zero_exact(i8 %x) {
entry:
  %s = lshr exact i8 0, %x
  ret i8 %s
}

define i8 @ashr_zero_exact(i8 %x) {
entry:
  %s = ashr exact i8 0, %x
  ret i8 %s
}
