define float @fp_dce_dead(float %a, float %b) {
entry:
  %dead_sum = fadd float %a, %b
  %dead_product = fmul float %a, %b
  %dead_cmp = fcmp olt float %a, %b
  ret float %a
}
