target triple = "x86_64-unknown-linux-gnu"

declare { i1, i1 } @llvm.uadd.with.overflow.i1(i1, i1)

declare { i1, i1 } @llvm.usub.with.overflow.i1(i1, i1)

declare { i1, i1 } @llvm.umul.with.overflow.i1(i1, i1)

declare { i1, i1 } @llvm.sadd.with.overflow.i1(i1, i1)

declare { i1, i1 } @llvm.ssub.with.overflow.i1(i1, i1)

declare { i1, i1 } @llvm.smul.with.overflow.i1(i1, i1)

declare { i3, i1 } @llvm.uadd.with.overflow.i3(i3, i3)

declare { i3, i1 } @llvm.usub.with.overflow.i3(i3, i3)

declare { i3, i1 } @llvm.umul.with.overflow.i3(i3, i3)

declare { i3, i1 } @llvm.sadd.with.overflow.i3(i3, i3)

declare { i3, i1 } @llvm.ssub.with.overflow.i3(i3, i3)

declare { i3, i1 } @llvm.smul.with.overflow.i3(i3, i3)

declare { i8, i1 } @llvm.uadd.with.overflow.i8(i8, i8)

declare { i8, i1 } @llvm.usub.with.overflow.i8(i8, i8)

declare { i8, i1 } @llvm.umul.with.overflow.i8(i8, i8)

declare { i8, i1 } @llvm.sadd.with.overflow.i8(i8, i8)

declare { i8, i1 } @llvm.ssub.with.overflow.i8(i8, i8)

declare { i8, i1 } @llvm.smul.with.overflow.i8(i8, i8)

declare { i16, i1 } @llvm.uadd.with.overflow.i16(i16, i16)

declare { i16, i1 } @llvm.usub.with.overflow.i16(i16, i16)

declare { i16, i1 } @llvm.umul.with.overflow.i16(i16, i16)

declare { i16, i1 } @llvm.sadd.with.overflow.i16(i16, i16)

declare { i16, i1 } @llvm.ssub.with.overflow.i16(i16, i16)

declare { i16, i1 } @llvm.smul.with.overflow.i16(i16, i16)

declare { i31, i1 } @llvm.uadd.with.overflow.i31(i31, i31)

declare { i31, i1 } @llvm.usub.with.overflow.i31(i31, i31)

declare { i31, i1 } @llvm.umul.with.overflow.i31(i31, i31)

declare { i31, i1 } @llvm.sadd.with.overflow.i31(i31, i31)

declare { i31, i1 } @llvm.ssub.with.overflow.i31(i31, i31)

declare { i31, i1 } @llvm.smul.with.overflow.i31(i31, i31)

declare { i32, i1 } @llvm.uadd.with.overflow.i32(i32, i32)

declare { i32, i1 } @llvm.usub.with.overflow.i32(i32, i32)

declare { i32, i1 } @llvm.umul.with.overflow.i32(i32, i32)

declare { i32, i1 } @llvm.sadd.with.overflow.i32(i32, i32)

declare { i32, i1 } @llvm.ssub.with.overflow.i32(i32, i32)

declare { i32, i1 } @llvm.smul.with.overflow.i32(i32, i32)

declare { i64, i1 } @llvm.uadd.with.overflow.i64(i64, i64)

declare { i64, i1 } @llvm.usub.with.overflow.i64(i64, i64)

declare i1 @checked_boolean_ptr(ptr)

declare i1 @checked_boolean_six(i64, i64, i64, i64, i64, i64)

declare i1 @checked_boolean_eight(i64, i64, i64, i64, i64, i64, i64, i64)

define i64 @checked_uadd_1_0(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i1
  %b = trunc i64 %input_b to i1
  %pair = call { i1, i1 } @llvm.uadd.with.overflow.i1(i1 %a, i1 %b)
  %flag = extractvalue { i1, i1 } %pair, 1
  %value = extractvalue { i1, i1 } %pair, 0
  %wide = zext i1 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_uadd_1_1(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i1
  %b = trunc i64 %input_b to i1
  %pair = call { i1, i1 } @llvm.uadd.with.overflow.i1(i1 -1, i1 %b)
  %flag = extractvalue { i1, i1 } %pair, 1
  %value = extractvalue { i1, i1 } %pair, 0
  %wide = zext i1 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_uadd_1_2(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i1
  %b = trunc i64 %input_b to i1
  %pair = call { i1, i1 } @llvm.uadd.with.overflow.i1(i1 %a, i1 -1)
  %flag = extractvalue { i1, i1 } %pair, 1
  %value = extractvalue { i1, i1 } %pair, 0
  %wide = zext i1 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_usub_1_0(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i1
  %b = trunc i64 %input_b to i1
  %pair = call { i1, i1 } @llvm.usub.with.overflow.i1(i1 %a, i1 %b)
  %flag = extractvalue { i1, i1 } %pair, 1
  %value = extractvalue { i1, i1 } %pair, 0
  %wide = zext i1 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_usub_1_1(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i1
  %b = trunc i64 %input_b to i1
  %pair = call { i1, i1 } @llvm.usub.with.overflow.i1(i1 -1, i1 %b)
  %flag = extractvalue { i1, i1 } %pair, 1
  %value = extractvalue { i1, i1 } %pair, 0
  %wide = zext i1 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_usub_1_2(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i1
  %b = trunc i64 %input_b to i1
  %pair = call { i1, i1 } @llvm.usub.with.overflow.i1(i1 %a, i1 -1)
  %flag = extractvalue { i1, i1 } %pair, 1
  %value = extractvalue { i1, i1 } %pair, 0
  %wide = zext i1 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_umul_1_0(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i1
  %b = trunc i64 %input_b to i1
  %pair = call { i1, i1 } @llvm.umul.with.overflow.i1(i1 %a, i1 %b)
  %flag = extractvalue { i1, i1 } %pair, 1
  %value = extractvalue { i1, i1 } %pair, 0
  %wide = zext i1 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_umul_1_1(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i1
  %b = trunc i64 %input_b to i1
  %pair = call { i1, i1 } @llvm.umul.with.overflow.i1(i1 -1, i1 %b)
  %flag = extractvalue { i1, i1 } %pair, 1
  %value = extractvalue { i1, i1 } %pair, 0
  %wide = zext i1 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_umul_1_2(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i1
  %b = trunc i64 %input_b to i1
  %pair = call { i1, i1 } @llvm.umul.with.overflow.i1(i1 %a, i1 -1)
  %flag = extractvalue { i1, i1 } %pair, 1
  %value = extractvalue { i1, i1 } %pair, 0
  %wide = zext i1 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_sadd_1_0(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i1
  %b = trunc i64 %input_b to i1
  %pair = call { i1, i1 } @llvm.sadd.with.overflow.i1(i1 %a, i1 %b)
  %flag = extractvalue { i1, i1 } %pair, 1
  %value = extractvalue { i1, i1 } %pair, 0
  %wide = zext i1 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_sadd_1_1(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i1
  %b = trunc i64 %input_b to i1
  %pair = call { i1, i1 } @llvm.sadd.with.overflow.i1(i1 -1, i1 %b)
  %flag = extractvalue { i1, i1 } %pair, 1
  %value = extractvalue { i1, i1 } %pair, 0
  %wide = zext i1 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_sadd_1_2(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i1
  %b = trunc i64 %input_b to i1
  %pair = call { i1, i1 } @llvm.sadd.with.overflow.i1(i1 %a, i1 -1)
  %flag = extractvalue { i1, i1 } %pair, 1
  %value = extractvalue { i1, i1 } %pair, 0
  %wide = zext i1 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_ssub_1_0(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i1
  %b = trunc i64 %input_b to i1
  %pair = call { i1, i1 } @llvm.ssub.with.overflow.i1(i1 %a, i1 %b)
  %flag = extractvalue { i1, i1 } %pair, 1
  %value = extractvalue { i1, i1 } %pair, 0
  %wide = zext i1 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_ssub_1_1(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i1
  %b = trunc i64 %input_b to i1
  %pair = call { i1, i1 } @llvm.ssub.with.overflow.i1(i1 -1, i1 %b)
  %flag = extractvalue { i1, i1 } %pair, 1
  %value = extractvalue { i1, i1 } %pair, 0
  %wide = zext i1 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_ssub_1_2(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i1
  %b = trunc i64 %input_b to i1
  %pair = call { i1, i1 } @llvm.ssub.with.overflow.i1(i1 %a, i1 -1)
  %flag = extractvalue { i1, i1 } %pair, 1
  %value = extractvalue { i1, i1 } %pair, 0
  %wide = zext i1 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_smul_1_0(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i1
  %b = trunc i64 %input_b to i1
  %pair = call { i1, i1 } @llvm.smul.with.overflow.i1(i1 %a, i1 %b)
  %flag = extractvalue { i1, i1 } %pair, 1
  %value = extractvalue { i1, i1 } %pair, 0
  %wide = zext i1 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_smul_1_1(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i1
  %b = trunc i64 %input_b to i1
  %pair = call { i1, i1 } @llvm.smul.with.overflow.i1(i1 -1, i1 %b)
  %flag = extractvalue { i1, i1 } %pair, 1
  %value = extractvalue { i1, i1 } %pair, 0
  %wide = zext i1 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_smul_1_2(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i1
  %b = trunc i64 %input_b to i1
  %pair = call { i1, i1 } @llvm.smul.with.overflow.i1(i1 %a, i1 -1)
  %flag = extractvalue { i1, i1 } %pair, 1
  %value = extractvalue { i1, i1 } %pair, 0
  %wide = zext i1 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_uadd_3_0(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i3
  %b = trunc i64 %input_b to i3
  %pair = call { i3, i1 } @llvm.uadd.with.overflow.i3(i3 %a, i3 %b)
  %flag = extractvalue { i3, i1 } %pair, 1
  %value = extractvalue { i3, i1 } %pair, 0
  %wide = zext i3 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_uadd_3_1(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i3
  %b = trunc i64 %input_b to i3
  %pair = call { i3, i1 } @llvm.uadd.with.overflow.i3(i3 -1, i3 %b)
  %flag = extractvalue { i3, i1 } %pair, 1
  %value = extractvalue { i3, i1 } %pair, 0
  %wide = zext i3 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_uadd_3_2(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i3
  %b = trunc i64 %input_b to i3
  %pair = call { i3, i1 } @llvm.uadd.with.overflow.i3(i3 %a, i3 -1)
  %flag = extractvalue { i3, i1 } %pair, 1
  %value = extractvalue { i3, i1 } %pair, 0
  %wide = zext i3 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_usub_3_0(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i3
  %b = trunc i64 %input_b to i3
  %pair = call { i3, i1 } @llvm.usub.with.overflow.i3(i3 %a, i3 %b)
  %flag = extractvalue { i3, i1 } %pair, 1
  %value = extractvalue { i3, i1 } %pair, 0
  %wide = zext i3 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_usub_3_1(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i3
  %b = trunc i64 %input_b to i3
  %pair = call { i3, i1 } @llvm.usub.with.overflow.i3(i3 -1, i3 %b)
  %flag = extractvalue { i3, i1 } %pair, 1
  %value = extractvalue { i3, i1 } %pair, 0
  %wide = zext i3 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_usub_3_2(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i3
  %b = trunc i64 %input_b to i3
  %pair = call { i3, i1 } @llvm.usub.with.overflow.i3(i3 %a, i3 -1)
  %flag = extractvalue { i3, i1 } %pair, 1
  %value = extractvalue { i3, i1 } %pair, 0
  %wide = zext i3 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_umul_3_0(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i3
  %b = trunc i64 %input_b to i3
  %pair = call { i3, i1 } @llvm.umul.with.overflow.i3(i3 %a, i3 %b)
  %flag = extractvalue { i3, i1 } %pair, 1
  %value = extractvalue { i3, i1 } %pair, 0
  %wide = zext i3 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_umul_3_1(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i3
  %b = trunc i64 %input_b to i3
  %pair = call { i3, i1 } @llvm.umul.with.overflow.i3(i3 -1, i3 %b)
  %flag = extractvalue { i3, i1 } %pair, 1
  %value = extractvalue { i3, i1 } %pair, 0
  %wide = zext i3 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_umul_3_2(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i3
  %b = trunc i64 %input_b to i3
  %pair = call { i3, i1 } @llvm.umul.with.overflow.i3(i3 %a, i3 -1)
  %flag = extractvalue { i3, i1 } %pair, 1
  %value = extractvalue { i3, i1 } %pair, 0
  %wide = zext i3 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_sadd_3_0(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i3
  %b = trunc i64 %input_b to i3
  %pair = call { i3, i1 } @llvm.sadd.with.overflow.i3(i3 %a, i3 %b)
  %flag = extractvalue { i3, i1 } %pair, 1
  %value = extractvalue { i3, i1 } %pair, 0
  %wide = zext i3 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_sadd_3_1(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i3
  %b = trunc i64 %input_b to i3
  %pair = call { i3, i1 } @llvm.sadd.with.overflow.i3(i3 -1, i3 %b)
  %flag = extractvalue { i3, i1 } %pair, 1
  %value = extractvalue { i3, i1 } %pair, 0
  %wide = zext i3 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_sadd_3_2(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i3
  %b = trunc i64 %input_b to i3
  %pair = call { i3, i1 } @llvm.sadd.with.overflow.i3(i3 %a, i3 -1)
  %flag = extractvalue { i3, i1 } %pair, 1
  %value = extractvalue { i3, i1 } %pair, 0
  %wide = zext i3 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_ssub_3_0(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i3
  %b = trunc i64 %input_b to i3
  %pair = call { i3, i1 } @llvm.ssub.with.overflow.i3(i3 %a, i3 %b)
  %flag = extractvalue { i3, i1 } %pair, 1
  %value = extractvalue { i3, i1 } %pair, 0
  %wide = zext i3 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_ssub_3_1(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i3
  %b = trunc i64 %input_b to i3
  %pair = call { i3, i1 } @llvm.ssub.with.overflow.i3(i3 -1, i3 %b)
  %flag = extractvalue { i3, i1 } %pair, 1
  %value = extractvalue { i3, i1 } %pair, 0
  %wide = zext i3 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_ssub_3_2(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i3
  %b = trunc i64 %input_b to i3
  %pair = call { i3, i1 } @llvm.ssub.with.overflow.i3(i3 %a, i3 -1)
  %flag = extractvalue { i3, i1 } %pair, 1
  %value = extractvalue { i3, i1 } %pair, 0
  %wide = zext i3 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_smul_3_0(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i3
  %b = trunc i64 %input_b to i3
  %pair = call { i3, i1 } @llvm.smul.with.overflow.i3(i3 %a, i3 %b)
  %flag = extractvalue { i3, i1 } %pair, 1
  %value = extractvalue { i3, i1 } %pair, 0
  %wide = zext i3 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_smul_3_1(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i3
  %b = trunc i64 %input_b to i3
  %pair = call { i3, i1 } @llvm.smul.with.overflow.i3(i3 -1, i3 %b)
  %flag = extractvalue { i3, i1 } %pair, 1
  %value = extractvalue { i3, i1 } %pair, 0
  %wide = zext i3 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_smul_3_2(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i3
  %b = trunc i64 %input_b to i3
  %pair = call { i3, i1 } @llvm.smul.with.overflow.i3(i3 %a, i3 -1)
  %flag = extractvalue { i3, i1 } %pair, 1
  %value = extractvalue { i3, i1 } %pair, 0
  %wide = zext i3 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_uadd_8_0(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i8
  %b = trunc i64 %input_b to i8
  %pair = call { i8, i1 } @llvm.uadd.with.overflow.i8(i8 %a, i8 %b)
  %flag = extractvalue { i8, i1 } %pair, 1
  %value = extractvalue { i8, i1 } %pair, 0
  %wide = zext i8 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_uadd_8_1(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i8
  %b = trunc i64 %input_b to i8
  %pair = call { i8, i1 } @llvm.uadd.with.overflow.i8(i8 -1, i8 %b)
  %flag = extractvalue { i8, i1 } %pair, 1
  %value = extractvalue { i8, i1 } %pair, 0
  %wide = zext i8 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_uadd_8_2(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i8
  %b = trunc i64 %input_b to i8
  %pair = call { i8, i1 } @llvm.uadd.with.overflow.i8(i8 %a, i8 -1)
  %flag = extractvalue { i8, i1 } %pair, 1
  %value = extractvalue { i8, i1 } %pair, 0
  %wide = zext i8 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_usub_8_0(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i8
  %b = trunc i64 %input_b to i8
  %pair = call { i8, i1 } @llvm.usub.with.overflow.i8(i8 %a, i8 %b)
  %flag = extractvalue { i8, i1 } %pair, 1
  %value = extractvalue { i8, i1 } %pair, 0
  %wide = zext i8 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_usub_8_1(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i8
  %b = trunc i64 %input_b to i8
  %pair = call { i8, i1 } @llvm.usub.with.overflow.i8(i8 -1, i8 %b)
  %flag = extractvalue { i8, i1 } %pair, 1
  %value = extractvalue { i8, i1 } %pair, 0
  %wide = zext i8 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_usub_8_2(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i8
  %b = trunc i64 %input_b to i8
  %pair = call { i8, i1 } @llvm.usub.with.overflow.i8(i8 %a, i8 -1)
  %flag = extractvalue { i8, i1 } %pair, 1
  %value = extractvalue { i8, i1 } %pair, 0
  %wide = zext i8 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_umul_8_0(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i8
  %b = trunc i64 %input_b to i8
  %pair = call { i8, i1 } @llvm.umul.with.overflow.i8(i8 %a, i8 %b)
  %flag = extractvalue { i8, i1 } %pair, 1
  %value = extractvalue { i8, i1 } %pair, 0
  %wide = zext i8 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_umul_8_1(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i8
  %b = trunc i64 %input_b to i8
  %pair = call { i8, i1 } @llvm.umul.with.overflow.i8(i8 -1, i8 %b)
  %flag = extractvalue { i8, i1 } %pair, 1
  %value = extractvalue { i8, i1 } %pair, 0
  %wide = zext i8 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_umul_8_2(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i8
  %b = trunc i64 %input_b to i8
  %pair = call { i8, i1 } @llvm.umul.with.overflow.i8(i8 %a, i8 -1)
  %flag = extractvalue { i8, i1 } %pair, 1
  %value = extractvalue { i8, i1 } %pair, 0
  %wide = zext i8 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_sadd_8_0(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i8
  %b = trunc i64 %input_b to i8
  %pair = call { i8, i1 } @llvm.sadd.with.overflow.i8(i8 %a, i8 %b)
  %flag = extractvalue { i8, i1 } %pair, 1
  %value = extractvalue { i8, i1 } %pair, 0
  %wide = zext i8 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_sadd_8_1(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i8
  %b = trunc i64 %input_b to i8
  %pair = call { i8, i1 } @llvm.sadd.with.overflow.i8(i8 -1, i8 %b)
  %flag = extractvalue { i8, i1 } %pair, 1
  %value = extractvalue { i8, i1 } %pair, 0
  %wide = zext i8 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_sadd_8_2(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i8
  %b = trunc i64 %input_b to i8
  %pair = call { i8, i1 } @llvm.sadd.with.overflow.i8(i8 %a, i8 -1)
  %flag = extractvalue { i8, i1 } %pair, 1
  %value = extractvalue { i8, i1 } %pair, 0
  %wide = zext i8 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_ssub_8_0(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i8
  %b = trunc i64 %input_b to i8
  %pair = call { i8, i1 } @llvm.ssub.with.overflow.i8(i8 %a, i8 %b)
  %flag = extractvalue { i8, i1 } %pair, 1
  %value = extractvalue { i8, i1 } %pair, 0
  %wide = zext i8 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_ssub_8_1(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i8
  %b = trunc i64 %input_b to i8
  %pair = call { i8, i1 } @llvm.ssub.with.overflow.i8(i8 -1, i8 %b)
  %flag = extractvalue { i8, i1 } %pair, 1
  %value = extractvalue { i8, i1 } %pair, 0
  %wide = zext i8 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_ssub_8_2(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i8
  %b = trunc i64 %input_b to i8
  %pair = call { i8, i1 } @llvm.ssub.with.overflow.i8(i8 %a, i8 -1)
  %flag = extractvalue { i8, i1 } %pair, 1
  %value = extractvalue { i8, i1 } %pair, 0
  %wide = zext i8 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_smul_8_0(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i8
  %b = trunc i64 %input_b to i8
  %pair = call { i8, i1 } @llvm.smul.with.overflow.i8(i8 %a, i8 %b)
  %flag = extractvalue { i8, i1 } %pair, 1
  %value = extractvalue { i8, i1 } %pair, 0
  %wide = zext i8 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_smul_8_1(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i8
  %b = trunc i64 %input_b to i8
  %pair = call { i8, i1 } @llvm.smul.with.overflow.i8(i8 -1, i8 %b)
  %flag = extractvalue { i8, i1 } %pair, 1
  %value = extractvalue { i8, i1 } %pair, 0
  %wide = zext i8 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_smul_8_2(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i8
  %b = trunc i64 %input_b to i8
  %pair = call { i8, i1 } @llvm.smul.with.overflow.i8(i8 %a, i8 -1)
  %flag = extractvalue { i8, i1 } %pair, 1
  %value = extractvalue { i8, i1 } %pair, 0
  %wide = zext i8 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_uadd_16_0(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i16
  %b = trunc i64 %input_b to i16
  %pair = call { i16, i1 } @llvm.uadd.with.overflow.i16(i16 %a, i16 %b)
  %flag = extractvalue { i16, i1 } %pair, 1
  %value = extractvalue { i16, i1 } %pair, 0
  %wide = zext i16 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_uadd_16_1(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i16
  %b = trunc i64 %input_b to i16
  %pair = call { i16, i1 } @llvm.uadd.with.overflow.i16(i16 -1, i16 %b)
  %flag = extractvalue { i16, i1 } %pair, 1
  %value = extractvalue { i16, i1 } %pair, 0
  %wide = zext i16 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_uadd_16_2(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i16
  %b = trunc i64 %input_b to i16
  %pair = call { i16, i1 } @llvm.uadd.with.overflow.i16(i16 %a, i16 -1)
  %flag = extractvalue { i16, i1 } %pair, 1
  %value = extractvalue { i16, i1 } %pair, 0
  %wide = zext i16 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_usub_16_0(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i16
  %b = trunc i64 %input_b to i16
  %pair = call { i16, i1 } @llvm.usub.with.overflow.i16(i16 %a, i16 %b)
  %flag = extractvalue { i16, i1 } %pair, 1
  %value = extractvalue { i16, i1 } %pair, 0
  %wide = zext i16 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_usub_16_1(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i16
  %b = trunc i64 %input_b to i16
  %pair = call { i16, i1 } @llvm.usub.with.overflow.i16(i16 -1, i16 %b)
  %flag = extractvalue { i16, i1 } %pair, 1
  %value = extractvalue { i16, i1 } %pair, 0
  %wide = zext i16 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_usub_16_2(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i16
  %b = trunc i64 %input_b to i16
  %pair = call { i16, i1 } @llvm.usub.with.overflow.i16(i16 %a, i16 -1)
  %flag = extractvalue { i16, i1 } %pair, 1
  %value = extractvalue { i16, i1 } %pair, 0
  %wide = zext i16 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_umul_16_0(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i16
  %b = trunc i64 %input_b to i16
  %pair = call { i16, i1 } @llvm.umul.with.overflow.i16(i16 %a, i16 %b)
  %flag = extractvalue { i16, i1 } %pair, 1
  %value = extractvalue { i16, i1 } %pair, 0
  %wide = zext i16 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_umul_16_1(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i16
  %b = trunc i64 %input_b to i16
  %pair = call { i16, i1 } @llvm.umul.with.overflow.i16(i16 -1, i16 %b)
  %flag = extractvalue { i16, i1 } %pair, 1
  %value = extractvalue { i16, i1 } %pair, 0
  %wide = zext i16 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_umul_16_2(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i16
  %b = trunc i64 %input_b to i16
  %pair = call { i16, i1 } @llvm.umul.with.overflow.i16(i16 %a, i16 -1)
  %flag = extractvalue { i16, i1 } %pair, 1
  %value = extractvalue { i16, i1 } %pair, 0
  %wide = zext i16 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_sadd_16_0(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i16
  %b = trunc i64 %input_b to i16
  %pair = call { i16, i1 } @llvm.sadd.with.overflow.i16(i16 %a, i16 %b)
  %flag = extractvalue { i16, i1 } %pair, 1
  %value = extractvalue { i16, i1 } %pair, 0
  %wide = zext i16 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_sadd_16_1(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i16
  %b = trunc i64 %input_b to i16
  %pair = call { i16, i1 } @llvm.sadd.with.overflow.i16(i16 -1, i16 %b)
  %flag = extractvalue { i16, i1 } %pair, 1
  %value = extractvalue { i16, i1 } %pair, 0
  %wide = zext i16 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_sadd_16_2(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i16
  %b = trunc i64 %input_b to i16
  %pair = call { i16, i1 } @llvm.sadd.with.overflow.i16(i16 %a, i16 -1)
  %flag = extractvalue { i16, i1 } %pair, 1
  %value = extractvalue { i16, i1 } %pair, 0
  %wide = zext i16 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_ssub_16_0(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i16
  %b = trunc i64 %input_b to i16
  %pair = call { i16, i1 } @llvm.ssub.with.overflow.i16(i16 %a, i16 %b)
  %flag = extractvalue { i16, i1 } %pair, 1
  %value = extractvalue { i16, i1 } %pair, 0
  %wide = zext i16 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_ssub_16_1(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i16
  %b = trunc i64 %input_b to i16
  %pair = call { i16, i1 } @llvm.ssub.with.overflow.i16(i16 -1, i16 %b)
  %flag = extractvalue { i16, i1 } %pair, 1
  %value = extractvalue { i16, i1 } %pair, 0
  %wide = zext i16 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_ssub_16_2(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i16
  %b = trunc i64 %input_b to i16
  %pair = call { i16, i1 } @llvm.ssub.with.overflow.i16(i16 %a, i16 -1)
  %flag = extractvalue { i16, i1 } %pair, 1
  %value = extractvalue { i16, i1 } %pair, 0
  %wide = zext i16 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_smul_16_0(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i16
  %b = trunc i64 %input_b to i16
  %pair = call { i16, i1 } @llvm.smul.with.overflow.i16(i16 %a, i16 %b)
  %flag = extractvalue { i16, i1 } %pair, 1
  %value = extractvalue { i16, i1 } %pair, 0
  %wide = zext i16 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_smul_16_1(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i16
  %b = trunc i64 %input_b to i16
  %pair = call { i16, i1 } @llvm.smul.with.overflow.i16(i16 -1, i16 %b)
  %flag = extractvalue { i16, i1 } %pair, 1
  %value = extractvalue { i16, i1 } %pair, 0
  %wide = zext i16 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_smul_16_2(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i16
  %b = trunc i64 %input_b to i16
  %pair = call { i16, i1 } @llvm.smul.with.overflow.i16(i16 %a, i16 -1)
  %flag = extractvalue { i16, i1 } %pair, 1
  %value = extractvalue { i16, i1 } %pair, 0
  %wide = zext i16 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_uadd_31_0(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i31
  %b = trunc i64 %input_b to i31
  %pair = call { i31, i1 } @llvm.uadd.with.overflow.i31(i31 %a, i31 %b)
  %flag = extractvalue { i31, i1 } %pair, 1
  %value = extractvalue { i31, i1 } %pair, 0
  %wide = zext i31 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_uadd_31_1(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i31
  %b = trunc i64 %input_b to i31
  %pair = call { i31, i1 } @llvm.uadd.with.overflow.i31(i31 -1, i31 %b)
  %flag = extractvalue { i31, i1 } %pair, 1
  %value = extractvalue { i31, i1 } %pair, 0
  %wide = zext i31 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_uadd_31_2(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i31
  %b = trunc i64 %input_b to i31
  %pair = call { i31, i1 } @llvm.uadd.with.overflow.i31(i31 %a, i31 -1)
  %flag = extractvalue { i31, i1 } %pair, 1
  %value = extractvalue { i31, i1 } %pair, 0
  %wide = zext i31 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_usub_31_0(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i31
  %b = trunc i64 %input_b to i31
  %pair = call { i31, i1 } @llvm.usub.with.overflow.i31(i31 %a, i31 %b)
  %flag = extractvalue { i31, i1 } %pair, 1
  %value = extractvalue { i31, i1 } %pair, 0
  %wide = zext i31 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_usub_31_1(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i31
  %b = trunc i64 %input_b to i31
  %pair = call { i31, i1 } @llvm.usub.with.overflow.i31(i31 -1, i31 %b)
  %flag = extractvalue { i31, i1 } %pair, 1
  %value = extractvalue { i31, i1 } %pair, 0
  %wide = zext i31 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_usub_31_2(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i31
  %b = trunc i64 %input_b to i31
  %pair = call { i31, i1 } @llvm.usub.with.overflow.i31(i31 %a, i31 -1)
  %flag = extractvalue { i31, i1 } %pair, 1
  %value = extractvalue { i31, i1 } %pair, 0
  %wide = zext i31 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_umul_31_0(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i31
  %b = trunc i64 %input_b to i31
  %pair = call { i31, i1 } @llvm.umul.with.overflow.i31(i31 %a, i31 %b)
  %flag = extractvalue { i31, i1 } %pair, 1
  %value = extractvalue { i31, i1 } %pair, 0
  %wide = zext i31 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_umul_31_1(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i31
  %b = trunc i64 %input_b to i31
  %pair = call { i31, i1 } @llvm.umul.with.overflow.i31(i31 -1, i31 %b)
  %flag = extractvalue { i31, i1 } %pair, 1
  %value = extractvalue { i31, i1 } %pair, 0
  %wide = zext i31 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_umul_31_2(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i31
  %b = trunc i64 %input_b to i31
  %pair = call { i31, i1 } @llvm.umul.with.overflow.i31(i31 %a, i31 -1)
  %flag = extractvalue { i31, i1 } %pair, 1
  %value = extractvalue { i31, i1 } %pair, 0
  %wide = zext i31 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_sadd_31_0(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i31
  %b = trunc i64 %input_b to i31
  %pair = call { i31, i1 } @llvm.sadd.with.overflow.i31(i31 %a, i31 %b)
  %flag = extractvalue { i31, i1 } %pair, 1
  %value = extractvalue { i31, i1 } %pair, 0
  %wide = zext i31 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_sadd_31_1(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i31
  %b = trunc i64 %input_b to i31
  %pair = call { i31, i1 } @llvm.sadd.with.overflow.i31(i31 -1, i31 %b)
  %flag = extractvalue { i31, i1 } %pair, 1
  %value = extractvalue { i31, i1 } %pair, 0
  %wide = zext i31 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_sadd_31_2(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i31
  %b = trunc i64 %input_b to i31
  %pair = call { i31, i1 } @llvm.sadd.with.overflow.i31(i31 %a, i31 -1)
  %flag = extractvalue { i31, i1 } %pair, 1
  %value = extractvalue { i31, i1 } %pair, 0
  %wide = zext i31 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_ssub_31_0(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i31
  %b = trunc i64 %input_b to i31
  %pair = call { i31, i1 } @llvm.ssub.with.overflow.i31(i31 %a, i31 %b)
  %flag = extractvalue { i31, i1 } %pair, 1
  %value = extractvalue { i31, i1 } %pair, 0
  %wide = zext i31 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_ssub_31_1(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i31
  %b = trunc i64 %input_b to i31
  %pair = call { i31, i1 } @llvm.ssub.with.overflow.i31(i31 -1, i31 %b)
  %flag = extractvalue { i31, i1 } %pair, 1
  %value = extractvalue { i31, i1 } %pair, 0
  %wide = zext i31 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_ssub_31_2(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i31
  %b = trunc i64 %input_b to i31
  %pair = call { i31, i1 } @llvm.ssub.with.overflow.i31(i31 %a, i31 -1)
  %flag = extractvalue { i31, i1 } %pair, 1
  %value = extractvalue { i31, i1 } %pair, 0
  %wide = zext i31 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_smul_31_0(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i31
  %b = trunc i64 %input_b to i31
  %pair = call { i31, i1 } @llvm.smul.with.overflow.i31(i31 %a, i31 %b)
  %flag = extractvalue { i31, i1 } %pair, 1
  %value = extractvalue { i31, i1 } %pair, 0
  %wide = zext i31 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_smul_31_1(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i31
  %b = trunc i64 %input_b to i31
  %pair = call { i31, i1 } @llvm.smul.with.overflow.i31(i31 -1, i31 %b)
  %flag = extractvalue { i31, i1 } %pair, 1
  %value = extractvalue { i31, i1 } %pair, 0
  %wide = zext i31 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_smul_31_2(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i31
  %b = trunc i64 %input_b to i31
  %pair = call { i31, i1 } @llvm.smul.with.overflow.i31(i31 %a, i31 -1)
  %flag = extractvalue { i31, i1 } %pair, 1
  %value = extractvalue { i31, i1 } %pair, 0
  %wide = zext i31 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_uadd_32_0(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %pair = call { i32, i1 } @llvm.uadd.with.overflow.i32(i32 %a, i32 %b)
  %flag = extractvalue { i32, i1 } %pair, 1
  %value = extractvalue { i32, i1 } %pair, 0
  %wide = zext i32 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_uadd_32_1(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %pair = call { i32, i1 } @llvm.uadd.with.overflow.i32(i32 -1, i32 %b)
  %flag = extractvalue { i32, i1 } %pair, 1
  %value = extractvalue { i32, i1 } %pair, 0
  %wide = zext i32 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_uadd_32_2(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %pair = call { i32, i1 } @llvm.uadd.with.overflow.i32(i32 %a, i32 -1)
  %flag = extractvalue { i32, i1 } %pair, 1
  %value = extractvalue { i32, i1 } %pair, 0
  %wide = zext i32 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_usub_32_0(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %pair = call { i32, i1 } @llvm.usub.with.overflow.i32(i32 %a, i32 %b)
  %flag = extractvalue { i32, i1 } %pair, 1
  %value = extractvalue { i32, i1 } %pair, 0
  %wide = zext i32 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_usub_32_1(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %pair = call { i32, i1 } @llvm.usub.with.overflow.i32(i32 -1, i32 %b)
  %flag = extractvalue { i32, i1 } %pair, 1
  %value = extractvalue { i32, i1 } %pair, 0
  %wide = zext i32 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_usub_32_2(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %pair = call { i32, i1 } @llvm.usub.with.overflow.i32(i32 %a, i32 -1)
  %flag = extractvalue { i32, i1 } %pair, 1
  %value = extractvalue { i32, i1 } %pair, 0
  %wide = zext i32 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_umul_32_0(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %pair = call { i32, i1 } @llvm.umul.with.overflow.i32(i32 %a, i32 %b)
  %flag = extractvalue { i32, i1 } %pair, 1
  %value = extractvalue { i32, i1 } %pair, 0
  %wide = zext i32 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_umul_32_1(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %pair = call { i32, i1 } @llvm.umul.with.overflow.i32(i32 -1, i32 %b)
  %flag = extractvalue { i32, i1 } %pair, 1
  %value = extractvalue { i32, i1 } %pair, 0
  %wide = zext i32 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_umul_32_2(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %pair = call { i32, i1 } @llvm.umul.with.overflow.i32(i32 %a, i32 -1)
  %flag = extractvalue { i32, i1 } %pair, 1
  %value = extractvalue { i32, i1 } %pair, 0
  %wide = zext i32 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_sadd_32_0(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %pair = call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %a, i32 %b)
  %flag = extractvalue { i32, i1 } %pair, 1
  %value = extractvalue { i32, i1 } %pair, 0
  %wide = zext i32 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_sadd_32_1(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %pair = call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 -1, i32 %b)
  %flag = extractvalue { i32, i1 } %pair, 1
  %value = extractvalue { i32, i1 } %pair, 0
  %wide = zext i32 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_sadd_32_2(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %pair = call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 %a, i32 -1)
  %flag = extractvalue { i32, i1 } %pair, 1
  %value = extractvalue { i32, i1 } %pair, 0
  %wide = zext i32 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_ssub_32_0(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %pair = call { i32, i1 } @llvm.ssub.with.overflow.i32(i32 %a, i32 %b)
  %flag = extractvalue { i32, i1 } %pair, 1
  %value = extractvalue { i32, i1 } %pair, 0
  %wide = zext i32 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_ssub_32_1(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %pair = call { i32, i1 } @llvm.ssub.with.overflow.i32(i32 -1, i32 %b)
  %flag = extractvalue { i32, i1 } %pair, 1
  %value = extractvalue { i32, i1 } %pair, 0
  %wide = zext i32 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_ssub_32_2(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %pair = call { i32, i1 } @llvm.ssub.with.overflow.i32(i32 %a, i32 -1)
  %flag = extractvalue { i32, i1 } %pair, 1
  %value = extractvalue { i32, i1 } %pair, 0
  %wide = zext i32 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_smul_32_0(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %pair = call { i32, i1 } @llvm.smul.with.overflow.i32(i32 %a, i32 %b)
  %flag = extractvalue { i32, i1 } %pair, 1
  %value = extractvalue { i32, i1 } %pair, 0
  %wide = zext i32 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_smul_32_1(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %pair = call { i32, i1 } @llvm.smul.with.overflow.i32(i32 -1, i32 %b)
  %flag = extractvalue { i32, i1 } %pair, 1
  %value = extractvalue { i32, i1 } %pair, 0
  %wide = zext i32 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_smul_32_2(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %pair = call { i32, i1 } @llvm.smul.with.overflow.i32(i32 %a, i32 -1)
  %flag = extractvalue { i32, i1 } %pair, 1
  %value = extractvalue { i32, i1 } %pair, 0
  %wide = zext i32 %value to i64
  store i64 %wide, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_uadd_64_0(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %pair = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 %input_a, i64 %input_b)
  %flag = extractvalue { i64, i1 } %pair, 1
  %value = extractvalue { i64, i1 } %pair, 0
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_uadd_64_1(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %pair = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 -1, i64 %input_b)
  %flag = extractvalue { i64, i1 } %pair, 1
  %value = extractvalue { i64, i1 } %pair, 0
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_uadd_64_2(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %pair = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 %input_a, i64 -1)
  %flag = extractvalue { i64, i1 } %pair, 1
  %value = extractvalue { i64, i1 } %pair, 0
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_usub_64_0(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %pair = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %input_a, i64 %input_b)
  %flag = extractvalue { i64, i1 } %pair, 1
  %value = extractvalue { i64, i1 } %pair, 0
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_usub_64_1(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %pair = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 -1, i64 %input_b)
  %flag = extractvalue { i64, i1 } %pair, 1
  %value = extractvalue { i64, i1 } %pair, 0
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_usub_64_2(i64 %input_a, i64 %input_b, ptr %out) {
entry:
  %pair = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %input_a, i64 -1)
  %flag = extractvalue { i64, i1 } %pair, 1
  %value = extractvalue { i64, i1 } %pair, 0
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %input_a, %input_b
  store i64 %live, ptr %next, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @checked_roundtrip(i64 %a, i64 %b, ptr %out) {
entry:
  %full = add i64 %a, 7
  %low = trunc i64 %full to i32
  %result = zext i32 %low to i64
  store i64 %full, ptr %out, align 8
  ret i64 %result
}


define i1 @checked_forward(ptr %p) {
entry:
  %r = call i1 @checked_boolean_ptr(ptr %p)
  ret i1 %r
}


define i64 @checked_bool_pointer(i64 %a, i64 %b, ptr %out) {
entry:
  store i64 %a, ptr %out, align 8
  %flag = call i1 @checked_boolean_ptr(ptr %out)
  %wide = zext i1 %flag to i64
  store i64 %wide, ptr %out, align 8
  %live = xor i64 %a, %b
  ret i64 %live
}


define i64 @checked_bool_derived(i64 %a, i64 %b, ptr %out) {
entry:
  store i64 %a, ptr %out, align 8
  %pointer = getelementptr i8, ptr %out, i64 8
  store i64 %a, ptr %pointer, align 8
  %flag = call i1 @checked_boolean_ptr(ptr %pointer)
  %wide = zext i1 %flag to i64
  store i64 %wide, ptr %out, align 8
  %live = xor i64 %a, %b
  ret i64 %live
}


define i64 @checked_bool_forward(i64 %a, i64 %b, ptr %out) {
entry:
  store i64 %a, ptr %out, align 8
  %flag = call i1 @checked_forward(ptr %out)
  %wide = zext i1 %flag to i64
  store i64 %wide, ptr %out, align 8
  %live = xor i64 %a, %b
  ret i64 %live
}


define i64 @checked_bool_branch(i64 %a, i64 %b, ptr %out) {
entry:
  store i64 %a, ptr %out, align 8
  %flag = call i1 @checked_boolean_ptr(ptr %out)
  br i1 %flag, label %yes, label %no
yes:
  store i64 1, ptr %out, align 8
  br label %done
no:
  store i64 0, ptr %out, align 8
  br label %done
done:
  %live = xor i64 %a, %b
  ret i64 %live
}


define i64 @checked_bool_six(i64 %a, i64 %b, ptr %out) {
entry:
  store i64 %a, ptr %out, align 8
  %flag = call i1 @checked_boolean_six(i64 %b, i64 %a, i64 19, i64 %a, i64 37, i64 %b)
  %wide = zext i1 %flag to i64
  store i64 %wide, ptr %out, align 8
  %live = xor i64 %a, %b
  ret i64 %live
}


define i64 @checked_bool_eight(i64 %a, i64 %b, ptr %out) {
entry:
  store i64 %a, ptr %out, align 8
  %flag = call i1 @checked_boolean_eight(i64 %b, i64 %a, i64 19, i64 %a, i64 37, i64 %b, i64 %a, i64 73)
  %wide = zext i1 %flag to i64
  store i64 %wide, ptr %out, align 8
  %live = xor i64 %a, %b
  ret i64 %live
}

