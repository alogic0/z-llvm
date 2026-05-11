define i1 @fcmp_false(float %a, float %b) {
entry:
  %r = fcmp false float %a, %b
  ret i1 %r
}

define i1 @fcmp_true(float %a, float %b) {
entry:
  %r = fcmp true float %a, %b
  ret i1 %r
}

