target triple = "x86_64-unknown-linux-gnu"
target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n8:16:32:64-S128"
declare i64 @integer_forms_clobber(i64)
define i64 @integer_forms_add_1(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i1
  %b = trunc i64 %other to i1
  %result = add i1 %a, %b
  %wide = zext i1 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_sub_1(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i1
  %b = trunc i64 %other to i1
  %result = sub i1 %a, %b
  %wide = zext i1 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_mul_1(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i1
  %b = trunc i64 %other to i1
  %result = mul i1 %a, %b
  %wide = zext i1 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_and_1(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i1
  %b = trunc i64 %other to i1
  %result = and i1 %a, %b
  %wide = zext i1 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_or_1(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i1
  %b = trunc i64 %other to i1
  %result = or i1 %a, %b
  %wide = zext i1 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_xor_1(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i1
  %b = trunc i64 %other to i1
  %result = xor i1 %a, %b
  %wide = zext i1 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_shl_1(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i1
  %count = urem i64 %other, 1
  %b = trunc i64 %count to i1
  %result = shl i1 %a, %b
  %wide = zext i1 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_lshr_1(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i1
  %count = urem i64 %other, 1
  %b = trunc i64 %count to i1
  %result = lshr i1 %a, %b
  %wide = zext i1 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_ashr_1(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i1
  %count = urem i64 %other, 1
  %b = trunc i64 %count to i1
  %result = ashr i1 %a, %b
  %wide = zext i1 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_udiv_1(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i1
  %b = trunc i64 %other to i1
  %divisor = or i1 %b, 1
  %result = udiv i1 %a, %divisor
  %wide = zext i1 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_urem_1(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i1
  %b = trunc i64 %other to i1
  %divisor = or i1 %b, 1
  %result = urem i1 %a, %divisor
  %wide = zext i1 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_add_2(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i2
  %b = trunc i64 %other to i2
  %result = add i2 %a, %b
  %wide = zext i2 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_sub_2(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i2
  %b = trunc i64 %other to i2
  %result = sub i2 %a, %b
  %wide = zext i2 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_mul_2(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i2
  %b = trunc i64 %other to i2
  %result = mul i2 %a, %b
  %wide = zext i2 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_and_2(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i2
  %b = trunc i64 %other to i2
  %result = and i2 %a, %b
  %wide = zext i2 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_or_2(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i2
  %b = trunc i64 %other to i2
  %result = or i2 %a, %b
  %wide = zext i2 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_xor_2(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i2
  %b = trunc i64 %other to i2
  %result = xor i2 %a, %b
  %wide = zext i2 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_shl_2(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i2
  %count = urem i64 %other, 2
  %b = trunc i64 %count to i2
  %result = shl i2 %a, %b
  %wide = zext i2 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_lshr_2(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i2
  %count = urem i64 %other, 2
  %b = trunc i64 %count to i2
  %result = lshr i2 %a, %b
  %wide = zext i2 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_ashr_2(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i2
  %count = urem i64 %other, 2
  %b = trunc i64 %count to i2
  %result = ashr i2 %a, %b
  %wide = zext i2 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_udiv_2(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i2
  %b = trunc i64 %other to i2
  %divisor = or i2 %b, 1
  %result = udiv i2 %a, %divisor
  %wide = zext i2 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_urem_2(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i2
  %b = trunc i64 %other to i2
  %divisor = or i2 %b, 1
  %result = urem i2 %a, %divisor
  %wide = zext i2 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_sdiv_2(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i2
  %b = trunc i64 %other to i2
  %divisor = or i2 %b, 1
  %is_min = icmp eq i2 %a, -2
  %is_neg_one = icmp eq i2 %divisor, -1
  %overflow = and i1 %is_min, %is_neg_one
  %numerator = select i1 %overflow, i2 0, i2 %a
  %result = sdiv i2 %numerator, %divisor
  %wide = zext i2 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_srem_2(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i2
  %b = trunc i64 %other to i2
  %divisor = or i2 %b, 1
  %is_min = icmp eq i2 %a, -2
  %is_neg_one = icmp eq i2 %divisor, -1
  %overflow = and i1 %is_min, %is_neg_one
  %numerator = select i1 %overflow, i2 0, i2 %a
  %result = srem i2 %numerator, %divisor
  %wide = zext i2 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_add_7(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i7
  %b = trunc i64 %other to i7
  %result = add i7 %a, %b
  %wide = zext i7 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_sub_7(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i7
  %b = trunc i64 %other to i7
  %result = sub i7 %a, %b
  %wide = zext i7 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_mul_7(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i7
  %b = trunc i64 %other to i7
  %result = mul i7 %a, %b
  %wide = zext i7 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_and_7(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i7
  %b = trunc i64 %other to i7
  %result = and i7 %a, %b
  %wide = zext i7 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_or_7(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i7
  %b = trunc i64 %other to i7
  %result = or i7 %a, %b
  %wide = zext i7 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_xor_7(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i7
  %b = trunc i64 %other to i7
  %result = xor i7 %a, %b
  %wide = zext i7 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_shl_7(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i7
  %count = urem i64 %other, 7
  %b = trunc i64 %count to i7
  %result = shl i7 %a, %b
  %wide = zext i7 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_lshr_7(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i7
  %count = urem i64 %other, 7
  %b = trunc i64 %count to i7
  %result = lshr i7 %a, %b
  %wide = zext i7 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_ashr_7(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i7
  %count = urem i64 %other, 7
  %b = trunc i64 %count to i7
  %result = ashr i7 %a, %b
  %wide = zext i7 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_udiv_7(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i7
  %b = trunc i64 %other to i7
  %divisor = or i7 %b, 1
  %result = udiv i7 %a, %divisor
  %wide = zext i7 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_urem_7(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i7
  %b = trunc i64 %other to i7
  %divisor = or i7 %b, 1
  %result = urem i7 %a, %divisor
  %wide = zext i7 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_sdiv_7(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i7
  %b = trunc i64 %other to i7
  %divisor = or i7 %b, 1
  %is_min = icmp eq i7 %a, -64
  %is_neg_one = icmp eq i7 %divisor, -1
  %overflow = and i1 %is_min, %is_neg_one
  %numerator = select i1 %overflow, i7 0, i7 %a
  %result = sdiv i7 %numerator, %divisor
  %wide = zext i7 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_srem_7(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i7
  %b = trunc i64 %other to i7
  %divisor = or i7 %b, 1
  %is_min = icmp eq i7 %a, -64
  %is_neg_one = icmp eq i7 %divisor, -1
  %overflow = and i1 %is_min, %is_neg_one
  %numerator = select i1 %overflow, i7 0, i7 %a
  %result = srem i7 %numerator, %divisor
  %wide = zext i7 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_add_8(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i8
  %b = trunc i64 %other to i8
  %result = add i8 %a, %b
  %wide = zext i8 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_sub_8(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i8
  %b = trunc i64 %other to i8
  %result = sub i8 %a, %b
  %wide = zext i8 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_mul_8(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i8
  %b = trunc i64 %other to i8
  %result = mul i8 %a, %b
  %wide = zext i8 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_and_8(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i8
  %b = trunc i64 %other to i8
  %result = and i8 %a, %b
  %wide = zext i8 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_or_8(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i8
  %b = trunc i64 %other to i8
  %result = or i8 %a, %b
  %wide = zext i8 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_xor_8(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i8
  %b = trunc i64 %other to i8
  %result = xor i8 %a, %b
  %wide = zext i8 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_shl_8(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i8
  %count = urem i64 %other, 8
  %b = trunc i64 %count to i8
  %result = shl i8 %a, %b
  %wide = zext i8 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_lshr_8(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i8
  %count = urem i64 %other, 8
  %b = trunc i64 %count to i8
  %result = lshr i8 %a, %b
  %wide = zext i8 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_ashr_8(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i8
  %count = urem i64 %other, 8
  %b = trunc i64 %count to i8
  %result = ashr i8 %a, %b
  %wide = zext i8 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_udiv_8(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i8
  %b = trunc i64 %other to i8
  %divisor = or i8 %b, 1
  %result = udiv i8 %a, %divisor
  %wide = zext i8 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_urem_8(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i8
  %b = trunc i64 %other to i8
  %divisor = or i8 %b, 1
  %result = urem i8 %a, %divisor
  %wide = zext i8 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_sdiv_8(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i8
  %b = trunc i64 %other to i8
  %divisor = or i8 %b, 1
  %is_min = icmp eq i8 %a, -128
  %is_neg_one = icmp eq i8 %divisor, -1
  %overflow = and i1 %is_min, %is_neg_one
  %numerator = select i1 %overflow, i8 0, i8 %a
  %result = sdiv i8 %numerator, %divisor
  %wide = zext i8 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_srem_8(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i8
  %b = trunc i64 %other to i8
  %divisor = or i8 %b, 1
  %is_min = icmp eq i8 %a, -128
  %is_neg_one = icmp eq i8 %divisor, -1
  %overflow = and i1 %is_min, %is_neg_one
  %numerator = select i1 %overflow, i8 0, i8 %a
  %result = srem i8 %numerator, %divisor
  %wide = zext i8 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_add_16(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i16
  %b = trunc i64 %other to i16
  %result = add i16 %a, %b
  %wide = zext i16 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_sub_16(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i16
  %b = trunc i64 %other to i16
  %result = sub i16 %a, %b
  %wide = zext i16 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_mul_16(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i16
  %b = trunc i64 %other to i16
  %result = mul i16 %a, %b
  %wide = zext i16 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_and_16(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i16
  %b = trunc i64 %other to i16
  %result = and i16 %a, %b
  %wide = zext i16 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_or_16(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i16
  %b = trunc i64 %other to i16
  %result = or i16 %a, %b
  %wide = zext i16 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_xor_16(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i16
  %b = trunc i64 %other to i16
  %result = xor i16 %a, %b
  %wide = zext i16 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_shl_16(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i16
  %count = urem i64 %other, 16
  %b = trunc i64 %count to i16
  %result = shl i16 %a, %b
  %wide = zext i16 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_lshr_16(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i16
  %count = urem i64 %other, 16
  %b = trunc i64 %count to i16
  %result = lshr i16 %a, %b
  %wide = zext i16 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_ashr_16(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i16
  %count = urem i64 %other, 16
  %b = trunc i64 %count to i16
  %result = ashr i16 %a, %b
  %wide = zext i16 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_udiv_16(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i16
  %b = trunc i64 %other to i16
  %divisor = or i16 %b, 1
  %result = udiv i16 %a, %divisor
  %wide = zext i16 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_urem_16(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i16
  %b = trunc i64 %other to i16
  %divisor = or i16 %b, 1
  %result = urem i16 %a, %divisor
  %wide = zext i16 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_sdiv_16(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i16
  %b = trunc i64 %other to i16
  %divisor = or i16 %b, 1
  %is_min = icmp eq i16 %a, -32768
  %is_neg_one = icmp eq i16 %divisor, -1
  %overflow = and i1 %is_min, %is_neg_one
  %numerator = select i1 %overflow, i16 0, i16 %a
  %result = sdiv i16 %numerator, %divisor
  %wide = zext i16 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_srem_16(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i16
  %b = trunc i64 %other to i16
  %divisor = or i16 %b, 1
  %is_min = icmp eq i16 %a, -32768
  %is_neg_one = icmp eq i16 %divisor, -1
  %overflow = and i1 %is_min, %is_neg_one
  %numerator = select i1 %overflow, i16 0, i16 %a
  %result = srem i16 %numerator, %divisor
  %wide = zext i16 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_add_17(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i17
  %b = trunc i64 %other to i17
  %result = add i17 %a, %b
  %wide = zext i17 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_sub_17(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i17
  %b = trunc i64 %other to i17
  %result = sub i17 %a, %b
  %wide = zext i17 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_mul_17(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i17
  %b = trunc i64 %other to i17
  %result = mul i17 %a, %b
  %wide = zext i17 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_and_17(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i17
  %b = trunc i64 %other to i17
  %result = and i17 %a, %b
  %wide = zext i17 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_or_17(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i17
  %b = trunc i64 %other to i17
  %result = or i17 %a, %b
  %wide = zext i17 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_xor_17(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i17
  %b = trunc i64 %other to i17
  %result = xor i17 %a, %b
  %wide = zext i17 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_shl_17(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i17
  %count = urem i64 %other, 17
  %b = trunc i64 %count to i17
  %result = shl i17 %a, %b
  %wide = zext i17 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_lshr_17(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i17
  %count = urem i64 %other, 17
  %b = trunc i64 %count to i17
  %result = lshr i17 %a, %b
  %wide = zext i17 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_ashr_17(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i17
  %count = urem i64 %other, 17
  %b = trunc i64 %count to i17
  %result = ashr i17 %a, %b
  %wide = zext i17 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_udiv_17(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i17
  %b = trunc i64 %other to i17
  %divisor = or i17 %b, 1
  %result = udiv i17 %a, %divisor
  %wide = zext i17 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_urem_17(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i17
  %b = trunc i64 %other to i17
  %divisor = or i17 %b, 1
  %result = urem i17 %a, %divisor
  %wide = zext i17 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_sdiv_17(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i17
  %b = trunc i64 %other to i17
  %divisor = or i17 %b, 1
  %is_min = icmp eq i17 %a, -65536
  %is_neg_one = icmp eq i17 %divisor, -1
  %overflow = and i1 %is_min, %is_neg_one
  %numerator = select i1 %overflow, i17 0, i17 %a
  %result = sdiv i17 %numerator, %divisor
  %wide = zext i17 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_srem_17(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i17
  %b = trunc i64 %other to i17
  %divisor = or i17 %b, 1
  %is_min = icmp eq i17 %a, -65536
  %is_neg_one = icmp eq i17 %divisor, -1
  %overflow = and i1 %is_min, %is_neg_one
  %numerator = select i1 %overflow, i17 0, i17 %a
  %result = srem i17 %numerator, %divisor
  %wide = zext i17 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_add_24(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i24
  %b = trunc i64 %other to i24
  %result = add i24 %a, %b
  %wide = zext i24 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_sub_24(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i24
  %b = trunc i64 %other to i24
  %result = sub i24 %a, %b
  %wide = zext i24 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_mul_24(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i24
  %b = trunc i64 %other to i24
  %result = mul i24 %a, %b
  %wide = zext i24 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_and_24(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i24
  %b = trunc i64 %other to i24
  %result = and i24 %a, %b
  %wide = zext i24 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_or_24(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i24
  %b = trunc i64 %other to i24
  %result = or i24 %a, %b
  %wide = zext i24 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_xor_24(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i24
  %b = trunc i64 %other to i24
  %result = xor i24 %a, %b
  %wide = zext i24 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_shl_24(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i24
  %count = urem i64 %other, 24
  %b = trunc i64 %count to i24
  %result = shl i24 %a, %b
  %wide = zext i24 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_lshr_24(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i24
  %count = urem i64 %other, 24
  %b = trunc i64 %count to i24
  %result = lshr i24 %a, %b
  %wide = zext i24 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_ashr_24(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i24
  %count = urem i64 %other, 24
  %b = trunc i64 %count to i24
  %result = ashr i24 %a, %b
  %wide = zext i24 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_udiv_24(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i24
  %b = trunc i64 %other to i24
  %divisor = or i24 %b, 1
  %result = udiv i24 %a, %divisor
  %wide = zext i24 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_urem_24(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i24
  %b = trunc i64 %other to i24
  %divisor = or i24 %b, 1
  %result = urem i24 %a, %divisor
  %wide = zext i24 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_sdiv_24(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i24
  %b = trunc i64 %other to i24
  %divisor = or i24 %b, 1
  %is_min = icmp eq i24 %a, -8388608
  %is_neg_one = icmp eq i24 %divisor, -1
  %overflow = and i1 %is_min, %is_neg_one
  %numerator = select i1 %overflow, i24 0, i24 %a
  %result = sdiv i24 %numerator, %divisor
  %wide = zext i24 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_srem_24(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i24
  %b = trunc i64 %other to i24
  %divisor = or i24 %b, 1
  %is_min = icmp eq i24 %a, -8388608
  %is_neg_one = icmp eq i24 %divisor, -1
  %overflow = and i1 %is_min, %is_neg_one
  %numerator = select i1 %overflow, i24 0, i24 %a
  %result = srem i24 %numerator, %divisor
  %wide = zext i24 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_add_31(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i31
  %b = trunc i64 %other to i31
  %result = add i31 %a, %b
  %wide = zext i31 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_sub_31(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i31
  %b = trunc i64 %other to i31
  %result = sub i31 %a, %b
  %wide = zext i31 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_mul_31(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i31
  %b = trunc i64 %other to i31
  %result = mul i31 %a, %b
  %wide = zext i31 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_and_31(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i31
  %b = trunc i64 %other to i31
  %result = and i31 %a, %b
  %wide = zext i31 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_or_31(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i31
  %b = trunc i64 %other to i31
  %result = or i31 %a, %b
  %wide = zext i31 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_xor_31(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i31
  %b = trunc i64 %other to i31
  %result = xor i31 %a, %b
  %wide = zext i31 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_shl_31(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i31
  %count = urem i64 %other, 31
  %b = trunc i64 %count to i31
  %result = shl i31 %a, %b
  %wide = zext i31 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_lshr_31(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i31
  %count = urem i64 %other, 31
  %b = trunc i64 %count to i31
  %result = lshr i31 %a, %b
  %wide = zext i31 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_ashr_31(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i31
  %count = urem i64 %other, 31
  %b = trunc i64 %count to i31
  %result = ashr i31 %a, %b
  %wide = zext i31 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_udiv_31(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i31
  %b = trunc i64 %other to i31
  %divisor = or i31 %b, 1
  %result = udiv i31 %a, %divisor
  %wide = zext i31 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_urem_31(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i31
  %b = trunc i64 %other to i31
  %divisor = or i31 %b, 1
  %result = urem i31 %a, %divisor
  %wide = zext i31 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_sdiv_31(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i31
  %b = trunc i64 %other to i31
  %divisor = or i31 %b, 1
  %is_min = icmp eq i31 %a, -1073741824
  %is_neg_one = icmp eq i31 %divisor, -1
  %overflow = and i1 %is_min, %is_neg_one
  %numerator = select i1 %overflow, i31 0, i31 %a
  %result = sdiv i31 %numerator, %divisor
  %wide = zext i31 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_srem_31(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i31
  %b = trunc i64 %other to i31
  %divisor = or i31 %b, 1
  %is_min = icmp eq i31 %a, -1073741824
  %is_neg_one = icmp eq i31 %divisor, -1
  %overflow = and i1 %is_min, %is_neg_one
  %numerator = select i1 %overflow, i31 0, i31 %a
  %result = srem i31 %numerator, %divisor
  %wide = zext i31 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_add_33(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i33
  %b = trunc i64 %other to i33
  %result = add i33 %a, %b
  %wide = zext i33 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_sub_33(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i33
  %b = trunc i64 %other to i33
  %result = sub i33 %a, %b
  %wide = zext i33 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_mul_33(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i33
  %b = trunc i64 %other to i33
  %result = mul i33 %a, %b
  %wide = zext i33 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_and_33(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i33
  %b = trunc i64 %other to i33
  %result = and i33 %a, %b
  %wide = zext i33 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_or_33(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i33
  %b = trunc i64 %other to i33
  %result = or i33 %a, %b
  %wide = zext i33 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_xor_33(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i33
  %b = trunc i64 %other to i33
  %result = xor i33 %a, %b
  %wide = zext i33 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_shl_33(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i33
  %count = urem i64 %other, 33
  %b = trunc i64 %count to i33
  %result = shl i33 %a, %b
  %wide = zext i33 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_lshr_33(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i33
  %count = urem i64 %other, 33
  %b = trunc i64 %count to i33
  %result = lshr i33 %a, %b
  %wide = zext i33 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_ashr_33(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i33
  %count = urem i64 %other, 33
  %b = trunc i64 %count to i33
  %result = ashr i33 %a, %b
  %wide = zext i33 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_udiv_33(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i33
  %b = trunc i64 %other to i33
  %divisor = or i33 %b, 1
  %result = udiv i33 %a, %divisor
  %wide = zext i33 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_urem_33(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i33
  %b = trunc i64 %other to i33
  %divisor = or i33 %b, 1
  %result = urem i33 %a, %divisor
  %wide = zext i33 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_sdiv_33(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i33
  %b = trunc i64 %other to i33
  %divisor = or i33 %b, 1
  %is_min = icmp eq i33 %a, -4294967296
  %is_neg_one = icmp eq i33 %divisor, -1
  %overflow = and i1 %is_min, %is_neg_one
  %numerator = select i1 %overflow, i33 0, i33 %a
  %result = sdiv i33 %numerator, %divisor
  %wide = zext i33 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_srem_33(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i33
  %b = trunc i64 %other to i33
  %divisor = or i33 %b, 1
  %is_min = icmp eq i33 %a, -4294967296
  %is_neg_one = icmp eq i33 %divisor, -1
  %overflow = and i1 %is_min, %is_neg_one
  %numerator = select i1 %overflow, i33 0, i33 %a
  %result = srem i33 %numerator, %divisor
  %wide = zext i33 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_add_63(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i63
  %b = trunc i64 %other to i63
  %result = add i63 %a, %b
  %wide = zext i63 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_sub_63(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i63
  %b = trunc i64 %other to i63
  %result = sub i63 %a, %b
  %wide = zext i63 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_mul_63(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i63
  %b = trunc i64 %other to i63
  %result = mul i63 %a, %b
  %wide = zext i63 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_and_63(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i63
  %b = trunc i64 %other to i63
  %result = and i63 %a, %b
  %wide = zext i63 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_or_63(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i63
  %b = trunc i64 %other to i63
  %result = or i63 %a, %b
  %wide = zext i63 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_xor_63(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i63
  %b = trunc i64 %other to i63
  %result = xor i63 %a, %b
  %wide = zext i63 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_shl_63(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i63
  %count = urem i64 %other, 63
  %b = trunc i64 %count to i63
  %result = shl i63 %a, %b
  %wide = zext i63 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_lshr_63(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i63
  %count = urem i64 %other, 63
  %b = trunc i64 %count to i63
  %result = lshr i63 %a, %b
  %wide = zext i63 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_ashr_63(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i63
  %count = urem i64 %other, 63
  %b = trunc i64 %count to i63
  %result = ashr i63 %a, %b
  %wide = zext i63 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_udiv_63(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i63
  %b = trunc i64 %other to i63
  %divisor = or i63 %b, 1
  %result = udiv i63 %a, %divisor
  %wide = zext i63 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_urem_63(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i63
  %b = trunc i64 %other to i63
  %divisor = or i63 %b, 1
  %result = urem i63 %a, %divisor
  %wide = zext i63 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_sdiv_63(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i63
  %b = trunc i64 %other to i63
  %divisor = or i63 %b, 1
  %is_min = icmp eq i63 %a, -4611686018427387904
  %is_neg_one = icmp eq i63 %divisor, -1
  %overflow = and i1 %is_min, %is_neg_one
  %numerator = select i1 %overflow, i63 0, i63 %a
  %result = sdiv i63 %numerator, %divisor
  %wide = zext i63 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_srem_63(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i63
  %b = trunc i64 %other to i63
  %divisor = or i63 %b, 1
  %is_min = icmp eq i63 %a, -4611686018427387904
  %is_neg_one = icmp eq i63 %divisor, -1
  %overflow = and i1 %is_min, %is_neg_one
  %numerator = select i1 %overflow, i63 0, i63 %a
  %result = srem i63 %numerator, %divisor
  %wide = zext i63 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_sdiv_32(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i32
  %b = trunc i64 %other to i32
  %divisor = or i32 %b, 1
  %is_min = icmp eq i32 %a, -2147483648
  %is_neg_one = icmp eq i32 %divisor, -1
  %overflow = and i1 %is_min, %is_neg_one
  %numerator = select i1 %overflow, i32 0, i32 %a
  %result = sdiv i32 %numerator, %divisor
  %wide = zext i32 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_srem_32(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i32
  %b = trunc i64 %other to i32
  %divisor = or i32 %b, 1
  %is_min = icmp eq i32 %a, -2147483648
  %is_neg_one = icmp eq i32 %divisor, -1
  %overflow = and i1 %is_min, %is_neg_one
  %numerator = select i1 %overflow, i32 0, i32 %a
  %result = srem i32 %numerator, %divisor
  %wide = zext i32 %result to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_sdiv_64(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = add i64 %input, 0
  %b = add i64 %other, 0
  %divisor = or i64 %b, 1
  %is_min = icmp eq i64 %a, -9223372036854775808
  %is_neg_one = icmp eq i64 %divisor, -1
  %overflow = and i1 %is_min, %is_neg_one
  %numerator = select i1 %overflow, i64 0, i64 %a
  %result = sdiv i64 %numerator, %divisor
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %result, %live
  ret i64 %answer
}

define i64 @integer_forms_srem_64(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = add i64 %input, 0
  %b = add i64 %other, 0
  %divisor = or i64 %b, 1
  %is_min = icmp eq i64 %a, -9223372036854775808
  %is_neg_one = icmp eq i64 %divisor, -1
  %overflow = and i1 %is_min, %is_neg_one
  %numerator = select i1 %overflow, i64 0, i64 %a
  %result = srem i64 %numerator, %divisor
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %result, %live
  ret i64 %answer
}

define i64 @integer_forms_cmp_eq_33(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i33
  %b = trunc i64 %other to i33
  %condition = icmp eq i33 %a, %b
  %wide = zext i1 %condition to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_cmp_ne_33(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i33
  %b = trunc i64 %other to i33
  %condition = icmp ne i33 %a, %b
  %wide = zext i1 %condition to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_cmp_ult_33(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i33
  %b = trunc i64 %other to i33
  %condition = icmp ult i33 %a, %b
  %wide = zext i1 %condition to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_cmp_ule_33(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i33
  %b = trunc i64 %other to i33
  %condition = icmp ule i33 %a, %b
  %wide = zext i1 %condition to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_cmp_ugt_33(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i33
  %b = trunc i64 %other to i33
  %condition = icmp ugt i33 %a, %b
  %wide = zext i1 %condition to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_cmp_uge_33(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i33
  %b = trunc i64 %other to i33
  %condition = icmp uge i33 %a, %b
  %wide = zext i1 %condition to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_cmp_slt_33(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i33
  %b = trunc i64 %other to i33
  %condition = icmp slt i33 %a, %b
  %wide = zext i1 %condition to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_cmp_sle_33(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i33
  %b = trunc i64 %other to i33
  %condition = icmp sle i33 %a, %b
  %wide = zext i1 %condition to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_cmp_sgt_33(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i33
  %b = trunc i64 %other to i33
  %condition = icmp sgt i33 %a, %b
  %wide = zext i1 %condition to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_cmp_sge_33(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i33
  %b = trunc i64 %other to i33
  %condition = icmp sge i33 %a, %b
  %wide = zext i1 %condition to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_cmp_eq_51(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i51
  %b = trunc i64 %other to i51
  %condition = icmp eq i51 %a, %b
  %wide = zext i1 %condition to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_cmp_ne_51(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i51
  %b = trunc i64 %other to i51
  %condition = icmp ne i51 %a, %b
  %wide = zext i1 %condition to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_cmp_ult_51(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i51
  %b = trunc i64 %other to i51
  %condition = icmp ult i51 %a, %b
  %wide = zext i1 %condition to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_cmp_ule_51(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i51
  %b = trunc i64 %other to i51
  %condition = icmp ule i51 %a, %b
  %wide = zext i1 %condition to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_cmp_ugt_51(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i51
  %b = trunc i64 %other to i51
  %condition = icmp ugt i51 %a, %b
  %wide = zext i1 %condition to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_cmp_uge_51(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i51
  %b = trunc i64 %other to i51
  %condition = icmp uge i51 %a, %b
  %wide = zext i1 %condition to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_cmp_slt_51(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i51
  %b = trunc i64 %other to i51
  %condition = icmp slt i51 %a, %b
  %wide = zext i1 %condition to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_cmp_sle_51(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i51
  %b = trunc i64 %other to i51
  %condition = icmp sle i51 %a, %b
  %wide = zext i1 %condition to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_cmp_sgt_51(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i51
  %b = trunc i64 %other to i51
  %condition = icmp sgt i51 %a, %b
  %wide = zext i1 %condition to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_cmp_sge_51(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i51
  %b = trunc i64 %other to i51
  %condition = icmp sge i51 %a, %b
  %wide = zext i1 %condition to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_cmp_eq_52(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i52
  %b = trunc i64 %other to i52
  %condition = icmp eq i52 %a, %b
  %wide = zext i1 %condition to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_cmp_ne_52(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i52
  %b = trunc i64 %other to i52
  %condition = icmp ne i52 %a, %b
  %wide = zext i1 %condition to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_cmp_ult_52(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i52
  %b = trunc i64 %other to i52
  %condition = icmp ult i52 %a, %b
  %wide = zext i1 %condition to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_cmp_ule_52(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i52
  %b = trunc i64 %other to i52
  %condition = icmp ule i52 %a, %b
  %wide = zext i1 %condition to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_cmp_ugt_52(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i52
  %b = trunc i64 %other to i52
  %condition = icmp ugt i52 %a, %b
  %wide = zext i1 %condition to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_cmp_uge_52(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i52
  %b = trunc i64 %other to i52
  %condition = icmp uge i52 %a, %b
  %wide = zext i1 %condition to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_cmp_slt_52(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i52
  %b = trunc i64 %other to i52
  %condition = icmp slt i52 %a, %b
  %wide = zext i1 %condition to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_cmp_sle_52(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i52
  %b = trunc i64 %other to i52
  %condition = icmp sle i52 %a, %b
  %wide = zext i1 %condition to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_cmp_sgt_52(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i52
  %b = trunc i64 %other to i52
  %condition = icmp sgt i52 %a, %b
  %wide = zext i1 %condition to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_cmp_sge_52(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i52
  %b = trunc i64 %other to i52
  %condition = icmp sge i52 %a, %b
  %wide = zext i1 %condition to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_cmp_eq_63(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i63
  %b = trunc i64 %other to i63
  %condition = icmp eq i63 %a, %b
  %wide = zext i1 %condition to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_cmp_ne_63(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i63
  %b = trunc i64 %other to i63
  %condition = icmp ne i63 %a, %b
  %wide = zext i1 %condition to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_cmp_ult_63(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i63
  %b = trunc i64 %other to i63
  %condition = icmp ult i63 %a, %b
  %wide = zext i1 %condition to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_cmp_ule_63(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i63
  %b = trunc i64 %other to i63
  %condition = icmp ule i63 %a, %b
  %wide = zext i1 %condition to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_cmp_ugt_63(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i63
  %b = trunc i64 %other to i63
  %condition = icmp ugt i63 %a, %b
  %wide = zext i1 %condition to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_cmp_uge_63(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i63
  %b = trunc i64 %other to i63
  %condition = icmp uge i63 %a, %b
  %wide = zext i1 %condition to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_cmp_slt_63(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i63
  %b = trunc i64 %other to i63
  %condition = icmp slt i63 %a, %b
  %wide = zext i1 %condition to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_cmp_sle_63(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i63
  %b = trunc i64 %other to i63
  %condition = icmp sle i63 %a, %b
  %wide = zext i1 %condition to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_cmp_sgt_63(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i63
  %b = trunc i64 %other to i63
  %condition = icmp sgt i63 %a, %b
  %wide = zext i1 %condition to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_cmp_sge_63(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i63
  %b = trunc i64 %other to i63
  %condition = icmp sge i63 %a, %b
  %wide = zext i1 %condition to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_sext_1_31(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i1
  %extended = sext i1 %a to i31
  %wide = zext i31 %extended to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_sext_1_32(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i1
  %extended = sext i1 %a to i32
  %wide = zext i32 %extended to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_sext_1_64(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i1
  %extended = sext i1 %a to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %extended, %live
  ret i64 %answer
}

define i64 @integer_forms_sext_2_31(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i2
  %extended = sext i2 %a to i31
  %wide = zext i31 %extended to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_sext_2_32(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i2
  %extended = sext i2 %a to i32
  %wide = zext i32 %extended to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_sext_2_64(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i2
  %extended = sext i2 %a to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %extended, %live
  ret i64 %answer
}

define i64 @integer_forms_sext_7_31(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i7
  %extended = sext i7 %a to i31
  %wide = zext i31 %extended to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_sext_7_32(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i7
  %extended = sext i7 %a to i32
  %wide = zext i32 %extended to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_sext_7_64(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i7
  %extended = sext i7 %a to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %extended, %live
  ret i64 %answer
}

define i64 @integer_forms_sext_8_31(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i8
  %extended = sext i8 %a to i31
  %wide = zext i31 %extended to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_sext_8_32(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i8
  %extended = sext i8 %a to i32
  %wide = zext i32 %extended to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_sext_8_64(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i8
  %extended = sext i8 %a to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %extended, %live
  ret i64 %answer
}

define i64 @integer_forms_sext_16_31(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i16
  %extended = sext i16 %a to i31
  %wide = zext i31 %extended to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_sext_16_32(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i16
  %extended = sext i16 %a to i32
  %wide = zext i32 %extended to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_sext_16_64(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i16
  %extended = sext i16 %a to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %extended, %live
  ret i64 %answer
}

define i64 @integer_forms_sext_17_31(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i17
  %extended = sext i17 %a to i31
  %wide = zext i31 %extended to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_sext_17_32(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i17
  %extended = sext i17 %a to i32
  %wide = zext i32 %extended to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_sext_17_64(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i17
  %extended = sext i17 %a to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %extended, %live
  ret i64 %answer
}

define i64 @integer_forms_sext_24_31(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i24
  %extended = sext i24 %a to i31
  %wide = zext i31 %extended to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_sext_24_32(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i24
  %extended = sext i24 %a to i32
  %wide = zext i32 %extended to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_sext_24_64(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i24
  %extended = sext i24 %a to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %extended, %live
  ret i64 %answer
}

define i64 @integer_forms_sext_31_32(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i31
  %extended = sext i31 %a to i32
  %wide = zext i32 %extended to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

define i64 @integer_forms_sext_31_64(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i31
  %extended = sext i31 %a to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %extended, %live
  ret i64 %answer
}

define i64 @integer_forms_sext_32_64(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i32
  %extended = sext i32 %a to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %extended, %live
  ret i64 %answer
}

define i64 @integer_forms_sext_33_64(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i33
  %extended = sext i33 %a to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %extended, %live
  ret i64 %answer
}

define i64 @integer_forms_sext_63_64(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i63
  %extended = sext i63 %a to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %extended, %live
  ret i64 %answer
}

declare i17 @integer_forms_narrow_return_17(i64)
define internal i17 @integer_forms_local_17(i17 %value) {
entry:
  %sum = add i17 %value, 17
  ret i17 %sum
}

define i64 @integer_forms_abi_17(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i17
  %local = call i17 @integer_forms_local_17(i17 %a)
  %external = call i17 @integer_forms_narrow_return_17(i64 %other)
  %joined = xor i17 %local, %external
  %wide = zext i17 %joined to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

declare i18 @integer_forms_narrow_return_18(i64)
define internal i18 @integer_forms_local_18(i18 %value) {
entry:
  %sum = add i18 %value, 17
  ret i18 %sum
}

define i64 @integer_forms_abi_18(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i18
  %local = call i18 @integer_forms_local_18(i18 %a)
  %external = call i18 @integer_forms_narrow_return_18(i64 %other)
  %joined = xor i18 %local, %external
  %wide = zext i18 %joined to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

declare i23 @integer_forms_narrow_return_23(i64)
define internal i23 @integer_forms_local_23(i23 %value) {
entry:
  %sum = add i23 %value, 17
  ret i23 %sum
}

define i64 @integer_forms_abi_23(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i23
  %local = call i23 @integer_forms_local_23(i23 %a)
  %external = call i23 @integer_forms_narrow_return_23(i64 %other)
  %joined = xor i23 %local, %external
  %wide = zext i23 %joined to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

declare i24 @integer_forms_narrow_return_24(i64)
define internal i24 @integer_forms_local_24(i24 %value) {
entry:
  %sum = add i24 %value, 17
  ret i24 %sum
}

define i64 @integer_forms_abi_24(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i24
  %local = call i24 @integer_forms_local_24(i24 %a)
  %external = call i24 @integer_forms_narrow_return_24(i64 %other)
  %joined = xor i24 %local, %external
  %wide = zext i24 %joined to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

declare i30 @integer_forms_narrow_return_30(i64)
define internal i30 @integer_forms_local_30(i30 %value) {
entry:
  %sum = add i30 %value, 17
  ret i30 %sum
}

define i64 @integer_forms_abi_30(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i30
  %local = call i30 @integer_forms_local_30(i30 %a)
  %external = call i30 @integer_forms_narrow_return_30(i64 %other)
  %joined = xor i30 %local, %external
  %wide = zext i30 %joined to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

declare i31 @integer_forms_narrow_return_31(i64)
define internal i31 @integer_forms_local_31(i31 %value) {
entry:
  %sum = add i31 %value, 17
  ret i31 %sum
}

define i64 @integer_forms_abi_31(i64 %input, i64 %other, i64 %live, ptr %out) {
entry:
  %a = trunc i64 %input to i31
  %local = call i31 @integer_forms_local_31(i31 %a)
  %external = call i31 @integer_forms_narrow_return_31(i64 %other)
  %joined = xor i31 %local, %external
  %wide = zext i31 %joined to i64
  %noise = call i64 @integer_forms_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %answer = xor i64 %wide, %live
  ret i64 %answer
}

