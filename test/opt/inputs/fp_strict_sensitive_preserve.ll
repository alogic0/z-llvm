define float @fp_add_zero_strict(float %a) {
entry:
  %r = fadd float %a, 0.000000e+00
  ret float %r
}
