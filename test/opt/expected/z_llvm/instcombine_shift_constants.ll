define i8 @lshr_constant() {
entry:
  ret i8 127
}

define i8 @ashr_constant() {
entry:
  ret i8 -1
}

define i8 @lshr_exact_constant() {
entry:
  ret i8 1
}

define i8 @ashr_exact_constant() {
entry:
  ret i8 1
}
