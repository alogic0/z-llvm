define float @fp_add_zero_strict(float %a) {
entry:
  %r = fadd float %a, 0.000000e+00
  ret float %r
}

define float @fp_sub_zero_strict(float %a) {
entry:
  %r = fsub float %a, 0.000000e+00
  ret float %r
}

define float @fp_mul_one_strict(float %a) {
entry:
  %r = fmul float %a, 1.000000e+00
  ret float %r
}

define float @fp_div_one_strict(float %a) {
entry:
  %r = fdiv float %a, 1.000000e+00
  ret float %r
}

define i1 @fp_compare_self_strict(float %a) {
entry:
  %r = fcmp oeq float %a, %a
  ret i1 %r
}
