target triple = "x86_64-unknown-linux-gnu"
define float @fp_frame_polynomial_64_32(double %x) {
entry:
  %square = fmul double %x, %x
  %fourth = fmul double %square, %square
  %first = fadd double %x, %fourth
  %sum = fadd double %first, %square
  %answer = fptrunc double %sum to float
  ret float %answer
}
define double @fp_frame_polynomial_32_64(float %x) {
entry:
  %square = fmul float %x, %x
  %fourth = fmul float %square, %square
  %first = fadd float %x, %fourth
  %sum = fadd float %first, %square
  %answer = fpext float %sum to double
  ret double %answer
}
define double @fp_frame_two_inputs(double %a, double %b) {
entry:
  %square = fmul double %a, %a
  %sum = fadd double %a, %b
  %answer = fadd double %square, %sum
  ret double %answer
}
define double @fp_frame_dead_input(double %x) {
entry:
  %square = fmul double %x, %x
  ret double %square
}
