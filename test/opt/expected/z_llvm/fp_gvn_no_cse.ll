define float @fp_gvn_no_cse(float %a, float %b) {
entry:
  %one = fadd float %a, %b
  %cmp1 = fcmp olt float %a, %b
  %value = select i1 %cmp1, float %one, float %one
  ret float %value
}
