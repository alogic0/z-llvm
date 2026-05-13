define double @fadd_pos_zero_rhs() {
entry:
  %x = fadd double 2.000000e+00, 0.000000e+00
  ret double %x
}

define double @fadd_pos_zero_lhs() {
entry:
  %x = fadd double 0.000000e+00, 2.000000e+00
  ret double %x
}

define double @fmul_one_rhs() {
entry:
  %x = fmul double 2.000000e+00, 1.000000e+00
  ret double %x
}

define double @fmul_one_lhs() {
entry:
  %x = fmul double 1.000000e+00, 2.000000e+00
  ret double %x
}

define double @fmul_pos_zero() {
entry:
  %x = fmul double 0.000000e+00, 2.000000e+00
  ret double %x
}
