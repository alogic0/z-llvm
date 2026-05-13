define float @fp_strict_early_cse(float %a, float %b) {
entry:
  %x = fadd float %a, %b
  %y = fadd float %a, %b
  %z = fmul float %x, %y
  ret float %z
}

define float @fp_partial_early_cse(float %a, float %b) {
entry:
  %x = fadd nnan float %a, %b
  %y = fadd nnan float %a, %b
  %z = fmul float %x, %y
  ret float %z
}

define float @fp_mixed_early_cse(float %a, float %b) {
entry:
  %x = fadd nnan float %a, %b
  %y = fadd ninf float %a, %b
  %z = fmul float %x, %y
  ret float %z
}
