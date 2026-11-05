target triple = "x86_64-unknown-linux-gnu"

declare i1 @llvm.uadd.sat.i1(i1, i1)

declare i1 @llvm.usub.sat.i1(i1, i1)

declare i1 @llvm.umin.i1(i1, i1)

declare i1 @llvm.umax.i1(i1, i1)

declare i1 @llvm.smin.i1(i1, i1)

declare i1 @llvm.smax.i1(i1, i1)

declare i1 @llvm.bitreverse.i1(i1)

declare i2 @llvm.uadd.sat.i2(i2, i2)

declare i2 @llvm.usub.sat.i2(i2, i2)

declare i2 @llvm.umin.i2(i2, i2)

declare i2 @llvm.umax.i2(i2, i2)

declare i2 @llvm.smin.i2(i2, i2)

declare i2 @llvm.smax.i2(i2, i2)

declare i2 @llvm.bitreverse.i2(i2)

declare i7 @llvm.uadd.sat.i7(i7, i7)

declare i7 @llvm.usub.sat.i7(i7, i7)

declare i7 @llvm.umin.i7(i7, i7)

declare i7 @llvm.umax.i7(i7, i7)

declare i7 @llvm.smin.i7(i7, i7)

declare i7 @llvm.smax.i7(i7, i7)

declare i7 @llvm.bitreverse.i7(i7)

declare i8 @llvm.uadd.sat.i8(i8, i8)

declare i8 @llvm.usub.sat.i8(i8, i8)

declare i8 @llvm.umin.i8(i8, i8)

declare i8 @llvm.umax.i8(i8, i8)

declare i8 @llvm.smin.i8(i8, i8)

declare i8 @llvm.smax.i8(i8, i8)

declare i8 @llvm.bitreverse.i8(i8)

declare i9 @llvm.uadd.sat.i9(i9, i9)

declare i9 @llvm.usub.sat.i9(i9, i9)

declare i9 @llvm.umin.i9(i9, i9)

declare i9 @llvm.umax.i9(i9, i9)

declare i9 @llvm.smin.i9(i9, i9)

declare i9 @llvm.smax.i9(i9, i9)

declare i9 @llvm.bitreverse.i9(i9)

declare i15 @llvm.uadd.sat.i15(i15, i15)

declare i15 @llvm.usub.sat.i15(i15, i15)

declare i15 @llvm.umin.i15(i15, i15)

declare i15 @llvm.umax.i15(i15, i15)

declare i15 @llvm.smin.i15(i15, i15)

declare i15 @llvm.smax.i15(i15, i15)

declare i15 @llvm.bitreverse.i15(i15)

declare i16 @llvm.uadd.sat.i16(i16, i16)

declare i16 @llvm.usub.sat.i16(i16, i16)

declare i16 @llvm.umin.i16(i16, i16)

declare i16 @llvm.umax.i16(i16, i16)

declare i16 @llvm.smin.i16(i16, i16)

declare i16 @llvm.smax.i16(i16, i16)

declare i16 @llvm.bitreverse.i16(i16)

declare i31 @llvm.uadd.sat.i31(i31, i31)

declare i31 @llvm.usub.sat.i31(i31, i31)

declare i31 @llvm.umin.i31(i31, i31)

declare i31 @llvm.umax.i31(i31, i31)

declare i31 @llvm.smin.i31(i31, i31)

declare i31 @llvm.smax.i31(i31, i31)

declare i31 @llvm.bitreverse.i31(i31)

declare i32 @llvm.uadd.sat.i32(i32, i32)

declare i32 @llvm.usub.sat.i32(i32, i32)

declare i32 @llvm.umin.i32(i32, i32)

declare i32 @llvm.umax.i32(i32, i32)

declare i32 @llvm.smin.i32(i32, i32)

declare i32 @llvm.smax.i32(i32, i32)

declare i32 @llvm.bitreverse.i32(i32)

declare i33 @llvm.umin.i33(i33, i33)

declare i33 @llvm.umax.i33(i33, i33)

declare i33 @llvm.smin.i33(i33, i33)

declare i33 @llvm.smax.i33(i33, i33)

declare i33 @llvm.bitreverse.i33(i33)

declare i63 @llvm.umin.i63(i63, i63)

declare i63 @llvm.umax.i63(i63, i63)

declare i63 @llvm.smin.i63(i63, i63)

declare i63 @llvm.smax.i63(i63, i63)

declare i63 @llvm.bitreverse.i63(i63)

declare i64 @llvm.uadd.sat.i64(i64, i64)

declare i64 @llvm.usub.sat.i64(i64, i64)

declare i64 @llvm.umin.i64(i64, i64)

declare i64 @llvm.umax.i64(i64, i64)

declare i64 @llvm.smin.i64(i64, i64)

declare i64 @llvm.smax.i64(i64, i64)

declare i64 @llvm.bitreverse.i64(i64)

define i64 @intrinsic_uadd_sat1_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i1
  %b = trunc i64 %input_b to i1
  %result = call i1 @llvm.uadd.sat.i1(i1 %a, i1 %b)
  %value = zext i1 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_uadd_sat1_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i1
  %b = trunc i64 %input_b to i1
  %result = call i1 @llvm.uadd.sat.i1(i1 -1, i1 %b)
  %value = zext i1 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_uadd_sat1_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i1
  %b = trunc i64 %input_b to i1
  %result = call i1 @llvm.uadd.sat.i1(i1 %a, i1 -1)
  %value = zext i1 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_usub_sat1_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i1
  %b = trunc i64 %input_b to i1
  %result = call i1 @llvm.usub.sat.i1(i1 %a, i1 %b)
  %value = zext i1 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_usub_sat1_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i1
  %b = trunc i64 %input_b to i1
  %result = call i1 @llvm.usub.sat.i1(i1 -1, i1 %b)
  %value = zext i1 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_usub_sat1_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i1
  %b = trunc i64 %input_b to i1
  %result = call i1 @llvm.usub.sat.i1(i1 %a, i1 -1)
  %value = zext i1 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umin1_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i1
  %b = trunc i64 %input_b to i1
  %result = call i1 @llvm.umin.i1(i1 %a, i1 %b)
  %value = zext i1 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umin1_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i1
  %b = trunc i64 %input_b to i1
  %result = call i1 @llvm.umin.i1(i1 -1, i1 %b)
  %value = zext i1 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umin1_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i1
  %b = trunc i64 %input_b to i1
  %result = call i1 @llvm.umin.i1(i1 %a, i1 -1)
  %value = zext i1 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umax1_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i1
  %b = trunc i64 %input_b to i1
  %result = call i1 @llvm.umax.i1(i1 %a, i1 %b)
  %value = zext i1 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umax1_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i1
  %b = trunc i64 %input_b to i1
  %result = call i1 @llvm.umax.i1(i1 -1, i1 %b)
  %value = zext i1 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umax1_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i1
  %b = trunc i64 %input_b to i1
  %result = call i1 @llvm.umax.i1(i1 %a, i1 -1)
  %value = zext i1 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smin1_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i1
  %b = trunc i64 %input_b to i1
  %result = call i1 @llvm.smin.i1(i1 %a, i1 %b)
  %value = zext i1 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smin1_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i1
  %b = trunc i64 %input_b to i1
  %result = call i1 @llvm.smin.i1(i1 -1, i1 %b)
  %value = zext i1 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smin1_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i1
  %b = trunc i64 %input_b to i1
  %result = call i1 @llvm.smin.i1(i1 %a, i1 -1)
  %value = zext i1 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smax1_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i1
  %b = trunc i64 %input_b to i1
  %result = call i1 @llvm.smax.i1(i1 %a, i1 %b)
  %value = zext i1 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smax1_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i1
  %b = trunc i64 %input_b to i1
  %result = call i1 @llvm.smax.i1(i1 -1, i1 %b)
  %value = zext i1 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smax1_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i1
  %b = trunc i64 %input_b to i1
  %result = call i1 @llvm.smax.i1(i1 %a, i1 -1)
  %value = zext i1 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_bitreverse1_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i1
  %b = trunc i64 %input_b to i1
  %result = call i1 @llvm.bitreverse.i1(i1 %a)
  %value = zext i1 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_bitreverse1_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i1
  %b = trunc i64 %input_b to i1
  %result = call i1 @llvm.bitreverse.i1(i1 -1)
  %value = zext i1 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_uadd_sat2_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i2
  %b = trunc i64 %input_b to i2
  %result = call i2 @llvm.uadd.sat.i2(i2 %a, i2 %b)
  %value = zext i2 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_uadd_sat2_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i2
  %b = trunc i64 %input_b to i2
  %result = call i2 @llvm.uadd.sat.i2(i2 -1, i2 %b)
  %value = zext i2 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_uadd_sat2_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i2
  %b = trunc i64 %input_b to i2
  %result = call i2 @llvm.uadd.sat.i2(i2 %a, i2 -1)
  %value = zext i2 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_usub_sat2_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i2
  %b = trunc i64 %input_b to i2
  %result = call i2 @llvm.usub.sat.i2(i2 %a, i2 %b)
  %value = zext i2 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_usub_sat2_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i2
  %b = trunc i64 %input_b to i2
  %result = call i2 @llvm.usub.sat.i2(i2 -1, i2 %b)
  %value = zext i2 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_usub_sat2_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i2
  %b = trunc i64 %input_b to i2
  %result = call i2 @llvm.usub.sat.i2(i2 %a, i2 -1)
  %value = zext i2 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umin2_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i2
  %b = trunc i64 %input_b to i2
  %result = call i2 @llvm.umin.i2(i2 %a, i2 %b)
  %value = zext i2 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umin2_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i2
  %b = trunc i64 %input_b to i2
  %result = call i2 @llvm.umin.i2(i2 -1, i2 %b)
  %value = zext i2 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umin2_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i2
  %b = trunc i64 %input_b to i2
  %result = call i2 @llvm.umin.i2(i2 %a, i2 -1)
  %value = zext i2 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umax2_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i2
  %b = trunc i64 %input_b to i2
  %result = call i2 @llvm.umax.i2(i2 %a, i2 %b)
  %value = zext i2 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umax2_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i2
  %b = trunc i64 %input_b to i2
  %result = call i2 @llvm.umax.i2(i2 -1, i2 %b)
  %value = zext i2 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umax2_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i2
  %b = trunc i64 %input_b to i2
  %result = call i2 @llvm.umax.i2(i2 %a, i2 -1)
  %value = zext i2 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smin2_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i2
  %b = trunc i64 %input_b to i2
  %result = call i2 @llvm.smin.i2(i2 %a, i2 %b)
  %value = zext i2 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smin2_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i2
  %b = trunc i64 %input_b to i2
  %result = call i2 @llvm.smin.i2(i2 -1, i2 %b)
  %value = zext i2 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smin2_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i2
  %b = trunc i64 %input_b to i2
  %result = call i2 @llvm.smin.i2(i2 %a, i2 -1)
  %value = zext i2 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smax2_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i2
  %b = trunc i64 %input_b to i2
  %result = call i2 @llvm.smax.i2(i2 %a, i2 %b)
  %value = zext i2 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smax2_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i2
  %b = trunc i64 %input_b to i2
  %result = call i2 @llvm.smax.i2(i2 -1, i2 %b)
  %value = zext i2 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smax2_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i2
  %b = trunc i64 %input_b to i2
  %result = call i2 @llvm.smax.i2(i2 %a, i2 -1)
  %value = zext i2 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_bitreverse2_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i2
  %b = trunc i64 %input_b to i2
  %result = call i2 @llvm.bitreverse.i2(i2 %a)
  %value = zext i2 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_bitreverse2_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i2
  %b = trunc i64 %input_b to i2
  %result = call i2 @llvm.bitreverse.i2(i2 -1)
  %value = zext i2 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_uadd_sat7_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i7
  %b = trunc i64 %input_b to i7
  %result = call i7 @llvm.uadd.sat.i7(i7 %a, i7 %b)
  %value = zext i7 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_uadd_sat7_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i7
  %b = trunc i64 %input_b to i7
  %result = call i7 @llvm.uadd.sat.i7(i7 -1, i7 %b)
  %value = zext i7 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_uadd_sat7_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i7
  %b = trunc i64 %input_b to i7
  %result = call i7 @llvm.uadd.sat.i7(i7 %a, i7 -1)
  %value = zext i7 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_usub_sat7_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i7
  %b = trunc i64 %input_b to i7
  %result = call i7 @llvm.usub.sat.i7(i7 %a, i7 %b)
  %value = zext i7 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_usub_sat7_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i7
  %b = trunc i64 %input_b to i7
  %result = call i7 @llvm.usub.sat.i7(i7 -1, i7 %b)
  %value = zext i7 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_usub_sat7_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i7
  %b = trunc i64 %input_b to i7
  %result = call i7 @llvm.usub.sat.i7(i7 %a, i7 -1)
  %value = zext i7 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umin7_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i7
  %b = trunc i64 %input_b to i7
  %result = call i7 @llvm.umin.i7(i7 %a, i7 %b)
  %value = zext i7 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umin7_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i7
  %b = trunc i64 %input_b to i7
  %result = call i7 @llvm.umin.i7(i7 -1, i7 %b)
  %value = zext i7 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umin7_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i7
  %b = trunc i64 %input_b to i7
  %result = call i7 @llvm.umin.i7(i7 %a, i7 -1)
  %value = zext i7 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umax7_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i7
  %b = trunc i64 %input_b to i7
  %result = call i7 @llvm.umax.i7(i7 %a, i7 %b)
  %value = zext i7 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umax7_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i7
  %b = trunc i64 %input_b to i7
  %result = call i7 @llvm.umax.i7(i7 -1, i7 %b)
  %value = zext i7 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umax7_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i7
  %b = trunc i64 %input_b to i7
  %result = call i7 @llvm.umax.i7(i7 %a, i7 -1)
  %value = zext i7 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smin7_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i7
  %b = trunc i64 %input_b to i7
  %result = call i7 @llvm.smin.i7(i7 %a, i7 %b)
  %value = zext i7 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smin7_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i7
  %b = trunc i64 %input_b to i7
  %result = call i7 @llvm.smin.i7(i7 -1, i7 %b)
  %value = zext i7 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smin7_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i7
  %b = trunc i64 %input_b to i7
  %result = call i7 @llvm.smin.i7(i7 %a, i7 -1)
  %value = zext i7 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smax7_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i7
  %b = trunc i64 %input_b to i7
  %result = call i7 @llvm.smax.i7(i7 %a, i7 %b)
  %value = zext i7 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smax7_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i7
  %b = trunc i64 %input_b to i7
  %result = call i7 @llvm.smax.i7(i7 -1, i7 %b)
  %value = zext i7 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smax7_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i7
  %b = trunc i64 %input_b to i7
  %result = call i7 @llvm.smax.i7(i7 %a, i7 -1)
  %value = zext i7 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_bitreverse7_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i7
  %b = trunc i64 %input_b to i7
  %result = call i7 @llvm.bitreverse.i7(i7 %a)
  %value = zext i7 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_bitreverse7_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i7
  %b = trunc i64 %input_b to i7
  %result = call i7 @llvm.bitreverse.i7(i7 -1)
  %value = zext i7 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_uadd_sat8_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i8
  %b = trunc i64 %input_b to i8
  %result = call i8 @llvm.uadd.sat.i8(i8 %a, i8 %b)
  %value = zext i8 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_uadd_sat8_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i8
  %b = trunc i64 %input_b to i8
  %result = call i8 @llvm.uadd.sat.i8(i8 -1, i8 %b)
  %value = zext i8 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_uadd_sat8_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i8
  %b = trunc i64 %input_b to i8
  %result = call i8 @llvm.uadd.sat.i8(i8 %a, i8 -1)
  %value = zext i8 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_usub_sat8_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i8
  %b = trunc i64 %input_b to i8
  %result = call i8 @llvm.usub.sat.i8(i8 %a, i8 %b)
  %value = zext i8 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_usub_sat8_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i8
  %b = trunc i64 %input_b to i8
  %result = call i8 @llvm.usub.sat.i8(i8 -1, i8 %b)
  %value = zext i8 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_usub_sat8_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i8
  %b = trunc i64 %input_b to i8
  %result = call i8 @llvm.usub.sat.i8(i8 %a, i8 -1)
  %value = zext i8 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umin8_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i8
  %b = trunc i64 %input_b to i8
  %result = call i8 @llvm.umin.i8(i8 %a, i8 %b)
  %value = zext i8 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umin8_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i8
  %b = trunc i64 %input_b to i8
  %result = call i8 @llvm.umin.i8(i8 -1, i8 %b)
  %value = zext i8 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umin8_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i8
  %b = trunc i64 %input_b to i8
  %result = call i8 @llvm.umin.i8(i8 %a, i8 -1)
  %value = zext i8 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umax8_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i8
  %b = trunc i64 %input_b to i8
  %result = call i8 @llvm.umax.i8(i8 %a, i8 %b)
  %value = zext i8 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umax8_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i8
  %b = trunc i64 %input_b to i8
  %result = call i8 @llvm.umax.i8(i8 -1, i8 %b)
  %value = zext i8 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umax8_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i8
  %b = trunc i64 %input_b to i8
  %result = call i8 @llvm.umax.i8(i8 %a, i8 -1)
  %value = zext i8 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smin8_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i8
  %b = trunc i64 %input_b to i8
  %result = call i8 @llvm.smin.i8(i8 %a, i8 %b)
  %value = zext i8 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smin8_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i8
  %b = trunc i64 %input_b to i8
  %result = call i8 @llvm.smin.i8(i8 -1, i8 %b)
  %value = zext i8 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smin8_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i8
  %b = trunc i64 %input_b to i8
  %result = call i8 @llvm.smin.i8(i8 %a, i8 -1)
  %value = zext i8 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smax8_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i8
  %b = trunc i64 %input_b to i8
  %result = call i8 @llvm.smax.i8(i8 %a, i8 %b)
  %value = zext i8 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smax8_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i8
  %b = trunc i64 %input_b to i8
  %result = call i8 @llvm.smax.i8(i8 -1, i8 %b)
  %value = zext i8 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smax8_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i8
  %b = trunc i64 %input_b to i8
  %result = call i8 @llvm.smax.i8(i8 %a, i8 -1)
  %value = zext i8 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_bitreverse8_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i8
  %b = trunc i64 %input_b to i8
  %result = call i8 @llvm.bitreverse.i8(i8 %a)
  %value = zext i8 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_bitreverse8_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i8
  %b = trunc i64 %input_b to i8
  %result = call i8 @llvm.bitreverse.i8(i8 -1)
  %value = zext i8 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_uadd_sat9_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i9
  %b = trunc i64 %input_b to i9
  %result = call i9 @llvm.uadd.sat.i9(i9 %a, i9 %b)
  %value = zext i9 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_uadd_sat9_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i9
  %b = trunc i64 %input_b to i9
  %result = call i9 @llvm.uadd.sat.i9(i9 -1, i9 %b)
  %value = zext i9 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_uadd_sat9_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i9
  %b = trunc i64 %input_b to i9
  %result = call i9 @llvm.uadd.sat.i9(i9 %a, i9 -1)
  %value = zext i9 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_usub_sat9_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i9
  %b = trunc i64 %input_b to i9
  %result = call i9 @llvm.usub.sat.i9(i9 %a, i9 %b)
  %value = zext i9 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_usub_sat9_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i9
  %b = trunc i64 %input_b to i9
  %result = call i9 @llvm.usub.sat.i9(i9 -1, i9 %b)
  %value = zext i9 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_usub_sat9_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i9
  %b = trunc i64 %input_b to i9
  %result = call i9 @llvm.usub.sat.i9(i9 %a, i9 -1)
  %value = zext i9 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umin9_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i9
  %b = trunc i64 %input_b to i9
  %result = call i9 @llvm.umin.i9(i9 %a, i9 %b)
  %value = zext i9 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umin9_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i9
  %b = trunc i64 %input_b to i9
  %result = call i9 @llvm.umin.i9(i9 -1, i9 %b)
  %value = zext i9 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umin9_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i9
  %b = trunc i64 %input_b to i9
  %result = call i9 @llvm.umin.i9(i9 %a, i9 -1)
  %value = zext i9 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umax9_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i9
  %b = trunc i64 %input_b to i9
  %result = call i9 @llvm.umax.i9(i9 %a, i9 %b)
  %value = zext i9 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umax9_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i9
  %b = trunc i64 %input_b to i9
  %result = call i9 @llvm.umax.i9(i9 -1, i9 %b)
  %value = zext i9 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umax9_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i9
  %b = trunc i64 %input_b to i9
  %result = call i9 @llvm.umax.i9(i9 %a, i9 -1)
  %value = zext i9 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smin9_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i9
  %b = trunc i64 %input_b to i9
  %result = call i9 @llvm.smin.i9(i9 %a, i9 %b)
  %value = zext i9 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smin9_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i9
  %b = trunc i64 %input_b to i9
  %result = call i9 @llvm.smin.i9(i9 -1, i9 %b)
  %value = zext i9 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smin9_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i9
  %b = trunc i64 %input_b to i9
  %result = call i9 @llvm.smin.i9(i9 %a, i9 -1)
  %value = zext i9 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smax9_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i9
  %b = trunc i64 %input_b to i9
  %result = call i9 @llvm.smax.i9(i9 %a, i9 %b)
  %value = zext i9 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smax9_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i9
  %b = trunc i64 %input_b to i9
  %result = call i9 @llvm.smax.i9(i9 -1, i9 %b)
  %value = zext i9 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smax9_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i9
  %b = trunc i64 %input_b to i9
  %result = call i9 @llvm.smax.i9(i9 %a, i9 -1)
  %value = zext i9 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_bitreverse9_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i9
  %b = trunc i64 %input_b to i9
  %result = call i9 @llvm.bitreverse.i9(i9 %a)
  %value = zext i9 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_bitreverse9_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i9
  %b = trunc i64 %input_b to i9
  %result = call i9 @llvm.bitreverse.i9(i9 -1)
  %value = zext i9 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_uadd_sat15_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i15
  %b = trunc i64 %input_b to i15
  %result = call i15 @llvm.uadd.sat.i15(i15 %a, i15 %b)
  %value = zext i15 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_uadd_sat15_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i15
  %b = trunc i64 %input_b to i15
  %result = call i15 @llvm.uadd.sat.i15(i15 -1, i15 %b)
  %value = zext i15 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_uadd_sat15_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i15
  %b = trunc i64 %input_b to i15
  %result = call i15 @llvm.uadd.sat.i15(i15 %a, i15 -1)
  %value = zext i15 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_usub_sat15_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i15
  %b = trunc i64 %input_b to i15
  %result = call i15 @llvm.usub.sat.i15(i15 %a, i15 %b)
  %value = zext i15 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_usub_sat15_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i15
  %b = trunc i64 %input_b to i15
  %result = call i15 @llvm.usub.sat.i15(i15 -1, i15 %b)
  %value = zext i15 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_usub_sat15_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i15
  %b = trunc i64 %input_b to i15
  %result = call i15 @llvm.usub.sat.i15(i15 %a, i15 -1)
  %value = zext i15 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umin15_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i15
  %b = trunc i64 %input_b to i15
  %result = call i15 @llvm.umin.i15(i15 %a, i15 %b)
  %value = zext i15 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umin15_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i15
  %b = trunc i64 %input_b to i15
  %result = call i15 @llvm.umin.i15(i15 -1, i15 %b)
  %value = zext i15 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umin15_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i15
  %b = trunc i64 %input_b to i15
  %result = call i15 @llvm.umin.i15(i15 %a, i15 -1)
  %value = zext i15 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umax15_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i15
  %b = trunc i64 %input_b to i15
  %result = call i15 @llvm.umax.i15(i15 %a, i15 %b)
  %value = zext i15 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umax15_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i15
  %b = trunc i64 %input_b to i15
  %result = call i15 @llvm.umax.i15(i15 -1, i15 %b)
  %value = zext i15 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umax15_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i15
  %b = trunc i64 %input_b to i15
  %result = call i15 @llvm.umax.i15(i15 %a, i15 -1)
  %value = zext i15 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smin15_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i15
  %b = trunc i64 %input_b to i15
  %result = call i15 @llvm.smin.i15(i15 %a, i15 %b)
  %value = zext i15 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smin15_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i15
  %b = trunc i64 %input_b to i15
  %result = call i15 @llvm.smin.i15(i15 -1, i15 %b)
  %value = zext i15 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smin15_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i15
  %b = trunc i64 %input_b to i15
  %result = call i15 @llvm.smin.i15(i15 %a, i15 -1)
  %value = zext i15 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smax15_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i15
  %b = trunc i64 %input_b to i15
  %result = call i15 @llvm.smax.i15(i15 %a, i15 %b)
  %value = zext i15 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smax15_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i15
  %b = trunc i64 %input_b to i15
  %result = call i15 @llvm.smax.i15(i15 -1, i15 %b)
  %value = zext i15 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smax15_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i15
  %b = trunc i64 %input_b to i15
  %result = call i15 @llvm.smax.i15(i15 %a, i15 -1)
  %value = zext i15 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_bitreverse15_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i15
  %b = trunc i64 %input_b to i15
  %result = call i15 @llvm.bitreverse.i15(i15 %a)
  %value = zext i15 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_bitreverse15_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i15
  %b = trunc i64 %input_b to i15
  %result = call i15 @llvm.bitreverse.i15(i15 -1)
  %value = zext i15 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_uadd_sat16_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i16
  %b = trunc i64 %input_b to i16
  %result = call i16 @llvm.uadd.sat.i16(i16 %a, i16 %b)
  %value = zext i16 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_uadd_sat16_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i16
  %b = trunc i64 %input_b to i16
  %result = call i16 @llvm.uadd.sat.i16(i16 -1, i16 %b)
  %value = zext i16 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_uadd_sat16_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i16
  %b = trunc i64 %input_b to i16
  %result = call i16 @llvm.uadd.sat.i16(i16 %a, i16 -1)
  %value = zext i16 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_usub_sat16_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i16
  %b = trunc i64 %input_b to i16
  %result = call i16 @llvm.usub.sat.i16(i16 %a, i16 %b)
  %value = zext i16 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_usub_sat16_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i16
  %b = trunc i64 %input_b to i16
  %result = call i16 @llvm.usub.sat.i16(i16 -1, i16 %b)
  %value = zext i16 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_usub_sat16_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i16
  %b = trunc i64 %input_b to i16
  %result = call i16 @llvm.usub.sat.i16(i16 %a, i16 -1)
  %value = zext i16 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umin16_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i16
  %b = trunc i64 %input_b to i16
  %result = call i16 @llvm.umin.i16(i16 %a, i16 %b)
  %value = zext i16 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umin16_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i16
  %b = trunc i64 %input_b to i16
  %result = call i16 @llvm.umin.i16(i16 -1, i16 %b)
  %value = zext i16 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umin16_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i16
  %b = trunc i64 %input_b to i16
  %result = call i16 @llvm.umin.i16(i16 %a, i16 -1)
  %value = zext i16 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umax16_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i16
  %b = trunc i64 %input_b to i16
  %result = call i16 @llvm.umax.i16(i16 %a, i16 %b)
  %value = zext i16 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umax16_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i16
  %b = trunc i64 %input_b to i16
  %result = call i16 @llvm.umax.i16(i16 -1, i16 %b)
  %value = zext i16 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umax16_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i16
  %b = trunc i64 %input_b to i16
  %result = call i16 @llvm.umax.i16(i16 %a, i16 -1)
  %value = zext i16 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smin16_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i16
  %b = trunc i64 %input_b to i16
  %result = call i16 @llvm.smin.i16(i16 %a, i16 %b)
  %value = zext i16 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smin16_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i16
  %b = trunc i64 %input_b to i16
  %result = call i16 @llvm.smin.i16(i16 -1, i16 %b)
  %value = zext i16 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smin16_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i16
  %b = trunc i64 %input_b to i16
  %result = call i16 @llvm.smin.i16(i16 %a, i16 -1)
  %value = zext i16 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smax16_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i16
  %b = trunc i64 %input_b to i16
  %result = call i16 @llvm.smax.i16(i16 %a, i16 %b)
  %value = zext i16 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smax16_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i16
  %b = trunc i64 %input_b to i16
  %result = call i16 @llvm.smax.i16(i16 -1, i16 %b)
  %value = zext i16 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smax16_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i16
  %b = trunc i64 %input_b to i16
  %result = call i16 @llvm.smax.i16(i16 %a, i16 -1)
  %value = zext i16 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_bitreverse16_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i16
  %b = trunc i64 %input_b to i16
  %result = call i16 @llvm.bitreverse.i16(i16 %a)
  %value = zext i16 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_bitreverse16_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i16
  %b = trunc i64 %input_b to i16
  %result = call i16 @llvm.bitreverse.i16(i16 -1)
  %value = zext i16 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_uadd_sat31_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i31
  %b = trunc i64 %input_b to i31
  %result = call i31 @llvm.uadd.sat.i31(i31 %a, i31 %b)
  %value = zext i31 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_uadd_sat31_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i31
  %b = trunc i64 %input_b to i31
  %result = call i31 @llvm.uadd.sat.i31(i31 -1, i31 %b)
  %value = zext i31 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_uadd_sat31_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i31
  %b = trunc i64 %input_b to i31
  %result = call i31 @llvm.uadd.sat.i31(i31 %a, i31 -1)
  %value = zext i31 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_usub_sat31_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i31
  %b = trunc i64 %input_b to i31
  %result = call i31 @llvm.usub.sat.i31(i31 %a, i31 %b)
  %value = zext i31 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_usub_sat31_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i31
  %b = trunc i64 %input_b to i31
  %result = call i31 @llvm.usub.sat.i31(i31 -1, i31 %b)
  %value = zext i31 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_usub_sat31_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i31
  %b = trunc i64 %input_b to i31
  %result = call i31 @llvm.usub.sat.i31(i31 %a, i31 -1)
  %value = zext i31 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umin31_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i31
  %b = trunc i64 %input_b to i31
  %result = call i31 @llvm.umin.i31(i31 %a, i31 %b)
  %value = zext i31 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umin31_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i31
  %b = trunc i64 %input_b to i31
  %result = call i31 @llvm.umin.i31(i31 -1, i31 %b)
  %value = zext i31 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umin31_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i31
  %b = trunc i64 %input_b to i31
  %result = call i31 @llvm.umin.i31(i31 %a, i31 -1)
  %value = zext i31 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umax31_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i31
  %b = trunc i64 %input_b to i31
  %result = call i31 @llvm.umax.i31(i31 %a, i31 %b)
  %value = zext i31 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umax31_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i31
  %b = trunc i64 %input_b to i31
  %result = call i31 @llvm.umax.i31(i31 -1, i31 %b)
  %value = zext i31 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umax31_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i31
  %b = trunc i64 %input_b to i31
  %result = call i31 @llvm.umax.i31(i31 %a, i31 -1)
  %value = zext i31 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smin31_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i31
  %b = trunc i64 %input_b to i31
  %result = call i31 @llvm.smin.i31(i31 %a, i31 %b)
  %value = zext i31 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smin31_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i31
  %b = trunc i64 %input_b to i31
  %result = call i31 @llvm.smin.i31(i31 -1, i31 %b)
  %value = zext i31 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smin31_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i31
  %b = trunc i64 %input_b to i31
  %result = call i31 @llvm.smin.i31(i31 %a, i31 -1)
  %value = zext i31 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smax31_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i31
  %b = trunc i64 %input_b to i31
  %result = call i31 @llvm.smax.i31(i31 %a, i31 %b)
  %value = zext i31 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smax31_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i31
  %b = trunc i64 %input_b to i31
  %result = call i31 @llvm.smax.i31(i31 -1, i31 %b)
  %value = zext i31 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smax31_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i31
  %b = trunc i64 %input_b to i31
  %result = call i31 @llvm.smax.i31(i31 %a, i31 -1)
  %value = zext i31 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_bitreverse31_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i31
  %b = trunc i64 %input_b to i31
  %result = call i31 @llvm.bitreverse.i31(i31 %a)
  %value = zext i31 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_bitreverse31_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i31
  %b = trunc i64 %input_b to i31
  %result = call i31 @llvm.bitreverse.i31(i31 -1)
  %value = zext i31 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_uadd_sat32_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %result = call i32 @llvm.uadd.sat.i32(i32 %a, i32 %b)
  %value = zext i32 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_uadd_sat32_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %result = call i32 @llvm.uadd.sat.i32(i32 -1, i32 %b)
  %value = zext i32 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_uadd_sat32_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %result = call i32 @llvm.uadd.sat.i32(i32 %a, i32 -1)
  %value = zext i32 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_usub_sat32_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %result = call i32 @llvm.usub.sat.i32(i32 %a, i32 %b)
  %value = zext i32 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_usub_sat32_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %result = call i32 @llvm.usub.sat.i32(i32 -1, i32 %b)
  %value = zext i32 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_usub_sat32_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %result = call i32 @llvm.usub.sat.i32(i32 %a, i32 -1)
  %value = zext i32 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umin32_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %result = call i32 @llvm.umin.i32(i32 %a, i32 %b)
  %value = zext i32 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umin32_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %result = call i32 @llvm.umin.i32(i32 -1, i32 %b)
  %value = zext i32 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umin32_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %result = call i32 @llvm.umin.i32(i32 %a, i32 -1)
  %value = zext i32 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umax32_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %result = call i32 @llvm.umax.i32(i32 %a, i32 %b)
  %value = zext i32 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umax32_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %result = call i32 @llvm.umax.i32(i32 -1, i32 %b)
  %value = zext i32 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umax32_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %result = call i32 @llvm.umax.i32(i32 %a, i32 -1)
  %value = zext i32 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smin32_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %result = call i32 @llvm.smin.i32(i32 %a, i32 %b)
  %value = zext i32 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smin32_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %result = call i32 @llvm.smin.i32(i32 -1, i32 %b)
  %value = zext i32 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smin32_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %result = call i32 @llvm.smin.i32(i32 %a, i32 -1)
  %value = zext i32 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smax32_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %result = call i32 @llvm.smax.i32(i32 %a, i32 %b)
  %value = zext i32 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smax32_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %result = call i32 @llvm.smax.i32(i32 -1, i32 %b)
  %value = zext i32 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smax32_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %result = call i32 @llvm.smax.i32(i32 %a, i32 -1)
  %value = zext i32 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_bitreverse32_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %result = call i32 @llvm.bitreverse.i32(i32 %a)
  %value = zext i32 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_bitreverse32_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i32
  %b = trunc i64 %input_b to i32
  %result = call i32 @llvm.bitreverse.i32(i32 -1)
  %value = zext i32 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umin33_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i33
  %b = trunc i64 %input_b to i33
  %result = call i33 @llvm.umin.i33(i33 %a, i33 %b)
  %value = zext i33 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umin33_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i33
  %b = trunc i64 %input_b to i33
  %result = call i33 @llvm.umin.i33(i33 -1, i33 %b)
  %value = zext i33 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umin33_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i33
  %b = trunc i64 %input_b to i33
  %result = call i33 @llvm.umin.i33(i33 %a, i33 -1)
  %value = zext i33 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umax33_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i33
  %b = trunc i64 %input_b to i33
  %result = call i33 @llvm.umax.i33(i33 %a, i33 %b)
  %value = zext i33 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umax33_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i33
  %b = trunc i64 %input_b to i33
  %result = call i33 @llvm.umax.i33(i33 -1, i33 %b)
  %value = zext i33 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umax33_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i33
  %b = trunc i64 %input_b to i33
  %result = call i33 @llvm.umax.i33(i33 %a, i33 -1)
  %value = zext i33 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smin33_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i33
  %b = trunc i64 %input_b to i33
  %result = call i33 @llvm.smin.i33(i33 %a, i33 %b)
  %value = zext i33 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smin33_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i33
  %b = trunc i64 %input_b to i33
  %result = call i33 @llvm.smin.i33(i33 -1, i33 %b)
  %value = zext i33 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smin33_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i33
  %b = trunc i64 %input_b to i33
  %result = call i33 @llvm.smin.i33(i33 %a, i33 -1)
  %value = zext i33 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smax33_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i33
  %b = trunc i64 %input_b to i33
  %result = call i33 @llvm.smax.i33(i33 %a, i33 %b)
  %value = zext i33 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smax33_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i33
  %b = trunc i64 %input_b to i33
  %result = call i33 @llvm.smax.i33(i33 -1, i33 %b)
  %value = zext i33 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smax33_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i33
  %b = trunc i64 %input_b to i33
  %result = call i33 @llvm.smax.i33(i33 %a, i33 -1)
  %value = zext i33 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_bitreverse33_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i33
  %b = trunc i64 %input_b to i33
  %result = call i33 @llvm.bitreverse.i33(i33 %a)
  %value = zext i33 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_bitreverse33_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i33
  %b = trunc i64 %input_b to i33
  %result = call i33 @llvm.bitreverse.i33(i33 -1)
  %value = zext i33 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umin63_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i63
  %b = trunc i64 %input_b to i63
  %result = call i63 @llvm.umin.i63(i63 %a, i63 %b)
  %value = zext i63 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umin63_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i63
  %b = trunc i64 %input_b to i63
  %result = call i63 @llvm.umin.i63(i63 -1, i63 %b)
  %value = zext i63 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umin63_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i63
  %b = trunc i64 %input_b to i63
  %result = call i63 @llvm.umin.i63(i63 %a, i63 -1)
  %value = zext i63 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umax63_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i63
  %b = trunc i64 %input_b to i63
  %result = call i63 @llvm.umax.i63(i63 %a, i63 %b)
  %value = zext i63 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umax63_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i63
  %b = trunc i64 %input_b to i63
  %result = call i63 @llvm.umax.i63(i63 -1, i63 %b)
  %value = zext i63 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umax63_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i63
  %b = trunc i64 %input_b to i63
  %result = call i63 @llvm.umax.i63(i63 %a, i63 -1)
  %value = zext i63 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smin63_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i63
  %b = trunc i64 %input_b to i63
  %result = call i63 @llvm.smin.i63(i63 %a, i63 %b)
  %value = zext i63 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smin63_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i63
  %b = trunc i64 %input_b to i63
  %result = call i63 @llvm.smin.i63(i63 -1, i63 %b)
  %value = zext i63 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smin63_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i63
  %b = trunc i64 %input_b to i63
  %result = call i63 @llvm.smin.i63(i63 %a, i63 -1)
  %value = zext i63 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smax63_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i63
  %b = trunc i64 %input_b to i63
  %result = call i63 @llvm.smax.i63(i63 %a, i63 %b)
  %value = zext i63 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smax63_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i63
  %b = trunc i64 %input_b to i63
  %result = call i63 @llvm.smax.i63(i63 -1, i63 %b)
  %value = zext i63 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smax63_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i63
  %b = trunc i64 %input_b to i63
  %result = call i63 @llvm.smax.i63(i63 %a, i63 -1)
  %value = zext i63 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_bitreverse63_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i63
  %b = trunc i64 %input_b to i63
  %result = call i63 @llvm.bitreverse.i63(i63 %a)
  %value = zext i63 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_bitreverse63_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %a = trunc i64 %input_a to i63
  %b = trunc i64 %input_b to i63
  %result = call i63 @llvm.bitreverse.i63(i63 -1)
  %value = zext i63 %result to i64
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_uadd_sat64_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %result = call i64 @llvm.uadd.sat.i64(i64 %input_a, i64 %input_b)
  %value = add i64 %result, 0
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_uadd_sat64_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %result = call i64 @llvm.uadd.sat.i64(i64 -1, i64 %input_b)
  %value = add i64 %result, 0
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_uadd_sat64_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %result = call i64 @llvm.uadd.sat.i64(i64 %input_a, i64 -1)
  %value = add i64 %result, 0
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_usub_sat64_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %result = call i64 @llvm.usub.sat.i64(i64 %input_a, i64 %input_b)
  %value = add i64 %result, 0
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_usub_sat64_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %result = call i64 @llvm.usub.sat.i64(i64 -1, i64 %input_b)
  %value = add i64 %result, 0
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_usub_sat64_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %result = call i64 @llvm.usub.sat.i64(i64 %input_a, i64 -1)
  %value = add i64 %result, 0
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umin64_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %result = call i64 @llvm.umin.i64(i64 %input_a, i64 %input_b)
  %value = add i64 %result, 0
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umin64_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %result = call i64 @llvm.umin.i64(i64 -1, i64 %input_b)
  %value = add i64 %result, 0
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umin64_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %result = call i64 @llvm.umin.i64(i64 %input_a, i64 -1)
  %value = add i64 %result, 0
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umax64_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %result = call i64 @llvm.umax.i64(i64 %input_a, i64 %input_b)
  %value = add i64 %result, 0
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umax64_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %result = call i64 @llvm.umax.i64(i64 -1, i64 %input_b)
  %value = add i64 %result, 0
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_umax64_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %result = call i64 @llvm.umax.i64(i64 %input_a, i64 -1)
  %value = add i64 %result, 0
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smin64_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %result = call i64 @llvm.smin.i64(i64 %input_a, i64 %input_b)
  %value = add i64 %result, 0
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smin64_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %result = call i64 @llvm.smin.i64(i64 -1, i64 %input_b)
  %value = add i64 %result, 0
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smin64_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %result = call i64 @llvm.smin.i64(i64 %input_a, i64 -1)
  %value = add i64 %result, 0
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smax64_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %result = call i64 @llvm.smax.i64(i64 %input_a, i64 %input_b)
  %value = add i64 %result, 0
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smax64_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %result = call i64 @llvm.smax.i64(i64 -1, i64 %input_b)
  %value = add i64 %result, 0
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_smax64_2(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %result = call i64 @llvm.smax.i64(i64 %input_a, i64 -1)
  %value = add i64 %result, 0
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_bitreverse64_0(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %result = call i64 @llvm.bitreverse.i64(i64 %input_a)
  %value = add i64 %result, 0
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}


define i64 @intrinsic_bitreverse64_1(i64 %input_a, i64 %input_b, ptr %out, i64 %salt) {
entry:
  %result = call i64 @llvm.bitreverse.i64(i64 -1)
  %value = add i64 %result, 0
  store i64 %value, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %xor = xor i64 %input_a, %input_b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %next, align 8
  ret i64 %value
}

