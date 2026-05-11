define double @fp_early_cse_no_cse(double %a, double %b) {
entry:
  %one = fmul double %a, %b
  %two = fmul double %a, %b
  %cmp1 = fcmp ugt double %a, %b
  %cmp2 = fcmp ugt double %a, %b
  %value = select i1 %cmp2, double %one, double %two
  ret double %value
}
