define float @fp_fast_early_cse(float %a, float %b) {
entry:
  %y = fadd fast float %a, %b
  ret float %y
}
