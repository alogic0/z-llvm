define float @fp_nnan_not_cse(float %a, float %b) {
entry:
  %y = fadd nnan float %a, %b
  ret float %y
}
