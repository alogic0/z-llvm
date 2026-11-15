target triple = "x86_64-unknown-linux-gnu"
declare i64 @preopt_scalar_touch(ptr)

define i64 @scalar_mul32_loaded(ptr %left, ptr %right, i64 %keep) {
entry:
  %a = load i32, ptr %left, align 1
  %b = load i32, ptr %right, align 1
  %product = mul i32 %a, %b
  %wide = zext i32 %product to i64
  %wa = zext i32 %a to i64
  %wb = zext i32 %b to i64
  %mix = xor i64 %wide, %wa
  %mix2 = xor i64 %mix, %wb
  %answer = xor i64 %mix2, %keep
  ret i64 %answer
}

define i64 @scalar_mul32_zext(ptr %left, ptr %right, i64 %keep) {
entry:
  %shorta = load i16, ptr %left, align 1
  %shortb = load i16, ptr %right, align 1
  %a = zext i16 %shorta to i32
  %b = zext i16 %shortb to i32
  %product = mul i32 %a, %b
  %wide = zext i32 %product to i64
  %wa = zext i32 %a to i64
  %wb = zext i32 %b to i64
  %mix = xor i64 %wide, %wa
  %mix2 = xor i64 %mix, %wb
  %answer = xor i64 %mix2, %keep
  ret i64 %answer
}

define i64 @scalar_mul32_square(ptr %left, ptr %right, i64 %keep) {
entry:
  %a = load i32, ptr %left, align 1
  %product = mul i32 %a, %a
  %wide = zext i32 %product to i64
  %wa = zext i32 %a to i64
  %mix = xor i64 %wide, %wa
  %answer = xor i64 %mix, %keep
  ret i64 %answer
}

define i64 @scalar_sub64_large(ptr %unused, i64 %a, i64 %b, i64 %c, i64 %d) {
entry:
  %slot = alloca i64, align 8
  store i64 %a, ptr %slot, align 8
  %loaded = call i64 @preopt_scalar_touch(ptr %slot)
  %result = sub i64 %loaded, 2147483648
  %mix = xor i64 %result, %a
  %mix2 = xor i64 %mix, %b
  %mix3 = xor i64 %mix2, %c
  %answer = xor i64 %mix3, %d
  ret i64 %answer
}

define i64 @scalar_sub64_exponent(ptr %unused, i64 %a, i64 %b, i64 %c, i64 %d) {
entry:
  %slot = alloca i64, align 8
  store i64 %a, ptr %slot, align 8
  %loaded = call i64 @preopt_scalar_touch(ptr %slot)
  %result = sub i64 %loaded, 4503599627370496
  %mix = xor i64 %result, %a
  %mix2 = xor i64 %mix, %b
  %mix3 = xor i64 %mix2, %c
  %answer = xor i64 %mix3, %d
  ret i64 %answer
}

define i64 @scalar_sub64_negative_min32(ptr %unused, i64 %a, i64 %b, i64 %c, i64 %d) {
entry:
  %slot = alloca i64, align 8
  store i64 %a, ptr %slot, align 8
  %loaded = call i64 @preopt_scalar_touch(ptr %slot)
  %result = sub i64 %loaded, -2147483648
  %mix = xor i64 %result, %a
  %mix2 = xor i64 %mix, %b
  %mix3 = xor i64 %mix2, %c
  %answer = xor i64 %mix3, %d
  ret i64 %answer
}

define i64 @scalar_sub64_signbit(ptr %unused, i64 %a, i64 %b, i64 %c, i64 %d) {
entry:
  %slot = alloca i64, align 8
  store i64 %a, ptr %slot, align 8
  %loaded = call i64 @preopt_scalar_touch(ptr %slot)
  %result = sub i64 %loaded, 9223372036854775808
  %mix = xor i64 %result, %a
  %mix2 = xor i64 %mix, %b
  %mix3 = xor i64 %mix2, %c
  %answer = xor i64 %mix3, %d
  ret i64 %answer
}

define i64 @scalar_sub32_signbit(ptr %unused, i64 %a, i64 %b, i64 %c, i64 %d) {
entry:
  %slot = alloca i64, align 8
  store i64 %a, ptr %slot, align 8
  %loaded = call i64 @preopt_scalar_touch(ptr %slot)
  %low = trunc i64 %loaded to i32
  %result = sub i32 %low, 2147483648
  %wide = zext i32 %result to i64
  %mix = xor i64 %wide, %a
  %mix2 = xor i64 %mix, %b
  %mix3 = xor i64 %mix2, %c
  %answer = xor i64 %mix3, %d
  ret i64 %answer
}
