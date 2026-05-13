define double @fp_early_cse_no_cse(double %a, double %b) {
entry:
  %one = fmul double %a, %b
  %cmp1 = fcmp ugt double %a, %b
  %value = select i1 %cmp1, double %one, double %one
  ret double %value
}
