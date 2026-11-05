target triple = "x86_64-unknown-linux-gnu"

declare void @comparison_clobber()

define i64 @compare_1_ne(i64 %a, i64 %b, ptr %out) {
entry:
  %x = trunc i64 %a to i1
  %y = trunc i64 %b to i1
  %c = icmp ne i1 %x, %y
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_1_ule(i64 %a, i64 %b, ptr %out) {
entry:
  %x = trunc i64 %a to i1
  %y = trunc i64 %b to i1
  %c = icmp ule i1 %x, %y
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_1_uge(i64 %a, i64 %b, ptr %out) {
entry:
  %x = trunc i64 %a to i1
  %y = trunc i64 %b to i1
  %c = icmp uge i1 %x, %y
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_1_sle(i64 %a, i64 %b, ptr %out) {
entry:
  %x = trunc i64 %a to i1
  %y = trunc i64 %b to i1
  %c = icmp sle i1 %x, %y
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_1_sge(i64 %a, i64 %b, ptr %out) {
entry:
  %x = trunc i64 %a to i1
  %y = trunc i64 %b to i1
  %c = icmp sge i1 %x, %y
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_1_reverse(i64 %a, i64 %b, ptr %out) {
entry:
  %x = trunc i64 %a to i1
  %y = trunc i64 %b to i1
  %c = icmp ule i1 1, %x
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_6_ne(i64 %a, i64 %b, ptr %out) {
entry:
  %x = trunc i64 %a to i6
  %y = trunc i64 %b to i6
  %c = icmp ne i6 %x, %y
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_6_ule(i64 %a, i64 %b, ptr %out) {
entry:
  %x = trunc i64 %a to i6
  %y = trunc i64 %b to i6
  %c = icmp ule i6 %x, %y
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_6_uge(i64 %a, i64 %b, ptr %out) {
entry:
  %x = trunc i64 %a to i6
  %y = trunc i64 %b to i6
  %c = icmp uge i6 %x, %y
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_6_sle(i64 %a, i64 %b, ptr %out) {
entry:
  %x = trunc i64 %a to i6
  %y = trunc i64 %b to i6
  %c = icmp sle i6 %x, %y
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_6_sge(i64 %a, i64 %b, ptr %out) {
entry:
  %x = trunc i64 %a to i6
  %y = trunc i64 %b to i6
  %c = icmp sge i6 %x, %y
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_6_reverse(i64 %a, i64 %b, ptr %out) {
entry:
  %x = trunc i64 %a to i6
  %y = trunc i64 %b to i6
  %c = icmp ule i6 32, %x
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_8_ne(i64 %a, i64 %b, ptr %out) {
entry:
  %x = trunc i64 %a to i8
  %y = trunc i64 %b to i8
  %c = icmp ne i8 %x, %y
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_8_ule(i64 %a, i64 %b, ptr %out) {
entry:
  %x = trunc i64 %a to i8
  %y = trunc i64 %b to i8
  %c = icmp ule i8 %x, %y
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_8_uge(i64 %a, i64 %b, ptr %out) {
entry:
  %x = trunc i64 %a to i8
  %y = trunc i64 %b to i8
  %c = icmp uge i8 %x, %y
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_8_sle(i64 %a, i64 %b, ptr %out) {
entry:
  %x = trunc i64 %a to i8
  %y = trunc i64 %b to i8
  %c = icmp sle i8 %x, %y
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_8_sge(i64 %a, i64 %b, ptr %out) {
entry:
  %x = trunc i64 %a to i8
  %y = trunc i64 %b to i8
  %c = icmp sge i8 %x, %y
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_8_reverse(i64 %a, i64 %b, ptr %out) {
entry:
  %x = trunc i64 %a to i8
  %y = trunc i64 %b to i8
  %c = icmp ule i8 128, %x
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_16_ne(i64 %a, i64 %b, ptr %out) {
entry:
  %x = trunc i64 %a to i16
  %y = trunc i64 %b to i16
  %c = icmp ne i16 %x, %y
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_16_ule(i64 %a, i64 %b, ptr %out) {
entry:
  %x = trunc i64 %a to i16
  %y = trunc i64 %b to i16
  %c = icmp ule i16 %x, %y
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_16_uge(i64 %a, i64 %b, ptr %out) {
entry:
  %x = trunc i64 %a to i16
  %y = trunc i64 %b to i16
  %c = icmp uge i16 %x, %y
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_16_sle(i64 %a, i64 %b, ptr %out) {
entry:
  %x = trunc i64 %a to i16
  %y = trunc i64 %b to i16
  %c = icmp sle i16 %x, %y
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_16_sge(i64 %a, i64 %b, ptr %out) {
entry:
  %x = trunc i64 %a to i16
  %y = trunc i64 %b to i16
  %c = icmp sge i16 %x, %y
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_16_reverse(i64 %a, i64 %b, ptr %out) {
entry:
  %x = trunc i64 %a to i16
  %y = trunc i64 %b to i16
  %c = icmp ule i16 32768, %x
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_31_ne(i64 %a, i64 %b, ptr %out) {
entry:
  %x = trunc i64 %a to i31
  %y = trunc i64 %b to i31
  %c = icmp ne i31 %x, %y
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_31_ule(i64 %a, i64 %b, ptr %out) {
entry:
  %x = trunc i64 %a to i31
  %y = trunc i64 %b to i31
  %c = icmp ule i31 %x, %y
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_31_uge(i64 %a, i64 %b, ptr %out) {
entry:
  %x = trunc i64 %a to i31
  %y = trunc i64 %b to i31
  %c = icmp uge i31 %x, %y
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_31_sle(i64 %a, i64 %b, ptr %out) {
entry:
  %x = trunc i64 %a to i31
  %y = trunc i64 %b to i31
  %c = icmp sle i31 %x, %y
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_31_sge(i64 %a, i64 %b, ptr %out) {
entry:
  %x = trunc i64 %a to i31
  %y = trunc i64 %b to i31
  %c = icmp sge i31 %x, %y
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_31_reverse(i64 %a, i64 %b, ptr %out) {
entry:
  %x = trunc i64 %a to i31
  %y = trunc i64 %b to i31
  %c = icmp ule i31 1073741824, %x
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_32_ne(i64 %a, i64 %b, ptr %out) {
entry:
  %x = trunc i64 %a to i32
  %y = trunc i64 %b to i32
  %c = icmp ne i32 %x, %y
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_32_ule(i64 %a, i64 %b, ptr %out) {
entry:
  %x = trunc i64 %a to i32
  %y = trunc i64 %b to i32
  %c = icmp ule i32 %x, %y
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_32_uge(i64 %a, i64 %b, ptr %out) {
entry:
  %x = trunc i64 %a to i32
  %y = trunc i64 %b to i32
  %c = icmp uge i32 %x, %y
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_32_sle(i64 %a, i64 %b, ptr %out) {
entry:
  %x = trunc i64 %a to i32
  %y = trunc i64 %b to i32
  %c = icmp sle i32 %x, %y
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_32_sge(i64 %a, i64 %b, ptr %out) {
entry:
  %x = trunc i64 %a to i32
  %y = trunc i64 %b to i32
  %c = icmp sge i32 %x, %y
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_32_reverse(i64 %a, i64 %b, ptr %out) {
entry:
  %x = trunc i64 %a to i32
  %y = trunc i64 %b to i32
  %c = icmp ule i32 2147483648, %x
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_64_ne(i64 %a, i64 %b, ptr %out) {
entry:
  %c = icmp ne i64 %a, %b
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_64_ule(i64 %a, i64 %b, ptr %out) {
entry:
  %c = icmp ule i64 %a, %b
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_64_uge(i64 %a, i64 %b, ptr %out) {
entry:
  %c = icmp uge i64 %a, %b
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_64_sle(i64 %a, i64 %b, ptr %out) {
entry:
  %c = icmp sle i64 %a, %b
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_64_sge(i64 %a, i64 %b, ptr %out) {
entry:
  %c = icmp sge i64 %a, %b
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_64_reverse(i64 %a, i64 %b, ptr %out) {
entry:
  %c = icmp ule i64 9223372036854775808, %a
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_pointer_ne(i64 %a, i64 %b, ptr %out) {
entry:
  %x = inttoptr i64 %a to ptr
  %y = inttoptr i64 %b to ptr
  %c = icmp ne ptr %x, %y
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_pointer_ule(i64 %a, i64 %b, ptr %out) {
entry:
  %x = inttoptr i64 %a to ptr
  %y = inttoptr i64 %b to ptr
  %c = icmp ule ptr %x, %y
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_pointer_uge(i64 %a, i64 %b, ptr %out) {
entry:
  %x = inttoptr i64 %a to ptr
  %y = inttoptr i64 %b to ptr
  %c = icmp uge ptr %x, %y
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @compare_frame(i64 %a, i64 %b, ptr %out) {
entry:
  %slot = alloca i128, align 16
  %end = getelementptr i8, ptr %slot, i64 8
  %c = icmp uge ptr %end, %slot
  %r = zext i1 %c to i32
  call void @comparison_clobber()
  store i32 %r, ptr %out, align 4
  %live = xor i64 %a, %b
  ret i64 %live
}
