source_filename = "fast_math_cancellation"
target triple = "x86_64-unknown-linux-gnu"

define double @fast_cancel64(double %x) {
entry:
  %sum = fadd fast double %x, 0x4270000000000000
  %out = fsub fast double %sum, 0x4270000000000000
  ret double %out
}
define double @fast_commute64(double %x) {
entry:
  %sum = fadd fast double 0x4270000000000000, %x
  %out = fsub fast double %sum, 0x4270000000000000
  ret double %out
}
define double @fast_sub_add64(double %x) {
entry:
  %sum = fsub fast double %x, 0x4270000000000000
  %out = fadd fast double 0x4270000000000000, %sum
  ret double %out
}
define double @fast_shared64(double %x, ptr %snapshot) {
entry:
  %sum = fadd fast double %x, 0x4270000000000000
  store double %sum, ptr %snapshot, align 8
  %out = fsub fast double %sum, 0x4270000000000000
  ret double %out
}
define double @strict_cancel64(double %x) {
entry:
  %sum = fadd double %x, 0x4270000000000000
  %out = fsub double %sum, 0x4270000000000000
  ret double %out
}
define double @strict_inner64(double %x) {
entry:
  %sum = fadd fast double %x, 0x4270000000000000
  %out = fsub double %sum, 0x4270000000000000
  ret double %out
}
define double @partial_outer64(double %x) {
entry:
  %sum = fadd double %x, 0x4270000000000000
  %out = fsub nnan ninf nsz double %sum, 0x4270000000000000
  ret double %out
}
define float @fast_cancel32(float %x) {
entry:
  %sum = fadd fast float %x, 0x4170000000000000
  %out = fsub fast float %sum, 0x4170000000000000
  ret float %out
}
define float @strict_cancel32(float %x) {
entry:
  %sum = fadd float %x, 0x4170000000000000
  %out = fsub float %sum, 0x4170000000000000
  ret float %out
}
