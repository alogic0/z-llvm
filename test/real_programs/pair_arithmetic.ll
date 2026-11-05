target triple = "x86_64-unknown-linux-gnu"
declare i64 @pair_arithmetic_clobber(i64)
define i64 @pair_arithmetic_add(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %v = add i128 %a, %b
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_mul(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %v = mul i128 %a, %b
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_and(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %v = and i128 %a, %b
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_shl(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %count = and i128 %b, 127
  %v = shl i128 %a, %count
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_lshr(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %count = and i128 %b, 127
  %v = lshr i128 %a, %count
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_ashr(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %count = and i128 %b, 127
  %v = ashr i128 %a, %count
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_cmp_eq(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %condition = icmp eq i128 %a, %b
  %bit = zext i1 %condition to i64
  %v = zext i64 %bit to i128
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_cmp_ne(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %condition = icmp ne i128 %a, %b
  %bit = zext i1 %condition to i64
  %v = zext i64 %bit to i128
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_cmp_ult(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %condition = icmp ult i128 %a, %b
  %bit = zext i1 %condition to i64
  %v = zext i64 %bit to i128
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_cmp_ule(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %condition = icmp ule i128 %a, %b
  %bit = zext i1 %condition to i64
  %v = zext i64 %bit to i128
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_cmp_ugt(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %condition = icmp ugt i128 %a, %b
  %bit = zext i1 %condition to i64
  %v = zext i64 %bit to i128
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_cmp_uge(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %condition = icmp uge i128 %a, %b
  %bit = zext i1 %condition to i64
  %v = zext i64 %bit to i128
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_cmp_slt(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %condition = icmp slt i128 %a, %b
  %bit = zext i1 %condition to i64
  %v = zext i64 %bit to i128
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_cmp_sle(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %condition = icmp sle i128 %a, %b
  %bit = zext i1 %condition to i64
  %v = zext i64 %bit to i128
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_cmp_sgt(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %condition = icmp sgt i128 %a, %b
  %bit = zext i1 %condition to i64
  %v = zext i64 %bit to i128
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_cmp_sge(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %condition = icmp sge i128 %a, %b
  %bit = zext i1 %condition to i64
  %v = zext i64 %bit to i128
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_select(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %word = trunc i128 %b to i64
  %condition = icmp ne i64 %word, 0
  %v = select i1 %condition, i128 %a, i128 %b
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_zext_literal(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %v = zext i7 -64 to i128
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_sext_literal(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %v = sext i7 -64 to i128
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_udiv_1(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %v = udiv i128 %a, 1
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_udiv_3(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %v = udiv i128 %a, 3
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_udiv_1000000000(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %v = udiv i128 %a, 1000000000
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_udiv_4294967295(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %v = udiv i128 %a, 4294967295
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_urem_1(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %v = urem i128 %a, 1
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_urem_3(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %v = urem i128 %a, 3
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_urem_1000000000(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %v = urem i128 %a, 1000000000
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_urem_4294967295(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %v = urem i128 %a, 4294967295
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_sdiv_1(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %v = sdiv i128 %a, 1
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_sdiv_3(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %v = sdiv i128 %a, 3
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_sdiv_neg_3(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %v = sdiv i128 %a, -3
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_sdiv_1000000000(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %v = sdiv i128 %a, 1000000000
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_sdiv_neg_1000000000(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %v = sdiv i128 %a, -1000000000
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_sdiv_4294967295(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %v = sdiv i128 %a, 4294967295
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_sdiv_neg_4294967295(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %v = sdiv i128 %a, -4294967295
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_srem_1(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %v = srem i128 %a, 1
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_srem_3(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %v = srem i128 %a, 3
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_srem_neg_3(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %v = srem i128 %a, -3
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_srem_1000000000(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %v = srem i128 %a, 1000000000
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_srem_neg_1000000000(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %v = srem i128 %a, -1000000000
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_srem_4294967295(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %v = srem i128 %a, 4294967295
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_srem_neg_4294967295(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %v = srem i128 %a, -4294967295
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_mul_zero_extended(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %alo = trunc i128 %a to i64
  %blo = trunc i128 %b to i64
  %aw = zext i64 %alo to i128
  %bw = zext i64 %blo to i128
  %v = mul i128 %aw, %bw
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_mul_after_add(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %pair_sum = add i128 %a, %b
  %v = mul i128 %pair_sum, %b
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_div_after_mul(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %product = mul i128 %a, %b
  %v = udiv i128 %product, 3
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @pair_arithmetic_project_masked(i128 %a, i128 %b, i64 %live, ptr %out) {
entry:
  %masked = and i128 %a, 127
  %lower = trunc i128 %masked to i64
  %shift = lshr i128 %masked, 64
  %upper_word = trunc i128 %shift to i64
  %combined = add i64 %lower, %upper_word
  %v = zext i64 %combined to i128
  %noise = call i64 @pair_arithmetic_clobber(i64 %live)
  %tag = getelementptr i8, ptr %out, i64 16
  store i64 %noise, ptr %tag, align 8
  %lo = trunc i128 %v to i64
  %shifted = lshr i128 %v, 64
  %hi = trunc i128 %shifted to i64
  store i64 %lo, ptr %out, align 8
  %upper = getelementptr i8, ptr %out, i64 8
  store i64 %hi, ptr %upper, align 8
  %sum = add i64 %lo, %hi
  %answer = xor i64 %sum, %live
  ret i64 %answer
}
