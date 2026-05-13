define float @fp_strict_gvn(float %a, float %b) {
entry:
  %x = fadd float %a, %b
  ret float %x
}

define float @fp_partial_gvn(float %a, float %b) {
entry:
  %x = fadd nnan float %a, %b
  ret float %x
}

define float @fp_mixed_gvn(float %a, float %b) {
entry:
  %x = fadd float %a, %b
  ret float %x
}
