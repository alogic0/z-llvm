define float @fp_gvn_no_cse(float %a, float %b) {
entry:
  %one = fadd float %a, %b
  %two = fadd float %a, %b
  %cmp1 = fcmp olt float %a, %b
  %cmp2 = fcmp olt float %a, %b
  %value = select i1 %cmp2, float %one, float %two
  ret float %value
}
