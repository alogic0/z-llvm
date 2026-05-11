define float @fp_fast_gvn(float %a, float %b, i1 %cond) {
entry:
  %x = fadd fast float %a, %b
  br i1 %cond, label %left, label %right
left:
  ret float %x
right:
  ret float %x
}
