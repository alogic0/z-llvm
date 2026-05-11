define float @fp_extended_float(float %a, float %b) {
entry:
  %sub = fsub float %a, %b
  %div = fdiv float %sub, %b
  %rem = frem float %div, %a
  ret float %rem
}

define double @fp_extended_double(double %a, double %b) {
entry:
  %sub = fsub double %a, %b
  %div = fdiv double %sub, %b
  %rem = frem double %div, %a
  ret double %rem
}
