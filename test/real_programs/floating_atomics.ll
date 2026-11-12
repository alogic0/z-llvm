target triple = "x86_64-unknown-linux-gnu"
define i64 @floating_atomic_add_32(ptr %p, i64 %input, ptr %out, i64 %salt) {
entry:
  %low = trunc i64 %input to i32
  %value = bitcast i32 %low to float
  %old = atomicrmw volatile fadd ptr %p, float %value seq_cst, align 4
  %old_bits = bitcast float %old to i32
  %wide = zext i32 %old_bits to i64
  store i64 %wide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input, %salt
  store i64 %live, ptr %next
  ret i64 %wide
}
define i64 @floating_atomic_sub_32(ptr %p, i64 %input, ptr %out, i64 %salt) {
entry:
  %low = trunc i64 %input to i32
  %value = bitcast i32 %low to float
  %old = atomicrmw volatile fsub ptr %p, float %value seq_cst, align 4
  %old_bits = bitcast float %old to i32
  %wide = zext i32 %old_bits to i64
  store i64 %wide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input, %salt
  store i64 %live, ptr %next
  ret i64 %wide
}
define i64 @floating_atomic_max_32(ptr %p, i64 %input, ptr %out, i64 %salt) {
entry:
  %low = trunc i64 %input to i32
  %value = bitcast i32 %low to float
  %old = atomicrmw volatile fmax ptr %p, float %value seq_cst, align 4
  %old_bits = bitcast float %old to i32
  %wide = zext i32 %old_bits to i64
  store i64 %wide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input, %salt
  store i64 %live, ptr %next
  ret i64 %wide
}
define i64 @floating_atomic_min_32(ptr %p, i64 %input, ptr %out, i64 %salt) {
entry:
  %low = trunc i64 %input to i32
  %value = bitcast i32 %low to float
  %old = atomicrmw volatile fmin ptr %p, float %value seq_cst, align 4
  %old_bits = bitcast float %old to i32
  %wide = zext i32 %old_bits to i64
  store i64 %wide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input, %salt
  store i64 %live, ptr %next
  ret i64 %wide
}
define i64 @floating_atomic_add_64(ptr %p, i64 %input, ptr %out, i64 %salt) {
entry:
  %value = bitcast i64 %input to double
  %old = atomicrmw volatile fadd ptr %p, double %value seq_cst, align 8
  %wide = bitcast double %old to i64
  store i64 %wide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input, %salt
  store i64 %live, ptr %next
  ret i64 %wide
}
define i64 @floating_atomic_sub_64(ptr %p, i64 %input, ptr %out, i64 %salt) {
entry:
  %value = bitcast i64 %input to double
  %old = atomicrmw volatile fsub ptr %p, double %value seq_cst, align 8
  %wide = bitcast double %old to i64
  store i64 %wide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input, %salt
  store i64 %live, ptr %next
  ret i64 %wide
}
define i64 @floating_atomic_max_64(ptr %p, i64 %input, ptr %out, i64 %salt) {
entry:
  %value = bitcast i64 %input to double
  %old = atomicrmw volatile fmax ptr %p, double %value seq_cst, align 8
  %wide = bitcast double %old to i64
  store i64 %wide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input, %salt
  store i64 %live, ptr %next
  ret i64 %wide
}
define i64 @floating_atomic_min_64(ptr %p, i64 %input, ptr %out, i64 %salt) {
entry:
  %value = bitcast i64 %input to double
  %old = atomicrmw volatile fmin ptr %p, double %value seq_cst, align 8
  %wide = bitcast double %old to i64
  store i64 %wide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input, %salt
  store i64 %live, ptr %next
  ret i64 %wide
}
