define double @fp_sccp_preserve(double %a, double %b, i1 %flag) {
entry:
  %sum = fadd double %a, %b
  %product = fmul double %sum, %b
  %value = select i1 %flag, double %sum, double %product
  ret double %value
}

define i1 @fp_sccp_fcmp(double %a, double %b) {
entry:
  %cmp = fcmp une double %a, %b
  ret i1 %cmp
}
