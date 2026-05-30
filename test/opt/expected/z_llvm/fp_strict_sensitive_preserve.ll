define float @fp_add_zero_strict(float %a) {
entry:
  %r = fadd float %a, 0.000000e+00
  ret float %r
}

define float @fp_sub_zero_strict(float %a) {
entry:
  ret float %a
}

define float @fp_mul_one_strict(float %a) {
entry:
  ret float %a
}

define float @fp_div_one_strict(float %a) {
entry:
  ret float %a
}

define i1 @fp_compare_self_strict(float %a) {
entry:
  %r = fcmp ord float %a, 0.000000e+00
  ret i1 %r
}
