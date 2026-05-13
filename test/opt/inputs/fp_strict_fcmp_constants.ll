define i1 @fcmp_oeq_true() {
entry:
  %c = fcmp oeq double 1.000000e+00, 1.000000e+00
  ret i1 %c
}

define i1 @fcmp_olt_true() {
entry:
  %c = fcmp olt double 1.000000e+00, 2.000000e+00
  ret i1 %c
}

define i1 @fcmp_ogt_false() {
entry:
  %c = fcmp ogt double 1.000000e+00, 2.000000e+00
  ret i1 %c
}

define i1 @fcmp_uno_nan() {
entry:
  %c = fcmp uno double 0x7FF8000000000000, 1.000000e+00
  ret i1 %c
}

define i1 @fcmp_oeq_nan_false() {
entry:
  %c = fcmp oeq double 0x7FF8000000000000, 0x7FF8000000000000
  ret i1 %c
}

define i1 @fcmp_une_nan_true() {
entry:
  %c = fcmp une double 0x7FF8000000000000, 1.000000e+00
  ret i1 %c
}
