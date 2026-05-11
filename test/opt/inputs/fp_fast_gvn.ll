define float @fp_fast_gvn(float %a, float %b, i1 %cond) {
entry:
  %x = fadd fast float %a, %b
  br i1 %cond, label %left, label %right
left:
  %y = fadd fast float %a, %b
  ret float %y
right:
  ret float %x
}
