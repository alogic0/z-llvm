define double @fp_sccp_fadd_nsz_zero() {
entry:
  ret double 1.000000e+00
}

define i32 @fp_sccp_constant_branch() {
entry:
  br label %then
then:
  ret i32 1
}
