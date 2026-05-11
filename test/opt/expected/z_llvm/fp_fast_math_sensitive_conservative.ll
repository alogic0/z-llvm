define float @fp_fast_add_zero(float %a) {
entry:
  %r = fadd nsz float %a, 0.000000e+00
  ret float %r
}

define i1 @fp_fast_compare_self(float %a) {
entry:
  %r = fcmp nnan oeq float %a, %a
  ret i1 %r
}

define float @fp_mul_one_local_conservative(float %a) {
entry:
  %r = fmul float %a, 1.000000e+00
  ret float %r
}

define i1 @fp_compare_self_local_conservative(float %a) {
entry:
  %r = fcmp oeq float %a, %a
  ret i1 %r
}
