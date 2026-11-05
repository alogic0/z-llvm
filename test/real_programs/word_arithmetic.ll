target triple = "x86_64-unknown-linux-gnu"

declare { i64, i1 } @llvm.umul.with.overflow.i64(i64, i64)

declare { i64, i1 } @llvm.smul.with.overflow.i64(i64, i64)

declare { i64, i1 } @llvm.sadd.with.overflow.i64(i64, i64)

declare { i64, i1 } @llvm.ssub.with.overflow.i64(i64, i64)

declare i32 @llvm.umax.i32(i32, i32)

declare i32 @llvm.smin.i32(i32, i32)

declare i32 @llvm.smax.i32(i32, i32)

declare i64 @llvm.umax.i64(i64, i64)

declare i64 @llvm.smin.i64(i64, i64)

declare i64 @llvm.smax.i64(i64, i64)

declare i16 @llvm.bswap.i16(i16)

declare i32 @llvm.bswap.i32(i32)

declare i64 @llvm.bswap.i64(i64)

define i64 @word_udiv32_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %r = udiv i32 %a, 1
  %value = zext i32 %r to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_udiv32_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %r = udiv i32 %a, 2
  %value = zext i32 %r to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_udiv32_3(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %r = udiv i32 %a, 3
  %value = zext i32 %r to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_udiv32_24(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %r = udiv i32 %a, 24
  %value = zext i32 %r to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_udiv32_100(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %r = udiv i32 %a, 100
  %value = zext i32 %r to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_udiv32_2147483648(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %r = udiv i32 %a, 2147483648
  %value = zext i32 %r to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_udiv32_4294967295(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %r = udiv i32 %a, 4294967295
  %value = zext i32 %r to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_udiv32_left(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %b = trunc i64 %input_b to i32
  %divisor = or i32 %b, 1
  %r = udiv i32 100, %divisor
  %value = zext i32 %r to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_urem32_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %r = urem i32 %a, 1
  %value = zext i32 %r to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_urem32_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %r = urem i32 %a, 2
  %value = zext i32 %r to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_urem32_3(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %r = urem i32 %a, 3
  %value = zext i32 %r to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_urem32_24(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %r = urem i32 %a, 24
  %value = zext i32 %r to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_urem32_100(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %r = urem i32 %a, 100
  %value = zext i32 %r to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_urem32_2147483648(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %r = urem i32 %a, 2147483648
  %value = zext i32 %r to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_urem32_4294967295(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %r = urem i32 %a, 4294967295
  %value = zext i32 %r to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_urem32_left(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %b = trunc i64 %input_b to i32
  %divisor = or i32 %b, 1
  %r = urem i32 100, %divisor
  %value = zext i32 %r to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_udiv64_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %r = udiv i64 %input_a, 1
  store i64 %r, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_udiv64_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %r = udiv i64 %input_a, 2
  store i64 %r, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_udiv64_3(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %r = udiv i64 %input_a, 3
  store i64 %r, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_udiv64_24(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %r = udiv i64 %input_a, 24
  store i64 %r, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_udiv64_100(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %r = udiv i64 %input_a, 100
  store i64 %r, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_udiv64_9223372036854775808(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %r = udiv i64 %input_a, 9223372036854775808
  store i64 %r, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_udiv64_18446744073709551615(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %r = udiv i64 %input_a, 18446744073709551615
  store i64 %r, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_udiv64_left(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %divisor = or i64 %input_b, 1
  %r = udiv i64 100, %divisor
  store i64 %r, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_urem64_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %r = urem i64 %input_a, 1
  store i64 %r, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_urem64_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %r = urem i64 %input_a, 2
  store i64 %r, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_urem64_3(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %r = urem i64 %input_a, 3
  store i64 %r, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_urem64_24(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %r = urem i64 %input_a, 24
  store i64 %r, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_urem64_100(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %r = urem i64 %input_a, 100
  store i64 %r, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_urem64_9223372036854775808(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %r = urem i64 %input_a, 9223372036854775808
  store i64 %r, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_urem64_18446744073709551615(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %r = urem i64 %input_a, 18446744073709551615
  store i64 %r, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_urem64_left(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %divisor = or i64 %input_b, 1
  %r = urem i64 100, %divisor
  store i64 %r, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_umul_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %pair = call { i64, i1 } @llvm.umul.with.overflow.i64(i64 %input_a, i64 %input_b)
  %flag = extractvalue { i64, i1 } %pair, 1
  %value = extractvalue { i64, i1 } %pair, 0
  %wide_flag = zext i1 %flag to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %wide_flag
}


define i64 @word_umul_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %pair = call { i64, i1 } @llvm.umul.with.overflow.i64(i64 -1, i64 %input_b)
  %flag = extractvalue { i64, i1 } %pair, 1
  %value = extractvalue { i64, i1 } %pair, 0
  %wide_flag = zext i1 %flag to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %wide_flag
}


define i64 @word_umul_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %pair = call { i64, i1 } @llvm.umul.with.overflow.i64(i64 %input_a, i64 -1)
  %flag = extractvalue { i64, i1 } %pair, 1
  %value = extractvalue { i64, i1 } %pair, 0
  %wide_flag = zext i1 %flag to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %wide_flag
}


define i64 @word_umul_fixed_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %sum = add i64 %input_a, %input_b
  %pair = call { i64, i1 } @llvm.umul.with.overflow.i64(i64 %sum, i64 %input_b)
  %flag = extractvalue { i64, i1 } %pair, 1
  %value = extractvalue { i64, i1 } %pair, 0
  %wide_flag = zext i1 %flag to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %wide_flag
}


define i64 @word_umul_fixed_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %pair = call { i64, i1 } @llvm.umul.with.overflow.i64(i64 %input_a, i64 %salt)
  %flag = extractvalue { i64, i1 } %pair, 1
  %value = extractvalue { i64, i1 } %pair, 0
  %wide_flag = zext i1 %flag to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  store i64 %xor, ptr %next, align 8
  ret i64 %wide_flag
}


define i64 @word_smul_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %pair = call { i64, i1 } @llvm.smul.with.overflow.i64(i64 %input_a, i64 %input_b)
  %flag = extractvalue { i64, i1 } %pair, 1
  %value = extractvalue { i64, i1 } %pair, 0
  %wide_flag = zext i1 %flag to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %wide_flag
}


define i64 @word_smul_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %pair = call { i64, i1 } @llvm.smul.with.overflow.i64(i64 -1, i64 %input_b)
  %flag = extractvalue { i64, i1 } %pair, 1
  %value = extractvalue { i64, i1 } %pair, 0
  %wide_flag = zext i1 %flag to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %wide_flag
}


define i64 @word_smul_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %pair = call { i64, i1 } @llvm.smul.with.overflow.i64(i64 %input_a, i64 -1)
  %flag = extractvalue { i64, i1 } %pair, 1
  %value = extractvalue { i64, i1 } %pair, 0
  %wide_flag = zext i1 %flag to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %wide_flag
}


define i64 @word_smul_fixed_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %sum = add i64 %input_a, %input_b
  %pair = call { i64, i1 } @llvm.smul.with.overflow.i64(i64 %sum, i64 %input_b)
  %flag = extractvalue { i64, i1 } %pair, 1
  %value = extractvalue { i64, i1 } %pair, 0
  %wide_flag = zext i1 %flag to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %wide_flag
}


define i64 @word_smul_fixed_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %pair = call { i64, i1 } @llvm.smul.with.overflow.i64(i64 %input_a, i64 %salt)
  %flag = extractvalue { i64, i1 } %pair, 1
  %value = extractvalue { i64, i1 } %pair, 0
  %wide_flag = zext i1 %flag to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  store i64 %xor, ptr %next, align 8
  ret i64 %wide_flag
}


define i64 @word_sadd_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %pair = call { i64, i1 } @llvm.sadd.with.overflow.i64(i64 %input_a, i64 %input_b)
  %flag = extractvalue { i64, i1 } %pair, 1
  %value = extractvalue { i64, i1 } %pair, 0
  %wide_flag = zext i1 %flag to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %wide_flag
}


define i64 @word_sadd_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %pair = call { i64, i1 } @llvm.sadd.with.overflow.i64(i64 -1, i64 %input_b)
  %flag = extractvalue { i64, i1 } %pair, 1
  %value = extractvalue { i64, i1 } %pair, 0
  %wide_flag = zext i1 %flag to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %wide_flag
}


define i64 @word_sadd_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %pair = call { i64, i1 } @llvm.sadd.with.overflow.i64(i64 %input_a, i64 -1)
  %flag = extractvalue { i64, i1 } %pair, 1
  %value = extractvalue { i64, i1 } %pair, 0
  %wide_flag = zext i1 %flag to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %wide_flag
}


define i64 @word_sadd_fixed_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %sum = add i64 %input_a, %input_b
  %pair = call { i64, i1 } @llvm.sadd.with.overflow.i64(i64 %sum, i64 %input_b)
  %flag = extractvalue { i64, i1 } %pair, 1
  %value = extractvalue { i64, i1 } %pair, 0
  %wide_flag = zext i1 %flag to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %wide_flag
}


define i64 @word_sadd_fixed_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %pair = call { i64, i1 } @llvm.sadd.with.overflow.i64(i64 %input_a, i64 %salt)
  %flag = extractvalue { i64, i1 } %pair, 1
  %value = extractvalue { i64, i1 } %pair, 0
  %wide_flag = zext i1 %flag to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  store i64 %xor, ptr %next, align 8
  ret i64 %wide_flag
}


define i64 @word_ssub_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %pair = call { i64, i1 } @llvm.ssub.with.overflow.i64(i64 %input_a, i64 %input_b)
  %flag = extractvalue { i64, i1 } %pair, 1
  %value = extractvalue { i64, i1 } %pair, 0
  %wide_flag = zext i1 %flag to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %wide_flag
}


define i64 @word_ssub_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %pair = call { i64, i1 } @llvm.ssub.with.overflow.i64(i64 -1, i64 %input_b)
  %flag = extractvalue { i64, i1 } %pair, 1
  %value = extractvalue { i64, i1 } %pair, 0
  %wide_flag = zext i1 %flag to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %wide_flag
}


define i64 @word_ssub_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %pair = call { i64, i1 } @llvm.ssub.with.overflow.i64(i64 %input_a, i64 -1)
  %flag = extractvalue { i64, i1 } %pair, 1
  %value = extractvalue { i64, i1 } %pair, 0
  %wide_flag = zext i1 %flag to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %wide_flag
}


define i64 @word_ssub_fixed_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %sum = add i64 %input_a, %input_b
  %pair = call { i64, i1 } @llvm.ssub.with.overflow.i64(i64 %sum, i64 %input_b)
  %flag = extractvalue { i64, i1 } %pair, 1
  %value = extractvalue { i64, i1 } %pair, 0
  %wide_flag = zext i1 %flag to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %wide_flag
}


define i64 @word_ssub_fixed_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %pair = call { i64, i1 } @llvm.ssub.with.overflow.i64(i64 %input_a, i64 %salt)
  %flag = extractvalue { i64, i1 } %pair, 1
  %value = extractvalue { i64, i1 } %pair, 0
  %wide_flag = zext i1 %flag to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  store i64 %xor, ptr %next, align 8
  ret i64 %wide_flag
}


define i64 @word_umax32_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %r = call i32 @llvm.umax.i32(i32 %a, i32 %b)
  %value = zext i32 %r to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_umax32_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %r = call i32 @llvm.umax.i32(i32 -1, i32 %b)
  %value = zext i32 %r to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_umax32_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %r = call i32 @llvm.umax.i32(i32 %a, i32 -1)
  %value = zext i32 %r to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_smin32_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %r = call i32 @llvm.smin.i32(i32 %a, i32 %b)
  %value = zext i32 %r to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_smin32_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %r = call i32 @llvm.smin.i32(i32 -1, i32 %b)
  %value = zext i32 %r to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_smin32_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %r = call i32 @llvm.smin.i32(i32 %a, i32 -1)
  %value = zext i32 %r to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_smax32_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %r = call i32 @llvm.smax.i32(i32 %a, i32 %b)
  %value = zext i32 %r to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_smax32_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %r = call i32 @llvm.smax.i32(i32 -1, i32 %b)
  %value = zext i32 %r to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_smax32_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %r = call i32 @llvm.smax.i32(i32 %a, i32 -1)
  %value = zext i32 %r to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_umax64_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %r = call i64 @llvm.umax.i64(i64 %input_a, i64 %input_b)
  store i64 %r, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_umax64_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %r = call i64 @llvm.umax.i64(i64 -1, i64 %input_b)
  store i64 %r, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_umax64_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %r = call i64 @llvm.umax.i64(i64 %input_a, i64 -1)
  store i64 %r, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_smin64_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %r = call i64 @llvm.smin.i64(i64 %input_a, i64 %input_b)
  store i64 %r, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_smin64_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %r = call i64 @llvm.smin.i64(i64 -1, i64 %input_b)
  store i64 %r, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_smin64_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %r = call i64 @llvm.smin.i64(i64 %input_a, i64 -1)
  store i64 %r, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_smax64_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %r = call i64 @llvm.smax.i64(i64 %input_a, i64 %input_b)
  store i64 %r, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_smax64_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %r = call i64 @llvm.smax.i64(i64 -1, i64 %input_b)
  store i64 %r, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_smax64_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %r = call i64 @llvm.smax.i64(i64 %input_a, i64 -1)
  store i64 %r, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_swap16_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i16
  %r = call i16 @llvm.bswap.i16(i16 %a)
  %value = zext i16 %r to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_swap16_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i16
  %r = call i16 @llvm.bswap.i16(i16 4660)
  %value = zext i16 %r to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_swap32_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %r = call i32 @llvm.bswap.i32(i32 %a)
  %value = zext i32 %r to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_swap32_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %r = call i32 @llvm.bswap.i32(i32 305419896)
  %value = zext i32 %r to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_swap64_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %r = call i64 @llvm.bswap.i64(i64 %input_a)
  store i64 %r, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_swap64_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %r = call i64 @llvm.bswap.i64(i64 1311768467463790320)
  store i64 %r, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}


define i64 @word_zero_extend(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %full = add i64 %input_a, %input_b
  %low = trunc i64 %full to i32
  %value = zext i32 %low to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 0
}

