define i1 @fcmp_oeq_true() {
entry:
  ret i1 1
}

define i1 @fcmp_olt_true() {
entry:
  ret i1 1
}

define i1 @fcmp_ogt_false() {
entry:
  ret i1 0
}

define i1 @fcmp_uno_nan() {
entry:
  ret i1 1
}

define i1 @fcmp_oeq_nan_false() {
entry:
  ret i1 0
}

define i1 @fcmp_une_nan_true() {
entry:
  ret i1 1
}
