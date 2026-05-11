define float @fp_fast_early_cse(float %a, float %b) {
entry:
  %x = fadd fast float %a, %b
  %y = fadd fast float %a, %b
  ret float %y
}
