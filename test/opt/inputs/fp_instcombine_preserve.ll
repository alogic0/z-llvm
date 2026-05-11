define float @fp_instcombine_preserve(float %a, float %b) {
entry:
  %sum = fadd float %a, %b
  %product = fmul float %sum, %b
  ret float %product
}

define i1 @fp_instcombine_fcmp(float %a, float %b) {
entry:
  %cmp = fcmp oeq float %a, %b
  ret i1 %cmp
}
