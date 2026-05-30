define i8 @lshr_constant() {
entry:
  %x = lshr i8 -2, 1
  ret i8 %x
}

define i8 @ashr_constant() {
entry:
  %x = ashr i8 -2, 1
  ret i8 %x
}

define i8 @lshr_exact_constant() {
entry:
  %x = lshr exact i8 3, 1
  ret i8 %x
}

define i8 @ashr_exact_constant() {
entry:
  %x = ashr exact i8 3, 1
  ret i8 %x
}
