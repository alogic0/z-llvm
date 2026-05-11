define double @fp_adce_dead(double %a, double %b) {
entry:
  %dead_sum = fadd double %a, %b
  %dead_product = fmul double %dead_sum, %b
  %dead_cmp = fcmp ord double %dead_product, %a
  ret double %a
}
