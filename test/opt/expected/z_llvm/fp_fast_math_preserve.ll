define float @fp_fast_math_preserve(float %a, float %b) {
entry:
  %sum = fadd fast float %a, %b
  %product = fmul nnan ninf float %sum, %b
  %cmp = fcmp nnan ninf olt float %sum, %product
  %value = select i1 %cmp, float %sum, float %product
  ret float %value
}
