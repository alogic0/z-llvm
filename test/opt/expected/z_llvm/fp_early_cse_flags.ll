define float @fp_strict_early_cse(float %a, float %b) {
entry:
  %x = fadd float %a, %b
  %z = fmul float %x, %x
  ret float %z
}

define float @fp_partial_early_cse(float %a, float %b) {
entry:
  %x = fadd nnan float %a, %b
  %z = fmul float %x, %x
  ret float %z
}

define float @fp_mixed_early_cse(float %a, float %b) {
entry:
  %x = fadd float %a, %b
  %z = fmul float %x, %x
  ret float %z
}
