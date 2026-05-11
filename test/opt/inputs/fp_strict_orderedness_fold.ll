define i1 @fcmp_ord_constants() {
entry:
  %r = fcmp ord double 1.000000e+00, inf
  ret i1 %r
}

define i1 @fcmp_uno_nan() {
entry:
  %r = fcmp uno double nan, 1.000000e+00
  ret i1 %r
}

