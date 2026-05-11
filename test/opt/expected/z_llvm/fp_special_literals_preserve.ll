define double @nan_literal() {
entry:
  ret double nan
}

define double @inf_literal() {
entry:
  ret double inf
}

define double @negative_zero_literal() {
entry:
  ret double -0.0
}

