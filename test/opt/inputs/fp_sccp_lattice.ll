define double @fp_sccp_fadd_nsz_zero() {
entry:
  %x = fadd nsz double 1.000000e+00, 0.000000e+00
  ret double %x
}

define i32 @fp_sccp_constant_branch() {
entry:
  %x = fadd nsz double 1.000000e+00, 0.000000e+00
  %cmp = fcmp ord double %x, 2.000000e+00
  br i1 %cmp, label %then, label %else
then:
  ret i32 1
else:
  ret i32 2
}
