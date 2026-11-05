declare void @remainder_touch(ptr)

define i64 @remainder_u8(ptr %storage, i64 %take, i64 %left, i64 %right, ptr %out) {
entry:
  %saved = alloca i64, align 8
  store i64 %left, ptr %saved, align 8
  call void @remainder_touch(ptr %saved)
  %condition = icmp ne i64 %take, 0
  br i1 %condition, label %calculate, label %empty
calculate:
  %input = load i8, ptr %storage, align 8
  %remainder = urem i8 %input, 128
  %value = zext i8 %remainder to i64
  %original = zext i8 %input to i64
  store i64 %value, ptr %out, align 8
  %live = load i64, ptr %saved, align 8
  %a = xor i64 %value, %original
  %b = xor i64 %a, %live
  %c = xor i64 %b, %right
  %result = xor i64 %c, %take
  ret i64 %result
empty:
  store i64 0, ptr %out, align 8
  %empty_live = load i64, ptr %saved, align 8
  %empty_a = xor i64 %empty_live, %right
  %empty_result = xor i64 %empty_a, %take
  ret i64 %empty_result
}

define i64 @remainder_u16(ptr %storage, i64 %take, i64 %left, i64 %right, ptr %out) {
entry:
  %saved = alloca i64, align 8
  store i64 %left, ptr %saved, align 8
  call void @remainder_touch(ptr %saved)
  %condition = icmp ne i64 %take, 0
  br i1 %condition, label %calculate, label %empty
calculate:
  %input = load i16, ptr %storage, align 8
  %remainder = urem i16 %input, 32768
  %value = zext i16 %remainder to i64
  %original = zext i16 %input to i64
  store i64 %value, ptr %out, align 8
  %live = load i64, ptr %saved, align 8
  %a = xor i64 %value, %original
  %b = xor i64 %a, %live
  %c = xor i64 %b, %right
  %result = xor i64 %c, %take
  ret i64 %result
empty:
  store i64 0, ptr %out, align 8
  %empty_live = load i64, ptr %saved, align 8
  %empty_a = xor i64 %empty_live, %right
  %empty_result = xor i64 %empty_a, %take
  ret i64 %empty_result
}

define i64 @remainder_u32(ptr %storage, i64 %take, i64 %left, i64 %right, ptr %out) {
entry:
  %saved = alloca i64, align 8
  store i64 %left, ptr %saved, align 8
  call void @remainder_touch(ptr %saved)
  %condition = icmp ne i64 %take, 0
  br i1 %condition, label %calculate, label %empty
calculate:
  %input = load i32, ptr %storage, align 8
  %remainder = urem i32 %input, 2147483648
  %value = zext i32 %remainder to i64
  %original = zext i32 %input to i64
  store i64 %value, ptr %out, align 8
  %live = load i64, ptr %saved, align 8
  %a = xor i64 %value, %original
  %b = xor i64 %a, %live
  %c = xor i64 %b, %right
  %result = xor i64 %c, %take
  ret i64 %result
empty:
  store i64 0, ptr %out, align 8
  %empty_live = load i64, ptr %saved, align 8
  %empty_a = xor i64 %empty_live, %right
  %empty_result = xor i64 %empty_a, %take
  ret i64 %empty_result
}

define i64 @remainder_u64(ptr %storage, i64 %take, i64 %left, i64 %right, ptr %out) {
entry:
  %saved = alloca i64, align 8
  store i64 %left, ptr %saved, align 8
  call void @remainder_touch(ptr %saved)
  %condition = icmp ne i64 %take, 0
  br i1 %condition, label %calculate, label %empty
calculate:
  %input = load i64, ptr %storage, align 8
  %remainder = urem i64 %input, 9223372036854775808
  %value = add i64 %remainder, 0
  %original = add i64 %input, 0
  store i64 %value, ptr %out, align 8
  %live = load i64, ptr %saved, align 8
  %a = xor i64 %value, %original
  %b = xor i64 %a, %live
  %c = xor i64 %b, %right
  %result = xor i64 %c, %take
  ret i64 %result
empty:
  store i64 0, ptr %out, align 8
  %empty_live = load i64, ptr %saved, align 8
  %empty_a = xor i64 %empty_live, %right
  %empty_result = xor i64 %empty_a, %take
  ret i64 %empty_result
}

define i64 @remainder_signed_spelling(ptr %storage, i64 %take, i64 %left, i64 %right, ptr %out) {
entry:
  %saved = alloca i64, align 8
  store i64 %left, ptr %saved, align 8
  call void @remainder_touch(ptr %saved)
  %condition = icmp ne i64 %take, 0
  br i1 %condition, label %calculate, label %empty
calculate:
  %input = load i64, ptr %storage, align 8
  %remainder = urem i64 %input, -9223372036854775808
  %value = add i64 %remainder, 0
  %original = add i64 %input, 0
  store i64 %value, ptr %out, align 8
  %live = load i64, ptr %saved, align 8
  %a = xor i64 %value, %original
  %b = xor i64 %a, %live
  %c = xor i64 %b, %right
  %result = xor i64 %c, %take
  ret i64 %result
empty:
  store i64 0, ptr %out, align 8
  %empty_live = load i64, ptr %saved, align 8
  %empty_a = xor i64 %empty_live, %right
  %empty_result = xor i64 %empty_a, %take
  ret i64 %empty_result
}

define i64 @remainder_one(ptr %storage, i64 %take, i64 %left, i64 %right, ptr %out) {
entry:
  %saved = alloca i64, align 8
  store i64 %left, ptr %saved, align 8
  call void @remainder_touch(ptr %saved)
  %condition = icmp ne i64 %take, 0
  br i1 %condition, label %calculate, label %empty
calculate:
  %input = load i64, ptr %storage, align 8
  %remainder = urem i64 %input, 1
  %value = add i64 %remainder, 0
  %original = add i64 %input, 0
  store i64 %value, ptr %out, align 8
  %live = load i64, ptr %saved, align 8
  %a = xor i64 %value, %original
  %b = xor i64 %a, %live
  %c = xor i64 %b, %right
  %result = xor i64 %c, %take
  ret i64 %result
empty:
  store i64 0, ptr %out, align 8
  %empty_live = load i64, ptr %saved, align 8
  %empty_a = xor i64 %empty_live, %right
  %empty_result = xor i64 %empty_a, %take
  ret i64 %empty_result
}

define i64 @remainder_page(ptr %storage, i64 %take, i64 %left, i64 %right, ptr %out) {
entry:
  %saved = alloca i64, align 8
  store i64 %left, ptr %saved, align 8
  call void @remainder_touch(ptr %saved)
  %condition = icmp ne i64 %take, 0
  br i1 %condition, label %calculate, label %empty
calculate:
  %input = load i64, ptr %storage, align 8
  %remainder = urem i64 %input, 4096
  %value = add i64 %remainder, 0
  %original = add i64 %input, 0
  store i64 %value, ptr %out, align 8
  %live = load i64, ptr %saved, align 8
  %a = xor i64 %value, %original
  %b = xor i64 %a, %live
  %c = xor i64 %b, %right
  %result = xor i64 %c, %take
  ret i64 %result
empty:
  store i64 0, ptr %out, align 8
  %empty_live = load i64, ptr %saved, align 8
  %empty_a = xor i64 %empty_live, %right
  %empty_result = xor i64 %empty_a, %take
  ret i64 %empty_result
}

define i64 @remainder_word(ptr %storage, i64 %take, i64 %left, i64 %right, ptr %out) {
entry:
  %saved = alloca i64, align 8
  store i64 %left, ptr %saved, align 8
  call void @remainder_touch(ptr %saved)
  %condition = icmp ne i64 %take, 0
  br i1 %condition, label %calculate, label %empty
calculate:
  %input = load i64, ptr %storage, align 8
  %remainder = urem i64 %input, 4294967296
  %value = add i64 %remainder, 0
  %original = add i64 %input, 0
  store i64 %value, ptr %out, align 8
  %live = load i64, ptr %saved, align 8
  %a = xor i64 %value, %original
  %b = xor i64 %a, %live
  %c = xor i64 %b, %right
  %result = xor i64 %c, %take
  ret i64 %result
empty:
  store i64 0, ptr %out, align 8
  %empty_live = load i64, ptr %saved, align 8
  %empty_a = xor i64 %empty_live, %right
  %empty_result = xor i64 %empty_a, %take
  ret i64 %empty_result
}
