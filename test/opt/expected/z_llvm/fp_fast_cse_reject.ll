define float @fp_nnan_not_cse(float %a, float %b) {
entry:
  %x = fadd nnan float %a, %b
  ret float %x
}
